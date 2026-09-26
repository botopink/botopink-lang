/// Snapshot infrastructure for comptime AST tests.
///
/// Converts typed bindings to structured JSON representations and builds
/// multi-section snapshot content for assertion:
///   ----- SOURCE CODE -- name.bp
///   ----- COMPTIME ERLANG / COMPTIME REPLY -- <kind> <fn>  (per decorator/template evaluation)
///   ----- COMPTIME VALUES -- name  (if comptime expressions exist)
///   ----- BOTOPINK TRANSFORM CODE -- name.bp  (if comptime expressions exist)
///   ----- TYPED AST JSON -- name.json
const std = @import("std");
const snapMod = @import("../utils/snap.zig");
const format = @import("../format.zig");
const T = @import("./types.zig");
const ast = @import("../ast.zig");
const inferMod = @import("infer.zig");
const comptimeMod = @import("../comptime.zig");
const errorMod = @import("./error.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");

// ── JSON representation types ─────────────────────────────────────────────────

/// A single parameter in a function signature.
const Param = struct {
    name: []const u8,
    type: []const u8,
    is_comptime: ?bool = null,
};

/// A string→string map serialized as a JSON object.
const FieldMap = struct {
    const Entry = struct { name: []const u8, value: []const u8 };
    entries: []const Entry,

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();
        for (self.entries) |e| {
            try jws.objectField(e.name);
            try jws.write(e.value);
        }
        try jws.endObject();
    }
};

/// A source line extracted from a function body.
const FnBodyLine = struct {
    source: []const u8,
};

/// A use-declaration inside a `use` statement.
const UseDeclaration = struct {
    ast: []const u8,
    ident: []const u8,
    return_type: []const u8,

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("ast");
        try jws.write(self.ast);
        try jws.objectField("ident");
        try jws.write(self.ident);
        try jws.objectField("return_type");
        try jws.write(self.return_type);
        try jws.endObject();
    }
};

/// A method signature inside a `type`, `behavior` or `implement` body. Methods
/// are not bindings, so — like a record field — the types are the annotations
/// the declaration wrote.
const MethodSig = struct {
    name: []const u8,
    /// `UsbCharger.Conectar` in an implement block; null for a plain method.
    qualifier: ?[]const u8 = null,
    is_pub: ?bool = null,
    /// `default fn` in a behavior body.
    is_default: ?bool = null,
    /// `declare fn` — a bodyless slot typed from its signature.
    is_declare: ?bool = null,
    generic_params: ?[]const []const u8 = null,
    params: []const Param,
    /// Absent for an `implement` method: the AST carries no return annotation
    /// there, and the signature it satisfies is the behavior's. Printing `void`
    /// would be a claim the declaration never made.
    return_type: ?[]const u8 = null,
};

/// One variant of an enum. `fields` is absent for a unit variant.
const VariantRepr = struct {
    name: []const u8,
    fields: ?FieldMap = null,
};

/// A named grouping of variants inside an enum body; sections nest.
const SectionRepr = struct {
    name: []const u8,
    variants: ?[]const VariantRepr = null,
    sections: ?[]const SectionRepr = null,
};

/// A call argument in a constructor or function call.
const CallParam = struct {
    name: ?[]const u8,
    value: []const u8,
};

/// A call expression inside a `val` binding.
const CallExpr = struct {
    ast: []const u8,
    params: []const CallParam,
    return_type: []const u8,
};

/// A statement inside a `case` block arm body.
const StmtType = struct {
    return_type: []const u8,
};

/// One arm of a `case` expression.
/// `ast` is `"value"` for simple expression arms or `"block"` for lambda arms.
const CaseArm = struct {
    ast: []const u8,
    body: ?[]const StmtType,
    return_type: []const u8,
};

/// Full JSON representation of a `val x = case … { … }` binding.
const CaseExpr = struct {
    ast: []const u8,
    param: []const u8,
    match: []const CaseArm,
    return_type: []const u8,
};

/// Full JSON representation of a `use {a, b} from "module"` statement.
const UseExpr = struct {
    ast: []const u8,
    declarations: []const UseDeclaration,
};

/// Tagged union over all binding values — serialized via `jsonStringify`.
const BindingRepr = union(enum) {
    val: struct {
        ast: []const u8,
        ident: []const u8,
        expr: ?CallExpr,
        return_type: []const u8,

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("ast");
            try jws.write(self.ast);
            try jws.objectField("ident");
            try jws.write(self.ident);
            try jws.objectField("return_type");
            try jws.write(self.return_type);
            if (self.expr) |expr| {
                try jws.objectField("expr");
                try jws.write(expr);
            }
            try jws.endObject();
        }
    },
    use: struct {
        ast: []const u8,
        declarations: []const UseDeclaration,

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("ast");
            try jws.write(self.ast);
            try jws.objectField("declarations");
            try jws.write(self.declarations);
            try jws.endObject();
        }
    },
    case: struct {
        ast: []const u8,
        param: []const u8,
        match: []const CaseArm,
        return_type: []const u8,
    },
    fn_: struct {
        ast: []const u8,
        name: []const u8,
        is_pub: bool,
        generic_params: ?[]const []const u8,
        params: []const Param,
        return_type: []const u8,
        body: []const FnBodyLine,
    },
    // `id` used to be rendered here and was `0` in every snapshot that carried
    // it — decision 19 of 1.0.5-beta removed the field. See `bindingToRepr`.
    struct_: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8,
        fields: FieldMap,
        methods: ?[]const MethodSig = null,
    },
    record: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8,
        implements: ?[]const []const u8 = null,
        fields: FieldMap,
        methods: ?[]const MethodSig = null,
    },
    enum_: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8,
        implements: ?[]const []const u8 = null,
        variants: ?[]const VariantRepr = null,
        sections: ?[]const SectionRepr = null,
        methods: ?[]const MethodSig = null,
    },
    interface: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8,
        extends: ?[]const []const u8 = null,
        fields: ?FieldMap = null,
        methods: ?[]const MethodSig = null,
    },
    implement: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8 = null,
        interfaces: []const []const u8,
        target: []const u8,
        methods: ?[]const MethodSig = null,
    },
    other: struct {
        ast: []const u8,
    },

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        switch (self) {
            inline else => |inner| try jws.write(inner),
        }
    }
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extract the text of a specific line (1-based) from source, trimmed.
fn extractLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return trimWhitespace(src[start..end]);
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return trimWhitespace(src[start..]);
}

fn trimWhitespace(s: []const u8) []const u8 {
    var end = s.len;
    while (end > 0 and std.ascii.isWhitespace(s[end - 1])) end -= 1;
    var start: usize = 0;
    while (start < end and std.ascii.isWhitespace(s[start])) start += 1;
    return s[start..end];
}

fn genericNames(allocator: std.mem.Allocator, params: anytype) ![]const []const u8 {
    var gens: std.ArrayList([]const u8) = .empty;
    defer gens.deinit(allocator);
    for (params) |gp| try gens.append(allocator, gp.name);
    return allocator.dupe([]const u8, gens.items);
}

/// The parameter list of a declared method signature, annotations as written.
fn methodParams(allocator: std.mem.Allocator, params: []const ast.Param) ![]const Param {
    var out: std.ArrayList(Param) = .empty;
    defer out.deinit(allocator);
    for (params) |p| {
        try out.append(allocator, .{
            .name = p.name,
            .type = try typeRefName(allocator, p.typeRef),
            .is_comptime = if (p.modifier == .@"comptime") true else null,
        });
    }
    return allocator.dupe(Param, out.items);
}

/// The methods declared in a `type` or `behavior` body, `declare fn` slots
/// included — an abstract member is exactly what a reader of a behavior needs.
fn behaviorMethods(
    allocator: std.mem.Allocator,
    methods: []const ast.BehaviorMethod,
) !?[]const MethodSig {
    if (methods.len == 0) return null;
    var out: std.ArrayList(MethodSig) = .empty;
    defer out.deinit(allocator);
    for (methods) |m| {
        const gens = try genericNames(allocator, m.genericParams);
        try out.append(allocator, .{
            .name = m.name,
            .is_pub = if (m.isPub) true else null,
            .is_default = if (m.is_default) true else null,
            .is_declare = if (m.is_declare) true else null,
            .generic_params = if (gens.len > 0) gens else null,
            .params = try methodParams(allocator, m.params),
            .return_type = if (m.returnType) |rt| try typeRefName(allocator, rt) else "void",
        });
    }
    return try allocator.dupe(MethodSig, out.items);
}

/// The methods of an `implement` block. They carry no return annotation in the
/// AST — the signature they satisfy is the behavior's.
fn implementMethods(
    allocator: std.mem.Allocator,
    methods: []const ast.ImplementMethod,
) !?[]const MethodSig {
    if (methods.len == 0) return null;
    var out: std.ArrayList(MethodSig) = .empty;
    defer out.deinit(allocator);
    for (methods) |m| {
        try out.append(allocator, .{
            .name = m.name,
            .qualifier = m.qualifier,
            .params = try methodParams(allocator, m.params),
        });
    }
    return try allocator.dupe(MethodSig, out.items);
}

fn variantReprs(
    allocator: std.mem.Allocator,
    variants: []const ast.EnumVariant,
) !?[]const VariantRepr {
    if (variants.len == 0) return null;
    var out: std.ArrayList(VariantRepr) = .empty;
    defer out.deinit(allocator);
    for (variants) |v| {
        var entries: std.ArrayList(FieldMap.Entry) = .empty;
        defer entries.deinit(allocator);
        for (v.fields) |fld| {
            try entries.append(allocator, .{ .name = fld.name, .value = try typeRefName(allocator, fld.typeRef) });
        }
        try out.append(allocator, .{
            .name = v.name,
            .fields = if (entries.items.len > 0)
                FieldMap{ .entries = try allocator.dupe(FieldMap.Entry, entries.items) }
            else
                null,
        });
    }
    return try allocator.dupe(VariantRepr, out.items);
}

fn sectionReprs(
    allocator: std.mem.Allocator,
    sections: []const ast.EnumSection,
) std.mem.Allocator.Error!?[]const SectionRepr {
    if (sections.len == 0) return null;
    var out: std.ArrayList(SectionRepr) = .empty;
    defer out.deinit(allocator);
    for (sections) |s| {
        try out.append(allocator, .{
            .name = s.name,
            .variants = try variantReprs(allocator, s.variants),
            .sections = try sectionReprs(allocator, s.sections),
        });
    }
    return try allocator.dupe(SectionRepr, out.items);
}

/// An `implement` block, which `inferProgram` returns no binding for — it is
/// read straight off the program instead.
fn implementToRepr(
    allocator: std.mem.Allocator,
    im: ast.ImplementDecl,
) !BindingRepr {
    const gens = try genericNames(allocator, im.genericParams);
    return .{ .implement = .{
        .ast = "implement_def",
        .name = im.name,
        .generic = if (gens.len > 0) gens else null,
        .interfaces = (try interfaceNames(allocator, im.interfaces)) orelse &.{},
        .target = im.target,
        .methods = try implementMethods(allocator, im.methods),
    } };
}

/// The behavior names an inline `record(…) implement I1, I2 { }` lists.
fn interfaceNames(allocator: std.mem.Allocator, refs: []const ast.TypeRef) !?[]const []const u8 {
    if (refs.len == 0) return null;
    var out: std.ArrayList([]const u8) = .empty;
    defer out.deinit(allocator);
    for (refs) |ref| try out.append(allocator, try typeRefName(allocator, ref));
    return try allocator.dupe([]const u8, out.items);
}

/// Display names for the `.generic` type variables of one rendered declaration.
///
/// A `T.TypeId` is allocation order over the whole environment, so printing the
/// id itself would re-record every polymorphic snapshot whenever an unrelated
/// type is added upstream. `bind` names a variable after the type parameter the
/// declaration wrote for it — matched through the annotation, never guessed by
/// position — and anything left unbound falls back to `'a`, `'b`, … by first
/// appearance.
const GenericNamer = struct {
    const Entry = struct { id: T.TypeId, name: []const u8 };

    allocator: std.mem.Allocator,
    entries: std.ArrayListUnmanaged(Entry) = .empty,

    fn deinit(self: *GenericNamer) void {
        self.entries.deinit(self.allocator);
    }

    fn find(self: *GenericNamer, id: T.TypeId) ?[]const u8 {
        for (self.entries.items) |e| {
            if (e.id == id) return e.name;
        }
        return null;
    }

    /// Name `id` after a declared type parameter. The first binding wins, so a
    /// parameter list read left to right decides.
    fn bind(self: *GenericNamer, id: T.TypeId, name: []const u8) std.mem.Allocator.Error!void {
        if (self.find(id) != null) return;
        try self.entries.append(self.allocator, .{ .id = id, .name = name });
    }

    fn nameFor(self: *GenericNamer, id: T.TypeId) std.mem.Allocator.Error![]const u8 {
        if (self.find(id)) |name| return self.allocator.dupe(u8, name);
        const index = self.entries.items.len;
        const name = if (index < 26)
            try std.fmt.allocPrint(self.allocator, "'{c}", .{'a' + @as(u8, @intCast(index))})
        else
            try std.fmt.allocPrint(self.allocator, "'t{d}", .{index});
        try self.entries.append(self.allocator, .{ .id = id, .name = name });
        return self.allocator.dupe(u8, name);
    }
};

/// Pair a declared type parameter with the type variable inference gave it, so
/// `fn identity<T>(x: T) -> T` renders `T` and not `'a`. Only an annotation
/// that names a type parameter of this declaration binds anything.
fn bindGenericNames(
    namer: *GenericNamer,
    generic_params: []const ast.GenericParam,
    annotation: ast.TypeRef,
    inferred: *T.Type,
) std.mem.Allocator.Error!void {
    if (generic_params.len == 0) return;
    if (annotation != .named) return;
    const declared = annotation.named;
    var matches = false;
    for (generic_params) |gp| {
        if (std.mem.eql(u8, gp.name, declared)) {
            matches = true;
            break;
        }
    }
    if (!matches) return;
    switch (inferred.deref().*) {
        .typeVar => |cell| switch (cell.state) {
            .generic => |id| try namer.bind(id, declared),
            else => {},
        },
        else => {},
    }
}

/// How `typeNameIn` spells a type out.
///
/// `.diagnostic` is what the error renderers have always printed and what the
/// `comptime/errors/` and `codegen/**/errors/` snapshots record — it is frozen.
/// `.ast` is the `TYPED AST JSON` rendering: it spells a function type out
/// instead of collapsing it to its return type, and separates a generic
/// variable (a correct polymorphic answer, named by `namer`) from an unbound
/// one (the checker punting, still `?`).
const TypeRender = struct {
    const Mode = enum { diagnostic, ast };

    mode: Mode = .diagnostic,
    namer: ?*GenericNamer = null,
};

/// Render a syntactic type annotation. Used only where inference has nothing to
/// add because the annotation *is* the type: a record field, whose declared
/// `TypeRef` is what `infer.zig` `buildRecordDeclName` itself renders into the
/// binding's type name. Mirrors that builder's text.
fn appendTypeRefName(
    buf: *std.ArrayListUnmanaged(u8),
    allocator: std.mem.Allocator,
    tr: ast.TypeRef,
) std.mem.Allocator.Error!void {
    switch (tr) {
        .named => |n| try buf.appendSlice(allocator, n),
        .array => |elem| {
            try appendTypeRefName(buf, allocator, elem.*);
            try buf.appendSlice(allocator, "[]");
        },
        .tuple_ => |elems| {
            try buf.appendSlice(allocator, "#(");
            for (elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefName(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .labeledTuple => |lt| {
            try buf.appendSlice(allocator, "#(");
            for (lt.elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try buf.appendSlice(allocator, lt.labels[i]);
                try buf.appendSlice(allocator, ": ");
                try appendTypeRefName(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .optional => |inner| {
            try buf.append(allocator, '?');
            try appendTypeRefName(buf, allocator, inner.*);
        },
        .function => |f| {
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefName(buf, allocator, p);
            }
            try buf.appendSlice(allocator, ") -> ");
            try appendTypeRefName(buf, allocator, f.returnType.*);
        },
        .generic => |g| {
            if (g.is_builtin) try buf.append(allocator, '@');
            try buf.appendSlice(allocator, g.name);
            try buf.append(allocator, '<');
            for (g.args, 0..) |a, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefName(buf, allocator, a);
            }
            try buf.append(allocator, '>');
        },
        .typeparam => |constraints| {
            try buf.appendSlice(allocator, "typeparam");
            for (constraints, 0..) |c, i| {
                try buf.appendSlice(allocator, if (i == 0) " " else " | ");
                try appendTypeRefName(buf, allocator, c);
            }
        },
    }
}

fn typeRefName(allocator: std.mem.Allocator, tr: ast.TypeRef) std.mem.Allocator.Error![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);
    try appendTypeRefName(&buf, allocator, tr);
    return buf.toOwnedSlice(allocator);
}

fn extractFnBody(
    allocator: std.mem.Allocator,
    src: []const u8,
    stmts: []const ast.Stmt,
) ![]FnBodyLine {
    var body: std.ArrayList(FnBodyLine) = .empty;
    defer body.deinit(allocator);
    for (stmts) |stmt| {
        try body.append(allocator, .{ .source = extractLine(src, getExprLoc(stmt.expr).line) });
    }
    return body.toOwnedSlice(allocator);
}

fn buildCaseExpr(allocator: std.mem.Allocator, expr: ast.TypedExpr, render: TypeRender) !CaseExpr {
    const case_ = expr.collection.kind.case;
    var arms: std.ArrayList(CaseArm) = .empty;
    defer arms.deinit(allocator);
    for (case_.arms) |arm| {
        try arms.append(allocator, try buildCaseArm(allocator, arm.body, render));
    }
    return CaseExpr{
        .ast = "case",
        .param = if (case_.subjects.len > 0) try typeNameIn(allocator, getTypedExprType(case_.subjects[0]), render) else "unknown",
        .match = try allocator.dupe(CaseArm, arms.items),
        .return_type = try typeNameIn(allocator, getTypedExprType(expr), render),
    };
}

fn buildCallExpr(allocator: std.mem.Allocator, expr: ast.TypedExpr, render: TypeRender) !CallExpr {
    const call_ = expr.call.kind.call;
    var params: std.ArrayList(CallParam) = .empty;
    defer params.deinit(allocator);
    for (call_.args) |arg| {
        try params.append(allocator, .{
            .name = arg.label,
            .value = try typeNameIn(allocator, getTypedExprType(arg.value.*), render),
        });
    }
    return CallExpr{
        .ast = "call",
        .params = try params.toOwnedSlice(allocator),
        .return_type = try typeNameIn(allocator, getTypedExprType(expr), render),
    };
}

/// Get the type from a TypedExpr based on its category
fn getTypedExprType(expr: ast.TypedExpr) *T.Type {
    return switch (expr) {
        .literal => |e| e.type_,
        .identifier => |e| e.type_,
        .binaryOp => |e| e.type_,
        .unaryOp => |e| e.type_,
        .jump => |e| e.type_,
        .branch => |e| e.type_,
        .loop => |e| e.type_,
        .binding => |e| e.type_,
        .useHook => |e| e.type_,
        .call => |e| e.type_,
        .function => |e| e.type_,
        .collection => |e| e.type_,
        .comptime_ => |e| e.type_,
    };
}

/// Get the location from a TypedExpr based on its category
fn getTypedExprLoc(expr: ast.TypedExpr) ast.Loc {
    return switch (expr) {
        .literal => |e| e.loc,
        .identifier => |e| e.loc,
        .binaryOp => |e| e.loc,
        .unaryOp => |e| e.loc,
        .jump => |e| e.loc,
        .branch => |e| e.loc,
        .loop => |e| e.loc,
        .binding => |e| e.loc,
        .useHook => |e| e.loc,
        .call => |e| e.loc,
        .function => |e| e.loc,
        .collection => |e| e.loc,
        .comptime_ => |e| e.loc,
    };
}

/// Get the location from an Expr based on its category
fn getExprLoc(expr: ast.Expr) ast.Loc {
    return switch (expr) {
        .literal => |e| e.loc,
        .identifier => |e| e.loc,
        .binaryOp => |e| e.loc,
        .unaryOp => |e| e.loc,
        .jump => |e| e.loc,
        .branch => |e| e.loc,
        .loop => |e| e.loc,
        .binding => |e| e.loc,
        .useHook => |e| e.loc,
        .call => |e| e.loc,
        .function => |e| e.loc,
        .collection => |e| e.loc,
        .comptime_ => |e| e.loc,
    };
}

fn buildCaseArm(allocator: std.mem.Allocator, body: ast.TypedExpr, render: TypeRender) !CaseArm {
    if (body == .function) {
        const fk = body.function.kind;
        if (fk.syntax == .lambda and fk.params.len == 0) {
            var items: std.ArrayList(StmtType) = .empty;
            defer items.deinit(allocator);
            for (fk.body) |stmt| {
                const stmt_type = getTypedExprType(stmt.expr);
                try items.append(allocator, .{ .return_type = try typeNameIn(allocator, stmt_type, render) });
            }
            // A block arm is a zero-parameter lambda the case calls at once, so
            // the arm's type is what that lambda returns, not `fn() -> …`.
            const arm_type = body.getType().deref();
            const value_type = if (arm_type.* == .func) arm_type.func.ret else body.getType();
            return CaseArm{
                .ast = "block",
                .body = try allocator.dupe(StmtType, items.items),
                .return_type = try typeNameIn(allocator, value_type, render),
            };
        }
    }
    return CaseArm{ .ast = "value", .body = null, .return_type = try typeNameIn(allocator, body.getType(), render) };
}

fn bindingToRepr(
    allocator: std.mem.Allocator,
    b: inferMod.TypedBinding,
    src: []const u8,
) !?BindingRepr {
    // `'a`, `'b` run per declaration, so one polymorphic signature reads the
    // same whatever else the module declares.
    var namer = GenericNamer{ .allocator = allocator };
    const render = TypeRender{ .mode = .ast, .namer = &namer };
    // Deliberately not rendered here: the first render of a declaration is what
    // fixes its `'a`, `'b`, and the `fn` arm binds the declared type-parameter
    // names before anything is spelled out.

    return switch (b.decl) {
        .use => {
            // Create a slice with a single use-declaration for this binding
            const decls = try allocator.alloc(UseDeclaration, 1);
            decls[0] = .{
                .ast = "use-declaration",
                .ident = b.name,
                .return_type = try typeNameIn(allocator, b.type_, render),
            };

            return .{ .use = .{
                .ast = "use",
                .declarations = decls,
            } };
        },
        .val => blk: {
            // The binding's own type first, so a `'a` in it is the first one.
            const typeStr = try typeNameIn(allocator, b.type_, render);
            if (b.typedExpr) |te| {
                if (te == .collection and te.collection.kind == .case) {
                    const caseExpr = try buildCaseExpr(allocator, te, render);
                    break :blk .{ .case = .{
                        .ast = caseExpr.ast,
                        .param = caseExpr.param,
                        .match = caseExpr.match,
                        .return_type = caseExpr.return_type,
                    } };
                }
                if (te == .call) {
                    break :blk .{ .val = .{
                        .ast = "val",
                        .ident = b.name,
                        .expr = try buildCallExpr(allocator, te, render),
                        .return_type = typeStr,
                    } };
                }
            }
            break :blk .{ .val = .{ .ast = "val", .ident = b.name, .expr = null, .return_type = typeStr } };
        },

        .@"fn" => |f| blk: {
            // The signature comes from the binding's inferred `.func` type, so
            // an unannotated parameter or return shows what inference worked
            // out rather than the `?` an absent annotation used to print. The
            // declared `TypeRef` is the fallback for a binding inference never
            // gave a function type (a declaration that did not type-check).
            const inferred = b.type_.deref();
            const fn_type = if (inferred.* == .func) inferred.func else null;

            // Name the polymorphic variables after the type parameters this
            // declaration wrote, before anything is rendered.
            if (fn_type) |ft| {
                for (f.params, 0..) |p, i| {
                    if (i >= ft.params.len) break;
                    try bindGenericNames(&namer, f.genericParams, p.typeRef, ft.params[i]);
                }
                if (f.returnType) |rt| try bindGenericNames(&namer, f.genericParams, rt, ft.ret);
            }

            var params: std.ArrayList(Param) = .empty;
            for (f.params, 0..) |p, i| {
                const from_inference = if (fn_type) |ft|
                    (if (i < ft.params.len) try typeNameIn(allocator, ft.params[i], render) else null)
                else
                    null;
                try params.append(allocator, .{
                    .name = p.name,
                    .type = from_inference orelse try typeRefName(allocator, p.typeRef),
                    .is_comptime = if (p.modifier == .@"comptime") true else null,
                });
            }
            const gens = try genericNames(allocator, f.genericParams);
            break :blk .{ .fn_ = .{
                .ast = "fn_def",
                .name = b.name,
                .is_pub = f.isPub,
                .generic_params = if (gens.len > 0) gens else null,
                .params = try params.toOwnedSlice(allocator),
                .return_type = if (fn_type) |ft|
                    try typeNameIn(allocator, ft.ret, render)
                else if (f.returnType) |rt|
                    try typeRefName(allocator, rt)
                else
                    "void",
                .body = try extractFnBody(allocator, src, f.body),
            } };
        },

        .type_ => |r| if (r.isRecord()) blk: {
            var entries: std.ArrayList(FieldMap.Entry) = .empty;
            for (r.recordFields()) |fld| {
                // A record field is always annotated, and `buildRecordDeclName`
                // renders that same annotation into the binding's type name —
                // inference has nothing here the declaration does not say.
                try entries.append(allocator, .{ .name = fld.name, .value = try typeRefName(allocator, fld.typeRef) });
            }
            const gens = try genericNames(allocator, r.genericParams);
            break :blk .{ .record = .{
                .ast = "record_def",
                .name = b.name,
                .generic = if (gens.len > 0) gens else null,
                .implements = try interfaceNames(allocator, r.implement),
                .fields = .{ .entries = try entries.toOwnedSlice(allocator) },
                .methods = try behaviorMethods(allocator, r.methods),
            } };
        } else blk: {
            const e = r;
            const gens = try genericNames(allocator, e.genericParams);
            break :blk .{ .enum_ = .{
                .ast = "enum_def",
                .name = b.name,
                .generic = if (gens.len > 0) gens else null,
                .implements = try interfaceNames(allocator, e.implement),
                .variants = try variantReprs(allocator, e.variants()),
                .sections = try sectionReprs(allocator, e.sections()),
                .methods = try behaviorMethods(allocator, e.methods),
            } };
        },

        .behavior => |i| blk: {
            const gens = try genericNames(allocator, i.genericParams);
            var entries: std.ArrayList(FieldMap.Entry) = .empty;
            defer entries.deinit(allocator);
            for (i.fields) |fld| {
                try entries.append(allocator, .{ .name = fld.name, .value = fld.typeName });
            }
            break :blk .{ .interface = .{
                .ast = "interface_def",
                .name = b.name,
                .generic = if (gens.len > 0) gens else null,
                .extends = if (i.extends.len > 0) i.extends else null,
                .fields = if (entries.items.len > 0)
                    FieldMap{ .entries = try allocator.dupe(FieldMap.Entry, entries.items) }
                else
                    null,
                .methods = try behaviorMethods(allocator, i.methods),
            } };
        },

        else => .{ .other = .{ .ast = @tagName(b.decl) } },
    };
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Return the string representation of an **inferred** type (allocated, caller
/// owns), in the frozen `.diagnostic` spelling the error renderers print.
pub fn typeNameOf(allocator: std.mem.Allocator, ty: *T.Type) std.mem.Allocator.Error![]const u8 {
    return typeNameIn(allocator, ty, .{});
}

/// `typeNameOf` with the rendering picked by the caller — see `TypeRender`.
fn typeNameIn(
    allocator: std.mem.Allocator,
    ty: *T.Type,
    render: TypeRender,
) std.mem.Allocator.Error![]const u8 {
    return switch (ty.deref().*) {
        .named => |n| {
            if (n.args.len == 0) return allocator.dupe(u8, n.name);
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            if (std.mem.eql(u8, n.name, "array") and n.args.len == 1) {
                const elem = try typeNameIn(allocator, n.args[0], render);
                defer allocator.free(elem);
                return std.fmt.allocPrint(allocator, "{s}[]", .{elem});
            }
            // Source syntax for the optional, the way `array<T>` above is
            // already written `T[]`. The AST dump only: the diagnostics have
            // always said `optional<T>` and their snapshots are frozen.
            if (render.mode == .ast and std.mem.eql(u8, n.name, "optional") and n.args.len == 1) {
                const inner = try typeNameIn(allocator, n.args[0], render);
                // An optional of a type inference has not worked out keeps the
                // long form: `??` would read as two unrelated question marks.
                if (!std.mem.eql(u8, inner, "?")) {
                    defer allocator.free(inner);
                    return std.fmt.allocPrint(allocator, "?{s}", .{inner});
                }
                allocator.free(inner);
            }
            if (std.mem.eql(u8, n.name, "tuple")) {
                try buf.appendSlice(allocator, "#(");
                for (n.args, 0..) |arg, i| {
                    if (i > 0) try buf.append(allocator, ',');
                    const arg_name = try typeNameIn(allocator, arg, render);
                    defer allocator.free(arg_name);
                    try buf.appendSlice(allocator, arg_name);
                }
                try buf.append(allocator, ')');
                return buf.toOwnedSlice(allocator);
            }
            try buf.appendSlice(allocator, n.name);
            try buf.append(allocator, '<');
            for (n.args, 0..) |arg, i| {
                if (i > 0) try buf.append(allocator, ',');
                const arg_name = try typeNameIn(allocator, arg, render);
                defer allocator.free(arg_name);
                try buf.appendSlice(allocator, arg_name);
            }
            try buf.append(allocator, '>');
            return buf.toOwnedSlice(allocator);
        },
        .func => |f| {
            // A diagnostic has always named the return type alone. The AST
            // dump spells the signature out, so a `val` bound to a function
            // stops reading as a value of its return type.
            if (render.mode == .diagnostic) return typeNameIn(allocator, f.ret, render);
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                const p_name = try typeNameIn(allocator, p, render);
                defer allocator.free(p_name);
                try buf.appendSlice(allocator, p_name);
            }
            try buf.appendSlice(allocator, ") -> ");
            const ret_name = try typeNameIn(allocator, f.ret, render);
            defer allocator.free(ret_name);
            try buf.appendSlice(allocator, ret_name);
            return buf.toOwnedSlice(allocator);
        },
        // `deref` already followed every `.link`, so the cell left here is
        // either `.unbound` or `.generic`. A diagnostic prints `?` for both.
        // The AST dump keeps `?` for `.unbound` only — that is the one place a
        // snapshot shows the checker saying it does not know, and nothing else
        // may be allowed to read like it.
        .typeVar => |cell| {
            if (render.mode == .diagnostic) return allocator.dupe(u8, "?");
            return switch (cell.state) {
                .generic => |id| if (render.namer) |namer|
                    namer.nameFor(id)
                else
                    allocator.dupe(u8, "'_"),
                else => allocator.dupe(u8, "?"),
            };
        },
        .record => |fields| {
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            try buf.appendSlice(allocator, "record { ");
            for (fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try buf.appendSlice(allocator, f.name);
                try buf.appendSlice(allocator, ": ");
                const fieldName = try typeNameIn(allocator, f.type_, render);
                defer allocator.free(fieldName);
                try buf.appendSlice(allocator, fieldName);
            }
            try buf.appendSlice(allocator, " }");
            return buf.toOwnedSlice(allocator);
        },
        .union_ => |types| {
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            for (types, 0..) |t, i| {
                if (i > 0) try buf.appendSlice(allocator, " | ");
                const type_name = try typeNameIn(allocator, t, render);
                defer allocator.free(type_name);
                try buf.appendSlice(allocator, type_name);
            }
            return buf.toOwnedSlice(allocator);
        },
    };
}

// ── Compile diagnostics (spec 06, H3/H9) ──────────────────────────────────────
//
// A module that does not parse or does not type-check never reaches codegen.
// The snapshot used to record nothing for it, so the test compared an empty
// (or source-only) file with itself and passed. Both snapshot writers now emit
// a `COMPILE DIAGNOSTIC` section instead, and the test harnesses turn the
// non-`ok` outcome into a failure unless the test opted into it.

/// Returns the source line numbered `line` (1-based), without its terminator.
pub fn getSourceLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return src[start..end];
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return src[start..];
}

/// The `error: …` body of a type-error diagnostic (title, location box and
/// per-kind detail). `comptime/tests/helpers.zig` prefixes it with the
/// `----- SOURCE CODE` / `----- ERROR` headers the `errors/` snapshots use;
/// the compile-diagnostic sections embed it directly.
pub fn renderTypeErrorBody(
    allocator: std.mem.Allocator,
    src: []const u8,
    err: errorMod.TypeError,
) ![]u8 {
    // Use an arena so intermediate allocPrint strings are freed together.
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const tmp = arena.allocator();

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // Error title
    const title = switch (err.kind) {
        .typeMismatch => "type mismatch",
        .unboundVariable => "unbound variable",
        .arityMismatch => "arity mismatch",
        .unknownField => "unknown field",
        .notARecord => "not a record type",
        .recursiveType => "recursive type",
        .unknownTypeName => "unknown type",
        .missingField => "missing field",
        .methodNotActive => "method not active",
        .ambiguousExtension => "ambiguous extension method",
        .notAnExtension => "not an extension symbol",
        .extendRequiresInterface => "extend requires a behavior",
        .redundantActivation => "redundant activation",
        .useNotAllowed => "use-of-non-context-fn: `use` not allowed",
        .useNotContext => "use-of-non-context-fn: `use` takes a hook",
        .contextMismatch => "context-anchor-violation: ContextBase mismatch",
        .contextBaseMixed => "context-anchor-violation: two ContextBases in one body",
        .useWithoutContextEffect => "use-without-context-effect: `use` needs a `-> @Component<C, T>` return on the enclosing fn",
        .useTupleArity => "use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements",
        .throwWithoutResult => "throw outside @Result",
        .missingMethod => "missing interface method",
        .unknownMethod => "unknown method",
        .unknownInterface => "unknown interface",
        .ambiguousMethod => "ambiguous method",
        .typeparamConstraint => "type constraint not satisfied",
        .tryOnNonResult => "try on non-Result",
        .nonExhaustive => "non-exhaustive case",
        .redundantPattern => "unreachable case arm",
        .custom => |c| c.message,
    };
    try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "error: {s}\n", .{title}));

    // Location box if available
    if (err.loc) |errLoc| {
        const lineText = getSourceLine(src, errLoc.line);
        const col0 = if (errLoc.col > 0) errLoc.col - 1 else 0;
        // ┌─ :line:col
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "  \u{250c}\u{2500} :{d}:{d}\n",
            .{ errLoc.line, errLoc.col },
        ));
        // │
        try out.appendSlice(allocator, "  \u{2502}\n");
        // N │ source line
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "{d} \u{2502} {s}\n",
            .{ errLoc.line, lineText },
        ));
        // │ spaces^
        try out.appendSlice(allocator, "  \u{2502} ");
        for (0..col0) |_| try out.append(allocator, ' ');
        try out.appendSlice(allocator, "^\n");
    }

    // Error details
    switch (err.kind) {
        .typeMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  expected: {s}\n  found:    {s}\n",
                .{ try typeNameOf(tmp, m.expected), try typeNameOf(tmp, m.got) },
            ));
            if (try @import("./error.zig").TypeError.resultMismatchHint(tmp, m.expected, m.got, m.origin)) |hint| {
                try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "  hint: {s}\n", .{hint}));
            }
        },
        .unboundVariable => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not in scope\n",
                .{name},
            ));
        },
        .arityMismatch => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' expected {d} argument(s), got {d}\n",
                .{ a.name, a.expected, a.got },
            ));
        },
        .unknownField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .notARecord => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not a record or struct type\n",
                .{name},
            ));
        },
        .recursiveType => {
            try out.appendSlice(allocator, "\n  type variable would reference itself (infinite type)\n");
        },
        .unknownTypeName => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  the type '{s}' is not defined in this scope\n",
                .{name},
            ));
        },
        .missingField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' requires field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .methodNotActive => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no active method '{s}'\n  hint: activate the extension with `{s}*`\n",
                .{ m.typeName, m.method, m.hintSym },
            ));
        },
        .ambiguousExtension => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}.{s}' is provided by both '{s}' and '{s}'\n  hint: qualify the call, e.g. `{s}.{s}(obj)`\n",
                .{ a.typeName, a.method, a.symA, a.symB, a.symA, a.method },
            ));
        },
        .notAnExtension => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not name an implement/extend symbol\n",
                .{name},
            ));
        },
        .extendRequiresInterface => |t| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `extend {s}` adds methods without a contract\n  hint: use `implement <Behavior> for {s}` so the methods satisfy a behavior\n",
                .{ t, t },
            ));
        },
        .redundantActivation => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `{s}*` is redundant: a local extension is auto-applied\n  hint: drop it — `*` is only for imports\n",
                .{name},
            ));
        },
        .useNotAllowed => |returnType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function returns `{s}`, which is not a `@Component<C, _>`\n",
                .{returnType},
            ));
        },
        .useNotContext => |exprType| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `{s}` is not a hook — `use` requires a hook @Component<_, _>\n",
                .{exprType},
            ));
        },
        .contextMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  function anchors at `{s}`\n  but the `use` expression returns @Component<{s}, _>\n",
                .{ m.fnBase, m.useBase },
            ));
        },
        .contextBaseMixed => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  this body's base is `{s}`, fixed by the `use` on line {d}\n  but this `use` returns @Component<{s}, _>\n",
                .{ m.anchorBase, m.anchorLine, m.useBase },
            ));
        },
        .useWithoutContextEffect => |u| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  fn '{s}' returns '{s}',\n  but only a `-> @Component<C, T>` body activates a hook (decisions 104, 118)\n",
                .{ u.fnName, u.returnType },
            ));
        },
        .useTupleArity => |u| {
            if (u.tupleLen) |n| {
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  the pattern binds {d} name(s), the hook yields a tuple of {d}\n",
                    .{ u.patternLen, n },
                ));
            } else {
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  the pattern binds {d} name(s), but the hook's Return type is not a tuple\n",
                    .{u.patternLen},
                ));
            }
        },
        .throwWithoutResult => {
            try out.appendSlice(allocator, "\n  'throw' requires the enclosing fn to return '@Result<D, E>'\n");
        },
        .missingMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' does not implement '{s}' required by behavior '{s}'\n",
                .{ m.typeName, m.method, m.interfaceName },
            ));
        },
        .unknownMethod => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not declared in any behavior implemented for '{s}'\n",
                .{ m.method, m.typeName },
            ));
        },
        .unknownInterface => |u| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not a behavior implemented here (method '{s}')\n",
                .{ u.qualifier, u.method },
            ));
        },
        .ambiguousMethod => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is declared by both '{s}' and '{s}' — qualify it\n",
                .{ a.method, a.interfaceA, a.interfaceB },
            ));
        },
        .typeparamConstraint => |c| {
            const gotName = try typeNameOf(tmp, c.got);
            var list: std.ArrayList(u8) = .empty;
            for (c.constraints, 0..) |name, i| {
                if (i > 0) try list.appendSlice(tmp, ", ");
                try list.appendSlice(tmp, name);
            }
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has type '{s}', which does not satisfy 'type {s}'\n",
                .{ c.paramName, gotName, list.items },
            ));
        },
        .tryOnNonResult => |ty| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  `try` requires a @Result<D, E> value, found '{s}'\n",
                .{try typeNameOf(tmp, ty)},
            ));
        },
        .nonExhaustive => |n| {
            if (n.missing.len == 0) {
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  `{s}` has no wildcard `_` arm; it cannot be matched exhaustively\n",
                    .{n.typeName},
                ));
            } else {
                var list: std.ArrayList(u8) = .empty;
                for (n.missing, 0..) |name, i| {
                    if (i > 0) try list.appendSlice(tmp, ", ");
                    try list.appendSlice(tmp, name);
                }
                try out.appendSlice(allocator, try std.fmt.allocPrint(
                    tmp,
                    "\n  '{s}' is missing variant(s): {s}\n",
                    .{ n.typeName, list.items },
                ));
            }
        },
        .redundantPattern => |r| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  {s} is already covered by an earlier arm ('{s}')\n",
                .{ r.description, r.typeName },
            ));
        },
        .custom => |c| {
            if (c.hint) |h| {
                try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "\n  hint: {s}\n", .{h}));
            }
        },
    }

    return try out.toOwnedSlice(allocator);
}

/// Re-parses `src` to describe the parse failure the pipeline only reports as
/// `Outcome.parseError` (which carries no payload). Caller owns the result.
pub fn renderParseErrorBody(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = lexerMod.Lexer.init(src);
    const tokens = lx.scanAll(alloc) catch {
        return allocator.dupe(u8, "error: parse error (the source could not be tokenized)\n");
    };
    var p = parserMod.Parser.init(tokens);
    p.source = src;
    _ = p.parse(alloc) catch {
        // `parseError` is only populated by the parser's *named* rejections;
        // a plain `consume` mismatch leaves it null, so fall back to the token
        // the parser stopped on.
        const kind: []const u8 = if (p.parseError) |info| @tagName(info.kind) else "unexpectedToken";
        const tok = p.peek();
        const line = if (p.parseError) |info| info.line else tok.line;
        const col = if (p.parseError) |info| info.col else tok.col;
        const lexeme = if (p.parseError) |info| info.lexeme else tok.lexeme;
        const detail = if (p.parseError) |info| info.detail else null;

        var out: std.ArrayList(u8) = .empty;
        errdefer out.deinit(allocator);
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            alloc,
            "error: parse error ({s})\n  \u{250c}\u{2500} :{d}:{d}\n  \u{2502}\n{d} \u{2502} {s}\n",
            .{ kind, line, col, line, getSourceLine(src, line) },
        ));
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            alloc,
            "\n  unexpected `{s}`\n",
            .{lexeme},
        ));
        if (detail) |d| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(alloc, "  detail: {s}\n", .{d}));
        }
        return out.toOwnedSlice(allocator);
    };
    // The pipeline saw a parse error we cannot reproduce standalone (e.g. a
    // multi-module compile). Say so rather than record nothing.
    return allocator.dupe(u8, "error: parse error (not reproducible standalone)\n");
}

/// `true` when the module never reached codegen.
pub fn outcomeFailed(outcome: comptimeMod.ComptimeOutput.Outcome) bool {
    return outcome != .ok;
}

/// Rendered body of whatever stopped the module, or `null` when it compiled.
/// Caller owns the result.
pub fn renderOutcomeDiagnostic(
    allocator: std.mem.Allocator,
    src: []const u8,
    outcome: comptimeMod.ComptimeOutput.Outcome,
) !?[]u8 {
    return switch (outcome) {
        .ok => null,
        .parseError => try renderParseErrorBody(allocator, src),
        .typeError => |te| try renderTypeErrorBody(allocator, src, te),
        .validationError => |ce| try ce.renderAlloc(allocator, src),
    };
}

/// `----- COMPILE DIAGNOSTIC -- <name>` section, shared by the codegen and
/// comptime snapshot writers.
pub fn appendDiagnosticSection(
    allocator: std.mem.Allocator,
    buf: *std.ArrayListUnmanaged(u8),
    name: []const u8,
    body: []const u8,
) !void {
    const hdr = try std.fmt.allocPrint(allocator, "----- COMPILE DIAGNOSTIC -- {s}\n```text\n", .{name});
    defer allocator.free(hdr);
    try buf.appendSlice(allocator, hdr);
    try buf.appendSlice(allocator, body);
    if (body.len > 0 and body[body.len - 1] != '\n') try buf.append(allocator, '\n');
    try buf.appendSlice(allocator, "```\n\n");
}

/// Build the full snapshot text for a single module output.
pub fn buildSnapshot(allocator: std.mem.Allocator, output: comptimeMod.ComptimeOutput) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);

    const srcHdr = try std.fmt.allocPrint(allocator, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{output.name});
    defer allocator.free(srcHdr);
    try buf.appendSlice(allocator, srcHdr);
    try buf.appendSlice(allocator, output.src);
    try buf.appendSlice(allocator, "\n```\n\n");

    switch (output.outcome) {
        .ok => |ok| {
            // The runtime exchanges (`COMPTIME ERLANG`/`COMPTIME WAT` +
            // `COMPTIME REPLY`) are not here: they depend on the comptime
            // runtime, the AST does not — `assertComptimeExchange` records
            // them per runtime (front 18 step 4, `snapshot-layout.md` § 6).
            if (ok.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(allocator, "----- COMPTIME VALUES -- {s}\n```text\n", .{output.name});
                defer allocator.free(ctHdr);
                try buf.appendSlice(allocator, ctHdr);
                try buf.appendSlice(allocator, ct);
                try buf.appendSlice(allocator, "```\n\n");
            }

            // H8 / C1 — the spliced program is evidence for *any* comptime work,
            // not just folded `val`s: a template expansion or a decorator
            // `@emit` contribution rewrites the program without producing a
            // `comptime_script`, and used to leave no trace of the result here.
            // `template_expansions` covers the V1-driver expansions
            // (pass-through / `@expr` / `@code`), which never run in the `erl`
            // runtime and so record no `comptime_traces` entry either.
            if (ok.comptime_script != null or ok.comptime_traces.len > 0 or ok.template_expansions > 0) {
                const fmtHdr = try std.fmt.allocPrint(allocator, "----- BOTOPINK TRANSFORM CODE -- {s}.bp\n```botopink\n", .{output.name});
                defer allocator.free(fmtHdr);
                try buf.appendSlice(allocator, fmtHdr);
                const formatted = try format.format(allocator, ok.transformed);
                defer allocator.free(formatted);
                try buf.appendSlice(allocator, formatted);
                try buf.appendSlice(allocator, "\n```\n\n");
            }

            const jsonHdr = try std.fmt.allocPrint(allocator, "----- TYPED AST JSON -- {s}.json\n```json\n", .{output.name});
            defer allocator.free(jsonHdr);
            try buf.appendSlice(allocator, jsonHdr);

            // Use a temporary arena for all intermediate work: BindingRepr structs
            // (which own allocated slices) plus intermediate JSON values.
            var json_arena = std.heap.ArenaAllocator.init(allocator);
            defer json_arena.deinit();
            const ja = json_arena.allocator();

            var items = std.json.Array.init(ja);

            // First pass: collect and merge use declarations
            var merged_uses: std.StringHashMap(std.ArrayList(UseDeclaration)) = std.StringHashMap(std.ArrayList(UseDeclaration)).init(ja);
            defer {
                var iter = merged_uses.iterator();
                while (iter.next()) |entry| {
                    entry.value_ptr.deinit(ja);
                }
                merged_uses.deinit();
            }

            for (ok.bindings) |b| {
                const repr = (try bindingToRepr(ja, b, output.src)) orelse continue;

                if (repr == .use) {
                    const use_info = b.decl.use;
                    const module_source = "module";
                    _ = use_info;

                    const gop = try merged_uses.getOrPut(module_source);
                    if (!gop.found_existing) {
                        gop.value_ptr.* = std.ArrayList(UseDeclaration).empty;
                    }

                    // Add all declarations from this use to the merged list
                    for (repr.use.declarations) |decl| {
                        try gop.value_ptr.append(ja, decl);
                    }
                } else {
                    // For non-use declarations, add directly to items
                    const jsonStr = try std.json.Stringify.valueAlloc(ja, repr, .{ .emit_null_optional_fields = false, .whitespace = .indent_2 });
                    const value = try std.json.parseFromSliceLeaky(std.json.Value, ja, jsonStr, .{});
                    try items.append(value);
                }
            }

            // Second pass: the `implement` blocks, which `inferProgram` returns
            // no binding for (a behavior implementation declares no name of its
            // own in the value namespace). They are read off the transformed
            // program, in source order, after the declarations that do bind.
            for (ok.transformed.decls) |decl| {
                if (decl != .implement) continue;
                const repr = try implementToRepr(ja, decl.implement);
                const jsonStr = try std.json.Stringify.valueAlloc(ja, repr, .{ .emit_null_optional_fields = false, .whitespace = .indent_2 });
                try items.append(try std.json.parseFromSliceLeaky(std.json.Value, ja, jsonStr, .{}));
            }

            // Third pass: add merged use declarations to items
            var iter = merged_uses.iterator();
            while (iter.next()) |entry| {
                const use_repr = BindingRepr{ .use = .{
                    .ast = "use",
                    .declarations = try entry.value_ptr.toOwnedSlice(ja),
                } };
                const jsonStr = try std.json.Stringify.valueAlloc(ja, use_repr, .{ .emit_null_optional_fields = false, .whitespace = .indent_2 });
                const value = try std.json.parseFromSliceLeaky(std.json.Value, ja, jsonStr, .{});
                try items.append(value);
            }
            var root = if (comptime @hasDecl(std.array_hash_map, "String"))
                try std.json.ObjectMap.init(ja, &.{}, &.{})
            else
                std.json.ObjectMap.init(ja);
            if (comptime @hasDecl(std.array_hash_map, "String")) {
                try root.put(ja, "declarations", .{ .array = items });
            } else {
                try root.put("declarations", .{ .array = items });
            }

            const json = try std.json.Stringify.valueAlloc(allocator, std.json.Value{ .object = root }, .{ .whitespace = .indent_2 });
            defer allocator.free(json);
            try buf.appendSlice(allocator, json);
            try buf.appendSlice(allocator, "\n```\n\n");
        },
        // H3 — a module that never compiled used to add nothing after the
        // source, so the snapshot compared source-with-source and passed.
        .validationError, .typeError, .parseError => {
            const body = (try renderOutcomeDiagnostic(allocator, output.src, output.outcome)).?;
            defer allocator.free(body);
            try appendDiagnosticSection(allocator, &buf, output.name, body);
        },
    }

    return buf.toOwnedSlice(allocator);
}

/// Build a multi-section snapshot for multiple module outputs joined together.
pub fn buildSnapshotMulti(allocator: std.mem.Allocator, outputs: []const comptimeMod.ComptimeOutput) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);
    for (outputs, 0..) |output, idx| {
        if (idx > 0) try buf.appendSlice(allocator, "\n");
        const text = try buildSnapshot(allocator, output);
        defer allocator.free(text);
        try buf.appendSlice(allocator, text);
    }
    return buf.toOwnedSlice(allocator);
}

/// The runtime exchanges of `outputs` — the source, then every evaluation's
/// listing and reply — or null when no decorator or template ran.
pub fn buildExchange(allocator: std.mem.Allocator, outputs: []const comptimeMod.ComptimeOutput) !?[]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);
    var any = false;
    for (outputs) |output| {
        const ok = switch (output.outcome) {
            .ok => |ok| ok,
            else => continue,
        };
        if (ok.comptime_traces.len == 0) continue;
        if (any) try buf.appendSlice(allocator, "\n");
        any = true;
        try buf.print(allocator, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{output.name});
        try buf.appendSlice(allocator, output.src);
        try buf.appendSlice(allocator, "\n```\n\n");
        try comptimeMod.trace.render(allocator, &buf, ok.comptime_traces);
    }
    if (!any) {
        buf.deinit(allocator);
        return null;
    }
    return try buf.toOwnedSlice(allocator);
}

/// Assert the runtime exchanges of `outputs`, evaluated on `runtime`, against
/// `comptime/runtime/<runtime>/{slug}.snap.md` — nothing when no decorator or
/// template ran (front 18 step 4: the AST is recorded once, the exchange once
/// per runtime).
pub fn assertComptimeExchange(
    allocator: std.mem.Allocator,
    runtime: []const u8,
    slug: []const u8,
    outputs: []const comptimeMod.ComptimeOutput,
) !void {
    const text = (try buildExchange(allocator, outputs)) orelse return;
    defer allocator.free(text);
    const snapName = try std.fmt.allocPrint(allocator, "comptime/runtime/{s}/{s}", .{ runtime, slug });
    defer allocator.free(snapName);
    try snapMod.checkText(allocator, snapName, text);
}

/// Assert the comptime AST against a snapshot file.
/// The snapshot path is `"comptime/ast/{slug}.snap.md"` — one file per test.
/// The AST snapshot carries no per-backend text, so there is nothing to record
/// per runtime; the sibling `comptime/errors/` tree is written by
/// `tests/helpers.zig` `assertTypeErrorSnap` and `comptime/templates/` by
/// `tests/templates.zig`.
pub fn assertComptimeAst(
    allocator: std.mem.Allocator,
    slug: []const u8,
    outputs: []const comptimeMod.ComptimeOutput,
) !void {
    const snapName = try std.fmt.allocPrint(allocator, "comptime/ast/{s}", .{slug});
    defer allocator.free(snapName);
    const text = try buildSnapshotMulti(allocator, outputs);
    defer allocator.free(text);
    try snapMod.checkText(allocator, snapName, text);
}

// ── Unit tests ────────────────────────────────────────────────────────────────
//
// The `TYPED AST JSON` type rendering, asserted directly. The snapshots cover
// what the checker produces for real programs; these pin the contract the
// renderer owes them — above all that `?` means one thing.

fn testNamed(arena: std.mem.Allocator, name: []const u8) !*T.Type {
    const ty = try arena.create(T.Type);
    ty.* = .{ .named = .{ .name = name, .args = &.{} } };
    return ty;
}

fn testVar(arena: std.mem.Allocator, state: T.TypeVar) !*T.Type {
    const cell = try arena.create(T.TypeCell);
    cell.* = .{ .state = state };
    const ty = try arena.create(T.Type);
    ty.* = .{ .typeVar = cell };
    return ty;
}

fn testFunc(arena: std.mem.Allocator, params: []*T.Type, ret: *T.Type) !*T.Type {
    const ty = try arena.create(T.Type);
    ty.* = .{ .func = .{ .params = params, .ret = ret } };
    return ty;
}

test "ast rendering: a resolved fn spells its signature out" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const params = try arena.alloc(*T.Type, 2);
    params[0] = try testNamed(arena, "i32");
    params[1] = try testNamed(arena, "string");
    const fn_type = try testFunc(arena, params, try testNamed(arena, "bool"));

    var namer = GenericNamer{ .allocator = arena };
    const rendered = try typeNameIn(arena, fn_type, .{ .mode = .ast, .namer = &namer });
    try std.testing.expectEqualStrings("fn(i32, string) -> bool", rendered);

    // A diagnostic still names the return type alone — the `errors/` snapshots
    // record that text and this front does not move it.
    const as_diagnostic = try typeNameOf(arena, fn_type);
    try std.testing.expectEqualStrings("bool", as_diagnostic);
}

test "ast rendering: a generic variable is named, an unbound one stays `?`" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const generic = try testVar(arena, .{ .generic = 7 });
    const unbound = try testVar(arena, .{ .unbound = .{ .id = 9, .level = 0 } });

    var namer = GenericNamer{ .allocator = arena };
    const render = TypeRender{ .mode = .ast, .namer = &namer };

    // Unnamed, a generic falls back to a stable letter — never to `?`.
    try std.testing.expectEqualStrings("'a", try typeNameIn(arena, generic, render));
    // Named after the type parameter the declaration wrote, it reads as source.
    var named_namer = GenericNamer{ .allocator = arena };
    try named_namer.bind(7, "T");
    try std.testing.expectEqualStrings(
        "T",
        try typeNameIn(arena, generic, .{ .mode = .ast, .namer = &named_namer }),
    );

    // `?` is reserved for the checker saying it does not know.
    try std.testing.expectEqualStrings("?", try typeNameIn(arena, unbound, render));
    // A diagnostic cannot tell the two apart, and still does not have to.
    try std.testing.expectEqualStrings("?", try typeNameOf(arena, generic));
    try std.testing.expectEqualStrings("?", try typeNameOf(arena, unbound));
}

test "ast rendering: a generic fn signature reads with its declared parameters" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const t_var = try testVar(arena, .{ .generic = 1 });
    const r_var = try testVar(arena, .{ .generic = 2 });
    const params = try arena.alloc(*T.Type, 1);
    params[0] = t_var;
    const fn_type = try testFunc(arena, params, r_var);

    const generic_params = [_]ast.GenericParam{
        .{ .name = "T" },
        .{ .name = "R" },
    };
    var namer = GenericNamer{ .allocator = arena };
    try bindGenericNames(&namer, &generic_params, .{ .named = "T" }, t_var);
    try bindGenericNames(&namer, &generic_params, .{ .named = "R" }, r_var);

    try std.testing.expectEqualStrings(
        "fn(T) -> R",
        try typeNameIn(arena, fn_type, .{ .mode = .ast, .namer = &namer }),
    );

    // An annotation that names no type parameter of the declaration binds
    // nothing, so a stray name can never rename someone else's variable.
    var other = GenericNamer{ .allocator = arena };
    try bindGenericNames(&other, &generic_params, .{ .named = "i32" }, t_var);
    try std.testing.expectEqualStrings("'a", try typeNameIn(arena, t_var, .{ .mode = .ast, .namer = &other }));
}

test "ast rendering: an optional reads as source, unless its inner is unknown" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const args = try arena.alloc(*T.Type, 1);
    args[0] = try testNamed(arena, "string");
    const opt = try arena.create(T.Type);
    opt.* = .{ .named = .{ .name = "optional", .args = args } };

    var namer = GenericNamer{ .allocator = arena };
    const render = TypeRender{ .mode = .ast, .namer = &namer };
    try std.testing.expectEqualStrings("?string", try typeNameIn(arena, opt, render));
    try std.testing.expectEqualStrings("optional<string>", try typeNameOf(arena, opt));

    const unknown_args = try arena.alloc(*T.Type, 1);
    unknown_args[0] = try testVar(arena, .{ .unbound = .{ .id = 3, .level = 0 } });
    const opt_unknown = try arena.create(T.Type);
    opt_unknown.* = .{ .named = .{ .name = "optional", .args = unknown_args } };
    try std.testing.expectEqualStrings("optional<?>", try typeNameIn(arena, opt_unknown, render));
}

test "ast rendering: a record field annotation renders in full" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var inner: ast.TypeRef = .{ .named = "Inner" };
    const optional_ref: ast.TypeRef = .{ .optional = &inner };
    try std.testing.expectEqualStrings("?Inner", try typeRefName(arena, optional_ref));

    var elem: ast.TypeRef = .{ .named = "i32" };
    try std.testing.expectEqualStrings("i32[]", try typeRefName(arena, .{ .array = &elem }));
}
