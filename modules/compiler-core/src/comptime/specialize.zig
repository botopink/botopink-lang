/// Comptime specialization: pure AST transform pass.
///
/// Takes a typed FnDecl and comptime argument values, returns a SpecializedFn
/// with comptime params removed and the body transformed (loops unrolled,
/// static branches folded). No JS is emitted here — that is the backend's job.
const std = @import("std");
const ast = @import("../ast.zig");

// ── Public types ──────────────────────────────────────────────────────────────

/// A comptime parameter that was specialized away (kept for JSDoc generation).
pub const CtParam = struct {
    name: []const u8,
    value: []const u8,
};

/// Result of specializing a function for a specific set of comptime arguments.
/// All fields except `fn_name` are owned by `spec_arena`.
pub const SpecializedFn = struct {
    id: usize,
    /// Original (unmangled) function name — points into the parse arena.
    fn_name: []const u8,
    /// Mangled name, e.g. `build_$0` — allocated in spec_arena.
    name: []const u8,
    /// Comptime params that were specialized away, in declaration order.
    ct_params: []const CtParam,
    /// Runtime-only parameters (comptime params removed).
    params: []const ast.Param,
    /// Transformed body: loops unrolled, static ifs/cases folded.
    body: []const ast.Stmt,
    spec_arena: std.heap.ArenaAllocator,

    pub fn deinit(self: *SpecializedFn) void {
        self.spec_arena.deinit();
    }
};

// ── SpecCache ─────────────────────────────────────────────────────────────────

/// Cache for specialized function versions with string interning.
pub const SpecCache = struct {
    /// Map from "fn_name|arg1|arg2|..." to numeric ID for deduplication.
    dedup: std.StringHashMap(usize),
    sources: std.ArrayListUnmanaged(SpecializedFn),
    next_id: usize,
    arena: std.mem.Allocator,

    pub fn init(arena: std.mem.Allocator) SpecCache {
        return .{
            .dedup = std.StringHashMap(usize).init(arena),
            .sources = .empty,
            .next_id = 0,
            .arena = arena,
        };
    }

    /// Get or create a specialization ID for the given comptime args.
    pub fn getOrPutId(this: *@This(), fn_name: []const u8, args: []const []const u8) !struct { id: usize, is_new: bool } {
        var key_buf: std.ArrayListUnmanaged(u8) = .empty;
        errdefer key_buf.deinit(this.arena);
        try key_buf.appendSlice(this.arena, fn_name);
        for (args) |arg| {
            try key_buf.append(this.arena, '|');
            try key_buf.appendSlice(this.arena, arg);
        }
        const key = try key_buf.toOwnedSlice(this.arena);

        if (this.dedup.get(key)) |id| {
            this.arena.free(key);
            return .{ .id = id, .is_new = false };
        }

        const id = this.next_id;
        this.next_id += 1;
        try this.dedup.put(key, id);
        return .{ .id = id, .is_new = true };
    }

    pub fn addSource(this: *@This(), spec_fn: SpecializedFn) !void {
        try this.sources.append(this.arena, spec_fn);
    }
};

// ── Specialization entry point ────────────────────────────────────────────────

/// Pure AST transform: specializes `fn_decl` for the given comptime argument values.
/// Returns a `SpecializedFn` that owns a `spec_arena` for all newly allocated nodes.
pub fn specialize(
    parent_allocator: std.mem.Allocator,
    fn_decl: ast.FnDecl,
    spec_id: usize,
    comptime_args: []const []const u8,
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
) !SpecializedFn {
    var spec_arena = std.heap.ArenaAllocator.init(parent_allocator);
    errdefer spec_arena.deinit();
    const arena = spec_arena.allocator();

    // Build comptime param name → value map.
    var ct_arg_map = std.StringHashMap([]const u8).init(arena);
    {
        var ci: usize = 0;
        for (fn_decl.params) |param| {
            if (param.modifier == .@"comptime" and ci < comptime_args.len) {
                try ct_arg_map.put(param.name, comptime_args[ci]);
                ci += 1;
            }
        }
    }

    // Build ct_params list in declaration order (for JSDoc).
    var ct_params_list: std.ArrayListUnmanaged(CtParam) = .empty;
    {
        var ci: usize = 0;
        for (fn_decl.params) |param| {
            if (param.modifier == .@"comptime" and ci < comptime_args.len) {
                try ct_params_list.append(arena, .{ .name = param.name, .value = comptime_args[ci] });
                ci += 1;
            }
        }
    }

    // Build runtime-only params (filter out comptime params).
    var rt_params: std.ArrayListUnmanaged(ast.Param) = .empty;
    for (fn_decl.params) |p| {
        if (p.modifier != .@"comptime") try rt_params.append(arena, p);
    }

    // Mangle the function name.
    const mangled = try std.fmt.allocPrint(arena, "{s}_${d}", .{ fn_decl.name, spec_id });

    // Transform the function body.
    const body = try transformBody(
        arena,
        fn_decl.body,
        fn_decl.params,
        comptime_args,
        &ct_arg_map,
        comptime_arrays,
    );

    return .{
        .id = spec_id,
        .fn_name = fn_decl.name,
        .name = mangled,
        .ct_params = try ct_params_list.toOwnedSlice(arena),
        .params = try rt_params.toOwnedSlice(arena),
        .body = body,
        .spec_arena = spec_arena,
    };
}

// ── Transform pass ────────────────────────────────────────────────────────────

fn transformBody(
    arena: std.mem.Allocator,
    original_body: []const ast.Stmt,
    fn_params: []const ast.Param,
    comptime_args: []const []const u8,
    ct_arg_map: *const std.StringHashMap([]const u8),
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
) ![]const ast.Stmt {
    var out: std.ArrayListUnmanaged(ast.Stmt) = .empty;

    // Prepend `const param = value;` for comptime params used outside comptime loops,
    // emitted in declaration order for deterministic output.
    {
        var ci: usize = 0;
        for (fn_params) |param| {
            if (param.modifier == .@"comptime" and ci < comptime_args.len) {
                if (bodyNeedsParamConst(original_body, param.name, comptime_arrays)) {
                    try out.append(arena, try makeConstDecl(arena, param.name, comptime_args[ci]));
                }
                ci += 1;
            }
        }
    }

    // Transform each top-level statement.
    for (original_body) |stmt| {
        switch (stmt.expr) {
            .controlFlow => |cf| switch (cf.kind) {
                .loop => |lp| {
                    const iter_name: ?[]const u8 = switch (lp.iter.*) {
                        .identifier => |id| if (id.kind == .ident) id.kind.ident else null,
                        else => null,
                    };
                    const elements_opt = if (iter_name) |n| comptime_arrays.get(n) else null;
                    if (elements_opt) |elements| {
                        // Comptime array: unroll the loop.
                        for (elements) |elem| {
                            const elem_val: []const u8 = switch (elem) {
                                .literal => |lit| switch (lit.kind) {
                                    .stringLit => |s| s,
                                    .numberLit => |n| n,
                                    else => continue,
                                },
                                else => continue,
                            };
                        try transformBodyWithLoopCtx(
                            arena,
                            &out,
                            lp.body,
                            lp.params,
                            elem_val,
                            ct_arg_map,
                        );
                    }
                } else {
                    // Runtime array: keep the loop as-is.
                    try out.append(arena, stmt);
                }
                },
                .@"return" => try out.append(arena, stmt),
                .throw_ => try out.append(arena, stmt),
                .try_ => try out.append(arena, stmt),
                .tryCatch => try out.append(arena, stmt),
                .if_ => try out.append(arena, stmt),
                .@"break" => try out.append(arena, stmt),
                .yield => try out.append(arena, stmt),
                .@"continue" => try out.append(arena, stmt),
            },
            else => try out.append(arena, stmt),
        }
    }

    return try out.toOwnedSlice(arena);
}

/// Append transformed statements for one unrolled loop iteration.
/// Static `if (loopVar == literal)` branches are folded; foldable
/// `assign x = case(loopVar) {...}` are resolved to a single assignment.
fn transformBodyWithLoopCtx(
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(ast.Stmt),
    stmts: []const ast.Stmt,
    loop_params: []const []const u8,
    elem_val: []const u8,
    ct_arg_map: *const std.StringHashMap([]const u8),
) !void {
    for (stmts) |stmt| {
        switch (stmt.expr) {
            .controlFlow => |cf| switch (cf.kind) {
                .if_ => |if_node| {
                    if (evalEqCondition(if_node.cond.*, loop_params, elem_val, ct_arg_map)) |cond_val| {
                        if (cond_val) {
                            // Statically true: inline the then_ body.
                            try transformBodyWithLoopCtx(arena, out, if_node.then_, loop_params, elem_val, ct_arg_map);
                        } else if (if_node.else_) |else_stmts| {
                        // Statically false: try the else branch.
                        try transformBodyWithLoopCtx(arena, out, else_stmts, loop_params, elem_val, ct_arg_map);
                    }
                    // Statically false with no else: emit nothing.
                } else {
                    // Cannot evaluate statically: keep stmt as-is.
                    try out.append(arena, stmt);
                }
                },
                else => try out.append(arena, stmt),
            },
            .binding => |b| switch (b.kind) {
                .assign => |a| {
                    switch (a.value.*) {
                        .collection => |col| switch (col.kind) {
                            .case => |cn| {
                                if (try tryFoldCaseAssign(arena, a.name, cn, loop_params, elem_val, ct_arg_map)) |folded| {
                                    try out.append(arena, folded);
                                } else {
                                    try out.append(arena, stmt);
                                }
                            },
                            else => try out.append(arena, stmt),
                        },
                        else => try out.append(arena, stmt),
                    }
                },
                else => try out.append(arena, stmt),
            },
            else => try out.append(arena, stmt),
        }
    }
}

/// Try to fold `name = case subject { arms }` at compile time.
/// Returns a new `assign` stmt on success, null when the case cannot be resolved.
fn tryFoldCaseAssign(
    arena: std.mem.Allocator,
    name: []const u8,
    case_node: anytype,
    loop_params: []const []const u8,
    elem_val: []const u8,
    ct_arg_map: *const std.StringHashMap([]const u8),
) !?ast.Stmt {
    const subject_val = if (case_node.subjects.len > 0)
        resolveToStr(case_node.subjects[0], loop_params, elem_val, ct_arg_map) orelse return null
    else
        return null;

    for (case_node.arms) |arm| {
        const matched = switch (arm.pattern) {
            .stringLit => |s| std.mem.eql(u8, s, subject_val),
            .numberLit => |n| std.mem.eql(u8, n, subject_val),
            .wildcard => true,
            .ident => |i| std.mem.eql(u8, i, subject_val),
            else => continue, // variantFields, list, or-pattern — not foldable
        };
        if (matched) {
            // Shallow-copy the matched arm body expression into the spec arena.
            const body_copy = try arena.create(ast.Expr);
            body_copy.* = arm.body;
            return ast.Stmt{
                .expr = ast.Expr{ .binding = .{
                    .loc = .{ .line = 0, .col = 0 },
                    .kind = .{ .assign = .{ .name = name, .value = body_copy } },
                } },
            };
        }
    }
    return null;
}

/// Create a `const name = value;` statement allocated in `arena`.
fn makeConstDecl(arena: std.mem.Allocator, name: []const u8, val: []const u8) !ast.Stmt {
    const is_number = val.len > 0 and std.ascii.isDigit(val[0]);
    const val_expr = try arena.create(ast.Expr);
    val_expr.* = if (is_number)
        ast.Expr{ .literal = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .numberLit = val } } }
    else
        ast.Expr{ .literal = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .stringLit = val } } };
    return ast.Stmt{
        .expr = ast.Expr{ .binding = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .localBind = .{
            .name = name,
            .value = val_expr,
            .mutable = false,
        } } } },
    };
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Statically evaluate a simple equality condition for loop unrolling.
fn evalEqCondition(
    cond: anytype,
    loop_params: []const []const u8,
    elem_val: []const u8,
    ct_arg_map: *const std.StringHashMap([]const u8),
) ?bool {
    switch (cond) {
        .binaryOp => |bin| switch (bin.kind) {
            .eq => |b| {
                const lv = resolveToStr(b.lhs.*, loop_params, elem_val, ct_arg_map) orelse return null;
                const rv = resolveToStr(b.rhs.*, loop_params, elem_val, ct_arg_map) orelse return null;
                return std.mem.eql(u8, lv, rv);
            },
            else => return null,
        },
        else => return null,
    }
}

/// Resolve an expression to a string value for static condition evaluation.
fn resolveToStr(
    e: anytype,
    loop_params: []const []const u8,
    elem_val: []const u8,
    ct_arg_map: *const std.StringHashMap([]const u8),
) ?[]const u8 {
    const expr = if (@typeInfo(@TypeOf(e)) == .pointer) e.* else e;
    switch (expr) {
        .identifier => |id| switch (id.kind) {
            .ident => |name| {
                for (loop_params) |p| {
                    if (std.mem.eql(u8, p, name)) return elem_val;
                }
                return ct_arg_map.get(name);
            },
            else => return null,
        },
        .literal => |lit| switch (lit.kind) {
            .stringLit => |s| return s,
            .numberLit => |n| return n,
            else => return null,
        },
        else => return null,
    }
}

/// Returns true when `paramName` is referenced outside comptime-unrolled loops.
/// Used to decide whether to emit `const paramName = value` in the specialization.
fn bodyNeedsParamConst(
    body: []const ast.Stmt,
    param_name: []const u8,
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
) bool {
    for (body) |stmt| {
        switch (stmt.expr) {
            .controlFlow => |cf| switch (cf.kind) {
                .loop => |lp| {
                    const is_ct_loop = switch (lp.iter.*) {
                        .identifier => |id| if (id.kind == .ident)
                            comptime_arrays.get(id.kind.ident) != null
                        else
                            false,
                        else => false,
                    };
                    if (is_ct_loop) continue; // handled by unrolling — skip
                    if (identInExpr(lp.iter.*, param_name)) return true;
                    for (lp.body) |bs| if (identInExpr(bs.expr, param_name)) return true;
                },
                else => if (identInExpr(stmt.expr, param_name)) return true,
            },
            else => if (identInExpr(stmt.expr, param_name)) return true,
        }
    }
    return false;
}

fn identInExpr(expr: anytype, name: []const u8) bool {
    const e = if (@typeInfo(@TypeOf(expr)) == .pointer) expr.* else expr;
    return switch (e) {
        .identifier => |id| if (id.kind == .ident)
            std.mem.eql(u8, id.kind.ident, name)
        else
            false,
        .binaryOp => |bin| switch (bin.kind) {
            .add, .sub, .mul, .div, .mod, .eq, .ne, .lt, .gt, .lte, .gte, .@"and", .@"or" => |b| identInExpr(b.lhs.*, name) or identInExpr(b.rhs.*, name),
        },
        .call => |c| switch (c.kind) {
            .pipeline => |p| identInExpr(p.lhs.*, name) or identInExpr(p.rhs.*, name),
            .call => |cc| blk: {
                for (cc.args) |a| if (identInExpr(a.value.*, name)) break :blk true;
                break :blk false;
            },
            .staticCall => |sc| identInExpr(sc.arg.*, name),
            .builtinCall => |bc| blk: {
                for (bc.args) |a| if (identInExpr(a.value.*, name)) break :blk true;
                break :blk false;
            },
        },
        .binding => |b| switch (b.kind) {
            .localBind => |lb| identInExpr(lb.value.*, name),
            .assign => |a| identInExpr(a.value.*, name),
            .assignPlus => |ap| identInExpr(ap.value.*, name),
            .fieldAssign => |fa| identInExpr(fa.receiver.*, name) or identInExpr(fa.value.*, name),
            .fieldPlusEq => |fpe| identInExpr(fpe.receiver.*, name) or identInExpr(fpe.value.*, name),
            .localBindDestruct => |lb| identInExpr(lb.value.*, name),
        },
        .controlFlow => |cf| switch (cf.kind) {
            .@"return" => |r| identInExpr(r.*, name),
            .throw_ => |t| identInExpr(t.*, name),
            .try_ => |t| identInExpr(t.*, name),
            .tryCatch => |tc| identInExpr(tc.expr.*, name) or identInExpr(tc.handler.*, name),
            .if_ => |inode| blk: {
                if (identInExpr(inode.cond.*, name)) break :blk true;
                for (inode.then_) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
            .loop => |lp| blk: {
                if (identInExpr(lp.iter.*, name)) break :blk true;
                for (lp.body) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
            .@"break" => |b| if (b) |bp| identInExpr(bp.*, name) else false,
            .yield => |y| identInExpr(y.*, name),
            .@"continue" => false,
        },
        .function => |f| switch (f.kind) {
            .lambda => |l| blk: {
                for (l.body) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
            .fnExpr => |fn_expr| blk: {
                for (fn_expr.body) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
        },
        .collection => |c| switch (c.kind) {
            .grouped => |g| identInExpr(g.*, name),
            .block => |bl| blk: {
                for (bl.body) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
            .arrayLit => |al| blk: {
                for (al.elems) |elem| if (identInExpr(elem, name)) break :blk true;
                if (al.spreadExpr) |se| if (identInExpr(se, name)) break :blk true;
                break :blk false;
            },
            .tupleLit => |tl| blk: {
                for (tl.elems) |elem| if (identInExpr(elem, name)) break :blk true;
                break :blk false;
            },
            .case => |cs| blk: {
                for (cs.subjects) |s| if (identInExpr(s, name)) break :blk true;
                for (cs.arms) |arm| {
                    if (identInExpr(arm.body, name)) break :blk true;
                }
                break :blk false;
            },
            .range => |r| blk: {
                if (identInExpr(r.start.*, name)) break :blk true;
                if (r.end) |end| if (identInExpr(end.*, name)) break :blk true;
                break :blk false;
            },
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |ce| identInExpr(ce.*, name),
            .comptimeBlock => |cb| blk: {
                for (cb.body) |s| if (identInExpr(s.expr, name)) break :blk true;
                break :blk false;
            },
            .@"assert" => |a| blk: {
                if (identInExpr(a.condition.*, name)) break :blk true;
                if (a.message) |m| if (identInExpr(m.*, name)) break :blk true;
                break :blk false;
            },
            .assertPattern => |ap| blk: {
                if (identInExpr(ap.expr.*, name)) break :blk true;
                if (identInExpr(ap.handler.*, name)) break :blk true;
                break :blk false;
            },
        },
        .literal => |lit| switch (lit.kind) {
            .stringLit, .numberLit, .null_, .comment => false,
        },
        .unaryOp => |un| switch (un.kind) {
            .not => |o| identInExpr(o.*, name),
            .neg => |o| identInExpr(o.*, name),
        },
    };
}
