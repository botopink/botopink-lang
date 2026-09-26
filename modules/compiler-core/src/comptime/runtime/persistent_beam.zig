//! The BEAM comptime runtime's node — one long-lived Erlang/OTP process per Zig
//! process (the runtime `persistent_erl.zig` was until front 14 step 3).
//!
//! Spawns `erl` lazily on the first request and keeps it alive. Comptime
//! evaluators hand the node a module as `.beam` bytes the compiler assembled
//! (`beam/program.zig`) and ask it to run `main/1`. Nothing on this path
//! compiles Erlang: the node loads bytes and calls a function.
//!
//! The node runs three resident modules: this server (`server_source.zig`) and
//! the two comptime preludes (`prelude.zig`), which carry the host glue every
//! generated module used to copy. They are **`.beam` bytes embedded in the
//! compiler** (decision 83): `erlc` compiles them at `zig build` time (root
//! `build.zig`, "resident comptime modules") and the spawn bootstrap loads them
//! into the node over stdin before the server loop starts — no `erlc` on any
//! user's machine, no `-pa` directory, nothing written but the stderr log.
//!
//! Protocol (Zig ↔ erl), length-prefixed binary frames both ways:
//!   request:  <u32 BE len><cmd:u8><payload>
//!             cmd 3 = call `<module>:main(<term>)`, where the payload is
//!                     `<u16 BE namelen><module><external term>`
//!             cmd 4 = load `.beam` bytes, answer the module atom; the payload is
//!                     `<u16 BE namelen><module><beam bytes>` (no file, no compiler)
//!   response: <u32 BE len><payload>        `main`'s iodata result, or an error
//!             payload tagged `__BP_ERL_COMPILE_ERROR__:` (the loader refused
//!             the bytes) /
//!             `__BP_ERL_RUNTIME_ERROR__:` (raise, exit, non-iodata result, timeout)
//!
//! Before the first request the same frame shape carries the handshake: the
//! spawn sends one cmd-4 frame per resident module and reads one reply — `ok`,
//! or `__BP_ERL_BELOW_FLOOR__:` (an `erl` older than `otp_floor`, decision 86) /
//! `__BP_ERL_LOAD_ERROR__:` (a `.beam` this release cannot load), both reported
//! through `lastTransportError`.
//!
//! Cmd 4 + cmd 3 are what the evaluators use: the module is loaded once per
//! declaration (the `loaded` set) and every later call site sends cmd 3 alone.
//! A `code:load_binary/3` rejection comes back on the `compile_error` channel.
//! Cmds 1 and 2 — `compile:file` of a staged `.erl` — are gone with the `.erl`
//! staging (front 14 step 3, front 18 step 1b): a module the BEAM lowering
//! refuses is a compile error naming the construct, as on the wat runtime.
//!
//! `main` runs in a monitored process with a wall-clock budget
//! (`server_source.eval_timeout_ms`), so a runaway body is killed instead of
//! wedging the server. `evalBeamWithArg` returns the reply classified as a `Response`.
//!
//! stdout is the frame channel and nothing else may write to it: the server
//! moves the default logger handler to `standard_error`, and `main` runs with
//! `standard_error` as its group leader, so `io:format/1` and log events from a
//! comptime body land in this process's `erl.<id>.stderr.log`. A reply longer than `max_frame_len`
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
const serverSource = @import("./server_source.zig");
const beamFile = @import("../../codegen/beam/beam_file.zig");
const etf = @import("./etf.zig");
const beamProgram = @import("beam/program.zig");
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

/// The three resident modules as `.beam` bytes — the server
/// (`server_source.zig`) and the two comptime preludes (`prelude.zig`).
/// `erlc +deterministic` compiled them at `zig build` time (root `build.zig`,
/// "resident comptime modules") and the build hands them here as anonymous
/// imports. Decision 83: the Erlang compiler is a dependency of building this
/// compiler, not of running it. Their release is the `erlc`'s that built the
/// binary — on CI OTP 28, decision 86's floor — and a `.beam` loads on the
/// release that made it and later ones.
const ResidentBeam = struct {
    name: []const u8,
    bytes: []const u8,
};

const resident_beams = [_]ResidentBeam{
    .{ .name = serverSource.module_name, .bytes = @embedFile("botopink_comptime_server.beam") },
    .{ .name = preludeMod.template_module, .bytes = @embedFile("bp_comptime_template.beam") },
    .{ .name = preludeMod.decorator_module, .bytes = @embedFile("bp_comptime_decorator.beam") },
};

/// Decision 86's floor: the oldest Erlang/OTP release the comptime runtime runs
/// on. The spawn bootstrap refuses an older `erl` before loading anything, with
/// a message naming both releases (`error.PersistentErlBelowFloor`); the
/// assembled modules' `opcode_max` stamp (`codegen/beam/beam_file.zig`) makes
/// the VM's own loader refuse them below it too.
pub const otp_floor = 28;

const below_floor_tag = "__BP_ERL_BELOW_FLOOR__:";
const load_error_tag = "__BP_ERL_LOAD_ERROR__:";

/// What `erl -noshell -eval` runs at spawn: check the floor, read
/// `resident_beams.len` cmd-4 frames from stdin and `code:load_binary/3` each,
/// answer one frame — `ok`, or a tagged refusal — and hand the pipes to the
/// server's `start/0`. It is `erl_eval`-interpreted source, so it runs on any
/// release and can report a floor violation the embedded `.beam`s could not
/// (they would simply fail to load). The logger handler moves to stderr
/// before the first load: a loader's `=ERROR REPORT` would otherwise land on
/// stdout ahead of the refusal frame and read as a multi-GiB length. `halt()`
/// after `start()` returns (stdin EOF — the parent exited) ends the VM;
/// without it `-noshell` keeps an orphan `beam.smp` alive forever.
const bootstrap_eval = bootstrap_bindings ++
    \\ok = io:setopts(standard_io, [binary, {encoding, latin1}]),
    \\_ = logger:remove_handler(default),
    \\ok = logger:add_handler(default, logger_std_h, #{config => #{type => standard_error}}),
    \\Rel = list_to_integer(erlang:system_info(otp_release)),
    \\Read = fun(N) -> {ok, D} = file:read(standard_io, N), D end,
    \\Reply = fun(Text) -> B = iolist_to_binary(Text), file:write(standard_io, <<(byte_size(B)):32, B/binary>>) end,
    \\if Rel < Floor -> Reply(io_lib:format("__BP_ERL_BELOW_FLOOR__:erl is Erlang/OTP ~p; the compiler's embedded comptime runtime needs OTP ~p or later", [Rel, Floor])), halt(3); true -> ok end,
    \\Load = fun() -> <<Len:32>> = Read(4), <<4:8, NL:16, Name:NL/binary, Beam/binary>> = Read(Len), Mod = binary_to_atom(Name, latin1), case code:load_binary(Mod, "", Beam) of {module, Mod} -> ok; {error, R} -> {Mod, R} end end,
    \\case [E || E <- [Load() || _ <- lists:seq(1, Count)], E =/= ok] of
    \\    [] -> Reply(<<"ok">>), Server:start();
    \\    Errs -> Reply(io_lib:format("__BP_ERL_LOAD_ERROR__:~p; erl is Erlang/OTP ~p and the embedded modules were compiled by the erlc that built this compiler", [Errs, Rel])), halt(3)
    \\end,
    \\halt().
;

/// The bootstrap's three constants, bound ahead of it: decision 86's floor, the
/// number of resident modules to expect, and the server module to start.
const bootstrap_bindings = std.fmt.comptimePrint(
    "Floor = {d}, Count = {d}, Server = {s},\n",
    .{ otp_floor, resident_beams.len, serverSource.module_name },
);

/// Largest reply frame `readFrame` accepts. A reply is a comptime body's
/// generated code or JSON outcome — kilobytes. A prefix past this is text that
/// reached stdout outside a frame (`=INF` of an `=INFO REPORT` reads as
/// 1 028 214 342 bytes), so it fails as a transport error, not an allocation.
pub const max_frame_len: u32 = 16 * 1024 * 1024;

/// Root of the runtime's files, relative to the cwd. Only the stderr log lives
/// here now; the resident modules never touch the disk.
const server_dir = ".botopinkbuild/tmp/persistent_beam";

/// erl's stderr: the logger's output and everything a comptime body prints.
/// Truncated at every spawn; nothing reads it back — transport errors name it.
///
/// **Per process.** `server_dir` is fixed and the checkout is shared, so two
/// compilers with this cwd (parallel tests, two `zig build test` runs, a gate
/// and a developer) used to hand their two `erl` children ONE log path: the
/// second spawn truncated the file the first child was still writing to, and
/// the transport diagnostic that names the log pointed at a mixture of both.
/// 64 random bits drawn once per process keep each child's stderr its own. The
/// directory sits under `TMP_ROOT`, so `clean-tmp` reaps it after a day.
const log_stem = server_dir ++ "/erl.";
const log_ext = ".stderr.log";
var stderr_log_buf: [log_stem.len + 16 + log_ext.len]u8 = undefined;
var stderr_log_ready = false;

/// Draw this process's log path. Called once, under the spawn's init lock.
fn ensureStderrLogPath(io: Io) []const u8 {
    if (!stderr_log_ready) {
        var rand_bytes: [8]u8 = undefined;
        io.random(&rand_bytes);
        _ = std.fmt.bufPrint(&stderr_log_buf, log_stem ++ "{x:0>16}" ++ log_ext, .{
            std.mem.readInt(u64, &rand_bytes, .little),
        }) catch unreachable;
        stderr_log_ready = true;
    }
    return &stderr_log_buf;
}

/// The log path a diagnostic names. Before the first spawn there is none yet,
/// and the pattern is more use than a name that does not exist.
fn stderrLogPath() []const u8 {
    if (stderr_log_ready) return &stderr_log_buf;
    return log_stem ++ "<id>" ++ log_ext;
}

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

/// Lazy-spawn the persistent `erl` process: `erl -noshell -eval <bootstrap>`,
/// then the handshake that loads the embedded resident modules into it.
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
            transport_error_len = 0;

            // stderr goes to a log file, never inherited: an orphan holding the
            // parent's stderr open blocks whoever waits for its EOF (the
            // `zig build test` runner reports "test runner failed to respond").
            const cwd = std.Io.Dir.cwd();
            try cwd.createDirPath(io, server_dir);
            const stderr_log = try cwd.createFile(io, ensureStderrLogPath(io), .{});
            defer stderr_log.close(io);
            const child = try std.process.spawn(io, .{
                .argv = &.{ "erl", "-noshell", "-eval", bootstrap_eval },
                .stdin = .pipe,
                .stdout = .pipe,
                .stderr = .{ .file = stderr_log },
            });
            state = .{
                .child = child,
                .stdin = child.stdin orelse return error.NoStdin,
                .stdout = child.stdout orelse return error.NoStdout,
            };
            handshake(io, allocator) catch |err| {
                state.child.kill(io);
                return err;
            };
            init_state.store(2, .release);
            return;
        }
        std.atomic.spinLoopHint();
    }
}

/// Hand the embedded `.beam`s to the freshly spawned node and read its one
/// handshake frame. `ok` means every resident module is loaded and the server
/// loop owns the pipes; anything else is the bootstrap's refusal, kept in
/// `lastTransportError` so the evaluators' diagnostic carries it.
fn handshake(io: Io, allocator: std.mem.Allocator) !void {
    for (resident_beams) |m| {
        const payload = try namedPayload(allocator, m.name, m.bytes);
        defer allocator.free(payload);
        try sendFrame(io, 4, payload);
    }
    const reply = readFrame(io, state.stdout, allocator) catch |err| {
        if (transport_error_len == 0) setTransportError("{s} while the erl node loaded the embedded comptime runtime", .{@errorName(err)});
        return error.PersistentErlBroken;
    };
    defer allocator.free(reply);
    if (std.mem.eql(u8, reply, "ok")) return;
    if (std.mem.startsWith(u8, reply, below_floor_tag)) {
        setTransportError("{s}", .{reply[below_floor_tag.len..]});
        return error.PersistentErlBelowFloor;
    }
    const detail = if (std.mem.startsWith(u8, reply, load_error_tag)) reply[load_error_tag.len..] else reply;
    setTransportError("the erl node could not load the embedded comptime runtime: {s}", .{detail});
    return error.PersistentErlBroken;
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
    // The log path is per process (see `ensureStderrLogPath`), so the suffix is
    // appended as a value rather than concatenated into the format string.
    const head = std.fmt.bufPrint(&transport_error_buf, fmt, args) catch blk: {
        const fallback = "transport error";
        @memcpy(transport_error_buf[0..fallback.len], fallback);
        break :blk transport_error_buf[0..fallback.len];
    };
    const tail = std.fmt.bufPrint(transport_error_buf[head.len..], " (erl stderr: {s})", .{stderrLogPath()}) catch "";
    transport_error_len = head.len + tail.len;
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
    /// `code:load_binary/3` rejected the bytes (`~p` of `{load_binary, Mod, Reason}`).
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

/// Send one command and classify the reply, the pipes' lock held — a caller
/// that sends two commands in a row (`evalBeamWithArg`: load, then call) holds
/// one lock rather than racing another thread between them. A transport
/// failure (erl died, short/garbled frame) kills the child and marks the
/// singleton broken so the next request respawns a fresh process instead of
/// reading a desynced pipe.
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

/// Module atoms this process has had the node load (cmd 4). Keys are
/// owned by `loaded_keys` and live as long as the process: their number is
/// bounded by the declarations in the build, not by the call sites. Read and
/// written only under `io_mu`, and cleared when the child is respawned.
var loaded: std.StringHashMapUnmanaged(void) = .empty;
const loaded_keys = std.heap.page_allocator;

/// Call `<module>:main(<arg>)` in the node, loading `beam` first — cmd 4, bytes
/// in the frame, no file, no compiler — the first time this process sees
/// `module`. `arg` is an external term (`etf.encode`), so nothing about the
/// call site is in the module — which is what lets one module serve every call
/// site of a declaration.
pub fn evalBeamWithArg(
    allocator: std.mem.Allocator,
    io: Io,
    beam: []const u8,
    module: []const u8,
    arg: []const u8,
) !Response {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();

    if (!loaded.contains(module)) {
        const response = blk: {
            const payload = try namedPayload(allocator, module, beam);
            defer allocator.free(payload);
            break :blk try requestLocked(allocator, io, 4, payload);
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

/// `source` as `.beam` bytes: the text lowered and assembled by the comptime
/// BEAM path (`beam/program.zig`), as every generated module now is.
fn testBeam(module: []const u8, source: []const u8) ![]const u8 {
    return switch (try beamProgram.build(module, module, source)) {
        .ok => |ok| ok.beam,
        .refused => |why| {
            std.debug.print("refused: {s}\n", .{why});
            return error.TestUnexpectedResult;
        },
    };
}

/// `main(_)`'s reply for `module` (its `.beam`), expected to be `expected`.
fn expectOk(expected: []const u8, module: []const u8, beam: []const u8) !void {
    const response = try evalBeamWithArg(std.testing.allocator, std.testing.io, beam, module, "\x83\x6a");
    defer std.testing.allocator.free(response.payload());
    try std.testing.expectEqual(std.meta.Tag(Response).ok, std.meta.activeTag(response));
    try std.testing.expectEqualStrings(expected, response.payload());
}

const noisy_module =
    \\-module(bp_persistent_beam_noisy).
    \\-export([main/1]).
    \\
    \\main(_) ->
    \\    io:format("io:format/1 from a comptime body~n"),
    \\    io:format(standard_io, "~p~n", [standard_io_noise]),
    \\    logger:error("logger event from a comptime body"),
    \\    spawn(fun() -> io:format("a process the body spawned~n") end),
    \\    <<"clean reply">>.
    \\
;

test "persistent_beam: a comptime body's io:format and logger output stay off the frame stream" {
    const beam = try testBeam("bp_persistent_beam_noisy", noisy_module);
    // Twice: output that lands late (the logger handler, the spawned process)
    // would corrupt the second reply's length prefix, not the first.
    try expectOk("clean reply", "bp_persistent_beam_noisy", beam);
    try expectOk("clean reply", "bp_persistent_beam_noisy", beam);
    try std.testing.expectEqual(@as(?[]const u8, null), lastTransportError());
}

test "persistent_beam: a reply frame over the length cap is a transport error, then the server respawns" {
    // `user` is the server's own stdout: bytes written there bypass the group
    // leader and read as a 0x7FFFFFFF length prefix.
    const corrupt = try testBeam("bp_persistent_beam_corrupt",
        \\-module(bp_persistent_beam_corrupt).
        \\-export([main/1]).
        \\
        \\main(_) ->
        \\    file:write(user, <<127, 255, 255, 255>>),
        \\    <<"unreachable">>.
        \\
    );
    const noisy = try testBeam("bp_persistent_beam_noisy", noisy_module);

    try std.testing.expectError(
        error.PersistentErlFrameTooLarge,
        evalBeamWithArg(std.testing.allocator, std.testing.io, corrupt, "bp_persistent_beam_corrupt", "\x83\x6a"),
    );
    const message = lastTransportError() orelse return error.TestExpectedTransportMessage;
    try std.testing.expect(std.mem.indexOf(u8, message, "exceeds the 16777216-byte cap") != null);
    try std.testing.expect(std.mem.indexOf(u8, message, stderrLogPath()) != null);

    // The respawned node has loaded nothing: the module is sent again.
    try expectOk("clean reply", "bp_persistent_beam_noisy", noisy);
}

test "persistent_beam: the embedded resident modules are .beam files of their atoms" {
    // The server and both comptime preludes, compiled by `erlc` at `zig build`.
    try std.testing.expectEqual(@as(usize, 3), resident_beams.len);
    for (resident_beams) |m| {
        try std.testing.expectEqualSlices(u8, "FOR1", m.bytes[0..4]);
        try std.testing.expectEqualSlices(u8, "BEAM", m.bytes[8..12]);
        // The module atom sits in the `AtU8` table.
        try std.testing.expect(std.mem.indexOf(u8, m.bytes, m.name) != null);
    }
    // The bootstrap names the floor, the count and the server it starts.
    try std.testing.expect(std.mem.startsWith(u8, bootstrap_eval, "Floor = 28, Count = 3, Server = botopink_comptime_server,\n"));
    try std.testing.expect(std.mem.indexOf(u8, bootstrap_eval, "if Rel < Floor ->") != null);
    try std.testing.expect(std.mem.indexOf(u8, bootstrap_eval, "Server:start()") != null);
}

test "persistent_beam: readFrame rejects a stray =INFO REPORT before allocating" {
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

/// `-module(bp_persistent_beam_echo). -export([main/1]). main(X) -> X.` assembled
/// by `codegen/beam/beam_file.zig` — the argument arrives in `{x, 0}` and is the
/// reply, so the frame that comes back is the ETF-decoded term as iodata.
fn echoBeam(allocator: std.mem.Allocator) ![]u8 {
    const S = struct {
        const m = "bp_persistent_beam_echo";
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

test "persistent_beam: cmd 4 loads .beam bytes in-frame and cmd 3 calls main/1 on them" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const beam = try echoBeam(allocator);
    defer allocator.free(beam);
    const module = "bp_persistent_beam_echo";

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
    const rejected = try evalBeamWithArg(allocator, io, garbage, "bp_persistent_beam_garbage", "\x83\x6a");
    defer allocator.free(rejected.payload());
    try std.testing.expectEqual(std.meta.Tag(Response).compile_error, std.meta.activeTag(rejected));
    try std.testing.expect(std.mem.indexOf(u8, rejected.payload(), "load_binary") != null);
    try std.testing.expect(std.mem.indexOf(u8, rejected.payload(), "badfile") != null);
    try std.testing.expect(!loaded.contains("bp_persistent_beam_garbage"));
}

test "persistent_beam: readFrame returns a payload under the cap" {
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
