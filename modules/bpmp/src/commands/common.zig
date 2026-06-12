/// Shared helpers used by every command — keeps the per-command file small.
const std = @import("std");
const cli = @import("../cli.zig");

pub fn writeStdout(ctx: cli.Context, text: []const u8) void {
    std.Io.File.stdout().writeStreamingAll(ctx.io, text) catch {};
}

pub fn printf(ctx: cli.Context, comptime fmt: []const u8, args: anytype) void {
    const text = std.fmt.allocPrint(ctx.gpa, fmt, args) catch return;
    defer ctx.gpa.free(text);
    writeStdout(ctx, text);
}

pub fn errMsg(msg: []const u8) u8 {
    std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: {s}\n", .{msg});
    return 1;
}

pub fn errFmt(comptime fmt: []const u8, args: anytype) u8 {
    std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: " ++ fmt ++ "\n", args);
    return 1;
}

pub fn hintMsg(msg: []const u8) void {
    std.debug.print("\x1b[1m\x1b[36mhint\x1b[0m: {s}\n", .{msg});
}

pub fn warnMsg(msg: []const u8) void {
    std.debug.print("\x1b[1m\x1b[33mwarning\x1b[0m: {s}\n", .{msg});
}

pub fn warnMsgFmt(ctx: cli.Context, comptime fmt: []const u8, args: anytype) void {
    _ = ctx;
    std.debug.print("\x1b[1m\x1b[33mwarning\x1b[0m: " ++ fmt ++ "\n", args);
}
