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
pub const ExprKind = ast.ExprKind;
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

    pub fn parse(this: *This, allocator: std.mem.Allocator) ParseError!Program {
        var decls: std.ArrayList(DeclKind) = .empty;
        errdefer {
            for (decls.items) |*d| d.deinit(allocator);
            decls.deinit(allocator);
        }
        while (!this.check(.endOfFile)) {
            const decl: DeclKind = if (this.check(.use)) blk: {
                const d = try this.parseUseDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.checkShorthand(.@"fn")) blk: {
                const d = try this.parseFnDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .@"fn" = d };
            } else if (this.checkShorthand(.@"enum")) blk: {
                const d = try this.parseShorthandEnumDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .@"enum" = d };
            } else if (this.checkShorthand(.@"struct")) blk: {
                const d = try this.parseShorthandStructDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .@"struct" = d };
            } else if (this.checkShorthand(.record)) blk: {
                const d = try this.parseShorthandRecordDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .record = d };
            } else if (this.checkShorthandDelegate()) blk: {
                const d = try this.parseShorthandDelegateDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .delegate = d };
            } else if (this.checkShorthand(.interface)) blk: {
                const d = try this.parseShorthandInterfaceDecl(allocator);
                _ = this.match(.semicolon);
                break :blk .{ .interface = d };
            } else if (this.check(.loop)) blk: {
                // top-level loop statement: parsed as a val named "_loop"
                const e = try this.parseLoopExpr(allocator);
                const ePtr = try allocator.create(Expr);
                ePtr.* = e;
                _ = this.match(.semicolon);
                break :blk DeclKind{ .val = ast.ValDecl{ .name = "_loop", .value = ePtr } };
            } else if (this.checkShorthand(.val)) blk: {
                const decl = try this.parseValForm(allocator);
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
                    .@"fn" => DeclKind{ .@"fn" = try this.parseFnDecl(allocator) },
                    .@"struct" => DeclKind{ .@"struct" = try this.parseShorthandStructDecl(allocator) },
                    .@"enum" => DeclKind{ .@"enum" = try this.parseShorthandEnumDecl(allocator) },
                    .record => DeclKind{ .record = try this.parseShorthandRecordDecl(allocator) },
                    .interface => DeclKind{ .interface = try this.parseShorthandInterfaceDecl(allocator) },
                    .declare => DeclKind{ .delegate = try this.parseShorthandDelegateDecl(allocator) },
                    else => return ParseError.UnexpectedToken,
                };
                // Optional semicolon after top-level declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else {
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
                }
                return ParseError.UnexpectedToken;
            };
            try decls.append(allocator, decl);
        }
        return Program{ .decls = try decls.toOwnedSlice(allocator) };
    }

    /// Dispatches `val [pub] Name = <kind> ...` to the appropriate sub-parser.
    /// Uses pure lookahead ---- no state mutation.
    fn parseValForm(this: *This, allocator: std.mem.Allocator) ParseError!DeclKind {
        const baseOffset = this.valBodyOffset();
        // peek past any inline annotations to find the real body keyword
        const offset = this.skipAnnotationsLookaheadFrom(baseOffset);
        const body = this.peekAt(offset).kind;
        const bodyNext = this.peekAt(offset + 1).kind;
        return switch (body) {
            .@"struct" => .{ .@"struct" = try this.parseStructDecl(allocator) },
            .record => .{ .record = try this.parseRecordDecl(allocator) },
            .implement => .{ .implement = try this.parseImplementDecl(allocator) },
            .@"enum" => .{ .@"enum" = try this.parseEnumDecl(allocator) },
            .declare => .{ .delegate = try this.parseDelegateDecl(allocator) },
            .interface => if (bodyNext == .@"fn")
                .{ .delegate = try this.parseDelegateDecl(allocator) }
            else
                .{ .interface = try this.parseInterfaceDecl(allocator) },
            .@"fn" => .{ .@"fn" = try this.parseFnDeclFromVal(allocator) },
            else => .{ .val = try this.parseValDecl(allocator) },
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
    fn parseBraceBlock(this: *This, allocator: std.mem.Allocator) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(allocator);
    }

    /// Parse either `{ expr; ... }` or a single `expr`.
    /// Used by `if`, `catch`, and any place that accepts a block or bare expression.
    /// Does NOT require semicolon after the bare expression.
    fn parseBlockOrExpr(this: *This, allocator: std.mem.Allocator) ParseError![]Stmt {
        if (this.check(.leftBrace)) {
            return this.parseBraceBlock(allocator);
        }
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        const expr = try this.parseExpr(allocator);
        try stmts.append(allocator, .{ .expr = expr });
        return stmts.toOwnedSlice(allocator);
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
    fn parseAnnotations(this: *This, allocator: std.mem.Allocator) ParseError![]Annotation {
        var list: std.ArrayList(Annotation) = .empty;
        errdefer {
            for (list.items) |*ann| ann.deinit(allocator);
            list.deinit(allocator);
        }
        while (this.check(.hash) and this.peekAt(1).kind == .leftSquareBracket) {
            _ = try this.consume(.hash);
            _ = try this.consume(.leftSquareBracket);
            // Accept any word (identifier or reserved word) as the annotation name.
            const nameTok = this.peek();
            if (nameTok.kind != .identifier and !isReservedWord(nameTok.kind)) return ParseError.UnexpectedToken;
            const name = this.advance().lexeme;
            var args: std.ArrayList([]const u8) = .empty;
            errdefer args.deinit(allocator);
            if (this.match(.leftParenthesis)) {
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    if (this.check(.dot) and this.peekAt(1).kind == .identifier) {
                        // `.erlang` — adjacent source bytes form a single lexeme
                        const dot = try this.consume(.dot);
                        const ident = try this.consume(.identifier);
                        try args.append(allocator, dot.lexeme.ptr[0 .. dot.lexeme.len + ident.lexeme.len]);
                    } else {
                        const tok = this.advance();
                        try args.append(allocator, tok.lexeme);
                    }
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
            }
            _ = try this.consume(.rightSquareBracket);
            try list.append(allocator, Annotation{
                .name = name,
                .args = try args.toOwnedSlice(allocator),
            });
        }
        return list.toOwnedSlice(allocator);
    }

    // ── expression helper ─────────────────────────────────────────────────────

    /// Wraps an `ExprKind` with the source location from `tok`.
    fn mkExpr(_: *This, kind: ast.ExprKind, tok: Token) Expr {
        return .{ .loc = .{ .line = tok.line, .col = tok.col }, .kind = kind };
    }

    // ── val decl ─────────────────────────────────────────────────────────────

    fn parseValDecl(this: *This, allocator: std.mem.Allocator) ParseError!ValDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        var typeAnnotation: ?ast.TypeRef = null;
        if (this.match(.colon)) {
            typeAnnotation = try this.parseTypeRef(allocator);
        }
        errdefer if (typeAnnotation) |*ann| ann.deinit(allocator);
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        var value = try this.parseExpr(allocator);
        errdefer value.deinit(allocator);
        const value_ptr = try allocator.create(Expr);
        value_ptr.* = value;
        // Semicolon required after top-level val declaration
        _ = try this.consume(.semicolon);
        return ValDecl{ .name = name, .isPub = isPub, .typeAnnotation = typeAnnotation, .value = value_ptr };
    }

    /// Parses a full type reference, including `E!T` error-union postfix.
    fn parseTypeRef(this: *This, allocator: std.mem.Allocator) ParseError!ast.TypeRef {
        var base = try this.parseBaseTypeRef(allocator);
        errdefer base.deinit(allocator);
        // E!T ---- error union: base is the error type, rhs is the payload
        if (this.match(.bang)) {
            var payload = try this.parseBaseTypeRef(allocator);
            errdefer payload.deinit(allocator);
            const errPtr = try allocator.create(ast.TypeRef);
            errPtr.* = base;
            const payPtr = try allocator.create(ast.TypeRef);
            payPtr.* = payload;
            return ast.TypeRef{ .errorUnion = .{ .errorType = errPtr, .payload = payPtr } };
        }
        return base;
    }

    /// Parses a base type ref: `?T`, `#(T1,T2)`, plain name with optional `[]` wraps.
    fn parseBaseTypeRef(this: *This, allocator: std.mem.Allocator) ParseError!ast.TypeRef {
        // ?T ---- optional type
        if (this.match(.questionMark)) {
            var inner = try this.parseBaseTypeRef(allocator);
            errdefer inner.deinit(allocator);
            const innerPtr = try allocator.create(ast.TypeRef);
            innerPtr.* = inner;
            return ast.TypeRef{ .optional = innerPtr };
        }
        // #(T1, T2, ...) ---- tuple type
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            _ = this.advance(); // consume '#'
            _ = this.advance(); // consume '('
            var elems: std.ArrayList(ast.TypeRef) = .empty;
            errdefer {
                for (elems.items) |*e| e.deinit(allocator);
                elems.deinit(allocator);
            }
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try elems.append(allocator, try this.parseTypeRef(allocator));
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            return ast.TypeRef{ .tuple_ = try elems.toOwnedSlice(allocator) };
        }
        // Plain named type, possibly followed by [] for array
        const nameTok = try this.consumeTypeName();
        var ref = ast.TypeRef{ .named = nameTok.lexeme };
        // T[] — zero or more array wraps
        while (this.check(.leftSquareBracket) and this.peekAt(1).kind == .rightSquareBracket) {
            _ = this.advance(); // [
            _ = this.advance(); // ]
            const elem = try allocator.create(ast.TypeRef);
            elem.* = ref;
            ref = ast.TypeRef{ .array = elem };
        }
        return ref;
    }

    // ── use decl ─────────────────────────────────────────────────────────────

    fn parseUseDecl(this: *This, allocator: std.mem.Allocator) ParseError!UseDecl {
        _ = try this.consume(.use);
        _ = try this.consume(.leftBrace);
        const imports = try this.parseImportList(allocator);
        errdefer allocator.free(imports);
        _ = try this.consume(.rightBrace);
        _ = try this.consume(.from);
        return UseDecl{ .imports = imports, .source = try this.parseSource() };
    }

    fn parseImportList(this: *This, allocator: std.mem.Allocator) ParseError![]const []const u8 {
        var names: std.ArrayList([]const u8) = .empty;
        errdefer names.deinit(allocator);
        if (!this.check(.identifier)) return names.toOwnedSlice(allocator);
        try names.append(allocator, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            if (this.check(.rightBrace)) break;
            try names.append(allocator, (try this.consume(.identifier)).lexeme);
        }
        return names.toOwnedSlice(allocator);
    }

    fn parseSource(this: *This) ParseError!Source {
        if (this.check(.stringLiteral)) {
            const tok = try this.consume(.stringLiteral);
            return Source{ .stringPath = tok.lexeme[1 .. tok.lexeme.len - 1] };
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

    fn parseFnDecl(this: *This, allocator: std.mem.Allocator) ParseError!FnDecl {
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*ann| ann.deinit(allocator);
            allocator.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;
        return this.parseFnBody(allocator, name, isPub, annotations);
    }

    /// `val name = #[...] fn(params) -> R { body }` — val-form annotated function.
    fn parseFnDeclFromVal(this: *This, allocator: std.mem.Allocator) ParseError!FnDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*ann| ann.deinit(allocator);
            allocator.free(annotations);
        }
        _ = try this.consume(.@"fn");
        return this.parseFnBody(allocator, name, false, annotations);
    }

    fn parseFnBody(
        this: *This,
        allocator: std.mem.Allocator,
        name: []const u8,
        isPub: bool,
        annotations: []Annotation,
    ) ParseError!FnDecl {
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        var params: std.ArrayList(Param) = .empty;
        errdefer {
            for (params.items) |*p| {
                if (p.typeinfoConstraints) |c| allocator.free(c);
            }
            params.deinit(allocator);
        }
        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(allocator);
        }
        errdefer if (returnType) |*rt| rt.deinit(allocator);

        const body = try this.parseBraceBlock(allocator);

        return FnDecl{
            .isPub = isPub,
            .name = name,
            .annotations = annotations,
            .genericParams = genericParams,
            .params = try params.toOwnedSlice(allocator),
            .returnType = returnType,
            .body = body,
        };
    }

    // ── delegate decl ────────────────────────────────────────────────────────────

    /// `val log = declare fn(self: Self) -> R`
    fn parseDelegateDecl(this: *This, allocator: std.mem.Allocator) ParseError!DelegateDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.equal);
        _ = try this.consume(.declare);
        _ = try this.consume(.@"fn");
        return this.parseDelegateParams(allocator, name, false);
    }

    /// `[pub] declare fn log(self: Self) -> R`
    fn parseShorthandDelegateDecl(this: *This, allocator: std.mem.Allocator) ParseError!DelegateDecl {
        const isPub = this.match(.@"pub");
        _ = try this.consume(.declare);
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;
        return this.parseDelegateParams(allocator, name, isPub);
    }

    fn parseDelegateParams(this: *This, allocator: std.mem.Allocator, name: []const u8, isPub: bool) ParseError!DelegateDecl {
        _ = try this.consume(.leftParenthesis);
        var params: std.ArrayList(Param) = .empty;
        errdefer {
            for (params.items) |*p| {
                if (p.typeinfoConstraints) |c| allocator.free(c);
                if (p.fnType) |*ft| ft.deinit(allocator);
            }
            params.deinit(allocator);
        }
        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);
        var returnType: ?[]const u8 = null;
        if (this.match(.rightArrow)) {
            returnType = (try this.consumeTypeName()).lexeme;
        }
        // Semicolon required after delegate declaration
        _ = try this.consume(.semicolon);
        return DelegateDecl{
            .name = name,
            .isPub = isPub,
            .params = try params.toOwnedSlice(allocator),
            .returnType = returnType,
        };
    }

    // ── interface decl ───────────────────────────────────────────────────────────

    fn parseInterfaceDecl(this: *This, allocator: std.mem.Allocator) ParseError!InterfaceDecl {
        _ = this.match(.@"pub"); // optional pub ---- consumed but not stored
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        _ = try this.consume(.interface);
        // optional: `extends T1, T2, T3` after `interface`
        const extendsSlice = try this.parseExtendsClause(allocator);
        return this.parseInterfaceBody(allocator, name, extendsSlice, annotations, false);
    }

    fn parseShorthandInterfaceDecl(this: *This, allocator: std.mem.Allocator) ParseError!InterfaceDecl {
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.interface);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        // optional: `extends T1, T2, T3` after name
        const extendsSlice = try this.parseExtendsClause(allocator);
        return this.parseInterfaceBody(allocator, name, extendsSlice, annotations, isPub);
    }

    /// Parses an optional `extends T1, T2, T3` clause.
    /// Returns an owned slice (may be empty). The caller owns the memory.
    fn parseExtendsClause(this: *This, allocator: std.mem.Allocator) ParseError![]const []const u8 {
        if (!this.match(.extends)) return &.{};
        var list: std.ArrayList([]const u8) = .empty;
        errdefer list.deinit(allocator);
        try list.append(allocator, (try this.consume(.identifier)).lexeme);
        while (this.match(.comma)) {
            try list.append(allocator, (try this.consume(.identifier)).lexeme);
        }
        return list.toOwnedSlice(allocator);
    }

    fn parseInterfaceBody(this: *This, allocator: std.mem.Allocator, name: []const u8, extendsSlice: []const []const u8, annotations: []Annotation, isPub: bool) ParseError!InterfaceDecl {
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);
        _ = try this.consume(.leftBrace);

        var fields: std.ArrayList(InterfaceField) = .empty;
        errdefer fields.deinit(allocator);

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.val)) {
                _ = try this.consume(.val);
                const fieldName = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                const typeName = (try this.consume(.identifier)).lexeme;
                _ = this.match(.comma);
                try fields.append(allocator, .{ .name = fieldName, .typeName = typeName });
            } else if (this.check(.default) or this.check(.@"fn")) {
                const is_default = this.match(.default);
                const method = try this.parseInterfaceMethod(allocator, is_default);
                _ = this.match(.comma);
                try methods.append(allocator, method);
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
            .fields = try fields.toOwnedSlice(allocator),
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    fn parseInterfaceMethod(this: *This, allocator: std.mem.Allocator, is_default: bool) ParseError!InterfaceMethod {
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;

        // optional generic params: `<T, R>`
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(allocator);
        }
        errdefer if (returnType) |*rt| rt.deinit(allocator);

        if (!is_default) {
            // Optional semicolon after abstract method declaration
            _ = this.match(.semicolon);
            return InterfaceMethod{
                .name = name,
                .genericParams = genericParams,
                .params = try params.toOwnedSlice(allocator),
                .returnType = returnType,
                .body = null,
                .is_default = false,
            };
        }

        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }

        _ = try this.consume(.rightBrace);

        return InterfaceMethod{
            .name = name,
            .genericParams = genericParams,
            .params = try params.toOwnedSlice(allocator),
            .returnType = returnType,
            .body = try stmts.toOwnedSlice(allocator),
            .is_default = true,
        };
    }

    /// Parse a method inside a struct, record, or enum body.
    /// `is_declare fn ` → abstract slot (no body, `is_declare = true`).
    /// Plain `fn` → always requires a body.
    fn parseMethodDecl(this: *This, allocator: std.mem.Allocator, is_declare: bool, isPub: bool) ParseError!InterfaceMethod {
        _ = try this.consume(.@"fn");
        const name = (try this.consume(.identifier)).lexeme;

        // optional generic params: `<T, R>`
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        var returnType: ?ast.TypeRef = null;
        if (this.match(.rightArrow)) {
            returnType = try this.parseTypeRef(allocator);
        }
        errdefer if (returnType) |*rt| rt.deinit(allocator);

        if (is_declare) {
            _ = try this.consume(.semicolon);
            return InterfaceMethod{
                .name = name,
                .genericParams = genericParams,
                .params = try params.toOwnedSlice(allocator),
                .returnType = returnType,
                .body = null,
                .is_default = false,
                .is_declare = true,
                .isPub = isPub,
            };
        }

        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }

        _ = try this.consume(.rightBrace);

        return InterfaceMethod{
            .name = name,
            .genericParams = genericParams,
            .params = try params.toOwnedSlice(allocator),
            .returnType = returnType,
            .body = try stmts.toOwnedSlice(allocator),
            .is_default = false,
            .is_declare = false,
            .isPub = isPub,
        };
    }

    // ── struct decl ───────────────────────────────────────────────────────────

    fn parseStructDecl(this: *This, allocator: std.mem.Allocator) ParseError!StructDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        _ = try this.consume(.@"struct");
        return this.parseStructBody(allocator, name, annotations, false);
    }

    fn parseShorthandStructDecl(this: *This, allocator: std.mem.Allocator) ParseError!StructDecl {
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"struct");
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseStructBody(allocator, name, annotations, isPub);
    }

    fn parseStructBody(this: *This, allocator: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!StructDecl {
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);
        _ = try this.consume(.leftBrace);

        var members: std.ArrayList(StructMember) = .empty;
        errdefer {
            for (members.items) |*m| m.deinit(allocator);
            members.deinit(allocator);
        }

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
                        initExpr = try this.parseExpr(allocator);
                    }
                    // Optional comma separator
                    _ = this.match(.comma);
                    try members.append(allocator, .{ .field = .{
                        .name = fieldName,
                        .typeName = typeName,
                        .init = initExpr,
                    } });
                    continue;
                }
            }

            if (this.check(.get)) {
                const getter = try this.parseStructGetter(allocator);
                try members.append(allocator, .{ .getter = getter });
            } else if (this.check(.set)) {
                const setter = try this.parseStructSetter(allocator);
                try members.append(allocator, .{ .setter = setter });
            } else if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(allocator, is_iface, is_pub);
                try members.append(allocator, .{ .method = method });
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
            .members = try members.toOwnedSlice(allocator),
        };
    }

    fn parseStructGetter(this: *This, allocator: std.mem.Allocator) ParseError!StructGetter {
        _ = try this.consume(.get);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.leftParenthesis);
        const selfParamName = (try this.consumeParamName()).lexeme;
        _ = try this.consume(.colon);
        const selfParamType = (try this.consumeTypeName()).lexeme;
        _ = try this.consume(.rightParenthesis);
        _ = try this.consume(.rightArrow);
        const returnType = (try this.consumeTypeName()).lexeme;

        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return StructGetter{
            .name = name,
            .selfParam = .{ .name = selfParamName, .typeName = selfParamType },
            .returnType = returnType,
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    fn parseStructSetter(this: *This, allocator: std.mem.Allocator) ParseError!StructSetter {
        _ = try this.consume(.set);
        const name = (try this.consume(.identifier)).lexeme;
        _ = try this.consume(.leftParenthesis);

        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);
        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return StructSetter{
            .name = name,
            .params = try params.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    // ── record decl ──────────────────────────────────────────────────────────

    fn parseRecordDecl(this: *This, allocator: std.mem.Allocator) ParseError!RecordDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        _ = try this.consume(.record);
        return this.parseRecordBody(allocator, name, annotations, false);
    }

    fn parseShorthandRecordDecl(this: *This, allocator: std.mem.Allocator) ParseError!RecordDecl {
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.record);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseRecordBody(allocator, name, annotations, isPub);
    }

    fn parseRecordBody(this: *This, allocator: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!RecordDecl {
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);
        _ = try this.consume(.leftBrace);

        var fields: std.ArrayList(RecordField) = .empty;
        errdefer {
            for (fields.items) |*f| f.deinit(allocator);
            fields.deinit(allocator);
        }

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            // Check if this is a method (fn/pub/declare)
            if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(allocator, is_iface, is_pub);
                try methods.append(allocator, method);
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
                var fieldType = try this.parseTypeRef(allocator);
                errdefer fieldType.deinit(allocator);
                var defaultExpr: ?Expr = null;
                if (this.match(.equal)) {
                    defaultExpr = try this.parseEqExpr(allocator);
                }
                // Optional comma separator
                _ = this.match(.comma);
                try fields.append(allocator, .{ .name = fieldName, .typeRef = fieldType, .default = defaultExpr });
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
            .fields = try fields.toOwnedSlice(allocator),
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    // ── implement decl ────────────────────────────────────────────────────────────

    fn parseImplementDecl(this: *This, allocator: std.mem.Allocator) ParseError!ImplementDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);
        _ = try this.consume(.equal);
        _ = try this.consume(.implement);

        var interfaces: std.ArrayList([]const u8) = .empty;
        errdefer interfaces.deinit(allocator);

        const firstInterface = (try this.consume(.identifier)).lexeme;
        try interfaces.append(allocator, firstInterface);
        while (this.match(.comma)) {
            if (this.check(.@"for")) break;
            try interfaces.append(allocator, (try this.consume(.identifier)).lexeme);
        }

        _ = try this.consume(.@"for");
        const target = (try this.consume(.identifier)).lexeme;

        _ = try this.consume(.leftBrace);
        var methods: std.ArrayList(ImplementMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.@"fn")) {
                const method = try this.parseImplementMethod(allocator);
                try methods.append(allocator, method);
            } else {
                return ParseError.UnexpectedToken;
            }
        }
        _ = try this.consume(.rightBrace);

        return ImplementDecl{
            .name = name,
            .genericParams = genericParams,
            .interfaces = try interfaces.toOwnedSlice(allocator),
            .target = target,
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    fn parseImplementMethod(this: *This, allocator: std.mem.Allocator) ParseError!ImplementMethod {
        _ = try this.consume(.@"fn");

        const first = (try this.consume(.identifier)).lexeme;
        var qualifier: ?[]const u8 = null;
        var methodName: []const u8 = first;

        if (this.match(.dot)) {
            qualifier = first;
            methodName = (try this.consume(.identifier)).lexeme;
        }

        // optional generic params: `<T, R>`
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);

        _ = try this.consume(.leftParenthesis);
        var params: std.ArrayList(Param) = .empty;
        errdefer params.deinit(allocator);

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const p = try this.parseParam(allocator);
            try params.append(allocator, p);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        if (this.match(.rightArrow)) {
            var rt = try this.parseTypeRef(allocator);
            rt.deinit(allocator); // ImplementMethod has no returnType field
        }

        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return ImplementMethod{
            .qualifier = qualifier,
            .name = methodName,
            .params = try params.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        };
    }

    // ── enum decl ─────────────────────────────────────────────────────────────

    fn parseEnumDecl(this: *This, allocator: std.mem.Allocator) ParseError!EnumDecl {
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        _ = try this.consume(.@"enum");
        return this.parseEnumBody(allocator, name, annotations, false);
    }

    fn parseShorthandEnumDecl(this: *This, allocator: std.mem.Allocator) ParseError!EnumDecl {
        const annotations = try this.parseAnnotations(allocator);
        errdefer {
            for (annotations) |*a| a.deinit(allocator);
            allocator.free(annotations);
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.@"enum");
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        return this.parseEnumBody(allocator, name, annotations, isPub);
    }

    fn parseEnumBody(this: *This, allocator: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!EnumDecl {
        const genericParams = try this.parseGenericParams(allocator);
        errdefer allocator.free(genericParams);
        _ = try this.consume(.leftBrace);

        var variants: std.ArrayList(EnumVariant) = .empty;
        errdefer {
            for (variants.items) |*v| v.deinit(allocator);
            variants.deinit(allocator);
        }

        var methods: std.ArrayList(InterfaceMethod) = .empty;
        errdefer {
            for (methods.items) |*m| m.deinit(allocator);
            methods.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            if (this.check(.@"pub") or this.check(.@"fn") or this.check(.declare)) {
                const is_pub = this.match(.@"pub");
                const is_iface = this.match(.declare);
                const method = try this.parseMethodDecl(allocator, is_iface, is_pub);
                try methods.append(allocator, method);
                continue;
            }

            const variantName = (try this.consume(.identifier)).lexeme;

            if (this.check(.leftParenthesis)) {
                _ = this.advance(); // consume '('
                var fields: std.ArrayList(EnumVariantField) = .empty;
                errdefer {
                    for (fields.items) |*f| f.deinit(allocator);
                    fields.deinit(allocator);
                }

                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const fieldName = (try this.consume(.identifier)).lexeme;
                    _ = try this.consume(.colon);
                    var fieldType = try this.parseTypeRef(allocator);
                    errdefer fieldType.deinit(allocator);
                    try fields.append(allocator, .{ .name = fieldName, .typeRef = fieldType });
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);

                // Optional comma after payload variant
                _ = this.match(.comma);
                try variants.append(allocator, .{
                    .name = variantName,
                    .fields = try fields.toOwnedSlice(allocator),
                });
            } else {
                // Optional comma after unit variant
                _ = this.match(.comma);
                try variants.append(allocator, .{ .name = variantName, .fields = &.{} });
            }
        }

        _ = try this.consume(.rightBrace);

        return EnumDecl{
            .name = name,
            .id = this.nextId("enum"),
            .isPub = isPub,
            .annotations = annotations,
            .genericParams = genericParams,
            .variants = try variants.toOwnedSlice(allocator),
            .methods = try methods.toOwnedSlice(allocator),
        };
    }

    // ── case / pattern matching ────────────────────────────────────────────────

    fn parseCaseExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        const caseTok = try this.consume(.case);

        // Subject: `(expr)` strips parens; bare expression otherwise.
        const subjectVal: Expr = if (this.check(.leftParenthesis)) blk: {
            _ = this.advance(); // consume '('
            const e = try this.parseEqExpr(allocator);
            _ = try this.consume(.rightParenthesis);
            break :blk e;
        } else try this.parseEqExpr(allocator);

        const subjectPtr = try allocator.create(Expr);
        subjectPtr.* = subjectVal;
        errdefer {
            subjectPtr.deinit(allocator);
            allocator.destroy(subjectPtr);
        }

        _ = try this.consume(.leftBrace);

        var arms: std.ArrayList(CaseArm) = .empty;
        errdefer {
            for (arms.items) |*a| a.deinit(allocator);
            arms.deinit(allocator);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const pattern = try this.parsePattern(allocator);
            _ = try this.consume(.rightArrow);
            // A `{` starts a block arm body (zero-param lambda with semicolon-separated stmts).
            const body = if (this.check(.leftBrace)) blk: {
                const braceTok = this.advance();
                // Body is already-consumed `{ stmt; ... }` — wrap as zero-param lambda
                var blockStmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (blockStmts.items) |*s| s.deinit(allocator);
                    blockStmts.deinit(allocator);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const e = try this.parseExpr(allocator);
                    _ = try this.consume(.semicolon);
                    try blockStmts.append(allocator, .{ .expr = e });
                }
                _ = try this.consume(.rightBrace);
                var emptyParams: std.ArrayList([]const u8) = .empty;
                break :blk this.mkExpr(.{ .lambda = .{
                    .params = try emptyParams.toOwnedSlice(allocator),
                    .body = try blockStmts.toOwnedSlice(allocator),
                } }, braceTok);
            } else try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try arms.append(allocator, .{ .pattern = pattern, .body = body });
        }

        _ = try this.consume(.rightBrace);

        return this.mkExpr(.{ .case = .{
            .subject = subjectPtr,
            .arms = try arms.toOwnedSlice(allocator),
        } }, caseTok);
    }

    /// Parses a full pattern, including OR chains: `a | b | c`
    fn parsePattern(this: *This, allocator: std.mem.Allocator) ParseError!Pattern {
        const first = try this.parseSimplePattern(allocator);

        if (!this.check(.verticalBar)) return first;

        // OR pattern: collect alternatives
        var alts: std.ArrayList(Pattern) = .empty;
        errdefer {
            for (alts.items) |*p| p.deinit(allocator);
            alts.deinit(allocator);
        }
        try alts.append(allocator, first);
        while (this.match(.verticalBar)) {
            const next = try this.parseSimplePattern(allocator);
            try alts.append(allocator, next);
        }
        return Pattern{ .@"or" = try alts.toOwnedSlice(allocator) };
    }

    /// Parses a single (non-OR) pattern.
    fn parseSimplePattern(this: *This, allocator: std.mem.Allocator) ParseError!Pattern {
        // `else` ---- wildcard
        if (this.check(.@"else")) {
            _ = this.advance();
            return Pattern.wildcard;
        }

        // Number literal: `42`
        if (this.check(.numberLiteral)) {
            return Pattern{ .numberLit = this.advance().lexeme };
        }

        // String literal: `"hello"`
        if (this.check(.stringLiteral)) {
            const tok = this.advance();
            return Pattern{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] };
        }

        // List pattern: `[...]`
        if (this.check(.leftSquareBracket)) {
            return try this.parseListPattern(allocator);
        }

        // identifier: variant name or binding variable
        if (this.check(.identifier)) {
            const name = this.advance().lexeme;

            // Variant with bound fields: `Rgb(r, g, b)`
            if (this.check(.leftParenthesis)) {
                _ = this.advance(); // consume '('
                var bindings: std.ArrayList([]const u8) = .empty;
                errdefer bindings.deinit(allocator);

                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const bind = (try this.consume(.identifier)).lexeme;
                    try bindings.append(allocator, bind);
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);

                return Pattern{ .variantFields = .{
                    .name = name,
                    .bindings = try bindings.toOwnedSlice(allocator),
                } };
            }

            return Pattern{ .ident = name };
        }

        return ParseError.UnexpectedToken;
    }

    /// Parses a list pattern: `[]`, `[1]`, `[4, ..]`, `[_, _]`, `[first, ..rest]`
    fn parseListPattern(this: *This, allocator: std.mem.Allocator) ParseError!Pattern {
        _ = try this.consume(.leftSquareBracket);

        var elems: std.ArrayList(ListPatternElem) = .empty;
        errdefer elems.deinit(allocator);
        var spread: ?[]const u8 = null;

        while (!this.check(.rightSquareBracket) and !this.check(.endOfFile)) {
            // `..` or `..rest`
            if (this.match(.dotDot)) {
                spread = if (this.check(.identifier)) this.advance().lexeme else "";
                break;
            }

            const elem: ListPatternElem =
                if (this.check(.identifier) and std.mem.eql(u8, this.peek().lexeme, "_")) blk: {
                    _ = this.advance();
                    break :blk .wildcard;
                } else if (this.check(.numberLiteral)) blk: {
                    break :blk .{ .numberLit = this.advance().lexeme };
                } else if (this.check(.identifier)) blk: {
                    break :blk .{ .bind = this.advance().lexeme };
                } else {
                    return ParseError.UnexpectedToken;
                };

            try elems.append(allocator, elem);
            if (!this.match(.comma)) break;
        }

        _ = try this.consume(.rightSquareBracket);

        return Pattern{ .list = .{
            .elems = try elems.toOwnedSlice(allocator),
            .spread = spread,
        } };
    }

    // ── param / type name helpers ─────────────────────────────────────────────

    fn consumeParamName(this: *This) ParseError!Token {
        if (this.check(.identifier)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses a plain type name token: `Self`, `type`, or any `identifier`.
    fn consumeTypeName(this: *This) ParseError!Token {
        if (this.check(.selfType)) return this.advance();
        if (this.check(.type)) return this.advance();
        if (this.check(.identifier)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses an optional generic parameter list `<T, R, ...>`.
    /// Returns an empty slice if there is no `<` at the current position.
    fn parseGenericParams(this: *This, allocator: std.mem.Allocator) ParseError![]GenericParam {
        var list: std.ArrayList(GenericParam) = .empty;
        errdefer list.deinit(allocator);

        if (!this.match(.lessThan)) return list.toOwnedSlice(allocator);

        while (!this.check(.greaterThan) and !this.check(.endOfFile)) {
            const name = (try this.consume(.identifier)).lexeme;
            try list.append(allocator, .{ .name = name });
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.greaterThan);
        return list.toOwnedSlice(allocator);
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
    fn parseParam(this: *This, allocator: std.mem.Allocator) ParseError!Param {
        // ── record destructuring: { name, age }: Type ────────────────────────
        if (this.check(.leftBrace)) {
            _ = this.advance(); // consume '{'
            var names: std.ArrayList([]const u8) = .empty;
            errdefer names.deinit(allocator);
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                try names.append(allocator, (try this.consume(.identifier)).lexeme);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightBrace);
            _ = try this.consume(.colon);
            const typeName = (try this.consumeTypeName()).lexeme;
            return Param{
                .name = "",
                .typeName = typeName,
                .destruct = .{ .record_ = try names.toOwnedSlice(allocator) },
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
                    return Param{ .name = varName, .typeName = "", .modifier = .typeinfo };
                }
                const firstType = try this.consumeTypeName();
                var constraints: std.ArrayList([]const u8) = .empty;
                errdefer constraints.deinit(allocator);
                try constraints.append(allocator, firstType.lexeme);
                while (this.match(.verticalBar)) {
                    try constraints.append(allocator, (try this.consumeTypeName()).lexeme);
                }
                return Param{
                    .name = varName,
                    .typeName = firstType.lexeme,
                    .modifier = .typeinfo,
                    .typeinfoConstraints = try constraints.toOwnedSlice(allocator),
                };
            } else {
                // Pre-name comptime: `comptime name : type`
                _ = this.advance(); // consume 'comptime'
                const name = (try this.consumeParamName()).lexeme;
                _ = try this.consume(.colon);
                const typeTok = try this.consumeTypeName();
                return Param{ .name = name, .typeName = typeTok.lexeme, .modifier = .@"comptime" };
            }
        }

        // ── regular param: name ['comptime'] ':' ['syntax'] type_expr ────────
        const name = (try this.consumeParamName()).lexeme;
        // Optional post-name, pre-colon marker.
        const pre_comptime = this.match(.@"comptime");
        _ = try this.consume(.colon);

        // ── fn-type params: `name: fn(...)` or `name comptime: syntax fn(...)` ─
        const post_syntax = this.match(.syntax);
        if (this.check(.@"fn")) {
            _ = this.advance(); // consume 'fn'
            _ = try this.consume(.leftParenthesis);
            var fnParams: std.ArrayList(FnTypeParam) = .empty;
            errdefer fnParams.deinit(allocator);
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                const pname = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                const ptype = (try this.consumeTypeName()).lexeme;
                try fnParams.append(allocator, .{ .name = pname, .typeName = ptype });
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            const retType: ?[]const u8 = if (this.match(.rightArrow))
                (try this.consumeTypeName()).lexeme
            else
                null;
            // post-colon `syntax` marks the fn-type as a syntax param.
            const fnMod: ParamModifier = if (post_syntax) .syntax else .none;
            return Param{
                .name = name,
                .typeName = "fn",
                .modifier = fnMod,
                .fnType = .{
                    .params = try fnParams.toOwnedSlice(allocator),
                    .returnType = retType,
                },
            };
        }

        // ── plain type ────────────────────────────────────────────────────────
        // Post-colon `syntax` overrides; otherwise use pre-colon marker.
        const modifier: ParamModifier = if (post_syntax) .syntax else if (pre_comptime) .@"comptime" else .none;
        const typeTok = try this.consumeTypeName();
        return Param{ .name = name, .typeName = typeTok.lexeme, .modifier = modifier };
    }

    // ── expression parser ──────────────────────────────────────────────────────

    fn parseExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
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
                var valExpr = try this.parseExpr(allocator);
                errdefer valExpr.deinit(allocator);
                const valPtr = try allocator.create(Expr);
                valPtr.* = valExpr;
                return this.mkExpr(.{ .assign = .{ .name = identTok.lexeme, .value = valPtr } }, identTok);
            }
            this.current = saved;
        }

        // throw [new] expr
        if (this.check(.throw)) {
            const throwTok = this.advance();
            _ = this.match(.new); // skip optional `new` keyword
            const inner = try this.parseExpr(allocator);
            const innerPtr = try allocator.create(Expr);
            innerPtr.* = inner;
            return this.mkExpr(.{ .throw_ = innerPtr }, throwTok);
        }

        // try expr [catch handler]
        if (this.check(.@"try")) {
            const tryTok = this.advance();
            const inner = try this.parseExpr(allocator);
            const innerPtr = try allocator.create(Expr);
            innerPtr.* = inner;
            if (this.match(.@"catch")) {
                const handler = try this.parseExpr(allocator);
                const handlerPtr = try allocator.create(Expr);
                handlerPtr.* = handler;
                return this.mkExpr(.{ .tryCatch = .{ .expr = innerPtr, .handler = handlerPtr } }, tryTok);
            }
            return this.mkExpr(.{ .try_ = innerPtr }, tryTok);
        }

        // if (cond) { [binding ->] stmt; } [else { stmt; }]
        // OR: if (cond) expr [else expr]
        if (this.check(.@"if")) {
            const ifTok = this.advance();

            _ = try this.consume(.leftParenthesis);
            const cond = try this.parseEqExpr(allocator);
            errdefer @constCast(&cond).deinit(allocator);
            _ = try this.consume(.rightParenthesis);
            const condPtr = try allocator.create(Expr);
            condPtr.* = cond;

            var binding: ?[]const u8 = null;

            const then_ = if (this.check(.leftBrace)) blk: {
                _ = this.advance(); // consume `{`
                if (this.check(.identifier) and this.peekAt(1).kind == .rightArrow) {
                    binding = this.advance().lexeme;
                    _ = this.advance(); // consume `->`
                }
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer {
                    for (stmts.items) |*s| s.deinit(allocator);
                    stmts.deinit(allocator);
                }
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    const expr = try this.parseExpr(allocator);
                    _ = try this.consume(.semicolon);
                    try stmts.append(allocator, .{ .expr = expr });
                }
                _ = try this.consume(.rightBrace);
                break :blk try stmts.toOwnedSlice(allocator);
            } else blk: {
                const expr = try this.parseExpr(allocator);
                var stmts: std.ArrayList(Stmt) = .empty;
                errdefer stmts.deinit(allocator);
                try stmts.append(allocator, .{ .expr = expr });
                break :blk try stmts.toOwnedSlice(allocator);
            };

            const else_ = if (this.match(.@"else")) blk: {
                break :blk if (this.check(.leftBrace))
                    try this.parseBraceBlock(allocator)
                else blk2: {
                    const expr = try this.parseExpr(allocator);
                    var stmts: std.ArrayList(Stmt) = .empty;
                    errdefer stmts.deinit(allocator);
                    try stmts.append(allocator, .{ .expr = expr });
                    break :blk2 try stmts.toOwnedSlice(allocator);
                };
            } else null;

            return this.mkExpr(.{ .if_ = .{
                .cond = condPtr,
                .binding = binding,
                .then_ = then_,
                .else_ = else_,
            } }, ifTok);
        }

        // return expr
        if (this.check(.@"return")) {
            const retTok = this.advance();
            const inner = try this.parseExpr(allocator);
            const innerPtr = try allocator.create(Expr);
            innerPtr.* = inner;
            return this.mkExpr(.{ .@"return" = innerPtr }, retTok);
        }

        // case expr { arm* }
        if (this.check(.case)) {
            return try this.parseCaseExpr(allocator);
        }

        // comptime expr  /  comptime { expr; ... }
        if (this.check(.@"comptime")) {
            const comptimeTok = this.advance();
            if (this.check(.leftBrace)) {
                const body = try this.parseBraceBlock(allocator);
                return this.mkExpr(.{ .comptimeBlock = .{ .body = body } }, comptimeTok);
            } else {
                var inner = try this.parseEqExpr(allocator);
                errdefer inner.deinit(allocator);
                const innerPtr = try allocator.create(Expr);
                innerPtr.* = inner;
                return this.mkExpr(.{ .@"comptime" = innerPtr }, comptimeTok);
            }
        }

        // break [expr]
        if (this.check(.@"break")) {
            const breakTok = this.advance();
            // break with no expression (e.g. bare `break` inside a loop)
            const isEnd = this.check(.rightBrace) or this.check(.endOfFile) or this.check(.newLine);
            if (isEnd) {
                return this.mkExpr(.{ .@"break" = null }, breakTok);
            }
            var inner = try this.parseEqExpr(allocator);
            errdefer inner.deinit(allocator);
            const innerPtr = try allocator.create(Expr);
            innerPtr.* = inner;
            return this.mkExpr(.{ .@"break" = innerPtr }, breakTok);
        }

        // yield expr
        if (this.check(.yield)) {
            const yieldTok = this.advance();
            var inner = try this.parseEqExpr(allocator);
            errdefer inner.deinit(allocator);
            const innerPtr = try allocator.create(Expr);
            innerPtr.* = inner;
            return this.mkExpr(.{ .yield = innerPtr }, yieldTok);
        }

        // continue
        if (this.check(.@"continue")) {
            const contTok = this.advance();
            return this.mkExpr(.{ .@"continue" = {} }, contTok);
        }

        // loop (iter) { params -> body }  /  loop (iter, 0..) { item, i -> body }
        if (this.check(.loop)) {
            return try this.parseLoopExpr(allocator);
        }

        // #(e1, e2, ...) ---- tuple literal
        if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
            const tupleTok = this.advance(); // consume '#'
            _ = this.advance(); // consume '('
            var elems: std.ArrayList(Expr) = .empty;
            errdefer {
                for (elems.items) |*e| e.deinit(allocator);
                elems.deinit(allocator);
            }
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                try elems.append(allocator, try this.parseEqExpr(allocator));
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
            return this.mkExpr(.{ .tupleLit = try elems.toOwnedSlice(allocator) }, tupleTok);
        }

        // val name = expr / var name = expr  (local binding)
        // val { name } = expr  (record destructuring)
        // val/var binding
        if (this.check(.val) or this.check(.@"var")) {
            const mutable = this.peek().kind == .@"var";
            const bindTok = this.advance(); // consume 'val' or 'var'

            // Record destructuring: val { name, age } = expr
            if (this.check(.leftBrace)) {
                _ = this.advance(); // consume '{'
                var names: std.ArrayList([]const u8) = .empty;
                errdefer names.deinit(allocator);
                while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                    try names.append(allocator, (try this.consume(.identifier)).lexeme);
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightBrace);
                _ = try this.consume(.equal);
                var valExpr = try this.parseExpr(allocator);
                errdefer valExpr.deinit(allocator);
                const valPtr = try allocator.create(Expr);
                valPtr.* = valExpr;
                const namesSlice = try names.toOwnedSlice(allocator);
                return this.mkExpr(.{ .localBindDestruct = .{
                    .pattern = .{ .record_ = namesSlice },
                    .value = valPtr,
                    .mutable = mutable,
                } }, bindTok);
            }

            // Tuple destructuring: val #(a, b) = expr
            if (this.check(.hash) and this.peekAt(1).kind == .leftParenthesis) {
                _ = this.advance(); // consume '#'
                _ = this.advance(); // consume '('
                var names: std.ArrayList([]const u8) = .empty;
                errdefer names.deinit(allocator);
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    try names.append(allocator, (try this.consume(.identifier)).lexeme);
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
                _ = try this.consume(.equal);
                var valExpr = try this.parseExpr(allocator);
                errdefer valExpr.deinit(allocator);
                const valPtr = try allocator.create(Expr);
                valPtr.* = valExpr;
                const namesSlice = try names.toOwnedSlice(allocator);
                return this.mkExpr(.{ .localBindDestruct = .{
                    .pattern = .{ .tuple_ = namesSlice },
                    .value = valPtr,
                    .mutable = mutable,
                } }, bindTok);
            }

            // Plain binding: val name [: TypeRef] = expr
            const name = (try this.consume(.identifier)).lexeme;
            // Optional type annotation: `: TypeRef`
            if (this.match(.colon)) {
                var typeRef = try this.parseTypeRef(allocator);
                typeRef.deinit(allocator); // discard — type inference handles it
            }
            _ = try this.consume(.equal);
            var valExpr = try this.parseExpr(allocator);
            errdefer valExpr.deinit(allocator);
            const valPtr = try allocator.create(Expr);
            valPtr.* = valExpr;
            return this.mkExpr(.{ .localBind = .{ .name = name, .value = valPtr, .mutable = mutable } }, bindTok);
        }

        // receiver.field = expr   ou   receiver.field += expr
        if (this.check(.identifier)) {
            const saved = this.current;
            const first = this.advance();

            if (this.check(.dot)) {
                _ = this.advance();
                const fieldTok = try this.consume(.identifier);

                if (this.match(.equal)) {
                    const valExpr = try this.parseEqExpr(allocator);
                    const valPtr = try allocator.create(Expr);
                    valPtr.* = valExpr;
                    const recvPtr = try allocator.create(Expr);
                    recvPtr.* = this.mkExpr(.{ .ident = first.lexeme }, first);
                    return this.mkExpr(.{ .fieldAssign = .{ .receiver = recvPtr, .field = fieldTok.lexeme, .value = valPtr } }, first);
                }

                if (this.match(.plusEqual)) {
                    const valExpr = try this.parseEqExpr(allocator);
                    const valPtr = try allocator.create(Expr);
                    valPtr.* = valExpr;
                    const recvPtr = try allocator.create(Expr);
                    recvPtr.* = this.mkExpr(.{ .ident = first.lexeme }, first);
                    return this.mkExpr(.{ .fieldPlusEq = .{ .receiver = recvPtr, .field = fieldTok.lexeme, .value = valPtr } }, first);
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
                const methodTok = try this.consume(.identifier);

                var args: []CallArg = &.{};
                if (this.check(.leftParenthesis)) {
                    args = try this.parseCallArgs(allocator);
                }
                errdefer {
                    for (args) |*a| a.deinit(allocator);
                    allocator.free(args);
                }

                const trailing = if (this.noTrailingLambda) try allocator.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(allocator);
                errdefer {
                    for (trailing) |*t| t.deinit(allocator);
                    allocator.free(trailing);
                }

                if (args.len > 0 or trailing.len > 0) {
                    return this.mkExpr(.{ .call = .{
                        .receiver = firstTok.lexeme,
                        .callee = methodTok.lexeme,
                        .args = args,
                        .trailing = trailing,
                    } }, firstTok);
                }

                // No args or trailing lambdas.
                // Fall back so parsePrimary handles field access: self.field or Color.Red
                this.current = saved;
            }

            // Plain call: ident(args...) trailing...
            else if (this.check(.leftParenthesis)) {
                const args = try this.parseCallArgs(allocator);
                errdefer {
                    for (args) |*a| a.deinit(allocator);
                    allocator.free(args);
                }
                const trailing = if (this.noTrailingLambda) try allocator.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(allocator);
                errdefer {
                    for (trailing) |*t| t.deinit(allocator);
                    allocator.free(trailing);
                }
                return this.mkExpr(.{ .call = .{
                    .receiver = null,
                    .callee = firstTok.lexeme,
                    .args = args,
                    .trailing = trailing,
                } }, firstTok);
            }

            // Call with only trailing lambdas: ident { ... } label: { ... }
            // (only when not in noTrailingLambda mode)
            else if (!this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda())) {
                const trailing = try this.parseTrailingLambdas(allocator);
                errdefer {
                    for (trailing) |*t| t.deinit(allocator);
                    allocator.free(trailing);
                }
                if (trailing.len > 0) {
                    return this.mkExpr(.{ .call = .{
                        .receiver = null,
                        .callee = firstTok.lexeme,
                        .args = &.{},
                        .trailing = trailing,
                    } }, firstTok);
                }
                for (trailing) |*t| t.deinit(allocator);
                allocator.free(trailing);
                this.current = saved;
            } else {
                this.current = saved;
            }
        }

        return this.parseEqExpr(allocator);
    }

    fn parseEqExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseCompareExpr(allocator);

        while (this.match(.equalEqual) or this.match(.notEqual)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseCompareExpr(allocator);
            const lhsPtr = try allocator.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try allocator.create(Expr);
            rhsPtr.* = rhs;
            const kind: ExprKind = if (opTok.kind == .equalEqual)
                .{ .eq = .{ .lhs = lhsPtr, .rhs = rhsPtr } }
            else
                .{ .ne = .{ .lhs = lhsPtr, .rhs = rhsPtr } };
            lhs = this.mkExpr(kind, opTok);
        }

        return lhs;
    }

    fn parseCompareExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseAddExpr(allocator);

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
            const rhs = try this.parseAddExpr(allocator);
            const lhsPtr = try allocator.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try allocator.create(Expr);
            rhsPtr.* = rhs;
            const kind: ExprKind = switch (opTok.kind) {
                .lessThan => .{ .lt = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .greaterThan => .{ .gt = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .lessThanEqual => .{ .lte = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .greaterThanEqual => .{ .gte = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                else => unreachable,
            };
            lhs = this.mkExpr(kind, opTok);
        }

        return lhs;
    }

    fn parseAddExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parseMulExpr(allocator);

        while (this.match(.plus) or this.match(.minus)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parseMulExpr(allocator);
            const lhsPtr = try allocator.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try allocator.create(Expr);
            rhsPtr.* = rhs;
            const kind: ExprKind = if (opTok.kind == .plus)
                .{ .add = .{ .lhs = lhsPtr, .rhs = rhsPtr } }
            else
                .{ .sub = .{ .lhs = lhsPtr, .rhs = rhsPtr } };
            lhs = this.mkExpr(kind, opTok);
        }

        return lhs;
    }

    fn parseMulExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        var lhs = try this.parsePrimary(allocator);

        while (this.match(.star) or this.match(.slash) or this.match(.percent)) {
            const opTok = this.tokens[this.current - 1];
            const rhs = try this.parsePrimary(allocator);
            const lhsPtr = try allocator.create(Expr);
            lhsPtr.* = lhs;
            const rhsPtr = try allocator.create(Expr);
            rhsPtr.* = rhs;
            const kind: ExprKind = switch (opTok.kind) {
                .star => .{ .mul = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .slash => .{ .div = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                .percent => .{ .mod = .{ .lhs = lhsPtr, .rhs = rhsPtr } },
                else => unreachable,
            };
            lhs = this.mkExpr(kind, opTok);
        }

        return lhs;
    }

    fn parsePrimary(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        // @name(args...) ---- built-in function call
        if (this.check(.builtinIdent)) {
            const nameTok = this.advance();
            const args = try this.parseCallArgs(allocator);
            errdefer {
                for (args) |*a| a.deinit(allocator);
                allocator.free(args);
            }
            return this.mkExpr(.{ .builtinCall = .{ .name = nameTok.lexeme, .args = args } }, nameTok);
        }

        if (this.check(.stringLiteral)) {
            const tok = this.advance();
            return this.mkExpr(.{ .stringLit = tok.lexeme[1 .. tok.lexeme.len - 1] }, tok);
        }

        if (this.check(.numberLiteral)) {
            const tok = this.advance();
            return this.mkExpr(.{ .numberLit = tok.lexeme }, tok);
        }

        if (this.check(.selfType)) {
            const tok = this.advance();
            return this.mkExpr(.{ .ident = "Self" }, tok);
        }

        if (this.check(.todo)) {
            const tok = this.advance();
            return this.mkExpr(.todo, tok);
        }

        if (this.check(.null)) {
            const tok = this.advance();
            return this.mkExpr(.null_, tok);
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
            if (this.check(.dot)) {
                _ = this.advance();
                const field = (try this.consume(.identifier)).lexeme;
                const recvPtr = try allocator.create(Expr);
                recvPtr.* = this.mkExpr(.{ .ident = tok.lexeme }, tok);
                return this.mkExpr(.{ .identAccess = .{
                    .receiver = recvPtr,
                    .member = field,
                } }, tok);
            }
            return this.mkExpr(.{ .ident = tok.lexeme }, tok);
        }

        // Dot-shorthand variant: `.Red` ---- type resolved from context.
        if (this.check(.dot)) {
            const dotTok = this.advance();
            const memberTok = try this.consume(.identifier);
            return this.mkExpr(.{ .dotIdent = memberTok.lexeme }, dotTok);
        }

        // [e1, e2, ...] ---- array literal
        if (this.check(.leftSquareBracket)) {
            const bracketTok = this.advance();
            var elems: std.ArrayList(Expr) = .empty;
            errdefer {
                for (elems.items) |*e| e.deinit(allocator);
                elems.deinit(allocator);
            }
            while (!this.check(.rightSquareBracket) and !this.check(.endOfFile)) {
                try elems.append(allocator, try this.parseEqExpr(allocator));
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightSquareBracket);
            return this.mkExpr(.{ .arrayLit = try elems.toOwnedSlice(allocator) }, bracketTok);
        }

        return ParseError.UnexpectedToken;
    }

    // ── lambda / call helpers ─────────────────────────────────────────────────

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
    fn parseLambdaBody(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        const startTok = this.peek();
        // Detect and parse optional parameter list
        var paramList: std.ArrayList([]const u8) = .empty;
        errdefer paramList.deinit(allocator);

        if (this.hasLambdaParams()) {
            // Consume: ident (, ident)* ->
            try paramList.append(allocator, (try this.consume(.identifier)).lexeme);
            while (this.match(.comma)) {
                try paramList.append(allocator, (try this.consume(.identifier)).lexeme);
            }
            _ = try this.consume(.rightArrow);
        }

        // Parse body statements
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const expr = try this.parseExpr(allocator);
            try stmts.append(allocator, .{ .expr = expr });
        }
        _ = try this.consume(.rightBrace);

        return this.mkExpr(.{ .lambda = .{
            .params = try paramList.toOwnedSlice(allocator),
            .body = try stmts.toOwnedSlice(allocator),
        } }, startTok);
    }

    fn parseCallArgs(this: *This, allocator: std.mem.Allocator) ParseError![]CallArg {
        _ = try this.consume(.leftParenthesis);
        var args: std.ArrayList(CallArg) = .empty;
        errdefer {
            for (args.items) |*a| a.deinit(allocator);
            args.deinit(allocator);
        }

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
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

            const valExpr = try this.parseExpr(allocator);
            const valPtr = try allocator.create(Expr);
            valPtr.* = valExpr;
            try args.append(allocator, .{ .label = label, .value = valPtr });

            if (!this.match(.comma)) break;
        }

        _ = try this.consume(.rightParenthesis);
        return args.toOwnedSlice(allocator);
    }

    /// Parses zero or more trailing lambda blocks:
    ///   `{ params? -> body }`  or  `label: { params? -> body }`
    fn parseTrailingLambdas(this: *This, allocator: std.mem.Allocator) ParseError![]TrailingLambda {
        var lambdas: std.ArrayList(TrailingLambda) = .empty;
        errdefer {
            for (lambdas.items) |*t| t.deinit(allocator);
            lambdas.deinit(allocator);
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
            errdefer paramList.deinit(allocator);

            if (this.hasLambdaParams()) {
                try paramList.append(allocator, (try this.consume(.identifier)).lexeme);
                while (this.match(.comma)) {
                    try paramList.append(allocator, (try this.consume(.identifier)).lexeme);
                }
                _ = try this.consume(.rightArrow);
            }

            // Parse body statements
            var stmts: std.ArrayList(Stmt) = .empty;
            errdefer {
                for (stmts.items) |*s| s.deinit(allocator);
                stmts.deinit(allocator);
            }
            while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
                const expr = try this.parseExpr(allocator);
                _ = try this.consume(.semicolon);
                try stmts.append(allocator, .{ .expr = expr });
            }
            _ = try this.consume(.rightBrace);

            try lambdas.append(allocator, .{
                .label = label,
                .params = try paramList.toOwnedSlice(allocator),
                .body = try stmts.toOwnedSlice(allocator),
            });
        }

        return lambdas.toOwnedSlice(allocator);
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
    fn parseLoopExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        const loopTok = this.advance(); // consume 'loop'
        _ = try this.consume(.leftParenthesis);

        // Parse primary iterator expression (may be a range or identifier)
        const iterExpr = try this.parseRangeExpr(allocator);
        const iterPtr = try allocator.create(Expr);
        iterPtr.* = iterExpr;

        // Optional index range: `loop (iter, 0..)`
        var indexPtr: ?*Expr = null;
        if (this.match(.comma)) {
            const idxExpr = try this.parseRangeExpr(allocator);
            indexPtr = try allocator.create(Expr);
            indexPtr.?.* = idxExpr;
        }

        _ = try this.consume(.rightParenthesis);
        _ = try this.consume(.leftBrace);

        // Parse parameter list: `param1, param2, ...  ->`
        var params: std.ArrayList([]const u8) = .empty;
        errdefer params.deinit(allocator);
        while (this.check(.identifier)) {
            try params.append(allocator, this.advance().lexeme);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightArrow);

        // Body is already-consumed `{ stmt; ... }`
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(allocator);
            stmts.deinit(allocator);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const e = try this.parseExpr(allocator);
            _ = try this.consume(.semicolon);
            try stmts.append(allocator, .{ .expr = e });
        }
        _ = try this.consume(.rightBrace);
        const body = try stmts.toOwnedSlice(allocator);

        return this.mkExpr(.{ .loop = .{
            .iter = iterPtr,
            .indexRange = indexPtr,
            .params = try params.toOwnedSlice(allocator),
            .body = body,
        } }, loopTok);
    }

    /// Parses a range expression `expr..` or `expr..expr`, or falls back to
    /// a plain `parseEqExpr` if `..` is not present.
    fn parseRangeExpr(this: *This, allocator: std.mem.Allocator) ParseError!Expr {
        var start = try this.parseEqExpr(allocator);
        errdefer start.deinit(allocator);
        if (!this.check(.dotDot)) return start;
        const dotTok = this.advance(); // consume '..'
        const startPtr = try allocator.create(Expr);
        startPtr.* = start;
        // Optional end: `0..10` vs `0..`
        const hasEnd = !this.check(.rightParenthesis) and !this.check(.comma) and
            !this.check(.endOfFile);
        if (hasEnd) {
            var end = try this.parseEqExpr(allocator);
            errdefer end.deinit(allocator);
            const endPtr = try allocator.create(Expr);
            endPtr.* = end;
            return this.mkExpr(.{ .range = .{ .start = startPtr, .end = endPtr } }, dotTok);
        }
        return this.mkExpr(.{ .range = .{ .start = startPtr, .end = null } }, dotTok);
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
