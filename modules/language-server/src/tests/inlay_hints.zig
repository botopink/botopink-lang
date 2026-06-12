/// Tests for `engine.inlayHints` — inferred `val` types, call-site parameter
/// names, and lambda parameter types.
/// Snapshots in: snapshots/lsp/inlay_hints_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

/// Compiles `source`, computes hints over the whole document, and snapshots.
fn run(gpa: std.mem.Allocator, slug: []const u8, source: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);

    const tokens = try h.tokenize(arena.allocator(), source);
    const bindings = c.bindings() orelse &.{};
    const whole = h.range(0, 0, 1000, 0);
    const hints = try engine.inlayHints(arena.allocator(), tokens, bindings, whole);

    try snap.assertInlayHints(gpa, slug, source, hints);
}

// ── IH1 — inferred type on `val n = 1 + 2` ────────────────────────────────────

test "inlayHints: inferred val type" {
    try run(std.testing.allocator, "inlay_hints_val_inferred", "val n = 1 + 2;");
}

// ── IH2 — annotated `val` suppresses the hint ─────────────────────────────────

test "inlayHints: annotated val is suppressed" {
    try run(std.testing.allocator, "inlay_hints_val_annotated", "val n: i32 = 1 + 2;");
}

// ── IH3 — parameter-name hints at a call site ─────────────────────────────────

test "inlayHints: parameter-name hints at call site" {
    const source =
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\val s = add(1, 2);
    ;
    try run(std.testing.allocator, "inlay_hints_call_params", source);
}

// ── IH4 — redundant parameter name is not repeated ────────────────────────────

test "inlayHints: bare-name argument suppresses its hint" {
    const source =
        \\fn greet(name: string) -> string { return name; }
        \\val name = "bob";
        \\val msg = greet(name);
    ;
    try run(std.testing.allocator, "inlay_hints_call_redundant", source);
}

// ── IH5 — lambda parameter types from the callee signature ────────────────────

test "inlayHints: lambda parameter types" {
    const source =
        \\fn apply(f: fn(n: i32) -> i32) -> i32 { return f(1); }
        \\val r = apply({ x -> x * x });
    ;
    try run(std.testing.allocator, "inlay_hints_lambda_params", source);
}
