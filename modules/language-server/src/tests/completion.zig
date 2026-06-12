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

// ── C7 — cursor sobre literal numérico retorna vazio ─────────────────────────
//
// Gleam ref: `do_not_show_completions_when_typing_a_number`
// O binding "result_2" existe e contém "2" no nome, mas o cursor está sobre
// o literal `2` (não sobre um identificador), então nenhum item é sugerido.

test "completion: number literal at cursor returns empty" {
    const gpa = std.testing.allocator;
    // "result_2" é um binding válido — intencionalmente contém "2" no nome
    // para confirmar que o guard atua antes do filtro de prefixo.
    const source =
        \\val result_2 = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // cursor antes do literal '2' (col 15 = char imediatamente antes de '2')
    // val result_2 = 2;
    // 0         1
    // 0123456789012345
    // col 15 = '2', source[offset] = '2' → guard numérico → vazio
    const cursor = h.pos(0, 15);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_number_prefix", source, cursor, items);
}

// ── C8 — cursor dentro de string literal retorna vazio ────────────────────────
//
// Gleam refs: `ignore_completions_inside_string`,
//             `ignore_completions_inside_empty_string`

test "completion: cursor inside string literal returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val greeting = "hello";
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // val greeting = "hello";
    // 0         1         2
    // 0123456789012345678901 2
    // col 15 = '"', col 16 = 'h', col 17 = 'e', col 18 = 'l'
    // cursor em col 18 → offset 18 cai dentro da string → guard retorna vazio
    const cursor = h.pos(0, 18);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_cursor_in_string", source, cursor, items);
}

test "completion: cursor inside empty string returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = "";
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // val x = "";
    // 0         1
    // 012345678901
    // col 8 = '"' (abertura), col 9 = '"' (fechamento)
    // cursorInString varre até offset 9 exclusive: processa col 8 → in_string = true → vazio
    const cursor = h.pos(0, 9);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_cursor_in_empty_string", source, cursor, items);
}

// ── C9 — cursor dentro de string com prefixo "io." retorna vazio ────────────────
//
// Gleam ref: `no_completions_in_constant_string`

test "completion: cursor in const string returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = "io.";
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // val x = "io.";
    // 0         1         2
    // 0123456789012345678
    // col 10 = 'i', col 11 = 'o', col 12 = '.'
    // cursor em col 12 → dentro da string → guard retorna vazio
    const cursor = h.pos(0, 12);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_cursor_in_const_string", source, cursor, items);
}

// ── C10, C11, C12 — cursor dentro de comentário retorna vazio ───────────────────
//
// Gleam refs: `ignore_completions_in_empty_comment`,
//             `ignore_completions_in_middle_of_comment`,
//             `ignore_completions_in_end_of_comment`

test "completion: cursor in empty comment returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\//
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // linha 1: //
    // 01
    // col 0 = '/', col 1 = '/', col 2 = (após //)
    // cursor em col 2 → dentro de comentário → guard retorna vazio
    const cursor = h.pos(1, 2);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_comment_empty", source, cursor, items);
}

test "completion: cursor in middle of comment returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\// hello world
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // linha 1: // hello world
    // 01 234567890123456
    // col 0-1 = '//', col 7 = 'o' (meio de "world")
    // cursor em col 7 → dentro de comentário → guard retorna vazio
    const cursor = h.pos(1, 7);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_comment_middle", source, cursor, items);
}

test "completion: cursor at end of comment returns empty" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\// hello
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // linha 1: // hello
    // 01 23456789
    // col 0-1 = '//', col 8 = fim da linha (após 'o')
    // cursor em col 8 → ainda na linha com // → guard retorna vazio
    const cursor = h.pos(1, 8);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expectEqual(@as(usize, 0), items.len);
    try snap.assertCompletion(gpa, "completion_comment_end", source, cursor, items);
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

// ── C9 — dot-completion: campos de struct ─────────────────────────────────────
//
// TODO "lsp ---- autocomplete for struct/record field".

test "completion: dot completes record fields" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = record { x: f64, y: f64 };
        \\val origin = Point(x: 0.0, y: 0.0);
        \\val gx = origin.x;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val gx = origin." → o ponto fica na col 15; cursor logo após (col 16).
    const cursor = h.pos(2, 16);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var has_x = false;
    var has_y = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "x")) has_x = true;
        if (std.mem.eql(u8, it.label, "y")) has_y = true;
    }
    try std.testing.expect(has_x and has_y);
    try snap.assertCompletion(gpa, "completion_dot_record_fields", source, cursor, items);
}

// ── C10 — dot-completion: variantes de enum ───────────────────────────────────
//
// TODO "lsp ---- autocomplete for enum variant".

test "completion: dot completes enum variants" {
    const gpa = std.testing.allocator;
    const source =
        \\val Status = enum { Active, Inactive };
        \\val s = Status.Active;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val s = Status." → o ponto fica na col 14; cursor logo após (col 15).
    const cursor = h.pos(1, 15);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var has_active = false;
    var has_inactive = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "Active")) has_active = true;
        if (std.mem.eql(u8, it.label, "Inactive")) has_inactive = true;
    }
    try std.testing.expect(has_active and has_inactive);
    try snap.assertCompletion(gpa, "completion_dot_enum_variants", source, cursor, items);
}

// ── iterator method completion (*fn generators) ───────────────────────────────

test "completion: iterator receiver offers next/iter/map" {
    const gpa = std.testing.allocator;
    // Bindings come from a valid compile; completion runs on the mid-edit buffer
    // (`it.`) just like the LSP serves completion against the last good index.
    const valid_source =
        \\*fn gen() -> @Iterator<i32> { yield 1; }
        \\val it = gen();
    ;
    const edit_source =
        \\*fn gen() -> @Iterator<i32> { yield 1; }
        \\val it = gen();
        \\val first = it.
    ;

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Cursor at end of `val first = it.` on line 2 (col 15).
    const cursor = h.pos(2, 15);
    const items = try engine.completion(gpa, edit_source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var have_next = false;
    var have_iter = false;
    var have_map = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "next")) have_next = true;
        if (std.mem.eql(u8, it.label, "iter")) have_iter = true;
        if (std.mem.eql(u8, it.label, "map")) have_map = true;
    }
    try std.testing.expect(have_next and have_iter and have_map);
}

// ── C-std — `list.` completes embedded std module members ─────────────────────

test "completion: std module member after import from std" {
    const gpa = std.testing.allocator;
    const source =
        \\import {order} from "std";
        \\val xs = order.
    ;
    // Cursor right after `order.` (line 1, char 15).
    const cursor = h.pos(1, 15);
    const items = try engine.completion(gpa, source, cursor, &.{});
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var have_lt = false;
    var have_to_int = false;
    var have_reverse = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "lt")) have_lt = true;
        if (std.mem.eql(u8, it.label, "toInt")) have_to_int = true;
        if (std.mem.eql(u8, it.label, "reverse")) have_reverse = true;
    }
    try std.testing.expect(have_lt and have_to_int and have_reverse);
    try std.testing.expect(items.len >= 5);
}

// ── F4 — interface-method dispatch on builtin receivers ───────────────────────

test "completion: integer literal receiver offers I32 methods" {
    const gpa = std.testing.allocator;
    // Bindings come from a valid compile; completion runs on the mid-edit buffer.
    const valid_source =
        \\val n = 42;
    ;
    const edit_source =
        \\val n = 42;
        \\val s = 42.
    ;

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Cursor right after `42.` on line 1 (char 11).
    const cursor = h.pos(1, 11);
    const items = try engine.completion(gpa, edit_source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var have_abs = false;
    var have_clamp = false;
    var have_to_string = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "abs")) have_abs = true;
        if (std.mem.eql(u8, it.label, "clamp")) have_clamp = true;
        if (std.mem.eql(u8, it.label, "toString")) have_to_string = true;
    }
    try std.testing.expect(have_abs and have_clamp and have_to_string);
    try snap.assertCompletion(gpa, "completion_primitive_methods", edit_source, cursor, items);
}

test "completion: boolean literal receiver offers Bool methods" {
    const gpa = std.testing.allocator;
    const source =
        \\val s = true.
    ;
    const cursor = h.pos(0, 13);
    const items = try engine.completion(gpa, source, cursor, &.{});
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var have_to_string = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "toString")) have_to_string = true;
    }
    try std.testing.expect(have_to_string);
    try snap.assertCompletion(gpa, "completion_bool_methods", source, cursor, items);
}

test "completion: array value receiver offers Array methods" {
    const gpa = std.testing.allocator;
    const valid_source =
        \\val xs = [1, 2, 3];
    ;
    const edit_source =
        \\val xs = [1, 2, 3];
        \\val y = xs.
    ;

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Cursor right after `xs.` on line 1 (char 11).
    const cursor = h.pos(1, 11);
    const items = try engine.completion(gpa, edit_source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    var have_map = false;
    var have_filter = false;
    var have_push = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "map")) have_map = true;
        if (std.mem.eql(u8, it.label, "filter")) have_filter = true;
        if (std.mem.eql(u8, it.label, "push")) have_push = true;
    }
    try std.testing.expect(have_map and have_filter and have_push);
    try snap.assertCompletion(gpa, "completion_array_methods", edit_source, cursor, items);
}

test "completion: std module dot does not fire without the import" {
    const gpa = std.testing.allocator;
    const source =
        \\val xs = list.
    ;
    const cursor = h.pos(0, 14);
    const items = try engine.completion(gpa, source, cursor, &.{});
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }
    try std.testing.expectEqual(@as(usize, 0), items.len);
}

// ── R1 — local-scope symbol model (lsp-project-awareness) ─────────────────────
//
// A decorator body is full of locals the module-level `bindings` slice never
// holds: the `comptime decl` parameter, the `var args` local, and the `{ f -> … }`
// closure binder. Completion inside the body must list them — this is the real
// shape that shipped broken. The body need not type-check (`@Decl` here is left
// unresolved); completion degrades to a token walk and still surfaces the locals.

fn hasLabel(items: []const proto.CompletionItem, name: []const u8) bool {
    for (items) |it| if (std.mem.eql(u8, it.label, name)) return true;
    return false;
}

test "completion: decorator body lists params/locals/closure binder (R1)" {
    const gpa = std.testing.allocator;
    const source =
        \\pub fn component(comptime decl: @Decl) {
        \\    var args = "";
        \\    items.forEach({ f ->
        \\        log(args);
        \\    });
        \\}
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse &[_]h.comptime_pipeline.TypedBinding{};

    // cursor at the start of the `log(args)` line (empty prefix → list everything)
    const cursor = h.pos(3, 8);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    try std.testing.expect(hasLabel(items, "decl")); // comptime parameter
    try std.testing.expect(hasLabel(items, "args")); // `var` local
    try std.testing.expect(hasLabel(items, "f")); //    closure binder
    try snap.assertCompletion(gpa, "completion_decorator_body_locals", source, cursor, items);
}

// ── R2 — decorator-bearing record keeps its bindings (lsp-project-awareness) ───
//
// A record carrying an EMITTING decorator (`#[service]`) used to hand the LSP
// zero bindings: the decorator `@emit`ed wiring, the spliced re-analysis failed
// to type-check standalone, and completion went dark everywhere in the file
// (R2). The fix surfaces the source decls (record, fields, the marker) even when
// the emitted code can't stand alone. Runs the node-backed evaluator so the
// `@emit` path actually fires.

test "completion: decorator-bearing record still lists bindings (R2)" {
    const gpa = std.testing.allocator;
    // `@emit`s code referencing an unresolved symbol — stands in for the wiring a
    // real `#[service]` emits against `from \"<lib>\"` symbols the LSP compiled
    // without. The spliced re-analysis fails; completion must still degrade.
    const source =
        \\fn service(comptime decl: @Decl) {
        \\    @emit("val __wired = unresolvedRuntimeSymbol();");
        \\}
        \\
        \\#[service]
        \\record PostService { name: string, count: i32 }
        \\
        \\val usePost = PostService;
    ;

    var c = try h.compileEval(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse &[_]h.comptime_pipeline.TypedBinding{};

    // cursor at the start of `PostService` on the last line (empty prefix)
    const cursor = h.pos(7, 14);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    // Not blanked: the record (and the marker fn) are still completable.
    try std.testing.expect(items.len > 0);
    try std.testing.expect(hasLabel(items, "PostService"));
    try snap.assertCompletion(gpa, "completion_decorator_record", source, cursor, items);
}
