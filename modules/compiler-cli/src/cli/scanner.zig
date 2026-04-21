/// Source file scanner — walks `src/` recursively collecting `.bp` /
/// `.botopink` files and returns them as `botopink.Module` slices.
const std = @import("std");
const bp = @import("botopink");

const Module = bp.Module;

// ── Extensions ───────────────────────────────────────────────────────────────

const EXTS = [_][]const u8{ ".bp", ".botopink" };

fn hasSourceExt(name: []const u8) bool {
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

/// Scan `src_dir_path` (relative to cwd) recursively.
///
/// Returns a list of `Module` values.  Both `path` and `source` fields are
/// heap-allocated with `gpa` — call `freeModules` when done.
pub fn scanSources(
    gpa: std.mem.Allocator,
    io: std.Io,
    src_dir_path: []const u8,
) ![]Module {
    var modules: std.ArrayListUnmanaged(Module) = .empty;
    errdefer freeModules(gpa, modules.items);
    errdefer modules.deinit(gpa);

    const src_dir = std.Io.Dir.cwd().openDir(io, src_dir_path, .{
        .iterate = true,
        .access_sub_paths = true,
    }) catch |err| switch (err) {
        error.FileNotFound, error.NotDir => return try modules.toOwnedSlice(gpa),
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

        try modules.append(gpa, .{ .path = module_path, .source = source });
    }

    // Sort by path so compilation order is deterministic.
    const items = modules.items;
    std.mem.sort(Module, items, {}, struct {
        fn lt(_: void, a: Module, b: Module) bool {
            return std.mem.lessThan(u8, a.path, b.path);
        }
    }.lt);

    return modules.toOwnedSlice(gpa);
}

/// Free memory allocated by `scanSources`.
pub fn freeModules(gpa: std.mem.Allocator, modules: []Module) void {
    for (modules) |m| {
        gpa.free(m.path);
        gpa.free(m.source);
    }
    gpa.free(modules);
}
