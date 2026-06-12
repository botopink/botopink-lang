//! lexer: error tokens & cross-stage error-message units (split from tests.zig).

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

test "lexer: unterminated string" {
    var l = Lexer.init("\"no closing quote");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnterminatedString, result);
}

test "lexer: \\u{z} ---- ExpectedHexDigitOrCloseBrace" {
    var l = Lexer.init("\"\\u{z}\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lexError.?.kind);
    try std.testing.expectEqual(
        @as(?InvalidUnicodeEscapeKind, .ExpectedHexDigitOrCloseBrace),
        l.lexError.?.unicodeKind,
    );
}

test "lexer: \\u{110000} ---- InvalidCodepoint (acima de U+10FFFF)" {
    var l = Lexer.init("\"\\u{110000}\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lexError.?.kind);
    try std.testing.expectEqual(
        @as(?InvalidUnicodeEscapeKind, .InvalidCodepoint),
        l.lexError.?.unicodeKind,
    );
}

test "lexer: \\u sem chave ---- MissingOpenBrace" {
    var l = Lexer.init("\"\\uABCD\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lexError.?.kind);
}

test "lexer: === is invalid in botopink ---- InvalidTripleEqual" {
    var l = Lexer.init("a === b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidTripleEqual, l.lexError.?.kind);
}

test "parser: validateListSpread ---- no spread is valid" {
    const err = parserFull.validateListSpread(false, true, 3);
    try std.testing.expect(err == null);
}

test "parser: validateListSpread ---- spread as last elem with prepend is valid" {
    const err = parserFull.validateListSpread(true, true, 2);
    try std.testing.expect(err == null);
}

test "parser: validateListSpread ---- elements after spread (elementsAfterSpread)" {
    const err = parserFull.validateListSpread(true, false, 0);
    try std.testing.expect(err != null);
    try std.testing.expectEqual(parserFull.ListSpreadError.elementsAfterSpread, err.?);
}

test "parser: validateListSpread ---- useless spread with no elements before (UselessSpread)" {
    const err = parserFull.validateListSpread(true, true, 0);
    try std.testing.expect(err != null);
    try std.testing.expectEqual(parserFull.ListSpreadError.uselessSpread, err.?);
}

test "parser: listSpreadErrorMessage ---- UselessSpread tem hint correto" {
    const msgs = parserFull.listSpreadErrorMessage(.uselessSpread);
    try std.testing.expect(std.mem.indexOf(u8, msgs.hint, "prepending") != null or
        std.mem.indexOf(u8, msgs.hint, "Prepend") != null);
}

test "parser: listSpreadErrorMessage ---- elementsAfterSpread menciona immutable" {
    const msgs = parserFull.listSpreadErrorMessage(.elementsAfterSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.hint, "immutable") != null or
            std.mem.indexOf(u8, msgs.message, "expecting") != null,
    );
}
