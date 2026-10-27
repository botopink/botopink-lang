/// The workspace fan-out (decisions 1006 (5), 1066): at a workspace root,
/// `build` and `run --target <t>` run one child process per member, one after
/// another in the workspace's order, each under a timeout. The compiler
/// decides no parallelism: running members side by side is the spawner's
/// (`conformance/run.sh` starts `cd <member> && botopink run --target <t>` on
/// its pool share). A member's failure, a crash or a hang is that member's
/// line alone:
///
///     ok   <member>
///         <its output, indented>
///     FAIL <member> — <reason>
///         <its output, indented>
///     modules: N checked — P passed, F failed
///
/// `<member>` is the member's directory relative to the root; N is the member
/// count; the command exits 1 on any red. Each member's whole output is
/// buffered and printed under its own line, never interleaved with another
/// member's (decision 1065 (4)).
///
/// **Timeout** (decision 1067). `--timeout <s>` bounds the whole command,
/// every member together, and exists only when passed — no per-member bound,
/// no default. When it fires the running member's process group is killed
/// (`FAIL <m> — stopped: …`), the members not yet run are reported `not run`,
/// and the command exits 1 naming the bound; a `run` member is handed the
/// time left as its own `--timeout`, from which its wasm runner arms its
/// epoch deadline. A member is its own process group, so a stop kills what it
/// spawned too (`node`, `erl`); the group is killed once its leader ended as
/// well, so no straggler outlives the command.
///
/// **Output.** A member's stdout and stderr go to one log file of its own
/// under `<root>/.botopinkbuild/tmp/fanout/` (never a pipe, so a member that
/// writes much never blocks on a reader), read back and indented when its
/// line is printed, then removed.
const std = @import("std");
const builtin = @import("builtin");
const bp = @import("botopink");
const reporter = @import("./reporter.zig");

pub const Member = struct {
    /// What its line names: the directory relative to the root.
    name: []const u8,
    /// Absolute.
    dir: []const u8,
};

pub const Options = struct {
    /// The command each member runs, in its directory.
    argv: []const []const u8,
    /// `--timeout`: the seconds the whole command is given, every member
    /// together (decision 1067); null, no bound.
    timeout_s: ?u64 = null,
    /// Each member's command is handed the time left as `--timeout <s>`, so
    /// its wasm runner arms its epoch deadline from it (1067 (2)).
    hand_timeout: bool = false,
    /// Where the members' logs are written (created, removed at the end).
    log_dir: []const u8,
};

const Slot = struct {
    log: []const u8,
    /// The member's command: `Options.argv`, then `--timeout <left>` when handed.
    argv: [][]const u8,
    left_buf: [24]u8 = undefined,
    /// The member's pid once spawned (0 before).
    pid: std.atomic.Value(i32) = .init(0),
    /// Stopped by the bound while it ran.
    stopped: std.atomic.Value(bool) = .init(false),
    /// Never started: the bound was reached first.
    not_run: bool = false,
    done: std.atomic.Value(bool) = .init(false),
    /// Written by the worker before `done`.
    term: ?std.process.Child.Term = null,
    spawn_error: ?anyerror = null,
};

const Shared = struct {
    io: std.Io,
    members: []const Member,
    opts: Options,
    slots: []Slot,
    /// The bound's end (ns, the awake clock); null, none.
    deadline_ns: ?i64,
    /// Set once the bound is reached: no member starts after it.
    expired: std.atomic.Value(bool) = .init(false),
};

fn nowNs(io: std.Io) i64 {
    return @intCast(std.Io.Timestamp.now(io, .awake).nanoseconds);
}

fn worker(sh: *Shared) void {
    for (0..sh.members.len) |i| runOne(sh, i);
}

fn runOne(sh: *Shared, i: usize) void {
    const io = sh.io;
    const slot = &sh.slots[i];
    defer slot.done.store(true, .release);
    if (sh.expired.load(.acquire)) {
        slot.not_run = true;
        return;
    }
    const log = std.Io.Dir.cwd().createFile(io, slot.log, .{}) catch |e| {
        slot.spawn_error = e;
        return;
    };
    defer log.close(io);
    var argv: []const []const u8 = sh.opts.argv;
    if (sh.opts.hand_timeout) if (sh.deadline_ns) |d| {
        const left_ns = @max(d - nowNs(io), 0);
        const left_s: u64 = @intCast(@max(@divFloor(left_ns + std.time.ns_per_s - 1, std.time.ns_per_s), 1));
        slot.argv[slot.argv.len - 1] = std.fmt.bufPrint(&slot.left_buf, "{d}", .{left_s}) catch "1";
        argv = slot.argv;
    };
    var child = bp.procgroup.spawnMember(io, .{
        .argv = argv,
        .cwd = .{ .path = sh.members[i].dir },
        .stdin = .ignore,
        .stdout = .{ .file = log },
        .stderr = .{ .file = log },
        // Its own process group: a stop reaches what it spawned.
        .pgid = if (builtin.os.tag == .windows) null else 0,
    }) catch |e| {
        slot.spawn_error = e;
        return;
    };
    const pid: i32 = if (builtin.os.tag == .windows) 0 else @intCast(child.id.?);
    slot.pid.store(pid, .release);
    const term = bp.procgroup.waitMember(io, &child) catch |e| {
        child.kill(io);
        slot.spawn_error = e;
        return;
    };
    // Whatever the member left behind in its group ends with it.
    killGroup(pid);
    slot.term = term;
}

const TERM_GRACE_NS: i64 = 3 * std.time.ns_per_s;

fn termMember(pid: i32) void {
    if (builtin.os.tag == .windows or pid <= 0) return;
    std.posix.kill(pid, .TERM) catch {};
}

pub fn killGroup(pid: i32) void {
    if (builtin.os.tag == .windows or pid <= 0) return;
    std.posix.kill(-pid, .KILL) catch {};
}

/// Runs every member, prints its line as the order reaches it, and the count.
/// 0 when every member answered 0, else 1.
pub fn run(gpa: std.mem.Allocator, io: std.Io, members: []const Member, opts: Options) !u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    std.Io.Dir.cwd().createDirPath(io, opts.log_dir) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };
    defer std.Io.Dir.cwd().deleteTree(io, opts.log_dir) catch {};

    const slots = try arena.alloc(Slot, members.len);
    for (slots, 0..) |*s, i| {
        const argv = try arena.alloc([]const u8, opts.argv.len + 2);
        @memcpy(argv[0..opts.argv.len], opts.argv);
        argv[opts.argv.len] = "--timeout";
        argv[opts.argv.len + 1] = "1";
        s.* = .{ .log = try std.fmt.allocPrint(arena, "{s}/{d}.log", .{ opts.log_dir, i }), .argv = argv };
    }
    const deadline_ns: ?i64 = if (opts.timeout_s) |t|
        nowNs(io) +| @as(i64, @intCast(@min(t, @as(u64, std.math.maxInt(i64) / std.time.ns_per_s)))) * std.time.ns_per_s
    else
        null;
    var sh: Shared = .{ .io = io, .members = members, .opts = opts, .slots = slots, .deadline_ns = deadline_ns };

    // One worker takes the members in order, one at a time (decision 1066);
    // this thread holds the whole command's bound (1067) and prints each line
    // as the order reaches it.
    const thread = try std.Thread.spawn(.{}, worker, .{&sh});
    defer thread.join();

    var printed: usize = 0;
    var passed: usize = 0;
    var not_run: usize = 0;
    while (printed < members.len) {
        if (deadline_ns) |d| {
            const now = nowNs(io);
            if (!sh.expired.load(.acquire) and now >= d) {
                sh.expired.store(true, .release);
                // SIGTERM first (decision 1061 (1)): the member's own children
                // lead groups of their own, which its handler kills; its group
                // is killed when it ended (worker) or after `TERM_GRACE_NS`.
                for (slots) |*s| {
                    if (s.done.load(.acquire)) continue;
                    const pid = s.pid.load(.acquire);
                    if (pid == 0) continue;
                    s.stopped.store(true, .release);
                    termMember(pid);
                }
            } else if (sh.expired.load(.acquire) and now >= d + TERM_GRACE_NS) {
                // It ignored the SIGTERM: the group goes.
                for (slots) |*s| if (!s.done.load(.acquire) and s.stopped.load(.acquire)) killGroup(s.pid.load(.acquire));
            }
        }
        while (printed < members.len and slots[printed].done.load(.acquire)) : (printed += 1) {
            if (slots[printed].not_run) not_run += 1;
            if (try report(arena, io, members[printed], &slots[printed], opts.timeout_s orelse 0)) passed += 1;
        }
        if (printed < members.len) io.sleep(.fromMilliseconds(50), .awake) catch {};
    }
    const failed = members.len - passed;
    reporter.stdout(io, try std.fmt.allocPrint(arena, "modules: {d} checked — {d} passed, {d} failed\n", .{ members.len, passed, failed }));
    if (sh.expired.load(.acquire)) {
        reporter.errMsg(try std.fmt.allocPrint(arena, "the command's --timeout of {d} s was reached: the running member was stopped and {d} member(s) not run", .{ opts.timeout_s.?, not_run }));
    }
    return if (failed == 0) 0 else 1;
}

/// The member's line and its output; true when it passed.
fn report(arena: std.mem.Allocator, io: std.Io, member: Member, slot: *const Slot, timeout_s: u64) !bool {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    const reason: ?[]const u8 = if (slot.not_run)
        try std.fmt.allocPrint(arena, "not run: the command's --timeout of {d} s was reached", .{timeout_s})
    else if (slot.spawn_error) |e|
        try std.fmt.allocPrint(arena, "cannot start its process ({s})", .{@errorName(e)})
    else if (slot.stopped.load(.acquire))
        try std.fmt.allocPrint(arena, "stopped: the command's --timeout of {d} s was reached", .{timeout_s})
    else switch (slot.term.?) {
        .exited => |code| if (code == 0) null else try std.fmt.allocPrint(arena, "exit {d}", .{code}),
        .signal => |sig| try std.fmt.allocPrint(arena, "crashed (signal {d})", .{@intFromEnum(sig)}),
        .stopped => |sig| try std.fmt.allocPrint(arena, "stopped (signal {d})", .{@intFromEnum(sig)}),
        .unknown => |v| try std.fmt.allocPrint(arena, "ended abnormally ({d})", .{v}),
    };
    if (reason) |r|
        try text.print(arena, "FAIL {s} — {s}\n", .{ member.name, r })
    else
        try text.print(arena, "ok   {s}\n", .{member.name});
    if (!slot.not_run) {
        const out = std.Io.Dir.cwd().readFileAlloc(io, slot.log, arena, .limited(64 * 1024 * 1024)) catch "";
        try indentInto(arena, &text, out);
        std.Io.Dir.cwd().deleteFile(io, slot.log) catch {};
    }
    reporter.stdout(io, text.items);
    return reason == null;
}

/// Each non-empty line of `out`, four spaces in.
fn indentInto(arena: std.mem.Allocator, text: *std.ArrayListUnmanaged(u8), out: []const u8) !void {
    var lines = std.mem.splitScalar(u8, out, '\n');
    while (lines.next()) |raw| {
        const line = std.mem.trimEnd(u8, raw, "\r");
        if (std.mem.trim(u8, line, " \t").len == 0) continue;
        try text.print(arena, "    {s}\n", .{line});
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "indentInto: every non-empty line four spaces in" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try indentInto(arena_inst.allocator(), &text, "a\n\n  b\r\n\n");
    try testing.expectEqualStrings("    a\n      b\n", text.items);
}
