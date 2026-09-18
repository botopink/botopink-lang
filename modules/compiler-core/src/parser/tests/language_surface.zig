//! Front 15 — the language surface: the forms the documents write, against the
//! grammar that has to accept them.
//!
//! Spec: `specs/1.0.5-beta/15-language-surface/` in the meta workspace
//! (`README.md`, `seven-forms.md`, `surface-gaps.md`).
//!
//! One section per row. A row that **hoists a rule** carries its regressions
//! beside its new forms — the point of hoisting is that the arms which already
//! worked keep working, so the two are asserted together. A form here parses;
//! what it *means* is the checker's and the backends'.

const std = @import("std");
const h = @import("helpers.zig");
const assertParser = h.assertParser;
const expectParseError = h.expectParseError;

// ── R1 — the array suffix is the type's, not the arm's ───────────────────────
//
// `parseBaseTypeRef` applied the `T[]` wrap at the end of its named-type path
// and again, copied, inside the `unknown` arm; the tuple arm and the
// builtin-generic arm returned before either. The suffix now runs once, at the
// single exit, so every arm inherits it.

test "surface R1: an array of a labeled tuple, and of an unlabeled one" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(rows: #(a: i32, b: string)[], pairs: #(i32, string)[]) -> i32 {
        \\    return rows.length;
        \\}
    );
}

test "surface R1: an array of a builtin generic" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: @Result<i32, string>[]) -> i32 {
        \\    return xs.length;
        \\}
    );
}

test "surface R1: a parenthesised type, and an array of a union" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(x: (i32), xs: (i32 | string)[], ys: (i32 | string)[][]) -> i32 {
        \\    return xs.length;
        \\}
    );
}

test "surface R1: the arms that already carried the suffix still do" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(
        \\    a: unknown[],
        \\    b: Box<i32>[],
        \\    c: i32[][],
        \\    d: ?i32[],
        \\    e: fn(x: i32) -> i32[],
        \\    g: i32 | string[],
        \\) -> i32 {
        \\    return 1;
        \\}
    );
}

// ── R2 — one postfix chain, reached from every receiver ──────────────────────
//
// The chain existed in four copies. `parsePrimary`'s grouped arm reached none
// of them and `return`ed, so `("ab").length` was `Unexpected token` at the `.`;
// and no copy had a `(` link, so `adder(3)(4)` was `Unexpected token` at the
// second `(`. The identical copy in `parsePrimary`'s identifier path is gone;
// the one in `parseExpr`'s call path stays (it consumes trailing lambdas, which
// `parsePostfixChain` must not) and carries the same `(` link.

test "surface R2: a method on a parenthesised receiver" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: i32, b: i32) -> i32 {
        \\    val n = ("ab").length;
        \\    val s = (a == b).toString();
        \\    val m = (a + b).toString().length;
        \\    return n + m;
        \\}
    );
}

test "surface R2: calling what a call returned" {
    try assertParser(std.testing.allocator, @src(),
        \\fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
        \\fn f() -> i32 {
        \\    val a = adder(3)(4);
        \\    val b = adder(3)(4)(5);
        \\    return a + b;
        \\}
    );
}

test "surface R2: the receivers that already chained still do" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32[], r: Box) -> i32 {
        \\    val a = [1, 2].length;
        \\    val b = "x".toUpperCase().length;
        \\    val c = r.get().length;
        \\    val d = r?.get();
        \\    return a + b + c;
        \\}
    );
}

// ── R3 — a number is a receiver ──────────────────────────────────────────────
//
// `lexer.zig`'s number scanner ate the `.` of `42.toString()`, and the number
// arm of `parsePrimary` did not chain. Both halves are needed: the lexer makes
// the tokens, the parser makes the link.

test "surface R3: a method on a number literal" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> i32 {
        \\    val a = 42.toString().length;
        \\    val b = 3.0.toString().length;
        \\    return a + b;
        \\}
    );
}

test "surface R3: the range and the float forms are unchanged" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> f64 {
        \\    var s = 0;
        \\    loop (0..4) { i -> s = s + i; };
        \\    val a = 1.5;
        \\    val b = 1_000;
        \\    val c = 1e10;
        \\    val d = 0xFF;
        \\    val e = 1_000.5;
        \\    return a;
        \\}
    );
}

// ── R4 — one block body, reached by every block ──────────────────────────────
//
// `parseBlock` grew `handleComments` and `trackEmptyLines`; five blocks never
// reached it, each carrying its own loop written before the options existed.
// A `//` comment was a parse error in an `if` then-branch, a lambda body, a
// `loop` body and a trailing lambda, while the same comment in a fn body, a
// `test` body or an `if` else-branch parsed.

test "surface R4: a comment and a blank line inside an if branch" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(c: bool) -> i32 {
        \\    if (c) {
        \\        // the then-branch
        \\        println("a");
        \\
        \\        println("b");
        \\    } else {
        \\        // the else-branch
        \\        println("c");
        \\    };
        \\    return 1;
        \\}
    );
}

test "surface R4: a comment inside a loop body and a lambda body" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() -> i32 {
        \\    loop ([1, 2]) { x ->
        \\        // a loop body is not a lambda body — it has its own block
        \\        println("a");
        \\
        \\        println("b");
        \\    };
        \\    val g = { x ->
        \\        // a standalone lambda
        \\        x + 1
        \\    };
        \\    return g(1);
        \\}
    );
}

test "surface R4: an if branch that binds its value still binds it" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(v: ?i32) -> i32 {
        \\    if (v) { x ->
        \\        // the binding is the block's prologue, the comment is its body
        \\        println("has");
        \\    };
        \\    return 1;
        \\}
    );
}
