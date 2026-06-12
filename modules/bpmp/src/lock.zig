/// `botopink.lock` — sibling of `botopink.json`, machine-written by
/// `bpmp install`.
///
/// Distinct from `botopink.lock.json` (the v0.beta.18 compiler-distribution
/// lockfile owned by `lockfile.zig`). They coexist: legacy projects keep
/// using `.json` flavour; object-form projects get the new flavour.
///
/// On-disk shape:
///
/// ```json
/// {
///   "generated_by": "bpmp 0.0.1",
///   "lockfile_version": 1,
///   "deps": {
///     "<name>": {
///       "git": "<url>",         // may be "" for path: deps
///       "rev": "<sha-40>",       // empty for path: deps
///       "path": "<abs>",          // null unless this is a path: dep
///       "fetched_at": "<ISO-8601 UTC>"
///     }
///   }
/// }
/// ```
const std = @import("std");
const dep = @import("./dep/spec.zig");

pub const LOCKFILE_NAME = "botopink.lock";
pub const LOCKFILE_VERSION: u32 = 1;

pub const Error = error{
    LockfileNotFound,
    LockfileInvalid,
} || std.mem.Allocator.Error;

pub const Entry = struct {
    name: []const u8,
    git: []const u8 = "",
    rev: []const u8 = "",
    path: ?[]const u8 = null,
    fetched_at: []const u8 = "",
};

pub const Lockfile = struct {
    arena: std.heap.ArenaAllocator,
    generated_by: []const u8,
    lockfile_version: u32 = LOCKFILE_VERSION,
    entries: []Entry,

    pub fn deinit(self: *Lockfile) void {
        self.arena.deinit();
    }

    /// Find an entry by name; null if not present. O(n) — entry counts are tiny.
    pub fn find(self: *const Lockfile, name: []const u8) ?Entry {
        for (self.entries) |e| {
            if (std.mem.eql(u8, e.name, name)) return e;
        }
        return null;
    }
};

/// Read `<project_root>/botopink.lock`. Returns `LockfileNotFound` if the
/// file is missing (the typical first-install case). Caller calls `deinit`.
pub fn read(gpa: std.mem.Allocator, io: std.Io, project_root: []const u8) Error!Lockfile {
    var arena = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();

    const path_buf = try std.fs.path.join(a, &.{ project_root, LOCKFILE_NAME });
    const data = std.Io.Dir.cwd().readFileAlloc(io, path_buf, a, .limited(256 * 1024)) catch return error.LockfileNotFound;

    return parse(arena, data);
}

/// Parse a `botopink.lock` blob. `arena` carries the entire returned value
/// (ownership transfers).
pub fn parse(arena: std.heap.ArenaAllocator, data: []const u8) Error!Lockfile {
    var arena_var = arena;
    errdefer arena_var.deinit();
    const a = arena_var.allocator();

    var parsed = std.json.parseFromSlice(std.json.Value, a, data, .{}) catch return error.LockfileInvalid;
    defer parsed.deinit();
    const root = parsed.value;
    if (root != .object) return error.LockfileInvalid;

    const gen = if (root.object.get("generated_by")) |v| (if (v == .string) try a.dupe(u8, v.string) else "") else "";
    const ver: u32 = if (root.object.get("lockfile_version")) |v| (if (v == .integer) @intCast(v.integer) else LOCKFILE_VERSION) else LOCKFILE_VERSION;

    const deps_node = root.object.get("deps") orelse return Lockfile{
        .arena = arena_var,
        .generated_by = gen,
        .lockfile_version = ver,
        .entries = &.{},
    };
    if (deps_node != .object) return error.LockfileInvalid;

    var entries = try a.alloc(Entry, deps_node.object.count());
    var i: usize = 0;
    var it = deps_node.object.iterator();
    while (it.next()) |kv| {
        const name = try a.dupe(u8, kv.key_ptr.*);
        const obj = kv.value_ptr.*;
        if (obj != .object) return error.LockfileInvalid;
        entries[i] = .{
            .name = name,
            .git = if (obj.object.get("git")) |v| (if (v == .string) try a.dupe(u8, v.string) else "") else "",
            .rev = if (obj.object.get("rev")) |v| (if (v == .string) try a.dupe(u8, v.string) else "") else "",
            .path = if (obj.object.get("path")) |v| (if (v == .string) try a.dupe(u8, v.string) else null) else null,
            .fetched_at = if (obj.object.get("fetched_at")) |v| (if (v == .string) try a.dupe(u8, v.string) else "") else "",
        };
        i += 1;
    }

    return Lockfile{
        .arena = arena_var,
        .generated_by = gen,
        .lockfile_version = ver,
        .entries = entries[0..i],
    };
}

/// Serialise `entries` to disk (pretty-printed JSON, sorted by name for
/// deterministic diffs). Overwrites any existing `botopink.lock`.
pub fn write(
    gpa: std.mem.Allocator,
    io: std.Io,
    project_root: []const u8,
    entries: []const Entry,
) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    const sorted = try a.alloc(Entry, entries.len);
    @memcpy(sorted, entries);
    std.mem.sort(Entry, sorted, {}, lessThanByName);

    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    try render(&aw.writer, sorted);

    const path_buf = try std.fs.path.join(gpa, &.{ project_root, LOCKFILE_NAME });
    defer gpa.free(path_buf);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path_buf, .data = aw.written() });
}

fn lessThanByName(_: void, lhs: Entry, rhs: Entry) bool {
    return std.mem.order(u8, lhs.name, rhs.name) == .lt;
}

/// Render to an arbitrary writer (used by tests + golden snapshots).
pub fn render(w: anytype, sorted: []const Entry) !void {
    try w.print("{{\n", .{});
    try w.print("  \"generated_by\": \"bpmp {s}\",\n", .{@import("./version.zig").BPMP_VERSION});
    try w.print("  \"lockfile_version\": {d},\n", .{LOCKFILE_VERSION});
    try w.print("  \"deps\": {{", .{});
    var first = true;
    for (sorted) |e| {
        if (!first) try w.print(",", .{});
        first = false;
        try w.print("\n    \"{s}\": {{", .{e.name});
        try w.print("\n      \"git\": \"{s}\",", .{e.git});
        try w.print("\n      \"rev\": \"{s}\"", .{e.rev});
        if (e.path) |p| {
            try w.print(",\n      \"path\": \"{s}\"", .{p});
        }
        try w.print(",\n      \"fetched_at\": \"{s}\"", .{e.fetched_at});
        try w.print("\n    }}", .{});
    }
    if (!first) try w.print("\n  ", .{});
    try w.print("}}\n}}\n", .{});
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "render: empty deps" {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();
    try render(&aw.writer, &.{});
    try testing.expect(std.mem.indexOf(u8, aw.written(), "\"deps\": {}") != null);
    try testing.expect(std.mem.indexOf(u8, aw.written(), "\"lockfile_version\": 1") != null);
}

test "render: single git entry" {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();
    const entries = [_]Entry{
        .{ .name = "jhonstart", .git = "https://e/j.git", .rev = "abc123", .fetched_at = "2026-06-19T00:00:00Z" },
    };
    try render(&aw.writer, &entries);
    try testing.expect(std.mem.indexOf(u8, aw.written(), "\"jhonstart\"") != null);
    try testing.expect(std.mem.indexOf(u8, aw.written(), "\"rev\": \"abc123\"") != null);
}

test "parse: round-trip a written lockfile" {
    var aw: std.Io.Writer.Allocating = .init(testing.allocator);
    defer aw.deinit();
    const entries = [_]Entry{
        .{ .name = "jhonstart", .git = "https://e/j.git", .rev = "abc123", .fetched_at = "2026-06-19T00:00:00Z" },
        .{ .name = "emilia", .git = "https://e/e.git", .rev = "def456", .fetched_at = "2026-06-19T00:00:00Z" },
    };
    var sorted: [2]Entry = entries;
    std.mem.sort(Entry, &sorted, {}, lessThanByName);
    try render(&aw.writer, &sorted);

    const arena = std.heap.ArenaAllocator.init(testing.allocator);
    var lf = try parse(arena, aw.written());
    defer lf.deinit();
    try testing.expectEqual(@as(usize, 2), lf.entries.len);
    const j = lf.find("jhonstart").?;
    try testing.expectEqualStrings("https://e/j.git", j.git);
    try testing.expectEqualStrings("abc123", j.rev);
}

test "parse: path entry" {
    const arena = std.heap.ArenaAllocator.init(testing.allocator);
    var lf = try parse(arena,
        \\{ "lockfile_version": 1, "deps": {
        \\  "local": { "git": "", "rev": "", "path": "/abs/p", "fetched_at": "2026-06-19T00:00:00Z" }
        \\}}
    );
    defer lf.deinit();
    try testing.expectEqual(@as(usize, 1), lf.entries.len);
    try testing.expectEqualStrings("/abs/p", lf.entries[0].path.?);
}

test "parse: invalid JSON → LockfileInvalid" {
    const arena = std.heap.ArenaAllocator.init(testing.allocator);
    const r = parse(arena, "not json");
    try testing.expectError(error.LockfileInvalid, r);
}
