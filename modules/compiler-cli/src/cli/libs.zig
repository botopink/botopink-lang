/// Generic external-lib loader.
///
/// Resolves a project's declared `dependencies` (from `botopink.json`) to their
/// source modules on disk and returns them as `botopink.Module` values, prefixed
/// by lib name (`rakun/http`, `rakun/rakun`, …). This is the driver-side half of
/// the lib-agnostic package mechanism: the compiler core never names a specific
/// lib — it only sees ordinary `Module[]` and resolves `from "<lib>"` generically
/// through the shared import registry. `std` is the one embedded exception and is
/// NOT loaded here.
///
/// Lib layout (each lib carries its own manifest):
///   <libs_root>/<name>/botopink.json   { "src": "src/", "files": ["a.bp", …] }
///   <libs_root>/<name>/<src>/<file>
///
/// or, under a workspace (decision 75), `<root>/<lib>/botopink.json` declares
/// `"workspaces"` and every member it expands to is reachable by its own
/// `name`. Which library a `dependencies` entry means is the shared
/// `manifest.resolveDependency`: `{ "path" }` from the project's directory,
/// `{ "workspace": true }` from the enclosing workspace, `{ "git" }` by name
/// across the lookup tiers (`dependencyTiers`, decision 483):
/// `BOTOPINK_LIB_ROOTS`, the project's `.botopinkbuild/deps/` links, then the
/// walk-up roots.
const std = @import("std");
const bp = @import("botopink");
const manifest = @import("manifest");
const config = @import("./config.zig");
const diagnostics = @import("./diagnostics.zig");
const reporter = @import("./reporter.zig");
const arglist = @import("./arglist.zig");
const otp = @import("./otp.zig");
const resolver = @import("./resolver.zig");
const sources = @import("./sources.zig");
const bpp = @import("./bpp.zig");
const bpp_unfold = @import("./bpp_unfold.zig");
const code_cache = @import("./code_cache.zig");
const analysis_store = @import("./analysis_store.zig");
const runtime_cache = @import("./runtime_cache.zig");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");

const Module = bp.Module;
const DepEntry = config.DepEntry;

/// Optional process-environment handle. The CLI threads `init.environ_map`
/// through every caller; `null` is the test-friendly "no env" mode.
pub const EnvMap = ?*const std.process.Environ.Map;

pub const Error = error{
    LibsRootNotFound,
    LibNotFound,
    /// A dependency could not be resolved to a package: its manifest was
    /// refused, it names a workspace, a `path` lands on a sibling member, a
    /// `{ "workspace": true }` has no member, … The located diagnostic has
    /// already been printed.
    LibManifestInvalid,
    /// A `files` entry of a dependency's `botopink.json` could not be read;
    /// the located diagnostic (the path looked for, the manifest line) has
    /// already been printed.
    LibFileNotFound,
    /// The manifest lists `std` — the one package the compiler ships (decision
    /// 326) — in `dependencies`; the located diagnostic has already been printed.
    BundledDependency,
    /// A module of a dependency imports a package that dependency does not
    /// declare, or a module of itself with `from` — the same refusal its own
    /// build gives (decisions 206, 242); the located diagnostic has already
    /// been printed.
    ImportSourceRefused,
} || std.mem.Allocator.Error;

/// Name of the env var that prepends extra lib roots (drop-in for `PATH`-style
/// path lists — colon-separated on POSIX, semicolon-separated on Windows). See
/// `parseEnvRootsString`.
pub const ENV_VAR = "BOTOPINK_LIB_ROOTS";

/// Where every build cache of a compilation lives, below its cache root
/// (decision 225, `manifest.CACHE_DIR`): deleting the root's `.botopinkbuild/`
/// deletes them all.
pub const CACHE_DIR = manifest.CACHE_DIR;

/// The directory whose `.botopinkbuild/cache/` holds `proj`'s build caches:
/// `manifest.cacheRoot` over the workspace `config.load` found — the root of
/// the workspace it is a member of, else the project's own directory. The
/// language server answers the same root through `manifest.findCacheRoot`.
pub fn cacheRoot(proj: config.ProjectConfig) []const u8 {
    return manifest.cacheRoot(proj.dir, proj.workspace);
}

/// `<cacheRoot(proj)>/.botopinkbuild/cache/<store>` — the home of one
/// content-keyed store (the code cache, `code_cache.zig`, keeps its own `dir`
/// for the cell override). Nothing here reads the environment: a cache in the user's
/// home is one `rm -rf .botopinkbuild` and `botopink clean` cannot reach, and
/// one a `--cold` gate still answers from.
pub fn cacheDir(arena: std.mem.Allocator, proj: config.ProjectConfig, store: []const u8) ![]const u8 {
    return manifest.cacheDir(arena, cacheRoot(proj), store);
}

/// Resolve the ordered list of library roots — directories that directly hold a
/// `<name>/botopink.json`, so `from "<name>"` and a project's declared
/// `dependencies` resolve `<name>` to the **first root** carrying it.
///
/// The list is built in two halves:
///
///   1. **Env-driven roots** parsed from `BOTOPINK_LIB_ROOTS` (when `env_map` is
///      not null and the var is set). Each entry is `std.fs.path.delimiter`-split
///      (`:` on POSIX, `;` on Windows), resolved to an absolute path, and dropped
///      silently when the directory does not exist. This is the hook bpmp uses
///      to point the compiler at its package store without symlinking.
///   2. **Walk-up roots** — for each ancestor dir `D` of cwd (nearest-first):
///        * `D` itself, when `D/botopink.json` is a workspace — its members
///          (so a member resolves its siblings from inside the workspace)
///        * `D/repository/botopink-lang/libs`  — bundled libs (std)
///        * `D/repository`                     — sibling projects (frameworks)
///        * `D/libs`                           — legacy flat tree
///      The walk stops after the first `D` that holds `repository/`
///      (`manifest.isCheckoutRoot`): that is the enclosing checkout, and an
///      ancestor of it — the main checkout above a `.tasks/<name>` worktree —
///      is another one, whose libraries would be every name a second time.
///
/// The combined list is de-duplicated first-occurrence-wins, so an env entry
/// always shadows a walk-up duplicate. With `BOTOPINK_LIB_ROOTS` unset the
/// result is byte-identical to the legacy single-source walk. Caller owns the
/// slice and every element (free with `freeRoots`).
pub fn resolveLibRoots(gpa: std.mem.Allocator, io: std.Io, env_map: EnvMap) ![][]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &buf);
    const cwd = buf[0..n];

    const env_roots = try parseEnvRoots(gpa, env_map, cwd);
    defer {
        for (env_roots) |r| gpa.free(r);
        gpa.free(env_roots);
    }
    return rootsFrom(gpa, io, env_roots, cwd);
}

/// Read `BOTOPINK_LIB_ROOTS` from `env_map` and split it into absolute root
/// paths. Returns an empty slice when the map is null, the var is unset, or
/// the value is empty. Relative entries are resolved against `cwd`. Empty
/// entries (`a::b` → `a`, `b`) are dropped silently. Caller owns the slice
/// and every element via `gpa` (free with `freeRoots`).
pub fn parseEnvRoots(
    gpa: std.mem.Allocator,
    env_map: EnvMap,
    cwd: []const u8,
) ![][]const u8 {
    const m = env_map orelse return gpa.alloc([]const u8, 0);
    const value = m.get(ENV_VAR) orelse return gpa.alloc([]const u8, 0);
    return parseEnvRootsString(gpa, value, cwd);
}

/// `parseEnvRoots` minus the env lookup — splits a literal value into roots.
/// Empty `value` returns an empty slice (no allocations beyond the zero-length
/// header). Split out so tests can drive synthetic env contents.
pub fn parseEnvRootsString(
    gpa: std.mem.Allocator,
    value: []const u8,
    cwd: []const u8,
) ![][]const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer {
        for (out.items) |r| gpa.free(r);
        out.deinit(gpa);
    }
    if (value.len == 0) return out.toOwnedSlice(gpa);

    var it = std.mem.splitScalar(u8, value, std.fs.path.delimiter);
    while (it.next()) |raw| {
        if (raw.len == 0) continue;
        const abs = if (std.fs.path.isAbsolute(raw))
            try gpa.dupe(u8, raw)
        else
            try std.fs.path.resolve(gpa, &.{ cwd, raw });
        try out.append(gpa, abs);
    }
    return out.toOwnedSlice(gpa);
}

/// `resolveLibRoots` minus the cwd lookup — walks up from `start` after seeding
/// with `env_roots`. Split out so a test can drive a synthetic tree without
/// touching the process cwd.
pub fn rootsFrom(
    gpa: std.mem.Allocator,
    io: std.Io,
    env_roots: []const []const u8,
    start: []const u8,
) ![][]const u8 {
    var dir = start;

    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer {
        for (roots.items) |r| gpa.free(r);
        roots.deinit(gpa);
    }

    // Env roots first; non-existent entries are silently dropped (a typo in
    // BOTOPINK_LIB_ROOTS must never break a build that does not depend on the
    // missing root).
    for (env_roots) |er| {
        try addRootIfExists(gpa, io, &roots, &.{er});
    }

    while (true) {
        if (manifest.isWorkspaceDir(io, dir)) try addRootIfExists(gpa, io, &roots, &.{dir});
        try addRootIfExists(gpa, io, &roots, &.{ dir, "repository", "botopink-lang", "libs" });
        try addRootIfExists(gpa, io, &roots, &.{ dir, "repository" });
        try addRootIfExists(gpa, io, &roots, &.{ dir, "libs" });
        // The enclosing checkout ends the walk (`manifest.isCheckoutRoot`): a
        // worktree nested in the meta checkout must not see its `repository/*`.
        if (manifest.isCheckoutRoot(io, dir)) break;

        const parent = std.fs.path.dirname(dir) orelse break;
        if (std.mem.eql(u8, parent, dir)) break;
        dir = dir[0..parent.len];
    }

    return roots.toOwnedSlice(gpa);
}

/// Join `parts` into a candidate root; if it is an existing directory and not
/// already in `roots`, append it (transferring ownership). Otherwise free it.
fn addRootIfExists(
    gpa: std.mem.Allocator,
    io: std.Io,
    roots: *std.ArrayListUnmanaged([]const u8),
    parts: []const []const u8,
) !void {
    const candidate = try std.fs.path.join(gpa, parts);
    var keep = false;
    defer if (!keep) gpa.free(candidate);

    var d = std.Io.Dir.cwd().openDir(io, candidate, .{}) catch return;
    d.close(io);

    for (roots.items) |r| {
        if (std.mem.eql(u8, r, candidate)) return; // de-dup, nearest-first wins
    }
    try roots.append(gpa, candidate);
    keep = true;
}

/// Free a root list produced by `resolveLibRoots`.
pub fn freeRoots(gpa: std.mem.Allocator, roots: [][]const u8) void {
    for (roots) |r| gpa.free(r);
    gpa.free(roots);
}

/// Load every module of every declared dependency of `proj`. Returns a flat
/// `Module[]` (caller owns — free with `freeModules`). With no dependencies
/// this returns an empty slice without touching the filesystem.
///
/// Resolution per dep (`manifest.resolveDependency`):
///   * `{ "workspace": true }` — the sibling member of the enclosing workspace.
///   * `{ "path": … }` — `<project>/<path>`, which must hold that package.
///   * `{ "git": … }` — by name across `dependencyTiers` (decision 483), the
///     first tier carrying the name wins: `BOTOPINK_LIB_ROOTS` when set; then
///     `<project>/.botopinkbuild/deps/<name>/` — the link `bpmp install` (into
///     its store) or `bpmp link` (into a local checkout) writes — and, for a
///     workspace member, `<workspace root>/.botopinkbuild/deps/<name>/`; only
///     then the walk-up roots (the enclosing workspace, `repository/…`,
///     `libs/`) as a fallback.
///   * nothing carries the name → `LibNotFound` (named on stderr). No library
///     root at all is not an error: `path` and `workspace` need none.
///
/// `std` is the one bundled package (decision 326): embedded in the compiler,
/// imported with no declaration, and refused in `dependencies`
/// (`BundledDependency`). Every other package — `routing`, `actions`, … — is a
/// library like any other: declared here, resolved like the entries above, and
/// `from "<name>"` without the declaration is decision 242's unresolved import
/// source (the module-tree resolver's refusal).
pub fn loadDependencies(
    gpa: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    env_map: EnvMap,
) ![]Module {
    return loadDependenciesWith(gpa, io, proj, env_map, null);
}

/// The closure keys of a build's dependency packages (decision 509 (3),
/// 144 B-60): computed while the closure is loaded — each package's
/// directory, effective manifest and dependencies are at hand there — for the
/// analysis store (`analysis_store.Cache`). Keyed by import name, owned by
/// `arena`.
pub const ClosureKeys = struct {
    arena: std.mem.Allocator,
    target: code_cache.EntryTarget,
    keys: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8) = .empty,
    /// What the project's `.bpp` files unfold onto (front 116 step 2), when
    /// its manifest names a `"bpp"` package: the roles `checkBppRoles` found,
    /// in `arena`. `sources.load` hands it to the resolver.
    bpp: ?bpp_unfold.Spec = null,
    /// The cache root the build files its entries under
    /// (`analysis_store.root`), when it keeps them: each package's key then
    /// holds the files its last analysis read besides its own — its INPUTS
    /// (decision 519: a `compiler.load` file outside `src`).
    cache_root: ?[]const u8 = null,
    /// Each package's reader log, by import name (`bp.PackageFiles.log`):
    /// what this build's analysis of it reads, for `analysis_store.Cache`
    /// to write as its INPUTS.
    logs: std.StringHashMapUnmanaged(*bp.ReadLog) = .empty,
    /// Every package's `.bpr` key (decision 1006 (3), `code_cache.runtimeKey`),
    /// by import name: target-free, Merkle over its dependencies' — what the
    /// key of the package a command builds hashes for its dependencies
    /// (`runtime_cache.zig`).
    runtime: std.StringHashMapUnmanaged([code_cache.KEY_HEX]u8) = .empty,
    /// Whether to fill `runtime` (`build` and `run` only).
    want_runtime: bool = false,
    /// Only `runtime` (a `compiler.load`ed package's `.bpr` key, decision
    /// 1006 (6) P5): no level B key, no read log, no build-target refusal —
    /// the load resolves the package as it did without keys.
    runtime_only: bool = false,
};

/// `loadDependencies`, filling `keys` (when given) with every package's
/// closure key on `keys.target`.
pub fn loadDependenciesWith(
    gpa: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    env_map: EnvMap,
    keys: ?*ClosureKeys,
) ![]Module {
    return loadDependenciesIn(gpa, io, proj, env_map, keys, proj.srcDir());
}

/// `loadDependenciesWith`, the project's `.bpp` files looked for in
/// `src_dir` (cwd's `proj.srcDir()` for the package a command builds; a
/// loaded package's own, under its directory, `resolveLoaded`).
fn loadDependenciesIn(
    gpa: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
    env_map: EnvMap,
    keys: ?*ClosureKeys,
    src_dir: []const u8,
) ![]Module {
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    // On error, free what was accumulated, then the list backing — in this order
    // (a single block, not two errdefers, which would run LIFO and free the
    // backing before reading `.items`).
    errdefer {
        for (modules.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
            if (m.files) |f| gpa.free(f.root);
        }
        modules.deinit(gpa);
    }

    for (proj.dependencies) |dep| {
        if (bp.comptime_pipeline.bundledPackage(dep.name) == null) continue;
        var buf: [512]u8 = undefined;
        const msg = std.fmt.bufPrint(&buf, "dependency \"{s}\" is bundled with the compiler — `from \"{s}\"` resolves with no `dependencies` entry; remove this one", .{ dep.name, dep.name }) catch "a bundled package is listed in `dependencies`";
        proj.manifest.locateEntryAt("dependencies", dep.name, msg).print();
        return error.BundledDependency;
    }

    // Decision 361 — the `.bpp` files of the project: with no `"bpp"` key the
    // first one is refused at the file; with one, the roles of the package it
    // names are checked once that package is loaded (`loadClosure`).
    var bpp_arena = std.heap.ArenaAllocator.init(gpa);
    defer bpp_arena.deinit();
    const bpp_files = try bpp.scanBppFiles(bpp_arena.allocator(), io, src_dir);
    if (proj.manifest.bpp == null and bpp_files.len > 0) return bpp.refuseUnnamed(bpp_arena.allocator(), bpp_files);
    try bpp.refuseTwins(bpp_arena.allocator(), io, bpp_files);

    if (proj.dependencies.len == 0) return try modules.toOwnedSlice(gpa);

    const roots = try resolveLibRoots(gpa, io, env_map);
    defer freeRoots(gpa, roots);

    // No root at all is not an error here: a `path` or `{ "workspace": true }`
    // dependency needs none, and a `git` one nothing carries is named below.
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const tiers = try dependencyTiers(gpa, arena, io, env_map, proj.dir, roots);

    try loadClosure(gpa, io, arena, proj.manifest, proj.dir, proj.workspace, proj.dependencies, tiers, &modules, bpp_files, keys);
    return try modules.toOwnedSlice(gpa);
}

// ── A loaded package's own dependencies (decision 993 (1)) ──────────────────

/// The environment the CLI's commands run with, for `resolveLoaded`'s tiers.
var load_env: EnvMap = null;

/// Hand compiler-core the resolver of a `compiler.load`ed package's own
/// dependencies (`bp.load.resolver`): every command that compiles calls it
/// once, before its first compile.
pub fn installLoadResolver(env_map: EnvMap) void {
    load_env = env_map;
    bp.load.resolver = .{ .resolve = resolveLoaded, .by_name = resolveByName, .runtime_read = runtimeRead, .runtime_write = runtimeWrite, .check_sources = checkLoadedSources };
}

// ── A by-name load's `.bpr` set (decisions 1006 (6) P5, 1030, 1039) ─────────

/// A package a load resolved (`resolveLoaded`), as its `.bpr` set keys it.
/// The set itself lives under the LOADING build's cache root
/// (`runtime_cache.load_root`), one per load directory and wasm host
/// (`runtime_cache.loadedDir`).
const LoadedSet = struct {
    /// The package's directory, absolute.
    pkg_dir: []const u8,
    meta: runtime_cache.SetMeta,
    /// Its own key (`runtime_cache.keyOf`), before its load directory and the
    /// packages it loads.
    base: runtime_cache.Key,
};

/// By the directory `resolveLoaded` was handed. Under `loaded_mutex`.
var loaded_sets: std.StringHashMapUnmanaged(LoadedSet) = .empty;

/// One name a by-name load resolved this process (`resolveByName`, or a
/// reused set's line): the name, the directory it was looked up from and the
/// package's directory, both absolute. Under `loaded_mutex`.
const Found = struct { name: []const u8, from: []const u8, dir: []const u8 };
var found_names: std.ArrayListUnmanaged(Found) = .empty;

/// Notes `name` found from `from` at `dir` (absolute). Holds `loaded_mutex`.
fn noteFoundLocked(name: []const u8, from: []const u8, dir: []const u8) !void {
    for (found_names.items) |f| {
        if (std.mem.eql(u8, f.name, name) and std.mem.eql(u8, f.from, from) and std.mem.eql(u8, f.dir, dir)) return;
    }
    const a = loaded_arena.allocator();
    try found_names.append(a, .{ .name = try a.dupe(u8, name), .from = try a.dupe(u8, from), .dir = try a.dupe(u8, dir) });
}

fn setOf(io: std.Io, dir: []const u8) ?LoadedSet {
    _ = resolveLoaded(null, io, dir) catch return null;
    while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
    defer loaded_mutex.unlock();
    return loaded_sets.get(dir);
}

fn absolute(arena: std.mem.Allocator, io: std.Io, path: []const u8) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = buf[0..try std.process.currentPath(io, &buf)];
    return std.fs.path.resolve(arena, &.{ cwd, path });
}

/// `to` relative to `from` (both absolute); `.` when they are one.
fn relativeTo(arena: std.mem.Allocator, from: []const u8, to: []const u8) ![]const u8 {
    if (std.mem.eql(u8, from, to)) return ".";
    return std.fs.path.relative(arena, "/", null, from, to);
}

/// The key-file lines (`runtime_cache.loadsOf`) of the directories `loads`
/// (as the loader's reader roots them) for the package in `pkg_dir`: each
/// `<dir>\t<name>\t<from>` per name that resolved to it (`found_names`),
/// both directories relative to the package; a directory no name noted is its
/// relative path alone. In `arena`.
pub fn relativeLoads(arena: std.mem.Allocator, io: std.Io, pkg_dir: []const u8, loads: []const []const u8) ![]const []const u8 {
    const from = try absolute(arena, io, pkg_dir);
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (loads) |l| {
        const abs = try absolute(arena, io, l);
        if (std.mem.eql(u8, abs, from)) continue;
        const rel = try relativeTo(arena, from, abs);
        var any = false;
        {
            while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
            defer loaded_mutex.unlock();
            for (found_names.items) |f| if (std.mem.eql(u8, f.dir, abs)) {
                any = true;
                const line = try std.fmt.allocPrint(arena, "{s}\t{s}\t{s}", .{ rel, f.name, try relativeTo(arena, from, f.from) });
                const seen = for (out.items) |o| {
                    if (std.mem.eql(u8, o, line)) break true;
                } else false;
                if (!seen) try out.append(arena, line);
            };
        }
        if (!any) try out.append(arena, rel);
    }
    return out.items;
}

/// One key-file line, read: its directory, and the name and the directory it
/// was looked up from (null for a line of its directory alone).
const LoadLine = struct { dir: []const u8, name: ?[]const u8 = null, from: []const u8 = "." };

fn parseLoadLine(line: []const u8) LoadLine {
    var parts = std.mem.splitScalar(u8, line, '\t');
    const dir = parts.first();
    const name = parts.next() orelse return .{ .dir = dir };
    return .{ .dir = dir, .name = name, .from = parts.next() orelse "." };
}

/// Where `name` resolves now from `from` (absolute), as a by-name load would
/// find it; null when it resolves to no package.
fn resolvesNow(arena: std.mem.Allocator, io: std.Io, name: []const u8, from: []const u8) !?[]const u8 {
    while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
    defer loaded_mutex.unlock();
    return switch (try resolveByNameIn(arena, io, load_env, name, from)) {
        .found => |f| f.dir,
        else => null,
    };
}

/// `base` (the key of the package in `pkg_dir`) combined with, for each
/// package it loads by name (`loads`, its key-file lines — every package its
/// analysis loaded by name, nested loads included, `bp.load.namedLoadsSince`),
/// the directory its name resolves to NOW (decision 1039 (3)) and that
/// package's own key; null when one of them is no package now.
pub fn keyWithNamedLoads(arena: std.mem.Allocator, io: std.Io, pkg_dir: []const u8, base: runtime_cache.Key, loads: []const []const u8) !?runtime_cache.Key {
    if (loads.len == 0) return base;
    const pkg = try absolute(arena, io, pkg_dir);
    var keys: std.ArrayListUnmanaged(runtime_cache.LoadKey) = .empty;
    for (loads) |line| {
        const l = parseLoadLine(line);
        var abs: []const u8 = try std.fs.path.resolve(arena, &.{ pkg, l.dir });
        var shown = line;
        if (l.name) |name| {
            abs = (try resolvesNow(arena, io, name, try std.fs.path.resolve(arena, &.{ pkg, l.from }))) orelse return null;
            shown = try std.fmt.allocPrint(arena, "{s}\t{s}\t{s}", .{ try relativeTo(arena, pkg, abs), name, l.from });
        }
        const sub = setOf(io, abs) orelse return null;
        try keys.append(arena, .{ .rel = shown, .key = sub.base });
    }
    return try runtime_cache.withLoads(arena, base, keys.items);
}

fn setFor(dir: []const u8) ?LoadedSet {
    while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
    defer loaded_mutex.unlock();
    return loaded_sets.get(dir);
}

/// `Resolver.runtime_read`: the fresh set's program, else null. A hit notes
/// the loads its analysis made (`bp.load.noteNamedLoad`, `found_names`): the
/// loader's key covers them though this compile does not run them again.
fn runtimeRead(_: ?*anyopaque, io: std.Io, arena: std.mem.Allocator, dir: []const u8, root: []const u8, wasm_host: bp.ast.WasmHost) anyerror!?[]const bp.codegen.ComptimeOutput {
    if (runtime_cache.rebuild) return null;
    const load_root = runtime_cache.load_root orelse return null;
    const set = setFor(dir) orelse return null;
    const set_dir = try runtime_cache.loadedDir(arena, load_root, set.meta.root, runtime_cache.loadedPlace(root, wasm_host));
    const loads = runtime_cache.loadsOf(arena, io, set_dir, set.meta.root);
    const key = (try keyWithNamedLoads(arena, io, set.pkg_dir, runtime_cache.loadedIdent(set.base, root, wasm_host), loads)) orelse return null;
    if (!runtime_cache.isFresh(arena, io, set_dir, set.meta.root, key, runtime_cache.bprStamp())) return null;
    const program = (try runtime_cache.readProgram(arena, io, set_dir, set.meta.root)) orelse return null;
    const pkg = try absolute(arena, io, set.pkg_dir);
    for (loads) |line| {
        const l = parseLoadLine(line);
        const abs = try std.fs.path.resolve(arena, &.{ pkg, l.dir });
        if (l.name) |name| {
            while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
            defer loaded_mutex.unlock();
            try noteFoundLocked(name, try std.fs.path.resolve(arena, &.{ pkg, l.from }), abs);
        }
        try bp.load.noteNamedLoad(abs);
    }
    return program;
}

/// `Resolver.runtime_write`: the set written from the load's analysis, in
/// place of the one before (decision 1039 (2)).
fn runtimeWrite(_: ?*anyopaque, io: std.Io, dir: []const u8, root: []const u8, wasm_host: bp.ast.WasmHost, outputs: []const bp.codegen.ComptimeOutput, readers: []const []const u8, loads: []const []const u8) anyerror!void {
    const load_root = runtime_cache.load_root orelse return;
    const set = setFor(dir) orelse return;
    var arena_inst = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const set_dir = try runtime_cache.loadedDir(arena, load_root, set.meta.root, runtime_cache.loadedPlace(root, wasm_host));
    const rel = try relativeLoads(arena, io, set.pkg_dir, loads);
    const key = try keyWithNamedLoads(arena, io, set.pkg_dir, runtime_cache.loadedIdent(set.base, root, wasm_host), rel);
    var meta = set.meta;
    meta.wasm_host = wasm_host;
    var written: std.ArrayListUnmanaged(runtime_cache.Written) = .empty;
    try runtime_cache.writeSet(std.heap.page_allocator, io, set_dir, meta, key, rel, outputs, readers, &written, arena);
    runtime_cache.pruneSet(arena, io, set_dir, written.items);
}

/// Decision 993 (2) — the directory of the package `name`, looked up as a
/// `git` dependency of the package at `from` is (`manifest.resolveDependency`'s
/// last branch): decision 483's tiers — `BOTOPINK_LIB_ROOTS`, the links under
/// `from`'s `.botopinkbuild/deps/`, the walk-up roots — the first tier carrying
/// the name; a name two libraries declare, a workspace's name and a manifest
/// that does not parse are refused with the text `botopink build` prints for a
/// dependency of that name. What it answers lives as long as the process.
fn resolveByName(_: ?*anyopaque, io: std.Io, name: []const u8, from: []const u8) anyerror!bp.load.NameResolution {
    while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
    defer loaded_mutex.unlock();
    const a = loaded_arena.allocator();
    const r = try resolveByNameIn(a, io, load_env, name, from);
    // What a set's key file names (`relativeLoads`, decision 1039 (3)).
    if (r == .found) try noteFoundLocked(name, try absolute(a, io, from), r.found.dir);
    return r;
}

fn resolveByNameIn(a: std.mem.Allocator, io: std.Io, env_map: EnvMap, name: []const u8, from: []const u8) anyerror!bp.load.NameResolution {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = buf[0..try std.process.currentPath(io, &buf)];
    const abs_from = try std.fs.path.resolve(a, &.{ cwd, from });
    const roots = try resolveLibRoots(a, io, env_map);
    const tiers = try dependencyTiers(a, a, io, env_map, abs_from, roots);
    const found = for (tiers) |tier| {
        if (manifest.find(tier, name)) |e| break e;
    } else return .unknown;
    if (found.problem) |pr| return .{ .refused = try a.dupe(u8, pr.message) };
    if (found.is_workspace) {
        const list = if (found.workspace) |ws| try ws.memberList(a) else "none";
        return .{ .refused = try std.fmt.allocPrint(a, "\"{s}\" is a workspace, not a package — load one of its members: {s}", .{ name, list }) };
    }
    const dir = try std.fs.path.resolve(a, &.{ cwd, found.dir });
    const under = try std.fmt.allocPrint(a, "{s}{c}", .{ abs_from, std.fs.path.sep });
    const rel: ?[]const u8 = if (std.mem.startsWith(u8, dir, under)) dir[under.len..] else null;
    // Decisions 1030 (3), 1006 P4 — outside the loader, the load is named by
    // its directory relative to the loading build's cache root, never by its
    // absolute path: the package's name, its group file in the `.bpr` set and
    // `Module.path` carry no machine's path, so a set built in one checkout
    // runs in another (CI's artifact). Its `root` stays the absolute
    // directory (1003 (2)), read only by a program that asks for it.
    const shown: ?[]const u8 = if (rel == null) if (runtime_cache.load_root) |lr|
        try relativeTo(a, try std.fs.path.resolve(a, &.{ cwd, lr }), dir)
    else
        null else null;
    return .{ .found = .{ .dir = dir, .rel = rel, .shown = shown } };
}

/// One resolution per package directory per process (decision 993 (1)): a
/// package two loads reach is resolved once, its modules shared.
var loaded_mutex: std.atomic.Mutex = .unlocked;
var loaded_arena: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var loaded_cache: std.StringHashMapUnmanaged(bp.load.Resolution) = .empty;

/// Decision 993 (1) — the dependencies of the package whose `botopink.json`
/// is in `dir`, as `botopink build` there resolves them: its manifest read
/// with its workspace's (512), `path` from its directory, `{ "workspace": true }`
/// from its workspace's root, `git` through 483's tiers; and the targets it
/// holds when it writes none (75, 770). What `botopink build` there would
/// print as a refusal is answered as the package's own (`refused`), never
/// printed: a nested compile is captured (780 (5)). Lives as long as the process.
fn resolveLoaded(_: ?*anyopaque, io: std.Io, dir: []const u8) anyerror!bp.load.Resolution {
    while (!loaded_mutex.tryLock()) std.atomic.spinLoopHint();
    defer loaded_mutex.unlock();
    const a = loaded_arena.allocator();
    if (loaded_cache.get(dir)) |r| return r;
    const key = try a.dupe(u8, dir);
    const r = try resolveLoadedUncached(a, io, key);
    try loaded_cache.put(a, key, r);
    return r;
}

fn resolveLoadedUncached(a: std.mem.Allocator, io: std.Io, dir: []const u8) !bp.load.Resolution {
    // What a refusal prints, read back instead of printed.
    var captured: std.Io.Writer.Allocating = .init(a);
    const saved_sink = reporter.sink;
    const saved_manifest_sink = manifest.sink;
    reporter.sink = &captured.writer;
    manifest.sink = &captured.writer;
    defer {
        reporter.sink = saved_sink;
        manifest.sink = saved_manifest_sink;
    }
    const refused = struct {
        fn of(arena: std.mem.Allocator, text: []const u8, err: anyerror) !bp.load.Resolution {
            return .{ .refused = try refusalOf(arena, text, err) };
        }
    };
    const proj = config.loadAt(a, io, dir) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return refused.of(a, captured.written(), err),
    };
    // The modules live as long as the process (never freed), so they may join
    // the program a `run()` compiles. The `.bpr` keys of its closure are
    // computed on the way (decision 1006 (6) P5).
    var keys_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer keys_arena.deinit();
    var keys: ClosureKeys = .{ .arena = keys_arena.allocator(), .target = .{ .target = .commonJS }, .want_runtime = true, .runtime_only = true };
    // Decision 1061 (2) — the walk of the closure (the library roots, every
    // manifest under them, the tiers) is scratch: on an allocator that frees,
    // not on `a`, where each loaded package with a dependency kept a scan of
    // the checkout (~150 MB a package in the meta checkout). Only the modules
    // it answers stay.
    const modules = loadDependenciesIn(std.heap.smp_allocator, io, proj, load_env, &keys, try std.fs.path.join(a, &.{ proj.dir, proj.srcDir() })) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return refused.of(a, captured.written(), err),
    };
    // The package's own key, as a bare `build` in its directory keys it —
    // `out/` is its default output, left out anyway; a load's set adds its
    // load directory (decision 1030 (2)).
    const base = try runtime_cache.keyOf(keys_arena.allocator(), io, proj, &keys, &.{});
    const pk = try packagesOf(a, proj, modules);
    try loaded_sets.put(a, dir, .{
        .pkg_dir = proj.dir,
        .meta = .{ .root = proj.name, .deps = pk.deps, .wasm_host = proj.wasmHost() },
        .base = base,
    });
    var targets: ?[]const []const u8 = null;
    if (proj.manifest.targets == null or proj.manifest.targets_inherited) {
        // The closure walked again: scratch too, the names copied out.
        var held_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
        defer held_arena.deinit();
        const ha = held_arena.allocator();
        const held = heldTargets(ha, io, ha, proj, load_env) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => return refused.of(a, captured.written(), err),
        };
        // Every target held is no narrowing: the package declares none.
        if (held.len < ALL_TARGET_NAMES.len) {
            const kept = try a.alloc([]const u8, held.len);
            for (held, kept) |t, *k| k.* = try a.dupe(u8, t);
            targets = kept;
        }
    }
    return .{ .ok = .{ .modules = modules, .targets = targets } };
}

/// `bp.load.Resolver.check_sources` (decisions 242, 989 (4), 1050): the
/// import-source rule of the package's own build (`resolver.checkSources`)
/// over the loaded package's own modules, against the dependencies its
/// manifest in `dir` declares; the refusal as `check` prints it.
fn checkLoadedSources(_: ?*anyopaque, io: std.Io, arena: std.mem.Allocator, dir: []const u8, mods: []const Module) anyerror!?bp.load.SourceRefusal {
    const proj = config.loadAt(arena, io, dir) catch return null;
    const declared = try proj.dependencyNames(arena);
    const files = try arena.alloc([]const u8, mods.len);
    for (mods, files) |m, *f| f.* = m.srcPath;
    var diag: resolver.Diagnostic = .{ .kind = resolver.Error.RootNotFound };
    resolver.checkSources(arena, mods, files, declared, proj.name, arena, &diag) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            if (diag.kind != resolver.Error.UnresolvedImportSource and diag.kind != resolver.Error.ModuleImportWithFrom) return null;
            return .{
                .message = try resolver.importSourceMessage(arena, diag),
                .file = diag.file,
                .line = diag.line,
                .column = diag.col,
            };
        },
    };
    return null;
}

/// The first `error…: <message>` line of `text` (its `[code]` moved to the message's head) (a refusal as the CLI prints
/// it, colours stripped) and the `--> <file>:<line>:<col>` under it when it
/// points at `botopink.json`; the error's name when nothing was printed.
fn refusalOf(a: std.mem.Allocator, text: []const u8, err: anyerror) !bp.load.Resolution.Refusal {
    const plain = try stripAnsi(a, text);
    var lines = std.mem.splitScalar(u8, plain, '\n');
    var out: bp.load.Resolution.Refusal = .{ .message = "" };
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \r");
        if (out.message.len == 0) {
            if (std.mem.startsWith(u8, line, "error")) {
                const colon = std.mem.indexOf(u8, line, ": ") orelse continue;
                out.message = line[colon + 2 ..];
                // `error[<code>]: …`: the code leads the message (`<code>: …`), as `load.codeOf` reads it back.
                if (std.mem.startsWith(u8, line, "error[") and colon > "error[]".len - 1)
                    out.message = try std.fmt.allocPrint(a, "{s}: {s}", .{ line["error[".len .. colon - 1], line[colon + 2 ..] });
            }
            continue;
        }
        if (std.mem.startsWith(u8, line, "--> ")) {
            const place = line["--> ".len..];
            const c2 = std.mem.lastIndexOfScalar(u8, place, ':') orelse break;
            const c1 = std.mem.lastIndexOfScalar(u8, place[0..c2], ':') orelse break;
            if (std.mem.eql(u8, std.fs.path.basename(place[0..c1]), manifest.FILENAME)) {
                out.line = std.fmt.parseInt(usize, place[c1 + 1 .. c2], 10) catch 0;
                out.column = std.fmt.parseInt(usize, place[c2 + 1 ..], 10) catch 0;
            }
        }
        break;
    }
    if (out.message.len == 0) out.message = try std.fmt.allocPrint(a, "the package's dependencies could not be resolved ({s})", .{@errorName(err)});
    return out;
}

fn stripAnsi(a: std.mem.Allocator, text: []const u8) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    while (i < text.len) {
        if (text[i] == 0x1b and i + 1 < text.len and text[i + 1] == '[') {
            i += 2;
            while (i < text.len and !std.ascii.isAlphabetic(text[i])) i += 1;
            i += 1;
            continue;
        }
        try out.append(a, text[i]);
        i += 1;
    }
    return out.items;
}

/// Decision 770 — the targets the project holds: its own `"targets"` when
/// it writes them, else the intersection of its dependencies' (and of its
/// workspace's, when it inherits them); every target when nothing narrows
/// it. Resolves the closure as a build does and refuses as it refuses
/// (`LibManifestInvalid`, …), printing nothing else. Owned by `arena`.
pub fn heldTargets(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    proj: config.ProjectConfig,
    env_map: EnvMap,
) ![]const []const u8 {
    var closure: DepClosure = .{ .arena = arena, .io = io, .tiers = &.{} };
    if (proj.dependencies.len > 0) {
        const roots = try resolveLibRoots(gpa, io, env_map);
        defer freeRoots(gpa, roots);
        closure.tiers = try dependencyTiers(gpa, arena, io, env_map, proj.dir, roots);
        for (proj.dependencies) |dep| _ = try closure.resolve(proj.manifest, proj.dir, dep);
        for (proj.dependencies) |dep| try closure.visit(proj.manifest, dep.name);
        try closure.orderByLevel();
        try closure.computeHeld();
        try closure.refuseMissingTargets(proj.manifest, proj.dependencies);
    }
    return closure.heldBy(proj.manifest);
}

/// One package of a project's closure: its import name and its directory,
/// absolute and link-free (`linkFreeDir`).
pub const NamedDir = struct { name: []const u8, dir: []const u8 };

/// The packages of the project's dependency closure (std, the bundled
/// package, is none of them), each once, resolved as a build resolves them —
/// what a workspace's one output folder holds besides its members
/// (decision 1015 (4), `workspace_out.refuseShared`). Refuses as the closure
/// refuses, printing its located diagnostic. Owned by `arena`.
pub fn closurePackages(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    proj: config.ProjectConfig,
    env_map: EnvMap,
) ![]const NamedDir {
    if (proj.dependencies.len == 0) return &.{};
    var closure: DepClosure = .{ .arena = arena, .io = io, .tiers = &.{} };
    const roots = try resolveLibRoots(gpa, io, env_map);
    defer freeRoots(gpa, roots);
    closure.tiers = try dependencyTiers(gpa, arena, io, env_map, proj.dir, roots);
    for (proj.dependencies) |dep| _ = try closure.resolve(proj.manifest, proj.dir, dep);
    for (proj.dependencies) |dep| try closure.visit(proj.manifest, dep.name);
    const out = try arena.alloc(NamedDir, closure.order.items.len);
    for (closure.order.items, out) |pkg, *o| o.* = .{ .name = pkg.name, .dir = try linkFreeDir(arena, io, pkg.dir) };
    return out;
}

/// Load, into `out`, the modules of every package of `DepClosure` for the
/// project at `project_dir` whose manifest is `project` — dependencies before
/// dependents.
fn loadClosure(
    gpa: std.mem.Allocator,
    io: std.Io,
    arena: std.mem.Allocator,
    project: manifest.Manifest,
    project_dir: []const u8,
    /// The workspace the project is a member of, when it is one: its members
    /// and the closure's packages share one name space (`refuseNameTwice`).
    workspace: ?manifest.Workspace,
    deps: []const manifest.DepEntry,
    /// `dependencyTiers` — every package of the closure looks its `git`
    /// dependencies up in the project's tiers (one `.botopinkbuild/deps/`, as
    /// one `node_modules`).
    tiers: []const []const manifest.Entry,
    out: *std.ArrayListUnmanaged(Module),
    /// The project's `.bpp` files (decision 361), checked against the roles
    /// of the package `project.bpp` names.
    bpp_files: []const bpp.BppFile,
    /// Filled with every package's closure key when given (144 B-60).
    keys: ?*ClosureKeys,
) !void {
    var closure: DepClosure = .{ .arena = arena, .io = io, .tiers = tiers };
    // The project's own entries are resolved first, so the directory each of
    // its names means is the project's — a dependency that means another
    // directory by one of them is refused, not silently shadowed.
    for (deps) |dep| _ = try closure.resolve(project, project_dir, dep);
    for (deps) |dep| try closure.visit(project, dep.name);
    try closure.orderByLevel();
    try closure.computeHeld();
    try closure.refuseMissingTargets(project, deps);
    if (keys) |k| if (!k.runtime_only) try closure.refuseBuildTarget(project, deps, k.target.target.toString());
    try refuseNameTwice(arena, io, project, project_dir, workspace, closure.order.items);
    // One OTP release across the closure (decision 228): every package that
    // pins `"otp"` pins the project's — or the first pin's — release.
    var pinned: std.ArrayListUnmanaged(manifest.Manifest) = .empty;
    try pinned.append(arena, project);
    for (closure.order.items) |pkg| try pinned.append(arena, pkg.manifest);
    var otp_err: ?manifest.Located = null;
    _ = manifest.closureOtp(arena, pinned.items, &otp_err) catch |e| switch (e) {
        error.Invalid => {
            otp_err.?.print();
            return error.LibManifestInvalid;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    for (closure.order.items) |pkg| {
        const log: ?*bp.ReadLog = if (keys) |k| if (k.runtime_only) null else blk: {
            const l = try k.arena.create(bp.ReadLog);
            l.* = .{ .arena = k.arena };
            try k.logs.put(k.arena, try k.arena.dupe(u8, pkg.name), l);
            break :blk l;
        } else null;
        try loadOneLogged(gpa, io, pkg.dir, pkg.manifest, pkg.name, out, log);
    }
    if (project.bpp) |name| {
        const pkg = closure.packages.get(name).?;
        const roles = try checkBppRoles(arena, io, project, pkg, out.items, bpp_files);
        if (keys) |k| k.bpp = try bpp.unfoldSpec(k.arena, name, pkg.manifest.entry orelse "root.bp", roles);
    }
    // Dependencies come before dependents in `order`, so each package's
    // dependencies have their keys when its own is computed (Merkle). std is
    // no package of the closure: its bytes are inside the compiler key.
    if (keys) |k| for (closure.order.items) |pkg| {
        if (!k.runtime_only) {
            var dep_keys: std.ArrayListUnmanaged(code_cache.DepKey) = .empty;
            for (pkg.manifest.dependencies) |d| if (k.keys.get(d.name)) |dk| try dep_keys.append(arena, .{ .name = d.name, .key = dk });
            const inputs = if (k.cache_root) |r| try analysis_store.readInputs(arena, io, r, k.target, pkg.name) else &.{};
            const key = try code_cache.closureKeyReading(arena, io, pkg.dir, pkg.manifest, dep_keys.items, k.target, code_cache.compilerKey(k.target.target), inputs);
            try k.keys.put(k.arena, try k.arena.dupe(u8, pkg.name), key);
        }
        if (!k.want_runtime) continue;
        var rt_deps: std.ArrayListUnmanaged(code_cache.DepKey) = .empty;
        for (pkg.manifest.dependencies) |d| if (k.runtime.get(d.name)) |dk| try rt_deps.append(arena, .{ .name = d.name, .key = dk });
        try k.runtime.put(k.arena, try k.arena.dupe(u8, pkg.name), try code_cache.runtimeKey(arena, io, pkg.dir, pkg.manifest, rt_deps.items, &.{}));
    };
}

/// 144 B-60 — one package name is one directory in the workspace's closure:
/// a dependency of the build named like the project, or like a member of the
/// project's workspace, at another directory is refused, located on the
/// `dependencies` entry that brought it in, naming both directories. The
/// code cache files a dependency's analysis by its name
/// (`<cache root>/.botopinkbuild/analysis/<target>/<name>.bpa`, the
/// workspace's root shared by its members): two packages of one name would
/// replace each other's entry, one build after the other. A refusal, never a
/// silent replacement.
fn refuseNameTwice(
    arena: std.mem.Allocator,
    io: std.Io,
    project: manifest.Manifest,
    project_dir: []const u8,
    workspace: ?manifest.Workspace,
    packages: []const DepClosure.Package,
) !void {
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    const own_dir = try linkFreeDir(arena, io, try std.fs.path.resolve(arena, &.{ cwd, project_dir }));
    for (packages) |pkg| {
        const other: []const u8 = blk: {
            if (std.mem.eql(u8, pkg.name, project.name)) break :blk own_dir;
            const ws = workspace orelse continue;
            const member = ws.member(pkg.name) orelse continue;
            break :blk try linkFreeDir(arena, io, try std.fs.path.resolve(arena, &.{ cwd, member.dir }));
        };
        const dir = try std.fs.path.resolve(arena, &.{ cwd, pkg.dir });
        if (std.mem.eql(u8, other, dir)) continue;
        const msg = try std.fmt.allocPrint(arena, "two packages named \"{s}\" in this workspace's build — {s} here and {s} — one name is one package", .{
            pkg.name,
            try displayDir(arena, cwd, dir),
            try displayDir(arena, cwd, other),
        });
        pkg.by.locateEntryAt("dependencies", pkg.name, msg).print();
        return error.LibManifestInvalid;
    }
}

/// `dir` relative to `cwd` (`.` for `cwd` itself), the way a refusal names
/// a directory.
fn displayDir(arena: std.mem.Allocator, cwd: []const u8, dir: []const u8) ![]const u8 {
    const rel = try std.fs.path.relative(arena, cwd, null, cwd, dir);
    return if (rel.len == 0) "." else rel;
}

/// Decision 361 — the roles std's `bpp` annotations mark in the package the
/// project's `"bpp"` names (`bpp.checkPackage`), and the project's `.bpp`
/// files against them (`bpp.checkStyleSections`). `pkg` is the closure's
/// entry for that name: `"bpp"` is refused unless it names a dependency
/// (`manifest.parse`), and every dependency is in the closure.
fn checkBppRoles(
    arena: std.mem.Allocator,
    io: std.Io,
    project: manifest.Manifest,
    pkg: DepClosure.Package,
    loaded: []const Module,
    bpp_files: []const bpp.BppFile,
) !bpp.Roles {
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    var mods: std.ArrayListUnmanaged(bpp.PackageModule) = .empty;
    for (pkg.manifest.files) |file| {
        const path = try std.fmt.allocPrint(arena, "{s}/{s}", .{ pkg.name, stripSourceExt(file) });
        const mod = for (loaded) |m| {
            if (std.mem.eql(u8, m.path, path)) break m;
        } else continue;
        const on_disk = try std.fs.path.join(arena, &.{ pkg.dir, pkg.manifest.src, file });
        try mods.append(arena, .{ .module = mod, .file = try std.fs.path.relative(arena, cwd, null, cwd, on_disk) });
    }
    const roles = try bpp.checkPackage(arena, project, pkg.name, mods.items);
    try bpp.checkStyleSections(arena, pkg.name, roles, bpp_files);
    return roles;
}

/// The packages a build compiles: every dependency the project declares, every
/// dependency THOSE declare, and so on — each once, by import name, placed after
/// every package it depends on.
///
/// A dependency is compiled as the `<name>/<stem>` modules of one flat list, in
/// list order, so a package whose modules import another package has to come
/// after it, and it has to be there at all. `loadDependencies` used to load only
/// the project's own entries, in the order the manifest lists them: a package
/// outside the jhonstart workspace that depends on `jhonstart-forms` compiled
/// `jhonstart-forms/form` with `from "jhonstart"` and `from "jhonstart-link"`
/// unbound — neither was loaded, and listing both after it still failed, on the
/// order (decision 143). Each dependency's own entries resolve from ITS manifest
/// and directory (`{ "workspace": true }` from its workspace, `path` from its
/// directory, `git` across the roots), exactly as when it builds itself.
///
/// Refused, located on the entry that brought it in: an import name two
/// packages of the build resolve to two directories (one `<name>/` prefix
/// cannot hold both), and a cycle between packages (neither can come first).
/// `std`, the one bundled package (decision 326), is skipped — it is embedded,
/// and a dependency's own build is the one that refuses listing it.
const ALL_TARGET_NAMES = [_][]const u8{ "commonJS", "erlang", "beam", "wasm" };

const DepClosure = struct {
    arena: std.mem.Allocator,
    io: std.Io,
    tiers: []const []const manifest.Entry,
    /// Every package resolved so far, by import name.
    packages: std.StringArrayHashMapUnmanaged(Package) = .empty,
    /// Dependencies before dependents; level by level once `orderByLevel`
    /// ran (decision 660).
    order: std.ArrayListUnmanaged(Package) = .empty,
    /// The targets each package holds, by import name (`computeHeld`,
    /// decision 770).
    held: std.StringHashMapUnmanaged([]const []const u8) = .empty,

    const Package = struct {
        name: []const u8,
        dir: []const u8,
        manifest: manifest.Manifest,
        state: enum { resolved, visiting, placed } = .resolved,
        /// The manifest that first named it, for the located refusals.
        by: manifest.Manifest,
    };

    /// Resolve `dep`, an entry of the package at `dir` whose manifest is `by`.
    /// False for `std`, the bundled package, which is not a package of the closure.
    fn resolve(self: *DepClosure, by: manifest.Manifest, dir: []const u8, dep: manifest.DepEntry) !bool {
        if (bp.comptime_pipeline.bundledPackage(dep.name) != null) return false;
        const abs_dir = try std.fs.path.resolve(self.arena, &.{dir});
        var err: ?manifest.Located = null;
        const resolved = manifest.resolveDependency(self.arena, self.io, by, abs_dir, dep, self.tiers, &err) catch |e| switch (e) {
            error.Invalid => {
                // Located as a dependency's source refusal is (`loadOne`):
                // relative to the working directory, `deps/p/botopink.json`,
                // never the absolute directory the closure resolved.
                var loc = err.?;
                var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
                const cwd = cwd_buf[0..try std.process.currentPath(self.io, &cwd_buf)];
                if (std.fs.path.isAbsolute(loc.file) and std.mem.startsWith(u8, loc.file, cwd))
                    loc.file = try std.fs.path.relative(self.arena, cwd, null, cwd, loc.file);
                loc.print();
                return error.LibManifestInvalid;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        const r = resolved orelse {
            // Name the dependency here — the caller only sees the error tag.
            reporter.print("\x1b[1m\x1b[31merror\x1b[0m: dependency '{s}' was not found under any library root\n", .{dep.name});
            return error.LibNotFound;
        };
        const r_dir = try linkFreeDir(self.arena, self.io, r.dir);
        if (self.packages.get(dep.name)) |known| {
            if (std.mem.eql(u8, known.dir, r_dir)) return true;
            const msg = try std.fmt.allocPrint(self.arena, "\"{s}\" resolves to {s} here, but to {s} for {s} — one import name is one package in a build", .{ dep.name, r_dir, known.dir, known.by.path });
            by.locateEntryAt("dependencies", dep.name, msg).print();
            return error.LibManifestInvalid;
        }
        try self.packages.put(self.arena, dep.name, .{ .name = dep.name, .dir = r_dir, .manifest = r.manifest, .by = by });
        return true;
    }

    /// Place `name` after every package it depends on (depth first); `from` is
    /// the manifest whose `dependencies` entry reached it.
    fn visit(self: *DepClosure, from: manifest.Manifest, name: []const u8) !void {
        const pkg = self.packages.getPtr(name) orelse return;
        switch (pkg.state) {
            .placed => return,
            .visiting => {
                const msg = try std.fmt.allocPrint(self.arena, "\"{s}\" depends on itself through its dependencies — packages cannot form a cycle", .{name});
                from.locateEntryAt("dependencies", name, msg).print();
                return error.LibManifestInvalid;
            },
            .resolved => {},
        }
        pkg.state = .visiting;
        const m = pkg.manifest;
        const dir = pkg.dir;
        for (m.dependencies) |dep| {
            if (try self.resolve(m, dir, dep)) try self.visit(m, dep.name);
        }
        // `resolve` may have grown the map: take the pointer again.
        const done = self.packages.getPtr(name).?;
        done.state = .placed;
        try self.order.append(self.arena, done.*);
    }

    /// Decision 770 — the targets each package of the closure holds: the
    /// `"targets"` it writes, else the intersection of its dependencies'
    /// (and of its workspace's, when it is a member that inherits them);
    /// every target when nothing narrows it. `order` is dependencies first,
    /// so each dependency's set is known when its dependant's is computed.
    fn computeHeld(self: *DepClosure) !void {
        for (self.order.items) |pkg| try self.held.put(self.arena, pkg.name, try self.heldBy(pkg.manifest));
    }

    /// The targets the package whose manifest is `m` holds (decision 770),
    /// once its dependencies' are in `held`.
    fn heldBy(self: *DepClosure, m: manifest.Manifest) ![]const []const u8 {
        if (m.declaresTargets()) return m.targets.?;
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        for (m.targets orelse &ALL_TARGET_NAMES) |t| {
            const every = for (m.dependencies) |d| {
                const dep_held = self.held.get(d.name) orelse continue;
                if (!holds(dep_held, t)) break false;
            } else true;
            if (every) try out.append(self.arena, t);
        }
        return out.items;
    }

    fn holds(list: []const []const u8, t: []const u8) bool {
        for (list) |x| if (std.mem.eql(u8, x, t)) return true;
        return false;
    }

    /// Decision 676, as 770 reads it — a package that writes its own
    /// `"targets"` holds them only when each declared dependency holds every
    /// one of them, whatever target this build is for: the project's
    /// dependencies against the project's targets, and each package's own
    /// against its own, so the whole graph builds for every target of the
    /// root. A package that writes none takes its dependencies' (770) and is
    /// never refused here. Refused at the dependant's manifest, on the
    /// dependency's line, naming the package and each missing target.
    fn refuseMissingTargets(self: *DepClosure, project: manifest.Manifest, deps: []const manifest.DepEntry) !void {
        try self.checkTargets(project, deps);
        for (self.order.items) |pkg| try self.checkTargets(pkg.manifest, pkg.manifest.dependencies);
    }

    fn checkTargets(self: *DepClosure, by: manifest.Manifest, deps: []const manifest.DepEntry) !void {
        if (!by.declaresTargets()) return;
        for (deps) |dep| {
            const dep_held = self.held.get(dep.name) orelse continue;
            var missing: std.ArrayListUnmanaged(u8) = .empty;
            var count: usize = 0;
            for (by.targets.?) |t| {
                if (holds(dep_held, t)) continue;
                if (count > 0) try missing.appendSlice(self.arena, ", ");
                try missing.appendSlice(self.arena, t);
                count += 1;
            }
            if (count == 0) continue;
            const verb = if (self.packages.get(dep.name).?.manifest.declaresTargets()) "declares" else "holds";
            const msg = try std.fmt.allocPrint(self.arena, "{s} {s} no {s} target{s} — a dependency's \"targets\" hold every target of the package that declares it", .{ dep.name, verb, missing.items, if (count > 1) "s" else "" });
            return self.refuseAt(by, dep.name, msg);
        }
    }

    /// Decisions 676, 770 — a dependency is never compiled for a target it
    /// does not hold: a project built for such a target (one it writes no
    /// `"targets"` for and so holds only as its dependencies do, or one its
    /// own `"targets"` leave out) is refused on that dependency's line.
    fn refuseBuildTarget(self: *DepClosure, project: manifest.Manifest, deps: []const manifest.DepEntry, target: []const u8) !void {
        for (deps) |dep| {
            const dep_held = self.held.get(dep.name) orelse continue;
            if (holds(dep_held, target)) continue;
            const msg = try std.fmt.allocPrint(self.arena, "{s} holds no {s} target — a package that writes no \"targets\" holds its dependencies' (decision 770)", .{ dep.name, target });
            return self.refuseAt(project, dep.name, msg);
        }
    }

    fn refuseAt(self: *DepClosure, by: manifest.Manifest, dep_name: []const u8, msg: []const u8) !void {
        var loc = by.locateEntryAt("dependencies", dep_name, msg);
        loc.code = "dependency-target-missing";
        // Located relative to the working directory, as `resolve` locates.
        var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
        const cwd = cwd_buf[0..try std.process.currentPath(self.io, &cwd_buf)];
        if (std.fs.path.isAbsolute(loc.file) and std.mem.startsWith(u8, loc.file, cwd))
            loc.file = try std.fs.path.relative(self.arena, cwd, null, cwd, loc.file);
        loc.print();
        return error.LibManifestInvalid;
    }

    /// Decision 660 — the order of the program's init list, which is the
    /// order the packages compile in: a package that depends on nothing
    /// first, a package after every package it depends on, the ones with the
    /// most levels of dependencies last. A package's level is 0 with no
    /// dependency of the closure, else one more than its deepest
    /// dependency's. Packages of one level keep the depth-first order
    /// `visit` placed them in, which is the order their dependant's
    /// `botopink.json` lists them.
    fn orderByLevel(self: *DepClosure) !void {
        const items = self.order.items;
        const levels = try self.arena.alloc(usize, items.len);
        // `order` is dependencies first, so each dependency's level is known
        // when its dependant's is computed.
        for (items, 0..) |pkg, i| {
            var level: usize = 0;
            for (pkg.manifest.dependencies) |d| {
                for (items[0..i], 0..) |dep, j| {
                    if (std.mem.eql(u8, dep.name, d.name)) level = @max(level, levels[j] + 1);
                }
            }
            levels[i] = level;
        }
        const Keyed = struct { level: usize, pkg: Package };
        const keyed = try self.arena.alloc(Keyed, items.len);
        for (items, levels, keyed) |pkg, level, *k| k.* = .{ .level = level, .pkg = pkg };
        std.sort.insertion(Keyed, keyed, {}, struct {
            fn lt(_: void, a: Keyed, b: Keyed) bool {
                return a.level < b.level;
            }
        }.lt);
        for (keyed, items) |k, *slot| slot.* = k.pkg;
    }
};

/// `dir`, lexically resolved — or, when `dir` itself is a symbolic link, the
/// directory it points at. `bpmp install` links `.botopinkbuild/deps/<name>`
/// into its store, and a git dependency with a `"subdir"` (decision 344) is a
/// link to a package inside a checkout: its `path` dependencies (`../core`) and
/// its enclosing workspace are the checkout's, which only the link's target
/// reaches — resolved lexically from the link they would name
/// `.botopinkbuild/deps/core`.
fn linkFreeDir(arena: std.mem.Allocator, io: std.Io, dir: []const u8) ![]const u8 {
    const lexical = try std.fs.path.resolve(arena, &.{dir});
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    _ = std.Io.Dir.cwd().readLink(io, lexical, &buf) catch return lexical;
    return std.Io.Dir.cwd().realPathFileAlloc(io, lexical, arena) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => lexical,
    };
}

/// The tiers a `git` dependency of the project at `project_dir` (absolute) is
/// looked up in, in order (decision 483) — each one `manifest.scanRoots`, so a
/// name two tiers carry is the earlier tier's, never "declared by two
/// libraries":
///
///   1. `BOTOPINK_LIB_ROOTS` (when set) — bpmp's package store, first;
///   2. `manifest.depsRoots(project_dir)`, one tier each: the project's
///      `.botopinkbuild/deps/`, then — for a workspace member — its workspace
///      root's. Each child is a link: into the `bpmp install` store, or into a
///      local checkout's `repository/<name>` (`bpmp link`). A link wins over
///      the walk-up;
///   3. `roots` (`resolveLibRoots`: the env roots again, then the walk-up to
///      the enclosing checkout) — the fallback, scanned whole as it always
///      was, so its own duplicate-member refusals stand.
///
/// Owned by `arena`.
pub fn dependencyTiers(
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    io: std.Io,
    env_map: EnvMap,
    project_dir: []const u8,
    roots: []const []const u8,
) ![]const []const manifest.Entry {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = buf[0..try std.process.currentPath(io, &buf)];
    const env_roots = try parseEnvRoots(gpa, env_map, cwd);
    defer freeRoots(gpa, env_roots);
    return tiersFrom(arena, io, env_roots, project_dir, roots);
}

/// `dependencyTiers` minus the environment — the roots given, for a test.
fn tiersFrom(
    arena: std.mem.Allocator,
    io: std.Io,
    env_roots: []const []const u8,
    project_dir: []const u8,
    roots: []const []const u8,
) ![]const []const manifest.Entry {
    var tiers: std.ArrayListUnmanaged([]const manifest.Entry) = .empty;
    if (env_roots.len > 0) try tiers.append(arena, try manifest.scanRoots(arena, io, env_roots));
    const abs_project = try std.fs.path.resolve(arena, &.{project_dir});
    for (try manifest.depsRoots(arena, io, abs_project)) |d| try tiers.append(arena, try manifest.scanRoots(arena, io, &.{d}));
    try tiers.append(arena, try manifest.scanRoots(arena, io, roots));
    return tiers.toOwnedSlice(arena);
}

/// Resolve the absolute path to `$BPMP_HOME/store/` (or the XDG fallback).
/// Returns null when neither env var is present (i.e. nothing to consult).
/// Caller owns the returned slice via `gpa`.
pub fn resolveBpmpStoreRoot(gpa: std.mem.Allocator, env_map: EnvMap) !?[]u8 {
    if (env_map) |m| {
        if (m.get("BPMP_HOME")) |v| {
            if (v.len > 0) return try std.fs.path.join(gpa, &.{ v, "store" });
        }
        if (m.get("XDG_CACHE_HOME")) |v| {
            if (v.len > 0) return try std.fs.path.join(gpa, &.{ v, "bpmp", "store" });
        }
        if (m.get("HOME")) |v| {
            if (v.len > 0) return try std.fs.path.join(gpa, &.{ v, ".cache", "bpmp", "store" });
        }
    }
    return null;
}

/// The packages of one compilation (decision 109): the project's own
/// `botopink.json` `name` and every dependency package a module was loaded
/// from — the first segment of its `<dep>/<stem>` path, transitive ones
/// included. The erlang and BEAM module atoms start with it. Owned by `arena`.
pub fn packagesOf(arena: std.mem.Allocator, proj: config.ProjectConfig, dep_modules: []const Module) !bp.codegen.crossModule.Packages {
    var deps: std.ArrayListUnmanaged([]const u8) = .empty;
    for (dep_modules) |m| {
        const slash = std.mem.indexOfScalar(u8, m.path, '/') orelse continue;
        const head = m.path[0..slash];
        for (deps.items) |d| {
            if (std.mem.eql(u8, d, head)) break;
        } else try deps.append(arena, try arena.dupe(u8, head));
    }
    return .{ .root = proj.name, .deps = deps.items };
}

/// The package whose sources hold the sidecars of module `name`: the
/// dependency the build's module table (`packages`, `packagesOf`) gives it, or
/// null for a module of the project itself — whatever its folder. A project
/// module `orm/entity` is the project's even when a library root carries a
/// package named `orm`; reading the first segment as a package name looked
/// that package up and never shipped `src/sidecars/orm_host.erl` (T16).
pub fn sidecarPackage(packages: bp.codegen.crossModule.Packages, name: []const u8) ?[]const u8 {
    const id = packages.idOf(name);
    return if (id.package_in_path) id.package else null;
}

test "sidecarPackage: a project folder is the project's, a dependency module its package's" {
    const pk: bp.codegen.crossModule.Packages = .{ .root = "app", .deps = &.{"rakun"} };
    try std.testing.expectEqual(@as(?[]const u8, null), sidecarPackage(pk, "orm/entity"));
    try std.testing.expectEqual(@as(?[]const u8, null), sidecarPackage(pk, "main"));
    try std.testing.expectEqualStrings("rakun", sidecarPackage(pk, "rakun/http").?);
    try std.testing.expectEqualStrings("std", sidecarPackage(pk, "std/io").?);
    // `libs/std`'s own build: its folders are its own.
    const own_std: bp.codegen.crossModule.Packages = .{ .root = "std" };
    try std.testing.expectEqual(@as(?[]const u8, null), sidecarPackage(own_std, "io/random"));
}

/// Load the `files` of the resolved dependency `dep` at `dir` as modules named
/// `<dep>/<stem>` — the prefix is how the core resolves `from "<dep>"`
/// generically.
fn loadOne(
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    m: manifest.Manifest,
    dep: []const u8,
    out: *std.ArrayListUnmanaged(Module),
) !void {
    return loadOneLogged(gpa, io, dir, m, dep, out, null);
}

/// `loadOne`, each module's reader noting its reads in `log` when given.
fn loadOneLogged(
    gpa: std.mem.Allocator,
    io: std.Io,
    dir: []const u8,
    m: manifest.Manifest,
    dep: []const u8,
    out: *std.ArrayListUnmanaged(Module),
    log: ?*bp.ReadLog,
) !void {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    const first = out.items.len;
    // Where an import-source refusal points: each file relative to the
    // working directory, the spelling a project module's location has.
    var file_paths: std.ArrayListUnmanaged([]const u8) = .empty;
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = cwd_buf[0..try std.process.currentPath(io, &cwd_buf)];
    for (m.files) |file| {
        const file_path = try std.fs.path.join(arena, &.{ dir, m.src, file });
        const source = std.Io.Dir.cwd().readFileAlloc(io, file_path, gpa, .unlimited) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => {
                var aw: std.Io.Writer.Allocating = .init(arena);
                try renderMissingFile(&aw.writer, err, dep, file, file_path, m.path, m.text);
                reporter.print("{s}", .{aw.written()});
                return error.LibFileNotFound;
            },
        };
        errdefer gpa.free(source);

        const stem = stripSourceExt(file);
        const mod_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ dep, stem });
        errdefer gpa.free(mod_path);
        // `@src().file` (decision 73) is relative to the dependency's own
        // package root: `<manifest.src>/<file>`, a trailing `/` of `src`
        // dropped (`"src/"` gave `src//x.bp`).
        const src_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ std.mem.trimEnd(u8, m.src, "/"), file });
        errdefer gpa.free(src_path);
        std.mem.replaceScalar(u8, src_path, '\\', '/');

        // The package is the path's first segment (`<dep>/<stem>`), a slice
        // of the path so `freeModules` owns it with it.
        // Decision 341: the dependency's declared targets decide which host
        // cells its decorators need.
        // Decision 519 — `@embed` in the dependency reads its own files.
        const root = try gpa.dupe(u8, dir);
        errdefer gpa.free(root);
        try out.append(gpa, .{ .path = mod_path, .source = source, .srcPath = src_path, .package = mod_path[0..dep.len], .targets = bp.Targets.of(m.targets), .files = files: {
            var f = bp.PackageFiles.disk(io, root);
            f.log = log;
            break :files f;
        } });
        try file_paths.append(arena, try std.fs.path.relative(arena, cwd, null, cwd, file_path));
    }
    try checkImportSources(arena, dep, m, file_paths.items, out.items[first..]);
    // `files` lists what the package ships, not a build order: each module
    // compiles after the siblings it imports.
    resolver.orderPackageModules(arena, dep, out.items[first..]);
}

/// The import-source rule a package's own build applies (`resolver.checkSources`,
/// decisions 206, 242 and 309), applied to dependency `dep`'s modules `mods`
/// (read from `files`) against ITS manifest `m`: a `from` names std or a
/// package `m` declares, and never `dep` itself or a module of
/// it. A consumer used to compile the import of a package the dependency does
/// not declare with nothing bound, and answered `unbound variable` at the
/// first use — in the dependency's module, with no word of the import that
/// bound nothing.
fn checkImportSources(
    arena: std.mem.Allocator,
    dep: []const u8,
    m: manifest.Manifest,
    files: []const []const u8,
    mods: []const Module,
) Error!void {
    // The package's own module paths, as when it builds itself (`<dep>/a` → `a`).
    const local = try arena.alloc(Module, mods.len);
    for (mods, 0..) |mod, i| {
        local[i] = mod;
        local[i].path = mod.path[dep.len + 1 ..];
        local[i].package = "";
    }
    const declared = try arena.alloc([]const u8, m.dependencies.len);
    for (m.dependencies, 0..) |d, i| declared[i] = d.name;
    var diag: resolver.Diagnostic = .{ .kind = resolver.Error.RootNotFound };
    // Decision 309 — nor the package itself: its manifest `name`, or the
    // name it is imported under when the manifest names none.
    const own = if (m.name.len > 0) m.name else dep;
    resolver.checkSources(arena, local, files, declared, own, arena, &diag) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => {
            sources.reportDiag(arena, diag);
            return error.ImportSourceRefused;
        },
    };
}

test "loadOne: a dependency importing a package it does not declare is refused at the import" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;
    test_scratch.remove(io, "dep-import-source");
    defer test_scratch.remove(io, "dep-import-source");
    // `kit-link` imports `kit-core` and declares it; `kit-bare` imports it too
    // and declares nothing.
    try writeKitWorkspace(io, "dep-import-source");
    try writeFileP(io, test_scratch.path(io, "dep-import-source/ws/repository/kit/modules/kit-bare/botopink.json"), "{ \"name\": \"kit-bare\", \"files\": [\"bare.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "dep-import-source/ws/repository/kit/modules/kit-bare/src/bare.bp"), "import {core} from \"kit-core\";");
    const roots = [_][]const u8{test_scratch.path(io, "dep-import-source/ws/repository")};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |mod| {
            gpa.free(mod.path);
            gpa.free(mod.source);
            gpa.free(mod.srcPath);
            if (mod.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    try loadByName(gpa, io, &roots, "kit-link", &out);
    try std.testing.expectError(error.ImportSourceRefused, loadByName(gpa, io, &roots, "kit-bare", &out));
}

/// The package a sidecar is shipped from: the directory, and the manifest whose
/// `src` says where inside it the sidecar lives.
const SidecarOwner = struct {
    dir: []const u8,
    package: manifest.Manifest,

    /// Where the owner keeps its sources — `<dir>/<src>`.
    fn srcDir(self: SidecarOwner, arena: std.mem.Allocator) ![]const u8 {
        return std.fs.path.join(arena, &.{ self.dir, self.package.src });
    }
};

/// The owner of the sidecars of the emitted modules prefixed `<lib>/`.
///
/// A sidecar shipper sees only the emitted module name, whose first segment is
/// the **import name** of a dependency (`rakun/http` → `rakun`). Which
/// directory that name meant was already decided, by `manifest.resolveDependency`,
/// when `loadDependencies` compiled the modules: `{ "path" }` from the project's
/// directory, `{ "workspace": true }` from the enclosing workspace, `{ "git" }`
/// by name across the roots. Asking the roots for the name a second time asks a
/// different question and gets a different answer — a `path` dependency outside
/// every root has no entry at all, and a name two checkouts of one library both
/// declare is a located problem rather than a directory. So the dependency is
/// resolved again, the same way, from the project's own manifest.
///
/// Only an owner the project does not declare falls back to the by-name entry:
/// that is the embedded `std`, whose modules are emitted as `std/<mod>` and
/// which never appears in `dependencies`.
///
/// A package a `run()` brought into the program (`bp_load__<path>`,
/// decision 792 (5)) is no dependency and no package on disk by that name:
/// it is none, and nothing is read. Asking the closure and every root for it
/// read every manifest of the checkout again for each loaded package, into
/// the shipper's arena (~140 MB a package in the meta checkout): a module
/// that loads and runs 39 cases peaked at 4.6 GB on erlang (decision 1061 (2)).
///
/// Null with `out_err` set is a located problem; null without one is "no such
/// package" — the caller decides whether that is fatal.
fn sidecarOwner(
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    io: std.Io,
    roots: []const []const u8,
    env_map: EnvMap,
    project: ?manifest.Manifest,
    lib: []const u8,
    out_err: *?manifest.Located,
) !?SidecarOwner {
    if (bp.load.isLoadedPackage(lib)) return null;
    if (project) |proj| {
        for (proj.dependencies) |dep| {
            if (!std.mem.eql(u8, dep.name, lib)) continue;

            var buf: [std.fs.max_path_bytes]u8 = undefined;
            const n = try std.process.currentPath(io, &buf);
            const tiers = try dependencyTiers(gpa, arena, io, env_map, buf[0..n], roots);
            const resolved = manifest.resolveDependency(arena, io, proj, buf[0..n], dep, tiers, out_err) catch |e| switch (e) {
                // The build already compiled this dependency, so a refusal here
                // is not reachable through `build`/`test`; it is still a located
                // problem and never a silent null.
                error.Invalid => return null,
                error.OutOfMemory => return error.OutOfMemory,
            };
            const r = resolved orelse return null;
            return .{ .dir = r.dir, .package = r.manifest };
        }

        // A dependency of a dependency: the build compiled it from the
        // directory its OWN dependent's entry meant (`DepClosure`), so the
        // closure is walked again the same way. A `path` dependency outside
        // the workspace whose members it depends on carries those members in
        // no root, and asking the roots by name found nothing.
        var buf: [std.fs.max_path_bytes]u8 = undefined;
        const n = try std.process.currentPath(io, &buf);
        if (try closureOwner(gpa, arena, io, roots, env_map, proj, buf[0..n], lib)) |owner| return owner;
    }

    const entries = try manifest.scanRoots(arena, io, roots);
    const e = manifest.find(entries, lib) orelse return null;
    if (e.problem) |pr| {
        out_err.* = pr;
        return null;
    }
    if (e.is_workspace) return null;
    return .{ .dir = e.dir, .package = e.manifest.? };
}

/// The package `lib` of the dependency closure of the project at `project_dir`
/// whose manifest is `project` — resolved exactly as `loadDependencies` resolved
/// it for the build (`DepClosure`) — or null when no package of the closure
/// carries that import name. A closure that does not resolve is null too: the
/// build compiled it before any shipper runs, so that is not reachable through
/// `build`/`test`, and the caller still names the missing owner.
fn closureOwner(
    gpa: std.mem.Allocator,
    arena: std.mem.Allocator,
    io: std.Io,
    roots: []const []const u8,
    env_map: EnvMap,
    project: manifest.Manifest,
    project_dir: []const u8,
    lib: []const u8,
) !?SidecarOwner {
    var closure: DepClosure = .{
        .arena = arena,
        .io = io,
        .tiers = try dependencyTiers(gpa, arena, io, env_map, project_dir, roots),
    };
    for (project.dependencies) |dep| _ = closure.resolve(project, project_dir, dep) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    for (project.dependencies) |dep| closure.visit(project, dep.name) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return null,
    };
    const pkg = closure.packages.get(lib) orelse return null;
    return .{ .dir = pkg.dir, .package = pkg.manifest };
}

test "resolveLoaded: what a loaded package keeps is its modules, not the walk of the roots (decision 1061 (2))" {
    const io = std.testing.io;
    test_scratch.remove(io, "loaded-keeps");
    defer test_scratch.remove(io, "loaded-keeps");
    // A root of many packages: a walk that kept what it read would keep them.
    const roots_dir = test_scratch.path(io, "loaded-keeps/roots");
    var path_buf: [std.fs.max_path_bytes]u8 = undefined;
    var text_buf: [64]u8 = undefined;
    for (0..300) |i| {
        try writeFileP(io, try std.fmt.bufPrint(&path_buf, "{s}/p{d}/botopink.json", .{ roots_dir, i }), try std.fmt.bufPrint(&text_buf, "{{ \"name\": \"p{d}\" }}", .{i}));
        try writeFileP(io, try std.fmt.bufPrint(&path_buf, "{s}/p{d}/src/main.bp", .{ roots_dir, i }), "pub fn main() -> void {}\n");
    }
    try writeFileP(io, test_scratch.path(io, "loaded-keeps/dep/botopink.json"), "{ \"name\": \"dep\", \"version\": \"0.0.1\", \"src\": \"src/\", \"entry\": \"one.bp\", \"files\": [\"one.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "loaded-keeps/dep/src/one.bp"), "pub fn one() -> i32 { return 1; }\n");
    try writeFileP(io, test_scratch.path(io, "loaded-keeps/pkg/botopink.json"), "{ \"name\": \"pkg\", \"dependencies\": { \"dep\": { \"path\": \"../dep\" } } }");
    try writeFileP(io, test_scratch.path(io, "loaded-keeps/pkg/src/main.bp"), "import {one} from \"dep\";\npub fn main() -> void { _ = one(); }\n");

    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try map.put(ENV_VAR, roots_dir);
    const saved_env = load_env;
    load_env = &map;
    defer load_env = saved_env;

    const before = loaded_arena.queryCapacity();
    const r = try resolveLoaded(null, io, test_scratch.path(io, "loaded-keeps/pkg"));
    const kept = loaded_arena.queryCapacity() - before;
    try std.testing.expect(r == .ok);
    try std.testing.expectEqual(@as(usize, 1), r.ok.modules.len);
    try std.testing.expect(kept < 64 * 1024);
}

test "sidecarOwner: a loaded package is no package on disk — no root is read for it (decision 1061 (2))" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "sidecar-owner-loaded");
    defer test_scratch.remove(io, "sidecar-owner-loaded");
    // A root holding a package under the very name a loaded package is
    // emitted as (a root's child is found by its directory's name): the
    // lookup, were it made, would answer it.
    try writeFileP(io, test_scratch.path(io, "sidecar-owner-loaded/repository/bp_load__cases__a/botopink.json"),
        \\{ "name": "bp_load__cases__a" }
    );
    try writeFileP(io, test_scratch.path(io, "sidecar-owner-loaded/repository/bp_load__cases__a/src/main.bp"), "pub fn main() -> void {}\n");
    try writeFileP(io, test_scratch.path(io, "sidecar-owner-loaded/repository/other/botopink.json"),
        \\{ "name": "other" }
    );
    try writeFileP(io, test_scratch.path(io, "sidecar-owner-loaded/repository/other/src/main.bp"), "pub fn main() -> void {}\n");
    const roots = [_][]const u8{test_scratch.path(io, "sidecar-owner-loaded/repository")};
    var err: ?manifest.Located = null;
    try std.testing.expectEqual(@as(?SidecarOwner, null), try sidecarOwner(std.testing.allocator, arena, io, &roots, null, null, "bp_load__cases__a", &err));
    try std.testing.expectEqual(@as(?manifest.Located, null), err);
    // A package by its name is still found among the roots.
    const other = (try sidecarOwner(std.testing.allocator, arena, io, &roots, null, null, "other", &err)).?;
    try std.testing.expectEqualStrings("other", other.package.name);
}

test "closureOwner: a dependency of a path dependency resolves from its dependent's workspace" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure-owner");
    defer test_scratch.remove(io, "closure-owner");
    try writeKitWorkspace(io, "closure-owner");

    // `app` lives outside the `kit` workspace and names only `kit-forms`, by
    // path; `kit-core` and `kit-link` are `kit-forms`' workspace siblings and
    // are under no library root (none is given).
    const app_dir = test_scratch.path(io, "closure-owner/app");
    var err: ?manifest.Located = null;
    const m = try manifest.parse(arena,
        \\{ "name": "app", "dependencies": { "kit-forms": { "path": "../ws/repository/kit/modules/kit-forms" } } }
    , try std.fmt.allocPrint(arena, "{s}/botopink.json", .{app_dir}), &err);

    const core = (try closureOwner(std.testing.allocator, arena, io, &.{}, null, m, app_dir, "kit-core")).?;
    try std.testing.expect(std.mem.endsWith(u8, core.dir, "closure-owner/ws/repository/kit/modules/kit-core"));
    try std.testing.expectEqualStrings("kit-core", core.package.name);
    const forms = (try closureOwner(std.testing.allocator, arena, io, &.{}, null, m, app_dir, "kit-forms")).?;
    try std.testing.expect(std.mem.endsWith(u8, forms.dir, "closure-owner/ws/repository/kit/modules/kit-forms"));
    // Not a package of the closure.
    try std.testing.expectEqual(@as(?SidecarOwner, null), try closureOwner(std.testing.allocator, arena, io, &.{}, null, m, app_dir, "kit-other"));
}

/// The project's own manifest, read once per shipper run and only when a
/// relative sidecar require is actually seen. A project whose manifest cannot
/// be read is not diagnosed here — `build` and `test` already refused before
/// reaching a shipper — it simply has no dependency to resolve through.
const ProjectManifest = struct {
    value: ?manifest.Manifest = null,
    read: bool = false,

    fn get(self: *ProjectManifest, arena: std.mem.Allocator, io: std.Io) ?manifest.Manifest {
        if (self.read) return self.value;
        self.read = true;
        // Parsed under the bare `botopink.json`, the name every other CLI
        // diagnostic gives the project's manifest (`config.zig`), so a located
        // refusal reads `--> botopink.json:L:C` like the rest.
        const text = std.Io.Dir.cwd().readFileAlloc(io, manifest.FILENAME, arena, .unlimited) catch return null;
        var err: ?manifest.Located = null;
        var m = manifest.parseWith(arena, text, manifest.FILENAME, &err, .{ .defer_bpp = true }) catch return null;
        // A workspace member resolves the dependencies it inherits too
        // (decision 512), as `config.load` gave them to the build.
        manifest.inheritInPlace(arena, io, &m, ".", &err) catch return null;
        self.value = m;
        return self.value;
    }
};

/// A sidecar the build cannot ship ends the build, after the located
/// diagnostic: `error.SidecarRefused`, which `build` and `test` answer with
/// exit 1. It used to `std.process.exit(1)` by hand, because both callers ran
/// the shipper as `shipMjsSidecars(…) catch {}` and would have swallowed the
/// error — that is fixed at the callers, so the refusal is an ordinary error
/// return again. There is no flag, environment variable or manifest field that
/// turns it off (decision 67 of 1.0.10-beta).
fn refuseSidecar(loc: manifest.Located) error{SidecarRefused} {
    loc.print();
    return error.SidecarRefused;
}

/// True when the project's manifest declares `lib` under `dependencies`.
fn declaresDependency(proj: ?manifest.Manifest, lib: ?[]const u8) bool {
    const p = proj orelse return false;
    const name = lib orelse return false;
    for (p.dependencies) |dep| {
        if (std.mem.eql(u8, dep.name, name)) return true;
    }
    return false;
}

/// Where a sidecar refusal points: the `dependencies` entry that named the
/// owning library, when the project declares one — the line a reader can act on
/// — and otherwise the `"src"` of the manifest the file was looked for under
/// (a project-own sidecar, or an owner the project does not declare, such as the
/// embedded `std`). A project whose manifest could not be read leaves the
/// diagnostic on the first byte of `botopink.json` rather than unreported.
fn sidecarLocation(
    proj: ?manifest.Manifest,
    lib: ?[]const u8,
    owner_pkg: ?manifest.Manifest,
    message: []const u8,
) manifest.Located {
    if (declaresDependency(proj, lib)) return proj.?.locateEntryAt("dependencies", lib.?, message);
    if (owner_pkg) |pkg| return pkg.locateAt("src", message);
    if (proj) |p| return p.locateAt("src", message);
    return .{ .message = message, .file = manifest.FILENAME, .source = "", .line = 1, .col = 1, .span = 1 };
}

/// The owning library of an emitted module resolves to no package directory:
/// the project declares no dependency of that name and no root carries it
/// either, so there is nowhere to ship the sidecar from.
fn unresolvedOwner(
    arena: std.mem.Allocator,
    proj: ?manifest.Manifest,
    lib: []const u8,
    module: []const u8,
    req_path: []const u8,
) !manifest.Located {
    const message = try std.fmt.allocPrint(
        arena,
        "module '{s}' requires \"{s}\", but its library '{s}' resolves to no package directory — the sidecar cannot be shipped",
        .{ module, req_path, lib },
    );
    return sidecarLocation(proj, lib, null, message);
}

/// The owner resolved, but neither of the two places a sidecar may live under
/// its `src` holds the file the emitted module requires.
fn missingSidecar(
    arena: std.mem.Allocator,
    proj: ?manifest.Manifest,
    lib: []const u8,
    owner_pkg: manifest.Manifest,
    module: []const u8,
    req_path: []const u8,
    probed_sidecar: []const u8,
    probed_flat: []const u8,
) !manifest.Located {
    const message = try std.fmt.allocPrint(
        arena,
        "dependency '{s}' requires \"{s}\" from module '{s}', but no such file is in its sources (looked at {s}, then {s})",
        .{ lib, req_path, module, probed_sidecar, probed_flat },
    );
    return sidecarLocation(proj, lib, owner_pkg, message);
}

/// The same for a module of the project itself, whose sidecars come from the
/// project's own `src`.
fn missingOwnSidecar(
    arena: std.mem.Allocator,
    proj: ?manifest.Manifest,
    module: []const u8,
    req_path: []const u8,
    probed_sidecar: []const u8,
    probed_flat: []const u8,
) !manifest.Located {
    const message = try std.fmt.allocPrint(
        arena,
        "module '{s}' requires \"{s}\", but no such file is in this project's sources (looked at {s}, then {s})",
        .{ module, req_path, probed_sidecar, probed_flat },
    );
    return sidecarLocation(proj, null, null, message);
}

/// The sidecar is where it should be and still could not be read (permissions,
/// a dangling symlink, an I/O error).
fn unreadableSidecar(
    arena: std.mem.Allocator,
    proj: ?manifest.Manifest,
    lib: ?[]const u8,
    module: []const u8,
    req_path: []const u8,
    src: []const u8,
    err: anyerror,
) !manifest.Located {
    const message = try std.fmt.allocPrint(
        arena,
        "module '{s}' requires \"{s}\", but {s} could not be read ({s})",
        .{ module, req_path, src, @errorName(err) },
    );
    return sidecarLocation(proj, lib, null, message);
}

/// A dependency's `files` entry that could not be read: the path looked for,
/// located at the entry in the manifest (`--> <lib>/botopink.json:L:C`).
fn renderMissingFile(
    w: *std.Io.Writer,
    err: anyerror,
    dep: []const u8,
    entry: []const u8,
    file_path: []const u8,
    manifest_path: []const u8,
    manifest_text: []const u8,
) !void {
    var msg_buf: [1024]u8 = undefined;
    const message = (if (err == error.FileNotFound)
        std.fmt.bufPrint(&msg_buf, "dependency '{s}' lists \"{s}\" in `files`, but {s} does not exist", .{ dep, entry, file_path })
    else
        std.fmt.bufPrint(&msg_buf, "dependency '{s}' lists \"{s}\" in `files`, but {s} could not be read ({s})", .{ dep, entry, file_path, @errorName(err) })) catch "a dependency's `files` entry could not be read";

    // Locate the quoted entry after the `"files"` key; fall back to the key,
    // then to the first line.
    var quoted_buf: [512]u8 = undefined;
    const quoted = std.fmt.bufPrint(&quoted_buf, "\"{s}\"", .{entry}) catch entry;
    const key = std.mem.indexOf(u8, manifest_text, "\"files\"");
    const offset: usize, const span: usize = blk: {
        if (key) |k| {
            if (std.mem.indexOfPos(u8, manifest_text, k, quoted)) |at| break :blk .{ at, quoted.len };
            break :blk .{ k, "\"files\"".len };
        }
        break :blk .{ 0, 1 };
    };
    var line: usize = 1;
    var line_start: usize = 0;
    for (manifest_text[0..offset], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    try diagnostics.renderLocated(w, message, manifest_path, manifest_text, line, offset - line_start + 1, span);
}

/// The one list of source extensions (`manifest.SOURCE_EXTENSIONS`).
fn stripSourceExt(name: []const u8) []const u8 {
    return manifest.stripSourceExt(name);
}

/// Free memory allocated by `loadDependencies`.
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
        gpa.free(m.srcPath);
        if (m.files) |f| gpa.free(f.root);
    }
    gpa.free(modules);
}

// ── runtime `.mjs` sidecar shipping (G2) ───────────────────────────────────────
//
// A `#[@external(.JavaScript("""require("../../src/x.mjs")…"""))]` lowers to a top-level
// `require("../../src/x.mjs")` in the emitted module. The path is authored
// relative to the lib's OWN build output, so it resolves for the lib's own
// `botopink test`/`build`; but when the lib is loaded as a *dependency* its
// emitted module sits one directory deeper (`<out>/<lib>/<mod>.js`), so the same
// relative `require` lands at a path the source `.mjs` was never copied to.
//
// `shipMjsSidecars` closes that gap generically (no lib names): for every emitted
// module it scans the JS for relative `require("….mjs")` and — when nothing is
// there yet — copies the source `.mjs` (found under the owning lib's `src/`, or
// the project's own `src/`) into place. Idempotent and lib-agnostic.
//
// Decision 1015 — the output is one flat folder, so a sidecar is a file of it
// too, named after its package as a module is: `<pkg>@<base>` (std's
// `./sidecars/random.mjs` ships as `std@random.mjs`, rakun-bpp's
// `./form_runtime.mjs` as `rakun_bpp@form_runtime.mjs`). The emitted module's
// `require` — and its test unit's, one folder below — is rewritten to reach
// it, so two packages' sidecars of one basename never meet, and a `require`
// that would escape the output (`../../src/onze.mjs`) writes nothing beside it.
pub fn shipMjsSidecars(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    packages: bp.codegen.crossModule.Packages,
    out_dir: []const u8,
    ext: []const u8,
    env_map: EnvMap,
) !void {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Resolved lazily on the first relative `.mjs` require (most builds have none).
    var roots: ?[][]const u8 = null;
    defer if (roots) |r| freeRoots(gpa, r);
    // The project's own manifest — how a dependency's directory is resolved, and
    // where a refusal is located. Read on the same first require.
    var project: ProjectManifest = .{};

    for (outputs) |o| {
        if (o.result.failed()) continue;
        const stem = try bp.codegen.crossModule.flatName(arena, packages.idOf(o.name));
        const emitted_rel = try std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ out_dir, stem, ext });
        // The sidecar's flat name starts with the module's package (`std@`).
        const pkg_prefix = stem[0..(std.mem.indexOfScalar(u8, stem, '@') orelse stem.len)];
        // `require` paths of this module to rewrite once the scan is done.
        var rewrites: std.ArrayListUnmanaged([2][]const u8) = .empty;
        // The owning lib is the package the build's module table gives the
        // module (`sidecarPackage`): `rakun/http` → `rakun`; a module in a
        // folder of the project's own tree (`io/random` under `libs/std`'s
        // own `botopink test`) is the project's.
        const owner = sidecarPackage(packages, o.name);

        var search: usize = 0;
        const js = o.result.js;
        // Probe both quote styles — `#[@external(.JavaScript(…))]` templates rendered
        // verbatim by the §A2 path may emit either `require("…")` (the legacy
        // codegen-side form) or `require('…')` (when the template body itself
        // chose single quotes, e.g. `require('./sidecars/random.mjs')`).
        while (true) {
            const dq = std.mem.indexOfPos(u8, js, search, "require(\"");
            const sq = std.mem.indexOfPos(u8, js, search, "require('");
            const start = blk: {
                if (dq) |d| {
                    if (sq) |s| break :blk if (d < s) d else s;
                    break :blk d;
                }
                if (sq) |s| break :blk s;
                break;
            };
            const quote: u8 = if (js[start + "require(".len] == '"') '"' else '\'';
            const path_start = start + "require(\"".len; // same length for both quotes
            const path_end = std.mem.indexOfScalarPos(u8, js, path_start, quote) orelse break;
            const req_path = js[path_start..path_end];
            search = path_end + 1;

            if (!std.mem.endsWith(u8, req_path, ".mjs")) continue;
            // Only relative requires need shipping — bare specifiers (`node:http`)
            // and absolutes resolve on their own.
            if (!std.mem.startsWith(u8, req_path, ".")) continue;

            const base = std.fs.path.basename(req_path);
            // Decision 1015 — `<out>/<pkg>@<base>`, the module's `require`
            // rewritten to the sibling.
            const flat = try std.fmt.allocPrint(arena, "{s}@{s}", .{ pkg_prefix, base });
            const target = try std.fs.path.join(arena, &.{ out_dir, flat });
            const new_req = try std.fmt.allocPrint(arena, "./{s}", .{flat});
            if (!std.mem.eql(u8, req_path, new_req)) {
                var seen = false;
                for (rewrites.items) |r| {
                    if (std.mem.eql(u8, r[0], req_path)) seen = true;
                }
                if (!seen) try rewrites.append(arena, .{ req_path, new_req });
            }
            if (fileExists(io, target)) continue;

            // std-tail F2: when a sidecar lives under `<lib>/<src>/sidecars/<base>`
            // (the convention for std's `#[@external(.JavaScript(…))]` adapters that
            // need a sibling `.mjs`/`.erl` file), the search also probes that
            // subdirectory before falling back to the flat `<lib>/<src>/<base>`.
            //
            // The owner's directory is the one the build resolved the dependency
            // to (`sidecarOwner`), and `<src>` is that package's own — never a
            // basename match across the roots. A sidecar that is named and
            // cannot be found is the end of the build, not a silent skip.
            // `std` is bundled: its sidecars ship from the compiler's own copy,
            // whether or not the project sits where a `std` directory resolves
            // (a project outside any checkout, a published binary) — 144 B-49.
            if (owner) |lib| {
                if (std.mem.eql(u8, lib, "std")) {
                    if (bp.comptime_pipeline.stdSidecar(base)) |embedded| {
                        if (std.fs.path.dirname(target)) |parent| {
                            std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                                error.PathAlreadyExists => {},
                                else => return err,
                            };
                        }
                        try placeFile(arena, io, target, embedded);
                        continue;
                    }
                }
            }

            const src: []const u8 = blk: {
                if (owner) |lib| {
                    if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                    const proj = project.get(arena, io);
                    var oerr: ?manifest.Located = null;
                    const found = try sidecarOwner(gpa, arena, io, roots.?, env_map, proj, lib, &oerr);
                    const pkg = found orelse return refuseSidecar(oerr orelse
                        try unresolvedOwner(arena, proj, lib, o.name, req_path));
                    const src_dir = try pkg.srcDir(arena);
                    const sidecar = try std.fs.path.join(arena, &.{ src_dir, "sidecars", base });
                    if (fileExists(io, sidecar)) break :blk sidecar;
                    const cand = try std.fs.path.join(arena, &.{ src_dir, base });
                    if (fileExists(io, cand)) break :blk cand;
                    return refuseSidecar(try missingSidecar(arena, proj, lib, pkg.package, o.name, req_path, sidecar, cand));
                }
                // Project-own module: probe sidecars/ first, then flat src/.
                const proj = project.get(arena, io);
                const own_src = if (proj) |p| p.src else "src/";
                const sidecar = try std.fs.path.join(arena, &.{ own_src, "sidecars", base });
                if (fileExists(io, sidecar)) break :blk sidecar;
                const cand = try std.fs.path.join(arena, &.{ own_src, base });
                if (fileExists(io, cand)) break :blk cand;
                return refuseSidecar(try missingOwnSidecar(arena, proj, o.name, req_path, sidecar, cand));
            };

            const data = std.Io.Dir.cwd().readFileAlloc(io, src, arena, .unlimited) catch |err|
                return refuseSidecar(try unreadableSidecar(arena, project.get(arena, io), owner, o.name, req_path, src, err));
            if (std.fs.path.dirname(target)) |parent| {
                std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            }
            try placeFile(arena, io, target, data);
        }

        if (rewrites.items.len > 0) {
            // The file this run just wrote: failing to read it back is an I/O
            // error of the run, never a module left with its old `require`s.
            const emitted = try std.Io.Dir.cwd().readFileAlloc(io, emitted_rel, arena, .unlimited);
            try placeFile(arena, io, emitted_rel, try rewriteRequires(arena, emitted, rewrites.items, ""));
            // `botopink test`'s unit (decision 513) sits one folder below and
            // spells each of the module's relative `require`s from there
            // (`commonJS.zig` `deeperRequires`: `../` before it).
            if (o.result.test_unit) |u| {
                const unit_rel = try std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ out_dir, u.atom, ext });
                const unit = try std.Io.Dir.cwd().readFileAlloc(io, unit_rel, arena, .unlimited);
                try placeFile(arena, io, unit_rel, try rewriteRequires(arena, unit, rewrites.items, "../"));
            }
        }
    }
}

test "shipMjsSidecars: std's sidecar ships from the compiler's own copy, not from a std directory a root carries (144 B-49)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "std-sidecar");
    defer test_scratch.remove(io, "std-sidecar");
    // A root carrying a `std` package whose sidecar differs from the bundled
    // one: the bundled `std` is the compiler's, so its copy is what ships.
    try writeFileP(io, test_scratch.path(io, "std-sidecar/roots/std/botopink.json"), "{ \"name\": \"std\", \"src\": \"src/\" }");
    try writeFileP(io, test_scratch.path(io, "std-sidecar/roots/std/src/sidecars/random.mjs"), "// a std that is not the bundled one\n");
    var env = std.process.Environ.Map.init(std.testing.allocator);
    defer env.deinit();
    try env.put(ENV_VAR, test_scratch.path(io, "std-sidecar/roots"));

    const out_dir = test_scratch.path(io, "std-sidecar/out");
    try writeFileP(io, try std.fs.path.join(arena, &.{ out_dir, "std@io@random.js" }), "const r = require('./sidecars/random.mjs');\n");
    var outputs = [_]bp.codegen.ModuleOutput{.{
        .name = "std/io/random",
        .src = "",
        .result = .{ .js = try arena.dupe(u8, "const r = require('./sidecars/random.mjs');\n"), .comptime_script = null },
    }};
    try shipMjsSidecars(std.testing.allocator, io, &outputs, .{ .root = "app" }, out_dir, ".js", &env);

    // Decision 1015 — flat, after its package, the module's `require` rewritten.
    const shipped = try std.Io.Dir.cwd().readFileAlloc(io, try std.fs.path.join(arena, &.{ out_dir, "std@random.mjs" }), arena, .unlimited);
    try std.testing.expectEqualStrings(bp.comptime_pipeline.stdSidecar("random.mjs").?, shipped);
    const module = try std.Io.Dir.cwd().readFileAlloc(io, try std.fs.path.join(arena, &.{ out_dir, "std@io@random.js" }), arena, .unlimited);
    try std.testing.expectEqualStrings("const r = require('./std@random.mjs');\n", module);
}

// ── host `.erl` module shipping ────────────────────────────────────────────────
//
// The erlang twin of `shipMjsSidecars`. A `#[@external(.Erlang("host:fn($0)"))]`
// lowers to a qualified call `host:fn(…)`; `host` is a module the library
// authors in erlang and keeps beside its `.bp` sources. Nothing shipped it, so
// a library whose host code is erlang had nothing to ship — only `.mjs`
// sidecars ever reached the output — and every such call died with
// `undefined function host:fn/N` at run time.
//
// What each runtime looks up differs, so what "into place" means differs. Node
// reads a path out of the emitted text (`require("…/x.mjs")`), so the `.mjs`
// half resolves that path and puts the file there. The erlang code server
// resolves a module **atom**, and the emitted text carries no path at all — so
// the `.erl` half puts the source in the output directory, which is where the
// test runner's `__bp_load_siblings/0` looks: it compiles and loads every
// `**/*.erl` beside the script before running (`codegen/erlang.zig`). Plain
// `escript` does not do that — a `build`/`run` output needs the same loader, and
// that emitter is another front's (`examples/modules` — now `conformance/modules/modules/cases/modules` — was red on erlang for the
// same reason).
//
// Generic and lib-agnostic, like the `.mjs` half: the scan yields every
// `atom:atom(` qualifier in the emitted erlang, and a qualifier ships only when
// a file of that name is found under the owning lib's `src/sidecars/` or `src/`
// — so `lists:foldl`, `base64:encode` and every other OTP call is a no-op, as
// is a call to another module of this build. Idempotent; writes only inside
// `out_dir`. Returns how many host modules it shipped.
//
// The BEAM target calls the same host modules — an `#[@external(.Erlang("host:fn($0)"))]`
// lowers to `{extfunc, host, fn, N}` in the `.S` — so its build ships
// the same files, into `out/beam/`, where the assembled entry's
// `'__bp_load_siblings'/0` (`codegen/beam_asm.zig`) compiles and loads every
// `.erl` beside the module. `text` says which of the two emitted texts
// `outputs` holds; everything after the scan is one code path.
pub fn shipErlSidecars(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    packages: bp.codegen.crossModule.Packages,
    out_dir: []const u8,
    text: HostText,
    env_map: EnvMap,
) !usize {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Module atoms this build emits — a qualifier naming one of them is a
    // project or dependency module, never a host module: every `-module(…)`
    // an output declares (decision 109's `<package>@<path>`, and each unit
    // `<…>@@<Decl>` a `type` becomes). Not the output's BASENAME: no emitted
    // atom is one any more, and matching it skipped a sidecar named like a
    // module of the build (`runtime.erl` beside `rakun/runtime`), which was
    // then never shipped and died `undef`.
    // Each atom maps to the module that emits it, for the collision below.
    var emitted = std.StringHashMapUnmanaged([]const u8){};
    for (outputs) |o| {
        if (o.result.failed()) continue;
        try putModuleAtoms(arena, &emitted, o.result.js, text, o.name);
        for (o.result.units) |u| {
            try emitted.put(arena, u.atom, o.name);
            try putModuleAtoms(arena, &emitted, u.code, text, o.name);
        }
    }

    // Resolved lazily on the first unknown qualifier (most builds have none).
    var roots: ?[][]const u8 = null;
    defer if (roots) |r| freeRoots(gpa, r);
    var project: ProjectManifest = .{};

    var shipped = std.StringHashMapUnmanaged(void){};
    // Both answers below depend only on the roots on disk and the project's
    // manifest, which one run reads once — so each is asked once per run.
    // `owners`: lib → the package `sidecarOwner` resolved it to (null: none).
    // `misses`: `<owner>\x00<atom>` pairs already probed and not found — an OTP
    // qualifier (`lists:`, `maps:`) is not a sidecar and never becomes one.
    // Without them every OTP call in every dependency module re-ran
    // `manifest.scanRoots` over every library root, reading every workspace
    // manifest again: measured on emilia's `emilia-backgrounds` (1 849 emitted
    // modules), its erlang cell went from ~51 s to ~11 s with nothing else
    // changed.
    var owners = std.StringHashMapUnmanaged(?SidecarOwner){};
    var misses = std.StringHashMapUnmanaged(void){};
    // Every atom no sidecar answers, with the first module that calls it —
    // asked of the Erlang code path once, after the scan.
    var unresolved: std.StringArrayHashMapUnmanaged(ErlMiss) = .empty;
    var guarded = std.StringHashMapUnmanaged(void){};

    // A sidecar named like an atom this build emits (`<pkg>@<path>.erl`) is
    // never consulted — every qualifier naming that atom is the emitted
    // module's — and on the code path the two would be one module. Refused
    // before anything is shipped, naming both (C-25). Every package of the
    // build is looked at, the project's own `src` included.
    {
        var dirs: std.ArrayListUnmanaged([]const u8) = .empty;
        try dirs.append(arena, if (project.get(arena, io)) |p| p.src else "src/");
        var seen_libs = std.StringHashMapUnmanaged(void){};
        for (outputs) |o| {
            if (o.result.failed()) continue;
            const lib = sidecarPackage(packages, o.name) orelse continue;
            if (seen_libs.contains(lib)) continue;
            try seen_libs.put(arena, lib, {});
            if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
            const found = owners.get(lib) orelse found: {
                var oerr: ?manifest.Located = null;
                const f = try sidecarOwner(gpa, arena, io, roots.?, env_map, project.get(arena, io), lib, &oerr);
                // A refusal is the main scan's to print, at its first use.
                if (f != null or oerr == null) try owners.put(arena, lib, f);
                break :found f;
            };
            if (found) |pkg| try dirs.append(arena, try pkg.srcDir(arena));
        }
        var refused = false;
        for (dirs.items) |src_dir| {
            for ([_][]const u8{ try std.fs.path.join(arena, &.{ src_dir, "sidecars" }), src_dir }) |dir_path| {
                var dir = std.Io.Dir.cwd().openDir(io, dir_path, .{ .iterate = true }) catch continue;
                defer dir.close(io);
                var it = dir.iterate();
                while (try it.next(io)) |entry| {
                    if (entry.kind != .file and entry.kind != .sym_link) continue;
                    if (!std.mem.endsWith(u8, entry.name, ".erl")) continue;
                    const stem = entry.name[0 .. entry.name.len - ".erl".len];
                    const module = emitted.get(stem) orelse continue;
                    const path = try std.fs.path.join(arena, &.{ dir_path, entry.name });
                    sidecarNamedLikeAtom(arena, io, path, stem, module).print();
                    refused = true;
                }
            }
        }
        if (refused) return error.SidecarRefused;
    }

    for (outputs) |o| {
        if (o.result.failed()) continue;
        // The owning lib is the package the build's module table gives the
        // module (`sidecarPackage`), never the first segment of its name: a
        // module in a folder of the project (`orm/entity`) is the project's,
        // whatever package a library root happens to carry under `orm`.
        const owner = sidecarPackage(packages, o.name);

        // Comments out: a `%%` line quoting `std@erlang:self()` is prose.
        var texts: std.ArrayListUnmanaged([]const u8) = .empty;
        try texts.append(arena, try blankErlComments(arena, o.result.js));
        for (o.result.units) |u| try texts.append(arena, try blankErlComments(arena, u.code));
        for (texts.items) |emitted_text| {
            var it = HostModuleIterator{ .text = emitted_text, .kind = text };
            while (it.next()) |atom| {
                if (emitted.contains(atom)) continue;
                // `case code:ensure_loaded(m) of {module, _} -> m:f(); _ -> … end`
                // handles the module's absence itself — an optional host module
                // another package of the program may ship (`rakun-web` reaching
                // `rakun-app`'s `rakun_file_router`). It is shipped when a
                // package of this build carries it, and never refused.
                if (ensuresLoaded(emitted_text, atom, text)) try guarded.put(arena, try arena.dupe(u8, atom), {});
                if (shipped.contains(atom)) continue;
                const miss_key = try std.fmt.allocPrint(arena, "{s}\x00{s}", .{ owner orelse "", atom });
                if (misses.contains(miss_key)) continue;

                const base = try std.fmt.allocPrint(arena, "{s}.erl", .{atom});
                const target = try std.fs.path.join(arena, &.{ out_dir, base });

                var probed: [2][]const u8 = undefined;
                var pkg_manifest: ?manifest.Manifest = null;
                var src_dir_of_owner: ?[]const u8 = null;
                const src_path: ?[]const u8 = blk: {
                    if (owner) |lib| {
                        if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                        // Same owner lookup as the `.mjs` shipper: the directory the
                        // build resolved the dependency to, and that package's `src`.
                        const found = owners.get(lib) orelse found: {
                            var oerr: ?manifest.Located = null;
                            const f = try sidecarOwner(gpa, arena, io, roots.?, env_map, project.get(arena, io), lib, &oerr);
                            if (f == null) if (oerr) |located| return refuseSidecar(located);
                            try owners.put(arena, lib, f);
                            break :found f;
                        };
                        // No package on disk: the embedded `std`, whose
                        // sources are in the binary — it probes the project's
                        // `src` below, and an atom found nowhere is asked of
                        // the code path.
                        if (found) |pkg| {
                            pkg_manifest = pkg.package;
                            const src_dir = try pkg.srcDir(arena);
                            src_dir_of_owner = src_dir;
                            probed = .{ try std.fs.path.join(arena, &.{ src_dir, "sidecars", base }), try std.fs.path.join(arena, &.{ src_dir, base }) };
                        }
                    }
                    if (src_dir_of_owner == null) {
                        const own_src = if (project.get(arena, io)) |p| p.src else "src/";
                        src_dir_of_owner = own_src;
                        probed = .{ try std.fs.path.join(arena, &.{ own_src, "sidecars", base }), try std.fs.path.join(arena, &.{ own_src, base }) };
                    }
                    for (probed) |cand| if (fileExists(io, cand)) break :blk cand;
                    break :blk null;
                };
                const src = src_path orelse {
                    try misses.put(arena, miss_key, {});
                    const gop = try unresolved.getOrPut(arena, try arena.dupe(u8, atom));
                    if (!gop.found_existing) gop.value_ptr.* = .{
                        .module = o.name,
                        .source = o.src,
                        .src_dir = src_dir_of_owner.?,
                        // A package the build resolved; a project folder
                        // and the embedded `std` name none.
                        .owner = if (pkg_manifest != null) owner else null,
                        .owner_pkg = pkg_manifest,
                        .probed = probed,
                    };
                    continue;
                };

                const data = std.Io.Dir.cwd().readFileAlloc(io, src, arena, .unlimited) catch |err|
                    return refuseSidecar(try unreadableSidecar(arena, project.get(arena, io), owner, o.name, base, src, err));
                if (std.fs.path.dirname(target)) |parent| {
                    std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                        error.PathAlreadyExists => {},
                        else => return err,
                    };
                }
                try placeFile(arena, io, target, data);
                try shipped.put(arena, try arena.dupe(u8, atom), {});
            }
        }
    }

    // An atom that is neither a module of this build nor a sidecar of its
    // owner must be a module of the Erlang code path (`lists`, `crypto`, a
    // preloaded `erlang`). One that is not is a sidecar the library names and
    // does not carry: the program would die with `undef` at the first call.
    //
    // A host module is the BUILD's, not only its caller's package's: a
    // `rakun-web` template reaching `rakun_file_router` (which `rakun` keeps)
    // is answered by the package that carries it. So an atom still unresolved
    // is looked for under every package of the build before the code path is
    // asked, and shipped from the first that has it.
    if (unresolved.count() > 0) {
        var pkgs: std.ArrayListUnmanaged(SidecarOwner) = .empty;
        var seen_libs = std.StringHashMapUnmanaged(void){};
        for (outputs) |o| {
            if (o.result.failed()) continue;
            const lib = sidecarPackage(packages, o.name) orelse continue;
            if (seen_libs.contains(lib)) continue;
            try seen_libs.put(arena, lib, {});
            const found = owners.get(lib) orelse found: {
                if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                var oerr: ?manifest.Located = null;
                const f = try sidecarOwner(gpa, arena, io, roots.?, env_map, project.get(arena, io), lib, &oerr);
                try owners.put(arena, lib, f);
                break :found f;
            };
            if (found) |pkg| try pkgs.append(arena, pkg);
        }
        var still: std.ArrayListUnmanaged([]const u8) = .empty;
        for (unresolved.keys()) |atom| {
            if (shipped.contains(atom)) continue;
            const is_guarded = guarded.contains(atom);
            const base = try std.fmt.allocPrint(arena, "{s}.erl", .{atom});
            const src: ?[]const u8 = blk: for (pkgs.items) |pkg| {
                const src_dir = try pkg.srcDir(arena);
                for ([_][]const u8{ try std.fs.path.join(arena, &.{ src_dir, "sidecars", base }), try std.fs.path.join(arena, &.{ src_dir, base }) }) |cand| {
                    if (fileExists(io, cand)) break :blk cand;
                }
            } else null;
            const from = src orelse {
                if (!is_guarded) try still.append(arena, atom);
                continue;
            };
            const data = std.Io.Dir.cwd().readFileAlloc(io, from, arena, .unlimited) catch |err| {
                const miss = unresolved.get(atom).?;
                return refuseSidecar(try unreadableSidecar(arena, project.get(arena, io), miss.owner, miss.module, base, from, err));
            };
            const target = try std.fs.path.join(arena, &.{ out_dir, base });
            if (std.fs.path.dirname(target)) |parent| {
                std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            }
            try placeFile(arena, io, target, data);
            try shipped.put(arena, atom, {});
        }
        if (still.items.len == 0) return shipped.count();
        const absent = try absentFromCodePath(arena, io, still.items);
        var refused = false;
        for (absent) |atom| {
            const miss = unresolved.get(atom).?;
            locateErlMiss(arena, project.get(arena, io), atom, miss).print();
            refused = true;
        }
        if (refused) return error.SidecarRefused;
    }
    return shipped.count();
}

/// `text` with every erlang comment — `%` to the end of the line, outside a
/// string, a quoted atom and a `$c` character literal — and every string's
/// contents blanked to spaces, so the qualifier scan reads code only: a CSS
/// string `"from:var(…)"` is not a call to a module `from`. Same length, same
/// line structure; a quoted atom is kept (it may be a module).
fn blankErlComments(arena: std.mem.Allocator, text: []const u8) ![]const u8 {
    const out = try arena.dupe(u8, text);
    var i: usize = 0;
    var quote: u8 = 0;
    while (i < out.len) : (i += 1) {
        const c = out[i];
        if (quote != 0) {
            if (c == '\\') {
                if (quote == '"') {
                    out[i] = ' ';
                    if (i + 1 < out.len and out[i + 1] != '\n') out[i + 1] = ' ';
                }
                i += 1;
            } else if (c == quote) {
                quote = 0;
            } else if (quote == '"' and c != '\n') out[i] = ' ';
            continue;
        }
        switch (c) {
            '"', '\'' => quote = c,
            '$' => i += if (i + 1 < out.len and out[i + 1] == '\\') 2 else 1,
            '%' => while (i < out.len and out[i] != '\n') : (i += 1) {
                out[i] = ' ';
            },
            else => {},
        }
    }
    return out;
}

test "blankErlComments: comments and string contents go, char literals and quoted atoms stay" {
    const a = std.testing.allocator;
    var arena_inst = std.heap.ArenaAllocator.init(a);
    defer arena_inst.deinit();
    const got = try blankErlComments(arena_inst.allocator(), "%% std@erlang:self()\nf() -> io:format(\"a:b(%\\\"\"), $%, 'm':y(). % z:w()\n");
    try std.testing.expectEqualStrings("                    \nf() -> io:format(\"       \"), $%, 'm':y().        \n", got);
}

/// Whether `text` guards calls into `atom` with `code:ensure_loaded(atom)` —
/// the code answers the module's absence itself. In BEAM assembly the same
/// guard is the atom moved into `{x, 0}` by the instruction right before the
/// `{extfunc, code, ensure_loaded, 1}` call.
fn ensuresLoaded(text: []const u8, atom: []const u8, kind: HostText) bool {
    switch (kind) {
        .erlang => {
            const key = "code:ensure_loaded(";
            var i: usize = 0;
            while (std.mem.indexOfPos(u8, text, i, key)) |at| {
                const start = at + key.len;
                i = start;
                if (std.mem.startsWith(u8, text[start..], atom) and start + atom.len < text.len and text[start + atom.len] == ')') return true;
            }
            return false;
        },
        .beam => {
            const key = "{extfunc, code, ensure_loaded, 1}";
            var i: usize = 0;
            while (std.mem.indexOfPos(u8, text, i, key)) |at| {
                i = at + key.len;
                // The instruction before the call: the previous line.
                const line_start = if (std.mem.lastIndexOfScalar(u8, text[0..at], '\n')) |nl| nl else continue;
                const prev_start = if (std.mem.lastIndexOfScalar(u8, text[0..line_start], '\n')) |nl| nl + 1 else 0;
                const prev = text[prev_start..line_start];
                const lead = "{atom, ";
                const a = std.mem.indexOf(u8, prev, lead) orelse continue;
                const rest = prev[a + lead.len ..];
                if (std.mem.startsWith(u8, rest, atom) and rest.len > atom.len and rest[atom.len] == '}') return true;
            }
            return false;
        },
    }
}

test "ensuresLoaded: the guard names the atom exactly" {
    try std.testing.expect(ensuresLoaded("case code:ensure_loaded(rk_fr) of {module, _} -> rk_fr:t(); _ -> 0 end", "rk_fr", .erlang));
    try std.testing.expect(!ensuresLoaded("case code:ensure_loaded(rk_frx) of _ -> 0 end", "rk_fr", .erlang));
    try std.testing.expect(!ensuresLoaded("rk_fr:t()", "rk_fr", .erlang));
}

test "ensuresLoaded: in BEAM assembly the guard is the atom moved right before the call" {
    const guarded =
        \\    {move, {atom, rk_fr}, {x, 0}}.
        \\    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
        \\    {call_ext, 0, {extfunc, rk_fr, t, 0}}.
        \\
    ;
    try std.testing.expect(ensuresLoaded(guarded, "rk_fr", .beam));
    try std.testing.expect(!ensuresLoaded(guarded, "rk_f", .beam));
    const unguarded =
        \\    {move, {atom, rk_fr}, {x, 0}}.
        \\    {call_ext, 0, {extfunc, rk_fr, t, 0}}.
        \\
    ;
    try std.testing.expect(!ensuresLoaded(unguarded, "rk_fr", .beam));
}

/// The first module of a build that calls a host module no sidecar answers.
const ErlMiss = struct {
    /// The emitted module's name (`rakun/http`, `main`).
    module: []const u8,
    /// Its botopink source, to locate the call.
    source: []const u8,
    /// The `src` directory of the package the module belongs to.
    src_dir: []const u8,
    owner: ?[]const u8,
    owner_pkg: ?manifest.Manifest,
    /// Where the sidecar was looked for: `<src>/sidecars/<atom>.erl`, then `<src>/<atom>.erl`.
    probed: [2][]const u8,
};

/// Every module an emitted text declares: the `-module(<atom>).` attribute of
/// erlang source, the `{module, <atom>}.` form of BEAM assembly.
fn putModuleAtoms(arena: std.mem.Allocator, set: *std.StringHashMapUnmanaged([]const u8), text: []const u8, kind: HostText, module: []const u8) !void {
    const key, const close_char: u8 = switch (kind) {
        .erlang => .{ "-module(", ')' },
        .beam => .{ "{module, ", '}' },
    };
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, text, i, key)) |at| {
        const start = at + key.len;
        const close = std.mem.indexOfScalarPos(u8, text, start, close_char) orelse return;
        i = close;
        // The assembly's form starts its line; an operand `{module, …}` of a
        // literal does not.
        if (kind == .beam and at > 0 and text[at - 1] != '\n') continue;
        var atom = text[start..close];
        if (atom.len >= 2 and atom[0] == '\'' and atom[atom.len - 1] == '\'') atom = atom[1 .. atom.len - 1];
        try set.put(arena, atom, module);
    }
}

/// The refusal for a sidecar file named like a module atom the build emits:
/// located on the file's own `-module(…)` attribute (its first line when it
/// has none), naming the module the atom belongs to.
fn sidecarNamedLikeAtom(arena: std.mem.Allocator, io: std.Io, path: []const u8, atom: []const u8, module: []const u8) manifest.Located {
    const message = std.fmt.allocPrint(
        arena,
        "the sidecar {s} is named like the module atom '{s}', which module '{s}' of this build compiles to — the code path cannot hold both; rename the sidecar",
        .{ path, atom, module },
    ) catch "a sidecar is named like a module atom this build emits";
    const source = std.Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(16 * 1024 * 1024)) catch "";
    const key = "-module(";
    const at: usize, const span: usize = if (std.mem.indexOf(u8, source, key)) |i| .{ i, key.len } else .{ 0, 1 };
    var line: usize = 1;
    var line_start: usize = 0;
    for (source[0..at], 0..) |c, i| if (c == '\n') {
        line += 1;
        line_start = i + 1;
    };
    return .{ .message = message, .file = path, .source = source, .line = line, .col = at - line_start + 1, .span = span };
}

test "putModuleAtoms reads the module form of each emitted text" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    var set = std.StringHashMapUnmanaged([]const u8){};
    try putModuleAtoms(arena, &set,
        \\-module(app@main).
        \\-export([main/0]).
    , .erlang, "m");
    try putModuleAtoms(arena, &set,
        \\{module, app@text}.
        \\{exports, []}.
        \\    {move, {literal, {module, not_a_form}}, {x, 0}}.
    , .beam, "m");
    try putModuleAtoms(arena, &set,
        \\{module, 'app@main@@Shape'}.
    , .beam, "m");
    try std.testing.expect(set.contains("app@main"));
    try std.testing.expect(set.contains("app@text"));
    try std.testing.expect(set.contains("app@main@@Shape"));
    try std.testing.expectEqual(@as(u32, 3), set.count());
}

/// The atoms of `atoms` the Erlang code path does not hold — asked of `erl`
/// itself, once (`code:which/1` answers `non_existing`). A missing `erl` is a
/// refusal: without it no qualifier can be told from a missing sidecar, and
/// the program could not run anyway.
fn absentFromCodePath(arena: std.mem.Allocator, io: std.Io, atoms: []const []const u8) ![]const []const u8 {
    // The atoms go through a list file: one per host module on the `-eval`
    // made a single argument that grows with the program, and Linux refuses
    // one above 128 KiB (`arglist.zig`).
    const list = try arglist.write(arena, io, atoms);
    defer arglist.remove(io, list);
    // A job of the command's `erl` session (`otp.zig`) when one is open.
    const argv: []const []const u8 = &.{ "erl", "-noshell", "-noinput", "-eval", CODE_PATH_EVAL, "-extra", list };
    const result = otp.job(arena, io, CODE_PATH_EVAL, argv[6..], 1) catch |err| {
        reporter.print("\x1b[1m\x1b[31merror\x1b[0m: the emitted erlang calls host modules ({d}), and {s} to tell an OTP module from a missing sidecar\n", .{ atoms.len, arglist.spawnError(arena, "erl", argv, err) });
        return error.SidecarRefused;
    };
    if (result.code != 0) {
        // Its stderr is already printed, above this line.
        reporter.print("\x1b[1m\x1b[31merror\x1b[0m: `erl` failed while looking up the host modules the emitted erlang calls\n", .{});
        return error.SidecarRefused;
    }
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = std.mem.tokenizeAny(u8, result.stdout, "\r\n");
    while (it.next()) |line| {
        for (atoms) |a| if (std.mem.eql(u8, a, line)) {
            try out.append(arena, a);
            break;
        };
    }
    return out.items;
}

/// `absentFromCodePath`'s `erl`: the one plain argument is the list file of
/// atoms; each one `code:which/1` does not find is printed on its own line.
const CODE_PATH_EVAL =
    \\[ListFile] = init:get_plain_arguments(),
++ arglist.READ_LIST("Atoms", "ListFile") ++
    \\lists:foreach(fun(A) -> M = list_to_atom(A), case code:which(M) of non_existing -> io:format("~s~n", [M]); _ -> ok end end, Atoms),
    \\halt().
;

/// The refusal for a host module that is neither shipped nor in the code
/// path, located on the botopink line that names it — the `"<atom>"` of an
/// `#[@external(.Erlang("<atom>:…"))]`, or an `<atom>:` in a template — and on
/// the manifest when the source spells it nowhere.
fn locateErlMiss(arena: std.mem.Allocator, proj: ?manifest.Manifest, atom: []const u8, miss: ErlMiss) manifest.Located {
    const whose = if (miss.owner) |lib|
        std.fmt.allocPrint(arena, "dependency '{s}'", .{lib}) catch "its dependency"
    else
        "this project";
    const fixed = std.fmt.allocPrint(
        arena,
        "module '{s}' calls the erlang module '{s}', which is not a module of this build, not in the Erlang code path, and not a sidecar of {s} (looked at {s}, then {s})",
        .{ miss.module, atom, whose, miss.probed[0], miss.probed[1] },
    ) catch "an erlang host module is neither shipped nor in the code path";
    const quoted = std.fmt.allocPrint(arena, "\"{s}\"", .{atom}) catch atom;
    const colon = std.fmt.allocPrint(arena, "{s}:", .{atom}) catch atom;
    const hit: ?struct { at: usize, len: usize } = if (std.mem.indexOf(u8, miss.source, quoted)) |at|
        .{ .at = at + 1, .len = atom.len }
    else if (std.mem.indexOf(u8, miss.source, colon)) |at|
        .{ .at = at, .len = atom.len }
    else
        null;
    if (hit) |h| {
        const stem = if (miss.owner) |lib| miss.module[lib.len + 1 ..] else miss.module;
        const file = std.fs.path.join(arena, &.{ miss.src_dir, stem }) catch stem;
        const with_ext = std.fmt.allocPrint(arena, "{s}.bp", .{file}) catch file;
        var line: usize = 1;
        var line_start: usize = 0;
        for (miss.source[0..h.at], 0..) |c, i| if (c == '\n') {
            line += 1;
            line_start = i + 1;
        };
        return .{ .message = fixed, .file = with_ext, .source = miss.source, .line = line, .col = h.at - line_start + 1, .span = h.len };
    }
    return sidecarLocation(proj, miss.owner, miss.owner_pkg, fixed);
}

/// Which emitted text `shipErlSidecars` reads its host modules out of.
pub const HostText = enum {
    /// Erlang source: a host call is `host:fn(…)`.
    erlang,
    /// BEAM assembly: a host call is `{extfunc, host, fn, N}`.
    beam,
};

/// The host module of every remote call in an emitted text, whichever of the
/// two it is.
const HostModuleIterator = struct {
    text: []const u8,
    kind: HostText,
    pos: usize = 0,

    fn next(self: *HostModuleIterator) ?[]const u8 {
        switch (self.kind) {
            .erlang => {
                var it = QualifierIterator{ .text = self.text, .pos = self.pos };
                defer self.pos = it.pos;
                return it.next();
            },
            .beam => {
                var it = ExtfuncIterator{ .text = self.text, .pos = self.pos };
                defer self.pos = it.pos;
                return it.next();
            },
        }
    }
};

/// Walks the `{extfunc, <module>, <function>, <arity>}` operands of emitted
/// BEAM assembly and yields each module atom — unquoted, or the contents of a
/// quoted one. Comments and string contents are blanked before the walk
/// (`blankErlComments`), so a literal that spells the operand is not one.
const ExtfuncIterator = struct {
    text: []const u8,
    pos: usize = 0,

    const lead = "{extfunc, ";

    fn next(self: *ExtfuncIterator) ?[]const u8 {
        while (std.mem.indexOfPos(u8, self.text, self.pos, lead)) |at| {
            var i = at + lead.len;
            self.pos = i;
            if (i >= self.text.len) return null;
            if (self.text[i] == '\'') {
                const close = std.mem.indexOfScalarPos(u8, self.text, i + 1, '\'') orelse return null;
                self.pos = close + 1;
                if (close + 1 < self.text.len and self.text[close + 1] == ',') return self.text[i + 1 .. close];
                continue;
            }
            const start = i;
            while (i < self.text.len and isAtomChar(self.text[i])) i += 1;
            self.pos = i;
            if (i == start or !std.ascii.isLower(self.text[start])) continue;
            if (i < self.text.len and self.text[i] == ',') return self.text[start..i];
        }
        self.pos = self.text.len;
        return null;
    }
};

test "ExtfuncIterator yields the module atom of every remote call" {
    var it = HostModuleIterator{ .kind = .beam, .text =
        \\    {call_ext, 1, {extfunc, hostlib_native, greet, 1}}.
        \\    {call, 1, {f, 9}}.
        \\    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.
        \\    {call_ext, 0, {extfunc, 'app@main@@Shape', '__bp_format', 1}}.
        \\    {call_ext_only, 0, {extfunc, std@beam, ptPut, 2}}.
    };
    var seen: std.ArrayListUnmanaged([]const u8) = .empty;
    defer seen.deinit(std.testing.allocator);
    while (it.next()) |a| try seen.append(std.testing.allocator, a);
    try std.testing.expectEqual(@as(usize, 4), seen.items.len);
    try std.testing.expectEqualStrings("hostlib_native", seen.items[0]);
    try std.testing.expectEqualStrings("io", seen.items[1]);
    try std.testing.expectEqualStrings("app@main@@Shape", seen.items[2]);
    try std.testing.expectEqualStrings("std@beam", seen.items[3]);
}

/// Walks the `atom:` qualifiers of emitted erlang text. An erlang module atom
/// is unquoted lower-case `[a-z][a-zA-Z0-9_@]*`; the iterator yields one per
/// `atom:` occurrence that is followed by a call head (`name(` or `'name'(`),
/// skipping `::` and a qualifier preceded by an identifier character (so
/// `Foo.bar:baz` and record fields are not mistaken for one).
const QualifierIterator = struct {
    text: []const u8,
    pos: usize = 0,

    fn next(self: *QualifierIterator) ?[]const u8 {
        while (self.pos < self.text.len) {
            const colon = std.mem.indexOfScalarPos(u8, self.text, self.pos, ':') orelse return null;
            self.pos = colon + 1;
            if (colon + 1 < self.text.len and self.text[colon + 1] == ':') {
                self.pos = colon + 2;
                continue;
            }
            // Walk back over the atom.
            var start = colon;
            while (start > 0 and isAtomChar(self.text[start - 1])) start -= 1;
            if (start == colon) continue;
            if (!std.ascii.isLower(self.text[start])) continue;
            if (start > 0 and (self.text[start - 1] == '.' or self.text[start - 1] == '\'' or self.text[start - 1] == '"')) continue;
            // A call head must follow: `fn(` or `'fn'(`.
            var i = colon + 1;
            if (i < self.text.len and self.text[i] == '\'') {
                i += 1;
                while (i < self.text.len and self.text[i] != '\'') i += 1;
                if (i >= self.text.len) continue;
                i += 1;
            } else {
                const fn_start = i;
                while (i < self.text.len and isAtomChar(self.text[i])) i += 1;
                if (i == fn_start) continue;
            }
            if (i >= self.text.len or self.text[i] != '(') continue;
            return self.text[start..colon];
        }
        return null;
    }
};

fn isAtomChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_' or c == '@';
}

/// `text` with each `require(<from>)` of `rewrites` — `up` before both paths —
/// spelled `require(<to>)`, in either quote style.
fn rewriteRequires(arena: std.mem.Allocator, text: []const u8, rewrites: []const [2][]const u8, up: []const u8) ![]const u8 {
    var out = text;
    for (rewrites) |r| {
        for ([_]u8{ '"', '\'' }) |q| {
            const from = try std.fmt.allocPrint(arena, "require({c}{s}{s}{c})", .{ q, up, r[0], q });
            const to = try std.fmt.allocPrint(arena, "require({c}{s}{s}{c})", .{ q, up, r[1], q });
            out = try std.mem.replaceOwned(u8, arena, out, from, to);
        }
    }
    return out;
}

fn fileExists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "QualifierIterator yields the module atom of every qualified call" {
    var it = QualifierIterator{ .text =
        \\greet(Name) ->
        \\    hostlib_native:greet(Name).
        \\encode(S) ->
        \\    Raw = base64:encode(S),
        \\    '__bp_print'([Raw]),
        \\    lists:foldl(fun(A, B) -> A + B end, 0, [1]).
    };
    var seen: std.ArrayListUnmanaged([]const u8) = .empty;
    defer seen.deinit(std.testing.allocator);
    while (it.next()) |a| try seen.append(std.testing.allocator, a);
    try std.testing.expectEqual(@as(usize, 3), seen.items.len);
    try std.testing.expectEqualStrings("hostlib_native", seen.items[0]);
    try std.testing.expectEqualStrings("base64", seen.items[1]);
    try std.testing.expectEqualStrings("lists", seen.items[2]);
}

test "QualifierIterator skips what is not a module qualifier" {
    // `::` (a type spec), an upper-case variable, a bare atom with no call
    // head, a quoted local call, and a map/record `key: value`.
    var it = QualifierIterator{ .text =
        \\-spec greet(binary()) -> binary().
        \\f() ->
        \\    Mod:apply(),
        \\    ok:thing,
        \\    '__bp_print'([1]),
        \\    #{name := V}.
    };
    try std.testing.expectEqual(@as(?[]const u8, null), it.next());
}

test "QualifierIterator reads a quoted function name after the module atom" {
    var it = QualifierIterator{ .text = "    myhost:'do it'(X)." };
    const a = it.next() orelse return error.TestExpectedQualifier;
    try std.testing.expectEqualStrings("myhost", a);
}

test "rewriteRequires spells a sidecar's flat name from the module and from its unit (1015)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const rw = [_][2][]const u8{.{ "../../src/onze.mjs", "./onze@onze.mjs" }};
    try std.testing.expectEqualStrings("require('./onze@onze.mjs').f()", try rewriteRequires(a, "require('../../src/onze.mjs').f()", &rw, ""));
    try std.testing.expectEqualStrings("require(\".././onze@onze.mjs\")", try rewriteRequires(a, "require(\"../../../src/onze.mjs\")", &rw, "../"));
}

test "stripSourceExt strips .bp; a .d.bp is the module x.d" {
    try std.testing.expectEqualStrings("rakun.d", stripSourceExt("rakun.d.bp"));
    try std.testing.expectEqualStrings("http", stripSourceExt("http.bp"));
    try std.testing.expectEqualStrings("page", stripSourceExt("page.botopink"));
    try std.testing.expectEqualStrings("noext", stripSourceExt("noext"));
}

test "loadDependencies with no deps touches no filesystem" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const proj = try config.parse(arena.allocator(),
        \\{ "name": "p" }
    );
    const mods = try loadDependencies(std.testing.allocator, std.testing.io, proj, null);
    defer freeModules(std.testing.allocator, mods);
    try std.testing.expectEqual(@as(usize, 0), mods.len);
}

test "resolveBpmpStoreRoot: BPMP_HOME wins" {
    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try map.put("BPMP_HOME", "/srv/bpmp");
    const r = try resolveBpmpStoreRoot(std.testing.allocator, &map);
    defer if (r) |s| std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("/srv/bpmp/store", r.?);
}

test "resolveBpmpStoreRoot: XDG_CACHE_HOME fallback" {
    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try map.put("XDG_CACHE_HOME", "/u/cache");
    const r = try resolveBpmpStoreRoot(std.testing.allocator, &map);
    defer if (r) |s| std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("/u/cache/bpmp/store", r.?);
}

test "resolveBpmpStoreRoot: HOME → ~/.cache/bpmp/store" {
    var map = std.process.Environ.Map.init(std.testing.allocator);
    defer map.deinit();
    try map.put("HOME", "/home/x");
    const r = try resolveBpmpStoreRoot(std.testing.allocator, &map);
    defer if (r) |s| std.testing.allocator.free(s);
    try std.testing.expectEqualStrings("/home/x/.cache/bpmp/store", r.?);
}

test "resolveBpmpStoreRoot: null env_map yields null" {
    const r = try resolveBpmpStoreRoot(std.testing.allocator, null);
    try std.testing.expectEqual(@as(?[]u8, null), r);
}

// Multi-root resolution. Each test materializes a synthetic tree under a unique
// relative dir (resolved against the test cwd) and drives `rootsFrom` / `loadOne`
// directly, so neither the process cwd nor the real repo layout is touched.

/// A shipped file (a sidecar, a module whose `require`s were rewritten): left
/// alone when it already holds `data`, else staged and renamed over it — the
/// members of one workspace folder ship the same files side by side (decision
/// 1006 (5)), and none reads one half written.
fn placeFile(arena: std.mem.Allocator, io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.Io.Dir.cwd().readFileAlloc(io, path, arena, .limited(data.len + 1))) |have| {
        if (std.mem.eql(u8, have, data)) return;
    } else |_| {}
    try analysis_store.write(arena, io, path, data);
}

fn writeFileP(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

test "resolveLibRoots: repository workspace yields [bundled libs, repository]" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "roots-repo");
    defer test_scratch.remove(io, "roots-repo");
    try writeFileP(io, test_scratch.path(io, "roots-repo/ws/repository/botopink-lang/libs/std/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "roots-repo/ws/repository/rakun/botopink.json"), "{}");

    // A consumer under repository/rakun resolves up to `ws`, where both roots fire.
    const roots = try rootsFrom(gpa, io, &.{}, test_scratch.path(io, "roots-repo/ws/repository/rakun"));
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-repo/ws/repository/botopink-lang/libs"), roots[0]);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-repo/ws/repository"), roots[1]);
}

test "resolveLibRoots: flat libs/ tree yields a single legacy root" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = test_scratch.path(io, "roots-flat/ws");
    test_scratch.remove(io, "roots-flat");
    defer test_scratch.remove(io, "roots-flat");
    try writeFileP(io, test_scratch.path(io, "roots-flat/ws/libs/std/botopink.json"), "{}");

    const roots = try rootsFrom(gpa, io, &.{}, ws);
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-flat/ws/libs"), roots[0]);
}

// ── BOTOPINK_LIB_ROOTS env-hook tests ──────────────────────────────────────────
//
// The env-aware path is driven through `parseEnvRootsString` (so a synthetic
// string stands in for the actual env var) plus the splittable `rootsFrom` (so
// the prepend + de-dup interaction is exercised without touching cwd).

test "parseEnvRootsString: empty value yields no roots" {
    const gpa = std.testing.allocator;
    const roots = try parseEnvRootsString(gpa, "", "/cwd");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRootsString: drops empty entries and trailing delimiter" {
    const gpa = std.testing.allocator;
    const sep = std.fs.path.delimiter;
    // `a` + `` + `b` + trailing `` → only `a`, `b` survive.
    const value = try std.fmt.allocPrint(gpa, "/a{c}{c}/b{c}", .{ sep, sep, sep });
    defer gpa.free(value);
    const roots = try parseEnvRootsString(gpa, value, "/cwd");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings("/a", roots[0]);
    try std.testing.expectEqualStrings("/b", roots[1]);
}

test "parseEnvRootsString: relative entries resolve against cwd" {
    const gpa = std.testing.allocator;
    const sep = std.fs.path.delimiter;
    const value = try std.fmt.allocPrint(gpa, "rel/one{c}/abs/two", .{sep});
    defer gpa.free(value);
    const roots = try parseEnvRootsString(gpa, value, "/home/u");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings("/home/u/rel/one", roots[0]);
    try std.testing.expectEqualStrings("/abs/two", roots[1]);
}

test "rootsFrom: env entries prepend before walk-up roots" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "roots-env");
    defer test_scratch.remove(io, "roots-env");
    try writeFileP(io, test_scratch.path(io, "roots-env/ws/store/erika/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "roots-env/ws/repository/rakun/botopink.json"), "{}");

    const env_roots = [_][]const u8{test_scratch.path(io, "roots-env/ws/store")};
    const roots = try rootsFrom(gpa, io, &env_roots, test_scratch.path(io, "roots-env/ws/repository/rakun"));
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-env/ws/store"), roots[0]);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-env/ws/repository"), roots[1]);
}

test "rootsFrom: the walk-up stops at the enclosing checkout (a nested worktree does not see its parent's repository/)" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "roots-nested");
    defer test_scratch.remove(io, "roots-nested");
    try writeFileP(io, test_scratch.path(io, "roots-nested/main/repository/lib/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "roots-nested/main/libs/std/botopink.json"), "{}");
    try writeFileP(io, test_scratch.path(io, "roots-nested/main/.tasks/wt/repository/lib/botopink.json"), "{}");

    const roots = try rootsFrom(gpa, io, &.{}, test_scratch.path(io, "roots-nested/main/.tasks/wt/repository/lib"));
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-nested/main/.tasks/wt/repository"), roots[0]);
}

test "rootsFrom: non-existent env entry is silently dropped" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = test_scratch.path(io, "roots-envmiss/ws");
    test_scratch.remove(io, "roots-envmiss");
    defer test_scratch.remove(io, "roots-envmiss");
    try writeFileP(io, test_scratch.path(io, "roots-envmiss/ws/libs/std/botopink.json"), "{}");

    const env_roots = [_][]const u8{test_scratch.path(io, "roots-envmiss/nope")};
    const roots = try rootsFrom(gpa, io, &env_roots, ws);
    defer freeRoots(gpa, roots);

    // Env entry dropped silently; only the walk-up `libs/` root fires.
    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-envmiss/ws/libs"), roots[0]);
}

test "rootsFrom: env entry duplicating a walk-up root de-dups env-first" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = test_scratch.path(io, "roots-envdup/ws");
    test_scratch.remove(io, "roots-envdup");
    defer test_scratch.remove(io, "roots-envdup");
    try writeFileP(io, test_scratch.path(io, "roots-envdup/ws/libs/std/botopink.json"), "{}");

    const env_roots = [_][]const u8{test_scratch.path(io, "roots-envdup/ws/libs")};
    const roots = try rootsFrom(gpa, io, &env_roots, ws);
    defer freeRoots(gpa, roots);

    // The walk-up duplicate is skipped — env copy wins, kept first.
    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-envdup/ws/libs"), roots[0]);
}

test "parseEnvRoots: null env_map → empty slice (byte-identical to unset)" {
    const gpa = std.testing.allocator;
    const roots = try parseEnvRoots(gpa, null, "/cwd");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRoots: env_map without BOTOPINK_LIB_ROOTS → empty slice" {
    const gpa = std.testing.allocator;
    var map = std.process.Environ.Map.init(gpa);
    defer map.deinit();
    try map.put("OTHER", "/x");
    const roots = try parseEnvRoots(gpa, &map, "/cwd");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRoots: BOTOPINK_LIB_ROOTS set is parsed" {
    const gpa = std.testing.allocator;
    var map = std.process.Environ.Map.init(gpa);
    defer map.deinit();
    const sep = std.fs.path.delimiter;
    const value = try std.fmt.allocPrint(gpa, "/a{c}/b", .{sep});
    defer gpa.free(value);
    try map.put(ENV_VAR, value);

    const roots = try parseEnvRoots(gpa, &map, "/cwd");
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings("/a", roots[0]);
    try std.testing.expectEqualStrings("/b", roots[1]);
}

/// Resolve `dep` by name across `roots` and load its files — the two steps
/// `loadDependencies` runs per entry, for a synthetic tree.
fn loadByName(gpa: std.mem.Allocator, io: std.Io, roots: []const []const u8, dep: []const u8, out: *std.ArrayListUnmanaged(Module)) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const entries = try manifest.scanRoots(arena.allocator(), io, roots);
    const e = manifest.find(entries, dep) orelse return error.LibNotFound;
    if (e.problem) |p| {
        p.print();
        return error.LibManifestInvalid;
    }
    try loadOne(gpa, io, e.dir, e.manifest.?, dep, out);
}

/// A scratch workspace `kit` under `<root>/ws/repository`: `kit-core`,
/// `kit-link` (→ kit-core) and `kit-forms` (→ kit-core, kit-link), every
/// dependency `{ "workspace": true }` — the shape of jhonstart's members.
fn writeKitWorkspace(io: std.Io, comptime root: []const u8) !void {
    const files = [_][2][]const u8{
        .{ "ws/repository/kit/botopink.json", "{ \"name\": \"kit\", \"workspaces\": [\"modules/*\"] }" },
        .{ "ws/repository/kit/modules/kit-core/botopink.json", "{ \"name\": \"kit-core\", \"files\": [\"core.bp\"] }" },
        .{ "ws/repository/kit/modules/kit-core/src/core.bp", "pub fn core() -> void {}" },
        .{ "ws/repository/kit/modules/kit-link/botopink.json", "{ \"name\": \"kit-link\", \"files\": [\"link.bp\"], \"dependencies\": { \"kit-core\": { \"workspace\": true } } }" },
        .{ "ws/repository/kit/modules/kit-link/src/link.bp", "import {core} from \"kit-core\";" },
        .{ "ws/repository/kit/modules/kit-forms/botopink.json", "{ \"name\": \"kit-forms\", \"files\": [\"forms.bp\"], \"dependencies\": { \"kit-link\": { \"workspace\": true }, \"kit-core\": { \"workspace\": true } } }" },
        .{ "ws/repository/kit/modules/kit-forms/src/forms.bp", "import {core} from \"kit-core\";" },
    };
    inline for (files) |f| try writeFileP(io, test_scratch.path(io, root ++ "/" ++ f[0]), f[1]);
}

/// `loadClosure` for the project manifest `text` at `<root>/app`, over the
/// roots `<root>/ws/repository`; the loaded module paths, joined by spaces.
fn closureOf(arena: std.mem.Allocator, io: std.Io, comptime root: []const u8, text: []const u8) ![]const u8 {
    const gpa = std.testing.allocator;
    const app_dir = test_scratch.path(io, root ++ "/app");
    const repo = test_scratch.path(io, root ++ "/ws/repository");
    var err: ?manifest.Located = null;
    const m = try manifest.parse(arena, text, try std.fmt.allocPrint(arena, "{s}/botopink.json", .{app_dir}), &err);
    const entries = try manifest.scanRoots(arena, io, &.{repo});
    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |mod| {
            gpa.free(mod.path);
            gpa.free(mod.source);
            gpa.free(mod.srcPath);
            if (mod.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    try loadClosure(gpa, io, arena, m, app_dir, null, m.dependencies, &.{entries}, &out, &.{}, null);
    var names: std.ArrayListUnmanaged(u8) = .empty;
    for (out.items, 0..) |mod, i| {
        if (i > 0) try names.append(arena, ' ');
        try names.appendSlice(arena, mod.path);
    }
    return names.items;
}

test "loadDependencies: a dependency's own dependencies load too, each before the packages that import it" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure");
    defer test_scratch.remove(io, "closure");
    try writeKitWorkspace(io, "closure");

    // A package outside the workspace that names only `kit-forms` gets the two
    // members it imports as well (jhonstart-forms → jhonstart, jhonstart-link).
    try std.testing.expectEqualStrings("kit-core/core kit-link/link kit-forms/forms", try closureOf(arena, io, "closure",
        \\{ "name": "app", "dependencies": { "kit-forms": { "git": "https://example.invalid/kit" } } }
    ));
    // Listed dependents-first, they still compile dependencies-first.
    try std.testing.expectEqualStrings("kit-core/core kit-link/link kit-forms/forms", try closureOf(arena, io, "closure",
        \\{ "name": "app", "dependencies": { "kit-forms": { "git": "https://example.invalid/kit" },
        \\  "kit-link": { "git": "https://example.invalid/kit" }, "kit-core": { "git": "https://example.invalid/kit" } } }
    ));
}

test "loadDependencies: packages compile and init by level — the most levels of dependencies last, ties as listed (decision 660)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure-level");
    defer test_scratch.remove(io, "closure-level");
    try writeKitWorkspace(io, "closure-level");
    try writeFileP(io, test_scratch.path(io, "closure-level/ws/repository/solo/botopink.json"), "{ \"name\": \"solo\", \"files\": [\"solo.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "closure-level/ws/repository/solo/src/solo.bp"), "pub fn solo() -> void {}");

    // `kit-forms` is listed first and depends on two levels of packages:
    // it goes last, after `solo`, which depends on nothing — depth first,
    // `solo` came after `kit-forms`.
    try std.testing.expectEqualStrings("kit-core/core solo/solo kit-link/link kit-forms/forms", try closureOf(arena, io, "closure-level",
        \\{ "name": "app", "dependencies": { "kit-forms": { "git": "https://example.invalid/kit" }, "solo": { "git": "https://example.invalid/solo" } } }
    ));
    // Two packages of one level keep the order their dependant lists them.
    try std.testing.expectEqualStrings("solo/solo kit-core/core kit-link/link", try closureOf(arena, io, "closure-level",
        \\{ "name": "app", "dependencies": { "solo": { "git": "https://example.invalid/solo" }, "kit-core": { "git": "https://example.invalid/kit" }, "kit-link": { "git": "https://example.invalid/kit" } } }
    ));
}

test "loadDependencies: one import name meaning two directories in one build is refused" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure-clash");
    defer test_scratch.remove(io, "closure-clash");
    try writeKitWorkspace(io, "closure-clash");
    try writeFileP(io, test_scratch.path(io, "closure-clash/other/kit-core/botopink.json"), "{ \"name\": \"kit-core\", \"files\": [\"core.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "closure-clash/other/kit-core/src/core.bp"), "pub fn core() -> void {}");

    // The project's `kit-core` is another directory than the one `kit-forms`
    // means by that name.
    try std.testing.expectError(error.LibManifestInvalid, closureOf(arena, io, "closure-clash",
        \\{ "name": "app", "dependencies": { "kit-core": { "path": "../other/kit-core" },
        \\  "kit-forms": { "git": "https://example.invalid/kit" } } }
    ));
}

test "loadDependencies: a dependency named like the project or a member of its workspace, at another directory, is refused naming both (144 B-60)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure-name-twice");
    defer test_scratch.remove(io, "closure-name-twice");
    try writeKitWorkspace(io, "closure-name-twice");
    // A second `kit-core`, outside the workspace, and a package named `app`.
    try writeFileP(io, test_scratch.path(io, "closure-name-twice/other/kit-core/botopink.json"), "{ \"name\": \"kit-core\", \"files\": [\"core.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "closure-name-twice/other/kit-core/src/core.bp"), "pub fn core() -> void {}");
    try writeFileP(io, test_scratch.path(io, "closure-name-twice/other/app/botopink.json"), "{ \"name\": \"app\", \"files\": [\"a.bp\"] }");
    try writeFileP(io, test_scratch.path(io, "closure-name-twice/other/app/src/a.bp"), "pub fn a() -> void {}");

    var captured: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer captured.deinit();
    manifest.sink = &captured.writer;
    defer manifest.sink = null;

    // The project's own name.
    try std.testing.expectError(error.LibManifestInvalid, closureOf(arena, io, "closure-name-twice",
        \\{ "name": "app", "dependencies": { "app": { "path": "../other/app" } } }
    ));
    const own = captured.written();
    try std.testing.expect(std.mem.indexOf(u8, own, "two packages named \"app\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, own, "other/app here and ") != null);
    try std.testing.expect(std.mem.indexOf(u8, own, "closure-name-twice/app — one name is one package") != null);
    try std.testing.expect(std.mem.indexOf(u8, own, "botopink.json:1:") != null);

    // A member of the project's workspace: `kit-forms` is one, and the
    // project names a `kit-core` the workspace's member is not.
    captured.clearRetainingCapacity();
    var werr: ?manifest.Located = null;
    const ws_dir = try std.Io.Dir.cwd().realPathFileAlloc(io, test_scratch.path(io, "closure-name-twice/ws/repository/kit"), arena);
    const ws = try manifest.expand(arena, io, try manifest.read(arena, io, ws_dir, &werr), &werr);
    const forms = ws.member("kit-forms").?;
    const gpa = std.testing.allocator;
    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |mod| {
            gpa.free(mod.path);
            gpa.free(mod.source);
            gpa.free(mod.srcPath);
            if (mod.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    var pm = forms.manifest;
    pm.dependencies = &.{.{ .name = "kit-core", .spec = .{ .path = "../../../../../other/kit-core" } }};
    try std.testing.expectError(error.LibManifestInvalid, loadClosure(gpa, io, arena, pm, forms.dir, ws, pm.dependencies, &.{}, &out, &.{}, null));
    const member = captured.written();
    try std.testing.expect(std.mem.indexOf(u8, member, "two packages named \"kit-core\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, member, "other/kit-core here and ") != null);
    try std.testing.expect(std.mem.indexOf(u8, member, "modules/kit-core — one name is one package") != null);

    // The member itself, reached as `{ "workspace": true }`, is no second package.
    captured.clearRetainingCapacity();
    pm.dependencies = &.{.{ .name = "kit-core", .spec = .{ .workspace = true } }};
    try loadClosure(gpa, io, arena, pm, forms.dir, ws, pm.dependencies, &.{}, &out, &.{}, null);
}

test "loadDependencies: a cycle between packages is refused" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "closure-cycle");
    defer test_scratch.remove(io, "closure-cycle");
    const files = [_][2][]const u8{
        .{ "closure-cycle/ws/repository/ring/botopink.json", "{ \"name\": \"ring\", \"workspaces\": [\"modules/*\"] }" },
        .{ "closure-cycle/ws/repository/ring/modules/ring-a/botopink.json", "{ \"name\": \"ring-a\", \"files\": [\"a.bp\"], \"dependencies\": { \"ring-b\": { \"workspace\": true } } }" },
        .{ "closure-cycle/ws/repository/ring/modules/ring-a/src/a.bp", "pub fn a() -> void {}" },
        .{ "closure-cycle/ws/repository/ring/modules/ring-b/botopink.json", "{ \"name\": \"ring-b\", \"files\": [\"b.bp\"], \"dependencies\": { \"ring-a\": { \"workspace\": true } } }" },
        .{ "closure-cycle/ws/repository/ring/modules/ring-b/src/b.bp", "pub fn b() -> void {}" },
    };
    inline for (files) |f| try writeFileP(io, test_scratch.path(io, f[0]), f[1]);
    try std.testing.expectError(error.LibManifestInvalid, closureOf(arena, io, "closure-cycle",
        \\{ "name": "app", "dependencies": { "ring-a": { "git": "https://example.invalid/ring" } } }
    ));
}

test "loadOne: std resolves from the bundled root, rakun from the sibling root; absent dep is LibNotFound" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "loadone");
    defer test_scratch.remove(io, "loadone");
    // `std` is the bundled lib (`libs/std`, of a checkout that holds
    // `modules/compiler-core` — decision 453); `rakun` is a sibling project.
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/botopink-lang/modules/compiler-core/src/root.zig"), "");
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/botopink-lang/libs/std/botopink.json"),
        \\{ "name": "std", "src": "src/", "files": ["math.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/botopink-lang/libs/std/src/math.bp"),
        \\pub fn abs() -> void {}
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/rakun/botopink.json"),
        \\{ "name": "rakun", "src": "src/", "files": ["rakun.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/rakun/src/rakun.bp"),
        \\pub fn run() -> void {}
    );

    const roots = [_][]const u8{
        test_scratch.path(io, "loadone/ws/repository/botopink-lang/libs"),
        test_scratch.path(io, "loadone/ws/repository"),
    };

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
            if (m.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }

    try loadByName(gpa, io, &roots, "std", &out); // bundled — first root
    try loadByName(gpa, io, &roots, "rakun", &out); // sibling — second root
    try std.testing.expectEqual(@as(usize, 2), out.items.len);
    try std.testing.expectEqualStrings("std/math", out.items[0].path);
    try std.testing.expect(std.mem.indexOf(u8, out.items[0].source, "abs") != null);
    try std.testing.expectEqualStrings("rakun/rakun", out.items[1].path);

    try std.testing.expectError(error.LibNotFound, loadByName(gpa, io, &roots, "absent", &out));
}

test "loadOne: a workspace member resolves by its manifest name through the umbrella under a root" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "loadone-ws");
    defer test_scratch.remove(io, "loadone-ws");
    try writeFileP(io, test_scratch.path(io, "loadone-ws/ws/repository/rakun/botopink.json"),
        \\{ "name": "rakun", "workspaces": ["modules/*"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone-ws/ws/repository/rakun/modules/rakun-web/botopink.json"),
        \\{ "name": "rakun-web", "files": ["root.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone-ws/ws/repository/rakun/modules/rakun-web/src/root.bp"),
        \\pub fn serve() -> void {}
    );
    const roots = [_][]const u8{test_scratch.path(io, "loadone-ws/ws/repository")};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
            if (m.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    try loadByName(gpa, io, &roots, "rakun-web", &out);
    try std.testing.expectEqual(@as(usize, 1), out.items.len);
    try std.testing.expectEqualStrings("rakun-web/root", out.items[0].path);
}

test "loadOne: a files entry that does not exist is LibFileNotFound, located in the manifest" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "loadone-missing");
    defer test_scratch.remove(io, "loadone-missing");
    try writeFileP(io, test_scratch.path(io, "loadone-missing/ws/repository/rakun/botopink.json"),
        \\{ "name": "rakun", "src": "src/",
        \\  "files": ["rakun.bp", "gone.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone-missing/ws/repository/rakun/src/rakun.bp"),
        \\pub fn run() -> void {}
    );
    const roots = [_][]const u8{test_scratch.path(io, "loadone-missing/ws/repository")};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
            if (m.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    try std.testing.expectError(error.LibFileNotFound, loadByName(gpa, io, &roots, "rakun", &out));
}

test "rootsFrom: an ancestor workspace is a root, nearest-first" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "roots-ws");
    defer test_scratch.remove(io, "roots-ws");
    try writeFileP(io, test_scratch.path(io, "roots-ws/ws/repository/rakun/botopink.json"),
        \\{ "name": "rakun", "workspaces": ["modules/*"] }
    );
    try writeFileP(io, test_scratch.path(io, "roots-ws/ws/repository/rakun/modules/rakun-web/botopink.json"),
        \\{ "name": "rakun-web", "files": ["root.bp"] }
    );

    const roots = try rootsFrom(gpa, io, &.{}, test_scratch.path(io, "roots-ws/ws/repository/rakun/modules/rakun-web"));
    defer freeRoots(gpa, roots);
    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-ws/ws/repository/rakun"), roots[0]);
    try std.testing.expectEqualStrings(test_scratch.path(io, "roots-ws/ws/repository"), roots[1]);
}

test "renderMissingFile names the path it looked for and the manifest entry" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const text =
        \\{ "src": "src/",
        \\  "files": ["rakun.bp", "gone.bp"] }
    ;
    try renderMissingFile(&aw.writer, error.FileNotFound, "rakun", "gone.bp", "libs/rakun/src/gone.bp", "libs/rakun/botopink.json", text);
    try std.testing.expectEqualStrings(
        \\error: dependency 'rakun' lists "gone.bp" in `files`, but libs/rakun/src/gone.bp does not exist
        \\ --> libs/rakun/botopink.json:2:25
        \\  |
        \\2 |   "files": ["rakun.bp", "gone.bp"] }
        \\  |                         ^^^^^^^^^
        \\
        \\
    , aw.written());
}

test "loadDependencies: the compiler embeds std alone — an import of another package loads nothing undeclared" {
    // Decision 326: `std` is the one bundled package; `routing`, `actions`,
    // `http`, `log` and `validation` are libraries a program declares.
    const pkgs = bp.comptime_pipeline.bundled_packages;
    try std.testing.expectEqual(@as(usize, 1), pkgs.len);
    try std.testing.expectEqualStrings("std", pkgs[0].name);
    try std.testing.expect(bp.comptime_pipeline.bundledPackage("routing") == null);

    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const proj = try config.parse(arena.allocator(),
        \\{ "name": "app" }
    );
    const mods = try loadDependencies(std.testing.allocator, std.testing.io, proj, null);
    defer freeModules(std.testing.allocator, mods);
    try std.testing.expectEqual(@as(usize, 0), mods.len);
}

test "loadDependencies: a bundled name listed in `dependencies` is refused" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const proj = try config.parse(arena.allocator(),
        \\{ "name": "app", "dependencies": { "std": { "path": "../std" } } }
    );
    try std.testing.expectError(error.BundledDependency, loadDependencies(std.testing.allocator, std.testing.io, proj, null));
}

test "linkFreeDir: a symbolic link resolves to its target, a directory stays as spelled (decision 344)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "link-free-dir");
    defer test_scratch.remove(io, "link-free-dir");
    // `.botopinkbuild/deps/web` as `bpmp install` writes it for a `"subdir"`:
    // a link to `modules/web` of a checkout whose sibling is `modules/core`.
    try writeFileP(io, test_scratch.path(io, "link-free-dir/checkout/modules/web/botopink.json"), "{ \"name\": \"web\" }");
    try writeFileP(io, test_scratch.path(io, "link-free-dir/checkout/modules/core/botopink.json"), "{ \"name\": \"core\" }");
    try std.Io.Dir.cwd().createDirPath(io, test_scratch.path(io, "link-free-dir/app/.botopinkbuild/deps"));
    const target = try std.Io.Dir.cwd().realPathFileAlloc(io, test_scratch.path(io, "link-free-dir/checkout/modules/web"), arena);
    try std.Io.Dir.cwd().symLink(io, target, test_scratch.path(io, "link-free-dir/app/.botopinkbuild/deps/web"), .{ .is_directory = true });

    const via_link = try linkFreeDir(arena, io, test_scratch.path(io, "link-free-dir/app/.botopinkbuild/deps/web"));
    try std.testing.expectEqualStrings(target, via_link);
    // The package's `../core` is the checkout's sibling, not `deps/core`.
    const sibling = try std.fs.path.resolve(arena, &.{ via_link, "../core" });
    var err: ?manifest.Located = null;
    const core = try manifest.read(arena, io, sibling, &err);
    try std.testing.expectEqualStrings("core", core.name);

    const plain = test_scratch.path(io, "link-free-dir/checkout/modules/core");
    try std.testing.expectEqualStrings(try std.fs.path.resolve(arena, &.{plain}), try linkFreeDir(arena, io, plain));
}

/// The scratch tree of the decision-483 tests under `<root>`: one package
/// `kit-x` three times — under the walk-up root `ws/repository`, under
/// `linked/` (where a `.botopinkbuild/deps/kit-x` link points) and under
/// `env/` (a `BOTOPINK_LIB_ROOTS` entry) — each exporting a function named
/// after where it is; a project `ws/repository/app` that declares it by `git`
/// and links it; `ws/repository/bare`, which declares it and links nothing;
/// and a workspace `ws/repository/lib` whose member `modules/m` declares it,
/// linked at the workspace root.
fn writeTiersTree(arena: std.mem.Allocator, io: std.Io, comptime root: []const u8) !void {
    const dep = "{ \"kit-x\": { \"git\": \"https://example.invalid/kit-x\" } }";
    const files = [_][2][]const u8{
        .{ "ws/repository/kit-x/botopink.json", "{ \"name\": \"kit-x\", \"files\": [\"x.bp\"] }" },
        .{ "ws/repository/kit-x/src/x.bp", "pub fn walkup() -> void {}" },
        .{ "linked/kit-x/botopink.json", "{ \"name\": \"kit-x\", \"files\": [\"x.bp\"] }" },
        .{ "linked/kit-x/src/x.bp", "pub fn linked() -> void {}" },
        .{ "env/kit-x/botopink.json", "{ \"name\": \"kit-x\", \"files\": [\"x.bp\"] }" },
        .{ "env/kit-x/src/x.bp", "pub fn env() -> void {}" },
        .{ "ws/repository/app/botopink.json", "{ \"name\": \"app\", \"dependencies\": " ++ dep ++ " }" },
        .{ "ws/repository/bare/botopink.json", "{ \"name\": \"bare\", \"dependencies\": " ++ dep ++ " }" },
        .{ "ws/repository/lib/botopink.json", "{ \"name\": \"lib\", \"workspaces\": [\"modules/*\"] }" },
        .{ "ws/repository/lib/modules/m/botopink.json", "{ \"name\": \"m\", \"dependencies\": " ++ dep ++ " }" },
    };
    inline for (files) |f| try writeFileP(io, test_scratch.path(io, root ++ "/" ++ f[0]), f[1]);
    const target = try std.Io.Dir.cwd().realPathFileAlloc(io, test_scratch.path(io, root ++ "/linked/kit-x"), arena);
    inline for (.{ root ++ "/ws/repository/app", root ++ "/ws/repository/lib" }) |project| {
        const deps = try std.fs.path.join(arena, &.{ test_scratch.path(io, project), manifest.DEPS_DIR });
        try std.Io.Dir.cwd().createDirPath(io, deps);
        try std.Io.Dir.cwd().symLink(io, target, try std.fs.path.join(arena, &.{ deps, "kit-x" }), .{ .is_directory = true });
    }
}

/// The source of `kit-x` the closure of the project at `project` loads, over
/// the tiers `tiersFrom(env_roots, project, roots)` builds.
fn kitXSource(arena: std.mem.Allocator, io: std.Io, project: []const u8, env_roots: []const []const u8, roots: []const []const u8) ![]const u8 {
    const gpa = std.testing.allocator;
    var err: ?manifest.Located = null;
    const m = try manifest.read(arena, io, project, &err);
    const tiers = try tiersFrom(arena, io, env_roots, project, roots);
    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |mod| {
            gpa.free(mod.path);
            gpa.free(mod.source);
            gpa.free(mod.srcPath);
            if (mod.files) |f| gpa.free(f.root);
        }
        out.deinit(gpa);
    }
    try loadClosure(gpa, io, arena, m, project, null, m.dependencies, tiers, &out, &.{}, null);
    try std.testing.expectEqual(@as(usize, 1), out.items.len);
    try std.testing.expectEqualStrings("kit-x/x", out.items[0].path);
    return arena.dupe(u8, out.items[0].source);
}

test "dependencyTiers: a .botopinkbuild/deps link wins over the walk-up; BOTOPINK_LIB_ROOTS wins over a link (decision 483)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "deps-tiers");
    defer test_scratch.remove(io, "deps-tiers");
    try writeTiersTree(arena, io, "deps-tiers");

    const app = test_scratch.path(io, "deps-tiers/ws/repository/app");
    const walk_up = try rootsFrom(std.testing.allocator, io, &.{}, app);
    defer freeRoots(std.testing.allocator, walk_up);
    // The walk-up carries `kit-x` (ws/repository), and so does the link.
    try std.testing.expectEqualStrings("pub fn linked() -> void {}", try kitXSource(arena, io, app, &.{}, walk_up));
    // Linked nowhere: the walk-up is the fallback.
    const bare = test_scratch.path(io, "deps-tiers/ws/repository/bare");
    try std.testing.expectEqualStrings("pub fn walkup() -> void {}", try kitXSource(arena, io, bare, &.{}, walk_up));
    // An env root first, before the link.
    const env = [_][]const u8{test_scratch.path(io, "deps-tiers/env")};
    try std.testing.expectEqualStrings("pub fn env() -> void {}", try kitXSource(arena, io, app, &env, walk_up));
    // A workspace member reads its workspace root's links.
    const member = test_scratch.path(io, "deps-tiers/ws/repository/lib/modules/m");
    try std.testing.expectEqualStrings("pub fn linked() -> void {}", try kitXSource(arena, io, member, &.{}, walk_up));
}

test "dependencyTiers: a project whose dependencies are only .botopinkbuild/deps links resolves with no library root at all (decision 483)" {
    var arena_inst = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const io = std.testing.io;
    test_scratch.remove(io, "deps-only");
    defer test_scratch.remove(io, "deps-only");
    try writeTiersTree(arena, io, "deps-only");

    // No `repository/`, no env root: the link is all there is.
    const app = test_scratch.path(io, "deps-only/ws/repository/app");
    try std.testing.expectEqualStrings("pub fn linked() -> void {}", try kitXSource(arena, io, app, &.{}, &.{}));
    // And without the link the name is not found.
    const bare = test_scratch.path(io, "deps-only/ws/repository/bare");
    try std.testing.expectError(error.LibNotFound, kitXSource(arena, io, bare, &.{}, &.{}));
}
