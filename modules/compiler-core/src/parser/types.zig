//! Type-reference sub-grammar extracted from `parser.zig`.
//! Free functions on `*Parser` (post-`usingnamespace` Zig idiom); the
//! `Parser` struct re-exports each as a thin alias so `this.parseTypeRef()`
//! keeps working at every call site.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const TokenKind = parser.TokenKind;
const TypeRef = parser.TypeRef;
const GenericParam = parser.GenericParam;

/// True when `kind` can begin a type reference. Used to decide whether a
/// `type` meta-kind keyword is followed by a constraint list or stands alone.
fn startsTypeRef(kind: TokenKind) bool {
    return switch (kind) {
        .identifier, .builtinIdent, .questionMark, .hash, .@"fn", .selfType => true,
        else => false,
    };
}

/// Parses a full type reference.
pub fn parseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
    const ref = try this.parseBaseTypeRef(alloc);
    if (this.check(.bang)) {
        const tok = this.peek();
        this.parseError = .{
            .kind = .removedErrorUnion,
            .start = tok.col - 1,
            .end = tok.col - 1 + tok.lexeme.len,
            .lexeme = tok.lexeme,
            .line = tok.line,
            .col = tok.col,
        };
        return ParseError.UnexpectedToken;
    }
    return ref;
}

/// Parses a base type ref: `?T`, `#(T1,T2)`, plain name with optional `[]` wraps.
pub fn parseBaseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
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
            // Optional `name:` prefix — `fn(next: T)` is accepted alongside the
            // bare `fn(T)` form. The parameter name is documentation-only here
            // (function types are positional), so it is parsed and discarded.
            if (this.check(.identifier) and this.peekAt(1).kind == .colon) {
                _ = this.advance(); // name
                _ = this.advance(); // ':'
            }
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
    // { name: T, ... } — anonymous record type
    if (this.check(.leftBrace)) {
        _ = this.advance(); // consume '{'
        var fields: std.ArrayList(ast.RecordTypeField) = .empty;
        errdefer {
            for (fields.items) |*f| f.typeRef.deinit(alloc);
            fields.deinit(alloc);
        }
        while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
            const nameTok = try this.consumeMemberName();
            _ = try this.consume(.colon);
            const fieldType = try this.parseTypeRef(alloc);
            try fields.append(alloc, .{ .name = nameTok.lexeme, .typeRef = fieldType });
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightBrace);
        return ast.TypeRef{ .record_type = try fields.toOwnedSlice(alloc) };
    }
    // @Name<T1, T2> — builtin type constructor
    if (this.check(.builtinIdent)) {
        const tok = this.advance();
        const name = tok.lexeme[1..];
        if (this.check(.leftParenthesis)) {
            this.parseError = .{
                .kind = .removedBuiltinType,
                .start = tok.col - 1,
                .end = tok.col - 1 + tok.lexeme.len,
                .lexeme = tok.lexeme,
                .line = tok.line,
                .col = tok.col,
            };
            return ParseError.UnexpectedToken;
        }
        // `@Decl` (the annotation-processor reflection handle) is the one builtin
        // written WITHOUT type arguments — bare, like a nominal type. A decorator
        // declares its first parameter as `comptime _: @Decl`.
        if (std.mem.eql(u8, name, "Decl") and !this.check(.lessThan)) {
            return ast.TypeRef{ .generic = .{ .name = name, .args = &.{}, .is_builtin = true } };
        }
        // Other builtin types always take their generic parameters (`@Expr<i32>`,
        // never bare `@Expr`) — a result type only the expansion knows is
        // written as an ordinary fn generic: `fn yaml<T>(…) -> @Expr<T>`.
        _ = try this.consume(.lessThan);
        var args: std.ArrayList(ast.TypeRef) = .empty;
        errdefer {
            for (args.items) |*a| a.deinit(alloc);
            args.deinit(alloc);
        }
        while (!this.checkGenericClose() and !this.check(.endOfFile)) {
            try args.append(alloc, try this.parseTypeRef(alloc));
            if (!this.match(.comma)) break;
        }
        try this.consumeGenericClose();
        return ast.TypeRef{ .generic = .{ .name = name, .args = try args.toOwnedSlice(alloc), .is_builtin = true } };
    }
    // type [Constraint (| Constraint)*] — comptime type parameter (meta-kind)
    // with an optional `|`-separated constraint list. `type` alone is unconstrained.
    if (this.check(.type)) {
        _ = this.advance(); // consume 'type'
        var constraints: std.ArrayList(ast.TypeRef) = .empty;
        errdefer {
            for (constraints.items) |*c| c.deinit(alloc);
            constraints.deinit(alloc);
        }
        if (startsTypeRef(this.peek().kind)) {
            while (true) {
                try constraints.append(alloc, try this.parseTypeRef(alloc));
                if (!this.match(.verticalBar)) break;
            }
        }
        return ast.TypeRef{ .typeparam = try constraints.toOwnedSlice(alloc) };
    }

    // Plain named type, possibly followed by <T1, T2> and/or []
    const nameTok = try this.consumeTypeName();
    var ref: ast.TypeRef = undefined;
    if (this.check(.lessThan)) {
        _ = this.advance();
        var args: std.ArrayList(ast.TypeRef) = .empty;
        errdefer {
            for (args.items) |*a| a.deinit(alloc);
            args.deinit(alloc);
        }
        while (!this.checkGenericClose() and !this.check(.endOfFile)) {
            try args.append(alloc, try this.parseTypeRef(alloc));
            if (!this.match(.comma)) break;
        }
        try this.consumeGenericClose();
        ref = ast.TypeRef{ .generic = .{ .name = nameTok.lexeme, .args = try args.toOwnedSlice(alloc), .is_builtin = false } };
    } else {
        ref = ast.TypeRef{ .named = nameTok.lexeme };
    }
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

/// Parses an optional generic parameter list `<T, R, ...>`.
/// Returns an empty slice if there is no `<` at the current position.
pub fn parseGenericParams(this: *This, alloc: std.mem.Allocator) ParseError![]GenericParam {
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

pub fn parseImplementClause(this: *This, alloc: std.mem.Allocator) ParseError![]TypeRef {
    var list: std.ArrayList(TypeRef) = .empty;
    errdefer {
        for (list.items) |*t| t.deinit(alloc);
        list.deinit(alloc);
    }
    if (!this.match(.implement)) return list.toOwnedSlice(alloc);
    try list.append(alloc, try this.parseTypeRef(alloc));
    while (this.match(.comma)) {
        if (this.check(.leftBrace)) break;
        try list.append(alloc, try this.parseTypeRef(alloc));
    }
    return list.toOwnedSlice(alloc);
}
