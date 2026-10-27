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
const Lexer = @import("../lexer.zig").Lexer;
const Parser = @import("../parser.zig").Parser;
const reflectionMod = @import("reflection.zig");
const modTree = @import("mod_tree.zig");
const Frame = @import("error.zig").Frame;
const compilerSurface = @import("../parser/compiler_surface.zig");
const comptime_blocks = @import("../parser/comptime_blocks.zig");
const memberFn = @import("member_fn.zig");
const loadMod = @import("load.zig");

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
    if (c.kind != .call) return null;
    const call = c.kind.call;
    if (call.is_builtin or call.calleeExpr != null or call.trailing.len > 0) return null;
    if (env.comptimeDepth > 0 or env.inDecoratorFn or env.inTemplateFn) {
        // Decision 808 (3) — a function that writes `compiler.init`, called
        // from a body that runs at build and is no top-level `comptime`
        // block: its executor has no place there.
        if (try targetOf(env, call)) |t| if (writesInit(env, t.decl, 0)) return refuseInitAtBuild(env, t.decl.name, loc);
        return null;
    }
    const target = (try targetOf(env, call)) orelse return null;
    const key = @intFromPtr(target.decl.body.ptr);
    if (env.expanding.contains(key)) return null;
    const args = (try argsOf(env, target.decl, call.args, loc)) orelse return null;

    try env.expanding.put(env.arena, key, {});
    defer _ = env.expanding.remove(key);
    // Decision 564 — the code an expansion emits may call a behavior's
    // function on a catalogue entry's `value`.
    const savedInExpansion = env.inExpansion;
    env.inExpansion = true;
    defer env.inExpansion = savedInExpansion;
    const savedInExpandedFnDecl = env.inExpandedFnDecl;
    env.inExpandedFnDecl = false;
    defer env.inExpandedFnDecl = savedInExpandedFnDecl;

    var x: Expander = .{
        .env = env,
        .owner = target.owner,
        .foreign = !std.mem.eql(u8, target.owner, env.modulePath),
        .call_loc = loc,
        .first_exp = env.expansionCount,
    };
    return expandWith(&x, target.decl, args, loc, expected) catch |err| {
        if (err == error.TypeError) try x.locateInOwner();
        return err;
    };
}

/// Decision 808 (3) — the call of `name`, a function that writes
/// `compiler.init`, from a decorator's or a template's body or a `comptime`
/// that answers a value.
fn refuseInitAtBuild(env: *Env, name: []const u8, loc: ast.Loc) InferError {
    const where: []const u8 = if (env.inDecoratorFn) "a decorator's body" else if (env.inTemplateFn) "a template's body" else "this `comptime`, which answers a value,";
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` writes `compiler.init`, and {s} runs at build with no place for its executor", .{ diagnostics.compiler_output_outside_decorator, name, where });
    env.lastError = TypeError.custom(msg, "A function whose every parameter is `comptime` is expanded wherever it is called (decision 808): call it from a run-time body, from a `comptime { … }` written as a statement, or from a top-level `comptime { … }`; a decorator registers its own executor with `compiler.init` (decision 575 (3)).").withLoc(loc);
    return error.TypeError;
}

/// Decision 808 — whether `f`'s body writes `compiler.init`
/// (`compiler_surface.init_here_builtin`), itself or through a call of
/// another function expanded at its call site this module reaches.
pub fn writesInit(env: *Env, f: ast.FnDecl, depth: usize) bool {
    if (depth > 16) return false;
    var w: InitWalk = .{ .arena = env.arena };
    w.walk([]const ast.Stmt, f.body);
    if (w.found) return true;
    for (w.callees.items) |cc| {
        const t = (targetOf(env, cc) catch null) orelse continue;
        if (@intFromPtr(t.decl.body.ptr) == @intFromPtr(f.body.ptr)) continue;
        if (writesInit(env, t.decl, depth + 1)) return true;
    }
    return false;
}

/// Finds `init_here_builtin` in a body and keeps the calls by name it holds.
const CallData = @FieldType(@FieldType(ast.CallExprOf(.untyped), "kind"), "call");

const InitWalk = struct {
    arena: std.mem.Allocator,
    found: bool = false,
    callees: std.ArrayListUnmanaged(CallData) = .empty,

    fn walk(self: *InitWalk, comptime N: type, v: N) void {
        if (self.found) return;
        if (N == ast.Expr) if (v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (c.is_builtin and std.mem.eql(u8, c.callee, compilerSurface.init_here_builtin)) {
                self.found = true;
                return;
            }
            if (!c.is_builtin and c.calleeExpr == null) self.callees.append(self.arena, c) catch {};
        };
        if (N == ast.ImportDecl or N == ast.TypeRef or N == ast.Pattern or N == ast.Loc) return;
        switch (@typeInfo(N)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (!f.is_comptime) self.walk(f.type, @field(v, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (v) {
                inline else => |payload| self.walk(@TypeOf(payload), payload),
            },
            .optional => |o| if (v) |inner| self.walk(o.child, inner),
            .pointer => |pi| switch (pi.size) {
                .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") self.walk(pi.child, v.*),
                .slice => if (pi.child != u8) for (v) |e| self.walk(pi.child, e),
                else => {},
            },
            else => {},
        }
    }
};

/// Decision 998 (1) — notes each `m.run()` / `` m.`test`() `` an
/// executor's body holds (`Env.initHereRuns`), the body written out of the
/// executor into the body the call stands in. A lambda inside is not walked:
/// `run()` written there is refused where it stands, as in any executor.
const RunMark = struct {
    env: *Env,
    failed: bool = false,

    fn walk(self: *RunMark, comptime N: type, v: N) void {
        if (N == ast.Expr) if (v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (c.receiver != null and !c.is_builtin and c.args.len == 0 and
                (std.mem.eql(u8, c.callee, "run") or std.mem.eql(u8, c.callee, loadMod.test_method)))
            {
                self.env.initHereRuns.put(self.env.arena, v.call.loc, {}) catch {
                    self.failed = true;
                };
            }
        };
        if (N == ast.Expr) if (v == .function) return;
        if (N == ast.ImportDecl or N == ast.TypeRef or N == ast.Pattern or N == ast.Loc) return;
        switch (@typeInfo(N)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (!f.is_comptime) self.walk(f.type, @field(v, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (v) {
                inline else => |payload| self.walk(@TypeOf(payload), payload),
            },
            .optional => |o| if (v) |inner| self.walk(o.child, inner),
            .pointer => |pi| switch (pi.size) {
                .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") self.walk(pi.child, v.*),
                .slice => if (pi.child != u8) for (v) |e| self.walk(pi.child, e),
                else => {},
            },
            else => {},
        }
    }
};

/// Decision 808 (4) — a `comptime { … }` written as a statement of a
/// run-time body that calls a function writing `compiler.init`: its lines
/// run at build, each one as a `comptime` of it, the functions it calls
/// expanded at build alike, and the body of each executor they reach is
/// written where the block is, run each time the enclosing function runs.
/// Null for any other block (one that answers a value included).
pub fn expandComptimeBlock(env: *Env, body: []const ast.Stmt, loc: ast.Loc) InferError!?ast.TypedExpr {
    if (env.templateEval == null) return null;
    if (env.comptimeDepth > 0 or env.inDecoratorFn or env.inTemplateFn) return null;
    var reaches = false;
    for (body) |st| {
        const e = st.expr;
        if (e == .jump and e.jump.kind == .@"break" and e.jump.kind.@"break".value != null) return null;
        if (e != .call or e.call.kind != .call) continue;
        const cc = e.call.kind.call;
        if (cc.is_builtin or cc.calleeExpr != null or cc.trailing.len > 0) continue;
        const t = (try targetOf(env, cc)) orelse continue;
        if (writesInit(env, t.decl, 0)) reaches = true;
    }
    if (!reaches) return null;
    var x: Expander = .{
        .env = env,
        .owner = env.modulePath,
        .foreign = false,
        .call_loc = loc,
        .first_exp = env.expansionCount,
        .build_mode = true,
    };
    var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;
    _ = try x.walk(body, &out);
    const expansion = try env.arena.create(ast.Expr);
    expansion.* = exprsMod.makeBlockExpr(env.arena, .{ .line = loc.line, .col = loc.col, .expansion = try x.callerFresh() }, out.items) catch return error.OutOfMemory;
    _ = try infer.inferExprTyped(env, expansion.*);
    try env.srcRewrites.put(loc, expansion);
    return .{ .comptime_ = .{ .loc = loc, .type_ = try env.namedType("void"), .kind = .{ .comptimeBlock = .{ .body = &.{} } } } };
}

/// Decision 793 (3) — `program` with each statement-level call, in a
/// top-level `comptime { … }` block (the decorator `parser/comptime_blocks.zig`
/// reads it onto), of a function of another module that writes
/// `compiler.init` replaced by a block of the function's body: each
/// parameter read its argument, each name of the declaring module its alias
/// (`Copier`), and each `compiler.init(f)` the block's own executor
/// (`<handle>.compile(f)`), so it joins the block's init at its anchor. Run
/// after the imports resolve and before inference (a block's decorator runs
/// before its body is checked); the module's own functions the parser
/// expanded already.
pub fn expandBlockCalls(env: *Env, program: ast.Program) InferError!ast.Program {
    if (env.expandedImports.count() == 0) return program;
    var decls: ?[]ast.DeclKind = null;
    for (program.decls, 0..) |d, i| {
        if (d != .@"fn") continue;
        const f = d.@"fn";
        if (!std.mem.startsWith(u8, f.name, comptime_blocks.decorator_prefix) or f.params.len == 0) continue;
        const handle = f.params[0].name;
        if (!std.mem.eql(u8, handle, comptime_blocks.handle_name)) continue;
        const body = (try blockCalls(env, f.body, handle, 0)) orelse continue;
        if (decls == null) decls = try env.arena.dupe(ast.DeclKind, program.decls);
        var nf = f;
        nf.body = body;
        decls.?[i] = .{ .@"fn" = nf };
    }
    return if (decls) |ds| .{ .decls = ds, .blankLineBefore = program.blankLineBefore } else program;
}

/// `stmts` with each call `expandBlockCalls` expands replaced; null when none
/// is one.
fn blockCalls(env: *Env, stmts: []ast.Stmt, handle: []const u8, depth: usize) InferError!?[]ast.Stmt {
    if (depth > 16) return null;
    var out: ?[]ast.Stmt = null;
    for (stmts, 0..) |st, i| {
        const replaced: ?ast.Expr = blk: {
            if (st.deferred) break :blk null;
            const e = st.expr;
            if (e != .call or e.call.kind != .call) {
                // A block the parser expanded a function of the module into.
                if (blockBodyOf(e)) |inner| if (try blockCalls(env, inner, handle, depth + 1)) |nb| {
                    break :blk exprsMod.makeBlockExpr(env.arena, e.getLoc(), nb) catch return error.OutOfMemory;
                };
                break :blk null;
            }
            const cc = e.call.kind.call;
            if (cc.is_builtin or cc.calleeExpr != null or cc.trailing.len > 0) break :blk null;
            const target = (try targetOf(env, cc)) orelse break :blk null;
            if (std.mem.eql(u8, target.owner, env.modulePath)) break :blk null;
            if (!writesInit(env, target.decl, 0)) break :blk null;
            const key = @intFromPtr(target.decl.body.ptr);
            if (env.expanding.contains(key)) break :blk null;
            const args = (try argsOf(env, target.decl, cc.args, e.call.loc)) orelse break :blk null;
            try env.expanding.put(env.arena, key, {});
            defer _ = env.expanding.remove(key);
            var x: Expander = .{ .env = env, .owner = target.owner, .foreign = true, .call_loc = e.call.loc, .first_exp = env.expansionCount };
            for (target.decl.params, args) |p, a| try x.bindings.append(env.arena, .{ .name = p.name, .bound = .{ .param = a } });
            var cp: Copier = .{ .x = &x, .exp = x.fresh(), .body = true, .eval = false };
            var copied = try cp.copy([]const ast.Stmt, target.decl.body);
            const mutable = try env.arena.dupe(ast.Stmt, copied);
            for (mutable) |*s| {
                s.tail = .none;
                try compileOnHandle(env.arena, ast.Expr, &s.expr, handle);
            }
            copied = mutable;
            const body = (try blockCalls(env, mutable, handle, depth + 1)) orelse mutable;
            break :blk exprsMod.makeBlockExpr(env.arena, e.call.loc, body) catch return error.OutOfMemory;
        };
        if (replaced) |r| {
            if (out == null) out = try env.arena.dupe(ast.Stmt, stmts);
            out.?[i].expr = r;
        }
    }
    return out;
}

/// The statements of a block written as an expression (`case true { _ { … } }`).
fn blockBodyOf(e: ast.Expr) ?[]ast.Stmt {
    if (e != .collection or e.collection.kind != .case) return null;
    const cs = e.collection.kind.case;
    if (!cs.isBlock or cs.arms.len != 1 or cs.arms[0].body != .function) return null;
    return cs.arms[0].body.function.kind.body;
}

/// Every `init_here_builtin(f)` under `p` rewritten `<handle>.compile(f)`:
/// the executor of the block the body was copied into (decision 615).
fn compileOnHandle(arena: std.mem.Allocator, comptime N: type, p: *N, handle: []const u8) InferError!void {
    if (N == ast.Expr) if (p.* == .call and p.call.kind == .call) {
        const c = &p.call.kind.call;
        if (c.is_builtin and std.mem.eql(u8, c.callee, compilerSurface.init_here_builtin)) {
            const r = try arena.create(ast.Expr);
            r.* = .{ .identifier = .{ .loc = p.call.loc, .kind = .{ .ident = handle } } };
            c.is_builtin = false;
            c.receiver = r;
            c.callee = memberFn.compile_name;
            return;
        }
    };
    if (N == ast.ImportDecl or N == ast.TypeRef or N == ast.Pattern or N == ast.Loc) return;
    switch (@typeInfo(N)) {
        .@"struct" => |st| inline for (st.fields) |f| {
            if (!f.is_comptime) try compileOnHandle(arena, f.type, &@field(p.*, f.name), handle);
        },
        .@"union" => |u| if (u.tag_type != null) switch (p.*) {
            inline else => |*payload| try compileOnHandle(arena, @TypeOf(payload.*), payload, handle),
        },
        .optional => |o| if (p.*) |*inner| try compileOnHandle(arena, o.child, inner, handle),
        .pointer => |pi| switch (pi.size) {
            .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") try compileOnHandle(arena, pi.child, @constCast(p.*), handle),
            .slice => if (pi.child != u8) for (@constCast(p.*)) |*e| try compileOnHandle(arena, pi.child, e, handle),
            else => {},
        },
        else => {},
    }
}

fn expandWith(x: *Expander, decl: ast.FnDecl, args: []const Arg, loc: ast.Loc, expected: ?*T.Type) InferError!?ast.TypedExpr {
    const env = x.env;
    for (decl.params, args) |p, a| try x.bindings.append(env.arena, .{ .name = p.name, .bound = .{ .param = a } });
    var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;
    _ = try x.walk(decl.body, &out);

    const expansion = try env.arena.create(ast.Expr);
    if (out.items.len == 0 and x.tail != null) {
        expansion.* = x.tail.?.*;
    } else if (out.items.len == 1 and x.tail == null and !declares(out.items)) {
        expansion.* = out.items[0].expr;
    } else {
        if (x.tail) |t| try out.append(env.arena, .{ .expr = t.*, .tail = .value });
        expansion.* = exprsMod.makeBlockExpr(env.arena, .{ .line = loc.line, .col = loc.col, .expansion = try x.callerFresh() }, out.items) catch return error.OutOfMemory;
    }
    const saved = env.expectedType;
    env.expectedType = expected;
    defer env.expectedType = saved;
    const typed = try infer.inferExprTyped(env, expansion.*);
    try env.templateExpansions.put(loc, expansion);
    try env.noteExpansionOrigin(loc, decl);
    return typed;
}

/// Decision 562 — the imports the code of each function expanded here from
/// another module needs, read before this module is inferred: every type and
/// every namespace its body names, as its own module resolves them
/// (`Reflection.scopes`), imported under an alias no source writes — a type
/// under `written_names.typeAliasOf` (a private one too: the module shares
/// its privates), a namespace under `namespaceAlias`. The copies of the body
/// name them by those aliases (`Copier`). A type of a name this module
/// already holds from elsewhere is left out: naming it is refused at the call
/// (`aliasOf`). Each import is the checker's and every backend's, as written.
pub fn importsFor(env: *Env, decls: []const ast.DeclKind, own_package: []const u8) InferError![]ast.DeclKind {
    const r = env.reflection orelse return &.{};
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var bound: std.StringHashMapUnmanaged(void) = .empty;
    for (decls) |d| if (d == .use) for (d.use.imports) |imp| try bound.put(env.arena, imp.name(), {});
    var seen: std.AutoHashMapUnmanaged(usize, void) = .empty;
    var it = env.expandedImports.valueIterator();
    while (it.next()) |imp| {
        if (std.mem.eql(u8, imp.owner, env.modulePath)) continue;
        if ((try seen.getOrPut(env.arena, @intFromPtr(imp.decl.body.ptr))).found_existing) continue;
        var names: Names = .{ .arena = env.arena };
        try names.walk([]const ast.Stmt, imp.decl.body);
        for (names.list.items) |n| {
            const w = (try r.written(env.arena, imp.owner, n)) orelse continue;
            const parsed = (try importOf(env, decls, imp.owner, n, w, own_package)) orelse continue;
            const alias = parsed.use.imports[0].name();
            if ((try bound.getOrPut(env.arena, alias)).found_existing) continue;
            try out.append(env.arena, parsed);
        }
    }
    return out.items;
}

/// The import that binds, in the module of `decls`, the name `n` a body of
/// `owner` writes (`w`, as `owner`'s scope resolves it) under its alias: a
/// namespace under `namespaceAlias`, a type under `written_names.typeAliasOf`.
/// Null for a value (bound by `written_names.bindValue`) and for a type this
/// module holds from elsewhere. Decision 757's copies of an imported body
/// (`token_import.zig`) are bound the same way.
pub fn importOf(env: *Env, decls: []const ast.DeclKind, owner: []const u8, n: []const u8, w: reflectionMod.WrittenName, own_package: []const u8) InferError!?ast.DeclKind {
    const r = env.reflection orelse return null;
    const text = switch (w.namespace) {
        .std => try std.fmt.allocPrint(env.arena, "import {{{s} as {s}}} from \"std\";", .{ try dotted(env.arena, w.module), try namespaceAlias(env.arena, owner, n) }),
        .module => blk: {
            // A module of this package is named by its path in it, one
            // of another package through that package (decision 337).
            const pkg = packageOf(r, w.module);
            const local = try dotted(env.arena, modTree.localPath(pkg, w.module));
            const alias = try namespaceAlias(env.arena, owner, n);
            break :blk if (std.mem.eql(u8, pkg, own_package))
                try std.fmt.allocPrint(env.arena, "import {{{s} as {s}}};", .{ local, alias })
            else
                try std.fmt.allocPrint(env.arena, "import {{{s} as {s}}} from \"{s}\";", .{ local, alias, pkg });
        },
        .stdLeaf => return null,
        .none => if (w.isType and !typeHeldElsewhere(env, decls, w.module, w.name))
            try std.fmt.allocPrint(env.arena, "import {{{s} as {s}}} from \"{s}\";", .{ w.name, try writtenNames.typeAliasOf(env.arena, w.module, w.name), w.module })
        else
            return null,
    };
    return parseImport(env.arena, text);
}

/// The alias a namespace `name` of `module` is imported under where a
/// function of `module` is expanded.
pub fn namespaceAlias(arena: std.mem.Allocator, module: []const u8, name: []const u8) ![]const u8 {
    return envMod.templateAlias(arena, module, name);
}

/// The package `module` belongs to: the session's module tree's answer, else
/// its first segment when it has more than one (a dependency's module is
/// loaded as `<lib>/<stem>`).
fn packageOf(r: *const reflectionMod.Reflection, module: []const u8) []const u8 {
    if (r.modTree) |t| if (t.entries.get(module)) |e| return e.package;
    if (std.mem.indexOfScalar(u8, module, '/')) |i| return module[0..i];
    return "";
}

fn dotted(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    const out = try arena.dupe(u8, path);
    std.mem.replaceScalar(u8, out, '/', '.');
    return out;
}

fn parseImport(arena: std.mem.Allocator, text: []const u8) InferError!?ast.DeclKind {
    var lx = Lexer.init(text);
    const tokens = lx.scanAll(arena) catch return null;
    var p = Parser.init(tokens);
    const parsed = p.parse(arena) catch return null;
    if (parsed.decls.len != 1 or parsed.decls[0] != .use) return null;
    return parsed.decls[0];
}

/// Whether this module holds a type named `name` other than `module`'s:
/// declared in `decls`, or imported from another module.
fn typeHeldElsewhere(env: *const Env, decls: []const ast.DeclKind, module: []const u8, name: []const u8) bool {
    for (decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, name)) return true,
        .typeAlias => |a| if (std.mem.eql(u8, a.name, name)) return true,
        else => {},
    };
    return writtenNames.typeNameTaken(env, module, name);
}

/// Every name a body writes: a name read, a function called by name, a type
/// named — what `importsFor` asks the declaring module's scope about.
const Names = struct {
    arena: std.mem.Allocator,
    list: std.ArrayListUnmanaged([]const u8) = .empty,
    set: std.StringHashMapUnmanaged(void) = .empty,

    fn add(self: *Names, n: []const u8) InferError!void {
        if (n.len == 0 or (try self.set.getOrPut(self.arena, n)).found_existing) return;
        try self.list.append(self.arena, n);
    }

    fn walk(self: *Names, comptime N: type, v: N) InferError!void {
        if (N == ast.Expr) switch (v) {
            .identifier => |id| if (id.kind == .ident) try self.add(id.kind.ident),
            .call => |c| if (c.kind == .call) {
                const cc = c.kind.call;
                if (cc.receiver == null and !cc.is_builtin and cc.calleeExpr == null) try self.add(cc.callee);
            },
            else => {},
        };
        if (N == ast.TypeRef) switch (v) {
            .named => |n| try self.add(n),
            .generic => |g| if (!g.is_builtin) try self.add(g.name),
            else => {},
        };
        switch (@typeInfo(N)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (!f.is_comptime) try self.walk(f.type, @field(v, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            .optional => |o| if (v) |inner| try self.walk(o.child, inner),
            .pointer => |pi| switch (pi.size) {
                .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") try self.walk(pi.child, v.*),
                .slice => if (pi.child != u8) for (v) |e| try self.walk(pi.child, e),
                else => {},
            },
            else => {},
        }
    }
};

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
    /// The expansions the caller's own nodes (an argument, a value computed
    /// at build) were copied into; every other one this expansion opened
    /// holds a copy of the body.
    caller_exps: std.AutoHashMapUnmanaged(u32, void) = .empty,
    /// Decision 695 — where each caller's node copied into the expansion is
    /// written in the caller: by the expansion its copy took.
    caller_origin: std.AutoHashMapUnmanaged(u32, ast.Loc) = .empty,
    /// Decision 695 — a copied call of the body whose receiver is a caller's
    /// node (`value.toUpper()`, `value` the argument `7`): the call's location
    /// in the expansion, and the argument's in the caller. A refusal of that
    /// call is the argument's.
    blame: std.AutoHashMapUnmanaged(ast.Loc, ast.Loc) = .empty,
    /// The expansions this one opened: `(first, last]`.
    first_exp: u32 = 0,
    /// Decision 808 (4) — every line runs at build (a `comptime { … }`
    /// statement and the functions it expands): only an executor's body is
    /// written into the program.
    build_mode: bool = false,

    fn fresh(self: *Expander) u32 {
        self.env.expansionCount += 1;
        return self.env.expansionCount;
    }

    /// A fresh expansion for a node located at the call.
    fn callerFresh(self: *Expander) InferError!u32 {
        const exp = self.fresh();
        try self.caller_exps.put(self.env.arena, exp, {});
        return exp;
    }

    /// A refusal raised while the body of a function of another module is
    /// expanded or its code typed, located in a copy of that body: located
    /// in the declaring module's file, where it is written (decision 532's
    /// `origin`), and the call it was expanded at named (`called from`). A
    /// refusal already located in another file (a nested expansion's, a raise
    /// at build) is left as it is.
    fn locateInOwner(self: *Expander) InferError!void {
        var e = self.env.lastError orelse return;
        if (e.origin != null) return;
        const l = e.loc orelse return;
        // Decision 695 — the value at fault is the caller's argument, written
        // in the caller's file: the refusal is located there.
        if (self.blame.get(l)) |argLoc| {
            e.loc = argLoc;
            self.env.lastError = e;
            return;
        }
        if (!self.foreign) return;
        if (l.expansion <= self.first_exp or l.expansion > self.env.expansionCount or self.caller_exps.contains(l.expansion)) return;
        const frames = try self.env.arena.alloc(Frame, 1);
        frames[0] = .{ .file = self.env.srcPathOf(self.env.modulePath), .loc = self.call_loc };
        e.origin = .{ .file = self.env.diagLabelOf(self.owner), .loc = .{ .line = l.line, .col = l.col } };
        e.loc = self.call_loc;
        e.frames = frames;
        self.env.lastError = e;
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
            if (self.build_mode) return self.unsupported(st.expr.getLoc(), "a `defer` has no place in a `comptime` that writes an executor");
            try self.emit(st, out);
            return .normal;
        }
        const e = &st.expr;
        if (e.* == .call and e.call.kind == .call) {
            const cc = e.call.kind.call;
            // Decision 808 (2), (4) — `compiler.init(f)`: `f`'s body written
            // here, run when this line runs.
            if (cc.is_builtin and std.mem.eql(u8, cc.callee, compilerSurface.init_here_builtin)) {
                try self.initHere(cc, out);
                return .normal;
            }
            if (self.build_mode) if (try self.expandAtBuild(e.call, out)) return .normal;
        }
        if (try self.handledReturn(st, out)) |flow| return flow;
        switch (e.*) {
            .literal => |l| if (l.kind == .comment) return .normal,
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    if (self.build_mode) {
                        if (lb.mutable or lb.typeAnnotation != null) return self.unsupported(e.getLoc(), "a `comptime` that writes an executor binds its values with a plain `val`");
                        const v = try self.evalBuild(lb.value);
                        try self.bindings.append(self.env.arena, .{ .name = lb.name, .bound = .{ .build = v } });
                        return .normal;
                    }
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
                    if (self.build_mode) return self.unsupported(e.getLoc(), "a `comptime` that writes an executor binds its values with a plain `val`");
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
        if (self.build_mode) {
            try self.runBuild(st);
            return .normal;
        }
        try self.emit(st, out);
        return .normal;
    }

    /// Decision 808 (2), (4) — the body of the executor `compiler.init(f)`
    /// hands, written where the line is: a block of its own when it binds a
    /// name.
    ///
    /// Decision 998 (2) — an `async` executor's statements are written as
    /// they are inside its brace, its `await`s the enclosing body's: only at
    /// a run-time call inside an `async` body; in a body that is not `async`
    /// and in 808 (4)'s block (`build_mode`) it is refused at the `async`.
    fn initHere(self: *Expander, cc: anytype, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!void {
        if (cc.args.len != 1 or cc.args[0].value.* != .function) return;
        const f = cc.args[0].value.function;
        var body: []const ast.Stmt = f.kind.body;
        if (f.kind.marker == .task) {
            const awaits = if (self.env.starFn) |sf| sf.allowsAwait else false;
            if (self.build_mode or !awaits) return infer.refuseAsyncExecutor(self.env, f.loc);
            body = ast.asyncLambdaBody(f) orelse body;
        }
        var inner: std.ArrayListUnmanaged(ast.Stmt) = .empty;
        for (body) |*s| {
            if (s.expr == .literal and s.expr.literal.kind == .comment) continue;
            // A lambda's tail answers nothing here.
            var one = s.*;
            if (one.tail == .returned and one.expr == .jump and one.expr.jump.kind == .@"return") if (one.expr.jump.kind.@"return") |v| {
                one.expr = v.*;
            };
            try self.emit(&one, &inner);
        }
        var runs: RunMark = .{ .env = self.env };
        runs.walk([]const ast.Stmt, inner.items);
        if (runs.failed) return error.OutOfMemory;
        if (!declares(inner.items)) {
            try out.appendSlice(self.env.arena, inner.items);
            return;
        }
        const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = try self.callerFresh() };
        const blk = exprsMod.makeBlockExpr(self.env.arena, loc, inner.items) catch return error.OutOfMemory;
        try out.append(self.env.arena, .{ .expr = blk });
    }

    /// Decisions 789 (4), 998 (5) — `[val x =] try e catch { r -> …; return; }`
    /// with `e` known at build (`try comptime compiler.load(…)`): its branch
    /// taken here, as a top-level block's is (`parser/comptime_blocks.zig`
    /// `liftCatchReturns`) — on `Ok` the value bound to `x` and the
    /// statements after it walked, on `Error` the handler's statements, `r`
    /// bound to the error, and the expansion ended. Null for any other line.
    fn handledReturn(self: *Expander, st: *const ast.Stmt, out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!?Flow {
        var name: ?[]const u8 = null;
        var e = &st.expr;
        if (e.* == .binding and e.binding.kind == .localBind) {
            const lb = e.binding.kind.localBind;
            if (lb.mutable or lb.typeAnnotation != null) return null;
            name = lb.name;
            e = lb.value;
        }
        if (e.* != .branch or e.branch.kind != .tryCatch) return null;
        const tc = e.branch.kind.tryCatch;
        if (tc.region) return null;
        const handler = blockBodyOf(tc.handler.*) orelse return null;
        if (handler.len == 0) return null;
        const last = handler[handler.len - 1].expr;
        if (last != .jump or last.jump.kind != .@"return" or last.jump.kind.@"return" != null) return null;
        if (self.runRead(tc.expr) != null) return null;
        const side: enum { ok, err }, const payload = blk: {
            if (try self.loadAtBuild(tc.expr)) |answered| {
                if (answered.refused) |refused| break :blk .{ .err, refused };
                break :blk .{ .ok, answered.module };
            }
            var v = try self.evalBuild(tc.expr);
            while (v.* == .collection and v.collection.kind == .grouped) v = v.collection.kind.grouped;
            if (v.* == .call and v.call.kind == .call) {
                const cc = v.call.kind.call;
                if (cc.receiver == null and !cc.is_builtin and cc.args.len == 1) {
                    if (std.mem.eql(u8, cc.callee, "Ok")) break :blk .{ .ok, cc.args[0].value };
                    if (std.mem.eql(u8, cc.callee, "Error")) break :blk .{ .err, cc.args[0].value };
                }
            }
            _ = try self.unsupported(tc.expr.getLoc(), "a handled read that returns takes its branch at build over a `Result` known there");
            unreachable;
        };
        switch (side) {
            .ok => {
                if (name) |n| try self.bindings.append(self.env.arena, .{ .name = n, .bound = .{ .build = payload } });
                return .normal;
            },
            .err => {
                const mark = self.bindings.items.len;
                defer self.bindings.shrinkRetainingCapacity(mark);
                if (tc.binder) |b| try self.bindings.append(self.env.arena, .{ .name = b, .bound = .{ .build = payload } });
                const flow = try self.block(handler[0 .. handler.len - 1], out);
                return if (flow == .normal) .ret else flow;
            },
        }
    }

    const LoadAnswer = struct { module: *const ast.Expr, refused: ?*const ast.Expr };

    /// Decision 998 (6) — `compiler.load(path)` read in the body, its path
    /// folded here (`"cases/" + name`, `name` a `comptime` parameter) and
    /// answered at build as anywhere else (`infer.zig` `inferLoadBuiltin`):
    /// the `Module` written as `__bp_load_module(…)` — what an executor
    /// captures (`load.recordSource`) — and, refused, the `Refused` record
    /// over it. Null when `e` is no such call.
    fn loadAtBuild(self: *Expander, e: *const ast.Expr) InferError!?LoadAnswer {
        var c = e;
        while (true) switch (c.*) {
            .collection => |col| if (col.kind == .grouped) {
                c = col.kind.grouped;
            } else break,
            .comptime_ => |ct| if (ct.kind == .comptimeExpr) {
                c = ct.kind.comptimeExpr;
            } else break,
            else => break,
        };
        if (c.* != .call or c.call.kind != .call) return null;
        const cc = c.call.kind.call;
        if (!cc.is_builtin or !std.mem.eql(u8, cc.callee, compilerSurface.load_builtin)) return null;
        var cp: Copier = .{ .x = self, .exp = try self.callerFresh(), .body = true, .eval = true };
        const copied = try cp.copy(ast.Expr, c.*);
        _ = try infer.inferExprTyped(self.env, copied);
        const rw = self.env.srcRewrites.get(copied.getLoc()) orelse return null;
        var r = rw;
        while (r.* == .collection and r.collection.kind == .grouped) r = r.collection.kind.grouped;
        if (r.* != .call or r.call.kind != .call) return null;
        const answer = r.call.kind.call;
        if (!std.mem.eql(u8, answer.callee, loadMod.helper_fn) or answer.args.len != 2) return null;
        const module = answer.args[0].value;
        const ds = answer.args[1].value;
        const empty = ds.* == .collection and ds.collection.kind == .arrayLit and ds.collection.kind.arrayLit.elems.len == 0;
        if (empty) return .{ .module = module, .refused = null };
        const args = try self.env.arena.alloc(ast.CallArg, 2);
        args[0] = .{ .label = "module", .value = module };
        args[1] = .{ .label = "diagnostics", .value = ds };
        const refused = try self.env.arena.create(ast.Expr);
        refused.* = .{ .call = .{ .loc = copied.getLoc(), .kind = .{ .call = .{
            .receiver = null,
            .callee = loadMod.refused_alias,
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
        } } } };
        return .{ .module = module, .refused = refused };
    }

    /// Decision 808 (4) — a line of a build-mode expansion, run at build as
    /// a `comptime { <line> }` of it (its prints the build's output).
    fn runBuild(self: *Expander, st: *const ast.Stmt) InferError!void {
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = false };
        var copied = try cp.copy(ast.Stmt, st.*);
        copied.tail = .none;
        const body = try self.env.arena.alloc(ast.Stmt, 1);
        body[0] = copied;
        const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = try self.callerFresh() };
        const node: ast.Expr = .{ .comptime_ = .{ .loc = loc, .kind = .{ .comptimeBlock = .{ .body = body } } } };
        _ = try infer.inferExprTyped(self.env, node);
    }

    /// Decision 808 (4) — a call, in a build-mode expansion, of a function
    /// that writes `compiler.init`: expanded here at build, its executors'
    /// bodies written into `out`. False for any other call.
    fn expandAtBuild(self: *Expander, c: ast.CallExprOf(.untyped), out: *std.ArrayListUnmanaged(ast.Stmt)) InferError!bool {
        const written = c.kind.call;
        if (written.is_builtin or written.calleeExpr != null or written.trailing.len > 0) return false;
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = false };
        const copied = try cp.copy(ast.Expr, .{ .call = c });
        if (copied != .call or copied.call.kind != .call) return false;
        const call = copied.call.kind.call;
        const target = (try targetOf(self.env, call)) orelse return false;
        if (!writesInit(self.env, target.decl, 0)) return false;
        const key = @intFromPtr(target.decl.body.ptr);
        if (self.env.expanding.contains(key)) return false;
        const site = self.at(c.loc);
        const args = (try argsOf(self.env, target.decl, call.args, site)) orelse return false;
        try self.env.expanding.put(self.env.arena, key, {});
        defer _ = self.env.expanding.remove(key);
        var x: Expander = .{
            .env = self.env,
            .owner = target.owner,
            .foreign = !std.mem.eql(u8, target.owner, self.env.modulePath),
            .call_loc = site,
            .first_exp = self.env.expansionCount,
            .build_mode = true,
        };
        for (target.decl.params, args) |p, a| try x.bindings.append(self.env.arena, .{ .name = p.name, .bound = .{ .param = a } });
        _ = x.walk(target.decl.body, out) catch |err| {
            if (err == error.TypeError) try x.locateInOwner();
            return err;
        };
        return true;
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
            const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = try self.callerFresh() };
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
        return std.fmt.allocPrint(self.env.arena, " (at {s}:{d}:{d}, in the function expanded here)", .{ self.env.diagLabelOf(self.owner), loc.line, loc.col });
    }

    // ── values at build ──────────────────────────────────────────────────

    /// The value of `e`, known at build: written as data when it already is
    /// one, else computed as a `comptime` of it (`infer.foldBodyComptime`).
    fn evalBuild(self: *Expander, e: *const ast.Expr) InferError!*const ast.Expr {
        var cp: Copier = .{ .x = self, .exp = self.fresh(), .body = true, .eval = true };
        const s = try self.env.arena.create(ast.Expr);
        s.* = try cp.copy(ast.Expr, e.*);
        if (isData(s.*)) return s;
        if (moduleGetter(s)) |v| return v;
        const loc: ast.Loc = .{ .line = self.call_loc.line, .col = self.call_loc.col, .expansion = try self.callerFresh() };
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
                        // Decision 998 (6) — `compiler.load(path)` is answered at
                        // build, its path folded here (`"cases/" + name`).
                        if (std.mem.eql(u8, cc.callee, compilerSurface.load_builtin)) return null;
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
        if (N == ast.Expr) {
            const out = (try self.rewrite(v)) orelse try self.copyPlain(N, v);
            try self.noteBlame(out);
            return out;
        }
        if (N == ast.TypeRef) if (try self.rewriteType(v)) |r| return r;
        return self.copyPlain(N, v);
    }

    /// A type of the declaring module the body names, by the alias the
    /// caller holds it under.
    fn rewriteType(self: *Copier, t: ast.TypeRef) InferError!?ast.TypeRef {
        if (!self.body or !self.x.foreign) return null;
        const name = switch (t) {
            .named => |n| n,
            .generic => |g| if (g.is_builtin) return null else g.name,
            else => return null,
        };
        const r = self.x.env.reflection orelse return null;
        const w = (try r.written(self.x.env.arena, self.x.owner, name)) orelse return null;
        if (!w.isType or w.namespace != .none) return null;
        const alias = (try typeAliasIn(self.x, w)) orelse return null;
        var out = try self.copyPlain(ast.TypeRef, t);
        switch (out) {
            .named => out = .{ .named = alias },
            .generic => |*g| g.name = alias,
            else => {},
        }
        return out;
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

    /// Decision 695 — a method call of the body on a caller's node: a
    /// refusal of the call is located at that node, where the caller wrote it.
    fn noteBlame(self: *Copier, e: ast.Expr) InferError!void {
        if (!self.body or e != .call or e.call.kind != .call) return;
        const recv = e.call.kind.call.receiver orelse return;
        const argLoc = self.x.caller_origin.get(recv.getLoc().expansion) orelse return;
        try self.x.blame.put(self.x.env.arena, e.call.loc, argLoc);
    }

    /// A value of the caller copied into the expansion: its names are the
    /// caller's, left as written.
    fn caller(self: *Copier, e: *const ast.Expr) InferError!ast.Expr {
        // An expansion of its own: a refusal located in it is the caller's.
        const exp = self.x.fresh();
        try self.x.caller_exps.put(self.x.env.arena, exp, {});
        try self.x.caller_origin.put(self.x.env.arena, exp, e.getLoc());
        var cp: Copier = .{ .x = self.x, .exp = exp, .body = false, .eval = self.eval, .depth = self.depth };
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
    // A namespace or a type `importsFor` imported under its alias.
    if (w.namespace != .none) {
        const alias = try namespaceAlias(x.env.arena, x.owner, name);
        return if (x.env.stdImports.contains(alias) or x.env.namespaces.paths.contains(alias)) alias else null;
    }
    if (w.isType) return typeAliasIn(x, w);
    const alias = (try writtenNames.bindValue(x.env, w.module, w.name)) orelse return null;
    // A function expanded at its call site, reached under its alias.
    if (x.env.reflection) |_| if (x.env.templateImports.get(alias)) |_| {
        if (try expandedDeclOf(x.env, w.module, w.name)) |decl| try x.env.expandedImports.put(x.env.arena, try aliasKey(x.env.arena, w.module, w.name), .{ .decl = decl, .owner = w.module });
    };
    return alias;
}

/// The name the caller holds the declaring module's type `w` under: the alias
/// `importsFor` imported it as, or decision 310's alias of a contested name.
/// A type of that name the caller holds from elsewhere is refused at the call:
/// one module holds one type of a name.
fn typeAliasIn(x: *Expander, w: reflectionMod.WrittenName) InferError!?[]const u8 {
    if (writtenNames.renamedAliasOf(x.env, w.module, w.name)) |al| return al;
    const alias = try writtenNames.typeAliasOf(x.env.arena, w.module, w.name);
    if (x.env.importedTypeDecls.contains(alias)) return alias;
    const msg = try std.fmt.allocPrint(x.env.arena, "{s}: the function expanded here names `{s}`'s type `{s}`, and this module holds another type declared `{s}`; a type is told apart by its declared name, so one module holds one type of a name", .{ diagnostics.import_name_collision, w.module, w.name, w.name });
    x.env.lastError = TypeError.custom(msg, "Rename this module's own type, or call the function from a module that holds no other type of that name (decisions 310, 562).").withLoc(x.call_loc);
    return error.TypeError;
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

/// Decision 998 (4) — a getter of a `Module` known at build
/// (`loaded.mainAsync()`, `loaded` bound to `__bp_load_module(…)`): the
/// field the constructor writes, under any `comptime` and parentheses.
fn moduleGetter(e: *const ast.Expr) ?*const ast.Expr {
    var v = e;
    while (true) switch (v.*) {
        .collection => |col| if (col.kind == .grouped) {
            v = col.kind.grouped;
        } else break,
        .comptime_ => |ct| if (ct.kind == .comptimeExpr) {
            v = ct.kind.comptimeExpr;
        } else break,
        else => break,
    };
    if (v.* != .call or v.call.kind != .call) return null;
    const cc = v.call.kind.call;
    if (cc.args.len != 0 or cc.trailing.len != 0 or cc.is_builtin) return null;
    var r = cc.receiver orelse return null;
    while (r.* == .collection and r.collection.kind == .grouped) r = r.collection.kind.grouped;
    if (r.* != .call or r.call.kind != .call) return null;
    const ctor = r.call.kind.call;
    if (ctor.receiver != null or ctor.is_builtin or !std.mem.eql(u8, ctor.callee, loadMod.module_fn)) return null;
    for (ctor.args) |a| if (a.label) |l| if (std.mem.eql(u8, l, cc.callee)) return a.value;
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
pub fn destructNames(arena: std.mem.Allocator, pattern: ast.ParamDestruct, out: *std.ArrayListUnmanaged([]const u8)) InferError!void {
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
