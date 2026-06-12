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
const std = @import("std");
const bp = @import("botopink");
const config = @import("./config.zig");

const Module = bp.Module;
const DepEntry = config.DepEntry;

/// Optional process-environment handle. The CLI threads `init.environ_map`
/// through every caller; `null` is the test-friendly "no env" mode.
pub const EnvMap = ?*const std.process.Environ.Map;

/// Minimal view of a lib's own `botopink.json` — only the fields the loader needs.
const LibManifest = struct {
    src: []const u8 = "src/",
    files: []const []const u8 = &.{},
};

pub const Error = error{
    LibsRootNotFound,
    LibNotFound,
    LibManifestInvalid,
} || std.mem.Allocator.Error;

/// Name of the env var that prepends extra lib roots (drop-in for `PATH`-style
/// path lists — colon-separated on POSIX, semicolon-separated on Windows). See
/// `parseEnvRootsString`.
pub const ENV_VAR = "BOTOPINK_LIB_ROOTS";

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
///        * `D/repository/botopink-lang/libs`  — bundled libs (std/client/server)
///        * `D/repository`                     — sibling projects (frameworks)
///        * `D/libs`                           — legacy flat tree
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
fn rootsFrom(
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
        try addRootIfExists(gpa, io, &roots, &.{ dir, "repository", "botopink-lang", "libs" });
        try addRootIfExists(gpa, io, &roots, &.{ dir, "repository" });
        try addRootIfExists(gpa, io, &roots, &.{ dir, "libs" });

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

/// Load every module of every declared dependency. Returns a flat `Module[]`
/// (caller owns — free with `freeModules`). With no dependencies this returns an
/// empty slice without touching the filesystem.
///
/// Resolution order per dep:
///   1. project-local `libs/<name>/` (via `resolveLibRoots` walk-up).
///   2. each entry of `BOTOPINK_LIB_ROOTS` (via `resolveLibRoots`).
///   3. (F2 fallback) `<project>/.botopinkbuild/deps/<name>/` — the per-project
///      symlink that `bpmp install` materialises.
///   4. (F2 fallback) `$BPMP_HOME/store/<name>/<rev-from-lockfile>/` — direct
///      lookup into the global CAS when the symlink is missing but the
///      lockfile still pins a rev.
///   5. error `LibsRootNotFound`.
pub fn loadDependencies(
    gpa: std.mem.Allocator,
    io: std.Io,
    deps: []const DepEntry,
    env_map: EnvMap,
) ![]Module {
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    // On error, free what was accumulated, then the list backing — in this order
    // (a single block, not two errdefers, which would run LIFO and free the
    // backing before reading `.items`).
    errdefer {
        for (modules.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
        }
        modules.deinit(gpa);
    }

    if (deps.len == 0) return try modules.toOwnedSlice(gpa);

    const roots = try resolveLibRoots(gpa, io, env_map);
    defer freeRoots(gpa, roots);

    // F2 fallback roots: `.botopinkbuild/deps/` + (lockfile-driven) `$BPMP_HOME/store/`.
    const fallback_roots = try resolveFallbackRoots(gpa, io, env_map);
    defer freeRoots(gpa, fallback_roots);

    if (roots.len == 0 and fallback_roots.len == 0) return error.LibsRootNotFound;

    for (deps) |dep| {
        try loadOne(gpa, io, roots, fallback_roots, dep.name, &modules);
    }
    return try modules.toOwnedSlice(gpa);
}

/// Build the F2 fallback root list: today this is just
/// `.botopinkbuild/deps/` — the per-project symlink store materialised by
/// `bpmp install`. Each symlink under it points into
/// `$BPMP_HOME/store/<name>/<rev>/`, so resolving against the symlink
/// transparently reaches the CAS. A second-tier "$BPMP_HOME/store direct"
/// fallback (used when `.botopinkbuild/deps/` was deleted by `clean` but
/// `botopink.lock` still pins a rev) needs lockfile knowledge and is left
/// for a follow-up. Caller owns the slice (free with `freeRoots`).
pub fn resolveFallbackRoots(gpa: std.mem.Allocator, io: std.Io, env_map: EnvMap) ![][]const u8 {
    _ = env_map;
    var roots: std.ArrayListUnmanaged([]const u8) = .empty;
    errdefer {
        for (roots.items) |r| gpa.free(r);
        roots.deinit(gpa);
    }

    try addRootIfExists(gpa, io, &roots, &.{".botopinkbuild/deps"});

    return roots.toOwnedSlice(gpa);
}

/// Resolve the absolute path to `$BPMP_HOME/store/` (or the XDG fallback).
/// Returns null when neither env var is present (i.e. nothing to consult).
/// Caller owns the returned slice via `gpa`.
pub fn resolveBpmpStoreRoot(gpa: std.mem.Allocator, env_map: EnvMap) !?[]u8 {
    if (env_map) |m| {
        if (m.get("BPMP_HOME")) |v| {
            if (v.len > 0) return std.fs.path.join(gpa, &.{ v, "store" });
        }
        if (m.get("XDG_CACHE_HOME")) |v| {
            if (v.len > 0) return std.fs.path.join(gpa, &.{ v, "bpmp", "store" });
        }
        if (m.get("HOME")) |v| {
            if (v.len > 0) return std.fs.path.join(gpa, &.{ v, ".cache", "bpmp", "store" });
        }
    }
    return null;
}

fn loadOne(
    gpa: std.mem.Allocator,
    io: std.Io,
    roots: []const []const u8,
    fallback_roots: []const []const u8,
    dep: []const u8,
    out: *std.ArrayListUnmanaged(Module),
) !void {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Resolve `dep` to the first root carrying `<root>/<dep>/botopink.json`.
    // Regular roots first; F2 fallback roots last.
    var lib_dir: ?[]const u8 = null;
    var data: []const u8 = undefined;
    for ([_][]const []const u8{ roots, fallback_roots }) |group| {
        for (group) |root| {
            const cand_dir = try std.fs.path.join(arena, &.{ root, dep });
            const manifest_path = try std.fs.path.join(arena, &.{ cand_dir, "botopink.json" });
            data = std.Io.Dir.cwd().readFileAlloc(io, manifest_path, arena, .limited(64 * 1024)) catch continue;
            lib_dir = cand_dir;
            break;
        }
        if (lib_dir != null) break;
    }
    const dir = lib_dir orelse return error.LibNotFound;
    const manifest = std.json.parseFromSliceLeaky(LibManifest, arena, data, .{
        .ignore_unknown_fields = true,
    }) catch return error.LibManifestInvalid;

    for (manifest.files) |file| {
        const file_path = try std.fs.path.join(arena, &.{ dir, manifest.src, file });
        const source = try std.Io.Dir.cwd().readFileAlloc(io, file_path, gpa, .unlimited);
        errdefer gpa.free(source);

        // Module path: `<dep>/<basename without extension>`. The `<dep>/` prefix
        // is how the core resolves `from "<dep>"` generically.
        const stem = stripSourceExt(file);
        const mod_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ dep, stem });
        errdefer gpa.free(mod_path);

        try out.append(gpa, .{ .path = mod_path, .source = source, .declaration = isDeclFile(file) });
    }
}

fn isDeclFile(name: []const u8) bool {
    return std.mem.endsWith(u8, name, ".d.bp");
}

fn stripSourceExt(name: []const u8) []const u8 {
    // Longest match first so `.d.bp` wins over `.bp`.
    const exts = [_][]const u8{ ".d.bp", ".botopink", ".bp" };
    for (exts) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return name[0 .. name.len - ext.len];
    }
    return name;
}

/// Free memory allocated by `loadDependencies`.
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    gpa.free(modules);
}

// ── runtime `.mjs` sidecar shipping (G2) ───────────────────────────────────────
//
// A `#\[@External\.node("../../src/x.mjs", …)]` lowers to a top-level
// `require("../../src/x.mjs")` in the emitted module. The path is authored
// relative to the lib's OWN build output, so it resolves for the lib's own
// `botopink test`/`build`; but when the lib is loaded as a *dependency* its
// emitted module sits one directory deeper (`<out>/<lib>/<mod>.js`), so the same
// relative `require` lands at a path the source `.mjs` was never copied to.
//
// `shipMjsSidecars` closes that gap generically (no lib names): for every emitted
// module it scans the JS for relative `require("….mjs")`, resolves the path the
// runtime will look up, and — when nothing is there yet — copies the source
// `.mjs` (found under the owning lib's `src/`, or the project's own `src/`) into
// place. Idempotent and lib-agnostic; a no-op when every `.mjs` already resolves.
pub fn shipMjsSidecars(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
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

    for (outputs) |o| {
        const emitted_rel = try std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ out_dir, o.name, ext });
        const emitted_dir = std.fs.path.dirname(emitted_rel) orelse out_dir;
        // The owning lib is the first path segment of a dependency module name
        // (`server/server` → `server`); a project-own module has no such prefix.
        const owner: ?[]const u8 = if (std.mem.indexOfScalar(u8, o.name, '/')) |i| o.name[0..i] else null;

        var search: usize = 0;
        const js = o.result.js;
        // Probe both quote styles — `#\[@External\.node(…)]` templates rendered
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

            // Where the runtime will look for it (absolute, `..` collapsed).
            const target = try std.fs.path.resolve(arena, &.{ emitted_dir, req_path });
            if (fileExists(io, target)) continue;

            const base = std.fs.path.basename(req_path);
            // std-tail F2: when a sidecar lives under `<lib>/src/sidecars/<base>`
            // (the convention for std's `#\[@External\.node(…)]` adapters that
            // need a sibling `.mjs`/`.erl` file), the search also probes that
            // subdirectory before falling back to the flat `<lib>/src/<base>`.
            const src_path: ?[]const u8 = blk: {
                if (owner) |lib| {
                    if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                    // The owning lib lives under the first root that carries it.
                    for (roots.?) |root| {
                        const sidecar = try std.fs.path.join(arena, &.{ root, lib, "src", "sidecars", base });
                        if (fileExists(io, sidecar)) break :blk sidecar;
                        const cand = try std.fs.path.join(arena, &.{ root, lib, "src", base });
                        if (fileExists(io, cand)) break :blk cand;
                    }
                    break :blk null;
                }
                // Project-own module: probe sidecars/ first, then flat src/.
                const sidecar = try std.fs.path.join(arena, &.{ "src", "sidecars", base });
                if (fileExists(io, sidecar)) break :blk sidecar;
                break :blk try std.fs.path.join(arena, &.{ "src", base });
            };
            const src = src_path orelse continue;

            const data = std.Io.Dir.cwd().readFileAlloc(io, src, arena, .unlimited) catch continue;
            if (std.fs.path.dirname(target)) |parent| {
                std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            }
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = target, .data = data });
        }
    }
}

fn fileExists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "stripSourceExt strips .d.bp before .bp" {
    try std.testing.expectEqualStrings("rakun", stripSourceExt("rakun.d.bp"));
    try std.testing.expectEqualStrings("http", stripSourceExt("http.bp"));
    try std.testing.expectEqualStrings("page", stripSourceExt("page.botopink"));
    try std.testing.expectEqualStrings("noext", stripSourceExt("noext"));
}

test "isDeclFile recognizes declaration modules" {
    try std.testing.expect(isDeclFile("rakun.d.bp"));
    try std.testing.expect(!isDeclFile("http.bp"));
}

test "loadDependencies with no deps touches no filesystem" {
    const mods = try loadDependencies(std.testing.allocator, std.testing.io, &.{}, null);
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

fn writeFileP(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

test "resolveLibRoots: repository workspace yields [bundled libs, repository]" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/roots-repo/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-repo") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-repo") catch {};
    try writeFileP(io, ws ++ "/repository/botopink-lang/libs/server/botopink.json", "{}");
    try writeFileP(io, ws ++ "/repository/rakun/botopink.json", "{}");

    // A consumer under repository/rakun resolves up to `ws`, where both roots fire.
    const roots = try rootsFrom(gpa, io, &.{}, ws ++ "/repository/rakun");
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings(ws ++ "/repository/botopink-lang/libs", roots[0]);
    try std.testing.expectEqualStrings(ws ++ "/repository", roots[1]);
}

test "resolveLibRoots: flat libs/ tree yields a single legacy root" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/roots-flat/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-flat") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-flat") catch {};
    try writeFileP(io, ws ++ "/libs/std/botopink.json", "{}");

    const roots = try rootsFrom(gpa, io, &.{}, ws);
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(ws ++ "/libs", roots[0]);
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

    const ws = ".botopinkbuild/roots-env/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-env") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-env") catch {};
    try writeFileP(io, ws ++ "/store/erika/botopink.json", "{}");
    try writeFileP(io, ws ++ "/repository/rakun/botopink.json", "{}");

    const env_roots = [_][]const u8{ws ++ "/store"};
    const roots = try rootsFrom(gpa, io, &env_roots, ws ++ "/repository/rakun");
    defer freeRoots(gpa, roots);

    try std.testing.expectEqual(@as(usize, 2), roots.len);
    try std.testing.expectEqualStrings(ws ++ "/store", roots[0]);
    try std.testing.expectEqualStrings(ws ++ "/repository", roots[1]);
}

test "rootsFrom: non-existent env entry is silently dropped" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/roots-envmiss/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-envmiss") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-envmiss") catch {};
    try writeFileP(io, ws ++ "/libs/std/botopink.json", "{}");

    const env_roots = [_][]const u8{".botopinkbuild/roots-envmiss/nope"};
    const roots = try rootsFrom(gpa, io, &env_roots, ws);
    defer freeRoots(gpa, roots);

    // Env entry dropped silently; only the walk-up `libs/` root fires.
    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(ws ++ "/libs", roots[0]);
}

test "rootsFrom: env entry duplicating a walk-up root de-dups env-first" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/roots-envdup/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-envdup") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/roots-envdup") catch {};
    try writeFileP(io, ws ++ "/libs/std/botopink.json", "{}");

    const env_roots = [_][]const u8{ws ++ "/libs"};
    const roots = try rootsFrom(gpa, io, &env_roots, ws);
    defer freeRoots(gpa, roots);

    // The walk-up duplicate is skipped — env copy wins, kept first.
    try std.testing.expectEqual(@as(usize, 1), roots.len);
    try std.testing.expectEqualStrings(ws ++ "/libs", roots[0]);
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

test "loadOne: rakun resolves \"server\" across roots; absent dep is LibNotFound" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/loadone/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/loadone") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/loadone") catch {};
    // `server` is a bundled lib; `rakun` is a sibling project.
    try writeFileP(io, ws ++ "/repository/botopink-lang/libs/server/botopink.json",
        \\{ "src": "src/", "files": ["server.bp"] }
    );
    try writeFileP(io, ws ++ "/repository/botopink-lang/libs/server/src/server.bp",
        \\pub fn serverServe() {}
    );
    try writeFileP(io, ws ++ "/repository/rakun/botopink.json",
        \\{ "src": "src/", "files": ["rakun.bp"] }
    );
    try writeFileP(io, ws ++ "/repository/rakun/src/rakun.bp",
        \\pub fn run() {}
    );

    const roots = [_][]const u8{
        ws ++ "/repository/botopink-lang/libs",
        ws ++ "/repository",
    };

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
        }
        out.deinit(gpa);
    }

    try loadOne(gpa, io, &roots, &.{}, "server", &out); // bundled — first root
    try loadOne(gpa, io, &roots, &.{}, "rakun", &out); // sibling — second root
    try std.testing.expectEqual(@as(usize, 2), out.items.len);
    try std.testing.expectEqualStrings("server/server", out.items[0].path);
    try std.testing.expect(std.mem.indexOf(u8, out.items[0].source, "serverServe") != null);
    try std.testing.expectEqualStrings("rakun/rakun", out.items[1].path);

    try std.testing.expectError(error.LibNotFound, loadOne(gpa, io, &roots, &.{}, "absent", &out));
}

test "loadOne: falls back to fallback_roots when not in regular roots" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const ws = ".botopinkbuild/loadone-fb/ws";
    std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/loadone-fb") catch {};
    defer std.Io.Dir.cwd().deleteTree(io, ".botopinkbuild/loadone-fb") catch {};
    try writeFileP(io, ws ++ "/.botopinkbuild/deps/jhonstart/botopink.json",
        \\{ "src": "src/", "files": ["jhonstart.bp"] }
    );
    try writeFileP(io, ws ++ "/.botopinkbuild/deps/jhonstart/src/jhonstart.bp",
        \\pub fn n() {}
    );

    const roots = [_][]const u8{}; // no regular roots
    const fb = [_][]const u8{ws ++ "/.botopinkbuild/deps"};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
        }
        out.deinit(gpa);
    }

    try loadOne(gpa, io, &roots, &fb, "jhonstart", &out);
    try std.testing.expectEqual(@as(usize, 1), out.items.len);
    try std.testing.expectEqualStrings("jhonstart/jhonstart", out.items[0].path);
}

test "LibManifest parses src + files, ignores unknown fields" {
    const json =
        \\{ "name": "rakun", "version": "0.0.1", "src": "src/",
        \\  "files": ["http.bp", "rakun.d.bp"] }
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const m = try std.json.parseFromSliceLeaky(LibManifest, arena.allocator(), json, .{
        .ignore_unknown_fields = true,
    });
    try std.testing.expectEqualStrings("src/", m.src);
    try std.testing.expectEqual(@as(usize, 2), m.files.len);
    try std.testing.expectEqualStrings("http.bp", m.files[0]);
}
