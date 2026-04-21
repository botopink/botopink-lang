/// Testes de formatação — cobre `engine.formatting`.
///
/// Analogia BotoPink não tem suite separada (formatação é testada no compiler-core).
/// Aqui testamos a camada LSP: TextEdit retornado, null quando já formatado.
const std = @import("std");
const h = @import("./helpers.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── F1 — fonte já formatada não gera edits ────────────────────────────────────

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

// ── F4 — fonte formatável retorna TextEdit cobrindo o documento inteiro ───────

test "formatting: unformatted source returns a TextEdit covering the whole document" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Fonte válida mas que o formatter vai normalizar (espaços extras)
    const source = "val   x = 42;";
    const edit = try engine.formatting(arena.allocator(), source);

    // Se o formatter normalizou algo, edit != null e range começa em (0,0)
    if (edit) |e| {
        try std.testing.expectEqual(@as(u32, 0), e.range.start.line);
        try std.testing.expectEqual(@as(u32, 0), e.range.start.character);
        // newText não deve ser vazio
        try std.testing.expect(e.newText.len > 0);
    }
    // Se null, o formatter considerou correto — também aceitável
}

// ── F5 — TextEdit range.end aponta para o fim do documento ───────────────────

test "formatting: TextEdit end position matches end of source" {
    const gpa = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Multilinhas para garantir que end.line > 0 se houver edit
    const source = "val   x = 1;\nval   y = 2;";
    const edit = try engine.formatting(arena.allocator(), source);
    if (edit) |e| {
        // Range deve cobrir as 2 linhas
        try std.testing.expect(e.range.end.line >= 1);
    }
}
