const std = @import("std");
const token = @import("./lexer/token.zig");
const ast = @import("ast.zig");
const lexer = @import("lexer.zig");

// Sub-grammar implementations split out of this file. Each module holds free
// functions on `*Parser`; the `Parser` struct below re-exports them as thin
// aliases so `this.parseX()` keeps resolving at every call site.
const types = @import("parser/types.zig");
const patterns = @import("parser/patterns.zig");
const decl_grammar = @import("parser/decls.zig");
const exprs = @import("parser/exprs.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

pub const ImportDecl = ast.ImportDecl;
pub const ImportSource = ast.ImportSource;
pub const ImportPath = ast.ImportPath;
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
pub const JumpExpr = ast.JumpExpr;
pub const BranchExpr = ast.BranchExpr;
pub const LoopExpr = ast.LoopExprOf(.untyped);
pub const FunctionExpr = ast.FunctionExpr;
pub const Loc = ast.Loc;
pub const RecordDecl = ast.RecordDecl;
pub const RecordField = ast.RecordField;
pub const ImplementDecl = ast.ImplementDecl;
pub const ExtendDecl = ast.ExtendDecl;
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
    /// Removed error union syntax `T!E` (use `@Result<D, E>` instead)
    removedErrorUnion,
    /// Removed builtin type syntax `@Result(D, E)` (use `@Result<D, E>` instead)
    removedBuiltinType,
    /// `use` hook after branch/return (must be in static prefix)
    useAfterBranch,
    /// Malformed `${…}` string interpolation (unterminated or invalid expression)
    badInterpolation,
    /// Meta-kind parameter (`type` / `expr T`) without the `comptime` modifier
    metaKindRequiresComptime,
    /// Anonymous `implement`/`extend` block (the name is required)
    anonymousImplExtend,
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
    /// One `>` still owed to an enclosing generic-argument list: nested
    /// generics close with `>>`, which the lexer scans as a single shift
    /// token (`Array<Array<T>>`). `consumeGenericClose` consumes the `>>`
    /// for the inner list and credits the second `>` here for the outer one.
    pending_gt: bool = false,
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

    /// True when the current position closes a generic-argument list:
    /// a plain `>`, a `>>` (nested close, lexed as one shift token), or a
    /// `>` still owed from a previously split `>>`.
    pub fn checkGenericClose(this: *This) bool {
        return this.pending_gt or this.check(.greaterThan) or this.check(.greaterThanGreaterThan);
    }

    /// Consume the close of a generic-argument list, splitting `>>` so
    /// `Array<Array<T>>` parses (the second `>` is credited to the
    /// enclosing list via `pending_gt`).
    pub fn consumeGenericClose(this: *This) ParseError!void {
        if (this.pending_gt) {
            this.pending_gt = false;
            return;
        }
        if (this.check(.greaterThanGreaterThan)) {
            _ = this.advance();
            this.pending_gt = true;
            return;
        }
        _ = try this.consume(.greaterThan);
    }

    /// Returns the next ID counter for a declaration type.
    /// The caller stores this as a u32; formatting happens in the formatter.
    pub fn nextId(this: *This, comptime kind: []const u8) u32 {
        const counter = &@field(this.id_counters, kind);
        counter.* += 1;
        return counter.*;
    }

    /// Consumes an optional `@type_NNNN` ID token after the declaration name.
    /// Always returns 0 when absent (IDs are parser-generated on first parse).
    pub fn tryParseId(this: *This) u32 {
        if (this.check(.at)) {
            _ = this.advance(); // skip @
            if (this.check(.identifier)) {
                _ = this.advance(); // skip type_NNNN token
            }
        }
        return 0;
    }

    /// Creates a Loc from a Token's line and column.
    pub fn locFromToken(tok: Token) Loc {
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
            const decl: DeclKind = if (this.check(.import)) blk: {
                const d = try this.parseImportDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.check(.mod) or
                (this.check(.@"pub") and this.peekAt(1).kind == .mod) or
                this.checkDefaultMod())
            blk: {
                const d = try this.parseModDecl();
                break :blk .{ .mod = d };
            } else if (this.isActivationStmt()) blk: {
                const d = try this.parseActivationStmt(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .use = d };
            } else if (this.checkShorthand(.@"fn") or this.checkStarFn() or this.checkDefaultFn()) blk: {
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
            } else if (this.checkNamedDecl(.implement)) blk: {
                const d = try this.parseShorthandImplementDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .implement = d };
            } else if (this.checkNamedDecl(.extend)) blk: {
                const d = try this.parseShorthandExtendDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .extend = d };
            } else if (this.check(.@"test")) blk: {
                const d = try this.parseTestDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .@"test" = d };
            } else if (this.check(.loop)) blk: {
                // top-level loop statement: parsed as a val named "_loop"
                const e = try this.parseLoopExpr(alloc);
                const ePtr = try this.boxExpr(alloc, .{ .loop = e });
                _ = this.match(.semicolon);
                break :blk DeclKind{ .val = ast.ValDecl{ .name = "_loop", .value = ePtr } };
            } else if (this.checkShorthand(.val)) blk: {
                const decl = try this.parseValForm(alloc);
                // Optional semicolon after top-level val declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.hash) or
                (this.check(.at) and this.peekAt(1).kind == .leftSquareBracket))
            blk: {
                // Annotations precede the declaration — peek past them to find the keyword.
                const annEnd = this.skipAnnotationsLookaheadFrom(0);
                const tok = this.peekAt(annEnd).kind;
                const isPub = tok == .@"pub";
                const eff = if (isPub) this.peekAt(annEnd + 1).kind else tok;
                const decl: DeclKind = switch (eff) {
                    .@"fn", .star => DeclKind{ .@"fn" = try this.parseFnDecl(alloc) },
                    .@"struct" => DeclKind{ .@"struct" = try this.parseShorthandStructDecl(alloc) },
                    .@"enum" => DeclKind{ .@"enum" = try this.parseShorthandEnumDecl(alloc) },
                    .record => DeclKind{ .record = try this.parseShorthandRecordDecl(alloc) },
                    .interface => DeclKind{ .interface = try this.parseShorthandInterfaceDecl(alloc) },
                    // An ANNOTATED `declare fn` is the FFI declaration form
                    // (`@[external(…)] pub declare fn …;`), not a delegate.
                    .declare => DeclKind{ .@"fn" = try this.parseFnDecl(alloc) },
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
                // A bare `implement …` / `extend …` (optionally `pub`) with no name:
                // these declarations are always named, so reject with a clear error.
                if (this.check(.implement) or this.check(.extend) or
                    (this.check(.@"pub") and (this.peekAt(1).kind == .implement or this.peekAt(1).kind == .extend)))
                {
                    this.reportAnonImplExtendError();
                    return ParseError.UnexpectedToken;
                }
                if (isReservedWord(this.peek().kind)) {
                    this.reportReservedWordError();
                }
                return ParseError.UnexpectedToken;
            };
            try decls.append(alloc, decl);
        }
        return Program{ .decls = try decls.toOwnedSlice(alloc) };
    }

    /// Parses a top-level `mod Name;` / `pub mod Name;` module declaration.
    /// `mod` is a keyword: inside a fn body statement parsing never reaches here,
    /// so a stray `mod` there surfaces as a normal unexpected-token error.
    pub fn parseModDecl(this: *This) ParseError!ast.ModDecl {
        const isPub = this.match(.@"pub");
        // `pub default mod Name;` — the package's DEFAULT module (the `import <pkg>`
        // surface). Declarable at any module top level; uniqueness is validated
        // later (inference), not by the parser.
        const isDefault = this.match(.default);
        _ = try this.consume(.mod);
        const nameTok = try this.consume(.identifier);
        _ = try this.consume(.semicolon);
        return .{ .name = nameTok.lexeme, .isPub = isPub, .isDefault = isDefault };
    }

    /// Dispatches `val [pub] Name = <kind> ...` to the appropriate sub-parser.
    /// Uses pure lookahead ---- no state mutation.
    pub fn parseValForm(this: *This, alloc: std.mem.Allocator) ParseError!DeclKind {
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
            .extend => .{ .extend = try this.parseExtendDecl(alloc) },
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
    pub inline fn checkShorthand(this: *This, kind: TokenKind) bool {
        return this.check(kind) or (this.check(.@"pub") and this.peekAt(1).kind == kind);
    }

    /// true for a named shorthand decl `Name <kind> …` or `pub Name <kind> …`,
    /// used to detect `Name implement …` / `Name extend …`.
    pub inline fn checkNamedDecl(this: *This, kind: TokenKind) bool {
        if (this.check(.identifier)) return this.peekAt(1).kind == kind;
        if (this.check(.@"pub")) return this.peekAt(1).kind == .identifier and this.peekAt(2).kind == kind;
        return false;
    }

    /// true if a `*fn` (async/generator) declaration is next: `*fn` or `pub *fn`.
    pub inline fn checkStarFn(this: *This) bool {
        if (this.check(.star)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .star and this.peekAt(2).kind == .@"fn";
        return false;
    }
    /// `default fn` / `pub default fn` at a module's top level — the package DSL
    /// handler (`root.bp`). Distinct from a `default fn` inside an `interface`.
    pub inline fn checkDefaultFn(this: *This) bool {
        if (this.check(.default)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .default and this.peekAt(2).kind == .@"fn";
        return false;
    }

    /// `default mod Name;` / `pub default mod Name;` at a module's top level — the
    /// package's DEFAULT module (the `import <pkg>` surface). Mirrors
    /// `checkDefaultFn`; declarable at any module top level (no root-only rule).
    pub inline fn checkDefaultMod(this: *This) bool {
        if (this.check(.default)) return this.peekAt(1).kind == .mod;
        if (this.check(.@"pub")) return this.peekAt(1).kind == .default and this.peekAt(2).kind == .mod;
        return false;
    }

    /// true if a shorthand delegate (`declare fn` or `pub declare fn`) is next.
    pub inline fn checkShorthandDelegate(this: *This) bool {
        if (this.check(.declare)) return this.peekAt(1).kind == .@"fn";
        if (this.check(.@"pub")) return this.peekAt(1).kind == .declare and this.peekAt(2).kind == .@"fn";
        return false;
    }

    /// Returns the lookahead offset of the token that follows `[pub] val Name =`.
    /// Does not consume any tokens.
    pub inline fn valBodyOffset(this: *This) usize {
        var offset: usize = 0;
        if (this.peekAt(offset).kind == .@"pub") offset += 1; // optional pub
        offset += 1; // val
        offset += 1; // Name
        offset += 1; // =
        return offset;
    }

    // ── block parsing ──────────────────────────────────────────────────────

    /// How a `{ ... }` block enforces statement-terminating semicolons.
    const SemicolonPolicy = enum {
        /// Every statement must end with `;`.
        required,
        /// `;` is consumed if present but never required.
        optional,
        /// `;` required except for the last statement before `}`.
        requiredExceptLast,
    };

    /// Knobs controlling the single `parseBlock` implementation. All fields are
    /// comptime-known per call so unused branches are pruned.
    const BlockParseOptions = struct {
        /// Record `emptyLinesBefore` on each statement (formatter fidelity).
        trackEmptyLines: bool = false,
        /// Preserve `//`/`///`/`////` comment tokens as comment-literal statements.
        handleComments: bool = false,
        semicolonPolicy: SemicolonPolicy = .required,
        /// Reject a `use` hook that appears after a branch/return (static-prefix rule).
        useAfterBranchGuard: bool = false,
    };

    /// Parse `{ stmt; stmt; ... }`. The opening `{` must be the current token.
    /// Unifies every brace-delimited block in the parser via `BlockParseOptions`.
    pub fn parseBlock(this: *This, alloc: std.mem.Allocator, comptime opts: BlockParseOptions) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        var seenBranch = false;
        _ = &seenBranch; // used only when useAfterBranchGuard is set
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const emptyLinesBefore: u32 = if (opts.trackEmptyLines) blk: {
                const prevLine = if (this.current > 0) this.tokens[this.current - 1].line else 1;
                const currLine = this.peek().line;
                break :blk if (currLine > prevLine + 1) @intCast(currLine - prevLine - 1) else 0;
            } else 0;

            if (opts.handleComments and try this.tryParseCommentStmt(alloc, &stmts, emptyLinesBefore)) continue;

            if (opts.useAfterBranchGuard) {
                if (seenBranch and this.check(.use)) {
                    const tok = this.peek();
                    this.parseError = .{
                        .kind = .useAfterBranch,
                        .start = tok.col - 1,
                        .end = tok.col - 1 + tok.lexeme.len,
                        .lexeme = tok.lexeme,
                        .line = tok.line,
                        .col = tok.col,
                    };
                    return ParseError.UnexpectedToken;
                }
                if (this.check(.@"if") or this.check(.@"return") or this.check(.loop) or this.check(.case))
                    seenBranch = true;
            }

            const expr = try this.parseExpr(alloc);
            switch (opts.semicolonPolicy) {
                .required => _ = try this.consume(.semicolon),
                .optional => _ = this.match(.semicolon),
                .requiredExceptLast => if (!this.match(.semicolon) and !this.check(.rightBrace))
                    return ParseError.UnexpectedToken,
            }
            try stmts.append(alloc, .{ .expr = expr, .emptyLinesBefore = emptyLinesBefore });
        }
        _ = try this.consume(.rightBrace);
        return stmts.toOwnedSlice(alloc);
    }

    /// Parse `{ expr; expr; ... }` — a brace-delimited block of semicolon-separated expressions.
    /// The opening `{` must already be the current token.
    pub fn parseStmtListInBraces(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{
            .trackEmptyLines = true,
            .handleComments = true,
            .semicolonPolicy = .requiredExceptLast,
            .useAfterBranchGuard = true,
        });
    }

    /// Parse either `{ expr; ... }` or a single `expr`.
    /// Used by `if`, `catch`, and any place that accepts a block or bare expression.
    /// Does NOT require semicolon after the bare expression.
    pub fn parseBlockOrExpr(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
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
    pub fn parseBlockWithOptionalTrailingSemicolon(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{ .semicolonPolicy = .optional });
    }

    // ── shared body / param helpers ───────────────────────────────────────────

    /// Parses `{ stmt; ... }` preserving comment nodes as literal expressions.
    /// Used in fn/method bodies where source comments must be kept.
    pub fn parseMethodBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{ .handleComments = true });
    }

    /// Parses `{ stmt; ... }` without special comment handling.
    /// Used in implement methods, getters, setters, and interface default bodies.
    pub fn parseSimpleBodyStmts(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{});
    }

    pub const parseParamList = decl_grammar.parseParamList;

    /// Skips zero or more `#[name(args...)]` / `@[call, call]` annotation blocks
    /// from `offset` and returns the position of the first non-annotation token.
    /// Pure lookahead.
    pub fn skipAnnotationsLookaheadFrom(this: *This, offset: usize) usize {
        var o = offset;
        while ((this.peekAt(o).kind == .hash or this.peekAt(o).kind == .at) and
            this.peekAt(o + 1).kind == .leftSquareBracket)
        {
            o += 2; // skip `#`/`@` and `[`
            var depth: usize = 1;
            while (depth > 0 and this.peekAt(o).kind != .endOfFile) {
                switch (this.peekAt(o).kind) {
                    .leftSquareBracket => depth += 1,
                    .rightSquareBracket => depth -= 1,
                    else => {},
                }
                o += 1;
            }
        }
        return o;
    }

    /// Parses zero or more annotation blocks at the current position.
    ///
    /// Primary form (new): `#[@builtin(arg, arg), custom()]`
    ///   - `@name` prefix marks a compiler-known (builtin) attribute;
    ///   - plain `name` is a user-defined attribute;
    ///   - comma-separated list of any mix.
    ///
    /// Legacy form (kept for migration): `@[name(…), name(…)]`
    ///   - all annotations inside are treated as builtin (`is_builtin = true`).
    ///
    /// Returns an owned slice (empty when no annotations are present).
    pub fn parseAnnotations(this: *This, alloc: std.mem.Allocator) ParseError![]Annotation {
        var list: std.ArrayList(Annotation) = .empty;
        errdefer {
            for (list.items) |*ann| ann.deinit(alloc);
            list.deinit(alloc);
        }
        while ((this.check(.hash) or this.check(.at)) and this.peekAt(1).kind == .leftSquareBracket) {
            const isLegacyAtBlock = this.check(.at);
            _ = this.advance(); // `#` or `@`
            _ = try this.consume(.leftSquareBracket);
            while (true) {
                var ann = try this.parseAnnotationCall(alloc);
                // In the legacy `@[…]` form every annotation is implicitly builtin.
                if (isLegacyAtBlock) ann.is_builtin = true;
                try list.append(alloc, ann);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightSquareBracket);
        }
        return list.toOwnedSlice(alloc);
    }

    /// Parses a single annotation call.
    ///
    /// Forms:
    ///   `@name(arg, arg)` — builtin attribute (`is_builtin = true`)
    ///   `name(arg, arg)`  — custom/user attribute (`is_builtin = false`)
    fn parseAnnotationCall(this: *This, alloc: std.mem.Allocator) ParseError!Annotation {
        // `@name(…)` is lexed as a single `.builtinIdent` token (e.g. `"@external"`).
        // Strip the leading `@` to get the bare name; mark as builtin.
        var is_builtin = false;
        const name: []const u8 = blk: {
            if (this.check(.builtinIdent)) {
                is_builtin = true;
                break :blk this.advance().lexeme[1..]; // "@external" → "external"
            }
            // Accept any word (identifier or reserved word) as a custom attribute name.
            const nameTok = this.peek();
            if (nameTok.kind != .identifier and !isReservedWord(nameTok.kind)) return ParseError.UnexpectedToken;
            break :blk this.advance().lexeme;
        };

        var args: std.ArrayList([]const u8) = .empty;
        errdefer args.deinit(alloc);
        if (this.match(.leftParenthesis)) {
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                // Labeled argument (`runtime:`, `module:`, `method:`) — the label is
                // cosmetic; the value is kept positionally so Form A `@external(t, m, s)`
                // and Form B `@external(runtime: t, module: m, method: s)` share a single
                // representation. (See the `#[@external]` vocabulary in libs/std/AGENTS.md.)
                if (this.check(.identifier) and this.peekAt(1).kind == .colon) {
                    _ = this.advance(); // label name
                    _ = this.advance(); // `:`
                }
                if ((this.check(.dot) or this.check(.identifier)) and
                    (this.peekAt(1).kind == .dot or this.peekAt(1).kind == .identifier))
                {
                    // Enum/member chain: `.Erlang`, `Target.Erlang`, … — the adjacent
                    // source bytes form a single lexeme spanning the whole path.
                    const first = this.advance();
                    var last = first;
                    while (this.check(.dot) or this.check(.identifier)) last = this.advance();
                    try args.append(alloc, spanLexemes(first, last));
                } else {
                    const tok = this.advance();
                    try args.append(alloc, tok.lexeme);
                }
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightParenthesis);
        }
        return Annotation{
            .name = name,
            .args = try args.toOwnedSlice(alloc),
            .is_builtin = is_builtin,
        };
    }

    /// The single source lexeme spanning `first`..`last` inclusive. Used to keep
    /// an enum/member chain (`Target.Erlang`) as one annotation argument — the
    /// tokens are adjacent in source, so the byte range is contiguous.
    fn spanLexemes(first: Token, last: Token) []const u8 {
        const begin = @intFromPtr(first.lexeme.ptr);
        const end = @intFromPtr(last.lexeme.ptr) + last.lexeme.len;
        return first.lexeme.ptr[0 .. end - begin];
    }

    /// The shared opening of a type/interface declaration: visibility, name and
    /// annotations. The keyword that introduces the construct (and the trailing
    /// generic params / body) are parsed by the caller.
    const DeclPreamble = struct {
        isPub: bool,
        name: []const u8,
        annotations: []Annotation,
    };

    /// Frees an owned annotation slice (used on declaration parse-error paths).
    pub fn freeAnnotations(alloc: std.mem.Allocator, annotations: []Annotation) void {
        for (annotations) |*a| a.deinit(alloc);
        alloc.free(annotations);
    }

    /// Parses the shared preamble of a declaration up to and including `keyword`.
    /// Two surface forms are supported:
    ///   - val-form (`shorthand == false`):  `[pub] val Name = #[...] <keyword>`
    ///   - shorthand (`shorthand == true`):   `#[...] [pub] <keyword> Name`
    /// On error the parsed annotations are freed.
    pub fn parseDeclPreamble(this: *This, alloc: std.mem.Allocator, keyword: TokenKind, shorthand: bool) ParseError!DeclPreamble {
        if (shorthand) {
            const annotations = try this.parseAnnotations(alloc);
            errdefer freeAnnotations(alloc, annotations);
            const isPub = this.match(.@"pub");
            _ = try this.consume(keyword);
            const name = (try this.consume(.identifier)).lexeme;
            _ = this.tryParseId();
            return .{ .isPub = isPub, .name = name, .annotations = annotations };
        }
        const isPub = this.match(.@"pub");
        _ = try this.consume(.val);
        const name = (try this.consume(.identifier)).lexeme;
        _ = this.tryParseId();
        _ = try this.consume(.equal);
        const annotations = try this.parseAnnotations(alloc);
        errdefer freeAnnotations(alloc, annotations);
        _ = try this.consume(keyword);
        return .{ .isPub = isPub, .name = name, .annotations = annotations };
    }

    // ── expression helper ─────────────────────────────────────────────────────

    /// Creates a heap-allocated copy of an expression.
    pub fn boxExpr(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!*Expr {
        _ = this;
        const ptr = try alloc.create(Expr);
        ptr.* = expr;
        return ptr;
    }

    /// The binary-operator enum carried by `binaryOp` expressions.
    pub const BinOp = @FieldType(ast.BinOpExpr, "op");

    /// Builds a `binaryOp` expression, boxing both operands.
    pub fn makeBinOp(this: *This, alloc: std.mem.Allocator, op: BinOp, opTok: Token, lhs: Expr, rhs: Expr) ParseError!Expr {
        const lhsPtr = try this.boxExpr(alloc, lhs);
        const rhsPtr = try this.boxExpr(alloc, rhs);
        return Expr{ .binaryOp = .{ .loc = locFromToken(opTok), .op = op, .lhs = lhsPtr, .rhs = rhsPtr } };
    }

    /// Builds a `call` expression node (no boxing needed — `args`/`trailing` are already slices).
    pub fn makeCall(
        tok: Token,
        receiver: ?*Expr,
        callee: []const u8,
        is_builtin: bool,
        args: []CallArg,
        trailing: []TrailingLambda,
    ) Expr {
        return Expr{ .call = .{ .loc = locFromToken(tok), .kind = .{ .call = .{
            .receiver = receiver,
            .callee = callee,
            .is_builtin = is_builtin,
            .args = args,
            .trailing = trailing,
        } } } };
    }

    /// Builds a `jump` expression (`return`/`throw`/`try`/`break`/`yield`), boxing `inner` when present.
    pub fn makeJump(this: *This, alloc: std.mem.Allocator, tok: Token, comptime variant: std.meta.Tag(JumpExpr), inner: ?Expr) ParseError!Expr {
        const innerPtr: ?*Expr = if (inner) |e| try this.boxExpr(alloc, e) else null;
        return Expr{ .jump = .{ .loc = locFromToken(tok), .kind = @unionInit(JumpExpr, @tagName(variant), innerPtr) } };
    }

    /// If the current token is a comment, consumes it and appends it as a comment
    /// literal statement to `stmts`, returning true. Otherwise returns false.
    /// `emptyLinesBefore` is recorded on the appended statement.
    pub fn tryParseCommentStmt(this: *This, alloc: std.mem.Allocator, stmts: *std.ArrayList(Stmt), emptyLinesBefore: u32) ParseError!bool {
        if (!this.check(.commentNormal) and !this.check(.commentDoc) and !this.check(.commentModule)) return false;
        const tok = this.advance();
        const kind: ast.CommentKind = if (tok.kind == .commentDoc)
            .{ .doc = "" }
        else if (tok.kind == .commentModule)
            .{ .module = "" }
        else
            .{ .normal = "" };
        const text = try alloc.dupe(u8, commentText(tok.lexeme));
        try stmts.append(alloc, .{
            .expr = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .comment = .{ .kind = kind, .text = text } } } },
            .emptyLinesBefore = emptyLinesBefore,
        });
        return true;
    }

    /// If `noTailCatch` is false and the next token is `catch`, wraps `expr` in a tryCatch node.
    /// Otherwise returns `expr` unchanged. Used to apply `catch` as a tail operator.
    pub fn wrapCatch(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!Expr {
        if (!this.noTailCatch and this.match(.@"catch")) {
            const catchTok = this.tokens[this.current - 1];
            const handler = try this.parseExpr(alloc);
            const exprPtr = try this.boxExpr(alloc, expr);
            const handlerPtr = try this.boxExpr(alloc, handler);
            return Expr{ .branch = .{ .loc = locFromToken(catchTok), .kind = .{ .tryCatch = .{ .expr = exprPtr, .handler = handlerPtr } } } };
        }
        return expr;
    }

    /// Parses comma-separated identifiers (e.g., `extends T1, T2, T3` or `use { a, b, c }`).
    pub fn parseCommaSeparatedIdentifiers(this: *This, alloc: std.mem.Allocator, stopAt: ?TokenKind) ParseError![]const []const u8 {
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
    pub fn reportReservedWordError(this: *This) void {
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

    pub const parseValDecl = decl_grammar.parseValDecl;

    pub const parseTypeRef = types.parseTypeRef;

    pub const parseBaseTypeRef = types.parseBaseTypeRef;

    // ── import decl ──────────────────────────────────────────────────────────

    pub const parseImportDecl = decl_grammar.parseImportDecl;

    pub const parseActivationStmt = decl_grammar.parseActivationStmt;

    pub const parseImportList = decl_grammar.parseImportList;

    pub const parseImportItem = decl_grammar.parseImportItem;

    pub const isActivationStmt = decl_grammar.isActivationStmt;

    // ── fn decl ───────────────────────────────────────────────────────────────────

    pub const parseFnDecl = decl_grammar.parseFnDecl;

    pub const parseFnDeclFromVal = decl_grammar.parseFnDeclFromVal;

    pub const parseFnBody = decl_grammar.parseFnBody;

    // ── test decl ─────────────────────────────────────────────────────────────────

    pub const parseTestDecl = decl_grammar.parseTestDecl;

    // ── delegate decl ────────────────────────────────────────────────────────────

    pub const parseDelegateDecl = decl_grammar.parseDelegateDecl;

    pub const parseShorthandDelegateDecl = decl_grammar.parseShorthandDelegateDecl;

    pub const parseDelegateParams = decl_grammar.parseDelegateParams;

    // ── interface decl ───────────────────────────────────────────────────────────

    pub const parseInterfaceDecl = decl_grammar.parseInterfaceDecl;

    pub const parseShorthandInterfaceDecl = decl_grammar.parseShorthandInterfaceDecl;

    pub const parseExtendsClause = decl_grammar.parseExtendsClause;

    pub const parseInterfaceBody = decl_grammar.parseInterfaceBody;

    pub const parseInterfaceMethod = decl_grammar.parseInterfaceMethod;

    pub const parseMethodDecl = decl_grammar.parseMethodDecl;

    // ── struct decl ───────────────────────────────────────────────────────────

    pub const parseStructDecl = decl_grammar.parseStructDecl;

    pub const parseShorthandStructDecl = decl_grammar.parseShorthandStructDecl;

    pub const parseStructBody = decl_grammar.parseStructBody;

    pub const parseStructGetter = decl_grammar.parseStructGetter;

    pub const parseStructSetter = decl_grammar.parseStructSetter;

    // ── record decl ──────────────────────────────────────────────────────────

    pub const parseRecordDecl = decl_grammar.parseRecordDecl;

    pub const parseShorthandRecordDecl = decl_grammar.parseShorthandRecordDecl;

    pub const parseRecordBody = decl_grammar.parseRecordBody;

    // ── implement decl ────────────────────────────────────────────────────────────

    pub const parseImplementDecl = decl_grammar.parseImplementDecl;

    pub const parseShorthandImplementDecl = decl_grammar.parseShorthandImplementDecl;

    pub const parseImplementBody = decl_grammar.parseImplementBody;

    pub const parseExtendDecl = decl_grammar.parseExtendDecl;

    pub const parseShorthandExtendDecl = decl_grammar.parseShorthandExtendDecl;

    pub const parseExtendBody = decl_grammar.parseExtendBody;

    pub const parseImplementMethods = decl_grammar.parseImplementMethods;

    /// Reports an anonymous-implement/extend error for the current token.
    pub fn reportAnonImplExtendError(this: *This) void {
        const tok = this.peek();
        this.parseError = .{
            .kind = .anonymousImplExtend,
            .start = tok.col - 1,
            .end = tok.col - 1 + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
            .detail = tok.lexeme,
        };
    }

    pub const parseImplementMethod = decl_grammar.parseImplementMethod;

    // ── enum decl ─────────────────────────────────────────────────────────────

    pub const parseEnumDecl = decl_grammar.parseEnumDecl;

    pub const parseShorthandEnumDecl = decl_grammar.parseShorthandEnumDecl;

    pub const parseEnumBody = decl_grammar.parseEnumBody;

    // ── case / pattern matching ────────────────────────────────────────────────

    pub const parseCaseExpr = patterns.parseCaseExpr;

    pub const parsePattern = patterns.parsePattern;

    pub const parseSimplePattern = patterns.parseSimplePattern;

    pub const parseListPattern = patterns.parseListPattern;

    // ── comment helpers ───────────────────────────────────────────────────────

    /// Strip the leading `//`, `///`, or `////` prefix (and optional space) from a comment lexeme.
    pub fn commentText(lexeme: []const u8) []const u8 {
        var start: usize = 0;
        while (start < lexeme.len and start < 4 and lexeme[start] == '/') start += 1;
        if (start < lexeme.len and lexeme[start] == ' ') start += 1;
        return lexeme[start..];
    }

    // ── param / type name helpers ─────────────────────────────────────────────

    pub fn consumeParamName(this: *This) ParseError!Token {
        if (this.check(.identifier)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// True when `kind` may be used as a record field / member name. `get` and
    /// `set` are soft keywords: they introduce struct getters/setters only at
    /// the start of a struct member, and are otherwise ordinary names (a hook
    /// returns the shape `{ value, set }` where `set` is a function field).
    pub fn isMemberName(kind: TokenKind) bool {
        return kind == .identifier or kind == .get or kind == .set;
    }

    /// Consume a record field / member name — an `identifier`, or the soft
    /// keywords `get` / `set`.
    pub fn consumeMemberName(this: *This) ParseError!Token {
        if (isMemberName(this.peek().kind)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    /// Parses a plain type name token: `Self`, `type`, `null`, or any `identifier`.
    pub fn consumeTypeName(this: *This) ParseError!Token {
        if (this.check(.selfType)) return this.advance();
        if (this.check(.type)) return this.advance();
        if (this.check(.identifier)) return this.advance();
        // Allow `null` and other keywords that can be used as type names
        if (this.check(.null)) return this.advance();
        return ParseError.UnexpectedToken;
    }

    pub const parseGenericParams = types.parseGenericParams;

    pub const parseImplementClause = types.parseImplementClause;

    pub const parseParam = decl_grammar.parseParam;

    // ── expression parser ──────────────────────────────────────────────────────

    pub const parseExpr = exprs.parseExpr;

    pub const parseLocalBindExpr = exprs.parseLocalBindExpr;

    pub const parsePipelineExpr = exprs.parsePipelineExpr;

    /// Precedence-level entry points used by callers outside `parseBinaryExpr`.
    pub const prec = struct {
        /// `||` — the loosest binary level (full binary expression).
        pub const lowest: usize = 0;
        /// `==`/`!=` and tighter — the entry point for operand positions where
        /// `||`/`&&` are not accepted (if-conditions, yields, ranges, assignments…).
        pub const equality: usize = 2;
    };

    pub const parseBinaryExpr = exprs.parseBinaryExpr;

    pub const parsePrimary = exprs.parsePrimary;

    // ── collection literal helpers ────────────────────────────────────────────

    pub const parseTupleLitExpr = exprs.parseTupleLitExpr;

    pub const parseArrayLitExpr = exprs.parseArrayLitExpr;

    // ── lambda / call helpers ─────────────────────────────────────────────────

    pub const parseBlockExpr = exprs.parseBlockExpr;

    pub const isComment = exprs.isComment;

    pub const hasLambdaParams = exprs.hasLambdaParams;

    pub const hasLambdaBodyAhead = exprs.hasLambdaBodyAhead;

    pub const checkLabeledTrailingLambda = exprs.checkLabeledTrailingLambda;

    pub const parseLambdaBody = exprs.parseLambdaBody;

    pub const parseCallArgs = exprs.parseCallArgs;

    pub const parseTrailingLambdas = exprs.parseTrailingLambdas;

    // ── primitives ────────────────────────────────────────────────────────────

    pub fn consume(this: *This, kind: TokenKind) ParseError!Token {
        if (this.check(kind)) return this.advance();
        // parseError may not be set here; the top-level caller must populate
        // it before propagating if rich error context is needed.
        return ParseError.UnexpectedToken;
    }

    pub fn match(this: *This, kind: TokenKind) bool {
        if (!this.check(kind)) return false;
        _ = this.advance();
        return true;
    }

    pub fn check(this: *This, kind: TokenKind) bool {
        return this.peek().kind == kind;
    }

    pub fn advance(this: *This) Token {
        const t = this.tokens[this.current];
        if (t.kind != .endOfFile) this.current += 1;
        return t;
    }

    /// Consume any run of comment tokens. Used inside type/interface/record
    /// bodies, whose member loops don't model comments as members.
    pub fn skipComments(this: *This) void {
        while (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) {
            _ = this.advance();
        }
    }

    pub fn peek(this: *This) Token {
        return this.tokens[this.current];
    }

    pub fn peekAt(this: *This, offset: usize) Token {
        const i = this.current + offset;
        return if (i < this.tokens.len) this.tokens[i] else this.tokens[this.tokens.len - 1];
    }

    // ── reserved word detection helpers ──────────────────────────────────────

    pub fn isReservedWord(kind: TokenKind) bool {
        return lexer.isReservedWord(kind);
    }

    pub const parseLoopExpr = exprs.parseLoopExpr;

    pub const parseRangeExpr = exprs.parseRangeExpr;
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
