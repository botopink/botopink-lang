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
const crossModule = @import("./crossModule.zig");

/// Emit a TypeScript declaration file for all bindings. `cross` (null for a
/// standalone module) says which imported names another module actually emits.
pub fn emitProgram(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
    cross: ?*const crossModule.CrossModule,
    /// The module's path (`main`, `shapes/circle`, `<dep>/<mod>`): an import's
    /// source is spelled relative to it, as the `.js` beside it spells its
    /// `require`.
    module_name: []const u8,
) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var bld = Builder{ .b = .{ .arena = arena.allocator() }, .cross = cross, .module_name = module_name };

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
    cross: ?*const crossModule.CrossModule = null,
    module_name: []const u8 = "",
    /// What `Self` spells inside the declaration being built — the class with
    /// its own type parameters (`Dict<K, V>`). TypeScript has no `Self`.
    self_type: ?js.TsType = null,
    /// Import declarations already written: the checker hands one
    /// `TypedBinding` per imported NAME, each carrying the whole
    /// `ImportDecl`, and every one of them used to write the full `import`.
    seen_import_decls: std.ArrayListUnmanaged([*]const ast.ImportPath) = .empty,
    /// Names an `import` already bound in this file — a second binding of
    /// one is `Duplicate identifier` to `tsc`.
    seen_import_names: std.ArrayListUnmanaged([]const u8) = .empty,

    const Error = anyerror;

    // ── declarations ─────────────────────────────────────────────────────────

    fn binding(self: *Builder, bd: comptimeMod.TypedBinding) Error!js.TsDecl {
        return switch (bd.decl) {
            .val => |v| try self.val(v.name, v.isPub, bd.type_),
            .@"fn" => |f| try self.fnDecl(f),
            // Phantom `@Context` base structs are erased from the typedef too.
            .type_ => |t| if (t.isRecord()) try self.record(t) else try self.enumDecl(t),
            .behavior => |i| try self.interface(i),
            .implement => |im| try self.implement(im),
            // `extend` dispatch/codegen is handled in a later phase
            // (extension-dispatch).
            .extend => .none,
            .use => |u| try self.use(u),
            .delegate => |d| try self.delegate(d),
            // Test blocks never surface in the public typedef; `mod` declares a
            // submodule that carries its own typedef, so it emits nothing here.
            .@"test", .mod, .comment => .none,
            .typeAlias => |a| try self.typeAlias(a),
        };
    }

    /// `pub type Parser<T> = @Result<T, E>;` → `export declare type Parser<T> = …;`,
    /// the target mapped the way any annotation is, so a signature that
    /// writes the alias names a type the `.d.ts` declares.
    fn typeAlias(self: *Builder, a: ast.TypeAliasDecl) Error!js.TsDecl {
        if (!a.isPub) return .none;
        var name: std.ArrayListUnmanaged(u8) = .empty;
        try name.appendSlice(self.b.arena, a.name);
        if (a.genericParams.len > 0) {
            try name.append(self.b.arena, '<');
            for (a.genericParams, 0..) |gp, i| {
                if (i > 0) try name.appendSlice(self.b.arena, ", ");
                try name.appendSlice(self.b.arena, gp.name);
            }
            try name.append(self.b.arena, '>');
        }
        return .{ .type_alias = .{ .name = name.items, .type = try self.typeRef(a.target) } };
    }

    fn val(self: *Builder, name: []const u8, is_pub: bool, ty: *comptimeMod.Type) Error!js.TsDecl {
        if (!is_pub and name.len > 0) return .none;
        return .{ .const_ = .{ .name = name, .type = try self.inferredType(ty.*) } };
    }

    /// `name<A, B>` — a declaration's name with its type parameters, which
    /// the `.d.ts` must declare or every `A` in the signature is `Cannot find
    /// name` (the model has no slot for them, so they ride in the name, as a
    /// type alias's always have).
    fn genericName(self: *Builder, name: []const u8, gps: []const ast.GenericParam) Error![]const u8 {
        if (gps.len == 0) return name;
        var out: std.ArrayListUnmanaged(u8) = .empty;
        try out.appendSlice(self.b.arena, name);
        try out.append(self.b.arena, '<');
        for (gps, 0..) |gp, i| {
            if (i > 0) try out.appendSlice(self.b.arena, ", ");
            try out.appendSlice(self.b.arena, gp.name);
        }
        try out.append(self.b.arena, '>');
        return out.items;
    }

    /// The type a declaration's own `Self` stands for: its name, applied to
    /// its type parameters.
    fn selfTypeOf(self: *Builder, name: []const u8, gps: []const ast.GenericParam) Error!js.TsType {
        if (gps.len == 0) return .{ .name = name };
        const args = try self.b.arena.alloc(js.TsType, gps.len);
        for (gps, 0..) |gp, i| args[i] = .{ .name = gp.name };
        return .{ .generic = .{ .name = name, .args = args } };
    }

    fn fnDecl(self: *Builder, f: ast.FnDecl) Error!js.TsDecl {
        if (!f.isPub) return .none;
        // Template fns (`@Expr<…>` / `@ExprCustom<…>`) expand at their call site
        // and never reach codegen. Their `.d.ts` surface would be unusable from
        // host TypeScript — drop the declaration entirely.
        if (f.returnType) |ret| if (ret.isTemplateReturnType()) return .none;
        // A decorator (`comptime _: @Decl` first) runs at compile time and is
        // dropped from the program before the JavaScript is written, so the
        // `.d.ts` declaring it promised a function the module does not export
        // — and named `Decl`, which no TypeScript declares.
        if (f.params.len > 0 and f.params[0].modifier == .@"comptime" and f.params[0].typeRef.isDeclType()) return .none;
        return .{ .func = .{
            .name = try self.genericName(f.name, f.genericParams),
            .params = try self.params(f.params),
            .ret = try self.returnType(f.returnType),
        } };
    }

    fn record(self: *Builder, r: ast.TypeDecl) Error!js.TsDecl {
        if (!r.isPub) return .none;
        const saved_self = self.self_type;
        defer self.self_type = saved_self;
        self.self_type = try self.selfTypeOf(r.name, r.genericParams);
        var members: std.ArrayListUnmanaged(js.TsMember) = .empty;
        for (r.recordFields()) |f| try members.append(self.b.arena, .{ .field = .{
            .modifier = "readonly ",
            .name = f.name,
            .type = try self.typeRef(f.typeRef),
        } });
        const ctor_params = try self.b.arena.alloc(js.TsParam, r.recordFields().len);
        for (r.recordFields(), 0..) |f, i| ctor_params[i] = .{ .name = f.name, .type = try self.typeRef(f.typeRef) };
        try members.append(self.b.arena, .{ .ctor = .{ .params = ctor_params } });
        for (r.methods) |m| {
            if (m.is_declare) continue;
            if (m.returnType) |ret| if (ret.isTemplateReturnType()) continue;
            try members.append(self.b.arena, .{ .method = .{
                .name = try self.genericName(m.name, m.genericParams),
                .params = try self.params(m.params),
                .ret = try self.returnType(m.returnType),
            } });
        }
        return .{ .class = .{ .name = try self.genericName(r.name, r.genericParams), .members = try members.toOwnedSlice(self.b.arena) } };
    }

    /// An enum declares the **class** the JavaScript builds (decision 5): a
    /// payload variant is a `static` factory returning the enum type, a
    /// payload-less one a `static readonly` singleton of it, and every value
    /// carries the `tag` its prototype holds. Before this the typedef promised
    /// a TypeScript `enum` of strings or a discriminated union of plain
    /// objects, and the `.js` beside it built neither.
    fn enumDecl(self: *Builder, e: ast.TypeDecl) Error!js.TsDecl {
        if (!e.isPub) return .none;
        const saved_self = self.self_type;
        defer self.self_type = saved_self;
        self.self_type = try self.selfTypeOf(e.name, e.genericParams);
        const enum_type = self.self_type.?;
        var members: std.ArrayListUnmanaged(js.TsMember) = .empty;
        try members.append(self.b.arena, .{ .field = .{
            .modifier = "readonly ",
            .name = "tag",
            .type = .{ .union_ = blk: {
                const tags = try self.b.arena.alloc(js.TsType, e.variants().len);
                for (e.variants(), 0..) |v, i| tags[i] = .{ .literal = v.name };
                break :blk tags;
            } },
        } });
        for (e.variants()) |v| {
            if (v.fields.len == 0) {
                try members.append(self.b.arena, .{ .field = .{
                    .modifier = "static readonly ",
                    .name = v.name,
                    .type = enum_type,
                } });
                continue;
            }
            const ps = try self.b.arena.alloc(js.TsParam, v.fields.len);
            for (v.fields, 0..) |f, i| ps[i] = .{ .name = f.name, .type = try self.typeRef(f.typeRef) };
            try members.append(self.b.arena, .{ .method = .{
                .modifier = "static ",
                .name = try self.genericName(v.name, e.genericParams),
                .params = ps,
                .ret = enum_type,
            } });
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            if (m.returnType) |ret| if (ret.isTemplateReturnType()) continue;
            // An enum method is a `static` of the enum's class, and a
            // receiver-first one keeps `self` as a real first parameter, so it
            // is not dropped the way a record method's `self` is.
            var ps: std.ArrayListUnmanaged(js.TsParam) = .empty;
            for (m.params) |p| try ps.append(self.b.arena, .{
                .name = p.name,
                .type = if (std.mem.eql(u8, p.name, "self")) enum_type else try self.typeRef(p.typeRef),
            });
            // A static cannot see the class's type parameters, so it declares
            // them itself, with its own after them.
            var gps: std.ArrayListUnmanaged(ast.GenericParam) = .empty;
            try gps.appendSlice(self.b.arena, e.genericParams);
            try gps.appendSlice(self.b.arena, m.genericParams);
            try members.append(self.b.arena, .{ .method = .{
                .modifier = "static ",
                .name = try self.genericName(m.name, gps.items),
                .params = try ps.toOwnedSlice(self.b.arena),
                .ret = try self.returnType(m.returnType),
            } });
        }
        return .{ .class = .{ .name = try self.genericName(e.name, e.genericParams), .members = try members.toOwnedSlice(self.b.arena) } };
    }

    fn interface(self: *Builder, i: ast.BehaviorDecl) Error!js.TsDecl {
        if (!i.isPub) return .none;
        const saved_self = self.self_type;
        defer self.self_type = saved_self;
        self.self_type = try self.selfTypeOf(i.name, i.genericParams);
        var members: std.ArrayListUnmanaged(js.TsMember) = .empty;
        for (i.fields) |f| try members.append(self.b.arena, .{ .field = .{
            .name = f.name,
            .type = try self.typeRef(f.typeRef),
        } });
        for (i.methods) |m| {
            if (m.is_default) continue;
            if (m.returnType) |ret| if (ret.isTemplateReturnType()) continue;
            try members.append(self.b.arena, .{ .method = .{
                .name = try self.genericName(m.name, m.genericParams),
                .params = try self.params(m.params),
                .ret = try self.returnType(m.returnType),
            } });
        }
        return .{ .interface = .{
            .name = try self.genericName(i.name, i.genericParams),
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

    /// An import, spelled the way the `.js` beside it spells its `require`
    /// (`commonJS.zig` `buildUse`): relative to this module's own path, one
    /// `import` per module that emits the names, and — from `"std"` — a whole
    /// module bound as a namespace. It used to write the `from` verbatim
    /// (`from "geometry"`, a bare specifier `tsc` resolves in `node_modules`)
    /// once per imported name.
    fn use(self: *Builder, u: ast.ImportDecl) Error!js.TsDecl {
        // Fallback activation `X*;` has no type binding — emit nothing.
        if (u.activationOnly) return .none;
        for (self.seen_import_decls.items) |p| if (p == u.imports.ptr) return .none;
        try self.seen_import_decls.append(self.b.arena, u.imports.ptr);

        const prefix = try self.requirePrefix();
        var decls: std.ArrayListUnmanaged(js.TsDecl) = .empty;

        if (u.source == .module and std.mem.eql(u8, u.source.module, "std")) {
            var mods: std.ArrayListUnmanaged([]const u8) = .empty;
            var names: std.ArrayListUnmanaged(std.ArrayListUnmanaged([]const u8)) = .empty;
            for (u.imports) |imp| {
                if (imp.activate) continue;
                if (!try self.noteImportName(imp.name())) continue;
                const whole = try imp.fullPath(self.b.arena);
                if (!imp.isQualified() or comptimeMod.isStdModule(whole)) {
                    try decls.append(self.b.arena, .{ .import_namespace = .{
                        .name = imp.name(),
                        .source = try std.fmt.allocPrint(self.b.arena, "{s}std/{s}", .{ prefix, whole }),
                    } });
                    continue;
                }
                const mod = try imp.prefixPath(self.b.arena);
                const slot = for (mods.items, 0..) |m, k| {
                    if (std.mem.eql(u8, m, mod)) break k;
                } else blk: {
                    try mods.append(self.b.arena, mod);
                    try names.append(self.b.arena, .empty);
                    break :blk mods.items.len - 1;
                };
                try names.items[slot].append(self.b.arena, try importSpec(self.b.arena, imp));
            }
            for (mods.items, names.items) |mod, list| try decls.append(self.b.arena, .{ .import = .{
                .names = list.items,
                .source = try std.fmt.allocPrint(self.b.arena, "{s}std/{s}", .{ prefix, mod }),
            } });
            return group(decls.items);
        }

        // Every other import names its symbols one by one, each resolved to the
        // module that emits it. A name whose owner's `.d.ts` declares nothing
        // for it (a template fn, a lib namespace handle, an activated
        // `implement`) is left out: importing it would dangle.
        const xm = self.cross orelse return .none;
        var seen_mods: std.ArrayListUnmanaged([]const u8) = .empty;
        for (u.imports) |imp| {
            if (imp.activate) continue;
            const info = xm.picked(imp.leaf(), try u.leafSource(imp, self.b.arena, false), null) orelse continue;
            const already = for (seen_mods.items) |m| {
                if (std.mem.eql(u8, m, info.module)) break true;
            } else false;
            if (already) continue;
            try seen_mods.append(self.b.arena, info.module);
            var names: std.ArrayListUnmanaged([]const u8) = .empty;
            for (u.imports) |imp2| {
                if (imp2.activate) continue;
                const info2 = xm.picked(imp2.leaf(), try u.leafSource(imp2, self.b.arena, false), null) orelse continue;
                if (!std.mem.eql(u8, info2.module, info.module)) continue;
                if (!try self.noteImportName(imp2.name())) continue;
                try names.append(self.b.arena, try importSpec(self.b.arena, imp2));
            }
            if (names.items.len == 0) continue;
            try decls.append(self.b.arena, .{ .import = .{
                .names = names.items,
                .source = try std.fmt.allocPrint(self.b.arena, "{s}{s}", .{ prefix, info.module }),
            } });
        }
        return group(decls.items);
    }

    fn group(decls: []const js.TsDecl) js.TsDecl {
        return switch (decls.len) {
            0 => .none,
            1 => decls[0],
            else => .{ .group = decls },
        };
    }

    /// `leaf` or `leaf as alias`.
    fn importSpec(arena: std.mem.Allocator, imp: ast.ImportPath) Error![]const u8 {
        if (imp.alias) |a| if (!std.mem.eql(u8, a, imp.leaf()))
            return std.fmt.allocPrint(arena, "{s} as {s}", .{ imp.leaf(), a });
        return imp.leaf();
    }

    /// Records `name` as bound by an import; false when it already was.
    fn noteImportName(self: *Builder, name: []const u8) Error!bool {
        for (self.seen_import_names.items) |n| if (std.mem.eql(u8, n, name)) return false;
        try self.seen_import_names.append(self.b.arena, name);
        return true;
    }

    /// `./` for a module at the output root, one `../` per path segment
    /// otherwise — `commonJS.zig` `buildUse`'s `req_prefix`.
    fn requirePrefix(self: *Builder) Error![]const u8 {
        const depth = std.mem.count(u8, self.module_name, "/");
        if (depth == 0) return "./";
        var buf: std.ArrayListUnmanaged(u8) = .empty;
        for (0..depth) |_| try buf.appendSlice(self.b.arena, "../");
        return buf.items;
    }

    fn delegate(self: *Builder, d: ast.DelegateDecl) Error!js.TsDecl {
        if (!d.isPub) return .none;
        const ps = try self.b.arena.alloc(js.TsParam, d.params.len);
        for (d.params, 0..) |p, i| ps[i] = .{ .name = p.name, .type = try self.typeRef(p.typeRef) };
        const ret = try self.b.typePtr(if (d.returnType) |r| try self.typeRef(r) else js.TsType{ .name = "void" });
        return .{ .type_alias = .{
            .name = try self.genericName(d.name, d.genericParams),
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

    /// The TypeScript spelling of a botopink primitive. `i32` is not a
    /// TypeScript type: a `.d.ts` naming one is not a declaration file, it is
    /// a file `tsc` rejects, which is what made the emitted typedef worth
    /// nothing to a host consumer.
    fn primitiveTsName(name: []const u8) ?[]const u8 {
        const numbers = [_][]const u8{
            "i8",    "i16",   "i32", "i64",  "i128",
            "u8",    "u16",   "u32", "u64",  "u128",
            "f32",   "f64",   "int", "uint", "float",
            "isize", "usize",
        };
        for (numbers) |n| if (std.mem.eql(u8, name, n)) return "number";
        if (std.mem.eql(u8, name, "bool")) return "boolean";
        // `string`, `void`, `unknown`, `never` and `any` are spelled the same
        // in both languages and need no row of their own.
        if (std.mem.eql(u8, name, "char")) return "string";
        return null;
    }

    /// A type the frontend carries as a name (an interface field, a delegate's
    /// return). A position with no written type is `any`, TypeScript's own
    /// spelling of "not constrained" — never an empty `x: `. A botopink
    /// primitive takes its TypeScript spelling.
    fn namedType(name: []const u8) js.TsType {
        if (name.len == 0) return .{ .name = "any" };
        return .{ .name = primitiveTsName(name) orelse name };
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
                if (n.args.len == 0) return namedType(n.name);
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
            .named => |n| {
                if (std.mem.eql(u8, n, "Self")) if (self.self_type) |st| return st;
                return namedType(n);
            },
            .array => |inner| return .{ .array = try self.b.typePtr(try self.typeRef(inner.*)) },
            .tuple_ => |elems| {
                const out = try self.b.arena.alloc(js.TsType, elems.len);
                for (elems, 0..) |e, i| out[i] = try self.typeRef(e);
                return .{ .tuple = out };
            },
            // Labels are compile-time names: the value is the positional tuple.
            .labeledTuple => |lt| {
                const out = try self.b.arena.alloc(js.TsType, lt.elems.len);
                for (lt.elems, 0..) |e, i| out[i] = try self.typeRef(e);
                return .{ .tuple = out };
            },
            // `?T` is `T | null`.
            .optional => |inner| return .{ .union_ = try self.b.types(&.{
                try self.typeRef(inner.*),
                .{ .name = "null" },
            }) },
            .function => |f| {
                const ps = try self.b.arena.alloc(js.TsParam, f.params.len);
                // TypeScript's function type names every parameter: in
                // `(A, K) => A` each `A` is a parameter NAME of type `any`.
                for (f.params, 0..) |p, i| ps[i] = .{
                    .name = if (i < f.paramNames.len and f.paramNames[i].len > 0)
                        f.paramNames[i]
                    else
                        try std.fmt.allocPrint(self.b.arena, "p{d}", .{i}),
                    .type = try self.typeRef(p),
                };
                return .{ .func = .{ .params = ps, .ret = try self.b.typePtr(try self.typeRef(f.returnType.*)) } };
            },
            .generic => |g| return self.genericTypeRef(g),
            // A comptime typeparam is erased after specialization; surface it
            // as `any`.
            .typeparam => return .{ .name = "any" },
        }
    }

    /// The effect wrappers erase or map onto a host type.
    fn genericTypeRef(self: *Builder, g: anytype) Error!js.TsType {
        // Decision 8 §3's union `A | B` rides on `TypeRef.generic` under the
        // reserved name `ast.union_type_name` (`"|"`), which no source can
        // write. TypeScript spells it the same way botopink does, so it is the
        // model's own `union_` — not `|<A, B>`, which is not TypeScript.
        if (std.mem.eql(u8, g.name, ast.union_type_name)) {
            const members = try self.b.arena.alloc(js.TsType, g.args.len);
            for (g.args, 0..) |a, i| members[i] = try self.typeRef(a);
            return .{ .union_ = members };
        }
        // `#[@use]` lowers to an `async function` (decision 104), so its
        // wrapper is a `Promise` of the value: `@Component<C, T>` →
        // `Promise<T>` (the base `C` is a phantom, decision 128).
        if (std.mem.eql(u8, g.name, "Component") and g.args.len == 2) {
            return .{ .generic = .{ .name = "Promise", .args = try self.b.types(&.{try self.typeRef(g.args[1])}) } };
        }
        // `@Result<T, E>` is what the JavaScript builds: `{ ok: v }` or
        // `{ error: e }` (`buildResult`). It used to promise a tagged
        // `{ tag: "Ok"; result: T }` no module ever returned.
        if (std.mem.eql(u8, g.name, "Result") and g.args.len == 2) {
            return .{ .union_ = try self.b.types(&.{
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "ok", .type = try self.typeRef(g.args[0]) },
                }), .sep = "; " } },
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "error", .type = try self.typeRef(g.args[1]) },
                }), .sep = "; " } },
            }) };
        }
        // Decisions 120 / 122: `@Task<T>` → `Promise<T>`; `@Component<C, T>`
        // → `Promise<T>` (it extends `@Task`); `@Iterator<T>` →
        // `IterableIterator<T>`; `@Stream<T>` → `AsyncGenerator<T>`.
        if (std.mem.eql(u8, g.name, "Component") and g.args.len >= 2) {
            return .{ .generic = .{ .name = "Promise", .args = try self.b.types(&.{try self.typeRef(g.args[1])}) } };
        }
        const host: ?[]const u8 =
            if (std.mem.eql(u8, g.name, "Task")) "Promise" else if (std.mem.eql(u8, g.name, "Iterator")) "IterableIterator" else if (std.mem.eql(u8, g.name, "Stream")) "AsyncGenerator" else null;
        if (host) |h| if (g.args.len >= 1) {
            return .{ .generic = .{ .name = h, .args = try self.b.types(&.{try self.typeRef(g.args[0])}) } };
        };
        if (std.mem.eql(u8, g.name, "Self")) if (self.self_type) |st| return st;
        // `@Decl` with no type arguments is the plain name, never `Decl<>`.
        if (g.args.len == 0) return .{ .name = g.name };
        const args = try self.b.arena.alloc(js.TsType, g.args.len);
        for (g.args, 0..) |a, i| args[i] = try self.typeRef(a);
        return .{ .generic = .{ .name = g.name, .args = args } };
    }
};
