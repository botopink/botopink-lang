//! codegen: val/fn/call/operators/assign/self/comments (split from tests.zig).

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

test "js: val ---- number literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val x = 42;
    );
}

test "js: val ---- string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
    );
}

test "js: val ---- binary expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val sum = 1 + 2;
        \\fn main() -> void {
        \\    print(sum);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: fn ---- private function with return" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        \\val result = double(5);
        \\fn main() -> void {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: fn ---- max via if comparison" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn max(a: i32, b: i32) -> i32 {
        \\    if (a < b) {
        \\        return b;
        \\    } else {
        \\        return a;
        \\    }
        \\}
        \\fn main() -> void {
        \\    print(max(3, 7));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: fn ---- pub exported function" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\val result = add(3, 4);
        \\fn main() -> void {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: fn ---- with local binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 {
        \\    val result = x * 2;
        \\    return result;
        \\}
        \\val output = double(10);
        \\fn main() -> void {
        \\    print(output);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A qualified call inside a method body keeps BOTH arguments — `List` is a
// namespace, not a value to dispatch on. `List` used to be declared nowhere,
// which only compiled while `inferTypeMethods` swallowed its method bodies'
// errors (06 C9); it is a real type with an associated fn now. commonJS emits
// the same `List.map(this.items, f)` as before; erlang and beam resolve the
// call locally (`map/2`, `call_last {f, 3}`) instead of emitting a remote call
// into a `list` module no program declared. The arity — two arguments, the
// receiver NOT dispatched on — is what this pins, and it is the same on all
// four backends.
test "js: call ---- qualified module call resolves arity" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type List(tag: i32) {
        \\    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        \\        return items.map(f);
        \\    }
        \\}
        \\type Pipeline(
        \\    items: i32[]) {
        \\    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        \\        return List.map(self.items, f);
        \\    }
        \\}
    );
}

// The trailing lambda becomes the call's LAST argument, after the receiver
// argument — arity 2, not 1. The lambda is parameterless: a trailing lambda's
// own parameter is not typed from the callee's declared `fn(item: i32)` param
// on a qualified associated-fn call (`{ x -> … }` reds `unbound variable 'x'`),
// a gap this fixture used to hide behind the swallowed method body and which
// reproduces at top level too.
test "js: call ---- qualified module call with trailing lambda arity" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type List(tag: i32) {
        \\    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        \\        return items;
        \\    }
        \\}
        \\type Pipeline(
        \\    items: i32[]) {
        \\    fn doubled(self: Self) -> i32[] {
        \\        return List.each(self.items) { ->
        \\            return 2;
        \\        };
        \\    }
        \\}
    );
}

test "js: operators ---- comparison" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> bool {
        \\    return n > 0;
        \\}
        \\fn main() -> void {
        \\    print(isPositive(5));
        \\    print(isPositive(-1));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- equality maps to ==" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn isZero(n: i32) -> bool {
        \\    return n == 0;
        \\}
        \\fn main() -> void {
        \\    print(isZero(0));
        \\    print(isZero(42));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- logical and" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn both(a: bool, b: bool) -> bool {
        \\    return a && b;
        \\}
        \\fn main() -> void {
        \\    print(both(true, false));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- logical or" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn either(a: bool, b: bool) -> bool {
        \\    return a || b;
        \\}
        \\fn main() -> void {
        \\    print(either(false, true));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- logical not" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn negate(v: bool) -> bool {
        \\    return !v;
        \\}
        \\fn main() -> void {
        \\    print(negate(true));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- chained logical and" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn allThree(a: bool, b: bool, c: bool) -> bool {
        \\    return a && b && c;
        \\}
    );
}

test "js: val ---- null literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val nothing = null;
    );
}

test "js: val ---- optional annotation with null" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val msg: ?string = null;
    );
}

test "js: call ---- trailing lambda block" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn run(f: fn(i32) -> string) -> void {
        \\    panic("not implemented");
        \\}
        \\fn main() -> void {
        \\    run { x ->
        \\        return "done";
        \\    };
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: call ---- trailing lambda with multiple params" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn calc(factor: i32, f: fn(i32, i32) -> i32) -> i32 {
        \\    panic("not implemented");
        \\}
        \\fn main() -> void {
        \\    val r = calc(2) { a, b ->
        \\        return 0;
        \\    };
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: val ---- pub val declaration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val HOST = "localhost";
    );
}

test "js: comment ---- single line before fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\// This is a comment
        \\fn main() -> void {
        \\    null;
        \\}
    );
}

test "js: comment ---- inside function body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    // Initialize value
        \\    val x = 1;
        \\    // Return null
        \\    null;
        \\}
    );
}

test "js: doc comment ---- before fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\/// This function greets the user
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "js: doc comment ---- multiline before struct" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\/// User account structure
        \\/// Holds name and email
        \\val Account = type(name: string, email: string);
    );
}

test "js: module comment ---- at top of file" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\//// This module provides utility functions
        \\//// for string manipulation
        \\
        \\fn capitalize(s: string) -> string {
        \\    return s;
        \\}
    );
}

test "js: assign ---- update var with plusEq" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    var count = 0;
        \\    count += 1;
        \\    print(count);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A record is immutable (decision 37): assigning `self.count` is refused at
// the assignment, with the `..self` update named. The fixture used to write the
// method without a `self` parameter and compiled only because another body's
// `self` leaked into this one (01 step 13); every backend's output was wrong.
test "js: field assign ---- self.field update" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\val Counter = type(
        \\    count: i32 = 0) {
        \\    fn inc(self: Self) -> void {
        \\        self.count += 1;
        \\    }
        \\};
    );
}

test "js: self ---- field access in method" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Point = type(
        \\    x: i32,
        \\    y: i32) {
        \\    fn sum(self: Self) -> i32 {
        \\        return self.x + self.y;
        \\    }
        \\};
    );
}

test "js: block ---- a block's value is its tail (decision 525)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val input = 42;
        \\    val status = {
        \\        val calculo = input * 2;
        \\        if (calculo > 100) {
        \\            "Alto"
        \\        } else {
        \\            "Baixo"
        \\        }
        \\    };
        \\    return status;
        \\}
    );
}

test "js: string ---- interpolation lowers to concat" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val name = "world";
        \\    print("hi ${name}!");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── net-new (v0.beta.13 · A8): backend-parity snapshots ──────────────────────

// String interpolation with TWO holes (`"${a}-${b}"`) lowers consistently on
// every backend (node/erlang/beam/wasm) — the snapshot pins each lowering.
test "js: net-new ---- interpolation with two holes lowers on every backend" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn label(a: string, b: string) -> string {
        \\    return "${a}-${b}";
        \\}
    );
}

// Record `==` vs array `==`: the per-backend snapshots pin how each `==` lowers
// and expose that equality is *backend-defined* — node/wasm emit reference
// equality (`===`) for both records and arrays, while erlang/beam emit Erlang
// term equality (`=:=`, structural) for both. No backend gives records a
// special structural `==` that arrays lack.
test "js: net-new ---- record equality vs array equality across backends" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn recordEq() -> bool {
        \\    val a = Point(x: 1, y: 2);
        \\    val b = Point(x: 1, y: 2);
        \\    return a == b;
        \\}
        \\fn arrayEq() -> bool {
        \\    val xs = [1, 2];
        \\    val ys = [1, 2];
        \\    return xs == ys;
        \\}
    );
}

test "js: tuple ---- equality is positional, and labels take no part" {
    // Decision 8 §6 T6 — a tuple is positional at run time, so `==` compares
    // its elements. A tuple is a JS array and `==` lowers to `===`, which
    // compares references, so two structurally equal tuples were unequal and
    // the negative case passed for the wrong reason. T1/T5: the labels a
    // construction lends take no part, and a different arity is not equal.
    //
    // Decision 210 made it every composite: a record, an array and a variant
    // call their type's generated `__bp_eq_<T>` too (`js/AGENTS.md`).
    //
    // A RUN LOG, not a snapshot: the erlang, beam and wasm baselines of this
    // program are not this front's to record.
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    val a = #(1, "a");
        \\    val b = #(1, "a");
        \\    val c = #(1, "b");
        \\    print(a == b);
        \\    print(a != b);
        \\    print(a == c);
        \\    print(a != c);
        \\    val name = "SP";
        \\    val pop = 12;
        \\    val labeled = #(name, pop);
        \\    val plain = #("SP", 12);
        \\    print(labeled == plain);
        \\    val n1 = #(#(1, 2), "x");
        \\    val n2 = #(#(1, 2), "x");
        \\    val n3 = #(#(1, 3), "x");
        \\    print(n1 == n2);
        \\    print(n1 == n3);
        \\    val wide = #(1, "a", 2);
        \\    print(a == wide);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "true\nfalse\nfalse\ntrue\ntrue\ntrue\nfalse\nfalse\n");
}

test "js: operators ---- plus on untyped operands and division of floats" {
    // A lambda parameter carries no type: `x + y` over two strings concatenates
    // and `/` over floats divides — erlang's `+` and `div` raised `badarith`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn average(xs: Array<f64>) -> f64 {
        \\    var total = 0.0;
        \\    var n = 0.0;
        \\    for (xs) { x ->
        \\        total = total + x;
        \\        n = n + 1.0;
        \\    };
        \\    return total / n;
        \\}
        \\fn main() -> void {
        \\    val cat: fn(string, string) -> string = { x, y -> x + y };
        \\    print(cat("ab", "cd"));
        \\    print(average([2.0, 4.0, 9.0]));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: operators ---- abs on an i32 receiver reaches Signed" {
    // `abs` is declared on `Signed`, below `Integer`: the erlang lowering used
    // to walk from `Integer`, miss it, and emit the auto-imported `abs/1`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn mag(n: i32) -> i32 {
        \\    return n.abs();
        \\}
        \\fn main() -> void {
        \\    print(mag(-7));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// The program this test used to carry — `val assert 42 = answer catch 0;` with
// `answer` declared nowhere — no longer compiles: 06 C12 stopped the pattern
// assert from swallowing its subject's type error, so the read reds at the name
// (`comptime/tests/narrowing.zig`, "an unbound name in a pattern assert reds").
// beam's `{unresolved_identifier, …}` abort stays as the backstop for a name
// that reaches codegen from generated code, which no source can express here.
