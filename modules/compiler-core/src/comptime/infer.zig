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
            const ty = typedExpr.getType();
            if (v.typeAnnotation) |ann| {
                const annType = try resolveTypeRef(env, ann);
                try unifyAt(env, annType, ty, v.value.getLoc());
            }
            try env.bind(v.name, ty);
            return .{ .name = v.name, .type_ = ty, .typedExpr = typedExpr, .decl = decl };
        },
        .@"fn" => |f| {
            const ty = try inferFnDecl(env, f);
            try env.bind(f.name, ty);
            return .{ .name = f.name, .type_ = ty, .typedExpr = null, .decl = decl };
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
            try appendTypeRefStr(&buf, env.arena, p.typeRef);
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
        try appendTypeRefStr(&buf, env.arena, p.typeRef);
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
        .function => |f| {
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, p);
            }
            try buf.appendSlice(allocator, ") -> ");
            try appendTypeRefStr(buf, allocator, f.returnType.*);
        },
    }
}

fn inferDecl(env: *Env, decl: ast.DeclKind) InferError!?Binding {
    switch (decl) {
        .val => |v| {
            const ty = try inferExpr(env, v.value.*);
            if (v.typeAnnotation) |ann| {
                const annType = try resolveTypeRef(env, ann);
                try unifyAt(env, annType, ty, v.value.getLoc());
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
        const ty = try resolveTypeRefInContext(env, p.typeRef, genericMap);
        paramTypes[i] = ty;
        if (p.destruct) |d| {
            // Destructuring param: bind each field name to its type.
            const tyName: []const u8 = switch (p.typeRef) {
                .named => |n| n,
                else => "",
            };
            const maybeTypeDef = env.typeDefs.get(tyName);
            switch (d) {
                .names => |*n| {
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeTypeDef) |td|
                            if (td.findField(fld.field_name)) |f_| f_.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    // For tuple destructuring, we'd need the tuple element types.
                    // For now, bind each name to a fresh type variable.
                    for (t) |fname| {
                        try env.bind(fname, try env.freshVar());
                    }
                },
                .list => {}, // List destructuring — no bindings to infer
                .ctor => {}, // Constructor destructuring — handled by pattern matching
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
        .function => |f| {
            // For function types, resolve params and return type
            const paramTypes = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| {
                paramTypes[i] = try resolveTypeRefInContext(env, p, genericMap);
            }
            const returnType = try resolveTypeRefInContext(env, f.returnType.*, genericMap);
            const args = try env.arena.alloc(*T.Type, f.params.len + 1);
            for (f.params, 0..) |_, i| args[i] = paramTypes[i];
            args[f.params.len] = returnType;
            return env.namedTypeArgs("function", args);
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
    return (try inferExprTyped(env, expr)).getType();
}

// ── typed expression construction ─────────────────────────────────────────────

const TypedExpr = ast.TypedExpr;
const TypedStmt = ast.StmtOf(.typed);

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
    return switch (expr) {
        // ── literals ──────────────────────────────────────────────────────────
        .literal => |l| inferLiteralExpr(env, l, l.loc),

        // ── identifiers ───────────────────────────────────────────────────────
        .identifier => |i| inferIdentifierExpr(env, i, i.loc),

        // ── binary operations ───────────────────────────────────────────────────
        .binaryOp => |b| inferBinaryOpExpr(env, b, b.loc),

        // ── unary operations ──────────────────────────────────────────────────
        .unaryOp => |u| inferUnaryOpExpr(env, u, u.loc),

        // ── control flow ──────────────────────────────────────────────────────
        .controlFlow => |c| inferControlFlowExpr(env, c, c.loc),

        // ── binding expressions ────────────────────────────────────────────────
        .binding => |b| inferBindingExpr(env, b, b.loc),

        // ── call expressions ───────────────────────────────────────────────────
        .call => |c| inferCallExpr(env, c, c.loc),

        // ── function definition expressions ────────────────────────────────────
        .function => |f| inferFunctionExpr(env, f, f.loc),

        // ── collection expressions ─────────────────────────────────────────────
        .collection => |co| inferCollectionExpr(env, co, co.loc),

        // ── comptime expressions ───────────────────────────────────────────────
        .comptime_ => |a| inferComptimeExpr(env, a, a.loc),
    };
}

// ── Helper functions for each expression category ───────────────────────────

/// Infer type for literal expressions (strings, numbers, null, comments)
fn inferLiteralExpr(env: *Env, lit: ast.LiteralExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (lit.kind) {
        .stringLit => |s| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("string"), .kind = .{ .stringLit = s } } },
        .numberLit => |n| blk: {
            const isFloat = std.mem.indexOfScalar(u8, n, '.') != null;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType(if (isFloat) "f64" else "i32"), .kind = .{ .numberLit = n } } };
        },
        .null_ => blk: {
            const innerVar = try env.freshVar();
            const optArgs = try env.arena.alloc(*T.Type, 1);
            optArgs[0] = innerVar;
            break :blk TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedTypeArgs("optional", optArgs), .kind = .null_ } };
        },
        .comment => |c| TypedExpr{ .literal = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .comment = c } } },
    };
}

/// Infer type for identifier expressions (ident, dotIdent, identAccess)
fn inferIdentifierExpr(env: *Env, ident: ast.IdentifierExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ident.kind) {
        .ident => |name| {
            if (env.lookup(name)) |ty| return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .ident = name } } };
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .dotIdent => |name| {
            if (env.lookup(name)) |ty| return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .dotIdent = name } } };
            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
            return error.TypeError;
        },
        .identAccess => |ia| {
            // When receiver is an identifier, check if it's a type name rather than a variable.
            // This handles enum/record/struct constructor access like Color.Red, Option.None
            if (ia.receiver.* == .identifier) {
                if (ia.receiver.*.identifier.kind == .ident) {
                    const receiverName = ia.receiver.*.identifier.kind.ident;
                    // Check if this identifier is a registered type definition
                    if (env.lookupTypeDef(receiverName)) |_| {
                        const ty = try env.namedType(receiverName);
                        const recvTyped = try makeTypedPtr(env, TypedExpr{ .identifier = .{
                            .loc = ia.receiver.*.getLoc(),
                            .type_ = ty,
                            .kind = .{ .ident = receiverName },
                        } });
                        return TypedExpr{ .identifier = .{ .loc = loc, .type_ = ty, .kind = .{ .identAccess = .{
                            .receiver = recvTyped,
                            .member = ia.member,
                        } } } };
                    }
                }
            }
            // Regular instance field access on a variable/instance
            const recvTyped = try inferExprTyped(env, ia.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            return TypedExpr{ .identifier = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .identAccess = .{
                .receiver = recvPtr,
                .member = ia.member,
            } } } };
        },
    };
}

/// Infer type for binary operation expressions
fn inferBinaryOpExpr(env: *Env, binop: ast.BinOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    // Extract the BinOp struct (all variants have the same structure)
    const op = switch (binop.kind) {
        .lt => |v| v,
        .gt => |v| v,
        .lte => |v| v,
        .gte => |v| v,
        .eq => |v| v,
        .ne => |v| v,
        .add => |v| v,
        .sub => |v| v,
        .mul => |v| v,
        .div => |v| v,
        .mod => |v| v,
        .@"and" => |v| v,
        .@"or" => |v| v,
    };

    const lhsTyped = try inferExprTyped(env, op.lhs.*);
    const rhsTyped = try inferExprTyped(env, op.rhs.*);
    const lhsPtr = try makeTypedPtr(env, lhsTyped);
    const rhsPtr = try makeTypedPtr(env, rhsTyped);

    // Determine result type based on operator
    const resultType: *T.Type = switch (binop.kind) {
        .lt, .gt, .lte, .gte, .eq, .ne => try env.namedType("bool"),
        .@"and", .@"or" => blk: {
            try unifyAt(env, lhsTyped.getType(), try env.namedType("bool"), loc);
            try unifyAt(env, rhsTyped.getType(), try env.namedType("bool"), loc);
            break :blk try env.namedType("bool");
        },
        .add => blk: {
            // String + anything → string (coercion)
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            if (lhsTy.isNamed("string") or rhsTy.isNamed("string")) break :blk try env.namedType("string");
            // Numeric promotion: float wins over int
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
        .sub, .mul, .div, .mod => blk: {
            const lhsTy = lhsTyped.getType();
            const rhsTy = rhsTyped.getType();
            if (isFloatType(lhsTy) and isIntType(rhsTy)) break :blk lhsTy;
            if (isIntType(lhsTy) and isFloatType(rhsTy)) break :blk rhsTy;
            try unify(env, lhsTy, rhsTy);
            break :blk lhsTy;
        },
    };

    // Reconstruct the same binary op variant with typed operands
    return switch (binop.kind) {
        .lt => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .lt = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .gt => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .gt = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .lte => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .lte = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .gte => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .gte = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .eq => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .eq = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .ne => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .ne = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .add => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .add = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .sub => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .sub = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .mul => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .mul = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .div => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .div = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .mod => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .mod = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .@"and" => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .@"and" = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
        .@"or" => TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{ .@"or" = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } },
    };
}

/// Infer type for unary operation expressions
fn inferUnaryOpExpr(env: *Env, unaryop: ast.UnaryOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const operandTyped = try inferExprTyped(env, switch (unaryop.kind) {
        .not => |e| e.*,
        .neg => |e| e.*,
    });
    const operandPtr = try makeTypedPtr(env, operandTyped);

    return switch (unaryop.kind) {
        .not => blk: {
            try unifyAt(env, operandTyped.getType(), try env.namedType("bool"), loc);
            break :blk TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = try env.namedType("bool"), .kind = .{ .not = operandPtr } } };
        },
        .neg => TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = operandTyped.getType(), .kind = .{ .neg = operandPtr } } },
    };
}

/// Infer type for control flow expressions (branching, error propagation, iteration)
fn inferControlFlowExpr(env: *Env, cf: ast.ControlFlowExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (cf.kind) {
        .if_ => |i| {
            const condTyped = try inferExprTyped(env, i.cond.*);
            const condPtr = try makeTypedPtr(env, condTyped);

            if (i.binding) |binding_name| {
                // Null-check form: `if (x) { e -> ... }` — condition is optional, not bool.
                // Bind the unwrapped inner type to `binding_name`.
                const condTy = condTyped.getType().deref();
                const innerTy: *T.Type = switch (condTy.*) {
                    .named => |n| if (std.mem.eql(u8, n.name, "optional") and n.args.len == 1)
                        n.args[0]
                    else
                        try env.freshVar(),
                    else => try env.freshVar(),
                };
                try env.bind(binding_name, innerTy);
            } else {
                try unifyAt(env, try env.namedType("bool"), condTyped.getType(), loc);
            }

            const thenTyped = try inferStmtsTyped(env, i.then_);
            const elseTyped = if (i.else_) |els| try inferStmtsTyped(env, els) else null;

            const bodyType = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.getType() else try env.namedType("void");
            const elseType = if (elseTyped) |els| blk: {
                if (els.len > 0) break :blk els[els.len - 1].expr.getType();
                break :blk try env.namedType("void");
            } else try env.namedType("void");

            if (elseTyped != null) {
                try unify(env, bodyType, elseType);
            }
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = bodyType, .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = i.binding,
                .then_ = thenTyped,
                .else_ = elseTyped,
            } } } };
        },

        .@"return" => |r| {
            const valTyped = try inferExprTyped(env, r.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"return" = valPtr } } };
        },

        .throw_ => |e| {
            const valTyped = try inferExprTyped(env, e.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .throw_ = valPtr } } };
        },

        .try_ => |e| {
            const valTyped = try inferExprTyped(env, e.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .try_ = valPtr } } };
        },

        .tryCatch => |tc| {
            const exprTyped = try inferExprTyped(env, tc.expr.*);
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerTyped = try inferExprTyped(env, tc.handler.*);
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            // Skip unification when the handler diverges (throw/return → void type).
            if (!handlerTyped.getType().isNamed("void")) {
                try unify(env, exprTyped.getType(), handlerTyped.getType());
            }
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = exprTyped.getType(), .kind = .{ .tryCatch = .{
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },

        .loop => |lp| {
            const iterTyped = try inferExprTyped(env, lp.iter.*);
            const iterPtr = try makeTypedPtr(env, iterTyped);
            const indexRangePtr = if (lp.indexRange) |ir| try makeTypedPtr(env, try inferExprTyped(env, ir.*)) else null;

            for (lp.params) |p| {
                try env.bind(p, try env.freshVar());
            }

            const typedBody = try inferStmtsTyped(env, lp.body);
            const loopArrayArgs = try env.arena.alloc(*T.Type, 1);
            loopArrayArgs[0] = try env.freshVar();
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedTypeArgs("array", loopArrayArgs), .kind = .{ .loop = .{
                .iter = iterPtr,
                .indexRange = indexRangePtr,
                .params = lp.params,
                .body = typedBody,
            } } } };
        },

        .@"break" => |e| {
            if (e) |expr| {
                const typed = try inferExprTyped(env, expr.*);
                const typedPtr = try makeTypedPtr(env, typed);
                return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = typedPtr } } };
            } else {
                return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = null } } };
            }
        },

        .@"continue" => TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .@"continue" } },

        .yield => |e| {
            const typed = try inferExprTyped(env, e.*);
            const typedPtr = try makeTypedPtr(env, typed);
            return TypedExpr{ .controlFlow = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .yield = typedPtr } } };
        },
    };
}

/// Infer type for binding expressions (variable declarations and assignments)
fn inferBindingExpr(env: *Env, b: ast.BindingExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
        .localBind => |lb| {
            const valTyped = try inferExprTyped(env, lb.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            try env.bind(lb.name, valTyped.getType());
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBind = .{
                .name = lb.name,
                .value = valPtr,
                .mutable = lb.mutable,
            } } } };
        },

        .assign => |a| {
            const valTyped = try inferExprTyped(env, a.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            if (env.lookup(a.name)) |ty| {
                try unifyAt(env, ty, valTyped.getType(), loc);
            } else {
                env.lastError = TypeError.unboundVariable(a.name).withLoc(loc);
                return error.TypeError;
            }
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .assign = .{
                .name = a.name,
                .value = valPtr,
            } } } };
        },

        .assignPlus => |a| {
            const valTyped = try inferExprTyped(env, a.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            if (env.lookup(a.name)) |ty| {
                try unifyAt(env, ty, valTyped.getType(), loc);
            } else {
                env.lastError = TypeError.unboundVariable(a.name).withLoc(loc);
                return error.TypeError;
            }
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .assignPlus = .{
                .name = a.name,
                .value = valPtr,
            } } } };
        },

        .fieldAssign => |fa| {
            const recvTyped = try inferExprTyped(env, fa.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            const valTyped = try inferExprTyped(env, fa.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .fieldAssign = .{
                .receiver = recvPtr,
                .field = fa.field,
                .value = valPtr,
            } } } };
        },

        .fieldPlusEq => |fp| {
            const recvTyped = try inferExprTyped(env, fp.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            const valTyped = try inferExprTyped(env, fp.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .fieldPlusEq = .{
                .receiver = recvPtr,
                .field = fp.field,
                .value = valPtr,
            } } } };
        },

        .localBindDestruct => |lb| {
            const valTyped = try inferExprTyped(env, lb.value.*);
            const valPtr = try makeTypedPtr(env, valTyped);
            // Bind destructured names into the environment.
            const derefedTy = valTyped.getType().deref();
            switch (lb.pattern) {
                .names => |n| {
                    const typeName: []const u8 = switch (derefedTy.*) {
                        .named => |nm| nm.name,
                        else => "",
                    };
                    const maybeDef = env.typeDefs.get(typeName);
                    // For concrete named types that are not records/structs, reject destructuring.
                    if (maybeDef == null and typeName.len > 0 and derefedTy.* == .named) {
                        env.lastError = TypeError.notARecord(typeName).withLoc(loc);
                        return error.TypeError;
                    }
                    for (n.fields) |fld| {
                        const fieldTy = if (maybeDef) |td|
                            if (td.findField(fld.field_name)) |f| f.type_ else try env.freshVar()
                        else
                            try env.freshVar();
                        try env.bind(fld.bind_name, fieldTy);
                    }
                },
                .tuple_ => |t| {
                    const tupleArgs: []*T.Type = switch (derefedTy.*) {
                        .named => |n| if (std.mem.eql(u8, n.name, "tuple")) n.args else &.{},
                        else => &.{},
                    };
                    for (t, 0..) |nm, i| {
                        const elemTy = if (i < tupleArgs.len) tupleArgs[i] else try env.freshVar();
                        try env.bind(nm, elemTy);
                    }
                },
                .list => |pat| {
                    // Bind pattern variable names to fresh type vars.
                    switch (pat) {
                        .ident => |name| try env.bind(name, try env.freshVar()),
                        .variantFields => |vf| for (vf.bindings) |binding| try env.bind(binding, try env.freshVar()),
                        else => {},
                    }
                },
                .ctor => |pat| {
                    switch (pat) {
                        .ident => |name| try env.bind(name, try env.freshVar()),
                        .variantFields => |vf| for (vf.bindings) |binding| try env.bind(binding, try env.freshVar()),
                        else => {},
                    }
                },
            }
            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .localBindDestruct = .{
                .pattern = lb.pattern,
                .value = valPtr,
                .mutable = lb.mutable,
            } } } };
        },
    };
}

/// Infer type for call expressions (function/method invocations and pipelines)
fn inferCallExpr(env: *Env, c: ast.CallExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (c.kind) {
        .call => |call| {
            const calleeType = if (env.lookup(call.callee)) |ty| ty else {
                env.lastError = TypeError.unboundVariable(call.callee).withLoc(loc);
                return error.TypeError;
            };
            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
            for (call.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);
            const resolved = calleeType.deref();
            const retType: *T.Type = switch (resolved.*) {
                .func => |f| blk: {
                    if (f.params.len != call.args.len) {
                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                        return error.TypeError;
                    }
                    for (typedArgs, f.params) |ta, paramType| {
                        try unifyAt(env, paramType, ta.value.getType(), ta.value.getLoc());
                    }
                    break :blk f.ret;
                },
                .named => resolved,
                else => try env.freshVar(),
            };
            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                .receiver = call.receiver,
                .callee = call.callee,
                .args = typedArgs,
                .trailing = typedTrailing,
            } } } };
        },

        .staticCall => |sc| {
            const recvTyped = try inferExprTyped(env, sc.arg.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            return TypedExpr{ .call = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .staticCall = .{
                .receiver = sc.receiver,
                .method = sc.method,
                .arg = recvPtr,
            } } } };
        },

        .builtinCall => |bc| {
            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), bc.args.len);
            for (bc.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            return TypedExpr{ .call = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .builtinCall = .{
                .name = bc.name,
                .args = typedArgs,
            } } } };
        },

        .pipeline => |p| {
            const lhsTyped = try inferExprTyped(env, p.lhs.*);
            const lhsPtr = try makeTypedPtr(env, lhsTyped);
            // When the RHS is a plain call, the LHS value is the first argument.
            // Build the typed RHS manually to avoid the arity check in inferCallExpr.
            if (p.rhs.* == .call and p.rhs.*.call.kind == .call) {
                const call = p.rhs.*.call.kind.call;
                const calleeType = if (env.lookup(call.callee)) |ty| ty else try env.freshVar();
                const resolved = calleeType.deref();
                const retType: *T.Type = switch (resolved.*) {
                    .func => |f| blk: {
                        const totalArgs = call.args.len + 1;
                        if (f.params.len == totalArgs) {
                            try unifyAt(env, f.params[0], lhsTyped.getType(), loc);
                            for (call.args, 1..) |arg, i| {
                                const argTyped = try inferExprTyped(env, arg.value.*);
                                try unifyAt(env, f.params[i], argTyped.getType(), loc);
                            }
                        }
                        break :blk f.ret;
                    },
                    else => try env.freshVar(),
                };
                // Build a typed call node for the RHS (with pipeline arity).
                const typedCallArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
                for (call.args, 0..) |arg, i| {
                    const val = try inferExprTyped(env, arg.value.*);
                    typedCallArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
                }
                const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);
                const rhsNode = TypedExpr{ .call = .{ .loc = p.rhs.*.getLoc(), .type_ = retType, .kind = .{ .call = .{
                    .receiver = call.receiver,
                    .callee = call.callee,
                    .args = typedCallArgs,
                    .trailing = typedTrailing,
                } } } };
                const rhsPtr = try makeTypedPtr(env, rhsNode);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .pipeline = .{
                    .lhs = lhsPtr,
                    .rhs = rhsPtr,
                    .comment = p.comment,
                } } } };
            }
            const rhsTyped = try inferExprTyped(env, p.rhs.*);
            const rhsPtr = try makeTypedPtr(env, rhsTyped);
            return TypedExpr{ .call = .{ .loc = loc, .type_ = rhsTyped.getType(), .kind = .{ .pipeline = .{
                .lhs = lhsPtr,
                .rhs = rhsPtr,
                .comment = p.comment,
            } } } };
        },
    };
}

/// Infer type for function definition expressions (lambdas and anonymous functions)
fn inferFunctionExpr(env: *Env, func: ast.FunctionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (func.kind) {
        .lambda => |l| {
            const params = try env.arena.alloc(*T.Type, l.params.len);
            for (l.params, 0..) |p, i| {
                params[i] = try env.freshVar();
                try env.bind(p, params[i]);
            }
            const bodyTyped = try inferStmtsTyped(env, l.body);
            const retType = if (bodyTyped.len > 0) bodyTyped[bodyTyped.len - 1].expr.getType() else try env.namedType("void");
            const funcType = try env.funcType(params, retType);
            return TypedExpr{ .function = .{ .loc = loc, .type_ = funcType, .kind = .{ .lambda = .{
                .params = l.params,
                .body = bodyTyped,
            } } } };
        },

        .fnExpr => |f| {
            const params = try env.arena.alloc(*T.Type, f.params.len);
            for (f.params, 0..) |p, i| {
                params[i] = try env.freshVar();
                try env.bind(p, params[i]);
            }
            const bodyTyped = try inferStmtsTyped(env, f.body);
            const retType = if (bodyTyped.len > 0) bodyTyped[bodyTyped.len - 1].expr.getType() else try env.namedType("void");
            const funcType = try env.funcType(params, retType);
            return TypedExpr{ .function = .{ .loc = loc, .type_ = funcType, .kind = .{ .fnExpr = .{
                .params = f.params,
                .body = bodyTyped,
            } } } };
        },
    };
}

/// Infer type for collection expressions (arrays, tuples, ranges, case, block, grouped)
fn inferCollectionExpr(env: *Env, col: ast.CollectionExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (col.kind) {
        .arrayLit => |al| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, al.elems.len);
            for (al.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTyped(env, elem);
            }
            const elemType = if (typedElems.len > 0) typedElems[0].getType() else try env.freshVar();
            for (typedElems) |elem| {
                try unify(env, elemType, elem.getType());
            }
            const arrayArgs = try env.arena.alloc(*T.Type, 1);
            arrayArgs[0] = elemType;
            const arrayType = try env.namedTypeArgs("array", arrayArgs);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = arrayType, .kind = .{ .arrayLit = .{
                .elems = typedElems,
                .spread = al.spread,
                .spreadExpr = if (al.spreadExpr) |se| try makeTypedPtr(env, try inferExprTyped(env, se.*)) else null,
                .comments = al.comments,
                .commentsPerElem = al.commentsPerElem,
                .trailingComma = al.trailingComma,
            } } } };
        },

        .tupleLit => |tl| {
            const typedElems = try env.arena.alloc(ast.TypedExpr, tl.elems.len);
            const elemTypes = try env.arena.alloc(*T.Type, tl.elems.len);
            for (tl.elems, 0..) |elem, i| {
                typedElems[i] = try inferExprTyped(env, elem);
                elemTypes[i] = typedElems[i].getType();
            }
            const tupleType = try env.namedTypeArgs("tuple", elemTypes);
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = tupleType, .kind = .{ .tupleLit = .{
                .elems = typedElems,
                .comments = tl.comments,
                .commentsPerElem = tl.commentsPerElem,
            } } } };
        },

        .range => |r| {
            const startTyped = try inferExprTyped(env, r.start.*);
            const startPtr = try makeTypedPtr(env, startTyped);
            const endPtr = if (r.end) |e| try makeTypedPtr(env, try inferExprTyped(env, e.*)) else null;
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.namedType("Range"), .kind = .{ .range = .{
                .start = startPtr,
                .end = endPtr,
            } } } };
        },

        .case => |c| {
            const typedSubjects = try env.arena.alloc(ast.TypedExpr, c.subjects.len);
            for (c.subjects, 0..) |subj, i| {
                typedSubjects[i] = try inferExprTyped(env, subj);
            }
            const typedArms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
            for (c.arms, 0..) |arm, i| {
                typedArms[i] = .{
                    .pattern = arm.pattern,
                    .body = try inferExprTyped(env, arm.body),
                    .emptyLinesBefore = arm.emptyLinesBefore,
                };
            }
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .case = .{
                .subjects = typedSubjects,
                .arms = typedArms,
                .trailingComments = c.trailingComments,
            } } } };
        },

        .block => |b| {
            const typedBody = try inferStmtsTyped(env, b.body);
            const bodyType = if (typedBody.len > 0) typedBody[typedBody.len - 1].expr.getType() else try env.namedType("void");
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = bodyType, .kind = .{ .block = .{
                .body = typedBody,
            } } } };
        },

        .grouped => |e| {
            return try inferExprTyped(env, e.*);
        },
    };
}

/// Infer type for comptime expressions (comptime, assert, assertPattern).
fn inferComptimeExpr(env: *Env, ct: ast.ComptimeExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    return switch (ct.kind) {
        .comptimeExpr => |e| {
            const typed = try inferExprTyped(env, e.*);
            const typedPtr = try makeTypedPtr(env, typed);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = typed.getType(), .kind = .{ .comptimeExpr = typedPtr } } };
        },

        .comptimeBlock => |cb| {
            const typedBody = try inferStmtsTyped(env, cb.body);
            const bodyType = if (typedBody.len > 0) typedBody[typedBody.len - 1].expr.getType() else try env.namedType("void");
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = bodyType, .kind = .{ .comptimeBlock = .{
                .body = typedBody,
            } } } };
        },

        .@"assert" => |a| {
            const condTyped = try inferExprTyped(env, a.condition.*);
            const condPtr = try makeTypedPtr(env, condTyped);
            const msgPtr = if (a.message) |msg| try makeTypedPtr(env, try inferExprTyped(env, msg.*)) else null;
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"assert" = .{
                .condition = condPtr,
                .message = msgPtr,
            } } } };
        },

        .assertPattern => |ap| {
            // Use a fresh type variable when the expression can't be inferred (e.g. unbound var).
            const exprTyped = inferExprTyped(env, ap.expr.*) catch |err| blk: {
                if (err != error.TypeError) return err;
                const freshTy = try env.freshVar();
                break :blk TypedExpr{ .literal = .{ .loc = ap.expr.getLoc(), .type_ = freshTy, .kind = .null_ } };
            };
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerExpr = ap.handler.*;
            const handlerTyped = inferExprTyped(env, handlerExpr) catch |err| blk: {
                if (err != error.TypeError) return err;
                const freshTy = try env.freshVar();
                break :blk TypedExpr{ .literal = .{ .loc = handlerExpr.getLoc(), .type_ = freshTy, .kind = .null_ } };
            };
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = exprTyped.getType(), .kind = .{ .assertPattern = .{
                .pattern = ap.pattern,
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },
    };
}

// ── Legacy inferExprTyped (kept for reference during migration) ────────────────
// TODO: Remove this after migration is complete
// COMMENTED OUT: Uses old flat AST structure that no longer exists
//
// The function below has been removed because it used the old flat AST structure.
// The new inferExprTyped function uses the hierarchical AST structure with categories.

// /// OLD VERSION - kept for reference
// /// Infer the type of `expr` AND build the fully-annotated `TypedExpr` in one
// /// pass.  Every child node is recursively typed before its parent is built, so
// /// no expression is visited more than once.  All allocations go into env.arena.
// pub fn inferExprTyped_OLD(env: *Env, expr: ast.Expr) InferError!TypedExpr {
//     switch (expr.kind) {
//         // ── literals ──────────────────────────────────────────────────────────
//         .stringLit => |s| return makeExpr(expr.loc, .{ .stringLit = s }, try env.namedType("string")),
// 
//         .numberLit => |n| {
//             const isFloat = std.mem.indexOfScalar(u8, n, '.') != null;
//             return makeExpr(expr.loc, .{ .numberLit = n }, try env.namedType(if (isFloat) "f64" else "i32"));
//         },
// 
//         // ── comments are void-typed expressions (no runtime value) ────────────
//         .comment => |c| {
//             return makeExpr(expr.loc, .{ .comment = c }, try env.namedType("void"));
//         },
// 
//         // ── identifiers ───────────────────────────────────────────────────────
//         .ident => |name| {
//             if (env.lookup(name)) |ty| return makeExpr(expr.loc, .{ .ident = name }, ty);
//             env.lastError = TypeError.unboundVariable(name).withLoc(expr.loc);
//             return error.TypeError;
//         },
// 
//         .dotIdent => |name| {
//             if (env.lookup(name)) |ty| return makeExpr(expr.loc, .{ .dotIdent = name }, ty);
//             env.lastError = TypeError.unboundVariable(name).withLoc(expr.loc);
//             return error.TypeError;
//         },
// 
//         .identAccess => |ia| {
//             // When receiver is an identifier, check if it's a type name rather than a variable.
//             // This handles enum/record/struct constructor access like Color.Red, Option.None
//             if (ia.receiver.*.kind == .ident) {
//                 const receiverName = ia.receiver.*.kind.ident;
//                 // Check if this identifier is a registered type definition
//                 if (env.lookupTypeDef(receiverName)) |_| {
//                     const ty = try env.namedType(receiverName);
//                     // Build a typed receiver expression
//                     const recvTyped = try makeTypedPtr(env, .{
//                         .loc = ia.receiver.*.loc,
//                         .kind = .{ .ident = receiverName },
//                         .type_ = ty,
//                     });
//                     return makeExpr(expr.loc, .{ .identAccess = .{
//                         .receiver = recvTyped,
//                         .member = ia.member,
//                     } }, ty);
//                 }
//             }
//             // Regular instance field access on a variable/instance
//             const recvTyped = try inferExprTyped(env, ia.receiver.*);
//             const recvPtr = try makeTypedPtr(env, recvTyped);
//             return makeExpr(expr.loc, .{ .identAccess = .{
//                 .receiver = recvPtr,
//                 .member = ia.member,
//             } }, try env.freshVar());
//         },
// 
//         // ── function/method calls ─────────────────────────────────────────────
//         .call => |c| {
//             const calleeType = if (env.lookup(c.callee)) |ty| ty else {
//                 env.lastError = TypeError.unboundVariable(c.callee).withLoc(expr.loc);
//                 return error.TypeError;
//             };
//             // Type all args first ---- they are visited regardless of callee shape.
//             const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), c.args.len);
//             for (c.args, 0..) |arg, i| {
//                 const val = try inferExprTyped(env, arg.value.*);
//                 typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
//             }
//             const typedTrailing = try inferTrailingLambdasTyped(env, c.trailing);
//             const resolved = calleeType.deref();
//             const retType: *T.Type = switch (resolved.*) {
//                 .func => |f| blk: {
//                     // Strict arity check for regular calls
//                     // Pipeline expressions handle their own arity checking separately
//                     if (f.params.len != c.args.len) {
//                         env.lastError = TypeError.arityMismatch(c.callee, f.params.len, c.args.len).withLoc(expr.loc);
//                         return error.TypeError;
//                     }
//                     // Type-check provided args against corresponding params
//                     for (typedArgs, f.params) |ta, paramType| {
//                         try unifyAt(env, paramType, ta.value.type_, ta.value.loc);
//                     }
//                     break :blk f.ret;
//                 },
//                 .named => resolved,
//                 else => try env.freshVar(),
//             };
//             return makeExpr(expr.loc, .{ .call = .{
//                 .receiver = c.receiver,
//                 .callee = c.callee,
//                 .args = typedArgs,
//                 .trailing = typedTrailing,
//             } }, retType);
//         },
// 
//         // ── additive: string coercion + numeric promotion ─────────────────────
//         .add => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             const resT: *T.Type = blk: {
//                 if (lhs.type_.isNamed("string") or rhs.type_.isNamed("string")) break :blk try env.namedType("string");
//                 if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
//                 if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//                 break :blk lhs.type_;
//             };
//             return makeExpr(expr.loc, .{ .add = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, resT);
//         },
// 
//         // ── multiplicative / sub / div / mod ─────────────────────────────────
//         .mul => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             const resT: *T.Type = blk: {
//                 if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
//                 if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//                 break :blk lhs.type_;
//             };
//             return makeExpr(expr.loc, .{ .mul = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, resT);
//         },
// 
//         .sub => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             const resT: *T.Type = blk: {
//                 if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
//                 if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//                 break :blk lhs.type_;
//             };
//             return makeExpr(expr.loc, .{ .sub = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, resT);
//         },
// 
//         .div => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             const resT: *T.Type = blk: {
//                 if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
//                 if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//                 break :blk lhs.type_;
//             };
//             return makeExpr(expr.loc, .{ .div = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, resT);
//         },
// 
//         .mod => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             const resT: *T.Type = blk: {
//                 if (isFloatType(lhs.type_) and isIntType(rhs.type_)) break :blk lhs.type_;
//                 if (isIntType(lhs.type_) and isFloatType(rhs.type_)) break :blk rhs.type_;
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//                 break :blk lhs.type_;
//             };
//             return makeExpr(expr.loc, .{ .mod = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, resT);
//         },
// 
//         // ── ordered comparisons: unify operands, result is bool ───────────────
//         .lt => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
//                 !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .lt = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         .gt => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
//                 !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .gt = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         .lte => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
//                 !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .lte = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         .gte => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             if (!(isFloatType(lhs.type_) and isIntType(rhs.type_)) and
//                 !(isIntType(lhs.type_) and isFloatType(rhs.type_)))
//                 try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .gte = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         // ── equality: unify operands, result is bool ──────────────────────────
//         .eq => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .eq = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         .ne => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             try unifyAt(env, lhs.type_, rhs.type_, expr.loc);
//             return makeExpr(expr.loc, .{ .ne = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         // ── logical operators: both operands and result must be bool ──────────
//         .@"and" => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             try unifyAt(env, lhs.type_, try env.namedType("bool"), expr.loc);
//             try unifyAt(env, rhs.type_, try env.namedType("bool"), expr.loc);
//             return makeExpr(expr.loc, .{ .@"and" = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         .@"or" => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             try unifyAt(env, lhs.type_, try env.namedType("bool"), expr.loc);
//             try unifyAt(env, rhs.type_, try env.namedType("bool"), expr.loc);
//             return makeExpr(expr.loc, .{ .@"or" = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//             } }, try env.namedType("bool"));
//         },
// 
//         // ── logical not: operand must be bool, result is bool ─────────────────
//         .not => |operand| {
//             const child = try inferExprTyped(env, operand.*);
//             try unifyAt(env, child.type_, try env.namedType("bool"), expr.loc);
//             return makeExpr(expr.loc, .{ .not = try makeTypedPtr(env, child) }, try env.namedType("bool"));
//         },
// 
//         // ── unary negation: operand must be numeric, result is same type ──────
//         .neg => |operand| {
//             const child = try inferExprTyped(env, operand.*);
//             try unifyAt(env, child.type_, try env.namedType("i32"), expr.loc);
//             return makeExpr(expr.loc, .{ .neg = try makeTypedPtr(env, child) }, try env.namedType("i32"));
//         },
// 
//         // ── pipeline: lhs value flows as first arg to rhs function ────────────
//         .pipeline => |op| {
//             const lhs = try inferExprTyped(env, op.lhs.*);
//             // If RHS is a call, we need to verify that the function can accept lhs as first arg
//             // and construct a typed call expression with the pipeline argument added
//             if (op.rhs.kind == .call) {
//                 const c = op.rhs.kind.call;
//                 // Get the function type
//                 const calleeType = if (env.lookup(c.callee)) |ty| ty else {
//                     env.lastError = TypeError.unboundVariable(c.callee).withLoc(op.rhs.loc);
//                     return error.TypeError;
//                 };
//                 const resolved = calleeType.deref();
//                 if (resolved.* == .func) {
//                     const funcType = resolved.func;
//                     // Check arity: function should expect (args.len + 1) parameters
//                     // because lhs will be passed as the first argument
//                     if (funcType.params.len != c.args.len + 1) {
//                         env.lastError = TypeError.arityMismatch(c.callee, funcType.params.len, c.args.len + 1).withLoc(expr.loc);
//                         return error.TypeError;
//                     }
//                     // Check that lhs type matches first parameter type
//                     try unifyAt(env, funcType.params[0], lhs.type_, op.lhs.loc);
// 
//                     // Type-check the remaining arguments against the remaining parameters
//                     const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), c.args.len);
//                     for (c.args, funcType.params[1..], 0..) |arg, paramType, i| {
//                         const typedArg = try inferExprTyped(env, arg.value.*);
//                         try unifyAt(env, paramType, typedArg.type_, arg.value.loc);
//                         typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, typedArg) };
//                     }
// 
//                     // Construct the typed call expression (as if all args including lhs were provided)
//                     const typedCall = makeExpr(op.rhs.loc, .{ .call = .{
//                         .receiver = c.receiver,
//                         .callee = c.callee,
//                         .args = typedArgs,
//                         .trailing = &.{},
//                     }}, funcType.ret);
// 
//                     return makeExpr(expr.loc, .{ .pipeline = .{
//                         .lhs = try makeTypedPtr(env, lhs),
//                         .rhs = try makeTypedPtr(env, typedCall),
//                         .comment = op.comment,
//                     }}, funcType.ret);
//                 }
//             }
//             const rhs = try inferExprTyped(env, op.rhs.*);
//             return makeExpr(expr.loc, .{ .pipeline = .{
//                 .lhs = try makeTypedPtr(env, lhs),
//                 .rhs = try makeTypedPtr(env, rhs),
//                 .comment = op.comment,
//             } }, rhs.type_);
//         },
// 
//         // ── control flow ──────────────────────────────────────────────────────
//         .@"return" => |e| {
//             const child = try inferExprTyped(env, e.*);
//             return makeExpr(expr.loc, .{ .@"return" = try makeTypedPtr(env, child) }, child.type_);
//         },
// 
//         .localBind => |lb| {
//             const val = try inferExprTyped(env, lb.value.*);
//             try env.bind(lb.name, val.type_);
//             return makeExpr(expr.loc, .{ .localBind = .{
//                 .name = lb.name,
//                 .value = try makeTypedPtr(env, val),
//                 .mutable = lb.mutable,
//             } }, val.type_);
//         },
// 
//         .localBindDestruct => |lb| {
//             const valTyped = try inferExprTyped(env, lb.value.*);
//             // Resolve the value type
//             const derefed = valTyped.type_.deref();
// 
//             switch (lb.pattern) {
//                 .names => |*n| {
//                     // Record destructuring: must be a record/struct
//                     const typeName = switch (derefed.*) {
//                         .named => |nm| nm.name,
//                         else => {
//                             env.lastError = TypeError.notARecord("unknown").withLoc(expr.loc);
//                             return error.TypeError;
//                         },
//                     };
//                     const maybeDef = env.typeDefs.get(typeName);
//                     if (maybeDef == null or maybeDef.?.fields() == null) {
//                         env.lastError = TypeError.notARecord(typeName).withLoc(expr.loc);
//                         return error.TypeError;
//                     }
//                     const typeDef = maybeDef.?;
//                     for (n.fields) |fld| {
//                         const fieldTy = if (typeDef.findField(fld.field_name)) |f| f.type_ else {
//                             env.lastError = TypeError.unknownField(typeName, fld.field_name).withLoc(expr.loc);
//                             return error.TypeError;
//                         };
//                         try env.bind(fld.bind_name, fieldTy);
//                     }
//                 },
//                 .tuple_ => |t| {
//                     // Tuple destructuring: must be a tuple type
//                     const tupleArgs = switch (derefed.*) {
//                         .named => |n| if (std.mem.eql(u8, n.name, "tuple")) n.args else {
//                             env.lastError = TypeError.notARecord("<tuple>").withLoc(expr.loc);
//                             return error.TypeError;
//                         },
//                         else => {
//                             env.lastError = TypeError.notARecord("<tuple>").withLoc(expr.loc);
//                             return error.TypeError;
//                         },
//                     };
//                     if (t.len != tupleArgs.len) {
//                         env.lastError = TypeError.notARecord("<tuple>").withLoc(expr.loc);
//                         return error.TypeError;
//                     }
//                     for (t, 0..) |nm, i| {
//                         try env.bind(nm, tupleArgs[i]);
//                     }
//                 },
//                 .list => {}, // List destructuring — type checking handled by pattern matching
//                 .ctor => {}, // Constructor destructuring — handled by pattern matching
//             }
//             const valPtr = try env.arena.create(ast.TypedExpr);
//             valPtr.* = valTyped;
//             return makeExpr(expr.loc, .{ .localBindDestruct = .{
//                 .pattern = lb.pattern,
//                 .value = valPtr,
//                 .mutable = lb.mutable,
//             } }, valTyped.type_);
//         },
// 
//         .case => |c| {
//             const typedSubjects = try env.arena.alloc(ast.TypedExpr, c.subjects.len);
//             for (c.subjects, 0..) |s, i| {
//                 typedSubjects[i] = try inferExprTyped(env, s);
//             }
//             const arms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
//             var distinct: std.ArrayListUnmanaged(*T.Type) = .empty;
//             for (c.arms, 0..) |arm, i| {
//                 const body = try inferExprTyped(env, arm.body);
//                 arms[i] = .{ .pattern = arm.pattern, .body = body };
//                 var seen = false;
//                 for (distinct.items) |existing| {
//                     if (typesSameShape(existing, body.type_)) {
//                         seen = true;
//                         break;
//                     }
//                 }
//                 if (!seen) try distinct.append(env.arena, body.type_);
//             }
//             const resT: *T.Type = if (distinct.items.len == 0)
//                 try env.freshVar()
//             else if (distinct.items.len == 1)
//                 distinct.items[0]
//             else
//                 try env.unionType(try distinct.toOwnedSlice(env.arena));
//             return makeExpr(expr.loc, .{ .case = .{
//                 .subjects = typedSubjects,
//                 .arms = arms,
//                 .trailingComments = c.trailingComments,
//             } }, resT);
//         },
// 
//         // ── comptime ──────────────────────────────────────────────────────────
//         .comptimeExpr => |e| {
//             const child = try inferExprTyped(env, e.*);
//             return makeExpr(expr.loc, .{ .comptimeExpr = try makeTypedPtr(env, child) }, child.type_);
//         },
// 
//         .comptimeBlock => |cb| {
//             const body = try inferStmtsTyped(env, cb.body);
//             const resT = if (body.len > 0) body[body.len - 1].expr.type_ else try env.namedType("void");
//             return makeExpr(expr.loc, .{ .comptimeBlock = .{ .body = body } }, resT);
//         },
// 
//         .@"break" => |e| {
//             if (e) |ep| {
//                 const child = try inferExprTyped(env, ep.*);
//                 return makeExpr(expr.loc, .{ .@"break" = try makeTypedPtr(env, child) }, child.type_);
//             }
//             return makeExpr(expr.loc, .{ .@"break" = null }, try env.namedType("void"));
//         },
// 
//         // ── lambdas ───────────────────────────────────────────────────────────
//         .lambda => |l| {
//             // For lambda expressions, bind parameters to fresh type variables
//             var paramTypes = try env.arena.alloc(*T.Type, l.params.len);
//             for (l.params, 0..) |p, i| {
//                 const ty = try env.freshVar();
//                 paramTypes[i] = ty;
//                 try env.bind(p, ty);
//             }
// 
//             // Infer the body
//             const body = try inferStmtsTyped(env, l.body);
// 
//             // Get return type from last expression in body
//             const returnType = if (body.len > 0)
//                 body[body.len - 1].expr.type_
//             else
//                 try env.namedType("void");
// 
//             const funcType = try env.funcType(paramTypes, returnType);
//             return makeExpr(expr.loc, .{ .lambda = .{ .params = l.params, .body = body } }, funcType);
//         },
// 
//         // ── anonymous fn expression ───────────────────────────────────────────
//         .fnExpr => |f| {
//             const body = try inferStmtsTyped(env, f.body);
//             return makeExpr(expr.loc, .{ .fnExpr = .{ .params = f.params, .body = body } }, try env.freshVar());
//         },
// 
//         // ── misc ──────────────────────────────────────────────────────────────
//         .grouped => |e| return inferExprTyped(env, e.*),
//         .block => |b| {
//             // Infer type of last expression in block
//             if (b.body.len == 0) {
//                 const emptyBody = try env.arena.alloc(ast.StmtOf(.typed), 0);
//                 return makeExpr(expr.loc, .{ .block = .{ .body = emptyBody } }, try env.namedType("void"));
//             }
//             // Infer all statements (side effects)
//             var typedStmts = try env.arena.alloc(ast.StmtOf(.typed), b.body.len);
//             for (b.body, 0..) |stmt, i| {
//                 const typedExpr = try inferExprTyped(env, stmt.expr);
//                 const exprPtr = try env.arena.create(ast.AstOf(.typed));
//                 exprPtr.* = typedExpr;
//                 typedStmts[i] = .{ .expr = exprPtr.* };
//             }
//             const lastExpr = typedStmts[b.body.len - 1].expr;
//             return makeExpr(expr.loc, .{ .block = .{ .body = typedStmts } }, lastExpr.type_);
//         },
// 
//         .assign => |a| {
//             const val = try inferExprTyped(env, a.value.*);
//             if (env.lookup(a.name)) |ty| {
//                 try unifyAt(env, ty, val.type_, expr.loc);
//             } else {
//                 env.lastError = TypeError.unboundVariable(a.name).withLoc(expr.loc);
//                 return error.TypeError;
//             }
//             return makeExpr(expr.loc, .{ .assign = .{
//                 .name = a.name,
//                 .value = try makeTypedPtr(env, val),
//             } }, try env.namedType("void"));
//         },
// 
//         .assignPlus => |a| {
//             // x += 1  →  x = x + 1
//             const valType = try inferExprTyped(env, a.value.*);
//             if (env.lookup(a.name)) |ty| {
//                 try unifyAt(env, ty, valType.type_, expr.loc);
//                 try unifyAt(env, ty, try env.namedType("i32"), expr.loc);
//             } else {
//                 env.lastError = TypeError.unboundVariable(a.name).withLoc(expr.loc);
//                 return error.TypeError;
//             }
//             return makeExpr(expr.loc, .{ .assignPlus = .{
//                 .name = a.name,
//                 .value = try makeTypedPtr(env, valType),
//             } }, try env.namedType("void"));
//         },
// 
//         .fieldAssign => |a| {
//             const recvTyped = try inferExprTyped(env, a.receiver.*);
//             const recvPtr = try makeTypedPtr(env, recvTyped);
//             const child = try inferExprTyped(env, a.value.*);
//             return makeExpr(expr.loc, .{ .fieldAssign = .{
//                 .receiver = recvPtr,
//                 .field = a.field,
//                 .value = try makeTypedPtr(env, child),
//             } }, try env.namedType("void"));
//         },
// 
//         .fieldPlusEq => |a| {
//             const recvTyped = try inferExprTyped(env, a.receiver.*);
//             const recvPtr = try makeTypedPtr(env, recvTyped);
//             const child = try inferExprTyped(env, a.value.*);
//             return makeExpr(expr.loc, .{ .fieldPlusEq = .{
//                 .receiver = recvPtr,
//                 .field = a.field,
//                 .value = try makeTypedPtr(env, child),
//             } }, try env.namedType("void"));
//         },
// 
//         .throw_ => |e| {
//             const child = try inferExprTyped(env, e.*);
//             return makeExpr(expr.loc, .{ .throw_ = try makeTypedPtr(env, child) }, try env.freshVar());
//         },
// 
//         .null_ => {
//             const args = try env.arena.alloc(*T.Type, 1);
//             args[0] = try env.freshVar();
//             return makeExpr(expr.loc, .null_, try env.namedTypeArgs("optional", args));
//         },
// 
//         .if_ => |i| {
//             const cond = try inferExprTyped(env, i.cond.*);
// 
//             // For null-check binding, extract the inner type and add binding to environment
//             var bindingScope = false;
//             if (i.binding) |b| {
//                 // Condition should be optional type ?T, extract T for the binding
//                 if (cond.type_.* == .named and std.mem.eql(u8, cond.type_.*.named.name, "optional")) {
//                     const args = cond.type_.*.named.args;
//                     if (args.len > 0) {
//                         // Create a new scope level for the binding
//                         env.enterLevel();
//                         // Bind the unwrapped type to the binding name
//                         try env.bind(b, args[0]);
//                         bindingScope = true;
//                     }
//                 }
//             }
// 
//             const thenTyped = try env.arena.alloc(ast.StmtOf(.typed), i.then_.len);
//             for (i.then_, 0..) |s, idx| {
//                 thenTyped[idx] = .{ .expr = try inferExprTyped(env, s.expr) };
//             }
// 
//             // Remove binding scope from environment after then block
//             if (bindingScope) {
//                 env.exitLevel();
//             }
// 
//             var elseTyped: ?[]ast.StmtOf(.typed) = null;
//             if (i.else_) |els| {
//                 const et = try env.arena.alloc(ast.StmtOf(.typed), els.len);
//                 for (els, 0..) |s, idx| {
//                     et[idx] = .{ .expr = try inferExprTyped(env, s.expr) };
//                 }
//                 elseTyped = et;
//             }
// 
//             // Determine result type
//             const resT: *T.Type = if (i.binding) |b| blk: {
//                 // Null-check binding: result is ?T
//                 _ = b;
//                 const thenT = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.type_ else try env.namedType("void");
//                 // Build ?T type — args must be mutable slice
//                 var args = try env.arena.alloc(*T.Type, 1);
//                 args[0] = thenT;
//                 const optionalType = try env.arena.create(T.Type);
//                 optionalType.* = .{ .named = .{ .name = "optional", .args = args } };
//                 break :blk optionalType;
//             } else if (elseTyped) |et| blk: {
//                 // If with else — result type is the type of the last else statement
//                 const thenT = if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.type_ else try env.namedType("void");
//                 const elseT = if (et.len > 0) et[et.len - 1].expr.type_ else try env.namedType("void");
//                 // Try to unify then and else types
//                 unifyAt(env, thenT, elseT, expr.loc) catch {
//                     // If they don't unify, use the then type (could be improved to use union)
//                 };
//                 break :blk thenT;
//             } else if (thenTyped.len > 0) thenTyped[thenTyped.len - 1].expr.type_ else try env.namedType("void");
// 
//             return makeExpr(expr.loc, .{ .if_ = .{
//                 .cond = try makeTypedPtr(env, cond),
//                 .binding = i.binding,
//                 .then_ = thenTyped,
//                 .else_ = elseTyped,
//             } }, resT);
//         },
// 
//         .try_ => |e| {
//             const child = try inferExprTyped(env, e.*);
//             // Result is the ok-payload type of the error union; use fresh var for now
//             const resultT = try env.freshVar();
//             return makeExpr(expr.loc, .{ .try_ = try makeTypedPtr(env, child) }, resultT);
//         },
// 
//         .tryCatch => |tc| {
//             const innerTyped = try inferExprTyped(env, tc.expr.*);
//             const handlerTyped = try inferExprTyped(env, tc.handler.*);
//             // The result type should be the union of inner and handler types
//             // For now, use the inner type as the result type
//             const resultT = innerTyped.type_;
//             // Unify handler type with result type to ensure they match
//             try unifyAt(env, resultT, handlerTyped.type_, tc.handler.loc);
//             return makeExpr(expr.loc, .{ .tryCatch = .{
//                 .expr = try makeTypedPtr(env, innerTyped),
//                 .handler = try makeTypedPtr(env, handlerTyped),
//             } }, resultT);
//         },
// 
//         .staticCall => |c| {
//             const arg = try inferExprTyped(env, c.arg.*);
//             return makeExpr(expr.loc, .{ .staticCall = .{
//                 .receiver = c.receiver,
//                 .method = c.method,
//                 .arg = try makeTypedPtr(env, arg),
//             } }, try env.freshVar());
//         },
// 
//         .builtinCall => |c| {
//             const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), c.args.len);
//             for (c.args, 0..) |arg, i| {
//                 const val = try inferExprTyped(env, arg.value.*);
//                 typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
//             }
//             return makeExpr(expr.loc, .{ .builtinCall = .{
//                 .name = c.name,
//                 .args = typedArgs,
//             } }, try env.freshVar());
//         },
// 
//         .arrayLit => |al| {
//             const typedElems = try env.arena.alloc(ast.TypedExpr, al.elems.len);
//             const elemTy = try env.freshVar();
//             for (al.elems, 0..) |e, i| {
//                 typedElems[i] = try inferExprTyped(env, e);
//                 try unifyAt(env, elemTy, typedElems[i].type_, expr.loc);
//             }
//             const args = try env.arena.alloc(*T.Type, 1);
//             args[0] = elemTy;
//             const typedSpreadExpr: ?*ast.TypedExpr = if (al.spreadExpr) |se| blk2: {
//                 const typed = try env.arena.create(ast.TypedExpr);
//                 typed.* = try inferExprTyped(env, se.*);
//                 break :blk2 typed;
//             } else null;
//             return makeExpr(expr.loc, .{ .arrayLit = .{ .elems = typedElems, .spread = al.spread, .spreadExpr = typedSpreadExpr, .comments = al.comments, .commentsPerElem = al.commentsPerElem, .trailingComma = al.trailingComma } }, try env.namedTypeArgs("array", args));
//         },
// 
//         .tupleLit => |tl| {
//             const typedElems = try env.arena.alloc(ast.TypedExpr, tl.elems.len);
//             const args = try env.arena.alloc(*T.Type, tl.elems.len);
//             for (tl.elems, 0..) |e, i| {
//                 typedElems[i] = try inferExprTyped(env, e);
//                 args[i] = typedElems[i].type_;
//             }
//             return makeExpr(expr.loc, .{ .tupleLit = .{ .elems = typedElems, .comments = tl.comments, .commentsPerElem = tl.commentsPerElem } }, try env.namedTypeArgs("tuple", args));
//         },
// 
//         .yield => |e| {
//             const child = try inferExprTyped(env, e.*);
//             return makeExpr(expr.loc, .{ .yield = try makeTypedPtr(env, child) }, child.type_);
//         },
// 
//         .@"continue" => return makeExpr(expr.loc, .{ .@"continue" = {} }, try env.namedType("void")),
// 
//         .@"assert" => |a| {
//             const conditionTyped = try inferExprTyped(env, a.condition.*);
//             // Assert expects boolean condition and returns void
//             const boolType = try env.namedType("bool");
//             try unifyAt(env, conditionTyped.type_, boolType, expr.loc);
//             return makeExpr(expr.loc, .{ .@"assert" = .{
//                 .condition = try makeTypedPtr(env, conditionTyped),
//                 .message = if (a.message) |msg| blk: {
//                     const msgTyped = try inferExprTyped(env, msg.*);
//                     break :blk try makeTypedPtr(env, msgTyped);
//                 } else null,
//             } }, try env.namedType("void"));
//         },
// 
//         .assertPattern => |ap| {
//             // Type check the expression being matched
//             const exprTyped = try inferExprTyped(env, ap.expr.*);
// 
//             // The pattern type should be compatible with the expression type
//             // For now, we'll use a simplified approach - the pattern defines the expected type
//             // and the expression must match it
// 
//             // Type check the handler and determine the result type
//             const resultType = switch (ap.handler) {
//                 .orthrow => |errorExpr| blk: {
//                     // orthrow: throws error, so never returns normally
//                     const errorTyped = try inferExprTyped(env, errorExpr.*);
//                     // Error expression should be of Error type
//                     const errorType = try env.namedType("Error");
//                     try unifyAt(env, errorTyped.type_, errorType, expr.loc);
//                     // orthrow expressions don't return normally (they throw)
//                     break :blk try env.namedType("never");
//                 },
//                 .@"catch" => |catchExpr| blk: {
//                     // catch: provides default value on pattern match failure
//                     const catchTyped = try inferExprTyped(env, catchExpr.*);
//                     // The catch handler type becomes the result type
//                     break :blk catchTyped.type_;
//                 },
//             };
// 
//             // Create the typed assert pattern expression by handling each case separately
//             if (ap.handler == .orthrow) {
//                 const typed = try inferExprTyped(env, ap.handler.orthrow.*);
//                 return makeExpr(expr.loc, .{ .assertPattern = .{
//                     .pattern = ap.pattern,
//                     .expr = try makeTypedPtr(env, exprTyped),
//                     .handler = .{ .orthrow = try makeTypedPtr(env, typed) },
//                 } }, resultType);
//             } else {
//                 const typed = try inferExprTyped(env, ap.handler.@"catch".*);
//                 return makeExpr(expr.loc, .{ .assertPattern = .{
//                     .pattern = ap.pattern,
//                     .expr = try makeTypedPtr(env, exprTyped),
//                     .handler = .{ .@"catch" = try makeTypedPtr(env, typed) },
//                 } }, resultType);
//             }
//         },
// 
//         .range => |r| {
//             const startTyped = try inferExprTyped(env, r.start.*);
//             const endTyped: ?*ast.TypedExpr = if (r.end) |end| blk: {
//                 const et = try inferExprTyped(env, end.*);
//                 break :blk try makeTypedPtr(env, et);
//             } else null;
//             return makeExpr(expr.loc, .{ .range = .{
//                 .start = try makeTypedPtr(env, startTyped),
//                 .end = endTyped,
//             } }, try env.namedType("range"));
//         },
// 
//         .loop => |lp| {
//             const iterTyped = try inferExprTyped(env, lp.iter.*);
//             const indexTyped: ?*ast.TypedExpr = if (lp.indexRange) |ir| blk: {
//                 const it = try inferExprTyped(env, ir.*);
//                 break :blk try makeTypedPtr(env, it);
//             } else null;
//             // Bind loop params to fresh type vars so body can reference them.
//             for (lp.params) |p| {
//                 try env.bind(p, try env.freshVar());
//             }
//             const bodyTyped = try inferStmtsTyped(env, lp.body);
//             // Result type: if body has yield stmts → list<T>, otherwise void.
//             const elemT = try env.freshVar();
//             const listArgs = try env.arena.alloc(*T.Type, 1);
//             listArgs[0] = elemT;
//             const resultT = try env.namedTypeArgs("list", listArgs);
//             return makeExpr(expr.loc, .{ .loop = .{
//                 .iter = try makeTypedPtr(env, iterTyped),
//                 .indexRange = indexTyped,
//                 .params = lp.params,
//                 .body = bodyTyped,
//             } }, resultT);
//         },
//     }
// }

pub fn freshEnv(a: std.mem.Allocator, gpa: std.mem.Allocator) !Env {
    var e = Env.init(a);
    try e.registerBuiltins();
    try comptimeMod.registerStdlib(&e, gpa);
    try e.bind("true", try e.namedType("bool"));
    try e.bind("false", try e.namedType("bool"));
    return e;
}
