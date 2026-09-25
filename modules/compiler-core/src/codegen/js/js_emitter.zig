//! JavaScript source emitter — the only place that writes JS text.
//!
//! It owns the lexical rules of the target: string escaping, the reserved-word
//! rename that makes a botopink name a legal JS binding, parenthesisation,
//! indentation and semicolons. `codegen/commonJS.zig` builds `js_ast` nodes and
//! hands them here; it writes no text of its own.

const std = @import("std");
const Ast = @import("js_ast.zig");

const Writer = std.Io.Writer;

pub const Error = Writer.Error;

// ── names ────────────────────────────────────────────────────────────────────

/// ES2015+ reserved words that are illegal as JS binding names (plus
/// `arguments`/`eval`, illegal in strict mode). A botopink identifier that
/// collides is renamed with a `_` suffix — `with` → `with_`, `delete` →
/// `delete_` — consistently across declarations, call sites and exports (an
/// `exports.<name>` property keeps the original name; property positions
/// accept reserved words).
///
/// `true`/`false`/`null`/`this`/`super` are deliberately omitted: botopink
/// never creates bindings with those names, and in value position they are
/// legal JS primary expressions or handled separately (`self` → `this`). `of`
/// is also omitted — it is only a contextual keyword (`for…of`), so
/// `function of()` is valid JS and the stdlib relies on it.
const reserved_words = [_][]const u8{
    "arguments", "await",      "break",    "case",     "catch",
    "class",     "const",      "continue", "debugger", "default",
    "delete",    "do",         "else",     "enum",     "eval",
    "export",    "extends",    "finally",  "for",      "function",
    "if",        "implements", "import",   "in",       "instanceof",
    "interface", "let",        "new",      "package",  "private",
    "protected", "public",     "return",   "static",   "switch",
    "throw",     "try",        "typeof",   "var",      "void",
    "while",     "with",       "yield",
};

/// Sanitized JS binding name: reserved words get a `_` suffix, everything else
/// passes through unchanged. Returns a static string — no allocation. The
/// result aliases `name` exactly when nothing was renamed, which is how the
/// object-shorthand rule below detects a rename.
pub fn ident(name: []const u8) []const u8 {
    inline for (reserved_words) |w| {
        if (std.mem.eql(u8, name, w)) return w ++ "_";
    }
    return name;
}

/// True when `ident` renamed the name (so an object shorthand `{ name }` would
/// bind the wrong thing and has to become `{ name: name_ }`).
fn isRenamed(name: []const u8) bool {
    return ident(name).ptr != name.ptr;
}

// ── strings ──────────────────────────────────────────────────────────────────

/// Write a botopink string literal's RAW content as a JS string literal.
///
/// The lexer has already validated every textual escape (`\n`, `\"`, `\\`,
/// `\$`, `\u{…}`, …) and the escape set is JS-compatible, so escape PAIRS pass
/// through verbatim — re-escaping their backslash would double the source
/// escapes (`"\n"` would print a literal `\n` at runtime). Only real control
/// characters and unescaped quotes (multiline `"""` content) need escaping.
pub fn writeLexemeString(w: *Writer, s: []const u8) Error!void {
    try w.writeByte('"');
    var i: usize = 0;
    while (i < s.len) : (i += 1) {
        const c = s[i];
        switch (c) {
            '\\' => {
                // A validated escape — copy the pair verbatim.
                try w.writeByte('\\');
                if (i + 1 < s.len) {
                    i += 1;
                    try w.writeByte(s[i]);
                }
            },
            '"' => try w.writeAll("\\\""),
            '\n' => try w.writeAll("\\n"),
            '\r' => try w.writeAll("\\r"),
            '\t' => try w.writeAll("\\t"),
            else => try w.writeByte(c),
        }
    }
    try w.writeByte('"');
}

// ── layout ───────────────────────────────────────────────────────────────────

pub fn writeIndent(w: *Writer, indent: usize) Error!void {
    for (0..indent) |_| try w.writeAll("    ");
}

// ── expressions ──────────────────────────────────────────────────────────────

/// Render `e` as it continues a line already indented to `indent`; multi-line
/// constructs indent their inner lines relative to it.
pub fn writeExpr(w: *Writer, e: Ast.Expr, indent: usize) Error!void {
    switch (e) {
        .lexeme_string => |s| try writeLexemeString(w, s),
        .quoted => |s| {
            try w.writeByte('"');
            try w.writeAll(s);
            try w.writeByte('"');
        },
        .number => |n| try w.writeAll(n),
        .null_ => try w.writeAll("null"),
        .ident => |n| try w.writeAll(ident(n)),
        .name => |n| try w.writeAll(n),
        .this => try w.writeAll("this"),
        .member => |m| {
            // A number literal takes parentheses before a `.`: `42.toString()`
            // lexes `42.` as a float and node refuses the module, so the
            // receiver is spelled `(42).toString()` — what erlang and wasm
            // already answer as `42`.
            const paren_number = m.object.* == .number;
            if (paren_number) try w.writeByte('(');
            try writeExpr(w, m.object.*, indent);
            if (paren_number) try w.writeByte(')');
            try w.writeAll(if (m.optional) "?." else ".");
            try w.writeAll(m.name);
        },
        .index => |ix| {
            try writeExpr(w, ix.object.*, indent);
            if (ix.optional) try w.writeAll("?.");
            try w.writeByte('[');
            try writeExpr(w, ix.index.*, indent);
            try w.writeByte(']');
        },
        .call => |c| {
            try writeExpr(w, c.callee.*, indent);
            try writeArgs(w, c.args, indent);
        },
        .new_ => |c| {
            try w.writeAll("new ");
            try writeExpr(w, c.callee.*, indent);
            try writeArgs(w, c.args, indent);
        },
        .binary => |b| {
            if (b.parens) try w.writeByte('(');
            try writeExpr(w, b.lhs.*, indent);
            try w.writeByte(' ');
            try w.writeAll(b.op);
            try w.writeByte(' ');
            try writeExpr(w, b.rhs.*, indent);
            if (b.parens) try w.writeByte(')');
        },
        .unary => |u| {
            if (u.parens) try w.writeByte('(');
            try w.writeAll(u.op);
            try writeExpr(w, u.operand.*, indent);
            if (u.parens) try w.writeByte(')');
        },
        .ternary => |t| {
            try writeExpr(w, t.cond.*, indent);
            try w.writeAll(" ? ");
            try writeExpr(w, t.then.*, indent);
            try w.writeAll(" : ");
            try writeExpr(w, t.else_.*, indent);
        },
        .assign => |a| {
            try writeExpr(w, a.target.*, indent);
            try w.writeByte(' ');
            try w.writeAll(a.op);
            try w.writeByte(' ');
            try writeExpr(w, a.value.*, indent);
        },
        .paren => |inner| {
            try w.writeByte('(');
            try writeExpr(w, inner.*, indent);
            try w.writeByte(')');
        },
        .arrow => |a| {
            try writeParams(w, a.params, indent);
            try w.writeAll(" => ");
            switch (a.body) {
                .expr => |inner| try writeExpr(w, inner.*, indent),
                .block => |blk| try writeBlock(w, blk),
            }
        },
        .function => |f| {
            try w.writeAll(f.keyword);
            try writeParams(w, f.params, indent);
            try w.writeByte(' ');
            try writeBlock(w, f.body);
        },
        .array => |arr| try writeArray(w, arr, indent),
        .object => |obj| try writeObject(w, obj, indent),
        .host => |parts| for (parts) |part| switch (part) {
            .text => |t| try w.writeAll(t),
            .expr => |inner| try writeExpr(w, inner, indent),
        },
        .await_ => |inner| {
            try w.writeAll("await ");
            try writeExpr(w, inner.*, indent);
        },
        .yield_ => |inner| {
            try w.writeAll("yield");
            if (inner) |v| {
                try w.writeByte(' ');
                try writeExpr(w, v.*, indent);
            }
        },
        .comment => |c| try writeComment(w, c),
    }
}

fn writeArgs(w: *Writer, args: []const Ast.Expr, indent: usize) Error!void {
    try w.writeByte('(');
    for (args, 0..) |arg, i| {
        if (i > 0) try w.writeAll(", ");
        try writeExpr(w, arg, indent);
    }
    try w.writeByte(')');
}

fn writeArray(w: *Writer, arr: Ast.Array, indent: usize) Error!void {
    switch (arr.layout) {
        .inline_ => {
            try w.writeByte('[');
            for (arr.elems, 0..) |elem, i| {
                if (i > 0) try w.writeAll(", ");
                try writeExpr(w, elem, indent);
            }
            if (arr.spread) |sp| {
                if (arr.elems.len > 0) try w.writeAll(", ");
                try writeSpread(w, sp, indent);
            }
            try w.writeByte(']');
        },
        .lines => {
            try w.writeAll("[\n");
            for (arr.elems) |elem| {
                try writeIndent(w, indent + 1);
                try writeExpr(w, elem, indent + 1);
                try w.writeAll(",\n");
            }
            try writeIndent(w, indent);
            try w.writeByte(']');
        },
    }
}

fn writeSpread(w: *Writer, sp: Ast.Spread, indent: usize) Error!void {
    try w.writeAll("...");
    switch (sp) {
        .name => |n| try w.writeAll(n),
        .expr => |e| try writeExpr(w, e.*, indent),
    }
}

fn writeObject(w: *Writer, obj: Ast.Object, indent: usize) Error!void {
    switch (obj.layout) {
        .spaced, .tight => {
            const open: []const u8 = if (obj.layout == .spaced) "{ " else "{";
            const close: []const u8 = if (obj.layout == .spaced) " }" else "}";
            if (obj.props.len == 0) return w.writeAll("{}");
            try w.writeAll(open);
            for (obj.props, 0..) |p, i| {
                if (i > 0) try w.writeAll(", ");
                try writeProp(w, p, indent);
            }
            try w.writeAll(close);
        },
        .lines => {
            try w.writeByte('{');
            for (obj.props) |p| {
                try w.writeByte('\n');
                try writeIndent(w, indent + 1);
                try writeProp(w, p, indent + 1);
                try w.writeByte(',');
            }
            try w.writeByte('\n');
            try writeIndent(w, indent);
            try w.writeByte('}');
        },
    }
}

fn writeProp(w: *Writer, p: Ast.Object.Prop, indent: usize) Error!void {
    switch (p) {
        .kv => |kv| {
            try w.writeAll(kv.key);
            try w.writeAll(": ");
            try writeExpr(w, kv.value, indent);
        },
        .shorthand => |name| {
            try w.writeAll(name);
            if (isRenamed(name)) {
                try w.writeAll(": ");
                try w.writeAll(ident(name));
            }
        },
        .method => |m| {
            try w.writeAll(m.name);
            try writeParams(w, m.params, indent);
            try w.writeByte(' ');
            try writeBlock(w, m.body);
        },
    }
}

// ── patterns ─────────────────────────────────────────────────────────────────

fn writeParams(w: *Writer, params: []const Ast.Param, indent: usize) Error!void {
    try w.writeByte('(');
    for (params, 0..) |p, i| {
        if (i > 0) try w.writeAll(", ");
        try writeParam(w, p, indent);
    }
    try w.writeByte(')');
}

fn writeParam(w: *Writer, p: Ast.Param, indent: usize) Error!void {
    try writePattern(w, p.pattern, indent);
    if (p.default) |d| {
        try w.writeAll(" = ");
        try writeExpr(w, d, indent);
    }
}

pub fn writePattern(w: *Writer, pat: Ast.Pattern, indent: usize) Error!void {
    switch (pat) {
        .ident => |n| try w.writeAll(ident(n)),
        .name => |n| try w.writeAll(n),
        .object => |o| {
            try w.writeAll("{ ");
            for (o.props, 0..) |p, i| {
                if (i > 0) try w.writeAll(", ");
                if (p.bind) |b| {
                    try w.writeAll(p.key);
                    try w.writeAll(": ");
                    try w.writeAll(b);
                } else {
                    // Shorthand, unless the key is a reserved word: then the
                    // binding has to be renamed and spelled out.
                    try w.writeAll(p.key);
                    if (isRenamed(p.key)) {
                        try w.writeAll(": ");
                        try w.writeAll(ident(p.key));
                    }
                }
            }
            if (o.rest) |r| {
                if (o.props.len > 0) try w.writeAll(", ");
                try writeRest(w, r);
            }
            try w.writeAll(" }");
        },
        .array => |a| {
            try w.writeAll(if (a.spaced) "[ " else "[");
            for (a.elems, 0..) |elem, i| {
                if (i > 0) try w.writeAll(", ");
                try writePattern(w, elem, indent);
            }
            if (a.rest) |r| {
                if (a.elems.len > 0) try w.writeAll(", ");
                try writeRest(w, r);
            }
            try w.writeAll(if (a.spaced) " ]" else "]");
        },
        .match => |m| try writeMatchPattern(w, m, indent),
    }
}

fn writeRest(w: *Writer, r: Ast.Rest) Error!void {
    try w.writeAll("...");
    switch (r) {
        .binding => |n| try w.writeAll(ident(n)),
    }
}

fn writeMatchPattern(w: *Writer, m: Ast.MatchPattern, indent: usize) Error!void {
    switch (m) {
        .variant_binding => |v| {
            try w.writeAll(v.name);
            try w.writeByte(' ');
            try w.writeAll(ident(v.binding));
        },
        .variant_fields => |v| {
            try w.writeAll(v.name);
            try w.writeByte('(');
            for (v.fields, 0..) |f, i| {
                if (i > 0) try w.writeAll(", ");
                try w.writeAll(ident(f));
            }
            try w.writeByte(')');
        },
        .variant_patterns => |v| {
            try w.writeAll(v.name);
            try w.writeByte('(');
            for (v.args, 0..) |a, i| {
                if (i > 0) try w.writeAll(", ");
                try writePattern(w, a, indent);
            }
            try w.writeByte(')');
        },
        .number => |n| try w.writeAll(n),
        .string => |s| {
            try w.writeByte('"');
            try w.writeAll(s);
            try w.writeByte('"');
        },
        .alt => |pats| for (pats, 0..) |p, i| {
            if (i > 0) try w.writeAll(" | ");
            try writePattern(w, p, indent);
        },
        .multi => |pats| for (pats, 0..) |p, i| {
            if (i > 0) try w.writeAll(", ");
            try writePattern(w, p, indent);
        },
    }
}

// ── statements ───────────────────────────────────────────────────────────────

/// Render `s` at `indent` — the caller has already written the leading
/// indentation of the first line.
pub fn writeStmt(w: *Writer, s: Ast.Stmt, indent: usize) Error!void {
    switch (s) {
        .expr => |e| {
            try writeExpr(w, e, indent);
            try w.writeByte(';');
        },
        .decl => |d| {
            try w.writeAll(d.kw.text());
            try w.writeByte(' ');
            try writePattern(w, d.pattern, indent);
            try w.writeAll(" = ");
            try writeExpr(w, d.value, indent);
            try w.writeByte(';');
        },
        .return_ => |v| {
            try w.writeAll("return");
            if (v) |e| {
                try w.writeByte(' ');
                try writeExpr(w, e, indent);
            }
            try w.writeByte(';');
        },
        .throw_ => |e| {
            try w.writeAll("throw ");
            try writeExpr(w, e, indent);
            try w.writeByte(';');
        },
        .continue_ => try w.writeAll("continue;"),
        .continue_label => |l| {
            try w.writeAll("continue ");
            try w.writeAll(l);
            try w.writeByte(';');
        },
        .break_ => try w.writeAll("break;"),
        .yield_delegate => |e| {
            try w.writeAll("yield* ");
            try writeExpr(w, e, indent);
            try w.writeAll("; return;");
        },
        .if_ => |i| {
            try w.writeAll("if (");
            try writeExpr(w, i.cond, indent);
            try w.writeAll(") ");
            try writeStmt(w, i.then.*, indent);
            if (i.else_) |els| {
                try w.writeAll(" else ");
                try writeStmt(w, els.*, indent);
            }
        },
        .for_of => |f| {
            try w.writeAll(if (f.is_await) "for await (const " else "for (const ");
            try writePattern(w, f.pattern, indent);
            try w.writeAll(" of ");
            try writeExpr(w, f.iter, indent);
            try w.writeAll(") ");
            try writeBlock(w, f.body);
        },
        .while_ => |wh| {
            if (wh.label) |l| {
                try w.writeAll(l);
                try w.writeAll(": ");
            }
            try w.writeAll("while (");
            try writeExpr(w, wh.cond, indent);
            try w.writeAll(") ");
            try writeBlock(w, wh.body);
        },
        .block => |blk| try writeBlock(w, blk),
        .function => |f| try writeFunctionDecl(w, f, indent),
        .class => |c| try writeClass(w, c, indent),
        .comment => |c| try writeComment(w, c),
        .group => |items| for (items, 0..) |item, i| {
            if (i > 0) {
                try w.writeByte('\n');
                try writeIndent(w, indent);
            }
            try writeStmt(w, item, indent);
        },
    }
}

/// A braced statement list, in the layout the node asks for.
pub fn writeBlock(w: *Writer, blk: Ast.Block) Error!void {
    switch (blk.layout) {
        .indented => {
            try w.writeAll("{\n");
            for (blk.stmts) |s| {
                try writeIndent(w, blk.indent + 1);
                try writeStmt(w, s, blk.indent + 1);
                try w.writeByte('\n');
            }
            try writeIndent(w, blk.indent);
            try w.writeByte('}');
        },
        // Legacy: one literal level of indentation and a closing brace at
        // column 0, whatever the nesting. `blk.indent` is the ambient level a
        // multi-line statement's continuation lines still use.
        .fixed => {
            try w.writeAll("{\n");
            for (blk.stmts) |s| {
                try w.writeAll("    ");
                try writeStmt(w, s, blk.indent);
                try w.writeByte('\n');
            }
            try w.writeByte('}');
        },
        // A one-line block keeps a `group` on its line: its statements are
        // the block's own, written in sequence.
        .spaced => {
            try w.writeByte('{');
            try writeInline(w, blk.stmts, blk.indent, true);
            try w.writeAll(" }");
        },
        .tight => {
            try w.writeByte('{');
            try writeInline(w, blk.stmts, blk.indent, false);
            try w.writeByte('}');
        },
    }
}

/// Statements on one line, a `group` flattened into the sequence. `lead`
/// puts a space before every statement; otherwise only between them.
fn writeInline(w: *Writer, stmts: []const Ast.Stmt, indent: usize, lead: bool) Error!void {
    var first = true;
    for (stmts) |s| {
        if (s == .group) {
            for (s.group) |item| {
                if (lead or !first) try w.writeByte(' ');
                try writeInlineStmt(w, item, indent);
                first = false;
            }
            continue;
        }
        if (lead or !first) try w.writeByte(' ');
        try writeInlineStmt(w, s, indent);
        first = false;
    }
}

/// One statement of a ONE-LINE block. A `// …` comment runs to the end of the
/// physical line, and on this line the statements that follow it, the block's
/// own `}` and everything after it are still to come — a `//` here silently
/// deletes them (`{ // note; return 1; }` left the module unterminated and node
/// answered `SyntaxError: Unexpected end of input`). So a line comment is
/// spelled as a BLOCK comment wherever the rest of the line must survive.
fn writeInlineStmt(w: *Writer, s: Ast.Stmt, indent: usize) Error!void {
    switch (s) {
        .comment => |c| return writeInlineComment(w, c),
        // A comment written in the SOURCE reaches codegen as an expression
        // (`literal.comment`), so one standing where a statement stands is an
        // expression statement around it — and the `;` that statement adds
        // ends up inside the comment too.
        .expr => |e| if (e == .comment) return writeInlineComment(w, e.comment),
        else => {},
    }
    try writeStmt(w, s, indent);
}

/// `/* text */` — a comment that does not eat the rest of its line. A `*/`
/// inside the text would close it early, so each one is broken up.
fn writeInlineComment(w: *Writer, c: Ast.Comment) Error!void {
    if (c.style == .doc) return writeComment(w, c);
    try w.writeAll("/* ");
    var rest = c.text;
    while (std.mem.indexOf(u8, rest, "*/")) |i| {
        try w.writeAll(rest[0..i]);
        try w.writeAll("*\\/");
        rest = rest[i + 2 ..];
    }
    try w.writeAll(rest);
    try w.writeAll(" */");
}

fn writeFunctionDecl(w: *Writer, f: Ast.FunctionDecl, indent: usize) Error!void {
    try w.writeAll(f.keyword);
    try w.writeByte(' ');
    try w.writeAll(ident(f.name));
    try writeParams(w, f.params, indent);
    try w.writeByte(' ');
    try writeBlock(w, f.body);
}

fn writeClass(w: *Writer, c: Ast.Class, indent: usize) Error!void {
    try w.writeAll("class ");
    try w.writeAll(c.name);
    if (c.extends) |base| {
        try w.writeAll(" extends ");
        try w.writeAll(base);
    }
    try w.writeAll(" {\n");
    if (c.ctor) |ctor| {
        try writeIndent(w, 1);
        try w.writeAll("constructor");
        try writeParams(w, ctor.params, indent);
        try w.writeByte(' ');
        try writeBlock(w, ctor.body);
        try w.writeByte('\n');
    }
    for (c.members, 0..) |m, mi| {
        // A blank line separates members from each other and from the
        // constructor — never opens the body.
        if (mi > 0 or c.ctor != null) try w.writeByte('\n');
        try writeIndent(w, 1);
        switch (m.kind) {
            .method => {},
            .static_method => try w.writeAll("static "),
            .getter => try w.writeAll("get "),
            .setter => try w.writeAll("set "),
        }
        // JS fixes the order of a method's modifiers: `static async *name`.
        if (m.is_async) try w.writeAll("async ");
        if (m.is_generator) try w.writeByte('*');
        try w.writeAll(m.name);
        try writeParams(w, m.params, indent);
        try w.writeByte(' ');
        try writeBlock(w, m.body);
        try w.writeByte('\n');
    }
    try w.writeByte('}');
}

/// `// text`, `/** text */` or `//// text`.
pub fn writeComment(w: *Writer, c: Ast.Comment) Error!void {
    switch (c.style) {
        .line => {
            try w.writeAll("// ");
            try w.writeAll(c.text);
        },
        .doc => {
            try w.writeAll("/** ");
            try w.writeAll(c.text);
            try w.writeAll(" */");
        },
        .module => {
            try w.writeAll("//// ");
            try w.writeAll(c.text);
        },
    }
}

// ── module ───────────────────────────────────────────────────────────────────

/// Write a whole module: generated declarations separated by a blank line,
/// runtime-support source verbatim.
pub fn writeProgram(w: *Writer, items: []const Ast.Item) Error!void {
    var first = true;
    for (items) |item| switch (item) {
        .runtime => |text| try w.writeAll(text),
        .stmt => |s| {
            if (!first) try w.writeByte('\n');
            try writeStmt(w, s, 0);
            try w.writeByte('\n');
            first = false;
        },
    };
}

// ── tests ────────────────────────────────────────────────────────────────────

fn expectExpr(expected: []const u8, e: Ast.Expr) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeExpr(&aw.writer, e, 0);
    try std.testing.expectEqualStrings(expected, aw.written());
}

fn expectStmt(expected: []const u8, s: Ast.Stmt) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeStmt(&aw.writer, s, 0);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "js_emitter: reserved words are renamed once, in the emitter" {
    try std.testing.expectEqualStrings("delete_", ident("delete"));
    try std.testing.expectEqualStrings("with_", ident("with"));
    try std.testing.expectEqualStrings("of", ident("of"));
    try std.testing.expectEqualStrings("main", ident("main"));
    try expectExpr("delete_", Ast.Expr.id("delete"));
    // A property position accepts a reserved word, so it is never renamed.
    const obj = Ast.Expr.id("x");
    try expectExpr("x.delete", .{ .member = .{ .object = &obj, .name = "delete" } });
}

test "js_emitter: string literals keep validated escapes and escape raw bytes" {
    try expectExpr("\"a\\nb\"", .{ .lexeme_string = "a\\nb" });
    try expectExpr("\"a\\nb\"", .{ .lexeme_string = "a\nb" });
    try expectExpr("\"say \\\"hi\\\"\"", .{ .lexeme_string = "say \"hi\"" });
    try expectExpr("\"main.bp:3\"", Ast.Expr.str("main.bp:3"));
}

test "js_emitter: expressions parenthesise the way the backend expects" {
    const x = Ast.Expr.id("x");
    const one = Ast.Expr.num("1");
    try expectExpr("(x + 1)", .{ .binary = .{ .op = "+", .lhs = &x, .rhs = &one } });
    try expectExpr("\"error\" in x", .{ .binary = .{ .op = "in", .lhs = &Ast.Expr{ .quoted = "error" }, .rhs = &x, .parens = false } });
    try expectExpr("(!x)", .{ .unary = .{ .op = "!", .operand = &x } });
    try expectExpr("x ? 1 : x", .{ .ternary = .{ .cond = &x, .then = &one, .else_ = &x } });
    try expectExpr("x.length", .{ .member = .{ .object = &x, .name = "length" } });
    const n42 = Ast.Expr.num("42");
    try expectExpr("(42).toString", .{ .member = .{ .object = &n42, .name = "toString" } });
    try expectExpr("x?.[1]", .{ .index = .{ .object = &x, .index = &one, .optional = true } });
    try expectExpr("new Person(1)", .{ .new_ = .{ .callee = &Ast.Expr{ .name = "Person" }, .args = &.{one} } });
    try expectExpr("await x", .{ .await_ = &x });
    try expectExpr("yield", .{ .yield_ = null });
}

test "js_emitter: aggregates and their layouts" {
    try expectExpr("[1, 1]", .{ .array = .{ .elems = &.{ Ast.Expr.num("1"), Ast.Expr.num("1") } } });
    try expectExpr("[1, ...rest]", .{ .array = .{ .elems = &.{Ast.Expr.num("1")}, .spread = .{ .name = "rest" } } });
    try expectExpr("{}", .{ .object = .{} });
    try expectExpr("{ ok: 1 }", .{ .object = .{ .props = &.{.{ .kv = .{ .key = "ok", .value = Ast.Expr.num("1") } }} } });
    try expectExpr("{length: 1}", .{ .object = .{ .props = &.{.{ .kv = .{ .key = "length", .value = Ast.Expr.num("1") } }}, .layout = .tight } });
    // A shorthand whose key is a reserved word has to name the binding.
    try expectExpr("{ delete: delete_ }", .{ .object = .{ .props = &.{.{ .shorthand = "delete" }} } });
    try expectExpr(
        \\[
        \\    1,
        \\]
    , .{ .array = .{ .elems = &.{Ast.Expr.num("1")}, .layout = .lines } });
}

test "js_emitter: block layouts" {
    const body = [_]Ast.Stmt{.{ .return_ = Ast.Expr.num("1") }};
    // The single-line IIFE shape.
    try expectExpr("(() => { return 1; })()", .{ .call = .{
        .callee = &Ast.Expr{ .paren = &Ast.Expr{ .arrow = .{ .body = .{ .block = .{ .stmts = &body, .layout = .spaced } } } } },
    } });
    // An arrow block: one literal level, closing brace at column 0.
    try expectExpr(
        \\(x) => {
        \\    return 1;
        \\}
    , .{ .arrow = .{ .params = &.{Ast.Param.id("x")}, .body = .{ .block = .{ .stmts = &body, .layout = .fixed } } } });
    // A nesting-correct body.
    try expectStmt(
        \\function f() {
        \\    return 1;
        \\}
    , .{ .function = .{ .name = "f", .body = .{ .stmts = &body } } });
}

test "js_emitter: statements" {
    try expectStmt("const x = 1;", .{ .decl = .{ .pattern = .{ .ident = "x" }, .value = Ast.Expr.num("1") } });
    try expectStmt("let delete_ = 1;", .{ .decl = .{ .kw = .let_, .pattern = .{ .ident = "delete" }, .value = Ast.Expr.num("1") } });
    try expectStmt("return;", .{ .return_ = null });
    try expectStmt("continue;", .continue_);
    try expectStmt("break;", .break_);
    try expectStmt(
        \\while (x) {
        \\    break;
        \\}
    , .{ .while_ = .{ .cond = Ast.Expr.id("x"), .body = .{ .stmts = &.{.break_}, .layout = .fixed } } });
    try expectStmt("yield* xs; return;", .{ .yield_delegate = Ast.Expr.id("xs") });
    try expectStmt("// note", .{ .comment = Ast.Comment.line("note") });
    try expectStmt("/** note */", .{ .comment = .{ .style = .doc, .text = "note" } });
    try expectStmt("if (x) return 1;", .{ .if_ = .{ .cond = Ast.Expr.id("x"), .then = &Ast.Stmt{ .return_ = Ast.Expr.num("1") } } });
    try expectStmt(
        \\for (const x of xs) {
        \\    return 1;
        \\}
    , .{ .for_of = .{
        .pattern = .{ .ident = "x" },
        .iter = Ast.Expr.id("xs"),
        .body = .{ .stmts = &.{.{ .return_ = Ast.Expr.num("1") }}, .layout = .fixed },
    } });
}

test "js_emitter: destructuring patterns" {
    try expectStmt("const { name } = p;", .{ .decl = .{
        .pattern = .{ .object = .{ .props = &.{.{ .key = "name" }} } },
        .value = Ast.Expr.id("p"),
    } });
    // A rest element can only sit at the end — it is a field of the pattern.
    try expectStmt("const { name, ...rest } = p;", .{ .decl = .{
        .pattern = .{ .object = .{ .props = &.{.{ .key = "name" }}, .rest = .{ .binding = "rest" } } },
        .value = Ast.Expr.id("p"),
    } });
    try expectStmt("const { class: class_ } = p;", .{ .decl = .{
        .pattern = .{ .object = .{ .props = &.{.{ .key = "class" }} } },
        .value = Ast.Expr.id("p"),
    } });
    try expectStmt("const [ a, b ] = p;", .{ .decl = .{
        .pattern = .{ .array = .{ .elems = &.{ .{ .ident = "a" }, .{ .ident = "b" } }, .spaced = true } },
        .value = Ast.Expr.id("p"),
    } });
}

const this_expr: Ast.Expr = .this;

test "js_emitter: classes" {
    try expectStmt(
        \\class Person {
        \\    constructor(name) {
        \\        this.name = name;
        \\    }
        \\
        \\    greet() {
        \\        return this.name;
        \\    }
        \\}
    , .{ .class = .{
        .name = "Person",
        .ctor = .{
            .params = &.{Ast.Param.id("name")},
            .body = .{ .stmts = &.{.{ .expr = .{ .assign = .{
                .target = &Ast.Expr{ .member = .{ .object = &this_expr, .name = "name" } },
                .value = &Ast.Expr{ .ident = "name" },
            } } }}, .indent = 1 },
        },
        .members = &.{.{
            .name = "greet",
            .body = .{ .stmts = &.{.{ .return_ = .{ .member = .{ .object = &this_expr, .name = "name" } } }}, .indent = 1 },
        }},
    } });
}

test "js_emitter: a module separates declarations with a blank line" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeProgram(&aw.writer, &.{
        .{ .stmt = .{ .decl = .{ .pattern = .{ .ident = "x" }, .value = Ast.Expr.num("1") } } },
        .{ .stmt = .{ .group = &.{
            .{ .function = .{ .name = "f", .body = .{} } },
            .{ .expr = .{ .assign = .{
                .target = &Ast.Expr{ .member = .{ .object = &Ast.Expr{ .name = "exports" }, .name = "f" } },
                .value = &Ast.Expr{ .ident = "f" },
            } } },
        } } },
    });
    try std.testing.expectEqualStrings(
        \\const x = 1;
        \\
        \\function f() {
        \\}
        \\exports.f = f;
        \\
    , aw.written());
}

test "js_emitter: the bridges render the shapes the model would otherwise forbid" {
    // A botopink match pattern used as a binding target.
    try expectStmt("const Circle(r) = p;", .{ .decl = .{
        .pattern = .{ .match = .{ .variant_fields = .{ .name = "Circle", .fields = &.{"r"} } } },
        .value = Ast.Expr.id("p"),
    } });
}
