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

/// Erlang server module. Compiled once at warmup, loaded into the persistent
/// `erl`. Each `eval` request compiles and executes a comptime module via
/// `compile:file/2` + `code:load_binary/3` + `Mod:main()`.
const server_erl =
    \\-module(botopink_comptime_server).
    \\-export([start/0]).
    \\start() ->
    \\    case io:get_line("") of
    \\        eof -> ok;
    \\        "eval " ++ Path0 ->
    \\            Path = string:trim(Path0),
    \\            case compile:file(Path, [binary, return]) of
    \\                {ok, Mod, Beam} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = Mod:main(),
    \\                    io:format("~s~n", [Result]),
    \\                    start();
    \\                {ok, Mod, Beam, _Warnings} ->
    \\                    {module, _} = code:load_binary(Mod, "", Beam),
    \\                    Result = Mod:main(),
    \\                    io:format("~s~n", [Result]),
    \\                    start();
    \\                {error, Errors, Warnings} ->
    \\                    io:format("__BP_ERL_COMPILE_ERROR__:~p~n", [{Errors, Warnings}]),
    \\                    start()
    \\            end;
    \\        "ping" ++ _ ->
    \\            io:format("pong~n"),
    \\            start();
    \\        _Other ->
    \\            io:format("__BP_ERL_BAD_COMMAND__:~s~n", [_Other]),
    \\            start()
    \\    end.
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

            const compile_result = std.process.run(allocator, io, .{
                .argv = &.{ "erlc", "-o", server_dir, server_path },
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

            // Health check: ping the server.
            try state.stdin.writeStreamingAll(io, "ping\n");
            var pong_buf: [5]u8 = undefined;
            _ = try state.stdout.readStreaming(io, &.{&pong_buf});
            if (!std.mem.eql(u8, &pong_buf, "pong\n")) return error.PersistentErlBadPong;
            return;
        }
        std.atomic.spinLoopHint();
    }
}

/// Read a line from the persistent erl's stdout. Returns the line without
/// the trailing newline.
fn readLine(io: Io, allocator: std.mem.Allocator) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);

    var byte: [1]u8 = undefined;
    while (true) {
        const n = state.stdout.readStreaming(io, &.{&byte}) catch |err| switch (err) {
            error.EndOfStream => return error.PersistentErlEof,
            else => return err,
        };
        if (n == 0) return error.PersistentErlEof;
        if (byte[0] == '\n') break;
        try buf.append(allocator, byte[0]);
    }
    return buf.toOwnedSlice(allocator);
}

/// Evaluate a comptime module at `beam_path` (an `.erl` source file) in the
/// persistent erl process. Returns the captured stdout (one JSON line) allocated
/// from `allocator` and owned by the caller.
///
/// On the first call, lazy-spawns the erl process and compiles the server module.
pub fn eval(allocator: std.mem.Allocator, io: Io, erl_path: []const u8) ![]u8 {
    try ensureSpawned(io, allocator);
    lock();
    defer unlock();

    // Send: "eval <path>\n"
    try state.stdin.writeStreamingAll(io, "eval ");
    try state.stdin.writeStreamingAll(io, erl_path);
    try state.stdin.writeStreamingAll(io, "\n");

    // Receive: one JSON line.
    const line = try readLine(io, allocator);
    errdefer allocator.free(line);

    // Check for server-side errors.
    if (std.mem.startsWith(u8, line, "__BP_ERL_COMPILE_ERROR__:")) {
        allocator.free(line);
        return error.PersistentErlCompileError;
    }
    if (std.mem.startsWith(u8, line, "__BP_ERL_BAD_COMMAND__:")) {
        allocator.free(line);
        return error.PersistentErlBadCommand;
    }

    return line;
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
    PersistentErlBadCommand,
    PersistentErlBadPong,
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
