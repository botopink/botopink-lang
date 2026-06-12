/// `botopink.lock.json` reader/writer.
///
/// The lockfile pins every package and the toolchain by **git commit SHA**,
/// not by tag — see spec §"Lockfile" and plan §D5b. The schema is:
///
/// ```jsonc
/// {
///   "schema": 1,
///   "generated_at": "2026-06-12T15:42:11Z",
///   "botopink": { "version", "commit", "tag", "sha256", "source" },
///   "packages": {
///     "<name>": { "version", "commit", "tag", "constraint", "sha256", "source", "requires"[] }
///   }
/// }
/// ```
///
/// A schema mismatch produces an explicit "run `bpmp sync`" hint — we don't
/// auto-migrate, so the user is always in control of what bpmp pinned.
const std = @import("std");

pub const FILENAME = "botopink.lock.json";
pub const SCHEMA = 1;

pub const Error = error{
    LockfileNotFound,
    LockfileInvalid,
    SchemaMismatch,
    NotAnObject,
} || std.mem.Allocator.Error || std.json.ParseError(std.json.Scanner);

/// Toolchain pin — `botopink` (and bundled bpmp) version.
pub const ToolchainPin = struct {
    version: []const u8,
    commit: []const u8,
    tag: []const u8,
    sha256: []const u8,
    source: []const u8,
};

/// One locked package pin.
pub const PackagePin = struct {
    name: []const u8,
    version: []const u8,
    commit: []const u8,
    tag: []const u8,
    constraint: []const u8,
    sha256: []const u8,
    source: []const u8,
    requires: []const []const u8 = &.{},
};

pub const Lockfile = struct {
    gpa: std.mem.Allocator,
    /// Heap-allocated so any allocator pointers std.json baked into the parsed
    /// tree survive any move of the Lockfile value (`Manifest` does the same).
    arena: *std.heap.ArenaAllocator,
    generated_at: []const u8,
    botopink: ?ToolchainPin,
    packages: []PackagePin,

    pub fn deinit(self: *Lockfile) void {
        self.arena.deinit();
        self.gpa.destroy(self.arena);
    }

    pub fn findPackage(self: *const Lockfile, name: []const u8) ?*const PackagePin {
        for (self.packages) |*p| {
            if (std.mem.eql(u8, p.name, name)) return p;
        }
        return null;
    }
};

// ── Read ───────────────────────────────────────────────────────────────────────

pub fn parse(gpa: std.mem.Allocator, data: []const u8) Error!Lockfile {
    const arena = try gpa.create(std.heap.ArenaAllocator);
    errdefer gpa.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();

    const tree = try std.json.parseFromSliceLeaky(std.json.Value, a, data, .{});
    if (tree != .object) return error.NotAnObject;
    const o = tree.object;

    const schema_val = o.get("schema") orelse return error.SchemaMismatch;
    if (schema_val != .integer or schema_val.integer != SCHEMA) return error.SchemaMismatch;

    const generated_at = blk: {
        const v = o.get("generated_at") orelse break :blk "";
        break :blk if (v == .string) v.string else "";
    };

    var bp_pin: ?ToolchainPin = null;
    if (o.get("botopink")) |v| {
        if (v != .object) return error.LockfileInvalid;
        bp_pin = try readToolchain(v.object);
    }

    var pkgs: std.ArrayListUnmanaged(PackagePin) = .empty;
    if (o.get("packages")) |v| {
        if (v != .object) return error.LockfileInvalid;
        for (v.object.keys()) |k| {
            const entry = v.object.get(k) orelse continue;
            if (entry != .object) return error.LockfileInvalid;
            try pkgs.append(a, try readPackage(a, k, entry.object));
        }
    }

    return .{
        .gpa = gpa,
        .arena = arena,
        .generated_at = generated_at,
        .botopink = bp_pin,
        .packages = try pkgs.toOwnedSlice(a),
    };
}

fn readString(map: std.json.ObjectMap, key: []const u8) Error![]const u8 {
    const v = map.get(key) orelse return error.LockfileInvalid;
    if (v != .string) return error.LockfileInvalid;
    return v.string;
}

fn readToolchain(map: std.json.ObjectMap) Error!ToolchainPin {
    return .{
        .version = try readString(map, "version"),
        .commit = try readString(map, "commit"),
        .tag = try readString(map, "tag"),
        .sha256 = try readString(map, "sha256"),
        .source = try readString(map, "source"),
    };
}

fn readPackage(a: std.mem.Allocator, name: []const u8, map: std.json.ObjectMap) Error!PackagePin {
    var requires: []const []const u8 = &.{};
    if (map.get("requires")) |v| {
        if (v != .array) return error.LockfileInvalid;
        var list = try a.alloc([]const u8, v.array.items.len);
        for (v.array.items, 0..) |entry, i| {
            if (entry != .string) return error.LockfileInvalid;
            list[i] = entry.string;
        }
        requires = list;
    }
    return .{
        .name = name,
        .version = try readString(map, "version"),
        .commit = try readString(map, "commit"),
        .tag = try readString(map, "tag"),
        .constraint = try readString(map, "constraint"),
        .sha256 = try readString(map, "sha256"),
        .source = try readString(map, "source"),
        .requires = requires,
    };
}

/// Read `<dir>/<FILENAME>` and parse it.
pub fn read(gpa: std.mem.Allocator, io: std.Io, dir: []const u8) Error!Lockfile {
    const path = try std.fs.path.join(gpa, &.{ dir, FILENAME });
    defer gpa.free(path);
    const data = std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .limited(1024 * 1024)) catch
        return error.LockfileNotFound;
    defer gpa.free(data);
    return parse(gpa, data);
}

// ── Write ──────────────────────────────────────────────────────────────────────

pub fn writeAlloc(gpa: std.mem.Allocator, lf: *const Lockfile) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const a = arena.allocator();

    var root: std.json.ObjectMap = .empty;
    try root.put(a, "schema", .{ .integer = SCHEMA });
    try root.put(a, "generated_at", .{ .string = lf.generated_at });

    if (lf.botopink) |bp| {
        var bo: std.json.ObjectMap = .empty;
        try bo.put(a, "version", .{ .string = bp.version });
        try bo.put(a, "commit", .{ .string = bp.commit });
        try bo.put(a, "tag", .{ .string = bp.tag });
        try bo.put(a, "sha256", .{ .string = bp.sha256 });
        try bo.put(a, "source", .{ .string = bp.source });
        try root.put(a, "botopink", .{ .object = bo });
    }

    var pkgs_obj: std.json.ObjectMap = .empty;
    for (lf.packages) |p| {
        var po: std.json.ObjectMap = .empty;
        try po.put(a, "version", .{ .string = p.version });
        try po.put(a, "commit", .{ .string = p.commit });
        try po.put(a, "tag", .{ .string = p.tag });
        try po.put(a, "constraint", .{ .string = p.constraint });
        try po.put(a, "sha256", .{ .string = p.sha256 });
        try po.put(a, "source", .{ .string = p.source });
        var req_arr = std.json.Array.init(a);
        for (p.requires) |r| try req_arr.append(.{ .string = r });
        try po.put(a, "requires", .{ .array = req_arr });
        try pkgs_obj.put(a, p.name, .{ .object = po });
    }
    try root.put(a, "packages", .{ .object = pkgs_obj });

    var aw: std.Io.Writer.Allocating = .init(gpa);
    defer aw.deinit();
    try std.json.Stringify.value(std.json.Value{ .object = root }, .{ .whitespace = .indent_2 }, &aw.writer);
    try aw.writer.writeByte('\n');
    return aw.toOwnedSlice();
}

pub fn write(gpa: std.mem.Allocator, io: std.Io, dir: []const u8, lf: *const Lockfile) !void {
    const path = try std.fs.path.join(gpa, &.{ dir, FILENAME });
    defer gpa.free(path);
    const text = try writeAlloc(gpa, lf);
    defer gpa.free(text);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = text });
}

/// Create a fresh empty lockfile (used by `bpmp init`). The `generated_at`
/// slice is duplicated upfront before the struct moves, then patched in by
/// referencing the arena indirectly to avoid the captured-arena footgun.
pub fn create(gpa: std.mem.Allocator, generated_at: []const u8) !Lockfile {
    const arena = try gpa.create(std.heap.ArenaAllocator);
    errdefer gpa.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const stamp = try arena.allocator().dupe(u8, generated_at);
    const empty_pkgs = try arena.allocator().alloc(PackagePin, 0);
    return .{
        .gpa = gpa,
        .arena = arena,
        .generated_at = stamp,
        .botopink = null,
        .packages = empty_pkgs,
    };
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "schema mismatch produces explicit error" {
    try testing.expectError(error.SchemaMismatch, parse(testing.allocator,
        \\{ "schema": 9999, "packages": {} }
    ));
}

test "schema absent → mismatch (we don't migrate)" {
    try testing.expectError(error.SchemaMismatch, parse(testing.allocator,
        \\{ "packages": {} }
    ));
}

test "parse minimal lockfile" {
    var lf = try parse(testing.allocator,
        \\{ "schema": 1, "generated_at": "2026-06-12T00:00:00Z", "packages": {} }
    );
    defer lf.deinit();
    try testing.expectEqualStrings("2026-06-12T00:00:00Z", lf.generated_at);
    try testing.expect(lf.botopink == null);
    try testing.expectEqual(@as(usize, 0), lf.packages.len);
}

test "round-trip preserves package shape" {
    const src =
        \\{
        \\  "schema": 1,
        \\  "generated_at": "now",
        \\  "botopink": { "version":"0.0.1","commit":"a","tag":"v0.0.1","sha256":"d","source":"github.com/botopink/botopink-lang" },
        \\  "packages": {
        \\    "erika": { "version":"0.0.1","commit":"e","tag":"0.0.1","constraint":"^0.0.1","sha256":"s","source":"github.com/botopink/erika","requires":[] }
        \\  }
        \\}
    ;
    var lf = try parse(testing.allocator, src);
    defer lf.deinit();

    try testing.expectEqualStrings("0.0.1", lf.botopink.?.version);
    try testing.expectEqualStrings("a", lf.botopink.?.commit);

    const erika = lf.findPackage("erika") orelse return error.MissingPackage;
    try testing.expectEqualStrings("e", erika.commit);
    try testing.expectEqualStrings("^0.0.1", erika.constraint);

    const out = try writeAlloc(testing.allocator, &lf);
    defer testing.allocator.free(out);

    var rt = try parse(testing.allocator, out);
    defer rt.deinit();
    const erika2 = rt.findPackage("erika") orelse return error.MissingPackage;
    try testing.expectEqualStrings("e", erika2.commit);
}

test "create builds an empty lockfile at schema 1" {
    var lf = try create(testing.allocator, "0001");
    defer lf.deinit();
    const out = try writeAlloc(testing.allocator, &lf);
    defer testing.allocator.free(out);
    try testing.expect(std.mem.indexOf(u8, out, "\"schema\": 1") != null);
}
