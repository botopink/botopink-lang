//! comptime: type & generic inference (split from tests.zig).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

test "infer: type ---- arg satisfies single constraint" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn render(comptime tag: type string, props: i32) -> i32 {
        \\    return props;
        \\}
        \\val a = render("div", 1);
    );
}

test "infer: type ---- arg satisfies one of multiple constraints" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val s = coerce("s", 0);
        \\val i = coerce(7, 0);
        \\val b = coerce(true, 0);
    );
}

test "infer: type ---- no constraint accepts any type" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn id(comptime t: type, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val a = id("s", 0);
        \\val b = id(3.14, 0);
        \\val c = id(true, 0);
    );
}

test "infer: generic record Pair<A, B>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Pair = record <A, B> { first: A, second: B };
        \\val p = Pair(first: 42, second: "hello");
        \\@print(p);
    );
}

test "infer: generic record Triple<A, B, C>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Triple = record <A, B, C> { first: A, second: B, third: C };
        \\val t = Triple(first: 1, second: "x", third: 3.14);
    );
}

test "infer: generic struct Box<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = struct <T> {
        \\    value: T = todo,
        \\};
        \\val b = Box(42);
    );
}

test "infer: generic enum Option<T> ---- unit and payload variants" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    None,
        \\    Some(value: T),
        \\};
        \\val n = Option.None;
        \\val s = Option.Some(value: 42);
    );
}

test "infer: generic enum Result<T> with Ok and Err" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T> {
        \\    Ok(value: T),
        \\    Err(message: string),
        \\};
        \\pub fn isOk(r: Result) -> bool {
        \\    return true;
        \\}
        \\val r = Result.Ok(value: 42);
        \\val ok = isOk(r);
    );
}

test "infer: pub fn generic ---- identity<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\val r = identity(42);
    );
}

test "infer: pub fn generic with two type params<T, R>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn transform<T, R>(x: T, y: R) -> R {
        \\    return y;
        \\}
        \\val result = transform(42, "mapped");
    );
}

test "infer: generic fn ---- two calls with different types in same scope" {
    // Regression (stdlib-gleam known gap #6): each call site must get a fresh
    // instantiation of the fn's generic vars — the first call must not lock
    // `T` for the second.
    try h.assertInfersOk(std.testing.allocator,
        \\fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\fn main() {
        \\    val a: i32 = identity(42);
        \\    val b: string = identity("hi");
        \\}
    );
}

test "infer: generic fn ---- referenced as a value instantiates fresh vars" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\fn main() {
        \\    val f = identity;
        \\    val g = identity;
        \\    val a: i32 = f(1);
        \\    val s: string = g("x");
        \\}
    );
}

test "infer: generic interface Container<T>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Container = interface <T> {
        \\    fn fetch(self: Self) -> T;
        \\    fn store(self: Self, value: T);
        \\}
    );
}

test "infer: @Expr builtin type ---- declaration with bounded return typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn identity(comptime template: @Expr<string>) -> @Expr<string> {
        \\    return template;
        \\}
        \\fn main() {
        \\    @print("ok");
        \\}
    );
}

test "infer: generic record ---- per-use instantiation does not collapse" {
    // Regression: the registered cells of `Box<A, B>` must NOT unify globally.
    // `swap` re-constructs with swapped fields (would bind A := B without
    // per-call-site constructor instantiation + per-instance field typing).
    try h.assertInfersOk(std.testing.allocator,
        \\record Box<A, B> { first: A, second: B }
        \\
        \\fn swap<A, B>(p: Box<A, B>) -> Box<B, A> {
        \\    return Box(first: p.second, second: p.first);
        \\}
        \\
        \\fn main() {
        \\    val b = Box(first: 1, second: "one");
        \\    val s = swap(b);
        \\    val n: i32 = s.second;
        \\    val t: string = s.first;
        \\}
    );
}

test "infer error: generic record ---- instantiated field type still checks" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record Box<A, B> { first: A, second: B }
        \\
        \\fn main() {
        \\    val b = Box(first: 1, second: "one");
        \\    val bad: i32 = b.second;
        \\}
    );
}

// ── net-new (v0.beta.13 · A4): generics / recursion / context ────────────────

// A generic RECORD instantiates independently at two concrete types in the same
// scope: `unbox(Box<i32>)` and `unbox(Box<string>)` each bind `T` fresh.
test "infer: net-new ---- generic record at two concrete types" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Box<T> { item: T }
        \\fn unbox<T>(b: Box<T>) -> T { return b.item; }
        \\fn main() {
        \\    val a: i32 = unbox(Box(item: 7));
        \\    val s: string = unbox(Box(item: "hi"));
        \\}
    );
}

// Recursion through a generic data type: a `Tree<T>` sum folds the two child
// `Tree<i32>` subtrees, so the recursive call type-checks at the instantiated
// element type.
test "infer: net-new ---- recursion through a generic data type" {
    try h.assertInfersOk(std.testing.allocator,
        \\enum Tree<T> {
        \\    Leaf(value: T),
        \\    Node(left: Tree<T>, right: Tree<T>),
        \\}
        \\fn sum(t: Tree<i32>) -> i32 {
        \\    return case t {
        \\        Leaf(v) -> v;
        \\        Node(l, r) -> sum(l) + sum(r);
        \\    };
        \\}
    );
}

// A generic fn's return type is inferred SOLELY from the call's usage context:
// `make()` has no value argument fixing `T`, so the `val: i32`/`val: string`
// annotations are the only source — each call site instantiates fresh.
test "infer: net-new ---- generic return inferred from usage context" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn make<T>() -> T { @todo(); }
        \\fn main() {
        \\    val n: i32 = make();
        \\    val s: string = make();
        \\}
    );
}

// An inline `test {}` block inside a module that also defines a generic fn
// resolves (historic `.generic` TypeError gap): the test body instantiates the
// generic call and the `assert` typechecks.
test "infer: net-new ---- inline test in a generic module resolves" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Box<T> { item: T }
        \\fn unbox<T>(b: Box<T>) -> T { return b.item; }
        \\test "unbox round-trips" {
        \\    val n = unbox(Box(item: 7));
        \\    assert n == 7;
        \\}
    );
}

// @Context composition across THREE hook layers stays Element-based: a base hook
// feeds a second hook, which a third consumes, and the component still returns
// `Element` with no ContextBase drift.
test "infer: net-new ---- @Context across three hook layers stays Element-based" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn layer1(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn layer2() -> @Context<Element, i32> {
        \\    val a = use layer1(0);
        \\    a;
        \\}
        \\fn layer3() -> @Context<Element, i32> {
        \\    val b = use layer2();
        \\    b;
        \\}
        \\fn Widget() -> Element {
        \\    val c = use layer3();
        \\    Element();
        \\}
    );
}

test "infer: interface associated fn ---- resolves and instantiates per call" {
    // `Interface.method(...)` (no `self`) resolves as an associated function;
    // each call site instantiates fresh generics, so two calls with different
    // concrete types in the same scope never conflict.
    try h.assertInfersOk(std.testing.allocator,
        \\interface Pair2<A, B> {
        \\    default fn of(first: A, second: B) -> #(A, B) {
        \\        return #(first, second);
        \\    }
        \\    default fn first(p: #(A, B)) -> A {
        \\        return p._0;
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val a: i32 = Pair2.first(Pair2.of(1, "one"));
        \\    val b: bool = Pair2.first(Pair2.of(true, 9));
        \\}
    );
}
