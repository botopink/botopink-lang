//! format: binary/call/access/lambda/precedence/pipeline/negation (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const formatMod = @import("../../format.zig");
const h = @import("helpers.zig");

test "format: lambda ---- trailing no params" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Test {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        };
        \\    }
        \\}
    );
}

test "format: lambda ---- named arg + trailing with params" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Test {
        \\    default fn run() {
        \\        calcular(fator: 2) { a, b ->
        \\            a + b;
        \\        };
        \\    }
        \\}
    );
}

test "format: lambda ---- two trailing blocks second labeled" {
    try h.assertFormat(std.testing.allocator,
        \\behavior Test {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        } erro: {
        \\            fail;
        \\        };
        \\    }
        \\}
    );
}

test "format: lambda ---- simple no params" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- with param" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- multi-statement body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        1;
        \\        2;
        \\    };
        \\}
    );
}

test "format: lambda ---- case expression in body" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\    };
        \\}
    );
}

test "format: call ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run();
        \\}
    );
}

test "format: call ---- single argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(1);
        \\}
    );
}

test "format: call ---- labeled argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(with: 1);
        \\}
    );
}

test "format: call ---- constructor with labeled args" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Person(name: "Al", is_cool: VeryTrue);
        \\}
    );
}

test "format: binary ---- logical and" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True && False;
        \\}
    );
}

test "format: binary ---- logical or" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True || False;
        \\}
    );
}

test "format: binary ---- comparison less than" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 < 1;
        \\}
    );
}

test "format: binary ---- comparison less than or equal" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 <= 1;
        \\}
    );
}

test "format: binary ---- equality" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 == 1;
        \\}
    );
}

test "format: binary ---- inequality" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 != 1;
        \\}
    );
}

test "format: binary ---- addition" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 + 1;
        \\}
    );
}

test "format: binary ---- subtraction" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 - 1;
        \\}
    );
}

test "format: binary ---- multiplication" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 * 1;
        \\}
    );
}

test "format: binary ---- division" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 / 1;
        \\}
    );
}

test "format: binary ---- modulo" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 % 1;
        \\}
    );
}

test "format: seq ---- multiple expressions" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1;
        \\    2;
        \\    3;
        \\}
    );
}

test "format: seq ---- call then literal" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    first(1);
        \\    1;
        \\}
    );
}

test "format: access ---- simple field access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two;
        \\}
    );
}

test "format: access ---- chained field access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two.three.four;
        \\}
    );
}

test "format: access ---- tuple access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.0;
        \\}
    );
}

test "format: access ---- chained tuple access" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.1.2;
        \\}
    );
}

test "format: panic ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic();
        \\}
    );
}

test "format: panic ---- with message" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("panicking");
        \\}
    );
}

test "format: precedence ---- parentheses around addition" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    (1 + 2) * 3;
        \\}
    );
}

test "format: precedence ---- multiplication on right" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    3 * (1 + 2);
        \\}
    );
}

test "format: precedence ---- logical or in parentheses" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True != (a == b);
        \\}
    );
}

test "format: negation ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !x;
        \\}
    );
}

test "format: negation ---- block" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !@block{
        \\        123;
        \\        x;
        \\    };
        \\}
    );
}

test "format: pipeline ---- simple" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name;
        \\}
    );
}

test "format: pipeline ---- in list" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        1
        \\        |> succ
        \\        |> succ,
        \\        2,
        \\        3,
        \\    ];
        \\}
    );
}

test "format: pipeline ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    // 1
        \\    |> func1
        \\    // 2
        \\    |> func2;
        \\}
    );
}

test "format: labeled args ---- with comments" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Emulator(
        \\        // one
        \\        one: 1,
        \\        // two
        \\        two: 1,
        \\    );
        \\}
    );
}

test "format: panic ---- with message and comment" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("wibble");
        \\}
    );
}

test "format: multiline string ---- as function argument" {
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    wibble(
        \\        wobble,
        \\        """
        \\        This is a multiline string.
        \\        It can span several lines.
        \\        """,
        \\        wibble,
        \\        wibble,
        \\    );
        \\}
    );
}

test "format: await ---- prefix expression" {
    try h.assertFormat(std.testing.allocator,
        \\fn run() -> @Task<Int> {
        \\    val x = await load(url);
        \\    return x;
        \\}
    );
}

test "format: tagged call ---- round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\val q = sql "SELECT 1";
    );
}

test "format: tagged call ---- interpolated multiline round-trip" {
    try h.assertFormat(std.testing.allocator,
        \\val component = html """
        \\<Button label=${title}></Button>
        \\""";
    );
}

// front 12 step 3 (format --check on libs/std): three shapes the formatter
// printed as source that no longer parsed.

test "format: a parameterless lambda argument keeps its arrow" {
    // Re-recorded for decision 61 rule 1: the body indents +4 from the call line
    // and the `}` lines up with the call, where it used to be +8 and +4. What this
    // case is about — the arrow a parameterless lambda argument keeps, without
    // which the braces re-parse as a block — is unchanged. Two statements, so the
    // one-line rule does not take it.
    try h.assertFormat(std.testing.allocator,
        \\fn main() {
        \\    throws({ ->
        \\        0;
        \\        1;
        \\    }, "expected");
        \\}
    );
}

test "format: a multi-statement if branch prints its statements, not break" {
    try h.assertFormat(std.testing.allocator,
        \\fn pick(xs: Array<i32>) -> i32 {
        \\    return if (xs.isEmpty()) 0 else {
        \\        val head = xs.length;
        \\        head + 1;
        \\    };
        \\}
    );
}

test "format: branches re-parse and format to the same text" {
    try h.assertIdempotent(std.testing.allocator,
        \\fn pick(xs: Array<i32>) -> i32 {
        \\    return if (xs.isEmpty()) { 0; } else { val head = xs.length; head + 1; };
        \\}
    );
}

// A `loop` body printed each statement without its `;` (and with a
// whitespace-only line between them), so a loop holding two statements
// no longer parsed — a library's template lexer after `botopink format`.

test "format: a loop body keeps each statement's semicolon" {
    try h.assertFormat(std.testing.allocator,
        \\fn f(xs: Array<string>) -> string {
        \\    var a = "";
        \\    for (xs) { x ->
        \\        if (x == "a") a = a + x;
        \\        val y = x;
        \\        a = a + y;
        \\    };
        \\    return a;
        \\}
    );
}

test "format: braced ifs inside a loop body format to statements that re-parse" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn f(xs: Array<string>) -> string {
        \\    var a = "";
        \\    var b = "";
        \\    for (xs) { x -> if (x == "a") { a = a + x; }; if (x == "b") { b = b + x; }; };
        \\    return a + b;
        \\}
    ,
        \\fn f(xs: Array<string>) -> string {
        \\    var a = "";
        \\    var b = "";
        \\    for (xs) { x ->
        \\        if (x == "a") a = a + x;
        \\        if (x == "b") b = b + x;
        \\    };
        \\    return a + b;
        \\}
    );
    try h.assertIdempotent(std.testing.allocator,
        \\fn f(xs: Array<string>) -> string {
        \\    var a = "";
        \\    for (xs) { x -> if (x == "a") { a = a + x; }; if (x == "b") { a = a + x; }; };
        \\    return a;
        \\}
    );
}

// ── decision 105: the three loop keywords print back as written ──────────────

test "format: for, for await, while, loop and the annotated loop round-trip" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: i32[], gen: @Stream<i32>) {
        \\    for :outer (xs) { x ->
        \\        if (x == 2) break :outer;
        \\    };
        \\    for (0..xs.length) { i ->
        \\        @print(i);
        \\    };
        \\    for (1...3) { i ->
        \\        @print(i);
        \\    };
        \\    for await (gen) { v ->
        \\        @print(v);
        \\    };
        \\    var n = 0;
        \\    while :w (n < 3 && true) {
        \\        n = n + 1;
        \\        continue;
        \\    };
        \\    loop :l {
        \\        n = n - 1;
        \\        if (n == 0) break :l;
        \\    };
        \\    val g = iter loop :gen {
        \\        n = n + 1;
        \\        if (n == 10) break n * 2;
        \\        yield n * 2;
        \\    };
        \\    val r = iter loop {
        \\        yield 1;
        \\    };
        \\    val fg = stream loop {
        \\        yield 1;
        \\    };
        \\}
    );
}

test "format: the front-24 forms round-trip — async block, the prefixed while / for, try await, yield :label" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: i32[]) -> @Task<@Result<i32, string>> {
        \\    val t = async {
        \\        return try await load(1);
        \\    };
        \\    val e = async {};
        \\    var i = 0;
        \\    val w = iter while (i < 3) {
        \\        i = i + 1;
        \\        yield i;
        \\    };
        \\    val c = iter for (xs) { x ->
        \\        yield x * 2;
        \\    };
        \\    val sw = stream while (i > 0) {
        \\        i = i - 1;
        \\        yield await load(i);
        \\    };
        \\    val sf = stream for (xs) { x ->
        \\        yield x;
        \\    };
        \\    val n = try await load(2);
        \\    val m = await t;
        \\    return n;
        \\}
        \\
        \\fn g(xs: i32[]) -> @Iterator<i32> :out {
        \\    for (xs) { x ->
        \\        yield :out x;
        \\    };
        \\}
    );
}

test "format: an empty loop body prints on one line and a body breaks" {
    try h.assertFormat(std.testing.allocator,
        \\fn f(xs: i32[]) {
        \\    for (xs) { x -> };
        \\    while (true) { };
        \\    loop {
        \\        break;
        \\    };
        \\}
    );
}

// ── calling what a call returned (decision 14) ────────────────────────────────
// `adder(3)(4)` has no name to put in `callee`, so the callee travels as an
// expression (`ast.CallExpr.call.calleeExpr`) and `callee` is `""`. The printer
// read only `receiver` and `callee`, so it printed the empty name and dropped the
// receiver entirely: `adder(3)(4)` came back as `(4)`. Handed over by
// `15-language-surface`, whose step 4 made the form parse.

test "format: call ---- a call of what a call returned keeps its callee" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f() -> i32 {
        \\    return adder(3)(4);
        \\}
    );
}

test "format: call ---- a chained call composes with the links after it" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: i32[]) -> i32 {
        \\    return pick(xs)(0).value;
        \\}
    );
}

test "format: call ---- three calls in a row keep all three" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f() -> i32 {
        \\    return curry(1)(2)(3);
        \\}
    );
}

test "format: call ---- a method call's result is called with no receiver invented" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: Box) -> i32 {
        \\    return o.pick(1)(2);
        \\}
    );
}

// ── the desugarings print back in the spelling that was written ───────────────
// `ast.zig` says why `xs[0]`, `x is T` and `a ?? b` all desugar in the parser
// rather than becoming nodes of their own: no AST union there may gain a variant,
// or every consumer would have to grow an arm before the form could parse at all.
// The printer is then the one place that has to undo it — and it did not, so
// `format` rewrote the file into a program nobody wrote:
//
//   xs[0]    → @[](xs, 0)                          the desugaring leaks
//   o is i32 → @is(o)                              the tested TYPE is deleted
//   a ?? 0   → if (a) { __bp_nullish -> … } else 0  the `??` token is deleted
//
// Two of the three lose text, and idempotently, so `format --check` reported the
// rewritten file as clean. The first two were handed over by
// `15-language-surface`; `x is T` is the same class and was already there.

test "format: index ---- an index expression is not `@[]`" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: i32[]) -> i32 {
        \\    return xs[0];
        \\}
    );
}

test "format: index ---- a slice is the same node and keeps its range" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(xs: i32[]) -> i32[] {
        \\    return xs[0..2];
        \\}
    );
}

test "format: index ---- a dict read is the same node and keeps its key" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(d: Dict<string, i32>) -> i32 {
        \\    return d["k"];
        \\}
    );
}

test "format: index ---- a tuple member is the same node" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(t: #(i32, string)) -> i32 {
        \\    return t[0];
        \\}
    );
}

test "format: index ---- an index composes with the links around it" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(d: Dict<string, i32[]>) -> i32 {
        \\    return d["k"][0];
        \\}
    );
}

test "format: is ---- `x is T` keeps the tested type" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32) -> bool {
        \\    return o is i32;
        \\}
    );
}

test "format: is ---- the tested type may be a union" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32) -> bool {
        \\    return o is string | i32;
        \\}
    );
}

test "format: nullish ---- `a ?? b` is not its desugared `if`" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32) -> i32 {
        \\    return o ?? 3;
        \\}
    );
}

test "format: nullish ---- a `??` chain stays right-associative and flat" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32, p: ?i32) -> i32 {
        \\    return o ?? p ?? 7;
        \\}
    );
}

test "format: nullish ---- a `??` inside a larger expression keeps its parentheses" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32) -> i32 {
        \\    return (o ?? 3) + 1;
        \\}
    );
}

test "format: nullish ---- an optional-binding `if` is still printed as an `if`" {
    // The negative of the arm above: the desugaring is recognised by all four of
    // its parts, so an `if` that binds a name of its own is untouched.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(o: ?i32) {
        \\    if (o) {
        \\        n ->
        \\        @print(n);
        \\    };
        \\}
    );
}

// decision 61 rule 3 — the one-line rule covers a parameterless lambda. Before
// this, `{ n -> n * 2 }` stayed inline and `{ -> 3 + 4 }` exploded into three
// lines: one form printed two ways, decided by whether it had a name to bind.

test "format: lambda ---- a parameterless lambda on one line stays on one line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    val g = { -> 3 + 4 };
        \\    @print(g());
        \\}
    );
}

test "format: lambda ---- the one-line form prints for a parameterless lambda argument" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    val n = measureMillis({ -> 42 });
        \\}
    );
}

test "format: lambda ---- a trailing lambda keeps the open form, one statement or not" {
    // The one-line rule stops at the `arrow_when_empty` boundary, and the reason
    // was measured rather than assumed: a trailing lambda's body is a statement
    // block, so `executar { ok }` is a **parse error** (*unexpected `}`*) and so
    // is `calcular(fator: 2) { a, b -> a + b }`. Printing the one-line form here
    // would emit text this compiler refuses, which `assertIdempotent` — it
    // re-parses pass 1 — would then fail on.
    try h.assertFormatLossless(std.testing.allocator,
        \\behavior Test {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        };
        \\    }
        \\}
    );
}

test "format: lambda ---- a parameterless lambda whose body needs a line keeps the open form" {
    // The negative: the one-line rule tests the source's own line, so a body
    // that was written below the arrow stays below it, with or without params.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    val g = { ->
        \\        val a = 1;
        \\        a + 2;
        \\    };
        \\}
    );
}

// decision 61 rule 2 — an empty lambda body stays inline. The open form had
// nothing to put between its two hardlines, so it printed the body's indentation
// and then a newline: a line of eight spaces and nothing else.

test "format: lambda ---- an empty body stays inline" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    val g = { next -> };
        \\    val h = { -> };
        \\}
    );
}

test "format: lambda ---- an empty body as a record field and a tuple element" {
    // The shape both real occurrences have: a sink a client runtime rebinds,
    // written empty on the server. The open form spent three lines on it.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn state(initial: i32) -> State<i32> {
        \\    return State(value: initial, set: { next -> });
        \\}
    );
}

test "format: lambda ---- an empty trailing lambda and an empty case arm print {}" {
    // `arrow_when_empty` is false for both, and neither can re-parse as a block:
    // a trailing lambda's braces follow a callee, and a `case` arm's follow a
    // pattern. `fmtBody` already answers `{}` for an empty `fn` body.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn pick(n: i32) {
        \\    case n {
        \\        1 {
        \\            @print("one");
        \\        }
        \\        _ {}
        \\    };
        \\}
    );
}

// decision 61 rule 1 — a lambda **argument** hugs the call: its body indents +4
// from the call line and its closing `});` lines up with the call. Before this
// the argument list's `nest(INDENT)` sat outside the lambda's own, so one line
// break paid twice: +8 for the body, +4 for the brace.

test "format: call ---- a lambda argument's body indents +4 and its brace lines up" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    xs.forEach({ x ->
        \\        @print(x);
        \\        @print(x + 1);
        \\    });
        \\}
    );
}

test "format: call ---- the lambda need not be the last argument" {
    // The rule is about the lambda's body, not its position: a first-argument
    // lambda hugs exactly as a last-argument one does.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    throws({ ->
        \\        0;
        \\        1;
        \\    }, "expected");
        \\}
    );
}

test "format: call ---- a lambda after a plain argument hugs, the argument stays flat" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn run(app: App) {
        \\    val _port = serve(app.port, { method, path ->
        \\        dispatch(method, path);
        \\        done(method);
        \\    });
        \\}
    );
}

test "format: call ---- nesting compounds by +4 a level, not +8" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn walk(decl: Decl) {
        \\    decl.methods.forEach({ m ->
        \\        m.annotations.forEach({ a ->
        \\            @print(a);
        \\            @print(m);
        \\        });
        \\    });
        \\}
    );
}

test "format: call ---- a lambda argument that fits on one line is not hugged" {
    // The negative: the hug is decided by whether the lambda's own printing
    // breaks, so a one-line lambda leaves the argument list grouped as before.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    val ys = xs.map({ n -> n * 2 });
        \\}
    );
}

test "format: call ---- a comment on an argument still opens the list" {
    // The other negative: the comment and multiline-string arms print the list
    // open, one argument per line, and the hug does not reach them — a comment
    // has nowhere to go inside a flat `(a, b)`.
    try h.assertFormatLossless(std.testing.allocator,
        \\fn main() {
        \\    run(
        \\        // why
        \\        1,
        \\        { x ->
        \\            @print(x);
        \\            @print(x);
        \\        },
        \\    );
        \\}
    );
}

// ── method chains (decision 65) ───────────────────────────────────────────────

test "format: method chain ---- fits, so it stays on one line" {
    try h.assertFormat(std.testing.allocator,
        \\fn names() -> string[] {
        \\    return of(people).where({ p -> p.age >= 18 }).select({ p -> p.name });
        \\}
    );
}

test "format: method chain ---- does not fit, so every call takes its own line at +4" {
    try h.assertFormat(std.testing.allocator,
        \\fn names() -> string {
        \\    return of(people)
        \\        .where({ p -> p.age >= 18 })
        \\        .orderBy({ p -> p.name })
        \\        .select({ p -> p.name })
        \\        .toArray()
        \\        .join(", ");
        \\}
    );
}

test "format: method chain ---- a one-line chain past the width is opened" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn names() -> string {
        \\    return of(people).where({ p -> p.age >= 18 }).orderBy({ p -> p.name }).select({ p -> p.name }).toArray().join(", ");
        \\}
    ,
        \\fn names() -> string {
        \\    return of(people)
        \\        .where({ p -> p.age >= 18 })
        \\        .orderBy({ p -> p.name })
        \\        .select({ p -> p.name })
        \\        .toArray()
        \\        .join(", ");
        \\}
    );
}

test "format: method chain ---- no middle: two calls on a line become one per line" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn names() -> string {
        \\    return of(people).where({ p -> p.age >= 18 }).orderBy({ p -> p.name })
        \\        .select({ p -> p.name }).toArray().join(", ");
        \\}
    ,
        \\fn names() -> string {
        \\    return of(people)
        \\        .where({ p -> p.age >= 18 })
        \\        .orderBy({ p -> p.name })
        \\        .select({ p -> p.name })
        \\        .toArray()
        \\        .join(", ");
        \\}
    );
}

test "format: method chain ---- a hand-broken chain that fits is joined (pure function of content)" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn names() -> string[] {
        \\    return of(people)
        \\        .where({ p -> p.age >= 18 })
        \\        .select({ p -> p.name });
        \\}
    ,
        \\fn names() -> string[] {
        \\    return of(people).where({ p -> p.age >= 18 }).select({ p -> p.name });
        \\}
    );
}

test "format: method chain ---- the boundary is exact: 80 columns stay, 81 break" {
    // The first `val` line is exactly 80 columns, the second 81.
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val n = a.bbbbbbbbbb().cccccccccc().dddddddddd().eeeeeeeeee().fffffffffff();
        \\}
    );
    try h.assertFormatAs(std.testing.allocator,
        \\fn f() {
        \\    val n = a.bbbbbbbbbb().cccccccccc().dddddddddd().eeeeeeeeee().ffffffffffff();
        \\}
    ,
        \\fn f() {
        \\    val n = a
        \\        .bbbbbbbbbb()
        \\        .cccccccccc()
        \\        .dddddddddd()
        \\        .eeeeeeeeee()
        \\        .ffffffffffff();
        \\}
    );
}

test "format: method chain ---- a single method call is not a chain" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val n = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb();
        \\}
    );
}

test "format: method chain ---- a link whose lambda breaks opens the whole chain" {
    try h.assertFormat(std.testing.allocator,
        \\fn f() {
        \\    xs
        \\        .map({ x -> x * 2 })
        \\        .forEach({ x ->
        \\            @print(x);
        \\        });
        \\}
    );
}

test "format: method chain ---- round trip is idempotent and lossless" {
    try h.assertIdempotent(std.testing.allocator,
        \\fn names() -> string {
        \\    return of(people)
        \\        .where({ p -> p.age >= 18 })
        \\        .orderBy({ p -> p.name })
        \\        .select({ p -> p.name })
        \\        .toArray()
        \\        .join(", ");
        \\}
    );
    try h.assertIdempotent(std.testing.allocator,
        \\fn f() {
        \\    xs
        \\        .map({ x -> x * 2 })
        \\        .forEach({ x ->
        \\            @print(x);
        \\        });
        \\}
    );
}

// ── C-12: the constructs under `fits`, enclosing ones first (decision 65) ──────
//
// The argument list could not be enabled alone: about half the lists it opened
// closed on a line that went on with an operator (`) != -1;`), opened for what
// FOLLOWED them because the binary expression and the brace-less `if` around
// them were pinned — the middle decision 65 calls wrong. So the enclosing
// constructs measure too: a binary run, a brace-less `if`, the argument list,
// the array / tuple / behavior literal. Each is all-or-nothing; the outer one
// decides first, and an inner one is measured where the outer one put it.

test "format: C-12 ---- a call that fits stays on one line, 80 columns exactly" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f() {
        \\    val entry = ThemeEntry(name: "--text-3xl--line-height", value: "calc(2)");
        \\}
    );
}

test "format: C-12 ---- an argument list past the width takes one argument per line" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f() {
        \\    val entry = ThemeEntry(
        \\        name: "--text-3xl--line-height",
        \\        value: "calc(2.25 / 1.875)",
        \\    );
        \\}
    );
}

test "format: C-12 ---- an open argument list that fits is joined (a pure function of the content)" {
    try h.assertFormatAs(std.testing.allocator,
        \\fn f() {
        \\    g(
        \\        1,
        \\        2,
        \\    );
        \\}
    ,
        \\fn f() {
        \\    g(1, 2);
        \\}
    );
}

test "format: C-12 ---- a binary run breaks before every operator, +4" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(title: string, known: string[]) -> string {
        \\    return reportTitle()
        \\        + "\n\n"
        \\        + notAppliedLine()
        \\        + "\n"
        \\        + known.length
        \\        + " registered, none evaluated";
        \\}
    );
}

test "format: C-12 ---- the binary breaks before the argument list inside it" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(doc: string, a: string) {
        \\    assert doc.indexOf(
        \\        "." + a + "{background-attachment:fixed;background-attachment:local}",
        \\    )
        \\        != -1;
        \\}
    );
}

test "format: C-12 ---- a brace-less if puts its branch on the next line, not its condition" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f(absDiff: f64, tolerance: f64) -> @Result<void, string> {
        \\    if (absDiff > tolerance)
        \\        throw "asserts.approxEquals: values differ by more than tolerance";
        \\    return;
        \\}
    );
}

test "format: C-12 ---- an else-if chain breaks at every else or at none" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn kindLabel(kind: string) -> string {
        \\    if (kind == "L")
        \\        return "layout"
        \\    else if (kind == "T")
        \\        return "template"
        \\    else if (kind == "P")
        \\        return "page"
        \\    else
        \\        return "";
        \\}
        \\
        \\fn short(k: string) -> string {
        \\    if (k == "L") return "layout" else return "";
        \\}
    );
}

test "format: C-12 ---- a braced else stays outside the measured if" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn pick(xs: Array<i32>) -> i32 {
        \\    return if (xs.isEmpty()) 0 else {
        \\        val head = xs.length;
        \\        head + 1;
        \\    };
        \\}
    );
}

test "format: C-12 ---- a tuple and a behavior literal break like an argument list" {
    try h.assertFormatLossless(std.testing.allocator,
        \\fn f() {
        \\    val t = #(
        \\        "the first element is long enough",
        \\        "and the second one pushes it over",
        \\    );
        \\    val decl = @Decl(
        \\        kind: "Record",
        \\        name: "ServiceWithALongName",
        \\        fields: [Field(name: "x", typeName: "i32")],
        \\    );
        \\}
    );
}
