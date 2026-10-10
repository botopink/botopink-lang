//! Decision 307 — a derived type: a compile-time function of std's `Type`
//! answering a NEW record type, bound by a module-level `val` and named after
//! it.
//!
//! ```bp
//! import {types.Type} from "std";
//! pub val RecipeTitle = Type.pick(Recipe, .title);
//! #[validated] pub val RecipePatch = Type.partial(Recipe);
//! pub val AnchorProps = Type.merge(Type.merge(GlobalAttrs, AriaAttrs), AnchorAttrs);
//! ```
//!
//! `Type.partial`, `Type.required`, `Type.pick`, `Type.omit` and `Type.merge`
//! are declared bodyless in `libs/std/src/types.bp`; the bodies are this
//! pass. It runs on the parsed program before the checker and the backends
//! see it (`analyzeSource`, after `nested_types`) and turns each such `val`
//! into the record declaration it answers — `pub type RecipeTitle(title:
//! string)`, the `val`'s annotations, visibility and comments on the type, each
//! field as the source declares it (its annotations — the markers — and its
//! default included). So no checker rule and no backend learns a new node: the
//! derived type is nominal, usable in every type position, constructed,
//! matched, exported and imported, and a decorator on the `val` sees a type
//! declaration.
//!
//! The call is recognised by its receiver: a name the module binds to std's
//! `types.Type` (`import {types.Type} from "std";`, an alias included) — never
//! by the bare function names, so `partial(Recipe)` is an unbound name.
//!
//! The source is a record type of the module, a record type it imports, a
//! type alias of one, another derived `val` of the module (in any order; a
//! cycle is refused) or a nested derivation (`Type.merge(Type.merge(A, B),
//! C)`). Every refusal is located at what it is about:
//!
//! - a field written as a string (`"title"`) — `derived-type-field-string`,
//!   naming `.title`;
//! - a field the source does not declare — the ordinary `Type.Field<T>` error
//!   (`unknown field 'titel' on type 'Recipe'`, decision 280), at the field;
//! - a field named twice, no field for `pick` / `omit`, an `omit` leaving no
//!   field — `derived-type-fields`;
//! - a source that is not a record (an enum, a namespace type, a primitive, a
//!   generic record, a value) — `derived-type-source-not-record`;
//! - a field on both sides of a `merge` — `derived-type-merge-duplicate`, at
//!   the second argument (nothing overrides silently: `omit` it first);
//! - the wrong number of arguments or a labelled one — `derived-type-arguments`;
//! - the call anywhere but as the whole initializer of a module-level `val`
//!   without a type annotation — `derived-type-outside-val`, at the call.
const std = @import("std");
const ast = @import("../ast.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const infer = @import("infer.zig");

const Error = error{OutOfMemory};

/// The five functions of std's `Type` this pass answers. `Type.keys` answers
/// `Type.Field<T>` and is not a record derivation.
const functions = [_][]const u8{ "partial", "required", "pick", "omit", "merge" };

fn isDeriveFn(name: []const u8) bool {
    for (functions) |f| if (std.mem.eql(u8, f, name)) return true;
    return false;
}

/// The program after the rewrite, or the refusal located at what it is about.
pub const Result = union(enum) {
    ok: ast.Program,
    refused: TypeError,
};

/// Finds the declaration an import item names in another module — the type
/// declarations every analysed module exported (`typeDeclRegistry`).
pub const ImportLookup = struct {
    ctx: *const anyopaque,
    find: *const fn (ctx: *const anyopaque, arena: std.mem.Allocator, decl: ast.ImportDecl, item: ast.ImportPath) Error!?ast.DeclKind,
};

/// A source's fields, and the name a diagnostic gives it.
const Record = struct {
    name: []const u8,
    fields: []const ast.Field,
};

/// An imported source's fields as they travel: a default naming a binding of
/// the declaring module cannot be written in this one, so the field travels
/// without it (the rule `registerExports` applies to a parameter's default,
/// `infer.isClosedDefault`) — a construction that omits it is the ordinary
/// missing-field refusal at the call.
fn travelled(arena: std.mem.Allocator, fields: []const ast.Field) Error![]const ast.Field {
    const out = try arena.dupe(ast.Field, fields);
    for (out) |*f| if (f.default) |d| if (!infer.isClosedDefault(d)) {
        f.default = null;
    };
    return out;
}

const Refusal = error{Refused};

/// A plain call node (`receiver.callee(args)`).
const CallNode = @FieldType(@FieldType(@FieldType(ast.Expr, "call"), "kind"), "call");

const Ctx = struct {
    arena: std.mem.Allocator,
    program: ast.Program,
    lookup: ?ImportLookup,
    /// The names this module binds to std's `types.Type`.
    binders: std.StringHashMapUnmanaged(void) = .empty,
    /// The module's derived `val`s, by name (index into `program.decls`).
    derived: std.StringHashMapUnmanaged(usize) = .empty,
    /// Each derived `val`'s answer, once computed.
    done: std.StringHashMapUnmanaged([]const ast.Field) = .empty,
    /// The derived `val`s being computed (a cycle is refused).
    active: std.StringHashMapUnmanaged(void) = .empty,
    refusal: ?TypeError = null,

    fn refuse(self: *Ctx, loc: ast.Loc, comptime fmt: []const u8, args: anytype, hint: ?[]const u8) (Error || Refusal) {
        const msg = std.fmt.allocPrint(self.arena, fmt, args) catch return error.OutOfMemory;
        self.refusal = TypeError.custom(msg, hint).withLoc(loc);
        return error.Refused;
    }

    /// `Type.<fn>(…)` with `Type` bound to std's `types.Type`: the call node.
    fn deriveCall(self: *const Ctx, e: *const ast.Expr) ?CallNode {
        if (e.* != .call or e.call.kind != .call) return null;
        const c = e.call.kind.call;
        if (c.is_builtin or c.calleeExpr != null) return null;
        const recv = c.receiver orelse return null;
        if (recv.* != .identifier or recv.identifier.kind != .ident) return null;
        if (!self.binders.contains(recv.identifier.kind.ident)) return null;
        if (!isDeriveFn(c.callee)) return null;
        return c;
    }

    fn localDecl(self: *const Ctx, name: []const u8) ?ast.DeclKind {
        for (self.program.decls) |d| switch (d) {
            .type_ => |t| if (std.mem.eql(u8, t.name, name)) return d,
            .typeAlias => |a| if (std.mem.eql(u8, a.name, name)) return d,
            else => {},
        };
        return null;
    }

    fn importedDecl(self: *const Ctx, name: []const u8) Error!?ast.DeclKind {
        const lookup = self.lookup orelse return null;
        for (self.program.decls) |d| {
            if (d != .use) continue;
            for (d.use.imports) |imp| {
                if (imp.activate or !std.mem.eql(u8, imp.name(), name)) continue;
                return try lookup.find(lookup.ctx, self.arena, d.use, imp);
            }
        }
        return null;
    }

    /// The record a source argument names.
    fn source(self: *Ctx, fn_name: []const u8, arg: *const ast.Expr, depth: usize) (Error || Refusal)!Record {
        if (self.deriveCall(arg)) |c| {
            return .{ .name = try std.fmt.allocPrint(self.arena, "Type.{s}(…)", .{c.callee}), .fields = try self.derive(c, arg.getLoc()) };
        }
        if (arg.* == .identifier and arg.identifier.kind == .ident) {
            return self.named(fn_name, arg.identifier.kind.ident, arg.getLoc(), depth);
        }
        return self.refuse(arg.getLoc(), "{s}: `Type.{s}` takes a record type here, not a value", .{ diagnostics.derived_type_source_not_record, fn_name }, "Name a record type, a derived type, or a nested `Type.…(…)` call.");
    }

    fn named(self: *Ctx, fn_name: []const u8, name: []const u8, loc: ast.Loc, depth: usize) (Error || Refusal)!Record {
        if (depth > 64) return self.refuse(loc, "{s}: `{s}` aliases itself", .{ diagnostics.derived_type_source_not_record, name }, null);
        if (self.derived.get(name)) |idx| {
            return .{ .name = name, .fields = try self.answer(idx) };
        }
        for (infer.scalar_type_names) |n| if (std.mem.eql(u8, n, name)) {
            return self.refuse(loc, "{s}: `Type.{s}` takes a record type; `{s}` is a primitive type", .{ diagnostics.derived_type_source_not_record, fn_name, name }, null);
        };
        const local = self.localDecl(name);
        const decl = local orelse (try self.importedDecl(name)) orelse
            return self.refuse(loc, "{s}: `Type.{s}` takes a record type; `{s}` is not a type of this module or one it imports", .{ diagnostics.derived_type_source_not_record, fn_name, name }, null);
        switch (decl) {
            // A local alias of a record is that record (an alias is
            // transparent, 118). An imported alias names its target in its own
            // module's scope, which this module's lookup does not see.
            .typeAlias => |a| if (local != null) switch (a.target) {
                .named => |target| if (a.genericParams.len == 0) return self.named(fn_name, target, loc, depth + 1),
                else => {},
            } else return self.refuse(loc, "{s}: `Type.{s}` takes a record type; `{s}` is an imported type alias — import the record it names", .{ diagnostics.derived_type_source_not_record, fn_name, name }, null),
            .type_ => |t| {
                if (t.isRecord() and !t.isNamespace and t.genericParams.len == 0) {
                    return .{ .name = name, .fields = if (local != null) t.recordFields() else try travelled(self.arena, t.recordFields()) };
                }
                const what: []const u8 = if (t.isNamespace) "a namespace type" else if (!t.isRecord()) "an enum" else "a record with type parameters";
                return self.refuse(loc, "{s}: `Type.{s}` takes a record type; `{s}` is {s}", .{ diagnostics.derived_type_source_not_record, fn_name, name, what }, null);
            },
            else => {},
        }
        return self.refuse(loc, "{s}: `Type.{s}` takes a record type; `{s}` is not one", .{ diagnostics.derived_type_source_not_record, fn_name, name }, null);
    }

    /// The fields of the derived `val` at `idx`, computed once.
    fn answer(self: *Ctx, idx: usize) (Error || Refusal)![]const ast.Field {
        const v = self.program.decls[idx].val;
        if (self.done.get(v.name)) |f| return f;
        if (self.active.contains(v.name)) {
            return self.refuse(v.value.getLoc(), "{s}: `{s}` is derived from itself", .{ diagnostics.derived_type_source_not_record, v.name }, null);
        }
        try self.active.put(self.arena, v.name, {});
        const fields = try self.derive(self.deriveCall(v.value).?, v.value.getLoc());
        _ = self.active.remove(v.name);
        try self.done.put(self.arena, v.name, fields);
        return fields;
    }

    /// The `.name` a `pick` / `omit` field argument names.
    fn fieldName(self: *Ctx, arg: *const ast.Expr) (Error || Refusal)![]const u8 {
        switch (arg.*) {
            .identifier => |id| if (id.kind == .dotIdent) return id.kind.dotIdent,
            .literal => |lit| if (lit.kind == .stringLit) {
                return self.refuse(arg.getLoc(), "{s}: a field is named `.{s}`, not the string \"{s}\"", .{ diagnostics.derived_type_field_string, lit.kind.stringLit, lit.kind.stringLit }, "A field of `Type.Field<T>` is written `.name` (decision 308).");
            },
            else => {},
        }
        return self.refuse(arg.getLoc(), "{s}: a field is written `.name`", .{diagnostics.derived_type_fields}, "Name a field of the source type with the `.name` shorthand.");
    }

    fn indexOf(fields: []const ast.Field, name: []const u8) ?usize {
        for (fields, 0..) |f, i| if (std.mem.eql(u8, f.name, name)) return i;
        return null;
    }

    /// The fields one `Type.<fn>(…)` call answers.
    fn derive(self: *Ctx, c: CallNode, loc: ast.Loc) (Error || Refusal)![]const ast.Field {
        const name = c.callee;
        for (c.args) |a| if (a.label) |l| {
            return self.refuse(a.value.getLoc(), "{s}: `Type.{s}` takes no labelled argument (`{s}:`)", .{ diagnostics.derived_type_arguments, name, l }, null);
        };
        if (c.trailing.len > 0) return self.refuse(loc, "{s}: `Type.{s}` takes no trailing lambda", .{ diagnostics.derived_type_arguments, name }, null);
        const want: usize = if (std.mem.eql(u8, name, "merge")) 2 else 1;
        const fieldwise = std.mem.eql(u8, name, "pick") or std.mem.eql(u8, name, "omit");
        if (c.args.len == 0 or (!fieldwise and c.args.len != want)) {
            const sig: []const u8 = if (want == 2) "two record types" else "one record type";
            return self.refuse(loc, "{s}: `Type.{s}` takes {s}, {d} given", .{ diagnostics.derived_type_arguments, name, sig, c.args.len }, null);
        }
        if (fieldwise and c.args.len < 2) {
            return self.refuse(loc, "{s}: `Type.{s}` takes at least one field after the type", .{ diagnostics.derived_type_fields, name }, "Name the fields: `Type.pick(Recipe, .title)`.");
        }

        const src = try self.source(name, c.args[0].value, 0);
        var out: std.ArrayListUnmanaged(ast.Field) = .empty;

        if (std.mem.eql(u8, name, "merge")) {
            const second = try self.source(name, c.args[1].value, 0);
            for (second.fields) |f| if (indexOf(src.fields, f.name) != null) {
                return self.refuse(c.args[1].value.getLoc(), "{s}: field `{s}` is on both sides of `Type.merge({s}, {s})`", .{ diagnostics.derived_type_merge_duplicate, f.name, src.name, second.name }, "Nothing overrides silently: `Type.omit` the field from one side first.");
            };
            try out.appendSlice(self.arena, src.fields);
            try out.appendSlice(self.arena, second.fields);
            return out.toOwnedSlice(self.arena);
        }

        if (fieldwise) {
            const named_fields = c.args[1..];
            const chosen = try self.arena.alloc(bool, src.fields.len);
            @memset(chosen, false);
            for (named_fields) |a| {
                const f = try self.fieldName(a.value);
                const i = indexOf(src.fields, f) orelse {
                    self.refusal = TypeError.unknownField(src.name, f).withLoc(a.value.getLoc());
                    return error.Refused;
                };
                if (chosen[i]) return self.refuse(a.value.getLoc(), "{s}: field `.{s}` is named twice", .{ diagnostics.derived_type_fields, f }, null);
                chosen[i] = true;
            }
            const keep = std.mem.eql(u8, name, "pick");
            for (src.fields, 0..) |f, i| if (chosen[i] == keep) try out.append(self.arena, f);
            if (out.items.len == 0) {
                return self.refuse(loc, "{s}: `Type.omit` leaves `{s}` with no field", .{ diagnostics.derived_type_fields, src.name }, null);
            }
            return out.toOwnedSlice(self.arena);
        }

        // partial / required
        const partial = std.mem.eql(u8, name, "partial");
        for (src.fields) |f| {
            var nf = f;
            if (partial) {
                if (f.typeRef != .optional) {
                    const inner = try self.arena.create(ast.TypeRef);
                    inner.* = f.typeRef;
                    nf.typeRef = .{ .optional = inner };
                }
            } else if (f.typeRef == .optional) {
                nf.typeRef = f.typeRef.optional.*;
                // A `null` default has no place on a field that is no longer
                // optional: the field is required.
                if (f.default) |d| if (d == .literal and d.literal.kind == .null_) {
                    nf.default = null;
                };
            }
            try out.append(self.arena, nf);
        }
        return out.toOwnedSlice(self.arena);
    }

    /// A derivation left anywhere but as a module-level `val`'s initializer.
    fn findStray(self: *Ctx, comptime T: type, ptr: *const T) ?ast.Loc {
        if (T == ast.Expr) if (self.deriveCall(ptr) != null) return ptr.getLoc();
        if (T == ast.ImportDecl or T == ast.TypeRef) return null;
        switch (@typeInfo(T)) {
            .@"struct" => |s| inline for (s.fields) |fld| {
                if (fld.is_comptime) continue;
                if (comptime mayHoldExpr(fld.type)) if (self.findStray(fld.type, &@field(ptr.*, fld.name))) |l| return l;
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        if (self.findStray(@TypeOf(payload.*), payload)) |l| return l;
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| return self.findStray(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) return self.findStray(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*x| if (self.findStray(p.child, x)) |l| return l;
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*x| if (self.findStray(arr.child, x)) |l| return l;
            },
            else => {},
        }
        return null;
    }
};

fn mayHoldExpr(comptime T: type) bool {
    if (T == ast.TypeRef) return false;
    return switch (@typeInfo(T)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}

/// Whether `decl` brings std's `types.Type` into the module, and under which
/// name.
fn stdTypeBinder(arena: std.mem.Allocator, decl: ast.ImportDecl, imp: ast.ImportPath) Error!?[]const u8 {
    if (imp.activate) return null;
    switch (decl.source) {
        .module => |m| if (!std.mem.eql(u8, m, "std")) return null,
        .root, .key => return null,
    }
    if (!std.mem.eql(u8, imp.leaf(), "Type")) return null;
    const src = try decl.leafSource(imp, arena, false);
    return switch (src) {
        .module => |m| if (std.mem.eql(u8, m, "std/types")) imp.name() else null,
        .root, .key => null,
    };
}

/// Rewrite `program` (the arena-owned parse of one module). A program that
/// imports no std `Type` is returned untouched.
pub fn expand(arena: std.mem.Allocator, program: ast.Program, lookup: ?ImportLookup) Error!Result {
    var ctx = Ctx{ .arena = arena, .program = program, .lookup = lookup };
    for (program.decls) |d| {
        if (d != .use) continue;
        for (d.use.imports) |imp| if (try stdTypeBinder(arena, d.use, imp)) |b| try ctx.binders.put(arena, b, {});
    }
    if (ctx.binders.count() == 0) return .{ .ok = program };

    // The module-level `val`s a derivation initialises.
    for (program.decls, 0..) |d, i| {
        if (d != .val or ctx.deriveCall(d.val.value) == null) continue;
        const v = d.val;
        if (v.mutable or v.typeAnnotation != null) {
            return .{ .refused = TypeError.custom(
                try std.fmt.allocPrint(arena, "{s}: a derived type is bound by a module-level `val` with no type annotation — `{s}` is {s}", .{ diagnostics.derived_type_outside_val, v.name, if (v.mutable) "a `var`" else "annotated" }),
                null,
            ).withLoc(v.value.getLoc()) };
        }
        try ctx.derived.put(arena, v.name, i);
    }

    var out = try arena.alloc(ast.DeclKind, program.decls.len);
    for (program.decls, 0..) |d, i| {
        out[i] = d;
        if (d != .val or !ctx.derived.contains(d.val.name)) continue;
        const v = d.val;
        const fields = ctx.answer(i) catch |err| switch (err) {
            error.Refused => return .{ .refused = ctx.refusal.? },
            else => |e| return e,
        };
        out[i] = .{ .type_ = .{
            .name = v.name,
            .isPub = v.isPub,
            .docComment = v.docComment,
            .comment = v.comment,
            .moduleComment = v.moduleComment,
            .annotations = v.annotations,
            .shape = .{ .record = try arena.dupe(ast.Field, fields) },
            .loc = v.nameLoc,
        } };
    }
    const rewritten: ast.Program = .{ .decls = out };
    for (out) |*d| if (ctx.findStray(ast.DeclKind, d)) |loc| {
        return .{ .refused = TypeError.custom(
            try std.fmt.allocPrint(arena, "{s}: a derived type is the whole initializer of a module-level `val`", .{diagnostics.derived_type_outside_val}),
            "Bind it at the module's top level: `pub val RecipeTitle = Type.pick(Recipe, .title);`.",
        ).withLoc(loc) };
    };
    return .{ .ok = rewritten };
}

fn parseProgram(arena: std.mem.Allocator, src: []const u8) !ast.Program {
    const Lexer = @import("../lexer.zig").Lexer;
    const Parser = @import("../parser.zig").Parser;
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    return p.parse(arena);
}

test "derived types: a `val` over `Type.pick` / `Type.partial` / `Type.merge` becomes a record declaration" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const program = try parseProgram(arena,
        \\import {types.Type} from "std";
        \\pub type Recipe(title: string, description: ?string, servings: i32 = 2)
        \\pub type Extra(note: string)
        \\pub val Patch = Type.partial(Brief);
        \\pub val Brief = Type.omit(Recipe, .description);
        \\val Both = Type.merge(Type.pick(Recipe, .title), Extra);
    );
    const out = (try expand(arena, program, null)).ok;
    const patch = out.decls[3].type_;
    try std.testing.expectEqualStrings("Patch", patch.name);
    try std.testing.expect(patch.isPub);
    try std.testing.expectEqual(@as(usize, 2), patch.recordFields().len);
    try std.testing.expect(patch.recordFields()[0].typeRef == .optional);
    try std.testing.expectEqualStrings("servings", patch.recordFields()[1].name);
    const both = out.decls[5].type_;
    try std.testing.expect(!both.isPub);
    try std.testing.expectEqualStrings("title", both.recordFields()[0].name);
    try std.testing.expectEqualStrings("note", both.recordFields()[1].name);
}

test "derived types: a `Type` that is not std's is left alone" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const program = try parseProgram(arena, "type R(a: i32)\nval P = Type.pick(R, .a);");
    const out = (try expand(arena, program, null)).ok;
    try std.testing.expect(out.decls[1] == .val);
}

test "derived types: the refusals are located" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const cases = [_]struct { src: []const u8, line: usize, col: usize }{
        .{ .src = "import {types.Type} from \"std\";\ntype R(a: i32)\nval P = Type.pick(R, \"a\");", .line = 3, .col = 22 },
        .{ .src = "import {types.Type} from \"std\";\ntype R(a: i32)\nval P = Type.pick(R, .b);", .line = 3, .col = 22 },
        .{ .src = "import {types.Type} from \"std\";\ntype R(a: i32)\nval P = Type.merge(R, R);", .line = 3, .col = 23 },
        .{ .src = "import {types.Type} from \"std\";\ntype E { A, B }\nval P = Type.partial(E);", .line = 3, .col = 22 },
        .{ .src = "import {types.Type} from \"std\";\ntype R(a: i32)\nfn f() { val P = Type.partial(R); }", .line = 3, .col = 23 },
        .{ .src = "import {types.Type as T} from \"std\";\ntype R(a: i32)\nval P = T.omit(R, .a);", .line = 3, .col = 11 },
    };
    for (cases) |cs| {
        const r = try expand(arena, try parseProgram(arena, cs.src), null);
        try std.testing.expect(r == .refused);
        try std.testing.expectEqual(cs.line, r.refused.loc.?.line);
        try std.testing.expectEqual(cs.col, r.refused.loc.?.col);
    }
}
