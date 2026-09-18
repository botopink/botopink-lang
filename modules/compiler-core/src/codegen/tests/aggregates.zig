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
        \\val E = type(tag: string, n: i32) implement @Context<E, E>
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
// KNOWN-WRONG (wasm): wasm has no function values, so the element cannot be
// applied there — the module traps with `unresolved call: _1/1`, the same gap
// a lambda stored in any value has.
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
