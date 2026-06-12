/// `botopink migrate` — derive an explicit module tree from the current `src/`
/// layout, the migration mechanism for the module system.
///
/// For every directory under `src/` it ensures an index file (`root.bp`/`main.bp`
/// at the package root, `mod.bp` in each subdirectory) and prepends a `pub mod
/// X;` declaration for each sibling `.bp` module and each `.bp`-bearing
/// subdirectory not already declared there. Defaulting to `pub mod` preserves
/// the old implicit-scan reachability (everything stays importable), so a
/// migrated package keeps building. Idempotent — re-running adds only what is
/// missing. `--dry-run` reports without writing.
const std = @import("std");
const reporter = @import("./reporter.zig");

pub const Options = struct {
    dry_run: bool = false,
};

// Reserved index basenames — never treated as ordinary `mod` modules.
const ROOT_BIN = "main.bp";
const ROOT_LIB = "root.bp";
const FOLDER_INDEX = "mod.bp";

pub fn run(gpa: std.mem.Allocator, io: std.Io, opts: Options) !u8 {
    var arena_inst = std.heap.ArenaAllocator.init(gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    // Gather the directory tree under src/ from a single recursive walk.
    var tree = collectTree(arena, io, "src") catch |err| {
        const msg = std.fmt.allocPrint(gpa, "could not scan src/: {s}", .{@errorName(err)}) catch "could not scan src/";
        reporter.errMsg(msg);
        return 1;
    };
    if (tree.dirs.count() == 0) {
        reporter.errMsg("no src/ directory found");
        return 1;
    }

    var changed: usize = 0;
    // Process every directory that contains sources.
    var it = tree.dirs.iterator();
    while (it.next()) |e| {
        const dir = e.key_ptr.*;
        const info = e.value_ptr.*;
        if (!info.has_sources) continue;
        changed += try migrateDir(gpa, arena, io, &tree, dir, opts);
    }

    if (changed == 0) {
        reporter.warnMsg("nothing to migrate — the module tree already covers src/");
    } else if (opts.dry_run) {
        reporter.hintMsg("dry run — re-run without --dry-run to write these files");
    }
    return 0;
}

// ── directory tree ──────────────────────────────────────────────────────────

const DirInfo = struct {
    /// `.bp` (non-`.d.bp`) basenames directly in this directory.
    files: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Direct child directory paths (relative to cwd).
    subdirs: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Whether this directory or any descendant holds a `.bp` source.
    has_sources: bool = false,
};

const Tree = struct {
    /// dir path (relative to cwd, e.g. "src", "src/shapes") → its contents.
    dirs: std.StringHashMapUnmanaged(DirInfo),

    fn ensure(self: *Tree, a: std.mem.Allocator, path: []const u8) *DirInfo {
        const gop = self.dirs.getOrPut(a, path) catch unreachable;
        if (!gop.found_existing) gop.value_ptr.* = .{};
        return gop.value_ptr;
    }
};

fn collectTree(a: std.mem.Allocator, io: std.Io, root: []const u8) !Tree {
    var tree: Tree = .{ .dirs = .{} };
    _ = tree.ensure(a, root); // the root always exists as a node

    const dir = std.Io.Dir.cwd().openDir(io, root, .{ .iterate = true, .access_sub_paths = true }) catch
        return tree;
    var d = dir;
    defer d.close(io);

    var walker = try d.walk(a);
    defer walker.deinit();

    while (walker.next(io) catch null) |entry| {
        const full = try std.fs.path.join(a, &.{ root, entry.path });
        const parent = std.fs.path.dirname(full) orelse root;
        switch (entry.kind) {
            .directory => {
                _ = tree.ensure(a, full);
                try tree.ensure(a, parent).subdirs.append(a, full);
            },
            .file => {
                if (!isSource(entry.basename)) continue;
                try tree.ensure(a, parent).files.append(a, try a.dupe(u8, entry.basename));
                // Mark this dir and every ancestor up to the root as sourced.
                markSourced(&tree, a, parent, root);
            },
            else => {},
        }
    }
    return tree;
}

fn markSourced(tree: *Tree, a: std.mem.Allocator, dir: []const u8, root: []const u8) void {
    var cur = dir;
    while (true) {
        tree.ensure(a, cur).has_sources = true;
        if (std.mem.eql(u8, cur, root)) break;
        cur = std.fs.path.dirname(cur) orelse break;
    }
}

// ── per-directory migration ─────────────────────────────────────────────────

fn migrateDir(
    gpa: std.mem.Allocator,
    a: std.mem.Allocator,
    io: std.Io,
    tree: *Tree,
    dir: []const u8,
    opts: Options,
) !usize {
    const is_root = std.mem.eql(u8, dir, "src");
    const info = tree.dirs.get(dir).?;

    const index = indexBasename(is_root, info.files);
    const index_path = try std.fs.path.join(a, &.{ dir, index });

    // Modules to declare: sibling `.bp` modules (not the index / reserved) and
    // `.bp`-bearing subdirectories.
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    for (info.files.items) |f| {
        if (isReserved(f)) continue;
        try names.append(a, stripBpExt(f));
    }
    for (info.subdirs.items) |sub| {
        const sub_info = tree.dirs.get(sub) orelse continue;
        if (!sub_info.has_sources) continue;
        try names.append(a, std.fs.path.basename(sub));
    }
    if (names.items.len == 0) return 0;
    std.mem.sort([]const u8, names.items, {}, lessStr);

    // Read the existing index (empty when absent).
    const existing: []const u8 = std.Io.Dir.cwd().readFileAlloc(io, index_path, a, .unlimited) catch "";
    const missing = existing.len == 0;

    // Collect the not-yet-declared module names.
    var fresh: std.ArrayListUnmanaged([]const u8) = .empty;
    for (names.items) |name| {
        if (!alreadyDeclared(existing, name)) try fresh.append(a, name);
    }
    if (fresh.items.len == 0) return 0;

    // Build the new content: a block of `pub mod X;` lines, then the old body.
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (fresh.items) |name| {
        try buf.appendSlice(a, "pub mod ");
        try buf.appendSlice(a, name);
        try buf.appendSlice(a, ";\n");
    }
    if (existing.len > 0) {
        if (existing[0] != '\n') try buf.append(a, '\n');
        try buf.appendSlice(a, existing);
    }

    const verb = if (missing) "create" else "update";
    const line = try std.fmt.allocPrint(gpa, "{s} {s}", .{ verb, index_path });
    defer gpa.free(line);
    if (opts.dry_run) {
        reporter.warnDetail("  would", line);
    } else {
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = index_path, .data = buf.items });
        reporter.created(index_path);
    }
    return 1;
}

/// The index file basename for a directory: `main.bp`/`root.bp` at the package
/// root (preferring an existing one, else `root.bp`), `mod.bp` in a subdir.
fn indexBasename(is_root: bool, files: std.ArrayListUnmanaged([]const u8)) []const u8 {
    if (!is_root) return FOLDER_INDEX;
    var has_main = false;
    var has_root = false;
    for (files.items) |f| {
        if (std.mem.eql(u8, f, ROOT_BIN)) has_main = true;
        if (std.mem.eql(u8, f, ROOT_LIB)) has_root = true;
    }
    if (has_main) return ROOT_BIN;
    if (has_root) return ROOT_LIB;
    return ROOT_LIB; // default new library root
}

/// True when a top-level line of `content` already declares `mod name;`.
fn alreadyDeclared(content: []const u8, name: []const u8) bool {
    var lines = std.mem.splitScalar(u8, content, '\n');
    while (lines.next()) |raw| {
        var line = std.mem.trim(u8, raw, " \t\r");
        if (std.mem.startsWith(u8, line, "pub ")) line = std.mem.trimStart(u8, line["pub ".len..], " \t");
        if (!std.mem.startsWith(u8, line, "mod ")) continue;
        const rest = std.mem.trim(u8, line["mod ".len..], " \t");
        const decl_name = std.mem.trimEnd(u8, rest, ";");
        if (std.mem.eql(u8, std.mem.trim(u8, decl_name, " \t"), name)) return true;
    }
    return false;
}

// ── helpers ─────────────────────────────────────────────────────────────────

fn isReserved(basename: []const u8) bool {
    return std.mem.eql(u8, basename, ROOT_BIN) or
        std.mem.eql(u8, basename, ROOT_LIB) or
        std.mem.eql(u8, basename, FOLDER_INDEX);
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

fn lessStr(_: void, x: []const u8, y: []const u8) bool {
    return std.mem.lessThan(u8, x, y);
}

// ── tests ─────────────────────────────────────────────────────────────────────

test "alreadyDeclared matches plain and pub mod lines" {
    const content =
        \\pub mod geometry;
        \\mod helpers;
        \\fn main() {}
    ;
    try std.testing.expect(alreadyDeclared(content, "geometry"));
    try std.testing.expect(alreadyDeclared(content, "helpers"));
    try std.testing.expect(!alreadyDeclared(content, "shapes"));
    // a substring of another name must not match
    try std.testing.expect(!alreadyDeclared(content, "geo"));
}

test "indexBasename prefers main.bp then root.bp at the root" {
    const none: std.ArrayListUnmanaged([]const u8) = .empty;
    try std.testing.expectEqualStrings("root.bp", indexBasename(true, none));
    try std.testing.expectEqualStrings("mod.bp", indexBasename(false, none));

    var with_main: std.ArrayListUnmanaged([]const u8) = .empty;
    with_main.append(std.testing.allocator, "main.bp") catch unreachable;
    defer with_main.deinit(std.testing.allocator);
    try std.testing.expectEqualStrings("main.bp", indexBasename(true, with_main));
}

test "isReserved + stripBpExt" {
    try std.testing.expect(isReserved("mod.bp"));
    try std.testing.expect(!isReserved("geometry.bp"));
    try std.testing.expectEqualStrings("geometry", stripBpExt("geometry.bp"));
}
