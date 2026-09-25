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
/// One leaf of an import list (decision 107). The dotted spelling
/// (`io.fs.readText as read`) and the grouped spelling
/// (`io: {fs: {readText as read}}`) both flatten to this — the parser writes
/// the group's prefix into `segments`, so nothing downstream knows which one
/// was written. Only the leaf enters scope: `segments[0..len-1]` is the path
/// of the module the leaf lives in (or, when the whole path names a module,
/// the leaf is that module as a namespace).
pub const ImportPath = struct {
    segments: []const []const u8,
    /// Trailing `*` — activates dispatch of the symbol's methods (impl or extend).
    activate: bool = false,
    /// `as` rename of the final binding (`std.List as L`); null when absent.
    alias: ?[]const u8 = null,
    /// Where the item is written — its first own token (`json` in `json.parse`,
    /// `parse` in `json: {parse}`), so a refusal such as `import-name-collision`
    /// points at the item it is about. `line == 0` when synthesised.
    loc: Loc = .{ .line = 0, .col = 0 },

    /// Final bound name: the alias when present, else the last path segment.
    pub fn name(this: ImportPath) []const u8 {
        return this.alias orelse this.segments[this.segments.len - 1];
    }

    /// The AST snapshots serialise every field; `loc` is diagnostic
    /// provenance, not shape, so it stays out of them — a snapshot recorded
    /// before the field existed reads the same after it.
    pub fn jsonStringify(this: ImportPath, jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("segments");
        try jws.write(this.segments);
        try jws.objectField("activate");
        try jws.write(this.activate);
        try jws.objectField("alias");
        try jws.write(this.alias);
        try jws.endObject();
    }

    /// The last segment — the exported name the leaf refers to, whatever the
    /// local binding (`alias`) is called.
    pub fn leaf(this: ImportPath) []const u8 {
        return this.segments[this.segments.len - 1];
    }

    /// True when the item carries a path (`a.b`, or a group leaf), so the leaf
    /// is looked up in the module the prefix names rather than in the source
    /// module itself.
    pub fn isQualified(this: ImportPath) bool {
        return this.segments.len > 1;
    }

    /// The segments before the leaf joined with `/` — the module path the
    /// leaf is resolved in, relative to the import's source package. Empty for
    /// a single-segment item.
    pub fn prefixPath(this: ImportPath, alloc: std.mem.Allocator) ![]const u8 {
        return joinSegments(alloc, this.segments[0 .. this.segments.len - 1]);
    }

    /// Every segment joined with `/` — the module path the whole item names
    /// when the leaf is itself a module (`io.fs` → `io/fs`).
    pub fn fullPath(this: ImportPath, alloc: std.mem.Allocator) ![]const u8 {
        return joinSegments(alloc, this.segments);
    }

    /// The item as written, segments joined with `.` — for a diagnostic.
    pub fn dotted(this: ImportPath, alloc: std.mem.Allocator) ![]const u8 {
        const out = try joinSegments(alloc, this.segments);
        for (@constCast(out)) |*c| {
            if (c.* == '/') c.* = '.';
        }
        return out;
    }

    /// True when two items name the same thing: same path, same activation.
    /// A repeated identical import (an `@emit` contribution re-importing what
    /// its module already imports) is not a collision.
    pub fn samePath(this: ImportPath, other: ImportPath) bool {
        if (this.segments.len != other.segments.len) return false;
        for (this.segments, other.segments) |a, b| {
            if (!std.mem.eql(u8, a, b)) return false;
        }
        return this.activate == other.activate;
    }
};

fn joinSegments(alloc: std.mem.Allocator, segs: []const []const u8) ![]const u8 {
    var total: usize = 0;
    for (segs, 0..) |s, i| total += s.len + @as(usize, if (i > 0) 1 else 0);
    const out = try alloc.alloc(u8, total);
    var at: usize = 0;
    for (segs, 0..) |s, i| {
        if (i > 0) {
            out[at] = '/';
            at += 1;
        }
        @memcpy(out[at .. at + s.len], s);
        at += s.len;
    }
    return out;
}

/// Where an `import { … }` resolves from.
pub const ImportSource = union(enum) {
    /// `import { … };` — resolves from the current project root.
    root,
    /// `import { … } from "name";` — resolves from a named dependency.
    module: []const u8,

    /// Whether `path` is the module this source NAMES. The question every
    /// name-keyed import index used to skip: a symbol name is unique only
    /// inside one module, so "which `parse`" is answered by the `from` and not
    /// by whichever module a hash iteration reached first (`libs/std` declares
    /// `parse` in `json`, `querystring` and `url` today).
    ///
    /// Two spellings name a module: its full path (`web/http`) and the last
    /// segment of it (`http`). A PACKAGE handle (`std`, a lib's name) names the
    /// package, so it matches only a module whose basename IS the handle — the
    /// single-module lib shape — and a caller that gets no match must widen to
    /// the whole package rather than treat the name as absent. `.root` names no
    /// module in particular (it is "this project"), so it never narrows.
    pub fn namesModule(this: ImportSource, path: []const u8) bool {
        const m = switch (this) {
            .root => return false,
            .module => |name| name,
        };
        if (std.mem.eql(u8, m, path)) return true;
        const base = if (std.mem.lastIndexOfScalar(u8, path, '/')) |i| path[i + 1 ..] else path;
        return std.mem.eql(u8, m, base);
    }
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

    /// The module a qualified item's leaf lives in, as the source a lookup
    /// narrows by (`ImportSource.namesModule`): `import {io.fs.readText} from
    /// "std"` answers `std/io/fs`, `import {html.div} from "web"` answers
    /// `web/html`, and the bare `import {shapes.circle.name};` answers
    /// `shapes/circle` — the package's own module tree. A single-segment item
    /// answers the decl's own source, and so does `from "std"` on a single
    /// segment (the std namespace form). With `whole`, every segment is the
    /// path: the item names a module (`io.fs` → `std/io/fs`) rather than a
    /// symbol of one.
    pub fn leafSource(this: ImportDecl, imp: ImportPath, alloc: std.mem.Allocator, whole: bool) !ImportSource {
        if (!whole and !imp.isQualified()) return this.source;
        const rel = if (whole) try imp.fullPath(alloc) else try imp.prefixPath(alloc);
        return switch (this.source) {
            .root => .{ .module = rel },
            .module => |pkg| .{ .module = try std.fmt.allocPrint(alloc, "{s}/{s}", .{ pkg, rel }) },
        };
    }
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
            /// Written at the end of the previous statement's line
            /// (`f(); // note`); the formatter keeps it there.
            trailing: bool = false,

            pub fn jsonStringify(this: @This(), jws: anytype) !void {
                try jws.beginObject();
                try jws.objectField("kind");
                try jws.write(this.kind);
                try jws.objectField("text");
                try jws.write(this.text);
                if (this.trailing) {
                    try jws.objectField("trailing");
                    try jws.write(true);
                }
                try jws.endObject();
            }
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
        /// True when `value` is a *reference* into a fn-decl's `Param.default`
        /// (injected at call-site default-value expansion in
        /// `comptime/transform.zig`). `deinit` skips the value teardown since
        /// the source decl owns it.
        is_default_inj: bool = false,

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            if (!this.is_default_inj) {
                this.value.deinit(allocator);
                allocator.destroy(this.value);
            }
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
        /// Where the arm's pattern starts. `Pattern` carries no location of its
        /// own, so a diagnostic about the pattern — decision 54's "an optional
        /// is matched by `null`", for one — has nowhere else to point. Left out
        /// of the dump: a location is a diagnostic aid, not surface, and the AST
        /// dumps are snapshot-compared.
        patternLoc: Loc = .{ .line = 0, .col = 0 },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            this.pattern.deinit(allocator);
            this.body.deinit(allocator);
            if (this.guard) |*g| g.deinit(allocator);
        }

        pub fn jsonStringify(this: @This(), jws: anytype) !void {
            return stringifyOmitting(this, jws, &.{"patternLoc"}, &.{});
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
        /// `break [:label] [expr]` ---- exit a block/loop/iterator early.
        /// `value=null` is bare `break`; the optional `:label` targets a named
        /// outer loop or `#[@resultGenerator]` / `#[@futureGenerator]` fn scope (§1I
        /// REGRAS DE ESCOPO: an unlabelled `break` inside a nested loop binds
        /// to the loop, not the iterator).
        @"break": struct {
            label: ?[]const u8 = null,
            value: ?*ExprOf(phase),
        },
        /// `continue` ---- skip the rest of this loop iteration
        @"continue",
        /// `yield [:label] expr` ---- in a generator (`#[@resultGenerator]` /
        /// `#[@generator]` / `#[@futureGenerator]` fn), suspend emitting `expr`;
        /// in a plain loop, accumulate `expr` into the loop's result list. The
        /// optional `:label` disambiguates which generator/loop scope the yield
        /// targets.
        yield: struct {
            label: ?[]const u8 = null,
            value: ?*ExprOf(phase),
        },

        pub fn deinit(this: *@This(), allocator: std.mem.Allocator) void {
            switch (this.*) {
                inline .@"return", .throw_, .try_ => |e| {
                    if (e) |expr| destroyExpr(allocator, expr);
                },
                .await_ => |e| destroyExpr(allocator, e),
                inline .@"break", .yield => |jl| {
                    if (jl.value) |expr| destroyExpr(allocator, expr);
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
        /// Location of the first parameter (the loop's own location when it has none).
        paramsLoc: Loc = .{ .line = 0, .col = 0 },
        /// Decision 8 §10 — `loop (condition) { … }` / `loop { … }`: repeat while
        /// `iter` (a `bool`) holds, binding nothing. Set by the parser for
        /// `loop { … }` and a syntactically boolean condition, and by the
        /// comptime transform for any `iter` inference typed `bool`.
        condition: bool = false,
        body: []StmtOf(phase),
        /// `loop await (iter) { ... }` ---- iterate an `@FutureGenerator`, awaiting each item.
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
        ///   `@field(obj, "name")`               receiver=null, callee="field", is_builtin=true
        ///   `@emit("pub val …")`                receiver=null, callee="emit", is_builtin=true
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
            /// The type on the right of `x is T` — set only on the `is` builtin
            /// call the parser synthesises (`is_builtin_name`), null on every
            /// other call. Left out of the AST dump when null, so the slot moved
            /// no snapshot.
            isType: ?TypeRef = null,
            /// The callee as an **expression** rather than a name — set only
            /// for `adder(3)(4)`, where what is called is the result of the
            /// previous call and no name exists to put in `callee` (which is
            /// then `""`). `receiver` stays null: a chained call is not a
            /// method call, and a consumer that reads `receiver` to mean "the
            /// value before the `.`" must not see one here.
            ///
            /// Null on every call written today, and left out of the AST dump
            /// when null, so the slot moved no snapshot. A backend that does
            /// not read it lowers exactly the calls it lowered before.
            calleeExpr: ?*ExprOf(phase) = null,

            pub fn jsonStringify(this: @This(), jws: anytype) !void {
                return stringifyOmitting(this, jws, &.{}, &.{ "isType", "calleeExpr" });
            }
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
                    if (c.isType) |t| {
                        var owned = t;
                        owned.deinit(allocator);
                    }
                    if (c.calleeExpr) |ce| {
                        ce.deinit(allocator);
                        allocator.destroy(ce);
                    }
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
            /// Element labels the COMPILER attaches (decision 8 §6) — never set
            /// by the parser: construction has no labels. A value lifted from a
            /// template (`@expr(…)`) carries the labels of the structure it was
            /// built from, so `cfg.server.port` resolves. "" = unlabeled.
            /// Arena-owned; not freed by `deinit`.
            labels: []const []const u8 = &.{},
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
        /// `@BehaviorName(field: value, …)` ---- behavior literal instantiation.
        /// Creates a value of the named behavior type with the given fields.
        behaviorLit: struct {
            name: []const u8,
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
                .behaviorLit => |il| {
                    for (il.fields) |f| {
                        f.value.deinit(allocator);
                        allocator.destroy(f.value);
                    }
                    allocator.free(il.fields);
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
            /// True for the handler-less `val assert P = e;` of decision 8 § 9,
            /// whose failure is a fatal assert. The parser still fills
            /// `handler` — with the `@panic(…)` the form desugars to — so every
            /// backend's existing lowering emits the fatal path unchanged; the
            /// flag is what lets the checker tell the two forms apart.
            fatal: bool = false,
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

/// What a `Pattern.variant` node matches (decision 8 §5, 06 N22). The default,
/// `.variant`, is the pre-decision-8 meaning; the other two are §5's shapes that
/// have no name of their own, so they ride on the same node.
pub const PatternShape = enum {
    /// `Ok(v)`, `Shape.Circle(r)`, `.Some(v)` — the variant `name` names.
    variant,
    /// `#(a, b)`, `#(0, s)`, `#(a, ..)` — a tuple pattern (§5.1 P6). Positional
    /// only: `name` is empty, the elements are `payload.literals`, and a label
    /// inside one is a parse error.
    tuple,
    /// `1...9` — an inclusive range (§5.2), both ends included. `name` is empty
    /// and `payload.literals` holds exactly the two bounds, low then high.
    /// `1..9` in a pattern is refused: `..` is iteration.
    range,
};

/// A match pattern used in `case` arms.
///
/// Decision 8 §5's shapes (06 N22) are carried by the existing variants under
/// spellings no source can write, because a new variant here does not compile
/// without edits to `comptime/infer.zig`, `comptime/specialize.zig`,
/// `codegen/erlang.zig` and `format.zig`, which this front's checker half owns:
///
/// | Written | Node |
/// |---|---|
/// | `Shape.Circle(r)` | `.variant` whose `name` is the dotted path |
/// | `.None` / `.Some(v)` | `.ident` / `.variant` whose `name` keeps the leading `.` |
/// | `Rect(width: w, height: h)` | `.variant` with `labels` beside `payload.fields` |
/// | `.Rect(width: w, ..)` | the same, with `rest` set |
/// | `#(a, b)` | `.variant` with `shape == .tuple` |
/// | `1...9` | `.variant` with `shape == .range` |
///
/// **What inference has to do with them** (the checker half of N22): resolve a
/// dotted or dot-shorthand `name` against the matched value's type (§5.1 P8),
/// bind `payload.fields` by `labels` when they are there and by position when
/// they are not (P4), type each bound name from the matched value (P5), let
/// `rest` stand for the fields or elements the pattern does not name and require
/// the arity to match when it is not set (P7), and count arms for
/// exhaustiveness (§5.4) — a guarded arm never counting.
pub const Pattern = union(enum) {
    /// `_`
    wildcard,
    /// enum variant or variable binding: `Red`, `x`, `total`. A `name` carrying
    /// a `.` is a variant path, never a binding: `Maybe.None`, `.None` (§5.1 P8).
    ident: []const u8,
    /// enum variant with a payload: `Ok ok`, `Rgb(r, g, b)`, `Ok(1)`; and, under
    /// `shape`, decision 8's tuple and range patterns.
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
        /// Which of decision 8 §5's patterns this is; `.variant` unless the
        /// parser read a `#(…)` tuple or an `A...B` range.
        shape: PatternShape = .variant,
        /// The labels written in the payload, parallel to `payload.fields` /
        /// `payload.literals` — `""` where an element carried none. Empty when
        /// the pattern is fully positional. Owned slice; the strings slice into
        /// the source.
        labels: []const []const u8 = &.{},
        /// `..` — the pattern ignores the remaining fields or elements (§5.1 P7).
        rest: bool = false,
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
            .variant => |*v| {
                switch (v.payload) {
                    .fields => |f| allocator.free(f),
                    .literals => |args| {
                        for (args) |*p| p.deinit(allocator);
                        allocator.free(args);
                    },
                    .binding => {},
                }
                if (v.labels.len > 0) allocator.free(v.labels);
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
/// JSON dump of a struct (the parser snapshots) that leaves out formatting-only
/// fields: `omitAlways` never appear, `omitIfEmpty` only when their slice is
/// non-empty — so source layout kept for the formatter does not reach every
/// snapshot.
/// `omitIfEmpty` names fields the dump leaves out when they carry nothing: a
/// slice of length 0, or an optional that is null. A field listed there is
/// therefore invisible in every declaration that does not use it, which is what
/// keeps adding one — `typeGuardType`, say — from moving several hundred
/// snapshots that would all gain the same `null`.
fn stringifyOmitting(value: anytype, jws: anytype, comptime omitAlways: []const []const u8, comptime omitIfEmpty: []const []const u8) !void {
    const T = @TypeOf(value);
    try jws.beginObject();
    inline for (@typeInfo(T).@"struct".fields) |f| {
        comptime var always = false;
        comptime var ifEmpty = false;
        inline for (omitAlways) |name| {
            if (comptime std.mem.eql(u8, f.name, name)) always = true;
        }
        inline for (omitIfEmpty) |name| {
            if (comptime std.mem.eql(u8, f.name, name)) ifEmpty = true;
        }
        const empty = if (!ifEmpty) false else switch (@typeInfo(f.type)) {
            .optional => @field(value, f.name) == null,
            .bool => !@field(value, f.name),
            else => @field(value, f.name).len == 0,
        };
        if (!always and !empty) {
            try jws.objectField(f.name);
            try jws.write(@field(value, f.name));
        }
    }
    try jws.endObject();
}

pub const BehaviorField = struct {
    name: []const u8,
    typeName: []const u8,
    /// Comment lines written above the member inside the body (the lexemes,
    /// prefix included), with "" for a blank source line. Owned slice; the
    /// strings slice into the source. Kept by the formatter.
    comments: []const []const u8 = &.{},

    pub fn jsonStringify(this: BehaviorField, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{}, &.{"comments"});
    }
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
    /// Default value expression for the param. Unified with `Field.default`
    /// / struct-field init / enum-variant-field default so call sites,
    /// annotations, record constructors, and enum-variant constructors all
    /// consume the same fallback shape (see infer.zig arity check + the
    /// `fn-param-default-expansion` future spec for call-site injection).
    default: ?Expr = null,
    /// Where the type annotation starts (`x: Foo` → `Foo`'s column). Set by the
    /// parser; `{0,0}` when the param was synthesised. Carries the location an
    /// unknown type name reds at (06 N30) and is left out of the AST dump.
    typeLoc: Loc = .{ .line = 0, .col = 0 },

    /// Dumped without `typeLoc`: the location is a diagnostic aid, not surface.
    pub fn jsonStringify(this: Param, jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("name");
        try jws.write(this.name);
        try jws.objectField("typeRef");
        try jws.write(this.typeRef);
        try jws.objectField("typeName");
        try jws.write(this.typeName);
        try jws.objectField("modifier");
        try jws.write(this.modifier);
        try jws.objectField("fnType");
        try jws.write(this.fnType);
        try jws.objectField("destruct");
        try jws.write(this.destruct);
        try jws.objectField("default");
        try jws.write(this.default);
        try jws.endObject();
    }

    pub fn deinit(this: *Param, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.fnType) |*ft| ft.deinit(allocator);
        if (this.destruct) |*d| d.deinit(allocator);
        if (this.default) |*d| d.deinit(allocator);
    }
};

/// A generic type parameter, e.g. `T` or `R` in `fn select<T, R>(...)`.
/// `default` is set when the param carries a default type ref
/// (`<T, U = string>`); the strict-trailing-position rule for defaults is
/// enforced at parse-time (R16 / RG1).
pub const GenericParam = struct {
    name: []const u8,
    default: ?TypeRef = null,

    pub fn deinit(this: *GenericParam, allocator: std.mem.Allocator) void {
        if (this.default) |*d| d.deinit(allocator);
    }
};

/// A method declared inside a interface.
/// If `body` is null the method is abstract (no default implementation).
pub const BehaviorMethod = struct {
    name: []const u8,
    /// `@[external(target, "module", "symbol")]` annotations on a `declare fn`
    /// member — host-backed interface methods (per-target lowering).
    annotations: []Annotation = &.{},
    /// Generic type parameters, e.g. `<T, R>`. Empty slice when not generic.
    genericParams: []GenericParam = &.{},
    params: []Param,
    /// Return type annotation. null for void methods.
    returnType: ?TypeRef = null,
    /// Where the return-type annotation starts (06 N30); `{0,0}` when the
    /// member was synthesised. Left out of the AST dump.
    returnTypeLoc: Loc = .{ .line = 0, .col = 0 },
    body: ?[]Stmt,
    /// true when declared with `default fn` in an interface body
    is_default: bool = false,
    /// true when declared with `declare fn` inside a struct/record/enum body
    /// or an interface body (bodyless, typed from the signature)
    is_declare: bool = false,
    isPub: bool = false,
    /// Comment lines written above the member inside the body (the lexemes,
    /// prefix included), with "" for a blank source line. Owned slice; the
    /// strings slice into the source. Kept by the formatter.
    comments: []const []const u8 = &.{},
    /// A `//` comment written on the member's own line, after it
    /// (`fn two(self: Self) -> i32 { return 2; } // trailing`). Without this
    /// slot it is picked up as the NEXT member's leading comment, or — on the
    /// last member — by `bodyComments`, and either way it moves below the member
    /// it was written on. Slices into the source.
    trailingComment: ?[]const u8 = null,

    /// True when the method is a host-backed `#[@External.<Target>(…)]`
    /// declaration.
    pub fn isExternal(this: BehaviorMethod) bool {
        for (this.annotations) |a| {
            if (std.mem.startsWith(u8, a.name, "External.") and a.name.len > "External.".len) return true;
        }
        return false;
    }

    /// True when the method carries `#[builtin]` — the host/raw-infra provides
    /// the real body; the bp body is a stub and codegen skips it.
    pub fn isHost(this: BehaviorMethod) bool {
        for (this.annotations) |a| {
            if (std.mem.eql(u8, a.name, "Host")) return true;
        }
        return false;
    }

    /// The `(module, symbol)` of the `external` annotation targeting `target`
    /// (e.g. "node", "erlang"), or null when none matches.
    pub fn externalFor(this: BehaviorMethod, target: []const u8) ?ExternalRef {
        for (this.annotations) |a| {
            if (!std.mem.startsWith(u8, a.name, "External.")) continue;
            if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
            var n = a.args.len;
            if (n >= 1 and isBoolFlagArg(a.args[n - 1])) n -= 1;
            if (n == 1) return .{ .module = "", .symbol = unquoteAnnotationArg(a.args[0]) };
            if (n == 2) return .{ .module = unquoteAnnotationArg(a.args[0]), .symbol = unquoteAnnotationArg(a.args[1]) };
        }
        return null;
    }

    pub fn deinit(this: *BehaviorMethod, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        if (this.annotations.len > 0) allocator.free(this.annotations);
        for (this.genericParams) |*gp| gp.deinit(allocator);
        allocator.free(this.genericParams);
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        if (this.returnType) |*rt| rt.deinit(allocator);
        if (this.body) |stmts| {
            for (stmts) |*s| s.deinit(allocator);
            allocator.free(stmts);
        }
        if (this.comments.len > 0) allocator.free(this.comments);
    }

    pub fn jsonStringify(this: BehaviorMethod, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{"returnTypeLoc"}, &.{ "comments", "trailingComment" });
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
    /// — i.e. `#[@External.<Target>(…)]`. False for user-defined attributes `#[custom()]`.
    is_builtin: bool = false,
    /// Where the annotation name starts (null for synthesized annotations).
    /// Diagnostics raised by a decorator body point here.
    loc: ?Loc = null,
    /// The arguments as written, when `args` holds a translation — an
    /// `@External` template whose positional markers (decision 5) were mapped
    /// to the renderers' receiver convention (`parser/template_markers.zig`).
    /// `args` and its strings are then owned; `source_args` borrows the source.
    source_args: ?[]const []const u8 = null,
    /// The label written before each argument — `keyed` in
    /// `#[@BeamMemory.Ets(keyed = true)]`, `inline` in `inline = true` — parallel
    /// to `args`, `""` where the argument had none. Empty when no argument was
    /// labelled, so an unlabelled annotation dumps and frees as before. The
    /// value still lands positionally in `args`; the label is what a validator
    /// checks (decision 41) and what the formatter prints back — before this
    /// field it printed `#[@External.Node("charAt", true)]` for `inline = true`.
    labels: []const []const u8 = &.{},

    /// The label of argument `i`, or null when it was written bare.
    pub fn labelOf(this: Annotation, i: usize) ?[]const u8 {
        if (i >= this.labels.len or this.labels[i].len == 0) return null;
        return this.labels[i];
    }

    pub fn deinit(this: *Annotation, allocator: std.mem.Allocator) void {
        if (this.labels.len > 0) allocator.free(this.labels);
        if (this.source_args) |src| {
            for (this.args) |a| allocator.free(a);
            allocator.free(src);
        }
        allocator.free(this.args);
    }

    /// The arguments as the author wrote them (see `source_args`).
    pub fn writtenArgs(this: Annotation) []const []const u8 {
        return this.source_args orelse this.args;
    }

    /// The location is diagnostic metadata, not part of the serialized AST.
    pub fn jsonStringify(this: Annotation, jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("name");
        try jws.write(this.name);
        try jws.objectField("args");
        try jws.write(this.writtenArgs());
        if (this.labels.len > 0) {
            try jws.objectField("labels");
            try jws.write(this.labels);
        }
        try jws.objectField("is_builtin");
        try jws.write(this.is_builtin);
        try jws.endObject();
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
/// caller (`BehaviorMethod.callTemplateFor`/`FnDecl.callTemplateFor`) reuses a
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
/// Recognises triple-quoted raw strings (`"""…"""`) for the
/// `prim-op-annotation` template grammar — needed when the template body
/// itself carries `"` (e.g. `Array.join`'s `io_lib:format("~p", …)`). The
/// "indent the block" convention strips ONE leading newline immediately
/// after the opening `"""` and ONE trailing newline immediately before the
/// closing `"""`; inner indentation is preserved (target-language whitespace).
fn unquoteAnnotationArg(arg: []const u8) []const u8 {
    if (arg.len >= 6 and std.mem.startsWith(u8, arg, "\"\"\"") and std.mem.endsWith(u8, arg, "\"\"\"")) {
        var inner = arg[3 .. arg.len - 3];
        if (inner.len > 0 and inner[0] == '\n') inner = inner[1..];
        if (inner.len > 0 and inner[inner.len - 1] == '\n') inner = inner[0 .. inner.len - 1];
        return inner;
    }
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

/// True for the literal `"true"` / `"false"` an `@external` flag drops in
/// after the parser strips its `inline:` label.
fn isBoolFlagArg(arg: []const u8) bool {
    return std.mem.eql(u8, arg, "true") or std.mem.eql(u8, arg, "false");
}

/// `prim-op-annotation` arity branch: `when($argc == N): "<template>"`.
pub const ArityBranch = struct {
    argc: usize,
    /// Template body with the surrounding quotes stripped.
    template: []const u8,
};

/// Parses one `when(argc == N): "<template>"` annotation arg lexeme. Returns
/// null if the arg doesn't look like an arity branch. Whitespace inside the
/// `when(...)` parens is tolerated; the predicate is `argc == <digits>` (the
/// `$argc` spelling reads as a bare `$` to the botopink lexer outside of a
/// string literal, so the surface syntax drops the sigil).
pub fn parseArityBranchArg(raw: []const u8) ?ArityBranch {
    if (!std.mem.startsWith(u8, raw, "when")) return null;
    var i: usize = "when".len;
    while (i < raw.len and (raw[i] == ' ' or raw[i] == '\t')) i += 1;
    if (i >= raw.len or raw[i] != '(') return null;
    const lp = i;
    var depth: usize = 1;
    i += 1;
    while (i < raw.len and depth > 0) : (i += 1) {
        if (raw[i] == '(') depth += 1;
        if (raw[i] == ')') {
            depth -= 1;
            if (depth == 0) break;
        }
    }
    if (i >= raw.len) return null;
    const rp = i;
    const inside = std.mem.trim(u8, raw[lp + 1 .. rp], " \t");
    // Predicate must read `argc == <digits>`.
    const arg_prefix = "argc";
    if (!std.mem.startsWith(u8, inside, arg_prefix)) return null;
    var p: usize = arg_prefix.len;
    while (p < inside.len and (inside[p] == ' ' or inside[p] == '\t')) p += 1;
    if (p + 1 >= inside.len or inside[p] != '=' or inside[p + 1] != '=') return null;
    p += 2;
    while (p < inside.len and (inside[p] == ' ' or inside[p] == '\t')) p += 1;
    var argc: usize = 0;
    var digits: usize = 0;
    while (p < inside.len and std.ascii.isDigit(inside[p])) : (p += 1) {
        argc = argc * 10 + (inside[p] - '0');
        digits += 1;
    }
    if (digits == 0) return null;
    // After `)` expect `:` then the template string.
    var j = rp + 1;
    while (j < raw.len and (raw[j] == ' ' or raw[j] == '\t')) j += 1;
    if (j >= raw.len or raw[j] != ':') return null;
    j += 1;
    while (j < raw.len and (raw[j] == ' ' or raw[j] == '\t')) j += 1;
    const value = std.mem.trim(u8, raw[j..], " \t");
    return .{ .argc = argc, .template = unquoteAnnotationArg(value) };
}

/// True when `annotations` carry at least one `when($argc == N): "..."` branch
/// targeting `target`. Used by callers to know whether arity-branch dispatch
/// is in play and choose the matching branch via `externalArityBranchFor`.
pub fn externalHasArityBranches(annotations: []const Annotation, target: []const u8) bool {
    for (annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "External.")) continue;
        if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
        for (a.args) |raw| {
            if (parseArityBranchArg(raw) != null) return true;
        }
    }
    return false;
}

/// Returns the `when($argc == argc)` template body for `target`, or null if no
/// arity-branch annotation matches. Caller is responsible for emitting the
/// `prim-op-no-arity-match` diagnostic (RP2) when this returns null AND the
/// annotation set IS arity-branched (cf. `externalHasArityBranches`).
pub fn externalArityBranchFor(annotations: []const Annotation, target: []const u8, argc: usize) ?[]const u8 {
    for (annotations) |a| {
        if (!std.mem.startsWith(u8, a.name, "External.")) continue;
        if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
        for (a.args) |raw| {
            const branch = parseArityBranchArg(raw) orelse continue;
            if (branch.argc == argc) return branch.template;
        }
    }
    return null;
}

/// `val Name = interface { ... }`  or  `val Name = interface <T> { ... }`
pub const BehaviorDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"behavior_{id:0>4}"` when rendered.
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
    fields: []BehaviorField,
    /// Whether the last field/method had a trailing comma in the source.
    trailingComma: bool = false,
    methods: []BehaviorMethod,
    /// Comment lines after the last member, before `}` ("" = blank line). Owned slice.
    bodyComments: []const []const u8 = &.{},

    pub fn deinit(this: *BehaviorDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        for (this.genericParams) |*gp| gp.deinit(allocator);
        allocator.free(this.genericParams);
        allocator.free(this.extends);
        for (this.fields) |f| if (f.comments.len > 0) allocator.free(f.comments);
        allocator.free(this.fields);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
        if (this.bodyComments.len > 0) allocator.free(this.bodyComments);
    }

    pub fn jsonStringify(this: BehaviorDecl, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{}, &.{"bodyComments"});
    }
};

// ── enum decl ─────────────────────────────────────────────────────────────────

/// One variant of an enum.
/// Simple:  `Red`
/// Payload: `Rgb(r: Int, g: Int, b: Int)`
/// Numeric (sections only): `500` — `name` carries the digit string verbatim
/// and `numeric == true` so codegen can lower it as `_500`.
pub const EnumVariant = struct {
    name: []const u8,
    /// Empty for simple (unit) variants; non-empty for payload variants.
    fields: []Field,
    /// True iff the variant name is a pure-digit literal. Only legal inside an
    /// enum-section body (top-level enum body still rejects digit names).
    numeric: bool = false,
    /// Position among the members of the body that declares it, counting
    /// variants and sections together. `variants` and `sections` are two
    /// parallel slices, so without this the interleaving the source wrote is
    /// gone by the time anything reads the AST, and a printer can only emit all
    /// of one list and then all of the other. Layout only — never dumped.
    order: u32 = 0,
    /// `//` comment lines written above the variant, with "" for a blank source
    /// line — the same convention `Field.comments` and `BehaviorMethod.comments`
    /// use. Owned slice; the strings slice into the source.
    comments: []const []const u8 = &.{},
    /// A `//` comment written on the variant's own line, after it (`Red, // warm`).
    /// Slices into the source.
    trailingComment: ?[]const u8 = null,

    pub fn deinit(this: *EnumVariant, allocator: std.mem.Allocator) void {
        for (this.fields) |*f| f.deinit(allocator);
        allocator.free(this.fields);
        if (this.comments.len > 0) allocator.free(this.comments);
    }

    /// `order` is layout, and the trivia is written only when present, so a
    /// variant that carries neither dumps exactly as it did before they existed.
    pub fn jsonStringify(this: EnumVariant, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{"order"}, &.{ "comments", "trailingComment" });
    }
};

/// A named grouping of variants inside an enum body:
///   `Color { Red { 100, 500 }, Blue { 500 }, Hex(string) }`
/// Sections nest arbitrarily deep; variants and nested sections may interleave
/// at any level. Section names are PascalCase identifiers — pure-digit names
/// are reserved for variant leaves only.
pub const EnumSection = struct {
    name: []const u8,
    /// Bare variants directly inside this section (may include numeric leaves).
    variants: []EnumVariant,
    /// Nested sub-sections.
    sections: []EnumSection,
    /// Position among the members of the body that declares it — see
    /// `EnumVariant.order`, which counts from the same sequence. Layout only.
    order: u32 = 0,
    /// `//` comment lines written above the section, with "" for a blank source
    /// line. Owned slice; the strings slice into the source.
    comments: []const []const u8 = &.{},

    pub fn deinit(this: *EnumSection, allocator: std.mem.Allocator) void {
        for (this.variants) |*v| v.deinit(allocator);
        allocator.free(this.variants);
        for (this.sections) |*s| s.deinit(allocator);
        allocator.free(this.sections);
        if (this.comments.len > 0) allocator.free(this.comments);
    }

    pub fn jsonStringify(this: EnumSection, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{"order"}, &.{"comments"});
    }
};

// ── type reference ────────────────────────────────────────────────────────────

/// One field of an anonymous record TYPE: `name: Type` in `{ value: T, set: fn(T) }`.
/// A type annotation expression, e.g. `Int`, `string[]`, `#(Int, string)`, `?T`.
/// The reserved `TypeRef.named` spelling of decision 8 §2's `unknown` (06 N19).
///
/// `unknown` lexes as a keyword (`TokenKind.unknown`), so no declaration can be
/// named `unknown` and this spelling can only come from the `unknown` written
/// in a type position — never from a user type of that name.
///
/// **What inference has to do with it** (the checker half of N19): resolve a
/// `TypeRef.named` equal to this to the `unknown` type instead of looking the
/// name up, and give that type §2's rules — every value assignable *into* it,
/// nothing out of it without an `is` check, `@print`/`==`/`!=` and a generic
/// argument allowed, arithmetic / field access / indexing / method calls
/// refused, and a `pub` declaration whose *inferred* type contains it an error.
pub const unknown_type_name = "unknown";

/// The reserved `TypeRef.generic` name that carries decision 8 §3's union type
/// `A | B` (06 N20): `generic{ .name = union_type_name, .args = <members>,
/// .is_builtin = false }`, members in source order, never fewer than two.
///
/// It is a spelling no source can write — `consumeTypeName` needs an identifier
/// — so no user type collides with it. It is not a `TypeRef` variant of its own
/// because one does not compile without edits to `comptime/infer.zig`,
/// `codegen/typescript.zig`, `format.zig` and the language server, which this
/// front's checker half owns; promoting it to a variant is a rename away once
/// both halves are in one tree.
///
/// **What inference has to do with it** (the checker half of N20): resolve it to
/// a union of its members instead of a named type, and give it §3's rules — a
/// value assignable when it is assignable to one member, only the operations
/// every member allows, narrowing by `is` and by a `case` arm, the join of
/// `X<A> | X<B>` for a single-value immutable container and for `Dict` (never
/// for `T[]`), and the error reported at the *use*, naming the branch that
/// widened it.
pub const union_type_name = "|";

/// The reserved builtin-call name that carries decision 8 §4's `x is T`
/// (06 N21): `call{ .callee = is_builtin_name, .is_builtin = true,
/// .args = &.{ <the value> }, .isType = <the type> }` — the desugaring of the
/// expression into `@is(x)` with the tested type on the node, since a type is
/// not an expression and no AST union here may gain a variant.
///
/// `is` is a keyword, so no user function is called `is` and no source can write
/// this call by hand.
///
/// **What inference has to do with it** (the checker half of N21): type the call
/// `bool`, test the *value* by §4.1 (a number by range, converting inside the
/// narrowed block), narrow the operand for the guarded block / arm body, and
/// warn when the operand's static type makes the answer always false (§4.3).
/// `Box<i32>` as the tested type is §4.2's error — only `Box<unknown>` is
/// checkable.
pub const is_builtin_name = "is";

/// The reserved builtin-call name that carries [decision 30](../../../specs)'s
/// index expression: `call{ .callee = index_builtin_name, .is_builtin = true,
/// .args = &.{ <the receiver>, <the index> } }` — the desugaring of `xs[0]`
/// into `@[](xs, 0)`, for the same reason `is` desugars: **no AST union here
/// may gain a variant**, and every consumer would otherwise have to grow an arm
/// before the form can parse at all.
///
/// The spelling is not an identifier, like `union_type_name`, so no source can
/// write this call by hand: `@[](…)` does not lex.
///
/// **The index is an ordinary expression**, which is what makes one node serve
/// indexing *and* slicing: `xs[0..2]` is this call with a `range` second
/// argument (`decision-8:447` — "`..` belongs to iteration and slicing"), and a
/// dict read `d["k"]` is this call with a string.
///
/// **What inference has to do with it** (`01-checker`): type the call by the
/// receiver — the element type for an array, the value type for a dict, a
/// character for a string, the member type for a tuple with a constant index —
/// decide whether it answers `T` or `?T`, and refuse an index on a receiver
/// decision 8 §2 says has none (`:112` lists indexing among the operations
/// `unknown` refuses). **What each backend has to do with it** (fronts 02–05):
/// lower it. Until then it reaches each backend's unrecognised-builtin path,
/// which is the same place `x is T` reached before `04-js` lowered it.
pub const index_builtin_name = "[]";

/// The binding name the parser gives `a ?? b`'s desugaring (decision 28).
///
/// `a ?? b` becomes `if (a) { <this> -> <this> } else { b }` — the optional
/// binding form the language already has (`if (email) { e -> … }`), which
/// evaluates `a` once and narrows it inside the branch. There is no `??`
/// operator in `BinOp` and no new AST node, for the reason `is_builtin_name`
/// states: no AST union here may gain a variant, and every consumer would have
/// to grow an arm before the form could parse at all. The desugaring instead
/// reaches machinery all four backends already lower.
///
/// The `__bp` prefix is the codebase's reserved one (`__bp_show`, `__bp_eq`),
/// so a nested `a ?? (b ?? c)` shadows correctly and no user name collides in
/// practice.
pub const nullish_binding_name = "__bp_nullish";

pub const TypeRef = union(enum) {
    /// Plain named type: `Int`, `string`, `Self`. Slice into source — not heap-owned.
    named: []const u8,
    /// Array type: `T[]`. Owns the element type.
    array: *TypeRef,
    /// Tuple type: `#(T1, T2, ...)`. Owns the element types.
    tuple_: []TypeRef,
    /// Tuple type with labels: `#(name: string, pop: i32)` (decision 8 §6). The
    /// labels are names for the compiler — `row.pop` becomes a positional access
    /// and the run-time value is the plain tuple. Owns `elems` and the `labels`
    /// slice (the label strings slice into the source).
    labeledTuple: struct { elems: []TypeRef, labels: []const []const u8 },
    /// Optional type: `?T`. Owns the inner type.
    optional: *TypeRef,
    /// Function type: `fn(T1, T2) -> R`. Owns both param types and return type.
    function: struct {
        params: []TypeRef,
        returnType: *TypeRef,
        /// The documentation names written in `fn(item: T)` ("" where none), for
        /// the formatter; function types stay positional. Owned slice; the
        /// strings slice into the source. Left out of the AST dump.
        paramNames: []const []const u8 = &.{},

        pub fn jsonStringify(this: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("params");
            try jws.write(this.params);
            try jws.objectField("returnType");
            try jws.write(this.returnType);
            try jws.endObject();
        }
    },
    /// Generic type: `@Result<D, E>` (builtin) or `MyType<T>` (user-defined). Owns the argument types.
    generic: struct { name: []const u8, args: []TypeRef, is_builtin: bool },
    /// Comptime type parameter: `typeparam` or `typeparam string | int | bool`.
    /// `constraints` is the `|`-separated list of accepted types; an empty slice
    /// means the typeparam is unconstrained and accepts any type. Owns the constraints.
    /// Surface syntax (post-F0): `type` / `type string | int | bool`.
    typeparam: []TypeRef,

    /// The members of a union type `A | B` (`union_type_name`); null otherwise.
    pub fn unionMembers(this: TypeRef) ?[]TypeRef {
        return switch (this) {
            .generic => |g| if (!g.is_builtin and std.mem.eql(u8, g.name, union_type_name)) g.args else null,
            else => null,
        };
    }

    /// The element types of a tuple type, labeled or not; null otherwise.
    pub fn tupleElems(this: TypeRef) ?[]TypeRef {
        return switch (this) {
            .tuple_ => |elems| elems,
            .labeledTuple => |lt| lt.elems,
            else => null,
        };
    }

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
            .labeledTuple => |lt| {
                for (lt.elems) |*e| e.deinit(allocator);
                allocator.free(lt.elems);
                allocator.free(lt.labels);
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
                if (f.paramNames.len > 0) allocator.free(f.paramNames);
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

/// Top-level binding: `val name = expr`, `val name: Type = expr` — or, since
/// decision 38 / front 17, `var name: Type = expr`, the module-level `var`
/// that a `#[@BeamMemory.<mode>]` annotation gives storage on the BEAM.
pub const ValDecl = struct {
    name: []const u8,
    isPub: bool = false,
    /// `var` rather than `val`: the binding may be assigned. The local form
    /// keeps the same bit on `localBind.mutable`; this is it one level up.
    mutable: bool = false,
    /// `#[…]` written above the declaration — `#[@BeamMemory.Ets]`. Empty for
    /// the plain form; only a `var` may carry one (checked by inference).
    annotations: []Annotation = &.{},
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
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        this.value.deinit(allocator);
        allocator.destroy(this.value);
    }

    /// `mutable` (false) and `annotations` (empty) are left out of the AST
    /// dump, so a `val` written today dumps exactly as it did before the two
    /// fields existed and no parser snapshot moves.
    pub fn jsonStringify(this: @This(), jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{}, &.{ "mutable", "annotations" });
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
    type_: TypeDecl,
    implement: ImplementDecl,
    extend: ExtendDecl,
    use: ImportDecl,
    mod: ModDecl,
    behavior: BehaviorDecl,
    delegate: DelegateDecl,
    @"fn": FnDecl,
    val: ValDecl,
    @"test": TestDecl,
    /// A standalone comment at the top level (not attached to any declaration).
    /// `text` is the comment content without the `//` / `///` / `////` prefix.
    /// `is_module` is true for `////` module-level comments.
    /// `is_doc` is true for `///` doc comments.
    comment: struct {
        text: []const u8,
        is_module: bool,
        is_doc: bool,
        /// Written at the end of the previous declaration's line
        /// (`pub mod geometry; // note`); the formatter keeps it there.
        trailing: bool = false,

        pub fn jsonStringify(this: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("text");
            try jws.write(this.text);
            try jws.objectField("is_module");
            try jws.write(this.is_module);
            try jws.objectField("is_doc");
            try jws.write(this.is_doc);
            if (this.trailing) {
                try jws.objectField("trailing");
                try jws.write(true);
            }
            try jws.endObject();
        }
    },

    pub fn deinit(this: *DeclKind, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .use => |*u| {
                for (u.imports) |imp| allocator.free(imp.segments);
                allocator.free(u.imports);
            },
            .behavior => |*t| t.deinit(allocator),
            .delegate => |*d| d.deinit(allocator),
            .type_ => |*t| t.deinit(allocator),
            .implement => |*i| i.deinit(allocator),
            .extend => |*x| x.deinit(allocator),
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
    /// `blankLineBefore[i]`: a blank source line precedes `decls[i]` (empty
    /// when the program was not parsed from source). The formatter keeps it.
    blankLineBefore: []const bool = &.{},

    pub fn deinit(this: *Program, allocator: std.mem.Allocator) void {
        for (this.decls) |*d| d.deinit(allocator);
        allocator.free(this.decls);
        if (this.blankLineBefore.len > 0) allocator.free(this.blankLineBefore);
    }

    pub fn jsonStringify(this: Program, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{"blankLineBefore"}, &.{});
    }
};

// ── fn decl ───────────────────────────────────────────────────────────────────

/// `pub fn name<T>(params) ReturnType { body }`
/// `isPub` is false for module-private functions.
/// The effect a function implements, named by a `#[@<effect>]` annotation. The
/// matching `@Effect<…>` return wrapper carries the effect's type parameters;
/// this enum is the source of truth for how the function lowers and which body
/// operations (`await` / `yield` / `throw`) it permits.
pub const EffectKind = enum {
    result,
    future,
    generator,
    resultGenerator,
    futureGenerator,
    context,

    /// Every effect, in declaration order. The one list: `fromAnnotationName`
    /// and `comptime/effect_chain.zig` both walk it, so a seventh effect is a
    /// value here and nowhere else.
    pub const all = [_]EffectKind{ .result, .future, .generator, .resultGenerator, .futureGenerator, .context };

    /// The annotation spelling — `#[@<name>]` — for this effect.
    pub fn annotationName(self: EffectKind) []const u8 {
        return switch (self) {
            .result => "result",
            .future => "future",
            .generator => "generator",
            .resultGenerator => "resultGenerator",
            .futureGenerator => "futureGenerator",
            .context => "context",
        };
    }

    /// The builtin return-type wrapper this effect requires (`@Future`, …).
    pub fn returnWrapper(self: EffectKind) []const u8 {
        return switch (self) {
            .result => "Result",
            .future => "Future",
            .generator => "Generator",
            .resultGenerator => "ResultGenerator",
            .futureGenerator => "FutureGenerator",
            .context => "Context",
        };
    }

    /// Map a builtin annotation name (`future`, …) to its effect, or null when
    /// the name is not one of the builtin effect markers.
    pub fn fromAnnotationName(name: []const u8) ?EffectKind {
        for (all) |kind| {
            if (std.mem.eql(u8, kind.annotationName(), name)) return kind;
        }
        return null;
    }
};

pub const FnDecl = struct {
    isPub: bool,
    /// The function's effect, or null for a plain function. Set from a
    /// `#[@<effect>]` annotation. The return wrapper carries the type params.
    effect: ?EffectKind = null,
    /// `declare fn` ---- a bodyless declaration typed from the signature alone.
    /// Required for `@[external(…)]` FFI fns (the only valid annotated form).
    isDeclare: bool = false,
    /// `pub default fn` — a package's DEFAULT handler, invoked by the
    /// `<package> "…"` DSL form (`q "select …"`). Declarable at any module's top
    /// level (not just `root.bp`).
    isDefault: bool = false,
    /// Optional generator label declared after the return type
    /// (`#[@resultGenerator] fn f() -> @ResultGenerator<T, E> :gen`), used to
    /// disambiguate `yield :label` / `break :label` from an enclosing loop's.
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
    /// Where the return-type annotation starts (`-> Foo` → `Foo`'s column). Set
    /// by the parser; `{0,0}` when the fn was synthesised. Carries the location
    /// an unknown type name reds at (06 N30) and is left out of the AST dump.
    returnTypeLoc: Loc = .{ .line = 0, .col = 0 },
    /// When non-null, this fn is a type guard: `fn f(x: T) -> x is NarrowedType`.
    /// The string names the parameter being narrowed.
    typeGuardParam: ?[]const u8 = null,
    /// The narrowed type of a type guard (`NarrowedType` above). 06 C5: a guard
    /// *returns* `bool` — `returnType` says so — and this slot holds the type the
    /// parameter is narrowed to in the branch the guard proves. Before C5 the
    /// narrowed type was parked in `returnType`, which typed every guard call as
    /// `T` and made the narrowing at the `if` unreachable.
    typeGuardType: ?TypeRef = null,
    body: []Stmt,

    /// The effect named by a `#[@<effect>]` annotation on this fn, if any.
    /// Equivalent to `this.effect` — kept as an alias for callers that want
    /// to express "the effect spelled in source", since the field used to be
    /// distinct when the deprecated `*fn` prefix could also set `effect`.
    pub fn effectAnnotation(this: FnDecl) ?EffectKind {
        return this.effect;
    }

    /// True when the fn is an `@[external(…)]` / `@[External.<Target>(…)]` FFI
    /// declaration (bodyless; each codegen backend lowers calls to its
    /// target's symbol).
    pub fn isExternal(this: FnDecl) bool {
        for (this.annotations) |a| {
            if (std.mem.startsWith(u8, a.name, "External.") and a.name.len > "External.".len) return true;
        }
        return false;
    }

    /// True when the fn carries `#[builtin]` — the host/raw-infra provides the
    /// real body; the bp body is a stub and codegen skips it.
    pub fn isHost(this: FnDecl) bool {
        for (this.annotations) |a| {
            if (std.mem.eql(u8, a.name, "Host")) return true;
        }
        return false;
    }

    /// True when the declared return type is the builtin `@Result<_, _>`.
    /// An `#[@result] fn -> @Result<…>` is the checked-Result effect form (it
    /// emits as a plain function in every backend, never as an async/generator).
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
        for (this.annotations) |a| {
            if (!std.mem.startsWith(u8, a.name, "External.")) continue;
            if (!std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
            var n = a.args.len;
            if (n >= 1 and isBoolFlagArg(a.args[n - 1])) n -= 1;
            if (n == 1) return .{ .module = "", .symbol = unquoteAnnotationArg(a.args[0]) };
            if (n == 2) return .{ .module = unquoteAnnotationArg(a.args[0]), .symbol = unquoteAnnotationArg(a.args[1]) };
        }
        return null;
    }

    /// Dumped without `returnTypeLoc`: the location is a diagnostic aid, not
    /// surface, and the AST dumps are snapshot-compared.
    pub fn jsonStringify(this: FnDecl, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{"returnTypeLoc"}, &.{"typeGuardType"});
    }

    pub fn deinit(this: *FnDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        for (this.genericParams) |*gp| gp.deinit(allocator);
        allocator.free(this.genericParams);
        for (this.params) |*p| p.deinit(allocator);
        allocator.free(this.params);
        if (this.returnType) |*rt| rt.deinit(allocator);
        if (this.typeGuardType) |*gt| gt.deinit(allocator);
        for (this.body) |*s| s.deinit(allocator);
        allocator.free(this.body);
    }
};

// ── type decl ───────────────────────────────────────────────────────────────────

/// One field — of a record field list or of an enum variant payload:
/// `name: Type` or `name: ?Type = default`.
pub const Field = struct {
    name: []const u8,
    typeRef: TypeRef,
    /// Optional default value, e.g. `= null` or `= 0`.
    default: ?Expr = null,
    /// Member-level decorators on the field (`#[inject] repo: …`).
    annotations: []Annotation = &.{},
    /// `//` comments written before the field in a 1.0.3 field list
    /// (`type Config(\n // where it listens\n host: string)`), text only.
    /// Owned. Kept so the formatter prints them back.
    comments: []const []const u8 = &.{},
    /// A `//` comment written on the field's own line, after it
    /// (`x: i32, // the horizontal coordinate`). Without this slot the comment
    /// is read as the NEXT field's leading comment — where it says something
    /// false — and on the last field there is no next field, so it was freed.
    /// Text only and owned, like `comments`.
    trailingComment: ?[]const u8 = null,
    /// Where the field's type annotation starts (06 N30). `{0,0}` when
    /// synthesised. Left out of the AST dump.
    typeLoc: Loc = .{ .line = 0, .col = 0 },

    pub fn deinit(this: *Field, allocator: std.mem.Allocator) void {
        this.typeRef.deinit(allocator);
        if (this.default) |*d| d.deinit(allocator);
        for (this.annotations) |*ann| ann.deinit(allocator);
        if (this.annotations.len > 0) allocator.free(this.annotations);
        for (this.comments) |c| allocator.free(c);
        if (this.comments.len > 0) allocator.free(this.comments);
        if (this.trailingComment) |c| allocator.free(c);
    }

    /// `comments` is written only when present, so a field without comments
    /// serializes exactly as before the field list kept them.
    pub fn jsonStringify(this: Field, jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("name");
        try jws.write(this.name);
        try jws.objectField("typeRef");
        try jws.write(this.typeRef);
        try jws.objectField("default");
        try jws.write(this.default);
        try jws.objectField("annotations");
        try jws.write(this.annotations);
        if (this.comments.len > 0) {
            try jws.objectField("comments");
            try jws.write(this.comments);
        }
        if (this.trailingComment) |c| {
            try jws.objectField("trailingComment");
            try jws.write(c);
        }
        try jws.endObject();
    }
};

/// The body shape of a `TypeDecl`: a field list (record) or variants and
/// sections (enum).
pub const TypeShape = union(enum) {
    /// Inline fields declared in the parameter list.
    record: []Field,
    enum_: EnumShape,

    /// Two parallel slices, and an enum body may **interleave** them. The
    /// source order lives in each member's `order` field, not in the slices:
    /// read them together and sort by it to recover what was written.
    ///
    /// **Nothing in `src/codegen/` may key on a variant's position in
    /// `variants`.** A section desugars into a synthesised inner enum with a
    /// mangled name, and no emitter derives a run-time encoding from an ordinal
    /// (`grep -r 'variantIndex\|tag_index\|ordinal' src/codegen/` → 0 hits;
    /// emilia built from both orderings emits byte-identical output on commonJS,
    /// erlang, beam and wasm, and its 17 cells pass either way — re-measured
    /// 2026-09-18 at `f8d97f95`, after fronts 02, 03, 04 and 05 had landed their
    /// emitter work, by hoisting the 13 variants `tokens.bp` writes after a
    /// section and diffing all four output trees). The moment one emitter did key
    /// on the position, the order a member is stored in would stop being layout
    /// and start being semantics, and it would do so silently.
    pub const EnumShape = struct {
        variants: []EnumVariant,
        /// Top-level sections (recursive groupings) declared inside the body. The
        /// comptime desugars each section into a synthesised inner enum with a
        /// mangled name encoding the path. Empty for plain enums.
        sections: []EnumSection = &.{},
    };

    pub fn deinit(this: *TypeShape, allocator: std.mem.Allocator) void {
        switch (this.*) {
            .record => |fields| {
                for (fields) |*f| f.deinit(allocator);
                allocator.free(fields);
            },
            .enum_ => |*e| {
                for (e.variants) |*v| v.deinit(allocator);
                allocator.free(e.variants);
                for (e.sections) |*sec| sec.deinit(allocator);
                allocator.free(e.sections);
            },
        }
    }
};

/// A named type: a record (`val Name = record(val f: T) { fn ... }`) or an
/// enum (`val Color = enum { Red, Rgb(r: Int) }`). The shape tells them apart.
pub const TypeDecl = struct {
    name: []const u8,
    /// Auto-generated unique ID counter, formatted as `"type_{id:0>4}"` when rendered.
    id: u32 = 0,
    isPub: bool = false,
    docComment: ?[]const u8 = null,
    /// `//` regular comment (last one before the declaration)
    comment: ?[]const u8 = null,
    /// `////` module-level documentation
    moduleComment: ?[]const u8 = null,
    annotations: []Annotation = &.{},
    /// Generic type parameters, e.g. `<T>`.
    genericParams: []GenericParam = &.{},
    /// Inline behavior implementations: `record(...) implement I1 { }`.
    implement: []TypeRef = &.{},
    shape: TypeShape,
    /// Whether the last field/variant had a trailing comma in the source.
    trailingComma: bool = false,
    /// Methods declared in the body (may include `declare fn` abstract slots).
    methods: []BehaviorMethod = &.{},
    /// Comment lines after the last member, before `}` ("" = blank line). Owned slice.
    bodyComments: []const []const u8 = &.{},

    /// True for the record shape (a field list).
    pub fn isRecord(this: TypeDecl) bool {
        return this.shape == .record;
    }

    /// The record fields; empty for an enum.
    pub fn recordFields(this: TypeDecl) []Field {
        return switch (this.shape) {
            .record => |f| f,
            .enum_ => &.{},
        };
    }

    /// The enum variants; empty for a record.
    pub fn variants(this: TypeDecl) []EnumVariant {
        return switch (this.shape) {
            .record => &.{},
            .enum_ => |e| e.variants,
        };
    }

    /// The enum sections; empty for a record.
    pub fn sections(this: TypeDecl) []EnumSection {
        return switch (this.shape) {
            .record => &.{},
            .enum_ => |e| e.sections,
        };
    }

    pub fn deinit(this: *TypeDecl, allocator: std.mem.Allocator) void {
        for (this.annotations) |*ann| ann.deinit(allocator);
        allocator.free(this.annotations);
        for (this.genericParams) |*gp| gp.deinit(allocator);
        allocator.free(this.genericParams);
        for (this.implement) |*im| im.deinit(allocator);
        allocator.free(this.implement);
        this.shape.deinit(allocator);
        for (this.methods) |*m| m.deinit(allocator);
        allocator.free(this.methods);
        if (this.bodyComments.len > 0) allocator.free(this.bodyComments);
    }

    pub fn jsonStringify(this: TypeDecl, jws: anytype) !void {
        return stringifyOmitting(this, jws, &.{}, &.{"bodyComments"});
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
        for (this.genericParams) |*gp| gp.deinit(allocator);
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
        for (this.genericParams) |*gp| gp.deinit(allocator);
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
