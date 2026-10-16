//! Decision 562 — a function whose every parameter is `comptime` and whose
//! body reads one's `.value` (`hooks.isExpandedFn`) is expanded at its call
//! site: the call is replaced by the code its body emits, written where the
//! call is.
//!
//! The body is walked with each parameter bound to its argument, known at
//! build (417, `infer.refuseRuntimeComptimeArg`). A loop over a value known
//! at build, a condition, a `val` and a call answered from build data alone
//! (a `Declared`'s `name`, `module`, `meta`, a literal, another `comptime`
//! value, a constant `val` of the module, std's functions over them, 380)
//! run at build: their values are computed by the comptime runtime as a
//! `comptime` of them would be (`infer.foldBodyComptime`), and `x.fail(…)`
//! reports at the argument. Each other statement — one that reaches a
//! run-time value (a `Declared`'s `value`, a host call, a function of
//! `Stage.Run`, a local the expansion emitted) — is emitted, in order, once
//! per iteration of the loop that holds it, the build-known parts written
//! into it as constants. A loop's bound or a condition that needs a run-time
//! value is refused at it (`run-in-build`), naming the value.
//!
//! The emitted statements form a block (decision 525) that stands for the
//! call: inference types it in the caller's environment and records it in
//! `Env.templateExpansions` under the call's location, where the transform
//! splices it as it splices a template's expansion. Each copy of a body
//! statement is located in an expansion of its own (`Env.expansionCount`),
//! so no two copies share a location. A name the body writes that resolves
//! in another module (the declaring module's functions and values) is bound
//! in the caller under its alias, as a template's library's names are
//! (decision 112, `written_names.bindValue`). The function itself has no
//! run-time body (`transform.zig` drops it).
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const envMod = @import("env.zig");
const Env = envMod.Env;
const infer = @import("infer.zig");
const hooks = @import("hooks.zig");
const diagnostics = @import("diagnostics.zig");
const TypeError = @import("error.zig").TypeError;
const writtenNames = @import("written_names.zig");
const templateEval = @import("template_eval.zig");
const typeinfoAll = @import("typeinfo_all.zig");
const formatMod = @import("../format.zig");
const exprsMod = @import("../parser/exprs.zig");

const InferError = infer.InferError;

/// What a name of the body stands for while it is expanded.
const Bound = union(enum) {
    /// A `comptime` parameter: its argument, known at build.
    param: Arg,
    /// A `val` or a loop's name computed at build: its value.
    build: *const ast.Expr,
    /// A local the expansion emitted: a run-time value.
    runtime,
};

const Arg = struct {
    value: *const ast.Expr,
    /// Where the argument is written (the call's location for a default).
    loc: ast.Loc,
};

const Binding = struct { name: []const u8, bound: Bound };

const Flow = enum { normal, brk, cont, ret };

/// A run-time value the body reaches, as written.
const RunRead = struct { loc: ast.Loc, text: []const u8 };

/// The function a call names, when it is expanded at its call site.
const Target = struct { decl: ast.FnDecl, owner: []const u8 };

/// Decision 562 — the call `c` at `loc`, typed `typed`, of a function
/// expanded at its call site: its expansion, typed in the caller's
/// environment, or null when the call is not one (or is not expanded here:
/// inside a `comptime`, a decorator's or a template's body, which run at
/// build, or in a session that runs no comptime).
pub fn expand(env: *Env, c: ast.CallExprOf(.untyped), loc: ast.Loc, expected: ?*T.Type) InferError!?ast.TypedExpr {
    if (env.templateEval == null) return null;
    if (env.comptimeDepth > 0 or env.inDecoratorFn or env.inTemplateFn) return null;
    if (c.kind != .call) return null;
    const call = c.kind.call;
    if (call.is_builtin or call.calleeExpr != null or call.trailing.len > 0) return null;
    const target = (try targetOf(env, call)) orelse return null;
    const key = @intFromPtr(target.decl.body.ptr);
    if (env.expanding.contains(key)) return null;
    const args = (try argsOf(env, target.decl, call.args, loc)) orelse return null;

    try env.expanding.put(env.arena, key, {});
    defer _ = env.expanding.remove(key);

    var x: Expander = .{
        .env = env,
        .owner = target.owner,
        .foreign = !std.mem.eql(u8, target.owner, env.modulePath),
        .call_loc = loc,
    };
    for (target.decl.params, args) |p, a| try x.bindings.append(env.arena, .{ .name = p.name, .bound = .{ .param = a } });
    var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;
    _ = try x.walk(target.decl.body, &out);

    const expansion = try env.arena.create(ast.Expr);
    if (out.items.len == 0 and x.tail != null) {
        expansion.* = x.tail.?.*;
    } else if (out.items.len == 1 and x.tail == null and !declares(out.items)) {
        expansion.* = out.items[0].expr;
    } else {
        if (x.tail) |t| try out.append(env.arena, .{ .expr = t.*, .tail = .value });
        expansion.* = exprsMod.makeBlockExpr(env.arena, .{ .line = loc.line, .col = loc.col, .expansion = x.fresh() }, out.items) catch return error.OutOfMemory;
    }
    const saved = env.expectedType;
    env.expectedType = expected;
    defer env.expectedType = saved;
    const typed = try infer.inferExprTyped(env, expansion.*);
    try env.templateExpansions.put(loc, expansion);
    return typed;
}

/// The function `call` names, when it is expanded: this module's own
/// (not shadowed by a local) or one imported by name or through a namespace.
fn targetOf(env: *Env, call: anytype) InferError!?Target {
    if (call.receiver) |r| {
        if (r.* != .identifier or r.identifier.kind != .ident) return null;
        const ns = r.identifier.kind.ident;
        if (env.localBindDepth(ns) != null) return null;
        const k = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ ns, call.callee });
        const imp = env.expandedImports.get(k) orelse return null;
        return .{ .decl = imp.decl, .owner = imp.owner };
    }
    if (env.localBindDepth(call.callee) != null) return null;
    if (env.expandedImports.get(call.callee)) |imp| return .{ .decl = imp.decl, .owner = imp.owner };
    // An alias a template's or an expansion's code is written with
    // (`written_names.bindValue`).
    if (env.templateImports.get(call.callee)) |ti| if (env.expandedImports.get(try aliasKey(env.arena, ti.owner, ti.name))) |imp| return .{ .decl = imp.decl, .owner = imp.owner };
    const f = env.fnDecls.get(call.callee) orelse return null;
    if (!try hooks.isExpandedFn(env.arena, f)) return null;
    return .{ .decl = f, .owner = env.modulePath };
}

/// The key `Env.expandedImports` holds a function reached through an alias
/// under (`<module>\x00<name>`).
fn aliasKey(arena: std.mem.Allocator, module: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ module, name });
}

/// Each parameter's argument, in the parameters' order: the one the call
/// writes (by position, or by its label) or the parameter's default. Null
/// when a parameter is left to a catalogue default not answered in this
/// analysis (551's first analysis of the root, `fillCatalogueDefaults`).
fn argsOf(env: *Env, f: ast.FnDecl, written: []const ast.CallArg, loc: ast.Loc) InferError!?[]Arg {
    const out = try env.arena.alloc(?Arg, f.params.len);
    @memset(out, null);
    var pos: usize = 0;
    for (written) |a| {
        const i = if (a.label) |l| blk: {
            for (f.params, 0..) |p, pi| if (std.mem.eql(u8, p.name, l)) break :blk pi;
            return null;
        } else blk: {
            while (pos < f.params.len and out[pos] != null) pos += 1;
            break :blk pos;
        };
        if (i >= f.params.len) return null;
        const value = env.srcRewrites.get(a.value.getLoc()) orelse a.value;
        out[i] = .{ .value = value, .loc = a.value.getLoc() };
    }
    const args = try env.arena.alloc(Arg, f.params.len);
    for (f.params, out, 0..) |p, a, i| {
        if (a) |given| {
            args[i] = given;
            continue;
        }
        const d = p.default orelse return null;
        if (typeinfoAll.isCatalogueDefault(p)) return null;
        const dp = try env.arena.create(ast.Expr);
        dp.* = d;
        args[i] = .{ .value = dp, .loc = loc };
    }
    return args;
}

const Expander = struct {
    env: *Env,
    /// The module the function is declared in.
    owner: []const u8,
    /// True when `owner` is not the calling module: its names are bound
    /// here under their aliases.
    foreign: bool,
    call_loc: ast.Loc,
    bindings: std.ArrayListUnmanaged(Binding) = .empty,
    /// Names a lambda of the body binds, while it is copied or read.
    shadows: std.ArrayListUnmanaged([]const u8) = .empty,
    /// The value a `return` answered.
    tail: ?*const ast.Expr = null,

    fn fresh(self: *Expander) u32 {
        self.env.expansionCount += 1;
        return self.env.expansionCount;
    }

    fn lookup(self: *Expander, name: []const u8) ?Bound {
        for (self.shadows.items) |s| if (std.mem.eql(u8, s, name)) return null;
        var i = self.bindings.items.len;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, self.bindings.items[i].name, name)) return self.bindings.items[i].bound;
        }
        return null;
    }

    fn shadowed(self: *Expander, name: []const u8) bool {
        for (self.shadows.items) |s| if (std.mem.eql(u8, s, name)) return true;
        return false;
    }

    // ── statements ───────────────────────────────────────────────────────

    fn walk(self: *Expander, stmts: []const ast.Stmt, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!Flow {
        const mark = self.bindings.items.len;
        defer self.bindings.shrinkRetainingCapacity(mark);
        for (stmts) |*st| {
            const flow = try self.stmt(st, out);
            if (flow != .normal) return flow;
        }
        return .normal;
    }

    fn emit(self: *Expander, st: *const ast.Stmt, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!void {
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = false };
        var copied = try cp.copy(ast.Stmt, st.*);
        // A body's last expression answers nothing here: the block's value is
        // the `return`'s (`tail`).
        copied.tail = .none;
        try out.append(self.env.arena, copied);
    }

    fn stmt(self: *Expander, st: *const ast.Stmt, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!Flow {
        if (st.deferred) {
            try self.emit(st, out);
            return .normal;
        }
        const e = &st.expr;
        switch (e.*) {
            .literal => |l| if (l.kind == .comment) return .normal,
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    if (!lb.mutable and lb.typeAnnotation == null and self.runRead(lb.value) == null) {
                        const v = try self.evalBuild(lb.value);
                        try self.bindings.append(self.env.arena, .{ .name = lb.name, .bound = .{ .build = v } });
                        return .normal;
                    }
                    try self.emit(st, out);
                    try self.bindings.append(self.env.arena, .{ .name = lb.name, .bound = .runtime });
                    return .normal;
                },
                .localBindDestruct => |lb| {
                    try self.emit(st, out);
                    var names: std.ArrayListUnmanaged([]const u8) = .empty;
                    try destructNames(self.env.arena, lb.pattern, &names);
                    for (names.items) |n| try self.bindings.append(self.env.arena, .{ .name = n, .bound = .runtime });
                    return .normal;
                },
                .assign => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |iff| return self.ifStmt(iff, out),
                .tryCatch => {},
            },
            .loop => |lp| return self.loopStmt(lp, out),
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |value| {
                        self.tail = if (self.runRead(value) == null) try self.evalBuild(value) else try self.copyBody(value);
                    }
                    return .ret;
                },
                .@"break" => |bk| if (bk.value == null and bk.label == null) return .brk,
                .@"continue" => |ct| if (ct.label == null) return .cont,
                else => {},
            },
            .call => |c| if (c.kind == .call) if (try self.failCall(c.kind.call)) return .normal,
            else => {},
        }
        try self.emit(st, out);
        return .normal;
    }

    /// `x.fail(message)` on a `comptime` parameter: reported at build, at
    /// the argument (decision 364 (3)).
    fn failCall(self: *Expander, call: anytype) InferError!bool {
        if (!std.mem.eql(u8, call.callee, "fail")) return false;
        const r = call.receiver orelse return false;
        if (r.* != .identifier or r.identifier.kind != .ident) return false;
        const b = self.lookup(r.identifier.kind.ident) orelse return false;
        if (b != .param or call.args.len != 1) return false;
        const msg = try self.evalBuild(call.args[0].value);
        const text = if (msg.* == .literal and msg.literal.kind == .stringLit)
            (try templateEval.lexemeBytes(self.env.arena, msg.literal.kind.stringLit)) orelse msg.literal.kind.stringLit
        else
            try exprText(self.env.arena, msg.*);
        self.env.lastError = TypeError.custom(text, "raised by the function expanded here via `fail` on this argument (decisions 364 (3), 562)").withLoc(b.param.loc);
        return error.TypeError;
    }

    fn ifStmt(self: *Expander, iff: anytype, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!Flow {
        if (self.runRead(iff.cond)) |rr| return self.refuse(rr, "this condition is decided at build");
        const v = try self.evalBuild(iff.cond);
        const chosen: ?[]const ast.Stmt, const bind: ?*const ast.Expr = if (iff.binding != null)
            (if (isNull(v.*)) .{ iff.else_, null } else .{ iff.then_, v })
        else if (isTrue(v.*))
            .{ iff.then_, null }
        else
            .{ iff.else_, null };
        const body = chosen orelse return .normal;
        const mark = self.bindings.items.len;
        defer self.bindings.shrinkRetainingCapacity(mark);
        if (iff.binding) |name| if (bind) |b| try self.bindings.append(self.env.arena, .{ .name = name, .bound = .{ .build = b } });
        return self.block(body, out);
    }

    /// `body` walked into a block of its own (its locals scoped), appended
    /// to `out` when it emitted anything.
    fn block(self: *Expander, body: []const ast.Stmt, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!Flow {
        var inner: std.ArrayListUnmanaged(ast.Stmt) = .empty;
        const flow = try self.walk(body, &inner);
        // Statements that bind nothing are written in place.
        if (!declares(inner.items)) {
            try out.appendSlice(self.env.arena, inner.items);
        } else {
            const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = self.fresh() };
            const blk = exprsMod.makeBlockExpr(self.env.arena, loc, inner.items) catch return error.OutOfMemory;
            try out.append(self.env.arena, .{ .expr = blk });
        }
        return flow;
    }

    fn loopStmt(self: *Expander, lp: anytype, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!Flow {
        if (lp.condition) {
            if (self.runRead(lp.iter)) |rr| return self.refuse(rr, "this loop's condition is decided at build");
            while (isTrue((try self.evalBuild(lp.iter)).*)) {
                switch (try self.block(lp.body, out)) {
                    .brk => break,
                    .ret => return .ret,
                    else => {},
                }
            }
            return .normal;
        }
        if (self.runRead(lp.iter)) |rr| return self.refuse(rr, "this loop's bound is decided at build");
        var elems: std.ArrayListUnmanaged(*const ast.Expr) = .empty;
        if (lp.iter.* == .collection and lp.iter.collection.kind == .range) {
            const r = lp.iter.collection.kind.range;
            const start = try self.evalInt(r.start);
            const end_expr = r.end orelse return self.unsupported(lp.iter.getLoc(), "an open range is iterated at build only with an end");
            var end = try self.evalInt(end_expr);
            if (r.inclusive) end += 1;
            var i = start;
            while (i < end) : (i += 1) {
                const n = try self.env.arena.create(ast.Expr);
                n.* = .{ .literal = .{ .loc = self.call_loc, .kind = .{ .numberLit = try std.fmt.allocPrint(self.env.arena, "{d}", .{i}) } } };
                try elems.append(self.env.arena, n);
            }
        } else {
            const v = try self.evalBuild(lp.iter);
            const arr = arrayOf(v) orelse return self.unsupported(lp.iter.getLoc(), "a loop is unrolled at build over an array or a range");
            for (arr) |*el| try elems.append(self.env.arena, el);
        }
        for (elems.items) |el| {
            const mark = self.bindings.items.len;
            if (lp.params.len > 0) try self.bindings.append(self.env.arena, .{ .name = lp.params[0], .bound = .{ .build = el } });
            const flow = try self.block(lp.body, out);
            self.bindings.shrinkRetainingCapacity(mark);
            switch (flow) {
                .brk => break,
                .ret => return .ret,
                else => {},
            }
        }
        return .normal;
    }

    fn refuse(self: *Expander, rr: RunRead, what: []const u8) InferError!Flow {
        const msg = try std.fmt.allocPrint(self.env.arena, "{s}: `{s}` runs only at run time — {s}{s}", .{ diagnostics.run_in_build, rr.text, what, try self.where(rr.loc) });
        self.env.lastError = TypeError.custom(msg, "A function whose every parameter is `comptime` is expanded where it is called (decision 562): its loops and conditions run at build, over build data alone — a `Declared`'s `name`, `module` and `meta`, literals, `comptime` values and constants.").withLoc(self.at(rr.loc));
        return error.TypeError;
    }

    fn unsupported(self: *Expander, loc: ast.Loc, what: []const u8) InferError!Flow {
        const msg = try std.fmt.allocPrint(self.env.arena, "{s}: {s}{s}", .{ diagnostics.run_in_build, what, try self.where(loc) });
        self.env.lastError = TypeError.custom(msg, "A function whose every parameter is `comptime` is expanded where it is called (decision 562).").withLoc(self.at(loc));
        return error.TypeError;
    }

    /// Where a refusal of the body is located: at it in this module's
    /// function, else at the call, the body's place named (`where`).
    fn at(self: *Expander, loc: ast.Loc) ast.Loc {
        return if (self.foreign) self.call_loc else loc;
    }

    fn where(self: *Expander, loc: ast.Loc) InferError![]const u8 {
        if (!self.foreign) return "";
        return std.fmt.allocPrint(self.env.arena, " (at {s}:{d}:{d}, in the function expanded here)", .{ self.env.srcPathOf(self.owner), loc.line, loc.col });
    }

    // ── values at build ──────────────────────────────────────────────────

    /// The value of `e`, known at build: written as data when it already is
    /// one, else computed as a `comptime` of it (`infer.foldBodyComptime`).
    fn evalBuild(self: *Expander, e: *const ast.Expr) InferError!*const ast.Expr {
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = true };
        const s = try self.env.arena.create(ast.Expr);
        s.* = try cp.copy(ast.Expr, e.*);
        if (isData(s.*)) return s;
        const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = self.fresh() };
        const node: ast.Expr = .{ .comptime_ = .{ .loc = loc, .kind = .{ .comptimeExpr = s } } };
        _ = try infer.inferExprTyped(self.env, node);
        if (self.env.srcRewrites.get(loc)) |v| return v;
        self.env.lastError = TypeError.custom(
            try std.fmt.allocPrint(self.env.arena, "{s}: `{s}` is not computed at build{s}", .{ diagnostics.run_in_build, try exprText(self.env.arena, e.*), try self.where(e.getLoc()) }),
            "A function whose every parameter is `comptime` is expanded where it is called (decision 562).",
        ).withLoc(self.at(e.getLoc()));
        return error.TypeError;
    }

    fn evalInt(self: *Expander, e: *const ast.Expr) InferError!i64 {
        const v = try self.evalBuild(e);
        var n = v;
        if (n.* == .collection and n.collection.kind == .grouped) n = n.collection.kind.grouped;
        var neg = false;
        if (n.* == .unaryOp and n.unaryOp.op == .neg) {
            neg = true;
            n = n.unaryOp.expr;
        }
        if (n.* == .literal and n.literal.kind == .numberLit) {
            var digits: std.ArrayListUnmanaged(u8) = .empty;
            for (n.literal.kind.numberLit) |ch| {
                if (ch == '_') continue;
                if (!std.ascii.isDigit(ch)) break;
                try digits.append(self.env.arena, ch);
            }
            const i = std.fmt.parseInt(i64, digits.items, 10) catch 0;
            return if (neg) -i else i;
        }
        _ = try self.unsupported(e.getLoc(), "a range is iterated at build over integers");
        unreachable;
    }

    fn copyBody(self: *Expander, e: *const ast.Expr) InferError!*const ast.Expr {
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = false };
        const s = try self.env.arena.create(ast.Expr);
        s.* = try cp.copy(ast.Expr, e.*);
        return s;
    }

    // ── what reaches the run time ────────────────────────────────────────

    /// The first run-time value `e` reaches, widened over the member reads
    /// and calls written on it (`d.value.make()`), or null when `e` is
    /// computed from build data alone.
    fn runRead(self: *Expander, e: *const ast.Expr) ?RunRead {
        return self.runReadOrErr(e) catch null;
    }

    fn runReadOrErr(self: *Expander, e: *const ast.Expr) InferError!?RunRead {
        switch (e.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    const b = self.lookup(n) orelse return null;
                    return if (b == .runtime) .{ .loc = id.loc, .text = n } else null;
                },
                .identAccess => |ia| {
                    if (try self.runReadOrErr(ia.receiver)) |_| return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) };
                    // A catalogue entry's `value` is the declaration itself:
                    // never read at build (356).
                    if (std.mem.eql(u8, ia.member, "value") and self.isEntry(ia.receiver)) return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) };
                    return null;
                },
                .dotIdent => return null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.receiver) |r| if (try self.runReadOrErr(r)) |_| return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) };
                    for (cc.args) |a| if (try self.runReadOrErr(a.value)) |rr| return rr;
                    for (cc.trailing) |tl| for (tl.body) |*s| if (try self.runReadOrErr(&s.expr)) |rr| return rr;
                    if (cc.is_builtin) {
                        if (std.mem.eql(u8, cc.callee, ast.is_builtin_name)) return null;
                        return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) };
                    }
                    // A method of build data (a string, an array, a record) is
                    // computed as written.
                    if (cc.receiver) |r| if (!self.rootUnbound(r)) return null;
                    // A function of the program, std or a host: computed at
                    // build when `Any` (380); anything else runs with the program.
                    var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = false };
                    const copied = try cp.copy(ast.Expr, e.*);
                    if (copied == .call and infer.callFoldable(self.env, copied.call)) return null;
                    return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) };
                },
                .pipeline => return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) },
            },
            .binaryOp => |b| return (try self.runReadOrErr(b.lhs)) orelse try self.runReadOrErr(b.rhs),
            .unaryOp => |u| return self.runReadOrErr(u.expr),
            .literal => |l| switch (l.kind) {
                .stringTemplate => |t| {
                    for (t.parts) |p| switch (p) {
                        .text => {},
                        .expr => |h| if (try self.runReadOrErr(h)) |rr| return rr,
                    };
                    return null;
                },
                else => return null,
            },
            .collection => |col| switch (col.kind) {
                .grouped => |g| return self.runReadOrErr(g),
                .arrayLit => |al| {
                    for (al.elems) |*el| if (try self.runReadOrErr(el)) |rr| return rr;
                    if (al.spreadExpr) |se| return self.runReadOrErr(se);
                    if (al.spread) |sp| if (sp.len > 0) if (self.lookup(sp)) |b| if (b == .runtime) return .{ .loc = e.getLoc(), .text = sp };
                    return null;
                },
                .tupleLit => |tl| {
                    for (tl.elems) |*el| if (try self.runReadOrErr(el)) |rr| return rr;
                    return null;
                },
                .range => |r| {
                    if (try self.runReadOrErr(r.start)) |rr| return rr;
                    if (r.end) |end| return self.runReadOrErr(end);
                    return null;
                },
                .case => |cs| {
                    for (cs.subjects) |*s| if (try self.runReadOrErr(s)) |rr| return rr;
                    for (cs.arms) |*arm| if (try self.runReadOrErr(&arm.body)) |rr| return rr;
                    return null;
                },
                .behaviorLit => |bl| {
                    for (bl.fields) |f| if (try self.runReadOrErr(f.value)) |rr| return rr;
                    return null;
                },
            },
            .function => |f| {
                const mark = self.shadows.items.len;
                defer self.shadows.shrinkRetainingCapacity(mark);
                try self.shadowLambda(f.kind.params, f.kind.body);
                for (f.kind.body) |*s| if (try self.runReadOrErr(&s.expr)) |rr| return rr;
                return null;
            },
            .branch => |br| switch (br.kind) {
                .if_ => |iff| {
                    if (try self.runReadOrErr(iff.cond)) |rr| return rr;
                    for (iff.then_) |*s| if (try self.runReadOrErr(&s.expr)) |rr| return rr;
                    if (iff.else_) |els| for (els) |*s| if (try self.runReadOrErr(&s.expr)) |rr| return rr;
                    return null;
                },
                .tryCatch => return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) },
            },
            .binding => |b| switch (b.kind) {
                .localBind => |lb| return self.runReadOrErr(lb.value),
                .localBindDestruct => |lb| return self.runReadOrErr(lb.value),
                .assign => return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) },
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| return if (r) |v| self.runReadOrErr(v) else null,
                .@"break", .@"continue", .yield => return null,
                else => return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) },
            },
            .comptime_ => return null,
            .loop, .useHook => return .{ .loc = e.getLoc(), .text = try exprText(self.env.arena, e.*) },
        }
    }

    /// Whether `r`, a member read's receiver, is a catalogue entry
    /// (`Declared(…)`) known at build.
    fn isEntry(self: *Expander, r: *const ast.Expr) bool {
        if (r.* != .identifier or r.identifier.kind != .ident) return false;
        const b = self.lookup(r.identifier.kind.ident) orelse return false;
        if (b != .build) return false;
        var v = b.build;
        if (v.* == .collection and v.collection.kind == .grouped) v = v.collection.kind.grouped;
        return v.* == .call and v.call.kind == .call and std.mem.eql(u8, v.call.kind.call.callee, "Declared");
    }

    /// Whether the chain of member reads `r` starts at a name the expansion
    /// does not bind — a namespace, a type, a function of the program: a
    /// call on it is no method of build data.
    fn rootUnbound(self: *Expander, r: *const ast.Expr) bool {
        var cur = r;
        while (true) switch (cur.*) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| return self.lookup(n) == null and !self.shadowed(n),
                .identAccess => |ia| cur = ia.receiver,
                .dotIdent => return true,
            },
            else => return false,
        };
    }

    fn shadowLambda(self: *Expander, params: []const []const u8, body: []const ast.Stmt) InferError!void {
        for (params) |p| try self.shadows.append(self.env.arena, p);
        for (body) |s| if (s.expr == .binding) switch (s.expr.binding.kind) {
            .localBind => |lb| try self.shadows.append(self.env.arena, lb.name),
            .localBindDestruct => |lb| try destructNames(self.env.arena, lb.pattern, &self.shadows),
            .assign => {},
        };
    }
};

/// A copy of a node of the body (`body`) or of the caller (an argument, a
/// value computed at build), every location moved into the expansion `exp`.
/// A body node's names are rewritten: a parameter's `.value` and a name
/// bound at build to their values, a member of a record known at build to
/// the field's value, a name of another declaring module to its alias, and
/// — `eval`, for a value computed at build — a constant `val` of this module
/// to its initializer.
const Copier = struct {
    x: *Expander,
    exp: u32,
    body: bool,
    eval: bool,
    depth: usize = 0,

    fn copy(self: *Copier, comptime N: type, v: N) InferError!N {
        if (N == ast.Loc) return .{ .line = v.line, .col = v.col, .expansion = self.exp };
        if (N == ast.Expr) if (try self.rewrite(v)) |r| return r;
        return self.copyPlain(N, v);
    }

    fn copyPlain(self: *Copier, comptime N: type, v: N) InferError!N {
        switch (@typeInfo(N)) {
            .@"struct" => |st| {
                var out: N = v;
                inline for (st.fields) |f| {
                    if (f.is_comptime) continue;
                    @field(out, f.name) = try self.copy(f.type, @field(v, f.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| return @unionInit(N, @tagName(tag), try self.copy(@TypeOf(payload), payload)),
                }
            },
            .optional => |o| return if (v) |inner| try self.copy(o.child, inner) else null,
            .pointer => |pi| switch (pi.size) {
                .one => {
                    if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") return v;
                    const p = try self.x.env.arena.create(pi.child);
                    p.* = try self.copy(pi.child, v.*);
                    return p;
                },
                .slice => {
                    if (pi.child == u8) return v;
                    const out = try self.x.env.arena.alloc(pi.child, v.len);
                    for (v, 0..) |e, i| out[i] = try self.copy(pi.child, e);
                    return out;
                },
                else => return v,
            },
            else => return v,
        }
    }

    /// A value of the caller copied into the expansion: its names are the
    /// caller's, left as written.
    fn caller(self: *Copier, e: *const ast.Expr) InferError!ast.Expr {
        var cp: Copier = .{ .x = self.x, .exp = self.exp, .body = false, .eval = self.eval, .depth = self.depth };
        return cp.copy(ast.Expr, e.*);
    }

    fn rewrite(self: *Copier, e: ast.Expr) InferError!?ast.Expr {
        const x = self.x;
        switch (e) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| {
                    if (self.body) if (x.lookup(n)) |b| switch (b) {
                        .param => |a| return try self.caller(a.value),
                        .build => |v| return try self.caller(v),
                        .runtime => return null,
                    };
                    if (self.body and x.shadowed(n)) return null;
                    // A constant of the module the value is computed in.
                    if (self.eval and self.depth < 32 and (!self.body or !x.foreign)) if (moduleConst(x.env, n)) |init| {
                        var cp: Copier = .{ .x = x, .exp = self.exp, .body = false, .eval = true, .depth = self.depth + 1 };
                        return try cp.copy(ast.Expr, init.*);
                    };
                    if (self.body and x.foreign) if (try aliasOf(x, n)) |alias| {
                        return .{ .identifier = .{ .loc = try self.copy(ast.Loc, id.loc), .kind = .{ .ident = alias } } };
                    };
                    return null;
                },
                .identAccess => |ia| {
                    if (self.body and std.mem.eql(u8, ia.member, "value") and ia.receiver.* == .identifier and ia.receiver.identifier.kind == .ident) {
                        if (x.lookup(ia.receiver.identifier.kind.ident)) |b| if (b == .param) return try self.caller(b.param.value);
                    }
                    var out = try self.copyPlain(ast.Expr, e);
                    if (fieldOf(out.identifier.kind.identAccess.receiver, ia.member)) |field| out = field.*;
                    return out;
                },
                .dotIdent => return null,
            },
            // A function of the declaring module called by name, reached
            // here under its alias.
            .call => |c| if (self.body and x.foreign and c.kind == .call) {
                const cc = c.kind.call;
                if (cc.receiver != null or cc.is_builtin or cc.calleeExpr != null or cc.callee.len == 0) return null;
                if (x.lookup(cc.callee) != null or x.shadowed(cc.callee)) return null;
                const alias = (try aliasOf(x, cc.callee)) orelse return null;
                var out = try self.copyPlain(ast.Expr, e);
                out.call.kind.call.callee = alias;
                return out;
            } else return null,
            .function => |f| {
                if (!self.body) return null;
                const mark = x.shadows.items.len;
                defer x.shadows.shrinkRetainingCapacity(mark);
                try x.shadowLambda(f.kind.params, f.kind.body);
                return try self.copyPlain(ast.Expr, e);
            },
            else => return null,
        }
    }
};

/// The initializer of the non-`var` module-level `val` `name` of the module
/// being compiled, when no local shadows it.
fn moduleConst(env: *Env, name: []const u8) ?*const ast.Expr {
    if (env.localBindDepth(name) != null) return null;
    for (env.moduleDecls) |d| switch (d) {
        .val => |v| if (std.mem.eql(u8, v.name, name)) return if (v.mutable) null else v.value,
        else => {},
    };
    return null;
}

/// The alias the caller reaches the name `name` of the declaring module
/// under (decision 112): one of its functions or values, or one it imports.
fn aliasOf(x: *Expander, name: []const u8) InferError!?[]const u8 {
    const r = x.env.reflection orelse return null;
    const w = (try r.written(x.env.arena, x.owner, name)) orelse return null;
    if (w.isType) return null;
    const alias = (try writtenNames.bindValue(x.env, w.module, w.name)) orelse return null;
    // A function expanded at its call site, reached under its alias.
    if (x.env.reflection) |_| if (x.env.templateImports.get(alias)) |_| {
        if (try expandedDeclOf(x.env, w.module, w.name)) |decl| try x.env.expandedImports.put(x.env.arena, try aliasKey(x.env.arena, w.module, w.name), .{ .decl = decl, .owner = w.module });
    };
    return alias;
}

/// The declaration of `module`'s function `name` when it is expanded at its
/// call site and the caller imports it.
fn expandedDeclOf(env: *Env, module: []const u8, name: []const u8) InferError!?ast.FnDecl {
    var it = env.expandedImports.iterator();
    while (it.next()) |e| if (std.mem.eql(u8, e.value_ptr.owner, module) and std.mem.eql(u8, e.value_ptr.decl.name, name)) return e.value_ptr.decl;
    return null;
}

/// The value of the field `member` of the record `r` writes, when `r` is a
/// constructor call that labels it.
fn fieldOf(r: *const ast.Expr, member: []const u8) ?*const ast.Expr {
    var v = r;
    if (v.* == .collection and v.collection.kind == .grouped) v = v.collection.kind.grouped;
    if (v.* != .call or v.call.kind != .call) return null;
    const call = v.call.kind.call;
    if (call.is_builtin or call.callee.len == 0 or !std.ascii.isUpper(call.callee[0])) return null;
    for (call.args) |a| if (a.label) |l| if (std.mem.eql(u8, l, member)) return a.value;
    return null;
}

/// Whether `stmts` bind a name (a scope must hold them).
fn declares(stmts: []const ast.Stmt) bool {
    for (stmts) |st| if (st.expr == .binding and st.expr.binding.kind != .assign) return true;
    return false;
}

/// Whether `e` is written as data already: a literal, a name, a lambda, an
/// array, a tuple or a record of data.
fn isData(e: ast.Expr) bool {
    return switch (e) {
        .literal => |l| l.kind != .stringTemplate,
        .identifier => |id| id.kind == .ident or id.kind == .dotIdent,
        .function => true,
        .unaryOp => |u| u.op == .neg and u.expr.* == .literal,
        .collection => |c| switch (c.kind) {
            .grouped => |g| isData(g.*),
            .arrayLit => |al| al.spread == null and al.spreadExpr == null and for (al.elems) |el| {
                if (!isData(el)) break false;
            } else true,
            .tupleLit => |tl| for (tl.elems) |el| {
                if (!isData(el)) break false;
            } else true,
            else => false,
        },
        .call => |c| switch (c.kind) {
            .call => |cc| !cc.is_builtin and cc.callee.len > 0 and std.ascii.isUpper(cc.callee[0]) and cc.trailing.len == 0 and for (cc.args) |a| {
                if (!isData(a.value.*)) break false;
            } else true,
            else => false,
        },
        else => false,
    };
}

fn isTrue(e: ast.Expr) bool {
    var v = e;
    while (v == .collection and v.collection.kind == .grouped) v = v.collection.kind.grouped.*;
    return v == .identifier and v.identifier.kind == .ident and std.mem.eql(u8, v.identifier.kind.ident, "true");
}

fn isNull(e: ast.Expr) bool {
    return e == .literal and e.literal.kind == .null_;
}

fn arrayOf(e: *const ast.Expr) ?[]const ast.Expr {
    var v = e;
    while (v.* == .collection and v.collection.kind == .grouped) v = v.collection.kind.grouped;
    if (v.* != .collection or v.collection.kind != .arrayLit) return null;
    const al = v.collection.kind.arrayLit;
    if (al.spread != null or al.spreadExpr != null) return null;
    return al.elems;
}

/// The names a destructuring binds; a list or a constructor pattern binds
/// none the expansion reads at build (their names stay as written).
fn destructNames(arena: std.mem.Allocator, pattern: ast.ParamDestruct, out: *std.ArrayListUnmanaged([]const u8)) InferError!void {
    switch (pattern) {
        .names => |n| for (n.fields) |f| try out.append(arena, f.bind_name),
        .tuple_ => |t| for (t) |name| try out.append(arena, name),
        .list, .ctor => {},
    }
}

fn exprText(arena: std.mem.Allocator, e: ast.Expr) InferError![]const u8 {
    var f = formatMod.Formatter.init(arena);
    const doc = f.fmtExpr(e) catch return error.OutOfMemory;
    return formatMod.render(arena, doc, std.math.maxInt(u16)) catch return error.OutOfMemory;
}
