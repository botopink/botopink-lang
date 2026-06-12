/// Project configuration — loaded from `botopink.json` in the project root.
const std = @import("std");

// ── Types ─────────────────────────────────────────────────────────────────────

pub const Target = enum {
    commonJS,
    erlang,
    beam,
    wasm,

    pub fn fromString(s: []const u8) ?Target {
        if (std.mem.eql(u8, s, "commonJS")) return .commonJS;
        if (std.mem.eql(u8, s, "erlang")) return .erlang;
        if (std.mem.eql(u8, s, "beam")) return .beam;
        if (std.mem.eql(u8, s, "wasm")) return .wasm;
        return null;
    }

    pub fn toString(self: Target) []const u8 {
        return switch (self) {
            .commonJS => "commonJS",
            .erlang => "erlang",
            .beam => "beam",
            .wasm => "wasm",
        };
    }
};

/// Pinned ref carried by a `DepSpec` (`branch` / `rev` / `tag` are mutually
/// exclusive at the *resolved* layer — DEP-003 warns when more than one is
/// present in the source JSON and picks the strongest pin).
pub const DepRef = union(enum) {
    branch: []const u8,
    rev: []const u8,
    tag: []const u8,
    none,
};

/// Source coordinates for an object-form dependency. Carried directly by
/// `DepEntry.spec`. Mirrored by `modules/bpmp/src/dep/spec.zig` so bpmp can
/// consume the same shape without taking a compiler-cli build dependency.
pub const DepSpec = struct {
    git: ?[]const u8 = null,
    path: ?[]const u8 = null,
    ref: DepRef = .none,
};

/// Normalised representation of one entry in the project's `dependencies`
/// field. `spec == null` is the legacy bare-name form (resolver-only, no
/// install). `spec != null` carries the new object-form source coordinates.
pub const DepEntry = struct {
    name: []const u8,
    spec: ?DepSpec = null,
};

/// Parsed representation of `botopink.json`.
pub const ProjectConfig = struct {
    name: []const u8,
    version: []const u8 = "0.1.0",
    target: []const u8 = "commonJS",
    /// Module-tree root file, relative to `src/` (e.g. `"main.bp"` for a binary
    /// package, `"root.bp"` for a library). When null the resolver auto-detects:
    /// `main.bp` if present (binary), else `root.bp` (library). The resolver
    /// follows `mod` declarations from this file to build the package's modules.
    entry: ?[]const u8 = null,
    /// Normalised dependencies. The on-disk form may be either the legacy
    /// `["foo", "bar"]` array of bare names OR the new object form
    /// `{ "foo": { "git": ..., "branch": ... } }`. Both shapes are
    /// normalised here into `[]DepEntry` — `spec == null` for the legacy
    /// form, `spec != null` for the object form.
    dependencies: []const DepEntry = &.{},
    /// Diagnostic codes raised by the dependencies parser. `null` when the
    /// loader path is bypassed (e.g. a hand-rolled `ProjectConfig` in tests).
    /// Owned by the same arena as the rest of the config.
    dep_diagnostics: []const DepDiagnostic = &.{},

    pub fn parsedTarget(self: ProjectConfig) Target {
        return Target.fromString(self.target) orelse .commonJS;
    }

    /// Convenience: flatten `dependencies` to just the names — the shape the
    /// existing `libs.loadDependencies` resolver consumes. Caller owns the
    /// slice (free with `gpa.free`); element strings remain owned by the
    /// config arena.
    pub fn dependencyNames(self: ProjectConfig, gpa: std.mem.Allocator) ![]const []const u8 {
        var names = try gpa.alloc([]const u8, self.dependencies.len);
        for (self.dependencies, 0..) |d, i| names[i] = d.name;
        return names;
    }
};

/// One parser diagnostic surfaced while normalising `dependencies`.
pub const DepDiagnostic = struct {
    code: DepDiagCode,
    /// Dep name the diagnostic is about. Empty (`""`) for shape-level codes
    /// (DEP-001) where no individual entry is at fault.
    name: []const u8 = "",
};

pub const DepDiagCode = enum {
    /// Whole `dependencies` field is neither array-of-strings nor object-of-DepSpec.
    DEP_001_invalid_shape,
    /// A `DepSpec` declared neither `git` nor `path`.
    DEP_002_missing_source,
    /// A `DepSpec` declared more than one of `branch`/`rev`/`tag` — the parser
    /// keeps the strongest pin (`rev` > `tag` > `branch`) and surfaces this
    /// warning.
    DEP_003_ambiguous_ref,
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

    return parse(arena, data);
}

/// Parse a botopink.json blob from memory. Splits out the on-disk read so
/// tests can drive synthetic JSON without touching the filesystem.
pub fn parse(arena: std.mem.Allocator, data: []const u8) LoadError!ProjectConfig {
    var parsed = std.json.parseFromSlice(
        std.json.Value,
        arena,
        data,
        .{},
    ) catch return error.ConfigInvalid;
    defer parsed.deinit();

    const root = parsed.value;
    if (root != .object) return error.ConfigInvalid;

    var cfg: ProjectConfig = .{ .name = "" };

    if (root.object.get("name")) |v| {
        if (v != .string) return error.ConfigInvalid;
        cfg.name = try arena.dupe(u8, v.string);
    } else return error.ConfigInvalid;

    if (root.object.get("version")) |v| {
        if (v != .string) return error.ConfigInvalid;
        cfg.version = try arena.dupe(u8, v.string);
    }

    if (root.object.get("target")) |v| {
        if (v != .string) return error.ConfigInvalid;
        cfg.target = try arena.dupe(u8, v.string);
    }

    if (root.object.get("entry")) |v| {
        switch (v) {
            .null => {},
            .string => |s| cfg.entry = try arena.dupe(u8, s),
            else => return error.ConfigInvalid,
        }
    }

    if (root.object.get("dependencies")) |v| {
        var diags: std.ArrayListUnmanaged(DepDiagnostic) = .empty;
        cfg.dependencies = try parseDependencies(arena, v, &diags);
        cfg.dep_diagnostics = try diags.toOwnedSlice(arena);
    }

    return cfg;
}

/// Normalise either the legacy array form or the new object form into
/// `[]DepEntry`. Pushes diagnostics into `diags` along the way (caller owns).
pub fn parseDependencies(
    arena: std.mem.Allocator,
    node: std.json.Value,
    diags: *std.ArrayListUnmanaged(DepDiagnostic),
) ![]const DepEntry {
    return switch (node) {
        .array => |arr| try parseArrayForm(arena, arr, diags),
        .object => |obj| try parseObjectForm(arena, obj, diags),
        else => blk: {
            try diags.append(arena, .{ .code = .DEP_001_invalid_shape });
            break :blk &.{};
        },
    };
}

fn parseArrayForm(
    arena: std.mem.Allocator,
    arr: std.json.Array,
    diags: *std.ArrayListUnmanaged(DepDiagnostic),
) ![]const DepEntry {
    var out = try arena.alloc(DepEntry, arr.items.len);
    var i: usize = 0;
    for (arr.items) |item| {
        if (item != .string) {
            try diags.append(arena, .{ .code = .DEP_001_invalid_shape });
            return &.{};
        }
        out[i] = .{ .name = try arena.dupe(u8, item.string), .spec = null };
        i += 1;
    }
    return out[0..i];
}

fn parseObjectForm(
    arena: std.mem.Allocator,
    obj: std.json.ObjectMap,
    diags: *std.ArrayListUnmanaged(DepDiagnostic),
) ![]const DepEntry {
    var out = try arena.alloc(DepEntry, obj.count());
    var i: usize = 0;
    var it = obj.iterator();
    while (it.next()) |kv| {
        const name = kv.key_ptr.*;
        const spec_node = kv.value_ptr.*;
        if (spec_node != .object) {
            try diags.append(arena, .{ .code = .DEP_001_invalid_shape, .name = try arena.dupe(u8, name) });
            return &.{};
        }
        var spec: DepSpec = .{};
        var have_branch = false;
        var have_rev = false;
        var have_tag = false;

        if (spec_node.object.get("git")) |v| switch (v) {
            .string => |s| spec.git = try arena.dupe(u8, s),
            .null => {},
            else => return &.{}, // malformed; surface as DEP-001 path collapses upstream
        };
        if (spec_node.object.get("path")) |v| switch (v) {
            .string => |s| spec.path = try arena.dupe(u8, s),
            .null => {},
            else => return &.{},
        };
        if (spec_node.object.get("branch")) |v| switch (v) {
            .string => |s| {
                spec.ref = .{ .branch = try arena.dupe(u8, s) };
                have_branch = true;
            },
            .null => {},
            else => return &.{},
        };
        if (spec_node.object.get("tag")) |v| switch (v) {
            .string => |s| {
                spec.ref = .{ .tag = try arena.dupe(u8, s) };
                have_tag = true;
            },
            .null => {},
            else => return &.{},
        };
        if (spec_node.object.get("rev")) |v| switch (v) {
            .string => |s| {
                spec.ref = .{ .rev = try arena.dupe(u8, s) };
                have_rev = true;
            },
            .null => {},
            else => return &.{},
        };

        // DEP-002 — must declare at least one of git/path.
        if (spec.git == null and spec.path == null) {
            try diags.append(arena, .{
                .code = .DEP_002_missing_source,
                .name = try arena.dupe(u8, name),
            });
        }
        // DEP-003 — pick strongest pin; rev > tag > branch.
        const ref_count = @as(u2, @intFromBool(have_branch)) +
            @as(u2, @intFromBool(have_rev)) +
            @as(u2, @intFromBool(have_tag));
        if (ref_count > 1) {
            try diags.append(arena, .{
                .code = .DEP_003_ambiguous_ref,
                .name = try arena.dupe(u8, name),
            });
        }

        out[i] = .{ .name = try arena.dupe(u8, name), .spec = spec };
        i += 1;
    }
    return out[0..i];
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

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "parse: legacy array dependencies → DepEntry with spec=null" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p", "dependencies": ["foo", "bar"] }
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 2), cfg.dependencies.len);
    try testing.expectEqualStrings("foo", cfg.dependencies[0].name);
    try testing.expectEqual(@as(?DepSpec, null), cfg.dependencies[0].spec);
    try testing.expectEqualStrings("bar", cfg.dependencies[1].name);
    try testing.expectEqual(@as(usize, 0), cfg.dep_diagnostics.len);
}

test "parse: object form with git+branch" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{
        \\  "name": "p",
        \\  "dependencies": {
        \\    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" }
        \\  }
        \\}
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 1), cfg.dependencies.len);
    try testing.expectEqualStrings("jhonstart", cfg.dependencies[0].name);
    const spec = cfg.dependencies[0].spec.?;
    try testing.expectEqualStrings("https://github.com/botopink/jhonstart.git", spec.git.?);
    try testing.expectEqualStrings("feat", spec.ref.branch);
    try testing.expectEqual(@as(usize, 0), cfg.dep_diagnostics.len);
}

test "parse: object form with path-only" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{
        \\  "name": "p",
        \\  "dependencies": {
        \\    "local": { "path": "../local-lib" }
        \\  }
        \\}
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 1), cfg.dependencies.len);
    const spec = cfg.dependencies[0].spec.?;
    try testing.expectEqual(@as(?[]const u8, null), spec.git);
    try testing.expectEqualStrings("../local-lib", spec.path.?);
    try testing.expect(spec.ref == .none);
    try testing.expectEqual(@as(usize, 0), cfg.dep_diagnostics.len);
}

test "parse: DEP-001 fires on non-object/non-array dependencies" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p", "dependencies": "nope" }
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 0), cfg.dependencies.len);
    try testing.expectEqual(@as(usize, 1), cfg.dep_diagnostics.len);
    try testing.expectEqual(DepDiagCode.DEP_001_invalid_shape, cfg.dep_diagnostics[0].code);
}

test "parse: DEP-002 fires on spec missing git AND path" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p", "dependencies": { "x": { "branch": "feat" } } }
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 1), cfg.dependencies.len);
    try testing.expectEqual(@as(usize, 1), cfg.dep_diagnostics.len);
    try testing.expectEqual(DepDiagCode.DEP_002_missing_source, cfg.dep_diagnostics[0].code);
    try testing.expectEqualStrings("x", cfg.dep_diagnostics[0].name);
}

test "parse: DEP-003 fires on branch+rev; rev wins" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p", "dependencies": {
        \\  "x": { "git": "https://e/x.git", "branch": "feat", "rev": "deadbeef" }
        \\}}
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 1), cfg.dependencies.len);
    const spec = cfg.dependencies[0].spec.?;
    // rev set last in the parse order → rev wins.
    try testing.expectEqualStrings("deadbeef", spec.ref.rev);
    try testing.expectEqual(@as(usize, 1), cfg.dep_diagnostics.len);
    try testing.expectEqual(DepDiagCode.DEP_003_ambiguous_ref, cfg.dep_diagnostics[0].code);
}

test "parse: missing dependencies field → empty slice, no diagnostics" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p" }
    ;
    const cfg = try parse(arena, json);
    try testing.expectEqual(@as(usize, 0), cfg.dependencies.len);
    try testing.expectEqual(@as(usize, 0), cfg.dep_diagnostics.len);
}

test "dependencyNames: flattens to bare names" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const json =
        \\{ "name": "p", "dependencies": ["a", "b"] }
    ;
    const cfg = try parse(arena, json);
    const names = try cfg.dependencyNames(testing.allocator);
    defer testing.allocator.free(names);
    try testing.expectEqual(@as(usize, 2), names.len);
    try testing.expectEqualStrings("a", names[0]);
    try testing.expectEqualStrings("b", names[1]);
}
