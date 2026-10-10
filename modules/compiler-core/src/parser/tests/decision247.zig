//! Decision 247 — numeric literal suffixes (1.0.11-beta `01-compiler/01-checker`
//! step 18): the lexer keeps the letters glued to a number in its token, the
//! parser names every spelling it refuses at the suffix, and
//! `lexer.splitNumber` is the one reading of the text.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const h = @import("helpers.zig");
const expectErrorAt = h.expectErrorAt;

fn expectSplit(lexeme: []const u8, digits: []const u8, suffix: []const u8, floating: bool) !void {
    const p = lexerMod.splitNumber(lexeme);
    try std.testing.expectEqualStrings(digits, p.digits);
    try std.testing.expectEqualStrings(suffix, p.suffix);
    try std.testing.expectEqual(floating, p.floating);
}

fn expectOneNumberToken(src: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    defer l.deinit(std.testing.allocator);
    const tokens = try l.scanAll(std.testing.allocator);
    try std.testing.expectEqual(lexerMod.TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings(src, tokens[0].lexeme);
}

test "decision 247: a suffix stays in the number's token" {
    for ([_][]const u8{ "1.5f", "1d", "42l", "42u", "42ul", "7i8", "7i16", "7u8", "7u16", "7isize", "7usize", "0xFFul", "0b101u8", "1_000l", "2.5e1d", "42L", "10px", "1e", "42n", "0xFFn" }) |src| try expectOneNumberToken(src);
}

test "decision 247: splitNumber separates digits and suffix" {
    try expectSplit("1.5f", "1.5", "f", true);
    try expectSplit("1d", "1", "d", false);
    try expectSplit("1_000ul", "1_000", "ul", false);
    try expectSplit("2.5e-3d", "2.5e-3", "d", true);
    try expectSplit("1e10", "1e10", "", true);
    try expectSplit("1e", "1", "e", false);
    // Hex digits win: `0x1f` is 31, `0x1ful` takes `ul` after them.
    try expectSplit("0x1f", "0x1f", "", false);
    try expectSplit("0x1ful", "0x1f", "ul", false);
    try expectSplit("0b1f", "0b1", "f", false);
    try expectSplit("123456789012345678901234567890n", "123456789012345678901234567890", "n", false);
    try expectSplit("0xFFn", "0xFF", "n", false);
}

test "decision 247: a suffix's type and the backend's text" {
    try std.testing.expectEqualStrings("f32", lexerMod.numberSuffixType("f").?);
    try std.testing.expectEqualStrings("u64", lexerMod.numberSuffixType("ul").?);
    try std.testing.expect(lexerMod.numberSuffixType("L") == null);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("1.0", try lexerMod.numberBackendText(a, "1d"));
    try std.testing.expectEqualStrings("1000.0", try lexerMod.numberBackendText(a, "1_000f"));
    try std.testing.expectEqualStrings("1.5", try lexerMod.numberBackendText(a, "1.5f"));
    try std.testing.expectEqualStrings("0xFF", try lexerMod.numberBackendText(a, "0xFFul"));
    try std.testing.expectEqualStrings("42", try lexerMod.numberBackendText(a, "42"));
}

test "decision 332: a bigint literal keeps its `n` for the backends" {
    try std.testing.expectEqualStrings("bigint", lexerMod.numberSuffixType("n").?);
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    try std.testing.expectEqualStrings("1_000n", try lexerMod.numberBackendText(a, "1_000n"));
    try std.testing.expect(lexerMod.isBigintText("42n"));
    try std.testing.expect(lexerMod.isBigintText("0xFFn"));
    try std.testing.expect(!lexerMod.isBigintText("42"));
    try std.testing.expect(!lexerMod.isBigintText("0xFF"));
    try std.testing.expectEqualStrings("0xFF", lexerMod.bigintDigits("0xFFn"));
    try std.testing.expectEqualStrings("42", lexerMod.bigintDigits("42"));
}

test "decision 247: every refused spelling is named at its suffix" {
    try expectErrorAt("val n = 42L;", .numberSuffixUppercase, 1, 11);
    try expectErrorAt("val n = 1.5F;", .numberSuffixUppercase, 1, 12);
    try expectErrorAt("val n = 2x;", .numberSuffixUnknown, 1, 10);
    try expectErrorAt("val n = 0b1f;", .numberSuffixFloatOnRadix, 1, 12);
    try expectErrorAt("val n = 0o7d;", .numberSuffixFloatOnRadix, 1, 12);
    try expectErrorAt("val n = 1.5u;", .numberSuffixIntegerOnFloat, 1, 12);
    try expectErrorAt("val n = 1e3l;", .numberSuffixIntegerOnFloat, 1, 12);
    // Decision 332 — `n` is an integer suffix: never on a fraction or an exponent.
    try expectErrorAt("val n = 1.5n;", .numberSuffixIntegerOnFloat, 1, 12);
    try expectErrorAt("val n = 1e3n;", .numberSuffixIntegerOnFloat, 1, 12);
    try expectErrorAt("val n = 42N;", .numberSuffixUppercase, 1, 11);
    try expectErrorAt("val n = 1e;", .numberExponentWithoutDigits, 1, 10);
    try expectErrorAt("val n = case x { 1L -> 1; _ -> 0; };", .numberSuffixUppercase, 1, 19);
}

test "decision 247: a member access on a literal still reads" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    for ([_][]const u8{ "val n = 42.toString();", "val n = 42u.toString();", "val n = 1.5f.toString();", "val n = t.0.1;" }) |src| {
        var l = lexerMod.Lexer.init(src);
        const tokens = try l.scanAll(a);
        var p = @import("../../parser.zig").Parser.initWithSource(tokens, src);
        _ = try p.parse(a);
    }
}
