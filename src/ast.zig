const std = @import("std");

// ── use decl ──────────────────────────────────────────────────────────────────

pub const Source = union(enum) {
    StringPath: []const u8,
    FunctionCall: []const u8,
};

pub const UseDecl = struct {
    imports: []const []const u8,
    source: Source,
};

// ── interface decl ────────────────────────────────────────────────────────────────

/// A single expression in a method body.
pub const Expr = union(enum) {
    /// A string literal value, e.g. "hello"
    StringLit: []const u8,
    /// A number literal, e.g. 0
    NumberLit: []const u8,
    /// Field access on self, e.g. self.color
    SelfField: []const u8,
    /// Assign to a private self field, e.g. self._balance = value
    SelfFieldAssign: struct {
        field: []const u8,
        value: *Expr,
    },
    /// self._field += amount
    SelfFieldPlusEq: struct {
        field: []const u8,
        value: *Expr,
    },
    /// Binary + concatenation, e.g. lhs + rhs
    Concat: struct {
        lhs: *Expr,
        rhs: *Expr,
    },
    /// A plain identifier, e.g. Console
    Ident: []const u8,
    /// Static method call, e.g. Console.WriteLine(arg)
    StaticCall: struct {
        receiver: []const u8,
        method: []const u8,
        arg: *Expr,
    },
    /// throw new Error("msg")
    ThrowNew: struct {
        error_type: []const u8,
        message: *Expr,
    },
    /// return expr
    Return: *Expr,
    /// Binary < comparison, e.g. value < 0
    Lt: struct {
        lhs: *Expr,
        rhs: *Expr,
    },

    pub fn deinit(self: *Expr, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .SelfFieldAssign => |a| {
                a.value.deinit(allocator);
                allocator.destroy(a.value);
            },
            .SelfFieldPlusEq => |a| {
                a.value.deinit(allocator);
                allocator.destroy(a.value);
            },
            .Concat => |c| {
                c.lhs.deinit(allocator);
                allocator.destroy(c.lhs);
                c.rhs.deinit(allocator);
                allocator.destroy(c.rhs);
            },
            .StaticCall => |c| {
                c.arg.deinit(allocator);
                allocator.destroy(c.arg);
            },
            .ThrowNew => |t| {
                t.message.deinit(allocator);
                allocator.destroy(t.message);
            },
            .Return => |r| {
                r.deinit(allocator);
                allocator.destroy(r);
            },
            .Lt => |l| {
                l.lhs.deinit(allocator);
                allocator.destroy(l.lhs);
                l.rhs.deinit(allocator);
                allocator.destroy(l.rhs);
            },
            else => {},
        }
    }
};

/// A statement inside a method body (expression-statement only for now).
pub const Stmt = struct {
    expr: Expr,

    pub fn deinit(self: *Stmt, allocator: std.mem.Allocator) void {
        self.expr.deinit(allocator);
    }
};

/// A field declared inside a interface: `val name: Type`
pub const InterfaceField = struct {
    name: []const u8,
    type_name: []const u8,
};

/// Modifier on a parameter type — controls how the argument is treated.
pub const ParamModifier = enum {
    /// No modifier — normal evaluated argument.
    None,
    /// `comptime` — argument must be known at compile time.
    Comptime,
    /// `syntax` — argument is passed as an unevaluated expression tree (AST).
    Syntax,
    /// `typeinfo` — argument is a type used as a value; constraint lists allowed.
    Typeinfo,
};

/// A single parameter in a method/function signature.
/// Examples:
///   `x: Int`
///   `s: comptime string`
///   `lamb: syntax fn(item: T) -> R`
///   `T: typeinfo int | float`
pub const Param = struct {
    name: []const u8,
    type_name: []const u8,
    modifier: ParamModifier = .None,
    /// For `typeinfo` params: the union-of-types constraint, e.g. ["int","float"].
    /// Null when there is no constraint or the modifier is not Typeinfo.
    typeinfo_constraints: ?[]const []const u8 = null,
};

/// A generic type parameter, e.g. `T` or `R` in `fn select<T, R>(...)`.
pub const GenericParam = struct {
    name: []const u8,
};

/// A method declared inside a interface.
/// If `body` is null the method is abstract (no default implementation).
pub const InterfaceMethod = struct {
    name: []const u8,
    /// Generic type parameters, e.g. `<T, R>`. Empty slice when not generic.
    generic_params: []GenericParam = &.{},
    params: []Param,
    body: ?[]Stmt,

    pub fn deinit(self: *InterfaceMethod, allocator: std.mem.Allocator) void {
        allocator.free(self.generic_params);
        allocator.free(self.params);
        if (self.body) |stmts| {
            for (stmts) |*s| s.deinit(allocator);
            allocator.free(stmts);
        }
    }
};

/// `val Name = interface { ... }`  or  `val Name<T> = interface { ... }`
pub const InterfaceDecl = struct {
    name: []const u8,
    /// Generic type parameters on the interface itself, e.g. `<T>`.
    generic_params: []GenericParam = &.{},
    fields: []InterfaceField,
    methods: []InterfaceMethod,

    pub fn deinit(self: *InterfaceDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.generic_params);
        allocator.free(self.fields);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};

// ── struct decl ───────────────────────────────────────────────────────────────

/// A field declared inside a struct.
/// `private val _name: type = defaultValue`  or  `val name: type = defaultValue`
pub const StructField = struct {
    is_private: bool,
    name: []const u8,
    type_name: []const u8,
    /// The initializer expression (required in struct fields).
    init: Expr,

    pub fn deinit(self: *StructField, allocator: std.mem.Allocator) void {
        self.init.deinit(allocator);
    }
};

/// `get name(self: Self): ReturnType { ... }`
pub const StructGetter = struct {
    name: []const u8,
    self_param: Param,
    return_type: []const u8,
    body: []Stmt,

    pub fn deinit(self: *StructGetter, allocator: std.mem.Allocator) void {
        for (self.body) |*s| s.deinit(allocator);
        allocator.free(self.body);
    }
};

/// `set name(self: Self, value: Type) { ... }`
pub const StructSetter = struct {
    name: []const u8,
    params: []Param,
    body: []Stmt,

    pub fn deinit(self: *StructSetter, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
        for (self.body) |*s| s.deinit(allocator);
        allocator.free(self.body);
    }
};

/// A member inside a struct body.
pub const StructMember = union(enum) {
    Field: StructField,
    Getter: StructGetter,
    Setter: StructSetter,
    Method: InterfaceMethod, // re-use InterfaceMethod for fn members

    pub fn deinit(self: *StructMember, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .Field => |*f| f.deinit(allocator),
            .Getter => |*g| g.deinit(allocator),
            .Setter => |*s| s.deinit(allocator),
            .Method => |*m| m.deinit(allocator),
        }
    }
};

/// `val Name = struct { ... }`  or  `val Name<T> = struct { ... }`
pub const StructDecl = struct {
    name: []const u8,
    /// Generic type parameters on the struct, e.g. `<T, R>`.
    generic_params: []GenericParam = &.{},
    members: []StructMember,

    pub fn deinit(self: *StructDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.generic_params);
        for (self.members) |*m| m.deinit(allocator);
        allocator.free(self.members);
    }
};

// ── top-level program ─────────────────────────────────────────────────────────

pub const DeclKind = union(enum) {
    Record: RecordDecl,
    Implement: ImplementDecl,
    Use: UseDecl,
    Interface: InterfaceDecl,
    Struct: StructDecl,

    pub fn deinit(self: *DeclKind, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .Use => |*u| allocator.free(u.imports),
            .Interface => |*t| t.deinit(allocator),
            .Struct => |*s| s.deinit(allocator),
            .Record => |*r| r.deinit(allocator),
            .Implement => |*i| i.deinit(allocator),
        }
    }
};

pub const Program = struct {
    decls: []DeclKind,

    pub fn deinit(self: *Program, allocator: std.mem.Allocator) void {
        for (self.decls) |*d| d.deinit(allocator);
        allocator.free(self.decls);
    }
};

// ── record decl ───────────────────────────────────────────────────────────────

/// A field in a record's parameter list: `val name: Type`
pub const RecordField = struct {
    name: []const u8,
    type_name: []const u8,
};

/// `val Name = record(val f1: T1, val f2: T2) { fn ... }`
/// or `val Name<T> = record(val item: T) { fn ... }`
pub const RecordDecl = struct {
    name: []const u8,
    /// Generic type parameters on the record, e.g. `<T>`.
    generic_params: []GenericParam = &.{},
    /// Inline fields declared in the parameter list.
    fields: []RecordField,
    /// Methods declared in the body (use InterfaceMethod; body is always present).
    methods: []InterfaceMethod,

    pub fn deinit(self: *RecordDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.generic_params);
        allocator.free(self.fields);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};

// ── implement decl ─────────────────────────────────────────────────────────────────

/// A method inside an implement block.
/// The name may be qualified: `UsbCharger.Conectar` or plain `doSomething`.
pub const ImplementMethod = struct {
    /// interface qualifier, e.g. "UsbCharger" — null for unqualified methods.
    qualifier: ?[]const u8,
    /// The bare method name, e.g. "Conectar".
    name: []const u8,
    params: []Param,
    body: []Stmt,

    pub fn deinit(self: *ImplementMethod, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
        for (self.body) |*s| s.deinit(allocator);
        allocator.free(self.body);
    }
};

/// `val Name = implement interface1, interface2 for TargetType { fn ... }`
/// or `val Name<T> = implement Container<T> for MyType { fn ... }`
pub const ImplementDecl = struct {
    name: []const u8,
    /// Generic type parameters on the implement block, e.g. `<T>`.
    generic_params: []GenericParam = &.{},
    /// interfaces being implemented, e.g. ["UsbCharger", "SolarCharger"].
    interfaces: []const []const u8,
    /// The type this implement is for, e.g. "SmartCamera".
    target: []const u8,
    methods: []ImplementMethod,

    pub fn deinit(self: *ImplementDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.generic_params);
        allocator.free(self.interfaces);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};
