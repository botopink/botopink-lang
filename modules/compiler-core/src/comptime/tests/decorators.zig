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
        \\record UserService { name: string }
    );
}

test "decorator: string-arg marker on a method (interface site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(comptime decl: @Decl, path: string) { }
        \\
        \\interface Routes {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string
        \\}
    );
}

test "decorator: string-arg marker on a record method (P3 method-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn getMapping(comptime decl: @Decl, path: string) { }
        \\
        \\record Controller {
        \\    name: string,
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string { return self.name; }
        \\}
    );
}

test "decorator: marker on a struct method (P3 method-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn tag(comptime decl: @Decl, label: string) { }
        \\
        \\struct Sb {
        \\    val x: i32,
        \\    #[tag("a")]
        \\    fn m(self: Self) -> i32 { return self.x; }
        \\}
    );
}

test "decorator: marker on a record field (P3 field-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn inject(comptime decl: @Decl) { }
        \\
        \\record UserService {
        \\    #[inject]
        \\    repo: string,
        \\    name: string
        \\}
    );
}

test "decorator: string-arg marker on a struct field (P3 field-site)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn value(comptime decl: @Decl, key: string) { }
        \\
        \\struct Config {
        \\    #[value("port")]
        \\    val port: i32
        \\}
    );
}

test "decorator: declared as a `declare fn` marker (delegate form)" {
    // A framework lib may ship its markers as bodyless `declare fn`s — the core
    // recognizes that form identically (first param `comptime _: @Decl`).
    try h.assertInfersOk(std.testing.allocator,
        \\declare fn component(comptime decl: @Decl);
        \\
        \\#[component]
        \\record Widget { id: i32 }
    );
}

test "decorator: applies on struct, enum and fn sites" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn tag(comptime decl: @Decl, label: string) { }
        \\
        \\#[tag("a")]
        \\struct Sa { val x: i32 }
        \\
        \\#[tag("b")]
        \\enum Color { Red, Green }
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
        \\record A { x: i32 }
    );
}

// ── decorator bodies reflect over `@Decl` (P2) ─────────────────────────────────

test "decorator body: @compilerError aborts compilation" {
    // `@compilerError(msg)` is the generic compile-time error — no `@Decl` handle
    // needed, reads like `@panic`. Preferred over `decl.fail`/`decl.failAt`.
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != .Record) {
        \\        @compilerError("#[service] must annotate a record");
        \\    }
        \\}
        \\
        \\#[service]
        \\record UserService { name: string }
    );
}

test "decorator body: reads decl.kind and calls decl.fail" {
    // The body must type-check: `decl.kind` (a `DeclKind`), the `.Record`
    // member literal, and the `decl.fail(string)` diagnostic call.
    try h.assertInfersOk(std.testing.allocator,
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != .Record) {
        \\        decl.fail("#[service] must annotate a record");
        \\    }
        \\}
        \\
        \\#[service]
        \\record UserService { name: string }
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
        \\record Point { x: i32, y: i32 }
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
        \\record Service { repo: string }
    );
}

// ── generic argument validation (arity + type) ────────────────────────────────

test "decorator error: too few arguments" {
    try expectDecoratorError(
        \\fn getMapping(comptime decl: @Decl, path: string) { }
        \\
        \\#[getMapping]
        \\record A { x: i32 }
    , "expects 1 argument");
}

test "decorator error: too many arguments" {
    try expectDecoratorError(
        \\fn service(comptime decl: @Decl) { }
        \\
        \\#[service("oops")]
        \\record A { x: i32 }
    , "expects 0 argument");
}

test "decorator error: argument type mismatch (number where string expected)" {
    try expectDecoratorError(
        \\fn value(comptime decl: @Decl, key: string) { }
        \\
        \\#[value(123)]
        \\record A { x: i32 }
    , "must be string");
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
        \\record PostService { name: string }
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
