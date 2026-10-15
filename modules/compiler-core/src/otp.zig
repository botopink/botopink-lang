//! The one OTP release check (decision 228 of 1.0.11-beta), for every `erl`,
//! `erlc` and `escript` the compiler spawns.
//!
//! The compiler emits Erlang for one release, `manifest.OTP_RELEASE`. Before
//! anything Erlang starts — a RUN LOG executor (`codegen/runtime.zig`), the
//! CLI's compile check, runner
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

/// The `-eval` text of a VM that runs a program, around the erlang expression
/// `call` that starts it, then `halt()`. An uncaught abort writes to stderr one
/// line, `<kind>: <message>`, status 1 — the `Failure` std's `attempt` would
/// have caught (decision 535, 527), never `erl`'s own report of the raw
/// `Class:Reason` term (it goes to stdout, where it leaks into the program's
/// output and races the halt; and prints a UTF-8 message's bytes as numbers
/// once one is outside ASCII):
///
/// - `panic: <message>` — an `@panic` / `@todo` (`{panic, Msg}`, `{todo, Msg}`),
///   a checked integer operator or a division by zero (`{integer_overflow, Msg}`,
///   `{panic, Msg}`), a failed `assert` (`{bp_assert, …, Panic}`): `Msg` the
///   text the program raised, a UTF-8 binary or an iolist;
/// - `host: <message>` — a host raise marked by the wrapper of a binding outside
///   std (`{bp_host, Msg}`, decision 546), `Msg` the reason by `~tp`;
/// - `crash: <reason>` — anything else (a failing match, `badarith`, an exit, a
///   std binding's raise): the reason by `~tp`, without the class.
///
/// `botopink run` (`compiler-cli/src/cli/otp.zig` `mainEval`) and the
/// compiler-core tests that run an abort (`codegen/runtime.zig`
/// `executeAborting`) both use it.
pub fn guardedEval(arena: std.mem.Allocator, call: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena,
        \\try {s} catch
        \\error:{{Tag, Msg}} when (Tag =:= panic orelse Tag =:= todo orelse Tag =:= integer_overflow) andalso (is_binary(Msg) orelse is_list(Msg)) -> io:setopts(standard_error, [{{encoding, unicode}}]), io:format(standard_error, "panic: ~ts~n", [Msg]), halt(1);
        \\error:{{bp_assert, _, _, Msg}} -> io:setopts(standard_error, [{{encoding, unicode}}]), io:format(standard_error, "panic: ~ts~n", [Msg]), halt(1);
        \\error:{{bp_assert, Msg, _}} when is_binary(Msg) -> io:setopts(standard_error, [{{encoding, unicode}}]), io:format(standard_error, "panic: ~ts~n", [Msg]), halt(1);
        \\error:{{bp_host, Msg}} when is_binary(Msg) -> io:setopts(standard_error, [{{encoding, unicode}}]), io:format(standard_error, "host: ~ts~n", [Msg]), halt(1);
        \\_:Reason -> io:setopts(standard_error, [{{encoding, unicode}}]), io:format(standard_error, "crash: ~ts~n", [io_lib:format("~tp", [Reason])]), halt(1) end, halt().
    , .{call});
}

/// The JavaScript a node VM that runs a program loads first (`--import`, a
/// `data:` URL of `node_abort_import`): an uncaught abort — a throw out of
/// `main`, a rejected promise nobody awaited — writes one line to stderr,
/// `<kind>: <message>`, and exits 1: the `Failure` std's `attempt` answers
/// for the same raise (decision 535; `libs/std/src/failure.bp`'s Node form
/// reads the same marks), not node's own report, a stack trace. `panic` is an
/// `@panic`, `@todo`, `x!`, an overflow, a division by zero or a failed
/// `assert` (the `__bp_panic` mark the backend puts on each, whose value is
/// the message when it is a string); a raise marked `__bp_host` (a binding
/// outside std without `result: true`, decision 546) is `host`; anything else
/// is `crash`; the message an `Error`'s `message`, else `String(e)`.
pub const node_abort_source =
    "import{writeSync}from\"node:fs\";" ++
    "const k=(e)=>e!=null&&e.__bp_panic!=null?[\"panic\",typeof e.__bp_panic===\"string\"?e.__bp_panic:e.message]:" ++
    "e!=null&&typeof e.__bp_assert_loc===\"string\"?[\"panic\",e.message]:" ++
    "[e!=null&&e.__bp_host===true?\"host\":\"crash\",e instanceof Error?e.message:String(e)];" ++
    "const a=(e)=>{const[x,m]=k(e);writeSync(2,x+\": \"+m+\"\\n\");process.exit(1)};" ++
    "process.on(\"uncaughtException\",a);process.on(\"unhandledRejection\",a);";

/// `node_abort_source` as the `data:` URL `node --import` takes: every byte
/// outside `[A-Za-z0-9]` percent-encoded.
pub const node_abort_import: []const u8 = blk: {
    const prefix = "data:text/javascript,";
    var out: []const u8 = prefix;
    for (node_abort_source) |c| {
        const plain = std.ascii.isAlphanumeric(c);
        out = out ++ (if (plain) &[_]u8{c} else &[_]u8{ '%', "0123456789ABCDEF"[c >> 4], "0123456789ABCDEF"[c & 15] });
    }
    break :blk out;
};

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

test "otp: an abort by @panic writes panic: and its message unchanged, outside ASCII too" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const eval = try guardedEval(arena, "erlang:error({panic, <<\"lib: '--gutter' is in no known namespace \\x{2014} a prefix\"/utf8>>})");
    const res = std.process.run(arena, io, .{
        .argv = &([_][]const u8{"erl"} ++ QUIET_FLAGS ++ [_][]const u8{ "-noshell", "-eval", eval }),
    }) catch return;
    try std.testing.expectEqualStrings("panic: lib: '--gutter' is in no known namespace \xe2\x80\x94 a prefix\n", res.stderr);
    try std.testing.expectEqual(@as(u8, 1), res.term.exited);
}

test "otp: an integer overflow abort writes panic: and its message, no error report" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const eval = try guardedEval(arena, "erlang:error({integer_overflow, <<\"integer overflow: + on i32 at src/main.bp:6:14\">>})");
    const res = std.process.run(arena, io, .{
        .argv = &([_][]const u8{"erl"} ++ QUIET_FLAGS ++ [_][]const u8{ "-noshell", "-eval", eval }),
    }) catch return;
    try std.testing.expectEqualStrings("panic: integer overflow: + on i32 at src/main.bp:6:14\n", res.stderr);
    try std.testing.expectEqualStrings("", res.stdout);
    try std.testing.expectEqual(@as(u8, 1), res.term.exited);
}

test "otp: any other abort writes crash: and the reason, one stderr line and nothing to stdout" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const eval = try guardedEval(arena, "erlang:error(badarith)");
    const res = std.process.run(arena, io, .{
        .argv = &([_][]const u8{"erl"} ++ QUIET_FLAGS ++ [_][]const u8{ "-noshell", "-eval", eval }),
    }) catch return;
    try std.testing.expectEqualStrings("crash: badarith\n", res.stderr);
    try std.testing.expectEqualStrings("", res.stdout);
    try std.testing.expectEqual(@as(u8, 1), res.term.exited);
}

test "otp: a marked host raise writes host: and its text; a failed assert and a todo write panic:" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const cases = [_][2][]const u8{
        .{ "erlang:error({bp_host, <<\"boom\">>})", "host: boom\n" },
        .{ "erlang:error({bp_assert, <<\"assertion failed\">>, <<\"m.bp:3\">>, [<<\"assertion failed: x at m.bp:3:5\">>]})", "panic: assertion failed: x at m.bp:3:5\n" },
        .{ "erlang:error({todo, <<\"later\">>})", "panic: later\n" },
        .{ "erlang:error({case_clause, 'Square'})", "crash: {case_clause,'Square'}\n" },
    };
    for (cases) |c| {
        const eval = try guardedEval(arena, c[0]);
        const res = std.process.run(arena, io, .{
            .argv = &([_][]const u8{"erl"} ++ QUIET_FLAGS ++ [_][]const u8{ "-noshell", "-eval", eval }),
        }) catch return;
        try std.testing.expectEqualStrings(c[1], res.stderr);
        try std.testing.expectEqual(@as(u8, 1), res.term.exited);
    }
}
