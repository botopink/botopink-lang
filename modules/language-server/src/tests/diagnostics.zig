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

// ── D9 — erro de tipo vira diagnóstico (squiggle) ─────────────────────────────
//
// TODO "lsp ---- diagnostic squiggle on type error".

test "diagnostics: type mismatch surfaces a located typeError" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\val x: i32 = "hello";
    );
    defer c.deinit(gpa);

    // A type error means there is no successful (.ok) output.
    try std.testing.expect(!c.isOk());

    var found = false;
    for (c.result.session.outputs.items) |o| {
        if (o.outcome == .typeError) {
            found = true;
            try std.testing.expect(o.outcome.typeError.loc != null);
            const msg = try o.outcome.typeError.message(gpa);
            defer gpa.free(msg);
            try std.testing.expect(std.mem.indexOf(u8, msg, "mismatch") != null);
        }
    }
    try std.testing.expect(found);
}

// ── D10 — comptime annotation failure surfaces as a diagnostic ────────────────
//
// A comptime annotation `fail` surfaces as a diagnostic. `@external` arity
// validation runs during inference (no node eval needed), so it is the
// deterministic, node-free representative of that path. (The node-backed
// `decorator_eval` `fail`/`failAt` path is exercised by the lib matrix —
// onze/rakun decorators — see front-c-runtime.md C3.)
//
// NOTE: this annotation-validation typeError currently carries a null `loc`, so
// it surfaces file-wide rather than pinned to the annotated decl. Attaching the
// span is `compiler-core` (Front A) work; here we pin the diagnostic fires.
test "diagnostics: a comptime @external misuse surfaces a typeError diagnostic" {
    const gpa = std.testing.allocator;
    var c = try h.compile(gpa,
        \\#[@external(erlang)]
        \\pub declare fn length(s: string) -> i32;
    );
    defer c.deinit(gpa);

    // The arity failure means there is no successful (.ok) output. (1 arg is
    // below the 2..3 range; the 2-arg node shorthand is valid — see §A.)
    try std.testing.expect(!c.isOk());

    var found = false;
    for (c.result.session.outputs.items) |o| {
        if (o.outcome != .typeError) continue;
        const msg = try o.outcome.typeError.message(gpa);
        defer gpa.free(msg);
        if (std.mem.indexOf(u8, msg, "external") != null) found = true;
    }
    try std.testing.expect(found);
}
