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
        switch (decl) {
            // `resolveImports` (called before inference in comptime.zig) already
            // called `env.bind(name, ty)` for each symbol in the `use` statement.
            // Emit one TypedBinding per import so the LSP completion engine can
            // see them — the dummy `name = ""` binding is gone.
            .use => |u| {
                for (u.imports) |imp| {
                    const name = imp.name();
                    if (env.lookup(name)) |ty| {
                        try list.append(env.arena, .{
                            .name = name,
                            .type_ = ty,
                            .typedExpr = null,
                            .decl = decl,
                        });
                    }
                }
            },
            else => {
                if (try inferDeclTyped(env, decl)) |b| {
                    try list.append(env.arena, b);
                }
            },
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
        // Handled in `inferProgramTyped` — each import name is looked up in env.
        .use => return null,
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

fn extractImplementNames(arena: std.mem.Allocator, impls: []const ast.TypeRef) ![]const []const u8 {
    if (impls.len == 0) return &.{};
    var names = try arena.alloc([]const u8, impls.len);
    for (impls, 0..) |im, i| {
        names[i] = switch (im) {
            .named => |n| n,
            .generic => |g| g.name,
            else => "unknown",
        };
    }
    return names;
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
    const implNames = try extractImplementNames(env.arena, r.implement);
    try env.registerTypeDef(r.name, .{ .record = .{
        .name = r.name,
        .id = typeId,
        .genericParams = genericIds,
        .fields = fields,
        .implements = implNames,
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
    const implNames = try extractImplementNames(env.arena, s.implement);
    try env.registerTypeDef(s.name, .{ .struct_ = .{
        .name = s.name,
        .id = structTypeId,
        .genericParams = genericIds,
        .fields = fields,
        .implements = implNames,
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
    const implNames = try extractImplementNames(env.arena, e.implement);
    try env.registerTypeDef(e.name, .{ .enum_ = .{
        .name = e.name,
        .id = enumTypeId,
        .genericParams = genericIds,
        .variants = variants,
        .implements = implNames,
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
        .function => |f| {
            try buf.appendSlice(allocator, "fn(");
            for (f.params, 0..) |p, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, p);
            }
            try buf.appendSlice(allocator, ") -> ");
            try appendTypeRefStr(buf, allocator, f.returnType.*);
        },
        .generic => |b| {
            if (b.is_builtin) try buf.append(allocator, '@');
            try buf.appendSlice(allocator, b.name);
            try buf.append(allocator, '<');
            for (b.args, 0..) |a, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try appendTypeRefStr(buf, allocator, a);
            }
            try buf.append(allocator, '>');
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
fn inferBuiltinCallReturnType(
    env: *Env,
    callee: []const u8,
    typedArgs: []ast.CallArgOf(.typed),
    typedTrailing: []ast.TrailingLambdaOf(.typed),
) InferError!*T.Type {
    if (std.mem.eql(u8, callee, "block")) {
        if (typedTrailing.len > 0) {
            const body = typedTrailing[0].body;
            if (body.len > 0) return body[body.len - 1].expr.getType();
        }
        return env.namedType("void");
    }
    if (std.mem.eql(u8, callee, "src") or
        std.mem.eql(u8, callee, "embedFile") or
        std.mem.eql(u8, callee, "typeName") or
        std.mem.eql(u8, callee, "tagName"))
    {
        return env.namedType("string");
    }
    if (std.mem.eql(u8, callee, "sizeOf") or std.mem.eql(u8, callee, "alignOf")) {
        return env.namedType("i32");
    }
    if (std.mem.eql(u8, callee, "min") or
        std.mem.eql(u8, callee, "max") or
        std.mem.eql(u8, callee, "abs") or
        std.mem.eql(u8, callee, "as") or
        std.mem.eql(u8, callee, "field") or
        std.mem.eql(u8, callee, "typeOf"))
    {
        if (typedArgs.len > 0) return typedArgs[0].value.getType();
        return env.freshVar();
    }
    return env.namedType("void");
}

fn unwrapResultType(ty: *T.Type) ?*T.Type {
    const t = ty.deref();
    return switch (t.*) {
        .named => |n| if (std.mem.eql(u8, n.name, "Result") and n.args.len >= 1)
            n.args[0]
        else
            null,
        else => null,
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
        .generic => |b| {
            const args = try env.arena.alloc(*T.Type, b.args.len);
            for (b.args, 0..) |a, i| {
                args[i] = try resolveTypeRefInContext(env, a, genericMap);
            }
            return env.namedTypeArgs(b.name, args);
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
const PatternBindingSnapshot = struct {
    name: []const u8,
    previous: ?*T.Type,
};

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

fn patternContainsWildcard(pattern: ast.Pattern) bool {
    return switch (pattern) {
        .wildcard => true,
        .@"or" => |patterns| blk: {
            for (patterns) |p| {
                if (patternContainsWildcard(p)) break :blk true;
            }
            break :blk false;
        },
        .multi => |patterns| blk: {
            for (patterns) |p| {
                if (patternContainsWildcard(p)) break :blk true;
            }
            break :blk false;
        },
        .variantLiterals => |vl| blk: {
            for (vl.args) |p| {
                if (patternContainsWildcard(p)) break :blk true;
            }
            break :blk false;
        },
        else => false,
    };
}

fn isEnumVariantNameForSubject(env: *Env, subjectType: *T.Type, candidate: []const u8) bool {
    const ty = subjectType.deref();
    if (ty.* != .named) return false;
    if (env.lookupTypeDef(ty.named.name)) |td| {
        switch (td) {
            .enum_ => |en| {
                for (en.variants) |v| {
                    if (std.mem.eql(u8, v.name, candidate)) return true;
                }
            },
            else => {},
        }
    }
    return false;
}

fn saveAndBindPatternName(
    env: *Env,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
    name: []const u8,
    ty: *T.Type,
) InferError!void {
    var seen = false;
    for (snapshots.items) |s| {
        if (std.mem.eql(u8, s.name, name)) {
            seen = true;
            break;
        }
    }
    if (!seen) {
        try snapshots.append(env.arena, .{
            .name = name,
            .previous = env.lookup(name),
        });
    }
    try env.bind(name, ty);
}

fn restorePatternBindings(env: *Env, snapshots: []const PatternBindingSnapshot) InferError!void {
    var i = snapshots.len;
    while (i > 0) {
        i -= 1;
        const snapshot = snapshots[i];
        if (snapshot.previous) |old| {
            try env.bind(snapshot.name, old);
        } else {
            _ = env.bindings.remove(snapshot.name);
        }
    }
}

fn bindPatternNamesForSubject(
    env: *Env,
    pattern: ast.Pattern,
    subjectType: *T.Type,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    switch (pattern) {
        .wildcard, .numberLit, .stringLit => {},
        .ident => |name| {
            if (isEnumVariantNameForSubject(env, subjectType, name)) return;
            try saveAndBindPatternName(env, snapshots, name, try env.freshVar());
        },
        .variantBinding => |vb| {
            try saveAndBindPatternName(env, snapshots, vb.binding, try env.freshVar());
        },
        .variantFields => |vf| {
            for (vf.bindings) |binding| {
                try saveAndBindPatternName(env, snapshots, binding, try env.freshVar());
            }
        },
        .variantLiterals => |vl| {
            for (vl.args) |arg| {
                try bindPatternNamesForSubject(env, arg, try env.freshVar(), snapshots);
            }
        },
        .list => |lst| {
            for (lst.elems) |elem| {
                switch (elem) {
                    .bind => |name| try saveAndBindPatternName(env, snapshots, name, try env.freshVar()),
                    else => {},
                }
            }
            if (lst.spread) |name| {
                if (name.len > 0) try saveAndBindPatternName(env, snapshots, name, try env.freshVar());
            }
        },
        .@"or" => |patterns| {
            if (patterns.len > 0) try bindPatternNamesForSubject(env, patterns[0], subjectType, snapshots);
        },
        .multi => {},
    }
}

fn bindCaseArmPatternNames(
    env: *Env,
    pattern: ast.Pattern,
    typedSubjects: []const ast.TypedExpr,
    snapshots: *std.ArrayListUnmanaged(PatternBindingSnapshot),
) InferError!void {
    if (pattern == .multi) {
        const patterns = pattern.multi;
        for (patterns, 0..) |p, i| {
            const subjectTy = if (i < typedSubjects.len) typedSubjects[i].getType() else try env.freshVar();
            try bindPatternNamesForSubject(env, p, subjectTy, snapshots);
        }
        return;
    }
    const subjectTy = if (typedSubjects.len > 0) typedSubjects[0].getType() else try env.freshVar();
    try bindPatternNamesForSubject(env, pattern, subjectTy, snapshots);
}

fn isExhaustivenessCheckedType(env: *Env, ty: *T.Type) bool {
    const resolved = ty.deref();
    if (resolved.isNamed("string")) return true;
    if (resolved.* == .named) {
        if (env.lookupTypeDef(resolved.named.name)) |td| {
            return switch (td) {
                .enum_ => true,
                else => false,
            };
        }
    }
    return false;
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
        .jump => |j| inferJumpExpr(env, j, j.loc),
        .branch => |b| inferBranchExpr(env, b, b.loc),
        .loop => |lp| inferLoopExpr(env, lp, lp.loc),

        // ── binding expressions ────────────────────────────────────────────────
        .binding => |b| inferBindingExpr(env, b, b.loc),

        // ── use-hook expressions (@Context Fase 3) ────────────────────────────
        .useHook => return InferError.TypeError,

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
                    if (env.lookupTypeDef(receiverName)) |td| {
                        switch (td) {
                            .enum_ => |en| {
                                var found = false;
                                for (en.variants) |v| {
                                    if (std.mem.eql(u8, v.name, ia.member)) {
                                        found = true;
                                        break;
                                    }
                                }
                                if (!found) {
                                    env.lastError = TypeError.unknownField(receiverName, ia.member).withLoc(loc);
                                    return error.TypeError;
                                }
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
                            },
                            else => {},
                        }
                    }
                }
            }
            // Regular instance field access on a variable/instance
            const recvTyped = try inferExprTyped(env, ia.receiver.*);
            const recvPtr = try makeTypedPtr(env, recvTyped);
            const recvType = recvTyped.getType().deref();
            var outType: *T.Type = try env.freshVar();
            if (recvType.* == .named) {
                const recvNamed = recvType.named;
                if (env.lookupTypeDef(recvNamed.name)) |td| {
                    switch (td) {
                        .record, .struct_ => {
                            if (td.findField(ia.member)) |f| {
                                outType = f.type_;
                            } else {
                                env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                                return error.TypeError;
                            }
                        },
                        .enum_ => {
                            env.lastError = TypeError.unknownField(recvNamed.name, ia.member).withLoc(loc);
                            return error.TypeError;
                        },
                    }
                }
            }
            return TypedExpr{ .identifier = .{ .loc = loc, .type_ = outType, .kind = .{ .identAccess = .{
                .receiver = recvPtr,
                .member = ia.member,
            } } } };
        },
    };
}

/// Infer type for binary operation expressions
fn inferBinaryOpExpr(env: *Env, binop: ast.BinOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const lhsTyped = try inferExprTyped(env, binop.kind.lhs.*);
    const rhsTyped = try inferExprTyped(env, binop.kind.rhs.*);
    const lhsPtr = try makeTypedPtr(env, lhsTyped);
    const rhsPtr = try makeTypedPtr(env, rhsTyped);

    // Determine result type based on operator
    const resultType: *T.Type = switch (binop.kind.op) {
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
    return TypedExpr{ .binaryOp = .{ .loc = loc, .type_ = resultType, .kind = .{
        .op = binop.kind.op,
        .lhs = lhsPtr,
        .rhs = rhsPtr,
    } } };
}

/// Infer type for unary operation expressions
fn inferUnaryOpExpr(env: *Env, unaryop: ast.UnaryOpExprOf(.untyped), loc: ast.Loc) InferError!TypedExpr {
    const operandTyped = try inferExprTyped(env, unaryop.kind.expr.*);
    const operandPtr = try makeTypedPtr(env, operandTyped);
    return switch (unaryop.kind.op) {
        .not => blk: {
            try unifyAt(env, operandTyped.getType(), try env.namedType("bool"), loc);
            break :blk TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = try env.namedType("bool"), .kind = .{ .op = .not, .expr = operandPtr } } };
        },
        .neg => TypedExpr{ .unaryOp = .{ .loc = loc, .type_ = operandTyped.getType(), .kind = .{ .op = .neg, .expr = operandPtr } } },
    };
}

/// Infer type for jump expressions (return, throw, try, break, continue, yield)
fn inferJumpExpr(env: *Env, j: ast.MakeExpr(.untyped, ast.JumpExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (j.kind) {
        .@"return" => |r| {
            const valPtr: ?*TypedExpr = if (r) |rv| try makeTypedPtr(env, try inferExprTyped(env, rv.*)) else null;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"return" = valPtr } } };
        },
        .throw_ => |e| {
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .throw_ = valPtr } } };
        },
        .try_ => |e| {
            const valPtr: ?*TypedExpr = if (e) |ev| try makeTypedPtr(env, try inferExprTyped(env, ev.*)) else null;
            const rawTy = if (valPtr) |vp| vp.getType() else try env.freshVar();
            const ty = unwrapResultType(rawTy) orelse rawTy;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = ty, .kind = .{ .try_ = valPtr } } };
        },
        .@"break" => |e| {
            const typedPtr: ?*TypedExpr = if (e) |expr| try makeTypedPtr(env, try inferExprTyped(env, expr.*)) else null;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .@"break" = typedPtr } } };
        },
        .@"continue" => TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .@"continue" } },
        .yield => |e| {
            const typedPtr: ?*TypedExpr = if (e) |expr| try makeTypedPtr(env, try inferExprTyped(env, expr.*)) else null;
            return TypedExpr{ .jump = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .yield = typedPtr } } };
        },
    };
}

/// Infer type for branch expressions (if and try-catch)
fn inferBranchExpr(env: *Env, b: ast.MakeExpr(.untyped, ast.BranchExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    return switch (b.kind) {
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
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = bodyType, .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = i.binding,
                .then_ = thenTyped,
                .else_ = elseTyped,
            } } } };
        },

        .tryCatch => |tc| {
            const exprTyped = try inferExprTyped(env, tc.expr.*);
            const exprPtr = try makeTypedPtr(env, exprTyped);
            const handlerTyped = try inferExprTyped(env, tc.handler.*);
            const handlerPtr = try makeTypedPtr(env, handlerTyped);
            const rawTy = exprTyped.getType();
            const resultTy = unwrapResultType(rawTy) orelse rawTy;
            const handlerTy = handlerTyped.getType().deref();
            const effectiveTy = switch (handlerTy.*) {
                .func => |f| f.ret,
                else => handlerTyped.getType(),
            };
            if (!effectiveTy.isNamed("void")) {
                try unify(env, resultTy, effectiveTy);
            }
            return TypedExpr{ .branch = .{ .loc = loc, .type_ = resultTy, .kind = .{ .tryCatch = .{
                .expr = exprPtr,
                .handler = handlerPtr,
            } } } };
        },
    };
}

/// Infer type for loop expressions
fn inferLoopExpr(env: *Env, lp: ast.MakeExpr(.untyped, ast.LoopExprOf(.untyped)), loc: ast.Loc) InferError!TypedExpr {
    const iterTyped = try inferExprTyped(env, lp.kind.iter.*);
    const iterPtr = try makeTypedPtr(env, iterTyped);
    const indexRangePtr = if (lp.kind.indexRange) |ir| try makeTypedPtr(env, try inferExprTyped(env, ir.*)) else null;

    for (lp.kind.params) |p| {
        try env.bind(p, try env.freshVar());
    }

    const typedBody = try inferStmtsTyped(env, lp.kind.body);
    const loopArrayArgs = try env.arena.alloc(*T.Type, 1);
    loopArrayArgs[0] = try env.freshVar();
    return TypedExpr{ .loop = .{ .loc = loc, .type_ = try env.namedTypeArgs("array", loopArrayArgs), .kind = .{
        .iter = iterPtr,
        .indexRange = indexRangePtr,
        .params = lp.kind.params,
        .body = typedBody,
    } } };
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

            return TypedExpr{ .binding = .{ .loc = loc, .type_ = valTyped.getType(), .kind = .{ .assign = .{
                .target = switch (a.target) {
                    .name => |name| blk: {
                        if (env.lookup(name)) |ty| {
                            try unifyAt(env, ty, valTyped.getType(), loc);
                        } else {
                            env.lastError = TypeError.unboundVariable(name).withLoc(loc);
                            return error.TypeError;
                        }
                        break :blk .{ .name = name };
                    },
                    .fieldAccess => |fa| blk: {
                        const recvTyped = try inferExprTyped(env, fa.receiver.*);
                        const recvPtr = try makeTypedPtr(env, recvTyped);
                        break :blk .{ .fieldAccess = .{ .receiver = recvPtr, .field = fa.field } };
                    },
                },
                .op = a.op,
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
            const typedArgs = try env.arena.alloc(ast.CallArgOf(.typed), call.args.len);
            for (call.args, 0..) |arg, i| {
                const val = try inferExprTyped(env, arg.value.*);
                typedArgs[i] = .{ .label = arg.label, .value = try makeTypedPtr(env, val) };
            }
            const typedTrailing = try inferTrailingLambdasTyped(env, call.trailing);

            if (call.is_builtin) {
                const retType = try inferBuiltinCallReturnType(env, call.callee, typedArgs, typedTrailing);
                return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                    .receiver = call.receiver,
                    .callee = call.callee,
                    .is_builtin = call.is_builtin,
                    .args = typedArgs,
                    .trailing = typedTrailing,
                } } } };
            }
            const calleeType = if (env.lookup(call.callee)) |ty| ty else {
                env.lastError = TypeError.unboundVariable(call.callee).withLoc(loc);
                return error.TypeError;
            };
            const resolved = calleeType.deref();
            const retType: *T.Type = switch (resolved.*) {
                .func => |f| blk: {
                    var spreadCount: usize = 0;
                    var nonSpreadCount: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) {
                                spreadCount += 1;
                                continue;
                            }
                        }
                        nonSpreadCount += 1;
                    }

                    if (spreadCount == 0) {
                        if (f.params.len != call.args.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        for (typedArgs, f.params) |ta, paramType| {
                            try unifyAt(env, paramType, ta.value.getType(), ta.value.getLoc());
                        }
                        break :blk f.ret;
                    }

                    // Keep the historical spread behavior (and snapshots) for narrow update/error cases.
                    if (spreadCount != 1 or nonSpreadCount < 2) {
                        if (f.params.len != call.args.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, call.args.len).withLoc(loc);
                            return error.TypeError;
                        }
                        for (typedArgs, f.params) |ta, paramType| {
                            try unifyAt(env, paramType, ta.value.getType(), ta.value.getLoc());
                        }
                        break :blk f.ret;
                    }

                    if (nonSpreadCount > f.params.len) {
                        env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                        return error.TypeError;
                    }

                    var paramIndex: usize = 0;
                    for (typedArgs) |ta| {
                        if (ta.label) |lbl| {
                            if (std.mem.eql(u8, lbl, "..")) continue;
                        }
                        if (paramIndex >= f.params.len) {
                            env.lastError = TypeError.arityMismatch(call.callee, f.params.len, nonSpreadCount).withLoc(loc);
                            return error.TypeError;
                        }
                        try unifyAt(env, f.params[paramIndex], ta.value.getType(), ta.value.getLoc());
                        paramIndex += 1;
                    }
                    break :blk f.ret;
                },
                .named => resolved,
                else => try env.freshVar(),
            };
            return TypedExpr{ .call = .{ .loc = loc, .type_ = retType, .kind = .{ .call = .{
                .receiver = call.receiver,
                .callee = call.callee,
                .is_builtin = call.is_builtin,
                .args = typedArgs,
                .trailing = typedTrailing,
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
                    .is_builtin = call.is_builtin,
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

            if (typedSubjects.len == 1 and c.arms.len == 1 and !patternContainsWildcard(c.arms[0].pattern)) {
                if (isExhaustivenessCheckedType(env, typedSubjects[0].getType())) {
                    env.lastError = TypeError.typeMismatch(
                        try env.namedType("exhaustive"),
                        typedSubjects[0].getType(),
                    ).withLoc(loc);
                    return error.TypeError;
                }
            }
            const typedArms = try env.arena.alloc(ast.CaseArmOf(.typed), c.arms.len);
            for (c.arms, 0..) |arm, i| {
                var snapshots: std.ArrayListUnmanaged(PatternBindingSnapshot) = .empty;
                defer snapshots.deinit(env.arena);
                try bindCaseArmPatternNames(env, arm.pattern, typedSubjects, &snapshots);

                const bodyTyped = inferExprTyped(env, arm.body) catch |err| {
                    try restorePatternBindings(env, snapshots.items);
                    return err;
                };
                try restorePatternBindings(env, snapshots.items);
                typedArms[i] = .{
                    .pattern = arm.pattern,
                    .body = bodyTyped,
                    .emptyLinesBefore = arm.emptyLinesBefore,
                };
            }
            return TypedExpr{ .collection = .{ .loc = loc, .type_ = try env.freshVar(), .kind = .{ .case = .{
                .subjects = typedSubjects,
                .arms = typedArms,
                .trailingComments = c.trailingComments,
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

        .assert => |a| {
            const condTyped = try inferExprTyped(env, a.condition.*);
            const condPtr = try makeTypedPtr(env, condTyped);
            const msgPtr = if (a.message) |msg| try makeTypedPtr(env, try inferExprTyped(env, msg.*)) else null;
            return TypedExpr{ .comptime_ = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .assert = .{
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

pub fn freshEnv(a: std.mem.Allocator, gpa: std.mem.Allocator) !Env {
    var e = Env.init(a);
    try e.registerBuiltins();
    try comptimeMod.registerStdlib(&e, gpa);
    try e.bind("true", try e.namedType("bool"));
    try e.bind("false", try e.namedType("bool"));
    return e;
}
