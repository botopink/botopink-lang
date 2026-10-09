//! comptime: annotation-processor (decorator) INVOCATION (P2).
//!
//! After argument validation, a decorator's body RUNS over the declaration it
//! annotates: the core serializes that declaration into a `@Decl` handle and
//! executes the body on the persistent `erl` (host-side comptime, like `@Expr`
//! templates). `decl.fail(...)` surfaces as a type error at the annotation; a
//! clean return accepts the placement. The core has NO lib knowledge — the body
//! holds every rule. (P1's recognition + generic argument validation live in
//! `decorators.zig`; these scenarios need the full compile pipeline.)

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

/// The decorator body accepts the placement — compilation succeeds. The session
/// is kept alive until after the assertion (its arena backs the outcome).
fn assertAccepts(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
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
    try assertRejectsAt(loc, src, needle, null);
}

/// `assertRejects`, also checking the diagnostic's `line:col` when given.
fn assertRejectsAt(comptime loc: std.builtin.SourceLocation, src: []const u8, needle: []const u8, at: ?[2]usize) !void {
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .typeError);
    // Match the diagnostic's own message, not the rendered report: the report
    // quotes the source, where the expected text appears as a string literal.
    const message = try outcome.typeError.message(std.testing.allocator);
    defer std.testing.allocator.free(message);
    if (std.mem.indexOf(u8, message, needle) == null) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nexpected rejection containing \"{s}\", got:\n{s}\n", .{ needle, desc });
        return error.TestUnexpectedResult;
    }
    if (at) |want| {
        const got = outcome.typeError.loc orelse return error.TestUnexpectedResult;
        try std.testing.expectEqual(want, [2]usize{ got.line, got.col });
    }
}

// ── placement validation in the body ──────────────────────────────────────────

test "decorator invocation: body accepts a record" {
    try assertAccepts(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { decl.fail("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator invocation: body rejects wrong placement (fn instead of record)" {
    try assertRejects(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { decl.fail("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\fn notARecord() { }
    , "must annotate a type with fields");
}

test "decorator invocation: rejection points at the annotation" {
    try assertRejectsAt(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { decl.failAt(Span(0, 1, 1), "#[service] must annotate a type with fields"); }
        \\}
        \\
        \\#[service]
        \\fn notARecord() { }
    , "must annotate a type with fields", .{ 5, 3 });
}

test "decorator invocation: a method nothing answers is the compiler's message, naming the call in the body" {
    // 1.0.11 front 14 step 1: the refusal is the compiler's own (no runtime
    // ran). The decorator is the module's own, so its body is checked when
    // the evaluator refuses it (01-checker's decorator-body row): the
    // checker's unknown method, located at the call in the body.
    try assertRejectsAt(@src(),
        \\fn check(comptime decl: @Decl) {
        \\    val n = decl.name;
        \\    val x = n.frobnicate(1, 2);
        \\}
        \\
        \\#[check]
        \\type A(x: i32)
    , "unknown-primitive-method: `string` has no method `frobnicate`", .{ 3, 15 });
}

test "decorator invocation: round trip ---- a @Decl handle carries fields, methods, variants and annotations" {
    // Front 14 step 3: the handle reaches the body as `main/1`'s argument (an
    // external term); the body reads every part back and emits it, and the reply
    // is byte-identical on the BEAM and the wat runtime.
    const src =
        \\fn column(comptime decl: @Decl, comptime name: string) { }
        \\fn describe(comptime decl: @Decl, comptime label: string) {
        \\    var out = decl.name + "[" + label + "]";
        \\    for (decl.annotations) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
        \\    for (decl.fields) { f ->
        \\        out = out + " field " + f.name + ":" + f.typeName;
        \\        for (f.annotations) { a -> out = out + " @" + a.name + "(" + a.args.join(",") + ")"; };
        \\    };
        \\    for (decl.variants) { v -> out = out + " variant " + v; };
        \\    for (decl.methods) { m ->
        \\        var ps = "";
        \\        for (m.params) { p -> ps = ps + p.name + ":" + p.typeName + ";"; };
        \\        out = out + " method " + m.name + "(" + ps + ")->" + m.returnType;
        \\    };
        \\    @emit("pub fn describe" + decl.name + "() -> string { return \"\"\"" + out + "\"\"\"; }");
        \\}
        \\#[describe("record")]
        \\type Point(#[column("px")] x: i32, y: ?i32) {
        \\    fn scaled(self: Self, by: i32) -> Point {
        \\        return Point(x: self.x * by, y: self.y);
        \\    }
        \\}
        \\#[describe("enum")]
        \\type Mode {
        \\    Fast,
        \\    Slow,
        \\    fn label(self: Self) -> string {
        \\        return "mode";
        \\    }
        \\}
        \\val p = describePoint();
        \\val m = describeMode();
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.repliesIdenticalAcrossRuntimes(std.testing.allocator, arena.allocator(), @src(), &.{.{ .path = "", .source = src }});
    // `#[describe]` twice (the record, the enum) and `#[column]` once, whose
    // body is empty and answers no contribution.
    var record: ?[]const u8 = null;
    var enumeration: ?[]const u8 = null;
    for (replies) |r| {
        if (std.mem.indexOf(u8, r, "describePoint") != null) record = r;
        if (std.mem.indexOf(u8, r, "describeMode") != null) enumeration = r;
    }
    const rec = record orelse return error.TestExpectedReply;
    const en = enumeration orelse return error.TestExpectedReply;
    // Annotations with their raw argument lexemes, fields with their types and
    // their own annotations, methods with their parameters and return type.
    for ([_][]const u8{
        "Point[record] @describe(\\\"record\\\")",
        " field x:i32 @column(\\\"px\\\")",
        " field y:?i32",
        " method scaled(self:Self;by:i32;)->Point",
    }) |needle| {
        if (std.mem.indexOf(u8, rec, needle) == null) {
            std.debug.print("\nexpected {s} in:\n{s}\n", .{ needle, rec });
            return error.TestExpectedContains;
        }
    }
    // Variants (and no field) on the enum-shaped type.
    for ([_][]const u8{
        "Mode[enum] @describe(\\\"enum\\\") variant Fast variant Slow method label(self:Self;)->string",
    }) |needle| {
        if (std.mem.indexOf(u8, en, needle) == null) {
            std.debug.print("\nexpected {s} in:\n{s}\n", .{ needle, en });
            return error.TestExpectedContains;
        }
    }
    try h.assertComptimeAstSingle(std.testing.allocator, @src(), src);
}

test "decorator invocation: a \\u{…} literal in the body evaluates to the character on both runtimes" {
    // 1.0.12 front 14 step 7 (02-erlang step 5 box 2): the body's literal and
    // the annotation's plain argument reach the comptime module as text written
    // by `erl_emitter.writeStringFromLexeme`, the erlang target's renderer, so
    // `\u{…}` is the code point's UTF-8 bytes — not Erlang's `\x{263A}`, which
    // a plain `<<"…">>` truncates to its low byte. The wat runtime decodes the
    // same lexeme in `wat.zig`'s `literalBytes`; both replies must agree.
    const src =
        \\fn smile(comptime decl: @Decl, comptime mark: string) {
        \\    val s = "<\u{263A}\u{e7}\u{1F600}>";
        \\    @emit("pub val smiled" + decl.name + " = \"" + s + mark + "\";");
        \\}
        \\#[smile("[\u{2028}\u{263A}]")]
        \\type Face(x: i32)
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.repliesIdenticalAcrossRuntimes(std.testing.allocator, arena.allocator(), @src(), &.{.{ .path = "", .source = src }});
    // U+263A, U+00E7, U+1F600, then the argument's U+2028, U+263A — each as
    // its UTF-8 bytes, the whole code point.
    const expected = "pub val smiledFace = \\\"<\xE2\x98\xBA\xC3\xA7\xF0\x9F\x98\x80>[\xE2\x80\xA8\xE2\x98\xBA]\\\";";
    for (replies) |r| {
        if (std.mem.indexOf(u8, r, expected) == null) {
            std.debug.print("\nexpected {s} in:\n{s}\n", .{ expected, r });
            return error.TestExpectedContains;
        }
    }
}

test "decorator invocation: method placement accepted" {
    try assertAccepts(@src(),
        \\fn getMapping(comptime decl: @Decl, comptime path: string) {
        \\    if (decl.kind != DeclKind.Method) { decl.fail("#[getMapping] must annotate a method"); }
        \\}
        \\behavior Routes {
        \\    #[getMapping("/users")]
        \\    fn index(self: Self) -> string;
        \\}
    );
}

test "decorator invocation: method decorator rejects a record" {
    try assertRejects(@src(),
        \\fn getMapping(comptime decl: @Decl, comptime path: string) {
        \\    if (decl.kind != DeclKind.Method) { decl.fail("#[getMapping] must annotate a method"); }
        \\}
        \\#[getMapping("/x")]
        \\type Nope()
    , "must annotate a method");
}

test "decorator invocation: body reads the reflected name" {
    try assertRejects(@src(),
        \\fn named(comptime decl: @Decl) {
        \\    if (decl.name == "Bad") { decl.fail("the name Bad is reserved"); }
        \\}
        \\#[named]
        \\type Bad()
    , "the name Bad is reserved");
}

test "decorator invocation: @compilerError rejects wrong placement" {
    // The generic compile-time error builtin — no `@Decl` handle needed — also
    // surfaces as a scoped rejection when the body runs.
    try assertRejects(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { @compilerError("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\fn notARecord() { }
    , "must annotate a type with fields");
}

test "decorator invocation: @compilerError body accepts the right placement" {
    try assertAccepts(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { @compilerError("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\type UserService(name: string)
    );
}

test "decorator invocation: decl.variants tells an enum-shaped type from a record" {
    // `DeclKind.Type` covers both shapes; `decl.variants` is empty for a record
    // and lists the variant names of an enum.
    try assertRejects(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { decl.fail("#[service] must annotate a type with fields"); };
        \\    if (decl.variants.length > 0) { decl.fail("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\type Mode { Fast, Slow }
    , "must annotate a type with fields");
}

test "decorator invocation: decl.variants is empty on a record" {
    try assertAccepts(@src(),
        \\fn service(comptime decl: @Decl) {
        \\    if (decl.kind != DeclKind.Type) { decl.fail("#[service] must annotate a type with fields"); };
        \\    if (decl.variants.length > 0) { decl.fail("#[service] must annotate a type with fields"); }
        \\}
        \\#[service]
        \\type UserService(name: string)
    );
}

// ── wiring contribution: a body emits generated declarations (P3) ──────────────

test "decorator invocation: @emit contributes a top-level declaration" {
    // The decorator body builds wiring as ordinary code; `@emit(source)` splices
    // it into the module, where it is inferred + emitted like hand-written decls.
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const src =
        \\fn singleton(comptime decl: @Decl) {
        \\    @emit("pub val wiredMarker = 99;");
        \\}
        \\#[singleton]
        \\type Service(x: i32)
    ;
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
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

test "decorator invocation: the body runs on the compilation target's runtime (decision 84)" {
    // `comptime.compile` chooses the runtime from the target name it is given,
    // so every driver — `botopink build`, `test`, and `check` — evaluates a
    // commonJS or wasm compilation's decorators on wat and an erlang or
    // no-target one on the BEAM; a driver cannot forget to select.
    const io = std.testing.io;
    const build_root = h.buildRootPathFromSrc(io, @src());
    const src =
        \\fn singleton(comptime decl: @Decl) {
        \\    @emit("pub val wiredMarker = 99;");
        \\}
        \\#[singleton]
        \\type Service(x: i32)
    ;
    const cases = [_]struct { target: ?[]const u8, lang: comptimeMod.trace.Lang }{
        .{ .target = "node", .lang = .wat },
        .{ .target = "wasm", .lang = .wat },
        .{ .target = "erlang", .lang = .beam },
        .{ .target = null, .lang = .beam },
    };
    for (cases) |c| {
        var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, c.target);
        defer session.deinit(std.testing.allocator);
        const outcome = session.outputs.items[0].outcome;
        try std.testing.expect(outcome == .ok);
        const traces = outcome.ok.comptime_traces;
        try std.testing.expect(traces.len > 0);
        for (traces) |t| try std.testing.expectEqual(c.lang, t.lang);
    }
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
        \\type Anchor(x: i32)
        \\fn useit() -> i32 { return makeThing(); }
    );
}

test "decorator invocation: interface-level marker runs over the interface" {
    // A marker on an interface reflects with `kind == Interface` and runs its body
    // (previously interface-level markers were silently skipped).
    try assertRejects(@src(),
        \\fn onlyRecords(comptime decl: @Decl) {
        \\    if (decl.kind == DeclKind.Behavior) { decl.fail("marker is not allowed on a behavior"); }
        \\}
        \\#[onlyRecords]
        \\behavior Repo { fn find(self: Self, id: i32) -> string; }
    , "not allowed on a behavior");
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
        \\    @emit("type Mock" + decl.name + "(\n  tag: string,\n) implement " + decl.name + " {\n" + methods + "}");
        \\    @emit("pub fn mock" + decl.name + "() -> " + decl.name + " { return Mock" + decl.name + "(tag: \"\"); }");
        \\}
        \\#[mock]
        \\behavior Counter { fn value(self: Self) -> i32; }
        \\fn useit() -> i32 { return mockCounter().value(); }
    );
}

test "decorator invocation: a helper of another module builds that module's record on both runtimes" {
    // A library's `#[page]` calls `routing`'s `segment.parseSegment`, which
    // builds a `Segment(…)`: the record travels into the decorator module with
    // the helper (`block_eval.typesReached`), and a method the body calls on
    // it with the type. The parent binary lowered `Seg(…)` as a call of an
    // undefined `Seg/2` — the decorator module did not compile on either
    // runtime ("call to undefined function Seg/2"), and `s.shout()` was a
    // method no primitive answers.
    const lib =
        \\pub type Seg(name: string, size: i32) {
        \\    pub fn shout(self: Self) -> string {
        \\        return self.name.toUpper();
        \\    }
        \\}
        \\pub fn parseSeg(raw: string) -> Seg {
        \\    return Seg(name: raw, size: raw.length());
        \\}
    ;
    const src =
        \\import {seg.parseSeg};
        \\fn page(comptime decl: @Decl) {
        \\    val s = parseSeg(decl.name);
        \\    @emit("pub fn seen" + decl.name + "() -> string { return \"" + s.shout() + s.size.toString() + "\"; }");
        \\}
        \\#[page]
        \\type Home(x: i32)
        \\val shown = seenHome();
    ;
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const replies = try h.repliesIdenticalAcrossRuntimes(std.testing.allocator, arena.allocator(), @src(), &.{
        .{ .path = "seg", .source = lib },
        .{ .path = "", .source = src },
    });
    for (replies) |r| {
        if (std.mem.indexOf(u8, r, "return \\\"HOME4\\\";") != null) return;
    }
    std.debug.print("\nno reply emits seenHome:\n", .{});
    for (replies) |r| std.debug.print("{s}\n", .{r});
    return error.TestExpectedContains;
}
