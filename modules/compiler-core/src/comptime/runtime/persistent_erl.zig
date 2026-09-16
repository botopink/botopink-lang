//! Persistent `erl` runner — one long-lived Erlang/OTP process per Zig process.
//!
//! Spawns `erl` lazily on the first request and keeps it alive. Comptime
//! evaluators write a module to disk and ask the server to run it; evals after
//! the first cost ~2ms (compile:file + code:load_binary + module call).
//!
//! Protocol (Zig ↔ erl), length-prefixed binary frames both ways:
//!   request:  <u32 BE len><cmd:u8><path>   cmd 1 = compile+run `.erl`
//!   response: <u32 BE len><payload>        `main/0`'s iodata result, or an error
//!             payload tagged `__BP_ERL_COMPILE_ERROR__:` /
//!             `__BP_ERL_RUNTIME_ERROR__:` (raise, exit, non-iodata result, timeout)
//!
//! `main/0` runs in a monitored process with a wall-clock budget
//! (`eval_timeout_ms`), so a runaway body is killed instead of wedging the server.
//! `evalDetailed` returns the reply classified as a `Response`.
//!
//! stdout is the frame channel and nothing else may write to it: the server
//! moves the default logger handler to `standard_error`, and `main/0` runs with
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
    \\        {1, PathBin} ->  %% eval: compile .erl file
    \\            Path = binary_to_list(PathBin),
    \\            case compile:file(Path, [binary, return]) of
    \\                {ok, Mod, Beam} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = safe_call(Mod),
    \\                    write_frame(Result),
    \\                    loop();
    \\                {ok, Mod, Beam, _Warnings} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = safe_call(Mod),
    \\                    write_frame(Result),
    \\                    loop();
    \\                {error, Errors, Warnings} ->
    \\                    write_frame(io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{Errors, Warnings}])),
    \\                    loop()
    \\            end
    \\    end.
    \\
    \\%% `Mod:main()` runs in a monitored process so a runaway comptime body
    \\%% (infinite loop, blocked receive) is killed after the timeout instead of
    \\%% wedging the server — and with it every later eval of this compiler run.
    \\%% Its group leader is `standard_error`, not the server's (`user`, the frame
    \\%% channel): `io:format/1`, `io:get_line/1` and every process it spawns talk
    \\%% to stderr, so a printing body cannot desynchronise the frame stream.
    \\safe_call(Mod) ->
    \\    {Pid, Ref} = spawn_monitor(fun() ->
    \\        group_leader(whereis(standard_error), self()),
    \\        Result = try {ok, Mod:main()}
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
    \\        io_lib:format("__BP_ERL_RUNTIME_ERROR__:timeout:main/0 did not return within ~pms", [?EVAL_TIMEOUT_MS])
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
    \\%% Every response is exactly one frame. A `main/0` result that is not iodata
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

/// Where the server module is written and compiled, relative to the cwd.
const server_dir = ".botopinkbuild/tmp/persistent_erl";

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

/// Lazy-spawn the persistent `erl` process. Compiles the server module to
/// `.botopinkbuild/tmp/persistent_erl/` and starts `erl` with it on the code path.
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

            // Ensure the server module dir exists under .botopinkbuild/tmp/.
            try std.Io.Dir.cwd().createDirPath(io, server_dir);
            const server_path = try std.fs.path.join(allocator, &.{ server_dir, "botopink_comptime_server.erl" });
            defer allocator.free(server_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = server_path, .data = server_erl });

            const compile_result = std.process.run(allocator, io, .{
                .argv = &.{ "erlc", "-o", server_dir, server_path },
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

            // Spawn erl with the server module on its code path. `halt()` after
            // `start()` returns (stdin EOF — the parent exited) ends the VM;
            // without it `-noshell` keeps an orphan `beam.smp` alive forever.
            // stderr goes to a log file, never inherited: an orphan holding the
            // parent's stderr open blocks whoever waits for its EOF (the
            // `zig build test` runner reports "test runner failed to respond").
            const stderr_log = try std.Io.Dir.cwd().createFile(io, stderr_log_path, .{});
            defer stderr_log.close(io);
            const child = try std.process.spawn(io, .{
                .argv = &.{ "erl", "-noshell", "-pa", server_dir, "-eval", "botopink_comptime_server:start(), halt()." },
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

/// Send a command frame: <4-byte BE len><cmd byte><path bytes>.
fn sendFrame(io: Io, cmd: u8, path: []const u8) !void {
    const total_len: u32 = @intCast(1 + path.len); // cmd byte + path
    var len_buf: [4]u8 = undefined;
    std.mem.writeInt(u32, &len_buf, total_len, .big);
    try state.stdin.writeStreamingAll(io, &len_buf);
    try state.stdin.writeStreamingAll(io, &.{cmd});
    try state.stdin.writeStreamingAll(io, path);
}

/// One request/reply round trip on the child's pipes.
fn exchange(io: Io, allocator: std.mem.Allocator, cmd: u8, path: []const u8) ![]u8 {
    try sendFrame(io, cmd, path);
    return readFrame(io, state.stdout, allocator);
}

/// Outcome of one request. Every variant's slice is allocated from the
/// caller's allocator and owned by the caller.
pub const Response = union(enum) {
    /// `main/0`'s result.
    ok: []u8,
    /// `compile:file/2` rejected the module (`~p` of `{Errors, Warnings}`).
    compile_error: []u8,
    /// `main/0` raised, exited, returned non-iodata, or timed out.
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
fn request(allocator: std.mem.Allocator, io: Io, cmd: u8, path: []const u8) !Response {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();
    transport_error_len = 0;

    const raw = exchange(io, allocator, cmd, path) catch |err| {
        if (transport_error_len == 0) setTransportError("{s} on the erl frame stream", .{@errorName(err)});
        state.child.kill(io);
        init_state.store(3, .release);
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
pub fn evalDetailed(allocator: std.mem.Allocator, io: Io, erl_path: []const u8) !Response {
    return request(allocator, io, 1, erl_path);
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
