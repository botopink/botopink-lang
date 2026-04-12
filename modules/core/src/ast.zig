const std = @import("std");

/// Compilation phase tag ---- distinguishes AST nodes before and after type inference.
pub const Phase = enum { untyped, typed };

// ── use decl ──────────────────────────────────────────────────────────────────

pub const Source = union(enum) {
    stringPath: []const u8,
    functionCall: []const u8,
};

pub const UseDecl = struct {
    imports: []const []const u8,
    source: Source,
};

/// Source location of a node: line and column (both 1-based).
pub const Loc = struct {
    line: usize,
    col: usize,
};

// ── parameterized expression types ────────────────────────────────────────────
//
// Each helper is a comptime function keyed on `Phase`.
// The `.untyped` instantiation matches the pre-existing shape exactly.
// The `.typed` instantiation adds `type_: *types.Type` to every `Expr` node.
//
// Backward-compat aliases after the functions keep existing call-sites untouched.

/// A call argument: positional when `label` is null, named otherwise.
pub fn CallArgOf(comptime phase: Phase) type {
    return struct {
        const Self = @This();
        /// null for positional args; non-null for named args (`fator: 2`).
        label: ?[]const u8,
        value: *ExprOf(phase),

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.value.deinit(allocator);
            allocator.destroy(self.value);
        }
    };
}

/// A trailing lambda argument, optionally labeled.
/// Unlabeled: `{ a, b -> body }`  Labeled: `erro: { body }`
pub fn TrailingLambdaOf(comptime phase: Phase) type {
    return struct {
        const Self = @This();
        label: ?[]const u8,
        /// Parameter names (types are inferred). Empty when the lambda takes no params.
        params: []const []const u8,
        body: []StmtOf(phase),

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            allocator.free(self.params);
            for (self.body) |*s| s.deinit(allocator);
            allocator.free(self.body);
        }
    };
}

/// A statement inside a method body (expression-statement only for now).
pub fn StmtOf(comptime phase: Phase) type {
    return struct {
        const Self = @This();
        expr: ExprOf(phase),

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.expr.deinit(allocator);
        }
    };
}

/// One arm of a `case` expression: `pattern -> expr`.
pub fn CaseArmOf(comptime phase: Phase) type {
    return struct {
        const Self = @This();
        pattern: Pattern,
        body: ExprOf(phase),

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.pattern.deinit(allocator);
            self.body.deinit(allocator);
        }
    };
}

/// An expression node parameterised by compilation phase.
///
/// `.untyped` ---- parser output, no type information.
/// `.typed`   ---- after type inference; every node carries `type_: *types.Type`.
pub fn ExprOf(comptime phase: Phase) type {
    return struct {
        const Self = @This();

        /// Shared payload for all binary-operator expression nodes.
        pub const BinOp = struct { lhs: *Self, rhs: *Self };

        /// The kind of expression ---- the payload of this node.
        pub const Kind = union(enum) {
            /// A string literal value, e.g. `"hello"`
            stringLit: []const u8,
            /// A number literal, e.g. `0`
            numberLit: []const u8,
            /// Identifier-based access: `self.field`, `Color.Red`, `obj.x`
            identAccess: struct {
                receiver: *Self,
                member: []const u8,
            },
            /// Assign to a field, e.g. `self._balance = value`
            fieldAssign: struct {
                receiver: *Self,
                field: []const u8,
                value: *Self,
            },
            /// `self._field += amount`
            fieldPlusEq: struct {
                receiver: *Self,
                field: []const u8,
                value: *Self,
            },
            /// A plain identifier, e.g. `Console`
            ident: []const u8,
            /// Static method call, e.g. `Console.WriteLine(arg)`
            staticCall: struct {
                receiver: []const u8,
                method: []const u8,
                arg: *Self,
            },
            /// `throw expr` — throw any expression (e.g. a constructor call)
            throw_: *Self,
            /// `null` literal
            null_,
            /// `if (cond) { [binding ->] then } [else { else_ }]`
            if_: struct {
                cond: *Self,
                /// Optional binding for null-check form: `if (email) { e -> ... }`
                binding: ?[]const u8,
                then_: []StmtOf(phase),
                else_: ?[]StmtOf(phase),
            },
            /// `try expr` — propagate error union failure upward
            try_: *Self,
            /// `try expr catch handler` — handle error inline
            tryCatch: struct {
                expr: *Self,
                handler: *Self,
            },
            /// `return expr`
            @"return": *Self,
            /// Binary `<`
            lt: BinOp,
            /// Binary `+`
            add: BinOp,
            /// Binary `-`
            sub: BinOp,
            /// Binary `/`
            div: BinOp,
            /// Binary `%`
            mod: BinOp,
            /// Binary `*`
            mul: BinOp,
            /// Binary `>`
            gt: BinOp,
            /// Binary `<=`
            lte: BinOp,
            /// Binary `>=`
            gte: BinOp,
            /// Binary `==`
            eq: BinOp,
            /// Binary `!=`
            ne: BinOp,
            /// A lambda expression: `{ a, b -> stmts }` or `{ stmts }` (no params).
            lambda: struct {
                /// Parameter names (inferred types). Empty for no-param lambdas.
                params: []const []const u8,
                body: []StmtOf(phase),
            },
            /// A function or method call with optional named args and trailing lambda blocks.
            ///
            /// Examples:
            ///   `calcular(fator: 2) { a, b -> ... }`   receiver=null, callee="calcular"
            ///   `executar { ... } erro: { ... }`        receiver=null, callee="executar"
            ///   `precos.forEach { fruta, valor -> ... }` receiver="precos", callee="forEach"
            call: struct {
                /// null for plain calls; the object for method calls.
                receiver: ?[]const u8,
                callee: []const u8,
                args: []CallArgOf(phase),
                trailing: []TrailingLambdaOf(phase),
            },
            /// `case .identifier{ arm* }` or `case (expr) { arm* }`
            case: struct {
                subject: *Self,
                arms: []CaseArmOf(phase),
            },
            /// `val name = expr` (immutable) or `var name = expr` (mutable)
            localBind: struct {
                name: []const u8,
                value: *Self,
                /// true when declared with `var`, false for `val`
                mutable: bool,
            },
            /// `name = expr` ---- assign to a previously declared `var` binding
            assign: struct {
                name: []const u8,
                value: *Self,
            },
            /// Destructuring val/var binding: `val (a, b) = expr` or `val { name } = expr`
            localBindDestruct: struct {
                pattern: ParamDestruct,
                value: *Self,
                mutable: bool,
            },
            /// Dot-shorthand variant: `.Red` ---- the type is inferred from context.
            dotIdent: []const u8,
            /// `@name(args...)` ---- built-in function call, e.g. `@sizeOf(T)`, `@panic("msg")`
            builtinCall: struct {
                /// The builtin name including the leading `@`, e.g. `"@sizeOf"`.
                name: []const u8,
                args: []CallArgOf(phase),
            },
            /// `[e1, e2, ...]` ---- array literal
            arrayLit: []Self,
            /// `tuple(e1, e2, ...)` ---- tuple literal
            tupleLit: []Self,
            /// `todo` ---- placeholder expression, marks unimplemented bodies
            todo,
            /// `comptime expr` ---- evaluate expression at compile time
            @"comptime": *Self,
            /// `comptime { break expr; ... }` ---- comptime block
            comptimeBlock: struct { body: []StmtOf(phase) },
            /// `break [expr]` ---- exit a block/loop early; expr=null means bare `break`
            @"break": ?*Self,
            /// `yield expr` ---- accumulate `expr` into a loop's result list; loop continues
            yield: *Self,
            /// `continue` ---- skip the rest of this loop iteration
            @"continue",
            /// `start..end` or `start..` ---- integer range (end=null means open)
            range: struct {
                start: *Self,
                end: ?*Self,
            },
            /// `loop (iter) { params -> body }` or `loop (iter, 0..) { item, i -> body }`
            loop: struct {
                /// Primary iterable expression.
                iter: *Self,
                /// Optional index range (the `0..` in `loop (iter, 0..)`). Null if no index.
                indexRange: ?*Self,
                /// Bound variable names (e.g. `["item"]` or `["item", "i"]`).
                params: []const []const u8,
                body: []StmtOf(phase),
            },
            pub fn deinit(self: *Kind, allocator: std.mem.Allocator) void {
                switch (self.*) {
                    .identAccess => |a| {
                        a.receiver.deinit(allocator);
                        allocator.destroy(a.receiver);
                    },
                    .fieldAssign => |a| {
                        a.receiver.deinit(allocator);
                        allocator.destroy(a.receiver);
                        a.value.deinit(allocator);
                        allocator.destroy(a.value);
                    },
                    .fieldPlusEq => |a| {
                        a.receiver.deinit(allocator);
                        allocator.destroy(a.receiver);
                        a.value.deinit(allocator);
                        allocator.destroy(a.value);
                    },
                    .staticCall => |c| {
                        c.arg.deinit(allocator);
                        allocator.destroy(c.arg);
                    },
                    .throw_ => |e| {
                        e.deinit(allocator);
                        allocator.destroy(e);
                    },
                    .null_ => {},
                    .if_ => |i| {
                        i.cond.deinit(allocator);
                        allocator.destroy(i.cond);
                        for (i.then_) |*s| s.deinit(allocator);
                        allocator.free(i.then_);
                        if (i.else_) |els| {
                            for (els) |*s| @constCast(s).deinit(allocator);
                            allocator.free(els);
                        }
                    },
                    .try_ => |e| {
                        e.deinit(allocator);
                        allocator.destroy(e);
                    },
                    .tryCatch => |tc| {
                        tc.expr.deinit(allocator);
                        allocator.destroy(tc.expr);
                        tc.handler.deinit(allocator);
                        allocator.destroy(tc.handler);
                    },
                    .@"return" => |r| {
                        r.deinit(allocator);
                        allocator.destroy(r);
                    },
                    .lambda => |l| {
                        allocator.free(l.params);
                        for (l.body) |*s| s.deinit(allocator);
                        allocator.free(l.body);
                    },
                    .builtinCall => |c| {
                        for (c.args) |*a| a.deinit(allocator);
                        allocator.free(c.args);
                    },
                    .call => |c| {
                        for (c.args) |*a| a.deinit(allocator);
                        allocator.free(c.args);
                        for (c.trailing) |*t| t.deinit(allocator);
                        allocator.free(c.trailing);
                    },
                    .case => |c| {
                        c.subject.deinit(allocator);
                        allocator.destroy(c.subject);
                        for (c.arms) |*a| a.deinit(allocator);
                        allocator.free(c.arms);
                    },
                    .localBind => |lb| {
                        lb.value.deinit(allocator);
                        allocator.destroy(lb.value);
                    },
                    .assign => |a| {
                        a.value.deinit(allocator);
                        allocator.destroy(a.value);
                    },
                    .localBindDestruct => |lb| {
                        switch (lb.pattern) {
                            .record_, .tuple_ => |ns| allocator.free(ns),
                        }
                        lb.value.deinit(allocator);
                        allocator.destroy(lb.value);
                    },
                    .@"comptime" => |e| {
                        e.deinit(allocator);
                        allocator.destroy(e);
                    },
                    .comptimeBlock => |cb| {
                        for (cb.body) |*s| s.deinit(allocator);
                        allocator.free(cb.body);
                    },
                    .@"break" => |e| {
                        if (e) |ep| {
                            ep.deinit(allocator);
                            allocator.destroy(ep);
                        }
                    },
                    .yield => |e| {
                        e.deinit(allocator);
                        allocator.destroy(e);
                    },
                    .range => |r| {
                        r.start.deinit(allocator);
                        allocator.destroy(r.start);
                        if (r.end) |e| {
                            e.deinit(allocator);
                            allocator.destroy(e);
                        }
                    },
                    .loop => |lp| {
                        lp.iter.deinit(allocator);
                        allocator.destroy(lp.iter);
                        if (lp.indexRange) |ir| {
                            ir.deinit(allocator);
                            allocator.destroy(ir);
                        }
                        allocator.free(lp.params);
                        for (lp.body) |*s| s.deinit(allocator);
                        allocator.free(lp.body);
                    },
                    .lt, .add, .sub, .div, .mod, .mul, .gt, .lte, .gte, .eq, .ne => |b| {
                        b.lhs.deinit(allocator);
                        allocator.destroy(b.lhs);
                        b.rhs.deinit(allocator);
                        allocator.destroy(b.rhs);
                    },
                    .arrayLit => |elems| {
                        for (elems) |*e| e.deinit(allocator);
                        allocator.free(elems);
                    },
                    .tupleLit => |elems| {
                        for (elems) |*e| e.deinit(allocator);
                        allocator.free(elems);
                    },
                    else => {},
                }
            }
        };

        loc: Loc,
        kind: Kind,
        /// Type annotation ---- `void` (zero size) in `.untyped`, `*types.Type` in `.typed`.
        /// `.untyped` defaults to `{}` so parser call-sites need not mention the field.
        /// `.typed` defaults to `undefined`; the type checker must set it before use.
        /// Not freed in `deinit` ---- types are arena-owned by the type checker.
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        pub fn deinit(self: *Self, allocator: std.mem.Allocator) void {
            self.kind.deinit(allocator);
        }

        // ── public surface ────────────────────────────────────────────────────────────

        /// Returns true when the top-level typed expression is a comptime node.
        pub fn isComptimeExpr(self: *const Self) bool {
            return switch (self.kind) {
                .@"comptime", .comptimeBlock => true,
                else => false,
            };
        }
    };
}

// ── backward-compat aliases ───────────────────────────────────────────────────

/// Untyped expression ---- parser output, before type inference.
pub const Expr = ExprOf(.untyped);
/// Typed expression ---- after type inference, every node carries `type_: *types.Type`.
pub const TypedExpr = ExprOf(.typed);

/// Expression-kind union for untyped expressions.
pub const ExprKind = Expr.Kind;

/// Untyped statement.
pub const Stmt = StmtOf(.untyped);
/// Untyped case arm.
pub const CaseArm = CaseArmOf(.untyped);
/// Untyped call argument.
pub const CallArg = CallArgOf(.untyped);
/// Untyped trailing lambda.
pub const TrailingLambda = TrailingLambdaOf(.untyped);

// ── patterns ──────────────────────────────────────────────────────────────────

/// One element inside a list pattern: `_`, `x`, `42`.
pub const ListPatternElem = union(enum) {
    /// `_`
    wildcard,
    /// Named binding, e.g. `first`
    bind: []const u8,
    /// Number literal, e.g. `1`, `4`
    numberLit: []const u8,
};

/// A match pattern used in `case` arms.
pub const Pattern = union(enum) {
    /// `_`
    wildcard,
    /// enum variant or variable binding: `Red`, `x`, `total`
    ident: []const u8,
    /// enum variant with bound fields: `Rgb(r, g, b)`
    variantFields: struct {
        name: []const u8,
        bindings: []const []const u8,
    },
    /// Number literal: `42`
    numberLit: []const u8,
    /// String literal: `"hello"`
    stringLit: []const u8,
    /// List pattern: `[]`, `[1]`, `[4, ..]`, `[first, ..rest]`
    list: struct {
        /// Elements before the optional spread.
        elems: []ListPatternElem,
        /// null = no spread; "" = anonymous `..`; "rest" = named `..rest`
        spread: ?[]const u8,
    },
    /// OR pattern: `2 | 4 | 6 | 8`
    @"or": []Pattern,

    pub fn deinit(self: *Pattern, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .variantFields => |vf| allocator.free(vf.bindings),
            .list => |l| allocator.free(l.elems),
            .@"or" => |pats| {
                for (pats) |*p| p.deinit(allocator);
                allocator.free(pats);
            },
            else => {},
        }
    }
};

// ── interface decl ────────────────────────────────────────────────────────────────

/// A field declared inside a interface: `val name: Type`
pub const InterfaceField = struct {
    name: []const u8,
    typeName: []const u8,
};

/// Modifier on a parameter type ---- controls how the argument is treated.
pub const ParamModifier = enum {
    /// No modifier ---- normal evaluated argument.
    none,
    /// `comptime` ---- argument must be known at compile time.
    @"comptime",
    /// `syntax` ---- argument is passed as an unevaluated expression tree (AST).
    syntax,
    /// `typeinfo` ---- argument is a type used as a value; constraint lists allowed.
    typeinfo,
};

/// A parameter inside a function-type annotation used by `syntax` params.
/// Example: `item: T` in `fn(item: T) -> R`.
pub const FnTypeParam = struct {
    name: []const u8,
    typeName: []const u8,
};

/// A function-type annotation: `fn(item: T) -> R`.
/// Used as the type of `syntax` parameters.
pub const FnType = struct {
    params: []FnTypeParam,
    returnType: ?[]const u8,

    pub fn deinit(self: *FnType, allocator: std.mem.Allocator) void {
        allocator.free(self.params);
    }
};

/// Destructuring pattern for a parameter or local binding.
/// `.record_` matches named fields:       `{ name, age }`
/// `.tuple_`  matches positional elements: `tuple(a, b)`
pub const ParamDestruct = union(enum) {
    record_: []const []const u8,
    tuple_: []const []const u8,
};

/// A single parameter in a method/function signature.
/// Examples:
///   `x: Int`
///   `s comptime: string`
///   `lamb comptime: syntax fn(item: T) -> R`
///   `comptime: typeinfo T int | float`
pub const Param = struct {
    name: []const u8,
    typeName: []const u8,
    modifier: ParamModifier = .none,
    /// For `typeinfo` params: the union-of-types constraint, e.g. ["int","float"].
    /// Null when there is no constraint or the modifier is not Typeinfo.
    typeinfoConstraints: ?[]const []const u8 = null,
    /// For `syntax fn(...)` params: the function-type signature.
    /// Null for all other params.
    fnType: ?FnType = null,
    /// null for plain params; set for destructuring params.
    destruct: ?ParamDestruct = null,

    pub fn deinit(self: *Param, allocator: std.mem.Allocator) void {
        if (self.typeinfoConstraints) |c| allocator.free(c);
        if (self.fnType) |*ft| ft.deinit(allocator);
        if (self.destruct) |d| switch (d) {
            .record_, .tuple_ => |names| allocator.free(names),
        };
    }
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
    genericParams: []GenericParam = &.{},
    params: []Param,
    /// Return type annotation. null for void methods.
    returnType: ?TypeRef = null,
    body: ?[]Stmt,
    /// true when declared with `default fn` in an interface body
    is_default: bool = false,
    /// true when declared with `declare fn` inside a struct/record/enum body
    is_declare: bool = false,
    isPub: bool = false,

    pub fn deinit(self: *InterfaceMethod, allocator: std.mem.Allocator) void {
        allocator.free(self.genericParams);
        for (self.params) |*p| p.deinit(allocator);
        allocator.free(self.params);
        if (self.returnType) |*rt| rt.deinit(allocator);
        if (self.body) |stmts| {
            for (stmts) |*s| s.deinit(allocator);
            allocator.free(stmts);
        }
    }
};

/// A single-method interface type alias declared as:
///   `val log = declare fn(self: Self)` or
///   `[pub] declare fn log(self: Self)`
pub const DelegateDecl = struct {
    name: []const u8,
    isPub: bool = false,
    params: []Param,
    returnType: ?[]const u8 = null,

    pub fn deinit(self: *DelegateDecl, allocator: std.mem.Allocator) void {
        for (self.params) |*p| p.deinit(allocator);
        allocator.free(self.params);
    }
};

/// A single annotation applied to a declaration: `#[name]` or `#[name(arg1, arg2)]`.
pub const Annotation = struct {
    name: []const u8,
    /// Raw argument lexemes (may span adjacent source tokens, e.g. `.erlang`).
    args: []const []const u8,

    pub fn deinit(self: *Annotation, allocator: std.mem.Allocator) void {
        allocator.free(self.args);
    }
};

/// `val Name = interface { ... }`  or  `val Name = interface <T> { ... }`
pub const InterfaceDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"interface_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the interface itself, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    /// Super-interfaces listed in `extends T1, T2` clause. Empty when absent.
    extends: []const []const u8 = &.{},
    fields: []InterfaceField,
    methods: []InterfaceMethod,

    pub fn deinit(self: *InterfaceDecl, allocator: std.mem.Allocator) void {
        for (self.annotations) |*ann| ann.deinit(allocator);
        allocator.free(self.annotations);
        allocator.free(self.genericParams);
        allocator.free(self.extends);
        allocator.free(self.fields);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};

// ── struct decl ───────────────────────────────────────────────────────────────

/// A field declared inside a struct.
/// `name: type` or `name: type = defaultValue`
pub const StructField = struct {
    name: []const u8,
    typeName: []const u8,
    /// Optional initializer expression.
    init: ?Expr,

    pub fn deinit(self: *StructField, allocator: std.mem.Allocator) void {
        if (self.init) |*expr| expr.deinit(allocator);
    }
};

/// `get name(self: Self): ReturnType { ... }`
pub const StructGetter = struct {
    name: []const u8,
    selfParam: Param,
    returnType: []const u8,
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
        for (self.params) |*p| p.deinit(allocator);
        allocator.free(self.params);
        for (self.body) |*s| s.deinit(allocator);
        allocator.free(self.body);
    }
};

/// A member inside a struct body.
pub const StructMember = union(enum) {
    field: StructField,
    getter: StructGetter,
    setter: StructSetter,
    method: InterfaceMethod, // re-use InterfaceMethod for fn members

    pub fn deinit(self: *StructMember, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .field => |*f| f.deinit(allocator),
            .getter => |*g| g.deinit(allocator),
            .setter => |*s| s.deinit(allocator),
            .method => |*m| m.deinit(allocator),
        }
    }
};

/// `val Name = struct { ... }`  or  `val Name = struct <T> { ... }`
pub const StructDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"struct_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the struct, e.g. `<T, R>`.
    genericParams: []GenericParam = &.{},
    members: []StructMember,

    pub fn deinit(self: *StructDecl, allocator: std.mem.Allocator) void {
        for (self.annotations) |*ann| ann.deinit(allocator);
        allocator.free(self.annotations);
        allocator.free(self.genericParams);
        for (self.members) |*m| m.deinit(allocator);
        allocator.free(self.members);
    }
};

// ── enum decl ─────────────────────────────────────────────────────────────────

/// A named field inside an enum variant with a payload: `r: Int` or `reason: ?string`
pub const EnumVariantField = struct {
    name: []const u8,
    typeRef: TypeRef,

    pub fn deinit(self: *EnumVariantField, allocator: std.mem.Allocator) void {
        self.typeRef.deinit(allocator);
    }
};

/// One variant of an enum.
/// Simple:  `Red`
/// Payload: `Rgb(r: Int, g: Int, b: Int)`
pub const EnumVariant = struct {
    name: []const u8,
    /// Empty for simple (unit) variants; non-empty for payload variants.
    fields: []EnumVariantField,

    pub fn deinit(self: *EnumVariant, allocator: std.mem.Allocator) void {
        for (self.fields) |*f| f.deinit(allocator);
        allocator.free(self.fields);
    }
};

/// `val Color = enum { Red, Green, Rgb(r: Int, g: Int, b: Int) }` or `val Option = enum <T> { ... }`
pub const EnumDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"enum_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    genericParams: []GenericParam = &.{},
    variants: []EnumVariant,
    /// Methods declared after the variant list (may include `declare fn` abstract slots).
    methods: []InterfaceMethod = &.{},

    pub fn deinit(self: *EnumDecl, allocator: std.mem.Allocator) void {
        for (self.annotations) |*ann| ann.deinit(allocator);
        allocator.free(self.annotations);
        allocator.free(self.genericParams);
        for (self.variants) |*v| v.deinit(allocator);
        allocator.free(self.variants);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};

// ── type reference ────────────────────────────────────────────────────────────

/// A type annotation expression, e.g. `Int`, `string[]`, `#(Int, string)`, `?T`, `E!T`.
pub const TypeRef = union(enum) {
    /// Plain named type: `Int`, `string`, `Self`. Slice into source — not heap-owned.
    named: []const u8,
    /// Array type: `T[]`. Owns the element type.
    array: *TypeRef,
    /// Tuple type: `#(T1, T2, ...)`. Owns the element types.
    tuple_: []TypeRef,
    /// Optional type: `?T`. Owns the inner type.
    optional: *TypeRef,
    /// Error-union type: `E!T`. Owns both sides.
    errorUnion: struct { errorType: *TypeRef, payload: *TypeRef },

    pub fn deinit(self: *TypeRef, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .named => {},
            .array => |elem| {
                elem.deinit(allocator);
                allocator.destroy(elem);
            },
            .tuple_ => |elems| {
                for (elems) |*e| e.deinit(allocator);
                allocator.free(elems);
            },
            .optional => |inner| {
                inner.deinit(allocator);
                allocator.destroy(inner);
            },
            .errorUnion => |eu| {
                eu.errorType.deinit(allocator);
                allocator.destroy(eu.errorType);
                eu.payload.deinit(allocator);
                allocator.destroy(eu.payload);
            },
        }
    }
};

// ── top-level program ─────────────────────────────────────────────────────────

/// Top-level constant binding: `val name = expr` or `val name: Type = expr`
pub const ValDecl = struct {
    name: []const u8,
    isPub: bool = false,
    /// Optional explicit type annotation, e.g. `Color` in `val c: Color = .Red`
    /// or `string[]` in `val xs: string[] = [...]`.
    typeAnnotation: ?TypeRef = null,
    value: *Expr,

    pub fn deinit(self: *ValDecl, allocator: std.mem.Allocator) void {
        if (self.typeAnnotation) |*ann| ann.deinit(allocator);
        self.value.deinit(allocator);
        allocator.destroy(self.value);
    }
};

pub const DeclKind = union(enum) {
    record: RecordDecl,
    implement: ImplementDecl,
    use: UseDecl,
    interface: InterfaceDecl,
    delegate: DelegateDecl,
    @"struct": StructDecl,
    @"enum": EnumDecl,
    @"fn": FnDecl,
    val: ValDecl,

    pub fn deinit(self: *DeclKind, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .use => |*u| allocator.free(u.imports),
            .interface => |*t| t.deinit(allocator),
            .delegate => |*d| d.deinit(allocator),
            .@"struct" => |*s| s.deinit(allocator),
            .record => |*r| r.deinit(allocator),
            .implement => |*i| i.deinit(allocator),
            .@"enum" => |*e| e.deinit(allocator),
            .@"fn" => |*f| f.deinit(allocator),
            .val => |*v| v.deinit(allocator),
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

// ── fn decl ───────────────────────────────────────────────────────────────────

/// `pub fn name<T>(params) ReturnType { body }`
/// `isPub` is false for module-private functions.
pub const FnDecl = struct {
    isPub: bool,
    name: []const u8,
    annotations: []Annotation = &.{},
    /// Generic type parameters, e.g. `<T, R>`. Empty slice when not generic.
    genericParams: []GenericParam,
    params: []Param,
    /// null when the return type is omitted (void-returning functions).
    returnType: ?TypeRef,
    body: []Stmt,

    pub fn deinit(self: *FnDecl, allocator: std.mem.Allocator) void {
        for (self.annotations) |*ann| ann.deinit(allocator);
        allocator.free(self.annotations);
        allocator.free(self.genericParams);
        for (self.params) |*p| p.deinit(allocator);
        allocator.free(self.params);
        if (self.returnType) |*rt| rt.deinit(allocator);
        for (self.body) |*s| s.deinit(allocator);
        allocator.free(self.body);
    }
};

// ── record decl ───────────────────────────────────────────────────────────────

/// A field in a record's parameter list: `name: Type` or `name: ?Type = default`
pub const RecordField = struct {
    name: []const u8,
    typeRef: TypeRef,
    /// Optional default value, e.g. `= null` or `= 0`.
    default: ?Expr = null,

    pub fn deinit(self: *RecordField, allocator: std.mem.Allocator) void {
        self.typeRef.deinit(allocator);
        if (self.default) |*d| d.deinit(allocator);
    }
};

/// `val Name = record(val f1: T1, val f2: T2) { fn ... }`
/// or `val Name = record <T>(val item: T) { fn ... }`
pub const RecordDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"record_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the record, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    /// Inline fields declared in the parameter list.
    fields: []RecordField,
    /// Methods declared in the body (use InterfaceMethod; body is always present).
    methods: []InterfaceMethod,

    pub fn deinit(self: *RecordDecl, allocator: std.mem.Allocator) void {
        for (self.annotations) |*ann| ann.deinit(allocator);
        allocator.free(self.annotations);
        allocator.free(self.genericParams);
        for (self.fields) |*f| f.deinit(allocator);
        allocator.free(self.fields);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};

// ── implement decl ─────────────────────────────────────────────────────────────────

/// A method inside an implement block.
/// The name may be qualified: `UsbCharger.Conectar` or plain `doSomething`.
pub const ImplementMethod = struct {
    /// interface qualifier, e.g. "UsbCharger" ---- null for unqualified methods.
    qualifier: ?[]const u8,
    /// The bare method name, e.g. "Conectar".
    name: []const u8,
    params: []Param,
    body: []Stmt,

    pub fn deinit(self: *ImplementMethod, allocator: std.mem.Allocator) void {
        for (self.params) |*p| p.deinit(allocator);
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
    genericParams: []GenericParam = &.{},
    /// interfaces being implemented, e.g. ["UsbCharger", "SolarCharger"].
    interfaces: []const []const u8,
    /// The type this implement is for, e.g. "SmartCamera".
    target: []const u8,
    methods: []ImplementMethod,

    pub fn deinit(self: *ImplementDecl, allocator: std.mem.Allocator) void {
        allocator.free(self.genericParams);
        allocator.free(self.interfaces);
        for (self.methods) |*m| m.deinit(allocator);
        allocator.free(self.methods);
    }
};
