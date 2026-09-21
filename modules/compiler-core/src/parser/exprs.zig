//! Expression sub-grammar extracted from `parser.zig`: the precedence-
//! climbing binary parser, primary/pipeline/local-bind/lambda/loop/range.
//! Free functions on `*Parser`; `parser.zig` re-exports each as a thin alias.
const std = @import("std");
const parser = @import("../parser.zig");
const ast = @import("../ast.zig");
const token = @import("../lexer/token.zig");
const lexer = @import("../lexer.zig");

const This = parser.Parser;
const ParseError = parser.ParseError;
const ParseErrorInfo = parser.ParseErrorInfo;
const Expr = parser.Expr;
const CollectionExpr = parser.CollectionExpr;
const JumpExpr = parser.JumpExpr;
const BranchExpr = parser.BranchExpr;
const LoopExpr = parser.LoopExpr;
const FunctionExpr = parser.FunctionExpr;
const Loc = parser.Loc;
const Stmt = parser.Stmt;
const Param = parser.Param;
const ParamModifier = parser.ParamModifier;
const CallArg = parser.CallArg;
const TrailingLambda = parser.TrailingLambda;
const Pattern = parser.Pattern;
const ParamDestruct = parser.ParamDestruct;
const Token = parser.Token;
const TokenKind = parser.TokenKind;
const BinOp = This.BinOp;
const prec = This.prec;
const locFromToken = This.locFromToken;
const commentText = This.commentText;
const makeCall = This.makeCall;
const makeCallAt = This.makeCallAt;
const isReservedWord = This.isReservedWord;

/// One operator token and the AST op it maps to, at a given precedence level.
const PrecedenceOp = struct { tok: TokenKind, op: BinOp };

/// One precedence level: the operators it recognises (left-associative) plus
/// whether it enforces the `opNakedRight` rule (a compare op with no RHS value).
const PrecedenceLevel = struct { ops: []const PrecedenceOp, nakedRightCheck: bool = false };

/// Binary-operator precedence, lowest level first. `parseBinaryExpr` walks this
/// table recursively; level == len delegates to `parsePrimary`.
const precedence_table = [_]PrecedenceLevel{
    .{ .ops = &.{.{ .tok = .verticalBarVerticalBar, .op = .@"or" }} },
    .{ .ops = &.{.{ .tok = .amperAmper, .op = .@"and" }} },
    .{ .ops = &.{ .{ .tok = .equalEqual, .op = .eq }, .{ .tok = .notEqual, .op = .ne } } },
    .{ .ops = &.{
        .{ .tok = .lessThan, .op = .lt },
        .{ .tok = .greaterThan, .op = .gt },
        .{ .tok = .lessThanEqual, .op = .lte },
        .{ .tok = .greaterThanEqual, .op = .gte },
    }, .nakedRightCheck = true },
    .{ .ops = &.{ .{ .tok = .plus, .op = .add }, .{ .tok = .minus, .op = .sub } } },
    .{ .ops = &.{
        .{ .tok = .star, .op = .mul },
        .{ .tok = .slash, .op = .div },
        .{ .tok = .percent, .op = .mod },
    } },
};

pub fn parseExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    // The removed `record { … }` literal, before the call-chain path reads
    // `record { … }` as a call with a trailing lambda (see `parsePrimary`).
    if (this.check(.identifier) and std.mem.eql(u8, this.peek().lexeme, "record") and
        this.peekAt(1).kind == .leftBrace)
    {
        return this.failRemovedAt(.removedRecordLiteral, 0);
    }

    // ── Detect: identifier = expr or identifier : Type = expr ────────────
    if (this.check(.identifier)) {
        const saved = this.current;
        const identTok = this.advance();
        if (this.check(.colon)) {
            // "x: Int = 4" without val/var ---- NovalBinding error
            this.parseError = ParseErrorInfo.fromTokenDetail(.novalBinding, identTok, identTok.lexeme);
            return ParseError.UnexpectedToken;
        }
        if (this.match(.equal)) {
            // "x = expr" ---- assignment to a previously declared `var`
            var valExpr = try this.parseExpr(alloc);
            errdefer valExpr.deinit(alloc);
            const valPtr = try this.boxExpr(alloc, valExpr);
            return Expr{ .binding = .{ .loc = locFromToken(identTok), .kind = .{ .assign = .{
                .target = .{ .name = identTok.lexeme },
                .op = .assign,
                .value = valPtr,
            } } } };
        }
        this.current = saved;
    }

    // `while (cond) { … }` is not part of the language (decision 8 §10).
    if (this.check(.identifier) and std.mem.eql(u8, this.peek().lexeme, "while") and
        this.peekAt(1).kind == .leftParenthesis)
    {
        return this.failRemovedAt(.removedKeywordWhile, 0);
    }

    // throw expr — `new` is not a keyword (06 N27): `throw new Error(…)` gets
    // a targeted diagnostic at `new`.
    if (this.check(.throw)) {
        const throwTok = this.advance();
        if (this.check(.identifier) and std.mem.eql(u8, this.peek().lexeme, "new") and
            this.peekAt(1).kind == .identifier)
        {
            return this.failRemovedAt(.removedKeywordNew, 0);
        }
        const inner = try this.parseExpr(alloc);
        return this.makeJump(alloc, throwTok, .throw_, inner);
    }

    // `use` prefix operator: `use <hookcall>`. Binding (if any) is handled
    // by the enclosing `val`/`var`, e.g. `val {v, s} = use state(0)`.
    if (this.check(.use)) {
        const useTok = this.advance();
        const loc = locFromToken(useTok);
        const inner = try this.parseExpr(alloc);
        const innerPtr = try this.boxExpr(alloc, inner);
        return Expr{ .useHook = .{ .loc = loc, .kind = .{ .inner = innerPtr } } };
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
            return Expr{ .branch = .{ .loc = locFromToken(tryTok), .kind = .{ .tryCatch = .{ .expr = innerPtr, .handler = handlerPtr } } } };
        }
        return Expr{ .jump = .{ .loc = locFromToken(tryTok), .kind = .{ .try_ = innerPtr } } };
    }

    // await expr — suspend on a `@Future`; result is the resolved value (like `try`).
    if (this.check(.await)) {
        const awaitTok = this.advance();
        const inner = try this.parseExpr(alloc);
        const innerPtr = try this.boxExpr(alloc, inner);
        return Expr{ .jump = .{ .loc = locFromToken(awaitTok), .kind = .{ .await_ = innerPtr } } };
    }

    // if (cond) { [binding ->] stmt; } [else { stmt; }]
    // OR: if (cond) expr [else expr]
    if (this.check(.@"if")) {
        const ifTok = this.advance();
        // Static prefix of `use`: an `if` ends it for the rest of the function
        // body, its own branches included (`parser.zig` `useBranchSeen`).
        this.useBranchSeen = true;

        _ = try this.consume(.leftParenthesis);
        const cond = try this.parseBinaryExpr(alloc, prec.equality);
        errdefer @constCast(&cond).deinit(alloc);
        _ = try this.consume(.rightParenthesis);
        const condPtr = try this.boxExpr(alloc, cond);
        // `cond`'s errdefer above frees the children; the box itself was
        // leaked when a branch failed to parse (a `use` inside the then-block
        // refused by the static-prefix rule, for one).
        errdefer alloc.destroy(condPtr);

        var binding: ?[]const u8 = null;

        const then_ = if (this.check(.leftBrace)) blk: {
            _ = this.advance(); // consume `{`
            if (this.check(.identifier) and this.peekAt(1).kind == .rightArrow) {
                binding = this.advance().lexeme;
                _ = this.advance(); // consume `->`
            }
            // The shared block body — same options as `parseStmtListInBraces`,
            // which the else-branch below already uses. The `{` and the `x ->`
            // binding are the prologue this branch reads first; everything
            // after it is the one block loop, so a `//` comment and a blank
            // line are recorded here exactly as they are in the else-branch.
            break :blk try this.parseBlockBody(alloc, .{
                .trackEmptyLines = true,
                .handleComments = true,
                .semicolonPolicy = .requiredExceptLast,
                .useAfterBranchGuard = true,
            });
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

        return Expr{ .branch = .{ .loc = locFromToken(ifTok), .kind = .{ .if_ = .{
            .cond = condPtr,
            .binding = binding,
            .then_ = then_,
            .else_ = else_,
        } } } };
    }

    // return [expr]
    //
    // A bare `return;` (or `return` closing a block) carries no value — the
    // `ok` position of a `-> @Result<void, E>` fn (1.0.10-beta decision 74).
    // Only `;`, `}` and end of input end it: `return` followed by a newline
    // still takes the expression on the next line, as it always did.
    if (this.check(.@"return")) {
        const retTok = this.advance();
        this.useBranchSeen = true; // static prefix of `use` ends at a `return`
        if (this.check(.semicolon) or this.check(.rightBrace) or this.check(.endOfFile)) {
            return this.makeJump(alloc, retTok, .@"return", null);
        }
        const inner = try this.parseExpr(alloc);
        return this.makeJump(alloc, retTok, .@"return", inner);
    }

    // case expr { arm* }
    if (this.check(.case)) {
        this.useBranchSeen = true; // static prefix of `use` ends at a `case`
        return .{ .collection = try this.parseCaseExpr(alloc) };
    }

    // comptime expr  /  comptime { expr; ... }
    if (this.check(.@"comptime")) {
        const comptimeTok = this.advance();
        if (this.check(.leftBrace)) {
            const body = try this.parseStmtListInBraces(alloc);
            return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeBlock = .{ .body = body } } } };
        } else {
            const inner = try this.parseBinaryExpr(alloc, prec.equality);
            const innerPtr = try this.boxExpr(alloc, inner);
            return Expr{ .comptime_ = .{ .loc = locFromToken(comptimeTok), .kind = .{ .comptimeExpr = innerPtr } } };
        }
    }

    // break [:label] [expr]
    //
    // §1I (`frente-b-rules-tooling.md`) extends `break` with an optional
    // `:label` targeting an enclosing labelled loop or `#[@iterator]` /
    // `#[@futureGenerator]` fn scope. The bare and value forms keep their old
    // shape; `break :name` (no expr) and `break :name <expr>` are the new
    // surface. Unbound labels are caught by the comptime body walk (RI5).
    if (this.check(.@"break")) {
        const breakTok = this.advance();
        var label: ?[]const u8 = null;
        if (this.check(.colon)) {
            _ = this.advance();
            const labelTok = try this.consume(.identifier);
            label = labelTok.lexeme;
        }
        const isEnd = this.check(.rightBrace) or this.check(.endOfFile) or this.check(.newLine) or this.check(.semicolon);
        const innerPtr: ?*Expr = if (isEnd) null else blk: {
            const inner = try this.parseExpr(alloc);
            break :blk try this.boxExpr(alloc, inner);
        };
        return Expr{ .jump = .{ .loc = locFromToken(breakTok), .kind = .{ .@"break" = .{ .label = label, .value = innerPtr } } } };
    }

    // yield [:label] expr
    if (this.check(.yield)) {
        const yieldTok = this.advance();
        // RI6 (§1I) — the legacy `yield break [<expr>]` form is removed in
        // v0.beta.19; use `break <C>` (or bare `break`) instead.
        if (this.check(.@"break")) {
            const breakTok = this.peek();
            this.parseError = ParseErrorInfo.fromToken(.yieldBreakRemoved, breakTok);
            return ParseError.UnexpectedToken;
        }
        // Optional `:label` disambiguating the target generator/loop scope.
        var label: ?[]const u8 = null;
        if (this.check(.colon)) {
            _ = this.advance();
            const labelTok = try this.consume(.identifier);
            label = labelTok.lexeme;
        }
        const inner = try this.parseBinaryExpr(alloc, prec.equality);
        const innerPtr = try this.boxExpr(alloc, inner);
        return Expr{ .jump = .{ .loc = locFromToken(yieldTok), .kind = .{ .yield = .{ .label = label, .value = innerPtr } } } };
    }

    // continue
    if (this.check(.@"continue")) {
        const contTok = this.advance();
        return Expr{ .jump = .{ .loc = locFromToken(contTok), .kind = .@"continue" } };
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
        this.useBranchSeen = true; // static prefix of `use` ends at a `loop`
        return .{ .loop = try this.parseLoopExpr(alloc) };
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
            const valPtr = try this.boxExpr(alloc, valExpr);
            return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                .target = .{ .name = first.lexeme },
                .op = .plusAssign,
                .value = valPtr,
            } } } };
        }

        // `ident.field = expr` / `ident.field += expr`. Accept identifier,
        // numberLiteral (tuple access `.0`), or the soft keywords `get`/`set`
        // as the field — anything else rolls back to the call-chain path below.
        if (this.check(.dot) and
            (this.peekAt(1).kind == .numberLiteral or This.isMemberName(this.peekAt(1).kind)))
        {
            _ = this.advance();
            const fieldTok: Token = this.advance();

            if (this.match(.equal)) {
                const valExpr = try this.parseBinaryExpr(alloc, prec.equality);
                const valPtr = try this.boxExpr(alloc, valExpr);
                const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } });
                return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                    .target = .{ .fieldAccess = .{ .receiver = recvPtr, .field = fieldTok.lexeme } },
                    .op = .assign,
                    .value = valPtr,
                } } } };
            }

            if (this.match(.plusEqual)) {
                const valExpr = try this.parseBinaryExpr(alloc, prec.equality);
                const valPtr = try this.boxExpr(alloc, valExpr);
                const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(first), .kind = .{ .ident = first.lexeme } } });
                return Expr{ .binding = .{ .loc = locFromToken(first), .kind = .{ .assign = .{
                    .target = .{ .fieldAccess = .{ .receiver = recvPtr, .field = fieldTok.lexeme } },
                    .op = .plusAssign,
                    .value = valPtr,
                } } } };
            }

            this.current = saved;
        } else {
            this.current = saved;
        }
    }

    // ── call expressions & method chains ──
    //   ident(...) {...}, ident {...}, recv.method(...) {...},
    //   zero-arg method calls `r.isOk()`, and chains `a(x).map(f).filter(g)`.
    if (this.check(.identifier)) {
        const saved = this.current;
        const firstTok = this.advance();

        // Establish the chain base: a plain call `ident(args)`, a trailing
        // lambda call `ident { ... }`, or (provisionally) the bare identifier
        // — the latter only becomes a real node once a `.method(...)` follows.
        var base: Expr = Expr{ .identifier = .{ .loc = locFromToken(firstTok), .kind = .{ .ident = firstTok.lexeme } } };
        var baseIsCall = false;

        if (this.check(.leftParenthesis)) {
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
            base = Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                .receiver = null,
                .callee = firstTok.lexeme,
                .is_builtin = false,
                .args = args,
                .trailing = trailing,
            } } } };
            baseIsCall = true;
        } else if (!this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda())) {
            const trailing = try this.parseTrailingLambdas(alloc);
            if (trailing.len > 0) {
                base = Expr{ .call = .{ .loc = locFromToken(firstTok), .kind = .{ .call = .{
                    .receiver = null,
                    .callee = firstTok.lexeme,
                    .is_builtin = false,
                    .args = &.{},
                    .trailing = trailing,
                } } } };
                baseIsCall = true;
            } else {
                alloc.free(trailing);
                this.current = saved;
                return this.wrapCatch(alloc, try this.parsePipelineExpr(alloc));
            }
        }

        // Postfix chain: consume `.method(args)` / `.method { ... }` links.
        // A `.member` with no `(`/trailing is a pure field-access link — roll
        // it back and let `parsePrimary` own `a.b.c` so those snapshots stay
        // identical.
        var sawMethodCall = false;
        while (this.check(.dot) or this.check(.questionDot) or this.check(.leftParenthesis) or
            this.check(.leftSquareBracket))
        {
            // `xs[0]` — see the matching link in `parsePostfixChain`. The two
            // chain copies carry the same links; `parser/AGENTS.md` says so.
            if (this.check(.leftSquareBracket)) {
                base = try makeIndexExpr(this, alloc, base);
                sawMethodCall = true;
                continue;
            }
            // `adder(3)(4)` — calling what a call returned. A `(` reaches this
            // loop only after the base is already a call or a chain link (the
            // first `(` after the identifier was taken above), so it is always
            // a chained call and never the first one. There is no name for the
            // callee, so it travels as an expression — `ast.CallExpr.call.calleeExpr`.
            if (this.check(.leftParenthesis)) {
                const calleeTok = this.peek();
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
                const calleePtr = try this.boxExpr(alloc, base);
                base = Expr{ .call = .{ .loc = locFromToken(calleeTok), .kind = .{ .call = .{
                    .receiver = null,
                    .callee = "",
                    .is_builtin = false,
                    .args = args,
                    .trailing = trailing,
                    .calleeExpr = calleePtr,
                } } } };
                sawMethodCall = true;
                continue;
            }
            const isOptional = this.check(.questionDot);
            const dotSaved = this.current;
            _ = this.advance(); // '.' / '?.'
            const methodTok: Token = if (this.check(.numberLiteral))
                this.advance()
            else
                this.consumeMemberName() catch {
                    this.current = dotSaved;
                    break;
                };

            const hasParen = this.check(.leftParenthesis);
            const hasTrailing = !this.noTrailingLambda and (this.check(.leftBrace) or this.checkLabeledTrailingLambda());
            if (!hasParen and !hasTrailing) {
                // Field-access link without a call — not our job.
                this.current = dotSaved;
                break;
            }

            var args: []CallArg = &.{};
            if (hasParen) args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }
            const trailing = if (this.noTrailingLambda) try alloc.alloc(TrailingLambda, 0) else try this.parseTrailingLambdas(alloc);
            errdefer {
                for (trailing) |*t| t.deinit(alloc);
                alloc.free(trailing);
            }
            const recvPtr = try this.boxExpr(alloc, base);
            // Use the method token's loc so each chain link has a distinct
            // location (the type-directed method lowering is keyed by loc).
            base = Expr{ .call = .{ .loc = locFromToken(methodTok), .kind = .{ .call = .{
                .receiver = recvPtr,
                .callee = methodTok.lexeme,
                .is_builtin = false,
                .optional = isOptional,
                .args = args,
                .trailing = trailing,
            } } } };
            sawMethodCall = true;
        }

        if ((baseIsCall or sawMethodCall) and !isBinaryOpNext(this) and !this.check(.dot) and !this.check(.questionDot)) {
            return this.wrapCatch(alloc, base);
        }

        // Either a bare identifier with no call/chain, or a call chain
        // followed by a binary operator (`add(1, 2) == 5`, `f() + 1`) or a
        // field-access link (`s.split(",").length`) — the call is an operand,
        // not the whole expression. Roll back and let the precedence climber
        // (whose parsePrimary parses call chains) own it.
        base.deinit(alloc);
        this.current = saved;
    }

    return this.wrapCatch(alloc, try this.parsePipelineExpr(alloc));
}

/// True when the current token is a binary operator from `precedence_table`.
fn isBinaryOpNext(this: *This) bool {
    const kind = this.peek().kind;
    // `??` is not in the table — it desugars rather than mapping to a `BinOp`
    // (see `parseNullishExpr`) — but `g(1) ?? 0` must not end the expression
    // at the call, so it is named here beside the table's operators.
    if (kind == .questionQuestion) return true;
    inline for (precedence_table) |lvl| {
        inline for (lvl.ops) |o| {
            if (kind == o.tok) return true;
        }
    }
    return false;
}

/// The handler a handler-less `val assert P = e;` desugars to: `@panic(…)`,
/// so the fatal path decision 8 § 9 asks for is the `@panic` lowering every
/// backend already has. The message is a static literal — the parser owns no
/// arena and a `Literal.stringLit` is never freed by `deinit`.
fn assertFatalHandler(alloc: std.mem.Allocator, assertTok: Token) ParseError!Expr {
    const loc = locFromToken(assertTok);
    const msgExpr = try alloc.create(Expr);
    errdefer alloc.destroy(msgExpr);
    msgExpr.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = "assert pattern did not match" } } };
    const args = try alloc.alloc(ast.CallArg, 1);
    args[0] = .{ .label = null, .value = msgExpr };
    return Expr{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = "panic",
        .is_builtin = true,
        .args = args,
        .trailing = &.{},
    } } } };
}

/// `val/var name = expr` or any destructuring variant.
/// Call when current token is `val` or `var`.
pub fn parseLocalBindExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
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
                const expr = try this.parseExpr(alloc);
                this.noTailCatch = savedNTC2;
                // The box takes ownership: no `errdefer expr.deinit` may stay
                // alive past this line, or the two free the same children.
                const exprPtr = try this.boxExprOwned(alloc, expr);
                errdefer {
                    exprPtr.deinit(alloc);
                    alloc.destroy(exprPtr);
                }
                errdefer {
                    var mutPattern = pattern;
                    mutPattern.deinit(alloc);
                }

                if (this.match(.@"catch")) {
                    const catchExpr = if (this.check(.leftBrace)) blk: {
                        const stmts = try this.parseBlockWithOptionalTrailingSemicolon(alloc);
                        errdefer {
                            for (stmts) |*s| s.deinit(alloc);
                            alloc.free(stmts);
                        }
                        const resultOwned = stmts[stmts.len - 1].expr;
                        alloc.free(stmts);
                        break :blk resultOwned;
                    } else try this.parseExpr(alloc);
                    const catchExprPtr = try this.boxExprOwned(alloc, catchExpr);
                    return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assertPattern = .{
                        .pattern = pattern,
                        .expr = exprPtr,
                        .handler = catchExprPtr,
                    } } } };
                } else {
                    // 06 C12 / decision 8 § 9 — `val assert P = e;` with no
                    // `catch` is valid: a failure is a fatal assert. The form
                    // desugars here into the handler `@panic(…)` so the AST
                    // keeps one shape and every backend's existing lowering
                    // already emits the fatal path.
                    const panicExpr = try assertFatalHandler(alloc, assertTok);
                    const panicPtr = try this.boxExprOwned(alloc, panicExpr);
                    return Expr{ .comptime_ = .{ .loc = locFromToken(assertTok), .kind = .{ .assertPattern = .{
                        .pattern = pattern,
                        .expr = exprPtr,
                        .handler = panicPtr,
                        .fatal = true,
                    } } } };
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
            const field_name = try alloc.dupe(u8, (try this.consumeMemberName()).lexeme);
            const bind_name: []const u8 = if (this.match(.colon))
                try alloc.dupe(u8, (try this.consumeMemberName()).lexeme)
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
                .pattern = .{ .ctor = .{ .variant = .{ .name = ctorName, .payload = .{ .literals = try args.toOwnedSlice(alloc) } } } },
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
    var typeAnnotation: ?ast.TypeRef = null;
    if (this.match(.colon)) {
        typeAnnotation = try this.parseTypeRef(alloc);
    }
    errdefer if (typeAnnotation) |*ann| ann.deinit(alloc);
    _ = try this.consume(.equal);
    const valPtr = try this.boxExpr(alloc, try this.parseExpr(alloc));
    return Expr{ .binding = .{ .loc = locFromToken(bindTok), .kind = .{ .localBind = .{
        .name = name,
        .value = valPtr,
        .mutable = mutable,
        .typeAnnotation = typeAnnotation,
    } } } };
}

pub fn parsePipelineExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    var lhs = try this.parseBinaryExpr(alloc, prec.lowest);

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
                    break :rhs_blk makeCall(nameTok, null, nameTok.lexeme, false, args, trailing);
                } else if (this.match(.dot)) {
                    const methodTok = try this.consumeMemberName();
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
                    const recvPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(nameTok), .kind = .{ .ident = nameTok.lexeme } } });
                    // The pipeline RHS `Recv.method(args)` is a method call:
                    // like every other method-call link it is located at the
                    // METHOD, so it does not share the receiver's loc key.
                    break :rhs_blk makeCall(methodTok, recvPtr, methodTok.lexeme, false, args, trailing);
                } else {
                    this.current = saved;
                }
            }
            break :rhs_blk try this.parseBinaryExpr(alloc, prec.lowest);
        };
        const lhsPtr = try this.boxExpr(alloc, lhs);
        const rhsPtr = try this.boxExpr(alloc, rhs);
        lhs = Expr{ .call = .{ .loc = locFromToken(opTok), .kind = .{ .pipeline = .{ .lhs = lhsPtr, .rhs = rhsPtr, .comment = pipeComment } } } };
    }

    return lhs;
}

/// `a ?? b` — the nullish default (decision 28): `a` unless it is null, and
/// then `b`.
///
/// It sits at the tightest binary level, just above `is` and a primary, for the
/// reason `is` does: `a ?? 0 == 1` reads as `(a ?? 0) == 1`, `if (a ?? false)`
/// needs no parentheses of its own, and there is no "cannot mix `??` with `||`"
/// rule to learn. **Right-associative**, so `a ?? b ?? c` is `a ?? (b ?? c)` —
/// the first non-null of the three.
///
/// **It desugars rather than adding an operator.** `a ?? b` becomes
/// `if (a) { <n> -> <n> } else { b }` with `n = ast.nullish_binding_name`: the
/// optional binding form the language already has, which evaluates `a` once,
/// narrows it inside the branch, and is already lowered by all four backends.
/// `ast.zig` says why a `BinOp` variant is not the shape.
fn parseNullishExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    var value = try parseIsExpr(this, alloc);
    errdefer value.deinit(alloc);
    if (!this.check(.questionQuestion)) return value;
    const opTok = this.advance();
    // Right-associative: the RHS is another `??` chain, not just one operand.
    const fallback = try parseNullishExpr(this, alloc);

    const condPtr = try this.boxExpr(alloc, value);
    const fallbackPtr = try this.boxExprOwned(alloc, fallback);

    var then_ = try alloc.alloc(Stmt, 1);
    then_[0] = .{ .expr = Expr{ .identifier = .{
        .loc = locFromToken(opTok),
        .kind = .{ .ident = ast.nullish_binding_name },
    } } };
    var else_ = try alloc.alloc(Stmt, 1);
    else_[0] = .{ .expr = fallbackPtr.* };
    alloc.destroy(fallbackPtr);

    return Expr{ .branch = .{ .loc = locFromToken(opTok), .kind = .{ .if_ = .{
        .cond = condPtr,
        .binding = ast.nullish_binding_name,
        .then_ = then_,
        .else_ = else_,
    } } } };
}

/// `x is T` — decision 8 §4 (06 N21): tests the VALUE, not its origin.
///
/// The tightest level of the expression grammar, just above a primary, so
/// `a is i32 && b` is `(a is i32) && b` and `if (v is string)` needs no
/// parentheses of its own. It desugars to the `is` builtin call with the tested
/// type on the node (`ast.is_builtin_name`), because a type is not an
/// expression; `ast.zig` documents what inference owes it.
fn parseIsExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    var value = try this.parsePrimary(alloc);
    errdefer value.deinit(alloc);
    while (this.check(.is)) {
        const isTok = this.advance();
        if (!This.startsTypeRef(this.peek().kind)) {
            this.parseError = ParseErrorInfo.fromToken(.isMissingType, isTok);
            return ParseError.UnexpectedToken;
        }
        var ty = try this.parseTypeRef(alloc);
        errdefer ty.deinit(alloc);
        // `x is Option.Some(v)` (§4.2) binds the payload; the node carries a
        // type, so the payload form is refused where it starts instead of
        // failing as an unexpected token further along.
        if (this.check(.leftParenthesis)) {
            this.parseError = ParseErrorInfo.fromToken(.isVariantBinding, this.peek());
            return ParseError.UnexpectedToken;
        }
        const valuePtr = try this.boxExpr(alloc, value);
        var args = try alloc.alloc(CallArg, 1);
        args[0] = .{ .label = null, .value = valuePtr };
        value = Expr{ .call = .{ .loc = locFromToken(isTok), .kind = .{ .call = .{
            .receiver = null,
            .callee = ast.is_builtin_name,
            .is_builtin = true,
            .args = args,
            .trailing = try alloc.alloc(TrailingLambda, 0),
            .isType = ty,
        } } } };
    }
    return value;
}

/// Left-associative precedence-climbing parser driven by `precedence_table`.
pub fn parseBinaryExpr(this: *This, alloc: std.mem.Allocator, comptime level: usize) ParseError!Expr {
    if (level == precedence_table.len) return parseNullishExpr(this, alloc);
    const entry = precedence_table[level];

    var lhs = try this.parseBinaryExpr(alloc, level + 1);
    while (true) {
        const op: BinOp = inline for (entry.ops) |o| {
            if (this.match(o.tok)) break o.op;
        } else break;
        const opTok = this.tokens[this.current - 1];
        if (entry.nakedRightCheck and (this.check(.val) or this.check(.endOfFile))) {
            this.parseError = ParseErrorInfo.fromToken(.opNakedRight, opTok);
            return ParseError.UnexpectedToken;
        }
        const rhs = try this.parseBinaryExpr(alloc, level + 1);
        lhs = try this.makeBinOp(alloc, op, opTok, lhs, rhs);
    }
    return lhs;
}

/// `receiver[index]` — decision 30's index expression, as the reserved builtin
/// call `ast.index_builtin_name` over `(receiver, index)`. The `[` must be the
/// current token.
///
/// It is a **chain link**, built by both copies of the chain loop, so
/// `f(1)[0].name` and `d["k"][0]` are one chain and an index composes with
/// every other link. The index is parsed as an ordinary expression, which is
/// what makes `xs[0..2]` the same node with a `range` inside it.
fn makeIndexExpr(this: *This, alloc: std.mem.Allocator, base: Expr) ParseError!Expr {
    const openTok = this.advance(); // [
    // `parseRangeExpr`, not `parseExpr`: the index is where `xs[0..2]` puts a
    // range, and `decision-8:447` says `..` is iteration **and slicing**.
    const idx = try this.parseRangeExpr(alloc);
    const idxPtr = try this.boxExpr(alloc, idx);
    _ = try this.consume(.rightSquareBracket);
    const recvPtr = try this.boxExpr(alloc, base);
    var args = try alloc.alloc(CallArg, 2);
    args[0] = .{ .label = null, .value = recvPtr };
    args[1] = .{ .label = null, .value = idxPtr };
    return Expr{ .call = .{ .loc = locFromToken(openTok), .kind = .{ .call = .{
        .receiver = null,
        .callee = ast.index_builtin_name,
        .is_builtin = true,
        .args = args,
        .trailing = &.{},
    } } } };
}

/// Consume a postfix `.member` / `?.member` / `.method(args)` chain off an
/// already-parsed `base` expression, so a literal receiver chains the same way
/// an identifier does (`[1, 2].map(f)`, `"x".contains(y)`). Operand position:
/// trailing lambdas are not consumed (a `{` belongs to the enclosing construct),
/// mirroring the identifier path below. Each method-call link uses the method
/// token's loc so loc-keyed method lowering stays per-link distinct.
fn parsePostfixChain(this: *This, alloc: std.mem.Allocator, base_in: Expr) ParseError!Expr {
    var base = base_in;
    while (this.check(.dot) or this.check(.questionDot) or this.check(.leftParenthesis) or
        this.check(.leftSquareBracket))
    {
        // `xs[0]` — an index expression (decision 30), a chain link like
        // `.field`, so `f(1)[0].name` is one chain. The index is an ordinary
        // expression, which is what makes `xs[0..2]` the same node.
        if (this.check(.leftSquareBracket)) {
            base = try makeIndexExpr(this, alloc, base);
            continue;
        }
        // `f(a)(b)` — a function is a value, so calling what a call returned is
        // a link in the chain like a `.method(…)` is (decision 14). There is no
        // name to put in `callee`, so the callee travels as an expression; see
        // `ast.CallExpr.call.calleeExpr`.
        if (this.check(.leftParenthesis)) {
            const calleeTok = this.peek();
            const args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }
            const calleePtr = try this.boxExpr(alloc, base);
            base = makeCall(calleeTok, null, "", false, args, try alloc.alloc(TrailingLambda, 0));
            base.call.kind.call.calleeExpr = calleePtr;
            continue;
        }
        const isOptional = this.check(.questionDot);
        _ = this.advance();
        const fieldTok: Token = if (this.check(.numberLiteral))
            this.advance()
        else
            try this.consumeMemberName();
        if (this.check(.leftParenthesis)) {
            const args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }
            const recvPtr = try this.boxExpr(alloc, base);
            base = makeCall(fieldTok, recvPtr, fieldTok.lexeme, false, args, try alloc.alloc(TrailingLambda, 0));
            base.call.kind.call.optional = isOptional;
        } else {
            const recvPtr = try this.boxExpr(alloc, base);
            // Field-access links use the member token's loc — like the
            // method-call links above — so each chain link has a distinct
            // location. Loc-keyed lowering (`instanceLowerings` for `.length`)
            // would otherwise collide on the shared base loc, e.g. emitting
            // `self.pairs.length` as `length(length(Self))`.
            base = Expr{ .identifier = .{ .loc = locFromToken(fieldTok), .kind = .{ .identAccess = .{
                .receiver = recvPtr,
                .member = fieldTok.lexeme,
                .optional = isOptional,
            } } } };
        }
    }
    return base;
}

pub fn parsePrimary(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    // `record { … }` ---- the removed anonymous record literal (1.0.3: a tuple).
    // `record` lexes as an identifier; followed by `{` it gets its targeted
    // diagnostic instead of a generic syntax error.
    if (this.check(.identifier) and std.mem.eql(u8, this.peek().lexeme, "record") and
        this.peekAt(1).kind == .leftBrace)
    {
        return this.failRemovedAt(.removedRecordLiteral, 0);
    }

    // Unary `-` — negation of any expression (-x, -123, -(a+b), etc.)
    if (this.check(.minus)) {
        const opTok = this.advance();
        const operand = try this.parsePrimary(alloc);
        const operandPtr = try this.boxExpr(alloc, operand);
        return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .op = .neg, .expr = operandPtr } };
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

            // The shared block body — the `{` and the `a, b ->` parameter list
            // are this block's prologue. The semicolon policy stays `.optional`,
            // which is what this body has always applied: `{ x -> a b }` parses
            // today and tightening it would refuse a program that compiles.
            // What it gains is comment handling and empty-line tracking, so a
            // `//` inside a lambda — and so inside every `loop (…) { x -> … }`
            // body — parses, and a blank line inside one survives the printer.
            const body = try this.parseBlockBody(alloc, .{
                .trackEmptyLines = true,
                .handleComments = true,
                .semicolonPolicy = .optional,
                // A lambda is another function: its static prefix of `use`
                // starts over and does not touch the enclosing body's.
                .useAfterBranchGuard = true,
                .freshUseScope = true,
            });

            return Expr{ .function = .{ .loc = locFromToken(braceTok), .kind = .{
                .syntax = .lambda,
                .params = try paramList.toOwnedSlice(alloc),
                .body = body,
            } } };
        } else {
            // { } without -> is not allowed (use @block builtin instead)
            return ParseError.UnexpectedToken;
        }
    }

    // Unary `!` — logical not
    if (this.check(.bang)) {
        const opTok = this.advance();
        const operand = try this.parsePrimary(alloc);
        const operandPtr = try this.boxExpr(alloc, operand);
        return Expr{ .unaryOp = .{ .loc = locFromToken(opTok), .op = .not, .expr = operandPtr } };
    }

    // @name(args...) ---- built-in function call (same as regular calls, just with @ prefix)
    // OR @InterfaceName(field: value, …) ---- interface literal instantiation.
    // Distinguish by checking for named arguments (field: value pattern).
    if (this.check(.builtinIdent)) {
        const nameTok = this.advance();
        const callee = nameTok.lexeme[1..]; // Remove @ prefix

        // Check for @name{ ... } syntax (trailing lambda with no args)
        if (this.check(.leftBrace)) {
            const trailing = try this.parseTrailingLambdas(alloc);
            errdefer {
                for (trailing) |*t| t.deinit(alloc);
                alloc.free(trailing);
            }
            return makeCall(nameTok, null, callee, true, &.{}, trailing);
        }

        // Check for interface literal: @Name(field: value, ...)
        // Look ahead to see if we have named arguments (identifier followed by colon)
        if (this.check(.leftParenthesis)) {
            const savedPos = this.current;
            _ = this.advance(); // consume (
            const isInterfaceLit = this.check(.identifier) and this.peekAt(1).kind == .colon;
            this.current = savedPos; // restore position

            if (isInterfaceLit) {
                // Parse as interface literal
                _ = this.advance(); // consume (
                var fields: std.ArrayList(ast.RecordLitFieldOf(.untyped)) = .empty;
                errdefer {
                    for (fields.items) |f| {
                        f.value.deinit(alloc);
                        alloc.destroy(f.value);
                    }
                    fields.deinit(alloc);
                }
                while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
                    const nameTok2 = try this.consumeMemberName();
                    _ = try this.consume(.colon);
                    const value = try this.parseExpr(alloc);
                    const valuePtr = try this.boxExpr(alloc, value);
                    try fields.append(alloc, .{ .name = nameTok2.lexeme, .value = valuePtr });
                    if (!this.match(.comma)) break;
                }
                _ = try this.consume(.rightParenthesis);
                const lit = Expr{ .collection = .{ .loc = locFromToken(nameTok), .kind = .{ .behaviorLit = .{
                    .name = callee,
                    .fields = try fields.toOwnedSlice(alloc),
                } } } };
                return parsePostfixChain(this, alloc, lit);
            }
        }

        // Regular @name(args...) syntax
        const args = try this.parseCallArgs(alloc);
        errdefer {
            for (args) |*a| a.deinit(alloc);
            alloc.free(args);
        }

        // Check for trailing lambdas after args
        const trailing = try this.parseTrailingLambdas(alloc);
        errdefer {
            for (trailing) |*t| t.deinit(alloc);
            alloc.free(trailing);
        }

        // A builtin call is a value like any other call: `@src().line`,
        // `@field(x, "a").b` continue with the postfix chain (1.0.10-beta
        // decision 73 — `@src()` answers a record whose fields are read
        // in place). Before this the chain was a parse error, so no program
        // that compiled changes.
        const call = makeCall(nameTok, null, nameTok.lexeme[1..], true, args, trailing);
        return parsePostfixChain(this, alloc, call);
    }

    if (this.check(.stringLiteral)) {
        const tok = this.advance();
        const lit = try makeStringExpr(this, alloc, tok, tok.lexeme[1 .. tok.lexeme.len - 1], false);
        return parsePostfixChain(this, alloc, lit);
    }
    if (this.check(.multilineStringLiteral)) {
        const tok = this.advance();
        // Remove the triple quotes from both ends
        const lit = try makeStringExpr(this, alloc, tok, tok.lexeme[3 .. tok.lexeme.len - 3], true);
        return parsePostfixChain(this, alloc, lit);
    }
    if (this.check(.linesStringLiteral)) {
        const tok = this.advance();
        const content = try materializeLineString(alloc, tok.lexeme);
        const lit = try makeStringExpr(this, alloc, tok, content, true);
        return parsePostfixChain(this, alloc, lit);
    }

    if (this.check(.numberLiteral)) {
        const tok = this.advance();
        const lit = Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .{ .numberLit = tok.lexeme } } };
        // A number is a receiver like any other literal — `libs/std` declares
        // `Integer.toString` and `"ab".toUpperCase()` already chains. The
        // range `0..4` is unaffected: `..` lexes as `dotDot`, which is not a
        // chain link.
        return parsePostfixChain(this, alloc, lit);
    }

    if (this.check(.selfType)) {
        const tok = this.advance();
        return Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = "Self" } } };
    }

    // `fn(params) { body }` — anonymous function expression. (The legacy
    // `*fn(...)` lambda form was removed in v0.beta.19 along with the rest of
    // the `*fn` surface; reject it with the same migration diagnostic the
    // top-level path uses.)
    if (this.check(.star) and this.peekAt(1).kind == .@"fn") {
        const tok = this.peek();
        this.parseError = ParseErrorInfo.fromTokenSpan(.deprecatedStarFn, tok, "*fn".len);
        return ParseError.UnexpectedToken;
    }
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
        const body = try this.parseFnBodyInBraces(alloc);
        return Expr{ .function = .{ .loc = locFromToken(fnTok), .kind = .{
            .syntax = .fnExpr,
            .params = try params.toOwnedSlice(alloc),
            .body = body,
        } } };
    }

    if (this.check(.null)) {
        const tok = this.advance();
        return Expr{ .literal = .{ .loc = locFromToken(tok), .kind = .null_ } };
    }

    // Detect reserved word used as expression
    if (isReservedWord(this.peek().kind)) {
        const tok = this.peek();
        this.parseError = ParseErrorInfo.fromTokenDetail(.reservedWord, tok, tok.lexeme);
        return ParseError.UnexpectedToken;
    }

    if (this.check(.identifier)) {
        const tok = this.advance();
        var base: Expr = Expr{ .identifier = .{ .loc = locFromToken(tok), .kind = .{ .ident = tok.lexeme } } };

        // `ident(args)` — a call in operand position (e.g. `add(1, 2) == 3`).
        // Trailing lambdas are not consumed here: in a binary operand a `{`
        // belongs to the enclosing construct (if/case/loop bodies).
        if (this.check(.leftParenthesis)) {
            const args = try this.parseCallArgs(alloc);
            errdefer {
                for (args) |*a| a.deinit(alloc);
                alloc.free(args);
            }
            base = makeCall(tok, null, tok.lexeme, false, args, try alloc.alloc(TrailingLambda, 0));
        }

        // Chained links: `.field`, `.method(args)`, their optional-chaining
        // forms, and `(args)` on what a call returned. This used to be a
        // verbatim third copy of `parsePostfixChain`'s loop, which is why
        // adding the `(` link there closed `("ab").length` and not
        // `adder(3)(4)`: the two forms reached two copies of one rule. One
        // rule, one place.
        base = try parsePostfixChain(this, alloc, base);

        // Tagged-call sugar: a string literal immediately after a plain
        // identifier or `a.b` access is a call with that single argument:
        // `html """<Button/>"""` => `html("""<Button/>""")`.
        if ((this.check(.stringLiteral) or this.check(.multilineStringLiteral) or this.check(.linesStringLiteral)) and base == .identifier) {
            switch (base.identifier.kind) {
                .dotIdent => {}, // `.Red "x"` is not callable — leave for the normal error path
                else => {
                    const strTok = this.advance();
                    const multiline = strTok.kind != .stringLiteral;
                    const content = switch (strTok.kind) {
                        .multilineStringLiteral => strTok.lexeme[3 .. strTok.lexeme.len - 3],
                        .linesStringLiteral => try materializeLineString(alloc, strTok.lexeme),
                        else => strTok.lexeme[1 .. strTok.lexeme.len - 1],
                    };
                    const strExpr = try makeStringExpr(this, alloc, strTok, content, multiline);
                    const argPtr = try this.boxExpr(alloc, strExpr);
                    var args = try alloc.alloc(CallArg, 1);
                    args[0] = .{ .label = null, .value = argPtr, .comments = &.{} };
                    base = switch (base.identifier.kind) {
                        // `html """…"""` — the head identifier IS the callee.
                        .ident => |name| makeCall(tok, null, name, false, args, try alloc.alloc(TrailingLambda, 0)),
                        // `db.sql "…"` — the callee is the member, so the call
                        // takes the member's loc (as ordinary method-call links
                        // do). Using the head token here gave the call and its
                        // receiver the same loc, and loc-keyed method lowering
                        // then collided on it.
                        .identAccess => |ia| makeCallAt(base.identifier.loc, ia.receiver, ia.member, false, args, try alloc.alloc(TrailingLambda, 0)),
                        .dotIdent => unreachable,
                    };
                    base.call.kind.call.is_tagged = true;
                },
            }
        }
        return base;
    }

    // Dot-shorthand variant: `.Red` ---- type resolved from context.
    // Multi-segment chains `.Color.Red.500` (enum-sections path access, §F2)
    // ride the existing postfix-chain machinery — it already accepts both
    // identifier and numeric segments after a `.`.
    if (this.check(.dot)) {
        const dotTok = this.advance();
        const memberTok = try this.consume(.identifier);
        const head = Expr{ .identifier = .{ .loc = locFromToken(dotTok), .kind = .{ .dotIdent = memberTok.lexeme } } };
        return parsePostfixChain(this, alloc, head);
    }

    // [e1, e2, ...] or [e1, ..rest] ---- array literal with optional spread.
    // A literal receiver may chain methods directly (`[1, 2].map(f).len()`).
    if (this.check(.leftSquareBracket)) {
        const lit = Expr{ .collection = try this.parseArrayLitExpr(alloc) };
        return parsePostfixChain(this, alloc, lit);
    }

    // `(expr)` ---- grouped expression (parentheses for precedence).
    // The eighth literal receiver, and the one that used to `return` instead of
    // chaining: `("ab").length`, `(a == b).toString()` and `(sql """…""").length`
    // were `Unexpected token` at the `.` while every other receiver chained
    // (decision 14).
    if (this.check(.leftParenthesis)) {
        const parenTok = this.advance();
        const inner = try this.parseExpr(alloc);
        _ = try this.consume(.rightParenthesis);
        const innerPtr = try this.boxExpr(alloc, inner);
        const grouped = Expr{ .collection = .{ .loc = locFromToken(parenTok), .kind = .{ .grouped = innerPtr } } };
        return parsePostfixChain(this, alloc, grouped);
    }

    return ParseError.UnexpectedToken;
}

/// `#(e1, e2, ...)` ---- tuple literal.  Call when current token is `#`.
pub fn parseTupleLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
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
pub fn parseArrayLitExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
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
                spreadExpr = try this.boxExpr(alloc, se);
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

/// Parses a block expression: `{ stmt; stmt; ... }`
pub fn parseBlockExpr(this: *This, alloc: std.mem.Allocator) ParseError!CollectionExpr {
    const braceTok = try this.consume(.leftBrace);

    var stmts: std.ArrayList(Stmt) = .empty;
    errdefer {
        for (stmts.items) |*s| s.deinit(alloc);
        stmts.deinit(alloc);
    }

    while (!this.check(.rightBrace) and !this.check(.endOfFile)) {
        if (try this.tryParseCommentStmt(alloc, &stmts, 0)) continue;
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
pub fn isComment(this: *const This) bool {
    const toks = this.tokens;
    if (this.current >= toks.len) return false;
    const k = toks[this.current].kind;
    return k == .commentNormal or k == .commentDoc or k == .commentModule;
}

/// Returns true if the upcoming tokens look like a lambda parameter list:
/// `ident (,ident)* ->`.
/// Does not consume any tokens.
pub fn hasLambdaParams(this: *const This) bool {
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
pub fn hasLambdaBodyAhead(this: *const This) bool {
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
pub fn checkLabeledTrailingLambda(this: *const This) bool {
    const i = this.current;
    const toks = this.tokens;
    return i + 2 < toks.len and
        toks[i].kind == .identifier and
        toks[i + 1].kind == .colon and
        toks[i + 2].kind == .leftBrace;
}

/// Parses the body of a lambda after `{` has been consumed.
/// Grammar: `(ident (, ident)* ->)? (stmt ';'?)* }`
///
/// The statement separator is optional, as it is in the lambda body
/// `parsePrimary` reads: the last expression of the body is its value and takes
/// no `;` (decision 2, and decision 8 §5.1 P3 for a `case` arm), while the
/// statements before it are separated by one.
pub fn parseLambdaBody(this: *This, alloc: std.mem.Allocator) ParseError!FunctionExpr {
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
        _ = this.match(.semicolon);
        try stmts.append(alloc, .{ .expr = expr });
    }
    _ = try this.consume(.rightBrace);

    return .{
        .loc = locFromToken(startTok),
        .kind = .{
            .syntax = .lambda,
            .params = try paramList.toOwnedSlice(alloc),
            .body = try stmts.toOwnedSlice(alloc),
        },
    };
}

pub fn parseCallArgs(this: *This, alloc: std.mem.Allocator) ParseError![]CallArg {
    _ = try this.consume(.leftParenthesis);
    var args: std.ArrayList(CallArg) = .empty;
    errdefer {
        for (args.items) |*a| a.deinit(alloc);
        args.deinit(alloc);
    }

    // D2 — once the call switches to named-arg form, the remaining positional
    // args are rejected (Kotlin-style). Tracks whether *any* prior arg was
    // labeled; `..base` spread is allowed before or after named args.
    var saw_named = false;
    while (!this.check(.rightParenthesis) and !this.check(.endOfFile)) {
        // Collect comments before this argument
        var argComments: std.ArrayList([]const u8) = .empty;
        errdefer argComments.deinit(alloc);
        while (this.isComment()) {
            const cTok = this.advance();
            try argComments.append(alloc, try alloc.dupe(u8, commentText(cTok.lexeme)));
        }

        // Spread argument used by record/variant update calls, e.g. `Ctor(..base, x: 1)`.
        if (this.match(.dotDot)) {
            const valExpr = try this.parseExpr(alloc);
            const valPtr = try this.boxExpr(alloc, valExpr);
            const commentsSlice = try argComments.toOwnedSlice(alloc);
            try args.append(alloc, .{ .label = "..", .value = valPtr, .comments = commentsSlice });
            if (!this.match(.comma)) break;
            continue;
        }

        // Detect named arg: ident : expr (`get`/`set` are valid labels)
        const arg_tok = this.peek();
        const label: ?[]const u8 = blk: {
            if (This.isMemberName(this.peek().kind)) {
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

        if (label == null and saw_named) {
            this.parseError = ParseErrorInfo.fromToken(.fnParamPositionalAfterNamed, arg_tok);
            return ParseError.UnexpectedToken;
        }
        if (label != null) saw_named = true;

        const valExpr = try this.parseExpr(alloc);
        const valPtr = try this.boxExpr(alloc, valExpr);
        const commentsSlice = try argComments.toOwnedSlice(alloc);
        try args.append(alloc, .{ .label = label, .value = valPtr, .comments = commentsSlice });

        if (!this.match(.comma)) break;
    }

    _ = try this.consume(.rightParenthesis);
    return args.toOwnedSlice(alloc);
}

/// Parses zero or more trailing lambda blocks:
///   `{ params? -> body }`  or  `label: { params? -> body }`
pub fn parseTrailingLambdas(this: *This, alloc: std.mem.Allocator) ParseError![]TrailingLambda {
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
        } else if (this.check(.rightArrow)) {
            // `{ -> body }` — explicit no-param lambda; consume the arrow.
            _ = this.advance();
        }

        // The shared block body — the `{`, the optional label and the
        // `a, b ->` parameter list are this block's prologue. The semicolon
        // policy stays `.required`, which a trailing lambda has always applied;
        // what it gains is comment handling and empty-line tracking.
        const body = try this.parseBlockBody(alloc, .{
            .trackEmptyLines = true,
            .handleComments = true,
            .semicolonPolicy = .required,
            // A trailing lambda is another function: a fresh static prefix
            // of `use` (`use memo { -> return … }` keeps the enclosing one).
            .useAfterBranchGuard = true,
            .freshUseScope = true,
        });

        try lambdas.append(alloc, .{
            .label = label,
            .params = try paramList.toOwnedSlice(alloc),
            .body = body,
        });
    }

    return lambdas.toOwnedSlice(alloc);
}

/// Parses a `loop` expression:
///   `loop (iter) { param -> body }`
///   `loop (iter, 0..) { item, i -> body }`
///   `loop (start..end) { i -> body }`
///   `loop (start..) { i -> body }`
pub fn parseLoopExpr(this: *This, alloc: std.mem.Allocator) ParseError!LoopExpr {
    const loopTok = this.advance(); // consume 'loop'

    // `loop await (iter)` — iterate an `@FutureGenerator`, awaiting each item.
    const awaitLoop = this.match(.await);

    // Optional loop label: `loop :acc (iter) { ... }`.
    var label: ?[]const u8 = null;
    if (this.check(.colon)) {
        _ = this.advance();
        label = (try this.consume(.identifier)).lexeme;
    }

    // `loop { … break; }` (decision 8 §10) repeats until a break: it is the
    // condition loop over `true`.
    var iterPtr: *Expr = undefined;
    var indexPtr: ?*Expr = null;
    var condition = false;
    if (this.check(.leftBrace)) {
        iterPtr = try this.boxExpr(alloc, Expr{ .identifier = .{ .loc = locFromToken(loopTok), .kind = .{ .ident = "true" } } });
        condition = true;
    } else {
        _ = try this.consume(.leftParenthesis);

        // Parse primary iterator expression (a collection, a range or a condition)
        const iterExpr = try this.parseRangeExpr(alloc);
        iterPtr = try this.boxExpr(alloc, iterExpr);

        // Optional index range: `loop (iter, 0..)`
        if (this.match(.comma)) {
            const idxExpr = try this.parseRangeExpr(alloc);
            indexPtr = try this.boxExpr(alloc, idxExpr);
        }

        _ = try this.consume(.rightParenthesis);
        condition = indexPtr == null and isSyntacticCondition(iterPtr.*);
    }
    _ = try this.consume(.leftBrace);

    // Parameter list `param1, param2 ->` — only when the body opens with
    // names followed by `->`; a condition loop's body starts with statements.
    var params: std.ArrayList([]const u8) = .empty;
    errdefer params.deinit(alloc);
    var paramsLoc = locFromToken(loopTok);
    if (loopParamsAhead(this)) {
        paramsLoc = locFromToken(this.peek());
        while (this.check(.identifier)) {
            try params.append(alloc, this.advance().lexeme);
            if (!this.match(.comma)) break;
        }
        _ = try this.consume(.rightArrow);
    }

    // The shared block body — the `{` and the `x, y ->` parameter list are this
    // block's prologue. The semicolon policy stays `.required`, which is what a
    // loop body has always applied. What it gains is comment handling and
    // empty-line tracking: a `//` inside a `loop (…) { x -> … }` body was a
    // parse error, and a blank line inside one was dropped by the printer.
    const body = try this.parseBlockBody(alloc, .{
        .trackEmptyLines = true,
        .handleComments = true,
        .semicolonPolicy = .required,
        // A loop body is a branch's block, not a function: it inherits the
        // enclosing body's static prefix, which the `loop` itself just ended,
        // so a `use` inside it is `useAfterBranch`.
        .useAfterBranchGuard = true,
    });

    return .{
        .loc = locFromToken(loopTok),
        .iter = iterPtr,
        .indexRange = indexPtr,
        .params = try params.toOwnedSlice(alloc),
        .paramsLoc = paramsLoc,
        .condition = condition,
        .body = body,
        .awaitLoop = awaitLoop,
        .label = label,
    };
}

/// An expression that is boolean by its shape: a comparison, `&&`/`||`, `not`,
/// or the literal `true`/`false` (parenthesised or not).
fn isSyntacticCondition(e: Expr) bool {
    return switch (e) {
        .binaryOp => |bin| switch (bin.op) {
            .eq, .ne, .lt, .gt, .lte, .gte, .@"and", .@"or" => true,
            else => false,
        },
        .unaryOp => |un| un.op == .not,
        .identifier => |id| switch (id.kind) {
            .ident => |n| std.mem.eql(u8, n, "true") or std.mem.eql(u8, n, "false"),
            else => false,
        },
        .collection => |col| switch (col.kind) {
            .grouped => |inner| isSyntacticCondition(inner.*),
            else => false,
        },
        else => false,
    };
}

/// True when the tokens at the cursor are `name (, name)* ->` — a loop's
/// parameter list rather than the first statement of its body.
fn loopParamsAhead(this: *This) bool {
    var i: usize = 0;
    while (true) {
        if (this.peekAt(i).kind != .identifier) return false;
        i += 1;
        switch (this.peekAt(i).kind) {
            .rightArrow => return true,
            .comma => i += 1,
            else => return false,
        }
    }
}

/// Parses a range expression `expr..` or `expr..expr`, or falls back to
/// a plain `parseEqExpr` if `..` is not present.
pub fn parseRangeExpr(this: *This, alloc: std.mem.Allocator) ParseError!Expr {
    const start = try this.parseBinaryExpr(alloc, prec.equality);
    // Nothing between here and the box can fail (`check`/`advance` do not), so
    // `start` needs no errdefer of its own — and must not have one: once boxed,
    // the box owns its children.
    if (!this.check(.dotDot)) return start;
    const dotTok = this.advance(); // consume '..'
    const startPtr = try this.boxExprOwned(alloc, start);
    errdefer {
        startPtr.deinit(alloc);
        alloc.destroy(startPtr);
    }
    // Optional end: `0..10` vs `0..`
    // `]` closes an open-ended slice `xs[0..]`, like `)` closes `loop (0..)`.
    const hasEnd = !this.check(.rightParenthesis) and !this.check(.comma) and
        !this.check(.rightSquareBracket) and !this.check(.endOfFile);
    if (hasEnd) {
        const end = try this.parseBinaryExpr(alloc, prec.equality);
        const endPtr = try this.boxExprOwned(alloc, end);
        return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = endPtr } } } };
    }
    return Expr{ .collection = .{ .loc = locFromToken(dotTok), .kind = .{ .range = .{ .start = startPtr, .end = null } } } };
}

// ── string interpolation (`${…}`) ───────────────────────────────────────────

/// Index of the next unescaped `${` at/after `from`, or null.
fn findInterpStart(s: []const u8, from: usize) ?usize {
    var i = from;
    while (i + 1 < s.len) {
        if (s[i] == '\\') {
            i += 2;
            continue;
        }
        if (s[i] == '$' and s[i + 1] == '{') return i;
        i += 1;
    }
    return null;
}

/// Index of the `}` matching the `{` at `open` (brace-depth and nested-string
/// aware — mirrors `Lexer.scanInterpolation`), or null when unterminated.
fn findInterpEnd(s: []const u8, open: usize) ?usize {
    var depth: usize = 1;
    var i = open + 1;
    while (i < s.len) {
        const c = s[i];
        if (c == '{') {
            depth += 1;
        } else if (c == '}') {
            depth -= 1;
            if (depth == 0) return i;
        } else if (c == '"') {
            i += 1;
            while (i < s.len and s[i] != '"') {
                if (s[i] == '\\') i += 1;
                i += 1;
            }
            if (i >= s.len) return null;
        }
        i += 1;
    }
    return null;
}

/// Absolute source position of one byte of a string literal's content.
const ContentPos = struct { line: usize, col: usize, offset: usize };

/// Maps byte `idx` of a string literal's CONTENT back to its position in the
/// source file. "Content" is the literal minus its delimiters (`"…"`,
/// `"""…"""`) or, for a `\\ …` line string, the materialised join of its
/// lines. In both cases content line `k` is source line `tok.line + k`; only
/// the column base differs, because a `\\` line's indent and prefix are not
/// part of the content.
///
/// This is what lets an interpolation hole (`${name}`) be parsed on its own
/// and still report absolute locations: a hole token's offset inside the hole
/// slice is also its displacement inside the content.
fn contentPos(tok: Token, content: []const u8, idx: usize) ContentPos {
    // Content line index of `idx` and the byte column within that line.
    var lineIdx: usize = 0;
    var lineBegin: usize = 0;
    var i: usize = 0;
    const stop = @min(idx, content.len);
    while (i < stop) : (i += 1) {
        if (content[i] == '\n') {
            lineIdx += 1;
            lineBegin = i + 1;
        }
    }
    const colInLine = @min(idx, content.len) - lineBegin;

    if (tok.kind != .linesStringLiteral) {
        // The content is a verbatim slice of the source, so offsets are
        // linear and every line after the first starts at column 1.
        const prefix: usize = if (tok.kind == .multilineStringLiteral) 3 else 1;
        return .{
            .line = tok.line + lineIdx,
            .col = (if (lineIdx == 0) tok.col + prefix else 1) + colInLine,
            .offset = tok.offset + prefix + idx,
        };
    }

    // `\\ …` line string: content line k is the text after line k's
    // `<indent>\\` prefix, which `materializeLineString` stripped.
    var lexLineStart: usize = 0;
    var it = std.mem.splitScalar(u8, tok.lexeme, '\n');
    var k: usize = 0;
    while (it.next()) |line| : (k += 1) {
        if (k == lineIdx) {
            const indent = line.len - std.mem.trimStart(u8, line, " \t\r").len;
            const base = indent + "\\\\".len;
            return .{
                .line = tok.line + lineIdx,
                .col = (if (lineIdx == 0) tok.col else 1) + base + colInLine,
                .offset = tok.offset + lexLineStart + base + colInLine,
            };
        }
        lexLineStart += line.len + 1;
    }
    return .{ .line = tok.line, .col = tok.col, .offset = tok.offset };
}

/// Rewrites a sub-lexed hole's tokens from hole-relative to absolute source
/// positions. `holeStart` is the index of the hole's first byte (just past
/// `${`) inside `content`.
fn retargetHoleTokens(holeTokens: []Token, tok: Token, content: []const u8, holeStart: usize) void {
    for (holeTokens) |*ht| {
        const pos = contentPos(tok, content, holeStart + ht.offset);
        ht.line = pos.line;
        ht.col = pos.col;
        ht.offset = pos.offset;
    }
}

/// Materialize a `\\ …` line string's content: strip each line's leading
/// whitespace + `\\` prefix and join the remainders with newlines. The
/// content then follows the same conventions as `"""` literals (escape
/// sequences resolve in the target; `${…}` interpolates).
fn materializeLineString(alloc: std.mem.Allocator, lexeme: []const u8) ParseError![]const u8 {
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(alloc);
    var lines = std.mem.splitScalar(u8, lexeme, '\n');
    var first = true;
    while (lines.next()) |line| {
        if (!first) try buf.append(alloc, '\n');
        first = false;
        const trimmed = std.mem.trimStart(u8, line, " \t\r");
        // Every line of the token starts with `\\` (the lexer guarantees it).
        try buf.appendSlice(alloc, if (trimmed.len >= 2) trimmed[2..] else "");
    }
    return buf.toOwnedSlice(alloc);
}

/// Builds either a plain `stringLit` or, when the content contains `${…}`
/// interpolations, a `stringTemplate` whose holes are parsed expressions.
/// Hole sources are sub-lexed/sub-parsed on their own; `retargetHoleTokens`
/// then maps the sub-lexer's hole-relative positions back onto the source, so
/// a hole's AST locs are absolute like every other node's.
fn makeStringExpr(this: *This, alloc: std.mem.Allocator, tok: Token, content: []const u8, multiline: bool) ParseError!Expr {
    const loc = locFromToken(tok);
    if (findInterpStart(content, 0) == null)
        return Expr{ .literal = .{ .loc = loc, .kind = .{ .stringLit = content } } };

    const badInterp = ParseErrorInfo.fromToken(.badInterpolation, tok);

    var parts: std.ArrayList(ast.StringTemplatePartOf(.untyped)) = .empty;
    errdefer {
        for (parts.items) |*p| switch (p.*) {
            .text => {},
            .expr => |e| {
                e.deinit(alloc);
                alloc.destroy(e);
            },
        };
        parts.deinit(alloc);
    }

    var cursor: usize = 0;
    while (findInterpStart(content, cursor)) |start| {
        if (start > cursor)
            try parts.append(alloc, .{ .text = content[cursor..start] });

        const close = findInterpEnd(content, start + 1) orelse {
            this.parseError = badInterp;
            return ParseError.UnexpectedToken;
        };
        const holeSrc = content[start + 2 .. close];

        var sublex = lexer.Lexer.init(holeSrc);
        defer sublex.deinit(alloc);
        const holeTokens = sublex.scanAll(alloc) catch {
            this.parseError = badInterp;
            return ParseError.UnexpectedToken;
        };
        retargetHoleTokens(sublex.tokens.items, tok, content, start + "${".len);
        var sub = parser.Parser.init(holeTokens);
        const holePtr = try alloc.create(Expr);
        errdefer alloc.destroy(holePtr);
        holePtr.* = sub.parseExpr(alloc) catch |err| switch (err) {
            ParseError.OutOfMemory => return err,
            else => {
                this.parseError = sub.parseError orelse badInterp;
                return ParseError.UnexpectedToken;
            },
        };
        if (!sub.check(.endOfFile)) {
            holePtr.deinit(alloc); // box itself is freed by the errdefer above
            this.parseError = badInterp;
            return ParseError.UnexpectedToken;
        }
        try parts.append(alloc, .{ .expr = holePtr });
        cursor = close + 1;
    }
    if (cursor < content.len)
        try parts.append(alloc, .{ .text = content[cursor..] });

    return Expr{ .literal = .{ .loc = loc, .kind = .{ .stringTemplate = .{
        .multiline = multiline,
        .parts = try parts.toOwnedSlice(alloc),
    } } } };
}
