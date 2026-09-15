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
};

pub const RunResult = struct {
    /// `id = literal` per entry, one per line (shown in snapshots).
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

    var script: std.ArrayListUnmanaged(u8) = .empty;
    errdefer script.deinit(allocator);
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer {
        var it = values.valueIterator();
        while (it.next()) |v| allocator.free(v.*);
        values.deinit();
    }
    for (entries) |e| {
        const lit = try literal(allocator, try valueOf(arena, e.expr));
        errdefer allocator.free(lit);
        try values.put(try allocator.dupe(u8, e.id), lit);
        try script.appendSlice(allocator, e.id);
        try script.appendSlice(allocator, " = ");
        try script.appendSlice(allocator, lit);
        try script.append(allocator, '\n');
    }
    return .{ .script = try script.toOwnedSlice(allocator), .values = values };
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

fn valueOf(arena: std.mem.Allocator, te: ast.TypedExpr) EvalError!Value {
    switch (te) {
        .comptime_ => |ct| return switch (ct.kind) {
            .comptimeExpr => |inner| valueOf(arena, inner.*),
            .comptimeBlock => |cb| blockValue(arena, cb.body),
            else => .null_,
        },
        .literal => |lit| return switch (lit.kind) {
            .numberLit => |n| numberValue(n),
            .stringLit => |s| .{ .string = s },
            .null_, .comment => .null_,
            .stringTemplate => unreachable,
        },
        .binaryOp => |b| {
            const lhs = evalConstInt(b.lhs.*);
            const rhs = evalConstInt(b.rhs.*);
            return .{ .integer = switch (b.op) {
                .add => lhs + rhs,
                .sub => lhs - rhs,
                .mul => lhs * rhs,
                .div => if (rhs != 0) @divTrunc(lhs, rhs) else 0,
                .mod => if (rhs != 0) @mod(lhs, rhs) else 0,
                else => 0,
            } };
        },
        .unaryOp => |u| return switch (u.op) {
            .not => .{ .boolean = !evalConstBool(u.expr.*) },
            .neg => .{ .integer = -evalConstInt(u.expr.*) },
        },
        .call => |c| switch (c.kind) {
            .call => |cc| {
                if (cc.is_builtin and cc.args.len >= 1) {
                    if (std.mem.eql(u8, cc.callee, "typeInfo")) return .object;
                    if (std.mem.eql(u8, cc.callee, "TypeOf")) return .{ .string = typeName(cc.args[0].value.getType()) };
                }
                return .null_;
            },
            .pipeline => |p| return valueOf(arena, p.rhs.*),
        },
        .identifier => |id| switch (id.kind) {
            .ident => |name| {
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
                for (al.elems, 0..) |item, i| items[i] = try valueOf(arena, item);
                return .{ .list = items };
            },
            .recordLit => |rl| {
                for (rl.fields) |f| _ = try valueOf(arena, f.value.*);
                return .object;
            },
            .interfaceLit => |il| {
                for (il.fields) |f| _ = try valueOf(arena, f.value.*);
                return .object;
            },
            // Only a wildcard / binding arm matches a folded subject.
            .case => |cs| {
                for (cs.subjects) |subj| {
                    _ = try valueOf(arena, subj);
                    for (cs.arms) |arm| {
                        if (arm.pattern == .wildcard or arm.pattern == .ident) return valueOf(arena, arm.body);
                    }
                }
                return .null_;
            },
            else => return .null_,
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |y| if (y.value) |v| return valueOf(arena, v.*),
            .@"return" => |r| if (r) |v| return valueOf(arena, v.*),
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |i| {
                const cond = try valueOf(arena, i.cond.*);
                const taken = cond == .boolean and cond.boolean;
                return blockValue(arena, if (taken) i.then_ else i.else_ orelse &.{});
            },
            else => return .null_,
        },
        .loop => |lp| return blockValue(arena, lp.body),
        else => {},
    }
    return .null_;
}

/// The value of the first `break`/`return` carrying one, else `null`.
fn blockValue(arena: std.mem.Allocator, body: []const ast.TypedStmt) EvalError!Value {
    for (body) |stmt| {
        if (stmt.expr != .jump) continue;
        switch (stmt.expr.jump.kind) {
            .@"break" => |y| if (y.value) |v| return valueOf(arena, v.*),
            .@"return" => |r| if (r) |v| return valueOf(arena, v.*),
            else => {},
        }
    }
    return .null_;
}

fn numberValue(text: []const u8) EvalError!Value {
    if (std.fmt.parseInt(i64, text, 10)) |n| return .{ .integer = n } else |_| {}
    if (std.fmt.parseFloat(f64, text)) |f| return .{ .float = f } else |_| {}
    return error.UnsupportedComptimeValue;
}

fn evalConstInt(te: ast.TypedExpr) i64 {
    return switch (te) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| std.fmt.parseInt(i64, n, 10) catch 0,
            else => 0,
        },
        .binaryOp => |b| blk: {
            const lhs = evalConstInt(b.lhs.*);
            const rhs = evalConstInt(b.rhs.*);
            break :blk switch (b.op) {
                .add => lhs + rhs,
                .sub => lhs - rhs,
                .mul => lhs * rhs,
                .div => if (rhs != 0) @divTrunc(lhs, rhs) else 0,
                .mod => if (rhs != 0) @mod(lhs, rhs) else 0,
                else => 0,
            };
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| evalConstInt(inner.*),
            else => 0,
        },
        else => 0,
    };
}

fn evalConstBool(te: ast.TypedExpr) bool {
    return switch (te) {
        .identifier => |id| id.kind == .ident and std.mem.eql(u8, id.kind.ident, "true"),
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| evalConstBool(inner.*),
            else => false,
        },
        else => false,
    };
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
