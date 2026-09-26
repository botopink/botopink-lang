//! Parser-level effect rejections — decisions 118 and 127 of 1.0.10-beta:
//! the return type is the effect, so the six effect annotations and the
//! removed wrappers are recognised only to be refused, each with a fix-it
//! located on what was written.
//!   `effect-annotation-removed`     — `#[@result]` … `#[@futureGenerator]`
//!                                     (on a loop: the `iter` / `stream` fix-it)
//!   `effect-type-removed`           — `@Future`, `@Generator`, `@ResultGenerator`,
//!                                     `@FutureGenerator`, `@Use`
//!   `iterator-error-param-removed`  — `@Iterator<T, E>`
//! Plus the contextual words `iter` / `stream` (decision 125).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const ParseErrorType = parserMod.ParseErrorType;
const ParseErrorInfo = parserMod.ParseErrorInfo;
const expectErrorAt = @import("helpers.zig").expectErrorAt;

fn expectKind(src: []const u8, kind: ParseErrorType) !void {
    const alloc = std.testing.allocator;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, src);
    if (p.parse(alloc)) |*prog| {
        var owned = prog.*;
        owned.deinit(alloc);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parseError orelse return error.TestExpectedParseErrorInfo;
        try std.testing.expectEqual(kind, pe.kind);
    }
}

/// The refusal's kind AND where its caret lands (1-based line / column).
fn expectKindAt(src: []const u8, kind: ParseErrorType, line: usize, col: usize) !void {
    const alloc = std.testing.allocator;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);
    var p = Parser.initWithSource(tokens, src);
    if (p.parse(alloc)) |*prog| {
        var owned = prog.*;
        owned.deinit(alloc);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parseError orelse return error.TestExpectedParseErrorInfo;
        try std.testing.expectEqual(kind, pe.kind);
        try std.testing.expectEqual(line, pe.line);
        try std.testing.expectEqual(col, pe.col);
    }
}

fn expectParses(src: []const u8) !void {
    const alloc = std.testing.allocator;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);
    var p = Parser.initWithSource(tokens, src);
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "effect-annotation-removed — each of the six, located on the name" {
    inline for (.{ "result", "future", "use", "generator", "resultGenerator", "futureGenerator" }) |name| {
        try expectKindAt("#[@" ++ name ++ "]\nfn f() -> i32 { return 0; }", .effectAnnotationRemoved, 1, 3);
    }
}

test "effect-annotation-removed — on a declare fn, a behavior method and a type method" {
    try expectKind(
        \\#[@future]
        \\#[@External.Node("fetch($0)")]
        \\pub declare fn fetch(url: string) -> @Task<i32>;
    , .effectAnnotationRemoved);
    try expectKind(
        \\val AsyncSource = behavior {
        \\    #[@future]
        \\    fn next(self: Self) -> @Task<i32>;
        \\}
    , .effectAnnotationRemoved);
    try expectKind(
        \\type Box(n: i32) {
        \\    #[@generator]
        \\    fn each(self: Self) -> @Iterator<i32> { yield self.n; }
        \\}
    , .effectAnnotationRemoved);
}

test "effect-annotation-removed — in a list with another annotation" {
    try expectKind(
        \\#[@External.Node("x"), @result]
        \\declare fn f() -> @Result<i32, string>;
    , .effectAnnotationRemoved);
}

test "effect-annotation-removed — before a loop the fix-it is `iter` / `stream`" {
    try expectKindAt(
        \\fn f() {
        \\    val xs = #[@generator] loop { yield 1; break; };
        \\}
    , .effectAnnotationRemovedLoop, 2, 16);
    try expectKind(
        \\fn f() {
        \\    val xs = #[@futureGenerator] loop { yield 1; break; };
        \\}
    , .effectAnnotationRemovedLoop);
    try expectKind(
        \\fn f(xs: i32[]) {
        \\    val ys = #[@resultGenerator] for (xs) { x -> yield x; };
        \\}
    , .effectAnnotationRemovedLoop);
}

test "effect-type-removed — each removed wrapper, located on the name" {
    try expectKindAt("fn f() -> @Future<i32, string> { return 0; }", .effectTypeRemovedFuture, 1, 11);
    try expectKindAt("fn f() -> @Generator<i32> { yield 0; }", .effectTypeRemovedGenerator, 1, 11);
    try expectKindAt("fn f() -> @ResultGenerator<i32, string> { yield 0; }", .effectTypeRemovedResultGenerator, 1, 11);
    try expectKindAt("fn f() -> @FutureGenerator<i32, string> { yield 0; }", .effectTypeRemovedFutureGenerator, 1, 11);
    try expectKindAt("fn f() -> @Use<Base, i32> { return 0; }", .effectTypeRemovedUse, 1, 11);
}

test "effect-type-removed — in a parameter and inside another type" {
    try expectKind("fn f(t: @Future<i32>) -> i32 { return 0; }", .effectTypeRemovedFuture);
    try expectKind("fn f() -> Array<@Generator<i32>> { return []; }", .effectTypeRemovedGenerator);
}

test "iterator-error-param-removed — located on the error argument" {
    try expectKindAt("fn f() -> @Iterator<i32, string> { yield 0; }", .iteratorErrorParamRemoved, 1, 26);
}

test "the new surface parses — the five wrappers with no annotation" {
    try expectParses(
        \\fn a() -> @Result<i32, string> { return 1; }
        \\fn b() -> @Task<@Result<i32, string>> { return 1; }
        \\fn c() -> @Component<Base, i32> { return 1; }
        \\fn d() -> @Iterator<@Result<i32, string>> { yield 1; }
        \\fn e() -> @Stream<i32> { yield 1; }
    );
}

test "the return is the effect — FnDecl.effect, and a factory has none" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src =
        \\fn a() -> @Task<i32> { return 0; }
        \\fn b() -> @Iterator<i32> { yield 0; }
        \\fn c(xs: i32[]) -> @Iterator<i32> { return iter for (xs) { x -> yield x; }; }
        \\fn d() -> @Component<Base, i32> { return 0; }
        \\fn e() -> i32 { return 0; }
    ;
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    const program = try p.parse(alloc);
    try std.testing.expectEqual(ast.EffectKind.task, program.decls[0].@"fn".effect.?);
    try std.testing.expectEqual(ast.EffectKind.iterator, program.decls[1].@"fn".effect.?);
    try std.testing.expect(program.decls[2].@"fn".effect == null);
    try std.testing.expectEqual(ast.EffectKind.component, program.decls[3].@"fn".effect.?);
    try std.testing.expect(program.decls[4].@"fn".effect == null);
}

test "`iter` / `stream` prefix the three loops, as a value and as an argument" {
    try expectParses(
        \\fn f(xs: i32[]) {
        \\    val a = iter loop { yield 1; break 2; };
        \\    val b = iter while (true) { yield 1; break; };
        \\    val c = iter for (xs) { x -> yield x * 2; };
        \\    val d = stream loop { yield 1; break; };
        \\    val e = stream for (xs) { x -> yield x; };
        \\    g(iter for (xs) { x -> yield x; });
        \\}
    );
}

test "`iter` / `stream` / `try await` — contextual words stay identifiers" {
    try expectParses(
        \\fn f(g: Grid, http: Http) -> @Task<@Result<i32, string>> {
        \\    val it = g.iter();
        \\    val stream = 1;
        \\    val iter = 2;
        \\    val s = http.stream("x");
        \\    val n = try await g.load();
        \\    return stream + iter;
        \\}
    );
}

test "`try await x` is `try (await x)`" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src = "fn f() -> @Task<@Result<i32, string>> { val n = try await g(); return n; }";
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    const program = try p.parse(alloc);
    const bind = program.decls[0].@"fn".body[0].expr.binding.kind.localBind;
    try std.testing.expect(bind.value.* == .jump);
    const inner = bind.value.jump.kind.try_.?;
    try std.testing.expect(inner.* == .jump);
    try std.testing.expect(inner.jump.kind == .await_);
}

// ── decision 137: `try` / `await` begin an expression, never an operand ──────
//
// Every position where an expression begins takes the prefix form, which reads
// the whole expression after the keyword; an operand position (under a binary
// operator, a unary prefix, a group or a chain) refuses it at the keyword.

test "decision 137: `try` / `await` parse wherever an expression begins" {
    try expectParses(
        \\fn f(xs: i32[]) -> @Task<@Result<i32, string>> {
        \\    try g();
        \\    val a = try g();
        \\    var b = try await h();
        \\    b = try g();
        \\    p.x = try g();
        \\    k(try g(), await h());
        \\    val arr = [try g(), await h()];
        \\    val tup = #(try g(), 1);
        \\    val rec = P(x: try g());
        \\    if (try ok()) { b = 1; }
        \\    while (await more()) { b = 2; }
        \\    case try g() { 0 { b = 3; } _ { b = 4; } }
        \\    for (try items()) { x -> b = x; }
        \\    val c = try g() catch 0;
        \\    k(try g() catch 0);
        \\    return try g();
        \\}
        \\fn it() -> @Iterator<@Result<i32, string>> { yield try g(); }
    );
}

test "decision 137: `try` takes the whole expression after it" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src = "fn f() -> @Result<i32, string> { val n = try a + b; return n; }";
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    const program = try p.parse(alloc);
    const bind = program.decls[0].@"fn".body[0].expr.binding.kind.localBind;
    const inner = bind.value.jump.kind.try_.?;
    try std.testing.expect(inner.* == .binaryOp);
}

test "decision 137: `try` / `await` as an operand is `try-await-operand`, at the keyword" {
    try expectErrorAt("fn f() -> @Result<i32, string> { return t + try r(); }", .tryAwaitOperand, 1, 45);
    try expectErrorAt("fn f() -> @Result<i32, string> { val x = -try r(); return x; }", .tryAwaitOperand, 1, 43);
    try expectErrorAt("fn f() -> @Result<i32, string> { return (try r()).length; }", .tryAwaitOperand, 1, 42);
    try expectErrorAt("fn f() -> @Result<i32, string> { return (try r() catch 0) == 1; }", .tryAwaitOperand, 1, 42);
    try expectErrorAt("fn f() -> @Task<bool> { return !await r(); }", .tryAwaitOperand, 1, 33);
    try expectErrorAt("fn f() -> @Task<i32> { return x ?? await r(); }", .tryAwaitOperand, 1, 36);
    try expectErrorAt("fn f() -> @Task<bool> { if (a && await r()) { return true; } return false; }", .tryAwaitOperand, 1, 34);
    try expectErrorAt("fn f() -> @Task<i32> { return xs[try r()]; }", .tryAwaitOperand, 1, 34);
}

test "RI6 — legacy `yield break <expr>` is rejected at parse" {
    try expectKind(
        \\fn it() -> @Iterator<@Result<i32, string>> {
        \\    yield break 0;
        \\}
    , .yieldBreakRemoved);
}

test "RI6 — bare `yield break` is also rejected" {
    try expectKind(
        \\fn g() -> @Iterator<i32> {
        \\    yield break;
        \\}
    , .yieldBreakRemoved);
}

test "RG1 — record with default before required is rejected" {
    try expectKind(
        \\type Container<T = i32, U>(item: T)
    , .genericDefaultBeforeRequired);
}

test "RG1 — fn with default before required is rejected" {
    try expectKind(
        \\fn pair<A = i32, B>(a: A, b: B) -> B { return b; }
    , .genericDefaultBeforeRequired);
}

test "RG1 — defaulted trailing parameters are accepted" {
    const alloc = std.testing.allocator;
    var l = Lexer.init(
        \\fn pair<T, U = string>(a: T, b: U) -> U { return b; }
    );
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "RG1 — every parameter defaulted is accepted" {
    const alloc = std.testing.allocator;
    var l = Lexer.init(
        \\fn triple<T = i32, U = string, V = bool>(a: T, b: U, c: V) -> V { return c; }
    );
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "RG4 — `@Result<i32, , i64>` rejected at parse" {
    try expectKind(
        \\fn middle() -> @Result<i32, , i64> { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — trailing `,>` is also a skipped slot" {
    try expectKind(
        \\fn trail() -> @Result<i32, > { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — user-defined generic skip is rejected" {
    try expectKind(
        \\fn p() -> Container<i32, , bool> { return 0; }
    , .genericArgSkipForbidden);
}
