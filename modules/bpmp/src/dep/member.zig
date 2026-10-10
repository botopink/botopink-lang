/// The package a git dependency names inside its checkout (decision 344 of
/// 1.0.12-beta).
///
/// `bpmp install` clones a repository once per ref into
/// `<store>/<repo_key>/<rev>/`; a dependency with a `"subdir"` is the package
/// at `<checkout>/<subdir>`, and `.botopinkbuild/deps/<name>` links there. Its
/// `path` (and `{ "workspace": true }`) dependencies resolve from that
/// directory, so they land in the same checkout — the package's siblings come
/// at the same ref. `check` refuses, located, what would make that false or
/// leave the compiler a package it cannot read:
///
///   * a `subdir` with no `botopink.json` (in the project's manifest);
///   * a `subdir` whose manifest is a workspace — never a package — naming its
///     members' subdirs (in the project's manifest);
///   * a `subdir` holding a package of another name (in the project's
///     manifest: the dependency key is the import name);
///   * a `path` or `workspace` dependency anywhere in the package's in-checkout
///     closure that lands outside the checkout, by its spelling or through a
///     symbolic link (in the manifest that declares it), plus every refusal
///     the compiler's own resolution makes for it.
///
/// A dependency without `subdir` is the repository's root: its closure is
/// checked the same way when the root holds a package.
const std = @import("std");
const manifest = @import("manifest");

pub const Located = manifest.Located;

pub const Error = error{Invalid} || std.mem.Allocator.Error;

/// Check the package dependency `name` (spec `spec`, the project's manifest
/// `project`) names inside `checkout` — the absolute checkout root at commit
/// `rev`. Returns the directory `.botopinkbuild/deps/<name>` links to.
pub fn check(
    arena: std.mem.Allocator,
    io: std.Io,
    project: manifest.Manifest,
    name: []const u8,
    spec: manifest.DepSpec,
    checkout: []const u8,
    rev: []const u8,
    out_err: *?Located,
) Error![]const u8 {
    const git = spec.git orelse "";
    const short = rev[0..@min(rev.len, 12)];
    const dir = if (spec.subdir) |sub| try std.fs.path.join(arena, &.{ checkout, sub }) else checkout;

    var merr: ?Located = null;
    const m = manifest.read(arena, io, dir, &merr) catch |e| switch (e) {
        error.NotFound => {
            const sub = spec.subdir orelse return dir; // the compiler reports a root without one
            out_err.* = project.locateEntryAt("dependencies", name, try std.fmt.allocPrint(
                arena,
                "\"{s}\": subdir \"{s}\" holds no botopink.json in {s} at {s} (looked at {s}/botopink.json)",
                .{ name, sub, git, short, dir },
            ));
            return error.Invalid;
        },
        error.Invalid => {
            out_err.* = merr;
            return error.Invalid;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };

    if (m.isWorkspace()) {
        const sub = spec.subdir orelse return dir; // the compiler names a root workspace's members
        var werr: ?Located = null;
        const ws = manifest.expand(arena, io, m, &werr) catch |e| switch (e) {
            error.Invalid => {
                out_err.* = werr;
                return error.Invalid;
            },
            error.OutOfMemory => return error.OutOfMemory,
        };
        var list: std.ArrayListUnmanaged(u8) = .empty;
        for (ws.members, 0..) |mem, i| {
            if (i > 0) try list.appendSlice(arena, ", ");
            try list.appendSlice(arena, try relativeTo(arena, checkout, mem.dir));
        }
        if (ws.members.len == 0) try list.appendSlice(arena, "none");
        out_err.* = project.locateEntryAt("dependencies", name, try std.fmt.allocPrint(
            arena,
            "\"{s}\": subdir \"{s}\" is a workspace, not a package — name one of its members' subdirs: {s}",
            .{ name, sub, list.items },
        ));
        return error.Invalid;
    }

    if (spec.subdir) |sub| if (!std.mem.eql(u8, m.name, name)) {
        out_err.* = project.locateEntryAt("dependencies", name, try std.fmt.allocPrint(
            arena,
            "\"{s}\": subdir \"{s}\" holds a package named \"{s}\" — the dependency key is the import name and must match",
            .{ name, sub, m.name },
        ));
        return error.Invalid;
    };

    try checkClosure(arena, io, m, dir, checkout, git, out_err);
    return dir;
}

/// Walk the in-checkout closure of the package `m` at `dir`: every `path` and
/// `workspace` dependency, transitively. Each must land inside `checkout`; the
/// compiler's own resolution (`manifest.resolveDependency`) then refuses what
/// it would refuse at build time. `git` dependencies of the package are the
/// package's own business — the compiler resolves them by name.
fn checkClosure(
    arena: std.mem.Allocator,
    io: std.Io,
    m: manifest.Manifest,
    dir: []const u8,
    checkout: []const u8,
    git: []const u8,
    out_err: *?Located,
) Error!void {
    const Pkg = struct { m: manifest.Manifest, dir: []const u8 };
    var seen: std.StringArrayHashMapUnmanaged(void) = .empty;
    var work: std.ArrayListUnmanaged(Pkg) = .empty;
    try seen.put(arena, try std.fs.path.resolve(arena, &.{dir}), {});
    try work.append(arena, .{ .m = m, .dir = dir });
    while (work.pop()) |pkg| {
        for (pkg.m.dependencies) |dep| {
            if (dep.spec.git != null) continue;
            if (dep.spec.path) |p| {
                const target = try std.fs.path.resolve(arena, &.{ pkg.dir, p });
                if (!within(checkout, target) or !try realWithin(arena, io, checkout, target)) {
                    out_err.* = pkg.m.locateEntryAt("dependencies", dep.name, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\": path \"{s}\" leaves the checkout of {s} — a package of a git dependency names by path only packages of its own repository",
                        .{ dep.name, p, git },
                    ));
                    return error.Invalid;
                }
            }
            const r = (try manifest.resolveDependency(arena, io, pkg.m, pkg.dir, dep, &.{}, &.{}, out_err)) orelse continue;
            const rdir = try std.fs.path.resolve(arena, &.{r.dir});
            if (!within(checkout, rdir) or !try realWithin(arena, io, checkout, rdir)) {
                out_err.* = pkg.m.locateEntryAt("dependencies", dep.name, try std.fmt.allocPrint(
                    arena,
                    "\"{s}\" resolves to {s}, outside the checkout of {s} — a package of a git dependency names only packages of its own repository",
                    .{ dep.name, rdir, git },
                ));
                return error.Invalid;
            }
            if ((try seen.getOrPut(arena, rdir)).found_existing) continue;
            try work.append(arena, .{ .m = r.manifest, .dir = rdir });
        }
    }
}

/// `path` is `root` or below it, by spelling (both already resolved).
fn within(root: []const u8, path: []const u8) bool {
    const r = std.mem.trimEnd(u8, root, "/");
    const p = std.mem.trimEnd(u8, path, "/");
    if (std.mem.eql(u8, r, p)) return true;
    return p.len > r.len and std.mem.startsWith(u8, p, r) and p[r.len] == '/';
}

/// `path` is `root` or below it once symbolic links are followed. A path that
/// does not exist is left to the resolution that reads it.
fn realWithin(arena: std.mem.Allocator, io: std.Io, root: []const u8, path: []const u8) std.mem.Allocator.Error!bool {
    const real_path = std.Io.Dir.realPathFileAbsoluteAlloc(io, path, arena) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return true,
    };
    const real_root = std.Io.Dir.realPathFileAbsoluteAlloc(io, root, arena) catch |e| switch (e) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return true,
    };
    return within(real_root, real_path);
}

fn relativeTo(arena: std.mem.Allocator, root: []const u8, path: []const u8) std.mem.Allocator.Error![]const u8 {
    const r = std.mem.trimEnd(u8, root, "/");
    if (path.len > r.len + 1 and std.mem.startsWith(u8, path, r) and path[r.len] == '/') return path[r.len + 1 ..];
    return arena.dupe(u8, path);
}

// ── tests ─────────────────────────────────────────────────────────────────────
//
// The checkout is a plain directory tree here: `check` reads only what a clone
// leaves on disk. `install.zig` proves the clone half over a real repository.

const testing = std.testing;
const test_scratch = @import("test_scratch");

fn writeFile(io: std.Io, path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(io, d);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = path, .data = data });
}

fn absPath(a: std.mem.Allocator, rel: []const u8) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const n = try std.process.currentPath(testing.io, &buf);
    return std.fs.path.resolve(a, &.{ buf[0..n], rel });
}

/// A checkout under the test's scratch directory:
///   modules/web   — `web`, path dependency `../core`
///   modules/core  — `core`
///   modules/ws    — a workspace with the member `modules/ws/members/m`
///   modules/empty — no botopink.json
///   modules/escape — `escape`, path dependency `../../../outside`
///   modules/hop   — `hop`, path dependency `../web` (whose own `../core` is inside)
///   modules/linked — `linked`, path dependency `../link`, a symbolic link out of the checkout
fn makeCheckout(a: std.mem.Allocator, comptime test_name: []const u8) ![]const u8 {
    const io = testing.io;
    const root = try absPath(a, test_scratch.path(io, "bpmp-tests/" ++ test_name));
    std.Io.Dir.cwd().deleteTree(io, root) catch {};
    const co = try std.fs.path.join(a, &.{ root, "checkout" });
    const f = struct {
        fn at(al: std.mem.Allocator, base: []const u8, rel: []const u8) ![]const u8 {
            return std.fs.path.join(al, &.{ base, rel });
        }
    }.at;
    try writeFile(io, try f(a, co, "modules/web/botopink.json"),
        \\{ "name": "web", "dependencies": { "core": { "path": "../core" } } }
    );
    try writeFile(io, try f(a, co, "modules/core/botopink.json"),
        \\{ "name": "core" }
    );
    try writeFile(io, try f(a, co, "modules/ws/botopink.json"),
        \\{ "name": "ws", "workspaces": ["members/*"] }
    );
    try writeFile(io, try f(a, co, "modules/ws/members/m/botopink.json"),
        \\{ "name": "m" }
    );
    try writeFile(io, try f(a, co, "modules/empty/README"), "no manifest here\n");
    try writeFile(io, try f(a, co, "modules/escape/botopink.json"),
        \\{ "name": "escape", "dependencies": { "outside": { "path": "../../../outside" } } }
    );
    try writeFile(io, try f(a, root, "outside/botopink.json"),
        \\{ "name": "outside" }
    );
    try writeFile(io, try f(a, co, "modules/hop/botopink.json"),
        \\{ "name": "hop", "dependencies": { "web": { "path": "../web" } } }
    );
    try writeFile(io, try f(a, co, "modules/linked/botopink.json"),
        \\{ "name": "linked", "dependencies": { "link": { "path": "../link" } } }
    );
    try writeFile(io, try f(a, root, "elsewhere/link/botopink.json"),
        \\{ "name": "link" }
    );
    try std.Io.Dir.cwd().symLink(io, try f(a, root, "elsewhere/link"), try f(a, co, "modules/link"), .{ .is_directory = true });
    return co;
}

fn projectWith(a: std.mem.Allocator, deps_json: []const u8) !manifest.Manifest {
    var err: ?Located = null;
    const text = try std.fmt.allocPrint(a, "{{ \"name\": \"app\", \"dependencies\": {s} }}", .{deps_json});
    return manifest.parse(a, text, "botopink.json", &err);
}

fn refusal(a: std.mem.Allocator, co: []const u8, name: []const u8, subdir: ?[]const u8) ![]const u8 {
    const deps = if (subdir) |s|
        try std.fmt.allocPrint(a, "{{ \"{s}\": {{ \"git\": \"file:///r.git\", \"tag\": \"v1\", \"subdir\": \"{s}\" }} }}", .{ name, s })
    else
        try std.fmt.allocPrint(a, "{{ \"{s}\": {{ \"git\": \"file:///r.git\", \"tag\": \"v1\" }} }}", .{name});
    const project = try projectWith(a, deps);
    var err: ?Located = null;
    try testing.expectError(error.Invalid, check(a, testing.io, project, name, project.dependencies[0].spec, co, "0123456789abcdef0123456789abcdef01234567", &err));
    return err.?.renderAlloc(a);
}

test "check: a subdir package and its path sibling resolve inside the checkout" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const co = try makeCheckout(a, "member-ok");
    const project = try projectWith(a,
        \\{ "web": { "git": "file:///r.git", "tag": "v1", "subdir": "modules/web" },
        \\  "hop": { "git": "file:///r.git", "tag": "v1", "subdir": "modules/hop" } }
    );
    var err: ?Located = null;
    const dir = try check(a, testing.io, project, "web", project.dependencies[0].spec, co, "0123456789ab", &err);
    try testing.expectEqualStrings(try std.fs.path.join(a, &.{ co, "modules/web" }), dir);
    // Two hops by path, both inside.
    _ = try check(a, testing.io, project, "hop", project.dependencies[1].spec, co, "0123456789ab", &err);
}

test "check: a subdir with no botopink.json is refused in the project's manifest" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const co = try makeCheckout(a, "member-empty");
    const out = try refusal(a, co, "empty", "modules/empty");
    try testing.expect(std.mem.startsWith(u8, out, "error: \"empty\": subdir \"modules/empty\" holds no botopink.json in file:///r.git at 0123456789ab (looked at "));
    try testing.expect(std.mem.indexOf(u8, out, "--> botopink.json:1:36") != null);
    const missing = try refusal(a, co, "nope", "modules/nope");
    try testing.expect(std.mem.indexOf(u8, missing, "subdir \"modules/nope\" holds no botopink.json") != null);
}

test "check: a subdir whose manifest is a workspace is refused, naming its members' subdirs" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const co = try makeCheckout(a, "member-workspace");
    const out = try refusal(a, co, "ws", "modules/ws");
    try testing.expect(std.mem.startsWith(u8, out, "error: \"ws\": subdir \"modules/ws\" is a workspace, not a package — name one of its members' subdirs: modules/ws/members/m\n"));
}

test "check: a subdir holding a package of another name is refused" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const co = try makeCheckout(a, "member-name");
    const out = try refusal(a, co, "webx", "modules/web");
    try testing.expect(std.mem.startsWith(u8, out, "error: \"webx\": subdir \"modules/web\" holds a package named \"web\" — the dependency key is the import name and must match\n"));
}

test "check: a path dependency leaving the checkout is refused in the manifest that declares it" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const co = try makeCheckout(a, "member-escape");
    const out = try refusal(a, co, "escape", "modules/escape");
    try testing.expect(std.mem.startsWith(u8, out, "error: \"outside\": path \"../../../outside\" leaves the checkout of file:///r.git — a package of a git dependency names by path only packages of its own repository\n"));
    try testing.expect(std.mem.indexOf(u8, out, "modules/escape/botopink.json:1:") != null);
    // Through a symbolic link that points out of the checkout.
    const linked = try refusal(a, co, "linked", "modules/linked");
    try testing.expect(std.mem.startsWith(u8, linked, "error: \"link\": path \"../link\" leaves the checkout of file:///r.git"));
}
