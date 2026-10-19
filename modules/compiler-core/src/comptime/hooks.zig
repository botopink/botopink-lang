//! Decision 277 — the hooks a function reaches, as its `@Decl` hands them to a
//! decorator: `decl.hooks: HookNode[]` (`builtins.d.bp`).
//!
//! **One node per function**, holding only what is written in it: each `use
//! h(…)` (`Use` — the hook's declaration with its own annotations, the `use`'s
//! explicit type arguments, and for std's `provide` / `context` the context
//! object, decision 354 (4)) and each edge to a `@Component` (`Call`) — a call
//! of a `@Component` function (the calls a template such as `html` builds
//! from tags included, since the node is recorded while the body is
//! inferred), such a function named as a value (decision 389: under 388 a
//! component value is rendered wherever its lambda lands, so naming it
//! reaches it), and a component value the checker cannot follow (a function
//! value called, a method, what generic code answers) with `callee: null`. The checker records a node
//! as it infers a top-level function's body (`infer.zig` `inferFnDecl`,
//! `Env.hookBuilder`); a module's nodes are published to the session
//! (`Reflection.hookFns`) when its analysis ends, so an importer reads the
//! nodes of the functions it reaches in another module — each computed once
//! per compilation and shared.
//!
//! **The list** `decl.hooks` is the reflected function's node, then every
//! node reachable through its `use`s and calls — breadth-first, each node's
//! `use`s and calls in body order, each function once (`infer.zig`
//! `declHooks`). A cycle is an edge back to a listed node. A `use` over a
//! function value enters with `hook: null` and reaches nothing, as a call
//! edge with `callee: null` does (389: its reader decides on the safe side); a host
//! function (`declare fn`, `#[@External…]`) and std's compiler-lowered
//! `provide` / `context` get no node. The compiler names no stage, marker or
//! library: what the list means is the reading decorator's.
//!
//! **`async`** (decision 375) marks a node asynchronous: a body that writes
//! `await` / `async { … }`, calls a host function answering `@Task` (or
//! `@Component`, which extends it), calls what the checker cannot follow, or
//! reaches an asynchronous node — computed over the module's nodes once its
//! bodies are inferred (`infer.zig` `markHookAsync`), an imported node read
//! as its module published it. commonJS runs a synchronous component's
//! lambda (decision 388) with no `await`, and its body awaits nothing.
//!
//! **`stage`** (decision 376) is when the function can run — `Build`, `Run`
//! or `Any` — from the resources its body reads (`buildResource`, a host
//! call) and the stages of the declarations it calls, `build-and-run` when
//! both meet (`infer.zig` `markStages`).
const std = @import("std");
const ast = @import("../ast.zig");
const Term = @import("../codegen/beam/term.zig").Term;
const T = @import("./types.zig");

/// A declaration a node names: the module that declares it and its declared
/// name — what `Declared<unknown>` carries (`returnTypeName` the declared
/// return type as the source spells it, `""` for a `val`).
pub const DeclRef = struct {
    module: []const u8,
    name: []const u8,
    returnTypeName: []const u8 = "",
};

/// One annotation of a hook's declaration, with the decorator it names
/// resolved in the hook's own module (`DeclAnnotation.decorator`): the
/// identity `envMod.declIdentity(owner, declared name)`, never the spelling.
pub const Annotation = struct {
    name: []const u8,
    args: []const []const u8,
    decorator: []const u8,
};

/// One explicit type argument of a `use` (`use params<BlogParams>()`), as
/// `TypeInfo<unknown>` hands it out: its name, the module that declares it
/// (`""` for a primitive) and a record's fields as the checker spells them.
pub const TypeArg = struct {
    name: []const u8,
    module: []const u8,
    fields: []const Field,

    pub const Field = struct { name: []const u8, typeName: []const u8 };
};

/// One `use` written in the function.
pub const Use = struct {
    /// Null for a `use` over a function value (a parameter, a local).
    hook: ?DeclRef,
    /// The hook's own annotations.
    annotations: []const Annotation,
    at: ast.Loc,
    typeArgs: []const TypeArg,
    /// Decision 354 (4) — the context object a `use provide(C, …)` / `use
    /// context(C)` names (the `val` that declares `C`); null for any other hook.
    context: ?DeclRef = null,
};

/// One edge to a `@Component` written in the function (decision 389): a call
/// of a `@Component` function, or such a function named as a value (`val
/// cards = itens.map(Card);` — under 388 naming it is enough to reach it). A
/// component value the checker cannot follow — a function value called, a
/// method, what generic code answers — has `callee: null`.
pub const Call = struct {
    callee: ?DeclRef,
    at: ast.Loc,
};

/// Decision 376 — when a function can run: `build` when it reads what exists
/// only while the program compiles (a `comptime` `@Decl` / `@Expr<T>` /
/// `type` parameter's reflection), `run` when it reaches what exists only
/// when the program runs (a host function std or its library does not
/// declare `#[compiler.stage(.Any)]`), `any` otherwise. Propagated through calls.
pub const Stage = enum {
    any,
    build,
    run,

    /// The variant of `builtins.d.bp`'s `Stage` a decorator reads.
    pub fn spelled(s: Stage) []const u8 {
        return switch (s) {
            .any => "Any",
            .build => "Build",
            .run => "Run",
        };
    }
};

/// What sets a stage, where it is written: a resource (`` `decl` ``, the host
/// function `` `clock.nowMillis` ``) or a call of a function of that stage.
pub const Mark = struct {
    at: ast.Loc,
    /// The resource or call as a refusal names it.
    what: []const u8,
    /// For a call, the resource that gives the callee its stage, where it
    /// is written — what the caller's stage is then named by.
    root: ?[]const u8 = null,
};

/// Decision 376 — a call of a declaration written in a body: its stage is
/// the callee's, read once every node of the module is recorded.
pub const StageCall = struct {
    ref: DeclRef,
    at: ast.Loc,
    /// The call as written (`` `campos(…)` ``).
    what: []const u8,
};

/// What one function's body writes for its stage (decision 376), kept by
/// the function's name until the module's stages are computed.
pub const StageFacts = struct {
    /// The first resource of each stage written in the body (outside a
    /// `comptime`), in body order.
    build: ?Mark = null,
    run: ?Mark = null,
    calls: []const StageCall = &.{},
    /// Decision 380 — the first thing the body writes that keeps a call of it
    /// from being computed at build although it is `any`: a written raise
    /// (`@panic`, `@todo`, `throw`, 380 (3)), the program's output
    /// (`@print`), a module `var`, a call the checker does not follow (a
    /// function value, a method of a declared type). Null when none.
    blocker: ?Mark = null,
    /// The function's body runs at build: a decorator's or a template's.
    buildBody: ?[]const u8 = null,
};

/// What one function's body writes.
pub const Node = struct {
    function: DeclRef,
    uses: []const Use,
    calls: []const Call,
    /// Decision 375 — the node is asynchronous: its body writes `await` or
    /// `async { … }`, calls a host function answering `@Task` or
    /// `@Component`, calls what the checker cannot follow (a function value
    /// or a method answering `@Component<R>`, a `use` with `hook: null`), or
    /// reaches an asynchronous node through a `use` or a call (`infer.zig`
    /// `markHookAsync`, a cycle asynchronous when any node in it is).
    is_async: bool = false,
    /// Decision 376 — the function's stage (`markStages`), and what gives it
    /// (`""` for `any`), for a refusal in another module.
    stage: Stage = .any,
    why: []const u8 = "",
    /// Decision 380 — a call of the function with arguments known at build
    /// is computed at build: it is `any`, and neither it nor what it calls
    /// writes a `StageFacts.blocker`.
    foldable: bool = false,
};

/// A top-level function of a module, as the session knows it.
pub const FnInfo = struct {
    ref: DeclRef,
    /// A host function, or a hook the compiler lowers where it is written:
    /// no node.
    host: bool,
    /// The function's own annotations, decorators resolved in its module.
    annotations: []const Annotation,
    /// Null for a host function.
    node: ?Node,
    /// Decision 376 — the function's stage: a host's by its `#[compiler.stage(.Any)]`
    /// (else `run`), any other's its node's.
    stage: Stage = .any,
    why: []const u8 = "",
};

/// The node being recorded while a top-level function's body is inferred.
/// A call's type is read when the body is done: a call whose type was still
/// a variable when it was met may resolve to `@Component<R>` by then.
pub const Builder = struct {
    uses: std.ArrayListUnmanaged(Use) = .empty,
    calls: std.ArrayListUnmanaged(PendingCall) = .empty,
    /// Decision 375 — what the body writes that makes the node asynchronous
    /// by itself (`Node.async` before its edges are followed).
    is_async: bool = false,
    /// Decision 375 — the calls of a function value or a method, by type and
    /// place: one that resolves to `@Component<R>` (or stays open) cannot be
    /// followed — an edge with `callee: null` (389) and an asynchronous node.
    dynamicCalls: std.ArrayListUnmanaged(DynamicCall) = .empty,
    /// Decision 376 — the body's stage resources and calls (`StageFacts`).
    build: ?Mark = null,
    run: ?Mark = null,
    stageCalls: std.ArrayListUnmanaged(StageCall) = .empty,
    blocker: ?Mark = null,

    pub const DynamicCall = struct { type_: *T.Type, at: ast.Loc };

    pub const PendingCall = struct { call: Call, type_: *T.Type };
};

/// `"<module>:<line>:<column>"` — where a `use` or a call is written; the
/// entry module is `main`.
pub fn atText(arena: std.mem.Allocator, module: []const u8, loc: ast.Loc) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}:{d}:{d}", .{ if (module.len == 0) "main" else module, loc.line, loc.col });
}

/// The order of two positions in one body.
pub fn before(a: ast.Loc, b: ast.Loc) bool {
    return a.line < b.line or (a.line == b.line and a.col < b.col);
}

// ── the term a decorator body reads ──────────────────────────────────────────

/// What a `Declared` of a reached declaration carries beside its identity:
/// the meta its decorators set so far, each key spelled `<decorator>.<key>`
/// (the path `@typeInfo(X).meta.<decorator>.<key>` reads).
pub const MetaPair = struct { key: []const u8, value: []const u8 };

pub const MetaSource = struct {
    ctx: *const anyopaque,
    metaOf: *const fn (ctx: *const anyopaque, arena: std.mem.Allocator, module: []const u8, name: []const u8) anyerror![]const MetaPair,
};

/// `decl.hooks` as the BEAM term the decorator body reads: a list of
/// `HookNode` maps (records lower to maps keyed by field atoms; a null is
/// `undefined`).
pub fn nodesToTerm(arena: std.mem.Allocator, nodes: []const Node, meta: MetaSource) ![]const Term {
    const out = try arena.alloc(Term, nodes.len);
    for (nodes, 0..) |n, i| {
        const uses = try arena.alloc(Term, n.uses.len);
        for (n.uses, 0..) |u, j| uses[j] = try useTerm(arena, n.function.module, u, meta);
        const calls = try arena.alloc(Term, n.calls.len);
        for (n.calls, 0..) |c, j| calls[j] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
            Term.field("callee", if (c.callee) |callee| try declaredTerm(arena, callee, meta) else Term.undefined_atom),
            Term.field("at", Term.str(try atText(arena, n.function.module, c.at))),
        }));
        out[i] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
            Term.field("function", try declaredTerm(arena, n.function, meta)),
            Term.field("uses", Term.listOf(uses)),
            Term.field("calls", Term.listOf(calls)),
            Term.field("async", .{ .boolean = n.is_async }),
            Term.field("stage", Term.atomOf(n.stage.spelled())),
        }));
    }
    return out;
}

fn useTerm(arena: std.mem.Allocator, module: []const u8, u: Use, meta: MetaSource) !Term {
    const anns = try annotationsTerm(arena, u.annotations);
    const args = try arena.alloc(Term, u.typeArgs.len);
    for (u.typeArgs, 0..) |ta, i| {
        const fields = try arena.alloc(Term, ta.fields.len);
        for (ta.fields, 0..) |f, j| fields[j] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
            Term.field("name", Term.str(f.name)),
            Term.field("typeName", Term.str(f.typeName)),
            Term.field("annotations", Term.listOf(&.{})),
        }));
        args[i] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
            Term.field("name", Term.str(ta.name)),
            Term.field("module", Term.str(ta.module)),
            Term.field("fields", Term.listOf(fields)),
            Term.field("methods", Term.listOf(&.{})),
            Term.field("meta", try metaTerm(arena, if (ta.module.len > 0) try meta.metaOf(meta.ctx, arena, ta.module, ta.name) else &.{})),
        }));
    }
    return Term.mapOf(try arena.dupe(Term.MapEntry, &.{
        Term.field("hook", if (u.hook) |h| try declaredTerm(arena, h, meta) else Term.undefined_atom),
        Term.field("annotations", anns),
        Term.field("at", Term.str(try atText(arena, module, u.at))),
        Term.field("typeArgs", Term.listOf(args)),
        Term.field("context", if (u.context) |c| try declaredTerm(arena, c, meta) else Term.undefined_atom),
    }));
}

/// `DeclAnnotation` maps: `name`, `args` (the raw lexemes) and `decorator`
/// (the decorator's identity).
pub fn annotationsTerm(arena: std.mem.Allocator, anns: []const Annotation) !Term {
    const items = try arena.alloc(Term, anns.len);
    for (anns, 0..) |a, i| {
        const args = try arena.alloc(Term, a.args.len);
        for (a.args, 0..) |arg, j| args[j] = Term.str(arg);
        items[i] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
            Term.field("name", Term.str(a.name)),
            Term.field("args", Term.listOf(args)),
            Term.field("decorator", Term.str(a.decorator)),
        }));
    }
    return Term.listOf(items);
}

/// `Declared<unknown>`: the declaration's name, module, meta and return type.
/// Its `value` is `null` in a decorator body — the program's functions do not
/// run while it compiles (decision 364 (3)).
pub fn declaredTerm(arena: std.mem.Allocator, d: DeclRef, meta: MetaSource) !Term {
    return Term.mapOf(try arena.dupe(Term.MapEntry, &.{
        Term.field("name", Term.str(d.name)),
        Term.field("module", Term.str(if (d.module.len == 0) "main" else d.module)),
        Term.field("meta", try metaTerm(arena, try meta.metaOf(meta.ctx, arena, d.module, d.name))),
        Term.field("returnTypeName", Term.str(d.returnTypeName)),
        Term.field("value", Term.undefined_atom),
    }));
}

fn metaTerm(arena: std.mem.Allocator, pairs: []const MetaPair) !Term {
    const items = try arena.alloc(Term, pairs.len);
    for (pairs, 0..) |p, i| items[i] = Term.mapOf(try arena.dupe(Term.MapEntry, &.{
        Term.field("key", Term.str(p.key)),
        Term.field("value", Term.str(p.value)),
    }));
    return Term.listOf(items);
}

test "hooks: atText names the entry module main" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();
    try std.testing.expectEqualStrings("main:3:5", try atText(a, "", .{ .line = 3, .col = 5 }));
    try std.testing.expectEqualStrings("app/page:1:2", try atText(a, "app/page", .{ .line = 1, .col = 2 }));
    try std.testing.expect(before(.{ .line = 1, .col = 9 }, .{ .line = 2, .col = 1 }));
    try std.testing.expect(!before(.{ .line = 2, .col = 1 }, .{ .line = 2, .col = 1 }));
}

// ── whether a decorator reads the list ───────────────────────────────────────

/// True when one of `fns` reads a member named `member` (`decl.hooks`,
/// `val { hooks } = decl`): a function's node list is computed only for a
/// decorator that reads it — the list is the same whenever it is read.
pub fn readsMember(fns: []const ast.FnDecl, member: []const u8) bool {
    for (fns) |f| for (f.body) |*s| if (walk(ast.Stmt, s, member)) return true;
    return false;
}

fn walk(comptime X: type, ptr: *const X, member: []const u8) bool {
    if (X == ast.Expr) {
        if (ptr.* == .identifier and ptr.identifier.kind == .identAccess and std.mem.eql(u8, ptr.identifier.kind.identAccess.member, member)) return true;
    }
    if (X == ast.FieldDestruct) return std.mem.eql(u8, ptr.field_name, member);
    if (X == ast.ImportDecl) return false;
    switch (@typeInfo(X)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            if (comptime mayHoldExpr(f.type)) if (walk(f.type, &@field(ptr.*, f.name), member)) return true;
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                    if (walk(@TypeOf(payload.*), payload, member)) return true;
                },
            }
        },
        .optional => |o| if (ptr.*) |*inner| return walk(o.child, inner, member),
        .pointer => |p| switch (p.size) {
            .one => if (comptime mayHoldExpr(p.child)) return walk(p.child, ptr.*, member),
            .slice => if (comptime mayHoldExpr(p.child)) {
                for (ptr.*) |*e| if (walk(p.child, e, member)) return true;
            },
            else => {},
        },
        .array => |arr| if (comptime mayHoldExpr(arr.child)) {
            for (ptr) |*e| if (walk(arr.child, e, member)) return true;
        },
        else => {},
    }
    return false;
}

// ── decision 376 — the resources that run only at build ─────────────────────

/// The first build-only resource `f`'s body writes outside a `comptime`
/// (decision 376 (1)): a read of a `comptime` parameter — `@Decl` (`decl.*`),
/// `@Expr<T>` / `@ExprCustom<T>` (`x.value`, `x.fail`, a template's
/// `q.source()`). A `@typeInfo` of a type the body names is
/// answered at build as a constant (380 (1)) and is no resource.
///
/// Decision 562 amends 376 (1): a function whose every parameter is
/// `comptime` (`isExpandedFn`) is expanded at its call site, and reading
/// one's `.value` gives it no stage.
pub fn buildResource(arena: std.mem.Allocator, f: ast.FnDecl) !?Mark {
    if (try isExpandedFn(arena, f)) return null;
    var reflected: std.ArrayListUnmanaged([]const u8) = .empty;
    for (f.params) |p| {
        if (p.modifier != .@"comptime") continue;
        const tr = p.typeRef;
        if (p.exprWrapped or tr.isDeclType() or tr.isTemplateReturnType()) try reflected.append(arena, p.name);
    }
    if (reflected.items.len == 0) return null;
    var w: BuildWalk = .{ .arena = arena, .reflected = reflected.items };
    for (f.body) |*st| {
        w.walk(ast.Stmt, st);
        if (w.found) |m| return m;
    }
    return null;
}

/// Decision 562 — a function whose every parameter is `comptime x: @Expr<T>`
/// and whose body reads one's `.value`: it is expanded at its call site
/// (`expand_call.zig`) and has no run-time body. A decorator (`@Decl`), a
/// template (`-> @Expr<…>`), a component, a host declaration and a function
/// taking a type (`@Expr<type>`, 297's twins) are not.
pub fn isExpandedFn(arena: std.mem.Allocator, f: ast.FnDecl) !bool {
    if (f.params.len == 0 or f.body.len == 0 or f.isDeclare) return false;
    if (f.returnType) |rt| {
        if (rt.isTemplateReturnType()) return false;
        if (rt == .generic and rt.generic.is_builtin and std.mem.eql(u8, rt.generic.name, "Component")) return false;
    }
    if (f.isExternal()) return false;
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    for (f.params) |p| {
        if (p.modifier != .@"comptime" or !p.exprWrapped) return false;
        if (p.typeArgOf != null or mentionsType(p.typeRef)) return false;
        try names.append(arena, p.name);
    }
    var w: BuildWalk = .{ .arena = arena, .reflected = names.items, .value_only = true };
    for (f.body) |*st| {
        w.walk(ast.Stmt, st);
        if (w.found != null) return true;
    }
    return false;
}

/// Whether `tr` names `type` (`@Expr<type>`, `@Expr<V | type<T>>`).
fn mentionsType(tr: ast.TypeRef) bool {
    return switch (tr) {
        .named => |n| std.mem.eql(u8, n, "type"),
        .array => |e| mentionsType(e.*),
        .optional => |e| mentionsType(e.*),
        .generic => |g| for (g.args) |a| {
            if (mentionsType(a)) break true;
        } else false,
        .typeparam => true,
        else => false,
    };
}

const BuildWalk = struct {
    arena: std.mem.Allocator,
    reflected: []const []const u8,
    found: ?Mark = null,
    /// Decision 562 — only a `.value` read counts.
    value_only: bool = false,

    fn walk(self: *BuildWalk, comptime X: type, ptr: *const X) void {
        if (self.found != null) return;
        if (X == ast.Expr) {
            switch (ptr.*) {
                // A `comptime` is computed at build into a constant: what it
                // reads gives the function no stage.
                .comptime_ => |c| switch (c.kind) {
                    .comptimeExpr, .comptimeBlock => return,
                    else => {},
                },
                .identifier => |id| if (self.value_only) {
                    if (id.kind == .identAccess and std.mem.eql(u8, id.kind.identAccess.member, "value")) {
                        const r = id.kind.identAccess.receiver.*;
                        if (r == .identifier and r.identifier.kind == .ident) for (self.reflected) |n| if (std.mem.eql(u8, n, r.identifier.kind.ident)) {
                            self.found = .{ .at = id.loc, .what = n };
                            return;
                        };
                    }
                } else if (id.kind == .ident) for (self.reflected) |n| if (std.mem.eql(u8, n, id.kind.ident)) {
                    self.found = .{ .at = id.loc, .what = std.fmt.allocPrint(self.arena, "`{s}`, a `comptime` parameter read", .{n}) catch n };
                    return;
                },
                else => {},
            }
        }
        if (X == ast.ImportDecl or X == ast.TypeRef or X == ast.Pattern) return;
        switch (@typeInfo(X)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

// ── decision 380 — what keeps a call from being computed at build ──────────

/// The first raise (`@panic`, `@todo`, `@trap`, `throw`), output (`@print`,
/// `@println`, `@debug`) or read or write of one of `vars` (the module's
/// `var`s) in `body`, outside a `comptime`.
pub fn foldBlocker(body: []const ast.Stmt, vars: []const []const u8) ?Mark {
    var w: BlockWalk = .{ .vars = vars };
    for (body) |*st| {
        w.walk(ast.Stmt, st);
        if (w.found) |m| return m;
    }
    return null;
}

const BlockWalk = struct {
    vars: []const []const u8,
    found: ?Mark = null,

    fn isVar(self: *BlockWalk, n: []const u8) bool {
        for (self.vars) |v| if (std.mem.eql(u8, v, n)) return true;
        return false;
    }

    fn walk(self: *BlockWalk, comptime X: type, ptr: *const X) void {
        if (self.found != null) return;
        if (X == ast.Expr) {
            switch (ptr.*) {
                .comptime_ => |c| switch (c.kind) {
                    .comptimeExpr, .comptimeBlock => return,
                    else => {},
                },
                .identifier => |id| if (id.kind == .ident and self.isVar(id.kind.ident)) {
                    self.found = .{ .at = id.loc, .what = "a module `var`" };
                    return;
                },
                .binding => |b| if (b.kind == .assign and b.kind.assign.target == .name and self.isVar(b.kind.assign.target.name)) {
                    self.found = .{ .at = b.loc, .what = "a module `var`" };
                    return;
                },
                .jump => |j| if (j.kind == .throw_) {
                    self.found = .{ .at = j.loc, .what = "`throw`" };
                    return;
                },
                .call => |c| if (c.kind == .call and c.kind.call.is_builtin) {
                    const raises = [_][]const u8{ "panic", "todo", "trap", "print", "println", "debug" };
                    for (raises) |r| if (std.mem.eql(u8, c.kind.call.callee, r)) {
                        self.found = .{ .at = c.loc, .what = r };
                        return;
                    };
                },
                else => {},
            }
        }
        if (X == ast.ImportDecl or X == ast.TypeRef or X == ast.Pattern) return;
        switch (@typeInfo(X)) {
            .@"struct" => |s| inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (comptime mayHoldExpr(f.type)) self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        self.walk(@TypeOf(payload.*), payload);
                    },
                }
            },
            .optional => |o| if (ptr.*) |*inner| self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| self.walk(arr.child, e);
            },
            else => {},
        }
    }
};

// ── what a `.hooks` reader may write ─────────────────────────────────────────

/// Decision 372 — a call that gives the program code: `@emit(…)`, or
/// `addMember(…)` / `addType(…)` / `wrapWith(…)` (316) on a receiver
/// (`decl.addMember(…)`). A
/// decorator that reads `.hooks` runs after the module's bodies and may only
/// record meta or refuse, so such a call in it is refused where it is written.
pub const OutputCall = struct { name: []const u8, at: ast.Loc };

/// The first output call written in `f`'s body, in source order of the walk.
pub fn outputCall(f: ast.FnDecl) ?OutputCall {
    for (f.body) |*s| if (findOutput(ast.Stmt, s)) |c| return c;
    return null;
}

fn findOutput(comptime X: type, ptr: *const X) ?OutputCall {
    if (X == ast.Expr) {
        if (ptr.* == .call and ptr.call.kind == .call) {
            const c = ptr.call.kind.call;
            if (c.is_builtin and std.mem.eql(u8, c.callee, "emit")) return .{ .name = "@emit", .at = ptr.call.loc };
            if (!c.is_builtin and c.receiver != null and
                (std.mem.eql(u8, c.callee, "addMember") or std.mem.eql(u8, c.callee, "addType") or std.mem.eql(u8, c.callee, "wrapWith")))
                return .{ .name = c.callee, .at = ptr.call.loc };
        }
    }
    if (X == ast.ImportDecl) return null;
    switch (@typeInfo(X)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            if (comptime mayHoldExpr(f.type)) if (findOutput(f.type, &@field(ptr.*, f.name))) |c| return c;
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                    if (findOutput(@TypeOf(payload.*), payload)) |c| return c;
                },
            }
        },
        .optional => |o| if (ptr.*) |*inner| return findOutput(o.child, inner),
        .pointer => |p| switch (p.size) {
            .one => if (comptime mayHoldExpr(p.child)) return findOutput(p.child, ptr.*),
            .slice => if (comptime mayHoldExpr(p.child)) {
                for (ptr.*) |*e| if (findOutput(p.child, e)) |c| return c;
            },
            else => {},
        },
        .array => |arr| if (comptime mayHoldExpr(arr.child)) {
            for (ptr) |*e| if (findOutput(arr.child, e)) |c| return c;
        },
        else => {},
    }
    return null;
}

/// Where a decorator body writes `.<callee>(…)` on a receiver
/// (`decl.addMember(…)`), in the walk's source order. A run's k-th output of a
/// kind is taken to come from the k-th such call: exact for a body that calls
/// straight through, the nearest call otherwise.
pub fn callSites(arena: std.mem.Allocator, f: ast.FnDecl, callee: []const u8) ![]const ast.Loc {
    var out: std.ArrayListUnmanaged(ast.Loc) = .empty;
    for (f.body) |*s| try collectCalls(arena, ast.Stmt, s, callee, &out);
    return out.toOwnedSlice(arena);
}

fn collectCalls(arena: std.mem.Allocator, comptime X: type, ptr: *const X, callee: []const u8, out: *std.ArrayListUnmanaged(ast.Loc)) std.mem.Allocator.Error!void {
    if (X == ast.Expr) {
        if (ptr.* == .call and ptr.call.kind == .call) {
            const c = ptr.call.kind.call;
            if (!c.is_builtin and c.receiver != null and std.mem.eql(u8, c.callee, callee)) try out.append(arena, ptr.call.loc);
        }
    }
    if (X == ast.ImportDecl) return;
    switch (@typeInfo(X)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            if (comptime mayHoldExpr(f.type)) try collectCalls(arena, f.type, &@field(ptr.*, f.name), callee, out);
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                    try collectCalls(arena, @TypeOf(payload.*), payload, callee, out);
                },
            }
        },
        .optional => |o| if (ptr.*) |*inner| try collectCalls(arena, o.child, inner, callee, out),
        .pointer => |p| switch (p.size) {
            .one => if (comptime mayHoldExpr(p.child)) try collectCalls(arena, p.child, ptr.*, callee, out),
            .slice => if (comptime mayHoldExpr(p.child)) {
                for (ptr.*) |*e| try collectCalls(arena, p.child, e, callee, out);
            },
            else => {},
        },
        .array => |arr| if (comptime mayHoldExpr(arr.child)) {
            for (ptr) |*e| try collectCalls(arena, arr.child, e, callee, out);
        },
        else => {},
    }
}

fn mayHoldExpr(comptime X: type) bool {
    return switch (@typeInfo(X)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}
