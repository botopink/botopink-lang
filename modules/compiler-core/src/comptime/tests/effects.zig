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
        \\record AppError { msg: string }
        \\*fn fetch() -> @Result<i32, AppError> {
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
        \\record IoError { path: string }
        \\*fn load() -> @Result<string, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\*fn run() -> @Result<string, IoError> {
        \\    val s = try load();
        \\    return s;
        \\}
    );
}

test "@Result: multiple catch with different types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record UserError { msg: string }
        \\*fn getName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "missing");
        \\}
        \\*fn getAge() -> @Result<i32, UserError> {
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
        \\*fn parse(s: string) -> @Result<i32, string> {
        \\    if (s == "") {
        \\        throw "empty input";
        \\    }
        \\    return 0;
        \\}
    );
}

test "throw check: record matches declared E = ErrorRecord" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record AppError { code: i32, msg: string }
        \\*fn load() -> @Result<string, AppError> {
        \\    throw AppError(code: 500, msg: "boom");
        \\}
    );
}

test "throw check: throw inside catch handler checks enclosing fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn fetch() -> @Result<i32, string> {
        \\    throw "primary";
        \\}
        \\*fn process() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "secondary";
        \\    return r;
        \\}
    );
}

test "throw check: multiple throw sites all match E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn validate(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) {
        \\        throw "negative";
        \\    }
        \\    if (n > 100) {
        \\        throw "too big";
        \\    }
        \\    return n;
        \\}
    );
}

test "throw check: throw inside nested fn does not check outer fn E" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\*fn outer() -> @Result<i32, string> {
        \\    val cb = fn() {
        \\        throw 404;
        \\    };
        \\    throw "outer error";
        \\}
    );
}

test "throw check error: type mismatch i32 thrown but E = string" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\*fn parse(s: string) -> @Result<i32, string> {
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
        \\record Cell { value: @Result<i32, string> }
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
        \\record User { name: ?string }
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
        \\enum LoadError {
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
        \\record Fetcher {
        \\    url: string,
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

test "context: use with binding in @Context fn passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn useThing() -> @Context<Element, i32> {
        \\    val x = use state(0);
        \\    state(0);
        \\}
    );
}

test "context: use void hook with discard binding passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn effect(cb: i32) -> @Context<Element, i32> {
        \\    cb;
        \\}
        \\fn comp() -> @Context<Element, i32> {
        \\    use effect(0);
        \\    effect(0);
        \\}
    );
}

test "context: struct implement @Context resolved via inline impl passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val n = use state(0);
        \\    Element();
        \\}
    );
}

test "context: custom hook propagates ContextBase transitively passes" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\val AuthState = struct implement @Context<Element, AuthState> {
        \\    loggedIn: bool
        \\}
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn useAuth() -> AuthState {
        \\    val t = use state(0);
        \\    AuthState(loggedIn: true);
        \\}
        \\fn Dashboard() -> Element {
        \\    val {loggedIn} = use useAuth();
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
        \\fn bad() -> @Context<Element, i32> {
        \\    val c = use connection();
        \\    state(0);
        \\}
    );
}

test "context error: struct without @Context impl used with use" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val Plain = struct { x: i32 }
        \\fn make() -> Plain {
        \\    Plain(x: 0);
        \\}
        \\fn comp() -> @Context<Element, i32> {
        \\    val p = use make();
        \\    0;
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
        \\record State<T> { value: T, set: fn(next: T) }
    );
}

// a function type returns an array (`fn() -> T[]`), incl. nested/optional forms.
test "context: fn() -> T[] parses" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn rows() -> i32[] { rows(); }
        \\fn grid() -> i32[][] { grid(); }
        \\fn maybe() -> ?i32[] { maybe(); }
        \\record Builder { make: fn() -> i32[] }
    );
}

// the `{value, set}` hook shape type-checks: a hook returns a record carrying a
// fn-typed `set`, and a component uses it (`s.set(s.value)`).
test "context: {value, set} hook shape type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\record State<T> { value: T, set: fn(next: T) }
        \\fn state<T>(initial: T) -> @Context<Element, State<T>> {
        \\    State(value: initial, set: { n -> });
        \\}
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
        \\fn mk() -> { value: i32, set: fn(next: i32) } {
        \\    record { value: 0, set: { n -> } };
        \\}
    );
}

// `Element[]` coerces into a `Children`-typed parameter (the builder children
// model `div([a, b])`); a single `Element` and a `string` coerce too.
test "context: Element[] coerces into Children" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn div(children: Children) -> Element { Element(); }
        \\fn a() -> Element { Element(); }
        \\val list = div([a(), a()]);
        \\val one = div(a());
        \\val text = div("hello");
    );
}
