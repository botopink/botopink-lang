const std = @import("std");
const OhSnap = @import("ohsnap");
const Allocator = std.mem.Allocator;
const SourceLocation = std.builtin.SourceLocation;

const Lexer = @import("../lexer.zig").Lexer;
const TokenKind = @import("token.zig").TokenKind;

// ── helper ────────────────────────────────────────────────────────────────────

fn assertTokens(
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

test "lexer: empty source returns only .endOfFile" {
    var l = Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.endOfFile, tokens[0].kind);
}

test "lexer: whitespace-only source returns only .endOfFile" {
    var l = Lexer.init("   \t\n  ");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 1), tokens.len);
    try std.testing.expectEqual(TokenKind.endOfFile, tokens[0].kind);
}

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

// ── groupings ─────────────────────────────────────────────────────────────────

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

// ── integer operators ─────────────────────────────────────────────────────────

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

// ── other punctuation ─────────────────────────────────────────────────────────

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

// ── disambiguation: multi-char operators vs shorter prefixes ─────────────────

test "lexer: '=' alone is Equal, not EqualEqual" {
    var l = Lexer.init("= x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equal, tokens[0].kind);
}

test "lexer: '<' alone is Less, not LessEqual nor LessDot" {
    var l = Lexer.init("< x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.lessThan, tokens[0].kind);
}

test "lexer: '>' alone is greater, not greaterEqual nor greaterDot" {
    var l = Lexer.init("> x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.greaterThan, tokens[0].kind);
}

test "lexer: '+' alone is plus, not plusEq" {
    var l = Lexer.init("+ x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.plus, tokens[0].kind);
}

test "lexer: '*' alone is Star" {
    var l = Lexer.init("* x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.star, tokens[0].kind);
}

test "lexer: '-' alone is Minus, not rArrow" {
    var l = Lexer.init("- x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.minus, tokens[0].kind);
}

test "lexer: '|' alone is Vbar, not VbarVbar nor Pipe" {
    var l = Lexer.init("| x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.verticalBar, tokens[0].kind);
}

test "lexer: '.' alone is Dot, not DotDot" {
    var l = Lexer.init(". x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.dot, tokens[0].kind);
}

test "lexer: '!' alone is bang, not NotEqual" {
    var l = Lexer.init("! x");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.bang, tokens[0].kind);
}

// ── comments ──────────────────────────────────────────────────────────────────

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

test "lexer: comment does not consume next line tokens" {
    var l = Lexer.init("// comment\nuse");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.commentNormal, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.use, tokens[1].kind);
}

// ── keywords (alphabetical) ───────────────────────────────────────────────────

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

test "lexer: const is not a reserved keyword (use val instead)" {
    var l = Lexer.init("const");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    // 'const' is no longer a surface keyword; it lexes as an identifier
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
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

test "lexer: Self (uppercase) is KwSelfType" {
    var l = Lexer.init("Self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.selfType, tokens[0].kind);
}

test "lexer: self (lowercase) is an identifier" {
    var l = Lexer.init("self");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.identifier, tokens[0].kind);
    try std.testing.expectEqualStrings("self", tokens[0].lexeme);
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

// ── record / implement / for keywords ──────────────────────────────────────────────

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

// ══════════════════════════════════════════════════════════════════════════════
// NEW TESTS ---- botopink: structured lexer errors
// ══════════════════════════════════════════════════════════════════════════════

const lexerFull = @import("../lexer.zig");
const LexicalErrorType = lexerFull.LexicalErrorType;
const InvalidUnicodeEscapeKind = lexerFull.InvalidUnicodeEscapeKind;

// ── Binary integer literals (0b) ──────────────────────────────────────────────

test "lexer: 0b1010 is a valid numberLiteral" {
    var l = Lexer.init("0b1010");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0b1010", tokens[0].lexeme);
}

test "lexer: 0b0 and 0b1 are valid numberLiterals" {
    var l = Lexer.init("0b0");
    const t1 = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, t1[0].kind);
}

test "lexer: 0b012 ---- digit '2' out of binary base" {
    var l = Lexer.init("0b012");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, '2'), l.lexError.?.invalidChar);
}

// ── Octal integer literals (0o) ────────────────────────────────────────────────

test "lexer: 0o17 is a valid numberLiteral" {
    var l = Lexer.init("0o17");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0o17", tokens[0].lexeme);
}

test "lexer: 0o12345670 is valid (digits 0-7)" {
    var l = Lexer.init("0o1234567");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
}

test "lexer: 0o12345678 ---- digit '8' out of octal base" {
    var l = Lexer.init("0o12345678");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.DigitOutOfRadix, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, '8'), l.lexError.?.invalidChar);
}

// ── Hexadecimal integer literals (0x) ─────────────────────────────────────────

test "lexer: 0xFF is a valid numberLiteral" {
    var l = Lexer.init("0xFF");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqualStrings("0xFF", tokens[0].lexeme);
}

test "lexer: 0x1A2B3C is a valid numberLiteral" {
    var l = Lexer.init("0x1A2B3C");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
}

test "lexer: 0x with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0x");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

test "lexer: 0b with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

test "lexer: 0o with no digits ---- RadixIntNovalue" {
    var l = Lexer.init("0o");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.RadixIntNovalue, l.lexError.?.kind);
}

// ── valid string escapes ─────────────────────────────────────────────────────

test "lexer: string with valid escapes \\n \\r \\t \\\\ \\\" \\0" {
    var l = Lexer.init("\"\\n\\r\\t\\\\\\\"\\0\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: string with valid unicode \\u{41}" {
    var l = Lexer.init("\"\\u{41}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

test "lexer: string with valid unicode \\u{10FFFF}" {
    var l = Lexer.init("\"\\u{10FFFF}\"");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.stringLiteral, tokens[0].kind);
}

// ── Invalid string escapes ───────────────────────────────────────────────────

test "lexer: \\g is invalid escape ---- BadStringEscape" {
    var l = Lexer.init("\"\\g\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lexError.?.kind);
    try std.testing.expectEqual(@as(?u8, 'g'), l.lexError.?.invalidChar);
}

test "lexer: \\q is invalid escape ---- BadStringEscape" {
    var l = Lexer.init("\"\\q\"");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expectEqual(LexicalErrorType.BadStringEscape, l.lexError.?.kind);
}

// ── Invalid unicode escapes ─────────────────────────────────────────────────

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

// ── Invalid === operator ─────────────────────────────────────────────────────

test "lexer: === is invalid in botopink ---- InvalidTripleEqual" {
    var l = Lexer.init("a === b");
    const result = l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectError(error.LexicalError, result);
    try std.testing.expect(l.lexError != null);
    try std.testing.expectEqual(LexicalErrorType.InvalidTripleEqual, l.lexError.?.kind);
}

test "lexer: == remains valid after adding === detection" {
    var l = Lexer.init("a == b");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.equalEqual, tokens[1].kind);
}

// ── Semicolon token ──────────────────────────────────────────────────────

test "lexer: semicolon is tokenized" {
    var l = Lexer.init("2 + 3;");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 5), tokens.len);
    try std.testing.expectEqual(TokenKind.semicolon, tokens[3].kind);
}

test "lexer: standalone semicolon is tokenized" {
    var l = Lexer.init(";");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(@as(usize, 2), tokens.len);
    try std.testing.expectEqual(TokenKind.semicolon, tokens[0].kind);
}

// ── Reserved words recognized as tokens ──────────────────────────────────────

test "lexer: 'auto' is recognized as KwAuto (reserved word)" {
    var l = Lexer.init("auto");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.auto, tokens[0].kind);
}

test "lexer: 'delegate' is recognized as KwDelegate (reserved word)" {
    var l = Lexer.init("delegate");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.delegate, tokens[0].kind);
}

test "lexer: 'echo' is recognized as KwEcho (reserved word)" {
    var l = Lexer.init("echo");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.echo, tokens[0].kind);
}

test "lexer: 'implement' is recognized as implement (reserved word)" {
    var l = Lexer.init("implement");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.implement, tokens[0].kind);
}

test "lexer: 'macro' is recognized as macro (reserved word)" {
    var l = Lexer.init("macro");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.macro, tokens[0].kind);
}

test "lexer: 'derive' is recognized as KwDerive (reserved word)" {
    var l = Lexer.init("derive");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.derive, tokens[0].kind);
}

// ── isReservedWord helper ─────────────────────────────────────────────────────

test "lexer: isReservedWord returns true for reserved words" {
    try std.testing.expect(lexerFull.isReservedWord(.auto));
    try std.testing.expect(lexerFull.isReservedWord(.delegate));
    try std.testing.expect(lexerFull.isReservedWord(.echo));
    try std.testing.expect(lexerFull.isReservedWord(.@"else"));
    try std.testing.expect(lexerFull.isReservedWord(.implement));
    try std.testing.expect(lexerFull.isReservedWord(.macro));
    try std.testing.expect(lexerFull.isReservedWord(.@"test"));
    try std.testing.expect(lexerFull.isReservedWord(.derive));
}

test "lexer: isReservedWord returns false for normal identifiers" {
    try std.testing.expect(!lexerFull.isReservedWord(.identifier));
    try std.testing.expect(!lexerFull.isReservedWord(.@"var"));
    try std.testing.expect(!lexerFull.isReservedWord(.@"const"));
    try std.testing.expect(!lexerFull.isReservedWord(.@"fn"));
    try std.testing.expect(!lexerFull.isReservedWord(.val));
}

// ── Integration: decimal numbers are unaffected ──────────────────────────────

test "lexer: normal decimal numbers continue to work" {
    var l = Lexer.init("42 3.14 0 100");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[1].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[2].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[3].kind);
}

test "lexer: 0 followed by non-prefix is normal decimal" {
    var l = Lexer.init("0 01 09");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[0].kind);
    try std.testing.expectEqual(TokenKind.numberLiteral, tokens[1].kind);
}

// ── validateListSpread helper ─────────────────────────────────────────────────

const parserFull = @import("../parser.zig");

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
