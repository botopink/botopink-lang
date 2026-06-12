/// `botopink clean` — remove build artifacts.
const std = @import("std");
const reporter = @import("./reporter.zig");

const ARTIFACTS = [_][]const u8{ "out", ".botopinkbuild" };

pub fn run(io: std.Io) !u8 {
    const cwd = std.Io.Dir.cwd();
    for (ARTIFACTS) |dir| {
        cwd.deleteTree(io, dir) catch |err| {
            std.debug.print("  warning: could not remove {s}: {s}\n", .{ dir, @errorName(err) });
        };
        std.debug.print("   {s}Removed{s} {s}/\n", .{ "\x1b[32m", "\x1b[0m", dir });
    }
    return 0;
}
