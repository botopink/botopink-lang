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
        \\  = hint: Test the variant with `x is Shape` and read the payload in a `case` arm: `case x { Shape.Circle(radius: r) { … } }`. An optional is not a variant — a `?T` is read with `case x { null { … } v { … } }` (decision 54).
        \\
        \\
    ,
        \\fn f(a: unknown) -> bool { return a is Some(v); }
    );
}

// ── decision 54 — the optional's pattern form ────────────────────────────────

test "decision 54: a ?T is matched by null and a binder" {
    try assertParser(std.testing.allocator, @src(),
        \\fn describe(x: ?i32) -> string {
        \\    return case x { null { "absent" } v { "present" } };
        \\}
    );
}

// ── N22 — `case` arms (§5) ────────────────────────────────────────────────────

test "decision 8 N22: arms are Pattern { body }, with literals, a range and a binder" {
    try assertParser(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return case n {
        \\        0 { "zero" }
        \\        1...9 { "digit" }
        \\        i32 { m ->
        \\            val d = m * 2;
        \\            d + 1
        \\        }
        \\        _ { v -> "big" }
        \\    };
        \\}
    );
}

test "decision 8 N22: variant arms by path, by shorthand, by label and with a rest" {
    try assertParser(std.testing.allocator, @src(),
        \\fn area(s: Shape) -> i32 {
        \\    return case s {
        \\        Shape.Circle(r) { r }
        \\        .Rect(width: w, height: h) { w }
        \\        .Rect(width: w, ..) { w }
        \\        .Square(..) { 0 }
        \\        .None { 0 }
        \\    };
        \\}
    );
}

test "decision 8 N22: tuple patterns and a pattern nested in a variant" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f(p: #(i32, string)) -> string {
        \\    return case p {
        \\        #(0, s) { s }
        \\        #(n, "x") { "x" }
        \\        #(a, ..) { "rest" }
        \\        .Some(#(a, b)) { "pair" }
        \\        _ { "other" }
        \\    };
        \\}
    );
}

test "decision 8 N22: when guards, and the arrow arm the libraries still use" {
    try assertParser(std.testing.allocator, @src(),
        \\fn sign(x: i32) -> string {
        \\    return case x {
        \\        i32 when (x > 0) { "positive" }
        \\        _ when (x == 0) { v -> "zero" }
        \\        _ { "negative" }
        \\    };
        \\}
        \\fn legacy(o: Order) -> i32 {
        \\    return case o {
        \\        Lt -> -1;
        \\        x if x > 3 -> 1;
        \\        _ -> 0;
        \\    };
        \\}
    );
}

test "decision 8 N22: a name alone is not an arm" {
    try expectParseError(std.testing.allocator,
        \\error[case-bare-name-arm]: a name alone is not a pattern
        \\ --> <test>:3:9
        \\  |
        \\3 |         n { "other" }
        \\  |         ^ use _ { n -> … } to bind the matched value
        \\  |
        \\  = hint: An arm names a type (`i32`), a variant (`.Some(v)`), a literal (`0`), a range (`1...9`) or `_`. To give the matched value a name, bind it in the body: `_ { n -> … }`.
        \\
        \\
    ,
        \\fn f(x: i32) -> string {
        \\    return case x {
        \\        n { "other" }
        \\    };
        \\}
    );
}

test "decision 8 N22: a constant is not an arm" {
    try expectParseError(std.testing.allocator,
        \\error[case-constant-pattern]: a constant is not a pattern
        \\ --> <test>:3:9
        \\  |
        \\3 |         MAX { "max" }
        \\  |         ^^^ use _ when (x == MAX) { … } to compare with it
        \\  |
        \\  = hint: A pattern matches a shape; comparing with a constant is a guard. Write `_ when (x == MAX) { … }`.
        \\
        \\
    ,
        \\fn f(x: i32) -> string {
        \\    return case x {
        \\        MAX { "max" }
        \\        _ { "other" }
        \\    };
        \\}
    );
}

test "decision 8 N22: a tuple pattern takes no label" {
    try expectParseError(std.testing.allocator,
        \\error[pattern-tuple-label]: a tuple pattern is positional — it takes no label
        \\ --> <test>:3:11
        \\  |
        \\3 |         #(name: n, ..) { n }
        \\  |           ^^^^ drop the label and match by position
        \\  |
        \\  = hint: Labels are names for the compiler; a tuple is positional at run time. Write `#(n, ..)`, whatever the labels of its type.
        \\
        \\
    ,
        \\fn f(row: #(name: string, pop: i32)) -> string {
        \\    return case row {
        \\        #(name: n, ..) { n }
        \\    };
        \\}
    );
}

test "decision 8 N22: a pattern range is written with three dots" {
    try expectParseError(std.testing.allocator,
        \\error[pattern-range-exclusive]: `..` is iteration, not a pattern's range
        \\ --> <test>:3:10
        \\  |
        \\3 |         1..9 { "digit" }
        \\  |          ^^ write `...` — an inclusive range, both ends matched
        \\  |
        \\  = hint: `1...9` matches every value from 1 to 9; `..` belongs to `loop (0..n)` and slicing. An open end is a guard: `_ when (x < 0) { … }`.
        \\
        \\
    ,
        \\fn f(x: i32) -> string {
        \\    return case x {
        \\        1..9 { "digit" }
        \\        _ { "other" }
        \\    };
        \\}
    );
}

test "decision 8 N22: the rest comes last" {
    try expectParseError(std.testing.allocator,
        \\error[pattern-rest-not-last]: `..` stands for what the pattern does not name, so it comes last
        \\ --> <test>:3:15
        \\  |
        \\3 |         .Rect(.., width: w) { w }
        \\  |               ^^ move `..` to the end
        \\  |
        \\  = hint: Write `.Rect(width: w, ..)`: the fields you name first, then `..` once, at the end.
        \\
        \\
    ,
        \\fn f(s: Shape) -> i32 {
        \\    return case s {
        \\        .Rect(.., width: w) { w }
        \\    };
        \\}
    );
}
