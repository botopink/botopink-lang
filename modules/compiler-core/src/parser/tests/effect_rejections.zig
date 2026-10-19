//! Parser-level effect rejections — decisions 118 and 127 of 1.0.10-beta:
//! the return type is the effect, so the six effect annotations and the
//! removed wrappers are recognised only to be refused, each with a fix-it
//! located on what was written.
//!   `effect-annotation-removed`     — `#[@result]` … `#[@futureGenerator]`
//!                                     (on a loop: the `iter` / `stream` fix-it)
//!   `effect-type-removed`           — `@Future`, `@Generator`, `@ResultGenerator`,
//!                                     `@FutureGenerator`, `@Use`
//!   `iterator-error-param-removed`  — `@Iterator<T, E>`
//! Plus the contextual words `iter` / `stream` (decision 125), and the body
//! markers of decision 553 — `async`, `iter`, `async iter`, `component` before
//! `fn` and before a lambda's brace:
//!   `marker-type-mismatch`   — a marker whose return type is not its wrapper
//!   `marker-without-arrow`   — `iter { … }` / `component { … }` with no `->`
//!   `marker-on-declaration`  — a marker on a bodyless declaration

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
        \\#[compiler.external(.JavaScript("fetch($0)"))]
        \\pub declare fn fetch(url: string) -> Task<i32>;
        \\
        \\import {compiler} from "std";
    , .effectAnnotationRemoved);
    try expectKind(
        \\val AsyncSource = behavior {
        \\    #[@future]
        \\    fn next(self: Self) -> Task<i32>;
        \\}
    , .effectAnnotationRemoved);
    try expectKind(
        \\type Box(n: i32) {
        \\    #[@generator]
        \\    fn each(self: Self) -> Iterator<i32> { yield self.n; }
        \\}
    , .effectAnnotationRemoved);
}

test "effect-annotation-removed — in a list with another annotation" {
    try expectKind(
        \\#[@result]
        \\#[compiler.external(.JavaScript("x"))]
        \\declare fn f() -> Result<i32, string>;
        \\
        \\import {compiler} from "std";
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

test "decision 354 — `@Context`, `@Component<C, R>` and `@Renderable<…>` refused, located" {
    try expectKindAt("type E() implement @Context<E>", .contextMarkerRemoved, 1, 20);
    try expectKindAt("fn f() -> @Component<Base, i32> { return 0; }", .componentBaseParamRemoved, 1, 22);
    try expectKindAt("type E() implement @Renderable<E>", .renderableTakesNoTypeArguments, 1, 31);
    try expectKind("fn f(g: fn() -> @Component<Base, i32>) -> i32 { return 0; }", .componentBaseParamRemoved);
}

test "iterator-error-param-removed — located on the error argument" {
    try expectKindAt("fn f() -> @Iterator<i32, string> { yield 0; }", .iteratorErrorParamRemoved, 1, 26);
}

test "the new surface parses — the five wrappers with no annotation" {
    try expectParses(
        \\fn a() -> Result<i32, string> { return 1; }
        \\fn b() -> Task<Result<i32, string>> { return 1; }
        \\fn c() -> Component<i32> { return 1; }
        \\fn d() -> Iterator<Result<i32, string>> { yield 1; }
        \\fn e() -> Stream<i32> { yield 1; }
    );
}

test "the return is the effect — FnDecl.effect, and a factory has none" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src =
        \\fn a() -> Task<i32> { return 0; }
        \\fn b() -> Iterator<i32> { yield 0; }
        \\fn c(xs: i32[]) -> Iterator<i32> { return iter for (xs) { x -> yield x; }; }
        \\fn d() -> Component<i32> { return 0; }
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
        \\fn f(g: Grid, http: Http) -> Task<Result<i32, string>> {
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
        \\fn f(xs: i32[]) -> Task<Result<i32, string>> {
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
        \\fn it() -> Iterator<Result<i32, string>> { yield try g(); }
    );
}

/// The first statement of `fn f() { <stmt> }` parsed; `check` reads it.
fn firstStmt(alloc: std.mem.Allocator, stmt: []const u8) !ast.Expr {
    const src = try std.fmt.allocPrint(alloc, "fn f() -> @Result<i32, string> {{ {s} }}", .{stmt});
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    const program = try p.parse(alloc);
    return program.decls[0].@"fn".body[0].expr;
}

fn bindValue(e: ast.Expr) ast.Expr {
    return e.binding.kind.localBind.value.*;
}

test "decision 537: `try` and `await` are prefix operators binding as the unary `-` does" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    // `try a + b` is `(try a) + b`.
    const sum = bindValue(try firstStmt(alloc, "val n = try a() + b;"));
    try std.testing.expect(sum == .binaryOp);
    try std.testing.expect(sum.binaryOp.lhs.* == .jump);
    try std.testing.expect(sum.binaryOp.lhs.jump.kind == .try_);
    // `await t * 2` is `(await t) * 2`; `await x + await y` is a sum of two awaits.
    const prod = bindValue(try firstStmt(alloc, "val n = await t * 2;"));
    try std.testing.expect(prod == .binaryOp);
    try std.testing.expect(prod.binaryOp.lhs.jump.kind == .await_);
    const two = bindValue(try firstStmt(alloc, "val n = await x + await y;"));
    try std.testing.expect(two.binaryOp.lhs.jump.kind == .await_);
    try std.testing.expect(two.binaryOp.rhs.jump.kind == .await_);
    // Postfix binds tighter: `await t.x` is `await (t.x)`, `await f()` is `await (f())`.
    const member = bindValue(try firstStmt(alloc, "val n = await t.x;"));
    try std.testing.expect(member.jump.kind.await_.* == .identifier);
    const call = bindValue(try firstStmt(alloc, "val n = await f();"));
    try std.testing.expect(call.jump.kind.await_.* == .call);
    // `try await t` is `try (await t)`.
    const both = bindValue(try firstStmt(alloc, "val n = try await t;"));
    try std.testing.expect(both.jump.kind.try_.?.*.jump.kind == .await_);
}

test "decision 537: `catch` is infix with the lowest precedence" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    // `try await t catch 0 * 2` is `(try await t) catch (0 * 2)`.
    const fallback = bindValue(try firstStmt(alloc, "val n = try await t catch 0 * 2;"));
    try std.testing.expect(fallback.branch.kind == .tryCatch);
    try std.testing.expect(fallback.branch.kind.tryCatch.tryKeyword);
    try std.testing.expect(fallback.branch.kind.tryCatch.expr.jump.kind == .await_);
    try std.testing.expect(fallback.branch.kind.tryCatch.handler.* == .binaryOp);
    // `try await t + 1 catch 0` is `((try await t) + 1) catch 0`.
    const whole = bindValue(try firstStmt(alloc, "val n = try await t + 1 catch 0;"));
    try std.testing.expect(whole.branch.kind == .tryCatch);
    try std.testing.expect(whole.branch.kind.tryCatch.expr.* == .binaryOp);
    // Parentheses group: `(try await t catch 0) * 2` doubles the result.
    const grouped = bindValue(try firstStmt(alloc, "val n = (try await t catch 0) * 2;"));
    try std.testing.expect(grouped == .binaryOp);
    try std.testing.expect(grouped.binaryOp.lhs.* == .collection);
}

test "decision 537: `try` and `await` stand as an operand, no refusal remains" {
    try expectParses(
        \\fn f() -> Task<Result<i32, string>> {
        \\    val a = total + try r();
        \\    val b = -try r();
        \\    val c = (try r()).length;
        \\    val d = (try r() catch 0) == 1;
        \\    val e = !await r();
        \\    val g = x ?? await r();
        \\    if (a && await r()) { return 1; }
        \\    val h = xs[try r()];
        \\    return (try await t catch 0) * 2;
        \\}
    );
}

test "an `if` expression as an operand is `if-operand`, at the `if` (decision 137's reading)" {
    try expectErrorAt("fn f(c: bool) -> i32 { return 1 + if (c) { 2 } else { 3 }; }", .ifOperand, 1, 35);
    try expectErrorAt("fn f(c: bool) -> i32 { return -if (c) 1 else 2; }", .ifOperand, 1, 32);
    try expectErrorAt("fn f(c: bool) -> i32 { return (if (c) 1 else 2) + 1; }", .ifOperand, 1, 32);
    try expectErrorAt("fn f(c: bool) -> i32 { return x ?? if (c) 1 else 2; }", .ifOperand, 1, 36);
    try expectErrorAt("fn f(c: bool) -> i32 { return xs[if (c) 1 else 0]; }", .ifOperand, 1, 34);
}

test "an `if` expression stands where an expression begins" {
    try expectParses("fn f(c: bool) -> i32 { val x = if (c) 1 else 2; return x; }");
    try expectParses("fn f(c: bool) -> i32 { return if (c) 1 else 2; }");
    try expectParses("fn f(c: bool) -> i32 { return g(if (c) 1 else 2); }");
    try expectParses("fn f(c: bool) -> i32[] { return [if (c) 1 else 2, 3]; }");
}

test "RI6 — legacy `yield break <expr>` is rejected at parse" {
    try expectKind(
        \\fn it() -> Iterator<Result<i32, string>> {
        \\    yield break 0;
        \\}
    , .yieldBreakRemoved);
}

test "RI6 — bare `yield break` is also rejected" {
    try expectKind(
        \\fn g() -> Iterator<i32> {
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
        \\fn middle() -> Result<i32, , i64> { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — trailing `,>` is also a skipped slot" {
    try expectKind(
        \\fn trail() -> Result<i32, > { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — user-defined generic skip is rejected" {
    try expectKind(
        \\fn p() -> Container<i32, , bool> { return 0; }
    , .genericArgSkipForbidden);
}

test "decision 316 — `fn(..) -> R` is `@Decl<…>`'s pattern alone, refused anywhere else at the `..`" {
    try expectKindAt("fn f(g: fn(..) -> i32) -> i32 { return 0; }", .anyParamsOutsideDecl, 1, 12);
    try expectKind("fn d(syntax decl: fn(g: fn(..) -> i32) -> i32) {}", .anyParamsOutsideDecl);
    try expectKind("fn d(syntax decl: Box<fn(..) -> i32>) {}", .anyParamsOutsideDecl);

    const alloc = std.testing.allocator;
    const src = "fn d(syntax decl: fn(..) -> string) {}";
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);
    var p = Parser.initWithSource(tokens, src);
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    const pattern = prog.decls[0].@"fn".params[0].typeRef.generic.args[0];
    try std.testing.expect(pattern.function.anyParams);
    try std.testing.expectEqual(@as(usize, 0), pattern.function.params.len);
}

fn lambdaBody(e: ast.Expr) []ast.Stmt {
    return e.binding.kind.localBind.value.function.kind.body;
}

test "decision 541: a lambda's tail is its last expression written without `;`" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const bare = lambdaBody(try firstStmt(alloc, "val f = { x -> x + 1 };"));
    try std.testing.expect(bare[0].tail == .value);
    const semi = lambdaBody(try firstStmt(alloc, "val f = { x -> x + 1; };"));
    try std.testing.expect(semi[0].tail == .none);
    // A braced `if` at the end is the tail whatever follows it (decision 29 (c)).
    const braced = lambdaBody(try firstStmt(alloc, "val f = { x -> if (x > 1) { 1 } else { 2 } };"));
    try std.testing.expect(braced[0].tail == .value);
    // `await e` and `try e` are values, so a lambda may end in one.
    const awaited = lambdaBody(try firstStmt(alloc, "val f = { x -> await g(x) };"));
    try std.testing.expect(awaited[0].tail == .value);
}

test "decision 541: a block ending a function body is its tail" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const src = "fn f() -> i32 { { 41 + 1 } }";
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    const program = try p.parse(alloc);
    const body = program.decls[0].@"fn".body;
    // The tail is wrapped in the `return` the written `-> i32` asks for.
    try std.testing.expect(body[0].tail == .returned);
    try std.testing.expect(body[0].expr.jump.kind.@"return".?.* == .collection);
}

// ── decision 553 — the body markers ──────────────────────────────────────────

fn parseOk(alloc: std.mem.Allocator, src: []const u8) !ast.Program {
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.initWithSource(tokens, src);
    return p.parse(alloc);
}

test "decision 553: a marker before `fn` on a declaration sets the marker and the effect" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const prog = try parseOk(alloc,
        \\async fn a() -> Task<i32> { return 1; }
        \\iter fn b() -> Iterator<i32> { yield 1; }
        \\async iter fn c() -> Stream<i32> { yield 1; }
        \\component fn D() -> Component<i32> { return 1; }
        \\pub async fn e() -> Task<i32> { return 1; }
        \\pub default async fn f() -> Task<i32> { return 1; }
        \\iter fn g() -> Iterator<i32> { return [1].iter(); }
    );
    const want = [_]ast.EffectKind{ .task, .iterator, .stream, .component, .task, .task, .iterator };
    for (want, 0..) |k, i| {
        const f = prog.decls[i].@"fn";
        try std.testing.expectEqual(@as(?ast.EffectKind, k), f.marker);
        try std.testing.expectEqual(@as(?ast.EffectKind, k), f.effect);
    }
    try std.testing.expect(prog.decls[4].@"fn".isPub);
    try std.testing.expect(prog.decls[5].@"fn".isDefault);
    try std.testing.expectEqual(@as(usize, 1), prog.decls[2].@"fn".markerLoc.col);
}

test "decision 553: an unmarked body keeps today's effect" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const prog = try parseOk(alloc,
        \\fn b() -> Iterator<i32> { yield 1; }
        \\fn g() -> Iterator<i32> { return [1].iter(); }
    );
    try std.testing.expectEqual(@as(?ast.EffectKind, null), prog.decls[0].@"fn".marker);
    try std.testing.expectEqual(@as(?ast.EffectKind, .iterator), prog.decls[0].@"fn".effect);
    // A body that does not yield is a factory (decision 123).
    try std.testing.expectEqual(@as(?ast.EffectKind, null), prog.decls[1].@"fn".effect);
}

test "decision 553: markers on a type's method, a behavior's default and an implement's method" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const prog = try parseOk(alloc,
        \\type Grid(cells: i32[]) {
        \\    iter fn each(self: Self) -> Iterator<i32> { yield 1; }
        \\    pub async fn total(self: Self) -> Task<i32> { return 1; }
        \\}
        \\behavior Source {
        \\    fn base(self: Self) -> i32;
        \\    default async fn scaled(self: Self) -> Task<i32> { return 1; }
        \\}
        \\Loud implement Speak for Grid {
        \\    async fn say(self: Self) { }
        \\}
    );
    const t = prog.decls[0].type_;
    try std.testing.expectEqual(@as(?ast.EffectKind, .iterator), t.methods[0].marker);
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), t.methods[1].marker);
    try std.testing.expect(t.methods[1].isPub);
    const b = prog.decls[1].behavior;
    try std.testing.expectEqual(@as(?ast.EffectKind, null), b.methods[0].marker);
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), b.methods[1].marker);
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), prog.decls[2].implement.methods[0].marker);
}

test "decision 553: marker-type-mismatch — located at the marker" {
    try expectKindAt("async fn f() -> i32 { return 1; }", .markerTypeMismatch, 1, 1);
    try expectKindAt("pub iter fn f() -> @Task<i32> { return 1; }", .markerTypeMismatch, 1, 5);
    try expectKindAt("async iter fn f() -> @Iterator<i32> { yield 1; }", .markerTypeMismatch, 1, 1);
    try expectKindAt("component fn F() -> @Task<i32> { return 1; }", .markerTypeMismatch, 1, 1);
    // No return type at all (open point B-116-f).
    try expectKindAt("async fn f() { }", .markerTypeMismatch, 1, 1);
    try expectKindAt(
        \\type Grid(n: i32) {
        \\    async fn each(self: Self) -> Iterator<i32> { yield 1; }
        \\}
    , .markerTypeMismatch, 2, 5);
    try expectKindAt("fn f() { val g = async fn(x: i32) -> i32 { x }; }", .markerTypeMismatch, 1, 18);
}

test "decision 553: marker-on-declaration — a bodyless declaration takes no marker" {
    try expectKindAt("async fn f() -> @Task<i32>;", .markerOnDeclaration, 1, 1);
    try expectKindAt("pub declare async fn f() -> @Task<i32>;", .markerOnDeclaration, 1, 13);
    try expectKindAt(
        \\behavior Source {
        \\    async fn next(self: Self) -> Task<i32>;
        \\}
    , .markerOnDeclaration, 2, 5);
    try expectKindAt(
        \\type Box(n: i32) {
        \\    declare async fn next(self: Self) -> Task<i32>;
        \\}
    , .markerOnDeclaration, 2, 13);
}

test "decision 584: marker-without-arrow — a marker inside a lambda's brace with no `->`" {
    try expectKindAt("fn f() { val g = { iter yield 1; }; }", .markerWithoutArrow, 1, 20);
    try expectKindAt("fn f() { val g = { async iter yield 1; }; }", .markerWithoutArrow, 1, 20);
    try expectKindAt("fn f() { val g = { component val x = 1; }; }", .markerWithoutArrow, 1, 20);
    try expectKindAt("fn f() { val g = { async x }; }", .markerWithoutArrow, 1, 20);
    // Trailing too.
    try expectKindAt("fn f() { g(1) { iter yield 1; }; }", .markerWithoutArrow, 1, 17);
}

test "decision 584: the block forms and the words as names still parse" {
    try expectParses("fn f() -> @Task<i32> { val t = async { 1 }; return await t; }");
    // `async {` is always the block, whatever its body starts with.
    try expectParses("fn f() -> @Task<i32> { val t = async { x }; return await t; }");
    try expectParses("fn f() { val a = iter loop { yield 1; break; }; val b = stream loop { yield 1; break; }; }");
    try expectParses("fn f(g: G) { val x = g.iter { -> 1 }; val iter = 1; val component = iter; }");
    try expectParses("fn f(iter: E) -> i32 { return case iter { .A { 1 } .B { 2 } }; }");
    // A function named `iter` / `component` takes a trailing lambda as any
    // function does (584 (1): no parentheses needed).
    try expectParses("fn f() { iter { x -> x }; component { -> 1 }; iter() { x -> x }; }");
    // A block whose first word is a marker word an expression continues.
    try expectParses("fn f() -> @Task<i32> { val a = { iter.next() }; val b = { async { 1 } }; val c = { iter loop { yield 1; break; } }; return await b; }");
    // `{ async, b -> … }` is a lambda whose first parameter is `async`.
    try expectParses("fn f() { val g = { async, b -> b }; }");
}

test "decisions 553, 584: a marked lambda is the block form it names, returned" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const asyncLambda = bindValue(try firstStmt(alloc, "val f = { async x -> await g(x) };")).function;
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), asyncLambda.kind.marker);
    try std.testing.expectEqual(@as(usize, 1), asyncLambda.kind.params.len);
    const ret = asyncLambda.kind.body[0];
    try std.testing.expect(ret.tail == .returned);
    const block = ret.expr.jump.kind.@"return".?.*.function;
    try std.testing.expect(block.kind.syntax == .asyncBlock);
    // The block's tail `await g(x)` is its value (decisions 525, 537).
    try std.testing.expect(block.kind.body[0].tail == .returned);

    const iterLambda = bindValue(try firstStmt(alloc, "val f = { iter n -> yield n; };")).function;
    try std.testing.expectEqual(@as(?ast.EffectKind, .iterator), iterLambda.kind.marker);
    const loop = iterLambda.kind.body[0].expr.jump.kind.@"return".?.*.loop;
    try std.testing.expectEqual(@as(?ast.EffectKind, .iterator), loop.generator);
    try std.testing.expectEqual(@as(usize, 2), loop.body.len);
    try std.testing.expect(loop.body[1].expr.jump.kind == .@"break");
    // Decision 584 (2) — the loop is the lambda's function body.
    try std.testing.expect(loop.markedLambda);

    const streamLambda = bindValue(try firstStmt(alloc, "val f = { async iter -> yield 1; };")).function;
    try std.testing.expectEqual(@as(?ast.EffectKind, .stream), streamLambda.kind.body[0].expr.jump.kind.@"return".?.*.loop.generator);

    const comp = bindValue(try firstStmt(alloc, "val f = { component -> 1 };")).function;
    try std.testing.expectEqual(@as(?ast.EffectKind, .component), comp.kind.marker);
    try std.testing.expect(comp.kind.body[0].tail == .value);

    const fnExpr = bindValue(try firstStmt(alloc, "val f = async fn(x) { await g(x) };")).function;
    try std.testing.expect(fnExpr.kind.syntax == .fnExpr);
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), fnExpr.kind.marker);
}

test "decision 584: a marked trailing lambda carries its marker and its block form" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const prog = try parseOk(alloc, "fn f() { g(1) { async x -> await h(x) }; k { iter -> yield 1; }; }");
    const body = prog.decls[0].@"fn".body;
    const a = body[0].expr.call.kind.call.trailing[0];
    try std.testing.expectEqual(@as(?ast.EffectKind, .task), a.marker);
    try std.testing.expectEqual(@as(usize, 1), a.params.len);
    try std.testing.expect(a.body[0].expr.jump.kind.@"return".?.*.function.kind.syntax == .asyncBlock);
    const b = body[1].expr.call.kind.call.trailing[0];
    try std.testing.expectEqual(@as(?ast.EffectKind, .iterator), b.marker);
    try std.testing.expect(b.body[0].expr.jump.kind.@"return".?.*.loop.markedLambda);
}

test "decision 537: a body's tail `await e` / `try e` is its value" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const prog = try parseOk(alloc,
        \\fn f() -> Task<i32> { await g() }
        \\fn h() -> Result<i32, string> { try k() }
    );
    try std.testing.expect(prog.decls[0].@"fn".body[0].tail == .returned);
    try std.testing.expect(prog.decls[1].@"fn".body[0].tail == .returned);
}
