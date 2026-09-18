//! format: struct/interface/implement/fn/const/val/let/pub (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: val ---- integer constant" {
    try h.assertFormat(std.testing.allocator,
        \\val MAX = 100;
    );
}

test "format: val ---- comptime float mul" {
    try h.assertFormat(std.testing.allocator,
        \\val pi = comptime 3.14 * 2.0;
    );
}

test "format: val ---- comptime string concat" {
    try h.assertFormat(std.testing.allocator,
        \\val greeting = comptime "Hello, " + "World";
    );
}

test "format: val ---- comptime block with break" {
    try h.assertFormat(std.testing.allocator,
        \\val hash = comptime {
        \\    break 6364 + 11;
        \\};
    );
}

test "format: val ---- multiple top-level vals" {
    try h.assertFormat(std.testing.allocator,
        \\val box = wrap(int);
        \\
        \\val m = maxval(float);
    );
}

test "format: behavior ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Drawable {}
    );
}

test "format: behavior ---- one field" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Drawable {
        \\    val color: string;
        \\}
    );
}

test "format: behavior ---- abstract method" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Drawable {
        \\    fn draw(self: Self);
        \\}
    );
}

test "format: behavior ---- full Drawable (field + abstract + default method)" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Drawable {
        \\    val color: string;
        \\
        \\    fn draw(self: Self);
        \\
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\}
    );
}

test "format: behavior ---- multiple abstract methods" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Canvas {
        \\    fn clear(self: Self);
        \\    fn drawLine(self: Self, x1: i32, y1: i32);
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string);
        \\}
    );
}

test "format: type (record) ---- no fields, no body" {
    try h.assertFormat(std.testing.allocator,
        \\type Point
    );
}

test "format: type (record) ---- two fields" {
    try h.assertFormat(std.testing.allocator,
        \\type Point(x: number, y: number)
    );
}

test "format: type (record) ---- with method" {
    try h.assertFormat(std.testing.allocator,
        \\type GPSCoordinates(lat: number, lon: number) {
        \\    fn toString(self: Self) {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "format: type (enum) ---- unit variants" {
    try h.assertFormat(std.testing.allocator,
        \\type Direction { North, South, East, West }
    );
}

test "format: type (enum) ---- with payload variant" {
    try h.assertFormat(std.testing.allocator,
        \\type Color { Red, Green, Blue, Rgb(r: i32, g: i32, b: i32) }
    );
}

test "format: implement ---- single interface" {
    try h.assertFormat(std.testing.allocator,
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\};
    );
}

test "format: implement ---- two interfaces with qualified methods" {
    try h.assertFormat(std.testing.allocator,
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        Console.WriteLine("Connected via USB. Battery level: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        Console.WriteLine("Connected via Solar Panel. Battery level: " + self.batteryLevel);
        \\    }
        \\};
    );
}

test "format: implement ---- shorthand named" {
    try h.assertFormat(std.testing.allocator,
        \\PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\};
    );
}

test "format: implement ---- shorthand named pub" {
    try h.assertFormat(std.testing.allocator,
        \\pub PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\};
    );
}

test "format: extend ---- shorthand named" {
    try h.assertFormat(std.testing.allocator,
        \\PatoExtra extend Pato {
        \\    fn quack(self: Self) {}
        \\};
    );
}

test "format: extend ---- explicit named" {
    try h.assertFormat(std.testing.allocator,
        \\val PatoExtra = extend Pato {
        \\    fn quack(self: Self) {}
        \\};
    );
}

test "format: pub fn ---- simple with return type" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
    );
}

test "format: pub fn ---- comptime params" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn repeat(comptime s: string, comptime n: int) -> string {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- syntax fn type param" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn select<T, R>(lamb comptime: syntax fn(item: T) -> R) {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- type meta-kind no constraint" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn wrap(comptime T: type) -> type {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- type meta-kind single constraint" {
    try h.assertFormat(std.testing.allocator,
        \\fn render(comptime tag: type string, props: i32) -> string {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- type meta-kind multiple pipe constraints" {
    try h.assertFormat(std.testing.allocator,
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    todo;
        \\}
    );
}

test "format: generic ---- @Result<D, E> in signature" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn parse(s: string) -> @Result<i32, string> {
        \\    todo;
        \\}
    );
}

test "format: generic ---- nested ?T in @Result" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn lookup(k: string) -> @Result<?i32, string> {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- comptime param with generic constraint" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn run(comptime ctx: @Context<i32, string>) {
        \\    todo;
        \\}
    );
}

test "format: fn statement ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main(one: string, two: string, three: string) {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- discarded parameter" {
    try h.assertFormat(std.testing.allocator,
        \\fn main(_discarded: string) {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- with return type" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() -> null {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- trailing comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    null;
        \\    // Done
        \\}
    );
}

test "format: let ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = 1;
        \\    null;
        \\}
    );
}

test "format: let ---- block value" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = @block{
        \\        1;
        \\        2;
        \\    };
        \\    null;
        \\}
    );
}

test "format: let ---- case value" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val y = case x {
        \\        1 -> 1;
        \\        _ -> 0;
        \\    };
        \\    y;
        \\}
    );
}

test "format: let ---- fn value" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = fn(x) {
        \\        x;
        \\    };
        \\    x;
        \\}
    );
}

test "format: empty lines ---- single between statements" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1;
        \\
        \\    2;
        \\}
    );
}

test "format: empty lines ---- between comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // one
        \\
        \\    // two
        \\
        \\    3;
        \\}
    );
}

test "format: const ---- integer" {
    try h.assertFormat(std.testing.allocator,
        \\val MAX = 100;
    );
}

test "format: const ---- float" {
    try h.assertFormat(std.testing.allocator,
        \\val PI = 3.14;
    );
}

test "format: const ---- string" {
    try h.assertFormat(std.testing.allocator,
        \\val greeting = "Hello";
    );
}

test "format: const ---- multiple constants" {
    try h.assertFormat(std.testing.allocator,
        \\val str = "a string";
        \\
        \\val int = 4;
        \\
        \\val float = 3.14;
    );
}

test "format: const list ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\val wibble = [
        \\    // A comment
        \\    1, 2,
        \\    // Another comment
        \\    3,
        \\    // One last comment
        \\];
    );
}

test "format: const tuple ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\val wibble = #(
        \\    // A comment
        \\    1,
        \\    2,
        \\    // Another comment
        \\    3,
        \\    // One last comment
        \\);
    );
}

test "format: star fn ---- async function" {
    try h.assertFormat(std.testing.allocator,
        \\#[@future]
        \\fn fetch(url: string) -> @Future<Response> {
        \\    return download(url);
        \\}
    );
}

test "format: star fn ---- generator with label" {
    try h.assertFormat(std.testing.allocator,
        \\#[@iterator]
        \\fn gen() -> @Iterator<Int> :gen {
        \\    yield :gen 1;
        \\}
    );
}

test "format: test ---- anonymous block" {
    try h.assertFormat(std.testing.allocator,
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

test "format: test ---- named block" {
    try h.assertFormat(std.testing.allocator,
        \\test "addition works" {
        \\    val r = 2 + 3;
        \\    assert r == 5;
        \\}
    );
}

test "format: test ---- named block with assert message" {
    try h.assertFormat(std.testing.allocator,
        \\test "map doubles" {
        \\    assert [2, 4, 6] == [2, 4, 6], "map should double each element";
        \\}
    );
}

test "format: Expr builtin type ---- round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<Component> {
        \\    @todo();
        \\}
    );
}

test "format: Expr builtin type ---- generic return round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\fn yaml<T>(comptime template: @Expr<string>) -> @Expr<T> {
        \\    @todo();
        \\}
    );
}

// The formatter used to DROP enum sections entirely (`Token { Text { … } }`
// came back as `val Token = enum { Hover(inner: Token) };`) and to rewrite a
// bodyless `declare fn` as `pub fn f() -> i32 {}`. Both erased source.
test "format: type (enum) ---- section with bare variants is preserved" {
    try h.assertFormat(std.testing.allocator,
        \\type Token {
        \\    Hover(inner: Token),
        \\    Text {
        \\        Bold,
        \\        Italic,
        \\    }
        \\}
    );
}

test "format: type (enum) ---- nested sections with numeric leaves are preserved" {
    try h.assertFormat(std.testing.allocator,
        \\type Color {
        \\    Palette {
        \\        Red {
        \\            100,
        \\            500,
        \\        }
        \\    }
        \\}
    );
}

test "format: declare fn ---- external declaration keeps `declare` and stays bodyless" {
    try h.assertFormat(std.testing.allocator,
        \\#[@External.Erlang("string", "length")]
        \\pub declare fn length(s: string) -> i32;
    );
}

// ── 1.0.3 surface: the separator rule (specs/1.0.4-beta/12-surface-cutover/separators.md) ──

test "format: type ---- a compact field list stays on one line past the line width" {
    try h.assertFormat(std.testing.allocator,
        \\type Point(firstCoordinateOnTheHorizontalAxis: i32, secondCoordinateOnTheVerticalAxis: i32, thirdCoordinate: i32)
    );
}

test "format: type ---- a trailing comma opens the field list" {
    try h.assertFormatAs(std.testing.allocator, "type Point(x: i32, y: i32,)",
        \\type Point(
        \\    x: i32,
        \\    y: i32,
        \\)
    );
}

test "format: type ---- a comment in a compact field list opens it and adds the trailing comma" {
    try h.assertFormatAs(std.testing.allocator,
        \\type Config(
        \\    // where it listens
        \\    host: string, port: i32)
    ,
        \\type Config(
        \\    // where it listens
        \\    host: string,
        \\    port: i32,
        \\)
    );
}

test "format: type ---- annotations and defaults in a field list" {
    try h.assertFormat(std.testing.allocator,
        \\type Config(#[value("k")] host: string = "0.0.0.0", port: i32)
    );
}

test "format: type ---- compact variants stay compact; a trailing comma opens them" {
    try h.assertFormat(std.testing.allocator,
        \\type Color { Red, Green }
    );
    try h.assertFormatAs(std.testing.allocator, "type Color { Red, Green, }",
        \\type Color {
        \\    Red,
        \\    Green,
        \\}
    );
}

test "format: type ---- a body with a method is open, with a blank line before the method" {
    try h.assertFormatAs(std.testing.allocator,
        \\type Shape { Circle(r: f64), pub fn area(self: Self) -> f64 { return 0.0; } }
    ,
        \\type Shape {
        \\    Circle(r: f64),
        \\
        \\    pub fn area(self: Self) -> f64 {
        \\        return 0.0;
        \\    }
        \\}
    );
}

test "format: type ---- implement clause and generics" {
    try h.assertFormat(std.testing.allocator,
        \\pub type Stack<T>(items: T[]) implement Sized {
        \\    fn size(self: Self) -> i32 {
        \\        return 0;
        \\    }
        \\}
    );
}

test "format: behavior ---- an empty behavior stays {}; one fn member opens it" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Marker {}
    );
    try h.assertFormatAs(std.testing.allocator, "behavior Printable { fn print(self: Self) -> string; }",
        \\behavior Printable {
        \\    fn print(self: Self) -> string;
        \\}
    );
}

test "format: behavior ---- pub, generics and extends round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\pub behavior Container<T> extends Sized {
        \\    fn get(self: Self, i: i32) -> T;
        \\}
    );
}

test "format: the old surface prints as the new one" {
    try h.assertFormatAs(std.testing.allocator,
        \\type Point(x: i32, y: i32)
        \\type Color { Red, Green }
        \\behavior Shape { fn area(self: Self) -> f64; }
    ,
        \\type Point(x: i32, y: i32)
        \\
        \\type Color { Red, Green }
        \\
        \\behavior Shape {
        \\    fn area(self: Self) -> f64;
        \\}
    );
}

test "format: declarations ---- a parameter default and fn-type parameter names are kept" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Seq<T> {
        \\    fn slice(self: Self, start: i32, end: i32 = null) -> Self;
        \\    fn forEach(self: Self, action: fn(item: T));
        \\    fn fold<A>(self: Self, initial: A, f: fn(acc: A, item: T) -> A) -> A;
        \\}
    );
}

test "format: declarations ---- an if whose then-branch is an if keeps its braces before else" {
    try h.assertFormat(std.testing.allocator,
        \\fn f(a: bool, b: bool) -> i32 {
        \\    return if (a) {
        \\        if (b) 1 else 2;
        \\    } else 3;
        \\}
    );
}

// ── the package-default keyword (`pub default mod` / `pub default fn`) ────────
// Both flags are recorded by the parser and read by `comptime.zig`'s
// package-default DSL, and the printer had no arm for either: `format` rewrote
// `pub default mod X;` as `pub mod X;` and `pub default fn f(…)` as
// `pub fn f(…)`. On a package whose handle and handler have different names that
// unbinds every consumer — and because a deletion is idempotent, `format --check`
// reported the broken file as clean.

test "format: declarations ---- `pub default mod` keeps its keyword" {
    try h.assertFormat(std.testing.allocator,
        \\pub default mod zeta;
    );
}

test "format: declarations ---- a private `default mod` keeps its keyword" {
    try h.assertFormat(std.testing.allocator,
        \\default mod zeta;
    );
}

test "format: declarations ---- `pub default fn` keeps its keyword" {
    try h.assertFormat(std.testing.allocator,
        \\pub default fn query(s: string) -> string {
        \\    return s;
        \\}
    );
}

test "format: declarations ---- the package surface round-trips as a whole" {
    try h.assertFormat(std.testing.allocator,
        \\pub default mod zeta;
        \\
        \\pub default fn query(s: string) -> string {
        \\    return s;
        \\}
        \\
        \\pub mod other;
        \\
        \\pub fn plain(s: string) -> string {
        \\    return s;
        \\}
    );
}
