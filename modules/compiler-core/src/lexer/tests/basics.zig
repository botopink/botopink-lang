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

// A lone `&`, a `^` and a `'a'` used to stop the lexer with `UnexpectedCharacter`,
// which no parse error can name or locate. Each is a token now, refused by the
// parser by name (front 15 step 3: `bitwise-operator-absent`,
// `char-literal-absent`). `&&` is unchanged.

test "lexer: a single ampersand and a caret are tokens the parser refuses by name" {
    var l = Lexer.init("a & b ^ c && d");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.ampersand, tokens[1].kind);
    try std.testing.expectEqualStrings("&", tokens[1].lexeme);
    try std.testing.expectEqual(TokenKind.caret, tokens[3].kind);
    try std.testing.expectEqual(TokenKind.amperAmper, tokens[5].kind);
}

test "lexer: a character literal is one token, closed by the quote or the line" {
    var l = Lexer.init("'a' '\\'' 'ab\nx");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.charLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("'a'", tokens[0].lexeme);
    try std.testing.expectEqual(TokenKind.charLiteral, tokens[1].kind);
    try std.testing.expectEqualStrings("'\\''", tokens[1].lexeme);
    // Unterminated: the token ends at the line, and the next line lexes on.
    try std.testing.expectEqual(TokenKind.charLiteral, tokens[2].kind);
    try std.testing.expectEqualStrings("'ab", tokens[2].lexeme);
    try std.testing.expectEqual(TokenKind.identifier, tokens[3].kind);
    try std.testing.expectEqual(@as(usize, 2), tokens[3].line);
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

// ── Front 15 R3 — a `.` continues a number only before a digit ───────────────
//
// The guard used to be "the next character is not a `.`", which kept `1..9` a
// range and made every other `.` a fractional part: `42.toString()` lexed as
// the number `42.` followed by `toString`, so an integer literal could not
// receive a method while a string literal could.

test "lexer: a method on an integer literal is three tokens" {
    var l = Lexer.init("42.toString()");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("42", tokens[0].lexeme);
    try std.testing.expectEqual(TokenKind.dot, tokens[1].kind);
    try std.testing.expectEqual(TokenKind.identifier, tokens[2].kind);
    try std.testing.expectEqualStrings("toString", tokens[2].lexeme);
}

test "lexer: the float, range, separator and radix forms are unchanged" {
    var l = Lexer.init("1..9 1.5 1_000 1_000.5 1e10 1.0e10 1.5e-3 0xFF 0b1010 0o17");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // `1..9` — three tokens, the `..` intact.
    try std.testing.expectEqualStrings("1", tokens[0].lexeme);
    try std.testing.expectEqual(TokenKind.dotDot, tokens[1].kind);
    try std.testing.expectEqualStrings("9", tokens[2].lexeme);
    // Every remaining form is one number literal, lexeme intact.
    const rest = [_][]const u8{ "1.5", "1_000", "1_000.5", "1e10", "1.0e10", "1.5e-3", "0xFF", "0b1010", "0o17" };
    for (rest, 0..) |want, i| {
        try std.testing.expectEqual(TokenKind.numberLiteral, tokens[3 + i].kind);
        try std.testing.expectEqualStrings(want, tokens[3 + i].lexeme);
    }
}

test "lexer: a point with no digit after it is not part of the number" {
    // `t.0.first` — a tuple access chained off a tuple access. The `0.` used
    // to swallow the second `.`, so the chain was unreachable.
    var l = Lexer.init("t.0.first");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.dot, tokens[1].kind);
    try std.testing.expectEqualStrings("0", tokens[2].lexeme);
    try std.testing.expectEqual(TokenKind.dot, tokens[3].kind);
    try std.testing.expectEqualStrings("first", tokens[4].lexeme);
}

// ── Front 15 / decision 28 — `??` is a token ─────────────────────────────────

test "lexer: ?? is one token, and ? and ?. are unchanged" {
    var l = Lexer.init("a ?? b ?. c ?i32");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.questionQuestion, tokens[1].kind);
    try std.testing.expectEqual(TokenKind.questionDot, tokens[3].kind);
    try std.testing.expectEqual(TokenKind.questionMark, tokens[5].kind);
}
