const std = @import("std");

/// Compilation phase tag ---- distinguishes AST nodes before and after type inference.
pub const Phase = enum { untyped, typed };

// ── import decl ───────────────────────────────────────────────────────────────

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
pub const ImportPath = struct {
    segments: []const []const u8,
    /// Trailing `*` — activates dispatch of the symbol's methods (impl or extend).
    activate: bool = false,
    /// `as` rename of the final binding (`std.List as L`); null when absent.
    alias: ?[]const u8 = null,

    /// Final bound name: the alias when present, else the last path segment.
    pub fn name(this: ImportPath) []const u8 {
        return this.alias orelse this.segments[this.segments.len - 1];
    }
};

/// Where an `import { … }` resolves from.
pub const ImportSource = union(enum) {
    /// `import { … };` — resolves from the current project root.
    root,
    /// `import { … } from "name";` — resolves from a named dependency.
    module: []const u8,
};

pub const ImportDecl = struct {
    imports: []const ImportPath,
    source: ImportSource,
    /// Package-namespace import: `import pkg [, { … }];` binds the package name
    /// (so the package's `pub default fn` powers the `pkg "…"` DSL). Null for the
    /// plain `import { … }` form. The bound name is `package` (= the `from` target
    /// when present, else this identifier).
    package: ?[]const u8 = null,
    /// Fallback activation statement `X*;` — no real import, only activation.
    activationOnly: bool = false,
    /// `///` documentation comment (multi-line joined with `\n`)
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
};

/// A `mod Name;` / `pub mod Name;` declaration — a node in the explicit module
/// tree (Rust-style). It names a submodule of the declaring file's module and
/// records whether it is re-exported (`pub mod`) or private to the subtree
/// (`mod`). Resolution of `Name` to `Name.bp` / `Name/mod.bp` happens in the
/// CLI driver, not here; the AST only carries the declaration.
pub const ModDecl = struct {
    name: []const u8,
    isPub: bool,
    /// `pub default mod Name;` — names the package's DEFAULT module, the surface
    /// `import <pkg>` resolves to (its `pub default fn` powers the `<pkg> "…"`
    /// DSL). Declarable at any module's top level; a package has at most one.
    isDefault: bool = false,
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

/// Helper to generate expression types with standard fields (loc, type_, kind)
pub fn MakeExpr(comptime phase: Phase, comptime Kind: type) type {
    return struct {
        loc: Loc,
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},
        kind: Kind,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.kind.deinit(allocator);
        }
    };
}

/// Helper function to destroy an expression and free its memory
fn destroyExpr(allocator: std.mem.Allocator, expr: anytype) void {
    expr.deinit(allocator);
    allocator.destroy(expr);
}

/// One segment of a `stringTemplate` literal: raw text or a `${…}` hole.
pub fn StringTemplatePartOf(comptime phase: Phase) type {
    return union(enum) {
        /// Raw text between interpolations (escape sequences still unprocessed).
        text: []const u8,
        /// An interpolated `${expr}` hole.
        expr: *ExprOf(phase),
    };
}

/// Literal expressions: constant values and comments
pub fn LiteralExprOf(comptime phase: Phase) type {
    const Kind = union(enum) {
        /// A string literal value, e.g. `"hello"`
        stringLit: []const u8,
        /// A string literal containing `${…}` interpolations, e.g. `"a ${x} b"`.
        /// Parts alternate raw text and interpolated expressions in source order.
        /// Lowered to a `+` concatenation chain before codegen (see transform).
        stringTemplate: struct {
            /// true when the source literal was a `"""…"""` multiline string
            multiline: bool,
            parts: []StringTemplatePartOf(phase),
        },
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
                .stringTemplate => |t| {
                    for (t.parts) |*p| switch (p.*) {
                        .text => {},
                        .expr => |e| destroyExpr(allocator, e),
                    };
                    allocator.free(t.parts);
                },
                .comment => |c| allocator.free(c.text),
            }
        }
    };

    return MakeExpr(phase, Kind);
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
        jump: MakeExpr(phase, JumpExprOf(phase)),
        branch: MakeExpr(phase, BranchExprOf(phase)),
        loop: LoopExprOf(phase),
        binding: BindingExprOf(phase),
        useHook: UseHookExprOf(phase),
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
pub const JumpExpr = JumpExprOf(.untyped);
pub const BranchExpr = BranchExprOf(.untyped);
pub const LoopExpr = LoopExprOf(.untyped);
pub const BindingExpr = BindingExprOf(.untyped);
pub const UseHookExpr = UseHookExprOf(.untyped);
pub const FunctionExpr = FunctionExprOf(.untyped);
pub const CollectionExpr = CollectionExprOf(.untyped);
pub const ComptimeExpr = ComptimeExprOf(.untyped);

/// Helper to get the correct statement type based on phase
pub fn StmtOf(comptime phase: Phase) type {
    return struct {
        expr: ExprOf(phase),
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
        value: *ExprOf(phase),
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
        body: ExprOf(phase),
        /// Optional guard clause: `pattern if <guard> -> body`. The arm only
        /// matches when the pattern matches AND the guard evaluates to `true`.
        guard: ?ExprOf(phase) = null,
        /// Number of empty lines before this arm in the source
        emptyLinesBefore: u32 = 0,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.pattern.deinit(allocator);
            this.body.deinit(allocator);
            if (this.guard) |*g| g.deinit(allocator);
        }
    };
}

/// Identifier expressions: name-based access and references
pub fn IdentifierExprOf(comptime phase: Phase) type {
    const Kind = union(enum) {
        /// A plain identifier, e.g. `Console`
        ident: []const u8,
        /// Dot-shorthand variant: `.Red` ---- the type is inferred from context.
        dotIdent: []const u8,
        /// Identifier-based access: `this.field`, `Color.Red`, `obj.x`.
        /// `optional` marks the chaining form `obj?.x` — when the receiver is
        /// null/absent the whole access evaluates to null instead of failing.
        identAccess: struct {
            receiver: *ExprOf(phase),
            member: []const u8,
            optional: bool = false,
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
    };

    return MakeExpr(phase, Kind);
}

/// Binary operations: all binary operators.
/// Flattened: `op`/`lhs`/`rhs` live directly on the node (no `.kind` indirection).
pub fn BinOpExprOf(comptime phase: Phase) type {
    return struct {
        loc: Loc,
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},
        /// Binary operator type
        op: enum {
            lt, // `<`
            gt, // `>`
            lte, // `<=`
            gte, // `>=`
            eq, // `==`
            ne, // `!=`
            add, // `+`
            sub, // `-`
            mul, // `*`
            div, // `/`
            mod, // `%`
            @"and", // `&&`
            @"or", // `||`
        },
        lhs: *ExprOf(phase),
        rhs: *ExprOf(phase),

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            destroyExpr(allocator, this.lhs);
            destroyExpr(allocator, this.rhs);
        }
    };
}

/// Unary operations: unary operators.
/// Flattened: `op`/`expr` live directly on the node (no `.kind` indirection).
pub fn UnaryOpExprOf(comptime phase: Phase) type {
    return struct {
        loc: Loc,
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},
        /// Unary operator type
        op: enum {
            neg, // `-` negation
            not, // `not` logical not
        },
        expr: *ExprOf(phase),

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            destroyExpr(allocator, this.expr);
        }
    };
}

/// Jump expressions: simple control flow jumps (return, break, continue, throw, yield, try)
pub fn JumpExprOf(comptime phase: Phase) type {
    return union(enum) {
        /// `return expr`
        @"return": ?*ExprOf(phase),
        /// `throw expr` — throw any expression (e.g. a constructor call)
        throw_: ?*ExprOf(phase),
        /// `try expr` — propagate error union failure upward
        try_: ?*ExprOf(phase),
        /// `await expr` — suspend until the `@Future` operand resolves; result is its `T`
        await_: *ExprOf(phase),
        /// `break [expr]` ---- exit a block/loop early; expr=null means bare `break`
        @"break": ?*ExprOf(phase),
        /// `continue` ---- skip the rest of this loop iteration
        @"continue",
        /// `yield [:label] expr` ---- in a generator (`*fn`), suspend emitting `expr`;
        /// in a plain loop, accumulate `expr` into the loop's result list. The optional
        /// `:label` disambiguates which generator/loop scope the yield targets.
        yield: struct {
            label: ?[]const u8 = null,
            value: ?*ExprOf(phase),
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                inline .@"return", .throw_, .try_, .@"break" => |e| {
                    if (e) |expr| destroyExpr(allocator, expr);
                },
                .await_ => |e| destroyExpr(allocator, e),
                .yield => |y| {
                    if (y.value) |expr| destroyExpr(allocator, expr);
                },
                .@"continue" => {},
            }
        }
    };
}

/// Branch expressions: conditional and error handling constructs
pub fn BranchExprOf(comptime phase: Phase) type {
    return union(enum) {
        /// `if (cond) { [binding ->] then } [else { else_ }]`
        if_: struct {
            cond: *ExprOf(phase),
            /// Optional binding for null-check form: `if (email) { e -> ... }`
            binding: ?[]const u8,
            then_: []StmtOf(phase),
            else_: ?[]StmtOf(phase),
        },
        /// `try expr catch handler` — handle error inline
        tryCatch: struct {
            expr: *ExprOf(phase),
            handler: *ExprOf(phase),
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .if_ => |*i| {
                    destroyExpr(allocator, i.cond);
                    for (i.then_) |*s| s.deinit(allocator);
                    allocator.free(i.then_);
                    if (i.else_) |els| {
                        for (els) |*s| @constCast(s).deinit(allocator);
                        allocator.free(els);
                    }
                },
                .tryCatch => |*tc| {
                    destroyExpr(allocator, tc.expr);
                    destroyExpr(allocator, tc.handler);
                },
            }
        }
    };
}

/// Loop expressions: iteration constructs.
/// Flattened: loop fields live directly on the node (no `.kind` indirection).
pub fn LoopExprOf(comptime phase: Phase) type {
    return struct {
        loc: Loc,
        type_: if (phase == .typed) *@import("./comptime/types.zig").Type else void =
            if (phase == .typed) undefined else {},
        /// `loop (iter) { params -> body }` or `loop (iter, 0..) { item, i -> body }`
        iter: *ExprOf(phase),
        indexRange: ?*ExprOf(phase),
        params: []const []const u8,
        body: []StmtOf(phase),
        /// `loop await (iter) { ... }` ---- iterate an `@AsyncIterator`, awaiting each item.
        awaitLoop: bool = false,
        /// Optional loop label (`loop :acc (iter) { ... }`) for `yield :label` disambiguation.
        label: ?[]const u8 = null,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            destroyExpr(allocator, this.iter);
            if (this.indexRange) |ir| destroyExpr(allocator, ir);
            allocator.free(this.params);
            for (this.body) |*s| s.deinit(allocator);
            allocator.free(this.body);
        }
    };
}

/// Binding expressions: variable declarations and assignments
pub fn BindingExprOf(comptime phase: Phase) type {
    const LValue = union(enum) {
        /// Simple name: `name`
        name: []const u8,
        /// Field access: `receiver.field`
        fieldAccess: struct {
            receiver: *ExprOf(phase),
            field: []const u8,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .name => {},
                .fieldAccess => |*fa| {
                    destroyExpr(allocator, fa.receiver);
                },
            }
        }
    };

    const AssignOp = enum {
        assign, // `=`
        plusAssign, // `+=`
    };

    const Kind = union(enum) {
        /// `val name = expr` (immutable) or `var name = expr` (mutable)
        localBind: struct {
            name: []const u8,
            value: *ExprOf(phase),
            /// true when declared with `var`, false for `val`
            mutable: bool,
            /// `val name: TypeRef = expr` — the declared type; inference binds
            /// it (not the RHS type) and the formatter round-trips it.
            typeAnnotation: ?TypeRef = null,
        },
        /// Assignment to a variable or field: `name = expr`, `name += expr`, `this.field = expr`, `this.field += expr`
        assign: struct {
            target: LValue,
            op: AssignOp,
            value: *ExprOf(phase),
        },
        /// Destructuring val/var binding: `val TypeName(x, y) = expr` or `val { name, age } = expr`
        localBindDestruct: struct {
            pattern: ParamDestruct,
            value: *ExprOf(phase),
            mutable: bool,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .localBind => |*lb| {
                    destroyExpr(allocator, lb.value);
                    if (lb.typeAnnotation) |*ann| @constCast(ann).deinit(allocator);
                },
                .assign => |*a| {
                    a.target.deinit(allocator);
                    destroyExpr(allocator, a.value);
                },
                .localBindDestruct => |*lb| {
                    @constCast(&lb.pattern).deinit(allocator);
                    destroyExpr(allocator, lb.value);
                },
            }
        }
    };

    return MakeExpr(phase, Kind);
}

/// Use-hook expressions: the `use` prefix operator inside function bodies
/// (distinct from top-level `ImportDecl` imports).
///
/// `use` is a prefix operator on a hook call. Binding is handled by the
/// enclosing `val`/`var`, never by `use` itself:
///   `use effect { -> cleanup() }`       — void hook (statement position)
///   `val d = use memo { -> v*2 }`        — value bound by `val`
///   `val {v, s} = use state(0)`          — destructured by `val`
pub fn UseHookExprOf(comptime phase: Phase) type {
    const Kind = struct {
        /// The hook call the `use` prefix wraps, e.g. `state(0)` or `memo { … }`.
        inner: *ExprOf(phase),

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            destroyExpr(allocator, this.inner);
        }
    };

    return MakeExpr(phase, Kind);
}

/// Function definition expressions: lambdas and anonymous functions.
/// Both share the same shape (`params`/`body`); `syntax` records which surface
/// form produced the node so consumers can emit the right syntax.
pub fn FunctionExprOf(comptime phase: Phase) type {
    const Kind = struct {
        /// Surface syntax: `{ a, b -> stmts }` lambda vs `fn(a, b) { stmts }`.
        syntax: enum { lambda, fnExpr },
        /// Parameter names (inferred types). Empty for no-param functions.
        params: []const []const u8,
        body: []StmtOf(phase),
        /// `*fn(...) { ... }` — async/generator function expression (return impl
        /// `@Future`/`@Iterator`). Only meaningful when `syntax == .fnExpr`.
        isStarFn: bool = false,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            allocator.free(this.params);
            for (this.body) |*s| s.deinit(allocator);
            allocator.free(this.body);
        }
    };

    return MakeExpr(phase, Kind);
}

/// Call expressions: function/method invocations and pipelines
pub fn CallExprOf(comptime phase: Phase) type {
    const Kind = union(enum) {
        /// A function or method call with optional named args and trailing lambda blocks.
        ///
        /// Examples:
        ///   `calcular(fator: 2) { a, b -> ... }`   receiver=null, callee="calcular", is_builtin=false
        ///   `@sizeOf(T)`                        receiver=null, callee="sizeOf", is_builtin=true
        ///   `@block{ ... }`                     receiver=null, callee="block", is_builtin=true
        ///   `executar { ... } erro: { ... }`    receiver=null, callee="executar", is_builtin=false
        ///   `precos.forEach { ... }`             receiver=`precos`, callee="forEach", is_builtin=false
        call: struct {
            /// null for plain calls; the receiver expression for method calls.
            /// An arbitrary expression so method chains (`a().map(f).filter(g)`)
            /// and zero-arg method calls (`r.isOk()`) are representable.
            receiver: ?*ExprOf(phase),
            /// Function/method name (without @ prefix for builtins)
            callee: []const u8,
            /// true if this is a builtin call (starts with @ in source)
            is_builtin: bool,
            /// true when written with tagged-call sugar: `callee "..."` /
            /// `callee """..."""` — a single string-literal argument with no
            /// parentheses. Formatting preserves the tagged form.
            is_tagged: bool = false,
            /// true for the optional-chaining call form `recv?.method(args)` —
            /// when the receiver is null/absent the call short-circuits to null.
            optional: bool = false,
            args: []CallArgOf(phase),
            trailing: []TrailingLambdaOf(phase),
        },
        /// `expr |> fn1 |> fn2` — pipeline operator, left-associative chain
        pipeline: struct {
            lhs: *ExprOf(phase),
            rhs: *ExprOf(phase),
            /// Optional comment appearing before this `|>` step in the source
            comment: ?[]const u8 = null,
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                .call => |c| {
                    if (c.receiver) |recv| {
                        recv.deinit(allocator);
                        allocator.destroy(recv);
                    }
                    for (c.args) |*a| a.deinit(allocator);
                    allocator.free(c.args);
                    for (c.trailing) |*t| t.deinit(allocator);
                    allocator.free(c.trailing);
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
    };

    return MakeExpr(phase, Kind);
}

/// One `name: value` field of an anonymous `record { … }` literal.
pub fn RecordLitFieldOf(comptime phase: Phase) type {
    return struct {
        name: []const u8,
        value: *ExprOf(phase),
    };
}

/// Collection expressions: data structures and grouping
pub fn CollectionExprOf(comptime phase: Phase) type {
    const Kind = union(enum) {
        /// `[e1, e2, ...]` or `[e1, ..rest]` — array literal with optional spread
        arrayLit: struct {
            elems: []ExprOf(phase),
            /// null = no spread; "" = `..`; non-empty = `..name`
            spread: ?[]const u8 = null,
            /// Complex spread expression: `..[expr]`, `..(expr)`, etc. Set when
            /// the spread value is not a simple identifier.
            spreadExpr: ?*ExprOf(phase) = null,
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
            elems: []ExprOf(phase),
            /// Comments appearing between elements (text only, without `// `)
            comments: []const []const u8 = &.{},
            /// Number of comments before each element, then trailing.
            /// Length = elems.len + 1 (or 0 when no comments).
            commentsPerElem: []const u32 = &.{},
        },
        /// `start..end` or `start..` ---- integer range (end=null means open)
        range: struct {
            start: *ExprOf(phase),
            end: ?*ExprOf(phase),
        },
        /// `case .identifier{ arm* }` or `case expr1, expr2 { arm* }`
        case: struct {
            subjects: []ExprOf(phase),
            arms: []CaseArmOf(phase),
            /// Comments appearing after the last arm, before closing `}`
            trailingComments: []const []const u8 = &.{},
        },
        /// `(expr)` ---- grouped expression (parentheses for precedence)
        grouped: *ExprOf(phase),
        /// `record { name: value, … }` ---- anonymous structural record literal.
        /// Types as an anonymous record (`Type.record`); nests freely.
        recordLit: struct {
            fields: []RecordLitFieldOf(phase),
        },

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
                .grouped => |e| {
                    e.deinit(allocator);
                    allocator.destroy(e);
                },
                .recordLit => |rl| {
                    for (rl.fields) |f| {
                        f.value.deinit(allocator);
                        allocator.destroy(f.value);
                    }
                    allocator.free(rl.fields);
                },
            }
        }
    };

    return MakeExpr(phase, Kind);
}

/// Compile-time expressions: comptime evaluation and assertions
pub fn ComptimeExprOf(comptime phase: Phase) type {
    const Kind = union(enum) {
        /// `comptime expr` ---- evaluate expression at compile time
        comptimeExpr: *ExprOf(phase),
        /// `comptime { break expr; ... }` ---- comptime block
        comptimeBlock: struct { body: []StmtOf(phase) },
        /// `assert cond` or `assert cond, "message"` ---- assertion that fails if cond is false
        assert: struct {
            condition: *ExprOf(phase),
            /// Optional error message displayed when assertion fails
            message: ?*ExprOf(phase) = null,
        },
        /// `assert Pattern = expr catch handler` ---- pattern assertion with error handling
        assertPattern: struct {
            /// Pattern to match against (e.g., Person(name, ..))
            pattern: Pattern,
            /// Expression being matched
            expr: *ExprOf(phase),
            /// catch handler expression (can be throw, return, or a fallback value)
            handler: *ExprOf(phase),
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
                .assert => |a| {
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
    };

    return MakeExpr(phase, Kind);
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
    /// enum variant with a payload: `Ok ok`, `Rgb(r, g, b)`, `Ok(1)`.
    /// The `name` is the variant; `payload` records how its contents are matched.
    variant: struct {
        name: []const u8,
        payload: union(enum) {
            /// whole-payload binding: `Ok ok` (bind entire payload to `ok`)
            binding: []const u8,
            /// bound fields: `Rgb(r, g, b)`
            fields: []const []const u8,
            /// literal / nested-pattern arguments: `Ok(1)`, `Error("not found")`
            literals: []Pattern,
        },
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
            .variant => |*v| switch (v.payload) {
                .fields => |f| allocator.free(f),
                .literals => |args| {
                    for (args) |*p| p.deinit(allocator);
                    allocator.free(args);
                },
                .binding => {},
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
///   `comptime T: typeparam`
pub const Param = struct {
    name: []const u8,
    /// Full type reference (supports arrays, optionals, etc.)
    typeRef: TypeRef,
    typeName: []const u8 = "",
    modifier: ParamModifier = .none,
    /// For `syntax fn(...)` params: the function-type signature.
    /// Null for all other params.
    fnType: ?FnType = null,
    /// null for plain params; set for destructuring params.
    destruct: ?ParamDestruct = null,
    /// Default value expression for delegate/callback params (stored as raw text)
    defaultVal: ?[]const u8 = null,

    pub fn deinit(this: *Param, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
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
    /// `@[external(target, "module", "symbol")]` annotations on a `declare fn`
    /// member — host-backed interface methods (per-target lowering).
    annotations: []Annotation = &.{},
    /// Generic type parameters, e.g. `<T, R>`. Empty slice when not generic.
    genericParams: []GenericParam = &.{},
    params: []Param,
    /// Return type annotation. null for void methods.
    returnType: ?TypeRef = null,
    body: ?[]Stmt,
    /// true when declared with `default fn` in an interface body
    is_default: bool = false,
    /// true when declared with `declare fn` inside a struct/record/enum body
    /// or an interface body (bodyless, typed from the signature)
    is_declare: bool = false,
    isPub: bool = false,

    /// True when the method is a host-backed `#[@external(…)]` declaration.
    pub fn isExternal(this: InterfaceMethod) bool {
        for (this.annotations) |a| {
            if (std.mem.eql(u8, a.name, "external")) return true;
        }
        return false;
    }

    /// The `(module, symbol)` of the `external` annotation targeting `target`
    /// (e.g. "node", "erlang"), or null when none matches.
    pub fn externalFor(this: InterfaceMethod, target: []const u8) ?ExternalRef {
        return externalRefFor(this.annotations, target);
    }

    pub fn deinit(this: *InterfaceMethod, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        if (this.annotations.len > 0) allocator.free(this.annotations);
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

/// A single annotation applied to a declaration: `#[name]` or `#[name(arg1, arg2)]`,
/// or one builtin call of an `@[call, call]` annotation block.
pub const Annotation = struct {
    name: []const u8,
    /// Raw argument lexemes (may span adjacent source tokens, e.g. `.erlang`).
    args: []const []const u8,
    /// True when the annotation was written with a `@` prefix inside `#[…]`
    /// — i.e. `#[@external(…)]`. False for user-defined attributes `#[custom()]`.
    is_builtin: bool = false,

    pub fn deinit(this: *Annotation, allocator: std.mem.Allocator) void {
        allocator.free(this.args);
    }
};

/// The host `(module, symbol)` pair of one `external(target, module, symbol)`
/// annotation, with the string-literal quotes stripped.
pub const ExternalRef = struct {
    module: []const u8,
    symbol: []const u8,
};

/// A parsed `@external` call template: the host `symbol` (with the call
/// punctuation stripped) plus the ordered argument names that pin the host's
/// argument layout — including `self`'s position. `args == null` means the
/// caller should use the botopink fn's declaration order (bare symbol).
pub const ExternalCall = struct {
    symbol: []const u8,
    args: ?[]const []const u8,
};

/// Splits an `@external` symbol slot into its host symbol and an optional
/// ordered arg-name list. `"sym(a, self)"` → `("sym", ["a", "self"])`;
/// `"sym"` → `("sym", null)`. The arg list is empty for `"sym()"`.
/// `slots_out` must have capacity for at least one slot per `,` plus one — the
/// caller (`InterfaceMethod.callTemplateFor`/`FnDecl.callTemplateFor`) reuses a
/// stack-allocated buffer so we never allocate just to read an annotation.
pub fn parseExternalCallTemplate(
    symbol: []const u8,
    slots_out: [][]const u8,
) ExternalCall {
    const lp = std.mem.indexOfScalar(u8, symbol, '(') orelse
        return .{ .symbol = symbol, .args = null };
    const rp = std.mem.lastIndexOfScalar(u8, symbol, ')') orelse
        return .{ .symbol = symbol, .args = null };
    if (rp <= lp) return .{ .symbol = symbol, .args = null };

    const head = std.mem.trim(u8, symbol[0..lp], " \t");
    const inside = std.mem.trim(u8, symbol[lp + 1 .. rp], " \t");
    if (inside.len == 0) return .{ .symbol = head, .args = slots_out[0..0] };

    var n: usize = 0;
    var it = std.mem.tokenizeScalar(u8, inside, ',');
    while (it.next()) |tok| {
        if (n >= slots_out.len) break;
        slots_out[n] = std.mem.trim(u8, tok, " \t");
        n += 1;
    }
    return .{ .symbol = head, .args = slots_out[0..n] };
}

/// Strips the surrounding quotes off a string-literal annotation argument.
fn unquoteAnnotationArg(arg: []const u8) []const u8 {
    if (arg.len >= 2 and arg[0] == '"' and arg[arg.len - 1] == '"')
        return arg[1 .. arg.len - 1];
    return arg;
}

/// Canonicalises an `@external` target argument to its bare target name.
/// Accepts every spelling of the `Target` enum value: bare (`erlang`), the
/// dot-variant shorthand (`.Erlang`) and the qualified form (`Target.Erlang`).
/// The remainder is compared case-insensitively by `externalTargetMatches`.
pub fn normalizeExternalTarget(arg: []const u8) []const u8 {
    var t = std.mem.trimStart(u8, arg, ".");
    if (std.mem.indexOfScalar(u8, t, '.')) |dot| {
        if (std.ascii.eqlIgnoreCase(t[0..dot], "Target")) t = t[dot + 1 ..];
    }
    return t;
}

/// True when an `@external` target argument names `target` (a lowercase
/// canonical name like "node"/"erlang"), in any of the accepted spellings.
pub fn externalTargetMatches(arg: []const u8, target: []const u8) bool {
    return std.ascii.eqlIgnoreCase(normalizeExternalTarget(arg), target);
}

/// Resolves an `@external` annotation's `(module, symbol)` for `target`, honouring
/// both arities: 3 args `[target, module, symbol]`, or 2 args `[target, symbol]`
/// with the module omitted (node ⇒ native JS prototype; `module` comes back "").
/// `symbol` may carry a call template `"sym(arg, self)"` — callers detect the `(`.
fn externalRefFor(annotations: []const Annotation, target: []const u8) ?ExternalRef {
    for (annotations) |a| {
        if (!std.mem.eql(u8, a.name, "external")) continue;
        if (a.args.len < 2 or a.args.len > 3) continue;
        if (!externalTargetMatches(a.args[0], target)) continue;
        return if (a.args.len == 3)
            .{ .module = unquoteAnnotationArg(a.args[1]), .symbol = unquoteAnnotationArg(a.args[2]) }
        else
            .{ .module = "", .symbol = unquoteAnnotationArg(a.args[1]) };
    }
    return null;
}

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
    /// Full type reference — supports arrays (`E[]`), optionals (`?T`),
    /// generics, etc., exactly like `RecordField.typeRef`.
    typeRef: TypeRef,
    /// Optional initializer expression.
    init: ?Expr,
    /// Member-level decorators on the field (`#[inject] val repo: …`).
    annotations: []Annotation = &.{},

    pub fn deinit(this: *StructField, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.init) |*expr| expr.deinit(allocator);
        for (this.annotations) |*ann| ann.deinit(allocator);
        if (this.annotations.len > 0) allocator.free(this.annotations);
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
/// `val Name = struct implement @Context<B, R> { ... }`
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
    /// Inline interface implementations: `struct implement I1, I2 { }`.
    implement: []TypeRef = &.{},
    members: []StructMember,
    /// Whether the last member had a trailing comma in the source.
    trailingComma: bool = false,

    pub fn deinit(this: *StructDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.implement) |*im| im.deinit(allocator);
        allocator.free(this.implement);
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
    /// Inline interface implementations: `enum implement I1 { }`.
    implement: []TypeRef = &.{},
    variants: []EnumVariant,
    /// Whether the last variant had a trailing comma in the source.
    trailingComma: bool = false,
    /// Methods declared after the variant list (may include `declare fn` abstract slots).
    methods: []InterfaceMethod = &.{},

    pub fn deinit(this: *EnumDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        allocator.free(this.genericParams);
        for (this.implement) |*im| im.deinit(allocator);
        allocator.free(this.implement);
        for (this.variants) |*v| v.deinit(allocator);
        allocator.free(this.variants);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
    }
};

// ── type reference ────────────────────────────────────────────────────────────

/// One field of an anonymous record TYPE: `name: Type` in `{ value: T, set: fn(T) }`.
pub const RecordTypeField = struct {
    name: []const u8,
    typeRef: TypeRef,
};

/// A type annotation expression, e.g. `Int`, `string[]`, `#(Int, string)`, `?T`.
pub const TypeRef = union(enum) {
    /// Plain named type: `Int`, `string`, `Self`. Slice into source — not heap-owned.
    named: []const u8,
    /// Array type: `T[]`. Owns the element type.
    array: *TypeRef,
    /// Tuple type: `#(T1, T2, ...)`. Owns the element types.
    tuple_: []TypeRef,
    /// Optional type: `?T`. Owns the inner type.
    optional: *TypeRef,
    /// Function type: `fn(T1, T2) -> R`. Owns both param types and return type.
    function: struct { params: []TypeRef, returnType: *TypeRef },
    /// Generic type: `@Result<D, E>` (builtin) or `MyType<T>` (user-defined). Owns the argument types.
    generic: struct { name: []const u8, args: []TypeRef, is_builtin: bool },
    /// Comptime type parameter: `typeparam` or `typeparam string | int | bool`.
    /// `constraints` is the `|`-separated list of accepted types; an empty slice
    /// means the typeparam is unconstrained and accepts any type. Owns the constraints.
    /// Surface syntax (post-F0): `type` / `type string | int | bool`.
    typeparam: []TypeRef,
    /// Anonymous structural record type: `{ value: T, set: fn(T) }`, usable as a
    /// return type or annotation without a named `record`. Owns the fields.
    record_type: []RecordTypeField,

    pub fn deinit(this: *TypeRef, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .named => {},
            .record_type => |flds| {
                for (flds) |*f| f.typeRef.deinit(allocator);
                allocator.free(flds);
            },
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
            .function => |f| {
                for (f.params) |*p| p.deinit(allocator);
                allocator.free(f.params);
                f.returnType.deinit(allocator);
                allocator.destroy(f.returnType);
            },
            .generic => |b| {
                for (b.args) |*a| a.deinit(allocator);
                allocator.free(b.args);
            },
            .typeparam => |constraints| {
                for (constraints) |*c| c.deinit(allocator);
                allocator.free(constraints);
            },
        }
    }

    /// True when this annotation is the builtin expression type — `@Expr<T>`
    /// or bare `@Expr` (expr-templates). Parameters of this type are captured
    /// unevaluated; functions returning it are comptime-expanded templates.
    pub fn isExprType(this: TypeRef) bool {
        return this == .generic and this.generic.is_builtin and
            std.mem.eql(u8, this.generic.name, "Expr");
    }

    /// True when this annotation is the builtin custom-carrier type
    /// `@ExprCustom<T>` (expr-custom). A function returning it is a template fn
    /// whose body returns `q.custom(tree, code)`: `code` travels the ordinary
    /// `@Expr<T>` expansion path while `tree` is a reference `CustomNode` stored
    /// by call-location for tooling. The carrier is generic on purpose — the
    /// core never learns any sub-language; `kind`/`label` are opaque lib tags.
    pub fn isExprCustomType(this: TypeRef) bool {
        return this == .generic and this.generic.is_builtin and
            std.mem.eql(u8, this.generic.name, "ExprCustom");
    }

    /// True when this return type marks a comptime-expanded template function —
    /// either a plain `@Expr<T>` or the custom carrier `@ExprCustom<T>`. Both are
    /// expanded at their call sites and never reach codegen.
    pub fn isTemplateReturnType(this: TypeRef) bool {
        return this.isExprType() or this.isExprCustomType();
    }

    /// True when this is the builtin reflection type `@Decl` (annotation
    /// processors). A function whose first parameter is `comptime _: @Decl` is a
    /// decorator: the core invokes it over the declaration the annotation sits on.
    /// Bare `@Decl` parses as a builtin generic with no args (like bare `@Expr`).
    pub fn isDeclType(this: TypeRef) bool {
        return this == .generic and this.generic.is_builtin and
            std.mem.eql(u8, this.generic.name, "Decl");
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

/// Top-level test declaration: `test { body }` or `test "name" { body }`.
/// Collected and run by `botopink test`; excluded from normal build output.
pub const TestDecl = struct {
    /// null for the anonymous form `test { … }`.
    name: ?[]const u8 = null,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    loc: Loc = .{ .line = 0, .col = 0 },
    body: []Stmt,

    pub fn deinit(this: *TestDecl, allocator: std.mem.Allocator) void {
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

pub const DeclKind = union(enum) {
    record: RecordDecl,
    implement: ImplementDecl,
    extend: ExtendDecl,
    use: ImportDecl,
    mod: ModDecl,
    interface: InterfaceDecl,
    delegate: DelegateDecl,
    @"struct": StructDecl,
    @"enum": EnumDecl,
    @"fn": FnDecl,
    val: ValDecl,
    @"test": TestDecl,
    /// A standalone comment at the top level (not attached to any declaration).
    /// `text` is the comment content without the `//` / `///` / `////` prefix.
    /// `is_module` is true for `////` module-level comments.
    /// `is_doc` is true for `///` doc comments.
    comment: struct { text: []const u8, is_module: bool, is_doc: bool },

    pub fn deinit(this: *DeclKind, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .use => |*u| {
                for (u.imports) |imp| allocator.free(imp.segments);
                allocator.free(u.imports);
            },
            .interface => |*t| t.deinit(allocator),
            .delegate => |*d| d.deinit(allocator),
            .@"struct" => |*s| s.deinit(allocator),
            .record => |*r| r.deinit(allocator),
            .implement => |*i| i.deinit(allocator),
            .extend => |*x| x.deinit(allocator),
            .@"enum" => |*e| e.deinit(allocator),
            .@"fn" => |*f| f.deinit(allocator),
            .val => |*v| v.deinit(allocator),
            .@"test" => |*t| t.deinit(allocator),
            .mod => {},
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
/// The effect a function implements, named by a `#[@<effect>]` annotation (the
/// marker that replaces the deprecated `*fn` prefix). The matching `@Effect<…>`
/// return wrapper carries the effect's type parameters; this enum is the source
/// of truth for how the function lowers and which body operations (`await` /
/// `yield` / `throw`) it permits.
pub const EffectKind = enum {
    result,
    future,
    generator,
    iterator,
    asyncGenerator,
    context,

    /// The annotation spelling — `#[@<name>]` — for this effect.
    pub fn annotationName(self: EffectKind) []const u8 {
        return switch (self) {
            .result => "result",
            .future => "future",
            .generator => "generator",
            .iterator => "iterator",
            .asyncGenerator => "asyncGenerator",
            .context => "context",
        };
    }

    /// The builtin return-type wrapper this effect requires (`@Future`, …).
    pub fn returnWrapper(self: EffectKind) []const u8 {
        return switch (self) {
            .result => "Result",
            .future => "Future",
            .generator => "Generator",
            .iterator => "Iterator",
            .asyncGenerator => "AsyncIterator",
            .context => "Context",
        };
    }

    /// Map a builtin annotation name (`future`, …) to its effect, or null when
    /// the name is not one of the builtin effect markers.
    pub fn fromAnnotationName(name: []const u8) ?EffectKind {
        const all = [_]EffectKind{ .result, .future, .generator, .iterator, .asyncGenerator, .context };
        for (all) |kind| {
            if (std.mem.eql(u8, kind.annotationName(), name)) return kind;
        }
        return null;
    }

    /// Derive the effect of a (deprecated) `*fn` from its return wrapper / body.
    /// Mirrors the legacy return-type discrimination so codegen stays
    /// byte-identical when the `*` prefix is used instead of the annotation.
    pub fn fromStarReturn(returnType: ?TypeRef, body: []const Stmt) EffectKind {
        if (returnType) |rt| {
            if (rt == .generic and rt.generic.is_builtin) {
                const n = rt.generic.name;
                if (std.mem.eql(u8, n, "Future")) return .future;
                if (std.mem.eql(u8, n, "Iterator")) return .iterator;
                if (std.mem.eql(u8, n, "AsyncIterator")) return .asyncGenerator;
                if (std.mem.eql(u8, n, "Result")) return .result;
                if (std.mem.eql(u8, n, "Generator")) return .generator;
                if (std.mem.eql(u8, n, "Context")) return .context;
            }
        }
        // A bare `*fn` with no recognized wrapper: a yielding body is a
        // generator, else an async function (the legacy commonJS fallback).
        for (body) |stmt| {
            if (stmt.expr == .jump and stmt.expr.jump.kind == .yield) return .generator;
        }
        return .future;
    }
};

pub const FnDecl = struct {
    isPub: bool,
    /// The function's effect, or null for a plain function. Set from a
    /// `#[@<effect>]` annotation (the canonical marker) or derived from the
    /// deprecated `*fn` prefix. The return wrapper carries the type params.
    effect: ?EffectKind = null,
    /// `declare fn` ---- a bodyless declaration typed from the signature alone.
    /// Required for `@[external(…)]` FFI fns (the only valid annotated form).
    isDeclare: bool = false,
    /// `pub default fn` — a package's DEFAULT handler, invoked by the
    /// `<package> "…"` DSL form (`q "select …"`). Declarable at any module's top
    /// level (not just `root.bp`).
    isDefault: bool = false,
    /// Optional generator label declared after the return type (`*fn f() -> @Iterator<T> :gen`),
    /// used to disambiguate `yield :label` from an enclosing loop's accumulator.
    label: ?[]const u8 = null,
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

    /// The effect named by a `#[@<effect>]` annotation on this fn, if any.
    /// Distinct from `effect`, which may also be set by the deprecated `*fn`.
    pub fn effectAnnotation(this: FnDecl) ?EffectKind {
        for (this.annotations) |a| {
            if (a.is_builtin) {
                if (EffectKind.fromAnnotationName(a.name)) |k| return k;
            }
        }
        return null;
    }

    /// True when the fn is an `@[external(…)]` FFI declaration (bodyless;
    /// each codegen backend lowers calls to its target's symbol).
    pub fn isExternal(this: FnDecl) bool {
        for (this.annotations) |a| {
            if (std.mem.eql(u8, a.name, "external")) return true;
        }
        return false;
    }

    /// True when the declared return type is the builtin `@Result<_, _>`.
    /// A `*fn -> @Result<…>` is the checked-Result effect form (it emits as a
    /// plain function in every backend, never as an async/generator).
    pub fn returnsResult(this: FnDecl) bool {
        if (this.returnType) |rt| {
            return rt == .generic and rt.generic.is_builtin and
                std.mem.eql(u8, rt.generic.name, "Result");
        }
        return false;
    }

    /// The `(module, symbol)` of the `external` annotation matching `target`
    /// (e.g. "erlang", "node"), or null when no annotation targets it.
    pub fn externalFor(this: FnDecl, target: []const u8) ?ExternalRef {
        return externalRefFor(this.annotations, target);
    }

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
    /// Member-level decorators on the field (`#[inject] repo: …`).
    annotations: []Annotation = &.{},

    pub fn deinit(this: *RecordField, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.default) |*d| d.deinit(allocator);
        for (this.annotations) |*ann| ann.deinit(allocator);
        if (this.annotations.len > 0) allocator.free(this.annotations);
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
    /// Inline interface implementations: `record(...) implement I1 { }`.
    implement: []TypeRef = &.{},
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
        for (this.implement) |*im| im.deinit(allocator);
        allocator.free(this.implement);
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

/// Named trait implementation. Two surface forms, both always named:
///   shorthand: `pub? Name implement interface1, interface2 for TargetType { fn ... }`
///   explicit:  `pub? val Name = implement interface1, interface2 for TargetType { fn ... }`
pub const ImplementDecl = struct {
    name: []const u8,
    isPub: bool = false,
    /// true when written in shorthand form (`Name implement …`), false for the
    /// explicit `val Name = implement …` form. Used by the formatter to round-trip.
    shorthand: bool = false,
    /// Generic type parameters on the implement block, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    /// interfaces being implemented, e.g. `[Drawable, @Context<E, E>]`.
    /// Each is a full `TypeRef` so generic interfaces (`Iface<A, B>`, `@Context<…>`)
    /// are supported, not just bare identifiers.
    interfaces: []TypeRef,
    /// The type this implement is for, e.g. "SmartCamera".
    target: []const u8,
    methods: []ImplementMethod,

    pub fn deinit(this: *ImplementDecl, allocator: std.mem.Allocator) void {
        allocator.free(this.genericParams);
        for (this.interfaces) |*iface| iface.deinit(allocator);
        allocator.free(this.interfaces);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
    }
};

/// Named extension without a trait. Two surface forms, both always named:
///   shorthand: `pub? Name extend TargetType { fn ... }`
///   explicit:  `pub? val Name = extend TargetType { fn ... }`
/// Reuses `ImplementMethod` for its method bodies (extensions are never qualified,
/// so `qualifier` is always null).
pub const ExtendDecl = struct {
    name: []const u8,
    isPub: bool = false,
    /// true when written in shorthand form (`Name extend …`), false for the
    /// explicit `val Name = extend …` form. Used by the formatter to round-trip.
    shorthand: bool = false,
    /// Generic type parameters on the extend block, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    /// The type this extension adds methods to, e.g. "Pato".
    target: []const u8,
    methods: []ImplementMethod,

    pub fn deinit(this: *ExtendDecl, allocator: std.mem.Allocator) void {
        allocator.free(this.genericParams);
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
