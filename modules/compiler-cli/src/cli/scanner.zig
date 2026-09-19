/// Source file scanner — walks `src/` recursively collecting `.bp` /
/// `.botopink` files and returns them as `botopink.Module` slices.
const std = @import("std");
const bp = @import("botopink");

const Module = bp.Module;

// ── Extensions ───────────────────────────────────────────────────────────────

const EXTS = [_][]const u8{ ".bp", ".botopink" };

fn hasSourceExt(name: []const u8) bool {
    // Declaration modules (`*.d.bp`) are type surface only — they declare
    // ambient builtins (bodyless `fn`), use declaration-file syntax the
    // regular pipeline rejects, and are embedded by the compiler separately.
    if (std.mem.endsWith(u8, name, ".d.bp")) return false;
    for (EXTS) |ext| {
        if (std.mem.endsWith(u8, name, ext)) return true;
    }
    return false;
}

fn stripExt(name: []const u8) []const u8 {
    for (EXTS) |ext| {
        if (std.mem.endsWith(u8, name, ext))
            return name[0 .. name.len - ext.len];
    }
    return name;
}

// ── Scanner ───────────────────────────────────────────────────────────────────

/// A flat directory scan: the modules and, aligned by index, the path each one
/// was read from (relative to cwd, extension included). A flat directory is not
/// a package, so it never reaches `resolver.resolve` and its imports are checked
/// separately (`sources.checkFlatImports`) — which needs the file to locate a
/// diagnostic in it.
pub const Scan = struct {
    modules: []Module,
    files: []const []const u8,

    pub fn free(self: *Scan, gpa: std.mem.Allocator) void {
        freeModules(gpa, self.modules);
        freeFiles(gpa, self.files);
    }
};

/// Scan `src_dir_path` (relative to cwd) recursively.
///
/// Returns a list of `Module` values.  Both `path` and `source` fields are
/// heap-allocated with `gpa` — call `freeModules` when done.
pub fn scanSources(
    gpa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
) ![]Module {
    const scan = try scanSourcesWithFiles(gpa, io, src_dir_path);
    freeFiles(gpa, scan.files);
    return scan.modules;
}

/// `scanSources` plus the file each module was read from, in the same order.
/// Both slices and every string in them are `gpa`-owned — free with
/// `Scan.free`, or with `freeModules` + `freeFiles`.
pub fn scanSourcesWithFiles(
    gpa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
) !Scan {
    // One list of pairs rather than two parallel lists: the sort below must
    // keep a module and its file together, and a single list cannot fall out
    // of step with itself.
    const Pair = struct { module: Module, file: []const u8 };
    var pairs: std.ArrayListUnmanaged(Pair) = .empty;
    errdefer {
        for (pairs.items) |pair| {
            gpa.free(pair.module.path);
            gpa.free(pair.module.source);
            gpa.free(pair.file);
        }
        pairs.deinit(gpa);
    }

    const src_dir = std.Io.Dir.cwd().openDir(io, src_dir_path, .{
        .iterate = true,
        .access_sub_paths = true,
    }) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return .{ .modules = &.{}, .files = &.{} },
        else => return err,
    };
    defer src_dir.close(io);

    var walker = try src_dir.walk(gpa);
    defer walker.deinit();

    while (try walker.next(io)) |entry| {
        if (entry.kind != .file) continue;
        if (!hasSourceExt(entry.basename)) continue;

        // Module path: path relative to src_dir, without extension.
        // e.g. "utils/math.bp" → "utils/math"
        const path_no_ext = stripExt(entry.path);
        const module_path = try gpa.dupe(u8, path_no_ext);
        errdefer gpa.free(module_path);

        const source = try entry.dir.readFileAlloc(io, entry.basename, gpa, .unlimited);
        errdefer gpa.free(source);

        const file = try std.fs.path.join(gpa, &.{ src_dir_path, entry.path });
        errdefer gpa.free(file);

        try pairs.append(gpa, .{ .module = .{ .path = module_path, .source = source }, .file = file });
    }

    // Sort by path so compilation order is deterministic.
    std.mem.sort(Pair, pairs.items, {}, struct {
        fn lt(_: void, a: Pair, b: Pair) bool {
            return std.mem.lessThan(u8, a.module.path, b.module.path);
        }
    }.lt);

    const modules = try gpa.alloc(Module, pairs.items.len);
    errdefer gpa.free(modules);
    const files = try gpa.alloc([]const u8, pairs.items.len);
    for (pairs.items, 0..) |pair, i| {
        modules[i] = pair.module;
        files[i] = pair.file;
    }
    pairs.deinit(gpa);
    return .{ .modules = modules, .files = files };
}

/// Free a `Scan.files` slice and its strings.
pub fn freeFiles(gpa: std.mem.Allocator, files: []const []const u8) void {
    for (files) |f| gpa.free(f);
    gpa.free(files);
}

/// Free memory allocated by `scanSources`.
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    gpa.free(modules);
}
