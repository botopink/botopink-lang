/// TypeScript `.d.ts` typedef backend.
///
/// Iterates over typed bindings and **builds** a declaration model
/// (`codegen/js/js_ast.zig`: `TsDecl` / `TsMember` / `TsType`); `ts_emitter.zig`
/// renders it. This file decides what the public contract of a module is —
/// which bindings surface, how `@Result` / `@Task` / `@Component` erase — and
/// writes no TypeScript text of its own.
const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const js = @import("./js/js_ast.zig");
const tsEmitter = @import("./js/ts_emitter.zig");
const crossModule = @import("./crossModule.zig");
const hostMethods = @import("./hostMethods.zig");

/// A `pub` declaration that is a TYPE and nothing else — a `behavior` (an
/// `interface` in the `.d.ts`) or a type alias. No `.js` emits a value for
/// one, so the cross-module index (`crossModule.zig`, which records what a
/// `require` reaches) does not know it, and an `import { Request } from
/// "web"` was dropped from the typedef: every signature naming `Request` was
/// `Cannot find name` to `tsc`. The `.d.ts` of the owner declares it, so the
/// importer's `.d.ts` imports it from there.
pub const TypeExport = struct {
    name: []const u8,
    /// The declaring module's path, as `crossModule.ExportInfo.module`.
    module: []const u8,
};

/// The `TypeExport` a binding declares, or null.
pub fn typeExportOf(bd: comptimeMod.TypedBinding) ?[]const u8 {
    return switch (bd.decl) {
        .behavior => |b| if (b.isPub) b.name else null,
        .typeAlias => |a| if (a.isPub) a.name else null,
        else => null,
    };
}

/// Emit a TypeScript declaration file for all bindings. `cross` (null for a
/// standalone module) says which imported names another module actually emits.
pub fn emitProgram(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
    cross: ?*const crossModule.CrossModule,
    /// Every type-only `pub` declaration of the program (`TypeExport`).
    type_exports: []const TypeExport,
    /// The module's path (`main`, `shapes/circle`, `<dep>/<mod>`): an import's
    /// source is spelled relative to it, as the `.js` beside it spells its
    /// `require`.
    module_name: []const u8,
    /// The declarations of the module's transformed program — the program the
    /// `.js` beside this `.d.ts` is written from, so it also holds the
    /// prelude records the comptime pass splices into a module that names
    /// them (`SourceLocation`, `YieldStep`, `Declared`, private, no binding).
    /// Its `type`s are, beside the bindings, where a private type a public
    /// signature names is declared from (`Builder.localTypes`).
    program_decls: []const ast.DeclKind,
) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var bld = Builder{ .b = .{ .arena = arena.allocator() }, .cross = cross, .type_exports = type_exports, .module_name = module_name };

    var decls: std.ArrayListUnmanaged(js.TsDecl) = .empty;
    for (bindings) |binding| try decls.append(bld.b.arena, try bld.binding(binding));
    try bld.localTypes(&decls, bindings, program_decls);

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try tsEmitter.writeProgram(&aw.writer, decls.items);
    return aw.toOwnedSlice();
}

/// Builds the `.d.ts` model. Every node it produces lives in `b.arena`.
const Builder = struct {
    b: js.Builder,
    cross: ?*const crossModule.CrossModule = null,
    type_exports: []const TypeExport = &.{},
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

    // ── module-private types ─────────────────────────────────────────────────

    /// A public signature may name a type the module keeps private — a
    /// `type` written without `pub`, or a prelude record the comptime pass
    /// spliced in (`pub fn path(loc: SourceLocation)` in std's
    /// `testing/snapshots`). The `.js` defines its class and exports nothing
    /// for it; the `.d.ts` named it and declared nothing, which `tsc` refuses
    /// (`Cannot find name 'SourceLocation'`). Each such name — and, to a
    /// fixpoint, each private type those declarations name in turn — is
    /// declared without `export`, after the module's own declarations, and
    /// the file then ends in `export {};`: without it TypeScript exports every
    /// top-level declaration of a declaration file, and the `.d.ts` would
    /// promise an export the `.js` does not have.
    ///
    /// The candidates are the module's own private declarations (its
    /// bindings: a `type`, a `behavior`, a type alias, a delegate) and the
    /// `type`s of the transformed program (the spliced prelude records). Not
    /// the program's other declarations: the comptime pass also prepends the
    /// std prelude's primitive behaviors a module calls into (`Array<T>`,
    /// `Pair<A, B>`, `String` — `env.assocInterfaceDecls`), and `Array<K>` in
    /// a signature is TypeScript's own `Array`, which a local `interface
    /// Array<T>` would shadow.
    fn localTypes(self: *Builder, decls: *std.ArrayListUnmanaged(js.TsDecl), bindings: []const comptimeMod.TypedBinding, program_decls: []const ast.DeclKind) Error!void {
        var candidates: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
        for (bindings) |bd| try candidates.append(self.b.arena, bd.decl);
        for (program_decls) |pd| if (pd == .type_) try candidates.append(self.b.arena, pd);
        var bound: std.StringHashMapUnmanaged(void) = .empty;
        var named: std.StringHashMapUnmanaged(void) = .empty;
        for (decls.items) |d| try self.scanDecl(d, &bound, &named);
        try self.reflectionCandidates(&candidates, &named);
        var added = false;
        var pass_start: usize = decls.items.len;
        while (true) {
            var progress = false;
            for (candidates.items) |pd| {
                const name = localTypeName(pd) orelse continue;
                if (bound.contains(name) or !named.contains(name)) continue;
                const d = try self.markPrivate(try self.privateDecl(pd));
                if (d == .none) continue;
                try bound.put(self.b.arena, name, {});
                try decls.append(self.b.arena, d);
                progress = true;
                added = true;
            }
            if (!progress) break;
            for (decls.items[pass_start..]) |d| try self.scanDecl(d, &bound, &named);
            pass_start = decls.items.len;
        }
        try self.programImports(decls, &bound, &named, program_decls);
        if (added) try decls.append(self.b.arena, .export_none);
    }

    /// A public signature may name a type of another module that the module
    /// never imports in its source: the transformed program imports it where
    /// a value of it is written (01-compiler/14 step 8 — a `comptime` whose
    /// answer is a package's record is lifted as that record's constructor,
    /// imported under its template alias, `Env.templateImports`). The `.js`
    /// requires it from that `import`, which is no binding of the module; the
    /// `.d.ts` named it and imported nothing (`Cannot find name 'Badge'`).
    /// Each name a declaration reads that nothing binds and that such an
    /// `import` brings is imported from the module that emits it, by its
    /// declared name — the alias is a checker name only (decision 110), as
    /// the `.js` spells it — at the top of the file.
    fn programImports(self: *Builder, decls: *std.ArrayListUnmanaged(js.TsDecl), bound: *std.StringHashMapUnmanaged(void), named: *const std.StringHashMapUnmanaged(void), program_decls: []const ast.DeclKind) Error!void {
        const xm = self.cross orelse return;
        const prefix = try self.requirePrefix();
        var imports: std.ArrayListUnmanaged(js.TsDecl) = .empty;
        for (program_decls) |pd| {
            if (pd != .use) continue;
            const u = pd.use;
            if (u.activationOnly) continue;
            if (u.source == .module and std.mem.eql(u8, u.source.module, "std")) continue;
            for (u.imports) |imp| {
                if (imp.activate) continue;
                const leaf = imp.leaf();
                if (bound.contains(leaf) or !named.contains(leaf)) continue;
                const module = try self.ownerOf(xm, u, imp) orelse continue;
                if (!try self.noteImportName(leaf)) continue;
                const names = try self.b.arena.alloc([]const u8, 1);
                names[0] = leaf;
                try imports.append(self.b.arena, .{ .import = .{
                    .names = names,
                    .source = try std.fmt.allocPrint(self.b.arena, "{s}{s}", .{ prefix, module }),
                } });
                try bound.put(self.b.arena, leaf, {});
            }
        }
        if (imports.items.len > 0) try decls.insertSlice(self.b.arena, 0, imports.items);
    }

    /// The comptime reflection records a signature names (`__Decl__Annotation`
    /// in std's `Type.Field<T>`, whose `annotations` are `DeclAnnotation[]`):
    /// the module never declares them — they live in the checker's prelude
    /// (`comptime.zig` `decl_reflection_src`) — so they join the candidates,
    /// read from that one source, only when a declaration names one; the
    /// behaviors of that source join with them (`Decorator`, the type of an
    /// annotation's `decorator`), since a record names one in turn.
    fn reflectionCandidates(self: *Builder, candidates: *std.ArrayListUnmanaged(ast.DeclKind), named: *const std.StringHashMapUnmanaged(void)) Error!void {
        var it = named.keyIterator();
        const wanted = while (it.next()) |k| {
            if (std.mem.startsWith(u8, k.*, decl_reflection_prefix)) break true;
        } else false;
        if (!wanted) return;
        var lx = Lexer.init(comptimeMod.decl_reflection_src);
        const tokens = try lx.scanAll(self.b.arena);
        var p = Parser.init(tokens);
        const prog = try p.parse(self.b.arena);
        for (prog.decls) |d| switch (d) {
            .type_ => |t| if (std.mem.startsWith(u8, t.name, decl_reflection_prefix)) try candidates.append(self.b.arena, d),
            // A behavior the records name (`Decorator`, decision 268: an
            // annotation's `decorator`, decision 277) is no binding of the
            // module either: it joins private, declared only when named.
            .behavior => |b| {
                var pb = b;
                pb.isPub = false;
                try candidates.append(self.b.arena, .{ .behavior = pb });
            },
            else => {},
        };
    }

    /// The prefix of the comptime reflection records' names.
    const decl_reflection_prefix = "__Decl__";

    /// The name a declaration of the program binds as a TYPE in the `.d.ts`,
    /// when it is not already public (a public one is a binding's).
    fn localTypeName(d: ast.DeclKind) ?[]const u8 {
        return switch (d) {
            // The comptime reflection records (`__Decl__Annotation`, … —
            // `comptime.zig` `decl_reflection_src`) are spliced in `pub` but
            // are no binding of the module: `Type.Field<T>`'s `annotations:
            // DeclAnnotation[]` named one the `.d.ts` never declared.
            .type_ => |t| if (t.isPub and !std.mem.startsWith(u8, t.name, decl_reflection_prefix)) null else t.name,
            .behavior => |b| if (b.isPub) null else b.name,
            .typeAlias => |a| if (a.isPub) null else a.name,
            .delegate => |dg| if (dg.isPub) null else dg.name,
            else => null,
        };
    }

    /// A private declaration built by the public path (`isPub` forced).
    fn privateDecl(self: *Builder, d: ast.DeclKind) Error!js.TsDecl {
        return switch (d) {
            .type_ => |t| blk: {
                var pt = t;
                pt.isPub = true;
                break :blk if (pt.isRecord()) try self.record(pt) else try self.enumDecl(pt);
            },
            .behavior => |b| blk: {
                var pb = b;
                pb.isPub = true;
                break :blk try self.interface(pb);
            },
            .typeAlias => |a| blk: {
                var pa = a;
                pa.isPub = true;
                break :blk try self.typeAlias(pa);
            },
            .delegate => |dg| blk: {
                var pd = dg;
                pd.isPub = true;
                break :blk try self.delegate(pd);
            },
            else => .none,
        };
    }

    /// `d` without its `export`.
    fn markPrivate(self: *Builder, d: js.TsDecl) Error!js.TsDecl {
        var out = d;
        switch (out) {
            .class => |*c| c.exported = false,
            .interface => |*i| i.exported = false,
            .type_alias => |*t| t.exported = false,
            .namespace_ => |*ns| ns.exported = false,
            // An enum with sections: its class and the namespace merged with
            // it, both private.
            .group => |items| {
                const copy = try self.b.arena.alloc(js.TsDecl, items.len);
                for (items, copy) |item, *c| c.* = try self.markPrivate(item);
                out = .{ .group = copy };
            },
            else => {},
        }
        return out;
    }

    /// Records the names `d` binds (`bound`) and the type names it reads
    /// (`named`): a qualified `Token.Layout` reads `Token`, and a generic
    /// declaration's `Name<A>` binds `Name`.
    fn scanDecl(self: *Builder, d: js.TsDecl, bound: *std.StringHashMapUnmanaged(void), named: *std.StringHashMapUnmanaged(void)) Error!void {
        const a = self.b.arena;
        switch (d) {
            .none, .export_none => {},
            .const_ => |c| {
                try bound.put(a, baseName(c.name), {});
                try self.scanType(c.type, named);
            },
            .func => |f| {
                try bound.put(a, baseName(f.name), {});
                for (f.params) |p| try self.scanType(p.type, named);
                try self.scanType(f.ret, named);
            },
            .class => |c| {
                try bound.put(a, baseName(c.name), {});
                for (c.members) |m| try self.scanMember(m, named);
            },
            .interface => |i| {
                try bound.put(a, baseName(i.name), {});
                for (i.extends) |e| try named.put(a, baseName(e), {});
                for (i.members) |m| try self.scanMember(m, named);
            },
            .enum_ => |e| try bound.put(a, baseName(e.name), {}),
            .type_alias => |t| {
                try bound.put(a, baseName(t.name), {});
                try self.scanType(t.type, named);
            },
            .namespace_ => |ns| try bound.put(a, ns.name, {}),
            .import => |i| for (i.names) |n| {
                const as = std.mem.indexOf(u8, n, " as ");
                try bound.put(a, if (as) |k| n[k + 4 ..] else n, {});
            },
            .import_namespace => |i| try bound.put(a, i.name, {}),
            .group => |items| for (items) |item| try self.scanDecl(item, bound, named),
        }
    }

    fn scanMember(self: *Builder, m: js.TsMember, named: *std.StringHashMapUnmanaged(void)) Error!void {
        switch (m) {
            .field => |f| try self.scanType(f.type, named),
            .method => |f| {
                for (f.params) |p| try self.scanType(p.type, named);
                try self.scanType(f.ret, named);
            },
            .getter => |g| try self.scanType(g.type, named),
            .setter => |st| for (st.params) |p| try self.scanType(p.type, named),
            .ctor => |c| for (c.params) |p| try self.scanType(p.type, named),
            .enum_member => {},
        }
    }

    fn scanType(self: *Builder, t: js.TsType, named: *std.StringHashMapUnmanaged(void)) Error!void {
        const a = self.b.arena;
        switch (t) {
            .name => |n| try named.put(a, baseName(n), {}),
            .literal => {},
            .generic => |g| {
                try named.put(a, baseName(g.name), {});
                for (g.args) |x| try self.scanType(x, named);
            },
            .array => |inner| try self.scanType(inner.*, named),
            .tuple, .union_ => |ts| for (ts) |x| try self.scanType(x, named),
            .func => |f| {
                for (f.params) |p| try self.scanType(p.type, named);
                try self.scanType(f.ret.*, named);
            },
            .object => |o| for (o.fields) |f| try self.scanType(f.type, named),
        }
    }

    /// `Name` of `Name<A, B>` or of `Name.Section`.
    fn baseName(n: []const u8) []const u8 {
        const end = std.mem.indexOfAny(u8, n, "<.") orelse n.len;
        return n[0..end];
    }

    // ── declarations ─────────────────────────────────────────────────────────

    fn binding(self: *Builder, bd: comptimeMod.TypedBinding) Error!js.TsDecl {
        return switch (bd.decl) {
            .val => |v| try self.val(v.name, v.isPub, bd.type_),
            .@"fn" => |f| try self.fnDecl(f),
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
            if (m.is_declare and !declaresHostMember(m)) continue;
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
        try members.append(self.b.arena, try self.tagField(e.variants(), e.sections()));
        // A section is a payload variant of the enum whose one field is the
        // section's own enum (`comptime/AGENTS.md` § Enum sections):
        // `Token.Layout(_inner)`, its tag the section's name.
        for (e.sections()) |sec| {
            try members.append(self.b.arena, .{ .method = .{
                .modifier = "static ",
                .name = sec.name,
                .params = try self.b.arena.dupe(js.TsParam, &.{.{
                    .name = "_inner",
                    .type = .{ .name = try std.fmt.allocPrint(self.b.arena, "{s}.{s}", .{ e.name, sec.name }) },
                }}),
                .ret = enum_type,
            } });
        }
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
            if (m.is_declare and !declaresHostMember(m)) continue;
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
        const class: js.TsDecl = .{ .class = .{ .name = try self.genericName(e.name, e.genericParams), .members = try members.toOwnedSlice(self.b.arena) } };
        if (e.sections().len == 0) return class;
        // The sections' types, merged with the class: a signature writes
        // `Token.Layout.Break`, which `tsc` read as a namespace that did not
        // exist. Each section's runtime enum is a class no module exports
        // (`__Token__Layout__Break`), so it is an `interface` here — a type,
        // promising no value.
        return .{ .group = try self.b.arena.dupe(js.TsDecl, &.{ class, .{ .namespace_ = .{
            .name = e.name,
            .items = try self.sectionItems(e.sections()),
        } } }) };
    }

    /// `readonly tag: "A" | "B";` over a variant list and the sections beside
    /// it — `never` for an enum with neither, never an empty `tag: ;`.
    fn tagField(self: *Builder, variants: []const ast.EnumVariant, sections: []const ast.EnumSection) Error!js.TsMember {
        const tags = try self.b.arena.alloc(js.TsType, variants.len + sections.len);
        for (variants, 0..) |v, i| tags[i] = .{ .literal = v.name };
        for (sections, 0..) |sec, i| tags[variants.len + i] = .{ .literal = sec.name };
        return .{ .field = .{
            .modifier = "readonly ",
            .name = "tag",
            .type = if (tags.len == 0) .{ .name = "never" } else .{ .union_ = tags },
        } };
    }

    /// One `interface` per section, and a `namespace` of the same name for
    /// the sections nested in it.
    fn sectionItems(self: *Builder, sections: []const ast.EnumSection) Error![]const js.TsNamespaceItem {
        var items: std.ArrayListUnmanaged(js.TsNamespaceItem) = .empty;
        for (sections) |sec| {
            try items.append(self.b.arena, .{ .interface = .{
                .name = sec.name,
                .members = try self.b.arena.dupe(js.TsMember, &.{try self.tagField(sec.variants, sec.sections)}),
            } });
            if (sec.sections.len > 0) try items.append(self.b.arena, .{ .namespace = .{
                .name = sec.name,
                .items = try self.sectionItems(sec.sections),
            } });
        }
        return items.toOwnedSlice(self.b.arena);
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
            const module = try self.ownerOf(xm, u, imp) orelse continue;
            const already = for (seen_mods.items) |m| {
                if (std.mem.eql(u8, m, module)) break true;
            } else false;
            if (already) continue;
            try seen_mods.append(self.b.arena, module);
            var names: std.ArrayListUnmanaged([]const u8) = .empty;
            for (u.imports) |imp2| {
                if (imp2.activate) continue;
                const module2 = try self.ownerOf(xm, u, imp2) orelse continue;
                if (!std.mem.eql(u8, module2, module)) continue;
                if (!try self.noteImportName(imp2.name())) continue;
                try names.append(self.b.arena, try importSpec(self.b.arena, imp2));
            }
            if (names.items.len == 0) continue;
            try decls.append(self.b.arena, .{ .import = .{
                .names = names.items,
                .source = try std.fmt.allocPrint(self.b.arena, "{s}{s}", .{ prefix, module }),
            } });
        }
        return group(decls.items);
    }

    /// The module whose `.d.ts` declares an imported name: the one the
    /// cross-module index answers for a value, else the one `TypeExport`s
    /// answer for a type-only name, narrowed by the import's source the way
    /// `crossModule.pick` narrows (the module it names, then the package it
    /// names) — two candidates left standing answer null, never the first.
    fn ownerOf(self: *Builder, xm: *const crossModule.CrossModule, u: ast.ImportDecl, imp: ast.ImportPath) Error!?[]const u8 {
        const src = try u.leafSource(imp, self.b.arena, false);
        if (xm.picked(imp.leaf(), src, null)) |info| return info.module;
        var pass: u2 = 0;
        while (true) : (pass += 1) {
            var hit: ?[]const u8 = null;
            var n: usize = 0;
            for (self.type_exports) |te| {
                if (!std.mem.eql(u8, te.name, imp.leaf())) continue;
                if (pass < 2 and !src.admits(te.module, pass)) continue;
                hit = te.module;
                n += 1;
            }
            if (n == 1) return hit;
            if (n > 1 or pass == 2) return null;
        }
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
        for (d.params, 0..) |p, i| ps[i] = .{ .name = p.name, .type = try self.typeRef(p.typeRef), .rest = p.variadic };
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
            try out.append(self.b.arena, .{ .name = p.name, .type = try self.typeRef(p.typeRef), .rest = p.variadic });
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
            "i8",  "i16",  "i32", "i128", "u8",    "u16",
            "u32", "u128", "f32", "f64",  "float",
        };
        for (numbers) |n| if (std.mem.eql(u8, name, n)) return "number";
        if (std.mem.eql(u8, name, "bool")) return "boolean";
        // `string`, `void`, `unknown`, `never` and `any` are spelled the same
        // in both languages and need no row of their own.
        if (std.mem.eql(u8, name, "char")) return "string";
        // The checker's type of a call that never returns (`@panic`).
        if (std.mem.eql(u8, name, "noreturn")) return "never";
        return null;
    }

    /// A type the frontend carries as a name (an interface field, a delegate's
    /// return). A position with no written type is `any`, TypeScript's own
    /// spelling of "not constrained" — never an empty `x: `. A botopink
    /// primitive takes its TypeScript spelling.
    fn namedType(name: []const u8) js.TsType {
        if (name.len == 0) return .{ .name = "any" };
        if (isWideInteger(name)) return wide_integer;
        return .{ .name = primitiveTsName(name) orelse name };
    }

    /// Decision 319 — `i64`, `isize`, `u64` and `usize` cross to JavaScript as
    /// a number within ±(2^53 − 1) and a `BigInt` beyond.
    const wide_integer: js.TsType = .{ .union_ = &.{ .{ .name = "number" }, .{ .name = "bigint" } } };

    fn isWideInteger(name: []const u8) bool {
        const wide = [_][]const u8{ "i64", "u64", "isize", "usize", "int", "uint" };
        for (wide) |w| if (std.mem.eql(u8, name, w)) return true;
        return false;
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
                return self.applied(n.name, args);
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

    /// A written `Name<A, B>`: `Self<…>` is the declaration's own type, the
    /// rest is `applied` over the mapped arguments.
    fn genericTypeRef(self: *Builder, g: anytype) Error!js.TsType {
        if (std.mem.eql(u8, g.name, "Self")) if (self.self_type) |st| return st;
        // `@Decl` with no type arguments is the plain name, never `Decl<>`.
        if (g.args.len == 0) return .{ .name = g.name };
        const args = try self.b.arena.alloc(js.TsType, g.args.len);
        for (g.args, 0..) |a, i| args[i] = try self.typeRef(a);
        return self.applied(g.name, args);
    }

    /// A type constructor applied to arguments already in their TypeScript
    /// spelling — one table for a written type (`TypeRef.generic`) and an
    /// inferred one (`Type.named` with arguments, a `val`'s type), so the two
    /// cannot disagree. The checker names its own constructors in lower case
    /// (`array<T>`, `optional<T>`, `tuple<A, B>`), which no TypeScript
    /// declares; a `pub val sizes = [1, 2, 3]` was typed `array<number>`.
    fn applied(self: *Builder, name: []const u8, args: []const js.TsType) Error!js.TsType {
        // Decision 8 §3's union `A | B` rides on `TypeRef.generic` under the
        // reserved name `ast.union_type_name` (`"|"`), which no source can
        // write. TypeScript spells it the same way botopink does, so it is the
        // model's own `union_` — not `|<A, B>`, which is not TypeScript.
        if (std.mem.eql(u8, name, ast.union_type_name)) return .{ .union_ = args };
        if (std.mem.eql(u8, name, "array") and args.len == 1) return .{ .array = try self.b.typePtr(args[0]) };
        // `?T` is `T | null`.
        if (std.mem.eql(u8, name, "optional") and args.len == 1)
            return .{ .union_ = try self.b.types(&.{ args[0], .{ .name = "null" } }) };
        if (std.mem.eql(u8, name, "tuple")) return .{ .tuple = args };
        // A `@Component` body lowers to an `async function` (decision 104), so
        // its wrapper is a `Promise` of the value: `@Component<R>` →
        // `Promise<R>` (decision 354).
        if (std.mem.eql(u8, name, "Component") and args.len >= 1)
            return .{ .generic = .{ .name = "Promise", .args = try self.b.types(&.{args[0]}) } };
        // `@Result<T, E>` is what the JavaScript builds: `{ ok: v }` or
        // `{ error: e }` (`buildResult`). It used to promise a tagged
        // `{ tag: "Ok"; result: T }` no module ever returned.
        if (std.mem.eql(u8, name, "Result") and args.len == 2) {
            return .{ .union_ = try self.b.types(&.{
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "ok", .type = args[0] },
                }), .sep = "; " } },
                .{ .object = .{ .fields = try self.b.arena.dupe(js.TsField, &.{
                    .{ .name = "error", .type = args[1] },
                }), .sep = "; " } },
            }) };
        }
        // Decisions 120 / 122: `@Task<T>` → `Promise<T>`; `@Iterator<T>` →
        // `IterableIterator<T>`; `@Stream<T>` → `AsyncGenerator<T>`.
        const host: ?[]const u8 =
            if (std.mem.eql(u8, name, "Task")) "Promise" else if (std.mem.eql(u8, name, "Iterator")) "IterableIterator" else if (std.mem.eql(u8, name, "Stream")) "AsyncGenerator" else null;
        if (host) |h| if (args.len >= 1) {
            return .{ .generic = .{ .name = h, .args = try self.b.types(&.{args[0]}) } };
        };
        return .{ .generic = .{ .name = name, .args = args } };
    }
};

/// A host-backed method the `.js` beside this `.d.ts` defines: a bodyless
/// `declare fn` member with an `#[@External.Node(…)]` binding is a real class
/// member there (`commonJS.hostMethodMember`), so it is declared like any other
/// method. One without a `node` binding has no member and no declaration.
fn declaresHostMember(m: ast.BehaviorMethod) bool {
    return hostMethods.isHostMethod(m) and hostMethods.binds(m, .node);
}
