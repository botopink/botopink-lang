//! Erlang abstract syntax — the code model `erl_emitter.zig` renders.
//!
//! `term.zig` models *values*; this file models *code*: expressions, clauses,
//! function definitions and module forms. The Erlang backend and the comptime
//! evaluators build these nodes and let `erl_emitter` produce the text, so the
//! Erlang layout rules (indentation, clause separators, `end`) live in one place.
//!
//! Layout is part of the model where the backend's output depends on it: a
//! clause body is either a block (`Pat ->` + indented statements) or inline
//! (`Pat -> Expr`). A `raw` node embeds author-written Erlang text verbatim — a
//! host template (`#[@External.Erlang("…")]`) and nothing else.
//!
//! Nodes borrow their slices: build them in an arena that outlives rendering.

const std = @import("std");
const Term = @import("term.zig").Term;

pub const Expr = union(enum) {
    /// Host template text, written verbatim (multi-line text carries its own
    /// indentation). Only a host template produces it — see `beam/AGENTS.md`.
    raw: []const u8,
    /// A value literal.
    term: Term,
    /// An Erlang variable, already spelled (`Decl`, `Count@1`, `_`).
    variable: []const u8,
    /// An atom by its unquoted name.
    atom: []const u8,
    /// A binary from a botopink string literal's lexeme (escapes unresolved).
    lexeme_binary: []const u8,
    /// `name(Args)` / `module:name(Args)`.
    call: Call,
    /// `Fun(Args)` — applying a variable or expression.
    apply: Apply,
    /// `(L op R)` or `L op R`.
    binop: BinOp,
    /// `op X` / `(op X)`.
    unop: UnOp,
    /// `Pattern = Value`.
    match: Match,
    tuple: []const Expr,
    list: []const Expr,
    /// `[H1, H2 | Tail]`.
    cons: Cons,
    /// `#{K => V}` / `#{K := V}` (pattern).
    map: []const MapField,
    /// `Map#{K => V}`.
    map_update: MapUpdate,
    /// `[Expr || Gen, Filter]`.
    list_comp: ListComp,
    case_: Case,
    fun: Fun,
    try_catch: TryCatch,
    /// `<<V1/binary, V2>>`.
    bin: []const BinSegment,
    /// A numeric literal token, written as the source spelled it.
    number: []const u8,
    /// `(Expr)`.
    paren: *const Expr,
    /// `fun(P1) -> B1; (P2) -> B2 end` on one line — each clause inline.
    fun_clauses: []const Clause,
    /// `Class:Reason` / `Class:Reason:Stack` — a `catch` clause pattern.
    exception: Exception,
    /// An Erlang string literal `"text"` (a character list) from raw bytes.
    string: []const u8,
    /// `fun name/Arity`.
    fun_ref: FnRef,
    /// `[` newline, one element per line at +1 joined `,`, newline, `]`.
    list_block: []const Expr,
    /// A comment in expression position (`%% continue`): it ends the line, so
    /// it stands in for a construct with no Erlang form.
    comment: Comment,
    /// Parts written one after another with no separator — a host template
    /// (`raw` text around argument nodes).
    seq: []const Expr,

    pub fn v(name: []const u8) Expr {
        return .{ .variable = name };
    }
    pub fn a(name: []const u8) Expr {
        return .{ .atom = name };
    }
    pub fn r(text: []const u8) Expr {
        return .{ .raw = text };
    }
    pub fn t(value: Term) Expr {
        return .{ .term = value };
    }
};

/// `name/Arity` — a function reference in `fun`, `-export` and `-compile`.
pub const FnRef = struct {
    name: []const u8,
    arity: usize,
};

pub const Call = struct {
    module: ?[]const u8 = null,
    name: []const u8,
    args: []const Expr = &.{},
};

pub const Apply = struct {
    fun: *const Expr,
    args: []const Expr = &.{},
};

pub const BinOp = struct {
    op: []const u8,
    lhs: *const Expr,
    rhs: *const Expr,
    parens: bool = true,
};

pub const UnOp = struct {
    op: []const u8,
    operand: *const Expr,
    parens: bool = true,
};

pub const Match = struct {
    pattern: *const Expr,
    value: *const Expr,
};

pub const Cons = struct {
    heads: []const Expr,
    tail: *const Expr,
};

pub const MapField = struct {
    key: Expr,
    value: Expr,
    /// `:=` (map pattern / exact update) instead of `=>`.
    exact: bool = false,
};

pub const MapUpdate = struct {
    map: *const Expr,
    fields: []const MapField,
};

pub const ListComp = struct {
    element: *const Expr,
    /// Generators (`Pat <- List`) and filters, in order.
    qualifiers: []const Qualifier,

    pub const Qualifier = union(enum) {
        generator: struct { pattern: Expr, list: Expr },
        filter: Expr,
    };
};

pub const BinSegment = struct {
    value: Expr,
    /// Segment type (`binary`, `utf8`, …); null for the default.
    type: ?[]const u8 = null,
};

pub const Exception = struct {
    class: *const Expr,
    reason: *const Expr,
    stack: ?*const Expr = null,
};

pub const Case = struct {
    subject: *const Expr,
    clauses: []const Clause,
    layout: Layout = .block,

    pub const Layout = enum {
        /// `case S of` newline, one clause per line, `end` on its own line.
        block,
        /// `case S of P1 -> B1; P2 -> B2 end` on one line (clauses inline).
        inline_,
    };
};

pub const Fun = struct {
    params: []const Expr,
    body: Body,
    /// Named fun (`fun Loop(I) -> … end`) — the name is in scope inside the
    /// body, which is how an unbounded loop recurses. Null for a plain `fun`.
    name: ?[]const u8 = null,
};

pub const TryCatch = struct {
    body: Body,
    /// Catch clauses; the pattern is written as `Class:Reason[:Stack]`.
    catches: []const Clause,
};

pub const Clause = struct {
    /// Patterns of the clause head. A `case` clause has exactly one; a function
    /// clause has one per parameter (written `(P1, P2)`).
    patterns: []const Expr,
    /// Guard tests joined by `,` (all must hold).
    guards: []const Expr = &.{},
    body: Body,
    layout: Layout = .block,

    pub const Layout = enum {
        /// `Head ->` newline, body statements indented one level deeper.
        block,
        /// `Head -> Stmt1, Stmt2` on the head's line.
        inline_,
    };
};

/// A sequence of statements.
pub const Body = struct {
    stmts: []const Stmt,

    pub fn of(stmts: []const Stmt) Body {
        return .{ .stmts = stmts };
    }
};

pub const Stmt = union(enum) {
    expr: Expr,
    /// A comment line — never takes a `,` separator.
    comment: Comment,
};

/// `% text` (line), `%% text` (doc, the default) or `%%% text` (module). The
/// text is written after the prefix and one space, as given.
pub const Comment = struct {
    level: Level = .doc,
    text: []const u8,

    pub const Level = enum { line, doc, module };

    pub fn doc(text: []const u8) Comment {
        return .{ .text = text };
    }
};

/// `name(P1, P2) -> Body.` with one or more clauses.
pub const Function = struct {
    name: []const u8,
    clauses: []const Clause,
};

/// `-import(mod, [f/1, g/2]).` — functions another module defines that this one
/// calls by their bare name. The comptime evaluators use it to reach the host
/// glue in the resident prelude without rendering it into every generated
/// module (`comptime/runtime/prelude.zig`).
pub const Import = struct {
    module: []const u8,
    funs: []const FnRef,
};

pub const Form = union(enum) {
    /// `-module(name).` — the name as spelled.
    module: []const u8,
    /// `-export([f/0, g/1]).`
    exports: []const FnRef,
    /// `-import(mod, [f/1]).`
    import: Import,
    /// `-compile({no_auto_import,[f/1]}).`
    no_auto_import: []const FnRef,
    function: Function,
    /// A comment line.
    comment: Comment,
    /// An empty line.
    blank,
};

/// Arena-backed construction helpers: copy slices and allocate child nodes so a
/// tree built from runtime values outlives the builder's caller frames.
pub const Builder = struct {
    arena: std.mem.Allocator,

    pub const Error = std.mem.Allocator.Error;

    pub fn ptr(b: Builder, e: Expr) Error!*const Expr {
        const p = try b.arena.create(Expr);
        p.* = e;
        return p;
    }

    pub fn exprs(b: Builder, items: []const Expr) Error![]const Expr {
        return b.arena.dupe(Expr, items);
    }

    /// A body of expression statements.
    pub fn body(b: Builder, items: []const Expr) Error!Body {
        const stmts = try b.arena.alloc(Stmt, items.len);
        for (items, 0..) |e, i| stmts[i] = .{ .expr = e };
        return .{ .stmts = stmts };
    }

    pub fn call(b: Builder, name: []const u8, args: []const Expr) Error!Expr {
        return .{ .call = .{ .name = name, .args = try b.exprs(args) } };
    }

    pub fn remote(b: Builder, module: []const u8, name: []const u8, args: []const Expr) Error!Expr {
        return .{ .call = .{ .module = module, .name = name, .args = try b.exprs(args) } };
    }

    pub fn tuple(b: Builder, items: []const Expr) Error!Expr {
        return .{ .tuple = try b.exprs(items) };
    }

    pub fn list(b: Builder, items: []const Expr) Error!Expr {
        return .{ .list = try b.exprs(items) };
    }

    pub fn map(b: Builder, fields: []const MapField) Error!Expr {
        return .{ .map = try b.arena.dupe(MapField, fields) };
    }

    pub fn match(b: Builder, pattern: Expr, value: Expr) Error!Expr {
        return .{ .match = .{ .pattern = try b.ptr(pattern), .value = try b.ptr(value) } };
    }

    pub fn binop(b: Builder, op: []const u8, lhs: Expr, rhs: Expr) Error!Expr {
        return .{ .binop = .{ .op = op, .lhs = try b.ptr(lhs), .rhs = try b.ptr(rhs) } };
    }

    pub fn cons(b: Builder, heads: []const Expr, tail: Expr) Error!Expr {
        return .{ .cons = .{ .heads = try b.exprs(heads), .tail = try b.ptr(tail) } };
    }

    pub fn exception(b: Builder, class: Expr, reason: Expr) Error!Expr {
        return .{ .exception = .{ .class = try b.ptr(class), .reason = try b.ptr(reason) } };
    }

    pub fn paren(b: Builder, inner: Expr) Error!Expr {
        return .{ .paren = try b.ptr(inner) };
    }

    pub fn caseOf(b: Builder, subject: Expr, clauses: []const Clause) Error!Expr {
        return .{ .case_ = .{ .subject = try b.ptr(subject), .clauses = try b.arena.dupe(Clause, clauses) } };
    }

    /// `case S of P1 -> B1; … end` on one line.
    pub fn caseInline(b: Builder, subject: Expr, clauses: []const Clause) Error!Expr {
        return .{ .case_ = .{ .subject = try b.ptr(subject), .clauses = try b.arena.dupe(Clause, clauses), .layout = .inline_ } };
    }

    /// `(Fun)(Args)` — applying a parenthesized expression.
    pub fn applyParen(b: Builder, fun: Expr, args: []const Expr) Error!Expr {
        return .{ .apply = .{ .fun = try b.ptr(try b.paren(fun)), .args = try b.exprs(args) } };
    }

    /// A clause with an expression body; `.inline_` layout unless overridden.
    pub fn clause(b: Builder, patterns: []const Expr, guards: []const Expr, body_exprs: []const Expr) Error!Clause {
        return .{
            .patterns = try b.exprs(patterns),
            .guards = try b.exprs(guards),
            .body = try b.body(body_exprs),
            .layout = .inline_,
        };
    }

    /// Single-clause inline function form `name(Patterns) [when Guards] -> Body.`
    pub fn function(b: Builder, name: []const u8, patterns: []const Expr, guards: []const Expr, body_exprs: []const Expr) Error!Form {
        const clauses = try b.arena.alloc(Clause, 1);
        clauses[0] = try b.clause(patterns, guards, body_exprs);
        return .{ .function = .{ .name = name, .clauses = clauses } };
    }

    /// Multi-clause function form.
    pub fn functionClauses(b: Builder, name: []const u8, clauses: []const Clause) Error!Form {
        return .{ .function = .{ .name = name, .clauses = try b.arena.dupe(Clause, clauses) } };
    }
};

/// `<<"text">>` — a binary literal from raw bytes.
pub fn str(text: []const u8) Expr {
    return .{ .term = .{ .binary = text } };
}

/// Map entry keyed by an atom (`key => Value`, or `key := Value` when `exact`).
pub fn field(key: []const u8, value: Expr) MapField {
    return .{ .key = .{ .atom = key }, .value = value };
}

pub fn exactField(key: []const u8, value: Expr) MapField {
    return .{ .key = .{ .atom = key }, .value = value, .exact = true };
}
