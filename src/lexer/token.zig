const std = @import("std");

pub const TokenKind = enum {
    // ── groupings ─────────────────────────────────────────────────────────────
    LParen, // (
    RParen, // )
    LSquare, // [
    RSquare, // ]
    LBrace, // {
    RBrace, // }

    // ── integer operators ─────────────────────────────────────────────────────
    Plus, // +
    Minus, // -
    Star, // *
    Slash, // /
    Less, // <
    Greater, // >
    LessEqual, // <=
    GreaterEqual, // >=
    Percent, // %

    // ── float operators ───────────────────────────────────────────────────────
    PlusDot, // +.
    MinusDot, // -.
    StarDot, // *.
    SlashDot, // /.
    LessDot, // <.
    GreaterDot, // >.
    LessEqualDot, // <=.
    GreaterEqualDot, // >=.

    // ── string operators ──────────────────────────────────────────────────────
    Concatenate, // ++

    // ── other punctuation ─────────────────────────────────────────────────────
    Colon, // :
    Comma, // ,
    Hash, // #
    Bang, // !
    Equal, // =
    EqualEqual, // ==
    NotEqual, // !=
    Vbar, // |
    VbarVbar, // ||
    AmperAmper, // &&
    LtLt, // <<
    GtGt, // >>
    Pipe, // |>
    Dot, // .
    RArrow, // ->
    DotDot, // ..
    At, // @
    PlusEq, // +=  (augmented assignment)

    // ── literals / names ──────────────────────────────────────────────────────
    NumberLiteral,
    Identifier,
    StringLiteral,

    // ── trivia ────────────────────────────────────────────────────────────────
    CommentNormal, // // ...
    CommentModule, // /// ...
    NewLine, // \n (emitted as a token when significant)

    // ── end of file ───────────────────────────────────────────────────────────
    EndOfFile,
    Invalid,

    // ── keywords (alphabetical) ───────────────────────────────────────────────
    KwAs, // as
    KwAssert, // assert
    KwAuto, // auto
    KwCase, // case
    KwConst, // const
    KwDelegate, // delegate
    KwDerive, // derive
    KwEcho, // echo
    KwElse, // else
    KwFn, // fn
    KwFor, // for        (used in `implement ... for Type`)
    KwFrom, // from       (used in `use {} from`)
    KwGet, // get
    KwIf, // if
    KwImplement, // implement       (implementation block)
    KwImport, // import
    KwLet, // let
    KwMacro, // macro
    KwNew, // new
    KwOpaque, // opaque
    KwPanic, // panic
    KwPrivate, // private
    KwPub, // pub
    KwReturn, // return
    KwSelfType, // Self  (type, uppercase)
    KwSet, // set
    KwStruct, // struct
    KwTest, // test
    KwThrow, // throw
    KwTodo, // todo
    KwInterface, // interface
    KwType, // type
    KwRecord, // record
    KwUse, // use
    KwVal, // val
    KwComptime, // comptime
    KwSyntax, // syntax
    KwTypeinfo, // typeinfo
    // note: `self` (lowercase, parameter name) is a plain Identifier
};

pub const Token = struct {
    kind: TokenKind,
    lexeme: []const u8,
    /// Line number, 1-based.
    line: usize,
    /// Column of the first byte of this token, 1-based.
    col: usize,
};
