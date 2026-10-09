//! Decision 354 (8) — the hidden context map, lowered on the transformed AST
//! for every backend at once.
//!
//! Every `@Component` function takes the map as a hidden first parameter
//! (after `self` on a method), typed `unknown`; every call of a `@Component`
//! function passes one. Which one is the body's business: a component's
//! children receive the map its `use provide(…)`s built (the "kids" map), a
//! `@Component` read with `use` receives the map its caller received — it is
//! part of that body, as React's hooks are part of their component — and a
//! call outside any `@Component` body passes `null`, the empty map.
//!
//!   use provide(C, v);     →  val bpContextKids__N = bpContextPush__(<kids>, "<C's identity>", v);
//!   use context(C)         →  bpContextFind__(<received>, "<C's identity>", "C")
//!
//! `bpContextPush__` / `bpContextFind__` are std's `context.push` /
//! `context.find`, imported under those names when a module provides or reads
//! (the import is added here). A context's identity is `declIdentity` of the
//! `val` that declares it (281), recorded by the checker in
//! `Env.contextUses`; the calls and lambdas to rewrite are the checker's
//! `Env.componentCalls` / `Env.componentLambdas`, keyed by location and read
//! here once every type is resolved. A provide binds a fresh `val`, so a
//! closure written after it captures the map as it was where it is written
//! (the checker refuses a provide after the body rendered a component).
//!
//! The comptime runtimes evaluate the parsed program (`erlang.zig`
//! `emitComptimeModule`) and do not run this pass (`language-gaps.md`).
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const T = @import("types.zig");

const Env = envMod.Env;

/// The hidden parameter every `@Component` function takes.
pub const map_param = "bpContextMap__";
/// The local names std's two functions are imported under.
pub const push_fn = "bpContextPush__";
pub const find_fn = "bpContextFind__";

const Frame = struct {
    /// The map this body received (its hidden parameter).
    received: []const u8,
    /// The map its children receive: `received` until a `use provide`.
    kids: []const u8,
};

const Lowering = struct {
    arena: std.mem.Allocator,
    env: *Env,
    frames: std.ArrayListUnmanaged(Frame) = .empty,
    kids_count: usize = 0,
    seen: std.AutoHashMapUnmanaged(usize, void) = .empty,
    /// The module's host functions (bodyless `declare fn`s), by name, with
    /// their parameters: a host calls what it is handed with the host's own
    /// signature, so it takes no map and gets none.
    hosts: std.StringHashMapUnmanaged([]const ast.Param) = .empty,
    uses_std: bool = false,

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

    /// The map a call passes: the kids map to a component, the received map
    /// to a `@Component` read with `use`, `null` outside every body.
    fn mapArg(self: *Lowering, renders: bool, loc: ast.Loc) !*ast.Expr {
        const f = self.current() orelse return self.nullLit(loc);
        return self.ident(if (renders) f.kids else f.received, loc);
    }

    fn call(self: *Lowering, callee: []const u8, args: []const *ast.Expr, loc: ast.Loc) !ast.Expr {
        const out = try self.arena.alloc(ast.CallArg, args.len);
        for (args, 0..) |a, i| out[i] = .{ .label = null, .value = a };
        return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = callee,
            .is_builtin = false,
            .args = out,
            .trailing = &.{},
        } } } };
    }

    /// A function type answering `@Component<R>` takes the hidden map first,
    /// as the functions of that type do — a parameter's, a field's, an
    /// annotation's, the type `v is fn(…) -> @Component<R>` tests (its arity).
    /// Every `TypeRef` of the module is reached once (`seen`).
    fn fixTypes(self: *Lowering, comptime N: type, ptr: *N) anyerror!void {
        if (N == ast.TypeRef) {
            const key = @intFromPtr(ptr);
            if (self.seen.contains(key)) return;
            try self.seen.put(self.arena, key, {});
        }
        if (comptime !mayHoldTypeRef(N)) return;
        switch (@typeInfo(N)) {
            .@"struct" => |st| inline for (st.fields) |f| {
                if (f.is_comptime) continue;
                try self.fixTypes(f.type, &@field(ptr.*, f.name));
            },
            .@"union" => |u| if (u.tag_type != null) {
                switch (ptr.*) {
                    inline else => |*payload| try self.fixTypes(@TypeOf(payload.*), payload),
                }
            },
            .optional => |o| if (ptr.*) |*inner| try self.fixTypes(o.child, inner),
            .pointer => |pi| switch (pi.size) {
                .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") {
                    try self.fixTypes(pi.child, @constCast(ptr.*));
                },
                .slice => for (ptr.*) |*e| try self.fixTypes(pi.child, @constCast(e)),
                else => {},
            },
            else => {},
        }
        if (N == ast.TypeRef) try self.withHiddenTypeParam(ptr);
    }

    fn withHiddenTypeParam(self: *Lowering, t: *ast.TypeRef) !void {
        switch (t.*) {
            .function => |*f| {
                if (!returnsComponentRef(self.env, f.returnType.*)) return;
                const params = try self.arena.alloc(ast.TypeRef, f.params.len + 1);
                params[0] = .{ .named = ast.unknown_type_name };
                @memcpy(params[1..], f.params);
                f.params = params;
                if (f.paramNames.len > 0) {
                    const names = try self.arena.alloc([]const u8, f.paramNames.len + 1);
                    names[0] = map_param;
                    @memcpy(names[1..], f.paramNames);
                    f.paramNames = names;
                }
            },
            else => {},
        }
    }

    fn hiddenParam() ast.Param {
        return .{ .name = map_param, .typeRef = .{ .named = ast.unknown_type_name } };
    }

    fn withHiddenParam(self: *Lowering, params: []const ast.Param) ![]ast.Param {
        const at: usize = if (params.len > 0 and std.mem.eql(u8, params[0].name, "self")) 1 else 0;
        const out = try self.arena.alloc(ast.Param, params.len + 1);
        @memcpy(out[0..at], params[0..at]);
        out[at] = hiddenParam();
        @memcpy(out[at + 1 ..], params[at..]);
        return out;
    }

    /// A call of a host function passes no map: the host's signature is the
    /// host's. A `@Component` function value handed to it keeps the hidden
    /// map as its first parameter — a host stores it opaquely, and a host that
    /// calls one passes the map first (`null` when it has none).
    fn lowerHostCall(self: *Lowering, cc: anytype) !void {
        if (cc.receiver) |r| try self.walk(ast.Expr, r);
        for (cc.args) |*a| try self.walk(ast.Expr, a.value);
        for (cc.trailing) |*t| try self.walk(@TypeOf(t.*), t);
    }

    fn lowerBody(self: *Lowering, body: []ast.Stmt, component: bool) !void {
        if (component) try self.frames.append(self.arena, .{ .received = map_param, .kids = map_param });
        defer if (component) {
            _ = self.frames.pop();
        };
        for (body) |*s| try self.walk(ast.Stmt, s);
    }

    /// `use provide(C, v)` as a whole statement: bind the children's map.
    fn lowerProvideStmt(self: *Lowering, stmt: *ast.Stmt, use: envMod.ContextUse) !void {
        const inner = stmt.expr.useHook.kind.inner;
        const loc = stmt.expr.getLoc();
        const value = inner.call.kind.call.args[1].value;
        try self.walk(ast.Expr, value);
        const f = self.current() orelse return error.ContextLowering;
        const name = try std.fmt.allocPrint(self.arena, "bpContextKids__{d}", .{self.kids_count});
        self.kids_count += 1;
        const pushed = try self.arena.create(ast.Expr);
        pushed.* = try self.call(push_fn, &.{ try self.ident(f.kids, loc), try self.string(use.key, loc), value }, loc);
        stmt.expr = .{ .binding = .{ .loc = loc, .kind = .{ .localBind = .{ .name = name, .value = pushed, .mutable = false } } } };
        self.frames.items[self.frames.items.len - 1].kids = name;
        self.uses_std = true;
    }

    fn visitExpr(self: *Lowering, e: *ast.Expr) !bool {
        switch (e.*) {
            .useHook => |uh| if (self.env.contextUses.get(uh.loc)) |use| {
                if (use.kind == .provide) return error.ContextLowering; // a statement of its own
                const map = try self.mapArg(false, uh.loc);
                e.* = try self.call(find_fn, &.{ map, try self.string(use.key, uh.loc), try self.string(use.name, uh.loc) }, uh.loc);
                self.uses_std = true;
                return true;
            },
            .call => |*c| if (c.kind == .call) {
                const cc = &c.kind.call;
                if (cc.receiver == null and !cc.is_builtin) if (self.hosts.get(cc.callee)) |params| {
                    _ = params;
                    try self.lowerHostCall(cc);
                    return true;
                };
                if (self.env.componentCalls.get(c.loc)) |recs| if (recordFor(recs, cc.callee)) |rec| if (componentValue(rec.type_)) |r| {
                    const args = try self.arena.alloc(ast.CallArg, cc.args.len + 1);
                    args[0] = .{ .label = null, .value = try self.mapArg(isRenderable(self.env, r), c.loc) };
                    @memcpy(args[1..], cc.args);
                    cc.args = args;
                };
            },
            .function => |*f| if (f.kind.syntax != .asyncBlock) {
                if (self.env.componentLambdas.get(f.loc)) |rec| if (rec.params == f.kind.params.len and returnsComponent(rec.type_)) {
                    const params = try self.arena.alloc([]const u8, f.kind.params.len + 1);
                    params[0] = map_param;
                    @memcpy(params[1..], f.kind.params);
                    f.kind.params = params;
                    try self.frames.append(self.arena, .{ .received = map_param, .kids = map_param });
                    defer _ = self.frames.pop();
                    for (f.kind.body) |*s| try self.walk(ast.Stmt, s);
                    return true;
                };
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
            if (try self.visitExpr(ptr)) {
                // A replaced `use context` still holds its map; a lambda's
                // body was walked under its own frame.
                return;
            }
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
};

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

/// The record of the call naming `callee` at a location (two template
/// expansions' built code can share one).
fn recordFor(recs: []const envMod.ComponentCall, callee: []const u8) ?envMod.ComponentCall {
    for (recs) |r| if (std.mem.eql(u8, r.callee, callee)) return r;
    return null;
}

/// A deep copy of `v`: every node behind a pointer or a slice is copied, and
/// text (`[]const u8`) is shared, being immutable.
fn deepCopy(comptime N: type, arena: std.mem.Allocator, v: N) anyerror!N {
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

/// Whether a value of `N` can reach an `ast.TypeRef`.
fn mayHoldTypeRef(comptime N: type) bool {
    return switch (@typeInfo(N)) {
        .@"struct", .@"union" => N != ast.Loc,
        .optional => |o| mayHoldTypeRef(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldTypeRef(pi.child),
        else => false,
    };
}

/// The `R` of a resolved `@Component<R>`, or null.
fn componentValue(ty: *T.Type) ?*T.Type {
    const d = ty.deref();
    if (d.* != .named or !std.mem.eql(u8, d.named.name, "Component") or d.named.args.len < 1) return null;
    return d.named.args[0];
}

fn returnsComponent(ty: *T.Type) bool {
    const d = ty.deref();
    if (d.* != .func) return false;
    return componentValue(d.func.ret) != null;
}

fn isRenderable(env: *Env, r: *T.Type) bool {
    const d = r.deref();
    if (d.* != .named) return true; // an `R` still open renders, as a component's would
    const td = env.lookupTypeDef(d.named.name) orelse return false;
    return td.isRenderable();
}

/// True when a written return is `@Component<…>`, or an alias that stands
/// for it (`-> StyledView`): the hidden map follows the type, not the spelling.
fn returnsComponentRef(env: *Env, rt: ?ast.TypeRef) bool {
    const r = rt orelse return false;
    if (r == .generic and r.generic.is_builtin and std.mem.eql(u8, r.generic.name, "Component")) return true;
    const w = env.aliasedWrapper(r) orelse return false;
    return std.mem.eql(u8, w.wrapper, "Component");
}

/// The behavior `name` — this module's or an imported one.
fn behaviorNamed(env: *Env, program: ast.Program, name: []const u8) ?ast.BehaviorDecl {
    for (program.decls) |d| if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) return d.behavior;
    return env.importedBehaviorDecls.get(name);
}

/// True when an `implement` method answers `@Component<R>`: its behavior's
/// declaration says so (an implement method writes no return).
fn implementMethodIsComponent(env: *Env, program: ast.Program, im: ast.ImplementDecl, method: []const u8) bool {
    for (im.interfaces) |iface| {
        const name = switch (iface) {
            .named => |n| n,
            .generic => |g| g.name,
            else => continue,
        };
        const b = behaviorNamed(env, program, name) orelse continue;
        for (b.methods) |bm| if (std.mem.eql(u8, bm.name, method)) return returnsComponentRef(env, bm.returnType);
    }
    return false;
}

/// True when the module holds anything the map reaches.
fn needed(env: *Env, program: ast.Program) bool {
    if (env.contextUses.count() > 0 or env.componentCalls.count() > 0) return true;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| if (env.componentFns.contains(f.name)) return true,
        .type_ => |t| for (t.methods) |m| if (returnsComponentRef(env, m.returnType)) return true,
        else => {},
    };
    return false;
}

/// Lower the hidden context map over `program` (the transformed module).
pub fn lower(arena: std.mem.Allocator, program: ast.Program, env_const: *const Env) !ast.Program {
    const env = @constCast(env_const);
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
        .@"fn", .@"test", .val, .implement, .behavior, .delegate => d.* = try deepCopy(ast.DeclKind, arena, d.*),
        // A type's methods are copied; its shape is not — the passes after
        // this one rewrite a type's shape where the parsed program holds it,
        // and the module's importers read that.
        .type_ => |*t| t.methods = try deepCopy([]ast.BehaviorMethod, arena, t.methods),
        else => {},
    };
    for (decls) |d| switch (d) {
        .@"fn" => |f| if (f.body.len == 0) try low.hosts.put(arena, f.name, f.params),
        .delegate => |dg| try low.hosts.put(arena, dg.name, dg.params),
        else => {},
    };
    for (decls) |*d| switch (d.*) {
        .@"fn" => |*f| {
            const component = env.componentFns.contains(f.name);
            if (component and f.body.len > 0) f.params = try low.withHiddenParam(f.params);
            try low.lowerBody(f.body, component and f.body.len > 0);
            for (f.params) |*p| if (p.default) |*dv| try low.walk(ast.Expr, dv);
        },
        .@"test" => |*t| try low.lowerBody(t.body, false),
        .val => |*v| try low.walk(ast.Expr, v.value),
        .type_ => |*t| {
            const methods = try arena.dupe(ast.BehaviorMethod, t.methods);
            for (methods) |*m| {
                const body = m.body orelse continue;
                const component = returnsComponentRef(env, m.returnType);
                if (component) m.params = try low.withHiddenParam(m.params);
                try low.lowerBody(body, component);
            }
            t.methods = methods;
        },
        .implement => |*im| {
            const methods = try arena.dupe(ast.ImplementMethod, im.methods);
            for (methods) |*m| {
                const component = implementMethodIsComponent(env, program, im.*, m.name);
                if (component) m.params = try low.withHiddenParam(m.params);
                try low.lowerBody(m.body, component);
            }
            im.methods = methods;
        },
        .behavior => |*b| {
            const methods = try arena.dupe(ast.BehaviorMethod, b.methods);
            for (methods) |*m| {
                const body = m.body orelse continue;
                if (!m.is_default) continue;
                const component = returnsComponentRef(env, m.returnType);
                if (component) m.params = try low.withHiddenParam(m.params);
                try low.lowerBody(body, component);
            }
            b.methods = methods;
        },
        else => {},
    };
    for (decls) |*d| switch (d.*) {
        // A record's field types stay the parsed ones (see the copy above): a
        // function-typed field keeps its written arity, the values in it the
        // hidden map.
        .type_ => |*t| for (t.methods) |*m| try low.fixTypes(ast.BehaviorMethod, m),
        else => try low.fixTypes(ast.DeclKind, d),
    };
    if (!low.uses_std) return .{ .decls = decls };
    // std's `push` / `find`, under names no source can collide with.
    const items = try arena.alloc(ast.ImportPath, 2);
    items[0] = .{ .segments = try arena.dupe([]const u8, &.{ "context", "push" }), .alias = push_fn };
    items[1] = .{ .segments = try arena.dupe([]const u8, &.{ "context", "find" }), .alias = find_fn };
    const grown = try arena.alloc(ast.DeclKind, decls.len + 1);
    grown[0] = .{ .use = .{ .imports = items, .source = .{ .module = "std" } } };
    @memcpy(grown[1..], decls);
    return .{ .decls = grown };
}
