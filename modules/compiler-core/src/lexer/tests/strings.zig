//! lexer: string literals, escapes, unicode (split from tests.zig).

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

test "lexer: string with valid escapes \\n \\r \\t \\\\ \\\" \\0" {
    var l = Lexer.init("\"\\n\\r\\t\\\\\\\"\\0\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: string with valid unicode \\u{41}" {
    var l = Lexer.init("\"\\u{41}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: string with valid unicode \\u{10FFFF}" {
    var l = Lexer.init("\"\\u{10FFFF}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: \\g is invalid escape ---- BadStringEscape" {
    var l = Lexer.init("\"\\g\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, 'g'), l.lexError.?.invalidChar);
}

test "lexer: \\q is invalid escape ---- BadStringEscape" {
    var l = Lexer.init("\"\\q\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lexError.?.kind);
}
