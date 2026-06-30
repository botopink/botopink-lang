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
        \\record User { name: string }
        \\fn greet(maybeUser: ?User) -> string {
        \\    if (maybeUser) { u ->
        \\        return "hello " + u.name;
        \\    };
        \\    return "no user";
        \\}
        \\@print(greet(User(name: "alice")));
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
        \\@print(and(true, true));
    );
}

test "infer: narrow ---- if null check chained" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn getC() -> i32 {
        \\    val x: ?record { b: ?record { c: i32 } } = null;
        \\    return 0;
        \\}
        \\@print(getC());
    );
}

// ── case narrowing on @Result ──────────────────────────────────────────────────

test "infer: narrow ---- case result ok err" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\#[@result]
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
        \\@print(handle(5));
    );
}

test "infer: narrow ---- case result different payload types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record User { name: string }
        \\enum AppError { NotFound, Timeout(msg: string) }
        \\#[@result]
        \\fn fetchUser(id: i32) -> @Result<User, AppError> {
        \\    if (id == 0) { throw AppError.NotFound; };
        \\    return User(name: "alice");
        \\}
        \\fn main() {
        \\    val r = fetchUser(1);
        \\    case r {
        \\        Ok(u) -> @print(u.name);
        \\        Err(NotFound) -> @print("404");
        \\        Err(Timeout(msg)) -> @print("timeout: " + msg);
        \\    };
        \\}
    );
}

// ── case narrowing on enum variants ───────────────────────────────────────────

test "infer: narrow ---- case enum variant field bindings" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Shape {
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
        \\@print(area(Shape.Circle(2.0)));
    );
}

test "infer: narrow ---- case enum nested variant access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Result_ { OkData(val: record { code: i32, msg: string }), Fail }
        \\fn describe(r: Result_) -> string {
        \\    return case r {
        \\        OkData(d) -> d.msg;
        \\        Fail -> "failed";
        \\    };
        \\}
    );
}

// ── case with OR patterns narrowing ────────────────────────────────────────────

test "infer: narrow ---- case or patterns shared bindings" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Animal {
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
        \\@print(describe(5));
    );
}

test "infer: narrow ---- case guard variant field" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Response {
        \\    Data(code: i32, body: string),
        \\    Error(code: i32),
        \\}
        \\fn handle(r: Response) -> string {
        \\    return case r {
        \\        Data(code, body) if (code == 200) -> body;
        \\        Data(code, body) if (code == 404) -> "not found";
        \\        Error(code) -> "error " + code;
        \\    };
        \\}
    );
}

// ── assert pattern narrowing ───────────────────────────────────────────────────

test "infer: narrow ---- assert pattern after assert" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn process(x: ?i32) -> i32 {
        \\    assert x is Some(n);
        \\    return n + 1;
        \\}
        \\@print(process(42));
    );
}

test "infer: narrow ---- assert pattern enum variant" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\enum Status { Ready, Busy(count: i32), Down }
        \\fn work(s: Status) -> i32 {
        \\    assert s is Busy(n);
        \\    return n;
        \\}
    );
}

// ── early return narrowing ─────────────────────────────────────────────────────

test "infer: narrow ---- early return guard clause" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet(x: ?string) -> string {
        \\    if (!x) { return "nobody"; };
        \\    return "hello " + x;
        \\}
        \\@print(greet("world"));
    );
}

// ── type guard narrowing ───────────────────────────────────────────────────────

test "infer: narrow ---- type guard basic" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> n is i32 {
        \\    return n > 0;
        \\}
        \\@print(isPositive(5));
    );
}

test "infer: narrow ---- type guard narrowing in if" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn isString(x: ?string) -> x is string {
        \\    if (x) { _ -> return true; };
        \\    return false;
        \\}
        \\@print(isString("hello"));
    );
}

// ── AND condition narrowing ────────────────────────────────────────────────────

test "infer: narrow ---- and condition field access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = record { weight: i32 }
        \\fn describe(b: ?Box) -> string {
        \\    if (b && b.weight > 10) {
        \\        return "heavy";
        \\    };
        \\    return "light or none";
        \\}
        \\@print(describe(Box(weight: 20)));
    );
}

// ── optional chaining narrowing ────────────────────────────────────────────────

test "infer: narrow ---- optional chaining field access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Inner = record { value: i32 }
        \\val Outer = record { inner: ?Inner }
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
        \\@print(classify(42));
    );
}

// ── narrowing failure tests ────────────────────────────────────────────────────

test "infer: narrow ---- error variant field in wrong arm" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\enum Shape {
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
