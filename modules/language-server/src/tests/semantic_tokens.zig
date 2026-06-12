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

// ── ST3 — free fn vs interface method vs *fn distinguished ────────────────────

test "semanticTokens: free fn, interface method, and *fn distinguished" {
    const source =
        \\fn free(a: i32) -> i32 { return a; }
        \\interface Greeter { fn greet(self: Self) -> string }
        \\*fn counter() -> @Iterator<i32> :gen { yield 1; }
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
        \\val Color = enum { Red, Green, Blue };
        \\val Point = record { x: i32, y: i32 };
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

test "semanticTokens: method call vs property access" {
    const source =
        \\fn dist(p: i32) -> i32 { return p.distance(); }
    ;
    try run(std.testing.allocator, "semantic_tokens_member_access", source);
}
