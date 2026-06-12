//! lexer: reserved words, self/Self, semicolons (split from tests.zig).

const std = @import("std");
const OhSnap = @import("ohsnap");
const Allocator = std.mem.Allocator;
const SourceLocation = std.builtin.SourceLocation;
const Lexer = @import("../../lexer.zig").Lexer;
const TokenKind = @import("../token.zig").TokenKind;
const lexerFull = @import("../../lexer.zig");
const LexicalErrorType = lexerFull.LexicalErrorType;
const InvalidUnicodeEscapeKind = lexerFull.InvalidUnicodeEscapeKind;
const parserFull = @import("../../parser.zig");
const h = @import("helpers.zig");

test "lexer: const is not a reserved keyword (use val instead)" {
    var l = Lexer.init("const");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // 'const' is no longer a surface keyword; it lexes as an identifier
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
}

test "lexer: Self (uppercase) is KwSelfType" {
    var l = Lexer.init("Self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.selfType, tokens[0].kind);
}

test "lexer: self (lowercase) is an identifier" {
    var l = Lexer.init("self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
    try std.testing.expectEqualStrings("self", tokens[0].lexeme);
}

test "lexer: semicolon is tokenized" {
    var l = Lexer.init("2 + 3;");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 5), tokens.len);
    try std.testing.expectEqual(TokenKind.semicolon, tokens[3].kind);
}

test "lexer: standalone semicolon is tokenized" {
    var l = Lexer.init(";");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), tokens.len);
    try std.testing.expectEqual(TokenKind.semicolon, tokens[0].kind);
}

test "lexer: 'auto' is recognized as KwAuto (reserved word)" {
    var l = Lexer.init("auto");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.auto, tokens[0].kind);
}

test "lexer: 'delegate' is recognized as KwDelegate (reserved word)" {
    var l = Lexer.init("delegate");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.delegate, tokens[0].kind);
}

test "lexer: 'echo' is recognized as KwEcho (reserved word)" {
    var l = Lexer.init("echo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.echo, tokens[0].kind);
}

test "lexer: 'implement' is recognized as implement (reserved word)" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.implement, tokens[0].kind);
}

test "lexer: 'macro' is recognized as macro (reserved word)" {
    var l = Lexer.init("macro");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.macro, tokens[0].kind);
}

test "lexer: 'derive' is recognized as KwDerive (reserved word)" {
    var l = Lexer.init("derive");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.derive, tokens[0].kind);
}

test "lexer: isReservedWord returns true for reserved words" {
    try std.testing.expect(lexerFull.isReservedWord(.auto));
    try std.testing.expect(lexerFull.isReservedWord(.delegate));
    try std.testing.expect(lexerFull.isReservedWord(.echo));
    try std.testing.expect(lexerFull.isReservedWord(.@"else"));
    try std.testing.expect(lexerFull.isReservedWord(.implement));
    try std.testing.expect(lexerFull.isReservedWord(.macro));
    try std.testing.expect(lexerFull.isReservedWord(.@"test"));
    try std.testing.expect(lexerFull.isReservedWord(.derive));
}

test "lexer: isReservedWord returns false for normal identifiers" {
    try std.testing.expect(!lexerFull.isReservedWord(.identifier));
    try std.testing.expect(!lexerFull.isReservedWord(.@"var"));
    try std.testing.expect(!lexerFull.isReservedWord(.@"const"));
    try std.testing.expect(!lexerFull.isReservedWord(.@"fn"));
    try std.testing.expect(!lexerFull.isReservedWord(.val));
}
