/// Testes de signature help — cobre `engine.signatureHelp`.
/// Snapshots em: snapshots/lsp/sig_*.snap.md
///
/// Analogia Gleam: tests/signature_help.rs (26 testes / 25 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

// ── SH1 — cursor após ( mostra primeiro parâmetro ─────────────────────────────

test "signature_help: cursor after opening paren shows first param" {
    const gpa = std.testing.allocator;

    // Bindings da última compilação bem-sucedida (só a definição).
    const bindings_source =
        \\fn add(x: i32, y: i32) { return x; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Fonte atual (incompleta) — cenário real de edição.
    const source =
        \\fn add(x: i32, y: i32) { return x; }
        \\val r = add(
    ;
    // col 12 = depois do '(' em "val r = add("
    const cursor = h.pos(1, 12);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_first_param", source, cursor, result);
}

// ── SH2 — após vírgula mostra segundo parâmetro ───────────────────────────────

test "signature_help: cursor after comma shows second param" {
    const gpa = std.testing.allocator;

    // Bindings da última compilação bem-sucedida.
    const bindings_source =
        \\fn add(x: i32, y: i32) { return x; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Fonte atual (incompleta): usuário digitou o primeiro argumento e a vírgula.
    const source =
        \\fn add(x: i32, y: i32) { return x; }
        \\val r = add(1,
    ;
    // col 14 = depois da vírgula em "val r = add(1," → active_param=1
    const cursor = h.pos(1, 14);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    if (result) |sh| {
        const active_param = sh.activeParameter orelse 0;
        try std.testing.expectEqual(@as(u32, 1), active_param);
    }
    try snap.assertSignatureHelp(gpa, "sig_second_param", source, cursor, result);
}

// ── SH3 — fora de chamada retorna null ────────────────────────────────────────

test "signature_help: cursor outside a call returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    const cursor = h.pos(0, 4);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_outside_call_null", source, cursor, result);
}

// ── SH4 — função sem parâmetros ───────────────────────────────────────────────

test "signature_help: zero-param function" {
    const gpa = std.testing.allocator;

    // Bindings da última compilação bem-sucedida.
    const bindings_source =
        \\fn greet() { return 42; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Fonte atual (incompleta): usuário acabou de digitar `greet(`.
    const source =
        \\fn greet() { return 42; }
        \\val r = greet(
    ;
    // col 14 = depois do '(' em "val r = greet("
    const cursor = h.pos(1, 14);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_zero_params", source, cursor, result);
}

// ── SH5 — identificador não é função ─────────────────────────────────────────

test "signature_help: non-function identifier returns null" {
    const gpa = std.testing.allocator;

    // Compile only `val x = 1;` so that bindings carry x : i32 (non-function).
    // We cannot include the incomplete call `val r = x(` in the compiled source
    // because the type-checker rejects calling an integer.
    const bindings_source =
        \\val x = 1;
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Separate source used only for position scanning (not compilation).
    // The engine scans text backwards from cursor, finds `x` before `(`,
    // looks up `x` in bindings, sees it is not a function, and returns null.
    const scan_source =
        \\val x = 1;
        \\val r = x(
    ;
    // col 10 = depois do '(' em "val r = x("
    const cursor = h.pos(1, 10);
    const result = try engine.signatureHelp(arena.allocator(), scan_source, cursor, bindings);

    try snap.assertSignatureHelp(gpa, "sig_non_function_null", scan_source, cursor, result);
}

// ── SH6 — label da assinatura contém nome da função ──────────────────────────

test "signature_help: signature label contains function name" {
    const gpa = std.testing.allocator;

    // Bindings da última compilação bem-sucedida (só a definição).
    const bindings_source =
        \\fn compute(n: i32) { return n; }
    ;
    var c = try h.compile(gpa, bindings_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    // Fonte atual (incompleta) — usuário acabou de digitar `compute(`.
    const source =
        \\fn compute(n: i32) { return n; }
        \\val r = compute(
    ;
    // col 16 = depois do '(' em "val r = compute("
    const cursor = h.pos(1, 16);
    const result = try engine.signatureHelp(arena.allocator(), source, cursor, bindings);

    if (result) |sh| {
        if (sh.signatures.len > 0) {
            try std.testing.expect(
                std.mem.indexOf(u8, sh.signatures[0].label, "compute") != null,
            );
        }
    }
    try snap.assertSignatureHelp(gpa, "sig_label_has_name", source, cursor, result);
}
