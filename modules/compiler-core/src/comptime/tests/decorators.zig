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
        \\fn service(comptime decl: @Decl) { }
        \\
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator: string-arg marker on a method (interface site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(comptime decl: @Decl, comptime path: @Expr<string>) { }
        \\
        \\behavior Routes {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string;
        \\}
    );
}

test "decorator: string-arg marker on a record method (P3 method-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(comptime decl: @Decl, comptime path: @Expr<string>) { }
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
        \\fn tag(comptime decl: @Decl, comptime label: @Expr<string>) { }
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
        \\fn inject(comptime decl: @Decl) { }
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
        \\fn value(comptime decl: @Decl, comptime key: @Expr<string>) { }
        \\
        \\type Config(
        \\    #[value("port")]
        \\    port: i32
        \\)
    );
}

test "decorator: declared as a `declare fn` marker (delegate form)" {
    // A framework lib may ship its markers as bodyless `declare fn`s — the core
    // recognizes that form identically (first param `comptime _: @Decl`).
    try h.assertInfersOk(std.testing.allocator,
        \\declare fn component(comptime decl: @Decl);
        \\
        \\#[component]
        \\type Widget(id: i32)
    );
}

test "decorator: applies on struct, enum and fn sites" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn tag(comptime decl: @Decl, comptime label: @Expr<string>) { }
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
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != .Type) {
        \\        @compilerError("#[service] must annotate a type with fields");
        \\    }
        \\}
        \\
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator body: reads decl.kind and calls decl.fail" {
    // The body must type-check: `decl.kind` (a `DeclKind`), the `.Type`
    // member literal — resolved against `DeclKind`, the left operand's type
    // (it read `.Record` until 01 step 12, a member of `TypeInfoKind` and of
    // `TypeInfo` but not of `DeclKind`, taken from the flat variant table) —
    // and the `decl.fail(string)` diagnostic call.
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != .Type) {
        \\        decl.fail("#[service] must annotate a type with fields");
        \\    }
        \\}
        \\
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator body: reads decl.name and decl.returnType" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn describe(comptime decl: @Decl) {
        \\    val n = decl.name;
        \\    val rt = decl.returnType;
        \\}
        \\
        \\#[describe]
        \\type Point(x: i32, y: i32)
    );
}

test "decorator body: reads the aggregate members (fields/methods/annotations)" {
    // P3: `@Decl` is a struct, so the aggregate reflection members resolve —
    // this is what a wiring decorator iterates to build a DI/router table.
    try h.assertInfersOk(std.testing.allocator,
        \\fn component(comptime decl: @Decl) {
        \\    val fs = decl.fields;
        \\    val ms = decl.methods;
        \\    val ans = decl.annotations;
        \\}
        \\
        \\#[component]
        \\type Service(repo: string)
    );
}

// ── generic argument validation (arity + type) ────────────────────────────────

test "decorator error: too few arguments" {
    try expectDecoratorError(
        \\fn getMapping(comptime decl: @Decl, comptime path: @Expr<string>) { }
        \\
        \\#[getMapping]
        \\type A(x: i32)
    , "expects 1 argument");
}

test "decorator error: too many arguments" {
    try expectDecoratorError(
        \\fn service(comptime decl: @Decl) { }
        \\
        \\#[service("oops")]
        \\type A(x: i32)
    , "expects 0 argument");
}

test "decorator error: argument type mismatch (number where string expected)" {
    try expectDecoratorError(
        \\fn value(comptime decl: @Decl, comptime key: @Expr<string>) { }
        \\
        \\#[value(123)]
        \\type A(x: i32)
    , "`#[value]`'s `key` expects `string`, got `i32`");
}

// ── decision 280 — typed comptime decorator arguments ────────────────────────

test "decision 280: a decorator parameter without comptime is refused at it" {
    try expectDecoratorError(
        \\fn route(comptime decl: @Decl, path: string) { }
    , "decorator-param-not-comptime: the decorator `route`'s parameter `path` is not `comptime`");
}

test "decision 280: a comptime default outside a decorator is refused at it" {
    try expectDecoratorError(
        \\fn scale(x: i32, comptime n: @Expr<i32> = 3) -> i32 { return x * n.value; }
    , "comptime-default-outside-decorator: the `comptime` parameter `n` takes a default only in a decorator");
}

test "decision 364: a function call is not known at build, refused where the body reads it" {
    try expectDecoratorError(
        \\fn env(name: string) -> string { return name; }
        \\fn tag(comptime decl: @Decl, comptime label: @Expr<string>) { decl.setMeta("l", label.value); }
        \\
        \\#[tag(env("X"))]
        \\type A(x: i32)
    , "decorator-value-not-comptime");
}

test "decision 364: an argument not known at build that the body never reads is accepted" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn env(name: string) -> string { return name; }
        \\fn tag(comptime decl: @Decl, comptime label: @Expr<string>) { }
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
        \\    comptime decl: @Decl<T>,
        \\    comptime sizes: @Expr<i32[]>,
        \\    comptime rule: @Expr<?fn(v: T) -> bool> = null,
        \\    comptime level: @Expr<Level> = .Low,
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
        \\fn check<T>(comptime decl: @Decl<T>, comptime rule: @Expr<fn(v: T) -> bool>) { }
        \\
        \\#[check(positive)]
        \\type Account(name: string)
    , "`#[check]`'s `rule` expects `fn(Account) -> bool`, got `fn(Order) -> bool`");
}

test "decision 280: @Decl<P> refuses a declaration of another shape" {
    try expectDecoratorError(
        \\fn on<E>(comptime decl: @Decl<fn(e: E) -> unknown>) { }
        \\
        \\#[on]
        \\fn wrong() { }
    , "`#[on]` expects a declaration of type `fn(E) -> unknown`, and `wrong` is `fn() -> void`");
}

test "decision 280: a variant is named as declared" {
    try expectDecoratorError(
        \\type Code { Custom, Mismatch }
        \\fn tag(comptime decl: @Decl, comptime code: @Expr<Code>) { }
        \\
        \\#[tag(.custom)]
        \\type A(x: i32)
    , "`.custom` names no variant of `Code`");
}

test "decision 280: a type parameter refuses a string" {
    try expectDecoratorError(
        \\type Mail(to: string)
        \\fn missing(comptime decl: @Decl, comptime t: @Expr<type>) { }
        \\
        \\#[missing("Mail")]
        \\fn mail() { }
    , "`#[missing]`'s `t` expects a `type`, got `string`");
}

test "decision 280: a label names a parameter" {
    try expectDecoratorError(
        \\fn tag(comptime decl: @Decl, comptime label: @Expr<string>) { }
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
        \\fn service(comptime decl: @Decl) { }
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

test "decision 364: `comptime x: T` is refused at the declaration — decorator, function, method, declare fn" {
    try expectDecoratorError(
        \\fn route(comptime decl: @Decl, comptime path: string) { }
    , "comptime-param-not-expr: `route`'s parameter `path` is `comptime path: string` — a `comptime` parameter is `comptime path: @Expr<string>`");
    try expectDecoratorError(
        \\fn twice(comptime n: i32) -> i32 { return n * 2; }
    , "comptime-param-not-expr: `twice`'s parameter `n`");
    try expectDecoratorError(
        \\type Kit {
        \\    fn pick(comptime t: type) -> i32 { return 1; }
        \\}
    , "comptime-param-not-expr: `pick`'s parameter `t` is `comptime t: type`");
    try expectDecoratorError(
        \\declare fn host(comptime key: string) -> string;
    , "comptime-param-not-expr: `host`'s parameter `key`");
}

test "decision 364: `x.value` is the argument's value, typed `T`" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Level { Low, High }
        \\fn mark(comptime decl: @Decl, comptime n: @Expr<i32>, comptime l: @Expr<Level>, comptime xs: @Expr<string[]>) {
        \\    val total: i32 = n.value + xs.value.length;
        \\    if (l.value == Level.High) decl.setMeta("t", total.toString());
        \\}
        \\fn scale(comptime n: @Expr<i32>, x: i32) -> i32 { return x * n.value; }
        \\#[mark(2, .High, ["a"])]
        \\type A(x: i32)
        \\val s = scale(3, 4);
    );
}

test "decision 364: an `@Expr` of a function or a type has no `.value`" {
    try expectDecoratorError(
        \\fn rule(comptime decl: @Decl, comptime r: @Expr<fn(x: i32) -> bool>) {
        \\    val f = r.value;
        \\}
    , "expr-value-of-function: `r` is an `@Expr` of a function, which has no `.value`");
    try expectDecoratorError(
        \\fn rule(comptime decl: @Decl, comptime r: @Expr<?fn(x: i32) -> bool> = null) {
        \\    if (r.value == null) decl.fail("none");
        \\}
    , "expr-value-of-function");
    try expectDecoratorError(
        \\fn bean(comptime decl: @Decl, comptime t: @Expr<type>) {
        \\    val v = t.value;
        \\}
    , "expr-value-of-type: `t` is an `@Expr` of a type, which has no `.value`");
    // A type parameter the annotation binds to a function, read `.value`.
    try expectDecoratorError(
        \\fn pass<T>(comptime decl: @Decl, comptime v: @Expr<T>) {
        \\    val x = v.value;
        \\}
        \\fn f(n: i32) -> i32 { return n; }
        \\#[pass(f)]
        \\type A(x: i32)
    , "expr-value-of-function: `#[pass]`'s `v` is a function here");
}

test "decision 364: a `comptime` parameter's `@Expr` answers `.value`, and `.fail` in a decorator" {
    try expectDecoratorError(
        \\fn note(comptime decl: @Decl, comptime m: @Expr<string>) {
        \\    decl.setMeta("m", m.text());
        \\}
    , "expr-param-method: `m` is a `comptime` parameter, whose `@Expr` answers `.value` and `.fail(…)` — not `.text(…)`");
    try expectDecoratorError(
        \\fn twice(comptime n: @Expr<i32>) -> i32 {
        \\    n.fail("no");
        \\    return 2;
        \\}
    , "expr-param-method: `n` is a `comptime` parameter, whose `@Expr` answers `.value` — not `.fail(…)`");
    try h.assertInfersOk(std.testing.allocator,
        \\fn check(comptime decl: @Decl, comptime n: @Expr<i32>) {
        \\    if (n.value < 0) n.fail("negative");
        \\}
    );
}
