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
