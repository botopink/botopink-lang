const std = @import("std");
const OhSnap = @import("ohsnap");
const Allocator = std.mem.Allocator;
const SourceLocation = std.builtin.SourceLocation;

const Lexer = @import("../lexer.zig").Lexer;
const TokenKind = @import("token.zig").TokenKind;

// ── helper ────────────────────────────────────────────────────────────────────

fn assert_tokens(
    allocator: Allocator,
    comptime location: SourceLocation,
    comptime text: []const u8,
    src: []const u8,
) !void {
    var l = Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    const oh = OhSnap{};
    try oh.snap(location, text).expectEqual(tokens);
}

// ── basic tokens ──────────────────────────────────────────────────────────────

test "lexer: empty source returns only EndOfFile" {
    var l = Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.EndOfFile, tokens[0].kind);
}

test "lexer: whitespace-only source returns only EndOfFile" {
    var l = Lexer.init("   \t\n  ");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.EndOfFile, tokens[0].kind);
}

test "lexer: recognizes identifier" {
    var l = Lexer.init("myVar");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Identifier, tokens[0].kind);
    try std.testing.expectEqualStrings("myVar", tokens[0].lexeme);
}

test "lexer: recognizes string literal" {
    var l = Lexer.init("\"my-lib\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.StringLiteral, tokens[0].kind);
}

test "lexer: recognizes number literal integer" {
    var l = Lexer.init("42");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("42", tokens[0].lexeme);
}

test "lexer: recognizes number literal zero" {
    var l = Lexer.init("0");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0", tokens[0].lexeme);
}

test "lexer: recognizes number literal float" {
    var l = Lexer.init("3.14");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("3.14", tokens[0].lexeme);
}

// ── groupings ─────────────────────────────────────────────────────────────────

test "lexer: recognizes all grouping tokens" {
    var l = Lexer.init("( ) [ ] { }");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{ .LParen, .RParen, .LSquare, .RSquare, .LBrace, .RBrace, .EndOfFile };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: recognizes LParen" {
    var l = Lexer.init("(");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LParen, tokens[0].kind);
}

test "lexer: recognizes RParen" {
    var l = Lexer.init(")");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.RParen, tokens[0].kind);
}

test "lexer: recognizes LSquare" {
    var l = Lexer.init("[");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LSquare, tokens[0].kind);
}

test "lexer: recognizes RSquare" {
    var l = Lexer.init("]");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.RSquare, tokens[0].kind);
}

test "lexer: recognizes LBrace" {
    var l = Lexer.init("{");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LBrace, tokens[0].kind);
}

test "lexer: recognizes RBrace" {
    var l = Lexer.init("}");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.RBrace, tokens[0].kind);
}

// ── integer operators ─────────────────────────────────────────────────────────

test "lexer: recognizes Plus" {
    var l = Lexer.init("+");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Plus, tokens[0].kind);
    try std.testing.expectEqualStrings("+", tokens[0].lexeme);
}

test "lexer: recognizes Minus" {
    var l = Lexer.init("-");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Minus, tokens[0].kind);
    try std.testing.expectEqualStrings("-", tokens[0].lexeme);
}

test "lexer: recognizes Star" {
    var l = Lexer.init("*");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Star, tokens[0].kind);
    try std.testing.expectEqualStrings("*", tokens[0].lexeme);
}

test "lexer: recognizes StarDot" {
    var l = Lexer.init("*.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.StarDot, tokens[0].kind);
    try std.testing.expectEqualStrings("*.", tokens[0].lexeme);
}

test "lexer: recognizes Slash" {
    var l = Lexer.init("/");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Slash, tokens[0].kind);
    try std.testing.expectEqualStrings("/", tokens[0].lexeme);
}

test "lexer: recognizes Less" {
    var l = Lexer.init("<");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Less, tokens[0].kind);
    try std.testing.expectEqualStrings("<", tokens[0].lexeme);
}

test "lexer: recognizes Greater" {
    var l = Lexer.init(">");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Greater, tokens[0].kind);
    try std.testing.expectEqualStrings(">", tokens[0].lexeme);
}

test "lexer: recognizes LessEqual" {
    var l = Lexer.init("<=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LessEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("<=", tokens[0].lexeme);
}

test "lexer: recognizes GreaterEqual" {
    var l = Lexer.init(">=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.GreaterEqual, tokens[0].kind);
    try std.testing.expectEqualStrings(">=", tokens[0].lexeme);
}

test "lexer: recognizes Percent" {
    var l = Lexer.init("%");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Percent, tokens[0].kind);
    try std.testing.expectEqualStrings("%", tokens[0].lexeme);
}

// ── float operators ───────────────────────────────────────────────────────────

test "lexer: recognizes PlusDot" {
    var l = Lexer.init("+.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.PlusDot, tokens[0].kind);
    try std.testing.expectEqualStrings("+.", tokens[0].lexeme);
}

test "lexer: recognizes MinusDot" {
    var l = Lexer.init("-.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.MinusDot, tokens[0].kind);
    try std.testing.expectEqualStrings("-.", tokens[0].lexeme);
}

test "lexer: recognizes SlashDot" {
    var l = Lexer.init("/.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.SlashDot, tokens[0].kind);
    try std.testing.expectEqualStrings("/.", tokens[0].lexeme);
}

test "lexer: recognizes LessDot" {
    var l = Lexer.init("<.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LessDot, tokens[0].kind);
    try std.testing.expectEqualStrings("<.", tokens[0].lexeme);
}

test "lexer: recognizes GreaterDot" {
    var l = Lexer.init(">.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.GreaterDot, tokens[0].kind);
    try std.testing.expectEqualStrings(">.", tokens[0].lexeme);
}

test "lexer: recognizes LessEqualDot" {
    var l = Lexer.init("<=.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LessEqualDot, tokens[0].kind);
    try std.testing.expectEqualStrings("<=.", tokens[0].lexeme);
}

test "lexer: recognizes GreaterEqualDot" {
    var l = Lexer.init(">=.");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.GreaterEqualDot, tokens[0].kind);
    try std.testing.expectEqualStrings(">=.", tokens[0].lexeme);
}

// ── string operators ──────────────────────────────────────────────────────────

test "lexer: recognizes Concatenate (++)" {
    var l = Lexer.init("++");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Concatenate, tokens[0].kind);
    try std.testing.expectEqualStrings("++", tokens[0].lexeme);
}

// ── other punctuation ─────────────────────────────────────────────────────────

test "lexer: recognizes Colon" {
    var l = Lexer.init(":");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Colon, tokens[0].kind);
}

test "lexer: recognizes Comma" {
    var l = Lexer.init(",");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Comma, tokens[0].kind);
}

test "lexer: recognizes Hash" {
    var l = Lexer.init("#");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Hash, tokens[0].kind);
    try std.testing.expectEqualStrings("#", tokens[0].lexeme);
}

test "lexer: recognizes Bang alone" {
    var l = Lexer.init("!");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Bang, tokens[0].kind);
    try std.testing.expectEqualStrings("!", tokens[0].lexeme);
}

test "lexer: recognizes Equal" {
    var l = Lexer.init("=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Equal, tokens[0].kind);
    try std.testing.expectEqualStrings("=", tokens[0].lexeme);
}

test "lexer: recognizes EqualEqual" {
    var l = Lexer.init("==");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.EqualEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("==", tokens[0].lexeme);
}

test "lexer: recognizes NotEqual" {
    var l = Lexer.init("!=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NotEqual, tokens[0].kind);
    try std.testing.expectEqualStrings("!=", tokens[0].lexeme);
}

test "lexer: recognizes Vbar" {
    var l = Lexer.init("|");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Vbar, tokens[0].kind);
    try std.testing.expectEqualStrings("|", tokens[0].lexeme);
}

test "lexer: recognizes VbarVbar" {
    var l = Lexer.init("||");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.VbarVbar, tokens[0].kind);
    try std.testing.expectEqualStrings("||", tokens[0].lexeme);
}

test "lexer: recognizes AmperAmper" {
    var l = Lexer.init("&&");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.AmperAmper, tokens[0].kind);
    try std.testing.expectEqualStrings("&&", tokens[0].lexeme);
}

test "lexer: recognizes LtLt" {
    var l = Lexer.init("<<");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.LtLt, tokens[0].kind);
    try std.testing.expectEqualStrings("<<", tokens[0].lexeme);
}

test "lexer: recognizes GtGt" {
    var l = Lexer.init(">>");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.GtGt, tokens[0].kind);
    try std.testing.expectEqualStrings(">>", tokens[0].lexeme);
}

test "lexer: recognizes Pipe (|>)" {
    var l = Lexer.init("|>");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Pipe, tokens[0].kind);
    try std.testing.expectEqualStrings("|>", tokens[0].lexeme);
}

test "lexer: recognizes Dot" {
    var l = Lexer.init(".");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Dot, tokens[0].kind);
    try std.testing.expectEqualStrings(".", tokens[0].lexeme);
}

test "lexer: recognizes RArrow (->)" {
    var l = Lexer.init("->");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.RArrow, tokens[0].kind);
    try std.testing.expectEqualStrings("->", tokens[0].lexeme);
}

test "lexer: recognizes DotDot (..)" {
    var l = Lexer.init("..");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.DotDot, tokens[0].kind);
    try std.testing.expectEqualStrings("..", tokens[0].lexeme);
}

test "lexer: recognizes At (@)" {
    var l = Lexer.init("@");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.At, tokens[0].kind);
    try std.testing.expectEqualStrings("@", tokens[0].lexeme);
}

test "lexer: recognizes PlusEq (+=)" {
    var l = Lexer.init("+=");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.PlusEq, tokens[0].kind);
    try std.testing.expectEqualStrings("+=", tokens[0].lexeme);
}

// ── disambiguation: multi-char operators vs shorter prefixes ─────────────────

test "lexer: '=' alone is Equal, not EqualEqual" {
    var l = Lexer.init("= x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Equal, tokens[0].kind);
}

test "lexer: '<' alone is Less, not LessEqual nor LessDot" {
    var l = Lexer.init("< x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Less, tokens[0].kind);
}

test "lexer: '>' alone is Greater, not GreaterEqual nor GreaterDot" {
    var l = Lexer.init("> x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Greater, tokens[0].kind);
}

test "lexer: '+' alone is Plus, not PlusDot nor Concatenate nor PlusEq" {
    var l = Lexer.init("+ x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Plus, tokens[0].kind);
}

test "lexer: '*' alone is Star, not StarDot" {
    var l = Lexer.init("* x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Star, tokens[0].kind);
}

test "lexer: '-' alone is Minus, not MinusDot nor RArrow" {
    var l = Lexer.init("- x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Minus, tokens[0].kind);
}

test "lexer: '|' alone is Vbar, not VbarVbar nor Pipe" {
    var l = Lexer.init("| x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Vbar, tokens[0].kind);
}

test "lexer: '.' alone is Dot, not DotDot" {
    var l = Lexer.init(". x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Dot, tokens[0].kind);
}

test "lexer: '!' alone is Bang, not NotEqual" {
    var l = Lexer.init("! x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Bang, tokens[0].kind);
}

// ── comments ──────────────────────────────────────────────────────────────────

test "lexer: recognizes normal comment" {
    var l = Lexer.init("// hello world");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.CommentNormal, tokens[0].kind);
    try std.testing.expectEqualStrings("// hello world", tokens[0].lexeme);
}

test "lexer: recognizes module doc comment" {
    var l = Lexer.init("/// module doc");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.CommentModule, tokens[0].kind);
    try std.testing.expectEqualStrings("/// module doc", tokens[0].lexeme);
}

test "lexer: comment does not consume next line tokens" {
    var l = Lexer.init("// comment\nuse");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.CommentNormal, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.KwUse, tokens[1].kind);
}

// ── keywords (alphabetical) ───────────────────────────────────────────────────

test "lexer: recognizes keyword as" {
    var l = Lexer.init("as");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwAs, tokens[0].kind);
}

test "lexer: recognizes keyword assert" {
    var l = Lexer.init("assert");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwAssert, tokens[0].kind);
}

test "lexer: recognizes keyword auto" {
    var l = Lexer.init("auto");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwAuto, tokens[0].kind);
}

test "lexer: recognizes keyword case" {
    var l = Lexer.init("case");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwCase, tokens[0].kind);
}

test "lexer: recognizes keyword const" {
    var l = Lexer.init("const");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwConst, tokens[0].kind);
}

test "lexer: recognizes keyword delegate" {
    var l = Lexer.init("delegate");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwDelegate, tokens[0].kind);
}

test "lexer: recognizes keyword derive" {
    var l = Lexer.init("derive");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwDerive, tokens[0].kind);
}

test "lexer: recognizes keyword echo" {
    var l = Lexer.init("echo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwEcho, tokens[0].kind);
}

test "lexer: recognizes keyword else" {
    var l = Lexer.init("else");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwElse, tokens[0].kind);
}

test "lexer: recognizes keyword from" {
    var l = Lexer.init("from");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwFrom, tokens[0].kind);
}

test "lexer: recognizes keyword fn" {
    var l = Lexer.init("fn");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwFn, tokens[0].kind);
}

test "lexer: recognizes keyword get" {
    var l = Lexer.init("get");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwGet, tokens[0].kind);
}

test "lexer: recognizes keyword if" {
    var l = Lexer.init("if");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwIf, tokens[0].kind);
}

test "lexer: recognizes keyword implement" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwImplement, tokens[0].kind);
}

test "lexer: recognizes keyword import" {
    var l = Lexer.init("import");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwImport, tokens[0].kind);
}

test "lexer: recognizes keyword let" {
    var l = Lexer.init("let");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwLet, tokens[0].kind);
}

test "lexer: recognizes keyword macro" {
    var l = Lexer.init("macro");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwMacro, tokens[0].kind);
}

test "lexer: recognizes keyword new" {
    var l = Lexer.init("new");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwNew, tokens[0].kind);
}

test "lexer: recognizes keyword opaque" {
    var l = Lexer.init("opaque");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwOpaque, tokens[0].kind);
}

test "lexer: recognizes keyword panic" {
    var l = Lexer.init("panic");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwPanic, tokens[0].kind);
}

test "lexer: recognizes keyword private" {
    var l = Lexer.init("private");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwPrivate, tokens[0].kind);
}

test "lexer: recognizes keyword pub" {
    var l = Lexer.init("pub");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwPub, tokens[0].kind);
}

test "lexer: recognizes keyword return" {
    var l = Lexer.init("return");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwReturn, tokens[0].kind);
}

test "lexer: Self (uppercase) is KwSelfType" {
    var l = Lexer.init("Self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwSelfType, tokens[0].kind);
}

test "lexer: self (lowercase) is an Identifier" {
    var l = Lexer.init("self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.Identifier, tokens[0].kind);
    try std.testing.expectEqualStrings("self", tokens[0].lexeme);
}

test "lexer: recognizes keyword set" {
    var l = Lexer.init("set");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwSet, tokens[0].kind);
}

test "lexer: recognizes keyword struct" {
    var l = Lexer.init("struct");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwStruct, tokens[0].kind);
}

test "lexer: recognizes keyword test" {
    var l = Lexer.init("test");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwTest, tokens[0].kind);
}

test "lexer: recognizes keyword throw" {
    var l = Lexer.init("throw");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwThrow, tokens[0].kind);
}

test "lexer: recognizes keyword todo" {
    var l = Lexer.init("todo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwTodo, tokens[0].kind);
}

test "lexer: recognizes keyword interface" {
    var l = Lexer.init("interface");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwInterface, tokens[0].kind);
}

test "lexer: recognizes keyword type" {
    var l = Lexer.init("type");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwType, tokens[0].kind);
}

test "lexer: recognizes keyword use" {
    var l = Lexer.init("use");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwUse, tokens[0].kind);
}

test "lexer: recognizes keyword val" {
    var l = Lexer.init("val");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwVal, tokens[0].kind);
}

// ── errors ────────────────────────────────────────────────────────────────────

test "lexer: error on single ampersand" {
    var l = Lexer.init("&");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnexpectedCharacter, result);
}

test "lexer: unterminated string" {
    var l = Lexer.init("\"no closing quote");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.UnterminatedString, result);
}

// ── line tracking ─────────────────────────────────────────────────────────────

test "lexer: tracks line numbers" {
    var l = Lexer.init("use\nfrom");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens[0].line); // use
    try std.testing.expectEqual(@as(usize, 2), tokens[1].line); // from
}

// ── integration: tokenizes expressions ───────────────────────────────────────

test "lexer: tokenizes arithmetic expression" {
    var l = Lexer.init("a + b - c * d / e % f");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .Plus,    .Identifier, .Minus,
        .Identifier, .Star,    .Identifier, .Slash,
        .Identifier, .Percent, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes comparison chain" {
    var l = Lexer.init("a < b <= c > d >= e == f != g");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // a  <   b  <=   c   >   d  >=   e  ==   f  !=   g  EOF
    const expected = [_]TokenKind{
        .Identifier, .Less,         .Identifier,
        .LessEqual,  .Identifier,   .Greater,
        .Identifier, .GreaterEqual, .Identifier,
        .EqualEqual, .Identifier,   .NotEqual,
        .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes float operator expression" {
    var l = Lexer.init("a +. b -. c *. d /. e");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .PlusDot,   .Identifier, .MinusDot,
        .Identifier, .StarDot,   .Identifier, .SlashDot,
        .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes logical operators" {
    var l = Lexer.init("a && b || c");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .AmperAmper, .Identifier, .VbarVbar, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes bitshift operators" {
    var l = Lexer.init("a << b >> c");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .LtLt, .Identifier, .GtGt, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes pipe operator" {
    var l = Lexer.init("x |> f |> g");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .Pipe, .Identifier, .Pipe, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes arrow and range" {
    var l = Lexer.init("x -> y .. z");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .RArrow, .Identifier, .DotDot, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes string concatenation" {
    var l = Lexer.init("\"hello\" ++ \" world\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .StringLiteral, .Concatenate, .StringLiteral, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes private field declaration" {
    var l = Lexer.init("private val _balance: number = 0");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwPrivate, .KwVal, .Identifier, .Colon, .Identifier, .Equal, .NumberLiteral, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes getter signature" {
    var l = Lexer.init("get balance(self: Self): number");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwGet, .Identifier, .LParen, .Identifier, .Colon, .KwSelfType, .RParen, .Colon, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes self field plus-eq" {
    var l = Lexer.init("self._balance += amount");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .Identifier, .Dot, .Identifier, .PlusEq, .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes throw new expression" {
    var l = Lexer.init("throw new Error(\"msg\")");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwThrow, .KwNew, .Identifier, .LParen, .StringLiteral, .RParen, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

// ── record / implement / for keywords ──────────────────────────────────────────────

test "lexer: recognizes keyword record" {
    var l = Lexer.init("record");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwRecord, tokens[0].kind);
}

test "lexer: recognizes keyword implementations" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwImplement, tokens[0].kind);
}

test "lexer: recognizes keyword for" {
    var l = Lexer.init("for");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwFor, tokens[0].kind);
}

test "lexer: tokenizes record header" {
    var l = Lexer.init("val GPSCoordinates = record(val lat: number, val lon: number)");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwVal,     .Identifier, .Equal, .KwRecord,   .LParen,
        .KwVal,     .Identifier, .Colon, .Identifier, .Comma,
        .KwVal,     .Identifier, .Colon, .Identifier, .RParen,
        .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes implement header" {
    var l = Lexer.init("val Cameraimplement = implement UsbCharger, SolarCharger for SmartCamera");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwVal,      .Identifier, .Equal,      .KwImplement,
        .Identifier, .Comma,      .Identifier, .KwFor,
        .Identifier, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

test "lexer: tokenizes qualified implement method name" {
    var l = Lexer.init("fn UsbCharger.Conectar(self: Self)");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    const expected = [_]TokenKind{
        .KwFn,   .Identifier, .Dot,   .Identifier,
        .LParen, .Identifier, .Colon, .KwSelfType,
        .RParen, .EndOfFile,
    };
    for (expected, tokens) |exp, tok| try std.testing.expectEqual(exp, tok.kind);
}

// ══════════════════════════════════════════════════════════════════════════════
// NOVOS TESTES — botopink: erros léxicos estruturados
// ══════════════════════════════════════════════════════════════════════════════

const lexer_full = @import("../lexer.zig");
const LexicalErrorType = lexer_full.LexicalErrorType;
const InvalidUnicodeEscapeKind = lexer_full.InvalidUnicodeEscapeKind;

// ── Binary integer literals (0b) ──────────────────────────────────────────────

test "lexer: 0b1010 é um NumberLiteral válido" {
    var l = Lexer.init("0b1010");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0b1010", tokens[0].lexeme);
}

test "lexer: 0b0 e 0b1 são NumberLiterals válidos" {
    var l = Lexer.init("0b0");
    const t1 = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, t1[0].kind);
}

test "lexer: 0b012 — dígito '2' fora da base binária" {
    var l = Lexer.init("0b012");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lex_error.?.kind);
    try std.testing.expectEqual(@as(?u8, '2'), l.lex_error.?.invalid_char);
}

// ── Octal integer literals (0o) ────────────────────────────────────────────────

test "lexer: 0o17 é um NumberLiteral válido" {
    var l = Lexer.init("0o17");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0o17", tokens[0].lexeme);
}

test "lexer: 0o12345670 é válido (dígitos 0-7)" {
    var l = Lexer.init("0o1234567");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
}

test "lexer: 0o12345678 — dígito '8' fora da base octal" {
    var l = Lexer.init("0o12345678");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lex_error.?.kind);
    try std.testing.expectEqual(@as(?u8, '8'), l.lex_error.?.invalid_char);
}

// ── Hexadecimal integer literals (0x) ─────────────────────────────────────────

test "lexer: 0xFF é um NumberLiteral válido" {
    var l = Lexer.init("0xFF");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0xFF", tokens[0].lexeme);
}

test "lexer: 0x1A2B3C é um NumberLiteral válido" {
    var l = Lexer.init("0x1A2B3C");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
}

test "lexer: 0x sem dígitos — RadixIntNoValue" {
    var l = Lexer.init("0x");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNoValue, l.lex_error.?.kind);
}

test "lexer: 0b sem dígitos — RadixIntNoValue" {
    var l = Lexer.init("0b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNoValue, l.lex_error.?.kind);
}

test "lexer: 0o sem dígitos — RadixIntNoValue" {
    var l = Lexer.init("0o");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNoValue, l.lex_error.?.kind);
}

// ── Valid string escapes ─────────────────────────────────────────────────────

test "lexer: string com escapes válidos \\n \\r \\t \\\\ \\\" \\0" {
    var l = Lexer.init("\"\\n\\r\\t\\\\\\\"\\0\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.StringLiteral, tokens[0].kind);
}

test "lexer: string com unicode válido \\u{41}" {
    var l = Lexer.init("\"\\u{41}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.StringLiteral, tokens[0].kind);
}

test "lexer: string com unicode válido \\u{10FFFF}" {
    var l = Lexer.init("\"\\u{10FFFF}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.StringLiteral, tokens[0].kind);
}

// ── Invalid string escapes ───────────────────────────────────────────────────

test "lexer: \\g é escape inválido — BadStringEscape" {
    var l = Lexer.init("\"\\g\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lex_error.?.kind);
    try std.testing.expectEqual(@as(?u8, 'g'), l.lex_error.?.invalid_char);
}

test "lexer: \\q é escape inválido — BadStringEscape" {
    var l = Lexer.init("\"\\q\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lex_error.?.kind);
}

// ── Invalid unicode escapes ─────────────────────────────────────────────────

test "lexer: \\u{z} — ExpectedHexDigitOrCloseBrace" {
    var l = Lexer.init("\"\\u{z}\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lex_error.?.kind);
    try std.testing.expectEqual(
        @as(?InvalidUnicodeEscapeKind, .ExpectedHexDigitOrCloseBrace),
        l.lex_error.?.unicode_kind,
    );
}

test "lexer: \\u{110000} — InvalidCodepoint (acima de U+10FFFF)" {
    var l = Lexer.init("\"\\u{110000}\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lex_error.?.kind);
    try std.testing.expectEqual(
        @as(?InvalidUnicodeEscapeKind, .InvalidCodepoint),
        l.lex_error.?.unicode_kind,
    );
}

test "lexer: \\u sem chave — MissingOpenBrace" {
    var l = Lexer.init("\"\\uABCD\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.InvalidUnicodeEscape, l.lex_error.?.kind);
}

// ── Invalid === operator ─────────────────────────────────────────────────────

test "lexer: === é inválido em botopink — InvalidTripleEqual" {
    var l = Lexer.init("a === b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidTripleEqual, l.lex_error.?.kind);
}

test "lexer: == ainda é válido após adicionar detecção de ===" {
    var l = Lexer.init("a == b");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.EqualEqual, tokens[1].kind);
}

// ── Invalid semicolon ──────────────────────────────────────────────────────

test "lexer: ponto e vírgula é inválido em botopink — UnexpectedSemicolon" {
    var l = Lexer.init("{ 2 + 3; }");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lex_error != null);
    try std.testing.expectEqual(LexicalErrorType.UnexpectedSemicolon, l.lex_error.?.kind);
}

test "lexer: ponto e vírgula isolado é inválido" {
    var l = Lexer.init(";");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.UnexpectedSemicolon, l.lex_error.?.kind);
}

// ── Palavras reservadas reconhecidas como tokens ──────────────────────────────

test "lexer: 'auto' é reconhecido como KwAuto (palavra reservada)" {
    var l = Lexer.init("auto");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwAuto, tokens[0].kind);
}

test "lexer: 'delegate' é reconhecido como KwDelegate (palavra reservada)" {
    var l = Lexer.init("delegate");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwDelegate, tokens[0].kind);
}

test "lexer: 'echo' é reconhecido como KwEcho (palavra reservada)" {
    var l = Lexer.init("echo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwEcho, tokens[0].kind);
}

test "lexer: 'implement' é reconhecido como KwImplement (palavra reservada)" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwImplement, tokens[0].kind);
}

test "lexer: 'macro' é reconhecido como KwMacro (palavra reservada)" {
    var l = Lexer.init("macro");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwMacro, tokens[0].kind);
}

test "lexer: 'derive' é reconhecido como KwDerive (palavra reservada)" {
    var l = Lexer.init("derive");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.KwDerive, tokens[0].kind);
}

// ── isReservedWord helper ─────────────────────────────────────────────────────

test "lexer: isReservedWord retorna true para palavras reservadas" {
    try std.testing.expect(lexer_full.isReservedWord(.KwAuto));
    try std.testing.expect(lexer_full.isReservedWord(.KwDelegate));
    try std.testing.expect(lexer_full.isReservedWord(.KwEcho));
    try std.testing.expect(lexer_full.isReservedWord(.KwElse));
    try std.testing.expect(lexer_full.isReservedWord(.KwImplement));
    try std.testing.expect(lexer_full.isReservedWord(.KwMacro));
    try std.testing.expect(lexer_full.isReservedWord(.KwTest));
    try std.testing.expect(lexer_full.isReservedWord(.KwDerive));
}

test "lexer: isReservedWord retorna false para identificadores normais" {
    try std.testing.expect(!lexer_full.isReservedWord(.Identifier));
    try std.testing.expect(!lexer_full.isReservedWord(.KwLet));
    try std.testing.expect(!lexer_full.isReservedWord(.KwConst));
    try std.testing.expect(!lexer_full.isReservedWord(.KwFn));
    try std.testing.expect(!lexer_full.isReservedWord(.KwVal));
}

// ── Integration: decimal numbers are unaffected ──────────────────────────────

test "lexer: números decimais normais continuam funcionando" {
    var l = Lexer.init("42 3.14 0 100");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[1].kind);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[2].kind);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[3].kind);
}

test "lexer: 0 seguido de não-prefixo é decimal normal" {
    var l = Lexer.init("0 01 09");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.NumberLiteral, tokens[1].kind);
}

// ── validateListSpread helper ─────────────────────────────────────────────────

const parser_full = @import("../parser.zig");

test "parser: validateListSpread — sem spread é válido" {
    const err = parser_full.validateListSpread(false, true, 3);
    try std.testing.expect(err == null);
}

test "parser: validateListSpread — spread como último elem com prepend é válido" {
    const err = parser_full.validateListSpread(true, true, 2);
    try std.testing.expect(err == null);
}

test "parser: validateListSpread — elementos após spread (ElementsAfterSpread)" {
    const err = parser_full.validateListSpread(true, false, 0);
    try std.testing.expect(err != null);
    try std.testing.expectEqual(parser_full.ListSpreadError.ElementsAfterSpread, err.?);
}

test "parser: validateListSpread — spread inútil sem elementos antes (UselessSpread)" {
    const err = parser_full.validateListSpread(true, true, 0);
    try std.testing.expect(err != null);
    try std.testing.expectEqual(parser_full.ListSpreadError.UselessSpread, err.?);
}

test "parser: listSpreadErrorMessage — UselessSpread tem hint correto" {
    const msgs = parser_full.listSpreadErrorMessage(.UselessSpread);
    try std.testing.expect(std.mem.indexOf(u8, msgs.hint, "prepending") != null or
        std.mem.indexOf(u8, msgs.hint, "Prepend") != null);
}

test "parser: listSpreadErrorMessage — ElementsAfterSpread menciona immutable" {
    const msgs = parser_full.listSpreadErrorMessage(.ElementsAfterSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.hint, "immutable") != null or
            std.mem.indexOf(u8, msgs.message, "expecting") != null,
    );
}
