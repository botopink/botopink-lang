/// The workspace fan-out (decision 1006 (5)): at a workspace root, `build` and
/// `run --target <t>` run one child process per member, in the workspace's
/// order, at most `jobs` at once, each under a timeout. A member's failure, a
/// crash or a hang is that member's line alone:
///
///     ok   <member>
///         <its output, indented>
///     FAIL <member> — <reason>
///         <its output, indented>
///     modules: N checked — P passed, F failed
///
/// `<member>` is the member's directory relative to the root; N is the member
/// count; the command exits 1 on any red. The lines are printed in the
/// workspace's order whatever order the members end in, so `--jobs 1` and the
/// default print the same lines.
///
/// **Jobs.** `defaultJobs`: one per CPU, bounded by `MemAvailable` over one
/// module's peak (`JOB_PEAK_KIB`, 768 MiB), at least 1 — the rule of the gate's
/// shell pool (`scripts/lib/pool.sh`, `pool_default_jobs`), so a caller that
/// holds a share of the machine (`scripts/gate.sh`, `conformance/run.sh`) hands
/// it with `--jobs`. The rule is held at each start too (`admit`): while a
/// member runs, the next one waits until `MemAvailable` holds one more peak.
///
/// **Timeout.** Each member runs under `timeout_s` (`--timeout`, default
/// `DEFAULT_TIMEOUT_S`, decision 1004's 900 s). A member is its own process
/// group, so a stop kills what it spawned too (`node`, `erl`, `wasmtime`); the
/// group is killed once its leader ended as well, so no straggler outlives
/// the command.
///
/// **Output.** A member's stdout and stderr go to one log file of its own
/// under `<root>/.botopinkbuild/tmp/fanout/` (never a pipe, so a member that
/// writes much never blocks on a reader), read back and indented when its
/// line is printed, then removed.
///
/// The shape is generic — a list of named directories and one command line —
/// so the libraries' jobs (decision 1004) can run on the same code.
const std = @import("std");
const builtin = @import("builtin");
const reporter = @import("./reporter.zig");

pub const DEFAULT_TIMEOUT_S: u64 = 900;
/// One member's peak, as the gate's pool counts a job (`pool.sh`).
pub const JOB_PEAK_KIB: u64 = 768 * 1024;

pub const Member = struct {
    /// What its line names: the directory relative to the root.
    name: []const u8,
    /// Absolute.
    dir: []const u8,
};

pub const Options = struct {
    /// The command each member runs, in its directory.
    argv: []const []const u8,
    jobs: usize,
    timeout_s: u64 = DEFAULT_TIMEOUT_S,
    /// Where the members' logs are written (created, removed at the end).
    log_dir: []const u8,
};

/// One CPU per job, bounded by `MemAvailable / 768 MiB`, at least 1; the CPUs
/// alone where `/proc/meminfo` is not there.
pub fn defaultJobs(io: std.Io) usize {
    const cpus = std.Thread.getCpuCount() catch 1;
    var buf: [8192]u8 = undefined;
    const text = readSmall(io, "/proc/meminfo", &buf) orelse return @max(cpus, 1);
    return jobsFor(cpus, memAvailableKib(text));
}

/// The rule, over its inputs.
pub fn jobsFor(cpus: usize, avail_kib: ?u64) usize {
    var jobs: usize = @max(cpus, 1);
    if (avail_kib) |kib| {
        const by_mem: usize = @intCast(@max(kib / JOB_PEAK_KIB, 1));
        jobs = @min(jobs, by_mem);
    }
    return jobs;
}

/// `MemAvailable:` of a `/proc/meminfo` text, in KiB.
pub fn memAvailableKib(text: []const u8) ?u64 {
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (!std.mem.startsWith(u8, line, "MemAvailable:")) continue;
        var fields = std.mem.tokenizeAny(u8, line["MemAvailable:".len..], " \t");
        const n = fields.next() orelse return null;
        return std.fmt.parseInt(u64, n, 10) catch null;
    }
    return null;
}

fn readSmall(io: std.Io, path: []const u8, buf: []u8) ?[]const u8 {
    const f = std.Io.Dir.cwd().openFile(io, path, .{}) catch return null;
    defer f.close(io);
    const n = f.readPositionalAll(io, buf, 0) catch return null;
    return buf[0..n];
}

const Slot = struct {
    log: []const u8,
    /// Set by the worker before the spawn: the member's start, ns.
    start_ns: std.atomic.Value(i64) = .init(0),
    /// The member's pid once spawned (0 before).
    pid: std.atomic.Value(i32) = .init(0),
    timed_out: std.atomic.Value(bool) = .init(false),
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
    next: std.atomic.Value(usize) = .init(0),
    /// Members spawned and not yet ended.
    running: std.atomic.Value(usize) = .init(0),
};

fn nowNs(io: std.Io) i64 {
    return @intCast(std.Io.Timestamp.now(io, .awake).nanoseconds);
}

fn worker(sh: *Shared) void {
    while (true) {
        const i = sh.next.fetchAdd(1, .monotonic);
        if (i >= sh.members.len) return;
        runOne(sh, i);
    }
}

fn runOne(sh: *Shared, i: usize) void {
    const io = sh.io;
    const slot = &sh.slots[i];
    defer slot.done.store(true, .release);
    const log = std.Io.Dir.cwd().createFile(io, slot.log, .{}) catch |e| {
        slot.spawn_error = e;
        return;
    };
    defer log.close(io);
    admit(sh);
    _ = sh.running.fetchAdd(1, .acq_rel);
    defer _ = sh.running.fetchSub(1, .acq_rel);
    slot.start_ns.store(nowNs(io), .release);
    var child = std.process.spawn(io, .{
        .argv = sh.opts.argv,
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
    const term = child.wait(io) catch |e| {
        child.kill(io);
        slot.spawn_error = e;
        return;
    };
    // Whatever the member left behind in its group ends with it.
    killGroup(pid);
    slot.term = term;
}

/// Before a member starts while another runs: wait until `MemAvailable` holds
/// one more member's peak (`JOB_PEAK_KIB`), re-read every half second — the
/// jobs are sized at the start, and members that grow past their peak must
/// not have more started beside them. A member with nothing running beside
/// it always starts, so the fan-out never waits forever.
fn admit(sh: *Shared) void {
    var buf: [8192]u8 = undefined;
    while (sh.running.load(.acquire) > 0) {
        const text = readSmall(sh.io, "/proc/meminfo", &buf) orelse return;
        const kib = memAvailableKib(text) orelse return;
        if (kib >= JOB_PEAK_KIB) return;
        sh.io.sleep(.fromMilliseconds(500), .awake) catch return;
    }
}

const TERM_GRACE_NS: i64 = 3 * std.time.ns_per_s;

fn termMember(pid: i32) void {
    if (builtin.os.tag == .windows or pid <= 0) return;
    std.posix.kill(pid, .TERM) catch {};
}

fn killGroup(pid: i32) void {
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
    for (slots, 0..) |*s, i| s.* = .{ .log = try std.fmt.allocPrint(arena, "{s}/{d}.log", .{ opts.log_dir, i }) };
    var sh: Shared = .{ .io = io, .members = members, .opts = opts, .slots = slots };

    const n_workers = @max(@min(opts.jobs, members.len), 1);
    const threads = try arena.alloc(std.Thread, n_workers);
    var started: usize = 0;
    defer for (threads[0..started]) |t| t.join();
    for (threads) |*t| {
        t.* = std.Thread.spawn(.{}, worker, .{&sh}) catch |e| {
            if (started == 0) return e;
            break;
        };
        started += 1;
    }

    const timeout_s: i64 = @intCast(@min(opts.timeout_s, @as(u64, std.math.maxInt(i64) / std.time.ns_per_s)));
    const timeout_ns: i64 = timeout_s * std.time.ns_per_s;
    var printed: usize = 0;
    var passed: usize = 0;
    while (printed < members.len) {
        const now = nowNs(io);
        for (slots) |*s| {
            if (s.done.load(.acquire)) continue;
            const pid = s.pid.load(.acquire);
            if (pid == 0) continue;
            const age = now - s.start_ns.load(.acquire);
            if (s.timed_out.load(.acquire)) {
                // It ignored the SIGTERM: the group goes.
                if (age >= timeout_ns + TERM_GRACE_NS) killGroup(pid);
                continue;
            }
            if (age < timeout_ns) continue;
            s.timed_out.store(true, .release);
            // SIGTERM first (decision 1061 (1)): the member's own children lead
            // groups of their own, which its handler kills; a SIGKILL of its group
            // alone would leave them. The group is killed when it ended (worker)
            // or after `TERM_GRACE_NS`.
            termMember(pid);
        }
        while (printed < members.len and slots[printed].done.load(.acquire)) : (printed += 1) {
            if (try report(arena, io, members[printed], &slots[printed], opts.timeout_s)) passed += 1;
        }
        if (printed < members.len) io.sleep(.fromMilliseconds(50), .awake) catch {};
    }
    const failed = members.len - passed;
    reporter.stdout(io, try std.fmt.allocPrint(arena, "modules: {d} checked — {d} passed, {d} failed\n", .{ members.len, passed, failed }));
    return if (failed == 0) 0 else 1;
}

/// The member's line and its output; true when it passed.
fn report(arena: std.mem.Allocator, io: std.Io, member: Member, slot: *const Slot, timeout_s: u64) !bool {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    const reason: ?[]const u8 = if (slot.spawn_error) |e|
        try std.fmt.allocPrint(arena, "cannot start its process ({s})", .{@errorName(e)})
    else if (slot.timed_out.load(.acquire))
        try std.fmt.allocPrint(arena, "no answer within {d} s (a hang): stopped", .{timeout_s})
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
    const out = std.Io.Dir.cwd().readFileAlloc(io, slot.log, arena, .limited(64 * 1024 * 1024)) catch "";
    try indentInto(arena, &text, out);
    reporter.stdout(io, text.items);
    std.Io.Dir.cwd().deleteFile(io, slot.log) catch {};
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

test "jobsFor: the CPUs, bounded by MemAvailable over 768 MiB, at least 1" {
    try testing.expectEqual(@as(usize, 16), jobsFor(16, null));
    try testing.expectEqual(@as(usize, 8), jobsFor(16, 6 * 1024 * 1024)); // 6 GiB / 768 MiB
    try testing.expectEqual(@as(usize, 1), jobsFor(16, 100));
    try testing.expectEqual(@as(usize, 4), jobsFor(4, 64 * 1024 * 1024));
    try testing.expectEqual(@as(usize, 1), jobsFor(0, null));
}

test "memAvailableKib: the MemAvailable line of /proc/meminfo" {
    try testing.expectEqual(@as(?u64, 5_800_000), memAvailableKib("MemTotal:       16000000 kB\nMemFree:  100 kB\nMemAvailable:    5800000 kB\n"));
    try testing.expectEqual(@as(?u64, null), memAvailableKib("MemTotal: 1 kB\n"));
}

test "indentInto: every non-empty line four spaces in" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try indentInto(arena_inst.allocator(), &text, "a\n\n  b\r\n\n");
    try testing.expectEqualStrings("    a\n      b\n", text.items);
}
