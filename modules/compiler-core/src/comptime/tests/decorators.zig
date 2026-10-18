//! comptime: annotation-processor (decorator) recognition + generic argument
//! validation (P1). A decorator is any fn whose first parameter is
//! `comptime _: @Decl`; applying `#[d(args)]` type-checks the trailing `args`
//! against the decorator's declared signature — with NO lib-specific knowledge
//! in the core. Placement rules (where a marker may sit) are the decorator
//! body's job (P2), not validated here.

const std = @import("std");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Env = @import("../env.zig").Env;
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

/// Infer `src`, expecting a `TypeError` whose rendered message contains `needle`.
/// Inline (no snapshot) so these stay deterministic under parallel test runs.
fn expectDecoratorError(src: []const u8, needle: []const u8) !void {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;
    // C-21 — every type error carries a location.
    try std.testing.expect(err.loc != null);
    const msg = switch (err.kind) {
        .custom => |c| c.message,
        else => return error.TestUnexpectedError,
    };
    if (std.mem.indexOf(u8, msg, needle) == null) {
        std.debug.print("\nexpected error containing \"{s}\", got:\n{s}\n", .{ needle, msg });
        return error.TestUnexpectedError;
    }
}

// ── recognition + valid applications ──────────────────────────────────────────

test "decorator: marker with no trailing args applies to a record" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(syntax decl: unknown) { }
        \\
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator: string-arg marker on a method (interface site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(syntax decl: unknown, comptime path: string) { }
        \\
        \\behavior Routes {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string;
        \\}
    );
}

test "decorator: string-arg marker on a record method (P3 method-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(syntax decl: unknown, comptime path: string) { }
        \\
        \\type Controller(
        \\    name: string) {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string { return self.name; }
        \\}
    );
}

test "decorator: marker on a struct method (P3 method-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn tag(syntax decl: unknown, comptime label: string) { }
        \\
        \\type Sb(
        \\    x: i32) {
        \\    #[tag("a")]
        \\    fn m(self: Self) -> i32 { return self.x; }
        \\}
    );
}

test "decorator: marker on a record field (P3 field-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn inject(syntax decl: unknown) { }
        \\
        \\type UserService(
        \\    #[inject]
        \\    repo: string,
        \\    name: string
        \\)
    );
}

test "decorator: string-arg marker on a struct field (P3 field-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn value(syntax decl: unknown, comptime key: string) { }
        \\
        \\type Config(
        \\    #[value("port")]
        \\    port: i32
        \\)
    );
}

test "decorator: a marker is a decorator with an empty body" {
    // Decision 604 — a library ships its markers as decorators with an empty
    // body; a bodyless `declare fn` decorator is refused.
    try h.assertInfersOk(std.testing.allocator,
        \\fn component(syntax decl: unknown) {}
        \\
        \\#[component]
        \\type Widget(id: i32)
    );
}

test "decorator: applies on struct, enum and fn sites" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn tag(syntax decl: unknown, comptime label: string) { }
        \\
        \\#[tag("a")]
        \\type Sa(x: i32)
        \\
        \\#[tag("b")]
        \\type Color { Red, Green }
        \\
        \\#[tag("c")]
        \\fn handler() -> i32 { return 1; }
    );
}

test "decorator: an unknown marker is left untouched (no decorator loaded)" {
    // `unknownMarker` is not a recognized decorator (no `comptime _: @Decl` fn),
    // so the core stays lenient — a lib that defines it may simply be absent.
    try h.assertInfersOk(std.testing.allocator,
        \\#[unknownMarker("anything", 1, 2, 3)]
        \\type A(x: i32)
    );
}

// ── decorator bodies reflect over `@Decl` (P2) ─────────────────────────────────

test "decorator body: @compilerError aborts compilation" {
    // `@compilerError(msg)` is the generic compile-time error — no `@Decl` handle
    // needed, reads like `@panic`. Preferred over `decl.fail`/`decl.failAt`.
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(syntax decl: unknown) {
        \\    if (compiler.kind(decl) != .Type) {
        \\        @compilerError("#[service] must annotate a type with fields");
        \\    }
        \\}
        \\
        \\#[service]
        \\type UserService(name: string)
        \\import {compiler} from "std";
    );
}

test "decorator body: reads decl.kind and calls decl.fail" {
    // The body must type-check: `decl.kind` (a `DeclKind`), the `.Type`
    // member literal — resolved against `DeclKind`, the left operand's type
    // (it read `.Record` until 01 step 12, a member of `TypeInfoKind` and of
    // `TypeInfo` but not of `DeclKind`, taken from the flat variant table) —
    // and the `decl.fail(string)` diagnostic call.
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(syntax decl: unknown) {
        \\    if (compiler.kind(decl) != .Type) {
        \\        compiler.fail("#[service] must annotate a type with fields", at: decl);
        \\    }
        \\}
        \\
        \\#[service]
        \\type UserService(name: string)
        \\import {compiler} from "std";
    );
}

test "decorator body: reads decl.name and decl.returnType" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn describe(syntax decl: unknown) {
        \\    val n = compiler.name(decl);
        \\    val rt = compiler.returnType(decl);
        \\}
        \\
        \\#[describe]
        \\type Point(x: i32, y: i32)
        \\import {compiler} from "std";
    );
}

test "decorator body: reads the aggregate members (fields/methods/annotations)" {
    // P3: `@Decl` is a struct, so the aggregate reflection members resolve —
    // this is what a wiring decorator iterates to build a DI/router table.
    try h.assertInfersOk(std.testing.allocator,
        \\fn component(syntax decl: unknown) {
        \\    val fs = compiler.fields(decl);
        \\    val ms = compiler.methods(decl);
        \\    val ans = compiler.annotations(decl);
        \\}
        \\
        \\#[component]
        \\type Service(repo: string)
        \\import {compiler} from "std";
    );
}

// ── generic argument validation (arity + type) ────────────────────────────────

test "decorator error: too few arguments" {
    try expectDecoratorError(
        \\fn getMapping(syntax decl: unknown, comptime path: string) { }
        \\
        \\#[getMapping]
        \\type A(x: i32)
    , "expects 1 argument");
}

test "decorator error: too many arguments" {
    try expectDecoratorError(
        \\fn service(syntax decl: unknown) { }
        \\
        \\#[service("oops")]
        \\type A(x: i32)
    , "expects 0 argument");
}

test "decorator error: argument type mismatch (number where string expected)" {
    try expectDecoratorError(
        \\fn value(syntax decl: unknown, comptime key: string) { }
        \\
        \\#[value(123)]
        \\type A(x: i32)
    , "`#[value]`'s `key` expects `string`, got `i32`");
}

// ── decision 280 — typed comptime decorator arguments ────────────────────────

test "decision 280: a decorator parameter without comptime is refused at it" {
    try expectDecoratorError(
        \\fn route(syntax decl: unknown, path: string) { }
    , "decorator-param-not-comptime: the decorator `route`'s parameter `path` is not `comptime`");
}

test "decision 280: a comptime default outside a decorator is refused at it" {
    try expectDecoratorError(
        \\fn scale(x: i32, comptime n: i32 = 3) -> i32 { return x * n; }
    , "comptime-default-outside-decorator: the `comptime` parameter `n` takes a default only in a decorator");
}

test "decision 364: a function call is not known at build, refused where the body reads it" {
    try expectDecoratorError(
        \\fn env(name: string) -> string { return name; }
        \\fn tag(syntax decl: unknown, comptime label: string) { decl.setMeta("l", label); }
        \\
        \\#[tag(env("X"))]
        \\type A(x: i32)
    , "decorator-value-not-comptime");
}

test "decision 364: an argument not known at build that the body never reads is accepted" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn env(name: string) -> string { return name; }
        \\fn tag(syntax decl: unknown, comptime label: string) { }
        \\
        \\#[tag(env("X"))]
        \\type A(x: i32)
    );
}

test "decision 280: arguments are typed — arrays, functions, variants, labels, defaults" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Level { Low, High }
        \\fn positive(o: Order) -> bool { return o.total > 0; }
        \\fn mark<T>(
        \\    syntax decl: T,
        \\    comptime sizes: i32[],
        \\    comptime rule: ?fn(v: T) -> bool = null,
        \\    comptime level: Level = .Low,
        \\) { }
        \\
        \\#[mark([1, 2], positive, level: .High)]
        \\type Order(total: i32)
    );
}

test "decision 280: a function argument over another type is refused, both spelled" {
    try expectDecoratorError(
        \\type Order(total: i32)
        \\fn positive(o: Order) -> bool { return o.total > 0; }
        \\fn check<T>(syntax decl: T, comptime rule: fn(v: T) -> bool) { }
        \\
        \\#[check(positive)]
        \\type Account(name: string)
    , "`#[check]`'s `rule` expects `fn(Account) -> bool`, got `fn(Order) -> bool`");
}

test "decision 280: @Decl<P> refuses a declaration of another shape" {
    try expectDecoratorError(
        \\fn on<E>(syntax decl: fn(e: E) -> unknown) { }
        \\
        \\#[on]
        \\fn wrong() { }
    , "`#[on]` expects a declaration of type `fn(E) -> unknown`, and `wrong` is `fn() -> void`");
}

test "decision 280: a variant is named as declared" {
    try expectDecoratorError(
        \\type Code { Custom, Mismatch }
        \\fn tag(syntax decl: unknown, comptime code: Code) { }
        \\
        \\#[tag(.custom)]
        \\type A(x: i32)
    , "`.custom` names no variant of `Code`");
}

test "decision 280: a type parameter refuses a string" {
    try expectDecoratorError(
        \\type Mail(to: string)
        \\fn missing(syntax decl: unknown, comptime t: anytype) { }
        \\
        \\#[missing("Mail")]
        \\fn mail() { }
    , "`#[missing]`'s `t` expects a `type`, got `string`");
}

test "decision 280: a label names a parameter" {
    try expectDecoratorError(
        \\fn tag(syntax decl: unknown, comptime label: string) { }
        \\
        \\#[tag(name: "x")]
        \\type A(x: i32)
    , "`#[tag]` has no parameter `name`");
}

// ── F2 (lsp-project-awareness): @emit must not blank the binding list ─────────
//
// When a decorator body `@emit`s code, `inferProgramTyped` used to return an
// empty binding slice (the per-decl loop sat after an early `return`). The LSP
// then saw zero bindings for any file applying an emitting decorator — completion
// went dark everywhere (R2). The fix still collects the SOURCE decls (record,
// fields, imports, fn signatures) before deferring the spliced re-analysis.

test "infer: an @emit-ing module still yields source-decl TypedBindings (R2)" {
    const allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    const src =
        \\fn service(syntax decl: unknown) { }
        \\
        \\#[service]
        \\type PostService(name: string)
    ;
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);

    // A non-empty contributions list is exactly what a decorator body's `@emit`
    // produces — and what used to trigger the early empty return.
    try env.contributions.append(env.arena, "val __emitted = 1;");

    const bindings = try inferMod.inferProgramTyped(&env, program);

    try std.testing.expect(bindings.len > 0);
    var found_record = false;
    for (bindings) |b| {
        if (std.mem.eql(u8, b.name, "PostService")) found_record = true;
    }
    try std.testing.expect(found_record);
}

// ── decision 364 — every `comptime` parameter is `comptime x: @Expr<T>` ──────

test "decision 575 (4): `comptime x: T` holds the value — decorator, function, method, declare fn" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Level { Low, High }
        \\fn mark(syntax decl: unknown, comptime n: i32, comptime l: Level, comptime xs: string[]) {
        \\    val total: i32 = n + xs.length;
        \\    if (l == Level.High) compiler.setMeta("t", total.toString());
        \\}
        \\fn scale(comptime n: i32, x: i32) -> i32 { return x * n; }
        \\type Kit {
        \\    fn pick(comptime t: anytype) -> i32 { return 1; }
        \\}
        \\#[@external(.Erlang("os:getenv($0)"), .Node("process.env[$0]"))]
        \\declare fn host(comptime key: string) -> string;
        \\#[mark(2, .High, ["a"])]
        \\type A(x: i32)
        \\val s = scale(3, 4);
        \\import {compiler} from "std";
    );
}

test "decision 364: `x.value` is the argument's value, typed `T`" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Level { Low, High }
        \\fn mark(syntax decl: unknown, comptime n: i32, comptime l: Level, comptime xs: string[]) {
        \\    val total: i32 = n + xs.length;
        \\    if (l == Level.High) decl.setMeta("t", total.toString());
        \\}
        \\fn scale(comptime n: i32, x: i32) -> i32 { return x * n; }
        \\#[mark(2, .High, ["a"])]
        \\type A(x: i32)
        \\val s = scale(3, 4);
    );
}

test "decision 364: an `@Expr` of a function or a type has no `.value`" {
    try expectDecoratorError(
        \\fn rule(syntax decl: unknown, comptime r: fn(x: i32) -> bool) {
        \\    val f = r;
        \\}
    , "expr-value-of-function: `r` is an `@Expr` of a function, which has no `.value`");
    try expectDecoratorError(
        \\fn rule(syntax decl: unknown, comptime r: ?fn(x: i32) -> bool = null) {
        \\    if (r == null) compiler.fail("none", at: decl);
        \\}
        \\import {compiler} from "std";
    , "expr-value-of-function");
    try expectDecoratorError(
        \\fn bean(syntax decl: unknown, comptime t: anytype) {
        \\    val v = t;
        \\}
    , "expr-value-of-type: `t` is an `@Expr` of a type, which has no `.value`");
    // A type parameter the annotation binds to a function, read `.value`.
    try expectDecoratorError(
        \\fn pass<T>(syntax decl: unknown, comptime v: T) {
        \\    val x = v;
        \\}
        \\fn f(n: i32) -> i32 { return n; }
        \\#[pass(f)]
        \\type A(x: i32)
    , "expr-value-of-function: `#[pass]`'s `v` is a function here");
}

test "decision 364: a `comptime` parameter's `@Expr` answers `.value`, and `.fail` and `.text` in a decorator (576 (2))" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn note(syntax decl: unknown, syntax m: string) {
        \\    decl.setMeta("m", compiler.text(m));
        \\}
        \\import {compiler} from "std";
    );
    try h.assertInfersOk(std.testing.allocator,
        \\fn check(syntax decl: unknown, comptime n: i32) {
        \\    if (n < 0) compiler.fail("negative", at: n);
        \\}
        \\import {compiler} from "std";
    );
}
