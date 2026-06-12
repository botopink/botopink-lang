/// Testes de hover — cobre `engine.hover`.
/// Snapshots em: snapshots/lsp/hover_*.snap.md
///
/// Analogia Gleam: tests/hover.rs (128 testes / 127 snapshots).
/// Formato (inspirado em Gleam):
///   ----- SOURCE
///   ```botopink
///   val x = 42;
///   ```
///   ----- HOVER at (line 0, char 4)
///   kind: markdown
///   ```botopink
///   x : i32
///   ```
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");
const proto = @import("../protocol.zig");

// ── H1 — val inteiro ──────────────────────────────────────────────────────────

test "hover: val integer shows inferred type i32" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_val_integer", source, h.pos(0, 4), result);
}

// ── H2 — val string ───────────────────────────────────────────────────────────

test "hover: val string shows type string" {
    const gpa = std.testing.allocator;
    const source =
        \\val greeting = "hello";
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_val_string", source, h.pos(0, 4), result);
}

// ── H3 — keyword não tem hover ────────────────────────────────────────────────

test "hover: keyword val returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // col 0 = 'v' em 'val'
    const result = try engine.hover(gpa, source, h.pos(0, 0), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_keyword_null", source, h.pos(0, 0), result);
}

// ── H4 — fn polimórfica ───────────────────────────────────────────────────────

test "hover: fn binding shows function type" {
    const gpa = std.testing.allocator;
    const source =
        \\fn f(a: i32) { return a; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // 'f' na col 3
    const result = try engine.hover(gpa, source, h.pos(0, 3), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_fn_polymorphic", source, h.pos(0, 3), result);
}

// ── H5 — fn anotada ───────────────────────────────────────────────────────────

test "hover: annotated fn shows concrete parameter types" {
    const gpa = std.testing.allocator;
    const source =
        \\fn add(x: i32, y: i32) { return x; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    const result = try engine.hover(gpa, source, h.pos(0, 3), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_fn_annotated", source, h.pos(0, 3), result);
}

// ── H6 — segunda linha ────────────────────────────────────────────────────────

test "hover: val on second line" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 1;
        \\val y = 2;
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // 'y' na linha 1, col 4
    const result = try engine.hover(gpa, source, h.pos(1, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_second_line", source, h.pos(1, 4), result);
}

// ── H7 — sem bindings ─────────────────────────────────────────────────────────

test "hover: empty bindings returns null" {
    const gpa = std.testing.allocator;
    const source =
        \\val x = 42;
    ;

    const result = try engine.hover(gpa, source, h.pos(0, 4), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_empty_bindings", source, h.pos(0, 4), result);
}

// ── async / generators (*fn) ──────────────────────────────────────────────────

test "hover: star fn shows async marker and element type" {
    const gpa = std.testing.allocator;
    const source =
        \\*fn counter() -> @Iterator<i32> :gen { yield 1; }
    ;

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // 'counter' starts at col 4 (`*fn ` prefix).
    const result = try engine.hover(gpa, source, h.pos(0, 4), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try snap.assertHover(gpa, "hover_star_fn", source, h.pos(0, 4), result);
}

// ── H-std — hover on a qualified std module member ────────────────────────────

test "hover: std module fn shows its signature" {
    const gpa = std.testing.allocator;
    const source =
        \\import {order} from "std";
        \\val n = order.toInt(order.lt());
    ;
    // Cursor on `toInt` in `order.toInt` (line 1, char 14).
    const result = try engine.hover(gpa, source, h.pos(1, 14), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "fn toInt") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "std/order") != null);
    try snap.assertHover(gpa, "hover_std_module_fn", source, h.pos(1, 14), result);
}

// NOTE: the "external declare fn in std module" hover test was retired with the
// stdlib-interface migration — `io` was dissolved and `@[external]` declarations
// now live in `primitives.d.bp` (flattened into the global env, not an importable
// std module). Re-add once an importable module carries an `@[external]` declare
// fn again (tasks/v0.beta.4 carryover).

// ── H-F4 — hover on an interface method invoked on a builtin receiver ──────────

test "hover: interface method on integer receiver shows signature" {
    const gpa = std.testing.allocator;
    const source =
        \\val s = 42.abs();
    ;
    // Cursor on `abs` in `42.abs` (line 0, char 12).
    const result = try engine.hover(gpa, source, h.pos(0, 12), &.{});
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "fn abs") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "interface I32") != null);
    try snap.assertHover(gpa, "hover_interface_method", source, h.pos(0, 12), result);
}

test "hover: interface method on array receiver shows signature" {
    const gpa = std.testing.allocator;
    const valid_source =
        \\val xs = [1, 2, 3];
    ;
    const source =
        \\val xs = [1, 2, 3];
        \\val y = xs.filter({ x -> true });
    ;

    var c = try h.compile(gpa, valid_source);
    defer c.deinit(gpa);
    const bindings = c.bindings() orelse return error.CompileFailed;

    // Cursor on `filter` in `xs.filter` (line 1, char 12).
    const result = try engine.hover(gpa, source, h.pos(1, 12), bindings);
    defer if (result) |hov| gpa.free(hov.contents.value);

    try std.testing.expect(result != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "fn filter") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.?.contents.value, "interface Array") != null);
    try snap.assertHover(gpa, "hover_interface_method_array", source, h.pos(1, 12), result);
}
