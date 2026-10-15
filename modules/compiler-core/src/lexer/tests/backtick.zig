//! lexer: decision 561's backtick identifiers.

const std = @import("std");
const lexerFull = @import("../../lexer.zig");
const Lexer = lexerFull.Lexer;
const TokenKind = @import("../token.zig").TokenKind;
const LexicalErrorType = lexerFull.LexicalErrorType;

test "lexer: a backtick name that is no identifier keeps its backticks" {
    const source = "val `not-found` = 1;";
    var l = Lexer.init(source);
    defer l.deinit(std.testing.allocator);
    const tokens = try l.scanAll(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[1].kind);
    try std.testing.expectEqualStrings("`not-found`", tokens[1].lexeme);
    try std.testing.expectEqual(@as(usize, 4), tokens[1].offset);
    try std.testing.expectEqual(@as(usize, 5), tokens[1].col);
    try std.testing.expectEqual(TokenKind.equal, tokens[2].kind);
}

test "lexer: a keyword between backticks is an identifier" {
    var l = Lexer.init("`fn` `else` `_`");
    defer l.deinit(std.testing.allocator);
    const tokens = try l.scanAll(std.testing.allocator);
    for (tokens[0..3], [_][]const u8{ "`fn`", "`else`", "`_`" }) |t, want| {
        try std.testing.expectEqual(TokenKind.identifier, t.kind);
        try std.testing.expectEqualStrings(want, t.lexeme);
    }
}

test "lexer: `count` is the identifier count, located at its text" {
    const source = "x + `count`";
    var l = Lexer.init(source);
    defer l.deinit(std.testing.allocator);
    const tokens = try l.scanAll(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[2].kind);
    try std.testing.expectEqualStrings("count", tokens[2].lexeme);
    // `source[offset..offset + lexeme.len]` is the token's text.
    try std.testing.expectEqualStrings("count", source[tokens[2].offset..][0..tokens[2].lexeme.len]);
}

test "lexer: any bytes but a backtick and a line break, UTF-8 included" {
    var l = Lexer.init("`a b-c$'\"@ção`");
    defer l.deinit(std.testing.allocator);
    const tokens = try l.scanAll(std.testing.allocator);
    try std.testing.expectEqualStrings("`a b-c$'\"@ção`", tokens[0].lexeme);
    try std.testing.expectEqual(TokenKind.endOfFile, tokens[1].kind);
}

test "lexer: an empty backtick identifier is refused at its backticks" {
    var l = Lexer.init("val `` = 1;");
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, l.scanAll(std.testing.allocator));
    try std.testing.expectEqual(LexicalErrorType.EmptyBacktickIdentifier, l.lexError.?.kind);
    try std.testing.expectEqual(@as(usize, 4), l.lexError.?.start);
    try std.testing.expectEqual(@as(usize, 6), l.lexError.?.end);
}

test "lexer: a line break before the closing backtick is refused" {
    for ([_][]const u8{ "val `two\nlines` = 1;", "val `open", "val `cr\r\n`" }) |source| {
        var l = Lexer.init(source);
        defer l.deinit(std.testing.allocator);
        try std.testing.expectError(error.LexicalError, l.scanAll(std.testing.allocator));
        try std.testing.expectEqual(LexicalErrorType.UnclosedBacktickIdentifier, l.lexError.?.kind);
        try std.testing.expectEqual(@as(usize, 4), l.lexError.?.start);
    }
}

test "lexer: a backtick name's module segment and plain identifiers" {
    try std.testing.expectEqualStrings("not-found", lexerFull.unquotedName("`not-found`"));
    try std.testing.expectEqualStrings("count", lexerFull.unquotedName("count"));
    try std.testing.expect(lexerFull.isBacktickName("`a`"));
    try std.testing.expect(!lexerFull.isBacktickName("``"));
    try std.testing.expect(Lexer.isPlainIdentifier("count_2"));
    try std.testing.expect(!Lexer.isPlainIdentifier("fn"));
    try std.testing.expect(!Lexer.isPlainIdentifier("2x"));
    try std.testing.expect(!Lexer.isPlainIdentifier("not-found"));
}
