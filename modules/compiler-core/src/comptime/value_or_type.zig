//! Decision 297 — a `comptime` parameter that takes a value or a type:
//! `fn pick<T>(comptime source: Box<T> | type T) -> …`. An argument of type
//! `Box<T>` binds `T` from it; a type argument (`pick(User)`) binds `T` to that
//! type; the body tells them apart at comptime with `source is type`.
//!
//! Run on the parsed program (`analyzeSource`, before the checker), so the
//! checker and every backend read one ordinary shape:
//!
//! - the function keeps the value form: the parameter's type is the value
//!   member (`Box<T>`), `Param.typeArgOf` names `T`, and every `source is type`
//!   is folded to `false` — an `if` on it keeps its `else` branch;
//! - a twin `<name>__type` is declared for the type form: the parameter is
//!   gone (a type has no value, so a read of `source` there is the ordinary
//!   unbound name), `source is type` is `true` and an `if` on it keeps its
//!   `then` branch. It carries no annotation (a decorator runs once).
//!
//! The checker (`infer.zig`, `typeArgCall`) types a call whose argument is a
//! type by the value form with `T` bound to it, and records the call's
//! rewrite to the twin with that argument removed; `transform.zig` splices it.

const std = @import("std");
const ast = @import("../ast.zig");

/// The suffix of the type-form twin of a function.
pub const twin_suffix = "__type";

/// The value member and the type parameter of a `comptime x: V | type T`
/// parameter (one `type T` member naming one of `generics`), else null.
pub fn shape(p: ast.Param, generics: []const ast.GenericParam) ?struct { value: ast.TypeRef, typeParam: []const u8 } {
    if (p.modifier != .@"comptime") return null;
    const members = p.typeRef.unionMembers() orelse return null;
    var tp: ?[]const u8 = null;
    var value: ?ast.TypeRef = null;
    var values: usize = 0;
    for (members) |m| switch (m) {
        .typeparam => |cs| {
            if (cs.len != 1 or cs[0] != .named or tp != null) return null;
            tp = cs[0].named;
        },
        else => {
            value = m;
            values += 1;
        },
    };
    const t = tp orelse return null;
    if (values != 1) return null;
    for (generics) |g| if (std.mem.eql(u8, g.name, t)) return .{ .value = value.?, .typeParam = t };
    return null;
}

const Ctx = struct {
    arena: std.mem.Allocator,
    /// The parameter `x` of `x is type`.
    param: []const u8,
    /// What `x is type` answers in this copy.
    isType: bool,
};

/// `program` with each top-level function that has a value-or-type parameter
/// rewritten to its value form, and its type-form twin added after it.
pub fn expand(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blanks: std.ArrayListUnmanaged(bool) = .empty;
    var touched = false;
    for (program.decls, 0..) |d, i| {
        const blank = if (i < program.blankLineBefore.len) program.blankLineBefore[i] else false;
        try out.append(arena, d);
        try blanks.append(arena, blank);
        if (d != .@"fn") continue;
        const f = d.@"fn";
        const at, const sh = for (f.params, 0..) |p, pi| {
            if (shape(p, f.genericParams)) |s| break .{ pi, s };
        } else continue;
        touched = true;
        const pname = f.params[at].name;

        var value = f;
        value.params = try arena.dupe(ast.Param, f.params);
        value.params[at].typeRef = sh.value;
        value.params[at].typeArgOf = sh.typeParam;
        var vctx: Ctx = .{ .arena = arena, .param = pname, .isType = false };
        value.body = try cloneValue([]ast.Stmt, &vctx, f.body);
        out.items[out.items.len - 1] = .{ .@"fn" = value };

        var twin = f;
        twin.name = try std.fmt.allocPrint(arena, "{s}{s}", .{ f.name, twin_suffix });
        twin.annotations = &.{};
        twin.isDefault = false;
        twin.anonymousDefault = false;
        twin.defaultBy = null;
        const tparams = try arena.alloc(ast.Param, f.params.len - 1);
        @memcpy(tparams[0..at], f.params[0..at]);
        @memcpy(tparams[at..], f.params[at + 1 ..]);
        twin.params = tparams;
        var tctx: Ctx = .{ .arena = arena, .param = pname, .isType = true };
        twin.body = try cloneValue([]ast.Stmt, &tctx, f.body);
        try out.append(arena, .{ .@"fn" = twin });
        try blanks.append(arena, true);
    }
    if (!touched) return program;
    var result = program;
    result.decls = try out.toOwnedSlice(arena);
    result.blankLineBefore = try blanks.toOwnedSlice(arena);
    return result;
}

/// The transformed program's imports with each item that binds a function
/// `twins` names (a call of this module passed it a type) followed by its type
/// form: `import {m.pick};` → `import {m.pick, m.pick__type};`, an alias
/// aliased the same way (`pick as p` → `pick__type as p__type`).
pub fn withTwinImports(arena: std.mem.Allocator, program: ast.Program, twins: *const std.StringHashMapUnmanaged(void)) !ast.Program {
    if (twins.count() == 0) return program;
    var decls: ?[]ast.DeclKind = null;
    for (program.decls, 0..) |d, di| {
        if (d != .use) continue;
        var items: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
        var added = false;
        for (d.use.imports) |imp| {
            try items.append(arena, imp);
            if (imp.activate or !twins.contains(imp.name())) continue;
            var twin = imp;
            const segs = try arena.dupe([]const u8, imp.segments);
            segs[segs.len - 1] = try std.fmt.allocPrint(arena, "{s}{s}", .{ imp.leaf(), twin_suffix });
            twin.segments = segs;
            if (imp.alias) |al| twin.alias = try std.fmt.allocPrint(arena, "{s}{s}", .{ al, twin_suffix });
            try items.append(arena, twin);
            added = true;
        }
        if (!added) continue;
        if (decls == null) decls = try arena.dupe(ast.DeclKind, program.decls);
        decls.?[di].use.imports = try items.toOwnedSlice(arena);
    }
    var out = program;
    if (decls) |ds| out.decls = ds;
    return out;
}

/// A statement list, with a guard on the test folded: `if (x is type) { … }`
/// with no `else` is dropped where the test is false, and where it is true its
/// statements take its place — the rest of the list too when they end in a
/// `return` / `throw` (what follows is unreachable, and may read `x`).
fn cloneStmts(ctx: *Ctx, stmts: []ast.Stmt) error{OutOfMemory}![]ast.Stmt {
    var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;
    for (stmts) |st| {
        const e = st.expr;
        if (e == .branch and e.branch.kind == .if_ and e.branch.kind.if_.else_ == null and isTypeTest(ctx, e.branch.kind.if_.cond.*)) {
            if (!ctx.isType) continue;
            const then_ = e.branch.kind.if_.then_;
            for (then_) |inner| try out.append(ctx.arena, try cloneValue(ast.Stmt, ctx, inner));
            if (then_.len > 0 and endsInExit(then_[then_.len - 1].expr)) break;
            continue;
        }
        try out.append(ctx.arena, try cloneValue(ast.Stmt, ctx, st));
    }
    return out.toOwnedSlice(ctx.arena);
}

fn endsInExit(e: ast.Expr) bool {
    if (e != .jump) return false;
    return switch (e.jump.kind) {
        .@"return", .throw_ => true,
        else => false,
    };
}

/// `x is type` for the context's parameter `x`.
fn isTypeTest(ctx: *const Ctx, e: ast.Expr) bool {
    if (e != .call or e.call.kind != .call) return false;
    const c = e.call.kind.call;
    if (!c.is_builtin or !std.mem.eql(u8, c.callee, ast.is_builtin_name)) return false;
    const tested = c.isType orelse return false;
    if (tested != .typeparam or tested.typeparam.len != 0) return false;
    if (c.args.len != 1) return false;
    const subject = c.args[0].value.*;
    return subject == .identifier and subject.identifier.kind == .ident and
        std.mem.eql(u8, subject.identifier.kind.ident, ctx.param);
}

fn boolIdent(loc: ast.Loc, v: bool) ast.Expr {
    return .{ .identifier = .{ .loc = loc, .kind = .{ .ident = if (v) "true" else "false" } } };
}

/// A deep copy of `v`, with the context's `x is type` folded: the test itself
/// becomes `true` / `false`, and an `if` on it keeps only the branch taken (the
/// other branch is that branch again, so an `if` used as a value keeps its
/// type; an `if` with no `else` whose `then` is not taken gets an empty one).
/// Strings are shared.
fn cloneValue(comptime T: type, ctx: *Ctx, v: T) error{OutOfMemory}!T {
    if (T == []ast.Stmt) return cloneStmts(ctx, v);
    if (T == ast.Expr) {
        if (isTypeTest(ctx, v)) return boolIdent(v.call.loc, ctx.isType);
        if (v == .branch and v.branch.kind == .if_) {
            const node = v.branch.kind.if_;
            if (isTypeTest(ctx, node.cond.*)) {
                var out = v;
                const cond = try ctx.arena.create(ast.Expr);
                cond.* = boolIdent(node.cond.getLoc(), ctx.isType);
                const written = if (ctx.isType) node.then_ else (node.else_ orelse node.then_[0..0]);
                const taken = try cloneValue([]ast.Stmt, ctx, written);
                out.branch.kind.if_ = .{
                    .cond = cond,
                    .binding = node.binding,
                    .then_ = taken,
                    .else_ = if (node.else_ != null) try cloneValue([]ast.Stmt, ctx, taken) else null,
                };
                return out;
            }
        }
    }
    switch (@typeInfo(T)) {
        .pointer => |ptr| switch (ptr.size) {
            .one => {
                const p = try ctx.arena.create(ptr.child);
                p.* = try cloneValue(ptr.child, ctx, v.*);
                return p;
            },
            .slice => {
                if (ptr.child == u8) return v;
                const out = try ctx.arena.alloc(ptr.child, v.len);
                for (v, 0..) |item, i| out[i] = try cloneValue(ptr.child, ctx, item);
                return out;
            },
            else => return v,
        },
        .optional => |o| return if (v) |x| try cloneValue(o.child, ctx, x) else null,
        .@"struct" => |s| {
            var out = v;
            inline for (s.fields) |f| {
                if (f.is_comptime) continue;
                @field(out, f.name) = try cloneValue(f.type, ctx, @field(v, f.name));
            }
            return out;
        },
        .@"union" => |u| {
            if (u.tag_type == null) return v;
            switch (v) {
                inline else => |payload, tag| return @unionInit(T, @tagName(tag), try cloneValue(@TypeOf(payload), ctx, payload)),
            }
        },
        else => return v,
    }
}

test "the value form folds `x is type` to false and keeps the else branch" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\type Box<T>(value: T)
        \\fn pick<T>(comptime s: Box<T> | type T) -> string {
        \\    return if (s is type) "type" else "value";
        \\}
    );
    const tokens = try lx.scanAll(arena);
    var p = parser.Parser.init(tokens);
    const program = try expand(arena, try p.parse(arena));
    try std.testing.expectEqual(@as(usize, 3), program.decls.len);
    const value = program.decls[1].@"fn";
    try std.testing.expectEqualStrings("T", value.params[0].typeArgOf.?);
    try std.testing.expect(value.params[0].typeRef == .generic);
    const twin = program.decls[2].@"fn";
    try std.testing.expectEqualStrings("pick__type", twin.name);
    try std.testing.expectEqual(@as(usize, 0), twin.params.len);
}
