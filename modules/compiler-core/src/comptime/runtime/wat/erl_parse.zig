//! The Erlang the comptime evaluators generate, read back as a tree.
//!
//! The wat runtime lowers **the same program the BEAM runtime compiles** — the
//! `.erl` text of the generated module and of the two resident preludes — so
//! the two runtimes cannot drift apart through two lowerings of the botopink
//! body. This file is the front half: a tokenizer and a recursive-descent
//! parser for the subset `codegen/beam/erl_emitter.zig` writes plus the host
//! templates of `libs/std/src/primitives.bp` (`raw` nodes): module attributes,
//! function clauses with guards, `case`/`if`/`try`/`begin`, `fun` (anonymous,
//! named, `fun F/A`, `fun M:F/A`), list comprehensions, maps and map updates,
//! binaries with segments, the operator table of the Erlang reference manual.
//! `receive`, records, macros and bit-syntax sizes other than literals are not
//! in the subset and are refused by name (`Error.Unsupported`, `failure`).
//!
//! Source text is UTF-8 and read as Erlang reads it: a string literal is its
//! code points (so `<<"é">>` is the one byte 233, as `erlc` compiles it).
const std = @import("std");

pub const Error = error{ OutOfMemory, Syntax, Unsupported };

// ── tree ─────────────────────────────────────────────────────────────────────

pub const Expr = union(enum) {
    variable: []const u8,
    atom: []const u8,
    int: i64,
    float: f64,
    /// A string literal: its code points (a char list).
    string: []const u21,
    binary: []const Segment,
    tuple: []const Expr,
    list: List,
    map: MapExpr,
    call: Call,
    fun_ref: FunRef,
    fun: Fun,
    binop: BinOp,
    unop: UnOp,
    match: Match,
    case_: Case,
    if_: []const Clause,
    try_: Try,
    block: []const Expr,
    list_comp: ListComp,

    pub const List = struct { items: []const Expr, tail: ?*const Expr = null };
    pub const MapExpr = struct { base: ?*const Expr = null, fields: []const Field };
    pub const Field = struct { key: Expr, value: Expr, exact: bool };
    /// `fun` is an atom (a local or remote call by name) or any other
    /// expression (applying a fun value).
    pub const Call = struct { module: ?*const Expr = null, fun: *const Expr, args: []const Expr };
    pub const FunRef = struct { module: ?[]const u8 = null, name: []const u8, arity: usize };
    pub const Fun = struct { name: ?[]const u8 = null, clauses: []const Clause };
    pub const BinOp = struct { op: []const u8, lhs: *const Expr, rhs: *const Expr };
    pub const UnOp = struct { op: []const u8, operand: *const Expr };
    pub const Match = struct { pattern: *const Expr, value: *const Expr };
    pub const Case = struct { subject: *const Expr, clauses: []const Clause };
    pub const Try = struct { body: []const Expr, of: []const Clause = &.{}, catches: []const Clause, after: []const Expr = &.{} };
    pub const ListComp = struct { element: *const Expr, qualifiers: []const Qualifier };
    /// `Pat <- List`, `<<Seg>> <= Bin` (a binary generator) or a filter.
    pub const Qualifier = union(enum) {
        generator: struct { pattern: Expr, list: Expr },
        bin_generator: struct { pattern: Expr, bin: Expr },
        filter: Expr,
    };
};

/// One element of `<<…>>`: the value, an optional size, and the type list
/// (`binary`, `utf8`, `integer`, …) — empty for the default (integer, 8 bits).
pub const Segment = struct {
    value: Expr,
    size: ?Expr = null,
    types: []const []const u8 = &.{},
};

/// A clause of a function, `case`, `if`, `fun` or `catch`. `patterns` has one
/// element for `case`/`catch` (a `catch` pattern is `Class:Reason[:Stack]`,
/// parsed as nested `:` binops), none for `if`. `guards` is a guard sequence:
/// alternatives joined by `;`, each a list of tests joined by `,`.
pub const Clause = struct {
    patterns: []const Expr,
    guards: []const []const Expr = &.{},
    body: []const Expr,
};

pub const Function = struct {
    name: []const u8,
    arity: usize,
    clauses: []const Clause,
};

pub const Import = struct { module: []const u8, name: []const u8, arity: usize };

pub const Module = struct {
    name: []const u8 = "",
    exports: []const Expr.FunRef = &.{},
    imports: []const Import = &.{},
    functions: []const Function = &.{},
};

// ── tokens ───────────────────────────────────────────────────────────────────

const Tok = union(enum) {
    atom: []const u8,
    variable: []const u8,
    int: i64,
    float: f64,
    string: []const u21,
    char: u21,
    punct: []const u8,
    keyword: []const u8,
    dot,
    eof,
};

const keywords = [_][]const u8{
    "after", "and",  "andalso", "band",  "begin", "bnot", "bor", "bsl", "bsr", "bxor",   "case",    "catch",
    "cond",  "div",  "end",     "fun",   "if",    "let",  "not", "of",  "or",  "orelse", "receive", "rem",
    "try",   "when", "xor",     "maybe", "else",
};

fn isKeyword(s: []const u8) bool {
    for (keywords) |k| if (std.mem.eql(u8, k, s)) return true;
    return false;
}

/// Longest first: the tokenizer tries these in order.
const puncts = [_][]const u8{
    "=:=", "=/=", "...", "<<", ">>", "->", "<-", "<=", "=>", ":=", "||", "++", "--", "==", "/=", "=<", ">=", "::",
    "(",   ")",   "[",   "]",  "{",  "}",  ",",  ";",  "|",  "#",  ":",  "=",  "+",  "-",  "*",  "/",  "<",  ">",
    "!",   "?",
};

const Lexer = struct {
    src: []const u8,
    i: usize = 0,
    arena: std.mem.Allocator,
    failure: *Failure,

    fn skip(l: *Lexer) void {
        while (l.i < l.src.len) {
            const c = l.src[l.i];
            if (c == '%') {
                while (l.i < l.src.len and l.src[l.i] != '\n') l.i += 1;
            } else if (std.ascii.isWhitespace(c)) {
                l.i += 1;
            } else break;
        }
    }

    fn fail(l: *Lexer, comptime fmt: []const u8, args: anytype) Error {
        l.failure.set(l.arena, l.src, l.i, fmt, args);
        return error.Syntax;
    }

    fn next(l: *Lexer) Error!Tok {
        l.skip();
        if (l.i >= l.src.len) return .eof;
        const c = l.src[l.i];
        if (c == '.' and (l.i + 1 >= l.src.len or std.ascii.isWhitespace(l.src[l.i + 1]) or l.src[l.i + 1] == '%')) {
            l.i += 1;
            return .dot;
        }
        if (std.ascii.isLower(c)) {
            const s = l.i;
            while (l.i < l.src.len and (std.ascii.isAlphanumeric(l.src[l.i]) or l.src[l.i] == '_' or l.src[l.i] == '@')) l.i += 1;
            const w = l.src[s..l.i];
            return if (isKeyword(w)) .{ .keyword = w } else .{ .atom = w };
        }
        if (std.ascii.isUpper(c) or c == '_') {
            const s = l.i;
            while (l.i < l.src.len and (std.ascii.isAlphanumeric(l.src[l.i]) or l.src[l.i] == '_' or l.src[l.i] == '@')) l.i += 1;
            return .{ .variable = l.src[s..l.i] };
        }
        if (std.ascii.isDigit(c)) return l.number();
        if (c == '\'') {
            l.i += 1;
            const cps = try l.quoted('\'');
            var out: std.ArrayListUnmanaged(u8) = .empty;
            for (cps) |cp| {
                var buf: [4]u8 = undefined;
                const n = std.unicode.utf8Encode(cp, &buf) catch return l.fail("bad code point in an atom", .{});
                try out.appendSlice(l.arena, buf[0..n]);
            }
            return .{ .atom = out.items };
        }
        if (c == '"') {
            l.i += 1;
            return .{ .string = try l.quoted('"') };
        }
        if (c == '$') {
            l.i += 1;
            if (l.i >= l.src.len) return l.fail("`$` at end of input", .{});
            if (l.src[l.i] == '\\') {
                l.i += 1;
                return .{ .char = try l.escape() };
            }
            return .{ .char = try l.codepoint() };
        }
        for (puncts) |p| {
            if (std.mem.startsWith(u8, l.src[l.i..], p)) {
                l.i += p.len;
                return .{ .punct = p };
            }
        }
        return l.fail("unexpected character `{c}`", .{c});
    }

    fn codepoint(l: *Lexer) Error!u21 {
        const len = std.unicode.utf8ByteSequenceLength(l.src[l.i]) catch return l.fail("invalid UTF-8", .{});
        if (l.i + len > l.src.len) return l.fail("invalid UTF-8", .{});
        const cp = std.unicode.utf8Decode(l.src[l.i..][0..len]) catch return l.fail("invalid UTF-8", .{});
        l.i += len;
        return cp;
    }

    fn escape(l: *Lexer) Error!u21 {
        if (l.i >= l.src.len) return l.fail("escape at end of input", .{});
        const e = l.src[l.i];
        l.i += 1;
        return switch (e) {
            'n' => '\n',
            'r' => '\r',
            't' => '\t',
            'v' => 11,
            'b' => 8,
            'f' => 12,
            'e' => 27,
            's' => ' ',
            'd' => 127,
            '0'...'7' => blk: {
                var v: u21 = e - '0';
                var k: usize = 0;
                while (k < 2 and l.i < l.src.len and l.src[l.i] >= '0' and l.src[l.i] <= '7') : (k += 1) {
                    v = v * 8 + (l.src[l.i] - '0');
                    l.i += 1;
                }
                break :blk v;
            },
            'x' => blk: {
                if (l.i < l.src.len and l.src[l.i] == '{') {
                    l.i += 1;
                    const s = l.i;
                    while (l.i < l.src.len and l.src[l.i] != '}') l.i += 1;
                    const v = std.fmt.parseInt(u21, l.src[s..l.i], 16) catch return l.fail("bad \\x{{…}} escape", .{});
                    l.i += 1;
                    break :blk v;
                }
                if (l.i + 2 > l.src.len) return l.fail("bad \\x escape", .{});
                const v = std.fmt.parseInt(u21, l.src[l.i..][0..2], 16) catch return l.fail("bad \\x escape", .{});
                l.i += 2;
                break :blk v;
            },
            '^' => blk: {
                if (l.i >= l.src.len) return l.fail("bad \\^ escape", .{});
                const ch = l.src[l.i];
                l.i += 1;
                break :blk ch & 31;
            },
            else => blk: {
                l.i -= 1;
                break :blk try l.codepoint();
            },
        };
    }

    fn quoted(l: *Lexer, q: u8) Error![]const u21 {
        var out: std.ArrayListUnmanaged(u21) = .empty;
        while (true) {
            if (l.i >= l.src.len) return l.fail("unterminated quote", .{});
            const c = l.src[l.i];
            if (c == q) {
                l.i += 1;
                return out.items;
            }
            if (c == '\\') {
                l.i += 1;
                try out.append(l.arena, try l.escape());
            } else try out.append(l.arena, try l.codepoint());
        }
    }

    fn number(l: *Lexer) Error!Tok {
        const s = l.i;
        while (l.i < l.src.len and (std.ascii.isDigit(l.src[l.i]) or l.src[l.i] == '_')) l.i += 1;
        if (l.i < l.src.len and l.src[l.i] == '#') {
            const base = std.fmt.parseInt(u8, l.src[s..l.i], 10) catch return l.fail("bad base", .{});
            l.i += 1;
            const d = l.i;
            while (l.i < l.src.len and (std.ascii.isAlphanumeric(l.src[l.i]) or l.src[l.i] == '_')) l.i += 1;
            const v = std.fmt.parseInt(i64, try strip(l.arena, l.src[d..l.i]), base) catch return l.fail("integer beyond 64 bits", .{});
            return .{ .int = v };
        }
        var is_float = false;
        if (l.i + 1 < l.src.len and l.src[l.i] == '.' and std.ascii.isDigit(l.src[l.i + 1])) {
            is_float = true;
            l.i += 1;
            while (l.i < l.src.len and (std.ascii.isDigit(l.src[l.i]) or l.src[l.i] == '_')) l.i += 1;
            if (l.i < l.src.len and (l.src[l.i] == 'e' or l.src[l.i] == 'E')) {
                l.i += 1;
                if (l.i < l.src.len and (l.src[l.i] == '-' or l.src[l.i] == '+')) l.i += 1;
                while (l.i < l.src.len and std.ascii.isDigit(l.src[l.i])) l.i += 1;
            }
        }
        const text = try strip(l.arena, l.src[s..l.i]);
        if (is_float) return .{ .float = std.fmt.parseFloat(f64, text) catch return l.fail("bad float", .{}) };
        return .{ .int = std.fmt.parseInt(i64, text, 10) catch return l.fail("integer beyond 64 bits", .{}) };
    }
};

fn strip(arena: std.mem.Allocator, s: []const u8) Error![]const u8 {
    if (std.mem.indexOfScalar(u8, s, '_') == null) return s;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (s) |c| if (c != '_') try out.append(arena, c);
    return out.items;
}

/// Where a parse stopped and why, for the refusal the evaluator reports.
pub const Failure = struct {
    message: []const u8 = "",
    line: usize = 0,

    fn set(f: *Failure, arena: std.mem.Allocator, src: []const u8, at: usize, comptime fmt: []const u8, args: anytype) void {
        var line: usize = 1;
        for (src[0..@min(at, src.len)]) |c| {
            if (c == '\n') line += 1;
        }
        f.line = line;
        f.message = std.fmt.allocPrint(arena, fmt, args) catch "out of memory";
    }
};

// ── parser ───────────────────────────────────────────────────────────────────

pub const Parser = struct {
    lx: Lexer,
    tok: Tok = .eof,
    arena: std.mem.Allocator,

    pub fn init(arena: std.mem.Allocator, src: []const u8, failure: *Failure) Error!Parser {
        var p: Parser = .{ .lx = .{ .src = src, .arena = arena, .failure = failure }, .arena = arena };
        p.tok = try p.lx.next();
        return p;
    }

    fn advance(p: *Parser) Error!void {
        p.tok = try p.lx.next();
    }

    fn fail(p: *Parser, comptime fmt: []const u8, args: anytype) Error {
        return p.lx.fail(fmt, args);
    }

    fn unsupported(p: *Parser, comptime fmt: []const u8, args: anytype) Error {
        p.lx.failure.set(p.arena, p.lx.src, p.lx.i, fmt, args);
        return error.Unsupported;
    }

    fn isPunct(p: *Parser, s: []const u8) bool {
        return switch (p.tok) {
            .punct => |x| std.mem.eql(u8, x, s),
            else => false,
        };
    }

    fn isKw(p: *Parser, s: []const u8) bool {
        return switch (p.tok) {
            .keyword => |x| std.mem.eql(u8, x, s),
            else => false,
        };
    }

    fn expectPunct(p: *Parser, s: []const u8) Error!void {
        if (!p.isPunct(s)) return p.fail("expected `{s}`", .{s});
        try p.advance();
    }

    fn expectKw(p: *Parser, s: []const u8) Error!void {
        if (!p.isKw(s)) return p.fail("expected `{s}`", .{s});
        try p.advance();
    }

    fn box(p: *Parser, e: Expr) Error!*const Expr {
        const b = try p.arena.create(Expr);
        b.* = e;
        return b;
    }

    // ── module ───────────────────────────────────────────────────────────

    pub fn module(p: *Parser) Error!Module {
        var m: Module = .{};
        var exports: std.ArrayListUnmanaged(Expr.FunRef) = .empty;
        var imports: std.ArrayListUnmanaged(Import) = .empty;
        var functions: std.ArrayListUnmanaged(Function) = .empty;
        while (p.tok != .eof) {
            if (p.isPunct("-")) {
                try p.advance();
                const attr = switch (p.tok) {
                    .atom => |a| a,
                    else => return p.fail("expected an attribute name", .{}),
                };
                try p.advance();
                try p.expectPunct("(");
                if (std.mem.eql(u8, attr, "module")) {
                    m.name = try p.atomName();
                } else if (std.mem.eql(u8, attr, "export")) {
                    try p.funRefList(&exports, null);
                } else if (std.mem.eql(u8, attr, "import")) {
                    const mod = try p.atomName();
                    try p.expectPunct(",");
                    var refs: std.ArrayListUnmanaged(Expr.FunRef) = .empty;
                    try p.funRefList(&refs, null);
                    for (refs.items) |r| try imports.append(p.arena, .{ .module = mod, .name = r.name, .arity = r.arity });
                } else {
                    // `-compile(…)`, `-file(…)`: nothing the lowering reads.
                    var depth: usize = 1;
                    while (depth > 0) {
                        if (p.tok == .eof) return p.fail("unterminated attribute", .{});
                        if (p.isPunct("(")) depth += 1;
                        if (p.isPunct(")")) depth -= 1;
                        if (depth > 0) try p.advance();
                    }
                }
                try p.expectPunct(")");
                if (p.tok != .dot) return p.fail("expected `.` after an attribute", .{});
                try p.advance();
                continue;
            }
            const f = try p.function();
            // Consecutive clauses of one function are already joined by `;`;
            // a second definition of the same name/arity is a new function in
            // Erlang's eyes too (and erlc would refuse it).
            try functions.append(p.arena, f);
        }
        m.exports = exports.items;
        m.imports = imports.items;
        m.functions = functions.items;
        return m;
    }

    fn atomName(p: *Parser) Error![]const u8 {
        const a = switch (p.tok) {
            .atom => |a| a,
            else => return p.fail("expected an atom", .{}),
        };
        try p.advance();
        return a;
    }

    fn funRefList(p: *Parser, out: *std.ArrayListUnmanaged(Expr.FunRef), _: ?void) Error!void {
        try p.expectPunct("[");
        while (!p.isPunct("]")) {
            const name = try p.atomName();
            try p.expectPunct("/");
            const arity = switch (p.tok) {
                .int => |n| n,
                else => return p.fail("expected an arity", .{}),
            };
            try p.advance();
            try out.append(p.arena, .{ .name = name, .arity = @intCast(arity) });
            if (p.isPunct(",")) try p.advance();
        }
        try p.advance();
    }

    fn function(p: *Parser) Error!Function {
        const name = try p.atomName();
        var clauses: std.ArrayListUnmanaged(Clause) = .empty;
        var arity: usize = 0;
        while (true) {
            const cl = try p.clauseAfterName();
            arity = cl.patterns.len;
            try clauses.append(p.arena, cl);
            if (p.isPunct(";")) {
                try p.advance();
                const again = try p.atomName();
                if (!std.mem.eql(u8, again, name)) return p.fail("clause of `{s}` inside `{s}`", .{ again, name });
                continue;
            }
            if (p.tok != .dot) return p.fail("expected `.` or `;` after a function clause", .{});
            try p.advance();
            break;
        }
        return .{ .name = name, .arity = arity, .clauses = clauses.items };
    }

    /// `(Patterns) [when Guards] -> Body` — the head of a function or `fun`
    /// clause, after its name.
    fn clauseAfterName(p: *Parser) Error!Clause {
        try p.expectPunct("(");
        var pats: std.ArrayListUnmanaged(Expr) = .empty;
        while (!p.isPunct(")")) {
            try pats.append(p.arena, try p.expr());
            if (p.isPunct(",")) try p.advance() else break;
        }
        try p.expectPunct(")");
        const guards = try p.guardSeq();
        try p.expectPunct("->");
        return .{ .patterns = pats.items, .guards = guards, .body = try p.body() };
    }

    fn guardSeq(p: *Parser) Error![]const []const Expr {
        if (!p.isKw("when")) return &.{};
        try p.advance();
        var alts: std.ArrayListUnmanaged([]const Expr) = .empty;
        while (true) {
            var tests: std.ArrayListUnmanaged(Expr) = .empty;
            while (true) {
                try tests.append(p.arena, try p.expr());
                if (p.isPunct(",")) try p.advance() else break;
            }
            try alts.append(p.arena, tests.items);
            if (p.isPunct(";")) try p.advance() else break;
        }
        return alts.items;
    }

    /// Expressions separated by `,`.
    fn body(p: *Parser) Error![]const Expr {
        var out: std.ArrayListUnmanaged(Expr) = .empty;
        while (true) {
            try out.append(p.arena, try p.expr());
            if (p.isPunct(",")) try p.advance() else break;
        }
        return out.items;
    }

    // ── expressions (precedence climbing) ────────────────────────────────

    pub fn expr(p: *Parser) Error!Expr {
        if (p.isKw("catch")) return p.unsupported("`catch Expr` (the old-style catch)", .{});
        return p.matchExpr();
    }

    fn matchExpr(p: *Parser) Error!Expr {
        const lhs = try p.orelseExpr();
        if (p.isPunct("=")) {
            try p.advance();
            const rhs = try p.matchExpr();
            return .{ .match = .{ .pattern = try p.box(lhs), .value = try p.box(rhs) } };
        }
        if (p.isPunct("!")) return p.unsupported("message send `!`", .{});
        return lhs;
    }

    fn orelseExpr(p: *Parser) Error!Expr {
        const lhs = try p.andalsoExpr();
        if (p.isKw("orelse")) {
            try p.advance();
            const rhs = try p.orelseExpr();
            return .{ .binop = .{ .op = "orelse", .lhs = try p.box(lhs), .rhs = try p.box(rhs) } };
        }
        return lhs;
    }

    fn andalsoExpr(p: *Parser) Error!Expr {
        const lhs = try p.compExpr();
        if (p.isKw("andalso")) {
            try p.advance();
            const rhs = try p.andalsoExpr();
            return .{ .binop = .{ .op = "andalso", .lhs = try p.box(lhs), .rhs = try p.box(rhs) } };
        }
        return lhs;
    }

    fn compOp(p: *Parser) ?[]const u8 {
        for ([_][]const u8{ "==", "/=", "=<", "<", ">=", ">", "=:=", "=/=" }) |op| {
            if (p.isPunct(op)) return op;
        }
        return null;
    }

    fn compExpr(p: *Parser) Error!Expr {
        const lhs = try p.listOpExpr();
        if (p.compOp()) |op| {
            try p.advance();
            const rhs = try p.listOpExpr();
            return .{ .binop = .{ .op = op, .lhs = try p.box(lhs), .rhs = try p.box(rhs) } };
        }
        return lhs;
    }

    fn listOpExpr(p: *Parser) Error!Expr {
        const lhs = try p.addExpr();
        if (p.isPunct("++") or p.isPunct("--")) {
            const op = p.tok.punct;
            try p.advance();
            const rhs = try p.listOpExpr();
            return .{ .binop = .{ .op = op, .lhs = try p.box(lhs), .rhs = try p.box(rhs) } };
        }
        return lhs;
    }

    fn addOp(p: *Parser) ?[]const u8 {
        if (p.isPunct("+")) return "+";
        if (p.isPunct("-")) return "-";
        for ([_][]const u8{ "bor", "bxor", "bsl", "bsr", "or", "xor" }) |k| if (p.isKw(k)) return k;
        return null;
    }

    fn addExpr(p: *Parser) Error!Expr {
        var lhs = try p.mulExpr();
        while (p.addOp()) |op| {
            try p.advance();
            const rhs = try p.mulExpr();
            const l = try p.box(lhs);
            const r = try p.box(rhs);
            lhs = .{ .binop = .{ .op = op, .lhs = l, .rhs = r } };
        }
        return lhs;
    }

    fn mulOp(p: *Parser) ?[]const u8 {
        if (p.isPunct("*")) return "*";
        if (p.isPunct("/")) return "/";
        for ([_][]const u8{ "div", "rem", "band", "and" }) |k| if (p.isKw(k)) return k;
        return null;
    }

    fn mulExpr(p: *Parser) Error!Expr {
        var lhs = try p.unaryExpr();
        while (p.mulOp()) |op| {
            try p.advance();
            const rhs = try p.unaryExpr();
            const l = try p.box(lhs);
            const r = try p.box(rhs);
            lhs = .{ .binop = .{ .op = op, .lhs = l, .rhs = r } };
        }
        return lhs;
    }

    fn unaryExpr(p: *Parser) Error!Expr {
        if (p.isPunct("-") or p.isPunct("+") or p.isKw("not") or p.isKw("bnot")) {
            const op: []const u8 = switch (p.tok) {
                .punct => |x| x,
                .keyword => |x| x,
                else => unreachable,
            };
            try p.advance();
            const operand = try p.unaryExpr();
            // A negative literal is the literal (patterns match `-1`).
            if (std.mem.eql(u8, op, "-")) switch (operand) {
                .int => |n| return .{ .int = -n },
                .float => |f| return .{ .float = -f },
                else => {},
            };
            if (std.mem.eql(u8, op, "+")) return operand;
            return .{ .unop = .{ .op = op, .operand = try p.box(operand) } };
        }
        return p.postfixExpr();
    }

    fn postfixExpr(p: *Parser) Error!Expr {
        var e = try p.primary();
        while (true) {
            if (p.isPunct("#")) {
                // `Map#{…}`
                try p.advance();
                if (!p.isPunct("{")) return p.unsupported("records (`#name{{…}}`)", .{});
                const fields = try p.mapFields();
                const base = try p.box(e);
                e = .{ .map = .{ .base = base, .fields = fields } };
            } else if (p.isPunct(":")) {
                // `M:F(Args)` — `:` binds tighter than a call
                try p.advance();
                const f = try p.primary();
                const lhs = try p.box(e);
                const rhs = try p.box(f);
                if (!p.isPunct("(")) {
                    // `Class:Reason` in a catch pattern
                    e = .{ .binop = .{ .op = ":", .lhs = lhs, .rhs = rhs } };
                    continue;
                }
                const call_args = try p.callArgs();
                e = .{ .call = .{ .module = lhs, .fun = rhs, .args = call_args } };
            } else if (p.isPunct("(")) {
                const fun = try p.box(e);
                const call_args = try p.callArgs();
                e = .{ .call = .{ .fun = fun, .args = call_args } };
            } else break;
        }
        return e;
    }

    fn callArgs(p: *Parser) Error![]const Expr {
        try p.expectPunct("(");
        var out: std.ArrayListUnmanaged(Expr) = .empty;
        while (!p.isPunct(")")) {
            try out.append(p.arena, try p.expr());
            if (p.isPunct(",")) try p.advance() else break;
        }
        try p.expectPunct(")");
        return out.items;
    }

    fn mapFields(p: *Parser) Error![]const Expr.Field {
        try p.expectPunct("{");
        var out: std.ArrayListUnmanaged(Expr.Field) = .empty;
        while (!p.isPunct("}")) {
            const k = try p.expr();
            const exact = if (p.isPunct(":=")) true else if (p.isPunct("=>")) false else return p.fail("expected `=>` or `:=`", .{});
            try p.advance();
            const v = try p.expr();
            try out.append(p.arena, .{ .key = k, .value = v, .exact = exact });
            if (p.isPunct(",")) try p.advance() else break;
        }
        try p.expectPunct("}");
        return out.items;
    }

    fn primary(p: *Parser) Error!Expr {
        switch (p.tok) {
            .variable => |v| {
                try p.advance();
                return .{ .variable = v };
            },
            .atom => |a| {
                try p.advance();
                return .{ .atom = a };
            },
            .int => |n| {
                try p.advance();
                return .{ .int = n };
            },
            .float => |f| {
                try p.advance();
                return .{ .float = f };
            },
            .char => |c| {
                try p.advance();
                return .{ .int = c };
            },
            .string => |s| {
                try p.advance();
                // Adjacent string literals concatenate.
                var acc: std.ArrayListUnmanaged(u21) = .empty;
                try acc.appendSlice(p.arena, s);
                while (p.tok == .string) {
                    try acc.appendSlice(p.arena, p.tok.string);
                    try p.advance();
                }
                return .{ .string = acc.items };
            },
            .punct => |x| {
                if (std.mem.eql(u8, x, "(")) {
                    try p.advance();
                    const e = try p.expr();
                    try p.expectPunct(")");
                    return e;
                }
                if (std.mem.eql(u8, x, "{")) {
                    try p.advance();
                    var items: std.ArrayListUnmanaged(Expr) = .empty;
                    while (!p.isPunct("}")) {
                        try items.append(p.arena, try p.expr());
                        if (p.isPunct(",")) try p.advance() else break;
                    }
                    try p.expectPunct("}");
                    return .{ .tuple = items.items };
                }
                if (std.mem.eql(u8, x, "[")) return p.listOrComp();
                if (std.mem.eql(u8, x, "#")) {
                    try p.advance();
                    if (!p.isPunct("{")) return p.unsupported("records (`#name{{…}}`)", .{});
                    return .{ .map = .{ .fields = try p.mapFields() } };
                }
                if (std.mem.eql(u8, x, "<<")) return p.binary();
                if (std.mem.eql(u8, x, "?")) return p.unsupported("macros (`?NAME`)", .{});
                return p.fail("unexpected `{s}`", .{x});
            },
            .keyword => |k| {
                if (std.mem.eql(u8, k, "case")) return p.caseExpr();
                if (std.mem.eql(u8, k, "if")) return p.ifExpr();
                if (std.mem.eql(u8, k, "fun")) return p.funExpr();
                if (std.mem.eql(u8, k, "try")) return p.tryExpr();
                if (std.mem.eql(u8, k, "begin")) {
                    try p.advance();
                    const b = try p.body();
                    try p.expectKw("end");
                    return .{ .block = b };
                }
                if (std.mem.eql(u8, k, "receive")) return p.unsupported("`receive`", .{});
                if (std.mem.eql(u8, k, "maybe")) return p.unsupported("`maybe`", .{});
                return p.fail("unexpected `{s}`", .{k});
            },
            .dot => return p.fail("unexpected `.`", .{}),
            .eof => return p.fail("unexpected end of input", .{}),
        }
    }

    fn listOrComp(p: *Parser) Error!Expr {
        try p.expectPunct("[");
        if (p.isPunct("]")) {
            try p.advance();
            return .{ .list = .{ .items = &.{} } };
        }
        const first = try p.expr();
        if (p.isPunct("||")) {
            try p.advance();
            var quals: std.ArrayListUnmanaged(Expr.Qualifier) = .empty;
            while (true) {
                const q = try p.expr();
                if (p.isPunct("<-")) {
                    try p.advance();
                    const l = try p.expr();
                    try quals.append(p.arena, .{ .generator = .{ .pattern = q, .list = l } });
                } else if (p.isPunct("<=")) {
                    try p.advance();
                    const b = try p.expr();
                    try quals.append(p.arena, .{ .bin_generator = .{ .pattern = q, .bin = b } });
                } else try quals.append(p.arena, .{ .filter = q });
                if (p.isPunct(",")) try p.advance() else break;
            }
            try p.expectPunct("]");
            return .{ .list_comp = .{ .element = try p.box(first), .qualifiers = quals.items } };
        }
        var items: std.ArrayListUnmanaged(Expr) = .empty;
        try items.append(p.arena, first);
        while (p.isPunct(",")) {
            try p.advance();
            try items.append(p.arena, try p.expr());
        }
        var tail: ?*const Expr = null;
        if (p.isPunct("|")) {
            try p.advance();
            tail = try p.box(try p.expr());
        }
        try p.expectPunct("]");
        return .{ .list = .{ .items = items.items, .tail = tail } };
    }

    fn binary(p: *Parser) Error!Expr {
        try p.expectPunct("<<");
        var segs: std.ArrayListUnmanaged(Segment) = .empty;
        while (!p.isPunct(">>")) {
            // A segment value is a primary expression (no binary operators
            // without parentheses, as in Erlang).
            const v = try p.segmentValue();
            var seg: Segment = .{ .value = v };
            if (p.isPunct(":")) {
                try p.advance();
                seg.size = try p.segmentValue();
            }
            if (p.isPunct("/")) {
                try p.advance();
                var types: std.ArrayListUnmanaged([]const u8) = .empty;
                while (true) {
                    const t = switch (p.tok) {
                        .atom => |a| a,
                        else => return p.fail("expected a segment type", .{}),
                    };
                    try p.advance();
                    try types.append(p.arena, t);
                    if (p.isPunct("-")) try p.advance() else break;
                }
                seg.types = types.items;
            }
            try segs.append(p.arena, seg);
            if (p.isPunct(",")) try p.advance() else break;
        }
        try p.expectPunct(">>");
        return .{ .binary = segs.items };
    }

    fn segmentValue(p: *Parser) Error!Expr {
        if (p.isPunct("-")) {
            try p.advance();
            return switch (try p.primary()) {
                .int => |n| .{ .int = -n },
                .float => |f| .{ .float = -f },
                else => |e| .{ .unop = .{ .op = "-", .operand = try p.box(e) } },
            };
        }
        return p.primary();
    }

    fn clauseList(p: *Parser, comptime with_pattern: bool) Error![]const Clause {
        var out: std.ArrayListUnmanaged(Clause) = .empty;
        while (true) {
            var pats: []const Expr = &.{};
            if (with_pattern) pats = try p.arena.dupe(Expr, &.{try p.expr()});
            const guards = try p.guardSeq();
            try p.expectPunct("->");
            try out.append(p.arena, .{ .patterns = pats, .guards = guards, .body = try p.body() });
            if (p.isPunct(";")) try p.advance() else break;
        }
        return out.items;
    }

    fn caseExpr(p: *Parser) Error!Expr {
        try p.expectKw("case");
        const subject = try p.expr();
        try p.expectKw("of");
        const cls = try p.clauseList(true);
        try p.expectKw("end");
        return .{ .case_ = .{ .subject = try p.box(subject), .clauses = cls } };
    }

    fn ifExpr(p: *Parser) Error!Expr {
        try p.expectKw("if");
        var out: std.ArrayListUnmanaged(Clause) = .empty;
        while (true) {
            var alts: std.ArrayListUnmanaged([]const Expr) = .empty;
            while (true) {
                var tests: std.ArrayListUnmanaged(Expr) = .empty;
                while (true) {
                    try tests.append(p.arena, try p.expr());
                    if (p.isPunct(",")) try p.advance() else break;
                }
                try alts.append(p.arena, tests.items);
                if (p.isPunct(";")) try p.advance() else break;
            }
            try p.expectPunct("->");
            try out.append(p.arena, .{ .patterns = &.{}, .guards = alts.items, .body = try p.body() });
            if (p.isPunct(";")) try p.advance() else break;
        }
        try p.expectKw("end");
        return .{ .if_ = out.items };
    }

    fn funExpr(p: *Parser) Error!Expr {
        try p.expectKw("fun");
        // `fun name/Arity`, `fun mod:name/Arity`
        switch (p.tok) {
            .atom => |a| {
                try p.advance();
                var module_name: ?[]const u8 = null;
                var name = a;
                if (p.isPunct(":")) {
                    try p.advance();
                    module_name = a;
                    name = try p.atomName();
                }
                try p.expectPunct("/");
                const arity = switch (p.tok) {
                    .int => |n| n,
                    else => return p.fail("expected an arity", .{}),
                };
                try p.advance();
                return .{ .fun_ref = .{ .module = module_name, .name = name, .arity = @intCast(arity) } };
            },
            else => {},
        }
        var name: ?[]const u8 = null;
        if (p.tok == .variable) {
            name = p.tok.variable;
            try p.advance();
        }
        var out: std.ArrayListUnmanaged(Clause) = .empty;
        while (true) {
            try out.append(p.arena, try p.clauseAfterName());
            if (p.isPunct(";")) {
                try p.advance();
                if (name) |n| {
                    if (p.tok != .variable or !std.mem.eql(u8, p.tok.variable, n)) return p.fail("named fun clause without its name", .{});
                    try p.advance();
                }
            } else break;
        }
        try p.expectKw("end");
        return .{ .fun = .{ .name = name, .clauses = out.items } };
    }

    fn tryExpr(p: *Parser) Error!Expr {
        try p.expectKw("try");
        const b = try p.body();
        var of: []const Clause = &.{};
        if (p.isKw("of")) {
            try p.advance();
            of = try p.clauseList(true);
        }
        var catches: []const Clause = &.{};
        if (p.isKw("catch")) {
            try p.advance();
            catches = try p.clauseList(true);
        }
        var after: []const Expr = &.{};
        if (p.isKw("after")) {
            try p.advance();
            after = try p.body();
        }
        try p.expectKw("end");
        return .{ .try_ = .{ .body = b, .of = of, .catches = catches, .after = after } };
    }
};

/// Parse a whole module.
pub fn parseModule(arena: std.mem.Allocator, src: []const u8, failure: *Failure) Error!Module {
    var p = try Parser.init(arena, src, failure);
    return p.module();
}

// ── tests ────────────────────────────────────────────────────────────────────

test "a generated comptime module parses: attributes, clauses, guards, funs, try" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const src =
        \\-module(bp@comptime__tpl__six__a524da87efe1379c).
        \\-export([main/1, six/1]).
        \\-import(bp_comptime_template, [text/1, expr/1, '__bp_add'/2]).
        \\
        \\six(T) ->
        \\    N = '__bp_add'(2, 4),
        \\    Xs = [X * 2 || X <- [1, 2, 3], X > 1],
        \\    F = fun __F(0) -> done; __F(I) -> __F(I - 1) end,
        \\    M = #{kind => <<"code">>, <<"$tuple">> => [1 | Xs]},
        \\    M2 = M#{kind := x},
        \\    B = <<"a", (text(T))/binary, 255, $é/utf8>>,
        \\    %% a comment in expression position
        \\    case maps:get(kind, M2) of
        \\        x when is_atom(x), not false; true -> expr(N);
        \\        _ -> if N > 3 -> {N, F, B}; true -> fun erlang:is_binary/1 end
        \\    end.
        \\
        \\main({Arg0}) ->
        \\    try
        \\        json:encode(six(Arg0))
        \\    catch
        \\        throw:{'__bp_template_fail', Message, Param, Span} -> Message;
        \\        Class:Reason -> {Class, Reason}
        \\    end.
    ;
    var failure: Failure = .{};
    const m = try parseModule(arena, src, &failure);
    try std.testing.expectEqualStrings("bp@comptime__tpl__six__a524da87efe1379c", m.name);
    try std.testing.expectEqual(@as(usize, 2), m.exports.len);
    try std.testing.expectEqual(@as(usize, 3), m.imports.len);
    try std.testing.expectEqualStrings("__bp_add", m.imports[2].name);
    try std.testing.expectEqual(@as(usize, 2), m.functions.len);
    try std.testing.expectEqual(@as(usize, 1), m.functions[1].arity);
    const body = m.functions[0].clauses[0].body;
    try std.testing.expectEqual(@as(usize, 7), body.len);
    // `<<"a", …>>`: the string segment, the call segment, 255, the utf8 char.
    const bin = body[5].match.value.binary;
    try std.testing.expectEqual(@as(usize, 4), bin.len);
    try std.testing.expectEqual(@as(i64, 0xE9), bin[3].value.int);
    try std.testing.expectEqualStrings("utf8", bin[3].types[0]);
    // The catch clause pattern is `Class:Reason` — a `:` binop.
    const tr = m.functions[1].clauses[0].body[0].try_;
    try std.testing.expectEqualStrings(":", tr.catches[1].patterns[0].binop.op);
}

test "a construct outside the subset is refused by name" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    var failure: Failure = .{};
    try std.testing.expectError(error.Unsupported, parseModule(arena_state.allocator(), "f() -> receive X -> X end.", &failure));
    try std.testing.expect(std.mem.indexOf(u8, failure.message, "receive") != null);
}
