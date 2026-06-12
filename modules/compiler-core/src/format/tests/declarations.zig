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

test "format: interface ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\val Drawable = interface {};
    );
}

test "format: interface ---- one field" {
    try h.assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\};
    );
}

test "format: interface ---- abstract method" {
    try h.assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    fn draw(self: Self);
        \\};
    );
}

test "format: interface ---- full Drawable (field + abstract + default method)" {
    try h.assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self);
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: interface ---- multiple abstract methods" {
    try h.assertFormat(std.testing.allocator,
        \\val Canvas = interface {
        \\    fn clear(self: Self);
        \\    fn drawLine(self: Self, x1: i32, y1: i32);
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string);
        \\};
    );
}

test "format: struct ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {};
    );
}

test "format: struct ---- single field single-line" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct { _balance: number = 0 };
    );
}

test "format: struct ---- multiple fields single-line" {
    try h.assertFormat(std.testing.allocator,
        \\val Point = struct { x: f32, y: f32 };
    );
}

test "format: struct ---- field with default value" {
    try h.assertFormat(std.testing.allocator,
        \\val Config = struct { host: string = "localhost", port: i32 = 8080 };
    );
}

test "format: struct ---- field with method multi-line" {
    try h.assertFormat(std.testing.allocator,
        \\val Counter = struct {
        \\    _count: i32 = 0,
        \\    fn increment(self: Self) {
        \\        self._count += 1;
        \\    }
        \\};
    );
}

test "format: struct ---- field with getter multi-line" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\};
    );
}

test "format: struct ---- getter" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\};
    );
}

test "format: struct ---- setter that throws" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Balance cannot be negative");
        \\    }
        \\};
    );
}

test "format: struct ---- method with augmented assign" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\};
    );
}

test "format: struct ---- full Account" {
    try h.assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\};
    );
}

test "format: record ---- empty" {
    try h.assertFormat(std.testing.allocator,
        \\val Point = record {};
    );
}

test "format: record ---- two fields" {
    try h.assertFormat(std.testing.allocator,
        \\val Point = record { x: number, y: number };
    );
}

test "format: record ---- with method" {
    try h.assertFormat(std.testing.allocator,
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
    );
}

test "format: enum ---- unit variants" {
    try h.assertFormat(std.testing.allocator,
        \\val Direction = enum { North, South, East, West };
    );
}

test "format: enum ---- with payload variant" {
    try h.assertFormat(std.testing.allocator,
        \\val Color = enum { Red, Green, Blue, Rgb(r: i32, g: i32, b: i32) };
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

test "format: struct ---- inline implement @Context<B, R>" {
    try h.assertFormat(std.testing.allocator,
        \\val Handler = struct implement @Context<i32, string> { state: i32 };
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
        \\*fn fetch(url: string) -> @Future<Response> {
        \\    return download(url);
        \\}
    );
}

test "format: star fn ---- generator with label" {
    try h.assertFormat(std.testing.allocator,
        \\*fn gen() -> @Iterator<Int> :gen {
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
