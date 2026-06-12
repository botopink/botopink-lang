//! Declaration sub-grammar extracted from `parser.zig`: val/fn/struct/
//! record/enum/interface/implement/extend/delegate/import decls + params.
//! Free functions on `*Parser`; `parser.zig` re-exports each as a thin alias.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");
const token = @import("../lexer/token.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const ImportDecl = parser.ImportDecl;
const ImportSource = parser.ImportSource;
const ImportPath = parser.ImportPath;
const InterfaceDecl = parser.InterfaceDecl;
const InterfaceField = parser.InterfaceField;
const InterfaceMethod = parser.InterfaceMethod;
const StructDecl = parser.StructDecl;
const StructMember = parser.StructMember;
const StructField = parser.StructField;
const StructGetter = parser.StructGetter;
const StructSetter = parser.StructSetter;
const Param = parser.Param;
const Stmt = parser.Stmt;
const Expr = parser.Expr;
const RecordDecl = parser.RecordDecl;
const RecordField = parser.RecordField;
const ImplementDecl = parser.ImplementDecl;
const ExtendDecl = parser.ExtendDecl;
const ImplementMethod = parser.ImplementMethod;
const DeclKind = parser.DeclKind;
const GenericParam = parser.GenericParam;
const ParamModifier = parser.ParamModifier;
const EnumDecl = parser.EnumDecl;
const EnumVariant = parser.EnumVariant;
const EnumVariantField = parser.EnumVariantField;
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

/// Parses `param, param, ...` up to and including `)`.
/// The caller must have already consumed the opening `(`.
pub fn parseParamList(this: *This, alloc: std.mem.Allocator) ParseError![]Param {
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

pub fn parseValDecl(this: *This, alloc: std.mem.Allocator) ParseError!ValDecl {
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
    if (!this.check(.identifier)) return paths.toOwnedSlice(alloc);
    try paths.append(alloc, try this.parseImportItem(alloc));
    while (this.match(.comma)) {
        if (this.check(.rightBrace)) break;
        try paths.append(alloc, try this.parseImportItem(alloc));
    }
    return paths.toOwnedSlice(alloc);
}

/// `dottedPath "*"? ("as" ident)?` — one import item.
pub fn parseImportItem(this: *This, alloc: std.mem.Allocator) ParseError!ImportPath {
    var segs: std.ArrayList([]const u8) = .empty;
    errdefer segs.deinit(alloc);
    try segs.append(alloc, (try this.consume(.identifier)).lexeme);
    while (this.match(.dot)) {
        try segs.append(alloc, (try this.consume(.identifier)).lexeme);
    }
    const activate = this.match(.star);
    const alias: ?[]const u8 = if (this.match(.as))
        (try this.consume(.identifier)).lexeme
    else
        null;
    return ImportPath{
        .segments = try segs.toOwnedSlice(alloc),
        .activate = activate,
        .alias = alias,
    };
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
    // `*fn` — async / generator marker. The leading `*` makes the function
    // return an `@Future`/`@Iterator` and enables `await`/`yield` in the body.
    const isStarFn = this.match(.star);
    _ = try this.consume(.@"fn");
    const name = (try this.consume(.identifier)).lexeme;
    var fn_decl = try this.parseFnBody(alloc, name, isPub, isDeclare, annotations, isStarFn);
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
    const isStarFn = this.match(.star);
    _ = try this.consume(.@"fn");
    return this.parseFnBody(alloc, name, isPub, false, annotations, isStarFn);
}

pub fn parseFnBody(
    this: *This,
    alloc: std.mem.Allocator,
    name: []const u8,
    isPub: bool,
    isDeclare: bool,
    annotations: []Annotation,
    isStarFn: bool,
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

    // Optional generator label after the return type: `-> @Iterator<T> :gen`.
    var label: ?[]const u8 = null;
    if (this.check(.colon)) {
        _ = this.advance();
        label = (try this.consume(.identifier)).lexeme;
    }

    // A `*fn` must have a body — `*fn` is sugar for an async/generator
    // function, not a declaration. (Bodyless functions use `declare fn`.)
    if (isStarFn and !this.check(.leftBrace)) {
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

    // The function's effect: a `#[@<effect>]` annotation names it directly; the
    // deprecated `*` prefix derives it from the return wrapper (mapped below).
    const annEffect = effectFromAnnotations(annotations);

    // A `declare fn` omits its body — it is typed from the signature alone.
    // `@[external(…)]` fns must use this form (validated in inference).
    if (isDeclare and !this.check(.leftBrace)) {
        _ = this.match(.semicolon);
        return FnDecl{
            .isPub = isPub,
            .effect = annEffect, // `*fn` requires a body, so only an annotation applies here
            .isDeclare = true,
            .label = label,
            .name = name,
            .annotations = annotations,
            .genericParams = genericParams,
            .params = params,
            .returnType = returnType,
            .body = &.{},
        };
    }

    const body = try this.parseStmtListInBraces(alloc);

    const effect: ?ast.EffectKind = annEffect orelse
        (if (isStarFn) ast.EffectKind.fromStarReturn(returnType, body) else null);

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

/// `test { body }` / `test "name" { body }` — top-level test declaration.
/// The optional string literal names the test; the body is a normal stmt block.
pub fn parseTestDecl(this: *This, alloc: std.mem.Allocator) ParseError!ast.TestDecl {
    const testTok = try this.consume(.@"test");
    var name: ?[]const u8 = null;
    if (this.check(.stringLiteral)) {
        const tok = this.advance();
        name = tok.lexeme[1 .. tok.lexeme.len - 1];
    }
    const body = try this.parseStmtListInBraces(alloc);
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

pub fn parseInterfaceDecl(this: *This, alloc: std.mem.Allocator) ParseError!InterfaceDecl {
    // val-form: the `extends` clause (if any) follows the `interface` keyword.
    const p = try this.parseDeclPreamble(alloc, .interface, false);
    errdefer freeAnnotations(alloc, p.annotations);
    const extendsSlice = try this.parseExtendsClause(alloc);
    return this.parseInterfaceBody(alloc, p.name, extendsSlice, p.annotations, p.isPub);
}

pub fn parseShorthandInterfaceDecl(this: *This, alloc: std.mem.Allocator) ParseError!InterfaceDecl {
    // shorthand: the `extends` clause (if any) follows the interface name.
    const p = try this.parseDeclPreamble(alloc, .interface, true);
    errdefer freeAnnotations(alloc, p.annotations);
    const extendsSlice = try this.parseExtendsClause(alloc);
    return this.parseInterfaceBody(alloc, p.name, extendsSlice, p.annotations, p.isPub);
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

pub fn parseInterfaceBody(this: *This, alloc: std.mem.Allocator, name: []const u8, extendsSlice: []const []const u8, annotations: []Annotation, isPub: bool) ParseError!InterfaceDecl {
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
        this.skipComments();
        if (this.check(.rightBrace) or this.check(.endOfFile)) break;
        if (this.check(.val)) {
            _ = this.match(.@"pub");
            _ = try this.consume(.val);
            const fieldName = (try this.consume(.identifier)).lexeme;
            _ = try this.consume(.colon);
            const typeName = (try this.consume(.identifier)).lexeme;
            trailingComma = this.match(.comma);
            try fields.append(alloc, .{ .name = fieldName, .typeName = typeName });
        } else if (this.check(.default) or this.check(.@"fn") or this.check(.declare) or
            this.check(.hash) or (this.check(.at) and this.peekAt(1).kind == .leftSquareBracket))
        {
            // `default fn … { body }` (default method), `declare fn …;`
            // (abstract/host-backed member), optionally preceded by an
            // `@[external(…)]` annotation block.
            const memberAnnotations = try this.parseAnnotations(alloc);
            const is_default = this.match(.default);
            const is_declare = this.match(.declare);
            var method = try this.parseInterfaceMethod(alloc, is_default);
            method.annotations = memberAnnotations;
            method.is_declare = is_declare;
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

pub fn parseInterfaceMethod(this: *This, alloc: std.mem.Allocator, is_default: bool) ParseError!InterfaceMethod {
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
pub fn parseMethodDecl(this: *This, alloc: std.mem.Allocator, is_declare: bool, isPub: bool) ParseError!InterfaceMethod {
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

pub fn parseStructDecl(this: *This, alloc: std.mem.Allocator) ParseError!StructDecl {
    const p = try this.parseDeclPreamble(alloc, .@"struct", false);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseStructBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseShorthandStructDecl(this: *This, alloc: std.mem.Allocator) ParseError!StructDecl {
    const p = try this.parseDeclPreamble(alloc, .@"struct", true);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseStructBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseStructBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!StructDecl {
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    const implementList = try this.parseImplementClause(alloc);
    errdefer {
        for (implementList) |*im| @constCast(im).deinit(alloc);
        alloc.free(implementList);
    }
    _ = try this.consume(.leftBrace);

    var members: std.ArrayList(StructMember) = .empty;
    errdefer {
        for (members.items) |*m| m.deinit(alloc);
        members.deinit(alloc);
    }

    var trailingComma = false;
    while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
        // Member-level decorators: `#[getMapping("/")] fn handler(…)`. Parsed
        // here so annotation processors reach struct methods (field/getter/setter
        // sites are a follow-up — only `InterfaceMethod` carries annotations).
        const memberAnnotations = try this.parseAnnotations(alloc);
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
                // Reuse the full type-ref parser (same as record fields) so
                // array-typed (`E[]`), optional, and generic fields parse.
                const fieldName = (try this.consume(.identifier)).lexeme;
                _ = try this.consume(.colon);
                var fieldType = try this.parseTypeRef(alloc);
                errdefer fieldType.deinit(alloc);
                var initExpr: ?Expr = null;
                if (this.match(.equal)) {
                    initExpr = try this.parseExpr(alloc);
                }
                trailingComma = this.match(.comma);
                try members.append(alloc, .{ .field = .{
                    .name = fieldName,
                    .typeRef = fieldType,
                    .init = initExpr,
                    .annotations = memberAnnotations,
                } });
                continue;
            }
        }

        if (this.check(.get)) {
            if (memberAnnotations.len > 0) return ParseError.UnexpectedToken;
            const getter = try this.parseStructGetter(alloc);
            trailingComma = this.match(.comma);
            try members.append(alloc, .{ .getter = getter });
        } else if (this.check(.set)) {
            if (memberAnnotations.len > 0) return ParseError.UnexpectedToken;
            const setter = try this.parseStructSetter(alloc);
            trailingComma = this.match(.comma);
            try members.append(alloc, .{ .setter = setter });
        } else if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
            const is_pub = this.match(.@"pub");
            const is_iface = this.match(.declare);
            var method = try this.parseMethodDecl(alloc, is_iface, is_pub);
            method.annotations = memberAnnotations;
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
        .implement = implementList,
        .members = try members.toOwnedSlice(alloc),
        .trailingComma = trailingComma,
    };
}

pub fn parseStructGetter(this: *This, alloc: std.mem.Allocator) ParseError!StructGetter {
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

pub fn parseStructSetter(this: *This, alloc: std.mem.Allocator) ParseError!StructSetter {
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

pub fn parseRecordDecl(this: *This, alloc: std.mem.Allocator) ParseError!RecordDecl {
    const p = try this.parseDeclPreamble(alloc, .record, false);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseRecordBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseShorthandRecordDecl(this: *This, alloc: std.mem.Allocator) ParseError!RecordDecl {
    const p = try this.parseDeclPreamble(alloc, .record, true);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseRecordBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseRecordBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!RecordDecl {
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    const implementList = try this.parseImplementClause(alloc);
    errdefer {
        for (implementList) |*im| @constCast(im).deinit(alloc);
        alloc.free(implementList);
    }
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
        this.skipComments();
        if (this.check(.rightBrace) or this.check(.endOfFile)) break;
        // Member-level decorators: `#[getMapping("/")] fn index(…)`. Parsed here
        // so annotation processors reach record methods (field-site is a separate
        // follow-up — `RecordField` carries no annotations yet).
        const memberAnnotations = try this.parseAnnotations(alloc);
        // Check if this is a method (fn/pub/declare)
        if (this.check(.@"pub") or this.check(.declare) or this.check(.@"fn")) {
            const is_pub = this.match(.@"pub");
            const is_iface = this.match(.declare);
            var method = try this.parseMethodDecl(alloc, is_iface, is_pub);
            method.annotations = memberAnnotations;
            trailingComma = false;
            try methods.append(alloc, method);
        } else if (this.check(.val) or This.isMemberName(this.peek().kind)) {
            // Could be a field: [val] name: Type [= expr]. `get`/`set` are valid
            // record field names (records have no getters/setters).
            const nextIdx = this.current + 1;
            const nextToken = if (nextIdx < this.tokens.len) this.tokens[nextIdx] else token.Token{ .kind = .endOfFile, .lexeme = "", .line = 0, .col = 0 };

            // If next token is '(', it's a method
            if (nextToken.kind == .leftParenthesis) {
                return ParseError.UnexpectedToken;
            }

            // It's a field: [val] name: Type [= expr]
            if (this.check(.val)) _ = this.advance();
            const fieldName = (try this.consumeMemberName()).lexeme;
            _ = try this.consume(.colon);
            var fieldType = try this.parseTypeRef(alloc);
            errdefer fieldType.deinit(alloc);
            var defaultExpr: ?Expr = null;
            if (this.match(.equal)) {
                defaultExpr = try this.parseBinaryExpr(alloc, prec.equality);
            }
            trailingComma = this.match(.comma);
            try fields.append(alloc, .{ .name = fieldName, .typeRef = fieldType, .default = defaultExpr, .annotations = memberAnnotations });
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
        .implement = implementList,
        .fields = try fields.toOwnedSlice(alloc),
        .trailingComma = trailingComma,
        .methods = try methods.toOwnedSlice(alloc),
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

pub fn parseEnumDecl(this: *This, alloc: std.mem.Allocator) ParseError!EnumDecl {
    const p = try this.parseDeclPreamble(alloc, .@"enum", false);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseEnumBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseShorthandEnumDecl(this: *This, alloc: std.mem.Allocator) ParseError!EnumDecl {
    const p = try this.parseDeclPreamble(alloc, .@"enum", true);
    errdefer freeAnnotations(alloc, p.annotations);
    return this.parseEnumBody(alloc, p.name, p.annotations, p.isPub);
}

pub fn parseEnumBody(this: *This, alloc: std.mem.Allocator, name: []const u8, annotations: []Annotation, isPub: bool) ParseError!EnumDecl {
    const genericParams = try this.parseGenericParams(alloc);
    errdefer alloc.free(genericParams);
    const implementList = try this.parseImplementClause(alloc);
    errdefer {
        for (implementList) |*im| @constCast(im).deinit(alloc);
        alloc.free(implementList);
    }
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
        .implement = implementList,
        .variants = try variants.toOwnedSlice(alloc),
        .trailingComma = trailingComma,
        .methods = try methods.toOwnedSlice(alloc),
    };
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
        const typeRef = try this.parseTypeRef(alloc);
        return Param{ .name = name, .typeRef = typeRef, .modifier = .@"comptime" };
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
    var typeRef = try this.parseTypeRef(alloc);
    // Meta-kind params (`type`) only exist at compile time — require the
    // `comptime` modifier so the binding-time is visible in the signature.
    // (`@Expr<…>` params get the same rule as a semantic check in inference.)
    if (typeRef == .typeparam and modifier != .@"comptime") {
        typeRef.deinit(alloc);
        this.parseError = .{
            .kind = .metaKindRequiresComptime,
            .start = nameTok.col - 1,
            .end = nameTok.col - 1 + nameTok.lexeme.len,
            .lexeme = nameTok.lexeme,
            .line = nameTok.line,
            .col = nameTok.col,
        };
        return ParseError.UnexpectedToken;
    }
    return Param{ .name = name, .typeRef = typeRef, .modifier = modifier };
}
