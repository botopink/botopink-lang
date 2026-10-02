//! codegen: the BEAM assembly backend's own rows (front 03-beam). Every
//! fixture here assembles and runs the emitted module (`assertBeamRunLog`) —
//! a beam row whose other backends answer differently, or are still open,
//! is pinned by its RUN LOG without moving another backend's snapshot.

const std = @import("std");
const h = @import("helpers.zig");

// ── step 1 — a pattern in binding position, and list patterns ───────────────

test "beam: a list pattern binds every element and its spread's tail" {
    // A `case` arm's list pattern walked the elements without binding any of
    // them (`[a] -> a` answered `{unresolved_identifier, a}`) and, with no
    // spread, accepted any longer list. Each element is now tested or bound
    // from a copy of the subject, and the length is exact unless a spread
    // follows (`emitSubPattern`'s `.list`).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn describe(xs: i32[]) -> string {
        \\    return case xs {
        \\        [] -> "empty";
        \\        [a] -> "one " + a.toString();
        \\        [a, b] -> "two " + (a + b).toString();
        \\        [first, _, ..rest] -> "many " + first.toString() + " +" + rest.length.toString();
        \\    };
        \\}
        \\fn main() {
        \\    @print(describe([]));
        \\    @print(describe([7]));
        \\    @print(describe([2, 5]));
        \\    @print(describe([1, 2, 3, 4]));
        \\    @print(describe([9, 8, 7]));
        \\}
    ,
        \\empty
        \\one 7
        \\two 7
        \\many 1 +2
        \\many 9 +1
        \\
    , &.{ "{test, is_nil, ", "{get_list, " });
}

test "beam: a number in a list pattern is a test of that element" {
    // `[1, b]` takes a two-element list whose head is 1 only; `[2, 5]`
    // reaches the next arm. (commonJS answers `105` for `sum([2, 5])` — it
    // does not test the literal, `04-js`'s row — so this is a beam fixture,
    // not a four-backend snapshot.)
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn sum(xs: i32[]) -> i32 {
        \\    return case xs {
        \\        [] -> 0;
        \\        [a] -> a;
        \\        [1, b] -> 100 + b;
        \\        [a, b] -> a + b;
        \\        [a, _, ..rest] -> a + sum(rest);
        \\    };
        \\}
        \\fn main() {
        \\    @print(sum([]));
        \\    @print(sum([7]));
        \\    @print(sum([1, 5]));
        \\    @print(sum([2, 5]));
        \\    @print(sum([1, 2, 3, 4, 5]));
        \\}
    ,
        \\0
        \\7
        \\105
        \\7
        \\9
        \\
    , &.{"{test, is_eq, {f, "});
}

// ── a lambda a `case` arm answers ────────────────────────────────────────────

test "beam: a lambda literal that ends a case arm is the arm's value" {
    // `_ { { x -> x * n }; }` — the arm block's last statement is a lambda,
    // so it is the value the `case` answers (a statement-position block does
    // not parse). It ran as a statement, the arm answered `ok`, and applying
    // it was `{badfun, ok}` (01-checker's `test/case_arm_lambda_value`).
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn scaleBy(n: i32) -> fn(x: i32) -> i32 {
        \\    val f = case n {
        \\        _ {
        \\            { x -> x * n };
        \\        }
        \\    };
        \\    return f;
        \\}
        \\fn main() {
        \\    @print(scaleBy(3)(10));
        \\}
    , "30\n", &.{"{make_fun3, "});
}
