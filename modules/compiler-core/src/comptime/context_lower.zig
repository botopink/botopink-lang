//! Decisions 809 (8), 812, 819 — a `Component<R>` at run time is a function
//! over a `Scope` and a `Place`, lowered on the transformed AST for every
//! backend at once.
//!
//! A function whose resolved return is `Component<R>` (a hook's and a
//! component's alike) answers the function; calling it runs nothing:
//!
//!   fn Card(item: Item) -> Component<View> { body }
//!     →  fn Card(item: Item) -> fn(unknown, unknown) -> unknown {
//!            return { bpScope__, bpKey__ -> val bpCell__N = bpScopeEnter__(bpScope__, bpKey__); body' };
//!        }
//!
//! The body opens its own cell, the child at `key` of the scope it was handed
//! (819 (1)), and `body'` reads and writes it:
//!
//!   use provide(c);      →  bpScopeProvide__(bpCell__N, "<T's identity>", c);
//!   use context(ctx)     →  bpScopeFind__(bpRecv__N, "<ctx's type's identity>", ctx)
//!
//! where a `Context<T>` is its value at run time (`createContext(v)` is `v`)
//! and `bpRecv__N = bpScopeReceived__(bpCell__N)`, bound at the body's entry,
//! is what the cell held then — a body reads the contexts it received, never
//! its own provides (354 (2), 809 (8)).
//!
//!   use h(…) / use c     →  await (h(…))(bpCell__N, bpScopeNowhere__())   — a child cell of the body's (812 (1), 818 (1))
//!   return v             →  return bpScopeAnswer__(v)
//!
//! and a body that ends without a `return` answers `answer(null)`. A `use
//! provide` writes the cell where it is written, so what the body resolves
//! after it reads it and what it resolved before does not (812 (3)).
//!
//! Decisions 820, 821 — each written call answering a component stamps its
//! place on the value, numbered in written order within the nearest
//! `component` body, the lambdas written in it counted with it:
//!
//!   Item(p)              →  bpStamp__(Item(p), bpCell__N, <n>)            — in a component body
//!   Item(p)              →  bpStampPlain__(Item(p), bpCount__N, <n>)      — in a plain function
//!   #[key(k)] Item(p)    →  bpStampKeyed__(Item(p), <n>, k)               — 818 (3)
//!   itens.map(Card)      →  itens.map({ a -> bpStamp__(Card(a), bpCell__N, <n>) })
//!
//! A plain function that stamps opens `val bpCount__N = bpCountNew__();
//! defer bpCountEnd__(bpCount__N);`, its counter reset at each entry; a value
//! made outside every function carries no stamp (820 (3)). Decisions 816,
//! 818 (1) — `use memo(make)` is a call of the body like the others, its
//! slot its own child cell's: `bpMemoIn__(bpCell__N, <n>, make)`.
//! A `{ component x -> body }` lambda (decision 574, `Env.componentLambdas`)
//! is lowered the same way, its tail made its `return`:
//! `{ x -> return { bpScope__, bpKey__ -> body' }; }` — its parameters and
//! what it captures closed over by the inner lambda.
//! A component call makes its function wherever it is written, a component
//! body included (decision 791 (1)): it is resolved by a `use` of it in a body,
//! by a render library's `resolve`, or by a root's `run` (std's `context`,
//! 809 (6), 822). Nothing is captured: a lambda written in a body is outside it.
//!
//! On commonJS the `await` is left out where the target's node is
//! synchronous (`Env.syncCalls`, decision 375), so a synchronous component's
//! function awaits nothing and stays a plain arrow. A host function answering
//! `Component<R>` (`Env.hostCalls`) answers the host's own value: a `use` of
//! it runs nothing.
//!
//! The `bpScope…__` functions are std's `context.enter` / `received` /
//! `provideIn` / `find` / `answer` / `nowhere` / `root`, imported under those
//! names when the module needs them (the import is added here). A context's
//! identity is its value's type (379), recorded by the checker in
//! `Env.contextUses`: a read's fallback is the context value it names (723),
//! an `inject` field's the `val` that declares its type's default (another
//! module's through a hidden import, `Env.contextDefaultImports`).
//!
//! The comptime runtimes evaluate the parsed program (`erlang.zig`
//! `emitComptimeModule`) and do not run this pass (`language-gaps.md`).
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const T = @import("types.zig");
const infer = @import("infer.zig");

const Env = envMod.Env;

/// The parameters of a component's function: the scope it is handed and its
/// place (819 (1)).
pub const scope_param = "bpScope__";
pub const key_param = "bpKey__";
/// The local names std's lowering functions are imported under.
pub const enter_fn = "bpScopeEnter__";
pub const received_fn = "bpScopeReceived__";
pub const provide_fn = "bpScopeProvide__";
pub const find_fn = "bpScopeFind__";
pub const answer_fn = "bpScopeAnswer__";
pub const nowhere_fn = "bpScopeNowhere__";
pub const root_fn = "bpScopeRoot__";
/// Decision 771's slot functions, gone with 816 (a slot belongs to a cell):
/// no lowering writes them; the names stay for the wasm backend's list.
pub const memo_new_fn = "bpMemoNew__";
pub const memo_read_fn = "bpMemoRead__";
/// std's `context.memoIn` (816, 818 (1)): `use memo` over its own child cell.
pub const memo_in_fn = "bpMemoIn__";
/// std's `context.allIn` (827, 884): `use all(cs)` over its own child cell.
pub const all_in_fn = "bpAllIn__";
/// std's `context.stamp` / `stampPlain` / `stampKeyed` (820, 821, 818 (3))
/// and the plain function's counter, `countNew` / `countEnd`.
pub const stamp_fn = "bpStamp__";
pub const stamp_plain_fn = "bpStampPlain__";
pub const stamp_keyed_fn = "bpStampKeyed__";
pub const count_new_fn = "bpCountNew__";
pub const count_end_fn = "bpCountEnd__";
/// The column a stamp's call is written at past the call it wraps: its loc
/// keys none of the checker's plans of the wrapped call (`ast.optional_synthetic_col`'s reason).
const stamp_col: usize = 3_000_000;
/// The type argument a run's call carries (`(c)(cell, place)`): its one
/// argument is the `R` the run answers (decision 504, `wat/scope_carry.zig`).
pub const run_mark = "bpRun__";

/// The cell a body opens (`bpCell__<n>`) and the contexts it received
/// (`bpRecv__<n>`).
const cell_prefix = "bpCell__";
const recv_prefix = "bpRecv__";
/// A plain function's counter (`bpCount__<n>`).
const count_prefix = "bpCount__";
/// The inner closure's answer, in a body that keeps a bare `try`.
const result_local = "bpScopeResult__";

/// The lowering's functions, as `wat.zig` refuses them.
pub const lowered_fns = [_][]const u8{ enter_fn, received_fn, provide_fn, find_fn, answer_fn, nowhere_fn, root_fn, memo_new_fn, memo_read_fn, memo_in_fn, all_in_fn, stamp_fn, stamp_plain_fn, stamp_keyed_fn, count_new_fn, count_end_fn };

const Frame = struct {
    /// The cell this body opened.
    cell: []const u8,
    /// The contexts the cell held at the body's entry.
    recv: []const u8,
    /// Whether the body reads `recv` (a `use context`, an `inject`).
    reads: bool = false,
    /// Whether the body names its cell (a `use`, a `use provide`, a returned
    /// component).
    uses_cell: bool = false,
    /// Each `return v` answers `answer(v)`; false when the body runs as an
    /// inner closure (a bare `try` in it, `lowerComponentBody`).
    wraps_returns: bool = true,
    /// The `R` of the `Component<R>` the body answers, as written — what
    /// each `answer(v)` carries (`carry`).
    renders: ?ast.TypeRef = null,
    /// Whether the body's node is synchronous (375): a returned component
    /// held in a name is then run without an `await`.
    sync: bool = false,
};

/// Decisions 820, 821 — the body whose calls a stamp numbers: the nearest
/// `component` body (its cell) or plain function (its counter); a lambda
/// counts with the body it is written in.
const StampScope = struct {
    kind: enum { body, plain },
    /// The cell's name (`bpCell__N`) or the counter's (`bpCount__N`).
    name: []const u8,
    /// The body's frame, which names its cell once a stamp reads it.
    frame: usize = 0,
    /// The calls numbered so far.
    calls: usize = 0,
};

const Lowering = struct {
    arena: std.mem.Allocator,
    env: *Env,
    /// One entry per body being walked: a component body's frame, or null
    /// for a body that is none (a lambda, a plain function, a test).
    frames: std.ArrayListUnmanaged(?Frame) = .empty,
    body_count: usize = 0,
    uses_std: bool = false,
    /// One entry per component body or plain function being walked.
    stamps: std.ArrayListUnmanaged(StampScope) = .empty,
    count_count: usize = 0,
    /// The lowering functions the module calls: only these are imported, so
    /// a target reaches no other of std's lowering code.
    used: std.StringHashMapUnmanaged(void) = .empty,

    /// The next call's number in the nearest stamping body, and the
    /// expression that body counts its items by (the cell or the counter);
    /// null outside every function.
    fn nextStamp(self: *Lowering, loc: ast.Loc) !?struct { n: usize, kind: @TypeOf(@as(StampScope, undefined).kind), by: *ast.Expr } {
        if (self.stamps.items.len == 0) return null;
        const top = &self.stamps.items[self.stamps.items.len - 1];
        top.calls += 1;
        if (top.kind == .body) if (self.frames.items[top.frame]) |*f| {
            f.uses_cell = true;
        };
        return .{ .n = top.calls, .kind = top.kind, .by = try self.ident(top.name, loc) };
    }

    fn int(self: *Lowering, n: usize, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .literal = .{ .loc = loc, .kind = .{ .numberLit = try std.fmt.allocPrint(self.arena, "{d}", .{n}) } } };
        return e;
    }

    /// The loc a stamp's call is written at.
    fn stampLoc(loc: ast.Loc) ast.Loc {
        var l = loc;
        l.col += stamp_col;
        return l;
    }

    /// Whether the checker typed the call at `loc` as a component.
    fn makesComponent(self: *Lowering, e: *const ast.Expr) bool {
        if (e.* != .call or e.call.kind != .call) return false;
        const cc = e.call.kind.call;
        if (cc.is_builtin) return false;
        const ty = self.env.componentCalls.get(e.call.loc) orelse return false;
        if (componentOf(ty) == null) return false;
        if (self.env.hostCalls.contains(e.call.loc)) return false;
        return true;
    }

    /// The fields of `ptr` walked, `ptr` itself not intercepted.
    fn walkChildren(self: *Lowering, comptime N: type, ptr: *N) anyerror!void {
        if (comptime !mayHoldExpr(N)) return;
        switch (@typeInfo(N)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                try self.walk(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| try self.walk(@TypeOf(payload.*), payload),
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |pi| switch (pi.size) {
                .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") {
                    try self.walk(pi.child, @constCast(ptr.*));
                },
                .slice => for (ptr.*) |*e| try self.walk(pi.child, @constCast(e)),
                else => {},
            },
            else => {},
        }
    }

    fn current(self: *const Lowering) ?Frame {
        if (self.frames.items.len == 0) return null;
        return self.frames.items[self.frames.items.len - 1];
    }

    fn ident(self: *Lowering, name: []const u8, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
        return e;
    }

    fn string(self: *Lowering, text: []const u8, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = text } } };
        return e;
    }

    fn nullLit(self: *Lowering, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .literal = .{ .loc = loc, .kind = .null_ } };
        return e;
    }

    fn callArgs(self: *Lowering, args: []const *ast.Expr) ![]ast.CallArg {
        const out = try self.arena.alloc(ast.CallArg, args.len);
        for (args, 0..) |a, i| out[i] = .{ .label = null, .value = a };
        return out;
    }

    /// A call of one of std's lowering functions.
    fn call(self: *Lowering, callee: []const u8, args: []const *ast.Expr, loc: ast.Loc) !*ast.Expr {
        self.uses_std = true;
        try self.used.put(self.arena, callee, {});
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = callee,
            .is_builtin = false,
            .args = try self.callArgs(args),
            .trailing = &.{},
        } } } };
        return e;
    }

    /// `call` carrying the checker's type of the value that crosses the
    /// call's `unknown` slot (`carry`).
    fn callCarrying(self: *Lowering, callee: []const u8, args: []const *ast.Expr, carried: ?ast.TypeRef, loc: ast.Loc) !*ast.Expr {
        const e = try self.call(callee, args, loc);
        try self.carry(e, carried);
        return e;
    }

    /// Decision 504 — the type a value has where it crosses one of std's
    /// `unknown` slots (`provideIn`'s and `answer`'s value, `find`'s answer,
    /// the `R` a run answers), written as the call's one type argument. The
    /// checker never reads these calls (they are made after inference) and
    /// erlang, beam and commonJS ignore a call's type arguments; wasm, which
    /// boxes and unboxes only by a static type, moves the value's own word
    /// through the slot by it. Nothing is written when the type is not
    /// resolved: wasm then refuses the call.
    fn carry(self: *Lowering, e: *ast.Expr, carried: ?ast.TypeRef) !void {
        const t = carried orelse return;
        const args = try self.arena.alloc(ast.TypeRef, 1);
        args[0] = t;
        e.call.kind.call.typeArgs = args;
    }

    /// The written form of a checker type, for `carry`; null for a type
    /// variable, a union or a structural record — what nothing names.
    fn typeRefOfType(self: *Lowering, ty: *T.Type) anyerror!?ast.TypeRef {
        return infer.typeRefOfType(self.arena, self.env, ty);
    }

    /// `(<callee>)(args)` — the call of a value.
    fn callValue(self: *Lowering, callee: *ast.Expr, args: []const *ast.Expr, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = "",
            .is_builtin = false,
            .args = try self.callArgs(args),
            .trailing = &.{},
            .calleeExpr = callee,
        } } } };
        return e;
    }

    /// The cell a `use` resolves under: the body's own; outside every body
    /// a fresh root.
    fn cellArg(self: *Lowering, loc: ast.Loc) !*ast.Expr {
        if (self.frames.items.len == 0) return self.call(root_fn, &.{}, loc);
        const top = &self.frames.items[self.frames.items.len - 1];
        if (top.*) |*f| {
            f.uses_cell = true;
            return self.ident(f.cell, loc);
        }
        return self.call(root_fn, &.{}, loc);
    }

    /// The contexts a `use context` reads: what the body's cell held at its
    /// entry; outside every body nothing (each read answers its default).
    fn recvArg(self: *Lowering, loc: ast.Loc) !*ast.Expr {
        if (self.frames.items.len == 0) return self.nullLit(loc);
        const top = &self.frames.items[self.frames.items.len - 1];
        if (top.*) |*f| {
            f.reads = true;
            return self.ident(f.recv, loc);
        }
        return self.nullLit(loc);
    }

    /// `(c)(cell, nowhere())` — run a component value under the body's cell
    /// (812 (1)), awaited where its node is asynchronous, the `R` it answers
    /// carried (`carry`).
    fn run(self: *Lowering, c: *ast.Expr, awaited: bool, r: ?*T.Type, loc: ast.Loc) !ast.Expr {
        var ran = try self.callValue(c, &.{ try self.cellArg(loc), try self.call(nowhere_fn, &.{}, loc) }, loc);
        // The run answers `R`: wasm reads the function's mark there
        // (decision 504, `codegen/wat/scope_carry.zig`).
        if (r) |t| if (try self.typeRefOfType(t)) |rr| {
            const args = try self.arena.alloc(ast.TypeRef, 1);
            args[0] = rr;
            try self.carry(ran, .{ .generic = .{ .name = run_mark, .args = args, .is_builtin = false } });
        };
        if (awaited) {
            const w = try self.arena.create(ast.Expr);
            w.* = .{ .jump = .{ .loc = loc, .kind = .{ .await_ = ran } } };
            ran = w;
        }
        return ran.*;
    }

    /// The `R` the hook call `inner` renders, when the checker typed it
    /// `Component<R>`.
    fn hookRenders(self: *Lowering, inner: *const ast.Expr) ?*T.Type {
        if (inner.* != .call) return null;
        const ty = self.env.componentCalls.get(inner.call.loc) orelse return null;
        return componentOf(ty);
    }

    /// The `R` a component value of `ty` renders, when `ty` resolved to
    /// `Component<R>`.
    fn componentOf(ty: *T.Type) ?*T.Type {
        const d = ty.deref();
        if (d.* != .named or !std.mem.eql(u8, d.named.name, "Component") or d.named.args.len < 1) return null;
        return d.named.args[0];
    }

    /// Whether the call at `loc` runs a synchronous node (commonJS awaits it
    /// not, decision 375).
    fn syncAt(self: *Lowering, operand: *const ast.Expr, useLoc: ?ast.Loc) bool {
        if (useLoc) |l| if (self.env.syncCalls.contains(l)) return true;
        if (stampedValue(operand)) |inner| return self.syncAt(inner, null);
        if (operand.* == .call) return self.env.syncCalls.contains(operand.call.loc);
        return false;
    }

    /// The value a stamp's call wraps, or null for any other expression.
    fn stampedValue(e: *const ast.Expr) ?*const ast.Expr {
        if (e.* != .call or e.call.kind != .call) return null;
        const cc = e.call.kind.call;
        if (cc.receiver != null or cc.args.len == 0) return null;
        if (!std.mem.eql(u8, cc.callee, stamp_fn) and !std.mem.eql(u8, cc.callee, stamp_plain_fn) and !std.mem.eql(u8, cc.callee, stamp_keyed_fn)) return null;
        return cc.args[0].value;
    }

    /// `use provide(ctx)` as a whole statement: the body's cell holds the
    /// context's value under its type from here on (379 (2), 812 (3)).
    fn lowerProvideStmt(self: *Lowering, stmt: *ast.Stmt, use: envMod.ContextUse) !void {
        const inner = stmt.expr.useHook.kind.inner;
        const loc = stmt.expr.getLoc();
        const ctx = inner.call.kind.call.args[0].value;
        try self.walk(ast.Expr, ctx);
        if (self.current() == null) return error.ContextLowering;
        const provided = try self.callCarrying(provide_fn, &.{ try self.cellArg(loc), try self.string(use.key, loc), ctx }, try self.typeRefOfType(use.value_type), loc);
        stmt.expr = provided.*;
    }

    /// Decision 416 (1) — `use inject(R)` is `R(f: <read of f's type>, …)`:
    /// each field the nearest context of its type, else that type's declared
    /// default, else the field's own default (copied where it is written).
    fn injectRecord(self: *Lowering, use: envMod.ContextUse, loc: ast.Loc) !*ast.Expr {
        const args = try self.arena.alloc(ast.CallArg, use.fields.len);
        for (use.fields, 0..) |f, i| {
            const value: *ast.Expr = if (f.key) |key| blk: {
                const fallback: *ast.Expr = if (f.default_ref) |ref|
                    try self.ident(ref, loc)
                else
                    try deepCopy(*ast.Expr, self.arena, @constCast(f.field_default orelse return error.ContextLowering));
                const recv = try self.recvArg(loc);
                break :blk try self.callCarrying(find_fn, &.{ recv, try self.string(key, loc), fallback }, try self.typeRefOfType(f.value_type), loc);
            } else try deepCopy(*ast.Expr, self.arena, @constCast(f.field_default orelse return error.ContextLowering));
            args[i] = .{ .label = f.name, .value = value, .comments = &.{} };
        }
        const n = try self.arena.create(ast.Expr);
        n.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{ .receiver = null, .callee = use.value_type.deref().named.name, .is_builtin = false, .args = args, .trailing = &.{} } } } };
        return n;
    }

    fn visitExpr(self: *Lowering, e: *ast.Expr) !bool {
        // Decision 379 — a `Context<T>` is its value at run time: a
        // `createContext(v)` (`Env.createContextCalls`) and a lifted
        // `Context(…)` (a `comptime createContext(…)`'s value) are `v`, so a
        // value of any type crosses the scope as it does (504).
        if (e.* == .call and e.call.kind == .call) {
            const cc = e.call.kind.call;
            const made = self.env.createContextCalls.contains(e.call.loc) or
                (cc.receiver == null and !cc.is_builtin and std.mem.eql(u8, cc.callee, "Context") and self.env.liftedStdTypes.contains("Context"));
            if (made and cc.args.len >= 1) {
                e.* = cc.args[0].value.*;
                try self.walk(ast.Expr, e);
                return true;
            }
        }
        if (e.* == .call and e.call.kind == .call) {
            const cc = e.call.kind.call;
            const loc = e.call.loc;
            // Decision 818 (3) — `#[key(k)] x`: the key in the item's stead
            // of the place the value carries.
            if (cc.is_builtin and std.mem.eql(u8, cc.callee, ast.key_builtin_name) and cc.args.len == 2) {
                const value = cc.args[0].value;
                const key = cc.args[1].value;
                const st = try self.nextStamp(loc);
                try self.walk(ast.Expr, key);
                if (self.makesComponent(value)) try self.walkChildren(ast.Expr, value) else try self.walk(ast.Expr, value);
                e.* = (try self.call(stamp_keyed_fn, &.{ value, try self.int(if (st) |x| x.n else 0, loc), key }, stampLoc(loc))).*;
                return true;
            }
            // Decisions 820 (1), 821 — a written call answering a component
            // answers its value carrying its place, numbered in written
            // order: the call before its arguments.
            if (self.makesComponent(e)) {
                const st = try self.nextStamp(loc);
                const made = try self.arena.create(ast.Expr);
                made.* = e.*;
                try self.walkChildren(ast.Expr, made);
                if (st) |x| {
                    e.* = (try self.call(if (x.kind == .body) stamp_fn else stamp_plain_fn, &.{ made, x.by, try self.int(x.n, loc) }, stampLoc(loc))).*;
                } else e.* = made.*;
                return true;
            }
        }
        // Decision 821 (3) — `itens.map(Card)`: numbered where it is
        // written, each value it makes stamped and counted on that number:
        // `{ a… -> stamp(Card(a…), <cell>, n) }`.
        if (e.* == .identifier and e.identifier.kind == .ident) if (self.env.componentFnValues.get(e.identifier.loc)) |arity| {
            const loc = e.identifier.loc;
            if (try self.nextStamp(loc)) |st| {
                const params = try self.arena.alloc([]const u8, arity);
                const args = try self.arena.alloc(*ast.Expr, arity);
                for (0..arity) |i| {
                    params[i] = try std.fmt.allocPrint(self.arena, "bpArg__{d}", .{i});
                    args[i] = try self.ident(params[i], loc);
                }
                const made = try self.arena.create(ast.Expr);
                made.* = .{ .call = .{ .loc = stampLoc(stampLoc(loc)), .kind = .{ .call = .{
                    .receiver = null,
                    .callee = e.identifier.kind.ident,
                    .is_builtin = false,
                    .args = try self.callArgs(args),
                    .trailing = &.{},
                } } } };
                const stampedCall = try self.call(if (st.kind == .body) stamp_fn else stamp_plain_fn, &.{ made, st.by, try self.int(st.n, loc) }, stampLoc(loc));
                const body = try self.arena.alloc(ast.Stmt, 1);
                body[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = stampedCall } } } };
                e.* = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = body } } };
            }
            return true;
        };
        switch (e.*) {
            .useHook => |uh| {
                // Decisions 755, 771 — `use memo(make)` reads the slot of its
                // position, made with the component's value.
                if (self.env.memoUses.get(uh.loc)) |t| {
                    const inner = uh.kind.inner;
                    if (inner.* != .call or inner.call.kind != .call) return error.ContextLowering;
                    const args = inner.call.kind.call.args;
                    if (args.len != 1) return error.ContextLowering;
                    const make = args[0].value;
                    // Decisions 816, 818 (1) — the hook is a call of the
                    // body, numbered with the rest; its slot its own child
                    // cell's.
                    const st = try self.nextStamp(uh.loc) orelse return error.ContextLowering;
                    if (st.kind != .body) return error.ContextLowering;
                    try self.walk(ast.Expr, make);
                    // A `Context<T>` is its `T` at run time (decision 379): the slot holds that value.
                    const td = t.deref();
                    const carried = if (td.* == .named and std.mem.eql(u8, td.named.name, "Context") and td.named.args.len >= 1) td.named.args[0] else t;
                    e.* = (try self.callCarrying(memo_in_fn, &.{ st.by, try self.int(st.n, uh.loc), make }, try self.typeRefOfType(carried), uh.loc)).*;
                    return true;
                }
                // Decisions 827, 884 — `use all(cs)`: `all`'s cell opened at
                // the call's place, entry `i` run under it at
                // `Place.index(i)`; awaited, its node asynchronous.
                if (self.env.allUses.get(uh.loc)) |t| {
                    const inner = uh.kind.inner;
                    if (inner.* != .call or inner.call.kind != .call) return error.ContextLowering;
                    const args = inner.call.kind.call.args;
                    if (args.len != 1) return error.ContextLowering;
                    const cs = args[0].value;
                    const st = try self.nextStamp(uh.loc) orelse return error.ContextLowering;
                    if (st.kind != .body) return error.ContextLowering;
                    try self.walk(ast.Expr, cs);
                    const ran = try self.callCarrying(all_in_fn, &.{ st.by, try self.int(st.n, uh.loc), cs }, try self.typeRefOfType(t), uh.loc);
                    e.* = .{ .jump = .{ .loc = uh.loc, .kind = .{ .await_ = ran } } };
                    return true;
                }
                if (self.env.contextUses.get(uh.loc)) |use| {
                    if (use.kind == .provide) return error.ContextLowering; // a statement of its own
                    if (use.kind == .inject) {
                        e.* = (try self.injectRecord(use, uh.loc)).*;
                        return true;
                    }
                    const recv = try self.recvArg(uh.loc);
                    // Decisions 378 (3), 723 — no read is unbound: the
                    // default of the value it names when nothing of its
                    // type is provided above.
                    const fallback = try self.ident(use.default_ref orelse return error.ContextLowering, uh.loc);
                    e.* = (try self.callCarrying(find_fn, &.{ recv, try self.string(use.key, uh.loc), fallback }, try self.typeRefOfType(use.value_type), uh.loc)).*;
                    return true;
                }
                const inner = uh.kind.inner;
                if (inner.* == .call and inner.call.kind == .call and self.env.hostCalls.contains(inner.call.loc)) return false;
                const renders = self.hookRenders(inner) orelse
                    (if (self.env.useOperandTypes.get(uh.loc)) |t| componentOf(t) else null);
                try self.walk(ast.Expr, inner);
                // Decisions 812 (1), 818 (1) — every `use` that answers a
                // value, a hook's or a component's, runs under a child cell
                // of the body's.
                e.* = try self.run(inner, !self.syncAt(inner, uh.loc), renders, uh.loc);
                return true;
            },
            .jump => |*j| switch (j.kind) {
                .@"return" => |value| if (self.current()) |f| if (f.wraps_returns) {
                    const returned: ?*T.Type = if (value) |rv| self.env.componentReturns.get(rv.getLoc()) else null;
                    if (value) |v| try self.walk(ast.Expr, v);
                    var v = value orelse try self.nullLit(j.loc);
                    // Decisions 809 (4), 816 (6) — a returned component is
                    // resolved under a child cell of the body's first.
                    if (value) |rv| if (returned) |r| {
                        const awaited = if (rv.* == .call) !self.syncAt(rv, null) else !f.sync;
                        const ran = try self.arena.create(ast.Expr);
                        ran.* = try self.run(rv, awaited, r, j.loc);
                        v = ran;
                    };
                    j.kind = .{ .@"return" = try self.callCarrying(answer_fn, &.{v}, f.renders, j.loc) };
                    return true;
                },
                else => {},
            },
            .function => |*f| {
                // Decision 888 — the lambda takes the arity of the function
                // type it met: the omitted trailing parameters, unnamed.
                if (self.env.lambdaPads.get(f.loc)) |names| f.kind.params = names;
                // Decision 574 — a `{ component -> … }` lambda is a
                // `component fn`: its body becomes the function over the
                // scope, the lambda's parameters and captures closed over by it.
                if (f.kind.marker == .component) if (self.env.componentLambdas.get(f.loc)) |r| {
                    try self.lowerComponentLambda(f, r);
                    return true;
                };
                // A lambda (an `async { … }` block too) is no component body:
                // nothing is captured, and its `return`s are its own.
                try self.frames.append(self.arena, null);
                defer _ = self.frames.pop();
                for (f.kind.body) |*s| try self.walk(ast.Stmt, s);
                return true;
            },
            else => {},
        }
        return false;
    }

    /// Every field of every node, by type (`dsl_hygiene.zig`'s walk), with
    /// statements and expressions intercepted.
    fn walk(self: *Lowering, comptime N: type, ptr: *N) anyerror!void {
        if (N == ast.Stmt) {
            if (ptr.expr == .useHook) if (self.env.contextUses.get(ptr.expr.useHook.loc)) |use| if (use.kind == .provide) {
                return self.lowerProvideStmt(ptr, use);
            };
        }
        if (N == ast.Expr) {
            if (try self.visitExpr(ptr)) return;
        }
        return self.walkChildren(N, ptr);
    }

    /// Walk a body that is no component's (a plain function, a test). One
    /// that stamps a value opens its counter at its entry and ends it on
    /// every exit (821 (2)): `val bpCount__N = countNew(); defer
    /// countEnd(bpCount__N);`.
    fn lowerPlainBody(self: *Lowering, body: []ast.Stmt, loc: ast.Loc) ![]ast.Stmt {
        const name = try std.fmt.allocPrint(self.arena, count_prefix ++ "{d}", .{self.count_count});
        self.count_count += 1;
        try self.frames.append(self.arena, null);
        try self.stamps.append(self.arena, .{ .kind = .plain, .name = name });
        for (body) |*s| try self.walk(ast.Stmt, s);
        const stamped_any = self.stamps.items[self.stamps.items.len - 1].calls > 0;
        _ = self.stamps.pop();
        _ = self.frames.pop();
        if (!stamped_any) return body;
        const out = try self.arena.alloc(ast.Stmt, body.len + 2);
        out[0] = .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = name, .value = try self.call(count_new_fn, &.{}, loc), .mutable = false } } } } };
        out[1] = .{ .expr = (try self.call(count_end_fn, &.{try self.ident(name, loc)}, loc)).*, .deferred = true };
        @memcpy(out[2..], body);
        return out;
    }

    /// A component's body as its function: `[return { bpScope__, bpKey__ ->
    /// val bpCell__N = enter(bpScope__, bpKey__); [val bpRecv__N =
    /// received(bpCell__N);] body' }]`.
    ///
    /// A body that keeps a bare `try` (one the transform did not turn into a
    /// `return`) runs its statements after the last `use provide` as an inner
    /// closure, whose answer — the value, or the error a `try` returns early,
    /// which every backend lowers as the closure's own return — is the
    /// body's result: `val bpScopeResult__ = ({ -> rest })(); return
    /// answer(bpScopeResult__);`. Nothing before the last provide can leave
    /// early (357: no `use` after an early exit).
    fn lowerComponentBody(self: *Lowering, body: []ast.Stmt, renders: ?ast.TypeRef, sync: bool, loc: ast.Loc) ![]ast.Stmt {
        const inner_closure = hasBareTry(body);
        const n = self.body_count;
        self.body_count += 1;
        const cell = try std.fmt.allocPrint(self.arena, cell_prefix ++ "{d}", .{n});
        const recv = try std.fmt.allocPrint(self.arena, recv_prefix ++ "{d}", .{n});
        try self.frames.append(self.arena, Frame{ .cell = cell, .recv = recv, .wraps_returns = !inner_closure, .renders = renders, .sync = sync });
        // Decision 821 (1) — the calls of the body and of the lambdas written
        // in it are numbered here, their items counted in the body's cell.
        try self.stamps.append(self.arena, .{ .kind = .body, .name = cell, .frame = self.frames.items.len - 1 });
        for (body) |*s| try self.walk(ast.Stmt, s);
        _ = self.stamps.pop();
        const reads = self.current().?.reads;
        const uses_cell = reads or self.current().?.uses_cell;
        _ = self.frames.pop();
        const rest: []ast.Stmt = if (inner_closure) blk: {
            var split: usize = 0;
            for (body, 0..) |st, i| if (st.expr == .call and st.expr.call.kind == .call and
                std.mem.eql(u8, st.expr.call.kind.call.callee, provide_fn))
            {
                split = i + 1;
            };
            const rest_lambda = try self.arena.create(ast.Expr);
            rest_lambda.* = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = &.{}, .body = body[split..] } } };
            var result = try self.callValue(rest_lambda, &.{}, loc);
            if (containsAwait(body[split..])) {
                const w = try self.arena.create(ast.Expr);
                w.* = .{ .jump = .{ .loc = loc, .kind = .{ .await_ = result } } };
                result = w;
            }
            const out = try self.arena.alloc(ast.Stmt, split + 2);
            @memcpy(out[0..split], body[0..split]);
            out[split] = .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = result_local, .value = result, .mutable = false, .typeAnnotation = renders } } } } };
            const ret = try self.callCarrying(answer_fn, &.{try self.ident(result_local, loc)}, renders, loc);
            out[split + 1] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = ret } } } };
            break :blk out;
        } else if (body.len > 0 and body[body.len - 1].expr == .jump and body[body.len - 1].expr.jump.kind == .@"return")
            body
        else blk: {
            const grown = try self.arena.alloc(ast.Stmt, body.len + 1);
            @memcpy(grown[0..body.len], body);
            const ret = try self.callCarrying(answer_fn, &.{try self.nullLit(loc)}, renders, loc);
            grown[body.len] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = ret } } } };
            break :blk grown;
        };
        // The body's entry: its own cell, and what that cell held then.
        const head: usize = if (reads) 2 else 1;
        const inner = try self.arena.alloc(ast.Stmt, head + rest.len);
        const opened = try self.call(enter_fn, &.{ try self.ident(scope_param, loc), try self.ident(key_param, loc) }, loc);
        inner[0] = if (uses_cell)
            .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = cell, .value = opened, .mutable = false } } } } }
        else
            .{ .expr = opened.* };
        if (reads) {
            const got = try self.call(received_fn, &.{try self.ident(cell, loc)}, loc);
            inner[1] = .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = recv, .value = got, .mutable = false } } } } };
        }
        @memcpy(inner[head..], rest);
        const params = try self.arena.alloc([]const u8, 2);
        params[0] = scope_param;
        params[1] = key_param;
        const lambda = try self.arena.create(ast.Expr);
        // Typed `unknown`, as the function type a component answers is: wasm
        // passes the scope and the place on as the words they are.
        const ptypes = try self.arena.alloc(ast.TypeRef, 2);
        ptypes[0] = .{ .named = ast.unknown_type_name };
        ptypes[1] = .{ .named = ast.unknown_type_name };
        lambda.* = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = inner, .paramTypes = ptypes } } };
        const out = try self.arena.alloc(ast.Stmt, 1);
        out[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = lambda } } } };
        return out;
    }

    /// Decision 574 — `{ component x -> body }` as `{ x -> return {
    /// bpScope__, bpKey__ -> body' }; }`, the body a `component fn`'s
    /// (`lowerComponentBody`). The tail the body answers (decision 541 (1)) is
    /// its `return`, so it is answered as a `return` is.
    fn lowerComponentLambda(self: *Lowering, f: anytype, r: *T.Type) !void {
        const body = f.kind.body;
        if (body.len > 0) {
            const s = &body[ast.lastRealIndex(body)];
            const tailable = switch (s.expr) {
                .binding, .useHook, .loop => false,
                .jump => |j| j.kind == .try_ or j.kind == .await_,
                .literal => |lit| lit.kind != .comment,
                else => true,
            };
            if (s.tail == .value and tailable) {
                const v = try self.arena.create(ast.Expr);
                v.* = s.expr;
                s.expr = .{ .jump = .{ .loc = v.getLoc(), .kind = .{ .@"return" = v } } };
                s.tail = .returned;
            }
        }
        f.kind.body = try self.lowerComponentBody(body, try self.typeRefOfType(r), false, f.loc);
        f.kind.marker = null;
    }

    /// `fn(unknown, unknown) -> R` (`unknown` when `R` is not written) — what a component function answers
    /// once lowered: no effect, so no backend wraps it in a Async.
    fn lambdaTypeOf(self: *Lowering, r: ?ast.TypeRef) !ast.TypeRef {
        const params = try self.arena.alloc(ast.TypeRef, 2);
        params[0] = .{ .named = ast.unknown_type_name };
        params[1] = .{ .named = ast.unknown_type_name };
        const ret = try self.arena.create(ast.TypeRef);
        ret.* = r orelse .{ .named = ast.unknown_type_name };
        return .{ .function = .{ .params = params, .returnType = ret } };
    }
};

/// Whether `body` holds a `try` outside every lambda — one the transform
/// left to the backends, which lower it as an early return of the error.
fn hasBareTry(body: []const ast.Stmt) bool {
    for (body) |*st| if (findJump(ast.Stmt, st, .try_)) return true;
    return false;
}

/// Whether `body` holds an `await` outside every lambda.
pub fn containsAwait(body: []const ast.Stmt) bool {
    for (body) |*st| if (findJump(ast.Stmt, st, .await_)) return true;
    return false;
}

fn findJump(comptime N: type, ptr: *const N, comptime tag: std.meta.Tag(ast.JumpExpr)) bool {
    if (N == ast.Expr) switch (ptr.*) {
        .jump => |j| if (j.kind == tag) return true,
        .function => return false,
        else => {},
    };
    if (comptime !mayHoldExpr(N)) return false;
    switch (@typeInfo(N)) {
        .@"struct" => |st| inline for (st.fields) |f| {
            if (f.is_comptime) continue;
            if (findJump(f.type, &@field(ptr.*, f.name), tag)) return true;
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (findJump(@TypeOf(payload.*), payload, tag)) return true,
            }
        },
        .optional => |o| if (ptr.*) |*inner| return findJump(o.child, inner, tag),
        .pointer => |pi| switch (pi.size) {
            .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") return findJump(pi.child, ptr.*, tag),
            .slice => for (ptr.*) |*e| if (findJump(pi.child, e, tag)) return true,
            else => {},
        },
        else => {},
    }
    return false;
}

/// Whether a value of `N` can reach an `ast.Expr` — prunes strings, locations
/// and type references.
fn mayHoldExpr(comptime N: type) bool {
    return switch (@typeInfo(N)) {
        .@"struct", .@"union" => N != ast.Loc and N != ast.TypeRef and N != ast.Param,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

/// A deep copy of `v`: every node behind a pointer or a slice is copied, and
/// text (`[]const u8`) is shared, being immutable.
pub fn deepCopy(comptime N: type, arena: std.mem.Allocator, v: N) anyerror!N {
    switch (@typeInfo(N)) {
        .@"struct" => |st| {
            var out: N = v;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try deepCopy(f.type, arena, @field(v, f.name));
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(N, @tagName(tag), try deepCopy(@TypeOf(payload), arena, payload)),
            }
        },
        .optional => |o| return if (v) |inner| try deepCopy(o.child, arena, inner) else null,
        .pointer => |pi| switch (pi.size) {
            .one => {
                if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") return v;
                const p = try arena.create(pi.child);
                p.* = try deepCopy(pi.child, arena, v.*);
                return p;
            },
            .slice => {
                if (pi.child == u8) return v;
                const out = try arena.alloc(pi.child, v.len);
                for (v, 0..) |e, i| out[i] = try deepCopy(pi.child, arena, e);
                return out;
            },
            else => return v,
        },
        else => return v,
    }
}

/// The `R` of a written `@Component<R>`.
fn writtenRenders(rt: ?ast.TypeRef) ?ast.TypeRef {
    const r = rt orelse return null;
    if (!writesComponent(r) or r.generic.args.len < 1) return null;
    return r.generic.args[0];
}

/// True when a written return is `@Component<…>` itself: the body is a
/// component's, lowered to its lambda. An alias that stands for it (`->
/// StyledView`) types the function but activates nothing (118): its body is
/// a plain one answering a component value — the lambda another body made.
fn writesComponent(rt: ?ast.TypeRef) bool {
    const r = rt orelse return false;
    return r == .generic and r.generic.is_builtin and std.mem.eql(u8, r.generic.name, "Component");
}

/// The behavior `name` — this module's or an imported one.
fn behaviorNamed(env: *Env, program: ast.Program, name: []const u8) ?ast.BehaviorDecl {
    for (program.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) return d.behavior;
    return env.importedBehaviorDecls.get(name);
}

/// The written return of an `implement` method answering `@Component<R>`:
/// its behavior's declaration says so (an implement method writes no
/// return). Null for any other method.
fn implementMethodComponent(env: *Env, program: ast.Program, im: ast.ImplementDecl, method: []const u8) ?ast.TypeRef {
    for (im.interfaces) |iface| {
        const name = switch (iface) {
            .named => |n| n,
            .generic => |g| g.name,
            else => continue,
        };
        const b = behaviorNamed(env, program, name) orelse continue;
        for (b.methods) |bm| if (std.mem.eql(u8, bm.name, method)) return if (writesComponent(bm.returnType)) bm.returnType else null;
    }
    return null;
}

/// True when the module holds anything the lowering reaches.
fn needed(env: *Env, program: ast.Program) bool {
    if (env.contextUses.count() > 0 or env.componentCalls.count() > 0 or
        env.componentLambdas.count() > 0 or env.lambdaPads.count() > 0 or env.createContextCalls.count() > 0 or env.memoUses.count() > 0 or env.allUses.count() > 0 or env.keyedExprs.count() > 0 or env.liftedStdTypes.contains("Context")) return true;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| if (writesComponent(f.returnType)) return true,
        .type_ => |t| for (t.methods) |m| if (writesComponent(m.returnType)) return true,
        .behavior => |b| for (b.methods) |m| if (writesComponent(m.returnType)) return true,
        else => {},
    };
    return false;
}

/// Lower the component model's scope (decisions 809 (8), 819) over `program`
/// (the transformed module).
pub fn lower(arena: std.mem.Allocator, program: ast.Program, env_const: *const Env) !ast.Program {
    const env = @constCast(env_const);
    // std's `context` module declares the hooks the lowering replaces where
    // they are `use`d (their bodies panic) and the functions it calls.
    if (std.mem.eql(u8, env.modulePath, "std/context")) return program;
    // std's `hooks` module declares `memo`, lowered where it is `use`d (its
    // body panics), and the slot functions the lowering calls.
    if (std.mem.eql(u8, env.modulePath, "std/hooks")) return program;
    if (!needed(env, program)) return program;
    var low: Lowering = .{ .arena = arena, .env = env };
    // The transformed module shares its nodes with the parsed one, which a
    // later compilation of the session checks again (`botopink test` builds
    // each test module over the same library modules): the lowering writes
    // into a deep copy, never into the parsed AST.
    // Only the declarations the lowering writes into are copied: a type
    // alias, an import and the like stay the parsed nodes the later passes
    // (`alias_erase.zig`) are handed today.
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    for (decls) |*d| switch (d.*) {
        .@"fn", .@"test", .val, .implement, .behavior => d.* = try deepCopy(ast.DeclKind, arena, d.*),
        // A type's methods are copied; its shape is not — the passes after
        // this one rewrite a type's shape where the parsed program holds it,
        // and the module's importers read that.
        .type_ => |*t| t.methods = try deepCopy([]ast.BehaviorMethod, arena, t.methods),
        else => {},
    };
    for (decls) |*d| switch (d.*) {
        .@"fn" => |*f| {
            for (f.params) |*p| if (p.default) |*dv| try low.walk(ast.Expr, dv);
            if (f.body.len == 0) continue;
            // Decision 570 — only a `component fn` is a component body; an
            // unmarked one answering `Component<R>` is a plain function
            // returning the whole value (`fn linha(p) -> Component<E> {
            // return Item(p); }`, 821 (2)).
            if (writesComponent(f.returnType) and f.marker == .component) {
                f.body = try low.lowerComponentBody(f.body, writtenRenders(f.returnType), env.syncFns.contains(f.name), f.nameLoc);
                f.returnType = try low.lambdaTypeOf(writtenRenders(f.returnType));
                f.effect = null;
            } else f.body = try low.lowerPlainBody(f.body, f.nameLoc);
        },
        .@"test" => |*t| t.body = try low.lowerPlainBody(t.body, t.loc),
        .val => |*v| try low.walk(ast.Expr, v.value),
        .type_ => |*t| {
            const methods = try arena.dupe(ast.BehaviorMethod, t.methods);
            for (methods) |*m| try lowerMethod(&low, m);
            t.methods = methods;
        },
        .implement => |*im| {
            const methods = try arena.dupe(ast.ImplementMethod, im.methods);
            for (methods) |*m| {
                if (implementMethodComponent(env, program, im.*, m.name)) |rt| {
                    m.body = try low.lowerComponentBody(m.body, writtenRenders(rt), false, m.loc);
                } else m.body = try low.lowerPlainBody(m.body, m.loc);
            }
            im.methods = methods;
        },
        .behavior => |*b| {
            const methods = try arena.dupe(ast.BehaviorMethod, b.methods);
            for (methods) |*m| try lowerMethod(&low, m);
            b.methods = methods;
        },
        else => {},
    };
    if (!low.uses_std) return .{ .decls = decls };
    // std's lowering functions, under names no source can collide with.
    const names = [_][3][]const u8{
        .{ "context", "enter", enter_fn },
        .{ "context", "received", received_fn },
        .{ "context", "provideIn", provide_fn },
        .{ "context", "find", find_fn },
        .{ "context", "answer", answer_fn },
        .{ "context", "nowhere", nowhere_fn },
        .{ "context", "root", root_fn },
        .{ "context", "memoIn", memo_in_fn },
        .{ "context", "allIn", all_in_fn },
        .{ "context", "stamp", stamp_fn },
        .{ "context", "stampPlain", stamp_plain_fn },
        .{ "context", "stampKeyed", stamp_keyed_fn },
        .{ "context", "countNew", count_new_fn },
        .{ "context", "countEnd", count_end_fn },
    };
    var count: usize = 0;
    for (names) |n| if (low.used.contains(n[2])) {
        count += 1;
    };
    const items = try arena.alloc(ast.ImportPath, count);
    var i: usize = 0;
    for (names) |n| if (low.used.contains(n[2])) {
        items[i] = .{ .segments = try arena.dupe([]const u8, &.{ n[0], n[1] }), .alias = n[2] };
        i += 1;
    };
    const grown = try arena.alloc(ast.DeclKind, decls.len + 1);
    grown[0] = .{ .use = .{ .imports = items, .source = .{ .module = "std" } } };
    @memcpy(grown[1..], decls);
    return .{ .decls = grown };
}

/// A type's method or a behavior's: a body answering `@Component<R>` becomes
/// its lambda, and the written return the lambda's type (a behavior's
/// bodyless declaration too, so its implementations agree). Its `component`
/// marker goes with the written return, as a top-level fn's `effect` does:
/// the method is then a plain function making the lambda (decision 791 (1)),
/// and only the lambda runs asynchronously when its body awaits (375).
fn lowerMethod(low: *Lowering, m: *ast.BehaviorMethod) !void {
    const component = writesComponent(m.returnType);
    const renders = writtenRenders(m.returnType);
    if (component) {
        m.returnType = try low.lambdaTypeOf(renders);
        if (m.marker == .component) m.marker = null;
    }
    const body = m.body orelse return;
    if (component) {
        m.body = try low.lowerComponentBody(body, renders, false, m.returnTypeLoc);
    } else m.body = try low.lowerPlainBody(body, m.returnTypeLoc);
}
