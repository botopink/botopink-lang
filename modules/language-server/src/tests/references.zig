/// Testes de find references — cobre `engine.references`.
/// Snapshots em: snapshots/lsp/references_*.snap.md
///
/// Analogia Gleam: tests/reference.rs (49 testes / 61 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── R1 — inclui declaração ────────────────────────────────────────────────────

test "references: include_declaration=true returns decl + usages" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
        \\val z = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // cursor na declaração 'x' linha 0, col 4
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // declaração + 2 usos = 3
    try std.testing.expectEqual(@as(usize, 3), locs.len);
    try snap.assertReferences(gpa, "references_include_decl", source, cursor, locs);
}

// ── R2 — exclui declaração ────────────────────────────────────────────────────

test "references: include_declaration=false returns only usages" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
        \\val z = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, false);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // apenas 2 usos (sem a declaração)
    try std.testing.expectEqual(@as(usize, 2), locs.len);
    try snap.assertReferences(gpa, "references_exclude_decl", source, cursor, locs);
}

// ── R3 — símbolo não utilizado ────────────────────────────────────────────────

test "references: unused binding has no references" {
    const gpa = std.testing.allocator;
    const source =
        \\val unused = 1;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // col 4 = 'unused'
    const cursor = h.pos(0, 4);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, false);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try std.testing.expectEqual(@as(usize, 0), locs.len);
    try snap.assertReferences(gpa, "references_unused", source, cursor, locs);
}

// ── R4 — cursor em não-identifier ─────────────────────────────────────────────

test "references: cursor on literal returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // col 8 = '4' em '42'
    const cursor = h.pos(0, 8);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try snap.assertReferences(gpa, "references_literal", source, cursor, locs);
}

// ── R5 — ranges corretos ──────────────────────────────────────────────────────

test "references: returned ranges match token positions" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const locs = try engine.references(gpa, h.TEST_URI, source, h.pos(0, 4), tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    // A declaração 'x' está na linha 0
    var found_decl = false;
    for (locs) |loc| {
        if (loc.range.start.line == 0) {
            try std.testing.expectEqual(@as(u32, 4), loc.range.start.character);
            found_decl = true;
        }
    }
    try std.testing.expect(found_decl);
    try snap.assertReferences(gpa, "references_ranges", source, h.pos(0, 4), locs);
}

// ── R6 — referências de fn ────────────────────────────────────────────────────

test "references: fn references across multiple usages" {
    const gpa = std.testing.allocator;
    const source =
        \\fn id(a: i32) { return a; }
        \\val r1 = id(1);
        \\val r2 = id(2);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'id' na col 3, linha 0
    const cursor = h.pos(0, 3);
    const locs = try engine.references(gpa, h.TEST_URI, source, cursor, tokens, true);
    defer {
        for (locs) |l| gpa.free(l.uri);
        gpa.free(locs);
    }

    try snap.assertReferences(gpa, "references_fn_usages", source, cursor, locs);
}
