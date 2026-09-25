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
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "js: assert ---- with arithmetic comparison" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "js: assert ---- with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "error message";
        \\}
    );
}

test "js: assert ---- array equality" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "js: assert pattern ---- with catch throw" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch throw "is not person";
        \\}
    );
}

test "js: assert pattern ---- with catch default value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn f() {
        \\    val r = Person(name: "ann", age: 30);
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "js: assert pattern ---- with list pattern" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val items = [1, 2, 3];
        \\    val assert [first, ..] = items catch throw "not a list";
        \\}
    );
}

test "js: assert pattern ---- with string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val greeting = "hello";
        \\    val assert "hello" = greeting catch throw "not hello";
        \\}
    );
}

test "js: assert pattern ---- with number literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val answer = 42;
        \\    val assert 42 = answer catch throw "not 42";
        \\}
    );
}

test "js: assert pattern ---- with enum variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse() -> @Result<i32, string> {
        \\    return 42;
        \\}
        \\fn main() {
        \\    val result = parse();
        \\    val assert Ok(value) = result;
        \\    @print(value);
        \\}
    );
}

test "js: assert pattern ---- with empty list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val list: i32[] = [];
        \\    val assert [] = list catch throw "not empty";
        \\}
    );
}

test "js: assert pattern ---- with multiple element list" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val numbers = [1, 2, 3];
        \\    val assert [1, 2, 3] = numbers catch throw "not matching";
        \\}
    );
}

test "js: assert pattern ---- with list and rest" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val items = [1, 2, 3, 4];
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

test "js: builtin ---- @todo with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn notImplemented() {
        \\    @todo("implement this function");
        \\}
    );
}

test "js: builtin ---- @panic with message" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fail() {
        \\    @panic("something went wrong");
        \\}
    );
}

test "js: builtin ---- @print single argument" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("Hello, World!");
        \\}
    );
}

test "js: builtin ---- @print multiple arguments" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("Hello", 42, true);
        \\}
    );
}

test "js: builtin ---- @print expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val x = 10;
        \\    @print(x * 2);
        \\}
    );
}

// A user declaration named like a comptime type-manipulation builtin
// (`pick`, `omit`, `partial`, `mergeRecords`, `mapFields`) is called as
// declared: the inference intercept only claims a bare name the scope does not
// bind (std-surface 6a — `libs/std/src/random.bp` declares `pick`).
test "js: builtin ---- user fns named like type-manipulation builtins call their own bodies" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pick(n: i32) -> i32 { return n + 1; }
        \\fn omit(n: i32) -> i32 { return n + 2; }
        \\fn partial(n: i32) -> i32 { return n + 3; }
        \\fn mergeRecords(a: i32, b: i32) -> i32 { return a + b; }
        \\fn mapFields(n: i32) -> i32 { return n * 2; }
        \\fn main() {
        \\    @print(pick(1));
        \\    @print(omit(1));
        \\    @print(partial(1));
        \\    @print(mergeRecords(2, 3));
        \\    @print(mapFields(3));
        \\}
    );
}

test "js: stdlib ---- Result.map transforms Ok, propagates Error intact" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42").map({ n -> n + 1 });
        \\}
    );
}

test "js: stdlib ---- Result.flatMap chains and flattens" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\#[@result]
        \\fn validate(n: i32) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42").flatMap({ n -> validate(n) });
        \\}
    );
}

test "js: stdlib ---- Result.unwrapOr returns data on Ok, default on Error" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val n = parseAge("42").unwrapOr(0);
        \\}
    );
}

test "js: stdlib ---- Result.isOk and isError predicates" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42");
        \\    val ok = r.isOk();
        \\    val bad = r.isError();
        \\}
    );
}

test "js: stdlib ---- Option map, flatMap and unwrapOr mirror Result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string)
        \\fn firstName(p: Person) -> ?string { @todo(); }
        \\fn shout(s: string) -> ?string { @todo(); }
        \\fn greet(p: Person) -> string {
        \\    return firstName(p)
        \\        .map({ n -> "Hello " + n })
        \\        .flatMap({ n -> shout(n) })
        \\        .unwrapOr("Hello stranger");
        \\}
    );
}

test "js: stdlib ---- chain map flatMap unwrapOr types correctly" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
        \\#[@result]
        \\fn validate(n: i32) -> @Result<i32, string> { @todo(); }
        \\fn main() {
        \\    val r = parseAge("42")
        \\        .map({ n -> n + 1 })
        \\        .flatMap({ n -> validate(n) })
        \\        .unwrapOr(0);
        \\}
    );
}

test "js: builtin ---- @print in if branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn check(x: i32) {
        \\    if (x > 0) {
        \\        @print("positive");
        \\    } else {
        \\        @print("non-positive");
        \\    }
        \\}
        \\fn main() {
        \\    check(1);
        \\    check(-1);
        \\}
    );
}

test "js: builtin ---- @print with variable" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val name = "world";
        \\    @print("Hello, " + name);
        \\}
    );
}

test "js: builtin ---- @print in loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countdown(n: i32) {
        \\    for (0..n) { i ->
        \\        @print(n - i);
        \\    };
        \\}
        \\fn main() {
        \\    countdown(3);
        \\}
    );
}

test "js: builtin ---- @print return value void" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn log(msg: string) {
        \\    @print(msg);
        \\}
        \\fn main() {
        \\    log("started");
        \\    val x = 42;
        \\    log("done");
        \\}
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
        \\fn main() {
        \\    @print("hello");
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{"function add"});
    try h.assertJsNotContains(std.testing.allocator, src, &.{ "__bp_test", "__bp_assert", "__bp_run_tests" });
}

// Semantics decision 4 (1.0.2-beta): `assert` outside test mode is always
// fatal, carrying its message and `file:line`. A holding assertion lets the
// program continue on every backend.
test "js: assert ---- holding assertion lets main continue" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    assert 1 + 1 == 2, "arithmetic";
        \\    @print("after");
        \\}
    );
}

// A failing assertion aborts the program. beam raises
// `{bp_assert, <<"boom">>, <<"main.bp:3">>}`, so the process exits non-zero and
// the RUN LOG is empty (a crash records no output). KNOWN DIVERGENCE: commonJS
// still lowers to `console.assert` and prints `before`/`after` (F8), erlang to
// `true = (…)` without message or location (F5).
test "js: assert ---- failing assertion outside test mode is fatal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print("before");
        \\    assert 1 == 2, "boom";
        \\    @print("after");
        \\}
    );
}

// Semantics decisions 1 and 1a: `@print` writes a top-level string as its
// text and an array as `[1,2]`, space-separated, on one line.
test "js: builtin ---- @print mixes strings and terms as text" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val name = "ana";
        \\    @print("hi", name, 42, [1, 2]);
        \\}
    );
}

// Semantics decision 1a: an array is `[a,b]` with no spaces, and a string
// nested in it is quoted with the source escapes; a top-level string stays
// bare. KNOWN: beam prints its own `~p` text (PR3, deferred after 06).
test "js: builtin ---- @print quotes the strings of an array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val words = ["plain", "say \"hi\"", "back\\slash", "two\nlines"];
        \\    @print(words);
        \\    @print("top", words);
        \\}
    );
}

// Semantics decision 1a: a tuple is `#(a,b)` — from a literal, a nested tuple,
// an array of tuples, a fn's declared result and a parameter's declared type.
// KNOWN: beam prints its own `~p` text (PR3, deferred after 06).
test "js: builtin ---- @print writes tuples as #(a,b)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pairOf(a: i32, b: string) -> #(i32, string) {
        \\    return #(a, b);
        \\}
        \\fn show(p: #(i32, string)) {
        \\    @print(p);
        \\}
        \\fn main() {
        \\    @print(#(true, 1));
        \\    @print(#(#(1, 2), "x"));
        \\    @print([#(1, 2), #(17, 1)]);
        \\    @print(pairOf(7, "s"));
        \\    show(#(3, "z"));
        \\}
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
        \\    val loc = @src();
        \\    @print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\test {
        \\    @print(@src().fnName);
        \\}
    );
}

test "js: src ---- in a fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn locate() -> SourceLocation {
        \\    return @src();
        \\}
        \\fn main() {
        \\    val loc = locate();
        \\    @print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
    );
}

test "js: src ---- in a method" {
    // `fnName` is `Type.method`. KNOWN-WRONG (wasm): a record answered by a
    // *method* call loses its field types on the wat backend — `loc.file` and
    // `loc.fnName` print as the raw i32 pointers (`256 … 272`); a hand-written
    // `SourceLocation(…)` returned from the same method prints the same, so it
    // is the wat backend's method-return typing, not `@src()`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Stub(n: i32) {
        \\    fn where(self: Self) -> SourceLocation {
        \\        return @src();
        \\    }
        \\}
        \\fn main() {
        \\    val loc = Stub(n: 1).where();
        \\    @print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
    );
}

test "js: src ---- at module level" {
    // `fnName` is `""` outside any declaration.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val top = @src();
        \\fn main() {
        \\    @print(top.file, top.line, top.column);
        \\    @print(top.fnName == "");
        \\}
    );
}

test "js: src ---- equals a hand-written constructor" {
    // The two programs differ only in how line 2 spells the record: the
    // builtin, or the constructor call with the literals the builtin computes.
    // Their generated JS is the same text — the rewrite is the constructor.
    const with_builtin =
        \\fn locate() -> SourceLocation {
        \\    return @src();
        \\}
        \\fn main() {
        \\    @print(locate().fnName);
        \\}
    ;
    const hand_written =
        \\fn locate() -> SourceLocation {
        \\    return SourceLocation(file: "main.bp", line: 2, column: 12, fnName: "locate");
        \\}
        \\fn main() {
        \\    @print(locate().fnName);
        \\}
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
        \\fn main() {
        \\    @print(@src().line);
        \\    @print(@src().column, @src().fnName);
        \\}
    , "2\n12 main\n");
}

test "erlang: src ---- run log" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\    @print(@src().line);
        \\    @print(@src().column, @src().fnName);
        \\}
    , "2\n12 main\n", &.{ ", 2, 12, <<\"main\">>}", ", 3, 12, <<\"main\">>}", ", 3, 27, <<\"main\">>}" });
}

test "js: src ---- with an argument is refused" {
    // `src-takes-no-arguments`, located at the call — recorded as the
    // `COMPILE DIAGNOSTIC` of every backend (the H3 contract for a program
    // whose point is that it does not compile).
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() {
        \\    val loc = @src(1);
        \\}
    );
}

test "js: src ---- with a trailing lambda is refused" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() {
        \\    val loc = @src { 1; };
        \\}
    );
}

test "js: unknown builtin ---- is refused" {
    // The silent `void` fallback is gone (decision 67): a typo is a located
    // `unknown-builtin`, with the nearest name when one is an edit away.
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() {
        \\    @pritn("x");
        \\}
    );
}

test "js: unknown builtin ---- Src is not src" {
    // Builtin names are exact: `@Src()` is refused and pointed at `@src`.
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() {
        \\    val loc = @Src();
        \\}
    );
}

test "js: test body ---- try on an Error fails the test" {
    // Decision 74 — a test body is a fallible context: `try` on an `Error(e)`
    // ends the test as `FAIL <name>  (<e>)  at main.bp:<line>` on both
    // `botopink test` targets, an empty `return;` is the `ok` position of a
    // `-> @Result<void, string>`, and a `try` inside a lambda is the lambda's.
    // The RUN LOG is the runner's own output: one FAIL, two ok.
    try h.assertJsTestMode(std.testing.allocator, @src(),
        \\#[@result]
        \\fn failing() -> @Result<void, string> {
        \\    throw "boom";
        \\}
        \\#[@result]
        \\fn passing() -> @Result<void, string> {
        \\    return;
        \\}
        \\test "t: fails" {
        \\    try failing();
        \\    @print("not reached");
        \\}
        \\test "t: passes" {
        \\    try passing();
        \\    @print("reached");
        \\}
        \\test "t: a lambda's try is its own" {
        \\    val f = { -> try failing(); 0; };
        \\    @print("still here");
        \\}
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
        \\    val loc = @src();
        \\    @print(loc.file, loc.line, loc.column, loc.fnName);
        \\}
        \\test {
        \\    @print(@src().fnName);
        \\}
    ,
        \\TEST main.bp:1 src: in a test
        \\----- RUN LOG -----
        \\```logs
        \\main.bp 2 15 src: in a test
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
    // `t: fails` as `FAIL t: fails  (boom)  at main.bp:9` — the error string
    // is the message, the `at` is the test's own line — and the statement
    // after the `try` never runs; `t: passes` reaches its print through the
    // empty `return;` of a `-> @Result<void, string>`. The runner exits 1.
    try h.assertTestModeRunLog(std.testing.allocator,
        \\#[@result]
        \\fn failing() -> @Result<void, string> {
        \\    throw "boom";
        \\}
        \\#[@result]
        \\fn passing() -> @Result<void, string> {
        \\    return;
        \\}
        \\test "t: fails" {
        \\    try failing();
        \\    @print("not reached");
        \\}
        \\test "t: passes" {
        \\    try passing();
        \\    @print("reached");
        \\}
    ,
        \\TEST main.bp:9 t: fails
        \\----- RUN LOG -----
        \\```logs
        \\```
        \\  FAIL t: fails  (boom)  at main.bp:9
        \\TEST main.bp:13 t: passes
        \\----- RUN LOG -----
        \\```logs
        \\reached
        \\```
        \\  ok   t: passes
        \\1 passed, 1 failed
        \\
    );
}
