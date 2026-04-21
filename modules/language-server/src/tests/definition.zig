/// Testes de go-to-definition — cobre `engine.definition`.
/// Snapshots em: snapshots/lsp/definition_*.snap.md
///
/// Analogia Gleam: tests/definition.rs (43 testes / 77 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── DG1 — vai para declaração val ────────────────────────────────────────────

test "definition: cursor on val usage jumps to declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'x' na segunda linha: "val y = x;" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_val_usage", source, h.pos(1, 8), result);
}

// ── DG2 — vai para declaração fn ─────────────────────────────────────────────

test "definition: cursor on fn call jumps to fn declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f(a: i32) { return a; }
        \\val r = f(1);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'f' na segunda linha: "val r = f(1);" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_fn_usage", source, h.pos(1, 8), result);
}

// ── DG3 — cursor em literal retorna null ─────────────────────────────────────

test "definition: cursor on integer literal" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // '42' começa na col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(0, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_literal_null", source, h.pos(0, 8), result);
}

// ── DG4 — record ─────────────────────────────────────────────────────────────

test "definition: cursor on record type usage" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'Point' na linha 1: "val p = Point(x: 1, y: 2);" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_record_usage", source, h.pos(1, 8), result);
}

// ── DG5 — URI preservada ──────────────────────────────────────────────────────

test "definition: returned Location carries the correct URI" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = x;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    // Verificação inline: URI deve ser a que passamos
    if (result) |loc| {
        try std.testing.expectEqualStrings(h.TEST_URI, loc.uri);
    }

    try snap.assertDefinition(gpa, "definition_uri_preserved", source, h.pos(1, 8), result);
}

// ── DG6 — enum declaration ────────────────────────────────────────────────────

test "definition: cursor on enum usage jumps to enum declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Color = enum { Red, Green, Blue };
        \\val c = Color.Red;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    // 'Color' na linha 1: "val c = Color.Red;" — col 8
    const result = try engine.definition(gpa, h.TEST_URI, source, h.pos(1, 8), tokens);
    defer if (result) |loc| gpa.free(loc.uri);

    try snap.assertDefinition(gpa, "definition_enum_usage", source, h.pos(1, 8), result);
}
