/// Project-graph resolver for the language server.
///
/// The LSP used to compile each open document **alone** — `mod` siblings and
/// `from "<lib>"` / `from "std"` packages were unresolved, so completion,
/// go-to-def, and sub-language expansion died on any file that imports across
/// modules. This resolver rebuilds the dependency set the compiler would see,
/// using the same rules as the CLI driver:
///
///   * `from "<lib>"` → the lib's own `botopink.json` (`src` + `files`), read
///     from `<root>/<lib>/…` where `<root>` is the first entry in the resolved
///     root list (bundled `repository/botopink-lang/libs`, sibling `repository/`,
///     or legacy flat `libs/`) that carries `<lib>` — see `resolveRoots`.
///   * `mod` / `pub mod` siblings → every `.bp` under the project's `src/`.
///   * `from "std"` → handled inside the compiler (embedded), not here.
///
/// The active document's own source stays the hot, in-memory copy (the server
/// overlays it); dependencies are read from disk and cached per project root so
/// a keystroke reuses them instead of re-walking the tree. The compiler core
/// still names no specific lib — this driver-side resolver feeds it ordinary
/// `(uri, source)` pairs and `resolveImports` binds them generically.
const std = @import("std");
const lsp_types = @import("./lsp_types.zig");

/// One resolved dependency module: a real file URI (so go-to-def can jump into
/// it), its on-disk source, and whether it is a declaration-only `.d.bp` (those
/// are kept for go-to-def but excluded from the compile, mirroring the CLI).
pub const GraphModule = struct {
    uri: []const u8,
    source: []const u8,
    declaration: bool,
};

/// The project manifest fields this resolver consumes (`botopink.json`).
const ProjectManifest = struct {
    src: []const u8 = "src/",
    dependencies: []const []const u8 = &.{},
};

/// A lib's own manifest — the declaration surface it exports to consumers.
const LibManifest = struct {
    src: []const u8 = "src/",
    files: []const []const u8 = &.{},
};

const CachedProject = struct {
    arena: std.heap.ArenaAllocator,
    root: []const u8,
    deps: []GraphModule,

    fn destroy(self: *CachedProject, gpa: std.mem.Allocator) void {
        self.arena.deinit();
        gpa.destroy(self);
    }
};

pub const Resolved = struct {
    /// Dependency modules (libs + project `src` files), borrowed from the cache.
    /// Valid until the next `invalidateAll`.
    deps: []const GraphModule,
    /// True when these deps came from the cache (no disk walk this call).
    hit: bool,
};

pub const ProjectGraph = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    /// project-root path → cached dependency set.
    cache: std.StringHashMap(*CachedProject),

    pub fn init(gpa: std.mem.Allocator, io: std.Io) ProjectGraph {
        return .{ .gpa = gpa, .io = io, .cache = std.StringHashMap(*CachedProject).init(gpa) };
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
            return .{ .deps = cached.deps, .hit = true };
        }

        const cp = self.buildProject(root) catch |err| {
            self.gpa.free(root);
            return err;
        };
        // `cp.root` is arena-owned; the cache key is a gpa-owned dup.
        try self.cache.put(root, cp);
        return .{ .deps = cp.deps, .hit = false };
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

        // Read the project manifest (best effort: a missing/invalid one yields
        // no lib deps, just the local `src` files).
        const manifest = self.readManifest(ProjectManifest, a, root, "botopink.json") catch ProjectManifest{};

        // 1) Lib dependencies, in declared order, before the project's own files.
        if (manifest.dependencies.len > 0) {
            const roots = try self.resolveRoots(root);
            defer {
                for (roots) |r| self.gpa.free(r);
                self.gpa.free(roots);
            }
            for (manifest.dependencies) |dep| {
                self.loadLib(a, &deps, roots, dep) catch continue;
            }
        }

        // 2) The project's own `src` tree (`mod` siblings). Trailing slashes are
        // trimmed so the joined paths stay canonical and match the editor's URIs.
        const src_dir = try std.fs.path.join(self.gpa, &.{ root, std.mem.trimEnd(u8, manifest.src, "/") });
        defer self.gpa.free(src_dir);
        try self.loadSrcTree(a, &deps, src_dir);

        cp.deps = try deps.toOwnedSlice(a);
        return cp;
    }

    /// Load every `file` listed in `<root>/<dep>/botopink.json` as a module,
    /// resolving `dep` to the first root in `roots` that carries its manifest.
    fn loadLib(
        self: *ProjectGraph,
        a: std.mem.Allocator,
        deps: *std.ArrayListUnmanaged(GraphModule),
        roots: []const []const u8,
        dep: []const u8,
    ) !void {
        var resolved_dir: ?[]const u8 = null;
        var lib: LibManifest = undefined;
        for (roots) |root| {
            const cand = try std.fs.path.join(self.gpa, &.{ root, dep });
            if (self.readManifest(LibManifest, a, cand, "botopink.json")) |m| {
                lib = m;
                resolved_dir = cand;
                break;
            } else |_| self.gpa.free(cand);
        }
        const lib_dir = resolved_dir orelse return error.ManifestNotFound;
        defer self.gpa.free(lib_dir);
        const lib_src = std.mem.trimEnd(u8, lib.src, "/");
        for (lib.files) |file| {
            const path = try std.fs.path.join(self.gpa, &.{ lib_dir, lib_src, file });
            defer self.gpa.free(path);
            const source = std.Io.Dir.cwd().readFileAlloc(self.io, path, a, .limited(10 * 1024 * 1024)) catch continue;
            try deps.append(a, .{
                .uri = try lsp_types.pathToUri(a, path),
                .source = source,
                .declaration = std.mem.endsWith(u8, file, ".d.bp"),
            });
        }
    }

    /// Append every `.bp` under `src_dir` (recursively) as a module.
    fn loadSrcTree(
        self: *ProjectGraph,
        a: std.mem.Allocator,
        deps: *std.ArrayListUnmanaged(GraphModule),
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
            const source = entry.dir.readFileAlloc(self.io, entry.basename, a, .limited(10 * 1024 * 1024)) catch continue;
            const abs = try std.fs.path.join(a, &.{ src_dir, entry.path });
            try deps.append(a, .{
                .uri = try lsp_types.pathToUri(a, abs),
                .source = source,
                .declaration = std.mem.endsWith(u8, entry.basename, ".d.bp"),
            });
        }
    }

    // ── filesystem helpers ──────────────────────────────────────────────────────

    /// Parse `<dir>/<name>` into `a` (so its strings live as long as the cache).
    fn readManifest(self: *ProjectGraph, comptime T: type, a: std.mem.Allocator, dir: []const u8, name: []const u8) !T {
        const path = try std.fs.path.join(self.gpa, &.{ dir, name });
        defer self.gpa.free(path);
        const data = std.Io.Dir.cwd().readFileAlloc(self.io, path, a, .limited(64 * 1024)) catch return error.ManifestNotFound;
        return std.json.parseFromSliceLeaky(T, a, data, .{ .ignore_unknown_fields = true }) catch return error.ManifestInvalid;
    }

    /// Resolve the ordered list of library roots — directories that directly hold
    /// a `<name>/botopink.json` — mirroring the CLI driver's `resolveLibRoots`.
    /// Walking up from `project_root`, for each ancestor `D` (nearest-first) these
    /// roots are added when present: `D/repository/botopink-lang/libs` (bundled),
    /// `D/repository` (sibling projects), `D/libs` (legacy flat tree). De-duped,
    /// nearest-first. On the flat tree the list is exactly `[<ancestor>/libs]`, so
    /// resolution is byte-identical to the former single-root walk. Caller owns
    /// the slice and each element via gpa.
    fn resolveRoots(self: *ProjectGraph, project_root: []const u8) ![][]const u8 {
        // Walking with `std.fs.path.dirname` only behaves correctly on absolute
        // paths — a relative `../../..` lexically shortens to `../..`, which
        // resolves to a *different* directory and the walk silently visits the
        // wrong ancestors. Normalize via process cwd before walking.
        var abs_root_buf: ?[]u8 = null;
        defer if (abs_root_buf) |b| self.gpa.free(b);
        var dir: []const u8 = project_root;
        if (!std.fs.path.isAbsolute(project_root)) {
            var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
            const n = try std.process.currentPath(self.io, &cwd_buf);
            const abs = try std.fs.path.resolve(self.gpa, &.{ cwd_buf[0..n], project_root });
            abs_root_buf = abs;
            dir = abs;
        }

        var roots: std.ArrayListUnmanaged([]const u8) = .empty;
        errdefer {
            for (roots.items) |r| self.gpa.free(r);
            roots.deinit(self.gpa);
        }
        while (true) {
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
