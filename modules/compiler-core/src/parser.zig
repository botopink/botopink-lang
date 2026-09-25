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
const template_markers = @import("parser/template_markers.zig");

pub const Token = token.Token;
pub const TokenKind = token.TokenKind;

pub const ImportDecl = ast.ImportDecl;
pub const ImportSource = ast.ImportSource;
pub const ImportPath = ast.ImportPath;
pub const BehaviorDecl = ast.BehaviorDecl;
pub const BehaviorField = ast.BehaviorField;
pub const BehaviorMethod = ast.BehaviorMethod;
pub const Param = ast.Param;
pub const Stmt = ast.Stmt;
pub const Expr = ast.Expr;
pub const CollectionExpr = ast.CollectionExpr;
pub const JumpExpr = ast.JumpExpr;
pub const BranchExpr = ast.BranchExpr;
pub const LoopExpr = ast.LoopExprOf(.untyped);
pub const FunctionExpr = ast.FunctionExpr;
pub const Loc = ast.Loc;
pub const TypeDecl = ast.TypeDecl;
pub const TypeShape = ast.TypeShape;
pub const Field = ast.Field;
pub const ImplementDecl = ast.ImplementDecl;
pub const ExtendDecl = ast.ExtendDecl;
pub const ImplementMethod = ast.ImplementMethod;
pub const DeclKind = ast.DeclKind;
pub const Program = ast.Program;
pub const GenericParam = ast.GenericParam;
pub const ParamModifier = ast.ParamModifier;
pub const CallArg = ast.CallArg;
pub const TrailingLambda = ast.TrailingLambda;
pub const EnumVariant = ast.EnumVariant;
pub const EnumSection = ast.EnumSection;
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
    /// Removed `*fn` prefix (use `#[@<effect>]` annotation instead).
    /// Deprecation window was v0.beta.12; the prefix is hard-removed in v0.beta.19.
    deprecatedStarFn,
    /// Decisions 118 / 127 — `#[@result]`, `#[@future]`, `#[@use]`,
    /// `#[@generator]`, `#[@resultGenerator]` or `#[@futureGenerator]`: the
    /// effect annotations left the language; the return type is the effect.
    effectAnnotationRemoved,
    /// The same annotation written before a loop: the loop takes the `iter` /
    /// `stream` prefix instead (decision 125).
    effectAnnotationRemovedLoop,
    /// Decisions 120 / 127 — `@Future<…>` in a type: the wrapper is `@Task<T>`,
    /// and a failure is `@Task<@Result<T, E>>`.
    effectTypeRemovedFuture,
    /// Decisions 122 / 127 — `@Generator<T>` in a type: `@Iterator<T>`.
    effectTypeRemovedGenerator,
    /// Decisions 122 / 127 — `@ResultGenerator<T, E>`: `@Iterator<@Result<T, E>>`.
    effectTypeRemovedResultGenerator,
    /// Decisions 122 / 127 — `@FutureGenerator<T, E>`: `@Stream<@Result<T, E>>`.
    effectTypeRemovedFutureGenerator,
    /// Decisions 128 / 127 — `@Use<C, T>`: `@Component<C, T>`.
    effectTypeRemovedUse,
    /// Decision 127 — a pre-122 sequence name that had already left
    /// (`@AsyncIterator`, `@Iterable`, `@IteratorStep`, `@Yield`): refused,
    /// naming the current one.
    effectTypeRemovedLegacy,
    /// Decisions 122 / 127 — `@Iterator<T, E>`: the iterator has no error
    /// parameter; the item carries the failure, `@Iterator<@Result<T, E>>`.
    iteratorErrorParamRemoved,
    /// R16 / RG1 (§1G) — a generic parameter without a default follows one
    /// with a default. Defaulted generics must be the trailing parameters.
    genericDefaultBeforeRequired,
    /// RI6 (§1I) — the deprecated `yield break [<expr>]` form. Use
    /// `break <C>` (or bare `break`) inside an iterator instead.
    yieldBreakRemoved,
    /// RG4 (§1G) — a generic argument list with a skipped middle slot
    /// (`@ResultGenerator<i32, , i64>`). Either pass the middle argument explicitly,
    /// or rely on defaults for the contiguous trailing range.
    genericArgSkipForbidden,
    /// D5 (fn-param-default-expansion §F2) — a fn param without a default
    /// follows one with a default (`fn f(a: i32 = 1, b: i32)`). Defaults
    /// occupy trailing positions only, mirroring §1G's generic-param rule.
    fnParamDefaultTrailingOnly,
    /// D2 (fn-param-default-expansion §F2) — a positional call argument
    /// follows a named one (`f(host: "x", "y")`). Once the call switches to
    /// named-arg form, the remaining args must also be named (the
    /// `..base` spread is allowed anywhere).
    fnParamPositionalAfterNamed,
    /// The retired `@[…]` annotation-block opener (spec 05 §5.12). Annotation
    /// blocks are written `#[…]`; the builtin marker `@` belongs on the
    /// annotation name (`#[@external(…)]`), not on the block.
    retiredAnnotationBlock,
    /// `type P(x: i32) { A }` — a field list and a variant in the same
    /// declaration: a `type` is a record (fields) or an enum (variants).
    typeRecordWithVariants,
    /// `record P { … }` — `record` was replaced by `type` in 1.0.3.
    removedKeywordRecord,
    /// `enum E { … }` — `enum` was replaced by `type` in 1.0.3.
    removedKeywordEnum,
    /// Decision 107 — `*` or `as` on an import node that opens braces
    /// (`import {io* : {fs}}`, `import {io as x: {fs}}`). Both belong to a
    /// leaf: an activation names one extension and an alias renames one
    /// binding, and a group is neither.
    importGroupModifier,
    /// `interface I { … }` — `interface` was renamed to `behavior` in 1.0.3.
    removedKeywordInterface,
    /// `record { x: 1 }` — anonymous records are tuples in 1.0.3.
    removedRecordLiteral,
    /// `loop (…) { … }` — decision 105: `loop` takes no parenthesis; a
    /// collection is `for (xs) { x -> … }`, a condition `while (cond) { … }`.
    removedLoopParenthesised,
    /// `while (cond) { x -> … }` / `loop { x -> … }` — neither binds a name
    /// (decision 105); only `for` takes `{ x -> … }`.
    loopBindsNothing,
    /// `for (xs) { … }` without `x ->` — a `for` binds the item it iterates.
    forWithoutBinder,
    /// `for (xs) { x, i -> … }` — a `for` binds one name; the index is
    /// `for (0..xs.length) { i -> }` (decision 105).
    forBindsOneName,
    /// `#[…] loop` with an annotation that is not a generator effect, or a
    /// generator annotation on `for` / `while` — only `loop` takes the
    /// annotation, and only the three generator effects (decision 105).
    loopAnnotationNotGenerator,
    /// `throw new Error(…)` — `new` is not a keyword (06 N27).
    removedKeywordNew,
    /// `{ x: i32 }` in type position — anonymous record types are tuples in 1.0.3.
    removedRecordType,
    /// `unknown<i32>` / `unknown(…)` — decision 8 §2's `unknown` is one type,
    /// not a constructor: it takes no type arguments (06 N19).
    unknownTakesNoArguments,
    /// `i32 | ` — a union type with nothing after the `|` (decision 8 §3, 06 N20).
    unionMemberMissing,
    /// `x is` with no type after it (decision 8 §4, 06 N21).
    isMissingType,
    /// `x is Option.Some(v)` — the variant-binding form of `is` (§4.2), which
    /// the grammar does not carry yet: `is` takes a type (06 N21).
    isVariantBinding,
    /// `1..9` in a pattern — `..` is iteration and slicing; an inclusive range
    /// pattern is `1...9` (decision 8 §5.2, 06 N22).
    patternRangeExclusive,
    /// `1...` — a range pattern with no upper bound (§5.2, 06 N22).
    patternRangeMissingEnd,
    /// `.Rect(.., width: w)` — `..` stands for the rest, so it comes last
    /// (§5.1 P7, 06 N22).
    patternRestNotLast,
    /// `#(name: n, ..)` — a tuple pattern is positional; a label in one is an
    /// error (§5.1 P6, 06 N22).
    patternTupleLabel,
    /// `case x { n { … } }` — a lower-case name alone is not a pattern
    /// (§5.2, 06 N22).
    caseBareNameArm,
    /// `case x { MAX { … } }` — a constant is not a pattern (§5.2, 06 N22).
    caseConstantPattern,
    /// `type P()` — an empty field list; a record with no fields omits `()`.
    typeEmptyFieldList,
    /// `type S { fn f(self: Self) {} A }` — variants come before methods.
    typeVariantAfterMethod,
    /// `type P(val x: i32)` — the field list takes no `val` prefix.
    typeFieldValPrefix,
    /// `type Shape { Circle(i32) }`, `type P(i32)` — a field or a variant
    /// payload written without its name. Decision 12: the form is refused, with
    /// a diagnostic that names `Variant(field: T)`.
    fieldNeedsName,
    /// A `,` after a member of a `type`/`behavior` body: members end with `;`
    /// (bodyless) or `}` (with a body), never with `,`.
    memberCommaSeparator,
    /// A bodyless member of a `behavior` (`fn f(self: Self) -> i32`, `val x: T`)
    /// without its terminating `;`.
    memberMissingSemicolon,
    /// `$self` in an `@External` template: markers are positional (decision 5),
    /// `$0` is the first declared parameter — `self` on a method.
    templateSelfMarker,
    /// `$N` in an `@External` template past the declaration's parameters.
    templateMarkerOutOfRange,
    /// `fn f(x: string)` with no body and no `-> …` — decision 33 (b): a
    /// declaration without a body says what it answers, even when the answer
    /// is nothing.
    bodylessFnNeedsReturnType,
    /// `c ? 1 : 2` — there is no ternary; `if` is an expression (front 15
    /// step 3). Located at the `?`.
    ternaryAbsent,
    /// `1 << 2`, `a >> 1`, `a & b`, `a ^ b` — the language has no bitwise
    /// operators, and no replacement to name (front 15 step 3). Located at the
    /// operator.
    bitwiseOperatorAbsent,
    /// `'a'` — there is no character literal; a character is a one-character
    /// string (front 15 step 3). Located at the literal.
    charLiteralAbsent,
    /// `fn inner(x: i32) { … }` inside a body — a `fn` declares at module
    /// level; inside a body a function is a value bound with `val` (front 15
    /// step 3). Located at the `fn`.
    nestedFnDecl,
    /// `[...a, 3]` — `...` is a pattern's inclusive range; the spread of an
    /// array literal is `..` (front 15 step 3). Located at the `...`.
    listSpreadDotDotDot,
    /// `type P(x: i32)` followed by `implement A for P { … }`: the `implement`
    /// was read as the bodyless type's own clause, whose receiver is the type
    /// itself, so `for` has nothing to name (front 15 step 3). Located at the
    /// `for`.
    implementClauseFor,
    /// `#(x: 1, y: 2)` — a tuple LITERAL is positional; labels belong to the
    /// tuple type `#(x: i32, y: i32)` (decision 8 §6). The labeled
    /// construction is not parsed (`01-checker` §6); this names it instead of
    /// blaming the value for a missing `val` (front 15 step 3). Located at the
    /// label.
    tupleLiteralLabel,
};

pub const ParseErrorInfo = struct {
    kind: ParseErrorType,
    /// Byte offset of the start of the problematic token in the original
    /// source. `print.render` resolves the rendered line from it and
    /// `lsp_types.spanToRange` builds the LSP range from it, so it MUST be a
    /// byte offset — never a column. Use `fromToken` rather than filling the
    /// fields by hand.
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

    /// Builds the diagnostic for `tok`: the span covers the whole token and
    /// `start`/`end` are the byte offsets the renderer and the LSP expect.
    /// This is the single place the location contract is applied — the
    /// per-site `.start = tok.col - 1` spelling it replaced reported every
    /// multi-line source's errors on line 1.
    pub fn fromToken(kind: ParseErrorType, tok: Token) ParseErrorInfo {
        return .{
            .kind = kind,
            .start = tok.offset,
            .end = tok.offset + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
        };
    }

    /// `fromToken` plus `detail` (e.g. the offending reserved word).
    pub fn fromTokenDetail(kind: ParseErrorType, tok: Token, detail: []const u8) ParseErrorInfo {
        var info = fromToken(kind, tok);
        info.detail = detail;
        return info;
    }

    /// `fromToken` with a span of exactly `len` bytes from the token's start
    /// — for diagnostics whose carets cover a fixed surface (`*fn`) rather
    /// than the token's own lexeme.
    pub fn fromTokenSpan(kind: ParseErrorType, tok: Token, len: usize) ParseErrorInfo {
        var info = fromToken(kind, tok);
        info.end = info.start + len;
        return info;
    }
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
    /// The static-prefix rule of `use` (front 19 step 1, decision 88): true once
    /// an `if`, `case`, `loop` or `return` of the **current function body** has
    /// been parsed, at any nesting. A `use` seen while it is set is
    /// `useAfterBranch`. Set by the four constructs themselves (`parser/exprs.zig`),
    /// so a branch's own block inherits it (`if (a) { use … }` is a `use` after
    /// an `if`) and a `val c = if (…) …` counts as a branch too. Reset by a block
    /// that starts a function (`BlockParseOptions.freshUseScope`): a lambda body
    /// is another function, so its `return` does not break the enclosing prefix
    /// and the enclosing `if` does not break its own.
    useBranchSeen: bool = false,
    /// One `>` still owed to an enclosing generic-argument list: nested
    /// generics close with `>>`, which the lexer scans as a single shift
    /// token (`Array<Array<T>>`). `consumeGenericClose` consumes the `>>`
    /// for the inner list and credits the second `>` here for the outer one.
    pending_gt: bool = false,
    /// Auto-incrementing counters for unique IDs per declaration type.
    id_counters: struct {
        behavior: u32 = 0,
        type: u32 = 0,
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
        // Every `UnexpectedToken` leaves a located `parseError`. The named
        // rejections fill it at the site; a plain `consume` mismatch deep in
        // an expression (`print((1);`) does not, so record the token the
        // parser stopped on — callers render the location instead of a bare
        // error name.
        var program = this.parseDecls(alloc) catch |err| {
            if (err == ParseError.UnexpectedToken and this.parseError == null) {
                this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, this.peek());
            }
            return err;
        };
        // Decision 5: positional `@External` template markers, translated for
        // the renderers; `$self` and an out-of-range `$N` are refused here.
        if (template_markers.normalizeProgram(alloc, this.tokens, &program) catch |err| {
            program.deinit(alloc);
            return err;
        }) |failure| {
            program.deinit(alloc);
            this.parseError = ParseErrorInfo.fromToken(switch (failure.kind) {
                .selfMarker => .templateSelfMarker,
                .indexOutOfRange => .templateMarkerOutOfRange,
            }, failure.tok);
            return ParseError.UnexpectedToken;
        }
        return program;
    }

    fn parseDecls(this: *This, alloc: std.mem.Allocator) ParseError!Program {
        var decls: std.ArrayList(DeclKind) = .empty;
        errdefer {
            for (decls.items) |*d| d.deinit(alloc);
            decls.deinit(alloc);
        }
        var blankBefore: std.ArrayList(bool) = .empty;
        errdefer blankBefore.deinit(alloc);
        while (!this.check(.endOfFile)) {
            const blank = if (this.current > 0) blk: {
                const prev = this.tokens[this.current - 1];
                break :blk this.peek().line > prev.line + std.mem.count(u8, prev.lexeme, "\n") + 1;
            } else false;
            try blankBefore.append(alloc, blank);
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
            } else if (this.checkShorthandNamed(.type)) blk: {
                const d = try this.parseShorthandTypeDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .type_ = d };
            } else if (this.checkShorthand(.behavior)) blk: {
                const d = try this.parseShorthandBehaviorDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .behavior = d };
            } else if (this.removedDeclKeywordAt(0) != null or
                (this.check(.@"pub") and this.removedDeclKeywordAt(1) != null))
            {
                return this.failRemovedDeclKeyword(if (this.check(.@"pub")) 1 else 0);
            } else if (this.checkShorthandDelegate()) blk: {
                const d = try this.parseShorthandDelegateDecl(alloc);
                _ = this.match(.semicolon);
                break :blk .{ .delegate = d };
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
            } else if (this.check(.loop) or this.check(.@"while") or this.check(.@"for")) blk: {
                // top-level loop statement: parsed as a val named "_loop"
                const e = if (this.check(.loop))
                    try this.parseLoopExpr(alloc, null)
                else if (this.check(.@"while"))
                    try this.parseWhileExpr(alloc)
                else
                    try this.parseForExpr(alloc);
                const ePtr = try this.boxExpr(alloc, .{ .loop = e });
                _ = this.match(.semicolon);
                break :blk DeclKind{ .val = ast.ValDecl{ .name = "_loop", .value = ePtr } };
            } else if (this.checkShorthand(.val) or this.checkShorthand(.@"var")) blk: {
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
                    .identifier => {
                        const off = if (isPub) annEnd + 1 else annEnd;
                        if (this.removedDeclKeywordAt(off) != null) return this.failRemovedDeclKeyword(off);
                        return ParseError.UnexpectedToken;
                    },
                    .type => DeclKind{ .type_ = try this.parseShorthandTypeDecl(alloc) },
                    .behavior => DeclKind{ .behavior = try this.parseShorthandBehaviorDecl(alloc) },
                    // `#[@BeamMemory.Ets] var hits: i32 = 0;` (front 17): the
                    // annotations land on the binding. Only the plain form takes
                    // them — `val Name = fn …` and the other `val` shorthands do
                    // not, and are refused where the annotation is.
                    .val, .@"var" => blk2: {
                        const annTok = this.peek();
                        const anns = try this.parseAnnotations(alloc);
                        var decl = try this.parseValForm(alloc);
                        switch (decl) {
                            .val => |*v| v.annotations = anns,
                            else => {
                                decl.deinit(alloc);
                                for (anns) |*ann| ann.deinit(alloc);
                                alloc.free(anns);
                                // Refused at the annotation, not at whatever
                                // token follows the form (decision 67).
                                this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, annTok);
                                return ParseError.UnexpectedToken;
                            },
                        }
                        break :blk2 decl;
                    },
                    // An ANNOTATED `declare fn` is the FFI declaration form
                    // (`@[external(…)] pub declare fn …;`), not a delegate.
                    .declare => DeclKind{ .@"fn" = try this.parseFnDecl(alloc) },
                    else => return ParseError.UnexpectedToken,
                };
                // Optional semicolon after top-level declaration
                _ = this.match(.semicolon);
                break :blk decl;
            } else if (this.check(.commentNormal) or this.check(.commentDoc) or this.check(.commentModule)) blk: {
                const trailing = decls.items.len > 0 and this.onPreviousTokenLine();
                const tok = this.advance();
                break :blk DeclKind{ .comment = .{
                    .text = commentText(tok.lexeme),
                    .is_module = tok.kind == .commentModule,
                    .is_doc = tok.kind == .commentDoc,
                    .trailing = trailing,
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
                    return ParseError.UnexpectedToken;
                }
                // `name = <expr>` at top level: a binding that forgot its
                // `val`/`var`. `parseExpr` raises the same diagnostic for the
                // annotated form (`name: T = …`); without this arm the top
                // level returned an UnexpectedToken with NO `parseError`, so
                // nothing was rendered at all.
                if (this.check(.identifier) and
                    (this.peekAt(1).kind == .equal or this.peekAt(1).kind == .plusEqual))
                {
                    const tok = this.peek();
                    this.parseError = ParseErrorInfo.fromTokenDetail(.novalBinding, tok, tok.lexeme);
                    return ParseError.UnexpectedToken;
                }
                // No stderr from the parser: the error carries the location
                // (`errorInfo`) and the caller renders it.
                return ParseError.UnexpectedToken;
            };
            try decls.append(alloc, decl);
        }
        const declSlice = try decls.toOwnedSlice(alloc);
        errdefer {
            for (declSlice) |*d| d.deinit(alloc);
            alloc.free(declSlice);
        }
        return Program{ .decls = declSlice, .blankLineBefore = try blankBefore.toOwnedSlice(alloc) };
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
        // `var` has the plain form only — no shorthand reads it.
        if (this.checkShorthand(.@"var")) return .{ .val = try this.parseValDecl(alloc) };
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
        if (body == .identifier and this.removedDeclKeywordAt(adjustedOffset) != null) {
            const lexeme = this.peekAt(adjustedOffset).lexeme;
            // `val x = record { a: 1 }` in a lower-case binding is the removed
            // anonymous record literal; `val Point = record { … }` the removed
            // declaration form. `val Name = interface fn(…)` was a delegate.
            if (std.mem.eql(u8, lexeme, "record") and bodyNext == .leftBrace and this.valFormNameIsLower()) {
                return this.failRemovedAt(.removedRecordLiteral, adjustedOffset);
            }
            return this.failRemovedDeclKeyword(adjustedOffset);
        }
        return switch (body) {
            .implement => .{ .implement = try this.parseImplementDecl(alloc) },
            .extend => .{ .extend = try this.parseExtendDecl(alloc) },
            .declare => .{ .delegate = try this.parseDelegateDecl(alloc) },
            .type => switch (bodyNext) {
                .lessThan, .leftParenthesis, .leftBrace, .implement => .{ .type_ = try this.parseTypeDecl(alloc) },
                else => .{ .val = try this.parseValDecl(alloc) },
            },
            .behavior => .{ .behavior = try this.parseBehaviorDecl(alloc) },
            .@"fn" => .{ .@"fn" = try this.parseFnDeclFromVal(alloc) },
            else => .{ .val = try this.parseValDecl(alloc) },
        };
    }

    /// The removed 1.0.2 declaration keyword at `offset` — `record`, `enum` or
    /// `interface`, which lex as identifiers since 1.0.3 — when it is followed
    /// by what a declaration would take (a name, `{`, `<` or `fn`). Null
    /// otherwise, so the three words stay free as ordinary identifiers.
    pub fn removedDeclKeywordAt(this: *This, offset: usize) ?ParseErrorType {
        const tok = this.peekAt(offset);
        if (tok.kind != .identifier) return null;
        const next = this.peekAt(offset + 1).kind;
        if (next != .identifier and next != .leftBrace and next != .lessThan and next != .@"fn") return null;
        if (std.mem.eql(u8, tok.lexeme, "record")) return .removedKeywordRecord;
        if (std.mem.eql(u8, tok.lexeme, "enum")) return .removedKeywordEnum;
        if (std.mem.eql(u8, tok.lexeme, "interface")) return .removedKeywordInterface;
        return null;
    }

    /// Records the targeted removed-keyword diagnostic at the keyword token.
    pub fn failRemovedDeclKeyword(this: *This, offset: usize) ParseError {
        const kind = this.removedDeclKeywordAt(offset) orelse .unexpectedToken;
        return this.failRemovedAt(kind, offset);
    }

    pub fn failRemovedAt(this: *This, kind: ParseErrorType, offset: usize) ParseError {
        const tok = this.peekAt(offset);
        this.parseError = ParseErrorInfo.fromTokenSpan(kind, tok, tok.lexeme.len);
        return ParseError.UnexpectedToken;
    }

    /// `val name = …` / `pub val name = …`: the bound name starts lower-case.
    fn valFormNameIsLower(this: *This) bool {
        const off: usize = if (this.check(.@"pub")) 2 else 1;
        const name = this.peekAt(off).lexeme;
        return name.len > 0 and std.ascii.isLower(name[0]);
    }

    /// true if the current token is `kind`, or `pub` followed by `kind`.
    pub inline fn checkShorthand(this: *This, kind: TokenKind) bool {
        return this.check(kind) or (this.check(.@"pub") and this.peekAt(1).kind == kind);
    }

    /// true if `kind Name` or `pub kind Name` is next — for keywords that also
    /// have a non-declaration meaning (`type` is the kind of types too).
    pub inline fn checkShorthandNamed(this: *This, kind: TokenKind) bool {
        if (this.check(kind)) return this.peekAt(1).kind == .identifier;
        if (this.check(.@"pub")) return this.peekAt(1).kind == kind and this.peekAt(2).kind == .identifier;
        return false;
    }

    /// true for a named shorthand decl `Name <kind> …` or `pub Name <kind> …`,
    /// used to detect `Name implement …` / `Name extend …`.
    pub inline fn checkNamedDecl(this: *This, kind: TokenKind) bool {
        if (this.check(.identifier)) return this.peekAt(1).kind == kind;
        if (this.check(.@"pub")) return this.peekAt(1).kind == .identifier and this.peekAt(2).kind == kind;
        return false;
    }

    /// true if a removed `*fn` declaration is next: `*fn` or `pub *fn`. Used
    /// by the top-level dispatcher to route the prefix into `parseFnDecl`,
    /// where the `deprecated-star-fn` diagnostic fires (v0.beta.19). Without
    /// this routing the prefix would fall through to a generic
    /// "unexpected token" error and the migration help would never run.
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
        /// This block starts a function body (fn, `test`, lambda): the static
        /// prefix starts over — `useBranchSeen` is cleared on entry and restored
        /// on exit. A branch's block (`if`/`else`/`case` arm/`loop` body) leaves
        /// it false and inherits the enclosing body's flag.
        freshUseScope: bool = false,
    };

    /// Parse `{ stmt; stmt; ... }`. The opening `{` must be the current token.
    /// Unifies every brace-delimited block in the parser via `BlockParseOptions`.
    pub fn parseBlock(this: *This, alloc: std.mem.Allocator, comptime opts: BlockParseOptions) ParseError![]Stmt {
        _ = try this.consume(.leftBrace);
        return this.parseBlockBody(alloc, opts);
    }

    /// The body of a brace-delimited block, `{` **already consumed**, up to and
    /// including the `}`.
    ///
    /// It exists for the two blocks that read something between the `{` and the
    /// first statement and so cannot call `parseBlock`: the `if` then-branch's
    /// `{ x -> … }` value binding, and a lambda's `{ a, b -> … }` parameter
    /// list. Both used to carry their own copy of this loop, written before
    /// `BlockParseOptions` existed, and each copy left out comment handling and
    /// empty-line tracking — so a `//` comment was a parse error inside an `if`
    /// then-branch and inside every `loop (…) { x -> … }` body (which is a
    /// lambda body), while the same comment in a fn body, a `test` body or an
    /// `if` **else**-branch parsed. **A block that needs a prologue calls this;
    /// it does not copy the loop.**
    pub fn parseBlockBody(this: *This, alloc: std.mem.Allocator, comptime opts: BlockParseOptions) ParseError![]Stmt {
        var stmts: std.ArrayList(Stmt) = .empty;
        errdefer {
            for (stmts.items) |*s| s.deinit(alloc);
            stmts.deinit(alloc);
        }
        // The static prefix is a property of the function body, not of this
        // block: nested branch blocks inherit `useBranchSeen`, a function body
        // starts clean, and both restore the enclosing state on exit.
        const savedBranchSeen = this.useBranchSeen;
        defer this.useBranchSeen = savedBranchSeen;
        if (opts.freshUseScope) this.useBranchSeen = false;
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const emptyLinesBefore: u32 = if (opts.trackEmptyLines) blk: {
                const prevLine = if (this.current > 0) this.tokens[this.current - 1].line else 1;
                const currLine = this.peek().line;
                break :blk if (currLine > prevLine + 1) @intCast(currLine - prevLine - 1) else 0;
            } else 0;

            if (opts.handleComments and try this.tryParseCommentStmt(alloc, &stmts, emptyLinesBefore)) continue;

            // A bare `use …;` statement after a branch: refused at its own
            // token before anything is parsed. The `if`/`case`/`loop`/`return`
            // that set `useBranchSeen` did so when they were parsed
            // (`parser/exprs.zig`), which is what lets a `use` inside a
            // branch's block see the branch it is in (row 4c of front 19).
            if (opts.useAfterBranchGuard and this.useBranchSeen and this.check(.use)) {
                const tok = this.peek();
                this.parseError = ParseErrorInfo.fromToken(.useAfterBranch, tok);
                return ParseError.UnexpectedToken;
            }

            var expr = try this.parseExpr(alloc);
            // The statement is parsed before the separator is checked, so a
            // semicolon-policy failure leaves it owned by nobody. It is freed
            // here rather than leaked; once appended, `stmts`' own errdefer
            // owns it and this one is discharged.
            errdefer expr.deinit(alloc);
            // `val c = use …` / `var c = use …` / `val {a, b} = use …` after a
            // branch (row 4b): the statement starts with `val`, so only the
            // parsed shape shows the `use`. Reported at the `use` token.
            if (opts.useAfterBranchGuard and this.useBranchSeen) {
                if (bindingUseLoc(&expr)) |loc| {
                    this.parseError = ParseErrorInfo.fromToken(.useAfterBranch, this.tokenAt(loc, .use));
                    return ParseError.UnexpectedToken;
                }
            }
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

    /// A block that **starts a function body** — a `fn` / method body, a `test`
    /// body, a `fn (…) { … }` expression: `parseStmtListInBraces` with the
    /// static prefix of `use` starting over (`freshUseScope`). Lambdas read a
    /// prologue and call `parseBlockBody` with the same flag themselves.
    pub fn parseFnBodyInBraces(this: *This, alloc: std.mem.Allocator) ParseError![]Stmt {
        return this.parseBlock(alloc, .{
            .trackEmptyLines = true,
            .handleComments = true,
            .semicolonPolicy = .requiredExceptLast,
            .useAfterBranchGuard = true,
            .freshUseScope = true,
        });
    }

    /// The `use` a statement activates at its top level, if any: a bare
    /// `use …;`, or a `val`/`var` (plain or destructuring) whose value is the
    /// `use` prefix. The static-prefix rule tests statements by this shape, not
    /// by their first token. Same shape as `codegen/commonJS.zig`'s former
    /// `useHookInner`, over the binding as well.
    fn bindingUseLoc(e: *const Expr) ?Loc {
        return switch (e.*) {
            .useHook => |uh| uh.loc,
            .binding => |b| switch (b.kind) {
                .localBind => |lb| if (lb.value.* == .useHook) lb.value.useHook.loc else null,
                .localBindDestruct => |lb| if (lb.value.* == .useHook) lb.value.useHook.loc else null,
                else => null,
            },
            else => null,
        };
    }

    /// The token of kind `kind` at `loc` — the one an already-parsed node was
    /// built from — so a diagnostic raised after the parse still carries the
    /// byte offsets `ParseErrorInfo.fromToken` requires. Falls back to the
    /// current token when no token matches (it always does for a node the
    /// parser just built).
    fn tokenAt(this: *This, loc: Loc, kind: TokenKind) Token {
        for (this.tokens) |tok| {
            if (tok.kind == kind and tok.line == loc.line and tok.col == loc.col) return tok;
        }
        return this.peek();
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
    /// The only form is `#[@builtin(arg, arg), custom()]`:
    ///   - `@name` prefix marks a compiler-known (builtin) attribute;
    ///   - plain `name` is a user-defined attribute;
    ///   - comma-separated list of any mix.
    ///
    /// The retired `@[name(…)]` opener (spec 05 §5.12) is REJECTED here, with
    /// a diagnostic naming its `#[@name(…)]` replacement. It is still detected
    /// by the lookaheads (`skipAnnotationsLookaheadFrom`, the interface-member
    /// check) so a stale `@[` reaches this diagnostic instead of a bare
    /// "unexpected token".
    ///
    /// Returns an owned slice (empty when no annotations are present).
    pub fn parseAnnotations(this: *This, alloc: std.mem.Allocator) ParseError![]Annotation {
        var list: std.ArrayList(Annotation) = .empty;
        errdefer {
            for (list.items) |*ann| ann.deinit(alloc);
            list.deinit(alloc);
        }
        while ((this.check(.hash) or this.check(.at)) and this.peekAt(1).kind == .leftSquareBracket) {
            if (this.check(.at)) {
                this.parseError = ParseErrorInfo.fromTokenSpan(.retiredAnnotationBlock, this.peek(), "@[".len);
                return ParseError.UnexpectedToken;
            }
            _ = this.advance(); // `#`
            _ = try this.consume(.leftSquareBracket);
            // Decisions 118 / 127 — the six effect annotations are recognised
            // only to be refused, located on the annotation's name.
            var removed: ?Token = null;
            while (true) {
                const nameTok = this.peek();
                const ann = try this.parseAnnotationCall(alloc);
                if (removed == null and ann.is_builtin and ast.isRemovedEffectAnnotation(ann.name)) removed = nameTok;
                try list.append(alloc, ann);
                if (!this.match(.comma)) break;
            }
            _ = try this.consume(.rightSquareBracket);
            if (removed) |tok| {
                // Before a loop the fix-it is the `iter` / `stream` prefix
                // (decision 125); anywhere else it is the return type.
                const onLoop = this.check(.loop) or this.check(.@"while") or this.check(.@"for");
                this.parseError = ParseErrorInfo.fromToken(if (onLoop) .effectAnnotationRemovedLoop else .effectAnnotationRemoved, tok);
                return ParseError.UnexpectedToken;
            }
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
        // A qualified path (`@External.Erlang(...)`) reads the trailing
        // `.Ident(.Ident)*` chain — used by enum-variant annotations (a builtin
        // enum implementing `@Annotation` exposes each variant as an annotation).
        // The full path lands as the annotation name (`"External.Erlang"`), the
        // single key the decorator validator looks up.
        var is_builtin = false;
        var name_start: Token = undefined;
        var name_end: Token = undefined;
        if (this.check(.builtinIdent)) {
            is_builtin = true;
            name_start = this.advance();
            name_end = name_start;
        } else {
            const nameTok = this.peek();
            if (nameTok.kind != .identifier and !isReservedWord(nameTok.kind)) return ParseError.UnexpectedToken;
            name_start = this.advance();
            name_end = name_start;
        }
        while (this.check(.dot) and this.peekAt(1).kind == .identifier) {
            _ = this.advance(); // `.`
            name_end = this.advance(); // ident
        }
        const name: []const u8 = blk: {
            const skip: usize = if (is_builtin) 1 else 0; // strip leading `@`
            if (name_end.lexeme.ptr == name_start.lexeme.ptr) {
                break :blk name_start.lexeme[skip..];
            }
            const begin = @intFromPtr(name_start.lexeme.ptr) + skip;
            const end = @intFromPtr(name_end.lexeme.ptr) + name_end.lexeme.len;
            break :blk @as([*]const u8, @ptrFromInt(begin))[0 .. end - begin];
        };

        var args: std.ArrayList([]const u8) = .empty;
        errdefer args.deinit(alloc);
        // One entry per argument: the label written before it, or `""`.
        var labels: std.ArrayList([]const u8) = .empty;
        defer labels.deinit(alloc);
        var any_label = false;
        if (this.match(.leftParenthesis)) {
            while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                // `prim-op-annotation` arity-branch label: `when($argc == N): "..."`
                // is recognised before label-strip and spans through balanced parens
                // + the `:` separator + the value, landing as one arg lexeme
                // (`when($argc == 1): "lists:nthtail($1, $0)"`). Readers
                // (`ast.externalArityBranchFor`) detect the `when(` prefix.
                if (this.check(.identifier) and
                    std.mem.eql(u8, this.peek().lexeme, "when") and
                    this.peekAt(1).kind == .leftParenthesis)
                {
                    const first = this.advance(); // `when`
                    _ = this.advance(); // `(`
                    var depth: usize = 1;
                    var last = first;
                    while (depth > 0 and !this.check(.endOfFile)) {
                        const k = this.peek().kind;
                        if (k == .leftParenthesis) depth += 1;
                        if (k == .rightParenthesis) {
                            depth -= 1;
                            if (depth == 0) {
                                last = this.advance(); // closing `)`
                                break;
                            }
                        }
                        last = this.advance();
                    }
                    if (this.check(.colon)) {
                        last = this.advance(); // `:`
                        if (!this.check(.rightParenthesis) and !this.check(.comma) and !this.check(.endOfFile)) {
                            last = this.advance(); // the value (typically a string literal)
                        }
                    }
                    try args.append(alloc, spanLexemes(first, last));
                    try labels.append(alloc, "");
                    if (!this.match(.comma)) break;
                    continue;
                }
                // Labeled argument (`runtime:`, `module:`, `method:`, `inline:`) —
                // both the `:` (Form B label) and the `=` (fn-style default-arg
                // assignment, `inline = true`) separators are accepted, keeping
                // annotation args close to how fn params are written. The label is
                // cosmetic at this layer; the value lands positionally so each
                // annotation's reader (`FnDecl.externalFor` / `BehaviorMethod.externalFor`
                // + `hasExternalInline`, `parseExternalCallTemplate`, …) interprets it. See the
                // `#[@External.<targert>(...)]` vocabulary in `libs/std/AGENTS.md`.
                var label: []const u8 = "";
                if (this.check(.identifier) and
                    (this.peekAt(1).kind == .colon or this.peekAt(1).kind == .equal))
                {
                    label = this.advance().lexeme; // label name
                    _ = this.advance(); // `:` or `=`
                    any_label = true;
                }
                try labels.append(alloc, label);
                if ((this.check(.dot) or this.check(.identifier)) and
                    (this.peekAt(1).kind == .dot or this.peekAt(1).kind == .identifier))
                {
                    // Enum/member chain: `.Erlang`, `Target.Erlang`, … — the adjacent
                    // source bytes form a single lexeme spanning the whole path.
                    const first = this.advance();
                    var last = first;
                    while (this.check(.dot) or this.check(.identifier)) last = this.advance();
                    try args.append(alloc, spanLexemes(first, last));
                } else if (this.check(.minus) and this.peekAt(1).kind == .numberLiteral) {
                    // `#[mark(-20)]` — a negative literal is one argument, the
                    // sign and the digits spanned into one lexeme, so the
                    // reader that parses the lexeme as an expression sees
                    // `-20`. It used to be the catch-all at the digits: the
                    // `-` was taken as the whole argument and `20` had
                    // nowhere to go (front 15 step 4b).
                    const first = this.advance(); // `-`
                    const last = this.advance(); // the digits
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
            .labels = if (any_label) try labels.toOwnedSlice(alloc) else &.{},
            .is_builtin = is_builtin,
            .loc = .{ .line = name_start.line, .col = name_start.col },
        };
    }

    /// The single source lexeme spanning `first`..`last` inclusive. Used to keep
    /// an enum/member chain (`Target.Erlang`) as one annotation argument — the
    /// tokens are adjacent in source, so the byte range is contiguous.
    pub fn spanLexemes(first: Token, last: Token) []const u8 {
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

    /// `boxExpr`, taking ownership even when the allocation fails: the value is
    /// freed on the error path, so the caller must **not** keep an
    /// `errdefer expr.deinit(alloc)` alive across the call. The boxed copy owns
    /// the children from here on, and a second `deinit` of the same children is
    /// a double free — that is what aborted the compiler on
    /// `val assert Ok(n) = f();` with no `catch` (06 C12).
    pub fn boxExprOwned(this: *This, alloc: std.mem.Allocator, expr: Expr) ParseError!*Expr {
        return this.boxExpr(alloc, expr) catch |err| {
            var mut = expr;
            mut.deinit(alloc);
            return err;
        };
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
        return makeCallAt(locFromToken(tok), receiver, callee, is_builtin, args, trailing);
    }

    /// `makeCall` for callers that already hold the callee's `Loc` rather than
    /// its token (the tagged-call sugar, which rebuilds a method call from an
    /// `identAccess` node). Call locs are keyed by location downstream, so the
    /// loc must be the CALLEE's — never the receiver's.
    pub fn makeCallAt(
        loc: Loc,
        receiver: ?*Expr,
        callee: []const u8,
        is_builtin: bool,
        args: []CallArg,
        trailing: []TrailingLambda,
    ) Expr {
        return Expr{ .call = .{ .loc = loc, .kind = .{ .call = .{
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
    /// The current token starts on the line where the previous token ends —
    /// a comment there is a trailing comment (`f(); // note`). False after `{`.
    pub fn onPreviousTokenLine(this: *This) bool {
        if (this.current == 0) return false;
        const prev = this.tokens[this.current - 1];
        if (prev.kind == .leftBrace) return false;
        return this.peek().line == prev.line + std.mem.count(u8, prev.lexeme, "\n");
    }

    pub fn tryParseCommentStmt(this: *This, alloc: std.mem.Allocator, stmts: *std.ArrayList(Stmt), emptyLinesBefore: u32) ParseError!bool {
        if (!this.check(.commentNormal) and !this.check(.commentDoc) and !this.check(.commentModule)) return false;
        const trailing = this.onPreviousTokenLine() and stmts.items.len > 0;
        const tok = this.advance();
        const kind: ast.CommentKind = if (tok.kind == .commentDoc)
            .{ .doc = "" }
        else if (tok.kind == .commentModule)
            .{ .module = "" }
        else
            .{ .normal = "" };
        const text = try alloc.dupe(u8, commentText(tok.lexeme));
        try stmts.append(alloc, .{
            .expr = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .comment = .{ .kind = kind, .text = text, .trailing = trailing } } } },
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
        this.parseError = ParseErrorInfo.fromTokenDetail(.reservedWord, tok, tok.lexeme);
    }

    // ── val decl ─────────────────────────────────────────────────────────────

    pub const parseValDecl = decl_grammar.parseValDecl;

    pub const parseTypeRef = types.parseTypeRef;

    pub const parseBaseTypeRef = types.parseBaseTypeRef;

    pub const parseTypeRefMember = types.parseTypeRefMember;

    pub const startsTypeRef = types.startsTypeRef;

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

    pub const parseExtendsClause = decl_grammar.parseExtendsClause;

    pub const parseMethodDecl = decl_grammar.parseMethodDecl;

    // ── record decl ──────────────────────────────────────────────────────────

    pub const parseTypeDecl = decl_grammar.parseTypeDecl;

    pub const parseShorthandTypeDecl = decl_grammar.parseShorthandTypeDecl;

    pub const parseTypeDeclRest = decl_grammar.parseTypeDeclRest;

    pub const parseBehaviorDecl = decl_grammar.parseBehaviorDecl;

    pub const parseShorthandBehaviorDecl = decl_grammar.parseShorthandBehaviorDecl;

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
        this.parseError = ParseErrorInfo.fromTokenDetail(.anonymousImplExtend, tok, tok.lexeme);
    }

    pub const parseImplementMethod = decl_grammar.parseImplementMethod;

    // ── enum decl ─────────────────────────────────────────────────────────────

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
    /// Consume a record field / member name — an `identifier`.
    pub fn isMemberName(kind: TokenKind) bool {
        return kind == .identifier;
    }

    /// Consume a record field / member name — an `identifier`.
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
    pub const parseWhileExpr = exprs.parseWhileExpr;
    pub const parseForExpr = exprs.parseForExpr;
    pub const parseAnnotatedLoopExpr = exprs.parseAnnotatedLoopExpr;
    pub const parseGenLoopExpr = exprs.parseGenLoopExpr;

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

test {
    _ = template_markers;
}
