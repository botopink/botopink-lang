/// `bpmp link [<checkout>]` — link each `git` dependency of the project to a
/// local checkout (decision 483).
///
/// For every `git` dependency of every manifest of the project in the working
/// directory — a workspace's members included — `.botopinkbuild/deps/<name>`
/// becomes a symbolic link to `<checkout>/repository/<name>` (a dependency with
/// a `"subdir"`: `<checkout>/repository/<repository>/<subdir>`, `<repository>`
/// the last segment of its `git` URL). The compiler and the language server
/// resolve a `git` dependency from those links first (`manifest.depsRoots`).
///
/// * `<checkout>` defaults to the enclosing meta checkout: the nearest
///   directory, from the working directory up, that holds `repository/`
///   (`manifest.isCheckoutRoot`). A `<checkout>` given must hold `repository/`.
/// * The links are flat, as one `node_modules`: the `git` dependencies of a
///   linked package (and of its `path` / `workspace` closure inside the
///   checkout) are linked too, each name once — the compiler looks every
///   package of the build up in the project's links.
/// * A dependency whose local repository holds no `botopink.json` is named
///   (located at the entry that declares it) and the command fails before any
///   link is written — nothing is guessed, nothing is cloned. One name meaning
///   two directories is refused the same way.
/// * An existing `.botopinkbuild/deps/<name>` is replaced; links to names the
///   project no longer declares are left alone. No lockfile is written.
///
/// Run at a workspace root, the links go to the workspace root's
/// `.botopinkbuild/deps/` (one per name for every member), which the compiler
/// reads after a member's own; run in a package (a member included), to its own.
const std = @import("std");
const cli = @import("../cli.zig");
const common = @import("./common.zig");
const install = @import("./install.zig");
const manifest = @import("manifest");
/// Test-only: the one way a test spells a path it writes to.
const test_scratch = @import("test_scratch");

const HELP =
    \\bpmp link — link each git dependency to a local checkout (decision 483).
    \\
    \\Usage:
    \\  bpmp link [<checkout>]
    \\
    \\For every git dependency of the project's manifests (a workspace's members
    \\included, and the git dependencies of what they link), writes
    \\  .botopinkbuild/deps/<name> → <checkout>/repository/<name>
    \\replacing an existing link. <checkout> defaults to the nearest directory,
    \\from here up, that holds repository/. A dependency with no local repository
    \\is named and nothing is linked. Nothing is cloned; CI runs `bpmp install`.
    \\
;

pub fn run(ctx: cli.Context, args: []const []const u8) anyerror!u8 {
    var positional: ?[]const u8 = null;
    for (args) |a| {
        if (std.mem.eql(u8, a, "-h") or std.mem.eql(u8, a, "--help")) {
            common.writeStdout(ctx, HELP);
            return 0;
        } else if (std.mem.startsWith(u8, a, "-")) {
            return common.errFmt("link: unknown flag '{s}'", .{a});
        } else {
            if (positional != null) return common.errFmt("link: unexpected argument '{s}' — one <checkout> at most", .{a});
            positional = a;
        }
    }

    var arena_inst = std.heap.ArenaAllocator.init(ctx.gpa);
    defer arena_inst.deinit();
    const arena = arena_inst.allocator();

    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = try arena.dupe(u8, buf[0..try std.process.currentPath(ctx.io, &buf)]);

    const checkout = if (positional) |p| blk: {
        const abs = try std.fs.path.resolve(arena, &.{ cwd, p });
        if (!manifest.isCheckoutRoot(ctx.io, abs)) return common.errFmt("link: {s} holds no repository/ — <checkout> is a directory whose repository/<name> holds each library", .{abs});
        break :blk abs;
    } else findCheckout(ctx.io, cwd) orelse
        return common.errFmt("link: no directory from {s} up holds repository/ — name the checkout: bpmp link <checkout>", .{cwd});

    var err: ?manifest.Located = null;
    const p = plan(arena, ctx.io, cwd, checkout, &err) catch |e| switch (e) {
        error.NoManifest => return common.errFmt("link: no botopink.json in {s}", .{cwd}),
        error.Invalid => {
            err.?.print();
            return 1;
        },
        error.OutOfMemory => return error.OutOfMemory,
    };
    if (p.missing.len > 0) {
        for (p.missing) |m| m.print();
        return common.errFmt("link: {d} dependenc{s} with no local repository under {s}/repository — nothing linked", .{ p.missing.len, if (p.missing.len == 1) "y" else "ies", checkout });
    }

    for (p.links) |l| {
        const link_path = try std.fs.path.join(arena, &.{ cwd, manifest.DEPS_DIR, l.name });
        install.ensureSymlink(ctx.io, l.target, link_path) catch |e|
            return common.errFmt("link: could not link {s} → {s}: {s}", .{ link_path, l.target, @errorName(e) });
        common.printf(ctx, "  ✓ {s} → {s}\n", .{ l.name, l.target });
    }
    common.printf(ctx, "bpmp link: {d} link(s) under {s}/{s}\n", .{ p.links.len, cwd, manifest.DEPS_DIR });
    return 0;
}

/// The nearest directory from `start` (absolute) up that holds `repository/`.
pub fn findCheckout(io: std.Io, start: []const u8) ?[]const u8 {
    var dir = start;
    while (true) {
        if (manifest.isCheckoutRoot(io, dir)) return dir;
        const parent = std.fs.path.dirname(dir) orelse return null;
        if (std.mem.eql(u8, parent, dir)) return null;
        dir = parent;
    }
}

pub const Link = struct {
    name: []const u8,
    /// Absolute: `<checkout>/repository/<name>` (or `…/<repository>/<subdir>`).
    target: []const u8,
};

pub const Plan = struct {
    /// Every link, in the order its name is first met. Written only when
    /// `missing` is empty.
    links: []const Link,
    /// One located refusal per dependency whose local repository holds no
    /// `botopink.json`, at the entry that names it.
    missing: []const manifest.Located,
};

pub const PlanError = error{ NoManifest, Invalid } || std.mem.Allocator.Error;

/// Every link `bpmp link` writes for the project at `project_dir` against
/// `checkout` (both absolute). Writes nothing. A located refusal (a manifest
/// that does not parse, a `path` the compiler refuses, one name at two
/// directories) is `error.Invalid` with `out_err` set.
pub fn plan(arena: std.mem.Allocator, io: std.Io, project_dir: []const u8, checkout: []const u8, out_err: *?manifest.Located) PlanError!Plan {
    var missing: std.ArrayListUnmanaged(manifest.Located) = .empty;
    const project = manifest.read(arena, io, project_dir, out_err) catch |e| switch (e) {
        error.NotFound => return error.NoManifest,
        error.Invalid => return error.Invalid,
        error.OutOfMemory => return error.OutOfMemory,
    };

    const Pkg = struct { m: manifest.Manifest, dir: []const u8 };
    const Named = struct { link: Link, by: manifest.Manifest };
    var work: std.ArrayListUnmanaged(Pkg) = .empty;
    var seen: std.StringArrayHashMapUnmanaged(void) = .empty;
    var links: std.StringArrayHashMapUnmanaged(Named) = .empty;

    const enqueue = struct {
        fn f(a: std.mem.Allocator, w: *std.ArrayListUnmanaged(Pkg), s: *std.StringArrayHashMapUnmanaged(void), m: manifest.Manifest, dir: []const u8) !void {
            const key = try std.fs.path.resolve(a, &.{dir});
            if ((try s.getOrPut(a, key)).found_existing) return;
            try w.append(a, .{ .m = m, .dir = key });
        }
    }.f;

    if (project.isWorkspace()) {
        const ws = manifest.expand(arena, io, project, out_err) catch |e| switch (e) {
            error.Invalid => return error.Invalid,
            error.OutOfMemory => return error.OutOfMemory,
        };
        for (ws.members) |mem| try enqueue(arena, &work, &seen, mem.manifest, mem.dir);
    } else try enqueue(arena, &work, &seen, project, project_dir);

    var i: usize = 0;
    while (i < work.items.len) : (i += 1) {
        const pkg = work.items[i];
        for (pkg.m.dependencies) |dep| {
            const url = dep.spec.git orelse {
                // `path` / `workspace`: the package it names is followed for its
                // own git dependencies; the compiler resolves it in place.
                const r = (try manifest.resolveDependency(arena, io, pkg.m, pkg.dir, dep, &.{}, out_err)) orelse continue;
                try enqueue(arena, &work, &seen, r.manifest, r.dir);
                continue;
            };
            if (std.mem.eql(u8, dep.name, "std")) continue; // the bundled package — the compiler refuses it
            const target = if (dep.spec.subdir) |sub|
                try std.fs.path.join(arena, &.{ checkout, "repository", std.fs.path.basename(manifest.repositoryUrl(url)), sub })
            else
                try std.fs.path.join(arena, &.{ checkout, "repository", dep.name });

            if (links.get(dep.name)) |known| {
                if (std.mem.eql(u8, known.link.target, target)) continue;
                out_err.* = pkg.m.locateEntryAt("dependencies", dep.name, try std.fmt.allocPrint(
                    arena,
                    "\"{s}\" links to {s} here, but to {s} for {s} — one name is one link",
                    .{ dep.name, target, known.link.target, known.by.path },
                ));
                return error.Invalid;
            }

            var terr: ?manifest.Located = null;
            const tm = manifest.read(arena, io, target, &terr) catch |e| switch (e) {
                error.NotFound => {
                    try missing.append(arena, pkg.m.locateEntryAt("dependencies", dep.name, try std.fmt.allocPrint(
                        arena,
                        "\"{s}\" has no local repository: {s} holds no botopink.json — check it out there, or name another checkout",
                        .{ dep.name, target },
                    )));
                    // Recorded so a second mention is not reported twice.
                    try links.put(arena, dep.name, .{ .link = .{ .name = dep.name, .target = target }, .by = pkg.m });
                    continue;
                },
                error.Invalid => {
                    out_err.* = terr;
                    return error.Invalid;
                },
                error.OutOfMemory => return error.OutOfMemory,
            };
            try links.put(arena, dep.name, .{ .link = .{ .name = dep.name, .target = target }, .by = pkg.m });

            // Follow what the compiler will load under this name: the package,
            // or the workspace member so named (a core member named like its
            // repository).
            if (tm.isWorkspace()) {
                var werr: ?manifest.Located = null;
                const ws = manifest.expand(arena, io, tm, &werr) catch |e| switch (e) {
                    error.Invalid => {
                        out_err.* = werr;
                        return error.Invalid;
                    },
                    error.OutOfMemory => return error.OutOfMemory,
                };
                if (ws.member(dep.name)) |mem| try enqueue(arena, &work, &seen, mem.manifest, mem.dir);
            } else try enqueue(arena, &work, &seen, tm, target);
        }
    }

    var out = try arena.alloc(Link, links.count());
    for (links.values(), 0..) |n, k| out[k] = n.link;
    return .{ .links = out, .missing = missing.items };
}

// ── tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

fn writeP(path: []const u8, data: []const u8) !void {
    if (std.fs.path.dirname(path)) |d| try std.Io.Dir.cwd().createDirPath(testing.io, d);
    try std.Io.Dir.cwd().writeFile(testing.io, .{ .sub_path = path, .data = data });
}

fn absScratch(a: std.mem.Allocator, comptime rel: []const u8) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    const cwd = buf[0..try std.process.currentPath(testing.io, &buf)];
    return std.fs.path.resolve(a, &.{ cwd, test_scratch.path(testing.io, rel) });
}

/// `<root>/checkout/repository/{alpha, beta, kit}` — `alpha` depends on `beta`
/// by git; `kit` is a workspace whose core member `kit` depends on `gamma` by
/// git, absent from the checkout — and `<root>/lib`, a workspace of two members
/// naming `alpha` and `kit` by git.
fn writeLinkTree(comptime root: []const u8) !void {
    const git = "\"git\": \"https://example.invalid/";
    const files = [_][2][]const u8{
        .{ "checkout/repository/alpha/botopink.json", "{ \"name\": \"alpha\", \"dependencies\": { \"beta\": { " ++ git ++ "beta.git\" } } }" },
        .{ "checkout/repository/beta/botopink.json", "{ \"name\": \"beta\" }" },
        .{ "checkout/repository/kit/botopink.json", "{ \"name\": \"kit\", \"workspaces\": [\"modules/*\"] }" },
        .{ "checkout/repository/kit/modules/kit/botopink.json", "{ \"name\": \"kit\" }" },
        .{ "lib/botopink.json", "{ \"name\": \"lib\", \"workspaces\": [\"modules/*\"] }" },
        .{ "lib/modules/one/botopink.json", "{ \"name\": \"one\", \"dependencies\": { \"alpha\": { " ++ git ++ "alpha\" } } }" },
        .{ "lib/modules/two/botopink.json", "{ \"name\": \"two\", \"dependencies\": { \"one\": { \"workspace\": true }, \"kit\": { " ++ git ++ "kit.git\" } } }" },
    };
    inline for (files) |f| try writeP(test_scratch.path(testing.io, root ++ "/" ++ f[0]), f[1]);
}

test "link: a workspace's members' git dependencies, and theirs, link flat into the checkout's repository/" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    test_scratch.remove(testing.io, "bpmp-link-ok");
    defer test_scratch.remove(testing.io, "bpmp-link-ok");
    try writeLinkTree("bpmp-link-ok");

    const lib = try absScratch(a, "bpmp-link-ok/lib");
    const checkout = try absScratch(a, "bpmp-link-ok/checkout");
    try testing.expectEqualStrings(checkout, findCheckout(testing.io, try absScratch(a, "bpmp-link-ok/checkout/repository/alpha")).?);

    var err: ?manifest.Located = null;
    const p = try plan(a, testing.io, lib, checkout, &err);
    try testing.expectEqual(@as(usize, 0), p.missing.len);
    try testing.expectEqual(@as(usize, 3), p.links.len);
    try testing.expectEqualStrings("alpha", p.links[0].name);
    try testing.expectEqualStrings(try std.fs.path.join(a, &.{ checkout, "repository/alpha" }), p.links[0].target);
    try testing.expectEqualStrings("kit", p.links[1].name);
    try testing.expectEqualStrings("beta", p.links[2].name); // alpha's own, linked flat

    // Written, and an existing link replaced.
    for (p.links) |l| try install.ensureSymlink(testing.io, l.target, try std.fs.path.join(a, &.{ lib, manifest.DEPS_DIR, l.name }));
    for (p.links) |l| try install.ensureSymlink(testing.io, l.target, try std.fs.path.join(a, &.{ lib, manifest.DEPS_DIR, l.name }));
    const beta = try manifest.read(a, testing.io, try std.fs.path.join(a, &.{ lib, manifest.DEPS_DIR, "beta" }), &err);
    try testing.expectEqualStrings("beta", beta.name);
}

test "link: a dependency with no local repository is named, located — the command links nothing" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    test_scratch.remove(testing.io, "bpmp-link-missing");
    defer test_scratch.remove(testing.io, "bpmp-link-missing");
    try writeLinkTree("bpmp-link-missing");
    // kit's core member now names `gamma`, which the checkout does not hold.
    try writeP(test_scratch.path(testing.io, "bpmp-link-missing/checkout/repository/kit/modules/kit/botopink.json"),
        \\{ "name": "kit", "dependencies": { "gamma": { "git": "https://example.invalid/gamma.git" } } }
    );

    const lib = try absScratch(a, "bpmp-link-missing/lib");
    const checkout = try absScratch(a, "bpmp-link-missing/checkout");
    var err: ?manifest.Located = null;
    const p = try plan(a, testing.io, lib, checkout, &err);
    try testing.expectEqual(@as(usize, 1), p.missing.len);
    const m = p.missing[0];
    try testing.expect(std.mem.startsWith(u8, m.message, "\"gamma\" has no local repository: "));
    try testing.expect(std.mem.indexOf(u8, m.message, "/repository/gamma holds no botopink.json") != null);
    try testing.expect(std.mem.endsWith(u8, m.file, "repository/kit/modules/kit/botopink.json"));
}

test "link: a subdir dependency links into its repository's subdir; one name at two directories is refused" {
    var arena_inst = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena_inst.deinit();
    const a = arena_inst.allocator();
    test_scratch.remove(testing.io, "bpmp-link-subdir");
    defer test_scratch.remove(testing.io, "bpmp-link-subdir");
    try writeP(test_scratch.path(testing.io, "bpmp-link-subdir/checkout/repository/mono/modules/web/botopink.json"), "{ \"name\": \"web\" }");
    try writeP(test_scratch.path(testing.io, "bpmp-link-subdir/app/botopink.json"),
        \\{ "name": "app", "dependencies": { "web": { "git": "https://example.invalid/mono.git", "subdir": "modules/web" } } }
    );
    const checkout = try absScratch(a, "bpmp-link-subdir/checkout");
    var err: ?manifest.Located = null;
    const p = try plan(a, testing.io, try absScratch(a, "bpmp-link-subdir/app"), checkout, &err);
    try testing.expectEqual(@as(usize, 1), p.links.len);
    try testing.expectEqualStrings(try std.fs.path.join(a, &.{ checkout, "repository/mono/modules/web" }), p.links[0].target);

    // `web` by subdir from the project, `web` by name from the package it links.
    try writeP(test_scratch.path(testing.io, "bpmp-link-subdir/checkout/repository/mono/modules/web/botopink.json"),
        \\{ "name": "web", "dependencies": { "web2": { "git": "https://example.invalid/web2.git" } } }
    );
    try writeP(test_scratch.path(testing.io, "bpmp-link-subdir/checkout/repository/web2/botopink.json"),
        \\{ "name": "web2", "dependencies": { "web": { "git": "https://example.invalid/web.git" } } }
    );
    try writeP(test_scratch.path(testing.io, "bpmp-link-subdir/checkout/repository/web/botopink.json"), "{ \"name\": \"web\" }");
    try testing.expectError(error.Invalid, plan(a, testing.io, try absScratch(a, "bpmp-link-subdir/app"), checkout, &err));
    try testing.expect(std.mem.indexOf(u8, err.?.message, "one name is one link") != null);
}
