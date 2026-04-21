/// Testes de document symbols — cobre `engine.documentSymbols`.
/// Snapshots em: snapshots/lsp/symbols_*.snap.md
///
/// Analogia Gleam: tests/document_symbols.rs (10 testes / 10 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── S1 — arquivo vazio ────────────────────────────────────────────────────────

test "symbols: empty source returns no symbols" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), "");
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try snap.assertDocumentSymbols(gpa, "symbols_empty", "", syms);
}

// ── S2 — val ─────────────────────────────────────────────────────────────────

test "symbols: single val binding" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try snap.assertDocumentSymbols(gpa, "symbols_single_val", source, syms);
}

// ── S3 — fn ──────────────────────────────────────────────────────────────────

test "symbols: single fn binding" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f(a: i32) { return a; }
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try snap.assertDocumentSymbols(gpa, "symbols_single_fn", source, syms);
}

// ── S4 — record ──────────────────────────────────────────────────────────────

test "symbols: record declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = record { x: i32, y: i32 };
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try snap.assertDocumentSymbols(gpa, "symbols_record", source, syms);
}

// ── S5 — enum ────────────────────────────────────────────────────────────────

test "symbols: enum declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Color = enum { Red, Green, Blue };
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try snap.assertDocumentSymbols(gpa, "symbols_enum", source, syms);
}

// ── S6 — múltiplos ────────────────────────────────────────────────────────────

test "symbols: multiple declarations in order" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\fn f(a: i32) { return a; }
        \\val Color = enum { Red };
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 3), syms.len);
    try snap.assertDocumentSymbols(gpa, "symbols_multiple", source, syms);
}

// ── S7 — selectionRange linha correta ─────────────────────────────────────────

test "symbols: selectionRange.start.line matches declaration line" {
    const gpa = std.testing.allocator;
    const source =
        \\val a = 1;
        \\val b = 2;
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| gpa.free(s.name);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 2), syms.len);
    try std.testing.expectEqual(@as(u32, 0), syms[0].selectionRange.start.line);
    try std.testing.expectEqual(@as(u32, 1), syms[1].selectionRange.start.line);
    try snap.assertDocumentSymbols(gpa, "symbols_line_ranges", source, syms);
}
