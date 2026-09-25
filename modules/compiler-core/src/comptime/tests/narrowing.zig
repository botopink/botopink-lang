//! comptime: state narrowing tests (if null-check, case variant, type guards).

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

// ── if null-check narrowing ───────────────────────────────────────────────────

test "infer: narrow ---- if null check record field access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type User(name: string)
        \\fn greet(maybeUser: ?User) -> string {
        \\    if (maybeUser) { u ->
        \\        return "hello " + u.name;
        \\    };
        \\    return "no user";
        \\}
        \\fn main() {
        \\    @print(greet(User(name: "alice")));
        \\}
    );
}

test "infer: narrow ---- if null check bool" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn and(a: ?bool, b: ?bool) -> bool {
        \\    if (a) { va ->
        \\        if (b) { vb ->
        \\            return va && vb;
        \\        };
        \\    };
        \\    return false;
        \\}
        \\fn main() {
        \\    @print(and(true, true));
        \\}
    );
}

test "infer: narrow ---- if null check chained" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Inner(c: i32)
        \\type Outer(b: ?Inner)
        \\fn getC(o: ?Outer) -> i32 {
        \\    if (o) { outer ->
        \\        if (outer.b) { inner ->
        \\            return inner.c;
        \\        };
        \\    };
        \\    return 0;
        \\}
        \\fn main() {
        \\    @print(getC(Outer(b: Inner(c: 7))));
        \\    @print(getC(Outer(b: null)));
        \\}
    );
}

// ── case narrowing on @Result ──────────────────────────────────────────────────

test "infer: narrow ---- case result ok err" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn parse(n: i32) -> @Result<string, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return "ok";
        \\}
        \\fn handle(n: i32) -> string {
        \\    val r = parse(n);
        \\    return case r {
        \\        Ok(v) -> "parsed: " + v;
        \\        Err(e) -> "error: " + e;
        \\    };
        \\}
        \\fn main() {
        \\    @print(handle(5));
        \\}
    );
}

test "infer: narrow ---- case result different payload types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type User(name: string)
        \\type AppError { NotFound, Timeout(msg: string) }
        \\fn fetchUser(id: i32) -> @Result<User, AppError> {
        \\    if (id == 0) { throw AppError.NotFound; };
        \\    return User(name: "alice");
        \\}
        \\fn main() {
        \\    val r = fetchUser(1);
        \\    case r {
        \\        Ok(u) -> @print(u.name);
        \\        Err(e) -> @print(case e {
        \\            NotFound -> "404";
        \\            Timeout(msg) -> "timeout: " + msg;
        \\        });
        \\    };
        \\}
    );
}

// ── case narrowing on enum variants ───────────────────────────────────────────

test "infer: narrow ---- case enum variant field bindings" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: f64),
        \\    Rectangle(w: f64, h: f64),
        \\    Point,
        \\}
        \\fn area(s: Shape) -> f64 {
        \\    return case s {
        \\        Circle(radius) -> 3.14 * radius * radius;
        \\        Rectangle(w, h) -> w * h;
        \\        Point -> 0.0;
        \\    };
        \\}
        \\fn main() {
        \\    @print(area(Shape.Circle(2.0)));
        \\}
    );
}

test "infer: narrow ---- case enum nested variant access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Payload(code: i32, msg: string)
        \\type Result_ { OkData(data: Payload), Fail }
        \\fn describe(r: Result_) -> string {
        \\    return case r {
        \\        OkData(d) -> d.msg;
        \\        Fail -> "failed";
        \\    };
        \\}
        \\fn main() {
        \\    @print(describe(Result_.OkData(Payload(code: 200, msg: "ok"))));
        \\}
    );
}

// ── case with OR patterns narrowing ────────────────────────────────────────────

test "infer: narrow ---- case or patterns shared bindings" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Animal {
        \\    Dog(breed: string),
        \\    Cat(breed: string),
        \\    Fish,
        \\}
        \\fn breed(a: Animal) -> string {
        \\    return case a {
        \\        Dog(b) | Cat(b) -> b;
        \\        Fish -> "none";
        \\    };
        \\}
    );
}

// ── case with guard clauses narrowing ──────────────────────────────────────────

test "infer: narrow ---- case guard bound identifier" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return case n {
        \\        x if (x > 0) -> "positive: " + x;
        \\        x if (x < 0) -> "negative: " + x;
        \\        _ -> "zero";
        \\    };
        \\}
        \\fn main() {
        \\    @print(describe(5));
        \\}
    );
}

test "infer: narrow ---- case guard variant field" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Response {
        \\    Data(code: i32, body: string),
        \\    Error(code: i32),
        \\}
        \\fn handle(r: Response) -> string {
        \\    return case r {
        \\        Data(code, body) if (code == 200) -> body;
        \\        Data(code, body) if (code == 404) -> "not found";
        \\        Data(code, body) -> "status " + code;
        \\        Error(code) -> "error " + code;
        \\    };
        \\}
        \\fn main() {
        \\    @print(handle(Response.Data(200, "hi")));
        \\    @print(handle(Response.Error(500)));
        \\}
    );
}

// `assert <expr> is <Pattern>` was a DOCUMENTED SKIP here and in
// `codegen/tests/narrowing.zig`, pinning a parse error "so the test starts
// failing the day the form lands". C-08 decided the form does not land: `is`
// answers a `bool` and does not bind (decision 8 §4), `val assert <Pattern> =
// <expr>;` is the form that binds a pattern's names into the enclosing scope,
// and `docs.md` already lists `assert x is Some(n)` as deliberately absent. The
// refusal it must keep giving — `error[is-variant-binding]` — is pinned at the
// language level by `tests/language/reject/assert_is_pattern.bp`, which is where
// a deliberate refusal belongs.

// ── early return narrowing ─────────────────────────────────────────────────────

test "infer: narrow ---- early return guard clause" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(x: ?string) -> string {
        \\    if (x == null) { return "nobody"; };
        \\    return "hello " + x;
        \\}
        \\fn main() {
        \\    @print(greet("world"));
        \\    @print(greet(null));
        \\}
    );
}

// ── type guard narrowing ───────────────────────────────────────────────────────

test "infer: narrow ---- type guard basic" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> n is i32 {
        \\    return n > 0;
        \\}
        \\fn main() {
        \\    @print(isPositive(5));
        \\}
    );
}

test "infer: narrow ---- type guard narrowing in if" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn isString(x: ?string) -> x is string {
        \\    if (x) { s -> return true; };
        \\    return false;
        \\}
        \\fn main() {
        \\    @print(isString("hello"));
        \\    @print(isString(null));
        \\}
    );
}

// ── AND condition narrowing ────────────────────────────────────────────────────

// DOCUMENTED SKIP — `if (a && b)` parses since C-08 widened the `if`
// condition to `prec.lowest`, so what is left is the checker half: `?Box && …`
// is rejected because an optional is not a bool, and narrowing through an `&&`
// chain does not exist. Missing feature: `&&`-guarded narrowing; owner: spec
// 02 (checker). `narrow ---- if null check record field access` covers the
// nested-`if` form that does work.
test "infer: narrow ---- and condition field access" {
    try h.assertComptimeCompileError(std.testing.allocator, @src(),
        \\val Box = type(weight: i32)
        \\fn describe(b: ?Box) -> string {
        \\    if (b && b.weight > 10) {
        \\        return "heavy";
        \\    };
        \\    return "light or none";
        \\}
        \\fn main() {
        \\    @print(describe(Box(weight: 20)));
        \\}
    );
}

// ── optional chaining narrowing ────────────────────────────────────────────────

test "infer: narrow ---- optional chaining field access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Inner = type(value: i32)
        \\val Outer = type(inner: ?Inner)
        \\fn getValue(o: Outer) -> ?i32 {
        \\    return o.inner?.value;
        \\}
    );
}

// ── else if chain narrowing ────────────────────────────────────────────────────

test "infer: narrow ---- else if chain with null checks" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn classify(x: ?i32) -> string {
        \\    if (x == 0) { return "zero"; }
        \\    else if (x != 0) { return "nonzero: " + x; }
        \\    else { return "null"; }
        \\}
        \\fn main() {
        \\    @print(classify(42));
        \\    @print(classify(null));
        \\}
    );
}

// ── narrowing failure tests ────────────────────────────────────────────────────

test "infer: narrow ---- error variant field in wrong arm" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\type Shape {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\}
        \\fn bad(s: Shape) -> f64 {
        \\    return case s {
        \\        Circle(radius) -> radius;
        \\        Square(side) -> radius;
        \\    };
        \\}
    );
}

// ── 06 C5 — a guard is typed `bool`, and its narrowed type is usable ──────────
// Before C5 the narrowed type sat in `returnType`, so a guard call was typed `T`
// and the narrowing below was unreachable: the `if` unified the call against
// `bool` and errored first.

test "infer: narrow ---- a guard call is a bool" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn isPositive(n: i32) -> n is i32 {
        \\    return n > 0;
        \\}
        \\fn main() {
        \\    val b: bool = isPositive(5);
        \\    @print(b);
        \\}
    );
}

test "infer: narrow ---- a guard narrows the argument in the then-branch" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn isStr(y: ?string) -> y is string {
        \\    return y != null;
        \\}
        \\fn main() {
        \\    val y: ?string = "a";
        \\    if (isStr(y)) {
        \\        val s: string = y;
        \\        @print(s);
        \\    }
        \\}
    );
}

test "infer error: narrow ---- a guard body must answer bool" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> n is i32 {
        \\    return n;
        \\}
    );
}

// ── 06 C12 — a pattern assert checks its subject and its handler ──────────────

test "infer error: narrow ---- an unbound name in a pattern assert reds" {
    // Both halves used to swallow `error.TypeError` into a fresh type variable,
    // so this compiled and only aborted at run time (beam printed
    // `{unresolved_identifier, answer}`).
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn main() {
        \\    val assert 42 = answer catch 0;
        \\    @print("unreachable");
        \\}
    );
}

test "infer error: narrow ---- a pattern assert handler is checked too" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn main() {
        \\    val answer = 42;
        \\    val assert 42 = answer catch fallback;
        \\    @print(answer);
        \\}
    );
}
