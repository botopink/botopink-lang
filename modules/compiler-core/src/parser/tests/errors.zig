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

// Where a `use` may stand is the checker's rule (decision 357,
// `use-not-top-level`), not the parser's: a `return` inside a lambda is the
// lambda's, and a `use` after `use memo { -> return … }` parses.
test "parser: lambda return does not end the enclosing static prefix" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn Counter() {
        \\    val doubled = use memo { -> return 2; };
        \\    val c = use state(0);
        \\}
    );
}

test "parser error: assignment without val" {
    try h.expectParseError(std.testing.allocator,
        \\error: There must be a 'val' or 'var' to bind a variable to a value
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

// Same diagnostic from a non-first line, so it also covers the location
// contract on the top-level `ident =` path.
test "parser error: assignment without val on a later line" {
    try h.expectParseError(std.testing.allocator,
        \\error: There must be a 'val' or 'var' to bind a variable to a value
        \\ --> <test>:3:1
        \\  |
        \\3 | wibble = 4
        \\  | ^^^^^^ There must be a 'val' or 'var' to bind a variable to a value
        \\  |
        \\  = hint: Use `val <n> = <value>` for bindings.
        \\
        \\
    ,
        \\val a = 1;
        \\val b = 2;
        \\wibble = 4
    );
}

test "parser error: reserved word at top-level" {
    try h.expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:1:1
        \\  |
        \\1 | else
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "else");
}

// A real reserved word (`else`) in a real expression position — `echo` was
// used here before, but it is a plain identifier (the keyword was removed;
// see `expressions.zig`'s "echo is a plain identifier" test), so the parse
// failed with no `parseError` and the comparison never ran.
test "parser error: reserved word in expression" {
    try h.expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:2:13
        \\  |
        \\2 |     val x = else;
        \\  |             ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    ,
        \\fn f() {
        \\    val x = else;
        \\}
    );
}

// The retired `@[…]` annotation opener (spec 05 §5.12) is rejected, not
// silently accepted as a synonym of `#[…]`.
test "parser error: retired @[ annotation block" {
    try h.expectParseError(std.testing.allocator,
        \\error: the `@[…]` annotation block was retired
        \\ --> <test>:2:1
        \\  |
        \\2 | @[external(node, "m.mjs", "f")]
        \\  | ^^ write `#[…]` instead
        \\  |
        \\  = hint: An annotation block opens with `#[`; the `@` marks a builtin annotation INSIDE it, e.g. `#[@External.Node("./m.mjs", "f")]`.
        \\
        \\
    ,
        \\val a = 1;
        \\@[external(node, "m.mjs", "f")]
        \\pub declare fn f() -> i32;
    );
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

test "parser error: deprecated *fn prefix" {
    // v0.beta.19 hard-removed the `*fn` parse path; since decision 118 the
    // return type is the effect. A user migrating from an old codebase sees
    // this diagnostic, which names the canonical replacement.
    try h.expectParseError(std.testing.allocator,
        \\error[deprecated-star-fn]: the `*fn` prefix was removed in v0.beta.19
        \\ --> <test>:1:1
        \\  |
        \\1 | *fn parse(n: i32) -> @Result<i32, string> { return n; }
        \\  | ^^^ write a plain `fn` whose return type is the effect wrapper
        \\  |
        \\  = note: the `*fn` form was deprecated in v0.beta.12; since decision 118 there is no effect marker at all — the return type is the effect
        \\  = hint: rewrite as `fn <name>(...) -> @<Wrapper><...> { ... }` — `@Result`, `@Task`, `@Component`, `@Iterator` or `@Stream`
        \\
        \\
    , "*fn parse(n: i32) -> @Result<i32, string> { return n; }");
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
        .lexeme = "else",
        .detail = "else",
    };
    try std.testing.expectEqual(ParseErrorType.reservedWord, info.kind);
    try std.testing.expectEqualStrings("else", info.lexeme);
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

test "parser: $self in an External template names the positional marker" {
    try h.expectParseError(std.testing.allocator,
        \\error[template-self-marker]: `$self` is not a template marker
        \\ --> <test>:1:18
        \\  |
        \\1 | #[@External.Node("$self.trim()")]
        \\  |                  ^^^^^^^^^^^^^^ use `$0`
        \\  |
        \\  = hint: Markers are positional over the declared parameters: on a method `$0` is `self`, `$1` the next parameter.
        \\
        \\
    ,
        \\#[@External.Node("$self.trim()")]
        \\declare fn trim(s: string) -> string;
    );
}
