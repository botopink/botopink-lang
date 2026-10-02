/// `botopink clean` — remove build artifacts.
///
/// Prints `Removed <dir>/` only for a directory that is gone afterwards, and
/// exits 1 when any delete failed (contract row C13).
///
/// Every build cache lives under `.botopinkbuild/cache/` of the cache root
/// (decision 225, `libs.cacheRoot`): the project's own `.botopinkbuild/`, which
/// goes whole, or — for a workspace member — the workspace root's, whose
/// `.botopinkbuild/cache/` goes too, so a clean leaves no cache the next build
/// of this package would read. Nothing outside those directories is a cache.
const std = @import("std");
const manifest = @import("manifest");
const reporter = @import("./reporter.zig");
const libs = @import("./libs.zig");

const ARTIFACTS = [_][]const u8{ "out", ".botopinkbuild" };

pub fn run(gpa: std.mem.Allocator, io: std.Io) !u8 {
    var failed = removeAll(io, std.Io.Dir.cwd()) != 0;

    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &cwd_buf);
    var err: ?manifest.Located = null;
    const ws = manifest.enclosingWorkspace(arena, io, cwd_buf[0..n], &err) catch |e| switch (e) {
        error.Invalid => {
            // The member cannot know its workspace, so its cache root is unknown.
            err.?.print();
            return 1;
        },
        else => |other| return other,
    } orelse return if (failed) 1 else 0;
    const cache = try std.fs.path.join(arena, &.{ ws.dir, libs.CACHE_DIR });
    if (removeOne(io, std.Io.Dir.cwd(), cache)) failed = true;
    return if (failed) 1 else 0;
}

/// Delete `name` under `dir`; true when the delete failed (reported).
fn removeOne(io: std.Io, dir: std.Io.Dir, name: []const u8) bool {
    dir.deleteTree(io, name) catch |err| {
        var buf: [std.fs.max_path_bytes + 64]u8 = undefined;
        reporter.errMsg(std.fmt.bufPrint(&buf, "could not remove {s}/: {s}", .{ name, @errorName(err) }) catch "could not remove a build directory");
        return true;
    };
    std.debug.print("   {s}Removed{s} {s}/\n", .{ "\x1b[32m", "\x1b[0m", name });
    return false;
}

fn removeAll(io: std.Io, dir: std.Io.Dir) u8 {
    var failed = false;
    for (ARTIFACTS) |name| {
        if (removeOne(io, dir, name)) failed = true;
    }
    return if (failed) 1 else 0;
}

test "clean removes both artifact trees and succeeds when they are absent" {
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();
    const io = std.testing.io;
    // Populated from `ARTIFACTS` itself, never from a re-spelling of the two
    // names: the test then covers exactly what `removeAll` deletes, and it
    // names no path anchored at the process cwd (`scripts/check-test-scratch.sh`).
    var nested: [ARTIFACTS.len][]const u8 = undefined;
    inline for (ARTIFACTS, 0..) |name, i| {
        nested[i] = name ++ "/nested";
        try tmp.dir.createDirPath(io, nested[i]);
    }
    try std.testing.expectEqual(@as(u8, 0), removeAll(io, tmp.dir));
    for (ARTIFACTS) |name| try std.testing.expectError(error.FileNotFound, tmp.dir.access(io, name, .{}));
    try std.testing.expectEqual(@as(u8, 0), removeAll(io, tmp.dir));
}
