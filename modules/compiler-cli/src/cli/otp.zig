/// The OTP check of every erlang and beam run (decision 228 of 1.0.11-beta).
///
/// The compiler emits Erlang for one release, `manifest.OTP_RELEASE`; the
/// `erl` / `erlc` on `PATH` decide which release the emitted code is checked
/// and run against. A machine on another release than CI once kept the gate
/// green on a module the CI release refuses (`erlang:element(2, C)(9)`, accepted
/// by OTP 29, a syntax error for 28). So before `botopink build | run | test
/// --target erlang | beam` spawns anything else, it asks the `erl` on `PATH`
/// for its release and refuses another one — before any `.erl` is written. No
/// flag, variable or manifest value turns the refusal into a warning (decision
/// 67); a manifest's `"otp"` can only name the same release (`manifest.closureOtp`).
const std = @import("std");
const manifest = @import("manifest");
const reporter = @import("./reporter.zig");
const arglist = @import("./arglist.zig");

/// The release the compiler emits for — the one constant, owned by `manifest`.
pub const RELEASE = manifest.OTP_RELEASE;

/// What the probe evaluates: the release, alone on stdout, no newline.
pub const PROBE_EVAL = "io:format(\"~s\",[erlang:system_info(otp_release)]),halt().";

/// Ask the `erl` on `PATH` for its release and compare it with `RELEASE`.
/// False, with the refusal printed, when it differs or cannot be read.
pub fn check(arena: std.mem.Allocator, io: std.Io) !bool {
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-eval", PROBE_EVAL };
    const result = std.process.run(arena, io, .{
        .argv = argv,
        .stdout_limit = .limited(4096),
        .stderr_limit = .limited(64 * 1024),
    }) catch |err| {
        reporter.errMsg(try std.fmt.allocPrint(arena, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and {s} — install OTP " ++ RELEASE ++ " and put it on PATH", .{arglist.spawnError(arena, "erl", argv, err)}));
        return false;
    };
    const code: ?u8 = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => null,
    };
    if (try refusal(arena, code, result.stdout)) |msg| {
        if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};
        reporter.errMsg(msg);
        return false;
    }
    return true;
}

/// The refusal for a probe that exited with `code` (null: killed) and printed
/// `stdout`, or null when it named `RELEASE`.
fn refusal(arena: std.mem.Allocator, code: ?u8, stdout: []const u8) std.mem.Allocator.Error!?[]const u8 {
    const release = std.mem.trim(u8, stdout, " \t\r\n");
    if (code != 0 or release.len == 0)
        return try std.fmt.allocPrint(arena, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and `erl` on PATH did not name its release ({s}) — install OTP " ++ RELEASE ++ " and put it on PATH", .{if (code) |c| try std.fmt.allocPrint(arena, "exit {d}", .{c}) else "killed"});
    if (std.mem.eql(u8, release, RELEASE)) return null;
    return try std.fmt.allocPrint(arena, "botopink emits Erlang for OTP " ++ RELEASE ++ ", and `erl` on PATH is OTP {s} — install OTP " ++ RELEASE ++ " and put it on PATH", .{release});
}

test "otp: the release the compiler emits for passes, another one and a silent erl are refused" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try std.testing.expect((try refusal(a, 0, RELEASE)) == null);
    try std.testing.expect((try refusal(a, 0, RELEASE ++ "\n")) == null);
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it on PATH",
        (try refusal(a, 0, "29")).?,
    );
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH did not name its release (exit 1) — install OTP 28 and put it on PATH",
        (try refusal(a, 1, "")).?,
    );
    try std.testing.expectEqualStrings(
        "botopink emits Erlang for OTP 28, and `erl` on PATH did not name its release (killed) — install OTP 28 and put it on PATH",
        (try refusal(a, null, RELEASE)).?,
    );
}
