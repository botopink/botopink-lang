//! Erlang abstract syntax — the code model `erl_emitter.zig` renders.
//!
//! `term.zig` models *values*; this file models *code*: expressions, clauses,
//! function definitions and module forms. The Erlang backend and the comptime
//! evaluators build these nodes and let `erl_emitter` produce the text, so the
//! Erlang layout rules (indentation, clause separators, `end`) live in one place.
//!
//! Layout is part of the model where the backend's output depends on it: a
//! clause body is either a block (`Pat ->` + indented statements) or inline
//! (`Pat -> Expr`). A `raw` node embeds already-rendered Erlang text; it is the
//! bridge for code not yet expressed as nodes and is written verbatim.
//!
//! Nodes borrow their slices: build them in an arena that outlives rendering.

const std = @import("std");
const Term = @import("term.zig").Term;

pub const Expr = union(enum) {
    /// Rendered Erlang, written verbatim (multi-line text carries its own
    /// indentation).
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
    /// `Class:Reason` / `Class:Reason:Stack` — a `catch` clause pattern.
    exception: Exception,

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
};

pub const Fun = struct {
    params: []const Expr,
    body: Body,
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

/// A sequence of statements, or pre-rendered statement lines.
pub const Body = union(enum) {
    stmts: []const Stmt,
    /// Already-indented statement lines (no trailing newline).
    raw_block: []const u8,

    pub fn of(stmts: []const Stmt) Body {
        return .{ .stmts = stmts };
    }
};

pub const Stmt = union(enum) {
    expr: Expr,
    /// `% text` / `%% text` — never takes a `,` separator.
    comment: []const u8,
};

/// `name(P1, P2) -> Body.` with one or more clauses.
pub const Function = struct {
    name: []const u8,
    clauses: []const Clause,
};

pub const Form = union(enum) {
    /// `-name(Value).` with the value already rendered (`-module(m).`,
    /// `-export([f/0]).`).
    attribute: struct { name: []const u8, value: []const u8 },
    function: Function,
    comment: []const u8,
    /// Rendered form text, written verbatim.
    raw: []const u8,
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

    pub fn caseOf(b: Builder, subject: Expr, clauses: []const Clause) Error!Expr {
        return .{ .case_ = .{ .subject = try b.ptr(subject), .clauses = try b.arena.dupe(Clause, clauses) } };
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
