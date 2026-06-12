//! parser: parse errors & cross-stage error-message units (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: anonymous implement rejected" {
    try h.expectParseError(std.testing.allocator,
        \\error: An `implement`/`extend` block must be named
        \\ --> <test>:1:1
        \\  |
        \\1 | implement Nada for Pato {}
        \\  | ^^^^^^^^^ An `implement`/`extend` block must be named
        \\  |
        \\  = hint: Give it a name, e.g. `Name implement Trait for Type { … }` or `Name extend Type { … }`
        \\
        \\
    ,
        \\implement Nada for Pato {}
    );
}

test "parser: anonymous extend rejected" {
    try h.expectParseError(std.testing.allocator,
        \\error: An `implement`/`extend` block must be named
        \\ --> <test>:1:1
        \\  |
        \\1 | extend Pato {}
        \\  | ^^^^^^ An `implement`/`extend` block must be named
        \\  |
        \\  = hint: Give it a name, e.g. `Name implement Trait for Type { … }` or `Name extend Type { … }`
        \\
        \\
    ,
        \\extend Pato {}
    );
}

test "parser error: use after return (static prefix violation)" {
    try h.expectParseError(std.testing.allocator,
        \\error: `use` must be in static prefix
        \\ --> <test>:1:5
        \\  |
        \\1 | fn App() {
        \\  |     ^^^ `use` must be in static prefix
        \\  |
        \\  = hint: Move all `use` statements to the top of the function body, before any `if`, `case`, `loop`, or `return`
        \\
        \\
    ,
        \\fn App() {
        \\    return 1;
        \\    use state(0);
        \\}
    );
}

test "parser error: assignment without val" {
    try h.expectParseError(std.testing.allocator,
        \\error comptime: syntax error
        \\ --> <test>:1:1
        \\  |
        \\1 | wibble = 4
        \\  | ^^^^^^ There must be a 'val' or 'var' to bind a variable to a value
        \\  |
        \\  = hint: Use `val <n> = <value>` for bindings.
        \\
        \\
    , "wibble = 4");
}

test "parser error: reserved word at top-level" {
    try h.expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:1:1
        \\  |
        \\1 | auto
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "auto");
}

test "parser error: reserved word in expression" {
    try h.expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:1:1
        \\  |
        \\1 | echo
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "echo");
}

test "parser error: removed error union syntax T!E" {
    try h.expectParseError(std.testing.allocator,
        \\error: Error union syntax `T!E` has been removed
        \\ --> <test>:1:16
        \\  |
        \\1 | fn foo() -> i32!Error { }
        \\  |                ^ Error union syntax `T!E` has been removed
        \\  |
        \\  = hint: Use `@Result<D, E>` instead, e.g. `fn fetch() -> @Result<i32, MyError>`
        \\
        \\
    , "fn foo() -> i32!Error { }");
}

test "parser: validateListSpread ---- empty list is valid" {
    try std.testing.expect(parserMod.validateListSpread(false, false, 0) == null);
}

test "parser: validateListSpread ---- [1, 2, ..xs] is valid" {
    try std.testing.expect(parserMod.validateListSpread(true, true, 2) == null);
}

test "parser: validateListSpread ---- [..xs, 3] gives elementsAfterSpread" {
    const result = parserMod.validateListSpread(true, false, 0);
    try std.testing.expectEqual(parserMod.ListSpreadError.elementsAfterSpread, result.?);
}

test "parser: validateListSpread ---- [..xs] gives UselessSpread" {
    const result = parserMod.validateListSpread(true, true, 0);
    try std.testing.expectEqual(parserMod.ListSpreadError.uselessSpread, result.?);
}

test "parser: listSpreadErrorMessage.elementsAfterSpread mentions 'after'" {
    const msgs = parserMod.listSpreadErrorMessage(.elementsAfterSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "after") != null or
            std.mem.indexOf(u8, msgs.message, "expecting") != null,
    );
}

test "parser: listSpreadErrorMessage.uselessSpread mentions spread has no effect" {
    const msgs = parserMod.listSpreadErrorMessage(.uselessSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "nothing") != null or
            std.mem.indexOf(u8, msgs.message, "does") != null,
    );
}

test "parser: ParseErrorInfo has all expected fields" {
    const info = parserMod.ParseErrorInfo{
        .kind = .reservedWord,
        .start = 0,
        .end = 4,
        .lexeme = "auto",
        .detail = "auto",
    };
    try std.testing.expectEqual(ParseErrorType.reservedWord, info.kind);
    try std.testing.expectEqualStrings("auto", info.lexeme);
    try std.testing.expectEqual(@as(usize, 0), info.start);
    try std.testing.expectEqual(@as(usize, 4), info.end);
}

test "parser: ParseErrorInfo detail is optional" {
    const info = parserMod.ParseErrorInfo{
        .kind = .novalBinding,
        .start = 0,
        .end = 6,
        .lexeme = "wibble",
    };
    try std.testing.expect(info.detail == null);
}

test "lexer: lexicalErrorMessage for DigitOutOfRadix" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .DigitOutOfRadix, .start = 4, .end = 5, .invalidChar = '8' });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "radix") != null or std.mem.indexOf(u8, msg, "Digit") != null,
    );
}

test "lexer: lexicalErrorMessage for RadixIntNovalue" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .RadixIntNovalue, .start = 1, .end = 1 });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidTripleEqual" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .InvalidTripleEqual, .start = 0, .end = 3 });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "===") != null or std.mem.indexOf(u8, msg, "botopink") != null,
    );
}

test "lexer: lexicalErrorMessage for BadStringEscape" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .BadStringEscape, .start = 1, .end = 3, .invalidChar = 'g' });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape ExpectedHexDigitOrCloseBrace" {
    const msg = lexerMod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicodeKind = .ExpectedHexDigitOrCloseBrace,
        .start = 1,
        .end = 5,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "hex") != null or
            std.mem.indexOf(u8, msg, "Hex") != null or
            std.mem.indexOf(u8, msg, "Expected") != null,
    );
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape InvalidCodepoint" {
    const msg = lexerMod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicodeKind = .InvalidCodepoint,
        .start = 1,
        .end = 11,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "10FFFF") != null or
            std.mem.indexOf(u8, msg, "codepoint") != null or
            std.mem.indexOf(u8, msg, "Codepoint") != null,
    );
}
