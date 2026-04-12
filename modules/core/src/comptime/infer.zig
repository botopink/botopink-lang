/// Type inference for the botopink type checker.
///
/// Entry points:
///   `inferProgram(env, program)` ---- infers all top-level declarations and
///   returns a map of name → *Type for every declared binding.
///
/// The inference is two-pass:
///   1. Register all type definitions (records, structs, enums) and build
///      constructor types for them.
///   2. Infer the type of every expression/declaration and bind the result.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const Env = @import("env.zig").Env;
const envMod = @import("env.zig");
const TypeError = @import("error.zig").TypeError;
const unify = @import("unify.zig").unify;
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const Module = @import("../module.zig").Module;
const comptimeMod = @import("../comptime.zig");

pub const InferError = error{ TypeError, OutOfMemory };

/// A single resolved top-level binding: the declaration name and its inferred type.
pub const Binding = struct {
    name: []const u8,
    type_: *T.Type,
};

/// Like `Binding` but also carries the typed expression tree for `val` declarations.
/// `typedExpr` is null for type declarations (record/struct/enum/interface/fn).
/// `decl` is the original AST declaration node.
/// `typeId` is set for record/struct/enum declarations (monotonic counter).
pub const TypedBinding = struct {
    name: []const u8,
    type_: *T.Type,
    typedExpr: ?ast.TypedExpr,
    decl: ast.DeclKind,
    typeId: ?usize = null,
};

// ── public entry point ────────────────────────────────────────────────────────

/// Infer types for an entire program.
///
/// Pass 1 registers all type definitions (record, struct, enum) and builds
/// constructor bindings in the environment.
/// Pass 2 infers every `val` and `fn` declaration in source order.
///
/// Returns a slice of `Binding` values in declaration order.
/// All memory is allocated in `env.arena`.
pub fn inferProgram(env: *Env, program: ast.Program) InferError![]Binding {
    var list: std.ArrayListUnmanaged(Binding) = .empty;

    // Pass 1: register type definitions and their constructors.
    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }

    // Pass 2: infer value-producing declarations in order.
    for (program.decls) |decl| {
        if (try inferDecl(env, decl)) |b| {
            try list.append(env.arena, b);
        }
    }
    return list.toOwnedSlice(env.arena);
}

/// Like `inferProgram` but returns `TypedBinding` slices that include the
/// typed expression tree for each `val` declaration.
pub fn inferProgramTyped(env: *Env, program: ast.Program) InferError![]TypedBinding {
    var list: std.ArrayListUnmanaged(TypedBinding) = .empty;

    for (program.decls) |decl| {
        try registerTypeDecl(env, decl);
    }
    for (program.decls) |decl| {
        if (try inferDeclTyped(env, decl)) |b| {
            try list.append(env.arena, b);
        }
    }
    return list.toOwnedSlice(env.arena);
}

// ── stdlib preload ────────────────────────────────────────────────────────────

/// Parse and register all stdlib interface declarations into `env`.
///
/// The three stdlib source files are embedded at compile time via `@embedFile`.
/// Each file is lexed and parsed in a temporary arena that is freed immediately
/// after inference; the resulting type bindings live in `env.arena`.
fn inferDeclTyped(env: *Env, decl: ast.DeclKind) InferError!?TypedBinding {
    switch (decl) {
        .val => |v| {
            const typedExpr = try inferExprTyped(env, v.value.*);
            const ty = typedExpr.type_;
            if (v.typeAnnotation) |ann| {
                const annType = try resolveTypeRef(env, ann);
                try unifyAt(env, annType, ty, v.value.loc);
            }
            try env.bind(v.name, ty);
            return .{ .name = v.name, .type_ = ty, .typedExpr = typedExpr, .decl = decl };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            const sigName = try buildFnSigName(env, f);
            return .{ .name = f.name, .type_ = try env.namedType(sigName), .typedExpr = null, .decl = decl };
        },
        .record => |r| {
            const typeName = try buildRecordDeclName(env, r);
            const typeId = if (env.lookupTypeDef(r.name)) |td| switch (td) {
                .record => |rec| rec.id,
                else => null,
            } else null;
            return .{ .name = r.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .@"struct" => |s| {
            const typeName = try buildStructDeclName(env, s);
            const typeId = if (env.lookupTypeDef(s.name)) |td| switch (td) {
                .struct_ => |st| st.id,
                else => null,
            } else null;
            return .{ .name = s.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .@"enum" => |e| {
            const typeName = try buildEnumDeclName(env, e);
            const typeId = if (env.lookupTypeDef(e.name)) |td| switch (td) {
                .enum_ => |en| en.id,
                else => null,
            } else null;
            return .{ .name = e.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl, .typeId = typeId };
        },
        .interface => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName), .typedExpr = null, .decl = decl };
        },
        .use => {
            return .{ .name = "", .type_ = try env.namedType("void"), .typedExpr = null, .decl = decl };
        },
        else => return null,
    }
}

// ── pass 1: type definition registration ─────────────────────────────────────

fn registerTypeDecl(env: *Env, decl: ast.DeclKind) InferError!void {
    switch (decl) {
        .record => |r| try registerRecord(env, r),
        .@"struct" => |s| try registerStruct(env, s),
        .@"enum" => |e| try registerEnum(env, e),
        else => {},
    }
}

fn registerRecord(env: *Env, r: ast.RecordDecl) InferError!void {
    // Build generic param map: each param name → fresh generic type var.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Resolve each field's type.
    var fields = try env.arena.alloc(envMod.FieldDef, r.fields.len);
    for (r.fields, 0..) |f, i| {
        fields[i] = .{
            .name = f.name,
            .type_ = try resolveTypeRefInContext(env, f.typeRef, genericMap),
        };
    }

    // Register the type definition.
    const typeId = env.allocTypeId();
    try env.registerTypeDef(r.name, .{ .record = .{
        .name = r.name,
        .id = typeId,
        .genericParams = genericIds,
        .fields = fields,
    } });

    // Build constructor function type: `fn(T1, T2, ...) -> RecordName<A,B,...>`.
    // The return type carries the generic type vars so that after call-site
    // unification `typeNameOf` can display the instantiated form, e.g. `Pair<Int,String>`.
    var paramTypes = try env.arena.alloc(*T.Type, r.fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    var retArgs = try env.arena.alloc(*T.Type, r.genericParams.len);
    for (r.genericParams, 0..) |gp, i| retArgs[i] = genericMap.get(gp.name).?;
    const retType = try env.namedTypeArgs(r.name, retArgs);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(r.name, ctorType);
}

fn registerStruct(env: *Env, s: ast.StructDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, s.genericParams.len);
    for (s.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    // Collect non-private fields.
    var fieldCount: usize = 0;
    for (s.members) |m| switch (m) {
        .field => fieldCount += 1,
        else => {},
    };

    var fields = try env.arena.alloc(envMod.FieldDef, fieldCount);
    var fi: usize = 0;
    for (s.members) |m| switch (m) {
        .field => |f| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try env.resolveTypeName(f.typeName, genericMap),
            };
            fi += 1;
        },
        else => {},
    };

    const structTypeId = env.allocTypeId();
    try env.registerTypeDef(s.name, .{ .struct_ = .{
        .name = s.name,
        .id = structTypeId,
        .genericParams = genericIds,
        .fields = fields,
    } });

    var paramTypes = try env.arena.alloc(*T.Type, fields.len);
    for (fields, 0..) |f, i| paramTypes[i] = f.type_;
    const retType = try env.namedType(s.name);
    const ctorType = try env.funcType(paramTypes, retType);
    try env.bind(s.name, ctorType);
}

fn registerEnum(env: *Env, e: ast.EnumDecl) InferError!void {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    var genericIds = try env.arena.alloc([]const u8, e.genericParams.len);
    for (e.genericParams, 0..) |gp, i| {
        const tv = try env.freshVar();
        try genericMap.put(gp.name, tv);
        genericIds[i] = gp.name;
    }

    var variants = try env.arena.alloc(envMod.VariantDef, e.variants.len);
    for (e.variants, 0..) |v, vi| {
        var fields = try env.arena.alloc(envMod.FieldDef, v.fields.len);
        for (v.fields, 0..) |f, fi| {
            fields[fi] = .{
                .name = f.name,
                .type_ = try resolveTypeRefInContext(env, f.typeRef, genericMap),
            };
        }
        variants[vi] = .{ .name = v.name, .fields = fields };

        // Each variant is also a constructor: unit → `EnumName`, payload → `fn(T...) → EnumName`.
        const retType = try env.namedType(e.name);
        const ctorType = if (v.fields.len == 0)
            retType
        else blk: {
            var ps = try env.arena.alloc(*T.Type, v.fields.len);
            for (fields, 0..) |f, i| ps[i] = f.type_;
            break :blk try env.funcType(ps, retType);
        };
        try env.bind(v.name, ctorType);
    }

    const enumTypeId = env.allocTypeId();
    try env.registerTypeDef(e.name, .{ .enum_ = .{
        .name = e.name,
        .id = enumTypeId,
        .genericParams = genericIds,
        .variants = variants,
    } });
    // Bind the enum name itself so `inferDecl` can look it up.
    try env.bind(e.name, try env.namedType(e.name));
}

// ── pass 2: declaration inference ────────────────────────────────────────────

/// Build a signature name for a record declaration binding.
/// Format: `"record { f1: T1, f2: T2 }"` ---- fields inline, body omitted.
fn buildRecordDeclName(env: *Env, r: ast.RecordDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "record");
    if (r.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (r.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " { ");
    for (r.fields, 0..) |f, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try appendTypeRefStr(&buf, env.arena, f.typeRef);
    }
    try buf.append(env.arena, ' ');
    try buf.appendSlice(env.arena, "}");
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a struct declaration binding.
/// Format: `"struct {\n    name: Type\n}"` ---- fields only.
fn buildStructDeclName(env: *Env, s: ast.StructDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "struct");
    if (s.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (s.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (s.members) |m| {
        switch (m) {
            .field => |f| {
                try buf.appendSlice(env.arena, "    ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try buf.appendSlice(env.arena, f.typeName);
                if (f.init) |_| {
                    try buf.append(env.arena, '\n');
                } else {
                    try buf.append(env.arena, '\n');
                }
            },
            else => {},
        }
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for an interface declaration binding.
/// Format: `"interface {\n    fn method(params)\n}"` ---- methods and fields.
fn buildInterfaceDeclName(env: *Env, d: ast.InterfaceDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "interface");
    if (d.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (d.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (d.fields) |f| {
        try buf.appendSlice(env.arena, "    val ");
        try buf.appendSlice(env.arena, f.name);
        try buf.appendSlice(env.arena, ": ");
        try buf.appendSlice(env.arena, f.typeName);
        try buf.appendSlice(env.arena, ";\n");
    }
    for (d.methods) |m| {
        try buf.appendSlice(env.arena, "    fn ");
        try buf.appendSlice(env.arena, m.name);
        try buf.append(env.arena, '(');
        for (m.params, 0..) |p, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, p.name);
            if (p.modifier == .@"comptime" or p.modifier == .syntax) {
                try buf.appendSlice(env.arena, " comptime");
            }
            try buf.appendSlice(env.arena, ": ");
            if (p.modifier == .syntax) try buf.appendSlice(env.arena, "syntax ");
            try buf.appendSlice(env.arena, p.typeName);
        }
        try buf.append(env.arena, ')');
        if (!m.is_default) try buf.appendSlice(env.arena, ";");
        try buf.append(env.arena, '\n');
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for an enum declaration binding.
/// Format: `"enum {\n    Variant,\n    Variant(field: Type),\n}\n"`
fn buildEnumDeclName(env: *Env, e: ast.EnumDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "enum");
    if (e.genericParams.len > 0) {
        try buf.appendSlice(env.arena, " <");
        for (e.genericParams, 0..) |gp, i| {
            if (i > 0) try buf.appendSlice(env.arena, ", ");
            try buf.appendSlice(env.arena, gp.name);
        }
        try buf.append(env.arena, '>');
    }
    try buf.appendSlice(env.arena, " {\n");
    for (e.variants) |v| {
        try buf.appendSlice(env.arena, "    ");
        try buf.appendSlice(env.arena, v.name);
        if (v.fields.len > 0) {
            try buf.append(env.arena, '(');
            for (v.fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(env.arena, ", ");
                try buf.appendSlice(env.arena, f.name);
                try buf.appendSlice(env.arena, ": ");
                try appendTypeRefStr(&buf, env.arena, f.typeRef);
            }
            try buf.append(env.arena, ')');
        }
        try buf.appendSlice(env.arena, ",\n");
    }
    try buf.append(env.arena, '}');
    return try buf.toOwnedSlice(env.arena);
}

/// Build a signature name for a fn declaration binding.
/// Format: `fn(name [comptime]: [syntax ]Type, ...) -> ReturnType`
/// The function name and generic params are omitted; modifiers are included.
fn buildFnSigName(env: *Env, f: ast.FnDecl) ![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    try buf.appendSlice(env.arena, "fn(");
    for (f.params, 0..) |p, i| {
        if (i > 0) try buf.appendSlice(env.arena, ", ");
        try buf.appendSlice(env.arena, p.name);
        if (p.modifier == .@"comptime" or p.modifier == .syntax) {
            try buf.appendSlice(env.arena, " comptime");
        }
        try buf.appendSlice(env.arena, ": ");
        if (p.modifier == .syntax) {
            try buf.appendSlice(env.arena, "syntax ");
        }
        try buf.appendSlice(env.arena, p.typeName);
    }
    try buf.append(env.arena, ')');
    if (f.returnType) |rt| {
        try buf.appendSlice(env.arena, " -> ");
        try appendTypeRefStr(&buf, env.arena, rt);
    }
    return try buf.toOwnedSlice(env.arena);
}

/// Append the string form of a TypeRef to `buf`.
fn appendTypeRefStr(buf: *std.ArrayListUnmanaged(u8), allocator: std.mem.Allocator, ref: ast.TypeRef) std.mem.Allocator.Error!void {
    switch (ref) {
        .named => |n| try buf.appendSlice(allocator, n),
        .array => |elem| {
            try appendTypeRefStr(buf, allocator, elem.*);
            try buf.appendSlice(allocator, "[]");
        },
        .tuple_ => |elems| {
            try buf.appendSlice(allocator, "#(");
            for (elems, 0..) |e, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, e);
            }
            try buf.append(allocator, ')');
        },
        .optional => |inner| {
            try buf.append(allocator, '?');
            try appendTypeRefStr(buf, allocator, inner.*);
        },
        .errorUnion => |eu| {
            try appendTypeRefStr(buf, allocator, eu.errorType.*);
            try buf.append(allocator, '!');
            try appendTypeRefStr(buf, allocator, eu.payload.*);
        },
    }
}

fn inferDecl(env: *Env, decl: ast.DeclKind) InferError!?Binding {
    switch (decl) {
        .val => |v| {
            const ty = try inferExpr(env, v.value.*);
            if (v.typeAnnotation) |ann| {
                const annType = try resolveTypeRef(env, ann);
                try unifyAt(env, annType, ty, v.value.loc);
            }
            try env.bind(v.name, ty);
            return .{ .name = v.name, .type_ = ty };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            const sigName = try buildFnSigName(env, f);
            return .{ .name = f.name, .type_ = try env.namedType(sigName) };
        },
        // Type declarations produce a binding whose type name encodes the body.
        .record => |r| {
            const typeName = try buildRecordDeclName(env, r);
            return .{ .name = r.name, .type_ = try env.namedType(typeName) };
        },
        .@"struct" => |s| {
            const typeName = try buildStructDeclName(env, s);
            return .{ .name = s.name, .type_ = try env.namedType(typeName) };
        },
        .@"enum" => |e| {
            const typeName = try buildEnumDeclName(env, e);
            return .{ .name = e.name, .type_ = try env.namedType(typeName) };
        },
        .interface => |d| {
            const typeName = try buildInterfaceDeclName(env, d);
            return .{ .name = d.name, .type_ = try env.namedType(typeName) };
        },
        // implement and use don't produce a value binding.
        else => return null,
    }
}

fn inferFnDecl(env: *Env, f: ast.FnDecl) InferError!*T.Type {
    // Build generic map.
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    for (f.genericParams) |gp| {
        try genericMap.put(gp.name, try env.freshVar());
    }

    // Infer parameter types.
    var paramTypes = try env.arena.alloc(*T.Type, f.params.len);
    for (f.params, 0..) |p, i| {
        const ty = try env.resolveTypeName(p.typeName, genericMap);
        paramTypes[i] = ty;
        if (p.destruct) |d| {
            // Destructuring param: bind each field name to its type.
            const maybeTypeDef = env.typeDefs.get(p.typeName);
            switch (d) {
                .record_ => |fieldNames| {
                    for (fieldNames) |fname| {
                        const fieldTy = if (maybeTypeDef) |td|
                            if (td.findField(fname)) |f_| f_.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fname, fieldTy);
                    }
                },
                .tuple_ => |names| {
                    // Tuple-destructured parameter: bind each name to a fresh type var.
                    for (names) |n| try env.bind(n, try env.freshVar());
                },
            }
        } else {
            try env.bind(p.name, ty);
        }
    }

    // Infer return type.
    const retType = if (f.returnType) |rt|
        try resolveTypeRefInContext(env, rt, genericMap)
    else
        try env.namedType("void");

    // Infer body (for type checking; we ignore the result for now).
    for (f.body) |stmt| {
        _ = try inferExpr(env, stmt.expr);
    }

    return env.funcType(paramTypes, retType);
}

// ── expression inference ──────────────────────────────────────────────────────

fn isIntType(t: *T.Type) bool {
    return t.isNamed("i8") or t.isNamed("u8") or
        t.isNamed("i16") or t.isNamed("u16") or
        t.isNamed("i32") or t.isNamed("u32") or
        t.isNamed("i64") or t.isNamed("u64") or
        t.isNamed("isize") or t.isNamed("usize");
}

fn isFloatType(t: *T.Type) bool {
    return t.isNamed("f32") or t.isNamed("f64");
}

/// Calls `unify` and, if it fails, stamps the expression's location onto the error.
fn unifyAt(env: *Env, a: *T.Type, b: *T.Type, loc: ast.Loc) InferError!void {
    unify(env, a, b) catch |err| {
        if (env.lastError) |*e| e.loc = loc;
        return err;
    };
}

/// Shallow structural equality check ---- used by case-arm deduplication.
/// Does NOT unify type variables; treats any typeVar as distinct from a named type.
fn typesSameShape(a: *T.Type, b: *T.Type) bool {
    const ta = a.deref();
    const tb = b.deref();
    if (ta == tb) return true;
    return switch (ta.*) {
        .named => |na| switch (tb.*) {
            .named => |nb| std.mem.eql(u8, na.name, nb.name),
            else => false,
        },
        .union_ => |ua| switch (tb.*) {
            .union_ => |ub| ua.len == ub.len,
            else => false,
        },
        .typeVar => switch (tb.*) {
            .typeVar => |cellB| ta.typeVar == cellB,
            else => false,
        },
        else => false,
    };
}

/// Resolve an `ast.TypeRef` to a `*T.Type` using a generic-parameter map.
/// Used when the type ref appears inside a generic context (record/enum registration).
fn resolveTypeRefInContext(env: *Env, ref: ast.TypeRef, genericMap: std.StringHashMap(*T.Type)) InferError!*T.Type {
    switch (ref) {
        .named => |n| return env.resolveTypeName(n, genericMap),
        .array => |elem| {
            const elemTy = try resolveTypeRefInContext(env, elem.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = elemTy;
            return env.namedTypeArgs("array", args);
        },
        .tuple_ => |elems| {
            const args = try env.arena.alloc(*T.Type, elems.len);
            for (elems, 0..) |e, i| args[i] = try resolveTypeRefInContext(env, e, genericMap);
            return env.namedTypeArgs("tuple", args);
        },
        .optional => |inner| {
            const innerTy = try resolveTypeRefInContext(env, inner.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = innerTy;
            return env.namedTypeArgs("optional", args);
        },
        .errorUnion => |eu| {
            const errTy = try resolveTypeRefInContext(env, eu.errorType.*, genericMap);
            const payTy = try resolveTypeRefInContext(env, eu.payload.*, genericMap);
            const args = try env.arena.alloc(*T.Type, 2);
            args[0] = errTy;
            args[1] = payTy;
            return env.namedTypeArgs("errorUnion", args);
        },
    }
}

/// Resolve an `ast.TypeRef` annotation to a `*T.Type` (no generic context).
fn resolveTypeRef(env: *Env, ref: ast.TypeRef) InferError!*T.Type {
    var genericMap = std.StringHashMap(*T.Type).init(env.arena);
    defer genericMap.deinit();
    return resolveTypeRefInContext(env, ref, genericMap);
}

/// Infer the type of an expression, returning a *Type.
/// On type error: sets `env.lastError` and returns `error.TypeError`.
/// This is a thin wrapper around `inferExprTyped` ---- it discards the typed node.
pub fn inferExpr(env: *Env, expr: ast.Expr) InferError!*T.Type {
    return (try inferExprTyped(env, expr)).type_;
}

// ── typed expression construction ─────────────────────────────────────────────

const TypedExpr = ast.TypedExpr;
const TypedStmt = ast.StmtOf(.typed);

/// Convenience constructor: bundle loc + kind + type into a TypedExpr.
fn makeExpr(loc: ast.Loc, kind: TypedExpr.Kind, type_: *T.Type) TypedExpr {
    return .{ .loc = loc, .kind = kind, .type_ = type_ };
}

/// Allocate a heap-owned TypedExpr in env.arena.
fn makeTypedPtr(env: *Env, node: TypedExpr) !*TypedExpr {
    const ptr = try env.arena.create(TypedExpr);
    ptr.* = node;
    return ptr;
}

/// Convert a slice of untyped statements to typed ones (arena-allocated).
fn inferStmtsTyped(env: *Env, stmts: []const ast.Stmt) InferError![]TypedStmt {
    const out = try env.arena.alloc(TypedStmt, stmts.len);
    for (stmts, 0..) |s, i| out[i] = .{ .expr = try inferExprTyped(env, s.expr) };
    return out;
}

/// Convert a slice of untyped trailing lambdas to typed ones (arena-allocated).
fn inferTrailingLambdasTyped(env: *Env, trailing: []const ast.TrailingLambda) InferError![]ast.TrailingLambdaOf(.typed) {
    const out = try env.arena.alloc(ast.TrailingLambdaOf(.typed), trailing.len);
    for (trailing, 0..) |tl, i| {
        out[i] = .{
            .label = tl.label,
            .params = tl.params,
            .body = try inferStmtsTyped(env, tl.body),
        };
    }
    return out;
}

/// Infer the type of `expr` AND build the fully-annotated `TypedExpr` in one
/// pass.  Every child node is recursively typed before its parent is built, so
/// no expression is visited more than once.  All allocations go into env.arena.
pub fn inferExprTyped(env: *Env, expr: ast.Expr) InferError!TypedExpr {
    switch (expr.kind) {
        // ── literals ──────────────────────────────────────────────────────────
        .stringLit => |s| return makeExpr(expr.loc, .{ .stringLit = s }, try env.namedType("string")),

        .numberLit => |n| {
            const isFloat = std.mem.indexOfScalar(u8, n, '.') != null;
            return makeExpr(expr.loc, .{ .numberLit = n }, try env.namedType(if (isFloat) "f64" else "i32"));
        },

        // ── identifiers ───────────────────────────────────────────────────────
        .ident => |name| {
            if (env.lookup(name)) |ty| return makeExpr(expr.loc, .{ .ident = name }, ty);
            env.lastError = TypeError.unboundVariable(name).withLoc(expr.loc);
            return error.TypeError;
        },

        .dotIdent => |name| {
            if (env.lookup(name)) |ty| return makeExpr(expr.loc, .{ .dotIdent = name }, ty);
            env.lastError = TypeError.unboundVariable(name).withLoc(expr.loc);
            return error.TypeError;
        },

        .identAccess => |ia| {
            // When receiver is an identifier, check if it's a type name rather than a variable.
            // This handles enum/record/struct constructor access like Color.Red, Option.None
            if (ia.receiver.*.kind == .ident) {
                const receiverName = ia.receiver.*.kind.ident;
                // Check if this identifier is a registered type definition
                if (env.lookupTypeDef(receiverName)) |_| {
                    const ty = try env.namedType(receiverName);
                    // Build a typed receiver expression
                    const recvTyped = try makeTypedPtr(env, .{
                        .loc = ia.receiver.*.loc,
                        .kind = .{ .ident = receiverName },
                        .type_ = ty,
                    });
                    return makeExpr(expr.loc, .{ .identAccess = .{
                        .receiver = recvTyped,
                        .member = ia.member,
                    } }, ty);
                }
            }
            // Regular instance field access on a variable/instance
            const recvTyped = try inferExprTyped(env, ia.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            return makeExpr(expr.loc, .{ .identAccess = .{
                .receiver = recvPtr,
                .member = ia.member,
            } }, try env.freshVar());
        },

        // ── function/method calls ─────────────────────────────────────────────
        .call => |c| {
            const calleeType = if (env.lookup(c.callee)) |ty| ty else {
                env.lastError = TypeError.unboundVariable(c.callee).withLoc(expr.loc);
                return error.TypeError;
            };
            // Type all args first ---- they are visited regardless of callee shape.
            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), c.args.len);
            for (c.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            const typedTrailing = try inferTrailingLambdasTyped(env, c.trailing);
            const resolved = calleeType.deref();
            const retType: *T.Type = switch (resolved.*) {
                .func => |f| blk: {
                    if (f.params.len != c.args.len) {
                        env.lastError = TypeError.arityMismatch(c.callee, f.params.len, c.args.len).withLoc(expr.loc);
                        return error.TypeError;
                    }
                    for (typedArgs, f.params) |ta, paramType| {
                        try unifyAt(env, paramType, ta.value.type_, ta.value.loc);
                    }
                    break :blk f.ret;
                },
                .named => resolved,
                else => try env.freshVar(),
            };
            return makeExpr(expr.loc, .{ .call = .{
                .receiver = c.receiver,
                .callee = c.callee,
                .args = typedArgs,
                .trailing = typedTrailing,
            } }, retType);
        },

        // ── additive: string coercion + numeric promotion ─────────────────────
        .add => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            const resT: *T.Type = blk: {
                if (lhs.type_.isNamed("string") or rhs.type_.isNamed("string")) break :blk try env.namedType("string");
                if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
                if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
                break :blk lhs.type_;
            };
            return makeExpr(expr.loc, .{ .add = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, resT);
        },

        // ── multiplicative / sub / div / mod ─────────────────────────────────
        .mul => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            const resT: *T.Type = blk: {
                if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
                if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
                break :blk lhs.type_;
            };
            return makeExpr(expr.loc, .{ .mul = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, resT);
        },

        .sub => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            const resT: *T.Type = blk: {
                if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
                if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
                break :blk lhs.type_;
            };
            return makeExpr(expr.loc, .{ .sub = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, resT);
        },

        .div => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            const resT: *T.Type = blk: {
                if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
                if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
                break :blk lhs.type_;
            };
            return makeExpr(expr.loc, .{ .div = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, resT);
        },

        .mod => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            const resT: *T.Type = blk: {
                if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
                if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
                break :blk lhs.type_;
            };
            return makeExpr(expr.loc, .{ .mod = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, resT);
        },

        // ── ordered comparisons: unify operands, result is bool ───────────────
        .lt => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
                !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .lt = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        .gt => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
                !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .gt = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        .lte => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
                !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .lte = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        .gte => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
                !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
                try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .gte = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        // ── equality: unify operands, result is bool ──────────────────────────
        .eq => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .eq = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        .ne => |op| {
            const lhs = try inferExprTyped(env, op.lhs.*);
            const rhs = try inferExprTyped(env, op.rhs.*);
            try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
            return makeExpr(expr.loc, .{ .ne = .{
                .lhs = try makeTypedPtr(env, lhs),
                .rhs = try makeTypedPtr(env, rhs),
            } }, try env.namedType("bool"));
        },

        // ── control flow ──────────────────────────────────────────────────────
        .@"return" => |e| {
            const child = try inferExprTyped(env, e.*);
            return makeExpr(expr.loc, .{ .@"return" = try makeTypedPtr(env, child) }, child.type_);
        },

        .localBind => |lb| {
            const val = try inferExprTyped(env, lb.value.*);
            try env.bind(lb.name, val.type_);
            return makeExpr(expr.loc, .{ .localBind = .{
                .name = lb.name,
                .value = try makeTypedPtr(env, val),
                .mutable = lb.mutable,
            } }, val.type_);
        },

        .localBindDestruct => |lb| {
            const valTyped = try inferExprTyped(env, lb.value.*);
            switch (lb.pattern) {
                .record_ => |names| {
                    // Resolve the value type and validate it is a record/struct.
                    const derefed = valTyped.type_.deref();
                    const typeName = switch (derefed.*) {
                        .named => |n| n.name,
                        else => {
                            env.lastError = (TypeError.notARecord("?")).withLoc(expr.loc);
                            return error.TypeError;
                        },
                    };
                    const maybeDef = env.typeDefs.get(typeName);
                    if (maybeDef == null or maybeDef.?.fields() == null) {
                        env.lastError = (TypeError.notARecord(typeName)).withLoc(expr.loc);
                        return error.TypeError;
                    }
                    const typeDef = maybeDef.?;
                    for (names) |n| {
                        const fieldTy = if (typeDef.findField(n)) |f| f.type_ else {
                            env.lastError = (TypeError.unknownField(typeName, n)).withLoc(expr.loc);
                            return error.TypeError;
                        };
                        try env.bind(n, fieldTy);
                    }
                },
                .tuple_ => |names| {
                    // Build a tuple type with one fresh var per binding, then unify
                    // against the value type so the vars resolve to the element types.
                    const freshArgs = try env.arena.alloc(*T.Type, names.len);
                    for (freshArgs) |*a| a.* = try env.freshVar();
                    const tupleTy = try env.namedTypeArgs("tuple", freshArgs);
                    try unifyAt(env, tupleTy, valTyped.type_, expr.loc);
                    for (names, 0..) |n, i| try env.bind(n, freshArgs[i]);
                },
            }
            const valPtr = try env.arena.create(ast.TypedExpr);
            valPtr.* = valTyped;
            return makeExpr(expr.loc, .{ .localBindDestruct = .{
                .pattern = lb.pattern,
                .value = valPtr,
                .mutable = lb.mutable,
            } }, valTyped.type_);
        },

        .case => |c| {
            const subj = try inferExprTyped(env, c.subject.*);
            const arms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
            var distinct: std.ArrayListUnmanaged(*T.Type) = .empty;
            for (c.arms, 0..) |arm, i| {
                const body = try inferExprTyped(env, arm.body);
                arms[i] = .{ .pattern = arm.pattern, .body = body };
                var seen = false;
                for (distinct.items) |existing| {
                    if (typesSameShape(existing, body.type_)) {
                        seen = true;
                        break;
                    }
                }
                if (!seen) try distinct.append(env.arena, body.type_);
            }
            const resT: *T.Type = if (distinct.items.len == 0)
                try env.freshVar()
            else if (distinct.items.len == 1)
                distinct.items[0]
            else
                try env.unionType(try distinct.toOwnedSlice(env.arena));
            return makeExpr(expr.loc, .{ .case = .{
                .subject = try makeTypedPtr(env, subj),
                .arms = arms,
            } }, resT);
        },

        // ── comptime ──────────────────────────────────────────────────────────
        .@"comptime" => |e| {
            const child = try inferExprTyped(env, e.*);
            return makeExpr(expr.loc, .{ .@"comptime" = try makeTypedPtr(env, child) }, child.type_);
        },

        .comptimeBlock => |cb| {
            const body = try inferStmtsTyped(env, cb.body);
            const resT = if (body.len > 0) body[body.len - 1].expr.type_ else try env.namedType("void");
            return makeExpr(expr.loc, .{ .comptimeBlock = .{ .body = body } }, resT);
        },

        .@"break" => |e| {
            if (e) |ep| {
                const child = try inferExprTyped(env, ep.*);
                return makeExpr(expr.loc, .{ .@"break" = try makeTypedPtr(env, child) }, child.type_);
            }
            return makeExpr(expr.loc, .{ .@"break" = null }, try env.namedType("void"));
        },

        // ── lambdas ───────────────────────────────────────────────────────────
        .lambda => |l| {
            const body = try inferStmtsTyped(env, l.body);
            return makeExpr(expr.loc, .{ .lambda = .{ .params = l.params, .body = body } }, try env.freshVar());
        },

        // ── misc ──────────────────────────────────────────────────────────────
        .todo => return makeExpr(expr.loc, .todo, try env.freshVar()),

        .assign => |a| {
            const val = try inferExprTyped(env, a.value.*);
            if (env.lookup(a.name)) |ty| {
                try unifyAt(env, ty, val.type_, expr.loc);
            } else {
                env.lastError = TypeError.unboundVariable(a.name).withLoc(expr.loc);
                return error.TypeError;
            }
            return makeExpr(expr.loc, .{ .assign = .{
                .name = a.name,
                .value = try makeTypedPtr(env, val),
            } }, try env.namedType("void"));
        },

        .fieldAssign => |a| {
            const recvTyped = try inferExprTyped(env, a.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            const child = try inferExprTyped(env, a.value.*);
            return makeExpr(expr.loc, .{ .fieldAssign = .{
                .receiver = recvPtr,
                .field = a.field,
                .value = try makeTypedPtr(env, child),
            } }, try env.namedType("void"));
        },

        .fieldPlusEq => |a| {
            const recvTyped = try inferExprTyped(env, a.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            const child = try inferExprTyped(env, a.value.*);
            return makeExpr(expr.loc, .{ .fieldPlusEq = .{
                .receiver = recvPtr,
                .field = a.field,
                .value = try makeTypedPtr(env, child),
            } }, try env.namedType("void"));
        },

        .throw_ => |e| {
            const child = try inferExprTyped(env, e.*);
            return makeExpr(expr.loc, .{ .throw_ = try makeTypedPtr(env, child) }, try env.freshVar());
        },

        .null_ => {
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = try env.freshVar();
            return makeExpr(expr.loc, .null_, try env.namedTypeArgs("optional", args));
        },

        .if_ => |i| {
            const cond = try inferExprTyped(env, i.cond.*);
            const thenTyped = try env.arena.alloc(ast.StmtOf(.typed), i.then_.len);
            for (i.then_, 0..) |s, idx| {
                thenTyped[idx] = .{ .expr = try inferExprTyped(env, s.expr) };
            }
            var elseTyped: ?[]ast.StmtOf(.typed) = null;
            if (i.else_) |els| {
                const et = try env.arena.alloc(ast.StmtOf(.typed), els.len);
                for (els, 0..) |s, idx| {
                    et[idx] = .{ .expr = try inferExprTyped(env, s.expr) };
                }
                elseTyped = et;
            }
            const resT = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.type_ else try env.namedType("void");
            return makeExpr(expr.loc, .{ .if_ = .{
                .cond = try makeTypedPtr(env, cond),
                .binding = i.binding,
                .then_ = thenTyped,
                .else_ = elseTyped,
            } }, resT);
        },

        .try_ => |e| {
            const child = try inferExprTyped(env, e.*);
            // Result is the ok-payload type of the error union; use fresh var for now
            const resultT = try env.freshVar();
            return makeExpr(expr.loc, .{ .try_ = try makeTypedPtr(env, child) }, resultT);
        },

        .tryCatch => |tc| {
            const innerTyped = try inferExprTyped(env, tc.expr.*);
            const handlerTyped = try inferExprTyped(env, tc.handler.*);
            const resultT = try env.freshVar();
            return makeExpr(expr.loc, .{ .tryCatch = .{
                .expr = try makeTypedPtr(env, innerTyped),
                .handler = try makeTypedPtr(env, handlerTyped),
            } }, resultT);
        },

        .staticCall => |c| {
            const arg = try inferExprTyped(env, c.arg.*);
            return makeExpr(expr.loc, .{ .staticCall = .{
                .receiver = c.receiver,
                .method = c.method,
                .arg = try makeTypedPtr(env, arg),
            } }, try env.freshVar());
        },

        .builtinCall => |c| {
            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), c.args.len);
            for (c.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            return makeExpr(expr.loc, .{ .builtinCall = .{
                .name = c.name,
                .args = typedArgs,
            } }, try env.freshVar());
        },

        .arrayLit => |elems| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, elems.len);
            const elemTy = try env.freshVar();
            for (elems, 0..) |e, i| {
                typedElems[i] = try inferExprTyped(env, e);
                try unifyAt(env, elemTy, typedElems[i].type_, expr.loc);
            }
            const args = try env.arena.alloc(*T.Type, 1);
            args[0] = elemTy;
            return makeExpr(expr.loc, .{ .arrayLit = typedElems }, try env.namedTypeArgs("array", args));
        },

        .tupleLit => |elems| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, elems.len);
            const args = try env.arena.alloc(*T.Type, elems.len);
            for (elems, 0..) |e, i| {
                typedElems[i] = try inferExprTyped(env, e);
                args[i] = typedElems[i].type_;
            }
            return makeExpr(expr.loc, .{ .tupleLit = typedElems }, try env.namedTypeArgs("tuple", args));
        },

        .yield => |e| {
            const child = try inferExprTyped(env, e.*);
            return makeExpr(expr.loc, .{ .yield = try makeTypedPtr(env, child) }, child.type_);
        },

        .@"continue" => return makeExpr(expr.loc, .{ .@"continue" = {} }, try env.namedType("void")),

        .range => |r| {
            const startTyped = try inferExprTyped(env, r.start.*);
            const endTyped: ?*ast.TypedExpr = if (r.end) |end| blk: {
                const et = try inferExprTyped(env, end.*);
                break :blk try makeTypedPtr(env, et);
            } else null;
            return makeExpr(expr.loc, .{ .range = .{
                .start = try makeTypedPtr(env, startTyped),
                .end = endTyped,
            } }, try env.namedType("range"));
        },

        .loop => |lp| {
            const iterTyped = try inferExprTyped(env, lp.iter.*);
            const indexTyped: ?*ast.TypedExpr = if (lp.indexRange) |ir| blk: {
                const it = try inferExprTyped(env, ir.*);
                break :blk try makeTypedPtr(env, it);
            } else null;
            // Bind loop params to fresh type vars so body can reference them.
            for (lp.params) |p| {
                try env.bind(p, try env.freshVar());
            }
            const bodyTyped = try inferStmtsTyped(env, lp.body);
            // Result type: if body has yield stmts → list<T>, otherwise void.
            const elemT = try env.freshVar();
            const listArgs = try env.arena.alloc(*T.Type, 1);
            listArgs[0] = elemT;
            const resultT = try env.namedTypeArgs("list", listArgs);
            return makeExpr(expr.loc, .{ .loop = .{
                .iter = try makeTypedPtr(env, iterTyped),
                .indexRange = indexTyped,
                .params = lp.params,
                .body = bodyTyped,
            } }, resultT);
        },
    }
}

pub fn freshEnv(a: std.mem.Allocator, gpa: std.mem.Allocator) !Env {
    var e = Env.init(a);
    try e.registerBuiltins();
    try comptimeMod.registerStdlib(&e, gpa);
    try e.bind("true", try e.namedType("bool"));
    try e.bind("false", try e.namedType("bool"));
    return e;
}
