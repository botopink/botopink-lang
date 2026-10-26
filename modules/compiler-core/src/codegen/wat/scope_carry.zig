//! Decision 504 — the component scope's values on wasm, typed.
//!
//! The scope lowering (`comptime/context_lower.zig`, decisions 809 (8), 819)
//! carries values through std's `context` functions in `unknown` slots — its
//! marked calls of them by their std names (`context_lower.isHelperCall`,
//! decision 961 (2)) — a
//! provided value, a body's answer, the value a run answers — and writes, on
//! each call that crosses one, the checker's type of the value as the call's
//! one type argument (`find<T>(…)`, the `bpRun__<R>` a run of a
//! component value carries). This backend boxes and unboxes only by a static
//! type, so before anything is registered each module's program is rewritten
//! here (a copy: the transformed program is shared with the module's other
//! emissions):
//!
//! - a value crosses the scope as its own word, never boxed: `enter`'s,
//!   `provideIn`'s and `answer`'s calls go through one wrapper each,
//!   `bpScopeRaw__enter` / `bpScopeRaw__provide` / `bpScopeRaw__answer`,
//!   whose arguments the emitter passes as they are (`isWrapper`);
//! - a value read back is typed by what the call carries: each carried
//!   `find` and each run is a call of a wrapper of its own
//!   (`bpScopeRaw__find<n>` …) declared to answer that type, so every
//!   reader of the call's answer — a field read, a string concatenation, a
//!   printer — asks a declared return, as of any function; the wrapper's
//!   `return` passes the word as it is (`Emitter.raw_return`);
//! - a written `Component<R>` is the function a component is at run time
//!   (819): `fn(unknown, unknown) -> R`, wherever it is written but a host
//!   declaration (a bodyless `declare fn` answers the host's own value).
//!
//! A value whose type is a float or an `i64` (8 bytes, no word) crosses as
//! the address of its cell, as a function value's does: `provideIn` and
//! `answer` keep the type they carry, so the emitter boxes their value
//! argument (`valueArg`), and a reader's wrapper declared to answer that type
//! loads the cell. A carried call with no type (the checker left it
//! unresolved) is left as it is, and the emitter refuses it at the call.
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

/// The position of the value a `provide` / `answer` wrapper carries into the
/// scope — the argument the emitter boxes when the call's type argument is a
/// float or an `i64` — or null for a reader.
pub fn valueArg(name: []const u8) ?usize {
    if (std.mem.endsWith(u8, name, wrapper_prefix ++ "provide")) return 2;
    if (std.mem.endsWith(u8, name, wrapper_prefix ++ "answer")) return 0;
    // Decision 378 (3) — `find`'s fallback, the type's declared default,
    // crosses as `push`'s value does.
    if (std.mem.indexOf(u8, name, wrapper_prefix ++ "find") != null) return 2;
    return null;
}

const unknown_ref: ast.TypeRef = .{ .named = ast.unknown_type_name };

const Carry = struct {
    arena: std.mem.Allocator,
    wrappers: std.ArrayListUnmanaged(ast.DeclKind) = .empty,
    count: usize = 0,
    provide_done: bool = false,
    answer_done: bool = false,
    enter_done: bool = false,

    fn lambdaRef(self: *Carry) !ast.TypeRef {
        const params = try self.arena.alloc(ast.TypeRef, 2);
        params[0] = unknown_ref;
        params[1] = unknown_ref;
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
            // Decision 961 (2) — the wrapper calls std's helper by its std
            // name, marked as the lowering's call it stands in for.
            .lowering = callee != null,
            .stdModule = if (callee != null) context_lower.helper_module else null,
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
            // A run, `(c)(cell, place)`, carrying `bpRun__<R>`.
            const ta = cc.typeArgs orelse return;
            if (ta.len != 1 or ta[0] != .generic or !std.mem.eql(u8, ta[0].generic.name, context_lower.run_mark) or ta[0].generic.args.len != 1 or cc.args.len != 2) return;
            const name = try self.fresh("run");
            try self.declare(name, &.{ param("c", try self.lambdaRef()), param("s", unknown_ref), param("k", unknown_ref) }, ta[0].generic.args[0], null, c.loc);
            const args = try self.arena.alloc(ast.CallArg, 3);
            args[0] = .{ .label = null, .value = ce };
            args[1] = cc.args[0];
            args[2] = cc.args[1];
            cc.* = .{ .receiver = null, .callee = name, .is_builtin = false, .args = args, .trailing = &.{} };
            return;
        }
        if (context_lower.isHelperCall(cc.*, context_lower.provide_fn)) {
            const name = wrapper_prefix ++ "provide";
            if (!self.provide_done) try self.declare(name, &.{ param("s", unknown_ref), param("k", .{ .named = "string" }), param("v", unknown_ref) }, unknown_ref, context_lower.provide_fn, c.loc);
            self.provide_done = true;
            cc.callee = name;
            cc.stdModule = null;
            cc.lowering = false;
        } else if (context_lower.isHelperCall(cc.*, context_lower.enter_fn)) {
            // The function's own parameters, the scope and the place: passed
            // on as the words they are.
            const name = wrapper_prefix ++ "enter";
            if (!self.enter_done) try self.declare(name, &.{ param("s", unknown_ref), param("k", unknown_ref) }, unknown_ref, context_lower.enter_fn, c.loc);
            self.enter_done = true;
            cc.callee = name;
            cc.stdModule = null;
            cc.lowering = false;
        } else if (context_lower.isHelperCall(cc.*, context_lower.answer_fn)) {
            const name = wrapper_prefix ++ "answer";
            if (!self.answer_done) try self.declare(name, &.{param("v", unknown_ref)}, unknown_ref, context_lower.answer_fn, c.loc);
            self.answer_done = true;
            cc.callee = name;
            cc.stdModule = null;
            cc.lowering = false;
        } else if (context_lower.isHelperCall(cc.*, context_lower.find_fn)) {
            const ta = cc.typeArgs orelse return;
            if (ta.len != 1) return;
            const name = try self.fresh("find");
            // Decision 378 (3) — the third argument is the type's declared
            // default, moved through `find`'s `unknown` slot as `push`'s value is.
            try self.declare(name, &.{ param("s", unknown_ref), param("k", .{ .named = "string" }), param("f", unknown_ref) }, ta[0], context_lower.find_fn, c.loc);
            cc.callee = name;
            cc.stdModule = null;
            cc.lowering = false;
        }
    }

    fn walk(self: *Carry, comptime N: type, ptr: *N) anyerror!void {
        if (N == ast.TypeRef) {
            if (isComponentRef(ptr.*)) {
                // `fn(unknown, unknown) -> R`: the function a component is,
                // answering its `R` as the word it is (`answer`), so a generic
                // signature (`run<T>(c: Component<T>)`) still binds `T`.
                const r = ptr.generic.args[0];
                ptr.* = try self.lambdaRef();
                const ret = try self.arena.create(ast.TypeRef);
                ret.* = r;
                ptr.function.returnType = ret;
                try self.walk(ast.TypeRef, ret);
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
            if (context_lower.isAnyHelperCall(cc)) return true;
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
    return d == .@"fn" and (d.@"fn".isDeclare or (d.@"fn".body.len == 0 and d.@"fn".isExternal()));
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
