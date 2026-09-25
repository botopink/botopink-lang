//! comptime: throw/context/@Result effect checking (split from tests.zig).

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

test "@Result: try unwraps Result to D" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type AppError(msg: string)
        \\#[@result]
        \\fn fetch() -> @Result<i32, AppError> {
        \\    throw AppError(msg: "fail");
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
    );
}

test "@Result: try propagates without catch" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type IoError(path: string)
        \\#[@result]
        \\fn load() -> @Result<string, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\#[@result]
        \\fn run() -> @Result<string, IoError> {
        \\    val s = try load();
        \\    return s;
        \\}
    );
}

test "@Result: multiple catch with different types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type UserError(msg: string)
        \\#[@result]
        \\fn getName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\#[@result]
        \\fn getAge() -> @Result<i32, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\fn loadUser() {
        \\    val name = try getName() catch "anon";
        \\    val age = try getAge() catch 0;
        \\}
    );
}

test "throw check: string matches declared E = string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(s: string) -> @Result<i32, string> {
        \\    if (s == "") {
        \\        throw "empty input";
        \\    };
        \\    return 0;
        \\}
    );
}

test "throw check: record matches declared E = ErrorRecord" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type AppError(code: i32, msg: string)
        \\#[@result]
        \\fn load() -> @Result<string, AppError> {
        \\    throw AppError(code: 500, msg: "boom");
        \\}
    );
}

test "throw check: throw inside catch handler checks enclosing fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    throw "primary";
        \\}
        \\#[@result]
        \\fn process() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "secondary";
        \\    return r;
        \\}
    );
}

test "throw check: multiple throw sites all match E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn validate(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) {
        \\        throw "negative";
        \\    };
        \\    if (n > 100) {
        \\        throw "too big";
        \\    };
        \\    return n;
        \\}
    );
}

test "throw check: throw inside nested fn does not check outer fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn outer() -> @Result<i32, string> {
        \\    val cb = fn() {
        \\        throw 404;
        \\    };
        \\    throw "outer error";
        \\}
    );
}

test "throw check error: type mismatch i32 thrown but E = string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse(s: string) -> @Result<i32, string> {
        \\    throw 404;
        \\}
    );
}

test "throw check error: throw without enclosing Result return type" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn run() -> i32 {
        \\    throw "x";
        \\}
    );
}

// ── net-new (v0.beta.13 · A2): errors / result / option ──────────────────────

// A `@Result<T, E>` is usable as a record FIELD type: constructing the record
// with a result-returning call type-checks, and the field's `.unwrapOr` resolves
// the wrapped value.
test "infer: net-new ---- @Result as a record field" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> { return n; }
        \\type Cell(value: @Result<i32, string>)
        \\fn main() {
        \\    val c = Cell(value: parse(2));
        \\    val v: i32 = c.value.unwrapOr(0);
        \\}
    );
}

// `?.` optional chaining over an optional receiver yields an Option, which
// `unwrapOr` collapses back to a concrete value.
test "infer: net-new ---- optional chain yields an Option resolved by unwrapOr" {
    try h.assertInfersOk(std.testing.allocator,
        \\type User(name: ?string)
        \\fn nameOf(u: ?User) -> string {
        \\    return u?.name.unwrapOr("anon");
        \\}
    );
}

// `val x = try f()` in expression position binds the unwrapped Ok value, which
// is then usable as the underlying `T`.
test "infer: net-new ---- val x = try f() binds the unwrapped Ok value" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> { return n; }
        \\#[@result]
        \\fn compute() -> @Result<i32, string> {
        \\    val x = try parse(2);
        \\    return x + 1;
        \\}
    );
}

// `throw` of an enum error variant unifies the thrown value with the enclosing
// fn's declared `E = <that enum>` — including a payload-carrying variant.
test "infer: net-new ---- throw of an enum error variant unifies with E" {
    try h.assertInfersOk(std.testing.allocator,
        \\type LoadError {
        \\    NotFound,
        \\    Invalid(reason: string),
        \\}
        \\#[@result]
        \\fn load() -> @Result<i32, LoadError> {
        \\    throw LoadError.Invalid(reason: "bad");
        \\}
    );
}

// ── net-new (v0.beta.13 · A1): effect markers ────────────────────────────────

// An effect marker applies to a record METHOD (not only a top-level fn): the
// `#[@result]` method body may `throw`, and the throw checks against the
// method's declared `E`.
test "infer: net-new ---- effect marker on a record method" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Fetcher(
        \\    url: string) {
        \\    #[@result]
        \\    fn load(self: Self) -> @Result<string, string> {
        \\        throw self.url;
        \\    }
        \\}
    );
}

// A compound return `@Future<@Result<T, E>>` type-checks: the `#[@future]` body
// `await`s an inner future and returns a `@Result` produced by a `#[@result]`
// fn — the two effect layers compose.
test "infer: net-new ---- compound @Future<@Result> return type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    return n;
        \\}
        \\#[@future]
        \\fn ready() -> @Future<i32> {
        \\    return 5;
        \\}
        \\#[@future]
        \\fn fetch() -> @Future<@Result<i32, string>> {
        \\    val n = await ready();
        \\    return parse(n);
        \\}
    );
}

// Decision 88 (front 19 of 1.0.10-beta): a body activates a hook only under
// `#[@context]`; the return type (`-> Element`, or `-> @Context<B, R>` for a
// custom hook) still decides the owner every `use` must agree on.
test "context: use with binding in @Context fn passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn thing() -> @Context<Element, i32> {
        \\    val x = use state(0);
        \\    state(0);
        \\}
    );
}

test "context: use void hook with discard binding passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn effect(cb: i32) -> @Context<Element, i32> {
        \\    cb;
        \\}
        \\#[@context]
        \\fn comp() -> @Context<Element, i32> {
        \\    use effect(0);
        \\    effect(0);
        \\}
    );
}

test "context: record implement @Context resolved via inline impl passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn Counter() -> Element {
        \\    val n = use state(0);
        \\    Element();
        \\}
    );
}

test "context: custom hook propagates ContextBase transitively passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\val AuthState = type(
        \\    loggedIn: bool
        \\) implement @Context<Element, AuthState>
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn auth() -> AuthState {
        \\    val t = use state(0);
        \\    AuthState(loggedIn: true);
        \\}
        \\#[@context]
        \\fn Dashboard() -> Element {
        \\    val {loggedIn} = use auth();
        \\    Element();
        \\}
    );
}

test "context error: use in fn returning string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn bad() -> string {
        \\    val x = use state(0);
        \\    "hi";
        \\}
    );
}

test "context error: ContextBase mismatch Element vs Http" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn connection() -> @Context<Http, i32> {
        \\    0;
        \\}
        \\#[@context]
        \\fn bad() -> @Context<Element, i32> {
        \\    val c = use connection();
        \\    state(0);
        \\}
    );
}

test "context error: record without @Context impl used with use" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Plain = type(x: i32)
        \\fn make() -> Plain {
        \\    Plain(x: 0);
        \\}
        \\#[@context]
        \\fn comp() -> @Context<Element, i32> {
        \\    val p = use make();
        \\    0;
        \\}
    );
}

// Decision 88: the return type implements `@Context` (a component's owner
// type), but the fn is not `#[@context]` — a `use` in it is refused, naming
// the annotation. A bare `-> Element` without the annotation is an ordinary fn.
test "context error: use without #[@context] on a -> Element body" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val n = use state(0);
        \\    Element();
        \\}
    );
}

// Decision 88: `#[@context]` on a fn whose return type is the owner type
// (`Element` implements `@Context<Element, Element>`), not the `@Context<…>`
// wrapper — the component form; the effect accepts either.
test "context: #[@context] fn -> Element (owner type) passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn counter(n: i32) -> @Context<Element, i32> {
        \\    val c = use state(n);
        \\    return c;
        \\}
        \\#[@context]
        \\fn Counter() -> Element {
        \\    val n = use counter(0);
        \\    return Element();
        \\}
    );
}

// Decisions 89 + 90: `contextInfoFromReturn` looks through `@Future<T>` to
// `T`'s owner, and a wrapper effect (`#[@future]`) whose unwrapped return type
// owns a context activates hooks on its own — R5 forbids a second annotation,
// so `#[@future] #[@context]` is not a way to spell this.
test "context: #[@future] fn -> @Future<Element> activates without #[@context]" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\val Request = type(path: string) implement @Context<Element, Request>
        \\fn request() -> @Context<Element, Request> {
        \\    Request(path: "/");
        \\}
        \\#[@future]
        \\fn Page() -> @Future<Element> {
        \\    val r = use request();
        \\    return Element();
        \\}
    );
}

// Decision 90 is a dispensation, not a way to switch a refusal off: the
// wrapper effect is there, but `@Future<i32>` unwraps to a type that owns no
// context, so there is no owner for the `use` to agree on — `use-of-non-context-fn`.
test "context error: #[@future] fn -> @Future<i32> still refuses use" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@future]
        \\fn Page() -> @Future<i32> {
        \\    val n = use state(0);
        \\    return 0;
        \\}
    );
}

// Decision 90 keeps decision 67's other refusal: `#[@context]` over a return
// type that owns no context is `effect-wrapper-mismatch` — the annotation and
// the return wrapper must name the same effect.
test "context error: #[@context] on a return type that owns no context" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@context]
        \\fn bad() -> i32 {
        \\    return 0;
        \\}
    );
}

// Decision 90 does not widen the owner check either: a `#[@future]` body whose
// unwrapped owner is `Element` may not activate a hook anchored elsewhere.
test "context error: #[@future] fn -> @Future<Element> owner mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn connection() -> @Context<Http, i32> {
        \\    0;
        \\}
        \\#[@future]
        \\fn Page() -> @Future<Element> {
        \\    val c = use connection();
        \\    return Element();
        \\}
    );
}

// ── record/array ergonomics the hook/builder model needs ──────────────────────
//
// The features a `@Context` hook + markup-builder model relies on: records with
// function-typed fields (the `{value, set}` hook shape), anonymous record types
// as annotations, function types returning arrays, and `Children` coercion.

// a record can carry a function-typed field (`set: fn(next: T)`); `set` is a
// soft keyword, valid as a field name.
test "context: record with a fn-typed field parses" {
    try h.assertInfersOk(std.testing.allocator,
        \\type State<T>(value: T, set: fn(next: T))
    );
}

// a function type returns an array (`fn() -> T[]`), incl. nested/optional forms.
test "context: fn() -> T[] parses" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn rows() -> i32[] { rows(); }
        \\fn grid() -> i32[][] { grid(); }
        \\fn maybe() -> ?i32[] { maybe(); }
        \\type Builder(make: fn() -> i32[])
    );
}

// the `{value, set}` hook shape type-checks: a hook returns a record carrying a
// fn-typed `set`, and a component uses it (`s.set(s.value)`).
test "context: {value, set} hook shape type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\type State<T>(value: T, set: fn(next: T))
        \\fn state<T>(initial: T) -> @Context<Element, State<T>> {
        \\    State(value: initial, set: { n -> });
        \\}
        \\#[@context]
        \\fn Counter() -> Element {
        \\    val s = use state(0);
        \\    s.set(s.value);
        \\    Element();
        \\}
    );
}

// an anonymous record TYPE is accepted as a return annotation, and a
// `record { … }` literal unifies with it field-by-field.
test "context: anonymous record type as return annotation" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn mk() -> #(value: i32, set: fn(next: i32)) {
        \\    #(0, { n -> });
        \\}
    );
}

// `Element[]` coerces into a `Children`-typed parameter (the builder children
// model `div([a, b])`); a single `Element` and a `string` coerce too.
test "context: Element[] coerces into Children" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn div(children: Children) -> Element { Element(); }
        \\fn a() -> Element { Element(); }
        \\val list = div([a(), a()]);
        \\val one = div(a());
        \\val text = div("hello");
    );
}

// ── decision 95: the effects are a chain ──────────────────────────────────────
//
// `@Context` ⊃ `@Future` ⊃ `@Result`, `@FutureGenerator` ⊃ `@Future`,
// `@ResultGenerator` ⊃ `@Result`, and an annotation grants every body operation at or
// below its own level. The order itself is `comptime/effect_chain.zig`'s unit
// tests (and its drift gate against `libs/std/src/builtins.d.bp`); what follows
// is the order as the CHECKER applies it — one cell per granted capability and
// one per refusal, since a rule that only a table believes is not a rule.
//
// `tests/language` carries the half of this that RUNS. One row cannot: `await`
// inside a `#[@context]` body is legal here and executes on erlang, wasm and
// beam, but commonJS lowers `#[@context]` to a plain `function` and the emitted
// `await` is a JS SyntaxError. The legality is this front's; the `async`
// keyword is the backend's, and the row is a handoff rather than a capability
// left refused.

const chain_preamble =
    \\val Element = type implement @Context<Element, Element> { }
    \\fn state(initial: i32) -> @Context<Element, i32> {
    \\    initial;
    \\}
    \\#[@result]
    \\fn parse(n: i32) -> @Result<i32, string> {
    \\    return n;
    \\}
    \\#[@future]
    \\fn fetch(n: i32) -> @Future<i32> {
    \\    return n;
    \\}
    \\
;

test "chain: #[@result] is the base — it answers `try`" {
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\#[@result]
        \\fn doubled(n: i32) -> @Result<i32, string> {
        \\    val v = try parse(n);
        \\    return v * 2;
        \\}
    );
}

test "chain: #[@future] implements @Result — it answers `try` and `await`" {
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\#[@future]
        \\fn load(n: i32) -> @Future<i32> {
        \\    val v = try parse(n);
        \\    val w = await fetch(v);
        \\    return w;
        \\}
    );
}

test "chain: #[@resultGenerator] implements @Result — it answers `try` and `yield`" {
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\#[@resultGenerator]
        \\fn upTo(n: i32) -> @ResultGenerator<i32> {
        \\    val limit = try parse(n);
        \\    yield limit;
        \\}
    );
}

test "chain: #[@futureGenerator] implements @Future — `try`, `await`, `yield`" {
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\#[@futureGenerator]
        \\fn stream(n: i32) -> @FutureGenerator<i32, string> {
        \\    val v = try parse(n);
        \\    val w = await fetch(v);
        \\    yield w;
        \\}
    );
}

test "chain: #[@context] implements @Future implements @Result — `use`, `await`, `try`" {
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\#[@context]
        \\fn Widget(n: i32) -> Element {
        \\    val c = use state(0);
        \\    val v = try parse(n);
        \\    val w = await fetch(v);
        \\    return Element();
        \\}
    );
}

// Decision 103 (question 97 (b)) — `@Generator<T>` has no error channel and
// stays out of the chain. Its cell asserts the REFUSAL, which names
// `@ResultGenerator<T, E>`, the generator that has one.
test "chain error: `try` inside #[@generator] — question 97 keeps it refused" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(), chain_preamble ++
        \\#[@generator]
        \\fn counted(n: i32) -> @Generator<i32> {
        \\    val v = try parse(n);
        \\    yield v;
        \\}
    );
}

// The chain grants downwards and never upwards: one cell per capability written
// one level above the body that holds it.
test "chain error: `try` in a plain fn — no effect, no error channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(), chain_preamble ++
        \\fn plain(n: i32) -> i32 {
        \\    val v = try parse(n);
        \\    return v;
        \\}
    );
}

test "chain error: `await` inside #[@resultGenerator] — @ResultGenerator does not implement @Future" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(), chain_preamble ++
        \\#[@resultGenerator]
        \\fn bad(n: i32) -> @ResultGenerator<i32> {
        \\    val w = await fetch(n);
        \\    yield w;
        \\}
    );
}

test "chain error: `yield` inside #[@result] — `yield` is no level of the chain" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(), chain_preamble ++
        \\#[@result]
        \\fn bad(n: i32) -> @Result<i32, string> {
        \\    yield n;
        \\}
    );
}

test "chain error: `yield` inside #[@context] — the top of the chain still cannot yield" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(), chain_preamble ++
        \\#[@context]
        \\fn Bad(n: i32) -> Element {
        \\    yield n;
        \\}
    );
}

// Decision 105 — a `yield` inside a `for` / `while` feeds the nearest generator
// scope, and a body the chain grants no `yield` has none: the loop does not
// make it legal. This is the cell that pinned the opposite (decision 8 §10's
// comprehension) before the decision.
test "chain error: `yield` inside a loop still needs a generator scope (decision 105)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn collected() -> @Future<i32> {
        \\    var n = 0;
        \\    for ([1, 2, 3]) { x -> yield x * 2; };
        \\    return n;
        \\}
    );
}

test "chain: `try … catch` needs no channel — it propagates nothing" {
    // The gated form is bare `try`, which RETURNS the error out of the body.
    // `try <e> catch <f>` handles it on the spot, so a plain `fn` may hold it.
    try h.assertInfersOk(std.testing.allocator, chain_preamble ++
        \\fn plain(n: i32) -> i32 {
        \\    val v = try parse(n) catch 0;
        \\    return v;
        \\}
    );
}

// ── decision 96: one ContextBase per function ─────────────────────────────────
//
// The anchor is a property of the BODY, not of each activation: the first `use`
// fixes it and every later one must agree. Two refusals live here and they are
// not the same rule —
//
//   RC2 (`context-anchor-violation: function returns …`) is the DECLARATION's:
//   one `use` anchored at a base the return type never named. It fires before
//   any anchor exists, which is why a single misanchored `use` still meets it.
//
//   Decision 96's (`… every `use` in one function resolves against the same
//   ContextBase`) is the BODY's: a second `use` disagreeing with the first,
//   refused at its own site with both bases and the line that fixed the anchor.
//
// Measured while implementing this: the premise decision 96 corrects —
// "today RC2 asks only that a hook be anchored at a SUBTYPE of the body's
// Base, so two different subtypes can meet in one function" — was true of the
// documentation (`builtins.d.bp` § 1C, which front 20 step 2 rewrote) and never
// of the checker, which has always compared the two names for equality. What
// this step adds is the anchor as a thing the body owns, and the refusal that
// says which `use` committed it.

test "anchor: a body whose hooks share a base compiles" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn memo(value: i32) -> @Context<Element, i32> {
        \\    value;
        \\}
        \\#[@context]
        \\fn Widget() -> Element {
        \\    val a = use state(0);
        \\    val b = use memo(a);
        \\    return Element();
        \\}
    );
}

test "anchor error: two `use`s at different bases in one body (decision 96)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\val Http = type implement @Context<Http, Http> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn connection() -> @Context<Http, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn Mixed() -> Element {
        \\    val a = use state(0);
        \\    val b = use connection();
        \\    return Element();
        \\}
    );
}

test "anchor: each body starts over — a sibling fn may anchor elsewhere" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\val Http = type implement @Context<Http, Http> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn connection() -> @Context<Http, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn Widget() -> Element {
        \\    val a = use state(0);
        \\    return Element();
        \\}
        \\#[@context]
        \\fn Server() -> Http {
        \\    val c = use connection();
        \\    return Http();
        \\}
    );
}

// ── decision 103: a type that wants to be iterated exposes a generator method ──
//
// There is no iterable behavior (decision 103): a `behavior` would only buy the
// sugar `for (g)`, and surface nobody uses drifts. The shape is an ordinary
// method answering a generator, and the consumer calls it — `for (bag.iter())`. The
// annotation belongs to the implementation (a `behavior` method is declarative
// and carries none — the R1/R2 error).

test "decision 103: a type exposes a #[@resultGenerator] fn iter and a body iterates it" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Bag(items: i32[]) {
        \\    #[@resultGenerator]
        \\    fn iter(self: Self) -> @ResultGenerator<i32> {
        \\        for (self.items) { x -> yield x; };
        \\    }
        \\}
        \\#[@result]
        \\fn total(b: Bag) -> @Result<i32, string> {
        \\    var acc = 0;
        \\    for (b.iter()) { x -> acc = acc + x; };
        \\    return acc;
        \\}
    );
}

// Decision 103 — a loop over a fallible generator is a `try` in the body that
// iterates it, so a plain `fn` (no error channel) is refused naming the level;
// `@Generator<T>` is infallible and iterable anywhere.
test "chain error: a plain fn iterating a @ResultGenerator — the loop is a `try`" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@resultGenerator]
        \\fn upTo(n: i32) -> @ResultGenerator<i32, string> {
        \\    yield n;
        \\}
        \\fn total(n: i32) -> i32 {
        \\    var acc = 0;
        \\    for (upTo(n)) { x -> acc = acc + x; };
        \\    return acc;
        \\}
    );
}

test "chain: a plain fn iterates a @Generator<T> — infallible, no level needed" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@generator]
        \\fn upTo(n: i32) -> @Generator<i32> {
        \\    yield n;
        \\}
        \\fn total(n: i32) -> i32 {
        \\    var acc = 0;
        \\    for (upTo(n)) { x -> acc = acc + x; };
        \\    return acc;
        \\}
    );
}

// Front 19 step 3 (1.0.10-beta): `val #(a, b) = use …` binds each name to the
// element of `R` at its position — `push` is `fn(action: i32) -> i32`, so
// `push(shown)` types and `push("x")` reds — and the arity is checked at the
// binding, as is that `R` is a tuple at all (decision 67: located, no flag).
test "context: use tuple destructure binds element types" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = type implement @Context<Element, Element> { }
        \\fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
        \\    val push = { action -> f(base, action) };
        \\    #(base, push);
        \\}
        \\#[@context]
        \\fn LikeWidget() -> Element {
        \\    val #(shown, push) = use optimistic(12, { c, a -> c + a });
        \\    push(shown);
        \\    Element();
        \\}
    );
}

test "context error: use tuple destructure element is R's, not a fresh var" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
        \\    val push = { action -> f(base, action) };
        \\    #(base, push);
        \\}
        \\#[@context]
        \\fn LikeWidget() -> Element {
        \\    val #(shown, push) = use optimistic(12, { c, a -> c + a });
        \\    push("x");
        \\    Element();
        \\}
    );
}

test "context error: use tuple destructure arity mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
        \\    val push = { action -> f(base, action) };
        \\    #(base, push);
        \\}
        \\#[@context]
        \\fn LikeWidget() -> Element {
        \\    val #(shown) = use optimistic(12, { c, a -> c + a });
        \\    Element();
        \\}
    );
}

test "context error: use tuple destructure of a hook whose R is not a tuple" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Element = type implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\#[@context]
        \\fn Counter() -> Element {
        \\    val #(count, setCount) = use state(0);
        \\    Element();
        \\}
    );
}
