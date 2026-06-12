//! lexer: single-token recognition (split from tests.zig).

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

test "lexer: recognizes identifier" {
    var l = Lexer.init("myVar");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
    try std.testing.expectEqualStrings("myVar", tokens[0].lexeme);
}

test "lexer: recognizes string literal" {
    var l = Lexer.init("\"my-lib\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: recognizes number literal integer" {
    var l = Lexer.init("42");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("42", tokens[0].lexeme);
}

test "lexer: recognizes number literal zero" {
    var l = Lexer.init("0");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0", tokens[0].lexeme);
}

test "lexer: recognizes number literal float" {
    var l = Lexer.init("3.14");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("3.14", tokens[0].lexeme);
}

test "lexer: recognizes all grouping tokens" {
    var l = Lexer.init("( ) [ ] { }");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{ .leftParenthesis, .rightParenthesis, .leftSquareBracket, .rightSquareBracket, .leftBrace, .rightBrace, .endOfFile };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: recognizes lParen" {
    var l = Lexer.init("(");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.leftParenthesis, tokens[0].kind);
}

test "lexer: recognizes rParen" {
    var l = Lexer.init(")");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.rightParenthesis, tokens[0].kind);
}

test "lexer: recognizes lSquare" {
    var l = Lexer.init("[");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.leftSquareBracket, tokens[0].kind);
}

test "lexer: recognizes rSquare" {
    var l = Lexer.init("]");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.rightSquareBracket, tokens[0].kind);
}

test "lexer: recognizes lBrace" {
    var l = Lexer.init("{");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.leftBrace, tokens[0].kind);
}

test "lexer: recognizes rBrace" {
    var l = Lexer.init("}");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.rightBrace, tokens[0].kind);
}

test "lexer: recognizes plus" {
    var l = Lexer.init("+");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.plus, tokens[0].kind);
    try std.testing.expectEqualStrings("+", tokens[0].lexeme);
}

test "lexer: recognizes Minus" {
    var l = Lexer.init("-");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.minus, tokens[0].kind);
    try std.testing.expectEqualStrings("-", tokens[0].lexeme);
}

test "lexer: recognizes Star" {
    var l = Lexer.init("*");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.star, tokens[0].kind);
    try std.testing.expectEqualStrings("*", tokens[0].lexeme);
}

test "lexer: recognizes Slash" {
    var l = Lexer.init("/");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.slash, tokens[0].kind);
    try std.testing.expectEqualStrings("/", tokens[0].lexeme);
}

test "lexer: recognizes Less" {
    var l = Lexer.init("<");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.lessThan, tokens[0].kind);
    try std.testing.expectEqualStrings("<", tokens[0].lexeme);
}

test "lexer: recognizes greater" {
    var l = Lexer.init(">");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.greaterThan, tokens[0].kind);
    try std.testing.expectEqualStrings(">", tokens[0].lexeme);
}

test "lexer: recognizes LessEqual" {
    var l = Lexer.init("<=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.lessThanEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("<=", tokens[0].lexeme);
}

test "lexer: recognizes greaterEqual" {
    var l = Lexer.init(">=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.greaterThanEqual, tokens[0].kind);
    try std.testing.expectEqualStrings(">=", tokens[0].lexeme);
}

test "lexer: recognizes Percent" {
    var l = Lexer.init("%");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.percent, tokens[0].kind);
    try std.testing.expectEqualStrings("%", tokens[0].lexeme);
}

test "lexer: recognizes colon" {
    var l = Lexer.init(":");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.colon, tokens[0].kind);
}

test "lexer: recognizes Comma" {
    var l = Lexer.init(",");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.comma, tokens[0].kind);
}

test "lexer: recognizes Hash" {
    var l = Lexer.init("#");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.hash, tokens[0].kind);
    try std.testing.expectEqualStrings("#", tokens[0].lexeme);
}

test "lexer: recognizes bang alone" {
    var l = Lexer.init("!");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.bang, tokens[0].kind);
    try std.testing.expectEqualStrings("!", tokens[0].lexeme);
}

test "lexer: recognizes Equal" {
    var l = Lexer.init("=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equal, tokens[0].kind);
    try std.testing.expectEqualStrings("=", tokens[0].lexeme);
}

test "lexer: recognizes EqualEqual" {
    var l = Lexer.init("==");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equalEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("==", tokens[0].lexeme);
}

test "lexer: recognizes NotEqual" {
    var l = Lexer.init("!=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.notEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("!=", tokens[0].lexeme);
}

test "lexer: recognizes Vbar" {
    var l = Lexer.init("|");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.verticalBar, tokens[0].kind);
    try std.testing.expectEqualStrings("|", tokens[0].lexeme);
}

test "lexer: recognizes VbarVbar" {
    var l = Lexer.init("||");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.verticalBarVerticalBar, tokens[0].kind);
    try std.testing.expectEqualStrings("||", tokens[0].lexeme);
}

test "lexer: recognizes AmperAmper" {
    var l = Lexer.init("&&");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.amperAmper, tokens[0].kind);
    try std.testing.expectEqualStrings("&&", tokens[0].lexeme);
}

test "lexer: recognizes LtLt" {
    var l = Lexer.init("<<");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.lessThanLessThan, tokens[0].kind);
    try std.testing.expectEqualStrings("<<", tokens[0].lexeme);
}

test "lexer: recognizes GtGt" {
    var l = Lexer.init(">>");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.greaterThanGreaterThan, tokens[0].kind);
    try std.testing.expectEqualStrings(">>", tokens[0].lexeme);
}

test "lexer: recognizes Pipe (|>)" {
    var l = Lexer.init("|>");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.pipe, tokens[0].kind);
    try std.testing.expectEqualStrings("|>", tokens[0].lexeme);
}

test "lexer: recognizes Dot" {
    var l = Lexer.init(".");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.dot, tokens[0].kind);
    try std.testing.expectEqualStrings(".", tokens[0].lexeme);
}

test "lexer: recognizes rArrow (->)" {
    var l = Lexer.init("->");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.rightArrow, tokens[0].kind);
    try std.testing.expectEqualStrings("->", tokens[0].lexeme);
}

test "lexer: recognizes DotDot (..)" {
    var l = Lexer.init("..");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.dotDot, tokens[0].kind);
    try std.testing.expectEqualStrings("..", tokens[0].lexeme);
}

test "lexer: recognizes At (@)" {
    var l = Lexer.init("@");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.at, tokens[0].kind);
    try std.testing.expectEqualStrings("@", tokens[0].lexeme);
}

test "lexer: recognizes plusEq (+=)" {
    var l = Lexer.init("+=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.plusEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("+=", tokens[0].lexeme);
}

test "lexer: recognizes normal comment" {
    var l = Lexer.init("// hello world");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.commentNormal, tokens[0].kind);
    try std.testing.expectEqualStrings("// hello world", tokens[0].lexeme);
}

test "lexer: recognizes doc comment ///" {
    var l = Lexer.init("/// type or function doc");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.commentDoc, tokens[0].kind);
    try std.testing.expectEqualStrings("/// type or function doc", tokens[0].lexeme);
}

test "lexer: recognizes module doc comment ////" {
    var l = Lexer.init("//// module doc");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.commentModule, tokens[0].kind);
    try std.testing.expectEqualStrings("//// module doc", tokens[0].lexeme);
}

test "lexer: recognizes keyword as" {
    var l = Lexer.init("as");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.as, tokens[0].kind);
}

test "lexer: recognizes keyword assert" {
    var l = Lexer.init("assert");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.assert, tokens[0].kind);
}

test "lexer: recognizes keyword auto" {
    var l = Lexer.init("auto");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.auto, tokens[0].kind);
}

test "lexer: recognizes keyword case" {
    var l = Lexer.init("case");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.case, tokens[0].kind);
}

test "lexer: recognizes keyword delegate" {
    var l = Lexer.init("delegate");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.delegate, tokens[0].kind);
}

test "lexer: recognizes keyword derive" {
    var l = Lexer.init("derive");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.derive, tokens[0].kind);
}

test "lexer: recognizes keyword echo" {
    var l = Lexer.init("echo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.echo, tokens[0].kind);
}

test "lexer: recognizes keyword else" {
    var l = Lexer.init("else");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"else", tokens[0].kind);
}

test "lexer: recognizes keyword from" {
    var l = Lexer.init("from");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.from, tokens[0].kind);
}

test "lexer: recognizes keyword fn" {
    var l = Lexer.init("fn");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"fn", tokens[0].kind);
}

test "lexer: recognizes keyword get" {
    var l = Lexer.init("get");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.get, tokens[0].kind);
}

test "lexer: recognizes keyword if" {
    var l = Lexer.init("if");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"if", tokens[0].kind);
}

test "lexer: recognizes keyword implement" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.implement, tokens[0].kind);
}

test "lexer: recognizes keyword import" {
    var l = Lexer.init("import");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.import, tokens[0].kind);
}

test "lexer: recognizes keyword macro" {
    var l = Lexer.init("macro");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.macro, tokens[0].kind);
}

test "lexer: recognizes keyword new" {
    var l = Lexer.init("new");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.new, tokens[0].kind);
}

test "lexer: recognizes keyword opaque" {
    var l = Lexer.init("opaque");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"opaque", tokens[0].kind);
}

test "lexer: recognizes keyword private" {
    var l = Lexer.init("private");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.private, tokens[0].kind);
}

test "lexer: recognizes keyword pub" {
    var l = Lexer.init("pub");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"pub", tokens[0].kind);
}

test "lexer: recognizes keyword return" {
    var l = Lexer.init("return");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"return", tokens[0].kind);
}

test "lexer: recognizes keyword set" {
    var l = Lexer.init("set");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.set, tokens[0].kind);
}

test "lexer: recognizes keyword struct" {
    var l = Lexer.init("struct");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"struct", tokens[0].kind);
}

test "lexer: recognizes keyword test" {
    var l = Lexer.init("test");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"test", tokens[0].kind);
}

test "lexer: recognizes keyword throw" {
    var l = Lexer.init("throw");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.throw, tokens[0].kind);
}

test "lexer: recognizes keyword interface" {
    var l = Lexer.init("interface");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.interface, tokens[0].kind);
}

test "lexer: recognizes keyword type" {
    var l = Lexer.init("type");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.type, tokens[0].kind);
}

test "lexer: recognizes keyword use" {
    var l = Lexer.init("use");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.use, tokens[0].kind);
}

test "lexer: recognizes keyword val" {
    var l = Lexer.init("val");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.val, tokens[0].kind);
}

test "lexer: recognizes keyword record" {
    var l = Lexer.init("record");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.record, tokens[0].kind);
}

test "lexer: recognizes keyword implementations" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.implement, tokens[0].kind);
}

test "lexer: recognizes keyword for" {
    var l = Lexer.init("for");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.@"for", tokens[0].kind);
}
