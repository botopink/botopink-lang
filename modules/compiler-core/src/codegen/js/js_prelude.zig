//! The commonJS runtime helpers, as built nodes.
//!
//! Most primitive methods lower to a native JS method or an inline host
//! template. A few native methods disagree with the botopink signature
//! (`"ab".charAt(5)` is `""` where `String.charAt` says `?string`), and those
//! need JavaScript of our own. It is never a shipped runtime file: only the
//! helper a module actually calls is written into that module, as a plain
//! function declaration built from `js_ast` nodes like any other.
//!
//! The shape is `codegen/wat/wat_prelude.zig`'s: a call site never spells a
//! helper's name — `Emitter.helper` in `commonJS.zig` hands out the symbol
//! **and** marks the helper for emission in one call, so a module cannot call a
//! helper it does not define.
//!
//! A helper answers a primitive *declaration* (`String.charAt`), which is the
//! identity every backend's lowering of that method shares.

const std = @import("std");
const ast = @import("js_ast.zig");

pub const Helper = enum {
    /// `assert cond, msg` outside test mode: always fatal, naming the message
    /// and the `file:line` (cross-backend semantics decision 4).
    assert_fatal,
    /// `String.charAt(i) -> ?string`: the character, or `null` out of range.
    string_char_at,
    /// An open-ended range `a..` used as a value: the lazy, unbounded
    /// sequence `a, a + 1, …` as a generator (a finite array cannot hold it).
    range_from,
};

/// Emission order of the helpers a module uses.
pub const order = [_]Helper{ .assert_fatal, .string_char_at, .range_from };

/// The receiver family of a primitive method call, as inference recorded it.
pub const Receiver = enum { string, array, other };

/// The helper that replaces the native method `method` on a `receiver`
/// value, or null when the native method (or the annotation's template)
/// already matches the signature.
pub fn forMethod(receiver: Receiver, method: []const u8, argc: usize) ?Helper {
    if (receiver == .string and argc == 1 and std.mem.eql(u8, method, "charAt")) return .string_char_at;
    return null;
}

/// The function name a call site uses.
pub fn name(h: Helper) []const u8 {
    return switch (h) {
        .assert_fatal => "__bp_assert_fatal",
        .string_char_at => "__bp_string_char_at",
        .range_from => "__bp_range_from",
    };
}

/// The helper's declaration.
pub fn decl(h: Helper) ast.Stmt {
    return switch (h) {
        .assert_fatal => assert_fatal,
        .string_char_at => string_char_at,
        .range_from => range_from,
    };
}

// ── the helpers ──────────────────────────────────────────────────────────────

const cond: ast.Expr = .{ .name = "cond" };
const msg: ast.Expr = .{ .name = "msg" };
const loc: ast.Expr = .{ .name = "loc" };

/// `function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? "assertion failed") + " at " + loc); } }`
const assert_fatal: ast.Stmt = .{ .function = .{
    .name = "__bp_assert_fatal",
    .params = &.{ .{ .pattern = .{ .name = "cond" } }, .{ .pattern = .{ .name = "msg" } }, .{ .pattern = .{ .name = "loc" } } },
    .body = .{ .stmts = &.{.{ .if_ = .{
        .cond = .{ .unary = .{ .op = "!", .operand = &cond, .parens = false } },
        .then = &.{ .block = .{ .stmts = &.{.{ .throw_ = .{ .new_ = .{
            .callee = &.{ .name = "Error" },
            .args = &.{.{ .binary = .{
                .op = "+",
                .lhs = &.{ .binary = .{
                    .op = "+",
                    .lhs = &.{ .binary = .{ .op = "??", .lhs = &msg, .rhs = &.{ .quoted = "assertion failed" } } },
                    .rhs = &.{ .quoted = " at " },
                    .parens = false,
                } },
                .rhs = &loc,
                .parens = false,
            } }},
        } } }}, .layout = .spaced } },
    } }}, .layout = .spaced },
} };

const s: ast.Expr = .{ .name = "s" };
const i: ast.Expr = .{ .name = "i" };
const zero: ast.Expr = .{ .number = "0" };
const s_length: ast.Expr = .{ .member = .{ .object = &s, .name = "length" } };
const s_char_at: ast.Expr = .{ .member = .{ .object = &s, .name = "charAt" } };

/// `function __bp_string_char_at(s, i) { return (i >= 0 && i < s.length) ? s.charAt(i) : null; }`
const string_char_at: ast.Stmt = .{ .function = .{
    .name = "__bp_string_char_at",
    .params = &.{ .{ .pattern = .{ .name = "s" } }, .{ .pattern = .{ .name = "i" } } },
    .body = .{ .stmts = &.{.{ .return_ = .{ .ternary = .{
        .cond = &.{ .paren = &.{ .binary = .{
            .op = "&&",
            .lhs = &.{ .binary = .{ .op = ">=", .lhs = &i, .rhs = &zero, .parens = false } },
            .rhs = &.{ .binary = .{ .op = "<", .lhs = &i, .rhs = &s_length, .parens = false } },
            .parens = false,
        } } },
        .then = &.{ .call = .{ .callee = &s_char_at, .args = &.{i} } },
        .else_ = &.null_,
    } } }}, .layout = .spaced },
} };

const n: ast.Expr = .{ .name = "n" };
const one: ast.Expr = .{ .number = "1" };

/// `function* __bp_range_from(n) { while (true) { yield n; n += 1; } }`
const range_from: ast.Stmt = .{ .function = .{
    .keyword = "function*",
    .name = "__bp_range_from",
    .params = &.{.{ .pattern = .{ .name = "n" } }},
    .body = .{ .stmts = &.{.{ .while_ = .{
        .cond = .{ .name = "true" },
        .body = .{ .stmts = &.{
            .{ .expr = .{ .yield_ = &n } },
            .{ .expr = .{ .assign = .{ .target = &n, .op = "+=", .value = &one } } },
        }, .layout = .spaced },
    } }}, .layout = .spaced },
} };

test "js_prelude: an open-ended range counts up lazily" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.range_from), 0);
    try std.testing.expectEqualStrings(
        "function* __bp_range_from(n) { while (true) { yield n; n += 1; } }",
        aw.written(),
    );
}

test "js_prelude: a failed assert throws with its message and location" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.assert_fatal), 0);
    try std.testing.expectEqualStrings(
        "function __bp_assert_fatal(cond, msg, loc) { if (!cond) { throw new Error((msg ?? \"assertion failed\") + \" at \" + loc); } }",
        aw.written(),
    );
}

test "js_prelude: charAt answers null out of range" {
    var aw: std.Io.Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try @import("js_emitter.zig").writeStmt(&aw.writer, decl(.string_char_at), 0);
    try std.testing.expectEqualStrings(
        "function __bp_string_char_at(s, i) { return (i >= 0 && i < s.length) ? s.charAt(i) : null; }",
        aw.written(),
    );
    try std.testing.expectEqual(Helper.string_char_at, forMethod(.string, "charAt", 1).?);
    try std.testing.expect(forMethod(.array, "charAt", 1) == null);
}
