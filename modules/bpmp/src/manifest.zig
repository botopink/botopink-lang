/// `botopink.json` reader/writer for bpmp.
///
/// The compiler already parses `botopink.json` (see `compiler-cli/src/cli/`).
/// bpmp parses the same file but writes it too, so the read side is structured
/// around **preserving anything we don't recognise** — adding the manifest's
/// compiler-side bits to the bpmp side and back must round-trip every existing
/// key, including unknown extensions. We use `std.json.Value` (a generic tree)
/// for that, then layer typed views over it.
///
/// The compiler-facing fields are passed through verbatim; bpmp owns:
///   - `botopink`  — minimum compiler-version constraint (SemVer string)
///   - `requires`  — per-dep version constraint map (`{name: constraint}`)
///
/// On `bpmp install <name>@<spec>`, bpmp appends to `dependencies` (so the
/// compiler's loader picks the lib up) AND records the constraint in
/// `requires` (so a teammate's `bpmp install` resolves the same way).
const std = @import("std");

pub const Error = anyerror;

/// Default filename. Lives next to `botopink.lock.json`.
pub const FILENAME = "botopink.json";

/// A typed view over the manifest. The fields are projected from `tree`; on
/// write we mutate `tree` and serialise it, so every unknown sibling key the
/// project carried is preserved.
///
/// The arena lives on the heap (via the parent gpa) so the captured-allocator
/// pointers std.json's Array.init bakes into the tree survive any move of
/// the Manifest value. `deinit` tears the arena down and frees the heap slot.
pub const Manifest = struct {
    gpa: std.mem.Allocator,
    arena: *std.heap.ArenaAllocator,
    tree: std.json.Value,

    pub fn deinit(self: *Manifest) void {
        self.arena.deinit();
        self.gpa.destroy(self.arena);
    }

    fn obj(self: *Manifest) !*std.json.ObjectMap {
        if (self.tree != .object) return error.NotAnObject;
        return &self.tree.object;
    }

    fn arenaAllocator(self: *Manifest) std.mem.Allocator {
        return self.arena.allocator();
    }

    pub fn name(self: *Manifest) ?[]const u8 {
        const o = self.obj() catch return null;
        const v = o.get("name") orelse return null;
        return if (v == .string) v.string else null;
    }

    pub fn version(self: *Manifest) ?[]const u8 {
        const o = self.obj() catch return null;
        const v = o.get("version") orelse return null;
        return if (v == .string) v.string else null;
    }

    /// The compiler-version constraint — bpmp's read of `botopink.json.botopink`.
    pub fn botopinkConstraint(self: *Manifest) ?[]const u8 {
        const o = self.obj() catch return null;
        const v = o.get("botopink") orelse return null;
        return if (v == .string) v.string else null;
    }

    /// Iterate `files` (the lib publish surface) as a slice of paths.
    /// Returns an empty slice if the field is absent — `pack` then refuses
    /// to write an empty archive.
    pub fn files(self: *Manifest, gpa: std.mem.Allocator) ![]const []const u8 {
        const o = try self.obj();
        const v = o.get("files") orelse return &.{};
        if (v != .array) return error.ManifestInvalid;
        var out = try gpa.alloc([]const u8, v.array.items.len);
        for (v.array.items, 0..) |entry, i| {
            if (entry != .string) return error.ManifestInvalid;
            out[i] = entry.string;
        }
        return out;
    }

    /// Iterate `dependencies` as a `[]const string`. Arena-allocated.
    pub fn dependencies(self: *Manifest, gpa: std.mem.Allocator) ![]const []const u8 {
        const o = try self.obj();
        const v = o.get("dependencies") orelse return &.{};
        if (v != .array) return error.ManifestInvalid;
        var out = try gpa.alloc([]const u8, v.array.items.len);
        for (v.array.items, 0..) |entry, i| {
            if (entry != .string) return error.ManifestInvalid;
            out[i] = entry.string;
        }
        return out;
    }

    /// Look up the version constraint for `dep_name` under `requires`. Returns
    /// `null` when `requires` is absent or the key is missing.
    pub fn requirement(self: *Manifest, dep_name: []const u8) ?[]const u8 {
        const o = self.obj() catch return null;
        const v = o.get("requires") orelse return null;
        if (v != .object) return null;
        const c = v.object.get(dep_name) orelse return null;
        return if (c == .string) c.string else null;
    }

    /// Append `dep_name` to `dependencies` (when not already present) and set
    /// `requires.<dep_name>` to `constraint` (overwriting any existing). Both
    /// updates happen in lockstep — see Notes in the spec for why.
    pub fn addDependency(
        self: *Manifest,
        gpa: std.mem.Allocator,
        dep_name: []const u8,
        constraint: []const u8,
    ) !void {
        const a = self.arenaAllocator();
        const o = try self.obj();

        // 1. dependencies (string[]): ensure entry present.
        if (o.getPtr("dependencies") == null) {
            try o.put(a, try a.dupe(u8, "dependencies"), .{ .array = std.json.Array.init(a) });
        }
        const deps_val = o.getPtr("dependencies").?;
        if (deps_val.* != .array) return error.ManifestInvalid;
        var found = false;
        for (deps_val.array.items) |e| {
            if (e == .string and std.mem.eql(u8, e.string, dep_name)) {
                found = true;
                break;
            }
        }
        if (!found) try deps_val.array.append(.{ .string = try a.dupe(u8, dep_name) });

        // 2. requires (object): set/overwrite the constraint.
        if (o.getPtr("requires") == null) {
            try o.put(a, try a.dupe(u8, "requires"), .{ .object = std.json.ObjectMap.empty });
        }
        const req_val = o.getPtr("requires").?;
        if (req_val.* != .object) return error.ManifestInvalid;
        try req_val.object.put(
            a,
            try a.dupe(u8, dep_name),
            .{ .string = try a.dupe(u8, constraint) },
        );
        _ = gpa;
    }

    /// Remove `dep_name` from both `dependencies` and `requires`. No-op when
    /// either is absent (so `bpmp uninstall` is idempotent).
    pub fn removeDependency(self: *Manifest, dep_name: []const u8) !void {
        const a = self.arenaAllocator();
        const o = try self.obj();
        if (o.getPtr("dependencies")) |p| {
            if (p.* != .array) return error.ManifestInvalid;
            var keep: std.json.Array = std.json.Array.init(a);
            for (p.array.items) |e| {
                if (e == .string and std.mem.eql(u8, e.string, dep_name)) continue;
                try keep.append(e);
            }
            // The old array's backing slice is arena-owned (parseFromSliceLeaky
            // allocated it there); leaving it for the arena to reclaim is
            // cheaper than calling deinit, which would walk back through the
            // arena's free path and hit non-top blocks.
            p.* = .{ .array = keep };
        }
        if (o.getPtr("requires")) |p| {
            if (p.* != .object) return error.ManifestInvalid;
            _ = p.object.fetchSwapRemove(dep_name);
        }
    }

    /// Serialise the (possibly mutated) tree to a JSON string, owned by `gpa`.
    /// The output is pretty-printed (2-space indent) so a hand-edited
    /// `botopink.json` stays diff-friendly.
    pub fn writeAlloc(self: *Manifest, gpa: std.mem.Allocator) ![]u8 {
        var aw: std.Io.Writer.Allocating = .init(gpa);
        defer aw.deinit();
        try std.json.Stringify.value(self.tree, .{ .whitespace = .indent_2 }, &aw.writer);
        try aw.writer.writeByte('\n');
        return aw.toOwnedSlice();
    }
};

/// Parse `data` as a `botopink.json` tree. The returned `Manifest` owns its
/// arena; the caller must `deinit` it.
pub fn parse(gpa: std.mem.Allocator, data: []const u8) Error!Manifest {
    const arena = try gpa.create(std.heap.ArenaAllocator);
    errdefer gpa.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const parsed = try std.json.parseFromSliceLeaky(
        std.json.Value,
        arena.allocator(),
        data,
        .{},
    );
    return .{ .gpa = gpa, .arena = arena, .tree = parsed };
}

/// Read `<dir>/<FILENAME>` and `parse` it.
pub fn read(gpa: std.mem.Allocator, io: std.Io, dir: []const u8) Error!Manifest {
    const path = try std.fs.path.join(gpa, &.{ dir, FILENAME });
    defer gpa.free(path);
    const data = std.Io.Dir.cwd().readFileAlloc(io, path, gpa, .limited(1024 * 1024)) catch
        return error.ManifestNotFound;
    defer gpa.free(data);
    return parse(gpa, data);
}

/// Write `manifest` to `<dir>/<FILENAME>` (overwrites in place).
pub fn write(gpa: std.mem.Allocator, io: std.Io, dir: []const u8, manifest: *Manifest) Error!void {
    const path = try std.fs.path.join(gpa, &.{ dir, FILENAME });
    defer gpa.free(path);
    const text = try manifest.writeAlloc(gpa);
    defer gpa.free(text);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = text });
}

/// Build a fresh manifest from scratch (used by `bpmp init`).
pub fn create(
    gpa: std.mem.Allocator,
    name: []const u8,
    version: []const u8,
    target: []const u8,
    entry: []const u8,
) !Manifest {
    const arena = try gpa.create(std.heap.ArenaAllocator);
    errdefer gpa.destroy(arena);
    arena.* = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();

    var obj: std.json.ObjectMap = .empty;
    try obj.put(a, "name", .{ .string = try a.dupe(u8, name) });
    try obj.put(a, "version", .{ .string = try a.dupe(u8, version) });
    try obj.put(a, "target", .{ .string = try a.dupe(u8, target) });
    try obj.put(a, "entry", .{ .string = try a.dupe(u8, entry) });
    try obj.put(a, "src", .{ .string = try a.dupe(u8, "src/") });
    try obj.put(a, "dependencies", .{ .array = std.json.Array.init(a) });
    try obj.put(a, "requires", .{ .object = std.json.ObjectMap.empty });
    return .{ .gpa = gpa, .arena = arena, .tree = .{ .object = obj } };
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "parse: minimal manifest yields typed views" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "dependencies": ["erika"] }
    );
    defer m.deinit();
    try testing.expectEqualStrings("x", m.name().?);
    try testing.expectEqualStrings("0.1.0", m.version().?);
    const deps = try m.dependencies(testing.allocator);
    defer testing.allocator.free(deps);
    try testing.expectEqual(@as(usize, 1), deps.len);
    try testing.expectEqualStrings("erika", deps[0]);
}

test "parse: unknown sibling keys preserved on round-trip" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "files": ["a.bp"], "future_field": 42 }
    );
    defer m.deinit();
    const out = try m.writeAlloc(testing.allocator);
    defer testing.allocator.free(out);
    try testing.expect(std.mem.indexOf(u8, out, "\"files\"") != null);
    try testing.expect(std.mem.indexOf(u8, out, "\"future_field\"") != null);
    try testing.expect(std.mem.indexOf(u8, out, "42") != null);
}

test "botopinkConstraint reads the bpmp-facing compiler version field" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "botopink": ">=0.0.1" }
    );
    defer m.deinit();
    try testing.expectEqualStrings(">=0.0.1", m.botopinkConstraint().?);
}

test "requirement: reads requires.<name>" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "requires": { "erika": "^0.0.1" } }
    );
    defer m.deinit();
    try testing.expectEqualStrings("^0.0.1", m.requirement("erika").?);
    try testing.expect(m.requirement("absent") == null);
}

test "addDependency adds to both dependencies AND requires" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "dependencies": [] }
    );
    defer m.deinit();
    try m.addDependency(testing.allocator, "erika", "^0.0.1");

    const deps = try m.dependencies(testing.allocator);
    defer testing.allocator.free(deps);
    try testing.expectEqual(@as(usize, 1), deps.len);
    try testing.expectEqualStrings("erika", deps[0]);
    try testing.expectEqualStrings("^0.0.1", m.requirement("erika").?);
}

test "addDependency is idempotent on dependencies array" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "dependencies": ["erika"], "requires": { "erika": "^0.0.1" } }
    );
    defer m.deinit();
    try m.addDependency(testing.allocator, "erika", "^0.0.2"); // bumped constraint

    const deps = try m.dependencies(testing.allocator);
    defer testing.allocator.free(deps);
    try testing.expectEqual(@as(usize, 1), deps.len);
    try testing.expectEqualStrings("^0.0.2", m.requirement("erika").?);
}

test "removeDependency drops from both arrays" {
    var m = try parse(testing.allocator,
        \\{ "name": "x", "version": "0.1.0", "dependencies": ["erika","onze"], "requires": { "erika":"^0.0.1", "onze":"*" } }
    );
    defer m.deinit();
    try m.removeDependency("erika");
    const deps = try m.dependencies(testing.allocator);
    defer testing.allocator.free(deps);
    try testing.expectEqual(@as(usize, 1), deps.len);
    try testing.expectEqualStrings("onze", deps[0]);
    try testing.expect(m.requirement("erika") == null);
    try testing.expectEqualStrings("*", m.requirement("onze").?);
}

test "create builds a manifest with the expected default fields" {
    var m = try create(testing.allocator, "myapp", "0.0.1", "commonJS", "src/main.bp");
    defer m.deinit();
    try testing.expectEqualStrings("myapp", m.name().?);
    try testing.expectEqualStrings("0.0.1", m.version().?);
    const deps = try m.dependencies(testing.allocator);
    defer testing.allocator.free(deps);
    try testing.expectEqual(@as(usize, 0), deps.len);
}
