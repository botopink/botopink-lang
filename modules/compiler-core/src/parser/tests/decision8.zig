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

// ── N20 — union types (§3) ────────────────────────────────────────────────────

test "decision 8 N20: a union type in an annotation, a parameter and a return" {
    try assertParser(std.testing.allocator, @src(),
        \\fn size(v: i32 | string) -> i32 | string {
        \\    val w: i32 | string | bool = v;
        \\    return w;
        \\}
    );
}

test "decision 8 N20: | binds looser than [] and reaches into generic arguments" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(xs: i32 | string[], b: Box<i32 | string>, o: ?i32 | string) -> i32 {
        \\    return 1;
        \\}
    );
}

test "decision 8 N20: a union member is missing after the bar" {
    try expectParseError(std.testing.allocator,
        \\error[union-member-missing]: a union type needs another type after `|`
        \\ --> <test>:1:13
        \\  |
        \\1 | fn f(x: i32 | ) -> i32 { return 1; }
        \\  |             ^ add the next member here
        \\  |
        \\  = hint: A union is written `i32 | string`, each member a complete type; `(i32 | string)[]` is an array of the union, `i32 | string[]` an `i32` or an array of `string`.
        \\
        \\
    ,
        \\fn f(x: i32 | ) -> i32 { return 1; }
    );
}

test "decision 8 N20: the type meta-kind still separates its constraints with a bar" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(comptime T: type string | i32) -> i32 {
        \\    return 1;
        \\}
    );
}

// ── N21 — `is` as an expression (§4) ──────────────────────────────────────────

test "decision 8 N21: is tests a value in an if condition and in a binding" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: unknown) -> bool {
        \\    if (a is i32) { @print(a); };
        \\    val b = a is string;
        \\    return b;
        \\}
    );
}

test "decision 8 N21: is binds tighter than every binary operator" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: unknown, b: bool) -> bool {
        \\    return a is i32 == b;
        \\}
    );
}

test "decision 8 N21: the tested type may be a tuple, a generic or a union" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(a: unknown) -> bool {
        \\    val t = a is #(i32, string);
        \\    val g = a is Box<unknown>;
        \\    val u = a is i32 | string;
        \\    return t;
        \\}
    );
}

test "decision 8 N21: is without a type" {
    try expectParseError(std.testing.allocator,
        \\error[is-missing-type]: `is` needs a type to test the value against
        \\ --> <test>:1:37
        \\  |
        \\1 | fn f(a: unknown) -> bool { return a is; }
        \\  |                                     ^^ add the type here
        \\  |
        \\  = hint: `x is i32` answers whether the value is an `i32` right now; inside the block that it guards, `x` is that type.
        \\
        \\
    ,
        \\fn f(a: unknown) -> bool { return a is; }
    );
}

test "decision 8 N21: is does not bind a variant payload" {
    try expectParseError(std.testing.allocator,
        \\error[is-variant-binding]: `is` tests a type; it does not bind a variant's payload
        \\ --> <test>:1:44
        \\  |
        \\1 | fn f(a: unknown) -> bool { return a is Some(v); }
        \\  |                                            ^ remove the payload pattern
        \\  |
        \\  = hint: Test the variant with `x is Option` and read the payload in a `case` arm: `case x { Option.Some(value: v) { … } }`.
        \\
        \\
    ,
        \\fn f(a: unknown) -> bool { return a is Some(v); }
    );
}
