//! Declaration sub-grammar extracted from `parser.zig`: val/fn/struct/
//! record/enum/interface/implement/extend/delegate/import decls + params.
//! Free functions on `*Parser`; `parser.zig` re-exports each as a thin alias.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");
const token = @import("../lexer/token.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const ParseErrorInfo = parser.ParseErrorInfo;
const ImportDecl = parser.ImportDecl;
const ImportSource = parser.ImportSource;
const ImportPath = parser.ImportPath;
const BehaviorDecl = parser.BehaviorDecl;
const BehaviorField = parser.BehaviorField;
const BehaviorMethod = parser.BehaviorMethod;
const Param = parser.Param;
const Stmt = parser.Stmt;
const Expr = parser.Expr;
const TypeDecl = parser.TypeDecl;
const Field = parser.Field;
const ImplementDecl = parser.ImplementDecl;
const ExtendDecl = parser.ExtendDecl;
const ImplementMethod = parser.ImplementMethod;
const DeclKind = parser.DeclKind;
const GenericParam = parser.GenericParam;
const ParamModifier = parser.ParamModifier;
const EnumVariant = parser.EnumVariant;
const FnDecl = parser.FnDecl;
const ValDecl = parser.ValDecl;
const DelegateDecl = parser.DelegateDecl;
const Annotation = parser.Annotation;
const FnType = parser.FnType;
const FnTypeParam = parser.FnTypeParam;
const TypeRef = parser.TypeRef;
const Pattern = parser.Pattern;
const Token = parser.Token;
const TokenKind = parser.TokenKind;
const prec = This.prec;
const locFromToken = This.locFromToken;
const freeAnnotations = This.freeAnnotations;

/// True when `kind` can begin a type reference. Mirrors `parser/types.zig`'s
/// `startsTypeRef`; lifted here for `parseFnBody`'s arrow-less return-type
/// shortform check (`fn typeOf<T>(val: T) type` in `libs/std/src/builtins.d.bp`).
fn isTypeStart(kind: TokenKind) bool {
    return switch (kind) {
        .identifier,
        .builtinIdent,
        .questionMark,
        .hash,
        .@"fn",
        .selfType,
        .type,
        .unknown,
        => true,
        else => false,
    };
}

/// Parses `param, param, ...` up to and including `)`.
/// The caller must have already consumed the opening `(`.
pub fn parseParamList(this: *This, alloc: std.mem.Allocator) ParseError![]Param {
    var params: std.ArrayList(Param) = .empty;
    errdefer {
        for (params.items) |*p| p.deinit(alloc);
        params.deinit(alloc);
    }
    while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
        // D5 — parse-time companion of D1: once a param declares `= <expr>`,
        // every subsequent param must too. Mirrors §1G's
        // generic-default-before-required rule, surfaced at parse time so the
        // bad signature is rejected before inference ever sees the fn.
        const param_tok = this.peek();
        const p = try this.parseParam(alloc);
        try params.append(alloc, p);
        if (params.items.len >= 2 and
            params.items[params.items.len - 2].default != null and
            params.items[params.items.len - 1].default == null)
        {
            this.parseError = ParseErrorInfo.fromToken(.fnParamDefaultTrailingOnly, param_tok);
            return ParseError.UnexpectedToken;
        }
        if (!this.match(.comma)) break;
    }
    _ = try this.consume(.rightParenthesis);
    return params.toOwnedSlice(alloc);
}

pub fn parseValDecl(this: *This, alloc: std.mem.Allocator) ParseError!ValDecl {
    const isPub = this.match(.@"pub");
    // `var name: T = v;` — decision 38's mutable binding, one level up from the
    // local `var` (`localBind.mutable`).
    const mutable = this.match(.@"var");
    if (!mutable) _ = try this.consume(.val);

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
        this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, tok);
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
    return ValDecl{ .name = name, .isPub = isPub, .mutable = mutable, .typeAnnotation = typeAnnotation, .value = value_ptr };
}

/// `import { item, ... } [from "name"];`  ──or──
/// `import pkg [, { item, ... }] [from "name"];`  (package-namespace form: binds
/// `pkg` so its `root.bp` `pub default fn` powers the `pkg "…"` DSL).
pub fn parseImportDecl(this: *This, alloc: std.mem.Allocator) ParseError!ImportDecl {
    _ = try this.consume(.import);

    // Package-namespace form leads with a bare identifier (not `{`).
    var package: ?[]const u8 = null;
    if (!this.check(.leftBrace)) {
        package = (try this.consume(.identifier)).lexeme;
        // `import pkg;` / `import pkg from "…";` — no named list.
        if (!this.match(.comma)) {
            const src: ImportSource = if (this.match(.from)) blk: {
                const tok = try this.consume(.stringLiteral);
                break :blk .{ .module = tok.lexeme[1 .. tok.lexeme.len - 1] };
            } else .root;
            return ImportDecl{ .imports = &.{}, .source = src, .package = package };
        }
        // `import pkg, { … } [from …];` falls through to parse the list.
    }

    _ = try this.consume(.leftBrace);
    const imports = try this.parseImportList(alloc);
    errdefer {
        for (imports) |imp| alloc.free(imp.segments);
        alloc.free(imports);
    }
    _ = try this.consume(.rightBrace);
    const source: ImportSource = if (this.match(.from)) blk: {
        const tok = try this.consume(.stringLiteral);
        break :blk .{ .module = tok.lexeme[1 .. tok.lexeme.len - 1] };
    } else .root;
    return ImportDecl{ .imports = imports, .source = source, .package = package };
}

/// Fallback activation statement `dottedPath "*" ";"` — activates an
/// already-visible symbol without re-importing it.
pub fn parseActivationStmt(this: *This, alloc: std.mem.Allocator) ParseError!ImportDecl {
    const path = try this.parseImportItem(alloc);
    errdefer alloc.free(path.segments);
    const imports = try alloc.alloc(ImportPath, 1);
    imports[0] = path;
    return ImportDecl{ .imports = imports, .source = .root, .activationOnly = true };
}

pub fn parseImportList(this: *This, alloc: std.mem.Allocator) ParseError![]const ImportPath {
    var paths: std.ArrayList(ImportPath) = .empty;
    errdefer {
        for (paths.items) |p| alloc.free(p.segments);
        paths.deinit(alloc);
    }
    try parseImportItems(this, alloc, &.{}, &paths);
    return paths.toOwnedSlice(alloc);
}

/// `ImportList := ImportItem ("," ImportItem)* ","?` under `prefix` — the
/// segments of every group this list is nested in (empty at the top). Each
/// item appends one or more leaves to `out`.
fn parseImportItems(
    this: *This,
    alloc: std.mem.Allocator,
    prefix: []const []const u8,
    out: *std.ArrayList(ImportPath),
) ParseError!void {
    if (!this.check(.identifier)) return;
    try parseImportItemInto(this, alloc, prefix, out);
    while (this.match(.comma)) {
        if (this.check(.rightBrace)) break;
        try parseImportItemInto(this, alloc, prefix, out);
    }
}

/// One import item (decision 107), in either spelling:
///
///     ImportItem := DottedName ("*" | "as" Ident)?   // a dotted path — one leaf
///                 | Ident ":" "{" ImportList "}"     // a group — several leaves under one prefix
///
/// Both produce the same `ImportPath` per leaf — a group is flattened, its
/// name prepended to every leaf inside it, so `io: {fs: {readText}}` and
/// `io.fs.readText` are one path. `*` and `as` belong to a leaf; on a node
/// that opens braces they are `importGroupModifier`.
fn parseImportItemInto(
    this: *This,
    alloc: std.mem.Allocator,
    prefix: []const []const u8,
    out: *std.ArrayList(ImportPath),
) ParseError!void {
    const first = this.peek();
    var own: std.ArrayList([]const u8) = .empty;
    defer own.deinit(alloc);
    try own.append(alloc, (try this.consume(.identifier)).lexeme);
    while (this.match(.dot)) {
        try own.append(alloc, (try this.consume(.identifier)).lexeme);
    }
    // A group: `Ident ":" "{" … "}"`. The grammar takes ONE identifier before
    // the colon — a dotted prefix is written as nested groups or as a dotted
    // leaf, never as `a.b: {…}` — so a dotted name followed by `:` is the
    // ordinary unexpected-token refusal at the colon.
    if (this.check(.colon) and own.items.len == 1) {
        _ = this.advance();
        _ = try this.consume(.leftBrace);
        const nested = try alloc.alloc([]const u8, prefix.len + 1);
        defer alloc.free(nested);
        @memcpy(nested[0..prefix.len], prefix);
        nested[prefix.len] = own.items[0];
        try parseImportItems(this, alloc, nested, out);
        _ = try this.consume(.rightBrace);
        return;
    }
    const modifier_tok = this.peek();
    const activate = this.match(.star);
    const alias: ?[]const u8 = if (this.match(.as))
        (try this.consume(.identifier)).lexeme
    else
        null;
    // `io* : {…}` / `io as x: {…}` — a modifier on a node that opens braces.
    if (this.check(.colon) and (activate or alias != null)) {
        this.parseError = ParseErrorInfo.fromToken(.importGroupModifier, modifier_tok);
        return ParseError.UnexpectedToken;
    }
    const segs = try alloc.alloc([]const u8, prefix.len + own.items.len);
    errdefer alloc.free(segs);
    @memcpy(segs[0..prefix.len], prefix);
    @memcpy(segs[prefix.len..], own.items);
    try out.append(alloc, ImportPath{
        .segments = segs,
        .activate = activate,
        .alias = alias,
        .loc = This.locFromToken(first),
    });
}

/// `dottedPath "*"? ("as" ident)?` — one import item with no group form: the
/// activation statement (`ducks.PatoNada*;`) takes exactly one leaf.
pub fn parseImportItem(this: *This, alloc: std.mem.Allocator) ParseError!ImportPath {
    var paths: std.ArrayList(ImportPath) = .empty;
    errdefer {
        for (paths.items) |p| alloc.free(p.segments);
        paths.deinit(alloc);
    }
    try parseImportItemInto(this, alloc, &.{}, &paths);
    if (paths.items.len != 1) {
        this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, this.peek());
        return ParseError.UnexpectedToken;
    }
    const one = paths.items[0];
    paths.deinit(alloc);
    return one;
}

/// Lookahead for a top-level activation statement: `ident ("." ident)* "*"`.
pub fn isActivationStmt(this: *This) bool {
    if (!this.check(.identifier)) return false;
    var offset: usize = 1;
    while (this.peekAt(offset).kind == .dot) {
        if (this.peekAt(offset + 1).kind != .identifier) return false;
        offset += 2;
    }
    return this.peekAt(offset).kind == .star;
}

pub fn parseFnDecl(this: *This, alloc: std.mem.Allocator) ParseError!FnDecl {
    const annotations = try this.parseAnnotations(alloc);
    errdefer {
        for (annotations) |*ann| ann.deinit(alloc);
        alloc.free(annotations);
    }
    const isPub = this.match(.@"pub");
    // `pub default fn` (root.bp) — the package's DSL default handler.
    const isDefault = this.match(.default);
    // `declare fn` — bodyless declaration (required for `@[external(…)]` fns).
    const isDeclare = this.match(.declare);
    // `*fn` was removed in v0.beta.19 (the v0.beta.12 deprecation window closed):
    // reject the prefix with a migration-pointing diagnostic instead of parsing it.
    if (this.check(.star) and this.peekAt(1).kind == .@"fn") {
        return failDeprecatedStarFn(this);
    }
    _ = try this.consume(.@"fn");
    const name = (try this.consume(.identifier)).lexeme;
    var fn_decl = try this.parseFnBody(alloc, name, isPub, isDeclare, annotations);
    fn_decl.isDefault = isDefault;
    return fn_decl;
}

/// `val name = #[...] fn(params) -> R { body }` — val-form annotated function.
pub fn parseFnDeclFromVal(this: *This, alloc: std.mem.Allocator) ParseError!FnDecl {
    const isPub = this.match(.@"pub");
    _ = try this.consume(.val);
    const nameTok: Token = if (this.check(.identifier) or this.check(.@"test"))
        this.advance()
    else
        try this.consume(.identifier);
    const name = nameTok.lexeme;
    _ = try this.consume(.equal);
    const annotations = try this.parseAnnotations(alloc);
    errdefer {
        for (annotations) |*ann| ann.deinit(alloc);
        alloc.free(annotations);
    }
    if (this.check(.star) and this.peekAt(1).kind == .@"fn") {
        return failDeprecatedStarFn(this);
    }
    _ = try this.consume(.@"fn");
    return this.parseFnBody(alloc, name, isPub, false, annotations);
}

/// Records the `deprecated-star-fn` diagnostic at the current `*` token and
/// returns a parse error. Hard-removed in v0.beta.19; v0.beta.12 was the
/// deprecation window. The carets cover `*fn` (3 chars).
fn failDeprecatedStarFn(this: *This) ParseError {
    const tok = this.peek();
    this.parseError = ParseErrorInfo.fromTokenSpan(.deprecatedStarFn, tok, "*fn".len);
    return ParseError.UnexpectedToken;
}

pub fn parseFnBody(
    this: *This,
    alloc: std.mem.Allocator,
    name: []const u8,
    isPub: bool,
    isDeclare: bool,
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

    // The `)` that just closed the parameter list — decision 33 (b)'s
    // diagnostic points at it, because "add `-> void`" means "right here".
    // Captured now: by the time the absence is known the cursor has walked on,
    // and `this.peek()` would be the NEXT declaration's first token.
    const closeParenTok = this.tokens[this.current - 1];

    var returnType: ?ast.TypeRef = null;
    // 06 N30 — where the return-type annotation starts, so an unknown type name
    // reds there instead of at the file.
    var returnTypeLoc: ast.Loc = .{ .line = 0, .col = 0 };
    var arrowOmitted = false;
    var typeGuardParam: ?[]const u8 = null;
    var typeGuardType: ?ast.TypeRef = null;
    if (this.match(.rightArrow)) {
        // Type guard: `-> param is NarrowedType`. 06 C5 — the narrowed type goes
        // in its own slot and the fn returns `bool`, which is what a guard
        // answers; parking `T` in `returnType` typed every call as `T`.
        if (this.check(.identifier) and this.peekAt(1).kind == .is) {
            typeGuardParam = this.advance().lexeme;
            _ = try this.consume(.is);
            returnTypeLoc = parser.Parser.locFromToken(this.peek());
            typeGuardType = try this.parseTypeRef(alloc);
            returnType = .{ .named = "bool" };
        } else {
            returnTypeLoc = parser.Parser.locFromToken(this.peek());
            returnType = try this.parseTypeRef(alloc);
        }
    } else if (!this.check(.leftBrace) and !this.check(.semicolon) and
        !this.check(.colon) and !this.check(.endOfFile) and
        isTypeStart(this.peek().kind) and
        // A `fn` that is not followed by `(` opens the NEXT declaration, not a
        // `fn(…) -> R` type. Without this the shortform swallowed it and the
        // missing return type was reported at the next declaration's `fn`
        // (decision 33 (b) wants it at the `)` this one just closed).
        !(this.check(.@"fn") and this.peekAt(1).kind != .leftParenthesis))
    {
        // `.d.bp`-style shortform: `fn name(params) Type` with no `->` and no
        // body — implicit declaration. The arrow-less form is the convention
        // in `libs/std/src/builtins.d.bp` (`fn typeOf<T>(val: T) type`,
        // `fn min<T>(a: T, b: T) T`). Treat as a bodyless `declare fn`.
        returnTypeLoc = parser.Parser.locFromToken(this.peek());
        returnType = try this.parseTypeRef(alloc);
        arrowOmitted = true;
    }
    errdefer if (returnType) |*rt| rt.deinit(alloc);

    // Optional generator/iterator label after the return type. Spec §1I
    // (`frente-b-rules-tooling.md`) extends the form from `#[@generator]` to
    // `#[@resultGenerator]` / `#[@futureGenerator]` — both can declare a label that a
    // nested `yield :label …` / `break :label …` then targets. The parser
    // accepts the form on any fn; the comptime body walk validates that the
    // label is only consumed inside a yielding effect.
    var label: ?[]const u8 = null;
    if (this.check(.colon)) {
        _ = this.advance();
        label = (try this.consume(.identifier)).lexeme;
    }

    // R5 (§2) — at most one builtin `#[@<effect>]` annotation per fn.
    if (firstDuplicateEffect(annotations)) |dup| {
        // 01 R9 — the caret is on the second annotation, not on the body.
        const tok = annotationHashToken(this, dup.loc) orelse this.peek();
        this.parseError = ParseErrorInfo.fromTokenDetail(.effectDuplicateAnnotation, tok, dup.name);
        return ParseError.UnexpectedToken;
    }

    // A `#[@<effect>]` annotation names the function's effect directly. (The
    // deprecated `*fn` prefix used to derive it; v0.beta.19 hard-removed that
    // path — see the `deprecatedStarFn` diagnostic.)
    const effect = effectFromAnnotations(annotations);

    // R1 (§2) — an effect annotation marks an implementation (a fn with a
    // body); `declare fn` expresses the effect through the return wrapper
    // alone. A `#[@<effect>] declare fn …` mixes the two surfaces, so reject.
    //
    // §A3 EXCEPTION — `#[@result] declare fn` / `#[@future] declare fn` are
    // accepted when at least one `@external` annotation is present: the host
    // template owns the wrapper shape (a JS `{ok,V}` object for `@result`, a
    // Promise/native-future for `@future`), so the marker signals "this
    // declare carries effect-wrapping at the host boundary" rather than
    // pretending to wrap a body. All other effects stay rejected on declare
    // fn (R1 is the contract: effect annotations gate IMPLEMENTATIONS).
    if (isDeclare and effect != null and !this.check(.leftBrace)) {
        const isTemplateOwned =
            (effect.? == .result or effect.? == .future) and
            hasAnyExternalAnnotation(annotations);
        if (!isTemplateOwned) {
            const tok = this.peek();
            this.parseError = ParseErrorInfo.fromTokenDetail(.effectOnDeclareForbidden, tok, effect.?.annotationName());
            return ParseError.UnexpectedToken;
        }
    }

    // Decision 33 (b) — a declaration without a body says what it answers,
    // even when the answer is nothing. `fn f(x: string)` with no body and no
    // return type at all is refused HERE, at the token a body would have
    // opened at, instead of failing several tokens later as `Unexpected token`
    // on the NEXT declaration. `declare fn f(x);` keeps its own contract and
    // is not this rule's.
    if (!isDeclare and returnType == null and typeGuardType == null and
        !this.check(.leftBrace))
    {
        this.parseError = ParseErrorInfo.fromToken(.bodylessFnNeedsReturnType, closeParenTok);
        return ParseError.UnexpectedToken;
    }

    // A `declare fn` omits its body — it is typed from the signature alone.
    // `@[external(…)]` fns must use this form (validated in inference). A
    // bodyless fn that DOES declare its return type is the same thing, whether
    // it writes the arrow (`fn f(x) -> void`, decision 33's spelling) or omits
    // it (`fn name(params) Type`, the `.d.bp` shortform) — promote both to
    // `isDeclare = true` here. The arrowed form used to be a parse error,
    // which made decision 33's own remedy unwritable.
    if ((isDeclare or (returnType != null and !this.check(.leftBrace))) and
        !this.check(.leftBrace))
    {
        _ = this.match(.semicolon);
        return FnDecl{
            .isPub = isPub,
            .effect = effect,
            .isDeclare = true,
            .label = label,
            .name = name,
            .annotations = annotations,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .returnTypeLoc = returnTypeLoc,
            .typeGuardParam = typeGuardParam,
            .typeGuardType = typeGuardType,
            .body = &.{},
        };
    }

    const body = try this.parseFnBodyInBraces(alloc);

    return FnDecl{
        .isPub = isPub,
        .effect = effect,
        .isDeclare = isDeclare,
        .label = label,
        .name = name,
        .annotations = annotations,
        .genericParams = genericParams,
        .params = params,
        .returnType = returnType,
        .returnTypeLoc = returnTypeLoc,
        .typeGuardParam = typeGuardParam,
        .typeGuardType = typeGuardType,
        .body = body,
    };
}

/// The effect named by a builtin `#[@<effect>]` annotation in `annotations`,
/// or null when none is present.
fn effectFromAnnotations(annotations: []const Annotation) ?ast.EffectKind {
    for (annotations) |a| {
        if (a.is_builtin) {
            if (ast.EffectKind.fromAnnotationName(a.name)) |k| return k;
        }
    }
    return null;
}

/// §A3 — true when at least one `#[@External.<targert>(...)]` annotation is present.
/// Used by R1 to admit `#[@result] declare fn` only when a host template
/// owns the wrapper shape; effect-only declares stay rejected.
fn hasAnyExternalAnnotation(annotations: []const Annotation) bool {
    for (annotations) |a| {
        if (a.is_builtin and std.mem.startsWith(u8, a.name, "External.") and a.name.len > "External.".len) return true;
    }
    return false;
}

/// Returns the *second* effect annotation's name when `annotations` carries two
/// or more builtin `#[@<effect>]` markers, or null when at most one is present.
/// Drives R5 (§2): `#[@result] #[@future] fn x()` reds with
/// `effect-duplicate-annotation`.
fn firstDuplicateEffect(annotations: []const Annotation) ?Annotation {
    var seen: ?ast.EffectKind = null;
    for (annotations) |a| {
        if (!a.is_builtin) continue;
        const k = ast.EffectKind.fromAnnotationName(a.name) orelse continue;
        if (seen != null) return a;
        seen = k;
    }
    return null;
}

/// The `#` that opens the annotation whose name starts at `nameLoc` — the
/// last `#` on that line before it. Null when the annotation was synthesised.
fn annotationHashToken(this: *This, nameLoc: ?ast.Loc) ?token.Token {
    const l = nameLoc orelse return null;
    var found: ?token.Token = null;
    for (this.tokens[0..this.current]) |t| {
        if (t.kind == .hash and t.line == l.line and t.col < l.col) found = t;
    }
    return found;
}

/// `test { body }` / `test "name" { body }` — top-level test declaration.
/// The optional string literal names the test; the body is a normal stmt block.
pub fn parseTestDecl(this: *This, alloc: std.mem.Allocator) ParseError!ast.TestDecl {
    const testTok = try this.consume(.@"test");
    var name: ?[]const u8 = null;
    if (this.check(.stringLiteral)) {
        const tok = this.advance();
        name = tok.lexeme[1 .. tok.lexeme.len - 1];
    }
    const body = try this.parseFnBodyInBraces(alloc);
    return ast.TestDecl{
        .name = name,
        .loc = locFromToken(testTok),
        .body = body,
    };
}

/// `val log = declare fn(self: Self) -> R`
pub fn parseDelegateDecl(this: *This, alloc: std.mem.Allocator) ParseError!DelegateDecl {
    const isPub = this.match(.@"pub");
    _ = try this.consume(.val);
    const name = (try this.consume(.identifier)).lexeme;
    _ = try this.consume(.equal);
    _ = try this.consume(.declare);
    _ = try this.consume(.@"fn");
    return this.parseDelegateParams(alloc, name, isPub);
}

/// `[pub] declare fn log(self: Self) -> R`
pub fn parseShorthandDelegateDecl(this: *This, alloc: std.mem.Allocator) ParseError!DelegateDecl {
    const isPub = this.match(.@"pub");
    _ = try this.consume(.declare);
    _ = try this.consume(.@"fn");
    const name = (try this.consume(.identifier)).lexeme;
    return this.parseDelegateParams(alloc, name, isPub);
}

pub fn parseDelegateParams(this: *This, alloc: std.mem.Allocator, name: []const u8, isPub: bool) ParseError!DelegateDecl {
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

/// Parses an optional `extends T1, T2, T3` clause.
/// Returns an owned slice (may be empty). The caller owns the memory.
pub fn parseExtendsClause(this: *This, alloc: std.mem.Allocator) ParseError![]const []const u8 {
    if (!this.match(.extends)) return &.{};
    var list: std.ArrayList([]const u8) = .empty;
    errdefer list.deinit(alloc);
    try list.append(alloc, (try this.consume(.identifier)).lexeme);
    while (this.match(.comma)) {
        try list.append(alloc, (try this.consume(.identifier)).lexeme);
    }
    return list.toOwnedSlice(alloc);
}

/// Parse a method inside a struct, record, or enum body.
/// `is_declare fn ` → abstract slot (no body, `is_declare = true`).
/// Plain `fn` → always requires a body.
pub fn parseMethodDecl(this: *This, alloc: std.mem.Allocator, is_declare: bool, isPub: bool) ParseError!BehaviorMethod {
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
    var returnTypeLoc: ast.Loc = .{ .line = 0, .col = 0 }; // 06 N30
    if (this.match(.rightArrow)) {
        returnTypeLoc = parser.Parser.locFromToken(this.peek());
        returnType = try this.parseTypeRef(alloc);
    }
    errdefer if (returnType) |*rt| rt.deinit(alloc);

    if (is_declare) {
        _ = try this.consume(.semicolon);
        return BehaviorMethod{
            .name = name,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .returnTypeLoc = returnTypeLoc,
            .body = null,
            .is_default = false,
            .is_declare = true,
            .isPub = isPub,
        };
    }

    const body = try this.parseMethodBodyStmts(alloc);
    return BehaviorMethod{
        .name = name,
        .genericParams = genericParams,
        .params = params,
        .returnType = returnType,
        .returnTypeLoc = returnTypeLoc,
        .body = body,
        .is_default = false,
        .is_declare = false,
        .isPub = isPub,
    };
}

/// Explicit form: `pub? val Name = implement Iface, … for Type { fn … }`.
pub fn parseImplementDecl(this: *This, alloc: std.mem.Allocator) ParseError!ImplementDecl {
    const isPub = this.match(.@"pub");
    _ = try this.consume(.val);
    const name = (try this.consume(.identifier)).lexeme;
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    _ = try this.consume(.equal);
    return this.parseImplementBody(alloc, name, isPub, false, genericParams);
}

/// Shorthand form: `pub? Name implement Iface, … for Type { fn … }`.
pub fn parseShorthandImplementDecl(this: *This, alloc: std.mem.Allocator) ParseError!ImplementDecl {
    const isPub = this.match(.@"pub");
    const name = (try this.consume(.identifier)).lexeme;
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    return this.parseImplementBody(alloc, name, isPub, true, genericParams);
}

/// Parses `implement Iface, … for Type { fn … }` starting at the `implement`
/// keyword. The name / pub / generic params / form were consumed by the caller.
pub fn parseImplementBody(
    this: *This,
    alloc: std.mem.Allocator,
    name: []const u8,
    isPub: bool,
    shorthand: bool,
    genericParams: []GenericParam,
) ParseError!ImplementDecl {
    _ = try this.consume(.implement);

    // Interfaces are full type refs so generic interfaces (`Iface<A, B>`,
    // `@Context<…>`) parse, not just bare identifiers.
    var interfaces: std.ArrayList(TypeRef) = .empty;
    errdefer {
        for (interfaces.items) |*t| t.deinit(alloc);
        interfaces.deinit(alloc);
    }

    try interfaces.append(alloc, try this.parseTypeRef(alloc));
    while (this.match(.comma)) {
        if (this.check(.@"for")) break;
        try interfaces.append(alloc, try this.parseTypeRef(alloc));
    }

    _ = try this.consume(.@"for");
    const target = (try this.consume(.identifier)).lexeme;

    const ifaceSlice = try interfaces.toOwnedSlice(alloc);
    errdefer {
        for (ifaceSlice) |*t| t.deinit(alloc);
        alloc.free(ifaceSlice);
    }
    const methods = try this.parseImplementMethods(alloc);

    return ImplementDecl{
        .name = name,
        .isPub = isPub,
        .shorthand = shorthand,
        .genericParams = genericParams,
        .interfaces = ifaceSlice,
        .target = target,
        .methods = methods,
    };
}

/// Explicit form: `pub? val Name = extend Type { fn … }`.
pub fn parseExtendDecl(this: *This, alloc: std.mem.Allocator) ParseError!ExtendDecl {
    const isPub = this.match(.@"pub");
    _ = try this.consume(.val);
    const name = (try this.consume(.identifier)).lexeme;
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    _ = try this.consume(.equal);
    return this.parseExtendBody(alloc, name, isPub, false, genericParams);
}

/// Shorthand form: `pub? Name extend Type { fn … }`.
pub fn parseShorthandExtendDecl(this: *This, alloc: std.mem.Allocator) ParseError!ExtendDecl {
    const isPub = this.match(.@"pub");
    const name = (try this.consume(.identifier)).lexeme;
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    return this.parseExtendBody(alloc, name, isPub, true, genericParams);
}

/// Parses `extend Type { fn … }` starting at the `extend` keyword.
pub fn parseExtendBody(
    this: *This,
    alloc: std.mem.Allocator,
    name: []const u8,
    isPub: bool,
    shorthand: bool,
    genericParams: []GenericParam,
) ParseError!ExtendDecl {
    _ = try this.consume(.extend);
    const target = (try this.consume(.identifier)).lexeme;
    const methods = try this.parseImplementMethods(alloc);
    return ExtendDecl{
        .name = name,
        .isPub = isPub,
        .shorthand = shorthand,
        .genericParams = genericParams,
        .target = target,
        .methods = methods,
    };
}

/// Parses a `{ fn … fn … }` block of method bodies shared by implement/extend.
pub fn parseImplementMethods(this: *This, alloc: std.mem.Allocator) ParseError![]ImplementMethod {
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
    return methods.toOwnedSlice(alloc);
}

pub fn parseImplementMethod(this: *This, alloc: std.mem.Allocator) ParseError!ImplementMethod {
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

/// Sets `parseError` for the current token and returns the canonical
/// `UnexpectedToken` ParseError. Used by enum-section diagnostics where the
/// offending token is the *next* one rather than a `consume` mismatch.
fn raiseUnexpected(this: *This, tok: Token) ParseError {
    this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, tok);
    return ParseError.UnexpectedToken;
}

/// A `//` comment written on the line the member just ended on — `Red, // warm`,
/// `x: i32, // horizontal`, `fn two(…) { … } // trailing`. Consumes and returns
/// it, or leaves the stream alone and returns null.
///
/// "Same line" is decided against the token just consumed, which is what tells a
/// trailing comment apart from the NEXT member's leading one. Without the test
/// every such comment is read as the next member's, where it says something
/// false about the program — and on the last member there is no next member, so
/// it used to be dropped.
fn takeTrailingComment(this: *This) ?[]const u8 {
    if (this.current == 0) return null;
    const tok = this.peek();
    if (tok.kind != .commentNormal and tok.kind != .commentDoc) return null;
    const prev = this.tokens[this.current - 1];
    const prevEnd = prev.line + std.mem.count(u8, prev.lexeme, "\n");
    if (tok.line != prevEnd) return null;
    _ = this.advance();
    return tok.lexeme;
}

/// Parses a single enum item — either a bare/payload variant or a section
/// (the latter when an identifier is followed by `{`). Returns whether the
/// item ended with a trailing comma. When `allow_numeric` is true, accepts
/// pure-digit tokens as variant names (sections only — top-level bodies set
/// it false).
fn parseEnumItem(
    this: *This,
    alloc: std.mem.Allocator,
    variants: *std.ArrayList(EnumVariant),
    sections: *std.ArrayList(parser.EnumSection),
    allow_numeric: bool,
    leading: []const []const u8,
) ParseError!bool {
    // The member's position in the body it is declared in. `variants` and
    // `sections` are two parallel slices, so the count of both together is the
    // running index the source wrote — which is the whole of what the two
    // `order` fields record.
    const order: u32 = @intCast(variants.items.len + sections.items.len);
    // Numeric variant leaf (inside a section).
    if (this.check(.numberLiteral)) {
        if (!allow_numeric) return raiseUnexpected(this, this.peek());
        const tok = this.advance();
        // Numeric variants cannot carry payload — they are terminal leaves.
        if (this.check(.leftParenthesis)) return raiseUnexpected(this, this.peek());
        // ES3 — section names must be identifiers (numeric names cannot open a section).
        if (this.check(.leftBrace)) return raiseUnexpected(this, this.peek());
        const consumed = this.match(.comma);
        try variants.append(alloc, .{
            .name = tok.lexeme,
            .fields = &.{},
            .numeric = true,
            .order = order,
            .comments = leading,
            .trailingComment = takeTrailingComment(this),
        });
        return consumed;
    }

    const head = try this.consume(.identifier);
    const itemName = head.lexeme;

    // Section: `Identifier { ... }`.
    if (this.check(.leftBrace)) {
        // §enum-sections F3 — ES1 (duplicate section name) + ES2 (section
        // name collides with a sibling bare/payload variant). Both are
        // hard parse errors because the resulting AST would carry two
        // entries pointing at the same name, leading to silent shadowing
        // at desugar time.
        for (sections.items) |existing| {
            if (std.mem.eql(u8, existing.name, itemName)) return raiseUnexpected(this, head);
        }
        for (variants.items) |existing| {
            if (std.mem.eql(u8, existing.name, itemName)) return raiseUnexpected(this, head);
        }
        _ = this.advance(); // consume '{'
        var sub_variants: std.ArrayList(EnumVariant) = .empty;
        errdefer {
            for (sub_variants.items) |*v| v.deinit(alloc);
            sub_variants.deinit(alloc);
        }
        var sub_sections: std.ArrayList(parser.EnumSection) = .empty;
        errdefer {
            for (sub_sections.items) |*s| s.deinit(alloc);
            sub_sections.deinit(alloc);
        }

        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const subLeading = try takeMemberComments(this, alloc);
            if (this.check(.rightBrace) or this.check(.endOfFile)) {
                alloc.free(subLeading);
                break;
            }
            _ = try parseEnumItem(this, alloc, &sub_variants, &sub_sections, true, subLeading);
        }
        _ = try this.consume(.rightBrace);
        // Between sibling items inside the enclosing body, a comma is optional —
        // the closing brace already terminates the section.
        const consumed = this.match(.comma);
        try sections.append(alloc, .{
            .name = itemName,
            .variants = try sub_variants.toOwnedSlice(alloc),
            .sections = try sub_sections.toOwnedSlice(alloc),
            .order = order,
            .comments = leading,
        });
        return consumed;
    }

    // §enum-sections F3 — ES2 from the other direction: a bare/payload
    // variant whose name collides with an EARLIER section at the same
    // level. (The forward-collision direction — variant declared first,
    // then a section with the same name — is caught by the section-side
    // check above.)
    for (sections.items) |existing| {
        if (std.mem.eql(u8, existing.name, itemName)) return raiseUnexpected(this, head);
    }

    // Variant with payload: `Variant(field: T, ...)`.
    if (this.check(.leftParenthesis)) {
        _ = this.advance(); // consume '('
        var fields: std.ArrayList(Field) = .empty;
        errdefer {
            for (fields.items) |*f| f.deinit(alloc);
            fields.deinit(alloc);
        }

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            const fieldName = (try this.consume(.identifier)).lexeme;
            _ = try this.consume(.colon);
            const fieldTypeTok = this.peek();
            var fieldType = try this.parseTypeRef(alloc);
            errdefer fieldType.deinit(alloc);
            // Variant fields can carry a default just like record fields
            // or fn-decl params — unified `default: ?Expr` slot.
            var variantDefault: ?Expr = null;
            if (this.match(.equal)) {
                variantDefault = try this.parseBinaryExpr(alloc, prec.equality);
            }
            try fields.append(alloc, .{
                .name = fieldName,
                .typeRef = fieldType,
                .default = variantDefault,
                .typeLoc = parser.Parser.locFromToken(fieldTypeTok),
            });
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);

        const consumed = this.match(.comma);
        try variants.append(alloc, .{
            .name = itemName,
            .fields = try fields.toOwnedSlice(alloc),
            .order = order,
            .comments = leading,
            .trailingComment = takeTrailingComment(this),
        });
        return consumed;
    }

    // Bare variant.
    const consumed = this.match(.comma);
    try variants.append(alloc, .{
        .name = itemName,
        .fields = &.{},
        .order = order,
        .comments = leading,
        .trailingComment = takeTrailingComment(this),
    });
    return consumed;
}

/// Parses a single function/method parameter with optional modifier.
///
/// Grammar:
///   param          ::= record_destruct
///                    | param_name ['comptime'] ':' value_param
///
///   record_destruct ::= '{' ident (',' ident)* '}' ':' type_name
///   value_param     ::= ['syntax'] 'fn' '(' fn_param* ')' ('->' type_name)?
///                     | ['syntax'] type_name
///
/// The `comptime` keyword marks a compile-time param. It may appear:
///   - before the name:  `comptime name : type`  (stdlib / builtin style)
///   - after the name:   `name comptime : type`  (inline style)
///
/// The post-colon `syntax` keyword overrides the modifier to `.syntax`.
pub fn parseParam(this: *This, alloc: std.mem.Allocator) ParseError!Param {
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
            const field_name = try alloc.dupe(u8, (try this.consumeMemberName()).lexeme);
            const bind_name: []const u8 = if (this.match(.colon))
                try alloc.dupe(u8, (try this.consumeMemberName()).lexeme)
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

    // ── comptime-prefixed form: `comptime name : type` ─────────────────
    if (this.check(.@"comptime")) {
        _ = this.advance(); // consume 'comptime'
        const name = (try this.consumeParamName()).lexeme;
        _ = try this.consume(.colon);
        const typeTok = this.peek();
        const typeRef = try this.parseTypeRef(alloc);
        return Param{
            .name = name,
            .typeRef = typeRef,
            .modifier = .@"comptime",
            .typeLoc = parser.Parser.locFromToken(typeTok),
        };
    }

    // ── regular param: name ['comptime'] ':' ['syntax'] type_expr ───────────
    const nameTok = try this.consumeParamName();
    const name = nameTok.lexeme;
    // Optional post-name, pre-colon modifier.
    var modifier: ParamModifier = .none;
    if (this.match(.@"comptime")) modifier = .@"comptime";

    // Type annotation is required.
    _ = try this.consume(.colon);

    // Detect post-colon modifiers: `syntax` or `comptime`
    if (this.match(.syntax)) modifier = .syntax else if (this.match(.@"comptime")) modifier = .@"comptime";

    // ── fn-type params: `name comptime: syntax fn(...)` ─────────────────────
    // The legacy `FnType` representation (named string params + named return)
    // is kept only for `syntax` params, whose template machinery reads it. A
    // plain `name: fn(...)` falls through to the general `parseTypeRef` below,
    // which yields a `TypeRef.function` and supports array/optional/nested
    // returns (`fn() -> T[]`).
    if (modifier == .syntax and this.check(.@"fn")) {
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
    // 06 N30 — where the annotation starts, so an unknown type name reds there.
    const typeTok = this.peek();
    var typeRef = try this.parseTypeRef(alloc);
    // Meta-kind params (`type`) only exist at compile time — require the
    // `comptime` modifier so the binding-time is visible in the signature.
    // (`@Expr<…>` params get the same rule as a semantic check in inference.)
    if (typeRef == .typeparam and modifier != .@"comptime") {
        typeRef.deinit(alloc);
        this.parseError = ParseErrorInfo.fromToken(.metaKindRequiresComptime, nameTok);
        return ParseError.UnexpectedToken;
    }
    // Optional default value: `name: Type = <expr>` — unified with record
    // field defaults (same parser entry, same AST slot). Annotations,
    // record/enum/struct constructors, and fn calls all consume this as
    // their fallback for a missing trailing positional / named arg (see
    // infer.zig arity check; call-site auto-injection is gated behind the
    // `fn-param-default-expansion` follow-up spec).
    var defaultExpr: ?Expr = null;
    if (this.match(.equal)) {
        defaultExpr = try this.parseBinaryExpr(alloc, prec.equality);
    }
    return Param{
        .name = name,
        .typeRef = typeRef,
        .modifier = modifier,
        .default = defaultExpr,
        .typeLoc = parser.Parser.locFromToken(typeTok),
    };
}

// ── 1.0.3 surface: `type` and `behavior` (front 12 dual grammar) ──────────────
//
// Both spellings build the same nodes as `record`/`enum`/`interface`:
//   type Name<G>(fields) implement B { methods }       → TypeDecl, record shape
//   type Name<G> implement B { Variant, V(f: T), S { … }, methods } → enum shape
//   type Name { methods } / type Name                  → record with no fields
//   behavior Name<G> extends B { val x: T; fn f(self: Self); default fn … { } }
// Shape resolution and separators: specs/1.0.4-beta/12-surface-cutover/
// type-grammar.md and separators.md.

fn failAt(this: *This, kind: parser.ParseErrorType, tok: Token) ParseError {
    this.parseError = ParseErrorInfo.fromToken(kind, tok);
    return ParseError.UnexpectedToken;
}

/// True when the current token starts a member of a `type` body (a method,
/// optionally annotated) rather than a variant or section.
fn startsTypeMember(this: *This) bool {
    return this.check(.@"pub") or this.check(.@"fn") or this.check(.declare) or
        (this.check(.hash) and this.peekAt(1).kind == .leftSquareBracket);
}

pub const FieldList = struct {
    fields: []Field,
    trailingComma: bool,
};

/// `( field, field, … )` — the field list shared by `type Name(…)` and a
/// variant payload `Variant(…)`:
///   field := comment* annotation* Name ':' TypeRef ('=' Expr)?
/// Comments before a field are kept on it; a trailing comma is allowed.
pub fn parseFieldList(this: *This, alloc: std.mem.Allocator) ParseError!FieldList {
    const open = try this.consume(.leftParenthesis);
    var fields: std.ArrayList(Field) = .empty;
    errdefer {
        for (fields.items) |*f| f.deinit(alloc);
        fields.deinit(alloc);
    }
    var trailingComma = false;
    while (true) {
        var comments: std.ArrayList([]const u8) = .empty;
        errdefer {
            for (comments.items) |c| alloc.free(c);
            comments.deinit(alloc);
        }
        while (this.isComment()) {
            const c = this.advance();
            try comments.append(alloc, try alloc.dupe(u8, This.commentText(c.lexeme)));
        }
        if (this.check(.rightParenthesis) or this.check(.endOfFile)) {
            for (comments.items) |c| alloc.free(c);
            comments.deinit(alloc);
            break;
        }
        const annotations = try this.parseAnnotations(alloc);
        errdefer freeAnnotations(alloc, annotations);
        if (this.check(.val)) return failAt(this, .typeFieldValPrefix, this.peek());
        // Decision 12 — a field and a variant payload are `name: Type`, always.
        // Anything else in this position is an unnamed payload: the bare type
        // (`Circle(i32)`, `Circle(Point)`, `Circle(Box<i32>)`) and the forms
        // that cannot even start with a name (`Circle(?i32)`, `Circle(#(a, b))`)
        // alike. Refused here, where it starts, with the field form named —
        // reading past it would report the missing `:` as a stray token.
        if (!This.isMemberName(this.peek().kind) or this.peekAt(1).kind != .colon) {
            return failAt(this, .fieldNeedsName, this.peek());
        }
        const nameTok = try this.consumeMemberName();
        _ = try this.consume(.colon);
        const fieldTypeTok = this.peek();
        var fieldType = try this.parseTypeRef(alloc);
        errdefer fieldType.deinit(alloc);
        var default: ?Expr = null;
        if (this.match(.equal)) default = try this.parseBinaryExpr(alloc, prec.equality);
        const commentSlice = try comments.toOwnedSlice(alloc);
        try fields.append(alloc, .{
            .name = nameTok.lexeme,
            .typeRef = fieldType,
            .default = default,
            .annotations = annotations,
            .comments = commentSlice,
            .typeLoc = parser.Parser.locFromToken(fieldTypeTok),
        });
        trailingComma = this.match(.comma);
        // A `//` on the field's own line belongs to THIS field. Collected at the
        // top of the next iteration instead, it becomes the next field's leading
        // comment — and on the last field the loop meets `)` and frees it, which
        // is where a comment used to be destroyed outright.
        if (takeTrailingComment(this)) |c| {
            fields.items[fields.items.len - 1].trailingComment =
                try alloc.dupe(u8, This.commentText(c));
        }
        if (!trailingComma) break;
    }
    this.skipComments();
    if (fields.items.len == 0) return failAt(this, .typeEmptyFieldList, open);
    _ = try this.consume(.rightParenthesis);
    return .{ .fields = try fields.toOwnedSlice(alloc), .trailingComma = trailingComma };
}

/// Val-form: `[pub] val Name = #[…] type<G>(fields) implement B { … }`.
pub fn parseTypeDecl(this: *This, alloc: std.mem.Allocator) ParseError!TypeDecl {
    const p = try this.parseDeclPreamble(alloc, .type, false);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseTypeDeclRest(alloc, p.name, p.annotations, p.isPub);
}

/// Shorthand: `#[…] [pub] type Name<G>(fields) implement B { … }`.
pub fn parseShorthandTypeDecl(this: *This, alloc: std.mem.Allocator) ParseError!TypeDecl {
    const p = try this.parseDeclPreamble(alloc, .type, true);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseTypeDeclRest(alloc, p.name, p.annotations, p.isPub);
}

/// Everything after `type Name` (shorthand) or `type` (val-form): generic
/// parameters, the optional field list, the `implement` clause and the
/// optional body. Decides the shape from what it consumed (type-grammar.md
/// § Shape resolution).
pub fn parseTypeDeclRest(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!TypeDecl {
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);

    var fields: []Field = &.{};
    var hasFieldList = false;
    var fieldTrailingComma = false;
    errdefer {
        for (fields) |*f| f.deinit(alloc);
        if (fields.len > 0) alloc.free(fields);
    }
    if (this.check(.leftParenthesis)) {
        const fl = try parseFieldList(this, alloc);
        fields = fl.fields;
        fieldTrailingComma = fl.trailingComma;
        hasFieldList = true;
    }

    const implementList = try this.parseImplementClause(alloc);
    errdefer {
        for (implementList) |*im| @constCast(im).deinit(alloc);
        alloc.free(implementList);
    }

    var variants: std.ArrayList(EnumVariant) = .empty;
    errdefer {
        for (variants.items) |*v| v.deinit(alloc);
        variants.deinit(alloc);
    }
    var sections: std.ArrayList(parser.EnumSection) = .empty;
    errdefer {
        for (sections.items) |*s| s.deinit(alloc);
        sections.deinit(alloc);
    }
    var methods: std.ArrayList(BehaviorMethod) = .empty;
    errdefer {
        for (methods.items) |*m| m.deinit(alloc);
        methods.deinit(alloc);
    }

    var variantTrailingComma = false;
    var bodyComments: []const []const u8 = &.{};
    if (this.match(.leftBrace)) {
        var sawMethod = false;
        // A bare/payload variant not followed by `,` may only be the last item
        // before `}` or before a method.
        var needSeparator = false;
        while (true) {
            const memberComments = try takeMemberComments(this, alloc);
            if (this.check(.rightBrace) or this.check(.endOfFile)) {
                bodyComments = memberComments;
                break;
            }
            if (startsTypeMember(this)) {
                const memberAnnotations = try this.parseAnnotations(alloc);
                const is_pub = this.match(.@"pub");
                const is_declare = this.match(.declare);
                var method = this.parseMethodDecl(alloc, is_declare, is_pub) catch |err| {
                    freeAnnotations(alloc, memberAnnotations);
                    return err;
                };
                method.annotations = memberAnnotations;
                method.comments = memberComments;
                method.trailingComment = takeTrailingComment(this);
                try methods.append(alloc, method);
                sawMethod = true;
                needSeparator = false;
                if (this.check(.comma)) return failAt(this, .memberCommaSeparator, this.peek());
                continue;
            }
            const head = this.peek();
            if (sawMethod) return failAt(this, .typeVariantAfterMethod, head);
            if (hasFieldList) return failAt(this, .typeRecordWithVariants, head);
            if (needSeparator) return failAt(this, .unexpectedToken, head);
            const isSection = head.kind == .identifier and this.peekAt(1).kind == .leftBrace;
            // `memberComments` used to be dropped on the floor for anything
            // that was not a method, which is why a `//` above a variant
            // vanished: it was collected and then never given to anyone.
            const consumedComma = if (head.kind == .identifier and this.peekAt(1).kind == .leftParenthesis)
                try parsePayloadVariant(this, alloc, &variants, &sections, memberComments)
            else
                try parseEnumItem(this, alloc, &variants, &sections, false, memberComments);
            variantTrailingComma = consumedComma;
            needSeparator = !consumedComma and !isSection;
        }
        _ = try this.consume(.rightBrace);
    }

    const isEnum = variants.items.len > 0 or sections.items.len > 0;
    const shape: ast.TypeShape = if (isEnum)
        .{ .enum_ = .{
            .variants = try variants.toOwnedSlice(alloc),
            .sections = try sections.toOwnedSlice(alloc),
        } }
    else
        .{ .record = fields };
    if (isEnum) {
        // No field list on an enum (rejected above), so `fields` is empty.
        variants = .empty;
        sections = .empty;
    }
    const methodSlice = try methods.toOwnedSlice(alloc);
    return TypeDecl{
        .name = name,
        .id = this.nextId("type"),
        .isPub = isPub,
        .annotations = annotations,
        .genericParams = genericParams,
        .implement = implementList,
        .shape = shape,
        .trailingComma = if (isEnum) variantTrailingComma else fieldTrailingComma,
        .methods = methodSlice,
        .bodyComments = bodyComments,
    };
}

/// `Variant(field, …)` in a `type` body: the payload is the shared field list.
/// Returns whether the variant ended with `,`.
fn parsePayloadVariant(
    this: *This,
    alloc: std.mem.Allocator,
    variants: *std.ArrayList(EnumVariant),
    sections: *std.ArrayList(parser.EnumSection),
    leading: []const []const u8,
) ParseError!bool {
    const order: u32 = @intCast(variants.items.len + sections.items.len);
    const head = try this.consume(.identifier);
    for (sections.items) |existing| {
        if (std.mem.eql(u8, existing.name, head.lexeme)) return failAt(this, .unexpectedToken, head);
    }
    const fl = try parseFieldList(this, alloc);
    errdefer {
        for (fl.fields) |*f| f.deinit(alloc);
        alloc.free(fl.fields);
    }
    const consumed = this.match(.comma);
    try variants.append(alloc, .{
        .name = head.lexeme,
        .fields = fl.fields,
        .order = order,
        .comments = leading,
        .trailingComment = takeTrailingComment(this),
    });
    return consumed;
}

/// Val-form: `[pub] val Name = #[…] behavior extends B { … }`.
pub fn parseBehaviorDecl(this: *This, alloc: std.mem.Allocator) ParseError!BehaviorDecl {
    const p = try this.parseDeclPreamble(alloc, .behavior, false);
    errdefer freeAnnotations(alloc, p.annotations);
    const extendsSlice = try this.parseExtendsClause(alloc);
    return parseBehaviorBody(this, alloc, p.name, extendsSlice, p.annotations, p.isPub);
}

/// Shorthand: `#[…] [pub] behavior Name<G> extends B { … }`.
pub fn parseShorthandBehaviorDecl(this: *This, alloc: std.mem.Allocator) ParseError!BehaviorDecl {
    const p = try this.parseDeclPreamble(alloc, .behavior, true);
    errdefer freeAnnotations(alloc, p.annotations);
    // Generic parameters may follow the name (`behavior Stack<T> { … }`) or,
    // as with `interface`, the `extends` clause.
    const early = try this.parseGenericParams(alloc);
    errdefer alloc.free(early);
    const extendsSlice = try this.parseExtendsClause(alloc);
    var decl = try parseBehaviorBody(this, alloc, p.name, extendsSlice, p.annotations, p.isPub);
    if (early.len > 0) {
        if (decl.genericParams.len > 0) return failAt(this, .unexpectedToken, this.tokens[this.current - 1]);
        alloc.free(decl.genericParams);
        decl.genericParams = early;
    } else {
        alloc.free(early);
    }
    return decl;
}

/// A `behavior` body with the 1.0.3 separator rule: a bodyless member
/// (`val x: T`, `fn f(…) -> R`, `declare fn …`) ends with `;`; a member with a
/// body ends with `}`; `,` never separates members.
/// The comment lines before the next member of a `type`/`behavior` body, with
/// "" for each run of blank source lines (so the formatter can keep them).
fn takeMemberComments(this: *This, alloc: std.mem.Allocator) ParseError![]const []const u8 {
    var out: std.ArrayList([]const u8) = .empty;
    errdefer out.deinit(alloc);
    while (true) {
        const tok = this.peek();
        if (this.current > 0) {
            const prev = this.tokens[this.current - 1];
            const prevEnd = prev.line + std.mem.count(u8, prev.lexeme, "\n");
            if (tok.line > prevEnd + 1) try out.append(alloc, "");
        }
        if (tok.kind != .commentNormal and tok.kind != .commentDoc and tok.kind != .commentModule) break;
        _ = this.advance();
        try out.append(alloc, tok.lexeme);
    }
    return out.toOwnedSlice(alloc);
}

fn parseBehaviorBody(this: *This, alloc: std.mem.Allocator, name: []const u8, extendsSlice: []const []const u8, annotations: []Annotation, isPub: bool) ParseError!BehaviorDecl {
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    _ = try this.consume(.leftBrace);

    var fields: std.ArrayList(BehaviorField) = .empty;
    errdefer fields.deinit(alloc);
    var methods: std.ArrayList(BehaviorMethod) = .empty;
    errdefer {
        for (methods.items) |*m| m.deinit(alloc);
        methods.deinit(alloc);
    }

    var bodyComments: []const []const u8 = &.{};
    while (true) {
        const memberComments = try takeMemberComments(this, alloc);
        if (this.check(.rightBrace) or this.check(.endOfFile)) {
            bodyComments = memberComments;
            break;
        }
        if (this.check(.val) or (this.check(.@"pub") and this.peekAt(1).kind == .val)) {
            _ = this.match(.@"pub");
            _ = try this.consume(.val);
            const fieldName = (try this.consume(.identifier)).lexeme;
            _ = try this.consume(.colon);
            const typeName = (try this.consume(.identifier)).lexeme;
            try expectMemberSemicolon(this);
            try fields.append(alloc, .{ .name = fieldName, .typeName = typeName, .comments = memberComments });
        } else if (this.check(.default) or this.check(.@"fn") or this.check(.declare) or
            this.check(.hash) or (this.check(.at) and this.peekAt(1).kind == .leftSquareBracket))
        {
            const memberAnnotations = try this.parseAnnotations(alloc);
            if (effectFromAnnotations(memberAnnotations)) |k| {
                freeAnnotations(alloc, memberAnnotations);
                const tok = this.peek();
                this.parseError = ParseErrorInfo.fromTokenDetail(.effectOnBehaviorMethodForbidden, tok, k.annotationName());
                return ParseError.UnexpectedToken;
            }
            const is_default = this.match(.default);
            const is_declare = this.match(.declare);
            var method = parseBehaviorMethod(this, alloc, is_default) catch |err| {
                freeAnnotations(alloc, memberAnnotations);
                return err;
            };
            method.annotations = memberAnnotations;
            method.is_declare = is_declare;
            method.comments = memberComments;
            method.trailingComment = takeTrailingComment(this);
            try methods.append(alloc, method);
        } else {
            return failAt(this, .unexpectedToken, this.peek());
        }
    }
    _ = try this.consume(.rightBrace);

    return BehaviorDecl{
        .name = name,
        .id = this.nextId("behavior"),
        .isPub = isPub,
        .annotations = annotations,
        .genericParams = genericParams,
        .extends = extendsSlice,
        .fields = try fields.toOwnedSlice(alloc),
        .trailingComma = false,
        .methods = try methods.toOwnedSlice(alloc),
        .bodyComments = bodyComments,
    };
}

/// `;` after a bodyless behavior member; `,` there is `member-comma-separator`,
/// anything else `member-missing-semicolon` (located at the member's last token).
fn expectMemberSemicolon(this: *This) ParseError!void {
    if (this.match(.semicolon)) return;
    if (this.check(.comma)) return failAt(this, .memberCommaSeparator, this.peek());
    return failAt(this, .memberMissingSemicolon, this.tokens[this.current - 1]);
}

/// One `fn` member of a `behavior`: a signature ending with `;`, or — for a
/// `default fn` — a body ending with `}` (no separator after it).
fn parseBehaviorMethod(this: *This, alloc: std.mem.Allocator, is_default: bool) ParseError!BehaviorMethod {
    _ = try this.consume(.@"fn");
    const methodName = (try this.consume(.identifier)).lexeme;
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    _ = try this.consume(.leftParenthesis);
    const params = try this.parseParamList(alloc);
    errdefer {
        for (params) |*p| p.deinit(alloc);
        alloc.free(params);
    }
    var returnType: ?ast.TypeRef = null;
    var returnTypeLoc: ast.Loc = .{ .line = 0, .col = 0 }; // 06 N30
    if (this.match(.rightArrow)) {
        returnTypeLoc = parser.Parser.locFromToken(this.peek());
        returnType = try this.parseTypeRef(alloc);
    }
    errdefer if (returnType) |*rt| rt.deinit(alloc);

    if (!is_default) {
        try expectMemberSemicolon(this);
        return BehaviorMethod{
            .name = methodName,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .returnTypeLoc = returnTypeLoc,
            .body = null,
            .is_default = false,
        };
    }
    const body = try this.parseSimpleBodyStmts(alloc);
    if (this.check(.comma)) return failAt(this, .memberCommaSeparator, this.peek());
    return BehaviorMethod{
        .name = methodName,
        .genericParams = genericParams,
        .params = params,
        .returnType = returnType,
        .returnTypeLoc = returnTypeLoc,
        .body = body,
        .is_default = true,
    };
}

// ── type alias ────────────────────────────────────────────────────────────────

/// True when a type alias starts at `offset`: `[pub] type Name [<…>] =`. The
/// generic list is skipped by bracket depth, so a `=` inside it (a default,
/// refused by `parseTypeAliasDecl`) does not end the lookahead. Pure lookahead.
pub fn isTypeAliasAt(this: *This, offset: usize) bool {
    var i = offset;
    if (this.peekAt(i).kind == .@"pub") i += 1;
    if (this.peekAt(i).kind != .type) return false;
    i += 1;
    if (this.peekAt(i).kind != .identifier) return false;
    i += 1;
    if (this.peekAt(i).kind == .lessThan) {
        var depth: usize = 0;
        while (true) : (i += 1) {
            switch (this.peekAt(i).kind) {
                .lessThan => depth += 1,
                .greaterThan => {
                    depth -= 1;
                    if (depth == 0) break;
                },
                .endOfFile, .leftBrace, .rightBrace, .semicolon => return false,
                else => {},
            }
        }
        i += 1;
    }
    return this.peekAt(i).kind == .equal;
}

/// `[pub] type Name<A, B> = Target;` (decision 118 rule 1). The parameters are
/// plain names — a default is `type-alias-generic-default` — and the `;` is
/// required: the target is a type, which has no closing token of its own.
pub fn parseTypeAliasDecl(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeAliasDecl {
    const isPub = this.match(.@"pub");
    const kw = try this.consume(.type);
    const name = (try this.consume(.identifier)).lexeme;
    const genericParams = try parseTypeAliasParams(this, alloc);
    errdefer alloc.free(genericParams);
    _ = try this.consume(.equal);
    const targetTok = this.peek();
    var target = try this.parseTypeRef(alloc);
    errdefer target.deinit(alloc);
    _ = try this.consume(.semicolon);
    return .{
        .name = name,
        .isPub = isPub,
        .genericParams = genericParams,
        .target = target,
        .loc = locFromToken(kw),
        .targetLoc = locFromToken(targetTok),
    };
}

/// `<A, B>` after an alias's name: plain names only. A default (`<T = i32>`)
/// is `type-alias-generic-default` at its `=`.
fn parseTypeAliasParams(this: *This, alloc: std.mem.Allocator) ParseError![]GenericParam {
    var list: std.ArrayList(GenericParam) = .empty;
    errdefer list.deinit(alloc);
    if (!this.match(.lessThan)) return list.toOwnedSlice(alloc);
    while (!this.check(.greaterThan) and !this.check(.endOfFile)) {
        const nameTok = try this.consume(.identifier);
        if (this.check(.equal)) return failAt(this, .typeAliasGenericDefault, this.peek());
        try list.append(alloc, .{ .name = nameTok.lexeme });
        if (!this.match(.comma)) break;
    }
    _ = try this.consume(.greaterThan);
    return list.toOwnedSlice(alloc);
}
