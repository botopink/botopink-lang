/// Testes de diagnóstico — cobre `compiler_mod.LspCompiler` + parse errors.
///
/// Analogia BotoPink tests/compilation.rs (6 testes)
const std = @import("std");
const bp = @import("botopink");
const h = @import("./helpers.zig");
const proto = @import("../protocol.zig");
const engine = @import("../engine.zig");

// ── D1 — arquivo vazio ────────────────────────────────────────────────────────

test "diagnostics: empty source compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, "");
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D2 — fonte válida ─────────────────────────────────────────────────────────

test "diagnostics: simple val compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa, "val x = 42;");
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D3 — múltiplas declarações válidas ────────────────────────────────────────

test "diagnostics: multiple declarations compile without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val x = 1;
        \\val s = "hello";
        \\fn f(a: i32) { return a; }
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D4 — erro de parse — token inesperado ─────────────────────────────────────

test "diagnostics: parse error on unexpected token" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "val = 1;"; // falta nome do binding
    var lexer = bp.Lexer.init(source);
    const tokens = try lexer.scanAll(arena.allocator());

    var parser = bp.Parser.init(tokens);
    const result = parser.parse(arena.allocator());
    try std.testing.expectError(error.UnexpectedToken, result);
    try std.testing.expect(parser.parseError != null);
}

// ── D5 — erro de parse — falta fechamento ─────────────────────────────────────

test "diagnostics: parse error on unclosed expression" {
    const gpa = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const source = "fn f( =";
    var lexer = bp.Lexer.init(source);
    const tokens = try lexer.scanAll(arena.allocator());

    var parser = bp.Parser.init(tokens);
    const result = parser.parse(arena.allocator());
    try std.testing.expectError(error.UnexpectedToken, result);
}

// ── D6 — struct válido ────────────────────────────────────────────────────────

test "diagnostics: struct declaration compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D7 — enum válido ──────────────────────────────────────────────────────────

test "diagnostics: enum declaration compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val Color = enum { Red, Green, Blue };
        \\val c = Color.Red;
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}

// ── D8 — fn com anotação de tipos ─────────────────────────────────────────────

test "diagnostics: annotated function compiles without errors" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\fn add(x: i32, y: i32) { return x; }
    );
    defer c.deinit(gpa);
    try std.testing.expect(c.isOk());
}
