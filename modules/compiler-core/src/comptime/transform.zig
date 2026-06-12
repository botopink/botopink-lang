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
const envMod = @import("./env.zig");

/// Map of `@Result`/`@Option` method-call sites (by source loc) to their
/// type-directed lowering, produced by inference.
pub const MethodLowerings = std.AutoHashMap(ast.Loc, envMod.MethodLowering);

/// Map of template-call sites (by source loc) to the expanded untyped
/// expression that replaces the call, produced by inference (expr-templates F6).
pub const TemplateExpansions = std.AutoHashMap(ast.Loc, *const ast.Expr);

/// Map of `return`/`throw` sites inside `-> @Result<…>` fns (by source loc)
/// to their value-construction lowering, produced by inference.
pub const ResultJumpLowerings = std.AutoHashMap(ast.Loc, envMod.ResultJumpLowering);

/// Map of stdlib-module method calls on builtin-array receivers (by source loc).
pub const StdArrayLowerings = std.AutoHashMap(ast.Loc, envMod.StdArrayLowering);

/// Aggregator: collects specialization info during scan/rewrite phases.
const Aggregator = struct {
    spec_cache: specialize.SpecCache,
    /// Builtin `@Result`/`@Option` method lowerings keyed by call loc.
    method_lowerings: *const MethodLowerings,
    /// Template-call expansions keyed by call loc (expr-templates F6).
    template_expansions: *const TemplateExpansions,
    /// `return`/`throw` → `__bp_ok`/`__bp_error` wrappings keyed by jump loc.
    result_jump_lowerings: *const ResultJumpLowerings,
    /// Stdlib array method dispatch lowerings keyed by call loc.
    std_array_lowerings: *const StdArrayLowerings,
    /// fn_name → total calls with comptime params found during rewrite.
    total_calls: std.StringHashMap(usize),
    /// fn_name → calls that were actually rewritten to specialized names.
    specialized_calls: std.StringHashMap(usize),
    /// Comptime evaluation results: "ct_N" → "6.28"
    comptime_vals: std.StringHashMap([]const u8),
    /// val_name → ct_id mapping (e.g. "pi" → "ct_0")
    val_ct_map: std.StringHashMap([]const u8),

    fn init(allocator: std.mem.Allocator, comptime_vals: std.StringHashMap([]const u8), method_lowerings: *const MethodLowerings, template_expansions: *const TemplateExpansions, result_jump_lowerings: *const ResultJumpLowerings, std_array_lowerings: *const StdArrayLowerings) Aggregator {
        return .{
            .spec_cache = specialize.SpecCache.init(allocator),
            .method_lowerings = method_lowerings,
            .template_expansions = template_expansions,
            .result_jump_lowerings = result_jump_lowerings,
            .std_array_lowerings = std_array_lowerings,
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
    method_lowerings: *const MethodLowerings,
    template_expansions: *const TemplateExpansions,
    result_jump_lowerings: *const ResultJumpLowerings,
    std_array_lowerings: *const StdArrayLowerings,
) !ast.Program {
    var agg = Aggregator.init(allocator, comptime_vals, method_lowerings, template_expansions, result_jump_lowerings, std_array_lowerings);
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
        if (decl == .@"test") {
            const test_decl = decl.@"test";
            for (test_decl.body) |stmt| {
                scanStmt(&agg, fn_decls, comptime_arrays, stmt) catch return error.OutOfMemory;
            }
        }
        if (decl == .val) {
            const val_decl = decl.val;
            switch (val_decl.value.*) {
                .comptime_ => |ct| switch (ct.kind) {
                    .comptimeExpr => |inner| {
                        // Track this val for comptime value lookup.
                        const ct_id = try std.fmt.allocPrint(allocator, "ct_{d}", .{binding_idx});
                        agg.registerCtVal(val_decl.name, ct_id) catch return error.OutOfMemory;
                        scanExpr(&agg, fn_decls, comptime_arrays, inner.*) catch return error.OutOfMemory;
                    },
                    else => scanExpr(&agg, fn_decls, comptime_arrays, val_decl.value.*) catch return error.OutOfMemory,
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
        if (decl.* == .@"test") {
            const test_decl = &decl.@"test";
            for (test_decl.body) |*stmt| {
                rewriteStmt(&agg, fn_decls, comptime_arrays, stmt) catch return error.OutOfMemory;
            }
        }
        if (decl.* == .val) {
            const val_decl = &decl.val;
            const is_comptime = switch (val_decl.value.*) {
                .comptime_ => true,
                else => false,
            };
            if (is_comptime) {
                // Look up the comptime value and replace with a literal.
                if (agg.val_ct_map.get(val_decl.name)) |ct_id| {
                    if (agg.comptime_vals.get(ct_id)) |lit| {
                        val_decl.value.deinit(allocator);
                        allocator.destroy(val_decl.value);
                        val_decl.value = try makeLiteralExpr(allocator, lit);
                    }
                }
            } else {
                rewriteExpr(&agg, fn_decls, comptime_arrays, val_decl.value) catch return error.OutOfMemory;
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
            // Template fns (`-> @Expr<…>` / `-> @ExprCustom<…>`) are
            // comptime-only: every call was expanded (or rejected) during
            // inference — never emit them.
            if (fn_decl.returnType) |rt| {
                if (rt.isTemplateReturnType()) continue;
            }
            // Decorator fns (first param `comptime _: @Decl`) are comptime-only
            // too: their body ran over each annotated declaration during inference
            // (validation + `@emit` wiring) — emitting it would leak `__decl`/
            // `__emit`/`__compilerError` into real output. Drop them like templates.
            if (fn_decl.params.len >= 1) {
                const p0 = fn_decl.params[0];
                if (p0.modifier == .@"comptime" and p0.typeRef.isDeclType()) continue;
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
    switch (stmt.expr) {
        .binding => |b| switch (b.kind) {
            .localBind => |lb| scanExpr(agg, fn_decls, comptime_arrays, lb.value.*) catch return ScanError.OutOfMemory,
            .assign => |a| scanExpr(agg, fn_decls, comptime_arrays, a.value.*) catch return ScanError.OutOfMemory,
            else => {},
        },
        .binaryOp => |b| {
            scanExpr(agg, fn_decls, comptime_arrays, b.lhs.*) catch return ScanError.OutOfMemory;
            scanExpr(agg, fn_decls, comptime_arrays, b.rhs.*) catch return ScanError.OutOfMemory;
        },
        .jump => |j| switch (j.kind) {
            .@"return" => |r| if (r) |rp| scanExpr(agg, fn_decls, comptime_arrays, rp.*) catch return ScanError.OutOfMemory,
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |if_node| {
                scanExpr(agg, fn_decls, comptime_arrays, if_node.cond.*) catch return ScanError.OutOfMemory;
                for (if_node.then_) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                if (if_node.else_) |else_stmts| {
                    for (else_stmts) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                }
            },
            .tryCatch => |tc| {
                scanExpr(agg, fn_decls, comptime_arrays, tc.expr.*) catch return ScanError.OutOfMemory;
                scanExpr(agg, fn_decls, comptime_arrays, tc.handler.*) catch return ScanError.OutOfMemory;
            },
        },
        .loop => |lp| {
            scanExpr(agg, fn_decls, comptime_arrays, lp.iter.*) catch return ScanError.OutOfMemory;
            if (lp.indexRange) |ir| scanExpr(agg, fn_decls, comptime_arrays, ir.*) catch return ScanError.OutOfMemory;
            for (lp.body) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .call, .identifier, .literal, .comptime_ => scanExpr(agg, fn_decls, comptime_arrays, stmt.expr) catch return ScanError.OutOfMemory,
        else => {},
    }
}

fn scanExpr(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), expr: anytype) ScanError!void {
    switch (expr) {
        .literal => |lit| switch (lit.kind) {
            .stringTemplate => |t| {
                // Interpolation holes may contain comptime calls to specialize.
                for (t.parts) |p| switch (p) {
                    .text => {},
                    .expr => |hole| scanExpr(agg, fn_decls, comptime_arrays, hole.*) catch return ScanError.OutOfMemory,
                };
            },
            else => {},
        },
        .call => |c| switch (c.kind) {
            .call => |call| {
                // Method receivers may themselves contain comptime calls.
                if (call.receiver) |r| scanExpr(agg, fn_decls, comptime_arrays, r.*) catch return ScanError.OutOfMemory;
                // Builtin calls don't need specialization
                if (call.is_builtin) {
                    for (call.args) |arg| scanExpr(agg, fn_decls, comptime_arrays, arg.value.*) catch return ScanError.OutOfMemory;
                    for (call.trailing) |tl| {
                        for (tl.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                    }
                    return;
                }

                const fn_decl = fn_decls.get(call.callee) orelse {
                    for (call.args) |arg| scanExpr(agg, fn_decls, comptime_arrays, arg.value.*) catch return ScanError.OutOfMemory;
                    for (call.trailing) |tl| {
                        for (tl.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                    }
                    return;
                };
                _ = trySpecializeCall(agg, call.callee, fn_decl, call.args, comptime_arrays) catch false;
                for (call.args) |arg| scanExpr(agg, fn_decls, comptime_arrays, arg.value.*) catch return ScanError.OutOfMemory;
                for (call.trailing) |tl| {
                    for (tl.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                }
            },
            .pipeline => |p| {
                scanExpr(agg, fn_decls, comptime_arrays, p.lhs.*) catch return ScanError.OutOfMemory;
                scanExpr(agg, fn_decls, comptime_arrays, p.rhs.*) catch return ScanError.OutOfMemory;
            },
        },
        .binding => |b| switch (b.kind) {
            .localBind => |lb| scanExpr(agg, fn_decls, comptime_arrays, lb.value.*) catch return ScanError.OutOfMemory,
            else => {},
        },
        .jump => |j| switch (j.kind) {
            .throw_ => |t| if (t) |tp| scanExpr(agg, fn_decls, comptime_arrays, tp.*) catch return ScanError.OutOfMemory,
            .try_ => |t| if (t) |tp| scanExpr(agg, fn_decls, comptime_arrays, tp.*) catch return ScanError.OutOfMemory,
            .await_ => |e| scanExpr(agg, fn_decls, comptime_arrays, e.*) catch return ScanError.OutOfMemory,
            .@"return" => |r| if (r) |rp| scanExpr(agg, fn_decls, comptime_arrays, rp.*) catch return ScanError.OutOfMemory,
            .@"break" => |b| if (b) |bp| scanExpr(agg, fn_decls, comptime_arrays, bp.*) catch return ScanError.OutOfMemory,
            .yield => |y| if (y.value) |yp| scanExpr(agg, fn_decls, comptime_arrays, yp.*) catch return ScanError.OutOfMemory,
            else => {},
        },
        .branch => |br| switch (br.kind) {
            .if_ => |if_node| {
                scanExpr(agg, fn_decls, comptime_arrays, if_node.cond.*) catch return ScanError.OutOfMemory;
                for (if_node.then_) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                if (if_node.else_) |else_stmts| {
                    for (else_stmts) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
                }
            },
            .tryCatch => |tc| {
                scanExpr(agg, fn_decls, comptime_arrays, tc.expr.*) catch return ScanError.OutOfMemory;
                scanExpr(agg, fn_decls, comptime_arrays, tc.handler.*) catch return ScanError.OutOfMemory;
            },
        },
        .loop => |lp| {
            scanExpr(agg, fn_decls, comptime_arrays, lp.iter.*) catch return ScanError.OutOfMemory;
            if (lp.indexRange) |ir| scanExpr(agg, fn_decls, comptime_arrays, ir.*) catch return ScanError.OutOfMemory;
            for (lp.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
        },
        .binaryOp => |b| {
            scanExpr(agg, fn_decls, comptime_arrays, b.lhs.*) catch return ScanError.OutOfMemory;
            scanExpr(agg, fn_decls, comptime_arrays, b.rhs.*) catch return ScanError.OutOfMemory;
        },
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                for (al.elems) |e| scanExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
            },
            .tupleLit => |tl| {
                for (tl.elems) |e| scanExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
            },
            .case => |case_node| {
                for (case_node.subjects) |s| scanExpr(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                for (case_node.arms) |arm| scanExpr(agg, fn_decls, comptime_arrays, arm.body) catch return ScanError.OutOfMemory;
            },
            .range => |r| {
                scanExpr(agg, fn_decls, comptime_arrays, r.start.*) catch return ScanError.OutOfMemory;
                if (r.end) |e| scanExpr(agg, fn_decls, comptime_arrays, e.*) catch return ScanError.OutOfMemory;
            },
            else => {},
        },
        .function => |func| {
            for (func.kind.body) |s| scanExpr(agg, fn_decls, comptime_arrays, s.expr) catch return ScanError.OutOfMemory;
        },
        .identifier => |id| switch (id.kind) {
            .identAccess => |ia| scanExpr(agg, fn_decls, comptime_arrays, ia.receiver.*) catch return ScanError.OutOfMemory,
            else => {},
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| scanExpr(agg, fn_decls, comptime_arrays, inner.*) catch return ScanError.OutOfMemory,
            .comptimeBlock => |cb| {
                for (cb.body) |s| scanStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            },
            .assert => |a| {
                scanExpr(agg, fn_decls, comptime_arrays, a.condition.*) catch return ScanError.OutOfMemory;
                if (a.message) |msg| scanExpr(agg, fn_decls, comptime_arrays, msg.*) catch return ScanError.OutOfMemory;
            },
            .assertPattern => |ap| {
                scanExpr(agg, fn_decls, comptime_arrays, ap.expr.*) catch return ScanError.OutOfMemory;
                scanExpr(agg, fn_decls, comptime_arrays, ap.handler.*) catch return ScanError.OutOfMemory;
            },
        },
        else => {},
    }
}

// ── Rewrite pass ─────────────────────────────────────────────────────────────

/// If `expr_ptr` is a `@Result`/`@Option` method call recorded by inference,
/// rewrite it in place into a `__bp_<domain>_<op>(receiver, args...)` builtin
/// call (receiver becomes the first positional arg) and return true. Each
/// codegen backend lowers the `__bp_*` callee to its native Result/Option form.
fn tryLowerMethodCall(agg: *Aggregator, expr_ptr: *ast.Expr) ScanError!bool {
    if (expr_ptr.* != .call) return false;
    if (expr_ptr.call.kind != .call) return false;
    const cc = expr_ptr.call.kind.call;
    const recv = cc.receiver orelse return false;
    const loc = expr_ptr.call.loc;
    const lowering = agg.method_lowerings.get(loc) orelse return false;

    const arena = agg.spec_cache.arena;
    const domain = switch (lowering.domain) {
        .result => "result",
        .option => "option",
    };
    const opName = switch (lowering.op) {
        .map => "map",
        .flatMap => "flatMap",
        .unwrapOr => "unwrapOr",
        .isOk => "isOk",
        .isError => "isError",
    };
    const callee = std.fmt.allocPrint(arena, "__bp_{s}_{s}", .{ domain, opName }) catch return ScanError.OutOfMemory;

    // Method form (`x.map(f)`): the receiver is the subject value and becomes
    // the first arg. Qualified namespace form (`result.map(r, f)`): the
    // receiver is the namespace identifier — drop it, args are already in place.
    const new_args = if (lowering.qualified) cc.args else blk: {
        var args = arena.alloc(ast.CallArg, cc.args.len + 1) catch return ScanError.OutOfMemory;
        args[0] = .{ .label = null, .value = recv, .comments = &.{} };
        for (cc.args, 0..) |a, i| args[i + 1] = a;
        break :blk args;
    };

    expr_ptr.* = ast.Expr{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = null,
        .callee = callee,
        .is_builtin = true,
        .args = new_args,
        .trailing = cc.trailing,
    } } } };
    return true;
}

/// If `expr_ptr` is a stdlib array method call recorded by inference
/// (e.g. `xs.isEmpty()`), rewrite it to `list.isEmpty(xs)` — a qualified std
/// module call — and return true. The transform then walks the new args.
fn tryLowerStdArrayCall(agg: *Aggregator, expr_ptr: *ast.Expr) ScanError!bool {
    if (expr_ptr.* != .call) return false;
    if (expr_ptr.call.kind != .call) return false;
    const cc = expr_ptr.call.kind.call;
    const recv = cc.receiver orelse return false;
    const loc = expr_ptr.call.loc;
    const lowering = agg.std_array_lowerings.get(loc) orelse return false;

    const arena = agg.spec_cache.arena;

    // New args: [original_receiver, ...original_args]
    const new_args = arena.alloc(ast.CallArg, cc.args.len + 1) catch return ScanError.OutOfMemory;
    new_args[0] = .{ .label = null, .value = recv, .comments = &.{} };
    for (cc.args, 0..) |a, i| new_args[i + 1] = a;

    // New receiver: the stdlib module identifier (e.g. `list`).
    const mod_ident = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
    mod_ident.* = ast.Expr{ .identifier = .{ .loc = loc, .kind = .{ .ident = lowering.module } } };

    expr_ptr.* = ast.Expr{ .call = .{ .loc = loc, .kind = .{ .call = .{
        .receiver = mod_ident,
        .callee = lowering.method,
        .is_builtin = false,
        .args = new_args,
        .trailing = cc.trailing,
    } } } };
    return true;
}

/// If `expr_ptr` is a `return`/`throw` jump recorded by inference as a Result
/// constructor site, wrap the value in a `__bp_ok(…)` / `__bp_error(…)` builtin
/// call — and rewrite `throw e` into `return __bp_error(e)` so every backend
/// emits an ordinary function return carrying the `{error, E}` value.
fn tryLowerResultJump(agg: *Aggregator, expr_ptr: *ast.Expr) ScanError!bool {
    if (expr_ptr.* != .jump) return false;
    const loc = expr_ptr.jump.loc;
    const lowering = agg.result_jump_lowerings.get(loc) orelse return false;
    const arena = agg.spec_cache.arena;

    const wrapCall = struct {
        fn make(a: std.mem.Allocator, callee: []const u8, value: *ast.Expr, l: ast.Loc) ScanError!*ast.Expr {
            const args = a.alloc(ast.CallArg, 1) catch return ScanError.OutOfMemory;
            args[0] = .{ .label = null, .value = value, .comments = &.{} };
            const call_expr = a.create(ast.Expr) catch return ScanError.OutOfMemory;
            call_expr.* = ast.Expr{ .call = .{ .loc = l, .kind = .{ .call = .{
                .receiver = null,
                .callee = callee,
                .is_builtin = true,
                .args = args,
                .trailing = &.{},
            } } } };
            return call_expr;
        }
    }.make;

    switch (lowering) {
        .wrap_ok => {
            if (expr_ptr.jump.kind != .@"return") return false;
            const rp = expr_ptr.jump.kind.@"return" orelse return false;
            expr_ptr.jump.kind = .{ .@"return" = try wrapCall(arena, "__bp_ok", rp, loc) };
        },
        .wrap_error => {
            if (expr_ptr.jump.kind != .throw_) return false;
            const tp = expr_ptr.jump.kind.throw_ orelse return false;
            expr_ptr.jump.kind = .{ .@"return" = try wrapCall(arena, "__bp_error", tp, loc) };
        },
        .unwrap_passthrough => {
            // `return try f()` → `return f()` (drop the redundant unwrap).
            if (expr_ptr.jump.kind != .@"return") return false;
            const rp = expr_ptr.jump.kind.@"return" orelse return false;
            if (rp.* != .jump or rp.jump.kind != .try_) return false;
            const inner = rp.jump.kind.try_ orelse return false;
            expr_ptr.jump.kind = .{ .@"return" = inner };
        },
    }
    return true;
}

fn rewriteStmt(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), stmt: *ast.Stmt) ScanError!void {
    // Template-call expansion (F6): substitute the expansion recorded by
    // inference, then process the spliced code like ordinary AST.
    if (stmt.expr == .call and stmt.expr.call.kind == .call) {
        if (agg.template_expansions.get(stmt.expr.call.loc)) |expansion| {
            stmt.expr = expansion.*;
            rewriteExpr(agg, fn_decls, comptime_arrays, &stmt.expr) catch return ScanError.OutOfMemory;
            return;
        }
    }
    switch (stmt.expr) {
        .call => |*c| switch (c.kind) {
            .call => {
                if (try tryLowerMethodCall(agg, &stmt.expr)) {
                    for (stmt.expr.call.kind.call.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
                } else if (try tryLowerStdArrayCall(agg, &stmt.expr)) {
                    for (stmt.expr.call.kind.call.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
                } else {
                    if (c.kind.call.receiver) |r| rewriteExpr(agg, fn_decls, comptime_arrays, r) catch return ScanError.OutOfMemory;
                    rewriteCall(agg, fn_decls, comptime_arrays, &c.kind.call) catch return ScanError.OutOfMemory;
                }
            },
            else => {},
        },
        .binding => |*b| switch (b.kind) {
            .localBind => |lb| rewriteExpr(agg, fn_decls, comptime_arrays, lb.value) catch return ScanError.OutOfMemory,
            .assign => |a| rewriteExpr(agg, fn_decls, comptime_arrays, a.value) catch return ScanError.OutOfMemory,
            else => {},
        },
        .jump => {
            _ = try tryLowerResultJump(agg, &stmt.expr);
            switch (stmt.expr.jump.kind) {
                .@"return" => |r| if (r) |rp| rewriteExpr(agg, fn_decls, comptime_arrays, rp) catch return ScanError.OutOfMemory,
                .throw_ => |t| if (t) |tp| rewriteExpr(agg, fn_decls, comptime_arrays, tp) catch return ScanError.OutOfMemory,
                .try_ => |t| if (t) |tp| rewriteExpr(agg, fn_decls, comptime_arrays, tp) catch return ScanError.OutOfMemory,
                .await_ => |e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory,
                .@"break" => |b| if (b) |bp| rewriteExpr(agg, fn_decls, comptime_arrays, bp) catch return ScanError.OutOfMemory,
                .yield => |y| if (y.value) |yp| rewriteExpr(agg, fn_decls, comptime_arrays, yp) catch return ScanError.OutOfMemory,
                .@"continue" => {},
            }
        },
        .branch => |*br| switch (br.kind) {
            .if_ => |if_node| {
                rewriteExpr(agg, fn_decls, comptime_arrays, if_node.cond) catch return ScanError.OutOfMemory;
                for (if_node.then_) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                if (if_node.else_) |else_stmts| {
                    for (else_stmts) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, @constCast(s)) catch return ScanError.OutOfMemory;
                }
            },
            .tryCatch => |tc| {
                rewriteExpr(agg, fn_decls, comptime_arrays, tc.expr) catch return ScanError.OutOfMemory;
                rewriteExpr(agg, fn_decls, comptime_arrays, tc.handler) catch return ScanError.OutOfMemory;
            },
        },
        .loop => |*lp| {
            rewriteExpr(agg, fn_decls, comptime_arrays, lp.iter) catch return ScanError.OutOfMemory;
            if (lp.indexRange) |ir| rewriteExpr(agg, fn_decls, comptime_arrays, ir) catch return ScanError.OutOfMemory;
            for (lp.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .comptime_ => rewriteExpr(agg, fn_decls, comptime_arrays, &stmt.expr) catch return ScanError.OutOfMemory,
        else => {},
    }
}

fn rewriteExpr(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), expr_ptr: *ast.Expr) ScanError!void {
    // Template-call expansion (F6): substitute the expansion recorded by
    // inference, then fall through so the spliced code is rewritten like
    // ordinary AST (string templates desugar, inner calls lower, …).
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call) {
        if (agg.template_expansions.get(expr_ptr.call.loc)) |expansion| {
            expr_ptr.* = expansion.*;
        }
    }
    switch (expr_ptr.*) {
        .call => |*c| switch (c.kind) {
            .call => {
                if (try tryLowerMethodCall(agg, expr_ptr)) {
                    for (expr_ptr.call.kind.call.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
                } else if (try tryLowerStdArrayCall(agg, expr_ptr)) {
                    for (expr_ptr.call.kind.call.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
                } else {
                    if (c.kind.call.receiver) |r| rewriteExpr(agg, fn_decls, comptime_arrays, r) catch return ScanError.OutOfMemory;
                    rewriteCall(agg, fn_decls, comptime_arrays, &c.kind.call) catch return ScanError.OutOfMemory;
                }
            },
            .pipeline => |p| {
                rewriteExpr(agg, fn_decls, comptime_arrays, p.lhs) catch return ScanError.OutOfMemory;
                rewriteExpr(agg, fn_decls, comptime_arrays, p.rhs) catch return ScanError.OutOfMemory;
            },
        },
        .binding => |*b| switch (b.kind) {
            .localBind => |lb| rewriteExpr(agg, fn_decls, comptime_arrays, lb.value) catch return ScanError.OutOfMemory,
            else => {},
        },
        .jump => {
            _ = try tryLowerResultJump(agg, expr_ptr);
            switch (expr_ptr.jump.kind) {
                .@"return" => |r| if (r) |rp| rewriteExpr(agg, fn_decls, comptime_arrays, rp) catch return ScanError.OutOfMemory,
                .@"break" => |b| if (b) |bp| rewriteExpr(agg, fn_decls, comptime_arrays, bp) catch return ScanError.OutOfMemory,
                .yield => |y| if (y.value) |yp| rewriteExpr(agg, fn_decls, comptime_arrays, yp) catch return ScanError.OutOfMemory,
                .@"continue" => {},
                .throw_ => |t| if (t) |tp| rewriteExpr(agg, fn_decls, comptime_arrays, tp) catch return ScanError.OutOfMemory,
                .try_ => |t| if (t) |tp| rewriteExpr(agg, fn_decls, comptime_arrays, tp) catch return ScanError.OutOfMemory,
                .await_ => |e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory,
            }
        },
        .branch => |*br| switch (br.kind) {
            .if_ => |if_node| {
                rewriteExpr(agg, fn_decls, comptime_arrays, if_node.cond) catch return ScanError.OutOfMemory;
                for (if_node.then_) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                if (if_node.else_) |else_stmts| {
                    for (else_stmts) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, @constCast(s)) catch return ScanError.OutOfMemory;
                }
            },
            .tryCatch => |tc| {
                rewriteExpr(agg, fn_decls, comptime_arrays, tc.expr) catch return ScanError.OutOfMemory;
                rewriteExpr(agg, fn_decls, comptime_arrays, tc.handler) catch return ScanError.OutOfMemory;
            },
        },
        .loop => |*lp| {
            rewriteExpr(agg, fn_decls, comptime_arrays, lp.iter) catch return ScanError.OutOfMemory;
            if (lp.indexRange) |ir| rewriteExpr(agg, fn_decls, comptime_arrays, ir) catch return ScanError.OutOfMemory;
            for (lp.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .binaryOp => |*b| {
            rewriteExpr(agg, fn_decls, comptime_arrays, b.lhs) catch return ScanError.OutOfMemory;
            rewriteExpr(agg, fn_decls, comptime_arrays, b.rhs) catch return ScanError.OutOfMemory;
        },
        .collection => |*col| switch (col.kind) {
            .arrayLit => |al| {
                for (al.elems) |*e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
            },
            .tupleLit => |tl| {
                for (tl.elems) |*e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
            },
            .case => |case_node| {
                for (case_node.subjects) |*s| rewriteExpr(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
                for (case_node.arms) |*arm| rewriteExpr(agg, fn_decls, comptime_arrays, &arm.body) catch return ScanError.OutOfMemory;
            },
            .range => |r| {
                rewriteExpr(agg, fn_decls, comptime_arrays, r.start) catch return ScanError.OutOfMemory;
                if (r.end) |e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
            },
            else => {},
        },
        .function => |*func| {
            for (func.kind.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        },
        .identifier => |*id| switch (id.kind) {
            .identAccess => |ia| rewriteExpr(agg, fn_decls, comptime_arrays, ia.receiver) catch return ScanError.OutOfMemory,
            else => {},
        },
        .comptime_ => |*ct| switch (ct.kind) {
            .comptimeExpr => |inner| rewriteExpr(agg, fn_decls, comptime_arrays, inner) catch return ScanError.OutOfMemory,
            .comptimeBlock => |cb| {
                for (cb.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
            },
            .assert => |a| {
                rewriteExpr(agg, fn_decls, comptime_arrays, a.condition) catch return ScanError.OutOfMemory;
                if (a.message) |msg| rewriteExpr(agg, fn_decls, comptime_arrays, msg) catch return ScanError.OutOfMemory;
            },
            .assertPattern => |ap| {
                rewriteExpr(agg, fn_decls, comptime_arrays, ap.expr) catch return ScanError.OutOfMemory;
                rewriteExpr(agg, fn_decls, comptime_arrays, ap.handler) catch return ScanError.OutOfMemory;
            },
        },
        .literal => |*lit| switch (lit.kind) {
            .stringTemplate => |t| {
                // Desugar `"a ${x} b"` into the `+` chain `"a " + x + " b"` so
                // every backend emits it exactly like written-out string
                // concatenation (the typed/eval path desugars in infer).
                const arena = agg.spec_cache.arena;
                const loc = lit.loc;
                var acc: ?*ast.Expr = null;
                if (t.parts.len > 0 and t.parts[0] == .expr) {
                    // Force a string-typed result when the template starts with a hole.
                    const empty = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
                    empty.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = "" } } };
                    acc = empty;
                }
                for (t.parts) |p| {
                    const operand: *ast.Expr = switch (p) {
                        .text => |txt| blk: {
                            const e = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
                            e.* = .{ .literal = .{ .loc = loc, .kind = .{ .stringLit = txt } } };
                            break :blk e;
                        },
                        .expr => |e| blk: {
                            rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory;
                            break :blk e;
                        },
                    };
                    if (acc) |lhs| {
                        const bin = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
                        bin.* = .{ .binaryOp = .{ .loc = loc, .op = .add, .lhs = lhs, .rhs = operand } };
                        acc = bin;
                    } else {
                        acc = operand;
                    }
                }
                expr_ptr.* = acc.?.*;
            },
            else => {},
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
        const inner = try allocator.dupe(u8, val[1 .. val.len - 1]);
        expr.* = .{ .literal = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .stringLit = inner } } };
    } else {
        expr.* = .{ .literal = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .numberLit = try allocator.dupe(u8, val) } } };
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
    // Template fns (`-> @Expr<…>` / `-> @ExprCustom<…>`) are expanded at their
    // call sites (F6), never specialized.
    if (fn_decl.returnType) |rt| {
        if (rt.isTemplateReturnType()) return false;
    }
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
    return switch (e) {
        .literal => |lit| switch (lit.kind) {
            .stringLit => |s| s,
            .numberLit => |n| n,
            else => null,
        },
        else => null,
    };
}
