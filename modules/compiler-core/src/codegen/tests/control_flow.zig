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
    // The propagating form returns the `Error` out of the enclosing function,
    // so that function needs an error channel of its own (decision 95): a plain
    // `fn process() -> i32` is `effect-try-without-fallible-channel`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn process() -> @Result<i32, string> {
        \\    val r = try fetch();
        \\    @print(r);
        \\    return r;
        \\}
    );
}

test "js: try ---- with inline catch handler" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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
        \\    for (messages) { msg ->
        \\        @print(msg);
        \\    };
        \\}
    );
}

test "js: loop ---- an indexed loop threads reassigned vars out" {
    // Decision 105 has no index binder: `for (0..xs.length) { i -> }` is the
    // spelling, and a counter the body reassigns is the other. Both must let
    // the reassignments of outer `var`s survive the loop like the plain
    // `for (xs) { x -> }` form's (a library's lexer written as a counter loop).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn pick(xs: Array<string>) -> string {
        \\    var first = "";
        \\    var last = "";
        \\    var i = 0;
        \\    for (xs) { x ->
        \\        if (i == 0) { first = x; };
        \\        last = x;
        \\        i = i + 1;
        \\    };
        \\    return first + "-" + last;
        \\}
        \\fn weigh(xs: Array<i32>) -> i32 {
        \\    var total = 0;
        \\    for (0..xs.length) { i ->
        \\        total = total + (xs[i] ?? 0) * (i + 1);
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
    // Decision 8 §10: `while (condition) { … }` re-tests the condition before
    // every iteration, including a condition false on entry; `continue` skips
    // to the next test.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn count(limit: i32) -> i32 {
        \\    var i = 0;
        \\    var acc = "";
        \\    while (i < limit) {
        \\        acc = acc + i.toString();
        \\        i = i + 1;
        \\    };
        \\    @print(acc);
        \\    return i;
        \\}
        \\fn evens(limit: i32) -> i32 {
        \\    var i = 0;
        \\    var sum = 0;
        \\    while (i < limit) {
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
        \\    while (outer < 3) {
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
        \\    for (words) { w -> emit(w); };
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
        \\    for (0..10) { i ->
        \\        @print(i);
        \\    };
        \\}
    );
}

// Decision 105 — a loop is a statement. What used to be collected by `break
// <v>` / `yield v` out of a `loop (…)` is a `var` the body reassigns, or a
// `map` / `filter`; the four fixtures below are the old comprehension shapes
// written that way, and they answer what the comprehensions answered.
test "js: loop ---- a var pushed to in a loop body (add tax)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val precosBrutos = [100, 250, 400];
        \\    var precosComTaxa = [];
        \\    for (precosBrutos) { valor ->
        \\        val taxa = valor * 0.15;
        \\        precosComTaxa.push(valor + taxa);
        \\    };
        \\    @print(precosComTaxa);
        \\}
    );
}

test "js: loop ---- a conditional push keeps some items" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val precosBrutos = [100, 250, 400];
        \\    var apenasGrandes = [];
        \\    for (precosBrutos) { valor ->
        \\        if (valor > 200) {
        \\            apenasGrandes.push(valor);
        \\        };
        \\    };
        \\    @print(apenasGrandes);
        \\}
    );
}

test "js: loop ---- map is the collecting form" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val ids = [10, 20, 30];
        \\    val dobrados = ids.map({ id -> id * 2 });
        \\    @print(dobrados);
        \\}
    );
}

test "js: loop ---- even numbers pushed from a range loop" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    var processamento = [];
        \\    for (0..10) { i ->
        \\        if (i % 2 == 0) {
        \\            processamento.push(i);
        \\        };
        \\    };
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

// A loop whose ITERABLE is written at the loop, not passed in as a name — the
// shape no cell in this corpus had, and the one beam emitted unassemblable `.S`
// for. `lowerLoop` materialises the iterable in the ENCLOSING frame (before it
// builds the body closure), so the array literal's cons accumulator takes one of
// that frame's y-slots; `countLocalsRec`'s `.loop` arm counted nothing for a
// collection loop, so the frame stayed at `{allocate, 0, 0}` and `erlc
// +from_asm` refused the module:
//
//     main:1: function main/0+7:
//       Internal consistency check failed - please report this bug.
//       Instruction: {move,{x,0},{y,0}}
//       Error:       {invalid_store,{y,0}}
//
// `beam_export_audit.sh` stayed green through it, because assembling every
// snapshot cannot find a shape no snapshot has. Both prints run on all four
// backends now: `1`, `2`, `3`, then `[20]`.
//
// KNOWN (decision 8 §10, all four backends): `break <value>` out of a
// COLLECTION loop answers a one-element ARRAY, `[20]`, where §10 reads as the
// value itself, `20`. commonJS, erlang, wasm and beam agree on `[20]`, so this
// is the decision's row (front 03's step 3 D7 names it), not one backend's.
test "js: loop ---- a loop over an array literal, and a break out of one" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    for ([1, 2, 3]) { x -> @print(x); };
        \\    var first = 0;
        \\    for ([1, 2, 3]) { x -> if (x == 2) { first = x * 10; break; }; };
        \\    @print(first);
        \\}
    );
}

// A search leaves its answer in a `var` and ends the loop with a bare `break`
// (decision 105: no loop has a value).
test "js: loop ---- a search ends at break with its answer in a var" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32 {
        \\    var found = 0;
        \\    for (arr) { x ->
        \\        if (x > 10) { found = x; break; };
        \\    };
        \\    return found;
        \\}
        \\fn main() {
        \\    @print(find([5, 8, 15, 20]));
        \\}
    );
}

test "js: loop ---- a condition loop's answer is read from a var" {
    // Decision 105 — `while` and `loop` are statements: the answer a loop
    // finds lives in a `var` the body reassigns before its bare `break`, and
    // a loop that ends without finding one leaves the `var` as it was.
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    var k = 0;
        \\    var r = 0;
        \\    loop { k = k + 1; if (k > 2) { r = k; break; }; };
        \\    @print(r);
        \\    var i = 0;
        \\    var found = 0;
        \\    while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
        \\    @print(found);
        \\    var n = 0;
        \\    while (n < 3) { n = n + 1; };
        \\    @print(n);
        \\}
    , "3\n8\n3\n");
}

test "js: loop ---- a condition loop's answer in a var, on every backend" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    var i = 0;
        \\    var found = 0;
        \\    while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
        \\    @print(found);
        \\    @print(i);
        \\    var k = 0;
        \\    var r = 0;
        \\    loop { k = k + 1; if (k > 2) { r = k; break; }; };
        \\    @print(r);
        \\    var n = 0;
        \\    var never = 0;
        \\    while (n < 3) { if (n == 99) { never = n; break; }; n = n + 1; };
        \\    @print(never);
        \\}
    );
}

test "js: loop ---- continue in iteration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumEvens(arr: i32[]) -> i32[] {
        \\    var out = [];
        \\    for (arr) { x ->
        \\        if (x % 2 != 0) { continue; };
        \\        out.push(x);
        \\    };
        \\    return out;
        \\}
    );
}

test "js: loop ---- a var accumulates what a body pushes" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn doubles(arr: i32[]) -> i32[] {
        \\    var out = [];
        \\    for (arr) { x ->
        \\        out.push(x * 2);
        \\    };
        \\    return out;
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
        \\fn fetch() -> @Result<i32, ApiError> {
        \\    throw ApiError(msg: "not found");
        \\}
        \\fn strict() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "fetch failed";
        \\    return r;
        \\}
    );
}

test "js: try ---- catch with return fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type NetError(code: i32)
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
        \\fn inner() -> @Result<i32, DbError> {
        \\    throw DbError(msg: "conn refused");
        \\}
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
        \\fn g(x: i32) -> @Result<i32, string> {
        \\    if (x > 0) { return x; };
        \\    throw "neg";
        \\}
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
        \\fn step1() -> @Result<i32, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\fn step2(x: i32) -> @Result<i32, IoError> {
        \\    throw IoError(path: "/out");
        \\}
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
        \\fn validate(items: i32) -> @Result<i32, string> {
        \\    for (0..items) { i ->
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
        \\fn fetchName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "name missing");
        \\}
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

// ── front 02-erlang: the two `case` defects `01-checker` handed over ──────────
//
// Both are erlang-only and both are *load* failures, not wrong values, so they
// are asserted by running the emitted module rather than by a snapshot: a
// snapshot of `{'.Some', V}` looks plausible and never matches, and `.None`
// renders a token `erlc` refuses outright.
//
// The §5.1 value-position forms these rows are written for (`test/case_variants.bp`,
// `test/case_guards.bp`) do not type-check until `01-checker` step 4 lands, so
// each cell is the same arm in **statement** position, which compiles at
// `bef762b`. When step 4 lands, the value-position twins join the language suite.

test "erlang: case ---- a variant pattern written with its path matches the bare tag" {
    // Handover 1. The constructor emits the tag the declaration renders
    // (`{test@main@@Maybe__v__some, 7}` since half 3); the pattern emitted what
    // was written — `{'.Some', V}`, matching nothing, and a nullary `.None` as
    // the bare token `.None`, which is `syntax error before: '.'`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Maybe { Some(v: i32), None }
        \\fn show(m: Maybe) { case m { .Some(v) { @print(v) } .None { @print(0) } }; }
        \\fn main() { show(Maybe.None); show(Maybe.Some(v: 7)); }
    , "0\n7\n", &.{ "{test@main@@Maybe__v__some, V} ->", "test@main@@Maybe__v__none ->" });
}

test "erlang: case ---- a one-parameter arm binds the whole subject" {
    // Handover 3. `_ { v -> … }` names the subject; nothing bound it, so the
    // arm body read an erlang variable the clause never introduced
    // (`variable 'V' is unbound`). The name is now an alias on the clause
    // pattern, and on a wildcard it *is* the pattern.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn show(n: i32) { case n { 0 { @print("zero") } _ { v -> @print(v) } }; }
        \\fn main() { show(4); show(0); }
    , "4\nzero\n", &.{"        V ->"});
}

test "erlang: case ---- a one-parameter arm on a variant pattern aliases it" {
    // The same binder where the pattern is not a wildcard: erlang's `V = Pat`
    // alias binds the subject without evaluating it twice.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Maybe { Some(v: i32), None }
        \\fn show(m: Maybe) { case m { .Some(v) { w -> @print(v) } .None { @print(0) } }; }
        \\fn main() { show(Maybe.Some(v: 7)); }
    , "7\n", &.{"W = {test@main@@Maybe__v__some, V} ->"});
}

// ── front 02-erlang, reopened: the three `patternNode` defects 01 isolated ────
//
// Each one made an arm match NOTHING, or the wrong arm match everything, so each
// is asserted by running the emitted module and pinning the clause head it now
// writes. commonJS had all three right, which is why only erlang's lines sat in
// `tests/language/expected-failures.txt`.
//
// The §5.1 cells these rows are written for (`test/case_tuples.bp`,
// `test/case_variants.bp`, `test/case_guards.bp`, `test/case_exhaustive.bp`) are
// in VALUE position and do not type-check until `01-checker` step 4 and step 5
// land, so each cell below is the same pattern in statement position, which
// compiles at `b09bf9c6`.

test "erlang: case ---- a tuple pattern is the bare tuple, with no variant tag" {
    // Defect 1. `#(0, s)` rode the variant lowering and gained the tag atom of a
    // variant with no name — `{'', 0, S}`, which no constructor builds — so every
    // tuple arm died with `{case_clause,{0,5}}`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  val p = #(0, 5);
        \\  case p { #(0, s) { @print(s) } #(n, _) { @print(n) } };
        \\}
    , "5\n", &.{ "{0, S} ->", "{N, _} ->" });
}

test "erlang: case ---- `..` writes the fields the pattern does not name" {
    // Defect 2. `v.rest` was never read: `Rect(width: w, ..)` was emitted
    // a two-slot pattern against the three-slot tuple the constructor builds,
    // and `Circle(..)` collapsed to the bare variant atom. Both matched nothing.
    // The declared arity comes from `variant_fields`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
        \\fn main() {
        \\  case Shape.Rect(width: 5, height: 9) { Rect(width: w, ..) { @print(w) } Circle(..) { @print(0) } };
        \\  case Shape.Circle(radius: 1) { Rect(width: w, ..) { @print(w) } Circle(..) { @print(0) } };
        \\}
    , "5\n0\n", &.{ "{test@main@@Shape__v__rect, W, _} ->", "{test@main@@Shape__v__circle, _} ->" });
}

test "erlang: case ---- a tuple under `..` is a tuple_size guard, not a fixed arity" {
    // Defect 2, the tuple half. `#(a, ..)` has an arity that is only a LOWER
    // bound and an erlang tuple pattern has no such thing, so the clause matches
    // a fresh variable, the shape becomes a guard, and the named element is an
    // `element/2` read the body opens with.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  val t = #(4, 5, 6);
        \\  case t { #(a, ..) { @print(a) } };
        \\}
    , "4\n", &.{ "when is_tuple(", "tuple_size(", ") >= 1) ->", "= element(1, " });
}

test "erlang: case ---- a primitive type pattern is a guard, not a binder" {
    // Defect 3. `i32` / `string` are §5.2's type-test arms. Lowered as the plain
    // binders `I32` / `String` the FIRST arm matched every subject, so `show("x")`
    // answered the `i32` arm; erlang cannot test a type in a pattern, so the test
    // is a clause guard on the variable the arm keeps — by value since step 2
    // (§4.1: a number with no fractional part, in range).
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn show(v: i32 | string) {
        \\  case v { i32 { @print("int") } string { @print("str") } };
        \\}
        \\fn main() { show(3); show("abcd"); }
    , "int\nstr\n", &.{ "I32 when is_number(I32), (I32 == trunc(I32))", "String when is_binary(String) ->" });
}

// ── front 03-beam: `case` patterns in BEAM assembly (C-06, C-07 D4) ──────────
//
// Each row made an arm match everything or nothing on beam, so each is asserted
// by assembling and running the emitted module and by pinning the test
// instructions it now writes. The erlang twins are the block above.

test "beam: case ---- an inclusive range is two is_ge tests (decision 53)" {
    // C-06's beam half. `1...9` reached the untested `.literals` arm and matched
    // every subject — 0 and 10 answered `1`. Both ends are inclusive; a string
    // bound compares the binaries in term order.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn n(x: i32) -> i32 { return case x { 1...3 { 1 } 4...6 { 2 } _ { 0 } }; }
        \\fn s(x: string) -> i32 { return case x { "b"..."d" { 1 } _ { 0 } }; }
        \\fn main() {
        \\  @print(n(0)); @print(n(1)); @print(n(3)); @print(n(4)); @print(n(6)); @print(n(7));
        \\  @print(s("a")); @print(s("b")); @print(s("d")); @print(s("e"));
        \\}
    , "0\n1\n1\n2\n2\n0\n0\n1\n1\n0\n", &.{ "{test, is_ge, ", "[{x, 0}, {integer, 1}]", "[{integer, 3}, {x, 0}]" });
}

test "beam: case ---- a tuple pattern is the bare tuple, element by element" {
    // C-07 D4 (P6, P7). `#(0, s)` reached the untested `.literals` arm, so the
    // first tuple arm took every subject and bound nothing. It is `is_tuple` +
    // `test_arity`, then each slot tested from `get_tuple_element`; under `..`
    // the arity is a lower bound read with the guard BIF `element/2`.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn classify(p: #(i32, string)) -> string {
        \\  return case p { #(0, s) { "zero " + s } #(n, "x") { "x " + n.toString() } #(_, s) { s } };
        \\}
        \\fn first(t: #(i32, i32, i32)) -> i32 { return case t { #(a, ..) { a } }; }
        \\fn main() {
        \\  @print(classify(#(0, "a"))); @print(classify(#(7, "x"))); @print(classify(#(7, "y")));
        \\  @print(first(#(4, 5, 6)));
        \\}
    , "zero a\nx 7\ny\n4\n", &.{ "{test, test_arity, ", "{bif, element, " });
}

test "beam: case ---- `..` and labels read the declared variant" {
    // C-07 D4 (P4, P7). `Rect(height: h, width: w)` binds by label, not by
    // position, and `Circle(..)` / `Rect(5, ..)` take the arity the variant
    // DECLARES — both used to match every subject.
    try h.assertBeamRunLog(std.testing.allocator,
        \\type Shape { Circle(radius: i32), Rect(width: i32, height: i32) }
        \\fn width(s: Shape) -> i32 { return case s { Rect(height: h, width: w) { w * 100 + h } Circle(..) { 0 } }; }
        \\fn five(s: Shape) -> i32 { return case s { Rect(5, ..) { 1 } _ { 0 } }; }
        \\fn kind(s: Shape) -> string {
        \\  return case s { .Rect(width: w, height: h) when (w == h) { "square" } .Rect(..) { "rect" } .Circle(..) { "circle" } };
        \\}
        \\fn main() {
        \\  @print(width(Shape.Rect(width: 5, height: 9))); @print(width(Shape.Circle(radius: 1)));
        \\  @print(five(Shape.Rect(width: 5, height: 9))); @print(five(Shape.Rect(width: 6, height: 9)));
        \\  @print(kind(Shape.Rect(width: 2, height: 2))); @print(kind(Shape.Rect(width: 2, height: 3))); @print(kind(Shape.Circle(radius: 2)));
        \\}
    , "509\n0\n1\n0\nsquare\nrect\ncircle\n", &.{"{test, is_tagged_tuple, "});
}

test "beam: case ---- a primitive type or a bool literal is a test, not a binder" {
    // C-07 D4 (§5.2). `i32 { … }`, `string { … }`, `true { … }` were plain
    // binders, so the first arm answered for every subject.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn kind(v: i32 | string) -> string { return case v { i32 { "int" } string { "str" } }; }
        \\fn yesNo(b: bool) -> string { return case b { true { "yes" } false { "no" } }; }
        \\fn sign(x: i32) -> string {
        \\  return case x { i32 when (x > 0) { "positive" } i32 when (x < 0) { "negative" } _ { "zero" } };
        \\}
        \\fn main() {
        \\  @print(kind(3)); @print(kind("abcd")); @print(yesNo(true)); @print(yesNo(false));
        \\  @print(sign(3)); @print(sign(-3)); @print(sign(0));
        \\}
    , "int\nstr\nyes\nno\npositive\nnegative\nzero\n", &.{ "{test, is_integer, ", "{test, is_binary, ", "{test, is_eq_exact, " });
}

test "beam: an enum variant's labelled payload claims its declared slot" {
    // `run/labelled_arguments.bp`'s beam twin of the erlang row. The record
    // constructor placed a labelled argument by field index; the variant
    // constructor zipped by position, so `Shape.Rect(height: 2, width: 5)`
    // was built `{Rect, 2, 5}` and the cell printed `205`.
    try h.assertBeamRunLog(std.testing.allocator,
        \\type Shape { Rect(width: i32, height: i32), Dot }
        \\fn shown(s: Shape) -> i32 { return case s { Shape.Rect(w, h) -> w * 100 + h; Shape.Dot -> 0; }; }
        \\fn main() {
        \\  @print(shown(Shape.Rect(height: 2, width: 5)));
        \\  @print(shown(Shape.Rect(width: 5, height: 2)));
        \\  @print(shown(Shape.Rect(5, 2)));
        \\}
    , "502\n502\n502\n", &.{});
}

// A string literal above U+007F — raw in the source or written `\u{…}` — is
// its UTF-8 bytes on erlang and beam. `erl_emitter.writeStringFromLexeme`
// wrote `\x{e7}` / a raw `ç` inside a plain `<<"…">>`, which keeps one byte per
// character (the low 8 bits): `"\u{2028}"` was `<<40>>`, `"\u{1f600}"` `<<0>>`
// (handed over by `01-std-lib-enablement`, 2026-09-25).
test "erlang: a non-ASCII string literal is its UTF-8 bytes" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  val a = "ç";
        \\  val b = "\u{e7}";
        \\  @print(a == b);
        \\  @print("\u{1f600}" == "😀");
        \\  @print("a\u{2028}b".length());
        \\  @print(["ç", "\u{e9}"]);
        \\  @print("Memória".toUpper());
        \\}
    , "true\ntrue\n3\n[\"ç\", \"é\"]\nMEMÓRIA\n", &.{"\\x{C3}\\x{A7}"});
}

test "beam: a non-ASCII string literal is its UTF-8 bytes" {
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn main() {
        \\  val a = "ç";
        \\  val b = "\u{e7}";
        \\  @print(a == b);
        \\  @print("\u{1f600}" == "😀");
        \\  @print("a\u{2028}b".length());
        \\  @print(["ç", "\u{e9}"]);
        \\  @print("Memória".toUpper());
        \\}
    , "true\ntrue\n3\n[\"ç\", \"é\"]\nMEMÓRIA\n", &.{"\\x{C3}\\x{A7}"});
}

test "erlang: calling the result of a call applies it (`calleeExpr`)" {
    // `test/curried_call.bp` (C-09's backend half): `adder(3)(4)` carries its
    // callee as an expression, and lowered as a name it was `''(4)`, which
    // `erlc` refuses.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
        \\fn pick(which: bool) -> fn(x: i32) -> i32 { return { x -> if (which) { x } else { 0 - x } }; }
        \\fn main() {
        \\  @print(adder(3)(4));
        \\  @print(pick(false)(5));
        \\  @print(adder(10)(adder(1)(2)));
        \\}
    , "7\n-5\n13\n", &.{"(adder(3))(4)"});
}

test "beam: calling the result of a call applies it (`calleeExpr`)" {
    // The beam twin: the callee value is parked on the stack while the
    // arguments are staged, then `call_fun` — it was
    // `{unresolved_call, '', 1}` at run time.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn adder(n: i32) -> fn(x: i32) -> i32 { return { x -> x + n }; }
        \\fn twice(n: i32) -> i32 { return adder(n)(n); }
        \\fn main() {
        \\  @print(adder(3)(4));
        \\  @print(adder(10)(adder(1)(2)));
        \\  @print(twice(4));
        \\  val xs: Array<i32> = [1, 2];
        \\  @print(xs.map({ x -> adder(x)(100) }));
        \\}
    , "7\n13\n8\n[101, 102]\n", &.{"{call_fun, 1}"});
}

test "erlang: an enum variant's labelled payload claims its declared slot" {
    // `run/labelled_arguments.bp`'s erlang row: the variant constructor zipped
    // by position, so `Shape.Rect(height: 2, width: 5)` was built
    // `{…rect, 2, 5}` and the cell printed `205` (02-erlang, no step).
    try h.assertErlangRunLog(std.testing.allocator,
        \\type Shape { Rect(width: i32, height: i32), Dot }
        \\fn shown(s: Shape) -> i32 { return case s { Shape.Rect(w, h) -> w * 100 + h; Shape.Dot -> 0; }; }
        \\fn main() {
        \\  @print(shown(Shape.Rect(height: 2, width: 5)));
        \\  @print(shown(Shape.Rect(width: 5, height: 2)));
        \\  @print(shown(Shape.Rect(5, 2)));
        \\}
    , "502\n502\n502\n", &.{});
}

test "beam: a lambda whose body is an if, a case or a try answers its value" {
    // 03 handover 01, `run/lambda_expression_body.bp`. `emitLambdaBody`
    // treated only a literal/name/operator/call tail as the lambda's value;
    // an `if`, a `case` and a `try … catch` fell to `emitBody`, which answers
    // the atom `ok` — `ok,ok,ok` on each line. The value tails are now
    // `armValueTail`'s, the set a `case` arm's block already used.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn tenth(x: i32) -> @Result<i32, string> {
        \\    if (x > 1) { return x * 10; } else { throw "too small"; }
        \\}
        \\fn main() {
        \\  val xs = [1, 2, 3];
        \\  @print(xs.map({ x -> if (x > 1) { x * 10 } else { x } }).join(","));
        \\  @print(xs.map({ x -> case x { 1 { 100 } _ { 200 } } }).join(","));
        \\  @print(xs.map({ x -> try tenth(x) catch 0 }).join(","));
        \\}
    , "1,20,30\n100,200,200\n0,20,30\n", &.{});
}

test "beam: a synth helper a type's module reached first is the file module's too" {
    // `run/narrowing_null_guard_clause.bp`. `'-bp_at-'/2` (and every other
    // once-per-module helper) was cached by name across the whole emit: a
    // record METHOD reached it first, inside the type's own module, and the
    // file's `fn` then asked its own label table for a name that module never
    // reserved — `UnknownFunction`, no location. Each unit now keeps its own.
    try h.assertBeamRunLog(std.testing.allocator,
        \\type Row(cells: string[]) {
        \\    fn widest(self: Self) -> i32 { return (self.cells.at(0) ?? "").length(); }
        \\}
        \\fn firstOf(ws: string[]) -> i32 { return (ws.at(0) ?? "").length(); }
        \\fn main() { @print(Row(cells: ["abc"]).widest()); @print(firstOf(["ab"])); }
    , "3\n2\n", &.{});
}

test "beam: the module body runs once, in declaration order, before main" {
    // `run/module_init_order.bp`. A named module-level `val` was a 0-arity
    // function evaluated on every READ (`first` printed twice, after `main`),
    // and the `'_botopink_main'/0` wrapper ran only the `_` statements. An
    // effectful `val` now caches under `persistent_term` (erlang's
    // `cachedValueExpr`) and the wrapper runs the module body in order.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn note(tag: string) -> i32 { @print(tag); return 1; }
        \\val first = note("first");
        \\val _second = note("second");
        \\fn main() { @print("main"); @print(first); @print(first); }
    , "first\nsecond\nmain\n1\n1\n", &.{ "{extfunc, persistent_term, get, 2}", "{extfunc, persistent_term, put, 2}" });
}

test "beam: is and == read numbers by value only where decision 8 says so" {
    // C-07 D1/D3 (§4.1, §2.3). `x is f64` is any number (`is_number`, was
    // `is_float`); `x is i32` holds for `2.0` (an integer, or a float equal to
    // its `trunc`), and inside the branch or the arm the value IS an `i32` —
    // `3.0` prints `number 3`. `==` / `!=` are exact between two typed
    // operands (decision B2: `2.0 == 2` is false) and by value when one is
    // `unknown`. D2 (§11): beam stores nothing extra for `unknown` or a union,
    // so no instruction is pinned for it.
    try h.assertBeamRunLog(std.testing.allocator,
        \\fn describe(x: unknown) -> string {
        \\    return case x {
        \\        i32 { n -> "number " + n.toString() }
        \\        string when (x == "") { "empty text" }
        \\        string { s -> "text " + s }
        \\        _ { "other" }
        \\    };
        \\}
        \\fn main() {
        \\    val a: unknown = 3.0;
        \\    @print(describe(a));
        \\    val b: unknown = 2.5;
        \\    @print(describe(b));
        \\    val e: unknown = "";
        \\    @print(describe(e));
        \\    val c: unknown = true;
        \\    @print(describe(c));
        \\    val d: unknown = 2.0;
        \\    @print(d is i32);
        \\    @print(d is f64);
        \\    val k: unknown = 2;
        \\    @print(k is f64);
        \\    @print(b is i32);
        \\    var got = 0;
        \\    if (d is i32) { got = d + 1; };
        \\    @print(got);
        \\    @print(d == 2);
        \\    @print(d != 2);
        \\    @print(2.0 == 2);
        \\    @print(2.0 != 2);
        \\}
    , "number 3\nother\nempty text\nother\ntrue\ntrue\ntrue\nfalse\n3\ntrue\nfalse\nfalse\ntrue\n", &.{ "{test, is_number, ", "{gc_bif, trunc, ", "{test, is_eq_exact, " });
}

// ── front 02-erlang step 5: a condition loop's value break (decision 8 §10) ──
//
// `break <value>` out of `while (cond)` was refused outright with an unlocated
// `ConditionLoopValueUnsupported`, on the bare `loop { … }` too — the parser
// gives both the same node. The loop now answers a pair, `{Group, Value}`, and
// a one-clause `case` destructures it: the group's variables are rebound and
// the case's value is the break's.

// ── decision 105 on commonJS: the annotated loop, `break v`, `for await`, `a...b`
//
// `iter loop { … }` is a `function*` IIFE whose body runs under
// `while (true)`: the captured `var` is the closure's, `yield v` is native,
// `break v` is `yield v; return;`, a bare `break` leaves the `while` and ends
// the generator. RUN LOGs, not snapshots: the other three backends record
// their own baselines in their own commits.
test "js: generator loop ---- a var captured by an annotated loop is its state" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    var n = 0;
        \\    val g = iter loop {
        \\        n = n + 1;
        \\        if (n == 4) { break n * 10; };
        \\        yield n * 10;
        \\    };
        \\    for (g) { x -> @print(x); };
        \\    @print(n);
        \\}
    , "10\n20\n30\n40\n4\n");
}

test "js: generator loop ---- break v inside a for ends the whole generator" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn firstOver(xs: i32[], limit: i32) -> @Iterator<i32> {
        \\    for (xs) { x ->
        \\        if (x > limit) { break x; };
        \\        yield 0;
        \\    };
        \\}
        \\fn main() {
        \\    for (firstOver([1, 5, 9, 12], 4)) { v -> @print(v); };
        \\}
    , "0\n5\n");
}

test "js: generator loop ---- a futureGenerator loop awaits inside and for await consumes it" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn fetch(n: i32) -> @Task<i32> { return n * 2; }
        \\type Ticker(gen: @Stream<i32>)
        \\fn ticks(limit: i32) -> Ticker {
        \\    var i = 0;
        \\    val gen = stream loop {
        \\        i = i + 1;
        \\        if (i > limit) { break; };
        \\        val v = await fetch(i);
        \\        yield v;
        \\    };
        \\    return Ticker(gen: gen);
        \\}
        \\fn total(limit: i32) -> @Task<i32> {
        \\    var sum = 0;
        \\    for await (ticks(limit).gen) { v -> sum = sum + v; };
        \\    @print(sum);
        \\    return sum;
        \\}
        \\fn main() { total(3); }
    , "12\n");
}

test "js: range ---- a...b includes its end" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    for (1..4) { i -> @print(i); };
        \\    for (1...4) { i -> @print(i); };
        \\}
    , "1\n2\n3\n1\n2\n3\n4\n");
}

// ── front 02-erlang step 5, re-specified by decision 105 ─────────────────────
//
// A condition loop is a statement: the variables its body reassigns travel
// through the loop fun as its group and come back — the answer a search finds
// is one of them, set before a bare `break`.

test "erlang: loop ---- a condition loop's answer comes back in the var it reassigned" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  var i = 0;
        \\  var found = 0;
        \\  while (i < 10) { if (i == 4) { found = i * 2; break; }; i = i + 1; };
        \\  @print(found);
        \\  @print(i);
        \\}
    , "8\n4\n", &.{});
}

test "erlang: loop ---- a bare loop's answer comes back in the var it reassigned" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn main() {
        \\  var k = 0;
        \\  var r = 0;
        \\  loop { k = k + 1; if (k > 2) { r = k; break; }; };
        \\  @print(r);
        \\  @print(k);
        \\}
    , "3\n3\n", &.{});
}

// ── front 02-erlang step 6: the generator protocol over a condition loop ─────
//
// `yield <v>` inside a condition loop lowered to the bare value expression,
// which an erlang clause body discards — so `fn nums` answered
// its loop's final counter and the consuming `lists:foldl/3` raised
// `no case clause matching 3` at run time. Decision 105 moved the collection
// from the loop to the generator scope: the fn's items are pushed under a
// `make_ref()` key from wherever the `yield` sits, and the fn answers
// `lists:reverse(erlang:erase(Key))`.

test "erlang: generator ---- a condition-loop body yields its elements in order" {
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn nums(n: i32) -> @Iterator<i32> {
        \\  var i = 0;
        \\  while (i < n) { yield i; i = i + 1; };
        \\}
        \\fn main() {
        \\  var acc = "";
        \\  for (nums(3)) { x -> acc = acc + x.toString(); };
        \\  @print(acc);
        \\  var runs = 0;
        \\  for (nums(0)) { x -> runs = runs + 1; };
        \\  @print(runs);
        \\}
    , "012\n0\n", &.{"lists:reverse(erlang:erase(__BpGen1))"});
}

test "erlang: generator ---- a bare-yield body still lowers to an eager list" {
    // `isPlainYieldGenerator`'s path, untouched by the collecting loop.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn two() -> @Iterator<i32> { yield 1; yield 2; }
        \\fn main() {
        \\  var a = "";
        \\  for (two()) { x -> a = a + x.toString(); };
        \\  @print(a);
        \\}
    , "12\n", &.{});
}

// 04-js — a lambda's single-expression body is a RETURN position, so every form
// `buildExpr` gives a value to is returned there. `isImplicitReturnExpr` listed
// only the always-a-value categories, so an `if`, a `loop` and a `try`/`catch`
// tail fell through to `buildStmt` and were emitted as statements: the value
// IIFE was written as `(x) => { (() => { … })(); }` and the arrow answered
// `undefined` for every element. Measured by emilia's theme front, on `if`; the
// other three rows are the same defect found while scoping it. `case` never had
// it (it is a `.collection`) and is the control in the language cell.
//
// The loop rows this cell used to carry left with decision 105: a loop is a
// statement, not a value a lambda's tail could answer.
//
// A RUN LOG plus the shapes, not a snapshot: the erlang, beam and wasm baselines
// of this program are not this front's to record. The language cell
// `tests/language/run/lambda_expression_body.bp` pins the same values on the
// other backends.
test "js: lambda ---- an expression body is the lambda's value" {
    const src =
        \\fn tenth(x: i32) -> @Result<i32, string> {
        \\    if (x > 1) { return x * 10; } else { throw "too small"; }
        \\}
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    @print(xs.map({ x -> if (x > 1) { x * 10 } else { x } }).join(","));
        \\    @print(xs.map({ x -> try tenth(x) catch 0 }).join(","));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "return (() => { if ((x > 1)) { return (x * 10); } else { return x; } })();",
        "return \"error\" in _try0 ? (0) : _try0.ok;",
    });
    try h.assertJsRunLog(std.testing.allocator, src,
        \\1,20,30
        \\0,20,30
        \\
    );
}

// The other half of the same rule: a lambda tail that JUMPS is still a
// statement, because a `return` cannot cross the IIFE the value form wraps it
// in. `exprJumps` is the guard, and this cell is what a wrong widening breaks.
test "js: lambda ---- a tail if whose branches return stays a statement" {
    const src =
        \\fn pick(xs: i32[]) -> i32[] {
        \\    return xs.map({ x -> if (x > 1) { return x * 10; } else { return 0; } });
        \\}
        \\fn main() {
        \\    @print(pick([1, 2, 3]).join(","));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "if ((x > 1)) { return (x * 10); } else { return 0; }",
    });
    try h.assertJsRunLog(std.testing.allocator, src, "0,20,30\n");
}

// ── self tail calls (1.0.10-beta `00 · 04-js` D6) ────────────────────────────
//
// V8 has no tail-call elimination, so `return f(…)` inside `f` cost a stack
// frame and a few thousand rounds killed the program — while erlang and beam,
// whose VMs drop the frame, ran the same source to the end. `std`'s
// `random.intInRange` is what found it. The whole-program behaviour is pinned
// by `tests/language/run/self_tail_recursion.bp` on every target; these three
// cells pin the JS SHAPE, which only this backend has, and each one RUNS.

// A `return <self>(…)` becomes "give the parameters their next values and go
// round again". The temporaries matter: `acc + n` still has to read the OLD
// `n`, and the assignments happen in order.
test "js: self tail call ---- a tail call is a round of a loop, not a frame" {
    const src =
        \\fn sumDown(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) return acc;
        \\    return sumDown(n - 1, acc + n);
        \\}
        \\fn main() {
        \\    @print(sumDown(20000, 0));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "    while (true) {",
        "const __bp_tc0 = (n - 1);",
        "const __bp_tc1 = (acc + n);",
        "n = __bp_tc0;",
        "acc = __bp_tc1;",
        "continue;",
    });
    // 20 000 rounds: `RangeError: Maximum call stack size exceeded` before.
    try h.assertJsRunLog(std.testing.allocator, src, "200010000\n");
}

// A tail call inside a loop of the function's OWN needs a labelled continue —
// a bare `continue` would go round that inner loop instead, and the function
// would never move on.
test "js: self tail call ---- one inside the function's own loop is labelled" {
    const src =
        \\fn firstUnder(n: i32, limit: i32) -> i32 {
        \\    for (0..3) { k ->
        \\        if (n + k > limit) { return firstUnder(n - 1, limit); };
        \\    };
        \\    return n;
        \\}
        \\fn main() {
        \\    @print(firstUnder(9000, 10));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "__bp_tc: while (true) {",
        "continue __bp_tc;",
    });
    try h.assertJsRunLog(std.testing.allocator, src, "8\n");
}

// The limit, stated as a test: a closure in the body that READS a parameter
// outlives the round that made it, so reassigning the parameter would change
// what that closure sees. The function keeps its recursion, and the cell is
// shallow on purpose.
test "js: self tail call ---- a closure over a parameter keeps the recursion" {
    const src =
        \\fn tally(n: i32, acc: i32) -> i32 {
        \\    if (n == 0) return acc;
        \\    val xs = [1, 2].map({ x -> x * n });
        \\    return tally(n - 1, acc + xs.length());
        \\}
        \\fn main() {
        \\    @print(tally(3, 0));
        \\}
    ;
    try h.assertJsContains(std.testing.allocator, src, &.{
        "return tally((n - 1), (acc + xs.length));",
    });
    try h.assertJsRunLog(std.testing.allocator, src, "6\n");
}

// ── front 02-erlang step 2: decision 8 at run time, by value ──────────────────

test "erlang: unknown ---- `is`, type arms and `==` answer by value" {
    // D1 (§4.1): `2.0 is i32` holds and `2.5 is i32` does not; an integer arm
    // and `if (a is i32)` bind the converted `2` (`trunc`), a float arm the
    // `float`. D2 (§11): a value entering `unknown` is stored as itself —
    // `A = 2.0`, no box. D3 (§2.3): with an `unknown` operand `==` / `!=` are
    // erlang's by-value `==` / `/=`; two typed operands keep `=:=`.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn show(x: unknown) {
        \\  case x { i32 { n -> @print(n) } f64 { f -> @print(f) } _ { @print("other") } };
        \\}
        \\fn main() {
        \\  val a: unknown = 2.0;
        \\  val c: unknown = 2.5;
        \\  @print(a == 2, a != 2, c == 2);
        \\  val i: i32 = 2;
        \\  val j: i32 = 2;
        \\  @print(i == j);
        \\  if (a is i32) { @print(a + 1); };
        \\  @print(a is i32, a is f64, c is i32, c is f64);
        \\  show(a);
        \\  show(c);
        \\  show("s");
        \\}
    , "true false false\ntrue\n3\ntrue true false true\n2\n2.5\nother\n", &.{
        "    A = 2.0,",
        "(A == 2), (A /= 2), (C == 2)",
        "(I =:= J)",
        "N = trunc(I32)",
        "F = float(F64)",
        "A@1 = trunc(A)",
    });
}

test "erlang: case ---- `A...B` matches both bounds, through guards" {
    // Front 02 step 3 (C-06, decision 53). Lowered through the variant path the
    // range was `{'', 1, 9}`, which no value is, so every probe fell to `_`. It
    // is now a fresh variable guarded by both bounds — in an arm with a binder
    // and inside a tuple pattern too.
    try h.assertErlangRunLog(std.testing.allocator,
        \\fn grade(n: i32) -> string {
        \\  return case n { 1...9 { d -> "digit " + d.toString() } 10...99 { "two" } _ { "other" } };
        \\}
        \\fn main() {
        \\  @print(grade(0), grade(1), grade(9), grade(10), grade(99), grade(100));
        \\  val t = #(5, "x");
        \\  case t { #(1...3, _) { @print("low") } #(4...6, s) { @print("mid " + s) } _ { @print("hi") } };
        \\}
    , "other digit 1 digit 9 two two other\nmid x\n", &.{
        "D = _Rng0 when (_Rng0 >= 1), (_Rng0 =< 9) ->",
        "{_Rng1, S} when (_Rng1 >= 4), (_Rng1 =< 6) ->",
    });
}
