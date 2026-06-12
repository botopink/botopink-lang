const std = @import("std");
const comptimeMod = @import("../comptime.zig");
const tsEmit = @import("./typescript.zig");
const moduleOutput = @import("./moduleOutput.zig");
const configMod = @import("./config.zig");
const ast = @import("../ast.zig");
const specialize = @import("../comptime/specialize.zig");
const crossModule = @import("./crossModule.zig");

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
                const js = try emitJs(alloc, ok.transformed, ok.comptime_vals, ok.dispatch_rewrites, &ok.js_method_renames, module_test_mode, ct.name, &cross);

                // Generate TypeScript typedefs if configured.
                const typedef: ?[]u8 = if (config.typeDefLanguage) |_|
                    try emitTypeDef(alloc, ok.bindings)
                else
                    null;

                try results.append(alloc, .{
                    .name = ct.name,
                    .src = ct.src,
                    .result = .{
                        .js = js,
                        .typedef = typedef,
                        .comptime_script = if (ok.comptime_script) |s| try alloc.dupe(u8, s) else null,
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
    test_mode: bool,
    module_name: []const u8,
    cross: ?*const CrossModule,
) ![]u8 {
    return try emitProgramOptsX(alloc, program, comptime_vals, rewrites, renames, test_mode, module_name, cross);
}

fn emitTypeDef(
    alloc: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
) ![]u8 {
    return try tsEmit.emitProgram(alloc, bindings);
}

// ── emit ──────────────────────────────────────────────────────────────────────

/// Zig-native JavaScript emitter for botopink.
///
/// Converts typed bindings directly to JavaScript source — no JSON
/// intermediate, no Node.js pipeline.  Comptime expression values
/// (pre-evaluated by running Node.js and capturing stdout) are injected
/// via `comptime_vals`.
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

/// JS host namespaces that exist as globals — `#[@external(node, "Math", …)]`
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

/// ES2015+ reserved words that are illegal as JS binding names (plus
/// `arguments`/`eval`, illegal in strict mode, and contextual keywords like
/// `of`). A botopink identifier that collides is renamed with a `_` suffix at
/// emission — `with` → `with_`, `delete` → `delete_` — consistently across
/// decls, call sites, and exports (the `exports.<name>` property keeps the
/// original name; property positions accept reserved words).
///
/// `true`/`false`/`null`/`this`/`super` are deliberately omitted: botopink
/// never creates bindings with those names, and in value position they are
/// legal JS primary expressions (`true`/`false`/`null`) or handled separately
/// (`self` → `this`). `of` is also omitted — it is only a contextual keyword
/// (`for…of`), so `function of()` is valid JS and the stdlib relies on it.
const js_reserved_words = [_][]const u8{
    "arguments", "await",      "break",    "case",     "catch",
    "class",     "const",      "continue", "debugger", "default",
    "delete",    "do",         "else",     "enum",     "eval",
    "export",    "extends",    "finally",  "for",      "function",
    "if",        "implements", "import",   "in",       "instanceof",
    "interface", "let",        "new",      "package",  "private",
    "protected", "public",     "return",   "static",   "switch",
    "throw",     "try",        "typeof",   "var",      "void",
    "while",     "with",       "yield",
};

/// Sanitized JS binding name: reserved words get a `_` suffix, everything
/// else passes through unchanged. Returns a static string — no allocation.
pub fn jsIdent(name: []const u8) []const u8 {
    inline for (js_reserved_words) |w| {
        if (std.mem.eql(u8, name, w)) return w ++ "_";
    }
    return name;
}

/// Emit all declarations as JavaScript source.
///
/// `comptime_vals` maps IDs such as `"ct_0"` to pre-evaluated JS literal
/// strings such as `"6.28"`.
///
/// The `program` is the transformed AST with specialized functions already
/// injected as regular FnDecl nodes. The emitter just renders what it sees.
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
    return emitProgramOptsX(alloc, program, comptime_vals, rewrites, null, test_mode, module_name, null);
}

fn emitProgramOptsX(
    alloc: std.mem.Allocator,
    program: ast.Program,
    comptime_vals: std.StringHashMap([]const u8),
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    renames: ?*const std.AutoHashMap(ast.Loc, []const u8),
    test_mode: bool,
    module_name: []const u8,
    cross: ?*const CrossModule,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(alloc);
    defer aw.deinit();
    var em = Emitter.emitterInit(alloc, &aw.writer, comptime_vals, rewrites);
    defer em.deinit();
    em.renames = renames;
    em.test_mode = test_mode;
    em.module_name = module_name;
    em.cross = cross;
    try em.collectExternals(program);
    try em.collectClassNames(program);
    try em.collectPrimNodeRenames(program);

    // Test registry entries collected while emitting decls (test mode only).
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

    // Test-mode preamble: a throwing assert helper the runner can catch.
    if (test_mode) {
        try aw.writer.writeAll(
            \\function __bp_assert(cond, msg, loc) {
            \\    if (!cond) {
            \\        const e = new Error(msg || "assertion failed");
            \\        e.__bp_assert_loc = loc;
            \\        throw e;
            \\    }
            \\}
            \\
        );
        try aw.writer.writeByte('\n');
    }

    // Emit declarations from the transformed program.
    var firstEmitted = true;
    for (program.decls) |decl| {
        switch (decl) {
            .val => |v| {
                if (comptime_only.contains(v.name)) {
                    // Emit resolved comptime value if available.
                    if (val_ct_map.get(v.name)) |ct_id| {
                        if (comptime_vals.get(ct_id)) |lit| {
                            if (!firstEmitted) try aw.writer.writeByte('\n');
                            try em.fmt("const {s} = {s};", .{ jsIdent(v.name), lit });
                            try aw.writer.writeByte('\n');
                            firstEmitted = false;
                        }
                    }
                    continue;
                }
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitValDecl(v);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"fn" => |f| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                if (f.isExternal()) {
                    // FFI declaration — import the host symbol under the fn name.
                    if (em.externals.get(f.name)) |ref| {
                        const bind_name = jsIdent(f.name);
                        if (isJsGlobalNamespace(ref.module)) {
                            // Global namespace (`Math`, `console`, …) —
                            // reference directly, never `require`.
                            try em.fmt("const {s} = {s}.{s};", .{ bind_name, ref.module, ref.symbol });
                        } else if (std.mem.eql(u8, ref.symbol, bind_name)) {
                            try em.fmt("const {{ {s} }} = require(\"{s}\");", .{ ref.symbol, ref.module });
                        } else {
                            try em.fmt("const {{ {s}: {s} }} = require(\"{s}\");", .{ ref.symbol, bind_name, ref.module });
                        }
                        if (f.isPub) try em.fmt("\nexports.{s} = {s};", .{ f.name, bind_name });
                    } else {
                        try em.fmt("// external fn {s} (no node target)", .{f.name});
                    }
                } else {
                    try em.emitFn(f);
                }
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"struct" => |s| {
                // Phantom `@Context` base structs are erased — emit no runtime code.
                if (!isPhantomContextStruct(s)) {
                    if (!firstEmitted) try aw.writer.writeByte('\n');
                    try em.emitStruct(s);
                    try aw.writer.writeByte('\n');
                    firstEmitted = false;
                }
            },
            .record => |r| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitRecord(r);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .@"enum" => |e| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitEnum(e);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .interface => |i| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitInterface(i);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .implement => |im| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitImplement(im);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .extend => |ex| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitExtend(ex);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .use => |u| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitUse(u);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .delegate => |d| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.fmt("// delegate {s}", .{d.name});
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            // `mod` declares a submodule in the explicit tree; the submodule is
            // emitted as its own module file, so the declaration emits nothing.
            .mod => {},
            // Test blocks are only compiled under `botopink test`; in normal
            // builds they are skipped entirely.
            .@"test" => |t| {
                if (!test_mode) continue;
                const idx = test_entries.items.len;
                try test_entries.append(alloc, .{ .name = t.name, .line = t.loc.line, .idx = idx });
                if (!firstEmitted) try aw.writer.writeByte('\n');
                try em.emitTestFn(t, idx);
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
            .comment => |c| {
                if (!firstEmitted) try aw.writer.writeByte('\n');
                if (c.is_doc) {
                    try em.fmt("/** {s} */", .{c.text});
                } else if (c.is_module) {
                    try em.fmt("//// {s}", .{c.text});
                } else {
                    try em.fmt("// {s}", .{c.text});
                }
                try aw.writer.writeByte('\n');
                firstEmitted = false;
            },
        }
    }

    // Auto-invoke entry point when `fn main/0` is defined (never in test mode).
    if (has_main_0 and !test_mode) {
        if (!firstEmitted) try aw.writer.writeByte('\n');
        try aw.writer.writeAll("function _botopink_main() {\n    main();\n}\n");
        try aw.writer.writeAll("_botopink_main();\n");
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
        if (!firstEmitted) try aw.writer.writeByte('\n');
        try aw.writer.writeAll("const __bp_tests = [\n");
        for (test_entries.items) |t| {
            if (t.name) |n| {
                try aw.writer.print("    {{ name: \"{s}\", fn: __bp_test_{d}, loc: \"{s}.bp:{d}\" }},\n", .{ n, t.idx, module_name, t.line });
            } else {
                try aw.writer.print("    {{ name: \"test_{d}\", fn: __bp_test_{d}, loc: \"{s}.bp:{d}\" }},\n", .{ t.idx, t.idx, module_name, t.line });
            }
        }
        try aw.writer.writeAll("];\n");
        try aw.writer.writeAll(
            \\function __bp_run_tests() {
            \\    const filter = process.argv[2] || null;
            \\    const tests = filter ? __bp_tests.filter((t) => t.name.includes(filter)) : __bp_tests;
            \\    console.log("running " + tests.length + " tests");
            \\    let passed = 0, failed = 0;
            \\    for (const t of tests) {
            \\        try {
            \\            t.fn();
            \\            console.log("  ok   " + t.name);
            \\            passed++;
            \\        } catch (e) {
            \\            const loc = e.__bp_assert_loc || t.loc;
            \\            console.log("  FAIL " + t.name + "  (" + e.message + ")  at " + loc);
            \\            failed++;
            \\        }
            \\    }
            \\    console.log(passed + " passed, " + failed + " failed");
            \\    if (failed > 0) process.exit(1);
            \\}
            \\if (require.main === module) __bp_run_tests();
            \\
        );
    }

    return aw.toOwnedSlice();
}

fn isComptimeVal(v: ast.ValDecl) bool {
    return if (v.value.* == .comptime_) true else false;
}

// ── emitter ───────────────────────────────────────────────────────────────────

/// Chainable JS code builder with automatic indentation.
///
/// Usage:
///   b.line("(() => {{"); b.indent(); b.newline();
///   b.line("const x = 1;"); b.newline();
///   b.open("if (x === 1)"); b.indent();
///   b.line("return x;"); b.newline();
///   b.close(); b.dedent();
///   b.line("})()");
const JsBuilder = struct {
    out: *std.Io.Writer,
    alloc: std.mem.Allocator,
    indent_level: usize = 0,
    tab: []const u8 = "    ",

    pub fn init(alloc: std.mem.Allocator, out: *std.Io.Writer) JsBuilder {
        return .{ .out = out, .alloc = alloc };
    }

    pub fn line(self: *JsBuilder, text: []const u8) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
        self.out.writeAll(text) catch {};
    }
    pub fn fmtLine(self: *JsBuilder, comptime f: []const u8, args: anytype) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
        self.out.print(f, args) catch {};
    }
    pub fn newline(self: *JsBuilder) void {
        self.out.writeByte('\n') catch {};
    }
    pub fn raw(self: *JsBuilder, text: []const u8) void {
        self.out.writeAll(text) catch {};
    }
    pub fn indent(self: *JsBuilder) void {
        self.indent_level += 1;
    }
    pub fn dedent(self: *JsBuilder) void {
        if (self.indent_level > 0) self.indent_level -= 1;
    }
    /// Write indent based on current level.
    pub fn writeIndent(self: *JsBuilder) void {
        for (0..self.indent_level) |_| self.out.writeAll(self.tab) catch {};
    }
    pub fn open(self: *JsBuilder, cond: []const u8) void {
        if (cond.len > 0) {
            self.fmtLine("if ({s}) {{", .{cond});
        } else {
            self.line("{");
        }
        self.newline();
        self.indent();
    }
    pub fn close(self: *JsBuilder) void {
        self.dedent();
        self.line("}");
    }
};

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
    decl: struct { kw: []const u8, name: []const u8 },
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
    const cv = std.StringHashMap([]const u8).init(alloc);
    const rewrites = std.AutoHashMap(ast.Loc, []const u8).init(alloc);
    var em = Emitter.emitterInit(alloc, out, cv, rewrites);
    defer em.deinit();
    try em.emitFn(f);
}

const Emitter = struct {
    out: *std.Io.Writer,
    cv: std.StringHashMap([]const u8),
    current_indent: usize = 0,
    try_seq: usize = 0,
    alloc: std.mem.Allocator,
    /// Static extension dispatch: call-site loc → activated extension symbol.
    rewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Type-directed JS method renames: call-site loc → native JS method name to
    /// emit instead of `callee` (e.g. string `contains` → `includes`). Null in the
    /// standalone `emitProgram`/`emitFnJs` paths.
    renames: ?*const std.AutoHashMap(ast.Loc, []const u8) = null,
    /// When true, `self.x` lowers to `self.x` (extension methods take `self` as a
    /// real first parameter) instead of the prototype-method `this.x`.
    self_is_param: bool = false,
    /// True while emitting a generator (`function*`) body. A `return <expr>`
    /// inside a `*fn -> @Iterator<T>` means *delegate the rest of the iteration*
    /// to that iterator, so it lowers to `yield* <expr>; return;` — a plain
    /// `return <gen>` would surface the generator object as the done-value and
    /// yield nothing (the iterator-recursion bug behind the dead `iterator` suite).
    in_generator: bool = false,
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
    /// path covers interface default-fn bodies, which are emitted from AST
    /// without going through inference. Collisions with a record/struct method
    /// of the same name are excluded (`String.contains`/`Set.contains` →
    /// inference's per-loc rename is the only path; this map omits `contains`).
    prim_node_renames: std.StringHashMap([]const u8),

    fn emitterInit(
        alloc: std.mem.Allocator,
        out: *std.Io.Writer,
        cv: std.StringHashMap([]const u8),
        rewrites: std.AutoHashMap(ast.Loc, []const u8),
    ) Emitter {
        var em = Emitter{
            .out = out,
            .cv = cv,
            .alloc = alloc,
            .rewrites = rewrites,
            .externals = std.StringHashMap(ast.ExternalRef).init(alloc),
            .externals_missing = std.StringHashMap(void).init(alloc),
            .class_names = std.StringHashMap(void).init(alloc),
            .seen_imports = std.StringHashMap(void).init(alloc),
            .prim_node_renames = std.StringHashMap([]const u8).init(alloc),
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
        self.seen_imports.deinit();
        self.prim_node_renames.deinit();
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
            .@"struct" => |s| for (s.members) |mem| switch (mem) {
                .method => |m| try record_methods.put(m.name, {}),
                else => {},
            },
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

    /// Indexes every `@[external(…)]` fn by name: with a `node` target it goes
    /// to `externals`; without one it goes to `externals_missing` (so a call
    /// can fail with a clear error instead of an undefined identifier).
    fn collectExternals(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| {
                if (!f.isExternal()) continue;
                if (f.externalFor("node")) |ref| {
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
    /// Emit `exports.<name> = <name>;` for a `pub` type that another module
    /// imports. Scoped to actually-consumed names so single-module programs
    /// (the vast majority of fixtures) emit no export line and stay unchanged.
    fn emitCrossExport(self: *Emitter, name: []const u8) !void {
        const xc = self.cross orelse return;
        if (!xc.imported.contains(name)) return;
        try self.fmt("\nexports.{s} = {s};", .{ name, name });
    }

    fn collectClassNames(self: *Emitter, program: ast.Program) !void {
        for (program.decls) |decl| switch (decl) {
            .record => |r| try self.class_names.put(r.name, {}),
            .@"struct" => |s| {
                if (!isPhantomContextStruct(s)) try self.class_names.put(s.name, {});
            },
            // An imported record/struct is a class in its own module — a
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

    fn w(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }
    fn fmt(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.out.print(f, args);
    }

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

    fn emitValDecl(self: *Emitter, v: ast.ValDecl) !void {
        if (isComptimeVal(v)) {
            // Will be handled via comptime_vals lookup at a higher level.
            return;
        }
        try self.fmt("const {s} = ", .{jsIdent(v.name)});
        try self.emitExpr(v.value.*);
        try self.w(";");
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

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        self.try_seq = 0;
        const kw = fnKeyword(f);
        const prev_in_generator = self.in_generator;
        self.in_generator = std.mem.endsWith(u8, kw, "function*");
        defer self.in_generator = prev_in_generator;
        try self.fmt("{s} {s}(", .{ kw, jsIdent(f.name) });
        try self.emitParams(f.params);
        try self.w(") {\n");
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        // Each function body gets a fresh reactive-name scope for hook deps.
        self.hook_state.clearRetainingCapacity();
        for (f.body) |s| {
            try self.w("    ");
            try self.emitStmt(s);
            try self.w("\n");
        }
        self.current_indent = prev_fn_indent;
        try self.w("}");
        if (f.isPub) try self.fmt("\nexports.{s} = {s};", .{ f.name, jsIdent(f.name) });
    }

    /// Emit a `test { … }` body as `function __bp_test_<idx>() { … }`.
    /// Same body emission as `emitFn` — no params, never exported.
    fn emitTestFn(self: *Emitter, t: ast.TestDecl, idx: usize) !void {
        self.try_seq = 0;
        try self.fmt("function __bp_test_{d}() {{\n", .{idx});
        const prev_fn_indent = self.current_indent;
        self.current_indent = 1;
        self.hook_state.clearRetainingCapacity();
        for (t.body) |s| {
            try self.w("    ");
            try self.emitStmt(s);
            try self.w("\n");
        }
        self.current_indent = prev_fn_indent;
        try self.w("}");
    }

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        try self.fmt("class {s} {{\n", .{s.name});
        // Emit a real constructor that assigns each field, matching `record`
        // codegen — otherwise `new S(a, b)` ignores its arguments and the
        // fields read `undefined` at runtime. Field initializers become
        // parameter defaults so `new S()` still applies them.
        var hasField = false;
        for (s.members) |m| if (m == .field) {
            hasField = true;
            break;
        };
        if (hasField) {
            try self.w("    constructor(");
            var firstParam = true;
            for (s.members) |m| switch (m) {
                .field => |f| {
                    if (!firstParam) try self.w(", ");
                    firstParam = false;
                    try self.w(f.name);
                    if (f.init) |init| {
                        try self.w(" = ");
                        try self.emitExpr(init);
                    }
                },
                else => {},
            };
            try self.w(") {\n");
            for (s.members) |m| switch (m) {
                .field => |f| try self.fmt("        this.{s} = {s};\n", .{ f.name, f.name }),
                else => {},
            };
            try self.w("    }\n");
        }
        for (s.members) |m| switch (m) {
            .field => {},
            .getter => |g| {
                try self.w("\n");
                try self.fmt("    get {s}() {{\n", .{g.name});
                self.current_indent = 2;
                for (g.body) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
            .setter => |sg| {
                try self.w("\n");
                const vp = for (sg.params) |p| {
                    if (!std.mem.eql(u8, p.name, "self")) break p.name;
                } else "value";
                try self.fmt("    set {s}({s}) {{\n", .{ sg.name, vp });
                self.current_indent = 2;
                for (sg.body) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
            .method => |m2| {
                if (m2.is_declare) continue;
                try self.w("\n");
                try self.fmt("    {s}(", .{m2.name});
                try self.emitParams(m2.params);
                try self.w(") {\n");
                self.current_indent = 2;
                for (m2.body orelse &.{}) |st| {
                    try self.w("        ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                self.current_indent = 0;
                try self.w("    }\n");
            },
        };
        try self.w("}");
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        try self.fmt("class {s} {{\n", .{r.name});
        if (r.fields.len > 0) {
            try self.w("    constructor(");
            for (r.fields, 0..) |f, i| {
                if (i > 0) try self.w(", ");
                try self.w(f.name);
            }
            try self.w(") {\n");
            for (r.fields) |f| try self.fmt("        this.{s} = {s};\n", .{ f.name, f.name });
            try self.w("    }\n");
        }
        for (r.methods) |m| {
            if (m.is_declare) continue;
            // A method with no `self` receiver is an associated function
            // (`Response.ok(...)`) — emit it as a `static` method so the call
            // resolves on the class itself, not an instance prototype.
            const has_self = m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self");
            try self.w("\n");
            try self.fmt("    {s}{s}(", .{ if (has_self) "" else "static ", m.name });
            try self.emitParams(m.params);
            try self.w(") {\n");
            self.current_indent = 2;
            for (m.body orelse &.{}) |st| {
                try self.w("        ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("    }\n");
        }
        try self.w("}");
        if (r.isPub) try self.emitCrossExport(r.name);
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        try self.fmt("const {s} = Object.freeze({{\n", .{e.name});
        for (e.variants) |v| {
            if (v.fields.len == 0) {
                try self.fmt("    {s}: \"{s}\",\n", .{ v.name, v.name });
            } else {
                try self.fmt("    {s}: (", .{v.name});
                for (v.fields, 0..) |f, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(f.name);
                }
                try self.fmt(") => ({{ tag: \"{s}\"", .{v.name});
                for (v.fields) |f| try self.fmt(", {s}", .{f.name});
                try self.w(" }),\n");
            }
        }
        for (e.methods) |m| {
            if (m.is_declare) continue;
            try self.fmt("    {s}: function(", .{m.name});
            try self.emitParams(m.params);
            try self.w(") {\n");
            self.current_indent = 2;
            for (m.body orelse &.{}) |st| {
                try self.w("        ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("    },\n");
        }
        try self.w("});");
        if (e.isPub) try self.emitCrossExport(e.name);
    }

    fn emitInterface(self: *Emitter, i: ast.InterfaceDecl) !void {
        if (i.extends.len > 0) {
            try self.fmt("// interface {s} extends ", .{i.name});
            for (i.extends, 0..) |ext, j| {
                if (j > 0) try self.w(", ");
                try self.w(ext);
            }
        } else {
            try self.fmt("// interface {s}", .{i.name});
        }
        for (i.fields) |f| try self.fmt("\n//   {s}: {s}", .{ f.name, f.typeName });
        for (i.methods) |m| {
            if (m.is_default) {
                try self.fmt("\n//   default fn {s}(...)", .{m.name});
            } else {
                try self.fmt("\n//   fn {s}(...)", .{m.name});
            }
        }

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
                try self.fmt("\nconst {s} = {{}};", .{assoc_ns});
            }
            for (i.methods) |m| {
                if (!isAssociatedFn(m)) continue;
                const body = m.body orelse continue;
                try self.fmt("\n{s}.{s} = function(", .{ assoc_ns, m.name });
                try self.emitParams(m.params);
                try self.w(") {\n");
                const prev = self.current_indent;
                self.current_indent = 1;
                self.hook_state.clearRetainingCapacity();
                for (body) |s| {
                    try self.w("    ");
                    try self.emitStmt(s);
                    try self.w("\n");
                }
                self.current_indent = prev;
                try self.w("};");
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
                if (ref.module.len == 0) continue; // §A4: native prototype, no patch
            }

            if (m.is_default) {
                const body = m.body orelse continue;
                try self.fmt("\n{s}.prototype.{s} = function(", .{ owner, m.name });
                try self.emitParams(m.params[1..]);
                try self.w(") {\n");
                const prev = self.current_indent;
                self.current_indent = 1;
                // Boxed primitives wrap `this` in a (truthy) object — bind `self`
                // to the unwrapped primitive; arrays use `this` directly.
                if (boxed) {
                    try self.w("    const self = this.valueOf();\n");
                    self.self_is_param = true; // `self`/`self.x` stay `self`
                } else {
                    self.self_is_param = false; // bare `self` → `this`
                }
                self.hook_state.clearRetainingCapacity();
                for (body) |s| {
                    try self.w("    ");
                    try self.emitStmt(s);
                    try self.w("\n");
                }
                self.current_indent = prev;
                try self.w("};");
            } else if (m.externalFor("node")) |ref| {
                // Host-backed instance method via a JS global namespace (`Math`):
                // `Owner.prototype.m = function(args){ return Mod.sym(self, args); }`.
                // Relative companions and call-template symbols are skipped (matches
                // the inference, which leaves them to native JS).
                if (!isJsGlobalNamespace(ref.module)) continue;
                if (std.mem.indexOfScalar(u8, ref.symbol, '(') != null) continue;
                try self.fmt("\n{s}.prototype.{s} = function(", .{ owner, m.name });
                try self.emitParams(m.params[1..]);
                try self.fmt(") {{ return {s}.{s}(", .{ ref.module, ref.symbol });
                try self.w(if (boxed) "this.valueOf()" else "this");
                for (m.params[1..]) |p| try self.fmt(", {s}", .{jsIdent(p.name)});
                try self.w("); };");
            }
        }
    }

    /// External dispatch: an `implement … for T` block is emitted as a namespace
    /// object whose methods take the receiver as an explicit `self` parameter, so
    /// `obj.m()` can be lowered to `Sym.m(obj)` without patching `T.prototype`.
    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        try self.w("// implement ");
        for (im.interfaces, 0..) |iface, i| {
            if (i > 0) try self.w(", ");
            try self.w(switch (iface) {
                .named => |n| n,
                .generic => |g| g.name,
                else => "?",
            });
        }
        try self.fmt(" for {s}\n", .{im.target});
        try self.emitExtensionNamespace(im.name, im.methods);
        // A `pub` implement consumed by another module (via `import { Name* }`)
        // is exported so the consumer's `require` can bind it for dispatch.
        if (im.isPub) try self.emitCrossExport(im.name);
    }

    /// External dispatch: an `extend T` block emitted as a namespace object.
    fn emitExtend(self: *Emitter, ex: ast.ExtendDecl) !void {
        try self.fmt("// extend {s}\n", .{ex.target});
        try self.emitExtensionNamespace(ex.name, ex.methods);
    }

    fn emitExtensionNamespace(self: *Emitter, name: []const u8, methods: []const ast.ImplementMethod) !void {
        try self.fmt("const {s} = {{", .{name});
        const prev_self = self.self_is_param;
        self.self_is_param = true;
        defer self.self_is_param = prev_self;
        for (methods) |m| {
            try self.fmt("\n    {s}(", .{m.name});
            var first = true;
            for (m.params) |p| {
                if (!first) try self.w(", ");
                try self.emitParam(p);
                first = false;
            }
            try self.w(") {\n");
            self.current_indent = 2;
            for (m.body) |st| {
                try self.w("        ");
                try self.emitStmt(st);
                try self.w("\n");
            }
            self.current_indent = 0;
            try self.w("    },");
        }
        try self.w("\n};");
    }

    fn emitUse(self: *Emitter, u: ast.ImportDecl) !void {
        // Fallback activation `X*;` has no runtime binding — emit nothing.
        if (u.activationOnly) return;

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
                try buf.appendSlice(self.alloc, "./");
            } else {
                for (0..depth) |_| try buf.appendSlice(self.alloc, "../");
            }
            break :blk try buf.toOwnedSlice(self.alloc);
        };
        defer self.alloc.free(req_prefix);
        // `"std"` package import: each item binds a whole stdlib module
        // emitted alongside the project (`out/std/<mod>.js`), so qualified
        // calls (`bool.negate(x)`) resolve naturally at runtime.
        if (u.source == .module and std.mem.eql(u8, u.source.module, "std")) {
            var first = true;
            for (u.imports) |imp| {
                if (self.seen_imports.contains(imp.name())) continue;
                try self.seen_imports.put(imp.name(), {});
                if (!first) try self.w("\n");
                first = false;
                const mod = imp.segments[imp.segments.len - 1];
                try self.fmt("const {s} = require(\"{s}std/{s}.js\");", .{ imp.name(), req_prefix, mod });
            }
            return;
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
            var first_line = true;
            for (u.imports) |imp| {
                const info = xm.get(imp.name()) orelse continue;
                if (seen.contains(info.module)) continue;
                try seen.put(info.module, {});
                // Names from this module not already bound here — `const {…}` for
                // exactly those. If every one is already bound, emit no line.
                var count: usize = 0;
                for (u.imports) |imp2| {
                    const info2 = xm.get(imp2.name()) orelse continue;
                    if (!std.mem.eql(u8, info2.module, info.module)) continue;
                    if (self.seen_imports.contains(imp2.name())) continue;
                    count += 1;
                }
                if (count == 0) continue;
                if (!first_line) try self.w("\n");
                first_line = false;
                try self.w("const { ");
                var firstn = true;
                for (u.imports) |imp2| {
                    const info2 = xm.get(imp2.name()) orelse continue;
                    if (!std.mem.eql(u8, info2.module, info.module)) continue;
                    if (self.seen_imports.contains(imp2.name())) continue;
                    try self.seen_imports.put(imp2.name(), {});
                    if (!firstn) try self.w(", ");
                    firstn = false;
                    try self.w(imp2.name());
                }
                try self.fmt(" }} = require(\"{s}{s}.js\");", .{ req_prefix, info.module });
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
                    if (!first_line) try self.w("\n");
                    first_line = false;
                    if (mods.items.len == 1) {
                        try self.fmt("const {s} = require(\"{s}{s}.js\");", .{ jsIdent(lib_name), req_prefix, mods.items[0] });
                    } else {
                        try self.fmt("const {s} = Object.assign({{}}", .{jsIdent(lib_name)});
                        for (mods.items) |m| try self.fmt(", require(\"{s}{s}.js\")", .{ req_prefix, m });
                        try self.w(");");
                    }
                }
            }
            return;
        }

        var count: usize = 0;
        for (u.imports) |imp| {
            if (self.seen_imports.contains(imp.name())) continue;
            count += 1;
        }
        if (count == 0) return;
        try self.w("const { ");
        var firstn = true;
        for (u.imports) |imp| {
            if (self.seen_imports.contains(imp.name())) continue;
            try self.seen_imports.put(imp.name(), {});
            if (!firstn) try self.w(", ");
            firstn = false;
            try self.w(imp.name());
        }
        try self.w(" } = require(\"");
        switch (u.source) {
            .root => try self.fmt("{s}module", .{req_prefix}),
            .module => |name| try self.w(name),
        }
        try self.w("\");");
    }

    // ── params ────────────────────────────────────────────────────────────────

    fn emitParams(self: *Emitter, params: []const ast.Param) !void {
        var first = true;
        for (params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            if (!first) try self.w(", ");
            try self.emitParam(p);
            first = false;
        }
    }

    fn emitPattern(self: *Emitter, pat: ast.Pattern) !void {
        switch (pat) {
            .wildcard => try self.w("_"),
            .ident => |name| try self.w(jsIdent(name)),
            .variant => |v| switch (v.payload) {
                .binding => |binding| {
                    try self.w(v.name);
                    try self.w(" ");
                    try self.w(jsIdent(binding));
                },
                .fields => |fields| {
                    try self.w(v.name);
                    try self.w("(");
                    for (fields, 0..) |b, i| {
                        if (i > 0) try self.w(", ");
                        try self.w(jsIdent(b));
                    }
                    try self.w(")");
                },
                .literals => |args| {
                    try self.w(v.name);
                    try self.w("(");
                    for (args, 0..) |arg, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitPattern(arg);
                    }
                    try self.w(")");
                },
            },
            .numberLit => |n| try self.w(n),
            .stringLit => |s| try self.fmt("\"{s}\"", .{s}),
            .list => |l| {
                try self.w("[");
                for (l.elems, 0..) |e, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitListPatternElem(e);
                }
                if (l.spread) |sp| {
                    if (l.elems.len > 0) try self.w(", ");
                    try self.w("...");
                    if (sp.len > 0) try self.w(sp);
                }
                try self.w("]");
            },
            .@"or" => |pats| {
                for (pats, 0..) |p, i| {
                    if (i > 0) try self.w(" | ");
                    try self.emitPattern(p);
                }
            },
            .multi => |pats| {
                for (pats, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitPattern(p);
                }
            },
        }
    }

    fn emitListPatternElem(self: *Emitter, elem: ast.ListPatternElem) !void {
        switch (elem) {
            .wildcard => try self.w("_"),
            .bind => |name| try self.w(jsIdent(name)),
            .numberLit => |n| try self.w(n),
        }
    }

    fn emitPatternCheck(self: *Emitter, pat: *const ast.Pattern, value: []const u8) !void {
        // Generate JavaScript code to check if value matches pattern
        switch (pat.*) {
            .wildcard => try self.w("true"), // Wildcard matches everything
            .ident => {
                // Identifier pattern - check if value is truthy and has the right type
                try self.fmt("({s} !== null && {s} !== undefined)", .{ value, value });
            },
            .variant => |v| switch (v.payload) {
                // Check if value is an instance of the variant type
                .binding, .fields => try self.fmt("({s} instanceof {s})", .{ value, v.name }),
                // Literal-argument variants fall back to the generic check below.
                .literals => try self.w("true"),
            },
            .numberLit => |n| {
                try self.fmt("({s} === {s})", .{ value, n });
            },
            .stringLit => |s| {
                try self.fmt("({s} === \"{s}\")", .{ value, s });
            },
            .list => |l| {
                try self.fmt("(Array.isArray({s})", .{value});
                if (l.elems.len > 0) {
                    try self.fmt(" && {s}.length >= {d}", .{ value, l.elems.len });
                }
                try self.w(")");
            },
            .@"or" => |patterns| {
                if (patterns.len == 0) {
                    try self.w("false");
                } else {
                    for (patterns, 0..) |*p, i| {
                        if (i > 0) try self.w(" || ");
                        try self.emitPatternCheck(p, value);
                    }
                }
            },
            else => try self.w("true"), // Fallback for other pattern types
        }
    }

    fn emitParam(self: *Emitter, p: ast.Param) !void {
        if (p.destruct) |d| {
            switch (d) {
                .names => |*n| {
                    try self.w("{ ");
                    for (n.fields, 0..) |nm, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitDestructFieldBind(nm.bind_name);
                    }
                    if (n.hasSpread) try self.w(", ...");
                    try self.w(" } = ");
                },
                .tuple_ => |t| {
                    try self.w("[ ");
                    for (t, 0..) |nm, i| {
                        if (i > 0) try self.w(", ");
                        try self.w(jsIdent(nm));
                    }
                    try self.w(" ]");
                },
                .list => |pat| try self.emitPattern(pat),
                .ctor => |pat| try self.emitPattern(pat),
            }
        } else try self.w(jsIdent(p.name));
    }

    /// Object-destructure field bind: shorthand `{ name }`, or `{ name: name_ }`
    /// when the bind name is a JS reserved word (shorthand would be a SyntaxError).
    fn emitDestructFieldBind(self: *Emitter, name: []const u8) !void {
        const sanitized = jsIdent(name);
        if (sanitized.ptr == name.ptr) {
            try self.w(name);
        } else {
            try self.fmt("{s}: {s}", .{ name, sanitized });
        }
    }

    // ── statements ──────────────────────────────────────────────────────────────

    fn emitStmt(self: *Emitter, stmt: ast.Stmt) anyerror!void {
        const e = stmt.expr;
        switch (e) {
            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    if (classifyTry(lb.value.*)) |form| {
                        const kw: []const u8 = if (lb.mutable) "let" else "const";
                        try self.emitTryStmt(form, .{ .decl = .{ .kw = kw, .name = lb.name } });
                        return;
                    }
                    const kw: []const u8 = if (lb.mutable) "let" else "const";
                    try self.fmt("{s} {s} = ", .{ kw, jsIdent(lb.name) });
                    // `val d = use memo { … }` → `const d = useMemo(…, [deps])`.
                    if (useHookInner(lb.value.*)) |inner| {
                        try self.emitHookCall(inner.*);
                        try self.hook_state.append(self.alloc, lb.name);
                    } else {
                        try self.emitExpr(lb.value.*);
                    }
                    try self.w(";");
                },
                .localBindDestruct => |lb| {
                    if (classifyTry(lb.value.*)) |form| {
                        try self.emitTryStmt(form, .{ .destruct = .{ .mutable = lb.mutable, .pattern = lb.pattern } });
                        return;
                    }
                    const kw: []const u8 = if (lb.mutable) "let" else "const";
                    try self.fmt("{s} ", .{kw});
                    try self.emitDestructHead(lb.pattern);
                    // `val {v, s} = use state(0)` → `const { v, s } = useState(0)`.
                    if (useHookInner(lb.value.*)) |inner| {
                        try self.emitHookCall(inner.*);
                        try self.trackDestructNames(lb.pattern);
                    } else {
                        try self.emitExpr(lb.value.*);
                    }
                    try self.w(";");
                },
                else => {
                    try self.emitExpr(e);
                    try self.w(";");
                },
            },
            // A bare `use <hookcall>;` statement is a void hook (e.g. `use effect { … }`).
            .useHook => |uh| {
                try self.emitHookCall(uh.kind.inner.*);
                try self.w(";");
            },
            .jump => |j| switch (j.kind) {
                .@"return" => |r| {
                    if (r) |rp| {
                        if (classifyTry(rp.*)) |form| {
                            try self.emitTryStmt(form, .ret);
                            return;
                        }
                        if (self.in_generator) {
                            // `return <iter>` in a `*fn -> @Iterator` delegates:
                            // `yield* <iter>; return;` (a plain `return <gen>`
                            // surfaces the generator object and yields nothing).
                            try self.w("yield* ");
                            try self.emitExpr(rp.*);
                            try self.w("; return;");
                            return;
                        }
                        try self.w("return ");
                        try self.emitExpr(rp.*);
                    } else {
                        try self.w("return");
                    }
                    try self.w(";");
                },
                else => {
                    if (classifyTry(e)) |form| {
                        try self.emitTryStmt(form, .discard);
                        return;
                    }
                    try self.emitExpr(e);
                    try self.w(";");
                },
            },
            else => {
                if (classifyTry(e)) |form| {
                    try self.emitTryStmt(form, .discard);
                    return;
                }
                try self.emitExpr(e);
                try self.w(";");
            },
        }
    }

    // ── use-hooks (React-like target) ───────────────────────────────────────────

    /// Hooks whose lambda argument is wrapped with an inferred dependency array,
    /// matching React's `useMemo`/`useEffect`/`useCallback` calling convention.
    fn hookTakesDeps(callee: []const u8) bool {
        const with_deps = [_][]const u8{ "memo", "effect", "callback", "layoutEffect", "imperativeHandle" };
        for (with_deps) |h| if (std.mem.eql(u8, callee, h)) return true;
        return false;
    }

    /// Write a hook's JS name. Bare capability names map by the React convention
    /// `state` → `useState`, `memo` → `useMemo`. Names already in `useXxx` form
    /// (custom hooks like `useAuth`) pass through unchanged.
    fn writeHookName(self: *Emitter, callee: []const u8) !void {
        const is_custom = callee.len > 3 and
            std.mem.startsWith(u8, callee, "use") and
            std.ascii.isUpper(callee[3]);
        if (is_custom) {
            try self.w(callee);
            return;
        }
        try self.w("use");
        if (callee.len > 0) {
            const upper = [_]u8{std.ascii.toUpper(callee[0])};
            try self.w(&upper);
            try self.w(callee[1..]);
        }
    }

    /// Emit a `use`-hook's value expression as a React hook call: map the hook
    /// name and, for dependency-taking hooks, append the inferred deps array.
    fn emitHookCall(self: *Emitter, value: ast.Expr) anyerror!void {
        const cc = switch (value) {
            .call => |c| switch (c.kind) {
                .call => |call| call,
                else => return self.emitExpr(value),
            },
            else => return self.emitExpr(value),
        };

        if (cc.receiver) |recv| {
            try self.emitExpr(recv.*);
            try self.w(".");
            try self.w(cc.callee);
        } else {
            try self.writeHookName(cc.callee);
        }
        try self.w("(");
        var first = true;
        for (cc.args) |arg| {
            if (!first) try self.w(", ");
            try self.emitExpr(arg.value.*);
            first = false;
        }
        for (cc.trailing) |tl| {
            if (!first) try self.w(", ");
            first = false;
            try self.emitLambda(tl.params, tl.body);
        }
        if (hookTakesDeps(cc.callee)) {
            try self.w(", [");
            try self.emitHookDeps(cc);
            try self.w("]");
        }
        try self.w(")");
    }

    /// Emit the inferred dependency array contents: the reactive names (bound by
    /// prior hooks) referenced inside this hook's lambda argument, in source order.
    fn emitHookDeps(self: *Emitter, cc: anytype) !void {
        const body = hookLambdaBody(cc) orelse return;
        var first = true;
        for (self.hook_state.items) |name| {
            var referenced = false;
            for (body) |s| {
                if (specialize.identInExpr(s.expr, name)) {
                    referenced = true;
                    break;
                }
            }
            if (referenced) {
                if (!first) try self.w(", ");
                try self.w(name);
                first = false;
            }
        }
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

    /// Emit a `params => { body }` arrow function (for trailing-lambda hook args).
    fn emitLambda(self: *Emitter, params: []const []const u8, body: []ast.Stmt) !void {
        // A nested arrow is not a generator — its `return` stays `return`.
        const prev_in_generator = self.in_generator;
        self.in_generator = false;
        defer self.in_generator = prev_in_generator;
        try self.w("(");
        for (params, 0..) |p, i| {
            if (i > 0) try self.w(", ");
            try self.w(jsIdent(p));
        }
        try self.w(") => {\n");
        for (body) |st| {
            try self.w("    ");
            try self.emitStmt(st);
            try self.w("\n");
        }
        try self.w("}");
    }

    /// Write the destructuring head (`{ a, b } = ` / `[ a, b ] = ` / pattern + ` = `)
    /// for a `localBindDestruct`. The `const`/`let` keyword is written by the caller.
    fn emitDestructHead(self: *Emitter, pattern: ast.ParamDestruct) !void {
        switch (pattern) {
            .names => |n| {
                try self.w("{ ");
                for (n.fields, 0..) |nm, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitDestructFieldBind(nm.bind_name);
                }
                if (n.hasSpread) try self.w(", ...");
                try self.w(" } = ");
            },
            .tuple_ => |t| {
                try self.w("[ ");
                for (t, 0..) |nm, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(jsIdent(nm));
                }
                try self.w(" ] = ");
            },
            .list => |pat| {
                try self.emitPattern(pat);
                try self.w(" = ");
            },
            .ctor => |pat| {
                try self.emitPattern(pat);
                try self.w(" = ");
            },
        }
    }

    /// Record the names introduced by a destructuring `use` as reactive deps.
    fn trackDestructNames(self: *Emitter, pattern: ast.ParamDestruct) !void {
        switch (pattern) {
            .names => |n| for (n.fields) |nm| try self.hook_state.append(self.alloc, nm.bind_name),
            .tuple_ => |t| for (t) |nm| try self.hook_state.append(self.alloc, nm),
            else => {},
        }
    }

    /// Newline + current indentation, for continuation lines of a multi-line
    /// statement (the leading indent of the first line is written by the caller).
    fn contLine(self: *Emitter) !void {
        try self.w("\n");
        for (0..self.current_indent) |_| try self.w("    ");
    }

    /// Write the binding head that receives the unwrapped Ok value.
    /// Returns false for `.discard` (no value should be written).
    fn writeTryHead(self: *Emitter, head: TryHead) !bool {
        switch (head) {
            .decl => |d| {
                try self.fmt("{s} {s} = ", .{ d.kw, d.name });
                return true;
            },
            .destruct => |d| {
                const kw: []const u8 = if (d.mutable) "let" else "const";
                try self.fmt("{s} ", .{kw});
                try self.emitDestructHead(d.pattern);
                return true;
            },
            .ret => {
                try self.w("return ");
                return true;
            },
            .discard => return false,
        }
    }

    /// Lower a `try`/`catch` at statement position to `"error" in _r` pattern
    /// matching over the `{ ok: V } | { error: E }` Result value — never JS
    /// try/catch. `head` says where the Ok value lands.
    fn emitTryStmt(self: *Emitter, form: TryForm, head: TryHead) !void {
        const n = self.try_seq;
        self.try_seq += 1;

        try self.fmt("const _try{d} = ", .{n});
        try self.emitExpr(form.inner());
        try self.w(";");

        switch (form) {
            .catchValue => |cv| {
                try self.contLine();
                _ = try self.writeTryHead(head);
                try self.fmt("\"error\" in _try{d} ? (", .{n});
                try self.emitExpr(cv.handler);
                try self.w(")");
                if (cv.is_lambda) try self.fmt("(_try{d}.error)", .{n});
                try self.fmt(" : _try{d}.ok;", .{n});
            },
            .propagate => {
                try self.contLine();
                try self.fmt("if (\"error\" in _try{d}) return _try{d};", .{ n, n });
                try self.writeTryValueLine(head, n);
            },
            .catchJump => |cj| {
                try self.contLine();
                try self.fmt("if (\"error\" in _try{d}) {{ ", .{n});
                try self.emitExpr(cj.handler);
                try self.w("; }");
                try self.writeTryValueLine(head, n);
            },
        }
    }

    /// Emit `<head>_tryN.ok;` on its own line, unless the value is discarded.
    fn writeTryValueLine(self: *Emitter, head: TryHead, n: usize) !void {
        if (head == .discard) return;
        try self.contLine();
        _ = try self.writeTryHead(head);
        try self.fmt("_try{d}.ok;", .{n});
    }

    /// Emit the last stmt of an if-branch as a value expression.
    fn emitIfLast(self: *Emitter, stmt: ast.Stmt) !void {
        switch (stmt.expr) {
            .jump => |j| switch (j.kind) {
                .@"return", .throw_ => try self.emitStmt(stmt),
                else => {
                    try self.w("return ");
                    try self.emitExpr(stmt.expr);
                    try self.w(";");
                },
            },
            else => {
                try self.w("return ");
                try self.emitExpr(stmt.expr);
                try self.w(";");
            },
        }
    }

    // ── expressions (generic over phase) ─────────────────────────────────────

    fn emitBinaryOp(self: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
        try self.w("(");
        try self.emitExpr(lhs.*);
        try self.w(" ");
        try self.w(op);
        try self.w(" ");
        try self.emitExpr(rhs.*);
        try self.w(")");
    }

    /// Emit the inline CommonJS form for a lowered `@Result`/`@Option` method op.
    /// `args[0]` is the receiver expression; `args[1]` (when present) is the
    /// transform function or default value. An IIFE binds the receiver once so it
    /// is not re-evaluated (important for method chains).
    fn emitResultOptionOp(self: *Emitter, callee: []const u8, args: []const ast.CallArg) anyerror!void {
        const recv = args[0].value;
        const arg1: ?*ast.Expr = if (args.len > 1) args[1].value else null;

        if (std.mem.eql(u8, callee, "__bp_ok")) {
            // Result constructor: `return v` in a `-> @Result<…>` fn.
            try self.w("({ ok: ");
            try self.emitExpr(recv.*);
            try self.w(" })");
        } else if (std.mem.eql(u8, callee, "__bp_error")) {
            // Result constructor: `throw e` in a `-> @Result<…>` fn.
            try self.w("({ error: ");
            try self.emitExpr(recv.*);
            try self.w(" })");
        } else if (std.mem.eql(u8, callee, "__bp_result_map")) {
            try self.w("((_r) => \"error\" in _r ? _r : { ok: (");
            if (arg1) |a| try self.emitExpr(a.*);
            try self.w(")(_r.ok) })(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_result_flatMap")) {
            try self.w("((_r) => \"error\" in _r ? _r : (");
            if (arg1) |a| try self.emitExpr(a.*);
            try self.w(")(_r.ok))(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_result_unwrapOr")) {
            try self.w("((_r) => \"error\" in _r ? (");
            if (arg1) |a| try self.emitExpr(a.*);
            try self.w(") : _r.ok)(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_result_isOk")) {
            try self.w("((_r) => !(\"error\" in _r))(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_result_isError")) {
            try self.w("((_r) => \"error\" in _r)(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_option_map") or std.mem.eql(u8, callee, "__bp_option_flatMap")) {
            try self.w("((_o) => _o != null ? (");
            if (arg1) |a| try self.emitExpr(a.*);
            try self.w(")(_o) : null)(");
            try self.emitExpr(recv.*);
            try self.w(")");
        } else if (std.mem.eql(u8, callee, "__bp_option_unwrapOr")) {
            try self.w("((_o) => _o != null ? _o : (");
            if (arg1) |a| try self.emitExpr(a.*);
            try self.w("))(");
            try self.emitExpr(recv.*);
            try self.w(")");
        }
    }

    fn emitExpr(self: *Emitter, e: ast.Expr) anyerror!void {
        switch (e) {
            .literal => |lit| switch (lit.kind) {
                .stringLit => |s| try self.emitJsonString(s),
                // Desugared to a `+` chain by the transform pass; never reaches codegen.
                .stringTemplate => unreachable,
                .numberLit => |n| try self.w(n),
                .null_ => try self.w("null"),
                .comment => |c| {
                    switch (c.kind) {
                        .normal => try self.fmt("// {s}", .{c.text}),
                        .doc => try self.fmt("/** {s} */", .{c.text}),
                        .module => try self.fmt("//// {s}", .{c.text}),
                    }
                },
            },

            .identifier => |id| switch (id.kind) {
                // Bare `self` as a value (`var out = self;`, `return self;`) in a
                // prototype method lowers to `this`; only extension methods keep
                // `self` as a real parameter (`self_is_param`).
                .ident => |n| {
                    if (std.mem.eql(u8, n, "self") and !self.self_is_param) {
                        try self.w("this");
                    } else {
                        try self.w(jsIdent(n));
                    }
                },
                .dotIdent => |n| try self.w(n),
                .identAccess => |ia| {
                    const isSelf = switch (ia.receiver.*) {
                        .identifier => |recv_id| if (recv_id.kind == .ident)
                            std.mem.eql(u8, recv_id.kind.ident, "self")
                        else
                            false,
                        else => false,
                    };
                    if (isSelf) {
                        if (self.self_is_param) {
                            try self.fmt("self.{s}", .{ia.member});
                        } else {
                            try self.fmt("this.{s}", .{ia.member});
                        }
                        return;
                    }
                    try self.emitExpr(ia.receiver.*);
                    // Tuple index access: `t._N` → `t[N]` (tuples are JS arrays).
                    if (tupleIndexMember(ia.member)) |idx| {
                        try self.fmt("{s}[{s}]", .{ @as([]const u8, if (ia.optional) "?." else ""), idx });
                        return;
                    }
                    // Optional chaining maps 1:1 to native JS `?.`.
                    try self.fmt("{s}{s}", .{ @as([]const u8, if (ia.optional) "?." else "."), ia.member });
                },
            },

            .binaryOp => |bin| switch (bin.op) {
                .add => try self.emitBinaryOp("+", bin.lhs, bin.rhs),
                .sub => try self.emitBinaryOp("-", bin.lhs, bin.rhs),
                .mul => try self.emitBinaryOp("*", bin.lhs, bin.rhs),
                .div => try self.emitBinaryOp("/", bin.lhs, bin.rhs),
                .mod => try self.emitBinaryOp("%", bin.lhs, bin.rhs),
                .lt => try self.emitBinaryOp("<", bin.lhs, bin.rhs),
                .gt => try self.emitBinaryOp(">", bin.lhs, bin.rhs),
                .lte => try self.emitBinaryOp("<=", bin.lhs, bin.rhs),
                .gte => try self.emitBinaryOp(">=", bin.lhs, bin.rhs),
                // `x == null` / `x != null` lower to loose `==`/`!=` so a `?T`
                // none represented as `undefined` (e.g. `Array.at()` past the
                // end) matches the `null` none literal — botopink treats both
                // as the single none value. All other `==` stay strict `===`.
                .eq => try self.emitBinaryOp(if (isNullLiteral(bin.lhs.*) or isNullLiteral(bin.rhs.*)) "==" else "===", bin.lhs, bin.rhs),
                .ne => try self.emitBinaryOp(if (isNullLiteral(bin.lhs.*) or isNullLiteral(bin.rhs.*)) "!=" else "!==", bin.lhs, bin.rhs),
                .@"and" => try self.emitBinaryOp("&&", bin.lhs, bin.rhs),
                .@"or" => try self.emitBinaryOp("||", bin.lhs, bin.rhs),
            },

            .unaryOp => |un| switch (un.op) {
                .not => {
                    try self.w("(!");
                    try self.emitExpr(un.expr.*);
                    try self.w(")");
                },
                .neg => {
                    try self.w("(-");
                    try self.emitExpr(un.expr.*);
                    try self.w(")");
                },
            },

            .jump => |j| switch (j.kind) {
                .@"return" => |r| if (r) |val| {
                    try self.w("return ");
                    try self.emitExpr(val.*);
                } else {
                    try self.w("return");
                },
                .throw_ => |r| if (r) |val| {
                    try self.w("throw ");
                    try self.emitExpr(val.*);
                } else {
                    try self.w("throw");
                },
                .try_ => |t| if (t) |val| {
                    // Nested `try` in expression position: unwrap Ok, propagate Error
                    // out of the surrounding IIFE. (Statement position is lowered in
                    // emitStmt to a real enclosing-function `return`.)
                    const n = self.try_seq;
                    self.try_seq += 1;
                    try self.fmt("(() => {{ const _try{d} = ", .{n});
                    try self.emitExpr(val.*);
                    try self.fmt("; if (\"error\" in _try{d}) return _try{d}; return _try{d}.ok; }})()", .{ n, n, n });
                },
                .await_ => |av| {
                    try self.w("await ");
                    try self.emitExpr(av.*);
                },
                .@"break" => |b| if (b) |val| {
                    try self.w("return ");
                    try self.emitExpr(val.*);
                } else {
                    try self.w("return");
                },
                .yield => |y| if (y.value) |val| {
                    // Generator `yield` (loop-accumulator yields are lowered at the
                    // `.loop` site, so reaching here means a `*fn` generator body).
                    try self.w("yield ");
                    try self.emitExpr(val.*);
                } else {
                    try self.w("yield");
                },
                .@"continue" => try self.w("continue"),
            },

            .branch => |br| switch (br.kind) {
                .if_ => |i| {
                    // Check if the if statement contains a return
                    const thenContainsReturn = i.then_.len > 0 and
                        switch (i.then_[i.then_.len - 1].expr) {
                            .jump => |j| j.kind == .@"return",
                            else => false,
                        };
                    const elseContainsReturn = if (i.else_) |els|
                        els.len > 0 and switch (els[els.len - 1].expr) {
                            .jump => |j| j.kind == .@"return",
                            else => false,
                        }
                    else
                        false;
                    const containsReturn = thenContainsReturn or elseContainsReturn;

                    if (!containsReturn) {
                        try self.w("(() => {");
                    }
                    if (i.binding) |b| {
                        try self.fmt(" const {s} = ", .{b});
                        try self.emitExpr(i.cond.*);
                        try self.fmt("; if ({s} !== null) {{", .{b});
                    } else {
                        try self.w(" if (");
                        try self.emitExpr(i.cond.*);
                        try self.w(") {");
                    }
                    const then = i.then_;
                    const head_n = if (then.len > 0) then.len - 1 else 0;
                    for (then[0..head_n]) |st| {
                        try self.w(" ");
                        try self.emitStmt(st);
                    }
                    if (then.len > 0) {
                        try self.w(" ");
                        if (thenContainsReturn) {
                            try self.emitStmt(then[then.len - 1]);
                        } else {
                            try self.emitIfLast(then[then.len - 1]);
                        }
                    }
                    try self.w(" }");
                    if (i.else_) |els| {
                        try self.w(" else {");
                        const ehead_n = if (els.len > 0) els.len - 1 else 0;
                        for (els[0..ehead_n]) |st| {
                            try self.w(" ");
                            try self.emitStmt(st);
                        }
                        if (els.len > 0) {
                            try self.w(" ");
                            if (elseContainsReturn) {
                                try self.emitStmt(els[els.len - 1]);
                            } else {
                                try self.emitIfLast(els[els.len - 1]);
                            }
                        }
                        try self.w(" }");
                    }
                    if (!containsReturn) {
                        try self.w(" })()");
                    }
                },
                .tryCatch => |tc| {
                    // `try expr catch handler` in expression position → pattern match
                    // on the `{ ok } | { error }` Result inside an IIFE (never JS
                    // try/catch).
                    const handler = tc.handler.*;
                    const n = self.try_seq;
                    self.try_seq += 1;
                    try self.fmt("(() => {{ const _try{d} = ", .{n});
                    try self.emitExpr(tc.expr.*);
                    try self.fmt("; if (\"error\" in _try{d}) {{ ", .{n});
                    if (isJumpHandler(handler)) {
                        try self.emitExpr(handler);
                        try self.w("; ");
                    } else {
                        try self.w("return (");
                        try self.emitExpr(handler);
                        try self.w(")");
                        switch (handler) {
                            .function => try self.fmt("(_try{d}.error)", .{n}),
                            else => {},
                        }
                        try self.w("; ");
                    }
                    try self.fmt("}} return _try{d}.ok; }})()", .{n});
                },
            },

            .loop => |lp| {
                const has_yield = blk: {
                    for (lp.body) |stmt| {
                        if (switch (stmt.expr) {
                            .jump => |j| j.kind == .yield,
                            else => false,
                        }) break :blk true;
                    }
                    break :blk false;
                };

                if (has_yield and self.in_generator) {
                    // Inside a `*fn` generator, `loop (xs) { item -> yield item }`
                    // is real generator iteration — emit `for…of` with native
                    // `yield`, NOT `.map()` (which builds a throwaway array and
                    // yields nothing — the `fromList`/iterator-suite bug).
                    if (lp.params.len == 1) {
                        try self.fmt("for (const {s} of ", .{jsIdent(lp.params[0])});
                        try self.emitExpr(lp.iter.*);
                        try self.w(") {\n");
                    } else {
                        try self.w("for (const [");
                        var i: usize = lp.params.len;
                        while (i > 0) {
                            i -= 1;
                            try self.w(jsIdent(lp.params[i]));
                            if (i > 0) try self.w(", ");
                        }
                        try self.w("] of (");
                        try self.emitExpr(lp.iter.*);
                        try self.w(").entries()) {\n");
                    }
                    for (lp.body) |stmt| {
                        try self.w("    ");
                        try self.emitStmt(stmt);
                        try self.w("\n");
                    }
                    try self.w("}");
                } else if (has_yield) {
                    try self.emitExpr(lp.iter.*);
                    try self.w(".map((");
                    for (lp.params, 0..) |p, i| {
                        if (i > 0) try self.w(", ");
                        try self.w(jsIdent(p));
                    }
                    try self.w(") => {\n");
                    for (lp.body) |stmt| {
                        const isYield = switch (stmt.expr) {
                            .jump => |j| j.kind == .yield,
                            else => false,
                        };
                        if (isYield) {
                            const yield_val = stmt.expr.jump.kind.yield.value;
                            if (yield_val) |val| {
                                try self.w("    return ");
                                try self.emitExpr(val.*);
                                try self.w(";\n");
                            }
                        } else {
                            try self.w("    ");
                            try self.emitStmt(stmt);
                            try self.w("\n");
                        }
                    }
                    try self.w("})");
                } else {
                    // `loop (xs) { x -> … }` binds the ITEM; with two params the
                    // second is the index (`{ item, i -> … }`). Array.entries()
                    // yields numeric [index, item] pairs, so the destructure
                    // order is swapped. (Object.entries gave [stringKey, value],
                    // which bound the 1-param form to the index — a real bug.)
                    if (lp.params.len == 1) {
                        try self.fmt("for (const {s} of ", .{jsIdent(lp.params[0])});
                        try self.emitExpr(lp.iter.*);
                        try self.w(") {\n");
                    } else {
                        try self.w("for (const [");
                        var i: usize = lp.params.len;
                        while (i > 0) {
                            i -= 1;
                            try self.w(jsIdent(lp.params[i]));
                            if (i > 0) try self.w(", ");
                        }
                        try self.w("] of (");
                        try self.emitExpr(lp.iter.*);
                        try self.w(").entries()) {\n");
                    }
                    for (lp.body) |stmt| {
                        try self.w("    ");
                        try self.emitStmt(stmt);
                        try self.w("\n");
                    }
                    try self.w("}");
                }
            },

            .binding => |b| switch (b.kind) {
                .localBind => |lb| {
                    const kw: []const u8 = if (lb.mutable) "let" else "const";
                    try self.fmt("{s} {s} = ", .{ kw, jsIdent(lb.name) });
                    try self.emitExpr(lb.value.*);
                },
                .assign => |a| {
                    const op_str: []const u8 = switch (a.op) {
                        .assign => "=",
                        .plusAssign => "+=",
                    };
                    switch (a.target) {
                        .name => |name| {
                            try self.fmt("{s} {s} ", .{ jsIdent(name), op_str });
                            try self.emitExpr(a.value.*);
                        },
                        .fieldAccess => |*fa| {
                            const isSelf = switch (fa.receiver.*) {
                                .identifier => |recv_id| if (recv_id.kind == .ident)
                                    std.mem.eql(u8, recv_id.kind.ident, "self")
                                else
                                    false,
                                else => false,
                            };
                            if (isSelf) {
                                try self.fmt("this.{s} {s} ", .{ fa.field, op_str });
                            } else {
                                try self.emitExpr(fa.receiver.*);
                                try self.fmt(".{s} {s} ", .{ fa.field, op_str });
                            }
                            try self.emitExpr(a.value.*);
                        },
                    }
                },
                .localBindDestruct => |lb| {
                    const kw: []const u8 = if (lb.mutable) "let" else "const";
                    try self.fmt("{s} ", .{kw});
                    try self.emitDestructHead(lb.pattern);
                    try self.emitExpr(lb.value.*);
                },
            },

            // A `use` hook used in value position: emit the underlying hook call.
            .useHook => |uh| try self.emitHookCall(uh.kind.inner.*),

            .call => |c| switch (c.kind) {
                .call => |cc| {
                    if (cc.is_builtin) {
                        const is_todo = std.mem.eql(u8, cc.callee, "todo");
                        const is_panic = std.mem.eql(u8, cc.callee, "panic");
                        const is_block = std.mem.eql(u8, cc.callee, "block");
                        const is_print = std.mem.eql(u8, cc.callee, "print");
                        if (is_print) {
                            try self.w("console.log(");
                            var first = true;
                            for (cc.args) |arg| {
                                if (!first) try self.w(", ");
                                try self.emitExpr(arg.value.*);
                                first = false;
                            }
                            try self.w(")");
                        } else if (is_todo or is_panic) {
                            const default_msg: []const u8 = if (is_todo) "not implemented" else "panic";
                            try self.w("(() => { throw new Error(");
                            if (cc.args.len > 0) {
                                try self.emitExpr(cc.args[0].value.*);
                            } else {
                                try self.fmt("\"{s}\"", .{default_msg});
                            }
                            try self.w(") })()");
                        } else if (is_block) {
                            // @block can be called as @block(arg) or @block { body }
                            if (cc.args.len == 1) {
                                const arg = cc.args[0].value;
                                const isBlock = switch (arg.*) {
                                    .function => true,
                                    else => false,
                                };
                                if (!isBlock) return error.InvalidArgs;
                                try self.emitExpr(arg.*);
                            } else if (cc.trailing.len == 1 and cc.trailing[0].params.len == 0) {
                                // @block { body } - trailing lambda with no params
                                try self.w("(() => {");
                                for (cc.trailing[0].body, 0..) |stmt, i| {
                                    if (i > 0) try self.w(" ");
                                    try self.emitStmt(stmt);
                                }
                                try self.w("})()");
                            } else {
                                return error.InvalidArgs;
                            }
                        } else if (std.mem.startsWith(u8, cc.callee, "__bp_")) {
                            try self.emitResultOptionOp(cc.callee, cc.args);
                        } else if (std.mem.eql(u8, cc.callee, "expr") or std.mem.eql(u8, cc.callee, "code") or std.mem.eql(u8, cc.callee, "compilerError") or std.mem.eql(u8, cc.callee, "emit")) {
                            // `@expr(value)` / `@code(text)` — comptime template
                            // construction builtins; `@compilerError(msg)` — abort
                            // compilation from a comptime body. Only reachable when
                            // the template/decorator evaluator emits the body
                            // (those fns are dropped before normal codegen); its
                            // prelude defines `__expr`/`__code`/`__compilerError`.
                            try self.fmt("__{s}(", .{cc.callee});
                            for (cc.args, 0..) |arg, i| {
                                if (i > 0) try self.w(", ");
                                try self.emitExpr(arg.value.*);
                            }
                            try self.w(")");
                        } else {
                            try self.w("@");
                            try self.w(cc.callee);
                            try self.w("(");
                            for (cc.args, 0..) |arg, i| {
                                if (i > 0) try self.w(", ");
                                try self.emitExpr(arg.value.*);
                            }
                            try self.w(")");
                        }
                    } else {
                        var first = true;
                        var as_property = false;
                        if (cc.receiver) |recv| {
                            // Static extension dispatch: lower `recv.m(args)` to
                            // `Sym.m(recv, args)` at activated call sites.
                            if (self.rewrites.get(c.loc)) |sym| {
                                try self.fmt("{s}.{s}(", .{ sym, cc.callee });
                                try self.emitExpr(recv.*);
                                first = false;
                            } else {
                                try self.emitExpr(recv.*);
                                // Optional chaining call maps to native JS `?.`.
                                // §A4 rename: a 2-arg `@external(node, "X")` on
                                // a primitive interface method routes
                                // `recv.callee(args)` to `recv.X(args)`. The
                                // per-loc `renames` map (populated by inference's
                                // type-directed lookup) is consulted FIRST so a
                                // collision-prone name (`String.contains` vs
                                // `Set.contains`) lands the right rename. The
                                // type-naive `prim_node_renames` map (built from
                                // annotations at emitter init) is the fallback
                                // for calls inference doesn't visit — interface
                                // default-fn bodies materialised as prototype
                                // patches (`out.append(inner)` inside `flatten`).
                                const method = blk: {
                                    if (self.renames) |r| {
                                        if (r.get(c.loc)) |loc_rename| break :blk loc_rename;
                                    }
                                    if (self.prim_node_renames.get(cc.callee)) |sym| break :blk sym;
                                    break :blk cc.callee;
                                };
                                const dot: []const u8 = if (cc.optional) "?." else ".";
                                // `arr.len()`/`.size()`/`.length()` & `str.length()`:
                                // inference renamed these to `length` only for a
                                // typed array/string receiver — the native `.length`
                                // is a PROPERTY, so emit it without call parens/args.
                                const len_prop = cc.args.len == 0 and cc.trailing.len == 0 and
                                    self.renames != null and
                                    if (self.renames.?.get(c.loc)) |rn| std.mem.eql(u8, rn, "length") else false;
                                if (len_prop) {
                                    try self.fmt("{s}length", .{dot});
                                    as_property = true;
                                } else {
                                    try self.fmt("{s}{s}(", .{ dot, method });
                                }
                            }
                        } else if (self.externals_missing.contains(cc.callee)) {
                            // External fn with no `node` target — no symbol to
                            // call on this backend.
                            return error.MissingExternalTarget;
                        } else if (self.class_names.contains(cc.callee)) {
                            // Record/struct constructor — JS classes cannot be
                            // invoked without `new`.
                            try self.fmt("new {s}(", .{cc.callee});
                        } else {
                            // Plain fn call — sanitize the callee in case the
                            // fn name is a JS reserved word (`delete` → `delete_`).
                            try self.fmt("{s}(", .{jsIdent(cc.callee)});
                        }
                        for (cc.args) |arg| {
                            if (!first) try self.w(", ");
                            try self.emitExpr(arg.value.*);
                            first = false;
                        }
                        for (cc.trailing) |tl| {
                            if (!first) try self.w(", ");
                            first = false;
                            // A trailing arrow is not a generator — `return` stays.
                            const prev_in_generator = self.in_generator;
                            self.in_generator = false;
                            defer self.in_generator = prev_in_generator;
                            try self.w("(");
                            for (tl.params, 0..) |p, pi| {
                                if (pi > 0) try self.w(", ");
                                try self.w(jsIdent(p));
                            }
                            try self.w(") => {\n");
                            for (tl.body, 0..) |st, si| {
                                try self.w("    ");
                                // Tail value expression is the lambda's result.
                                if (si == tl.body.len - 1 and isImplicitReturnExpr(st.expr)) try self.w("return ");
                                try self.emitStmt(st);
                                try self.w("\n");
                            }
                            try self.w("}");
                        }
                        // A `.length` property access (`as_property`) emitted no
                        // opening paren, so it must not emit a closing one either.
                        if (!as_property) try self.w(")");
                    }
                },
                .pipeline => |p| {
                    // Flatten the pipeline chain
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

                    // Emit as nested calls: last(items)(...(items[1](items[0])))
                    try self.w("(");
                    var i_idx: usize = items.items.len - 1;
                    while (i_idx > 0) : (i_idx -= 1) {
                        try self.emitExpr(items.items[i_idx]);
                        try self.w("(");
                    }
                    try self.emitExpr(items.items[0]);
                    i_idx = items.items.len - 1;
                    while (i_idx > 0) : (i_idx -= 1) {
                        try self.w(")");
                    }
                    try self.w(")");
                },
            },

            .function => |f| {
                // A nested arrow is not a generator — its `return` stays `return`.
                const prev_in_generator = self.in_generator;
                self.in_generator = false;
                defer self.in_generator = prev_in_generator;
                try self.w("(");
                for (f.kind.params, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(jsIdent(p));
                }
                try self.w(") => {\n");
                for (f.kind.body, 0..) |st, si| {
                    try self.w("    ");
                    // A bare value expression in tail position is the lambda's
                    // result — JS arrow blocks don't auto-return it.
                    if (si == f.kind.body.len - 1 and isImplicitReturnExpr(st.expr)) try self.w("return ");
                    try self.emitStmt(st);
                    try self.w("\n");
                }
                try self.w("}");
            },

            .collection => |col| switch (col.kind) {
                .arrayLit => |arr| {
                    try self.w("[");
                    for (arr.elems, 0..) |elem, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitExpr(elem);
                    }
                    if (arr.spread) |sp| {
                        if (arr.elems.len > 0) try self.w(", ");
                        try self.w("...");
                        if (sp.len > 0) try self.w(sp);
                    }
                    if (arr.spreadExpr) |se| {
                        if (arr.elems.len > 0) try self.w(", ");
                        try self.w("...");
                        try self.emitExpr(se.*);
                    }
                    try self.w("]");
                },
                .tupleLit => |tuple| {
                    try self.w("[");
                    for (tuple.elems, 0..) |elem, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitExpr(elem);
                    }
                    try self.w("]");
                },
                .grouped => |expr| {
                    try self.w("(");
                    try self.emitExpr(expr.*);
                    try self.w(")");
                },
                .case => |c| try self.emitCase(c.subjects, c.arms, null),
                .range => |r| {
                    // `a..b` is the half-open `[a, b)` integer range. JS has no
                    // range literal, so materialize a real array (parity with the
                    // erlang/beam `lists:seq(a, b-1)` and `Array.range`).
                    if (r.end) |end| {
                        try self.w("Array.from({length: Math.max(0, (");
                        try self.emitExpr(end.*);
                        try self.w(") - (");
                        try self.emitExpr(r.start.*);
                        try self.w("))}, (_, __i) => (");
                        try self.emitExpr(r.start.*);
                        try self.w(") + __i)");
                    } else {
                        // An open-ended `a..` is a lazy infinite range (used only
                        // with `break`); a finite JS array can't represent it.
                        try self.w("(() => { throw new Error(\"open-ended range unsupported on commonJS\"); })()");
                    }
                },
                // Anonymous record literal — a plain JS object (parenthesized
                // so it stays an expression in statement position).
                .recordLit => |rl| {
                    try self.w("({ ");
                    for (rl.fields, 0..) |f, i| {
                        if (i > 0) try self.w(", ");
                        try self.fmt("{s}: ", .{f.name});
                        try self.emitExpr(f.value.*);
                    }
                    try self.w(" })");
                },
            },

            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |expr| try self.emitExpr(expr.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .jump => |j| switch (j.kind) {
                                .@"break" => |b| if (b) |bp| {
                                    try self.emitExpr(bp.*);
                                    return;
                                },
                                else => {},
                            },
                            else => {},
                        }
                    }
                },
                .assert => |a| {
                    if (self.test_mode) {
                        // Throwing helper — the test runner catches per test,
                        // records the failure, and continues.
                        try self.w("__bp_assert(");
                        try self.emitExpr(a.condition.*);
                        try self.w(", ");
                        if (a.message) |msg| {
                            try self.emitExpr(msg.*);
                        } else {
                            try self.w("null");
                        }
                        try self.fmt(", \"{s}.bp:{d}\")", .{ self.module_name, ct.loc.line });
                    } else {
                        try self.w("console.assert(");
                        try self.emitExpr(a.condition.*);
                        if (a.message) |msg| {
                            try self.w(", ");
                            try self.emitExpr(msg.*);
                        }
                        try self.w(")");
                    }
                },
                .assertPattern => |ap| {
                    try self.w("(() => { ");
                    try self.w("const _match = ");
                    try self.emitExpr(ap.expr.*);
                    try self.w("; ");
                    try self.w("if (");
                    try self.emitPatternCheck(&ap.pattern, "_match");
                    try self.w(") { ");
                    try self.w("return _match; ");
                    try self.w("} else { ");
                    const handlerIsStatement = switch (ap.handler.*) {
                        .jump => |j| j.kind == .throw_ or j.kind == .@"return",
                        else => false,
                    };
                    if (!handlerIsStatement) try self.w("return ");
                    try self.emitExpr(ap.handler.*);
                    try self.w(";");
                    try self.w(" } })()");
                },
            },
        }
    }

    // ── case helper ───────────────────────────────────────────────────────────

    fn isLambdaBlock(e: ast.Expr) bool {
        return switch (e) {
            .function => |f| f.kind.syntax == .lambda,
            else => false,
        };
    }

    fn emitCaseBody(self: *Emitter, body: ast.Expr, b: *JsBuilder) !void {
        if (switch (body) {
            .function => |f| f.kind.syntax == .lambda,
            else => false,
        }) {
            const l = body.function.kind;
            self.current_indent = b.indent_level;
            for (l.body) |st| {
                b.writeIndent();
                switch (st.expr) {
                    .jump => |j| switch (j.kind) {
                        .@"break" => |br| if (br) |bp| {
                            try self.w("return ");
                            try self.emitExpr(bp.*);
                            try self.w(";");
                        },
                        else => try self.emitStmt(st),
                    },
                    else => try self.emitStmt(st),
                }
                b.newline();
            }
            self.current_indent = b.indent_level;
        } else {
            try self.emitExpr(body);
        }
    }

    fn buildCondStr(self: *Emitter, pat: ast.Pattern) ![]const u8 {
        var buf: std.Io.Writer.Allocating = .init(self.alloc);
        defer buf.deinit();
        switch (pat) {
            .numberLit => |n| try buf.writer.print("_s === {s}", .{n}),
            .stringLit => |s| {
                try buf.writer.writeAll("_s === ");
                var sw = Emitter{ .out = &buf.writer, .alloc = self.alloc, .cv = self.cv, .rewrites = self.rewrites, .externals = self.externals, .externals_missing = self.externals_missing, .class_names = self.class_names, .seen_imports = self.seen_imports, .prim_node_renames = self.prim_node_renames };
                try sw.emitJsonString(s);
            },
            .ident => |n| try buf.writer.print("_s === \"{s}\"", .{n}),
            .@"or" => |pats| {
                for (pats, 0..) |p, pi| {
                    if (pi > 0) try buf.writer.writeAll(" || ");
                    try self.writePatternCond(&buf.writer, p);
                }
            },
            else => {},
        }
        return try buf.toOwnedSlice();
    }

    fn writePatternCond(self: *Emitter, wr: *std.Io.Writer, pat: ast.Pattern) !void {
        switch (pat) {
            .numberLit => |n| try wr.print("_s === {s}", .{n}),
            .stringLit => |s| {
                try wr.writeAll("_s === ");
                var sw = Emitter{ .out = wr, .alloc = self.alloc, .cv = self.cv, .rewrites = self.rewrites, .externals = self.externals, .externals_missing = self.externals_missing, .class_names = self.class_names, .seen_imports = self.seen_imports, .prim_node_renames = self.prim_node_renames };
                try sw.emitJsonString(s);
            },
            .ident => |n| try wr.print("_s === \"{s}\"", .{n}),
            else => try wr.writeAll("false"),
        }
    }

    /// Emit `return <body>;` for a matched arm, gated by the arm's guard when
    /// present: `if (<guard>) return <body>;`.
    fn emitGuardedReturn(self: *Emitter, b: *JsBuilder, arm: ast.CaseArm) !void {
        if (arm.guard) |g| {
            b.line("if (");
            try self.emitExpr(g);
            b.raw(") return ");
        } else {
            b.line("return ");
        }
        try self.emitExpr(arm.body);
        b.raw(";");
        b.newline();
    }

    /// Emit a matched arm body — either a `return <expr>;` or an inlined lambda
    /// block — gated by the arm's guard when present.
    fn emitMatchedBody(self: *Emitter, b: *JsBuilder, arm: ast.CaseArm) !void {
        if (isLambdaBlock(arm.body)) {
            if (arm.guard) |g| {
                b.line("if (");
                try self.emitExpr(g);
                b.raw(") {");
                b.newline();
                b.indent();
                try self.emitCaseBody(arm.body, b);
                b.close();
                b.newline();
            } else {
                try self.emitCaseBody(arm.body, b);
            }
        } else {
            try self.emitGuardedReturn(b, arm);
        }
    }

    fn emitCase(
        self: *Emitter,
        subjects: []ast.Expr,
        arms: []ast.CaseArm,
        _: ?*JsBuilder,
    ) !void {
        var b = JsBuilder.init(self.alloc, self.out);
        b.indent_level = self.current_indent;

        b.raw("(() => {");
        b.newline();
        b.indent();
        if (subjects.len == 1) {
            b.line("const _s = ");
            try self.emitExpr(subjects[0]);
            b.raw(";");
            b.newline();
        } else {
            b.line("const _s = [");
            for (subjects, 0..) |s, i| {
                if (i > 0) b.raw(", ");
                try self.emitExpr(s);
            }
            b.raw("];");
            b.newline();
        }

        for (arms) |arm| {
            switch (arm.pattern) {
                .wildcard => {
                    if (arm.guard != null) {
                        try self.emitMatchedBody(&b, arm);
                    } else if (isLambdaBlock(arm.body)) {
                        b.open("");
                        try self.emitCaseBody(arm.body, &b);
                        b.close();
                        b.newline();
                    } else {
                        b.line("return ");
                        try self.emitExpr(arm.body);
                        b.raw(";");
                        b.newline();
                    }
                },

                .ident, .numberLit, .stringLit, .@"or", .multi => {
                    if (arm.pattern == .ident and arm.guard != null) {
                        // A guarded identifier binds the subject, then tests the guard.
                        b.open("");
                        b.fmtLine("const {s} = _s;", .{jsIdent(arm.pattern.ident)});
                        b.newline();
                        try self.emitMatchedBody(&b, arm);
                        b.close();
                        b.newline();
                    } else if (arm.guard != null) {
                        const cond = try self.buildCondStr(arm.pattern);
                        defer self.alloc.free(cond);
                        b.open(cond);
                        try self.emitMatchedBody(&b, arm);
                        b.close();
                        b.newline();
                    } else {
                        const cond = try self.buildCondStr(arm.pattern);
                        defer self.alloc.free(cond);
                        if (isLambdaBlock(arm.body)) {
                            b.open(cond);
                            try self.emitCaseBody(arm.body, &b);
                            b.close();
                            b.newline();
                        } else {
                            b.fmtLine("if ({s}) return ", .{cond});
                            try self.emitExpr(arm.body);
                            b.raw(";");
                            b.newline();
                        }
                    }
                },

                .variant => |v| {
                    b.fmtLine("if (_s.tag === \"{s}\") {{", .{v.name});
                    b.newline();
                    b.indent();
                    switch (v.payload) {
                        .binding => |binding| {
                            b.fmtLine("const {s} = _s;", .{jsIdent(binding)});
                            b.newline();
                        },
                        .fields => |fields| if (fields.len > 0) {
                            b.line("const { ");
                            for (fields, 0..) |bb, bi| {
                                if (bi > 0) b.raw(", ");
                                const sanitized = jsIdent(bb);
                                if (sanitized.ptr == bb.ptr) {
                                    b.raw(bb);
                                } else {
                                    b.raw(bb);
                                    b.raw(": ");
                                    b.raw(sanitized);
                                }
                            }
                            b.raw(" } = _s;");
                            b.newline();
                        },
                        .literals => {},
                    }
                    try self.emitMatchedBody(&b, arm);
                    b.close();
                    b.newline();
                },

                .list => |lp| {
                    if (lp.spread) |sp| {
                        if (lp.elems.len == 0 and sp.len == 0) {
                            b.line("return ");
                            try self.emitExpr(arm.body);
                            b.raw(";");
                            b.newline();
                        } else {
                            b.fmtLine("if (_s.length >= {d}) {{", .{lp.elems.len});
                            b.newline();
                            b.indent();
                            if (sp.len > 0) {
                                b.fmtLine("const {s} = _s.slice({d});", .{ jsIdent(sp), lp.elems.len });
                                b.newline();
                            }
                            for (lp.elems, 0..) |elem, ei| switch (elem) {
                                .bind => |bb| {
                                    b.fmtLine("const {s} = _s[{d}];", .{ jsIdent(bb), ei });
                                    b.newline();
                                },
                                else => {},
                            };
                            b.line("return ");
                            try self.emitExpr(arm.body);
                            b.raw(";");
                            b.newline();
                            b.close();
                            b.newline();
                        }
                    } else if (lp.elems.len == 0) {
                        b.fmtLine("if (_s.length === 0) return ", .{});
                        try self.emitExpr(arm.body);
                        b.raw(";");
                        b.newline();
                    } else {
                        b.fmtLine("if (_s.length === {d}) {{", .{lp.elems.len});
                        b.newline();
                        b.indent();
                        for (lp.elems, 0..) |elem, ei| switch (elem) {
                            .bind => |bb| {
                                b.fmtLine("const {s} = _s[{d}];", .{ jsIdent(bb), ei });
                                b.newline();
                            },
                            else => {},
                        };
                        b.line("return ");
                        try self.emitExpr(arm.body);
                        b.raw(";");
                        b.newline();
                        b.close();
                        b.newline();
                    }
                },
            }
        }

        b.dedent();
        b.line("})()");
    }

    // ── string helper ─────────────────────────────────────────────────────────

    /// Emit a botopink string literal's RAW content as a JS string literal.
    /// The lexer has already validated every textual escape (`\n`, `\"`,
    /// `\\`, `\$`, `\u{…}`, …) and the escape set is JS-compatible, so escape
    /// PAIRS pass through verbatim — re-escaping their backslash would double
    /// source escapes (`"\n"` would print a literal `\n` at runtime). Only
    /// real control characters and unescaped quotes (multiline `"""` content)
    /// need escaping here.
    fn emitJsonString(self: *Emitter, s: []const u8) !void {
        try self.out.writeByte('"');
        var i: usize = 0;
        while (i < s.len) : (i += 1) {
            const c = s[i];
            switch (c) {
                '\\' => {
                    // A validated escape — copy the pair verbatim.
                    try self.out.writeByte('\\');
                    if (i + 1 < s.len) {
                        i += 1;
                        try self.out.writeByte(s[i]);
                    }
                },
                '"' => try self.out.writeAll("\\\""),
                '\n' => try self.out.writeAll("\\n"),
                '\r' => try self.out.writeAll("\\r"),
                '\t' => try self.out.writeAll("\\t"),
                else => try self.out.writeByte(c),
            }
        }
        try self.out.writeByte('"');
    }
};
