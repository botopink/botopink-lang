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

test "lexer: unknown is a keyword, not an identifier" {
    var l = Lexer.init("unknown");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // decision 8 §2 (06 N19): `unknown` names the type and nothing else, so it
    // is a keyword token and `isReservedWord` refuses it as a name.
    try std.testing.expectEqual(TokenKind.unknown, tokens[0].kind);
    try std.testing.expect(lexerFull.isReservedWord(.unknown));
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

test "lexer: 'delegate', 'new' and 'const' are identifiers (06 N27)" {
    for ([_][]const u8{ "delegate", "new", "const" }) |word| {
        var l = Lexer.init(word);
        const tokens = try l.scanAll(std.testing.allocator);
        defer l.deinit(std.testing.allocator);
        try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
    }
}

test "lexer: 'implement' is recognized as implement (reserved word)" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.implement, tokens[0].kind);
}

test "lexer: isReservedWord returns true for reserved words" {
    try std.testing.expect(lexerFull.isReservedWord(.@"else"));
    try std.testing.expect(lexerFull.isReservedWord(.implement));
    try std.testing.expect(lexerFull.isReservedWord(.@"test"));
}

test "lexer: isReservedWord returns false for normal identifiers" {
    try std.testing.expect(!lexerFull.isReservedWord(.identifier));
    try std.testing.expect(!lexerFull.isReservedWord(.@"var"));
    try std.testing.expect(!lexerFull.isReservedWord(.@"fn"));
    try std.testing.expect(!lexerFull.isReservedWord(.val));
}
