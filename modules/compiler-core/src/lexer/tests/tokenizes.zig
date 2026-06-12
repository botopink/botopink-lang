//! lexer: multi-token sequences (split from tests.zig).

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

test "lexer: tokenizes arithmetic expression" {
    var l = Lexer.init("a + b - c * d / e % f");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .plus,    .identifier, .minus,
        .identifier, .star,    .identifier, .slash,
        .identifier, .percent, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes comparison chain" {
    var l = Lexer.init("a < b <= c > d >= e == f != g");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // a  <   b  <=   c   >   d  >=   e  ==   f  !=   g  EOF
    const expected = [_]TokenKind{
        .identifier,    .lessThan,         .identifier,
        .lessThanEqual, .identifier,       .greaterThan,
        .identifier,    .greaterThanEqual, .identifier,
        .equalEqual,    .identifier,       .notEqual,
        .identifier,    .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes logical operators" {
    var l = Lexer.init("a && b || c");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .amperAmper, .identifier, .verticalBarVerticalBar, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes bitshift operators" {
    var l = Lexer.init("a << b >> c");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .lessThanLessThan, .identifier, .greaterThanGreaterThan, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes pipe operator" {
    var l = Lexer.init("x |> f |> g");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .pipe, .identifier, .pipe, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes arrow and range" {
    var l = Lexer.init("x -> y .. z");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .rightArrow, .identifier, .dotDot, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes string concatenation with plus" {
    var l = Lexer.init("\"hello\" + \" world\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .stringLiteral, .plus, .stringLiteral, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes struct field declaration" {
    var l = Lexer.init("val _balance: number = 0");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .val, .identifier, .colon, .identifier, .equal, .numberLiteral, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes getter signature" {
    var l = Lexer.init("get balance(self: Self): number");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .get, .identifier, .leftParenthesis, .identifier, .colon, .selfType, .rightParenthesis, .colon, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes self field plus-eq" {
    var l = Lexer.init("self._balance += amount");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .identifier, .dot, .identifier, .plusEqual, .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes throw new expression" {
    var l = Lexer.init("throw new Error(\"msg\")");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .throw, .new, .identifier, .leftParenthesis, .stringLiteral, .rightParenthesis, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes record header" {
    var l = Lexer.init("val GPSCoordinates = record { lat: number, lon: number }");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .val,        .identifier, .equal,      .record,    .leftBrace,
        .identifier, .colon,      .identifier, .comma,     .identifier,
        .colon,      .identifier, .rightBrace, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes implement header" {
    var l = Lexer.init("val Cameraimplement = implement UsbCharger, SolarCharger for SmartCamera");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .val,        .identifier, .equal,      .implement,
        .identifier, .comma,      .identifier, .@"for",
        .identifier, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes qualified implement method name" {
    var l = Lexer.init("fn UsbCharger.Conectar(self: Self)");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .@"fn",            .identifier, .dot,   .identifier,
        .leftParenthesis,  .identifier, .colon, .selfType,
        .rightParenthesis, .endOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}
