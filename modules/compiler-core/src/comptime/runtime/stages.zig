//! Where an evaluation's time goes — an observation-only clock, read by
//! `scripts/comptime_bench.sh`'s in-compiler split (front 14 step 2, front 18
//! step 3).
//!
//! `BOTOPINK_COMPTIME_STAGES=<file>` (an absolute path) makes every timed
//! stage append one line `<stage> TAB <nanoseconds>` to `<file>`, opened once
//! with `O_APPEND` so each line is one `write`. Unset (or empty), `start`
//! answers 0 and `stop` returns at once: nothing is opened, read or written,
//! and no answer of the compiler depends on it. The variable is read once per
//! process. Not available in the browser build (no libc there): every call is
//! a no-op on `wasm32`.
//!
//! The stages, in the order one evaluation meets them:
//!
//! | Stage | What it times |
//! |---|---|
//! | `memo_key` | `infer.zig`'s template memo key (`templateEval.memoKey`) |
//! | `module` | the evaluator's `buildModule` (emit memo key, emit or memo hit, argument plan) |
//! | `encode` | the argument as external term format (`etf.encode`) |
//! | `lower` | the module's runtime program: `wat/program.zig` / `beam/program.zig` (a cache hit after the first) |
//! | `instance` | wat: the module's wasm3 instance (`persistent_wat.zig`: environment, runtime, parse, load — or the reset of a kept one) |
//! | `run` | wat: `bp_init`, the argument's copy, `bp_main` and the reply's read-back |
//! | `frame` | BEAM: cmd 4 (first time only) + cmd 3's round trip (`persistent_beam.evalBeamWithArg`) |
//! | `listing` | the trace listing of the evaluation (`runtime.listingOf` + its argument comment) |
//! | `outcome` | the reply parsed into the evaluator's outcome |
const std = @import("std");
const builtin = @import("builtin");

pub const env_name = "BOTOPINK_COMPTIME_STAGES";

pub const Stage = enum { memo_key, module, encode, lower, instance, run, frame, listing, outcome };

const supported = !builtin.cpu.arch.isWasm() and builtin.link_libc;

/// -2 not read yet, -1 off, otherwise the open file.
var fd: std.atomic.Value(i32) = .init(-2);

fn file() ?std.c.fd_t {
    if (comptime !supported) return null;
    const cur = fd.load(.acquire);
    if (cur >= 0) return cur;
    if (cur == -1) return null;
    const opened: i32 = blk: {
        const path = std.c.getenv(env_name) orelse break :blk -1;
        if (path[0] == 0) break :blk -1;
        const f = std.c.open(path, .{ .ACCMODE = .WRONLY, .CREAT = true, .APPEND = true, .CLOEXEC = true }, @as(std.c.mode_t, 0o644));
        break :blk if (f < 0) -1 else f;
    };
    if (fd.cmpxchgStrong(-2, opened, .acq_rel, .acquire)) |won| {
        if (opened >= 0) _ = std.c.close(opened);
        return if (won >= 0) won else null;
    }
    return if (opened >= 0) opened else null;
}

fn now() u64 {
    if (comptime !supported) return 0;
    var ts: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &ts) != 0) return 0;
    return @as(u64, @intCast(ts.sec)) * std.time.ns_per_s + @as(u64, @intCast(ts.nsec));
}

/// A stage's start, or 0 when the clock is off.
pub fn start() u64 {
    if (comptime !supported) return 0;
    if (file() == null) return 0;
    return now();
}

/// Record `stage` as having run since `t0` (`start`'s answer).
pub fn stop(stage: Stage, t0: u64) void {
    if (comptime !supported) return;
    if (t0 == 0) return;
    const f = file() orelse return;
    const elapsed = now() -| t0;
    var buf: [64]u8 = undefined;
    const line = std.fmt.bufPrint(&buf, "{s}\t{d}\n", .{ @tagName(stage), elapsed }) catch return;
    _ = std.c.write(f, line.ptr, line.len);
}
