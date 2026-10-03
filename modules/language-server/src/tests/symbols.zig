/// Document symbols tests — covers `engine.documentSymbols`.
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── S1 — empty file ────────────────────────────────────────────────────────

test "symbols: empty source returns no symbols" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), "");
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
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
        for (syms) |s| engine.freeSymbol(gpa, s);
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
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try snap.assertDocumentSymbols(gpa, "symbols_single_fn", source, syms);
}

// ── S4 — record ──────────────────────────────────────────────────────────────

test "symbols: record declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = type(x: i32, y: i32);
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try snap.assertDocumentSymbols(gpa, "symbols_record", source, syms);
}

// ── S5 — enum ────────────────────────────────────────────────────────────────

test "symbols: enum declaration" {
    const gpa = std.testing.allocator;
    const source =
        \\val Color = type { Red, Green, Blue };
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try snap.assertDocumentSymbols(gpa, "symbols_enum", source, syms);
}

// ── S6 — multiple ──

test "symbols: multiple declarations in order" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\fn f(a: i32) { return a; }
        \\val Color = type { Red };
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const tokens = try h.tokenize(arena.allocator(), source);
    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 3), syms.len);
    try snap.assertDocumentSymbols(gpa, "symbols_multiple", source, syms);
}

// ── S7 — correct selectionRange line ─────────────────────────────────────────

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
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 2), syms.len);
    try std.testing.expectEqual(@as(u32, 0), syms[0].selectionRange.start.line);
    try std.testing.expectEqual(@as(u32, 1), syms[1].selectionRange.start.line);
    try snap.assertDocumentSymbols(gpa, "symbols_line_ranges", source, syms);
}

// ── S-test — `test "name" { … }` blocks appear as Method symbols ──────────────

test "symbols: test blocks become Method symbols" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\test "x is positive" {
        \\    assert x > 0, "positive";
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    // val + test
    try std.testing.expectEqual(@as(usize, 2), syms.len);
    try std.testing.expectEqualStrings("x is positive", syms[1].name);
    try snap.assertDocumentSymbols(gpa, "symbols_test_block", source, syms);
}

// ── S9 — the 1.0.3 shorthand declarations ────────────────────────────────────
//
// The cases above declare types with the val-form (`val Point = type(…)`),
// which still parses. The shorthand — `type Name(…)`, `type Name { … }`,
// `behavior Name { … }` — is what the surface cutover made the way to write
// one, and nothing pinned the kinds the outline gives it (front 14 step 1:
// "record-shaped and enum-shaped `type` keep their `SymbolKind`; `behavior`
// stays `Interface`").

test "symbols: a shorthand `type Name(fields)` is a Struct with its fields" {
    const gpa = std.testing.allocator;
    const source =
        \\type Point(x: i32, y: i32) {
        \\    fn sum(self: Self) -> i32 { return self.x + self.y; }
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try std.testing.expectEqual(proto.SymbolKind.Struct, syms[0].kind);
    try snap.assertDocumentSymbols(gpa, "symbols_shorthand_type_record", source, syms);
}

test "symbols: a shorthand `type Name { variants }` is an Enum" {
    const gpa = std.testing.allocator;
    const source =
        \\type Color { Red, Green, Blue }
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try std.testing.expectEqual(proto.SymbolKind.Enum, syms[0].kind);
    try snap.assertDocumentSymbols(gpa, "symbols_shorthand_type_enum", source, syms);
}

test "symbols: a `behavior` is an Interface, not a Struct" {
    const gpa = std.testing.allocator;
    const source =
        \\behavior Printable {
        \\    fn show(self: Self) -> string;
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    try std.testing.expectEqual(proto.SymbolKind.Interface, syms[0].kind);
    try snap.assertDocumentSymbols(gpa, "symbols_shorthand_behavior", source, syms);
}

// ── S10 — a section is a type, not a member (decision 8 §5.3b) ────────────────

test "symbols: an enum section is an Enum carrying its own members" {
    const gpa = std.testing.allocator;
    const source =
        \\type Token {
        \\    Text { Bold, Italic, Size { Xs, Sm } },
        \\    Color { Red },
        \\    Hover(inner: i32)
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    try std.testing.expectEqual(@as(usize, 1), syms.len);
    const kids = syms[0].children orelse return error.NoChildren;
    try std.testing.expectEqual(@as(usize, 3), kids.len);

    // `Token.Text` and `Token.Color` are types; `Hover` is a payload variant.
    try std.testing.expectEqualStrings("Text", kids[0].name);
    try std.testing.expectEqual(proto.SymbolKind.Enum, kids[0].kind);
    try std.testing.expectEqualStrings("Color", kids[1].name);
    try std.testing.expectEqual(proto.SymbolKind.Enum, kids[1].kind);
    try std.testing.expectEqualStrings("Hover", kids[2].name);
    try std.testing.expectEqual(proto.SymbolKind.EnumMember, kids[2].kind);

    // `Token.Text.Size` nests one deeper.
    const text_kids = kids[0].children orelse return error.NoChildren;
    try std.testing.expectEqual(@as(usize, 3), text_kids.len);
    try std.testing.expectEqualStrings("Size", text_kids[2].name);
    try std.testing.expectEqual(proto.SymbolKind.Enum, text_kids[2].kind);

    try snap.assertDocumentSymbols(gpa, "symbols_enum_sections", source, syms);
}

test "symbols: a method's return type is not read as a variant" {
    const gpa = std.testing.allocator;
    const source =
        \\type Color {
        \\    Red,
        \\    Green,
        \\    fn next(self: Self) -> Color { return Color.Red; }
        \\}
    ;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();
    const tokens = try h.tokenize(arena.allocator(), source);

    const syms = try engine.documentSymbols(gpa, tokens);
    defer {
        for (syms) |s| engine.freeSymbol(gpa, s);
        gpa.free(syms);
    }

    const kids = syms[0].children orelse return error.NoChildren;
    // Red, Green, next — and not the `Color` of `-> Color` nor of `Color.Red`.
    try std.testing.expectEqual(@as(usize, 3), kids.len);
    try snap.assertDocumentSymbols(gpa, "symbols_enum_method_return_type", source, syms);
}
