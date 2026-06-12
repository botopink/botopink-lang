//! comptime: annotation-processor (decorator) INVOCATION (P2).
//!
//! After argument validation, a decorator's body RUNS over the declaration it
//! annotates: the core serializes that declaration into a `@Decl` handle and
//! executes the body in the node runtime (host-side comptime, like `@Expr`
//! templates). `decl.fail(...)` surfaces as a scoped type error; a clean return
//! accepts the placement. The core has NO lib knowledge — the body holds every
//! rule. (P1's recognition + generic argument validation live in
//! `decorators.zig`; these scenarios need the full node pipeline.)

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

/// The decorator body accepts the placement — compilation succeeds. The session
/// is kept alive until after the assertion (its arena backs the outcome).
fn assertAccepts(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, .node, build_root);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    if (outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected decorator rejection:\n{s}\n", .{desc});
    }
    try std.testing.expect(outcome == .ok);
}

/// The decorator body rejects the placement via `fail` — compilation reports a
/// type error whose message contains `needle`. The session is kept alive until
/// after the assertion (its arena backs the error message).
fn assertRejects(comptime loc: std.builtin.SourceLocation, src: []const u8, needle: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, .node, build_root);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .typeError);
    const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
    defer std.testing.allocator.free(desc);
    if (std.mem.indexOf(u8, desc, needle) == null) {
        std.debug.print("\nexpected rejection containing \"{s}\", got:\n{s}\n", .{ needle, desc });
        return error.TestUnexpectedResult;
    }
}

// ── placement validation in the body ──────────────────────────────────────────

test "decorator invocation: body accepts a record" {
    try assertAccepts(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Record) { decl.fail("#[service] must annotate a record"); }
        \\}
        \\#[service]
        \\record UserService { name: string }
    );
}

test "decorator invocation: body rejects wrong placement (fn instead of record)" {
    try assertRejects(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Record) { decl.fail("#[service] must annotate a record"); }
        \\}
        \\#[service]
        \\fn notARecord() { }
    , "must annotate a record");
}

test "decorator invocation: method placement accepted" {
    try assertAccepts(@src(),
        \\fn getMapping(comptime decl: @Decl, path: string) {
        \\    if (decl.kind != DeclKind.Method) { decl.fail("#[getMapping] must annotate a method"); }
        \\}
        \\interface Routes {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string
        \\}
    );
}

test "decorator invocation: method decorator rejects a record" {
    try assertRejects(@src(),
        \\fn getMapping(comptime decl: @Decl, path: string) {
        \\    if (decl.kind != DeclKind.Method) { decl.fail("#[getMapping] must annotate a method"); }
        \\}
        \\#[getMapping("/x")]
        \\record Nope { }
    , "must annotate a method");
}

test "decorator invocation: body reads the reflected name" {
    try assertRejects(@src(),
        \\fn named(comptime decl: @Decl) {
        \\    if (decl.name == "Bad") { decl.fail("the name Bad is reserved"); }
        \\}
        \\#[named]
        \\record Bad { }
    , "the name Bad is reserved");
}

test "decorator invocation: @compilerError rejects wrong placement" {
    // The generic compile-time error builtin — no `@Decl` handle needed — also
    // surfaces as a scoped rejection when the body runs.
    try assertRejects(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Record) { @compilerError("#[service] must annotate a record"); }
        \\}
        \\#[service]
        \\fn notARecord() { }
    , "must annotate a record");
}

test "decorator invocation: @compilerError body accepts the right placement" {
    try assertAccepts(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Record) { @compilerError("#[service] must annotate a record"); }
        \\}
        \\#[service]
        \\record UserService { name: string }
    );
}

// ── wiring contribution: a body emits generated declarations (P3) ──────────────

test "decorator invocation: @emit contributes a top-level declaration" {
    // The decorator body builds wiring as ordinary code; `@emit(source)` splices
    // it into the module, where it is inferred + emitted like hand-written decls.
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(@src());
    const src =
        \\fn singleton(comptime decl: @Decl) {
        \\    @emit("pub val wiredMarker = 99;");
        \\}
        \\#[singleton]
        \\record Service { x: i32 }
    ;
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, .node, build_root);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .ok);
    var found = false;
    var decoratorEmitted = false;
    for (outcome.ok.transformed.decls) |d| {
        if (d == .val and std.mem.eql(u8, d.val.name, "wiredMarker")) found = true;
        // The decorator fn is comptime-only and must be dropped from codegen
        // (else `@emit`/`__decl` would leak into real output).
        if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, "singleton")) decoratorEmitted = true;
    }
    if (!found) return error.ContributionMissing;
    if (decoratorEmitted) return error.DecoratorFnNotDropped;
}

test "decorator invocation: a body may reference an @emit'd declaration" {
    // Annotation processors run BEFORE bodies are inferred, so the generated decls
    // are spliced before any body that references them is type-checked. Here a `fn`
    // calls an `@emit`ed factory — with body-first inference this failed as an
    // unbound variable (the regression that blocked `@emit` under `botopink test`).
    try assertAccepts(@src(),
        \\fn gen(comptime decl: @Decl) {
        \\    @emit("pub fn makeThing() -> i32 { return 7; }");
        \\}
        \\#[gen]
        \\record Anchor { x: i32 }
        \\fn useit() -> i32 { return makeThing(); }
    );
}

test "decorator invocation: interface-level marker runs over the interface" {
    // A marker on an interface reflects with `kind == Interface` and runs its body
    // (previously interface-level markers were silently skipped).
    try assertRejects(@src(),
        \\fn onlyRecords(comptime decl: @Decl) {
        \\    if (decl.kind == DeclKind.Interface) { decl.fail("marker is not allowed on an interface"); }
        \\}
        \\#[onlyRecords]
        \\interface Repo { fn find(self: Self, id: i32) -> string }
    , "not allowed on an interface");
}

test "decorator invocation: mock-style synthesis from an interface compiles" {
    // A mocking-lib shape: reflect an interface's methods, emit a record that
    // implements it plus a factory, then use the factory — all in one compile.
    try assertAccepts(@src(),
        \\fn mock(comptime decl: @Decl) {
        \\    var methods = "";
        \\    decl.methods.forEach({ m ->
        \\        methods = methods + "  fn " + m.name + "(self: Self) -> i32 { return 0; }\n";
        \\    });
        \\    @emit("record Mock" + decl.name + " implement " + decl.name + " {\n  tag: string,\n" + methods + "}");
        \\    @emit("pub fn mock" + decl.name + "() -> " + decl.name + " { return Mock" + decl.name + "(tag: \"\"); }");
        \\}
        \\#[mock]
        \\interface Counter { fn value(self: Self) -> i32 }
        \\fn useit() -> i32 { return mockCounter().value(); }
    );
}
