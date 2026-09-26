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

test "infer error: await outside an await channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn notAsync() -> i32 {
        \\    val x = await ready();
        \\    return x;
        \\}
    );
}

test "infer error: await on a non-@Task value" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Task<i32> {
        \\    val x = await 5;
        \\    return x;
        \\}
    );
}

test "infer error: yield targets an unknown label" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn gen() -> @Iterator<i32> {
        \\    yield :nope 1;
        \\}
    );
}

test "infer error: for await on a non-@Stream value" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Task<i32> {
        \\    for await (5) { x ->
        \\        ping(x);
        \\    }
        \\}
    );
}

// 06 N25 / decision 8 § 9 — the wrapper without its annotation. A plain
// `fn -> @Result<D, E>` used to be accepted with no Result treatment at all.
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

test "infer error: @Task body using yield" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn bad() -> @Task<i32> {
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

test "infer error: RG3 ---- @Task<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn empty() -> @Task<> { return 0; }
    );
}

test "infer error: RG3 ---- @Stream<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn empty() -> @Stream<> { break; }
    );
}

test "infer error: RG3 ---- @Result<i32> rejects (E is required, no default)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn parse() -> @Result<i32> { return 0; }
    );
}

test "infer error: R11 ---- return Result.Ok(...) inside @Result reds return-must-be-bare-R" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    return Result.Ok(result: n * 2);
        \\}
    );
}

test "infer error: R11 mirror ---- throw Result.Error(...) inside @Result reds throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    throw Result.Error(error: "boom");
        \\}
    );
}

test "infer error: R12 ---- let-binding Result.Ok inside @Result reds result-manual-construction-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    val r = Result.Ok(result: n);
        \\    return n;
        \\}
    );
}

test "infer error: decision 123 ---- yield and return <expr> in an @Iterator<@Result<…>> body reds iter-mixed-yield-return" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    return 42;
        \\}
    );
}

test "infer error: decision 123 ---- yield and return <expr> in a @Stream body reds iter-mixed-yield-return" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Stream<@Result<i32, string>> {
        \\    yield 1;
        \\    return 42;
        \\}
    );
}

test "infer error: RI5 ---- break :unknown reds break-label-unbound" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<@Result<i32, string>> :outer {
        \\    yield 1;
        \\    break :nonsense 42;
        \\}
    );
}

// Decision 103 — `break <v>` at generator level emits `v` as the last item
// and ends; `v` is an item of `T`, so this compiles (the RI3 refusal left
// with the completion channel `C`).
test "infer: decision 103 ---- break <expr> inside @Iterator-of-Result is the last item" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn nums() -> @Iterator<@Result<i32, string>> {
        \\    yield 1;
        \\    break 42;
        \\}
    );
}

test "infer error: RG5 ---- a second argument on @Task reds generic-arg-count-exceeded" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Task<i32, string> {
        \\    return 1;
        \\}
    );
}

test "infer error: RG5 ---- a third argument on @Result reds generic-arg-count-exceeded" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Result<i32, string, i32> {
        \\    return 1;
        \\}
    );
}

test "infer error: RG5 ---- YieldStep with an error parameter reds generic-arg-count-exceeded (decision 122)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn first(step: YieldStep<i32, string>) -> i32 {
        \\    return 0;
        \\}
    );
}

test "infer error: RG5 ---- a declared type written with more arguments than it declares" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Box<T>(value: T)
        \\fn open(b: Box<i32, string>) -> i32 {
        \\    return 0;
        \\}
    );
}

test "infer: decision 122 ---- next() by hand answers YieldStep on an iterator and a Task of it on a stream" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn two() -> @Iterator<i32> {
        \\    yield 1;
        \\}
        \\fn ticks() -> @Stream<i32> {
        \\    yield 1;
        \\}
        \\fn first() -> i32 {
        \\    val s: YieldStep<i32> = two().next();
        \\    return case s {
        \\        Yield(v) -> v;
        \\        Done -> 0;
        \\    };
        \\}
        \\fn firstTick() -> @Task<i32> {
        \\    val t: @Task<YieldStep<i32>> = ticks().next();
        \\    val s = await t;
        \\    return case s {
        \\        Yield(v) -> v;
        \\        Done -> 0;
        \\    };
        \\}
    );
}

test "infer error: RC5 ---- @getContext outside @Component fn reds context-getcontext-outside-context-fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type User(id: i32)
        \\fn lookup() -> User {
        \\    return @getContext(User);
        \\}
    );
}

test "infer error: RC4 ---- @getContext(<value>) reds context-getcontext-expects-type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type User(id: i32)
        \\fn lookup() -> @Component<User, User> {
        \\    return @getContext(42);
        \\}
    );
}

test "infer error: RC6 ---- use of non-context fn reds use-of-non-context-fn" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type User(id: i32)
        \\fn plain() -> User { return User(id: 1); }
        \\fn lookup() -> @Component<User, User> {
        \\    val u = use plain();
        \\    return u;
        \\}
    );
}

test "infer error: RC3 ---- @getContext(T) outside enclosing Anchor tree reds context-getcontext-anchor-violation" {
    // The enclosing fn's Anchor is `RootA`; the requested type `LeafB`'s
    // Anchor is `RootB`. No `use` chain rooted at `RootA` can ever provide
    // `LeafB`, so the request is statically out of reach (RC3).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type RootA(name: string)
        \\type RootB(name: string)
        \\type LeafB(v: i32) implement @Context<RootB>
        \\fn pickA() -> @Component<RootA, RootA> {
        \\    return @getContext(LeafB);
        \\}
    );
}

test "infer error: break <wrongType> in a generator reds a type mismatch against T (decision 103)" {
    // `break v` emits `v` and ends the generator: `v` is an item, so it must
    // be a `T`. The completion channel `C` is gone (decision 103).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<@Result<i32, string>> {
        \\    yield 1;
        \\    break "not an i32";
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

test "infer: return ---- a hook body returns the X of @Component<B, X>, or another hook" {
    try h.assertInfersOk(std.testing.allocator,
        \\type El(tag: string)
        \\type Cell<T>(value: T)
        \\fn state<T>(initial: T) -> @Component<El, Cell<T>> { return Cell(value: initial); }
        \\fn counter(start: i32) -> @Component<El, Cell<i32>> { return state(start); }
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

// ── 01 R5: a pattern in binding position ──────────────────────────────────────

test "val destructure: a one-variant type binds its payload typed" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Round = type { Circle(radius: i32) };
        \\fn main() {
        \\    val s = Round.Circle(radius: 2);
        \\    val Circle(r) = s;
        \\    val n: i32 = r;
        \\    @print(n);
        \\}
    );
}

test "val destructure: a record's constructor binds its fields typed" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Person = type(name: string, age: i32);
        \\fn main() {
        \\    val p = Person(name: "a", age: 3);
        \\    val Person(name, age) = p;
        \\    val s: string = name;
        \\    val n: i32 = age;
        \\    @print(s);
        \\    @print(n);
        \\}
    );
}

test "val destructure: the bound name carries the payload's type" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Round = type { Circle(radius: i32) };
        \\fn main() {
        \\    val s = Round.Circle(radius: 2);
        \\    val Circle(r) = s;
        \\    val t: string = r;
        \\    @print(t);
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "string") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "i32") != null);
}

test "val destructure: a val-bound name cannot be assigned" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Round = type { Circle(radius: i32) };
        \\fn main() {
        \\    val Circle(r) = Round.Circle(radius: 2);
        \\    r = 3;
        \\    @print(r);
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`r` is a `val`") != null);
}

test "val destructure: a pattern that can fail is refused, naming val assert" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Shape = type { Circle(radius: i32), Square(side: i32) };
        \\fn main() {
        \\    val s = Shape.Circle(radius: 2);
        \\    val Circle(r) = s;
        \\    @print(r);
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "refutable-val-pattern") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`Shape`") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "val assert") != null);
}

test "val destructure: a list pattern with elements is refused" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn main() {
        \\    val xs = [1, 2];
        \\    val [a, b] = xs;
        \\    @print(a + b);
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "refutable-val-pattern") != null);
}

// ── 01 handover 15: a call whose callee is an expression ──────────────────────

test "chained call: calling what a call returned types by its return" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn adder(a: i32) -> fn(i32) -> i32 { return { b -> a + b }; }
        \\fn main() { val x: i32 = adder(3)(4); @print(x); }
    );
}

test "chained call: the result carries the returned fn's return type" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn adder(a: i32) -> fn(i32) -> i32 { return { b -> a + b }; }
        \\fn main() { val x: string = adder(3)(4); @print(x); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expected string, got i32") != null);
}

test "chained call: an argument count the returned fn does not take reds" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn adder(a: i32) -> fn(i32) -> i32 { return { b -> a + b }; }
        \\fn main() { val x = adder(3)(4, 5); @print(x); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expects 1 argument(s), got 2") != null);
}

// ── front 15 handover: `.Variant(…)` in expression position ──────────────────

test "leading-dot call: the expected type names the enum" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Shape = type { Circle(radius: i32), Square(side: i32) };
        \\fn area(s: Shape) -> i32 { return 1; }
        \\fn main() {
        \\    val s: Shape = .Circle(radius: 1);
        \\    val xs: Shape[] = [.Square(side: 2)];
        \\    @print(area(.Circle(radius: 3)));
        \\    @print(s);
        \\    @print(xs);
        \\}
    );
}

test "leading-dot call: the payload is checked against the variant" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Shape = type { Circle(radius: i32), Square(side: i32) };
        \\fn main() { val s: Shape = .Circle(radius: "x"); @print(s); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expected i32, got string") != null);
}

test "leading-dot call: no expected type is a named refusal, not an empty name" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Shape = type { Circle(radius: i32), Square(side: i32) };
        \\fn main() { val s = .Circle(radius: 1); @print(s); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`.Circle(…)` names a variant by its leading dot") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "''") == null);
}

// ── 01 R4: a behavior-typed parameter or field accepts an implementer ────────

test "behavior-typed field and parameter accept an implementer, through extends" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Named = behavior { fn name(self: Self) -> string; };
        \\val Handler = behavior extends Named { fn run(self: Self) -> i32; };
        \\val H = type(id: i32) implement Handler {
        \\    fn run(self: Self) -> i32 { return self.id; }
        \\    fn name(self: Self) -> string { return "h"; }
        \\};
        \\val Holder = type(h: Handler);
        \\fn use1(h: Handler) -> i32 { return h.run(); }
        \\fn nm(n: Named) -> string { return n.name(); }
        \\fn main() {
        \\    val x = Holder(h: H(id: 1));
        \\    @print(use1(H(id: 2)));
        \\    @print(nm(H(id: 3)));
        \\    @print(x.h.run());
        \\}
    );
}

test "behavior-typed field rejects a record that does not implement it" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val Handler = behavior { fn run(self: Self) -> i32; };
        \\val Other = type(id: i32);
        \\val Holder = type(h: Handler);
        \\fn main() { val x = Holder(h: Other(id: 1)); @print(x); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Handler") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Other") != null);
}

// ── 01 R8: a type position takes a type, not any binding ─────────────────────

test "type position: a val bound to a type is a type" {
    try h.assertInfersOk(std.testing.allocator,
        \\val T = i32;
        \\fn main() {
        \\    val x: T = 1;
        \\    val U = T;
        \\    val y: U = 2;
        \\    @print(x + y);
        \\}
    );
}

test "type position: a val bound to a value is refused, located" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn main() { val n = 5; val x: n = 7; @print(x); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "'n' is a value, not a type") != null);
}

test "type position: a module-level value is refused too" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\val n = 5;
        \\val x: n = 7;
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "'n' is a value, not a type") != null);
}

// ── 01 R6: a behavior's associated fn types its result ───────────────────────

test "associated fn: `Array.range` answers an array, so a method on it resolves" {
    try h.assertInfersOk(std.testing.allocator,
        \\pub fn main() { val xs: i32[] = Array.range(0, 3).map({ x -> x + 2 }); @print(xs); }
    );
    const msg = try typeErrorMessage(std.testing.allocator,
        \\pub fn main() { val b: bool = Array.range(0, 3); @print(b); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expected bool, got i32[]") != null);
}

// ── decision 57: the warning channel — decision 8 §1.4 and §4.3 ──────────────

/// Every warning inference recorded for `src`, message and hint joined, one
/// per line pair. The program must check.
fn warningMessages(allocator: std.mem.Allocator, src: []const u8) ![]u8 {
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
    _ = try inferMod.inferProgramTyped(&env, program);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    for (env.warnings.items) |w| {
        try std.testing.expect(w.loc != null);
        const msg = try w.message(allocator);
        defer allocator.free(msg);
        try out.print(allocator, "{s}\n", .{msg});
    }
    return out.toOwnedSlice(allocator);
}

test "warning: `is` on a value whose type is known is always false (§4.3)" {
    const msg = try warningMessages(std.testing.allocator,
        \\pub fn main() { val a: i32 = 1; @print(a is string); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "this `is string` test is always false: the value's type is `i32`") != null);
}

test "warning: `is` warns on nothing it can answer — numbers by range, unknown, a union, the same type" {
    const msg = try warningMessages(std.testing.allocator,
        \\type P(x: i32)
        \\pub fn main() {
        \\    val a: i32 = 1;
        \\    val f: f64 = 2.0;
        \\    val u: unknown = 1;
        \\    val v: i32 | string = 1;
        \\    val p = P(x: 1);
        \\    @print(a is f64);
        \\    @print(f is i32);
        \\    @print(u is string);
        \\    @print(v is string);
        \\    @print(p is P);
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expectEqualStrings("", msg);
}

test "warning: an unannotated `[]` names the annotation to write (§1.4)" {
    const msg = try warningMessages(std.testing.allocator,
        \\fn f() -> i32 { var out = []; out = [1]; return out.length; }
        \\fn g() -> i32 { val none = []; return 0; }
        \\pub fn main() { val ok: i32[] = []; @print(f() + g() + ok.length); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "annotate it: `var out: i32[] = [];`") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "annotate it: `val none: unknown[] = [];`") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`ok`") == null);
}

// ── decision 8 §2.4: a public declaration writes an `unknown` it means ───────

test "public unknown: a `pub val` inferred as `unknown` is refused; a written one checks" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn mk(s: string) -> unknown { return s; }
        \\pub val v = mk("a");
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`pub val v` is inferred as `unknown`") != null);
    try h.assertInfersOk(std.testing.allocator,
        \\fn mk(s: string) -> unknown { return s; }
        \\pub val v: unknown = mk("a");
        \\val w = mk("b");
        \\pub fn parse(s: string) -> unknown { return s; }
    );
}

// ── decision 8 §1.1 / §1.2: a written generic type carries its arguments ─────

test "generics: a generic type written without its arguments is refused, located" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\type Box<T>(value: T)
        \\fn get(b: Box) -> i32 { return 0; }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Box needs 1 type argument") != null);
}

test "generics: too few arguments names both counts" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\type Pair<A, B>(a: A, b: B)
        \\fn f(p: Pair<i32>) -> i32 { return 0; }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Pair needs 2 type arguments, 1 given") != null);
}

test "generics: bare `Self` in a generic declaration names `Self<…>`; `Self` in a plain one stays" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\type Box<T>(value: T) {
        \\    pub fn get(self: Self) -> T { return self.value; }
        \\}
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Self needs 1 type argument: `Box` declares 1") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "Self<…>") != null);
    const plain = try typeErrorMessage(std.testing.allocator,
        \\type Point(x: i32) {
        \\    pub fn get(self: Self<i32>) -> i32 { return self.x; }
        \\}
    );
    defer std.testing.allocator.free(plain);
    try std.testing.expect(std.mem.indexOf(u8, plain, "`Point` declares no type parameter") != null);
}

test "generics: `Self<U>` is the declaration over another argument; A1 binds a behavior's `Self<…>` to a plain implementer" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Box<T>(value: T) {
        \\    pub fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U> { return Box(value: f(self.value)); }
        \\}
        \\behavior Mappable<T> { fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U>; }
        \\type Point(x: i32) implement Mappable<i32> {
        \\    fn map(self: Self, f: fn(x: i32) -> i32) -> Self { return Point(x: f(self.x)); }
        \\}
        \\fn main() {
        \\    val b: Box<string> = Box(value: 1).map({ x -> "a" });
        \\    val p: Point = Point(x: 1).map({ x -> x + 1 });
        \\    @print(b.value);
        \\    @print(p.x);
        \\}
    );
    const msg = try typeErrorMessage(std.testing.allocator,
        \\behavior Mappable<T> { fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U>; }
        \\type Point(x: i32) implement Mappable<i32> {
        \\    fn map(self: Self, f: fn(x: i32) -> i32) -> Self { return Point(x: f(self.x)); }
        \\}
        \\fn main() { val p = Point(x: 1).map({ x -> "a" }); @print(p.x); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expected i32, got string") != null);
}

// ── 01 step 12: one flat variant table under four symptoms ───────────────────

test "variant table: a qualified constructor is the enum written, whatever else declares the name (row 3c)" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Shape { Circle(r: i32), Square(s: i32) }
        \\type Hole { Circle(r: i32), Slot(w: i32) }
        \\fn area(s: Shape) -> i32 { return 0; }
        \\fn main() { @print(area(Shape.Circle(r: 3))); }
    );
}

test "variant table: a leading dot takes the expected enum; with none, two claimants are a named refusal (row 1)" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Warm { Red, Orange }
        \\type Cold { Blue, Red }
        \\fn main() { val w: Warm = .Red; val c: Cold = .Red; @print(0); }
    );
    const msg = try typeErrorMessage(std.testing.allocator,
        \\type Warm { Red, Orange }
        \\type Cold { Blue, Red }
        \\fn main() { val x = Red; @print(0); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`Red` is a variant of `Warm` and of `Cold`, and nothing here says which") != null);
}

// ── 01-std handover: an integer literal takes the width its position asks for ─

test "integer literal: widens to the i64 its position asks for, and a mismatch is located" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn shrink(x: i64) -> i64 { return x - 1000; }
        \\fn wide(n: i64) -> i64 { return n * 1000 + 3 * 86400000; }
        \\fn take(n: i64) -> i64 { return n; }
        \\fn main() {
        \\    val k: i64 = 1000;
        \\    @print(shrink(k) + take(3 * 86400000) + wide(2) + (1000 - k));
        \\    @print(k > 0);
        \\}
    );
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn f(x: i64, y: i32) -> i64 { return x + y; }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "expected i64, got i32") != null);
}

// ── C-18: decisions 44 and 45 ────────────────────────────────────────────────

test "decision 44: `optional<T>` and `Option<T>` are refused naming `?T`" {
    for ([_][]const u8{
        "fn main() { val v: optional<i32> = null; @print(v); }",
        "fn main() { val v: Option<i32> = null; @print(v); }",
    }) |src| {
        const msg = try typeErrorMessage(std.testing.allocator, src);
        defer std.testing.allocator.free(msg);
        try std.testing.expect(std.mem.indexOf(u8, msg, "the optional type is written `?T`") != null);
    }
}

test "decision 45: a member read off a `?T` names `?.`; `?.` reads it" {
    const msg = try typeErrorMessage(std.testing.allocator,
        \\type R(a: i32, b: string)
        \\fn main() { val rs: R[] = [R(a: 1, b: "x")]; @print(rs.at(0).b); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`b` is read off an optional `?R` — write `?.b`") != null);
    try h.assertInfersOk(std.testing.allocator,
        \\type R(a: i32, b: string)
        \\fn main() { val rs: R[] = [R(a: 1, b: "x")]; @print(rs.at(0)?.b); }
    );
}

// ── 01 R7: decision 2 — a value leaves a function through `return` ───────────

test "decision 2: a fn that can fall off its end is refused; every exit form checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn a(c: bool) -> i32 { if (c) { return 1; } else { return 2; }; }
        \\fn b(c: i32) -> string { return case c { 0 { "z" } _ { "o" } }; }
        \\fn d() -> i32 { @todo(); }
        \\fn e(c: i32) -> i32 { return case c { 0 { 1 } _ { 2 } }; }
        \\fn main() { @print(a(true)); }
    );
    const msg = try typeErrorMessage(std.testing.allocator,
        \\fn f(c: bool) -> i32 { if (c) { return 1; }; }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`f` declares `-> i32` and its body can reach its end without a `return`") != null);
}

test "warning: a tuple variable whose name differs from the written label (decision 8 §6 T7)" {
    const msg = try warningMessages(std.testing.allocator,
        \\fn load() -> #(name: string, pop: i32) {
        \\    val city = "SP";
        \\    val pop = 12;
        \\    return #(city, pop);
        \\}
        \\pub fn main() { @print(load().name); }
    );
    defer std.testing.allocator.free(msg);
    try std.testing.expect(std.mem.indexOf(u8, msg, "the variable `city` fills the element labeled `name`") != null);
    try std.testing.expect(std.mem.indexOf(u8, msg, "`pop`") == null);
}
