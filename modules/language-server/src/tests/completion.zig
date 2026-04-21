/// Testes de completion — cobre `engine.completion`.
/// Snapshots em: snapshots/lsp/completion_*.snap.md
///
/// Analogia Gleam: tests/completion.rs (139 testes / 132 snapshots).
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── C1 — prefixo vazio retorna todos os bindings ──────────────────────────────

test "completion: empty prefix returns all bindings" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // cursor ao final da linha 1 (depois de todo o conteúdo)
    const cursor = h.pos(1, 10);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    // Deve incluir 'x' e 'y'
    try std.testing.expect(items.len >= 2);
    try snap.assertCompletion(gpa, "completion_empty_prefix", source, cursor, items);
}

// ── C2 — prefixo com match ────────────────────────────────────────────────────

test "completion: prefix filters to matching bindings" {
    const gpa = std.testing.allocator;
    // O prefixAt() lê o source diretamente; cursor em "gree" extrai o prefixo "gree".
    const source =
        \\val greeting = "hello";
        \\val x = greeting;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // col 12 = dentro de "greeting" na linha 1, prefixAt extrai "gree"
    const cursor = h.pos(1, 12);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    // Só 'greeting' começa com "gree"
    for (items) |it| {
        try std.testing.expect(std.mem.startsWith(u8, it.label, "gree"));
    }
    try snap.assertCompletion(gpa, "completion_prefix_filter", source, cursor, items);
}

// ── C3 — prefixo sem match retorna vazio ─────────────────────────────────────

test "completion: prefix with no match returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val zzz
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse &[_]h.comptime_pipeline.TypedBinding{};

    // col 7 = depois de "zzz"
    const cursor = h.pos(1, 7);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try snap.assertCompletion(gpa, "completion_no_match", source, cursor, items);
}

// ── C4 — fn aparece como kind=Function ───────────────────────────────────────

test "completion: fn binding has Function kind" {
    const gpa = std.testing.allocator;
    const source =
        \\fn identity(x: i32) { return x; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const cursor = h.pos(0, 19);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    // Achar 'identity' e verificar kind
    var found = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "identity")) {
            try std.testing.expectEqual(proto.CompletionItemKind.Function, it.kind.?);
            found = true;
        }
    }
    try std.testing.expect(found);
    try snap.assertCompletion(gpa, "completion_fn_kind", source, cursor, items);
}

// ── C5 — detail mostra tipo ───────────────────────────────────────────────────

test "completion: item detail shows inferred type" {
    const gpa = std.testing.allocator;
    const source =
        \\val count = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const cursor = h.pos(0, 15);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    for (items) |it| {
        if (std.mem.eql(u8, it.label, "count")) {
            try std.testing.expect(it.detail != null);
            // detail deve conter o nome do tipo
            try std.testing.expect(it.detail.?.len > 0);
        }
    }
    try snap.assertCompletion(gpa, "completion_detail_type", source, cursor, items);
}

// ── C6 — bindings vazios ──────────────────────────────────────────────────────

test "completion: empty bindings returns empty list" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
    ;

    const cursor = h.pos(0, 10);
    const items = try engine.completion(gpa, source, cursor, &.{});
    defer gpa.free(items);

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_empty_bindings", source, cursor, items);
}
