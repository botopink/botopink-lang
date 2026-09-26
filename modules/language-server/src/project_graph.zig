/// Project-graph resolver for the language server.
///
/// The LSP used to compile each open document **alone** — `mod` siblings and
/// `from "<lib>"` / `from "std"` packages were unresolved, so completion,
/// go-to-def, and sub-language expansion died on any file that imports across
/// modules. This resolver rebuilds the dependency set the compiler would see,
/// using the same rules as the CLI driver:
///
///   * `from "<lib>"` → the lib's own `botopink.json` (`src` + `files`), found
///     the way the CLI finds it (`manifest.resolveDependency`): a `path`
///     dependency from the project's directory, `{ "workspace": true }` from the
///     enclosing workspace, a `git` dependency by name across the resolved root
///     list (an ancestor workspace, bundled `repository/botopink-lang/libs`,
///     sibling `repository/`, legacy flat `libs/` — see `resolveRoots`; every
///     workspace found there contributes its members) and then the project's
///     `.botopinkbuild/deps/` store.
///   * `mod` / `pub mod` siblings → every `.bp` under the project's `src/`.
///   * `from "std"` → handled inside the compiler (embedded), not here.
///
/// The active document's own source stays the hot, in-memory copy (the server
/// overlays it); dependencies are read from disk and cached per project root so
/// a keystroke reuses them instead of re-walking the tree. The compiler core
/// still names no specific lib — this driver-side resolver feeds it ordinary
/// `(uri, source)` pairs and `resolveImports` binds them generically.
const std = @import("std");
const manifest = @import("manifest");
const bp = @import("botopink");
const lsp_types = @import("./lsp_types.zig");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");

/// Optional process-environment handle. The server threads its `environ_map`
/// through so the graph honours `BOTOPINK_LIB_ROOTS` — keeping the LSP's root
/// list aligned with the CLI's (`compiler-cli/src/cli/libs.zig:resolveLibRoots`).
/// `null` is the "no env" test mode.
pub const EnvMap = ?*const std.process.Environ.Map;

/// Name of the env var that prepends extra lib roots, mirroring the CLI driver.
pub const ENV_VAR = "BOTOPINK_LIB_ROOTS";

/// One resolved dependency module: a real file URI (so go-to-def can jump into
/// it), its on-disk source, and whether it is a declaration-only `.d.bp` (those
/// are kept for go-to-def but excluded from the compile, mirroring the CLI).
pub const GraphModule = struct {
    uri: []const u8,
    source: []const u8,
    declaration: bool,
};

/// A source the graph could not load, as a located diagnostic.
///
/// All three failures used to be `catch continue`: a dependency named in
/// `botopink.json` that no library root carries, a `files` entry of a resolved
/// library that cannot be read, and a `.bp` under the project's own `src` that
/// cannot be read. A manifest the shared model refuses (the string-array
/// `dependencies`, a workspace where a package is needed, a `path` to a sibling
/// member, …) is the fourth: the same located error the CLI prints, on the
/// manifest it is in. The graph then silently returned a shorter module list, and
/// the editor blamed the *user's* file — every symbol the missing module
/// exports reported "unbound", pointing nowhere near the line that is actually
/// wrong. The CLI names the first two (05 step 5,
/// `compiler-cli/src/cli/libs.zig:loadOne` / `renderMissingFile`); this is the
/// language-server half, with the same two messages, plus the third, which the
/// CLI does not have because it fails the whole compile instead.
///
/// The location is on whatever the user has to fix. For the two manifest
/// entries that is the *manifest* naming the entry — the project's own
/// `botopink.json` for a missing dependency, the library's for an unreadable
/// `files` entry. For an unreadable `src` file it is **that file**, first
/// character: no manifest line mentions it, and a diagnostic on `botopink.json`
/// would name a file the manifest never names. Either way the server publishes
/// it against that URI and the editor shows it in the Problems panel with a
/// jump to the offending line.
pub const Problem = struct {
    /// `file://` URI of the manifest carrying the offending entry.
    uri: []const u8,
    /// The message the CLI prints for the same failure.
    message: []const u8,
    /// 0-based LSP position of the entry, and its length in bytes.
    line: u32,
    character: u32,
    length: u32,
};

const CachedProject = struct {
    arena: std.heap.ArenaAllocator,
    root: []const u8,
    deps: []GraphModule,
    problems: []Problem = &.{},

    fn destroy(self: *CachedProject, gpa: std.mem.Allocator) void {
        self.arena.deinit();
        gpa.destroy(self);
    }
};

pub const Resolved = struct {
    /// Dependency modules (libs + project `src` files), borrowed from the cache.
    /// Valid until the next `invalidateAll`.
    deps: []const GraphModule,
    /// Manifest entries the graph could not follow, borrowed from the cache.
    /// Empty for a healthy project.
    problems: []const Problem = &.{},
    /// True when these deps came from the cache (no disk walk this call).
    hit: bool,
};

pub const ProjectGraph = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    /// Process env — read for `BOTOPINK_LIB_ROOTS` so the LSP and the CLI see
    /// the same root list (otherwise "go to definition" can misroute when bpmp
    /// is in play).
    env_map: EnvMap,
    /// project-root path → cached dependency set.
    cache: std.StringHashMap(*CachedProject),

    pub fn init(gpa: std.mem.Allocator, io: std.Io, env_map: EnvMap) ProjectGraph {
        return .{
            .gpa = gpa,
            .io = io,
            .env_map = env_map,
            .cache = std.StringHashMap(*CachedProject).init(gpa),
        };
    }

    pub fn deinit(self: *ProjectGraph) void {
        var it = self.cache.iterator();
        while (it.next()) |e| {
            self.gpa.free(e.key_ptr.*);
            e.value_ptr.*.destroy(self.gpa);
        }
        self.cache.deinit();
    }

    /// Drop every cached project. Call on save / watched-file change so a lib or
    /// sibling edited on disk is re-read on the next resolve. A keystroke in the
    /// active document does NOT need this — the server overlays its in-memory
    /// source, so the cached deps stay valid.
    pub fn invalidateAll(self: *ProjectGraph) void {
        var it = self.cache.iterator();
        while (it.next()) |e| {
            self.gpa.free(e.key_ptr.*);
            e.value_ptr.*.destroy(self.gpa);
        }
        self.cache.clearRetainingCapacity();
    }

    /// Resolve the dependency modules for the project owning `active_uri`.
    /// Returns null when no `botopink.json` is found walking up from the file
    /// (the caller then falls back to a single-document compile).
    pub fn resolve(self: *ProjectGraph, active_uri: []const u8) !?Resolved {
        const active_path = lsp_types.uriToPath(active_uri);
        const root = (try self.findProjectRoot(active_path)) orelse return null;

        if (self.cache.get(root)) |cached| {
            self.gpa.free(root);
            return .{ .deps = cached.deps, .problems = cached.problems, .hit = true };
        }

        const cp = self.buildProject(root) catch |err| {
            self.gpa.free(root);
            return err;
        };
        // `cp.root` is arena-owned; the cache key is a gpa-owned dup.
        try self.cache.put(root, cp);
        return .{ .deps = cp.deps, .problems = cp.problems, .hit = false };
    }

    // ── building ──────────────────────────────────────────────────────────────

    fn buildProject(self: *ProjectGraph, root: []const u8) !*CachedProject {
        const cp = try self.gpa.create(CachedProject);
        errdefer self.gpa.destroy(cp);
        cp.* = .{ .arena = std.heap.ArenaAllocator.init(self.gpa), .root = undefined, .deps = &.{} };
        errdefer cp.arena.deinit();
        const a = cp.arena.allocator();
        cp.root = try a.dupe(u8, root);

        var deps: std.ArrayListUnmanaged(GraphModule) = .empty;
        var problems: std.ArrayListUnmanaged(Problem) = .empty;

        // Read the project manifest through the shared model. A refused
        // manifest is a `Problem` on it (the same text the CLI prints) and the
        // project still gets its own `src` files; a missing one yields no deps.
        var err: ?manifest.Located = null;
        const project: ?manifest.Manifest = manifest.read(a, self.io, root, &err) catch |e| switch (e) {
            error.NotFound => null,
            error.Invalid => blk: {
                try problems.append(a, try problemFromLocated(a, err.?));
                break :blk null;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        var src_rel: []const u8 = "src/";
        if (project) |m| {
            src_rel = m.src;
            if (m.isWorkspace()) {
                // The nearest manifest is an umbrella: nothing compiles from it.
                try problems.append(a, try problemFromLocated(a, workspaceProblem(a, m)));
            } else if (m.dependencies.len > 0) {
                // 1) Lib dependencies, in declared order, before the project's own files.
                const roots = try self.resolveRoots(root);
                defer {
                    for (roots) |r| self.gpa.free(r);
                    self.gpa.free(roots);
                }
                const entries = try manifest.scanRoots(a, self.io, roots);
                const store = try std.fs.path.join(a, &.{ root, ".botopinkbuild", "deps" });
                const fallback = try manifest.scanRoots(a, self.io, &.{store});
                for (m.dependencies) |dep| {
                    var derr: ?manifest.Located = null;
                    const resolved = manifest.resolveDependency(a, self.io, m, root, dep, entries, fallback, &derr) catch |e| switch (e) {
                        error.Invalid => {
                            try problems.append(a, try problemFromLocated(a, derr.?));
                            continue;
                        },
                        error.OutOfMemory => return error.OutOfMemory,
                    };
                    const r = resolved orelse {
                        // A dependency no root carries: name it where the
                        // project declares it, instead of dropping it and
                        // letting every symbol it exports red in the user's file.
                        try problems.append(a, try self.manifestProblem(
                            a,
                            root,
                            m.text,
                            "\"dependencies\"",
                            dep.name,
                            try std.fmt.allocPrint(a, "dependency '{s}' was not found under any library root", .{dep.name}),
                        ));
                        continue;
                    };
                    try self.loadLib(a, &deps, &problems, r.dir, r.manifest, dep.name);
                }
            }
        }

        // 2) The project's own `src` tree (`mod` siblings). Trailing slashes are
        // trimmed so the joined paths stay canonical and match the editor's URIs.
        const src_dir = try std.fs.path.join(self.gpa, &.{ root, std.mem.trimEnd(u8, src_rel, "/") });
        defer self.gpa.free(src_dir);
        try self.loadSrcTree(a, &deps, &problems, src_dir);

        // 3) The bundled packages (decisions 115–117) a loaded module imports:
        // the copy inside the compiler, as the CLI loads it
        // (`compiler-cli/src/cli/libs.zig` `appendBundled`), first in the list.
        // They have no file on disk, so their URI is the virtual
        // `file:///botopink-bundled/<package>/src/<file>`.
        const own_name: []const u8 = if (project) |m| m.name else "";
        try appendBundled(a, &deps, own_name);

        cp.deps = try deps.toOwnedSlice(a);
        cp.problems = try problems.toOwnedSlice(a);
        return cp;
    }

    /// Prepend the embedded modules of every bundled package a module of `deps`
    /// imports, until no new package is named. `own` is the project's name —
    /// inside a bundled library's own directory its sources are the project.
    fn appendBundled(a: std.mem.Allocator, deps: *std.ArrayListUnmanaged(GraphModule), own: []const u8) !void {
        const pkgs = bp.comptime_pipeline.bundled_packages;
        var loaded = [_]bool{false} ** pkgs.len;
        var added: std.ArrayListUnmanaged(GraphModule) = .empty;
        var changed = true;
        while (changed) {
            changed = false;
            for (pkgs, 0..) |pkg, i| {
                if (loaded[i] or pkg.modules.len == 0 or std.mem.eql(u8, pkg.name, own)) continue;
                var named = false;
                for (deps.items) |m| if (bp.comptime_pipeline.importsPackage(m.source, pkg.name)) {
                    named = true;
                };
                for (added.items) |m| if (bp.comptime_pipeline.importsPackage(m.source, pkg.name)) {
                    named = true;
                };
                if (!named) continue;
                loaded[i] = true;
                changed = true;
                for (pkg.modules) |bm| try added.append(a, .{
                    .uri = try std.fmt.allocPrint(a, "file:///botopink-bundled/{s}/src/{s}", .{ pkg.name, bm.file }),
                    .source = bm.source,
                    .declaration = false,
                });
            }
        }
        try deps.insertSlice(a, 0, added.items);
    }

    /// Load every `file` the resolved dependency `dep` at `lib_dir` lists as a module.
    fn loadLib(
        self: *ProjectGraph,
        a: std.mem.Allocator,
        deps: *std.ArrayListUnmanaged(GraphModule),
        problems: *std.ArrayListUnmanaged(Problem),
        lib_dir: []const u8,
        lib: manifest.Manifest,
        dep: []const u8,
    ) !void {
        const lib_src = std.mem.trimEnd(u8, lib.src, "/");
        for (lib.files) |file| {
            const path = try std.fs.path.join(self.gpa, &.{ lib_dir, lib_src, file });
            defer self.gpa.free(path);
            const source = std.Io.Dir.cwd().readFileAlloc(self.io, path, a, .limited(10 * 1024 * 1024)) catch |err| {
                // The library exists but one of the modules it publishes does
                // not: say which entry, and where the library declares it.
                const message = if (err == error.FileNotFound)
                    try std.fmt.allocPrint(a, "dependency '{s}' lists \"{s}\" in `files`, but {s} does not exist", .{ dep, file, path })
                else
                    try std.fmt.allocPrint(a, "dependency '{s}' lists \"{s}\" in `files`, but {s} could not be read ({s})", .{ dep, file, path, @errorName(err) });
                try problems.append(a, try self.manifestProblem(a, lib_dir, lib.text, "\"files\"", file, message));
                continue;
            };
            try deps.append(a, .{
                .uri = try lsp_types.pathToUri(a, path),
                .source = source,
                .declaration = std.mem.endsWith(u8, file, ".d.bp"),
            });
        }
    }

    /// Build a `Problem` at the `"<entry>"` string inside `<dir>/botopink.json`,
    /// searched from `key` (`"dependencies"` / `"files"`) so an entry that also
    /// appears elsewhere in the manifest is not matched first. Falls back to the
    /// key, then to the file's first character — the message carries the name
    /// either way, so a JSON shape this search does not understand degrades to a
    /// diagnostic on line 1 rather than to no diagnostic at all.
    fn manifestProblem(
        self: *ProjectGraph,
        a: std.mem.Allocator,
        dir: []const u8,
        text: []const u8,
        key: []const u8,
        entry: []const u8,
        message: []const u8,
    ) !Problem {
        const path = try std.fs.path.join(self.gpa, &.{ dir, "botopink.json" });
        defer self.gpa.free(path);

        const quoted = try std.fmt.allocPrint(a, "\"{s}\"", .{entry});
        const offset: usize, const length: usize = blk: {
            if (std.mem.indexOf(u8, text, key)) |k| {
                if (std.mem.indexOfPos(u8, text, k, quoted)) |at| break :blk .{ at, quoted.len };
                break :blk .{ k, key.len };
            }
            break :blk .{ 0, @min(text.len, 1) };
        };

        var line: u32 = 0;
        var line_start: usize = 0;
        for (text[0..offset], 0..) |c, i| {
            if (c == '\n') {
                line += 1;
                line_start = i + 1;
            }
        }
        return .{
            .uri = try lsp_types.pathToUri(a, path),
            .message = message,
            .line = line,
            .character = @intCast(offset - line_start),
            .length = @intCast(length),
        };
    }

    /// Append every `.bp` under `src_dir` (recursively) as a module.
    ///
    /// A file the walk finds but cannot read is a `Problem` on the file itself,
    /// not a `catch continue`: dropping it left the graph a module short with no
    /// diagnostic anywhere, and the editor then reported every symbol it exports
    /// as unbound in whatever imported it. The walk continues after the problem,
    /// so one unreadable file does not cost the project the rest of its tree.
    fn loadSrcTree(
        self: *ProjectGraph,
        a: std.mem.Allocator,
        deps: *std.ArrayListUnmanaged(GraphModule),
        problems: *std.ArrayListUnmanaged(Problem),
        src_dir: []const u8,
    ) !void {
        const dir = std.Io.Dir.cwd().openDir(self.io, src_dir, .{ .iterate = true, .access_sub_paths = true }) catch return;
        var d = dir;
        defer d.close(self.io);

        var walker = try d.walk(self.gpa);
        defer walker.deinit();

        while (try walker.next(self.io)) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.basename, ".bp")) continue;
            const abs = try std.fs.path.join(a, &.{ src_dir, entry.path });
            const source = entry.dir.readFileAlloc(self.io, entry.basename, a, .limited(10 * 1024 * 1024)) catch |err| {
                try problems.append(a, .{
                    .uri = try lsp_types.pathToUri(a, abs),
                    .message = try std.fmt.allocPrint(
                        a,
                        "'{s}' is part of this project's `src` tree, but it could not be read ({s})",
                        .{ abs, @errorName(err) },
                    ),
                    .line = 0,
                    .character = 0,
                    .length = 1,
                });
                continue;
            };
            try deps.append(a, .{
                .uri = try lsp_types.pathToUri(a, abs),
                .source = source,
                .declaration = std.mem.endsWith(u8, entry.basename, ".d.bp"),
            });
        }
    }

    // ── filesystem helpers ──────────────────────────────────────────────────────

    /// Resolve the ordered list of library roots — directories that directly hold
    /// a `<name>/botopink.json` — mirroring the CLI driver's `resolveLibRoots`.
    /// Two halves: (1) entries from `BOTOPINK_LIB_ROOTS` (env-driven, dropped
    /// silently when missing on disk), then (2) walking up from `project_root`,
    /// for each ancestor `D` (nearest-first): `D` itself when it holds a
    /// workspace manifest (its members), `D/repository/botopink-lang/libs`
    /// (bundled), `D/repository` (sibling projects), `D/libs` (legacy flat tree).
    /// De-duped first-occurrence-wins so an env entry always shadows a duplicate
    /// walk-up root. With the env unset the result is byte-identical to the
    /// former pure walk-up. Caller owns the slice and each element via gpa.
    /// Test-only wrapper around the private `resolveRoots`. Keeps the production
    /// caller path private (`buildProject`) while letting the LSP test suite drive
    /// the BOTOPINK_LIB_ROOTS prepend through `init(env_map)` end-to-end.
    pub fn resolveRootsForTesting(self: *ProjectGraph, project_root: []const u8) ![][]const u8 {
        return self.resolveRoots(project_root);
    }

    fn resolveRoots(self: *ProjectGraph, project_root: []const u8) ![][]const u8 {
        // Walking with `std.fs.path.dirname` only behaves correctly on absolute
        // paths — a relative `../../..` lexically shortens to `../..`, which
        // resolves to a *different* directory and the walk silently visits the
        // wrong ancestors. Normalize via process cwd before walking.
        var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
        const cwd_n = try std.process.currentPath(self.io, &cwd_buf);
        const cwd = cwd_buf[0..cwd_n];

        var abs_root_buf: ?[]u8 = null;
        defer if (abs_root_buf) |b| self.gpa.free(b);
        var dir: []const u8 = project_root;
        if (!std.fs.path.isAbsolute(project_root)) {
            const abs = try std.fs.path.resolve(self.gpa, &.{ cwd, project_root });
            abs_root_buf = abs;
            dir = abs;
        }

        var roots: std.ArrayListUnmanaged([]const u8) = .empty;
        errdefer {
            for (roots.items) |r| self.gpa.free(r);
            roots.deinit(self.gpa);
        }

        // 1. Env-driven roots. `BOTOPINK_LIB_ROOTS` is `:`/`;`-separated; each
        // entry is resolved to abs and dropped silently when the directory does
        // not exist (typos must not break a build that doesn't use the root).
        const env_roots = try parseEnvRoots(self.gpa, self.env_map, cwd);
        defer {
            for (env_roots) |r| self.gpa.free(r);
            self.gpa.free(env_roots);
        }
        for (env_roots) |er| try self.addRoot(&roots, &.{er});

        // 2. Walk-up roots.
        while (true) {
            if (manifest.isWorkspaceDir(self.io, dir)) try self.addRoot(&roots, &.{dir});
            try self.addRoot(&roots, &.{ dir, "repository", "botopink-lang", "libs" });
            try self.addRoot(&roots, &.{ dir, "repository" });
            try self.addRoot(&roots, &.{ dir, "libs" });
            const parent = std.fs.path.dirname(dir) orelse break;
            if (std.mem.eql(u8, parent, dir)) break;
            dir = parent;
        }
        return roots.toOwnedSlice(self.gpa);
    }

    /// Join `parts`; if it is an existing directory not already in `roots`, append
    /// it (transferring ownership), else free it.
    fn addRoot(self: *ProjectGraph, roots: *std.ArrayListUnmanaged([]const u8), parts: []const []const u8) !void {
        const cand = try std.fs.path.join(self.gpa, parts);
        var keep = false;
        defer if (!keep) self.gpa.free(cand);
        std.Io.Dir.cwd().access(self.io, cand, .{}) catch return;
        for (roots.items) |r| {
            if (std.mem.eql(u8, r, cand)) return;
        }
        try roots.append(self.gpa, cand);
        keep = true;
    }

    /// Walk up from the active file's directory to the nearest `botopink.json`.
    /// Returns the directory path (caller owns via gpa), or null.
    fn findProjectRoot(self: *ProjectGraph, active_path: []const u8) !?[]u8 {
        var dir = std.fs.path.dirname(active_path) orelse return null;
        while (true) {
            const candidate = try std.fs.path.join(self.gpa, &.{ dir, "botopink.json" });
            defer self.gpa.free(candidate);
            if (std.Io.Dir.cwd().access(self.io, candidate, .{})) |_| {
                return try self.gpa.dupe(u8, dir);
            } else |_| {}
            const parent = std.fs.path.dirname(dir) orelse return null;
            if (std.mem.eql(u8, parent, dir)) return null;
            dir = parent;
        }
    }
};

/// A shared-model refusal as an editor diagnostic: the same message, on the
/// manifest it is in, at the 0-based position the LSP wants.
fn problemFromLocated(a: std.mem.Allocator, l: manifest.Located) !Problem {
    return .{
        .uri = try lsp_types.pathToUri(a, l.file),
        .message = l.message,
        .line = @intCast(l.line - 1),
        .character = @intCast(if (l.col > 0) l.col - 1 else 0),
        .length = @intCast(l.span),
    };
}

/// The refusal for a document whose nearest manifest is a workspace.
fn workspaceProblem(a: std.mem.Allocator, m: manifest.Manifest) manifest.Located {
    _ = a;
    const key = "\"workspaces\"";
    const offset = std.mem.indexOf(u8, m.text, key) orelse 0;
    var line: usize = 1;
    var line_start: usize = 0;
    for (m.text[0..offset], 0..) |c, i| {
        if (c == '\n') {
            line += 1;
            line_start = i + 1;
        }
    }
    return .{
        .message = "botopink.json is a workspace, not a package — a member's own botopink.json is the project of a file inside it",
        .file = m.path,
        .source = m.text,
        .line = line,
        .col = offset - line_start + 1,
        .span = key.len,
    };
}

/// Read `BOTOPINK_LIB_ROOTS` from `env_map` and split it into absolute root
/// paths. Returns an empty slice when the map is null, the var is unset, or
/// the value is empty. Mirrors `compiler-cli/src/cli/libs.zig:parseEnvRoots`
/// so the LSP and the CLI agree on every interpretation (separator, empty
/// entries, relative-to-cwd resolution). Caller owns the slice and elements
/// via `gpa`.
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
/// Empty `value` → empty slice. Empty entries (`a::b` → `a`, `b`) are dropped.
/// Relative entries resolve against `cwd`. Split out so tests can drive
/// synthetic env contents.
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

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

fn freeRoots(gpa: std.mem.Allocator, roots: [][]const u8) void {
    for (roots) |r| gpa.free(r);
    gpa.free(roots);
}

test "parseEnvRootsString: empty value yields no roots" {
    const roots = try parseEnvRootsString(testing.allocator, "", "/cwd");
    defer freeRoots(testing.allocator, roots);
    try testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRootsString: relative entries resolve against cwd" {
    const sep = std.fs.path.delimiter;
    const value = try std.fmt.allocPrint(testing.allocator, "rel/one{c}/abs/two", .{sep});
    defer testing.allocator.free(value);
    const roots = try parseEnvRootsString(testing.allocator, value, "/home/u");
    defer freeRoots(testing.allocator, roots);
    try testing.expectEqual(@as(usize, 2), roots.len);
    try testing.expectEqualStrings("/home/u/rel/one", roots[0]);
    try testing.expectEqualStrings("/abs/two", roots[1]);
}

test "parseEnvRoots: null env_map yields empty slice (byte-identical to unset)" {
    const roots = try parseEnvRoots(testing.allocator, null, "/cwd");
    defer freeRoots(testing.allocator, roots);
    try testing.expectEqual(@as(usize, 0), roots.len);
}

test "parseEnvRoots: BOTOPINK_LIB_ROOTS set is parsed" {
    var map = std.process.Environ.Map.init(testing.allocator);
    defer map.deinit();
    const sep = std.fs.path.delimiter;
    const value = try std.fmt.allocPrint(testing.allocator, "/a{c}/b", .{sep});
    defer testing.allocator.free(value);
    try map.put(ENV_VAR, value);

    const roots = try parseEnvRoots(testing.allocator, &map, "/cwd");
    defer freeRoots(testing.allocator, roots);
    try testing.expectEqual(@as(usize, 2), roots.len);
    try testing.expectEqualStrings("/a", roots[0]);
    try testing.expectEqualStrings("/b", roots[1]);
}

// ── The graph over a workspace (decision 75) and the dependency object (76) ──

fn writeFileP(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

fn absUri(a: std.mem.Allocator, io: std.Io, rel: []const u8) ![]const u8 {
    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &cwd_buf);
    const abs = try std.fs.path.resolve(a, &.{ cwd_buf[0..n], rel });
    return lsp_types.pathToUri(a, abs);
}

test "resolve: a member's { workspace: true } dependency loads the sibling's files, no problems" {
    const gpa = testing.allocator;
    const io = testing.io;
    test_scratch.remove(io, "pg-ws");
    defer test_scratch.remove(io, "pg-ws");
    try writeFileP(io, test_scratch.path(io, "pg-ws/meta/repository/acme/botopink.json"),
        \\{ "name": "acme", "workspaces": ["modules/*"] }
    );
    try writeFileP(io, test_scratch.path(io, "pg-ws/meta/repository/acme/modules/acme/botopink.json"),
        \\{ "name": "acme", "files": ["root.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "pg-ws/meta/repository/acme/modules/acme/src/root.bp"),
        \\pub fn core() -> i32 { return 1; }
    );
    try writeFileP(io, test_scratch.path(io, "pg-ws/meta/repository/acme/modules/acme-web/botopink.json"),
        \\{ "name": "acme-web", "files": ["root.bp"], "dependencies": { "acme": { "workspace": true } } }
    );
    try writeFileP(io, test_scratch.path(io, "pg-ws/meta/repository/acme/modules/acme-web/src/root.bp"),
        \\import { core } from "acme";
    );

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var graph = ProjectGraph.init(gpa, io, null);
    defer graph.deinit();

    const active = try absUri(a, io, test_scratch.path(io, "pg-ws/meta/repository/acme/modules/acme-web/src/root.bp"));
    const resolved = (try graph.resolve(active)) orelse return error.TestExpectedProject;
    try testing.expectEqual(@as(usize, 0), resolved.problems.len);
    // The sibling's `root.bp` and the project's own `root.bp`.
    try testing.expectEqual(@as(usize, 2), resolved.deps.len);
    try testing.expect(std.mem.endsWith(u8, resolved.deps[0].uri, "/modules/acme/src/root.bp"));
    try testing.expect(std.mem.indexOf(u8, resolved.deps[0].source, "core") != null);
}

test "resolve: a refused manifest is a Problem on it — the array form, and a path to a sibling member" {
    const gpa = testing.allocator;
    const io = testing.io;
    test_scratch.remove(io, "pg-bad");
    defer test_scratch.remove(io, "pg-bad");
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/repository/acme/botopink.json"),
        \\{ "name": "acme", "workspaces": ["modules/*"] }
    );
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/repository/acme/modules/acme/botopink.json"),
        \\{ "name": "acme", "files": ["root.bp"] }
    );
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/repository/acme/modules/acme/src/root.bp"), "pub fn core() -> i32 { return 1; }");
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/repository/acme/modules/acme-web/botopink.json"),
        \\{ "name": "acme-web", "files": ["root.bp"],
        \\  "dependencies": { "acme": { "path": "../acme" } } }
    );
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/repository/acme/modules/acme-web/src/root.bp"), "import { core } from \"acme\";");
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/app/botopink.json"),
        \\{ "name": "app", "dependencies": ["acme"] }
    );
    try writeFileP(io, test_scratch.path(io, "pg-bad/meta/app/src/main.bp"), "pub fn main() {}");

    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    var graph = ProjectGraph.init(gpa, io, null);
    defer graph.deinit();

    const member = (try graph.resolve(try absUri(a, io, test_scratch.path(io, "pg-bad/meta/repository/acme/modules/acme-web/src/root.bp")))) orelse return error.TestExpectedProject;
    try testing.expectEqual(@as(usize, 1), member.problems.len);
    try testing.expectEqualStrings("\"acme\": path \"../acme\" points at the sibling member \"acme\" — use { \"workspace\": true }", member.problems[0].message);
    try testing.expect(std.mem.endsWith(u8, member.problems[0].uri, "/modules/acme-web/botopink.json"));
    try testing.expectEqual(@as(u32, 1), member.problems[0].line);
    try testing.expectEqual(@as(u32, 20), member.problems[0].character);
    // The project's own file is still there.
    try testing.expectEqual(@as(usize, 1), member.deps.len);

    const app = (try graph.resolve(try absUri(a, io, test_scratch.path(io, "pg-bad/meta/app/src/main.bp")))) orelse return error.TestExpectedProject;
    try testing.expectEqual(@as(usize, 1), app.problems.len);
    try testing.expect(std.mem.startsWith(u8, app.problems[0].message, "\"dependencies\" must be an object, not an array"));
    try testing.expectEqual(@as(u32, 0), app.problems[0].line);
    try testing.expectEqual(@as(usize, 1), app.deps.len);
}

test "resolve: an import of a bundled package loads its embedded modules, first, with no dependency" {
    const gpa = testing.allocator;
    const io = testing.io;
    // The first non-std bundled package, whichever it is — the graph names none.
    var pkg: ?bp.comptime_pipeline.BundledPackage = null;
    for (bp.comptime_pipeline.bundled_packages) |p| {
        if (p.modules.len > 0) {
            pkg = p;
            break;
        }
    }
    const bundled = pkg orelse return;
    test_scratch.remove(io, "pg-bundled");
    defer test_scratch.remove(io, "pg-bundled");
    try writeFileP(io, test_scratch.path(io, "pg-bundled/app/botopink.json"),
        \\{ "name": "app" }
    );
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    const main_src = try std.fmt.allocPrint(a, "import {{x}} from \"{s}\";\n", .{bundled.name});
    try writeFileP(io, test_scratch.path(io, "pg-bundled/app/src/main.bp"), main_src);

    var graph = ProjectGraph.init(gpa, io, null);
    defer graph.deinit();
    const active = try absUri(a, io, test_scratch.path(io, "pg-bundled/app/src/main.bp"));
    const resolved = (try graph.resolve(active)) orelse return error.TestExpectedProject;
    try testing.expectEqual(@as(usize, 0), resolved.problems.len);
    try testing.expectEqual(bundled.modules.len + 1, resolved.deps.len);
    const first = try std.fmt.allocPrint(a, "file:///botopink-bundled/{s}/src/{s}", .{ bundled.name, bundled.modules[0].file });
    try testing.expectEqualStrings(first, resolved.deps[0].uri);
    try testing.expect(std.mem.endsWith(u8, resolved.deps[resolved.deps.len - 1].uri, "/src/main.bp"));
}
