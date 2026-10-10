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
fn declaredTerm(arena: std.mem.Allocator, d: DeclRef, meta: MetaSource) !Term {
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

// ── what a `.hooks` reader may write ─────────────────────────────────────────

/// Decision 372 — a call that gives the program code: `@emit(…)`, or
/// `addMember(…)` / `addType(…)` on a receiver (`decl.addMember(…)`). A
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
                (std.mem.eql(u8, c.callee, "addMember") or std.mem.eql(u8, c.callee, "addType")))
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

fn mayHoldExpr(comptime X: type) bool {
    return switch (@typeInfo(X)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExpr(p.child) else true,
        else => true,
    };
}
