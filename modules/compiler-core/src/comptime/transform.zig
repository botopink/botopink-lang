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

/// §enum-sections F2 — map of path-access (`.Color.Red.500`) outer-identAccess
/// locs → the qualified-ctor rewrite expression assembled at inference time.
pub const EnumSectionRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr);

/// C-02 (decision 63, amended 2026-09-19) — map of index-expression locs to
/// the method call each one IS: `xs[k]` → `xs.at(k)`, `xs[a..b]` →
/// `xs.slice(a, b)`, `xs[1..]` → `xs.slice(1, null)`, and a tuple's `t[0]` →
/// the positional `t._0`. Written by inference, which typed the rewrite and
/// not the index; applied here, so the backends see a method call they already
/// emit and **none of them learns a new rule**.
pub const IndexRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr);
/// Decision 8 §10 — locs of loops inference typed as condition loops.
/// C-04 (01 step 7, N1) — map of call sites (by source loc) to the argument
/// fill inference planned for them. Written whenever a call omitted an argument
/// whose parameter declares a default; the transform materialises the plan so
/// every backend sees a complete call and none of them learns a new rule.
pub const DefaultInjections = std.AutoHashMap(ast.Loc, envMod.DefaultFill);

/// Decision 54 — locs of the `case`s that are the optional's pattern form,
/// mapped to the binder's name (`""` for `_`). Produced by inference, which
/// validated the shape and narrowed the binder; `rewriteExpr` replaces each
/// with the `if (x) { v -> … } else { … }` the backends already lower.
pub const OptionalNullCases = std.AutoHashMap(ast.Loc, []const u8);

/// Aggregator: collects specialization info during scan/rewrite phases.
const Aggregator = struct {
    spec_cache: specialize.SpecCache,
    /// Builtin `@Result`/`@Option` method lowerings keyed by call loc.
    method_lowerings: *const MethodLowerings,
    /// Template-call expansions keyed by call loc (expr-templates F6).
    template_expansions: *const TemplateExpansions,
    /// `@src()` → `SourceLocation(…)` constructor calls keyed by call loc
    /// (1.0.10-beta decision 73). Same shape as `template_expansions`, spliced
    /// at the same two points; kept apart so a source location is not counted
    /// as a template expansion by the comptime snapshot.
    src_rewrites: *const TemplateExpansions,
    /// `return`/`throw` → `__bp_ok`/`__bp_error` wrappings keyed by jump loc.
    result_jump_lowerings: *const ResultJumpLowerings,
    /// Stdlib array method dispatch lowerings keyed by call loc.
    std_array_lowerings: *const StdArrayLowerings,
    /// §enum-sections F2 — untyped AST rewrites for dot-shorthand chains
    /// that the F2 path-resolver matched against an enum section path.
    enum_section_rewrites: *const EnumSectionRewrites,
    /// C-02 — the index expressions inference rewrote to method calls. Applied
    /// by BOTH aggregators, the `src_only` one included: an index in a method
    /// body is the same expression it is in a fn body, and a `[]` left in the
    /// tree reaches each backend's own decision-30 lowering instead of the
    /// method the language says it is.
    index_rewrites: *const IndexRewrites,
    /// Decision 8 §10 — loops to mark `condition` (their `iter` is a `bool`).
    optional_null_cases: *const OptionalNullCases,
    /// True for the aggregator that walks method bodies: every map but
    /// `src_rewrites` is empty and the one unconditional rewrite (the `${}`
    /// template desugar) is skipped, so a method body lowers byte-for-byte as
    /// before 1.0.10-beta except for the `@src()` splice. Lowering method
    /// bodies through the full walk is a separate change: it moves
    /// `record_method_with_todo_placeholder` on erlang (`@todo()` gets its
    /// default injected there as it does in a fn body).
    src_only: bool = false,
    /// fn_name → total calls with comptime params found during rewrite.
    total_calls: std.StringHashMap(usize),
    /// fn_name → calls that were actually rewritten to specialized names.
    specialized_calls: std.StringHashMap(usize),
    /// Comptime evaluation results: "ct_N" → "6.28"
    comptime_vals: std.StringHashMap([]const u8),
    /// val_name → ct_id mapping (e.g. "pi" → "ct_0")
    val_ct_map: std.StringHashMap([]const u8),
    /// Constructor param lists for record / struct / enum-variant types,
    /// populated by `env.ctorParams` (see comptime/env.zig). `rewriteCall`
    /// reads them when the callee misses `fn_decls` so `Config(host: "x")`
    /// / `Level.Error("boom")` get their trailing-default fields injected.
    ctor_params: std.StringHashMap([]const ast.Param),
    /// C-04 — the argument fills inference planned, keyed by call loc. Applied
    /// by BOTH aggregators, the `src_only` one included: a method body's call
    /// sites need their defaults as much as a fn body's do.
    default_injections: *const DefaultInjections,

    fn init(allocator: std.mem.Allocator, comptime_vals: std.StringHashMap([]const u8), method_lowerings: *const MethodLowerings, template_expansions: *const TemplateExpansions, src_rewrites: *const TemplateExpansions, result_jump_lowerings: *const ResultJumpLowerings, std_array_lowerings: *const StdArrayLowerings, enum_section_rewrites: *const EnumSectionRewrites, index_rewrites: *const IndexRewrites, optional_null_cases: *const OptionalNullCases, ctor_params: std.StringHashMap([]const ast.Param), default_injections: *const DefaultInjections) Aggregator {
        return .{
            .spec_cache = specialize.SpecCache.init(allocator),
            .method_lowerings = method_lowerings,
            .template_expansions = template_expansions,
            .src_rewrites = src_rewrites,
            .result_jump_lowerings = result_jump_lowerings,
            .std_array_lowerings = std_array_lowerings,
            .enum_section_rewrites = enum_section_rewrites,
            .index_rewrites = index_rewrites,
            .optional_null_cases = optional_null_cases,
            .total_calls = std.StringHashMap(usize).init(allocator),
            .specialized_calls = std.StringHashMap(usize).init(allocator),
            .comptime_vals = comptime_vals,
            .val_ct_map = std.StringHashMap([]const u8).init(allocator),
            .ctor_params = ctor_params,
            .default_injections = default_injections,
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
    src_rewrites: *const TemplateExpansions,
    result_jump_lowerings: *const ResultJumpLowerings,
    std_array_lowerings: *const StdArrayLowerings,
    enum_section_rewrites: *const EnumSectionRewrites,
    index_rewrites: *const IndexRewrites,
    optional_null_cases: *const OptionalNullCases,
    ctor_params: std.StringHashMap([]const ast.Param),
    default_injections: *const DefaultInjections,
) !ast.Program {
    var agg = Aggregator.init(allocator, comptime_vals, method_lowerings, template_expansions, src_rewrites, result_jump_lowerings, std_array_lowerings, enum_section_rewrites, index_rewrites, optional_null_cases, ctor_params, default_injections);
    defer agg.deinit(allocator);

    // The method-body aggregator (`src_only`): the `@src()` splice alone.
    var empty_ml = MethodLowerings.init(allocator);
    defer empty_ml.deinit();
    var empty_te = TemplateExpansions.init(allocator);
    defer empty_te.deinit();
    var empty_rj = ResultJumpLowerings.init(allocator);
    defer empty_rj.deinit();
    var empty_sa = StdArrayLowerings.init(allocator);
    defer empty_sa.deinit();
    var empty_es = EnumSectionRewrites.init(allocator);
    defer empty_es.deinit();
    var empty_onc = OptionalNullCases.init(allocator);
    defer empty_onc.deinit();
    const empty_vals = std.StringHashMap([]const u8).init(allocator);
    const empty_ctor = std.StringHashMap([]const ast.Param).init(allocator);
    const empty_fn_decls = std.StringHashMap(ast.FnDecl).init(allocator);
    const empty_ct_arrays = std.StringHashMap([]const ast.TypedExpr).init(allocator);
    var src_agg = Aggregator.init(allocator, empty_vals, &empty_ml, &empty_te, src_rewrites, &empty_rj, &empty_sa, &empty_es, index_rewrites, &empty_onc, empty_ctor, default_injections);
    src_agg.src_only = true;
    defer src_agg.deinit(allocator);

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
        // Method bodies (`type X { fn m(self) { … } }`, `implement B for X { … }`)
        // never went through this walk — the backends lower them from the
        // parsed AST. 1.0.10-beta's `@src()` (decision 73) is the first
        // inference-recorded rewrite a method body must receive, so they ride
        // the `src_only` aggregator: the splice and nothing else (see the
        // field's doc for what the full walk would move).
        if (src_rewrites.count() > 0) {
            if (decl.* == .type_) {
                for (decl.type_.methods) |*m| {
                    const body = m.body orelse continue;
                    for (body) |*stmt| rewriteStmt(&src_agg, empty_fn_decls, empty_ct_arrays, stmt) catch return error.OutOfMemory;
                }
            }
            if (decl.* == .implement) {
                for (decl.implement.methods) |*m| {
                    for (m.body) |*stmt| rewriteStmt(&src_agg, empty_fn_decls, empty_ct_arrays, stmt) catch return error.OutOfMemory;
                }
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
            .@"break" => |b| if (b.value) |bp| scanExpr(agg, fn_decls, comptime_arrays, bp.*) catch return ScanError.OutOfMemory,
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
            // A bare `return;` in a `-> @Result<void, E>` fn (decision 74)
            // wraps the unit value: `__bp_ok(null)`.
            const rp = expr_ptr.jump.kind.@"return" orelse blk: {
                const unit = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
                unit.* = .{ .literal = .{ .loc = loc, .kind = .null_ } };
                break :blk unit;
            };
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
        // Decision 122 — an item `U` of a sequence of `@Result<U, E>` is
        // emitted as `Ok(v)`: `yield v` → `yield __bp_ok(v)`, `break v` →
        // `break __bp_ok(v)`.
        .yield_ok => switch (expr_ptr.jump.kind) {
            .yield => |*y| {
                const vp = y.value orelse return false;
                y.value = try wrapCall(arena, "__bp_ok", vp, loc);
            },
            .@"break" => |*b| {
                const vp = b.value orelse return false;
                b.value = try wrapCall(arena, "__bp_ok", vp, loc);
            },
            else => return false,
        },
        // Decision 122 — `throw e` in such a sequence emits `Error(e)` as the
        // last item and ends: `break __bp_error(e)`.
        .break_error => {
            if (expr_ptr.jump.kind != .throw_) return false;
            const tp = expr_ptr.jump.kind.throw_ orelse return false;
            expr_ptr.jump.kind = .{ .@"break" = .{ .label = null, .value = try wrapCall(arena, "__bp_error", tp, loc) } };
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
        // `@src()` at statement position (decision 73) — the same splice.
        if (agg.src_rewrites.get(stmt.expr.call.loc)) |rewrite| {
            if (stmt.expr.call.kind.call.is_builtin) {
                stmt.expr = rewrite.*;
                rewriteExpr(agg, fn_decls, comptime_arrays, &stmt.expr) catch return ScanError.OutOfMemory;
                return;
            }
        }
    }
    // C-04 — the same fill at statement position (`b.bump();`).
    if (stmt.expr == .call and stmt.expr.call.kind == .call) {
        if (agg.default_injections.get(stmt.expr.call.loc)) |fill| {
            applyDefaultFill(agg, fill, &stmt.expr.call.kind.call) catch return ScanError.OutOfMemory;
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
                .@"break" => |b| if (b.value) |bp| rewriteExpr(agg, fn_decls, comptime_arrays, bp) catch return ScanError.OutOfMemory,
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
        // Decision 54's `?T` pattern form at statement position. Only that one
        // swap: `rewriteStmt` has never walked into a `case`'s arms, and giving
        // it a general `.collection` arm would start lowering things inside
        // them that no snapshot has ever recorded. The `if` it becomes is
        // re-dispatched through this same function, so its branches are walked
        // exactly as a written `if`'s are.
        .collection => |*col| if (col.kind == .case) {
            if (agg.optional_null_cases.get(col.loc)) |binder| {
                try rewriteOptionalNullCase(agg, &stmt.expr, binder);
                rewriteStmt(agg, fn_decls, comptime_arrays, stmt) catch return ScanError.OutOfMemory;
            }
        },
        else => {},
    }
}

/// The statements an arm's body contributes to an `if` branch. Decision 8's
/// `Pattern { body }` arm is a parameterless lambda, so its statements are the
/// branch's; the older `pattern -> value` arm is one expression.
fn armBodyStmts(allocator: std.mem.Allocator, body: ast.Expr) ScanError![]ast.Stmt {
    if (body == .function) return body.function.kind.body;
    const stmts = allocator.alloc(ast.Stmt, 1) catch return ScanError.OutOfMemory;
    stmts[0] = .{ .expr = body };
    return stmts;
}

/// Decision 54 — `case x { null { A } v { B } }` becomes
/// `if (x) { v -> B } else { A }`. Inference validated the shape (exactly two
/// arms, `null` first, a binder second, the subject a `?T`) and narrowed `v` to
/// the payload; all that is left is the node swap, and it is done here rather
/// than in the backends because the `if`-binder lowering is one every backend
/// already has. Nothing below inference learns a new pattern.
fn rewriteOptionalNullCase(
    agg: *Aggregator,
    expr_ptr: *ast.Expr,
    binder: []const u8,
) ScanError!void {
    const c = expr_ptr.collection.kind.case;
    if (c.subjects.len != 1 or c.arms.len != 2) return;
    const arena = agg.spec_cache.arena;
    const loc = expr_ptr.collection.loc;
    const cond = arena.create(ast.Expr) catch return ScanError.OutOfMemory;
    cond.* = c.subjects[0];
    expr_ptr.* = .{
        .branch = .{
            .loc = loc,
            .kind = .{
                .if_ = .{
                    .cond = cond,
                    // `_` binds the name `_`, never a null binding: a null `binding` is
                    // "this `if` has no binder at all", which makes the condition a `bool`
                    // and the optional's absence a truthiness test. The discard is the one
                    // `val _ = …` and `if (x) { _ -> … }` already record.
                    .binding = if (binder.len > 0) binder else "_",
                    .then_ = try armBodyStmts(arena, c.arms[1].body),
                    .else_ = try armBodyStmts(arena, c.arms[0].body),
                },
            },
        },
    };
}

fn rewriteExpr(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), expr_ptr: *ast.Expr) ScanError!void {
    // Decision 54's `?T` pattern form — swapped before the other dispatches so
    // the `if` it becomes rides through the same recursive walker.
    if (expr_ptr.* == .collection and expr_ptr.collection.kind == .case) {
        if (agg.optional_null_cases.get(expr_ptr.collection.loc)) |binder| {
            try rewriteOptionalNullCase(agg, expr_ptr, binder);
        }
    }
    // §enum-sections F2 — swap dot-shorthand path-access chains
    // (`.Color.Red.500`) with the qualified-ctor rewrite that F2 stashed
    // under the outer-identAccess loc. Runs before the other dispatches so
    // the swapped expression rides through the same recursive walker.
    if (expr_ptr.* == .identifier and expr_ptr.identifier.kind == .identAccess) {
        if (agg.enum_section_rewrites.get(expr_ptr.identifier.loc)) |rewrite| {
            expr_ptr.* = rewrite.*;
        }
    }
    // 01 step 12 — a leading-dot unit variant (`.Red`) whose enum the
    // position's expected type named: inference recorded the qualified
    // `Warm.Red` under the node's loc, so every backend sees the qualified
    // form. Only an identifier replaces an identifier; a call at the same loc
    // is the index/leading-dot call rewrite below.
    if (expr_ptr.* == .identifier and expr_ptr.identifier.kind == .dotIdent) {
        if (agg.index_rewrites.get(expr_ptr.identifier.loc)) |rewrite| {
            if (rewrite.* == .identifier) expr_ptr.* = rewrite.*;
        }
    }
    // Decision 110 rule 1 — an imported type's `as` alias in expression
    // position (`D` in `D.empty()`, a bare `P`): inference recorded the
    // declared name under the alias's loc. Only a plain name replaces a plain
    // name.
    if (expr_ptr.* == .identifier and expr_ptr.identifier.kind == .ident) {
        if (agg.index_rewrites.get(expr_ptr.identifier.loc)) |rewrite| {
            if (rewrite.* == .identifier and rewrite.identifier.kind == .ident) expr_ptr.* = rewrite.*;
        }
    }
    // 06 N24 — a tuple element of function type called by its LABEL
    // (`c.set(9)` on `#(value: i32, set: fn(…))`). Inference stashed the
    // positional callee under the call's loc; only the name moves, the
    // arguments stay where they are.
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call) {
        if (agg.enum_section_rewrites.get(expr_ptr.call.loc)) |rewrite| {
            if (rewrite.* == .call and rewrite.call.kind == .call) {
                expr_ptr.call.kind.call.callee = rewrite.call.kind.call.callee;
            }
        }
    }
    // Template-call expansion (F6): substitute the expansion recorded by
    // inference, then fall through so the spliced code is rewritten like
    // ordinary AST (string templates desugar, inner calls lower, …).
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call) {
        if (agg.template_expansions.get(expr_ptr.call.loc)) |expansion| {
            expr_ptr.* = expansion.*;
        }
    }
    // `@src()` → `SourceLocation(file: …, line: …, column: …, fnName: …)`
    // (decision 73). Only the builtin call at that loc is replaced — the
    // spliced constructor call carries the same loc and must not loop.
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call and expr_ptr.call.kind.call.is_builtin) {
        if (agg.src_rewrites.get(expr_ptr.call.loc)) |rewrite| {
            expr_ptr.* = rewrite.*;
        }
    }
    // C-02 (decision 63, amended 2026-09-19) — the index IS a method call.
    // `xs[k]` was typed as `xs.at(k)`, `xs[a..b]` as `xs.slice(a, b)` and a
    // tuple's `t[0]` as `t._0`; the rewrite inference recorded under this loc
    // takes the `[]` node's place here, and the walk carries on over the
    // spliced node — so its own method lowering, its C-04 fill and a nested
    // index inside its receiver or its arguments are all reached below,
    // exactly as they would be had the author written the method call.
    //
    // It sits after `@src()` and before C-04 for that reason: the fill and
    // the method lowering reshape an argument list, and there has to BE one.
    //
    // The same channel carries front 15's leading-dot call: `.Circle(r: 1)`
    // arrives with its callee in `calleeExpr` and is replaced by the named
    // constructor call inference resolved (`Shape.Circle(r: 1)`).
    //
    // And 01 step 12's payload section path (`.Color.Hex("#abc")`,
    // `Token.Color.Hex("#abc")`): a call whose receiver is a path, replaced by
    // the qualified constructor chain inference resolved.
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call and
        (expr_ptr.call.kind.call.is_builtin or expr_ptr.call.kind.call.calleeExpr != null or
            isPathReceiver(expr_ptr.call.kind.call.receiver)))
    {
        if (agg.index_rewrites.get(expr_ptr.call.loc)) |rewrite| {
            if (rewrite.* != .jump) expr_ptr.* = rewrite.*;
        }
    }
    // 01 — a component called inside a component body renders there: the
    // `await` inference spliced around it. Its operand is the rewrite's own
    // copy of the call, which is not wrapped a second time.
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call) {
        if (agg.index_rewrites.get(expr_ptr.call.loc)) |rewrite| {
            if (rewrite.* == .jump and rewrite.jump.kind == .await_ and rewrite.jump.kind.await_ != expr_ptr) {
                expr_ptr.* = rewrite.*;
            }
        }
    }
    // C-04 / 01 step 7 N1 — a call that omitted an argument whose parameter
    // declares a default. Inference accepted it and planned the fill under this
    // loc; materialise it HERE, before the method and std-array lowerings, which
    // reshape the argument list they are handed.
    //
    // It and decision 54's `optional_null_cases` swap above are both loc-keyed
    // and neither can skip the other: they act on disjoint node kinds (a `.call`
    // and a `case` `.collection`), and the `if` the swap produces is walked by
    // this same function, so a call inside a swapped arm still reaches its fill.
    if (expr_ptr.* == .call and expr_ptr.call.kind == .call) {
        if (agg.default_injections.get(expr_ptr.call.loc)) |fill| {
            applyDefaultFill(agg, fill, &expr_ptr.call.kind.call) catch return ScanError.OutOfMemory;
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
                .@"break" => |b| if (b.value) |bp| rewriteExpr(agg, fn_decls, comptime_arrays, bp) catch return ScanError.OutOfMemory,
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
            // A labeled access (`kinds.kind`) inside a literal's field values
            // is rewritten like anywhere else (decision 8 §6 T4).
            .behaviorLit => |bl| {
                for (bl.fields) |f| rewriteExpr(agg, fn_decls, comptime_arrays, f.value) catch return ScanError.OutOfMemory;
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
                // The method-body walk only splices `@src()` — recurse into the
                // holes and leave the template as written.
                if (agg.src_only) {
                    for (t.parts) |p| switch (p) {
                        .expr => |e| rewriteExpr(agg, fn_decls, comptime_arrays, e) catch return ScanError.OutOfMemory,
                        .text => {},
                    };
                    return;
                }
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

/// Default-value expansion: when fewer args were supplied than the fn's param
/// count AND every trailing missing param carries a `.default`, append the
/// defaults to `c.args` (as `is_default_inj` refs pointing to the param's
/// own Expr). Same rule as the annotation / record-constructor / enum-
/// constructor arity check (à la Kotlin). Shared by free-fn calls (`fn_decls`
/// hit) and record / struct / enum-variant constructor calls (`ctorParams`
/// hit) — same `[]ast.Param` shape on both sides, same helper.
fn expandTrailingDefaultsWithParams(agg: *Aggregator, params: []const ast.Param, c: anytype) !void {
    if (c.args.len >= params.len) return;
    // Every missing trailing param must have a default — otherwise the call
    // is malformed and we leave the original args slice alone (inference will
    // surface the arity error).
    var i: usize = c.args.len;
    while (i < params.len) : (i += 1) {
        if (params[i].default == null) return;
    }
    const arena = agg.spec_cache.arena;
    const ArgT = @TypeOf(c.args[0]);
    var new_args = try arena.alloc(ArgT, params.len);
    for (c.args, 0..) |arg, idx| new_args[idx] = arg;
    i = c.args.len;
    while (i < params.len) : (i += 1) {
        // Reference the param's own default Expr; deinit will skip the
        // value teardown via the `is_default_inj` flag.
        new_args[i] = .{
            .label = null,
            .value = @constCast(&params[i].default.?),
            .comments = &.{},
            .is_default_inj = true,
        };
    }
    c.args = new_args;
}

fn expandTrailingDefaults(agg: *Aggregator, fn_decl: ast.FnDecl, c: anytype) !void {
    return expandTrailingDefaultsWithParams(agg, fn_decl.params, c);
}

/// C-04 (01 step 7, N1) — materialise the fill inference planned for this call.
///
/// The plan has one slot per parameter, in declaration order: the index of the
/// argument the call wrote, or `null` for a parameter that takes its own
/// declared default. The rebuilt list is therefore complete and in declaration
/// order, which is what makes `P(y: 2)` answer `x == 0` on a backend that zips
/// positionally as well as on one that reads the labels. Injected arguments
/// carry `is_default_inj`, so teardown skips the `Expr` they point at — it is
/// the parameter's own, not a copy.
///
/// Nothing is trusted: the plan is applied only when it still describes the
/// call in front of us. Inference wrote it against this very AST, so a mismatch
/// means something else rewrote the call first, and then the call is left alone.
fn applyDefaultFill(agg: *Aggregator, fill: envMod.DefaultFill, c: anytype) !void {
    // A complete call is planned only to reorder labelled arguments (01).
    if (c.args.len > fill.params.len) return;
    var written: usize = 0;
    for (fill.slots) |slot| {
        const ai = slot orelse continue;
        if (ai >= c.args.len) return;
        written += 1;
    }
    if (written != c.args.len) return;

    const arena = agg.spec_cache.arena;
    const ArgT = @TypeOf(c.args[0]);
    var new_args = try arena.alloc(ArgT, fill.params.len);
    for (fill.slots, 0..) |slot, pi| {
        if (slot) |ai| {
            new_args[pi] = c.args[ai];
        } else {
            new_args[pi] = .{
                .label = null,
                .value = @constCast(&fill.params[pi].default.?),
                .comments = &.{},
                .is_default_inj = true,
            };
        }
    }
    c.args = new_args;
}

fn rewriteCall(agg: *Aggregator, fn_decls: std.StringHashMap(ast.FnDecl), comptime_arrays: std.StringHashMap([]const ast.TypedExpr), c: anytype) ScanError!void {
    const fn_decl = fn_decls.get(c.callee) orelse {
        // Ctor lookup (F4): a `Config(...)` / `Level.Error(...)` call hits the
        // record / struct / enum-variant constructor binding, not `fn_decls`.
        // Build the qualified key from the receiver when the call shape is
        // `Enum.Variant(...)` so the variant's param list is found under both
        // the bare and the qualified name (see infer.registerEnum).
        var ctor_key: []const u8 = c.callee;
        var key_buf: [256]u8 = undefined;
        if (c.receiver) |recv| if (recv.* == .identifier and recv.*.identifier.kind == .ident) {
            const rn = recv.*.identifier.kind.ident;
            const joined = std.fmt.bufPrint(&key_buf, "{s}.{s}", .{ rn, c.callee }) catch null;
            if (joined) |k| if (agg.ctor_params.contains(k)) {
                ctor_key = k;
            };
        };
        if (agg.ctor_params.get(ctor_key)) |params| {
            expandTrailingDefaultsWithParams(agg, params, c) catch return ScanError.OutOfMemory;
        }
        for (c.args) |*arg| rewriteExpr(agg, fn_decls, comptime_arrays, arg.value) catch return ScanError.OutOfMemory;
        for (c.trailing) |*tl| {
            for (tl.body) |*s| rewriteStmt(agg, fn_decls, comptime_arrays, s) catch return ScanError.OutOfMemory;
        }
        return;
    };

    // Default-value expansion at the call site (unified with annotation /
    // record-constructor / enum-constructor defaults): when fewer args were
    // supplied than the fn's param count, append the trailing params'
    // `.default` expressions to `c.args` so the dispatch path sees the
    // expanded call shape.
    expandTrailingDefaults(agg, fn_decl, c) catch return ScanError.OutOfMemory;

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

/// 01 step 12 — a call receiver written as a path (`.Color`, `Token.Color`):
/// the only receivers a payload section path is recorded under.
fn isPathReceiver(receiver: ?*ast.Expr) bool {
    const r = receiver orelse return false;
    if (r.* != .identifier) return false;
    return switch (r.identifier.kind) {
        .dotIdent, .identAccess => true,
        else => false,
    };
}
