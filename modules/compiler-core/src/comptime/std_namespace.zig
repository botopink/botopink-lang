//! Decisions 110 and 111 on the use side — a std namespace reached through
//! more than one dot.
//!
//! `import {io} from "std"` names a FOLDER of std (`io/` holds `fs`, `http`,
//! …; its `mod.bp` is no module of the registry), and decision 110 makes such
//! a leaf a namespace of its submodules: `io.fs.readText(p)`. Decision 111's
//! constructors are type-scoped (`Dict.empty()`), and reaching one through
//! the module namespace — `import {collections} from "std";
//! collections.Dict.empty()` — is the same use-side path.
//!
//! Both are rewritten here, on the parsed program, into the one-dot forms the
//! checker and the four backends already lower, before either sees the
//! module:
//!
//! - `io.fs` (a folder namespace, then a module of it) becomes the namespace
//!   of `io/fs`, bound under a local no source can spell
//!   (`__bp_ns_io_fs`), and an import item `io.fs as __bp_ns_io_fs` is
//!   added. A folder's folder goes one level deeper the same way.
//! - `collections.Dict` (a module namespace, then a `pub type` of it) becomes
//!   `Dict`, and the item `collections.Dict` is added — exactly the leaf form
//!   `import {collections.Dict}` writes. A module declaring its own top-level
//!   `Dict` is left alone: the name would be bound twice, and the
//!   `unbound variable 'collections'` the checker then reports is the refusal.
//!
//! The folder item itself leaves the import list (it binds nothing a backend
//! can emit); a member that names no module of the folder is left as written
//! and reported by the checker as the unbound folder name, at its location.
//! Only the imports a module reaches through the folder are added, so
//! `import {io}` brings STD-001's check for the modules it uses, not for all
//! of `io/`. The pass runs in the compile pipeline only (`analyzeSource`,
//! `expandStdImports`); the formatter prints the source as written.
const std = @import("std");
const ast = @import("../ast.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const std_pkg_modules = @import("std_prelude").pkg_modules;

const Error = error{OutOfMemory};

/// The registry key of every embedded std module (`collections`, `io/fs`).
fn moduleKey(path: []const u8) []const u8 {
    return path["std/".len..];
}

fn isModule(key: []const u8) bool {
    for (std_pkg_modules) |spm| {
        if (std.mem.eql(u8, moduleKey(spm.path), key)) return true;
    }
    return false;
}

/// A folder of std: no module of that key, and at least one module under it.
fn isFolder(key: []const u8) bool {
    if (isModule(key)) return false;
    for (std_pkg_modules) |spm| {
        const k = moduleKey(spm.path);
        if (k.len > key.len and std.mem.startsWith(u8, k, key) and k[key.len] == '/') return true;
    }
    return false;
}

fn moduleSource(key: []const u8) ?[]const u8 {
    for (std_pkg_modules) |spm| {
        if (std.mem.eql(u8, moduleKey(spm.path), key)) return spm.source;
    }
    return null;
}

const Namespace = union(enum) {
    /// A folder of std, by its key (`io`).
    folder: []const u8,
    /// A module of std, by its key (`collections`).
    module: []const u8,
};

const Ctx = struct {
    arena: std.mem.Allocator,
    /// Import local → what it names.
    names: std.StringHashMapUnmanaged(Namespace) = .empty,
    /// Top-level declaration names of the module being rewritten.
    own: std.StringHashMapUnmanaged(void) = .empty,
    /// Items to add, keyed by the local each binds (one per module / type).
    added: std.StringArrayHashMapUnmanaged(ast.ImportPath) = .empty,
    /// `pub type` names per std module key, parsed on first use.
    pubTypes: std.StringHashMapUnmanaged(std.StringHashMapUnmanaged(void)) = .empty,
    /// Where the folder / module item was written, for the added items.
    locs: std.StringHashMapUnmanaged(ast.Loc) = .empty,

    fn declaresPubType(self: *Ctx, key: []const u8, name: []const u8) Error!bool {
        if (self.pubTypes.get(key)) |set| return set.contains(name);
        var set: std.StringHashMapUnmanaged(void) = .empty;
        if (moduleSource(key)) |src| parse: {
            var lx = Lexer.init(src);
            const tokens = lx.scanAll(self.arena) catch break :parse;
            var p = Parser.init(tokens);
            const program = p.parse(self.arena) catch break :parse;
            for (program.decls) |d| switch (d) {
                .type_ => |t| if (t.isPub) try set.put(self.arena, t.name, {}),
                .typeAlias => |a| if (a.isPub) try set.put(self.arena, a.name, {}),
                else => {},
            };
        }
        try self.pubTypes.put(self.arena, key, set);
        return set.contains(name);
    }

    /// The folder key an expression names — a folder namespace local, or a
    /// member of one that is itself a folder — or null.
    fn folderOf(self: *Ctx, e: *const ast.Expr) Error!?[]const u8 {
        if (e.* != .identifier) return null;
        switch (e.identifier.kind) {
            .ident => |n| return switch (self.names.get(n) orelse return null) {
                .folder => |k| k,
                .module => null,
            },
            .identAccess => |a| {
                if (a.optional) return null;
                const parent = (try self.folderOf(a.receiver)) orelse return null;
                const key = try std.fmt.allocPrint(self.arena, "{s}/{s}", .{ parent, a.member });
                return if (isFolder(key)) key else null;
            },
            .dotIdent => return null,
        }
    }

    /// The first loc recorded for the namespace an expression is rooted at.
    fn rootLoc(self: *Ctx, e: *const ast.Expr) ast.Loc {
        var cur = e;
        while (cur.* == .identifier) switch (cur.identifier.kind) {
            .ident => |n| return self.locs.get(n) orelse cur.identifier.loc,
            .identAccess => |a| cur = a.receiver,
            .dotIdent => break,
        };
        return e.getLoc();
    }

    fn segmentsOf(self: *Ctx, key: []const u8, leaf: ?[]const u8) Error![]const []const u8 {
        var out: std.ArrayListUnmanaged([]const u8) = .empty;
        var it = std.mem.splitScalar(u8, key, '/');
        while (it.next()) |s| try out.append(self.arena, s);
        if (leaf) |l| try out.append(self.arena, l);
        return out.toOwnedSlice(self.arena);
    }

    /// Rewrite `e` in place when it is `<folder>.<module>` or
    /// `<module ns>.<pub type>`. Answers true when it did.
    fn rewrite(self: *Ctx, e: *ast.Expr) Error!bool {
        if (e.* != .identifier) return false;
        const a = switch (e.identifier.kind) {
            .identAccess => |a| a,
            else => return false,
        };
        if (a.optional) return false;
        const loc = e.identifier.loc;
        if (try self.folderOf(a.receiver)) |folder| {
            const key = try std.fmt.allocPrint(self.arena, "{s}/{s}", .{ folder, a.member });
            if (!isModule(key)) return false;
            var local: std.ArrayListUnmanaged(u8) = .empty;
            try local.appendSlice(self.arena, "__bp_ns_");
            for (key) |c| try local.append(self.arena, if (c == '/') '_' else c);
            const name = local.items;
            if (!self.added.contains(name)) try self.added.put(self.arena, name, .{
                .segments = try self.segmentsOf(key, null),
                .alias = name,
                .loc = self.rootLoc(a.receiver),
            });
            e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
            return true;
        }
        if (a.receiver.* != .identifier) return false;
        const root = switch (a.receiver.identifier.kind) {
            .ident => |n| n,
            else => return false,
        };
        const mod_key = switch (self.names.get(root) orelse return false) {
            .module => |k| k,
            .folder => return false,
        };
        if (a.member.len == 0 or !std.ascii.isUpper(a.member[0])) return false;
        if (self.own.contains(a.member)) return false;
        if (!try self.declaresPubType(mod_key, a.member)) return false;
        if (!self.added.contains(a.member)) try self.added.put(self.arena, a.member, .{
            .segments = try self.segmentsOf(mod_key, a.member),
            .loc = self.locs.get(root) orelse loc,
        });
        e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = a.member } } };
        return true;
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) Error!void {
        if (T == ast.Expr) {
            if (try self.rewrite(ptr)) return;
        }
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, @constCast(ptr.*)),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, @constCast(e));
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}

fn declName(d: ast.DeclKind) ?[]const u8 {
    return switch (d) {
        .type_ => |t| t.name,
        .typeAlias => |a| a.name,
        .@"fn" => |f| f.name,
        .val => |v| v.name,
        else => null,
    };
}

/// Rewrite `program` in place (it is the arena-owned parse of one module).
/// A program with no `from "std"` folder or module namespace is returned
/// untouched.
pub fn expand(arena: std.mem.Allocator, program: ast.Program) Error!ast.Program {
    var ctx = Ctx{ .arena = arena };
    var any_folder = false;
    for (program.decls) |d| switch (d) {
        .use => |u| {
            const from_std = switch (u.source) {
                .module => |m| std.mem.eql(u8, m, "std"),
                .root => false,
            };
            if (!from_std) continue;
            for (u.imports) |imp| {
                const whole = try imp.fullPath(arena);
                if (isFolder(whole)) {
                    try ctx.names.put(arena, imp.name(), .{ .folder = whole });
                    try ctx.locs.put(arena, imp.name(), imp.loc);
                    any_folder = true;
                } else if (isModule(whole)) {
                    try ctx.names.put(arena, imp.name(), .{ .module = whole });
                    try ctx.locs.put(arena, imp.name(), imp.loc);
                }
            }
        },
        else => if (declName(d)) |n| try ctx.own.put(arena, n, {}),
    };
    if (ctx.names.count() == 0) return program;

    for (program.decls) |*d| try ctx.walk(ast.DeclKind, @constCast(d));
    if (!any_folder and ctx.added.count() == 0) return program;

    // The first `from "std"` import loses its folder items and carries the
    // added ones; every other import only loses its folder items.
    var carried = false;
    for (program.decls) |*d| switch (d.*) {
        .use => |u| {
            const from_std = switch (u.source) {
                .module => |m| std.mem.eql(u8, m, "std"),
                .root => false,
            };
            if (!from_std) continue;
            var kept: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
            for (u.imports) |imp| {
                if (isFolder(try imp.fullPath(arena))) continue;
                try kept.append(arena, imp);
            }
            if (!carried) {
                carried = true;
                var it = ctx.added.iterator();
                while (it.next()) |e| {
                    if (alreadyImported(kept.items, e.value_ptr.*)) continue;
                    try kept.append(arena, e.value_ptr.*);
                }
            }
            @constCast(d).use.imports = try kept.toOwnedSlice(arena);
        },
        else => {},
    };
    return program;
}

fn alreadyImported(items: []const ast.ImportPath, want: ast.ImportPath) bool {
    for (items) |imp| {
        if (!std.mem.eql(u8, imp.name(), want.name())) continue;
        if (imp.segments.len != want.segments.len) continue;
        var same = true;
        for (imp.segments, want.segments) |x, y| same = same and std.mem.eql(u8, x, y);
        if (same) return true;
    }
    return false;
}

test "std namespace: a folder leaf and a module's type reach the one-dot forms" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\import {io, collections} from "std";
        \\fn main() {
        \\    val b = io.fs.exists("/");
        \\    val d = collections.Dict.empty();
        \\    val o = collections.lt();
        \\}
    ;
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const program = try expand(arena, try p.parse(arena));
    const imports = program.decls[0].use.imports;
    try std.testing.expectEqual(@as(usize, 3), imports.len);
    try std.testing.expectEqualStrings("collections", imports[0].name());
    try std.testing.expectEqualStrings("__bp_ns_io_fs", imports[1].name());
    try std.testing.expectEqualStrings("io/fs", try imports[1].fullPath(arena));
    try std.testing.expectEqualStrings("Dict", imports[2].name());
    try std.testing.expectEqualStrings("collections/Dict", try imports[2].fullPath(arena));
}
