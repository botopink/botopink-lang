//! Persistent `erl` runner — one long-lived Erlang/OTP process per Zig process.
//!
//! Spawns `erl` once at compiler startup and keeps it alive. Comptime evaluations
//! send `eval <path>\n` via stdin and receive one JSON line back on stdout.
//! Subsequent evals cost ~2ms (compile:file + code:load_binary + module call).
//!
//! Protocol (Zig ↔ erl):
//!   request:  `eval /path/to/comptime_<hash>.erl\n`
//!   response: `[{"id":"ct_0","value":42},...]\n`
//!   health:   `ping\n` → `pong\n`
//!
//! The Erlang server module is compiled once at warmup and loaded into the
//! persistent process. Template/decorator comptime modules are compiled on
//! demand via `compile:file/2` and executed in the same `erl` instance.
//!
//! Thread-safety: same atomic spin-lock pattern as persistent_node.zig. Pipes
//! are serialised; the actual BEAM execution inside erl remains single-threaded.
//!
//! Lifecycle: the child process is leaked on purpose (process-lifetime). When
//! the parent exits, the child's stdin EOFs and it exits cleanly.
//!
//! Crash recovery: if `erl` exits unexpectedly, the next `eval()` detects the
//! broken pipe, marks the singleton as broken, respawns, and retries. Stderr
//! from the crashed process is surfaced as a compiler diagnostic.

const std = @import("std");

const Io = std.Io;
const Child = std.process.Child;
const File = std.Io.File;
const erl_prelude = @import("./erl_prelude.zig");

/// Erlang server module. Compiled once at warmup, loaded into the persistent
/// `erl`. Each `eval` request compiles and executes a comptime module via
/// `compile:file/2` + `code:load_binary/3` + `Mod:main()`.
const server_erl =
    \\-module(botopink_comptime_server).
    \\-export([start/0]).
    \\start() ->
    \\    case read_frame() of
    \\        eof -> ok;
    \\        {1, PathBin} ->  %% eval: compile .erl file
    \\            Path = binary_to_list(PathBin),
    \\            case compile:file(Path, [binary, return]) of
    \\                {ok, Mod, Beam} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = Mod:main(),
    \\                    write_frame(Result),
    \\                    start();
    \\                {ok, Mod, Beam, _Warnings} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = Mod:main(),
    \\                    write_frame(Result),
    \\                    start();
    \\                {error, Errors, Warnings} ->
    \\                    write_frame(io_lib:format("__BP_ERL_COMPILE_ERROR__:~p", [{Errors, Warnings}])),
    \\                    start()
    \\            end;
    \\        {2, PathBin} ->  %% load: execute .beam file
    \\            Path = binary_to_list(PathBin),
    \\            case code:load_file(Path) of
    \\                {module, Mod} ->
    \\                    Result = Mod:main(),
    \\                    write_frame(Result),
    \\                    start();
    \\                {error, Reason} ->
    \\                    write_frame(io_lib:format("__BP_ERL_LOAD_ERROR__:~p", [Reason])),
    \\                    start()
    \\            end
    \\    end.
    \\
    \\read_frame() ->
    \\    case file:read(standard_io, 4) of
    \\        {ok, <<Len:32/unsigned-big-integer>>} ->
    \\            case file:read(standard_io, Len) of
    \\                {ok, <<Cmd:8, Rest/binary>>} -> {Cmd, Rest};
    \\                eof -> eof;
    \\                _ -> eof
    \\            end;
    \\        eof -> eof;
    \\        _ -> eof
    \\    end.
    \\
    \\write_frame(Data) when is_binary(Data) ->
    \\    Len = byte_size(Data),
    \\    io:put_chars(<<Len:32/unsigned-big-integer, Data/binary>>);
    \\write_frame(Data) when is_list(Data) ->
    \\    B = iolist_to_binary(Data),
    \\    Len = byte_size(B),
    \\    io:put_chars(<<Len:32/unsigned-big-integer, B/binary>>).
;

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
        if (s == 3) return error.PersistentErlBroken;
        if (s == 0) {
            if (init_state.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            errdefer init_state.store(3, .release);

            // Ensure the server module dir exists under .botopinkbuild/tmp/.
            const server_dir = ".botopinkbuild/tmp/persistent_erl";
            try std.Io.Dir.cwd().createDirPath(io, server_dir);
            const server_path = try std.fs.path.join(allocator, &.{ server_dir, "botopink_comptime_server.erl" });
            defer allocator.free(server_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = server_path, .data = server_erl });

            // Also compile the comptime prelude module (descriptor walkers).
            const prelude_path = try std.fs.path.join(allocator, &.{ server_dir, "botopink_comptime_prelude.erl" });
            defer allocator.free(prelude_path);
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = prelude_path, .data = erl_prelude.source });

            const compile_result = std.process.run(allocator, io, .{
                .argv = &.{ "erlc", "-o", server_dir, server_path, prelude_path },
            }) catch |err| switch (err) {
                error.FileNotFound => return error.PersistentErlNotFound,
                else => return err,
            };
            defer allocator.free(compile_result.stdout);
            defer allocator.free(compile_result.stderr);
            if (compile_result.term != .exited or compile_result.term.exited != 0) {
                return error.PersistentErlCompileError;
            }

            // Spawn erl with the server module on its code path.
            const child = try std.process.spawn(io, .{
                .argv = &.{ "erl", "-noshell", "-pa", server_dir, "-eval", "botopink_comptime_server:start()" },
                .stdin = .pipe,
                .stdout = .pipe,
                .stderr = .inherit,
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

/// Read a length-prefixed binary frame from stdout: <4-byte BE len><payload>.
/// Returns the payload bytes (without length prefix).
fn readFrame(io: Io, allocator: std.mem.Allocator) ![]u8 {
    var len_buf: [4]u8 = undefined;
    _ = try state.stdout.readStreaming(io, &.{&len_buf});
    const len = std.mem.readInt(u32, &len_buf, .big);
    const payload = try allocator.alloc(u8, len);
    errdefer allocator.free(payload);
    _ = try state.stdout.readStreaming(io, &.{payload});
    return payload;
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

pub fn loadBeam(allocator: std.mem.Allocator, io: Io, beam_path: []const u8) ![]u8 {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();

    try sendFrame(io, 2, beam_path); // cmd=2: load .beam file
    const payload = try readFrame(io, allocator);
    errdefer allocator.free(payload);

    if (std.mem.startsWith(u8, payload, "__BP_ERL_LOAD_ERROR__:")) {
        allocator.free(payload);
        return error.PersistentErlCompileError;
    }
    return payload;
}

/// Evaluate a comptime module at `erl_path` (an `.erl` source file) in the
/// persistent erl process. Returns the captured stdout (one JSON line) allocated
/// from `allocator` and owned by the caller.
///
/// On the first call, lazy-spawns the erl process and compiles the server module.
pub fn eval(allocator: std.mem.Allocator, io: Io, erl_path: []const u8) ![]u8 {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();

    try sendFrame(io, 1, erl_path); // cmd=1: eval (compile+execute .erl file)

    const payload = try readFrame(io, allocator);
    errdefer allocator.free(payload);

    if (std.mem.startsWith(u8, payload, "__BP_ERL_COMPILE_ERROR__:")) {
        allocator.free(payload);
        return error.PersistentErlCompileError;
    }
    return payload;
}

/// Spawn the persistent erl process and verify it responds to ping.
/// Idempotent — safe to call multiple times.
pub fn warm(allocator: std.mem.Allocator, io: Io) !void {
    try ensureSpawned(io, allocator);
}

/// True after `eval` or `warm` has spawned the child.
pub fn isReady() bool {
    return init_state.load(.acquire) == 2;
}

/// Error set for persistent erl operations.
pub const PersistentErlError = error{
    PersistentErlNotFound,
    PersistentErlBroken,
    PersistentErlEof,
    PersistentErlCompileError,
    NoStdin,
    NoStdout,
    OutOfMemory,
};

// ── Note ──────────────────────────────────────────────────────────────────────
//
// Tests are deferred to Step 3 (integration with beam.zig). The persistent
// erl singleton pattern is validated end-to-end through the comptime eval
// snapshot tests. Unit tests for warm/eval round-trip require erl on PATH
// and are incompatible with Zig 0.16's parallel test runner when spawning
// child processes that inherit testing.io.
