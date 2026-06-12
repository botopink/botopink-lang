//! comptime: literal/binary/case/control-flow inference (split from tests.zig).

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

test "infer: integer and float literals" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = 42;
        \\val y = 3.14;
        \\@print(x, y);
    );
}

test "infer: string literal" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
        \\@print(greeting);
    );
}

test "infer: binary operators" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val sum = 1 + 2;
        \\val product = 3.0 * 2.0;
        \\val joined = "a" + "b";
        \\@print(sum, product, joined);
    );
}

test "infer: local binding inside comptime" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val hash = comptime { break 6364 + 11; };
    );
}

test "infer: case on enum variants ---- all arms return string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
        \\val subject = Color.Red;
        \\val label = case subject {
        \\    Red -> "red";
        \\    Green -> "green";
        \\    Blue -> "blue";
        \\    _ -> "other";
        \\};
    );
}

test "infer: case on integer with wildcard" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val desc = case 42 {
        \\    0 -> "zero";
        \\    _ -> "nonzero";
        \\};
        \\@print(desc);
    );
}

test "infer: case with OR patterns" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _ -> "odd";
        \\};
        \\@print(parity);
    );
}

test "infer: case with variant field bindings ---- body does not use bound vars" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    Point,
        \\}
        \\val s = Shape.Point;
        \\val label = case s {
        \\    Circle(radius) -> "circle";
        \\    Square(side)   -> "square";
        \\    Point          -> "point";
        \\    _           -> "other";
        \\};
    );
}

test "infer: lt comparison returns bool" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val less = 1 < 2;
        \\val bigger = 10 < 5;
    );
}

test "infer: logical and returns bool" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = true && false;
    );
}

test "infer: logical or returns bool" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = true || false;
    );
}

test "infer: logical not returns bool" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = !true;
    );
}

test "infer: chained logical operators" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = true && false || true;
    );
}

test "infer: logical not with parens" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = !(true && false);
    );
}

test "infer: concat with i32 rhs ---- coerces to string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = "hello" + 42;
    );
}

test "infer: concat with i32 lhs ---- coerces to string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = 1 + "hello";
    );
}

test "infer: case arms with different types ---- string | i32 union" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> "zero";
        \\    _ -> 1;
        \\};
    );
}

test "infer: case arms with same type ---- no union" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val label = case 42 {
        \\    0 -> "zero";
        \\    1 -> "one";
        \\    _ -> "many";
        \\};
    );
}

test "infer: case arms three distinct types ---- union of three" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = case 0 {
        \\    0 -> "zero";
        \\    1 -> 42;
        \\    _ -> 3.14;
        \\};
    );
}

test "infer: null literal ---- type is optional<?>" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = null;
    );
}

test "infer: optional annotation ---- ?string val" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val msg: ?string = null;
    );
}

test "infer: optional annotation ---- ?i32 val with null" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val count: ?i32 = null;
    );
}

test "infer: if expression ---- result type from then branch" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    return r;
        \\}
        \\val s = sign(1);
    );
}

test "infer: if expression ---- with else branch" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return if (n > 0) { "positive"; } else { "non-positive"; };
        \\}
        \\val s = describe(5);
    );
}

test "infer: null-check binding ---- if (x) { e -> } body ignores binding" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn check() -> string {
        \\    var x = null;
        \\    if (x) { e ->
        \\        return "found";
        \\    };
        \\    return "none";
        \\}
        \\val r = check();
    );
}

test "infer: try expression ---- result type unified with return" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
        \\val x = process();
    );
}

test "infer: try-catch ---- handler provides fallback" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
        \\val x = safe();
    );
}

test "infer: assign ---- number literal to var" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = 10;
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- string to var" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var name = "old";
        \\    name = "new";
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- type mismatch error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = "oops";
        \\}
    );
}

test "infer: stdlib array method dispatch ---- xs.isEmpty() sugar" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs: Array<i32> = [1, 2];
        \\    val empty = xs.isEmpty();
        \\}
    );
}

test "infer: stdlib array method dispatch ---- ys.contains() with arg" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val ys = [1, 2, 3];
        \\    val found = ys.contains(2);
        \\}
    );
}
