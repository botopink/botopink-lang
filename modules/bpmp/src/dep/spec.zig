/// `DepSpec` / `DepEntry` for bpmp — the shared manifest model's own types.
///
/// bpmp keeps a thin build graph (no compiler-core dependency), so it used to
/// carry a byte-equal copy of `compiler-cli/src/cli/config.zig`'s shapes and a
/// second parser over the same JSON. The `manifest` module (`modules/manifest`,
/// `std` only) is now the one reading every tool shares: the object form of
/// decision 76 — `{ "<name>": { "path" } | { "git", "branch"|"tag"|"rev" } |
/// { "workspace": true } }` — and nothing else. The string-array form is a
/// located refusal here exactly as it is in the compiler.
const std = @import("std");
const manifest = @import("manifest");

pub const DepRef = manifest.DepRef;
pub const DepSpec = manifest.DepSpec;
pub const DepEntry = manifest.DepEntry;
pub const Located = manifest.Located;

/// True when the project declares any dependency. Every entry of the object
/// form carries a source, so this is what decides whether `bpmp install` has
/// dependencies to materialise.
pub fn anySpec(deps: []const DepEntry) bool {
    return deps.len > 0;
}

/// A refused `botopink.json`: the located error the shared model produced,
/// rendered by the caller (`Located.print`).
pub const Diagnostic = struct {
    located: Located,
};

/// Parse `dependencies` off a `botopink.json` blob through the shared model.
/// A refused manifest appends one located `Diagnostic` and returns an empty
/// slice — the caller prints it and stops.
pub fn parseFromManifest(
    arena: std.mem.Allocator,
    json_bytes: []const u8,
    diags: *std.ArrayListUnmanaged(Diagnostic),
) ![]const DepEntry {
    var err: ?Located = null;
    const m = manifest.parse(arena, json_bytes, manifest.FILENAME, &err) catch |e| switch (e) {
        error.Invalid => {
            try diags.append(arena, .{ .located = err.? });
            return &.{};
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    return m.dependencies;
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "parseFromManifest: the string-array form is a located refusal, not a legacy shape" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": ["a", "b"] }
    , &diags);
    try testing.expectEqual(@as(usize, 0), deps.len);
    try testing.expectEqual(@as(usize, 1), diags.items.len);
    try testing.expect(std.mem.startsWith(u8, diags.items[0].located.message, "\"dependencies\" must be an object, not an array"));
    try testing.expectEqualStrings("botopink.json", diags.items[0].located.file);
}

test "parseFromManifest: object form — git with a pin, path, workspace" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": {
        \\  "j": { "git": "https://e/j.git", "branch": "feat" },
        \\  "l": { "path": "../l" },
        \\  "w": { "workspace": true }
        \\}}
    , &diags);
    try testing.expectEqual(@as(usize, 3), deps.len);
    try testing.expectEqualStrings("https://e/j.git", deps[0].spec.git.?);
    try testing.expectEqualStrings("feat", deps[0].spec.ref.branch);
    try testing.expect(deps[1].spec.isPath());
    try testing.expect(deps[2].spec.workspace);
    try testing.expectEqual(@as(usize, 0), diags.items.len);
    try testing.expect(anySpec(deps));
    try testing.expect(!anySpec(&.{}));
}

test "parseFromManifest: an entry with no source is a located refusal" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var diags: std.ArrayListUnmanaged(Diagnostic) = .empty;
    const deps = try parseFromManifest(arena,
        \\{ "name": "p", "dependencies": { "x": { "branch": "feat" } } }
    , &diags);
    try testing.expectEqual(@as(usize, 0), deps.len);
    try testing.expectEqual(@as(usize, 1), diags.items.len);
    try testing.expectEqualStrings("dependency \"x\" declares no source — one of \"git\", \"path\" or \"workspace\": true is required", diags.items[0].located.message);
}

test "DepSpec.isGit/isPath" {
    const g: DepSpec = .{ .git = "https://e/x.git" };
    try testing.expect(g.isGit());
    try testing.expect(!g.isPath());
    const p: DepSpec = .{ .path = "../x" };
    try testing.expect(!p.isGit());
    try testing.expect(p.isPath());
}
