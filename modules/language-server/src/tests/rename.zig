/// Testes de rename — cobre `engine.rename`.
/// Snapshots em: snapshots/lsp/rename_*.snap.md
///
/// Analogia Gleam: tests/rename.rs (125 testes / 160 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── Rn1 — rename de val com usos ──────────────────────────────────────────────

test "rename: val with usages produces edits for all occurrences" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const cursor = h.pos(0, 4);
    const edits = try engine.rename(gpa, source, cursor, "newX", tokens);
    defer gpa.free(edits);

    // Declaração 'x' + uso 'x' = 2 edits
    try std.testing.expectEqual(@as(usize, 2), edits.len);
    // Todos os edits devem ter newText = "newX"
    for (edits) |edit| {
        try std.testing.expectEqualStrings("newX", edit.newText);
    }
    try snap.assertRename(gpa, "rename_val_with_usages", source, cursor, "newX", edits);
}

// ── Rn2 — rename de fn ───────────────────────────────────────────────────────

test "rename: fn with calls produces edits for all occurrences" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f(a: i32) { return a; }
        \\val r = f(1);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const cursor = h.pos(0, 3);
    const edits = try engine.rename(gpa, source, cursor, "identity", tokens);
    defer gpa.free(edits);

    // Declaração 'f' + chamada 'f' = 2 edits
    try std.testing.expectEqual(@as(usize, 2), edits.len);
    try snap.assertRename(gpa, "rename_fn_with_calls", source, cursor, "identity", edits);
}

// ── Rn3 — cursor em literal produz zero edits ─────────────────────────────────

test "rename: cursor on literal returns no edits" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // col 8 = '4' em '42'
    const cursor = h.pos(0, 8);
    const edits = try engine.rename(gpa, source, cursor, "z", tokens);
    defer gpa.free(edits);

    try snap.assertRename(gpa, "rename_literal_no_edits", source, cursor, "z", edits);
}

// ── Rn4 — múltiplas ocorrências ───────────────────────────────────────────────

test "rename: symbol used 3 times produces 3 edits" {
    const gpa = std.testing.allocator;
    const source =
        \\val n = 1;
        \\val a = n;
        \\val b = n;
        \\val c = n;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const cursor = h.pos(0, 4);
    const edits = try engine.rename(gpa, source, cursor, "num", tokens);
    defer gpa.free(edits);

    // 1 declaração + 3 usos = 4 edits
    try std.testing.expectEqual(@as(usize, 4), edits.len);
    try snap.assertRename(gpa, "rename_multiple_occurrences", source, cursor, "num", edits);
}

// ── Rn5 — ranges corretos ─────────────────────────────────────────────────────

test "rename: edit ranges cover exactly the identifier token" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const edits = try engine.rename(gpa, source, h.pos(0, 4), "z", tokens);
    defer gpa.free(edits);

    // O primeiro edit deve cobrir a posição de 'x' na declaração (linha 0, col 4)
    var found = false;
    for (edits) |edit| {
        if (edit.range.start.line == 0 and edit.range.start.character == 4) {
            try std.testing.expectEqual(@as(u32, 5), edit.range.end.character);
            found = true;
        }
    }
    try std.testing.expect(found);
    try snap.assertRename(gpa, "rename_ranges_correct", source, h.pos(0, 4), "z", edits);
}
