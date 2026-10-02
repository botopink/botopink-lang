/// The OTP check of every erlang and beam run (decision 228 of 1.0.11-beta),
/// and the one `erl` a command's own compile jobs share (front 133).
///
/// The compiler emits Erlang for one release, `manifest.OTP_RELEASE`; the
/// `erl` / `erlc` on `PATH` decide which release the emitted code is checked
/// and run against. A machine on another release than CI once kept the gate
/// green on a module the CI release refuses (`erlang:element(2, C)(9)`, accepted
/// by OTP 29, a syntax error for 28). So before `botopink build | run | test
/// --target erlang | beam` loads a source, it asks for the release and refuses
/// another one — before any `.erl` is written. No flag, variable or manifest
/// value turns the refusal into a warning (decision 67); a manifest's `"otp"`
/// can only name the same release (`manifest.closureOtp`).
///
/// **The session.** `check` asks by starting the command's one compile `erl`
/// (`SESSION_EVAL`): it prints its release on its first line and then waits on
/// stdin. The release is handed to compiler-core's check (`bp.otp.adopt`, the
/// verdict the comptime node and the RUN LOG executors read), so a refused
/// release ends the command there, as the separate probe did. On the release
/// the compiler emits for, the same VM then runs, one after another, every
/// compile job of the command (`job`): `build`'s in-memory check of the
/// emitted erlang, the host-module lookup of the sidecar shipper, `run`'s
/// compile of the output directory, `test`'s precompile. Each job is the
/// `-eval` text it was as a VM of its own, evaluated by `erl_eval` exactly as
/// `-eval` evaluates it, in a fresh process (its group leader and bindings are
/// its own), its plain arguments bound in place of `init:get_plain_arguments()`
/// and its `halt(N)` ending the job with N instead of the VM. An erlang `run`
/// started four VMs (release probe, check, compile, the program), now two; a
/// beam `run` three, now two; an erlang `test` three plus one per test module,
/// now two plus one per module. The session is one command's, inside the
/// command's own process: `main.zig` closes it (`close`) when the command
/// returns — nothing outlives the process, no VM is shared between commands.
///
/// What stays a VM of its own, and why: **the program** (`run`'s `main/1`,
/// `test`'s runners) — it is the user's code, and it must start in a clean VM
/// with the default scheduler count (`std/io/os.bp` reads
/// `schedulers_online`); **the comptime node** — it evaluates user comptime
/// code, holds resident modules and is spawned lazily from compiler-core, so
/// it keeps its own VM and the default scheduler count; `test`'s beam
/// assembly (`erlc +from_asm`, whose `.beam` bytes record `erlc`'s options).
///
/// **The flags.** Every VM the compiler starts gets `bp.otp.QUIET_FLAGS`
/// (`+sbwt none +sbwtdcpu none +sbwtdio none`): an idle scheduler does not
/// spin before it sleeps. A short-lived VM spent ~0.21 of its ~0.34 CPU-s
/// start in that busy wait (16 schedulers, 16 dirty-CPU, 10 dirty-IO). It
/// changes no result — only how long an idle scheduler polls. The session also
/// starts with `+S <n>:1` (`SESSION_SCHEDULERS`): it compiles and runs no user
/// program, so it starts few scheduler threads, one online, and each job sets
/// the online count it can use (`onlineFor`: one per 32 files, at most `n`) —
/// a small cell compiles on one scheduler, a 4 000-module closure on `n`. The
/// flags are on the argv (or `ERL_AFLAGS`, prepended, for a child whose argv
/// the compiler does not write): a user's `ERL_FLAGS` still comes last and
/// wins.
const std = @import("std");
const bp = @import("botopink");

/// The release the compiler emits for — the one constant, owned by `manifest`.
pub const RELEASE = bp.otp.RELEASE;

/// Ask the `erl` on `PATH` for its release and compare it with `RELEASE`, by
/// opening the command's session (once; later calls answer the same).
/// False, with the refusal printed, when it differs or cannot be read.
pub fn check(arena: std.mem.Allocator, io: std.Io) !bool {
    _ = arena;
    if (session == null and !opened) open(io);
    bp.otp.check(io) catch {
        close(io);
        return false;
    };
    return true;
}

/// Schedulers the session starts (`+S <n>:1`): the most any job brings
/// online. Eight: a compile job past ~250 files gains little from more, and
/// each scheduler thread is start-up CPU every cell pays.
pub const SESSION_SCHEDULERS = 8;

/// The online schedulers a job over `files` inputs asks for: one per 32
/// files, at least one, at most `SESSION_SCHEDULERS`.
pub fn onlineFor(files: usize) usize {
    return std.math.clamp((files + 31) / 32, 1, SESSION_SCHEDULERS);
}

/// The session's `-eval`: print the release, then run each job line from
/// stdin — `{Online, Text, Args}.`, every string a binary of byte values —
/// and end each with a `\x1ebp-session <code>` line on stdout. EOF on stdin
/// ends the VM.
pub const SESSION_EVAL =
    \\io:put_chars([erlang:system_info(otp_release), $\n]),
    \\Dec = fun(B) -> case unicode:characters_to_list(B) of L when is_list(L) -> L; _ -> binary_to_list(B) end end,
    \\Halt = fun(C) -> throw({bp_session_halt, C}) end,
    \\Loop = fun Next() ->
    \\    case io:get_line('') of
    \\        eof -> halt(0);
    \\        {error, _} -> halt(1);
    \\        Line ->
    \\            {ok, Toks, _} = erl_scan:string(Line),
    \\            {ok, {Online, Text, Args}} = erl_parse:parse_term(Toks),
    \\            erlang:system_flag(schedulers_online, erlang:max(1, erlang:min(Online, erlang:system_info(schedulers)))),
    \\            {ok, ETs, _} = erl_scan:string(Dec(Text)),
    \\            {ok, Exprs} = erl_parse:parse_exprs(ETs),
    \\            Bs = erl_eval:add_binding('BpSessionPlain', [Dec(A) || A <- Args],
    \\                     erl_eval:add_binding('BpSessionHalt', Halt, erl_eval:new_bindings())),
    \\            Self = self(),
    \\            {Pid, Mref} = spawn_monitor(fun() ->
    \\                Code = try erl_eval:exprs(Exprs, Bs), 0 catch throw:{bp_session_halt, C} -> C end,
    \\                Self ! {bp_session_job, self(), Code}
    \\            end),
    \\            Code = receive
    \\                {bp_session_job, Pid, C} -> erlang:demonitor(Mref, [flush]), C;
    \\                {'DOWN', Mref, process, Pid, Reason} ->
    \\                    io:format(standard_error, "Error! Failed to eval: ~p~n", [Reason]), 1
    \\            end,
    \\            io:put_chars([30, "bp-session ", integer_to_list(Code), $\n]),
    \\            Next()
    \\    end
    \\end,
    \\Loop().
;

const DONE = "\x1ebp-session ";

const Session = struct {
    child: std.process.Child,
    /// Bytes read from stdout; `buf[start..]` is not consumed yet.
    buf: std.ArrayListUnmanaged(u8) = .empty,
    start: usize = 0,
};

var session: ?Session = null;
/// `open` ran (successfully or not) in this process.
var opened = false;

fn open(io: std.Io) void {
    opened = true;
    const argv = [_][]const u8{"erl"} ++ bp.otp.QUIET_FLAGS ++ [_][]const u8{
        "+S", std.fmt.comptimePrint("{d}:1", .{SESSION_SCHEDULERS}), "-noshell", "-eval", SESSION_EVAL,
    };
    const child = std.process.spawn(io, .{
        .argv = &argv,
        .stdin = .pipe,
        .stdout = .pipe,
        .stderr = .inherit,
    }) catch |err| {
        bp.otp.adoptSpawnError(err);
        return;
    };
    session = .{ .child = child };
    const s = &session.?;
    // The first line is the release; EOF before it is an `erl` that did not
    // answer — its exit status names it, as the probe's did.
    if (readLine(io, s)) |line| {
        bp.otp.adopt(0, line);
        return;
    } else |_| {}
    const partial = s.buf.items[s.start..];
    if (s.child.stdin) |f| {
        f.close(io);
        s.child.stdin = null;
    }
    const term = s.child.wait(io) catch null;
    const code: ?u8 = if (term) |t| switch (t) {
        .exited => |c| c,
        .signal, .stopped, .unknown => null,
    } else null;
    session = null;
    bp.otp.adopt(code, partial);
}

/// End the session: EOF on its stdin, and wait for the VM. Idempotent.
pub fn close(io: std.Io) void {
    if (session) |*s| {
        if (s.child.stdin) |f| {
            f.close(io);
            s.child.stdin = null;
        }
        _ = s.child.wait(io) catch s.child.kill(io);
        session = null;
    }
}

/// The next stdout line of the session (without `\n`); valid until the next
/// read.
fn readLine(io: std.Io, s: *Session) ![]const u8 {
    const gpa = std.heap.page_allocator;
    if (s.start > 0) {
        const rest = s.buf.items.len - s.start;
        std.mem.copyForwards(u8, s.buf.items[0..rest], s.buf.items[s.start..]);
        s.buf.shrinkRetainingCapacity(rest);
        s.start = 0;
    }
    var scanned: usize = 0;
    while (true) {
        if (std.mem.indexOfScalarPos(u8, s.buf.items, scanned, '\n')) |nl| {
            s.start = nl + 1;
            return s.buf.items[0..nl];
        }
        scanned = s.buf.items.len;
        var chunk: [4096]u8 = undefined;
        const n = s.child.stdout.?.readStreaming(io, &.{&chunk}) catch |err| switch (err) {
            error.EndOfStream => return error.EndOfStream,
            else => return err,
        };
        if (n == 0) return error.EndOfStream;
        try s.buf.appendSlice(gpa, chunk[0..n]);
    }
}

/// What a job answered: its exit code (`halt(N)`'s N; 1 when it raised) and
/// what it wrote to stdout. Its stderr is the command's own.
pub const JobResult = struct {
    code: u8,
    stdout: []const u8,
};

/// Run `eval` — an `-eval` text that reads `init:get_plain_arguments()` and
/// ends with `halt(N)` — with `args` as its plain arguments, in the session
/// when one is open, else in an `erl` of its own (`QUIET_FLAGS`, `+S 1:1`,
/// `-noshell -eval <eval> -extra <args>`, stderr inherited). `online`: the
/// schedulers it may use (`onlineFor`). A spawn that fails is returned.
pub fn job(arena: std.mem.Allocator, io: std.Io, eval: []const u8, args: []const []const u8, online: usize) !JobResult {
    if (session) |*s| {
        if (s.child.stdin != null) {
            if (runInSession(arena, io, s, eval, args, online)) |r| return r else |_| {
                // The VM died under a job: the job failed, and so does every
                // later one (as a standalone `erl` that crashed would).
                s.child.kill(io);
                session = null;
                return .{ .code = 1, .stdout = "" };
            }
        }
    }
    var argv: std.ArrayListUnmanaged([]const u8) = .empty;
    try argv.append(arena, "erl");
    try argv.appendSlice(arena, &bp.otp.QUIET_FLAGS);
    try argv.appendSlice(arena, &.{ "+S", "1:1", "-noshell", "-eval", eval, "-extra" });
    try argv.appendSlice(arena, args);
    const result = try std.process.run(arena, io, .{
        .argv = argv.items,
        .stdout_limit = .limited(16 * 1024 * 1024),
        .stderr_limit = .limited(16 * 1024 * 1024),
    });
    if (result.stderr.len > 0) std.Io.File.stderr().writeStreamingAll(io, result.stderr) catch {};
    return .{ .code = switch (result.term) {
        .exited => |c| c,
        .signal, .stopped, .unknown => 1,
    }, .stdout = result.stdout };
}

fn runInSession(arena: std.mem.Allocator, io: std.Io, s: *Session, eval: []const u8, args: []const []const u8, online: usize) !JobResult {
    // The text as a job: its plain arguments and its halt are the session's.
    const t1 = try std.mem.replaceOwned(u8, arena, eval, "init:get_plain_arguments()", "BpSessionPlain");
    const t2 = try std.mem.replaceOwned(u8, arena, t1, "halt()", "BpSessionHalt(0)");
    const text = try std.mem.replaceOwned(u8, arena, t2, "halt(", "BpSessionHalt(");

    var line: std.ArrayListUnmanaged(u8) = .empty;
    try line.print(arena, "{{{d},", .{online});
    try appendBinary(arena, &line, text);
    try line.appendSlice(arena, ",[");
    for (args, 0..) |a, i| {
        if (i > 0) try line.append(arena, ',');
        try appendBinary(arena, &line, a);
    }
    try line.appendSlice(arena, "]}.\n");
    try s.child.stdin.?.writeStreamingAll(io, line.items);

    var out: std.ArrayListUnmanaged(u8) = .empty;
    while (true) {
        const l = try readLine(io, s);
        if (std.mem.indexOf(u8, l, DONE)) |at| {
            try out.appendSlice(arena, l[0..at]);
            const code = std.fmt.parseInt(u8, l[at + DONE.len ..], 10) catch 1;
            return .{ .code = code, .stdout = out.items };
        }
        try out.appendSlice(arena, l);
        try out.append(arena, '\n');
    }
}

/// `<<b1,b2,…>>`: any bytes, one ASCII line.
fn appendBinary(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), bytes: []const u8) !void {
    try out.appendSlice(arena, "<<");
    for (bytes, 0..) |b, i| {
        if (i > 0) try out.append(arena, ',');
        try out.print(arena, "{d}", .{b});
    }
    try out.appendSlice(arena, ">>");
}

/// `erl`, `bp.otp.QUIET_FLAGS`, then `rest`: the argv of a VM that runs the
/// user's program — the default scheduler count, no busy wait.
pub fn erlArgv(arena: std.mem.Allocator, rest: []const []const u8) ![]const []const u8 {
    const argv = try arena.alloc([]const u8, 1 + bp.otp.QUIET_FLAGS.len + rest.len);
    argv[0] = "erl";
    @memcpy(argv[1 .. 1 + bp.otp.QUIET_FLAGS.len], &bp.otp.QUIET_FLAGS);
    @memcpy(argv[1 + bp.otp.QUIET_FLAGS.len ..], rest);
    return argv;
}

/// `env` (a copy; null = none) with `bp.otp.QUIET_AFLAGS` prepended to
/// `ERL_AFLAGS`: for a child whose `erl` command line the compiler does not
/// write (`escript`, `erlc`) — the user's own `ERL_AFLAGS` text stays after
/// it, and `ERL_FLAGS` after both, so a flag the user sets still wins.
/// `extra` (may be empty) goes after the quiet flags: `+S 1:1` for `erlc`.
pub fn quietEnv(arena: std.mem.Allocator, env: ?*const std.process.Environ.Map, comptime extra: []const u8) !*std.process.Environ.Map {
    const map = try arena.create(std.process.Environ.Map);
    map.* = std.process.Environ.Map.init(arena);
    if (env) |m| {
        for (m.keys(), m.values()) |k, v| try map.put(k, v);
    }
    const prev = map.get("ERL_AFLAGS");
    const ours = if (extra.len == 0) bp.otp.QUIET_AFLAGS else bp.otp.QUIET_AFLAGS ++ " " ++ extra;
    const value = if (prev) |p| try std.fmt.allocPrint(arena, "{s} {s}", .{ ours, p }) else ours;
    try map.put("ERL_AFLAGS", value);
    return map;
}

test "onlineFor: one scheduler per 32 files, between 1 and SESSION_SCHEDULERS" {
    try std.testing.expectEqual(@as(usize, 1), onlineFor(0));
    try std.testing.expectEqual(@as(usize, 1), onlineFor(32));
    try std.testing.expectEqual(@as(usize, 2), onlineFor(33));
    try std.testing.expectEqual(@as(usize, SESSION_SCHEDULERS), onlineFor(100_000));
}

test "a job runs in a session as it runs in an erl of its own" {
    const io = std.testing.io;
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const eval =
        \\[A, B] = init:get_plain_arguments(),
        \\io:format("~ts|~ts~n", [A, B]),
        \\halt(case A of "x" -> 3; _ -> 0 end).
    ;
    const args = [_][]const u8{ "x", "caf\xc3\xa9 \"q\" \\n" };
    const alone = try job(arena, io, eval, &args, 1);
    open(io);
    defer {
        close(io);
        opened = false;
    }
    try std.testing.expect(session != null);
    const in_session = try job(arena, io, eval, &args, 1);
    try std.testing.expectEqual(alone.code, in_session.code);
    try std.testing.expectEqualStrings(alone.stdout, in_session.stdout);
    try std.testing.expectEqual(@as(u8, 3), in_session.code);
    // A second job in the same VM. (One that raises answers 1 and prints
    // `Error! Failed to eval` on stderr, which the test runner refuses.)
    const again = try job(arena, io, "io:put_chars(\"two\"), halt().", &.{}, 1);
    try std.testing.expectEqual(@as(u8, 0), again.code);
    try std.testing.expectEqualStrings("two", again.stdout);
}
