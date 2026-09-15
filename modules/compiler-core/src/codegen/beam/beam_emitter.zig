//! BEAM assembly (`.S`) emitter for BEAM terms.
//!
//! Renders the same `Term` model as `erl_emitter.zig`, but as instruction
//! operands: scalars get their typed wrapper (`{atom, ok}`, `{integer, 1}`,
//! `{float, 1.0}`, `nil`) and compound values become `{literal, <term>}`, whose
//! inner term syntax is exactly the Erlang source form — so it is delegated to
//! `erl_emitter`.

const std = @import("std");
const Term = @import("term.zig").Term;
const erl = @import("erl_emitter.zig");

const Writer = std.Io.Writer;

pub const Error = erl.Error;

/// `{atom, Name}` with the shared quoting rule (`{atom, 'Record'}`).
pub fn writeAtomOperand(w: *Writer, name: []const u8) Writer.Error!void {
    try w.writeAll("{atom, ");
    try erl.writeAtom(w, name);
    try w.writeAll("}");
}

/// `{literal, <<"…">>}` from a botopink string literal's lexeme content.
pub fn writeLexemeBinaryOperand(w: *Writer, lexeme: []const u8) Writer.Error!void {
    try w.writeAll("{literal, ");
    try erl.writeBinaryFromLexeme(w, lexeme);
    try w.writeAll("}");
}

/// Render `t` as an instruction operand.
pub fn writeOperand(w: *Writer, t: Term) Error!void {
    switch (t) {
        .atom => |a| try writeAtomOperand(w, a),
        .boolean => |b| try writeAtomOperand(w, if (b) "true" else "false"),
        .integer => |n| try w.print("{{integer, {d}}}", .{n}),
        .float => |f| {
            try w.writeAll("{float, ");
            try erl.writeFloat(w, f);
            try w.writeAll("}");
        },
        .nil => try w.writeAll("nil"),
        .list => |items| if (items.len == 0) try w.writeAll("nil") else try writeLiteral(w, t),
        .binary, .tuple, .map => try writeLiteral(w, t),
    }
}

/// `{literal, <term>}` — valid for any term, including scalars.
pub fn writeLiteral(w: *Writer, t: Term) Error!void {
    try w.writeAll("{literal, ");
    try erl.writeTerm(w, t);
    try w.writeAll("}");
}

/// `{move, <operand>, {x, Dest}}.` as a full instruction line (4-space indent).
pub fn writeMove(w: *Writer, t: Term, dest: u32) Error!void {
    try w.writeAll("    {move, ");
    try writeOperand(w, t);
    try w.print(", {{x, {d}}}}}.\n", .{dest});
}

// ── tests ────────────────────────────────────────────────────────────────────

fn expectOperand(expected: []const u8, t: Term) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeOperand(&aw.writer, t);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "beam_emitter: scalar operands" {
    try expectOperand("{atom, ok}", Term.atomOf("ok"));
    try expectOperand("{atom, 'Record'}", Term.atomOf("Record"));
    try expectOperand("{atom, 'end'}", Term.atomOf("end"));
    try expectOperand("{atom, true}", .{ .boolean = true });
    try expectOperand("{integer, 42}", Term.int(42));
    try expectOperand("{float, 2.5}", .{ .float = 2.5 });
    try expectOperand("nil", .nil);
    try expectOperand("nil", Term.listOf(&.{}));
}

test "beam_emitter: compound operands share erl term syntax" {
    try expectOperand("{literal, <<\"hi\">>}", Term.str("hi"));
    const entries = [_]Term.MapEntry{Term.field("kind", Term.atomOf("Record"))};
    try expectOperand("{literal, #{kind => 'Record'}}", Term.mapOf(&entries));
    const items = [_]Term{ Term.int(1), Term.atomOf("a") };
    try expectOperand("{literal, [1, a]}", Term.listOf(&items));
    try expectOperand("{literal, {1, a}}", Term.tupleOf(&items));
}

test "beam_emitter: move instruction" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeMove(&aw.writer, Term.str("~p~n"), 0);
    try std.testing.expectEqualStrings("    {move, {literal, <<\"~p~n\">>}, {x, 0}}.\n", aw.written());
}
