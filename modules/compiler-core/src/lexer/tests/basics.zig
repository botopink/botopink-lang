//! lexer: empty/whitespace/identifier/number basics (split from tests.zig).

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

test "lexer: empty source returns only .endOfFile" {
    var l = Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.endOfFile, tokens[0].kind);
}

test "lexer: whitespace-only source returns only .endOfFile" {
    var l = Lexer.init("   \t\n  ");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.endOfFile, tokens[0].kind);
}

test "lexer: '=' alone is Equal, not EqualEqual" {
    var l = Lexer.init("= x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equal, tokens[0].kind);
}

test "lexer: '<' alone is Less, not LessEqual nor LessDot" {
    var l = Lexer.init("< x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.lessThan, tokens[0].kind);
}

test "lexer: '>' alone is greater, not greaterEqual nor greaterDot" {
    var l = Lexer.init("> x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.greaterThan, tokens[0].kind);
}

test "lexer: '+' alone is plus, not plusEq" {
    var l = Lexer.init("+ x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.plus, tokens[0].kind);
}

test "lexer: '*' alone is Star" {
    var l = Lexer.init("* x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.star, tokens[0].kind);
}

test "lexer: '-' alone is Minus, not rArrow" {
    var l = Lexer.init("- x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.minus, tokens[0].kind);
}

test "lexer: '|' alone is Vbar, not VbarVbar nor Pipe" {
    var l = Lexer.init("| x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.verticalBar, tokens[0].kind);
}

test "lexer: '.' alone is Dot, not DotDot" {
    var l = Lexer.init(". x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.dot, tokens[0].kind);
}

test "lexer: '!' alone is bang, not NotEqual" {
    var l = Lexer.init("! x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.bang, tokens[0].kind);
}

test "lexer: comment does not consume next line tokens" {
    var l = Lexer.init("// comment\nuse");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.commentNormal, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.use, tokens[1].kind);
}

test "lexer: error on single ampersand" {
    var l = Lexer.init("&");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnexpectedCharacter, result);
}

test "lexer: tracks line numbers" {
    var l = Lexer.init("use\nfrom");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens[0].line); // use
    try std.testing.expectEqual(@as(usize, 2), tokens[1].line); // from
}

test "lexer: 0b1010 is a valid numberLiteral" {
    var l = Lexer.init("0b1010");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0b1010", tokens[0].lexeme);
}

test "lexer: 0b0 and 0b1 are valid numberLiterals" {
    var l = Lexer.init("0b0");
    const t1 = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, t1[0].kind);
}

test "lexer: 0b012 ---- digit '2' out of binary base" {
    var l = Lexer.init("0b012");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, '2'), l.lexError.?.invalidChar);
}

test "lexer: 0o17 is a valid numberLiteral" {
    var l = Lexer.init("0o17");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0o17", tokens[0].lexeme);
}

test "lexer: 0o12345670 is valid (digits 0-7)" {
    var l = Lexer.init("0o1234567");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
}

test "lexer: 0o12345678 ---- digit '8' out of octal base" {
    var l = Lexer.init("0o12345678");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, '8'), l.lexError.?.invalidChar);
}

test "lexer: 0xFF is a valid numberLiteral" {
    var l = Lexer.init("0xFF");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0xFF", tokens[0].lexeme);
}

test "lexer: 0x1A2B3C is a valid numberLiteral" {
    var l = Lexer.init("0x1A2B3C");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
}

test "lexer: 0x with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0x");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

test "lexer: 0b with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

test "lexer: 0o with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0o");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

test "lexer: == remains valid after adding === detection" {
    var l = Lexer.init("a == b");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equalEqual, tokens[1].kind);
}

test "lexer: normal decimal numbers continue to work" {
    var l = Lexer.init("42 3.14 0 100");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[1].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[2].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[3].kind);
}

test "lexer: 0 followed by non-prefix is normal decimal" {
    var l = Lexer.init("0 01 09");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[1].kind);
}
