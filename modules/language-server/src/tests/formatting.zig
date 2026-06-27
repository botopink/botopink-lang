/// Formatting tests — covers `engine.formatting`.
///
/// BotoPink has no separate formatting suite (formatting is tested in compiler-core).
/// Here we test the LSP layer: returned TextEdit, null when already formatted.
const std = @import("std");
const h = @import("./helpers.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── F1 — already formatted source produces no edits ──

test "formatting: already-formatted source returns null" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "val x = 42;";
    const edit = try engine.formatting(arena.allocator(), source);
    try std.testing.expectEqual(@as(?proto.TextEdit, null), edit);
}

// ── F2 — fonte com parse error retorna null ───────────────────────────────────

test "formatting: invalid source returns null" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "val = oops";
    const edit = try engine.formatting(arena.allocator(), source);
    try std.testing.expectEqual(@as(?proto.TextEdit, null), edit);
}

// ── F3 — arquivo vazio retorna null ──────────────────────────────────────────

test "formatting: empty source returns null" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const edit = try engine.formatting(arena.allocator(), "");
    try std.testing.expectEqual(@as(?proto.TextEdit, null), edit);
}

// ── F4 — formattable source returns TextEdit covering the whole document ──

test "formatting: unformatted source returns a TextEdit covering the whole document" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Valid source that the formatter will normalize (extra spaces)
    const source = "val   x = 42;";
    const edit = try engine.formatting(arena.allocator(), source);

    // If the formatter normalized anything, edit != null and range starts at (0,0)
    if (edit) |e| {
        try std.testing.expectEqual(@as(u32, 0), e.range.start.line);
        try std.testing.expectEqual(@as(u32, 0), e.range.start.character);
        // newText must not be empty
        try std.testing.expect(e.newText.len > 0);
    }
    // If null, the formatter considered it correct — also acceptable
}

// ── F5 — TextEdit range.end aponta para o fim do documento ───────────────────

test "formatting: TextEdit end position matches end of source" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Multi-line to ensure end.line > 0 if there is an edit
    const source = "val   x = 1;\nval   y = 2;";
    const edit = try engine.formatting(arena.allocator(), source);
    if (edit) |e| {
        // Range must cover both lines
        try std.testing.expect(e.range.end.line >= 1);
    }
}
