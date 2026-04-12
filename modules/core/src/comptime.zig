/// Public API for the botopink comptime pipeline.
///
/// This is the only file outside `src/comptime/` that should be imported by
/// other modules. All internal implementation lives under `src/comptime/`.
const std = @import("std");
const ast = @import("./ast.zig");
const infer = @import("./comptime/infer.zig");
const transform = @import("./comptime/transform.zig");
const evalMod = @import("./comptime/eval.zig");
const Lexer = @import("./lexer.zig").Lexer;
const Parser = @import("./parser.zig").Parser;
const Env = @import("./comptime/env.zig").Env;
const envMod = @import("./comptime/env.zig");
const T = @import("./comptime/types.zig");
const Module = @import("./module.zig").Module;
const validation = @import("./comptime/error.zig");

// ── Re-exports for external consumers ────────────────────────────────────────

/// Re-exported so callers only need to import `comptime.zig`.
pub const ComptimeError = validation.ComptimeError;
pub const TypedBinding = infer.TypedBinding;
pub const Type = T.Type;
pub const Env_ = Env; // alias: use `comptimeMod.Env` in callers

// ── Intermediate types ────────────────────────────────────────────────────────

pub const ComptimeEvalResult = struct {
    comptime_script: ?[]u8,
    comptime_vals: std.StringHashMap([]const u8),
};

/// Per-module result after analysis and comptime evaluation.
/// Bindings reference `ComptimeSession.arena` — valid only while the session is alive.
pub const ComptimeOutput = struct {
    name: []const u8,
    src: []const u8,
    outcome: Outcome,

    pub const Outcome = union(enum) {
        ok: OkData,
        validationError: ComptimeError,
    };

    pub const OkData = struct {
        bindings: []const infer.TypedBinding,
        comptime_script: ?[]u8,
        comptime_vals: std.StringHashMap([]const u8),
        /// Transformed program with specialized functions injected, calls rewritten,
        /// comptime args removed, and fully-specialized fns removed.
        transformed: ast.Program,
        /// Type name → type definition ID map (for snapshot serialization).
        type_ids: std.StringHashMap(usize),
    };
};

/// Owns the shared parse/type arena and per-module comptime outputs.
/// Keep alive until `codegenEmit` returns, then call `deinit(allocator)`.
pub const ComptimeSession = struct {
    arena: std.heap.ArenaAllocator,
    outputs: std.ArrayListUnmanaged(ComptimeOutput),

    pub fn deinit(self: *ComptimeSession, allocator: std.mem.Allocator) void {
        self.outputs.deinit(allocator);
        self.arena.deinit();
    }
};

// ── Analysis helpers (internal) ───────────────────────────────────────────────

const AnalysisResult = union(enum) {
    success: struct {
        bindings: []const infer.TypedBinding,
        env: envMod.Env,
        program: ast.Program,
    },
    validationError: struct {
        info: ComptimeError,
    },
};

fn analyzeModule(
    arena: std.mem.Allocator,
    mod: Module,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
) !AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);

    var lexer = Lexer.init(mod.source);
    const tokens = try lexer.scanAll(arena);

    var parser = Parser.init(tokens);
    const program = try parser.parse(arena);

    if (validation.validateComptime(program)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    try resolveImports(&env, program, registry);
    const bindings = try infer.inferProgramTyped(&env, program);
    return .{ .success = .{ .bindings = bindings, .env = env, .program = program } };
}

fn resolveImports(
    env: *envMod.Env,
    program: anytype,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
) !void {
    for (program.decls) |decl| {
        switch (decl) {
            .use => |u| {
                if (u.source == .stringPath) {
                    if (registry.get(u.source.stringPath)) |exports| {
                        for (u.imports) |name| {
                            if (exports.get(name)) |ty| try env.bind(name, ty);
                        }
                    }
                }
            },
            else => {},
        }
    }
}

fn registerExports(
    arena: std.mem.Allocator,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    path: []const u8,
    bindings: []const infer.TypedBinding,
    env: *envMod.Env,
) !void {
    var exports = std.StringHashMap(*T.Type).init(arena);
    for (bindings) |b| {
        if (b.name.len == 0 or b.decl == .use) continue;
        const is_pub = switch (b.decl) {
            .val => |v| v.isPub,
            .@"fn" => |f| f.isPub,
            else => true,
        };
        if (is_pub) {
            const ty = env.lookup(b.name) orelse b.type_;
            try exports.put(b.name, ty);
        }
    }
    try registry.put(path, exports);
}

/// Parse stdlib prelude modules and register their inferred types into `env`.
pub fn registerStdlib(env: *Env, gpa: std.mem.Allocator) anyerror!void {
    const prelude = @import("stdlib_prelude");
    const sources = [_][]const u8{
        prelude.primitives,
        prelude.array,
        prelude.string,
    };
    for (sources) |src| {
        var arena = std.heap.ArenaAllocator.init(gpa);
        defer arena.deinit();
        const alloc = arena.allocator();

        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }
}

/// Re-export so callers use `comptime.zig` as sole entry point.
pub const ComptimeRuntime = evalMod.Runtime;

/// Collect comptime entries from `bindings`, evaluate them via `runtime`,
/// and return the generated script (if any) and the evaluated values.
pub fn evaluateComptime(
    allocator: std.mem.Allocator,
    io: std.Io,
    bindings: []const infer.TypedBinding,
    runtime: ComptimeRuntime,
    build_root: []const u8,
) !ComptimeEvalResult {
    var entries: std.ArrayListUnmanaged(evalMod.ComptimeEntry) = .empty;
    defer {
        for (entries.items) |e| allocator.free(e.id);
        entries.deinit(allocator);
    }
    for (bindings, 0..) |b, i| {
        const te = b.typedExpr orelse continue;
        if (!te.isComptimeExpr()) continue;
        const id = try std.fmt.allocPrint(allocator, "ct_{d}", .{i});
        try entries.append(allocator, .{ .id = id, .expr = te });
    }

    if (entries.items.len == 0) {
        return .{
            .comptime_script = null,
            .comptime_vals = std.StringHashMap([]const u8).init(allocator),
        };
    }

    const result = try evalMod.evaluate(allocator, io, entries.items, runtime, build_root);
    return .{ .comptime_script = result.script, .comptime_vals = result.values };
}

// ── Phase 1: compile ──────────────────────────────────────────────────────────

/// Lex, parse, validate, infer types, and evaluate comptime expressions for
/// each module in order.
///
/// Returns a `ComptimeSession` that owns a shared arena and per-module outputs.
/// Keep the session alive until codegen returns, then call `deinit`.
pub fn compile(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    runtime: ComptimeRuntime,
    build_root: ?[]const u8,
) !ComptimeSession {
    var session = ComptimeSession{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .outputs = .empty,
    };
    errdefer session.arena.deinit();

    const arena_alloc = session.arena.allocator();
    var registry = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena_alloc);

    for (modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        const analysis = try analyzeModule(arena_alloc, mod, &registry);

        switch (analysis) {
            .validationError => |verr| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .{ .validationError = verr.info },
                });
            },
            .success => |succ| {
                if (idx < modules.len - 1) {
                    var env = succ.env;
                    try registerExports(arena_alloc, &registry, mod.path, succ.bindings, &env);
                    env.deinit();
                }
                const ct = try evaluateComptime(arena_alloc, io, succ.bindings, runtime, build_root orelse name);

                var fn_decls = std.StringHashMap(ast.FnDecl).init(arena_alloc);
                var comptime_arrays = std.StringHashMap([]const ast.TypedExpr).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.decl == .@"fn") {
                        try fn_decls.put(b.name, b.decl.@"fn");
                    }
                    if (b.typedExpr) |te| {
                        switch (te.kind) {
                            .@"comptime" => |inner| switch (inner.kind) {
                                .arrayLit => |elems| try comptime_arrays.put(b.name, elems),
                                else => {},
                            },
                            else => {},
                        }
                    }
                }

                const transformed = try transform.transform(arena_alloc, succ.program, fn_decls, comptime_arrays, ct.comptime_vals);

                var type_ids = std.StringHashMap(usize).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.typeId) |id| try type_ids.put(b.name, id);
                }

                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .{ .ok = .{
                        .bindings = succ.bindings,
                        .comptime_script = ct.comptime_script,
                        .comptime_vals = ct.comptime_vals,
                        .transformed = transformed,
                        .type_ids = type_ids,
                    } },
                });
            },
        }
    }

    return session;
}
