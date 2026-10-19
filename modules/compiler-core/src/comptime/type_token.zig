//! Decision 757 — a function or method with a `comptime t: type<T>`
//! parameter is specialised per type argument: a copy per type, `t` the type
//! inside it. Run on the transformed program, after `transform.zig`, from the
//! calls inference recorded (`Env.typeTokenCalls`, `infer.noteTypeTokenArgs`):
//!
//! - a callable whose body reads a token parameter (`v is t`, `t` handed on
//!   as `self.count(t)`, any other read of `t`) is replaced by one copy per
//!   list of type arguments its calls pass, named `<name>__<Type>`: the token
//!   parameters are gone, each `v is t` is `v is Users`, each read of `t` the
//!   type's name, and each call it hands `t` on to is the call of the copy for
//!   the same type — known at build, as decision 417 has it;
//! - a callable whose body reads none (`async.failed(string, "down")`) keeps
//!   one declaration with its token parameters removed: every copy would be
//!   the same;
//! - every recorded call drops its type arguments, and a call of a copied
//!   callable of this module calls the copy.
//!
//! A type token never reaches run time. The copies share the original's
//! nodes' locations, so every rewrite keyed by a location the transform
//! already applied is in them as in the original.

const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const memberFn = @import("member_fn.zig");

/// A callable of this module whose `comptime t: type<T>` parameters
/// specialise it.
const Callable = struct {
    /// The names of its token parameters, in declaration order.
    tokens: []const []const u8,
    /// Per token, the type parameter it binds (`T` of `type<T>`).
    bound: []const []const u8,
    /// Whether its body reads one (then it is copied per type).
    reads: bool,
    /// The declaration's name.
    name: []const u8,
    /// The body as written (after the transform).
    body: []ast.Stmt,
    /// Its copies so far: the mangled name per joined type list.
    copies: std.StringArrayHashMapUnmanaged([]const u8) = .empty,
};

/// A copy still to build: the callable's key and the types, one per token.
const Pending = struct { key: []const u8, types: []const []const u8 };

const Ctx = struct {
    arena: std.mem.Allocator,
    calls: *const std.AutoHashMapUnmanaged(ast.Loc, envMod.TypeTokenCall),
    /// Decision 758 — the `x is t` tests over a run-time token, and the types
    /// written where one is taken (`Env.runtimeTokenTests` / `runtimeTokenArgs`).
    rtTests: *const std.AutoHashMapUnmanaged(ast.Loc, void),
    rtArgs: *const std.AutoHashMapUnmanaged(ast.Loc, void),
    callables: *std.StringArrayHashMapUnmanaged(Callable),
    pending: *std.ArrayListUnmanaged(Pending),
    /// The token parameters of the copy being built, mapped to its types.
    subst: []const []const u8 = &.{},
    substTypes: []const []const u8 = &.{},
    /// The type parameters those tokens bind, each the same type in the copy.
    bound: []const []const u8 = &.{},

    fn substOf(self: *const Ctx, name: []const u8) ?[]const u8 {
        for (self.subst, 0..) |n, i| if (std.mem.eql(u8, n, name)) return self.substTypes[i];
        return null;
    }

    fn boundOf(self: *const Ctx, name: []const u8) ?[]const u8 {
        for (self.bound, 0..) |n, i| if (std.mem.eql(u8, n, name)) return self.substTypes[i];
        return null;
    }
};

/// Whether `p` is a type token: `comptime t: type<T>`.
pub fn isTokenParam(p: ast.Param) bool {
    return p.modifier == .@"comptime" and p.typeRef == .typeparam and p.typeRef.typeparam.len == 1;
}

/// Whether a function's token parameters specialise it: it has a body, and is
/// neither a decorator nor a template (`infer.isTypeTokenCallee`'s rule).
fn fnSpecialises(f: ast.FnDecl) bool {
    if (f.body.len == 0) return false;
    if (memberFn.declParamName(f) != null) return false;
    if (f.returnType) |rt| if (rt.isTemplateReturnType()) return false;
    for (f.params) |p| if (p.arrival == .syntax) return false;
    return true;
}

fn tokensOf(arena: std.mem.Allocator, params: []const ast.Param) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (params) |p| if (isTokenParam(p)) try out.append(arena, p.name);
    return out.toOwnedSlice(arena);
}

fn boundOf(arena: std.mem.Allocator, params: []const ast.Param) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (params) |p| if (isTokenParam(p)) {
        const t = p.typeRef.typeparam[0];
        try out.append(arena, if (t == .named) t.named else "");
    };
    return out.toOwnedSlice(arena);
}

/// `generics` without the ones a copy binds.
fn unbound(arena: std.mem.Allocator, generics: []ast.GenericParam, bound: []const []const u8) ![]ast.GenericParam {
    var out: std.ArrayListUnmanaged(ast.GenericParam) = .empty;
    outer: for (generics) |g| {
        for (bound) |b| if (std.mem.eql(u8, b, g.name)) continue :outer;
        try out.append(arena, g);
    }
    return out.toOwnedSlice(arena);
}

fn withoutTokens(arena: std.mem.Allocator, params: []ast.Param) ![]ast.Param {
    var out: std.ArrayListUnmanaged(ast.Param) = .empty;
    for (params) |p| if (!isTokenParam(p)) try out.append(arena, p);
    return out.toOwnedSlice(arena);
}

/// `program` with every type token specialised away (see the file's doc).
pub fn apply(arena: std.mem.Allocator, program: ast.Program, env: *const envMod.Env) !ast.Program {
    var callables: std.StringArrayHashMapUnmanaged(Callable) = .empty;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| {
            if (!fnSpecialises(f)) continue;
            const tokens = try tokensOf(arena, f.params);
            if (tokens.len == 0) continue;
            try callables.put(arena, f.name, .{ .tokens = tokens, .bound = try boundOf(arena, f.params), .reads = mentionsAny([]ast.Stmt, f.body, tokens), .name = f.name, .body = f.body });
        },
        .type_ => |t| for (t.methods) |m| {
            const body = m.body orelse continue;
            if (m.is_declare) continue;
            const tokens = try tokensOf(arena, m.params);
            if (tokens.len == 0) continue;
            const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ t.name, m.name });
            try callables.put(arena, key, .{ .tokens = tokens, .bound = try boundOf(arena, m.params), .reads = mentionsAny([]ast.Stmt, body, tokens), .name = m.name, .body = body });
        },
        else => {},
    };
    if (callables.count() == 0 and env.typeTokenCalls.count() == 0 and env.runtimeTokenTests.count() == 0 and env.runtimeTokenArgs.count() == 0) return program;

    var pending: std.ArrayListUnmanaged(Pending) = .empty;
    var ctx: Ctx = .{ .arena = arena, .calls = &env.typeTokenCalls, .rtTests = &env.runtimeTokenTests, .rtArgs = &env.runtimeTokenArgs, .callables = &callables, .pending = &pending };

    // Every body as written, the callables that read a token excepted (only
    // their copies run).
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    for (decls) |*d| switch (d.*) {
        .@"fn" => |*f| {
            if (callables.get(f.name)) |c| {
                if (c.reads) continue;
                f.params = try withoutTokens(arena, f.params);
            }
            f.body = try clone([]ast.Stmt, &ctx, f.body);
        },
        .type_ => |*t| {
            const methods = try arena.dupe(ast.BehaviorMethod, t.methods);
            for (methods) |*m| {
                const body = m.body orelse continue;
                const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ t.name, m.name });
                if (callables.get(key)) |c| {
                    if (c.reads) continue;
                    m.params = try withoutTokens(arena, m.params);
                }
                m.body = try clone([]ast.Stmt, &ctx, body);
            }
            t.methods = methods;
        },
        .@"test" => |*t| t.body = try clone([]ast.Stmt, &ctx, t.body),
        .val => |*v| v.value = try clone(*ast.Expr, &ctx, v.value),
        .implement => |*im| {
            const methods = try arena.dupe(@TypeOf(im.methods[0]), im.methods);
            for (methods) |*m| m.body = try clone(@TypeOf(m.body), &ctx, m.body);
            im.methods = methods;
        },
        else => {},
    };

    // The copies the calls asked for, and those their bodies ask for.
    var built: std.StringArrayHashMapUnmanaged(std.ArrayListUnmanaged(Built)) = .empty;
    var i: usize = 0;
    while (i < pending.items.len) : (i += 1) {
        const p = pending.items[i];
        const c = callables.getPtr(p.key).?;
        var inner = ctx;
        inner.subst = c.tokens;
        inner.substTypes = p.types;
        inner.bound = c.bound;
        const body = try clone([]ast.Stmt, &inner, c.body);
        const gop = try built.getOrPut(arena, p.key);
        if (!gop.found_existing) gop.value_ptr.* = .empty;
        try gop.value_ptr.append(arena, .{ .name = c.copies.get(try joined(arena, p.types)).?, .body = body, .ctx = inner });
    }

    // Each callable that reads a token gives way to its copies.
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blanks: std.ArrayListUnmanaged(bool) = .empty;
    for (decls, 0..) |d, di| {
        const blank = if (di < program.blankLineBefore.len) program.blankLineBefore[di] else false;
        switch (d) {
            .@"fn" => |f| if (callables.get(f.name)) |c| if (c.reads) {
                for ((built.get(f.name) orelse std.ArrayListUnmanaged(Built).empty).items) |b| {
                    var bc = b.ctx;
                    var copy = f;
                    copy.name = b.name;
                    copy.params = try clone([]ast.Param, &bc, try withoutTokens(arena, f.params));
                    copy.returnType = try clone(?ast.TypeRef, &bc, f.returnType);
                    copy.genericParams = try unbound(arena, f.genericParams, bc.bound);
                    copy.body = b.body;
                    copy.annotations = &.{};
                    copy.isPub = false;
                    copy.isDefault = false;
                    copy.anonymousDefault = false;
                    copy.defaultBy = null;
                    copy.pubByDefault = false;
                    try out.append(arena, .{ .@"fn" = copy });
                    try blanks.append(arena, true);
                }
                continue;
            },
            .type_ => |t| {
                var methods: std.ArrayListUnmanaged(ast.BehaviorMethod) = .empty;
                var changed = false;
                for (t.methods) |m| {
                    const key = try std.fmt.allocPrint(arena, "{s}.{s}", .{ t.name, m.name });
                    const c = callables.get(key) orelse {
                        try methods.append(arena, m);
                        continue;
                    };
                    if (!c.reads) {
                        try methods.append(arena, m);
                        continue;
                    }
                    changed = true;
                    for ((built.get(key) orelse std.ArrayListUnmanaged(Built).empty).items) |b| {
                        var bc = b.ctx;
                        var copy = m;
                        copy.name = b.name;
                        copy.params = try clone([]ast.Param, &bc, try withoutTokens(arena, m.params));
                        copy.returnType = try clone(?ast.TypeRef, &bc, m.returnType);
                        copy.genericParams = try unbound(arena, m.genericParams, bc.bound);
                        copy.body = b.body;
                        copy.annotations = &.{};
                        try methods.append(arena, copy);
                    }
                }
                if (changed) {
                    var nt = t;
                    nt.methods = try methods.toOwnedSlice(arena);
                    try out.append(arena, .{ .type_ = nt });
                    try blanks.append(arena, blank);
                    continue;
                }
            },
            else => {},
        }
        try out.append(arena, d);
        try blanks.append(arena, blank);
    }
    var result = program;
    result.decls = try out.toOwnedSlice(arena);
    result.blankLineBefore = try blanks.toOwnedSlice(arena);
    return result;
}

/// The builtin call `callee(args…)` at `loc` (decision 758's run-time token
/// forms, which each backend lowers).
fn builtinCall(ctx: *Ctx, callee: []const u8, loc: ast.Loc, args: []const ast.Expr) !ast.Expr {
    var out: ast.Expr = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = callee,
        .is_builtin = true,
        .args = &.{},
        .trailing = &.{},
    } } } };
    const list = try ctx.arena.alloc(ast.CallArg, args.len);
    for (args, list) |a, *slot| {
        const p = try ctx.arena.create(ast.Expr);
        p.* = a;
        slot.* = .{ .label = null, .value = p };
    }
    out.call.kind.call.args = list;
    return out;
}

const Built = struct { name: []const u8, body: []ast.Stmt, ctx: Ctx };

fn joined(arena: std.mem.Allocator, types: []const []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (types, 0..) |t, k| {
        if (k > 0) try buf.append(arena, '|');
        try buf.appendSlice(arena, t);
    }
    return buf.toOwnedSlice(arena);
}

/// `<name>__<Type>[_<Type>…]`, every character outside `[A-Za-z0-9_]` a `_`.
fn mangled(arena: std.mem.Allocator, name: []const u8, types: []const []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(arena, name);
    try buf.appendSlice(arena, "__");
    for (types, 0..) |t, k| {
        if (k > 0) try buf.append(arena, '_');
        for (t) |ch| try buf.append(arena, if (std.ascii.isAlphanumeric(ch) or ch == '_') ch else '_');
    }
    return buf.toOwnedSlice(arena);
}

/// The copy of `key` for `types`, asked for once.
fn copyOf(ctx: *Ctx, key: []const u8, types: []const []const u8) ![]const u8 {
    const c = ctx.callables.getPtr(key).?;
    const k = try joined(ctx.arena, types);
    if (c.copies.get(k)) |n| return n;
    const n = try mangled(ctx.arena, c.name, types);
    try c.copies.put(ctx.arena, k, n);
    try ctx.pending.append(ctx.arena, .{ .key = key, .types = types });
    return n;
}

/// The recorded call `call` at `loc`, rewritten: its type arguments dropped,
/// and a callable of this module that reads a token called through its copy.
fn rewriteCall(ctx: *Ctx, call: anytype, tc: envMod.TypeTokenCall) !void {
    const types = try ctx.arena.alloc([]const u8, tc.names.len);
    for (tc.names, types) |n, *t| t.* = ctx.substOf(n) orelse n;
    var args: std.ArrayListUnmanaged(@TypeOf(call.args[0])) = .empty;
    for (call.args, 0..) |a, k| {
        const dropped = for (tc.at) |at| {
            if (at == k) break true;
        } else false;
        if (!dropped) try args.append(ctx.arena, a);
    }
    call.args = try args.toOwnedSlice(ctx.arena);
    const local = call.receiver == null or tc.owner != null;
    if (!local) return;
    const key = if (tc.owner) |o| try std.fmt.allocPrint(ctx.arena, "{s}.{s}", .{ o, call.callee }) else call.callee;
    const c = ctx.callables.get(key) orelse return;
    if (!c.reads or c.tokens.len != types.len) return;
    call.callee = try copyOf(ctx, key, types);
}

/// A deep copy of `v` with the context's substitution applied and every
/// recorded call rewritten, and in a copy each type parameter a token binds
/// written as the copy's type. Strings are shared.
fn clone(comptime T: type, ctx: *Ctx, v: T) error{OutOfMemory}!T {
    if (T == ast.TypeRef) {
        if (ctx.bound.len == 0) return v;
        if (v == .named) return if (ctx.boundOf(v.named)) |t| .{ .named = t } else v;
    }
    if (T == ast.Expr) {
        var out = v;
        switch (v) {
            .identifier => |id| if (id.kind == .ident) {
                if (ctx.substOf(id.kind.ident)) |t| out.identifier.kind = .{ .ident = t };
                // Decision 758 — a type where a run-time token is taken.
                if (ctx.rtArgs.contains(id.loc)) return builtinCall(ctx, "__bp_type_token", id.loc, &.{out});
                return out;
            },
            .call => |c| if (c.kind == .call) {
                var call = c.kind.call;
                if (call.receiver) |r| call.receiver = try clone(@TypeOf(r), ctx, r);
                if (call.calleeExpr) |r| call.calleeExpr = try clone(@TypeOf(r), ctx, r);
                call.args = try clone(@TypeOf(call.args), ctx, call.args);
                call.trailing = try clone(@TypeOf(call.trailing), ctx, call.trailing);
                if (call.isType) |it| if (it == .named) if (ctx.substOf(it.named)) |t| {
                    call.isType = .{ .named = t };
                };
                if (ctx.calls.get(c.loc)) |tc| try rewriteCall(ctx, &call, tc);
                // Decision 758 — `x is t` over a run-time token: the
                // target's run-time helper over the value and the token.
                if (ctx.rtTests.contains(c.loc) and call.isType != null and call.isType.? == .named and call.args.len == 1) {
                    const token: ast.Expr = .{ .identifier = .{ .loc = c.loc, .kind = .{ .ident = call.isType.?.named } } };
                    return builtinCall(ctx, "__bp_is_type", c.loc, &.{ call.args[0].value.*, token });
                }
                out.call.kind = .{ .call = call };
                return out;
            },
            else => {},
        }
    }
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => {
                const p = try ctx.arena.create(ptr.child);
                p.* = try clone(ptr.child, ctx, v.*);
                return p;
            },
            .slice => {
                if (ptr.child == u8) return v;
                const out = try ctx.arena.alloc(ptr.child, v.len);
                for (v, 0..) |item, k| out[k] = try clone(ptr.child, ctx, item);
                return out;
            },
            else => return v,
        },
        .optional => |o| return if (v) |x| try clone(o.child, ctx, x) else null,
        .@"struct" => |s| {
            var out = v;
            inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try clone(f.type, ctx, @field(v, f.name));
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try clone(@TypeOf(payload), ctx, payload)),
            }
        },
        else => return v,
    }
}

/// Whether `v` reads one of `names`: as a name, or as the type `is` tests.
fn mentionsAny(comptime T: type, v: T, names: []const []const u8) bool {
    if (T == ast.TypeRef) return false;
    if (T == ast.Expr) switch (v) {
        .identifier => |id| if (id.kind == .ident) {
            for (names) |n| if (std.mem.eql(u8, n, id.kind.ident)) return true;
            return false;
        },
        .call => |c| if (c.kind == .call) if (c.kind.call.isType) |it| if (it == .named) {
            for (names) |n| if (std.mem.eql(u8, n, it.named)) return true;
        },
        else => {},
    };
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => return mentionsAny(ptr.child, v.*, names),
            .slice => {
                if (ptr.child == u8) return false;
                for (v) |item| if (mentionsAny(ptr.child, item, names)) return true;
                return false;
            },
            else => return false,
        },
        .optional => |o| return if (v) |x| mentionsAny(o.child, x, names) else false,
        .@"struct" => |s| {
            inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                if (mentionsAny(f.type, @field(v, f.name), names)) return true;
            }
            return false;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return false;
            switch (v) {
                inline else => |payload| return mentionsAny(@TypeOf(payload), payload, names),
            }
        },
        else => return false,
    }
}
