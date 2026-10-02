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

// ── a behavior's adopted `default fn` ────────────────────────────────────────

test "beam: a type adopts its behavior's default fns as methods of its module" {
    // `Sq(s: 3).twice()` — `twice` is a `default fn` of `Shape`, which `Sq`
    // implements without declaring it. The type's module had no such
    // function and the call aborted `{unresolved_method, twice, 1}`; the
    // default is now emitted into `Sq`'s module beside `area`
    // (`adoptedDefaults`), one default calling another, a type's own method
    // winning over the default, and a behavior-typed receiver dispatching on
    // the value. Two types adopt `twice`, so a call names the method and the
    // value's module answers it (`lowerDynamicMethodCall`). (erlang refuses this module — `function twice/1 undefined`
    // — `02-erlang`'s row; commonJS prints the same lines.)
    try h.assertBeamRunLog(std.testing.allocator,
        \\behavior Shape {
        \\    fn area(self: Self) -> i32;
        \\    default fn twice(self: Self) -> i32 {
        \\        return self.area() * 2;
        \\    }
        \\    default fn label(self: Self) -> string {
        \\        return "area " + self.twice().toString();
        \\    }
        \\}
        \\type Sq(s: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.s * self.s;
        \\    }
        \\}
        \\type Rect(w: i32, h: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.w * self.h;
        \\    }
        \\    fn label(self: Self) -> string {
        \\        return "rect";
        \\    }
        \\}
        \\fn show(x: Shape) -> i32 {
        \\    return x.twice();
        \\}
        \\fn main() {
        \\    @print(Sq(s: 3).twice());
        \\    @print(Sq(s: 3).label());
        \\    @print(Rect(w: 2, h: 5).twice());
        \\    @print(Rect(w: 2, h: 5).label());
        \\    @print(show(Sq(s: 1)));
        \\    @print(show(Rect(w: 1, h: 7)));
        \\}
    ,
        \\18
        \\area 18
        \\20
        \\rect
        \\2
        \\14
        \\
    , &.{"{move, {atom, twice}, {x, 1}}"});
}

// ── `?.` through a tuple label ───────────────────────────────────────────────

test "beam: ?. on an absent tuple element answers absent before the label is read" {
    // Decision 45 rewrites `?.b` to the element's position (`._1`), and the
    // tuple-index read came before the `?.` test: `es.at(0)?.b` read
    // `element(2, undefined)` and raised `badarg`. (wasm traps on the absent
    // half — `05-wasm`'s row — so this is a beam fixture.)
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn rows() -> #(a: i32, b: string)[] {
        \\    return [#(1, "x"), #(2, "y")];
        \\}
        \\fn main() {
        \\    val es: #(a: i32, b: string)[] = [];
        \\    @print(es.at(0)?.b ?? "none");
        \\    @print(es.at(3)?.a ?? 0);
        \\    val rs = rows();
        \\    @print(rs.at(1)?.b ?? "none");
        \\    @print(rs.at(5)?.a ?? -1);
        \\}
    ,
        \\none
        \\0
        \\y
        \\-1
        \\
    , &.{"{extfunc, erlang, element, 2}"});
}
