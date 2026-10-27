/// A package's `.bpr` set and its key (decision 1006 (2), (3)): where a bare
/// `botopink build` writes the resolved program (805), and how `build
/// --target <t>` / `run --target <t>` know it is fresh — the one place the
/// build, the key and the reuse meet, so a workspace's fan-out (1006 (5))
/// runs it per member.
///
/// **Where.** `<cache root>/.botopinkbuild/runtime/<pkg>/` (`dirFor`): the
/// cache root of decision 225 (`analysis_store.root`: `--cache-root`, else the
/// workspace root, else the project), beside the code cache and outside the
/// `.botopinkbuild/cache/` that `--cold` deletes; `--emit-runtime <dir>`
/// names another directory. It holds every package's `.bpr` (the root's
/// `<pkg>.bpr`, a dependency's, std's under `std/`) and the root's key file
/// `<pkg>.key` (`keyPath`).
///
/// **Fresh** (`isFresh`): the key file holds the key computed now
/// (`code_cache.runtimeKey`, over the package's files, its effective manifest,
/// its dependencies' keys and the compiler's source stamp) and the root's
/// `.bpr` opens with this compiler's stamp. No file time is read.
const std = @import("std");
const bp = @import("botopink");
const config = @import("./config.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");
const libs = @import("./libs.zig");
const runtime_file = bp.runtime_file;

/// The directory under the cache root.
pub const DIR = ".botopinkbuild/runtime";

/// The key file's extension, beside the root's `.bpr`.
pub const KEY_EXT = ".key";

pub const Key = [code_cache.KEY_HEX]u8;

/// `<cache root>/.botopinkbuild/runtime/<pkg>` for `proj`.
pub fn dirFor(arena: std.mem.Allocator, proj: config.ProjectConfig) ![]const u8 {
    return std.fs.path.join(arena, &.{ analysis_store.root(proj), DIR, proj.name });
}

/// `<dir>/<pkg>.key`.
pub fn keyPath(arena: std.mem.Allocator, dir: []const u8, pkg: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), pkg, KEY_EXT });
}

/// `<dir>/<pkg>.bpr`, the root package's file.
pub fn rootPath(arena: std.mem.Allocator, dir: []const u8, pkg: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), pkg, runtime_file.EXT });
}

/// The key of the package `proj` (decision 1006 (3)): its files, its
/// effective manifest and its direct dependencies' runtime keys — which
/// `libs.loadDependenciesWith` computed into `keys.runtime` (`want_runtime`).
/// `outputs` are the command's output directories (`--out`, `--emit-runtime`),
/// as given: those inside the package are left out of the key (decision
/// 1006-b (3), `insidePackage`).
pub fn keyOf(arena: std.mem.Allocator, io: std.Io, proj: config.ProjectConfig, keys: *const libs.ClosureKeys, outputs: []const []const u8) !Key {
    var deps: std.ArrayListUnmanaged(code_cache.DepKey) = .empty;
    for (proj.dependencies) |d| if (keys.runtime.get(d.name)) |k| try deps.append(arena, .{ .name = d.name, .key = k });
    var inside: std.ArrayListUnmanaged([]const u8) = .empty;
    for (outputs) |o| if (try insidePackage(arena, proj.dir, o)) |rel| try inside.append(arena, rel);
    return code_cache.runtimeKey(arena, io, proj.dir, proj.manifest, deps.items, inside.items);
}

/// `dir` (relative to the working directory, the package's, or absolute) as a
/// path from the package directory `pkg_dir` when it lies inside it; null
/// otherwise, or when it is the package itself.
pub fn insidePackage(arena: std.mem.Allocator, pkg_dir: []const u8, dir: []const u8) !?[]const u8 {
    const abs = if (std.fs.path.isAbsolute(dir)) try std.fs.path.resolve(arena, &.{dir}) else try std.fs.path.resolve(arena, &.{ pkg_dir, dir });
    const root = try std.fs.path.resolve(arena, &.{pkg_dir});
    if (abs.len <= root.len + 1 or !std.mem.startsWith(u8, abs, root) or abs[root.len] != '/') return null;
    return abs[root.len + 1 ..];
}

/// Whether the `.bpr` set of `pkg` in `dir` is fresh for `key` under `stamp`.
pub fn isFresh(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8, key: Key, stamp: runtime_file.Stamp) bool {
    const kp = keyPath(arena, dir, pkg) catch return false;
    const held = std.Io.Dir.cwd().readFileAlloc(io, kp, arena, .limited(4096)) catch return false;
    if (!std.mem.eql(u8, std.mem.trimEnd(u8, held, "\n"), &key)) return false;
    const rp = rootPath(arena, dir, pkg) catch return false;
    const bytes = std.Io.Dir.cwd().readFileAlloc(io, rp, arena, .unlimited) catch return false;
    return runtime_file.opensWith(bytes, stamp);
}

/// Removes the key file before a set is written again, so a set written in
/// part is never fresh.
pub fn removeKey(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8) void {
    const kp = keyPath(arena, dir, pkg) catch return;
    std.Io.Dir.cwd().deleteFile(io, kp) catch {};
}

/// Writes the key file once the set is written whole.
pub fn writeKey(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8, key: Key) !void {
    const kp = try keyPath(arena, dir, pkg);
    try analysis_store.write(arena, io, kp, try std.fmt.allocPrint(arena, "{s}\n", .{&key}));
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;
const test_scratch = @import("test_scratch");
const manifest = @import("manifest");

test "insidePackage: an output directory inside the package, as a path from it" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    try testing.expectEqualStrings("rt", (try insidePackage(a, "/p/app", "rt")).?);
    try testing.expectEqualStrings("b/o", (try insidePackage(a, "/p/app", "./b/o/")).?);
    try testing.expectEqualStrings("rt", (try insidePackage(a, "/p/app", "/p/app/rt")).?);
    try testing.expect((try insidePackage(a, "/p/app", "/p/other/rt")) == null);
    try testing.expect((try insidePackage(a, "/p/app", "../rt")) == null);
    try testing.expect((try insidePackage(a, "/p/app", ".")) == null);
    try testing.expect((try insidePackage(a, "/p/app", "/p/appx/rt")) == null);
}

test "runtimeKey: by content; out/, hidden entries, node_modules, *.new and the outputs left out; the stamp and a dependency move it" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "runtime-key");
    defer test_scratch.remove(io, "runtime-key");
    const base = test_scratch.path(io, "runtime-key/pkg");
    const cwd = std.Io.Dir.cwd();
    try cwd.createDirPath(io, try std.fs.path.join(arena, &.{ base, "src" }));
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ base, "botopink.json" }), .data = "{ \"name\": \"k\" }\n" });
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ base, "src/main.bp" }), .data = "pub fn main() -> void {}\n" });
    var err: ?manifest.Located = null;
    const m = try manifest.parse(arena, "{ \"name\": \"k\" }", "botopink.json", &err);
    const k0 = try code_cache.runtimeKeyWith(arena, io, base, m, &.{}, "s1", &.{"build/o"});
    // Left out: out/, a hidden entry, node_modules, a `*.new`, an output directory.
    for ([_][]const u8{ "out/x.js", ".state/runtime/k.bpr", "src/.hidden", "node_modules/m/i.js", "snapshot/main.snap.new", "build/o/x.js" }) |rel| {
        const p = try std.fs.path.join(arena, &.{ base, rel });
        try cwd.createDirPath(io, std.fs.path.dirname(p).?);
        try cwd.writeFile(io, .{ .sub_path = p, .data = "noise" });
    }
    try testing.expectEqualSlices(u8, &k0, &(try code_cache.runtimeKeyWith(arena, io, base, m, &.{}, "s1", &.{"build/o"})));
    // The directory named as an output only.
    try testing.expect(!std.mem.eql(u8, &k0, &(try code_cache.runtimeKeyWith(arena, io, base, m, &.{}, "s1", &.{}))));
    // Another compiler, a dependency's key, a changed byte.
    try testing.expect(!std.mem.eql(u8, &k0, &(try code_cache.runtimeKeyWith(arena, io, base, m, &.{}, "s2", &.{"build/o"}))));
    const dep: code_cache.DepKey = .{ .name = "d", .key = @splat('a') };
    try testing.expect(!std.mem.eql(u8, &k0, &(try code_cache.runtimeKeyWith(arena, io, base, m, &.{dep}, "s1", &.{"build/o"}))));
    try cwd.writeFile(io, .{ .sub_path = try std.fs.path.join(arena, &.{ base, "src/main.bp" }), .data = "pub fn main() -> void { }\n" });
    try testing.expect(!std.mem.eql(u8, &k0, &(try code_cache.runtimeKeyWith(arena, io, base, m, &.{}, "s1", &.{"build/o"}))));
}
