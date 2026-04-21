const std = @import("std");
const token = @import("./lexer/token.zig");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

pub const UseDecl = ast.UseDecl;
pub const Source = ast.Source;
pub const InterfaceDecl = ast.InterfaceDecl;
pub const InterfaceField = ast.InterfaceField;
pub const InterfaceMethod = ast.InterfaceMethod;
pub const StructDecl = ast.StructDecl;
pub const StructMember = ast.StructMember;
pub const StructField = ast.StructField;
pub const StructGetter = ast.StructGetter;
pub const StructSetter = ast.StructSetter;
pub const Param = ast.Param;
pub const Stmt = ast.Stmt;
pub const Expr = ast.Expr;
pub const CollectionExpr = ast.CollectionExpr;
pub const ControlFlowExpr = ast.ControlFlowExpr;
pub const FunctionExpr = ast.FunctionExpr;
pub const Loc = ast.Loc;
pub const RecordDecl = ast.RecordDecl;
pub const RecordField = ast.RecordField;
pub const ImplementDecl = ast.ImplementDecl;
pub const ImplementMethod = ast.ImplementMethod;
pub const DeclKind = ast.DeclKind;
pub const Program = ast.Program;
pub const GenericParam = ast.GenericParam;
pub const ParamModifier = ast.ParamModifier;
pub const CallArg = ast.CallArg;
pub const TrailingLambda = ast.TrailingLambda;
pub const EnumDecl = ast.EnumDecl;
pub const EnumVariant = ast.EnumVariant;
pub const EnumVariantField = ast.EnumVariantField;
pub const FnDecl = ast.FnDecl;
pub const ValDecl = ast.ValDecl;
pub const DelegateDecl = ast.DelegateDecl;
pub const Annotation = ast.Annotation;
pub const FnType = ast.FnType;
pub const FnTypeParam = ast.FnTypeParam;
pub const ParamDestruct = ast.ParamDestruct;
pub const Pattern = ast.Pattern;
pub const ListPatternElem = ast.ListPatternElem;
pub const CaseArm = ast.CaseArm;
pub const TypeRef = ast.TypeRef;

// ── Parser error types ────────────────────────────────────────────────────────

pub const ParseErrorType = enum {
    /// Generic unexpected token
    unexpectedToken,
    /// Reserved word used as an identifier (e.g. auto = 1)
    reservedWord,
    /// Assignment without 'val'/'var' (e.g. x = 4 instead of val x = 4)
    novalBinding,
    /// Binary operator with no value on its right-hand side (e.g. 1 + val a = 5)
    opNakedRight,
    /// List spread without a tail (e.g. [1, 2, ..])
    listSpreadWithoutTail,
    /// Elements after a spread in a list (e.g. [..xs, 1, 2])
    listSpreadNotLast,
    /// Useless spread with no elements to its left (e.g. [..wibble])
    uselessSpread,
};

pub const ParseErrorInfo = struct {
    kind: ParseErrorType,
    /// Byte offset of the start of the problematic token in the original source
    start: usize,
    /// Byte offset of the end (exclusive)
    end: usize,
    /// Lexeme of the problematic token
    lexeme: []const u8,
    /// Line number (1-based) ---- used when source is not available
    line: usize = 1,
    /// Column (1-based) ---- used when source is not available
    col: usize = 1,
    /// Extra context (e.g. the reserved word name)
    detail: ?[]const u8 = null,
};

pub const ParseError = error{ UnexpectedToken, OutOfMemory };

// ── Parser ────────────────────────────────────────────────────────────────────

pub const Parser = struct {
    tokens: []const Token,
    current: usize,
    /// Populated when parse() returns ParseError.unexpectedToken
    parseError: ?ParseErrorInfo,
    /// Original source text (for span calculation, when available)
    source: ?[]const u8,
    /// When true, `parsePrimary` will not consume trailing `{ }` lambda blocks.
    noTrailingLambda: bool = false,
    /// When true, `parsePipelineExpr` will not consume a trailing `catch` operator.
    noTailCatch: bool = false,
    /// Auto-incrementing counters for unique IDs per declaration type.
    id_counters: struct {
        interface: u32 = 0,
        @"struct": u32 = 0,
        record: u32 = 0,
        @"enum": u32 = 0,
    } = .{},
    const This = @This();

    pub fn init(tokens: []const Token) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parseError = null,
            .source = null,
        };
    }

    /// Returns the next ID counter for a declaration type.
    /// The caller stores this as a u32; formatting happens in the formatter.
    fn nextId(this: *This, comptime kind: []const u8) u32 {
        const counter = &@field(this.id_counters, kind);
        counter.* += 1;
        return counter.*;
    }

    /// Consumes an optional `@type_NNNN` ID token after the declaration name.
    /// Always returns 0 when absent (IDs are parser-generated on first parse).
    fn tryParseId(this: *This) u32 {
        if (this.check(.at)) {
            _ = this.advance(); // skip @
            if (this.check(.identifier)) {
                _ = this.advance(); // skip type_NNNN token
            }
        }
        return 0;
    }

    /// Creates a Loc from a Token's line and column.
    fn locFromToken(tok: Token) Loc {
        return .{
            .line = tok.line,
            .col = tok.col,
        };
    }

    /// Initializes with the original source for richer error messages.
    pub fn initWithSource(tokens: []const Token, source: []const u8) Parser {
        return .{
            .tokens = tokens,
            .current = 0,
            .parseError = null,
            .source = source,
        };
    }

    pub fn deinit(this: *This) void {
        _ = this;
    }

    pub fn parse(this: *This, alloc: std.mem.Allocator) ParseError!Program {
        var decls: std.ArrayList(DeclKind) = .empty;
        errdefer {
            for (decls.items) |*d| d.deinit(alloc);
            decls.deinit(alloc);
        }
        while (!this.check(.endOfFile)) {
            const decl: DeclKind = if (this.check(.use)) blk: {
                const d = try this.parseUseDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.checkShorthand(.@"fn")) blk: {
                const d = try this.parseFnDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"fn" = d };
            } else if (this.checkShorthand(.@"enum")) blk: {
                const d = try this.parseShorthandEnumDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"enum" = d };
            } else if (this.checkShorthand(.@"struct")) blk: {
                const d = try this.parseShorthandStructDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"struct" = d };
            } else if (this.checkShorthand(.record)) blk: {
                const d = try this.parseShorthandRecordDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .record = d };
            } else if (this.checkShorthandDelegate()) blk: {
                const d = try this.parseShorthandDelegateDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .delegate = d };
            } else if (this.checkShorthand(.interface)) blk: {
                const d = try this.parseShorthandInterfaceDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .interface = d };
            } else if (this.check(.loop)) blk: {
                // top-level loop statement: parsed as a val named "_loop"
                const e = try this.parseLoopExpr(alloc);
                const ePtr = try this.boxExpr(alloc, .{ .controlFlow = e });
                _ = this.match(.semicolon);
                break :blk DeclKind{ .val = ast.ValDecl{ .name = "_loop", .value = ePtr } };
            } else if (this.checkShorthand(.val)) blk: {
                const decl = try this.parseValForm(alloc);
                // Optional semicolon after top-level val declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.hash)) blk: {
                // Annotations precede the declaration — peek past them to find the keyword.
                const annEnd = this.skipAnnotationsLookaheadFrom(0);
                const tok = this.peekAt(annEnd).kind;
                const isPub = tok == .@"pub";
                const eff = if (isPub) this.peekAt(annEnd + 1).kind else tok;
                const decl: DeclKind = switch (eff) {
                    .@"fn" => DeclKind{ .@"fn" = try this.parseFnDecl(alloc) },
                    .@"struct" => DeclKind{ .@"struct" = try this.parseShorthandStructDecl(alloc) },
                    .@"enum" => DeclKind{ .@"enum" = try this.parseShorthandEnumDecl(alloc) },
                    .record => DeclKind{ .record = try this.parseShorthandRecordDecl(alloc) },
                    .interface => DeclKind{ .interface = try this.parseShorthandInterfaceDecl(alloc) },
                    .declare => DeclKind{ .delegate = try this.parseShorthandDelegateDecl(alloc) },
                    else => return ParseError.UnexpectedToken,
                };
                // Optional semicolon after top-level declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) blk: {
                const tok = this.advance();
                break :blk DeclKind{ .comment = .{
                    .text = commentText(tok.lexeme),
                    .is_module = tok.kind == .commentModule,
                    .is_doc = tok.kind == .commentDoc,
                } };
            } else {
                if (isReservedWord(this.peek().kind)) {
                    this.reportReservedWordError();
                }
                return ParseError.UnexpectedToken;
            };
            try decls.append(alloc, decl);
        }
        return Program{ .decls = try decls.toOwnedSlice(alloc) };
    }

    /// Dispatches `val [pub] Name = <kind> ...` to the appropriate sub-parser.
    /// Uses pure lookahead ---- no state mutation.
    fn parseValForm(this: *This, alloc: std.mem.Allocator) ParseError!DeclKind {
        // Check if we have `val Name : Type = Value` (type annotation) or `val Name = Value`
        var offset: usize = 0;
        if (this.peekAt(offset).kind == .@"pub") offset += 1; // optional pub
        offset += 1; // val
        offset += 1; // Name

        // Check for type annotation (`:`) vs direct assignment (`=`)
        const nextToken = this.peekAt(offset).kind;

        // If we have `:` followed by `fn`, this is a typed variable with function type
        // Use parseValDecl which handles type annotations properly
        if (nextToken == .colon and this.peekAt(offset + 1).kind == .@"fn") {
            return .{ .val = try this.parseValDecl(alloc) };
        }

        // Otherwise use the original logic for shorthand forms
        const baseOffset = this.valBodyOffset();
        const adjustedOffset = this.skipAnnotationsLookaheadFrom(baseOffset);
        const body = this.peekAt(adjustedOffset).kind;
        const bodyNext = this.peekAt(adjustedOffset + 1).kind;
        return switch (body) {
            .@"struct" => .{ .@"struct" = try this.parseStructDecl(alloc) },
            .record => .{ .record = try this.parseRecordDecl(alloc) },
            .implement => .{ .implement = try this.parseImplementDecl(alloc) },
            .@"enum" => .{ .@"enum" = try this.parseEnumDecl(alloc) },
            .declare => .{ .delegate = try this.parseDelegateDecl(alloc) },
            .interface => if (bodyNext == .@"fn")
                .{ .delegate = try this.parseDelegateDecl(alloc) }
            else
                .{ .interface = try this.parseInterfaceDecl(alloc) },
            .@"fn" => .{ .@"fn" = try this.parseFnDeclFromVal(alloc) },
            else => .{ .val = try this.parseValDecl(alloc) },
        };
    }

    /// true if the current token is `kind`, or `pub` followed by `kind`.
    inline fn checkShorthand(this: *This, kind: TokenKind) bool {
        return this.check(kind) or (this.check(.@"pub") and this.peekAt(1).kind == kind);
    }

    /// true if a shorthand delegate (`declare fn` or `pub declare fn`) is next.
    inline fn checkShorthandDelegate(this: *This) bool {
        if (this.check(.declare)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .declare and this.peekAt(2).kind == .@"fn";
        return false;
    }

    /// Returns the lookahead offset of the token that follows `[pub] val Name =`.
    /// Does not consume any tokens.
    inline fn valBodyOffset(this: *This) usize {
        var offset: usize = 0;
        if (this.peekAt(offset).kind == .@"pub") offset += 1; // optional pub
        offset += 1; // val
        offset += 1; // Name
        offset += 1; // =
        return offset;
    }

    // ── block parsing ──────────────────────────────────────────────────────

    /// Parse `{ expr; expr; ... }` — a brace-delimited block of semicolon-separated expressions.
    /// The opening `{` must already be the current token.
    fn parseStmtListInBraces(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            // Compute empty lines before this item using token line numbers
            const prevLine = if (this.current > 0) this.tokens[this.current - 1].line else 1;
            const currLine = this.peek().line;
            const emptyLinesBefore: u32 = if (currLine > prevLine + 1) @intCast(currLine - prevLine - 1) else 0;

            if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) {
                const tok = this.advance();
                const kind: ast.CommentKind = if (tok.kind == .commentDoc)
                    .{ .doc = "" }
                else if (tok.kind == .commentModule)
                    .{ .module = "" }
                else
                    .{ .normal = "" };
                const text = try alloc.dupe(u8, commentText(tok.lexeme));
                try stmts.append(alloc, .{ .expr = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .comment = .{ .kind = kind, .text = text } } } }, .emptyLinesBefore = emptyLinesBefore });
                continue;
            }

            const expr = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = expr, .emptyLinesBefore = emptyLinesBefore });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    /// Parse either `{ expr; ... }` or a single `expr`.
    /// Used by `if`, `catch`, and any place that accepts a block or bare expression.
    /// Does NOT require semicolon after the bare expression.
    fn parseBlockOrExpr(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        if (this.check(.leftBrace)) {
            return this.parseStmtListInBraces(alloc);
        }
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        const expr = try this.parseExpr(alloc);
        try stmts.append(alloc, .{ .expr = expr });
        return stmts.toOwnedSlice(alloc);
    }

    /// Parse a block where the last expression doesn't require a semicolon.
    /// Used for catch handlers where `{ throw Error(...) }` is valid.
    fn parseBlockWithOptionalTrailingSemicolon(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(alloc);
            // Try to consume semicolon, but don't fail if it's the last expression
            _ = this.match(.semicolon);
            try stmts.append(alloc, .{ .expr = expr, .emptyLinesBefore = 0 });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    // ── shared body / param helpers ───────────────────────────────────────────

    /// Parses `{ stmt; ... }` preserving comment nodes as literal expressions.
    /// Used in fn/method bodies where source comments must be kept.
    fn parseMethodBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) {
                const tok = this.advance();
                const kind: ast.CommentKind = if (tok.kind == .commentDoc)
                    .{ .doc = "" }
                else if (tok.kind == .commentModule)
                    .{ .module = "" }
                else
                    .{ .normal = "" };
                const text = try alloc.dupe(u8, commentText(tok.lexeme));
                try stmts.append(alloc, .{ .expr = Expr{ .literal = .{
                    .loc = locFromToken(tok),
                    .kind = .{ .comment = .{ .kind = kind, .text = text } },
                } } });
                continue;
            }
            const expr = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    /// Parses `{ stmt; ... }` without special comment handling.
    /// Used in implement methods, getters, setters, and interface default bodies.
    fn parseSimpleBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    /// Parses `param, param, ...` up to and including `)`.
    /// The caller must have already consumed the opening `(`.
    fn parseParamList(this: *This, alloc: std.mem.Allocator) ParseError![]Param {
        var params: std.ArrayList(Param) = .empty;
        errdefer {
            for (params.items) |*p| p.deinit(alloc);
            params.deinit(alloc);
        }
        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(alloc);
            try params.append(alloc, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);
        return params.toOwnedSlice(alloc);
    }

    /// Skips zero or more `#[name(args...)]` sequences from `offset` and returns
    /// the position of the first non-annotation token.  Pure lookahead.
    fn skipAnnotationsLookaheadFrom(this: *This, offset: usize) usize {
        var o = offset;
        while (this.peekAt(o).kind == .hash and this.peekAt(o + 1).kind == .leftSquareBracket) {
            o += 2; // skip `#` and `[`
            o += 1; // skip annotation name
            if (this.peekAt(o).kind == .leftParenthesis) {
                o += 1; // skip `(`
                var depth: usize = 1;
                while (depth > 0 and this.peekAt(o).kind != .endOfFile) {
                    switch (this.peekAt(o).kind) {
                        .leftParenthesis => depth += 1,
                        .rightParenthesis => depth -= 1,
                        else => {},
                    }
                    o += 1;
                }
            }
            o += 1; // skip `]`
        }
        return o;
    }

    /// Parses zero or more `#[name(arg, arg)]` annotations at the current position.
    /// Returns an owned slice (empty when no annotations are present).
    fn parseAnnotations(this: *This, alloc: std.mem.Allocator) ParseError![]Annotation {
        var list: std.ArrayList(Annotation) = .empty;
        errdefer {
            for (list.items) |*ann| ann.deinit(alloc);
            list.deinit(alloc);
        }
        while (this.check(.hash) and this.peekAt(1).kind == .leftSquareBracket) {
            _ = try this.consume(.hash);
            _ = try this.consume(.leftSquareBracket);
            // Accept any word (identifier or reserved word) as the annotation name.
            const nameTok = this.peek();
            if (nameTok.kind != .identifier and !isReservedWord(nameTok.kind)) return ParseError.UnexpectedToken;
            const name = this.advance().lexeme;
            var args: std.ArrayList([]const u8) = .empty;
            errdefer args.deinit(alloc);
            if (this.match(.leftParenthesis)) {
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    if (this.check(.dot) and this.peekAt(1).kind == .identifier) {
                        // `.erlang` — adjacent source bytes form a single lexeme
                        const dot = try this.consume(.dot);
                        const ident = try this.consume(.identifier);
                        try args.append(alloc, dot.lexeme.ptr[0 .. dot.lexeme.len + ident.lexeme.len]);
                    } else {
                        const tok = this.advance();
                        try args.append(alloc, tok.lexeme);
                    }
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
            }
            _ = try this.consume(.rightSquareBracket);
            try list.append(alloc, Annotation{
                .name = name,
                .args = try args.toOwnedSlice(alloc),
            });
        }
        return list.toOwnedSlice(alloc);
    }

    // ── expression helper ─────────────────────────────────────────────────────

    /// Creates a heap-allocated copy of an expression.
    fn boxExpr(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!*Expr {
        _ = this;
        const ptr = try alloc.create(Expr);
        ptr.* = expr;
        return ptr;
    }

    /// If `noTailCatch` is false and the next token is `catch`, wraps `expr` in a tryCatch node.
    /// Otherwise returns `expr` unchanged. Used to apply `catch` as a tail operator.
    fn wrapCatch(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!Expr {
        if (!this.noTailCatch and this.match(.@"catch")) {
            const catchTok = this.tokens[this.current - 1];
            const handler = try this.parseExpr(alloc);
            const exprPtr = try this.boxExpr(alloc, expr);
            const handlerPtr = try this.boxExpr(alloc, handler);
            return Expr{ .controlFlow = .{ .loc = locFromToken(catchTok), .kind = .{ .tryCatch = .{ .expr = exprPtr, .handler = handlerPtr } } } };
        }
        return expr;
    }

    /// Parses comma-separated identifiers (e.g., `extends T1, T2, T3` or `use { a, b, c }`).
    fn parseCommaSeparatedIdentifiers(this: *This, alloc: std.mem.Allocator, stopAt: ?TokenKind) ParseError![]const []const u8 {
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(alloc);
        if (!this.check(.identifier)) return list.toOwnedSlice(alloc);
        try list.append(alloc, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            if (this.check(.rightBrace) or this.check(.rightParenthesis)) break;
            if (stopAt != null and this.check(stopAt.?)) break;
            try list.append(alloc, (try this.consume(.identifier)).lexeme);
        }
        return list.toOwnedSlice(alloc);
    }

    /// Reports a reserved word error for the current token.
    fn reportReservedWordError(this: *This) void {
        const tok = this.peek();
        this.parseError = .{
            .kind = .reservedWord,
            .start = tok.col - 1,
            .end = tok.col - 1 + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
            .detail = tok.lexeme,
        };
    }

    // ── val decl ─────────────────────────────────────────────────────────────

    fn parseValDecl(this: *This, alloc: std.mem.Allocator) ParseError!ValDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);

        // Check for pattern assertion: val assert Pattern = expr handler
        // First check if we have 'assert' keyword followed by a valid pattern
        if (this.check(.assert)) {
            // Save position to backtrack if pattern assertion fails
            const savedPos = this.current;
            const assertTok = this.advance(); // consume 'assert'

            // Try to parse pattern
            if (this.parsePattern(alloc)) |pattern| {
                // Check if followed by '='
                if (this.match(.equal)) {
                    // Parse the expression to match against (noTailCatch to prevent consuming `catch`)
                    const savedNTC1 = this.noTailCatch;
                    this.noTailCatch = true;
                    const expr = try this.parseExpr(alloc);
                    this.noTailCatch = savedNTC1;
                    const exprPtr = try this.boxExpr(alloc, expr);

                    // Parse catch handler
                    if (this.match(.@"catch")) {
                        // catch expr (can be block, throw, return, or default value)
                        const catchExpr = try this.parseExpr(alloc);
                        const catchExprPtr = try this.boxExpr(alloc, catchExpr);

                        // Create the pattern assertion expression
                        const assertExpr = Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assertPattern = .{
                            .pattern = pattern,
                            .expr = exprPtr,
                            .handler = catchExprPtr,
                        } } } };

                        // Semicolon required after top-level val declaration
                        _ = try this.consume(.semicolon);

                        return ValDecl{
                            .name = "assert_pattern",
                            .isPub = isPub,
                            .typeAnnotation = null,
                            .value = try this.boxExpr(alloc, assertExpr),
                        };
                    } else {
                        // No handler provided - invalid for pattern assertions
                        exprPtr.deinit(alloc);
                        alloc.destroy(exprPtr);
                        {
                            var mutPattern = pattern;
                            mutPattern.deinit(alloc);
                        }
                        return ParseError.UnexpectedToken;
                    }
                } else {
                    // Not followed by '=', clean up and fall back to regular val
                    {
                        var mutPattern = pattern;
                        mutPattern.deinit(alloc);
                    }
                }
            } else |_| {
                // Pattern parsing failed, fall back to regular val
            }

            // Restore position and continue with regular val declaration
            this.current = savedPos;
        }

        // Regular val declaration
        if (!this.check(.identifier)) {
            const tok = this.peek();
            this.parseError = .{
                .kind = .unexpectedToken,
                .start = tok.col - 1,
                .end = tok.col - 1 + tok.lexeme.len,
                .lexeme = tok.lexeme,
                .line = tok.line,
                .col = tok.col,
            };
            return ParseError.UnexpectedToken;
        }
        const name = this.advance().lexeme;
        var typeAnnotation: ?ast.TypeRef = null;
        if (this.match(.colon)) {
            typeAnnotation = try this.parseTypeRef(alloc);
        }
        errdefer if (typeAnnotation) |*ann| ann.deinit(alloc);
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        var value = try this.parseExpr(alloc);
        errdefer value.deinit(alloc);
        const value_ptr = try this.boxExpr(alloc, value);
        // Semicolon required after top-level val declaration
        _ = try this.consume(.semicolon);
        return ValDecl{ .name = name, .isPub = isPub, .typeAnnotation = typeAnnotation, .value = value_ptr };
    }

    /// Parses a full type reference, including `E!T` error-union postfix.
    fn parseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
        var base = try this.parseBaseTypeRef(alloc);
        errdefer base.deinit(alloc);
        // E!T ---- error union: base is the error type, rhs is the payload
        if (this.match(.bang)) {
            var payload = try this.parseBaseTypeRef(alloc);
            errdefer payload.deinit(alloc);
            const errPtr = try alloc.create(ast.TypeRef);
            errPtr.* = base;
            const payPtr = try alloc.create(ast.TypeRef);
            payPtr.* = payload;
            return ast.TypeRef{ .errorUnion = .{ .errorType = errPtr, .payload = payPtr } };
        }
        return base;
    }

    /// Parses a base type ref: `?T`, `#(T1,T2)`, plain name with optional `[]` wraps.
    fn parseBaseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
        // ?T ---- optional type
        if (this.match(.questionMark)) {
            var inner = try this.parseBaseTypeRef(alloc);
            errdefer inner.deinit(alloc);
            const innerPtr = try alloc.create(ast.TypeRef);
            innerPtr.* = inner;
            return ast.TypeRef{ .optional = innerPtr };
        }
        // #(T1, T2, ...) ---- tuple type
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            _ = this.advance(); // consume '#'
            _ = this.advance(); // consume '('
            var elems: std.ArrayList(ast.TypeRef) = .empty;
            errdefer {
                for (elems.items) |*e| e.deinit(alloc);
                elems.deinit(alloc);
            }
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try elems.append(alloc, try this.parseTypeRef(alloc));
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            return ast.TypeRef{ .tuple_ = try elems.toOwnedSlice(alloc) };
        }
        // fn(T1, T2) -> R ---- function type
        if (this.check(.@"fn") and this.peekAt(1).kind == .leftParenthesis) {
            _ = try this.consume(.@"fn"); // consume 'fn'
            _ = try this.consume(.leftParenthesis); // consume '('

            var params: std.ArrayList(ast.TypeRef) = .empty;
            errdefer {
                for (params.items) |*p| p.deinit(alloc);
                params.deinit(alloc);
            }

            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try params.append(alloc, try this.parseTypeRef(alloc));
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis); // consume ')'

            // Parse optional return type -> R (defaults to void if omitted)
            var returnType: ast.TypeRef = undefined;
            if (this.match(.rightArrow)) {
                returnType = try this.parseTypeRef(alloc);
            } else {
                // Default to void return type
                returnType = ast.TypeRef{ .named = "void" };
            }

            const paramsSlice = try params.toOwnedSlice(alloc);
            const returnPtr = try alloc.create(ast.TypeRef);
            returnPtr.* = returnType;

            return ast.TypeRef{ .function = .{
                .params = paramsSlice,
                .returnType = returnPtr,
            } };
        }
        // Plain named type, possibly followed by [] for array
        const nameTok = try this.consumeTypeName();
        var ref = ast.TypeRef{ .named = nameTok.lexeme };
        // T[] — zero or more array wraps
        while (this.check(.leftSquareBracket) and this.peekAt(1).kind == .rightSquareBracket) {
            _ = this.advance(); // [
            _ = this.advance(); // ]
            const elem = try alloc.create(ast.TypeRef);
            elem.* = ref;
            ref = ast.TypeRef{ .array = elem };
        }
        return ref;
    }

    // ── use decl ─────────────────────────────────────────────────────────────

    fn parseUseDecl(this: *This, alloc: std.mem.Allocator) ParseError!UseDecl {
        _ = try this.consume(.use);
        _ = try this.consume(.leftBrace);
        const imports = try this.parseImportList(alloc);
        errdefer alloc.free(imports);
        _ = try this.consume(.rightBrace);
        _ = try this.consume(.from);
        return UseDecl{ .imports = imports, .source = try this.parseSource() };
    }

    fn parseImportList(this: *This, alloc: std.mem.Allocator) ParseError![]const []const u8 {
        var names: std.ArrayList([]const u8) = .empty;
        errdefer names.deinit(alloc);
        if (!this.check(.identifier)) return names.toOwnedSlice(alloc);
        try names.append(alloc, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            if (this.check(.rightBrace)) break;
            try names.append(alloc, (try this.consume(.identifier)).lexeme);
        }
        return names.toOwnedSlice(alloc);
    }

    fn parseSource(this: *This) ParseError!Source {
        if (this.check(.stringLiteral)) {
            const tok = this.advance();
            return Source{ .stringPath = tok.lexeme[1 .. tok.lexeme.len - 1] };
        }
        if (this.check(.multilineStringLiteral)) {
            const tok = this.advance();
            // Remove the triple quotes from both ends
            return Source{ .stringPath = tok.lexeme[3 .. tok.lexeme.len - 3] };
        }
        if (this.check(.identifier)) {
            const tok = try this.consume(.identifier);
            _ = try this.consume(.leftParenthesis);
            _ = try this.consume(.rightParenthesis);
            return Source{ .functionCall = tok.lexeme };
        }
        return ParseError.UnexpectedToken;
    }

    // ── fn decl ───────────────────────────────────────────────────────────────────

    fn parseFnDecl(this: *This, alloc: std.mem.Allocator) ParseError!FnDecl {
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*ann| ann.deinit(alloc);
            alloc.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;
        return this.parseFnBody(alloc, name, isPub, annotations);
    }

    /// `val name = #[...] fn(params) -> R { body }` — val-form annotated function.
    fn parseFnDeclFromVal(this: *This, alloc: std.mem.Allocator) ParseError!FnDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*ann| ann.deinit(alloc);
            alloc.free(annotations);
        }
        _ = try this.consume(.@"fn");
        return this.parseFnBody(alloc, name, isPub, annotations);
    }

    fn parseFnBody(
        this: *This,
        alloc: std.mem.Allocator,
        name: []const u8,
        isPub: bool,
        annotations: []Annotation,
    ) ParseError!FnDecl {
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(alloc);
        }
        errdefer if (returnType) |*rt| rt.deinit(alloc);

        const body = try this.parseStmtListInBraces(alloc);

        return FnDecl{
            .isPub = isPub,
            .name = name,
            .annotations = annotations,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .body = body,
        };
    }

    // ── delegate decl ────────────────────────────────────────────────────────────

    /// `val log = declare fn(self: Self) -> R`
    fn parseDelegateDecl(this: *This, alloc: std.mem.Allocator) ParseError!DelegateDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.equal);
        _ = try this.consume(.declare);
        _ = try this.consume(.@"fn");
        return this.parseDelegateParams(alloc, name, isPub);
    }

    /// `[pub] declare fn log(self: Self) -> R`
    fn parseShorthandDelegateDecl(this: *This, alloc: std.mem.Allocator) ParseError!DelegateDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.declare);
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;
        return this.parseDelegateParams(alloc, name, isPub);
    }

    fn parseDelegateParams(this: *This, alloc: std.mem.Allocator, name: []const u8, isPub: bool) ParseError!DelegateDecl {
        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }
        var returnType: ?[]const u8 = null;
        if (this.match(.rightArrow)) {
            returnType = (try this.consumeTypeName()).lexeme;
        }
        // Semicolon required after delegate declaration
        _ = try this.consume(.semicolon);
        return DelegateDecl{
            .name = name,
            .isPub = isPub,
            .params = params,
            .returnType = returnType,
        };
    }

    // ── interface decl ───────────────────────────────────────────────────────────

    fn parseInterfaceDecl(this: *This, alloc: std.mem.Allocator) ParseError!InterfaceDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        _ = try this.consume(.interface);
        // optional: `extends T1, T2, T3` after `interface`
        const extendsSlice = try this.parseExtendsClause(alloc);
        return this.parseInterfaceBody(alloc, name, extendsSlice, annotations, isPub);
    }

    fn parseShorthandInterfaceDecl(this: *This, alloc: std.mem.Allocator) ParseError!InterfaceDecl {
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.interface);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        // optional: `extends T1, T2, T3` after name
        const extendsSlice = try this.parseExtendsClause(alloc);
        return this.parseInterfaceBody(alloc, name, extendsSlice, annotations, isPub);
    }

    /// Parses an optional `extends T1, T2, T3` clause.
    /// Returns an owned slice (may be empty). The caller owns the memory.
    fn parseExtendsClause(this: *This, alloc: std.mem.Allocator) ParseError![]const []const u8 {
        if (!this.match(.extends)) return &.{};
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(alloc);
        try list.append(alloc, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            try list.append(alloc, (try this.consume(.identifier)).lexeme);
        }
        return list.toOwnedSlice(alloc);
    }

    fn parseInterfaceBody(this: *This, alloc: std.mem.Allocator, name: []const u8, extendsSlice: []const []const u8, annotations: []Annotation, isPub: bool) ParseError!InterfaceDecl {
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);
        _ = try this.consume(.leftBrace);

        var fields: std.ArrayList(InterfaceField) = .empty;
        errdefer fields.deinit(alloc);

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(alloc);
            methods.deinit(alloc);
        }

        var trailingComma = false;
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.val)) {
                _ = this.match(.@"pub");
                _ = try this.consume(.val);
                const fieldName = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                const typeName = (try this.consume(.identifier)).lexeme;
                trailingComma = this.match(.comma);
                try fields.append(alloc, .{ .name = fieldName, .typeName = typeName });
            } else if (this.check(.default) or this.check(.@"fn")) {
                const is_default = this.match(.default);
                const method = try this.parseInterfaceMethod(alloc, is_default);
                trailingComma = this.match(.comma);
                try methods.append(alloc, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }

        _ = try this.consume(.rightBrace);

        return InterfaceDecl{
            .name = name,
            .id = this.nextId("interface"),
            .isPub = isPub,
            .annotations = annotations,
            .genericParams = genericParams,
            .extends = extendsSlice,
            .fields = try fields.toOwnedSlice(alloc),
            .trailingComma = trailingComma,
            .methods = try methods.toOwnedSlice(alloc),
        };
    }

    fn parseInterfaceMethod(this: *This, alloc: std.mem.Allocator, is_default: bool) ParseError!InterfaceMethod {
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;

        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(alloc);
        }
        errdefer if (returnType) |*rt| rt.deinit(alloc);

        if (!is_default) {
            _ = this.match(.semicolon);
            return InterfaceMethod{
                .name = name,
                .genericParams = genericParams,
                .params = params,
                .returnType = returnType,
                .body = null,
                .is_default = false,
            };
        }

        const body = try this.parseSimpleBodyStmts(alloc);
        return InterfaceMethod{
            .name = name,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .body = body,
            .is_default = true,
        };
    }

    /// Parse a method inside a struct, record, or enum body.
    /// `is_declare fn ` → abstract slot (no body, `is_declare = true`).
    /// Plain `fn` → always requires a body.
    fn parseMethodDecl(this: *This, alloc: std.mem.Allocator, is_declare: bool, isPub: bool) ParseError!InterfaceMethod {
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;

        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(alloc);
        }
        errdefer if (returnType) |*rt| rt.deinit(alloc);

        if (is_declare) {
            _ = try this.consume(.semicolon);
            return InterfaceMethod{
                .name = name,
                .genericParams = genericParams,
                .params = params,
                .returnType = returnType,
                .body = null,
                .is_default = false,
                .is_declare = true,
                .isPub = isPub,
            };
        }

        const body = try this.parseMethodBodyStmts(alloc);
        return InterfaceMethod{
            .name = name,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .body = body,
            .is_default = false,
            .is_declare = false,
            .isPub = isPub,
        };
    }

    // ── struct decl ───────────────────────────────────────────────────────────

    fn parseStructDecl(this: *This, alloc: std.mem.Allocator) ParseError!StructDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        _ = try this.consume(.@"struct");
        return this.parseStructBody(alloc, name, annotations, isPub);
    }

    fn parseShorthandStructDecl(this: *This, alloc: std.mem.Allocator) ParseError!StructDecl {
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"struct");
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseStructBody(alloc, name, annotations, isPub);
    }

    fn parseStructBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!StructDecl {
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);
        _ = try this.consume(.leftBrace);

        var members: std.ArrayList(StructMember) = .empty;
        errdefer {
            for (members.items) |*m| m.deinit(alloc);
            members.deinit(alloc);
        }

        var trailingComma = false;
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            // Field: [val] name: Type = expr [,]
            // `val` keyword is optional/implicit
            if (this.check(.val)) _ = this.advance();

            if (this.check(.identifier)) {
                // Pode ser field ou fn/get/set
                const nextIdx = this.current + 1;
                const nextNext = if (nextIdx < this.tokens.len) this.tokens[nextIdx] else null;

                // If identifier is followed by '(' it is fn/get/set, not a field
                if (nextNext != null and nextNext.?.kind == .leftParenthesis) {
                    // Not a field — fall through to the normal member loop
                } else {
                    // Field: name: Type [= expr]
                    const fieldName = (try this.consume(.identifier)).lexeme;
                    _ = try this.consume(.colon);
                    const typeName = (try this.consumeTypeName()).lexeme;
                    var initExpr: ?Expr = null;
                    if (this.match(.equal)) {
                        initExpr = try this.parseExpr(alloc);
                    }
                    trailingComma = this.match(.comma);
                    try members.append(alloc, .{ .field = .{
                        .name = fieldName,
                        .typeName = typeName,
                        .init = initExpr,
                    } });
                    continue;
                }
            }

            if (this.check(.get)) {
                const getter = try this.parseStructGetter(alloc);
                trailingComma = this.match(.comma);
                try members.append(alloc, .{ .getter = getter });
            } else if (this.check(.set)) {
                const setter = try this.parseStructSetter(alloc);
                trailingComma = this.match(.comma);
                try members.append(alloc, .{ .setter = setter });
            } else if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(alloc, is_iface, is_pub);
                trailingComma = this.match(.comma);
                try members.append(alloc, .{ .method = method });
            } else {
                return ParseError.UnexpectedToken;
            }
        }

        _ = try this.consume(.rightBrace);

        return StructDecl{
            .name = name,
            .id = this.nextId("struct"),
            .isPub = isPub,
            .annotations = annotations,
            .genericParams = genericParams,
            .members = try members.toOwnedSlice(alloc),
            .trailingComma = trailingComma,
        };
    }

    fn parseStructGetter(this: *This, alloc: std.mem.Allocator) ParseError!StructGetter {
        _ = try this.consume(.get);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.leftParenthesis);
        const selfParamName = (try this.consumeParamName()).lexeme;
        _ = try this.consume(.colon);
        const selfParamType = (try this.consumeTypeName()).lexeme;
        _ = try this.consume(.rightParenthesis);
        _ = try this.consume(.rightArrow);
        const returnType = (try this.consumeTypeName()).lexeme;
        const body = try this.parseSimpleBodyStmts(alloc);
        return StructGetter{
            .name = name,
            .selfParam = .{ .name = selfParamName, .typeRef = .{ .named = selfParamType }, .typeName = selfParamType },
            .returnType = returnType,
            .body = body,
        };
    }

    fn parseStructSetter(this: *This, alloc: std.mem.Allocator) ParseError!StructSetter {
        _ = try this.consume(.set);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }
        const body = try this.parseSimpleBodyStmts(alloc);
        return StructSetter{
            .name = name,
            .params = params,
            .body = body,
        };
    }

    // ── record decl ──────────────────────────────────────────────────────────

    fn parseRecordDecl(this: *This, alloc: std.mem.Allocator) ParseError!RecordDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        _ = try this.consume(.record);
        return this.parseRecordBody(alloc, name, annotations, isPub);
    }

    fn parseShorthandRecordDecl(this: *This, alloc: std.mem.Allocator) ParseError!RecordDecl {
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.record);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseRecordBody(alloc, name, annotations, isPub);
    }

    fn parseRecordBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!RecordDecl {
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);
        _ = try this.consume(.leftBrace);

        var fields: std.ArrayList(RecordField) = .empty;
        errdefer {
            for (fields.items) |*f| f.deinit(alloc);
            fields.deinit(alloc);
        }

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(alloc);
            methods.deinit(alloc);
        }

        var trailingComma = false;
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            // Check if this is a method (fn/pub/declare)
            if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(alloc, is_iface, is_pub);
                trailingComma = false;
                try methods.append(alloc, method);
            } else if (this.check(.identifier)) {
                // Could be a field: [val] name: Type [= expr]
                const nextIdx = this.current + 1;
                const nextToken = if (nextIdx < this.tokens.len) this.tokens[nextIdx] else token.Token{ .kind = .endOfFile, .lexeme = "", .line = 0, .col = 0 };

                // If next token is '(', it's a method
                if (nextToken.kind == .leftParenthesis) {
                    return ParseError.UnexpectedToken;
                }

                // It's a field: [val] name: Type [= expr]
                if (this.check(.val)) _ = this.advance();
                const fieldName = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                var fieldType = try this.parseTypeRef(alloc);
                errdefer fieldType.deinit(alloc);
                var defaultExpr: ?Expr = null;
                if (this.match(.equal)) {
                    defaultExpr = try this.parseEqExpr(alloc);
                }
                trailingComma = this.match(.comma);
                try fields.append(alloc, .{ .name = fieldName, .typeRef = fieldType, .default = defaultExpr });
            } else {
                return ParseError.UnexpectedToken;
            }
        }
        _ = try this.consume(.rightBrace);

        return RecordDecl{
            .name = name,
            .id = this.nextId("record"),
            .isPub = isPub,
            .annotations = annotations,
            .genericParams = genericParams,
            .fields = try fields.toOwnedSlice(alloc),
            .trailingComma = trailingComma,
            .methods = try methods.toOwnedSlice(alloc),
        };
    }

    // ── implement decl ────────────────────────────────────────────────────────────

    fn parseImplementDecl(this: *This, alloc: std.mem.Allocator) ParseError!ImplementDecl {
        _ = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);
        _ = try this.consume(.equal);
        _ = try this.consume(.implement);

        var interfaces: std.ArrayList([]const u8) = .empty;
        errdefer interfaces.deinit(alloc);

        const firstInterface = (try this.consume(.identifier)).lexeme;
        try interfaces.append(alloc, firstInterface);
        while (this.match(.comma)) {
            if (this.check(.@"for")) break;
            try interfaces.append(alloc, (try this.consume(.identifier)).lexeme);
        }

        _ = try this.consume(.@"for");
        const target = (try this.consume(.identifier)).lexeme;

        _ = try this.consume(.leftBrace);
        var methods: std.ArrayList(ImplementMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(alloc);
            methods.deinit(alloc);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.@"fn")) {
                const method = try this.parseImplementMethod(alloc);
                try methods.append(alloc, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }
        _ = try this.consume(.rightBrace);

        return ImplementDecl{
            .name = name,
            .genericParams = genericParams,
            .interfaces = try interfaces.toOwnedSlice(alloc),
            .target = target,
            .methods = try methods.toOwnedSlice(alloc),
        };
    }

    fn parseImplementMethod(this: *This, alloc: std.mem.Allocator) ParseError!ImplementMethod {
        _ = try this.consume(.@"fn");

        const first = (try this.consume(.identifier)).lexeme;
        var qualifier: ?[]const u8 = null;
        var methodName: []const u8 = first;

        if (this.match(.dot)) {
            qualifier = first;
            methodName = (try this.consume(.identifier)).lexeme;
        }

        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        const params = try this.parseParamList(alloc);
        errdefer {
            for (params) |*p| p.deinit(alloc);
            alloc.free(params);
        }

        if (this.match(.rightArrow)) {
            var rt = try this.parseTypeRef(alloc);
            rt.deinit(alloc); // ImplementMethod has no returnType field
        }

        const body = try this.parseSimpleBodyStmts(alloc);
        return ImplementMethod{
            .qualifier = qualifier,
            .name = methodName,
            .params = params,
            .body = body,
        };
    }

    // ── enum decl ─────────────────────────────────────────────────────────────

    fn parseEnumDecl(this: *This, alloc: std.mem.Allocator) ParseError!EnumDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        _ = try this.consume(.@"enum");
        return this.parseEnumBody(alloc, name, annotations, isPub);
    }

    fn parseShorthandEnumDecl(this: *This, alloc: std.mem.Allocator) ParseError!EnumDecl {
        const annotations = try this.parseAnnotations(alloc);
        errdefer {
            for (annotations) |*a| a.deinit(alloc);
            alloc.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"enum");
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseEnumBody(alloc, name, annotations, isPub);
    }

    fn parseEnumBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!EnumDecl {
        const genericParams = try this.parseGenericParams(alloc);
        errdefer alloc.free(genericParams);
        _ = try this.consume(.leftBrace);

        var variants: std.ArrayList(EnumVariant) = .empty;
        errdefer {
            for (variants.items) |*v| v.deinit(alloc);
            variants.deinit(alloc);
        }

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(alloc);
            methods.deinit(alloc);
        }

        var trailingComma = false;
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.@"pub") or this.check(.@"fn") or this.check(.declare)) {
                trailingComma = false;
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(alloc, is_iface, is_pub);
                try methods.append(alloc, method);
                continue;
            }

            const variantName = (try this.consume(.identifier)).lexeme;

            if (this.check(.leftParenthesis)) {
                _ = this.advance(); // consume '('
                var fields: std.ArrayList(EnumVariantField) = .empty;
                errdefer {
                    for (fields.items) |*f| f.deinit(alloc);
                    fields.deinit(alloc);
                }

                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const fieldName = (try this.consume(.identifier)).lexeme;
                    _ = try this.consume(.colon);
                    var fieldType = try this.parseTypeRef(alloc);
                    errdefer fieldType.deinit(alloc);
                    try fields.append(alloc, .{ .name = fieldName, .typeRef = fieldType });
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);

                trailingComma = this.match(.comma);
                try variants.append(alloc, .{
                    .name = variantName,
                    .fields = try fields.toOwnedSlice(alloc),
                });
            } else {
                trailingComma = this.match(.comma);
                try variants.append(alloc, .{ .name = variantName, .fields = &.{} });
            }
        }

        _ = try this.consume(.rightBrace);

        return EnumDecl{
            .name = name,
            .id = this.nextId("enum"),
            .isPub = isPub,
            .annotations = annotations,
            .genericParams = genericParams,
            .variants = try variants.toOwnedSlice(alloc),
            .trailingComma = trailingComma,
            .methods = try methods.toOwnedSlice(alloc),
        };
    }

    // ── case / pattern matching ────────────────────────────────────────────────

    fn parseCaseExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
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
            const e = try this.parseEqExpr(alloc);
            _ = try this.consume(.rightParenthesis);
            try subjects.append(alloc, e);
        } else {
            // Multiple subjects separated by commas
            while (!this.check(.leftBrace) and !this.check(.endOfFile)) {
                try subjects.append(alloc, try this.parseEqExpr(alloc));
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
                break :blk Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{ .lambda = .{
                    .params = try emptyParams.toOwnedSlice(alloc),
                    .body = try blockStmts.toOwnedSlice(alloc),
                } } } };
            } else try this.parseExpr(alloc);
            // Accept both semicolon and comma as arm terminators
            if (!this.match(.semicolon)) {
                _ = this.match(.comma); // fallback to comma
            }
            try arms.append(alloc, .{ .pattern = pattern, .body = body, .emptyLinesBefore = emptyLinesBefore });
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
    fn parsePattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
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
    fn parseSimplePattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
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

                // Determine if this is variantFields (identifiers) or variantLiterals (literals or patterns)
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
                    // Parse as variantLiterals (can contain nested patterns)
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

                    return Pattern{ .variantLiterals = .{
                        .name = name,
                        .args = try args.toOwnedSlice(alloc),
                    } };
                } else {
                    // Parse as variantFields (existing logic)
                    var bindings: std.ArrayList([]const u8) = .empty;
                    errdefer bindings.deinit(alloc);

                    while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                        const bind = (try this.consume(.identifier)).lexeme;
                        try bindings.append(alloc, bind);
                        if (!this.match(.comma)) break;
                    }
                    _ = try this.consume(.rightParenthesis);

                    return Pattern{ .variantFields = .{
                        .name = name,
                        .bindings = try bindings.toOwnedSlice(alloc),
                    } };
                }
            }

            // `Variant binding` pattern: `Ok ok` — two identifiers, bind whole payload
            if (this.check(.identifier)) {
                const binding = this.advance().lexeme;
                return Pattern{ .variantBinding = .{
                    .name = name,
                    .binding = binding,
                } };
            }

            return Pattern{ .ident = name };
        }

        return ParseError.UnexpectedToken;
    }

    /// Parses a list pattern: `[]`, `[1]`, `[4, ..]`, `[_, _]`, `[first, ..rest]`
    fn parseListPattern(this: *This, alloc: std.mem.Allocator) ParseError!Pattern {
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

    // ── comment helpers ───────────────────────────────────────────────────────

    /// Strip the leading `//`, `///`, or `////` prefix (and optional space) from a comment lexeme.
    fn commentText(lexeme: []const u8) []const u8 {
        var start: usize = 0;
        while (start < lexeme.len and start < 4 and lexeme[start] == '/') start += 1;
        if (start < lexeme.len and lexeme[start] == ' ') start += 1;
        return lexeme[start..];
    }

    // ── param / type name helpers ─────────────────────────────────────────────

    fn consumeParamName(this: *This) ParseError!Token {
        if (this.check(.identifier)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses a plain type name token: `Self`, `type`, `null`, or any `identifier`.
    fn consumeTypeName(this: *This) ParseError!Token {
        if (this.check(.selfType)) return this.advance();
        if (this.check(.type)) return this.advance();
        if (this.check(.identifier)) return this.advance();
        // Allow `null` and other keywords that can be used as type names
        if (this.check(.null)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses an optional generic parameter list `<T, R, ...>`.
    /// Returns an empty slice if there is no `<` at the current position.
    fn parseGenericParams(this: *This, alloc: std.mem.Allocator) ParseError![]GenericParam {
        var list: std.ArrayList(GenericParam) = .empty;
        errdefer list.deinit(alloc);

        if (!this.match(.lessThan)) return list.toOwnedSlice(alloc);

        while (!this.check(.greaterThan) and !this.check(.endOfFile)) {
            const name = (try this.consume(.identifier)).lexeme;
            try list.append(alloc, .{ .name = name });
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.greaterThan);
        return list.toOwnedSlice(alloc);
    }

    /// Parses a single function/method parameter with optional modifier.
    ///
    /// Grammar:
    ///   param          ::= record_destruct
    ///                    | 'comptime' ':' typeinfo_body       (typeinfo param)
    ///                    | param_name ['comptime'] ':' value_param
    ///
    ///   record_destruct ::= '{' ident (',' ident)* '}' ':' type_name
    ///   typeinfo_body   ::= 'typeinfo' type_var (type_name ('|' type_name)*)?
    ///   value_param     ::= ['syntax'] 'fn' '(' fn_param* ')' ('->' type_name)?
    ///                     | ['syntax'] type_name
    ///
    /// The `comptime` keyword marks a compile-time param. It may appear:
    ///   - before the name:  `comptime name : type`  (stdlib / builtin style)
    ///   - after the name:   `name comptime : type`  (inline style)
    ///   - as typeinfo slot: `comptime : typeinfo TypeVar [constraints]`
    ///
    /// The post-colon `syntax` keyword overrides the modifier to `.syntax`.
    fn parseParam(this: *This, alloc: std.mem.Allocator) ParseError!Param {
        // ── record destructuring: { name, age }: Type or { name, .. }: Type or { c: the_c }: Type ──
        if (this.check(.leftBrace)) {
            _ = this.advance(); // consume '{'
            var fields: std.ArrayList(ast.FieldDestruct) = .empty;
            errdefer {
                for (fields.items) |f| {
                    alloc.free(f.field_name);
                    alloc.free(f.bind_name);
                }
                fields.deinit(alloc);
            }
            var hasSpread = false;
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                if (this.check(.dotDot)) {
                    _ = this.advance();
                    hasSpread = true;
                    break;
                }
                const field_name = try alloc.dupe(u8, (try this.consume(.identifier)).lexeme);
                const bind_name: []const u8 = if (this.match(.colon))
                    try alloc.dupe(u8, (try this.consume(.identifier)).lexeme)
                else
                    field_name;
                try fields.append(alloc, .{ .field_name = field_name, .bind_name = bind_name });
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightBrace);
            _ = try this.consume(.colon);
            const typeRef = try this.parseTypeRef(alloc);
            const fieldsSlice = try fields.toOwnedSlice(alloc);
            return Param{
                .name = "",
                .typeRef = typeRef,
                .typeName = if (typeRef == .named) typeRef.named else "",
                .destruct = .{ .names = .{ .fields = fieldsSlice, .hasSpread = hasSpread } },
            };
        }

        // ── tuple destructuring: #(a, b): Type ──
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            _ = this.advance(); // consume '#'
            _ = this.advance(); // consume '('
            var names: std.ArrayList([]const u8) = .empty;
            errdefer names.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try names.append(alloc, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            _ = try this.consume(.colon);
            const typeRef = try this.parseTypeRef(alloc);
            const namesSlice = try names.toOwnedSlice(alloc);
            return Param{
                .name = "",
                .typeRef = typeRef,
                .typeName = if (typeRef == .named) typeRef.named else "",
                .destruct = .{ .tuple_ = namesSlice },
            };
        }

        // ── comptime-prefixed forms ───────────────────────────────────────────
        // Peek one ahead to tell apart:
        //   `comptime :` → typeinfo slot   (`comptime: typeinfo TypeVar [constraints]`)
        //   `comptime id :` → pre-name modifier (`comptime name: type`)
        if (this.check(.@"comptime")) {
            if (this.peekAt(1).kind == .colon) {
                // Typeinfo param: `comptime : typeinfo TypeVar [constraints]`
                _ = this.advance(); // consume 'comptime'
                _ = try this.consume(.colon);
                _ = try this.consume(.typeinfo);
                const varName = (try this.consumeTypeName()).lexeme;
                if (this.check(.rightParenthesis) or this.check(.comma)) {
                    return Param{ .name = varName, .typeRef = .{ .named = "" }, .modifier = .typeinfo };
                }
                const firstType = try this.consumeTypeName();
                var constraints: std.ArrayList([]const u8) = .empty;
                errdefer constraints.deinit(alloc);
                try constraints.append(alloc, firstType.lexeme);
                while (this.match(.verticalBar)) {
                    try constraints.append(alloc, (try this.consumeTypeName()).lexeme);
                }
                return Param{
                    .name = varName,
                    .typeRef = .{ .named = firstType.lexeme },
                    .typeName = firstType.lexeme,
                    .modifier = .typeinfo,
                    .typeinfoConstraints = try constraints.toOwnedSlice(alloc),
                };
            } else {
                // Pre-name comptime: `comptime name : type`
                _ = this.advance(); // consume 'comptime'
                const name = (try this.consumeParamName()).lexeme;
                _ = try this.consume(.colon);
                const typeRef = try this.parseTypeRef(alloc);
                return Param{ .name = name, .typeRef = typeRef, .modifier = .@"comptime" };
            }
        }

        // ── regular param: name ['comptime'] ':' ['syntax'] type_expr ───────────
        const name = (try this.consumeParamName()).lexeme;
        // Optional post-name, pre-colon modifier.
        var modifier: ParamModifier = .none;
        if (this.match(.@"comptime")) modifier = .@"comptime";

        // Type annotation is required.
        _ = try this.consume(.colon);

        // Detect post-colon modifiers: `syntax` or `comptime`
        if (this.match(.syntax)) modifier = .syntax else if (this.match(.@"comptime")) modifier = .@"comptime";

        // ── fn-type params: `name: fn(...)` or `name comptime: syntax fn(...)` ─
        if (this.check(.@"fn")) {
            _ = this.advance(); // consume 'fn'
            _ = try this.consume(.leftParenthesis);
            var fnParams: std.ArrayList(FnTypeParam) = .empty;
            errdefer fnParams.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                const pname = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                const ptype = (try this.consumeTypeName()).lexeme;
                try fnParams.append(alloc, .{ .name = pname, .typeName = ptype });
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            const retType: ?[]const u8 = if (this.match(.rightArrow))
                (try this.consumeTypeName()).lexeme
            else
                null;
            // post-colon `syntax` marks the fn-type as a syntax param.
            const fnMod: ParamModifier = if (modifier == .syntax) .syntax else .none;
            return Param{
                .name = name,
                .typeRef = .{ .named = "fn" },
                .typeName = "fn",
                .modifier = fnMod,
                .fnType = .{
                    .params = try fnParams.toOwnedSlice(alloc),
                    .returnType = retType,
                },
            };
        }

        // ── plain type (use full TypeRef to support arrays, optionals, etc.) ─
        const typeRef = try this.parseTypeRef(alloc);
        return Param{ .name = name, .typeRef = typeRef, .modifier = modifier };
    }

    // ── expression parser ──────────────────────────────────────────────────────

    fn parseExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        // ── Detect: identifier = expr or identifier : Type = expr ────────────
        if (this.check(.identifier)) {
            const saved = this.current;
            const identTok = this.advance();
            if (this.check(.colon)) {
                // "x: Int = 4" without val/var ---- NovalBinding error
                this.parseError = .{
                    .kind = .novalBinding,
                    .start = identTok.col - 1,
                    .end = identTok.col - 1 + identTok.lexeme.len,
                    .lexeme = identTok.lexeme,
                    .line = identTok.line,
                    .col = identTok.col,
                    .detail = identTok.lexeme,
                };
                return ParseError.UnexpectedToken;
            }
            if (this.match(.equal)) {
                // "x = expr" ---- assignment to a previously declared `var`
                var valExpr = try this.parseExpr(alloc);
                errdefer valExpr.deinit(alloc);
                const valPtr = try this.boxExpr(alloc, valExpr);
                return Expr{ .binding = .{ .loc = locFromToken(identTok), .kind = .{ .assign = .{ .name = identTok.lexeme, .value = valPtr } } } };
            }
            this.current = saved;
        }

        // throw [new] expr
        if (this.check(.throw)) {
            const throwTok = this.advance();
            _ = this.match(.new); // skip optional `new` keyword
            const inner = try this.parseExpr(alloc);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .controlFlow = .{ .loc = locFromToken(throwTok), .kind = .{ .throw_ = innerPtr } } };
        }

        // try expr [catch handler]
        if (this.check(.@"try")) {
            const tryTok = this.advance();
            const savedNoTailCatch = this.noTailCatch;
            this.noTailCatch = true;
            const inner = try this.parseExpr(alloc);
            this.noTailCatch = savedNoTailCatch;
            const innerPtr = try this.boxExpr(alloc, inner);
            if (this.match(.@"catch")) {
                const handler = try this.parseExpr(alloc);
                const handlerPtr = try this.boxExpr(alloc, handler);
                return Expr{ .controlFlow = .{ .loc = locFromToken(tryTok), .kind = .{ .tryCatch = .{ .expr = innerPtr, .handler = handlerPtr } } } };
            }
            return Expr{ .controlFlow = .{ .loc = locFromToken(tryTok), .kind = .{ .try_ = innerPtr } } };
        }

        // if (cond) { [binding ->] stmt; } [else { stmt; }]
        // OR: if (cond) expr [else expr]
        if (this.check(.@"if")) {
            const ifTok = this.advance();

            _ = try this.consume(.leftParenthesis);
            const cond = try this.parseEqExpr(alloc);
            errdefer @constCast(&cond).deinit(alloc);
            _ = try this.consume(.rightParenthesis);
            const condPtr = try this.boxExpr(alloc, cond);

            var binding: ?[]const u8 = null;

            const then_ = if (this.check(.leftBrace)) blk: {
                _ = this.advance(); // consume `{`
                if (this.check(.identifier) and this.peekAt(1).kind == .rightArrow) {
                    binding = this.advance().lexeme;
                    _ = this.advance(); // consume `->`
                }
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (stmts.items) |*s| s.deinit(alloc);
                    stmts.deinit(alloc);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const expr = try this.parseExpr(alloc);
                    _ = try this.consume(.semicolon);
                    try stmts.append(alloc, .{ .expr = expr });
                }
                _ = try this.consume(.rightBrace);
                break :blk try stmts.toOwnedSlice(alloc);
            } else blk: {
                const expr = try this.parseExpr(alloc);
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer stmts.deinit(alloc);
                try stmts.append(alloc, .{ .expr = expr });
                break :blk try stmts.toOwnedSlice(alloc);
            };

            const else_ = if (this.match(.@"else")) blk: {
                break :blk if (this.check(.leftBrace))
                    try this.parseStmtListInBraces(alloc)
                else blk2: {
                    const expr = try this.parseExpr(alloc);
                    var stmts: std.ArrayList(Stmt) = .empty;
                    errdefer stmts.deinit(alloc);
                    try stmts.append(alloc, .{ .expr = expr });
                    break :blk2 try stmts.toOwnedSlice(alloc);
                };
            } else null;

            return Expr{ .controlFlow = .{ .loc = locFromToken(ifTok), .kind = .{ .if_ = .{
                .cond = condPtr,
                .binding = binding,
                .then_ = then_,
                .else_ = else_,
            } } } };
        }

        // return expr
        if (this.check(.@"return")) {
            const retTok = this.advance();
            const inner = try this.parseExpr(alloc);
            const innerPtr = try alloc.create(Expr);
            innerPtr.* = inner;
            return Expr{ .controlFlow = .{ .loc = locFromToken(retTok), .kind = .{ .@"return" = innerPtr } } };
        }

        // case expr { arm* }
        if (this.check(.case)) {
            return .{ .collection = try this.parseCaseExpr(alloc) };
        }

        // comptime expr  /  comptime { expr; ... }
        if (this.check(.@"comptime")) {
            const comptimeTok = this.advance();
            if (this.check(.leftBrace)) {
                const body = try this.parseStmtListInBraces(alloc);
                return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeBlock = .{ .body = body } } } };
            } else {
                var inner = try this.parseEqExpr(alloc);
                errdefer inner.deinit(alloc);
                const innerPtr = try alloc.create(Expr);
                innerPtr.* = inner;
                return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeExpr = innerPtr } } };
            }
        }

        // break [expr]
        if (this.check(.@"break")) {
            const breakTok = this.advance();
            // break with no expression (e.g. bare `break` inside a loop)
            const isEnd = this.check(.rightBrace) or this.check(.endOfFile) or this.check(.newLine) or this.check(.semicolon);
            if (isEnd) {
                return Expr{ .controlFlow = .{ .loc = locFromToken(breakTok), .kind = .{ .@"break" = null } } };
            }
            var inner = try this.parseExpr(alloc);
            errdefer inner.deinit(alloc);
            const innerPtr = try alloc.create(Expr);
            innerPtr.* = inner;
            return Expr{ .controlFlow = .{ .loc = locFromToken(breakTok), .kind = .{ .@"break" = innerPtr } } };
        }

        // yield expr
        if (this.check(.yield)) {
            const yieldTok = this.advance();
            var inner = try this.parseEqExpr(alloc);
            errdefer inner.deinit(alloc);
            const innerPtr = try alloc.create(Expr);
            innerPtr.* = inner;
            return Expr{ .controlFlow = .{ .loc = locFromToken(yieldTok), .kind = .{ .yield = innerPtr } } };
        }

        // continue
        if (this.check(.@"continue")) {
            const contTok = this.advance();
            return Expr{ .controlFlow = .{ .loc = locFromToken(contTok), .kind = .{ .@"continue" = {} } } };
        }

        // assert condition [,"message"]
        if (this.check(.assert)) {
            const assertTok = this.advance();
            const condition = try this.parseExpr(alloc);
            const conditionPtr = try this.boxExpr(alloc, condition);
            var message: ?*Expr = null;
            if (this.match(.comma)) {
                const msgExpr = try this.parseExpr(alloc);
                message = try this.boxExpr(alloc, msgExpr);
            }
            return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assert = .{ .condition = conditionPtr, .message = message } } } };
        }

        // loop (iter) { params -> body }  /  loop (iter, 0..) { item, i -> body }
        if (this.check(.loop)) {
            return .{ .controlFlow = try this.parseLoopExpr(alloc) };
        }

        // #(e1, e2, ...) ---- tuple literal
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            return .{ .collection = try this.parseTupleLitExpr(alloc) };
        }

        // val/var binding (local or destructuring)
        if (this.check(.val) or this.check(.@"var")) {
            return try this.parseLocalBindExpr(alloc);
        }

        // ident += expr  ou  ident.field += expr
        if (this.check(.identifier)) {
            const saved = this.current;
            const first = this.advance();

            // Simple assignment: ident += expr (no field access)
            if (this.match(.plusEqual)) {
                const valExpr = try this.parseExpr(alloc);
                const valPtr = try alloc.create(Expr);
                valPtr.* = valExpr;
                return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assignPlus = .{ .name = first.lexeme, .value = valPtr } } } };
            }

            if (this.check(.dot)) {
                _ = this.advance();
                // Accept both identifier and numberLiteral for tuple access (.0, .1)
                const fieldTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    try this.consume(.identifier);

                if (this.match(.equal)) {
                    const valExpr = try this.parseEqExpr(alloc);
                    const valPtr = try alloc.create(Expr);
                    valPtr.* = valExpr;
                    const recvPtr = try alloc.create(Expr);
                    recvPtr.* = Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } };
                    return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .fieldAssign = .{ .receiver = recvPtr, .field = fieldTok.lexeme, .value = valPtr } } } };
                }

                if (this.match(.plusEqual)) {
                    const valExpr = try this.parseEqExpr(alloc);
                    const valPtr = try alloc.create(Expr);
                    valPtr.* = valExpr;
                    const recvPtr = try alloc.create(Expr);
                    recvPtr.* = Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } };
                    return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .fieldPlusEq = .{ .receiver = recvPtr, .field = fieldTok.lexeme, .value = valPtr } } } };
                }

                this.current = saved;
            } else {
                this.current = saved;
            }
        }

        // ── call expressions: ident(...) {...}, ident {...}, recv.method(...) {...} ──
        if (this.check(.identifier)) {
            const saved = this.current;
            const firstTok = this.advance();

            // Method call: first.method(args...) trailing...
            //          or: first.method trailing...
            if (this.match(.dot)) {
                // Accept both identifier and numberLiteral for tuple access
                const methodTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    try this.consume(.identifier);

                var args: []CallArg = &.{};
                if (this.check(.leftParenthesis)) {
                    args = try this.parseCallArgs(alloc);
                }
                errdefer {
                    for (args) |*a| a.deinit(alloc);
                    alloc.free(args);
                }

                const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }

                if (args.len > 0 or trailing.len > 0) {
                    return this.wrapCatch(alloc, Expr{ .call = .{
                        .loc = locFromToken(firstTok),
                        .kind = .{ .call = .{
                            .receiver = firstTok.lexeme,
                            .callee = methodTok.lexeme,
                            .args = args,
                            .trailing = trailing,
                        } },
                    } });
                }

                // No args or trailing lambdas.
                // Fall back so parsePrimary handles field access: self.field or Color.Red
                this.current = saved;
            }

            // Plain call: ident(args...) trailing...
            else if (this.check(.leftParenthesis)) {
                const args = try this.parseCallArgs(alloc);
                errdefer {
                    for (args) |*a| a.deinit(alloc);
                    alloc.free(args);
                }
                const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }
                return this.wrapCatch(alloc, Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                    .receiver = null,
                    .callee = firstTok.lexeme,
                    .args = args,
                    .trailing = trailing,
                } } } });
            }

            // Call with only trailing lambdas: ident { ... } label: { ... }
            // (only when not in noTrailingLambda mode)
            else if (!this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda())) {
                const trailing = try this.parseTrailingLambdas(alloc);
                errdefer {
                    for (trailing) |*t| t.deinit(alloc);
                    alloc.free(trailing);
                }
                if (trailing.len > 0) {
                    return this.wrapCatch(alloc, Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                        .receiver = null,
                        .callee = firstTok.lexeme,
                        .args = &.{},
                        .trailing = trailing,
                    } } } });
                }
                for (trailing) |*t| t.deinit(alloc);
                alloc.free(trailing);
                this.current = saved;
            } else {
                this.current = saved;
            }
        }

        return this.wrapCatch(alloc, try this.parsePipelineExpr(alloc));
    }

    /// `val/var name = expr` or any destructuring variant.
    /// Call when current token is `val` or `var`.
    fn parseLocalBindExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        const mutable = this.peek().kind == .@"var";
        const bindTok = this.advance(); // consume 'val' or 'var'

        // Pattern assertion: val assert Pattern = expr catch handler
        if (this.check(.assert)) {
            const savedPos = this.current;
            const assertTok = this.advance(); // consume 'assert'

            if (this.parsePattern(alloc)) |pattern| {
                if (this.match(.equal)) {
                    // noTailCatch prevents `catch` from being consumed as tail operator
                    const savedNTC2 = this.noTailCatch;
                    this.noTailCatch = true;
                    var expr = try this.parseExpr(alloc);
                    this.noTailCatch = savedNTC2;
                    errdefer expr.deinit(alloc);
                    const exprPtr = try this.boxExpr(alloc, expr);
                    errdefer {
                        exprPtr.deinit(alloc);
                        alloc.destroy(exprPtr);
                    }
                    errdefer {
                        var mutPattern = pattern;
                        mutPattern.deinit(alloc);
                    }

                    if (this.match(.@"catch")) {
                        var catchExpr = if (this.check(.leftBrace)) blk: {
                            const stmts = try this.parseBlockWithOptionalTrailingSemicolon(alloc);
                            errdefer {
                                for (stmts) |*s| s.deinit(alloc);
                                alloc.free(stmts);
                            }
                            const resultOwned = stmts[stmts.len - 1].expr;
                            alloc.free(stmts);
                            break :blk resultOwned;
                        } else try this.parseExpr(alloc);
                        errdefer catchExpr.deinit(alloc);
                        const catchExprPtr = try this.boxExpr(alloc, catchExpr);
                        return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assertPattern = .{
                            .pattern = pattern,
                            .expr = exprPtr,
                            .handler = catchExprPtr,
                        } } } };
                    } else {
                        return ParseError.UnexpectedToken;
                    }
                } else {
                    var mutPattern = pattern;
                    mutPattern.deinit(alloc);
                }
            } else |_| {}

            this.current = savedPos;
        }

        // Record destructuring: val { x, y } = expr
        if (this.check(.leftBrace)) {
            _ = this.advance();
            var fields: std.ArrayList(ast.FieldDestruct) = .empty;
            errdefer {
                for (fields.items) |f| {
                    alloc.free(f.field_name);
                    alloc.free(f.bind_name);
                }
                fields.deinit(alloc);
            }
            var hasSpread = false;
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                if (this.check(.dotDot)) {
                    _ = this.advance();
                    hasSpread = true;
                    break;
                }
                const field_name = try alloc.dupe(u8, (try this.consume(.identifier)).lexeme);
                const bind_name: []const u8 = if (this.match(.colon))
                    try alloc.dupe(u8, (try this.consume(.identifier)).lexeme)
                else
                    field_name;
                try fields.append(alloc, .{ .field_name = field_name, .bind_name = bind_name });
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightBrace);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .names = .{ .fields = try fields.toOwnedSlice(alloc), .hasSpread = hasSpread } },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // Tuple destructuring: val #(a, b) = expr
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            _ = this.advance();
            _ = this.advance(); // '#' '('
            var names: std.ArrayList([]const u8) = .empty;
            errdefer names.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try names.append(alloc, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .tuple_ = try names.toOwnedSlice(alloc) },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // List destructuring: val [...] = expr
        if (this.check(.leftSquareBracket)) {
            const listPattern = try this.parseListPattern(alloc);
            _ = try this.consume(.equal);
            const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
            return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                .pattern = .{ .list = listPattern },
                .value = valPtr,
                .mutable = mutable,
            } } } };
        }

        // Constructor destructuring: val Ctor(fields) = expr
        if (this.check(.identifier)) {
            const saved = this.current;
            const ctorName = this.advance().lexeme;
            if (this.check(.leftParenthesis)) {
                _ = this.advance();
                var args: std.ArrayList(Pattern) = .empty;
                errdefer {
                    for (args.items) |*a| a.deinit(alloc);
                    args.deinit(alloc);
                }
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    try args.append(alloc, try this.parseSimplePattern(alloc));
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
                _ = try this.consume(.equal);
                const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
                return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBindDestruct = .{
                    .pattern = .{ .ctor = .{ .variantLiterals = .{ .name = ctorName, .args = try args.toOwnedSlice(alloc) } } },
                    .value = valPtr,
                    .mutable = mutable,
                } } } };
            }
            this.current = saved;
        }

        // Plain binding: val name [: TypeRef] = expr
        const nameTok = this.tokens[this.current];
        if (nameTok.kind != .identifier and nameTok.kind != .underscore) {
            return ParseError.UnexpectedToken;
        }
        _ = this.advance();
        const name = if (nameTok.kind == .underscore) "_" else nameTok.lexeme;
        if (this.match(.colon)) {
            var typeRef = try this.parseTypeRef(alloc);
            typeRef.deinit(alloc); // discarded — type inference handles it
        }
        _ = try this.consume(.equal);
        const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
        return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBind = .{
            .name = name,
            .value = valPtr,
            .mutable = mutable,
        } } } };
    }

    fn parsePipelineExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseOrExpr(alloc);

        while (true) {
            // Collect any comment that appears before the `|>` operator
            const savedPipe = this.current;
            var pipeComment: ?[]const u8 = null;
            while (this.isComment() or this.check(.newLine)) {
                const tok = this.advance();
                if (tok.kind == .commentNormal) {
                    // Free previous comment if multiple (keep last one)
                    if (pipeComment) |prev| alloc.free(prev);
                    pipeComment = try alloc.dupe(u8, commentText(tok.lexeme));
                }
            }
            if (!this.match(.pipe)) {
                if (pipeComment) |c| alloc.free(c);
                this.current = savedPipe;
                break;
            }
            const opTok = this.tokens[this.current - 1];
            // Skip comment tokens after `|>` (before RHS)
            while (this.isComment() or this.check(.newLine)) {
                _ = this.advance();
            }
            // Pipeline RHS can be a call expression: `add(2)`, `Recv.method(args)`, or a plain expr
            const rhs = rhs_blk: {
                if (this.check(.identifier)) {
                    const saved = this.current;
                    const nameTok = this.advance();
                    if (this.check(.leftParenthesis)) {
                        // ident(args) call
                        const args = try this.parseCallArgs(alloc);
                        errdefer {
                            for (args) |*a| a.deinit(alloc);
                            alloc.free(args);
                        }
                        const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                        errdefer {
                            for (trailing) |*t| t.deinit(alloc);
                            alloc.free(trailing);
                        }
                        break :rhs_blk Expr{ .call = .{ .loc = locFromToken(nameTok), .kind = .{ .call = .{
                            .receiver = null,
                            .callee = nameTok.lexeme,
                            .args = args,
                            .trailing = trailing,
                        } } } };
                    } else if (this.match(.dot)) {
                        const methodTok = try this.consume(.identifier);
                        var args: []CallArg = &.{};
                        if (this.check(.leftParenthesis)) {
                            args = try this.parseCallArgs(alloc);
                        }
                        errdefer {
                            for (args) |*a| a.deinit(alloc);
                            alloc.free(args);
                        }
                        const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
                        errdefer {
                            for (trailing) |*t| t.deinit(alloc);
                            alloc.free(trailing);
                        }
                        break :rhs_blk Expr{ .call = .{ .loc = locFromToken(nameTok), .kind = .{ .call = .{
                            .receiver = nameTok.lexeme,
                            .callee = methodTok.lexeme,
                            .args = args,
                            .trailing = trailing,
                        } } } };
                    } else {
                        this.current = saved;
                    }
                }
                break :rhs_blk try this.parseOrExpr(alloc);
            };
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .call = .{ .loc = locFromToken(opTok), .kind = .{ .pipeline = .{ .lhs = lhsPtr, .rhs = rhsPtr, .comment = pipeComment } } } };
        }

        return lhs;
    }

    fn parseOrExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseAndExpr(alloc);

        while (this.match(.verticalBarVerticalBar)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseAndExpr(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = .{ .@"or" = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } };
        }

        return lhs;
    }

    fn parseAndExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseEqExpr(alloc);

        while (this.match(.amperAmper)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseEqExpr(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = .{ .@"and" = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } };
        }

        return lhs;
    }

    fn parseEqExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseCompareExpr(alloc);

        while (this.match(.equalEqual) or this.match(.notEqual)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseCompareExpr(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = if (opTok.kind == .equalEqual)
                .{ .eq = .{ .lhs = lhsPtr, .rhs = rhsPtr } }
            else
                .{ .ne = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } };
        }

        return lhs;
    }

    fn parseCompareExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseAddExpr(alloc);

        while (this.match(.lessThan) or this.match(.greaterThan) or
            this.match(.lessThanEqual) or this.match(.greaterThanEqual))
        {
            const opTok = this.tokens[this.current - 1];
            if (this.check(.val) or this.check(.endOfFile)) {
                this.parseError = .{
                    .kind = .opNakedRight,
                    .start = opTok.col - 1,
                    .end = opTok.col - 1 + opTok.lexeme.len,
                    .lexeme = opTok.lexeme,
                    .line = opTok.line,
                    .col = opTok.col,
                };
                return ParseError.UnexpectedToken;
            }
            const rhs = try this.parseAddExpr(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = switch (opTok.kind) {
                .lessThan => .{ .lt = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .greaterThan => .{ .gt = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .lessThanEqual => .{ .lte = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .greaterThanEqual => .{ .gte = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                else => unreachable,
            } } };
        }

        return lhs;
    }

    fn parseAddExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseMulExpr(alloc);

        while (this.match(.plus) or this.match(.minus)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseMulExpr(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = if (opTok.kind == .plus)
                .{ .add = .{ .lhs = lhsPtr, .rhs = rhsPtr } }
            else
                .{ .sub = .{ .lhs = lhsPtr, .rhs = rhsPtr } } } };
        }

        return lhs;
    }

    fn parseMulExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parsePrimary(alloc);

        while (this.match(.star) or this.match(.slash) or this.match(.percent)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parsePrimary(alloc);
            const lhsPtr = try alloc.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try alloc.create(Expr);
            rhsPtr.* = rhs;
            lhs = Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .kind = switch (opTok.kind) {
                .star => .{ .mul = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .slash => .{ .div = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .percent => .{ .mod = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                else => unreachable,
            } } };
        }

        return lhs;
    }

    fn parsePrimary(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        // Unary `-` — negation of any expression (-x, -123, -(a+b), etc.)
        if (this.check(.minus)) {
            const opTok = this.advance();
            const operand = try this.parsePrimary(alloc);
            const operandPtr = try alloc.create(Expr);
            operandPtr.* = operand;
            return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .kind = .{ .neg = operandPtr } } };
        }

        // { params? -> body } ---- lambda expression (standalone or trailing)
        // Note: regular block expressions are only via @block builtin
        if (this.check(.leftBrace)) {
            const braceTok = this.advance();

            // Check if this is a lambda by looking ahead for `->` or params followed by `->`
            const isLambda = blk: {
                var i = this.current;
                const toks = this.tokens;
                const nextKind = if (i < toks.len) toks[i].kind else .endOfFile;
                // Empty lambda: `{ -> }`
                if (nextKind == .rightArrow) break :blk true;
                // Lambda with params: `{ ident, ident -> }`
                if (nextKind == .identifier) {
                    i += 1;
                    while (i < toks.len and toks[i].kind == .comma) {
                        i += 1;
                        if (i >= toks.len or toks[i].kind != .identifier) break :blk false;
                        i += 1;
                    }
                    const arrowKind = if (i < toks.len) toks[i].kind else .endOfFile;
                    break :blk arrowKind == .rightArrow;
                }
                break :blk false;
            };

            if (isLambda) {
                // Parse lambda: `{ params? -> body }`
                var paramList: std.ArrayList([]const u8) = .empty;
                errdefer paramList.deinit(alloc);

                // Parse parameters if present
                if (this.check(.identifier)) {
                    try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                    while (this.match(.comma)) {
                        try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                    }
                }
                _ = try this.consume(.rightArrow);

                // Parse body statements (with semicolons)
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (stmts.items) |*s| s.deinit(alloc);
                    stmts.deinit(alloc);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const expr = try this.parseExpr(alloc);
                    try stmts.append(alloc, .{ .expr = expr });
                    // Consume semicolon if present
                    if (this.check(.semicolon)) {
                        _ = try this.consume(.semicolon);
                    }
                }
                _ = try this.consume(.rightBrace);

                return Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{ .lambda = .{
                    .params = try paramList.toOwnedSlice(alloc),
                    .body = try stmts.toOwnedSlice(alloc),
                } } } };
            } else {
                // { } without -> is not allowed (use @block builtin instead)
                return ParseError.UnexpectedToken;
            }
        }

        // Unary `!` — logical not
        if (this.check(.bang)) {
            const opTok = this.advance();
            const operand = try this.parsePrimary(alloc);
            const operandPtr = try alloc.create(Expr);
            operandPtr.* = operand;
            return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .kind = .{ .not = operandPtr } } };
        }

        // @name(args...) ---- built-in function call
        if (this.check(.builtinIdent)) {
            const nameTok = this.advance();

            // Special handling for @block { ... } syntax (without parentheses)
            if (std.mem.eql(u8, nameTok.lexeme, "@block") and this.check(.leftBrace)) {
                const block = try this.parseBlockExpr(alloc);
                const blockExprPtr = try alloc.create(Expr);
                blockExprPtr.* = .{ .collection = block };
                const args = try alloc.alloc(ast.CallArg, 1);
                args[0] = .{ .label = null, .value = blockExprPtr, .comments = &.{} };
                return Expr{ .call = .{ .loc = locFromToken(nameTok), .kind = .{ .builtinCall = .{
                    .name = nameTok.lexeme,
                    .args = args,
                } } } };
            }

            const args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }
            return Expr{ .call = .{ .loc = locFromToken(nameTok), .kind = .{ .builtinCall = .{ .name = nameTok.lexeme, .args = args } } } };
        }

        if (this.check(.stringLiteral)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] } } };
        }
        if (this.check(.multilineStringLiteral)) {
            const tok = this.advance();
            // Remove the triple quotes from both ends
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .stringLit = tok.lexeme[3 .. tok.lexeme.len - 3] } } };
        }

        if (this.check(.numberLiteral)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .numberLit = tok.lexeme } } };
        }

        if (this.check(.selfType)) {
            const tok = this.advance();
            return Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = "Self" } } };
        }

        // fn(params) { body } ---- anonymous function expression
        if (this.check(.@"fn")) {
            const fnTok = this.advance();
            _ = try this.consume(.leftParenthesis);
            var params: std.ArrayList([]const u8) = .empty;
            errdefer params.deinit(alloc);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try params.append(alloc, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            const body = try this.parseStmtListInBraces(alloc);
            return Expr{ .function = .{ .loc = locFromToken(fnTok), .kind = .{ .fnExpr = .{
                .params = try params.toOwnedSlice(alloc),
                .body = body,
            } } } };
        }

        if (this.check(.null)) {
            const tok = this.advance();
            return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .null_ } };
        }

        // Detect reserved word used as expression
        if (isReservedWord(this.peek().kind)) {
            const tok = this.peek();
            this.parseError = .{
                .kind = .reservedWord,
                .start = tok.col - 1,
                .end = tok.col - 1 + tok.lexeme.len,
                .lexeme = tok.lexeme,
                .line = tok.line,
                .col = tok.col,
                .detail = tok.lexeme,
            };
            return ParseError.UnexpectedToken;
        }

        if (this.check(.identifier)) {
            const tok = this.advance();
            var base: Expr = Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = tok.lexeme } } };

            // Loop for chained field access: a.b.c.d
            while (this.check(.dot)) {
                _ = this.advance();
                // Accept both identifier and numberLiteral for tuple access
                const fieldTok: Token = if (this.check(.numberLiteral))
                    this.advance()
                else
                    try this.consume(.identifier);
                const recvPtr = try alloc.create(Expr);
                recvPtr.* = base;
                base = Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .identAccess = .{
                    .receiver = recvPtr,
                    .member = fieldTok.lexeme,
                } } } };
            }
            return base;
        }

        // Dot-shorthand variant: `.Red` ---- type resolved from context.
        if (this.check(.dot)) {
            const dotTok = this.advance();
            const memberTok = try this.consume(.identifier);
            return Expr{ .identifier = .{ .loc = locFromToken(dotTok), .kind = .{ .dotIdent = memberTok.lexeme } } };
        }

        // [e1, e2, ...] or [e1, ..rest] ---- array literal with optional spread
        if (this.check(.leftSquareBracket)) {
            return .{ .collection = try this.parseArrayLitExpr(alloc) };
        }

        // `(expr)` ---- grouped expression (parentheses for precedence)
        if (this.check(.leftParenthesis)) {
            const parenTok = this.advance();
            const inner = try this.parseExpr(alloc);
            _ = try this.consume(.rightParenthesis);
            const innerPtr = try alloc.create(ast.Expr);
            innerPtr.* = inner;
            return Expr{ .collection = .{ .loc = locFromToken(parenTok), .kind = .{ .grouped = innerPtr } } };
        }

        return ParseError.UnexpectedToken;
    }

    // ── collection literal helpers ────────────────────────────────────────────

    /// `#(e1, e2, ...)` ---- tuple literal.  Call when current token is `#`.
    fn parseTupleLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const tupleTok = this.advance(); // '#'
        _ = this.advance(); // '('
        var elems: std.ArrayList(Expr) = .empty;
        errdefer {
            for (elems.items) |*e| e.deinit(alloc);
            elems.deinit(alloc);
        }
        var allComments: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (allComments.items) |c| alloc.free(c);
            allComments.deinit(alloc);
        }
        var commentsPerElem: std.ArrayList(u32) = .empty;
        errdefer commentsPerElem.deinit(alloc);

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            var commentsBefore: u32 = 0;
            while (this.isComment()) {
                const cTok = this.advance();
                try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
                commentsBefore += 1;
            }
            if (this.check(.rightParenthesis)) {
                try commentsPerElem.append(alloc, commentsBefore);
                break;
            }
            try commentsPerElem.append(alloc, commentsBefore);
            try elems.append(alloc, try this.parseExpr(alloc));
            if (!this.match(.comma)) break;
        }
        var trailingCount: u32 = 0;
        while (this.isComment()) {
            const cTok = this.advance();
            try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            trailingCount += 1;
        }
        if (allComments.items.len > 0) {
            if (commentsPerElem.items.len == elems.items.len) {
                try commentsPerElem.append(alloc, trailingCount);
            }
        } else {
            commentsPerElem.clearAndFree(alloc);
        }
        _ = try this.consume(.rightParenthesis);
        return .{
            .loc = locFromToken(tupleTok),
            .kind = .{
                .tupleLit = .{
                    .elems = try elems.toOwnedSlice(alloc),
                    .comments = try allComments.toOwnedSlice(alloc),
                    .commentsPerElem = try commentsPerElem.toOwnedSlice(alloc),
                },
            },
        };
    }

    /// `[e1, e2, ...]` or `[e1, ..rest]` ---- array literal.  Call when current token is `[`.
    fn parseArrayLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const bracketTok = this.advance(); // '['
        var elems: std.ArrayList(Expr) = .empty;
        errdefer {
            for (elems.items) |*e| e.deinit(alloc);
            elems.deinit(alloc);
        }
        var spread: ?[]const u8 = null;
        var spreadExpr: ?*Expr = null;
        errdefer if (spreadExpr) |se| {
            se.deinit(alloc);
            alloc.destroy(se);
        };
        var trailingComma = false;
        var allComments: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (allComments.items) |c| alloc.free(c);
            allComments.deinit(alloc);
        }
        var commentsPerElem: std.ArrayList(u32) = .empty;
        errdefer commentsPerElem.deinit(alloc);

        while (!this.check(.rightSquareBracket) and !this.check(.endOfFile)) {
            var commentsBefore: u32 = 0;
            while (this.isComment()) {
                const cTok = this.advance();
                try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
                commentsBefore += 1;
            }

            if (this.check(.dotDot)) {
                try commentsPerElem.append(alloc, commentsBefore);
                _ = this.advance();
                if (this.check(.identifier)) {
                    spread = this.advance().lexeme;
                } else if (!this.check(.rightSquareBracket) and !this.check(.endOfFile) and !this.check(.comma)) {
                    const se = try this.parseExpr(alloc);
                    spreadExpr = try alloc.create(Expr);
                    spreadExpr.?.* = se;
                } else {
                    spread = "";
                }
                if (this.match(.comma)) {
                    if (this.check(.rightSquareBracket)) trailingComma = true;
                }
                break;
            }

            if (this.check(.rightSquareBracket)) {
                try commentsPerElem.append(alloc, 0); // spread slot (no spread)
                try commentsPerElem.append(alloc, commentsBefore); // trailing
                break;
            }

            try commentsPerElem.append(alloc, commentsBefore);
            try elems.append(alloc, try this.parseExpr(alloc));
            if (!this.match(.comma)) break;
            if (this.check(.rightSquareBracket)) {
                trailingComma = true;
                break;
            }
        }

        var trailingCommentCount: u32 = 0;
        while (this.isComment()) {
            const cTok = this.advance();
            try allComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            trailingCommentCount += 1;
        }

        const hasSpreadSlot = (spread != null or spreadExpr != null);
        if (allComments.items.len > 0 or trailingCommentCount > 0) {
            if (!hasSpreadSlot and commentsPerElem.items.len == elems.items.len) {
                try commentsPerElem.append(alloc, 0);
            }
            if (commentsPerElem.items.len == elems.items.len + 1) {
                try commentsPerElem.append(alloc, trailingCommentCount);
            }
        } else {
            commentsPerElem.clearAndFree(alloc);
        }

        _ = try this.consume(.rightSquareBracket);
        const commentsSlice = try allComments.toOwnedSlice(alloc);
        errdefer {
            for (commentsSlice) |c| alloc.free(c);
            alloc.free(commentsSlice);
        }
        return .{
            .loc = locFromToken(bracketTok),
            .kind = .{
                .arrayLit = .{
                    .elems = try elems.toOwnedSlice(alloc),
                    .spread = spread,
                    .spreadExpr = spreadExpr,
                    .comments = commentsSlice,
                    .commentsPerElem = try commentsPerElem.toOwnedSlice(alloc),
                    .trailingComma = trailingComma,
                },
            },
        };
    }

    // ── lambda / call helpers ─────────────────────────────────────────────────

    /// Parses a block expression: `{ stmt; stmt; ... }`
    fn parseBlockExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
        const braceTok = try this.consume(.leftBrace);

        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) {
                const tok = this.advance();
                const kind: ast.CommentKind = if (tok.kind == .commentDoc)
                    .{ .doc = "" }
                else if (tok.kind == .commentModule)
                    .{ .module = "" }
                else
                    .{ .normal = "" };
                const text = try alloc.dupe(u8, commentText(tok.lexeme));
                try stmts.append(alloc, .{ .expr = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .comment = .{ .kind = kind, .text = text } } } } });
                continue;
            }
            const expr = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return .{
            .loc = locFromToken(braceTok),
            .kind = .{
                .block = .{
                    .body = try stmts.toOwnedSlice(alloc),
                },
            },
        };
    }

    /// Returns true if the current token is any kind of comment.
    fn isComment(this: *const This) bool {
        const toks = this.tokens;
        if (this.current >= toks.len) return false;
        const k = toks[this.current].kind;
        return k == .commentNormal or k == .commentDoc or k == .commentModule;
    }

    /// Returns true if the upcoming tokens look like a lambda parameter list:
    /// `ident (,ident)* ->`.
    /// Does not consume any tokens.
    fn hasLambdaParams(this: *const This) bool {
        var i = this.current;
        const toks = this.tokens;
        if (i >= toks.len or toks[i].kind != .identifier) return false;
        i += 1;
        while (i < toks.len and toks[i].kind == .comma) {
            i += 1;
            if (i >= toks.len or toks[i].kind != .identifier) return false;
            i += 1;
        }
        return i < toks.len and toks[i].kind == .rightArrow;
    }

    /// Returns true if the upcoming tokens (after current) look like a lambda body:
    /// `{ ident (,ident)* -> ... }` or `{ -> ... }`.
    /// Used when current token is `{` to check if this is a lambda vs block.
    fn hasLambdaBodyAhead(this: *const This) bool {
        var i = this.current + 1; // Skip the current `{`
        const toks = this.tokens;
        if (i >= toks.len) return false;

        // Check for `->` immediately (lambda with no params)
        if (toks[i].kind == .rightArrow) return true;

        // Check for `ident (,ident)* ->`
        if (toks[i].kind != .identifier) return false;
        i += 1;
        while (i < toks.len and toks[i].kind == .comma) {
            i += 1;
            if (i >= toks.len or toks[i].kind != .identifier) return false;
            i += 1;
        }
        return i < toks.len and toks[i].kind == .rightArrow;
    }

    /// Returns true if the upcoming tokens are `ident : {` ---- a labeled trailing lambda.
    fn checkLabeledTrailingLambda(this: *const This) bool {
        const i = this.current;
        const toks = this.tokens;
        return i + 2 < toks.len and
            toks[i].kind == .identifier and
            toks[i + 1].kind == .colon and
            toks[i + 2].kind == .leftBrace;
    }

    /// Parses the body of a lambda after `{` has been consumed.
    /// Grammar: `(ident (, ident)* ->)? stmt* }`
    fn parseLambdaBody(this: *This, alloc: std.mem.Allocator) ParseError!FunctionExpr {
        const startTok = this.peek();
        // Detect and parse optional parameter list
        var paramList: std.ArrayList([]const u8) = .empty;
        errdefer paramList.deinit(alloc);

        if (this.hasLambdaParams()) {
            // Consume: ident (, ident)* ->
            try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
            while (this.match(.comma)) {
                try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
            }
            _ = try this.consume(.rightArrow);
        }

        // Parse body statements
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(alloc);
            try stmts.append(alloc, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return .{
            .loc = locFromToken(startTok),
            .kind = .{
                .lambda = .{
                    .params = try paramList.toOwnedSlice(alloc),
                    .body = try stmts.toOwnedSlice(alloc),
                },
            },
        };
    }

    fn parseCallArgs(this: *This, alloc: std.mem.Allocator) ParseError![]CallArg {
        _ = try this.consume(.leftParenthesis);
        var args: std.ArrayList(CallArg) = .empty;
        errdefer {
            for (args.items) |*a| a.deinit(alloc);
            args.deinit(alloc);
        }

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            // Collect comments before this argument
            var argComments: std.ArrayList([]const u8) = .empty;
            errdefer argComments.deinit(alloc);
            while (this.isComment()) {
                const cTok = this.advance();
                try argComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
            }

            // Detect named arg: ident : expr
            const label: ?[]const u8 = blk: {
                if (this.check(.identifier)) {
                    const i = this.current;
                    const toks = this.tokens;
                    if (i + 1 < toks.len and toks[i + 1].kind == .colon) {
                        const lbl = this.advance().lexeme; // consume ident
                        _ = this.advance(); // consume ':'
                        break :blk lbl;
                    }
                }
                break :blk null;
            };

            const valExpr = try this.parseExpr(alloc);
            const valPtr = try alloc.create(Expr);
            valPtr.* = valExpr;
            const commentsSlice = try argComments.toOwnedSlice(alloc);
            try args.append(alloc, .{ .label = label, .value = valPtr, .comments = commentsSlice });

            if (!this.match(.comma)) break;
        }

        _ = try this.consume(.rightParenthesis);
        return args.toOwnedSlice(alloc);
    }

    /// Parses zero or more trailing lambda blocks:
    ///   `{ params? -> body }`  or  `label: { params? -> body }`
    fn parseTrailingLambdas(this: *This, alloc: std.mem.Allocator) ParseError![]TrailingLambda {
        var lambdas: std.ArrayList(TrailingLambda) = .empty;
        errdefer {
            for (lambdas.items) |*t| t.deinit(alloc);
            lambdas.deinit(alloc);
        }

        while (this.check(.leftBrace) or this.checkLabeledTrailingLambda()) {
            // Optional label: `erro: {`
            const label: ?[]const u8 = if (this.checkLabeledTrailingLambda()) lbl: {
                const lbl = this.advance().lexeme; // consume label ident
                _ = this.advance(); // consume ':'
                break :lbl lbl;
            } else null;

            _ = try this.consume(.leftBrace);

            // Detect params
            var paramList: std.ArrayList([]const u8) = .empty;
            errdefer paramList.deinit(alloc);

            if (this.hasLambdaParams()) {
                try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                while (this.match(.comma)) {
                    try paramList.append(alloc, (try this.consume(.identifier)).lexeme);
                }
                _ = try this.consume(.rightArrow);
            }

            // Parse body statements
            var stmts: std.ArrayList(Stmt) = .empty;
            errdefer {
                for (stmts.items) |*s| s.deinit(alloc);
                stmts.deinit(alloc);
            }
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                const expr = try this.parseExpr(alloc);
                _ = try this.consume(.semicolon);
                try stmts.append(alloc, .{ .expr = expr });
            }
            _ = try this.consume(.rightBrace);

            try lambdas.append(alloc, .{
                .label = label,
                .params = try paramList.toOwnedSlice(alloc),
                .body = try stmts.toOwnedSlice(alloc),
            });
        }

        return lambdas.toOwnedSlice(alloc);
    }

    // ── primitives ────────────────────────────────────────────────────────────

    fn consume(this: *This, kind: TokenKind) ParseError!Token {
        if (this.check(kind)) return this.advance();
        // parseError may not be set here; the top-level caller must populate
        // it before propagating if rich error context is needed.
        return ParseError.UnexpectedToken;
    }

    fn match(this: *This, kind: TokenKind) bool {
        if (!this.check(kind)) return false;
        _ = this.advance();
        return true;
    }

    fn check(this: *This, kind: TokenKind) bool {
        return this.peek().kind == kind;
    }

    fn advance(this: *This) Token {
        const t = this.tokens[this.current];
        if (t.kind != .endOfFile) this.current += 1;
        return t;
    }

    fn peek(this: *This) Token {
        return this.tokens[this.current];
    }

    fn peekAt(this: *This, offset: usize) Token {
        const i = this.current + offset;
        return if (i < this.tokens.len) this.tokens[i] else this.tokens[this.tokens.len - 1];
    }

    // ── reserved word detection helpers ──────────────────────────────────────

    fn isReservedWord(kind: TokenKind) bool {
        return lexer.isReservedWord(kind);
    }

    /// Parses a `loop` expression:
    ///   `loop (iter) { param -> body }`
    ///   `loop (iter, 0..) { item, i -> body }`
    ///   `loop (start..end) { i -> body }`
    ///   `loop (start..) { i -> body }`
    fn parseLoopExpr(this: *This, alloc: std.mem.Allocator) ParseError!ControlFlowExpr {
        const loopTok = this.advance(); // consume 'loop'
        _ = try this.consume(.leftParenthesis);

        // Parse primary iterator expression (may be a range or identifier)
        const iterExpr = try this.parseRangeExpr(alloc);
        const iterPtr = try alloc.create(Expr);
        iterPtr.* = iterExpr;

        // Optional index range: `loop (iter, 0..)`
        var indexPtr: ?*Expr = null;
        if (this.match(.comma)) {
            const idxExpr = try this.parseRangeExpr(alloc);
            indexPtr = try alloc.create(Expr);
            indexPtr.?.* = idxExpr;
        }

        _ = try this.consume(.rightParenthesis);
        _ = try this.consume(.leftBrace);

        // Parse parameter list: `param1, param2, ...  ->`
        var params: std.ArrayList([]const u8) = .empty;
        errdefer params.deinit(alloc);
        while (this.check(.identifier)) {
            try params.append(alloc, this.advance().lexeme);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightArrow);

        // Body is already-consumed `{ stmt; ... }`
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const e = try this.parseExpr(alloc);
            _ = try this.consume(.semicolon);
            try stmts.append(alloc, .{ .expr = e });
        }
        _ = try this.consume(.rightBrace);
        const body = try stmts.toOwnedSlice(alloc);

        return .{
            .loc = locFromToken(loopTok),
            .kind = .{
                .loop = .{
                    .iter = iterPtr,
                    .indexRange = indexPtr,
                    .params = try params.toOwnedSlice(alloc),
                    .body = body,
                },
            },
        };
    }

    /// Parses a range expression `expr..` or `expr..expr`, or falls back to
    /// a plain `parseEqExpr` if `..` is not present.
    fn parseRangeExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
        var start = try this.parseEqExpr(alloc);
        errdefer start.deinit(alloc);
        if (!this.check(.dotDot)) return start;
        const dotTok = this.advance(); // consume '..'
        const startPtr = try alloc.create(Expr);
        startPtr.* = start;
        // Optional end: `0..10` vs `0..`
        const hasEnd = !this.check(.rightParenthesis) and !this.check(.comma) and
            !this.check(.endOfFile);
        if (hasEnd) {
            var end = try this.parseEqExpr(alloc);
            errdefer end.deinit(alloc);
            const endPtr = try alloc.create(Expr);
            endPtr.* = end;
            return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = endPtr } } } };
        }
        return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = null } } } };
    }
};

// ── List spread validation ---- public helpers ───────────────────────────────────

pub const ListSpreadError = enum {
    /// Spread without explicit tail: [1, 2, ..]
    noTail,
    /// Elements after spread: [..xs, 1, 2]
    elementsAfterSpread,
    /// Useless spread (sole element, no prepend): [..wibble]
    uselessSpread,
};

/// validates a list element sequence for spread errors.
/// Returns null if valid, or the error kind found.
pub fn validateListSpread(hasSpread: bool, spreadIsLast: bool, elementsBeforeSpread: usize) ?ListSpreadError {
    if (hasSpread) {
        if (!spreadIsLast) return .elementsAfterSpread;
        if (elementsBeforeSpread == 0) return .uselessSpread;
    }
    return null;
}

/// Error messages for invalid list spreads.
pub fn listSpreadErrorMessage(err: ListSpreadError) struct { message: []const u8, hint: []const u8 } {
    return switch (err) {
        .noTail => .{
            .message = "I was expecting a value after this spread",
            .hint = "If a list expression has a spread then a tail must also be given. Example: [1, 2, ..rest]",
        },
        .elementsAfterSpread => .{
            .message = "I wasn't expecting elements after this",
            .hint = "Lists are immutable and singly-linked. Prepend items to the list and then reverse it once you are done.",
        },
        .uselessSpread => .{
            .message = "This spread does nothing",
            .hint = "Try prepending some elements [1, 2, ..list].",
        },
    };
}

/// Prints a list spread error to stderr ---- convenient for CLIs.
/// For tests or custom output destinations, use `print.zig` directly.
pub fn printListSpreadError(err: ListSpreadError, path: []const u8, line: usize, col: usize, span: []const u8) void {
    const msgs = listSpreadErrorMessage(err);
    const stderr = std.io.getStdErr().writer();
    const lineW = blk: {
        var w: usize = 1;
        var n = line;
        while (n >= 10) : (n /= 10) w += 1;
        break :blk w;
    };
    stderr.print("error comptime: syntax error\n", .{}) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("┌─ {s}:{d}:{d}\n", .{ path, line, col }) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│\n", .{}) catch return;
    stderr.print("{d} │ {s}\n", .{ line, span }) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("│ ", .{}) catch return;
    for (0..col - 1) |_| stderr.writeByte(' ') catch return;
    for (0..span.len) |_| stderr.writeByte('^') catch return;
    stderr.print(" {s}\n\n", .{msgs.message}) catch return;
    for (0..lineW + 1) |_| stderr.writeByte(' ') catch return;
    stderr.print("hint: {s}\n\n", .{msgs.hint}) catch return;
}
