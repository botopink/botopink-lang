/// The code cache, level B (decision 509 (1), 144 B-60): where a dependency's
/// analysis entry lives on disk, and how it is read and written. The entry's
/// bytes are compiler-core's (`bp.analysis_entry`: the container, the
/// sections); its key is `code_cache.closureKey` (a package) or
/// `code_cache.stdKey` (one std module).
///
/// **Where.** `<root>/.botopinkbuild/analysis/<target>/<package>.bpa`, and
/// std's `<root>/.botopinkbuild/analysis/<target>/std/<module>.bpa` with the
/// module's `/` written `@` (`std/io/fs` → `std/io@fs.bpa`). `<root>` is the
/// cache root of decision 225 — the workspace root, else the project's own —
/// or, under `cell check`, the cell's (`code_cache.root_override`): a
/// workspace's members share one directory. `<target>` is
/// `code_cache.EntryTarget.name`: `wasm` and `wasm.browser` are two. One file
/// per package and target: an entry under a new key replaces the previous one,
/// so the directory needs no size bound.
///
/// **Reading** (`read`): the whole file, proven by `analysis_entry.unpack`
/// against the key the reader computed; any doubt deletes the file and
/// answers a miss — an entry is never used in part.
///
/// **Writing** (`write`): to `<name>.bpa.<pid>-<random>.tmp` beside it, then
/// renamed over it — no lock: a reader sees the old entry or the new one,
/// never half of one, and two writers of one key leave one whole entry.
///
/// **The compile's store** (`Cache`, S2): `build` (and through it `run` and
/// `cell check`), `test` and `check` hand one to the comptime pass
/// (`codegen.Config.analysis_store`, `comptime_pipeline.compileWith`): it
/// answers each group's key — a dependency's closure key
/// (`libs.ClosureKeys`), std's per module — reads entries, and keeps those the
/// compile staged until `commit`, which the command calls once its generate
/// (its comptime pass, for `check`) returned. `--cold` reads nothing and still
/// writes. The language server reads none.
const std = @import("std");
const builtin = @import("builtin");
const bp = @import("botopink");
const manifest = @import("manifest");
const config = @import("./config.zig");
const code_cache = @import("./code_cache.zig");

const entry = bp.analysis_entry;

/// The level's directory under a cache root.
pub const DIR = ".botopinkbuild/analysis";

/// The file extension of an entry.
pub const EXT = ".bpa";

/// The cache root `proj` files its entries under: `code_cache.root_override`
/// when set (a cell's), else `manifest.cacheRoot` over the workspace
/// `config.load` found.
pub fn root(proj: config.ProjectConfig) []const u8 {
    return code_cache.root_override orelse manifest.cacheRoot(proj.dir, proj.workspace);
}

/// `<root>/.botopinkbuild/analysis/<target>`.
pub fn targetDir(arena: std.mem.Allocator, cache_root: []const u8, target: code_cache.EntryTarget) ![]const u8 {
    return std.fs.path.join(arena, &.{ cache_root, DIR, target.name() });
}

/// The entry of the package `package` (its import name) on `target`.
pub fn packagePath(arena: std.mem.Allocator, cache_root: []const u8, target: code_cache.EntryTarget, package: []const u8) ![]const u8 {
    const file = try std.mem.concat(arena, u8, &.{ package, EXT });
    return std.fs.path.join(arena, &.{ cache_root, DIR, target.name(), file });
}

/// The extension of a package's INPUTS file beside its entry (decision 519):
/// the files its last analysis read through its reader, one path from the
/// package per line, sorted — what `code_cache.closureKeyReading` hashes
/// besides the package's own files, so a `compiler.load` file outside `src`
/// moves the package's key (and, Merkle, its dependants').
pub const INPUTS_EXT = ".inputs";

/// The INPUTS file of the package `package` on `target`.
pub fn inputsPath(arena: std.mem.Allocator, cache_root: []const u8, target: code_cache.EntryTarget, package: []const u8) ![]const u8 {
    const file = try std.mem.concat(arena, u8, &.{ package, INPUTS_EXT });
    return std.fs.path.join(arena, &.{ cache_root, DIR, target.name(), file });
}

/// The paths of `package`'s INPUTS file, none when it has none. A path that
/// is absolute or climbs out of the package is never hashed.
pub fn readInputs(arena: std.mem.Allocator, io: std.Io, cache_root: []const u8, target: code_cache.EntryTarget, package: []const u8) ![]const []const u8 {
    const path = try inputsPath(arena, cache_root, target, package);
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .unlimited) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return &.{},
    };
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = std.mem.splitScalar(u8, bytes, '\n');
    while (it.next()) |line| {
        if (line.len == 0 or std.fs.path.isAbsolute(line) or std.mem.indexOf(u8, line, "..") != null) continue;
        try out.append(arena, line);
    }
    return out.items;
}

/// The entry of std's module `module` (its path under std — `io/fs`, or
/// `std/io/fs` as a build names it) on `target`: `…/std/io@fs.bpa`.
pub fn stdPath(arena: std.mem.Allocator, cache_root: []const u8, target: code_cache.EntryTarget, module: []const u8) ![]const u8 {
    const rel = if (std.mem.startsWith(u8, module, "std/")) module["std/".len..] else module;
    const flat = try arena.dupe(u8, rel);
    std.mem.replaceScalar(u8, flat, '/', '@');
    const file = try std.mem.concat(arena, u8, &.{ flat, EXT });
    return std.fs.path.join(arena, &.{ cache_root, DIR, target.name(), "std", file });
}

/// The entry at `path`, proven against `key` — its bytes and sections owned
/// by `arena` — or null: no file, or a file in doubt, which is deleted.
pub fn read(arena: std.mem.Allocator, io: std.Io, path: []const u8, key: [code_cache.KEY_HEX]u8) !?entry.Entry {
    const cwd = std.Io.Dir.cwd();
    const bytes = cwd.readFileAlloc(io, path, arena, .unlimited) catch |err| switch (err) {
        error.FileNotFound => return null,
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            discard(io, path);
            return null;
        },
    };
    return entry.unpack(arena, bytes, entry.keyFromHex(key)) catch |err| switch (err) {
        error.Doubt => {
            discard(io, path);
            return null;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
}

/// Delete the entry at `path`; one already gone is gone.
fn discard(io: std.Io, path: []const u8) void {
    std.Io.Dir.cwd().deleteFile(io, path) catch {};
}

/// Write `bytes` as the entry at `path`, replacing any: staged under a name
/// no other writer uses, then renamed over it.
pub fn write(arena: std.mem.Allocator, io: std.Io, path: []const u8, bytes: []const u8) !void {
    const cwd = std.Io.Dir.cwd();
    if (std.fs.path.dirname(path)) |d| try cwd.createDirPath(io, d);
    var rand: [8]u8 = undefined;
    io.random(&rand);
    const tmp = try std.fmt.allocPrint(arena, "{s}.{d}-{x}.tmp", .{ path, pid(), std.mem.readInt(u64, &rand, .little) });
    errdefer cwd.deleteFile(io, tmp) catch {};
    try cwd.writeFile(io, .{ .sub_path = tmp, .data = bytes });
    try std.Io.Dir.rename(cwd, tmp, cwd, path, io);
}

/// One command's store: the keys of its build's closure on one target, the
/// entries it read and the ones its compile staged.
pub const Cache = struct {
    arena_inst: std.heap.ArenaAllocator,
    io: std.Io,
    /// The cache root (`root`).
    cache_root: []const u8,
    target: code_cache.EntryTarget,
    /// Each dependency package's closure key, by import name.
    keys: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8),
    /// Entries read, by group: one read per invocation, whatever the number
    /// of compile passes.
    read_entries: std.StringHashMapUnmanaged(?entry.Entry) = .empty,
    /// Entries staged, by group, written by `commit`.
    pending: std.StringArrayHashMapUnmanaged([]const u8) = .empty,
    /// Each dependency package's reader log (`libs.ClosureKeys.logs`), by
    /// import name: `commit` writes a staged package's INPUTS from it.
    logs: std.StringHashMapUnmanaged(*bp.ReadLog) = .empty,
    store: bp.level_b.Store,

    const vtable: bp.level_b.Store.VTable = .{
        .key = keyFn,
        .read = readFn,
        .discard = discardFn,
        .stage = stageFn,
    };

    /// A store over `keys` (copied) on `target`, filing under `cache_root`.
    pub fn init(self: *Cache, gpa: std.mem.Allocator, io: std.Io, cache_root: []const u8, target: code_cache.EntryTarget, keys: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8)) !void {
        self.* = .{
            .arena_inst = std.heap.ArenaAllocator.init(gpa),
            .io = io,
            .cache_root = cache_root,
            .target = target,
            .keys = .empty,
            .store = .{ .ctx = self, .vtable = &vtable, .target = target.name() },
        };
        const a = self.arena_inst.allocator();
        self.cache_root = try a.dupe(u8, cache_root);
        var it = keys.iterator();
        while (it.next()) |e| try self.keys.put(a, try a.dupe(u8, e.key_ptr.*), e.value_ptr.*);
    }

    pub fn deinit(self: *Cache) void {
        self.arena_inst.deinit();
    }

    /// Where `group`'s entry lives.
    fn pathOf(self: *Cache, group: []const u8) ![]const u8 {
        const a = self.arena_inst.allocator();
        if (std.mem.startsWith(u8, group, "std/")) return stdPath(a, self.cache_root, self.target, group);
        return packagePath(a, self.cache_root, self.target, group);
    }

    fn hexKey(self: *Cache, group: []const u8) ?[code_cache.KEY_HEX]u8 {
        if (std.mem.startsWith(u8, group, "std/")) return code_cache.stdKey(group["std/".len..], self.target);
        return self.keys.get(group);
    }

    fn keyFn(ctx: *anyopaque, group: []const u8) ?entry.Key {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        return entry.keyFromHex(self.hexKey(group) orelse return null);
    }

    fn readFn(ctx: *anyopaque, group: []const u8, key: entry.Key) ?entry.Entry {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        if (code_cache.cold) return null;
        if (self.read_entries.get(group)) |known| return known;
        const a = self.arena_inst.allocator();
        const found: ?entry.Entry = blk: {
            const path = self.pathOf(group) catch break :blk null;
            break :blk read(a, self.io, path, std.fmt.bytesToHex(key, .lower)) catch null;
        };
        const g = a.dupe(u8, group) catch return found;
        self.read_entries.put(a, g, found) catch {};
        return found;
    }

    fn discardFn(ctx: *anyopaque, group: []const u8) void {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        const path = self.pathOf(group) catch return;
        discard(self.io, path);
        if (self.read_entries.getPtr(group)) |slot| slot.* = null;
    }

    fn stageFn(ctx: *anyopaque, group: []const u8, bytes: []const u8) void {
        const self: *Cache = @ptrCast(@alignCast(ctx));
        const a = self.arena_inst.allocator();
        const copy = a.dupe(u8, bytes) catch return;
        const g = a.dupe(u8, group) catch return;
        self.pending.put(a, g, copy) catch {};
    }

    /// Write every staged entry, each renamed into place, and a package's
    /// INPUTS beside it — what its reader read, none removing the file. A
    /// package whose log lost a path writes neither. A write that fails
    /// leaves the previous entry (or none): the next invocation analyses
    /// that dependency again.
    ///
    /// The entry is filed under the key computed before the analysis read
    /// anything: a package whose INPUTS this commit changes gets another key
    /// at the next invocation and is analysed once more, then read back.
    pub fn commit(self: *Cache) void {
        const a = self.arena_inst.allocator();
        for (self.pending.keys(), self.pending.values()) |g, bytes| {
            const log = self.logs.get(g);
            if (log) |l| if (l.lost) continue;
            const path = self.pathOf(g) catch continue;
            write(a, self.io, path, bytes) catch {};
            if (log) |l| self.writeInputs(g, l) catch {};
        }
        self.pending.clearRetainingCapacity();
    }

    fn writeInputs(self: *Cache, g: []const u8, log: *const bp.ReadLog) !void {
        const a = self.arena_inst.allocator();
        const path = try inputsPath(a, self.cache_root, self.target, g);
        if (log.paths.count() == 0) return discard(self.io, path);
        const paths = try a.dupe([]const u8, log.paths.keys());
        std.mem.sort([]const u8, paths, {}, struct {
            fn lt(_: void, x: []const u8, y: []const u8) bool {
                return std.mem.lessThan(u8, x, y);
            }
        }.lt);
        var text: std.ArrayListUnmanaged(u8) = .empty;
        for (paths) |p| {
            try text.appendSlice(a, p);
            try text.append(a, '\n');
        }
        try write(a, self.io, path, text.items);
    }
};

fn pid() u64 {
    return switch (builtin.os.tag) {
        .windows => std.os.windows.GetCurrentProcessId(),
        .linux => @intCast(std.os.linux.getpid()),
        else => @intCast(std.c.getpid()),
    };
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;
const test_scratch = @import("test_scratch");

test "paths: one file per package and target under the cache root; std one per module, `/` as `@`" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/erlang/shelf.bpa", try packagePath(a, "/ws", .{ .target = .erlang }, "shelf"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/wasm/shelf.bpa", try packagePath(a, "/ws", .{ .target = .wasm }, "shelf"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/wasm.browser/shelf.bpa", try packagePath(a, "/ws", .{ .target = .wasm, .host = .browser }, "shelf"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/commonJS/std/io@fs.bpa", try stdPath(a, "/ws", .{ .target = .commonJS }, "std/io/fs"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/beam/std/collections.bpa", try stdPath(a, "/ws", .{ .target = .beam }, "collections"));
    try testing.expectEqualStrings("/ws/.botopinkbuild/analysis/beam", try targetDir(a, "/ws", .{ .target = .beam }));
}

test "root: a member's is its workspace's, a cell's the override" {
    var proj: config.ProjectConfig = .{ .name = "m" };
    proj.dir = "/ws/members/m";
    try testing.expectEqualStrings("/ws/members/m", root(proj));
    proj.workspace = .{ .dir = "/ws", .manifest = proj.manifest, .members = &.{} };
    try testing.expectEqualStrings("/ws", root(proj));
    code_cache.root_override = "/cells";
    defer code_cache.root_override = null;
    try testing.expectEqualStrings("/cells", root(proj));
}

test "write / read: a whole entry comes back; the write replaces, leaving nothing staged" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "analysis-store-rw");
    defer test_scratch.remove(io, "analysis-store-rw");
    const cache_root = test_scratch.path(io, "analysis-store-rw");
    const path = try packagePath(a, cache_root, .{ .target = .erlang }, "shelf");
    const key: [code_cache.KEY_HEX]u8 = @splat('a');

    try testing.expect(try read(a, io, path, key) == null);
    try write(a, io, path, try entry.pack(a, entry.keyFromHex(key), &.{.{ .id = .analysis, .bytes = "first" }}));
    try write(a, io, path, try entry.pack(a, entry.keyFromHex(key), &.{.{ .id = .analysis, .bytes = "second" }}));
    const e = (try read(a, io, path, key)).?;
    try testing.expectEqualStrings("second", e.get(.analysis).?);

    // Nothing but the entry is left in its directory.
    var d = try std.Io.Dir.cwd().openDir(io, std.fs.path.dirname(path).?, .{ .iterate = true });
    defer d.close(io);
    var it = d.iterate();
    var names: usize = 0;
    while (try it.next(io)) |ent| {
        try testing.expectEqualStrings("shelf.bpa", ent.name);
        names += 1;
    }
    try testing.expectEqual(@as(usize, 1), names);
}

test "read: an entry in doubt is deleted and answers a miss — truncated, another key, a flipped byte" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "analysis-store-doubt");
    defer test_scratch.remove(io, "analysis-store-doubt");
    const cache_root = test_scratch.path(io, "analysis-store-doubt");
    const path = try stdPath(a, cache_root, .{ .target = .commonJS }, "io/fs");
    const key: [code_cache.KEY_HEX]u8 = @splat('b');
    const good = try entry.pack(a, entry.keyFromHex(key), &.{.{ .id = .analysis, .bytes = "module" }});

    const cwd = std.Io.Dir.cwd();
    const cases = [_][]const u8{ good[0 .. good.len - 1], good[0..10], "" };
    for (cases) |bad| {
        try write(a, io, path, bad);
        try testing.expect(try read(a, io, path, key) == null);
        try testing.expectError(error.FileNotFound, cwd.access(io, path, .{}));
    }
    // Another key: the file is not this key's entry.
    try write(a, io, path, good);
    try testing.expect(try read(a, io, path, @splat('c')) == null);
    try testing.expectError(error.FileNotFound, cwd.access(io, path, .{}));
    // A flipped byte of the payload.
    const flipped = try a.dupe(u8, good);
    flipped[flipped.len - 2] ^= 1;
    try write(a, io, path, flipped);
    try testing.expect(try read(a, io, path, key) == null);
    try testing.expectError(error.FileNotFound, cwd.access(io, path, .{}));
    // The good one reads.
    try write(a, io, path, good);
    try testing.expectEqualStrings("module", (try read(a, io, path, key)).?.get(.analysis).?);
}
