//! Decision 388 — a `@Component<R>` at run time is a lambda over an opaque
//! `RenderScope`, lowered on the transformed AST for every backend at once.
//!
//! A function whose resolved return is `@Component<R>` (a hook's and a
//! component's alike) answers the lambda; calling it runs nothing:
//!
//!   fn Card(item: Item) -> @Component<View> { body }
//!     →  fn Card(item: Item) -> fn(unknown) -> unknown { return { bpScope__ -> body' }; }
//!
//! In `body'` the lambda's parameter is the scope the body received, and the
//! children's scope starts as it:
//!
//!   use provide(c);      →  val bpScopeKids__N = bpScopePush__(<kids>, "<T's identity>", c);
//!   use context(ctx)     →  bpScopeFind__(bpScope__, "<ctx's type's identity>", ctx)
//!
//! where a `Context<T>` is its value at run time: `createContext(v)` is `v`.
//!   use h(…)             →  bpScopeValue__(await (h(…))(bpScope__))    — a hook is part of the body
//!   await c              →  bpScopeValue__(await (c)(<kids>))          — a child placed in the tree
//!   return v             →  return bpScopeRendered__(v, <kids>)
//!
//! and a body that ends without a `return` answers `rendered(null, <kids>)`.
//! Decisions 755, 771 — each `use memo(make)` position of the body is a slot
//! made with the component's value, before its lambda, and read in the body:
//!
//!   fn Page(…) -> … { val bpMemoSlot__N = bpMemoNew__(); return { bpScope__ -> … bpMemoRead__(bpMemoSlot__N, make) … }; }
//!
//! so one `Page(…)` call is one instance: its first render fills the slot
//! (`read` runs `make`), a later render of the same value reads it.
//! A `{ component x -> body }` lambda (decision 574, `Env.componentLambdas`)
//! is lowered the same way, its tail made its `return`:
//! `{ x -> return { bpScope__ -> body' }; }` — its parameters and what it
//! captures closed over by the inner lambda.
//! A component call the checker renders in a body (`inferComponentCall`, 128)
//! is an `await` of it, so it runs with the children's scope. Outside every
//! body — `main`, a test, a plain function, a lambda — an `await c` runs `c`
//! with `bpScopeRoot__()` (388 (4)), and `c.run(scope)` is the call of the
//! lambda `c` is (`Env.componentRuns`): the render library holds the scopes
//! explicitly. Nothing is captured: a lambda written in a body is outside it.
//!
//! On commonJS the `await` is left out where the target's node is
//! synchronous (`Env.syncCalls`, decision 375), so a synchronous component's
//! lambda awaits nothing and stays a plain arrow. A host function answering
//! `@Component<R>` (`Env.hostCalls`) answers the host's own value: a `use` or
//! an `await` of it runs nothing.
//!
//! The `bpScope…__` functions are std's `context.push` / `find` / `rendered`
//! / `valueOf` / `root`, imported under those names when the module needs
//! them (the import is added here). A context's identity is its value's type
//! (379), recorded by the checker in `Env.contextUses`: a read's fallback is
//! the context value it names (723), an `inject` field's the `val` that
//! declares its type's default (another module's through a hidden import,
//! `Env.contextDefaultImports`). A provide binds a fresh `val`, so a `return` after it
//! answers the scope as it was there (the checker refuses a provide after the
//! body rendered a component and a `use` after an early return).
//!
//! The comptime runtimes evaluate the parsed program (`erlang.zig`
//! `emitComptimeModule`) and do not run this pass (`language-gaps.md`).
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const T = @import("types.zig");
const infer = @import("infer.zig");

const Env = envMod.Env;

/// The parameter of a component's lambda: the scope its body received.
pub const scope_param = "bpScope__";
/// The local names std's lowering functions are imported under.
pub const push_fn = "bpScopePush__";
pub const find_fn = "bpScopeFind__";
pub const rendered_fn = "bpScopeRendered__";
pub const value_fn = "bpScopeValue__";
pub const root_fn = "bpScopeRoot__";
/// std's `hooks.slot` / `hooks.read` (decision 771), imported under these.
pub const memo_new_fn = "bpMemoNew__";
pub const memo_read_fn = "bpMemoRead__";

/// The children's scope a `use provide` binds (`bpScopeKids__<n>`).
const kids_prefix = "bpScopeKids__";
/// A `use memo` position's slot (`bpMemoSlot__<n>`).
const memo_slot_prefix = "bpMemoSlot__";
/// The inner closure's answer, in a body that keeps a bare `try`.
const result_local = "bpScopeResult__";

/// The lowering's functions, as `wat.zig` refuses them.
pub const lowered_fns = [_][]const u8{ push_fn, find_fn, rendered_fn, value_fn, root_fn, memo_new_fn, memo_read_fn };

const Frame = struct {
    /// The scope this body received (its lambda's parameter).
    received: []const u8,
    /// The scope its children receive: `received` until a `use provide`.
    kids: []const u8,
    /// Each `return v` answers `rendered(v, kids)`; false when the body runs
    /// as an inner closure (a bare `try` in it, `lowerComponentBody`).
    wraps_returns: bool = true,
    /// The `R` of the `@Component<R>` the body answers, as written — what
    /// each `rendered(v, kids)` carries (`carry`).
    renders: ?ast.TypeRef = null,
};

const Lowering = struct {
    arena: std.mem.Allocator,
    env: *Env,
    /// One entry per body being walked: a component body's frame, or null
    /// for a body that is none (a lambda, a plain function, a test).
    frames: std.ArrayListUnmanaged(?Frame) = .empty,
    kids_count: usize = 0,
    uses_std: bool = false,
    /// Decision 771 — the slots of the `use memo` positions of the bodies
    /// being walked; a component body takes the ones its walk added.
    memo_slots: std.ArrayListUnmanaged([]const u8) = .empty,
    memo_count: usize = 0,
    uses_hooks: bool = false,

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
    /// `unknown` slots (`push`'s and `rendered`'s value, `find`'s and
    /// `valueOf`'s answer, the `Rendered<R>` a `c.run(scope)` answers),
    /// written as the call's one type argument. The checker never reads
    /// these calls (they are made after inference) and erlang, beam and
    /// commonJS ignore a call's type arguments; wasm, which boxes and unboxes
    /// only by a static type, moves the value's own word through the slot by
    /// it. Nothing is written when the type is not resolved: wasm then
    /// refuses the call.
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

    /// The scope a component value runs with here: in a body the children's
    /// scope (`renders`) or the received one (a hook, part of the body);
    /// outside every body `RenderScope.root()`.
    fn scopeArg(self: *Lowering, renders: bool, loc: ast.Loc) !*ast.Expr {
        const f = self.current() orelse return self.call(root_fn, &.{}, loc);
        return self.ident(if (renders) f.kids else f.received, loc);
    }

    /// `valueOf(await (c)(scope))` — run a component value, answer its
    /// result, the `R` it renders carried (`carry`).
    fn run(self: *Lowering, c: *ast.Expr, scope: *ast.Expr, awaited: bool, r: ?*T.Type, loc: ast.Loc) !ast.Expr {
        var ran = try self.callValue(c, &.{scope}, loc);
        // The run itself answers `Rendered<R>`: wasm reads the lambda's
        // mark there (decision 504, `codegen/wat/scope_carry.zig`).
        if (r) |t| try self.carry(ran, try self.renderedOf(t));
        if (awaited) {
            const w = try self.arena.create(ast.Expr);
            w.* = .{ .jump = .{ .loc = loc, .kind = .{ .await_ = ran } } };
            ran = w;
        }
        const carried = if (r) |t| try self.typeRefOfType(t) else null;
        return (try self.callCarrying(value_fn, &.{ran}, carried, loc)).*;
    }

    /// `Rendered<R>`, written, for the `R` a run renders.
    fn renderedOf(self: *Lowering, r: *T.Type) !?ast.TypeRef {
        const rr = (try self.typeRefOfType(r)) orelse return null;
        const args = try self.arena.alloc(ast.TypeRef, 1);
        args[0] = rr;
        return .{ .generic = .{ .name = "Rendered", .args = args, .is_builtin = false } };
    }

    /// The `R` the hook call `inner` renders, when the checker typed it
    /// `@Component<R>`.
    fn hookRenders(self: *Lowering, inner: *const ast.Expr) ?*T.Type {
        if (inner.* != .call) return null;
        const ty = self.env.componentCalls.get(inner.call.loc) orelse return null;
        return componentOf(ty);
    }

    /// The `R` a component value of `ty` renders, when `ty` resolved to
    /// `@Component<R>`.
    fn componentOf(ty: *T.Type) ?*T.Type {
        const d = ty.deref();
        if (d.* != .named or !std.mem.eql(u8, d.named.name, "Component") or d.named.args.len < 1) return null;
        return d.named.args[0];
    }

    /// The component value an `await` at `loc` over `operand` runs, as its
    /// `R`: a written `await` the checker recorded, or the `await` it spliced
    /// around a component call it renders in a body (same location).
    fn awaitedComponent(self: *Lowering, loc: ast.Loc, operand: *const ast.Expr) ?*T.Type {
        if (operand.* == .call and operand.call.kind == .call) {
            if (self.env.hostCalls.contains(operand.call.loc)) return null;
        }
        if (self.env.componentAwaits.get(loc)) |ty| return componentOf(ty);
        if (operand.* == .call and operand.call.kind == .call and std.meta.eql(operand.call.loc, loc)) {
            const ty = self.env.componentCalls.get(loc) orelse return null;
            return componentOf(ty);
        }
        return null;
    }

    /// Whether the call at `loc` runs a synchronous node (commonJS awaits it
    /// not, decision 375).
    fn syncAt(self: *Lowering, operand: *const ast.Expr, useLoc: ?ast.Loc) bool {
        if (useLoc) |l| return self.env.syncCalls.contains(l);
        if (operand.* == .call) return self.env.syncCalls.contains(operand.call.loc);
        return false;
    }

    /// `use provide(C, v)` as a whole statement: bind the children's scope.
    fn lowerProvideStmt(self: *Lowering, stmt: *ast.Stmt, use: envMod.ContextUse) !void {
        const inner = stmt.expr.useHook.kind.inner;
        const loc = stmt.expr.getLoc();
        // Decision 379 (2) — `use provide(ctx)`: the children's scope holds
        // the context's value under its type.
        const ctx = inner.call.kind.call.args[0].value;
        try self.walk(ast.Expr, ctx);
        const value = ctx;
        const f = self.current() orelse return error.ContextLowering;
        const name = try std.fmt.allocPrint(self.arena, kids_prefix ++ "{d}", .{self.kids_count});
        self.kids_count += 1;
        const pushed = try self.callCarrying(push_fn, &.{ try self.ident(f.kids, loc), try self.string(use.key, loc), value }, try self.typeRefOfType(use.value_type), loc);
        stmt.expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = name, .value = pushed, .mutable = false } } } };
        self.frames.items[self.frames.items.len - 1].?.kids = name;
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
                const scope = try self.scopeArg(false, loc);
                break :blk try self.callCarrying(find_fn, &.{ scope, try self.string(key, loc), fallback }, try self.typeRefOfType(f.value_type), loc);
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
                    try self.walk(ast.Expr, make);
                    const name = try std.fmt.allocPrint(self.arena, memo_slot_prefix ++ "{d}", .{self.memo_count});
                    self.memo_count += 1;
                    try self.memo_slots.append(self.arena, name);
                    self.uses_hooks = true;
                    e.* = (try self.callCarrying(memo_read_fn, &.{ try self.ident(name, uh.loc), make }, try self.typeRefOfType(t), uh.loc)).*;
                    return true;
                }
                if (self.env.contextUses.get(uh.loc)) |use| {
                    if (use.kind == .provide) return error.ContextLowering; // a statement of its own
                    if (use.kind == .inject) {
                        e.* = (try self.injectRecord(use, uh.loc)).*;
                        return true;
                    }
                    const scope = try self.scopeArg(false, uh.loc);
                    // Decisions 378 (3), 723 — no read is unbound: the
                    // default of the value it names when nothing of its
                    // type is provided above.
                    const fallback = try self.ident(use.default_ref orelse return error.ContextLowering, uh.loc);
                    e.* = (try self.callCarrying(find_fn, &.{ scope, try self.string(use.key, uh.loc), fallback }, try self.typeRefOfType(use.value_type), uh.loc)).*;
                    return true;
                }
                const inner = uh.kind.inner;
                if (inner.* == .call and inner.call.kind == .call and self.env.hostCalls.contains(inner.call.loc)) return false;
                const renders = self.hookRenders(inner);
                try self.walk(ast.Expr, inner);
                e.* = try self.run(inner, try self.scopeArg(false, uh.loc), !self.syncAt(inner, uh.loc), renders, uh.loc);
                return true;
            },
            .jump => |*j| switch (j.kind) {
                .await_ => |operand| if (self.awaitedComponent(j.loc, operand)) |r| {
                    try self.walk(ast.Expr, operand);
                    const scope = try self.scopeArg(isRenderable(self.env, r), j.loc);
                    e.* = try self.run(operand, scope, !self.syncAt(operand, null), r, j.loc);
                    return true;
                },
                .@"return" => |value| if (self.current()) |f| if (f.wraps_returns) {
                    if (value) |v| try self.walk(ast.Expr, v);
                    const kids = self.current().?.kids;
                    const v = value orelse try self.nullLit(j.loc);
                    j.kind = .{ .@"return" = try self.callCarrying(rendered_fn, &.{ v, try self.ident(kids, j.loc) }, f.renders, j.loc) };
                    return true;
                },
                else => {},
            },
            .call => |*c| if (c.kind == .call and self.env.componentRuns.get(c.loc) != null) {
                const cc = c.kind.call;
                const recv = cc.receiver orelse return false;
                // The `R` the value renders: the run answers `Rendered<R>`.
                const renders = self.env.componentRuns.get(c.loc).?;
                try self.walk(ast.Expr, recv);
                try self.walk(ast.Expr, cc.args[0].value);
                const ran = try self.callValue(recv, &.{cc.args[0].value}, c.loc);
                try self.carry(ran, try self.renderedOf(renders));
                e.* = ran.*;
                return true;
            },
            .function => |*f| {
                // Decision 574 — a `{ component -> … }` lambda is a
                // `component fn`: its body becomes the lambda over the scope,
                // the lambda's parameters and captures closed over by it.
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

    /// Walk a body that is no component's (a plain function, a test).
    fn lowerPlainBody(self: *Lowering, body: []ast.Stmt) !void {
        try self.frames.append(self.arena, null);
        defer _ = self.frames.pop();
        for (body) |*s| try self.walk(ast.Stmt, s);
    }

    /// A component's body as its lambda: `[return { bpScope__ -> body' }]`.
    ///
    /// A body that keeps a bare `try` (one the transform did not turn into a
    /// `return`) runs its statements after the last `use provide` as an inner
    /// closure, whose answer — the value, or the error a `try` returns early,
    /// which every backend lowers as the closure's own return — is the
    /// body's result: `val bpScopeResult__ = ({ -> rest })(); return
    /// rendered(bpScopeResult__, kids);`. Nothing before the last provide can
    /// leave early (357: no `use` after an early exit).
    fn lowerComponentBody(self: *Lowering, body: []ast.Stmt, renders: ?ast.TypeRef, loc: ast.Loc) ![]ast.Stmt {
        const inner_closure = hasBareTry(body);
        try self.frames.append(self.arena, Frame{ .received = scope_param, .kids = scope_param, .wraps_returns = !inner_closure, .renders = renders });
        defer _ = self.frames.pop();
        const memo_start = self.memo_slots.items.len;
        for (body) |*s| try self.walk(ast.Stmt, s);
        // Decision 771 — this body's `use memo` slots, made with the value.
        const slots = try self.arena.dupe([]const u8, self.memo_slots.items[memo_start..]);
        self.memo_slots.shrinkRetainingCapacity(memo_start);
        const kids = self.current().?.kids;
        const inner: []ast.Stmt = if (inner_closure) blk: {
            var split: usize = 0;
            for (body, 0..) |st, i| if (st.expr == .binding and st.expr.binding.kind == .localBind and
                std.mem.startsWith(u8, st.expr.binding.kind.localBind.name, kids_prefix))
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
            const ret = try self.callCarrying(rendered_fn, &.{ try self.ident(result_local, loc), try self.ident(kids, loc) }, renders, loc);
            out[split + 1] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = ret } } } };
            break :blk out;
        } else if (body.len > 0 and body[body.len - 1].expr == .jump and body[body.len - 1].expr.jump.kind == .@"return")
            body
        else blk: {
            const grown = try self.arena.alloc(ast.Stmt, body.len + 1);
            @memcpy(grown[0..body.len], body);
            const ret = try self.callCarrying(rendered_fn, &.{ try self.nullLit(loc), try self.ident(kids, loc) }, renders, loc);
            grown[body.len] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = ret } } } };
            break :blk grown;
        };
        const params = try self.arena.alloc([]const u8, 1);
        params[0] = scope_param;
        const lambda = try self.arena.create(ast.Expr);
        lambda.* = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = inner } } };
        const out = try self.arena.alloc(ast.Stmt, slots.len + 1);
        for (slots, 0..) |name, i| {
            const made = try self.call(memo_new_fn, &.{}, loc);
            out[i] = .{ .expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = name, .value = made, .mutable = false } } } } };
        }
        out[slots.len] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = lambda } } } };
        return out;
    }

    /// Decision 574 — `{ component x -> body }` as `{ x -> return { bpScope__
    /// -> body' }; }`, the body a `component fn`'s (`lowerComponentBody`).
    /// The tail the body answers (decision 541 (1)) is its `return`, so it
    /// is rendered as a `return` is.
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
        f.kind.body = try self.lowerComponentBody(body, try self.typeRefOfType(r), f.loc);
        f.kind.marker = null;
    }

    /// `fn(unknown) -> unknown` — what a component function answers once
    /// lowered: no effect, so no backend wraps it in a Async.
    fn lambdaType(self: *Lowering) !ast.TypeRef {
        const params = try self.arena.alloc(ast.TypeRef, 1);
        params[0] = .{ .named = ast.unknown_type_name };
        const ret = try self.arena.create(ast.TypeRef);
        ret.* = .{ .named = ast.unknown_type_name };
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

fn isRenderable(env: *Env, r: *T.Type) bool {
    const d = r.deref();
    if (d.* != .named) return true; // an `R` still open renders, as a component's would
    const td = env.lookupTypeDef(d.named.name) orelse return false;
    return td.isRenderable();
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
        env.componentAwaits.count() > 0 or env.componentRuns.count() > 0 or
        env.componentLambdas.count() > 0 or env.createContextCalls.count() > 0 or env.memoUses.count() > 0 or env.liftedStdTypes.contains("Context")) return true;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| if (writesComponent(f.returnType)) return true,
        .type_ => |t| for (t.methods) |m| if (writesComponent(m.returnType)) return true,
        .behavior => |b| for (b.methods) |m| if (writesComponent(m.returnType)) return true,
        else => {},
    };
    return false;
}

/// Lower decision 388's render scope over `program` (the transformed module).
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
            if (writesComponent(f.returnType)) {
                f.body = try low.lowerComponentBody(f.body, writtenRenders(f.returnType), f.nameLoc);
                f.returnType = try low.lambdaType();
                f.effect = null;
            } else try low.lowerPlainBody(f.body);
        },
        .@"test" => |*t| try low.lowerPlainBody(t.body),
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
                    m.body = try low.lowerComponentBody(m.body, writtenRenders(rt), m.loc);
                } else try low.lowerPlainBody(m.body);
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
        .{ "context", "push", push_fn },
        .{ "context", "find", find_fn },
        .{ "context", "rendered", rendered_fn },
        .{ "context", "valueOf", value_fn },
        .{ "context", "root", root_fn },
        .{ "hooks", "slot", memo_new_fn },
        .{ "hooks", "read", memo_read_fn },
    };
    const count = if (low.uses_hooks) names.len else names.len - 2;
    const items = try arena.alloc(ast.ImportPath, count);
    for (names[0..count], 0..) |n, i| items[i] = .{ .segments = try arena.dupe([]const u8, &.{ n[0], n[1] }), .alias = n[2] };
    const grown = try arena.alloc(ast.DeclKind, decls.len + 1);
    grown[0] = .{ .use = .{ .imports = items, .source = .{ .module = "std" } } };
    @memcpy(grown[1..], decls);
    return .{ .decls = grown };
}

/// A type's method or a behavior's: a body answering `@Component<R>` becomes
/// its lambda, and the written return the lambda's type (a behavior's
/// bodyless declaration too, so its implementations agree).
fn lowerMethod(low: *Lowering, m: *ast.BehaviorMethod) !void {
    const component = writesComponent(m.returnType);
    const renders = writtenRenders(m.returnType);
    if (component) m.returnType = try low.lambdaType();
    const body = m.body orelse return;
    if (component) {
        m.body = try low.lowerComponentBody(body, renders, m.returnTypeLoc);
    } else try low.lowerPlainBody(body);
}
