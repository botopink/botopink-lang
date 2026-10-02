//! The one OTP release check (decision 228 of 1.0.11-beta), for every `erl`,
//! `erlc` and `escript` the compiler spawns.
//!
//! The compiler emits Erlang for one release, `manifest.OTP_RELEASE`. Before
//! anything Erlang starts — the comptime node (`comptime/runtime/persistent_beam.zig`),
//! a RUN LOG executor (`codegen/runtime.zig`), the CLI's compile check, runner
//! and host-module probe (`compiler-cli/src/cli/otp.zig`, which asks first) —
//! `refusal` answers whether the `erl` on PATH runs that release. The probe
//! (`erl -noshell -eval <PROBE_EVAL>`) runs once per process; every later
//! caller reads its verdict. A spawn that already asked — the CLI's compile
//! session prints the release first — hands its answer in (`adopt`) and no
//! probe runs. Every `erl` the compiler starts carries `QUIET_FLAGS`. No
//! flag, variable or manifest value turns a refusal into a warning (decision
//! 67).
const std = @import("std");

/// The release the compiler emits for — the one constant, owned by `manifest`.
pub const RELEASE = @import("manifest").OTP_RELEASE;

/// What the probe evaluates: the release, alone on stdout, no newline.
pub const PROBE_EVAL = "io:format(\"~s\",[erlang:system_info(otp_release)]),halt().";

/// Every `erl` the compiler starts gets these emulator flags: an idle
/// scheduler (normal, dirty CPU, dirty IO) does not busy-wait before it
/// sleeps. A short-lived VM spent ~0.21 of its ~0.34 CPU-s start spinning
/// (1.0.11-beta front 133); the flags change only how long an idle scheduler
/// polls, never what runs. On the command line, so a user's `ERL_FLAGS`
/// (read after it) still wins.
pub const QUIET_FLAGS = [_][]const u8{ "+sbwt", "none", "+sbwtdcpu", "none", "+sbwtdio", "none" };

/// `QUIET_FLAGS` as one `ERL_AFLAGS` value, for a child whose `erl` command
/// line the compiler does not write (`escript`, `erlc`).
pub const QUIET_AFLAGS = "+sbwt none +sbwtdcpu none +sbwtdio none";

/// What a spawn site returns when `refusal` answered a message.
pub const Error = error{OtpReleaseRefused};

/// 0: not probed · 1: probing · 2: verdict in `verdict_buf[0..verdict_len]`
/// (empty = the release is the compiler's).
var state = std.atomic.Value(u8).init(0);
var verdict_buf: [512]u8 = undefined;
var verdict_len: usize = 0;

/// Null when the `erl` on PATH runs `RELEASE`; else the refusal, naming both
/// releases (or why the release could not be read). Probes once per process.
pub fn refusal(io: std.Io) ?[]const u8 {
    while (true) {
        switch (state.load(.acquire)) {
            2 => return if (verdict_len == 0) null else verdict_buf[0..verdict_len],
            0 => if (state.cmpxchgStrong(0, 1, .acquire, .acquire) == null) {
                verdict_len = probe(io).len;
                state.store(2, .release);
            },
            else => std.atomic.spinLoopHint(),
        }
    }
}

/// `refusal`, printed as an `error:` line when there is one.
pub fn check(io: std.Io) Error!void {
    if (refusal(io)) |msg| {
        std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{msg});
        return error.OtpReleaseRefused;
    }
}

/// Record the verdict of a release question another spawn asked — the CLI's
/// compile session prints the release as its first line
/// (`compiler-cli/src/cli/otp.zig`) — so no probe runs: `code` is how that
/// `erl` exited (0 while it runs on; null: killed), `stdout` what it printed
/// before. Ignored once a verdict exists or a probe is under way.
pub fn adopt(code: ?u8, stdout: []const u8) void {
    if (state.cmpxchgStrong(0, 1, .acquire, .acquire) != null) return;
    verdict_len = message(&verdict_buf, code, stdout).len;
    state.store(2, .release);
}

/// `adopt` for an `erl` that could not be spawned at all.
pub fn adoptSpawnError(err: anyerror) void {
    if (state.cmpxchgStrong(0, 1, .acquire, .acquire) != null) return;
    verdict_len = spawnMessage(&verdict_buf, err).len;
    state.store(2, .release);
}

fn spawnMessage(buf: []u8, err: anyerror) []const u8 {
    return std.fmt.bufPrint(buf, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and `erl` could not be run: {s} — install OTP " ++ RELEASE ++ " and put it on PATH", .{@errorName(err)}) catch buf[0..0];
}

fn probe(io: std.Io) []const u8 {
    var arena_inst = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_inst.deinit();
    // The probe compiles nothing and runs no user code: one scheduler.
    const result = std.process.run(arena_inst.allocator(), io, .{
        .argv = &([_][]const u8{"erl"} ++ QUIET_FLAGS ++ [_][]const u8{ "+S", "1:1", "-noshell", "-eval", PROBE_EVAL }),
        .stdout_limit = .limited(4096),
        .stderr_limit = .limited(64 * 1024),
    }) catch |err| {
        return spawnMessage(&verdict_buf, err);
    };
    const code: ?u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => null,
    };
    return message(&verdict_buf, code, result.stdout);
}

/// The refusal for a probe that exited with `code` (null: killed) and printed
/// `stdout`, written into `buf`; empty when it named `RELEASE`.
fn message(buf: []u8, code: ?u8, stdout: []const u8) []const u8 {
    const release = std.mem.trim(u8, stdout, " \t\r\n");
    if (code != 0 or release.len == 0) {
        var what: [32]u8 = undefined;
        const why = if (code) |c| std.fmt.bufPrint(&what, "exit {d}", .{c}) catch "exit ?" else "killed";
        return std.fmt.bufPrint(buf, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and `erl` on PATH did not name its release ({s}) — install OTP " ++ RELEASE ++ " and put it on PATH", .{why}) catch buf[0..0];
    }
    if (std.mem.eql(u8, release, RELEASE)) return buf[0..0];
    return std.fmt.bufPrint(buf, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and `erl` on PATH is OTP {s} — install OTP " ++ RELEASE ++ " and put it on PATH", .{release[0..@min(release.len, 64)]}) catch buf[0..0];
}

test "otp: the release the compiler emits for passes, another one and a silent erl are refused" {
    var buf: [512]u8 = undefined;
    try std.testing.expectEqualStrings("", message(&buf, 0, RELEASE));
    try std.testing.expectEqualStrings("", message(&buf, 0, RELEASE ++ "\n"));
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it on PATH",
        message(&buf, 0, "29"),
    );
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH did not name its release (exit 1) — install OTP 28 and put it on PATH",
        message(&buf, 1, ""),
    );
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH did not name its release (killed) — install OTP 28 and put it on PATH",
        message(&buf, null, RELEASE),
    );
}
