//! codegen: state narrowing tests (if null-check, case variant, type guards).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

// ── if null-check narrowing ───────────────────────────────────────────────────

test "js: narrow ---- if null check with print" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x: ?i32 = 42;
        \\    if (x) { n -> @print(n); };
        \\}
    );
}

// ── case narrowing on enum ────────────────────────────────────────────────────

test "js: narrow ---- case enum area with print" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\enum Shape { Circle(radius: f64), Square(side: f64) }
        \\fn area(s: Shape) -> f64 {
        \\    return case s {
        \\        Circle(r) -> 3.14 * r * r;
        \\        Square(s) -> s * s;
        \\    };
        \\}
        \\fn main() {
        \\    @print(area(Shape.Circle(2.0)));
        \\    @print(area(Shape.Square(3.0)));
        \\}
    );
}

// ── case narrowing on @Result ─────────────────────────────────────────────────

test "js: narrow ---- case result ok err with print" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch(ok: bool) -> @Result<string, string> {
        \\    if (ok) { return "data"; };
        \\    throw "fail";
        \\}
        \\fn main() {
        \\    val r1 = fetch(true);
        \\    val msg1 = case r1 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
        \\    @print(msg1);
        \\    val r2 = fetch(false);
        \\    val msg2 = case r2 { Ok(v) -> "OK:" + v; Err(e) -> "ERR:" + e; };
        \\    @print(msg2);
        \\}
    );
}

// ── early return narrowing ────────────────────────────────────────────────────

test "js: narrow ---- early return with print" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn greet(x: ?string) -> string {
        \\    if (!x) { return "nobody"; };
        \\    return "hello " + x;
        \\}
        \\fn main() {
        \\    @print(greet("world"));
        \\    @print(greet(null));
        \\}
    );
}

// ── assert pattern narrowing ──────────────────────────────────────────────────

test "js: narrow ---- assert pattern with print" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(x: ?i32) -> i32 {
        \\    assert x is Some(n);
        \\    return n + 1;
        \\}
        \\fn main() {
        \\    @print(process(42));
        \\}
    );
}

// ── type guard narrowing ──────────────────────────────────────────────────────

test "js: narrow ---- type guard basic codegen" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> n is i32 {
        \\    return n > 0;
        \\}
        \\fn main() {
        \\    @print(isPositive(5));
        \\}
    );
}

test "js: narrow ---- type guard if codegen" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn isString(x: ?string) -> x is string {
        \\    if (x) { _ -> return true; };
        \\    return false;
        \\}
        \\fn main() {
        \\    @print(isString("hello"));
        \\}
    );
}

// ── case narrowing on @Option ─────────────────────────────────────────────────

test "js: narrow ---- case option some none" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\enum @Option<T> { None, Some(T) }
        \\fn describe(opt: @Option<i32>) -> string {
        \\    return case opt {
        \\        None -> "empty";
        \\        Some(v) -> "value: " + v;
        \\    };
        \\}
        \\fn main() {
        \\    @print(describe(@Option<i32>.Some(42)));
        \\    @print(describe(@Option<i32>.None));
        \\}
    );
}

// ── AND condition narrowing ────────────────────────────────────────────────────

test "js: narrow ---- and condition field access" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Box = record { weight: i32 }
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

// ── optional chaining ──────────────────────────────────────────────────────────

test "js: narrow ---- optional chaining field access" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Inner = record { value: i32 }
        \\val Outer = record { inner: ?Inner }
        \\fn getValue(o: Outer) -> ?i32 {
        \\    return o.inner?.value;
        \\}
        \\fn main() {
        \\    val o = Outer(inner: Inner(value: 42));
        \\    @print(getValue(o));
        \\}
    );
}

// ── else if chain narrowing ────────────────────────────────────────────────────

test "js: narrow ---- else if chain with null checks" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(x: ?i32) -> string {
        \\    if (x == 0) { return "zero"; }
        \\    else if (x != 0) { return "nonzero: " + x; }
        \\    else { return "null"; }
        \\}
        \\fn main() {
        \\    @print(classify(42));
        \\    @print(classify(0));
        \\}
    );
}
