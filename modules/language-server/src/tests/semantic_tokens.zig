/// Tests for `engine.semanticTokens` — token classification driven by lexical
/// kind, structural nesting, and the typed top-level bindings.
/// Snapshots in: snapshots/lsp/semantic_tokens_*.snap.md
const std = @import("std");
const h = @import("./helpers.zig");
const snap = @import("./snapshot.zig");
const engine = @import("../engine.zig");

/// Compiles `source`, classifies it, and snapshots the result under `slug`.
fn run(gpa: std.mem.Allocator, slug: []const u8, source: []const u8) !void {
    var arena = std.heap.ArenaAllocator.init(gpa);
    defer arena.deinit();

    var c = try h.compile(gpa, source);
    defer c.deinit(gpa);

    const tokens = try h.tokenize(arena.allocator(), source);
    const bindings = c.bindings() orelse &.{};
    const toks = try engine.semanticTokens(arena.allocator(), tokens, bindings);

    try snap.assertSemanticTokens(gpa, slug, source, toks);
}

// ── ST1 — empty source ────────────────────────────────────────────────────────

test "semanticTokens: empty source" {
    try run(std.testing.allocator, "semantic_tokens_empty", "");
}

// ── ST2 — val with inferred type → variable + declaration ─────────────────────

test "semanticTokens: val binding is a variable declaration" {
    const source =
        \\val n = 1 + 2;
    ;
    try run(std.testing.allocator, "semantic_tokens_val", source);
}

// ── ST3 — free fn vs interface method vs effect fn distinguished ─────────────
//
// Three kinds, three classifications: `function [declaration]`,
// `method [declaration]`, and `function [declaration,async]` for the
// `#[@iterator]` fn (whose `:gen` label is syntax, not a binding).

test "semanticTokens: free fn, interface method, and effect fn distinguished" {
    const source =
        \\fn free(a: i32) -> i32 { return a; }
        \\behavior Greeter { fn greet(self: Self) -> string; }
        \\#[@iterator]
        \\fn counter() -> @Iterator<i32> :gen { yield 1; }
    ;
    try run(std.testing.allocator, "semantic_tokens_fn_kinds", source);
}

// ── ST4 — builtin @Type classified as type + defaultLibrary ───────────────────

test "semanticTokens: builtin @Type is type + defaultLibrary" {
    const source =
        \\fn parse(x: i32) -> @Result<i32, string> { return @ok(x); }
    ;
    try run(std.testing.allocator, "semantic_tokens_builtin_type", source);
}

// ── ST5 — enum members and record/struct types ────────────────────────────────

test "semanticTokens: enum variants and record fields" {
    const source =
        \\val Color = type { Red, Green, Blue };
        \\val Point = type(x: i32, y: i32);
    ;
    try run(std.testing.allocator, "semantic_tokens_enum_record", source);
}

// ── ST6 — comments and keywords ───────────────────────────────────────────────

test "semanticTokens: comments and keywords" {
    const source =
        \\/// doc comment
        \\val flag = true;
    ;
    try run(std.testing.allocator, "semantic_tokens_comment_keyword", source);
}

// ── ST7 — receiver method call vs property access ─────────────────────────────

// Both halves must appear: `p.x` is a property access and `p.norm()` a method
// call. With an `i32` receiver and a call-only body the `property` branch of the
// classifier was never reached, so the test's name outran what it checked.
test "semanticTokens: method call vs property access" {
    const source =
        \\val Point = type(x: i32, y: i32);
        \\fn dist(p: Point) -> i32 { return p.x + p.norm(); }
    ;
    try run(std.testing.allocator, "semantic_tokens_member_access", source);
}

// ── ST-14 — the builtin-type list is the checker's ────────────────────────────
//
// `type [defaultLibrary]` claims a name is a standard-library type. `char`,
// `byte` and `never` were painted that way and `Env.registerBuiltins` knows
// none of them; `unknown` is decision 8 §2's type and was painted as nothing.
// The fixture puts a real builtin, decision 8's `unknown`, and one of the three
// invented names side by side, so the snapshot shows all three verdicts at once.

test "semanticTokens: unknown is a builtin type, an invented one is not" {
    const source =
        \\fn f(a: i32, b: unknown, c: never) { }
    ;
    try run(std.testing.allocator, "semantic_tokens_builtin_type_list", source);
}
