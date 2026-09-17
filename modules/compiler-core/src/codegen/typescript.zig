/// TypeScript `.d.ts` typedef backend.
///
/// Iterates over typed bindings and **builds** a declaration model
/// (`codegen/js/js_ast.zig`: `TsDecl` / `TsMember` / `TsType`); `ts_emitter.zig`
/// renders it. This file decides what the public contract of a module is —
/// which bindings surface, how `@Result` / `@Future` / `@Context` erase — and
/// writes no TypeScript text of its own.
const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const js = @import("./js/js_ast.zig");
const tsEmitter = @import("./js/ts_emitter.zig");

/// Emit a TypeScript declaration file for all bindings.
pub fn emitProgram(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var bld = Builder{ .b = .{ .arena = arena.allocator() } };

    const decls = try bld.b.arena.alloc(js.TsDecl, bindings.len);
    for (bindings, 0..) |binding, i| decls[i] = try bld.binding(binding);

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try tsEmitter.writeProgram(&aw.writer, decls);
    return aw.toOwnedSlice();
}

/// Builds the `.d.ts` model. Every node it produces lives in `b.arena`.
const Builder = struct {
    b: js.Builder,

    const Error = anyerror;

    // ── declarations ─────────────────────────────────────────────────────────

    fn binding(self: *Builder, bd: comptimeMod.TypedBinding) Error!js.TsDecl {
        return switch (bd.decl) {
            .val => |v| try self.val(v.name, v.isPub, bd.type_),
            .@"fn" => |f| try self.fnDecl(f),
            // Phantom `@Context` base structs are erased from the typedef too.
            .record => |r| try self.record(r),
            .@"enum" => |e| try self.enumDecl(e),
            .interface => |i| try self.interface(i),
            .implement => |im| try self.implement(im),
            // `extend` dispatch/codegen is handled in a later phase
            // (extension-dispatch).
            .extend => .none,
            .use => |u| try self.use(u),
            .delegate => |d| try self.delegate(d),
            // Test blocks never surface in the public typedef; `mod` declares a
            // submodule that carries its own typedef, so it emits nothing here.
            .@"test", .mod, .comment => .none,
        };
    }

    fn val(self: *Builder, name: []const u8, is_pub: bool, ty: *comptimeMod.Type) Error!js.TsDecl {
        if (!is_pub and name.len > 0) return .none;
        return .{ .const_ = .{ .name = name, .type = try self.inferredType(ty.*) } };
    }

    fn fnDecl(self: *Builder, f: ast.FnDecl) Error!js.TsDecl {
        if (!f.isPub) return .none;
        // Template fns (`@Expr<…>` / `@ExprCustom<…>`) expand at their call site
        // and never reach codegen. Their `.d.ts` surface would be unusable from
        // host TypeScript — drop the declaration entirely.
        if (f.returnType) |ret| if (ret.isTemplateReturnType()) return .none;
        return .{ .func = .{
            .name = f.name,
            .params = try self.params(f.params),
            .ret = try self.returnType(f.returnType),
        } };
    }

    fn record(self: *Builder, r: ast.RecordDecl) Error!js.TsDecl {
        if (!r.isPub) return .none;
        var members: std.ArrayListUnmanaged(js.TsMember) = .empty;
        for (r.fields) |f| try members.append(self.b.arena, .{ .field = .{
            .modifier = "readonly ",
            .name = f.name,
            .type = try self.typeRef(f.typeRef),
        } });
        const ctor_params = try self.b.arena.alloc(js.TsParam, r.fields.len);
        for (r.fields, 0..) |f, i| ctor_params[i] = .{ .name = f.name, .type = try self.typeRef(f.typeRef) };
        try members.append(self.b.arena, .{ .ctor = .{ .params = ctor_params } });
        for (r.methods) |m| {
            if (m.is_declare) continue;
            if (m.returnType) |ret| if (ret.isTemplateReturnType()) continue;
            try members.append(self.b.arena, .{ .method = .{
                .name = m.name,
                .params = try self.params(m.params),
                .ret = try self.returnType(m.returnType),
            } });
        }
        return .{ .class = .{ .name = r.name, .members = try members.toOwnedSlice(self.b.arena) } };
    }

    fn enumDecl(self: *Builder, e: ast.EnumDecl) Error!js.TsDecl {
        if (!e.isPub) return .none;
        // Unit variants become a TypeScript enum; payload variants a
        // discriminated union type.
        var has_payload = false;
        for (e.variants) |v| {
            if (v.fields.len > 0) {
                has_payload = true;
                break;
            }
        }
        if (!has_payload) {
            const members = try self.b.arena.alloc(js.TsMember, e.variants.len);
            for (e.variants, 0..) |v, i| members[i] = .{ .enum_member = .{ .name = v.name, .value = v.name } };
            return .{ .enum_ = .{ .name = e.name, .members = members } };
        }
        const arms = try self.b.arena.alloc(js.TsType, e.variants.len);
        for (e.variants, 0..) |v, i| {
            const fields = try self.b.arena.alloc(js.TsField, v.fields.len + 1);
            fields[0] = .{ .name = "tag", .type = .{ .literal = v.name } };
            for (v.fields, 0..) |f, fi| fields[fi + 1] = .{ .name = f.name, .type = try self.typeRef(f.typeRef) };
            arms[i] = .{ .object = .{ .fields = fields } };
        }
        return .{ .type_alias = .{ .name = e.name, .type = .{ .union_ = arms } } };
    }

    fn interface(self: *Builder, i: ast.InterfaceDecl) Error!js.TsDecl {
        if (!i.isPub) return .none;
        var members: std.ArrayListUnmanaged(js.TsMember) = .empty;
        for (i.fields) |f| try members.append(self.b.arena, .{ .field = .{
            .name = f.name,
            .type = namedType(f.typeName),
        } });
        for (i.methods) |m| {
            if (m.is_default) continue;
            if (m.returnType) |ret| if (ret.isTemplateReturnType()) continue;
            try members.append(self.b.arena, .{ .method = .{
                .name = m.name,
                .params = try self.params(m.params),
                .ret = try self.returnType(m.returnType),
            } });
        }
        return .{ .interface = .{
            .name = i.name,
            .extends = i.extends,
            .members = try members.toOwnedSlice(self.b.arena),
        } };
    }

    /// `implement … for T` adds methods to an existing type; each one surfaces
    /// as a free function named `<Target>_<method>`.
    fn implement(self: *Builder, im: ast.ImplementDecl) Error!js.TsDecl {
        const decls = try self.b.arena.alloc(js.TsDecl, im.methods.len);
        for (im.methods, 0..) |m, i| {
            decls[i] = .{ .func = .{
                .name = try std.fmt.allocPrint(self.b.arena, "{s}_{s}", .{ im.target, m.name }),
                .params = try self.params(m.params),
                .ret = .{ .name = "void" },
            } };
        }
        return .{ .group = decls };
    }

    fn use(self: *Builder, u: ast.ImportDecl) Error!js.TsDecl {
        // Fallback activation `X*;` has no type binding — emit nothing.
        if (u.activationOnly) return .none;
        const names = try self.b.arena.alloc([]const u8, u.imports.len);
        for (u.imports, 0..) |imp, i| names[i] = imp.name();
        return .{ .import = .{
            .names = names,
            .source = switch (u.source) {
                .root => "./module",
                .module => |name| name,
            },
        } };
    }

    fn delegate(self: *Builder, d: ast.DelegateDecl) Error!js.TsDecl {
        if (!d.isPub) return .none;
        const ps = try self.b.arena.alloc(js.TsParam, d.params.len);
        for (d.params, 0..) |p, i| ps[i] = .{ .name = p.name, .type = try self.typeRef(p.typeRef) };
        const ret = try self.b.typePtr(if (d.returnType) |r| namedType(r) else js.TsType{ .name = "void" });
        return .{ .type_alias = .{
            .name = d.name,
            .type = .{ .func = .{ .params = ps, .ret = ret } },
        } };
    }

    // ── params ───────────────────────────────────────────────────────────────

    fn params(self: *Builder, ps: []const ast.Param) Error![]const js.TsParam {
        var out: std.ArrayListUnmanaged(js.TsParam) = .empty;
        for (ps) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try out.append(self.b.arena, .{ .name = p.name, .type = try self.typeRef(p.typeRef) });
        }
        return out.toOwnedSlice(self.b.arena);
    }

    fn returnType(self: *Builder, ret: ?ast.TypeRef) Error!js.TsType {
        return if (ret) |r| try self.typeRef(r) else .{ .name = "void" };
    }

    // ── types ────────────────────────────────────────────────────────────────

    /// A type the frontend carries as a name (an interface field, a delegate's
    /// return). A position with no written type is `any`, TypeScript's own
    /// spelling of "not constrained" — never an empty `x: `.
    fn namedType(name: []const u8) js.TsType {
        return .{ .name = if (name.len == 0) "any" else name };
    }

    fn derefType(ty: comptimeMod.Type) comptimeMod.Type {
        var cur = ty;
        while (true) {
            switch (cur) {
                .typeVar => |cell| switch (cell.state) {
                    .link => |linked| cur = linked.*,
                    else => return cur,
                },
                else => return cur,
            }
        }
    }

    /// An inferred type (`comptime.Type`), as `.d.ts` spells it.
    fn inferredType(self: *Builder, ty: comptimeMod.Type) Error!js.TsType {
        switch (derefType(ty)) {
            .named => |n| {
                if (n.args.len == 0) return .{ .name = n.name };
                const args = try self.b.arena.alloc(js.TsType, n.args.len);
                for (n.args, 0..) |a, i| args[i] = try self.inferredType(a.*);
                return .{ .generic = .{ .name = n.name, .args = args } };
            },
            .func => |f| {
                const ps = try self.b.arena.alloc(js.TsParam, f.params.len);
                for (f.params, 0..) |p, i| ps[i] = .{
                    .name = try std.fmt.allocPrint(self.b.arena, "p{d}", .{i}),
                    .type = try self.inferredType(p.*),
                };
                return .{ .func = .{ .params = ps, .ret = try self.b.typePtr(try self.inferredType(f.ret.*)) } };
            },
            .typeVar => return .{ .name = "any" },
            .union_ => |types| {
                const arms = try self.b.arena.alloc(js.TsType, types.len);
                for (types, 0..) |t, i| arms[i] = try self.inferredType(t.*);
                return .{ .union_ = arms };
            },
            // Anonymous structural record → inline object type.
            .record => |fields| {
                const fs = try self.b.arena.alloc(js.TsField, fields.len);
                for (fields, 0..) |f, i| fs[i] = .{ .name = f.name, .type = try self.inferredType(f.type_.*) };
                return .{ .object = .{ .fields = fs, .sep = "; " } };
            },
        }
    }

    /// A syntactic type reference (`ast.TypeRef`), as `.d.ts` spells it.
    fn typeRef(self: *Builder, tr: ast.TypeRef) Error!js.TsType {
        switch (tr) {
            // A parameter the source leaves unannotated carries an empty name.
            .named => |n| return namedType(n),
            .array => |inner| return .{ .array = try self.b.typePtr(try self.typeRef(inner.*)) },
            .tuple_ => |elems| {
                const out = try self.b.arena.alloc(js.TsType, elems.len);
                for (elems, 0..) |e, i| out[i] = try self.typeRef(e);
                return .{ .tuple = out };
            },
            // `?T` is `T | null`.
            .optional => |inner| return .{ .union_ = try self.b.types(&.{
                try self.typeRef(inner.*),
                .{ .name = "null" },
            }) },
            .function => |f| {
                const ps = try self.b.arena.alloc(js.TsParam, f.params.len);
                for (f.params, 0..) |p, i| ps[i] = .{ .type = try self.typeRef(p) };
                return .{ .func = .{ .params = ps, .ret = try self.b.typePtr(try self.typeRef(f.returnType.*)) } };
            },
            .generic => |g| return self.genericTypeRef(g),
            // A comptime typeparam is erased after specialization; surface it
            // as `any`.
            .typeparam => return .{ .name = "any" },
            .record_type => |flds| {
                const fs = try self.b.arena.alloc(js.TsField, flds.len);
                for (flds, 0..) |f, i| fs[i] = .{ .name = f.name, .type = try self.typeRef(f.typeRef) };
                return .{ .object = .{ .fields = fs } };
            },
        }
    }

    /// The effect wrappers erase or map onto a host type.
    fn genericTypeRef(self: *Builder, g: anytype) Error!js.TsType {
        // `@Context<B, R>` is a phantom capability — at the value level a
        // context function yields its Return type `R`. Erase the wrapper.
        if (std.mem.eql(u8, g.name, "Context") and g.args.len == 2) {
            return self.typeRef(g.args[1]);
        }
        if (std.mem.eql(u8, g.name, "Result") and g.args.len == 2) {
            return .{ .union_ = try self.b.types(&.{
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "tag", .type = .{ .literal = "Ok" } },
                    .{ .name = "result", .type = try self.typeRef(g.args[0]) },
                }), .sep = "; " } },
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "tag", .type = .{ .literal = "Error" } },
                    .{ .name = "error", .type = try self.typeRef(g.args[1]) },
                }), .sep = "; " } },
            }) };
        }
        // `@Future<T>` → `Promise<T>`; `@Iterator<T>` → `IterableIterator<T>`;
        // `@AsyncIterator<T, E>` → `AsyncIterableIterator<T>` (TypeScript
        // tracks only the item type).
        const host: ?[]const u8 =
            if (std.mem.eql(u8, g.name, "Future")) "Promise" else if (std.mem.eql(u8, g.name, "Iterator")) "IterableIterator" else if (std.mem.eql(u8, g.name, "AsyncIterator")) "AsyncIterableIterator" else null;
        if (host) |h| if (g.args.len >= 1) {
            return .{ .generic = .{ .name = h, .args = try self.b.types(&.{try self.typeRef(g.args[0])}) } };
        };
        // `@Decl` with no type arguments is the plain name, never `Decl<>`.
        if (g.args.len == 0) return .{ .name = g.name };
        const args = try self.b.arena.alloc(js.TsType, g.args.len);
        for (g.args, 0..) |a, i| args[i] = try self.typeRef(a);
        return .{ .generic = .{ .name = g.name, .args = args } };
    }
};
