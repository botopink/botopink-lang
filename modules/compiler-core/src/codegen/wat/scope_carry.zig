//! Decision 504 — the render scope's values on wasm, typed.
//!
//! The scope lowering (`comptime/context_lower.zig`, decision 388) carries
//! values through std's `context` functions in `unknown` slots — a provided
//! value, a body's result, the value a run answers — and writes, on each call
//! that crosses one, the checker's type of the value as the call's one type
//! argument (`bpScopeFind__<T>(…)`, `bpScopeValue__<R>(…)`, the
//! `Rendered<R>` a `c.run(scope)` answers). This backend boxes and unboxes
//! only by a static type, so before anything is registered each module's
//! program is rewritten here (a copy: the transformed program is shared with
//! the module's other emissions):
//!
//! - a value crosses the scope as its own word, never boxed: `push`'s and
//!   `rendered`'s calls go through one wrapper each, `bpScopeRaw__push` /
//!   `bpScopeRaw__rendered`, whose arguments the emitter passes as they are
//!   (`isWrapper`);
//! - a value read back is typed by what the call carries: each carried
//!   `find` / `valueOf` and each run is a call of a wrapper of its own
//!   (`bpScopeRaw__find<n>` …) declared to answer that type, so every
//!   reader of the call's answer — a field read, a string concatenation, a
//!   printer — asks a declared return, as of any function; the wrapper's
//!   `return` passes the word as it is (`Emitter.raw_return`);
//! - a written `@Component<R>` is the lambda a component is at run time
//!   (388): `fn(unknown) -> unknown`, wherever it is written but a host
//!   declaration (a bodyless `declare fn` answers the host's own value).
//!
//! A value whose type is a float or an `i64` (8 bytes, no word) crosses as
//! the address of its cell, as a function value's does: `push` and `rendered`
//! keep the type they carry, so the emitter boxes their value argument
//! (`valueArg`), and a reader's wrapper declared to answer that type loads
//! the cell. A carried call with no type (the checker left it unresolved) is
//! left as it is, and the emitter refuses it at the call.
const std = @import("std");
const ast = @import("../../ast.zig");
const context_lower = @import("../../comptime/context_lower.zig");

/// What every wrapper's name starts with; no source can spell it.
pub const wrapper_prefix = "bpScopeRaw__";

/// Whether `name` is a run's wrapper (`bpScopeRaw__run<n>`), which the
/// emitter lowers in place: the lambda's mark says whether its answer is a
/// task (decision 504, `Emitter.lowerRun`).
pub fn isRun(name: []const u8) bool {
    return std.mem.indexOf(u8, name, wrapper_prefix ++ "run") != null;
}

/// Whether `name` (a module's own, or mangled `<module>/<name>`) is one of
/// the wrappers this pass declares.
pub fn isWrapper(name: []const u8) bool {
    return std.mem.indexOf(u8, name, wrapper_prefix) != null;
}

/// The position of the value a `push` / `rendered` wrapper carries into the
/// scope — the argument the emitter boxes when the call's type argument is a
/// float or an `i64` — or null for a reader.
pub fn valueArg(name: []const u8) ?usize {
    if (std.mem.endsWith(u8, name, wrapper_prefix ++ "push")) return 2;
    if (std.mem.endsWith(u8, name, wrapper_prefix ++ "rendered")) return 0;
    return null;
}

const unknown_ref: ast.TypeRef = .{ .named = ast.unknown_type_name };

const Carry = struct {
    arena: std.mem.Allocator,
    wrappers: std.ArrayListUnmanaged(ast.DeclKind) = .empty,
    count: usize = 0,
    push_done: bool = false,
    rendered_done: bool = false,

    fn lambdaRef(self: *Carry) !ast.TypeRef {
        const params = try self.arena.alloc(ast.TypeRef, 1);
        params[0] = unknown_ref;
        const ret = try self.arena.create(ast.TypeRef);
        ret.* = unknown_ref;
        return .{ .function = .{ .params = params, .returnType = ret } };
    }

    fn ident(self: *Carry, name: []const u8, loc: ast.Loc) !*ast.Expr {
        const e = try self.arena.create(ast.Expr);
        e.* = .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
        return e;
    }

    fn param(name: []const u8, t: ast.TypeRef) ast.Param {
        return .{ .name = name, .typeRef = t };
    }

    /// `fn <name>(<params>) -> <ret> { return <callee>(<params>); }` — or,
    /// with `callee` null, the call of the first parameter with the rest.
    fn declare(self: *Carry, name: []const u8, params: []const ast.Param, ret: ast.TypeRef, callee: ?[]const u8, loc: ast.Loc) !void {
        const ps = try self.arena.dupe(ast.Param, params);
        const first: usize = if (callee == null) 1 else 0;
        const args = try self.arena.alloc(ast.CallArg, ps.len - first);
        for (ps[first..], 0..) |p, i| args[i] = .{ .label = null, .value = try self.ident(p.name, loc) };
        const call = try self.arena.create(ast.Expr);
        call.* = .{ .call = .{ .loc = loc, .kind = .{ .call = .{
            .receiver = null,
            .callee = callee orelse "",
            .is_builtin = false,
            .args = args,
            .trailing = &.{},
            .calleeExpr = if (callee == null) try self.ident(ps[0].name, loc) else null,
        } } } };
        const body = try self.arena.alloc(ast.Stmt, 1);
        body[0] = .{ .expr = .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = call } } } };
        try self.wrappers.append(self.arena, .{ .@"fn" = .{
            .isPub = false,
            .name = name,
            .nameLoc = loc,
            .genericParams = &.{},
            .params = ps,
            .returnType = ret,
            .body = body,
        } });
    }

    fn fresh(self: *Carry, what: []const u8) ![]const u8 {
        defer self.count += 1;
        return std.fmt.allocPrint(self.arena, wrapper_prefix ++ "{s}{d}", .{ what, self.count });
    }

    fn visitCall(self: *Carry, c: anytype) !void {
        const cc = &c.kind.call;
        if (cc.receiver != null or cc.is_builtin) return;
        if (cc.calleeExpr) |ce| {
            // A run, `(c)(scope)`, carrying `Rendered<R>`.
            const ta = cc.typeArgs orelse return;
            if (ta.len != 1 or ta[0] != .generic or !std.mem.eql(u8, ta[0].generic.name, "Rendered") or cc.args.len != 1) return;
            const name = try self.fresh("run");
            try self.declare(name, &.{ param("c", try self.lambdaRef()), param("s", unknown_ref) }, ta[0], null, c.loc);
            const args = try self.arena.alloc(ast.CallArg, 2);
            args[0] = .{ .label = null, .value = ce };
            args[1] = cc.args[0];
            cc.* = .{ .receiver = null, .callee = name, .is_builtin = false, .args = args, .trailing = &.{} };
            return;
        }
        if (std.mem.eql(u8, cc.callee, context_lower.push_fn)) {
            const name = wrapper_prefix ++ "push";
            if (!self.push_done) try self.declare(name, &.{ param("s", unknown_ref), param("k", .{ .named = "string" }), param("v", unknown_ref) }, unknown_ref, context_lower.push_fn, c.loc);
            self.push_done = true;
            cc.callee = name;
        } else if (std.mem.eql(u8, cc.callee, context_lower.rendered_fn)) {
            const name = wrapper_prefix ++ "rendered";
            if (!self.rendered_done) try self.declare(name, &.{ param("v", unknown_ref), param("s", unknown_ref) }, unknown_ref, context_lower.rendered_fn, c.loc);
            self.rendered_done = true;
            cc.callee = name;
        } else if (std.mem.eql(u8, cc.callee, context_lower.find_fn)) {
            const ta = cc.typeArgs orelse return;
            if (ta.len != 1) return;
            const name = try self.fresh("find");
            try self.declare(name, &.{ param("s", unknown_ref), param("k", .{ .named = "string" }), param("n", .{ .named = "string" }) }, ta[0], context_lower.find_fn, c.loc);
            cc.callee = name;
            cc.typeArgs = null;
        } else if (std.mem.eql(u8, cc.callee, context_lower.value_fn)) {
            const ta = cc.typeArgs orelse return;
            if (ta.len != 1) return;
            const name = try self.fresh("value");
            try self.declare(name, &.{param("r", unknown_ref)}, ta[0], context_lower.value_fn, c.loc);
            cc.callee = name;
            cc.typeArgs = null;
        }
    }

    fn walk(self: *Carry, comptime N: type, ptr: *N) anyerror!void {
        if (N == ast.TypeRef) {
            if (isComponentRef(ptr.*)) {
                ptr.* = try self.lambdaRef();
                return;
            }
        }
        if (N == ast.Expr) {
            if (ptr.* == .call and ptr.call.kind == .call) try self.visitCall(&ptr.call);
        }
        if (comptime !mayHold(N)) return;
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

fn isComponentRef(t: ast.TypeRef) bool {
    return t == .generic and t.generic.is_builtin and std.mem.eql(u8, t.generic.name, "Component");
}

/// Whether a value of `N` can reach an `ast.Expr` or an `ast.TypeRef`.
fn mayHold(comptime N: type) bool {
    return switch (@typeInfo(N)) {
        .@"struct", .@"union" => N != ast.Loc,
        .optional => |o| mayHold(o.child),
        .pointer => |pi| pi.child != u8 and mayHold(pi.child),
        else => false,
    };
}

/// Whether anything in `v` is for this pass: a written `@Component<…>`, or a
/// call of the scope lowering's functions.
fn needs(comptime N: type, v: *const N) bool {
    if (N == ast.TypeRef) {
        if (isComponentRef(v.*)) return true;
    }
    if (N == ast.Expr) {
        if (v.* == .call and v.call.kind == .call) {
            const cc = v.call.kind.call;
            if (cc.calleeExpr != null and cc.typeArgs != null) return true;
            for (context_lower.lowered_fns) |f| if (std.mem.eql(u8, cc.callee, f)) return true;
        }
    }
    if (comptime !mayHold(N)) return false;
    switch (@typeInfo(N)) {
        .@"struct" => |st| inline for (st.fields) |f| {
            if (f.is_comptime) continue;
            if (needs(f.type, &@field(v.*, f.name))) return true;
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (v.*) {
                inline else => |*payload| if (needs(@TypeOf(payload.*), payload)) return true,
            }
        },
        .optional => |o| if (v.*) |*inner| return needs(o.child, inner),
        .pointer => |pi| switch (pi.size) {
            .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") return needs(pi.child, v.*),
            .slice => for (v.*) |*e| if (needs(pi.child, e)) return true,
            else => {},
        },
        else => {},
    }
    return false;
}

/// A host declaration answers the host's own value: its written types stay.
fn isHost(d: ast.DeclKind) bool {
    return d == .@"fn" and (d.@"fn".isHost() or d.@"fn".isDeclare or (d.@"fn".body.len == 0 and d.@"fn".isExternal()));
}

/// `program` with the scope's values typed for this backend (the file's
/// comment), or `program` itself when nothing in it is for this pass.
pub fn carry(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var any = false;
    for (program.decls) |*d| if (!isHost(d.*) and needs(ast.DeclKind, d)) {
        any = true;
        break;
    };
    if (!any) return program;
    var c: Carry = .{ .arena = arena };
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    for (decls) |*d| {
        if (isHost(d.*) or !needs(ast.DeclKind, d)) continue;
        d.* = try context_lower.deepCopy(ast.DeclKind, arena, d.*);
        try c.walk(ast.DeclKind, d);
    }
    if (c.wrappers.items.len == 0) return .{ .decls = decls };
    const grown = try arena.alloc(ast.DeclKind, decls.len + c.wrappers.items.len);
    @memcpy(grown[0..decls.len], decls);
    @memcpy(grown[decls.len..], c.wrappers.items);
    return .{ .decls = grown };
}
