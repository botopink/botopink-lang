//! Type-reference sub-grammar extracted from `parser.zig`.
//! Free functions on `*Parser` (post-`usingnamespace` Zig idiom); the
//! `Parser` struct re-exports each as a thin alias so `this.parseTypeRef()`
//! keeps working at every call site.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const ParseErrorInfo = parser.ParseErrorInfo;
const TokenKind = parser.TokenKind;
const TypeRef = parser.TypeRef;
const GenericParam = parser.GenericParam;

/// True when `kind` can begin a type reference. Used to decide whether a
/// `type` meta-kind keyword is followed by a constraint list or stands alone,
/// whether a `|` opens another union member, and whether an `is` has a type.
pub fn startsTypeRef(kind: TokenKind) bool {
    return switch (kind) {
        .identifier, .builtinIdent, .questionMark, .hash, .@"fn", .selfType, .unknown => true,
        // `(T)` — a parenthesised type (decision 8 §3.1). It begins a type
        // wherever a bare name does, so `A | (B | C)` and `x is (i32 | string)`
        // read the way `(i32 | string)[]` does.
        .leftParenthesis => true,
        else => false,
    };
}

/// Parses a full type reference, union types included (decision 8 §3, 06 N20):
/// `i32 | string` is one type written as an alternation of its members.
///
/// `|` binds looser than every other type operator, so `i32 | string[]` is
/// "`i32`, or an array of `string`" (§3.1) and a union of arrays is written
/// `(…)` free — `i32[] | string[]`. The members land in source order on
/// `ast.union_type_name` (see `ast.zig` for what inference owes them).
pub fn parseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
    var first = try this.parseTypeRefMember(alloc);
    if (!this.check(.verticalBar)) return first;

    var members: std.ArrayList(ast.TypeRef) = .empty;
    errdefer {
        for (members.items) |*m| m.deinit(alloc);
        members.deinit(alloc);
    }
    errdefer first.deinit(alloc);
    try members.append(alloc, first);
    while (this.match(.verticalBar)) {
        const barTok = this.tokens[this.current - 1];
        if (!startsTypeRef(this.peek().kind)) {
            this.parseError = ParseErrorInfo.fromToken(.unionMemberMissing, barTok);
            return ParseError.UnexpectedToken;
        }
        try members.append(alloc, try this.parseTypeRefMember(alloc));
    }
    return ast.TypeRef{ .generic = .{
        .name = ast.union_type_name,
        .args = try members.toOwnedSlice(alloc),
        .is_builtin = false,
    } };
}

/// One member of a type: everything `parseTypeRef` parses except the `|`
/// alternation. The `type A | B` meta-kind constraint list parses its members
/// through this too, so `|` there keeps separating constraints.
pub fn parseTypeRefMember(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
    const ref = try this.parseBaseTypeRef(alloc);
    if (this.check(.bang)) {
        const tok = this.peek();
        this.parseError = ParseErrorInfo.fromToken(.removedErrorUnion, tok);
        return ParseError.UnexpectedToken;
    }
    return ref;
}

/// Parses a base type ref: `?T`, `#(T1,T2)`, `(T)`, a plain name — and then the
/// `T[]` array suffix, **once, at the single exit**.
///
/// The suffix belongs to the type, not to the arm that produced it. It used to
/// be written at the end of the named-type path and copied into the `unknown`
/// arm; the tuple arm and the builtin-generic arm `return`ed before either, so
/// `#(a: i32)[]` and `@Result<i32, E>[]` were parse errors while `unknown[]`
/// and `Box<i32>[]` parsed. Applying it here means every arm — and every arm
/// added later — inherits it. See `AGENTS.md`.
pub fn parseBaseTypeRef(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
    var ref = try parseBaseTypeRefArm(this, alloc);
    errdefer ref.deinit(alloc);
    // T[] — zero or more array wraps.
    while (this.check(.leftSquareBracket) and this.peekAt(1).kind == .rightSquareBracket) {
        _ = this.advance(); // [
        _ = this.advance(); // ]
        const elem = try alloc.create(ast.TypeRef);
        elem.* = ref;
        ref = ast.TypeRef{ .array = elem };
    }
    return ref;
}

/// One arm of the base-type grammar, without the `[]` suffix — see
/// `parseBaseTypeRef`, which applies that once for all of them.
fn parseBaseTypeRefArm(this: *This, alloc: std.mem.Allocator) ParseError!ast.TypeRef {
    // `unknown` — decision 8 §2 (06 N19). A keyword, so no declaration can be
    // called `unknown` and the name always means this type; it travels as
    // `TypeRef.named` under the reserved spelling `ast.unknown_type_name`,
    // which the checker resolves to the `unknown` type instead of a lookup.
    // It takes no type arguments and no payload.
    if (this.check(.unknown)) {
        const tok = this.advance();
        if (this.check(.lessThan) or this.check(.leftParenthesis)) {
            this.parseError = ParseErrorInfo.fromToken(.unknownTakesNoArguments, this.peek());
            return ParseError.UnexpectedToken;
        }
        _ = tok;
        // `unknown[]` comes from the shared suffix loop in `parseBaseTypeRef`,
        // like every other arm's.
        return ast.TypeRef{ .named = ast.unknown_type_name };
    }
    // `(T)` — a parenthesised type. `|` binds looser than every other type
    // operator, so `decision-8:141` writes `(i32 | string)[]` for an array of
    // a union: the parentheses are what make the suffix apply to the whole
    // alternation. The grouping is not kept in the AST — `(T)` *is* `T`.
    if (this.check(.leftParenthesis)) {
        _ = this.advance(); // (
        const inner = try this.parseTypeRef(alloc);
        errdefer {
            var mut = inner;
            mut.deinit(alloc);
        }
        _ = try this.consume(.rightParenthesis);
        return inner;
    }
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
        // `#(name: T, …)` — a labeled tuple type (decision 8 §6): every element
        // carries a label, or none does.
        const labeled = this.check(.identifier) and this.peekAt(1).kind == .colon;
        var labels: std.ArrayList([]const u8) = .empty;
        errdefer labels.deinit(alloc);
        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            if (labeled) {
                if (!(this.check(.identifier) and this.peekAt(1).kind == .colon)) {
                    this.parseError = ParseErrorInfo.fromToken(.unexpectedToken, this.peek());
                    return ParseError.UnexpectedToken;
                }
                try labels.append(alloc, this.advance().lexeme);
                _ = this.advance(); // ':'
            }
            try elems.append(alloc, try this.parseTypeRef(alloc));
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightParenthesis);
        if (labeled) return ast.TypeRef{ .labeledTuple = .{
            .elems = try elems.toOwnedSlice(alloc),
            .labels = try labels.toOwnedSlice(alloc),
        } };
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
        var names: std.ArrayList([]const u8) = .empty;
        errdefer names.deinit(alloc);
        var anyName = false;

        while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
            // Optional `name:` prefix — `fn(next: T)` is accepted alongside the
            // bare `fn(T)` form. The name is documentation-only (function types
            // are positional); it is kept for the formatter.
            if (this.check(.identifier) and this.peekAt(1).kind == .colon) {
                try names.append(alloc, this.advance().lexeme); // name
                _ = this.advance(); // ':'
                anyName = true;
            } else try names.append(alloc, "");
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

        const nameSlice: []const []const u8 = if (anyName) try names.toOwnedSlice(alloc) else blk: {
            names.deinit(alloc);
            break :blk &.{};
        };
        return ast.TypeRef{ .function = .{
            .params = paramsSlice,
            .returnType = returnPtr,
            .paramNames = nameSlice,
        } };
    }
    // `{ name: T, … }` — the removed anonymous record type (1.0.3: a tuple type).
    if (this.check(.leftBrace)) {
        return this.failRemovedAt(.removedRecordType, 0);
    }
    // @Name<T1, T2> — builtin type constructor
    if (this.check(.builtinIdent)) {
        const tok = this.advance();
        const name = tok.lexeme[1..];
        if (this.check(.leftParenthesis)) {
            this.parseError = ParseErrorInfo.fromToken(.removedBuiltinType, tok);
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
            // RG4 (§1G) — a comma followed by another comma or by the closing
            // `>` means a middle generic argument was skipped (e.g.
            // `@ResultGenerator<i32, , i64>` or a stray trailing `, >`). Either pass
            // the middle argument explicitly, or rely on defaults for the
            // contiguous trailing range.
            if (this.check(.comma) or this.checkGenericClose()) {
                const slot = this.peek();
                this.parseError = ParseErrorInfo.fromToken(.genericArgSkipForbidden, slot);
                return ParseError.UnexpectedToken;
            }
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
                try constraints.append(alloc, try this.parseTypeRefMember(alloc));
                if (!this.match(.verticalBar)) break;
            }
        }
        return ast.TypeRef{ .typeparam = try constraints.toOwnedSlice(alloc) };
    }

    // Plain named type, possibly followed by <T1, T2> and/or []
    const nameTok = try this.consumeTypeName();
    // N28 — a section of an enum-shaped `type` is named by its path
    // (`Token.Text`, `Token.Text.Size`, decision 8 §5.3b), the same path its
    // values use. The dotted spelling travels in `.named`; `resolveTypeName`
    // maps it to the section's typedef. No other type position is followed by
    // a `.`, so this is unambiguous.
    var pathName: []const u8 = nameTok.lexeme;
    if (this.check(.dot)) {
        var buf: std.ArrayList(u8) = .empty;
        errdefer buf.deinit(alloc);
        try buf.appendSlice(alloc, nameTok.lexeme);
        while (this.match(.dot)) {
            const seg = try this.consumeTypeName();
            try buf.append(alloc, '.');
            try buf.appendSlice(alloc, seg.lexeme);
        }
        pathName = try buf.toOwnedSlice(alloc);
    }
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
            // RG4 (§1G) — see the matching `@Name<…>` path above.
            if (this.check(.comma) or this.checkGenericClose()) {
                const slot = this.peek();
                this.parseError = ParseErrorInfo.fromToken(.genericArgSkipForbidden, slot);
                return ParseError.UnexpectedToken;
            }
        }
        try this.consumeGenericClose();
        ref = ast.TypeRef{ .generic = .{ .name = pathName, .args = try args.toOwnedSlice(alloc), .is_builtin = false } };
    } else {
        ref = ast.TypeRef{ .named = pathName };
    }
    // `T[]` is the shared suffix loop's, in `parseBaseTypeRef`.
    return ref;
}

/// Parses an optional generic parameter list `<T, R, ...>`. Each parameter
/// may carry a default type: `<T, U = string>`. Defaults must occupy the
/// trailing positions — once a parameter has a default, every later one
/// must too (§1G strict-trailing-position rule; R16 / RG1).
/// Returns an empty slice if there is no `<` at the current position.
pub fn parseGenericParams(this: *This, alloc: std.mem.Allocator) ParseError![]GenericParam {
    var list: std.ArrayList(GenericParam) = .empty;
    errdefer {
        for (list.items) |*gp| gp.deinit(alloc);
        list.deinit(alloc);
    }

    if (!this.match(.lessThan)) return list.toOwnedSlice(alloc);

    var seen_default = false;
    while (!this.check(.greaterThan) and !this.check(.endOfFile)) {
        const nameTok = try this.consume(.identifier);
        var default: ?ast.TypeRef = null;
        if (this.match(.equal)) {
            default = try this.parseTypeRef(alloc);
        }
        // R16 / RG1 — a required parameter cannot follow a defaulted one.
        if (seen_default and default == null) {
            this.parseError = ParseErrorInfo.fromTokenDetail(.genericDefaultBeforeRequired, nameTok, nameTok.lexeme);
            return ParseError.UnexpectedToken;
        }
        if (default != null) seen_default = true;
        try list.append(alloc, .{ .name = nameTok.lexeme, .default = default });
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
