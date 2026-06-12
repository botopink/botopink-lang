/// `DepSpec` mirror for bpmp.
///
/// `modules/compiler-cli/src/cli/config.zig` already carries the canonical
/// `DepEntry`/`DepSpec`/`DepRef` shapes, but compiler-cli is a downstream of
/// `compiler-core` which in turn pulls all of botopink. bpmp keeps a much
/// thinner build graph (no compiler-core dep), so it owns a parallel copy of
/// the same shape — both parsers feed off the same `botopink.json` and the
/// same JSON nodes. The two definitions are intentionally kept byte-equal at
/// the field level; cross-checked by `dep_spec_parity.zig` in `tests/`.
const std = @import("std");

pub const DepRef = union(enum) {
    branch: []const u8,
    rev: []const u8,
    tag: []const u8,
    none,
};

pub const DepSpec = struct {
    git: ?[]const u8 = null,
    path: ?[]const u8 = null,
    ref: DepRef = .none,

    /// True when this spec carries a git source. `bpmp install` clones on
    /// these; the `path:` variant symlinks instead.
    pub fn isGit(self: DepSpec) bool {
        return self.git != null;
    }

    /// True when this spec is purely local (no clone needed).
    pub fn isPath(self: DepSpec) bool {
        return self.path != null and self.git == null;
    }
};

pub const DepEntry = struct {
    name: []const u8,
    spec: ?DepSpec = null,
};

/// Whether the project's `dependencies` is in the new object form (i.e. at
/// least one entry carries a `DepSpec`). Drives the bpmp dispatch — legacy
/// `[…]` projects keep using the v18 compiler-distribution path.
pub fn anySpec(deps: []const DepEntry) bool {
    for (deps) |d| if (d.spec != null) return true;
    return false;
}

/// Parse `dependencies` directly off a `botopink.json` blob without taking a
/// compiler-cli dep. Diagnostics are collected into `diags`. Returns the
/// normalised `[]DepEntry` (legacy array form → spec=null; object form →
/// spec=DepSpec); empty slice on shape-level failure.
pub fn parseFromManifest(
    arena: std.mem.Allocator,
    json_bytes: []const u8,
    diags: *std.ArrayListUnmanaged(Diagnostic),
) ![]const DepEntry {
    var parsed = std.json.parseFromSlice(std.json.Value, arena, json_bytes, .{}) catch {
        try diags.append(arena, .{ .code = .invalid_json });
        return &.{};
    };
    defer parsed.deinit();
    const root = parsed.value;
    if (root != .object) {
        try diags.append(arena, .{ .code = .invalid_shape });
        return &.{};
    }
    const node = root.object.get("dependencies") orelse return &.{};
    return switch (node) {
        .array => parseArrayForm(arena, node.array, diags),
        .object => parseObjectForm(arena, node.object, diags),
        else => blk: {
            try diags.append(arena, .{ .code = .invalid_shape });
            break :blk &.{};
        },
    };
}

pub const DiagnosticCode = enum {
    invalid_json,
    invalid_shape, // DEP-001 equivalent for bpmp side.
    missing_source, // DEP-002.
    ambiguous_ref, // DEP-003.
};

pub const Diagnostic = struct {
    code: DiagnosticCode,
    name: []const u8 = "",
};

fn parseArrayForm(arena: std.mem.Allocator, arr: std.json.Array, diags: *std.ArrayListUnmanaged(Diagnostic)) ![]const DepEntry {
    var out = try arena.alloc(DepEntry, arr.items.len);
    var i: usize = 0;
    for (arr.items) |item| {
        if (item != .string) {
            try diags.append(arena, .{ .code = .invalid_shape });
            return &.{};
        }
        out[i] = .{ .name = try arena.dupe(u8, item.string), .spec = null };
        i += 1;
    }
    return out[0..i];
}

fn parseObjectForm(arena: std.mem.Allocator, obj: std.json.ObjectMap, diags: *std.ArrayListUnmanaged(Diagnostic)) ![]const DepEntry {
    var out = try arena.alloc(DepEntry, obj.count());
    var i: usize = 0;
    var it = obj.iterator();
    while (it.next()) |kv| {
        const name = kv.key_ptr.*;
        const node = kv.value_ptr.*;
        if (node != .object) {
            try diags.append(arena, .{ .code = .invalid_shape, .name = try arena.dupe(u8, name) });
            return &.{};
        }

        var spec: DepSpec = .{};
        var have_branch = false;
        var have_rev = false;
        var have_tag = false;

        if (node.object.get("git")) |v| if (v == .string) {
            spec.git = try arena.dupe(u8, v.string);
        };
        if (node.object.get("path")) |v| if (v == .string) {
            spec.path = try arena.dupe(u8, v.string);
        };
        if (node.object.get("branch")) |v| if (v == .string) {
            spec.ref = .{ .branch = try arena.dupe(u8, v.string) };
            have_branch = true;
        };
        if (node.object.get("tag")) |v| if (v == .string) {
            spec.ref = .{ .tag = try arena.dupe(u8, v.string) };
            have_tag = true;
        };
        if (node.object.get("rev")) |v| if (v == .string) {
            spec.ref = .{ .rev = try arena.dupe(u8, v.string) };
            have_rev = true;
        };

        if (spec.git == null and spec.path == null) {
            try diags.append(arena, .{ .code = .missing_source, .name = try arena.dupe(u8, name) });
        }
        const ref_count = @as(u2, @intFromBool(have_branch)) +
            @as(u2, @intFromBool(have_rev)) +
            @as(u2, @intFromBool(have_tag));
        if (ref_count > 1) {
            try diags.append(arena, .{ .code = .ambiguous_ref, .name = try arena.dupe(u8, name) });
        }

        out[i] = .{ .name = try arena.dupe(u8, name), .spec = spec };
        i += 1;
    }
    return out[0..i];
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "parseFromManifest: legacy array → spec=null" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": ["a", "b"] }
    , &diags);
    try testing.expectEqual(@as(usize, 2), deps.len);
    try testing.expectEqualStrings("a", deps[0].name);
    try testing.expectEqual(@as(?DepSpec, null), deps[0].spec);
    try testing.expectEqual(@as(usize, 0), diags.items.len);
}

test "parseFromManifest: object form" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": {
        \\  "j": { "git": "https://e/j.git", "branch": "feat" }
        \\}}
    , &diags);
    try testing.expectEqual(@as(usize, 1), deps.len);
    const s = deps[0].spec.?;
    try testing.expectEqualStrings("https://e/j.git", s.git.?);
    try testing.expectEqualStrings("feat", s.ref.branch);
    try testing.expectEqual(@as(usize, 0), diags.items.len);
}

test "parseFromManifest: object missing git+path → missing_source diagnostic" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": { "x": { "branch": "feat" } } }
    , &diags);
    try testing.expectEqual(@as(usize, 1), deps.len);
    try testing.expectEqual(@as(usize, 1), diags.items.len);
    try testing.expectEqual(DiagnosticCode.missing_source, diags.items[0].code);
}

test "anySpec: array-form returns false, object-form true" {
    const a = [_]DepEntry{ .{ .name = "x" }, .{ .name = "y" } };
    try testing.expect(!anySpec(&a));
    const b = [_]DepEntry{.{ .name = "x", .spec = .{ .git = "g" } }};
    try testing.expect(anySpec(&b));
}

test "DepSpec.isGit/isPath" {
    const g: DepSpec = .{ .git = "https://e/x.git" };
    try testing.expect(g.isGit());
    try testing.expect(!g.isPath());
    const p: DepSpec = .{ .path = "../x" };
    try testing.expect(!p.isGit());
    try testing.expect(p.isPath());
}
