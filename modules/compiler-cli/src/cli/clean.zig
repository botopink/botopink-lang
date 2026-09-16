/// `botopink clean` — remove build artifacts.
///
/// Prints `Removed <dir>/` only for a directory that is gone afterwards, and
/// exits 1 when any delete failed (contract row C13).
const std = @import("std");
const reporter = @import("./reporter.zig");

const ARTIFACTS = [_][]const u8{ "out", ".botopinkbuild" };

pub fn run(io: std.Io) !u8 {
    return removeAll(io, std.Io.Dir.cwd());
}

fn removeAll(io: std.Io, dir: std.Io.Dir) u8 {
    var failed = false;
    for (ARTIFACTS) |name| {
        dir.deleteTree(io, name) catch |err| {
            failed = true;
            var buf: [256]u8 = undefined;
            reporter.errMsg(std.fmt.bufPrint(&buf, "could not remove {s}/: {s}", .{ name, @errorName(err) }) catch "could not remove a build directory");
            continue;
        };
        std.debug.print("   {s}Removed{s} {s}/\n", .{ "\x1b[32m", "\x1b[0m", name });
    }
    return if (failed) 1 else 0;
}

test "clean removes both artifact trees and succeeds when they are absent" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;
    try tmp.dir.createDirPath(io, "out/nested");
    try tmp.dir.createDirPath(io, ".botopinkbuild/tmp");
    try std.testing.expectEqual(@as(u8, 0), removeAll(io, tmp.dir));
    try std.testing.expectError(error.FileNotFound, tmp.dir.access(io, "out", .{}));
    try std.testing.expectEqual(@as(u8, 0), removeAll(io, tmp.dir));
}
