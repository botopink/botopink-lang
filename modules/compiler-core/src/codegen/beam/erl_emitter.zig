//! Erlang source emitter for BEAM terms and names.
//!
//! Owns the lexical rules every BEAM-family emitter shares: when an atom needs
//! quoting, how a botopink name becomes an Erlang variable, and how strings
//! become binaries. `codegen/erlang.zig` uses it for names/literals, the
//! comptime evaluators for whole values (`Term`), and `beam_emitter.zig` for the
//! term syntax inside `{literal, …}` (identical in `.erl` and `.S`).

const std = @import("std");
const Term = @import("term.zig").Term;
const Ast = @import("erl_ast.zig");

const Writer = std.Io.Writer;

pub const Error = Writer.Error || error{NonFiniteFloat};

// ── names ────────────────────────────────────────────────────────────────────

/// Erlang reserved words. An identifier that collides with one (a fn named `of`,
/// an HTML builder `div`, a record field `end`) is lexically a valid bare atom
/// yet the parser rejects it — it must be single-quoted (`'of'`).
const reserved = std.StaticStringMap(void).initComptime(.{
    .{"after"}, .{"and"}, .{"andalso"}, .{"band"}, .{"begin"},  .{"bnot"},
    .{"bor"},   .{"bsl"}, .{"bsr"},     .{"bxor"}, .{"case"},   .{"catch"},
    .{"cond"},  .{"div"}, .{"end"},     .{"fun"},  .{"if"},     .{"let"},
    .{"maybe"}, .{"not"}, .{"of"},      .{"or"},   .{"orelse"}, .{"receive"},
    .{"rem"},   .{"try"}, .{"when"},    .{"xor"},
});

pub fn isReserved(name: []const u8) bool {
    return reserved.has(name);
}

/// True when `name` can be written as a bare atom: a lowercase letter followed
/// by letters, digits, `_` or `@`, and not a reserved word.
pub fn isUnquotedAtom(name: []const u8) bool {
    if (name.len == 0) return false;
    if (!(name[0] >= 'a' and name[0] <= 'z')) return false;
    for (name[1..]) |c| {
        if (!(std.ascii.isAlphanumeric(c) or c == '_' or c == '@')) return false;
    }
    return !isReserved(name);
}

/// Length of the quoted form of `name`: quotes plus one `\` per `'`/`\`.
fn quotedLen(name: []const u8) usize {
    var n = name.len + 2;
    for (name) |c| {
        if (c == '\'' or c == '\\') n += 1;
    }
    return n;
}

/// Render `name` as atom text into `buf`: bare when valid, otherwise
/// single-quoted with `'`/`\` escaped (`error.NoSpaceLeft` when `buf` cannot
/// hold it). A name that already starts with `'` is pre-quoted (a mangled
/// `'Owner_method'`) and is returned unchanged.
pub fn atomText(name: []const u8, buf: []u8) error{NoSpaceLeft}![]const u8 {
    if (name.len > 0 and name[0] == '\'') return name;
    if (isUnquotedAtom(name)) return name;
    if (buf.len < quotedLen(name)) return error.NoSpaceLeft;
    var i: usize = 0;
    buf[i] = '\'';
    i += 1;
    for (name) |c| {
        if (c == '\'' or c == '\\') {
            buf[i] = '\\';
            i += 1;
        }
        buf[i] = c;
        i += 1;
    }
    buf[i] = '\'';
    i += 1;
    return buf[0..i];
}

pub fn writeAtom(w: *Writer, name: []const u8) Writer.Error!void {
    if ((name.len > 0 and name[0] == '\'') or isUnquotedAtom(name)) return w.writeAll(name);
    try w.writeByte('\'');
    for (name) |c| {
        if (c == '\'' or c == '\\') try w.writeByte('\\');
        try w.writeByte(c);
    }
    try w.writeByte('\'');
}

/// `{f}` formatter for an atom inside a format string:
/// `w.print("{{atom, {f}}}", .{erl_emitter.atom(name)})`.
pub fn atom(name: []const u8) AtomFormatter {
    return .{ .name = name };
}

pub const AtomFormatter = struct {
    name: []const u8,

    pub fn format(self: AtomFormatter, w: *Writer) Writer.Error!void {
        return writeAtom(w, self.name);
    }
};

/// Erlang variable for a botopink name: first byte uppercased (`decl` → `Decl`).
pub fn writeVar(w: *Writer, name: []const u8) Writer.Error!void {
    if (name.len == 0) return;
    try w.writeByte(std.ascii.toUpper(name[0]));
    try w.writeAll(name[1..]);
}

/// Heap-allocated variable name (see `writeVar`). Caller owns the result.
pub fn varName(alloc: std.mem.Allocator, name: []const u8) std.mem.Allocator.Error![]u8 {
    const buf = try alloc.dupe(u8, name);
    if (buf.len > 0) buf[0] = std.ascii.toUpper(buf[0]);
    return buf;
}

/// Heap-allocated module atom for a type-like name: first byte lowercased
/// (`List` → `list`). Inverse of `varName`. Caller owns the result.
pub fn moduleName(alloc: std.mem.Allocator, name: []const u8) std.mem.Allocator.Error![]u8 {
    const buf = try alloc.dupe(u8, name);
    if (buf.len > 0) buf[0] = std.ascii.toLower(buf[0]);
    return buf;
}

// ── binaries ─────────────────────────────────────────────────────────────────

/// `<<"…">>` from raw runtime bytes. Quote, backslash and control bytes are
/// escaped; bytes >= 0x80 are written as `\x{HH}` so the binary holds exactly
/// these bytes regardless of the source file encoding.
pub fn writeBinaryFromBytes(w: *Writer, bytes: []const u8) Writer.Error!void {
    try w.writeAll("<<\"");
    try writeEscaped(w, bytes);
    try w.writeAll("\">>");
}

/// `"…"` — an Erlang string literal (character list) from raw bytes, escaped
/// like `writeBinaryFromBytes`.
pub fn writeString(w: *Writer, bytes: []const u8) Writer.Error!void {
    try w.writeByte('"');
    try writeEscaped(w, bytes);
    try w.writeByte('"');
}

fn writeEscaped(w: *Writer, bytes: []const u8) Writer.Error!void {
    for (bytes) |c| switch (c) {
        '"' => try w.writeAll("\\\""),
        '\\' => try w.writeAll("\\\\"),
        '\n' => try w.writeAll("\\n"),
        '\r' => try w.writeAll("\\r"),
        '\t' => try w.writeAll("\\t"),
        0...8, 11, 12, 14...31, 127...255 => try w.print("\\x{{{X:0>2}}}", .{c}),
        else => try w.writeByte(c),
    };
}

/// `<<"…">>` from a botopink string literal's lexeme content. The lexer keeps
/// escape sequences verbatim; botopink's map 1:1 onto Erlang's for the common
/// set (`\n \r \t \0 \\ \"`), `\$` becomes `$`, and `\u{…}` becomes `\x{…}`.
/// Raw bytes pass through unchanged.
pub fn writeBinaryFromLexeme(w: *Writer, s: []const u8) Writer.Error!void {
    try w.writeAll("<<\"");
    var i: usize = 0;
    while (i < s.len) {
        const c = s[i];
        if (c == '\\' and i + 1 < s.len) {
            const esc = s[i + 1];
            switch (esc) {
                'n', 'r', 't', '0', '\\', '"' => {
                    try w.writeByte('\\');
                    try w.writeByte(esc);
                    i += 2;
                },
                '$' => {
                    try w.writeByte('$');
                    i += 2;
                },
                'u' => {
                    try w.writeAll("\\x{");
                    i += 3; // skip `\u{`
                    while (i < s.len and s[i] != '}') : (i += 1) {
                        try w.writeByte(s[i]);
                    }
                    if (i < s.len) i += 1; // skip `}`
                    try w.writeByte('}');
                },
                else => {
                    try w.writeByte(c);
                    i += 1;
                },
            }
        } else {
            switch (c) {
                '"' => try w.writeAll("\\\""),
                '\n' => try w.writeAll("\\n"),
                '\r' => try w.writeAll("\\r"),
                '\t' => try w.writeAll("\\t"),
                else => try w.writeByte(c),
            }
            i += 1;
        }
    }
    try w.writeAll("\">>");
}

// ── terms ────────────────────────────────────────────────────────────────────

/// Erlang float literal: always carries a `.` (`1` → `1.0`, `1e21` → `1.0e21`).
pub fn writeFloat(w: *Writer, f: f64) Error!void {
    if (!std.math.isFinite(f)) return error.NonFiniteFloat;
    // `{d}` writes plain decimal notation: the longest finite f64 (the smallest
    // denormal) needs ~330 bytes.
    var buf: [1100]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, "{d}", .{f}) catch unreachable;
    if (std.mem.indexOfScalar(u8, text, '.') != null) return w.writeAll(text);
    if (std.mem.indexOfAny(u8, text, "eE")) |e| {
        try w.writeAll(text[0..e]);
        try w.writeAll(".0");
        return w.writeAll(text[e..]);
    }
    try w.writeAll(text);
    try w.writeAll(".0");
}

/// Render `t` as an Erlang term expression.
pub fn writeTerm(w: *Writer, t: Term) Error!void {
    switch (t) {
        .atom => |a| try writeAtom(w, a),
        .binary => |b| try writeBinaryFromBytes(w, b),
        .integer => |n| try w.print("{d}", .{n}),
        .float => |f| try writeFloat(w, f),
        .boolean => |b| try w.writeAll(if (b) "true" else "false"),
        .nil => try w.writeAll("[]"),
        .list => |items| try writeSeq(w, "[", items, "]"),
        .tuple => |items| try writeSeq(w, "{", items, "}"),
        .map => |entries| {
            try w.writeAll("#{");
            for (entries, 0..) |e, i| {
                if (i > 0) try w.writeAll(", ");
                try writeTerm(w, e.key);
                try w.writeAll(" => ");
                try writeTerm(w, e.value);
            }
            try w.writeAll("}");
        },
    }
}

fn writeSeq(w: *Writer, open: []const u8, items: []const Term, close: []const u8) Error!void {
    try w.writeAll(open);
    for (items, 0..) |item, i| {
        if (i > 0) try w.writeAll(", ");
        try writeTerm(w, item);
    }
    try w.writeAll(close);
}

// ── code (erl_ast) ───────────────────────────────────────────────────────────

pub fn writeIndent(w: *Writer, indent: usize) Writer.Error!void {
    for (0..indent) |_| try w.writeAll("    ");
}

/// Render `e` as it continues a line already indented to `indent`; multi-line
/// constructs indent their inner lines relative to it.
pub fn writeExpr(w: *Writer, e: Ast.Expr, indent: usize) Error!void {
    switch (e) {
        .raw => |text| try w.writeAll(text),
        .term => |value| try writeTerm(w, value),
        .variable => |name| try w.writeAll(name),
        .atom => |name| try writeAtom(w, name),
        .lexeme_binary => |lexeme| try writeBinaryFromLexeme(w, lexeme),
        .call => |c| {
            if (c.module) |m| {
                try writeAtom(w, m);
                try w.writeByte(':');
            }
            try writeAtom(w, c.name);
            try writeArgs(w, c.args, indent);
        },
        .apply => |ap| {
            try writeExpr(w, ap.fun.*, indent);
            try writeArgs(w, ap.args, indent);
        },
        .binop => |b| {
            if (b.parens) try w.writeByte('(');
            try writeExpr(w, b.lhs.*, indent);
            try w.print(" {s} ", .{b.op});
            try writeExpr(w, b.rhs.*, indent);
            if (b.parens) try w.writeByte(')');
        },
        .unop => |u| {
            if (u.parens) try w.writeByte('(');
            try w.writeAll(u.op);
            try writeExpr(w, u.operand.*, indent);
            if (u.parens) try w.writeByte(')');
        },
        .match => |m| {
            try writeExpr(w, m.pattern.*, indent);
            try w.writeAll(" = ");
            try writeExpr(w, m.value.*, indent);
        },
        .tuple => |items| try writeExprSeq(w, "{", items, "}", indent),
        .list => |items| try writeExprSeq(w, "[", items, "]", indent),
        .cons => |c| {
            try w.writeByte('[');
            for (c.heads, 0..) |h, i| {
                if (i > 0) try w.writeAll(", ");
                try writeExpr(w, h, indent);
            }
            try w.writeAll(" | ");
            try writeExpr(w, c.tail.*, indent);
            try w.writeByte(']');
        },
        .map => |fields| try writeMapFields(w, fields, indent),
        .map_update => |mu| {
            try writeExpr(w, mu.map.*, indent);
            try writeMapFields(w, mu.fields, indent);
        },
        .list_comp => |lc| {
            try w.writeByte('[');
            try writeExpr(w, lc.element.*, indent);
            try w.writeAll(" || ");
            for (lc.qualifiers, 0..) |q, i| {
                if (i > 0) try w.writeAll(", ");
                switch (q) {
                    .generator => |g| {
                        try writeExpr(w, g.pattern, indent);
                        try w.writeAll(" <- ");
                        try writeExpr(w, g.list, indent);
                    },
                    .filter => |f| try writeExpr(w, f, indent),
                }
            }
            try w.writeByte(']');
        },
        .case_ => |c| {
            try w.writeAll("case ");
            try writeExpr(w, c.subject.*, indent);
            if (c.layout == .inline_) {
                try w.writeAll(" of ");
                for (c.clauses, 0..) |cl, i| {
                    if (i > 0) try w.writeAll("; ");
                    try writeExpr(w, cl.patterns[0], indent);
                    for (cl.guards, 0..) |g, gi| {
                        try w.writeAll(if (gi == 0) " when " else ", ");
                        try writeExpr(w, g, indent);
                    }
                    try w.writeAll(" -> ");
                    try writeInlineBody(w, cl.body, indent);
                }
                return w.writeAll(" end");
            }
            try w.writeAll(" of\n");
            try writeClauses(w, c.clauses, indent + 1);
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeAll("end");
        },
        .fun => |f| {
            try w.writeAll("fun");
            try writeArgs(w, f.params, indent);
            try w.writeAll(" ->\n");
            try writeBody(w, f.body, indent + 1);
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeAll("end");
        },
        .bin => |segments| {
            try w.writeAll("<<");
            for (segments, 0..) |seg, i| {
                if (i > 0) try w.writeAll(", ");
                try writeExpr(w, seg.value, indent);
                if (seg.type) |ty| try w.print("/{s}", .{ty});
            }
            try w.writeAll(">>");
        },
        .number => |text| try w.writeAll(text),
        .paren => |inner| {
            try w.writeByte('(');
            try writeExpr(w, inner.*, indent);
            try w.writeByte(')');
        },
        .fun_clauses => |clauses| {
            try w.writeAll("fun");
            for (clauses, 0..) |c, i| {
                if (i > 0) try w.writeAll("; ");
                try writeArgs(w, c.patterns, indent);
                try w.writeAll(" -> ");
                try writeInlineBody(w, c.body, indent);
            }
            try w.writeAll(" end");
        },
        .exception => |ex| {
            try writeExpr(w, ex.class.*, indent);
            try w.writeByte(':');
            try writeExpr(w, ex.reason.*, indent);
            if (ex.stack) |st| {
                try w.writeByte(':');
                try writeExpr(w, st.*, indent);
            }
        },
        .string => |text| try writeString(w, text),
        .fun_ref => |ref| {
            try w.writeAll("fun ");
            try writeFnRef(w, ref);
        },
        .list_block => |items| {
            try w.writeAll("[\n");
            for (items, 0..) |item, i| {
                if (i > 0) try w.writeAll(",\n");
                try writeIndent(w, indent + 1);
                try writeExpr(w, item, indent + 1);
            }
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeByte(']');
        },
        .comment => |c| try writeComment(w, c),
        .seq => |parts| for (parts) |part| try writeExpr(w, part, indent),
        .try_catch => |tc| {
            try w.writeAll("try\n");
            try writeBody(w, tc.body, indent + 1);
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeAll("catch\n");
            try writeClauses(w, tc.catches, indent + 1);
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeAll("end");
        },
    }
}

fn writeArgs(w: *Writer, args: []const Ast.Expr, indent: usize) Error!void {
    try writeExprSeq(w, "(", args, ")", indent);
}

fn writeExprSeq(w: *Writer, open: []const u8, items: []const Ast.Expr, close: []const u8, indent: usize) Error!void {
    try w.writeAll(open);
    for (items, 0..) |item, i| {
        if (i > 0) try w.writeAll(", ");
        try writeExpr(w, item, indent);
    }
    try w.writeAll(close);
}

fn writeMapFields(w: *Writer, fields: []const Ast.MapField, indent: usize) Error!void {
    try w.writeAll("#{");
    for (fields, 0..) |f, i| {
        if (i > 0) try w.writeAll(", ");
        try writeExpr(w, f.key, indent);
        try w.writeAll(if (f.exact) " := " else " => ");
        try writeExpr(w, f.value, indent);
    }
    try w.writeByte('}');
}

/// Clauses of a `case`/`catch`, each starting at `indent`, separated by `;\n`.
fn writeClauses(w: *Writer, clauses: []const Ast.Clause, indent: usize) Error!void {
    for (clauses, 0..) |c, i| {
        if (i > 0) try w.writeAll(";\n");
        try writeIndent(w, indent);
        for (c.patterns, 0..) |p, pi| {
            if (pi > 0) try w.writeAll(", ");
            try writeExpr(w, p, indent);
        }
        try writeClauseTail(w, c, indent);
    }
}

/// ` [when Guard] ->` and the body in the clause's layout.
fn writeClauseTail(w: *Writer, c: Ast.Clause, indent: usize) Error!void {
    for (c.guards, 0..) |g, i| {
        try w.writeAll(if (i == 0) " when " else ", ");
        try writeExpr(w, g, indent);
    }
    switch (c.layout) {
        .block => {
            try w.writeAll(" ->\n");
            try writeBody(w, c.body, indent + 1);
        },
        .inline_ => {
            try w.writeAll(" -> ");
            try writeInlineBody(w, c.body, indent);
        },
    }
}

fn isComment(s: Ast.Stmt) bool {
    return s == .comment;
}

/// Statements one per line at `indent`. A real statement takes `,` only when
/// another real statement follows; comments never do. A body with no real
/// statement is `undefined` (Erlang has no empty body). No trailing newline.
pub fn writeBody(w: *Writer, body: Ast.Body, indent: usize) Error!void {
    const stmts = switch (body) {
        .raw_block => |text| return w.writeAll(text),
        .stmts => |s| s,
    };
    var last_real: ?usize = null;
    for (stmts, 0..) |s, i| {
        if (!isComment(s)) last_real = i;
    }
    for (stmts, 0..) |s, i| {
        try writeIndent(w, indent);
        try writeStmt(w, s, indent);
        if (i != stmts.len - 1) {
            const real_follows = if (last_real) |lr| (!isComment(s) and i < lr) else false;
            try w.writeAll(if (real_follows) ",\n" else "\n");
        }
    }
    if (last_real == null) {
        if (stmts.len > 0) try w.writeByte('\n');
        try writeIndent(w, indent);
        try w.writeAll("undefined");
    } else if (stmts.len > 0 and isComment(stmts[stmts.len - 1])) {
        try w.writeByte('\n');
        try writeIndent(w, indent);
    }
}

fn writeInlineBody(w: *Writer, body: Ast.Body, indent: usize) Error!void {
    const stmts = switch (body) {
        .raw_block => |text| return w.writeAll(text),
        .stmts => |s| s,
    };
    if (stmts.len == 0) return w.writeAll("undefined");
    for (stmts, 0..) |s, i| {
        if (i > 0) try w.writeAll(", ");
        try writeStmt(w, s, indent);
    }
}

fn writeStmt(w: *Writer, s: Ast.Stmt, indent: usize) Error!void {
    switch (s) {
        .expr => |e| try writeExpr(w, e, indent),
        .comment => |c| try writeComment(w, c),
    }
}

/// `name(P1, P2) [when G] -> Body.` — clauses separated by `;\n`, ending `.\n`.
pub fn writeFunction(w: *Writer, f: Ast.Function) Error!void {
    for (f.clauses, 0..) |c, i| {
        if (i > 0) try w.writeAll(";\n");
        try writeAtom(w, f.name);
        try writeArgs(w, c.patterns, 0);
        try writeClauseTail(w, c, 0);
    }
    try w.writeAll(".\n");
}

/// `% text` / `%% text` / `%%% text`.
pub fn writeComment(w: *Writer, c: Ast.Comment) Writer.Error!void {
    try w.writeAll(switch (c.level) {
        .line => "% ",
        .doc => "%% ",
        .module => "%%% ",
    });
    try w.writeAll(c.text);
}

fn writeFnRef(w: *Writer, ref: Ast.FnRef) Error!void {
    try writeAtom(w, ref.name);
    try w.print("/{d}", .{ref.arity});
}

fn writeFnRefs(w: *Writer, refs: []const Ast.FnRef) Error!void {
    try w.writeByte('[');
    for (refs, 0..) |ref, i| {
        if (i > 0) try w.writeAll(", ");
        try writeFnRef(w, ref);
    }
    try w.writeByte(']');
}

pub fn writeForm(w: *Writer, form: Ast.Form) Error!void {
    switch (form) {
        .module => |name| try w.print("-module({s}).\n", .{name}),
        .exports => |refs| {
            try w.writeAll("-export(");
            try writeFnRefs(w, refs);
            try w.writeAll(").\n");
        },
        .no_auto_import => |refs| {
            try w.writeAll("-compile({no_auto_import,");
            try writeFnRefs(w, refs);
            try w.writeAll("}).\n");
        },
        .blank => try w.writeByte('\n'),
        .attribute => |attr| try w.print("-{s}({s}).\n", .{ attr.name, attr.value }),
        .function => |f| try writeFunction(w, f),
        .comment => |c| {
            try writeComment(w, c);
            try w.writeByte('\n');
        },
        .raw => |text| try w.writeAll(text),
    }
}

pub fn writeForms(w: *Writer, forms: []const Ast.Form) Error!void {
    for (forms) |form| try writeForm(w, form);
}

// ── tests ────────────────────────────────────────────────────────────────────

fn expectTerm(expected: []const u8, t: Term) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeTerm(&aw.writer, t);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "erl_emitter: atoms quote only when needed" {
    var buf: [64]u8 = undefined;
    try std.testing.expectEqualStrings("ok", try atomText("ok", &buf));
    try std.testing.expectEqualStrings("'Record'", try atomText("Record", &buf));
    try std.testing.expectEqualStrings("'end'", try atomText("end", &buf));
    try std.testing.expectEqualStrings("'__500'", try atomText("__500", &buf));
    try std.testing.expectEqualStrings("'it\\'s'", try atomText("it's", &buf));
    try std.testing.expectEqualStrings("'Owner_m'", try atomText("'Owner_m'", &buf));
    try expectTerm("'Record'", Term.atomOf("Record"));
    try expectTerm("'of'", Term.atomOf("of"));
}

test "erl_emitter: variables" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeVar(&aw.writer, "decl");
    try std.testing.expectEqualStrings("Decl", aw.written());
    const v = try varName(std.testing.allocator, "path");
    defer std.testing.allocator.free(v);
    try std.testing.expectEqualStrings("Path", v);
}

test "erl_emitter: binaries from raw bytes escape everything non-printable" {
    try expectTerm("<<\"a\\\"b\\\\c\\nd\">>", Term.str("a\"b\\c\nd"));
    try expectTerm("<<\"Mem\\x{C3}\\x{B3}ria\">>", Term.str("Memória"));
    try expectTerm("<<\"\\x{01}\">>", Term.str("\x01"));
}

test "erl_emitter: binaries from lexemes keep botopink escapes" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeBinaryFromLexeme(&aw.writer, "a\\nb\\$c\\u{1F600}\"é");
    try std.testing.expectEqualStrings("<<\"a\\nb$c\\x{1F600}\\\"é\">>", aw.written());
}

test "erl_emitter: scalars" {
    try expectTerm("42", Term.int(42));
    try expectTerm("-3", Term.int(-3));
    try expectTerm("1.0", .{ .float = 1.0 });
    try expectTerm("3.14", .{ .float = 3.14 });
    try expectTerm("true", .{ .boolean = true });
    try expectTerm("[]", .nil);
    try expectTerm("undefined", Term.undefined_atom);
}

test "erl_emitter: compound terms" {
    const fields = [_]Term.MapEntry{
        Term.field("name", Term.str("name")),
        Term.field("typeName", Term.str("string")),
    };
    const field_list = [_]Term{Term.mapOf(&fields)};
    const handle = [_]Term.MapEntry{
        Term.field("kind", Term.atomOf("Record")),
        Term.field("name", Term.str("UserService")),
        Term.field("fields", Term.listOf(&field_list)),
        Term.field("methods", Term.listOf(&.{})),
    };
    try expectTerm(
        "#{kind => 'Record', name => <<\"UserService\">>, fields => [#{name => <<\"name\">>, typeName => <<\"string\">>}], methods => []}",
        Term.mapOf(&handle),
    );
    const pair = [_]Term{ Term.atomOf("ok"), Term.int(1) };
    try expectTerm("{ok, 1}", Term.tupleOf(&pair));
}

test "erl_emitter: expressions" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;
    const one = Ast.Expr.t(Term.int(1));
    const x = Ast.Expr.v("X");
    try writeExpr(w, .{ .call = .{ .module = "maps", .name = "get", .args = &.{ Ast.Expr.a("kind"), Ast.Expr.v("Decl") } } }, 0);
    try w.writeAll(" | ");
    try writeExpr(w, .{ .binop = .{ .op = "+", .lhs = &x, .rhs = &one } }, 0);
    try w.writeAll(" | ");
    try writeExpr(w, .{ .match = .{ .pattern = &Ast.Expr.v("Y@1"), .value = &Ast.Expr.a("Record") } }, 0);
    try w.writeAll(" | ");
    try writeExpr(w, .{ .map = &.{.{ .key = Ast.Expr.a("text"), .value = Ast.Expr.v("Text"), .exact = true }} }, 0);
    try w.writeAll(" | ");
    try writeExpr(w, .{ .cons = .{ .heads = &.{Ast.Expr.v("Hit")}, .tail = &Ast.Expr.v("_") } }, 0);
    try std.testing.expectEqualStrings(
        "maps:get(kind, Decl) | (X + 1) | Y@1 = 'Record' | #{text := Text} | [Hit | _]",
        aw.written(),
    );
}

test "erl_emitter: case, fun and function layouts" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;
    const subject = Ast.Expr.v("Hit");
    try writeIndent(w, 1);
    try writeExpr(w, .{ .case_ = .{ .subject = &subject, .clauses = &.{
        .{ .patterns = &.{Ast.Expr.a("undefined")}, .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.a("undefined") }}), .layout = .inline_ },
        .{ .patterns = &.{Ast.Expr.v("B")}, .body = Ast.Body.of(&.{
            .{ .expr = .{ .call = .{ .name = "f", .args = &.{Ast.Expr.v("B")} } } },
            .{ .comment = .{ .level = .line, .text = "done" } },
            .{ .expr = Ast.Expr.a("ok") },
        }) },
    } } }, 1);
    try w.writeByte('\n');
    try writeFunction(w, .{ .name = "each", .clauses = &.{.{
        .patterns = &.{Ast.Expr.v("Xs")},
        .body = Ast.Body.of(&.{.{ .expr = .{ .call = .{ .module = "lists", .name = "foreach", .args = &.{
            .{ .fun = .{ .params = &.{Ast.Expr.v("X")}, .body = Ast.Body.of(&.{}) } },
            Ast.Expr.v("Xs"),
        } } } }}),
    }} });
    try writeFunction(w, .{ .name = "text", .clauses = &.{.{
        .patterns = &.{.{ .map = &.{.{ .key = Ast.Expr.a("text"), .value = Ast.Expr.v("Text"), .exact = true }} }},
        .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("Text") }}),
        .layout = .inline_,
    }} });
    try std.testing.expectEqualStrings(
        \\    case Hit of
        \\        undefined -> undefined;
        \\        B ->
        \\            f(B),
        \\            % done
        \\            ok
        \\    end
        \\each(Xs) ->
        \\    lists:foreach(fun(X) ->
        \\        undefined
        \\    end, Xs).
        \\text(#{text := Text}) -> Text.
        \\
    , aw.written());
}

test "erl_emitter: inline case and seq" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;
    const subject = Ast.Expr.v("R");
    const ok_v = [_]Ast.Expr{ Ast.Expr.a("ok"), Ast.Expr.v("V") };
    try writeExpr(w, .{ .case_ = .{ .subject = &subject, .layout = .inline_, .clauses = &.{
        .{ .patterns = &.{.{ .tuple = &ok_v }}, .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.v("V") }}) },
        .{ .patterns = &.{Ast.Expr.v("_")}, .body = Ast.Body.of(&.{.{ .expr = Ast.Expr.a("false") }}) },
    } } }, 0);
    try w.writeAll(" | ");
    try writeExpr(w, .{ .seq = &.{ Ast.Expr.r("(string:find("), Ast.Expr.v("S"), Ast.Expr.r(", "), .{ .lexeme_binary = "x" }, Ast.Expr.r(") =/= nomatch)") } }, 0);
    try std.testing.expectEqualStrings(
        "case R of {ok, V} -> V; _ -> false end | (string:find(S, <<\"x\">>) =/= nomatch)",
        aw.written(),
    );
}

test "erl_emitter: module forms" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;
    const tests = [_]Ast.Expr{
        .{ .tuple = &.{ Ast.Expr.t(Term.str("a")), .{ .fun_ref = .{ .name = "__bp_test_0", .arity = 0 } } } },
        .{ .string = "~p~n" },
    };
    try writeForms(w, &.{
        .{ .module = "m" },
        .{ .no_auto_import = &.{.{ .name = "abs", .arity = 1 }} },
        .{ .exports = &.{ .{ .name = "main", .arity = 1 }, .{ .name = "of", .arity = 0 } } },
        .blank,
        .{ .comment = Ast.Comment.doc("record R: a") },
        .{ .comment = .{ .level = .module, .text = "module doc" } },
        .{ .function = .{ .name = "t", .clauses = &.{.{ .patterns = &.{}, .body = Ast.Body.of(&.{.{ .expr = .{ .list_block = &tests } }}) }} } },
    });
    try std.testing.expectEqualStrings(
        \\-module(m).
        \\-compile({no_auto_import,[abs/1]}).
        \\-export([main/1, 'of'/0]).
        \\
        \\%% record R: a
        \\%%% module doc
        \\t() ->
        \\    [
        \\        {<<"a">>, fun '__bp_test_0'/0},
        \\        "~p~n"
        \\    ].
        \\
    , aw.written());
}
