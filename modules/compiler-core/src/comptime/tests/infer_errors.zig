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
        \\val Drawable = behavior {
        \\    fn draw(self: Self);
        \\    fn erase(self: Self);
        \\};
        \\val Circle = type(radius: f64);
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: an inline implement clause missing a required interface method" {
    // Decision 58 — the inline `implement <Behavior> { }` asserts that the type
    // satisfies the behavior, and nothing verified the assertion: this checked.
    // Same coverage rule as the separate block above, on the inline form.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\behavior Display {
        \\    fn show(self: Self) -> string;
        \\}
        \\type Money(cents: i32) implement Display { }
    );
}

test "infer error: an inline implement clause whose method is only a declare fn" {
    // A `declare fn` member is an abstract slot typed from its signature, so it
    // satisfies nothing — the inline clause still owes the behavior a body.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\behavior Display {
        \\    fn show(self: Self) -> string;
        \\}
        \\type Money(cents: i32) implement Display {
        \\    declare fn show(self: Self) -> string;
        \\}
    );
}

test "infer error: implement method not declared in the interface" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Drawable = behavior {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = type(radius: f64);
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
        \\val Drawable = behavior {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = type(radius: f64);
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn Renderable.draw(self: Self) {
        \\        @print("draw");
        \\    }
        \\};
    );
}

test "infer error: duplicate method across interfaces without qualification" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val UsbCharger = behavior {
        \\    fn connect(self: Self);
        \\};
        \\val SolarCharger = behavior {
        \\    fn connect(self: Self);
        \\};
        \\val Camera = type(battery: i32);
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

// 06 C3 — `*` only unified the two sides with each other, and two strings
// agree; `-` applied no constraint at all.
test "infer error: mul with two non-numeric operands" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = "a" * "b";
    );
}

test "infer error: negating a string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = -"s";
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
        \\type Pato(id: i32)
        \\val PatoVoa = extend Pato {
        \\    fn fly(self: Self) {
        \\        return self.id;
        \\    }
        \\}
    );
}

test "infer error: redundant local activation ---- star is for imports" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
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
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\val Diver = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
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
        \\type Pato(id: i32)
        \\Pato*;
    );
}

test "infer error: implement declares method not in interface" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
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

test "infer error: loop await on a non-future-generator" {
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

// 06 N25 / decision 8 § 9 — the wrapper without its annotation. A plain
// `fn -> @Result<D, E>` used to be accepted with no Result treatment at all.
test "infer error: a @Result return without #[@result]" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Result<i32, string> {
        \\    @todo();
        \\}
    );
}

// ── 06 C9 — method bodies join the strict contract ───────────────────────────
//
// `inferTypeMethods` used to swallow `error.TypeError` from a method body, an
// unannotated method got no stored signature, and an unresolved method call
// fell back to a fresh var. All three made a real mismatch compile.

// `assertTypeErrorSnap` runs the UNTYPED `inferProgram`, whose `inferDecl`
// never walks a type's method bodies — only the typed `inferDeclTyped` calls
// `inferTypeMethods`, which is the path `botopink check` takes. The two rows
// that live inside a method body therefore assert through the typed path.
test "infer error: a type error inside a method body" {
    try h.assertComptimeCompileError(std.testing.allocator, @src(),
        \\type D(id: i32) {
        \\    fn bad(self: Self) -> string {
        \\        val z: string = self.id;
        \\        return z;
        \\    }
        \\}
    );
}

test "infer error: a method the receiver type does not declare" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type D(id: i32)
        \\fn main() {
        \\    val d = D(id: 1);
        \\    @print(d.swim());
        \\}
    );
}

test "infer error: an unannotated method's return type comes from its body" {
    try h.assertComptimeCompileError(std.testing.allocator, @src(),
        \\type D(id: i32) {
        \\    fn get(self: Self) { return self.id; }
        \\}
        \\fn main() {
        \\    val d = D(id: 1);
        \\    val a: string = d.get();
        \\    @print(a);
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
// effect-on-behavior-method / effect-duplicate-annotation now reject at the
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

// Front 20 F9, decision 67 — `inline` is read by two emitters (`erlang.zig` and
// `beam_asm.zig`, `hasExternalInline` over the last argument), so it is declared
// on `External.Erlang` and `External.Beam` alone, and a written flag no emitter
// would read is refused at the annotation rather than accepted and ignored.
test "infer error: external ---- inline on a variant that does not declare it" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@External.Node("Math.max($args)", inline = true)]
        \\pub declare fn biggest(a: i32, b: i32) -> i32;
    );
}

test "infer error: external ---- inline as a bare trailing bool is the same flag" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@External.Typescript("Math.max($args)", true)]
        \\pub declare fn biggest(a: i32, b: i32) -> i32;
    );
}

test "infer error: external ---- inline must be the last argument" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@External.Erlang(inline = true, "max($args)")]
        \\pub declare fn biggest(a: i32, b: i32) -> i32;
    );
}

test "infer error: external ---- inline is a bool" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@External.Beam("max($args)", inline = 1)]
        \\pub declare fn biggest(a: i32, b: i32) -> i32;
    );
}

test "infer error: external ---- inline on a behavior method is checked the same way" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub behavior Shape {
        \\    #[@External.Wasm("area", inline = true)]
        \\    fn area(self: Self) -> i32;
        \\}
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

test "infer error: RI1 ---- return <expr> inside #[@futureGenerator] reds iterator-return-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@futureGenerator]
        \\fn nums() -> @FutureGenerator<i32, string, i32> {
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
        \\type User(id: i32)
        \\fn lookup() -> User {
        \\    return @getContex(User);
        \\}
    );
}

test "infer error: RC4 ---- @getContex(<value>) reds context-getcontex-expects-type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type User(id: i32)
        \\#[@context]
        \\fn lookup() -> @Context<User, User> {
        \\    return @getContex(42);
        \\}
    );
}

test "infer error: RC6 ---- use of non-context fn reds use-of-non-context-fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type User(id: i32)
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
        \\type RootA(name: string)
        \\type RootB(name: string)
        \\type LeafB(v: i32) implement @Context<RootB, RootB>
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

// ── tuple labels (decision 8 §6) ──────────────────────────────────────────────

test "infer: tuple label ---- an unknown label is an error naming the positional form" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn loadTyped() -> #(string, i32) {
        \\    return #("SP", 12);
        \\}
        \\val n = loadTyped().name;
    );
}

// N24 — the labels live on the `named` type node, so instantiating a generic
// signature has to carry them. `r.current` used to red "this tuple has no
// element labeled `current`".
test "infer: tuple label ---- a label survives generic instantiation" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn ref<T>(v: T) -> #(current: T) {
        \\    return #(v);
        \\}
        \\fn main() -> i32 {
        \\    val r = ref(5);
        \\    return r.current;
        \\}
    );
}

test "infer: tuple label ---- labels come from the written type and from construction variables" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn load() -> #(name: string, pop: i32) {
        \\    val name = "SP";
        \\    val pop = 12;
        \\    return #(name, pop);
        \\}
        \\fn show(r: #(city: string, pop: i32)) -> i32 {
        \\    return r.pop;
        \\}
        \\fn main() -> i32 {
        \\    val row = load();
        \\    val a = "RJ";
        \\    val b = 7;
        \\    val local = #(a, b);
        \\    val s: string = local.a;
        \\    val typed: #(x: i32, y: i32) = #(1, 2);
        \\    return show(row) + show(#("BH", 3)) + typed.y + row.pop;
        \\}
    );
}

test "infer error: pipeline ---- the piped value does not fit the call's arity (C12)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\val r = 1 |> add(1, 2);
    );
}

test "infer error: record update ---- an unknown label reds at the label (C11)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\val alice = Person(name: "a", age: 1);
        \\val b = Person(..alice, agee: 25);
    );
}

test "infer error: record update ---- a wrong value type reds at the value (C11)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\val alice = Person(name: "a", age: 1);
        \\val b = Person(..alice, age: "x");
    );
}

test "infer error: loop ---- a condition loop takes no parameter (N26)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() {
        \\    var i = 0;
        \\    loop (i < 3) { x ->
        \\        i = i + 1;
        \\    };
        \\}
    );
}

// ── C1 — `return` unifies with the declared return type ─────────────────────

test "infer error: return ---- a value that is not the declared return type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() -> i32 { return "s"; }
    );
}

test "infer error: return ---- an anonymous fn returns a value that is not its declared type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val f = fn(x: i32) -> i32 { return "s"; };
    );
}

test "infer error: return ---- a result fn returns a value that is not R" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Oops(msg: string)
        \\#[@result]
        \\fn f() -> @Result<i32, Oops> { return "s"; }
    );
}

test "infer error: return ---- an @block value flows to the fn's return" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() -> i32 {
        \\    val s = @block{ return "x"; };
        \\    return s;
        \\}
    );
}

test "infer: return ---- a hook body returns the X of @Context<B, X>, or another hook" {
    try h.assertInfersOk(std.testing.allocator,
        \\type El(tag: string)
        \\type Cell<T>(value: T)
        \\fn state<T>(initial: T) -> @Context<El, Cell<T>> { return Cell(value: initial); }
        \\fn counter(start: i32) -> @Context<El, Cell<i32>> { return state(start); }
    );
}

test "infer: return ---- body annotations see the fn's generic params" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn wrap<P>(xs: Array<P>) -> Array<#(P, P)> {
        \\    var acc: Array<#(P, P)> = [];
        \\    return acc;
        \\}
        \\val n = wrap([1, 2]);
        \\val m = wrap(["a"]);
    );
}

test "infer: return ---- a type guard body returns bool" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn isPositive(n: i32) -> n is i32 { return n > 0; }
    );
}

// ── C2 — a `case` is typed from its arms; a `comptime` block from its `break` ──

test "infer error: case ---- its arms' type does not match the annotation" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val a: bool = case 42 { 0 -> "a"; _ -> "b"; };
    );
}

test "infer: comptime block ---- its value is the break value" {
    try h.assertInfersOk(std.testing.allocator,
        \\val h = comptime { break 1; };
        \\val z: i32 = h;
    );
}

test "infer: case ---- a block arm's return leaves the enclosing fn" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn f(x: i32) -> i32 {
        \\    val s = case x { 0 -> { return 7; }; _ -> "n"; };
        \\    return 1;
        \\}
    );
}

// ── C8 — pattern bindings take the matched value's types ─────────────────────

test "infer error: pattern ---- a variant payload binding has the field's type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type E { A(v: i32), B }
        \\fn f(s: string) -> string { return s; }
        \\fn g(e: E) -> string { return case e { A(v) -> f(v); B -> "b"; }; }
    );
}

test "infer error: pattern ---- an OR pattern binds the same field type in every alternative" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Pet { Dog(name: i32), Cat(name: i32) }
        \\fn f(s: string) -> string { return s; }
        \\fn g(p: Pet) -> string { return case p { Dog(b) | Cat(b) -> f(b); }; }
    );
}

test "infer error: pattern ---- a guarded binder is the subject type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f(s: string) -> string { return s; }
        \\fn g(x: i32) -> string { return case x { y if (y > 0) -> f(y); _ -> "n"; }; }
    );
}

test "infer error: pattern ---- Ok binds the R of a @Result" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Oops(msg: string)
        \\#[@result]
        \\fn parse(s: string) -> @Result<i32, Oops> { return 1; }
        \\fn f(s: string) -> string { return s; }
        \\fn g() -> string { return case parse("1") { Ok(v) -> f(v); Err(e) -> "e"; }; }
    );
}

test "infer error: pattern ---- a list pattern binds the element type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f(s: string) -> string { return s; }
        \\fn g(xs: i32[]) -> string { return case xs { [first, ..rest] -> f(first); _ -> "n"; }; }
    );
}

test "infer: pattern ---- a generic enum payload is instantiated against the subject" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Box<T> { Full(v: T), Empty }
        \\fn g(b: Box<string>) -> string { return case b { Full(v) -> v; Empty -> ""; }; }
    );
}

// ── N28 — a section of an enum-shaped `type` is a type named by its path ──────

test "infer: section ---- a section path types an annotation, a parameter and a return" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Token { Text { Bold, Size { Xs, Sm } }, Color { Red }, Hover(inner: Token[]) }
        \\fn sizeToCss(s: Token.Text.Size) -> string { return case s { Xs -> "xs"; Sm -> "sm"; }; }
        \\fn textToCss(t: Token.Text) -> string {
        \\    return case t { Bold -> "bold"; Size(s) -> sizeToCss(s); };
        \\}
        \\fn tokenToCss(t: Token) -> string {
        \\    return case t { Text(i) -> textToCss(i); Color(c) -> "c"; Hover(h) -> "h"; };
        \\}
    );
}

test "infer error: section ---- an unknown section path is not a type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Token { Text { Bold }, Hover(inner: Token[]) }
        \\fn f(t: Token.Nope) -> string { return "x"; }
    );
}

test "infer error: section ---- the flat spelling names the path to write" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Token { Text { Bold }, Hover(inner: Token[]) }
        \\fn f(t: TokenText) -> string { return "x"; }
    );
}

test "infer: section ---- a nested section pattern refines the arm, it does not cover it" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Token { Text { Bold, Italic }, Hover(inner: Token[]) }
        \\fn f(t: Token) -> string {
        \\    return case t { Text(Bold) -> "b"; Text(i) -> "t"; Hover(h) -> "h"; };
        \\}
    );
}

test "infer error: section ---- a refined section arm leaves the wrapper uncovered" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Token { Text { Bold, Italic }, Hover(inner: Token[]) }
        \\fn f(t: Token) -> string {
        \\    return case t { Text(Bold) -> "b"; Hover(h) -> "h"; };
        \\}
    );
}

// ── C10 / N30 — an annotation that names no type reds at the annotation ───────
// The resolution is two-pass: a name nothing declares yet is recorded with its
// location and re-checked once every declaration of the module is registered,
// so a forward reference resolves and only a name nothing declares reds. The
// caret is the annotation's, carried by `Param.typeLoc` / `Field.typeLoc` /
// `FnDecl.returnTypeLoc`.

test "infer error: unknown type ---- a param annotation names nothing" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f(p: NoSuchType) -> i32 { return 1; }
    );
}

test "infer error: unknown type ---- a field annotation names nothing" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Q(lat: bogusType)
    );
}

test "infer error: unknown type ---- a return annotation names nothing" {
    // An associated fn of a `behavior`: the signature is registered without a
    // body, so the annotation is what reds. (A `fn` with a body reds on the
    // returned value first — a different row.)
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\behavior Maker { fn make() -> NoSuchType; }
    );
}

test "infer error: unknown type ---- a variant field annotation names nothing" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Shape { Circle(r: bogusType), Square(side: f64) }
    );
}

test "infer: unknown type ---- a forward reference to a type declared below checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Outer(inner: Inner)
        \\type Inner(n: i32)
        \\fn f(o: Outer) -> i32 { return o.inner.n; }
    );
}

test "infer: unknown type ---- a behavior names a type in annotation position" {
    try h.assertInfersOk(std.testing.allocator,
        \\behavior Counter { fn value(self: Self) -> i32; }
        \\type Clicks(n: i32) implement Counter {
        \\    fn value(self: Self) -> i32 { return self.n; }
        \\}
        \\fn read(c: Counter) -> i32 { return c.value(); }
    );
}

// ── `@src()` (1.0.10-beta front 01-std, decision 73) ─────────────────────────

test "infer error: src takes no arguments" {
    // `src-takes-no-arguments`, located at the `@`.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn main() {
        \\    val loc = @src(1);
        \\}
    );
}

test "infer error: unknown builtin is refused" {
    // The silent `void` fallback for an unrecognised `@name(…)` is gone
    // (decision 67); the nearest known name is suggested when one is an edit away.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn main() {
        \\    @pritn("x");
        \\}
    );
}

test "infer error: unknown builtin without a near name" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn main() {
        \\    @frobnicate(1, 2);
        \\}
    );
}

// ── decision 38: a `val` is immutable ─────────────────────────────────────────

/// The error `inferProgram` raises for `src`, rendered — no snapshot: the
/// message is asserted by content so that the case does not add a cell to
/// `snapshots/comptime/errors/`.
fn typeErrorMessage(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);
    var env = try inferMod.freshEnv(alloc, allocator);
    defer env.deinit();
    try std.testing.expectError(error.TypeError, inferMod.inferProgram(&env, program));
    const err = env.lastError orelse return error.TestExpectedEqual;
    try std.testing.expect(err.loc != null);
    // Message and hint together: the hint is where `var` is named.
    const msg = try err.message(allocator);
    defer allocator.free(msg);
    const hint = switch (err.kind) {
        .custom => |c| c.hint orelse "",
        else => "",
    };
    return std.fmt.allocPrint(allocator, "{s}\n{s}", .{ msg, hint });
}

test "infer error: assigning to a local `val` names `var`" {
    const msg = try typeErrorMessage(std.testing.allocator, "fn main() { val x: i32 = 0; x = 1; @print(x); }");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`x` is a `val` and cannot be assigned") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "var x") != null);
}

test "infer error: assigning to a module-level `val` names `var`" {
    const msg = try typeErrorMessage(std.testing.allocator, "val hits: i32 = 0;\nfn bump() { hits += 1; }");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`hits` is a `val` and cannot be assigned") != null);
}

test "infer error: `#[@BeamMemory.Ets]` on a `val` is refused" {
    const msg = try typeErrorMessage(std.testing.allocator, "#[@BeamMemory.Ets]\nval hits: i32 = 0;");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "needs a `var`") != null);
}

test "infer: a `var` may be assigned, locally and at module level" {
    try h.assertInfersOk(std.testing.allocator, "var hits: i32 = 0;\nfn bump() { hits += 1; var y = 0; y = hits; }");
}

// ── front 17 step 3: `#[@BeamMemory.<member>]` is validated (decisions 41, 51) ─

test "infer error: an unknown `@BeamMemory` member" {
    const msg = try typeErrorMessage(std.testing.allocator, "#[@BeamMemory.Etz]\nvar x: i32 = 0;");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "unknown member `Etz` in `@BeamMemory` — expected `ProcessDict`, `Ets` or `PersistentTerm`") != null);
}

test "infer error: an unknown `@BeamMemory` argument" {
    const msg = try typeErrorMessage(std.testing.allocator, "#[@BeamMemory.Ets(keyd = true)]\nvar x: i32 = 0;");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "unknown argument `keyd` — expected `keyed`") != null);
}

test "infer error: `keyed = true` on an `i32` has no key" {
    const msg = try typeErrorMessage(std.testing.allocator, "#[@BeamMemory.Ets(keyed = true)]\nvar n: i32 = 0;");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`keyed` needs a keyed container — an `i32` has no key") != null);
}

test "infer error: `keyed = true` on a list has no key (decision 51)" {
    const msg = try typeErrorMessage(std.testing.allocator, "#[@BeamMemory.Ets(keyed = true)]\nvar xs: i32[] = [];");
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`keyed` needs a keyed container") != null);
}

test "infer: `@BeamMemory` accepts its three members, the default said out loud included" {
    try h.assertInfersOk(std.testing.allocator, "#[@BeamMemory.ProcessDict]\nvar a: i32 = 0;\n#[@BeamMemory.Ets]\nvar b: i32 = 0;\n#[@BeamMemory.PersistentTerm]\nvar c: i32 = 0;\n#[@BeamMemory.Ets(keyed = false)]\nvar d: i32 = 0;");
}
