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
    @"struct",
    @"test",
    throw,
    interface,
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
    /// Line number, 1-based.
    line: usize,
    /// Column of the first byte of this token, 1-based.
    col: usize,
};
