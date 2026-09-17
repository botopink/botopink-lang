const std = @import("std");
pub const TokenKind = enum {
    // ── groupings ─────────────────────────────────────────────────────────────
    leftParenthesis, // (
    rightParenthesis, // )
    leftSquareBracket, // [
    rightSquareBracket, // ]
    leftBrace, // {
    rightBrace, // }

    // ── arithmetic / comparison operators ────────────────────────────────────
    plus, // +
    minus, // -
    star, // *
    slash, // /
    lessThan, // <
    greaterThan, // >
    lessThanEqual, // <=
    greaterThanEqual, // >=
    percent, // %

    // ── other punctuation ─────────────────────────────────────────────────────
    colon, // :
    comma, // ,
    hash, // #
    bang, // !
    questionMark, // ?
    questionDot, // ?. (optional chaining)
    semicolon, // ;
    equal, // =
    equalEqual, // ==
    notEqual, // !=
    verticalBar, // |
    verticalBarVerticalBar, // ||
    amperAmper, // &&
    lessThanLessThan, // <<
    greaterThanGreaterThan, // >>
    pipe, // |>
    dot, // .
    rightArrow, // ->
    dotDot, // ..
    at, // @
    plusEqual, // +=
    builtinIdent, // @identifier (built-in function names)

    // ── literals / names ──────────────────────────────────────────────────────
    numberLiteral,
    identifier,
    stringLiteral,
    multilineStringLiteral,
    linesStringLiteral, // `\\`-prefixed line string (Zig style): consecutive
    //                     `\\ …` lines join with newlines

    // ── trivia ────────────────────────────────────────────────────────────────
    commentNormal, // // ...
    commentDoc, // /// ...  (type/function docs)
    commentModule, // //// ...  (module-level docs)
    newLine, // \n

    // ── end of file ───────────────────────────────────────────────────────────
    endOfFile,
    invalid,

    // ── keywords (alphabetical) ───────────────────────────────────────────────
    as,
    assert,
    auto,
    await,
    case,
    @"const", // reserved, not used in surface syntax
    default,
    delegate,
    derive,
    @"else",
    @"enum",
    extend,
    extends,
    @"fn",
    @"for",
    from,
    get,
    @"if",
    implement,
    is,
    import,
    macro,
    mod,
    new,
    @"opaque",
    private,
    @"pub",
    @"return",
    selfType,
    set,
    @"test",
    throw,
    interface,
    /// `behavior Name { … }` — the 1.0.3 spelling of `interface` (both parse
    /// during the front-12 dual grammar).
    behavior,
    type,
    record,
    use,
    val,
    @"var",
    @"comptime",
    syntax,
    @"break",
    loop,
    @"continue",
    yield,
    declare,
    null,
    @"try",
    @"catch",
    underscore,
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    /// Line on which the token STARTS, 1-based. A token that spans several
    /// lines (`"""…"""`, a `\\ …` line string) keeps its opening line.
    line: usize,
    /// Column of the first byte of this token, 1-based, measured from the
    /// start of `line` (never from an earlier line).
    col: usize,
    /// Byte offset of the first byte of this token in the original source.
    /// `source[offset..offset + lexeme.len]` is the token's text, so this is
    /// the value diagnostics and LSP ranges are built from.
    offset: usize = 0,
};
