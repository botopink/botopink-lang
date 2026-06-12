//! comptime: inference type errors (infer error: …) (split from tests.zig).

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

test "infer error: two pub default fn in one package" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub default fn one(comptime q: @Expr<string>) -> @ExprCustom<i32> { return q.build("0"); }
        \\pub default fn two(comptime q: @Expr<string>) -> @ExprCustom<i32> { return q.build("0"); }
    );
}

test "infer error: two pub default mod in one package" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub default mod alpha;
        \\pub default mod beta;
    );
}

test "infer error: type ---- arg violates constraint" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    return x;
        \\}
        \\val bad = coerce(3.14, 0);
    );
}

test "infer error: implement missing a required interface method" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\    fn erase(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: implement method not declared in the interface" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\    fn explode(self: Self) {
        \\        @print("boom");
        \\    }
        \\};
    );
}

test "infer error: implement qualified prefix is not a declared interface" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self),
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn Renderable.draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: duplicate method across interfaces without qualification" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val UsbCharger = interface {
        \\    fn connect(self: Self),
        \\};
        \\val SolarCharger = interface {
        \\    fn connect(self: Self),
        \\};
        \\val Camera = record { battery: i32 };
        \\val CameraCharger = implement UsbCharger, SolarCharger for Camera {
        \\    fn connect(self: Self) {
        \\        @print("connect");
        \\    }
        \\};
    );
}

test "infer error: getter return type mismatch with field type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    balance: i32 = 0,
        \\    get balance(self: Self) -> string {
        \\        return "nope";
        \\    }
        \\};
    );
}

test "infer error: setter value type mismatch with field type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    balance: i32 = 0,
        \\    set balance(self: Self, value: string) {
        \\        self.balance = value;
        \\    }
        \\};
    );
}

test "infer error: type mismatch ---- non-bool lhs with &&" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 1 && true;
    );
}

test "infer error: type mismatch ---- non-bool rhs with ||" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = true || 0;
    );
}

test "infer error: type mismatch ---- non-bool with !" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = !42;
    );
}

test "infer error: type mismatch ---- i32 + bool" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 1 + true;
    );
}

test "infer error: type mismatch ---- mul with non-numeric" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 3.14 * "oops";
    );
}

test "infer error: type mismatch ---- function argument wrong type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn double(x: i32) -> i32 {
        \\    @todo();
        \\}
        \\val bad = double("hello");
    );
}

test "infer error: type mismatch ---- val annotation mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x: string = 42;
    );
}

test "infer error: arity mismatch ---- too many arguments" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "hi";
        \\}
        \\val bad = greet("a", "extra");
    );
}

test "infer error: arity mismatch ---- too few arguments" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    @todo();
        \\}
        \\val bad = add(1);
    );
}

test "infer error: arity mismatch ---- zero-param function called with argument" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hello() -> string {
        \\    @todo();
        \\}
        \\val bad = hello(42);
    );
}

test "infer error: unbound variable ---- undefined identifier" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedIdent;
    );
}

test "infer error: unbound variable ---- undefined function call" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedFn(42);
    );
}

test "infer error: not a record ---- destructure val binding on primitive" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn describe(x: i32) -> string {
        \\    val { result } = x;
        \\    return result;
        \\}
    );
}

test "infer error: import of val ---- unbound variable" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {SECRET};
        \\val x = SECRET;
    );
}

test "infer error: extend without an interface ---- requires implement" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record Pato { id: i32 }
        \\val PatoVoa = extend Pato {
        \\    fn fly(self: Self) {
        \\        return self.id;
        \\    }
        \\}
    );
}

test "infer error: redundant local activation ---- star is for imports" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\PatoNada*;
    );
}

test "infer error: extension method ambiguous ---- two local impls" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\val Diver = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val PatoFundo = implement Diver for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val r = donald.swim();
    );
}

test "infer error: activation of non-extension symbol" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record Pato { id: i32 }
        \\Pato*;
    );
}

test "infer error: implement declares method not in interface" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = interface {
        \\    fn swim(self: Self);
        \\}
        \\record Pato { id: i32 }
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\    fn fly(self: Self) {
        \\        return self.id;
        \\    }
        \\}
    );
}

test "infer error: try ---- on non-Result type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    return 42;
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
    );
}

test "infer error: star fn returning a non-async type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> string {
        \\    return "x";
        \\}
    );
}

test "infer error: normal fn returning @Future must be star fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Future<i32> {
        \\    return 0;
        \\}
    );
}

test "infer error: await outside a star fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn notAsync() -> i32 {
        \\    val x = await ready();
        \\    return x;
        \\}
    );
}

test "infer error: await on a non-@Future value" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> @Future<i32> {
        \\    val x = await 5;
        \\    return x;
        \\}
    );
}

test "infer error: yield targets an unknown label" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn gen() -> @Iterator<i32> {
        \\    yield :nope 1;
        \\}
    );
}

test "infer error: loop await on a non-async-iterable" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn bad() -> @Future<i32> {
        \\    loop await (5) { x ->
        \\        ping(x);
        \\    }
        \\}
    );
}

test "infer error: effect annotation does not match the return wrapper" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn bad() -> @Result<i32, string> {
        \\    return 0;
        \\}
    );
}

test "infer error: #[@future] body using yield" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn bad() -> @Future<i32> {
        \\    yield 1;
        \\}
    );
}

test "infer error: effect annotation on a bodyless declare fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\pub declare fn parse(n: i32) -> @Result<i32, string>;
    );
}

test "infer error: effect annotation on an interface method" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val AsyncSource = interface {
        \\    #[@future]
        \\    fn next(self: Self) -> @Future<i32>
        \\}
    );
}

// net-new (A1): two effect markers on one fn conflict — `#[@result]` and
// `#[@future]` cannot both annotate the same declaration.
test "infer error: net-new ---- two effect markers on one fn conflict" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\#[@future]
        \\fn bad() -> @Future<i32> {
        \\    return 0;
        \\}
    );
}

test "infer error: assert requires bool" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\test "bad assert" {
        \\    assert 42;
        \\}
    );
}

test "infer error: test body type error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\test "bad call" {
        \\    val r = add("x", 3);
        \\}
    );
}

test "infer error: external ---- builtin typechecks args" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@external(python, "string", "length")]
        \\pub declare fn str_length(s: string) -> i32;
    );
}

test "infer error: external ---- wrong arity" {
    // 1 arg is below the 2..3 range (target alone). The 2-arg node-prototype
    // shorthand `@external(target, symbol)` is now valid (§A vocabulary).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@external(erlang)]
        \\pub declare fn str_length(s: string) -> i32;
    );
}

test "infer error: std package ---- unknown module" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {linked_list} from "std";
    );
}

test "infer error: std package ---- member missing" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {order} from "std";
        \\
        \\fn main() {
        \\    val x = order.collapse(true);
        \\}
    );
}

test "infer error: builtin result namespace ---- unknown function" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn parse(n: i32) -> @Result<i32, string> {
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val x = result.collapse(parse(1));
        \\}
    );
}

test "infer error: still_reports_unbound ---- a genuinely undefined name still errors" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn a() -> i32 { return nonexistent(); }
    );
}
