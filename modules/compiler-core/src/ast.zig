const std = @import("std");

/// Compilation phase tag ---- distinguishes AST nodes before and after type inference.
pub const Phase = enum { untyped, typed };

// ── use decl ──────────────────────────────────────────────────────────────────

pub const Source = union(enum) {
    stringPath: []const u8,
    functionCall: []const u8,
};

pub const CommentKind = union(enum) {
    /// `// ...` — regular inline comment (non-documenting)
    normal: []const u8,
    /// `/// ...` — documentation comment for types/functions
    doc: []const u8,
    /// `//// ...` — module-level documentation
    module: []const u8,
};

/// A comment or doc comment attached to a declaration.
pub const Comment = struct {
    kind: CommentKind,
    /// Combined text of consecutive same-kind comments (joined by `\n`).
    text: []const u8,

    pub fn deinit(this: *Comment, allocator: std.mem.Allocator) void {
        allocator.free(this.text);
    }
};
pub const UseDecl = struct {
    imports: []const []const u8,
    source: Source,
    /// `///` documentation comment (multi-line joined with `\n`)
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
};

/// Source location of a node: line and column (both 1-based).
pub const Loc = struct {
    line: usize,
    col: usize,
};

// ── Statement types ───────────────────────────────────────────────────────────

// ── Expression kind categories (parameterized by phase) ───────────────────────

/// Literal expressions: constant values and comments
pub fn LiteralExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of literal expression
        kind: union(enum) {
            /// A string literal value, e.g. `"hello"`
            stringLit: []const u8,
            /// A number literal, e.g. `0`
            numberLit: []const u8,
            /// `null` literal
            null_,
            /// A comment treated as an expression: `//` normal, `///` doc, or `////` module.
            /// `kind` tells you which type; `text` is the content without the leading slashes.
            comment: struct {
                kind: CommentKind,
                text: []const u8,
            },

            pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
                switch (this.*) {
                    .stringLit, .numberLit, .null_ => {},
                    .comment => |c| allocator.free(c.text),
                }
            }
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.kind.deinit(allocator);
        }
    };
}

// ── Top-level expression types ─────────────────────────────────────────────────────

/// Expression node parameterized by compilation phase.
/// Use the `Expr` and `TypedExpr` aliases; do not name this type directly.
pub fn ExprOf(comptime phase: Phase) type {
    return union(enum) {
        literal: LiteralExprOf(phase),
        identifier: IdentifierExprOf(phase),
        binaryOp: BinOpExprOf(phase),
        unaryOp: UnaryOpExprOf(phase),
        controlFlow: ControlFlowExprOf(phase),
        binding: BindingExprOf(phase),
        call: CallExprOf(phase),
        function: FunctionExprOf(phase),
        collection: CollectionExprOf(phase),
        comptime_: ComptimeExprOf(phase),

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                inline else => |*e| e.deinit(allocator),
            }
        }

        /// Source location of this expression.
        pub fn getLoc(this: *const @This()) Loc {
            return switch (this.*) {
                inline else => |*e| e.loc,
            };
        }

        /// Returns true when this is a comptime expression.
        pub fn isComptimeExpr(this: *const @This()) bool {
            return switch (this.*) {
                .comptime_ => |*c| switch (c.kind) {
                    .comptimeExpr, .comptimeBlock => true,
                    else => false,
                },
                else => false,
            };
        }

        /// Inferred type of this expression. Only valid on `TypedExpr` (phase == .typed).
        pub fn getType(this: *const @This()) *@import("./comptime/types.zig").Type {
            if (comptime phase != .typed) @compileError("getType() is only available on TypedExpr");
            return switch (this.*) {
                inline else => |*e| e.type_,
            };
        }
    };
}

/// Untyped expression (parser output, before type inference).
pub const Expr = ExprOf(.untyped);
/// Typed expression (after type inference; every node carries its inferred type).
pub const TypedExpr = ExprOf(.typed);

// ── Untyped subtype aliases ────────────────────────────────────────────────────
pub const LiteralExpr = LiteralExprOf(.untyped);
pub const IdentifierExpr = IdentifierExprOf(.untyped);
pub const BinOpExpr = BinOpExprOf(.untyped);
pub const UnaryOpExpr = UnaryOpExprOf(.untyped);
pub const ControlFlowExpr = ControlFlowExprOf(.untyped);
pub const BindingExpr = BindingExprOf(.untyped);
pub const FunctionExpr = FunctionExprOf(.untyped);
pub const CollectionExpr = CollectionExprOf(.untyped);
pub const ComptimeExpr = ComptimeExprOf(.untyped);

/// Helper to get the correct statement type based on phase
pub fn StmtOf(comptime phase: Phase) type {
    return struct {
        expr: if (phase == .untyped) Expr else TypedExpr,
        /// Number of empty lines before this statement in the source
        emptyLinesBefore: u32 = 0,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.expr.deinit(allocator);
        }
    };
}

/// Helper to get the correct call argument type based on phase
pub fn CallArgOf(comptime phase: Phase) type {
    return struct {
        /// null for positional args; non-null for named args (`fator: 2`).
        label: ?[]const u8,
        value: if (phase == .untyped) *Expr else *TypedExpr,
        /// Comments appearing before this argument (text only, without `// `)
        comments: []const []const u8 = &.{},

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.value.deinit(allocator);
            allocator.destroy(this.value);
            for (this.comments) |c| allocator.free(c);
            allocator.free(this.comments);
        }
    };
}

/// Helper to get the correct trailing lambda type based on phase
pub fn TrailingLambdaOf(comptime phase: Phase) type {
    return struct {
        label: ?[]const u8,
        /// Parameter names (types are inferred). Empty when the lambda takes no params.
        params: []const []const u8,
        body: []StmtOf(phase),

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(this.params);
            for (this.body) |*s| s.deinit(allocator);
            allocator.free(this.body);
        }
    };
}

/// Helper to get the correct case arm type based on phase
pub fn CaseArmOf(comptime phase: Phase) type {
    return struct {
        pattern: Pattern,
        body: if (phase == .untyped) Expr else TypedExpr,
        /// Number of empty lines before this arm in the source
        emptyLinesBefore: u32 = 0,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.pattern.deinit(allocator);
            this.body.deinit(allocator);
        }
    };
}

/// Identifier expressions: name-based access and references
pub fn IdentifierExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of identifier expression
        kind: union(enum) {
            /// A plain identifier, e.g. `Console`
            ident: []const u8,
            /// Dot-shorthand variant: `.Red` ---- the type is inferred from context.
            dotIdent: []const u8,
            /// Identifier-based access: `this.field`, `Color.Red`, `obj.x`
            identAccess: struct {
                receiver: if (phase == .untyped) *Expr else *TypedExpr,
                member: []const u8,
            },

            pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
                switch (this.*) {
                    .ident, .dotIdent => {},
                    .identAccess => |a| {
                        a.receiver.deinit(allocator);
                        allocator.destroy(a.receiver);
                    },
                }
            }
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.kind.deinit(allocator);
        }
    };
}

/// Binary operations: all binary operators
pub fn BinOpExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of binary operation
        kind: union(enum) {
            /// Shared payload for all binary operators
            const BinOp = struct { lhs: if (phase == .untyped) *Expr else *TypedExpr, rhs: if (phase == .untyped) *Expr else *TypedExpr };

            /// Binary `<`
            lt: BinOp,
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
            /// Binary `+`
            add: BinOp,
            /// Binary `-`
            sub: BinOp,
            /// Binary `*`
            mul: BinOp,
            /// Binary `/`
            div: BinOp,
            /// Binary `%`
            mod: BinOp,
            /// Binary `&&` — logical and
            @"and": BinOp,
            /// Binary `||` — logical or
            @"or": BinOp,

            pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
                // All variants share the same BinOp structure
                const b = switch (this.*) {
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
                b.lhs.deinit(allocator);
                allocator.destroy(b.lhs);
                b.rhs.deinit(allocator);
                allocator.destroy(b.rhs);
            }
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.kind.deinit(allocator);
        }
    };
}

/// Unary operations: unary operators
pub fn UnaryOpExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of unary operation
        kind: union(enum) {
            /// Unary `!` — logical not
            not: if (phase == .untyped) *Expr else *TypedExpr,
            /// Unary `-` — numeric negation (e.g., `-x`, `-expr`)
            neg: if (phase == .untyped) *Expr else *TypedExpr,

            pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
                const e = switch (this.*) {
                    .not => |e| e,
                    .neg => |e| e,
                };
                e.deinit(allocator);
                allocator.destroy(e);
            }
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.kind.deinit(allocator);
        }
    };
}

/// Control flow expressions: branching, error propagation, and iteration
pub fn ControlFlowExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of control flow expression
        kind: union(enum) {
        /// `if (cond) { [binding ->] then } [else { else_ }]`
        if_: struct {
            cond: if (phase == .untyped) *Expr else *TypedExpr,
            /// Optional binding for null-check form: `if (email) { e -> ... }`
            binding: ?[]const u8,
            then_: []StmtOf(phase),
            else_: ?[]StmtOf(phase),
        },
        /// `return expr`
        @"return": if (phase == .untyped) *Expr else *TypedExpr,
        /// `throw expr` — throw any expression (e.g. a constructor call)
        throw_: if (phase == .untyped) *Expr else *TypedExpr,
        /// `try expr` — propagate error union failure upward
        try_: if (phase == .untyped) *Expr else *TypedExpr,
        /// `try expr catch handler` — handle error inline
        tryCatch: struct {
            expr: if (phase == .untyped) *Expr else *TypedExpr,
            handler: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// `loop (iter) { params -> body }` or `loop (iter, 0..) { item, i -> body }`
        loop: struct {
            iter: if (phase == .untyped) *Expr else *TypedExpr,
            indexRange: ?if (phase == .untyped) *Expr else *TypedExpr,
            params: []const []const u8,
            body: []StmtOf(phase),
        },
        /// `break [expr]` ---- exit a block/loop early; expr=null means bare `break`
        @"break": ?if (phase == .untyped) *Expr else *TypedExpr,
        /// `continue` ---- skip the rest of this loop iteration
        @"continue",
        /// `yield expr` ---- accumulate `expr` into a loop's result list; loop continues
        yield: if (phase == .untyped) *Expr else *TypedExpr,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
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
                .@"return" => |r| {
                    r.deinit(allocator);
                    allocator.destroy(r);
                },
                .throw_ => |e| {
                    e.deinit(allocator);
                    allocator.destroy(e);
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
                .@"break" => |e| {
                    if (e) |ep| {
                        ep.deinit(allocator);
                        allocator.destroy(ep);
                    }
                },
                .@"continue" => {},
                .yield => |e| {
                    e.deinit(allocator);
                    allocator.destroy(e);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

/// Binding expressions: variable declarations and assignments
pub fn BindingExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of binding expression
        kind: union(enum) {
        /// `val name = expr` (immutable) or `var name = expr` (mutable)
        localBind: struct {
            name: []const u8,
            value: if (phase == .untyped) *Expr else *TypedExpr,
            /// true when declared with `var`, false for `val`
            mutable: bool,
        },
        /// `name = expr` ---- assign to a previously declared `var` binding
        assign: struct {
            name: []const u8,
            value: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// `name += expr` ---- compound assignment to a var
        assignPlus: struct {
            name: []const u8,
            value: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// Assign to a field, e.g. `this._balance = value`
        fieldAssign: struct {
            receiver: if (phase == .untyped) *Expr else *TypedExpr,
            field: []const u8,
            value: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// `this._field += amount`
        fieldPlusEq: struct {
            receiver: if (phase == .untyped) *Expr else *TypedExpr,
            field: []const u8,
            value: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// Destructuring val/var binding: `val TypeName(x, y) = expr` or `val { name, age } = expr`
        localBindDestruct: struct {
            pattern: ParamDestruct,
            value: if (phase == .untyped) *Expr else *TypedExpr,
            mutable: bool,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .localBind => |lb| {
                    lb.value.deinit(allocator);
                    allocator.destroy(lb.value);
                },
                .assign => |a| {
                    a.value.deinit(allocator);
                    allocator.destroy(a.value);
                },
                .assignPlus => |a| {
                    a.value.deinit(allocator);
                    allocator.destroy(a.value);
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
                .localBindDestruct => |lb| {
                    @constCast(&lb.pattern).deinit(allocator);
                    lb.value.deinit(allocator);
                    allocator.destroy(lb.value);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

/// Function definition expressions: lambdas and anonymous functions
pub fn FunctionExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of function expression
        kind: union(enum) {
        /// A lambda expression: `{ a, b -> stmts }` or `{ stmts }` (no params).
        lambda: struct {
            /// Parameter names (inferred types). Empty for no-param lambdas.
            params: []const []const u8,
            body: []StmtOf(phase),
        },
        /// An anonymous function expression: `fn(a, b) { stmts }`
        fnExpr: struct {
            /// Parameter names.
            params: []const []const u8,
            body: []StmtOf(phase),
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .lambda => |l| {
                    allocator.free(l.params);
                    for (l.body) |*s| s.deinit(allocator);
                    allocator.free(l.body);
                },
                .fnExpr => |f| {
                    allocator.free(f.params);
                    for (f.body) |*s| s.deinit(allocator);
                    allocator.free(f.body);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

/// Call expressions: function/method invocations and pipelines
pub fn CallExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of call expression
        kind: union(enum) {
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
        /// Static method call, e.g. `Console.WriteLine(arg)`
        staticCall: struct {
            receiver: []const u8,
            method: []const u8,
            arg: if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// `@name(args...)` ---- built-in function call, e.g. `@sizeOf(T)`, `@panic("msg")`
        builtinCall: struct {
            /// The builtin name including the leading `@`, e.g. `"@sizeOf"`.
            name: []const u8,
            args: []CallArgOf(phase),
        },
        /// `expr |> fn1 |> fn2` — pipeline operator, left-associative chain
        pipeline: struct {
            lhs: if (phase == .untyped) *Expr else *TypedExpr,
            rhs: if (phase == .untyped) *Expr else *TypedExpr,
            /// Optional comment appearing before this `|>` step in the source
            comment: ?[]const u8 = null,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .call => |c| {
                    for (c.args) |*a| a.deinit(allocator);
                    allocator.free(c.args);
                    for (c.trailing) |*t| t.deinit(allocator);
                    allocator.free(c.trailing);
                },
                .staticCall => |c| {
                    c.arg.deinit(allocator);
                    allocator.destroy(c.arg);
                },
                .builtinCall => |c| {
                    for (c.args) |*a| a.deinit(allocator);
                    allocator.free(c.args);
                },
                .pipeline => |p| {
                    p.lhs.deinit(allocator);
                    allocator.destroy(p.lhs);
                    p.rhs.deinit(allocator);
                    allocator.destroy(p.rhs);
                    if (p.comment) |cm| allocator.free(cm);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

/// Collection expressions: data structures and grouping
pub fn CollectionExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of expression
        kind: union(enum) {
        /// `[e1, e2, ...]` or `[e1, ..rest]` — array literal with optional spread
        arrayLit: struct {
            elems: if (phase == .untyped) []Expr else []TypedExpr,
            /// null = no spread; "" = `..`; non-empty = `..name`
            spread: ?[]const u8 = null,
            /// Complex spread expression: `..[expr]`, `..(expr)`, etc. Set when
            /// the spread value is not a simple identifier.
            spreadExpr: ?if (phase == .untyped) *Expr else *TypedExpr = null,
            /// Comments appearing between elements (text only, without `// `)
            comments: []const []const u8 = &.{},
            /// Number of comments before each element, then before spread, then trailing.
            /// Length = elems.len + 2 (or 0 when no comments).
            commentsPerElem: []const u32 = &.{},
            /// true when source had trailing comma after last element → forces multi-line
            trailingComma: bool = false,
        },
        /// `#(e1, e2, ...)` ---- tuple literal
        tupleLit: struct {
            elems: if (phase == .untyped) []Expr else []TypedExpr,
            /// Comments appearing between elements (text only, without `// `)
            comments: []const []const u8 = &.{},
            /// Number of comments before each element, then trailing.
            /// Length = elems.len + 1 (or 0 when no comments).
            commentsPerElem: []const u32 = &.{},
        },
        /// `start..end` or `start..` ---- integer range (end=null means open)
        range: struct {
            start: if (phase == .untyped) *Expr else *TypedExpr,
            end: ?if (phase == .untyped) *Expr else *TypedExpr,
        },
        /// `case .identifier{ arm* }` or `case expr1, expr2 { arm* }`
        case: struct {
            subjects: if (phase == .untyped) []Expr else []TypedExpr,
            arms: []CaseArmOf(phase),
            /// Comments appearing after the last arm, before closing `}`
            trailingComments: []const []const u8 = &.{},
        },
        /// `{ stmt; stmt; ... }` ---- block expression
        block: struct {
            body: []StmtOf(phase),
        },
        /// `(expr)` ---- grouped expression (parentheses for precedence)
        grouped: if (phase == .untyped) *Expr else *TypedExpr,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .arrayLit => |al| {
                    for (al.elems) |*e| e.deinit(allocator);
                    allocator.free(al.elems);
                    if (al.spreadExpr) |se| {
                        se.deinit(allocator);
                        allocator.destroy(se);
                    }
                    for (al.comments) |c| allocator.free(c);
                    allocator.free(al.comments);
                    allocator.free(al.commentsPerElem);
                },
                .tupleLit => |tl| {
                    for (tl.elems) |*e| e.deinit(allocator);
                    allocator.free(tl.elems);
                    for (tl.comments) |c| allocator.free(c);
                    allocator.free(tl.comments);
                    allocator.free(tl.commentsPerElem);
                },
                .range => |r| {
                    r.start.deinit(allocator);
                    allocator.destroy(r.start);
                    if (r.end) |e| {
                        e.deinit(allocator);
                        allocator.destroy(e);
                    }
                },
                .case => |c| {
                    for (c.subjects) |*s| s.deinit(allocator);
                    allocator.free(c.subjects);
                    for (c.arms) |*a| a.deinit(allocator);
                    allocator.free(c.arms);
                    for (c.trailingComments) |tc| allocator.free(tc);
                    allocator.free(c.trailingComments);
                },
                .block => |b| {
                    for (b.body) |*s| s.deinit(allocator);
                    allocator.free(b.body);
                },
                .grouped => |e| {
                    e.deinit(allocator);
                    allocator.destroy(e);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

/// Compile-time expressions: comptime evaluation and assertions
pub fn ComptimeExprOf(comptime phase: Phase) type {
    return struct {
        /// Source location
        loc: Loc,
        /// Type annotation (only for typed expressions)
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},

        /// The kind of comptime expression
        kind: union(enum) {
        /// `comptime expr` ---- evaluate expression at compile time
        comptimeExpr: if (phase == .untyped) *Expr else *TypedExpr,
        /// `comptime { break expr; ... }` ---- comptime block
        comptimeBlock: struct { body: []StmtOf(phase) },
        /// `assert cond` or `assert cond, "message"` ---- assertion that fails if cond is false
        @"assert": struct {
            condition: if (phase == .untyped) *Expr else *TypedExpr,
            /// Optional error message displayed when assertion fails
            message: ?if (phase == .untyped) *Expr else *TypedExpr = null,
        },
        /// `assert Pattern = expr catch handler` ---- pattern assertion with error handling
        assertPattern: struct {
            /// Pattern to match against (e.g., Person(name, ..))
            pattern: Pattern,
            /// Expression being matched
            expr: if (phase == .untyped) *Expr else *TypedExpr,
            /// catch handler expression (can be throw, return, or a fallback value)
            handler: if (phase == .untyped) *Expr else *TypedExpr,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .comptimeExpr => |e| {
                    e.deinit(allocator);
                    allocator.destroy(e);
                },
                .comptimeBlock => |cb| {
                    for (cb.body) |*s| s.deinit(allocator);
                    allocator.free(cb.body);
                },
                .@"assert" => |a| {
                    a.condition.deinit(allocator);
                    allocator.destroy(a.condition);
                    if (a.message) |msg| {
                        msg.deinit(allocator);
                        allocator.destroy(msg);
                    }
                },
                .assertPattern => |ap| {
                    var patternCopy = ap.pattern;
                    patternCopy.deinit(allocator);
                    ap.expr.deinit(allocator);
                    allocator.destroy(ap.expr);
                    ap.handler.deinit(allocator);
                    allocator.destroy(ap.handler);
                },
            }
        }
    },

    pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
        this.kind.deinit(allocator);
    }
};
}

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
    /// enum variant with whole-payload binding: `Ok ok` (bind entire payload to `ok`)
    variantBinding: struct {
        name: []const u8,
        binding: []const u8,
    },
    /// enum variant with bound fields: `Rgb(r, g, b)`
    variantFields: struct {
        name: []const u8,
        bindings: []const []const u8,
    },
    /// enum variant with literal arguments: `Ok(1)`, `Error("not found")`
    variantLiterals: struct {
        name: []const u8,
        args: []Pattern,
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

    /// Multi-pattern: `1, 2, 3` (positional matching for multi-subject case)
    multi: []Pattern,

    pub fn deinit(this: *Pattern, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .variantFields => |vf| allocator.free(vf.bindings),
            .variantLiterals => |vl| {
                for (vl.args) |*p| p.deinit(allocator);
                allocator.free(vl.args);
            },
            .list => |l| allocator.free(l.elems),
            .@"or" => |pats| {
                for (pats) |*p| p.deinit(allocator);
                allocator.free(pats);
            },
            .multi => |pats| {
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

    pub fn deinit(this: *FnType, allocator: std.mem.Allocator) void {
        allocator.free(this.params);
    }
};

pub const FieldDestruct = struct {
    field_name: []const u8,
    bind_name: []const u8,
};

/// Destructuring pattern for a parameter or local binding.
/// Syntax: `{ name, age }` / `{ name, .. }` / `{ c: the_c, .. }` (record) or `#(a, b)` (tuple)
pub const ParamDestruct = union(enum) {
    /// Record destructuring: `{ name, age }` or `{ name, .. }` or `{ c: the_c, .. }`
    names: struct {
        fields: []const FieldDestruct,
        hasSpread: bool = false,
    },
    /// Tuple destructuring: `#(a, b)`
    tuple_: []const []const u8,
    /// List destructuring: `[a, b, ..rest]`
    list: Pattern,
    /// Constructor destructuring: `Ctor(a, b)` or `Variant(..rest)`
    ctor: Pattern,

    pub fn deinit(this: *ParamDestruct, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .names => |*n| {
                for (n.fields) |f| {
                    allocator.free(f.field_name);
                    // Only free bind_name if it's a different pointer than field_name
                    if (f.bind_name.ptr != f.field_name.ptr or f.bind_name.len != f.field_name.len) {
                        allocator.free(f.bind_name);
                    }
                }
                allocator.free(n.fields);
            },
            .tuple_ => |t| allocator.free(t),
            .list => |*p| p.deinit(allocator),
            .ctor => |*p| p.deinit(allocator),
        }
    }
};

/// A single parameter in a method/function signature.
/// Examples:
///   `x: Int`
///   `s comptime: string`
///   `lamb comptime: syntax fn(item: T) -> R`
///   `comptime: typeinfo T int | float`
pub const Param = struct {
    name: []const u8,
    /// Full type reference (supports arrays, optionals, error unions, etc.)
    typeRef: TypeRef,
    /// For typeinfo params: kept for backward compat, typeName from typeRef.named
    typeName: []const u8 = "",
    modifier: ParamModifier = .none,
    /// For `typeinfo` params: the union-of-types constraint, e.g. ["int","float"].
    /// Null when there is no constraint or the modifier is not Typeinfo.
    typeinfoConstraints: ?[]const []const u8 = null,
    /// For `syntax fn(...)` params: the function-type signature.
    /// Null for all other params.
    fnType: ?FnType = null,
    /// null for plain params; set for destructuring params.
    destruct: ?ParamDestruct = null,
    /// Default value expression for delegate/callback params (stored as raw text)
    defaultVal: ?[]const u8 = null,

    pub fn deinit(this: *Param, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.typeinfoConstraints) |c| allocator.free(c);
        if (this.fnType) |*ft| ft.deinit(allocator);
        if (this.destruct) |*d| d.deinit(allocator);
        if (this.defaultVal) |v| allocator.free(v);
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

    pub fn deinit(this: *InterfaceMethod, allocator: std.mem.Allocator) void {
        allocator.free(this.genericParams);
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        if (this.returnType) |*rt| rt.deinit(allocator);
        if (this.body) |stmts| {
            for (stmts) |*s| s.deinit(allocator);
            allocator.free(stmts);
        }
    }
};

/// A single-method interface type alias declared as:
///   `val log = declare fn(self: Self)` or
///   `[pub] declare fn log(this: Self)`
pub const DelegateDecl = struct {
    name: []const u8,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    params: []Param,
    returnType: ?[]const u8 = null,

    pub fn deinit(this: *DelegateDecl, allocator: std.mem.Allocator) void {
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
    }
};

/// A single annotation applied to a declaration: `#[name]` or `#[name(arg1, arg2)]`.
pub const Annotation = struct {
    name: []const u8,
    /// Raw argument lexemes (may span adjacent source tokens, e.g. `.erlang`).
    args: []const []const u8,

    pub fn deinit(this: *Annotation, allocator: std.mem.Allocator) void {
        allocator.free(this.args);
    }
};

/// `val Name = interface { ... }`  or  `val Name = interface <T> { ... }`
pub const InterfaceDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"interface_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the interface itself, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    /// Super-interfaces listed in `extends T1, T2` clause. Empty when absent.
    extends: []const []const u8 = &.{},
    fields: []InterfaceField,
    /// Whether the last field/method had a trailing comma in the source.
    trailingComma: bool = false,
    methods: []InterfaceMethod,

    pub fn deinit(this: *InterfaceDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        allocator.free(this.extends);
        allocator.free(this.fields);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
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

    pub fn deinit(this: *StructField, allocator: std.mem.Allocator) void {
        if (this.init) |*expr| expr.deinit(allocator);
    }
};

/// `get name(self: Self): ReturnType { ... }`
pub const StructGetter = struct {
    name: []const u8,
    selfParam: Param,
    returnType: []const u8,
    body: []Stmt,

    pub fn deinit(this: *StructGetter, allocator: std.mem.Allocator) void {
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

/// `set name(self: Self, value: Type) { ... }`
pub const StructSetter = struct {
    name: []const u8,
    params: []Param,
    body: []Stmt,

    pub fn deinit(this: *StructSetter, allocator: std.mem.Allocator) void {
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

/// A member inside a struct body.
pub const StructMember = union(enum) {
    field: StructField,
    getter: StructGetter,
    setter: StructSetter,
    method: InterfaceMethod, // re-use InterfaceMethod for fn members

    pub fn deinit(this: *StructMember, allocator: std.mem.Allocator) void {
        switch (this.*) {
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
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the struct, e.g. `<T, R>`.
    genericParams: []GenericParam = &.{},
    members: []StructMember,
    /// Whether the last member had a trailing comma in the source.
    trailingComma: bool = false,

    pub fn deinit(this: *StructDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.members) |*m| m.deinit(allocator);
        allocator.free(this.members);
    }
};

// ── enum decl ─────────────────────────────────────────────────────────────────

/// A named field inside an enum variant with a payload: `r: Int` or `reason: ?string`
pub const EnumVariantField = struct {
    name: []const u8,
    typeRef: TypeRef,

    pub fn deinit(this: *EnumVariantField, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
    }
};

/// One variant of an enum.
/// Simple:  `Red`
/// Payload: `Rgb(r: Int, g: Int, b: Int)`
pub const EnumVariant = struct {
    name: []const u8,
    /// Empty for simple (unit) variants; non-empty for payload variants.
    fields: []EnumVariantField,

    pub fn deinit(this: *EnumVariant, allocator: std.mem.Allocator) void {
        for (this.fields) |*f| f.deinit(allocator);
        allocator.free(this.fields);
    }
};

/// `val Color = enum { Red, Green, Rgb(r: Int, g: Int, b: Int) }` or `val Option = enum <T> { ... }`
pub const EnumDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"enum_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    genericParams: []GenericParam = &.{},
    variants: []EnumVariant,
    /// Whether the last variant had a trailing comma in the source.
    trailingComma: bool = false,
    /// Methods declared after the variant list (may include `declare fn` abstract slots).
    methods: []InterfaceMethod = &.{},

    pub fn deinit(this: *EnumDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.variants) |*v| v.deinit(allocator);
        allocator.free(this.variants);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
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
    /// Function type: `fn(T1, T2) -> R`. Owns both param types and return type.
    function: struct { params: []TypeRef, returnType: *TypeRef },

    pub fn deinit(this: *TypeRef, allocator: std.mem.Allocator) void {
        switch (this.*) {
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
            .function => |f| {
                for (f.params) |*p| p.deinit(allocator);
                allocator.free(f.params);
                f.returnType.deinit(allocator);
                allocator.destroy(f.returnType);
            },
        }
    }
};

// ── top-level program ─────────────────────────────────────────────────────────

/// Top-level constant binding: `val name = expr` or `val name: Type = expr`
pub const ValDecl = struct {
    name: []const u8,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    /// Optional explicit type annotation, e.g. `Color` in `val c: Color = .Red`
    /// or `string[]` in `val xs: string[] = [...]`.
    typeAnnotation: ?TypeRef = null,
    value: *Expr,

    pub fn deinit(this: *ValDecl, allocator: std.mem.Allocator) void {
        if (this.typeAnnotation) |*ann| ann.deinit(allocator);
        this.value.deinit(allocator);
        allocator.destroy(this.value);
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
    /// A standalone comment at the top level (not attached to any declaration).
    /// `text` is the comment content without the `//` / `///` / `////` prefix.
    /// `is_module` is true for `////` module-level comments.
    /// `is_doc` is true for `///` doc comments.
    comment: struct { text: []const u8, is_module: bool, is_doc: bool },

    pub fn deinit(this: *DeclKind, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .use => |*u| allocator.free(u.imports),
            .interface => |*t| t.deinit(allocator),
            .delegate => |*d| d.deinit(allocator),
            .@"struct" => |*s| s.deinit(allocator),
            .record => |*r| r.deinit(allocator),
            .implement => |*i| i.deinit(allocator),
            .@"enum" => |*e| e.deinit(allocator),
            .@"fn" => |*f| f.deinit(allocator),
            .val => |*v| v.deinit(allocator),
            .comment => {},
        }
    }
};

pub const Program = struct {
    decls: []DeclKind,

    pub fn deinit(this: *Program, allocator: std.mem.Allocator) void {
        for (this.decls) |*d| d.deinit(allocator);
        allocator.free(this.decls);
    }
};

// ── fn decl ───────────────────────────────────────────────────────────────────

/// `pub fn name<T>(params) ReturnType { body }`
/// `isPub` is false for module-private functions.
pub const FnDecl = struct {
    isPub: bool,
    name: []const u8,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    /// Generic type parameters, e.g. `<T, R>`. Empty slice when not generic.
    genericParams: []GenericParam,
    params: []Param,
    /// null when the return type is omitted (void-returning functions).
    returnType: ?TypeRef,
    body: []Stmt,

    pub fn deinit(this: *FnDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        if (this.returnType) |*rt| rt.deinit(allocator);
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

// ── record decl ───────────────────────────────────────────────────────────────

/// A field in a record's parameter list: `name: Type` or `name: ?Type = default`
pub const RecordField = struct {
    name: []const u8,
    typeRef: TypeRef,
    /// Optional default value, e.g. `= null` or `= 0`.
    default: ?Expr = null,

    pub fn deinit(this: *RecordField, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.default) |*d| d.deinit(allocator);
    }
};

/// `val Name = record(val f1: T1, val f2: T2) { fn ... }`
/// or `val Name = record <T>(val item: T) { fn ... }`
pub const RecordDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"record_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    /// Generic type parameters on the record, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    /// Inline fields declared in the parameter list.
    fields: []RecordField,
    /// Whether the last field had a trailing comma in the source.
    trailingComma: bool = false,
    /// Methods declared in the body (use InterfaceMethod; body is always present).
    methods: []InterfaceMethod,

    pub fn deinit(this: *RecordDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.fields) |*f| f.deinit(allocator);
        allocator.free(this.fields);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
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

    pub fn deinit(this: *ImplementMethod, allocator: std.mem.Allocator) void {
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

/// `val Name = implement interface1, interface2 for TargetType { fn ... }`
/// or `val Name<T> = implement Container<T> for MyType { fn ... }`
pub const ImplementDecl = struct {
    name: []const u8,
    /// Generic type parameters on the implement block, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    /// interfaces being implemented, e.g. ["UsbCharger", "SolarCharger"].
    interfaces: []const []const u8,
    /// The type this implement is for, e.g. "SmartCamera".
    target: []const u8,
    methods: []ImplementMethod,

    pub fn deinit(this: *ImplementDecl, allocator: std.mem.Allocator) void {
        allocator.free(this.genericParams);
        allocator.free(this.interfaces);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
    }
};

// ── Convenience type aliases ─────────────────────────────────────────────────────

/// Untyped statement
pub const Stmt = StmtOf(.untyped);
/// Typed statement
pub const TypedStmt = StmtOf(.typed);

/// Untyped call argument
pub const CallArg = CallArgOf(.untyped);
/// Typed call argument
pub const TypedCallArg = CallArgOf(.typed);

/// Untyped trailing lambda
pub const TrailingLambda = TrailingLambdaOf(.untyped);
/// Typed trailing lambda
pub const TypedTrailingLambda = TrailingLambdaOf(.typed);

/// Untyped case arm
pub const CaseArm = CaseArmOf(.untyped);
/// Typed case arm
pub const TypedCaseArm = CaseArmOf(.typed);

