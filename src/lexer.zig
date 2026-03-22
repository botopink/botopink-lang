const std = @import("std");
const token = @import("./lexer/token.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

// ── Lexical error types ───────────────────────────────────────────────────────

pub const LexicalErrorType = enum {
    /// Digit outside the numeric base, e.g. '2' in 0b012, '8' in 0o178
    DigitOutOfRadix,
    /// Radix prefix with no digits, e.g. 0x with no hex digits
    RadixIntNoValue,
    /// Invalid string escape, e.g. \g
    BadStringEscape,
    /// Invalid unicode escape, e.g. \u{z} or \u{110000}
    InvalidUnicodeEscape,
    /// The === operator does not exist in botopink
    InvalidTripleEqual,
    /// Semicolons are not valid in botopink
    UnexpectedSemicolon,
};

pub const InvalidUnicodeEscapeKind = enum {
    /// Expected a hex digit or '}', e.g. \u{z}
    ExpectedHexDigitOrCloseBrace,
    /// Codepoint exceeds U+10FFFF
    InvalidCodepoint,
    /// Expected opening '{' after \u
    MissingOpenBrace,
    /// Missing closing '}'
    MissingCloseBrace,
};

pub const LexicalError = struct {
    kind: LexicalErrorType,
    /// Extra detail for Unicode errors
    unicode_kind: ?InvalidUnicodeEscapeKind = null,
    /// Start position of the error in source (byte offset)
    start: usize,
    /// End position of the error in source (byte offset, exclusive)
    end: usize,
    /// The invalid character (for DigitOutOfRadix and BadStringEscape)
    invalid_char: ?u8 = null,
};

pub const LexerError = error{
    UnterminatedString,
    UnexpectedCharacter,
    OutOfMemory,
    /// Structured lexical error — see Lexer.lex_error for details
    LexicalError,
};

// ── Lexer ─────────────────────────────────────────────────────────────────────

pub const Lexer = struct {
    source: []const u8,
    start: usize,
    current: usize,
    line: usize,
    /// Byte offset where the current line started (for column computation).
    line_start: usize,
    tokens: std.ArrayList(Token),
    /// Populated when scanAll returns LexerError.LexicalError
    lex_error: ?LexicalError,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 1,
            .line_start = 0,
            .tokens = .empty,
            .lex_error = null,
        };
    }

    pub fn deinit(self: *Lexer, allocator: std.mem.Allocator) void {
        self.tokens.deinit(allocator);
    }

    pub fn scanAll(self: *Lexer, allocator: std.mem.Allocator) LexerError![]const Token {
        while (!self.isAtEnd()) {
            self.start = self.current;
            try self.scanToken(allocator);
        }
        try self.tokens.append(allocator, .{ .kind = .EndOfFile, .lexeme = "", .line = self.line, .col = self.current - self.line_start + 1 });
        return self.tokens.items;
    }

    fn scanToken(self: *Lexer, allocator: std.mem.Allocator) LexerError!void {
        const c = self.advance();
        switch (c) {
            ' ', '\r', '\t' => {},
            '\n' => {
                self.line += 1;
                self.line_start = self.current;
            },

            // Ponto e vírgula é inválido em botopink
            ';' => {
                self.lex_error = .{
                    .kind = .UnexpectedSemicolon,
                    .start = self.start,
                    .end = self.current,
                };
                return LexerError.LexicalError;
            },

            // ── groupings ────────────────────────────────────────────────────
            '(' => try self.addToken(.LParen, allocator),
            ')' => try self.addToken(.RParen, allocator),
            '[' => try self.addToken(.LSquare, allocator),
            ']' => try self.addToken(.RSquare, allocator),
            '{' => try self.addToken(.LBrace, allocator),
            '}' => try self.addToken(.RBrace, allocator),

            // ── single-char punctuation ───────────────────────────────────────
            ',' => try self.addToken(.Comma, allocator),
            ':' => try self.addToken(.Colon, allocator),
            '%' => try self.addToken(.Percent, allocator),
            '*' => {
                if (self.matchChar('.')) {
                    try self.addToken(.StarDot, allocator);
                } else {
                    try self.addToken(.Star, allocator);
                }
            },
            '#' => try self.addToken(.Hash, allocator),
            '@' => try self.addToken(.At, allocator),

            // ── '=' or '==' — detect invalid '===' ───────────────────────────
            '=' => {
                if (self.matchChar('=')) {
                    if (self.matchChar('=')) {
                        // === is not valid in botopink
                        self.lex_error = .{
                            .kind = .InvalidTripleEqual,
                            .start = self.start,
                            .end = self.current,
                        };
                        return LexerError.LexicalError;
                    }
                    try self.addToken(.EqualEqual, allocator);
                } else {
                    try self.addToken(.Equal, allocator);
                }
            },

            // ── '!' or '!=' ──────────────────────────────────────────────────
            '!' => {
                if (self.matchChar('=')) {
                    try self.addToken(.NotEqual, allocator);
                } else {
                    try self.addToken(.Bang, allocator);
                }
            },

            // ── '+', '++', '+.', '+=' ─────────────────────────────────────────
            '+' => {
                if (self.matchChar('+')) {
                    try self.addToken(.Concatenate, allocator);
                } else if (self.matchChar('.')) {
                    try self.addToken(.PlusDot, allocator);
                } else if (self.matchChar('=')) {
                    try self.addToken(.PlusEq, allocator);
                } else {
                    try self.addToken(.Plus, allocator);
                }
            },

            // ── '-', '-.', '->' ───────────────────────────────────────────────
            '-' => {
                if (self.matchChar('.')) {
                    try self.addToken(.MinusDot, allocator);
                } else if (self.matchChar('>')) {
                    try self.addToken(.RArrow, allocator);
                } else {
                    try self.addToken(.Minus, allocator);
                }
            },

            // ── '/', '/.', '//', '///' ────────────────────────────────────────
            '/' => {
                if (self.matchChar('/')) {
                    if (self.matchChar('/')) {
                        while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                        try self.addToken(.CommentModule, allocator);
                    } else {
                        while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                        try self.addToken(.CommentNormal, allocator);
                    }
                } else if (self.matchChar('.')) {
                    try self.addToken(.SlashDot, allocator);
                } else {
                    try self.addToken(.Slash, allocator);
                }
            },

            // ── '<', '<=', '<.', '<=.', '<<' ─────────────────────────────────
            '<' => {
                if (self.matchChar('<')) {
                    try self.addToken(.LtLt, allocator);
                } else if (self.matchChar('=')) {
                    if (self.matchChar('.')) {
                        try self.addToken(.LessEqualDot, allocator);
                    } else {
                        try self.addToken(.LessEqual, allocator);
                    }
                } else if (self.matchChar('.')) {
                    try self.addToken(.LessDot, allocator);
                } else {
                    try self.addToken(.Less, allocator);
                }
            },

            // ── '>', '>=', '>.', '>=.', '>>' ─────────────────────────────────
            '>' => {
                if (self.matchChar('>')) {
                    try self.addToken(.GtGt, allocator);
                } else if (self.matchChar('=')) {
                    if (self.matchChar('.')) {
                        try self.addToken(.GreaterEqualDot, allocator);
                    } else {
                        try self.addToken(.GreaterEqual, allocator);
                    }
                } else if (self.matchChar('.')) {
                    try self.addToken(.GreaterDot, allocator);
                } else {
                    try self.addToken(.Greater, allocator);
                }
            },

            // ── '|', '||', '|>' ──────────────────────────────────────────────
            '|' => {
                if (self.matchChar('|')) {
                    try self.addToken(.VbarVbar, allocator);
                } else if (self.matchChar('>')) {
                    try self.addToken(.Pipe, allocator);
                } else {
                    try self.addToken(.Vbar, allocator);
                }
            },

            // ── '&', '&&' ────────────────────────────────────────────────────
            '&' => {
                if (self.matchChar('&')) {
                    try self.addToken(.AmperAmper, allocator);
                } else {
                    return LexerError.UnexpectedCharacter;
                }
            },

            // ── '.', '..' ────────────────────────────────────────────────────
            '.' => {
                if (self.matchChar('.')) {
                    try self.addToken(.DotDot, allocator);
                } else {
                    try self.addToken(.Dot, allocator);
                }
            },

            // ── strings ───────────────────────────────────────────────────────
            '"' => try self.scanString(allocator),

            // ── identifiers, keywords, numbers ───────────────────────────────
            else => {
                if (isAlpha(c)) {
                    try self.scanIdentifier(allocator);
                } else if (isDigit(c)) {
                    try self.scanNumber(c, allocator);
                } else {
                    return LexerError.UnexpectedCharacter;
                }
            },
        }
    }

    // ── string scanning with escape validation ───────────────────────────────

    fn scanString(self: *Lexer, allocator: std.mem.Allocator) LexerError!void {
        while (!self.isAtEnd() and self.peek() != '"') {
            if (self.peek() == '\n') self.line += 1;
            if (self.peek() == '\\') {
                _ = self.advance(); // consume '\'
                if (self.isAtEnd()) return LexerError.UnterminatedString;
                const esc = self.advance();
                switch (esc) {
                    'n', 'r', 't', '\\', '"', '0' => {}, // valid escapes
                    'u' => try self.scanUnicodeEscape(),
                    else => {
                        self.lex_error = .{
                            .kind = .BadStringEscape,
                            .start = self.current - 2,
                            .end = self.current,
                            .invalid_char = esc,
                        };
                        return LexerError.LexicalError;
                    },
                }
            } else {
                _ = self.advance();
            }
        }
        if (self.isAtEnd()) return LexerError.UnterminatedString;
        _ = self.advance(); // closing "
        try self.addToken(.StringLiteral, allocator);
    }

    fn scanUnicodeEscape(self: *Lexer) LexerError!void {
        if (self.isAtEnd() or self.peek() != '{') {
            self.lex_error = .{
                .kind = .InvalidUnicodeEscape,
                .unicode_kind = .MissingOpenBrace,
                .start = self.current - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
        _ = self.advance(); // consume '{'

        const hex_start = self.current;
        while (!self.isAtEnd() and self.peek() != '}') {
            const ch = self.peek();
            if (!isHexDigit(ch)) {
                self.lex_error = .{
                    .kind = .InvalidUnicodeEscape,
                    .unicode_kind = .ExpectedHexDigitOrCloseBrace,
                    .start = self.current,
                    .end = self.current + 1,
                    .invalid_char = ch,
                };
                return LexerError.LexicalError;
            }
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            self.lex_error = .{
                .kind = .InvalidUnicodeEscape,
                .unicode_kind = .MissingCloseBrace,
                .start = hex_start,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
        _ = self.advance(); // consume '}'

        const hex_str = self.source[hex_start .. self.current - 1];
        const codepoint = std.fmt.parseUnsigned(u32, hex_str, 16) catch {
            self.lex_error = .{
                .kind = .InvalidUnicodeEscape,
                .unicode_kind = .InvalidCodepoint,
                .start = hex_start - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        };
        if (codepoint > 0x10FFFF) {
            self.lex_error = .{
                .kind = .InvalidUnicodeEscape,
                .unicode_kind = .InvalidCodepoint,
                .start = hex_start - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
    }

    // ── number scanning with 0b, 0o, 0x support ──────────────────────────────

    fn scanNumber(self: *Lexer, first_digit: u8, allocator: std.mem.Allocator) LexerError!void {
        if (first_digit == '0' and !self.isAtEnd()) {
            const prefix = self.peek();
            switch (prefix) {
                'b', 'B' => {
                    _ = self.advance();
                    return self.scanRadixNumber(2, allocator);
                },
                'o', 'O' => {
                    _ = self.advance();
                    return self.scanRadixNumber(8, allocator);
                },
                'x', 'X' => {
                    _ = self.advance();
                    return self.scanRadixNumber(16, allocator);
                },
                else => {},
            }
        }

        // Decimal normal
        while (!self.isAtEnd() and isDigit(self.peek())) _ = self.advance();
        if (!self.isAtEnd() and self.peek() == '.' and self.peekNext() != '.') {
            _ = self.advance();
            while (!self.isAtEnd() and isDigit(self.peek())) _ = self.advance();
        }
        try self.addToken(.NumberLiteral, allocator);
    }

    fn scanRadixNumber(self: *Lexer, radix: u8, allocator: std.mem.Allocator) LexerError!void {
        var has_digits = false;

        while (!self.isAtEnd()) {
            const ch = self.peek();
            // Underscore separator is allowed in numeric literals (e.g. 0b1010_0011)
            if (ch == '_') {
                _ = self.advance();
                continue;
            }
            if (!isAlphaNumeric(ch)) break;

            if (!isValidRadixDigit(ch, radix)) {
                self.lex_error = .{
                    .kind = .DigitOutOfRadix,
                    .start = self.current,
                    .end = self.current + 1,
                    .invalid_char = ch,
                };
                return LexerError.LexicalError;
            }
            _ = self.advance();
            has_digits = true;
        }

        if (!has_digits) {
            self.lex_error = .{
                .kind = .RadixIntNoValue,
                .start = self.start + 1,
                .end = self.start + 1,
            };
            return LexerError.LexicalError;
        }

        try self.addToken(.NumberLiteral, allocator);
    }

    // ── identifier scanning ───────────────────────────────────────────────────

    fn scanIdentifier(self: *Lexer, allocator: std.mem.Allocator) LexerError!void {
        while (!self.isAtEnd() and isAlphaNumeric(self.peek())) _ = self.advance();
        const text = self.source[self.start..self.current];
        try self.addToken(keywordOrIdent(text), allocator);
    }

    // ── primitives ────────────────────────────────────────────────────────────

    fn advance(self: *Lexer) u8 {
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn matchChar(self: *Lexer, expected: u8) bool {
        if (self.isAtEnd()) return false;
        if (self.source[self.current] != expected) return false;
        self.current += 1;
        return true;
    }

    fn peek(self: *Lexer) u8 {
        if (self.isAtEnd()) return 0;
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn addToken(self: *Lexer, kind: TokenKind, allocator: std.mem.Allocator) LexerError!void {
        try self.tokens.append(allocator, .{
            .kind = kind,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
            .col = self.start - self.line_start + 1,
        });
    }

    // ── character classification ──────────────────────────────────────────────

    fn isAlpha(c: u8) bool {
        return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_';
    }

    fn isDigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }

    fn isAlphaNumeric(c: u8) bool {
        return isAlpha(c) or isDigit(c);
    }

    fn isHexDigit(c: u8) bool {
        return (c >= '0' and c <= '9') or
            (c >= 'a' and c <= 'f') or
            (c >= 'A' and c <= 'F');
    }

    fn isValidRadixDigit(c: u8, radix: u8) bool {
        return switch (radix) {
            2 => c == '0' or c == '1',
            8 => c >= '0' and c <= '7',
            16 => isHexDigit(c),
            else => false,
        };
    }

    // ── keyword table ─────────────────────────────────────────────────────────

    fn keywordOrIdent(text: []const u8) TokenKind {
        if (std.mem.eql(u8, text, "as")) return .KwAs;
        if (std.mem.eql(u8, text, "assert")) return .KwAssert;
        if (std.mem.eql(u8, text, "auto")) return .KwAuto;
        if (std.mem.eql(u8, text, "case")) return .KwCase;
        if (std.mem.eql(u8, text, "const")) return .KwConst;
        if (std.mem.eql(u8, text, "delegate")) return .KwDelegate;
        if (std.mem.eql(u8, text, "derive")) return .KwDerive;
        if (std.mem.eql(u8, text, "echo")) return .KwEcho;
        if (std.mem.eql(u8, text, "else")) return .KwElse;
        if (std.mem.eql(u8, text, "fn")) return .KwFn;
        if (std.mem.eql(u8, text, "for")) return .KwFor;
        if (std.mem.eql(u8, text, "from")) return .KwFrom;
        if (std.mem.eql(u8, text, "get")) return .KwGet;
        if (std.mem.eql(u8, text, "if")) return .KwIf;
        if (std.mem.eql(u8, text, "implement")) return .KwImplement;
        if (std.mem.eql(u8, text, "import")) return .KwImport;
        if (std.mem.eql(u8, text, "let")) return .KwLet;
        if (std.mem.eql(u8, text, "macro")) return .KwMacro;
        if (std.mem.eql(u8, text, "new")) return .KwNew;
        if (std.mem.eql(u8, text, "opaque")) return .KwOpaque;
        if (std.mem.eql(u8, text, "panic")) return .KwPanic;
        if (std.mem.eql(u8, text, "private")) return .KwPrivate;
        if (std.mem.eql(u8, text, "pub")) return .KwPub;
        if (std.mem.eql(u8, text, "return")) return .KwReturn;
        if (std.mem.eql(u8, text, "Self")) return .KwSelfType;
        if (std.mem.eql(u8, text, "set")) return .KwSet;
        if (std.mem.eql(u8, text, "struct")) return .KwStruct;
        if (std.mem.eql(u8, text, "test")) return .KwTest;
        if (std.mem.eql(u8, text, "throw")) return .KwThrow;
        if (std.mem.eql(u8, text, "todo")) return .KwTodo;
        if (std.mem.eql(u8, text, "interface")) return .KwInterface;
        if (std.mem.eql(u8, text, "interface")) return .KwInterface;
        if (std.mem.eql(u8, text, "type")) return .KwType;
        if (std.mem.eql(u8, text, "record")) return .KwRecord;
        if (std.mem.eql(u8, text, "use")) return .KwUse;
        if (std.mem.eql(u8, text, "val")) return .KwVal;
        if (std.mem.eql(u8, text, "comptime")) return .KwComptime;
        if (std.mem.eql(u8, text, "syntax")) return .KwSyntax;
        if (std.mem.eql(u8, text, "typeinfo")) return .KwTypeinfo;
        return .Identifier;
    }
};

// ── Public diagnostic helpers ─────────────────────────────────────────────────

/// Returns true if the TokenKind is a reserved word that cannot be
/// used as an identifier in botopink.
pub fn isReservedWord(kind: TokenKind) bool {
    return switch (kind) {
        .KwAuto,
        .KwDelegate,
        .KwEcho,
        .KwElse,
        .KwImplement,
        .KwMacro,
        .KwTest,
        .KwDerive,
        => true,
        else => false,
    };
}

/// Returns the lexeme string for a reserved word TokenKind.
pub fn reservedWordLexeme(kind: TokenKind) []const u8 {
    return switch (kind) {
        .KwAuto => "auto",
        .KwDelegate => "delegate",
        .KwEcho => "echo",
        .KwElse => "else",
        .KwImplement => "implement",
        .KwMacro => "macro",
        .KwTest => "test",
        .KwDerive => "derive",
        else => "<unknown>",
    };
}

/// Returns a human-readable message for a lexical error.
pub fn lexicalErrorMessage(err: LexicalError) []const u8 {
    return switch (err.kind) {
        .DigitOutOfRadix => "Digit out of radix",
        .RadixIntNoValue => "Radix integer prefix requires at least one digit",
        .BadStringEscape => "Invalid string escape sequence",
        .InvalidUnicodeEscape => switch (err.unicode_kind orelse .MissingOpenBrace) {
            .ExpectedHexDigitOrCloseBrace => "Expected a hex digit or '}' in unicode escape",
            .InvalidCodepoint => "Unicode codepoint exceeds U+10FFFF",
            .MissingOpenBrace => "Expected '{' after \\u",
            .MissingCloseBrace => "Missing closing '}' in unicode escape",
        },
        .InvalidTripleEqual => "The === operator does not exist in botopink — use == instead",
        .UnexpectedSemicolon => "Remove this semicolon",
    };
}

/// Formats and prints a lexical error with source context to stderr.
pub fn printLexicalError(source: []const u8, err: LexicalError, path: []const u8) void {
    const line_num = lineOf(source, err.start);
    const line_src = lineSource(source, err.start);
    const col = err.start - lineStartOf(source, err.start);
    const span_len = if (err.end > err.start) err.end - err.start else 1;

    std.debug.print("\nerror: Syntax error\n", .{});
    std.debug.print("  ┌─ {s}:{d}:{d}\n", .{ path, line_num, col + 1 });
    std.debug.print("  │\n", .{});
    std.debug.print("{d} │ {s}\n", .{ line_num, line_src });
    std.debug.print("  │ ", .{});
    for (0..col) |_| std.debug.print(" ", .{});
    for (0..span_len) |_| std.debug.print("^", .{});
    std.debug.print(" {s}\n\n", .{lexicalErrorMessage(err)});
}

fn lineOf(source: []const u8, offset: usize) usize {
    var line: usize = 1;
    for (source[0..@min(offset, source.len)]) |c| {
        if (c == '\n') line += 1;
    }
    return line;
}

fn lineStartOf(source: []const u8, offset: usize) usize {
    var i: usize = @min(offset, source.len);
    while (i > 0 and source[i - 1] != '\n') i -= 1;
    return i;
}

fn lineSource(source: []const u8, offset: usize) []const u8 {
    const start = lineStartOf(source, offset);
    var end = start;
    while (end < source.len and source[end] != '\n') end += 1;
    return source[start..end];
}
