const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const tsEmit = @import("./typescript.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const specialize = @import("../comptime/specialize.zig");
const crossModule = @import("./crossModule.zig");
const primOpTemplate = @import("../comptime/primOpTemplate.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");
const js = @import("./js/js_ast.zig");
const envMod = @import("../comptime/env.zig");
const jsEmitter = @import("./js/js_emitter.zig");

/// `prim-op-annotation` builtin dispatch entry (commonJS).
const BuiltinNodeCall = struct {
    symbol: []const u8,
    /// Module path for `@External.Node("./mod", "sym")` form — empty for
    /// template-only entries.
    module: []const u8 = "",
    arity_branches: []const ast.ArityBranch = &.{},
};

const ModuleOutput = moduleOutput.ModuleOutput;
const ComptimeOutput = comptimeMod.ComptimeOutput;

/// Cross-module link index — shared, backend-agnostic analysis (`crossModule.zig`).
/// commonJS reads `.module` (which file `require`s a name) and `.is_class`
/// (whether an imported record's construction needs `new`).
const CrossModule = crossModule.CrossModule;

// ── public phase 2: codegen ───────────────────────────────────────────────────

/// Emit JavaScript for each module in `outputs`.
///
/// Frees `comptime_vals` and transfers ownership of `comptime_script`
/// into each `ModuleOutput.result`. Call `ComptimeSession.deinit` after this.
pub fn codegenEmit(
    alloc: std.mem.Allocator,
    outputs: []ComptimeOutput,
    config: configMod.Config,
) !std.ArrayListUnmanaged(ModuleOutput) {
    var results: std.ArrayListUnmanaged(ModuleOutput) = .empty;

    // Cross-module link index: lets each module `require` the file that
    // actually emits an imported symbol, emit `new` for imported records, and
    // `exports.X` only for symbols consumed elsewhere.
    var cross = try crossModule.build(alloc, outputs);
    defer cross.deinit();

    for (outputs) |*ct| {
        switch (ct.outcome) {
            .parseError => continue,
            .typeError => continue,
            .validationError => |verr| {
                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = try alloc.dupe(u8, ""),
                        .comptime_script = null,
                        .comptime_err = verr,
                    },
                });
            },
            .ok => |*ok| {
                // `"std"` package copies are dependencies — never emit their
                // test blocks (a project's `botopink test` runs only its own
                // tests; the stdlib's inline tests run from `libs/std` itself).
                const module_test_mode = config.test_mode and !std.mem.startsWith(u8, ct.name, "std/");
                const js_src = try emitJs(alloc, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &ok.js_method_renames, &ok.instance_lowerings, module_test_mode, ct.name, &cross);

                // Generate TypeScript typedefs if configured.
                const typedef: ?[]u8 = if (config.typeDefLanguage) |_|
                    try emitTypeDef(alloc, ok.bindings)
                else
                    null;

                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = js_src,
                        .typedef = typedef,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
                        .comptime_trace = try comptimeMod.trace.renderAlloc(alloc, ok.comptime_traces),
                        .comptime_err = null,
                    },
                });
            },
        }
    }

    return results;
}

fn emitJs(
    alloc: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    renames: ?*const std.AutoHashMap(ast.Loc, []const u8),
    lowerings: ?*const std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    test_mode: bool,
    module_name: []const u8,
    cross: ?*const CrossModule,
) ![]u8 {
    return try emitProgramOptsX(alloc, program, comptime_vals, rewrites, renames, lowerings, test_mode, module_name, cross);
}

fn emitTypeDef(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
) ![]u8 {
    return try tsEmit.emitProgram(alloc, bindings);
}

// ── emit ──────────────────────────────────────────────────────────────────────

/// Zig-native JavaScript backend for botopink.
///
/// Converts typed bindings directly to a JavaScript code model
/// (`codegen/js/js_ast.zig`) that `codegen/js/js_emitter.zig` renders — no JSON
/// intermediate, no Node.js pipeline, and no target text written here. Comptime
/// expression values (pre-evaluated by running Node.js and capturing stdout)
/// are injected via `comptime_vals`.
// ── public surface ────────────────────────────────────────────────────────────

/// Returns true when the top-level typed expression is a comptime node.
pub fn isComptimeExpr(te: ast.TypedExpr) bool {
    return switch (te.kind) {
        .@"comptime", .comptimeBlock => true,
        else => false,
    };
}

/// If `e` is a `use`-hook prefix, return the wrapped hook-call expression.
pub fn useHookInner(e: ast.Expr) ?*ast.Expr {
    return switch (e) {
        .useHook => |uh| uh.kind.inner,
        else => null,
    };
}

/// True when `e` is the `null` literal — used to choose loose `==`/`!=` for
/// `?T` none comparisons (so `undefined` and `null` both count as none).
pub fn isNullLiteral(e: ast.Expr) bool {
    return e == .literal and e.literal.kind == .null_;
}

/// True when an interface method is an associated function — `default fn` with
/// no `self` receiver (callable as `Interface.method(...)`, not on a value).
pub fn isAssociatedFn(m: ast.InterfaceMethod) bool {
    if (!m.is_default) return false;
    return m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self");
}

/// Map a primitive controller interface name to the JS constructor whose
/// `prototype` carries the instance methods (`Bool` → `Boolean`). Other names
/// (incl. local interfaces) own their prototype directly.
pub fn jsPrototypeOwner(name: []const u8) []const u8 {
    if (std.mem.eql(u8, name, "Bool")) return "Boolean";
    // The numeric tower (controllers + concrete widths) maps to `Number`.
    const numeric = [_][]const u8{ "Number", "Integer", "Signed", "Float", "I32", "I64", "U32", "U64", "F32", "F64" };
    for (numeric) |nm| if (std.mem.eql(u8, name, nm)) return "Number";
    return name;
}

/// True for JS constructors whose instances box a primitive into an object —
/// calling a prototype method on a primitive (`false.m()`) sets `this` to a
/// truthy wrapper object, so the body must unwrap via `this.valueOf()`.
pub fn isBoxedPrototype(owner: []const u8) bool {
    return std.mem.eql(u8, owner, "Boolean") or
        std.mem.eql(u8, owner, "Number") or
        std.mem.eql(u8, owner, "String");
}

/// True when a type reference is the phantom capability `@Context<B, R>`.
pub fn isContextTypeRef(tr: ast.TypeRef) bool {
    return switch (tr) {
        .generic => |g| std.mem.eql(u8, g.name, "Context"),
        else => false,
    };
}

/// True when a struct exists solely as a phantom `ContextBase` marker —
/// it `implement`s `@Context` and carries no members. Such structs are erased:
/// they describe a capability, not a runtime value.
pub fn isPhantomContextStruct(s: ast.StructDecl) bool {
    if (s.members.len != 0) return false;
    for (s.implement) |im| if (isContextTypeRef(im)) return true;
    return false;
}

/// JS host namespaces that exist as globals — `#\[@External\.node("Math", …)]`
/// must reference them directly: `require("Math")` fails at module load
/// (`Cannot find module 'Math'`). `require` is reserved for relative/package
/// module paths.
const js_global_namespaces = [_][]const u8{
    "globalThis", "Math",    "JSON",    "console", "Number",  "Date",
    "Object",     "Array",   "String",  "Boolean", "Symbol",  "BigInt",
    "Promise",    "Reflect", "Intl",    "Error",   "RegExp",  "Map",
    "Set",        "WeakMap", "WeakSet", "Atomics", "process",
};

/// True when an `@[external(node, module, …)]` module name is a JS global
/// namespace rather than a requirable module.
pub fn isJsGlobalNamespace(module: []const u8) bool {
    for (js_global_namespaces) |g| {
        if (std.mem.eql(u8, module, g)) return true;
    }
    return false;
}

/// Sanitized JS binding name — the reserved-word rename lives in the emitter
/// (`js/js_emitter.zig`), which applies it to every `ident` node it renders.
/// This alias stays for the few places that need the final spelling while
/// *building* (a `require` binding compared against its host symbol).
pub fn jsIdent(name: []const u8) []const u8 {
    return jsEmitter.ident(name);
}

/// Emit all declarations as JavaScript source.
///
/// `comptime_vals` maps IDs such as `"ct_0"` to pre-evaluated JS literal
/// strings such as `"6.28"`.
///
/// The `program` is the transformed AST with specialized functions already
/// injected as regular FnDecl nodes. The backend just lowers what it sees.
pub fn emitProgram(
    alloc: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
) ![]u8 {
    return emitProgramOpts(alloc, program, comptime_vals, rewrites, false, "main");
}

// Standalone emit paths (`emitProgram`/`emitProgramOpts`) carry no type-directed
// rename map; only the cross-module `emitJs` path threads one from inference.

/// Like `emitProgram`, but with test-mode emission control. In test mode,
/// `test { … }` decls emit as `__bp_test_N` functions plus a registry +
/// runner, `assert` lowers to the throwing `__bp_assert` helper, and
/// `fn main/0` is not auto-invoked.
pub fn emitProgramOpts(
    alloc: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    test_mode: bool,
    module_name: []const u8,
) ![]u8 {
    return emitProgramOptsX(alloc, program, comptime_vals, rewrites, null, null, test_mode, module_name, null);
}

/// The test-mode preamble: a throwing assert helper the runner can catch.
const assert_helper_source =
    \\function __bp_assert(cond, msg, loc) {
    \\    if (!cond) {
    \\        const e = new Error(msg || "assertion failed");
    \\        e.__bp_assert_loc = loc;
    \\        throw e;
    \\    }
    \\}
    \\
    \\
;

/// The test-mode runner, appended after the `__bp_tests` registry.
const test_runner_source =
    \\async function __bp_run_tests() {
    \\    const filter = process.argv[2] || null;
    \\    const tests = filter ? __bp_tests.filter((t) => t.name.includes(filter)) : __bp_tests;
    \\    let passed = 0, failed = 0;
    \\    const _write = process.stdout.write.bind(process.stdout);
    \\    for (const t of tests) {
    \\        // §T `----- RUN LOG -----` envelope (v0.beta.20 frente-b spec):
    \\        // each test body produces a `TEST <loc> <name>` header + a fenced
    \\        // ```logs``` block capturing its stdout. The `async function`
    \\        // override and restore is per-test so a runtime error inside
    \\        // t.fn() can never strand the override.
    \\        _write("TEST " + t.loc + " " + t.name + "\n");
    \\        _write("----- RUN LOG -----\n```logs\n");
    \\        let _buf = "";
    \\        process.stdout.write = (chunk) => {
    \\            _buf += typeof chunk === "string" ? chunk : chunk.toString();
    \\            return true;
    \\        };
    \\        // §T duration: monotonic millisecond clock around t.fn(); the
    \\        // delta lands on its own `  duration <ms>ms` line between the
    \\        // fence close and the ok/FAIL line. Older parsers that don't
    \\        // recognise the duration line skip it (forward-compatible).
    \\        const _t0 = (typeof performance !== "undefined" && performance.now) ? performance.now() : Date.now();
    \\        let _err = null;
    \\        // Tests are `async function` (see `emitTestFn`) so the
    \\        // runner awaits — a `await flush()` / `await fetch(url)`
    \\        // inside the body resolves before the duration window closes.
    \\        // A sync test pays no observable cost (a resolved Promise
    \\        // is returned and awaited).
    \\        try { await t.fn(); } catch (e) { _err = e; }
    \\        const _t1 = (typeof performance !== "undefined" && performance.now) ? performance.now() : Date.now();
    \\        const _dur_ms = Math.max(0, Math.round(_t1 - _t0));
    \\        process.stdout.write = _write;
    \\        _write(_buf);
    \\        if (_buf.length > 0 && !_buf.endsWith("\n")) _write("\n");
    \\        _write("```\n");
    \\        _write("  duration " + _dur_ms + "ms\n");
    \\        if (_err === null) {
    \\            _write("  ok   " + t.name + "\n");
    \\            passed++;
    \\        } else {
    \\            const loc = _err.__bp_assert_loc || t.loc;
    \\            _write("  FAIL " + t.name + "  (" + _err.message + ")  at " + loc + "\n");
    \\            failed++;
    \\        }
    \\    }
    \\    _write(passed + " passed, " + failed + " failed\n");
    \\    if (failed > 0) process.exit(1);
    \\}
    \\if (require.main === module) __bp_run_tests();
    \\
;

fn emitProgramOptsX(
    alloc: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    renames: ?*const std.AutoHashMap(ast.Loc, []const u8),
    lowerings: ?*const std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
    test_mode: bool,
    module_name: []const u8,
    cross: ?*const CrossModule,
) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var em = Emitter.emitterInit(alloc, arena.allocator(), comptime_vals, rewrites);
    defer em.deinit();
    em.renames = renames;
    em.lowerings = lowerings;
    em.test_mode = test_mode;
    em.module_name = module_name;
    em.cross = cross;
    try em.collectExternals(program);
    try em.collectClassNames(program);
    try em.collectVariantFields(program);
    try em.collectPrimNodeRenames(program);
    try em.collectBuiltinNodeDispatch();

    const arena_alloc = arena.allocator();
    var items: std.ArrayListUnmanaged(js.Item) = .empty;

    // Test registry entries collected while building decls (test mode only).
    const TestEntry = struct { name: ?[]const u8, line: usize, idx: usize };
    var test_entries: std.ArrayListUnmanaged(TestEntry) = .empty;
    defer test_entries.deinit(alloc);

    // Track which val names are comptime-only (consumed at compile time).
    var comptime_only = std.StringHashMap(void).init(alloc);
    defer comptime_only.deinit();

    // Map val_name → ct_id so we can emit resolved comptime values.
    // The ct_{N} ID comes from the binding index in the original bindings list.
    // Val and fn decls each consume one binding slot.
    var val_ct_map = std.StringHashMap([]const u8).init(alloc);
    defer {
        var it = val_ct_map.iterator();
        while (it.next()) |kv| alloc.free(kv.value_ptr.*);
        val_ct_map.deinit();
    }
    {
        var binding_idx: usize = 0;
        for (program.decls) |decl| {
            switch (decl) {
                .val => |v| {
                    if (isComptimeVal(v)) {
                        try comptime_only.put(v.name, {});
                        const ct_id = try std.fmt.allocPrint(alloc, "ct_{d}", .{binding_idx});
                        try val_ct_map.put(v.name, ct_id);
                    }
                    binding_idx += 1;
                },
                .@"fn" => binding_idx += 1,
                else => {},
            }
        }
    }

    // Detect `fn main/0` so we can emit the `_botopink_main` entry wrapper.
    var has_main_0 = false;
    for (program.decls) |decl| {
        switch (decl) {
            .@"fn" => |f| {
                if (std.mem.eql(u8, f.name, "main")) {
                    var arity: usize = 0;
                    for (f.params) |p| {
                        if (!std.mem.eql(u8, p.name, "self")) arity += 1;
                    }
                    if (arity == 0) has_main_0 = true;
                }
            },
            else => {},
        }
    }

    if (test_mode) try items.append(arena_alloc, .{ .runtime = assert_helper_source });

    // Build declarations from the transformed program.
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (comptime_only.contains(v.name)) {
                    // Emit resolved comptime value if available.
                    const ct_id = val_ct_map.get(v.name) orelse continue;
                    const lit = comptime_vals.get(ct_id) orelse continue;
                    try items.append(arena_alloc, .{
                        .stmt = .{
                            .decl = .{
                                .pattern = .{ .ident = v.name },
                                // A pre-evaluated JS literal, already in target syntax.
                                .value = .{ .name = lit },
                            },
                        },
                    });
                    continue;
                }
                try items.append(arena_alloc, .{ .stmt = try em.buildValDecl(v) });
            },
            .@"fn" => |f| try items.append(arena_alloc, .{ .stmt = try em.buildFnItem(f) }),
            .record => |r| try items.append(arena_alloc, .{ .stmt = try em.buildRecord(r) }),
            .@"enum" => |e| try items.append(arena_alloc, .{ .stmt = try em.buildEnum(e) }),
            .interface => |i| try items.append(arena_alloc, .{ .stmt = try em.buildInterface(i) }),
            .implement => |im| try items.append(arena_alloc, .{ .stmt = try em.buildImplement(im) }),
            .extend => |ex| try items.append(arena_alloc, .{ .stmt = try em.buildExtend(ex) }),
            .use => |u| try items.append(arena_alloc, .{ .stmt = try em.buildUse(u) }),
            .delegate => |d| try items.append(arena_alloc, .{ .stmt = .{ .comment = .{
                .text = try std.fmt.allocPrint(arena_alloc, "delegate {s}", .{d.name}),
            } } }),
            // `mod` declares a submodule in the explicit tree; the submodule is
            // emitted as its own module file, so the declaration emits nothing.
            .mod => {},
            // Test blocks are only compiled under `botopink test`; in normal
            // builds they are skipped entirely.
            .@"test" => |t| {
                if (!test_mode) continue;
                const idx = test_entries.items.len;
                try test_entries.append(alloc, .{ .name = t.name, .line = t.loc.line, .idx = idx });
                try items.append(arena_alloc, .{ .stmt = try em.buildTestFn(t, idx) });
            },
            .comment => |c| try items.append(arena_alloc, .{ .stmt = .{ .comment = .{
                .style = if (c.is_doc) .doc else if (c.is_module) .module else .line,
                .text = c.text,
            } } }),
        }
    }

    // Auto-invoke entry point when `fn main/0` is defined (never in test mode).
    if (has_main_0 and !test_mode) {
        try items.append(arena_alloc, .{ .stmt = try em.b.group(&.{
            .{ .function = .{ .name = "_botopink_main", .body = .{
                .stmts = try em.b.stmts(&.{.{ .expr = try em.b.call(.{ .name = "main" }, &.{}) }}),
            } } },
            .{ .expr = try em.b.call(.{ .name = "_botopink_main" }, &.{}) },
        }) });
    }

    // Test mode: emit the registry + runner entry.
    if (test_mode and test_entries.items.len > 0) {
        // F6 — warn on duplicate test names within a module: two `test "x"`
        // blocks both run, but a shared name makes a failure report ambiguous.
        {
            var seen_names = std.StringHashMap(void).init(alloc);
            defer seen_names.deinit();
            for (test_entries.items) |t| {
                const n = t.name orelse continue;
                const gop = try seen_names.getOrPut(n);
                if (gop.found_existing) {
                    std.debug.print(
                        "warning: duplicate test name \"{s}\" in {s}.bp:{d}\n",
                        .{ n, module_name, t.line },
                    );
                }
            }
        }
        const entries = try arena_alloc.alloc(js.Expr, test_entries.items.len);
        for (test_entries.items, 0..) |t, i| {
            const name = t.name orelse try std.fmt.allocPrint(arena_alloc, "test_{d}", .{t.idx});
            entries[i] = try em.b.object(&.{
                .{ .kv = .{ .key = "name", .value = .{ .quoted = name } } },
                .{ .kv = .{ .key = "fn", .value = .{ .name = try std.fmt.allocPrint(arena_alloc, "__bp_test_{d}", .{t.idx}) } } },
                .{ .kv = .{ .key = "loc", .value = .{ .quoted = try std.fmt.allocPrint(arena_alloc, "{s}.bp:{d}", .{ module_name, t.line }) } } },
            });
        }
        try items.append(arena_alloc, .{ .stmt = .{ .decl = .{
            .pattern = .{ .name = "__bp_tests" },
            .value = .{ .array = .{ .elems = entries, .layout = .lines } },
        } } });
        try items.append(arena_alloc, .{ .runtime = test_runner_source });
    }

    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    try jsEmitter.writeProgram(&aw.writer, items.items);
    return aw.toOwnedSlice();
}

fn isComptimeVal(v: ast.ValDecl) bool {
    return if (v.value.* == .comptime_) true else false;
}

// ── backend ───────────────────────────────────────────────────────────────────

/// How `try`/`catch` is shaped once classified — drives statement-level lowering
/// to `"error" in _r` pattern matching over `{ ok } | { error }` Result values
/// (never JS try/catch).
const TryForm = union(enum) {
    /// `try expr` (no catch) — propagate the Error variant up via early `return`.
    propagate: ast.Expr,
    /// `try expr catch <value>` — on Error use a fallback value, or call a lambda
    /// handler with the unwrapped error (`is_lambda`).
    catchValue: struct { inner: ast.Expr, handler: ast.Expr, is_lambda: bool },
    /// `try expr catch <return|throw|break|continue ...>` — on Error run a jump stmt.
    catchJump: struct { inner: ast.Expr, handler: ast.Expr },

    fn inner(self: TryForm) ast.Expr {
        return switch (self) {
            .propagate => |e| e,
            .catchValue => |cv| cv.inner,
            .catchJump => |cj| cj.inner,
        };
    }
};

/// Where the unwrapped (Ok) value of a `try` should land at statement position.
const TryHead = union(enum) {
    decl: struct { kw: js.Decl.Kw, name: []const u8 },
    destruct: struct { mutable: bool, pattern: ast.ParamDestruct },
    ret,
    discard,
};

/// A handler that transfers control (`return`/`throw`/`break`/`continue`) is a
/// statement, not a value, so it cannot sit inside a `?:` ternary.
fn isJumpHandler(h: ast.Expr) bool {
    return switch (h) {
        .jump => |hj| switch (hj.kind) {
            .@"return", .throw_, .@"break", .@"continue", .yield => true,
            .try_, .await_ => false,
        },
        else => false,
    };
}

/// Marker kinds emitted by `transform.zig::tryLowerFutureJump`.
const FutureWrapKind = enum { resolved, rejected };

/// Recognise the `__bp_future_resolved(<t>)` / `__bp_future_rejected(<e>)`
/// builtin marker calls so the commonJS return-statement lowering can strip
/// them back to native `return <t>;` / `throw <e>;` (the JS `async function`
/// keyword is the actual promise wrap).
fn futureWrapCallName(e: ast.Expr) ?FutureWrapKind {
    if (e != .call) return null;
    if (e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (!c.is_builtin or c.args.len != 1) return null;
    if (std.mem.eql(u8, c.callee, "__bp_future_resolved")) return .resolved;
    if (std.mem.eql(u8, c.callee, "__bp_future_rejected")) return .rejected;
    return null;
}

/// Recognise the try/catch shape of `e`, or null when it is not a try/catch.
fn classifyTry(e: ast.Expr) ?TryForm {
    switch (e) {
        .jump => |j| switch (j.kind) {
            .try_ => |t| return if (t) |i| TryForm{ .propagate = i.* } else null,
            else => return null,
        },
        .branch => |br| switch (br.kind) {
            .tryCatch => |tc| {
                const h = tc.handler.*;
                if (isJumpHandler(h)) return TryForm{ .catchJump = .{ .inner = tc.expr.*, .handler = h } };
                const is_lambda = switch (h) {
                    .function => true,
                    else => false,
                };
                return TryForm{ .catchValue = .{ .inner = tc.expr.*, .handler = h, .is_lambda = is_lambda } };
            },
            else => return null,
        },
        else => return null,
    }
}

/// Emit a single function declaration as plain JS, with no program context
/// (no comptime vals, no dispatch rewrites). Used by the comptime template
/// evaluator (`comptime/template_eval.zig`) to run a template fn body in the
/// node eval runtime — the evaluator's JS prelude supplies the comptime
/// surface (`__expr`/`__code` and the capture objects' methods).
pub fn emitFnJs(alloc: std.mem.Allocator, out: *std.Io.Writer, f: ast.FnDecl) !void {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    const cv = std.StringHashMap([]const u8).init(alloc);
    const rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc);
    var em = Emitter.emitterInit(alloc, arena.allocator(), cv, rewrites);
    defer em.deinit();
    try jsEmitter.writeStmt(out, try em.buildFn(f), 0);
}

/// Collects a host template's rendered parts into an `Expr.host` node.
///
/// `primOpTemplate.render` streams literal annotation text and hole callbacks;
/// the literal runs become `.text` parts and each hole an `.expr` part, so the
/// template's own bytes stay host code and its arguments stay nodes.
fn HostTemplate(comptime Holes: type) type {
    return struct {
        arena: std.mem.Allocator,
        holes: *Holes,
        argc: usize,
        parts: std.ArrayListUnmanaged(js.HostPart) = .empty,
        buf: std.ArrayListUnmanaged(u8) = .empty,

        const Self = @This();

        pub fn writeByte(self: *Self, ch: u8) anyerror!void {
            try self.buf.append(self.arena, ch);
        }
        pub fn writeAll(self: *Self, s: []const u8) anyerror!void {
            try self.buf.appendSlice(self.arena, s);
        }
        fn flush(self: *Self) !void {
            if (self.buf.items.len == 0) return;
            try self.parts.append(self.arena, .{ .text = try self.arena.dupe(u8, self.buf.items) });
            self.buf.clearRetainingCapacity();
        }
        pub fn emitRecv(self: *Self) anyerror!void {
            try self.flush();
            try self.parts.append(self.arena, .{ .expr = try self.holes.recvExpr() });
        }
        pub fn emitArg(self: *Self, i: usize) anyerror!void {
            try self.flush();
            try self.parts.append(self.arena, .{ .expr = try self.holes.argExpr(i) });
        }
        fn finish(self: *Self) !js.Expr {
            try self.flush();
            return .{ .host = try self.parts.toOwnedSlice(self.arena) };
        }
    };
}

/// Holes filled from a call site's argument expressions. `$self` has no
/// meaning there — a template with a receiver marker is a declaration error.
fn CallHoles(comptime CC: type) type {
    return struct {
        em: *Emitter,
        cc: CC,
        err: anyerror,

        pub fn recvExpr(self: *@This()) anyerror!js.Expr {
            return self.err;
        }
        pub fn argExpr(self: *@This(), i: usize) anyerror!js.Expr {
            return self.em.buildExpr(self.cc.args[i].value.*);
        }
    };
}

/// Holes filled from a prototype method's parameters: `$self` is the receiver
/// (unwrapped for a boxed primitive) and `$N` the Nth parameter.
const MethodHoles = struct {
    params: []const ast.Param,
    boxed_recv: bool,

    pub fn recvExpr(self: *@This()) anyerror!js.Expr {
        return if (self.boxed_recv)
            js.Expr{ .call = .{ .callee = &boxed_value_of } }
        else
            js.Expr.this;
    }
    pub fn argExpr(self: *@This(), i: usize) anyerror!js.Expr {
        return .{ .ident = self.params[i].name };
    }
};

/// What a `break` / `continue` in the body being built binds to.
const LoopCtx = union(enum) {
    /// Not inside a loop body (or behind a function boundary).
    none,
    /// A `loop` in statement position: a JS `for…of`. `break;` ends it,
    /// `continue;` skips to the next item, a `break <v>` value is discarded.
    stmt,
    /// A `loop` used as a value — a comprehension lowered to an accumulating
    /// IIFE. `break <v>` / `yield <v>` push `v` onto the named array and move to
    /// the next item; `break;` ends the iteration.
    value: []const u8,
};

const this_expr: js.Expr = .this;
const boxed_value_of: js.Expr = .{ .member = .{ .object = &this_expr, .name = "valueOf" } };

const Emitter = struct {
    /// Scratch allocator for the collector hash maps.
    alloc: std.mem.Allocator,
    /// Arena the code model is built in — it outlives every build call and is
    /// freed once the module has been rendered.
    b: js.Builder,
    cv: std.StringHashMap([]const u8),
    current_indent: usize = 0,
    try_seq: usize = 0,
    /// Static extension dispatch: call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Type-directed JS method renames: call-site loc → native JS method name to
    /// emit instead of `callee` (e.g. string `contains` → `includes`). Null in the
    /// standalone `emitProgram`/`emitFnJs` paths.
    renames: ?*const std.AutoHashMap(ast.Loc, []const u8) = null,
    /// Inference's per-site lowering record (`s.len` on a typed string/array →
    /// `.prim`). commonJS reads it only to spell a primitive `len` as the
    /// native `.length` property. Null in the standalone paths.
    lowerings: ?*const std.AutoHashMap(ast.Loc, envMod.InstanceLowering) = null,
    /// When true, `self.x` lowers to `self.x` (extension methods take `self` as a
    /// real first parameter) instead of the prototype-method `this.x`.
    self_is_param: bool = false,
    /// True while building a generator (`function*`) body. A `return <expr>`
    /// inside an `#[@iterator] fn -> @Iterator<T>` means *delegate the rest of
    /// the iteration* to that iterator, so it lowers to `yield* <expr>;
    /// return;` — a plain `return <gen>` would surface the generator object as
    /// the done-value and yield nothing (the iterator-recursion bug behind the
    /// dead `iterator` suite).
    in_generator: bool = false,
    /// The innermost `loop` whose body is being built, which is what a
    /// `break` / `continue` / accumulator `yield` binds to. Reset to `.none`
    /// wherever a JS function boundary starts (an arrow, an IIFE), because a
    /// jump cannot cross one.
    loop_ctx: LoopCtx = .none,
    /// Set while the arms of a `return __bp_ok(case …)` are lowered as
    /// statements (`buildReturnCaseStmt`): a value arm then returns
    /// `({ ok: v })`, while an arm that already returns keeps its own value.
    case_ok_wrap: bool = false,
    /// Names bound by `use` hooks seen so far in the current function body, in
    /// source order. Used to infer the dependency array of `useMemo`/`useEffect`:
    /// a hook's lambda dep list is the reactive names it references.
    hook_state: std.ArrayListUnmanaged([]const u8) = .empty,
    /// `botopink test` compilation: `assert` lowers to the throwing
    /// `__bp_assert` helper instead of `console.assert`.
    test_mode: bool = false,
    /// Module name, used for `<module>.bp:<line>` source locations in
    /// test-mode assert failures.
    module_name: []const u8 = "main",
    /// `@[external(node, "module", "symbol")]` fns: name → host import.
    /// The decl lowers to `const { symbol: name } = require("module");`,
    /// or `const name = Module.symbol;` for JS global namespaces (`Math`, …).
    externals: std.StringHashMap(ast.ExternalRef),
    /// `@[external(…)]` fns with no `node` target — calling one is an error.
    externals_missing: std.StringHashMap(void),
    /// Names that emit as JS classes (record/struct decls, incl. the
    /// `val X = record { … }` shorthand) — constructor calls need `new`.
    class_names: std.StringHashMap(void),
    /// Payload variant name → its declared field names, in declaration order,
    /// for every enum declared in this module. A `case` arm `Circle(r)` binds
    /// positionally, so `r` is read from the declared field (`radius`), never
    /// from a property named after the binding.
    variant_fields: std.StringHashMap([]const []const u8),
    /// Cross-module link info (null in the standalone `emitProgram` path) —
    /// resolves a `from "<pkg>"` import to the file that emits each name.
    cross: ?*const CrossModule = null,
    /// Import binding names already lowered to a `const { … } = require(…)` in
    /// this module. A name maps to exactly one runtime binding, so a second
    /// `import {x}` for the same `x` (e.g. several decorator `@emit`s each
    /// importing the runtime fn they call) must not redeclare it — `const x`
    /// twice is a JS `SyntaxError`. Tracked per module; reset in `emitterInit`.
    seen_imports: std.StringHashMap(void),
    /// §A4 type-naive prim-method rename: method name → JS prototype symbol,
    /// driven by the 2-arg `@external(node, "X")` annotation on a primitive
    /// interface method. Consulted at the call site as a fallback when no
    /// per-loc (type-directed) rename was recorded by inference — the latter
    /// path covers interface default-fn bodies, which are lowered from AST
    /// without going through inference. Collisions with a record/struct method
    /// of the same name are excluded (`String.contains`/`Set.contains` →
    /// inference's per-loc rename is the only path; this map omits `contains`).
    prim_node_renames: std.StringHashMap([]const u8),
    /// `prim-op-annotation` builtin dispatch (node): callees from
    /// `builtins.d.bp` with `@external(node, …)`. Keyed by callee name.
    builtin_node_dispatch: std.StringHashMap(BuiltinNodeCall),
    /// §A2 user-fn per-callee template dispatch (node): a `declare fn`
    /// whose `@external(node, "<template>")` symbol contains `$0`/`$self`/…
    /// or whose annotation list carries `when(argc == N): "..."` branches
    /// renders at the call site instead of being aliased at the decl
    /// (the `const fn = Mod.method;` shape strips the receiver, so chained
    /// host calls like `process.cwd()`, `crypto.createHash($0).update($1).digest('hex')`,
    /// or `Buffer.from($0, 'utf8').toString('base64')` cannot live as a
    /// const-bound reference). Reuses the same `BuiltinNodeCall` shape as
    /// the `panic`/`todo` builtin path. Mirrors the erlang backend's
    /// existing `tryEmitPrimAnnotation` template path — `std-expansion-tail`
    /// §A2.
    user_node_templates: std.StringHashMap(BuiltinNodeCall),

    fn emitterInit(
        alloc: std.mem.Allocator,
        node_arena: std.mem.Allocator,
        cv: std.StringHashMap([]const u8),
        rewrites: std.AutoHashMap(ast.Loc, []const u8),
    ) Emitter {
        var em = Emitter{
            .alloc = alloc,
            .b = .{ .arena = node_arena },
            .cv = cv,
            .rewrites = rewrites,
            .externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .externals_missing = std.StringHashMap(void).init(alloc),
            .class_names = std.StringHashMap(void).init(alloc),
            .variant_fields = std.StringHashMap([]const []const u8).init(alloc),
            .seen_imports = std.StringHashMap(void).init(alloc),
            .prim_node_renames = std.StringHashMap([]const u8).init(alloc),
            .builtin_node_dispatch = std.StringHashMap(BuiltinNodeCall).init(alloc),
            .user_node_templates = std.StringHashMap(BuiltinNodeCall).init(alloc),
        };
        // §A4 default prim renames: the three host-name → native-prototype pairs
        // primitives.d.bp annotates with the 2-arg shorthand. Seeding them here
        // (instead of relying on `collectPrimNodeRenames` to find the interface
        // decl) lets the standalone `emitFnJs` path — used by the comptime
        // template eval to run a template body — pick up the rename even though
        // it has no program AST to scan. The full collector (called from
        // `emitProgramOptsX`) reaffirms these and adds any further interface
        // annotation, with a record-method collision filter on top.
        em.prim_node_renames.put("append", "concat") catch {};
        em.prim_node_renames.put("toUpper", "toUpperCase") catch {};
        em.prim_node_renames.put("toLower", "toLowerCase") catch {};
        return em;
    }

    fn deinit(self: *Emitter) void {
        self.hook_state.deinit(self.alloc);
        self.externals.deinit();
        self.externals_missing.deinit();
        self.class_names.deinit();
        self.variant_fields.deinit();
        self.seen_imports.deinit();
        self.prim_node_renames.deinit();
        var bit = self.builtin_node_dispatch.iterator();
        while (bit.next()) |entry| {
            self.alloc.free(entry.key_ptr.*);
            if (entry.value_ptr.symbol.len > 0) self.alloc.free(entry.value_ptr.symbol);
            if (entry.value_ptr.module.len > 0) self.alloc.free(entry.value_ptr.module);
            for (entry.value_ptr.arity_branches) |br| self.alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) self.alloc.free(entry.value_ptr.arity_branches);
        }
        self.builtin_node_dispatch.deinit();
        var uit = self.user_node_templates.iterator();
        while (uit.next()) |entry| {
            self.alloc.free(entry.key_ptr.*);
            if (entry.value_ptr.symbol.len > 0) self.alloc.free(entry.value_ptr.symbol);
            for (entry.value_ptr.arity_branches) |br| self.alloc.free(br.template);
            if (entry.value_ptr.arity_branches.len > 0) self.alloc.free(entry.value_ptr.arity_branches);
        }
        self.user_node_templates.deinit();
    }

    fn arena(self: *Emitter) std.mem.Allocator {
        return self.b.arena;
    }

    // ── collectors ────────────────────────────────────────────────────────────

    /// `prim-op-annotation` commonJS builtin dispatch collector — mirrors
    /// erlang's; scans `prelude.builtins` for top-level fn decls with
    /// `@external(node, …)` and indexes by callee name.
    ///
    /// `libs/std/src/builtins.d.bp` is the *documented* surface for compiler
    /// builtins and not strictly parseable (it carries forms the parser does
    /// not accept: bodyless `fn`, keyword-named params, bare-return-type
    /// shorthand, enum variant terminator `;`). The §A6 dispatch needs only
    /// the `panic`/`todo` entries, so we register those directly from a
    /// hand-rolled inline source that parses cleanly, then attempt the
    /// best-effort whole-file parse to pick up anything else (silently
    /// ignoring failures — pre-existing behaviour).
    fn collectBuiltinNodeDispatch(self: *Emitter) !void {
        try self.registerInlineBuiltinDispatch();
        // Scan `builtins_fns.d.bp` + `primitives.bp` for top-level `declare fn`
        // with `#[@External.Node]` annotations — both template and module+symbol
        // forms. Annotations drive dispatch; no file names are hardcoded.
        try self.scanDeclareFnExternal("node", prelude.builtins);
        try self.scanDeclareFnExternal("node", prelude.primitives);
    }

    /// Scan `src` (embedded .bp source) for top-level `declare fn` carrying
    /// `#[@External.<Target>]` annotations. Registers single-template and
    /// module+symbol entries in `builtin_node_dispatch`. Arity-branched entries
    /// are registered inline via `registerInlineBuiltinDispatch`.
    fn scanDeclareFnExternal(self: *Emitter, target: []const u8, src: []const u8) !void {
        var scan_arena = std.heap.ArenaAllocator.init(self.alloc);
        defer scan_arena.deinit();
        const alloc_arena = scan_arena.allocator();
        var lx = lexerMod.Lexer.init(src);
        const tokens = lx.scanAll(alloc_arena) catch return;
        var p = parserMod.Parser.init(tokens);
        var program = p.parse(alloc_arena) catch return;
        defer program.deinit(alloc_arena);
        for (program.decls) |decl| {
            if (decl != .@"fn") continue;
            const f = decl.@"fn";
            if (self.builtin_node_dispatch.contains(f.name)) continue;
            if (ast.externalHasArityBranches(f.annotations, target)) {
                var branches: std.ArrayList(ast.ArityBranch) = .empty;
                errdefer branches.deinit(self.alloc);
                for (f.annotations) |a| {
                    if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], target)) continue;
                    for (a.args) |raw| {
                        const br = ast.parseArityBranchArg(raw) orelse continue;
                        try branches.append(self.alloc, .{
                            .argc = br.argc,
                            .template = try self.alloc.dupe(u8, br.template),
                        });
                    }
                }
                try self.builtin_node_dispatch.put(try self.alloc.dupe(u8, f.name), .{
                    .symbol = "",
                    .arity_branches = try branches.toOwnedSlice(self.alloc),
                });
                continue;
            }
            const ref = f.externalFor(target) orelse continue;
            if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                try self.builtin_node_dispatch.put(try self.alloc.dupe(u8, f.name), .{
                    .symbol = try self.alloc.dupe(u8, ref.symbol),
                    .module = "",
                });
            } else {
                // module+symbol form: `@External.Node("./mod", "fun")`
                try self.builtin_node_dispatch.put(try self.alloc.dupe(u8, f.name), .{
                    .symbol = try self.alloc.dupe(u8, ref.symbol),
                    .module = try self.alloc.dupe(u8, ref.module),
                });
            }
        }
    }

    /// Hand-rolls the `panic` / `todo` dispatch entries that `libs/std/src/
    /// builtins.d.bp` documents. Mirrors the `@external(node, when(argc == N))`
    /// annotation literally — kept here because the documented surface file
    /// is intentionally not parseable, but the dispatch needs these two
    /// callees registered to lower `@panic(…)` / `@todo(…)`.
    fn registerInlineBuiltinDispatch(self: *Emitter) !void {
        try self.putInlineBuiltin("todo", &.{
            .{ .argc = 0, .template = "(() => { throw new Error(\"not implemented\") })()" },
            .{ .argc = 1, .template = "(() => { throw new Error($0) })()" },
        });
        try self.putInlineBuiltin("panic", &.{
            .{ .argc = 0, .template = "(() => { throw new Error(\"panic\") })()" },
            .{ .argc = 1, .template = "(() => { throw new Error($0) })()" },
        });
        // §D1: `print`/`println`/`debug` — host `console.log`/`console.debug`
        // via the same template machinery. Variadic shape via `$args` (the
        // marker expands to every positional arg, comma-separated); the d.bp
        // annotations may not parse because earlier file content stops the
        // standalone parser, so this inline registration is the dispatch's
        // source of truth either way.
        try self.putInlineBuiltinTemplate("print", "console.log($args)");
        try self.putInlineBuiltinTemplate("println", "console.log($args)");
        try self.putInlineBuiltinTemplate("debug", "console.debug($args)");
    }

    fn putInlineBuiltinTemplate(self: *Emitter, name: []const u8, template: []const u8) !void {
        if (self.builtin_node_dispatch.contains(name)) return;
        try self.builtin_node_dispatch.put(try self.alloc.dupe(u8, name), .{
            .symbol = try self.alloc.dupe(u8, template),
        });
    }

    fn putInlineBuiltin(self: *Emitter, name: []const u8, branches: []const ast.ArityBranch) !void {
        if (self.builtin_node_dispatch.contains(name)) return;
        const owned = try self.alloc.alloc(ast.ArityBranch, branches.len);
        for (branches, 0..) |br, i| {
            owned[i] = .{
                .argc = br.argc,
                .template = try self.alloc.dupe(u8, br.template),
            };
        }
        try self.builtin_node_dispatch.put(try self.alloc.dupe(u8, name), .{
            .symbol = "",
            .arity_branches = owned,
        });
    }

    /// §A4: build the type-naive prim-method rename map from interface
    /// annotations. For each interface method carrying a 2-arg
    /// `@external(node, "X")` annotation whose symbol `X` differs from the
    /// method name, register `name → X` — UNLESS a record/struct in the program
    /// declares a method with the same name (a collision would silently rename
    /// the record call, e.g. `Set.contains` → `Set.includes`). The per-loc
    /// `renames` map (populated by inference's type-directed lookup) takes
    /// precedence and covers the collision-prone cases (`contains`); this map
    /// only catches calls inference never visits, namely interface default-fn
    /// bodies materialised as prototype patches.
    fn collectPrimNodeRenames(self: *Emitter, program: ast.Program) !void {
        var record_methods = std.StringHashMap(void).init(self.alloc);
        defer record_methods.deinit();
        for (program.decls) |decl| switch (decl) {
            .record => |r| for (r.methods) |m| try record_methods.put(m.name, {}),
            else => {},
        };
        for (program.decls) |decl| {
            if (decl != .interface) continue;
            for (decl.interface.methods) |m| {
                const ref = m.externalFor("node") orelse continue;
                if (ref.module.len != 0) continue;
                if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) continue;
                if (std.mem.eql(u8, ref.symbol, m.name)) continue;
                if (record_methods.contains(m.name)) continue;
                try self.prim_node_renames.put(m.name, ref.symbol);
            }
        }
    }

    /// Indexes every `@[external(…)]` fn by name: with a `node` target it
    /// goes to `externals` (alias form: `const fn = require(…);`) or
    /// `user_node_templates` (§A2 template form: `$0`/`$self`/… or
    /// `when(argc == N)` branches — rendered at each call site instead of
    /// aliased); without a node target it goes to `externals_missing` (so a
    /// call can fail with a clear error instead of an undefined identifier).
    fn collectExternals(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                // §A2 arity-branched template: `when(argc == N): "<tmpl>"`.
                if (ast.externalHasArityBranches(f.annotations, "node")) {
                    var branches: std.ArrayList(ast.ArityBranch) = .empty;
                    errdefer branches.deinit(self.alloc);
                    for (f.annotations) |a| {
                        if (!std.mem.startsWith(u8, a.name, "External.") or !std.ascii.eqlIgnoreCase(a.name["External.".len..], "node")) continue;
                        for (a.args) |raw| {
                            const br = ast.parseArityBranchArg(raw) orelse continue;
                            try branches.append(self.alloc, .{
                                .argc = br.argc,
                                .template = try self.alloc.dupe(u8, br.template),
                            });
                        }
                    }
                    try self.user_node_templates.put(try self.alloc.dupe(u8, f.name), .{
                        .symbol = "",
                        .arity_branches = try branches.toOwnedSlice(self.alloc),
                    });
                    continue;
                }
                if (f.externalFor("node")) |ref| {
                    // §A2 single-template form (`"$0.method(...)"`,
                    // `"new X($0).y()"`, etc.): the symbol carries `$` markers
                    // → render at the call site, never alias. A 1-arg form
                    // without markers (`"process.cwd()"`) has no module to
                    // `require` either: it is a bare host expression, so it
                    // renders at the call site too instead of lowering to
                    // `const { process.cwd(): cwd } = require("")`.
                    if (primOpTemplate.looksLikeTemplate(ref.symbol) or ref.module.len == 0) {
                        try self.user_node_templates.put(try self.alloc.dupe(u8, f.name), .{
                            .symbol = try self.alloc.dupe(u8, ref.symbol),
                        });
                        continue;
                    }
                    try self.externals.put(f.name, ref);
                } else {
                    try self.externals_missing.put(f.name, {});
                }
            },
            else => {},
        };
    }

    /// Indexes every name that emits as a JS class so constructor calls
    /// (`Pair(1, "one")`) can be emitted with `new` — JS classes cannot be
    /// invoked without it. Both `record X { … }` and the `val X = record { … }`
    /// shorthand normalize to `.record` decls in the parser.
    fn collectClassNames(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .record => |r| try self.class_names.put(r.name, {}),
            // An imported record is a class in its own module — a
            // construction here (`App(8080, "/")`) still needs `new`.
            .use => |u| if (self.cross) |xc| {
                for (u.imports) |imp| {
                    if (xc.exports.get(imp.name())) |info| {
                        if (info.is_class) try self.class_names.put(imp.name(), {});
                    }
                }
            },
            else => {},
        };
    }

    /// Indexes each payload variant's declared field names (see
    /// `variant_fields`). Enum sections are desugared into inner enums before
    /// codegen, so the top-level variant list is the whole surface.
    fn collectVariantFields(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"enum" => |e| for (e.variants) |v| {
                if (v.fields.len == 0) continue;
                const names = try self.arena().alloc([]const u8, v.fields.len);
                for (v.fields, 0..) |f, i| names[i] = f.name;
                try self.variant_fields.put(v.name, names);
            },
            else => {},
        };
    }

    /// `exports.<name> = <name>;` for a `pub` type that another module
    /// imports. Scoped to actually-consumed names so single-module programs
    /// (the vast majority of fixtures) emit no export line and stay unchanged.
    fn crossExport(self: *Emitter, name: []const u8) !?js.Stmt {
        const xc = self.cross orelse return null;
        if (!xc.imported.contains(name)) return null;
        return js.Stmt{ .expr = try self.b.assign(
            try self.b.member(.{ .name = "exports" }, name),
            "=",
            .{ .name = name },
        ) };
    }

    // ── helpers ───────────────────────────────────────────────────────────────

    /// Tuple positional member (`_0`, `_1`, …) → the digits, else null.
    /// Distinguishes tuple index access from `_`-prefixed record fields
    /// (`_balance`) by requiring every char after `_` to be a digit.
    fn tupleIndexMember(member: []const u8) ?[]const u8 {
        if (member.len < 2 or member[0] != '_') return null;
        for (member[1..]) |ch| {
            if (!std.ascii.isDigit(ch)) return null;
        }
        return member[1..];
    }

    /// True when a lambda's final statement is a plain value expression that
    /// should be implicitly returned (JS arrow blocks don't auto-return).
    /// Jumps (return/throw/break), bindings, branches, and loops are
    /// statements — never prefixed with `return`.
    fn isImplicitReturnExpr(e: ast.Expr) bool {
        return switch (e) {
            .literal, .identifier, .binaryOp, .unaryOp, .call, .collection, .function => true,
            .comptime_ => |ct| switch (ct.kind) {
                // `assert`/pattern-assert are statements, the rest are values.
                .assert, .assertPattern => false,
                else => true,
            },
            .jump, .branch, .loop, .binding, .useHook => false,
        };
    }

    /// `_try<N>` — a fresh temporary for one `try` lowering.
    fn tryName(self: *Emitter, n: usize) ![]const u8 {
        return std.fmt.allocPrint(self.arena(), "_try{d}", .{n});
    }

    /// `"error" in <temp>` — the Result discriminant test.
    fn errorIn(self: *Emitter, temp: []const u8) !js.Expr {
        return self.b.binaryBare("in", .{ .quoted = "error" }, .{ .name = temp });
    }

    // ── declarations ──────────────────────────────────────────────────────────

    fn buildValDecl(self: *Emitter, v: ast.ValDecl) !js.Stmt {
        return .{ .decl = .{
            .pattern = .{ .ident = v.name },
            .value = try self.buildExpr(v.value.*),
        } };
    }

    /// JS function keyword for a botopink function, driven by its effect kind.
    ///   `#[@future]`         → `async function`
    ///   `#[@iterator]`       → `function*`
    ///   `#[@generator]`      → `function*`
    ///   `#[@asyncGenerator]` → `async function*`
    ///   `#[@result]`         → `function` (checked-Result effect — plain fn)
    ///   `#[@context]` / none → `function`
    fn fnKeyword(f: ast.FnDecl) []const u8 {
        const eff = f.effect orelse return "function";
        return switch (eff) {
            .future => "async function",
            .iterator => "function*",
            .generator => "function*",
            .asyncGenerator => "async function*",
            .result => "function",
            .context => "function",
        };
    }

    /// A top-level `fn` decl: an external alias/template breadcrumb, or a real
    /// function plus its `exports.<name>` line.
    fn buildFnItem(self: *Emitter, f: ast.FnDecl) !js.Stmt {
        if (!f.isExternal()) return self.buildFn(f);
        // §A2 template-form external: no decl alias — the template renders
        // inline at every call site (see `tryUserTemplate`). Emit a one-line
        // doc breadcrumb so the emitted file stays self-documenting.
        if (self.user_node_templates.contains(f.name)) {
            return .{ .comment = .{
                .text = try std.fmt.allocPrint(self.arena(), "{s}: per-call template (see annotation)", .{f.name}),
            } };
        }
        const ref = self.externals.get(f.name) orelse return .{ .comment = .{
            .text = try std.fmt.allocPrint(self.arena(), "external fn {s} (no node target)", .{f.name}),
        } };
        const bind_name = jsIdent(f.name);
        const decl: js.Stmt = if (isJsGlobalNamespace(ref.module))
            // Global namespace (`Math`, `console`, …) — reference directly,
            // never `require`.
            .{ .decl = .{
                .pattern = .{ .name = bind_name },
                .value = try self.b.member(.{ .name = ref.module }, ref.symbol),
            } }
        else
            .{ .decl = .{
                .pattern = .{ .object = .{ .props = try self.arena().dupe(js.ObjectPattern.Prop, &.{.{
                    .key = ref.symbol,
                    .bind = if (std.mem.eql(u8, ref.symbol, bind_name)) null else bind_name,
                }}) } },
                .value = try self.requireCall(ref.module),
            } };
        if (!f.isPub) return decl;
        return self.b.group(&.{ decl, .{ .expr = try self.b.assign(
            try self.b.member(.{ .name = "exports" }, f.name),
            "=",
            .{ .name = bind_name },
        ) } });
    }

    fn requireCall(self: *Emitter, path: []const u8) !js.Expr {
        return self.b.call(.{ .name = "require" }, &.{.{ .quoted = path }});
    }

    fn buildFn(self: *Emitter, f: ast.FnDecl) anyerror!js.Stmt {
        self.try_seq = 0;
        const kw = fnKeyword(f);
        const prev_in_generator = self.in_generator;
        self.in_generator = std.mem.endsWith(u8, kw, "function*");
        defer self.in_generator = prev_in_generator;
        const params = try self.buildParams(f.params);
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        // Each function body gets a fresh reactive-name scope for hook deps.
        self.hook_state.clearRetainingCapacity();
        const body = try self.buildStmts(f.body);
        self.current_indent = prev_fn_indent;
        const decl = js.Stmt{ .function = .{
            .keyword = kw,
            .name = f.name,
            .params = params,
            .body = .{ .stmts = body },
        } };
        if (!f.isPub) return decl;
        return self.b.group(&.{ decl, .{ .expr = try self.b.assign(
            try self.b.member(.{ .name = "exports" }, f.name),
            "=",
            .{ .ident = f.name },
        ) } });
    }

    /// A `test { … }` body as `async function __bp_test_<idx>() { … }`.
    /// `async` so the body may `await flush()` / `await fetch(url)` — the
    /// test runner (`__bp_run_tests`) awaits the call. Sync test bodies
    /// pay no observable cost (a resolved Promise is returned and awaited).
    fn buildTestFn(self: *Emitter, t: ast.TestDecl, idx: usize) !js.Stmt {
        self.try_seq = 0;
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        self.hook_state.clearRetainingCapacity();
        const body = try self.buildStmts(t.body);
        self.current_indent = prev_fn_indent;
        return .{ .function = .{
            .keyword = "async function",
            .name = try std.fmt.allocPrint(self.arena(), "__bp_test_{d}", .{idx}),
            .body = .{ .stmts = body },
        } };
    }

    fn buildRecord(self: *Emitter, r: ast.RecordDecl) !js.Stmt {
        var ctor: ?js.Class.Ctor = null;
        if (r.fields.len > 0) {
            const params = try self.arena().alloc(js.Param, r.fields.len);
            const assigns = try self.arena().alloc(js.Stmt, r.fields.len);
            for (r.fields, 0..) |f, i| {
                params[i] = .{ .pattern = .{ .name = f.name } };
                assigns[i] = .{ .expr = try self.b.assign(
                    try self.b.member(.this, f.name),
                    "=",
                    .{ .name = f.name },
                ) };
            }
            ctor = .{ .params = params, .body = .{ .stmts = assigns, .indent = 1 } };
        }
        var members: std.ArrayListUnmanaged(js.Class.ClassMember) = .empty;
        for (r.methods) |m| {
            if (m.is_declare) continue;
            // A method with no `self` receiver is an associated function
            // (`Response.ok(...)`) — emit it as a `static` method so the call
            // resolves on the class itself, not an instance prototype.
            const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
            const params = try self.buildParams(m.params);
            self.current_indent = 2;
            const body = try self.buildStmts(m.body orelse &.{});
            self.current_indent = 0;
            try members.append(self.arena(), .{
                .kind = if (has_self) .method else .static_method,
                .name = m.name,
                .params = params,
                .body = .{ .stmts = body, .indent = 1 },
            });
        }
        const class = js.Stmt{ .class = .{
            .name = r.name,
            .ctor = ctor,
            .members = try members.toOwnedSlice(self.arena()),
        } };
        if (!r.isPub) return class;
        const exp = try self.crossExport(r.name) orelse return class;
        return self.b.group(&.{ class, exp });
    }

    fn buildEnum(self: *Emitter, e: ast.EnumDecl) !js.Stmt {
        var props: std.ArrayListUnmanaged(js.Object.Prop) = .empty;
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try props.append(self.arena(), .{ .kv = .{ .key = v.name, .value = .{ .quoted = v.name } } });
                continue;
            }
            const params = try self.arena().alloc(js.Param, v.fields.len);
            const obj_props = try self.arena().alloc(js.Object.Prop, v.fields.len + 1);
            obj_props[0] = .{ .kv = .{ .key = "tag", .value = .{ .quoted = v.name } } };
            for (v.fields, 0..) |f, i| {
                params[i] = .{ .pattern = .{ .name = f.name } };
                obj_props[i + 1] = .{ .shorthand = f.name };
            }
            try props.append(self.arena(), .{ .kv = .{
                .key = v.name,
                .value = try self.b.arrowExpr(params, try self.b.paren(.{ .object = .{ .props = obj_props } })),
            } });
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            const params = try self.buildParams(m.params);
            self.current_indent = 2;
            const body = try self.buildStmts(m.body orelse &.{});
            self.current_indent = 0;
            try props.append(self.arena(), .{ .kv = .{
                .key = m.name,
                .value = .{ .function = .{ .params = params, .body = .{ .stmts = body, .indent = 1 } } },
            } });
        }
        const decl = js.Stmt{ .decl = .{
            .pattern = .{ .name = e.name },
            .value = try self.b.call(
                try self.b.member(.{ .name = "Object" }, "freeze"),
                &.{.{ .object = .{ .props = try props.toOwnedSlice(self.arena()), .layout = .lines } }},
            ),
        } };
        if (!e.isPub) return decl;
        const exp = try self.crossExport(e.name) orelse return decl;
        return self.b.group(&.{ decl, exp });
    }

    fn buildInterface(self: *Emitter, i: ast.InterfaceDecl) !js.Stmt {
        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;

        // A doc block naming the interface's shape — the contract itself has no
        // runtime representation.
        var head: std.ArrayListUnmanaged(u8) = .empty;
        try head.print(self.arena(), "interface {s}", .{i.name});
        if (i.extends.len > 0) {
            try head.appendSlice(self.arena(), " extends ");
            for (i.extends, 0..) |ext, j| {
                if (j > 0) try head.appendSlice(self.arena(), ", ");
                try head.appendSlice(self.arena(), ext);
            }
        }
        try stmts.append(self.arena(), .{ .comment = .{ .text = try head.toOwnedSlice(self.arena()) } });
        for (i.fields) |f| try stmts.append(self.arena(), .{ .comment = .{
            .text = try std.fmt.allocPrint(self.arena(), "  {s}: {s}", .{ f.name, f.typeName }),
        } });
        for (i.methods) |m| try stmts.append(self.arena(), .{ .comment = .{
            .text = try std.fmt.allocPrint(
                self.arena(),
                "  {s}fn {s}(...)",
                .{ @as([]const u8, if (m.is_default) "default " else ""), m.name },
            ),
        } });

        // Associated functions (`default fn` with no `self` receiver, e.g.
        // `Pair.of`, `Function.compose`) materialize as a namespace object so
        // `Interface.method(...)` resolves at runtime. Instance methods (with a
        // `self` receiver) dispatch on the value and are not emitted here.
        var has_assoc = false;
        for (i.methods) |m| {
            if (isAssociatedFn(m)) {
                has_assoc = true;
                break;
            }
        }
        if (has_assoc) {
            // A JS-global-backed primitive (`Array`, `String`, the numeric tower,
            // `Bool`) already exists as a global constructor: associated fns are
            // statics on it (`Array.range = …`). Emitting `const Array = {}` would
            // SHADOW the global and leave `Array.prototype.*` patches setting
            // properties on `undefined`. Only a fresh interface (`Pair`/`Function`)
            // needs the namespace object.
            const assoc_ns = jsIdent(i.name);
            if (!isJsGlobalNamespace(jsPrototypeOwner(i.name)) and !isJsGlobalNamespace(i.name)) {
                try stmts.append(self.arena(), .{ .decl = .{
                    .pattern = .{ .name = assoc_ns },
                    .value = .{ .object = .{} },
                } });
            }
            for (i.methods) |m| {
                if (!isAssociatedFn(m)) continue;
                const body_src = m.body orelse continue;
                const params = try self.buildParams(m.params);
                const prev = self.current_indent;
                self.current_indent = 1;
                self.hook_state.clearRetainingCapacity();
                const body = try self.buildStmts(body_src);
                self.current_indent = prev;
                try stmts.append(self.arena(), .{ .expr = try self.b.assign(
                    try self.b.member(.{ .name = assoc_ns }, m.name),
                    "=",
                    .{ .function = .{ .params = params, .body = .{ .stmts = body } } },
                ) });
            }
        }

        // Instance default fns (`self` receiver) materialize as prototype methods
        // on the type's JS constructor (`Array.prototype.contains`), so
        // `value.method(...)` resolves at runtime. §A4: a 2-arg
        // `@external(node, "X")` annotation means "this method already exists on
        // the engine's prototype (possibly under a different name `X`) — don't
        // patch", and is the single skip-rule. The call-site rename map routes
        // `recv.method(args)` to `recv.X(args)` for the same call.
        const prev_self_param = self.self_is_param;
        defer self.self_is_param = prev_self_param;
        const owner = jsPrototypeOwner(i.name);
        const boxed = isBoxedPrototype(owner);
        for (i.methods) |m| {
            if (isAssociatedFn(m)) continue; // associated fns handled above
            if (m.params.len == 0 or !std.mem.eql(u8, m.params[0].name, "self")) continue;
            if (m.externalFor("node")) |ref| {
                // Template-form annotation (`$self`/`$0`/… markers): render the
                // template into a prototype-method body so `recv.method(args)`
                // dispatches at runtime without a hand-rolled `lowerXxx` arm.
                // §F1-commonJS of `prim-op-template-instance-methods` —
                // the 1-arg form has module="" + symbol=<template>, so this
                // case takes precedence over the §A4 native-prototype skip.
                if (primOpTemplate.looksLikeTemplate(ref.symbol)) {
                    var holes = MethodHoles{ .params = m.params[1..], .boxed_recv = boxed };
                    var tmpl = HostTemplate(MethodHoles){
                        .arena = self.arena(),
                        .holes = &holes,
                        .argc = m.params.len - 1,
                    };
                    try primOpTemplate.render(ref.symbol, &tmpl);
                    try stmts.append(self.arena(), try self.prototypeAssign(owner, m.name, .{
                        .params = try self.buildParams(m.params[1..]),
                        .body = .{ .stmts = try self.b.stmts(&.{.{ .return_ = try tmpl.finish() }}), .layout = .spaced },
                    }));
                    continue;
                }
                if (ref.module.len == 0) continue; // §A4: native prototype, no patch
            }

            if (m.is_default) {
                const body_src = m.body orelse continue;
                const params = try self.buildParams(m.params[1..]);
                const prev = self.current_indent;
                self.current_indent = 1;
                var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                // Boxed primitives wrap `this` in a (truthy) object — bind `self`
                // to the unwrapped primitive; arrays use `this` directly.
                if (boxed) {
                    try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .name = "self" },
                        .value = try self.b.call(try self.b.member(.this, "valueOf"), &.{}),
                    } });
                    self.self_is_param = true; // `self`/`self.x` stay `self`
                } else {
                    self.self_is_param = false; // bare `self` → `this`
                }
                self.hook_state.clearRetainingCapacity();
                for (body_src) |s| try body.append(self.arena(), try self.buildStmt(s));
                self.current_indent = prev;
                try stmts.append(self.arena(), try self.prototypeAssign(owner, m.name, .{
                    .params = params,
                    .body = .{ .stmts = try body.toOwnedSlice(self.arena()) },
                }));
            } else if (m.externalFor("node")) |ref| {
                // Host-backed instance method via a JS global namespace (`Math`):
                // `Owner.prototype.m = function(args){ return Mod.sym(self, args); }`.
                // Relative companions and call-template symbols are skipped (matches
                // the inference, which leaves them to native JS).
                if (!isJsGlobalNamespace(ref.module)) continue;
                if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) continue;
                var args: std.ArrayListUnmanaged(js.Expr) = .empty;
                try args.append(self.arena(), if (boxed)
                    try self.b.call(try self.b.member(.this, "valueOf"), &.{})
                else
                    js.Expr.this);
                for (m.params[1..]) |p| try args.append(self.arena(), .{ .ident = p.name });
                const call = try self.b.call(
                    try self.b.member(.{ .name = ref.module }, ref.symbol),
                    try args.toOwnedSlice(self.arena()),
                );
                try stmts.append(self.arena(), try self.prototypeAssign(owner, m.name, .{
                    .params = try self.buildParams(m.params[1..]),
                    .body = .{ .stmts = try self.b.stmts(&.{.{ .return_ = call }}), .layout = .spaced },
                }));
            }
        }
        return self.b.group(try stmts.toOwnedSlice(self.arena()));
    }

    /// `Owner.prototype.name = function(params) { … };`
    fn prototypeAssign(self: *Emitter, owner: []const u8, name: []const u8, f: js.FunctionExpr) !js.Stmt {
        return .{ .expr = try self.b.assign(
            try self.b.member(try self.b.member(.{ .name = owner }, "prototype"), name),
            "=",
            .{ .function = f },
        ) };
    }

    /// External dispatch: an `implement … for T` block is emitted as a namespace
    /// object whose methods take the receiver as an explicit `self` parameter, so
    /// `obj.m()` can be lowered to `Sym.m(obj)` without patching `T.prototype`.
    fn buildImplement(self: *Emitter, im: ast.ImplementDecl) !js.Stmt {
        var head: std.ArrayListUnmanaged(u8) = .empty;
        try head.appendSlice(self.arena(), "implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try head.appendSlice(self.arena(), ", ");
            try head.appendSlice(self.arena(), switch (iface) {
                .named => |n| n,
                .generic => |g| g.name,
                else => "?",
            });
        }
        try head.print(self.arena(), " for {s}", .{im.target});

        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;
        try stmts.append(self.arena(), .{ .comment = .{ .text = try head.toOwnedSlice(self.arena()) } });
        try stmts.append(self.arena(), try self.buildExtensionNamespace(im.name, im.methods));
        // A `pub` implement consumed by another module (via `import { Name* }`)
        // is exported so the consumer's `require` can bind it for dispatch.
        if (im.isPub) {
            if (try self.crossExport(im.name)) |exp| try stmts.append(self.arena(), exp);
        }
        return self.b.group(try stmts.toOwnedSlice(self.arena()));
    }

    /// External dispatch: an `extend T` block emitted as a namespace object.
    fn buildExtend(self: *Emitter, ex: ast.ExtendDecl) !js.Stmt {
        return self.b.group(&.{
            .{ .comment = .{ .text = try std.fmt.allocPrint(self.arena(), "extend {s}", .{ex.target}) } },
            try self.buildExtensionNamespace(ex.name, ex.methods),
        });
    }

    fn buildExtensionNamespace(self: *Emitter, name: []const u8, methods: []const ast.ImplementMethod) !js.Stmt {
        const prev_self = self.self_is_param;
        self.self_is_param = true;
        defer self.self_is_param = prev_self;
        const props = try self.arena().alloc(js.Object.Prop, methods.len);
        for (methods, 0..) |m, i| {
            // Extension methods keep `self` as a real first parameter.
            const params = try self.arena().alloc(js.Param, m.params.len);
            for (m.params, 0..) |p, pi| params[pi] = try self.buildParam(p);
            self.current_indent = 2;
            const body = try self.buildStmts(m.body);
            self.current_indent = 0;
            props[i] = .{ .method = .{
                .name = m.name,
                .params = params,
                .body = .{ .stmts = body, .indent = 1 },
            } };
        }
        return .{ .decl = .{
            .pattern = .{ .name = name },
            .value = .{ .object = .{ .props = props, .layout = .lines } },
        } };
    }

    fn buildUse(self: *Emitter, u: ast.ImportDecl) !js.Stmt {
        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;
        // Fallback activation `X*;` has no runtime binding — emit nothing.
        if (u.activationOnly) return self.b.group(&.{});

        // All emitted `require` targets are module paths relative to the OUTPUT
        // ROOT (`std/x`, `<dep>/<mod>`, …), but node resolves a `require` relative
        // to the requiring FILE. A module nested under a package prefix (a
        // dependency's `<dep>/<mod>`, depth 1) must therefore reach back up to the
        // root with one `../` per path segment before descending — without this,
        // `./<dep2>/<mod2>.js` required from `out/<dep>/<mod>.js` would resolve
        // under `out/<dep>/`. A top-level module (depth 0) keeps the plain `./`.
        const depth = std.mem.count(u8, self.module_name, "/");
        const req_prefix: []const u8 = blk: {
            var buf: std.ArrayListUnmanaged(u8) = .empty;
            if (depth == 0) {
                try buf.appendSlice(self.arena(), "./");
            } else {
                for (0..depth) |_| try buf.appendSlice(self.arena(), "../");
            }
            break :blk try buf.toOwnedSlice(self.arena());
        };
        // `"std"` package import: each item binds a whole stdlib module
        // emitted alongside the project (`out/std/<mod>.js`), so qualified
        // calls (`bool.negate(x)`) resolve naturally at runtime.
        if (u.source == .module and std.mem.eql(u8, u.source.module, "std")) {
            for (u.imports) |imp| {
                if (self.seen_imports.contains(imp.name())) continue;
                try self.seen_imports.put(imp.name(), {});
                const mod = imp.segments[imp.segments.len - 1];
                try stmts.append(self.arena(), .{ .decl = .{
                    .pattern = .{ .name = imp.name() },
                    .value = try self.requireCall(try std.fmt.allocPrint(self.arena(), "{s}std/{s}.js", .{ req_prefix, mod })),
                } });
            }
            return self.b.group(try stmts.toOwnedSlice(self.arena()));
        }
        // Package import (e.g. `from "web"`): resolve each name to the file
        // that actually emits it via the cross-module export index. Names with
        // no emitted home (declaration-only markers like lib decorators) emit
        // no runtime binding. One `require` per distinct source module, and a
        // name already bound in this module (a repeated import) is skipped so it
        // is never redeclared.
        if (u.source == .module and self.cross != null) {
            const xm = &self.cross.?.exports;
            var seen = std.StringHashMap(void).init(self.alloc);
            defer seen.deinit();
            for (u.imports) |imp| {
                const info = xm.get(imp.name()) orelse continue;
                if (seen.contains(info.module)) continue;
                try seen.put(info.module, {});
                // Names from this module not already bound here — `const {…}` for
                // exactly those. If every one is already bound, emit no line.
                var props: std.ArrayListUnmanaged(js.ObjectPattern.Prop) = .empty;
                for (u.imports) |imp2| {
                    const info2 = xm.get(imp2.name()) orelse continue;
                    if (!std.mem.eql(u8, info2.module, info.module)) continue;
                    if (self.seen_imports.contains(imp2.name())) continue;
                    try self.seen_imports.put(imp2.name(), {});
                    try props.append(self.arena(), .{ .key = imp2.name() });
                }
                if (props.items.len == 0) continue;
                try stmts.append(self.arena(), .{ .decl = .{
                    .pattern = .{ .object = .{ .props = try props.toOwnedSlice(self.arena()) } },
                    .value = try self.requireCall(try std.fmt.allocPrint(self.arena(), "{s}{s}.js", .{ req_prefix, info.module })),
                } });
            }
            // Namespace binding: when the import names the lib itself
            // (`import {Lib} from "Lib"`) and that name has no emitted symbol of
            // its own — it's a namespace handle (or a comptime template fn, whose
            // only runtime use is `Lib.member(...)`) — bind it to the lib's module
            // object so `Lib.member(...)` resolves at runtime, parity with the
            // destructured bare form. Generic: the core names no specific lib; the
            // lib is whatever `from "<lib>"` resolved off disk.
            const lib_name = u.source.module;
            var names_lib = false;
            for (u.imports) |imp| {
                if (std.mem.eql(u8, imp.name(), lib_name)) {
                    names_lib = true;
                    break;
                }
            }
            if (names_lib and xm.get(lib_name) == null) {
                // Distinct modules emitted under the lib's `<lib>/` path prefix,
                // sorted for deterministic output (the export map is unordered).
                var mods: std.ArrayListUnmanaged([]const u8) = .empty;
                defer mods.deinit(self.alloc);
                var mseen = std.StringHashMap(void).init(self.alloc);
                defer mseen.deinit();
                const mod_prefix = try std.fmt.allocPrint(self.alloc, "{s}/", .{lib_name});
                defer self.alloc.free(mod_prefix);
                var it = xm.valueIterator();
                while (it.next()) |info| {
                    const m = info.module;
                    if (!std.mem.startsWith(u8, m, mod_prefix)) continue;
                    if (mseen.contains(m)) continue;
                    try mseen.put(m, {});
                    try mods.append(self.alloc, m);
                }
                if (mods.items.len > 0) {
                    std.mem.sort([]const u8, mods.items, {}, struct {
                        fn lt(_: void, a: []const u8, b: []const u8) bool {
                            return std.mem.lessThan(u8, a, b);
                        }
                    }.lt);
                    const value: js.Expr = if (mods.items.len == 1)
                        try self.requireCall(try std.fmt.allocPrint(self.arena(), "{s}{s}.js", .{ req_prefix, mods.items[0] }))
                    else blk: {
                        var args: std.ArrayListUnmanaged(js.Expr) = .empty;
                        try args.append(self.arena(), .{ .object = .{} });
                        for (mods.items) |m| try args.append(
                            self.arena(),
                            try self.requireCall(try std.fmt.allocPrint(self.arena(), "{s}{s}.js", .{ req_prefix, m })),
                        );
                        break :blk try self.b.call(
                            try self.b.member(.{ .name = "Object" }, "assign"),
                            try args.toOwnedSlice(self.arena()),
                        );
                    };
                    try stmts.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .name = jsIdent(lib_name) },
                        .value = value,
                    } });
                }
            }
            return self.b.group(try stmts.toOwnedSlice(self.arena()));
        }

        var props: std.ArrayListUnmanaged(js.ObjectPattern.Prop) = .empty;
        for (u.imports) |imp| {
            if (self.seen_imports.contains(imp.name())) continue;
            try self.seen_imports.put(imp.name(), {});
            try props.append(self.arena(), .{ .key = imp.name() });
        }
        if (props.items.len == 0) return self.b.group(&.{});
        return .{ .decl = .{
            .pattern = .{ .object = .{ .props = try props.toOwnedSlice(self.arena()) } },
            .value = try self.requireCall(switch (u.source) {
                .root => try std.fmt.allocPrint(self.arena(), "{s}module", .{req_prefix}),
                .module => |name| name,
            }),
        } };
    }

    // ── params & patterns ─────────────────────────────────────────────────────

    fn buildParams(self: *Emitter, params: []const ast.Param) ![]const js.Param {
        var out: std.ArrayListUnmanaged(js.Param) = .empty;
        for (params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try out.append(self.arena(), try self.buildParam(p));
        }
        return out.toOwnedSlice(self.arena());
    }

    fn buildParam(self: *Emitter, p: ast.Param) !js.Param {
        const d = p.destruct orelse return .{ .pattern = .{ .ident = p.name } };
        return switch (d) {
            // A destructuring parameter takes no default.
            .names => .{ .pattern = try self.buildNamesPattern(d.names) },
            .tuple_ => |t| .{ .pattern = try self.buildTuplePattern(t) },
            .list => |pat| .{ .pattern = try self.buildPattern(pat) },
            .ctor => |pat| .{ .pattern = try self.buildPattern(pat) },
        };
    }

    fn buildNamesPattern(self: *Emitter, n: anytype) !js.Pattern {
        const props = try self.arena().alloc(js.ObjectPattern.Prop, n.fields.len);
        for (n.fields, 0..) |nm, i| props[i] = .{ .key = nm.bind_name };
        // `{ x, .. }` ignores the rest (the parser has no named record rest),
        // and JS object destructuring already ignores unlisted keys, so the
        // `..` emits nothing (JS-3).
        return .{ .object = .{ .props = props } };
    }

    fn buildTuplePattern(self: *Emitter, names: []const []const u8) !js.Pattern {
        const elems = try self.arena().alloc(js.Pattern, names.len);
        for (names, 0..) |nm, i| elems[i] = .{ .ident = nm };
        return .{ .array = .{ .elems = elems, .spaced = true } };
    }

    fn buildPattern(self: *Emitter, pat: ast.Pattern) anyerror!js.Pattern {
        switch (pat) {
            .wildcard => return .{ .name = "_" },
            .ident => |name| return .{ .ident = name },
            .variant => |v| return switch (v.payload) {
                .binding => |binding| js.Pattern{ .match = .{ .variant_binding = .{ .name = v.name, .binding = binding } } },
                .fields => |fields| js.Pattern{ .match = .{ .variant_fields = .{ .name = v.name, .fields = fields } } },
                .literals => |args| blk: {
                    const out = try self.arena().alloc(js.Pattern, args.len);
                    for (args, 0..) |arg, i| out[i] = try self.buildPattern(arg);
                    break :blk js.Pattern{ .match = .{ .variant_patterns = .{ .name = v.name, .args = out } } };
                },
            },
            .numberLit => |n| return .{ .match = .{ .number = n } },
            .stringLit => |s| return .{ .match = .{ .string = s } },
            .list => |l| {
                const elems = try self.arena().alloc(js.Pattern, l.elems.len);
                for (l.elems, 0..) |e, i| elems[i] = switch (e) {
                    .wildcard => js.Pattern{ .name = "_" },
                    .bind => |name| js.Pattern{ .ident = name },
                    .numberLit => |n| js.Pattern{ .match = .{ .number = n } },
                };
                return .{
                    .array = .{
                        .elems = elems,
                        // A nameless `..` ignores the trailing elements, which JS
                        // array destructuring already does: no rest element.
                        .rest = if (l.spread) |sp| (if (sp.len > 0) js.Rest{ .binding = sp } else null) else null,
                    },
                };
            },
            .@"or" => |pats| {
                const out = try self.arena().alloc(js.Pattern, pats.len);
                for (pats, 0..) |p, i| out[i] = try self.buildPattern(p);
                return .{ .match = .{ .alt = out } };
            },
            .multi => |pats| {
                const out = try self.arena().alloc(js.Pattern, pats.len);
                for (pats, 0..) |p, i| out[i] = try self.buildPattern(p);
                return .{ .match = .{ .multi = out } };
            },
        }
    }

    /// The binding form of a `localBindDestruct` / a `try` head.
    fn buildDestructPattern(self: *Emitter, pattern: ast.ParamDestruct) !js.Pattern {
        return switch (pattern) {
            .names => try self.buildNamesPattern(pattern.names),
            .tuple_ => |t| try self.buildTuplePattern(t),
            .list => |pat| try self.buildPattern(pat),
            .ctor => |pat| try self.buildPattern(pat),
        };
    }

    /// Record the names introduced by a destructuring `use` as reactive deps.
    fn trackDestructNames(self: *Emitter, pattern: ast.ParamDestruct) !void {
        switch (pattern) {
            .names => |n| for (n.fields) |nm| try self.hook_state.append(self.alloc, nm.bind_name),
            .tuple_ => |t| for (t) |nm| try self.hook_state.append(self.alloc, nm),
            else => {},
        }
    }

    /// The runtime test a botopink pattern becomes, over `value`.
    fn buildPatternCheck(self: *Emitter, pat: *const ast.Pattern, value: []const u8) anyerror!js.Expr {
        const subject = js.Expr{ .name = value };
        switch (pat.*) {
            .wildcard => return .{ .name = "true" }, // Wildcard matches everything
            // Identifier pattern — the value just has to exist.
            .ident => return self.b.paren(try self.b.binaryBare(
                "&&",
                try self.b.binaryBare("!==", subject, .null_),
                try self.b.binaryBare("!==", subject, .{ .name = "undefined" }),
            )),
            .variant => |v| return switch (v.payload) {
                // Check if value is an instance of the variant type.
                .binding, .fields => try self.b.paren(try self.b.binaryBare("instanceof", subject, .{ .name = v.name })),
                // Literal-argument variants fall back to the generic check below.
                .literals => js.Expr{ .name = "true" },
            },
            .numberLit => |n| return self.b.paren(try self.b.binaryBare("===", subject, .{ .number = n })),
            .stringLit => |s| return self.b.paren(try self.b.binaryBare("===", subject, .{ .quoted = s })),
            .list => |l| {
                const is_array = try self.b.call(try self.b.member(.{ .name = "Array" }, "isArray"), &.{subject});
                if (l.elems.len == 0) return self.b.paren(is_array);
                return self.b.paren(try self.b.binaryBare("&&", is_array, try self.b.binaryBare(
                    ">=",
                    try self.b.member(subject, "length"),
                    .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{l.elems.len}) },
                )));
            },
            .@"or" => |patterns| {
                if (patterns.len == 0) return .{ .name = "false" };
                var acc = try self.buildPatternCheck(&patterns[0], value);
                for (patterns[1..]) |*p| acc = try self.b.binaryBare("||", acc, try self.buildPatternCheck(p, value));
                return acc;
            },
            else => return .{ .name = "true" }, // Fallback for other pattern types
        }
    }

    // ── statements ────────────────────────────────────────────────────────────

    fn buildStmts(self: *Emitter, body: []const ast.Stmt) anyerror![]const js.Stmt {
        const out = try self.arena().alloc(js.Stmt, body.len);
        for (body, 0..) |s, i| out[i] = try self.buildStmt(s);
        return out;
    }

    fn buildStmt(self: *Emitter, stmt: ast.Stmt) anyerror!js.Stmt {
        const e = stmt.expr;
        switch (e) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const kw: js.Decl.Kw = if (lb.mutable) .let_ else .const_;
                    if (classifyTry(lb.value.*)) |form| {
                        return self.buildTryStmt(form, .{ .decl = .{ .kw = kw, .name = lb.name } });
                    }
                    // `val d = use memo { … }` → `const d = useMemo(…, [deps])`.
                    const value = if (useHookInner(lb.value.*)) |inner| blk: {
                        const hook = try self.buildHookCall(inner.*);
                        try self.hook_state.append(self.alloc, lb.name);
                        break :blk hook;
                    } else try self.buildExpr(lb.value.*);
                    return .{ .decl = .{ .kw = kw, .pattern = .{ .ident = lb.name }, .value = value } };
                },
                .localBindDestruct => |lb| {
                    if (classifyTry(lb.value.*)) |form| {
                        return self.buildTryStmt(form, .{ .destruct = .{ .mutable = lb.mutable, .pattern = lb.pattern } });
                    }
                    // `val {v, s} = use state(0)` → `const { v, s } = useState(0)`.
                    const value = if (useHookInner(lb.value.*)) |inner| blk: {
                        const hook = try self.buildHookCall(inner.*);
                        try self.trackDestructNames(lb.pattern);
                        break :blk hook;
                    } else try self.buildExpr(lb.value.*);
                    return .{ .decl = .{
                        .kw = if (lb.mutable) .let_ else .const_,
                        .pattern = try self.buildDestructPattern(lb.pattern),
                        .value = value,
                    } };
                },
                else => return .{ .expr = try self.buildExpr(e) },
            },
            // A bare `use <hookcall>;` statement is a void hook (e.g. `use effect { … }`).
            .useHook => |uh| return .{ .expr = try self.buildHookCall(uh.kind.inner.*) },
            // An `if` whose branches jump out (`return`, `break`, `continue`)
            // is a JS `if` statement: a jump cannot leave the IIFE the value
            // form wraps it in.
            .branch => |br| switch (br.kind) {
                .if_ => |i| if (self.ifJumps(i)) return self.buildIfStmt(i),
                .tryCatch => {},
            },
            .loop => |lp| if (try self.buildLoopStmt(lp)) |st| return st,
            .jump => |j| switch (j.kind) {
                .@"break" => |br| return self.buildBreakStmt(br, false),
                .throw_ => |r| return .{ .throw_ = try self.buildExpr((r orelse return error.ThrowWithoutOperand).*) },
                .@"continue" => return switch (self.loop_ctx) {
                    .none => error.JumpOutsideLoop,
                    .stmt, .value => js.Stmt.continue_,
                },
                .yield => |y| if (self.loop_ctx == .value) {
                    // An accumulator `yield <v>` contributes `v` and moves on;
                    // a valueless one contributes nothing.
                    const val = y.value orelse return .continue_;
                    return self.b.group(&.{ try self.accPush(val.*), .continue_ });
                },
                else => {},
            },
            else => {},
        }
        switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    const rp = r orelse return .{ .return_ = null };
                    if (classifyTry(rp.*)) |form| return self.buildTryStmt(form, .ret);
                    // `return case … { A -> v; B -> return x; }` — an arm that
                    // returns from the function cannot sit inside the IIFE a
                    // `case` value lowers to, so the whole `case` becomes
                    // statements and every value arm returns (wrapped in
                    // `{ ok }` when `#[@result]` wrapped the case).
                    if (try self.buildReturnCaseStmt(rp.*)) |st| return st;
                    // §1F F4F-T2 — strip the post-transform future markers
                    // back to native shapes. The `async function` machinery
                    // is the actual promise wrap; the markers exist for
                    // backends that need an explicit form (and for uniform
                    // post-transform AST).
                    if (futureWrapCallName(rp.*)) |kind| {
                        const inner = try self.buildExpr(rp.*.call.kind.call.args[0].value.*);
                        return switch (kind) {
                            .resolved => js.Stmt{ .return_ = inner },
                            .rejected => js.Stmt{ .throw_ = inner },
                        };
                    }
                    // `return <iter>` in an `#[@iterator] fn -> @Iterator`
                    // delegates: `yield* <iter>; return;` (a plain
                    // `return <gen>` surfaces the generator object and
                    // yields nothing).
                    if (self.in_generator) return .{ .yield_delegate = try self.buildExpr(rp.*) };
                    return .{ .return_ = try self.buildExpr(rp.*) };
                },
                else => {
                    if (classifyTry(e)) |form| return self.buildTryStmt(form, .discard);
                    return .{ .expr = try self.buildExpr(e) };
                },
            },
            else => {
                if (classifyTry(e)) |form| return self.buildTryStmt(form, .discard);
                return .{ .expr = try self.buildExpr(e) };
            },
        }
    }

    // ── use-hooks (React-like target) ─────────────────────────────────────────

    /// Hooks whose lambda argument is wrapped with an inferred dependency array,
    /// matching React's `useMemo`/`useEffect`/`useCallback` calling convention.
    fn hookTakesDeps(callee: []const u8) bool {
        const with_deps = [_][]const u8{ "memo", "effect", "callback", "layoutEffect", "imperativeHandle" };
        for (with_deps) |h| if (std.mem.eql(u8, callee, h)) return true;
        return false;
    }

    /// A hook's JS name. Bare capability names map by the React convention
    /// `state` → `useState`, `memo` → `useMemo`. Names already in `useXxx` form
    /// (custom hooks like `useAuth`) pass through unchanged.
    fn hookName(self: *Emitter, callee: []const u8) ![]const u8 {
        const is_custom = callee.len > 3 and
            std.mem.startsWith(u8, callee, "use") and
            std.ascii.isUpper(callee[3]);
        if (is_custom) return callee;
        if (callee.len == 0) return "use";
        return std.fmt.allocPrint(self.arena(), "use{c}{s}", .{ std.ascii.toUpper(callee[0]), callee[1..] });
    }

    /// A `use`-hook's value expression as a React hook call: map the hook
    /// name and, for dependency-taking hooks, append the inferred deps array.
    fn buildHookCall(self: *Emitter, value: ast.Expr) anyerror!js.Expr {
        const cc = switch (value) {
            .call => |c| switch (c.kind) {
                .call => |call| call,
                else => return self.buildExpr(value),
            },
            else => return self.buildExpr(value),
        };

        const callee: js.Expr = if (cc.receiver) |recv|
            try self.b.member(try self.buildExpr(recv.*), cc.callee)
        else
            .{ .name = try self.hookName(cc.callee) };

        var args: std.ArrayListUnmanaged(js.Expr) = .empty;
        for (cc.args) |arg| try args.append(self.arena(), try self.buildExpr(arg.value.*));
        for (cc.trailing) |tl| try args.append(self.arena(), try self.buildLambda(tl.params, tl.body));
        if (hookTakesDeps(cc.callee)) {
            try args.append(self.arena(), .{ .array = .{ .elems = try self.buildHookDeps(cc) } });
        }
        return self.b.call(callee, try args.toOwnedSlice(self.arena()));
    }

    /// The inferred dependency array contents: the reactive names (bound by
    /// prior hooks) referenced inside this hook's lambda argument, in source order.
    fn buildHookDeps(self: *Emitter, cc: anytype) ![]const js.Expr {
        var out: std.ArrayListUnmanaged(js.Expr) = .empty;
        const body = hookLambdaBody(cc) orelse return out.toOwnedSlice(self.arena());
        for (self.hook_state.items) |name| {
            for (body) |s| {
                if (specialize.identInExpr(s.expr, name)) {
                    try out.append(self.arena(), .{ .name = name });
                    break;
                }
            }
        }
        return out.toOwnedSlice(self.arena());
    }

    /// Find the lambda body among a hook call's arguments (the dependency source).
    fn hookLambdaBody(cc: anytype) ?[]ast.Stmt {
        for (cc.args) |arg| switch (arg.value.*) {
            .function => |f| return f.kind.body,
            else => {},
        };
        if (cc.trailing.len > 0) return cc.trailing[0].body;
        return null;
    }

    /// A `params => { body }` arrow function (for trailing-lambda hook args).
    fn buildLambda(self: *Emitter, params: []const []const u8, body: []ast.Stmt) !js.Expr {
        // A nested arrow is not a generator — its `return` stays `return` —
        // and no jump crosses it.
        const prev_in_generator = self.in_generator;
        const prev_ctx = self.loop_ctx;
        const prev_wrap = self.case_ok_wrap;
        self.in_generator = false;
        self.loop_ctx = .none;
        self.case_ok_wrap = false;
        defer {
            self.in_generator = prev_in_generator;
            self.loop_ctx = prev_ctx;
            self.case_ok_wrap = prev_wrap;
        }
        const ps = try self.arena().alloc(js.Param, params.len);
        for (params, 0..) |p, i| ps[i] = .{ .pattern = .{ .ident = p } };
        return self.b.arrowBlock(ps, .{
            .stmts = try self.buildStmts(body),
            .layout = .fixed,
            .indent = self.current_indent,
        });
    }

    /// A trailing/inline lambda body: the tail value expression is its result,
    /// because a JS arrow block does not auto-return.
    fn buildLambdaBody(self: *Emitter, body: []const ast.Stmt) ![]const js.Stmt {
        const out = try self.arena().alloc(js.Stmt, body.len);
        for (body, 0..) |st, i| {
            if (i == body.len - 1 and isImplicitReturnExpr(st.expr)) {
                out[i] = .{ .return_ = try self.buildExpr(st.expr) };
            } else {
                out[i] = try self.buildStmt(st);
            }
        }
        return out;
    }

    /// `(params) => { body }` with implicit tail return.
    fn buildArrow(self: *Emitter, params: []const []const u8, body: []const ast.Stmt) !js.Expr {
        // A nested arrow is not a generator — its `return` stays `return` —
        // and no jump crosses it.
        const prev_in_generator = self.in_generator;
        const prev_ctx = self.loop_ctx;
        const prev_wrap = self.case_ok_wrap;
        self.in_generator = false;
        self.loop_ctx = .none;
        self.case_ok_wrap = false;
        defer {
            self.in_generator = prev_in_generator;
            self.loop_ctx = prev_ctx;
            self.case_ok_wrap = prev_wrap;
        }
        const ps = try self.arena().alloc(js.Param, params.len);
        for (params, 0..) |p, i| ps[i] = .{ .pattern = .{ .ident = p } };
        return self.b.arrowBlock(ps, .{
            .stmts = try self.buildLambdaBody(body),
            .layout = .fixed,
            .indent = self.current_indent,
        });
    }

    // ── try/catch lowering ────────────────────────────────────────────────────

    /// Wrap `value` in the binding head that receives the unwrapped Ok value.
    fn tryHeadStmt(self: *Emitter, head: TryHead, value: js.Expr) !js.Stmt {
        return switch (head) {
            .decl => |d| js.Stmt{ .decl = .{ .kw = d.kw, .pattern = .{ .name = d.name }, .value = value } },
            .destruct => |d| js.Stmt{ .decl = .{
                .kw = if (d.mutable) .let_ else .const_,
                .pattern = try self.buildDestructPattern(d.pattern),
                .value = value,
            } },
            .ret => js.Stmt{ .return_ = value },
            .discard => js.Stmt{ .expr = value },
        };
    }

    /// Lower a `try`/`catch` at statement position to `"error" in _r` pattern
    /// matching over the `{ ok: V } | { error: E }` Result value — never JS
    /// try/catch. `head` says where the Ok value lands.
    fn buildTryStmt(self: *Emitter, form: TryForm, head: TryHead) anyerror!js.Stmt {
        const n = self.try_seq;
        self.try_seq += 1;
        const temp = try self.tryName(n);

        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;
        try stmts.append(self.arena(), .{ .decl = .{
            .pattern = .{ .name = temp },
            .value = try self.buildExpr(form.inner()),
        } });

        switch (form) {
            .catchValue => |cv| {
                var fallback = try self.b.paren(try self.buildExpr(cv.handler));
                if (cv.is_lambda) fallback = try self.b.call(fallback, &.{try self.b.member(.{ .name = temp }, "error")});
                try stmts.append(self.arena(), try self.tryHeadStmt(head, try self.b.ternary(
                    try self.errorIn(temp),
                    fallback,
                    try self.b.member(.{ .name = temp }, "ok"),
                )));
            },
            .propagate => {
                try stmts.append(self.arena(), try self.b.ifStmt(
                    try self.errorIn(temp),
                    .{ .return_ = .{ .name = temp } },
                ));
                if (try self.tryValueStmt(head, temp)) |s| try stmts.append(self.arena(), s);
            },
            .catchJump => |cj| {
                try stmts.append(self.arena(), try self.b.ifStmt(try self.errorIn(temp), .{ .block = .{
                    .stmts = try self.b.stmts(&.{try self.buildStmt(.{ .expr = cj.handler })}),
                    .layout = .spaced,
                } }));
                if (try self.tryValueStmt(head, temp)) |s| try stmts.append(self.arena(), s);
            },
        }
        return self.b.group(try stmts.toOwnedSlice(self.arena()));
    }

    /// `<head>_tryN.ok;`, unless the value is discarded.
    fn tryValueStmt(self: *Emitter, head: TryHead, temp: []const u8) !?js.Stmt {
        if (head == .discard) return null;
        return try self.tryHeadStmt(head, try self.b.member(.{ .name = temp }, "ok"));
    }

    /// The last statement of an `if`-expression branch, as a value.
    fn buildIfLast(self: *Emitter, stmt: ast.Stmt) anyerror!js.Stmt {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return", .throw_ => return self.buildStmt(stmt),
                else => {},
            },
            // A trailing binding gives the branch no value.
            .binding => |b| switch (b.kind) {
                .localBind, .localBindDestruct => return self.buildStmt(stmt),
                .assign => {},
            },
            else => {},
        }
        return .{ .return_ = try self.buildExpr(stmt.expr) };
    }

    // ── expressions ───────────────────────────────────────────────────────────

    /// The inline CommonJS form for a lowered `@Result`/`@Option` method op.
    /// `args[0]` is the receiver expression; `args[1]` (when present) is the
    /// transform function or default value. An IIFE binds the receiver once so it
    /// is not re-evaluated (important for method chains).
    fn buildResultOptionOp(self: *Emitter, callee: []const u8, args: []const ast.CallArg) anyerror!js.Expr {
        const recv = try self.buildExpr(args[0].value.*);
        // Only the transform / default-value ops read a second argument, and
        // the transform always supplies it for them.
        const arg1: js.Expr = if (args.len > 1) try self.buildExpr(args[1].value.*) else js.Expr.null_;
        const r = js.Expr{ .name = "_r" };
        const o = js.Expr{ .name = "_o" };
        const r_param = [_]js.Param{.{ .pattern = .{ .name = "_r" } }};
        const o_param = [_]js.Param{.{ .pattern = .{ .name = "_o" } }};
        const error_in_r = try self.b.binaryBare("in", .{ .quoted = "error" }, r);
        const o_present = try self.b.binaryBare("!=", o, .null_);

        if (std.mem.eql(u8, callee, "__bp_ok")) {
            // Result constructor: `return v` in a `-> @Result<…>` fn.
            return self.b.paren(try self.b.object(&.{.{ .kv = .{ .key = "ok", .value = recv } }}));
        }
        if (std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor: `throw e` in a `-> @Result<…>` fn.
            return self.b.paren(try self.b.object(&.{.{ .kv = .{ .key = "error", .value = recv } }}));
        }
        if (std.mem.eql(u8, callee, "__bp_result_map")) {
            const mapped = try self.b.object(&.{.{ .kv = .{
                .key = "ok",
                .value = try self.b.call(try self.b.paren(arg1), &.{try self.b.member(r, "ok")}),
            } }});
            return self.applyLambda(&r_param, try self.b.ternary(error_in_r, r, mapped), recv);
        }
        if (std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            const mapped = try self.b.call(try self.b.paren(arg1), &.{try self.b.member(r, "ok")});
            return self.applyLambda(&r_param, try self.b.ternary(error_in_r, r, mapped), recv);
        }
        if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            return self.applyLambda(&r_param, try self.b.ternary(
                error_in_r,
                try self.b.paren(arg1),
                try self.b.member(r, "ok"),
            ), recv);
        }
        if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            return self.applyLambda(&r_param, try self.b.unary("!", try self.b.paren(error_in_r), false), recv);
        }
        if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            return self.applyLambda(&r_param, error_in_r, recv);
        }
        if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            return self.applyLambda(&o_param, try self.b.ternary(
                o_present,
                try self.b.call(try self.b.paren(arg1), &.{o}),
                .null_,
            ), recv);
        }
        if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            return self.applyLambda(&o_param, try self.b.ternary(o_present, o, try self.b.paren(arg1)), recv);
        }
        // The `#[@future]` markers outside a `return` (which strips them in
        // `buildStmt`): resolving is the value, rejecting throws.
        if (std.mem.eql(u8, callee, "__bp_future_resolved")) return recv;
        if (std.mem.eql(u8, callee, "__bp_future_rejected")) return self.b.iife(&.{.{ .throw_ = recv }});
        return error.UnknownResultOptionOp;
    }

    /// `((p) => body)(arg)` — bind the receiver once.
    fn applyLambda(self: *Emitter, params: []const js.Param, body: js.Expr, arg: js.Expr) !js.Expr {
        return self.b.call(try self.b.paren(try self.b.arrowExpr(params, body)), &.{arg});
    }

    fn buildExpr(self: *Emitter, e: ast.Expr) anyerror!js.Expr {
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => |s| return .{ .lexeme_string = s },
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .numberLit => |n| return .{ .number = n },
                .null_ => return .null_,
                .comment => |c| return .{ .comment = .{
                    .style = switch (c.kind) {
                        .normal => .line,
                        .doc => .doc,
                        .module => .module,
                    },
                    .text = c.text,
                } },
            },

            .identifier => |id| switch (id.kind) {
                // Bare `self` as a value (`var out = self;`, `return self;`) in a
                // prototype method lowers to `this`; only extension methods keep
                // `self` as a real parameter (`self_is_param`).
                .ident => |n| {
                    if (std.mem.eql(u8, n, "self") and !self.self_is_param) return .this;
                    return .{ .ident = n };
                },
                .dotIdent => |n| return .{ .name = n },
                .identAccess => |ia| {
                    const isSelf = switch (ia.receiver.*) {
                        .identifier => |recv_id| if (recv_id.kind == .ident)
                            std.mem.eql(u8, recv_id.kind.ident, "self")
                        else
                            false,
                        else => false,
                    };
                    if (isSelf) {
                        return self.b.member(if (self.self_is_param) js.Expr{ .ident = "self" } else .this, ia.member);
                    }
                    const recv = try self.buildExpr(ia.receiver.*);
                    // Tuple index access: `t._N` → `t[N]` (tuples are JS arrays).
                    if (tupleIndexMember(ia.member)) |idx| {
                        return self.b.index(recv, .{ .number = idx }, ia.optional);
                    }
                    // `s.len` / `arr.len` on a typed string or array is the
                    // host length (C3): JS spells it as the `.length` property.
                    // Inference records the primitive kind only for a typed
                    // receiver, so a record field named `len` is untouched.
                    if (std.mem.eql(u8, ia.member, "len")) if (self.lowerings) |lw| if (lw.get(id.loc)) |il| if (il == .prim) {
                        return self.b.memberOpt(recv, "length", ia.optional);
                    };
                    // Optional chaining maps 1:1 to native JS `?.`.
                    return self.b.memberOpt(recv, ia.member, ia.optional);
                },
            },

            .binaryOp => |bin| {
                const op: []const u8 = switch (bin.op) {
                    .add => "+",
                    .sub => "-",
                    .mul => "*",
                    .div => "/",
                    .mod => "%",
                    .lt => "<",
                    .gt => ">",
                    .lte => "<=",
                    .gte => ">=",
                    // `x == null` / `x != null` lower to loose `==`/`!=` so a `?T`
                    // none represented as `undefined` (e.g. `Array.at()` past the
                    // end) matches the `null` none literal — botopink treats both
                    // as the single none value. All other `==` stay strict `===`.
                    .eq => if (isNullLiteral(bin.lhs.*) or isNullLiteral(bin.rhs.*)) "==" else "===",
                    .ne => if (isNullLiteral(bin.lhs.*) or isNullLiteral(bin.rhs.*)) "!=" else "!==",
                    .@"and" => "&&",
                    .@"or" => "||",
                };
                return self.b.binary(op, try self.buildExpr(bin.lhs.*), try self.buildExpr(bin.rhs.*));
            },

            .unaryOp => |un| return self.b.unary(switch (un.op) {
                .not => "!",
                .neg => "-",
            }, try self.buildExpr(un.expr.*), true),

            .jump => |j| switch (j.kind) {
                // `return` / `break` / `continue` are statements that leave the
                // enclosing function or loop. Every position that can hold one
                // (a block statement, an `if` / `case` arm in statement or
                // return position) is lowered by `buildStmt`; in a value
                // position the jump would have to cross the IIFE the value is
                // wrapped in, which JavaScript cannot express.
                .@"return", .@"break", .@"continue" => return error.JumpInValuePosition,
                // `throw` leaves by unwinding, which crosses a function
                // boundary: in value position it is a one-statement IIFE.
                // The parser gives `throw` an operand (`throw;` is a parse
                // error), so a missing one is a frontend defect.
                .throw_ => |r| return self.b.iife(&.{.{
                    .throw_ = try self.buildExpr((r orelse return error.ThrowWithoutOperand).*),
                }}),
                .try_ => |t| {
                    // The parser always gives `try` an operand.
                    const val = t orelse return error.TryWithoutOperand;
                    // Nested `try` in expression position: unwrap Ok, propagate Error
                    // out of the surrounding IIFE. (Statement position is lowered in
                    // `buildStmt` to a real enclosing-function `return`.)
                    const n = self.try_seq;
                    self.try_seq += 1;
                    const temp = try self.tryName(n);
                    return self.b.iife(&.{
                        .{ .decl = .{ .pattern = .{ .name = temp }, .value = try self.buildExpr(val.*) } },
                        try self.b.ifStmt(try self.errorIn(temp), .{ .return_ = .{ .name = temp } }),
                        .{ .return_ = try self.b.member(.{ .name = temp }, "ok") },
                    });
                },
                .await_ => |av| return self.b.await_(try self.buildExpr(av.*)),
                // Generator `yield` (loop-accumulator yields are lowered at
                // the `.loop` site, so reaching here means an `#[@iterator]`
                // / `#[@generator]` / `#[@asyncGenerator]` body).
                .yield => |y| return self.b.yield_(if (y.value) |val| try self.buildExpr(val.*) else null),
            },

            .branch => |br| switch (br.kind) {
                .if_ => |i| return self.buildIfExpr(i),
                .tryCatch => |tc| {
                    // `try expr catch handler` in expression position → pattern match
                    // on the `{ ok } | { error }` Result inside an IIFE (never JS
                    // try/catch).
                    const handler = tc.handler.*;
                    const n = self.try_seq;
                    self.try_seq += 1;
                    const temp = try self.tryName(n);
                    // A jump handler is a statement. In this value position a
                    // `return` handler returns from the IIFE, i.e. becomes the
                    // `try`'s value — the statement-position lowering
                    // (`buildTryStmt`) is the one that leaves the function.
                    const handled: js.Stmt = if (isJumpHandler(handler))
                        try self.buildStmt(.{ .expr = handler })
                    else blk: {
                        var value = try self.b.paren(try self.buildExpr(handler));
                        if (handler == .function) {
                            value = try self.b.call(value, &.{try self.b.member(.{ .name = temp }, "error")});
                        }
                        break :blk js.Stmt{ .return_ = value };
                    };
                    return self.b.iife(&.{
                        .{ .decl = .{ .pattern = .{ .name = temp }, .value = try self.buildExpr(tc.expr.*) } },
                        try self.b.ifStmt(try self.errorIn(temp), .{ .block = .{
                            .stmts = try self.b.stmts(&.{handled}),
                            .layout = .spaced,
                        } }),
                        .{ .return_ = try self.b.member(.{ .name = temp }, "ok") },
                    });
                },
            },

            .loop => |lp| return self.buildLoop(lp),

            .binding => |b| switch (b.kind) {
                // A binding is a statement: every block position builds it
                // through `buildStmt`, and it has no value of its own.
                .localBind, .localBindDestruct => return error.BindingInValuePosition,
                .assign => |a| {
                    const op_str: []const u8 = switch (a.op) {
                        .assign => "=",
                        .plusAssign => "+=",
                    };
                    const target: js.Expr = switch (a.target) {
                        .name => |name| .{ .ident = name },
                        .fieldAccess => |*fa| blk: {
                            const isSelf = switch (fa.receiver.*) {
                                .identifier => |recv_id| if (recv_id.kind == .ident)
                                    std.mem.eql(u8, recv_id.kind.ident, "self")
                                else
                                    false,
                                else => false,
                            };
                            break :blk try self.b.member(
                                if (isSelf) js.Expr.this else try self.buildExpr(fa.receiver.*),
                                fa.field,
                            );
                        },
                    };
                    return self.b.assign(target, op_str, try self.buildExpr(a.value.*));
                },
            },

            // A `use` hook used in value position: the underlying hook call.
            .useHook => |uh| return self.buildHookCall(uh.kind.inner.*),

            .call => |c| switch (c.kind) {
                .call => |cc| return self.buildCall(c.loc, cc),
                .pipeline => |p| {
                    // Flatten the pipeline chain.
                    var items: std.ArrayList(ast.Expr) = .empty;
                    defer items.deinit(self.alloc);
                    try items.append(self.alloc, p.lhs.*);
                    var current = p.rhs.*;
                    while (true) {
                        const isPipeline = switch (current) {
                            .call => |c_pipe| c_pipe.kind == .pipeline,
                            else => false,
                        };
                        if (!isPipeline) break;
                        const innerP = current.call.kind.pipeline;
                        try items.append(self.alloc, innerP.lhs.*);
                        current = innerP.rhs.*;
                    }
                    try items.append(self.alloc, current);

                    // Nested calls: last(…(items[1](items[0]))).
                    var acc = try self.buildExpr(items.items[0]);
                    for (items.items[1..]) |step| {
                        acc = try self.b.call(try self.buildExpr(step), &.{acc});
                    }
                    return self.b.paren(acc);
                },
            },

            .function => |f| return self.buildArrow(f.kind.params, f.kind.body),

            .collection => |col| switch (col.kind) {
                .arrayLit => |arr| {
                    const elems = try self.arena().alloc(js.Expr, arr.elems.len);
                    for (arr.elems, 0..) |elem, i| elems[i] = try self.buildExpr(elem);
                    // `[a, b, ..]` — a nameless spread in a literal the parser
                    // accepts contributes no elements: no spread element.
                    const spread: ?js.Spread = if (arr.spread) |sp|
                        (if (sp.len > 0) js.Spread{ .name = sp } else null)
                    else if (arr.spreadExpr) |se|
                        js.Spread{ .expr = try self.b.ptr(try self.buildExpr(se.*)) }
                    else
                        null;
                    return .{ .array = .{ .elems = elems, .spread = spread } };
                },
                .tupleLit => |tuple| {
                    const elems = try self.arena().alloc(js.Expr, tuple.elems.len);
                    for (tuple.elems, 0..) |elem, i| elems[i] = try self.buildExpr(elem);
                    return .{ .array = .{ .elems = elems } };
                },
                .grouped => |expr| return self.b.paren(try self.buildExpr(expr.*)),
                .case => |c| return self.buildCase(c.subjects, c.arms),
                .range => |r| {
                    // `a..b` is the half-open `[a, b)` integer range. JS has no
                    // range literal, so materialize a real array (parity with the
                    // erlang/beam `lists:seq(a, b-1)` and `Array.range`).
                    const end = r.end orelse
                        // An open-ended `a..` is a lazy infinite range (used only
                        // with `break`); a finite JS array can't represent it.
                        return self.b.iife(&.{.{ .throw_ = try self.b.new_(
                            .{ .name = "Error" },
                            &.{.{ .quoted = "open-ended range unsupported on commonJS" }},
                        ) }});
                    const start = try self.b.paren(try self.buildExpr(r.start.*));
                    const length = try self.b.call(try self.b.member(.{ .name = "Math" }, "max"), &.{
                        .{ .number = "0" },
                        try self.b.binaryBare("-", try self.b.paren(try self.buildExpr(end.*)), start),
                    });
                    return self.b.call(try self.b.member(.{ .name = "Array" }, "from"), &.{
                        .{ .object = .{ .props = try self.b.props(&.{.{ .kv = .{ .key = "length", .value = length } }}), .layout = .tight } },
                        try self.b.arrowExpr(
                            &.{ .{ .pattern = .{ .name = "_" } }, .{ .pattern = .{ .name = "__i" } } },
                            try self.b.binaryBare("+", start, .{ .name = "__i" }),
                        ),
                    });
                },
                // Anonymous record literal — a plain JS object (parenthesized
                // so it stays an expression in statement position).
                .recordLit => |rl| return self.b.paren(try self.buildFieldObject(rl.fields)),
                .interfaceLit => |il| return self.b.paren(try self.buildFieldObject(il.fields)),
            },

            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |expr| return self.buildExpr(expr.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| switch (stmt.expr) {
                        .jump => |j| switch (j.kind) {
                            .@"break" => |b| if (b.value) |bp| return self.buildExpr(bp.*),
                            else => {},
                        },
                        else => {},
                    };
                    // No `break` value: a block's value comes only from
                    // `break <e>`, so it is `undefined` (erlang's twin is E5).
                    return .{ .name = "undefined" };
                },
                .assert => |a| {
                    const cond = try self.buildExpr(a.condition.*);
                    if (self.test_mode) {
                        // Throwing helper — the test runner catches per test,
                        // records the failure, and continues.
                        return self.b.call(.{ .name = "__bp_assert" }, &.{
                            cond,
                            if (a.message) |msg| try self.buildExpr(msg.*) else .null_,
                            .{ .quoted = try std.fmt.allocPrint(self.arena(), "{s}.bp:{d}", .{ self.module_name, ct.loc.line }) },
                        });
                    }
                    const callee = try self.b.member(.{ .name = "console" }, "assert");
                    if (a.message) |msg| {
                        return self.b.call(callee, &.{ cond, try self.buildExpr(msg.*) });
                    }
                    return self.b.call(callee, &.{cond});
                },
                .assertPattern => |ap| {
                    const handler_is_statement = switch (ap.handler.*) {
                        .jump => |j| j.kind == .throw_ or j.kind == .@"return",
                        else => false,
                    };
                    const handled: js.Stmt = if (handler_is_statement)
                        try self.buildStmt(.{ .expr = ap.handler.* })
                    else
                        .{ .return_ = try self.buildExpr(ap.handler.*) };
                    return self.b.iife(&.{
                        .{ .decl = .{ .pattern = .{ .name = "_match" }, .value = try self.buildExpr(ap.expr.*) } },
                        try self.b.ifElse(
                            try self.buildPatternCheck(&ap.pattern, "_match"),
                            .{ .block = .{ .stmts = try self.b.stmts(&.{.{ .return_ = .{ .name = "_match" } }}), .layout = .spaced } },
                            .{ .block = .{ .stmts = try self.b.stmts(&.{handled}), .layout = .spaced } },
                        ),
                    });
                },
            },
        }
    }

    fn buildFieldObject(self: *Emitter, fields: anytype) !js.Expr {
        const props = try self.arena().alloc(js.Object.Prop, fields.len);
        for (fields, 0..) |f, i| props[i] = .{ .kv = .{ .key = f.name, .value = try self.buildExpr(f.value.*) } };
        return .{ .object = .{ .props = props } };
    }

    /// An `if` used as a value: the branches are wrapped in an IIFE so the `if`
    /// yields a value. A branch that jumps out of the enclosing function or
    /// loop cannot be lowered here — `buildStmt` lowers such an `if` as a
    /// statement (`buildIfStmt`), and in a value position it is an error.
    fn buildIfExpr(self: *Emitter, i: anytype) anyerror!js.Expr {
        if (self.ifJumps(i)) return error.JumpInValuePosition;
        const prev_ctx = self.loop_ctx;
        const prev_wrap = self.case_ok_wrap;
        self.loop_ctx = .none;
        self.case_ok_wrap = false;
        defer {
            self.loop_ctx = prev_ctx;
            self.case_ok_wrap = prev_wrap;
        }

        var seq: std.ArrayListUnmanaged(js.Stmt) = .empty;
        const cond: js.Expr = if (i.binding) |b| blk: {
            try seq.append(self.arena(), .{ .decl = .{
                .pattern = .{ .name = b },
                .value = try self.buildExpr(i.cond.*),
            } });
            break :blk try self.b.binaryBare("!==", .{ .name = b }, .null_);
        } else try self.buildExpr(i.cond.*);

        const then_block = js.Stmt{ .block = .{
            .stmts = try self.buildBranchBody(i.then_),
            .layout = .spaced,
        } };
        const else_block: ?js.Stmt = if (i.else_) |els| js.Stmt{ .block = .{
            .stmts = try self.buildBranchBody(els),
            .layout = .spaced,
        } } else null;

        try seq.append(self.arena(), if (else_block) |eb|
            try self.b.ifElse(cond, then_block, eb)
        else
            try self.b.ifStmt(cond, then_block));

        return self.b.call(
            try self.b.paren(try self.b.arrowBlock(&.{}, .{ .stmts = try seq.toOwnedSlice(self.arena()), .layout = .spaced })),
            &.{},
        );
    }

    /// An `if` in statement position whose branches jump out: a JS `if`
    /// statement, each branch a plain statement list. The null-check binding
    /// form (`if (val e = …)`) keeps its binding in a block of its own so two
    /// such `if`s in one body do not redeclare it.
    fn buildIfStmt(self: *Emitter, i: anytype) anyerror!js.Stmt {
        const cond: js.Expr = if (i.binding) |b|
            try self.b.binaryBare("!==", .{ .name = b }, .null_)
        else
            try self.buildExpr(i.cond.*);
        const then_block = js.Stmt{ .block = .{ .stmts = try self.buildStmts(i.then_), .layout = .spaced } };
        const if_stmt = if (i.else_) |els|
            try self.b.ifElse(cond, then_block, .{ .block = .{ .stmts = try self.buildStmts(els), .layout = .spaced } })
        else
            try self.b.ifStmt(cond, then_block);
        const b = i.binding orelse return if_stmt;
        return .{ .block = .{
            .stmts = try self.b.stmts(&.{
                .{ .decl = .{ .pattern = .{ .name = b }, .value = try self.buildExpr(i.cond.*) } },
                if_stmt,
            }),
            .layout = .spaced,
        } };
    }

    /// True when a branch of `i` leaves the enclosing function or loop:
    /// `return`, or a `break` / `continue` not bound to a loop inside the
    /// branch — and, inside a comprehension body, an accumulator `yield`.
    fn ifJumps(self: *Emitter, i: anytype) bool {
        const acc = self.loop_ctx == .value;
        if (stmtsJump(i.then_, false, acc)) return true;
        if (i.else_) |els| if (stmtsJump(els, false, acc)) return true;
        return false;
    }

    fn stmtsJump(stmts: []const ast.Stmt, in_loop: bool, acc_yield: bool) bool {
        for (stmts) |st| if (exprJumps(st.expr, in_loop, acc_yield)) return true;
        return false;
    }

    fn exprJumps(e: ast.Expr, in_loop: bool, acc_yield: bool) bool {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => true,
                .@"break", .@"continue" => !in_loop,
                .yield => acc_yield and !in_loop,
                .throw_, .try_, .await_ => false,
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| stmtsJump(i.then_, in_loop, acc_yield) or
                    (if (i.else_) |els| stmtsJump(els, in_loop, acc_yield) else false),
                .tryCatch => false,
            },
            // A nested loop's own `break` / `continue` bind to it; a `return`
            // inside it still leaves the function.
            .loop => |lp| stmtsJump(lp.body, true, acc_yield),
            else => false,
        };
    }

    /// One branch of an `if` expression: every statement but the last as-is, the
    /// last one as the branch's value unless it already transfers control.
    fn buildBranchBody(self: *Emitter, body: []const ast.Stmt) ![]const js.Stmt {
        if (body.len == 0) return &.{};
        const out = try self.arena().alloc(js.Stmt, body.len);
        for (body[0 .. body.len - 1], 0..) |st, i| out[i] = try self.buildStmt(st);
        out[body.len - 1] = try self.buildIfLast(body[body.len - 1]);
        return out;
    }

    /// `loop (xs) { x -> … }` iterates the ITEM; with two params the second is
    /// the index (`{ item, i -> … }`). `Array.entries()` yields numeric
    /// [index, item] pairs, so the destructure order is swapped.
    /// (`Object.entries` gave [stringKey, value], which bound the 1-param
    /// form to the index — a real bug.)
    fn loopHead(self: *Emitter, lp: anytype) !struct { pattern: js.Pattern, iter: js.Expr } {
        const pattern: js.Pattern = if (lp.params.len == 1)
            .{ .ident = lp.params[0] }
        else blk: {
            const elems = try self.arena().alloc(js.Pattern, lp.params.len);
            for (lp.params, 0..) |p, i| elems[lp.params.len - 1 - i] = .{ .ident = p };
            break :blk js.Pattern{ .array = .{ .elems = elems } };
        };
        const iter: js.Expr = if (lp.params.len == 1)
            try self.buildExpr(lp.iter.*)
        else
            try self.b.call(try self.b.member(try self.b.paren(try self.buildExpr(lp.iter.*)), "entries"), &.{});
        return .{ .pattern = pattern, .iter = iter };
    }

    fn hasTopLevelYield(body: []const ast.Stmt) bool {
        for (body) |stmt| switch (stmt.expr) {
            .jump => |j| if (j.kind == .yield) return true,
            else => {},
        };
        return false;
    }

    /// A `loop` in statement position: a JS `for…of`. Its `break` / `continue`
    /// are the native statements, and inside a generator body its `yield` is
    /// the native one — which is what makes `#[@iterator]` recursion work (a
    /// `.map()` would build a throwaway array and yield nothing). Null for an
    /// accumulator `yield` loop outside a generator: that is a comprehension
    /// whose value is discarded, and it keeps the value lowering.
    fn buildLoopStmt(self: *Emitter, lp: anytype) anyerror!?js.Stmt {
        if (!self.in_generator and hasTopLevelYield(lp.body)) return null;
        const head = try self.loopHead(lp);
        const prev_ctx = self.loop_ctx;
        self.loop_ctx = .stmt;
        defer self.loop_ctx = prev_ctx;
        return .{ .for_of = .{
            .pattern = head.pattern,
            .iter = head.iter,
            .body = .{
                .stmts = try self.buildStmts(lp.body),
                .layout = .fixed,
                .indent = self.current_indent,
            },
        } };
    }

    /// `break` in a loop body. In a comprehension, `break <v>` contributes `v`
    /// and moves to the next item (`is_last` drops the redundant `continue`
    /// of the body's final statement); `break;` ends the iteration. In a
    /// statement loop a `break <v>` value is evaluated and discarded.
    fn buildBreakStmt(self: *Emitter, br: anytype, is_last: bool) anyerror!js.Stmt {
        const val = br.value orelse return switch (self.loop_ctx) {
            .none => error.JumpOutsideLoop,
            .stmt, .value => js.Stmt.break_,
        };
        return switch (self.loop_ctx) {
            .none => error.JumpOutsideLoop,
            .value => if (is_last)
                try self.accPush(val.*)
            else
                try self.b.group(&.{ try self.accPush(val.*), .continue_ }),
            .stmt => try self.b.group(&.{ .{ .expr = try self.buildExpr(val.*) }, .continue_ }),
        };
    }

    /// `<acc>.push(<v>);` for the comprehension being built.
    fn accPush(self: *Emitter, val: ast.Expr) anyerror!js.Stmt {
        const acc = switch (self.loop_ctx) {
            .value => |name| name,
            else => return error.JumpOutsideLoop,
        };
        return .{ .expr = try self.b.call(try self.b.member(.{ .name = acc }, "push"), &.{try self.buildExpr(val)}) };
    }

    /// True when a comprehension body needs the accumulating form: a `break`
    /// or `continue` anywhere in it (outside a nested loop), or a `yield`
    /// below the top level.
    fn loopNeedsAccumulator(body: []const ast.Stmt) bool {
        for (body) |st| switch (st.expr) {
            .jump => |j| switch (j.kind) {
                .@"break", .@"continue" => return true,
                else => {},
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| if (stmtsJump(i.then_, false, true) or
                    (if (i.else_) |els| stmtsJump(els, false, true) else false)) return true,
                .tryCatch => {},
            },
            else => {},
        };
        return false;
    }

    /// A `loop` used as a value — a comprehension.
    ///
    /// A body whose only contributions are top-level `yield <v>`s maps the
    /// collection (`xs.map((x) => { …; return v; })`). Any other body —
    /// `break <v>` contributing a value, `continue` dropping an item, a
    /// `yield` under an `if` — is an accumulating IIFE:
    ///
    ///     (() => {
    ///         const _acc = [];
    ///         for (const x of xs) { …; _acc.push(v); }
    ///         return _acc;
    ///     })()
    fn buildLoop(self: *Emitter, lp: anytype) anyerror!js.Expr {
        if (hasTopLevelYield(lp.body) and !loopNeedsAccumulator(lp.body)) {
            const params = try self.arena().alloc(js.Param, lp.params.len);
            for (lp.params, 0..) |p, i| params[i] = .{ .pattern = .{ .ident = p } };
            const prev_ctx = self.loop_ctx;
            const prev_gen = self.in_generator;
            self.loop_ctx = .none;
            self.in_generator = false;
            defer {
                self.loop_ctx = prev_ctx;
                self.in_generator = prev_gen;
            }
            var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
            for (lp.body) |stmt| {
                const is_yield = switch (stmt.expr) {
                    .jump => |j| j.kind == .yield,
                    else => false,
                };
                if (!is_yield) {
                    try body.append(self.arena(), try self.buildStmt(stmt));
                    continue;
                }
                // A valueless `yield` contributes no element.
                const val = stmt.expr.jump.kind.yield.value orelse continue;
                try body.append(self.arena(), .{ .return_ = try self.buildExpr(val.*) });
            }
            return self.b.call(
                try self.b.member(try self.buildExpr(lp.iter.*), "map"),
                &.{try self.b.arrowBlock(params, .{
                    .stmts = try body.toOwnedSlice(self.arena()),
                    .layout = .fixed,
                    .indent = self.current_indent,
                })},
            );
        }

        const head = try self.loopHead(lp);
        const acc = "_acc";
        const base = self.current_indent;
        const prev_ctx = self.loop_ctx;
        const prev_gen = self.in_generator;
        const prev_wrap = self.case_ok_wrap;
        self.loop_ctx = .{ .value = acc };
        self.in_generator = false;
        self.case_ok_wrap = false;
        self.current_indent = base + 2;
        defer {
            self.loop_ctx = prev_ctx;
            self.in_generator = prev_gen;
            self.case_ok_wrap = prev_wrap;
            self.current_indent = base;
        }
        const body = try self.arena().alloc(js.Stmt, lp.body.len);
        for (lp.body, 0..) |st, i| {
            const last = i == lp.body.len - 1;
            body[i] = switch (st.expr) {
                .jump => |j| switch (j.kind) {
                    .@"break" => |br| try self.buildBreakStmt(br, last),
                    .yield => |y| if (y.value) |v| (if (last)
                        try self.accPush(v.*)
                    else
                        try self.buildStmt(st)) else try self.buildStmt(st),
                    else => try self.buildStmt(st),
                },
                else => try self.buildStmt(st),
            };
        }
        return self.b.call(try self.b.paren(try self.b.arrowBlock(&.{}, .{
            .stmts = try self.b.stmts(&.{
                .{ .decl = .{ .pattern = .{ .name = acc }, .value = .{ .array = .{} } } },
                .{ .for_of = .{
                    .pattern = head.pattern,
                    .iter = head.iter,
                    .body = .{ .stmts = body, .indent = base + 1 },
                } },
                .{ .return_ = .{ .name = acc } },
            }),
            .indent = base,
        })), &.{});
    }

    // ── calls ─────────────────────────────────────────────────────────────────

    /// Try lowering an `@builtin(…)` call from its `@external(node, …)`
    /// annotation. Returns null when no annotation is registered.
    fn tryBuiltinAnnotation(self: *Emitter, callee: []const u8, cc: anytype) anyerror!?js.Expr {
        const call = self.builtin_node_dispatch.get(callee) orelse return null;
        return self.renderDispatch(call, cc, error.PrimOpRecvInBuiltinTemplate);
    }

    /// §A2 user-fn template dispatch (commonJS): when a `declare fn`'s
    /// `@external(node, …)` annotation is a template string (with `$0`/`$1`/…
    /// markers) or an arity-branched `when(argc == N): "<tmpl>"` set,
    /// render the template at the call site instead of emitting `fn(args)`
    /// against an aliased symbol (which strips `this` for method-on-global
    /// chains like `process.cwd()`).
    fn tryUserTemplate(self: *Emitter, callee: []const u8, cc: anytype) anyerror!?js.Expr {
        const call = self.user_node_templates.get(callee) orelse return null;
        return self.renderDispatch(call, cc, error.PrimOpRecvInUserTemplate);
    }

    /// Shared body of the two dispatch tables: an arity-branched template, a
    /// single template, or the `module`+`symbol` require form.
    fn renderDispatch(self: *Emitter, call: BuiltinNodeCall, cc: anytype, recv_err: anyerror) anyerror!?js.Expr {
        const argc = cc.args.len + cc.trailing.len;
        if (call.arity_branches.len > 0) {
            for (call.arity_branches) |branch| {
                if (branch.argc != argc) continue;
                return try self.renderTemplate(branch.template, cc, argc, recv_err);
            }
            return null;
        }
        // A 1-arg form without markers (`"process.cwd()"`, module empty) is a
        // bare host expression: it renders verbatim, like a template.
        if (primOpTemplate.looksLikeTemplate(call.symbol) or call.module.len == 0) {
            return try self.renderTemplate(call.symbol, cc, argc, recv_err);
        }
        // module+symbol form: `@External.Node("./mod", "fun")` —
        // `require("<module>").<symbol>(<args>)`. Trailing lambdas are not
        // supported in this form — declare fn helpers use fixed arity.
        if (call.module.len > 0) {
            const args = try self.arena().alloc(js.Expr, cc.args.len);
            for (cc.args, 0..) |arg, i| args[i] = try self.buildExpr(arg.value.*);
            return try self.b.call(
                try self.b.member(try self.requireCall(call.module), call.symbol),
                args,
            );
        }
        return null;
    }

    fn renderTemplate(self: *Emitter, template: []const u8, cc: anytype, argc: usize, recv_err: anyerror) anyerror!js.Expr {
        const Holes = CallHoles(@TypeOf(cc));
        var holes = Holes{ .em = self, .cc = cc, .err = recv_err };
        var tmpl = HostTemplate(Holes){ .arena = self.arena(), .holes = &holes, .argc = argc };
        try primOpTemplate.render(template, &tmpl);
        return tmpl.finish();
    }

    fn buildCall(self: *Emitter, loc: ast.Loc, cc: anytype) anyerror!js.Expr {
        if (cc.is_builtin) return self.buildBuiltinCall(cc);

        // builtin_node_dispatch: `declare fn` with `#[@External.Node]`.
        // Handles both template (`$0.method()`) and module+symbol
        // (`"./mod", "fun"`) forms discovered from primitives.bp +
        // builtins_fns.d.bp.
        if (self.builtin_node_dispatch.contains(cc.callee)) {
            if (try self.tryBuiltinAnnotation(cc.callee, cc)) |node| return node;
            // Fall through to a plain call if annotation dispatch fails.
        }

        var args: std.ArrayListUnmanaged(js.Expr) = .empty;
        var callee: js.Expr = undefined;
        var is_new = false;

        if (cc.receiver) |recv| {
            // Static extension dispatch: lower `recv.m(args)` to
            // `Sym.m(recv, args)` at activated call sites.
            if (self.rewrites.get(loc)) |sym| {
                callee = try self.b.member(.{ .name = sym }, cc.callee);
                try args.append(self.arena(), try self.buildExpr(recv.*));
            } else {
                const recv_node = try self.buildExpr(recv.*);
                // §A4 rename: a 2-arg `@external(node, "X")` on a primitive
                // interface method routes `recv.callee(args)` to
                // `recv.X(args)`. The per-loc `renames` map (populated by
                // inference's type-directed lookup) is consulted FIRST so a
                // collision-prone name (`String.contains` vs `Set.contains`)
                // lands the right rename. The type-naive `prim_node_renames`
                // map (built from annotations at init) is the fallback for
                // calls inference doesn't visit — interface default-fn bodies
                // materialised as prototype patches (`out.append(inner)`
                // inside `flatten`).
                const loc_rename: ?[]const u8 = if (self.renames) |r| r.get(loc) else null;
                const method = loc_rename orelse self.prim_node_renames.get(cc.callee) orelse cc.callee;
                // `arr.len()`/`.size()`/`.length()` & `str.length()`: inference
                // renamed these to `length` only for a typed array/string
                // receiver — the native `.length` is a PROPERTY, so it is a
                // member access with no call parens or args.
                const len_prop = cc.args.len == 0 and cc.trailing.len == 0 and
                    if (loc_rename) |rn| std.mem.eql(u8, rn, "length") else false;
                if (len_prop) return self.b.memberOpt(recv_node, "length", cc.optional);
                callee = try self.b.memberOpt(recv_node, method, cc.optional);
            }
        } else if (self.externals_missing.contains(cc.callee)) {
            // External fn with no `node` target — no symbol to call on this
            // backend.
            return error.MissingExternalTarget;
        } else if (self.user_node_templates.contains(cc.callee)) {
            // §A2 template-form external — render the host shape inline (no
            // `fnname(args)` against an aliased symbol; the alias would strip
            // `this` for chained-method-on-global calls).
            if (try self.tryUserTemplate(cc.callee, cc)) |node| return node;
            // Arity didn't match any `when(argc == N)` branch — fall back to a
            // plain call so the missing branch surfaces as a "fn is not
            // defined" rather than silently emitting nothing.
            callee = .{ .ident = cc.callee };
        } else if (self.class_names.contains(cc.callee)) {
            // Record/struct constructor — JS classes cannot be invoked without
            // `new`.
            callee = .{ .name = cc.callee };
            is_new = true;
        } else {
            callee = .{ .ident = cc.callee };
        }

        for (cc.args) |arg| try args.append(self.arena(), try self.buildExpr(arg.value.*));
        for (cc.trailing) |tl| try args.append(self.arena(), try self.buildArrow(tl.params, tl.body));

        const arg_slice = try args.toOwnedSlice(self.arena());
        return if (is_new) self.b.new_(callee, arg_slice) else self.b.call(callee, arg_slice);
    }

    fn buildBuiltinCall(self: *Emitter, cc: anytype) anyerror!js.Expr {
        // `prim-op-annotation` builtin dispatch fires first (`@todo` /
        // `@panic` annotated in `builtins.d.bp`).
        if (try self.tryBuiltinAnnotation(cc.callee, cc)) |node| return node;

        // Fallback for `@todo` / `@panic` when the annotation dispatch table is
        // empty (builtins.d.bp may stop parsing earlier in the file and the
        // collector silently swallows the parse error). Renders the same host
        // template the annotation would have.
        const is_todo = std.mem.eql(u8, cc.callee, "todo");
        const is_panic = std.mem.eql(u8, cc.callee, "panic");
        if (is_todo or is_panic) {
            const template: []const u8 = if (cc.args.len > 0)
                "(() => { throw new Error($0) })()"
            else if (is_todo)
                "(() => { throw new Error(\"not implemented\") })()"
            else
                "(() => { throw new Error(\"panic\") })()";
            return self.renderTemplate(template, cc, cc.args.len, error.PrimOpRecvInBuiltinTemplate);
        }

        if (std.mem.eql(u8, cc.callee, "block")) {
            // `@block` can be called as `@block(arg)` or `@block { body }`.
            if (cc.args.len == 1) {
                const arg = cc.args[0].value;
                if (arg.* != .function) return error.InvalidArgs;
                return self.buildExpr(arg.*);
            }
            if (cc.trailing.len == 1 and cc.trailing[0].params.len == 0) {
                // `@block { body }` — a trailing lambda with no params.
                return self.b.call(
                    try self.b.paren(try self.b.arrowBlock(&.{}, .{
                        .stmts = try self.buildStmts(cc.trailing[0].body),
                        .layout = .tight,
                    })),
                    &.{},
                );
            }
            return error.InvalidArgs;
        }

        if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
            return self.buildResultOptionOp(cc.callee, cc.args);
        }

        const args = try self.arena().alloc(js.Expr, cc.args.len);
        for (cc.args, 0..) |arg, i| args[i] = try self.buildExpr(arg.value.*);

        // `@expr(value)` / `@code(text)` — comptime template construction
        // builtins; `@compilerError(msg)` — abort compilation from a comptime
        // body. Only reachable when the template/decorator evaluator emits the
        // body (those fns are dropped before normal codegen); its prelude
        // defines `__expr`/`__code`/`__compilerError`.
        if (std.mem.eql(u8, cc.callee, "expr") or std.mem.eql(u8, cc.callee, "code") or
            std.mem.eql(u8, cc.callee, "compilerError") or std.mem.eql(u8, cc.callee, "emit"))
        {
            return self.b.call(.{ .name = try std.fmt.allocPrint(self.arena(), "__{s}", .{cc.callee}) }, args);
        }
        // An unrecognised builtin keeps its `@` so the gap is visible in the
        // output rather than silently disappearing.
        return self.b.call(.{ .name = try std.fmt.allocPrint(self.arena(), "@{s}", .{cc.callee}) }, args);
    }

    // ── case lowering ─────────────────────────────────────────────────────────

    fn isLambdaBlock(e: ast.Expr) bool {
        return switch (e) {
            .function => |f| f.kind.syntax == .lambda,
            else => false,
        };
    }

    /// The statements of a matched arm body: an inlined lambda block (with a
    /// loop-accumulator `break` turned into the arm's `return`), or a single
    /// `return <expr>;`.
    fn buildCaseBody(self: *Emitter, body: ast.Expr, indent: usize) anyerror![]const js.Stmt {
        if (!isLambdaBlock(body)) {
            return self.b.stmts(&.{try self.armReturn(body)});
        }
        const l = body.function.kind;
        self.current_indent = indent;
        var out: std.ArrayListUnmanaged(js.Stmt) = .empty;
        for (l.body) |st| {
            const br: ?ast.Expr = switch (st.expr) {
                .jump => |j| switch (j.kind) {
                    .@"break" => |b| if (b.value) |bp| bp.* else null,
                    else => null,
                },
                else => null,
            };
            if (br) |val| {
                try out.append(self.arena(), try self.armReturn(val));
            } else {
                try out.append(self.arena(), try self.buildStmt(st));
            }
        }
        self.current_indent = indent;
        return out.toOwnedSlice(self.arena());
    }

    /// The test an arm's pattern becomes over the `case` subject `_s`, or null
    /// when the pattern matches anything — the arm then has no `if` at all.
    fn buildCondExpr(self: *Emitter, pat: ast.Pattern) anyerror!?js.Expr {
        return self.patternTest(pat, .{ .name = "_s" });
    }

    /// The test `pat` becomes over `subject`, or null when it matches anything
    /// (`_`, or an alternative that is `_`). A multi-subject pattern
    /// (`case a, b { 0, 0 -> … }`, whose subject is the array `[a, b]`) is the
    /// conjunction of its per-position tests over `_s[i]`; an alternation is
    /// their disjunction. A shape this lowering has no test for is `false`.
    fn patternTest(self: *Emitter, pat: ast.Pattern, subject: js.Expr) anyerror!?js.Expr {
        switch (pat) {
            .wildcard => return null,
            .numberLit => |n| return try self.b.binaryBare("===", subject, .{ .number = n }),
            .stringLit => |s| return try self.b.binaryBare("===", subject, .{ .lexeme_string = s }),
            .ident => |n| return try self.b.binaryBare("===", subject, .{ .quoted = n }),
            .@"or" => |pats| {
                if (pats.len == 0) return js.Expr{ .name = "false" };
                var acc: ?js.Expr = null;
                for (pats) |p| {
                    const t = try self.patternTest(p, subject) orelse return null;
                    acc = if (acc) |a| try self.b.binaryBare("||", a, t) else t;
                }
                return acc;
            },
            .multi => |pats| {
                var acc: ?js.Expr = null;
                for (pats, 0..) |p, i| {
                    const at = try self.b.index(subject, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{i}) }, false);
                    const t = try self.patternTest(p, at) orelse continue;
                    acc = if (acc) |a| try self.b.binaryBare("&&", a, t) else t;
                }
                return acc;
            },
            .variant, .list => return js.Expr{ .name = "false" },
        }
    }

    /// `return <body>;` for a matched arm, gated by the arm's guard when
    /// present: `if (<guard>) return <body>;`.
    fn buildGuardedReturn(self: *Emitter, arm: ast.CaseArm) anyerror!js.Stmt {
        const ret = try self.armReturn(arm.body);
        const g = arm.guard orelse return ret;
        return self.b.ifStmt(try self.buildExpr(g), ret);
    }

    /// A matched arm body — either a `return <expr>;` or an inlined lambda
    /// block — gated by the arm's guard when present.
    fn buildMatchedBody(self: *Emitter, arm: ast.CaseArm, indent: usize) anyerror![]const js.Stmt {
        if (!isLambdaBlock(arm.body)) {
            return self.b.stmts(&.{try self.buildGuardedReturn(arm)});
        }
        const g = arm.guard orelse return self.buildCaseBody(arm.body, indent);
        return self.b.stmts(&.{try self.b.ifStmt(try self.buildExpr(g), .{ .block = .{
            .stmts = try self.buildCaseBody(arm.body, indent + 1),
            .indent = indent,
        } })});
    }

    /// `const _s = <subject>;` then one statement per arm.
    fn buildCaseStmts(self: *Emitter, subjects: []ast.Expr, arms: []ast.CaseArm, indent: usize) anyerror![]const js.Stmt {
        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;
        const subject: js.Expr = if (subjects.len == 1)
            try self.buildExpr(subjects[0])
        else blk: {
            const elems = try self.arena().alloc(js.Expr, subjects.len);
            for (subjects, 0..) |s, i| elems[i] = try self.buildExpr(s);
            break :blk js.Expr{ .array = .{ .elems = elems } };
        };
        try stmts.append(self.arena(), .{ .decl = .{ .pattern = .{ .name = "_s" }, .value = subject } });
        for (arms) |arm| try stmts.append(self.arena(), try self.buildCaseArm(arm, indent));
        return stmts.toOwnedSlice(self.arena());
    }

    /// A `case` used as a value: its arms inside an IIFE, each returning the
    /// arm's value.
    fn buildCase(self: *Emitter, subjects: []ast.Expr, arms: []ast.CaseArm) anyerror!js.Expr {
        const base = self.current_indent;
        const prev_ctx = self.loop_ctx;
        const prev_wrap = self.case_ok_wrap;
        self.loop_ctx = .none;
        self.case_ok_wrap = false;
        defer {
            self.loop_ctx = prev_ctx;
            self.case_ok_wrap = prev_wrap;
        }
        const stmts = try self.buildCaseStmts(subjects, arms, base + 1);
        return self.b.call(
            try self.b.paren(try self.b.arrowBlock(&.{}, .{ .stmts = stmts, .indent = base })),
            &.{},
        );
    }

    /// `return case … { … }` where an arm returns from the function itself
    /// (`Fail -> throw "failed"` in a `#[@result]` fn is `return __bp_error(…)`
    /// after the transform, and the wrap `__bp_ok(case …)` sits around the
    /// whole `case`). That arm cannot return through the IIFE a `case` value
    /// lowers to, so the `case` is lowered as statements in a block: a value
    /// arm returns its value — `({ ok: v })` under the `__bp_ok` wrap — and a
    /// returning arm keeps its own `return`. Null for any other `return`.
    fn buildReturnCaseStmt(self: *Emitter, value: ast.Expr) anyerror!?js.Stmt {
        var inner = value;
        var wrap_ok = false;
        if (value == .call and value.call.kind == .call) {
            const cc = value.call.kind.call;
            if (cc.is_builtin and cc.args.len == 1 and std.mem.eql(u8, cc.callee, "__bp_ok")) {
                inner = cc.args[0].value.*;
                wrap_ok = true;
            }
        }
        if (inner != .collection or inner.collection.kind != .case) return null;
        const c = inner.collection.kind.case;
        var any_returns = false;
        for (c.arms) |arm| {
            if (armReturns(arm.body)) any_returns = true;
        }
        if (!any_returns) return null;

        const base = self.current_indent;
        const prev_wrap = self.case_ok_wrap;
        self.case_ok_wrap = wrap_ok;
        defer self.case_ok_wrap = prev_wrap;
        return .{ .block = .{ .stmts = try self.buildCaseStmts(c.subjects, c.arms, base + 1), .indent = base } };
    }

    /// True when an arm body returns from the enclosing function: a `return`
    /// jump, or a block arm with a `return` statement in it.
    fn armReturns(body: ast.Expr) bool {
        return switch (body) {
            .jump => |j| j.kind == .@"return",
            .function => |f| f.kind.syntax == .lambda and stmtsReturn(f.kind.body),
            else => false,
        };
    }

    fn stmtsReturn(stmts: []const ast.Stmt) bool {
        for (stmts) |st| if (exprJumps(st.expr, true, false)) return true;
        return false;
    }

    /// `return <arm value>;` — or, for an arm body that is itself a `return`,
    /// that `return` (only reachable from `buildReturnCaseStmt`; in an IIFE
    /// `case` it is a value-position jump and an error). Under `case_ok_wrap`
    /// the value is returned as `({ ok: v })`.
    fn armReturn(self: *Emitter, body: ast.Expr) anyerror!js.Stmt {
        if (body == .jump and body.jump.kind == .@"return") {
            if (!self.case_ok_wrap) return error.JumpInValuePosition;
            const prev_wrap = self.case_ok_wrap;
            self.case_ok_wrap = false;
            defer self.case_ok_wrap = prev_wrap;
            return self.buildStmt(.{ .expr = body });
        }
        const wrap = self.case_ok_wrap;
        self.case_ok_wrap = false;
        defer self.case_ok_wrap = wrap;
        const val = try self.buildExpr(body);
        if (!wrap) return .{ .return_ = val };
        return .{ .return_ = try self.b.paren(try self.b.object(&.{.{ .kv = .{ .key = "ok", .value = val } }})) };
    }

    fn buildCaseArm(self: *Emitter, arm: ast.CaseArm, indent: usize) anyerror!js.Stmt {
        const subject = js.Expr{ .name = "_s" };
        switch (arm.pattern) {
            .wildcard => {
                if (arm.guard != null) {
                    return self.b.group(try self.buildMatchedBody(arm, indent));
                }
                if (isLambdaBlock(arm.body)) {
                    return .{ .block = .{ .stmts = try self.buildCaseBody(arm.body, indent + 1), .indent = indent } };
                }
                return try self.armReturn(arm.body);
            },

            .ident, .numberLit, .stringLit, .@"or", .multi => {
                if (arm.pattern == .ident and arm.guard != null) {
                    // A guarded identifier binds the subject, then tests the guard.
                    var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                    try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .ident = arm.pattern.ident },
                        .value = subject,
                    } });
                    for (try self.buildMatchedBody(arm, indent + 1)) |s| try body.append(self.arena(), s);
                    return .{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } };
                }
                const cond = try self.buildCondExpr(arm.pattern);
                if (arm.guard != null) {
                    const body = js.Stmt{ .block = .{
                        .stmts = try self.buildMatchedBody(arm, indent + 1),
                        .indent = indent,
                    } };
                    // A pattern with no test loses its `if` entirely and leaves
                    // a bare block.
                    return if (cond) |c| try self.b.ifStmt(c, body) else body;
                }
                if (isLambdaBlock(arm.body)) {
                    const body = js.Stmt{ .block = .{
                        .stmts = try self.buildCaseBody(arm.body, indent + 1),
                        .indent = indent,
                    } };
                    return if (cond) |c| try self.b.ifStmt(c, body) else body;
                }
                const ret = try self.armReturn(arm.body);
                return if (cond) |c| try self.b.ifStmt(c, ret) else ret;
            },

            .variant => |v| {
                var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                const declared = self.variant_fields.get(v.name);
                // An `Ok`/`Err`/`Error` arm that names no variant this module
                // declares matches a `@Result`, which `#[@result]` materialises
                // as `{ ok }` / `{ error }` — no `tag` (C5). The arm tests the
                // key, as the `try` lowering does, and binds the payload.
                if (declared == null) if (resultKey(v.name)) |key| {
                    switch (v.payload) {
                        .binding => |binding| try body.append(self.arena(), .{ .decl = .{
                            .pattern = .{ .ident = binding },
                            .value = try self.b.member(subject, key),
                        } }),
                        .fields => |fields| if (fields.len > 0) try body.append(self.arena(), .{ .decl = .{
                            .pattern = .{ .ident = fields[0] },
                            .value = try self.b.member(subject, key),
                        } }),
                        .literals => {},
                    }
                    for (try self.buildMatchedBody(arm, indent + 1)) |s| try body.append(self.arena(), s);
                    return self.b.ifStmt(
                        try self.b.binaryBare("in", .{ .quoted = key }, subject),
                        .{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } },
                    );
                };
                switch (v.payload) {
                    .binding => |binding| try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .ident = binding },
                        .value = subject,
                    } }),
                    // `Circle(r)` binds positionally: each binding reads the
                    // declared field at its position (`const { radius: r }`),
                    // never a property named after the binding (C4). A variant
                    // this module does not declare keeps the binding as key.
                    .fields => |fields| if (fields.len > 0) {
                        const props = try self.arena().alloc(js.ObjectPattern.Prop, fields.len);
                        for (fields, 0..) |bb, bi| {
                            const key = if (declared) |d| (if (bi < d.len) d[bi] else bb) else bb;
                            props[bi] = .{ .key = key, .bind = if (std.mem.eql(u8, key, bb)) null else jsIdent(bb) };
                        }
                        try body.append(self.arena(), .{ .decl = .{
                            .pattern = .{ .object = .{ .props = props } },
                            .value = subject,
                        } });
                    },
                    .literals => {},
                }
                for (try self.buildMatchedBody(arm, indent + 1)) |s| try body.append(self.arena(), s);
                return self.b.ifStmt(
                    try self.b.binaryBare("===", try self.b.member(subject, "tag"), .{ .quoted = v.name }),
                    .{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } },
                );
            },

            .list => |lp| {
                const len_of = try self.b.member(subject, "length");
                if (lp.spread) |sp| {
                    if (lp.elems.len == 0 and sp.len == 0) {
                        return try self.armReturn(arm.body);
                    }
                    var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                    if (sp.len > 0) try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .ident = sp },
                        .value = try self.b.call(try self.b.member(subject, "slice"), &.{
                            .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{lp.elems.len}) },
                        }),
                    } });
                    try self.appendListElemBinds(&body, lp.elems, subject);
                    try body.append(self.arena(), try self.armReturn(arm.body));
                    return self.b.ifStmt(
                        try self.b.binaryBare(">=", len_of, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{lp.elems.len}) }),
                        .{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } },
                    );
                }
                if (lp.elems.len == 0) {
                    return self.b.ifStmt(
                        try self.b.binaryBare("===", len_of, .{ .number = "0" }),
                        try self.armReturn(arm.body),
                    );
                }
                var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                try self.appendListElemBinds(&body, lp.elems, subject);
                try body.append(self.arena(), try self.armReturn(arm.body));
                return self.b.ifStmt(
                    try self.b.binaryBare("===", len_of, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{lp.elems.len}) }),
                    .{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } },
                );
            },
        }
    }

    /// The `@Result` key a variant arm name stands for: `Ok` → `ok`,
    /// `Err`/`Error` → `error`.
    fn resultKey(name: []const u8) ?[]const u8 {
        if (std.mem.eql(u8, name, "Ok")) return "ok";
        if (std.mem.eql(u8, name, "Err") or std.mem.eql(u8, name, "Error")) return "error";
        return null;
    }

    fn appendListElemBinds(
        self: *Emitter,
        body: *std.ArrayListUnmanaged(js.Stmt),
        elems: []const ast.ListPatternElem,
        subject: js.Expr,
    ) !void {
        for (elems, 0..) |elem, ei| switch (elem) {
            .bind => |bb| try body.append(self.arena(), .{ .decl = .{
                .pattern = .{ .ident = bb },
                .value = try self.b.index(subject, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{ei}) }, false),
            } }),
            else => {},
        };
    }
};
