/// Type error diagnostics and comptime validation for the botopink type checker.
const std = @import("std");
const T = @import("./types.zig");
const ast = @import("../ast.zig");
const render = @import("./render.zig");

pub const Loc = ast.Loc;

// ── ComptimeError ─────────────────────────────────────────────────────────────

/// Describes a `comptime` expression that cannot be evaluated at compile time.
pub const ComptimeError = struct {
    /// The identifier that triggered the error (e.g. `"greeting"`).
    ident: []const u8,
    /// Source location of the offending node.
    loc: ast.Loc,
    /// Why the expression cannot be evaluated. A runtime identifier is the
    /// historical case; the other two are structurally legal folds that
    /// evaluate to an error (C4b) instead of a silent `null`.
    reason: Reason = .runtimeIdentifier,

    pub const Reason = enum { runtimeIdentifier, divisionByZero, negatedNonNumber };

    /// Render the error to an allocated string. Caller owns the result.
    pub fn renderAlloc(this: ComptimeError, allocator: std.mem.Allocator, src: []const u8) ![]u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        try this.renderTo(&aw.writer, src);
        return aw.toOwnedSlice();
    }

    fn renderTo(this: ComptimeError, writer: anytype, src: []const u8) !void {
        const line_text = render.extractLine(src, this.loc.line);
        const line_w = render.digitWidth(this.loc.line);
        const gutter = line_w + 1;

        try writer.writeAll("error comptime: expression cannot be evaluated at compile time\n");
        try render.padSpaces(writer, gutter - 1);
        try writer.print("┌─ :{d}:{d}\n", .{ this.loc.line, this.loc.col });
        try render.padSpaces(writer, gutter);
        try writer.writeAll("│\n");
        try writer.print("{d} │ {s}\n", .{ this.loc.line, line_text });
        try render.padSpaces(writer, gutter);
        try writer.writeAll("│ ");
        try render.padSpaces(writer, this.loc.col - 1);
        for (0..this.ident.len) |_| try writer.writeByte('^');
        try writer.writeAll("\n\n");
        switch (this.reason) {
            .runtimeIdentifier => try writer.print("  '{s}' is a runtime identifier\n", .{this.ident}),
            .divisionByZero => try writer.writeAll("  division by zero\n"),
            .negatedNonNumber => try writer.writeAll("  only a number can be negated\n"),
        }
    }
};

// ── TypeError ─────────────────────────────────────────────────────────────────

/// The kind of type error that occurred.
pub const TypeErrorKind = union(enum) {
    /// Two types could not be unified.
    typeMismatch: struct {
        expected: *T.Type,
        got: *T.Type,
    },
    /// Identifier not found in scope.
    unboundVariable: []const u8,
    /// Wrong number of arguments in a call.
    arityMismatch: struct {
        name: []const u8,
        expected: usize,
        got: usize,
    },
    /// Field does not exist on a record or struct type.
    unknownField: struct {
        typeName: []const u8,
        field: []const u8,
    },
    /// Type is not a record or struct (field access on incompatible type).
    notARecord: []const u8,
    /// Occurs check failed — would create an infinite recursive type.
    recursiveType: T.TypeId,
    /// Type name used in source is not registered in the environment.
    unknownTypeName: []const u8,
    /// Record constructor is missing a required field.
    missingField: struct {
        typeName: []const u8,
        field: []const u8,
    },
    /// `obj.method()` where an `implement`/`extend` provides `method` for the
    /// receiver type but its symbol has not been activated. `hintSym` is the
    /// symbol to activate (`hintSym*`).
    methodNotActive: struct {
        typeName: []const u8,
        method: []const u8,
        hintSym: []const u8,
    },
    /// `obj.method()` resolves to two or more activated extensions; the call must
    /// be qualified (`symA.method(obj)`).
    ambiguousExtension: struct {
        typeName: []const u8,
        method: []const u8,
        symA: []const u8,
        symB: []const u8,
    },
    /// `name*` where `name` does not name an `implement`/`extend` symbol.
    notAnExtension: []const u8,
    /// A contract-free `extend T { … }` block. Methods may only be added to a
    /// type through `implement <Interface> for T`, so they satisfy an interface.
    /// Payload is the extended type `T`.
    extendRequiresInterface: []const u8,
    /// A bare `name*;` naming a locally-declared extension. Extensions declared in
    /// the current module are auto-applied; `*` is only for imports. Payload is `name`.
    redundantActivation: []const u8,
    /// `use` appeared in a function whose return type does not implement `@Context`.
    /// Payload is the rendered return type (e.g. `"string"`, `"void"`).
    useNotAllowed: []const u8,
    /// The expression used with `use` does not implement `@Context`.
    /// Payload is the rendered expression type.
    useNotContext: []const u8,
    /// A `use` expression's ContextBase diverges from the function's ContextBase.
    contextMismatch: struct {
        fnBase: []const u8,
        useBase: []const u8,
    },
    /// Decision 96 — two `use`s in ONE body anchored at different bases. The
    /// anchor is a property of the function, fixed by its first `use`, so this
    /// reds at the SECOND one and names both bases and the line that fixed it.
    contextBaseMixed: struct {
        anchorBase: []const u8,
        anchorLine: usize,
        useBase: []const u8,
    },
    /// `use` in a body whose return type implements `@Context` but whose fn does
    /// not carry `#[@context]` (decision 88). Payload: the fn's name and its
    /// rendered return type.
    useWithoutContextEffect: struct {
        fnName: []const u8,
        returnType: []const u8,
    },
    /// `throw` used in a function whose return type is not `@Result<D, E>`.
    throwWithoutResult,
    /// An `implement` block does not provide a method required by an interface.
    missingMethod: struct {
        typeName: []const u8,
        interfaceName: []const u8,
        method: []const u8,
    },
    /// An `implement` block declares a method not present in any implemented interface.
    unknownMethod: struct {
        typeName: []const u8,
        method: []const u8,
    },
    /// A qualified method's interface prefix is not one of the implemented interfaces.
    unknownInterface: struct {
        qualifier: []const u8,
        method: []const u8,
    },
    /// An unqualified method name is declared by more than one implemented interface.
    ambiguousMethod: struct {
        method: []const u8,
        interfaceA: []const u8,
        interfaceB: []const u8,
    },
    /// A comptime `typeparam` argument's type is not among the declared constraints.
    typeparamConstraint: struct {
        /// The constrained parameter's name.
        paramName: []const u8,
        /// The offending argument's type.
        got: *T.Type,
        /// The accepted constraint type names.
        constraints: []const []const u8,
    },
    /// `try` / `catch` applied to a value whose type is not `@Result<D, E>`.
    tryOnNonResult: *T.Type,
    /// A `case` expression does not cover every possibility of its subject.
    /// `missing` lists the uncovered enum variants; it is empty for open
    /// domains (e.g. `string`, `i32`, `unknown`), where a wildcard `_` arm is
    /// required instead.
    nonExhaustive: struct {
        typeName: []const u8,
        missing: []const []const u8,
        /// What the entries of `missing` are, for the message. Decision 8 §3.3
        /// made a union a `case` domain, and its uncovered entries are its
        /// **members**, not variants.
        missingLabel: []const u8 = "variant(s)",
    },
    /// A `case` arm can never match because an earlier arm (a wildcard, a
    /// whole-value binding, or the same variant) already covers it.
    redundantPattern: struct {
        typeName: []const u8,
        /// Short description of the unreachable arm (e.g. `"variant 'Red'"`).
        description: []const u8,
    },
    /// A rule-specific diagnostic with a ready-made message (and optional hint).
    /// Used for validations that don't map onto the structured kinds above
    /// (e.g. async/generator rules around `#[@<effect>]` / `await` / `yield`).
    custom: struct {
        message: []const u8,
        hint: ?[]const u8 = null,
    },
};

/// A type error with its source location.
pub const TypeError = struct {
    kind: TypeErrorKind,
    /// Source location of the triggering expression, if known.
    loc: ?Loc = null,

    pub fn withLoc(this: TypeError, loc: Loc) TypeError {
        var t = this;
        t.loc = loc;
        return t;
    }

    pub fn typeMismatch(expected: *T.Type, got: *T.Type) TypeError {
        return .{ .kind = .{ .typeMismatch = .{ .expected = expected, .got = got } } };
    }

    pub fn unboundVariable(name: []const u8) TypeError {
        return .{ .kind = .{ .unboundVariable = name } };
    }

    pub fn arityMismatch(name: []const u8, expected: usize, got: usize) TypeError {
        return .{ .kind = .{ .arityMismatch = .{ .name = name, .expected = expected, .got = got } } };
    }

    pub fn unknownField(typeName: []const u8, field: []const u8) TypeError {
        return .{ .kind = .{ .unknownField = .{ .typeName = typeName, .field = field } } };
    }

    pub fn notARecord(typeName: []const u8) TypeError {
        return .{ .kind = .{ .notARecord = typeName } };
    }

    pub fn recursiveType(id: T.TypeId) TypeError {
        return .{ .kind = .{ .recursiveType = id } };
    }

    pub fn unknownTypeName(name: []const u8) TypeError {
        return .{ .kind = .{ .unknownTypeName = name } };
    }

    pub fn missingField(typeName: []const u8, field: []const u8) TypeError {
        return .{ .kind = .{ .missingField = .{ .typeName = typeName, .field = field } } };
    }

    pub fn methodNotActive(typeName: []const u8, method: []const u8, hintSym: []const u8) TypeError {
        return .{ .kind = .{ .methodNotActive = .{ .typeName = typeName, .method = method, .hintSym = hintSym } } };
    }

    pub fn ambiguousExtension(typeName: []const u8, method: []const u8, symA: []const u8, symB: []const u8) TypeError {
        return .{ .kind = .{ .ambiguousExtension = .{ .typeName = typeName, .method = method, .symA = symA, .symB = symB } } };
    }

    pub fn notAnExtension(name: []const u8) TypeError {
        return .{ .kind = .{ .notAnExtension = name } };
    }

    pub fn extendRequiresInterface(typeName: []const u8) TypeError {
        return .{ .kind = .{ .extendRequiresInterface = typeName } };
    }

    pub fn redundantActivation(name: []const u8) TypeError {
        return .{ .kind = .{ .redundantActivation = name } };
    }

    pub fn useNotAllowed(returnType: []const u8) TypeError {
        return .{ .kind = .{ .useNotAllowed = returnType } };
    }

    pub fn useNotContext(exprType: []const u8) TypeError {
        return .{ .kind = .{ .useNotContext = exprType } };
    }

    pub fn contextMismatch(fnBase: []const u8, useBase: []const u8) TypeError {
        return .{ .kind = .{ .contextMismatch = .{ .fnBase = fnBase, .useBase = useBase } } };
    }

    pub fn contextBaseMixed(anchorBase: []const u8, anchorLine: usize, useBase: []const u8) TypeError {
        return .{ .kind = .{ .contextBaseMixed = .{ .anchorBase = anchorBase, .anchorLine = anchorLine, .useBase = useBase } } };
    }

    pub fn useWithoutContextEffect(fnName: []const u8, returnType: []const u8) TypeError {
        return .{ .kind = .{ .useWithoutContextEffect = .{ .fnName = fnName, .returnType = returnType } } };
    }

    pub fn throwWithoutResult() TypeError {
        return .{ .kind = .throwWithoutResult };
    }

    pub fn missingMethod(typeName: []const u8, interfaceName: []const u8, method: []const u8) TypeError {
        return .{ .kind = .{ .missingMethod = .{ .typeName = typeName, .interfaceName = interfaceName, .method = method } } };
    }

    pub fn unknownMethod(typeName: []const u8, method: []const u8) TypeError {
        return .{ .kind = .{ .unknownMethod = .{ .typeName = typeName, .method = method } } };
    }

    pub fn unknownInterface(qualifier: []const u8, method: []const u8) TypeError {
        return .{ .kind = .{ .unknownInterface = .{ .qualifier = qualifier, .method = method } } };
    }

    pub fn ambiguousMethod(method: []const u8, interfaceA: []const u8, interfaceB: []const u8) TypeError {
        return .{ .kind = .{ .ambiguousMethod = .{ .method = method, .interfaceA = interfaceA, .interfaceB = interfaceB } } };
    }

    pub fn typeparamConstraint(paramName: []const u8, got: *T.Type, constraints: []const []const u8) TypeError {
        return .{ .kind = .{ .typeparamConstraint = .{ .paramName = paramName, .got = got, .constraints = constraints } } };
    }

    pub fn tryOnNonResult(ty: *T.Type) TypeError {
        return .{ .kind = .{ .tryOnNonResult = ty } };
    }

    pub fn nonExhaustive(typeName: []const u8, missing: []const []const u8) TypeError {
        return .{ .kind = .{ .nonExhaustive = .{ .typeName = typeName, .missing = missing } } };
    }

    /// `nonExhaustive` naming what the uncovered entries are — `"member(s)"` for
    /// a union (§3.3), `"variant(s)"` for an enum.
    pub fn nonExhaustiveOf(typeName: []const u8, missing: []const []const u8, missingLabel: []const u8) TypeError {
        return .{ .kind = .{ .nonExhaustive = .{
            .typeName = typeName,
            .missing = missing,
            .missingLabel = missingLabel,
        } } };
    }

    pub fn redundantPattern(typeName: []const u8, description: []const u8) TypeError {
        return .{ .kind = .{ .redundantPattern = .{ .typeName = typeName, .description = description } } };
    }

    pub fn custom(msg: []const u8, hint: ?[]const u8) TypeError {
        return .{ .kind = .{ .custom = .{ .message = msg, .hint = hint } } };
    }

    /// Render a concise, human-readable message for this error. Caller owns the
    /// returned slice. Used by `botopink check` and the language server.
    pub fn message(this: TypeError, gpa: std.mem.Allocator) ![]u8 {
        return switch (this.kind) {
            .typeMismatch => |m| blk: {
                // A union's short label has to spell its members: "expected
                // union" names nothing the author wrote, and a union is the one
                // kind whose identity *is* its members (decision 8 §3).
                const expected = try typeLabelAlloc(gpa, m.expected);
                defer gpa.free(expected);
                const got = try typeLabelAlloc(gpa, m.got);
                defer gpa.free(got);
                break :blk std.fmt.allocPrint(gpa, "type mismatch: expected {s}, got {s}", .{ expected, got });
            },
            .unboundVariable => |n| std.fmt.allocPrint(gpa, "unbound variable '{s}'", .{n}),
            .arityMismatch => |a| std.fmt.allocPrint(gpa, "'{s}' expects {d} argument(s), got {d}", .{ a.name, a.expected, a.got }),
            .unknownField => |u| std.fmt.allocPrint(gpa, "unknown field '{s}' on type '{s}'", .{ u.field, u.typeName }),
            .notARecord => |n| std.fmt.allocPrint(gpa, "type '{s}' is not a record or struct", .{n}),
            .recursiveType => std.fmt.allocPrint(gpa, "recursive type detected", .{}),
            .unknownTypeName => |n| std.fmt.allocPrint(gpa, "unknown type '{s}'", .{n}),
            .missingField => |m| std.fmt.allocPrint(gpa, "missing required field '{s}' on type '{s}'", .{ m.field, m.typeName }),
            .useNotAllowed => |r| std.fmt.allocPrint(gpa, "use-of-non-context-fn: `use` not allowed: function returns '{s}' which does not implement @Context", .{r}),
            .useNotContext => |e| std.fmt.allocPrint(gpa, "use-of-non-context-fn: `use` requires @Context: '{s}' does not implement @Context", .{e}),
            .contextMismatch => |m| std.fmt.allocPrint(gpa, "context-anchor-violation: function returns @Context<{s}, _> but `use` returns @Context<{s}, _>", .{ m.fnBase, m.useBase }),
            .contextBaseMixed => |m| std.fmt.allocPrint(gpa, "context-anchor-violation: every `use` in one function resolves against the same ContextBase: this body's is @Context<{s}, _>, fixed by the `use` on line {d}, and this one is @Context<{s}, _>", .{ m.anchorBase, m.anchorLine, m.useBase }),
            .useWithoutContextEffect => |u| std.fmt.allocPrint(gpa, "use-without-context-effect: `use` needs `#[@context]` on the enclosing fn '{s}': its return type '{s}' implements @Context, but a body with no effect annotation does not activate a hook", .{ u.fnName, u.returnType }),
            .throwWithoutResult => std.fmt.allocPrint(gpa, "effect-throw-without-fallible-channel: `throw` is only valid inside a fn whose effect declares an error channel: #[@result], #[@future], #[@iterator], or #[@futureGenerator]", .{}),
            .methodNotActive => |m| std.fmt.allocPrint(gpa, "'{s}' has no active method '{s}' — activate the extension with `{s}*`", .{ m.typeName, m.method, m.hintSym }),
            .ambiguousExtension => |a| std.fmt.allocPrint(gpa, "'{s}.{s}' is provided by both '{s}' and '{s}' — qualify the call, e.g. `{s}.{s}(obj)`", .{ a.typeName, a.method, a.symA, a.symB, a.symA, a.method }),
            .notAnExtension => |name| std.fmt.allocPrint(gpa, "'{s}' does not name an implement/extend symbol", .{name}),
            .extendRequiresInterface => |t| std.fmt.allocPrint(gpa, "`extend {s}` adds methods without a contract — use `implement <Behavior> for {s}` so the methods satisfy a behavior", .{ t, t }),
            .redundantActivation => |name| std.fmt.allocPrint(gpa, "`{s}*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports", .{name}),
            .missingMethod => |m| std.fmt.allocPrint(gpa, "'{s}' does not implement '{s}' required by behavior '{s}'", .{ m.typeName, m.method, m.interfaceName }),
            .unknownMethod => |m| std.fmt.allocPrint(gpa, "'{s}' is not declared in any behavior implemented for '{s}'", .{ m.method, m.typeName }),
            .unknownInterface => |u| std.fmt.allocPrint(gpa, "'{s}' is not a behavior implemented here (method '{s}')", .{ u.qualifier, u.method }),
            .ambiguousMethod => |a| std.fmt.allocPrint(gpa, "'{s}' is declared by both '{s}' and '{s}' — qualify it", .{ a.method, a.interfaceA, a.interfaceB }),
            .typeparamConstraint => |c| std.fmt.allocPrint(gpa, "'{s}' has type '{s}', which does not satisfy its type constraint", .{ c.paramName, typeLabel(c.got) }),
            .tryOnNonResult => |ty| std.fmt.allocPrint(gpa, "`try` requires a @Result<D, E> value, found '{s}'", .{typeLabel(ty)}),
            .nonExhaustive => |n| nonExhaustiveMessage(gpa, n),
            .redundantPattern => |r| std.fmt.allocPrint(gpa, "unreachable `case` arm ({s}): {s} is already covered by an earlier arm", .{ r.typeName, r.description }),
            .custom => |c| std.fmt.allocPrint(gpa, "{s}", .{c.message}),
        };
    }
};

/// Build the `nonExhaustive` message: either "requires a wildcard" (open
/// domain) or "missing variants: A, B" (enum). Caller owns the result.
///
/// Both forms open with **`case` … is not exhaustive**, the wording
/// `1.0.4-beta/MIGRATION.md:300` publishes for this rule (`not exhaustive`,
/// `use _ {`) and the one decision 8 §5.4's reject fixtures match against. The
/// text that stood here said "non-exhaustive", which no published sketch and no
/// fixture asks for; MIGRATION's own note ("the implementing fronts fix the
/// wording") makes this the front that settles it. `comptime/snapshot.zig` keeps
/// its own shorter title, so no error snapshot moves with this.
fn nonExhaustiveMessage(gpa: std.mem.Allocator, n: anytype) ![]u8 {
    if (n.missing.len == 0) {
        return std.fmt.allocPrint(
            gpa,
            "`case` on '{s}' is not exhaustive: nothing covers the remaining values — use `_ {{ … }}`",
            .{n.typeName},
        );
    }
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(gpa);
    for (n.missing, 0..) |name, i| {
        if (i > 0) try list.appendSlice(gpa, ", ");
        try list.appendSlice(gpa, name);
    }
    return std.fmt.allocPrint(gpa, "`case` on '{s}' is not exhaustive: missing {s} {s}", .{ n.typeName, n.missingLabel, list.items });
}

/// `typeLabel`, with a union spelled out as `A | B`. Owned by the caller.
/// Every other kind is `typeLabel`'s own text, duplicated, so a message that
/// goes through this renders byte-identically to one that does not.
fn typeLabelAlloc(gpa: std.mem.Allocator, ty: *T.Type) ![]const u8 {
    const t = ty.deref();
    if (t.* != .union_) return gpa.dupe(u8, typeLabel(t));
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(gpa);
    for (t.union_, 0..) |member, i| {
        if (i > 0) try buf.appendSlice(gpa, " | ");
        const label = try typeLabelAlloc(gpa, member);
        defer gpa.free(label);
        try buf.appendSlice(gpa, label);
    }
    return buf.toOwnedSlice(gpa);
}

/// Best-effort short label for a type, used in error messages.
fn typeLabel(ty: *T.Type) []const u8 {
    return switch (ty.deref().*) {
        .named => |n| n.name,
        .func => "function",
        .union_ => "union",
        .record => "record",
        .typeVar => "_",
    };
}

// ── Comptime validation ───────────────────────────────────────────────────────

/// The names a `comptime { … }` block has declared so far, innermost first.
/// Built on the Zig stack as `validateBody` walks a block, so no allocator is
/// needed; `eval.zig` mirrors it with real values when the block is folded.
const CtScope = struct {
    name: []const u8,
    parent: ?*const CtScope,

    fn has(scope: ?*const CtScope, name: []const u8) bool {
        var cur = scope;
        while (cur) |s| : (cur = s.parent) {
            if (std.mem.eql(u8, s.name, name)) return true;
        }
        return false;
    }
};

/// Identifiers that always denote a compile-time value.
fn isLiteralIdent(name: []const u8) bool {
    return std.mem.eql(u8, name, "true") or std.mem.eql(u8, name, "false") or std.mem.eql(u8, name, "null");
}

/// Validates that every `comptime` / `comptime { }` expression in `program`
/// contains only compile-time-evaluable nodes: literals, arithmetic and
/// comparisons, and — inside a block — locals declared by the block itself.
/// Returns the first offending expression, or null if valid.
pub fn validateComptime(program: ast.Program) ?ComptimeError {
    for (program.decls) |decl| {
        if (validateDecl(decl)) |err| return err;
    }
    return null;
}

fn validateDecl(decl: ast.DeclKind) ?ComptimeError {
    switch (decl) {
        .val => |v| return validateIfComptime(v.value.*),
        else => return null,
    }
}

fn validateIfComptime(expr: ast.Expr) ?ComptimeError {
    switch (expr) {
        .comptime_ => |a| switch (a.kind) {
            .comptimeExpr => |e| return validateComptimeExpr(e.*, null),
            .comptimeBlock => |cb| return validateBody(cb.body, null),
            else => return null,
        },
        else => return null,
    }
}

/// Walk a block's statements, threading the names it declares. A `val`/`var`
/// validates its initialiser in the scope that precedes it and then validates
/// the rest of the block with the new name in scope (the recursion is what
/// carries the scope without an allocator).
fn validateBody(body: []const ast.Stmt, scope: ?*const CtScope) ?ComptimeError {
    for (body, 0..) |stmt, i| {
        if (stmt.expr == .binding) {
            const bind = stmt.expr.binding;
            switch (bind.kind) {
                .localBind => |lb| {
                    if (validateComptimeExpr(lb.value.*, scope)) |err| return err;
                    const declared = CtScope{ .name = lb.name, .parent = scope };
                    return validateBody(body[i + 1 ..], &declared);
                },
                .assign => |as| switch (as.target) {
                    .name => |name| {
                        if (!CtScope.has(scope, name)) return ComptimeError{ .ident = name, .loc = bind.loc };
                        if (validateComptimeExpr(as.value.*, scope)) |err| return err;
                        continue;
                    },
                    else => return ComptimeError{ .ident = @tagName(bind.kind), .loc = bind.loc },
                },
                else => return ComptimeError{ .ident = @tagName(bind.kind), .loc = bind.loc },
            }
        }
        if (validateComptimeExpr(stmt.expr, scope)) |err| return err;
    }
    return null;
}

/// The value of a constant numeric expression (literals and arithmetic over
/// them), or null when the expression is not a constant number.
fn constNumber(expr: ast.Expr) ?f64 {
    switch (expr) {
        .literal => |l| switch (l.kind) {
            .numberLit => |n| return std.fmt.parseFloat(f64, n) catch null,
            else => return null,
        },
        .unaryOp => |u| {
            if (u.op != .neg) return null;
            const v = constNumber(u.expr.*) orelse return null;
            return -v;
        },
        .binaryOp => |b| {
            const l = constNumber(b.lhs.*) orelse return null;
            const r = constNumber(b.rhs.*) orelse return null;
            return switch (b.op) {
                .add => l + r,
                .sub => l - r,
                .mul => l * r,
                else => null,
            };
        },
        else => return null,
    }
}

/// A string literal, or a concatenation of them.
fn isConstString(expr: ast.Expr) bool {
    return switch (expr) {
        .literal => |l| l.kind == .stringLit,
        .binaryOp => |b| b.op == .add and isConstString(b.lhs.*) and isConstString(b.rhs.*),
        else => false,
    };
}

fn validateComptimeExpr(expr: ast.Expr, scope: ?*const CtScope) ?ComptimeError {
    switch (expr) {
        .literal => |l| switch (l.kind) {
            .numberLit, .stringLit, .null_ => return null,
            else => return ComptimeError{ .ident = @tagName(l.kind), .loc = l.loc },
        },
        .binaryOp => |b| switch (b.op) {
            .add, .sub, .mul, .div, .mod, .lt, .gt, .lte, .gte, .eq, .ne, .@"and", .@"or" => {
                if (validateComptimeExpr(b.lhs.*, scope)) |err| return err;
                if (validateComptimeExpr(b.rhs.*, scope)) |err| return err;
                // C4b: a constant zero divisor is an error, not a `null` fold.
                if (b.op == .div or b.op == .mod) {
                    if (constNumber(b.rhs.*)) |d| if (d == 0) {
                        const rloc = b.rhs.*.getLoc();
                        return ComptimeError{ .ident = "0", .loc = rloc, .reason = .divisionByZero };
                    };
                }
                return null;
            },
        },
        .unaryOp => |u| {
            if (validateComptimeExpr(u.expr.*, scope)) |err| return err;
            // C4b: negating a string (or anything statically non-numeric).
            if (u.op == .neg and isConstString(u.expr.*)) {
                return ComptimeError{ .ident = "-", .loc = u.loc, .reason = .negatedNonNumber };
            }
            return null;
        },
        .call => |c| switch (c.kind) {
            .pipeline => |p| {
                if (validateComptimeExpr(p.lhs.*, scope)) |err| return err;
                return validateComptimeExpr(p.rhs.*, scope);
            },
            else => return ComptimeError{ .ident = @tagName(c.kind), .loc = c.loc },
        },
        .collection => |co| switch (co.kind) {
            .arrayLit => |al| {
                for (al.elems) |elem| {
                    if (validateComptimeExpr(elem, scope)) |err| return err;
                }
                return null;
            },
            else => return ComptimeError{ .ident = @tagName(co.kind), .loc = co.loc },
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |e| if (e.value) |ep| return validateComptimeExpr(ep.*, scope) else return null,
            else => return ComptimeError{ .ident = @tagName(j.kind), .loc = j.loc },
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                if (validateComptimeExpr(i.cond.*, scope)) |err| return err;
                if (validateBody(i.then_, scope)) |err| return err;
                if (i.else_) |body| return validateBody(body, scope);
                return null;
            },
            else => return ComptimeError{ .ident = @tagName(br.kind), .loc = br.loc },
        },
        .comptime_ => |a| switch (a.kind) {
            .comptimeExpr => |e| return validateComptimeExpr(e.*, scope),
            .comptimeBlock => |cb| return validateBody(cb.body, scope),
            else => return ComptimeError{ .ident = @tagName(a.kind), .loc = a.loc },
        },
        .identifier => |i| switch (i.kind) {
            .ident => |name| {
                if (isLiteralIdent(name) or CtScope.has(scope, name)) return null;
                return ComptimeError{ .ident = name, .loc = i.loc };
            },
            else => return ComptimeError{ .ident = @tagName(i.kind), .loc = i.loc },
        },
        else => return ComptimeError{ .ident = @tagName(expr), .loc = expr.getLoc() },
    }
}
