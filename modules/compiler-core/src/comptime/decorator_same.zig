//! Decision 371 — `d.same(other)` on the comptime runtime. A `Decorator` is
//! carried as its declaration's identity (`env.declIdentity`, the string a
//! `DeclAnnotation.decorator` holds — `hooks.zig` `annotationsTerm`), so the
//! call is the equality of two identities: each `same` call the checker typed
//! (`Env.decoratorSame`, by the call's location) becomes `receiver == other`,
//! a decorator's name in `other` the string literal of its identity — an
//! alias and a namespace resolved where the name is written, never the
//! spelling. Applied to a decorator body and the functions of its module it
//! reaches before the body is lowered (`infer.zig` `runDeclDecorators`, and
//! `comptime.zig` `registerExports` for an importer); the declaration itself
//! is left untouched (the copy is new nodes throughout).
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("./env.zig");

pub const Calls = std.AutoHashMapUnmanaged(ast.Loc, envMod.DecoratorSame);

/// `f` with every `same` call of `calls` lowered; `f` itself when none is.
pub fn lower(arena: std.mem.Allocator, calls: *const Calls, f: ast.FnDecl) std.mem.Allocator.Error!ast.FnDecl {
    if (calls.count() == 0) return f;
    var l: Lowering = .{ .arena = arena, .calls = calls };
    const body = try l.clone(@TypeOf(f.body), f.body);
    if (!l.changed) return f;
    var out = f;
    out.body = body;
    return out;
}

/// True when `f`'s body writes a method call named `same` — the functions a
/// decorator reaches that its run needs typed first.
pub fn mentionsSame(f: ast.FnDecl) bool {
    for (f.body) |*s| if (find(ast.Stmt, s)) return true;
    return false;
}

const Lowering = struct {
    arena: std.mem.Allocator,
    calls: *const Calls,
    changed: bool = false,

    fn clone(self: *Lowering, comptime U: type, v: U) std.mem.Allocator.Error!U {
        if (U == ast.TypeRef or U == ast.Pattern) return v;
        if (U == ast.Expr) if (try self.replace(v)) |r| return r;
        switch (@typeInfo(U)) {
            .@"struct" => |s| {
                var out: U = v;
                inline for (s.fields) |fld| {
                    if (fld.is_comptime) continue;
                    if (comptime mayHoldExprs(fld.type)) @field(out, fld.name) = try self.clone(fld.type, @field(v, fld.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| {
                        const P = @TypeOf(payload);
                        if (comptime !mayHoldExprs(P)) return v;
                        return @unionInit(U, @tagName(tag), try self.clone(P, payload));
                    },
                }
            },
            .optional => |o| return if (v) |inner| try self.clone(o.child, inner) else null,
            .pointer => |p| switch (p.size) {
                .one => {
                    if (comptime !mayHoldExprs(p.child)) return v;
                    const n = try self.arena.create(p.child);
                    n.* = try self.clone(p.child, v.*);
                    return n;
                },
                .slice => {
                    if (comptime !mayHoldExprs(p.child)) return v;
                    const out = try self.arena.alloc(p.child, v.len);
                    for (v, 0..) |e, i| out[i] = try self.clone(p.child, e);
                    return out;
                },
                else => return v,
            },
            else => return v,
        }
    }

    fn replace(self: *Lowering, e: ast.Expr) std.mem.Allocator.Error!?ast.Expr {
        if (e != .call or e.call.kind != .call) return null;
        const call = e.call.kind.call;
        const same = self.calls.get(e.call.loc) orelse return null;
        const recv = call.receiver orelse return null;
        if (call.args.len != 1) return null;
        self.changed = true;
        const lhs = try self.arena.create(ast.Expr);
        lhs.* = try self.clone(ast.Expr, recv.*);
        const rhs = try self.arena.create(ast.Expr);
        rhs.* = if (same.other) |id|
            .{ .literal = .{ .loc = call.args[0].value.getLoc(), .kind = .{ .stringLit = id } } }
        else
            try self.clone(ast.Expr, call.args[0].value.*);
        return .{ .binaryOp = .{ .loc = e.call.loc, .op = .eq, .lhs = lhs, .rhs = rhs } };
    }
};

fn find(comptime X: type, ptr: *const X) bool {
    if (X == ast.Expr) {
        if (ptr.* == .call and ptr.call.kind == .call) {
            const c = ptr.call.kind.call;
            if (!c.is_builtin and c.receiver != null and std.mem.eql(u8, c.callee, "same")) return true;
        }
    }
    if (X == ast.TypeRef or X == ast.Pattern or X == ast.ImportDecl) return false;
    switch (@typeInfo(X)) {
        .@"struct" => |s| inline for (s.fields) |f| {
            if (f.is_comptime) continue;
            if (comptime mayHoldExprs(f.type)) if (find(f.type, &@field(ptr.*, f.name))) return true;
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| if (comptime mayHoldExprs(@TypeOf(payload.*))) {
                    if (find(@TypeOf(payload.*), payload)) return true;
                },
            }
        },
        .optional => |o| if (ptr.*) |*inner| return find(o.child, inner),
        .pointer => |p| switch (p.size) {
            .one => if (comptime mayHoldExprs(p.child)) return find(p.child, ptr.*),
            .slice => if (comptime mayHoldExprs(p.child)) {
                for (ptr.*) |*e| if (find(p.child, e)) return true;
            },
            else => {},
        },
        .array => |arr| if (comptime mayHoldExprs(arr.child)) {
            for (ptr) |*e| if (find(arr.child, e)) return true;
        },
        else => {},
    }
    return false;
}

fn mayHoldExprs(comptime X: type) bool {
    return switch (@typeInfo(X)) {
        .int, .float, .bool, .@"enum", .void, .comptime_int, .comptime_float, .@"fn", .@"opaque" => false,
        .pointer => |p| if (@typeInfo(p.child) == .@"fn" or @typeInfo(p.child) == .@"opaque") false else if (p.size == .slice) mayHoldExprs(p.child) else true,
        else => true,
    };
}

fn parseFn(arena: std.mem.Allocator, src: []const u8) !ast.FnDecl {
    var lx = @import("../lexer.zig").Lexer.init(src);
    const tokens = try lx.scanAll(arena);
    var p = @import("../parser.zig").Parser.init(tokens);
    const program = try p.parse(arena);
    return program.decls[0].@"fn";
}

test "decorator_same: a recorded same call becomes == of two identities" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const a = arena_state.allocator();
    const f = try parseFn(a,
        \\fn d(x: i32) -> bool {
        \\    return x.same(y);
        \\}
    );
    try std.testing.expect(mentionsSame(f));
    var calls: Calls = .empty;
    // Nothing recorded: the function is left as it is.
    try std.testing.expectEqual(f.body.ptr, (try lower(a, &calls, f)).body.ptr);
    const ret = f.body[0].expr.jump.kind.@"return".?;
    try calls.put(a, ret.call.loc, .{ .other = "web@markers@@serverOnly" });
    const out = try lower(a, &calls, f);
    try std.testing.expect(out.body.ptr != f.body.ptr);
    const lowered = out.body[0].expr.jump.kind.@"return".?;
    try std.testing.expect(lowered.* == .binaryOp and lowered.binaryOp.op == .eq);
    try std.testing.expectEqualStrings("web@markers@@serverOnly", lowered.binaryOp.rhs.literal.kind.stringLit);
    // The declaration itself is untouched.
    try std.testing.expect(ret.* == .call);
}

test "decorator_same: a function without a same call mentions none" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const f = try parseFn(arena_state.allocator(),
        \\fn d(x: i32) -> i32 {
        \\    return x.abs();
        \\}
    );
    try std.testing.expect(!mentionsSame(f));
}
