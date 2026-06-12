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
    );
}

test "js: if ---- simple conditional in fn body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    @print(r);
        \\    return r;
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
        \\*fn fetch() -> @Result<i32, string> {
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
        \\*fn fetch() -> @Result<i32, string> {
        \\    @todo();
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    @print(r);
        \\    return r;
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
        \\val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
        \\loop (messages, 0..) { msg, i ->
        \\    @print(msg);
        \\};
    );
}

test "js: loop ---- side-effect over range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\loop (0..10) { i ->
        \\    @print(i);
        \\};
    );
}

test "js: loop ---- map with break (add tax)" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val precosBrutos = [100, 250, 400];
        \\val precosComTaxa = loop (precosBrutos) { valor ->
        \\    val taxa = valor * 0.15;
        \\    break valor + taxa;
        \\};
        \\@print(precosComTaxa);
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
        \\@print(apenasGrandes);
    );
}

test "js: loop ---- map with break simple" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val ids = [10, 20, 30];
        \\val dobrados = loop (ids) { id ->
        \\    break id * 2;
        \\};
        \\@print(dobrados);
    );
}

test "js: loop ---- even numbers with break" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val processamento = loop (0..10) { i ->
        \\    if (i % 2 == 0) {
        \\        break i;
        \\    };
        \\};
        \\@print(processamento);
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

test "js: loop ---- break with value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32 {
        \\    return loop (arr) { x ->
        \\        if (x > 10) { break x; };
        \\    };
        \\}
        \\fn main() {
        \\    @print(find([5, 8, 15, 20]));
        \\}
    );
}

test "js: loop ---- continue in iteration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumEvens(arr: i32[]) -> i32 {
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
        \\record ApiError { msg: string }
        \\*fn fetch() -> @Result<i32, ApiError> {
        \\    throw ApiError(msg: "not found");
        \\}
        \\*fn strict() -> @Result<i32, string> {
        \\    val r = try fetch() catch throw "fetch failed";
        \\    return r;
        \\}
    );
}

test "js: try ---- catch with return fallback" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record NetError { code: i32 }
        \\*fn fetch() -> @Result<i32, NetError> {
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
        \\record DbError { msg: string }
        \\*fn inner() -> @Result<i32, DbError> {
        \\    throw DbError(msg: "conn refused");
        \\}
        \\*fn outer() -> @Result<i32, DbError> {
        \\    throw DbError(msg: "timeout");
        \\}
        \\fn process() -> i32 {
        \\    val a = try inner() catch 0;
        \\    val b = try outer() catch a;
        \\    @print(a, b);
        \\    return a + b;
        \\}
    );
}

test "js: try ---- catch tail on method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record ParseError { msg: string }
        \\val Parser = struct {
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

test "js: throw ---- record constructor" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record AppError { code: i32, msg: string }
        \\fn validate(x: i32) {
        \\    if (x < 0) {
        \\        throw AppError(code: 400, msg: "negative");
        \\    };
        \\}
    );
}

test "js: try ---- propagate in multi-statement fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record IoError { path: string }
        \\*fn step1() -> @Result<i32, IoError> {
        \\    throw IoError(path: "/data");
        \\}
        \\*fn step2(x: i32) -> @Result<i32, IoError> {
        \\    throw IoError(path: "/out");
        \\}
        \\*fn pipeline() -> @Result<i32, IoError> {
        \\    val a = try step1();
        \\    val b = try step2(a);
        \\    return b;
        \\}
    );
}

test "js: try ---- catch with lambda handler" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record FetchError { url: string }
        \\*fn fetch() -> @Result<i32, FetchError> {
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
        \\record CalcError { msg: string }
        \\*fn getA() -> @Result<i32, CalcError> {
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
        \\val ErrorKind = enum { NotFound, Timeout }
        \\*fn fetch() -> @Result<i32, ErrorKind> {
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
        \\val Status = enum { Ok, Fail }
        \\fn check(s: Status) -> i32 {
        \\    return case s {
        \\        Status.Ok -> 1;
        \\        Status.Fail -> throw "failed";
        \\    };
        \\}
    );
}

test "js: try ---- catch preserves surrounding bindings" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record LoadError { msg: string }
        \\*fn load() -> @Result<i32, LoadError> {
        \\    throw LoadError(msg: "not found");
        \\}
        \\fn process() -> i32 {
        \\    val prefix = 10;
        \\    val data = try load() catch 0;
        \\    val suffix = 20;
        \\    @print(prefix, data, suffix);
        \\    return prefix + data + suffix;
        \\}
    );
}

test "js: throw ---- inside loop body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn validate(items: i32) {
        \\    val i = 0;
        \\    loop {
        \\        if (i > items) { throw "too many"; };
        \\        break;
        \\    };
        \\}
    );
}

test "js: try ---- multiple catch with different fallbacks" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record UserError { msg: string }
        \\*fn fetchName() -> @Result<string, UserError> {
        \\    throw UserError(msg: "name missing");
        \\}
        \\*fn fetchAge() -> @Result<i32, UserError> {
        \\    throw UserError(msg: "age missing");
        \\}
        \\fn loadUser() {
        \\    val name = try fetchName() catch "anonymous";
        \\    val age = try fetchAge() catch 0;
        \\    @print(name, age);
        \\}
    );
}

test "js: catch ---- tail on function call no try" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record RiskError { level: i32 }
        \\*fn risky() -> @Result<i32, RiskError> {
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
        \\val Shape = enum {
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
        \\val Shape = enum {
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
