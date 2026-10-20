//! codegen: builtin/stdlib/assert (split from tests.zig).

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

test "js: assert ---- simple assertion" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> void {
        \\    assert true;
        \\}
    );
}

test "js: assert ---- with arithmetic comparison" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> void {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "js: assert ---- with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> void {
        \\    assert false, "error message";
        \\}
    );
}

test "js: assert ---- array equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> void {
        \\    assert [] == [];
        \\}
    );
}

test "js: assert pattern ---- with catch throw" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() -> Result<void, string> {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch throw "is not person";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with catch default value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() -> void {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "js: assert pattern ---- with list pattern" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> Result<void, string> {
        \\    val items = [1, 2, 3];
        \\    val assert [first, ..] = items catch throw "not a list";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> Result<void, string> {
        \\    val greeting = "hello";
        \\    val assert "hello" = greeting catch throw "not hello";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with number literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> Result<void, string> {
        \\    val answer = 42;
        \\    val assert 42 = answer catch throw "not 42";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with enum variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parse() -> Result<i32, string> {
        \\    return 42;
        \\}
        \\fn main() -> void {
        \\    val result = parse();
        \\    val assert Ok(value) = result;
        \\    print(value);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: assert pattern ---- with empty list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> Result<void, string> {
        \\    val list: i32[] = [];
        \\    val assert [] = list catch throw "not empty";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with multiple element list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> Result<void, string> {
        \\    val numbers = [1, 2, 3];
        \\    val assert [1, 2, 3] = numbers catch throw "not matching";
        \\    return;
        \\}
    );
}

test "js: assert pattern ---- with list and rest" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() -> void {
        \\    val items = [1, 2, 3, 4];
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "js: builtin ---- @todo with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn notImplemented() -> void {
        \\    panic("implement this function");
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: builtin ---- @panic with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fail() -> void {
        \\    panic("something went wrong");
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

// Decision 430 (B-41): a library's abort reads the same on every target — the
// message a `@panic` was given reaches stderr unchanged (concatenated, with
// quotes and a non-ASCII dash), then the trap. The wasm backend dropped it.
test "wat: builtin ---- @panic message reaches stderr before the trap" {
    try h.assertWasmRunLog(std.testing.allocator,
        \\fn refuse(name: string) -> void {
        \\    panic("lib: '" + name + "' is in no known namespace — a prefix");
        \\}
        \\fn main() -> void {
        \\    print("before");
        \\    refuse("--gutter");
        \\    print("after");
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    ,
        \\before
        \\panic: lib: '--gutter' is in no known namespace — a prefix
        \\RUNTIME TRAP (wasmtime):
        \\wasm trap: wasm `unreachable` instruction executed
        \\
    );
}

// Decision 430 (B-41): the same message, run on every backend the way
// `botopink run` runs it — erlang and beam printed the term with the message's
// bytes as numbers once one left ASCII, wasm trapped with no text.
test "every backend: builtin ---- @panic message reaches stderr unchanged" {
    try h.assertAbortWritesEveryBackend(std.testing.allocator,
        \\fn refuse(name: string) -> void {
        \\    panic("lib: '" + name + "' is in no known namespace — a prefix");
        \\}
        \\fn main() -> void {
        \\    print("before");
        \\    refuse("--gutter");
        \\    print("after");
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    , "lib: '--gutter' is in no known namespace — a prefix\n");
}

// Decision 535: an uncaught abort writes the `Failure` an `attempt` would have
// answered, `<kind>: <message>`, never the runtime's raw term.
test "every backend: builtin ---- an uncaught @panic writes panic: <message>" {
    try h.assertAbortWritesEveryBackend(std.testing.allocator,
        \\fn main() -> void {
        \\    print("before");
        \\    panic("boom — 2");
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    , "panic: boom — 2\n");
}

test "every backend: builtin ---- an uncaught @todo writes panic: <message>" {
    try h.assertAbortWritesEveryBackend(std.testing.allocator,
        \\fn main() -> void {
        \\    panic("later");
        \\}
        \\
        \\import {failure.panic} from "std";
    , "panic: later\n");
}

test "every backend but wasm: builtin ---- an uncaught integer division by zero writes panic: <message>" {
    try h.assertAbortWritesFailure(std.testing.allocator,
        \\fn div(a: i32, b: i32) -> i32 {
        \\    return a / b;
        \\}
        \\fn main() -> void {
        \\    print(div(1, 0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "panic: integer division by zero: / on i32 at ");
}

test "every backend: builtin ---- an uncaught failed assert writes panic: <message>" {
    try h.assertAbortWritesEveryBackend(std.testing.allocator,
        \\fn main() -> void {
        \\    assert 1 > 2, "never";
        \\}
    , "panic: assertion failed: 1 > 2: never at ");
}

test "js: builtin ---- @print single argument" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    print("Hello, World!");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: builtin ---- @print multiple arguments" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    print("Hello", 42, true);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: builtin ---- @print expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val x = 10;
        \\    print(x * 2);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A user declaration named like one of the type functions the checker once
// intercepted (`pick`, `omit`, `partial`, `mergeRecords`, `mapFields`) is called as
// declared: they are std's `Type.pick` & co. now (decision 307), and a bare
// name is the module's own (`libs/std/src/random.bp` declares `pick`).
test "js: builtin ---- user fns named like type-manipulation builtins call their own bodies" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pick(n: i32) -> i32 { return n + 1; }
        \\fn omit(n: i32) -> i32 { return n + 2; }
        \\fn partial(n: i32) -> i32 { return n + 3; }
        \\fn mergeRecords(a: i32, b: i32) -> i32 { return a + b; }
        \\fn mapFields(n: i32) -> i32 { return n * 2; }
        \\fn main() -> void {
        \\    print(pick(1));
        \\    print(omit(1));
        \\    print(partial(1));
        \\    print(mergeRecords(2, 3));
        \\    print(mapFields(3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: stdlib ---- Result.map transforms Ok, propagates Error intact" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
        \\fn main() -> void {
        \\    val r = parseAge("42").map({ n -> n + 1 });
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: stdlib ---- Result.flatMap chains and flattens" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
        \\fn validate(n: i32) -> Result<i32, string> { panic("not implemented"); }
        \\fn main() -> void {
        \\    val r = parseAge("42").flatMap({ n -> validate(n) });
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: stdlib ---- Result.unwrapOr returns data on Ok, default on Error" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
        \\fn main() -> void {
        \\    val n = parseAge("42").unwrapOr(0);
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: stdlib ---- Result.isOk and isError predicates" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
        \\fn main() -> void {
        \\    val r = parseAge("42");
        \\    val ok = r.isOk();
        \\    val bad = r.isError();
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: stdlib ---- an optional is read by its operators, not by methods (decision 330)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string)
        \\fn find(p: Person) -> ?Person { panic("not implemented"); }
        \\fn greet(p: Person) -> string {
        \\    return find(p)?.name ?? "Hello stranger";
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: stdlib ---- chain map flatMap unwrapOr types correctly" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn parseAge(s: string) -> Result<i32, string> { panic("not implemented"); }
        \\fn validate(n: i32) -> Result<i32, string> { panic("not implemented"); }
        \\fn main() -> void {
        \\    val r = parseAge("42")
        \\        .map({ n -> n + 1 })
        \\        .flatMap({ n -> validate(n) })
        \\        .unwrapOr(0);
        \\}
        \\
        \\import {failure.panic} from "std";
    );
}

test "js: builtin ---- @print in if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn check(x: i32) -> void {
        \\    if (x > 0) {
        \\        print("positive");
        \\    } else {
        \\        print("non-positive");
        \\    }
        \\}
        \\fn main() -> void {
        \\    check(1);
        \\    check(-1);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: builtin ---- @print with variable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val name = "world";
        \\    print("Hello, " + name);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: builtin ---- @print in loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countdown(n: i32) -> void {
        \\    for (0..n) { i ->
        \\        print(n - i);
        \\    };
        \\}
        \\fn main() -> void {
        \\    countdown(3);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: builtin ---- @print return value void" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn log(msg: string) -> void {
        \\    print(msg);
        \\}
        \\fn main() -> void {
        \\    log("started");
        \\    val x = 42;
        \\    log("done");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "codegen: test runner" {
    try h.assertJsTestMode(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\test "addition works" {
        \\    val r = add(2, 3);
        \\    assert r == 5;
        \\}
        \\
        \\test {
        \\    assert true;
        \\}
    );
}

test "codegen: test runner excluded from normal build" {
    const src =
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\
        \\test "addition works" {
        \\    assert add(2, 3) == 5;
        \\}
        \\
        \\fn main() -> void {
        \\    print("hello");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"function add"});
    try h.assertJsNotContains(std.testing.allocator, src, &.{ "__bp_test", "__bp_assert", "__bp_run_tests" });
}

// Semantics decision 4 (1.0.2-beta): `assert` outside test mode is always
// fatal, carrying its message and `file:line`. A holding assertion lets the
// program continue on every backend.
test "js: assert ---- holding assertion lets main continue" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    assert 1 + 1 == 2, "arithmetic";
        \\    print("after");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// A failing assertion aborts the program on all four backends (decision 4),
// carrying the message and the location: erlang and beam raise
// `{bp_assert, <<"boom">>, <<"main.bp:3">>}`, commonJS throws from
// `__bp_assert_fatal`, wasm prints `main.bp:3: assertion failed: boom` and
// traps. `after` is never printed; the commonJS, erlang and beam RUN LOGs are
// empty (a crash records no output), wasm's keeps `before` and the trap.
test "js: assert ---- failing assertion outside test mode is fatal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    print("before");
        \\    assert 1 == 2, "boom";
        \\    print("after");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Semantics decisions 1 and 1a: `@print` writes a top-level string as its
// text and an array as `[1,2]`, space-separated, on one line.
test "js: builtin ---- @print mixes strings and terms as text" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val name = "ana";
        \\    print("hi", name, 42, [1, 2]);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Semantics decision 1a: an array is `[a, b]`, and a string nested in it is
// quoted with the source escapes; a top-level string stays bare. All four
// backends print the same text.
test "js: builtin ---- @print quotes the strings of an array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val words = ["plain", "say \"hi\"", "back\\slash", "two\nlines"];
        \\    print(words);
        \\    print("top", words);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// Semantics decision 1a: a tuple is `#(a,b)` — from a literal, a nested tuple,
// an array of tuples, a fn's declared result and a parameter's declared type.
// All four backends print the same text.
test "js: builtin ---- @print writes tuples as #(a,b)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pairOf(a: i32, b: string) -> #(i32, string) {
        \\    return #(a, b);
        \\}
        \\fn show(p: #(i32, string)) -> void {
        \\    print(p);
        \\}
        \\fn main() -> void {
        \\    print(#(true, 1));
        \\    print(#(#(1, 2), "x"));
        \\    print([#(1, 2), #(17, 1)]);
        \\    print(pairOf(7, "s"));
        \\    show(#(3, "z"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── `@src()` — 1.0.10-beta front 01-std, decisions 73 and 74 ─────────────────
// `@src()` is rewritten at inference into the ordinary constructor call
// `SourceLocation(file: "main.bp", line: L, column: C, fnName: "…")`, so every
// backend lowers it through its record-constructor path; the fixtures below
// are that path's output plus the RUN LOG of the program that reads the four
// fields back. In the harness `file` is `main.bp` (the module is `.path = ""`).

test "js: src ---- in a test" {
    // Test mode (commonJS + erlang, the `botopink test` targets): the test body
    // prints its own location and the RUN LOG shows `main.bp 3 15 src: in a test`
    // — `fnName` is the test name, verbatim.
    try h.assertJsTestMode(std.testing.allocator, @src(),
        \\fn helper() -> i32 { return 1; }
        \\test "src: in a test" {
        \\    val loc = comptime compiler.src();
        \\    print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\test {
        \\    print(comptime compiler.src().fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    );
}

test "js: src ---- in a fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn locate() -> SourceLocation {
        \\    return comptime compiler.src();
        \\}
        \\fn main() -> void {
        \\    val loc = locate();
        \\    print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    );
}

test "js: src ---- in a method" {
    // `fnName` is `Type.method`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Stub(n: i32) {
        \\    fn where(self: Self) -> SourceLocation {
        \\        return comptime compiler.src();
        \\    }
        \\}
        \\fn main() -> void {
        \\    val loc = Stub(n: 1).where();
        \\    print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    );
}

test "js: src ---- at module level" {
    // `fnName` is `""` outside any declaration.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val top = comptime compiler.src();
        \\fn main() -> void {
        \\    print(top.file, top.line, top.column);
        \\    print(top.fnName == "");
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    );
}

test "js: src ---- equals a hand-written constructor" {
    // The two programs differ only in how line 2 spells the record: the
    // builtin, or the constructor call with the literals the builtin computes.
    // Their generated JS is the same text — the rewrite is the constructor.
    const with_builtin =
        \\fn locate() -> SourceLocation {
        \\    return comptime compiler.src();
        \\}
        \\fn main() -> void {
        \\    print(locate().fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    ;
    const hand_written =
        \\fn locate() -> SourceLocation {
        \\    return SourceLocation(file: "main.bp", line: 2, column: 21, fnName: "locate");
        \\}
        \\fn main() -> void {
        \\    print(locate().fnName);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ;
    const a = try h.generateJs(std.testing.allocator, with_builtin);
    defer std.testing.allocator.free(a);
    const b = try h.generateJs(std.testing.allocator, hand_written);
    defer std.testing.allocator.free(b);
    try std.testing.expectEqualStrings(b, a);
    try h.assertJsSingle(std.testing.allocator, @src(), with_builtin);
}

test "js: src ---- run log" {
    // `@print(@src().line)` — the postfix chain on a builtin call, and the
    // literal line of the `@`.
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    print(comptime compiler.src().line);
        \\    print(comptime compiler.src().column, comptime compiler.src().fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "2\n20 main\n");
}

test "erlang: src ---- run log" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() -> void {
        \\    print(comptime compiler.src().line);
        \\    print(comptime compiler.src().column, comptime compiler.src().fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    , "2\n20 main\n", &.{ ", 2, 20, <<\"main\">>}", ", 3, 20, <<\"main\">>}", ", 3, 52, <<\"main\">>}" });
}

test "js: unknown builtin ---- is refused" {
    // The silent `void` fallback is gone (decision 67): a typo is a located
    // `unknown-builtin`, with the nearest name when one is an edit away.
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    @pritn("x");
        \\}
    );
}

test "js: unknown builtin ---- Src is not src" {
    // Builtin names are exact: `@Src()` is refused and pointed at `@src`.
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() -> void {
        \\    val loc = @Src();
        \\}
    );
}

test "js: test body ---- try on an Error fails the test" {
    // Decision 74 — a test body is a fallible context: `try` on an `Error(e)`
    // ends the test as `FAIL <name>  (<e>)  at <file>:<line>` on both
    // `botopink test` targets, an empty `return;` is the `ok` position of a
    // `-> @Result<void, string>`, and a `try` inside a lambda is the lambda's
    // (its expected `fn() -> @Result<…>` is the channel, decision 147).
    // The RUN LOG is the runner's own output: one FAIL, two ok.
    try h.assertJsTestMode(std.testing.allocator, @src(),
        \\fn failing() -> Result<void, string> {
        \\    throw "boom";
        \\}
        \\fn passing() -> Result<void, string> {
        \\    return;
        \\}
        \\test "t: fails" {
        \\    try failing();
        \\    print("not reached");
        \\}
        \\test "t: passes" {
        \\    try passing();
        \\    print("reached");
        \\}
        \\test "t: a lambda's try is its own" {
        \\    val f: fn() -> Result<i32, string> = { -> try failing(); return 0; };
        \\    print("still here");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: src ---- in a test run log" {
    // What `botopink test` prints on both targets for the `src_in_a_test`
    // program: the test body's own `main.bp 3 15 src: in a test` line inside
    // its RUN LOG fence, and `test_1` for the anonymous block. (The snapshot
    // harness never executes an erlang test module, so this is the erlang
    // evidence; the commonJS one agrees with `src_in_a_test.snap.md`.)
    try h.assertTestModeRunLog(std.testing.allocator,
        \\test "src: in a test" {
        \\    val loc = comptime compiler.src();
        \\    print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\test {
        \\    print(comptime compiler.src().fnName);
        \\}
        \\
        \\import {io.terminal.print, compiler} from "std";
    ,
        \\TEST main.bp:1 src: in a test
        \\----- RUN LOG -----
        \\```logs
        \\main.bp 2 24 src: in a test
        \\```
        \\  ok   src: in a test
        \\TEST main.bp:5 test_1
        \\----- RUN LOG -----
        \\```logs
        \\test_1
        \\```
        \\  ok   test_1
        \\2 passed, 0 failed
        \\
    );
}

test "js: test body ---- try on an Error prints the FAIL line" {
    // Decision 74 on both `botopink test` targets: the propagated Error ends
    // `t: fails` as `FAIL t: fails  (boom)  at main.bp:7` — the error string
    // is the message, the `at` is the test's own line — and the statement
    // after the `try` never runs; `t: passes` reaches its print through the
    // empty `return;` of a `-> @Result<void, string>`. The runner exits 1.
    try h.assertTestModeRunLog(std.testing.allocator,
        \\fn failing() -> Result<void, string> {
        \\    throw "boom";
        \\}
        \\fn passing() -> Result<void, string> {
        \\    return;
        \\}
        \\test "t: fails" {
        \\    try failing();
        \\    print("not reached");
        \\}
        \\test "t: passes" {
        \\    try passing();
        \\    print("reached");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    ,
        \\TEST main.bp:7 t: fails
        \\----- RUN LOG -----
        \\```logs
        \\```
        \\  FAIL t: fails  (boom)  at main.bp:7
        \\TEST main.bp:11 t: passes
        \\----- RUN LOG -----
        \\```logs
        \\reached
        \\```
        \\  ok   t: passes
        \\1 passed, 1 failed
        \\
    );
}

// The external scanners (`scanDeclareFnExternal` in `commonJS.zig` and
// `erlang.zig`) read the embedded prelude and stop on a parse failure instead
// of silently skipping it (decision 67) — so the two files must parse. Front 20
// made `primitives.bp`'s compiler section parseable (generic `declare fn`, `_` params, typed
// behavior `val` members); this pins it where a regression reds a test, not a
// user's build.
test "codegen: the embedded prelude parses (primitives.bp, both sections)" {
    const prelude = @import("std_prelude");
    inline for (.{ prelude.builtins, prelude.primitives }) |src| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(arena.allocator());
        var p = Parser.init(tokens);
        _ = try p.parse(arena.allocator());
    }
}
