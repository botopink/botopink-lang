//! Decision 788 — a top-level `comptime { … }` is a build body of its module,
//! run once per build in the order written, after the module's declarations
//! are known. It runs on the machinery every build body already runs on — a
//! decorator's (`comptime/decorator_eval.zig`, the wasm comptime runtime):
//! `Parser.parse` reads each block, before `syntax_params.zig` and
//! `compiler_surface.zig`, onto
//!
//!     fn __bp_comptime_<k>(syntax __bp_ct_decl: unknown) { <the block> }
//!     #[__bp_comptime_<k>] val __bp_comptime_<k>_at = 0;
//!
//! so `compiler.*`, `val`s known at build, `print` and every call are what a
//! decorator body makes of them; each `compiler.init` is the decorator's
//! executor, which joins the program's init list at the anchor's place (575
//! (3), 580) — the blocks of a module in the order written, the modules in
//! their build order (615). The anchor is a `val` the program never reads.
//!
//! **Expansion at the call (139, 562).** A function of the module whose every
//! parameter is `comptime` and whose body writes `compiler.init` (itself or
//! through another such function) is expanded where a block calls it as a
//! statement: the call becomes a block of the function's body, each parameter
//! read replaced by its argument, so the executor stands in the build body as
//! if written there. A body that may leave early (`return`, `throw`, a
//! propagating `try`) or declares a name one of its parameters has is not
//! expanded. A private function every call of which was expanded leaves the
//! program (562: an expanded function has no run-time body); any other keeps
//! its body, where a `compiler.init` is refused as before.
//!
//! **A handled read that returns (789 (4)).** A statement of the body
//! `[val x =] try e catch { r -> …; return; }` — its handler ending with a
//! bare `return`, leaving nowhere else — is read, before the check above, as
//! `case e { Ok(x) -> { <the statements after it> } Error(r) -> { <the
//! handler without its return> } }` (`liftCatchReturns`): what `return` left
//! is what the other arm holds, so the body leaves nothing early and is
//! expanded. `e` is a `comptime compiler.load(…)` the block's body answers
//! at build, so the branch is taken at build.

const std = @import("std");
const ast = @import("../ast.zig");
const Parser = @import("../parser.zig").Parser;
const Lexer = @import("../lexer.zig").Lexer;
const exprs = @import("exprs.zig");
const compiler_surface = @import("compiler_surface.zig");
const diagnostics = @import("../comptime/diagnostics.zig");

/// The name of the handle a block's decorator takes; no source writes it.
pub const handle_name = "__bp_ct_decl";
/// The prefix of a block's decorator (`__bp_comptime_<k>`) and of its anchor
/// (`__bp_comptime_<k>_at`).
pub const decorator_prefix = "__bp_comptime_";

/// How deep expansions nest inside one block.
const max_depth = 16;

const Error = error{ OutOfMemory, UnexpectedToken, ExpectedToken, InvalidCharacter } || anyerror;

/// Every top-level `comptime { … }` of `program` read onto its decorator and
/// anchor (see the file comment); a program with none is left untouched.
pub fn expandProgram(alloc: std.mem.Allocator, program: *ast.Program) !void {
    var any = false;
    for (program.decls) |d| if (d == .comptimeBlock) {
        any = true;
        break;
    };
    if (!any) return;

    var x: Expander = .{ .alloc = alloc, .program = program.*, .compiler = compiler_surface.boundCompilerName(program.*) };
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blanks: std.ArrayListUnmanaged(bool) = .empty;
    const keepBlanks = program.blankLineBefore.len == program.decls.len;
    var k: usize = 0;
    for (program.decls, 0..) |d, i| {
        const blank = keepBlanks and program.blankLineBefore[i];
        if (d != .comptimeBlock) {
            try decls.append(alloc, d);
            if (keepBlanks) try blanks.append(alloc, blank);
            continue;
        }
        const block = d.comptimeBlock;
        const pair = try x.lower(block, k);
        k += 1;
        try decls.append(alloc, .{ .@"fn" = pair.decorator });
        try decls.append(alloc, .{ .val = pair.anchor });
        if (keepBlanks) {
            try blanks.append(alloc, blank);
            try blanks.append(alloc, false);
        }
    }

    // A private function every call of which was expanded leaves the program.
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var outBlanks: std.ArrayListUnmanaged(bool) = .empty;
    for (decls.items, 0..) |d, i| {
        if (d == .@"fn" and !d.@"fn".isPub and x.expanded.contains(d.@"fn".name) and !referenced(decls.items, i, d.@"fn".name)) continue;
        try out.append(alloc, d);
        if (keepBlanks) try outBlanks.append(alloc, blanks.items[i]);
    }
    program.decls = try out.toOwnedSlice(alloc);
    if (keepBlanks) program.blankLineBefore = try outBlanks.toOwnedSlice(alloc);
}

const Pair = struct { decorator: ast.FnDecl, anchor: ast.ValDecl };

const Expander = struct {
    alloc: std.mem.Allocator,
    program: ast.Program,
    /// The name the module binds std's `compiler` to, null when it imports none.
    compiler: ?[]const u8,
    /// The functions an expansion copied, by name.
    expanded: std.StringHashMapUnmanaged(void) = .empty,
    /// The functions being expanded now (a recursive call is left a call).
    stack: std.ArrayListUnmanaged([]const u8) = .empty,

    fn lower(x: *Expander, block: ast.ComptimeBlockDecl, k: usize) Error!Pair {
        const name = try std.fmt.allocPrint(x.alloc, "{s}{d}", .{ decorator_prefix, k });
        const text = try std.fmt.allocPrint(x.alloc, "fn {s}(syntax {s}: unknown) -> void {{}}\n#[{s}]\nval {s}_at = 0;\n", .{ name, handle_name, name, name });
        var lx = Lexer.init(text);
        const tokens = try lx.scanAll(x.alloc);
        var p = Parser.init(tokens);
        const parsed = try p.parseRawDecls(x.alloc);
        var decorator = parsed.decls[0].@"fn";
        var anchor = parsed.decls[1].val;
        // Every diagnostic of the body's run points at `comptime`.
        decorator.startLoc = block.loc;
        decorator.nameLoc = block.loc;
        for (decorator.params) |*prm| {
            prm.loc = block.loc;
            prm.typeLoc = block.loc;
        }
        for (anchor.annotations) |*a| a.loc = block.loc;
        anchor.nameLoc = block.loc;
        // Decision 793 (1) — a block answers nothing and leaves nothing early:
        // its first `return` or `throw` is refused where it is written, the
        // body read no further.
        for (block.body) |s| if (ast.exprFindReturnOrThrow(s.expr)) |at| {
            const one = try x.alloc.alloc(ast.Stmt, 1);
            one[0] = s;
            one[0].expr = try compiler_surface.refusalExpr(x.alloc, at, diagnostics.comptime_block_exit, "a top-level `comptime` block runs to its end: it answers nothing and leaves nothing early", "A top-level `comptime { … }` is a build body of its module (decisions 788, 793 (1)): drop the `return` or `throw`, or write the condition around what follows it.");
            decorator.body = one;
            return .{ .decorator = decorator, .anchor = anchor };
        };
        decorator.body = try x.expandStmts(block.body, 0);
        return .{ .decorator = decorator, .anchor = anchor };
    }

    /// `stmts` with each statement-level call of a function expanded at the
    /// call replaced by the block of its body (and the bodies those hold).
    fn expandStmts(x: *Expander, stmts: []ast.Stmt, depth: usize) Error![]ast.Stmt {
        const out = try x.alloc.alloc(ast.Stmt, stmts.len);
        for (stmts, 0..) |s, i| {
            out[i] = s;
            if (depth < max_depth) if (try x.expandCall(s.expr, depth)) |e| {
                out[i].expr = e;
            };
        }
        return out;
    }

    fn expandCall(x: *Expander, e: ast.Expr, depth: usize) Error!?ast.Expr {
        if (e != .call or e.call.kind != .call) return null;
        const c = e.call.kind.call;
        if (c.receiver != null or c.calleeExpr != null or c.is_builtin or c.trailing.len > 0) return null;
        const f = (try x.target(c.callee)) orelse return null;
        for (x.stack.items) |n| if (std.mem.eql(u8, n, f.name)) return null;
        const args = (try argsOf(x.alloc, f, c.args)) orelse return null;
        const copied = try substitute([]ast.Stmt, x.alloc, f.body, f.params, args);
        try x.stack.append(x.alloc, f.name);
        defer _ = x.stack.pop();
        const body = try x.expandStmts(copied, depth + 1);
        try x.expanded.put(x.alloc, f.name, {});
        return try exprs.makeBlockExpr(x.alloc, e.call.loc, body);
    }

    /// The function of the module `name` calls, when a block expands it:
    /// its body with each handled read that returns lifted
    /// (`liftCatchReturns`).
    fn target(x: *Expander, name: []const u8) Error!?ast.FnDecl {
        for (x.program.decls) |d| if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, name)) {
            var f = d.@"fn";
            if (try liftCatchReturns(x.alloc, f.body)) |body| f.body = body;
            if (!expandable(f)) return null;
            if (!x.writesInit(f, 0)) return null;
            return f;
        };
        return null;
    }

    /// Whether `f`'s body writes `compiler.init`, itself or through a
    /// statement-level call of another function a block expands.
    fn writesInit(x: *Expander, f: ast.FnDecl, depth: usize) bool {
        if (depth > max_depth) return false;
        const n = x.compiler orelse return false;
        var w: InitWalk = .{ .compiler = n };
        for (f.body) |s| w.walk(ast.Expr, s.expr);
        if (w.found) return true;
        for (f.body) |s| {
            if (s.expr != .call or s.expr.call.kind != .call) continue;
            const c = s.expr.call.kind.call;
            if (c.receiver != null or c.calleeExpr != null or c.is_builtin) continue;
            if (std.mem.eql(u8, c.callee, f.name)) continue;
            for (x.program.decls) |d| if (d == .@"fn" and std.mem.eql(u8, d.@"fn".name, c.callee) and expandable(d.@"fn")) {
                if (x.writesInit(d.@"fn", depth + 1)) return true;
            };
        }
        return false;
    }
};

/// Decision 789 (4) — `stmts` with its first statement `[val x =] try e
/// catch { r -> …; return; }` (operand form, the handler a block ending with
/// a bare `return` and leaving nowhere else) read as `case e { Ok(x) -> {
/// <the statements after it, lifted too> } Error(r) -> { <the handler
/// without its return> } }`; null when no statement is one.
fn liftCatchReturns(alloc: std.mem.Allocator, stmts: []ast.Stmt) Error!?[]ast.Stmt {
    for (stmts, 0..) |s, i| {
        if (s.deferred) continue;
        var name: ?[]const u8 = null;
        var e = s.expr;
        if (e == .binding and e.binding.kind == .localBind) {
            const lb = e.binding.kind.localBind;
            if (lb.mutable or lb.typeAnnotation != null) continue;
            name = lb.name;
            e = lb.value.*;
        }
        if (e != .branch or e.branch.kind != .tryCatch) continue;
        const tc = e.branch.kind.tryCatch;
        if (tc.region) continue;
        const handler = blockBody(tc.handler.*) orelse continue;
        if (handler.len == 0) continue;
        const last = handler[handler.len - 1].expr;
        if (last != .jump or last.jump.kind != .@"return" or last.jump.kind.@"return" != null) continue;
        const kept = handler[0 .. handler.len - 1];
        const leaves = for (kept) |h| {
            if (ast.exprMayExitEarly(h.expr)) break true;
        } else false;
        if (leaves) continue;

        const rest = stmts[i + 1 ..];
        const after = (try liftCatchReturns(alloc, rest)) orelse rest;
        const text = try std.fmt.allocPrint(alloc, "fn __bp_lift() -> void {{ case __bp_lift {{ Ok({s}) -> {{ 0 }} Error({s}) -> {{ 0 }} }} }}\n", .{ name orelse "_", tc.binder orelse "_" });
        var lx = Lexer.init(text);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const parsed = try p.parseRawDecls(alloc);
        var lifted = parsed.decls[0].@"fn".body[0].expr;
        const cs = &lifted.collection.kind.case;
        lifted.collection.loc = e.getLoc();
        cs.subjects[0] = tc.expr.*;
        const loc = e.getLoc();
        for (cs.arms, [_][]ast.Stmt{ after, kept }) |*arm, body| {
            arm.patternLoc = loc;
            arm.body = .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = &.{}, .body = body } } };
        }
        const out = try alloc.alloc(ast.Stmt, i + 1);
        @memcpy(out[0..i], stmts[0..i]);
        out[i] = .{ .expr = lifted };
        return out;
    }
    return null;
}

/// The statements of a block written as an expression (`exprs.makeBlockExpr`:
/// `case true { _ { … } }`), null for any other expression.
fn blockBody(e: ast.Expr) ?[]ast.Stmt {
    if (e != .collection or e.collection.kind != .case) return null;
    const cs = e.collection.kind.case;
    if (!cs.isBlock or cs.arms.len != 1 or cs.arms[0].body != .function) return null;
    return cs.arms[0].body.function.kind.body;
}

/// Whether `f` is expanded where a block calls it: a function with a body,
/// every parameter `comptime` (at least one), that never leaves early and
/// declares none of its parameters' names.
fn expandable(f: ast.FnDecl) bool {
    if (f.isDeclare or f.params.len == 0 or f.genericParams.len > 0) return false;
    for (f.params) |p| if (p.modifier != .@"comptime" or p.arrival != .value or p.variadic) return false;
    for (f.body) |s| if (ast.exprMayExitEarly(s.expr)) return false;
    var w: DeclaredWalk = .{ .params = f.params };
    for (f.body) |s| w.walk(ast.Expr, s.expr);
    return !w.found;
}

/// Each parameter's argument at the call: by label, then in order, then the
/// default; null when one has none.
fn argsOf(alloc: std.mem.Allocator, f: ast.FnDecl, written: []const ast.CallArg) Error!?[]const ast.Expr {
    const out = try alloc.alloc(?ast.Expr, f.params.len);
    @memset(out, null);
    var next: usize = 0;
    for (written) |a| {
        if (a.label) |l| {
            const i = for (f.params, 0..) |p, j| {
                if (std.mem.eql(u8, p.name, l)) break j;
            } else return null;
            out[i] = a.value.*;
        } else {
            while (next < out.len and out[next] != null) next += 1;
            if (next >= out.len) return null;
            out[next] = a.value.*;
            next += 1;
        }
    }
    const done = try alloc.alloc(ast.Expr, f.params.len);
    for (out, 0..) |v, i| done[i] = v orelse (f.params[i].default orelse return null);
    return done;
}

/// A deep copy of `v` with every read of a parameter (`params[i].name` as an
/// identifier) replaced by a copy of `args[i]`. Text is shared.
fn substitute(comptime N: type, alloc: std.mem.Allocator, v: N, params: []const ast.Param, args: []const ast.Expr) Error!N {
    if (N == ast.Expr) if (v == .identifier and v.identifier.kind == .ident) {
        for (params, 0..) |p, i| if (std.mem.eql(u8, p.name, v.identifier.kind.ident)) return substitute(ast.Expr, alloc, args[i], &.{}, &.{});
    };
    switch (@typeInfo(N)) {
        .@"struct" => |st| {
            var out: N = v;
            inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try substitute(f.type, alloc, @field(v, f.name), params, args);
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(N, @tagName(tag), try substitute(@TypeOf(payload), alloc, payload, params, args)),
            }
        },
        .optional => |o| return if (v) |inner| try substitute(o.child, alloc, inner, params, args) else null,
        .pointer => |pi| switch (pi.size) {
            .one => {
                if (@typeInfo(pi.child) == .@"fn" or @typeInfo(pi.child) == .@"opaque") return v;
                const p = try alloc.create(pi.child);
                p.* = try substitute(pi.child, alloc, v.*, params, args);
                return p;
            },
            .slice => {
                if (pi.child == u8) return v;
                const out = try alloc.alloc(pi.child, v.len);
                for (v, 0..) |e, i| out[i] = try substitute(pi.child, alloc, e, params, args);
                return out;
            },
            else => return v,
        },
        else => return v,
    }
}

/// Finds `<compiler>.init(…)` in a body.
const InitWalk = struct {
    compiler: []const u8,
    found: bool = false,

    fn walk(self: *InitWalk, comptime N: type, v: N) void {
        if (self.found) return;
        if (N == ast.Expr) if (v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (!c.is_builtin and std.mem.eql(u8, c.callee, "init")) if (c.receiver) |r| {
                if (r.* == .identifier and r.identifier.kind == .ident and std.mem.eql(u8, r.identifier.kind.ident, self.compiler)) {
                    self.found = true;
                    return;
                }
            };
        };
        walkFields(N, v, self);
    }
};

/// Finds a name a body declares that one of `params` has.
const DeclaredWalk = struct {
    params: []const ast.Param,
    found: bool = false,

    fn isParam(self: *const DeclaredWalk, n: []const u8) bool {
        for (self.params) |p| if (std.mem.eql(u8, p.name, n)) return true;
        return false;
    }

    fn walk(self: *DeclaredWalk, comptime N: type, v: N) void {
        if (self.found) return;
        if (N == ast.Expr) switch (v) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| if (self.isParam(lb.name)) {
                    self.found = true;
                },
                else => {},
            },
            .loop => |lp| for (lp.params) |n| if (self.isParam(n)) {
                self.found = true;
            },
            .function => |f| for (f.kind.params) |n| if (self.isParam(n)) {
                self.found = true;
            },
            .call => |c| switch (c.kind) {
                .call => |cc| for (cc.trailing) |tl| for (tl.params) |n| if (self.isParam(n)) {
                    self.found = true;
                },
                else => {},
            },
            else => {},
        };
        if (self.found) return;
        walkFields(N, v, self);
    }
};

/// Whether a declaration other than `skip` (the function itself) reads `name`.
fn referenced(decls: []const ast.DeclKind, skip: usize, name: []const u8) bool {
    var w: NameWalk = .{ .name = name };
    for (decls, 0..) |d, i| {
        if (i == skip) continue;
        w.walk(ast.DeclKind, d);
        if (w.found) return true;
    }
    return false;
}

/// Finds a read of `name`: an identifier, or a call of it.
const NameWalk = struct {
    name: []const u8,
    found: bool = false,

    fn walk(self: *NameWalk, comptime N: type, v: N) void {
        if (self.found) return;
        if (N == ast.Expr) switch (v) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| if (std.mem.eql(u8, n, self.name)) {
                    self.found = true;
                },
                else => {},
            },
            .call => |c| switch (c.kind) {
                .call => |cc| if (!cc.is_builtin and cc.receiver == null and cc.calleeExpr == null and std.mem.eql(u8, cc.callee, self.name)) {
                    self.found = true;
                },
                else => {},
            },
            else => {},
        };
        if (self.found) return;
        walkFields(N, v, self);
    }
};

/// Visit every field of `v` that may hold an expression with `w.walk`.
fn walkFields(comptime N: type, v: N, w: anytype) void {
    if (comptime !mayHoldExpr(N)) return;
    switch (@typeInfo(N)) {
        .@"struct" => |st| inline for (st.fields) |f| {
            if (!f.is_comptime) w.walk(f.type, @field(v, f.name));
        },
        .@"union" => |u| if (u.tag_type != null) switch (v) {
            inline else => |payload| w.walk(@TypeOf(payload), payload),
        },
        .optional => |o| if (v) |inner| w.walk(o.child, inner),
        .pointer => |pi| switch (pi.size) {
            .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") w.walk(pi.child, v.*),
            .slice => for (v) |e| w.walk(pi.child, e),
            else => {},
        },
        else => {},
    }
}

/// Whether a value of `N` can reach an `ast.Expr`: text, locations and type
/// references cannot.
fn mayHoldExpr(comptime N: type) bool {
    return switch (@typeInfo(N)) {
        .@"struct", .@"union" => N != ast.Loc and N != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and @typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque" and mayHoldExpr(pi.child),
        else => false,
    };
}
