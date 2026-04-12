/// AST transform pass: specializes comptime calls by rewriting the AST directly.
///
/// Input:  typed Program + fn_decls map + comptime_arrays map
/// Output: new Program with:
///   - Calls rewritten to mangled names (scale_$0)
///   - Comptime args removed from call arg lists
///   - Fully-specialized fns removed from decls (dead code)
///   - Specialized fns injected as new DeclKind.fn
///
/// The codegen only sees the transformed AST — it has no knowledge of specialization.
const std = @import("std");
const ast = @import("../ast.zig");
const specialize = @import("./specialize.zig");

/// Aggregator: collects specialization info during scan/rewrite phases.
const Aggregator = struct {
    spec_cache: specialize.SpecCache,
    /// fn_name → total calls with comptime params found during rewrite.
    total_calls: std.StringHashMap(usize),
    /// fn_name → calls that were actually rewritten to specialized names.
    specialized_calls: std.StringHashMap(usize),
    /// Comptime evaluation results: "ct_N" → "6.28"
    comptime_vals: std.StringHashMap([]const u8),
    /// val_name → ct_id mapping (e.g. "pi" → "ct_0")
    val_ct_map: std.StringHashMap([]const u8),

    fn init(allocator: std.mem.Allocator, comptime_vals: std.StringHashMap([]const u8)) Aggregator {
        return .{
            .spec_cache = specialize.SpecCache.init(allocator),
            .total_calls = std.StringHashMap(usize).init(allocator),
            .specialized_calls = std.StringHashMap(usize).init(allocator),
            .comptime_vals = comptime_vals,
            .val_ct_map = std.StringHashMap([]const u8).init(allocator),
        };
    }

    fn deinit(this: *Aggregator, allocator: std.mem.Allocator) void {
        for (this.spec_cache.sources.items) |*spec| spec.deinit();
        this.spec_cache.sources.deinit(allocator);
        var it = this.spec_cache.dedup.iterator();
        while (it.next()) |kv| allocator.free(kv.key_ptr.*);
        this.spec_cache.dedup.deinit();
        this.total_calls.deinit();
        this.specialized_calls.deinit();
        this.val_ct_map.deinit();
    }

    /// Register a val name with its ct_id for comptime value lookup.
    fn registerCtVal(this: *Aggregator, val_name: []const u8, ct_id: []const u8) !void {
        try this.val_ct_map.put(val_name, ct_id);
    }

    /// Track a call to a fn with comptime params.
    fn trackCall(this: *Aggregator, fn_name: []const u8) !void {
        const count = this.total_calls.get(fn_name) orelse 0;
        try this.total_calls.put(fn_name, count + 1);
    }

    /// Track that a call was rewritten to a specialized name.
    fn trackSpecialization(this: *Aggregator, fn_name: []const u8) !void {
        const count = this.specialized_calls.get(fn_name) orelse 0;
        try this.specialized_calls.put(fn_name, count + 1);
    }

    /// Check if a fn is fully specialized (all calls were rewritten).
    fn isFullySpecialized(this: *const Aggregator, fn_name: []const u8) bool {
        const total = this.total_calls.get(fn_name) orelse 0;
        if (total == 0) return false;
        const spec = this.specialized_calls.get(fn_name) orelse 0;
        return spec == total;
    }
};

// ── Public API ────────────────────────────────────────────────────────────────

pub fn transform(
    allocator: std.mem.Allocator,
    program: ast.Program,
    fn_decls: std.StringHashMap(ast.FnDecl),
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
    comptime_vals: std.StringHashMap([]const u8),
) !ast.Program {
    var agg = Aggregator.init(allocator, comptime_vals);
    defer agg.deinit(allocator);

    // Phase 1: Scan and specialize.
    var out_decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    errdefer {
        for (out_decls.items) |*d| d.deinit(allocator);
        out_decls.deinit(allocator);
    }

    // Track binding index for comptime val lookup.
    var binding_idx: usize = 0;

    for (program.decls) |decl| {
        try out_decls.append(allocator, decl);
        if (decl == .@"fn") {
            const fn_decl = decl.@"fn";
            for (fn_decl.body) |stmt| {
                scanStmt(&agg, fn_decls, comptime_arrays, stmt) catch return error.OutOfMemory;
            }
        }
        if (decl == .val) {
            const val_decl = decl.val;
            switch (val_decl.value.kind) {
                .@"comptime" => |inner| {
                    // Track this val for comptime value lookup.
                    const ct_id = try std.fmt.allocPrint(allocator, "ct_{d}", .{binding_idx});
                    agg.registerCtVal(val_decl.name, ct_id) catch return error.OutOfMemory;
                    scanExpr(&agg, fn_decls, comptime_arrays, inner.*) catch return error.OutOfMemory;
                },
                else => scanExpr(&agg, fn_decls, comptime_arrays, val_decl.value.*) catch return error.OutOfMemory,
            }
        }
        // Update binding index for val/fn decls.
        switch (decl) {
            .val, .@"fn" => binding_idx += 1,
            else => {},
        }
    }

    // Phase 2: Rewrite calls, remove comptime args, inline comptime vals.
    for (out_decls.items) |*decl| {
        if (decl.* == .@"fn") {
            const fn_decl = &decl.@"fn";
            for (fn_decl.body) |*stmt| {
                rewriteStmt(&agg, fn_decls, comptime_arrays, stmt) catch return error.OutOfMemory;
            }
        }
        if (decl.* == .val) {
            const val_decl = &decl.val;
            switch (val_decl.value.kind) {
                .@"comptime" => {
                    // Look up the comptime value and replace with a literal.
                    if (agg.val_ct_map.get(val_decl.name)) |ct_id| {
                        if (agg.comptime_vals.get(ct_id)) |lit| {
                            // Create a number or string literal expression.
                            val_decl.value = try makeLiteralExpr(allocator, lit);
                        }
                    }
                },
                .comptimeBlock => |cb| {
                    // For comptime blocks, look up the val name and replace the entire value.
                    if (agg.val_ct_map.get(val_decl.name)) |ct_id| {
                        if (agg.comptime_vals.get(ct_id)) |lit| {
                            val_decl.value = try makeLiteralExpr(allocator, lit);
                        }
                    }
                    _ = cb;
                },
                else => {
                    rewriteExpr(&agg, fn_decls, comptime_arrays, val_decl.value) catch return error.OutOfMemory;
                },
            }
        }
    }

    // Phase 3: Filter out fully-specialized fns and inject specialized fns.
    var filtered: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    errdefer {
        for (filtered.items) |*d| d.deinit(allocator);
        filtered.deinit(allocator);
    }

    for (out_decls.items) |decl| {
        if (decl == .@"fn") {
            const fn_decl = decl.@"fn";
            if (agg.isFullySpecialized(fn_decl.name)) {
                // Skip — dead code.
                continue;
            }
        }
        try filtered.append(allocator, decl);
    }

    // Inject specialized function declarations.
    for (agg.spec_cache.sources.items) |*spec| {
        const spec_fn = spec.*;
        var params: std.ArrayListUnmanaged(ast.Param) = .empty;
        for (spec_fn.params) |p| try params.append(allocator, p);

        var body_copy: std.ArrayListUnmanaged(ast.Stmt) = .empty;
        for (spec_fn.body) |s| try body_copy.append(allocator, s);

        const spec_decl: ast.DeclKind = .{ .@"fn" = .{
            .isPub = false,
            .name = spec_fn.name,
            .annotations = &.{},
            .genericParams = &.{},
            .params = try params.toOwnedSlice(allocator),
            .returnType = null,
            .body = try body_copy.toOwnedSlice(allocator),
        } };
        try filtered.append(allocator, spec_decl);
    }

    return ast.Program{ .decls = try filtered.toOwnedSlice(allocator) };
}

// ── Scanning ─────────────────────────────────────────────────────────────────

const ScanError = error{OutOfMemory};

fn scanStmt(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), stmt: anytype) ScanError!void {
    switch (stmt.expr.kind) {
        .localBind => |lb| scanExpr(agg, fn_decls, comptime_arrays, lb.value.*) catch return ScanError.OutOfMemory,
        .@"return" => |r| scanExpr(agg, fn_decls, comptime_arrays, r.*) catch return ScanError.OutOfMemory,
        .loop => |lp| {
            scanExpr(agg, fn_decls, comptime_arrays, lp.iter.*) catch return ScanError.OutOfMemory;
            for (lp.body) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .if_ => |if_node| {
            scanExpr(agg, fn_decls, comptime_arrays, if_node.cond.*) catch return ScanError.OutOfMemory;
            for (if_node.then_) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            if (if_node.else_) |else_stmts| {
                for (else_stmts) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            }
        },
        .assign => |a| scanExpr(agg, fn_decls, comptime_arrays, a.value.*) catch return ScanError.OutOfMemory,
        .call, .ident, .stringLit, .numberLit => scanExpr(agg, fn_decls, comptime_arrays, stmt.expr) catch return ScanError.OutOfMemory,
        else => {},
    }
}

fn scanExpr(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), expr: anytype) ScanError!void {
    switch (expr.kind) {
        .call => |c| {
            const fn_decl = fn_decls.get(c.callee) orelse {
                for (c.args) |arg| scanExpr(agg, fn_decls, comptime_arrays, arg.value.*) catch return ScanError.OutOfMemory;
                for (c.trailing) |tl| {
                    for (tl.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                }
                return;
            };

            // Try to specialize.
            _ = trySpecializeCall(agg, c.callee, fn_decl, c.args, comptime_arrays) catch false;

            for (c.args) |arg| scanExpr(agg, fn_decls, comptime_arrays, arg.value.*) catch return ScanError.OutOfMemory;
            for (c.trailing) |tl| {
                for (tl.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
            }
        },
        .localBind => |lb| scanExpr(agg, fn_decls, comptime_arrays, lb.value.*) catch return ScanError.OutOfMemory,
        .if_ => |if_node| {
            scanExpr(agg, fn_decls, comptime_arrays, if_node.cond.*) catch return ScanError.OutOfMemory;
            for (if_node.then_) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
            if (if_node.else_) |else_stmts| {
                for (else_stmts) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
            }
        },
        .loop => |lp| {
            scanExpr(agg, fn_decls, comptime_arrays, lp.iter.*) catch return ScanError.OutOfMemory;
            for (lp.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
        },
        .case => |case_node| {
            scanExpr(agg, fn_decls, comptime_arrays, case_node.subject.*) catch return ScanError.OutOfMemory;
            for (case_node.arms) |arm| scanExpr(agg, fn_decls, comptime_arrays, arm.body) catch return ScanError.OutOfMemory;
        },
        .add, .sub, .mul, .div, .mod, .eq, .ne, .lt, .gt, .lte, .gte => |b| {
            scanExpr(agg, fn_decls, comptime_arrays, b.lhs.*) catch return ScanError.OutOfMemory;
            scanExpr(agg, fn_decls, comptime_arrays, b.rhs.*) catch return ScanError.OutOfMemory;
        },
        .arrayLit => |elems| {
            for (elems) |e| scanExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
        },
        .tupleLit => |elems| {
            for (elems) |e| scanExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
        },
        .lambda => |l| {
            for (l.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
        },
        .@"comptime" => |inner| scanExpr(agg, fn_decls, comptime_arrays, inner.*) catch return ScanError.OutOfMemory,
        .comptimeBlock => |cb| {
            for (cb.body) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .throw_ => |t| scanExpr(agg, fn_decls, comptime_arrays, t.*) catch return ScanError.OutOfMemory,
        .try_ => |t| scanExpr(agg, fn_decls, comptime_arrays, t.*) catch return ScanError.OutOfMemory,
        .tryCatch => |tc| {
            scanExpr(agg, fn_decls, comptime_arrays, tc.expr.*) catch return ScanError.OutOfMemory;
            scanExpr(agg, fn_decls, comptime_arrays, tc.handler.*) catch return ScanError.OutOfMemory;
        },
        .range => |r| {
            scanExpr(agg, fn_decls, comptime_arrays, r.start.*) catch return ScanError.OutOfMemory;
            if (r.end) |e| scanExpr(agg, fn_decls, comptime_arrays, e.*) catch return ScanError.OutOfMemory;
        },
        .identAccess => |ia| scanExpr(agg, fn_decls, comptime_arrays, ia.receiver.*) catch return ScanError.OutOfMemory,
        .staticCall => |sc| scanExpr(agg, fn_decls, comptime_arrays, sc.arg.*) catch return ScanError.OutOfMemory,
        .builtinCall => |bc| {
            for (bc.args) |a| scanExpr(agg, fn_decls, comptime_arrays, a.value.*) catch return ScanError.OutOfMemory;
        },
        else => {},
    }
}

// ── Rewrite pass ─────────────────────────────────────────────────────────────

fn rewriteStmt(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), stmt: *ast.Stmt) ScanError!void {
    switch (stmt.expr.kind) {
        .call => rewriteCall(agg, fn_decls, comptime_arrays, &stmt.expr.kind.call) catch return ScanError.OutOfMemory,
        .localBind => |lb| rewriteExpr(agg, fn_decls, comptime_arrays, lb.value) catch return ScanError.OutOfMemory,
        .@"return" => |r| rewriteExpr(agg, fn_decls, comptime_arrays, r) catch return ScanError.OutOfMemory,
        .loop => |lp| {
            rewriteExpr(agg, fn_decls, comptime_arrays, lp.iter) catch return ScanError.OutOfMemory;
            for (lp.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .if_ => |if_node| {
            rewriteExpr(agg, fn_decls, comptime_arrays, if_node.cond) catch return ScanError.OutOfMemory;
            for (if_node.then_) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            if (if_node.else_) |else_stmts| {
                for (else_stmts) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, @constCast(s)) catch return ScanError.OutOfMemory;
            }
        },
        .assign => |a| rewriteExpr(agg, fn_decls, comptime_arrays, a.value) catch return ScanError.OutOfMemory,
        else => {},
    }
}

fn rewriteExpr(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), expr_ptr: *ast.Expr) ScanError!void {
    switch (expr_ptr.kind) {
        .call => rewriteCall(agg, fn_decls, comptime_arrays, &expr_ptr.kind.call) catch return ScanError.OutOfMemory,
        .localBind => |lb| rewriteExpr(agg, fn_decls, comptime_arrays, lb.value) catch return ScanError.OutOfMemory,
        .if_ => |if_node| {
            rewriteExpr(agg, fn_decls, comptime_arrays, if_node.cond) catch return ScanError.OutOfMemory;
            for (if_node.then_) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            if (if_node.else_) |else_stmts| {
                for (else_stmts) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, @constCast(s)) catch return ScanError.OutOfMemory;
            }
        },
        .loop => |lp| {
            rewriteExpr(agg, fn_decls, comptime_arrays, lp.iter) catch return ScanError.OutOfMemory;
            for (lp.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .case => |case_node| {
            rewriteExpr(agg, fn_decls, comptime_arrays, case_node.subject) catch return ScanError.OutOfMemory;
            for (case_node.arms) |*arm| rewriteExpr(agg, fn_decls, comptime_arrays, &arm.body) catch return ScanError.OutOfMemory;
        },
        .add, .sub, .mul, .div, .mod, .eq, .ne, .lt, .gt, .lte, .gte => |b| {
            rewriteExpr(agg, fn_decls, comptime_arrays, b.lhs) catch return ScanError.OutOfMemory;
            rewriteExpr(agg, fn_decls, comptime_arrays, b.rhs) catch return ScanError.OutOfMemory;
        },
        .arrayLit => |elems| {
            for (elems) |*e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
        },
        .tupleLit => |elems| {
            for (elems) |*e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
        },
        .lambda => |l| {
            for (l.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .@"comptime" => |inner| rewriteExpr(agg, fn_decls, comptime_arrays, inner) catch return ScanError.OutOfMemory,
        .comptimeBlock => |cb| {
            for (cb.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .throw_ => |t| rewriteExpr(agg, fn_decls, comptime_arrays, t) catch return ScanError.OutOfMemory,
        .try_ => |t| rewriteExpr(agg, fn_decls, comptime_arrays, t) catch return ScanError.OutOfMemory,
        .tryCatch => |tc| {
            rewriteExpr(agg, fn_decls, comptime_arrays, tc.expr) catch return ScanError.OutOfMemory;
            rewriteExpr(agg, fn_decls, comptime_arrays, tc.handler) catch return ScanError.OutOfMemory;
        },
        .range => |r| {
            rewriteExpr(agg, fn_decls, comptime_arrays, r.start) catch return ScanError.OutOfMemory;
            if (r.end) |e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
        },
        .identAccess => |ia| rewriteExpr(agg, fn_decls, comptime_arrays, ia.receiver) catch return ScanError.OutOfMemory,
        .staticCall => |sc| rewriteExpr(agg, fn_decls, comptime_arrays, sc.arg) catch return ScanError.OutOfMemory,
        .builtinCall => |bc| {
            for (bc.args) |*a| rewriteExpr(agg, fn_decls, comptime_arrays, a.value) catch return ScanError.OutOfMemory;
        },
        else => {},
    }
}

fn rewriteCall(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), c: anytype) ScanError!void {
    const fn_decl = fn_decls.get(c.callee) orelse {
        for (c.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
        for (c.trailing) |*tl| {
            for (tl.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        }
        return;
    };

    // Check if fn has comptime params and build args_key.
    var has_comptime = false;
    for (fn_decl.params) |p| {
        if (p.modifier == .@"comptime") {
            has_comptime = true;
            break;
        }
    }

    var args_key_buf: std.ArrayListUnmanaged(u8) = .empty;
    defer args_key_buf.deinit(agg.spec_cache.arena);

    if (has_comptime) {
        var ci: usize = 0;
        for (fn_decl.params) |param| {
            if (param.modifier == .@"comptime" and ci < c.args.len) {
                if (extractComptimeLiteral(c.args[ci].value.*)) |lit| {
                    if (args_key_buf.items.len > 0) try args_key_buf.append(agg.spec_cache.arena, '|');
                    try args_key_buf.appendSlice(agg.spec_cache.arena, lit);
                } else {
                    break;
                }
                ci += 1;
            }
        }
    }

    if (!has_comptime or args_key_buf.items.len == 0) {
        // Not a comptime call — just recurse.
        for (c.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
        for (c.trailing) |*tl| {
            for (tl.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        }
        return;
    }

    // Track this call.
    try agg.trackCall(c.callee);

    // Look up the specialized name.
    var found_spec: ?[]const u8 = null;
    for (agg.spec_cache.sources.items) |*spec| {
        if (std.mem.eql(u8, spec.fn_name, c.callee)) {
            var spec_key_buf: std.ArrayListUnmanaged(u8) = .empty;
            defer spec_key_buf.deinit(agg.spec_cache.arena);
            for (spec.ct_params) |cp| {
                if (spec_key_buf.items.len > 0) try spec_key_buf.append(agg.spec_cache.arena, '|');
                try spec_key_buf.appendSlice(agg.spec_cache.arena, cp.value);
            }
            if (std.mem.eql(u8, spec_key_buf.items, args_key_buf.items)) {
                found_spec = spec.name;
                break;
            }
        }
    }

    if (found_spec) |sn| {
        // Track specialization and rewrite callee name.
        try agg.trackSpecialization(c.callee);
        c.callee = sn;
    }

    // Collect comptime arg indices to remove.
    var ct_indices: std.ArrayListUnmanaged(usize) = .empty;
    defer ct_indices.deinit(agg.spec_cache.arena);
    {
        var ci: usize = 0;
        for (fn_decl.params) |param| {
            if (param.modifier == .@"comptime") {
                try ct_indices.append(agg.spec_cache.arena, ci);
            }
            ci += 1;
        }
    }

    // Build new args array without comptime args.
    if (ct_indices.items.len > 0 and c.args.len > 0) {
        var new_args: std.ArrayListUnmanaged(ast.CallArg) = .empty;
        for (c.args, 0..) |arg, ai| {
            var is_ct = false;
            for (ct_indices.items) |ci| {
                if (ci == ai) {
                    is_ct = true;
                    break;
                }
            }
            if (!is_ct) try new_args.append(agg.spec_cache.arena, arg);
        }
        c.args = try new_args.toOwnedSlice(agg.spec_cache.arena);
    }

    for (c.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
    for (c.trailing) |*tl| {
        for (tl.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
    }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Create a literal expression (number or string) from a comptime value string.
fn makeLiteralExpr(allocator: std.mem.Allocator, val: []const u8) !*ast.Expr {
    const expr = try allocator.create(ast.Expr);
    // Check if this looks like a JSON string (starts and ends with quotes).
    const is_json_string = val.len >= 2 and val[0] == '"' and val[val.len - 1] == '"';
    if (is_json_string) {
        // Strip surrounding quotes and unescape JSON.
        const inner = try allocator.dupe(u8, val[1 .. val.len - 1]);
        expr.* = .{
            .loc = .{ .line = 0, .col = 0 },
            .kind = .{ .stringLit = inner },
        };
    } else {
        // Number literal.
        expr.* = .{
            .loc = .{ .line = 0, .col = 0 },
            .kind = .{ .numberLit = try allocator.dupe(u8, val) },
        };
    }
    return expr;
}

fn trySpecializeCall(
    agg: *Aggregator,
    fn_name: []const u8,
    fn_decl: ast.FnDecl,
    args: []const ast.CallArg,
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
) !bool {
    var has_comptime = false;
    for (fn_decl.params) |p| {
        if (p.modifier == .@"comptime") {
            has_comptime = true;
            break;
        }
    }
    if (!has_comptime) return false;

    var comptime_args_buf: std.ArrayListUnmanaged([]const u8) = .empty;
    defer comptime_args_buf.deinit(agg.spec_cache.arena);

    var arg_idx: usize = 0;
    for (fn_decl.params) |param| {
        if (param.modifier != .@"comptime") {
            arg_idx += 1;
            continue;
        }
        if (arg_idx >= args.len) return false;
        if (extractComptimeLiteral(args[arg_idx].value.*)) |lit| {
            try comptime_args_buf.append(agg.spec_cache.arena, lit);
        } else {
            return false;
        }
        arg_idx += 1;
    }

    if (comptime_args_buf.items.len == 0) return false;

    const result = try agg.spec_cache.getOrPutId(fn_name, comptime_args_buf.items);

    if (result.is_new) {
        const spec_fn = try specialize.specialize(
            agg.spec_cache.arena,
            fn_decl,
            result.id,
            comptime_args_buf.items,
            comptime_arrays,
        );
        try agg.spec_cache.addSource(spec_fn);
    }

    return true;
}

fn extractComptimeLiteral(e: anytype) ?[]const u8 {
    return switch (e.kind) {
        .stringLit => |s| s,
        .numberLit => |n| n,
        else => null,
    };
}
