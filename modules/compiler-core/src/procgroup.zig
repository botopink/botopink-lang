//! Decision 1061 (1) — no child of the compiler outlives it.
//!
//! Every child the compiler starts (`erl`, `erlc`, `node`, `tsc`, a test
//! runner, the persistent comptime `erl`) leads a process group of its own
//! (`pgid = 0`) and is recorded here while it runs. A group is killed as a
//! group (`kill(-pgid, SIGKILL)`), so the grandchildren a child starts
//! (`beam.smp` under `erl`, a shell script's jobs) go with it: when the
//! child ends, when a `run` timeout expires, and — from a signal handler,
//! `killAll` is async-signal-safe — on SIGTERM and SIGINT. A compiler killed
//! by SIGKILL (a `timeout -s KILL` above it) cannot clean up; the script that
//! killed it kills its own session (`conformance/run.sh`).
const std = @import("std");
const builtin = @import("builtin");
const posix = std.posix;

const supported = builtin.os.tag != .windows and builtin.os.tag != .wasi;

const MAX = 64;
var live: [MAX]std.atomic.Value(i32) = [_]std.atomic.Value(i32){.init(0)} ** MAX;

fn record(pid: i32) void {
    for (&live) |*slot| {
        if (slot.cmpxchgStrong(0, pid, .acq_rel, .acquire) == null) return;
    }
}

fn forget(pid: i32) void {
    for (&live) |*slot| _ = slot.cmpxchgStrong(pid, 0, .acq_rel, .acquire);
}

fn killGroup(pid: i32) void {
    if (!supported or pid <= 1) return;
    posix.kill(-pid, .KILL) catch {};
}

/// Kill every group still recorded. Async-signal-safe: atomics and `kill(2)`.
pub fn killAll() void {
    for (&live) |*slot| {
        const pid = slot.load(.acquire);
        if (pid > 0) killGroup(pid);
        if (pid < 0 and supported) posix.kill(-pid, .TERM) catch {};
    }
}

/// `std.process.spawn` with the child leading a group of its own, recorded.
pub fn spawn(io: std.Io, options: std.process.SpawnOptions) std.process.SpawnError!std.process.Child {
    var o = options;
    if (supported) o.pgid = 0;
    const child = try std.process.spawn(io, o);
    if (supported) if (child.id) |id| record(@intCast(id));
    return child;
}

/// A child that is itself a compiler (a workspace member's `botopink`): it
/// stays in this process's group, because its own children are in groups of
/// their own and a SIGKILL of its group would leave them; `killAll` sends it
/// SIGTERM, whose handler kills them. Recorded as `-pid`.
pub fn spawnMember(io: std.Io, options: std.process.SpawnOptions) std.process.SpawnError!std.process.Child {
    const child = try std.process.spawn(io, options);
    if (supported) if (child.id) |id| record(-@as(i32, @intCast(id)));
    return child;
}

/// `child.wait` for a `spawnMember` child.
pub fn waitMember(io: std.Io, child: *std.process.Child) !std.process.Child.Term {
    const id = child.id;
    defer if (id) |p| forget(-@as(i32, @intCast(p)));
    return child.wait(io);
}

/// The child ended (waited for): its group's remaining members go with it.
/// Call with the pid taken before `wait`.
pub fn finish(pid: ?std.process.Child.Id) void {
    const id = pid orelse return;
    if (!supported) return;
    killGroup(@intCast(id));
    forget(@intCast(id));
}

/// Kill `child`'s whole group, then the child itself (reaping it).
pub fn kill(io: std.Io, child: *std.process.Child) void {
    const id = child.id;
    if (id) |p| killGroup(@intCast(p));
    child.kill(io);
    finish(id);
}

/// `child.wait` and then `finish`.
pub fn wait(io: std.Io, child: *std.process.Child) !std.process.Child.Term {
    const id = child.id;
    const term = try child.wait(io);
    finish(id);
    return term;
}

/// `std.process.run` with the child in a group of its own: the group dies
/// with the call, on a timeout and on an error included.
pub fn run(gpa: std.mem.Allocator, io: std.Io, options: std.process.RunOptions) std.process.RunError!std.process.RunResult {
    var child = try spawn(io, .{
        .argv = options.argv,
        .cwd = options.cwd,
        .environ_map = options.environ_map,
        .expand_arg0 = options.expand_arg0,
        .progress_node = options.progress_node,
        .create_no_window = options.create_no_window,
        .disable_aslr = options.disable_aslr,
        .stdin = .ignore,
        .stdout = .pipe,
        .stderr = .pipe,
    });
    defer kill(io, &child);

    var multi_reader_buffer: std.Io.File.MultiReader.Buffer(2) = undefined;
    var multi_reader: std.Io.File.MultiReader = undefined;
    multi_reader.init(gpa, io, multi_reader_buffer.toStreams(), &.{ child.stdout.?, child.stderr.? });
    defer multi_reader.deinit();

    const stdout_reader = multi_reader.reader(0);
    const stderr_reader = multi_reader.reader(1);

    while (multi_reader.fill(options.reserve_amount, options.timeout)) |_| {
        if (options.stdout_limit.toInt()) |limit| {
            if (stdout_reader.buffered().len > limit) return error.StreamTooLong;
        }
        if (options.stderr_limit.toInt()) |limit| {
            if (stderr_reader.buffered().len > limit) return error.StreamTooLong;
        }
    } else |err| switch (err) {
        error.EndOfStream => {},
        else => |e| return e,
    }

    try multi_reader.checkAnyError();

    const term = try wait(io, &child);

    const stdout_slice = try multi_reader.toOwnedSlice(0);
    errdefer gpa.free(stdout_slice);
    const stderr_slice = try multi_reader.toOwnedSlice(1);
    errdefer gpa.free(stderr_slice);

    return .{ .stdout = stdout_slice, .stderr = stderr_slice, .term = term };
}

/// Make the child's group the terminal's foreground group while `fg` lives,
/// so a program reading the terminal is not stopped by SIGTTIN and Ctrl+C
/// reaches the group directly. Linux only; a no-op when stdin is not a terminal.
pub const Foreground = struct {
    prev: posix.pid_t = 0,
    active: bool = false,

    pub fn give(child: *const std.process.Child) Foreground {
        if (builtin.os.tag != .linux) return .{};
        const id = child.id orelse return .{};
        const prev = tcgetpgrp(0) orelse return .{};
        if (!tcsetpgrp(0, @intCast(id))) return .{};
        return .{ .prev = prev, .active = true };
    }

    pub fn restore(self: Foreground) void {
        if (self.active) _ = tcsetpgrp(0, self.prev);
    }
};

fn tcgetpgrp(fd: posix.fd_t) ?posix.pid_t {
    var pgrp: posix.pid_t = 0;
    const rc = std.os.linux.tcgetpgrp(fd, &pgrp);
    if (posix.errno(rc) != .SUCCESS) return null;
    return pgrp;
}

/// SIGTTOU is ignored around the call: a background group may not take the
/// terminal otherwise.
fn tcsetpgrp(fd: posix.fd_t, pgrp: posix.pid_t) bool {
    const ign: posix.Sigaction = .{ .handler = .{ .handler = posix.SIG.IGN }, .mask = posix.sigemptyset(), .flags = 0 };
    var old: posix.Sigaction = undefined;
    posix.sigaction(.TTOU, &ign, &old);
    defer posix.sigaction(.TTOU, &old, null);
    var p = pgrp;
    const rc = std.os.linux.tcsetpgrp(fd, &p);
    return posix.errno(rc) == .SUCCESS;
}
