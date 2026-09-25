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
    /// `??` — the nullish default: `a ?? 0` is `a` unless it is null
    /// (decision 28). Two characters, so `?` for an optional type and `?.` for
    /// optional chaining are unaffected.
    questionQuestion, // ??
    semicolon, // ;
    equal, // =
    equalEqual, // ==
    notEqual, // !=
    verticalBar, // |
    verticalBarVerticalBar, // ||
    amperAmper, // &&
    /// `&` alone and `^` — lexed so the parser can refuse them BY NAME
    /// (`bitwise-operator-absent`, front 15 step 3) instead of the lexer
    /// stopping on an "unexpected character" no parse error can locate.
    ampersand, // &
    caret, // ^
    lessThanLessThan, // <<
    greaterThanGreaterThan, // >>
    pipe, // |>
    dot, // .
    rightArrow, // ->
    dotDot, // ..
    /// `...` — the inclusive range of a pattern (`1...9`, decision 8 §5.2).
    /// `..` stays iteration and slicing.
    dotDotDot, // ...
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
    /// `'a'` — a character literal, which the language does not have: lexed as
    /// one token so `parsePrimary` refuses it as `char-literal-absent` and
    /// names `"a"` (front 15 step 3). The lexeme runs from the opening `'` to
    /// the closing one on the same line, or to the end of the line.
    charLiteral, // 'a'

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
    default,
    derive,
    @"else",
    /// `record`, `enum`, `interface`: NOT produced by the lexer since 1.0.3 —
    /// the words lex as identifiers. The variants stay as declaration-kind
    /// tags the language server's token scanners key on (`engine.zig`
    /// `declKindAt` maps `type`/`behavior` onto them).
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
    @"opaque",
    private,
    @"pub",
    @"return",
    selfType,
    set,
    @"test",
    throw,
    interface,
    /// `behavior Name { … }` — `interface` was renamed in 1.0.3.
    behavior,
    type,
    /// `unknown` — decision 8 §2's type. A keyword, not an identifier: a
    /// first-class type no declaration may take as its name.
    unknown,
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
