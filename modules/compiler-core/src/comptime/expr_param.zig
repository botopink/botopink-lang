//! Decision 364 — a `comptime x: @Expr<T>` parameter of a function that is not
//! a template (`Param.exprWrapped`, `parser/expr_params.zig`) is read in its
//! body as `x.value`. The checker types the read (`infer.zig`); the code that
//! runs — the program's own functions, and every function the comptime
//! runtimes lower (a decorator's body and the functions it reaches, a template's
//! helpers, a `comptime` block's) — holds the argument's value in `x` itself,
//! so the read is erased here: `x.value` is `x`.
//!
//! In a decorator body, `x.fail(message)` is located at `x`'s argument
//! (364 (3)): it becomes `__bp_failArg(<j>, message)`, `j` the parameter's
//! position after the `@Decl` one, which the decorator prelude throws and
//! `infer.zig` `runDeclDecorators` reports at that argument
//! (`runtime/prelude.zig`, `decorator_eval.zig`).

const std = @import("std");
const ast = @import("../ast.zig");
const memberFn = @import("member_fn.zig");

/// The decorator prelude's function `x.fail(m)` becomes.
pub const fail_arg_fn = @import("runtime/prelude.zig").fail_arg_fn;

const Ctx = struct {
    arena: std.mem.Allocator,
    /// The `exprWrapped` parameters, by name, with their index after `@Decl`
    /// (decorators) or in the list (any other function).
    names: []const []const u8,
    indices: []const usize,
    /// Rewrite `x.fail(m)` (a decorator body).
    failArg: bool,
    /// Decision 370 (2) — a decorator's `@Decl` parameter: each
    /// `decl.addMember(name, fn…)` hands the runtime the function's index
    /// (`member_fn.collect`'s order) instead of the function, which is the
    /// program's code, not the body's.
    declName: ?[]const u8 = null,
    members: usize = 0,
};

/// `f` with every read of a `comptime x: @Expr<T>` parameter erased; `f`
/// itself when it has none. `decorator` set: `f` is a decorator (its first
/// parameter `@Decl`), and `x.fail(m)` is located at the argument.
pub fn eraseFn(arena: std.mem.Allocator, f: ast.FnDecl, decorator: bool) !ast.FnDecl {
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    var indices: std.ArrayListUnmanaged(usize) = .empty;
    for (f.params, 0..) |p, i| {
        if (!p.exprWrapped) continue;
        try names.append(arena, p.name);
        try indices.append(arena, if (decorator and i > 0) i - 1 else i);
    }
    const declName: ?[]const u8 = if (decorator) memberFn.declParamName(f) else null;
    if (names.items.len == 0 and declName == null) return f;
    var ctx: Ctx = .{ .arena = arena, .names = names.items, .indices = indices.items, .failArg = decorator, .declName = declName };
    var out = f;
    out.body = try clone([]ast.Stmt, &ctx, f.body);
    return out;
}

/// Every function of `program` erased (`eraseFn`), the decorators' with their
/// `.fail` located; the program itself when none has a `comptime @Expr`
/// parameter.
pub fn eraseProgram(arena: std.mem.Allocator, program: ast.Program, isDecorator: *const fn ([]const ast.Param) bool) !ast.Program {
    var decls: ?[]ast.DeclKind = null;
    for (program.decls, 0..) |d, i| {
        switch (d) {
            .@"fn" => |f| {
                if (!hasWrapped(f.params)) continue;
                if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
                decls.?[i] = .{ .@"fn" = try eraseFn(arena, f, isDecorator(f.params)) };
            },
            .type_ => |t| {
                const methods = try eraseMethods(arena, t.methods) orelse continue;
                if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
                var nt = t;
                nt.methods = methods;
                decls.?[i] = .{ .type_ = nt };
            },
            .behavior => |b| {
                const methods = try eraseMethods(arena, b.methods) orelse continue;
                if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
                var nb = b;
                nb.methods = methods;
                decls.?[i] = .{ .behavior = nb };
            },
            .implement => |im| {
                const methods = try eraseImplMethods(arena, im.methods) orelse continue;
                if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
                var ni = im;
                ni.methods = methods;
                decls.?[i] = .{ .implement = ni };
            },
            .extend => |ex| {
                const methods = try eraseImplMethods(arena, ex.methods) orelse continue;
                if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
                var ne = ex;
                ne.methods = methods;
                decls.?[i] = .{ .extend = ne };
            },
            else => {},
        }
    }
    var out = program;
    if (decls) |ds| out.decls = ds;
    return out;
}

fn hasWrapped(params: []const ast.Param) bool {
    for (params) |p| if (p.exprWrapped) return true;
    return false;
}

fn eraseMethods(arena: std.mem.Allocator, methods: []ast.BehaviorMethod) !?[]ast.BehaviorMethod {
    var out: ?[]ast.BehaviorMethod = null;
    for (methods, 0..) |m, i| {
        if (!hasWrapped(m.params)) continue;
        const body = m.body orelse continue;
        if (out == null) out = try arena.dupe(ast.BehaviorMethod, methods);
        var ctx = try ctxOf(arena, m.params);
        out.?[i].body = try clone([]ast.Stmt, &ctx, body);
    }
    return out;
}

fn eraseImplMethods(arena: std.mem.Allocator, methods: []ast.ImplementMethod) !?[]ast.ImplementMethod {
    var out: ?[]ast.ImplementMethod = null;
    for (methods, 0..) |m, i| {
        if (!hasWrapped(m.params)) continue;
        if (out == null) out = try arena.dupe(ast.ImplementMethod, methods);
        var ctx = try ctxOf(arena, m.params);
        out.?[i].body = try clone([]ast.Stmt, &ctx, m.body);
    }
    return out;
}

fn ctxOf(arena: std.mem.Allocator, params: []const ast.Param) !Ctx {
    var names: std.ArrayListUnmanaged([]const u8) = .empty;
    var indices: std.ArrayListUnmanaged(usize) = .empty;
    for (params, 0..) |p, i| if (p.exprWrapped) {
        try names.append(arena, p.name);
        try indices.append(arena, i);
    };
    return .{ .arena = arena, .names = names.items, .indices = indices.items, .failArg = false };
}

fn indexOf(ctx: *const Ctx, e: ast.Expr) ?usize {
    if (e != .identifier or e.identifier.kind != .ident) return null;
    for (ctx.names, 0..) |n, i| if (std.mem.eql(u8, n, e.identifier.kind.ident)) return i;
    return null;
}

/// A deep copy of `v` with the reads erased. Strings are shared.
fn clone(comptime T: type, ctx: *Ctx, v: T) error{OutOfMemory}!T {
    if (T == ast.Expr) {
        // `decl.addMember(name, fn…)` → `decl.addMember(name, <k>)` (370 (2)).
        if (ctx.declName) |dn| if (memberFn.asCall(v, dn)) |mc| {
            var out = v;
            const c = v.call.kind.call;
            const args = try ctx.arena.alloc(ast.CallArg, 2);
            args[0] = c.args[0];
            args[0].value = try clone(*ast.Expr, ctx, mc.name);
            const idx = try ctx.arena.create(ast.Expr);
            idx.* = .{ .literal = .{ .loc = mc.loc, .kind = .{ .numberLit = try std.fmt.allocPrint(ctx.arena, "{d}", .{ctx.members}) } } };
            ctx.members += 1;
            args[1] = .{ .label = c.args[1].label, .value = idx };
            out.call.kind.call.args = args;
            return out;
        };
        // `x.value` → `x`.
        if (v == .identifier and v.identifier.kind == .identAccess) {
            const ia = v.identifier.kind.identAccess;
            if (!ia.optional and std.mem.eql(u8, ia.member, "value") and indexOf(ctx, ia.receiver.*) != null) return ia.receiver.*;
        }
        // `x.fail(m)` → `__bp_failArg(j, m)` in a decorator body.
        if (ctx.failArg and v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (c.receiver) |r| if (std.mem.eql(u8, c.callee, "fail")) if (indexOf(ctx, r.*)) |k| {
                var out = v;
                const args = try ctx.arena.alloc(ast.CallArg, c.args.len + 1);
                const idx = try ctx.arena.create(ast.Expr);
                idx.* = .{ .literal = .{ .loc = v.call.loc, .kind = .{ .numberLit = try std.fmt.allocPrint(ctx.arena, "{d}", .{ctx.indices[k]}) } } };
                args[0] = .{ .label = null, .value = idx };
                for (c.args, 1..) |a, i| args[i] = try clone(ast.CallArg, ctx, a);
                out.call.kind.call.receiver = null;
                out.call.kind.call.callee = fail_arg_fn;
                out.call.kind.call.args = args;
                out.call.kind.call.trailing = try clone(@TypeOf(c.trailing), ctx, c.trailing);
                return out;
            };
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
                for (v, 0..) |item, i| out[i] = try clone(ptr.child, ctx, item);
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

/// How a body uses the parameter `name`.
pub const Use = struct {
    /// `name` is read other than as the receiver of `.fail(…)`: its value is
    /// needed while the body runs (decision 364 (2)).
    reads: bool = false,
    /// `name.value` is written.
    value: bool = false,
};

/// How `f`'s body uses its parameter `name`.
/// A read inside a member function a decorator hands to `decl.addMember(name,
/// fn…)` is the program's, at run time (decision 370 (2)): it is not a use.
pub fn useOf(f: ast.FnDecl, name: []const u8) Use {
    var u: Use = .{};
    walk([]ast.Stmt, name, memberFn.declParamName(f), f.body, &u);
    return u;
}

fn walk(comptime T: type, name: []const u8, declName: ?[]const u8, v: T, u: *Use) void {
    if (T == ast.Expr) {
        if (declName) |dn| if (memberFn.asCall(v, dn)) |mc| {
            walk(ast.Expr, name, declName, mc.name.*, u);
            return;
        };
        if (v == .identifier) switch (v.identifier.kind) {
            .ident => |n| if (std.mem.eql(u8, n, name)) {
                u.reads = true;
                return;
            },
            .identAccess => |ia| if (std.mem.eql(u8, ia.member, "value") and isName(ia.receiver.*, name)) {
                u.reads = true;
                u.value = true;
                return;
            },
            else => {},
        };
        if (v == .call and v.call.kind == .call) {
            const c = v.call.kind.call;
            if (c.receiver) |r| if (std.mem.eql(u8, c.callee, "fail") and isName(r.*, name)) {
                walk(@TypeOf(c.args), name, declName, c.args, u);
                walk(@TypeOf(c.trailing), name, declName, c.trailing, u);
                return;
            };
        }
    }
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => walk(ptr.child, name, declName, v.*, u),
            .slice => {
                if (ptr.child == u8) return;
                for (v) |item| walk(ptr.child, name, declName, item, u);
            },
            else => {},
        },
        .optional => |o| if (v) |x| walk(o.child, name, declName, x, u),
        .@"struct" => |st| inline for (st.fields) |f| {
            if (!f.is_comptime) walk(f.type, name, declName, @field(v, f.name), u);
        },
        .@"union" => |un| {
            if (un.tag_type == null) return;
            switch (v) {
                inline else => |payload| walk(@TypeOf(payload), name, declName, payload, u),
            }
        },
        else => {},
    }
}

fn isName(e: ast.Expr, name: []const u8) bool {
    return e == .identifier and e.identifier.kind == .ident and std.mem.eql(u8, e.identifier.kind.ident, name);
}

test "`x.value` is `x`, and a decorator's `x.fail(m)` names its argument" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    const format = @import("../format.zig");
    var lx = lexer.Lexer.init(
        \\fn setting(comptime decl: @Decl, comptime key: @Expr<string>, comptime n: @Expr<i32>) {
        \\    if (key.value == "") n.fail("empty");
        \\    decl.setMeta("key", key.value + n.value.toString());
        \\}
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    const erased = try eraseFn(arena, program.decls[0].@"fn", true);
    var f = format.Formatter.init(arena);
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    for (erased.body) |st| {
        try buf.appendSlice(arena, try format.render(arena, try f.fmtExpr(st.expr), 200));
        try buf.append(arena, '\n');
    }
    const text = buf.items;
    try std.testing.expect(std.mem.indexOf(u8, text, "key == \"\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "__bp_failArg(1, \"empty\")") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "key + n.toString()") != null);
}

test "a body's use of a parameter: read, `.value`, `.fail` only" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn d(comptime decl: @Decl, comptime a: @Expr<string>, comptime b: @Expr<string>, comptime c: @Expr<string>) {
        \\    decl.setMeta("a", a.value);
        \\    if (decl.name == "") b.fail("no");
        \\}
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const f = (try p.parse(arena)).decls[0].@"fn";
    try std.testing.expect(useOf(f, "a").reads and useOf(f, "a").value);
    try std.testing.expect(!useOf(f, "b").reads);
    try std.testing.expect(!useOf(f, "c").reads);
}
