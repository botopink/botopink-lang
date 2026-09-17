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
        \\val E = record implement @Context<E, E> { tag: string, n: i32 }
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
        \\val Point = record { x: i32, y: i32 }
    );
}

test "js: record ---- methods using self fields in arithmetic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Vec2 = record {
        \\    x: f64,
        \\    y: f64,
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
        \\val Invoice = record {
        \\    subtotal: f64,
        \\    taxRate: f64,
        \\    fn total(self: Self) -> f64 {
        \\        return self.subtotal + self.subtotal * self.taxRate;
        \\    }
        \\    fn validate(self: Self) {
        \\        throw new Error("invalid invoice");
        \\    }
        \\}
    );
}

test "js: record ---- method with todo placeholder" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Unimplemented { id: i32,
        \\    fn process(self: Self) -> string {
        \\        return @todo();
        \\    }
        \\}
    );
}

test "js: record ---- shorthand declaration without val Name =" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Vec2 {
        \\    x: f64,
        \\    y: f64,
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
        \\record Doc {
        \\    title: string,
        \\
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

// `pair.0` is the tuple index `pair._0` (commonJS emitted `pair.0` verbatim, a
// SyntaxError), and `.map` on the `?T` a `find` answers is the Option map, not
// `Array.prototype.map` over the found tuple. KNOWN: `2` then `true`; erlang
// crashes (`pair.0` lowers to `maps:get('0', Pair)` on a tuple), beam prints
// `undefined` for the first line and wasm traps (1.0.4-beta 01 erlang/beam/wasm).
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
        \\record State<T> { value: T, set: fn(next: T) }
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
        \\    val DeclKind = record { Type: "Type", Fn: "Fn" };
        \\    val decl = @Decl(kind: DeclKind.Type, name: "Service", fields: [], methods: [], returnType: "", annotations: []);
        \\    @print(decl.name);
        \\}
    );
}

test "js: interface literal ---- with fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val DeclKind = record { Type: "Type", Fn: "Fn" };
        \\    val decl = @Decl(kind: DeclKind.Type, name: "Service", fields: [record { name: "x", typeName: "i32", annotations: [] }], methods: [], returnType: "", annotations: []);
        \\    @print(decl.fields.length);
        \\}
    );
}
