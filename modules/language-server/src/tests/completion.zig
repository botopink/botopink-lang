/// Completion tests — covers `engine.completion`.
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── C1 — empty prefix returns all bindings ──────────────────────────────

test "completion: empty prefix returns all bindings" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // cursor at end of line 1 (after all content)
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
    // prefixAt() reads source directly; cursor on "gree" extracts prefix "gree".
    const source =
        \\val greeting = "hello";
        \\val x = greeting;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // col 12 = inside "greeting" on line 1, prefixAt extracts "gree"
    const cursor = h.pos(1, 12);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    // Only 'greeting' starts with "gree"
    for (items) |it| {
        try std.testing.expect(std.mem.startsWith(u8, it.label, "gree"));
    }
    try snap.assertCompletion(gpa, "completion_prefix_filter", source, cursor, items);
}

// ── C3 — prefix with no match returns empty ─────────────────────────────────────

test "completion: prefix with no match returns empty" {
    const gpa = std.testing.allocator;
    // The bindings must come from a source that actually compiles: an
    // incomplete buffer yields *no* bindings, and an empty list makes the
    // completion empty whatever the prefix filter does — which would leave this
    // test asserting nothing.
    const compile_source =
        \\val x = 1;
    ;
    // The buffer the user is typing in: `zzz` matches no binding.
    const source =
        \\val x = 1;
        \\val y = zzz
    ;

    var c = try h.compile(gpa, compile_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Guard: `x` is offered for an empty prefix, so an empty list below is the
    // filter's doing and not a missing binding set.
    var has_x = false;
    for (bindings) |b| {
        if (std.mem.eql(u8, b.name, "x")) has_x = true;
    }
    try std.testing.expect(has_x);

    // col 11 = after "zzz" in `val y = zzz`
    const cursor = h.pos(1, 11);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }

    for (items) |it| try std.testing.expect(!std.mem.eql(u8, it.label, "x"));
    try std.testing.expectEqual(@as(usize, 0), items.len);
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

// ── C5 — detail shows type ───────────────────────────────────────────────────

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
            // detail must contain the type name
            try std.testing.expect(it.detail.?.len > 0);
        }
    }
    try snap.assertCompletion(gpa, "completion_detail_type", source, cursor, items);
}

// ── C7 — cursor on numeric literal returns empty ──
//
// Ref: `do_not_show_completions_when_typing_a_number`
// The binding "result_2" exists and contains "2" in the name, but the cursor is over
// the literal `2` (not an identifier), so no items are suggested.
//
// The guard has two arms (`engine.zig`, "guard: cursor on a numeric literal"):
// Case B — the prefix is empty and the char *at* the cursor is a digit — is this
// test; Case A — the prefix itself starts with a digit, i.e. the caret is
// *after* the digit — is C7b below. One test per arm, so neither arm can rot
// unnoticed behind the other.

test "completion: caret before a number literal returns empty" {
    const gpa = std.testing.allocator;
    // "result_2" is a valid binding — intentionally contains "2" in the name
    // to confirm the guard runs before the prefix filter.
    const source =
        \\val result_2 = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // cursor before literal '2' (col 15 = char immediately before '2')
    // val result_2 = 2;
    // 0         1
    // 0123456789012345
    // col 15 = '2', source[offset] = '2' → numeric guard → empty
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
    try snap.assertCompletion(gpa, "completion_before_number", source, cursor, items);
}

// ── C7b — caret *after* a digit (Case A of the numeric guard) ──

test "completion: caret after a number literal returns empty" {
    const gpa = std.testing.allocator;
    // Same binding as C7: `result_2` would match the prefix `2` on a substring
    // filter, so an empty list here is the guard's doing, not the filter's.
    const source =
        \\val result_2 = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // val result_2 = 2;
    // 0         1
    // 0123456789012345
    // col 16 = right after the literal `2`, so `prefixAt` yields "2" → Case A.
    const cursor = h.pos(0, 16);
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

// ── C8 — cursor inside string literal returns empty ──
//
// Refs: `ignore_completions_inside_string`,
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
    // cursor at col 18 → offset 18 falls inside string → guard returns empty
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
    // col 8 = '"' (open), col 9 = '"' (close)
    // cursorInString scans up to offset 9 exclusive: processes col 8 → in_string = true → empty
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

// ── C9 — cursor inside string with "io." prefix returns empty ──
//
// Ref: `no_completions_in_constant_string`

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
    // cursor at col 12 → inside string → guard returns empty
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

// ── C10, C11, C12 — cursor inside comment returns empty ──
//
// Refs: `ignore_completions_in_empty_comment`,
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

    // line 1: //
    // 01
    // col 0 = '/', col 1 = '/', col 2 = (after //)
    // cursor at col 2 → inside comment → guard returns empty
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

    // line 1: // hello world
    // 01 234567890123456
    // col 0-1 = '//', col 7 = 'o' (middle of "world")
    // cursor at col 7 → inside comment → guard returns empty
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

    // line 1: // hello
    // 01 23456789
    // col 0-1 = '//', col 8 = end of line (after 'o')
    // cursor at col 8 → still on line with // → guard returns empty
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

// ── C6 — empty bindings ──────────────────────────────────────────────────────

test "completion: no bindings falls back to the module's own declarations" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
    ;

    // No typed bindings is the state of every module that does not type-check.
    // The answer is no longer empty: the module's declarations are read off the
    // token stream so the file's own names stay completable (front 14).
    const cursor = h.pos(0, 10);
    const items = try engine.completion(gpa, source, cursor, &.{});
    defer freeItems(gpa, items);

    // `x`, then the two declaration keywords the cursor may start here.
    try std.testing.expectEqual(@as(usize, 3), items.len);
    try std.testing.expectEqualStrings("x", items[0].label);
    try std.testing.expectEqualStrings("val", items[0].detail.?);
    try snap.assertCompletion(gpa, "completion_empty_bindings", source, cursor, items);
}

// ── C9 — dot-completion: struct/record fields ────────────────────────────────

test "completion: dot completes record fields" {
    const gpa = std.testing.allocator;
    const source =
        \\val Point = type(x: f64, y: f64);
        \\val origin = Point(x: 0.0, y: 0.0);
        \\val gx = origin.x;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val gx = origin." → dot is at col 15; cursor right after (col 16).
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

// ── C10 — dot-completion: enum variants ──────────────────────────────────────

test "completion: dot completes enum variants" {
    const gpa = std.testing.allocator;
    const source =
        \\val Status = type { Active, Inactive };
        \\val s = Status.Active;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val s = Status." → dot is at col 14; cursor right after (col 15).
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

// ── effect-wrapper receiver completion (decisions 120/122/128) ────────────────
//
// A value typed by an effect wrapper completes the members the prelude
// declares for it (`libs/std/src/builtins.d.bp`): `@Iterator` steps with
// `next`; `@Stream` steps with `next` and, through `extends Task`, maps with
// `map` / `then`; a `@Task` maps with `map` / `then`.

/// Compiles `decls` + `val it = <call>;`, completes `it.` on the next line and
/// snapshots the items under `slug`.
fn wrapperReceiver(slug: []const u8, comptime decls: []const u8, comptime call: []const u8) !void {
    const gpa = std.testing.allocator;
    // Bindings come from a valid compile; completion runs on the mid-edit buffer
    // (`it.`) just like the LSP serves completion against the last good index.
    const valid_source = decls ++ "\nval it = " ++ call ++ ";";
    const edit_source = valid_source ++ "\nval first = it.";

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const line: u32 = @intCast(std.mem.count(u8, edit_source, "\n"));
    const cursor = h.pos(line, 15);
    const items = try engine.completion(gpa, edit_source, cursor, bindings);
    defer {
        for (items) |it| {
            gpa.free(it.label);
            if (it.detail) |d| gpa.free(d);
        }
        gpa.free(items);
    }
    try snap.assertCompletion(gpa, slug, edit_source, cursor, items);
}

test "completion: @Iterator receiver offers next" {
    try wrapperReceiver("completion_receiver_iterator",
        \\fn gen() -> @Iterator<i32> { yield 1; }
    , "gen()");
}

test "completion: @Stream receiver offers next, map and then" {
    try wrapperReceiver("completion_receiver_stream",
        \\fn pulses() -> @Stream<i32> { yield 1; }
    , "pulses()");
}

test "completion: @Task receiver offers map and then" {
    try wrapperReceiver("completion_receiver_task",
        \\fn load() -> @Task<i32> { return 1; }
    , "load()");
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

/// Frees a completion list the way the server does (label, detail, insertText,
/// then the slice).
fn freeItems(gpa: std.mem.Allocator, items: []const proto.CompletionItem) void {
    for (items) |it| {
        gpa.free(it.label);
        if (it.detail) |d| gpa.free(d);
        if (it.insertText) |t| gpa.free(t);
    }
    gpa.free(items);
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

    // The gap this test used to document is closed (front 14): the fixture does
    // not type-check (`items` is unbound), so `bindings()` is empty — and the
    // fallback now reads the module's own declarations off the token stream, so
    // the enclosing `component` fn is offered too.
    try std.testing.expect(hasLabel(items, "component"));
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
        \\type PostService(name: string, count: i32)
        \\
        \\val other = 1;
        \\val usePost = PostService;
    ;

    var c = try h.compileEval(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse &[_]h.comptime_pipeline.TypedBinding{};

    // cursor at the start of `PostService` on the last line (empty prefix)
    const cursor = h.pos(8, 14);
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
    // `other` is an unrelated `val` declared before the cursor, never touched
    // by the decorator. The degraded path (the spliced re-analysis failed) keeps
    // every well-typed `val` binding since 06 N23, so `other` is completable.
    try std.testing.expect(hasLabel(items, "other"));
    // `usePost` is the binding this very line is defining — the cursor sits in
    // its initialiser, where the name is not in scope yet (front 14).
    try std.testing.expect(!hasLabel(items, "usePost"));
    try snap.assertCompletion(gpa, "completion_decorator_record", source, cursor, items);
}

// ── C10b — a variant is reached through the type, never through a value ──────
//
// `fn a(c: Color) -> Color { return c.Red; }` is
// `error: unknown field 'Red' on type 'Color'`, yet the list offered every
// variant there: a value receiver resolved to its named type and then reused
// the type-name member list unchanged (front 14 step 1).

test "completion: a value of an enum type offers its methods, not its variants" {
    const gpa = std.testing.allocator;
    const source =
        \\val Status = type { Active, Inactive, fn label(self: Self) -> string { return "s"; } };
        \\val s = Status.Active;
        \\val n = s.label();
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val n = s." → dot at col 9, cursor right after.
    const cursor = h.pos(2, 10);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer freeItems(gpa, items);

    var has_variant = false;
    var has_method = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "Active") or std.mem.eql(u8, it.label, "Inactive")) has_variant = true;
        if (std.mem.eql(u8, it.label, "label")) has_method = true;
    }
    try std.testing.expect(!has_variant);
    try std.testing.expect(has_method);
    try snap.assertCompletion(gpa, "completion_dot_enum_value_members", source, cursor, items);
}

test "completion: the enum type itself still offers its variants and methods" {
    const gpa = std.testing.allocator;
    const source =
        \\val Status = type { Active, Inactive, fn label(self: Self) -> string { return "s"; } };
        \\val s = Status.Active;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val s = Status." → dot at col 14, cursor right after.
    const cursor = h.pos(1, 15);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer freeItems(gpa, items);

    var has_active = false;
    var has_method = false;
    for (items) |it| {
        if (std.mem.eql(u8, it.label, "Active")) has_active = true;
        if (std.mem.eql(u8, it.label, "label")) has_method = true;
    }
    try std.testing.expect(has_active);
    try std.testing.expect(has_method);
}

// ── front 11 carve-out: a declaration's constructor binding is named in the 1.0.3 surface ──
//
// `completion` prints a binding's `detail` through `renderType`, and a
// `type`/`behavior` declaration's binding is *named* by `comptime/infer.zig`'s
// `buildRecordDeclName` / `buildEnumDeclName` / `buildInterfaceDeclName`, so
// the name is what the editor shows verbatim. Until 1.0.10-beta (C-19) those
// names spelled `record { … }` / `enum { … }` / `interface { … }` — surfaces
// that no longer parse. `completion_decorator_record` above pins the record;
// these two pin the enum and the behavior, so a builder cannot regress alone.

fn assertNoLegacyDeclSurface(items: []const proto.CompletionItem) !void {
    for (items) |it| {
        const d = it.detail orelse continue;
        try std.testing.expect(std.mem.indexOf(u8, d, "record {") == null);
        try std.testing.expect(std.mem.indexOf(u8, d, "enum {") == null);
        try std.testing.expect(std.mem.indexOf(u8, d, "interface {") == null);
        try std.testing.expect(std.mem.indexOf(u8, d, "struct {") == null);
    }
}

test "completion: an enum type's binding is detailed as `type Name { … }`" {
    const gpa = std.testing.allocator;
    const source =
        \\pub type Shape {
        \\    Circle(radius: f64),
        \\    Square,
        \\}
        \\val s = Shape.Square;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // "val s = Sh|ape.Square;" → prefix `Sh`.
    const cursor = h.pos(4, 10);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "Shape"));
    try assertNoLegacyDeclSurface(items);
    try snap.assertCompletion(gpa, "completion_type_enum_detail", source, cursor, items);
}

test "completion: a behavior's binding is detailed as `behavior Name<G> { … }`" {
    const gpa = std.testing.allocator;
    const source =
        \\pub behavior Mappable<T> {
        \\    fn map(self: Self<T>) -> Self<T>;
        \\}
        \\
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // A behavior is not a value (`val m = Mappable;` does not check), so the
    // cursor sits on the empty line after it: empty prefix, every binding.
    const cursor = h.pos(3, 0);
    const items = try engine.completion(gpa, source, cursor, bindings);
    defer freeItems(gpa, items);

    try std.testing.expect(hasLabel(items, "Mappable"));
    try assertNoLegacyDeclSurface(items);
    try snap.assertCompletion(gpa, "completion_behavior_detail", source, cursor, items);
}
