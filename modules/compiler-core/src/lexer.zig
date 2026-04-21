const std = @import("std");
const token = @import("./lexer/token.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

// ── Lexical error types ───────────────────────────────────────────────────────

pub const LexicalErrorType = enum {
    /// Digit outside the numeric base, e.g. '2' in 0b012, '8' in 0o178
    DigitOutOfRadix,
    /// Radix prefix with no digits, e.g. 0x with no hex digits
    RadixIntNovalue,
    /// Invalid string escape, e.g. \g
    BadStringEscape,
    /// Invalid unicode escape, e.g. \u{z} or \u{110000}
    InvalidUnicodeEscape,
    /// The === operator does not exist in botopink
    InvalidTripleEqual,
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
    unicodeKind: ?InvalidUnicodeEscapeKind = null,
    /// Start position of the error in source (byte offset)
    start: usize,
    /// End position of the error in source (byte offset, exclusive)
    end: usize,
    /// The invalid character (for DigitOutOfRadix and BadStringEscape)
    invalidChar: ?u8 = null,
};

pub const LexerError = error{
    UnterminatedString,
    UnexpectedCharacter,
    OutOfMemory,
    /// Structured lexical error ---- see Lexer.lexError for details
    LexicalError,
};

// ── Lexer ─────────────────────────────────────────────────────────────────────

pub const Lexer = struct {
    source: []const u8,
    start: usize,
    current: usize,
    line: usize,
    /// Byte offset where the current line started (for column computation).
    lineStart: usize,
    tokens: std.ArrayList(Token),
    /// Populated when scanAll returns LexerError.LexicalError
    lexError: ?LexicalError,

    pub fn init(source: []const u8) Lexer {
        return .{
            .source = source,
            .start = 0,
            .current = 0,
            .line = 1,
            .lineStart = 0,
            .tokens = .empty,
            .lexError = null,
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
        try self.tokens.append(allocator, .{ .kind = .endOfFile, .lexeme = "", .line = self.line, .col = self.current - self.lineStart + 1 });
        return self.tokens.items;
    }

    fn scanToken(self: *Lexer, allocator: std.mem.Allocator) LexerError!void {
        const c = self.advance();
        switch (c) {
            ' ', '\r', '\t' => {},
            '\n' => {
                self.line += 1;
                self.lineStart = self.current;
            },

            // Semicolon
            ';' => try self.addToken(.semicolon, allocator),

            // ── groupings ────────────────────────────────────────────────────
            '(' => try self.addToken(.leftParenthesis, allocator),
            ')' => try self.addToken(.rightParenthesis, allocator),
            '[' => try self.addToken(.leftSquareBracket, allocator),
            ']' => try self.addToken(.rightSquareBracket, allocator),
            '{' => try self.addToken(.leftBrace, allocator),
            '}' => try self.addToken(.rightBrace, allocator),

            // ── single-char punctuation ───────────────────────────────────────
            ',' => try self.addToken(.comma, allocator),
            ':' => try self.addToken(.colon, allocator),
            '%' => try self.addToken(.percent, allocator),
            '*' => try self.addToken(.star, allocator),
            '#' => try self.addToken(.hash, allocator),
            '?' => try self.addToken(.questionMark, allocator),
            '@' => {
                if (!self.isAtEnd() and isAlpha(self.peek())) {
                    while (!self.isAtEnd() and isAlphaNumeric(self.peek())) _ = self.advance();
                    try self.addToken(.builtinIdent, allocator);
                } else {
                    try self.addToken(.at, allocator);
                }
            },

            // ── '=' or '==' ---- detect invalid '===' ───────────────────────────
            '=' => {
                if (self.matchChar('=')) {
                    if (self.matchChar('=')) {
                        // === is not valid in botopink
                        self.lexError = .{
                            .kind = .InvalidTripleEqual,
                            .start = self.start,
                            .end = self.current,
                        };
                        return LexerError.LexicalError;
                    }
                    try self.addToken(.equalEqual, allocator);
                } else {
                    try self.addToken(.equal, allocator);
                }
            },

            // ── '!' or '!=' ──────────────────────────────────────────────────
            '!' => {
                if (self.matchChar('=')) {
                    try self.addToken(.notEqual, allocator);
                } else {
                    try self.addToken(.bang, allocator);
                }
            },

            // ── '+', '+=' ─────────────────────────────────────────────────────
            '+' => {
                if (self.matchChar('=')) {
                    try self.addToken(.plusEqual, allocator);
                } else {
                    try self.addToken(.plus, allocator);
                }
            },

            // ── '-', '->' ─────────────────────────────────────────────────────
            '-' => {
                if (self.matchChar('>')) {
                    try self.addToken(.rightArrow, allocator);
                } else {
                    try self.addToken(.minus, allocator);
                }
            },

            // ── '/', '//', '///', '////' ──────────────────────────────────────
            '/' => {
                if (self.matchChar('/')) {
                    if (self.matchChar('/')) {
                        if (self.matchChar('/')) {
                            // '////' — module-level documentation
                            while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                            try self.addToken(.commentModule, allocator);
                        } else {
                            // '///' — type/function documentation
                            while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                            try self.addToken(.commentDoc, allocator);
                        }
                    } else {
                        // '//' — regular comment
                        while (!self.isAtEnd() and self.peek() != '\n') _ = self.advance();
                        try self.addToken(.commentNormal, allocator);
                    }
                } else {
                    try self.addToken(.slash, allocator);
                }
            },

            // ── '<', '<=', '<<' ───────────────────────────────────────────────
            '<' => {
                if (self.matchChar('<')) {
                    try self.addToken(.lessThanLessThan, allocator);
                } else if (self.matchChar('=')) {
                    try self.addToken(.lessThanEqual, allocator);
                } else {
                    try self.addToken(.lessThan, allocator);
                }
            },

            // ── '>', '>=', '>>' ───────────────────────────────────────────────
            '>' => {
                if (self.matchChar('>')) {
                    try self.addToken(.greaterThanGreaterThan, allocator);
                } else if (self.matchChar('=')) {
                    try self.addToken(.greaterThanEqual, allocator);
                } else {
                    try self.addToken(.greaterThan, allocator);
                }
            },

            // ── '|', '||', '|>' ──────────────────────────────────────────────
            '|' => {
                if (self.matchChar('|')) {
                    try self.addToken(.verticalBarVerticalBar, allocator);
                } else if (self.matchChar('>')) {
                    try self.addToken(.pipe, allocator);
                } else {
                    try self.addToken(.verticalBar, allocator);
                }
            },

            // ── '&', '&&' ────────────────────────────────────────────────────
            '&' => {
                if (self.matchChar('&')) {
                    try self.addToken(.amperAmper, allocator);
                } else {
                    return LexerError.UnexpectedCharacter;
                }
            },

            // ── '.', '..' ────────────────────────────────────────────────────
            '.' => {
                if (self.matchChar('.')) {
                    try self.addToken(.dotDot, allocator);
                } else {
                    try self.addToken(.dot, allocator);
                }
            },

            // ── strings ───────────────────────────────────────────────────────
            '"' => {
                // Check for multiline string (""")
                if (self.peek() == '"' and self.peekNext() == '"') {
                    _ = self.advance(); // consume second "
                    _ = self.advance(); // consume third "
                    try self.scanMultilineString(allocator);
                } else {
                    try self.scanString(allocator);
                }
            },

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
                        self.lexError = .{
                            .kind = .BadStringEscape,
                            .start = self.current - 2,
                            .end = self.current,
                            .invalidChar = esc,
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
        try self.addToken(.stringLiteral, allocator);
    }

    // ── multiline string scanning ───────────────────────────────────────────────

    fn scanMultilineString(self: *Lexer, allocator: std.mem.Allocator) LexerError!void {
        // Multiline strings span from """ to """ and preserve newlines
        while (!self.isAtEnd()) {
            // Check for closing """
            if (self.peek() == '"' and self.peekNext() == '"' and self.peekNextNext() == '"') {
                _ = self.advance(); // consume first "
                _ = self.advance(); // consume second "
                _ = self.advance(); // consume third "
                try self.addToken(.multilineStringLiteral, allocator);
                return;
            }

            if (self.peek() == '\n') self.line += 1;
            if (self.peek() == '\\') {
                _ = self.advance(); // consume '\'
                if (self.isAtEnd()) return LexerError.UnterminatedString;
                const esc = self.advance();
                switch (esc) {
                    'n', 'r', 't', '\\', '"', '0' => {}, // valid escapes
                    'u' => try self.scanUnicodeEscape(),
                    else => {
                        self.lexError = .{
                            .kind = .BadStringEscape,
                            .start = self.current - 2,
                            .end = self.current,
                            .invalidChar = esc,
                        };
                        return LexerError.LexicalError;
                    },
                }
            } else {
                _ = self.advance();
            }
        }
        return LexerError.UnterminatedString;
    }

    fn scanUnicodeEscape(self: *Lexer) LexerError!void {
        if (self.isAtEnd() or self.peek() != '{') {
            self.lexError = .{
                .kind = .InvalidUnicodeEscape,
                .unicodeKind = .MissingOpenBrace,
                .start = self.current - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
        _ = self.advance(); // consume '{'

        const hexStart = self.current;
        while (!self.isAtEnd() and self.peek() != '}') {
            const ch = self.peek();
            if (!isHexDigit(ch)) {
                self.lexError = .{
                    .kind = .InvalidUnicodeEscape,
                    .unicodeKind = .ExpectedHexDigitOrCloseBrace,
                    .start = self.current,
                    .end = self.current + 1,
                    .invalidChar = ch,
                };
                return LexerError.LexicalError;
            }
            _ = self.advance();
        }

        if (self.isAtEnd()) {
            self.lexError = .{
                .kind = .InvalidUnicodeEscape,
                .unicodeKind = .MissingCloseBrace,
                .start = hexStart,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
        _ = self.advance(); // consume '}'

        const hexStr = self.source[hexStart .. self.current - 1];
        const codepoint = std.fmt.parseUnsigned(u32, hexStr, 16) catch {
            self.lexError = .{
                .kind = .InvalidUnicodeEscape,
                .unicodeKind = .InvalidCodepoint,
                .start = hexStart - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        };
        if (codepoint > 0x10FFFF) {
            self.lexError = .{
                .kind = .InvalidUnicodeEscape,
                .unicodeKind = .InvalidCodepoint,
                .start = hexStart - 2,
                .end = self.current,
            };
            return LexerError.LexicalError;
        }
    }

    // ── number scanning with 0b, 0o, 0x support ──────────────────────────────

    fn scanNumber(self: *Lexer, firstDigit: u8, allocator: std.mem.Allocator) LexerError!void {
        if (firstDigit == '0' and !self.isAtEnd()) {
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
        while (!self.isAtEnd()) {
            const ch = self.peek();
            if (ch == '_') {
                // Allow underscores as digit separators (Kotlin style: 1_000_000)
                if (self.current + 1 < self.source.len and isDigit(self.source[self.current + 1])) {
                    _ = self.advance();
                    continue;
                } else {
                    // Underscore not followed by digit - stop scanning
                    break;
                }
            }
            if (!isDigit(ch)) break;
            _ = self.advance();
        }
        if (!self.isAtEnd() and self.peek() == '.' and self.peekNext() != '.') {
            _ = self.advance();
            while (!self.isAtEnd()) {
                const ch = self.peek();
                if (ch == '_') {
                    // Allow underscores in decimal part
                    if (self.current + 1 < self.source.len and isDigit(self.source[self.current + 1])) {
                        _ = self.advance();
                        continue;
                    } else {
                        break;
                    }
                }
                if (!isDigit(ch)) break;
                _ = self.advance();
            }
        }
        // Check for scientific notation: e.g. 1.0e10 or 1e10
        if (!self.isAtEnd() and (self.peek() == 'e' or self.peek() == 'E')) {
            _ = self.advance();
            // Optional sign for exponent
            if (!self.isAtEnd() and (self.peek() == '+' or self.peek() == '-')) {
                _ = self.advance();
            }
            while (!self.isAtEnd() and isDigit(self.peek())) _ = self.advance();
        }
        try self.addToken(.numberLiteral, allocator);
    }

    fn scanRadixNumber(self: *Lexer, radix: u8, allocator: std.mem.Allocator) LexerError!void {
        var hasDigits = false;

        while (!self.isAtEnd()) {
            const ch = self.peek();
            // Underscore separator is allowed in numeric literals (e.g. 0b1010_0011)
            if (ch == '_') {
                _ = self.advance();
                continue;
            }
            if (!isAlphaNumeric(ch)) break;

            if (!isValidRadixDigit(ch, radix)) {
                self.lexError = .{
                    .kind = .DigitOutOfRadix,
                    .start = self.current,
                    .end = self.current + 1,
                    .invalidChar = ch,
                };
                return LexerError.LexicalError;
            }
            _ = self.advance();
            hasDigits = true;
        }

        if (!hasDigits) {
            self.lexError = .{
                .kind = .RadixIntNovalue,
                .start = self.start + 1,
                .end = self.start + 1,
            };
            return LexerError.LexicalError;
        }

        try self.addToken(.numberLiteral, allocator);
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

    fn peekNextNext(self: *Lexer) u8 {
        if (self.current + 2 >= self.source.len) return 0;
        return self.source[self.current + 2];
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current >= self.source.len;
    }

    fn addToken(self: *Lexer, kind: TokenKind, allocator: std.mem.Allocator) LexerError!void {
        try self.tokens.append(allocator, .{
            .kind = kind,
            .lexeme = self.source[self.start..self.current],
            .line = self.line,
            .col = self.start - self.lineStart + 1,
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
        if (std.mem.eql(u8, text, "_")) return .underscore;
        if (std.mem.eql(u8, text, "as")) return .as;
        if (std.mem.eql(u8, text, "assert")) return .assert;
        if (std.mem.eql(u8, text, "auto")) return .auto;
        if (std.mem.eql(u8, text, "case")) return .case;
        // 'const' is not a surface keyword in botopink; use 'val' instead.
        if (std.mem.eql(u8, text, "default")) return .default;
        if (std.mem.eql(u8, text, "delegate")) return .delegate;
        if (std.mem.eql(u8, text, "derive")) return .derive;
        if (std.mem.eql(u8, text, "echo")) return .echo;
        if (std.mem.eql(u8, text, "else")) return .@"else";
        if (std.mem.eql(u8, text, "enum")) return .@"enum";
        if (std.mem.eql(u8, text, "extends")) return .extends;
        if (std.mem.eql(u8, text, "fn")) return .@"fn";
        if (std.mem.eql(u8, text, "for")) return .@"for";
        if (std.mem.eql(u8, text, "from")) return .from;
        if (std.mem.eql(u8, text, "get")) return .get;
        if (std.mem.eql(u8, text, "if")) return .@"if";
        if (std.mem.eql(u8, text, "implement")) return .implement;
        if (std.mem.eql(u8, text, "import")) return .import;
        // `let` is an alias for `val` (immutable binding)
        if (std.mem.eql(u8, text, "macro")) return .macro;
        if (std.mem.eql(u8, text, "new")) return .new;
        if (std.mem.eql(u8, text, "opaque")) return .@"opaque";
        if (std.mem.eql(u8, text, "private")) return .private;
        if (std.mem.eql(u8, text, "pub")) return .@"pub";
        if (std.mem.eql(u8, text, "return")) return .@"return";
        if (std.mem.eql(u8, text, "Self")) return .selfType;
        if (std.mem.eql(u8, text, "set")) return .set;
        if (std.mem.eql(u8, text, "struct")) return .@"struct";
        if (std.mem.eql(u8, text, "test")) return .@"test";
        if (std.mem.eql(u8, text, "throw")) return .throw;
        if (std.mem.eql(u8, text, "interface")) return .interface;
        if (std.mem.eql(u8, text, "type")) return .type;
        if (std.mem.eql(u8, text, "record")) return .record;
        if (std.mem.eql(u8, text, "use")) return .use;
        if (std.mem.eql(u8, text, "val")) return .val;
        if (std.mem.eql(u8, text, "var")) return .@"var";
        if (std.mem.eql(u8, text, "comptime")) return .@"comptime";
        if (std.mem.eql(u8, text, "syntax")) return .syntax;
        if (std.mem.eql(u8, text, "typeinfo")) return .typeinfo;
        if (std.mem.eql(u8, text, "break")) return .@"break";
        if (std.mem.eql(u8, text, "loop")) return .loop;
        if (std.mem.eql(u8, text, "continue")) return .@"continue";
        if (std.mem.eql(u8, text, "yield")) return .yield;
        if (std.mem.eql(u8, text, "declare")) return .declare;
        if (std.mem.eql(u8, text, "null")) return .null;
        if (std.mem.eql(u8, text, "try")) return .@"try";
        if (std.mem.eql(u8, text, "catch")) return .@"catch";

        return .identifier;
    }
};

// ── Public diagnostic helpers ─────────────────────────────────────────────────

/// Returns true if the TokenKind is a reserved word that cannot be
/// used as an identifier in botopink.
pub fn isReservedWord(kind: TokenKind) bool {
    return switch (kind) {
        .auto,
        .delegate,
        .echo,
        .@"else",
        .implement,
        .macro,
        .@"test",
        .derive,
        => true,
        else => false,
    };
}

/// Returns the lexeme string for a reserved word TokenKind.
pub fn reservedWordLexeme(kind: TokenKind) []const u8 {
    return switch (kind) {
        .auto => "auto",
        .delegate => "delegate",
        .echo => "echo",
        .@"else" => "else",
        .implement => "implement",
        .macro => "macro",
        .@"test" => "test",
        .derive => "derive",
        else => "<unknown>",
    };
}

/// Returns a human-readable message for a lexical error.
pub fn lexicalErrorMessage(err: LexicalError) []const u8 {
    return switch (err.kind) {
        .DigitOutOfRadix => "Digit out of radix",
        .RadixIntNovalue => "Radix integer prefix requires at least one digit",
        .BadStringEscape => "Invalid string escape sequence",
        .InvalidUnicodeEscape => switch (err.unicodeKind orelse .MissingOpenBrace) {
            .ExpectedHexDigitOrCloseBrace => "Expected a hex digit or '}' in unicode escape",
            .InvalidCodepoint => "Unicode codepoint exceeds U+10FFFF",
            .MissingOpenBrace => "Expected '{' after \\u",
            .MissingCloseBrace => "Missing closing '}' in unicode escape",
        },
        .InvalidTripleEqual => "The === operator does not exist in botopink ---- use == instead",
    };
}

/// Formats and prints a lexical error with source context to stderr.
pub fn printLexicalError(source: []const u8, err: LexicalError, path: []const u8) void {
    const lineNum = lineOf(source, err.start);
    const lineSrc = lineSource(source, err.start);
    const col = err.start - lineStartOf(source, err.start);
    const spanLen = if (err.end > err.start) err.end - err.start else 1;

    std.debug.print("\nerror: Lexical error\n", .{});
    std.debug.print("  ┌─ {s}:{d}:{d}\n", .{ path, lineNum, col + 1 });
    std.debug.print("  │\n", .{});
    std.debug.print("{d} │ {s}\n", .{ lineNum, lineSrc });
    std.debug.print("  │ ", .{});
    for (0..col) |_| std.debug.print(" ", .{});
    for (0..spanLen) |_| std.debug.print("^", .{});
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
