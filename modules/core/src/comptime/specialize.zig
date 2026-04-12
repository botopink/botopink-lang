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
        switch (stmt.expr.kind) {
            .loop => |lp| {
                const iter_name: ?[]const u8 = switch (lp.iter.kind) {
                    .ident => |n| n,
                    else => null,
                };
                const elements_opt = if (iter_name) |n| comptime_arrays.get(n) else null;
                if (elements_opt) |elements| {
                    // Comptime array: unroll the loop.
                    for (elements) |elem| {
                        const elem_val: []const u8 = switch (elem.kind) {
                            .stringLit => |s| s,
                            .numberLit => |n| n,
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
        switch (stmt.expr.kind) {
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
            .assign => |a| {
                switch (a.value.kind) {
                    .case => |cn| {
                        if (try tryFoldCaseAssign(arena, a.name, cn, loop_params, elem_val, ct_arg_map)) |folded| {
                            try out.append(arena, folded);
                        } else {
                            try out.append(arena, stmt);
                        }
                    },
                    else => try out.append(arena, stmt),
                }
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
    const subject_val = resolveToStr(case_node.subject.*, loop_params, elem_val, ct_arg_map) orelse return null;

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
                .expr = .{
                    .loc = .{ .line = 0, .col = 0 },
                    .kind = .{ .assign = .{ .name = name, .value = body_copy } },
                },
            };
        }
    }
    return null;
}

/// Create a `const name = value;` statement allocated in `arena`.
fn makeConstDecl(arena: std.mem.Allocator, name: []const u8, val: []const u8) !ast.Stmt {
    const is_number = val.len > 0 and std.ascii.isDigit(val[0]);
    const val_expr = try arena.create(ast.Expr);
    val_expr.* = .{
        .loc = .{ .line = 0, .col = 0 },
        .kind = if (is_number) .{ .numberLit = val } else .{ .stringLit = val },
    };
    return ast.Stmt{
        .expr = .{
            .loc = .{ .line = 0, .col = 0 },
            .kind = .{ .localBind = .{
                .name = name,
                .value = val_expr,
                .mutable = false,
            } },
        },
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
    switch (cond.kind) {
        .eq => |b| {
            const lv = resolveToStr(b.lhs.*, loop_params, elem_val, ct_arg_map) orelse return null;
            const rv = resolveToStr(b.rhs.*, loop_params, elem_val, ct_arg_map) orelse return null;
            return std.mem.eql(u8, lv, rv);
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
    switch (e.kind) {
        .ident => |name| {
            for (loop_params) |p| {
                if (std.mem.eql(u8, p, name)) return elem_val;
            }
            return ct_arg_map.get(name);
        },
        .stringLit => |s| return s,
        .numberLit => |n| return n,
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
        switch (stmt.expr.kind) {
            .loop => |lp| {
                const is_ct_loop = switch (lp.iter.kind) {
                    .ident => |n| comptime_arrays.get(n) != null,
                    else => false,
                };
                if (is_ct_loop) continue; // handled by unrolling — skip
                if (identInExpr(lp.iter.*, param_name)) return true;
                for (lp.body) |bs| if (identInExpr(bs.expr, param_name)) return true;
            },
            else => if (identInExpr(stmt.expr, param_name)) return true,
        }
    }
    return false;
}

fn identInExpr(expr: anytype, name: []const u8) bool {
    return switch (expr.kind) {
        .ident => |n| std.mem.eql(u8, n, name),
        .add, .sub, .mul, .div, .mod, .eq, .ne, .lt, .gt, .lte, .gte => |b| identInExpr(b.lhs.*, name) or identInExpr(b.rhs.*, name),
        .localBind => |lb| identInExpr(lb.value.*, name),
        .@"return" => |r| identInExpr(r.*, name),
        .assign => |a| identInExpr(a.value.*, name),
        .if_ => |inode| blk: {
            if (identInExpr(inode.cond.*, name)) break :blk true;
            for (inode.then_) |s| if (identInExpr(s.expr, name)) break :blk true;
            break :blk false;
        },
        .call => |c| blk: {
            for (c.args) |a| if (identInExpr(a.value.*, name)) break :blk true;
            break :blk false;
        },
        else => false,
    };
}
