//! Decision 370 (2) — a decorator hands a parameter's `@Expr` on to the program
//! through a typed member:
//!
//!     decl.addMember("validate", fn(self: T) -> Violation[] {
//!         if (rule(self)) return [];
//!         return [Violation(field: "confirm", message: message)];
//!     });
//!
//! The second argument is a function expression written at the call, typed
//! (`parser/exprs.zig`). The checker types it in the decorator's module with
//! each `comptime x: @Expr<T>` parameter read as a `T` (`infer.zig`
//! `inferMemberFnCall`); the decorator body runs on the comptime runtime with
//! the function replaced by its index here (`expr_param.zig` `eraseFn`), the
//! prelude's `addMember/3` hands the name and the index back
//! (`decorator_eval.Contribution.memberFn`), and `infer.zig`
//! `runDeclDecorators` renders the member the type receives — `pub fn
//! <name>(…) -> R { … }`, each parameter's argument spliced where the body
//! uses it, written as the annotation wrote it, and the decorator's type
//! parameters spelled as the annotation bound them (`render`). The member then
//! joins the type exactly as a `decl.addMember(source)` one does
//! (`comptime.zig` `mergeMembers`).
const std = @import("std");
const ast = @import("../ast.zig");
const format = @import("../format.zig");

/// The name a decorator body's `addMember` is written with.
pub const add_member = "addMember";

/// One `<decl>.addMember(<name>, <fn expression>)` call.
pub const Call = struct {
    name: *ast.Expr,
    func: ast.FunctionExpr,
    /// The function expression's own location.
    loc: ast.Loc,
};

/// `e` as `<declName>.addMember(<name>, <fn expression>)`; null for any other
/// node (a one-argument `addMember(source)` included).
pub fn asCall(e: ast.Expr, declName: []const u8) ?Call {
    if (e != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (!isAddMemberOn(c, declName) or c.args.len != 2) return null;
    const f = c.args[1].value.*;
    if (f != .function or f.function.kind.syntax != .fnExpr) return null;
    return .{ .name = c.args[0].value, .func = f.function, .loc = f.function.loc };
}

/// Whether `c` is `<declName>.addMember(…)`.
pub fn isAddMemberOn(c: anytype, declName: []const u8) bool {
    const r = c.receiver orelse return false;
    if (r.* != .identifier or r.identifier.kind != .ident) return false;
    return std.mem.eql(u8, r.identifier.kind.ident, declName) and std.mem.eql(u8, c.callee, add_member) and !c.is_builtin;
}

/// The `@Decl` parameter's name of a decorator, null for any other function.
pub fn declParamName(f: ast.FnDecl) ?[]const u8 {
    if (f.params.len == 0) return null;
    const p = f.params[0];
    return if (p.modifier == .@"comptime" and p.typeRef.isDeclType()) p.name else null;
}

// ── the member functions of a body, in order ────────────────────────────────

/// Every member function `f`'s body hands to `decl.addMember`, in the order
/// `expr_param.eraseFn` numbers them: a pre-order walk, the name argument
/// before the function.
pub fn collect(arena: std.mem.Allocator, f: ast.FnDecl, declName: []const u8) ![]const ast.FunctionExpr {
    var out: std.ArrayListUnmanaged(ast.FunctionExpr) = .empty;
    var c: Collector = .{ .arena = arena, .declName = declName, .out = &out };
    try c.walk([]ast.Stmt, f.body);
    return out.items;
}

const Collector = struct {
    arena: std.mem.Allocator,
    declName: []const u8,
    out: *std.ArrayListUnmanaged(ast.FunctionExpr),

    fn walk(self: *Collector, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (asCall(v, self.declName)) |mc| {
            try self.walk(ast.Expr, mc.name.*);
            try self.out.append(self.arena, mc.func);
            return;
        };
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// Whether a value of `T` can reach an `ast.Expr` — prunes strings,
/// locations and type references.
fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

// ── the names a function binds and reads ────────────────────────────────────

/// A name a member function reads, where it reads it.
pub const Name = struct { name: []const u8, loc: ast.Loc };

/// Every name `body` (with `params`) binds: the parameters, each `val` /
/// `var`, the parameters of every lambda, loop and trailing block, each
/// destructured and each pattern-bound name.
pub fn boundNames(arena: std.mem.Allocator, params: []const []const u8, body: []const ast.Stmt) !std.StringHashMapUnmanaged(void) {
    var set: std.StringHashMapUnmanaged(void) = .empty;
    for (params) |p| try set.put(arena, p, {});
    var b: Binder = .{ .arena = arena, .set = &set };
    try b.walk([]const ast.Stmt, body);
    return set;
}

const Binder = struct {
    arena: std.mem.Allocator,
    set: *std.StringHashMapUnmanaged(void),

    fn add(self: *Binder, n: []const u8) !void {
        if (n.len == 0 or std.mem.indexOfScalar(u8, n, '.') != null) return;
        try self.set.put(self.arena, n, {});
    }

    fn walk(self: *Binder, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) if (v == .binding and v.binding.kind == .localBind) try self.add(v.binding.kind.localBind.name);
        if (T == ast.FieldDestruct) return self.add(v.bind_name);
        if (T == ast.ParamDestruct) if (v == .tuple_) for (v.tuple_) |n| try self.add(n);
        if (T == ast.Pattern) switch (v) {
            .ident => |n| try self.add(n),
            .variant => |vr| switch (vr.payload) {
                .binding => |n| try self.add(n),
                .fields => |fs| for (fs) |n| try self.add(n),
                .literals => {},
            },
            .list => |l| if (l.spread) |s| try self.add(s),
            else => {},
        };
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => if (ptr.child != u8) for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (fl.is_comptime) continue;
                // `params` of a lambda, a fn expression, a loop, a trailing block.
                if (comptime std.mem.eql(u8, fl.name, "params") and fl.type == []const []const u8) {
                    for (@field(v, fl.name)) |n| try self.add(n);
                } else if (comptime T != ast.Loc and T != ast.TypeRef) {
                    try self.walk(fl.type, @field(v, fl.name));
                }
            },
            .@"union" => |un| if (un.tag_type != null and T != ast.TypeRef) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// The names `func` reads without binding them itself: each identifier and
/// each callee written without a receiver, in source order (duplicates kept).
pub fn freeNames(arena: std.mem.Allocator, func: ast.FunctionExpr) ![]const Name {
    const bound = try boundNames(arena, func.kind.params, func.kind.body);
    var out: std.ArrayListUnmanaged(Name) = .empty;
    var r: Reader = .{ .arena = arena, .bound = &bound, .out = &out };
    try r.walk([]const ast.Stmt, func.kind.body);
    return out.items;
}

const Reader = struct {
    arena: std.mem.Allocator,
    bound: *const std.StringHashMapUnmanaged(void),
    out: *std.ArrayListUnmanaged(Name),

    fn note(self: *Reader, n: []const u8, loc: ast.Loc) !void {
        if (self.bound.contains(n)) return;
        try self.out.append(self.arena, .{ .name = n, .loc = loc });
    }

    fn walk(self: *Reader, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.Expr) switch (v) {
            .identifier => |id| if (id.kind == .ident) try self.note(id.kind.ident, id.loc),
            .call => |c| if (c.kind == .call) {
                const cc = c.kind.call;
                if (cc.receiver == null and cc.calleeExpr == null and !cc.is_builtin and cc.callee.len > 0) try self.note(cc.callee, c.loc);
            },
            else => {},
        };
        if (comptime !mayHoldExpr(T)) return;
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

/// Every type name `func` writes — its parameters', its return's and the
/// annotations of its body (`val x: T`, `x is T`) — each a `TypeRef.named`
/// or a generic's head.
pub fn typeNames(arena: std.mem.Allocator, func: ast.FunctionExpr) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (func.kind.paramTypes) |t| try typeRefNames(arena, t, &out);
    if (func.kind.returnType) |t| try typeRefNames(arena, t, &out);
    var w: TypeWalker = .{ .arena = arena, .out = &out };
    try w.walk([]const ast.Stmt, func.kind.body);
    return out.items;
}

fn typeRefNames(arena: std.mem.Allocator, t: ast.TypeRef, out: *std.ArrayListUnmanaged([]const u8)) !void {
    switch (t) {
        .named => |n| try out.append(arena, n),
        .array => |a| try typeRefNames(arena, a.*, out),
        .optional => |o| try typeRefNames(arena, o.*, out),
        .tuple_ => |ts| for (ts) |x| try typeRefNames(arena, x, out),
        .labeledTuple => |lt| for (lt.elems) |x| try typeRefNames(arena, x, out),
        .function => |f| {
            for (f.params) |x| try typeRefNames(arena, x, out);
            try typeRefNames(arena, f.returnType.*, out);
        },
        .generic => |g| {
            if (!g.is_builtin) try out.append(arena, g.name);
            for (g.args) |x| try typeRefNames(arena, x, out);
        },
        .typeparam => |ts| for (ts) |x| try typeRefNames(arena, x, out),
    }
}

const TypeWalker = struct {
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged([]const u8),

    fn walk(self: *TypeWalker, comptime T: type, v: T) std.mem.Allocator.Error!void {
        if (T == ast.TypeRef) return typeRefNames(self.arena, v, self.out);
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => if (@typeInfo(ptr.child) != .@"fn" and @typeInfo(ptr.child) != .@"opaque") try self.walk(ptr.child, v.*),
                .slice => if (ptr.child != u8) for (v) |item| try self.walk(ptr.child, item),
                else => {},
            },
            .optional => |o| if (v) |x| try self.walk(o.child, x),
            .@"struct" => |st| if (T != ast.Loc) inline for (st.fields) |fl| {
                if (!fl.is_comptime) try self.walk(fl.type, @field(v, fl.name));
            },
            .@"union" => |un| if (un.tag_type != null) switch (v) {
                inline else => |payload| try self.walk(@TypeOf(payload), payload),
            },
            else => {},
        }
    }
};

// ── the member the type receives ─────────────────────────────────────────────

/// A decorator parameter the member reads, and the expression its argument is
/// as the annotation wrote it (a default as the decorator declared it).
pub const Splice = struct { param: []const u8, lexeme: []const u8 };

/// A decorator type parameter and its spelling at this annotation.
pub const TypeArg = struct { name: []const u8, spelled: []const u8 };

const placeholder_prefix = "__bp_member_arg_";

/// The member `func` becomes on the type: `pub fn <name>(<params>) -> R { … }`,
/// each read of a spliced parameter replaced by its argument — bare when the
/// argument is one name, parenthesised otherwise — and each type parameter by
/// its spelling (`Self` when it is the owner itself).
pub fn render(
    arena: std.mem.Allocator,
    name: []const u8,
    func: ast.FunctionExpr,
    splices: []const Splice,
    typeArgs: []const TypeArg,
    owner: []const u8,
) ![]const u8 {
    const bound = try boundNames(arena, func.kind.params, func.kind.body);
    var sub: Substitution = .{ .arena = arena, .splices = splices, .typeArgs = typeArgs, .owner = owner, .bound = &bound };
    var f = func;
    f.kind.body = try sub.clone([]ast.Stmt, func.kind.body);
    const pts = try arena.alloc(ast.TypeRef, func.kind.paramTypes.len);
    for (func.kind.paramTypes, 0..) |t, i| pts[i] = try sub.typeRef(t);
    f.kind.paramTypes = pts;
    f.kind.returnType = if (func.kind.returnType) |t| try sub.typeRef(t) else null;

    var fm = format.Formatter.init(arena);
    const text = try format.render(arena, try fm.fmtExpr(.{ .function = f }), std.math.maxInt(u16));
    if (!std.mem.startsWith(u8, text, "fn(")) return error.OutOfMemory;
    var out: std.ArrayListUnmanaged(u8) = .empty;
    try out.print(arena, "pub fn {s}", .{name});
    var rest = text[2..];
    while (std.mem.indexOf(u8, rest, placeholder_prefix)) |at| {
        try out.appendSlice(arena, rest[0..at]);
        const tail = rest[at + placeholder_prefix.len ..];
        const end = std.mem.indexOf(u8, tail, "__") orelse return error.OutOfMemory;
        const j = std.fmt.parseInt(usize, tail[0..end], 10) catch return error.OutOfMemory;
        const lexeme = std.mem.trim(u8, splices[j].lexeme, " \t\r\n");
        if (isOneName(lexeme)) {
            try out.appendSlice(arena, lexeme);
        } else {
            try out.append(arena, '(');
            try out.appendSlice(arena, lexeme);
            try out.append(arena, ')');
        }
        rest = tail[end + 2 ..];
    }
    try out.appendSlice(arena, rest);
    return out.items;
}

fn isOneName(s: []const u8) bool {
    if (s.len == 0 or !(std.ascii.isAlphabetic(s[0]) or s[0] == '_')) return false;
    for (s) |ch| if (!(std.ascii.isAlphanumeric(ch) or ch == '_')) return false;
    return true;
}

const Substitution = struct {
    arena: std.mem.Allocator,
    splices: []const Splice,
    typeArgs: []const TypeArg,
    owner: []const u8,
    bound: *const std.StringHashMapUnmanaged(void),

    fn spliceIndex(self: *const Substitution, n: []const u8) ?usize {
        if (self.bound.contains(n)) return null;
        for (self.splices, 0..) |s, i| if (std.mem.eql(u8, s.param, n)) return i;
        return null;
    }

    fn placeholder(self: *const Substitution, j: usize) ![]const u8 {
        return std.fmt.allocPrint(self.arena, placeholder_prefix ++ "{d}__", .{j});
    }

    fn typeRef(self: *Substitution, t: ast.TypeRef) error{OutOfMemory}!ast.TypeRef {
        switch (t) {
            .named => |n| {
                for (self.typeArgs) |ta| if (std.mem.eql(u8, ta.name, n)) {
                    return .{ .named = if (std.mem.eql(u8, ta.spelled, self.owner)) "Self" else ta.spelled };
                };
                return t;
            },
            .array => |a| {
                const p = try self.arena.create(ast.TypeRef);
                p.* = try self.typeRef(a.*);
                return .{ .array = p };
            },
            .optional => |o| {
                const p = try self.arena.create(ast.TypeRef);
                p.* = try self.typeRef(o.*);
                return .{ .optional = p };
            },
            .tuple_ => |ts| return .{ .tuple_ = try self.typeRefs(ts) },
            .labeledTuple => |lt| return .{ .labeledTuple = .{ .elems = try self.typeRefs(lt.elems), .labels = lt.labels } },
            .function => |f| {
                const r = try self.arena.create(ast.TypeRef);
                r.* = try self.typeRef(f.returnType.*);
                return .{ .function = .{ .params = try self.typeRefs(f.params), .returnType = r, .paramNames = f.paramNames } };
            },
            .generic => |g| return .{ .generic = .{ .name = g.name, .args = try self.typeRefs(g.args), .is_builtin = g.is_builtin } },
            .typeparam => return t,
        }
    }

    fn typeRefs(self: *Substitution, ts: []ast.TypeRef) error{OutOfMemory}![]ast.TypeRef {
        const out = try self.arena.alloc(ast.TypeRef, ts.len);
        for (ts, 0..) |x, i| out[i] = try self.typeRef(x);
        return out;
    }

    /// A deep copy of `v`, each spliced read and each type parameter replaced.
    fn clone(self: *Substitution, comptime T: type, v: T) error{OutOfMemory}!T {
        if (T == ast.TypeRef) return self.typeRef(v);
        if (T == ast.Expr) switch (v) {
            .identifier => |id| if (id.kind == .ident) if (self.spliceIndex(id.kind.ident)) |j| {
                var out = v;
                out.identifier.kind = .{ .ident = try self.placeholder(j) };
                return out;
            },
            .call => |c| if (c.kind == .call) {
                const cc = c.kind.call;
                if (cc.receiver == null and cc.calleeExpr == null and !cc.is_builtin) if (self.spliceIndex(cc.callee)) |j| {
                    var out = v;
                    out.call.kind.call.callee = try self.placeholder(j);
                    out.call.kind.call.args = try self.clone(@TypeOf(cc.args), cc.args);
                    out.call.kind.call.trailing = try self.clone(@TypeOf(cc.trailing), cc.trailing);
                    return out;
                };
            },
            else => {},
        };
        switch (@typeInfo(T)) {
            .pointer => |ptr| switch (ptr.size) {
                .one => {
                    if (@typeInfo(ptr.child) == .@"fn" or @typeInfo(ptr.child) == .@"opaque") return v;
                    const p = try self.arena.create(ptr.child);
                    p.* = try self.clone(ptr.child, v.*);
                    return p;
                },
                .slice => {
                    if (ptr.child == u8) return v;
                    const out = try self.arena.alloc(ptr.child, v.len);
                    for (v, 0..) |item, i| out[i] = try self.clone(ptr.child, item);
                    return out;
                },
                else => return v,
            },
            .optional => |o| return if (v) |x| try self.clone(o.child, x) else null,
            .@"struct" => |s| {
                if (T == ast.Loc) return v;
                var out = v;
                inline for (s.fields) |fl| {
                    if (fl.is_comptime) continue;
                    @field(out, fl.name) = try self.clone(fl.type, @field(v, fl.name));
                }
                return out;
            },
            .@"union" => |u| {
                if (u.tag_type == null) return v;
                switch (v) {
                    inline else => |payload, tag| return @unionInit(T, @tagName(tag), try self.clone(@TypeOf(payload), payload)),
                }
            },
            else => return v,
        }
    }
};

test "a member function: collected in order, its free names, rendered with each argument spliced" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const lexer = @import("../lexer.zig");
    const parser = @import("../parser.zig");
    var lx = lexer.Lexer.init(
        \\fn check<T>(comptime decl: @Decl<T>, comptime message: @Expr<string>, comptime rule: @Expr<fn(v: T) -> bool>) {
        \\    val unused = 1;
        \\    decl.addMember("validate", fn(self: T) -> Violation[] {
        \\        if (rule(self)) return [];
        \\        val m = message;
        \\        return [Violation(field: "confirm", message: m)];
        \\    });
        \\}
    );
    var p = parser.Parser.init(try lx.scanAll(arena));
    const f = (try p.parse(arena)).decls[0].@"fn";
    try std.testing.expectEqualStrings("decl", declParamName(f).?);
    const found = try collect(arena, f, "decl");
    try std.testing.expectEqual(@as(usize, 1), found.len);

    const free = try freeNames(arena, found[0]);
    var names: std.ArrayListUnmanaged(u8) = .empty;
    for (free) |n| try names.print(arena, "{s} ", .{n.name});
    try std.testing.expectEqualStrings("rule message Violation ", names.items);

    const text = try render(arena, "validate", found[0], &.{
        .{ .param = "message", .lexeme = "t(\"signup.mismatch\")" },
        .{ .param = "rule", .lexeme = "passwordsMatch" },
    }, &.{.{ .name = "T", .spelled = "Signup" }}, "Signup");
    try std.testing.expect(std.mem.startsWith(u8, text, "pub fn validate(self: Self) -> Violation[] {"));
    try std.testing.expect(std.mem.indexOf(u8, text, "if (passwordsMatch(self))") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "val m = (t(\"signup.mismatch\"));") != null);
}
