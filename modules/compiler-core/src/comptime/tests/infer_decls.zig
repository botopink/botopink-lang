//! comptime: pub fn/record/struct/interface/implement inference (split from tests.zig).

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

test "infer: enum constructors" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
        \\val c1 = Color.Red;
        \\val c2 = Color.Rgb(r: 255, g: 0, b: 0);
        \\val c3: Color = .Red;
    );
}

test "infer: record constructor" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
        \\@print(p);
    );
}

test "infer: record with method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: f64,
        \\    lon: f64,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
        \\val g = GPSCoordinates(lat: 5.0, lon: 3.0);
    );
}

test "infer: struct constructor" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    count: i32 = 0,
        \\};
        \\val c = Counter(0);
    );
}

test "infer: struct with private field and method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: i32 = 0,
        \\    fn deposit(self: Self, amount: i32) {
        \\        self._balance += amount;
        \\    }
        \\};
        \\val a = Account(0);
    );
}

test "infer: pub fn basic ---- greet returns string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
        \\val msg = greet("world");
        \\@print(msg);
    );
}

test "infer: pub fn with local val binding in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn compute(x: i32) -> i32 {
        \\    val doubled = x + x;
        \\    @print(doubled);
        \\    return doubled;
        \\}
        \\val result = compute(21);
        \\@print(result);
    );
}

test "infer: pub fn with comptime params" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: i32) -> string {
        \\    @todo();
        \\}
        \\val r = repeat("hi", 3);
    );
}

test "infer: pub fn using enum + case in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
        \\pub fn label(d: Direction) -> string {
        \\    val result = case d {
        \\        North -> "N";
        \\        South -> "S";
        \\        East -> "E";
        \\        West -> "W";
        \\        _ -> "?";
        \\    };
        \\    @print(result);
        \\    return result;
        \\}
        \\val n = label(Direction.North);
        \\@print(n);
    );
}

test "infer: val with explicit type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x: i32 = 42;
        \\val y: f64 = 3.14;
        \\val msg: string = "hello";
    );
}

test "infer: val dependency chain" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = 10;
        \\val b = a + 5;
        \\val c = b + a;
    );
}

test "infer: dotIdent resolved from type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Blue,
        \\};
        \\val c: Color = .Red;
    );
}

test "infer: implement block is invisible to the binding list" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @todo();
        \\    }
        \\};
        \\val c = Circle(radius: 5.0);
    );
}

test "infer: interface with field and abstract method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\}
    );
}

test "infer: interface with multiple abstract methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self),
        \\    fn drawLine(self: Self, x1: i32, y1: i32),
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string),
        \\}
    );
}

test "infer: struct with private field, getter, setter and method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
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
        \\}
    );
}

test "infer: record with fields and toString method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "infer: implement single interface for record" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("Drawing circle");
        \\    }
        \\};
    );
}

test "infer: implement two interfaces with qualified methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val UsbCharger = interface {
        \\    fn Connect(self: Self),
        \\};
        \\val SolarCharger = interface {
        \\    fn Connect(self: Self),
        \\};
        \\val SmartCamera = record { batteryLevel: i32 };
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        @print("Connected via USB");
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        @print("Connected via Solar");
        \\    }
        \\};
    );
}

test "infer: doc comment on function" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// Adds two numbers
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\val result = add(1, 2);
    );
}

test "infer: doc comment on struct" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// A point in 2D space
        \\val Point = struct { x: i32, y: i32 };
    );
}

test "infer: local extension method resolves without activation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = donald.swim();
    );
}

// ── net-new (v0.beta.13 · A5): extension dispatch ────────────────────────────

// Implementing an interface for a PRIMITIVE (`i32`) and dispatching a method on
// a literal receiver resolves the extension method.
test "infer: net-new ---- implement an interface for a primitive and dispatch" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Doubler = interface {
        \\    fn double(self: Self) -> i32;
        \\}
        \\val IntDoubler = implement Doubler for i32 {
        \\    fn double(self: Self) -> i32 {
        \\        return self + self;
        \\    }
        \\}
        \\val n = 3;
        \\val six = n.double();
    );
}

// Two imported libs each activating the SAME method name for the same type
// (`PatoNada*` from one, `PatoFundo*` from another) make `donald.swim()`
// cross-module ambiguous — inference reports a type error at the call.
test "infer: net-new ---- two imported libs activating the same method are ambiguous" {
    const io = std.testing.io;
    const modules = [_]Module{
        .{ .path = "swimlib", .source =
        \\pub record Pato { id: i32 }
        \\pub val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\pub val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "divelib", .source =
        \\import {Pato} from "swimlib";
        \\pub val Diver = interface {
        \\    fn swim(self: Self);
        \\}
        \\pub val PatoFundo = implement Diver for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "", .source =
        \\import {Pato, PatoNada*} from "swimlib";
        \\import {PatoFundo*} from "divelib";
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    };

    var session = try comptimeMod.compile(
        std.testing.allocator,
        &modules,
        io,
        .node,
        ".botopinkbuild/comptime/cross_module_extension_ambiguity",
    );
    defer session.deinit(std.testing.allocator);

    // The consumer module fails inference with an ambiguous-method diagnostic.
    var sawAmbiguous = false;
    for (session.outputs.items) |out| {
        if (out.outcome == .typeError) {
            switch (out.outcome.typeError.kind) {
                .ambiguousExtension, .ambiguousMethod => sawAmbiguous = true,
                else => {},
            }
        }
    }
    try std.testing.expect(sawAmbiguous);
}

// Precedence: when a record has an inherent method and an interface
// implementation declares the SAME method name, the inherent method wins (it is
// always available, so `t.label()` resolves without ambiguity).
test "infer: net-new ---- inherent method wins over a same-name implemented one" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Tag {
        \\    name: string,
        \\    fn label(self: Self) -> string {
        \\        return self.name;
        \\    }
        \\}
        \\val Named = interface {
        \\    fn label(self: Self) -> string;
        \\}
        \\val TagNamed = implement Named for Tag {
        \\    fn label(self: Self) -> string {
        \\        return "iface";
        \\    }
        \\}
        \\val t = Tag(name: "x");
        \\val l: string = t.label();
    );
}

// Chained `x.a().b()` where both `a` and `b` are extension methods resolves each
// link in the chain (the result of the first call is the receiver of the second).
test "infer: net-new ---- chained extension calls resolve each link" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Stepper = interface {
        \\    fn inc(self: Self) -> i32;
        \\    fn dec(self: Self) -> i32;
        \\}
        \\val IntStepper = implement Stepper for i32 {
        \\    fn inc(self: Self) -> i32 { return self + 1; }
        \\    fn dec(self: Self) -> i32 { return self - 1; }
        \\}
        \\val n = 5;
        \\val r: i32 = n.inc().dec();
    );
}

test "infer: qualified extension call needs no activation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = PatoNada.swim(donald);
    );
}

test "infer: multi-module local extension resolves on an imported record" {
    // `Pato` is imported; the interface and `implement` are declared in the
    // consumer module and auto-applied, so `donald.swim()` resolves without activation.
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\pub record Pato { id: i32 }
        },
        .{ .path = "", .source =
        \\import {Pato} from "pond";
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    });
}

test "infer: multi-module extension activated via star import" {
    // The interface + record + `implement` all live in `pond`; the consumer pulls
    // the type in and activates the imported extension with `PatoNada*`, so
    // `donald.swim()` dispatches across the module boundary.
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\pub record Pato { id: i32 }
        \\pub val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "", .source =
        \\import {Pato, PatoNada*} from "pond";
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    });
}

test "infer: inherent record method is always available" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record Pato {
        \\    id: i32,
        \\    fn quack(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val noise = donald.quack();
    );
}

test "infer: var binding ---- mutable local inside fn" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn count() -> i32 {
        \\    var n = 0;
        \\    return n;
        \\}
        \\val r = count();
    );
}

test "infer: var binding ---- mutable string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet() -> string {
        \\    var msg = "hello";
        \\    return msg;
        \\}
        \\val r = greet();
    );
}

test "infer: pub val ---- infers same as private val" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val NAME = "botopink";
    );
}

test "infer: star fn ---- async returns @Future is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
    );
}

test "infer: star fn ---- generator returns @Iterator is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<i32> {
        \\    yield 1;
        \\}
    );
}

test "infer: test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\test "addition works" {
        \\    val r = add(2, 3);
        \\    assert r == 5;
        \\}
    );
}

test "infer: anonymous test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

test "infer: external ---- fn no body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@external(erlang, "string", "length"),
        \\  @external(node, "./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    val n = str_length("hi");
        \\}
    );
}

test "infer: std package ---- import binds namespace" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {order} from "std";
        \\
        \\fn main() {
        \\    val a: i32 = order.toInt(order.lt());
        \\    val b: i32 = order.toInt(order.reverse(order.gt()));
        \\}
    );
}

test "infer: builtin result namespace ---- qualified calls typecheck" {
    try h.assertInfersOk(std.testing.allocator,
        \\*fn parse(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val doubled = result.map(parse(21), { x -> x * 2 });
        \\    val n: i32 = result.unwrap(doubled, 0);
        \\    val ok: bool = result.isOk(parse(n));
        \\}
    );
}

test "infer: @Option<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOption(x: @Option<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    @print(takeOption(3));
        \\}
    );
}

test "infer: @Optional<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOptional(x: @Optional<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    @print(takeOptional(3));
        \\}
    );
}

test "infer: forward_reference_top_level ---- a() calls b() declared after" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn a() -> i32 { return b(); }
        \\fn b() -> i32 { return 1; }
    );
}

test "infer: mutual_recursion ---- renderToString and renderChildren call each other" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Element { tag: string, value: string, children: Element[] }
        \\
        \\fn renderChildren(items: Element[]) -> string {
        \\    var out = "";
        \\    loop (items) { c -> out = out + renderToString(c); };
        \\    return out;
        \\}
        \\
        \\fn renderToString(e: Element) -> string {
        \\    if (e.tag == "#text") { return e.value; };
        \\    return "<" + e.tag + ">" + renderChildren(e.children) + "</" + e.tag + ">";
        \\}
    );
}
