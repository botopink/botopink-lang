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

// ── generic-inference-finalize (v0.beta.22 spec 04) ──────────────────────────

// Shape 1: chained method substitution. The second hop must see the U binding
// the first hop established (Array<i32> after `map`), so `.filter` resolves
// `self: Array<U>` to `Array<i32>` and the lambda `y -> y > 0` types against
// `i32`. Pre-spec: the inferencer loses the U binding between hops, the
// second hop sees `.generic`, and the whole expression fails to type.
test "infer: generic-inference-finalize ---- chained map().filter() propagates element type" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    val out = xs.map({ x -> x + 1 }).filter({ y -> y > 0 });
        \\    val n: i32 = out.length;
        \\}
    );
}

// Shape 2: a generic fn called with zero value args (`empty<K, V>() -> Dict<K, V>`)
// must use the caller's expected return type to constrain K and V. The
// explicit `Dict<K, V>` annotation on the val binding is the only source of
// information; without back-prop the unifier sees both type params unbound
// and reports `.generic TypeError`.
test "infer: generic-inference-finalize ---- empty<K,V>() infers from annotated binding" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Dict<K, V> { pairs: Array<#(K, V)> }
        \\fn empty<K, V>() -> Dict<K, V> {
        \\    return Dict(pairs: []);
        \\}
        \\fn main() {
        \\    val d: Dict<string, i32> = empty();
        \\}
    );
}

// Shape 3: LINQ-style tuple unify. A cross-product `from p in left, o in
// right on …` lowers to a method chain whose element type is the structural
// tuple #(P, O). When P and O are independently-resolved generics resolved
// against two source arrays, the unifier must build #(P, O) so the trailing
// `select` body sees both rows. Pre-spec: the join falls back to `.generic`
// and `p.<field>` / `o.<field>` inside the projection are unbound.
test "infer: generic-inference-finalize ---- linq join builds tuple element type" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Person { id: i32, name: string }
        \\record Order { personId: i32, product: string }
        \\fn crossJoin<P, O>(left: Array<P>, right: Array<O>, on: fn(p: P, o: O) -> bool) -> Array<#(P, O)> {
        \\    var acc: Array<#(P, O)> = [];
        \\    left.forEach({ p ->
        \\        right.forEach({ o ->
        \\            if (on(p, o)) { acc.push(#(p, o)); }
        \\        });
        \\    });
        \\    return acc;
        \\}
        \\fn main() {
        \\    val people = [Person(id: 1, name: "Ada")];
        \\    val orders = [Order(personId: 1, product: "book")];
        \\    val pairs = crossJoin(people, orders, { p, o -> p.id == o.personId });
        \\    val labels = pairs.map({ pair -> pair._0.name + " ordered " + pair._1.product });
        \\    val n: i32 = labels.length;
        \\}
    );
}
