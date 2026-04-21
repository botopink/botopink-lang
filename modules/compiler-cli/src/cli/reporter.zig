/// CLI status output — colored prefixes in the style of gleam/cargo.
///
/// All messages go to stderr via `std.debug.print`.
/// Pass `io` only for the stdout helpers (help / version).
const std = @import("std");

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
    std.debug.print("  {s}Compiling{s} {d} module(s)...\n", .{ cyan, reset, n });
}

pub fn compiled(elapsed_ms: f64) void {
    std.debug.print("   {s}Compiled{s} in {d:.2}ms\n", .{ green, reset, elapsed_ms });
}

pub fn checking(n: usize) void {
    std.debug.print("  {s}Checking{s} {d} module(s)...\n", .{ cyan, reset, n });
}

pub fn checked(elapsed_ms: f64) void {
    std.debug.print("   {s}Checked{s} in {d:.2}ms\n", .{ green, reset, elapsed_ms });
}

// ── Format ────────────────────────────────────────────────────────────────────

pub fn formatUnchanged(path: []const u8) void {
    std.debug.print("  {s}Unchanged{s} {s}\n", .{ dim, reset, path });
}

pub fn formatChanged(path: []const u8) void {
    std.debug.print("  {s}Formatted{s} {s}\n", .{ cyan, reset, path });
}

// ── New project ───────────────────────────────────────────────────────────────

pub fn created(path: []const u8) void {
    std.debug.print("   {s}Created{s} {s}\n", .{ green, reset, path });
}

// ── Errors / hints ────────────────────────────────────────────────────────────

pub fn errMsg(msg: []const u8) void {
    std.debug.print("{s}{s}error{s}: {s}\n", .{ bold, red, reset, msg });
}

pub fn hintMsg(msg: []const u8) void {
    std.debug.print(" {s}hint{s}: {s}\n", .{ yellow, reset, msg });
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
