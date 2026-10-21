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
// `method [declaration]`, and `function [declaration,async]` for the fn whose
// return is `@Iter<i32>` (whose `:gen` label is syntax, not a binding).

test "semanticTokens: free fn, interface method, and effect fn distinguished" {
    const source =
        \\fn free(a: i32) -> i32 { return a; }
        \\behavior Greeter { fn greet(self: Self) -> string; }
        \\iter fn counter() -> Iter<i32> :gen { yield 1; }
    ;
    try run(std.testing.allocator, "semantic_tokens_fn_kinds", source);
}

// ── ST3b — the `async` modifier comes from the return wrapper ────────────────
//
// Decision 118: the return is the effect. Each of the five wrappers written as
// the outermost return (`@Result`, `@Async`, `@Component`, `@Iter`,
// `@AsyncIter`) marks the fn `async`, generic or not, method or not; a plain
// return, a wrapper nested under a non-wrapper, and a parameter typed by a
// wrapper do not.

test "semanticTokens: async modifier follows each effect return wrapper" {
    const source =
        \\val Element = type() implement Renderable
        \\fn plain(a: i32) -> i32 { return a; }
        \\fn fails(a: i32) -> Result<i32, string> { return a; }
        \\async fn waits<T>(a: T) -> Async<T> { return a; }
        \\component fn hook(a: i32) -> Component<i32> { return a; }
        \\iter fn seq() -> Iter<i32> { yield 1; }
        \\async iter fn pulses() -> AsyncIter<i32> { yield 1; }
        \\fn takes(t: Async<i32>) -> i32[] { return [1]; }
        \\fn opt() -> ?Async<i32> { return null; }
        \\type Box(v: i32) {
        \\    async fn load(self: Self) -> Async<i32> { return self.v; }
        \\}
    ;
    try run(std.testing.allocator, "semantic_tokens_effect_returns", source);
}

// ── ST3c — contextual effect keywords and loop labels ────────────────────────
//
// `async` is a keyword only right before `{`; `iter` / `stream` only right
// before `loop` / `while` / `for` (decisions 124, 125). Elsewhere they stay
// names: `g.iter()`, `val stream = 1`, `http.stream(…)`, `import {async} from
// "std"`, `async.allOf(…)`. A loop label (`for :outer`, `break :outer`) is
// syntax, painted like the fn label.

test "semanticTokens: contextual async / iter / stream and loop labels" {
    const source =
        \\import {async} from "std";
        \\async fn f(xs: i32[], g: Grid, http: Http) -> Async<i32> {
        \\    val t = async { return 1; };
        \\    val all = async.allOf([t]);
        \\    val a = iter loop { yield 1; break; };
        \\    val b = iter for :outer (xs) { x -> if (x > 1) { break :outer; }; yield x; };
        \\    val c = stream while (true) { yield 1; };
        \\    val d = stream for await (s) { x -> yield x; };
        \\    val stream = 1;
        \\    val iter = g.iter();
        \\    val body = http.stream(stream);
        \\    return await t;
        \\}
    ;
    try run(std.testing.allocator, "semantic_tokens_contextual_keywords", source);
}

// Decision 553 (1) — the body markers `async`, `iter`, `async iter` and
// `component` are keywords right before `fn` or right after a lambda's `{`
// (decision 584); elsewhere the words stay names (`val component = 1`,
// `val iter = 2`).
test "semanticTokens: body markers" {
    const source =
        \\async fn one() -> Async<i32> { return 1; }
        \\iter fn two() -> Iter<i32> { yield 2; }
        \\async iter fn three() -> AsyncIter<i32> { yield 3; }
        \\component fn Four() -> Component<i32> { return 4; }
        \\async fn f() -> Async<i32> {
        \\    val g: fn(x: i32) -> Async<i32> = { async x -> await one() };
        \\    val component = 1;
        \\    val iter = 2;
        \\    return await g(component + iter);
        \\}
    ;
    try run(std.testing.allocator, "semantic_tokens_body_markers", source);
}

// Decision 811 (1) — `opaque` is a keyword right before `type`; elsewhere the
// word stays a name (`val opaque = 1`).
test "semanticTokens: the opaque modifier" {
    const source =
        \\pub opaque type Token(v: i32) {
        \\    pub fn of(v: i32) -> Token { return Token(v: v); }
        \\}
        \\val opaque = 1;
    ;
    try run(std.testing.allocator, "semantic_tokens_opaque_modifier", source);
}

// ── ST4 — builtin @Type classified as type + defaultLibrary ───────────────────

test "semanticTokens: builtin @Type is type + defaultLibrary" {
    const source =
        \\fn parse(x: i32) -> Result<i32, string> { return @ok(x); }
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
// `Point` declares `norm`: without it the module no longer compiles (06 C9 —
// calling a method a nominal type does not declare reds), and a non-compiling
// module makes the classifier paint `Point` `variable` instead of `type`.
test "semanticTokens: method call vs property access" {
    const source =
        \\val Point = type(x: i32, y: i32) {
        \\    fn norm(self: Self) -> i32 { return self.x + self.y; }
        \\};
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
        \\fn f(a: i32, b: unknown, c: never) -> void { }
    ;
    try run(std.testing.allocator, "semantic_tokens_builtin_type_list", source);
}
