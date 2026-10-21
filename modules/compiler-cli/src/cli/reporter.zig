/// CLI status output — colored prefixes.
///
/// All messages go to stderr via `print` — `std.debug.print`, unless a caller
/// has pointed `sink` at a buffer (`botopink cell check`, `cell.zig`, reads
/// what a build would have printed). Pass `io` only for the stdout helpers
/// (help / version).
const std = @import("std");

// ── The stderr sink ──────────────────────────────────────────────────────────

/// Where the CLI's stderr text goes while it is set: every message of this
/// file, every diagnostic of `diagnostics.zig`, the resolver's and the
/// dependency loader's refusals, and the OTP tools' stderr relayed by
/// `otp.job`. `cell.zig` sets it around one in-process build of a cell and
/// reads the refusals back from the text, so a cell's answer is exactly what
/// `botopink build` prints. Null (the default) is stderr. The CLI is one
/// thread; nothing sets it concurrently.
pub var sink: ?*std.Io.Writer = null;

/// `botopink build --json` (decision 798 (6)): every message printed is also
/// appended here, so the build can read its refusals back as events while its
/// stderr stays as it is.
pub var capture: ?*std.Io.Writer = null;

/// Print to `sink` when it is set, else to stderr (`std.debug.print`).
pub fn print(comptime fmt: []const u8, args: anytype) void {
    if (capture) |c| c.print(fmt, args) catch {};
    if (sink) |w| {
        w.print(fmt, args) catch {};
    } else std.debug.print(fmt, args);
}

// ── ANSI escape sequences ────────────────────────────────────────────────────

const reset = "\x1b[0m";
const bold = "\x1b[1m";
const dim = "\x1b[2m";
const red = "\x1b[31m";
const green = "\x1b[32m";
const yellow = "\x1b[33m";
const cyan = "\x1b[36m";

// ── Compiler lifecycle ────────────────────────────────────────────────────────

pub fn compiling(n: usize) void {
    print("  {s}Compiling{s} {d} module(s)...\n", .{ cyan, reset, n });
}

pub fn compiled(elapsed_ms: f64) void {
    print("   {s}Compiled{s} in {d:.2}ms\n", .{ green, reset, elapsed_ms });
}

pub fn checking(n: usize) void {
    print("  {s}Checking{s} {d} module(s)...\n", .{ cyan, reset, n });
}

pub fn checked(elapsed_ms: f64) void {
    print("   {s}Checked{s} in {d:.2}ms\n", .{ green, reset, elapsed_ms });
}

// ── Format ────────────────────────────────────────────────────────────────────

pub fn formatUnchanged(path: []const u8) void {
    print("  {s}Unchanged{s} {s}\n", .{ dim, reset, path });
}

pub fn formatChanged(path: []const u8) void {
    print("  {s}Formatted{s} {s}\n", .{ cyan, reset, path });
}

// ── New project ───────────────────────────────────────────────────────────────

pub fn created(path: []const u8) void {
    print("   {s}Created{s} {s}\n", .{ green, reset, path });
}

// ── Errors / hints ────────────────────────────────────────────────────────────

pub fn errMsg(msg: []const u8) void {
    print("{s}{s}error{s}: {s}\n", .{ bold, red, reset, msg });
}

/// `error[<code>]: <msg>` — an unlocated refusal that carries its code.
pub fn errCode(code: []const u8, msg: []const u8) void {
    print("{s}{s}error[{s}]{s}: {s}\n", .{ bold, red, code, reset, msg });
}

pub fn hintMsg(msg: []const u8) void {
    print(" {s}hint{s}: {s}\n", .{ yellow, reset, msg });
}

pub fn warnMsg(msg: []const u8) void {
    print("{s}{s}warning{s}: {s}\n", .{ bold, yellow, reset, msg });
}

/// Warning with a trailing detail string (e.g. a file path), dimmed.
pub fn warnDetail(msg: []const u8, detail: []const u8) void {
    print("{s}{s}warning{s}: {s} {s}{s}{s}\n", .{ bold, yellow, reset, msg, dim, detail, reset });
}

// ── Stdout helpers ────────────────────────────────────────────────────────────

/// Write `text` to stdout. Used for help text and version output.
pub fn stdout(io: std.Io, text: []const u8) void {
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};
}

/// Helper: milliseconds from a nanosecond duration value.
pub fn nsToMs(ns: i96) f64 {
    return @as(f64, @floatFromInt(@max(ns, 0))) / 1_000_000.0;
}
