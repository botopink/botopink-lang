//! Decision 8's grammar — the parser half of front 06 rows N19–N22.
//!
//! One section per row, in the order the rows landed:
//!   N19 `unknown` (§2), N20 union types (§3), N21 `is` (§4), N22 `case` arms (§5).
//!
//! Spec: `specs/1.0.4-beta/08-review-backlog/decision-8-language.md` in the meta
//! workspace. A form here parses; what it *means* is the checker half's, so a
//! fixture that parses may still red in inference — that is expected until
//! N19–N22's checker rows land.

const std = @import("std");
const h = @import("helpers.zig");
const assertParser = h.assertParser;
const expectParseError = h.expectParseError;

// ── N19 — `unknown` (§2) ──────────────────────────────────────────────────────

test "decision 8 N19: unknown in every type position" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(x: unknown, xs: unknown[]) -> unknown {
        \\    return x;
        \\}
    );
}

test "decision 8 N19: unknown as a generic argument and an optional" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(b: Box<unknown>, o: ?unknown) -> i32 {
        \\    return 1;
        \\}
    );
}

test "decision 8 N19: unknown takes no type arguments" {
    try expectParseError(std.testing.allocator,
        \\error[unknown-takes-no-arguments]: `unknown` takes no type arguments
        \\ --> <test>:1:16
        \\  |
        \\1 | fn f(x: unknown<i32>) -> i32 { return 1; }
        \\  |                ^ write `unknown` alone
        \\  |
        \\  = hint: `unknown` is one type — anything, checked before it is used (`x is i32`). A container of it is written `unknown[]` or `Box<unknown>`.
        \\
        \\
    ,
        \\fn f(x: unknown<i32>) -> i32 { return 1; }
    );
}
