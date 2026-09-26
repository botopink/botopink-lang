//! comptime: decorator REGRESSION tests.
//!
//! These tests guard against regressions in decorator body evaluation after
//! the fixes in step-1 (decorator eval) and step-2 (allocation leaks).
//!
//! Each test proves the lowering it names, not only that the body evaluated
//! (specs/1.0.4-beta/05-cli-residuals/mutation-matrix.md): a rejecting fixture
//! proves the failure path and is compared on the **whole** message; an
//! accepting fixture over the same decorator body proves the lowering computed
//! a real value, and asserts the shape the body lowered to
//! (`OkData.comptime_traces`) — on the BEAM runtime the listing is the BEAM
//! assembly that was loaded, so a lowering shows as the call it makes
//! (`{extfunc, lists, foreach, 2}` for `lists:foreach/2`). A mutation of the lowering that keeps a single
//! bit ("the first element is visited", "the length is greater than five")
//! reds one of the two.

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

/// The decorator body is accepted, and the BEAM assembly it lowered to contains
/// `lowering` (e.g. `{extfunc, lists, foreach, 2}`) — the lowering the test guards.
fn assertAccepts(comptime loc: std.builtin.SourceLocation, src: []const u8, lowering: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    if (outcome == .typeError) {
        const desc = try h.renderTypeError(std.testing.allocator, src, outcome.typeError);
        defer std.testing.allocator.free(desc);
        std.debug.print("\nunexpected decorator rejection:\n{s}\n", .{desc});
    }
    try std.testing.expect(outcome == .ok);
    try expectLowering(outcome.ok.comptime_traces, lowering);
}

/// Like `assertAccepts`, and the runtime's reply is exactly `reply` — for a
/// decorator whose effect is what it contributes (`@emit`).
fn assertAcceptsWithReply(comptime loc: std.builtin.SourceLocation, src: []const u8, lowering: []const u8, reply: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    try std.testing.expect(outcome == .ok);
    try expectLowering(outcome.ok.comptime_traces, lowering);
    for (outcome.ok.comptime_traces) |e| {
        if (e.kind == .decorator) return std.testing.expectEqualStrings(reply, e.reply);
    }
    return error.TestExpectedDecoratorTrace;
}

fn expectLowering(traces: []const comptimeMod.trace.Entry, lowering: []const u8) !void {
    for (traces) |e| {
        if (e.kind == .decorator and std.mem.indexOf(u8, e.listing, lowering) != null) return;
    }
    std.debug.print("\nno decorator lowered through \"{s}\"; generated:\n", .{lowering});
    for (traces) |e| std.debug.print("{s}\n", .{e.listing});
    return error.TestExpectedLowering;
}

/// The decorator rejects the declaration with exactly `expected` as its message.
fn assertRejects(comptime loc: std.builtin.SourceLocation, src: []const u8, expected: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
    var session = try comptimeMod.compile(std.testing.allocator, &.{.{ .path = "", .source = src }}, io, build_root, null);
    defer session.deinit(std.testing.allocator);
    const outcome = session.outputs.items[0].outcome;
    if (outcome != .typeError) {
        std.debug.print("\nexpected the decorator to reject with \"{s}\", got outcome .{s}\n", .{ expected, @tagName(outcome) });
        return error.TestUnexpectedResult;
    }
    // Compare the diagnostic's own message, not the rendered report: the report
    // quotes the source, where the expected text appears as a string literal.
    const message = try outcome.typeError.message(std.testing.allocator);
    defer std.testing.allocator.free(message);
    try std.testing.expectEqualStrings(expected, message);
}

// ── regression: loop in body ──────────────────────────────────────────────────
//
// Guards `arrayPrimFallbackNode`'s `forEach` arm (`lists:foreach/2` over every
// element): the offending field first, the offending field last, and none.

const loop_decorator =
    \\fn validate(comptime decl: @Decl) {
    \\    decl.fields.forEach({ f ->
    \\        if (f.name == "bad") { decl.fail("field 'bad' not allowed"); }
    \\    });
    \\}
;

test "decorator regression: loop in body" {
    try assertRejects(@src(), loop_decorator ++
        \\
        \\#[validate]
        \\type HasBad(bad: string, good: i32)
    , "field 'bad' not allowed");
}

test "decorator regression: loop in body visits the last element" {
    try assertRejects(@src(), loop_decorator ++
        \\
        \\#[validate]
        \\type HasBadLast(good: i32, other: i32, bad: string)
    , "field 'bad' not allowed");
}

test "decorator regression: loop in body accepts a clean record through lists:foreach" {
    try assertAccepts(@src(), loop_decorator ++
        \\
        \\#[validate]
        \\type AllGood(good: i32, fine: string)
    , "{extfunc, lists, foreach, 2}");
}

// ── regression: conditional in body ───────────────────────────────────────────
//
// Guards `.len` → `'__bp_len'/2` and its `is_list` clause (`length(X)`): six
// fields reject, five (the `5 > 5` boundary) and three accept — no constant
// length satisfies all three.

const conditional_decorator =
    \\fn checkFields(comptime decl: @Decl) {
    \\    if (decl.kind == DeclKind.Type) {
    \\        if (decl.fields.len > 5) {
    \\            decl.fail("too many fields");
    \\        }
    \\    }
    \\}
;

test "decorator regression: conditional in body" {
    try assertRejects(@src(), conditional_decorator ++
        \\
        \\#[checkFields]
        \\type TooMany(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32)
    , "too many fields");
}

test "decorator regression: conditional in body accepts exactly five fields" {
    try assertAccepts(@src(), conditional_decorator ++
        \\
        \\#[checkFields]
        \\type Five(a: i32, b: i32, c: i32, d: i32, e: i32)
    , "{extfunc, bp_comptime_decorator, '__bp_len', 2}");
}

test "decorator regression: conditional in body accepts three fields" {
    try assertAccepts(@src(), conditional_decorator ++
        \\
        \\#[checkFields]
        \\type Three(a: i32, b: i32, c: i32)
    , "{extfunc, bp_comptime_decorator, '__bp_len', 2}");
}

// ── regression: string concat in body ─────────────────────────────────────────
//
// Guards `bindExpr`'s `Name@N` versioning and the `is_binary/is_binary` clause
// of `'__bp_add'/2`: the whole message is compared, so a lowering that appends
// or truncates reds.

const concat_decorator =
    \\fn nameCheck(comptime decl: @Decl) {
    \\    var msg = "invalid name: ";
    \\    msg = msg + decl.name;
    \\    if (decl.name == "Forbidden") { decl.fail(msg); }
    \\}
;

test "decorator regression: string concat in body" {
    try assertRejects(@src(), concat_decorator ++
        \\
        \\#[nameCheck]
        \\type Forbidden(x: i32)
    , "invalid name: Forbidden");
}

test "decorator regression: string concat in body accepts another name through '__bp_add'" {
    try assertAccepts(@src(), concat_decorator ++
        \\
        \\#[nameCheck]
        \\type Allowed(x: i32)
    , "{extfunc, bp_comptime_decorator, '__bp_add', 2}");
}

// ── regression: @emit in body ─────────────────────────────────────────────────
//
// Guards the `@emit` contribution pipeline and `+` → `'__bp_add'/2` in the
// untyped path: the contributed source text is asserted exactly, not only that
// the module compiles.

test "decorator regression: @emit in body" {
    try assertAcceptsWithReply(@src(),
        \\fn addHelper(comptime decl: @Decl) {
        \\    @emit("pub fn helper_" + decl.name + "() -> i32 { return 42; }");
        \\}
        \\#[addHelper]
        \\type Service(x: i32)
        \\fn useHelper() -> i32 { return helper_Service(); }
    , "{extfunc, bp_comptime_decorator, '__bp_add', 2}",
        \\{"kind":"ok","contributions":["pub fn helper_Service() -> i32 { return 42; }"]}
    );
}

// ── regression: accumulator fold fusion ───────────────────────────────────────
//
// Guards `detectFoldFusion` / `foldFusionExpr`: `var acc = init;` immediately
// followed by a `forEach` that reassigns it lowers to `lists:foldl/3`. A fusion
// that discards the accumulator leaves `count` at 0 and the six-field record is
// accepted.

const fold_decorator =
    \\fn countFields(comptime decl: @Decl) {
    \\    var count = 0;
    \\    decl.fields.forEach({ f -> count = count + 1; });
    \\    if (count > 5) { decl.fail("too many fields"); }
    \\}
;

test "decorator regression: fold fusion counts every element" {
    try assertRejects(@src(), fold_decorator ++
        \\
        \\#[countFields]
        \\type TooMany(a: i32, b: i32, c: i32, d: i32, e: i32, f: i32)
    , "too many fields");
}

test "decorator regression: fold fusion accepts five fields through lists:foldl" {
    try assertAccepts(@src(), fold_decorator ++
        \\
        \\#[countFields]
        \\type Five(a: i32, b: i32, c: i32, d: i32, e: i32)
    , "{extfunc, lists, foldl, 3}");
}
