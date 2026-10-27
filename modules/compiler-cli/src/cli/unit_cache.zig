/// The unit cache (decision 1008 (2)): a dependency's units on one target —
/// each module's text, its `.d.ts`, its `.wasm`, its type units, what `build`
/// writes — kept so a later emit takes them instead of emitting the package
/// again, and writes them into its own output folder. One mechanism for every
/// target; it absorbs the code cache's level B CODE (144 B-60 S4), level B
/// keeping the analysis (`analysis_store.zig`).
///
/// **Where.** `<root>/.botopinkbuild/cache/unit/<target>/<package>.bpu`, and
/// std's one per module, `…/<target>/std/<module>.bpu` with the module's `/`
/// written `@` (`std/io/fs` → `std/io@fs.bpu`), as level B files them.
/// `<root>` is the cache root of decision 225 (the workspace root, else the
/// project's own; `--cache-root`'s directory), `<target>` is
/// `code_cache.EntryTarget.name` (`wasm` and `wasm.browser` are two). One
/// file per package and target: an entry under a new key replaces the
/// previous one, so the directory needs no size bound.
///
/// **The key** (`unitKey`): the package's `.bpr` key (decision 1006 (3),
/// Merkle over its dependencies'; std has none — its bytes are the
/// compiler's), the target and its host, the compiler by backend partition
/// (decision 249, `code_cache.compilerKey`) and its source stamp, and the
/// emit options a unit's bytes depend on (`bp.codegen.unitCache.Emit`: the
/// `.d.ts`, wasm's artifact). The file is `bp.analysis_entry`'s container
/// under that key — a META section naming the modules, one per line, then
/// one CODE section per module in that order — read whole or not at all
/// (`analysis_store.read`: any doubt, another key included, deletes it).
///
/// **What is never stored**: the package under test (`build`, `run`, `test`
/// always emit it), a package one of whose modules failed or was not emitted
/// (wasm's entry-only emit, decision 1008 (3)), a package holding a module
/// that answers for the whole program (it reads `@TypeInfo.all` or expands a
/// template querying the catalogue, `UnitCache.readers`).
///
/// **`--cold`** (`code_cache.cold`): nothing is read, and what was emitted is
/// written. A write is staged and renamed (`analysis_store.write`): two
/// writers of one key leave one whole entry.
const std = @import("std");
const builtin = @import("builtin");
const bp = @import("botopink");
const build_stamp = @import("build_stamp");
const config = @import("./config.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");
const libs = @import("./libs.zig");

const entry = bp.analysis_entry;
const UnitCache = bp.codegen.unitCache.UnitCache;
pub const Emit = bp.codegen.unitCache.Emit;
pub const Key = [code_cache.KEY_HEX]u8;

/// The store's name under `<root>/.botopinkbuild/cache/`.
pub const STORE = "unit";

/// The file extension of an entry.
pub const EXT = ".bpu";

/// `<root>/.botopinkbuild/cache/unit/<target>`.
pub fn targetDir(arena: std.mem.Allocator, cache_root: []const u8, target: code_cache.EntryTarget) ![]const u8 {
    return std.fs.path.join(arena, &.{ cache_root, ".botopinkbuild", "cache", STORE, target.name() });
}

/// The entry of `group` — a package's import name, or `std/<module>` — in
/// the target's directory `dir`.
pub fn groupPath(arena: std.mem.Allocator, dir: []const u8, group: []const u8) ![]const u8 {
    if (std.mem.startsWith(u8, group, "std/")) {
        const flat = try arena.dupe(u8, group["std/".len..]);
        std.mem.replaceScalar(u8, flat, '/', '@');
        return std.fs.path.join(arena, &.{ dir, "std", try std.mem.concat(arena, u8, &.{ flat, EXT }) });
    }
    return std.fs.path.join(arena, &.{ dir, try std.mem.concat(arena, u8, &.{ group, EXT }) });
}

/// The key of `group`'s units (see the file's head): `runtime` its `.bpr`
/// key, null for a std module.
pub fn unitKey(group: []const u8, runtime: ?Key, target: code_cache.EntryTarget, how: Emit) Key {
    return unitKeyWith(group, runtime, target, how, code_cache.compilerKey(target.target));
}

/// `unitKey` with the compiler's part given — what a test varies.
pub fn unitKeyWith(group: []const u8, runtime: ?Key, target: code_cache.EntryTarget, how: Emit, compiler: []const u8) Key {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    const parts = [_][]const u8{
        "botopink-unit-1",
        group,
        if (runtime) |*r| r else "-",
        target.name(),
        compiler,
        build_stamp.source_hash,
        if (how.typedef) "d.ts" else "-",
        if (how.wasm_artifact) "artifact" else "-",
        builtin.zig_version_string,
        @tagName(builtin.mode),
        @tagName(builtin.cpu.arch),
        @tagName(builtin.os.tag),
    };
    for (parts) |p| {
        h.update(p);
        h.update("\x00");
    }
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// One command's unit cache on one target: the entries it read, by group,
/// and the interface its emit asks (`iface`, `codegen.Config.unit_cache`).
pub const Cache = struct {
    /// What a unit is encoded with, freed once written.
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    io: std.Io,
    /// `targetDir` of the build.
    dir: []const u8,
    target: code_cache.EntryTarget,
    packages: bp.codegen.crossModule.Packages,
    /// Each dependency package's `.bpr` key, by import name
    /// (`libs.ClosureKeys.runtime`).
    runtime: *const std.StringHashMapUnmanaged(Key),
    how: Emit,
    /// Groups looked up: the entry read, or null (none, or in doubt).
    loaded: std.StringHashMapUnmanaged(?Loaded) = .empty,
    iface: UnitCache,
    /// Entries written by `record` — what a test reads.
    written: usize = 0,

    const Loaded = struct {
        modules: []const []const u8,
        units: std.StringHashMapUnmanaged([]const u8),
    };

    const vtable: UnitCache.VTable = .{ .get = getFn, .record = recordFn };

    /// A cache for a build on `target` filing under `cache_root`. Lives in
    /// `arena`, as everything it reads.
    pub fn init(
        self: *Cache,
        gpa: std.mem.Allocator,
        arena: std.mem.Allocator,
        io: std.Io,
        cache_root: []const u8,
        target: code_cache.EntryTarget,
        packages: bp.codegen.crossModule.Packages,
        runtime: *const std.StringHashMapUnmanaged(Key),
        how: Emit,
    ) !void {
        self.* = .{
            .gpa = gpa,
            .arena = arena,
            .io = io,
            .dir = try targetDir(arena, cache_root, target),
            .target = target,
            .packages = packages,
            .runtime = runtime,
            .how = how,
            .iface = .{ .ctx = self, .vtable = &vtable },
        };
    }

    /// The group of the emitted module `name`: its dependency package, std's
    /// module itself, or null for the package's own.
    fn groupOf(self: *const Cache, name: []const u8) ?[]const u8 {
        const pkg = libs.sidecarPackage(self.packages, name) orelse return null;
        if (std.mem.eql(u8, pkg, bp.codegen.crossModule.EMBEDDED_PACKAGE)) return name;
        return pkg;
    }

    fn keyOf(self: *const Cache, group: []const u8) ?Key {
        if (std.mem.startsWith(u8, group, "std/")) return unitKey(group, null, self.target, self.how);
        const rt = self.runtime.get(group) orelse return null;
        return unitKey(group, rt, self.target, self.how);
    }

    fn getFn(ctx: *anyopaque, name: []const u8) ?[]const u8 {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        if (code_cache.cold) return null;
        const g = self.groupOf(name) orelse return null;
        const loaded = self.load(g) orelse return null;
        return loaded.units.get(name);
    }

    /// `group`'s entry, read once per command.
    fn load(self: *Cache, group: []const u8) ?*const Loaded {
        if (self.loaded.getPtr(group)) |known| return if (known.*) |*l| l else null;
        const found = self.readEntry(group) catch null;
        const g = self.arena.dupe(u8, group) catch return null;
        self.loaded.put(self.arena, g, found) catch return null;
        return if (self.loaded.getPtr(g).?.*) |*l| l else null;
    }

    fn readEntry(self: *Cache, group: []const u8) !?Loaded {
        const key = self.keyOf(group) orelse return null;
        const path = try groupPath(self.arena, self.dir, group);
        const e = (try analysis_store.read(self.arena, self.io, path, key)) orelse return null;
        const names_text = e.get(.meta) orelse return null;
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, names_text, '\n');
        while (it.next()) |n| if (n.len > 0) try names.append(self.arena, n);
        const codes = try e.all(self.arena, .code);
        if (codes.len != names.items.len) return null;
        var units: std.StringHashMapUnmanaged([]const u8) = .empty;
        for (names.items, codes) |n, c| try units.put(self.arena, n, c);
        return .{ .modules = names.items, .units = units };
    }

    /// The emit returned `outputs`: each dependency package whose modules
    /// all emitted, none answering for the whole program, and whose entry
    /// did not already hold exactly them, is written — its units in the
    /// order they came. A write that fails leaves the previous entry (or
    /// none): the next command emits the package again.
    /// `codegen.generateWith` calls it through `iface`; a caller of
    /// `codegen.emit` calls `iface.record` once its emit returned.
    fn recordFn(ctx: *anyopaque, outputs: []const bp.codegen.ModuleOutput) void {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        self.recordGroups(self.gpa, outputs) catch {};
    }

    fn recordGroups(self: *Cache, gpa: std.mem.Allocator, outputs: []const bp.codegen.ModuleOutput) !void {
        var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(*const bp.codegen.ModuleOutput)) = .empty;
        var spoiled: std.StringHashMapUnmanaged(void) = .empty;
        for (outputs) |*o| {
            const g = self.groupOf(o.name) orelse continue;
            const slot = try groups.getOrPut(self.arena, g);
            if (!slot.found_existing) slot.value_ptr.* = .empty;
            try slot.value_ptr.append(self.arena, o);
            if (o.result.failed() or self.iface.isReader(o.name)) try spoiled.put(self.arena, g, {});
        }
        for (groups.keys(), groups.values()) |g, mods| {
            if (spoiled.contains(g)) continue;
            const key = self.keyOf(g) orelse continue;
            if (!code_cache.cold) if (self.load(g)) |l| if (sameModules(l.modules, mods.items)) continue;
            try self.write(gpa, g, key, mods.items);
        }
    }

    fn write(self: *Cache, gpa: std.mem.Allocator, group: []const u8, key: Key, mods: []const *const bp.codegen.ModuleOutput) !void {
        var names: std.ArrayListUnmanaged(u8) = .empty;
        var sections: std.ArrayListUnmanaged(entry.Section) = .empty;
        try sections.append(self.arena, .{ .id = .meta, .bytes = "" });
        for (mods) |m| {
            try names.appendSlice(self.arena, m.name);
            try names.append(self.arena, '\n');
            const bytes = try bp.codegen.unitCache.encode(gpa, m.result, self.how);
            defer gpa.free(bytes);
            try sections.append(self.arena, .{ .id = .code, .bytes = try self.arena.dupe(u8, bytes) });
        }
        sections.items[0].bytes = names.items;
        const packed_bytes = try entry.pack(gpa, entry.keyFromHex(key), sections.items);
        defer gpa.free(packed_bytes);
        try analysis_store.write(self.arena, self.io, try groupPath(self.arena, self.dir, group), packed_bytes);
        self.written += 1;
    }
};

fn sameModules(names: []const []const u8, mods: []const *const bp.codegen.ModuleOutput) bool {
    if (names.len != mods.len) return false;
    for (names, mods) |n, m| if (!std.mem.eql(u8, n, m.name)) return false;
    return true;
}

/// The modules of a program read back from its `.bpr` (`placed`) that answer
/// for the whole program: a dependency's module the root's file holds
/// (decision 805 (1) — a reader's analysis is the program's).
pub fn readersOf(arena: std.mem.Allocator, packages: bp.codegen.crossModule.Packages, placed: []const bp.runtime_file.Placed) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (placed) |p| {
        if (!std.mem.eql(u8, p.group, packages.root)) continue;
        if (libs.sidecarPackage(packages, p.module) != null) try out.append(arena, p.module);
    }
    return out.items;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;
const test_scratch = @import("test_scratch");

test "paths: one file per package and target under the cache root; std one per module, `/` as `@`" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const erl = try targetDir(a, "/ws", .{ .target = .erlang });
    try testing.expectEqualStrings("/ws/.botopinkbuild/cache/unit/erlang", erl);
    try testing.expectEqualStrings("/ws/.botopinkbuild/cache/unit/wasm.browser", try targetDir(a, "/ws", .{ .target = .wasm, .host = .browser }));
    try testing.expectEqualStrings("/ws/.botopinkbuild/cache/unit/erlang/lib.bpu", try groupPath(a, erl, "lib"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/cache/unit/erlang/std/io@fs.bpu", try groupPath(a, erl, "std/io/fs"));
}

test "unitKey: moves with the .bpr key, the target, the host, the compiler and each emit option" {
    const how: Emit = .{ .wasm_artifact = true, .typedef = false };
    const rt: Key = @splat('a');
    const k = unitKeyWith("lib", rt, .{ .target = .erlang }, how, "c");
    try testing.expectEqualStrings(&k, &unitKeyWith("lib", rt, .{ .target = .erlang }, how, "c"));
    const others = [_]Key{
        unitKeyWith("lib", @splat('b'), .{ .target = .erlang }, how, "c"),
        unitKeyWith("lib", null, .{ .target = .erlang }, how, "c"),
        unitKeyWith("lib", rt, .{ .target = .beam }, how, "c"),
        unitKeyWith("lib", rt, .{ .target = .erlang }, how, "d"),
        unitKeyWith("lib", rt, .{ .target = .erlang }, .{ .wasm_artifact = true, .typedef = true }, "c"),
        unitKeyWith("lib", rt, .{ .target = .erlang }, .{ .wasm_artifact = false, .typedef = false }, "c"),
        unitKeyWith("other", rt, .{ .target = .erlang }, how, "c"),
    };
    for (others) |o| try testing.expect(!std.mem.eql(u8, &k, &o));
    try testing.expect(!std.mem.eql(u8, &unitKeyWith("lib", rt, .{ .target = .wasm }, how, "c"), &unitKeyWith("lib", rt, .{ .target = .wasm, .host = .browser }, how, "c")));
}

test "Cache: a package's units written whole, read back by the next command; a failed module, a reader or the package's own are never stored" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "unit-cache");
    defer test_scratch.remove(io, "unit-cache");
    const root = test_scratch.path(io, "unit-cache");
    const packages: bp.codegen.crossModule.Packages = .{ .root = "app", .deps = &.{ "lib", "bad" } };
    var runtime: std.StringHashMapUnmanaged(Key) = .empty;
    try runtime.put(a, "lib", @splat('1'));
    try runtime.put(a, "bad", @splat('2'));
    const how: Emit = .{ .wasm_artifact = true, .typedef = false };

    const ok = struct {
        fn out(name: []const u8, js: []const u8) bp.codegen.ModuleOutput {
            return .{ .name = name, .src = "", .result = .{ .js = @constCast(js), .comptime_script = null } };
        }
    };
    var failed = ok.out("bad/b", "");
    failed.result.diagnostic = .{ .type = .{ .message = @constCast("no"), .loc = null } };
    const outputs = [_]bp.codegen.ModuleOutput{ ok.out("main", "app"), ok.out("lib/a", "A"), ok.out("lib/b", "B"), failed, ok.out("std/io", "IO") };

    var first: Cache = undefined;
    try first.init(testing.allocator, a, io, root, .{ .target = .erlang }, packages, &runtime, how);
    first.iface.record(&outputs);
    // lib and std/io; never `app`, never `bad`.
    try testing.expectEqual(@as(usize, 2), first.written);
    const dir = try targetDir(a, root, .{ .target = .erlang });
    const cwd = std.Io.Dir.cwd();
    try cwd.access(io, try groupPath(a, dir, "lib"), .{});
    try cwd.access(io, try groupPath(a, dir, "std/io"), .{});
    try testing.expectError(error.FileNotFound, cwd.access(io, try groupPath(a, dir, "bad"), .{}));

    var second: Cache = undefined;
    try second.init(testing.allocator, a, io, root, .{ .target = .erlang }, packages, &runtime, how);
    var unit = (try second.iface.take(testing.allocator, "lib/b", how)).?;
    defer unit.deinit(testing.allocator);
    try testing.expectEqualStrings("B", unit.js);
    try testing.expect(try second.iface.take(testing.allocator, "main", how) == null);
    // Read back whole: nothing written again.
    second.iface.record(&outputs);
    try testing.expectEqual(@as(usize, 0), second.written);

    // A reader's package is never taken nor stored.
    var third: Cache = undefined;
    try runtime.put(a, "lib", @splat('3'));
    try third.init(testing.allocator, a, io, root, .{ .target = .erlang }, packages, &runtime, how);
    third.iface.readers = &.{"lib/a"};
    try testing.expect(try third.iface.take(testing.allocator, "lib/b", how) == null);
    third.iface.record(&outputs);
    try testing.expectEqual(@as(usize, 0), third.written);

    // Another `.bpr` key: the old entry is in doubt, deleted, and written anew.
    var fourth: Cache = undefined;
    try fourth.init(testing.allocator, a, io, root, .{ .target = .erlang }, packages, &runtime, how);
    try testing.expect(try fourth.iface.take(testing.allocator, "lib/a", how) == null);
    fourth.iface.record(&outputs);
    try testing.expectEqual(@as(usize, 1), fourth.written);
}
