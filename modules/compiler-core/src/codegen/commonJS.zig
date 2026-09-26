const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const tsEmit = @import("./typescript.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const crossModule = @import("./crossModule.zig");
const patternFacts = @import("./patterns.zig");
const primOpTemplate = @import("../comptime/primOpTemplate.zig");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const prelude = @import("std_prelude");
const js = @import("./js/js_ast.zig");
const envMod = @import("../comptime/env.zig");
const jsEmitter = @import("./js/js_emitter.zig");
const jsPrelude = @import("./js/js_prelude.zig");

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
            .parseError, .typeError => try results.append(alloc, try ModuleOutput.failedModule(alloc, ct.*)),
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
                // An import this program cannot resolve to one module: the
                // index is keyed by the bare symbol name and two modules
                // export it. Backend-agnostic — every backend reads the same
                // index — so every backend's driver reports it, the way the
                // erlang atom fault is reported.
                if (cross.exportFault(ct.name)) |contest| {
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = .{ .type = .{ .message = try contest.message(alloc), .loc = null } },
                        },
                    });
                    continue;
                }
                // `"std"` package copies are dependencies — never emit their
                // test blocks (a project's `botopink test` runs only its own
                // tests; the stdlib's inline tests run from `libs/std` itself).
                const module_test_mode = config.test_mode and !std.mem.startsWith(u8, ct.name, "std/");
                // 06 C13 — a host-backed fn with no `node` target reaches the
                // driver as a located diagnostic naming the function, not as
                // the bare error name that aborted the whole build.
                var missing: ?moduleOutput.MissingExternal = null;
                const js_src = emitJs(alloc, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &ok.js_method_renames, &ok.instance_lowerings, module_test_mode, ct.name, &cross, &missing) catch |err| {
                    const me = missing orelse return err;
                    try results.append(alloc, .{
                        .name = ct.name,
                        .src = ct.src,
                        .result = .{
                            .js = try alloc.dupe(u8, ""),
                            .comptime_script = null,
                            .diagnostic = try me.diagnostic(alloc),
                        },
                    });
                    continue;
                };

                // Generate TypeScript typedefs if configured.
                const typedef: ?[]u8 = if (config.typeDefLanguage) |_|
                    try emitTypeDef(alloc, ok.bindings, &cross)
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
    /// 06 C13 — set when the emit fails with `error.MissingExternalTarget`.
    missing: ?*?moduleOutput.MissingExternal,
) ![]u8 {
    return try emitProgramOptsX(alloc, program, comptime_vals, rewrites, renames, lowerings, test_mode, module_name, cross, missing);
}

fn emitTypeDef(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
    cross: *const CrossModule,
) ![]u8 {
    return try tsEmit.emitProgram(alloc, bindings, cross);
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

/// True when `e` is the `null` literal — used to choose loose `==`/`!=` for
/// `?T` none comparisons (so `undefined` and `null` both count as none).
pub fn isNullLiteral(e: ast.Expr) bool {
    return e == .literal and e.literal.kind == .null_;
}

/// True when an interface method is an associated function — `default fn` with
/// no `self` receiver (callable as `Interface.method(...)`, not on a value).
pub fn isAssociatedFn(m: ast.BehaviorMethod) bool {
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

/// True when a type reference is the owner marker `@Context<B>` (decision 102).
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

/// True when an `#[@External.Node(module, …)]` module name is a JS global
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
///
/// It reads node's `process` through `globalThis`: a module that imports
/// `std`'s `process` declares a module-level `const process`, which shadowed
/// the global, and `process.argv[2]` threw before any test ran — the file
/// printed no `N passed, M failed` line and its cells vanished from the count.
const test_runner_source =
    \\async function __bp_run_tests() {
    \\    const process = globalThis.process;
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
    missing: ?*?moduleOutput.MissingExternal,
) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(alloc);
    defer arena.deinit();
    var em = Emitter.emitterInit(alloc, arena.allocator(), comptime_vals, rewrites);
    defer em.deinit();
    errdefer if (missing) |slot| {
        slot.* = em.missing_external;
    };
    em.renames = renames;
    em.lowerings = lowerings;
    em.test_mode = test_mode;
    em.module_name = module_name;
    em.cross = cross;
    try em.collectExternals(program);
    try em.collectClassNames(program);
    try em.collectDeclIndexes(program);
    // The dispatch scan first: it parses the embedded std registry and fills
    // `ambiguous_prim_renames`, which the rename collector consults.
    try em.collectBuiltinNodeDispatch();
    try em.collectPrimNodeRenames(program);

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
            .type_ => |tdecl| switch (tdecl.shape) {
                .record => try items.append(arena_alloc, .{ .stmt = try em.buildRecord(tdecl) }),
                .enum_ => try items.append(arena_alloc, .{ .stmt = try em.buildEnum(tdecl) }),
            },
            .behavior => |i| try items.append(arena_alloc, .{ .stmt = try em.buildInterface(i) }),
            .implement => |im| try items.append(arena_alloc, .{ .stmt = try em.buildImplement(im) }),
            .extend => |ex| try items.append(arena_alloc, .{ .stmt = try em.buildExtend(ex) }),
            .use => |u| try items.append(arena_alloc, .{ .stmt = try em.buildUse(u) }),
            .delegate => |d| try items.append(arena_alloc, .{ .stmt = .{ .comment = .{
                .text = try std.fmt.allocPrint(arena_alloc, "delegate {s}", .{d.name}),
            } } }),
            // `mod` declares a submodule in the explicit tree; the submodule is
            // emitted as its own module file, so the declaration emits nothing.
            .mod => {},
            // A type alias is erased: the checker substituted its target.
            .typeAlias => {},
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

    // The prelude helpers the module called, ahead of every declaration (after
    // the test-mode assert helper) — only the ones actually used.
    {
        var at: usize = if (test_mode) 1 else 0;
        for (jsPrelude.order) |hp| {
            if (!em.helpers.contains(hp)) continue;
            try items.insert(arena_alloc, at, .{ .stmt = jsPrelude.decl(hp) });
            at += 1;
        }
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
    /// `yield try x` — the Ok value is the item.
    yield_ok_value,
    /// `yield __bp_ok(try x)` — the Ok Result is the item as it is.
    yield_result,
};

/// True when a return written in source is `@Task<@Result<T, E>>` — a host
/// function whose rejection is `Error(e)` (decision 126).
fn isTaskOfResult(rt: ?ast.TypeRef) bool {
    const t = rt orelse return false;
    if (t != .generic or !t.generic.is_builtin or !std.mem.eql(u8, t.generic.name, "Task")) return false;
    if (t.generic.args.len != 1) return false;
    const inner = t.generic.args[0];
    return inner == .generic and inner.generic.is_builtin and std.mem.eql(u8, inner.generic.name, "Result");
}

/// The operand of a transform-inserted `__bp_ok(<v>)` wrap, or null.
fn okWrapOperand(e: ast.Expr) ?ast.Expr {
    if (e != .call or e.call.kind != .call) return null;
    const c = e.call.kind.call;
    if (!c.is_builtin or c.args.len != 1 or !std.mem.eql(u8, c.callee, "__bp_ok")) return null;
    return c.args[0].value.*;
}

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

/// Holes filled from a call site's argument expressions. The receiver marker has no
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

/// Holes filled from a prototype method's parameters: the receiver marker is the receiver
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
const LoopCtx = enum {
    /// Not inside a loop body (or behind a function boundary).
    none,
    /// Inside a loop body — a JS `for…of` or `while`, or the `while (true)`
    /// of an annotated `loop`'s generator. `break;` / `continue;` are the
    /// native statements. Decision 105: every loop is a statement, so this
    /// is the one context a body is built in; the comprehension and search
    /// contexts of decision 8 §10 are gone with the loop's value.
    stmt,
};

/// Holes filled from a wrapper function's own parameters: `$N` is the Nth
/// declared parameter, or `arguments[N]` past the declared list; the receiver marker has
/// no meaning in a plain function.
const ParamHoles = struct {
    b: js.Builder,
    names: []const []const u8,

    pub fn recvExpr(_: *@This()) anyerror!js.Expr {
        return error.PrimOpRecvInUserTemplate;
    }
    pub fn argExpr(self: *@This(), i: usize) anyerror!js.Expr {
        if (i < self.names.len) return .{ .ident = self.names[i] };
        return self.b.index(.{ .name = "arguments" }, .{ .number = try std.fmt.allocPrint(self.b.arena, "{d}", .{i}) }, false);
    }
};

// ── self tail calls ──────────────────────────────────────────────────────────
//
// V8 has no tail-call elimination, so a botopink function that recurses on
// itself walks the JS stack one frame per step and dies at a few thousand —
// while erlang and beam, whose VMs DO drop the frame, run the same program to
// the end. `std`'s `random.intInRange` is the shape that found it: its
// `floorWalk` helper is one frame per unit of range, so a range of a few
// thousand killed the program on node and nowhere else.
//
// The rewrite is the direct one: a `return f(a, b);` inside `f` gives the
// parameters their next values and goes round again, and the body becomes the
// body of a `while (true)`.
//
//     function f(n, acc) {         function f(n, acc) {
//         if (n === 0)                 while (true) {
//             return acc;                  if ((n === 0)) { return acc; }
//         return f(n - 1,                  { const __bp_tc0 = (n - 1);
//                  acc + n);                 const __bp_tc1 = (acc + n);
//     }                                      n = __bp_tc0; acc = __bp_tc1;
//                                            continue; }
//                                       }
//                                   }
//
// It fires only where it is provably sound; what it refuses still recurses,
// and that list is the language's documented limit (`AGENTS.md` § self tail
// calls, `docs.md` § Recursion).

/// The label a rewritten tail call continues when it sits inside a loop of the
/// function's own — a bare `continue` would target that inner loop.
const tc_label = "__bp_tc";

/// True when a built JS statement list holds an `await` outside any nested
/// function — what an IIFE wrapped around it has to be `async` for (an `await`
/// in a plain arrow does not parse). Nested arrows / functions are their own.
const AwaitScan = struct {
    fn expr(e: js.Expr) bool {
        return switch (e) {
            .await_ => true,
            .member => |m| expr(m.object.*),
            .index => |ix| expr(ix.object.*) or expr(ix.index.*),
            .call, .new_ => |cl| expr(cl.callee.*) or exprs(cl.args),
            .binary => |b| expr(b.lhs.*) or expr(b.rhs.*),
            .unary => |u| expr(u.operand.*),
            .ternary => |t| expr(t.cond.*) or expr(t.then.*) or expr(t.else_.*),
            .assign => |a| expr(a.target.*) or expr(a.value.*),
            .paren => |p| expr(p.*),
            .array => |a| exprs(a.elems),
            .object => |o| blk: {
                for (o.props) |pr| switch (pr) {
                    .kv => |kv| if (expr(kv.value)) break :blk true,
                    else => {},
                };
                break :blk false;
            },
            .yield_ => |y| if (y) |x| expr(x.*) else false,
            else => false,
        };
    }
    fn exprs(xs: []const js.Expr) bool {
        for (xs) |x| if (expr(x)) return true;
        return false;
    }
    fn stmt(st: js.Stmt) bool {
        return switch (st) {
            .expr, .throw_, .yield_delegate => |e| expr(e),
            .decl => |d| expr(d.value),
            .return_ => |e| if (e) |v| expr(v) else false,
            .if_ => |i| expr(i.cond) or stmt(i.then.*) or (if (i.else_) |el| stmt(el.*) else false),
            .for_of => |f| expr(f.iter) or stmts(f.body.stmts),
            .while_ => |wh| expr(wh.cond) or stmts(wh.body.stmts),
            .block => |b| stmts(b.stmts),
            .group => |g| stmts(g),
            .try_catch => |tc| stmts(tc.body.stmts) or stmts(tc.handler.stmts),
            else => false,
        };
    }
    fn stmts(list: []const js.Stmt) bool {
        for (list) |st| if (stmt(st)) return true;
        return false;
    }
};

/// Walks a built JS subtree looking for a reference to one of `names`.
/// `closure_only` counts a hit only when it sits inside a nested function,
/// arrow, class or object method: that is the shape where reassigning a
/// parameter is still observable after the round that owned it is gone.
const NameScan = struct {
    names: []const []const u8,
    closure_only: bool,

    fn hit(s: NameScan, n: []const u8, in_closure: bool) bool {
        if (s.closure_only and !in_closure) return false;
        for (s.names) |x| if (std.mem.eql(u8, x, n)) return true;
        return false;
    }

    fn expr(s: NameScan, e: js.Expr, c: bool) bool {
        return switch (e) {
            .lexeme_string, .quoted, .number, .null_, .this, .comment => false,
            .ident, .name => |n| s.hit(n, c),
            .member => |m| s.expr(m.object.*, c),
            .index => |ix| s.expr(ix.object.*, c) or s.expr(ix.index.*, c),
            .call, .new_ => |cl| s.expr(cl.callee.*, c) or s.exprs(cl.args, c),
            .binary => |b| s.expr(b.lhs.*, c) or s.expr(b.rhs.*, c),
            .unary => |u| s.expr(u.operand.*, c),
            .ternary => |t| s.expr(t.cond.*, c) or s.expr(t.then.*, c) or s.expr(t.else_.*, c),
            .assign => |a| s.expr(a.target.*, c) or s.expr(a.value.*, c),
            .paren => |p| s.expr(p.*, c),
            // A closure's body is the closure zone, whatever `c` was.
            .arrow => |a| switch (a.body) {
                .expr => |x| s.expr(x.*, true),
                .block => |b| s.stmts(b.stmts, true),
            },
            .function => |f| s.stmts(f.body.stmts, true),
            .array => |a| s.exprs(a.elems, c) or (if (a.spread) |sp| switch (sp) {
                .name => |n| s.hit(n, c),
                .expr => |x| s.expr(x.*, c),
            } else false),
            .object => |o| blk: {
                for (o.props) |pr| switch (pr) {
                    .kv => |kv| if (s.expr(kv.value, c)) break :blk true,
                    .shorthand => |n| if (s.hit(n, c)) break :blk true,
                    .method => |m| if (s.stmts(m.body.stmts, true)) break :blk true,
                };
                break :blk false;
            },
            .host => |parts| blk: {
                for (parts) |pt| switch (pt) {
                    .text => {},
                    .expr => |x| if (s.expr(x, c)) break :blk true,
                };
                break :blk false;
            },
            .await_ => |x| s.expr(x.*, c),
            .yield_ => |x| if (x) |v| s.expr(v.*, c) else false,
        };
    }

    fn exprs(s: NameScan, xs: []const js.Expr, c: bool) bool {
        for (xs) |x| if (s.expr(x, c)) return true;
        return false;
    }

    fn stmt(s: NameScan, st: js.Stmt, c: bool) bool {
        return switch (st) {
            .continue_, .continue_label, .break_, .comment => false,
            .expr, .throw_, .yield_delegate => |e| s.expr(e, c),
            .decl => |d| s.expr(d.value, c),
            .return_ => |e| if (e) |v| s.expr(v, c) else false,
            .if_ => |i| s.expr(i.cond, c) or s.stmt(i.then.*, c) or
                (if (i.else_) |el| s.stmt(el.*, c) else false),
            .for_of => |f| s.expr(f.iter, c) or s.stmts(f.body.stmts, c),
            .while_ => |wh| s.expr(wh.cond, c) or s.stmts(wh.body.stmts, c),
            .block => |b| s.stmts(b.stmts, c),
            .function => |f| s.stmts(f.body.stmts, true),
            .class => |cl| blk: {
                if (cl.ctor) |ct| if (s.stmts(ct.body.stmts, true)) break :blk true;
                for (cl.members) |m| if (s.stmts(m.body.stmts, true)) break :blk true;
                break :blk false;
            },
            .group => |g| s.stmts(g, c),
            .try_catch => |tc| s.stmts(tc.body.stmts, c) or s.stmts(tc.handler.stmts, c),
        };
    }

    fn stmts(s: NameScan, list: []const js.Stmt, c: bool) bool {
        for (list) |st| if (s.stmt(st, c)) return true;
        return false;
    }
};

/// Rewrites every `return <self>(args);` of one function into "assign the
/// parameters and go round again". Statement positions only: a `return` inside
/// a nested arrow or function belongs to THAT function, and the walk never
/// descends into one.
const TailRewrite = struct {
    em: *Emitter,
    fn_name: []const u8,
    params: []const []const u8,
    /// At least one tail call was rewritten — otherwise the caller drops the
    /// whole transform and the function keeps its original body.
    fired: bool = false,
    /// A rewritten call sat inside a loop of the function's own, so the outer
    /// `while (true)` needs a label to continue.
    needs_label: bool = false,

    /// The arguments of `v` when it is a call of this very function at the
    /// declared arity — a self tail call. Null for anything else.
    fn selfCallArgs(r: *TailRewrite, v: js.Expr) ?[]const js.Expr {
        const call = switch (v) {
            .call => |c| c,
            else => return null,
        };
        const name = switch (call.callee.*) {
            .ident, .name => |n| n,
            else => return null,
        };
        if (!std.mem.eql(u8, name, r.fn_name)) return null;
        if (call.args.len != r.params.len) return null;
        return call.args;
    }

    /// `{ <temps> <assignments> continue; }` — one round of the loop. An
    /// argument that READS a parameter is staged in a temporary first, because
    /// the assignments happen in order and an earlier one would be visible to
    /// a later argument. An argument that IS its own parameter is a no-op and
    /// is dropped.
    fn step(r: *TailRewrite, args: []const js.Expr, depth: usize) !js.Stmt {
        r.fired = true;
        if (depth > 0) r.needs_label = true;
        const arena = r.em.arena();
        const reads = NameScan{ .names = r.params, .closure_only = false };
        var pre: std.ArrayListUnmanaged(js.Stmt) = .empty;
        var set: std.ArrayListUnmanaged(js.Stmt) = .empty;
        for (args, 0..) |arg, i| {
            const p = r.params[i];
            if (arg == .ident and std.mem.eql(u8, arg.ident, p)) continue;
            var value = arg;
            if (reads.expr(arg, false)) {
                const tmp = try std.fmt.allocPrint(arena, "__bp_tc{d}", .{i});
                try pre.append(arena, .{ .decl = .{ .pattern = .{ .name = tmp }, .value = arg } });
                value = .{ .name = tmp };
            }
            try set.append(arena, .{ .expr = try r.em.b.assign(.{ .ident = p }, "=", value) });
        }
        try pre.appendSlice(arena, set.items);
        try pre.append(arena, if (depth > 0) js.Stmt{ .continue_label = tc_label } else .continue_);
        return .{ .block = .{ .stmts = try pre.toOwnedSlice(arena), .layout = .spaced } };
    }

    fn stmt(r: *TailRewrite, st: js.Stmt, depth: usize) anyerror!js.Stmt {
        return switch (st) {
            .return_ => |maybe| blk: {
                if (maybe) |v| {
                    if (r.selfCallArgs(v)) |args| break :blk try r.step(args, depth);
                }
                break :blk st;
            },
            .if_ => |i| .{ .if_ = .{
                .cond = i.cond,
                .then = try r.em.b.stmtPtr(try r.stmt(i.then.*, depth)),
                .else_ = if (i.else_) |el| try r.em.b.stmtPtr(try r.stmt(el.*, depth)) else null,
            } },
            .block => |b| .{ .block = .{
                .stmts = try r.stmts(b.stmts, depth),
                .layout = b.layout,
                .indent = b.indent,
            } },
            .group => |g| .{ .group = try r.stmts(g, depth) },
            .for_of => |f| .{ .for_of = .{
                .pattern = f.pattern,
                .iter = f.iter,
                .body = .{ .stmts = try r.stmts(f.body.stmts, depth + 1), .layout = f.body.layout, .indent = f.body.indent },
            } },
            .while_ => |wh| .{ .while_ = .{
                .cond = wh.cond,
                .label = wh.label,
                .body = .{ .stmts = try r.stmts(wh.body.stmts, depth + 1), .layout = wh.body.layout, .indent = wh.body.indent },
            } },
            else => st,
        };
    }

    fn stmts(r: *TailRewrite, list: []const js.Stmt, depth: usize) anyerror![]const js.Stmt {
        const out = try r.em.arena().alloc(js.Stmt, list.len);
        for (list, 0..) |st, i| out[i] = try r.stmt(st, depth);
        return out;
    }
};

/// True when the last statement of `list` cannot fall through — it leaves the
/// function (`return`/`throw`) or ends the round (`continue`/`break`). Falling
/// off the end of the rewritten body is then unreachable and no `return;` is
/// needed to stop the `while (true)` going round once more.
fn endsTheRound(list: []const js.Stmt) bool {
    const last = if (list.len == 0) return false else list[list.len - 1];
    return switch (last) {
        .return_, .throw_, .yield_delegate, .continue_, .continue_label, .break_ => true,
        .group => |g| endsTheRound(g),
        .block => |b| endsTheRound(b.stmts),
        else => false,
    };
}

/// True when some statement binds `name` — a local `const`/`let`, a nested
/// function or a class. The recursive call would then be that binding's, not
/// the function's, and the rewrite would be wrong.
fn bindsName(list: []const js.Stmt, name: []const u8) bool {
    for (list) |st| switch (st) {
        .decl => |d| switch (d.pattern) {
            .ident, .name => |n| if (std.mem.eql(u8, n, name)) return true,
            else => {},
        },
        .function => |f| if (std.mem.eql(u8, f.name, name)) return true,
        .class => |c| if (std.mem.eql(u8, c.name, name)) return true,
        .if_ => |i| {
            if (bindsName(&.{i.then.*}, name)) return true;
            if (i.else_) |el| if (bindsName(&.{el.*}, name)) return true;
        },
        .block => |b| if (bindsName(b.stmts, name)) return true,
        .group => |g| if (bindsName(g, name)) return true,
        .for_of => |f| if (bindsName(f.body.stmts, name)) return true,
        .while_ => |wh| if (bindsName(wh.body.stmts, name)) return true,
        else => {},
    };
    return false;
}

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
    /// `_assert<N>` counter — a fresh temporary per `val assert` lowering.
    assert_seq: usize = 0,
    /// 06 C13 — the host-backed fn whose `#[@External.Node(…)]` is missing,
    /// filled at the throw site so `codegenEmit` reports the function and its
    /// call site instead of the bare `MissingExternalTarget`.
    missing_external: ?moduleOutput.MissingExternal = null,
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
    /// inside an `#[@resultGenerator] fn -> @ResultGenerator<T>` means *delegate the rest of
    /// the iteration* to that iterator, so it lowers to `yield* <expr>;
    /// return;` — a plain `return <gen>` would surface the generator object as
    /// the done-value and yield nothing (the iterator-recursion bug behind the
    /// dead `iterator` suite).
    in_generator: bool = false,
    /// True while building a `test { … }` body (decision 74): a `try` whose
    /// operand is an Error there `throw`s the error instead of `return`ing it,
    /// so the runner's `catch` prints the FAIL line. Reset inside every nested
    /// function (a lambda is its own fallible context, or none).
    in_test_body: bool = false,
    /// Set when the body being built lowered an expression-position `try`
    /// through `__bp_try` (`total + try r`); the function-building site then
    /// wraps the body in the guard that turns the thrown Result back into
    /// the propagated one (`guardExprTry`). Saved and restored per function.
    expr_try_used: bool = false,
    /// Host functions of this module declared `-> @Task<@Result<T, E>>`
    /// (decision 126): every call — and a `pub` template's exported wrapper —
    /// goes through `__bp_host_task`, so a rejection becomes `Error(e)`.
    host_task_externals: std.StringHashMap(void) = undefined,
    host_task_externals_init: bool = false,
    /// The innermost `loop` whose body is being built, which is what a
    /// `break` / `continue` / accumulator `yield` binds to. Reset to `.none`
    /// wherever a JS function boundary starts (an arrow, an IIFE), because a
    /// jump cannot cross one.
    loop_ctx: LoopCtx = .none,
    /// The `js/js_prelude.zig` helpers this module calls — marked by `helper`,
    /// which is the only way a call site gets a helper's name.
    helpers: std.EnumSet(jsPrelude.Helper) = .initEmpty(),
    /// Set while the arms of a `return __bp_ok(case …)` are lowered as
    /// statements (`buildReturnCaseStmt`): a value arm then returns
    /// `({ ok: v })`, while an arm that already returns keeps its own value.
    case_ok_wrap: bool = false,
    /// `botopink test` compilation: `assert` lowers to the throwing
    /// `__bp_assert` helper instead of `console.assert`.
    test_mode: bool = false,
    /// Module name, used for `<module>.bp:<line>` source locations in
    /// test-mode assert failures.
    module_name: []const u8 = "main",
    /// `#[@External.Node("module", "symbol")]` fns: name → host import.
    /// The decl lowers to `const { symbol: name } = require("module");`,
    /// or `const name = Module.symbol;` for JS global namespaces (`Math`, …).
    externals: std.StringHashMap(ast.ExternalRef),
    /// `#[@External.<Target>(…)]` fns with no `Node` target — calling one is an error.
    externals_missing: std.StringHashMap(void),
    /// Names that emit as JS classes (record/struct decls, incl. the
    /// `val X = record { … }` shorthand) — constructor calls need `new`.
    class_names: std.StringHashMap(void),
    /// Record name → its declared field names, in declaration order, for every
    /// record this module can construct (its own, and the ones it imports —
    /// `crossModule.ExportInfo.fields` carries the owner's order). The slots a
    /// labelled constructor argument claims (`labelledArgs`).
    record_fields: std.StringHashMap([]const []const u8),
    /// Payload variant name → its declared field names, in declaration order,
    /// for every enum declared in this module. A `case` arm `Circle(r)` binds
    /// positionally, so `r` is read from the declared field (`radius`), never
    /// from a property named after the binding.
    variant_fields: std.StringHashMap([]const []const u8),
    /// Payload variant name → the enum that declares it. `Shape.Rect(width: …)`
    /// may claim `Rect`'s slots by label only through `Shape` itself
    /// (`variantSlotsFor`). `""` when two enums of this module declare the
    /// name: `variant_fields` is keyed by the bare name and keeps one entry, so
    /// a contested name has no slot list that is certainly its own, and it
    /// claims nothing by label (decision 67).
    variant_owner: std.StringHashMap([]const u8),
    /// Every payload-less variant name declared by an enum in this module
    /// (`Nothing`, `X3xl`). It says "this bare name is a variant, not a
    /// binding" — nothing more. The JS class the variant's singleton is an
    /// instance of is deliberately NOT recorded: a variant's identity across
    /// modules is its `tag`, never its class (`patternTest`).
    unit_variant_names: std.StringHashMap(void),
    /// `Enum.Variant` for every variant — payload-less or not — of every enum
    /// this module declares. It says which dotted spellings `x is Enum.Variant`
    /// may test through the enum's class (`isTest`).
    enum_variant_paths: std.StringHashMap(void),
    /// `Enum.method` for every enum method this module declares that takes the
    /// receiver first (`fn area(self: Self)`, `fn check(m: Self)`). Enum values
    /// are plain objects / variant-name strings with no methods of their own,
    /// so `recv.area()` lowers to `Shape.area(recv)` (`enumMethodOwner`).
    enum_recv_methods: std.StringHashMap(void),
    /// Enums this module imports by name (`import {Shape} from "shapes"`):
    /// their methods take the receiver first too, in the owner module.
    imported_enums: std.StringHashMap(void),
    /// `Iface.method` → its `#[@External.Node(…)]` in the std prelude
    /// (`primitives.bp`), for every prelude interface method that carries one.
    /// A module that redeclares a primitive interface (`interface Number { fn
    /// max(self: Self, other: Self) -> Self; … }`) replaces the prelude's
    /// declaration, annotations included; its bodyless members still name the
    /// host methods the prelude binds, so `buildInterface` falls back to these.
    /// Keys and strings live in the node arena.
    prelude_iface_externals: std.StringHashMap(ast.ExternalRef),
    /// Method name → the host symbol an UNTYPED call of it emits on node, over
    /// every behavior of the embedded std registry (`scanDeclareFnExternal`),
    /// and the names two behaviors disagree on. `at` is `String.at` → native
    /// `charAt` and `Array.at` → native `at` (decision 63, amended), so it has
    /// no type-naive rename: `collectPrimNodeRenames` skips `ambiguous_prim_renames`.
    /// Computed over the registry rather than the program because the program
    /// the emitter scans may carry ONE of the two behaviors (a String `default
    /// fn` in use materialises the String behavior alone) and `at → charAt`
    /// then looked unambiguous — `parts.at(0)` on a `string[]` emitted
    /// `parts.charAt(0)` in `libs/std`'s `querystring.bp`.
    prim_symbol_of: std.StringHashMap([]const u8),
    ambiguous_prim_renames: std.StringHashMap(void),
    /// Every interface this module declares, by name. A user interface has no
    /// JS object to patch, so its instance `default fn`s are copied into each
    /// local record that implements it (`buildRecord`).
    local_interfaces: std.StringHashMap(ast.BehaviorDecl),
    /// Top-level fn name → declared return type, for `printShape`.
    fn_return_types: std.StringHashMap(ast.TypeRef),
    /// Local / parameter name → the static print shape of its value, when it
    /// holds a tuple somewhere (`printShape`). Rebinding a name overwrites it.
    print_shapes: std.StringHashMap(js.Expr),
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
    /// driven by the 2-arg `#[@External.Node("X")]` annotation on a primitive
    /// interface method. Consulted at the call site as a fallback when no
    /// per-loc (type-directed) rename was recorded by inference — the latter
    /// path covers interface default-fn bodies, which are lowered from AST
    /// without going through inference. Collisions with a record/struct method
    /// of the same name are excluded (`String.contains`/`Set.contains` →
    /// inference's per-loc rename is the only path; this map omits `contains`).
    prim_node_renames: std.StringHashMap([]const u8),
    /// `prim-op-annotation` builtin dispatch (node): callees from
    /// `builtins.d.bp` with `#[@External.Node(…)]`. Keyed by callee name.
    builtin_node_dispatch: std.StringHashMap(BuiltinNodeCall),
    /// §A2 user-fn per-callee template dispatch (node): a `declare fn`
    /// whose `#[@External.Node("<template>")]` symbol contains `$0`/`$1`/…
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
            .record_fields = std.StringHashMap([]const []const u8).init(alloc),
            .variant_fields = std.StringHashMap([]const []const u8).init(alloc),
            .variant_owner = std.StringHashMap([]const u8).init(alloc),
            .unit_variant_names = std.StringHashMap(void).init(alloc),
            .enum_variant_paths = std.StringHashMap(void).init(alloc),
            .enum_recv_methods = std.StringHashMap(void).init(alloc),
            .imported_enums = std.StringHashMap(void).init(alloc),
            .prelude_iface_externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .prim_symbol_of = std.StringHashMap([]const u8).init(alloc),
            .ambiguous_prim_renames = std.StringHashMap(void).init(alloc),
            .local_interfaces = std.StringHashMap(ast.BehaviorDecl).init(alloc),
            .fn_return_types = std.StringHashMap(ast.TypeRef).init(alloc),
            .print_shapes = std.StringHashMap(js.Expr).init(alloc),
            .seen_imports = std.StringHashMap(void).init(alloc),
            .prim_node_renames = std.StringHashMap([]const u8).init(alloc),
            .builtin_node_dispatch = std.StringHashMap(BuiltinNodeCall).init(alloc),
            .user_node_templates = std.StringHashMap(BuiltinNodeCall).init(alloc),
        };
        // §A4 default prim renames: the three host-name → native-prototype pairs
        // primitives.bp annotates with the 2-arg shorthand. Seeding them here
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
        self.externals.deinit();
        self.externals_missing.deinit();
        self.class_names.deinit();
        self.record_fields.deinit();
        self.variant_fields.deinit();
        self.variant_owner.deinit();
        self.unit_variant_names.deinit();
        self.enum_variant_paths.deinit();
        self.enum_recv_methods.deinit();
        self.imported_enums.deinit();
        self.prelude_iface_externals.deinit();
        self.prim_symbol_of.deinit();
        self.ambiguous_prim_renames.deinit();
        self.local_interfaces.deinit();
        self.fn_return_types.deinit();
        self.print_shapes.deinit();
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

    /// A prelude helper's name, marking it for emission in this module.
    fn helper(self: *Emitter, h: jsPrelude.Helper) js.Expr {
        self.helpers.insert(h);
        return .{ .name = jsPrelude.name(h) };
    }

    // ── collectors ────────────────────────────────────────────────────────────

    /// `prim-op-annotation` commonJS builtin dispatch collector — mirrors
    /// erlang's; scans `prelude.builtins` for top-level fn decls with
    /// `#[@External.Node(…)]` and indexes by callee name.
    ///
    /// The arity-branched entries (`panic`/`todo`, and `print`/`println`/
    /// `debug`) are registered inline first; the scan of the embedded prelude
    /// then adds the rest and skips a name already registered. The prelude
    /// parses (front 20) — a failure there stops the compiler, it is not
    /// skipped (decision 67).
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
        // The embedded prelude (`builtins.d.bp`, `primitives.bp`) parses — a
        // test in `codegen/tests/builtins.zig` pins it — so a failure here
        // is a broken compiler, not a best-effort miss: it stops loudly instead
        // of silently dropping every `#[External.*]` the file declares
        // (decision 67).
        var lx = lexerMod.Lexer.init(src);
        const tokens = lx.scanAll(alloc_arena) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            else => std.debug.panic("embedded std prelude does not lex: {s}", .{@errorName(err)}),
        };
        var p = parserMod.Parser.initWithSource(tokens, src);
        var program = p.parse(alloc_arena) catch |err| switch (err) {
            error.OutOfMemory => return error.OutOfMemory,
            error.UnexpectedToken => {
                const pe = p.parseError;
                std.debug.panic("embedded std prelude does not parse at {d}:{d}", .{
                    if (pe) |e| e.line else 0,
                    if (pe) |e| e.col else 0,
                });
            },
        };
        defer program.deinit(alloc_arena);
        for (program.decls) |decl| {
            if (decl == .behavior) {
                const iface = decl.behavior;
                for (iface.methods) |m| {
                    if (std.mem.eql(u8, target, "node")) try self.noteUntypedNodeSymbol(m);
                    const ref = m.externalFor(target) orelse continue;
                    const key = try std.fmt.allocPrint(self.arena(), "{s}.{s}", .{ iface.name, m.name });
                    if (self.prelude_iface_externals.contains(key)) continue;
                    try self.prelude_iface_externals.put(key, .{
                        .module = try self.arena().dupe(u8, ref.module),
                        .symbol = try self.arena().dupe(u8, ref.symbol),
                    });
                }
                continue;
            }
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

    /// Hand-rolls the `panic` / `todo` dispatch entries. Mirrors the
    /// `#[@External.Node(when(argc == N))]` annotation literally — kept here
    /// because `panic`/`todo` live in `builtins_fns.d.bp`, which the prelude
    /// scan does not read, and the dispatch needs these two callees registered
    /// to lower `@panic(…)` / `@todo(…)`.
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
    /// `#[@External.Node("X")]` annotation whose symbol `X` differs from the
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
            .type_ => |r| if (r.isRecord()) for (r.methods) |m| try record_methods.put(m.name, {}),
            else => {},
        };
        // A name two primitive behaviors send to DIFFERENT host symbols has no
        // type-naive rename: `String.at` is native `charAt` while `Array.at` is
        // native `at` (decision 63's amendment gave both readers one name), and
        // whichever won here rewrote the other receiver's default-fn bodies —
        // `Array.first`'s `self.at(0)` was emitted `this.charAt(0)` on an array,
        // `TypeError: this.charAt is not a function` on node. Such a call keeps
        // its own name unless inference's per-loc rename typed the receiver.
        // The disagreement is read off the whole embedded std registry
        // (`ambiguous_prim_renames`, filled by `collectBuiltinNodeDispatch`)
        // AND this program's own behaviors: the program may carry one of the
        // two (see the field).
        for (program.decls) |decl| {
            if (decl != .behavior) continue;
            for (decl.behavior.methods) |m| try self.noteUntypedNodeSymbol(m);
        }
        for (program.decls) |decl| {
            if (decl != .behavior) continue;
            for (decl.behavior.methods) |m| {
                const ref = m.externalFor("node") orelse continue;
                if (ref.module.len != 0) continue;
                if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) continue;
                if (std.mem.eql(u8, ref.symbol, m.name)) continue;
                if (record_methods.contains(m.name)) continue;
                if (self.ambiguous_prim_renames.contains(m.name)) continue;
                try self.prim_node_renames.put(m.name, ref.symbol);
            }
        }
    }

    /// Indexes every `#[@External.<Target>(…)]` fn by name: with a `Node` target it
    /// goes to `externals` (alias form: `const fn = require(…);`) or
    /// `user_node_templates` (§A2 template form: `$0`/`$1`/… or
    /// `when(argc == N)` branches — rendered at each call site instead of
    /// aliased); without a node target it goes to `externals_missing` (so a
    /// call can fail with a clear error instead of an undefined identifier).
    fn collectExternals(self: *Emitter, program: ast.Program) !void {
        if (!self.host_task_externals_init) {
            self.host_task_externals = std.StringHashMap(void).init(self.arena());
            self.host_task_externals_init = true;
        }
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                if (isTaskOfResult(f.returnType)) try self.host_task_externals.put(f.name, {});
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
            .type_ => |r| if (r.isRecord()) {
                try self.class_names.put(r.name, {});
                const names = try self.arena().alloc([]const u8, r.recordFields().len);
                for (r.recordFields(), 0..) |f, i| names[i] = f.name;
                try self.record_fields.put(r.name, names);
            },
            // An imported record is a class in its own module — a
            // construction here (`App(8080, "/")`) still needs `new`.
            .use => |u| if (self.cross) |xc| {
                for (u.imports) |imp| {
                    // `picked`, not a name-keyed `get`: the import's own
                    // `from "<mod>"` says which module's record this is, so
                    // the slot names a labelled constructor claims come from
                    // the declaration the import names and never from
                    // whichever module the walk reached last.
                    if (xc.picked(imp.name(), u.source, null)) |info| {
                        if (info.is_class) {
                            try self.class_names.put(imp.name(), {});
                            if (info.fields.len > 0) try self.record_fields.put(imp.name(), info.fields);
                        }
                    }
                }
            },
            else => {},
        };
    }

    /// Indexes each fn's declared return type (`fn_return_types`) and each
    /// payload variant's declared field names (`variant_fields`). Enum
    /// sections are desugared into inner enums before codegen, so the
    /// top-level variant list is the whole surface.
    fn collectDeclIndexes(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (f.returnType) |rt| try self.fn_return_types.put(f.name, rt);
            },
            .type_ => |e| if (!e.isRecord()) {
                for (e.variants()) |v| {
                    try self.enum_variant_paths.put(try std.fmt.allocPrint(self.arena(), "{s}.{s}", .{ e.name, v.name }), {});
                    if (v.fields.len == 0) {
                        // The name alone, so that `patternTest` can tell a
                        // variant from a binding. Two enums in one module may
                        // share a bare variant name (emilia's
                        // `Token.Text.Bold` and `Token.Font.Weight.Bold`) and
                        // that changes nothing here: the arm's test is the
                        // `tag` either way.
                        try self.unit_variant_names.put(v.name, {});
                        continue;
                    }
                    const names = try self.arena().alloc([]const u8, v.fields.len);
                    for (v.fields, 0..) |f, i| names[i] = f.name;
                    try self.variant_fields.put(v.name, names);
                    // A second enum of this module declaring the same variant
                    // name contests it — neither owns it for the purpose of a
                    // labelled payload.
                    const owner = try self.variant_owner.getOrPut(v.name);
                    if (owner.found_existing) {
                        if (!std.mem.eql(u8, owner.value_ptr.*, e.name)) owner.value_ptr.* = "";
                    } else owner.value_ptr.* = e.name;
                }
                for (e.methods) |m| {
                    if (m.is_declare or !enumMethodTakesReceiver(m)) continue;
                    try self.enum_recv_methods.put(try std.fmt.allocPrint(self.arena(), "{s}.{s}", .{ e.name, m.name }), {});
                }
            },
            .behavior => |i| try self.local_interfaces.put(i.name, i),
            .use => |u| if (self.cross) |xc| {
                for (u.imports) |imp| {
                    const info = xc.picked(imp.name(), u.source, null) orelse continue;
                    if (info.kind == .@"enum") try self.imported_enums.put(imp.name(), {});
                }
            },
            else => {},
        };
    }

    /// An enum method takes the receiver as its first parameter when that
    /// parameter is `self` or is typed `Self`; any other method is an
    /// associated fn called on the enum object itself.
    fn enumMethodTakesReceiver(m: ast.BehaviorMethod) bool {
        if (m.params.len == 0) return false;
        const first = m.params[0];
        if (std.mem.eql(u8, first.name, "self")) return true;
        return first.typeRef == .named and std.mem.eql(u8, first.typeRef.named, "Self");
    }

    /// The enum whose method `recv.<method>(…)` calls, when inference typed the
    /// receiver as an enum value this module declares or imports by name. The
    /// call then passes the receiver first: `Shape.area(recv)`.
    fn enumMethodOwner(self: *Emitter, loc: ast.Loc, method: []const u8) !?[]const u8 {
        const lw = self.lowerings orelse return null;
        const type_name = switch (lw.get(loc) orelse return null) {
            .type_ => |n| n,
            .prim, .field_of, .sequence_next => return null,
        };
        if (self.imported_enums.contains(type_name)) return type_name;
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ type_name, method }) catch return null;
        return if (self.enum_recv_methods.contains(key)) type_name else null;
    }

    /// `exports.<name> = <name>;` for a `pub` record or enum. Always emitted,
    /// like a `pub fn`'s: the module's `.d.ts` declares the class / enum as
    /// exported, and a consumer reaching it through the module object
    /// (`order.Order.Lt` after `import {order} from "std"`) finds nothing
    /// otherwise.
    fn pubExport(self: *Emitter, name: []const u8) !js.Stmt {
        return .{ .expr = try self.b.assign(
            try self.b.member(.{ .name = "exports" }, name),
            "=",
            .{ .name = name },
        ) };
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

    /// Tuple positional member (`_0`, `_1`, … or the bare `0`, `1`, …) → the
    /// digits, else null. Distinguishes tuple index access from `_`-prefixed
    /// record fields (`_balance`) by requiring every char after `_` to be a
    /// digit. `pair.0` used to be emitted verbatim, which is a JS SyntaxError.
    fn tupleIndexMember(member: []const u8) ?[]const u8 {
        const digits = if (member.len > 0 and member[0] == '_') member[1..] else member;
        if (digits.len == 0) return null;
        for (digits) |ch| {
            if (!std.ascii.isDigit(ch)) return null;
        }
        return digits;
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

    /// A module-level binding: `const` for a `val`, `let` for a `var` — the
    /// same choice `buildStmt` makes for a local from `localBind.mutable`
    /// (front 17 step 2). Node throws `Assignment to constant variable` on a
    /// `const`, which is what made decision 38 a compile-time rule.
    fn buildValDecl(self: *Emitter, v: ast.ValDecl) !js.Stmt {
        return .{ .decl = .{
            .kw = if (v.mutable) .let_ else .const_,
            .pattern = .{ .ident = v.name },
            .value = try self.buildExpr(v.value.*),
        } };
    }

    /// The two JS modifiers a botopink effect asks of the function that
    /// carries it. A `function` declaration spells them as one keyword
    /// (`async function*`); a class member spells the same two without the
    /// `function` word (`static async *name`), so both read this one table.
    const FnShape = struct {
        is_async: bool = false,
        is_generator: bool = false,

        /// `function`, `async function`, `function*` or `async function*`.
        fn keyword(self: FnShape) []const u8 {
            if (self.is_async) return if (self.is_generator) "async function*" else "async function";
            return if (self.is_generator) "function*" else "function";
        }
    };

    /// The JS shape a botopink effect asks for — read off the return
    /// (decision 118):
    ///   `-> @Task<T>`          → `async function` (decision 120)
    ///   `-> @Component<C, T>`  → `async function`, awaiting or not (decision
    ///                            104: every hook and component answers a
    ///                            Promise and every caller `await`s it)
    ///   `-> @Iterator<T>`      → `function*` (a body that yields; decision 123)
    ///   `-> @Stream<T>`        → `async function*`
    ///   `-> @Result<T, E>`     → `function` (the checked-Result value)
    ///   none (and a factory)   → `function`
    fn effectShape(eff: ?ast.EffectKind) FnShape {
        const e = eff orelse return .{};
        return switch (e) {
            .task => .{ .is_async = true },
            .component => .{ .is_async = true },
            .iterator => .{ .is_generator = true },
            .stream => .{ .is_async = true, .is_generator = true },
            .result => .{},
        };
    }

    /// The effect a METHOD's return activates (decision 118). `ast.FnDecl`
    /// carries a parsed `effect` field; `ast.BehaviorMethod` — a record's or
    /// an enum's method, and a `behavior`'s `default fn` — does not, so the
    /// effect is read off its return type and body here, as the parser reads
    /// a fn's.
    fn methodEffect(m: ast.BehaviorMethod) ?ast.EffectKind {
        return ast.EffectKind.ofMethod(m.returnType, m.body);
    }

    /// A top-level `fn` decl: an external alias/template breadcrumb, or a real
    /// function plus its `exports.<name>` line.
    fn buildFnItem(self: *Emitter, f: ast.FnDecl) !js.Stmt {
        if (!f.isExternal()) return self.buildFn(f);
        // §A2 template-form external: no decl alias — the template renders
        // inline at every call site in this module (see `tryUserTemplate`).
        // Emit a one-line doc breadcrumb so the emitted file stays
        // self-documenting. A `pub` one is also a real exported function, so
        // another module reaching it through the module object
        // (`env.write(…)` after `import {env} from "std"`) finds it.
        if (self.user_node_templates.get(f.name)) |call| {
            const note = js.Stmt{ .comment = .{
                .text = try std.fmt.allocPrint(self.arena(), "{s}: per-call template (see annotation)", .{f.name}),
            } };
            if (!f.isPub) return note;
            const wrapper = try self.buildTemplateWrapper(f, call) orelse return note;
            return self.b.group(&.{ note, wrapper, .{ .expr = try self.b.assign(
                try self.b.member(.{ .name = "exports" }, f.name),
                "=",
                .{ .ident = f.name },
            ) } });
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

    /// `function name(params) { return <template>; }` for a `pub` template
    /// external: the template's `$N` holes are the declared parameters. An
    /// arity-branched template tests `arguments.length` per branch. Null when
    /// the template names a receiver (its `self` parameter), which a plain function has not.
    fn buildTemplateWrapper(self: *Emitter, f: ast.FnDecl, call: BuiltinNodeCall) !?js.Stmt {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        var params: std.ArrayListUnmanaged(js.Param) = .empty;
        for (f.params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            try names.append(self.arena(), p.name);
            try params.append(self.arena(), .{ .pattern = .{ .ident = p.name } });
        }
        var holes = ParamHoles{ .b = self.b, .names = names.items };
        var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
        if (call.arity_branches.len > 0) {
            for (call.arity_branches) |branch| {
                const value = try self.renderParamTemplate(branch.template, &holes, branch.argc) orelse return null;
                try body.append(self.arena(), try self.b.ifStmt(
                    try self.b.binaryBare("===", try self.b.member(.{ .name = "arguments" }, "length"), .{
                        .number = try std.fmt.allocPrint(self.arena(), "{d}", .{branch.argc}),
                    }),
                    .{ .return_ = value },
                ));
            }
        } else {
            const value = try self.renderParamTemplate(call.symbol, &holes, names.items.len) orelse return null;
            // Decision 126 — the exported face of a `-> @Task<@Result<…>>` host fn.
            const wrapped = if (isTaskOfResult(f.returnType)) try self.b.call(self.helper(.host_task), &.{value}) else value;
            try body.append(self.arena(), .{ .return_ = wrapped });
        }
        return .{ .function = .{
            .name = f.name,
            .params = params.items,
            .body = .{ .stmts = try body.toOwnedSlice(self.arena()), .layout = .spaced },
        } };
    }

    fn renderParamTemplate(self: *Emitter, template: []const u8, holes: *ParamHoles, argc: usize) !?js.Expr {
        var tmpl = HostTemplate(ParamHoles){ .arena = self.arena(), .holes = holes, .argc = argc };
        primOpTemplate.render(template, &tmpl) catch |err| switch (err) {
            error.PrimOpRecvInUserTemplate => return null,
            else => return err,
        };
        return try tmpl.finish();
    }

    fn requireCall(self: *Emitter, path: []const u8) !js.Expr {
        return self.b.call(.{ .name = "require" }, &.{.{ .quoted = path }});
    }

    /// The parameter names of `params` when every one is a plain binding.
    /// Null when one destructures or carries a default: the rewrite has to
    /// ASSIGN each parameter, and neither shape has a name to assign to.
    fn plainParamNames(self: *Emitter, params: []const js.Param) !?[][]const u8 {
        const out = try self.arena().alloc([]const u8, params.len);
        for (params, 0..) |p, i| {
            if (p.default != null) return null;
            out[i] = switch (p.pattern) {
                .ident, .name => |n| n,
                else => return null,
            };
        }
        return out;
    }

    /// `body` rewritten as `while (true) { … }` with every self tail call
    /// turned into a round of the loop — or null when nothing fires or the
    /// shape is not provably safe, and the function keeps its recursion.
    /// The refusals ARE the documented limit (`AGENTS.md` § self tail calls).
    fn selfTailLoop(self: *Emitter, name: []const u8, params: []const js.Param, body: []const js.Stmt) !?[]const js.Stmt {
        const names = try self.plainParamNames(params) orelse return null;
        // A sloppy-mode function maps `arguments` onto its parameters, so
        // reassigning one is visible through it.
        if ((NameScan{ .names = &.{"arguments"}, .closure_only = false }).stmts(body, false)) return null;
        // A closure that reads a parameter outlives the round that made it;
        // after the rewrite it would read the NEXT round's value.
        if ((NameScan{ .names = names, .closure_only = true }).stmts(body, false)) return null;
        // A local of the function's own name: the call is that binding's.
        if (bindsName(body, name)) return null;

        var r = TailRewrite{ .em = self, .fn_name = name, .params = names };
        const rewritten = try r.stmts(body, 0);
        if (!r.fired) return null;

        var loop_body: std.ArrayListUnmanaged(js.Stmt) = .empty;
        try loop_body.appendSlice(self.arena(), rewritten);
        // Falling off the end of a function body ends the FUNCTION; inside the
        // loop it would start another round, so it becomes an explicit
        // `return;` — the same `undefined` the fall-through answered.
        if (!endsTheRound(rewritten)) try loop_body.append(self.arena(), .{ .return_ = null });

        return try self.b.stmts(&.{.{ .while_ = .{
            .cond = .{ .name = "true" },
            .label = if (r.needs_label) tc_label else null,
            .body = .{ .stmts = try loop_body.toOwnedSlice(self.arena()), .layout = .indented, .indent = 1 },
        } }});
    }

    /// The guard an expression-position `try` needs (`__bp_try` throws the
    /// Error Result): `try { body } catch (__e) { if (<__e is one>) { … } throw
    /// __e; }` — `return __e.__bp_try` in a function, `yield …; return;` in a
    /// generator (decision 122: the error is the last item), the FAIL throw in
    /// a `test` body (decision 74). A body that used no expression `try` is
    /// returned as it is.
    fn guardExprTry(self: *Emitter, body: []const js.Stmt, indent: usize) ![]const js.Stmt {
        if (!self.expr_try_used) return body;
        const e: js.Expr = .{ .name = "__e" };
        const payload = try self.b.member(e, "__bp_try");
        const is_try = try self.b.binaryBare("&&", try self.b.binaryBare("&&", try self.b.binaryBare("!==", e, .null_), try self.b.binaryBare("===", try self.b.unary("typeof ", e, false), .{ .quoted = "object" })), try self.b.binaryBare("in", .{ .quoted = "__bp_try" }, e));
        const on_error: []const js.Stmt = if (self.in_test_body) blk: {
            const err_val = try self.b.member(payload, "error");
            const is_string = try self.b.binaryBare("===", try self.b.unary("typeof ", err_val, false), .{ .quoted = "string" });
            const rendered = try self.b.call(try self.b.member(.{ .name = "JSON" }, "stringify"), &.{err_val});
            break :blk try self.b.stmts(&.{.{ .throw_ = try self.b.new_(.{ .name = "Error" }, &.{try self.b.ternary(is_string, err_val, rendered)}) }});
        } else if (self.in_generator)
            try self.b.stmts(&.{ .{ .expr = try self.b.yield_(payload) }, .{ .return_ = null } })
        else
            try self.b.stmts(&.{.{ .return_ = payload }});
        return self.b.stmts(&.{.{ .try_catch = .{
            .body = .{ .stmts = body, .indent = indent },
            .param = "__e",
            .handler = .{ .stmts = try self.b.stmts(&.{
                try self.b.ifStmt(is_try, .{ .block = .{ .stmts = on_error, .layout = .spaced } }),
                .{ .throw_ = e },
            }), .indent = indent },
        } }});
    }

    fn buildFn(self: *Emitter, f: ast.FnDecl) anyerror!js.Stmt {
        self.try_seq = 0;
        const shape = effectShape(f.effect);
        const prev_in_generator = self.in_generator;
        self.in_generator = shape.is_generator;
        defer self.in_generator = prev_in_generator;
        const prev_expr_try = self.expr_try_used;
        self.expr_try_used = false;
        defer self.expr_try_used = prev_expr_try;
        const params = try self.buildParams(f.params);
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        var body = try self.buildStmts(f.body);
        body = @constCast(try self.guardExprTry(body, 1));
        self.current_indent = prev_fn_indent;
        const kw = shape.keyword();
        // A plain `function` only: a generator's `return f(…)` resumes an
        // iterator rather than ending one, and an `async` one's answer is a
        // promise the caller of the round would have to await.
        if (!shape.is_async and !shape.is_generator) {
            if (try self.selfTailLoop(f.name, params, body)) |looped| body = looped;
        }
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
        // Decision 74 — the test body is a fallible context whose failure
        // channel is the runner, not a returned Result.
        const prev_in_test = self.in_test_body;
        self.in_test_body = true;
        defer self.in_test_body = prev_in_test;
        const prev_expr_try = self.expr_try_used;
        self.expr_try_used = false;
        defer self.expr_try_used = prev_expr_try;
        const body = try self.guardExprTry(try self.buildStmts(t.body), 1);
        self.current_indent = prev_fn_indent;
        return .{ .function = .{
            .keyword = "async function",
            .name = try std.fmt.allocPrint(self.arena(), "__bp_test_{d}", .{idx}),
            .body = .{ .stmts = body },
        } };
    }

    fn buildRecord(self: *Emitter, r: ast.TypeDecl) !js.Stmt {
        var ctor: ?js.Class.Ctor = null;
        if (r.recordFields().len > 0) {
            const params = try self.arena().alloc(js.Param, r.recordFields().len);
            const assigns = try self.arena().alloc(js.Stmt, r.recordFields().len);
            for (r.recordFields(), 0..) |f, i| {
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
            const eff = methodEffect(m);
            const shape = effectShape(eff);
            const prev_in_generator = self.in_generator;
            self.in_generator = shape.is_generator;
            self.current_indent = 2;
            const prev_expr_try = self.expr_try_used;
            self.expr_try_used = false;
            const body = try self.guardExprTry(try self.buildStmts(m.body orelse &.{}), 2);
            self.expr_try_used = prev_expr_try;
            self.current_indent = 0;
            self.in_generator = prev_in_generator;
            try members.append(self.arena(), .{
                .kind = if (has_self) .method else .static_method,
                .name = m.name,
                .params = params,
                .body = .{ .stmts = body, .indent = 1 },
                .is_async = shape.is_async,
                .is_generator = shape.is_generator,
            });
        }
        for (r.implement) |im| switch (im) {
            .named => |n| try self.appendInterfaceDefaults(&members, n, 0),
            .generic => |g| try self.appendInterfaceDefaults(&members, g.name, 0),
            else => {},
        };
        const class = js.Stmt{ .class = .{
            .name = r.name,
            .ctor = ctor,
            .members = try members.toOwnedSlice(self.arena()),
        } };
        const marker = try self.protoName(r.name, r.name);
        if (!r.isPub) return self.b.group(&.{ class, marker });
        return self.b.group(&.{ class, marker, try self.pubExport(r.name) });
    }

    /// The instance `default fn`s of a local interface (and the interfaces it
    /// extends) that the record does not define itself, as class methods: a
    /// user interface is not a JS constructor, so `Iface.prototype.m = …`
    /// threw `Iface is not defined` when the module loaded. Inside the body
    /// `self` is `this`, so `self.max(lo).min(hi)` reaches the record's own
    /// methods.
    fn appendInterfaceDefaults(
        self: *Emitter,
        members: *std.ArrayListUnmanaged(js.Class.ClassMember),
        iface_name: []const u8,
        depth: usize,
    ) anyerror!void {
        if (depth > 16) return;
        const iface = self.local_interfaces.get(iface_name) orelse return;
        const prev_self_param = self.self_is_param;
        defer self.self_is_param = prev_self_param;
        self.self_is_param = false;
        for (iface.methods) |m| {
            if (!m.is_default or isAssociatedFn(m)) continue;
            const body_src = m.body orelse continue;
            const defined = for (members.items) |existing| {
                if (std.mem.eql(u8, existing.name, m.name)) break true;
            } else false;
            if (defined) continue;
            // No effect flags here: `#[@<effect>]` on a `behavior` member is
            // refused by the checker (`effect-on-behavior-method-forbidden`),
            // so a default body never carries one — the implementing `fn` does.
            const params = try self.buildParams(m.params);
            self.current_indent = 2;
            const body = try self.buildStmts(body_src);
            self.current_indent = 0;
            try members.append(self.arena(), .{
                .name = m.name,
                .params = params,
                .body = .{ .stmts = body, .indent = 1 },
            });
        }
        for (iface.extends) |parent| try self.appendInterfaceDefaults(members, parent, depth + 1);
    }

    /// `<Class>.prototype.__bp = "<source name>";` — the marker the §7
    /// formatter reads to tell a botopink value from a host object, carrying
    /// the name the language spells for the type. It sits on the prototype,
    /// so `Object.keys(value)` still answers exactly the declared fields.
    fn protoName(self: *Emitter, class_name: []const u8, source_name: []const u8) !js.Stmt {
        return .{ .expr = try self.b.assign(
            try self.b.member(try self.b.member(.{ .name = class_name }, "prototype"), "__bp"),
            "=",
            .{ .quoted = source_name },
        ) };
    }

    /// The JS class name of one variant of `enum_name` — `Shape$Circle`.
    /// A botopink identifier cannot hold a `$`, so the mangling never collides
    /// with a user type.
    fn variantClassName(self: *Emitter, enum_name: []const u8, variant: []const u8) ![]const u8 {
        return std.fmt.allocPrint(self.arena(), "{s}${s}", .{ enum_name, variant });
    }

    /// 1.0.5-beta decision 5 — a `type` with variants emits **a class per
    /// declaration and a subclass per variant**, so every value of the type
    /// answers `instanceof Shape` and every variant answers its own class:
    ///
    /// ```js
    /// class Shape {
    ///     static Circle(radius) { return new Shape$Circle(radius); }
    /// }
    /// class Shape$Circle extends Shape {
    ///     constructor(radius) { super(); this.radius = radius; }
    /// }
    /// Shape$Circle.prototype.tag = "Circle";
    /// class Shape$Dot extends Shape {
    /// }
    /// Shape$Dot.prototype.tag = "Dot";
    /// Shape.Dot = new Shape$Dot();
    /// ```
    ///
    /// A payload-less variant is a **singleton instance**, not the bare string
    /// it used to be — the shape the emitted `.d.ts` always declared. `tag`
    /// lives on the prototype, not on the instance, so it is identity rather
    /// than data: a variant arm in another module keeps testing `_s.tag`, and
    /// `Object.keys(value)` still answers exactly the payload fields, which is
    /// what the §7 formatter reads.
    ///
    /// The subclasses follow the base class because `extends Shape` is
    /// evaluated when the subclass declaration runs; the singletons follow the
    /// subclasses for the same reason.
    fn buildEnum(self: *Emitter, e: ast.TypeDecl) !js.Stmt {
        var members: std.ArrayListUnmanaged(js.Class.ClassMember) = .empty;
        var tail: std.ArrayListUnmanaged(js.Stmt) = .empty;

        for (e.variants()) |v| {
            const class_name = try self.variantClassName(e.name, v.name);
            var ctor: ?js.Class.Ctor = null;
            if (v.fields.len > 0) {
                const params = try self.arena().alloc(js.Param, v.fields.len);
                const assigns = try self.arena().alloc(js.Stmt, v.fields.len + 1);
                assigns[0] = .{ .expr = try self.b.call(.{ .name = "super" }, &.{}) };
                for (v.fields, 0..) |f, i| {
                    params[i] = .{ .pattern = .{ .name = f.name } };
                    assigns[i + 1] = .{ .expr = try self.b.assign(
                        try self.b.member(.this, f.name),
                        "=",
                        .{ .name = f.name },
                    ) };
                }
                ctor = .{ .params = params, .body = .{ .stmts = assigns, .indent = 1 } };

                // `Shape.Circle(5)` stays a call, so the factory keeps every
                // construction site in the language byte-identical.
                const args = try self.arena().alloc(js.Expr, v.fields.len);
                for (v.fields, 0..) |f, i| args[i] = .{ .name = f.name };
                try members.append(self.arena(), .{
                    .kind = .static_method,
                    .name = v.name,
                    .params = params,
                    .body = .{ .stmts = try self.b.stmts(&.{
                        .{ .return_ = try self.b.new_(.{ .name = class_name }, args) },
                    }), .indent = 1 },
                });
            }

            try tail.append(self.arena(), .{ .class = .{
                .name = class_name,
                .extends = e.name,
                .ctor = ctor,
            } });
            try tail.append(self.arena(), .{ .expr = try self.b.assign(
                try self.b.member(try self.b.member(.{ .name = class_name }, "prototype"), "tag"),
                "=",
                .{ .quoted = v.name },
            ) });
        }

        // The payload-less singletons, after every subclass exists.
        for (e.variants()) |v| {
            if (v.fields.len > 0) continue;
            try tail.append(self.arena(), .{ .expr = try self.b.assign(
                try self.b.member(.{ .name = e.name }, v.name),
                "=",
                try self.b.new_(.{ .name = try self.variantClassName(e.name, v.name) }, &.{}),
            ) });
        }

        const prev_self_param = self.self_is_param;
        defer self.self_is_param = prev_self_param;
        for (e.methods) |m| {
            if (m.is_declare) continue;
            // A receiver-first method keeps `self` as a real parameter: an enum
            // method is a static of the enum's class, so a call site passes the
            // value in (`Shape.area(value)`, `enumMethodOwner`).
            const recv_first = enumMethodTakesReceiver(m) and std.mem.eql(u8, m.params[0].name, "self");
            const params = if (recv_first) blk: {
                const ps = try self.arena().alloc(js.Param, m.params.len);
                for (m.params, 0..) |p, i| ps[i] = try self.buildParam(p);
                break :blk ps;
            } else try self.buildParams(m.params);
            self.self_is_param = recv_first;
            const eff = methodEffect(m);
            const shape = effectShape(eff);
            const prev_in_generator = self.in_generator;
            self.in_generator = shape.is_generator;
            self.current_indent = 2;
            const prev_expr_try = self.expr_try_used;
            self.expr_try_used = false;
            const body = try self.guardExprTry(try self.buildStmts(m.body orelse &.{}), 2);
            self.expr_try_used = prev_expr_try;
            self.current_indent = 0;
            self.in_generator = prev_in_generator;
            try members.append(self.arena(), .{
                .kind = .static_method,
                .name = m.name,
                .params = params,
                .body = .{ .stmts = body, .indent = 1 },
                .is_async = shape.is_async,
                .is_generator = shape.is_generator,
            });
        }

        var out: std.ArrayListUnmanaged(js.Stmt) = .empty;
        try out.append(self.arena(), .{ .class = .{
            .name = e.name,
            .members = try members.toOwnedSlice(self.arena()),
        } });
        // Only the base class is marked: every variant inherits `__bp` and
        // adds its own `tag`, which is how the formatter spells `Shape.Square`.
        try out.append(self.arena(), try self.protoName(e.name, e.name));
        for (tail.items) |st| try out.append(self.arena(), st);
        if (e.isPub) try out.append(self.arena(), try self.pubExport(e.name));
        return self.b.group(try out.toOwnedSlice(self.arena()));
    }

    fn buildInterface(self: *Emitter, i: ast.BehaviorDecl) !js.Stmt {
        var stmts: std.ArrayListUnmanaged(js.Stmt) = .empty;

        // A doc block naming the behavior's shape — the contract itself has no
        // runtime representation.
        var head: std.ArrayListUnmanaged(u8) = .empty;
        try head.print(self.arena(), "behavior {s}", .{i.name});
        if (i.extends.len > 0) {
            try head.appendSlice(self.arena(), " extends ");
            for (i.extends, 0..) |ext, j| {
                if (j > 0) try head.appendSlice(self.arena(), ", ");
                try head.appendSlice(self.arena(), ext);
            }
        }
        try stmts.append(self.arena(), .{ .comment = .{ .text = try head.toOwnedSlice(self.arena()) } });
        for (i.fields) |f| try stmts.append(self.arena(), .{ .comment = .{
            .text = try std.fmt.allocPrint(self.arena(), "  {s}: {f}", .{ f.name, f.typeRef }),
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
        // `#[@External.Node("X")]` annotation means "this method already exists on
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
            const node_ref = m.externalFor("node") orelse if (m.body == null and isJsGlobalNamespace(owner))
                try self.preludeIfaceExternal(i.name, m.name)
            else
                null;
            if (node_ref) |ref| {
                // Template-form annotation (`$0`/`$1`/… markers): render the
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
                // A user interface owns no JS constructor: its defaults are
                // class methods of each implementing record instead.
                if (!isJsGlobalNamespace(owner)) continue;
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
                for (body_src) |s| try body.append(self.arena(), try self.buildStmt(s));
                self.current_indent = prev;
                try stmts.append(self.arena(), try self.prototypeAssign(owner, m.name, .{
                    .params = params,
                    .body = .{ .stmts = try body.toOwnedSlice(self.arena()) },
                }));
            } else if (node_ref) |ref| {
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

    /// The symbol an UNTYPED call of behavior method `m` emits on node: the
    /// plain 2-arg `Node` symbol, else the method's own name (a template, a
    /// `(module, symbol)` external, a `default fn` and an unannotated method
    /// all keep it). Two behaviors disagreeing on a name make it ambiguous.
    fn noteUntypedNodeSymbol(self: *Emitter, m: ast.BehaviorMethod) !void {
        const sym: []const u8 = blk: {
            const ref = m.externalFor("node") orelse break :blk m.name;
            if (ref.module.len != 0) break :blk m.name;
            if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) break :blk m.name;
            break :blk ref.symbol;
        };
        if (self.prim_symbol_of.get(m.name)) |prev| {
            if (!std.mem.eql(u8, prev, sym)) try self.ambiguous_prim_renames.put(try self.arena().dupe(u8, m.name), {});
        } else {
            try self.prim_symbol_of.put(try self.arena().dupe(u8, m.name), try self.arena().dupe(u8, sym));
        }
    }

    /// The std prelude's `#[@External.Node]` for `iface.method`, if any.
    fn preludeIfaceExternal(self: *Emitter, iface: []const u8, method: []const u8) !?ast.ExternalRef {
        const key = try std.fmt.allocPrint(self.arena(), "{s}.{s}", .{ iface, method });
        return self.prelude_iface_externals.get(key);
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
            // Decision 107 — an item names a module (`dict`, `io.fs`,
            // `io: {fs}`) and binds the module object under the leaf; or it
            // names a `pub` declaration of the module its prefix spells
            // (`io.fs.readText as read`) and destructures that one name, under
            // the alias when there is one — one `const {…}` per std module,
            // in the order the list first names each.
            var symbol_mods: std.ArrayListUnmanaged([]const u8) = .empty;
            var symbol_props: std.ArrayListUnmanaged(std.ArrayListUnmanaged(js.ObjectPattern.Prop)) = .empty;
            for (u.imports) |imp| {
                if (self.seen_imports.contains(imp.name())) continue;
                try self.seen_imports.put(imp.name(), {});
                const whole = try imp.fullPath(self.arena());
                if (!imp.isQualified() or comptimeMod.isStdModule(whole)) {
                    try stmts.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .name = imp.name() },
                        .value = try self.requireCall(try std.fmt.allocPrint(self.arena(), "{s}std/{s}.js", .{ req_prefix, whole })),
                    } });
                    continue;
                }
                const mod = try imp.prefixPath(self.arena());
                var slot: ?usize = null;
                for (symbol_mods.items, 0..) |m, i| {
                    if (std.mem.eql(u8, m, mod)) slot = i;
                }
                if (slot == null) {
                    try symbol_mods.append(self.arena(), mod);
                    try symbol_props.append(self.arena(), .empty);
                    slot = symbol_mods.items.len - 1;
                }
                try symbol_props.items[slot.?].append(self.arena(), .{ .key = imp.leaf(), .bind = imp.alias });
            }
            for (symbol_mods.items, symbol_props.items) |mod, *props| {
                try stmts.append(self.arena(), .{ .decl = .{
                    .pattern = .{ .object = .{ .props = try props.toOwnedSlice(self.arena()) } },
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
        // A shorthand `import { … };` (decision 3 — the form stays, and it
        // resolves) names no module, so it took the fallback below and emitted
        // the literal word: `require("./module")`, a path that does not exist.
        // It resolves the same way a `from "<pkg>"` import does — name by name
        // through the cross-module export index — so both enter here.
        if (self.cross != null) {
            const xm = self.cross.?;
            var seen = std.StringHashMap(void).init(self.alloc);
            defer seen.deinit();
            for (u.imports) |imp| {
                // Which module emits this name — asked of the import's own
                // `from "<mod>"`, not of a name-keyed `get` whose winner was
                // the walk order. Measured before this: `import {parse} from
                // "one"` emitted `require("./two.js")` and node printed the
                // other module's answer at exit 0. A qualified item
                // (decision 107) asks for its LEAF in the module its prefix
                // names (`html.div` → `div` in `<lib>/html`), and binds it
                // under the alias when one is written.
                const info = xm.picked(imp.leaf(), try u.leafSource(imp, self.arena(), false), null) orelse continue;
                if (seen.contains(info.module)) continue;
                try seen.put(info.module, {});
                // Names from this module not already bound here — `const {…}` for
                // exactly those. If every one is already bound, emit no line.
                var props: std.ArrayListUnmanaged(js.ObjectPattern.Prop) = .empty;
                for (u.imports) |imp2| {
                    const info2 = xm.picked(imp2.leaf(), try u.leafSource(imp2, self.arena(), false), null) orelse continue;
                    if (!std.mem.eql(u8, info2.module, info.module)) continue;
                    if (self.seen_imports.contains(imp2.name())) continue;
                    try self.seen_imports.put(imp2.name(), {});
                    try props.append(self.arena(), .{ .key = imp2.leaf(), .bind = imp2.alias });
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
            // A shorthand `import { … };` names no package, so there is no
            // namespace handle to bind — only the per-name `require`s above.
            // No import is named `""`, so the block below never fires for it.
            const lib_name = switch (u.source) {
                .module => |name| name,
                .root => "",
            };
            var names_lib = false;
            for (u.imports) |imp| {
                if (std.mem.eql(u8, imp.name(), lib_name)) {
                    names_lib = true;
                    break;
                }
            }
            if (names_lib and xm.exports.get(lib_name) == null) {
                // Distinct modules emitted under the lib's `<lib>/` path prefix,
                // sorted for deterministic output (the export map is unordered).
                var mods: std.ArrayListUnmanaged([]const u8) = .empty;
                defer mods.deinit(self.alloc);
                var mseen = std.StringHashMap(void).init(self.alloc);
                defer mseen.deinit();
                const mod_prefix = try std.fmt.allocPrint(self.alloc, "{s}/", .{lib_name});
                defer self.alloc.free(mod_prefix);
                var it = xm.exports.valueIterator();
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
            try props.append(self.arena(), .{ .key = imp.leaf(), .bind = imp.alias });
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
        try self.notePrintShape(p.name, try self.typeShape(p.typeRef));
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

    /// A botopink pattern in BINDING position — `val Circle(r) = s;`,
    /// `val [a, ..rest] = xs;` — as a plain JavaScript destructuring target
    /// (JS-4). The checker (01 R5) accepts the bare form only where the
    /// pattern cannot fail — the one variant of a one-variant `type`, a
    /// record's own constructor, a spread-only list — and refuses every
    /// refutable one as `refutable-val-pattern`, so no test is emitted: a
    /// constructor reads each binding off the declared field at its position
    /// (`const { radius: r } = s;`), a list off its index. The arms a
    /// refutable pattern would need (a literal, an alternation) are never
    /// reached; they bind nothing (`_`).
    fn buildPattern(self: *Emitter, pat: ast.Pattern) anyerror!js.Pattern {
        switch (pat) {
            .wildcard, .numberLit, .stringLit, .@"or", .multi => return .{ .name = "_" },
            .ident => |name| return .{ .ident = name },
            .variant => |v| {
                if (v.shape == .tuple) {
                    const lits = if (v.payload == .literals) v.payload.literals else &.{};
                    const elems = try self.arena().alloc(js.Pattern, lits.len);
                    for (lits, 0..) |p, i| elems[i] = try self.buildPattern(p);
                    return .{ .array = .{ .elems = elems } };
                }
                const bare = bareVariantName(v.name);
                const declared = self.variant_fields.get(bare) orelse self.record_fields.get(bare);
                switch (v.payload) {
                    .binding => |binding| return .{ .ident = binding },
                    .fields => |fields| {
                        const props = try self.arena().alloc(js.ObjectPattern.Prop, fields.len);
                        for (fields, 0..) |bb, bi| {
                            const key = variantFieldKey(v, declared, bi) orelse bb;
                            props[bi] = .{ .key = key, .bind = if (std.mem.eql(u8, key, bb)) null else jsIdent(bb) };
                        }
                        return .{ .object = .{ .props = props } };
                    },
                    .literals => |lits| {
                        var props: std.ArrayListUnmanaged(js.ObjectPattern.Prop) = .empty;
                        for (lits, 0..) |p, li| {
                            // `_` binds nothing: the property is left out, so
                            // two wildcards never declare `_` twice.
                            if (p == .wildcard) continue;
                            const key = variantFieldKey(v, declared, li) orelse continue;
                            if (p == .ident) {
                                const bb = p.ident;
                                try props.append(self.arena(), .{ .key = key, .bind = if (std.mem.eql(u8, key, bb)) null else jsIdent(bb) });
                                continue;
                            }
                            const nested = try self.arena().create(js.Pattern);
                            nested.* = try self.buildPattern(p);
                            try props.append(self.arena(), .{ .key = key, .nested = nested });
                        }
                        return .{ .object = .{ .props = try props.toOwnedSlice(self.arena()) } };
                    },
                }
            },
            .list => |l| {
                const elems = try self.arena().alloc(js.Pattern, l.elems.len);
                for (l.elems, 0..) |e, i| elems[i] = switch (e) {
                    .wildcard, .numberLit => js.Pattern{ .name = "_" },
                    .bind => |name| js.Pattern{ .ident = name },
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
            .variant => |v| {
                // An `Ok`/`Err`/`Error` naming no variant this module declares
                // is a `@Result`, which `#[@result]` materialises as `{ ok }` /
                // `{ error }` — the same key test the `case` arms use
                // (`buildCaseArm`). `instanceof Ok` named a class no module
                // ever emits, so every `val assert Ok(…)` took its handler.
                if (self.variant_fields.get(v.name) == null) {
                    if (resultKey(v.name)) |key| {
                        return self.b.paren(try self.b.binaryBare("in", .{ .quoted = key }, subject));
                    }
                }
                return switch (v.payload) {
                    // Check if value is an instance of the variant type.
                    .binding, .fields => try self.b.paren(try self.b.binaryBare("instanceof", subject, .{ .name = v.name })),
                    // Literal-argument variants fall back to the generic check below.
                    .literals => js.Expr{ .name = "true" },
                };
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
        var out: std.ArrayListUnmanaged(js.Stmt) = .empty;
        try out.ensureTotalCapacity(self.arena(), body.len);
        for (body) |s| {
            // `val assert P = e [catch h];` — decision 8 § 9 binds `P`'s names
            // for the statements after it, so it needs more than one JS
            // statement and cannot go through `buildStmt`.
            if (self.assertPatternBindingStmt(s)) |ap| {
                try self.appendAssertPatternStmts(&out, ap);
                continue;
            }
            try out.append(self.arena(), try self.buildStmt(s));
        }
        return out.toOwnedSlice(self.arena());
    }

    /// The `val assert` at `stmt` whose pattern binds at least one name, or
    /// null. A pattern that binds nothing (`val assert 42 = answer catch 0;`)
    /// is a pure check and keeps the single-expression lowering.
    fn assertPatternBindingStmt(self: *const Emitter, stmt: ast.Stmt) ?@FieldType(@FieldType(ast.ComptimeExpr, "kind"), "assertPattern") {
        if (stmt.expr != .comptime_) return null;
        if (stmt.expr.comptime_.kind != .assertPattern) return null;
        const ap = stmt.expr.comptime_.kind.assertPattern;
        const isVariant = struct {
            fn f(e: *const Emitter, name: []const u8) bool {
                return e.variant_fields.get(name) != null;
            }
        }.f;
        if (!patternFacts.bindsNames(ap.pattern, self, isVariant)) return null;
        return ap;
    }

    /// ```javascript
    /// const _assert0 = (() => { … the check, the handler … })();
    /// const n = _assert0.ok;
    /// ```
    ///
    /// The IIFE is the lowering a `val assert` has always had — it yields the
    /// subject when the pattern matched and the handler's value otherwise (for
    /// the handler-less form the handler is the `@panic(…)` the parser
    /// desugars to, so a mismatch throws). The declarations after it are what
    /// decision 8 § 9 adds: the pattern's names, in the enclosing block.
    fn appendAssertPatternStmts(
        self: *Emitter,
        out: *std.ArrayListUnmanaged(js.Stmt),
        ap: anytype,
    ) anyerror!void {
        const tmp = try std.fmt.allocPrint(self.arena(), "_assert{d}", .{self.assert_seq});
        self.assert_seq += 1;
        try out.append(self.arena(), .{ .decl = .{
            .pattern = .{ .name = tmp },
            .value = try self.buildExpr(.{ .comptime_ = .{ .loc = .{ .line = 0, .col = 0 }, .kind = .{ .assertPattern = ap } } }),
        } });
        try self.appendPatternBinds(out, ap.pattern, .{ .name = tmp });
    }

    fn buildStmt(self: *Emitter, stmt: ast.Stmt) anyerror!js.Stmt {
        const e = stmt.expr;
        switch (e) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const kw: js.Decl.Kw = if (lb.mutable) .let_ else .const_;
                    try self.notePrintShape(lb.name, if (lb.typeAnnotation) |ta| try self.typeShape(ta) else try self.printShape(lb.value.*));
                    if (classifyTry(lb.value.*)) |form| {
                        return self.buildTryStmt(form, .{ .decl = .{ .kw = kw, .name = lb.name } });
                    }
                    // `val d = use memo(…)` → `const d = memo(…)`: the `use`
                    // prefix is transparent (decision 88), `buildExpr` drops it.
                    const value = try self.buildExpr(lb.value.*);
                    return .{ .decl = .{ .kw = kw, .pattern = .{ .ident = lb.name }, .value = value } };
                },
                .localBindDestruct => |lb| {
                    if (classifyTry(lb.value.*)) |form| {
                        return self.buildTryStmt(form, .{ .destruct = .{ .mutable = lb.mutable, .pattern = lb.pattern } });
                    }
                    // `val {v, s} = use state(0)` → `const { v, s } = state(0)`.
                    const value = try self.buildExpr(lb.value.*);
                    return .{ .decl = .{
                        .kw = if (lb.mutable) .let_ else .const_,
                        .pattern = try self.buildDestructPattern(lb.pattern),
                        .value = value,
                    } };
                },
                else => return .{ .expr = try self.buildExpr(e) },
            },
            // A bare `use <hookcall>;` statement is a void hook (`use effect(…)`).
            // Decision 104 — every `#[@use]` body is an `async function` here,
            // so a hook answers a Promise and `use` awaits it; the body that
            // writes `use` is `#[@use]` too, so the `await` is always legal.
            .useHook => |uh| return .{ .expr = try self.b.await_(try self.buildExpr(uh.kind.inner.*)) },
            // An `if` whose branches jump out (`return`, `break`, `continue`)
            // is a JS `if` statement: a jump cannot leave the IIFE the value
            // form wraps it in.
            .branch => |br| switch (br.kind) {
                .if_ => |i| if (self.ifJumps(i)) return self.buildIfStmt(i),
                .tryCatch => {},
            },
            .loop => |lp| return try self.buildLoopStmt(lp),
            .jump => |j| switch (j.kind) {
                .@"break" => |br| return self.buildBreakStmt(br, false),
                .throw_ => |r| return .{ .throw_ = try self.buildExpr((r orelse return error.ThrowWithoutOperand).*) },
                .@"continue" => return switch (self.loop_ctx) {
                    .none => error.JumpOutsideLoop,
                    .stmt => js.Stmt.continue_,
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
                    // `return <iter>` in a generator body
                    // delegates: `yield* <iter>; return;` (a plain
                    // `return <gen>` surfaces the generator object and
                    // yields nothing).
                    if (self.in_generator) return .{ .yield_delegate = try self.buildExpr(rp.*) };
                    return .{ .return_ = try self.buildExpr(rp.*) };
                },
                // Decision 122 — `yield try x` / `yield __bp_ok(try x)` in a
                // sequence whose item is a `@Result`: a failing `try` emits
                // the Error as the last item and ends; an Ok is emitted as
                // the Result it already is.
                .yield => |y| {
                    if (y.value) |vp| {
                        const inner: ?ast.Expr = if (classifyTry(vp.*) != null)
                            vp.*
                        else if (okWrapOperand(vp.*)) |op| (if (classifyTry(op) != null) op else null) else null;
                        if (inner) |in| {
                            if (classifyTry(in)) |form| if (form == .propagate) {
                                const wrapped = classifyTry(vp.*) == null;
                                return self.buildTryStmt(form, if (wrapped) .yield_result else .yield_ok_value);
                            };
                        }
                    }
                    return .{ .expr = try self.buildExpr(e) };
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

    /// A trailing/inline lambda body: the tail value expression is its result,
    /// because a JS arrow block does not auto-return.
    fn buildLambdaBody(self: *Emitter, body: []const ast.Stmt) ![]const js.Stmt {
        const out = try self.arena().alloc(js.Stmt, body.len);
        for (body, 0..) |st, i| {
            out[i] = if (i == body.len - 1)
                try self.buildLambdaTail(st)
            else
                try self.buildStmt(st);
        }
        return out;
    }

    /// The lambda's LAST statement is its return position, so every expression
    /// form `buildExpr` can give a value to is `return`ed there — the same rule
    /// `buildIfLast` applies one level down, and the same rule a `val x = <e>;`
    /// binding already gets.
    ///
    /// `isImplicitReturnExpr` alone was not that rule: it lists only the
    /// categories that are *always* a value, so an `if`, an annotated `loop`
    /// and a `try`/`catch` tail fell through to `buildStmt` and were emitted as
    /// statements — `(x) => { (() => { … })(); }` — dropping the value. A
    /// `case` never had the defect: it is a `.collection`.
    ///
    /// Still statements: a jump (`return`/`throw`/`break`/`continue`/`yield`),
    /// a binding, a `use` hook, and any `if`/`loop` whose body jumps out of the
    /// lambda — a `return` cannot cross the IIFE the value form wraps it in.
    fn buildLambdaTail(self: *Emitter, st: ast.Stmt) anyerror!js.Stmt {
        const e = st.expr;
        // `try f()` / `try f() catch v` — the Result lowering, with the Ok
        // value landing in `return` instead of being discarded.
        if (classifyTry(e)) |form| return self.buildTryStmt(form, .ret);
        if (isImplicitReturnExpr(e)) return .{ .return_ = try self.buildExpr(e) };
        switch (e) {
            // `buildArrow` reset `loop_ctx` to `.none`, so no accumulator
            // `yield` is in scope here — `exprJumps`' third argument is false.
            .branch => if (!exprJumps(e, false, false)) {
                return .{ .return_ = try self.buildExpr(e) };
            },
            // Decision 105: only the annotated loop is a value; every other
            // loop is a statement, even in the tail.
            .loop => |lp| if (lp.generator != null) {
                return .{ .return_ = try self.buildExpr(e) };
            },
            else => {},
        }
        return self.buildStmt(st);
    }

    /// `(params) => { body }` with implicit tail return.
    fn buildArrow(self: *Emitter, params: []const []const u8, body: []const ast.Stmt) !js.Expr {
        // A nested arrow is not a generator — its `return` stays `return` —
        // and no jump crosses it.
        const prev_in_generator = self.in_generator;
        const prev_ctx = self.loop_ctx;
        const prev_wrap = self.case_ok_wrap;
        const prev_in_test = self.in_test_body;
        self.in_generator = false;
        self.loop_ctx = .none;
        self.case_ok_wrap = false;
        self.in_test_body = false;
        defer {
            self.in_generator = prev_in_generator;
            self.loop_ctx = prev_ctx;
            self.case_ok_wrap = prev_wrap;
            self.in_test_body = prev_in_test;
        }
        const ps = try self.arena().alloc(js.Param, params.len);
        for (params, 0..) |p, i| ps[i] = .{ .pattern = .{ .ident = p } };
        const prev_expr_try = self.expr_try_used;
        self.expr_try_used = false;
        defer self.expr_try_used = prev_expr_try;
        const lambda_body = try self.guardExprTry(try self.buildLambdaBody(body), self.current_indent);
        return self.b.arrowBlock(ps, .{
            .stmts = lambda_body,
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
            .yield_ok_value => js.Stmt{ .expr = try self.b.yield_(value) },
            // Unreachable: `tryValueStmt` yields the whole Result for it.
            .yield_result => js.Stmt{ .expr = try self.b.yield_(value) },
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
                // Inside a `test` body (decision 74) the Error ends the test:
                // `throw new Error(e)` — a string `e` is the message verbatim,
                // anything else is JSON-rendered — and `__bp_run_tests`' catch
                // prints `FAIL <name>  (<e>)  at <file>:<line>`. Everywhere else
                // it propagates as the fn's own Result.
                const on_error: js.Stmt = if (self.in_test_body) blk: {
                    const err_val = try self.b.member(.{ .name = temp }, "error");
                    const is_string = try self.b.binaryBare("===", try self.b.unary("typeof ", err_val, false), .{ .quoted = "string" });
                    const rendered = try self.b.call(try self.b.member(.{ .name = "JSON" }, "stringify"), &.{err_val});
                    const message = try self.b.ternary(is_string, err_val, rendered);
                    break :blk .{ .throw_ = try self.b.new_(.{ .name = "Error" }, &.{message}) };
                } else if (self.in_generator) blk: {
                    // Decision 122 — in a sequence whose item is a
                    // `@Result`, a failing `try` emits the Error as the last
                    // item and ends: `yield _tryN; return;`.
                    break :blk .{ .block = .{
                        .stmts = try self.b.stmts(&.{
                            .{ .expr = try self.b.yield_(.{ .name = temp }) },
                            .{ .return_ = null },
                        }),
                        .layout = .spaced,
                    } };
                } else .{ .return_ = .{ .name = temp } };
                try stmts.append(self.arena(), try self.b.ifStmt(try self.errorIn(temp), on_error));
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
        // `yield __bp_ok(try x)`: the Ok Result is the item as it is.
        if (head == .yield_result) return js.Stmt{ .expr = try self.b.yield_(.{ .name = temp }) };
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
            // A trailing loop is a statement (decision 105) — only the
            // annotated one has a value.
            .loop => |lp| if (lp.generator == null) return self.buildStmt(stmt),
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
                // Decision 8 §6 T6 — a tuple is positional at run time, so
                // `==` compares its elements. A tuple is a JS array and `==`
                // lowers to `===`, which compares references, so two equal
                // tuples were unequal.
                //
                // The helper is structural for **every** composite value, not
                // only for tuples (decision 35), but only a tuple reaches it
                // today: this emitter walks the **untyped** AST
                // (`buildExpr(e: ast.Expr)`), so the one thing it can know
                // about an operand is the static print shape `printShape`
                // already recovers — and that is exactly "this expression
                // holds a tuple". Turning the row on for a record, an array or
                // a variant needs the operand's type at the site, which means
                // marking it in inference by `Loc` the way `method_lowerings`
                // does; that crosses front 01 and is the maintainer's call.
                // One side shaped is enough: the other is a tuple too, or the
                // helper's constructor test answers `false` exactly as `===`
                // did.
                if ((bin.op == .eq or bin.op == .ne) and try self.isTupleShaped(bin.lhs.*, bin.rhs.*)) {
                    const cmp = try self.b.call(self.helper(.structural_eq), &.{
                        try self.buildExpr(bin.lhs.*),
                        try self.buildExpr(bin.rhs.*),
                        .{ .number = "0" },
                    });
                    return if (bin.op == .eq) cmp else self.b.unary("!", cmp, true);
                }
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
                .throw_ => |r| return self.iife(&.{.{
                    .throw_ = try self.buildExpr((r orelse return error.ThrowWithoutOperand).*),
                }}),
                .try_ => |t| {
                    // The parser always gives `try` an operand.
                    const val = t orelse return error.TryWithoutOperand;
                    // Nested `try` in expression position (`total + try r`):
                    // `__bp_try(x)` answers the Ok value or throws the Error
                    // Result to the enclosing function's guard, which returns
                    // (or, in a generator, yields and ends) it — the same
                    // propagation the statement form gets from `buildTryStmt`.
                    self.expr_try_used = true;
                    return self.b.call(self.helper(.try_unwrap), &.{try self.buildExpr(val.*)});
                },
                .await_ => |av| return self.b.await_(try self.buildExpr(av.*)),
                // Generator `yield` (loop-accumulator yields are lowered at
                // the `.loop` site, so reaching here means an `#[@resultGenerator]`
                // / `#[@generator]` / `#[@futureGenerator]` body).
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
                    return self.iife(&.{
                        .{ .decl = .{ .pattern = .{ .name = temp }, .value = try self.buildExpr(tc.expr.*) } },
                        try self.b.ifStmt(try self.errorIn(temp), .{ .block = .{
                            .stmts = try self.b.stmts(&.{handled}),
                            .layout = .spaced,
                        } }),
                        .{ .return_ = try self.b.member(.{ .name = temp }, "ok") },
                    });
                },
            },

            .loop => |lp| return self.buildGeneratorLoop(lp),

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

            // `use <call>` in value position is the call, awaited: the prefix
            // is the activation the checker validated, not a rename (decision
            // 88), and on this target the hook is an `async function`
            // (decision 104), so `use state(0)` is `await state(0)`. erlang,
            // wasm and beam keep the bare call — their `@Future` is eager.
            .useHook => |uh| return self.b.await_(try self.buildExpr(uh.kind.inner.*)),

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

            .function => |f| {
                if (f.kind.syntax == .asyncBlock) return self.buildAsyncBlock(f.kind.body);
                return self.buildArrow(f.kind.params, f.kind.body);
            },

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
                        // An open-ended `a..` is a lazy infinite range; a finite
                        // JS array can't represent it, so it is the prelude
                        // generator counting up from `a` (a loop over it ends
                        // with `break`, like erlang's recursive counter).
                        return self.b.call(self.helper(.range_from), &.{try self.buildExpr(r.start.*)});
                    const start = try self.b.paren(try self.buildExpr(r.start.*));
                    // `a...b` (decision 105) includes its end: one more.
                    const stop = if (r.inclusive)
                        try self.b.paren(try self.b.binaryBare("+", try self.b.paren(try self.buildExpr(end.*)), .{ .number = "1" }))
                    else
                        try self.b.paren(try self.buildExpr(end.*));
                    const length = try self.b.call(try self.b.member(.{ .name = "Math" }, "max"), &.{
                        .{ .number = "0" },
                        try self.b.binaryBare("-", stop, start),
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
                .behaviorLit => |il| return self.b.paren(try self.buildFieldObject(il.fields)),
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
                    // Outside test mode an `assert` is always fatal and names
                    // its message and `file:line` (semantics decision 4) — never
                    // `console.assert`, which prints and carries on.
                    return self.b.call(self.helper(.assert_fatal), &.{
                        cond,
                        if (a.message) |msg| try self.buildExpr(msg.*) else .null_,
                        .{ .quoted = try std.fmt.allocPrint(self.arena(), "{s}.bp:{d}", .{ self.module_name, ct.loc.line }) },
                    });
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
                    return self.iife(&.{
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
        // The optional-binding guard is the **loose** `!= null`, for the reason
        // `==`/`!=` against a `null` literal are loose above: botopink has one
        // none value and JavaScript spells it two ways — `?.` answers
        // `undefined`, so `o.inner?.v ?? 9` took the value branch with
        // `undefined` in hand under a strict `!==`.
        const cond: js.Expr = if (i.binding) |b| blk: {
            try seq.append(self.arena(), .{ .decl = .{
                .pattern = .{ .name = b },
                .value = try self.buildExpr(i.cond.*),
            } });
            break :blk try self.b.binaryBare("!=", .{ .name = b }, .null_);
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
            try self.b.binaryBare("!=", .{ .name = b }, .null_)
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
    /// branch — or a `break <v>`, which ends the generator (decision 105).
    fn ifJumps(self: *Emitter, i: anytype) bool {
        if (stmtsJump(i.then_, false, self.in_generator)) return true;
        if (i.else_) |els| if (stmtsJump(els, false, self.in_generator)) return true;
        return false;
    }

    fn stmtsJump(stmts: []const ast.Stmt, in_loop: bool, gen_break: bool) bool {
        for (stmts) |st| if (exprJumps(st.expr, in_loop, gen_break)) return true;
        return false;
    }

    /// `gen_break`: inside a generator scope a `break <v>` ends the generator
    /// from any loop depth (`yield v; return;`); elsewhere a `break <v>` is a
    /// `case` arm's or `comptime` block's value and leaves nothing.
    fn exprJumps(e: ast.Expr, in_loop: bool, gen_break: bool) bool {
        return switch (e) {
            .jump => |j| switch (j.kind) {
                .@"return" => true,
                .@"break" => |b| (gen_break and b.value != null) or !in_loop,
                .@"continue" => !in_loop,
                // In a generator a `yield` cannot sit inside the arrow a
                // value-form `if` lowers to (decision 122's `if (…) { yield x; }`),
                // so an `if` holding one is a statement there.
                .yield => gen_break,
                .throw_, .try_, .await_ => false,
            },
            .branch => |br| switch (br.kind) {
                .if_ => |i| stmtsJump(i.then_, in_loop, gen_break) or
                    (if (i.else_) |els| stmtsJump(els, in_loop, gen_break) else false),
                .tryCatch => false,
            },
            // A nested loop's own `break` / `continue` bind to it; a `return`
            // inside it still leaves the function.
            .loop => |lp| stmtsJump(lp.body, true, gen_break),
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

    /// `for (xs) { x -> … }` iterates the ITEM: the one binder is the
    /// `for…of` pattern (decision 105 has no index binder; the index is
    /// `for (0..xs.length) { i -> }`).
    fn loopHead(self: *Emitter, lp: anytype) !struct { pattern: js.Pattern, iter: js.Expr } {
        return .{ .pattern = .{ .ident = lp.params[0] }, .iter = try self.buildExpr(lp.iter.*) };
    }

    /// A loop in statement position (decision 105 — every loop is one):
    /// `for (xs) { x -> … }` / `for await (gen) { x -> … }` is a JS `for…of`
    /// / `for await…of`; `while (cond) { … }` and `loop { … }` a JS `while`.
    /// `break` / `continue` are the native statements; inside a generator
    /// scope a `yield` is the native one and a `break <v>` is `yield v;
    /// return;`. An annotated `loop` in statement position is its generator
    /// expression, discarded.
    fn buildLoopStmt(self: *Emitter, lp: anytype) anyerror!js.Stmt {
        if (lp.generator != null) return .{ .expr = try self.buildGeneratorLoop(lp) };
        if (lp.condition) return try self.buildWhileStmt(lp.iter.*, lp.body);
        const head = try self.loopHead(lp);
        const prev_ctx = self.loop_ctx;
        self.loop_ctx = .stmt;
        defer self.loop_ctx = prev_ctx;
        return .{ .for_of = .{
            .pattern = head.pattern,
            .iter = head.iter,
            .is_await = lp.awaitLoop,
            .body = .{
                .stmts = try self.buildStmts(lp.body),
                .layout = .fixed,
                .indent = self.current_indent,
            },
        } };
    }

    /// `while (cond) { … }` / `loop { … }` (decision 105): a JS `while`;
    /// `break` / `continue` in its body bind to it.
    fn buildWhileStmt(self: *Emitter, cond: ast.Expr, body: []const ast.Stmt) anyerror!js.Stmt {
        const c = try self.buildExpr(cond);
        const prev_ctx = self.loop_ctx;
        self.loop_ctx = .stmt;
        defer self.loop_ctx = prev_ctx;
        return .{ .while_ = .{
            .cond = c,
            .body = .{ .stmts = try self.buildStmts(body), .layout = .fixed, .indent = self.current_indent },
        } };
    }

    /// `break` in a body. Bare, it leaves the nearest loop (a native
    /// `break;`), or — with no loop, inside a generator — ends the generator
    /// (`return;`). With a value it emits the value and ends the generator
    /// scope from any loop depth: `yield v; return;` (decision 105 — the
    /// checker admits `break <v>` in a generator scope only).
    fn buildBreakStmt(self: *Emitter, br: anytype, is_last: bool) anyerror!js.Stmt {
        _ = is_last;
        const val = br.value orelse return switch (self.loop_ctx) {
            .none => if (self.in_generator) js.Stmt{ .return_ = null } else error.JumpOutsideLoop,
            .stmt => js.Stmt.break_,
        };
        if (!self.in_generator) return error.JumpOutsideLoop;
        return self.b.group(&.{ .{ .expr = try self.b.yield_(try self.buildExpr(val.*)) }, .{ .return_ = null } });
    }

    /// `#[@generator] loop { … }` (decision 105) — the loop as a generator: a
    /// local parameterless generator function called in place, its body the
    /// loop's under `while (true)`:
    ///
    ///     (function* () {
    ///         while (true) { …; yield v; …; break; }
    ///     })()
    ///
    /// `#[@futureGenerator]` is `async function*`. The captured `var`s are the
    /// closure's — JS shares them by reference, so a counter the body
    /// reassigns is generator state for free. `yield v` is native, `break v`
    /// is `yield v; return;`, a bare `break` leaves the `while` and ends the
    /// generator, `continue` starts its next round. A function boundary: the
    /// enclosing loop context and test/result wraps do not reach the body.
    fn buildGeneratorLoop(self: *Emitter, lp: anytype) anyerror!js.Expr {
        const eff = lp.generator orelse return error.LoopInValuePosition;
        const shape = effectShape(eff);
        const base = self.current_indent;
        const prev_ctx = self.loop_ctx;
        const prev_gen = self.in_generator;
        const prev_wrap = self.case_ok_wrap;
        const prev_in_test = self.in_test_body;
        self.loop_ctx = .stmt;
        self.in_generator = true;
        self.case_ok_wrap = false;
        self.in_test_body = false;
        self.current_indent = base + 2;
        defer {
            self.loop_ctx = prev_ctx;
            self.in_generator = prev_gen;
            self.case_ok_wrap = prev_wrap;
            self.in_test_body = prev_in_test;
            self.current_indent = base;
        }
        const prev_expr_try = self.expr_try_used;
        self.expr_try_used = false;
        defer self.expr_try_used = prev_expr_try;
        const body = try self.buildStmts(lp.body);
        const while_stmt = js.Stmt{ .while_ = .{
            .cond = .{ .name = "true" },
            .body = .{ .stmts = body, .indent = base + 1 },
        } };
        return self.b.call(try self.b.paren(.{ .function = .{
            .keyword = shape.keyword(),
            .params = &.{},
            .body = .{ .stmts = try self.guardExprTry(try self.b.stmts(&.{while_stmt}), base), .indent = base },
        } }), &.{});
    }

    /// `(() => { … })()` — or, when the statements `await` (an expression
    /// `try`/`catch` over an `await` in an async body), `await (async () =>
    /// { … })()`: an `await` inside a plain arrow does not parse.
    fn iife(self: *Emitter, items: []const js.Stmt) anyerror!js.Expr {
        if (!AwaitScan.stmts(items)) return self.b.iife(items);
        const fnx = try self.b.paren(.{ .function = .{
            .keyword = "async function",
            .params = &.{},
            .body = try self.b.spacedBlock(items),
        } });
        return self.b.await_(try self.b.call(fnx, &.{}));
    }

    /// `async { … }` (decision 124) — an async function called in place:
    ///
    ///     (async function() { …; return v; })()
    ///
    /// Its `return`s leave the block (they are the function's); a `throw` /
    /// failing `try` resolves the Promise with the `{ error }` value, never a
    /// rejection (decision 120). A function boundary: the enclosing loop
    /// context, generator and test flags do not reach the body.
    fn buildAsyncBlock(self: *Emitter, body_stmts: []const ast.Stmt) anyerror!js.Expr {
        const base = self.current_indent;
        const prev_ctx = self.loop_ctx;
        const prev_gen = self.in_generator;
        const prev_wrap = self.case_ok_wrap;
        const prev_in_test = self.in_test_body;
        const prev_expr_try = self.expr_try_used;
        self.loop_ctx = .none;
        self.in_generator = false;
        self.case_ok_wrap = false;
        self.in_test_body = false;
        self.expr_try_used = false;
        self.current_indent = base + 1;
        defer {
            self.loop_ctx = prev_ctx;
            self.in_generator = prev_gen;
            self.case_ok_wrap = prev_wrap;
            self.in_test_body = prev_in_test;
            self.expr_try_used = prev_expr_try;
            self.current_indent = base;
        }
        const body = try self.guardExprTry(try self.buildStmts(body_stmts), base);
        return self.b.call(try self.b.paren(.{ .function = .{
            .keyword = "async function",
            .params = &.{},
            .body = .{ .stmts = body, .indent = base },
        } }), &.{});
    }

    // ── @print ────────────────────────────────────────────────────────────────

    /// `@print`/`@println`/`@debug` (semantics decisions 1 and 1a) →
    /// `__bp_print(a, b)`: each argument's text through the `__bp_show` prelude
    /// helper, space-separated, one `console.log` line. A tuple is a JS array,
    /// so when an argument's static shape holds one the call passes the shapes
    /// first: `__bp_print_as([["#", null, null], null], a, b)`.
    fn buildPrintCall(self: *Emitter, cc: anytype) anyerror!js.Expr {
        const args = try self.arena().alloc(js.Expr, cc.args.len + 1);
        const shapes = try self.arena().alloc(js.Expr, cc.args.len);
        var shaped = false;
        for (cc.args, 0..) |a, i| {
            args[i + 1] = try self.buildExpr(a.value.*);
            shapes[i] = (try self.printShape(a.value.*)) orelse .null_;
            if (shapes[i] != .null_) shaped = true;
        }
        _ = self.helper(.show);
        if (!shaped) return self.b.call(self.helper(.print), args[1..]);
        args[0] = .{ .array = .{ .elems = shapes } };
        return self.b.call(self.helper(.print_as), args);
    }

    fn notePrintShape(self: *Emitter, name: []const u8, shape: ?js.Expr) !void {
        if (shape) |s| try self.print_shapes.put(name, s) else _ = self.print_shapes.remove(name);
    }

    /// The shape leaf for an `f64` — decision 8 § 7 prints one with its decimal
    /// part, and JavaScript has one number type, so the value's static type has
    /// to reach the formatter from here.
    const float_shape: js.Expr = .{ .quoted = "f" };

    /// True when a number literal's own spelling is a float (`5.0`, `1e3`).
    /// An integer literal in an `f64` position takes its shape from the
    /// declared type instead (`typeShape`).
    fn isFloatLiteral(text: []const u8) bool {
        return std.mem.indexOfAny(u8, text, ".eE") != null;
    }

    /// The static print shape of `e` — `["#", s1, s2]` for a tuple, `["[", s]`
    /// for an array, `"f"` for an `f64` — when a tuple or a float is known to
    /// sit somewhere in its value; null otherwise (the runtime text of an
    /// array or an integer needs none). Known from a tuple or float literal,
    /// an array literal of those, a local or a parameter bound to one, a
    /// top-level fn's declared return type, and a primitive method's declared
    /// return type (`zip` → `Array<#(T, U)>`).
    fn printShape(self: *Emitter, e: ast.Expr) anyerror!?js.Expr {
        return switch (e) {
            .literal => |lit| switch (lit.kind) {
                .numberLit => |n| if (isFloatLiteral(n)) float_shape else null,
                else => null,
            },
            .collection => |col| switch (col.kind) {
                .tupleLit => |tl| blk: {
                    const elems = try self.arena().alloc(js.Expr, tl.elems.len + 1);
                    elems[0] = .{ .quoted = "#" };
                    for (tl.elems, 0..) |el, i| elems[i + 1] = (try self.printShape(el)) orelse .null_;
                    break :blk .{ .array = .{ .elems = elems } };
                },
                .arrayLit => |al| if (al.elems.len > 0)
                    try self.arrayShape(try self.printShape(al.elems[0]))
                else
                    null,
                .grouped => |inner| self.printShape(inner.*),
                else => null,
            },
            .identifier => |id| switch (id.kind) {
                .ident => |n| self.print_shapes.get(n),
                else => null,
            },
            .call => |c| switch (c.kind) {
                .call => |cc| blk: {
                    if (cc.is_builtin) break :blk null;
                    if (cc.receiver == null) break :blk if (self.fn_return_types.get(cc.callee)) |rt| try self.typeShape(rt) else null;
                    const lw = self.lowerings orelse break :blk null;
                    const iface_name: []const u8 = switch (lw.get(c.loc) orelse break :blk null) {
                        .prim => |k| switch (k) {
                            .array => "Array",
                            .string => "String",
                            else => break :blk null,
                        },
                        .type_, .field_of, .sequence_next => break :blk null,
                    };
                    const iface = self.local_interfaces.get(iface_name) orelse break :blk null;
                    for (iface.methods) |m| {
                        if (!std.mem.eql(u8, m.name, cc.callee)) continue;
                        break :blk if (m.returnType) |rt| try self.typeShape(rt) else null;
                    }
                    break :blk null;
                },
                else => null,
            },
            else => null,
        };
    }

    /// The print shape a declared type spells (see `printShape`).
    fn typeShape(self: *Emitter, t: ast.TypeRef) anyerror!?js.Expr {
        return switch (t) {
            .tuple_, .labeledTuple => blk: {
                const elems = t.tupleElems().?;
                const out = try self.arena().alloc(js.Expr, elems.len + 1);
                out[0] = .{ .quoted = "#" };
                for (elems, 0..) |el, i| out[i + 1] = (try self.typeShape(el)) orelse .null_;
                break :blk .{ .array = .{ .elems = out } };
            },
            .array => |inner| self.arrayShape(try self.typeShape(inner.*)),
            .generic => |g| if (g.args.len == 1 and std.mem.eql(u8, g.name, "Array"))
                self.arrayShape(try self.typeShape(g.args[0]))
            else
                null,
            .optional => |inner| self.typeShape(inner.*),
            .named => |n| if (std.mem.eql(u8, n, "f64") or std.mem.eql(u8, n, "f32")) float_shape else null,
            else => null,
        };
    }

    /// True when either side of a comparison is statically known to hold a
    /// tuple — its print shape starts with `"#"`, the same fact `@print` reads
    /// to write `#(1, "a")` instead of `[1, "a"]`.
    fn isTupleShaped(self: *Emitter, lhs: ast.Expr, rhs: ast.Expr) anyerror!bool {
        return isTupleShape(try self.printShape(lhs)) or isTupleShape(try self.printShape(rhs));
    }

    fn isTupleShape(shape: ?js.Expr) bool {
        const s = shape orelse return false;
        if (s != .array or s.array.elems.len == 0) return false;
        const head = s.array.elems[0];
        return head == .quoted and std.mem.eql(u8, head.quoted, "#");
    }

    /// `["[", elem]`, or null when the element shape holds no tuple.
    fn arrayShape(self: *Emitter, elem: ?js.Expr) !?js.Expr {
        const s = elem orelse return null;
        return .{ .array = .{ .elems = try self.b.exprs(&.{ .{ .quoted = "[" }, s }) } };
    }

    // ── calls ─────────────────────────────────────────────────────────────────

    /// Try lowering an `@builtin(…)` call from its `#[@External.Node(…)]`
    /// annotation. Returns null when no annotation is registered.
    fn tryBuiltinAnnotation(self: *Emitter, callee: []const u8, cc: anytype) anyerror!?js.Expr {
        const call = self.builtin_node_dispatch.get(callee) orelse return null;
        return self.renderDispatch(call, cc, error.PrimOpRecvInBuiltinTemplate);
    }

    /// §A2 user-fn template dispatch (commonJS): when a `declare fn`'s
    /// `#[@External.Node(…)]` annotation is a template string (with `$0`/`$1`/…
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

    /// Which sequence a `.next()` at `loc` steps, from inference's per-call-site
    /// `.sequence_next` record (decision 122), or null.
    fn sequenceNext(self: *Emitter, loc: ast.Loc) ?envMod.SequenceKind {
        const lw = self.lowerings orelse return null;
        return switch (lw.get(loc) orelse return null) {
            .sequence_next => |k| k,
            else => null,
        };
    }

    /// The prelude helper for `recv.method(args)` on a typed primitive
    /// receiver, from inference's per-call-site `.prim` record.
    fn primHelper(self: *Emitter, loc: ast.Loc, cc: anytype) ?jsPrelude.Helper {
        if (cc.trailing.len != 0) return null;
        const lw = self.lowerings orelse return null;
        const il = lw.get(loc) orelse return null;
        const kind = switch (il) {
            .prim => |k| k,
            .type_, .field_of, .sequence_next => return null,
        };
        const receiver: jsPrelude.Receiver = switch (kind) {
            .string => .string,
            .array => .array,
            else => .other,
        };
        return jsPrelude.forMethod(receiver, cc.callee, cc.args.len);
    }

    fn renderTemplate(self: *Emitter, template: []const u8, cc: anytype, argc: usize, recv_err: anyerror) anyerror!js.Expr {
        const Holes = CallHoles(@TypeOf(cc));
        var holes = Holes{ .em = self, .cc = cc, .err = recv_err };
        var tmpl = HostTemplate(Holes){ .arena = self.arena(), .holes = &holes, .argc = argc };
        try primOpTemplate.render(template, &tmpl);
        return tmpl.finish();
    }

    /// The index of `name` in `names`, or null.
    fn slotIndexOf(names: []const []const u8, name: []const u8) ?usize {
        for (names, 0..) |n, i| if (std.mem.eql(u8, n, name)) return i;
        return null;
    }

    /// The declared fields of the variant `name`, when `recv` is the very enum
    /// that declares it (`Shape.Rect`). A variant's slots are only claimable
    /// by label through its own enum: any other receiver is a value, and the
    /// callee is then a method that happens to share the spelling.
    fn variantSlotsFor(self: *Emitter, recv: ast.Expr, name: []const u8) ?[]const []const u8 {
        const owner = switch (recv) {
            .identifier => |id| switch (id.kind) {
                .ident => |n| n,
                else => return null,
            },
            else => return null,
        };
        const declared = self.variant_owner.get(name) orelse return null;
        if (declared.len == 0) return null; // two enums declare it — see `variant_owner`
        if (!std.mem.eql(u8, declared, owner)) return null;
        return self.variant_fields.get(name);
    }

    /// `docs.md` § Parameters with defaults — "a parameter the call names by
    /// label keeps the argument it was given, **whichever position it is in**".
    /// The arguments of a fully-written labelled call, moved into the slots
    /// their labels name; null when the call is not that shape, and the
    /// positional path then emits exactly what it emitted before.
    ///
    /// Every argument must carry a label, every label must name a distinct
    /// declared slot, and the call must fill every slot. Anything else — a
    /// call mixing labelled and positional arguments, a label naming no field,
    /// a trailing lambda — is left alone rather than placed on a guess
    /// (decision 67). A partly-labelled call reaches here after the checker's
    /// default fill, whose injected arguments are already in declared order.
    ///
    /// A re-ordered call evaluates its arguments in DECLARED order, not
    /// written order: JS evaluates an argument list left to right, and the
    /// list this writes is the declared one. Erlang and wasm place a labelled
    /// argument the same way and evaluate the same order, so the three agree;
    /// it is worth knowing only for an argument expression with a side effect.
    fn labelledArgs(self: *Emitter, slots: []const []const u8, cc: anytype) !?[]js.Expr {
        if (cc.trailing.len > 0) return null;
        if (slots.len == 0 or cc.args.len != slots.len) return null;
        const at = try self.arena().alloc(usize, cc.args.len);
        var filled = try self.arena().alloc(bool, slots.len);
        @memset(filled, false);
        for (cc.args, 0..) |arg, i| {
            const label = arg.label orelse return null;
            const idx = slotIndexOf(slots, label) orelse return null;
            if (filled[idx]) return null;
            filled[idx] = true;
            at[i] = idx;
        }
        const out = try self.arena().alloc(js.Expr, slots.len);
        for (cc.args, 0..) |arg, i| out[at[i]] = try self.buildExpr(arg.value.*);
        return out;
    }

    fn buildCall(self: *Emitter, loc: ast.Loc, cc: anytype) anyerror!js.Expr {
        const out = try self.buildCallRaw(loc, cc);
        // Decision 126 — a host call declared `-> @Task<@Result<T, E>>`.
        if (!cc.is_builtin and cc.receiver == null and self.host_task_externals_init and
            self.host_task_externals.contains(cc.callee))
        {
            return self.b.call(self.helper(.host_task), &.{out});
        }
        return out;
    }

    fn buildCallRaw(self: *Emitter, loc: ast.Loc, cc: anytype) anyerror!js.Expr {
        if (cc.is_builtin) return self.buildBuiltinCall(cc);
        // builtin_node_dispatch: `declare fn` with `#[@External.Node]`.
        // Handles both template (`$0.method()`) and module+symbol
        // (`"./mod", "fun"`) forms discovered from primitives.bp +
        // builtins_fns.d.bp. Those are free functions: their templates have
        // no receiver hole, so a method call `recv.print()` is never one — it
        // used to render `console.log()` and drop the receiver.
        if (cc.receiver == null and self.builtin_node_dispatch.contains(cc.callee)) {
            if (try self.tryBuiltinAnnotation(cc.callee, cc)) |node| return node;
            // Fall through to a plain call if annotation dispatch fails.
        }

        var args: std.ArrayListUnmanaged(js.Expr) = .empty;
        var callee: js.Expr = undefined;
        var is_new = false;
        // The declared slot names of the call's target, when this backend
        // knows them — what a labelled argument claims (`labelledArgs`). Left
        // null on every path that PREPENDS a receiver to `args`, because the
        // names would then no longer line up with the argument list.
        var slots: ?[]const []const u8 = null;

        if (cc.calleeExpr) |ce| {
            // `adder(3)(4)` — what is called is the VALUE of an expression
            // (01 handover 15): the callee travels in `calleeExpr` with
            // `callee == ""`, and writing `callee` dropped it (`(4)`).
            const target = try self.buildExpr(ce.*);
            callee = if (target == .arrow or target == .function) try self.b.paren(target) else target;
        } else if (cc.receiver) |recv| {
            // Decision 122 — `seq.next()` by hand: the generator's own
            // `{ value, done }` becomes the prelude `YieldStep` —
            // `__bp_yield_step(it.next())` on an `@Iterator`, and
            // `s.next().then(__bp_yield_step)` on a `@Stream`, whose `next()`
            // is a Promise.
            if (self.sequenceNext(loc)) |kind| {
                const native = try self.b.call(try self.b.memberOpt(try self.buildExpr(recv.*), "next", cc.optional), &.{});
                const step = self.helper(.yield_step);
                return switch (kind) {
                    .iterator => self.b.call(step, &.{native}),
                    .stream => self.b.call(try self.b.member(native, "then"), &.{step}),
                };
            }
            // Static extension dispatch: lower `recv.m(args)` to
            // `Sym.m(recv, args)` at activated call sites.
            if (self.rewrites.get(loc)) |sym| {
                callee = try self.b.member(.{ .name = sym }, cc.callee);
                try args.append(self.arena(), try self.buildExpr(recv.*));
            } else if (if (cc.optional) null else try self.enumMethodOwner(loc, cc.callee)) |owner| {
                // An enum method: the value is the first argument.
                callee = try self.b.member(.{ .name = owner }, cc.callee);
                try args.append(self.arena(), try self.buildExpr(recv.*));
            } else if (self.primHelper(loc, cc)) |hp| {
                // A primitive method whose native JS method disagrees with
                // the signature: `__bp_helper(recv, args)` (`js/js_prelude.zig`).
                callee = self.helper(hp);
                try args.append(self.arena(), try self.buildExpr(recv.*));
            } else {
                const recv_node = try self.buildExpr(recv.*);
                // §A4 rename: a 2-arg `#[@External.Node("X")]` on a primitive
                // interface method routes `recv.callee(args)` to
                // `recv.X(args)`. The per-loc `renames` map (populated by
                // inference's type-directed lookup) is consulted FIRST so a
                // collision-prone name (`String.contains` vs `Set.contains`)
                // lands the right rename. The type-naive `prim_node_renames`
                // map (built from annotations at init) is the fallback for
                // calls inference doesn't visit — interface default-fn bodies
                // materialised as prototype patches (`out.append(inner)`
                // inside `flatten`).
                // 06 N24 — a tuple element called by position (`c._1(9)`,
                // what a labelled `c.set(9)` becomes): a tuple is a JS array,
                // so the callee is an INDEX, never a property name.
                if (tupleIndexMember(cc.callee)) |idx| {
                    const elem = try self.b.index(recv_node, .{ .number = idx }, cc.optional);
                    for (cc.args) |arg| try args.append(self.arena(), try self.buildExpr(arg.value.*));
                    for (cc.trailing) |tl| try args.append(self.arena(), try self.buildArrow(tl.params, tl.body));
                    return self.b.call(elem, try args.toOwnedSlice(self.arena()));
                }
                const loc_rename: ?[]const u8 = if (self.renames) |r| r.get(loc) else null;
                const method = loc_rename orelse self.prim_node_renames.get(cc.callee) orelse cc.callee;
                // `arr.len()`/`.size()`/`.length()` & `str.length()`: inference
                // renamed these to `length` only for a typed array/string
                // receiver — the native `.length` is a PROPERTY, so it is a
                // member access with no call parens or args.
                const len_prop = cc.args.len == 0 and cc.trailing.len == 0 and
                    if (loc_rename) |rn| std.mem.eql(u8, rn, "length") else false;
                if (len_prop) return self.b.memberOpt(recv_node, "length", cc.optional);
                // `Shape.Rect(width: 5, height: 2)` — an enum variant reached
                // through its own enum. The variant's declared fields are the
                // slots; the guard is that the receiver names the enum that
                // DECLARES the variant, so a record method that happens to be
                // spelled `Rect` is never re-ordered.
                if (self.variantSlotsFor(recv.*, cc.callee)) |names| slots = names;
                callee = try self.b.memberOpt(recv_node, method, cc.optional);
            }
        } else if (self.externals_missing.contains(cc.callee)) {
            // External fn with no `node` target — no symbol to call on this
            // backend.
            self.missing_external = .{ .name = cc.callee, .target = "node", .loc = loc };
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
            slots = self.record_fields.get(cc.callee);
        } else {
            callee = .{ .ident = cc.callee };
            // A variant named bare (`Rect(width: 5, height: 2)`), which the
            // enum's static factory answers under the same slot names.
            if (self.variant_fields.get(cc.callee)) |names| slots = names;
        }

        const by_label: ?[]js.Expr = if (slots) |names| try self.labelledArgs(names, cc) else null;
        if (by_label) |placed| {
            try args.appendSlice(self.arena(), placed);
        } else {
            for (cc.args) |arg| try args.append(self.arena(), try self.buildExpr(arg.value.*));
        }
        for (cc.trailing) |tl| try args.append(self.arena(), try self.buildArrow(tl.params, tl.body));

        const arg_slice = try args.toOwnedSlice(self.arena());
        return if (is_new) self.b.new_(callee, arg_slice) else self.b.call(callee, arg_slice);
    }

    /// The inclusive range of an integer type, as JS number literals, or null
    /// when the type is not a sized integer. `i64` / `u64` carry no range: a JS
    /// number cannot represent their ends exactly, so the test is
    /// `Number.isInteger` (plus `>= 0` for the unsigned one).
    fn integerRange(name: []const u8) ?struct { lo: ?[]const u8, hi: ?[]const u8 } {
        const table = .{
            .{ "i8", "-128", "127" },                .{ "i16", "-32768", "32767" },
            .{ "i32", "-2147483648", "2147483647" }, .{ "u8", "0", "255" },
            .{ "u16", "0", "65535" },                .{ "u32", "0", "4294967295" },
        };
        inline for (table) |row| {
            if (std.mem.eql(u8, name, row[0])) return .{ .lo = row[1], .hi = row[2] };
        }
        if (std.mem.eql(u8, name, "i64") or std.mem.eql(u8, name, "int") or
            std.mem.eql(u8, name, "isize")) return .{ .lo = null, .hi = null };
        if (std.mem.eql(u8, name, "u64") or std.mem.eql(u8, name, "uint") or
            std.mem.eql(u8, name, "usize")) return .{ .lo = "0", .hi = null };
        return null;
    }

    /// `typeof <subject> === "<what>"`.
    fn typeofIs(self: *Emitter, subject: js.Expr, what: []const u8) !js.Expr {
        return self.b.binaryBare("===", try self.b.unary("typeof ", subject, false), .{ .quoted = what });
    }

    /// How many times `isTest` reads its subject for `t` — one read can be
    /// spelled inline, more than one needs the subject bound first.
    fn isTestReads(t: ast.TypeRef) usize {
        return switch (t) {
            // `Enum.Variant`: the class test and the `tag` read (`isTest`).
            .named => |n| if (isVariantPath(n)) 2 else if (integerRange(n)) |r| blk: {
                var k: usize = 2; // typeof + Number.isInteger
                if (r.lo != null) k += 1;
                if (r.hi != null) k += 1;
                break :blk k;
            } else 1,
            .optional => |inner| 1 + isTestReads(inner.*),
            .tuple_, .labeledTuple => blk: {
                var k: usize = 2; // Array.isArray + .length
                for (t.tupleElems().?) |e| k += isTestReads(e);
                break :blk k;
            },
            else => 1,
        };
    }

    /// Decision 8 §4 — `x is T` **tests the value**, never where it came from,
    /// which is what makes it answer for a `unknown` or a union member as well
    /// as for a value whose static type is known. An integer type is a number
    /// within its range, `f64` any number, `string` / `bool` the primitive, a
    /// tuple an array of the right arity with each element tested, `?T` null or
    /// `T`, and a **named type** an `instanceof` — free under decision 5,
    /// because the value's prototype is its identity.
    ///
    /// An array's element type is not tested (§4.2 only promises the
    /// constructor), and an unknown spelling answers `false` rather than
    /// emitting something that is not JavaScript.
    fn isTest(self: *Emitter, t: ast.TypeRef, subject: js.Expr) anyerror!js.Expr {
        switch (t) {
            .named => |n| {
                if (std.mem.eql(u8, n, "string")) return self.typeofIs(subject, "string");
                if (std.mem.eql(u8, n, "bool")) return self.typeofIs(subject, "boolean");
                if (std.mem.eql(u8, n, "f32") or std.mem.eql(u8, n, "f64") or
                    std.mem.eql(u8, n, "float")) return self.typeofIs(subject, "number");
                if (integerRange(n)) |r| {
                    var acc = try self.b.binaryBare("&&", try self.typeofIs(subject, "number"), try self.b.call(
                        try self.b.member(.{ .name = "Number" }, "isInteger"),
                        &.{subject},
                    ));
                    if (r.lo) |lo| acc = try self.b.binaryBare("&&", acc, try self.b.binaryBare(">=", subject, .{ .number = lo }));
                    if (r.hi) |hi| acc = try self.b.binaryBare("&&", acc, try self.b.binaryBare("<=", subject, .{ .number = hi }));
                    return self.b.paren(acc);
                }
                if (std.mem.eql(u8, n, "unknown")) return .{ .name = "true" };
                if (isVariantPath(n)) return self.variantIsTest(n, subject);
                return self.b.binaryBare("instanceof", subject, .{ .name = n });
            },
            // `T[]` / `Array<T>`: the constructor only (§4.2 — an element type
            // is not checkable).
            .array => return self.b.call(try self.b.member(.{ .name = "Array" }, "isArray"), &.{subject}),
            .generic => |g| {
                if (std.mem.eql(u8, g.name, "Array")) {
                    return self.b.call(try self.b.member(.{ .name = "Array" }, "isArray"), &.{subject});
                }
                return self.b.binaryBare("instanceof", subject, .{ .name = g.name });
            },
            .optional => |inner| return self.b.paren(try self.b.binaryBare(
                "||",
                try self.b.binaryBare("==", subject, .null_),
                try self.isTest(inner.*, subject),
            )),
            .tuple_, .labeledTuple => {
                const elems = t.tupleElems().?;
                var acc = try self.b.call(try self.b.member(.{ .name = "Array" }, "isArray"), &.{subject});
                acc = try self.b.binaryBare("&&", acc, try self.b.binaryBare(
                    "===",
                    try self.b.member(subject, "length"),
                    .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{elems.len}) },
                ));
                for (elems, 0..) |e, i| {
                    const at = try self.b.index(subject, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{i}) }, false);
                    acc = try self.b.binaryBare("&&", acc, try self.isTest(e, at));
                }
                return self.b.paren(acc);
            },
            // A function type and a comptime typeparam have no run-time test.
            .function, .typeparam => return .{ .name = "false" },
        }
    }

    /// `x is Enum.Variant`. `Enum.Variant` is the variant's constructor (a
    /// static factory) or its singleton, never a class, so `instanceof` on the
    /// written path threw `TypeError` at run time. A variant is its enum's
    /// class plus the `tag` its prototype carries — the same `tag` a `case`
    /// arm tests (`patternTest`) — so the test is
    /// `(x instanceof Enum && x.tag === "Variant")` when `Enum` is an enum
    /// this module declares with that variant, or one it imports by name.
    /// Any other path (a section's inner enum, which no module exports as a
    /// class) is tested by its `tag` alone, guarded against `null`.
    fn variantIsTest(self: *Emitter, path: []const u8, subject: js.Expr) anyerror!js.Expr {
        const dot = std.mem.lastIndexOfScalar(u8, path, '.').?;
        const owner = path[0..dot];
        const tag_test = try self.b.binaryBare("===", try self.b.member(subject, "tag"), .{ .quoted = path[dot + 1 ..] });
        const known = owner.len > 0 and (self.enum_variant_paths.contains(path) or
            (!isVariantPath(owner) and self.imported_enums.contains(owner)));
        const guard = if (known)
            try self.b.binaryBare("instanceof", subject, .{ .name = owner })
        else
            try self.b.binaryBare("!=", subject, .null_);
        return self.b.paren(try self.b.binaryBare("&&", guard, tag_test));
    }

    /// `x is T` (`ast.is_builtin_name`). The subject is bound first when the
    /// test reads it more than once, so a call on the left is evaluated once.
    fn buildIsCall(self: *Emitter, cc: anytype) anyerror!js.Expr {
        const t = cc.isType orelse return error.InvalidArgs;
        if (cc.args.len != 1) return error.InvalidArgs;
        const subject = try self.buildExpr(cc.args[0].value.*);
        if (isTestReads(t) <= 1) return self.isTest(t, subject);
        return self.b.call(
            try self.b.paren(try self.b.arrowExpr(
                &.{.{ .pattern = .{ .name = "_v" } }},
                try self.isTest(t, .{ .name = "_v" }),
            )),
            &.{subject},
        );
    }

    /// `receiver[index]` (`ast.index_builtin_name`, decision 30). One node
    /// carries the element read and the slice, because the index is an ordinary
    /// expression: a `range` index is `.slice(start, end)` — `.slice(start)`
    /// when the range is open-ended, which is the only place an open-ended
    /// range is *not* the lazy `__bp_range_from` generator — and any other
    /// index is a JS index, which answers an array's element, a tuple's member
    /// (a tuple is a JS array) and a string's character alike.
    fn buildIndexCall(self: *Emitter, cc: anytype) anyerror!js.Expr {
        if (cc.args.len != 2) return error.InvalidArgs;
        const recv = try self.buildExpr(cc.args[0].value.*);
        const idx = cc.args[1].value.*;
        if (idx == .collection and idx.collection.kind == .range) {
            const r = idx.collection.kind.range;
            const slice = try self.b.member(recv, "slice");
            const start = try self.buildExpr(r.start.*);
            const end = r.end orelse return self.b.call(slice, &.{start});
            return self.b.call(slice, &.{ start, try self.buildExpr(end.*) });
        }
        return self.b.index(recv, try self.buildExpr(idx), false);
    }

    fn buildBuiltinCall(self: *Emitter, cc: anytype) anyerror!js.Expr {
        if (std.mem.eql(u8, cc.callee, "print") or std.mem.eql(u8, cc.callee, "println") or std.mem.eql(u8, cc.callee, "debug"))
            return self.buildPrintCall(cc);
        if (std.mem.eql(u8, cc.callee, ast.is_builtin_name) and cc.isType != null)
            return self.buildIsCall(cc);
        if (std.mem.eql(u8, cc.callee, ast.index_builtin_name))
            return self.buildIndexCall(cc);
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

    /// The variant a pattern names, without the path it was **written** with:
    /// `Shape.Circle`, `.Circle` and `Circle` all name `Circle` (decision 8
    /// §5.1 P8). The constructor writes the bare name onto
    /// `<Variant>.prototype.tag`, so an arm that tests the written path never
    /// matches; `ast.Pattern` says a `name` carrying a `.` is a variant path
    /// and never a binding.
    fn bareVariantName(name: []const u8) []const u8 {
        const i = std.mem.lastIndexOfScalar(u8, name, '.') orelse return name;
        return name[i + 1 ..];
    }

    /// True when a `Pattern.ident` is a variant path (`Maybe.None`, `.None`)
    /// rather than a name to bind.
    fn isVariantPath(name: []const u8) bool {
        return std.mem.indexOfScalar(u8, name, '.') != null;
    }

    /// True when a bare pattern name spells a **primitive type**, which makes
    /// the arm decision 8 §5.2's type test (`case x { i32 { … } string { … } }`)
    /// rather than a variant or a binding. The set is exactly the spellings
    /// `isTest` answers for: a variant is capitalised, and §5.2 says a
    /// lower-case name alone is not a binding.
    fn primitiveTypeName(name: []const u8) bool {
        if (integerRange(name) != null) return true;
        return std.mem.eql(u8, name, "string") or std.mem.eql(u8, name, "bool") or
            std.mem.eql(u8, name, "f32") or std.mem.eql(u8, name, "f64") or
            std.mem.eql(u8, name, "float");
    }

    /// True when a bare name is declared as an enum VARIANT by this module —
    /// payload-less (`Block`) or carrying one (`Position`). A variant name
    /// wins over every other meaning the spelling has in scope: a `case` arm
    /// naming it is decision 8 §5.2's variant arm, never §3.3's type test,
    /// because the type it would name cannot inhabit the enum being cased.
    fn isDeclaredVariantName(self: *Emitter, bare: []const u8) bool {
        return self.unit_variant_names.contains(bare) or self.variant_fields.contains(bare);
    }

    /// True when a `Pattern.ident` **binds** rather than tests: it is not a
    /// path, not a primitive type spelling, not a variant this module declares,
    /// and it is not capitalised — which is how decision 8 §5 tells `Red` and
    /// `.None` (a variant) from the `s` of `#(0, s)` (a binding). A binding
    /// matches anything, so it contributes no test.
    fn isBindingName(self: *Emitter, name: []const u8) bool {
        if (name.len == 0) return false;
        if (isVariantPath(name) or primitiveTypeName(name)) return false;
        if (self.unit_variant_names.contains(name) or self.variant_fields.contains(name)) return false;
        return !std.ascii.isUpper(name[0]);
    }

    fn isLambdaBlock(e: ast.Expr) bool {
        return switch (e) {
            .function => |f| f.kind.syntax == .lambda,
            else => false,
        };
    }

    /// The `break <value>` an arm block carries, if any. It wins over the
    /// block's final expression as the arm's value.
    fn armBreakValue(stmts: []const ast.Stmt) bool {
        for (stmts) |st| switch (st.expr) {
            .jump => |j| switch (j.kind) {
                .@"break" => |b| if (b.value != null) return true,
                else => {},
            },
            else => {},
        };
        return false;
    }

    /// True when an arm block's final statement is the arm's **value**, so it
    /// is returned instead of being dropped as a statement (decision 8 §5: an
    /// arm's value is its body's last expression). Only the expression kinds
    /// that are unambiguously values qualify — a trailing `val`, `if`, `loop`
    /// or jump is a statement and stays one, so no existing lowering moves.
    fn isArmValueExpr(e: ast.Expr) bool {
        return switch (e) {
            .literal, .identifier, .binaryOp, .unaryOp, .call, .collection, .function => true,
            .jump, .branch, .loop, .binding, .useHook, .comptime_ => false,
        };
    }

    /// The statements of a matched arm body: an inlined lambda block (with a
    /// loop-accumulator `break` turned into the arm's `return`, and otherwise
    /// its final expression returned as the arm's value), or a single
    /// `return <expr>;`.
    ///
    /// A one-parameter arm block (`_ { v -> … }`) names the whole subject: the
    /// parameter is bound to `_s` at the top of the arm, which is the only
    /// place it can be bound (the checker types it as the subject narrowed by
    /// the arm's pattern).
    fn buildCaseBody(self: *Emitter, body: ast.Expr, indent: usize) anyerror![]const js.Stmt {
        if (!isLambdaBlock(body)) {
            return self.b.stmts(&.{try self.armReturn(body)});
        }
        const l = body.function.kind;
        self.current_indent = indent;
        var out: std.ArrayListUnmanaged(js.Stmt) = .empty;
        if (l.params.len == 1) try out.append(self.arena(), .{ .decl = .{
            .pattern = .{ .ident = l.params[0] },
            .value = .{ .name = "_s" },
        } });
        const tail_is_value = !armBreakValue(l.body) and
            l.body.len > 0 and isArmValueExpr(l.body[l.body.len - 1].expr);
        for (l.body, 0..) |st, i| {
            const br: ?ast.Expr = switch (st.expr) {
                .jump => |j| switch (j.kind) {
                    .@"break" => |b| if (b.value) |bp| bp.* else null,
                    else => null,
                },
                else => null,
            };
            if (br) |val| {
                try out.append(self.arena(), try self.armReturn(val));
            } else if (tail_is_value and i + 1 == l.body.len) {
                try out.append(self.arena(), try self.armReturn(st.expr));
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
            // A bare name is a payload-less variant (a lower-case name alone is
            // not an arm — decision 8 § 5.2). A variant's identity is the
            // `tag` its prototype carries, never the JS class the singleton
            // is an instance of, so the test is the same one here, in a
            // sibling module and in a consuming package.
            //
            // It used to be `instanceof <Enum>$<Variant>` whenever the bare
            // name was unique in the module, and `tag` only when the name
            // repeated. A class is per-EMITTED-COPY identity, and a copy is
            // emitted per module for every enum a module cannot `require` —
            // an enum section desugars into an inner enum that no module
            // exports, so `Token.Text.Size` is re-emitted in each module that
            // names it. A value built against one copy is not `instanceof`
            // another copy's class, so the arm silently did not fire and the
            // whole `case` answered `undefined` — at exit 0, with no
            // diagnostic. `tag` is a string on the prototype, so it crosses
            // every copy, every module and every package boundary, and it is
            // what `variantTest` and the payload arms have always used.
            .ident => |n| {
                const bare = bareVariantName(n);
                // A primitive type spelling is decision 8 §5.2's type-test arm
                // (`case x { i32 { … } string { … } }`), tested by §4.1's
                // run-time test — the same one `x is T` builds.
                if (primitiveTypeName(bare)) return try self.isTest(.{ .named = bare }, subject);
                // A binding (`#(0, s)`'s `s`) matches anything. It is asked
                // BEFORE the type test below: a name the arm binds stays a
                // binding even when a record of the module happens to share it.
                if (self.isBindingName(n)) return null;
                // Decision 8 §3.3 — an arm naming a `type` is chosen by the
                // VALUE's own type: on this backend a record IS its class
                // (decision 5), so the arm is the same `instanceof` `x is T`
                // builds. Written as the `tag` test below it answered `false`
                // for every class instance, and a `case` over `Person | Vec`
                // fell through both arms to `undefined`.
                //
                // One spelling can be BOTH — a `type Block(…)` in scope and a
                // `Block` variant of an enum this module declares. §5.3b says
                // which one an arm means: the SUBJECT's type does, and a
                // section's variants are written bare (`Bold`, `Size(s)`), so
                // the arm over `Token.Layout` is the variant even where a
                // record `Block` is in scope. This emitter walks the untyped
                // AST and has no subject type, so it tests BOTH: the subject's
                // own type makes at most one of the two possible — a variant
                // singleton is not `instanceof` any class, and a class
                // instance carries no `tag`. Emitted as the `instanceof`
                // alone, emilia's `Token.Layout` arm never fired and
                // `tokenDeclarations(.Layout.Block)` answered `undefined` at
                // exit 0, where erlang and wasm answered `display:block`.
                const tag_test = try self.b.binaryBare("===", try self.b.member(subject, "tag"), .{ .quoted = bare });
                if (self.class_names.contains(bare)) {
                    const class_test = try self.isTest(.{ .named = bare }, subject);
                    if (!self.isDeclaredVariantName(bare)) return class_test;
                    return try self.b.paren(try self.b.binaryBare("||", class_test, tag_test));
                }
                return tag_test;
            },
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
            // `#(a, b)` / `#(0, s)` (§5.1 P6): a tuple is a JS array, so the
            // test is the arity plus whatever test each element carries — `..`
            // makes the arity a lower bound.
            .variant => |v| switch (v.shape) {
                .tuple => {
                    const elems = switch (v.payload) {
                        .literals => |l| l,
                        else => return js.Expr{ .name = "false" },
                    };
                    var acc = try self.b.call(try self.b.member(.{ .name = "Array" }, "isArray"), &.{subject});
                    acc = try self.b.binaryBare("&&", acc, try self.b.binaryBare(
                        if (v.rest) ">=" else "===",
                        try self.b.member(subject, "length"),
                        .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{elems.len}) },
                    ));
                    for (elems, 0..) |p, i| {
                        const at = try self.b.index(subject, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{i}) }, false);
                        const t = try self.patternTest(p, at) orelse continue;
                        acc = try self.b.binaryBare("&&", acc, t);
                    }
                    return try self.b.paren(acc);
                },
                // `1...9` (§5.2): an inclusive range, both ends included.
                .range => {
                    const bounds = switch (v.payload) {
                        .literals => |l| l,
                        else => return js.Expr{ .name = "false" },
                    };
                    if (bounds.len != 2) return js.Expr{ .name = "false" };
                    const lo = try self.patternBoundExpr(bounds[0]) orelse return js.Expr{ .name = "false" };
                    const hi = try self.patternBoundExpr(bounds[1]) orelse return js.Expr{ .name = "false" };
                    return try self.b.paren(try self.b.binaryBare(
                        "&&",
                        try self.b.binaryBare(">=", subject, lo),
                        try self.b.binaryBare("<=", subject, hi),
                    ));
                },
                .variant => return try self.variantTest(v, subject),
            },
            .list => return js.Expr{ .name = "false" },
        }
    }

    /// A range pattern's bound as a JS literal, or null for a spelling that is
    /// not one (`1...9` and `"a"..."z"` are the forms §5.2 has).
    fn patternBoundExpr(self: *Emitter, pat: ast.Pattern) anyerror!?js.Expr {
        _ = self;
        return switch (pat) {
            .numberLit => |n| js.Expr{ .number = n },
            .stringLit => |s| js.Expr{ .lexeme_string = s },
            else => null,
        };
    }

    /// The test a `.variant`-shaped pattern becomes: the `tag` compare (or the
    /// `@Result` key test for an `Ok`/`Err` naming no declared variant), and
    /// then whatever test each nested payload pattern carries — `Ok(1)` tests
    /// the payload, `.Some(#(a, b))` tests the tuple.
    fn variantTest(self: *Emitter, v: anytype, subject: js.Expr) anyerror!js.Expr {
        const bare = bareVariantName(v.name);
        const declared = self.variant_fields.get(bare);
        if (declared == null) if (resultKey(bare)) |key| {
            return try self.b.binaryBare("in", .{ .quoted = key }, subject);
        };
        var acc = try self.b.binaryBare("===", try self.b.member(subject, "tag"), .{ .quoted = bare });
        if (v.payload == .literals) for (v.payload.literals, 0..) |p, i| {
            const key = variantFieldKey(v, declared, i) orelse continue;
            const t = try self.patternTest(p, try self.b.member(subject, key)) orelse continue;
            acc = try self.b.binaryBare("&&", acc, t);
        };
        return acc;
    }

    /// The field a variant pattern's payload element at `i` reads: the label
    /// the pattern **wrote** when it wrote one (`.Rect(height: h, width: w)`
    /// reads `height` for `h`, not the declared field at position 0), and
    /// otherwise the declared field at that position (§5.1 P4). Null when the
    /// variant is not declared in this module, which leaves the caller its own
    /// fallback.
    fn variantFieldKey(v: anytype, declared: ?[]const []const u8, i: usize) ?[]const u8 {
        if (v.labels.len > i and v.labels[i].len > 0) return v.labels[i];
        const d = declared orelse return null;
        if (i >= d.len) return null;
        return d[i];
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
                if (arm.pattern == .ident and arm.guard != null and self.isBindingName(arm.pattern.ident)) {
                    // A guarded identifier binds the subject, then tests the guard.
                    // A dotted `.ident` is a variant path (`Maybe.None`), a
                    // capitalised one a variant and a primitive spelling §5.2's
                    // type test (`i32 when (…)`); none of the three is a
                    // binding, so they take the test path below.
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

            // Every `.variant`-shaped pattern — decision 8 §5's variant, its
            // `#(a, b)` tuple (P6) and its `1...9` range (§5.2) alike — is the
            // conjunction `patternTest` builds over `_s`, then the bindings
            // `appendPatternBinds` takes from it. The two are the same pair a
            // `val assert` uses, so a pattern gains a shape in one place.
            .variant => {
                var body: std.ArrayListUnmanaged(js.Stmt) = .empty;
                try self.appendPatternBinds(&body, arm.pattern, subject);
                for (try self.buildMatchedBody(arm, indent + 1)) |s| try body.append(self.arena(), s);
                const block = js.Stmt{ .block = .{ .stmts = try body.toOwnedSlice(self.arena()), .indent = indent } };
                const cond = try self.patternTest(arm.pattern, subject) orelse return block;
                return self.b.ifStmt(cond, block);
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

    /// The `const` declarations a pattern's names take from `subject`, in the
    /// scope the caller is building. A `case` arm builds them at the top of its
    /// arm block; a `val assert` (decision 8 § 9) builds them in the enclosing
    /// block, where the statements after it read them.
    fn appendPatternBinds(
        self: *Emitter,
        body: *std.ArrayListUnmanaged(js.Stmt),
        pat: ast.Pattern,
        subject: js.Expr,
    ) anyerror!void {
        switch (pat) {
            // A name that spells a type (`i32`) or a variant path (`.None`)
            // is a test, not a binding (§5.2), so only a plain name binds.
            .ident => |n| {
                if (!self.isBindingName(n)) return;
                try body.append(self.arena(), .{ .decl = .{
                    .pattern = .{ .ident = n },
                    .value = subject,
                } });
            },
            .variant => |v| {
                // `#(a, b)` (§5.1 P6): a tuple is a JS array, so each element
                // pattern binds from `subject[i]`; `1...9` binds nothing.
                if (v.shape == .tuple) {
                    if (v.payload != .literals) return;
                    for (v.payload.literals, 0..) |p, i| try self.appendPatternBinds(
                        body,
                        p,
                        try self.b.index(subject, .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{i}) }, false),
                    );
                    return;
                }
                if (v.shape == .range) return;
                const bare = bareVariantName(v.name);
                const declared = self.variant_fields.get(bare);
                if (declared == null) if (resultKey(bare)) |key| {
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
                    return;
                };
                switch (v.payload) {
                    .binding => |binding| try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .ident = binding },
                        .value = subject,
                    } }),
                    // `Circle(r)` binds positionally: each binding reads the
                    // declared field at its position (`const { radius: r }`),
                    // never a property named after the binding (C4) — and the
                    // label the pattern wrote wins over the position when it
                    // wrote one, so `.Rect(height: h, width: w)` reads `height`
                    // for `h` (§5.1 P4). A variant this module does not declare
                    // and that wrote no label keeps the binding as key.
                    .fields => |fields| if (fields.len > 0) {
                        const props = try self.arena().alloc(js.ObjectPattern.Prop, fields.len);
                        for (fields, 0..) |bb, bi| {
                            const key = variantFieldKey(v, declared, bi) orelse bb;
                            props[bi] = .{ .key = key, .bind = if (std.mem.eql(u8, key, bb)) null else jsIdent(bb) };
                        }
                        try body.append(self.arena(), .{ .decl = .{
                            .pattern = .{ .object = .{ .props = props } },
                            .value = subject,
                        } });
                    },
                    // A nested pattern inside a payload (`.Some(#(a, b))`,
                    // `Ok(Circle(r))`) binds from the field it stands for.
                    .literals => |lits| for (lits, 0..) |p, li| {
                        const key = variantFieldKey(v, declared, li) orelse continue;
                        try self.appendPatternBinds(body, p, try self.b.member(subject, key));
                    },
                }
            },
            .list => |lp| {
                if (lp.spread) |sp| {
                    if (sp.len > 0) try body.append(self.arena(), .{ .decl = .{
                        .pattern = .{ .ident = sp },
                        .value = try self.b.call(try self.b.member(subject, "slice"), &.{
                            .{ .number = try std.fmt.allocPrint(self.arena(), "{d}", .{lp.elems.len}) },
                        }),
                    } });
                }
                try self.appendListElemBinds(body, lp.elems, subject);
            },
            else => {},
        }
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
