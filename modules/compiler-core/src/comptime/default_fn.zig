//! Decision 289 — a module's default function, and the import that binds it.
//!
//! `pub default fn (…) -> R { … }` binds no name in its module: the parser
//! leaves its name empty (`FnDecl.anonymousDefault`) and `nameAnonymous` gives
//! it `ast.anonymous_default_name` — `default`, a keyword, so no declaration,
//! import or call of the module can spell it. `pub default <name>;` (the
//! parser's `markDefaultNames`) and `pub default fn Name(…)` keep their name.
//!
//! The importer names the default: `import {m.double};`, whose whole path is a
//! module holding a default function, binds that function under the path's
//! last segment (`double`), or under the alias (`import {m.post_card as
//! Card};`). `expandImports` rewrites such an item into the ordinary
//! item-with-alias form every backend already lowers —
//! `import {m.double.<default's name> as double};` — so neither the checker's
//! import binding nor any emitter learns a new shape. A symbol of the prefix
//! module named like the item wins, as it does over the namespace form.
//!
//! `comptime.zig` registers each module's default (`key`) in its
//! `templateRegistry` when the module's exports are recorded.

const std = @import("std");
const ast = @import("../ast.zig");

/// The `templateRegistry` key of module `path`'s default function. No import
/// item can spell it: it holds two NULs.
pub fn key(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00\x00default", .{path});
}

/// `program` with its anonymous default function named
/// `ast.anonymous_default_name`; `program` itself when it has none.
pub fn nameAnonymous(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    const at = for (program.decls, 0..) |d, i| switch (d) {
        .@"fn" => |f| if (f.anonymousDefault) break i,
        else => {},
    } else return program;
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    decls[at].@"fn".name = ast.anonymous_default_name;
    var out = program;
    out.decls = decls;
    return out;
}

/// `program` with every import item that names a module holding a default
/// function rewritten to that function, aliased to the name the importer
/// wrote. `defaults` answers a module path's default (`key`); `exports` a
/// module path's exported names (a symbol named like the item wins).
pub fn expandImports(
    arena: std.mem.Allocator,
    program: ast.Program,
    defaults: *const std.StringHashMap(ast.FnDecl),
    exports: anytype,
) !ast.Program {
    var decls: ?[]ast.DeclKind = null;
    for (program.decls, 0..) |d, di| {
        if (d != .use) continue;
        const u = d.use;
        if (u.package != null or u.activationOnly) continue;
        switch (u.source) {
            .module => |m| if (std.mem.eql(u8, m, "std")) continue,
            .root, .key => {},
        }
        var items: ?[]ast.ImportPath = null;
        for (u.imports, 0..) |imp, ii| {
            if (imp.activate) continue;
            const whole = switch (try u.leafSource(imp, arena, true)) {
                .module, .key => |p| p,
                .root => continue,
            };
            const def = defaults.get(try key(arena, whole)) orelse continue;
            // A symbol of the prefix module named like the item wins.
            if (imp.isQualified()) {
                switch (try u.leafSource(imp, arena, false)) {
                    .module, .key => |prefix| if (exports.get(prefix)) |ex| if (ex.contains(imp.leaf())) continue,
                    .root => {},
                }
            }
            if (items == null) items = try arena.dupe(ast.ImportPath, u.imports);
            const segs = try arena.alloc([]const u8, imp.segments.len + 1);
            @memcpy(segs[0..imp.segments.len], imp.segments);
            segs[imp.segments.len] = def.name;
            items.?[ii].segments = segs;
            const local = imp.name();
            items.?[ii].alias = if (std.mem.eql(u8, local, def.name)) null else local;
        }
        if (items) |its| {
            if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
            decls.?[di].use.imports = its;
        }
    }
    var out = program;
    if (decls) |ds| out.decls = ds;
    return out;
}

test "an anonymous default is named `default`" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const decls = try arena.alloc(ast.DeclKind, 1);
    decls[0] = .{ .@"fn" = .{ .name = "", .isPub = true, .isDefault = true, .anonymousDefault = true, .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{} } };
    const out = try nameAnonymous(arena, .{ .decls = decls });
    try std.testing.expectEqualStrings(ast.anonymous_default_name, out.decls[0].@"fn".name);
    try std.testing.expectEqualStrings("", decls[0].@"fn".name);
}
