//! Decision 310 — a type's identity by its module where two same-named types
//! meet in one module (`import {m1.T as A}; import {m2.T as B};`).
//!
//! Types are nominal by name in the checker (`T.Type.named`), and one module
//! names each type once. When a module imports two types declared with one
//! name from two modules, each aliased item's alias is that type's identity in
//! the module (`Env.renamedTypeImports`): the declaration is registered under
//! the alias (`renameDecl` — its own name in its signatures renamed with it),
//! and a value imported from another module has the types of its signature
//! renamed the same way (`renameType`). The transformed program keeps the
//! alias in the import item; each backend maps it back to the declared name in
//! the declaring module (`codegen/crossModule.zig` `typeAliasesOf`).
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("types.zig");

const Error = error{OutOfMemory};

/// A copy of `t` named `to`, printed as it was, with every type reference to
/// `from` in its signatures (fields, variant payloads, method parameters and
/// returns, behaviors it implements) renamed to `to`. Bodies, defaults and
/// annotations are shared with the original, never rewritten.
pub fn renameDecl(arena: std.mem.Allocator, t: ast.TypeDecl, from: []const u8, to: []const u8) Error!ast.TypeDecl {
    var out = try renamed(ast.TypeDecl, arena, t, from, to);
    out.name = to;
    out.displayName = t.printedName();
    return out;
}

fn renamed(comptime V: type, arena: std.mem.Allocator, v: V, from: []const u8, to: []const u8) Error!V {
    if (V == ast.TypeRef) return renameRef(arena, v, from, to);
    if (comptime !mayHoldTypeRef(V)) return v;
    switch (@typeInfo(V)) {
        .@"struct" => |s| {
            var out = v;
            inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime std.mem.eql(u8, f.name, "body") or std.mem.eql(u8, f.name, "annotations") or std.mem.eql(u8, f.name, "default") or std.mem.eql(u8, f.name, "assocTypes")) continue;
                @field(out, f.name) = try renamed(f.type, arena, @field(v, f.name), from, to);
            }
            if (V == ast.Param) if (std.mem.eql(u8, v.typeName, from)) {
                out.typeName = to;
            };
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(V, @tagName(tag), try renamed(@TypeOf(payload), arena, payload, from, to)),
            }
        },
        .optional => |o| return if (v) |x| try renamed(o.child, arena, x, from, to) else null,
        .pointer => |p| switch (p.size) {
            .slice => {
                const out = try arena.alloc(p.child, v.len);
                for (v, 0..) |x, i| out[i] = try renamed(p.child, arena, x, from, to);
                return out;
            },
            .one => {
                const out = try arena.create(p.child);
                out.* = try renamed(p.child, arena, v.*, from, to);
                return out;
            },
            else => return v,
        },
        .array => |a| {
            var out: V = undefined;
            for (v, 0..) |x, i| out[i] = try renamed(a.child, arena, x, from, to);
            return out;
        },
        else => return v,
    }
}

fn renameRef(arena: std.mem.Allocator, r: ast.TypeRef, from: []const u8, to: []const u8) Error!ast.TypeRef {
    return switch (r) {
        .named => |n| .{ .named = if (std.mem.eql(u8, n, from)) to else n },
        .array => |e| .{ .array = try boxed(arena, try renameRef(arena, e.*, from, to)) },
        .optional => |e| .{ .optional = try boxed(arena, try renameRef(arena, e.*, from, to)) },
        .tuple_ => |es| .{ .tuple_ = try renameRefs(arena, es, from, to) },
        .labeledTuple => |lt| .{ .labeledTuple = .{ .elems = try renameRefs(arena, lt.elems, from, to), .labels = lt.labels } },
        .function => |f| blk: {
            var g = f;
            g.params = try renameRefs(arena, f.params, from, to);
            g.returnType = try boxed(arena, try renameRef(arena, f.returnType.*, from, to));
            break :blk .{ .function = g };
        },
        .generic => |g| .{ .generic = .{
            .name = if (!g.is_builtin and std.mem.eql(u8, g.name, from)) to else g.name,
            .args = try renameRefs(arena, g.args, from, to),
            .is_builtin = g.is_builtin,
        } },
        .typeparam => |cs| .{ .typeparam = try renameRefs(arena, cs, from, to) },
    };
}

fn renameRefs(arena: std.mem.Allocator, rs: []const ast.TypeRef, from: []const u8, to: []const u8) Error![]ast.TypeRef {
    const out = try arena.alloc(ast.TypeRef, rs.len);
    for (rs, 0..) |r, i| out[i] = try renameRef(arena, r, from, to);
    return out;
}

fn boxed(arena: std.mem.Allocator, r: ast.TypeRef) Error!*ast.TypeRef {
    const p = try arena.create(ast.TypeRef);
    p.* = r;
    return p;
}

/// Whether a value of `V` can reach a `TypeRef` this rename rewrites: an
/// expression or a statement never does (its types are not the declaration's
/// signature).
fn mayHoldTypeRef(comptime V: type) bool {
    if (V == ast.Expr or V == ast.Stmt or V == ast.Annotation) return false;
    return switch (@typeInfo(V)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn" => false,
        .pointer => |p| if (p.child == u8) false else mayHoldTypeRef(p.child),
        .optional => |o| mayHoldTypeRef(o.child),
        else => true,
    };
}

/// `ty` with each named type `rename` answers a new name for renamed — a copy
/// along the paths that change; every other node, type variables included, is
/// shared with `ty`.
pub fn renameType(arena: std.mem.Allocator, ty: *T.Type, ctx: anytype, depth: usize) Error!*T.Type {
    if (depth > 32) return ty;
    const d = ty.deref();
    switch (d.*) {
        .named => |n| {
            const name = ctx.rename(n.name) orelse n.name;
            var changed = name.ptr != n.name.ptr or name.len != n.name.len;
            const args = try arena.alloc(*T.Type, n.args.len);
            for (n.args, 0..) |a, i| {
                args[i] = try renameType(arena, a, ctx, depth + 1);
                if (args[i] != a) changed = true;
            }
            if (!changed) return ty;
            const out = try arena.create(T.Type);
            out.* = .{ .named = .{ .name = name, .args = args, .labels = n.labels } };
            return out;
        },
        .func => |f| {
            var changed = false;
            const params = try arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| {
                params[i] = try renameType(arena, p, ctx, depth + 1);
                if (params[i] != p) changed = true;
            }
            const ret = try renameType(arena, f.ret, ctx, depth + 1);
            if (ret != f.ret) changed = true;
            if (!changed) return ty;
            const out = try arena.create(T.Type);
            out.* = .{ .func = .{ .params = params, .ret = ret } };
            return out;
        },
        .union_ => |us| {
            var changed = false;
            const members = try arena.alloc(*T.Type, us.len);
            for (us, 0..) |m, i| {
                members[i] = try renameType(arena, m, ctx, depth + 1);
                if (members[i] != m) changed = true;
            }
            if (!changed) return ty;
            const out = try arena.create(T.Type);
            out.* = .{ .union_ = members };
            return out;
        },
        .record => |fs| {
            var changed = false;
            const fields = try arena.alloc(T.Field, fs.len);
            for (fs, 0..) |f, i| {
                fields[i] = .{ .name = f.name, .type_ = try renameType(arena, f.type_, ctx, depth + 1) };
                if (fields[i].type_ != f.type_) changed = true;
            }
            if (!changed) return ty;
            const out = try arena.create(T.Type);
            out.* = .{ .record = fields };
            return out;
        },
        .typeVar => return ty,
    }
}

test "renameDecl: the declaration and its own name in its signatures" {
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\pub type Policy(ms: i32, next: ?Policy) {
        \\    fn again(self: Self, other: Policy) -> Policy[] { return [other]; }
        \\}
    ;
    var lx = lexer.Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = parser.Parser.init(tokens);
    const program = try p.parse(arena);
    const t = program.decls[0].type_;
    const r = try renameDecl(arena, t, "Policy", "APolicy");
    try std.testing.expectEqualStrings("APolicy", r.name);
    try std.testing.expectEqualStrings("Policy", r.printedName());
    try std.testing.expectEqualStrings("APolicy", r.shape.record[1].typeRef.optional.named);
    try std.testing.expectEqualStrings("APolicy", r.methods[0].params[1].typeRef.named);
    try std.testing.expectEqualStrings("APolicy", r.methods[0].returnType.?.array.named);
    // The original is untouched.
    try std.testing.expectEqualStrings("Policy", t.shape.record[1].typeRef.optional.named);
    try std.testing.expectEqualStrings("Policy", t.methods[0].params[1].typeRef.named);
}
