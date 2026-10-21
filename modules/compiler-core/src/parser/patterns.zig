//! Pattern-matching sub-grammar extracted from `parser.zig`:
//! `case` expressions and the pattern grammar (`a | b`, variants, lists).
//! Free functions on `*Parser`; `parser.zig` re-exports each as a thin alias.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");
const exprs = @import("exprs.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const ParseErrorInfo = parser.ParseErrorInfo;
const Token = parser.Token;
const Expr = parser.Expr;
const Stmt = parser.Stmt;
const Pattern = parser.Pattern;
const CollectionExpr = parser.CollectionExpr;
const CaseArm = parser.CaseArm;
const ListPatternElem = parser.ListPatternElem;
const prec = This.prec;
const locFromToken = This.locFromToken;
const spanLexemes = This.spanLexemes;
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
        const e = try this.parseExprAtStart(alloc, prec.equality);
        _ = try this.consume(.rightParenthesis);
        try subjects.append(alloc, e);
    } else {
        // Multiple subjects separated by commas
        while (!this.check(.leftBrace) and !this.check(.endOfFile)) {
            try subjects.append(alloc, try this.parseExprAtStart(alloc, prec.equality));
            if (!this.match(.comma)) break;
        }
    }

    _ = try this.consume(.leftBrace);

    var arms: std.ArrayList(CaseArm) = .empty;
    errdefer {
        for (arms.items) |*a| a.deinit(alloc);
        arms.deinit(alloc);
    }

    // Decision 54 — set by a `null` arm, read by `rejectNonPatternArm`: the
    // arm after it may be the bare binder the `?T` form is written with.
    var sawNullArm = false;

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

        const patTok = this.peek();
        // The first token of each subject's pattern, so a refusal lands on the
        // offending one (decision 602: `m` in `Shape.Square(side), m`).
        var subjectToks: std.ArrayList(Token) = .empty;
        defer subjectToks.deinit(alloc);
        try subjectToks.append(alloc, patTok);
        // Decision 810 (3) — a generic type pattern, `Box<T> { b -> … }`: the
        // pattern is the type's name (what a backend tests, the type's
        // identity) and the written arguments ride on the arm for the checker.
        var patternTypeArgs: []ast.TypeRef = &.{};
        errdefer if (patternTypeArgs.len > 0) {
            for (patternTypeArgs) |*a| a.deinit(alloc);
            alloc.free(patternTypeArgs);
        };
        const firstPat = if (patTok.kind == .identifier and this.peekAt(1).kind == .lessThan) blk: {
            const ref = try this.parseTypeRefMember(alloc);
            if (ref != .generic or ref.unionMembers() != null) {
                var r = ref;
                r.deinit(alloc);
                this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, patTok);
                return ParseError.UnexpectedToken;
            }
            patternTypeArgs = ref.generic.args;
            break :blk ast.Pattern{ .ident = ref.generic.name };
        } else try this.parsePattern(alloc);
        const pattern: ast.Pattern = if (this.match(.comma)) blk: {
            var pats: std.ArrayList(ast.Pattern) = .empty;
            errdefer {
                for (pats.items) |*p| p.deinit(alloc);
                pats.deinit(alloc);
            }
            try pats.append(alloc, firstPat);
            while (true) {
                try subjectToks.append(alloc, this.peek());
                try pats.append(alloc, try this.parsePattern(alloc));
                if (!this.match(.comma)) break;
            }
            break :blk .{ .multi = try pats.toOwnedSlice(alloc) };
        } else firstPat;
        // The guard: decision 8's `when (…)` (§5.3), or the pre-decision-8
        // `pattern if <expr> -> body`. `when` is special only here — anywhere
        // else it is an ordinary identifier — so it is matched by lexeme.
        const guard: ?Expr = if (this.match(.@"if"))
            try this.parseExpr(alloc)
        else if (checkWhenGuard(this)) blk: {
            _ = this.advance(); // `when`
            _ = try this.consume(.leftParenthesis);
            const g = try this.parseBinaryExpr(alloc, prec.lowest);
            _ = try this.consume(.rightParenthesis);
            break :blk g;
        } else null;
        errdefer if (guard) |*g| @constCast(g).deinit(alloc);

        // Decision 8 §5.1: `Pattern { body }`. The body is a lambda body — a
        // leading `name ->` binds the whole matched value (P1) and the last
        // expression is the arm's value (P3) — so it lands as a lambda, the
        // shape the pre-decision-8 block arm already produced. An arm body with
        // one parameter can only come from this form.
        const body = if (this.check(.leftBrace)) blk: {
            rejectArm(this, pattern, patTok, subjectToks.items, sawNullArm, .braced) catch |e| {
                @constCast(&pattern).deinit(alloc);
                return e;
            };
            _ = this.advance(); // `{`
            break :blk Expr{ .function = try this.parseLambdaBody(alloc) };
        } else blk: {
            // The `pattern -> value` arm is judged as the braced one is: a
            // lower-case name alone (`k -> k + 1`) is no pattern — accepted,
            // commonJS bound nothing and failed `k is not defined`. A guarded
            // one (`x if x > 3 -> 1`) is the pre-decision-8 binder every
            // backend binds, and stays. A multi-subject arm is refused its bare
            // names, guarded or not (decision 602: `Shape.Square(side), m -> …`
            // is `case-bare-name-arm` at `m`; `_, _ if a > b -> …`).
            if (this.check(.rightArrow) and ((guard == null and pattern == .ident) or pattern == .multi)) rejectArm(this, pattern, patTok, subjectToks.items, sawNullArm, .arrow) catch |e| {
                @constCast(&pattern).deinit(alloc);
                return e;
            };
            _ = try this.consume(.rightArrow);
            // A lambda literal is the arm's VALUE (`A(x) -> { item -> f(item) }`,
            // row 28): a `{` whose head is `->` or `a, b ->` is the lambda
            // `parsePrimary` reads, wrapped as the one statement of a block arm
            // body — a lambda body with a parameter would be §5.1's binder of
            // the matched value instead.
            if (this.check(.leftBrace) and exprs.lambdaHeadAt(this, this.current + 1)) {
                const braceTok = this.peek();
                const value = try this.parseExpr(alloc);
                const stmts = try alloc.alloc(Stmt, 1);
                stmts[0] = .{ .expr = value };
                break :blk Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{
                    .syntax = .lambda,
                    .params = &.{},
                    .body = stmts,
                } } };
            }
            // A `{` starts a block arm body (zero-param lambda with semicolon-separated stmts).
            break :blk if (this.check(.leftBrace)) blk2: {
                const braceTok = this.advance();
                // Decision 525 — `p -> { … }` is a block: its last expression
                // written without `;` is the arm's value; a `//` comment
                // between its statements is kept (the shared block body).
                const blockStmts = try this.parseBlockBody(alloc, .{
                    .trackEmptyLines = true,
                    .handleComments = true,
                    .semicolonPolicy = .requiredExceptLast,
                    .markTail = true,
                    .bracedTail = true,
                });
                errdefer {
                    for (blockStmts) |*s| s.deinit(alloc);
                    alloc.free(blockStmts);
                }
                var emptyParams: std.ArrayList([]const u8) = .empty;
                break :blk2 Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{
                    .syntax = .lambda,
                    .params = try emptyParams.toOwnedSlice(alloc),
                    .body = blockStmts,
                } } };
            } else try this.parseExpr(alloc);
        };
        // Accept both semicolon and comma as arm terminators
        if (!this.match(.semicolon)) {
            _ = this.match(.comma); // fallback to comma
        }
        if (pattern == .ident and std.mem.eql(u8, pattern.ident, "null")) sawNullArm = true;
        try arms.append(alloc, .{
            .pattern = pattern,
            .body = body,
            .guard = guard,
            .emptyLinesBefore = emptyLinesBefore,
            .patternLoc = locFromToken(patTok),
            .patternTypeArgs = patternTypeArgs,
        });
        patternTypeArgs = &.{};
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

    // `null` ---- decision 54's optional pattern. It lands as `.ident` carrying
    // the keyword's own lexeme, the way `true` and `false` already do: no new
    // `Pattern` variant, so no consumer has to learn one, and `null` is a
    // keyword token, so no binding can ever carry this name and be confused
    // with it. `isNullPattern` (`comptime/infer.zig`) is the one reader.
    if (this.check(.null)) {
        _ = this.advance();
        return Pattern{ .ident = "null" };
    }

    // `#(a, b)` ---- tuple pattern (decision 8 §5.1 P6), positional only.
    if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
        _ = this.advance(); // `#`
        return parsePatternPayload(this, alloc, "", .tuple);
    }

    // Number literal: `42`, or the inclusive range `1...9` (§5.2)
    if (this.check(.numberLiteral)) {
        try this.checkNumberLiteral(this.peek());
        const lowTok = this.advance();
        return finishRangePattern(this, alloc, Pattern{ .numberLit = lowTok.lexeme });
    }

    // String literal: `"hello"` or `"""..."""`
    if (this.check(.stringLiteral)) {
        const tok = this.advance();
        return finishRangePattern(this, alloc, Pattern{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] });
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

    // `.Some(v)` / `.None` ---- the dot-shorthand variant (§5.1 P8). The enum
    // comes from the matched value's type, so only the variant is written; the
    // leading `.` stays in the name, which is what tells a variant path from a
    // binding.
    if (this.check(.dot) and this.peekAt(1).kind == .identifier) {
        const dotTok = this.advance();
        const nameTok = this.advance();
        return parsePatternTail(this, alloc, spanLexemes(dotTok, nameTok));
    }

    // identifier: variant name, dotted variant path (`Shape.Circle`) or binding
    if (this.check(.identifier)) {
        const first = this.advance();
        var last = first;
        while (this.check(.dot) and this.peekAt(1).kind == .identifier) {
            _ = this.advance(); // `.`
            last = this.advance();
        }
        return parsePatternTail(this, alloc, spanLexemes(first, last));
    }

    return ParseError.UnexpectedToken;
}

/// What follows a pattern's name: a payload, a whole-payload binding, or
/// nothing.
fn parsePatternTail(this: *This, alloc: std.mem.Allocator, name: []const u8) ParseError!Pattern {
    // Variant with a payload: `Rgb(r, g, b)`, `Rect(width: w, ..)`, `Ok(1)`,
    // `Some(#(a, b))`.
    if (this.check(.leftParenthesis)) {
        return parsePatternPayload(this, alloc, name, .variant);
    }

    // `Variant binding` pattern: `Ok ok` — two identifiers, bind whole payload.
    // `when (` after a pattern is decision 8's arm guard (§5.3), never a name.
    if (this.check(.identifier) and !checkWhenGuard(this)) {
        const binding = this.advance().lexeme;
        return Pattern{ .variant = .{
            .name = name,
            .payload = .{ .binding = binding },
        } };
    }

    return Pattern{ .ident = name };
}

/// `A...B` when a `...` follows the literal just parsed; `low` unchanged
/// otherwise. `A..B` is refused — `..` is iteration and slicing (§5.2).
fn finishRangePattern(this: *This, alloc: std.mem.Allocator, low: Pattern) ParseError!Pattern {
    if (this.check(.dotDot)) {
        this.parseError = ParseErrorInfo.fromToken(.patternRangeExclusive, this.peek());
        return ParseError.UnexpectedToken;
    }
    if (!this.check(.dotDotDot)) return low;
    const rangeTok = this.advance();
    if (!this.check(.numberLiteral) and !this.check(.stringLiteral)) {
        this.parseError = ParseErrorInfo.fromToken(.patternRangeMissingEnd, rangeTok);
        return ParseError.UnexpectedToken;
    }
    if (this.check(.numberLiteral)) try this.checkNumberLiteral(this.peek());
    const highTok = this.advance();
    const high: Pattern = if (highTok.kind == .numberLiteral)
        .{ .numberLit = highTok.lexeme }
    else
        .{ .stringLit = highTok.lexeme[1 .. highTok.lexeme.len - 1] };

    var bounds = try alloc.alloc(Pattern, 2);
    bounds[0] = low;
    bounds[1] = high;
    return Pattern{ .variant = .{
        .name = "",
        .payload = .{ .literals = bounds },
        .shape = .range,
    } };
}

/// The parenthesised part of a variant or tuple pattern, `(` already the current
/// token. One grammar for both (decision 8 §5.1 P4, P6, P7):
///
///   payload := '(' ( element ( ',' element )* )? ( ',' '..' )? ')'
///   element := ( label ':' )? pattern
///
/// A payload of nothing but plain binders keeps the `fields` shape every
/// existing consumer knows; anything else — a literal, a nested pattern, a
/// wildcard — lands as `literals`, so `Some(#(a, b))` recurses. A label is
/// recorded beside its element and refused inside a tuple: a tuple pattern is
/// positional (P6).
fn parsePatternPayload(
    this: *This,
    alloc: std.mem.Allocator,
    name: []const u8,
    shape: ast.PatternShape,
) ParseError!Pattern {
    _ = try this.consume(.leftParenthesis);

    var pats: std.ArrayList(Pattern) = .empty;
    errdefer {
        for (pats.items) |*p| p.deinit(alloc);
        pats.deinit(alloc);
    }
    var labels: std.ArrayList([]const u8) = .empty;
    errdefer labels.deinit(alloc);
    var anyLabel = false;
    var allBinders = true;
    var rest = false;

    while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
        // `..` — ignore the rest (P7): last, and once.
        if (this.check(.dotDot)) {
            const restTok = this.advance();
            rest = true;
            if (!this.check(.rightParenthesis)) {
                this.parseError = ParseErrorInfo.fromToken(.patternRestNotLast, restTok);
                return ParseError.UnexpectedToken;
            }
            break;
        }

        var label: []const u8 = "";
        if (this.check(.identifier) and this.peekAt(1).kind == .colon) {
            const labelTok = this.peek();
            if (shape == .tuple) {
                this.parseError = ParseErrorInfo.fromTokenDetail(.patternTupleLabel, labelTok, labelTok.lexeme);
                return ParseError.UnexpectedToken;
            }
            label = this.advance().lexeme;
            _ = this.advance(); // `:`
            anyLabel = true;
        }

        const pat = try this.parseSimplePattern(alloc);
        if (!isPlainBinder(pat)) allBinders = false;
        try pats.append(alloc, pat);
        try labels.append(alloc, label);
        if (!this.match(.comma)) break;
    }
    _ = try this.consume(.rightParenthesis);

    const labelSlice: []const []const u8 = if (anyLabel) try labels.toOwnedSlice(alloc) else blk: {
        labels.deinit(alloc);
        break :blk &.{};
    };
    errdefer if (labelSlice.len > 0) alloc.free(labelSlice);

    // A variant whose payload is only binders keeps the `fields` shape.
    if (allBinders and shape == .variant) {
        var names = try alloc.alloc([]const u8, pats.items.len);
        for (pats.items, 0..) |p, i| names[i] = p.ident;
        pats.deinit(alloc);
        return Pattern{ .variant = .{
            .name = name,
            .payload = .{ .fields = names },
            .shape = shape,
            .labels = labelSlice,
            .rest = rest,
        } };
    }

    return Pattern{ .variant = .{
        .name = name,
        .payload = .{ .literals = try pats.toOwnedSlice(alloc) },
        .shape = shape,
        .labels = labelSlice,
        .rest = rest,
    } };
}

/// True for a payload element that is a plain binding name — an identifier
/// with no dot, which is a variable and not a variant path. `null`, `true`
/// and `false` ride on `.ident` too (`parseSimplePattern`) but are literals,
/// never binders: `Box(label: null, n: k)` lands as `literals`, so a backend
/// tests the field instead of binding a name `null` (which matched anything
/// on erlang, beam and wasm and was a `SyntaxError` on commonJS).
fn isPlainBinder(pat: Pattern) bool {
    return switch (pat) {
        .ident => |n| std.mem.indexOfScalar(u8, n, '.') == null and
            !std.mem.eql(u8, n, "null") and !std.mem.eql(u8, n, "true") and !std.mem.eql(u8, n, "false"),
        else => false,
    };
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
                try this.checkNumberLiteral(this.peek());
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

/// True when the next two tokens are decision 8's arm guard `when (…)` (§5.3).
/// `when` is special only after an arm's pattern: it is an ordinary identifier
/// everywhere else, so it is never a keyword token and is matched by lexeme.
fn checkWhenGuard(this: *This) bool {
    return this.check(.identifier) and
        std.mem.eql(u8, this.peek().lexeme, "when") and
        this.peekAt(1).kind == .leftParenthesis;
}

const ArmForm = enum { braced, arrow };

/// `rejectNonPatternArm` over an arm: a multi-subject arm is judged subject by
/// subject, each refusal located at its own pattern (decision 602).
fn rejectArm(this: *This, pat: Pattern, tok: Token, subjectToks: []const Token, afterNullArm: bool, form: ArmForm) ParseError!void {
    switch (pat) {
        .multi => |pats| for (pats, 0..) |p, i| try rejectNonPatternArm(this, p, if (i < subjectToks.len) subjectToks[i] else tok, afterNullArm, form),
        else => try rejectNonPatternArm(this, pat, tok, afterNullArm, form),
    }
}

/// Decision 8 §5.2 — what a name means in an arm (`Pattern { body }` or
/// `pattern -> value`). A name alone is a type (`i32`), a variant (`Red`, `.Some`, a dotted
/// path) or `true`/`false`; a lower-case name is a variable and a constant is a
/// value, and neither is a pattern — each gets the rewrite the spec names.
///
/// Both arm forms are judged, the braced `Pattern { body }` and the
/// `pattern -> value` one; a constant only in the braced form, where a bare
/// upper-case variant is never written.
fn rejectNonPatternArm(this: *This, pat: Pattern, tok: Token, afterNullArm: bool, form: ArmForm) ParseError!void {
    switch (pat) {
        .multi, .@"or" => |pats| {
            for (pats) |p| try rejectNonPatternArm(this, p, tok, afterNullArm, form);
        },
        .ident => |name| {
            if (name.len == 0) return;
            // `Maybe.None`, `.None` — a variant path, never a binding.
            if (std.mem.indexOfScalar(u8, name, '.') != null) return;
            if (std.mem.eql(u8, name, "true") or std.mem.eql(u8, name, "false")) return;
            // Decision 54 — `null` is the optional's pattern, and the arm after
            // a `null` arm is its binder: `case x { null { … } v { … } }` is the
            // one spelling a `?T` has. The binder is a pattern only there, and
            // only after the `null` arm: written first it would match the absent
            // value too, so the order is the form. Whether the subject really is
            // a `?T`, and whether the two arms are the only two, is the
            // checker's (`optionalNullCase` in `comptime/infer.zig`).
            if (std.mem.eql(u8, name, "null")) return;
            if (isPrimitiveTypeName(name)) return;
            // An upper-case name in a `pattern -> value` arm is a variant
            // written bare (`NFKC -> true`, std's `unicode`): the constant
            // rule is the braced form's alone.
            if (form == .braced and isConstantName(name)) {
                this.parseError = ParseErrorInfo.fromTokenDetail(.caseConstantPattern, tok, name);
                return ParseError.UnexpectedToken;
            }
            // The binder of decision 54's `?T` form — a lower-case name is a
            // pattern here and only here. A constant is still refused above.
            if (afterNullArm) return;
            if (std.ascii.isLower(name[0])) {
                this.parseError = ParseErrorInfo.fromTokenDetail(.caseBareNameArm, tok, name);
                return ParseError.UnexpectedToken;
            }
        },
        else => {},
    }
}

/// The primitive type names an arm may be written with. Mirrors
/// `Env.registerBuiltins` in `comptime/env.zig` minus `Self` (its own token) and
/// `unknown` (a keyword since 06 N19, and as an arm it would be `_`); the
/// language server's `isPrimitiveType` mirrors the same list. Only these
/// lower-case names are types rather than variables, so the list is what keeps
/// `i32 { n -> … }` an arm and `n { … }` an error.
pub fn isPrimitiveTypeName(name: []const u8) bool {
    const prims = [_][]const u8{
        "i8",       "u8",     "i16", "u16", "i32",  "u32",    "i64",  "u64",
        "isize",    "usize",  "f32", "f64", "bool", "string", "void", "v128",
        "noreturn", "bigint",
    };
    for (prims) |p| if (std.mem.eql(u8, name, p)) return true;
    return false;
}

/// True for a name written the way constants are — `MAX`, `MAX_SIZE`: at least
/// two characters, a letter somewhere, and no lower-case letter. A single
/// upper-case letter is a type parameter (`T`), not a constant.
fn isConstantName(name: []const u8) bool {
    if (name.len < 2) return false;
    var sawLetter = false;
    for (name) |c| {
        if (std.ascii.isLower(c)) return false;
        if (std.ascii.isUpper(c)) sawLetter = true;
    }
    return sawLetter;
}
