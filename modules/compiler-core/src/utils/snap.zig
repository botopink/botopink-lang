const std = @import("std");
const SourceLocation = std.builtin.SourceLocation;
const pretty = @import("pretty.zig");
const jsonDiff = @import("json_diff.zig");

pub const SNAP_DIR = "snapshots";

/// true on Zig 0.16+, false on 0.15.x
const newIo = @hasDecl(std, "Io") and @hasDecl(std.Io, "Dir");

pub const OhSnap = struct {
    pub fn snap(_: OhSnap, location: SourceLocation, _: []const u8) Snap {
        return .{ .location = location };
    }
};

pub const Snap = struct {
    location: SourceLocation,

    pub fn expectEqual(self: Snap, args: anytype) !void {
        const allocator = std.testing.allocator;
        const got = try pretty.formatAlloc(allocator, args);
        defer allocator.free(got);

        const path = try snapFilePath(allocator, self.location);
        defer allocator.free(path);

        try compareOrCreate(allocator, path, got);
    }
};

/// File-based snapshot: reads `snapshots/{name}.botopink` as source, compares
/// result against `snapshots/{name}.snap.md` (creates it on first run).
pub fn check(allocator: std.mem.Allocator, name: []const u8, args: anytype) !void {
    const got = try pretty.formatAlloc(allocator, args);
    defer allocator.free(got);

    const snapPath = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.snap.md", .{name});
    defer allocator.free(snapPath);

    try compareOrCreate(allocator, snapPath, got);
}

/// File-based snapshot for plain text (not JSON-encoded).
/// Compares `text` directly against `snapshots/{name}.snap.md`.
pub fn checkText(allocator: std.mem.Allocator, name: []const u8, text: []const u8) !void {
    const snapPath = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.snap.md", .{name});
    defer allocator.free(snapPath);
    try compareOrCreate(allocator, snapPath, text);
}

/// Reads `snapshots/{name}.botopink`. Caller owns the returned slice.
pub fn readSource(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const path = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.botopink", .{name});
    defer allocator.free(path);
    return readFile(allocator, path);
}

// ── internals ─────────────────────────────────────────────────────────────────

fn compareOrCreate(allocator: std.mem.Allocator, snapPath: []const u8, got: []const u8) !void {
    const existing = readFile(allocator, snapPath) catch |err| switch (err) {
        error.FileNotFound => {
            try writeFile(snapPath, got);
            std.debug.print("snap created: {s}\n", .{snapPath});
            return;
        },
        else => return err,
    };
    defer allocator.free(existing);

    const expected = std.mem.trim(u8, existing, "\n\r");
    const actual = std.mem.trim(u8, got, "\n\r");

    if (std.mem.eql(u8, expected, actual)) {
        // Delete stale .new file if it exists from a previous failed run.
        const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snapPath});
        defer allocator.free(new_path);
        deleteFile(new_path);
        return;
    }

    // Write a .new file next to the original so the diff is easy to inspect.
    const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snapPath});
    defer allocator.free(new_path);
    try writeFile(new_path, got);

    std.debug.print("\nsnap mismatch: {s}\n", .{snapPath});
    {
        // Only attempt JSON diff if both expected and actual look like JSON
        const looks_like_json = std.mem.trim(u8, expected, " \n\r\t").len > 0 and
            std.mem.trim(u8, expected, " \n\r\t")[0] == '[' or
            std.mem.trim(u8, expected, " \n\r\t")[0] == '{';
        
        if (looks_like_json) {
            var aw: std.Io.Writer.Allocating = .init(allocator);
            defer aw.deinit();
            _ = jsonDiff.diff(allocator, expected, actual, &aw.writer) catch {};
            const diffOut = aw.toOwnedSlice() catch null;
            if (diffOut) |d| {
                defer allocator.free(d);
                std.debug.print("{s}\n", .{d});
            }
        }
    }
    std.debug.print("new output written to: {s}\n", .{new_path});
    return error.SnapshotMismatch;
}

fn snapFilePath(allocator: std.mem.Allocator, loc: SourceLocation) ![]u8 {
    const safe = try allocator.dupe(u8, loc.file);
    defer allocator.free(safe);
    for (safe) |*c| {
        if (c.* == '/' or c.* == '\\' or c.* == '.') c.* = '_';
    }
    return std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}_{d}.snap.md", .{ safe, loc.line });
}

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (newIo) {
        return std.Io.Dir.cwd().readFileAlloc(std.testing.io, path, allocator, .unlimited);
    } else {
        return std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024 * 1024);
    }
}

fn writeFile(path: []const u8, content: []const u8) !void {
    // Extract the directory component of path (everything before the last slash).
    const dir_part: []const u8 = blk: {
        var i = path.len;
        while (i > 0) : (i -= 1) {
            if (path[i - 1] == '/' or path[i - 1] == '\\') break :blk path[0 .. i - 1];
        }
        break :blk "";
    };

    if (newIo) {
        const io = std.testing.io;
        const cwd = std.Io.Dir.cwd();
        if (dir_part.len > 0) {
            cwd.createDirPath(io, dir_part) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try cwd.writeFile(io, .{ .sub_path = path, .data = content });
    } else {
        if (dir_part.len > 0) {
            std.fs.cwd().makePath(dir_part) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try std.fs.cwd().writeFile(.{ .sub_path = path, .data = content });
    }
}

fn deleteFile(path: []const u8) void {
    if (newIo) {
        std.Io.Dir.cwd().deleteFile(std.testing.io, path) catch {};
    } else {
        std.fs.cwd().deleteFile(path) catch {};
    }
}
