/// Public API for the botopink comptime pipeline.
///
/// This is the only file outside `src/comptime/` that should be imported by
/// other modules. All internal implementation lives under `src/comptime/`.
const std = @import("std");
const ast = @import("./ast.zig");
const infer = @import("./comptime/infer.zig");
const transform = @import("./comptime/transform.zig");
const context_lower = @import("comptime/context_lower.zig");
const alias_erase = @import("./comptime/alias_erase.zig");
const std_namespace = @import("./comptime/std_namespace.zig");
const inline_types = @import("./comptime/inline_types.zig");
const nested_types = @import("./comptime/nested_types.zig");
const default_fn = @import("./comptime/default_fn.zig");
const value_or_type = @import("./comptime/value_or_type.zig");
const expr_param = @import("./comptime/expr_param.zig");
const evalMod = @import("./comptime/eval.zig");
const format = @import("./format.zig");
pub const trace = @import("./comptime/trace.zig");
const Lexer = @import("./lexer.zig").Lexer;
const Token = @import("./lexer.zig").Token;
const Parser = @import("./parser.zig").Parser;
const LexicalError = @import("./lexer.zig").LexicalError;
const ParseErrorInfo = @import("./parser.zig").ParseErrorInfo;
const Env = @import("./comptime/env.zig").Env;
const envMod = @import("./comptime/env.zig");
const template = @import("./comptime/template.zig");
const T = @import("./comptime/types.zig");
const Module = @import("./module.zig").Module;
const validation = @import("./comptime/error.zig");
const diagnostics = @import("./comptime/diagnostics.zig");
const reflectionMod = @import("./comptime/reflection.zig");
const assocTypes = @import("./comptime/assoc_types.zig");
const typeinfoAll = @import("./comptime/typeinfo_all.zig");
const hostRuntime = @import("./comptime/runtime/runtime.zig");
const templateEval = @import("./comptime/template_eval.zig");

// ── Re-exports for external consumers ────────────────────────────────────────

/// Re-exported so callers only need to import `comptime.zig`.
pub const ComptimeError = validation.ComptimeError;
pub const TypeError = validation.TypeError;
pub const TypedBinding = infer.TypedBinding;
pub const Type = T.Type;
pub const Env_ = Env; // alias: use `comptimeMod.Env` in callers
/// What `compileTypesOnly`'s opt-in template evaluator needs (`{ io, build_root }`).
/// Re-exported so tooling (the LSP) builds it without importing comptime internals.
pub const TemplateEvalCtx = envMod.TemplateEvalCtx;

// ── Intermediate types ────────────────────────────────────────────────────────

pub const ComptimeEvalResult = struct {
    comptime_script: ?[]u8,
    comptime_vals: std.StringHashMap([]const u8),
};

/// Per-module result after analysis and comptime evaluation.
/// Bindings reference `ComptimeSession.arena` — valid only while the session is alive.
/// The canonical reference node a sub-language template produced via
/// `q.custom` — re-exported so tooling consumers (the language server) read the
/// generic shape without depending on the comptime internals. expr-custom.
pub const CustomNode = template.CustomNode;

/// A `CustomNode.ref` — the origin-scope symbol (`{ name, kind }`) a sub-language
/// node binds to (a `q.lookup` result). Re-exported so tooling resolves
/// hover/go-to-definition through it. expr-custom / sublanguage-lsp.
pub const NodeBinding = template.NodeBinding;

/// One `@ExprCustom` reference-AST entry surfaced to tooling: the call site, the
/// template callee, the canonical `CustomNode` root, and the provenance
/// (file/line/col of the template literal's opening quote) needed to map a
/// node's template-relative `span` to an absolute document position. Generic —
/// names no sub-language.
pub const CustomAstEntry = struct {
    loc: ast.Loc,
    callee: []const u8,
    root: CustomNode,
    file: []const u8,
    line: usize,
    col: usize,
};

/// Why a module did not lex or did not parse — the `Outcome.parseError`
/// payload, located so every caller (CLI, snapshots, the language server)
/// can render file, line and excerpt without re-running the lexer or parser.
pub const SyntaxError = union(enum) {
    /// `Lexer.scanAll` failed.
    lex: LexFailure,
    /// `Parser.parse` returned `UnexpectedToken`; the parser records a
    /// located `ParseErrorInfo` for every one it returns.
    parse: ?ParseErrorInfo,

    pub const LexFailure = struct {
        /// `@errorName` of the error `scanAll` returned (`UnterminatedString`,
        /// `UnexpectedCharacter`, `LexicalError`).
        name: []const u8,
        /// The structured error, when the lexer recorded one (`Lexer.lexError`).
        info: ?LexicalError,
        /// Byte span the lexer was scanning when it stopped (`start`..`current`).
        start: usize,
        end: usize,
    };
};

pub const ComptimeOutput = struct {
    name: []const u8,
    src: []const u8,
    outcome: Outcome,
    /// The driver's package-relative source path (`Module.srcPath`,
    /// `src/main.bp`), empty when it gave none: the file a test's and an
    /// `assert`'s `<file>:<line>` names, as `@src().file` does
    /// (`displaySrcPath`) — a backend falls back to `<name>.bp`.
    srcPath: []const u8 = "",

    pub const Outcome = union(enum) {
        ok: OkData,
        validationError: ComptimeError,
        /// Type inference failed (e.g. a type mismatch). Carries the located
        /// error so editors can render a diagnostic squiggle.
        typeError: TypeError,
        /// Source failed to lex or parse (e.g. incomplete input during LSP
        /// editing). Carries the located lexer / parser error.
        parseError: SyntaxError,
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
        /// Static extension dispatch: call-site location → activated extension
        /// symbol. Backends lower `obj.m(args)` at these sites to `Sym.m(obj, args)`.
        dispatch_rewrites: std.AutoHashMap(ast.Loc, []const u8),
        /// Type-directed JS method renames: call-site location → native JS method
        /// name. JS-specific (e.g. string `contains` → `includes`); only commonJS
        /// reads it. Empty for the other backends.
        js_method_renames: std.AutoHashMap(ast.Loc, []const u8),
        /// Value-receiver instance method calls: call-site location → how the
        /// receiver's record/primitive method lowers. Consumed by the backends
        /// without native method dispatch (erlang/beam/wasm); commonJS ignores it.
        instance_lowerings: std.AutoHashMap(ast.Loc, envMod.InstanceLowering),
        /// `@ExprCustom` reference ASTs produced by `q.custom` in this module —
        /// the generic, canonical `CustomNode` tree per call location. Read-only,
        /// for tooling (the language server). Empty for modules with no custom
        /// templates. expr-custom.
        custom_ast: []const CustomAstEntry,
        /// What each decorator / template evaluation sent to and got back from
        /// the `erl` runtime, in evaluation order (snapshots).
        comptime_traces: []const trace.Entry,
        /// How many template calls this module expanded, runtime-evaluated ones
        /// and V1-driver ones (pass-through / `@expr` / `@code`) alike. The
        /// V1 expansions never reach the `erl` runtime, so they leave no
        /// `comptime_traces` entry; snapshots use this count to decide that the
        /// spliced program is worth recording.
        template_expansions: usize = 0,
        /// Decision 57 — the warnings inference recorded for this module
        /// (`Env.warnings`), each located, none of them failing the module.
        warnings: []const TypeError = &.{},
    };
};

/// Collect the `@ExprCustom` reference-AST entries recorded during inference of
/// one module into the read-only slice surfaced on `OkData.custom_ast`.
fn collectCustomAst(arena: std.mem.Allocator, env: *const envMod.Env) ![]const CustomAstEntry {
    if (env.customAstByLoc.count() == 0) return &.{};
    var out = try arena.alloc(CustomAstEntry, env.customAstByLoc.count());
    var i: usize = 0;
    var it = env.customAstByLoc.iterator();
    while (it.next()) |e| : (i += 1) {
        out[i] = .{
            .loc = e.key_ptr.*,
            .callee = e.value_ptr.callee,
            .root = e.value_ptr.root,
            .file = e.value_ptr.file,
            .line = e.value_ptr.line,
            .col = e.value_ptr.col,
        };
    }
    return out;
}

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

/// Prepend the interface declarations whose associated functions were used as
/// call receivers (`Pair.of(...)`) but that aren't declared in the program —
/// i.e. stdlib primitives (`Pair`, `Function`, `Array`). Codegen then emits their
/// namespace objects so `Interface.method(...)` resolves at runtime. Local
/// interfaces already in the program are skipped (avoids duplicate emission).
/// True when `decls` declare a template function (`-> @Expr<T>` /
/// `-> @ExprCustom<T>`).
fn declaresTemplateFn(decls: []const ast.DeclKind) bool {
    for (decls) |d| if (d == .@"fn") if (d.@"fn".returnType) |rt| if (rt.isTemplateReturnType()) return true;
    return false;
}

/// Decision 112, at the backends' end. A consumer imports each name its
/// expanded templates' LIBRARY wrote (`Env.templateImports`) under the alias
/// inference bound it to — `import {<path>.<name> as <alias>} from "<pkg>"`,
/// the qualified form every backend lowers. A module declaring a template
/// (`declares_template`, read from the program before the transform dropped
/// the templates) makes its private functions and values visible to those
/// imports: `pub` from here on, where only the backends read it — the checker
/// already refused every source import of them.
fn withTemplateHygiene(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env, declares_template: bool) !ast.Program {
    if (env.templateImports.count() == 0 and !declares_template) return prog;
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var it = env.templateImports.iterator();
    while (it.next()) |e| {
        var parts: std.ArrayListUnmanaged([]const u8) = .empty;
        var seg = std.mem.splitScalar(u8, e.value_ptr.owner, '/');
        while (seg.next()) |p| try parts.append(arena, p);
        if (parts.items.len == 0) continue;
        try parts.append(arena, e.value_ptr.name);
        const items = try arena.alloc(ast.ImportPath, 1);
        items[0] = .{ .segments = parts.items[1..], .alias = e.key_ptr.* };
        try decls.append(arena, .{ .use = .{ .imports = items, .source = .{ .module = parts.items[0] } } });
    }
    for (prog.decls) |d| {
        var out = d;
        if (declares_template) switch (out) {
            .@"fn" => |*f| f.isPub = true,
            .val => |*v| v.isPub = true,
            else => {},
        };
        try decls.append(arena, out);
    }
    return ast.Program{ .decls = decls.items };
}

fn withUsedAssocInterfaces(arena: std.mem.Allocator, prog_in: ast.Program, env: *const envMod.Env) !ast.Program {
    // A program's own behavior that extends std's (`behavior String { … }`,
    // `Env.stdBehaviorBase`) is emitted as the merged declaration: std's
    // members are the program's too, and std's own emission of the behavior
    // is the one this replaces.
    var prog = prog_in;
    if (env.stdBehaviorBase.count() > 0) {
        const decls = try arena.dupe(ast.DeclKind, prog.decls);
        for (decls) |*d| if (d.* == .behavior) {
            if (env.stdBehaviorBase.contains(d.behavior.name)) {
                if (env.assocInterfaceDecls.get(d.behavior.name)) |merged| d.* = .{ .behavior = merged };
            }
        };
        prog = .{ .decls = decls };
    }
    if (env.usedAssocInterfaces.count() == 0) return prog;
    var extra: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var it = env.usedAssocInterfaces.keyIterator();
    while (it.next()) |k| {
        const name = k.*;
        var already = false;
        for (prog.decls) |d| {
            if (d == .behavior and std.mem.eql(u8, d.behavior.name, name)) {
                already = true;
                break;
            }
        }
        if (already) continue;
        if (env.assocInterfaceDecls.get(name)) |decl| {
            try extra.append(arena, .{ .behavior = decl });
        }
    }
    if (extra.items.len == 0) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, extra.items.len + prog.decls.len);
    @memcpy(new_decls[0..extra.items.len], extra.items);
    @memcpy(new_decls[extra.items.len..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// §enum-sections F4 — prepend every synthesised inner enum (the F1 desugar
/// produces one per section, registered by `registerEnumSection`) to
/// `program.decls` so codegen emits each as a top-level enum, AND enrich
/// every parent enum that carries sections with the matching section-wrapper
/// variants (`Color: (_inner) => ...`) so codegen emits them too. Without
/// the prepend the section-wrapper payload types (`_inner: __Enum__…`) bind
/// to nothing; without the enrichment the user-written parent enum's
/// codegen surface is empty (the source AST keeps sections separate from
/// variants — a `Token { Color { … } }` enum carries zero `.variants` and
/// only `.sections`). The synthesised decls land BEFORE the user-written
/// decls so the parent enum's payload types resolve without forward-ref
/// juggling.
/// `@src().file` for a module (1.0.10-beta decision 73): the driver's
/// package-relative `Module.srcPath` when it supplied one, else `<name>.bp` —
/// the spelling the test runners already print (`main.bp:12`), so the
/// compiler's own harness (which passes `.path = ""`) answers `main.bp`.
fn displaySrcPath(arena: std.mem.Allocator, mod: Module) ![]const u8 {
    if (mod.srcPath.len > 0) return mod.srcPath;
    const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
    return std.fmt.allocPrint(arena, "{s}.bp", .{name});
}

/// The builtin `SourceLocation` record as a program declaration. `@src()` is
/// rewritten into `SourceLocation(file: …, line: …, column: …, fnName: …)`
/// during inference (`infer.zig`, `inferSrcBuiltin`), and the record itself is
/// declared in `decl_reflection_src` — a prelude the backends never see. When a
/// module referenced the record (`env.usesSourceLocation`) this prepends its
/// declaration to the transformed program, so every backend registers the field
/// list through the record path it already has (commonJS `class`, erlang/beam
/// map, wat layout) and no codegen file learns the name. A module that never
/// touches it emits byte-for-byte what it emitted before.
/// Decision 110 — an import's `as` on a type (or type alias) is a name in the
/// checker only: the backends import the type under its declared name, which
/// is what every use of the alias was renamed to (`registerImportedTypeAlias`).
/// So the alias is dropped from the transformed program's import items.
fn withImportTypeAliasesErased(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.importedTypeAliases.count() == 0) return prog;
    const decls = try arena.dupe(ast.DeclKind, prog.decls);
    for (decls) |*d| switch (d.*) {
        .use => |*u| {
            var touched = false;
            for (u.imports) |imp| if (imp.alias) |al| {
                if (env.importedTypeAliases.contains(al)) touched = true;
            };
            if (!touched) continue;
            const items = try arena.dupe(ast.ImportPath, u.imports);
            for (items) |*imp| if (imp.alias) |al| {
                if (env.importedTypeAliases.contains(al)) imp.alias = null;
            };
            u.imports = items;
        },
        else => {},
    };
    return .{ .decls = decls };
}

/// Each import item another module the backends would also read declares
/// (`env.itemOwners` — a bundled package beside a shorthand, decision 170; a
/// module of this package beside `from "<pkg>"` or a package beside a module
/// path, decision 206) leaves its import for an import of its own that names
/// the module it resolved to by its key (`ImportSource.key`, `config` or
/// `log/levels` — written `import {charOf} from "config";` when formatted),
/// the item reduced to its leaf and its alias, so the backends' name-keyed
/// lookup reads the checker's answer, exactly that module, instead of
/// meeting the other declaration beside it (a key never reads as a basename:
/// the root package's `config` is not a dependency's `x/config`).
fn withImportSourcesNamed(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.itemOwners.count() == 0) return prog;
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (prog.decls) |d| switch (d) {
        .use => |u| {
            if (u.package != null or u.activationOnly) {
                try out.append(arena, d);
                continue;
            }
            var kept: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
            for (u.imports) |imp| {
                if (env.itemOwners.get(imp.loc)) |owner| {
                    var leaf = imp;
                    leaf.segments = try arena.dupe([]const u8, &.{imp.leaf()});
                    var nu = u;
                    nu.imports = try arena.dupe(ast.ImportPath, &.{leaf});
                    nu.source = .{ .key = owner };
                    try out.append(arena, .{ .use = nu });
                } else try kept.append(arena, imp);
            }
            if (kept.items.len > 0) {
                var ku = u;
                ku.imports = kept.items;
                try out.append(arena, .{ .use = ku });
            }
        },
        else => try out.append(arena, d),
    };
    return .{ .decls = out.items };
}

fn withSourceLocationDecl(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesSourceLocation) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, "SourceLocation")) return prog,
        else => {},
    };
    var lx = Lexer.init(source_location_decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const decl_prog = try p.parse(arena);
    if (decl_prog.decls.len != 1) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, 1 + prog.decls.len);
    new_decls[0] = decl_prog.decls[0];
    @memcpy(new_decls[1..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// Decision 216 (4) — the prelude records `@TypeInfo.all` answers with
/// (`Declared<T>`, `DeclaredMeta`), spliced into a module that names them the
/// way `withSourceLocationDecl` splices `SourceLocation`: private, per module.
fn withDeclaredDecls(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesDeclared) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, "Declared") or std.mem.eql(u8, t.name, "DeclaredMeta")) return prog,
        else => {},
    };
    var lx = Lexer.init(declared_decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const decl_prog = try p.parse(arena);
    const new_decls = try arena.alloc(ast.DeclKind, decl_prog.decls.len + prog.decls.len);
    @memcpy(new_decls[0..decl_prog.decls.len], decl_prog.decls);
    @memcpy(new_decls[decl_prog.decls.len..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// The declarations `withDeclaredDecls` splices — the `decl_reflection_src`
/// entries, private. Keep the two in sync.
const declared_decl_src =
    \\type DeclaredMeta(key: string, value: string)
    \\type Declared<T>(name: string, module: string, meta: DeclaredMeta[], returnTypeName: string, value: T)
;

/// The declaration `withSourceLocationDecl` splices: private (the record is
/// per-module — only its fields matter, never its identity), the same four
/// fields as the `decl_reflection_src` entry. Keep the two in sync.
const source_location_decl_src =
    \\type SourceLocation(file: string, line: i32, column: i32, fnName: string)
;

/// The prelude enum `YieldStep<T>` as a program declaration, when the module
/// referenced it (`env.usesYieldStep` — an annotation or a `.next()` on a
/// sequence): the same splice `withSourceLocationDecl` makes for the record, so
/// each backend builds `Yield(v)` / `Done` and matches them through the enum
/// path it already has. A module declaring its own `YieldStep` keeps it.
fn withYieldStepDecl(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesYieldStep) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, infer.yield_step_type_name)) return prog,
        else => {},
    };
    var lx = Lexer.init(yield_step_decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const decl_prog = try p.parse(arena);
    if (decl_prog.decls.len != 1) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, 1 + prog.decls.len);
    new_decls[0] = decl_prog.decls[0];
    @memcpy(new_decls[1..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// The declaration `withYieldStepDecl` splices: private, like
/// `source_location_decl_src` — per module, the variants are what matter.
const yield_step_decl_src =
    \\type YieldStep<T> {
    \\    Yield(value: T),
    \\    Done,
    \\}
;

test "yield step prelude matches builtins.d.bp" {
    const builtins = @import("std_prelude").builtins;
    try std.testing.expect(std.mem.indexOf(u8, builtins, yield_step_src) != null);
    try std.testing.expect(std.mem.endsWith(u8, yield_step_src, yield_step_decl_src));
}

fn withSynthesisedEnumDecls(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.synthesisedEnumDecls.count() == 0) return prog;

    // Step 1 — collect synthesised inner enum decls to prepend.
    var extra: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var it = env.synthesisedEnumDecls.iterator();
    while (it.next()) |entry| {
        try extra.append(arena, .{ .type_ = entry.value_ptr.* });
    }
    if (extra.items.len == 0) return prog;

    // Step 2 — enrich every parent enum with section wrappers, rewriting its
    // `variants` slice in-place inside a new program.decls buffer.
    const new_decls = try arena.alloc(ast.DeclKind, extra.items.len + prog.decls.len);
    @memcpy(new_decls[0..extra.items.len], extra.items);
    for (prog.decls, 0..) |d, i| {
        switch (d) {
            .type_ => |e| {
                if (e.sections().len == 0) {
                    new_decls[extra.items.len + i] = d;
                } else {
                    const enriched = try enrichEnumWithSectionWrappers(arena, e);
                    new_decls[extra.items.len + i] = .{ .type_ = enriched };
                }
            },
            else => new_decls[extra.items.len + i] = d,
        }
    }
    return ast.Program{ .decls = new_decls };
}

/// §enum-sections F4 — synthesise the section-wrapper variants for a parent
/// enum `TypeDecl` so codegen sees `Color(_inner: __Enum__Color)` alongside the
/// user-written variants. The parent's `sections()` carry the section
/// names; the wrapper payload's type-ref points at the mangled inner enum
/// name (matching `registerEnumSection`'s `__<Enum>__<Path>` convention).
/// Returns a new enum TypeDecl with its variants set to (original variants ++
/// synthesised wrappers).
fn enrichEnumWithSectionWrappers(arena: std.mem.Allocator, e: ast.TypeDecl) !ast.TypeDecl {
    const wrappers = try arena.alloc(ast.EnumVariant, e.sections().len);
    for (e.sections(), 0..) |sec, i| {
        const mangled = try std.fmt.allocPrint(arena, "__{s}__{s}", .{ e.name, sec.name });
        const fields = try arena.alloc(ast.Field, 1);
        fields[0] = .{
            .name = "_inner",
            .typeRef = .{ .named = mangled },
            .default = null,
        };
        wrappers[i] = .{ .name = sec.name, .fields = fields, .numeric = false };
    }
    const variants = e.variants();
    const merged = try arena.alloc(ast.EnumVariant, variants.len + wrappers.len);
    @memcpy(merged[0..variants.len], variants);
    @memcpy(merged[variants.len..], wrappers);
    var out = e;
    out.shape = .{ .enum_ = .{ .variants = merged, .sections = e.sections() } };
    return out;
}

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
    typeError: TypeError,
    parseError: SyntaxError,
};

fn analyzeModule(
    arena: std.mem.Allocator,
    mod: Module,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    templateEvalCtx: ?envMod.TemplateEvalCtx,
    types_only: bool,
    target_name: ?[]const u8,
    reflection: *reflectionMod.Reflection,
) !AnalysisResult {
    return analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, false, target_name, reflection);
}

/// Append decorator `@emit(...)` contributions to a module's source as extra
/// top-level declarations (the wiring a decorator builds — singletons, DI, router).
fn spliceContributions(arena: std.mem.Allocator, source: []const u8, contributions: []const []const u8) ![]const u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    try buf.appendSlice(arena, source);
    for (contributions) |c| {
        try buf.append(arena, '\n');
        try buf.appendSlice(arena, c);
    }
    return buf.toOwnedSlice(arena);
}

/// Pass-2 fast path: parse each `@emit` contribution into AST decls, append to
/// the pass-1 program's decl list, return a merged `Program`. Returns null if
/// any contribution fails to parse — caller falls back to text-splicing +
/// re-lexing the whole spliced source.
///
/// Skipping the re-lex/re-parse of the original module's source bytes is the
/// whole point: contributions are typically a handful of small generated
/// decls, while the original module can be hundreds of lines. Today's
/// recursive `analyzeSource(spliced, …)` repaid the entire original lex+parse
/// cost on every decorator that emits — visible as the ~10ms upper-half of
/// the `decorator-bearing record still lists bindings (R2)` LSP test.
///
/// Each contribution's tokens are placed where `spliceContributions` would put
/// them — after the module's own lines, one contribution after another — so
/// no two declarations share a location. Every lowering inference records is
/// keyed by location: parsed from line 1, two proxies a decorator emitted
/// (`LedgerSec`, `RunbookSec`) wrote `self.inner.status()` at the same loc,
/// the second record overwrote the first, and erlang called `Runbook:status`
/// from `LedgerSec` — another type's code, silently.
fn parseAndMergeContributions(
    arena: std.mem.Allocator,
    source: []const u8,
    original: ast.Program,
    contributions: []const []const u8,
) !?ast.Program {
    var merged: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    try merged.appendSlice(arena, original.decls);
    var line_shift: usize = std.mem.count(u8, source, "\n") + 1;
    var offset_shift: usize = source.len + 1;
    for (contributions) |contrib| {
        var c_lexer = Lexer.init(contrib);
        const c_tokens = try arena.dupe(Token, c_lexer.scanAll(arena) catch return null);
        for (c_tokens) |*t| {
            t.line += line_shift;
            t.offset += offset_shift;
        }
        line_shift += std.mem.count(u8, contrib, "\n") + 1;
        offset_shift += contrib.len + 1;
        var c_parser = Parser.init(c_tokens);
        const c_program = c_parser.parse(arena) catch return null;
        try merged.appendSlice(arena, c_program.decls);
    }
    return ast.Program{ .decls = try merged.toOwnedSlice(arena) };
}

/// What `mergeMembers` answers: the program with every member in its type's
/// body, or the refusal of the first member that cannot join it.
const MemberMerge = union(enum) {
    ok: ast.Program,
    refused: validation.TypeError,
};

/// Decision 216 (1) — every `decl.addMember(source)` of pass 1, parsed as one
/// member of its target type's body and appended to it, as if the type had
/// been written with it. The member's tokens are placed after the module's own
/// lines and after every `@emit` contribution (`first_line`, `first_offset`),
/// so no two lowerings share a location (`parseAndMergeContributions`).
///
/// Refused at the annotation that ran the decorator: a source that is not
/// exactly one `fn` (`decorator-member-not-one-fn`) and a name the type already
/// has — a field, a variant, a member written by hand or added before
/// (`decorator-member-duplicate`). A decorator adds; it never replaces.
fn mergeMembers(
    arena: std.mem.Allocator,
    original: ast.Program,
    members: []const envMod.MemberContribution,
    first_line: usize,
    first_offset: usize,
) !MemberMerge {
    const decls = try arena.dupe(ast.DeclKind, original.decls);
    var line_shift = first_line;
    var offset_shift = first_offset;
    for (members) |m| {
        const target_index = for (decls, 0..) |d, i| switch (d) {
            .type_ => |t| if (std.mem.eql(u8, t.name, m.target)) break i,
            .behavior => |b| if (std.mem.eql(u8, b.name, m.target)) break i,
            else => {},
        } else return error.MemberTargetMissing;
        const is_behavior = decls[target_index] == .behavior;
        const prefix = if (is_behavior) "behavior __bp_member {\n" else "type __bp_member() {\n";
        const text = try std.fmt.allocPrint(arena, "{s}{s}\n}}", .{ prefix, m.source });

        const refuse = struct {
            fn at(a: std.mem.Allocator, mc: envMod.MemberContribution, comptime fmt: []const u8, args: anytype, hint: []const u8) !MemberMerge {
                var e = validation.TypeError.custom(try std.fmt.allocPrint(a, fmt, args), hint);
                if (mc.loc) |l| e = e.withLoc(l);
                return .{ .refused = e };
            }
        }.at;
        const not_one = "`decl.addMember(source)` takes one member: a single `fn` (an associated fn, or a method whose first parameter is `self: Self`) written as it would be in the type's body.";

        const method: ast.BehaviorMethod = parsed: {
            var lexer = Lexer.init(text);
            const tokens = try arena.dupe(Token, lexer.scanAll(arena) catch
                return refuse(arena, m, "{s}: `#[{s}]` added a member to `{s}` that does not lex: `{s}`", .{ diagnostics.decorator_member_not_one_fn, m.decorator, m.target, m.source }, not_one));
            for (tokens) |*t| {
                t.line += line_shift - 1;
                t.offset = (t.offset + offset_shift) -| prefix.len;
            }
            var parser = Parser.init(tokens);
            const program = parser.parse(arena) catch
                return refuse(arena, m, "{s}: `#[{s}]` added a member to `{s}` that is not one `fn`: `{s}`", .{ diagnostics.decorator_member_not_one_fn, m.decorator, m.target, m.source }, not_one);
            const methods: []const ast.BehaviorMethod, const extra: bool = if (program.decls.len != 1) .{ &.{}, true } else switch (program.decls[0]) {
                .type_ => |t| .{ t.methods, t.recordFields().len != 0 },
                .behavior => |b| .{ b.methods, b.fields.len != 0 },
                else => .{ &.{}, true },
            };
            if (extra or methods.len != 1)
                return refuse(arena, m, "{s}: `#[{s}]` added a member to `{s}` that is not one `fn`: `{s}`", .{ diagnostics.decorator_member_not_one_fn, m.decorator, m.target, m.source }, not_one);
            break :parsed methods[0];
        };
        line_shift += std.mem.count(u8, m.source, "\n") + 1;
        offset_shift += m.source.len + 1;

        const taken = switch (decls[target_index]) {
            .type_ => |t| taken: {
                for (t.recordFields()) |f| if (std.mem.eql(u8, f.name, method.name)) break :taken "a field";
                for (t.variants()) |v| if (std.mem.eql(u8, v.name, method.name)) break :taken "a variant";
                for (t.methods) |mm| if (std.mem.eql(u8, mm.name, method.name)) break :taken "a member";
                break :taken null;
            },
            .behavior => |b| taken: {
                for (b.fields) |f| if (std.mem.eql(u8, f.name, method.name)) break :taken "a field";
                for (b.methods) |mm| if (std.mem.eql(u8, mm.name, method.name)) break :taken "a member";
                break :taken null;
            },
            else => unreachable,
        };
        if (taken) |what| return refuse(arena, m, "{s}: `#[{s}]` adds `{s}` to `{s}`, which already has {s} called `{s}`", .{ diagnostics.decorator_member_duplicate, m.decorator, method.name, m.target, what, method.name }, "A decorator adds members; it never replaces one. Rename the member the decorator writes, or the one already there.");

        switch (decls[target_index]) {
            .type_ => |*t| {
                const grown = try arena.alloc(ast.BehaviorMethod, t.methods.len + 1);
                @memcpy(grown[0..t.methods.len], t.methods);
                grown[t.methods.len] = method;
                t.methods = grown;
            },
            .behavior => |*b| {
                const grown = try arena.alloc(ast.BehaviorMethod, b.methods.len + 1);
                @memcpy(grown[0..b.methods.len], b.methods);
                grown[b.methods.len] = method;
                b.methods = grown;
            },
            else => unreachable,
        }
    }
    return .{ .ok = .{ .decls = decls } };
}

/// Decision 216 (4) — the build's modules with every module that reads
/// `@TypeInfo.all` moved after all the others (relative order kept), so a
/// reader's answer covers the whole program; the readers are noted in the
/// session's reflection. A module importing a reader is refused at the import
/// (`refusals`, by module index into the answer): the reader would have to be
/// analysed before the declarations it reports.
fn orderReaders(
    arena: std.mem.Allocator,
    modules: []const Module,
    reflection: *reflectionMod.Reflection,
    refusals: *std.AutoHashMapUnmanaged(usize, validation.TypeError),
) ![]const Module {
    var readers: std.ArrayListUnmanaged(Module) = .empty;
    var others: std.ArrayListUnmanaged(Module) = .empty;
    var reader_programs: std.ArrayListUnmanaged(?ast.Program) = .empty;
    var other_programs: std.ArrayListUnmanaged(?ast.Program) = .empty;
    var reader_tokens: std.ArrayListUnmanaged([]const Token) = .empty;
    var other_tokens: std.ArrayListUnmanaged([]const Token) = .empty;
    for (modules) |m| {
        // A module that does not parse is no reader; its own analysis
        // reports the parse error.
        var lx = Lexer.init(m.source);
        const tokens: []const Token = lx.scanAll(arena) catch &.{};
        const program: ?ast.Program = if (tokens.len > 0) parsed: {
            var p = Parser.init(tokens);
            const parsed = p.parse(arena) catch break :parsed null;
            break :parsed try ast.ImportDecl.withOwnPackage(arena, parsed, m.package);
        } else null;
        if (program != null and try typeinfoAll.reads(arena, program.?)) {
            try readers.append(arena, m);
            try reader_programs.append(arena, program);
            try reader_tokens.append(arena, tokens);
            try reflection.readers.put(arena, m.path, {});
        } else {
            try others.append(arena, m);
            try other_programs.append(arena, program);
            try other_tokens.append(arena, tokens);
        }
    }
    if (readers.items.len == 0) return modules;
    try others.appendSlice(arena, readers.items);
    try other_programs.appendSlice(arena, reader_programs.items);
    try other_tokens.appendSlice(arena, reader_tokens.items);
    for (others.items, other_programs.items, other_tokens.items, 0..) |m, maybe_program, tokens, idx| {
        const program = maybe_program orelse continue;
        scan: for (program.decls) |d| switch (d) {
            .use => |u| {
                // Decision 353 — `import pkg from "pkg"` binds the package's
                // default function: a reader holding it is imported too, and
                // refused at the handle (it used to be dropped from the
                // importer's scope, `unbound variable` at the use).
                if (u.package) |handle| {
                    const pkg = u.source.packageName() orelse handle;
                    for (readers.items, reader_programs.items) |r, rp| {
                        if (std.mem.eql(u8, r.path, m.path) or !ast.ImportSource.ofPackage(pkg, r.path)) continue;
                        const holds_default = for ((rp orelse continue).decls) |rd| {
                            if (rd == .@"fn" and rd.@"fn".isDefault) break true;
                        } else false;
                        if (!holds_default) continue;
                        const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it — `import {s}` binds its default function", .{ diagnostics.typeinfo_all_imported, r.path, handle });
                        try refusals.put(arena, idx, validation.TypeError.custom(msg, "Move the default function out of the reading module, or read the catalogue in the template function's body: a template body's query answers for the program that expands it (decision 353).").withLoc(handleLoc(tokens, handle)));
                        break :scan;
                    }
                }
                for (u.imports) |imp| {
                    for ([_]bool{ false, true }) |whole| switch (try u.leafSource(imp, arena, whole)) {
                        // A `.key` is one module: the package plus the path.
                        .key => |key| for (readers.items) |r| {
                            if (std.mem.eql(u8, r.path, m.path) or !std.mem.eql(u8, key, r.path)) continue;
                            const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it", .{ diagnostics.typeinfo_all_imported, r.path });
                            try refusals.put(arena, idx, validation.TypeError.custom(msg, "Move what this module needs out of the entry point into a module of its own; the entry point imports it, never the other way round.").withLoc(imp.loc));
                            break :scan;
                        },
                        .module => |path| for (readers.items) |r| {
                            if (std.mem.eql(u8, r.path, m.path)) continue;
                            if (!std.mem.eql(u8, path, r.path) and !std.mem.eql(u8, std.fs.path.basename(r.path), path)) continue;
                            const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it", .{ diagnostics.typeinfo_all_imported, r.path });
                            try refusals.put(arena, idx, validation.TypeError.custom(msg, "Move what this module needs out of the entry point into a module of its own; the entry point imports it, never the other way round.").withLoc(imp.loc));
                            break :scan;
                        },
                        .root => {},
                    };
                }
            },
            else => {},
        };
    }
    return others.items;
}

/// Where `import <handle>` writes its handle: the identifier after an
/// `import` keyword (the import declaration keeps no location of its own).
fn handleLoc(tokens: []const Token, handle: []const u8) ast.Loc {
    for (tokens, 0..) |t, i| {
        if (t.kind != .import or i + 1 >= tokens.len) continue;
        const next = tokens[i + 1];
        if (std.mem.eql(u8, next.lexeme, handle)) return .{ .line = next.line, .col = next.col };
    }
    return .{ .line = 1, .col = 1 };
}

/// Decision 216 (3) — every `decl.addType(name, source)` of pass 1, parsed as
/// the one top-level type `__<Owner>__<Name>` (`envMod.assocTypeName`), `pub`
/// when its owner is, and appended to the program. Its tokens are placed after
/// everything earlier contributions occupy (`first_line`, `first_offset`).
///
/// Refused at the annotation that ran the decorator: a source that is not the
/// shape of exactly one type (`decorator-type-not-one-type`), and a name the
/// owner already answers — one of its variants or members — or one the module
/// already declares (`decorator-type-duplicate`).
fn mergeAssocTypes(
    arena: std.mem.Allocator,
    original: ast.Program,
    types: []const envMod.TypeContribution,
    first_line: usize,
    first_offset: usize,
) !MemberMerge {
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    try decls.appendSlice(arena, original.decls);
    var line_shift = first_line;
    var offset_shift = first_offset;
    for (types) |t| {
        const refuse = struct {
            fn at(a: std.mem.Allocator, tc: envMod.TypeContribution, comptime fmt: []const u8, args: anytype, hint: []const u8) !MemberMerge {
                var e = validation.TypeError.custom(try std.fmt.allocPrint(a, fmt, args), hint);
                if (tc.loc) |l| e = e.withLoc(l);
                return .{ .refused = e };
            }
        }.at;
        var owner_pub = false;
        var taken: ?[]const u8 = null;
        var found = false;
        for (decls.items) |d| switch (d) {
            .type_ => |td| if (std.mem.eql(u8, td.name, t.owner)) {
                found = true;
                owner_pub = td.isPub;
                for (td.variants()) |v| if (std.mem.eql(u8, v.name, t.name)) {
                    taken = "a variant";
                };
                for (td.methods) |m| if (std.mem.eql(u8, m.name, t.name)) {
                    taken = "a member";
                };
                break;
            },
            .behavior => |b| if (std.mem.eql(u8, b.name, t.owner)) {
                found = true;
                owner_pub = b.isPub;
                for (b.methods) |m| if (std.mem.eql(u8, m.name, t.name)) {
                    taken = "a member";
                };
                break;
            },
            else => {},
        };
        if (!found) return error.AssocOwnerMissing;
        if (taken) |what| return refuse(arena, t, "{s}: `#[{s}]` declares `{s}.{s}`, and `{s}` already has {s} called `{s}`", .{ diagnostics.decorator_type_duplicate, t.decorator, t.owner, t.name, t.owner, what, t.name }, "`Owner.Name` names one thing; rename the associated type or the member.");
        const mangled = try envMod.assocTypeName(arena, t.owner, t.name);
        for (decls.items) |d| {
            const n: []const u8 = switch (d) {
                .type_ => |td| td.name,
                .behavior => |b| b.name,
                .@"fn" => |f| f.name,
                .val => |v| v.name,
                .typeAlias => |a| a.name,
                else => continue,
            };
            if (std.mem.eql(u8, n, mangled)) return refuse(arena, t, "{s}: `#[{s}]` declares `{s}.{s}`, and the module already declares `{s}`", .{ diagnostics.decorator_type_duplicate, t.decorator, t.owner, t.name, mangled }, "An associated type is declared under its owner's path; rename it, or the declaration it collides with.");
        }

        const prefix = try std.fmt.allocPrint(arena, "{s}type {s}", .{ if (owner_pub) "pub " else "", mangled });
        const text = try std.fmt.allocPrint(arena, "{s}{s}", .{ prefix, t.source });
        const not_one = "`decl.addType(name, source)` takes the shape of one type as it follows the name in a declaration: `(id: string)`, `(…) implement B { … }`, `{ A, B }`.";
        var lexer = Lexer.init(text);
        const tokens = try arena.dupe(Token, lexer.scanAll(arena) catch
            return refuse(arena, t, "{s}: `#[{s}]` declares `{s}.{s}` from a source that does not lex: `{s}`", .{ diagnostics.decorator_type_not_one_type, t.decorator, t.owner, t.name, t.source }, not_one));
        for (tokens) |*tok| {
            tok.line += line_shift - 1;
            tok.offset = (tok.offset + offset_shift) -| prefix.len;
        }
        var parser = Parser.init(tokens);
        const program = parser.parse(arena) catch
            return refuse(arena, t, "{s}: `#[{s}]` declares `{s}.{s}` from a source that is not one type: `{s}`", .{ diagnostics.decorator_type_not_one_type, t.decorator, t.owner, t.name, t.source }, not_one);
        if (program.decls.len != 1 or program.decls[0] != .type_ or !std.mem.eql(u8, program.decls[0].type_.name, mangled))
            return refuse(arena, t, "{s}: `#[{s}]` declares `{s}.{s}` from a source that is not one type: `{s}`", .{ diagnostics.decorator_type_not_one_type, t.decorator, t.owner, t.name, t.source }, not_one);
        var assoc = program.decls[0];
        assoc.type_.displayName = try std.fmt.allocPrint(arena, "{s}.{s}", .{ t.owner, t.name });
        try decls.append(arena, assoc);
        line_shift += std.mem.count(u8, t.source, "\n") + 1;
        offset_shift += t.source.len + 1;
    }
    return .{ .ok = .{ .decls = try decls.toOwnedSlice(arena) } };
}

/// Decision 216 (3) — the names `program` binds to owners of associated types
/// (`assoc_types.zig`): its own types and behaviors with entries in the
/// session's reflection, and every imported one — the module that declares
/// it found the way `resolveImports` finds a type (the module the source
/// names first, then the wider passes).
fn assocOwners(
    arena: std.mem.Allocator,
    program: ast.Program,
    module_path: []const u8,
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    reflection: *reflectionMod.Reflection,
) !std.StringHashMapUnmanaged(assocTypes.Owner) {
    var owners: std.StringHashMapUnmanaged(assocTypes.Owner) = .empty;
    for (program.decls, 0..) |d, idx| switch (d) {
        .type_, .behavior => {
            const name = if (d == .type_) d.type_.name else d.behavior.name;
            var assoc = try reflection.assocOf(arena, module_path, name);
            // Decision 330 (7): the types declared in its body.
            if (d == .type_) assoc = try withNested(arena, assoc, d.type_);
            if (assoc.len > 0) try owners.put(arena, name, .{ .name = name, .assoc = assoc });
        },
        .use => |u| {
            // An std owner answers only through the types declared in its
            // body (decision 330 (7)); decorators run on no std module.
            const from_std = switch (u.source) {
                .module => |m| std.mem.eql(u8, m, "std"),
                .root, .key => false,
            };
            for (u.imports) |imp| {
                if (imp.activate) continue;
                const leaf = imp.leaf();
                const leaf_src = try u.leafSource(imp, arena, false);
                const path: []const u8 = found: for ([3]u2{ 0, 1, 2 }) |pass| {
                    var it = typeDeclRegistry.iterator();
                    while (it.next()) |e| {
                        if (isStdPkgPath(e.key_ptr.*) != from_std) continue;
                        if (!leaf_src.admits(e.key_ptr.*, pass)) continue;
                        if (e.value_ptr.contains(leaf)) break :found e.key_ptr.*;
                    }
                } else continue;
                var assoc: []const []const u8 = if (from_std) &.{} else try reflection.assocOf(arena, path, leaf);
                if (typeDeclRegistry.get(path).?.get(leaf)) |dk| if (dk == .type_) {
                    assoc = try withNested(arena, assoc, dk.type_);
                };
                if (assoc.len > 0) try owners.put(arena, imp.name(), .{ .name = leaf, .assoc = assoc, .import = .{ .decl = idx, .item = imp } });
            }
        },
        else => {},
    };
    return owners;
}

/// `assoc` and the names of the types declared in `t`'s body (decision 330 (7)).
fn withNested(arena: std.mem.Allocator, assoc: []const []const u8, t: ast.TypeDecl) ![]const []const u8 {
    if (t.assocTypes.len == 0) return assoc;
    return std.mem.concat(arena, []const u8, &.{ assoc, try nested_types.namesOf(arena, t) });
}

/// The pass-2 env replaces pass 1's, where the decorators ran: carry their
/// runtime traces over, ahead of any pass-2 (template) evaluations.
fn keepPassOneTraces(pass_two: *Env, pass_one: *const Env) !void {
    try pass_two.comptimeTraces.insertSlice(pass_two.arena, 0, pass_one.comptimeTraces.items);
}

/// Pass-2 of decorator `@emit` expansion: re-infer on the merged program
/// (original decls + parsed contributions) with decorator invocation disabled
/// so generated decls don't re-emit. Mirrors `analyzeSource` minus the lex/
/// parse steps (the merged AST is already in hand) and minus the contributions
/// branch (skip_invoke == true here by construction).
fn analyzeMerged(
    arena: std.mem.Allocator,
    mod: Module,
    merged_in: ast.Program,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    templateEvalCtx: ?envMod.TemplateEvalCtx,
    target_name: ?[]const u8,
    reflection: *reflectionMod.Reflection,
    typeinfo_plan: ?typeinfoAll.Plan,
) anyerror!AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);
    env.modulePath = mod.path;
    env.reflection = reflection;
    if (typeinfo_plan) |pl| env.typeinfoAll = pl.rewrites;
    env.srcPath = try displaySrcPath(arena, mod);
    // The prelude registration may have named `SourceLocation`; only the
    // program's own references count (`withSourceLocationDecl`).
    env.usesSourceLocation = false;
    env.usesYieldStep = false;
    env.templateEval = templateEvalCtx;
    env.skipDecoratorInvoke = true;
    env.target = target_name;
    env.typeDeclRegistry = typeDeclRegistry;

    // Decision 216 (3): this module's own associated types exist now. The
    // contributions an `@emit` spliced in are imports of this package too.
    const merged = try ast.ImportDecl.withOwnPackage(arena, merged_in, mod.package);
    var owners = try assocOwners(arena, merged, mod.path, typeDeclRegistry, reflection);
    const program = try assocTypes.expand(arena, merged, &owners);

    if (validation.validateComptime(program)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    resolveImports(&env, program, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    const bindings = infer.inferProgramTyped(&env, program) catch |err| switch (err) {
        error.TypeError => {
            const te = inline_types.locatedAtCall(env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } });
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };

    return .{ .success = .{ .bindings = bindings, .env = env, .program = program } };
}

/// Analyze one module's `source`. On the first pass (`skip_invoke == false`) a
/// decorator body may contribute generated declarations via `@emit(...)`; if it
/// does, the contributions are spliced onto the source and the module is
/// re-analyzed ONCE with decorator invocation disabled (`skip_invoke == true`),
/// so the generated decls are inferred + emitted without re-running decorators.
// Per-sub-phase counters inside `analyzeSource` (the meat of
// `comptimeMod.compile`). Surfaces which of lexer / parser / resolveImports /
// infer dominates the ~82ms-per-call cost the assertJs harness measured.
/// Process-lifetime template Env populated once by `registerBuiltins` +
/// `registerStdlib`. Each `freshEnv` then clones the (already-inferred)
/// hashmaps in ~µs instead of re-lexing + re-parsing + re-inferring the
/// stdlib (`primitives.bp` + `@Decl` cluster + `CustomNode` +
/// `builtins_fns.d.bp`) on every call.
///
/// Before this template was introduced, every `freshEnv` invocation
/// re-ran the stdlib pipeline — ~83ms per call. With ~1000 calls in
/// the codegen suite, that was ~80s pure waste on input that never
/// changes. The template's arena is leaked on purpose (one-shot,
/// process-lifetime); `*Type` pointers in cloned hashmaps continue
/// referencing it safely from every test's private env.
var stdlib_template_arena: std.heap.ArenaAllocator = undefined;
var stdlib_template_env: Env = undefined;
/// State machine for the lazy single-init: 0 = uninit, 1 = initing, 2 = ready.
/// Threads racing on the first call CAS 0→1 to claim init; losers spin on
/// `.load(.acquire)` until they observe 2. No mutex needed — the
/// init function runs exactly once, every other caller is read-only.
var stdlib_template_init: std.atomic.Value(u8) = .init(0);

pub fn getStdlibTemplate(gpa: std.mem.Allocator) !*const Env {
    while (true) {
        const s = stdlib_template_init.load(.acquire);
        if (s == 2) return &stdlib_template_env;
        if (s == 0) {
            if (stdlib_template_init.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            // We claimed init.
            stdlib_template_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            errdefer {
                stdlib_template_arena.deinit();
                stdlib_template_init.store(0, .release);
            }
            const arena = stdlib_template_arena.allocator();
            stdlib_template_env = Env.init(arena);
            try stdlib_template_env.registerBuiltins();
            try registerStdlib(&stdlib_template_env, gpa);
            try stdlib_template_env.bind("true", try stdlib_template_env.namedType("bool"));
            try stdlib_template_env.bind("false", try stdlib_template_env.namedType("bool"));
            stdlib_template_init.store(2, .release);
            return &stdlib_template_env;
        }
        // s == 1: another thread is initing. Spin (`std.Thread.yield` is
        // not available in 0.16; a cheap pause + reload is enough for the
        // microsecond init).
        std.atomic.spinLoopHint();
    }
}

fn analyzeSource(
    arena: std.mem.Allocator,
    mod: Module,
    source: []const u8,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    templateEvalCtx: ?envMod.TemplateEvalCtx,
    types_only: bool,
    skip_invoke: bool,
    target_name: ?[]const u8,
    reflection: *reflectionMod.Reflection,
) anyerror!AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);
    env.reflection = reflection;
    // Capture provenance for `expr` templates: which file is being inferred.
    env.modulePath = mod.path;
    // `@src().file` (decision 73): the package-relative display path.
    env.srcPath = try displaySrcPath(arena, mod);
    // The prelude registration may have named `SourceLocation`; only the
    // program's own references count (`withSourceLocationDecl`).
    env.usesSourceLocation = false;
    env.usesYieldStep = false;
    // Runtime-backed template expansion (F6-full) — null in tooling paths.
    env.templateEval = templateEvalCtx;
    env.skipDecoratorInvoke = skip_invoke;
    // STD-001 — codegen-path target name (null in LSP / tests). Consumed by
    // `markStdImports` to red imports of `from "std"` modules whose
    // host-bound declares lack an `#[@External.<Target>(…)]` match.
    env.target = target_name;
    env.typeDeclRegistry = typeDeclRegistry;

    var lexer = Lexer.init(source);
    const tokens = lexer.scanAll(arena) catch |err| switch (err) {
        error.OutOfMemory => return err,
        // A lex error is an outcome of this module, not a failure of the
        // whole session: the other modules still compile and get diagnosed.
        else => return .{ .parseError = .{ .lex = .{
            .name = @errorName(err),
            .info = lexer.lexError,
            .start = lexer.start,
            .end = lexer.current,
        } } },
    };

    var parser = Parser.init(tokens);
    const parsed_as_written = parser.parse(arena) catch |err| switch (err) {
        // The caller renders the diagnostic (`ComptimeOutput.parseError`); a
        // library call must not write to stderr — a test runner reads it.
        error.UnexpectedToken => return .{ .parseError = .{ .parse = parser.parseError } },
        else => return err,
    };
    // Decision 309 — an embedded std module's brace imports name `std/<path>`.
    // A dependency's module marks its imports with its package, so a path
    // item names that package's module (decisions 170, 337).
    const parsed = if (isStdPkgPath(mod.path)) try embeddedStdProgram(arena, parsed_as_written) else try ast.ImportDecl.withOwnPackage(arena, parsed_as_written, mod.package);
    // Decisions 110 / 111 on the use side: `io.fs.f()` through a folder
    // namespace and `collections.Dict.empty()` through a module one reach the
    // checker and the backends as the one-dot forms they lower.
    // Decision 207: an inline parameter type becomes a record of the module.
    // Decision 289: an anonymous default is named `default`, and an import of
    // a module holding a default binds that function.
    const defaulted = try default_fn.expandImports(arena, try default_fn.nameAnonymous(arena, parsed), templateRegistry, registry);
    // Decision 297: a `comptime x: V | type T` parameter's two forms.
    // Decision 330 (7): a type declared in a type's body is a top-level type
    // under its owner's path.
    const expanded = try nested_types.expand(arena, try value_or_type.expand(arena, try inline_types.expand(arena, try std_namespace.expand(arena, defaulted))));
    // Decision 216 (3): `Owner.Name` of an imported owner (or of this
    // module's, on a re-analysis) reaches the checker as the declared name.
    var owners = try assocOwners(arena, expanded, mod.path, typeDeclRegistry, reflection);
    const program = try assocTypes.expand(arena, expanded, &owners);
    // Decision 216 (4): a module reading `@TypeInfo.all` is answered on its
    // re-analysis, after its own decorators ran.
    const typeinfo_queries = if (skip_invoke) &.{} else try typeinfoAll.collect(arena, program);
    env.typeinfoAllPending = typeinfo_queries.len > 0;

    if (validation.validateComptime(program)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    resolveImports(&env, program, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    const bindings = infer.inferProgramTyped(&env, program) catch |err| switch (err) {
        error.TypeError => {
            const te = inline_types.locatedAtCall(env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } });
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };

    // A decorator body contributed generated declarations (`@emit`): inject
    // them as extra top-level decls and re-infer (decorators off, to avoid
    // re-emitting). Fast path parses each contribution into AST and appends
    // to the pass-1 program — skipping the re-lex/re-parse of the original
    // module bytes that the legacy text-splice path forced. Fallback to text
    // splicing only when a contribution fails to parse standalone.
    if (!skip_invoke and (env.contributions.items.len > 0 or env.memberContributions.items.len > 0 or env.typeContributions.items.len > 0 or typeinfo_queries.len > 0)) {
        // Decision 216 (1): the members join their types' bodies first, after
        // every line the module and its `@emit` contributions occupy.
        var with_members = program;
        if (env.memberContributions.items.len > 0) {
            var first_line: usize = std.mem.count(u8, source, "\n") + 1;
            var first_offset: usize = source.len + 1;
            for (env.contributions.items) |c| {
                first_line += std.mem.count(u8, c, "\n") + 1;
                first_offset += c.len + 1;
            }
            switch (try mergeMembers(arena, program, env.memberContributions.items, first_line, first_offset)) {
                .ok => |p| with_members = p,
                .refused => |te| {
                    env.deinit();
                    return .{ .typeError = te };
                },
            }
        }
        // Decision 216 (3): the associated types become top-level types, after
        // every line the members occupy.
        if (env.typeContributions.items.len > 0) {
            var first_line: usize = std.mem.count(u8, source, "\n") + 1;
            var first_offset: usize = source.len + 1;
            for (env.contributions.items) |c| {
                first_line += std.mem.count(u8, c, "\n") + 1;
                first_offset += c.len + 1;
            }
            for (env.memberContributions.items) |m| {
                first_line += std.mem.count(u8, m.source, "\n") + 1;
                first_offset += m.source.len + 1;
            }
            switch (try mergeAssocTypes(arena, with_members, env.typeContributions.items, first_line, first_offset)) {
                .ok => |p| with_members = p,
                .refused => |te| {
                    env.deinit();
                    return .{ .typeError = te };
                },
            }
        }
        // Decision 216 (4): every query answered, now that this module's
        // decorators ran too; the answers' imports join the program.
        var typeinfo_plan: ?typeinfoAll.Plan = null;
        if (typeinfo_queries.len > 0) {
            var first_line: usize = std.mem.count(u8, source, "\n") + 2;
            for (env.contributions.items) |c| first_line += std.mem.count(u8, c, "\n") + 1;
            for (env.memberContributions.items) |m| first_line += std.mem.count(u8, m.source, "\n") + 1;
            for (env.typeContributions.items) |t| first_line += std.mem.count(u8, t.source, "\n") + 1;
            switch (try typeinfoAll.plan(arena, &env, with_members, mod.path, reflection, typeinfo_queries, first_line)) {
                .ok => |pl| {
                    typeinfo_plan = pl;
                    const grown = try arena.alloc(ast.DeclKind, pl.imports.len + with_members.decls.len);
                    @memcpy(grown[0..pl.imports.len], pl.imports);
                    @memcpy(grown[pl.imports.len..], with_members.decls);
                    with_members = .{ .decls = grown };
                },
                .refused => |te| {
                    env.deinit();
                    return .{ .typeError = te };
                },
            }
        }
        if (try parseAndMergeContributions(arena, source, with_members, env.contributions.items)) |merged_program| {
            var reanalysis = try analyzeMerged(arena, mod, merged_program, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, target_name, reflection, typeinfo_plan);
            if (reanalysis == .success) {
                try keepPassOneTraces(&reanalysis.success.env, &env);
                env.deinit();
                return reanalysis;
            }
            // Pass-2 inference failed on the merged program (e.g. a contribution
            // references a symbol that needs the full project graph). Same
            // fallback contract as the legacy path: in types_only (LSP) we
            // surface pass-1 bindings so completion/hover degrade gracefully;
            // in CLI we propagate the error so codegen never runs on a
            // half-resolved module.
            if (types_only) {
                return .{ .success = .{ .bindings = bindings, .env = env, .program = program } };
            }
            env.deinit();
            return reanalysis;
        }
        // A contribution didn't parse on its own — fall back to text splice +
        // full re-lex so the parser sees the original module as one unit (its
        // diagnostics carry global offsets).
        const spliced = try spliceContributions(arena, source, env.contributions.items);
        var reanalysis = try analyzeSource(arena, mod, spliced, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, true, target_name, reflection);
        if (reanalysis == .success) {
            try keepPassOneTraces(&reanalysis.success.env, &env);
            env.deinit();
            return reanalysis;
        }
        if (types_only) {
            return .{ .success = .{ .bindings = bindings, .env = env, .program = program } };
        }
        env.deinit();
        return reanalysis;
    }

    return .{ .success = .{ .bindings = bindings, .env = env, .program = program } };
}

/// The "std" package: stdlib impl modules importable via `import {…} from "std";`.
/// The registry is DATA-DRIVEN — `build.zig` enumerates the package `.bp` files
/// and generates this `{ path, source }` table (re-exported by `prelude.zig`), so
/// compiler-core names no individual std module. Order = list order in build.zig
/// (a later module may import an earlier one). Registry keys are prefixed `std/`
/// so project-root imports never see them.
pub const std_pkg_modules = @import("std_prelude").pkg_modules;

/// The bundled packages (decisions 115–117): `std` first, then every library
/// the compiler ships and resolves by name with no `dependencies` entry. The
/// list is generated by `build.zig` (its `bundled_packages` constant — the only
/// place a name is spelled); each non-std entry carries its `.bp` modules,
/// which the CLI and the language server load as the ordinary modules
/// `<package>/<stem>`. To this pipeline a non-std bundled library is ordinary
/// code: only `std` keeps its std-only rules.
pub const BundledPackage = @import("std_prelude").BundledPackage;
pub const bundled_packages = @import("std_prelude").bundled_packages;

/// Decision 206 — the code of the refusal of `from "<a module of this
/// package>"`, for the driver that raises it (the CLI's module-tree resolver).
pub const module_import_with_from = diagnostics.module_import_with_from;

/// The bundled package called `name`, or null — `from "<name>"` resolves to it
/// wherever the import is written.
pub fn bundledPackage(name: []const u8) ?BundledPackage {
    for (bundled_packages) |p| {
        if (std.mem.eql(u8, p.name, name)) return p;
    }
    return null;
}

/// True when `source` holds an import `from "<name>"` (or the dotted
/// `from "<name>.<module>"`) — a lexical scan: the `from` keyword, spaces, then
/// the quoted package name, outside a `//` comment. A comment spelling one used
/// to load the package: harmless where it compiles, and a refusal where it
/// does not (a module header quoting `from "routing"` failed a wasm build on
/// `routing`'s host calls, in a program that imports nothing from it).
pub fn importsPackage(source: []const u8, name: []const u8) bool {
    var i: usize = 0;
    while (std.mem.indexOfPos(u8, source, i, "from")) |at| {
        i = at + 4;
        if (at > 0 and isIdentChar(source[at - 1])) continue;
        const line_start = if (std.mem.lastIndexOfScalar(u8, source[0..at], '\n')) |nl| nl + 1 else 0;
        if (std.mem.indexOf(u8, source[line_start..at], "//") != null) continue;
        var k = at + 4;
        if (k >= source.len or !(source[k] == ' ' or source[k] == '\t')) continue;
        while (k < source.len and (source[k] == ' ' or source[k] == '\t')) k += 1;
        if (k >= source.len or source[k] != '"') continue;
        k += 1;
        if (!std.mem.startsWith(u8, source[k..], name)) continue;
        const end = k + name.len;
        if (end < source.len and (source[end] == '"' or source[end] == '.')) return true;
    }
    return false;
}

fn isIdentChar(c: u8) bool {
    return std.ascii.isAlphanumeric(c) or c == '_';
}

/// The `@Decl` reflection cluster, in botopink, registered into the global type
/// env so a decorator body (`fn d(comptime decl: @Decl) { … }`) type-checks. The
/// canonical/documented copy lives in `libs/std/src/builtins.d.bp`; this minimal
/// mirror exists because that file is not parsed as a standalone program. Keep
/// the two in sync.
///
/// `Decl` is a `struct` (not an interface) so its **aggregate** members —
/// `fields`/`methods`/`annotations` with array types — parse and resolve; that
/// is what the wiring phase (P3) reads to build DI/router tables. The shape
/// matches the `@Decl` handle JSON `buildHandleJson` emits and the `__decl`
/// object `decorator_eval.zig` binds, so a body's `decl.fields`/`decl.kind`/
/// `decl.fail(…)` type-check against the same data the runtime provides.
///
/// Decision 277 — `decl.hooks: HookNode[]` (`comptime/hooks.zig`), with
/// `HookUse`, `HookCall` and the `TypeInfo<T>` a `use`'s type argument is; a
/// `DeclAnnotation` carries the `Decorator` it names.
///
/// T17 — the member records a handle hands out (`DeclAnnotation`, `Param`,
/// `Field`, `Method`) are registered under internal names (`__Decl__Param`,
/// shown `Decl.Param` in a diagnostic) that no module can declare or import,
/// and spelled through the aliases below; a module declaring or importing a
/// type of one of those names takes the name (`infer.zig`
/// `dropReflectionAlias`), so a decorator module that imports a user `Param`
/// still reads `m.params` of a `@Decl` as the reflection's `Param`.
pub const decl_reflection_src =
    \\pub type DeclKind { Type, Behavior, Fn, Method, Field, Val }
    \\pub type Span(start: i32, end: i32, line: i32)
    \\pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)
    \\pub behavior Decorator {}
    \\pub type __Decl__Annotation(name: string, args: string[], decorator: Decorator)
    \\pub type __Decl__Param(name: string, typeName: string)
    \\pub type __Decl__Field(name: string, typeName: string, annotations: __Decl__Annotation[])
    \\pub type __Decl__Method(name: string, params: __Decl__Param[], returnType: string, annotations: __Decl__Annotation[])
    \\pub type DeclAnnotation = __Decl__Annotation;
    \\pub type Param = __Decl__Param;
    \\pub type Field = __Decl__Field;
    \\pub type Method = __Decl__Method;
    \\pub type DeclaredMeta(key: string, value: string)
    \\pub type Declared<T>(name: string, module: string, meta: DeclaredMeta[], returnTypeName: string, value: T)
    \\pub type TypeInfo<T>(
    \\    name: string,
    \\    module: string,
    \\    fields: __Decl__Field[],
    \\    methods: __Decl__Method[],
    \\    meta: DeclaredMeta[],
    \\)
    \\pub type HookUse(
    \\    hook: ?Declared<unknown>,
    \\    annotations: __Decl__Annotation[],
    \\    at: string,
    \\    typeArgs: TypeInfo<unknown>[],
    \\    context: ?Declared<unknown>,
    \\)
    \\pub type HookCall(callee: Declared<unknown>, at: string)
    \\pub type HookNode(function: Declared<unknown>, uses: HookUse[], calls: HookCall[])
    \\pub type Decl(
    \\    kind: DeclKind,
    \\    name: string,
    \\    fields: __Decl__Field[],
    \\    variants: string[],
    \\    methods: __Decl__Method[],
    \\    returnType: string,
    \\    annotations: __Decl__Annotation[],
    \\    hooks: HookNode[]) {
    \\    declare fn fail(self: Self, message: string);
    \\    declare fn failAt(self: Self, span: Span, message: string);
    \\    declare fn addMember(self: Self, source: string);
    \\    declare fn setMeta(self: Self, key: string, value: string);
    \\    declare fn addType(self: Self, name: string, source: string);
    \\}
;

/// The `@ExprCustom` reference-tree type (expr-custom), registered into the
/// global env so a sub-language template body can BUILD a `CustomNode` tree
/// (`CustomNode(kind: …, span: …, …)`) and hand it to `q.custom`. Like the
/// `@Decl` cluster this mirrors the surface documented in
/// `libs/std/src/builtins.d.bp`; registered after `decl_reflection_src` so its
/// `Span` field type resolves. `Binding` (the `ref` field) is the same opaque
/// type `q.lookup` yields. Generic — the core never inspects `kind`/`label`.
const custom_ast_reflection_src =
    \\pub type CustomNode(
    \\    kind: string,
    \\    span: Span,
    \\    label: string,
    \\    ref: ?Binding,
    \\    children: CustomNode[],
    \\)
;

/// Decision 248 — the field descriptor `@makeRecord` reads, registered into
/// the global env; mirrors `libs/std/src/builtins.d.bp`'s `pub type
/// RecordField`. `TypeInfo<T>` (decisions 216, 253) is in the `@Decl` cluster
/// above, since a `HookUse` names it (decision 277); its static `all` is
/// reached only as the builtin `@TypeInfo.all`, so the mirror leaves it out.
const type_info_src =
    \\pub type RecordField(
    \\    name: string,
    \\    typeName: string,
    \\)
;

/// Decision 252 — every mirror above of a type `builtins.d.bp` declares, in
/// registration order; `comptime/builtins.zig`'s drift test holds each type
/// they declare to its declaration (fields, variants, instance methods), the
/// internal `__Decl__X` names read through their aliases.
pub const builtin_type_mirrors = [_][]const u8{ decl_reflection_src, custom_ast_reflection_src, type_info_src, yield_step_src };

/// `YieldStep<T>` (decision 122) — the one step of both sequences, `Yield`
/// then `Done`, registered into the global env so an annotation, a `case` over
/// its variants and a `.next()` called by hand type-check. The canonical copy
/// is `libs/std/src/builtins.d.bp`'s (`comptime/effect_chain.zig`'s drift test
/// reads it; `yield step prelude matches builtins.d.bp` below reads this one).
/// A module that names it gets `yield_step_decl_src` spliced in
/// (`withYieldStepDecl`).
const yield_step_src =
    \\pub type YieldStep<T> {
    \\    Yield(value: T),
    \\    Done,
    \\}
;

/// Embedded builtin-type interface declarations. Unlike `std_pkg_modules`
/// these are flattened into the global type env at infer time (they declare the
/// methods available on primitives / arrays / strings). Tooling — the language
/// server — scans these sources to resolve receiver methods such as `42.abs()`,
/// `true.to_string()`, `xs.map(…)` and `"s".len()`.
pub const primitive_interfaces_src = @import("std_prelude").primitives;
// Array<T> and String behaviors live inside primitives.bp (the controller)
// in the interface model — there are no standalone array/string modules.
pub const array_interface_src = @import("std_prelude").primitives;
pub const string_interface_src = @import("std_prelude").primitives;

/// True when `key` is the path of an embedded std module relative to the
/// package (`dict`, `io/fs`) — what an import item's segments joined with
/// `/` spell when the item names a module rather than a symbol of one
/// (decision 107). The codegens ask this to tell the namespace form
/// (`import {io.fs}` binds the module) from the symbol form
/// (`import {io.fs.readText}` binds one of its `pub` declarations).
pub fn isStdModule(key: []const u8) bool {
    for (std_pkg_modules) |spm| {
        if (std.mem.eql(u8, spm.path["std/".len..], key)) return true;
    }
    return false;
}

/// Decision 170 — the shorthand import (`import {x};`, no `from`) names "the
/// sibling that exports it": it resolves among the importing package's own
/// modules and never reaches a BUNDLED package (`http/lexical`, `routing/match`)
/// or std, which are reached only by naming them (`from "http"`, `from
/// "std"`). Without it a bundled package loaded by any module of the program
/// made the importer's own `charOf` `ambiguous-import-use`. A module of the
/// bundled package itself keeps its siblings in reach.
fn outsideShorthandReach(env: *envMod.Env, u: ast.ImportDecl, path: []const u8) bool {
    if (u.source != .root) return false;
    // A module of a dependency reaches its own package's modules alone: a
    // module is its package plus its path, and another package's `theme` is
    // never this package's sibling (decisions 170, 337).
    if (u.ownPackage.len > 0) return !ast.ImportSource.ofPackage(u.ownPackage, path);
    const seg = path[0 .. std.mem.indexOfScalar(u8, path, '/') orelse return false];
    if (bundledPackage(seg) == null) return false;
    const own = env.modulePath[0 .. std.mem.indexOfScalar(u8, env.modulePath, '/') orelse env.modulePath.len];
    return !std.mem.eql(u8, own, seg);
}

/// Decision 206 — the package an import `from "<pkg>"` is confined to: `pkg`
/// when the program holds modules of it (`<pkg>/…`, a dependency or a bundled
/// package), else null — the package is the one being compiled (a bundled
/// library's own tests name it while its modules are the program's own), and
/// the source reads as before. A module of the importing package named like
/// the package (`log` beside the bundled `log`) is never in scope: `from`
/// names a package, and the module is imported by its path inside the braces.
fn packageScope(registry: anytype, source: ast.ImportSource) ?[]const u8 {
    const pkg = source.packageName() orelse return null;
    var it = registry.keyIterator();
    while (it.next()) |k| {
        if (ast.ImportSource.ofPackage(pkg, k.*)) return pkg;
    }
    return null;
}

/// True when `scope` confines a lookup and `path` is not a module of it.
fn outOfScope(scope: ?[]const u8, path: []const u8) bool {
    const pkg = scope orelse return false;
    return !ast.ImportSource.ofPackage(pkg, path);
}

/// True when `path` is a "std" package registry key (`std/<module>`).
fn isStdPkgPath(path: []const u8) bool {
    return std.mem.startsWith(u8, path, "std/");
}

/// Scans `modules` for `import {…} from "std"` declarations and returns the
/// module list with the required embedded std modules prepended (dependency
/// order, deduplicated). Modules that fail to parse pass through untouched —
/// `analyzeModule` reports the parse error later.
///
/// On a BEAM target (`target_name` `erlang` or `beam`) a module that declares a
/// module-level `var` needs `std/beam` too, whether or not it imports it: the
/// emitters lower the binding's reads and writes onto that module's host
/// primitives (front 17, decision 43's layer 2), so the module has to be in
/// the build for the calls to answer.
fn expandStdImports(arena: std.mem.Allocator, modules: []const Module, target_name: ?[]const u8) ![]const Module {
    var needed = [_]bool{false} ** std_pkg_modules.len;
    var any = false;
    const beam_target = if (target_name) |t| std.mem.eql(u8, t, "erlang") or std.mem.eql(u8, t, "beam") else false;
    for (modules) |mod| {
        var lx = Lexer.init(mod.source);
        const tokens = lx.scanAll(arena) catch continue;
        var p = Parser.init(tokens);
        // The same rewrite `analyzeSource` makes, so a module reached only
        // through a folder namespace (`io.fs.f()`) or a module's type
        // (`collections.Dict.empty()`) is embedded like any imported one.
        const program = std_namespace.expand(arena, p.parse(arena) catch continue) catch continue;
        for (program.decls) |decl| switch (decl) {
            .val => |v| if (beam_target and v.mutable) {
                for (std_pkg_modules, 0..) |spm, i| {
                    if (std.mem.eql(u8, spm.path, "std/beam")) {
                        needed[i] = true;
                        any = true;
                    }
                }
            },
            .use => |u| {
                if (!importsStd(u, isStdPkgPath(mod.path))) continue;
                for (u.imports) |imp| {
                    // Decision 107 — the item names a module by its whole path
                    // (`io.fs`, the namespace form) or a symbol of the module
                    // its prefix names (`io.fs.readText`); a single segment is
                    // both spellings of `dict`. Whichever matches is needed.
                    const whole = try imp.fullPath(arena);
                    const prefix = try imp.prefixPath(arena);
                    for (std_pkg_modules, 0..) |spm, i| {
                        const key = spm.path["std/".len..];
                        if (std.mem.eql(u8, key, whole) or (prefix.len > 0 and std.mem.eql(u8, key, prefix))) {
                            needed[i] = true;
                            any = true;
                        }
                    }
                }
            },
            else => {},
        };
    }
    if (!any) return modules;

    // A std module that imports another std module needs it too, however deep
    // the chain goes, and each one is emitted after what it imports.
    var changed = true;
    while (changed) {
        changed = false;
        for (std_pkg_modules, 0..) |spm, i| {
            if (!needed[i]) continue;
            for (try stdImportsOf(arena, spm.source)) |dep| if (!needed[dep]) {
                needed[dep] = true;
                changed = true;
            };
        }
    }

    var out: std.ArrayListUnmanaged(Module) = .empty;
    for (try stdModuleOrder(arena)) |i| {
        const spm = std_pkg_modules[i];
        // An embedded std module is `libs/std/src/<name>.bp` inside its own
        // package, so that is what its `@src().file` answers (decision 73).
        if (needed[i]) try out.append(arena, .{
            .path = spm.path,
            .source = spm.source,
            .srcPath = try std.fmt.allocPrint(arena, "src/{s}.bp", .{spm.path["std/".len..]}),
        });
    }
    try out.appendSlice(arena, modules);
    return out.toOwnedSlice(arena);
}

/// Whether `u` imports std modules: `from "std"`, or — inside a std module
/// (`in_std`) — the brace form with no `from` (decision 309), which names a
/// sibling of the module's own package, std.
fn importsStd(u: ast.ImportDecl, in_std: bool) bool {
    if (u.package != null or u.activationOnly) return false;
    return switch (u.source) {
        .module => |m| std.mem.eql(u8, m, "std"),
        .key => false,
        .root => in_std,
    };
}

/// Decision 309 — a std module imports a sibling by the brace form
/// (`import {path.relative};`), which std's own package build resolves among
/// std's modules (`path`). Embedded in another build, the module is
/// `std/<mod>` and its siblings are `std/<path>`, reached the way every other
/// module reaches std: so each brace import of the module reads as
/// `from "std"`, and the checker, the type exports and the four backends see
/// the import they already lower.
fn embeddedStdProgram(arena: std.mem.Allocator, program: ast.Program) !ast.Program {
    const decls = try arena.dupe(ast.DeclKind, program.decls);
    for (decls) |*d| switch (d.*) {
        .use => |*u| if (importsStd(u.*, true)) {
            u.source = .{ .module = "std" };
        },
        else => {},
    };
    var out = program;
    out.decls = decls;
    return out;
}

/// The file an embedded std module was built from, as its checkout names it:
/// `std/path` is `libs/std/src/path.bp`.
fn embeddedStdFile(arena: std.mem.Allocator, path: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "libs/std/src/{s}.bp", .{path["std/".len..]});
}

/// Lex and parse an embedded std module. One that does not is a defect of
/// this build, met before any program module is read: its diagnostic is
/// printed located at the std file (`embeddedStdDiagnostic`) and the build
/// stops with `error.EmbeddedStdRefused`. A bare `try` answered the CLI's
/// `compilation failed` / `UnexpectedToken`, naming no file and no line — a
/// reserved word used as a name in a `libs/std/src` file read that way.
pub fn parseEmbeddedStd(arena: std.mem.Allocator, path: []const u8, source: []const u8) !ast.Program {
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(arena) catch |err| {
        if (err == error.OutOfMemory) return err;
        std.debug.print("{s}", .{try embeddedStdDiagnostic(arena, path, source, &lx, null)});
        return error.EmbeddedStdRefused;
    };
    var p = Parser.init(tokens);
    return p.parse(arena) catch |err| {
        if (err == error.OutOfMemory) return err;
        std.debug.print("{s}", .{try embeddedStdDiagnostic(arena, path, source, null, &p)});
        return error.EmbeddedStdRefused;
    };
}

/// The located diagnostic of an embedded std module that did not lex
/// (`lexer`) or parse (`parser`): the parse error rendered as any module's
/// is (`print.render`), at `libs/std/src/<module>.bp`.
pub fn embeddedStdDiagnostic(arena: std.mem.Allocator, path: []const u8, source: []const u8, lexer: ?*const Lexer, parser: ?*const Parser) ![]const u8 {
    const file = try embeddedStdFile(arena, path);
    if (parser) |p| {
        const info = p.parseError orelse blk: {
            if (p.tokens.len == 0) break :blk null;
            break :blk @import("./parser.zig").ParseErrorInfo.fromToken(.unexpectedToken, p.tokens[@min(p.current, p.tokens.len - 1)]);
        };
        if (info) |i| return @import("./print.zig").renderAlloc(arena, i, source, file);
    }
    if (lexer) |lx| if (lx.lexError) |le| {
        const start = @min(le.start, source.len);
        var line: usize = 1;
        var col: usize = 1;
        for (source[0..start]) |c| {
            if (c == '\n') {
                line += 1;
                col = 1;
            } else col += 1;
        }
        return std.fmt.allocPrint(arena,
            \\error: {s}
            \\ --> {s}:{d}:{d}
            \\
            \\
        , .{ @import("./lexer.zig").lexicalErrorMessage(le), file, line, col });
    };
    return std.fmt.allocPrint(arena,
        \\error: the embedded std module does not parse
        \\ --> {s}
        \\
        \\
    , .{file});
}

/// The std modules `source` (a std module) imports — `import {json};` or a
/// leaf of one, `import {json.quote};` (decision 309's brace form; the
/// `from "std"` spelling reads the same) — as indices into
/// `std_pkg_modules`. A source that does not parse imports nothing here; its
/// own compile reports the error.
fn stdImportsOf(arena: std.mem.Allocator, source: []const u8) ![]const usize {
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(arena) catch return &.{};
    var p = Parser.init(tokens);
    const program = p.parse(arena) catch return &.{};
    var out: std.ArrayListUnmanaged(usize) = .empty;
    for (program.decls) |decl| {
        if (decl != .use) continue;
        const u = decl.use;
        if (!importsStd(u, true)) continue;
        for (u.imports) |imp| {
            const whole = try imp.fullPath(arena);
            const prefix = try imp.prefixPath(arena);
            for (std_pkg_modules, 0..) |spm, i| {
                const key = spm.path["std/".len..];
                if (std.mem.eql(u8, key, whole) or (prefix.len > 0 and std.mem.eql(u8, key, prefix))) {
                    try out.append(arena, i);
                }
            }
        }
    }
    return out.toOwnedSlice(arena);
}

/// Every std module's index, each after the std modules it imports
/// (`stdImportsOf`), otherwise in `std_pkg_modules` order. A cycle keeps the
/// declaration order for the modules on it; checking the importer then reports
/// the module it could not find.
fn stdModuleOrder(arena: std.mem.Allocator) ![]const usize {
    const n = std_pkg_modules.len;
    const state = try arena.alloc(u8, n); // 0 unvisited · 1 on the path · 2 placed
    @memset(state, 0);
    var out: std.ArrayListUnmanaged(usize) = .empty;
    const Visit = struct {
        fn visit(a: std.mem.Allocator, i: usize, st: []u8, o: *std.ArrayListUnmanaged(usize)) !void {
            if (st[i] != 0) return;
            st[i] = 1;
            for (try stdImportsOf(a, std_pkg_modules[i].source)) |dep| try visit(a, dep, st, o);
            st[i] = 2;
            try o.append(a, i);
        }
    };
    for (0..n) |i| try Visit.visit(arena, i, state, &out);
    return out.toOwnedSlice(arena);
}

fn resolveImports(
    env: *envMod.Env,
    program: anytype,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
) !void {
    for (program.decls) |decl| {
        switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root, .key => false,
                };
                // Package-namespace import (`import pkg [, { … }] [from "…"]`):
                // bind `pkg` to the package's `pub default fn` (aliased under the
                // package handle = the `pub default mod` name by `registerExports`
                // / the compile driver). Internal (`import pkg`, local call) and
                // external (`from "pkg"`, cross-module) resolve the same way — the
                // default fn is a template fn, expanded at the call site, so no
                // cross-module call ever reaches codegen. The named-item list of
                // `import pkg, { a, b }` is bound by the loop below as usual.
                if (u.package) |pkg| {
                    // Value/type binding so a bare `pkg "…"` callee type-checks
                    // (mirrors the named-import value binding below).
                    var pkg_owner: []const u8 = "";
                    var pit = registry.iterator();
                    while (pit.next()) |e| {
                        if (isStdPkgPath(e.key_ptr.*)) continue;
                        if (e.value_ptr.get(pkg)) |ty| {
                            try env.bind(pkg, ty);
                            pkg_owner = e.key_ptr.*;
                            break;
                        }
                    }
                    // Template-fn binding so the call expands at comptime.
                    if (templateRegistry.get(pkg)) |tfn| {
                        try infer.registerImportedTemplateFn(env, pkg, tfn, pkg_owner);
                        try importTemplateSupport(env, decoratorRegistry, pkg_owner, tfn.name, tfn);
                        if (registry.getPtr(pkg_owner)) |ex| try env.templateOwnerExports.put(env.arena, pkg_owner, ex);
                    }
                }
                // Decision 206 — `from "<pkg>"` names a package: its lookups
                // admit only the package's modules (`<pkg>/…`), never a
                // module of the importing package named like it.
                const scope = packageScope(registry, u.source);
                for (u.imports) |imp| {
                    if (from_std) {
                        // `import {bool} from "std"` — handled inside
                        // inference (`inferProgramTyped` marks `stdImports`,
                        // gating qualified calls on `env.stdModules`).
                        continue;
                    }
                    // Decision 107 — the item may carry a path: the leaf is
                    // what is looked up (`name`), in the module the prefix
                    // names (`leaf_src` — `import {html.div} from "web"`
                    // narrows to `web/html`, the bare
                    // `import {shapes.circle.name};` to `shapes/circle`), and
                    // what is bound is the alias when one is written
                    // (`local`). A single-segment item keeps today's shape:
                    // `name == local`, `leaf_src == u.source`.
                    const name = imp.leaf();
                    const local = imp.name();
                    const leaf_src = try u.leafSource(imp, env.arena, false);
                    // Decision 107's namespace form over a module of this
                    // package or a dependency: the item's whole path names a
                    // module (`import {jwt} from "sec"` → `sec/jwt`, `import
                    // {text};` → `text`), and the name binds a namespace its
                    // calls resolve against — ahead of the bare-name scan
                    // below, which would bind some other module's `text`.
                    // A symbol of that name in the module the source names
                    // wins (a lib's template handle `qlib` beside its module
                    // `qlib/qlib`).
                    const names_symbol = blk: {
                        // …or in the module the whole path names
                        // (`import {canvas} from "shapes"` for `shapes/canvas`'s
                        // own `canvas`).
                        switch (try u.leafSource(imp, env.arena, true)) {
                            .module, .key => |path| if (registry.get(path)) |exports| if (exports.contains(name)) break :blk true,
                            .root => {},
                        }
                        var sit = registry.iterator();
                        while (sit.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*)) continue;
                            if (outOfScope(scope, e.key_ptr.*)) continue;
                            if (leaf_src.namesModule(e.key_ptr.*) and e.value_ptr.contains(name)) break :blk true;
                        }
                        break :blk false;
                    };
                    if (!imp.activate and !names_symbol) switch (try u.leafSource(imp, env.arena, true)) {
                        .module, .key => |path| if (!isStdPkgPath(path)) if (registry.get(path)) |exports| {
                            try env.namespaces.modules.put(env.arena, local, exports);
                            try env.namespaces.paths.put(env.arena, local, path);
                            var eit = exports.keyIterator();
                            while (eit.next()) |fname| {
                                if (templateRegistry.get(try defaultParamsKey(env.arena, path, fname.*))) |pfn| {
                                    try env.namespaces.params.put(env.arena, try envMod.NamespaceImports.paramsKey(env.arena, local, fname.*), pfn.params);
                                }
                            }
                            continue;
                        },
                        .root => {},
                    };
                    // Bare import: same-package (project root) resolution only —
                    // never resolves "std" package modules. An imported nominal
                    // type carries its full declaration across the module
                    // boundary (re-registered below) so its `TypeDef` metadata —
                    // `implements`/`contextBase`/fields — is visible here, not
                    // just its constructor value. This mirrors the `from "std"`
                    // type-export path (`stdModuleTypes` → `registerTypeDecl`).
                    // Both registries are keyed by module PATH and were walked
                    // taking the first entry that held `name` — so `from
                    // "<mod>"`, the one thing that says WHICH module the import
                    // means, was never consulted. A name is unique inside a
                    // module and not over a program: `libs/std` declares
                    // `parse` in `json`, in `querystring` and in `url` today.
                    // Measured before this: a module importing `Outcome` from
                    // "parser" was bound to "net"'s `Outcome` and the program
                    // was REFUSED against the wrong record's fields
                    // ("expected i32, got string").
                    //
                    // So the module the source NAMES answers first, and the old
                    // whole-registry scan is the second pass — a `from "<pkg>"`
                    // handle covers several modules and names none of them, a
                    // bare `import { … };` names nothing at all, and a module
                    // not yet analysed is in neither pass — so every case that
                    // used to reach the scan still reaches it.
                    var bound_type_decl = false;
                    var bound_behavior = false;
                    for ([3]u2{ 0, 1, 2 }) |pass| {
                        if (bound_type_decl or bound_behavior) break;
                        var dit = typeDeclRegistry.iterator();
                        while (dit.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*)) continue;
                            if (!leaf_src.admits(e.key_ptr.*, pass) or outsideShorthandReach(env, u, e.key_ptr.*) or outOfScope(scope, e.key_ptr.*)) continue;
                            if (e.value_ptr.get(name)) |type_decl| {
                                // A behavior is not re-registered as a type:
                                // its value binding below stays what it was,
                                // and the importer only learns its methods.
                                if (type_decl == .behavior) {
                                    try env.importedBehaviorDecls.put(env.arena, name, type_decl.behavior);
                                    bound_behavior = true;
                                    break;
                                }
                                // A type's identity is its declared name on
                                // every backend; an alias would bind a name
                                // the emitted code never defines.
                                // The same declaration reached by an earlier
                                // item of this module (`import {catalog.Widget};`
                                // beside a `@TypeInfo.all` answer's
                                // `import {Widget as __bp_ti_0} from "catalog";`)
                                // is registered once: registering it again
                                // would rebind its constructor, and an alias
                                // bound to the first one would stop naming it.
                                var seen = false;
                                var tit = env.importedTypeDecls.valueIterator();
                                while (tit.next()) |prev| {
                                    if (std.mem.eql(u8, prev.name, name) and std.mem.eql(u8, prev.module, e.key_ptr.*)) seen = true;
                                }
                                try env.importedTypeDecls.put(env.arena, local, .{ .name = name, .module = e.key_ptr.* });
                                if (!seen) {
                                    try infer.registerImportedTypeClosure(env, e.value_ptr.*, type_decl);
                                    try infer.registerImportedTypeDecl(env, type_decl);
                                }
                                // Decision 110 — `as` binds a type leaf like any
                                // other: a checker-local alias of the declared
                                // name, which is the emitted identity.
                                if (imp.alias) |al| try infer.registerImportedTypeAlias(env, type_decl, al, imp.loc);
                                bound_type_decl = true;
                                break;
                            }
                        }
                    }
                    // Value/constructor binding. Skipped for nominal types whose
                    // declaration was just re-registered — `registerTypeDecl`
                    // already bound the constructor with the importing module's
                    // own type ids, and clobbering it with the exported `*T.Type`
                    // would reintroduce the defining module's ids.
                    // C-01 — the module that exports `name`, found the way
                    // the value binding below finds it (the named module
                    // first): a template or decorator evaluated here names it
                    // in its module atom.
                    var owner: []const u8 = "";
                    for ([3]u2{ 0, 1, 2 }) |pass| {
                        if (owner.len > 0) break;
                        var oit = registry.iterator();
                        while (oit.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*)) continue;
                            if (!leaf_src.admits(e.key_ptr.*, pass) or outsideShorthandReach(env, u, e.key_ptr.*) or outOfScope(scope, e.key_ptr.*)) continue;
                            if (e.value_ptr.contains(name)) {
                                owner = e.key_ptr.*;
                                break;
                            }
                        }
                    }
                    // Another module the backends' name-keyed lookup would also
                    // read declares the name — one this lookup left out of
                    // reach: a bundled package beside the shorthand (decision
                    // 170), a module of this package beside `from "<pkg>"`, or
                    // the package `log` beside the module path `log.levelName`
                    // (decision 206). The backends must be told which module
                    // the item names (`withImportSourcesNamed`); std is never
                    // in such a scan.
                    if (owner.len > 0) {
                        var xit = registry.iterator();
                        while (xit.next()) |e| {
                            const k = e.key_ptr.*;
                            if (isStdPkgPath(k) or std.mem.eql(u8, k, owner)) continue;
                            if (!e.value_ptr.contains(name)) continue;
                            const left_out = outsideShorthandReach(env, u, k) or outOfScope(scope, k);
                            if (!left_out and !leaf_src.admits(k, 0) and !leaf_src.admits(k, 1)) continue;
                            try env.itemOwners.put(env.arena, imp.loc, owner);
                            break;
                        }
                    }
                    var bound_value = false;
                    // `00 · 01-std` — the refusal of a duplicate `pub` name
                    // belongs to the consumer's unqualified USE: when the
                    // first scan that finds the name finds it in two modules
                    // (a bare `import {parse};`, a package handle that narrows
                    // to no module), the name is two identities, and nothing
                    // here says which. It stays unbound, and every use of it is
                    // refused where it is written, naming both
                    // (`infer.unboundAt` reads `NamespaceImports.ambiguous`).
                    if (!bound_type_decl) ambiguity: {
                        for ([3]u2{ 0, 1, 2 }) |pass| {
                            var owners: std.ArrayListUnmanaged([]const u8) = .empty;
                            var ait = registry.iterator();
                            while (ait.next()) |e| {
                                if (isStdPkgPath(e.key_ptr.*)) continue;
                                if (!leaf_src.admits(e.key_ptr.*, pass) or outsideShorthandReach(env, u, e.key_ptr.*) or outOfScope(scope, e.key_ptr.*)) continue;
                                if (e.value_ptr.contains(name)) try owners.append(env.arena, e.key_ptr.*);
                            }
                            if (owners.items.len == 0) continue;
                            if (owners.items.len == 1) break :ambiguity;
                            std.mem.sort([]const u8, owners.items, {}, struct {
                                fn lessThan(_: void, a: []const u8, b: []const u8) bool {
                                    return std.mem.order(u8, a, b) == .lt;
                                }
                            }.lessThan);
                            try env.namespaces.ambiguous.put(env.arena, local, owners.items);
                            bound_value = true;
                            owner = "";
                            break :ambiguity;
                        }
                    }
                    if (!bound_type_decl and !bound_value) {
                        for ([3]u2{ 0, 1, 2 }) |pass| {
                            if (bound_value) break;
                            var it = registry.iterator();
                            while (it.next()) |e| {
                                if (isStdPkgPath(e.key_ptr.*)) continue;
                                if (!leaf_src.admits(e.key_ptr.*, pass) or outsideShorthandReach(env, u, e.key_ptr.*) or outOfScope(scope, e.key_ptr.*)) continue;
                                if (e.value_ptr.get(name)) |ty| {
                                    try env.bind(local, ty);
                                    // The types its signature names come
                                    // with it, as types only (01 R2).
                                    if (typeDeclRegistry.get(e.key_ptr.*)) |decls| try infer.registerImportedSignatureClosure(env, decls, ty);
                                    bound_value = true;
                                    break;
                                }
                            }
                        }
                    }
                    // Imported template fns (`-> @Expr<…>`) carry their decl
                    // across modules so call sites here can expand them.
                    // One local name is one declaration. Two imports that each
                    // name their module (`import {title} from "app.page";
                    // import {title} from "app.blog.page";`) are two answered
                    // questions bound to ONE name: the second used to
                    // overwrite the first here and every backend picked its
                    // own — commonJS called `app/page`'s, erlang and wasm
                    // `app/blog/page`'s, with no diagnostic
                    // (`infer.noteImportBindings` compares the item's path
                    // and not its source, so it read the two as one repeated
                    // item). Refused at the second item; `as` is the remedy.
                    // The same declaration imported twice — an `@emit`
                    // contribution re-importing what its module imports — is
                    // one declaration and passes.
                    if (owner.len > 0) if (env.importOwners.get(local)) |first| {
                        if (!std.mem.eql(u8, first.owner, owner) or !std.mem.eql(u8, first.name, name)) {
                            const msg = try std.fmt.allocPrint(
                                env.arena,
                                "{s}: `{s}` is already bound by the import of `{s}` from `{s}`; `{s}` from `{s}` would bind it again",
                                .{ diagnostics.import_name_collision, local, first.name, first.owner, name, owner },
                            );
                            const hint = try std.fmt.allocPrint(env.arena, "Rename one of the two with `as` (`import {{{s} as other}} from \"{s}\"`): each alias then reaches its own declaration.", .{ name, owner });
                            env.lastError = validation.TypeError.custom(msg, hint).withLoc(imp.loc);
                            return error.TypeError;
                        }
                    };
                    if (owner.len > 0) try env.importOwners.put(env.arena, local, .{ .owner = owner, .name = name });
                    if (owner.len > 0) if (templateRegistry.get(try comptimeRegistryKey(env.arena, owner, name))) |tfn| {
                        try infer.registerImportedTemplateFn(env, local, tfn, owner);
                        try importTemplateSupport(env, decoratorRegistry, owner, name, tfn);
                        if (registry.getPtr(owner)) |ex| try env.templateOwnerExports.put(env.arena, owner, ex);
                    };
                    // C-04 — an imported function's parameters as written, so
                    // a call here that omits a trailing default is filled.
                    if (owner.len > 0) if (templateRegistry.get(try defaultParamsKey(env.arena, owner, name))) |pfn| {
                        try env.fnParams.put(local, pfn.params);
                    };
                    // Imported decorators (`comptime _: @Decl` first param) carry
                    // their decl across modules too, so `#[name(args)]` sites in
                    // THIS module argument-check against the marker and run its
                    // body over each annotated declaration at comptime. Without
                    // this a marker only fired in its defining module — a lib
                    // ships its decorators, but they are applied by importers.
                    if (owner.len > 0) if (decoratorRegistry.get(try comptimeRegistryKey(env.arena, owner, name))) |dfn| {
                        var support: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
                        var si: usize = 0;
                        while (decoratorRegistry.get(try decoratorSupportKey(env.arena, owner, name, si))) |sf| : (si += 1) {
                            try support.append(env.arena, sf);
                        }
                        const conflict = if (decoratorRegistry.get(try decoratorConflictKey(env.arena, owner, name))) |c| c.name else null;
                        try infer.registerImportedDecorator(env, local, dfn, owner, support.items, conflict);
                    };
                    // An imported plain function, with what it reaches in its
                    // own module: a decorator of THIS module that calls it
                    // carries it (`infer.decoratorSupport`). Bound under the
                    // local name; under the declared one too when an alias
                    // differs, since the function's own module calls it so.
                    if (owner.len > 0) if (decoratorRegistry.get(try decoratorClosureKey(env.arena, owner, name, 0))) |head| {
                        var closure: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
                        var renamed = head;
                        renamed.name = local;
                        try closure.append(env.arena, renamed);
                        if (!std.mem.eql(u8, local, name)) try closure.append(env.arena, head);
                        var ci: usize = 1;
                        while (decoratorRegistry.get(try decoratorClosureKey(env.arena, owner, name, ci))) |cf| : (ci += 1) {
                            try closure.append(env.arena, cf);
                        }
                        try env.importedFnSupport.put(env.arena, local, closure.items);
                    };
                    // Imported + activated extension (`import { Name* } from "mod"`):
                    // an `implement` block defined in another module is opted into
                    // THIS module's dispatch table only when the importer stars it.
                    // Local extensions auto-apply; imported ones are opt-in by `*`.
                    if (imp.activate) {
                        var eit = extensionRegistry.iterator();
                        while (eit.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*) or outOfScope(scope, e.key_ptr.*)) continue;
                            if (e.value_ptr.get(name)) |impl_decl| {
                                try infer.registerImportedExtension(env, impl_decl);
                                break;
                            }
                        }
                    }
                }
            },
            else => {},
        }
    }
}

/// Cross-module aggregation for the package-default DSL. A package's
/// `pub default mod` (the `import <pkg>` handle) and `pub default fn` (the
/// handler) may live in different modules; this pairs them — keyed by package key
/// (the module-path prefix before the first `/`, "" for the root package) — so
/// the handler can be aliased under the handle for `import <pkg>` to bind.
const DefaultDsl = struct {
    /// pkgKey -> default module name (= the import handle).
    modName: std.StringHashMap([]const u8),
    /// pkgKey -> the package's default handler fn (defining path + exported type).
    handler: std.StringHashMap(Handler),

    const Handler = struct { path: []const u8, type_: *T.Type, decl: ast.FnDecl };

    fn init(a: std.mem.Allocator) DefaultDsl {
        return .{
            .modName = std.StringHashMap([]const u8).init(a),
            .handler = std.StringHashMap(Handler).init(a),
        };
    }
};

/// 01 step 12's registry half (decisions-pending 01std-d) — the template and
/// decorator registries are keyed by the EXPORTING module and the name
/// (`<path>\x00<name>`), never by the bare name: two modules exporting a
/// `validated` decorator used to leave whichever registered last, so an
/// import of one ran the other. `resolveImports` looks a name up under the
/// module that exports it. A package's default handler stays under its bare
/// handle (`registerExports`), which is what `import <pkg>` names.
fn comptimeRegistryKey(arena: std.mem.Allocator, path: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ path, name });
}

/// The `decoratorRegistry` key of the `i`-th function decorator `name` of
/// module `path` needs beside it (`infer.decoratorSupport`). No import item
/// can spell it: it holds two NULs.
fn decoratorSupportKey(arena: std.mem.Allocator, path: []const u8, name: []const u8, i: usize) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}\x00support\x00{d}", .{ path, name, i });
}

/// Key of a `pub fn`'s closure in `decoratorRegistry`: entry 0 is the
/// function, the rest what it reaches (`Env.importedFnSupport`).
fn decoratorClosureKey(arena: std.mem.Allocator, path: []const u8, name: []const u8, i: usize) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}\x00closure\x00{d}", .{ path, name, i });
}

/// Key of an exported decorator's `infer.Support.conflict`. The registry holds
/// `FnDecl`s, so the message rides in a bodyless one's name
/// (`conflictCarrier`) — never a function anything calls.
fn decoratorConflictKey(arena: std.mem.Allocator, path: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}\x00conflict", .{ path, name });
}

/// `f` with its tuple label reads by position when `f` is a function of the
/// module being exported (`fns`): the reads were recorded by THIS module's
/// inference, keyed by location, so a function another module brought is
/// left as it came (it was relabelled when that module exported it).
fn relabelLocal(arena: std.mem.Allocator, env: *const envMod.Env, fns: *const std.StringHashMap(ast.FnDecl), f: ast.FnDecl) !ast.FnDecl {
    const own = fns.get(f.name) orelse return f;
    if (own.body.ptr != f.body.ptr) return f;
    return templateEval.relabelTupleReads(arena, &env.tupleLabelReads, f);
}

/// A function whose return is a template type (`-> @Expr<T>`, …): expanded at
/// its call sites, never compiled as a function.
fn isTemplateFn(f: ast.FnDecl) bool {
    const rt = f.returnType orelse return false;
    return rt.isTemplateReturnType();
}

/// Binds what the template `tfn`, exported by module `owner` under `name`,
/// carries beside it (`registerExports`: the functions its body reaches, or
/// why its module cannot be built) in `Env.importedTemplateSupport`, keyed by
/// the declaration's body as `Env.comptimeOwners` is.
fn importTemplateSupport(
    env: *envMod.Env,
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    owner: []const u8,
    name: []const u8,
    tfn: ast.FnDecl,
) !void {
    if (owner.len == 0 or tfn.body.len == 0) return;
    var support: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
    var si: usize = 0;
    while (decoratorRegistry.get(try decoratorSupportKey(env.arena, owner, name, si))) |sf| : (si += 1) {
        try support.append(env.arena, sf);
    }
    const conflict = if (decoratorRegistry.get(try decoratorConflictKey(env.arena, owner, name))) |c| c.name else null;
    try env.importedTemplateSupport.put(env.arena, @intFromPtr(tfn.body.ptr), .{ .fns = support.items, .conflict = conflict });
    try importTemplateAliasClosures(env, decoratorRegistry, owner);
}

/// 01-compiler/14 step 8 — the built code of a template of `owner` names the
/// owner's functions under their aliases (`envMod.templateAlias`, decision
/// 112); a `comptime` that reaches an expansion (`block_eval.zig`) carries
/// each such function with its closure, as it carries an imported one. Every
/// `pub fn` of `owner` with a closure (`decoratorClosureKey`) is bound in
/// `Env.importedFnSupport` under its alias, the head renamed to it.
fn importTemplateAliasClosures(
    env: *envMod.Env,
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    owner: []const u8,
) !void {
    const prefix = try std.fmt.allocPrint(env.arena, "{s}\x00", .{owner});
    const suffix = "\x00closure\x000";
    var it = decoratorRegistry.iterator();
    while (it.next()) |e| {
        const key = e.key_ptr.*;
        if (!std.mem.startsWith(u8, key, prefix) or !std.mem.endsWith(u8, key, suffix)) continue;
        const name = key[prefix.len .. key.len - suffix.len];
        if (std.mem.indexOfScalar(u8, name, 0) != null) continue;
        const alias = try envMod.templateAlias(env.arena, owner, name);
        if (env.importedFnSupport.contains(alias)) continue;
        var closure: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
        var head = e.value_ptr.*;
        head.name = alias;
        try closure.append(env.arena, head);
        // The function's own module calls it by its declared name.
        try closure.append(env.arena, e.value_ptr.*);
        var ci: usize = 1;
        while (decoratorRegistry.get(try decoratorClosureKey(env.arena, owner, name, ci))) |cf| : (ci += 1) {
            try closure.append(env.arena, cf);
        }
        try env.importedFnSupport.put(env.arena, alias, closure.items);
    }
}

fn conflictCarrier(message: []const u8) ast.FnDecl {
    return .{ .name = message, .isPub = false, .genericParams = &.{}, .params = &.{}, .returnType = null, .body = &.{} };
}

/// The `templateRegistry` key of the parameter list, as written, of the `pub fn`
/// `name` of module `path` (C-04 across a module boundary, and the labels of a
/// labelled call). No import item can spell it: it holds two NULs.
fn defaultParamsKey(arena: std.mem.Allocator, path: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}\x00params", .{ path, name });
}

/// The package key for a module path: the segment before the first `/` (a lib
/// dependency is loaded as `<lib>/<stem>`), or "" for a root-package module.
fn pkgKey(path: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, path, '/')) |i| return path[0..i];
    return "";
}

/// The key under which a module's type-declaration map (`typeDeclRegistry`)
/// holds a type it IMPORTS rather than declares: `"\x00" ++ name`. No import
/// item can spell it, so an importer's `get(name)` never answers with one —
/// the module does not re-export what it imports. Only the type closure of an
/// imported type reads it (`infer.registerImportedTypeClosure`): `Outer`'s
/// fields name `Other`, which `Outer`'s module took from a third one.
pub const imported_type_scope_prefix = "\x00";

/// Onze F2 — record in `typeDecls` the types this module imports, and the
/// imported-type scope of the modules they come from, under
/// `imported_type_scope_prefix`. A module that imports `Outer` from here then
/// resolves `Outer(others: Array<Other>)` without naming `Other`, however
/// many modules the chain crosses. This module's own imports win a collision.
fn addImportedTypeScope(
    arena: std.mem.Allocator,
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    typeDecls: *std.StringHashMap(ast.DeclKind),
    decls: []const ast.DeclKind,
) !void {
    const P = imported_type_scope_prefix;
    var inherited: std.ArrayListUnmanaged(std.StringHashMap(ast.DeclKind)) = .empty;
    for (decls) |d| {
        if (d != .use) continue;
        const u = d.use;
        const from_std = switch (u.source) {
            .module => |m| std.mem.eql(u8, m, "std"),
            .root, .key => false,
        };
        if (from_std) {
            // A std type leaf (`import {collections.Dict} from "std"`) is in
            // the scope too: `RouteMatch(params: Dict<…>)` imported from here
            // gives its importer `Dict`'s methods without naming `Dict`, as a
            // type of this package would. Only the leaf of a qualified item
            // names a type; a module leaf (`{collections}`) brings none.
            for (u.imports) |imp| {
                if (!imp.isQualified()) continue;
                const mod_path = try std.mem.concat(arena, u8, &.{ "std/", try imp.prefixPath(arena) });
                const std_types = typeDeclRegistry.get(mod_path) orelse continue;
                const decl = std_types.get(imp.leaf()) orelse continue;
                if (decl != .type_ and decl != .typeAlias) continue;
                const key = try std.mem.concat(arena, u8, &.{ P, imp.leaf() });
                if (!typeDecls.contains(key)) try typeDecls.put(key, decl);
            }
            continue;
        }
        const scope = packageScope(typeDeclRegistry, u.source);
        for (u.imports) |imp| {
            const name = imp.leaf();
            const leaf_src = try u.leafSource(imp, arena, false);
            var found = false;
            for ([3]u2{ 0, 1, 2 }) |pass| {
                if (found) break;
                var it = typeDeclRegistry.iterator();
                while (it.next()) |e| {
                    if (isStdPkgPath(e.key_ptr.*)) continue;
                    if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
                    const decl = e.value_ptr.get(name) orelse continue;
                    const key = try std.mem.concat(arena, u8, &.{ P, name });
                    if (!typeDecls.contains(key)) try typeDecls.put(key, decl);
                    try inherited.append(arena, e.value_ptr.*);
                    found = true;
                    break;
                }
            }
        }
    }
    for (inherited.items) |m| {
        var it = m.iterator();
        while (it.next()) |e| {
            const k = e.key_ptr.*;
            const key = if (std.mem.startsWith(u8, k, P)) k else try std.mem.concat(arena, u8, &.{ P, k });
            if (!typeDecls.contains(key)) try typeDecls.put(key, e.value_ptr.*);
        }
    }
}

fn registerExports(
    arena: std.mem.Allocator,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *std.StringHashMap(ast.FnDecl),
    extensionRegistry: *std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    dsl: *DefaultDsl,
    path: []const u8,
    bindings: []const infer.TypedBinding,
    decls: []const ast.DeclKind,
    env: *envMod.Env,
) !void {
    var exports = std.StringHashMap(*T.Type).init(arena);
    var typeDecls = std.StringHashMap(ast.DeclKind).init(arena);
    // A `pub` `implement` block is carried across the module boundary so an
    // importer that stars it (`import { Name* }`) can dispatch through it. These
    // come from the AST decls — an `implement` produces no `TypedBinding`.
    var extensions = std.StringHashMap(ast.ImplementDecl).init(arena);
    for (decls) |d| switch (d) {
        .implement => |im| if (im.isPub) try extensions.put(im.name, im),
        else => {},
    };
    // Decision 112 — a module declaring a template exports its PRIVATE
    // functions and values too, under a key no import can spell
    // (`envMod.templatePrivateKey`): the template's own text names them, and
    // that text resolves in this module wherever it is expanded.
    const declares_template = declaresTemplateFn(decls);
    for (bindings) |b| {
        if (b.name.len == 0 or b.decl == .use) continue;
        if (declares_template and (b.decl == .@"fn" or b.decl == .val)) {
            const private = switch (b.decl) {
                .@"fn" => |f| !f.isPub,
                .val => |v| !v.isPub,
                else => false,
            };
            if (private) try exports.put(try envMod.templatePrivateKey(arena, b.name), env.lookup(b.name) orelse b.type_);
        }
        // A type alias exports its declaration only — it names no value, and
        // an importer re-registers it (`registerTypeDecl`) to substitute it.
        if (b.decl == .typeAlias) {
            if (b.decl.typeAlias.isPub) try typeDecls.put(b.name, b.decl);
            continue;
        }
        const is_pub = switch (b.decl) {
            .val => |v| v.isPub,
            .@"fn" => |f| f.isPub,
            else => true,
        };
        if (is_pub) {
            const ty = env.lookup(b.name) orelse b.type_;
            try exports.put(b.name, ty);
            // `pub` nominal type declarations export their full AST decl too, so
            // the importing module can re-register the `TypeDef` (implements /
            // contextBase / fields) — not just the constructor value. Mirrors
            // the `from "std"` type-export path (`stdModuleTypes`), which is also
            // `pub`-only. Non-pub types still export their constructor (above)
            // for value use, but carry no cross-module `TypeDef`.
            switch (b.decl) {
                .type_ => |t| if (t.isPub) try typeDecls.put(b.name, b.decl),
                // A `pub behavior` too: an importer learns which methods it
                // declares (`Env.importedBehaviorDecls`) — it registers no
                // `TypeDef` from it.
                .behavior => |bd| if (bd.isPub) try typeDecls.put(b.name, b.decl),
                else => {},
            }
            // Template fns export their declaration too — importing modules
            // expand their calls at comptime (the decl never reaches codegen).
            if (b.decl == .@"fn") {
                const f = b.decl.@"fn";
                if (f.returnType) |rt| {
                    // Its tuple label reads by position (`relabelTupleReads`):
                    // the importer lowers the body untyped, without this
                    // module's inference.
                    if (rt.isTemplateReturnType()) try templateRegistry.put(try comptimeRegistryKey(arena, path, b.name), try templateEval.relabelTupleReads(arena, &env.tupleLabelReads, f));
                }
                // C-04 across a module boundary — a function exports its
                // parameters as written, so an importer's short call is filled
                // like a local one and a labelled call is checked and lowered
                // by label (01), never zipped by position. A default that names
                // a binding of this module cannot be written at the importer's
                // call site: that parameter travels without it, and a call
                // omitting it stays the arity error it was.
                if (!infer.isDecoratorParams(f.params)) {
                    const params = try arena.dupe(ast.Param, f.params);
                    for (params) |*p| if (p.default) |d| if (!infer.isClosedDefault(d)) {
                        p.default = null;
                    };
                    var carried = f;
                    carried.params = params;
                    try templateRegistry.put(try defaultParamsKey(arena, path, b.name), carried);
                }
                // Decorators (`comptime _: @Decl` first param) export their decl
                // too, so importing modules can run the body over their annotated
                // declarations — generic, by shape, no lib name involved.
                var fns = std.StringHashMap(ast.FnDecl).init(arena);
                for (decls) |d| if (d == .@"fn") try fns.put(d.@"fn".name, d.@"fn");
                if (infer.isDecoratorParams(f.params)) {
                    try decoratorRegistry.put(try comptimeRegistryKey(arena, path, b.name), f);
                    // The functions its body reaches travel with it
                    // (`decoratorSupportKey`) — its module's and the ones the
                    // module imports: the importer's module declares none of
                    // them, and the decorator module needs them.
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    for (support.fns, 0..) |sf, i| try decoratorRegistry.put(try decoratorSupportKey(arena, path, b.name, i), sf);
                    if (support.conflict) |c| try decoratorRegistry.put(try decoratorConflictKey(arena, path, b.name), conflictCarrier(c));
                } else if (isTemplateFn(f)) {
                    // A template carries the functions its body reaches the
                    // same way (decision 331, calls included): the template
                    // module is built where the template is EXPANDED, whose
                    // module declares none of them. Same keys as a
                    // decorator's — a template is never one.
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    for (support.fns, 0..) |sf, i| try decoratorRegistry.put(try decoratorSupportKey(arena, path, b.name, i), try relabelLocal(arena, env, &fns, sf));
                    if (support.conflict) |c| try decoratorRegistry.put(try decoratorConflictKey(arena, path, b.name), conflictCarrier(c));
                } else if (infer.isCarriableFn(f)) {
                    // A plain `pub fn` carries itself and what it reaches
                    // (`decoratorClosureKey`), so a decorator of a module
                    // that imports it can call it: entry 0 is the function,
                    // the rest are the functions of this module (and of its
                    // own imports) its body reaches.
                    try decoratorRegistry.put(try decoratorClosureKey(arena, path, b.name, 0), f);
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    if (support.conflict == null) {
                        for (support.fns, 1..) |sf, i| try decoratorRegistry.put(try decoratorClosureKey(arena, path, b.name, i), sf);
                    }
                }
            }
        }
    }
    try addImportedTypeScope(arena, typeDeclRegistry, &typeDecls, decls);
    try registry.put(path, exports);
    try typeDeclRegistry.put(path, typeDecls);
    try extensionRegistry.put(path, extensions);

    // Package-default DSL: record this module's `pub default mod` (the import
    // handle) and `pub default fn` (the handler), then — once both halves of the
    // package are known — alias the handler under the handle so `import <pkg>`
    // binds it. Per-module duplicates already errored in inference; first-seen
    // wins for the cross-module edge case.
    const key = pkgKey(path);
    for (decls) |d| switch (d) {
        .mod => |m| if (m.isDefault and !dsl.modName.contains(key)) {
            try dsl.modName.put(key, m.name);
        },
        else => {},
    };
    // Decision 289 — the module's default function, for `default_fn.expandImports`.
    for (decls) |d| switch (d) {
        .@"fn" => |f| if (f.isDefault) try templateRegistry.put(try default_fn.key(arena, path), f),
        else => {},
    };
    for (bindings) |b| {
        if (b.decl == .@"fn" and b.decl.@"fn".isDefault and !dsl.handler.contains(key)) {
            const ty = env.lookup(b.name) orelse b.type_;
            try dsl.handler.put(key, .{ .path = path, .type_ = ty, .decl = b.decl.@"fn" });
        }
    }
    if (dsl.modName.get(key)) |handle| {
        if (dsl.handler.get(key)) |h| {
            // Value/type binding under the handle (in the handler's own exports
            // table) + the handler decl under the handle in the template registry.
            if (registry.getPtr(h.path)) |exps| try exps.put(handle, h.type_);
            try templateRegistry.put(handle, h.decl);
        }
    }
}

/// Parse stdlib prelude modules and register their inferred types into `env`:
/// interface declarations flatten into the global env; "std" package impl
/// modules (`std_pkg_modules`) each get their own exports table in
/// `env.stdModules` (consumed by `import {…} from "std"` qualified calls).
/// Returns `program` with its top-level `test` decls removed. Stdlib
/// registration infers *declarations* into the type env; co-located `test`
/// blocks are for the test runner, not registration (inferring them here would
/// require full method-dispatch support at registration time). Allocates the
/// filtered decl slice in `alloc`.
fn stripTestDecls(program: ast.Program, alloc: std.mem.Allocator) !ast.Program {
    var kept: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (program.decls) |decl| {
        if (decl == .@"test") continue;
        try kept.append(alloc, decl);
    }
    var out = program;
    out.decls = try kept.toOwnedSlice(alloc);
    return out;
}

/// Register the `@Decl` reflection cluster (`decl_reflection_src` — `Span`,
/// `Annotation`, `Decl`, … and 1.0.10-beta's `SourceLocation`) into `env`.
/// Called for the global env and for every scratch env `registerStdlib` infers
/// a std module in, so a std module's signature may name a prelude record.
fn registerReflectionPrelude(env: *Env) anyerror!void {
    const alloc = env.arena;
    var lx = Lexer.init(decl_reflection_src);
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);
    _ = try infer.inferProgram(env, program);
}

/// Decision 252 — every builtin's declaration into `env.builtinDecls`: each
/// top-level `declare fn` of `builtins.d.bp` and `builtins_fns.d.bp`, and each
/// static `declare fn` of a type there (`TypeInfo.all`). Parsed into
/// `env.arena`, which the declarations' slices outlive with the env.
fn registerBuiltinDecls(env: *Env) anyerror!void {
    const prelude = @import("std_prelude");
    for ([_][]const u8{ prelude.builtins, prelude.builtin_fns }) |src| {
        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(env.arena);
        var p = Parser.init(tokens);
        const program = try p.parse(env.arena);
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| if (f.isDeclare) try env.builtinDecls.put(f.name, .{
                .genericParams = f.genericParams,
                .params = f.params,
                .returnType = f.returnType,
            }),
            // An unannotated `declare fn` parses as a delegate declaration.
            .delegate => |f| try env.builtinDecls.put(f.name, .{
                .genericParams = f.genericParams,
                .params = f.params,
                .returnType = f.returnType,
            }),
            .type_ => |t| for (t.methods) |m| {
                if (!m.is_declare) continue;
                if (m.params.len > 0 and std.mem.eql(u8, m.params[0].name, "self")) continue;
                try env.builtinDecls.put(try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ t.name, m.name }), .{
                    .genericParams = m.genericParams,
                    .params = m.params,
                    .returnType = m.returnType,
                });
            },
            else => {},
        };
    }
}

pub fn registerStdlib(env: *Env, gpa: std.mem.Allocator) anyerror!void {
    _ = gpa; // stdlib sources are now parsed into `env.arena` (see below)
    const prelude = @import("std_prelude");
    const sources = [_][]const u8{
        prelude.primitives,
    };
    for (sources) |src| {
        // Parse into `env.arena` (not a scratch arena): the interface decls for
        // primitive associated fns (`Pair`, `Function`, …) are retained in
        // `env.assocInterfaceDecls` and emitted by codegen, so they must outlive
        // this call.
        const alloc = env.arena;

        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try stripTestDecls(try p.parse(alloc), alloc);
        _ = try infer.inferProgram(env, program);
    }

    // The `@Decl` reflection cluster (annotation processors): register these
    // types into the global env so a decorator body type-checks — `decl.kind` /
    // `decl.name` / `decl.fields` / … and `decl.fail(…)`, plus the `Field` /
    // `Method` / `Param` / `Annotation` shapes it reads. This mirrors the surface
    // documented in `libs/std/src/builtins.d.bp` (kept there for tooling); it is
    // parsed from a dedicated minimal source here because the full `builtins.d.bp`
    // is the tooling/`@Expr` surface and is not consumed as a standalone program.
    try registerReflectionPrelude(env);

    // The `@ExprCustom` reference-tree type (expr-custom): registered after the
    // `@Decl` cluster so a sub-language template body can construct `CustomNode`
    // values for `q.custom`. Its `Span` field resolves against the struct just
    // registered above.
    {
        const alloc = env.arena;
        var lx = Lexer.init(custom_ast_reflection_src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }

    // `TypeInfo<T>` (what `@typeInfo(T)` answers) and `RecordField` (what
    // `@makeRecord` reads). Registered after `custom_ast_reflection_src` so the
    // global env carries the complete comptime surface.
    {
        const alloc = env.arena;
        var lx = Lexer.init(type_info_src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }

    // `YieldStep<T>` (decision 122): the step `.next()` answers on an
    // `@Iterator` / `@Stream`.
    {
        const alloc = env.arena;
        var lx = Lexer.init(yield_step_src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }

    // `builtins_fns.d.bp`: the parseable fn-decl slice of `builtins.d.bp`
    // (todo / panic / trap / emit / module / getContext / field). Parse it
    // here so a bare `todo()` / `panic()` call at user code resolves to the
    // declared `FnDecl` and `expandTrailingDefaults` injects the trailing
    // literal default into `c.args` before dispatch. The full doc surface
    // (Result / Future / Generator / ResultGenerator / FutureGenerator / Context
    // interfaces) stays in `builtins.d.bp` — re-parsing it here would red
    // on the synthetic interfaces already registered by `registerBuiltins`.
    {
        const alloc = env.arena;
        var lx = Lexer.init(prelude.builtin_fns);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        // Inference will still type-check the fn decls so any future
        // call-site work reads a real signature; we only care about the
        // FnDecl carrier here. Best-effort: a parse/inference red here
        // would stop the compiler from booting, so a failure surfaces
        // immediately.
        _ = try infer.inferProgram(env, program);
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| try env.stdlibFnDecls.put(f.name, f),
            else => {},
        };
    }

    try registerBuiltinDecls(env);

    // A std module may import another (`import {json} from "std"`): each is
    // inferred after the ones it imports, and sees their exports, types and
    // functions exactly as a program's module does.
    for (try stdModuleOrder(env.arena)) |spm_index| {
        const spm = std_pkg_modules[spm_index];
        const mod_name = spm.path["std/".len..];
        // Each std module is inferred in a scratch env (so its fn names don't
        // flatten into — or collide across — the global env), sharing `env`'s
        // arena so the resulting types outlive the scratch maps.
        var env2 = Env.init(env.arena);
        defer env2.deinit();
        try env2.registerBuiltins();
        // `true`/`false` are bound by `freshEnv` for project envs — the scratch
        // env needs them too (inline `test` bodies in std modules use them).
        try env2.bind("true", try env2.namedType("bool"));
        try env2.bind("false", try env2.namedType("bool"));
        // `SourceLocation` (1.0.10-beta decision 73) is a prelude record a std
        // module may name in a signature (`snapshots.path(loc: SourceLocation)`);
        // the scratch env has to know the same prelude the importer's env does.
        try registerReflectionPrelude(&env2);
        {
            var it = env.builtinDecls.iterator();
            while (it.next()) |e| try env2.builtinDecls.put(e.key_ptr.*, e.value_ptr.*);
        }
        {
            var it = env.stdModules.iterator();
            while (it.next()) |e| try env2.stdModules.put(e.key_ptr.*, e.value_ptr.*);
            var tit = env.stdModuleTypes.iterator();
            while (tit.next()) |e| try env2.stdModuleTypes.put(e.key_ptr.*, e.value_ptr.*);
            var fit = env.stdModuleFns.iterator();
            while (fit.next()) |e| try env2.stdModuleFns.put(e.key_ptr.*, e.value_ptr.*);
        }
        for (sources) |src| {
            var lx = Lexer.init(src);
            const tokens = try lx.scanAll(env.arena);
            var p = Parser.init(tokens);
            const program = try stripTestDecls(try p.parse(env.arena), env.arena);
            _ = try infer.inferProgram(&env2, program);
        }
        // Decision 330 (7): a std type's associated types are top-level types
        // of the module (`Type.Field` is `Type__Field`).
        const parsed_std = try embeddedStdProgram(env.arena, try stripTestDecls(try parseEmbeddedStd(env.arena, spm.path, spm.source), env.arena));
        // `Owner.Name` written in the module's own source — a member of
        // `Type` taking `Type.Field<T>` — names that one top-level type, as
        // `analyzeSource` rewrites it for a program's module; left dotted, an
        // importer registering the owner meets a name it cannot resolve.
        var std_owners: std.StringHashMapUnmanaged(assocTypes.Owner) = .empty;
        for (parsed_std.decls) |d| if (d == .type_ and d.type_.assocTypes.len > 0) {
            try std_owners.put(env.arena, d.type_.name, .{ .name = d.type_.name, .assoc = try nested_types.namesOf(env.arena, d.type_) });
        };
        const program = try assocTypes.expand(env.arena, try nested_types.expand(env.arena, parsed_std), &std_owners);
        const bindings = try infer.inferProgramTyped(&env2, program);

        // Collect the module's public type declarations so `import {…} from
        // "std"` can register them into the importing env (type export —
        // enables case patterns / annotations over e.g. `Order`).
        {
            var type_decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
            for (program.decls) |decl| {
                const is_pub_type = switch (decl) {
                    .type_ => |t| t.isPub,
                    .typeAlias => |a| a.isPub,
                    else => false,
                };
                if (is_pub_type) try type_decls.append(env.arena, decl);
            }
            if (type_decls.items.len > 0) {
                try env.stdModuleTypes.put(mod_name, try type_decls.toOwnedSlice(env.arena));
            }
        }

        // STD-001 — collect every `pub fn` of this std module so a future
        // `markStdImports` red can read the per-target `externalFor` set
        // without re-parsing. The FnDecl slice points into `env.arena` (the
        // shared parse arena), so callers see stable references.
        {
            var fn_decls: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
            for (program.decls) |decl| {
                switch (decl) {
                    .@"fn" => |f| if (f.isPub) try fn_decls.append(env.arena, f),
                    else => {},
                }
            }
            if (fn_decls.items.len > 0) {
                try env.stdModuleFns.put(mod_name, try fn_decls.toOwnedSlice(env.arena));
            }
        }

        var exports = std.StringHashMap(*T.Type).init(env.arena);
        for (bindings) |b| {
            if (b.name.len == 0 or b.decl == .use) continue;
            const is_pub = switch (b.decl) {
                .val => |v| v.isPub,
                .@"fn" => |f| f.isPub,
                else => false,
            };
            if (is_pub) {
                const ty = env2.lookup(b.name) orelse b.type_;
                try exports.put(b.name, ty);
            }
        }
        try env.stdModules.put(mod_name, exports);
    }
}

/// Collect the comptime `val` entries of `bindings` and fold them, returning
/// the value listing (null when there are none) and the evaluated literals.
pub fn evaluateComptime(
    allocator: std.mem.Allocator,
    bindings: []const infer.TypedBinding,
    /// Decision 331 — the values inference lifted (`Env.srcRewrites`): a
    /// `comptime` the Zig folder cannot read ran on the comptime runtime, and
    /// its listing shows the expression the program is emitted with.
    lifted: ?*const std.AutoHashMap(ast.Loc, *const ast.Expr),
) !ComptimeEvalResult {
    var entries: std.ArrayListUnmanaged(evalMod.ComptimeEntry) = .empty;
    defer {
        for (entries.items) |e| {
            allocator.free(e.id);
            allocator.free(e.source);
            if (e.lifted) |l| allocator.free(l);
        }
        entries.deinit(allocator);
    }
    for (bindings, 0..) |b, i| {
        const te = b.typedExpr orelse continue;
        if (!te.isComptimeExpr()) continue;
        const id = try std.fmt.allocPrint(allocator, "ct_{d}", .{i});
        errdefer allocator.free(id);
        var decl = [_]ast.DeclKind{b.decl};
        const source = format.format(allocator, .{ .decls = &decl }) catch try allocator.dupe(u8, b.name);
        errdefer allocator.free(source);
        const shown: ?[]const u8 = shown: {
            const map = lifted orelse break :shown null;
            if (b.decl != .val or validation.isFoldable(b.decl.val.value.*)) break :shown null;
            const value = map.get(b.decl.val.value.getLoc()) orelse break :shown null;
            break :shown try liftedText(allocator, value);
        };
        try entries.append(allocator, .{ .id = id, .expr = te, .source = source, .lifted = shown });
    }

    if (entries.items.len == 0) {
        return .{
            .comptime_script = null,
            .comptime_vals = std.StringHashMap([]const u8).init(allocator),
        };
    }

    const result = try evalMod.evaluate(allocator, entries.items);
    return .{ .comptime_script = result.script, .comptime_vals = result.values };
}

/// A lifted value as the formatter writes it (`Dict(pairs: [])`), for the
/// `COMPTIME VALUES` listing. Owned by `allocator`.
fn liftedText(allocator: std.mem.Allocator, value: *const ast.Expr) ![]const u8 {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    const copy = try arena.create(ast.Expr);
    copy.* = value.*;
    var decl = [_]ast.DeclKind{.{ .val = .{ .name = "v", .value = copy } }};
    const text = try format.format(arena, .{ .decls = &decl });
    const head = "val v = ";
    const start = if (std.mem.indexOf(u8, text, head)) |i| i + head.len else 0;
    return allocator.dupe(u8, std.mem.trimEnd(u8, std.mem.trimEnd(u8, text[start..], "\n"), ";"));
}

// ── LSP entry point: type inference only ─────────────────────────────────────

/// Lex, parse, and infer types for each module **without** evaluating the
/// ordinary comptime entries (`comptime_script`/`comptime_vals` stay empty).
/// Intended for tooling (LSP, linters).
///
/// `eval_ctx` is opt-in: when null, template functions whose bodies need the
/// node-backed evaluator are left unexpanded (the original types-only contract,
/// no external runtime). When supplied (`{ io, build_root }`), template bodies
/// are expanded exactly as the full `compile` pipeline does — the LSP passes it
/// so `@ExprCustom` templates run and surface their `CustomNode` trees on
/// `OkData.custom_ast` (sublanguage-lsp). Spawning `node` per compile is the
/// documented latency cost; callers that must not touch the filesystem/runtime
/// pass null.
///
/// Returns a `ComptimeSession` whose outputs always have `.ok.comptime_script = null`
/// and `.ok.comptime_vals` empty. Caller must call `session.deinit(allocator)`.
pub fn compileTypesOnly(
    allocator: std.mem.Allocator,
    modules: []const Module,
    eval_ctx: ?envMod.TemplateEvalCtx,
) !ComptimeSession {
    // No target: decision 84's default, beam (the language server's pass).
    const prev_runtime = hostRuntime.select(hostRuntime.forTarget(null));
    defer _ = hostRuntime.select(prev_runtime);

    var session = ComptimeSession{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .outputs = .empty,
    };
    errdefer session.arena.deinit();

    const arena_alloc = session.arena.allocator();
    var registry = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena_alloc);
    var type_decl_registry = std.StringHashMap(std.StringHashMap(ast.DeclKind)).init(arena_alloc);
    var template_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var decorator_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var extension_registry = std.StringHashMap(std.StringHashMap(ast.ImplementDecl)).init(arena_alloc);
    // Decision 216 — what decorators record for reflection, for this session.
    var reflection = reflectionMod.Reflection.init(arena_alloc);
    var default_dsl = DefaultDsl.init(arena_alloc);

    // `from "std"` imports pull the embedded std modules into the compilation.
    // Non-std libs are ordinary input modules: the driver supplies their `.bp`
    // sources and `resolveImports` binds `from "<lib>"` through the shared
    // registry — the core names no specific lib (std is the one exception).
    var reader_refusals: std.AutoHashMapUnmanaged(usize, validation.TypeError) = .empty;
    const all_modules = try orderReaders(arena_alloc, try expandStdImports(arena_alloc, modules, null), &reflection, &reader_refusals);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        if (reader_refusals.get(idx)) |te| {
            try session.outputs.append(allocator, .{ .name = name, .src = mod.source, .srcPath = mod.srcPath, .outcome = .{ .typeError = te } });
            continue;
        }
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, eval_ctx, true, null, &reflection);

        switch (analysis) {
            .parseError => |se| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .parseError = se },
                });
            },
            .validationError => |verr| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .validationError = verr.info },
                });
            },
            .typeError => |te| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .typeError = te },
                });
            },
            .success => |succ| {
                var dispatch_rewrites = std.AutoHashMap(ast.Loc, []const u8).init(arena_alloc);
                {
                    var rit = succ.env.dispatchRewrites.iterator();
                    while (rit.next()) |e| try dispatch_rewrites.put(e.key_ptr.*, e.value_ptr.*);
                }
                var js_method_renames = std.AutoHashMap(ast.Loc, []const u8).init(arena_alloc);
                {
                    var rit = succ.env.jsMethodRenames.iterator();
                    while (rit.next()) |e| try js_method_renames.put(e.key_ptr.*, e.value_ptr.*);
                }
                var instance_lowerings = std.AutoHashMap(ast.Loc, envMod.InstanceLowering).init(arena_alloc);
                {
                    var rit = succ.env.instanceLowerings.iterator();
                    while (rit.next()) |e| try instance_lowerings.put(e.key_ptr.*, e.value_ptr.*);
                    var dit = succ.env.divisions.iterator();
                    while (dit.next()) |e| if (infer.arithKind(e.value_ptr.*)) |k| {
                        // An operator's loc never holds another lowering; were
                        // one there (a `+=` keyed by its target's name), it wins.
                        const slot = try instance_lowerings.getOrPut(e.key_ptr.*);
                        if (!slot.found_existing) slot.value_ptr.* = .{ .division = k };
                    };
                }
                if (idx < all_modules.len - 1) {
                    var env = succ.env;
                    try registerExports(arena_alloc, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, &default_dsl, mod.path, succ.bindings, succ.program.decls, &env);
                    // NOTE: no env.deinit() here — `env` is a copy whose hashmap
                    // internals are shared with `succ.env`, and the transform
                    // below still reads `succ.env.method_lowerings`. The env is
                    // arena-backed; the session arena reclaims it wholesale.
                }

                var fn_decls = std.StringHashMap(ast.FnDecl).init(arena_alloc);
                {
                    // Stdlib fn decls (see `compile` for the same seed): a
                    // bare `todo()` call inside an LSP-typed-only session
                    // still wants `expandTrailingDefaults` to find the
                    // builtin FnDecl, otherwise the transform pass renders a
                    // mismatched zero-arg shape.
                    var sit = succ.env.stdlibFnDecls.iterator();
                    while (sit.next()) |e| try fn_decls.put(e.key_ptr.*, e.value_ptr.*);
                }
                for (succ.bindings) |b| {
                    if (b.decl == .@"fn") try fn_decls.put(b.name, try expr_param.eraseFn(arena_alloc, b.decl.@"fn", infer.isDecoratorParams(b.decl.@"fn".params)));
                }

                const empty_vals = std.StringHashMap([]const u8).init(arena_alloc);
                // Prepend synthetic imports for stdlib modules implicitly used via
                // array method dispatch (e.g. `xs.isEmpty()` → needs `list` required).
                const program_for_transform = blk: {
                    var synth: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
                    var mit = succ.env.implicitStdModules.keyIterator();
                    while (mit.next()) |mod_name| {
                        if (succ.env.stdImports.contains(mod_name.*)) continue;
                        const segs = try arena_alloc.alloc([]const u8, 1);
                        segs[0] = mod_name.*;
                        const paths = try arena_alloc.alloc(ast.ImportPath, 1);
                        paths[0] = .{ .segments = segs };
                        try synth.append(arena_alloc, .{ .use = .{
                            .imports = paths,
                            .source = .{ .module = "std" },
                        } });
                    }
                    if (synth.items.len == 0) break :blk succ.program;
                    const new_decls = try arena_alloc.alloc(ast.DeclKind, synth.items.len + succ.program.decls.len);
                    @memcpy(new_decls[0..synth.items.len], synth.items);
                    @memcpy(new_decls[synth.items.len..], succ.program.decls);
                    break :blk ast.Program{ .decls = new_decls };
                };
                // Lowering is best-effort here: a degraded module (decorator
                // `@emit` that couldn't type-check standalone, surfaced for the
                // LSP via the types-only fallback) may carry incomplete lowering
                // maps. The LSP reads `bindings`/`custom_ast`, not `transformed`,
                // so on a transform error we keep the untransformed program
                // rather than blanking the whole session.
                const transformed = blk_t: {
                    const t = transform.transform(
                        arena_alloc,
                        try expr_param.eraseProgram(arena_alloc, program_for_transform, infer.isDecoratorParams),
                        fn_decls,
                        std.StringHashMap([]const ast.TypedExpr).init(arena_alloc),
                        empty_vals,
                        &succ.env.method_lowerings,
                        &succ.env.templateExpansions,
                        &succ.env.srcRewrites,
                        &succ.env.result_jump_lowerings,
                        &succ.env.stdArrayLowerings,
                        &succ.env.enumSectionRewrites,
                        &succ.env.indexRewrites,
                        &succ.env.optionalNullCases,
                        succ.env.ctorParams,
                        &succ.env.defaultInjections,
                        &succ.env.resultPatternLocs,
                        &succ.env.namespaces,
                    ) catch break :blk_t program_for_transform;
                    const hygienic = withTemplateHygiene(arena_alloc, t, &succ.env, declaresTemplateFn(program_for_transform.decls)) catch break :blk_t t;
                    const with_assoc = withUsedAssocInterfaces(arena_alloc, hygienic, &succ.env) catch break :blk_t hygienic;
                    const with_enums = withSynthesisedEnumDecls(arena_alloc, with_assoc, &succ.env) catch with_assoc;
                    const with_src = withSourceLocationDecl(arena_alloc, with_enums, &succ.env) catch with_enums;
                    const with_step = withYieldStepDecl(arena_alloc, with_src, &succ.env) catch with_src;
                    const erased = alias_erase.erase(arena_alloc, with_step, &succ.env.typeAliases) catch with_step;
                    break :blk_t withImportSourcesNamed(arena_alloc, withImportTypeAliasesErased(arena_alloc, erased, &succ.env) catch erased, &succ.env) catch erased;
                };

                var type_ids = std.StringHashMap(usize).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.typeId) |id| try type_ids.put(b.name, id);
                }

                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .ok = .{
                        .bindings = succ.bindings,
                        .comptime_script = null,
                        .comptime_vals = empty_vals,
                        .transformed = transformed,
                        .type_ids = type_ids,
                        .dispatch_rewrites = dispatch_rewrites,
                        .js_method_renames = js_method_renames,
                        .instance_lowerings = instance_lowerings,
                        .custom_ast = try collectCustomAst(arena_alloc, &succ.env),
                        .comptime_traces = succ.env.comptimeTraces.items,
                        .template_expansions = succ.env.templateExpansions.count(),
                        .warnings = succ.env.warnings.items,
                    } },
                });
            },
        }
    }

    return session;
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
    build_root: ?[]const u8,
    target_name: ?[]const u8,
) !ComptimeSession {
    // Decision 84: this compilation's decorator and template bodies run on the
    // target's VM (`comptime/runtime/runtime.zig` `forTarget`) — chosen here,
    // once, so no driver can compile for a target and evaluate on the other one.
    // A wasm build's lookup carries its host (`wasm.browser`, decision 334);
    // the runtime is the member's.
    const prev_runtime = hostRuntime.select(hostRuntime.forTarget(if (target_name) |t| ast.ExternalLookup.of(t).member else null));
    defer _ = hostRuntime.select(prev_runtime);

    // Decision 353 — a template body's `@TypeInfo.all` answers for the whole
    // program, every module's decorators applied. A session answers it from
    // the catalogue as it stands when the template is expanded; when a module
    // analysed later added an entry to an answer (`staleTemplateRead`), the
    // modules are compiled again with the first session's complete catalogue
    // as the oracle the answers are read from.
    var first = try compileOnce(allocator, modules, io, build_root, target_name, null);
    if (try staleTemplateRead(first.session.arena.allocator(), first.reflection) == null) return first.session;
    var second = compileOnce(allocator, modules, io, build_root, target_name, first.reflection) catch |err| {
        first.session.deinit(allocator);
        return err;
    };
    first.session.deinit(allocator);
    // The oracle answered every read; one the final catalogue still disagrees
    // with means the catalogue depends on what the template answered.
    if (try staleTemplateRead(second.session.arena.allocator(), second.reflection)) |read| {
        try refuseStaleRead(allocator, &second.session, read);
    }
    return second.session;
}

/// The first template-body answer of the session that the session's final
/// catalogue answers differently, or null (decision 353).
fn staleTemplateRead(arena: std.mem.Allocator, reflection: *const reflectionMod.Reflection) !?reflectionMod.TemplateRead {
    for (reflection.templateReads.items) |read| {
        const now = switch (try typeinfoAll.templateAnswerText(arena, reflection, read.query, read.loc)) {
            .ok => |t| t,
            .refused => return read,
        };
        if (!std.mem.eql(u8, now, read.text)) return read;
    }
    return null;
}

/// The module that expanded `read` refused at the expansion: its answer,
/// given from a complete catalogue, changed that catalogue.
fn refuseStaleRead(allocator: std.mem.Allocator, session: *ComptimeSession, read: reflectionMod.TemplateRead) !void {
    const arena = session.arena.allocator();
    const msg = try std.fmt.allocPrint(arena, "{s}: the template expanded here reads `@TypeInfo.all(with: {s})`, and the declarations its answer builds change that catalogue", .{ diagnostics.typeinfo_all_template_unstable, read.query.label });
    const te = validation.TypeError.custom(msg, "A template's answer cannot add or remove a declaration carrying the decorators it reads: the catalogue it answers is the program's, decided before any template runs.").withLoc(read.loc);
    for (session.outputs.items) |*o| {
        const path = if (std.mem.eql(u8, o.name, "main")) "" else o.name;
        if (!std.mem.eql(u8, path, read.module) and !std.mem.eql(u8, o.name, read.module)) continue;
        o.outcome = .{ .typeError = te };
        return;
    }
    _ = allocator;
}

const CompiledOnce = struct {
    session: ComptimeSession,
    reflection: *reflectionMod.Reflection,
};

fn compileOnce(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    build_root: ?[]const u8,
    target_name: ?[]const u8,
    oracle: ?*const reflectionMod.Reflection,
) !CompiledOnce {
    var session = ComptimeSession{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .outputs = .empty,
    };
    errdefer session.arena.deinit();

    const arena_alloc = session.arena.allocator();
    var registry = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena_alloc);
    var type_decl_registry = std.StringHashMap(std.StringHashMap(ast.DeclKind)).init(arena_alloc);
    var template_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var decorator_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var extension_registry = std.StringHashMap(std.StringHashMap(ast.ImplementDecl)).init(arena_alloc);
    // Decision 216 — what decorators record for reflection, for this session.
    const reflection = try arena_alloc.create(reflectionMod.Reflection);
    reflection.* = reflectionMod.Reflection.init(arena_alloc);
    reflection.oracle = oracle;
    var default_dsl = DefaultDsl.init(arena_alloc);

    // `from "std"` imports pull the embedded std modules into the compilation.
    // Non-std libs are ordinary input modules: the driver supplies their `.bp`
    // sources and `resolveImports` binds `from "<lib>"` through the shared
    // registry — the core names no specific lib (std is the one exception).
    var reader_refusals: std.AutoHashMapUnmanaged(usize, validation.TypeError) = .empty;
    const all_modules = try orderReaders(arena_alloc, try expandStdImports(arena_alloc, modules, target_name), reflection, &reader_refusals);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        if (reader_refusals.get(idx)) |te| {
            try session.outputs.append(allocator, .{ .name = name, .src = mod.source, .srcPath = mod.srcPath, .outcome = .{ .typeError = te } });
            continue;
        }
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, .{
            .io = io,
            .build_root = build_root orelse name,
        }, false, target_name, reflection);

        switch (analysis) {
            .parseError => |se| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .parseError = se },
                });
            },
            .validationError => |verr| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .validationError = verr.info },
                });
            },
            .typeError => |te| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .typeError = te },
                });
            },
            .success => |succ| {
                var dispatch_rewrites = std.AutoHashMap(ast.Loc, []const u8).init(arena_alloc);
                {
                    var rit = succ.env.dispatchRewrites.iterator();
                    while (rit.next()) |e| try dispatch_rewrites.put(e.key_ptr.*, e.value_ptr.*);
                }
                var js_method_renames = std.AutoHashMap(ast.Loc, []const u8).init(arena_alloc);
                {
                    var rit = succ.env.jsMethodRenames.iterator();
                    while (rit.next()) |e| try js_method_renames.put(e.key_ptr.*, e.value_ptr.*);
                }
                var instance_lowerings = std.AutoHashMap(ast.Loc, envMod.InstanceLowering).init(arena_alloc);
                {
                    var rit = succ.env.instanceLowerings.iterator();
                    while (rit.next()) |e| try instance_lowerings.put(e.key_ptr.*, e.value_ptr.*);
                    var dit = succ.env.divisions.iterator();
                    while (dit.next()) |e| if (infer.arithKind(e.value_ptr.*)) |k| {
                        // An operator's loc never holds another lowering; were
                        // one there (a `+=` keyed by its target's name), it wins.
                        const slot = try instance_lowerings.getOrPut(e.key_ptr.*);
                        if (!slot.found_existing) slot.value_ptr.* = .{ .division = k };
                    };
                }
                if (idx < all_modules.len - 1) {
                    var env = succ.env;
                    try registerExports(arena_alloc, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, &default_dsl, mod.path, succ.bindings, succ.program.decls, &env);
                    // NOTE: no env.deinit() here — `env` is a copy whose hashmap
                    // internals are shared with `succ.env`, and the transform
                    // below still reads `succ.env.method_lowerings`. The env is
                    // arena-backed; the session arena reclaims it wholesale.
                }
                const ct = try evaluateComptime(arena_alloc, succ.bindings, &succ.env.srcRewrites);

                var fn_decls = std.StringHashMap(ast.FnDecl).init(arena_alloc);
                var comptime_arrays = std.StringHashMap([]const ast.TypedExpr).init(arena_alloc);
                {
                    // Stdlib fn decls (`todo`/`panic`/`trap`/`emit`/`module`/
                    // `getContext`/`field`) come from `registerStdlib`'s parse
                    // of `builtins_fns.d.bp`. Seed them first so user-module
                    // bindings (next loop) win on name collision — a user-
                    // defined `panic` shadows the builtin, same as any other
                    // stdlib symbol.
                    var sit = succ.env.stdlibFnDecls.iterator();
                    while (sit.next()) |e| try fn_decls.put(e.key_ptr.*, e.value_ptr.*);
                }
                for (succ.bindings) |b| {
                    if (b.decl == .@"fn") {
                        try fn_decls.put(b.name, try expr_param.eraseFn(arena_alloc, b.decl.@"fn", infer.isDecoratorParams(b.decl.@"fn".params)));
                    }
                    if (b.typedExpr) |te| {
                        switch (te) {
                            .comptime_ => |ct2| switch (ct2.kind) {
                                .comptimeExpr => |inner| switch (inner.*) {
                                    .collection => |col| switch (col.kind) {
                                        .arrayLit => |al| try comptime_arrays.put(b.name, al.elems),
                                        else => {},
                                    },
                                    else => {},
                                },
                                else => {},
                            },
                            else => {},
                        }
                    }
                }

                // Prepend synthetic imports for stdlib modules implicitly used via
                // array method dispatch (e.g. `xs.isEmpty()` → needs `list` required).
                const program_for_transform = blk: {
                    var synth: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
                    var mit = succ.env.implicitStdModules.keyIterator();
                    while (mit.next()) |mod_name| {
                        if (succ.env.stdImports.contains(mod_name.*)) continue;
                        const segs = try arena_alloc.alloc([]const u8, 1);
                        segs[0] = mod_name.*;
                        const paths = try arena_alloc.alloc(ast.ImportPath, 1);
                        paths[0] = .{ .segments = segs };
                        try synth.append(arena_alloc, .{ .use = .{
                            .imports = paths,
                            .source = .{ .module = "std" },
                        } });
                    }
                    if (synth.items.len == 0) break :blk succ.program;
                    const new_decls = try arena_alloc.alloc(ast.DeclKind, synth.items.len + succ.program.decls.len);
                    @memcpy(new_decls[0..synth.items.len], synth.items);
                    @memcpy(new_decls[synth.items.len..], succ.program.decls);
                    break :blk ast.Program{ .decls = new_decls };
                };
                const transformed = try value_or_type.withTwinImports(arena_alloc, try withImportSourcesNamed(arena_alloc, try withImportTypeAliasesErased(arena_alloc, try alias_erase.erase(arena_alloc, try withYieldStepDecl(arena_alloc, try withDeclaredDecls(arena_alloc, try withSourceLocationDecl(arena_alloc, try withSynthesisedEnumDecls(
                    arena_alloc,
                    try withUsedAssocInterfaces(arena_alloc, try withTemplateHygiene(arena_alloc, try context_lower.lower(arena_alloc, try transform.transform(arena_alloc, try expr_param.eraseProgram(arena_alloc, program_for_transform, infer.isDecoratorParams), fn_decls, comptime_arrays, ct.comptime_vals, &succ.env.method_lowerings, &succ.env.templateExpansions, &succ.env.srcRewrites, &succ.env.result_jump_lowerings, &succ.env.stdArrayLowerings, &succ.env.enumSectionRewrites, &succ.env.indexRewrites, &succ.env.optionalNullCases, succ.env.ctorParams, &succ.env.defaultInjections, &succ.env.resultPatternLocs, &succ.env.namespaces), &succ.env), &succ.env, declaresTemplateFn(program_for_transform.decls)), &succ.env),
                    &succ.env,
                ), &succ.env), &succ.env), &succ.env), &succ.env.typeAliases), &succ.env), &succ.env), &succ.env.typeArgTwins);

                var type_ids = std.StringHashMap(usize).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.typeId) |id| try type_ids.put(b.name, id);
                }

                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .ok = .{
                        .bindings = succ.bindings,
                        .comptime_script = ct.comptime_script,
                        .comptime_vals = ct.comptime_vals,
                        .transformed = transformed,
                        .type_ids = type_ids,
                        .dispatch_rewrites = dispatch_rewrites,
                        .js_method_renames = js_method_renames,
                        .instance_lowerings = instance_lowerings,
                        .custom_ast = try collectCustomAst(arena_alloc, &succ.env),
                        .comptime_traces = succ.env.comptimeTraces.items,
                        .template_expansions = succ.env.templateExpansions.count(),
                        .warnings = succ.env.warnings.items,
                    } },
                });
            },
        }
    }

    return .{ .session = session, .reflection = reflection };
}

test "importsPackage: the `from` keyword and the quoted name, dotted or not" {
    try std.testing.expect(importsPackage("import {match.matchPath} from \"shapes\";", "shapes"));
    try std.testing.expect(importsPackage("import {x} from  \"shapes.match\";", "shapes"));
    try std.testing.expect(!importsPackage("import {x} from \"shapesx\";", "shapes"));
    try std.testing.expect(!importsPackage("import {x} from \"std\";", "shapes"));
    try std.testing.expect(!importsPackage("val datefrom = \"shapes\";", "shapes"));
    // A comment quoting an import loads nothing.
    try std.testing.expect(!importsPackage("//// like `import {x} from \"shapes\"`\nval y = 1;", "shapes"));
    try std.testing.expect(!importsPackage("val y = 1; // from \"shapes\"", "shapes"));
    try std.testing.expect(importsPackage("// a comment\nimport {x} from \"shapes\";", "shapes"));
}

test "stdImportsOf: a std module's brace import names its std sibling (decision 309)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var path_index: ?usize = null;
    for (std_pkg_modules, 0..) |spm, i| {
        if (std.mem.eql(u8, spm.path, "std/path")) path_index = i;
    }
    for ([_][]const u8{
        "import {path.relative};\n",
        "import {path};\n",
        "import {path.relative} from \"std\";\n",
    }) |src| {
        const deps = try stdImportsOf(a, src);
        try std.testing.expectEqual(@as(usize, 1), deps.len);
        try std.testing.expectEqual(path_index.?, deps[0]);
    }
}

test "embedded std module: a brace import of a sibling resolves to std/<path> (decision 309)" {
    // A std module as a consumer's build embeds it (`std/<mod>`), importing
    // its sibling `path` by the brace form — what std's own build resolves to
    // `path`. Before: `relative` reached nothing and the module failed with an
    // unlocated `TypeError`.
    var session = try compileTypesOnly(std.testing.allocator, &.{.{
        .path = "std/self_import",
        .source =
        \\import {path.relative};
        \\
        \\pub fn rel(a: string, b: string) -> string {
        \\    return relative(a, b);
        \\}
        \\
        ,
    }}, null);
    defer session.deinit(std.testing.allocator);
    const items = session.outputs.items;
    try std.testing.expect(items.len >= 2);
    try std.testing.expectEqualStrings("std/path", items[0].name);
    try std.testing.expect(items[items.len - 1].outcome == .ok);
}
