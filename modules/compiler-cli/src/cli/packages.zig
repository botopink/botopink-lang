/// `botopink packages --list` — the packages of the checkout, one line each.
///
/// Decision 993 (2): the gate writes the in-process test program's `src/main.bp`
/// from this list. The set is the one the library test runner discovers
/// (`modules/lib-test-runner/src/discovery.zig`): the roots are `libs.resolveLibRoots`
/// (the same walk-up the runner does), the entries the shared `manifest.scanRoots`,
/// and a workspace that expands contributes its members, never itself.
///
/// A line is `<name>\t<dir>\t<targets>\t<kind>`: `dir` relative to the checkout
/// root (the directory ending the walk-up, `manifest.isCheckoutRoot`; the
/// absolute path when the package lies outside it, e.g. under
/// `BOTOPINK_LIB_ROOTS`); `targets` the manifest's `"targets"` joined by `,`
/// (a member inherits its workspace's, decision 75), `all` when none is
/// declared; `kind` `package`, or `not-a-package` for an entry discovery finds
/// that cannot be loaded: a refused manifest, a workspace that does not expand,
/// a name two libraries declare, a library member that lists no `files`.
/// Sorted by name, then dir.
const std = @import("std");
const manifest = @import("manifest");
const libs = @import("./libs.zig");

pub const Row = struct {
    name: []const u8,
    dir: []const u8,
    targets: []const u8,
    package: bool,
};

fn rowLess(_: void, a: Row, b: Row) bool {
    const by_name = std.mem.order(u8, a.name, b.name);
    if (by_name != .eq) return by_name == .lt;
    return std.mem.order(u8, a.dir, b.dir) == .lt;
}

/// The rows of `entries` (arena-owned results), `root` the checkout root that
/// `dir`s are made relative to.
pub fn rows(arena: std.mem.Allocator, io: std.Io, entries: []const manifest.Entry, root: []const u8) std.mem.Allocator.Error![]Row {
    var out: std.ArrayListUnmanaged(Row) = .empty;
    for (entries) |e| {
        // The umbrella is not a package — its members are; it stays only when
        // it is what is wrong (the runner's rule).
        if (e.is_workspace and e.problem == null) continue;
        const problem = e.problem != null or (e.workspace != null and e.manifest != null and manifest.shipsNothing(io, e.manifest.?) != null);
        const targets: []const u8 = blk: {
            const list = (e.manifest orelse break :blk "all").targets orelse break :blk "all";
            if (list.len == 0) break :blk "all";
            break :blk try std.mem.join(arena, ",", list);
        };
        try out.append(arena, .{
            .name = e.name,
            .dir = relativeTo(root, e.dir),
            .targets = targets,
            .package = !problem,
        });
    }
    std.mem.sort(Row, out.items, {}, rowLess);
    return out.toOwnedSlice(arena);
}

fn relativeTo(root: []const u8, dir: []const u8) []const u8 {
    if (std.mem.eql(u8, root, dir)) return ".";
    if (dir.len > root.len + 1 and std.mem.startsWith(u8, dir, root) and dir[root.len] == std.fs.path.sep) return dir[root.len + 1 ..];
    return dir;
}

pub fn render(arena: std.mem.Allocator, list: []const Row) std.mem.Allocator.Error![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (list) |r| {
        try buf.print(arena, "{s}\t{s}\t{s}\t{s}\n", .{ r.name, r.dir, r.targets, if (r.package) "package" else "not-a-package" });
    }
    return buf.toOwnedSlice(arena);
}

/// The checkout root for `cwd`: the first ancestor (or `cwd`) that ends the
/// library walk-up, else `cwd`.
fn checkoutRoot(io: std.Io, cwd: []const u8) []const u8 {
    var dir = cwd;
    while (true) {
        if (manifest.isCheckoutRoot(io, dir)) return dir;
        const parent = std.fs.path.dirname(dir) orelse return cwd;
        if (std.mem.eql(u8, parent, dir)) return cwd;
        dir = parent;
    }
}

pub fn run(gpa: std.mem.Allocator, io: std.Io, env_map: libs.EnvMap) !u8 {
    var arena_instance = std.heap.ArenaAllocator.init(gpa);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();

    var cwd_buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(io, &cwd_buf);
    const cwd = try arena.dupe(u8, cwd_buf[0..n]);

    const roots = try libs.resolveLibRoots(arena, io, env_map);
    const entries = try manifest.scanRoots(arena, io, roots);
    const list = try rows(arena, io, entries, checkoutRoot(io, cwd));
    const text = try render(arena, list);
    std.Io.File.stdout().writeStreamingAll(io, text) catch {};
    return 0;
}

test "rows sort by name then dir, and a relative dir is made from the root" {
    const a = std.testing.allocator;
    var arena_instance = std.heap.ArenaAllocator.init(a);
    defer arena_instance.deinit();
    const arena = arena_instance.allocator();
    const list = [_]Row{
        .{ .name = "b", .dir = "x", .targets = "all", .package = true },
        .{ .name = "a", .dir = "z", .targets = "erlang,beam", .package = false },
        .{ .name = "a", .dir = "y", .targets = "all", .package = true },
    };
    var sorted = list;
    std.mem.sort(Row, &sorted, {}, rowLess);
    try std.testing.expectEqualStrings("y", sorted[0].dir);
    try std.testing.expectEqualStrings("z", sorted[1].dir);
    const text = try render(arena, &sorted);
    try std.testing.expectEqualStrings("a\ty\tall\tpackage\na\tz\terlang,beam\tnot-a-package\nb\tx\tall\tpackage\n", text);
    try std.testing.expectEqualStrings("repository/q", relativeTo("/c", "/c/repository/q"));
    try std.testing.expectEqualStrings("/other/q", relativeTo("/c", "/other/q"));
}
