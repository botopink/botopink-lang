//! codegen: case/loop/if/try/throw/catch (split from tests.zig).

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

test "js: case ---- number literal patterns" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(n: i32) -> string {
        \\    val result = case n {
        \\        0 -> "zero";
        \\        1 -> "one";
        \\        _ -> "many";
        \\    };
        \\    @print(result);
        \\    return result;
        \\}
        \\fn main() {
        \\    classify(0);
        \\    classify(1);
        \\    classify(7);
        \\}
    );
}

test "js: case ---- string literal patterns" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn greet(lang: string) -> string {
        \\    val msg = case lang {
        \\        "en" -> "hello";
        \\        "pt" -> "ola";
        \\        _ -> "hi";
        \\    };
        \\    @print(msg);
        \\    return msg;
        \\}
        \\fn main() {
        \\    greet("en");
        \\    greet("pt");
        \\    greet("fr");
        \\}
    );
}

test "js: case ---- or patterns with numbers" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(day: i32) -> string {
        \\    val kind = case day {
        \\        6 | 7 -> "weekend";
        \\        _ -> "weekday";
        \\    };
        \\    @print(kind);
        \\    return kind;
        \\}
        \\fn main() {
        \\    classify(3);
        \\    classify(6);
        \\    classify(7);
        \\}
    );
}

// DIVERGENT wasm RUN LOG, second line (pinned, 06-wasm): `undefined` — the
// value of an `if` with no `else` when the condition is false. commonJS prints
// `undefined`, erlang `ok`; decision 2 (a block's value comes from `break`)
// makes this program a checker error, 07-checker's to land.
test "js: if ---- simple conditional in fn body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    @print(r);
        \\    return r;
        \\}
        \\fn main() {
        \\    sign(5);
        \\    sign(-3);
        \\}
    );
}

test "js: if ---- conditional with else branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return if (n > 0) "positive" else "non-positive";
        \\}
        \\fn main() {
        \\    @print(describe(5));
        \\    @print(describe(-3));
        \\}
    );
}

test "js: try ---- propagate without catch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    @print(r);
        \\    return r;
        \\}
    );
}

test "js: try ---- with inline catch handler" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    @print(r);
        \\    return r;
        \\}
        \\fn main() {
        \\    @print(safe());
        \\}
    );
}

test "js: case ---- list patterns empty, single, spread" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn describe() -> string {
        \\    val items = ["a", "b", "c"];
        \\    return case items {
        \\        [] -> "empty";
        \\        [x] -> "one";
        \\        [first, ..rest] -> "many";
        \\    };
        \\}
    );
}

test "js: loop ---- side-effect print in iterator" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
        \\    loop (messages, 0..) { msg, i ->
        \\        @print(msg);
        \\    };
        \\}
    );
}

test "js: loop ---- two-parameter loop threads reassigned vars out" {
    // `loop (xs) { x, i -> … }` names the index without writing a range. Its
    // reassignments of outer `var`s must survive the loop like the
    // one-parameter form's (a library's lexer written as a counter loop).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pick(xs: Array<string>) -> string {
        \\    var first = "";
        \\    var last = "";
        \\    loop (xs) { x, i ->
        \\        if (i == 0) { first = x; };
        \\        last = x;
        \\    };
        \\    return first + "-" + last;
        \\}
        \\fn weigh(xs: Array<i32>) -> i32 {
        \\    var total = 0;
        \\    loop (xs, 1..) { x, i ->
        \\        total = total + x * i;
        \\    };
        \\    return total;
        \\}
        \\fn main() {
        \\    @print(pick(["a", "b", "c"]));
        \\    @print(weigh([10, 20, 30]));
        \\}
    );
}

test "js: loop ---- a condition loop repeats while its condition holds and threads reassigned vars out" {
    // Decision 8 §10: `loop (condition) { … }` re-tests the condition before
    // every iteration, including a condition false on entry; `continue` skips
    // to the next test.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn count(limit: i32) -> i32 {
        \\    var i = 0;
        \\    var acc = "";
        \\    loop (i < limit) {
        \\        acc = acc + i.toString();
        \\        i = i + 1;
        \\    };
        \\    @print(acc);
        \\    return i;
        \\}
        \\fn evens(limit: i32) -> i32 {
        \\    var i = 0;
        \\    var sum = 0;
        \\    loop (i < limit) {
        \\        i = i + 1;
        \\        if (i % 2 == 1) { continue; };
        \\        sum = sum + i;
        \\    };
        \\    return sum;
        \\}
        \\fn main() {
        \\    @print(count(4));
        \\    @print(count(0));
        \\    @print(evens(6));
        \\}
    );
}

test "js: loop ---- an unconditioned loop ends at break and a break leaves only the inner loop" {
    // Decision 8 §10: `loop { … }` repeats until a `break`; a `break` inside a
    // nested loop ends that loop only; the variables reassigned before the
    // break survive it.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn firstSquareOver(n: i32) -> i32 {
        \\    var k = 0;
        \\    loop {
        \\        k = k + 1;
        \\        if (k * k > n) { break; };
        \\    };
        \\    return k;
        \\}
        \\fn nested() -> i32 {
        \\    var outer = 0;
        \\    var inner = 0;
        \\    loop (outer < 3) {
        \\        outer = outer + 1;
        \\        loop {
        \\            inner = inner + 1;
        \\            break;
        \\        };
        \\    };
        \\    return outer * 10 + inner;
        \\}
        \\fn main() {
        \\    @print(firstSquareOver(20));
        \\    @print(nested());
        \\}
    );
}

test "js: lambda ---- a local closure reassigning outer vars threads them out" {
    // A markup template's shape: a named closure appends to an outer `var`, and
    // is called both directly and from inside a loop.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn render(words: Array<string>) -> string {
        \\    var out = "";
        \\    var count = 0;
        \\    val emit = { w ->
        \\        out = out + "<" + w + ">";
        \\        count = count + 1;
        \\    };
        \\    emit("start");
        \\    loop (words) { w -> emit(w); };
        \\    return out + " " + count.toString();
        \\}
        \\fn main() {
        \\    @print(render(["a", "b"]));
        \\}
    );
}

test "js: loop ---- side-effect over range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    loop (0..10) { i ->
        \\        @print(i);
        \\    };
        \\}
    );
}

test "js: loop ---- map with break (add tax)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val precosBrutos = [100, 250, 400];
        \\val precosComTaxa = loop (precosBrutos) { valor ->
        \\    val taxa = valor * 0.15;
        \\    break valor + taxa;
        \\};
        \\fn main() {
        \\    @print(precosComTaxa);
        \\}
    );
}

test "js: loop ---- filter with conditional break" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val precosBrutos = [100, 250, 400];
        \\val apenasGrandes = loop (precosBrutos) { valor ->
        \\    if (valor > 200) {
        \\        break valor;
        \\    };
        \\};
        \\fn main() {
        \\    @print(apenasGrandes);
        \\}
    );
}

test "js: loop ---- map with break simple" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val ids = [10, 20, 30];
        \\val dobrados = loop (ids) { id ->
        \\    break id * 2;
        \\};
        \\fn main() {
        \\    @print(dobrados);
        \\}
    );
}

test "js: loop ---- even numbers with break" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val processamento = loop (0..10) { i ->
        \\    if (i % 2 == 0) {
        \\        break i;
        \\    };
        \\};
        \\fn main() {
        \\    @print(processamento);
        \\}
    );
}

test "js: case ---- OR patterns with block arm body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _      -> {
        \\        val value = "odd";
        \\        break value;
        \\    };
        \\};
    );
}

test "js: case ---- union return type from mismatched arms" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0    -> "zero";
        \\    _ -> 1;
        \\};
    );
}

// Three defects front `01-checker` handed over with its case-arm typing, in one
// program (04, 2026-09-18). Written with a statement-position `case`, because a
// `case` **value** whose arms are blocks does not type-check yet (01 step 4):
//   1. the arm names the variant with its written path (`Shape.Circle`) — the
//      ctor writes the bare `"Circle"` onto the prototype, so the `tag` test and
//      the declared field order both key on the bare name (`const { radius: r }`,
//      not `const { r }`);
//   2. the block's last expression is the arm's value, so it is returned — which
//      is also what stops execution falling through into the arms below it
//      (before the fix `show(Circle)` printed `2` *and* the wildcard arm's value);
//   3. `_ { v -> … }` binds the whole subject to `v`, which nothing else binds.
//
// No snapshot: the shapes and the RUN LOG are asserted directly, so this front's
// fixture does not write into the erlang/beam/wasm snapshot directories the
// other backend fronts own.
test "js: case ---- written variant path, arm value and whole-value binder" {
    const src =
        \\type Shape {
        \\    Circle(radius: i32),
        \\    Rect(width: i32, height: i32),
        \\}
        \\fn show(s: Shape) {
        \\    case s {
        \\        Shape.Circle(r) { @print(r); }
        \\        _ { v -> @print(v); }
        \\    };
        \\}
        \\fn main() {
        \\    show(Shape.Circle(radius: 2));
        \\    show(Shape.Rect(width: 1, height: 2));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "if (_s.tag === \"Circle\") {",
        "const { radius: r } = _s;",
        "return __bp_print(r);",
        "const v = _s;",
    });
    try h.assertJsRunLog(std.testing.allocator, src,
        \\2
        \\Shape.Rect(width: 1, height: 2)
        \\
    );
}

// Decision 8 §5's arm shapes, step 2's D4. Each cell below compiled before and
// answered wrongly, so each is a measured row, not a new feature:
//   * `i32 when (…)` — a type-test arm bound `const i32 = _s;` and tested
//     nothing (§5.2, tested by §4.1's run-time test, the one `x is T` builds);
//   * `#(0, s)` — a tuple pattern tested `_s.tag === ""` and never matched (P6);
//   * `1...5` — a range pattern did the same (§5.2);
//   * `.Rect(height: h, width: w)` — a written label was ignored and the fields
//     were read by position, so `h` and `w` came out swapped (P4);
//   * `.Some(#(a, b))` — a nested payload pattern bound nothing at all, and the
//     arm ran with `a` and `b` undeclared.
// The `break` form is used because a `case` value whose arms are blocks does not
// type-check yet (01 step 4). No snapshot, for the reason the fixture above it
// gives.
test "js: case ---- type-test, tuple, range, labelled and nested arms" {
    const src =
        \\type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
        \\type Maybe<T> { Some(value: T), None }
        \\fn sign(x: i32) -> string {
        \\    return case x {
        \\        i32 when (x > 0) { break "positive"; }
        \\        _ { break "zero"; }
        \\    };
        \\}
        \\fn pair(t: #(i32, string)) -> string {
        \\    return case t {
        \\        #(0, s) { break s; }
        \\        #(a, b) { break b + "!"; }
        \\    };
        \\}
        \\fn digit(n: i32) -> string {
        \\    return case n {
        \\        1...5 { break "low"; }
        \\        _ { break "high"; }
        \\    };
        \\}
        \\fn labels(s: Shape) -> i32 {
        \\    return case s {
        \\        .Rect(height: h, width: w) { break w * 10 + h; }
        \\        _ { break 0; }
        \\    };
        \\}
        \\fn nested(m: Maybe<#(i32, i32)>) -> i32 {
        \\    return case m {
        \\        .Some(#(a, b)) { break a + b; }
        \\        _ { break -1; }
        \\    };
        \\}
        \\fn rest(s: Shape) -> i32 {
        \\    return case s {
        \\        .Rect(width: w, ..) { break w; }
        \\        _ { break 0; }
        \\    };
        \\}
        \\fn main() {
        \\    @print(sign(5));
        \\    @print(sign(-1));
        \\    @print(pair(#(0, "z")));
        \\    @print(pair(#(9, "y")));
        \\    @print(digit(3));
        \\    @print(digit(8));
        \\    @print(labels(Shape.Rect(width: 2, height: 3)));
        \\    @print(nested(Maybe.Some(value: #(2, 3))));
        \\    @print(rest(Shape.Rect(width: 5, height: 9)));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "if ((typeof _s === \"number\" && Number.isInteger(_s) && _s >= -2147483648 && _s <= 2147483647)) {",
        "if ((Array.isArray(_s) && _s.length === 2 && _s[0] === 0)) {",
        "if ((_s >= 1 && _s <= 5)) {",
        "const { height: h, width: w } = _s;",
        "if (_s.tag === \"Some\" && (Array.isArray(_s.value) && _s.value.length === 2)) {",
        "const a = _s.value[0];",
    });
    try h.assertJsRunLog(std.testing.allocator, src,
        \\positive
        \\zero
        \\z
        \\y!
        \\low
        \\high
        \\23
        \\5
        \\5
        \\
    );
}

test "js: case ---- nested case in block arm" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> {
        \\      case 1 {
        \\          0    -> 54;
        \\          _ -> 1;
        \\      };
        \\   };
        \\   _ -> 1;
        \\};
    );
}

// The loop collects its `break` values into an array (erlang prints
// `[15,20]`). `find` was declared `-> i32`; since 06 C1 a `return` unifies with
// the declared type, so the fixture declares what the loop produces (N12).
test "js: loop ---- break with value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        if (x > 10) { break x; };
        \\    };
        \\}
        \\fn main() {
        \\    @print(find([5, 8, 15, 20]));
        \\}
    );
}

test "js: loop ---- a condition loop's break value is the loop's value" {
    // Decision 8 §10 — `break <v>` makes the loop an expression. A condition
    // loop with no `yield` is a search, not a comprehension: it collected into
    // `_acc` and answered `[3]` / `[8]` where §10 asks for `3` / `8`. A loop
    // that ends without breaking has no value to give, which is `null`.
    //
    // A RUN LOG, not a snapshot: the erlang, beam and wasm baselines of this
    // program are not this front's to record, and erlang does not compile it
    // at all (`ConditionLoopValueUnsupported`).
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    var k = 0;
        \\    var i = 0;
        \\    var n = 0;
        \\    val r = loop { k = k + 1; if (k > 2) { break k; }; };
        \\    @print(r);
        \\    val found = loop (i < 10) { if (i == 4) { break i * 2; }; i = i + 1; };
        \\    @print(found);
        \\    val never = loop (n < 3) { n = n + 1; };
        \\    @print(never);
        \\}
    , "3\n8\nnull\n");
}

test "js: loop ---- a condition loop that yields still collects" {
    // The other side of the same fork: a `yield` in the body makes it a
    // comprehension, and a `break <v>` there contributes its value and ends
    // the loop.
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    var i = 0;
        \\    val xs = loop (i < 10) {
        \\        i = i + 1;
        \\        if (i > 3) { break i; };
        \\        yield i;
        \\    };
        \\    @print(xs);
        \\}
    , "[1, 2, 3, 4]\n");
}

test "js: loop ---- continue in iteration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumEvens(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        if (x % 2 != 0) { continue; };
        \\        yield x;
        \\    };
        \\}
    );
}

test "js: loop ---- yield accumulation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn doubles(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        yield x * 2;
        \\    };
        \\}
        \\fn main() {
        \\    @print(doubles([1, 2, 3]));
        \\}
    );
}

test "js: if ---- with else branch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn abs(n: i32) -> i32 {
        \\    val result = if (n < 0) -n else n;
        \\    return result;
        \\}
        \\fn main() {
        \\    @print(abs(-5));
        \\    @print(abs(3));
        \\}
    );
}

test "js: if ---- null-check binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn getName(name: ?string) -> string {
        \\    if (name) { n ->
        \\        return n;
        \\    };
        \\    return "unknown";
        \\}
    );
}

test "js: case ---- multiple subjects" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(a: i32, b: i32) {
        \\    case a, b {
        \\        0, 0 -> null;
        \\        _, _ -> null;
        \\    };
        \\}
    );
}

test "js: case ---- nested case in fn body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(x: i32) -> string {
        \\    return case (x) {
        \\        0 -> {
        \\            break case (x) {
        \\                0 -> "zero";
        \\                _ -> "other";
        \\            };
        \\        };
        \\        _ -> "non-zero";
        \\    };
        \\}
    );
}

test "js: try ---- catch with throw rethrow" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type ApiError(msg: string)
        \\#[@result]
        \\fn fetch() -> @Result<i32, ApiError> {
        \\    throw ApiError(msg: "not found");
        \\}
        \\#[@result]
        \\fn strict() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "fetch failed";
        \\    return r;
        \\}
    );
}

test "js: try ---- catch with return fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type NetError(code: i32)
        \\#[@result]
        \\fn fetch() -> @Result<i32, NetError> {
        \\    throw NetError(code: 500);
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch return -1;
        \\    return r;
        \\}
    );
}

test "js: try ---- nested try catch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type DbError(msg: string)
        \\#[@result]
        \\fn inner() -> @Result<i32, DbError> {
        \\    throw DbError(msg: "conn refused");
        \\}
        \\#[@result]
        \\fn outer() -> @Result<i32, DbError> {
        \\    throw DbError(msg: "timeout");
        \\}
        \\fn process() -> i32 {
        \\    val a = try inner() catch 0;
        \\    val b = try outer() catch a;
        \\    @print(a, b);
        \\    return a + b;
        \\}
        \\fn main() {
        \\    @print(process());
        \\}
    );
}

test "js: try ---- catch tail on method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type ParseError(msg: string)
        \\val Parser = type {
        \\    fn parse(self: Self) -> @Result<i32, ParseError> {
        \\        throw ParseError(msg: "bad input");
        \\    }
        \\}
        \\fn run(p: Parser) -> i32 {
        \\    val result = p.parse() catch 0;
        \\    return result;
        \\}
    );
}

test "js: throw ---- string literal" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fail() {
        \\    throw "something went wrong";
        \\}
    );
}

// A bare `throw;` (no operand) — JS-6 in `codegen/js/AGENTS.md`. Decided
// semantics: rejected, not a rethrow. The parser requires an operand
// (`throw [new] <expr>`), so the program never reaches a backend; the
// snapshot pins the parse error on all four, which is what lets
// `Stmt.throw_` carry a required operand.
test "js: throw ---- bare throw inside try catch is rejected" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\#[@result]
        \\fn g(x: i32) -> @Result<i32, string> {
        \\    if (x > 0) { return x; };
        \\    throw "neg";
        \\}
        \\#[@result]
        \\fn f(x: i32) -> @Result<i32, string> {
        \\    val r = try g(x) catch { e -> throw; };
        \\    return r;
        \\}
    );
}

test "js: throw ---- record constructor" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type AppError(code: i32, msg: string)
        \\fn validate(x: i32) {
        \\    if (x < 0) {
        \\        throw AppError(code: 400, msg: "negative");
        \\    };
        \\}
    );
}

test "js: try ---- propagate in multi-statement fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type IoError(path: string)
        \\#[@result]
        \\fn step1() -> @Result<i32, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\#[@result]
        \\fn step2(x: i32) -> @Result<i32, IoError> {
        \\    throw IoError(path: "/out");
        \\}
        \\#[@result]
        \\fn pipeline() -> @Result<i32, IoError> {
        \\    val a = try step1();
        \\    val b = try step2(a);
        \\    return b;
        \\}
    );
}

test "js: try ---- catch with lambda handler" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type FetchError(url: string)
        \\#[@result]
        \\fn fetch() -> @Result<i32, FetchError> {
        \\    throw FetchError(url: "/api");
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch fn(e) { return 0; };
        \\    return r;
        \\}
    );
}

test "js: catch ---- tail on binary expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type CalcError(msg: string)
        \\#[@result]
        \\fn getA() -> @Result<i32, CalcError> {
        \\    throw CalcError(msg: "overflow");
        \\}
        \\fn compute() -> i32 {
        \\    val r = getA() catch 0;
        \\    return r;
        \\}
    );
}

test "js: try ---- catch with case handler" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val ErrorKind = type { NotFound, Timeout }
        \\#[@result]
        \\fn fetch() -> @Result<i32, ErrorKind> {
        \\    throw ErrorKind.NotFound;
        \\}
        \\fn handle() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
    );
}

test "js: throw ---- inside case arm" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Status { Ok, Fail }
        \\#[@result]
        \\fn check(s: Status) -> @Result<i32, string> {
        \\    return case s {
        \\        Ok -> 1;
        \\        Fail -> throw "failed";
        \\    };
        \\}
        \\fn main() {
        \\    @print(check(Status.Ok).isOk());
        \\    @print(check(Status.Fail).isOk());
        \\}
    );
}

test "js: try ---- catch preserves surrounding bindings" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type LoadError(msg: string)
        \\#[@result]
        \\fn load() -> @Result<i32, LoadError> {
        \\    throw LoadError(msg: "not found");
        \\}
        \\fn process() -> i32 {
        \\    val prefix = 10;
        \\    val data = try load() catch 0;
        \\    val suffix = 20;
        \\    @print(prefix, data, suffix);
        \\    return prefix + data + suffix;
        \\}
        \\fn main() {
        \\    @print(process());
        \\}
    );
}

test "js: throw ---- inside loop body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@result]
        \\fn validate(items: i32) -> @Result<i32, string> {
        \\    loop (0..items) { i ->
        \\        if (i > 2) { throw "too many"; };
        \\    };
        \\    return items;
        \\}
        \\fn main() {
        \\    @print(validate(2).isOk());
        \\}
    );
}

test "js: try ---- multiple catch with different fallbacks" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type UserError(msg: string)
        \\#[@result]
        \\fn fetchName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "name missing");
        \\}
        \\#[@result]
        \\fn fetchAge() -> @Result<i32, UserError> {
        \\    throw UserError(msg: "age missing");
        \\}
        \\fn loadUser() {
        \\    val name = try fetchName() catch "anonymous";
        \\    val age = try fetchAge() catch 0;
        \\    @print(name, age);
        \\}
        \\fn main() {
        \\    loadUser();
        \\}
    );
}

test "js: catch ---- tail on function call no try" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type RiskError(level: i32)
        \\#[@result]
        \\fn risky() -> @Result<i32, RiskError> {
        \\    throw RiskError(level: 5);
        \\}
        \\fn safe() -> i32 {
        \\    return risky() catch -1;
        \\}
    );
}

test "js: case ---- guard clause on bound identifier" {
    try h.assertJsContains(std.testing.allocator,
        \\fn classify(n: i32) -> string {
        \\    return case n {
        \\        x if x > 0 -> "positive";
        \\        0 -> "zero";
        \\        _ -> "negative";
        \\    };
        \\}
    , &.{
        "const x = _s;",
        "if ((x > 0)) return \"positive\";",
        "if (_s === 0) return \"zero\";",
        "return \"negative\";",
    });
}

test "js: case ---- guard clause on variant fields" {
    try h.assertJsContains(std.testing.allocator,
        \\val Shape = type {
        \\    Circle(r: i32),
        \\    Square(s: i32),
        \\}
        \\fn big(sh: Shape) -> string {
        \\    return case sh {
        \\        Circle(r) if r > 10 -> "big circle";
        \\        _ -> "other";
        \\    };
        \\}
    , &.{
        "if (_s.tag === \"Circle\") {",
        "if ((r > 10)) return \"big circle\";",
    });
}

// All-target snapshots for case guard clauses. The BEAM backend lowers a guard
// after the pattern's variables are bound: on a failing guard it restores the
// subject and falls through to the next arm (see `emitGuardPre`/`emitGuardPost`
// in `beam_asm.zig`). commonJS/erlang/wasm capture their own current behaviour.
test "case guard ---- bound identifier numeric guard" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(n: i32) -> string {
        \\    return case n {
        \\        x if x > 0 -> "positive";
        \\        0 -> "zero";
        \\        _ -> "negative";
        \\    };
        \\}
    );
}

test "case guard ---- variant field guard" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Shape = type {
        \\    Circle(r: i32),
        \\    Square(s: i32),
        \\}
        \\fn big(sh: Shape) -> string {
        \\    return case sh {
        \\        Circle(r) if r > 10 -> "big circle";
        \\        _ -> "other";
        \\    };
        \\}
    );
}

// Mutual recursion across declaration order, on every backend (mutual-recursion
// spec, Wave 1). `main` calls `isEven`, declared *after* it (a forward
// reference); `isEven`/`isOdd` then call each other. Each carries a bare-`if`
// base-case guard (`if (n == 0) { return … };`) followed by the recursive tail
// call. This is the BEAM regression guard: that else-less `if` must FALL
// THROUGH to the tail call when the guard is false — an earlier emitter ended
// the function in the else branch (`move undefined` + `return.`), turning the
// recursive call into unreachable dead code so `isEven(10)` returned the atom
// `undefined` instead of `true`. commonJS/erlang were already correct; wasm
// needed two unrelated fixes to *run* this (boolean literals `true`/`false` →
// `i32.const 1`/`0`, not an undefined `global.get $true`; and the entrypoint
// wrapper must `drop` a value-returning `main`).
test "js: mutual recursion ---- forward reference + bare-if base case on every backend" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> bool {
        \\    return isEven(10);
        \\}
        \\
        \\fn isEven(n: i32) -> bool {
        \\    if (n == 0) { return true; };
        \\    return isOdd(n - 1);
        \\}
        \\
        \\fn isOdd(n: i32) -> bool {
        \\    if (n == 0) { return false; };
        \\    return isEven(n - 1);
        \\}
    );
}
