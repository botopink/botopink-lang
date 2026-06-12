//! codegen: WAT backend codegen (split from tests.zig).

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

test "wat: record construct two fields" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
        \\fn make() -> Point {
        \\    return Point(x: 3, y: 4);
        \\}
    );
}

test "wat: tuple construct then destructure" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val t = #(10, 20);
        \\    val #(a, b) = t;
        \\    @print(a + b);
        \\}
    );
}

test "wat: enum payload construct as tagged struct" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\enum Shape {
        \\    Circle(r: i32),
        \\    Square(side: i32),
        \\}
        \\fn makeCircle() -> Shape {
        \\    return Shape.Circle(r: 5);
        \\}
    );
}

test "wat: string concat via linear memory" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn greeting() -> string {
        \\    return "Hello, " + "World";
        \\}
    );
}

test "wat: string compare via byte loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sameWord() -> bool {
        \\    return "foo" == "bar";
        \\}
    );
}

test "wat: string len reads length prefix" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn n() -> i32 {
        \\    val s = "hello";
        \\    return s.len;
        \\}
    );
}

test "wat: string slice copies bytes into a new buffer" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn first3() -> string {
        \\    val s = "hello";
        \\    return s.slice(0, 3);
        \\}
    );
}

test "wat: string slice without end arg slices to source length" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    val tail = s.slice(2);
        \\    @print(tail.len);
        \\}
    );
}

test "wat: string len participates in arithmetic" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "hello";
        \\    @print(s.len + 1);
        \\}
    );
}

test "wat: string slice result length is readable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "abcdef";
        \\    val mid = s.slice(1, 5);
        \\    @print(mid.len);
        \\}
    );
}
