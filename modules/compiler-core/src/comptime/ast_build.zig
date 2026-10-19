//! Decision 625 (2) — `compiler.ast(node)`: code built from a tree of
//! `compiler.Node` records (`libs/std/src/compiler.bp`), never from text.
//!
//! The template body runs on the comptime runtime, where a record is the map
//! of its fields; the reply encodes the tree as JSON (`{"kind":"ast",
//! "node":…}`, `template_eval.Outcome.ast`), each record an object of its
//! fields. A kind is read by its field set — each `Node` record declares a
//! set no other kind has (`kinds`, held to `compiler.bp` by a unit test):
//!
//!   Name(name)                  identifier
//!   Lit(value)                  the value's literal (`Ctx.lit`)
//!   Member(target, member)      `target.member`
//!   Call(callee, args)          a call; `callee` a `Name` (a plain call), a
//!                               `Member` (a method call) or any node; each
//!                               argument a node or an `Arg`
//!   Arg(name, value)            a labelled argument, only in `Call.args`
//!   List(items)                 `[…]`
//!   Tuple(elems)                `#(…)`
//!   Binary(op, lhs, rhs)        `lhs op rhs`
//!   Unary(op, operand)          `-x`, `!x`
//!   If(cond, then, otherwise)   `if (cond) then else otherwise`
//!   Lambda(params, body)        `{ a, b -> body }`
//!   Syntax(e)                   a `syntax` value's code, as written
//!                               (decision 638; `Ctx.syntax`)
//!   Fn(params, ret, body)       `fn(a: A) -> R { … }`, typed (decision 753)
//!   FnParam(name, annotation)   a parameter of a `Fn`, only in `Fn.params`
//!   Return(result)              `return result`
//!
//! and the type nodes (decision 753), each only where a type is written — an
//! `FnParam`'s annotation, a `Fn`'s `ret`, inside another type node
//! (`Builder.typeRef`): `NamedType(named)`, `ArrayType(elem)`,
//! `TupleType(types)`, `LabeledTupleType(types, labels)`,
//! `OptionalType(inner)`, `FnType(params, returns)`, `GenericType(name,
//! args)`, `UnionType(members)`.
//!
//! A tree that is no code is refused, naming the node (`Result.ill`). Every
//! node gets a location of its own in the expansion (`origin`'s line and
//! expansion, the column counting nodes), so no two nodes share one; `names`
//! records where each `Name` landed, so an unbound one is refused at the
//! `ast` call naming it (`infer.zig`). A `Syntax` splice is a placeholder
//! until the library's names are resolved (`splices`): the caller's code
//! keeps the caller's scope.
const std = @import("std");
const ast = @import("../ast.zig");
const parserTypes = @import("../parser/types.zig");

pub const Error = std.mem.Allocator.Error;

/// The kinds of `compiler.Node`, each with its field set (sorted).
pub const Kind = enum { Name, Lit, Member, Call, Arg, List, Tuple, Binary, Unary, If, Lambda, Syntax, Fn, FnParam, Return, NamedType, ArrayType, TupleType, LabeledTupleType, OptionalType, FnType, GenericType, UnionType };

pub const kinds = [_]struct { kind: Kind, fields: []const []const u8 }{
    .{ .kind = .Name, .fields = &.{"name"} },
    .{ .kind = .Lit, .fields = &.{"value"} },
    .{ .kind = .Member, .fields = &.{ "target", "member" } },
    .{ .kind = .Call, .fields = &.{ "callee", "args" } },
    .{ .kind = .Arg, .fields = &.{ "name", "value" } },
    .{ .kind = .List, .fields = &.{"items"} },
    .{ .kind = .Tuple, .fields = &.{"elems"} },
    .{ .kind = .Binary, .fields = &.{ "op", "lhs", "rhs" } },
    .{ .kind = .Unary, .fields = &.{ "op", "operand" } },
    .{ .kind = .If, .fields = &.{ "cond", "then", "otherwise" } },
    .{ .kind = .Lambda, .fields = &.{ "params", "body" } },
    .{ .kind = .Syntax, .fields = &.{"e"} },
    .{ .kind = .Fn, .fields = &.{ "params", "ret", "body" } },
    .{ .kind = .FnParam, .fields = &.{ "name", "annotation" } },
    .{ .kind = .Return, .fields = &.{"result"} },
    .{ .kind = .NamedType, .fields = &.{"named"} },
    .{ .kind = .ArrayType, .fields = &.{"elem"} },
    .{ .kind = .TupleType, .fields = &.{"types"} },
    .{ .kind = .LabeledTupleType, .fields = &.{ "types", "labels" } },
    .{ .kind = .OptionalType, .fields = &.{"inner"} },
    .{ .kind = .FnType, .fields = &.{ "params", "returns" } },
    .{ .kind = .GenericType, .fields = &.{ "name", "args" } },
    .{ .kind = .UnionType, .fields = &.{"members"} },
};

/// Decision 753 — whether `k` is a type node: it stands only where a type is
/// written (`Builder.typeRef`).
pub fn isTypeKind(k: Kind) bool {
    return switch (k) {
        .NamedType, .ArrayType, .TupleType, .LabeledTupleType, .OptionalType, .FnType, .GenericType, .UnionType => true,
        else => false,
    };
}

/// The kind whose field set is exactly `obj`'s keys, or null.
pub fn kindOf(obj: std.json.ObjectMap) ?Kind {
    for (kinds) |k| {
        if (k.fields.len != obj.count()) continue;
        for (k.fields) |f| {
            if (!obj.contains(f)) break;
        } else return k.kind;
    }
    return null;
}

/// A `Name` (or a `Call` whose callee is one) and where it landed.
pub const Placed = struct { loc: ast.Loc, name: []const u8 };

/// Decision 752 — a node of the tree and the location it took in the
/// expansion: a type error located there is reported at the `ast` call,
/// naming the node (`Builder.describe`).
pub const At = struct { loc: ast.Loc, node: std.json.Value };

/// Decision 752 — the node of `nodes` whose location is `loc`, or null when
/// `loc` is none of the tree's (the caller's code a `Syntax` holds keeps its
/// own).
pub fn nodeAt(nodes: []const At, loc: ast.Loc) ?std.json.Value {
    for (nodes) |n| if (n.loc.eql(loc)) return n.node;
    return null;
}

pub const Result = union(enum) {
    ok: *ast.Expr,
    /// The message naming the node that is no code.
    ill: []const u8,
};

/// The placeholder a `Syntax` splice stands as until `fill`, its index
/// appended: no module declares it, so the hygiene pass leaves it alone.
pub const splice_placeholder = "__bp_ast_syntax_";

/// Every field of every node, by type (`dsl_hygiene.zig`'s walk): each
/// placeholder identifier replaced by its splice.
fn fillIn(comptime T: type, ptr: *T, splices: []const *const ast.Expr) void {
    if (T == ast.Expr) if (ptr.* == .identifier and ptr.identifier.kind == .ident) {
        const n = ptr.identifier.kind.ident;
        if (std.mem.startsWith(u8, n, splice_placeholder)) {
            const i = std.fmt.parseInt(usize, n[splice_placeholder.len..], 10) catch return;
            if (i < splices.len) ptr.* = splices[i].*;
            return;
        }
    };
    if (comptime !mayHoldExpr(T)) return;
    switch (@typeInfo(T)) {
        .@"struct" => |st| inline for (st.fields) |f| {
            if (f.is_comptime) continue;
            fillIn(f.type, &@field(ptr.*, f.name), splices);
        },
        .@"union" => |u| if (u.tag_type != null) {
            switch (ptr.*) {
                inline else => |*payload| fillIn(@TypeOf(payload.*), payload, splices),
            }
        },
        .optional => |o| if (ptr.*) |*inner| fillIn(o.child, inner, splices),
        .pointer => |pi| switch (pi.size) {
            .one => if (@typeInfo(pi.child) != .@"fn" and @typeInfo(pi.child) != .@"opaque") {
                fillIn(pi.child, @constCast(ptr.*), splices);
            },
            .slice => for (ptr.*) |*e| fillIn(pi.child, @constCast(e), splices),
            else => {},
        },
        else => {},
    }
}

fn mayHoldExpr(comptime T: type) bool {
    return switch (@typeInfo(T)) {
        .@"struct", .@"union" => T != ast.Loc and T != ast.TypeRef,
        .optional => |o| mayHoldExpr(o.child),
        .pointer => |pi| pi.child != u8 and mayHoldExpr(pi.child),
        else => false,
    };
}

/// `ctx` answers `lit(value, loc) ?*const ast.Expr` (null: the value has no
/// literal) and `syntax(value) ?*const ast.Expr` (null: no `syntax` value).
pub fn Builder(comptime Ctx: type) type {
    return struct {
        arena: std.mem.Allocator,
        ctx: Ctx,
        origin: ast.Loc,
        count: usize = 0,
        names: std.ArrayListUnmanaged(Placed) = .empty,
        /// Every node, by the location it took (decision 752).
        placed: std.ArrayListUnmanaged(At) = .empty,
        /// The caller's code of each `Syntax`, by its placeholder's index.
        splices: std.ArrayListUnmanaged(*const ast.Expr) = .empty,
        ill: ?[]const u8 = null,

        const Self = @This();

        fn next(self: *Self, v: std.json.Value) Error!ast.Loc {
            self.count += 1;
            const loc: ast.Loc = .{ .line = self.origin.line, .col = self.origin.col + self.count - 1, .expansion = self.origin.expansion };
            try self.placed.append(self.arena, .{ .loc = loc, .node = v });
            return loc;
        }

        fn refuse(self: *Self, comptime fmt: []const u8, args: anytype) (Error || error{Ill})!noreturn {
            if (self.ill == null) self.ill = try std.fmt.allocPrint(self.arena, fmt, args);
            return error.Ill;
        }

        pub fn build(self: *Self, v: std.json.Value) Error!Result {
            const e = self.node(v) catch |err| switch (err) {
                error.Ill => return .{ .ill = self.ill.? },
                error.OutOfMemory => return error.OutOfMemory,
            };
            const p = try self.arena.create(ast.Expr);
            p.* = e;
            return .{ .ok = p };
        }

        /// Each `Syntax` placeholder of `root` written with the caller's code.
        pub fn fill(self: *Self, root: *ast.Expr) void {
            if (self.splices.items.len > 0) fillIn(ast.Expr, root, self.splices.items);
        }

        fn box(self: *Self, e: ast.Expr) Error!*ast.Expr {
            const p = try self.arena.create(ast.Expr);
            p.* = e;
            return p;
        }

        fn object(self: *Self, v: std.json.Value) (Error || error{Ill})!struct { obj: std.json.ObjectMap, kind: Kind } {
            if (v != .object) return try self.refuse("`{s}` is no `compiler.Node`", .{try self.describe(v)});
            const k = kindOf(v.object) orelse return try self.refuse("`{s}` is no `compiler.Node`: its fields are no node's", .{try self.describe(v)});
            return .{ .obj = v.object, .kind = k };
        }

        fn node(self: *Self, v: std.json.Value) (Error || error{Ill})!ast.Expr {
            const o = try self.object(v);
            const obj = o.obj;
            switch (o.kind) {
                .Name => {
                    const n = try self.identifier(obj.get("name").?, v);
                    const loc = try self.next(v);
                    try self.names.append(self.arena, .{ .loc = loc, .name = n });
                    return .{ .identifier = .{ .loc = loc, .kind = .{ .ident = n } } };
                },
                .Lit => {
                    const loc = try self.next(v);
                    const lit = self.ctx.lit(obj.get("value").?, loc) orelse
                        return try self.refuse("`{s}` holds no value known at build: write `Syntax(e)` for a `syntax` value", .{try self.describe(v)});
                    return lit.*;
                },
                .Member => {
                    const member = try self.identifier(obj.get("member").?, v);
                    const loc = try self.next(v);
                    const target = try self.box(try self.node(obj.get("target").?));
                    return .{ .identifier = .{ .loc = loc, .kind = .{ .identAccess = .{ .receiver = target, .member = member } } } };
                },
                .Call => return self.call(obj, v),
                .Arg => return try self.refuse("`{s}` is an argument outside a `Call`: an `Arg` is only an element of `Call.args`", .{try self.describe(v)}),
                .List => {
                    const loc = try self.next(v);
                    return .{ .collection = .{ .loc = loc, .kind = .{ .arrayLit = .{ .elems = try self.nodes(obj.get("items").?, v) } } } };
                },
                .Tuple => {
                    const loc = try self.next(v);
                    return .{ .collection = .{ .loc = loc, .kind = .{ .tupleLit = .{ .elems = try self.nodes(obj.get("elems").?, v) } } } };
                },
                .Binary => {
                    const opText = try self.string(obj.get("op").?, v);
                    const op = binaryOp(opText) orelse return try self.refuse("`{s}`: `{s}` is no binary operator", .{ try self.describe(v), opText });
                    const loc = try self.next(v);
                    const lhs = try self.box(try self.node(obj.get("lhs").?));
                    const rhs = try self.box(try self.node(obj.get("rhs").?));
                    return .{ .binaryOp = .{ .loc = loc, .op = op, .lhs = lhs, .rhs = rhs } };
                },
                .Unary => {
                    const opText = try self.string(obj.get("op").?, v);
                    const op: @FieldType(ast.UnaryOpExprOf(.untyped), "op") = if (std.mem.eql(u8, opText, "-")) .neg else if (std.mem.eql(u8, opText, "!")) .not else return try self.refuse("`{s}`: `{s}` is no unary operator", .{ try self.describe(v), opText });
                    const loc = try self.next(v);
                    return .{ .unaryOp = .{ .loc = loc, .op = op, .expr = try self.box(try self.node(obj.get("operand").?)) } };
                },
                .If => {
                    const loc = try self.next(v);
                    const cond = try self.box(try self.node(obj.get("cond").?));
                    const then_ = try self.arena.alloc(ast.Stmt, 1);
                    then_[0] = .{ .expr = try self.node(obj.get("then").?) };
                    const else_ = try self.arena.alloc(ast.Stmt, 1);
                    else_[0] = .{ .expr = try self.node(obj.get("otherwise").?) };
                    return .{ .branch = .{ .loc = loc, .kind = .{ .if_ = .{ .cond = cond, .binding = null, .then_ = then_, .else_ = else_ } } } };
                },
                .Lambda => {
                    const ps = obj.get("params").?;
                    if (ps != .array) return try self.refuse("`{s}`: `params` is no list of names", .{try self.describe(v)});
                    const params = try self.arena.alloc([]const u8, ps.array.items.len);
                    for (ps.array.items, 0..) |p, i| params[i] = try self.identifier(p, v);
                    const loc = try self.next(v);
                    const body = try self.arena.alloc(ast.Stmt, 1);
                    body[0] = .{ .expr = try self.node(obj.get("body").?), .tail = .value };
                    return .{ .function = .{ .loc = loc, .kind = .{ .syntax = .lambda, .params = params, .body = body } } };
                },
                .Syntax => {
                    const code = self.ctx.syntax(obj.get("e").?) orelse
                        return try self.refuse("`{s}` holds no `syntax` value: write `Lit(v)` for a value known at build", .{try self.describe(v)});
                    const loc = try self.next(v);
                    const name = try std.fmt.allocPrint(self.arena, "{s}{d}", .{ splice_placeholder, self.splices.items.len });
                    try self.splices.append(self.arena, code);
                    return .{ .identifier = .{ .loc = loc, .kind = .{ .ident = name } } };
                },
                .Fn => return self.function(obj, v),
                .FnParam => return try self.refuse("`{s}` is a parameter outside a `Fn`: an `FnParam` is only an element of `Fn.params`", .{try self.describe(v)}),
                .Return => {
                    const loc = try self.next(v);
                    return .{ .jump = .{ .loc = loc, .kind = .{ .@"return" = try self.box(try self.node(obj.get("result").?)) } } };
                },
                .NamedType, .ArrayType, .TupleType, .LabeledTupleType, .OptionalType, .FnType, .GenericType, .UnionType => return try self.refuse("`{s}` is a type, not an expression: a type node stands where a type is written — an `FnParam`'s annotation, a `Fn`'s `ret`", .{try self.describe(v)}),
            }
        }

        /// Decision 753 — `Fn(params, ret, body)`: a typed function
        /// expression, as the parser builds `fn(a: A) -> R { … }`.
        fn function(self: *Self, obj: std.json.ObjectMap, v: std.json.Value) (Error || error{Ill})!ast.Expr {
            const loc = try self.next(v);
            const ps = obj.get("params").?;
            if (ps != .array) return try self.refuse("`{s}`: `params` is no list of `FnParam`s", .{try self.describe(v)});
            const names = try self.arena.alloc([]const u8, ps.array.items.len);
            const types = try self.arena.alloc(ast.TypeRef, ps.array.items.len);
            for (ps.array.items, 0..) |p, i| {
                const po = try self.object(p);
                if (po.kind != .FnParam) return try self.refuse("`{s}`: each of `Fn.params` is an `FnParam`, not `{s}`", .{ try self.describe(v), try self.describe(p) });
                names[i] = try self.identifier(po.obj.get("name").?, p);
                types[i] = try self.typeRef(po.obj.get("annotation").?);
            }
            const ret = try self.typeRef(obj.get("ret").?);
            const bodyV = obj.get("body").?;
            if (bodyV != .array) return try self.refuse("`{s}`: `body` is no list of nodes", .{try self.describe(v)});
            const body = try self.arena.alloc(ast.Stmt, bodyV.array.items.len);
            for (bodyV.array.items, 0..) |st, i| body[i] = .{ .expr = try self.node(st) };
            return .{ .function = .{ .loc = loc, .kind = .{ .syntax = .fnExpr, .params = names, .body = body, .paramTypes = types, .returnType = ret } } };
        }

        /// Decision 753 — a type node as the type the parser reads.
        fn typeRef(self: *Self, v: std.json.Value) (Error || error{Ill})!ast.TypeRef {
            const o = try self.object(v);
            const obj = o.obj;
            if (!isTypeKind(o.kind)) return try self.refuse("`{s}` is no type node where a type is written", .{try self.describe(v)});
            _ = try self.next(v);
            return switch (o.kind) {
                .NamedType => .{ .named = try self.identifier(obj.get("named").?, v) },
                .ArrayType => .{ .array = try self.boxType(try self.typeRef(obj.get("elem").?)) },
                .OptionalType => .{ .optional = try self.boxType(try self.typeRef(obj.get("inner").?)) },
                .TupleType => .{ .tuple_ = try self.typeRefs(obj.get("types").?, v) },
                .LabeledTupleType => blk: {
                    const elems = try self.typeRefs(obj.get("types").?, v);
                    const ls = obj.get("labels").?;
                    if (ls != .array or ls.array.items.len != elems.len) return try self.refuse("`{s}`: one label per type", .{try self.describe(v)});
                    const labels = try self.arena.alloc([]const u8, elems.len);
                    for (ls.array.items, 0..) |l, i| labels[i] = try self.identifier(l, v);
                    break :blk .{ .labeledTuple = .{ .elems = elems, .labels = labels } };
                },
                .FnType => .{ .function = .{ .params = try self.typeRefs(obj.get("params").?, v), .returnType = try self.boxType(try self.typeRef(obj.get("returns").?)) } },
                .GenericType => blk: {
                    const name = try self.identifier(obj.get("name").?, v);
                    const prelude = parserTypes.isPreludeWrapperName(name);
                    break :blk .{ .generic = .{ .name = name, .args = try self.typeRefs(obj.get("args").?, v), .is_builtin = prelude, .bare = prelude } };
                },
                .UnionType => .{ .generic = .{ .name = ast.union_type_name, .args = try self.typeRefs(obj.get("members").?, v), .is_builtin = false } },
                else => unreachable,
            };
        }

        fn typeRefs(self: *Self, list: std.json.Value, owner: std.json.Value) (Error || error{Ill})![]ast.TypeRef {
            if (list != .array) return try self.refuse("`{s}` holds no list of type nodes", .{try self.describe(owner)});
            const out = try self.arena.alloc(ast.TypeRef, list.array.items.len);
            for (list.array.items, 0..) |item, i| out[i] = try self.typeRef(item);
            return out;
        }

        fn boxType(self: *Self, t: ast.TypeRef) Error!*ast.TypeRef {
            const p = try self.arena.create(ast.TypeRef);
            p.* = t;
            return p;
        }

        fn call(self: *Self, obj: std.json.ObjectMap, v: std.json.Value) (Error || error{Ill})!ast.Expr {
            const loc = try self.next(v);
            const calleeV = obj.get("callee").?;
            var receiver: ?*ast.Expr = null;
            var callee: []const u8 = "";
            var calleeExpr: ?*ast.Expr = null;
            const co = try self.object(calleeV);
            switch (co.kind) {
                .Name => {
                    callee = try self.identifier(co.obj.get("name").?, calleeV);
                    try self.names.append(self.arena, .{ .loc = loc, .name = callee });
                },
                .Member => {
                    callee = try self.identifier(co.obj.get("member").?, calleeV);
                    receiver = try self.box(try self.node(co.obj.get("target").?));
                },
                else => calleeExpr = try self.box(try self.node(calleeV)),
            }
            const argsV = obj.get("args").?;
            if (argsV != .array) return try self.refuse("`{s}`: `args` is no list of nodes", .{try self.describe(v)});
            const args = try self.arena.alloc(ast.CallArg, argsV.array.items.len);
            for (argsV.array.items, 0..) |a, i| {
                const ao = try self.object(a);
                if (ao.kind == .Arg) {
                    const name = try self.identifier(ao.obj.get("name").?, a);
                    args[i] = .{ .label = name, .value = try self.box(try self.node(ao.obj.get("value").?)) };
                } else {
                    args[i] = .{ .label = null, .value = try self.box(try self.node(a)) };
                }
            }
            return .{ .call = .{ .loc = loc, .kind = .{ .call = .{
                .receiver = receiver,
                .callee = callee,
                .calleeExpr = calleeExpr,
                .is_builtin = false,
                .args = args,
                .trailing = &.{},
            } } } };
        }

        fn nodes(self: *Self, list: std.json.Value, owner: std.json.Value) (Error || error{Ill})![]ast.Expr {
            if (list != .array) return try self.refuse("`{s}` holds no list of nodes", .{try self.describe(owner)});
            const out = try self.arena.alloc(ast.Expr, list.array.items.len);
            for (list.array.items, 0..) |item, i| out[i] = try self.node(item);
            return out;
        }

        fn string(self: *Self, s: std.json.Value, owner: std.json.Value) (Error || error{Ill})![]const u8 {
            return switch (s) {
                .string => |t| t,
                else => try self.refuse("`{s}` holds no string where one is written", .{try self.describe(owner)}),
            };
        }

        /// A name a botopink source could spell: `[A-Za-z_][A-Za-z0-9_]*`.
        fn identifier(self: *Self, s: std.json.Value, owner: std.json.Value) (Error || error{Ill})![]const u8 {
            const t = try self.string(s, owner);
            const ok = t.len > 0 and (std.ascii.isAlphabetic(t[0]) or t[0] == '_') and for (t[1..]) |c| {
                if (!(std.ascii.isAlphanumeric(c) or c == '_')) break false;
            } else true;
            if (!ok) return try self.refuse("`{s}`: \"{s}\" is no name", .{ try self.describe(owner), t });
            return t;
        }

        fn describe(self: *Self, v: std.json.Value) Error![]const u8 {
            return describeNode(self.arena, v);
        }
    };
}

/// The node as a `compiler.bp` constructor call, its leaves written and its
/// subtrees elided: `Arg(name: "tag", value: …)`.
pub fn describeNode(arena: std.mem.Allocator, v: std.json.Value) Error![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    switch (v) {
        .object => |obj| {
            if (obj.contains("__bp_capture")) return "a `syntax` value";
            const k = kindOf(obj);
            try out.appendSlice(arena, if (k) |kk| @tagName(kk) else "");
            try out.append(arena, '(');
            var first = true;
            if (k) |kk| {
                for (kinds) |e| if (e.kind == kk) for (e.fields) |f| {
                    if (!first) try out.appendSlice(arena, ", ");
                    first = false;
                    try leaf(arena, &out, f, obj.get(f).?);
                };
            } else {
                var it = obj.iterator();
                while (it.next()) |e| {
                    if (!first) try out.appendSlice(arena, ", ");
                    first = false;
                    try leaf(arena, &out, e.key_ptr.*, e.value_ptr.*);
                }
            }
            try out.append(arena, ')');
        },
        else => try leaf(arena, &out, "", v),
    }
    return out.items;
}

fn leaf(arena: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), label: []const u8, v: std.json.Value) Error!void {
    if (label.len > 0) try out.print(arena, "{s}: ", .{label});
    switch (v) {
        .string => |s| try out.print(arena, "\"{s}\"", .{s}),
        .integer => |n| try out.print(arena, "{d}", .{n}),
        .float => |f| try out.print(arena, "{d}", .{f}),
        .bool => |b| try out.appendSlice(arena, if (b) "true" else "false"),
        .null => try out.appendSlice(arena, "null"),
        else => try out.appendSlice(arena, "…"),
    }
}

fn binaryOp(text: []const u8) ?@FieldType(ast.BinOpExprOf(.untyped), "op") {
    const table = .{
        .{ "<", .lt },  .{ ">", .gt },      .{ "<=", .lte },   .{ ">=", .gte }, .{ "==", .eq },
        .{ "!=", .ne }, .{ "+", .add },     .{ "-", .sub },    .{ "*", .mul },  .{ "/", .div },
        .{ "%", .mod }, .{ "&&", .@"and" }, .{ "||", .@"or" },
    };
    inline for (table) |e| if (std.mem.eql(u8, text, e[0])) return e[1];
    return null;
}
