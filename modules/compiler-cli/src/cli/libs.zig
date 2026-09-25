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
/// across the roots (`manifest.scanRoots`) and then the `bpmp install` store.
const std = @import("std");
const bp = @import("botopink");
const manifest = @import("manifest");
const config = @import("./config.zig");
const diagnostics = @import("./diagnostics.zig");
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
///        * `D` itself, when `D/botopink.json` is a workspace — its members
///          (so a member resolves its siblings from inside the workspace)
///        * `D/repository/botopink-lang/libs`  — bundled libs (std)
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
        if (manifest.isWorkspaceDir(io, dir)) try addRootIfExists(gpa, io, &roots, &.{dir});
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

/// Load every module of every declared dependency of `proj`. Returns a flat
/// `Module[]` (caller owns — free with `freeModules`). With no dependencies
/// this returns an empty slice without touching the filesystem.
///
/// Resolution per dep (`manifest.resolveDependency`):
///   * `{ "workspace": true }` — the sibling member of the enclosing workspace.
///   * `{ "path": … }` — `<project>/<path>`, which must hold that package.
///   * `{ "git": … }` — by name across `resolveLibRoots` (env roots, the
///     enclosing workspace, `repository/…`, `libs/`), then the F2 fallback
///     `<project>/.botopinkbuild/deps/<name>/` that `bpmp install` materialises.
///   * nothing carries the name → `LibNotFound` (named on stderr). No library
///     root at all is not an error: `path` and `workspace` need none.
pub fn loadDependencies(
    gpa: std.mem.Allocator,
    io: std.Io,
    proj: config.ProjectConfig,
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
            gpa.free(m.srcPath);
        }
        modules.deinit(gpa);
    }

    if (proj.dependencies.len == 0) return try modules.toOwnedSlice(gpa);

    const roots = try resolveLibRoots(gpa, io, env_map);
    defer freeRoots(gpa, roots);

    // F2 fallback roots: `.botopinkbuild/deps/` + (lockfile-driven) `$BPMP_HOME/store/`.
    const fallback_roots = try resolveFallbackRoots(gpa, io, env_map);
    defer freeRoots(gpa, fallback_roots);

    // No root at all is not an error here: a `path` or `{ "workspace": true }`
    // dependency needs none, and a `git` one nothing carries is named below.
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();
    const entries = try manifest.scanRoots(arena, io, roots);
    const fallback_entries = try manifest.scanRoots(arena, io, fallback_roots);

    for (proj.dependencies) |dep| {
        var err: ?manifest.Located = null;
        const resolved = manifest.resolveDependency(arena, io, proj.manifest, proj.dir, dep, entries, fallback_entries, &err) catch |e| switch (e) {
            error.Invalid => {
                err.?.print();
                return error.LibManifestInvalid;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        const r = resolved orelse {
            // Name the dependency here — the caller only sees the error tag.
            std.debug.print("\x1b[1m\x1b[31merror\x1b[0m: dependency '{s}' was not found under any library root\n", .{dep.name});
            return error.LibNotFound;
        };
        try loadOne(gpa, io, r.dir, r.manifest, dep.name, &modules);
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
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    for (m.files) |file| {
        const file_path = try std.fs.path.join(arena, &.{ dir, m.src, file });
        const source = std.Io.Dir.cwd().readFileAlloc(io, file_path, gpa, .unlimited) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => {
                var aw: std.Io.Writer.Allocating = .init(arena);
                try renderMissingFile(&aw.writer, err, dep, file, file_path, m.path, m.text);
                std.debug.print("{s}", .{aw.written()});
                return error.LibFileNotFound;
            },
        };
        errdefer gpa.free(source);

        const stem = stripSourceExt(file);
        const mod_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ dep, stem });
        errdefer gpa.free(mod_path);
        // `@src().file` (decision 73) is relative to the dependency's own
        // package root: `<manifest.src>/<file>`.
        const src_path = try std.fmt.allocPrint(gpa, "{s}/{s}", .{ m.src, file });
        errdefer gpa.free(src_path);
        std.mem.replaceScalar(u8, src_path, '\\', '/');

        try out.append(gpa, .{ .path = mod_path, .source = source, .declaration = isDeclFile(file), .srcPath = src_path });
    }
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
    if (project) |proj| {
        for (proj.dependencies) |dep| {
            if (!std.mem.eql(u8, dep.name, lib)) continue;

            const fallback_roots = try resolveFallbackRoots(gpa, io, env_map);
            defer freeRoots(gpa, fallback_roots);
            const entries = try manifest.scanRoots(arena, io, roots);
            const fallback_entries = try manifest.scanRoots(arena, io, fallback_roots);

            var buf: [std.fs.max_path_bytes]u8 = undefined;
            const n = try std.process.currentPath(io, &buf);
            const resolved = manifest.resolveDependency(arena, io, proj, buf[0..n], dep, entries, fallback_entries, out_err) catch |e| switch (e) {
                // The build already compiled this dependency, so a refusal here
                // is not reachable through `build`/`test`; it is still a located
                // problem and never a silent null.
                error.Invalid => return null,
                error.OutOfMemory => return error.OutOfMemory,
            };
            const r = resolved orelse return null;
            return .{ .dir = r.dir, .package = r.manifest };
        }
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
        self.value = manifest.parse(arena, text, manifest.FILENAME, &err) catch null;
        return self.value;
    }
};

/// A sidecar the build cannot ship ends the build, after the located
/// diagnostic. It is not a `return error`: both shippers are called as
/// `shipMjsSidecars(…) catch {}` from `build` and `test`, so a returned error
/// would be swallowed and the build would still exit 0 — the silence this front
/// closes. There is no flag, environment variable or manifest field that turns
/// the refusal off (decision 67 of 1.0.10-beta).
fn refuseSidecar(loc: manifest.Located) noreturn {
    loc.print();
    std.process.exit(1);
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
        gpa.free(m.srcPath);
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
//
// A `require` whose resolved path escapes `out_dir` (onze's `../../src/onze.mjs`
// from `<out>/onze/onze.js` lands at `<out>/../src/onze.mjs`) is never shipped
// outside the output: the sidecar goes to `<out>/<owner>/<base>` (a project-own
// module: `<out>/<base>`) and the emitted module's `require` is rewritten to
// reach it, so a build writes nothing beside `--out`.
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
    // The project's own manifest — how a dependency's directory is resolved, and
    // where a refusal is located. Read on the same first require.
    var project: ProjectManifest = .{};

    const out_norm = try std.fs.path.resolve(arena, &.{out_dir});

    for (outputs) |o| {
        if (o.result.failed()) continue;
        const emitted_rel = try std.fmt.allocPrint(arena, "{s}/{s}{s}", .{ out_dir, o.name, ext });
        // `require` paths of this module to rewrite once the scan is done.
        var rewrites: std.ArrayListUnmanaged([2][]const u8) = .empty;
        const emitted_dir = std.fs.path.dirname(emitted_rel) orelse out_dir;
        // The owning lib is the first path segment of a dependency module name
        // (`rakun/http` → `rakun`); a project-own module has no such prefix.
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

            const base = std.fs.path.basename(req_path);
            // Where the runtime will look for it (`..` collapsed). A path that
            // escapes the output directory is relocated inside it.
            const resolved = try std.fs.path.resolve(arena, &.{ emitted_dir, req_path });
            const escapes = escapesDir(out_norm, resolved);
            const target = if (escapes)
                try std.fs.path.join(arena, if (owner) |lib| &.{ out_norm, lib, base } else &.{ out_norm, base })
            else
                resolved;
            if (escapes) {
                const new_req = try relocatedRequire(arena, o.name, owner, base);
                var seen = false;
                for (rewrites.items) |r| {
                    if (std.mem.eql(u8, r[0], req_path)) seen = true;
                }
                if (!seen) try rewrites.append(arena, .{ req_path, new_req });
            }
            if (fileExists(io, target)) continue;

            // std-tail F2: when a sidecar lives under `<lib>/<src>/sidecars/<base>`
            // (the convention for std's `#\[@External\.node(…)]` adapters that
            // need a sibling `.mjs`/`.erl` file), the search also probes that
            // subdirectory before falling back to the flat `<lib>/<src>/<base>`.
            //
            // The owner's directory is the one the build resolved the dependency
            // to (`sidecarOwner`), and `<src>` is that package's own — never a
            // basename match across the roots. A sidecar that is named and
            // cannot be found is the end of the build, not a silent skip.
            const src: []const u8 = blk: {
                if (owner) |lib| {
                    if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                    const proj = project.get(arena, io);
                    var oerr: ?manifest.Located = null;
                    const found = try sidecarOwner(gpa, arena, io, roots.?, env_map, proj, lib, &oerr);
                    const pkg = found orelse refuseSidecar(oerr orelse
                        try unresolvedOwner(arena, proj, lib, o.name, req_path));
                    const src_dir = try pkg.srcDir(arena);
                    const sidecar = try std.fs.path.join(arena, &.{ src_dir, "sidecars", base });
                    if (fileExists(io, sidecar)) break :blk sidecar;
                    const cand = try std.fs.path.join(arena, &.{ src_dir, base });
                    if (fileExists(io, cand)) break :blk cand;
                    refuseSidecar(try missingSidecar(arena, proj, lib, pkg.package, o.name, req_path, sidecar, cand));
                }
                // Project-own module: probe sidecars/ first, then flat src/.
                const proj = project.get(arena, io);
                const own_src = if (proj) |p| p.src else "src/";
                const sidecar = try std.fs.path.join(arena, &.{ own_src, "sidecars", base });
                if (fileExists(io, sidecar)) break :blk sidecar;
                const cand = try std.fs.path.join(arena, &.{ own_src, base });
                if (fileExists(io, cand)) break :blk cand;
                refuseSidecar(try missingOwnSidecar(arena, proj, o.name, req_path, sidecar, cand));
            };

            const data = std.Io.Dir.cwd().readFileAlloc(io, src, arena, .unlimited) catch |err|
                refuseSidecar(try unreadableSidecar(arena, project.get(arena, io), owner, o.name, req_path, src, err));
            if (std.fs.path.dirname(target)) |parent| {
                std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            }
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = target, .data = data });
        }

        if (rewrites.items.len > 0) {
            const emitted = std.Io.Dir.cwd().readFileAlloc(io, emitted_rel, arena, .unlimited) catch continue;
            var text: []const u8 = emitted;
            for (rewrites.items) |r| {
                for ([_]u8{ '"', '\'' }) |q| {
                    const from = try std.fmt.allocPrint(arena, "require({c}{s}{c})", .{ q, r[0], q });
                    const to = try std.fmt.allocPrint(arena, "require({c}{s}{c})", .{ q, r[1], q });
                    text = try std.mem.replaceOwned(u8, arena, text, from, to);
                }
            }
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = emitted_rel, .data = text });
        }
    }
}

// ── host `.erl` module shipping ────────────────────────────────────────────────
//
// The erlang twin of `shipMjsSidecars`. A `#\[@External\.Erlang("host", "fn")]`
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
// that emitter is another front's (`examples/modules` is red on erlang for the
// same reason).
//
// Generic and lib-agnostic, like the `.mjs` half: the scan yields every
// `atom:atom(` qualifier in the emitted erlang, and a qualifier ships only when
// a file of that name is found under the owning lib's `src/sidecars/` or `src/`
// — so `lists:foldl`, `base64:encode` and every other OTP call is a no-op, as
// is a call to another module of this build. Idempotent; writes only inside
// `out_dir`. Returns how many host modules it shipped.
pub fn shipErlSidecars(
    gpa: std.mem.Allocator,
    io: std.Io,
    outputs: []const bp.codegen.ModuleOutput,
    out_dir: []const u8,
    env_map: EnvMap,
) !usize {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Module atoms this build emits — a qualifier naming one of them is a
    // project or dependency module, never a host module.
    var emitted = std.StringHashMapUnmanaged(void){};
    for (outputs) |o| {
        if (o.result.failed()) continue;
        try emitted.put(arena, std.fs.path.basename(o.name), {});
    }

    // Resolved lazily on the first unknown qualifier (most builds have none).
    var roots: ?[][]const u8 = null;
    defer if (roots) |r| freeRoots(gpa, r);
    var project: ProjectManifest = .{};

    var shipped = std.StringHashMapUnmanaged(void){};
    for (outputs) |o| {
        if (o.result.failed()) continue;
        // The owning lib is the first path segment of a dependency module name
        // (`rakun/http` → `rakun`); a project-own module has no such prefix.
        const owner: ?[]const u8 = if (std.mem.indexOfScalar(u8, o.name, '/')) |i| o.name[0..i] else null;

        var it = QualifierIterator{ .text = o.result.js };
        while (it.next()) |atom| {
            if (emitted.contains(atom)) continue;
            if (shipped.contains(atom)) continue;

            const base = try std.fmt.allocPrint(arena, "{s}.erl", .{atom});
            const target = try std.fs.path.join(arena, &.{ out_dir, base });

            const src_path: ?[]const u8 = blk: {
                if (owner) |lib| {
                    if (roots == null) roots = try resolveLibRoots(gpa, io, env_map);
                    // Same owner lookup as the `.mjs` shipper: the directory the
                    // build resolved the dependency to, and that package's `src`.
                    var oerr: ?manifest.Located = null;
                    const found = try sidecarOwner(gpa, arena, io, roots.?, env_map, project.get(arena, io), lib, &oerr);
                    const pkg = found orelse break :blk null;
                    const src_dir = try pkg.srcDir(arena);
                    const sidecar = try std.fs.path.join(arena, &.{ src_dir, "sidecars", base });
                    if (fileExists(io, sidecar)) break :blk sidecar;
                    const cand = try std.fs.path.join(arena, &.{ src_dir, base });
                    if (fileExists(io, cand)) break :blk cand;
                    break :blk null;
                }
                const own_src = if (project.get(arena, io)) |p| p.src else "src/";
                const sidecar = try std.fs.path.join(arena, &.{ own_src, "sidecars", base });
                if (fileExists(io, sidecar)) break :blk sidecar;
                const cand = try std.fs.path.join(arena, &.{ own_src, base });
                if (fileExists(io, cand)) break :blk cand;
                break :blk null;
            };
            // An unresolved atom here is an OTP or unknown module, not a sidecar
            // the library named — the `.mjs` shipper's refusal has no twin here.
            const src = src_path orelse continue;

            const data = std.Io.Dir.cwd().readFileAlloc(io, src, arena, .unlimited) catch continue;
            if (std.fs.path.dirname(target)) |parent| {
                std.Io.Dir.cwd().createDirPath(io, parent) catch |err| switch (err) {
                    error.PathAlreadyExists => {},
                    else => return err,
                };
            }
            try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = target, .data = data });
            try shipped.put(arena, try arena.dupe(u8, atom), {});
        }
    }
    return shipped.count();
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

/// Whether `path` lies outside `dir` (both already `..`-collapsed by `resolve`).
fn escapesDir(dir: []const u8, path: []const u8) bool {
    if (std.mem.eql(u8, dir, ".")) {
        return std.mem.eql(u8, path, "..") or std.mem.startsWith(u8, path, "../") or std.fs.path.isAbsolute(path);
    }
    if (!std.mem.startsWith(u8, path, dir)) return true;
    return path.len > dir.len and path[dir.len] != '/';
}

/// The `require` path that reaches a relocated sidecar from module `name`:
/// `<out>/<owner>/<base>` for a dependency, `<out>/<base>` for a project-own
/// module; the module is emitted at `<out>/<name>.js`.
fn relocatedRequire(arena: std.mem.Allocator, name: []const u8, owner: ?[]const u8, base: []const u8) ![]const u8 {
    const depth = std.mem.count(u8, name, "/");
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    if (depth == 0) try buf.appendSlice(arena, "./");
    for (0..depth) |_| try buf.appendSlice(arena, "../");
    if (owner) |lib| {
        try buf.appendSlice(arena, lib);
        try buf.append(arena, '/');
    }
    try buf.appendSlice(arena, base);
    return buf.items;
}

fn fileExists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "escapesDir: a path under the output stays; a parent path escapes" {
    try std.testing.expect(!escapesDir("out", "out/onze/onze.mjs"));
    try std.testing.expect(escapesDir("out", "src/onze.mjs"));
    try std.testing.expect(escapesDir("out", "outer/x.mjs"));
    try std.testing.expect(escapesDir("/tmp/w/out", "/tmp/w/src/onze.mjs"));
    try std.testing.expect(!escapesDir("/tmp/w/out", "/tmp/w/out/rakun/runtime.mjs"));
    try std.testing.expect(!escapesDir(".", "src/x.mjs"));
    try std.testing.expect(escapesDir(".", "../src/x.mjs"));
}

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

test "relocatedRequire reaches <out>/<owner>/<base> from the emitting module" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("../onze/onze.mjs", try relocatedRequire(a, "onze/onze", "onze", "onze.mjs"));
    try std.testing.expectEqualStrings("../../onze/onze.mjs", try relocatedRequire(a, "onze/sub/mod", "onze", "onze.mjs"));
    try std.testing.expectEqualStrings("./x.mjs", try relocatedRequire(a, "main", null, "x.mjs"));
}

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

test "loadOne: std resolves from the bundled root, rakun from the sibling root; absent dep is LibNotFound" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    test_scratch.remove(io, "loadone");
    defer test_scratch.remove(io, "loadone");
    // `std` is the bundled lib (`libs/std`); `rakun` is a sibling project.
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/botopink-lang/libs/std/botopink.json"),
        \\{ "name": "std", "src": "src/", "files": ["math.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/botopink-lang/libs/std/src/math.bp"),
        \\pub fn abs() {}
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/rakun/botopink.json"),
        \\{ "name": "rakun", "src": "src/", "files": ["rakun.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "loadone/ws/repository/rakun/src/rakun.bp"),
        \\pub fn run() {}
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
        \\pub fn serve() {}
    );
    const roots = [_][]const u8{test_scratch.path(io, "loadone-ws/ws/repository")};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
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
        \\pub fn run() {}
    );
    const roots = [_][]const u8{test_scratch.path(io, "loadone-missing/ws/repository")};

    var out: std.ArrayListUnmanaged(Module) = .empty;
    defer {
        for (out.items) |m| {
            gpa.free(m.path);
            gpa.free(m.source);
            gpa.free(m.srcPath);
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
