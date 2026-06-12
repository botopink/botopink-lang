/// Module-tree resolver — builds a package's module set by following explicit
/// `mod` / `pub mod` declarations from the package root, instead of blindly
/// walking every `.bp` under `src/` (Rust-style explicit module tree).
///
/// Starting at the root file (`main.bp` for a binary, `root.bp` for a library —
/// `botopink.json` `entry` chooses), it parses each module, reads its `mod`
/// declarations, and resolves every `mod Name;` to `Name.bp` (a sibling file)
/// or `Name/mod.bp` (a folder index) in the declaring file's directory. Exactly
/// one must exist — both or neither is an error. A `.bp` under `src/` not
/// reached through any `mod` path is reported as orphaned (and not compiled).
const std = @import("std");
const bp = @import("botopink");

const Module = bp.Module;
const Lexer = bp.Lexer;
const Parser = bp.Parser;

pub const Error = error{
    RootNotFound,
    ModuleNotFound,
    AmbiguousModule,
    DuplicateModule,
    PrivateModuleImport,
    UnexportedImport,
} || std.mem.Allocator.Error;

/// Diagnostic detail for a resolution failure. `kind` selects the message; the
/// string fields are owned by the caller-supplied diag arena (set to the result
/// of `resolve` only on error).
pub const Diagnostic = struct {
    kind: Error,
    /// The `mod` name (or logical path) that failed to resolve.
    name: []const u8 = "",
    /// The file that declared the offending `mod`, for the error location.
    declared_in: []const u8 = "",
    /// Candidate paths considered (for ambiguous/missing diagnostics).
    sibling: []const u8 = "",
    folder: []const u8 = "",
    /// For a `PrivateModuleImport`: the module that issued the import.
    importer: []const u8 = "",
    /// For a `PrivateModuleImport`: the target module being imported.
    target: []const u8 = "",
};

/// A `.bp` file under `src/` that no `mod` path reached — not compiled.
pub const Orphan = struct {
    /// Path relative to cwd, e.g. `"src/dangling.bp"`.
    file: []const u8,
};

/// Result of resolving a package's module tree.
/// `modules` is a flat `Module[]` keyed by logical module path (the `mod` chain
/// joined with '/', e.g. `"shapes/circle"`); `path`/`source` are gpa-owned —
/// free with `freeModules`. `orphans` lists unreferenced `.bp` files (gpa-owned
/// — free with `freeOrphans`).
pub const Resolution = struct {
    modules: []Module,
    orphans: []Orphan,
};

const WorkItem = struct {
    /// Logical module path (the key), e.g. "main", "shapes", "shapes/circle".
    logical: []const u8,
    /// File path relative to cwd, e.g. "src/shapes/circle.bp".
    file: []const u8,
    /// Whether the declaring `mod` was `pub mod` (the root counts as public).
    is_pub: bool = true,
    /// Index in `modules`/`nodes` of the declaring (parent) module; null = root.
    parent: ?usize = null,
};

/// A node in the resolved module tree — the visibility data path-visibility
/// checks walk. Parallel to `modules` (same index) before reordering.
const Node = struct {
    is_pub: bool,
    parent: ?usize,
};

/// Resolve the module tree of the package whose source lives in `src_dir_path`
/// (relative to cwd). `entry` is the root file relative to `src_dir_path`, or
/// null to auto-detect (`main.bp` then `root.bp`). On a resolution error the
/// `*diag` (if non-null) is filled with detail allocated in `diag_arena`.
pub fn resolve(
    gpa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
    entry: ?[]const u8,
    diag_arena: std.mem.Allocator,
    diag: ?*Diagnostic,
) Error!Resolution {
    // Scratch arena for parsing + bookkeeping; only final modules are gpa-owned.
    var scratch = std.heap.ArenaAllocator.init(gpa);
    defer scratch.deinit();
    const sa = scratch.allocator();

    // Find the root file.
    const root_file = try resolveRoot(sa, io, src_dir_path, entry) orelse
        return fail(diag, diag_arena, .{ .kind = Error.RootNotFound, .declared_in = src_dir_path });
    const root_logical = stripBpExt(std.fs.path.basename(root_file));

    var modules: std.ArrayListUnmanaged(Module) = .empty;
    errdefer freeAccumulated(gpa, &modules);
    // `nodes` mirrors `modules` (same index) and carries the tree's visibility
    // data; scratch-owned (only needed during resolution).
    var nodes: std.ArrayListUnmanaged(Node) = .empty;

    // Set of resolved file paths (for orphan detection + duplicate guard),
    // keyed in the scratch arena.
    var visited = std.StringHashMapUnmanaged(void){};

    var work: std.ArrayListUnmanaged(WorkItem) = .empty;
    try work.append(sa, .{ .logical = try sa.dupe(u8, root_logical), .file = root_file });

    while (work.items.len > 0) {
        const item = work.orderedRemove(0);

        if (visited.contains(item.file)) {
            return fail(diag, diag_arena, .{ .kind = Error.DuplicateModule, .name = item.logical, .declared_in = item.file });
        }
        try visited.put(sa, item.file, {});

        const source = std.Io.Dir.cwd().readFileAlloc(io, item.file, gpa, .unlimited) catch
            return fail(diag, diag_arena, .{ .kind = Error.ModuleNotFound, .name = item.logical, .declared_in = item.file });

        const my_idx = modules.items.len;

        // Transfer `source` + `logical` ownership to `modules` (freed wholesale
        // by the function's `errdefer freeAccumulated`). No per-item errdefer:
        // once appended it would double-free with `freeAccumulated`.
        const logical = gpa.dupe(u8, item.logical) catch {
            gpa.free(source);
            return Error.OutOfMemory;
        };
        modules.append(gpa, .{ .path = logical, .source = source }) catch {
            gpa.free(source);
            gpa.free(logical);
            return Error.OutOfMemory;
        };
        try nodes.append(sa, .{ .is_pub = item.is_pub, .parent = item.parent });

        // Parse just enough to read the `mod` declarations. A parse failure here
        // is not fatal — the module is still compiled (the real pipeline reports
        // the error); we simply can't descend into its submodules.
        const decl_dir = std.fs.path.dirname(item.file) orelse src_dir_path;
        try collectChildren(sa, diag_arena, io, source, item.logical, decl_dir, root_logical, my_idx, &work, diag);
    }

    const orphans = try collectOrphans(gpa, io, src_dir_path, &visited);

    // Analyze the cross-module import graph once: which module owns each `pub`
    // symbol, and what each module imports. Used for both visibility and order.
    const analysis = analyzeModules(sa, modules.items);

    // F3 — imports resolve through the tree: an `import {x} from "a.b"` that
    // names a real package module must find `x` publicly exported there.
    try checkImportResolution(sa, modules.items, analysis, diag_arena, diag);

    // F2 — path-visibility: an import may cross into a module only if every
    // `mod` on its path is `pub mod`. Reject imports that reach a private module
    // from outside its declaring module's subtree (the private segment named).
    try checkVisibility(sa, modules.items, nodes.items, analysis, diag_arena, diag);

    // The comptime pipeline resolves imports by registering each module's
    // exports as it compiles, so an imported module must be compiled before its
    // importer. Reorder the discovered modules into dependency order (a parent
    // folder index that imports its submodules compiles after them).
    orderByDependencies(sa, modules.items, analysis);

    const owned_modules = try modules.toOwnedSlice(gpa);
    return .{ .modules = owned_modules, .orphans = orphans };
}

/// Parse `source`, resolve each `mod`/`pub mod` declaration to a file, and push
/// the resolved children onto `work`. `decl_dir` is the directory the `mod`s
/// resolve in (the declaring file's directory).
fn collectChildren(
    sa: std.mem.Allocator,
    diag_arena: std.mem.Allocator,
    io: std.Io,
    source: []const u8,
    parent_logical: []const u8,
    decl_dir: []const u8,
    root_logical: []const u8,
    parent_idx: usize,
    work: *std.ArrayListUnmanaged(WorkItem),
    diag: ?*Diagnostic,
) Error!void {
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(sa) catch return; // lex error → compiled later, no descent
    var p = Parser.init(tokens);
    var program = p.parse(sa) catch return; // parse error → compiled later, no descent
    defer program.deinit(sa);

    for (program.decls) |decl| {
        const m = switch (decl) {
            .mod => |m| m,
            else => continue,
        };

        // Candidate paths: sibling `Name.bp` or folder index `Name/mod.bp`.
        const sibling = try std.fs.path.join(sa, &.{ decl_dir, try concat(sa, m.name, ".bp") });
        const folder = try std.fs.path.join(sa, &.{ decl_dir, m.name, "mod.bp" });
        const has_sibling = exists(io, sibling);
        const has_folder = exists(io, folder);

        if (has_sibling and has_folder) {
            return fail(diag, diag_arena, .{ .kind = Error.AmbiguousModule, .name = m.name, .declared_in = decl_dir, .sibling = sibling, .folder = folder });
        }
        if (!has_sibling and !has_folder) {
            return fail(diag, diag_arena, .{ .kind = Error.ModuleNotFound, .name = m.name, .declared_in = decl_dir, .sibling = sibling, .folder = folder });
        }

        // Logical path: top-level mods (declared in the root module) are bare
        // names; deeper mods nest under the parent's logical path.
        const logical = if (std.mem.eql(u8, parent_logical, root_logical))
            try sa.dupe(u8, m.name)
        else
            try std.fs.path.join(sa, &.{ parent_logical, m.name });

        try work.append(sa, .{
            .logical = logical,
            .file = if (has_sibling) sibling else folder,
            .is_pub = m.isPub,
            .parent = parent_idx,
        });
    }
}

/// Walk `src_dir_path` for `.bp` files (excluding `.d.bp`) that no `mod` path
/// reached. Returned slice + its `file` strings are gpa-owned.
fn collectOrphans(
    gpa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
    visited: *std.StringHashMapUnmanaged(void),
) Error![]Orphan {
    var orphans: std.ArrayListUnmanaged(Orphan) = .empty;
    errdefer {
        for (orphans.items) |o| gpa.free(o.file);
        orphans.deinit(gpa);
    }

    const dir = std.Io.Dir.cwd().openDir(io, src_dir_path, .{ .iterate = true, .access_sub_paths = true }) catch
        return try orphans.toOwnedSlice(gpa);
    var d = dir;
    defer d.close(io);

    var walker = try d.walk(gpa);
    defer walker.deinit();

    while (walker.next(io) catch null) |entry| {
        if (entry.kind != .file) continue;
        if (!isSource(entry.basename)) continue;
        const full = std.fs.path.join(gpa, &.{ src_dir_path, entry.path }) catch continue;
        if (visited.contains(full)) {
            gpa.free(full);
            continue;
        }
        try orphans.append(gpa, .{ .file = full });
    }
    return try orphans.toOwnedSlice(gpa);
}

/// Resolve the root source file (relative to cwd). Returns a scratch-owned path.
fn resolveRoot(
    sa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
    entry: ?[]const u8,
) Error!?[]const u8 {
    if (entry) |e| {
        const path = try std.fs.path.join(sa, &.{ src_dir_path, e });
        return if (exists(io, path)) path else null;
    }
    // Auto-detect: prefer `main.bp` (binary) then `root.bp` (library).
    for ([_][]const u8{ "main.bp", "root.bp" }) |name| {
        const path = try std.fs.path.join(sa, &.{ src_dir_path, name });
        if (exists(io, path)) return path;
    }
    return null;
}

/// One `import {…}` item: the imported definition-name plus the project module
/// it names. `from` is the slashed logical path of `from "a.b"` (dotted → "a/b")
/// when it could name a package module; null for a bare `import {x};`, `from
/// "std"`, or an external lib import — those resolve globally / via the loader.
const ImportRef = struct {
    from: ?[]const u8,
    symbol: []const u8,
};

/// The cross-module import graph, computed once from every module's source.
/// `owner` maps each `pub`-exported symbol to the first module that defines it;
/// `imports[i]`/`exports[i]` are module i's imports and `pub` export names;
/// `paths` maps a logical module path to its index. Imports resolve by symbol
/// name across the whole package, so an edge runs from a symbol's owner to each
/// module that imports it.
const Analysis = struct {
    owner: std.StringHashMapUnmanaged(usize),
    imports: []const []const ImportRef,
    exports: []const []const []const u8,
    paths: std.StringHashMapUnmanaged(usize),
};

fn analyzeModules(sa: std.mem.Allocator, mods: []const Module) Analysis {
    var owner = std.StringHashMapUnmanaged(usize){};
    var paths = std.StringHashMapUnmanaged(usize){};
    for (mods, 0..) |m, i| paths.put(sa, m.path, i) catch {};

    const empty: Analysis = .{ .owner = owner, .imports = &.{}, .exports = &.{}, .paths = paths };
    const imports = sa.alloc([]const ImportRef, mods.len) catch return empty;
    const exports = sa.alloc([]const []const u8, mods.len) catch return empty;
    for (mods, 0..) |m, i| {
        const refs = collectModuleRefs(sa, m.source, &owner, i) catch ModuleRefs{ .imports = &.{}, .exports = &.{} };
        imports[i] = refs.imports;
        exports[i] = refs.exports;
    }
    return .{ .owner = owner, .imports = imports, .exports = exports, .paths = paths };
}

/// Reorder `mods` in place so that every module precedes the modules that
/// import its symbols (a topological sort of the cross-module import graph).
/// Best-effort: on any allocation failure, or an import cycle, the affected
/// modules keep their discovery order (the compiler then reports the genuine
/// error). Ties break by logical path for determinism.
fn orderByDependencies(sa: std.mem.Allocator, mods: []Module, analysis: Analysis) void {
    const n = mods.len;
    if (n < 2 or analysis.imports.len != n) return;
    const owner = analysis.owner;
    const imports = analysis.imports;

    // Build the dependency graph: edge owner(sym) → importer.
    var indeg = sa.alloc(usize, n) catch return;
    @memset(indeg, 0);
    var adj = sa.alloc(std.ArrayListUnmanaged(usize), n) catch return;
    for (adj) |*a| a.* = .empty;

    for (imports, 0..) |imps, j| {
        var deps = std.AutoHashMapUnmanaged(usize, void){};
        for (imps) |ref| {
            const oi = owner.get(ref.symbol) orelse continue;
            if (oi == j) continue;
            deps.put(sa, oi, {}) catch continue;
        }
        var dit = deps.keyIterator();
        while (dit.next()) |oi_ptr| {
            adj[oi_ptr.*].append(sa, j) catch continue;
            indeg[j] += 1;
        }
    }

    // Kahn's algorithm with alphabetical (logical-path) tie-breaking.
    var result = sa.alloc(usize, n) catch return;
    var emitted = sa.alloc(bool, n) catch return;
    @memset(emitted, false);
    var count: usize = 0;
    while (count < n) {
        // Pick the not-yet-emitted, in-degree-0 module with the smallest path.
        var pick: ?usize = null;
        for (0..n) |i| {
            if (emitted[i] or indeg[i] != 0) continue;
            if (pick == null or std.mem.lessThan(u8, mods[i].path, mods[pick.?].path)) pick = i;
        }
        const i = pick orelse break; // cycle — bail out, keep remaining order
        emitted[i] = true;
        result[count] = i;
        count += 1;
        for (adj[i].items) |j| indeg[j] -= 1;
    }
    if (count < n) {
        // A cycle left some modules unemitted; append them in discovery order.
        for (0..n) |i| {
            if (!emitted[i]) {
                result[count] = i;
                count += 1;
            }
        }
    }

    // Permute `mods` into the computed order.
    const tmp = sa.alloc(Module, n) catch return;
    for (result, 0..) |idx, i| tmp[i] = mods[idx];
    @memcpy(mods, tmp);
}

const Boundary = struct {
    /// Logical path of the declaring module whose subtree the target is private
    /// to; the target is importable only from within this subtree.
    prefix: []const u8,
    /// The private `mod` segment (the name) that blocks the import.
    private_segment: []const u8,
};

/// Enforce path-visibility (F2): an import may reach module `target` only if it
/// is issued from within the subtree of the module that declared `target`'s
/// shallowest private `mod`. Imports owned by a package module that cross such a
/// boundary fail, naming the private segment. Imports of external (`from
/// "<lib>"`/`"std"`) symbols never appear in `owner`, so they are not checked.
fn checkVisibility(
    sa: std.mem.Allocator,
    mods: []const Module,
    nodes: []const Node,
    analysis: Analysis,
    diag_arena: std.mem.Allocator,
    diag: ?*Diagnostic,
) Error!void {
    if (analysis.imports.len != mods.len) return;
    const owner = analysis.owner;
    for (analysis.imports, 0..) |imps, importer| {
        for (imps) |ref| {
            const target = owner.get(ref.symbol) orelse continue;
            if (target == importer) continue;
            const b = visibilityBoundary(sa, mods, nodes, target) orelse continue;
            if (!withinSubtree(mods[importer].path, b.prefix)) {
                return fail(diag, diag_arena, .{
                    .kind = Error.PrivateModuleImport,
                    .name = b.private_segment,
                    .importer = mods[importer].path,
                    .target = mods[target].path,
                });
            }
        }
    }
}

/// Enforce import resolution through the tree (F3): when an `import {x} from
/// "a.b"` names a real package module (dotted path = the `mod` chain), that
/// module must publicly export `x`. Imports whose `from` is a bare/`std`/lib
/// source — or names a path that isn't a package module — are left to the
/// global resolver / generic loader, never flagged.
fn checkImportResolution(
    sa: std.mem.Allocator,
    mods: []const Module,
    analysis: Analysis,
    diag_arena: std.mem.Allocator,
    diag: ?*Diagnostic,
) Error!void {
    _ = sa;
    if (analysis.imports.len != mods.len) return;
    for (analysis.imports, 0..) |imps, importer| {
        for (imps) |ref| {
            const from = ref.from orelse continue;
            const target = analysis.paths.get(from) orelse continue; // not a package module
            if (target == importer) continue;
            if (!symbolInList(analysis.exports[target], ref.symbol)) {
                return fail(diag, diag_arena, .{
                    .kind = Error.UnexportedImport,
                    .name = ref.symbol,
                    .importer = mods[importer].path,
                    .target = mods[target].path,
                });
            }
        }
    }
}

fn symbolInList(names: []const []const u8, name: []const u8) bool {
    for (names) |n| if (std.mem.eql(u8, n, name)) return true;
    return false;
}

/// The visibility boundary of module `idx`: the subtree it is confined to by the
/// shallowest private `mod` on its path. Returns null when the module is
/// reachable package-wide — either every `mod` on its path is `pub`, or the
/// shallowest private one is a top-level `mod` (private to the root, i.e. the
/// whole package).
fn visibilityBoundary(sa: std.mem.Allocator, mods: []const Module, nodes: []const Node, idx: usize) ?Boundary {
    // Collect the module's ancestor chain (deepest first), excluding the root —
    // the root is not a `mod` segment and is always visible.
    var chain: std.ArrayListUnmanaged(usize) = .empty;
    var cur: ?usize = idx;
    while (cur) |c| {
        if (nodes[c].parent == null) break;
        chain.append(sa, c) catch return null;
        cur = nodes[c].parent;
    }
    // Walk root-first; the first private segment is the most restrictive.
    var i: usize = chain.items.len;
    while (i > 0) {
        i -= 1;
        const node_idx = chain.items[i];
        if (nodes[node_idx].is_pub) continue;
        const parent = nodes[node_idx].parent.?;
        // A top-level private `mod` is private to the root → package-wide.
        if (nodes[parent].parent == null) return null;
        return .{ .prefix = mods[parent].path, .private_segment = std.fs.path.basename(mods[node_idx].path) };
    }
    return null;
}

/// True when logical `path` is `prefix` itself or a descendant of it.
fn withinSubtree(path: []const u8, prefix: []const u8) bool {
    if (prefix.len == 0) return true;
    if (std.mem.eql(u8, path, prefix)) return true;
    return path.len > prefix.len and std.mem.startsWith(u8, path, prefix) and path[prefix.len] == '/';
}

const ModuleRefs = struct {
    imports: []const ImportRef,
    exports: []const []const u8,
};

/// Parse `source` and collect its imports (each with the project module it
/// names, if any) and its `pub` export names, while recording each exported
/// symbol's owning module index into `owner` (first definer wins). Best-effort
/// — a parse failure yields no refs.
fn collectModuleRefs(
    sa: std.mem.Allocator,
    source: []const u8,
    owner: *std.StringHashMapUnmanaged(usize),
    idx: usize,
) !ModuleRefs {
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(sa) catch return .{ .imports = &.{}, .exports = &.{} };
    var p = Parser.init(tokens);
    const program = p.parse(sa) catch return .{ .imports = &.{}, .exports = &.{} };

    var imps: std.ArrayListUnmanaged(ImportRef) = .empty;
    var exps: std.ArrayListUnmanaged([]const u8) = .empty;
    for (program.decls) |decl| switch (decl) {
        .@"fn" => |f| if (f.isPub) try registerExport(sa, owner, &exps, f.name, idx),
        .val => |v| if (v.isPub) try registerExport(sa, owner, &exps, v.name, idx),
        .record => |r| if (r.isPub) try registerExport(sa, owner, &exps, r.name, idx),
        .@"struct" => |s| if (s.isPub) try registerExport(sa, owner, &exps, s.name, idx),
        .@"enum" => |e| if (e.isPub) try registerExport(sa, owner, &exps, e.name, idx),
        .interface => |it| if (it.isPub) try registerExport(sa, owner, &exps, it.name, idx),
        .use => |u| {
            // `from "a.b"` → slashed logical path "a/b" when it could name a
            // package module; `from "std"`, a lib, or a bare import → null.
            const from: ?[]const u8 = switch (u.source) {
                .root => null,
                .module => |m| if (std.mem.eql(u8, m, "std")) null else try dotsToSlashes(sa, m),
            };
            for (u.imports) |imp| {
                // The imported symbol's definition name is its last path segment
                // (an `as` alias renames only the local binding, not the export).
                try imps.append(sa, .{ .from = from, .symbol = imp.segments[imp.segments.len - 1] });
            }
        },
        else => {},
    };
    return .{ .imports = try imps.toOwnedSlice(sa), .exports = try exps.toOwnedSlice(sa) };
}

fn registerExport(
    sa: std.mem.Allocator,
    owner: *std.StringHashMapUnmanaged(usize),
    exps: *std.ArrayListUnmanaged([]const u8),
    name: []const u8,
    idx: usize,
) !void {
    if (!owner.contains(name)) try owner.put(sa, name, idx);
    try exps.append(sa, name);
}

fn dotsToSlashes(sa: std.mem.Allocator, dotted: []const u8) ![]const u8 {
    const out = try sa.dupe(u8, dotted);
    for (out) |*c| {
        if (c.* == '.') c.* = '/';
    }
    return out;
}

// ── helpers ─────────────────────────────────────────────────────────────────

/// Record `d` into `*diag` (duping its strings into `da` so they outlive the
/// resolver's scratch arena) and return its error code, for `return fail(...)`.
fn fail(diag: ?*Diagnostic, da: std.mem.Allocator, d: Diagnostic) Error {
    if (diag) |p| p.* = .{
        .kind = d.kind,
        .name = da.dupe(u8, d.name) catch d.name,
        .declared_in = da.dupe(u8, d.declared_in) catch d.declared_in,
        .sibling = da.dupe(u8, d.sibling) catch d.sibling,
        .folder = da.dupe(u8, d.folder) catch d.folder,
        .importer = da.dupe(u8, d.importer) catch d.importer,
        .target = da.dupe(u8, d.target) catch d.target,
    };
    return d.kind;
}

fn exists(io: std.Io, path: []const u8) bool {
    std.Io.Dir.cwd().access(io, path, .{}) catch return false;
    return true;
}

fn isSource(name: []const u8) bool {
    if (std.mem.endsWith(u8, name, ".d.bp")) return false;
    return std.mem.endsWith(u8, name, ".bp") or std.mem.endsWith(u8, name, ".botopink");
}

fn stripBpExt(name: []const u8) []const u8 {
    for ([_][]const u8{ ".d.bp", ".botopink", ".bp" }) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return name[0 .. name.len - ext.len];
    }
    return name;
}

fn concat(a: std.mem.Allocator, x: []const u8, y: []const u8) Error![]u8 {
    return std.fmt.allocPrint(a, "{s}{s}", .{ x, y });
}

fn freeAccumulated(gpa: std.mem.Allocator, modules: *std.ArrayListUnmanaged(Module)) void {
    for (modules.items) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    modules.deinit(gpa);
}

/// Free a `Resolution.modules` slice (mirrors `scanner.freeModules`).
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    gpa.free(modules);
}

/// Free a `Resolution.orphans` slice.
pub fn freeOrphans(gpa: std.mem.Allocator, orphans: []Orphan) void {
    for (orphans) |o| gpa.free(o.file);
    gpa.free(orphans);
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "stripBpExt strips source extensions" {
    try std.testing.expectEqualStrings("main", stripBpExt("main.bp"));
    try std.testing.expectEqualStrings("page", stripBpExt("page.botopink"));
    try std.testing.expectEqualStrings("noext", stripBpExt("noext"));
}

test "isSource excludes declaration files" {
    try std.testing.expect(isSource("geometry.bp"));
    try std.testing.expect(isSource("page.botopink"));
    try std.testing.expect(!isSource("primitives.d.bp"));
    try std.testing.expect(!isSource("README.md"));
}

fn indexOfPath(mods: []const Module, path: []const u8) usize {
    for (mods, 0..) |m, i| if (std.mem.eql(u8, m.path, path)) return i;
    return std.math.maxInt(usize);
}

test "orderByDependencies orders imported modules before importers" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    // Discovery (BFS) order: root first — the wrong order for compilation.
    var mods = [_]Module{
        .{ .path = "main", .source =
        \\import {area} from "geometry";
        \\import {describe} from "shapes";
        \\fn main() {}
        },
        .{ .path = "geometry", .source = "pub fn area() -> i32 { return 1; }" },
        .{ .path = "shapes", .source =
        \\import {name} from "shapes.circle";
        \\pub fn describe() -> string { return name(); }
        },
        .{ .path = "shapes/circle", .source = "pub fn name() -> string { return \"c\"; }" },
    };

    orderByDependencies(sa, &mods, analyzeModules(sa, &mods));

    // Every importer compiles after the modules whose symbols it imports.
    try std.testing.expect(indexOfPath(&mods, "geometry") < indexOfPath(&mods, "main"));
    try std.testing.expect(indexOfPath(&mods, "shapes/circle") < indexOfPath(&mods, "shapes"));
    try std.testing.expect(indexOfPath(&mods, "shapes") < indexOfPath(&mods, "main"));
}

test "withinSubtree matches a module and its descendants only" {
    try std.testing.expect(withinSubtree("shapes/circle", "shapes"));
    try std.testing.expect(withinSubtree("shapes", "shapes"));
    try std.testing.expect(withinSubtree("anything", "")); // package-wide
    try std.testing.expect(!withinSubtree("shapesX", "shapes"));
    try std.testing.expect(!withinSubtree("main", "shapes"));
}

test "checkImportResolution rejects importing an unexported symbol from a named module" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    // main imports `area` from "geometry", which only exports `perimeter`.
    var mods = [_]Module{
        .{ .path = "main", .source = "import {area} from \"geometry\";\nfn main() {}" },
        .{ .path = "geometry", .source = "pub fn perimeter() -> i32 { return 1; }" },
    };
    const analysis = analyzeModules(sa, &mods);
    var diag: Diagnostic = .{ .kind = Error.RootNotFound };
    try std.testing.expectError(Error.UnexportedImport, checkImportResolution(sa, &mods, analysis, sa, &diag));
    try std.testing.expectEqualStrings("area", diag.name);
    try std.testing.expectEqualStrings("geometry", diag.target);
}

test "checkImportResolution accepts a correct export and ignores lib/std imports" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    var mods = [_]Module{
        // `from "rakun"` names no package module → ignored (lib); `from "std"` → ignored.
        .{ .path = "main", .source =
        \\import {area} from "geometry";
        \\import {Rakun} from "rakun";
        \\import {bool} from "std";
        \\fn main() {}
        },
        .{ .path = "geometry", .source = "pub fn area() -> i32 { return 1; }" },
    };
    const analysis = analyzeModules(sa, &mods);
    var diag: Diagnostic = .{ .kind = Error.RootNotFound };
    try checkImportResolution(sa, &mods, analysis, sa, &diag); // no error
}

test "checkVisibility rejects an import crossing a private mod boundary" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    // main(root) → shapes(pub) → helpers(private). Root imports helpers' symbol.
    var mods = [_]Module{
        .{ .path = "main", .source = "import {secret} from \"shapes.helpers\";\nfn main() {}" },
        .{ .path = "shapes", .source = "pub fn describe() -> i32 { return 1; }" },
        .{ .path = "shapes/helpers", .source = "pub fn secret() -> i32 { return 42; }" },
    };
    const nodes = [_]Node{
        .{ .is_pub = true, .parent = null }, // main (root)
        .{ .is_pub = true, .parent = 0 }, // pub mod shapes
        .{ .is_pub = false, .parent = 1 }, // mod helpers (private under shapes)
    };
    const analysis = analyzeModules(sa, &mods);
    var diag: Diagnostic = .{ .kind = Error.RootNotFound };
    try std.testing.expectError(Error.PrivateModuleImport, checkVisibility(sa, &mods, &nodes, analysis, sa, &diag));
    try std.testing.expectEqualStrings("helpers", diag.name);
    try std.testing.expectEqualStrings("main", diag.importer);
    try std.testing.expectEqualStrings("shapes/helpers", diag.target);
}

test "checkVisibility allows an import from within the private subtree" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    // circle is a sibling of helpers inside shapes — within helpers' boundary.
    var mods = [_]Module{
        .{ .path = "main", .source = "fn main() {}" },
        .{ .path = "shapes", .source = "pub fn describe() -> i32 { return 1; }" },
        .{ .path = "shapes/circle", .source = "import {secret} from \"shapes.helpers\";\npub fn c() -> i32 { return secret(); }" },
        .{ .path = "shapes/helpers", .source = "pub fn secret() -> i32 { return 42; }" },
    };
    const nodes = [_]Node{
        .{ .is_pub = true, .parent = null },
        .{ .is_pub = true, .parent = 0 },
        .{ .is_pub = true, .parent = 1 },
        .{ .is_pub = false, .parent = 1 },
    };
    const analysis = analyzeModules(sa, &mods);
    var diag: Diagnostic = .{ .kind = Error.RootNotFound };
    try checkVisibility(sa, &mods, &nodes, analysis, sa, &diag); // no error
}

test "orderByDependencies keeps a cycle's modules without crashing" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const sa = arena.allocator();

    // a imports from b, b imports from a — a genuine cycle.
    var mods = [_]Module{
        .{ .path = "a", .source = "import {fb} from \"b\";\npub fn fa() -> i32 { return fb(); }" },
        .{ .path = "b", .source = "import {fa} from \"a\";\npub fn fb() -> i32 { return fa(); }" },
    };
    orderByDependencies(sa, &mods, analyzeModules(sa, &mods));
    // Both modules survive (order is best-effort under a cycle).
    try std.testing.expectEqual(@as(usize, 2), mods.len);
    try std.testing.expect(indexOfPath(&mods, "a") != std.math.maxInt(usize));
    try std.testing.expect(indexOfPath(&mods, "b") != std.math.maxInt(usize));
}
