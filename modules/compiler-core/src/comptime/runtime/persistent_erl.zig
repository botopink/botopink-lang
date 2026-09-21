//! Persistent `erl` runner — one long-lived Erlang/OTP process per Zig process.
//!
//! Spawns `erl` lazily on the first request and keeps it alive. Comptime
//! evaluators write a module to disk and ask the server to run it; evals after
//! the first cost ~2ms (compile:file + code:load_binary + module call).
//!
//! The hashed build directory holds three modules, compiled together by one
//! `erlc` at warmup: this server and the two comptime preludes
//! (`prelude.zig`), which carry the host glue every generated module used to
//! copy. `erl -pa <dir>` finds all of them, and the directory's hash is taken
//! over every source in it, so a changed server *or* a changed prelude gets a
//! fresh directory rather than a stale `.beam`.
//!
//! Protocol (Zig ↔ erl), length-prefixed binary frames both ways:
//!   request:  <u32 BE len><cmd:u8><payload>
//!             cmd 1 = compile+load `<path>`, run `main/0`   (the one-shot path)
//!             cmd 2 = compile+load `<path>`, answer the module atom
//!             cmd 3 = call `<module>:main(<term>)`, where the payload is
//!                     `<u16 BE namelen><module><external term>`
//!             cmd 4 = load `.beam` bytes, answer the module atom; the payload is
//!                     `<u16 BE namelen><module><beam bytes>` (no file, no compiler)
//!   response: <u32 BE len><payload>        `main`'s iodata result, or an error
//!             payload tagged `__BP_ERL_COMPILE_ERROR__:` /
//!             `__BP_ERL_RUNTIME_ERROR__:` (raise, exit, non-iodata result, timeout)
//!
//! Cmd 2 + cmd 3 are what the evaluators use: the module is compiled once per
//! declaration and every later call site sends cmd 3 alone. Cmd 4 is cmd 2 for
//! a module assembled in Zig (`codegen/beam/beam_file.zig`): the same `loaded`
//! set, the same cmd 3 afterwards, and a `code:load_binary/3` rejection comes
//! back on the `compile_error` channel so the evaluators read both the same
//! way. Cmd 1 stays as the one-shot fallback and is what this file's own
//! regression tests drive.
//!
//! `main` runs in a monitored process with a wall-clock budget
//! (`eval_timeout_ms`), so a runaway body is killed instead of wedging the server.
//! `evalDetailed` returns the reply classified as a `Response`.
//!
//! stdout is the frame channel and nothing else may write to it: the server
//! moves the default logger handler to `standard_error`, and `main` runs with
//! `standard_error` as its group leader, so `io:format/1` and log events from a
//! comptime body land in `erl.stderr.log`. A reply longer than `max_frame_len`
//! is a desynchronised stream (something wrote to `user` directly), reported as
//! `error.PersistentErlFrameTooLarge` with a message in `lastTransportError`.
//!
//! Thread-safety: an atomic spin-lock serialises the pipes; BEAM execution inside
//! erl stays single-request-at-a-time.
//!
//! Lifecycle: the child is process-lifetime; when the parent exits, its stdin
//! EOFs and it exits. Crash recovery: a transport failure (erl died, short,
//! garbled or over-cap frame) kills the child and marks the singleton broken;
//! the next request respawns. The failed request itself is not retried.

const std = @import("std");
const preludeMod = @import("./prelude.zig");
const beamFile = @import("../../codegen/beam/beam_file.zig");
const etf = @import("./etf.zig");
const Term = @import("../../codegen/beam/term.zig").Term;

// The assembler and its opcode table are reached only from this file until
// `codegen/tests.zig` lists them; the reference keeps their inline tests in
// the suite whatever `-Dtest-filter` selects (a file referenced from a
// filtered-out test alone is never analysed, and its tests silently vanish).
comptime {
    _ = beamFile;
}

const Io = std.Io;
const Child = std.process.Child;
const File = std.Io.File;

/// Erlang server module. Compiled once at warmup, loaded into the persistent
/// `erl`. Each `eval` request compiles and executes a comptime module via
/// `compile:file/2` + `code:load_binary/3` + `Mod:main()`.
const server_erl = server_header ++ std.fmt.comptimePrint("-define(EVAL_TIMEOUT_MS, {d}).\n", .{eval_timeout_ms}) ++ server_body;

const server_header =
    \\-module(botopink_comptime_server).
    \\-export([start/0]).
    \\
;

const server_body =
    \\start() ->
    \\    %% Frames are raw bytes; `unicode` (the default) would UTF-8-encode the
    \\    %% 4-byte length prefix and corrupt any payload >= 128 bytes.
    \\    ok = io:setopts(standard_io, [{encoding, latin1}]),
    \\    %% stdout is the frame channel, and the default logger handler writes to
    \\    %% it: a SIGTERM notice or a `logger:error/1` in a comptime body would
    \\    %% land between two frames. Send every log event to stderr instead.
    \\    _ = logger:remove_handler(default),
    \\    ok = logger:add_handler(default, logger_std_h, #{config => #{type => standard_error}}),
    \\    loop().
    \\
    \\loop() ->
    \\    case read_frame() of
    \\        eof -> ok;
    \\        {1, PathBin} ->  %% eval: compile .erl file, run main/0
    \\            write_frame(compile_then(binary_to_list(PathBin), fun(Mod) -> safe_call(Mod, []) end)),
    \\            loop();
    \\        {2, PathBin} ->  %% load: compile .erl file, answer the module atom
    \\            write_frame(compile_then(binary_to_list(PathBin), fun atom_to_binary/1)),
    \\            loop();
    \\        {3, Payload} ->  %% call: <<NameLen:16, Name, ExternalTerm>> -> main/1
    \\            <<NameLen:16/unsigned-big-integer, Rest/binary>> = Payload,
    \\            <<NameBin:NameLen/binary, ArgBin/binary>> = Rest,
    \\            Mod = binary_to_atom(NameBin, latin1),
    \\            write_frame(safe_call(Mod, [binary_to_term(ArgBin)])),
    \\            loop();
    \\        {4, Payload} ->  %% load: <<NameLen:16, Name, Beam>> -> code:load_binary, answer the atom
    \\            <<NameLen:16/unsigned-big-integer, Rest/binary>> = Payload,
    \\            <<NameBin:NameLen/binary, Beam/binary>> = Rest,
    \\            write_frame(load_beam(binary_to_atom(NameBin, latin1), Beam)),
    \\            loop()
    \\    end.
    \\
    \\%% Load `.beam` bytes assembled by the compiler (no source, no `compile:file`),
    \\%% then answer the module atom. The loader's rejection (`badfile`, an opcode
    \\%% above what this release knows) is reported on the compile-error channel:
    \\%% to the evaluators it is the same event a rejected `.erl` was.
    \\load_beam(Mod, Beam) ->
    \\    _ = code:purge(Mod),
    \\    case code:load_binary(Mod, "", Beam) of
    \\        {module, Mod} -> atom_to_binary(Mod);
    \\        {error, Reason} ->
    \\            io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{load_binary, Mod, Reason}])
    \\    end.
    \\
    \\%% Compile and load `Path`, then answer `Then(Mod)`; a compiler rejection is
    \\%% the error frame instead. `code:purge/1` drops a previous version of the
    \\%% same atom before it becomes old code: one module now serves every call
    \\%% site of a declaration, so a reload means the declaration itself changed.
    \\compile_then(Path, Then) ->
    \\    case compile:file(Path, [binary, return]) of
    \\        {ok, Mod, Beam} -> load_then(Mod, Beam, Then);
    \\        {ok, Mod, Beam, _Warnings} -> load_then(Mod, Beam, Then);
    \\        {error, Errors, Warnings} ->
    \\            io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{Errors, Warnings}])
    \\    end.
    \\
    \\load_then(Mod, Beam, Then) ->
    \\    _ = code:purge(Mod),
    \\    {module, _} = code:load_binary(Mod, "", Beam),
    \\    Then(Mod).
    \\
    \\%% `Mod:main(Args…)` runs in a monitored process so a runaway comptime body
    \\%% (infinite loop, blocked receive) is killed after the timeout instead of
    \\%% wedging the server — and with it every later eval of this compiler run.
    \\%% Its group leader is `standard_error`, not the server's (`user`, the frame
    \\%% channel): `io:format/1`, `io:get_line/1` and every process it spawns talk
    \\%% to stderr, so a printing body cannot desynchronise the frame stream.
    \\safe_call(Mod, Args) ->
    \\    {Pid, Ref} = spawn_monitor(fun() ->
    \\        group_leader(whereis(standard_error), self()),
    \\        Result = try {ok, apply(Mod, main, Args)}
    \\        catch
    \\            Class:Reason:Stack ->
    \\                {error, io_lib:format("__BP_ERL_RUNTIME_ERROR__:~p:~p~n~p", [Class, Reason, Stack])}
    \\        end,
    \\        exit({bp_result, Result})
    \\    end),
    \\    receive
    \\        {'DOWN', Ref, process, Pid, {bp_result, {ok, Value}}} -> Value;
    \\        {'DOWN', Ref, process, Pid, {bp_result, {error, Message}}} -> Message;
    \\        {'DOWN', Ref, process, Pid, Other} ->
    \\            io_lib:format("__BP_ERL_RUNTIME_ERROR__:exit:~p", [Other])
    \\    after ?EVAL_TIMEOUT_MS ->
    \\        exit(Pid, kill),
    \\        receive {'DOWN', Ref, process, Pid, _} -> ok end,
    \\        io_lib:format("__BP_ERL_RUNTIME_ERROR__:timeout:main did not return within ~pms", [?EVAL_TIMEOUT_MS])
    \\    end.
    \\
    \\read_frame() ->
    \\    case file:read(standard_io, 4) of
    \\        {ok, RawLen} ->
    \\            LenBin = if is_binary(RawLen) -> RawLen; true -> list_to_binary(RawLen) end,
    \\            <<Len:32/unsigned-big-integer>> = LenBin,
    \\            case file:read(standard_io, Len) of
    \\                {ok, RawPayload} ->
    \\                    PayloadBin = if is_binary(RawPayload) -> RawPayload; true -> list_to_binary(RawPayload) end,
    \\                    <<Cmd:8, Rest/binary>> = PayloadBin,
    \\                    {Cmd, Rest};
    \\                eof -> eof;
    \\                _ -> eof
    \\            end;
    \\        eof -> eof;
    \\        _ -> eof
    \\    end.
    \\
    \\%% Every response is exactly one frame. A `main` result that is not iodata
    \\%% becomes a runtime error frame rather than crashing the server.
    \\write_frame(Data) ->
    \\    B = try iolist_to_binary(Data)
    \\        catch _:_ ->
    \\            iolist_to_binary(io_lib:format("__BP_ERL_RUNTIME_ERROR__:bad_result:~p", [Data]))
    \\        end,
    \\    Len = byte_size(B),
    \\    file:write(standard_io, <<Len:32/unsigned-big-integer, B/binary>>).
;

/// Per-eval wall-clock budget enforced by the server (`safe_call`).
const eval_timeout_ms = 10_000;

/// Largest reply frame `readFrame` accepts. A reply is a comptime body's
/// generated code or JSON outcome — kilobytes. A prefix past this is text that
/// reached stdout outside a frame (`=INF` of an `=INFO REPORT` reads as
/// 1 028 214 342 bytes), so it fails as a transport error, not an allocation.
pub const max_frame_len: u32 = 16 * 1024 * 1024;

/// Root of the runtime's files, relative to the cwd.
const server_dir = ".botopinkbuild/tmp/persistent_erl";

const server_module_file = "botopink_comptime_server";

/// Everything built into the hashed directory: the server, then the comptime
/// evaluators' resident prelude modules (`prelude.zig`). They are compiled
/// together, once, and `erl -pa <dir>` finds all of them.
const ResidentModule = struct {
    name: []const u8,
    source: []const u8,
};

/// The build directory is `<server_dir>/<hash>/`, keyed by **every** source
/// built into it: a warm directory skips `erlc`, and a changed server or a
/// changed prelude never loads a stale `.beam`. The hash is taken at run time
/// because the prelude source is rendered from the same `erl_ast` forms the
/// generated modules are, not written out by hand.
fn buildHash(modules: []const ResidentModule) [16]u8 {
    var h = std.hash.Wyhash.init(0);
    h.update(server_erl);
    for (modules) |m| {
        h.update(m.name);
        h.update(m.source);
    }
    var out: [16]u8 = undefined;
    _ = std.fmt.bufPrint(&out, "{x:0>16}", .{h.final()}) catch unreachable;
    return out;
}

/// The server plus both preludes, built into `arena`.
fn residentModules(arena: std.mem.Allocator) ![]const ResidentModule {
    const preludes = try preludeMod.modules(arena);
    const out = try arena.alloc(ResidentModule, 1 + preludes.len);
    out[0] = .{ .name = server_module_file, .source = server_erl };
    for (preludes, out[1..]) |p, *slot| slot.* = .{ .name = p.name, .source = p.source };
    return out;
}

/// erl's stderr: the logger's output and everything a comptime body prints.
/// Truncated at every spawn; nothing reads it back — transport errors name it.
const stderr_log_path = server_dir ++ "/erl.stderr.log";

// ── singleton state ───────────────────────────────────────────────────────────

const State = struct {
    child: Child,
    stdin: File,
    stdout: File,
};

var state: State = undefined;
var init_state: std.atomic.Value(u8) = .init(0); // 0=uninit, 1=initing, 2=ready, 3=broken
var io_mu: std.atomic.Value(u8) = .init(0);

fn lock() void {
    while (io_mu.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| {
        std.atomic.spinLoopHint();
    }
}

fn unlock() void {
    io_mu.store(0, .release);
}

/// Lazy-spawn the persistent `erl` process. `prepareServer` builds the server into
/// `.botopinkbuild/tmp/persistent_erl/<server_hash>/`; `erl` starts with it on the code path.
fn ensureSpawned(io: Io, allocator: std.mem.Allocator) !void {
    while (true) {
        const s = init_state.load(.acquire);
        if (s == 2) return;
        if (s == 3) {
            // Previous invocation detected a broken pipe — reset and respawn.
            if (init_state.cmpxchgStrong(3, 0, .acquire, .acquire)) |_| continue;
        }
        if (s == 0) {
            if (init_state.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            errdefer init_state.store(3, .release);

            var build_arena = std.heap.ArenaAllocator.init(allocator);
            defer build_arena.deinit();
            const modules = try residentModules(build_arena.allocator());
            const beam_dir = try prepareServer(io, allocator, server_dir, modules);
            defer allocator.free(beam_dir);

            // Spawn erl with the server module on its code path. `halt()` after
            // `start()` returns (stdin EOF — the parent exited) ends the VM;
            // without it `-noshell` keeps an orphan `beam.smp` alive forever.
            // stderr goes to a log file, never inherited: an orphan holding the
            // parent's stderr open blocks whoever waits for its EOF (the
            // `zig build test` runner reports "test runner failed to respond").
            const stderr_log = try std.Io.Dir.cwd().createFile(io, stderr_log_path, .{});
            defer stderr_log.close(io);
            const child = try std.process.spawn(io, .{
                .argv = &.{ "erl", "-noshell", "-pa", beam_dir, "-eval", "botopink_comptime_server:start(), halt()." },
                .stdin = .pipe,
                .stdout = .pipe,
                .stderr = .{ .file = stderr_log },
            });
            state = .{
                .child = child,
                .stdin = child.stdin orelse return error.NoStdin,
                .stdout = child.stdout orelse return error.NoStdout,
            };
            init_state.store(2, .release);
            return;
        }
        std.atomic.spinLoopHint();
    }
}

/// Compile `modules` into `<base>/<hash of them all>/` unless they are already
/// there, and return that directory (owned by the caller). Several compiler
/// processes can share one cwd, so nothing is written in place: the sources and
/// `.beam`s are built in a uniquely named staging directory that is renamed onto
/// the final one. A process that loses the rename race uses the winner's
/// (identical) `.beam`s; a truncated source or `.beam` is never visible.
///
/// The last module decides whether the directory is warm: `erlc` is given every
/// source in one invocation, so either all of them are there or the staging
/// directory never made it.
fn prepareServer(io: Io, allocator: std.mem.Allocator, base: []const u8, modules: []const ResidentModule) ![]u8 {
    const cwd = std.Io.Dir.cwd();
    const hash = buildHash(modules);
    const dir = try std.fs.path.join(allocator, &.{ base, &hash });
    errdefer allocator.free(dir);
    const last = try std.fmt.allocPrint(allocator, "{s}/{s}.beam", .{ dir, modules[modules.len - 1].name });
    defer allocator.free(last);
    if (cwd.access(io, last, .{})) |_| return dir else |_| {}

    var nonce: [8]u8 = undefined;
    io.random(&nonce);
    const staging = try std.fmt.allocPrint(allocator, "{s}.{x:0>16}.tmp", .{ dir, std.mem.readInt(u64, &nonce, .little) });
    defer allocator.free(staging);
    try cwd.createDirPath(io, staging);
    // After a successful rename `staging` no longer exists; this only reaps a
    // failed build or a lost race.
    defer cwd.deleteTree(io, staging) catch {};

    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (argv.items[3..]) |p| allocator.free(p);
        argv.deinit(allocator);
    }
    try argv.appendSlice(allocator, &.{ "erlc", "-o", staging });
    for (modules) |m| {
        const source = try std.fmt.allocPrint(allocator, "{s}/{s}.erl", .{ staging, m.name });
        errdefer allocator.free(source);
        try cwd.writeFile(io, .{ .sub_path = source, .data = m.source });
        try argv.append(allocator, source);
    }

    const compile_result = std.process.run(allocator, io, .{
        .argv = argv.items,
        .timeout = .{ .duration = .{ .raw = .{ .nanoseconds = 120 * std.time.ns_per_s }, .clock = .real } },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.PersistentErlNotFound,
        else => return error.PersistentErlBroken,
    };
    defer allocator.free(compile_result.stdout);
    defer allocator.free(compile_result.stderr);
    if (compile_result.term != .exited or compile_result.term.exited != 0) {
        return error.PersistentErlCompileError;
    }

    cwd.rename(staging, cwd, dir, io) catch {
        // Another process renamed its build in first (a non-empty target
        // refuses the rename); anything else leaves no `.beam` behind.
        cwd.access(io, last, .{}) catch return error.PersistentErlBroken;
    };
    return dir;
}

/// Fill `buf` completely from `src`. `readStreaming` may return short reads (a
/// large compile-error payload arrives in several chunks); stopping early would
/// desynchronise the frame protocol for every later eval.
fn readExact(io: Io, src: File, buf: []u8) !void {
    var filled: usize = 0;
    while (filled < buf.len) {
        const n = try src.readStreaming(io, &.{buf[filled..]});
        if (n == 0) return error.PersistentErlEof;
        filled += n;
    }
}

/// Read a length-prefixed binary frame from `src`: <4-byte BE len><payload>.
/// Returns the payload bytes (without length prefix). A length above
/// `max_frame_len` records a transport-error message and fails before any
/// allocation.
fn readFrame(io: Io, src: File, allocator: std.mem.Allocator) ![]u8 {
    var len_buf: [4]u8 = undefined;
    try readExact(io, src, &len_buf);
    const len = std.mem.readInt(u32, &len_buf, .big);
    if (len > max_frame_len) {
        var shown = len_buf;
        for (&shown) |*c| {
            if (!std.ascii.isPrint(c.*)) c.* = '.';
        }
        setTransportError(
            "reply frame length {d} (prefix \"{s}\") exceeds the {d}-byte cap: " ++
                "something wrote to the erl server's stdout outside a frame",
            .{ len, &shown, max_frame_len },
        );
        return error.PersistentErlFrameTooLarge;
    }
    const payload = try allocator.alloc(u8, len);
    errdefer allocator.free(payload);
    try readExact(io, src, payload);
    return payload;
}

var transport_error_buf: [512]u8 = undefined;
var transport_error_len: usize = 0;

fn setTransportError(comptime fmt: []const u8, args: anytype) void {
    const suffix = " (erl stderr: " ++ stderr_log_path ++ ")";
    const message = std.fmt.bufPrint(&transport_error_buf, fmt ++ suffix, args) catch {
        const fallback = "transport error" ++ suffix;
        @memcpy(transport_error_buf[0..fallback.len], fallback);
        transport_error_len = fallback.len;
        return;
    };
    transport_error_len = message.len;
}

/// Why the last request failed with a transport error (`PersistentErlBroken`,
/// `PersistentErlFrameTooLarge`), or null when it did not. Valid until the
/// next request.
pub fn lastTransportError() ?[]const u8 {
    if (transport_error_len == 0) return null;
    return transport_error_buf[0..transport_error_len];
}

/// Send a command frame: <4-byte BE len><cmd byte><payload bytes>.
fn sendFrame(io: Io, cmd: u8, payload: []const u8) !void {
    const total_len: u32 = @intCast(1 + payload.len); // cmd byte + payload
    var len_buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &len_buf, total_len, .big);
    try state.stdin.writeStreamingAll(io, &len_buf);
    try state.stdin.writeStreamingAll(io, &.{cmd});
    try state.stdin.writeStreamingAll(io, payload);
}

/// One request/reply round trip on the child's pipes.
fn exchange(io: Io, allocator: std.mem.Allocator, cmd: u8, payload: []const u8) ![]u8 {
    try sendFrame(io, cmd, payload);
    return readFrame(io, state.stdout, allocator);
}

/// Outcome of one request. Every variant's slice is allocated from the
/// caller's allocator and owned by the caller.
pub const Response = union(enum) {
    /// `main`'s result.
    ok: []u8,
    /// `compile:file/2` rejected the module (`~p` of `{Errors, Warnings}`).
    compile_error: []u8,
    /// `main` raised, exited, returned non-iodata, or timed out.
    runtime_error: []u8,

    pub fn payload(self: Response) []u8 {
        return switch (self) {
            inline else => |p| p,
        };
    }
};

const compile_error_tag = "__BP_ERL_COMPILE_ERROR__:";
const runtime_error_tag = "__BP_ERL_RUNTIME_ERROR__:";

/// Send one command and classify the reply. A transport failure (erl died,
/// short/garbled frame) kills the child and marks the singleton broken so the
/// next request respawns a fresh process instead of reading a desynced pipe.
fn request(allocator: std.mem.Allocator, io: Io, cmd: u8, payload: []const u8) !Response {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();
    return requestLocked(allocator, io, cmd, payload);
}

/// `request` minus the spawn and the lock, so a caller that must keep the pipes
/// for two commands in a row (`evalWithArg`: load, then call) holds one lock
/// rather than racing another thread between them.
fn requestLocked(allocator: std.mem.Allocator, io: Io, cmd: u8, payload: []const u8) !Response {
    transport_error_len = 0;

    const raw = exchange(io, allocator, cmd, payload) catch |err| {
        if (transport_error_len == 0) setTransportError("{s} on the erl frame stream", .{@errorName(err)});
        state.child.kill(io);
        init_state.store(3, .release);
        // The next request respawns a fresh VM, which has loaded nothing.
        loaded.clearRetainingCapacity();
        return if (err == error.PersistentErlFrameTooLarge) err else error.PersistentErlBroken;
    };
    errdefer allocator.free(raw);

    const tags = [_]struct { []const u8, std.meta.Tag(Response) }{
        .{ compile_error_tag, .compile_error },
        .{ runtime_error_tag, .runtime_error },
    };
    for (tags) |t| {
        if (!std.mem.startsWith(u8, raw, t[0])) continue;
        const message = try allocator.dupe(u8, raw[t[0].len..]);
        allocator.free(raw);
        return switch (t[1]) {
            .compile_error => .{ .compile_error = message },
            .runtime_error => .{ .runtime_error = message },
            .ok => unreachable,
        };
    }
    return .{ .ok = raw };
}

/// Compile and run the comptime module at `erl_path` (cmd=1), keeping the
/// failure detail: the compiler diagnostics, or the runtime class/reason/stack.
/// On the first call, lazy-spawns the erl process and compiles the server module.
///
/// The one-shot path: it compiles on every call and calls `main/0`. The
/// evaluators use `evalWithArg` instead; this stays for a caller that has a
/// self-contained module and for this file's regression tests.
pub fn evalDetailed(allocator: std.mem.Allocator, io: Io, erl_path: []const u8) !Response {
    return request(allocator, io, 1, erl_path);
}

/// Module atoms this process has had the node compile and load (cmd 2). Keys are
/// owned by `loaded_keys` and live as long as the process: their number is
/// bounded by the declarations in the build, not by the call sites. Read and
/// written only under `io_mu`, and cleared when the child is respawned.
var loaded: std.StringHashMapUnmanaged(void) = .empty;
const loaded_keys = std.heap.page_allocator;

/// Call `<module>:main(<arg>)` in the node, compiling and loading `erl_path`
/// first if this process has not already. `arg` is an external term
/// (`etf.encode`), so nothing about the call site is in the module — which is
/// what lets one module serve every call site of a declaration.
pub fn evalWithArg(
    allocator: std.mem.Allocator,
    io: Io,
    erl_path: []const u8,
    module: []const u8,
    arg: []const u8,
) !Response {
    return evalLoaded(allocator, io, .{ .erl_path = erl_path }, module, arg);
}

/// `evalWithArg` for a module the compiler assembled itself
/// (`codegen/beam/beam_file.zig`): `beam` is loaded with cmd 4 — bytes in the
/// frame, no file, no `compile:file` — the first time this process sees
/// `module`, then `main/1` is called exactly as for a source module.
pub fn evalBeamWithArg(
    allocator: std.mem.Allocator,
    io: Io,
    beam: []const u8,
    module: []const u8,
    arg: []const u8,
) !Response {
    return evalLoaded(allocator, io, .{ .beam = beam }, module, arg);
}

/// How a module reaches the node: a `.erl` path it compiles (cmd 2) or `.beam`
/// bytes it loads (cmd 4). Either way the reply is the module atom.
const Load = union(enum) {
    erl_path: []const u8,
    beam: []const u8,
};

fn evalLoaded(allocator: std.mem.Allocator, io: Io, load: Load, module: []const u8, arg: []const u8) !Response {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();

    if (!loaded.contains(module)) {
        const response = switch (load) {
            .erl_path => |path| try requestLocked(allocator, io, 2, path),
            .beam => |bytes| blk: {
                const payload = try namedPayload(allocator, module, bytes);
                defer allocator.free(payload);
                break :blk try requestLocked(allocator, io, 4, payload);
            },
        };
        switch (response) {
            // The reply is the module atom; nothing needs it past this point.
            .ok => |atom| allocator.free(atom),
            else => return response,
        }
        const key = try loaded_keys.dupe(u8, module);
        errdefer loaded_keys.free(key);
        try loaded.put(loaded_keys, key, {});
    }

    const payload = try namedPayload(allocator, module, arg);
    defer allocator.free(payload);
    return requestLocked(allocator, io, 3, payload);
}

/// `<u16 BE namelen><module><body>` — the payload shape of cmd 3 (body = the
/// external term) and cmd 4 (body = the `.beam` bytes). Owned by the caller.
fn namedPayload(allocator: std.mem.Allocator, module: []const u8, body: []const u8) ![]u8 {
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    errdefer payload.deinit(allocator);
    try payload.appendSlice(allocator, &.{ @intCast(module.len >> 8), @truncate(module.len) });
    try payload.appendSlice(allocator, module);
    try payload.appendSlice(allocator, body);
    return payload.toOwnedSlice(allocator);
}

// ── tests ─────────────────────────────────────────────────────────────────────

/// Write `source` as `<module>.erl` under a fresh test tmp dir and return its
/// cwd-relative path (the erl server shares the test binary's cwd).
fn writeTestModule(tmp: *std.testing.TmpDir, module: []const u8, source: []const u8) ![]u8 {
    const io = std.testing.io;
    const file_name = try std.fmt.allocPrint(std.testing.allocator, "{s}.erl", .{module});
    defer std.testing.allocator.free(file_name);
    try tmp.dir.writeFile(io, .{ .sub_path = file_name, .data = source });
    return std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path, file_name });
}

fn expectOk(expected: []const u8, erl_path: []const u8) !void {
    const response = try evalDetailed(std.testing.allocator, std.testing.io, erl_path);
    defer std.testing.allocator.free(response.payload());
    try std.testing.expectEqual(std.meta.Tag(Response).ok, std.meta.activeTag(response));
    try std.testing.expectEqualStrings(expected, response.payload());
}

const noisy_module =
    \\-module(bp_persistent_erl_noisy).
    \\-export([main/0]).
    \\
    \\main() ->
    \\    io:format("io:format/1 from a comptime body~n"),
    \\    io:format(standard_io, "~p~n", [standard_io_noise]),
    \\    logger:error("logger event from a comptime body"),
    \\    spawn(fun() -> io:format("a process the body spawned~n") end),
    \\    <<"clean reply">>.
    \\
;

test "persistent_erl: a comptime body's io:format and logger output stay off the frame stream" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const path = try writeTestModule(&tmp, "bp_persistent_erl_noisy", noisy_module);
    defer std.testing.allocator.free(path);

    // Twice: output that lands late (the logger handler, the spawned process)
    // would corrupt the second reply's length prefix, not the first.
    try expectOk("clean reply", path);
    try expectOk("clean reply", path);
    try std.testing.expectEqual(@as(?[]const u8, null), lastTransportError());
}

test "persistent_erl: a reply frame over the length cap is a transport error, then the server respawns" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    // `user` is the server's own stdout: bytes written there bypass the group
    // leader and read as a 0x7FFFFFFF length prefix.
    const corrupt_path = try writeTestModule(&tmp, "bp_persistent_erl_corrupt",
        \\-module(bp_persistent_erl_corrupt).
        \\-export([main/0]).
        \\
        \\main() ->
        \\    file:write(user, <<16#7F, 16#FF, 16#FF, 16#FF>>),
        \\    <<"unreachable">>.
        \\
    );
    defer std.testing.allocator.free(corrupt_path);
    const noisy_path = try writeTestModule(&tmp, "bp_persistent_erl_noisy", noisy_module);
    defer std.testing.allocator.free(noisy_path);

    try std.testing.expectError(
        error.PersistentErlFrameTooLarge,
        evalDetailed(std.testing.allocator, std.testing.io, corrupt_path),
    );
    const message = lastTransportError() orelse return error.TestExpectedTransportMessage;
    try std.testing.expect(std.mem.indexOf(u8, message, "exceeds the 16777216-byte cap") != null);
    try std.testing.expect(std.mem.indexOf(u8, message, stderr_log_path) != null);

    try expectOk("clean reply", noisy_path);
}

const PrepareRace = struct {
    base: []const u8,
    modules: []const ResidentModule,
    dir: ?[]u8 = null,
    err: ?anyerror = null,

    fn run(self: *PrepareRace) void {
        self.dir = prepareServer(std.testing.io, std.heap.page_allocator, self.base, self.modules) catch |err| {
            self.err = err;
            return;
        };
    }
};

test "persistent_erl: concurrent server builds in one cwd all get a complete .beam" {
    const io = std.testing.io;
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const modules = try residentModules(arena_state.allocator());
    // The server and both comptime preludes, compiled in one `erlc`.
    try std.testing.expectEqual(@as(usize, 3), modules.len);

    var tmp = std.testing.tmpDir(.{ .iterate = true });
    defer tmp.cleanup();
    const base = try std.fs.path.join(std.testing.allocator, &.{ ".zig-cache", "tmp", &tmp.sub_path });
    defer std.testing.allocator.free(base);

    // Cold directory, several builders at once — the shape of parallel test
    // binaries (or compiler runs) sharing a working directory.
    var races: [6]PrepareRace = @splat(.{ .base = base, .modules = modules });
    var threads: [races.len]std.Thread = undefined;
    for (&races, &threads) |*race, *thread| thread.* = try std.Thread.spawn(.{}, PrepareRace.run, .{race});
    for (threads) |thread| thread.join();

    defer for (races) |race| if (race.dir) |dir| std.heap.page_allocator.free(dir);
    for (races) |race| if (race.err) |err| return err;
    for (races) |race| try std.testing.expectEqualStrings(races[0].dir.?, race.dir.?);

    // Warm: the cached build is reused, and no staging directory is left.
    const again = try prepareServer(io, std.testing.allocator, base, modules);
    defer std.testing.allocator.free(again);
    // Every resident module is there — the prelude is what a generated module
    // `-import`s, so a directory with only the server in it would spawn an erl
    // that compiles every comptime module and then fails to run it.
    for (modules) |m| {
        const beam = try std.fmt.allocPrint(std.testing.allocator, "{s}/{s}.beam", .{ again, m.name });
        defer std.testing.allocator.free(beam);
        try std.Io.Dir.cwd().access(io, beam, .{});
    }
    var it = tmp.dir.iterate();
    var entries: usize = 0;
    while (try it.next(io)) |entry| {
        try std.testing.expectEqualStrings(&buildHash(modules), entry.name);
        entries += 1;
    }
    try std.testing.expectEqual(@as(usize, 1), entries);
}

test "persistent_erl: readFrame rejects a stray =INFO REPORT before allocating" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "stream", .data = "=INFO REPORT==== SIGTERM received" });
    const src = try tmp.dir.openFile(io, "stream", .{});
    defer src.close(io);

    // Real payloads come back through the failing allocator: none may be made.
    try std.testing.expectError(
        error.PersistentErlFrameTooLarge,
        readFrame(io, src, std.testing.failing_allocator),
    );
    const message = lastTransportError() orelse return error.TestExpectedTransportMessage;
    try std.testing.expect(std.mem.indexOf(u8, message, "length 1028214342 (prefix \"=INF\")") != null);
}

/// `-module(bp_persistent_erl_echo). -export([main/1]). main(X) -> X.` assembled
/// by `codegen/beam/beam_file.zig` — the argument arrives in `{x, 0}` and is the
/// reply, so the frame that comes back is the ETF-decoded term as iodata.
fn echoBeam(allocator: std.mem.Allocator) ![]u8 {
    const S = struct {
        const m = "bp_persistent_erl_echo";
        const code = [_]beamFile.Instr{
            beamFile.Instr.of(.label, &.{beamFile.Arg.uint(1)}),
            beamFile.Instr.of(.func_info, &.{ beamFile.Arg.atomOf(m), beamFile.Arg.atomOf("main"), beamFile.Arg.uint(1) }),
            beamFile.Instr.of(.label, &.{beamFile.Arg.uint(2)}),
            beamFile.Instr.of(.@"return", &.{}),
        };
        const functions = [_]beamFile.Function{.{ .name = "main", .arity = 1, .entry = 2, .code = &code }};
    };
    return beamFile.assemble(allocator, .{ .name = S.m, .functions = &S.functions });
}

test "persistent_erl: cmd 4 loads .beam bytes in-frame and cmd 3 calls main/1 on them" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const beam = try echoBeam(allocator);
    defer allocator.free(beam);
    const module = "bp_persistent_erl_echo";

    // First call: load (cmd 4) then call (cmd 3). Second call: cmd 3 alone — the
    // `loaded` set remembers the atom, and the reply must be the same.
    for ([_][]const u8{ "echo", "again" }) |text| {
        const arg = try etf.encode(arena_state.allocator(), Term.str(text));
        const response = try evalBeamWithArg(allocator, io, beam, module, arg);
        defer allocator.free(response.payload());
        try std.testing.expectEqual(std.meta.Tag(Response).ok, std.meta.activeTag(response));
        try std.testing.expectEqualStrings(text, response.payload());
    }
    try std.testing.expect(loaded.contains(module));

    // Bytes the loader refuses come back on the compile-error channel — the same
    // event a rejected `.erl` was to the evaluators — and the atom is not
    // remembered as loaded.
    const garbage = "FOR1\x00\x00\x00\x04BEAM";
    const rejected = try evalBeamWithArg(allocator, io, garbage, "bp_persistent_erl_garbage", "\x83\x6a");
    defer allocator.free(rejected.payload());
    try std.testing.expectEqual(std.meta.Tag(Response).compile_error, std.meta.activeTag(rejected));
    try std.testing.expect(std.mem.indexOf(u8, rejected.payload(), "load_binary") != null);
    try std.testing.expect(std.mem.indexOf(u8, rejected.payload(), "badfile") != null);
    try std.testing.expect(!loaded.contains("bp_persistent_erl_garbage"));
}

test "persistent_erl: readFrame returns a payload under the cap" {
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    try tmp.dir.writeFile(io, .{ .sub_path = "stream", .data = "\x00\x00\x00\x05hello" });
    const src = try tmp.dir.openFile(io, "stream", .{});
    defer src.close(io);

    const payload = try readFrame(io, src, std.testing.allocator);
    defer std.testing.allocator.free(payload);
    try std.testing.expectEqualStrings("hello", payload);
}
