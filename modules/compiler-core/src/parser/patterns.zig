//! Pattern-matching sub-grammar extracted from `parser.zig`:
//! `case` expressions and the pattern grammar (`a | b`, variants, lists).
//! Free functions on `*Parser`; `parser.zig` re-exports each as a thin alias.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const Expr = parser.Expr;
const Stmt = parser.Stmt;
const Pattern = parser.Pattern;
const CollectionExpr = parser.CollectionExpr;
const CaseArm = parser.CaseArm;
const ListPatternElem = parser.ListPatternElem;
const prec = This.prec;
const locFromToken = This.locFromToken;
const commentText = This.commentText;

pub fn parseCaseExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
    const caseTok = try this.consume(.case);

    // Subjects: either `(expr)` for single (possibly tuple) subject,
    // or comma-separated expressions for multiple subjects.
    var subjects: std.ArrayList(Expr) = .empty;
    errdefer {
        for (subjects.items) |*s| s.deinit(alloc);
        subjects.deinit(alloc);
    }

    if (this.check(.leftParenthesis)) {
        // Single subject wrapped in parens (e.g. tuple)
        _ = this.advance(); // consume '('
        const e = try this.parseBinaryExpr(alloc, prec.equality);
        _ = try this.consume(.rightParenthesis);
        try subjects.append(alloc, e);
    } else {
        // Multiple subjects separated by commas
        while (!this.check(.leftBrace) and !this.check(.endOfFile)) {
            try subjects.append(alloc, try this.parseBinaryExpr(alloc, prec.equality));
            if (!this.match(.comma)) break;
        }
    }

    _ = try this.consume(.leftBrace);

    var arms: std.ArrayList(CaseArm) = .empty;
    errdefer {
        for (arms.items) |*a| a.deinit(alloc);
        arms.deinit(alloc);
    }

    var trailingComments: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (trailingComments.items) |c| alloc.free(c);
        trailingComments.deinit(alloc);
    }

    while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
        // Use token line numbers to detect empty lines between arms
        const prevLine = if (this.current > 0) this.tokens[this.current - 1].line else 1;
        const currLine = this.peek().line;
        const emptyLinesBefore: u32 = if (arms.items.len > 0 and currLine > prevLine + 1)
            @intCast(currLine - prevLine - 1)
        else
            0;

        // Handle comments inside the case block (trailing after last arm)
        if (this.isComment()) {
            while (this.isComment()) {
                const cTok = this.advance();
                try trailingComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            }
            continue;
        }
        if (this.check(.rightBrace)) break;

        const firstPat = try this.parsePattern(alloc);
        const pattern: ast.Pattern = if (this.match(.comma)) blk: {
            var pats: std.ArrayList(ast.Pattern) = .empty;
            errdefer {
                for (pats.items) |*p| p.deinit(alloc);
                pats.deinit(alloc);
            }
            try pats.append(alloc, firstPat);
            while (true) {
                try pats.append(alloc, try this.parsePattern(alloc));
                if (!this.match(.comma)) break;
            }
            break :blk .{ .multi = try pats.toOwnedSlice(alloc) };
        } else firstPat;
        // Optional guard clause: `pattern if <expr> -> body`.
        const guard: ?Expr = if (this.match(.@"if")) try this.parseExpr(alloc) else null;
        errdefer if (guard) |*g| @constCast(g).deinit(alloc);
        _ = try this.consume(.rightArrow);
        // A `{` starts a block arm body (zero-param lambda with semicolon-separated stmts).
        const body = if (this.check(.leftBrace)) blk: {
            const braceTok = this.advance();
            // Body is already-consumed `{ stmt; ... }` — wrap as zero-param lambda
            var blockStmts: std.ArrayList(Stmt) = .empty;
            errdefer {
                for (blockStmts.items) |*s| s.deinit(alloc);
                blockStmts.deinit(alloc);
            }
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                const e = try this.parseExpr(alloc);
                _ = try this.consume(.semicolon);
                try blockStmts.append(alloc, .{ .expr = e });
            }
            _ = try this.consume(.rightBrace);
            var emptyParams: std.ArrayList([]const u8) = .empty;
            break :blk Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{
                .syntax = .lambda,
                .params = try emptyParams.toOwnedSlice(alloc),
                .body = try blockStmts.toOwnedSlice(alloc),
            } } };
        } else try this.parseExpr(alloc);
        // Accept both semicolon and comma as arm terminators
        if (!this.match(.semicolon)) {
            _ = this.match(.comma); // fallback to comma
        }
        try arms.append(alloc, .{ .pattern = pattern, .body = body, .guard = guard, .emptyLinesBefore = emptyLinesBefore });
    }

    _ = try this.consume(.rightBrace);

    return .{
        .loc = locFromToken(caseTok),
        .kind = .{
            .case = .{
                .subjects = try subjects.toOwnedSlice(alloc),
                .arms = try arms.toOwnedSlice(alloc),
                .trailingComments = try trailingComments.toOwnedSlice(alloc),
            },
        },
    };
}

/// Parses a full pattern, including OR chains: `a | b | c`
pub fn parsePattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
    const first = try this.parseSimplePattern(alloc);

    if (!this.check(.verticalBar)) return first;

    // OR pattern: collect alternatives
    var alts: std.ArrayList(Pattern) = .empty;
    errdefer {
        for (alts.items) |*p| p.deinit(alloc);
        alts.deinit(alloc);
    }
    try alts.append(alloc, first);
    while (this.match(.verticalBar)) {
        const next = try this.parseSimplePattern(alloc);
        try alts.append(alloc, next);
    }
    return Pattern{ .@"or" = try alts.toOwnedSlice(alloc) };
}

/// Parses a single (non-OR) pattern.
pub fn parseSimplePattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
    // `_` ---- wildcard
    if (this.check(.underscore)) {
        _ = this.advance();
        return Pattern.wildcard;
    }

    // Number literal: `42`
    if (this.check(.numberLiteral)) {
        return Pattern{ .numberLit = this.advance().lexeme };
    }

    // String literal: `"hello"` or `"""..."""`
    if (this.check(.stringLiteral)) {
        const tok = this.advance();
        return Pattern{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] };
    }
    if (this.check(.multilineStringLiteral)) {
        const tok = this.advance();
        // Remove the triple quotes from both ends
        return Pattern{ .stringLit = tok.lexeme[3 .. tok.lexeme.len - 3] };
    }

    // List pattern: `[...]`
    if (this.check(.leftSquareBracket)) {
        return try this.parseListPattern(alloc);
    }

    // identifier: variant name or binding variable
    if (this.check(.identifier)) {
        const name = this.advance().lexeme;

        // Variant with bound fields: `Rgb(r, g, b)` or literals: `Ok(1)`
        if (this.check(.leftParenthesis)) {
            _ = this.advance(); // consume '('

            // Determine the variant payload: `fields` (identifiers) or `literals` (literals or patterns)
            var isLiterals = false;
            const lookahead = this.tokens[this.current];
            if (lookahead.kind != .rightParenthesis) {
                // Check if it's a literal (number, string) or a pattern (underscore, list, etc.)
                if (lookahead.kind == .numberLiteral or
                    lookahead.kind == .stringLiteral or
                    lookahead.kind == .multilineStringLiteral or
                    lookahead.kind == .underscore or
                    lookahead.kind == .leftSquareBracket)
                {
                    isLiterals = true;
                }
            }

            if (isLiterals) {
                // `literals` payload (can contain nested patterns)
                var args: std.ArrayList(Pattern) = .empty;
                errdefer {
                    for (args.items) |*a| a.deinit(alloc);
                    args.deinit(alloc);
                }

                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const pattern = try this.parseSimplePattern(alloc);
                    try args.append(alloc, pattern);
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);

                return Pattern{ .variant = .{
                    .name = name,
                    .payload = .{ .literals = try args.toOwnedSlice(alloc) },
                } };
            } else {
                // `fields` payload (existing logic)
                var bindings: std.ArrayList([]const u8) = .empty;
                errdefer bindings.deinit(alloc);

                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const bind = (try this.consume(.identifier)).lexeme;
                    try bindings.append(alloc, bind);
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);

                return Pattern{ .variant = .{
                    .name = name,
                    .payload = .{ .fields = try bindings.toOwnedSlice(alloc) },
                } };
            }
        }

        // `Variant binding` pattern: `Ok ok` — two identifiers, bind whole payload
        if (this.check(.identifier)) {
            const binding = this.advance().lexeme;
            return Pattern{ .variant = .{
                .name = name,
                .payload = .{ .binding = binding },
            } };
        }

        return Pattern{ .ident = name };
    }

    return ParseError.UnexpectedToken;
}

/// Parses a list pattern: `[]`, `[1]`, `[4, ..]`, `[_, _]`, `[first, ..rest]`
pub fn parseListPattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
    _ = try this.consume(.leftSquareBracket);

    var elems: std.ArrayList(ListPatternElem) = .empty;
    errdefer elems.deinit(alloc);
    var spread: ?[]const u8 = null;

    while (!this.check(.rightSquareBracket) and !this.check(.endOfFile)) {
        // `..` or `..rest`
        if (this.match(.dotDot)) {
            spread = if (this.check(.identifier)) this.advance().lexeme else "";
            break;
        }

        const elem: ListPatternElem =
            if (this.check(.underscore)) blk: {
                _ = this.advance();
                break :blk .wildcard;
            } else if (this.check(.numberLiteral)) blk: {
                break :blk .{ .numberLit = this.advance().lexeme };
            } else if (this.check(.identifier)) blk: {
                break :blk .{ .bind = this.advance().lexeme };
            } else {
                return ParseError.UnexpectedToken;
            };

        try elems.append(alloc, elem);
        if (!this.match(.comma)) break;
    }

    _ = try this.consume(.rightSquareBracket);

    return Pattern{ .list = .{
        .elems = try elems.toOwnedSlice(alloc),
        .spread = spread,
    } };
}
