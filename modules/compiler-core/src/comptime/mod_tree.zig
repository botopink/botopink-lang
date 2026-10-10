//! Decision 337 — the module tree of one compile session, as the checker reads
//! it: every module of every package by its key (the package plus the path,
//! decisions 170 and 337), the `mod` children each declares and the names each
//! declares `pub`.
//!
//! Two questions are answered from it:
//!
//! - which modules an import with no `from` may name — its first segment must
//!   name a module of the importing package, or the item is the shorthand
//!   (`import {splitPath};`), refused `shorthand-import` with its fix written
//!   (`comptime.zig` `resolveImports`): the one module that declares the name
//!   `pub`, or the candidates;
//! - what a `mod m;` binds — the namespace of the child module `m`, and the
//!   walk `mod1.mod2.f()` through a folder module's `pub mod` children
//!   (`mod_namespace.zig`).
//!
//! The keys are the driver's: the CLI keys a module by its logical path (the
//! `mod` chain joined with `/`, a dependency's under its package name), and a
//! top-level `mod` of the package root names a top-level module (`mod config;`
//! in `main` is `config`, in `mod1` it is `mod1/config`). A session whose keys
//! are file paths (the language server's) is not a module tree: `known` is
//! false and neither question is asked.
const std = @import("std");
const ast = @import("../ast.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const Module = @import("../module.zig").Module;

pub const Child = struct {
    /// The name the `mod` declares (`mod2`).
    name: []const u8,
    /// The child module's key (`mod1/mod2`).
    key: []const u8,
    isPub: bool,
    /// Where the `mod` declaration's name is written.
    loc: ast.Loc,
};

pub const Entry = struct {
    /// The package the module belongs to (`""` for the root package).
    package: []const u8,
    children: []const Child = &.{},
    /// The names the module declares `pub` — a function, value, type, type
    /// alias or behavior (a `pub mod` is a child, not a name).
    pubNames: []const []const u8 = &.{},
    /// The `pub` types among them (a type, a type alias, a behavior).
    pubTypes: []const []const u8 = &.{},

    pub fn declaresType(self: Entry, name: []const u8) bool {
        for (self.pubTypes) |n| if (std.mem.eql(u8, n, name)) return true;
        return false;
    }

    pub fn declares(self: Entry, name: []const u8) bool {
        for (self.pubNames) |n| if (std.mem.eql(u8, n, name)) return true;
        return false;
    }
};

pub const Tree = struct {
    /// False when the session's keys are not module paths (file paths, the
    /// language server's): no import is then refused as the shorthand.
    known: bool = false,
    entries: std.StringHashMapUnmanaged(Entry) = .empty,
    /// Decision 337 (3) — `reexportKey(M, X)` → the module whose `pub` `X` a
    /// module `M` re-exports under the same name: `pub val splitPath =
    /// mod2.splitPath;`, `pub type Pair = mod2.Pair;` (a namespace of `M`, then
    /// the name). An import of `M.X` is an import of that declaration.
    reexports: std.StringHashMapUnmanaged(Reexport) = .empty,

    pub const Reexport = struct { owner: []const u8, isType: bool };

    /// The module that declares what `module`'s `name` re-exports, followed
    /// through a chain of re-exports; null when `name` is `module`'s own.
    pub fn reexportOf(self: *const Tree, arena: std.mem.Allocator, module: []const u8, name: []const u8) !?Reexport {
        var at: ?Reexport = null;
        var cur = module;
        var hops: usize = 0;
        while (hops < 16) : (hops += 1) {
            const r = self.reexports.get(try reexportKey(arena, cur, name)) orelse break;
            at = r;
            cur = r.owner;
        }
        return at;
    }

    /// Whether `key` is a module of the session, or a folder of modules (a
    /// dependency's `sql/rows` loaded without `sql`).
    pub fn isModule(self: *const Tree, key: []const u8) bool {
        if (self.entries.contains(key)) return true;
        var it = self.entries.keyIterator();
        while (it.next()) |k| {
            if (k.len > key.len and k.*[key.len] == '/' and std.mem.startsWith(u8, k.*, key)) return true;
        }
        return false;
    }

    /// The child `name` the module `parent` declares with `mod`, if any.
    pub fn childOf(self: *const Tree, parent: []const u8, name: []const u8) ?Child {
        const e = self.entries.get(parent) orelse return null;
        for (e.children) |c| if (std.mem.eql(u8, c.name, name)) return c;
        return null;
    }

    /// The modules of `package` other than `except` that declare `name`
    /// `pub`, sorted by key.
    pub fn declarers(self: *const Tree, arena: std.mem.Allocator, package: []const u8, except: []const u8, name: []const u8) ![]const []const u8 {
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = self.entries.iterator();
        while (it.next()) |e| {
            if (!std.mem.eql(u8, e.value_ptr.package, package)) continue;
            if (std.mem.eql(u8, e.key_ptr.*, except)) continue;
            for (e.value_ptr.pubNames) |n| if (std.mem.eql(u8, n, name)) {
                try out.append(arena, e.key_ptr.*);
                break;
            };
        }
        std.mem.sort([]const u8, out.items, {}, struct {
            fn lessThan(_: void, a: []const u8, b: []const u8) bool {
                return std.mem.order(u8, a, b) == .lt;
            }
        }.lessThan);
        return out.items;
    }
};

pub fn reexportKey(arena: std.mem.Allocator, module: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ module, name });
}

/// The segments of a dotted name an expression spells (`mod2.splitPath`), or
/// null when it is not one.
fn exprSegments(arena: std.mem.Allocator, e: *const ast.Expr, acc: *std.ArrayListUnmanaged([]const u8)) !bool {
    if (e.* != .identifier) return false;
    switch (e.identifier.kind) {
        .ident => |n| try acc.append(arena, n),
        .identAccess => |a| {
            if (a.optional or !try exprSegments(arena, a.receiver, acc)) return false;
            try acc.append(arena, a.member);
        },
        .dotIdent => return false,
    }
    return true;
}

/// `M`'s `pub` declaration `name` written as `<namespace>.<name>`: the module
/// the namespace path names, when that module declares `name` `pub`.
fn reexported(tree: *const Tree, arena: std.mem.Allocator, program: ast.Program, m: Module, name: []const u8, segs: []const []const u8, isType: bool) !?[]const u8 {
    if (segs.len < 2 or !std.mem.eql(u8, segs[segs.len - 1], name)) return null;
    var key: ?[]const u8 = if (tree.childOf(m.path, segs[0])) |c| c.key else null;
    if (key == null) for (program.decls) |d| switch (d) {
        .use => |u| if (u.source == .root and u.package == null) for (u.imports) |imp| {
            if (imp.activate or !std.mem.eql(u8, imp.name(), segs[0])) continue;
            const whole = try keyIn(arena, m.package, try imp.fullPath(arena));
            if (tree.entries.contains(whole)) key = whole;
        },
        else => {},
    };
    var at = key orelse return null;
    for (segs[1 .. segs.len - 1]) |s| at = (tree.childOf(at, s) orelse return null).key;
    const e = tree.entries.get(at) orelse return null;
    if (isType) {
        if (!e.declaresType(name)) return null;
    } else if (!e.declares(name) or e.declaresType(name)) return null;
    return at;
}

/// `key` with its package's prefix taken off (`a/theme` → `theme` in `a`).
pub fn localPath(package: []const u8, key: []const u8) []const u8 {
    if (package.len == 0) return key;
    if (key.len > package.len and key[package.len] == '/' and std.mem.startsWith(u8, key, package)) return key[package.len + 1 ..];
    return key;
}

/// The key of the module `local` names in `package` (`theme` in `a` → `a/theme`).
pub fn keyIn(arena: std.mem.Allocator, package: []const u8, local: []const u8) ![]const u8 {
    if (package.len == 0) return local;
    return std.fmt.allocPrint(arena, "{s}/{s}", .{ package, local });
}

fn isStd(key: []const u8) bool {
    return std.mem.startsWith(u8, key, "std/");
}

/// A key the CLI could have written: no file path, no extension.
fn isLogical(key: []const u8) bool {
    if (key.len == 0) return false;
    if (std.fs.path.isAbsolute(key)) return false;
    return !std.mem.endsWith(u8, key, ".bp");
}

/// Build the tree of `modules` (std's own are left out: std is reached only by
/// `from "std"`). A module that does not lex or parse has no children and no
/// names; its own diagnostic is reported where it is analysed.
pub fn build(arena: std.mem.Allocator, modules: []const Module) !Tree {
    var tree: Tree = .{ .known = true };
    for (modules) |m| {
        if (isStd(m.path)) continue;
        if (!isLogical(m.path)) {
            tree.known = false;
            return tree;
        }
        try tree.entries.put(arena, m.path, .{ .package = m.package });
    }
    if (tree.entries.count() == 0) tree.known = false;
    const programs = try arena.alloc(?ast.Program, modules.len);
    for (modules, 0..) |m, i| {
        programs[i] = null;
        if (isStd(m.path)) continue;
        var lx = Lexer.init(m.source);
        const tokens = lx.scanAll(arena) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(arena) catch continue;
        programs[i] = program;
        var children: std.ArrayListUnmanaged(Child) = .empty;
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var types: std.ArrayListUnmanaged([]const u8) = .empty;
        const local = localPath(m.package, m.path);
        for (program.decls) |d| switch (d) {
            .mod => |md| {
                // A child of a module nests under it; a child of the package
                // root (a top-level module itself) is a top-level module.
                const nested = try std.fmt.allocPrint(arena, "{s}/{s}", .{ m.path, md.name });
                const key = if (tree.entries.contains(nested))
                    nested
                else if (std.mem.indexOfScalar(u8, local, '/') == null and tree.entries.contains(try keyIn(arena, m.package, md.name)))
                    try keyIn(arena, m.package, md.name)
                else
                    continue;
                try children.append(arena, .{ .name = md.name, .key = key, .isPub = md.isPub, .loc = md.loc });
            },
            .@"fn" => |f| if (f.isPub) try names.append(arena, f.name),
            .val => |v| if (v.isPub) try names.append(arena, v.name),
            .type_ => |t| if (t.isPub) {
                try names.append(arena, t.name);
                try types.append(arena, t.name);
            },
            .typeAlias => |a| if (a.isPub) {
                try names.append(arena, a.name);
                try types.append(arena, a.name);
            },
            .behavior => |b| if (b.isPub) {
                try names.append(arena, b.name);
                try types.append(arena, b.name);
            },
            .delegate => |dg| if (dg.isPub) try names.append(arena, dg.name),
            else => {},
        };
        const e = tree.entries.getPtr(m.path).?;
        e.children = children.items;
        e.pubNames = names.items;
        e.pubTypes = types.items;
    }
    for (modules, programs) |m, program_| {
        const program = program_ orelse continue;
        for (program.decls) |d| switch (d) {
            .val => |v| if (v.isPub and !v.mutable) {
                var segs: std.ArrayListUnmanaged([]const u8) = .empty;
                if (!try exprSegments(arena, v.value, &segs)) continue;
                if (try reexported(&tree, arena, program, m, v.name, segs.items, false)) |owner|
                    try tree.reexports.put(arena, try reexportKey(arena, m.path, v.name), .{ .owner = owner, .isType = false });
            },
            .typeAlias => |a| if (a.isPub and a.genericParams.len == 0) switch (a.target) {
                .named => |n| {
                    var segs: std.ArrayListUnmanaged([]const u8) = .empty;
                    var it = std.mem.splitScalar(u8, n, '.');
                    while (it.next()) |s| try segs.append(arena, s);
                    if (try reexported(&tree, arena, program, m, a.name, segs.items, true)) |owner|
                        try tree.reexports.put(arena, try reexportKey(arena, m.path, a.name), .{ .owner = owner, .isType = true });
                },
                else => {},
            },
            else => {},
        };
    }
    return tree;
}

test "mod tree: a root's child is top-level, a folder's nests; pub names" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const mods = [_]Module{
        .{ .path = "main", .source = "pub mod config;\nmod mod1;\npub fn main() {}\n" },
        .{ .path = "config", .source = "pub fn splitPath(p: string) -> string { return p; }\nfn hidden() {}\n" },
        .{ .path = "mod1", .source = "pub mod mod2;\n" },
        .{ .path = "mod1/mod2", .source = "pub type Pair(a: i32)\n" },
    };
    const tree = try build(arena, &mods);
    try std.testing.expect(tree.known);
    try std.testing.expectEqualStrings("config", tree.childOf("main", "config").?.key);
    try std.testing.expect(!tree.childOf("main", "mod1").?.isPub);
    try std.testing.expectEqualStrings("mod1/mod2", tree.childOf("mod1", "mod2").?.key);
    const who = try tree.declarers(arena, "", "main", "splitPath");
    try std.testing.expectEqual(@as(usize, 1), who.len);
    try std.testing.expectEqualStrings("config", who[0]);
    try std.testing.expectEqual(@as(usize, 0), (try tree.declarers(arena, "", "main", "hidden")).len);
}

test "mod tree: file-path keys are no module tree" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const mods = [_]Module{.{ .path = "/home/x/src/main.bp", .source = "pub mod config;\n" }};
    const tree = try build(arena_state.allocator(), &mods);
    try std.testing.expect(!tree.known);
}
