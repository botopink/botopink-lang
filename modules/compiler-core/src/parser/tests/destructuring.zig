//! parser: destructure/shorthand/assign (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: use prefix with destructuring val" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn App() {
        \\    val {count, setCount} = use state(0);
        \\}
    );
}

test "parser: shorthand enum ---- simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\enum Direction {
        \\    North,
        \\    South,
        \\}
    );
}

test "parser: shorthand enum ---- pub with generics and payload" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub enum Option <T> {
        \\    None,
        \\    Some(value: T),
        \\}
    );
}

test "parser: shorthand struct ---- simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\struct Account {
        \\    _balance: i32 = 0,
        \\}
    );
}

test "parser: shorthand struct ---- pub with generics" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub struct Box <T> {
        \\    item: T = 0,
        \\}
    );
}

test "parser: shorthand record ---- simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
    );
}

test "parser: shorthand record ---- pub with generics" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub record Pair <T> { first: T, second: T }
    );
}

test "parser: shorthand interface ---- simple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\interface Drawable {
        \\    fn draw()
        \\}
    );
}

test "parser: shorthand interface ---- pub with generics" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub interface Container <T> {
        \\    fn size() -> Int
        \\}
    );
}

test "parser: destructure ---- record val binding" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn greet(person: Person) -> string {
        \\    val { name, age } = person;
        \\    return name;
        \\}
    );
}

test "parser: destructure ---- record parameter" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn greet({ name, age }: Person) -> string {
        \\    return name;
        \\}
    );
}

test "parser: destructure ---- mixed params" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn process(prefix: string, { name }: Person) -> string {
        \\    return prefix;
        \\}
    );
}

test "parser: val tuple destructuring" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn bind() {
        \\    val #(a, b) = #(12, "5452");
        \\}
    );
}

test "parser: var tuple destructuring" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn swap(x: i32, y: i32) -> i32 {
        \\    var #(a, b) = #(x, y);
        \\    return a;
        \\}
    );
}

test "parser: tuple destructuring as function parameter" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

test "parser: try-catch with tuple destructure" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "parser: assign ---- simple number literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = 10;
        \\}
    );
}

test "parser: assign ---- expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var total = 0;
        \\    total = total + 1;
        \\}
    );
}

test "parser: assign ---- string value" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var name = "old";
        \\    name = "new";
        \\}
    );
}
