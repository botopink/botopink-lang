//! Decision 216 (3) — an associated type is named through its owner.
//!
//! `decl.addType("Columns", "(id: string)")` on `type City` declares the
//! top-level type `City__Columns` (`env.assocTypeName`). The source names it
//! `City.Columns`, and this
//! pass rewrites every such use on the parsed program into the one name the
//! checker and the four backends already know, before either sees the module:
//!
//! - in a type position, `City.Columns` becomes `City__Columns`;
//! - a construction `City.Columns(id: "x")` (a call on the owner's name)
//!   becomes the constructor call `City__Columns(id: "x")`;
//! - a value path `City.Size.Large` becomes `City__Size.Large`.
//!
//! An owner is a type of this module whose decorators declared associated
//! types, or an imported one (the module that declares it answers, through
//! the import's own source): importing `City` brings `City.Columns`, under an
//! alias too (`Town.Columns` names `City__Columns` — a type's identity is
//! its declared name, decision 110). For an imported owner, the import item of
//! each associated type a module uses is added beside the owner's item, so the
//! backends import it like any type. The pass runs in the compile pipeline only
//! (`comptime.zig` `analyzeSource`, `analyzeMerged`); the formatter prints the
//! source as written.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");

const Error = error{OutOfMemory};

/// A name the module binds to an owner of associated types.
pub const Owner = struct {
    /// The owner's declared name (an alias resolves to it).
    name: []const u8,
    /// Its associated types' own names.
    assoc: []const []const u8,
    /// For an imported owner: the import declaration (its index in the
    /// program) and the item that binds it.
    import: ?struct { decl: usize, item: ast.ImportPath } = null,
};

const Ctx = struct {
    arena: std.mem.Allocator,
    owners: *const std.StringHashMapUnmanaged(Owner),
    /// Items to add, per import declaration index, keyed by the mangled name.
    added: std.AutoArrayHashMapUnmanaged(usize, std.StringArrayHashMapUnmanaged(ast.ImportPath)) = .empty,

    /// The mangled name of `local.member` when `local` binds an owner with that
    /// associated type; records the import the use needs.
    fn resolve(self: *Ctx, local: []const u8, member: []const u8) Error!?[]const u8 {
        const owner = self.owners.get(local) orelse return null;
        for (owner.assoc) |a| {
            if (!std.mem.eql(u8, a, member)) continue;
            const mangled = try envMod.assocTypeName(self.arena, owner.name, member);
            if (owner.import) |imp| {
                const slot = try self.added.getOrPut(self.arena, imp.decl);
                if (!slot.found_existing) slot.value_ptr.* = .empty;
                if (!slot.value_ptr.contains(mangled)) {
                    const segs = try self.arena.dupe([]const u8, imp.item.segments);
                    segs[segs.len - 1] = mangled;
                    try slot.value_ptr.put(self.arena, mangled, .{ .segments = segs, .loc = imp.item.loc });
                }
            }
            return mangled;
        }
        return null;
    }

    fn rewriteType(self: *Ctx, t: *ast.TypeRef) Error!void {
        // `Owner.Name`, and the generic `Owner.Name<T>` (decision 330 (7)).
        const name = switch (t.*) {
            .named => |n| n,
            .generic => |g| if (g.is_builtin) return else g.name,
            else => return,
        };
        const dot = std.mem.indexOfScalar(u8, name, '.') orelse return;
        if (std.mem.indexOfScalarPos(u8, name, dot + 1, '.') != null) return;
        if (try self.resolve(name[0..dot], name[dot + 1 ..])) |mangled| switch (t.*) {
            .named => t.* = .{ .named = mangled },
            .generic => |*g| g.name = mangled,
            else => unreachable,
        };
    }

    fn rewriteExpr(self: *Ctx, e: *ast.Expr) Error!void {
        switch (e.*) {
            .call => |*c| switch (c.kind) {
                .call => |*call| {
                    const recv = call.receiver orelse return;
                    if (recv.* != .identifier or recv.identifier.kind != .ident) return;
                    if (try self.resolve(recv.identifier.kind.ident, call.callee)) |mangled| {
                        call.receiver = null;
                        call.callee = mangled;
                    }
                },
                else => {},
            },
            .identifier => |id| switch (id.kind) {
                .identAccess => |a| {
                    if (a.optional) return;
                    if (a.receiver.* != .identifier or a.receiver.identifier.kind != .ident) return;
                    if (try self.resolve(a.receiver.identifier.kind.ident, a.member)) |mangled| {
                        e.* = .{ .identifier = .{ .loc = id.loc, .kind = .{ .ident = mangled } } };
                    }
                },
                else => {},
            },
            else => {},
        }
    }

    fn walk(self: *Ctx, comptime T: type, ptr: *T) Error!void {
        if (T == ast.Expr) try self.rewriteExpr(ptr);
        if (T == ast.TypeRef) try self.rewriteType(ptr);
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldNode(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldNode(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldNode(p.child)) try self.walk(p.child, @constCast(ptr.*)),
                .slice => if (comptime mayHoldNode(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, @constCast(e));
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldNode(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

fn mayHoldNode(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldNode(p.child) else true,
        else => true,
    };
}

/// Rewrite `program` in place (the arena-owned parse of one module) and answer
/// it with the import items its uses of imported owners need. A program whose
/// module binds no owner is returned untouched.
pub fn expand(arena: std.mem.Allocator, program: ast.Program, owners: *const std.StringHashMapUnmanaged(Owner)) Error!ast.Program {
    if (owners.count() == 0) return program;
    var ctx = Ctx{ .arena = arena, .owners = owners };
    for (program.decls) |*d| try ctx.walk(ast.DeclKind, @constCast(d));
    if (ctx.added.count() == 0) return program;
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    var it = ctx.added.iterator();
    while (it.next()) |e| {
        const u = &decls[e.key_ptr.*].use;
        var items: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
        try items.appendSlice(arena, u.imports);
        try items.appendSlice(arena, e.value_ptr.values());
        u.imports = try items.toOwnedSlice(arena);
    }
    return .{ .decls = decls };
}

test "assoc types: a type position, a construction and a value path reach the mangled name" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    const src =
        \\import {City as Town} from "models";
        \\fn f(c: Town.Columns) -> i32 {
        \\    val d = Town.Columns(id: "x");
        \\    val k = Town.Size.Large;
        \\    return 1;
        \\}
    ;
    var lx = Lexer.init(src);
    var p = Parser.init(try lx.scanAll(arena));
    const parsed = try p.parse(arena);
    var owners: std.StringHashMapUnmanaged(Owner) = .empty;
    try owners.put(arena, "Town", .{
        .name = "City",
        .assoc = &.{ "Columns", "Size" },
        .import = .{ .decl = 0, .item = parsed.decls[0].use.imports[0] },
    });
    const program = try expand(arena, parsed, &owners);
    const f = program.decls[1].@"fn";
    try std.testing.expectEqualStrings("City__Columns", f.params[0].typeRef.named);
    try std.testing.expectEqualStrings("City__Columns", f.body[0].expr.binding.kind.localBind.value.call.kind.call.callee);
    try std.testing.expect(f.body[0].expr.binding.kind.localBind.value.call.kind.call.receiver == null);
    try std.testing.expectEqualStrings("City__Size", f.body[1].expr.binding.kind.localBind.value.identifier.kind.identAccess.receiver.identifier.kind.ident);
    const items = program.decls[0].use.imports;
    try std.testing.expectEqual(@as(usize, 3), items.len);
    try std.testing.expectEqualStrings("City__Columns", items[1].name());
    try std.testing.expectEqualStrings("City__Size", items[2].name());
}
