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
        \\#[@future]
        \\fn bad() -> string {
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
        \\#[@future]
        \\fn bad() -> @Future<i32> {
        \\    val x = await 5;
        \\    return x;
        \\}
    );
}

test "infer error: yield targets an unknown label" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn gen() -> @Iterator<i32> {
        \\    yield :nope 1;
        \\}
    );
}

test "infer error: loop await on a non-async-iterable" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn bad() -> @Future<i32> {
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

// R1, R2, R5 (§2 of frente-b-rules-tooling.md) — effect-on-declare /
// effect-on-interface-method / effect-duplicate-annotation now reject at the
// parser layer (see `parser/tests/effect_rejections.zig`). The comptime
// inference path keeps a defense-in-depth check for direct AST construction.

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
        \\#[@External.Python("string", "length")]
        \\pub declare fn str_length(s: string) -> i32;
    );
}

test "infer error: external ---- wrong arity" {
    // 1 arg is below the 2..3 range (target alone). The 2-arg node-prototype
    // shorthand `@external(target, symbol)` is now valid (§A vocabulary).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@External.Erlang(..)]
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
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
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

test "infer error: RG3 ---- @Future<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn empty() -> @Future<> { return 0; }
    );
}

test "infer error: RG3 ---- @Iterator<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn empty() -> @Iterator<> { break; }
    );
}

test "infer error: RG3 ---- @Result<i32> rejects (E is required, no default)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse() -> @Result<i32> { return 0; }
    );
}

test "infer error: R11 ---- return Result.Ok(...) inside #[@result] reds return-must-be-bare-R" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    return Result.Ok(result: n * 2);
        \\}
    );
}

test "infer error: R11 mirror ---- throw Result.Error(...) inside #[@result] reds throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    throw Result.Error(error: "boom");
        \\}
    );
}

test "infer error: R12 ---- let-binding Result.Ok inside #[@result] reds result-manual-construction-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    val r = Result.Ok(result: n);
        \\    return n;
        \\}
    );
}

test "infer error: RF1 ---- return Future.resolved(...) inside #[@future] reds future-return-must-be-bare-T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    return Future.resolved(value: 42);
        \\}
    );
}

test "infer error: RF2 ---- throw Future.rejected(...) inside #[@future] reds future-throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    throw Future.rejected(error: "boom");
        \\}
    );
}

test "infer error: RI1 ---- return <expr> inside #[@iterator] reds iterator-return-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn nums() -> @Iterator<i32, string, i32> {
        \\    yield 1;
        \\    return 42;
        \\}
    );
}

test "infer error: RI1 ---- return <expr> inside #[@asyncGenerator] reds iterator-return-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@asyncGenerator]
        \\fn nums() -> @AsyncIterator<i32, string, i32> {
        \\    yield 1;
        \\    return 42;
        \\}
    );
}

test "infer error: RI5 ---- break :unknown reds break-label-unbound" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn nums() -> @Iterator<i32, string, i32> :outer {
        \\    yield 1;
        \\    break :nonsense 42;
        \\}
    );
}

test "infer error: RI3 ---- break <expr> with C=void reds iterator-break-without-completion-type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    break 42;
        \\}
    );
}

test "infer error: RC5 ---- @getContex outside #[@context] fn reds context-getcontex-outside-context-fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record User { id: i32 }
        \\fn lookup() -> User {
        \\    return @getContex(User);
        \\}
    );
}

test "infer error: RC4 ---- @getContex(<value>) reds context-getcontex-expects-type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record User { id: i32 }
        \\#[@context]
        \\fn lookup() -> @Context<User, User> {
        \\    return @getContex(42);
        \\}
    );
}

test "infer error: RC6 ---- use of non-context fn reds use-of-non-context-fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record User { id: i32 }
        \\fn plain() -> User { return User(id: 1); }
        \\#[@context]
        \\fn lookup() -> @Context<User, User> {
        \\    val u = use plain();
        \\    return u;
        \\}
    );
}

test "infer error: RC3 ---- @getContex(T) outside enclosing Anchor tree reds context-getcontex-anchor-violation" {
    // The enclosing fn's Anchor is `RootA`; the requested type `LeafB`'s
    // Anchor is `RootB`. No `use` chain rooted at `RootA` can ever provide
    // `LeafB`, so the request is statically out of reach (RC3).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record RootA { name: string }
        \\record RootB { name: string }
        \\record LeafB implement @Context<RootB, RootB> { v: i32 }
        \\#[@context]
        \\fn pickA() -> @Context<RootA, RootA> {
        \\    return @getContex(LeafB);
        \\}
    );
}

test "infer error: RI2 ---- break <wrongType> reds iterator-break-type-mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn nums() -> @Iterator<i32, string, i32> {
        \\    yield 1;
        \\    break "not an i32";
        \\}
    );
}

test "infer error: RF5 ---- let-binding Future.resolved inside #[@future] reds future-manual-construction-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    val f = Future.resolved(value: 42);
        \\    return 0;
        \\}
    );
}
