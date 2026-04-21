/// Project configuration — loaded from `botopink.json` in the project root.
const std = @import("std");

// ── Types ─────────────────────────────────────────────────────────────────────

pub const Target = enum {
    commonJS,
    erlang,

    pub fn fromString(s: []const u8) ?Target {
        if (std.mem.eql(u8, s, "commonJS")) return .commonJS;
        if (std.mem.eql(u8, s, "erlang")) return .erlang;
        return null;
    }

    pub fn toString(self: Target) []const u8 {
        return switch (self) {
            .commonJS => "commonJS",
            .erlang => "erlang",
        };
    }
};

/// Parsed representation of `botopink.json`.
pub const ProjectConfig = struct {
    name: []const u8,
    version: []const u8 = "0.1.0",
    target: []const u8 = "commonJS",

    pub fn parsedTarget(self: ProjectConfig) Target {
        return Target.fromString(self.target) orelse .commonJS;
    }
};

// ── Loader ────────────────────────────────────────────────────────────────────

pub const LoadError = error{
    ConfigNotFound,
    ConfigInvalid,
} || std.mem.Allocator.Error;

/// Load and parse `botopink.json` from the current working directory.
/// The returned value and all strings in it are owned by `arena`.
pub fn load(arena: std.mem.Allocator, io: std.Io) LoadError!ProjectConfig {
    const data = std.Io.Dir.cwd().readFileAlloc(
        io,
        "botopink.json",
        arena,
        .limited(64 * 1024),
    ) catch return error.ConfigNotFound;

    const parsed = std.json.parseFromSliceLeaky(
        ProjectConfig,
        arena,
        data,
        .{ .ignore_unknown_fields = true },
    ) catch return error.ConfigInvalid;

    return parsed;
}

/// Walk parent directories until `botopink.json` is found or the fs root is
/// reached. Returns the path to that directory (caller owns via `gpa`), or
/// null if not found.
pub fn findProjectRoot(gpa: std.mem.Allocator, io: std.Io) !?[]u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &buf);
    var dir = buf[0..n];

    while (true) {
        const candidate = try std.fs.path.join(gpa, &.{ dir, "botopink.json" });
        defer gpa.free(candidate);

        std.Io.Dir.cwd().access(io, candidate, .{}) catch {
            const parent = std.fs.path.dirname(dir) orelse return null;
            if (std.mem.eql(u8, parent, dir)) return null;
            dir = buf[0..parent.len];
            @memcpy(buf[0..parent.len], parent);
            continue;
        };

        return try gpa.dupe(u8, dir);
    }
}
