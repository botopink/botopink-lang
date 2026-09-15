//! comptime: decorator REGRESSION tests.
//!
//! These tests guard against regressions in decorator body evaluation after
//! the fixes in step-1 (decorator eval) and step-2 (allocation leaks).

const std = @import("std");
const comptimeMod = @import("../../comptime.zig");
const h = @import("helpers.zig");

fn assertAccepts(comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
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
}

fn assertRejects(comptime loc: std.builtin.SourceLocation, src: []const u8, needle: []const u8) !void {
    const io = std.testing.io;
    const build_root = comptime h.buildRootPathFromSrc(loc);
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
}

// ── regression: loop in body ──────────────────────────────────────────────────

test "decorator regression: loop in body" {
    // A decorator body that uses forEach over fields — guards against regressions
    // in loop evaluation within the erl comptime runtime.
    try assertRejects(@src(),
        \\fn validate(comptime decl: @Decl) {
        \\    decl.fields.forEach({ f ->
        \\        if (f.name == "bad") { decl.fail("field 'bad' not allowed"); }
        \\    });
        \\}
        \\#[validate]
        \\record HasBad { bad: string, good: i32 }
    , "field 'bad' not allowed");
}

// ── regression: conditional in body ───────────────────────────────────────────

test "decorator regression: conditional in body" {
    // A decorator body with nested conditionals — guards against regressions in
    // if/else evaluation within the erl comptime runtime.
    try assertRejects(@src(),
        \\fn checkFields(comptime decl: @Decl) {
        \\    if (decl.kind == DeclKind.Record) {
        \\        if (decl.fields.len > 5) {
        \\            decl.fail("too many fields");
        \\        }
        \\    }
        \\}
        \\#[checkFields]
        \\record TooMany { a: i32, b: i32, c: i32, d: i32, e: i32, f: i32 }
    , "too many fields");
}

// ── regression: string concat in body ─────────────────────────────────────────

test "decorator regression: string concat in body" {
    // A decorator body that builds error messages via string concatenation —
    // guards against regressions in string operations within the erl runtime.
    try assertRejects(@src(),
        \\fn nameCheck(comptime decl: @Decl) {
        \\    var msg = "invalid name: ";
        \\    msg = msg + decl.name;
        \\    if (decl.name == "Forbidden") { decl.fail(msg); }
        \\}
        \\#[nameCheck]
        \\record Forbidden { x: i32 }
    , "invalid name: Forbidden");
}

// ── regression: @emit in body ─────────────────────────────────────────────────

test "decorator regression: @emit in body" {
    // A decorator body that uses @emit to contribute declarations — guards
    // against regressions in the @emit contribution pipeline.
    try assertAccepts(@src(),
        \\fn addHelper(comptime decl: @Decl) {
        \\    @emit("pub fn helper_" + decl.name + "() -> i32 { return 42; }");
        \\}
        \\#[addHelper]
        \\record Service { x: i32 }
        \\fn useHelper() -> i32 { return helper_Service(); }
    );
}
