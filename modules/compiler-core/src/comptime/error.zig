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

    /// Render the error to an allocated string; the location box names
    /// `file`. Caller owns the result.
    pub fn renderAlloc(this: ComptimeError, allocator: std.mem.Allocator, src: []const u8, file: []const u8) ![]u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        try this.renderTo(&aw.writer, src, file);
        return aw.toOwnedSlice();
    }

    fn renderTo(this: ComptimeError, writer: anytype, src: []const u8, file: []const u8) !void {
        const line_text = render.extractLine(src, this.loc.line);
        const line_w = render.digitWidth(this.loc.line);
        const gutter = line_w + 1;

        try writer.writeAll("error comptime: expression cannot be evaluated at compile time\n");
        try render.padSpaces(writer, gutter - 1);
        try writer.print("┌─ {s}:{d}:{d}\n", .{ file, this.loc.line, this.loc.col });
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

/// Where a `@Result` value came from — what the E3.9 hint of a `typeMismatch`
/// needs to say which fix applies (decisions 120–122, 124, 125). Recorded by
/// inference on a fresh copy of the `@Result` type node (`Env.resultOrigins`),
/// so the value keeps its origin through the type variables it flows into.
pub const ResultOrigin = struct {
    source: Source = .unknown,
    /// The `throw` / `try` that made an INFERRED value a `@Result`: an
    /// `async { }` block's, or an `iter` / `stream` loop's item.
    made_at: ?Loc = null,
    made_by: MadeBy = .try_,

    pub const Source = enum {
        unknown,
        /// `await t` on a `@Async<@Result<U, E>>` — answers the `@Result`.
        await_,
        /// a `for` / `for await` item over a sequence of `@Result`s.
        for_item,
    };
    pub const MadeBy = enum { try_, throw_ };
};

/// The kind of type error that occurred.
pub const TypeErrorKind = union(enum) {
    /// Two types could not be unified.
    typeMismatch: struct {
        expected: *T.Type,
        got: *T.Type,
        /// Where the `@Result` on the `got` side came from (E3.9), filled by
        /// `unify.zig` from `Env.resultOrigins`; the default when unknown.
        origin: ResultOrigin = .{},
        /// Decision 426 (4) — the reasons a template call's `q.note` gave,
        /// when the mismatch is at that call.
        notes: []const []const u8 = &.{},
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
    /// `use` appeared in a function whose return type is not `@Component<R>`.
    /// Payload is the rendered return type (e.g. `"string"`, `"void"`).
    useNotAllowed: []const u8,
    /// The expression used with `use` is not a hook.
    /// Payload is the rendered expression type.
    useNotContext: []const u8,
    /// `use` in a body whose fn does not carry `#[@use]` (decisions 88, 104).
    /// Payload: the fn's name and its rendered return type.
    useWithoutComponent: struct {
        fnName: []const u8,
        returnType: []const u8,
    },
    /// Front 19 step 3 — `val #(a, b) = use …` whose hook yields a tuple of
    /// another arity (`tupleLen` set), or no tuple at all (`tupleLen` null).
    /// Located at the binding; there is no flag (decision 67).
    useTupleArity: struct {
        patternLen: usize,
        tupleLen: ?usize,
        sourceType: *T.Type,
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
/// Decision 532 — one call of the chain a raise at build crossed: the file it
/// is written in, and where it starts there.
pub const Frame = struct { file: []const u8, loc: Loc };

pub const TypeError = struct {
    kind: TypeErrorKind,
    /// Source location of the triggering expression, if known.
    loc: ?Loc = null,
    /// Decision 532 — a raise at build whose innermost call is written in
    /// another file than the module's own (a library's helper, a decorator's
    /// body): that call, which the report is located at. `loc` stays the first
    /// call in the module's own file, where a tool that shows one file puts it.
    origin: ?Frame = null,
    /// Decision 532 — the calls the raise crossed after the innermost one (the
    /// `origin` or the one at `loc`), innermost first, down to the program's
    /// call, annotation or `comptime`: the report's `called from` lines.
    frames: []const Frame = &.{},

    pub fn withLoc(this: TypeError, loc: Loc) TypeError {
        var t = this;
        t.loc = loc;
        return t;
    }

    /// A raise at build located by `frames`, innermost first (decision 532):
    /// `own` is the module's file. The innermost call that is written in `own`
    /// is `loc`; when the innermost of all is not, it is `origin` and the
    /// report is located there. Needs at least one frame in `own` or none.
    pub fn withRaise(this: TypeError, own: []const u8, all: []const Frame) TypeError {
        var t = this;
        if (all.len == 0) return t;
        for (all) |f| {
            if (f.file.len == 0 or std.mem.eql(u8, f.file, own)) {
                t.loc = f.loc;
                break;
            }
        }
        const first = all[0];
        if (first.file.len == 0 or std.mem.eql(u8, first.file, own)) {
            t.origin = null;
        } else {
            t.origin = first;
        }
        t.frames = all[1..];
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

    pub fn useWithoutComponent(fnName: []const u8, returnType: []const u8) TypeError {
        return .{ .kind = .{ .useWithoutComponent = .{ .fnName = fnName, .returnType = returnType } } };
    }

    pub fn useTupleArity(patternLen: usize, tupleLen: ?usize, sourceType: *T.Type) TypeError {
        return .{ .kind = .{ .useTupleArity = .{ .patternLen = patternLen, .tupleLen = tupleLen, .sourceType = sourceType } } };
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

    /// Decision 788 — a refusal of a top-level `comptime { … }` names the
    /// block, never the decorator it is read onto: each `__bp_comptime_<k>`
    /// of a custom message or hint is `comptime`, and the decorator's words
    /// are the block's. `inBlock` says the refusal came from a block's run
    /// (its words are rewritten though no name appears); otherwise only a
    /// text naming a block is rewritten.
    pub fn blockNamed(this: TypeError, arena: std.mem.Allocator, inBlock: bool) std.mem.Allocator.Error!TypeError {
        if (this.kind != .custom) return this;
        const c = this.kind.custom;
        const names = std.mem.indexOf(u8, c.message, ast.comptime_block_prefix) != null or
            (c.hint != null and std.mem.indexOf(u8, c.hint.?, ast.comptime_block_prefix) != null);
        if (!inBlock and !names) return this;
        var t = this;
        t.kind = .{ .custom = .{ .message = try blockWords(arena, c.message), .hint = if (c.hint) |h| try blockWords(arena, h) else null } };
        return t;
    }

    pub fn custom(msg: []const u8, hint: ?[]const u8) TypeError {
        return .{ .kind = .{ .custom = .{ .message = msg, .hint = hint } } };
    }

    /// Decisions 120–122 (front 24 E3.9) — the most common error of the
    /// migration: a `@Result` used where its value is expected. One hint per
    /// source (`ResultOrigin`): after `await t` it suggests `try await t`, on a
    /// `for` item `try r`, and a value inferred as `@Result` (an `async { }`
    /// block, an `iter` / `stream` item) also points at the `try` / `throw`
    /// that made it one. Null when the mismatch is not that one. Caller owns
    /// the returned slice.
    pub fn resultMismatchHint(gpa: std.mem.Allocator, expected: *T.Type, got: *T.Type, origin: ResultOrigin) !?[]u8 {
        const e = expected.deref();
        const g = got.deref();
        const eIsResult = e.* == .named and std.mem.eql(u8, e.named.name, "Result");
        const gIsResult = g.* == .named and std.mem.eql(u8, g.named.name, "Result");
        if (eIsResult == gIsResult) return null;
        if (e.* == .typeVar or g.* == .typeVar) return null;
        if (!gIsResult) return try gpa.dupe(u8, generic_result_hint);
        const fix: []const u8 = switch (origin.source) {
            .await_ => "`await` answers the `Result` the Async holds: write `try await t` to propagate its error, or handle it with `case` / `catch`",
            .for_item => "a `for` over a sequence of `Result`s hands over each item as the `Result` (no implicit `try`): write `try r` to propagate its error, or handle it with `case` / `catch`",
            .unknown => if (origin.made_at == null)
                return try gpa.dupe(u8, generic_result_hint)
            else
                "a `Result` stands where its value is expected: propagate it with `try`, or handle it with `case` / `catch`",
        };
        const at = origin.made_at orelse return try gpa.dupe(u8, fix);
        return try std.fmt.allocPrint(gpa, "{s}; it is a `Result` because of the `{s}` at {d}:{d} in its own block", .{
            fix,
            switch (origin.made_by) {
                .try_ => "try",
                .throw_ => "throw",
            },
            at.line,
            at.col,
        });
    }

    /// The hint when nothing says where the `@Result` came from.
    const generic_result_hint = "a `Result` stands where its value is expected: propagate it with `try` (`try await t` for a Async, `try r` for a `for` item) or handle it with `case` / `catch`; a value inferred as `Result` became one from a `throw` / `try` in its own block";

    /// Render a concise, human-readable message for this error. Caller owns the
    /// returned slice. Used by `botopink check` and the language server.
    pub fn message(this: TypeError, gpa: std.mem.Allocator) ![]u8 {
        const raw = try this.rawMessage(gpa);
        return assocTypesShown(gpa, try namedByOwner(gpa, raw));
    }

    fn rawMessage(this: TypeError, gpa: std.mem.Allocator) ![]u8 {
        return switch (this.kind) {
            .typeMismatch => |m| blk: {
                // A union's short label has to spell its members: "expected
                // union" names nothing the author wrote, and a union is the one
                // kind whose identity *is* its members (decision 8 §3).
                const expected = try typeLabelAlloc(gpa, m.expected);
                defer gpa.free(expected);
                const got = try typeLabelAlloc(gpa, m.got);
                defer gpa.free(got);
                if (try resultMismatchHint(gpa, m.expected, m.got, m.origin)) |hint| {
                    defer gpa.free(hint);
                    break :blk std.fmt.allocPrint(gpa, "type mismatch: expected {s}, got {s} — {s}", .{ expected, got, hint });
                }
                if (m.notes.len > 0) {
                    var out: std.ArrayListUnmanaged(u8) = .empty;
                    errdefer out.deinit(gpa);
                    try out.print(gpa, "type mismatch: expected {s}, got {s}", .{ expected, got });
                    for (m.notes) |n| try out.print(gpa, " — note: {s}", .{n});
                    break :blk out.toOwnedSlice(gpa);
                }
                break :blk std.fmt.allocPrint(gpa, "type mismatch: expected {s}, got {s}", .{ expected, got });
            },
            .unboundVariable => |n| std.fmt.allocPrint(gpa, "unbound variable '{s}'", .{n}),
            .arityMismatch => |a| std.fmt.allocPrint(gpa, "'{s}' expects {d} argument(s), got {d}", .{ a.name, a.expected, a.got }),
            .unknownField => |u| std.fmt.allocPrint(gpa, "unknown field '{s}' on type '{s}'", .{ u.field, internalShown(u.typeName) }),
            .notARecord => |n| std.fmt.allocPrint(gpa, "type '{s}' is not a record or struct", .{n}),
            .recursiveType => std.fmt.allocPrint(gpa, "recursive type detected", .{}),
            .unknownTypeName => |n| std.fmt.allocPrint(gpa, "unknown type '{s}'", .{n}),
            .missingField => |m| std.fmt.allocPrint(gpa, "missing required field '{s}' on type '{s}'", .{ m.field, m.typeName }),
            .useNotAllowed => |r| std.fmt.allocPrint(gpa, "use-of-non-context-fn: `use` not allowed: function returns '{s}', which is not a `Component<R>`", .{r}),
            .useNotContext => |e| std.fmt.allocPrint(gpa, "use-of-non-context-fn: `use` takes a hook: '{s}' is not a hook `Component<R>`", .{e}),
            .useWithoutComponent => |u| std.fmt.allocPrint(gpa, "use-without-component: `use` needs a body marked `component` — the enclosing fn '{s}' carries no `component` marker (it returns '{s}'): write `component fn`", .{ u.fnName, u.returnType }),
            .useTupleArity => |u| blk: {
                const source = try typeLabelAlloc(gpa, u.sourceType);
                defer gpa.free(source);
                break :blk if (u.tupleLen) |n|
                    try std.fmt.allocPrint(gpa, "use-tuple-arity: `val #(…)` binds {d} name(s) but the hook yields a tuple of {d}", .{ u.patternLen, n })
                else
                    try std.fmt.allocPrint(gpa, "use-tuple-arity: `val #(…)` binds {d} name(s) but the hook yields '{s}', which is not a tuple", .{ u.patternLen, source });
            },
            .throwWithoutResult => std.fmt.allocPrint(gpa, "effect-try-without-fallible-channel: `throw` needs a `Result` in some layer of the return; `try … catch` handles the failure on the spot, and a host binding answers a `Result` with `result: true`", .{}),
            .methodNotActive => |m| std.fmt.allocPrint(gpa, "'{s}' has no active method '{s}' — activate the extension with `{s}*`", .{ m.typeName, m.method, m.hintSym }),
            .ambiguousExtension => |a| std.fmt.allocPrint(gpa, "'{s}.{s}' is provided by both '{s}' and '{s}' — qualify the call, e.g. `{s}.{s}(obj)`", .{ a.typeName, a.method, a.symA, a.symB, a.symA, a.method }),
            .notAnExtension => |name| std.fmt.allocPrint(gpa, "'{s}' does not name an implement/extend symbol", .{name}),
            .extendRequiresInterface => |t| std.fmt.allocPrint(gpa, "`extend {s}` adds methods without a contract — use `implement <Behavior> for {s}` so the methods satisfy a behavior", .{ t, t }),
            .redundantActivation => |name| std.fmt.allocPrint(gpa, "`{s}*` is redundant: an extension declared in this module is auto-applied; `*` is only for imports", .{name}),
            .missingMethod => |m| std.fmt.allocPrint(gpa, "'{s}' does not implement '{s}' required by behavior '{s}'", .{ m.typeName, m.method, m.interfaceName }),
            .unknownMethod => |m| std.fmt.allocPrint(gpa, "'{s}' is not declared in any behavior implemented for '{s}'", .{ m.method, internalShown(m.typeName) }),
            .unknownInterface => |u| std.fmt.allocPrint(gpa, "'{s}' is not a behavior implemented here (method '{s}')", .{ u.qualifier, u.method }),
            .ambiguousMethod => |a| std.fmt.allocPrint(gpa, "'{s}' is declared by both '{s}' and '{s}' — qualify it", .{ a.method, a.interfaceA, a.interfaceB }),
            .typeparamConstraint => |c| std.fmt.allocPrint(gpa, "'{s}' has type '{s}', which does not satisfy its type constraint", .{ c.paramName, typeLabel(c.got) }),
            .tryOnNonResult => |ty| std.fmt.allocPrint(gpa, "`try` requires a Result<D, E> value, found '{s}'", .{typeLabel(ty)}),
            .nonExhaustive => |n| nonExhaustiveMessage(gpa, n),
            .redundantPattern => |r| std.fmt.allocPrint(gpa, "unreachable `case` arm ({s}): {s} is already covered by an earlier arm", .{ r.typeName, r.description }),
            .custom => |c| std.fmt.allocPrint(gpa, "{s}", .{c.message}),
        };
    }
};

/// Decision 207 — an inline parameter type is named by its owner in every
/// diagnostic: `'BpInline__link__props'` reads ``the props of `link` ``
/// (the quotes around the name, when any, are dropped). Takes ownership of
/// `raw`.
pub fn namedByOwner(gpa: std.mem.Allocator, raw: []u8) ![]u8 {
    if (std.mem.indexOf(u8, raw, ast.inline_type_prefix) == null) return raw;
    defer gpa.free(raw);
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(gpa);
    var i: usize = 0;
    while (i < raw.len) {
        if (std.mem.startsWith(u8, raw[i..], ast.inline_type_prefix)) {
            var j = i;
            while (j < raw.len and (std.ascii.isAlphanumeric(raw[j]) or raw[j] == '_')) j += 1;
            if (ast.ownerOfInlineType(raw[i..j])) |o| {
                const quoted = out.items.len > 0 and (out.items[out.items.len - 1] == '\'' or out.items[out.items.len - 1] == '`') and
                    j < raw.len and raw[j] == out.items[out.items.len - 1];
                if (quoted) _ = out.pop();
                const named = try std.fmt.allocPrint(gpa, "the {s} of `{s}`", .{ o.param, o.owner });
                defer gpa.free(named);
                try out.appendSlice(gpa, named);
                i = if (quoted) j + 1 else j;
                continue;
            }
        }
        try out.append(gpa, raw[i]);
        i += 1;
    }
    return out.toOwnedSlice(gpa);
}

/// An internal type (`__Decl`, `__Expr` — decision 576 (1)) as a diagnostic
/// names it: without its `__`.
fn internalShown(name: []const u8) []const u8 {
    if (std.mem.startsWith(u8, name, "__") and name.len > 2 and std.mem.indexOf(u8, name[2..], "__") == null) return name[2..];
    return name;
}

/// Decision 216 (3), 330 (7) — an associated type is named in every
/// diagnostic as its owner's path, `City.Columns`, never as the top-level
/// type it is hoisted into (`City__Columns`, `env.assocTypeName`): every word
/// of capitalised segments joined by `__` is shown joined by `.`. Takes
/// ownership of `raw`.
pub fn assocTypesShown(gpa: std.mem.Allocator, raw: []u8) ![]u8 {
    if (std.mem.indexOf(u8, raw, "__") == null) return raw;
    var i: usize = 0;
    while (i < raw.len) {
        if (!isWordChar(raw[i]) or (i > 0 and isWordChar(raw[i - 1]))) {
            i += 1;
            continue;
        }
        var j = i;
        while (j < raw.len and isWordChar(raw[j])) j += 1;
        if (isAssocTypeWord(raw[i..j])) {
            // `A__B` → `A.B`: one byte shorter per joint, rewritten in place.
            var w: usize = i;
            var r: usize = i;
            while (r < j) {
                if (r + 1 < j and raw[r] == '_' and raw[r + 1] == '_') {
                    raw[w] = '.';
                    w += 1;
                    r += 2;
                    continue;
                }
                raw[w] = raw[r];
                w += 1;
                r += 1;
            }
            const shrink = j - w;
            if (shrink > 0) {
                std.mem.copyForwards(u8, raw[w..], raw[j..]);
                const out = try gpa.realloc(raw, raw.len - shrink);
                return assocTypesShown(gpa, out);
            }
        }
        i = j;
    }
    return raw;
}

fn isWordChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
}

/// `Owner__Name` (any depth): two or more segments, each starting with an
/// uppercase letter, joined by `__`, none holding `_` of its own.
fn isAssocTypeWord(w: []const u8) bool {
    var parts = std.mem.splitSequence(u8, w, "__");
    var n: usize = 0;
    while (parts.next()) |p| {
        if (p.len == 0 or !std.ascii.isUpper(p[0])) return false;
        for (p) |c| if (!std.ascii.isAlphanumeric(c)) return false;
        n += 1;
    }
    return n >= 2;
}

test "an associated type is shown under its owner's path" {
    const gpa = std.testing.allocator;
    const out = try assocTypesShown(gpa, try gpa.dupe(u8, "unknown field 'nope' on type 'City__Columns' (A__B__C, __bp_x, BpInline__x)"));
    defer gpa.free(out);
    try std.testing.expectEqualStrings("unknown field 'nope' on type 'City.Columns' (A.B.C, __bp_x, BpInline__x)", out);
}

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
pub fn typeLabelAlloc(gpa: std.mem.Allocator, ty: *T.Type) ![]const u8 {
    return typeLabelImpl(gpa, ty, false);
}

/// `typeLabelAlloc`, with a generic named type written with its arguments
/// (`Component<Styled>`, not `Component`): for a refusal that names two types
/// told apart by their arguments alone.
pub fn typeLabelFullAlloc(gpa: std.mem.Allocator, ty: *T.Type) ![]const u8 {
    return typeLabelImpl(gpa, ty, true);
}

fn typeLabelImpl(gpa: std.mem.Allocator, ty: *T.Type, full: bool) ![]const u8 {
    const t = ty.deref();
    if (t.* == .named) {
        const n = t.named;
        // The spellings a source writes, not the checker's internal names:
        // `?T` (decision 2 — "optional" is no spelling), `T[]`, and a
        // section's path (`Token.Text`, not `__Token__Text`).
        if (std.mem.eql(u8, n.name, "optional") and n.args.len == 1) {
            const inner = try typeLabelImpl(gpa, n.args[0], full);
            defer gpa.free(inner);
            return std.fmt.allocPrint(gpa, "?{s}", .{inner});
        }
        if (std.mem.eql(u8, n.name, "array") and n.args.len == 1 and n.args[0].deref().* == .named) {
            const inner = try typeLabelImpl(gpa, n.args[0], full);
            defer gpa.free(inner);
            return std.fmt.allocPrint(gpa, "{s}[]", .{inner});
        }
        if (std.mem.startsWith(u8, n.name, "__") and n.name.len > 2) {
            return std.mem.replaceOwned(u8, gpa, n.name[2..], "__", ".");
        }
        if (full and n.args.len > 0) {
            var buf: std.ArrayList(u8) = .empty;
            errdefer buf.deinit(gpa);
            try buf.appendSlice(gpa, n.name);
            try buf.append(gpa, '<');
            for (n.args, 0..) |arg, i| {
                if (i > 0) try buf.appendSlice(gpa, ", ");
                const label = try typeLabelImpl(gpa, arg, full);
                defer gpa.free(label);
                try buf.appendSlice(gpa, label);
            }
            try buf.append(gpa, '>');
            return buf.toOwnedSlice(gpa);
        }
    }
    if (t.* != .union_) return gpa.dupe(u8, typeLabel(t));
    var buf: std.ArrayList(u8) = .empty;
    errdefer buf.deinit(gpa);
    for (t.union_, 0..) |member, i| {
        if (i > 0) try buf.appendSlice(gpa, " | ");
        const label = try typeLabelImpl(gpa, member, full);
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

/// Decisions 266, 331 — what a module-level `comptime` may not read: a
/// module-level `val` (its value exists when the program runs, not while it is
/// compiled — `'greeting' is a runtime identifier`), unless the block declares
/// the name itself. A call, a loop, a lambda or a record is admitted: the
/// comptime runtime runs it (`block_eval.zig`), and what it cannot run is
/// reported there, located. Two folds that evaluate to an error stay refused
/// here (C4b): a constant zero divisor and a negated string. Returns the first
/// offending node, or null.
pub fn validateComptime(program: ast.Program) ?ComptimeError {
    for (program.decls) |decl| switch (decl) {
        .val => |v| if (v.value.* == .comptime_) {
            var check = ReadCheck{ .program = program, .root = v.value };
            check.walk(ast.Expr, v.value);
            if (check.found) |err| return err;
        },
        else => {},
    };
    return null;
}

/// The walk of `validateComptime` over one `comptime` node; no allocation —
/// a name's declaration inside the node is searched for (`declares`).
const ReadCheck = struct {
    program: ast.Program,
    root: *const ast.Expr,
    found: ?ComptimeError = null,

    fn walk(self: *ReadCheck, comptime U: type, ptr: *const U) void {
        if (self.found != null) return;
        if (U == ast.Expr) {
            self.visit(ptr.*);
            if (self.found != null) return;
        }
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }

    fn visit(self: *ReadCheck, e: ast.Expr) void {
        switch (e) {
            .identifier => |i| switch (i.kind) {
                .ident => |name| {
                    if (isLiteralIdent(name) or !isModuleValue(self.program, name)) return;
                    if (declares(self.root.*, name)) return;
                    self.found = .{ .ident = name, .loc = i.loc };
                },
                else => {},
            },
            .binaryOp => |b| if (b.op == .div or b.op == .mod) {
                if (constNumber(b.rhs.*)) |d| if (d == 0) {
                    self.found = .{ .ident = "0", .loc = b.rhs.*.getLoc(), .reason = .divisionByZero };
                };
            },
            .unaryOp => |u| if (u.op == .neg and isConstString(u.expr.*)) {
                self.found = .{ .ident = "-", .loc = u.loc, .reason = .negatedNonNumber };
            },
            else => {},
        }
    }
};

fn mayHoldExpr(comptime U: type) bool {
    return switch (@typeInfo(U)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque", .null, .undefined => false,
        .pointer => |p| if (p.child == u8) false else if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else true,
        else => true,
    };
}

/// A module-level `val` named `name`.
fn isModuleValue(program: ast.Program, name: []const u8) bool {
    for (program.decls) |d| switch (d) {
        .val => |v| if (std.mem.eql(u8, v.name, name)) return true,
        else => {},
    };
    return false;
}

/// Whether `root` declares `name` anywhere — a local, a loop's or a lambda's
/// parameter, an `if` binding.
fn declares(root: ast.Expr, name: []const u8) bool {
    var d = Declares{ .name = name };
    d.walk(ast.Expr, &root);
    return d.hit;
}

const Declares = struct {
    name: []const u8,
    hit: bool = false,

    fn walk(self: *Declares, comptime U: type, ptr: *const U) void {
        if (self.hit) return;
        if (U == ast.Expr) self.visit(ptr.*);
        if (U == ast.TypeRef or U == ast.Pattern) return;
        switch (@typeInfo(U)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) self.walk(@TypeOf(payload.*), payload),
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            else => {},
        }
    }

    fn visit(self: *Declares, e: ast.Expr) void {
        const eq = struct {
            fn any(names: []const []const u8, n: []const u8) bool {
                for (names) |x| if (std.mem.eql(u8, x, n)) return true;
                return false;
            }
        };
        switch (e) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| if (std.mem.eql(u8, lb.name, self.name)) {
                    self.hit = true;
                },
                else => {},
            },
            .loop => |lp| if (eq.any(lp.params, self.name)) {
                self.hit = true;
            },
            .function => |f| if (eq.any(f.kind.params, self.name)) {
                self.hit = true;
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| if (i.binding) |n| if (std.mem.eql(u8, n, self.name)) {
                    self.hit = true;
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| for (cc.trailing) |tl| if (eq.any(tl.params, self.name)) {
                    self.hit = true;
                },
                else => {},
            },
            else => {},
        }
    }
};

/// Decision 266 — whether a `comptime` node (`comptime <expr>` or
/// `comptime { … }`) written anywhere holds only what `eval.zig` folds in Zig:
/// literals, operators, the block's own locals, `if`, `break`. One that does
/// not runs on the comptime runtime instead (`infer.zig` `foldBodyComptime`,
/// decision 331).
pub fn isFoldable(expr: ast.Expr) bool {
    if (expr != .comptime_) return false;
    return validateIfComptime(expr) == null;
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

test "withRaise: located at the innermost call, in its own file; the rest are called-from lines" {
    const all = [_]Frame{
        .{ .file = "src/lib.bp", .loc = .{ .line = 3, .col = 5 } },
        .{ .file = "src/main.bp", .loc = .{ .line = 9, .col = 1 } },
        .{ .file = "src/main.bp", .loc = .{ .line = 12, .col = 7 } },
    };
    // The innermost call is in another file: it is the origin, `loc` the first
    // call of the module's own file, `frames` everything after the innermost.
    const foreign = TypeError.custom("boom", "h").withRaise("src/main.bp", &all);
    try std.testing.expectEqualStrings("src/lib.bp", foreign.origin.?.file);
    try std.testing.expectEqual(@as(usize, 9), foreign.loc.?.line);
    try std.testing.expectEqual(@as(usize, 2), foreign.frames.len);
    // The innermost call is in the module's own file: it is `loc`, no origin.
    const own = TypeError.custom("boom", "h").withRaise("src/main.bp", all[1..]);
    try std.testing.expect(own.origin == null);
    try std.testing.expectEqual(@as(usize, 9), own.loc.?.line);
    try std.testing.expectEqual(@as(usize, 1), own.frames.len);
    // No frame: the error is as it was.
    try std.testing.expect(TypeError.custom("boom", "h").withRaise("src/main.bp", &.{}).loc == null);
}

/// The words of a decorator's run read as a top-level `comptime` block's
/// (`TypeError.blockNamed`).
fn blockWords(arena: std.mem.Allocator, text: []const u8) std.mem.Allocator.Error![]const u8 {
    const phrases = [_][2][]const u8{
        .{ "the decorator's body raised", "the `comptime` block raised" },
        .{ "the decorator body raised", "the `comptime` block raised" },
        .{ "the decorator module did not compile", "the `comptime` block's module did not compile" },
        .{ "the decorator could not be evaluated", "the `comptime` block could not be evaluated" },
        .{ "the decorator evaluator", "the comptime evaluator" },
        .{ "down to the annotation", "down to the block" },
    };
    var out: std.ArrayListUnmanaged(u8) = .empty;
    var i: usize = 0;
    outer: while (i < text.len) {
        for (phrases) |ph| if (std.mem.startsWith(u8, text[i..], ph[0])) {
            try out.appendSlice(arena, ph[1]);
            i += ph[0].len;
            continue :outer;
        };
        // `the decorator `__bp_comptime_<k>`` → `the `comptime` block`.
        const the_decorator = "the decorator `";
        if (std.mem.startsWith(u8, text[i..], the_decorator)) {
            const at = i + the_decorator.len;
            const n = ast.comptimeBlockNameLen(text[at..]);
            if (n > 0 and at + n < text.len and text[at + n] == '`') {
                try out.appendSlice(arena, "the `comptime` block");
                i = at + n + 1;
                continue;
            }
        }
        // `#[__bp_comptime_<k>]` → `comptime`.
        if (std.mem.startsWith(u8, text[i..], "#[")) {
            const n = ast.comptimeBlockNameLen(text[i + 2 ..]);
            if (n > 0 and i + 2 + n < text.len and text[i + 2 + n] == ']') {
                try out.appendSlice(arena, "comptime");
                i += 2 + n + 1;
                continue;
            }
        }
        // A quoted name keeps the code quotes: `'__bp_comptime_0'` → `` `comptime` ``.
        if (text[i] == '\'') {
            const n = ast.comptimeBlockNameLen(text[i + 1 ..]);
            if (n > 0 and i + 1 + n < text.len and text[i + 1 + n] == '\'') {
                try out.appendSlice(arena, "`comptime`");
                i += n + 2;
                continue;
            }
        }
        const n = ast.comptimeBlockNameLen(text[i..]);
        if (n > 0 and (i == 0 or !(std.ascii.isAlphanumeric(text[i - 1]) or text[i - 1] == '_'))) {
            try out.appendSlice(arena, "comptime");
            i += n;
            continue;
        }
        try out.append(arena, text[i]);
        i += 1;
    }
    return out.items;
}

test "a block's decorator is named `comptime` in its refusals" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const te = try TypeError.custom("x: the decorator `__bp_comptime_0` writes `v`; `#[__bp_comptime_12]` on `__bp_comptime_12_at`, '__bp_comptime_3'", "the decorator's body raised; down to the annotation").blockNamed(arena, false);
    try std.testing.expectEqualStrings("x: the `comptime` block writes `v`; `comptime` on `comptime`, `comptime`", te.kind.custom.message);
    try std.testing.expectEqualStrings("the `comptime` block raised; down to the block", te.kind.custom.hint.?);
    const plain = TypeError.custom("the decorator's body raised", null);
    try std.testing.expectEqualStrings("the decorator's body raised", (try plain.blockNamed(arena, false)).kind.custom.message);
}
