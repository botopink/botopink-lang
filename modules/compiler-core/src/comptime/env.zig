/// Type inference environment for the botopink type checker.
///
/// All Type/TypeCell allocations go through `arena`. The caller owns an
/// ArenaAllocator and frees it after type-checking is complete.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");

// ── type definitions ──────────────────────────────────────────────────────────

/// A field inside a record, struct, or enum variant.
pub const FieldDef = struct {
    name: []const u8,
    type_: *T.Type,
};

/// One variant inside an enum type definition.
pub const VariantDef = struct {
    name: []const u8,
    fields: []FieldDef,
};

/// A registered type shape: record, struct, or enum.
pub const TypeDef = union(enum) {
    record: Record,
    struct_: Struct,
    enum_: Enum,

    pub const Record = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        fields: []FieldDef,
    };

    pub const Struct = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        fields: []FieldDef,
    };

    pub const Enum = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        variants: []VariantDef,
    };

    /// Return the fields slice for record or struct types; null for enums.
    pub fn fields(self: TypeDef) ?[]FieldDef {
        return switch (self) {
            .record => |r| r.fields,
            .struct_ => |s| s.fields,
            .enum_ => null,
        };
    }

    /// Look up a field by name. Returns null if not found or if this is an enum.
    pub fn findField(self: TypeDef, name: []const u8) ?*FieldDef {
        const flds = self.fields() orelse return null;
        for (flds) |*f| {
            if (std.mem.eql(u8, f.name, name)) return f;
        }
        return null;
    }
};

// ── environment ───────────────────────────────────────────────────────────────

/// The type-checking environment.
///
/// Owns no memory itself ---- all allocations go through `arena`.
/// Deinit only frees the hash map metadata; the arena frees everything else.
pub const Env = struct {
    /// Arena allocator ---- all Type and TypeCell nodes are allocated here.
    arena: std.mem.Allocator,
    /// Value bindings: variable/function name → *Type.
    bindings: std.StringHashMap(*T.Type),
    /// Registered type definitions: type name → TypeDef.
    typeDefs: std.StringHashMap(TypeDef),
    /// Monotonically increasing counter for fresh type variable IDs.
    nextId: T.TypeId,
    /// Monotonically increasing counter for type definition IDs (record$$0, struct$$1, ...).
    nextTypeId: usize,
    /// Current let-binding level for generalization.
    level: usize,
    /// The most recent type error (set before returning `error.TypeError`).
    lastError: ?@import("error.zig").TypeError,

    pub fn init(arena: std.mem.Allocator) Env {
        return .{
            .arena = arena,
            .bindings = std.StringHashMap(*T.Type).init(arena),
            .typeDefs = std.StringHashMap(TypeDef).init(arena),
            .nextId = 0,
            .nextTypeId = 0,
            .level = 0,
            .lastError = null,
        };
    }

    pub fn deinit(self: *Env) void {
        self.bindings.deinit();
        self.typeDefs.deinit();
    }

    // ── type constructors ─────────────────────────────────────────────────────

    /// Allocate a fresh unbound type variable at the current level.
    pub fn freshVar(self: *Env) !*T.Type {
        const id = self.nextId;
        self.nextId += 1;
        const cell = try self.arena.create(T.TypeCell);
        cell.* = .{ .state = .{ .unbound = .{ .id = id, .level = self.level } } };
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .typeVar = cell };
        return ty;
    }

    /// Allocate a named type with zero type arguments.
    pub fn namedType(self: *Env, name: []const u8) !*T.Type {
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .named = .{ .name = name, .args = &.{} } };
        return ty;
    }

    /// Allocate a named type with the given type arguments (args are copied).
    pub fn namedTypeArgs(self: *Env, name: []const u8, args: []*T.Type) !*T.Type {
        const argsCopy = try self.arena.dupe(*T.Type, args);
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .named = .{ .name = name, .args = argsCopy } };
        return ty;
    }

    /// Allocate a union type (types slice is used as-is ---- caller ensures lifetime).
    pub fn unionType(self: *Env, types: []*T.Type) !*T.Type {
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .union_ = types };
        return ty;
    }

    /// Allocate a function type (params slice is copied).
    pub fn funcType(self: *Env, params: []*T.Type, ret: *T.Type) !*T.Type {
        const paramsCopy = try self.arena.dupe(*T.Type, params);
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .func = .{ .params = paramsCopy, .ret = ret } };
        return ty;
    }

    // ── bindings ──────────────────────────────────────────────────────────────

    pub fn lookup(self: *Env, name: []const u8) ?*T.Type {
        return self.bindings.get(name);
    }

    pub fn bind(self: *Env, name: []const u8, ty: *T.Type) !void {
        try self.bindings.put(name, ty);
    }

    pub fn lookupTypeDef(self: *Env, name: []const u8) ?TypeDef {
        return self.typeDefs.get(name);
    }

    pub fn registerTypeDef(self: *Env, name: []const u8, def: TypeDef) !void {
        try self.typeDefs.put(name, def);
    }

    /// Allocate a unique type definition ID (monotonically increasing).
    pub fn allocTypeId(self: *Env) usize {
        const id = self.nextTypeId;
        self.nextTypeId += 1;
        return id;
    }

    // ── builtins ──────────────────────────────────────────────────────────────

    /// Register the primitive built-in types so they can be looked up by name.
    pub fn registerBuiltins(self: *Env) !void {
        const primitives = [_][]const u8{
            // integer types
            "i8",  "u8",  "i16",  "u16",    "i32",  "u32",  "i64",  "u64", "isize", "usize",
            // float types
            "f32", "f64",
            // other primitives
            "bool", "string", "void", "v128",
            // special
            "Self",
        };
        for (primitives) |p| {
            const ty = try self.namedType(p);
            try self.bind(p, ty);
        }
        // Built-in functions bound with placeholder void type.
        // These are runtime functions — actual types are resolved during codegen.
        try self.bind("print", try self.namedType("void"));
        try self.bind("println", try self.namedType("void"));
    }

    // ── level management ──────────────────────────────────────────────────────

    pub fn enterLevel(self: *Env) void {
        self.level += 1;
    }

    pub fn exitLevel(self: *Env) void {
        self.level -= 1;
    }

    // ── type name resolution ──────────────────────────────────────────────────

    /// Resolve a string type name (from AST) to a *Type.
    /// Generic parameters are looked up in `genericMap` first.
    pub fn resolveTypeName(
        self: *Env,
        name: []const u8,
        genericMap: std.StringHashMap(*T.Type),
    ) !*T.Type {
        // Generic parameters bound in the current function/type
        if (genericMap.get(name)) |ty| return ty;
        // Registered user-defined types
        if (self.typeDefs.contains(name)) return self.namedType(name);
        // Primitive / built-in names
        if (self.bindings.get(name)) |ty| return ty;
        // Fallback: treat as an opaque named type (forward reference, etc.)
        return self.namedType(name);
    }
};
