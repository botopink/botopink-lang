//! codegen: array/tuple/struct/record (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

test "js: record implement ---- fields round-trip at runtime" {
    // G7 regression: an inline `record implement … { fields }` must emit a real
    // constructor that assigns its fields, so `E(tag: "x", n: 5).n` reads `5` at
    // runtime instead of `undefined`. Runs on every backend (node + erlang
    // parity captured in each RUN LOG).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val E = type(tag: string, n: i32) implement @Context<E>
        \\fn mk() -> E {
        \\    return E(tag: "x", n: 5);
        \\}
        \\fn main() {
        \\    @print(mk().n);
        \\}
    );
}

test "js: record ---- two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Point = type(x: i32, y: i32)
    );
}

test "js: record ---- methods using self fields in arithmetic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Vec2 = type(
        \\    x: f64,
        \\    y: f64) {
        \\    fn lengthSq(self: Self) -> f64 {
        \\        return self.x * self.x + self.y * self.y;
        \\    }
        \\    fn scale(self: Self, factor: f64) -> f64 {
        \\        return self.x * factor;
        \\    }
        \\}
    );
}

test "js: record ---- method with throw" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Invoice = type(
        \\    subtotal: f64,
        \\    taxRate: f64) {
        \\    fn total(self: Self) -> f64 {
        \\        return self.subtotal + self.subtotal * self.taxRate;
        \\    }
        \\    fn validate(self: Self) {
        \\        throw "invalid invoice";
        \\    }
        \\}
    );
}

test "js: record ---- method with todo placeholder" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Unimplemented(id: i32) {
        \\    fn process(self: Self) -> string {
        \\        return @todo();
        \\    }
        \\}
    );
}

test "js: record ---- shorthand declaration without val Name =" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Vec2(
        \\    x: f64,
        \\    y: f64) {
        \\    fn dot(self: Self, other: Vec2) -> f64 {
        \\        return self.x * other.x + self.y * other.y;
        \\    }
        \\}
    );
}

test "js: array ---- string array literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "js: array ---- val with array type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "js: array ---- prepend with empty array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val list1 = [1, ..[]];
    );
}

test "js: array ---- prepend with single element array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val list2 = [1, 2, ..[3]];
    );
}

test "js: array ---- prepend with multiple elements array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "js: array ---- prepend with identifier" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val rest = [3, 4];
        \\val list = [1, 2, ..rest];
    );
}

// 06 N24 / decision 8 §6 — a tuple element of FUNCTION type called by its
// label. The label→index rewrite only ever fired for a member access
// (`row.pop` → `row._1`), so `c.set(9)` reached every backend as a method
// call on a value that is a tuple: `c.set is not a function` on commonJS,
// `'_1'(C, 9)` (an undefined function) on erlang, `unresolved_method` on beam.
// wasm answered this at front 05 step 7, and the note it carried — "wasm has no
// function values" — was wrong: wasm lifts a lambda into `$__lambda{n}`, lists it
// in the module's function table and applies it with `call_indirect`, so a lambda
// in a local, a lambda passed as a `fn(…)` parameter, a top-level fn used as a
// value and one bound to a local all worked. The one shape that did not was a
// function value read out of an **aggregate slot**: `lowerValueCall` recognised a
// record field and nothing else, and the checker resolves `c.set` to the position
// `_1`, which is not a field name — hence `unresolved call: _1/1`. All four
// backends now print `18`.
test "js: tuple ---- a labeled element of function type is called like a method" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn mk() -> #(value: i32, set: fn(n: i32) -> i32) {
        \\    val value = 1;
        \\    val set = { n -> return n * 2; };
        \\    return #(value, set);
        \\}
        \\fn main() {
        \\    val c = mk();
        \\    @print(c.set(9));
        \\}
    );
}

test "js: tuple ---- string pair literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "js: tuple ---- val with tuple type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "js: tuple ---- mixed types" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val t = #(12, "5452");
    );
}

test "js: tuple ---- literal pair" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val pair = #(1, "hello");
    );
}

test "js: tuple ---- nested tuples" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val nested = #(#(1, 2), #(3, 4));
    );
}

test "js: tuple ---- access elements" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn getFirst(t: #(i32, string)) -> i32 {
        \\    return t._0;
        \\}
    );
}

// A record method named like a builtin (`print`) is the record's method: a
// receiver call never reaches the `@print` dispatch. commonJS used to lower
// `d.print()` to `console.log(console.log())`, dropping the receiver.
// KNOWN: wasm prints `276`, the string's address (a record method's string
// result is printed as an i32 — 1.0.4-beta 01 wasm).
test "js: record ---- a method named print is called on the record" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Doc(
        \\    title: string,
        \\) {
        \\    fn print(self: Self) -> string {
        \\        return "doc:" + self.title;
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val d = Doc(title: "hi");
        \\    @print(d.print());
        \\}
    );
}

// `t.0.1` lexes as two positional indexes (not the float `0.1`) and
// `p.0.toString()` calls a method on an element; erlang and beam read tuple
// elements with `element/2`. Prints `2`, `x` and `7`. KNOWN: wasm prints the
// string element of an unannotated local tuple as its address (`256`).
test "js: tuple ---- chained positional access and a method on an element" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val t = #(#(1, 2), "x");
        \\    @print(t.0.1);
        \\    @print(t.1);
        \\    val p = #(7, "x");
        \\    @print(p.0.toString());
        \\}
    );
}

// `pair.0` is the tuple index `pair._0` (commonJS emitted `pair.0` verbatim, a
// SyntaxError), and `.map` on the `?T` a `find` answers is the Option map, not
// `Array.prototype.map` over the found tuple. Prints `2` then `true` on
// commonJS, erlang and beam (the bare `pair.0` is `element/2` since front 12
// step 4). KNOWN: wasm still traps (the `?T` map over a found tuple).
// The same `?T.map` inside a record method body is not lowered on commonJS
// either: inference records no Option lowering there (06-checker).
test "js: tuple ---- a bare digit index and an option map over a found pair" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn lookup(pairs: Array<#(string, i32)>, key: string) -> ?i32 {
        \\    return pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
        \\}
        \\
        \\fn main() {
        \\    val pairs = [#("a", 1), #("b", 2)];
        \\    @print(lookup(pairs, "b"));
        \\    @print(lookup(pairs, "z") == null);
        \\}
    );
}

// a record carrying a function-typed field (`set`) codegens like any other
// field — the closure is stored in the constructor.
test "js: record ---- fn-typed field (hook-shape record)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type State<T>(value: T, set: fn(next: T))
        \\fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
        \\fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
    );
}

// `Element[]`, a single value, and a `string` all coerce into a
// `Children`-typed parameter (the builder children model).
test "js: call ---- Children coercion (list / single / text)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn node() -> string { return "n"; }
        \\fn box(children: Children) -> string { return "x"; }
        \\val many = box([node(), node()]);
        \\val one = box(node());
        \\val txt = box("hi");
    );
}

test "js: interface literal ---- basic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val Type = "Type";
        \\    val Fn = "Fn";
        \\    val kinds = #(Type, Fn);
        \\    val decl = @Decl(kind: kinds.Type, name: "Service", fields: [], methods: [], returnType: "", annotations: []);
        \\    @print(decl.name);
        \\}
    );
}

test "js: interface literal ---- with fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val Type = "Type";
        \\    val Fn = "Fn";
        \\    val kinds = #(Type, Fn);
        \\    val decl = @Decl(kind: kinds.Type, name: "Service", fields: [#("x", "i32", [])], methods: [], returnType: "", annotations: []);
        \\    @print(decl.fields.length);
        \\}
    );
}

test "js: tuple ---- labels resolve to positions on every backend" {
    // Decision 8 §6: labels are compile-time names — from the written type
    // (`load`'s return, `show`'s parameter, an annotation) or from the variables
    // a tuple is built from; the value stays the positional tuple.
    // KNOWN (wasm): `row` and `local` carry no written type, so the wasm printer
    // has no print type for their string elements and prints the addresses
    // (`256`, `264`) — the same for a positional `row._0`; a decision-8 printer
    // concern (01 step 6), not a label one. The annotated `typed.y` prints 2.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn load() -> #(name: string, pop: i32) {
        \\    val name = "SP";
        \\    val pop = 12;
        \\    return #(name, pop);
        \\}
        \\
        \\fn show(r: #(city: string, pop: i32)) -> i32 {
        \\    return r.pop;
        \\}
        \\
        \\fn main() {
        \\    val row = load();
        \\    @print(row.name);
        \\    @print(row.pop + 1);
        \\    val a = "RJ";
        \\    val b = 7;
        \\    val local = #(a, b);
        \\    @print(local.a);
        \\    @print(show(#("BH", 3)));
        \\    @print(show(row));
        \\    val typed: #(x: i32, y: i32) = #(1, 2);
        \\    @print(typed.y);
        \\}
    );
}

test "js: surface ---- type and behavior compile like record, enum and interface" {
    // Front 12 step 2 (dual grammar): the 1.0.3 spelling builds the same nodes,
    // so the generated code is the old spelling's.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Shape {
        \\    fn area(self: Self) -> i32;
        \\}
        \\
        \\type Square(side: i32) implement Shape {
        \\    fn area(self: Self) -> i32 {
        \\        return self.side * self.side;
        \\    }
        \\}
        \\
        \\type Size { Small, Large(n: i32) }
        \\
        \\fn weight(s: Size) -> i32 {
        \\    return case s {
        \\        Small -> 1;
        \\        Large(n) -> n;
        \\    };
        \\}
        \\
        \\fn main() {
        \\    val sq = Square(side: 3);
        \\    @print(sq.area());
        \\    @print(weight(Size.Large(n: 5)) + weight(Size.Small));
        \\}
    );
}

// ── C-02: an index IS a method call (decision 63, amended 2026-09-19) ────────
//
// `xs[0]`, `s[0]`, `t[0]` and `xs[0..2]` are one AST node — the builtin call
// `[]` over `(receiver, index)`, with a `range` second argument for the slice
// (`ast.index_builtin_name`) — and the checker now rewrites every one of them
// before any backend sees it: `xs[k]` IS `xs.at(k)`, `xs[a..b]` is
// `xs.slice(a, b)` and `xs[1..]` is `xs.slice(1, null)`. So what these cells
// pin is no longer an erlang lowering of the index: it is that the index
// arrives here as the ORDINARY METHOD CALL this backend already emitted and
// already tested, and that running it answers what the method answers.
//
// The needles say exactly that. `'__bp_index'/2` and `'__bp_slice'/3` — the
// run-time dispatchers this backend used while the checker had no type for the
// node — are not emitted any more; `Array.at`'s own `@External.Erlang`
// template is, and `default fn slice` compiles to one `array_slice/3` with the
// `end =/= undefined` test the language wrote.

test "erlang: index ---- a list, a string and a tuple answer by position" {
    // The tuple is the checker's one special case (a constant index, a type per
    // position), and it rewrites to the positional access erlang already
    // lowered: `element(1, T)`, no method and no dispatcher.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  val xs = [10, 20, 30];
        \\  @print(xs[0]);
        \\  @print(xs[2]);
        \\  val s = "abcd";
        \\  @print(s[1]);
        \\  val t = #(1, "a");
        \\  @print(t[0]);
        \\}
    , "10\n30\nb\n1\n", &.{ "lists:nth(__I + 1, __L)", "element(1, T)" });
}

test "erlang: index ---- out of range answers undefined, not an error" {
    // `xs[5]` is `xs.at(5)`, whose type is `?i32`; decision 47 spells absent
    // `null` and erlang prints an empty optional as the atom `undefined`, which
    // is C-18's row rather than this one's. What this cell pins is that the
    // index reaches `Array.at` at all and does not abort.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() { val xs = [10, 20]; @print(xs[5]); }
    , "undefined\n", &.{});
}

test "erlang: index ---- a range second argument is a slice, open end included" {
    // There is no `Range` type — `start..end` is an AST node, not a value — so
    // the rewrite passes two bounds and an open end travels as `null`, which is
    // `undefined` on erlang. `Array.slice` is a `default fn` in `libs/std`, so
    // one `array_slice/3` carries both arms and the backend learns nothing.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  val xs = [10, 20, 30];
        \\  @print(xs[0..2]);
        \\  @print(xs[1..]);
        \\  val s = "abcd";
        \\  @print(s[1..3]);
        \\}
    , "[10, 20]\n[20, 30]\nbc\n", &.{ "array_slice(Xs, 0, 2)", "array_slice(Xs, 1, undefined)" });
}

// C-02 on commonJS. The same rewrite, seen from the backend that needed the
// least: `xs[0]` was already a JS index and is now `xs.at(0)` — the method the
// language says it is, and the one that answers `?T` on an array of anything.
// The checker used to answer `void` for this node, which is why two fronts wrote
// `.length()` around an index rather than indexing; what it answers now is what
// the method answers, and `tests/language/run/index_*` pins that by running.
//
// A tuple keeps a bare JS index, because a tuple's rewrite is `t._0` and a
// tuple is a JS array. `Array.at` goes through `__bp_array_at`, which answers
// decision 47's `null` past the end where native `.at` answers `undefined`; the
// inner `.at(0)` of `[[1, 2], [3, 4]][1][0]` stays native, because its
// receiver is the `?T` the outer one answered and inference records no array
// lowering for it.
test "js: index ---- element, slice, open slice, string and tuple" {
    const src =
        \\fn main() {
        \\    val xs = [10, 20, 30];
        \\    @print(xs[0]);
        \\    @print(xs[0..2]);
        \\    @print(xs[1..]);
        \\    val s = "abcd";
        \\    @print(s[1]);
        \\    @print(s[1..3]);
        \\    val t = #(1, "a");
        \\    @print(t[0]);
        \\    val i = 1;
        \\    @print(xs[i + 1]);
        \\    @print([[1, 2], [3, 4]][1][0]);
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "__bp_print(__bp_array_at(xs, 0));",
        "__bp_print(xs.slice(0, 2));",
        "__bp_print(xs.slice(1, null));",
        "__bp_print(__bp_string_char_at(s, 1));",
        "__bp_print(s.slice(1, 3));",
        "__bp_print(t[0]);",
        "__bp_print(__bp_array_at(xs, (i + 1)));",
        "__bp_print(__bp_array_at([[1, 2], [3, 4]], 1).at(0));",
    });
    // An open-ended range is `.slice(start, null)` here and the lazy
    // `__bp_range_from` generator everywhere else, so the helper is not pulled
    // in by a slice.
    try h.assertJsNotContains(std.testing.allocator, src, &.{"__bp_range_from"});
    try h.assertJsRunLog(std.testing.allocator, src,
        \\10
        \\[10, 20]
        \\[20, 30]
        \\b
        \\bc
        \\1
        \\30
        \\3
        \\
    );
}

test "js: destructure ---- a constructor in binding position is a plain destructure (JS-4)" {
    // `val Circle(r) = s;` — 01 R5 accepts the bare form only where the pattern
    // cannot fail (a record's own constructor, the variant of a one-variant
    // type), so the lowering is a destructure with no test: commonJS reads each
    // binding off the declared field at its position, wasm off its slot. It
    // used to write botopink's spelling into JS (`const Circle(r) = s;`, a
    // SyntaxError) and bind nothing on wasm (`0`, exit 0). erlang and beam are
    // 02's and 03's rows, hence two RUN LOGs rather than a snapshot.
    const src =
        \\type P(name: string, n: i32)
        \\type Tag { Label(text: string, weight: i32) }
        \\fn main() {
        \\    val P(nm, k) = P(name: "x", n: 2);
        \\    @print(nm);
        \\    @print(k);
        \\    val P(_, only) = P(name: "y", n: 5);
        \\    @print(only);
        \\    val Label(t, w) = Tag.Label(text: "hi", weight: 7);
        \\    @print(t + "!");
        \\    @print(w);
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "const { name: nm, n: k } = new P(\"x\", 2);",
        "const { n: only } = new P(\"y\", 5);",
        "const { text: t, weight: w } = Tag.Label(\"hi\", 7);",
    });
    const log =
        \\x
        \\2
        \\5
        \\hi!
        \\7
        \\
    ;
    try h.assertJsRunLog(std.testing.allocator, src, log);
    try h.assertWasmRunLog(std.testing.allocator, src, log);
}

test "js: call ---- the result of a call is called (curried)" {
    // `adder(3)(4)` — 01 types it through `calleeExpr` (01 handover 15), with
    // `callee == ""`. commonJS wrote the empty callee and emitted `(4)`; wasm
    // fell into the unresolved-call trap. A string-returning function value
    // (`greeter("a")("b")`, or through a local bound to one) is also a string
    // to wasm's printer — it wrote the heap address at exit 0 — and the lambda
    // `greeter` returns takes its parameter types from the declared
    // `-> fn(x: string) -> string`, so `p + x` concatenates. erlang and beam
    // are 02's and 03's rows (`test/curried_call.bp`).
    const src =
        \\fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
        \\fn greeter(p: string) -> fn(x: string) -> string { return { x -> p + x }; }
        \\fn main() {
        \\    @print(adder(3)(4));
        \\    @print(greeter("a")("b"));
        \\    val g = greeter("c");
        \\    @print(g("d") + "!");
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"__bp_print(adder(3)(4));"});
    const log =
        \\7
        \\ab
        \\cd!
        \\
    ;
    try h.assertJsRunLog(std.testing.allocator, src, log);
    try h.assertWasmRunLog(std.testing.allocator, src, log);
}

test "js: behavior literal ---- a method taking self is called on the literal" {
    // `@Greeter(greet: { self, who -> … })` called `g.greet("bo")`: the
    // receiver is `self`, as it is for a record's method. commonJS built an
    // arrow `(self, who) => …`, so `self` bound `"bo"` and `who` nothing
    // (`hi undefined`); wasm's indirect call passed one argument fewer than the
    // lifted lambda takes (a trap), then — with the receiver passed — printed
    // the string's address and concatenated one (`hi 256`), because the lambda's
    // `who` had no type: it takes it from the behavior's declaration now. The
    // erlang half (`greet/2 undefined`) is 02's.
    const src =
        \\behavior Greeter { fn greet(self: Self, who: string) -> string; }
        \\fn main() {
        \\    val g = @Greeter(greet: { self, who -> "hi " + who });
        \\    @print(g.greet("bo"));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"greet(who) {"});
    try h.assertJsRunLog(std.testing.allocator, src, "hi bo\n");
    try h.assertWasmRunLog(std.testing.allocator, src, "hi bo\n");
}
