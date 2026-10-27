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
const build_stamp = @import("build_stamp");
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

/// `<dir>/<target>.key`: the target key beside the `.bpr`'s (decision 1008 (1)).
pub fn targetKeyPath(arena: std.mem.Allocator, dir: []const u8, target: config.Target) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), @tagName(target), KEY_EXT });
}

/// What an emit's output depends on besides the `.bpr` set (decision 1008 (1)).
pub const EmitInputs = struct {
    /// The `.bpr` set's key (`keyOf`).
    bpr_key: Key,
    target: config.Target,
    wasm_host: bp.ast.WasmHost,
    /// The compiler's source stamp (805 (2)).
    stamp: []const u8 = build_stamp.source_hash,
    /// `--typescript` or the manifest's `"typings"`.
    typings: bool,
    /// `--out`, as given.
    out_dir: []const u8,
    /// The module `run` starts (wasm emits only its component).
    entry: []const u8,
    /// The OTP release the erlang / beam compile is for.
    otp_release: []const u8 = bp.otp.RELEASE,
};

/// The target key of an emit (decision 1008 (1)): a hash of a tag, the `.bpr`
/// set's key, the target and its wasm host, the compiler's stamp, the emit
/// options and — for erlang and beam — the OTP release and the options the
/// `.beam`s are compiled with.
pub fn targetKey(in: EmitInputs) Key {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink-target-1\x00");
    h.update(&in.bpr_key);
    h.update(&.{0});
    h.update(@tagName(in.target));
    h.update(&.{0});
    h.update(@tagName(in.wasm_host));
    h.update(&.{0});
    h.update(in.stamp);
    h.update(&.{0});
    h.update(if (in.typings) "typings" else "no-typings");
    h.update(&.{0});
    h.update(in.out_dir);
    h.update(&.{0});
    h.update(in.entry);
    h.update(&.{0});
    if (in.target == .erlang or in.target == .beam) {
        h.update(in.otp_release);
        h.update(&.{0});
        h.update("deterministic,binary,return_errors");
        h.update(&.{0});
    }
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// Whether the target key file in `dir` holds `key`.
pub fn targetMatches(arena: std.mem.Allocator, io: std.Io, dir: []const u8, target: config.Target, key: Key) bool {
    const kp = targetKeyPath(arena, dir, target) catch return false;
    const held = std.Io.Dir.cwd().readFileAlloc(io, kp, arena, .limited(4096)) catch return false;
    return std.mem.eql(u8, std.mem.trimEnd(u8, held, "\n"), &key);
}

/// Removes the target key before an emit, so one written in part never matches.
pub fn removeTargetKey(arena: std.mem.Allocator, io: std.Io, dir: []const u8, target: config.Target) void {
    const kp = targetKeyPath(arena, dir, target) catch return;
    std.Io.Dir.cwd().deleteFile(io, kp) catch {};
}

/// Writes the target key once the emit succeeded, last.
pub fn writeTargetKey(arena: std.mem.Allocator, io: std.Io, dir: []const u8, target: config.Target, key: Key) void {
    const kp = targetKeyPath(arena, dir, target) catch return;
    analysis_store.write(arena, io, kp, std.fmt.allocPrint(arena, "{s}\n", .{&key}) catch return) catch {};
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;
const test_scratch = @import("test_scratch");
const manifest = @import("manifest");

test "targetKey: the target, the host, the emit options and the .bpr key move it; the OTP release only for erlang and beam" {
    const base: EmitInputs = .{ .bpr_key = @splat('a'), .target = .commonJS, .wasm_host = .wasi, .typings = false, .out_dir = "out", .entry = "main" };
    const k0 = targetKey(base);
    try testing.expectEqualSlices(u8, &k0, &targetKey(base));
    var v = base;
    v.target = .beam;
    try testing.expect(!std.mem.eql(u8, &k0, &targetKey(v)));
    v = base;
    v.bpr_key = @splat('b');
    try testing.expect(!std.mem.eql(u8, &k0, &targetKey(v)));
    v = base;
    v.typings = true;
    try testing.expect(!std.mem.eql(u8, &k0, &targetKey(v)));
    v = base;
    v.out_dir = "o2";
    try testing.expect(!std.mem.eql(u8, &k0, &targetKey(v)));
    v = base;
    v.stamp = "other";
    try testing.expect(!std.mem.eql(u8, &k0, &targetKey(v)));
    v = base;
    v.otp_release = "99";
    try testing.expectEqualSlices(u8, &k0, &targetKey(v));
    v.target = .erlang;
    var w = v;
    w.otp_release = "98";
    try testing.expect(!std.mem.eql(u8, &targetKey(v), &targetKey(w)));
}

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
