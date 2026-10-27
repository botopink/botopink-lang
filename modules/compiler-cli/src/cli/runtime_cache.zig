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

/// Whether the `.bpr` set of `pkg` in `dir` is fresh for `key` under `stamp`:
/// the key file's first line is `key`.
pub fn isFresh(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8, key: Key, stamp: runtime_file.Stamp) bool {
    const kp = keyPath(arena, dir, pkg) catch return false;
    const held = std.Io.Dir.cwd().readFileAlloc(io, kp, arena, .limited(1 << 20)) catch return false;
    var lines = std.mem.splitScalar(u8, held, '\n');
    if (!std.mem.eql(u8, lines.first(), &key)) return false;
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

/// Writes the key file once the set is written whole: the key, then each
/// package the analysis loaded by name (`loadsOf`'s lines), one per line.
pub fn writeKey(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8, key: Key, loads: []const []const u8) !void {
    const kp = try keyPath(arena, dir, pkg);
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.print(arena, "{s}\n", .{&key});
    for (loads) |l| try text.print(arena, "{s}\n", .{l});
    try analysis_store.write(arena, io, kp, text.items);
}

// ── The packages loaded by name (decisions 1006 (6) P5, 1030, 1039) ───────
//
// A `compiler.load(package: "<name>")` makes another package part of what
// the analysis reads: its key covers that package's — the packages the last
// analysis loaded by name, nested loads included, are kept in the key file
// after the key (`loadsOf`: each its directory, and the name and the
// directory it was looked up from), and the key is the package's own
// (`keyOf`) combined with each one's key and the directory its name resolves
// to now (`withLoads`, `libs.keyWithNamedLoads`), so a changed library, or a
// name resolving elsewhere, makes its loader stale (1039 (3)). The loaded
// package's own set lives under the LOADING build's cache root (`load_root`,
// decision 1030 (1)), analysed with its load directory as `root` (1003 (2)):
// one set per load directory and wasm host, its directory named by a hash of
// both (`loadedPlace`, `loadedDir`) and never by the library's content, which
// its key file holds (`loadedIdent`) — so two sets of one library never share
// a file name, and an edited library's set is written again in place, its
// files no longer written removed (`pruneSet`, 1039 (2); `libs.zig`'s
// `runtimeRead` / `runtimeWrite`).

/// The cache root of the build that runs (`analysis_store.root` of its
/// package): where the sets of the packages it loads by name live. Null in a
/// command that keeps none.
pub var load_root: ?[]const u8 = null;

/// The key of a loaded package's set before its loads: its own key, the
/// directory it was loaded from, as its `root` reads it, and the wasm host the
/// loading build analyses it for.
pub fn loadedIdent(base: Key, root: []const u8, wasm_host: bp.ast.WasmHost) Key {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink-runtime-loaded-1\x00");
    h.update(&base);
    h.update(&.{0});
    h.update(root);
    h.update(&.{0});
    h.update(@tagName(wasm_host));
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// Where a loaded package's set lives, without its content (decision 1039
/// (2)): a hash of the directory it was loaded from and the wasm host — no
/// path in the name.
pub fn loadedPlace(root: []const u8, wasm_host: bp.ast.WasmHost) Key {
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink-runtime-loaded-place-1\x00");
    h.update(root);
    h.update(&.{0});
    h.update(@tagName(wasm_host));
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// `<cache root>/.botopinkbuild/runtime/<pkg>@<place>`: the set of `pkg`
/// loaded by name from one directory for one wasm host (`loadedPlace`). `@` is
/// in no package name.
pub fn loadedDir(arena: std.mem.Allocator, cache_root: []const u8, pkg: []const u8, place: Key) ![]const u8 {
    const leaf = try std.fmt.allocPrint(arena, "{s}@{s}", .{ pkg, &place });
    return std.fs.path.join(arena, &.{ cache_root, DIR, leaf });
}

/// Removes every `.bpr` under `dir` that `written` does not name: a set
/// written again in place keeps no file of the one before (decision 1039 (2)).
pub fn pruneSet(arena: std.mem.Allocator, io: std.Io, dir: []const u8, written: []const Written) void {
    pruneUnder(arena, io, dir, written) catch {};
}

fn pruneUnder(arena: std.mem.Allocator, io: std.Io, dir: []const u8, written: []const Written) !void {
    var d = std.Io.Dir.cwd().openDir(io, dir, .{ .iterate = true }) catch return;
    defer d.close(io);
    var it = d.iterate();
    while (try it.next(io)) |e| {
        const path = try std.fs.path.join(arena, &.{ dir, e.name });
        switch (e.kind) {
            .directory => try pruneUnder(arena, io, path, written),
            .file => if (std.mem.endsWith(u8, e.name, runtime_file.EXT)) {
                const kept = for (written) |w| {
                    if (std.mem.eql(u8, w.path, path)) break true;
                } else false;
                if (!kept) std.Io.Dir.cwd().deleteFile(io, path) catch {};
            },
            else => {},
        }
    }
}

/// `build --cold` (`Options.rebuild`): a load reads no set either, and
/// writes the one it analyses.
pub var rebuild: bool = false;

/// The compiler a `.bpr` is written and read by (decision 805 (2)): the hash
/// of the sources this binary is built from, which covers the analysis's
/// types the file's encoding follows.
pub fn bprStamp() runtime_file.Stamp {
    var out: runtime_file.Stamp = undefined;
    std.crypto.hash.sha2.Sha256.hash("botopink .bpr\x00" ++ @import("build_stamp").source_hash, &out, .{});
    return out;
}

/// The packages the last analysis of `pkg` loaded by name — the key file's
/// lines after the key, each `<dir>\t<name>\t<from>` (the package's
/// directory, the name it was loaded by and the directory it was looked up
/// from, both directories relative to `pkg`'s, `libs.relativeLoads`); none
/// when there is no key file.
pub fn loadsOf(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8) []const []const u8 {
    const kp = keyPath(arena, dir, pkg) catch return &.{};
    const held = std.Io.Dir.cwd().readFileAlloc(io, kp, arena, .limited(1 << 20)) catch return &.{};
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, held, '\n');
    _ = lines.first();
    while (lines.next()) |l| if (l.len > 0) out.append(arena, l) catch return &.{};
    return out.items;
}

/// One package loaded by name: its key-file line as it reads now (its
/// directory relative to the loader — where its name resolves now —, the name
/// and the directory it was looked up from) and its current key.
pub const LoadKey = struct { rel: []const u8, key: Key };

/// `base` with the keys of the packages loaded by name: `base` itself when
/// there is none, so a package that loads nothing by name keys as before.
pub fn withLoads(arena: std.mem.Allocator, base: Key, loads: []const LoadKey) !Key {
    if (loads.len == 0) return base;
    const sorted = try arena.dupe(LoadKey, loads);
    std.mem.sort(LoadKey, sorted, {}, struct {
        fn lt(_: void, a: LoadKey, b: LoadKey) bool {
            return std.mem.lessThan(u8, a.rel, b.rel);
        }
    }.lt);
    var h = std.crypto.hash.sha2.Sha256.init(.{});
    h.update("botopink-runtime-loads-1\x00");
    h.update(&base);
    for (sorted) |l| {
        h.update(&.{0});
        h.update(l.rel);
        h.update(&.{0});
        h.update(&l.key);
    }
    var digest: [32]u8 = undefined;
    h.final(&digest);
    return std.fmt.bytesToHex(digest, .lower);
}

/// A `.bpr` path written by `writeSet`, the root's flagged.
pub const Written = struct { path: []const u8, root: bool };

/// `<dir>/<group>.bpr` (`std/io` → `<dir>/std/io.bpr`).
pub fn groupPath(arena: std.mem.Allocator, dir: []const u8, group: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ std.mem.trimEnd(u8, dir, "/"), group, runtime_file.EXT });
}

/// What a set is of: the root package, the dependency packages the module
/// table names, the wasm host of the program.
pub const SetMeta = struct { root: []const u8, deps: []const []const u8, wasm_host: bp.ast.WasmHost };

/// One `<dir>/<group>.bpr` per package of the analysed program (decision 805
/// (1)) — a dependency's, a loaded file's, each embedded std module's, then
/// the root package's, which alone names the program (`Meta.program`) —, the
/// key file removed first and written last (`key` null: none, the set is
/// never fresh). A program one of whose modules did not analyse writes
/// nothing. Each path written is appended to `written` (in `keep`).
pub fn writeSet(
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    meta_of: SetMeta,
    key: ?Key,
    loads: []const []const u8,
    outputs: []const bp.codegen.ComptimeOutput,
    readers: []const []const u8,
    written: ?*std.ArrayListUnmanaged(Written),
    keep: std.mem.Allocator,
) !void {
    for (outputs) |o| if (o.outcome != .ok) return;
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // The groups in the order their first module comes, each its modules.
    var groups: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(bp.codegen.ComptimeOutput)) = .empty;
    const program = try arena.alloc(runtime_file.Placed, outputs.len);
    for (outputs, program) |o, *p| {
        // A module reading `@TypeInfo.all` answers for the whole program
        // (805 (1)): the root's file holds it, whatever its package.
        const reads = for (readers) |r| {
            if (std.mem.eql(u8, r, o.name)) break true;
        } else false;
        const g = if (reads) meta_of.root else runtime_file.groupOf(o.name, meta_of.root, meta_of.deps);
        const slot = try groups.getOrPut(arena, g);
        if (!slot.found_existing) slot.value_ptr.* = .empty;
        try slot.value_ptr.append(arena, o);
        p.* = .{ .group = g, .module = o.name };
    }
    std.Io.Dir.cwd().createDirPath(io, dir) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };
    const st = bprStamp();
    // A set written in part is never fresh: its key goes first.
    removeKey(arena, io, dir, meta_of.root);
    var it = groups.iterator();
    while (it.next()) |g| {
        const mods = g.value_ptr.items;
        const names = try arena.alloc([]const u8, mods.len);
        for (mods, names) |m, *n| n.* = m.name;
        const is_root = std.mem.eql(u8, g.key_ptr.*, meta_of.root);
        const meta: runtime_file.Meta = .{
            .group = g.key_ptr.*,
            .modules = names,
            .program = if (is_root) program else &.{},
            .root = if (is_root) meta_of.root else "",
            .deps = if (is_root) meta_of.deps else &.{},
            .wasm_host = if (is_root) meta_of.wasm_host else .wasi,
        };
        const bytes = try runtime_file.write(gpa, st, meta, mods);
        defer gpa.free(bytes);
        const path = try groupPath(arena, dir, g.key_ptr.*);
        // Whole or not at all (`analysis_store.write`): a build reading a
        // dependency's `.bpr` another build is writing reads the old file
        // or the new one, never a part.
        try analysis_store.write(arena, io, path, bytes);
        if (written) |w| try w.append(keep, .{ .path = try keep.dupe(u8, path), .root = is_root });
    }
    if (key) |k| try writeKey(arena, io, dir, meta_of.root, k, loads);
}

/// The analysed program of the set of `pkg` in `dir` — the root's file and
/// each package file it names beside it, decoded into `arena`, in the
/// program's order; null when a file is missing or does not read back.
pub fn readProgram(arena: std.mem.Allocator, io: std.Io, dir: []const u8, pkg: []const u8) !?[]const bp.codegen.ComptimeOutput {
    const st = bprStamp();
    const cwd = std.Io.Dir.cwd();
    const root_bytes = cwd.readFileAlloc(io, try rootPath(arena, dir, pkg), arena, .unlimited) catch return null;
    const root_file = runtime_file.read(arena, root_bytes, st) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    if (root_file.meta.program.len == 0) return null;
    var files: std.StringHashMapUnmanaged(runtime_file.Decoded) = .empty;
    try files.put(arena, root_file.meta.group, root_file);
    const outputs = try arena.alloc(bp.codegen.ComptimeOutput, root_file.meta.program.len);
    for (root_file.meta.program, outputs) |placed, *out| {
        const decoded = files.get(placed.group) orelse blk: {
            const bytes = cwd.readFileAlloc(io, try groupPath(arena, dir, placed.group), arena, .unlimited) catch return null;
            const d = runtime_file.read(arena, bytes, st) catch |err| switch (err) {
                error.OutOfMemory => return error.OutOfMemory,
                else => return null,
            };
            try files.put(arena, placed.group, d);
            break :blk d;
        };
        out.* = for (decoded.outputs) |o| {
            if (std.mem.eql(u8, o.name, placed.module)) break o;
        } else return null;
    }
    return outputs;
}

/// `<dir>/<pkg>.<target>.key`: the target key beside the `.bpr`'s `<pkg>.key` (decisions 1008 (1), 1029). `dir` is
/// `dirFor`'s `<cache root>/.botopinkbuild/runtime/<pkg>`, so the package is its last segment; no package name is
/// reserved — `erlang.erlang.key` sits beside `erlang.key`.
pub fn targetKeyPath(arena: std.mem.Allocator, dir: []const u8, target: config.Target) ![]const u8 {
    const d = std.mem.trimEnd(u8, dir, "/");
    return std.fmt.allocPrint(arena, "{s}/{s}.{s}{s}", .{ d, std.fs.path.basename(d), @tagName(target), KEY_EXT });
}

test "targetKeyPath: <pkg>.<target>.key, never the .bpr's own key (decision 1029)" {
    var a = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer a.deinit();
    const p = try targetKeyPath(a.allocator(), "/c/.botopinkbuild/runtime/erlang/", .erlang);
    try std.testing.expectEqualStrings("/c/.botopinkbuild/runtime/erlang/erlang.erlang" ++ KEY_EXT, p);
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

test "withLoads: no load keeps the key; the loads' order does not count; a loaded package's key moves it" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const base: Key = @splat('b');
    try testing.expectEqualSlices(u8, &base, &(try withLoads(a, base, &.{})));
    const x: LoadKey = .{ .rel = "../libs/x", .key = @splat('x') };
    const y: LoadKey = .{ .rel = "../libs/y", .key = @splat('y') };
    const xy = try withLoads(a, base, &.{ x, y });
    try testing.expect(!std.mem.eql(u8, &base, &xy));
    try testing.expectEqualSlices(u8, &xy, &(try withLoads(a, base, &.{ y, x })));
    const x2: LoadKey = .{ .rel = "../libs/x", .key = @splat('z') };
    try testing.expect(!std.mem.eql(u8, &xy, &(try withLoads(a, base, &.{ x2, y }))));
}

test "writeKey / loadsOf / isFresh: the loads follow the key; the key alone decides" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const io = testing.io;
    test_scratch.remove(io, "runtime-loads");
    defer test_scratch.remove(io, "runtime-loads");
    const dir = test_scratch.path(io, "runtime-loads/set");
    const key: Key = @splat('k');
    try writeKey(a, io, dir, "app", key, &.{ "../libs/greeter", "vendor/x" });
    const loads = loadsOf(a, io, dir, "app");
    try testing.expectEqual(@as(usize, 2), loads.len);
    try testing.expectEqualStrings("../libs/greeter", loads[0]);
    try testing.expectEqualStrings("vendor/x", loads[1]);
    try testing.expectEqual(@as(usize, 0), loadsOf(a, io, dir, "other").len);
    // No root `.bpr` beside it: never fresh, whatever the key.
    try testing.expect(!isFresh(a, io, dir, "app", key, bprStamp()));
}
