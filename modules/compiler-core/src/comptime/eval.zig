/// Comptime `val` evaluation.
///
/// `ComptimeEntry` — one expression to evaluate, with its generated ID.
/// `RunResult`     — the evaluated literals and a listing of them.
/// `evaluate()`    — folds each entry in Zig.
///
/// The expressions reaching here are constant folds (literals, arithmetic,
/// `@typeInfo`/`@TypeOf`, a comptime block's `break` value), so no runtime is
/// involved. Decorator and template bodies are different: they run on the
/// Erlang VM (`decorator_eval.zig`, `template_eval.zig`).
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");

/// A single comptime expression to be evaluated, paired with its generated ID.
pub const ComptimeEntry = struct {
    id: []const u8, // "ct_0", "ct_1", …
    expr: ast.TypedExpr,
    /// The declaration as written (formatted), shown next to its value.
    source: []const u8 = "",
};

pub const RunResult = struct {
    /// `id: <declaration> → literal` per entry (shown in snapshots).
    script: []u8,
    /// Evaluated values: id → literal (`3`, `"text"`, `[1, 2]`, `true`, `null`).
    values: std.StringHashMap([]const u8),
};

pub const EvalError = error{
    /// A bare identifier that isn't `true`/`false`/`null` has no constant value.
    UnsupportedComptimeValue,
} || std.mem.Allocator.Error;

/// Fold `entries`. The result is owned by the caller (allocated from `allocator`).
pub fn evaluate(allocator: std.mem.Allocator, entries: []const ComptimeEntry) EvalError!RunResult {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var root: Scope = .{};

    var script: std.ArrayListUnmanaged(u8) = .empty;
    errdefer script.deinit(allocator);
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer {
        var it = values.valueIterator();
        while (it.next()) |v| allocator.free(v.*);
        values.deinit();
    }
    for (entries) |e| {
        const lit = try literal(allocator, try valueOf(arena, &root, e.expr));
        errdefer allocator.free(lit);
        try values.put(try allocator.dupe(u8, e.id), lit);
        try writeListing(allocator, &script, e, lit);
    }
    return .{ .script = try script.toOwnedSlice(allocator), .values = values };
}

/// `ct_0: val pi = comptime 3.14 * 2 → 6.28`; a multi-line declaration keeps
/// its lines aligned under the first one.
fn writeListing(allocator: std.mem.Allocator, script: *std.ArrayListUnmanaged(u8), e: ComptimeEntry, lit: []const u8) EvalError!void {
    try script.print(allocator, "{s}: ", .{e.id});
    const source = std.mem.trimEnd(u8, std.mem.trim(u8, e.source, " \n"), ";");
    var lines = std.mem.splitScalar(u8, source, '\n');
    var first = true;
    while (lines.next()) |line| {
        if (!first) {
            try script.append(allocator, '\n');
            try script.appendNTimes(allocator, ' ', e.id.len + 2);
        }
        try script.appendSlice(allocator, line);
        first = false;
    }
    try script.print(allocator, " → {s}\n", .{lit});
}

// ── folding ───────────────────────────────────────────────────────────────────

const Value = union(enum) {
    null_,
    boolean: bool,
    integer: i64,
    float: f64,
    string: []const u8,
    list: []const Value,
    /// A record / interface literal or `@typeInfo` result: no literal form.
    object,
};

/// A `val`/`var` declared inside a `comptime { … }` block.
const Local = struct {
    name: []const u8,
    value: Value,
};

/// The locals visible while folding one block. A nested block (an `if` arm)
/// pushes a child scope, so its own `val`s do not leak out. `error.zig`
/// validates the same shape before anything is folded.
const Scope = struct {
    parent: ?*Scope = null,
    locals: std.ArrayListUnmanaged(Local) = .empty,

    /// The innermost binding of `name` (so a shadowing `val` wins), or null.
    fn find(this: *Scope, name: []const u8) ?*Local {
        var scope: ?*Scope = this;
        while (scope) |s| : (scope = s.parent) {
            var i = s.locals.items.len;
            while (i > 0) {
                i -= 1;
                if (std.mem.eql(u8, s.locals.items[i].name, name)) return &s.locals.items[i];
            }
        }
        return null;
    }

    fn declare(this: *Scope, arena: std.mem.Allocator, name: []const u8, value: Value) EvalError!void {
        try this.locals.append(arena, .{ .name = name, .value = value });
    }
};

fn valueOf(arena: std.mem.Allocator, scope: *Scope, te: ast.TypedExpr) EvalError!Value {
    switch (te) {
        .comptime_ => |ct| return switch (ct.kind) {
            .comptimeExpr => |inner| valueOf(arena, scope, inner.*),
            .comptimeBlock => |cb| blockValue(arena, scope, cb.body),
            else => .null_,
        },
        .literal => |lit| return switch (lit.kind) {
            .numberLit => |n| numberValue(n),
            .stringLit => |s| .{ .string = s },
            .null_, .comment => .null_,
            .stringTemplate => unreachable,
        },
        .binaryOp => |b| return binary(arena, b.op, try valueOf(arena, scope, b.lhs.*), try valueOf(arena, scope, b.rhs.*)),
        .unaryOp => |u| {
            const v = try valueOf(arena, scope, u.expr.*);
            return switch (u.op) {
                .not => .{ .boolean = !truthy(v) },
                .neg => switch (v) {
                    .integer => |n| .{ .integer = -n },
                    .float => |f| .{ .float = -f },
                    else => .null_,
                },
            };
        },
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.is_builtin and cc.args.len >= 1) {
                    if (std.mem.eql(u8, cc.callee, "typeInfo")) return .object;
                    if (std.mem.eql(u8, cc.callee, "TypeOf")) return .{ .string = typeName(cc.args[0].value.getType()) };
                }
                return .null_;
            },
            .pipeline => |p| return valueOf(arena, scope, p.rhs.*),
        },
        .identifier => |id| switch (id.kind) {
            .ident => |name| {
                if (scope.find(name)) |local| return local.value;
                if (std.mem.eql(u8, name, "true")) return .{ .boolean = true };
                if (std.mem.eql(u8, name, "false")) return .{ .boolean = false };
                if (std.mem.eql(u8, name, "null")) return .null_;
                return error.UnsupportedComptimeValue;
            },
            .dotIdent => |name| return .{ .string = name },
            .identAccess => return .null_,
        },
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                const items = try arena.alloc(Value, al.elems.len);
                for (al.elems, 0..) |item, i| items[i] = try valueOf(arena, scope, item);
                return .{ .list = items };
            },
            .behaviorLit => |il| {
                for (il.fields) |f| _ = try valueOf(arena, scope, f.value.*);
                return .object;
            },
            // Only a wildcard / binding arm matches a folded subject.
            .case => |cs| {
                for (cs.subjects) |subj| {
                    _ = try valueOf(arena, scope, subj);
                    for (cs.arms) |arm| {
                        if (arm.pattern == .wildcard or arm.pattern == .ident) return valueOf(arena, scope, arm.body);
                    }
                }
                return .null_;
            },
            else => return .null_,
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |y| if (y.value) |v| return valueOf(arena, scope, v.*),
            .@"return" => |r| if (r) |v| return valueOf(arena, scope, v.*),
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                const cond = try valueOf(arena, scope, i.cond.*);
                return blockValue(arena, scope, if (truthy(cond)) i.then_ else i.else_ orelse &.{});
            },
            else => return .null_,
        },
        .loop => |lp| return blockValue(arena, scope, lp.body),
        else => {},
    }
    return .null_;
}

// ── operators ────────────────────────────────────────────────────────────────
//
// An operand carries its own kind, so `3.14 * 2.0` folds as a float, `"a" + "b"`
// as a string and `a < b` as a boolean. Anything the folder cannot reduce
// (a record operand, a division by zero) yields `null` rather than a bogus `0`.

/// The operator enum of a typed binary node.
const BinOp = @FieldType(ast.BinOpExprOf(.typed), "op");

fn binary(arena: std.mem.Allocator, op: BinOp, lhs: Value, rhs: Value) EvalError!Value {
    switch (op) {
        .@"and" => return .{ .boolean = truthy(lhs) and truthy(rhs) },
        .@"or" => return .{ .boolean = truthy(lhs) or truthy(rhs) },
        .eq => return .{ .boolean = equals(lhs, rhs) },
        .ne => return .{ .boolean = !equals(lhs, rhs) },
        .lt, .gt, .lte, .gte => {
            const ord = compare(lhs, rhs) orelse return .null_;
            return .{ .boolean = switch (op) {
                .lt => ord == .lt,
                .gt => ord == .gt,
                .lte => ord != .gt,
                .gte => ord != .lt,
                else => unreachable,
            } };
        },
        .add, .sub, .mul, .div, .mod => {},
    }

    if (op == .add and lhs == .string and rhs == .string) {
        return .{ .string = try std.mem.concat(arena, u8, &.{ lhs.string, rhs.string }) };
    }
    if (lhs == .integer and rhs == .integer) {
        const a = lhs.integer;
        const b = rhs.integer;
        return switch (op) {
            .add => .{ .integer = a + b },
            .sub => .{ .integer = a - b },
            .mul => .{ .integer = a * b },
            .div => if (b != 0) .{ .integer = @divTrunc(a, b) } else .null_,
            .mod => if (b != 0) .{ .integer = @mod(a, b) } else .null_,
            else => .null_,
        };
    }
    const a = numeric(lhs) orelse return .null_;
    const b = numeric(rhs) orelse return .null_;
    return switch (op) {
        .add => .{ .float = a + b },
        .sub => .{ .float = a - b },
        .mul => .{ .float = a * b },
        .div => if (b != 0) .{ .float = a / b } else .null_,
        .mod => if (b != 0) .{ .float = @mod(a, b) } else .null_,
        else => .null_,
    };
}

fn numeric(v: Value) ?f64 {
    return switch (v) {
        .integer => |n| @floatFromInt(n),
        .float => |f| f,
        else => null,
    };
}

fn truthy(v: Value) bool {
    return v == .boolean and v.boolean;
}

fn equals(lhs: Value, rhs: Value) bool {
    return switch (lhs) {
        .null_ => rhs == .null_,
        .boolean => |b| rhs == .boolean and rhs.boolean == b,
        .string => |s| rhs == .string and std.mem.eql(u8, rhs.string, s),
        .integer, .float => blk: {
            const a = numeric(lhs) orelse break :blk false;
            const b = numeric(rhs) orelse break :blk false;
            break :blk a == b;
        },
        .list, .object => false,
    };
}

fn compare(lhs: Value, rhs: Value) ?std.math.Order {
    if (lhs == .string and rhs == .string) return std.mem.order(u8, lhs.string, rhs.string);
    const a = numeric(lhs) orelse return null;
    const b = numeric(rhs) orelse return null;
    return std.math.order(a, b);
}

// ── blocks ───────────────────────────────────────────────────────────────────

/// The value a `comptime { … }` body evaluates to: the first `break`/`return`
/// carrying one, else `null`.
fn blockValue(arena: std.mem.Allocator, parent: *Scope, body: []const ast.TypedStmt) EvalError!Value {
    return (try blockResult(arena, parent, body)) orelse .null_;
}

/// `null` when the body produced no `break`/`return` value (so an enclosing
/// block keeps looking), as opposed to a `break null`.
fn blockResult(arena: std.mem.Allocator, parent: *Scope, body: []const ast.TypedStmt) EvalError!?Value {
    var scope: Scope = .{ .parent = parent };
    for (body) |stmt| {
        if (try execStmt(arena, &scope, stmt.expr)) |v| return v;
    }
    return null;
}

/// Run one statement of a folded block: declare a local, assign to one, take a
/// branch, or yield the block's value.
fn execStmt(arena: std.mem.Allocator, scope: *Scope, expr: ast.TypedExpr) EvalError!?Value {
    switch (expr) {
        .binding => |bd| switch (bd.kind) {
            .localBind => |lb| {
                try scope.declare(arena, lb.name, try valueOf(arena, scope, lb.value.*));
                return null;
            },
            .assign => |as| switch (as.target) {
                .name => |name| {
                    const v = try valueOf(arena, scope, as.value.*);
                    if (scope.find(name)) |local| {
                        local.value = switch (as.op) {
                            .assign => v,
                            .plusAssign => try binary(arena, .add, local.value, v),
                        };
                    }
                    return null;
                },
                else => return null,
            },
            else => return null,
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |y| if (y.value) |v| return try valueOf(arena, scope, v.*),
            .@"return" => |r| if (r) |v| return try valueOf(arena, scope, v.*),
            else => {},
        },
        // A branch does not end the block by itself; its taken arm may `break`.
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                const cond = try valueOf(arena, scope, i.cond.*);
                const arm = if (truthy(cond)) i.then_ else i.else_ orelse return null;
                return blockResult(arena, scope, arm);
            },
            else => return null,
        },
        else => return null,
    }
    return null;
}

fn numberValue(text: []const u8) EvalError!Value {
    if (std.fmt.parseInt(i64, text, 10)) |n| return .{ .integer = n } else |_| {}
    if (std.fmt.parseFloat(f64, text)) |f| return .{ .float = f } else |_| {}
    return error.UnsupportedComptimeValue;
}

fn typeName(ty: *T.Type) []const u8 {
    return switch (ty.deref().*) {
        .named => |n| n.name,
        .record => "record",
        else => "unknown",
    };
}

// ── literals ──────────────────────────────────────────────────────────────────

/// The literal text the backends splice in. Nested lists and objects inside a
/// list, and top-level objects, have no literal form and become `null`.
fn literal(allocator: std.mem.Allocator, value: Value) EvalError![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    switch (value) {
        .list => |items| {
            try out.append(allocator, '[');
            for (items, 0..) |item, i| {
                if (i > 0) try out.appendSlice(allocator, ", ");
                switch (item) {
                    .list, .object => try out.appendSlice(allocator, "null"),
                    else => try writeScalar(allocator, &out, item, false),
                }
            }
            try out.append(allocator, ']');
        },
        .object => try out.appendSlice(allocator, "null"),
        else => try writeScalar(allocator, &out, value, true),
    }
    return out.toOwnedSlice(allocator);
}

fn writeScalar(allocator: std.mem.Allocator, out: *std.ArrayListUnmanaged(u8), value: Value, escape_newline: bool) EvalError!void {
    switch (value) {
        .null_ => try out.appendSlice(allocator, "null"),
        .boolean => |b| try out.appendSlice(allocator, if (b) "true" else "false"),
        .integer => |n| try out.print(allocator, "{d}", .{n}),
        .float => |f| try out.print(allocator, "{d}", .{f}),
        .string => |s| {
            try out.append(allocator, '"');
            for (s) |c| switch (c) {
                '"' => try out.appendSlice(allocator, "\\\""),
                '\\' => try out.appendSlice(allocator, "\\\\"),
                '\n' => try out.appendSlice(allocator, if (escape_newline) "\\n" else "\n"),
                else => try out.append(allocator, c),
            };
            try out.append(allocator, '"');
        },
        .list, .object => unreachable,
    }
}

test "comptime literals: lists, strings and numbers" {
    const alloc = std.testing.allocator;
    const text = try literal(alloc, .{ .list = &.{ .{ .integer = 1 }, .{ .string = "a\"b" }, .{ .float = 2.5 }, .object } });
    defer alloc.free(text);
    try std.testing.expectEqualStrings("[1, \"a\\\"b\", 2.5, null]", text);
    const n = try literal(alloc, try numberValue("3.0"));
    defer alloc.free(n);
    try std.testing.expectEqualStrings("3", n);
}

test "comptime operators: the operand kind drives the fold" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    const pi = Value{ .float = 3.14 };
    const two = Value{ .float = 2.0 };
    try std.testing.expectEqual(@as(f64, 6.28), (try binary(arena, .mul, pi, two)).float);
    // An integer operand promotes, it does not truncate the other side.
    try std.testing.expectEqual(@as(f64, 6.28), (try binary(arena, .mul, pi, .{ .integer = 2 })).float);
    try std.testing.expectEqual(@as(i64, 101), (try binary(arena, .add, .{ .integer = 100 }, .{ .integer = 1 })).integer);

    const joined = try binary(arena, .add, .{ .string = "Hello, " }, .{ .string = "World" });
    try std.testing.expectEqualStrings("Hello, World", joined.string);

    try std.testing.expect((try binary(arena, .lt, .{ .integer = 1 }, .{ .float = 1.5 })).boolean);
    try std.testing.expect((try binary(arena, .gte, .{ .integer = 2 }, .{ .integer = 2 })).boolean);
    try std.testing.expect(!(try binary(arena, .eq, .{ .string = "a" }, .{ .string = "b" })).boolean);
    try std.testing.expect((try binary(arena, .ne, .{ .string = "a" }, .{ .string = "b" })).boolean);
    // Nothing reducible: `null`, never a stand-in `0`.
    try std.testing.expect((try binary(arena, .div, .{ .integer = 1 }, .{ .integer = 0 })) == .null_);
    try std.testing.expect((try binary(arena, .add, .object, .{ .integer = 1 })) == .null_);
}

test "comptime scope: a local val is visible to the break expression" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var root: Scope = .{};
    var inner: Scope = .{ .parent = &root };
    try root.declare(arena, "x", .{ .integer = 10 });
    try inner.declare(arena, "x", .{ .integer = 20 });

    try std.testing.expectEqual(@as(i64, 20), inner.find("x").?.value.integer);
    try std.testing.expectEqual(@as(i64, 10), root.find("x").?.value.integer);
    try std.testing.expect(inner.find("nope") == null);
}
