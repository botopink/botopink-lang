//! comptime: types / type_unification (split from tests.zig).

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

test "types: array literal infers element type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "types: val with array type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "types: array ---- prepend with empty array" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list1 = [1, ..[]];
    );
}

test "types: array ---- prepend with single element array" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list2 = [1, 2, ..[3]];
    );
}

test "types: array ---- prepend with multiple elements array" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "types: assert ---- simple assertion" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "types: assert ---- with arithmetic comparison" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "types: assert ---- with message" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "error message";
        \\}
    );
}

test "types: assert ---- array equality" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "types: assert pattern ---- with catch throw" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch throw "is not person";
        \\}
    );
}

test "types: assert pattern ---- with catch default value" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "types: assert pattern ---- with string literal" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val greeting = "hello";
        \\    val assert "hello" = greeting catch throw "not hello";
        \\}
    );
}

test "types: assert pattern ---- with number literal" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val answer = 42;
        \\    val assert 42 = answer catch throw "not 42";
        \\}
    );
}

test "types: assert pattern ---- with enum variant" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse() -> @Result<i32, string> {
        \\    return 42;
        \\}
        \\fn main() {
        \\    val result = parse();
        \\    val assert Ok(value) = result;
        \\    @print(value);
        \\}
    );
}

test "types: assert pattern ---- with empty list" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val list: i32[] = [];
        \\    val assert [] = list catch throw "not empty";
        \\}
    );
}

test "types: assert pattern ---- with multiple element list" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val numbers = [1, 2, 3];
        \\    val assert [1, 2, 3] = numbers catch throw "not matching";
        \\}
    );
}

test "types: assert pattern ---- with list and rest" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val items = [1, 2, 3, 4];
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "types: tuple literal infers element types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "types: tuple destructuring binds variables" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn extract() {
        \\    val #(first, second) = #(1, "hello");
        \\}
    );
}

test "types: val with tuple type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "types: tuple literal with mixed types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #(12, "5452");
    );
}

test "types: pipeline ---- simple chain" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1 |> double |> inc;
        \\}
    );
}

test "types: pipeline ---- multiple parameters" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\fn multiply(a: i32, b: i32) -> i32 { return a * b; }
        \\fn format(value: i32, prefix: string, suffix: string) -> string { return prefix + value + suffix; }
        \\fn main() {
        \\    val result = 5 |> add(3) |> multiply(2) |> format("Result: ", " !");
        \\}
    );
}

test "types: comment ---- single line" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\// This is a comment
        \\fn main() {
        \\    null;
        \\}
    );
}

test "types: doc comment ---- before fn" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\/// This is a documented function
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "types: module comment ---- top of file" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// This module provides utilities
        \\
        \\fn main() {
        \\    null;
        \\}
    );
}

test "types: negation ---- unary minus" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn negate(x: i32) -> i32 {
        \\    return -x;
        \\}
    );
}

test "types: range ---- iterate 0 to n" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) {
        \\    loop (0..n) { i ->
        \\        yield i;
        \\    };
        \\}
    );
}

test "types: loop ---- break with value" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        if (x > 10) { break x; };
        \\    };
        \\}
    );
}

test "types: loop ---- yield accumulation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn doubles(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        yield x * 2;
        \\    };
        \\}
    );
}

test "types: assign ---- plusEq on var" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn increment() {
        \\    var count = 0;
        \\    count += 1;
        \\}
    );
}

test "types: self ---- field access in method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Point(
        \\    x: i32,
        \\    y: i32) {
        \\    fn sum(self: Self) -> i32 {
        \\        return self.x + self.y;
        \\    }
        \\}
        \\fn main() {
        \\    @print(Point(x: 1, y: 2).sum());
        \\}
    );
}

test "types: if ---- null-check binding returns optional" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: ?string) -> ?string {
        \\    return if (name) { n -> n; };
        \\}
    );
}

test "types: if ---- null-check binding with else" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(name: ?string) -> string {
        \\    return if (name) { n -> n; } else { "anonymous"; };
        \\}
    );
}
