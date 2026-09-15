//! Erlang source emitter for BEAM terms and names.
//!
//! Owns the lexical rules every BEAM-family emitter shares: when an atom needs
//! quoting, how a botopink name becomes an Erlang variable, and how strings
//! become binaries. `codegen/erlang.zig` uses it for names/literals, the
//! comptime evaluators for whole values (`Term`), and `beam_emitter.zig` for the
//! term syntax inside `{literal, …}` (identical in `.erl` and `.S`).

const std = @import("std");
const Term = @import("term.zig").Term;

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
    for (bytes) |c| switch (c) {
        '"' => try w.writeAll("\\\""),
        '\\' => try w.writeAll("\\\\"),
        '\n' => try w.writeAll("\\n"),
        '\r' => try w.writeAll("\\r"),
        '\t' => try w.writeAll("\\t"),
        0...8, 11, 12, 14...31, 127...255 => try w.print("\\x{{{X:0>2}}}", .{c}),
        else => try w.writeByte(c),
    };
    try w.writeAll("\">>");
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
