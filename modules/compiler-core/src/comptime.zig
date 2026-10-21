/// Public API for the botopink comptime pipeline.
///
/// This is the only file outside `src/comptime/` that should be imported by
/// other modules. All internal implementation lives under `src/comptime/`.
const std = @import("std");
const ast = @import("./ast.zig");
const infer = @import("./comptime/infer.zig");
const transform = @import("./comptime/transform.zig");
const context_lower = @import("comptime/context_lower.zig");
const resolved_origins = @import("comptime/resolved_origins.zig");
const typeIdentity = @import("comptime/type_identity.zig");
const alias_erase = @import("./comptime/alias_erase.zig");
const std_namespace = @import("./comptime/std_namespace.zig");
const std_calls = @import("./comptime/std_calls.zig");
const parserTypes = @import("./parser/types.zig");
const mod_tree = @import("./comptime/mod_tree.zig");
const levelB = @import("./comptime/level_b.zig");
/// The code cache's level B inside a compile (144 B-60): `compileWith`'s store.
pub const level_b = levelB;
const mod_namespace = @import("./comptime/mod_namespace.zig");
const inline_types = @import("./comptime/inline_types.zig");
const nested_types = @import("./comptime/nested_types.zig");
const component_types = @import("./comptime/component_types.zig");
const default_fn = @import("./comptime/default_fn.zig");
const value_or_type = @import("./comptime/value_or_type.zig");
const type_token = @import("./comptime/type_token.zig");
const token_import = @import("./comptime/token_import.zig");
const syntax_param = @import("./comptime/syntax_param.zig");
const derived_types = @import("./comptime/derived_types.zig");
const typed_meta = @import("./comptime/typed_meta.zig");
const written_names = @import("./comptime/written_names.zig");
const member_fn = @import("./comptime/member_fn.zig");
const expand_call = @import("./comptime/expand_call.zig");
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
const adoptDefaults = @import("./comptime/adopt_defaults.zig");
const typeinfoAll = @import("./comptime/typeinfo_all.zig");
const templateEval = @import("./comptime/template_eval.zig");
const hostCells = @import("./comptime/host_cells.zig");
const decoratorEval = @import("./comptime/decorator_eval.zig");
const blockEval = @import("./comptime/block_eval.zig");
const hooksMod = @import("./comptime/hooks.zig");

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
    /// A refused analysis' record of what the target's checks read
    /// (`envMod.TargetTrace`, `codegen/target_check.zig`); null otherwise.
    target_trace: ?*const envMod.TargetTrace = null,

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
        /// Decision 788 (3) — what this module's build bodies printed
        /// (`Env.buildOutput`): the build's output, which `botopink build`
        /// and `run` write to stdout. Kept in the analysis entry, so a build
        /// served from the code cache prints it as the build that ran it did.
        build_output: []const u8 = "",
        /// Decision 375 — this module's top-level functions whose hooks node
        /// is synchronous (`Env.syncFns`): commonJS emits one answering
        /// `@Component<R>` as a plain `function`, its typedef the value.
        sync_fns: std.StringHashMapUnmanaged(void) = .empty,
        /// Decision 375 — the calls and `use`s of a synchronous component or
        /// hook, by location (`Env.syncCalls`): commonJS emits no `await` there.
        sync_calls: std.AutoHashMapUnmanaged(ast.Loc, void) = .empty,
        /// STD-001 (decision 518 (4)) — this module's calls of std functions
        /// that reach a host declaration, in inference order (`Env.stdHostCalls`):
        /// `codegen/target_check.zig` refuses at emit the first whose host has
        /// no binding for the target (decision 798 (4)).
        std_host_calls: []const envMod.StdCall = &.{},
        /// Decision 798 (1) — the resolved program: the module as written once
        /// comptime has run (folded values spliced, template expansions and
        /// specialised copies in place, the decorators' contributions merged,
        /// the functions expanded at their calls gone), before any backend
        /// lowering. Kept only under `keep_resolved` (`--emit-resolved`,
        /// `comptime/resolved_print.zig`); null otherwise.
        resolved: ?ast.Program = null,
    };
};

/// Decision 798 (2) — set by a driver that prints the resolved program
/// (`--emit-resolved`): each analysed module keeps `OkData.resolved`.
pub var keep_resolved: bool = false;

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
    /// The code cache's level B CODE of this compile (144 B-60 S4): the units
    /// its entries hold and the entries still without them, for the emit
    /// (`codegen.generateWith`). Null without a store. In `arena`.
    level_b_code: ?*levelB.Code = null,
    /// Decision 787 — the modules of the loaded packages a `run()` brought
    /// into the program (`compileWith`): their sources, which the outputs
    /// read, live as long as the session.
    loaded: ?*std.heap.ArenaAllocator = null,
    /// The paths of the modules that read `@TypeInfo.all` (`orderReaders`) or
    /// expand a template whose body queries it (`templateReads`):
    /// their answer is the whole program's. In `arena`.
    readers: []const []const u8 = &.{},

    pub fn deinit(self: *ComptimeSession, allocator: std.mem.Allocator) void {
        self.outputs.deinit(allocator);
        self.arena.deinit();
        if (self.loaded) |l| {
            l.deinit();
            std.heap.page_allocator.destroy(l);
        }
    }
};

/// Prepend the interface declarations whose associated functions were used as
/// call receivers (`Array.range(...)`) but that aren't declared in the program —
/// i.e. stdlib primitives (`Array`, `String`). Codegen then emits their
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
/// Whether the module of `decls` exports its private functions and values
/// for the code other modules read from it, and marks them `pub` for the
/// backends: it declares a template (decision 112), a decorator handing a
/// member on (384), or an annotation's `@Expr` meta field (385).
fn sharesPrivates(arena: std.mem.Allocator, decls: []const ast.DeclKind, env: *const envMod.Env) !bool {
    if (declaresTemplateFn(decls)) return true;
    return written_names.sharesPrivates(arena, decls, env.reflection, env.modulePath);
}

fn withTemplateHygiene(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env, declares_template: bool, source: []const ast.DeclKind) !ast.Program {
    if (env.templateImports.count() == 0 and !declares_template) return prog;
    // Decision 562 — a module declaring a function expanded at its call site
    // shares its types too: the code it writes into a caller names them
    // (`expand_call.importsFor`).
    const shares_types = declares_template and declaresExpandedFn(arena, source);
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
            // A host function's `fn:` body stays private (decision 238): the
            // binding is what other modules reach.
            .@"fn" => |*f| f.isPub = f.isPub or !namesFnBinding(prog, f.name),
            .val => |*v| v.isPub = true,
            .type_ => |*t| t.isPub = t.isPub or shares_types,
            else => {},
        };
        try decls.append(arena, out);
    }
    return ast.Program{ .decls = decls.items };
}

fn declaresExpandedFn(arena: std.mem.Allocator, decls: []const ast.DeclKind) bool {
    for (decls) |d| if (d == .@"fn") if (hooksMod.isExpandedFn(arena, d.@"fn") catch false) return true;
    return false;
}

/// Decision 798 (1) — `OkData.resolved`: the transform with what comptime
/// decided alone — the specialised copies (`fn_decls`, `comptime_arrays`; a
/// call of a local named like a function is none, `localCalleeCalls`), the
/// template expansions, the folded values' splices (`srcRewrites`) and decision
/// 297's twin calls (`indexRewrites`, read for those alone) — and
/// none of the backends' lowerings (method, index, enum section, default
/// fills, namespaces …), so the tree is still the language as written.
fn resolvedProgram(
    arena: std.mem.Allocator,
    program: ast.Program,
    fn_decls: std.StringHashMap(ast.FnDecl),
    comptime_arrays: std.StringHashMap([]const ast.TypedExpr),
    env: *const envMod.Env,
    /// The module's own text: a line past its end is a decorator's output
    /// (`resolved_origins.outputAt`).
    source: []const u8,
) !ast.Program {
    const ml = transform.MethodLowerings.init(arena);
    const rj = transform.ResultJumpLowerings.init(arena);
    const sa = transform.StdArrayLowerings.init(arena);
    const es = transform.EnumSectionRewrites.init(arena);
    const onc = transform.OptionalNullCases.init(arena);
    const di = transform.DefaultInjections.init(arena);
    const rp: std.AutoHashMapUnmanaged(ast.Loc, envMod.PatternNote) = .empty;
    const ns: envMod.NamespaceImports = .{};
    const ec: std.AutoHashMapUnmanaged(ast.Loc, []const ast.CallArg) = .empty;
    // The transform rewrites nodes in place, and the backends' own transform
    // reads the same declarations: this one works on copies.
    const copied = try context_lower.deepCopy(ast.Program, arena, program);
    var decls = std.StringHashMap(ast.FnDecl).init(arena);
    var it = fn_decls.iterator();
    while (it.next()) |e| try decls.put(e.key_ptr.*, try context_lower.deepCopy(ast.FnDecl, arena, e.value_ptr.*));
    const erased = try syntax_param.eraseProgram(arena, try withoutExpandedFns(arena, copied), infer.isDecoratorParams);
    // Decision 835 (3) — a `@TypeInfo.all(…)` read stays the read as written
    // (its answer is no value a program writes), until 576 (7) removes it.
    var splices = try env.srcRewrites.clone();
    var cit = env.typeinfoAll.keyIterator();
    while (cit.next()) |loc| _ = splices.remove(loc.*);
    // Decision 798 (2) — each piece's origin, a comment over it: an expansion
    // and a folded value marked on the tree as written, a decorator's output
    // on the transform's.
    const self_file = resolved_origins.labelOf(env, env.modulePath, if (env.srcPath.len > 0) env.srcPath else try std.fmt.allocPrint(arena, "{s}.bp", .{if (env.modulePath.len > 0) env.modulePath else "main"}));
    const marked = try resolved_origins.annotateWritten(arena, erased, env, &splices, self_file);
    const t0 = try transform.transform(arena, marked, decls, comptime_arrays, &ml, &env.templateExpansions, &splices, &rj, &sa, &es, &env.indexRewrites, &onc, std.StringHashMap([]const ast.Param).init(arena), &di, &rp, &ns, &env.localCalleeCalls, &ec, .resolved);
    const t = try resolved_origins.annotateOutputs(arena, t0, env, source, self_file);
    // What expanded code and folded values name that the module does not
    // declare: the template's imports, the prelude records a value is built
    // from (`SourceLocation`, `Declared`, `Asset`, `__Source`).
    const hygienic = try withTemplateHygiene(arena, t, env, try sharesPrivates(arena, program.decls, env), program.decls);
    return withAssetDecl(arena, try withDeclaredDecls(arena, try withSourceRecordDecl(arena, try withSourceLocationDecl(arena, hygienic, env), env), env), env);
}

/// Decision 562 — `prog` without the functions expanded at their call
/// sites (`hooks.isExpandedFn`): each call was replaced by the code the body
/// emits, so the function has no run-time body. Read before `syntax_param`
/// erases the `.value` reads that mark one.
fn withoutExpandedFns(arena: std.mem.Allocator, prog: ast.Program) !ast.Program {
    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (prog.decls) |d| {
        if (d == .@"fn" and try hooksMod.isExpandedFn(arena, d.@"fn")) continue;
        try decls.append(arena, d);
    }
    if (decls.items.len == prog.decls.len) return prog;
    return .{ .decls = decls.items };
}

/// Whether a host declaration of `prog` binds a target to the fn `name`
/// (`#[@external(.<T>(body: name))]`).
fn namesFnBinding(prog: ast.Program, name: []const u8) bool {
    for (prog.decls) |d| if (d == .@"fn") for (d.@"fn".implementations) |r| {
        if (r.cell) |c| if (c.kind == .body and std.mem.eql(u8, c.value, name)) return true;
    };
    return false;
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

/// Every module's display path in the session's reflection
/// (`Reflection.srcPaths`), before any module is analysed — a cached
/// package's modules included, whose analysis does not run.
fn recordSrcPaths(arena: std.mem.Allocator, reflection: *reflectionMod.Reflection, mods: []const Module) !void {
    for (mods) |m| {
        const shown = try displaySrcPath(arena, m);
        try reflection.srcPaths.put(reflection.arena, m.path, shown);
        // A dependency's module is labelled by its module path, as its own
        // diagnostics are (decision 545), not by its package-relative file.
        const label = if (m.package.len > 0) try std.fmt.allocPrint(arena, "{s}.bp", .{m.path}) else shown;
        try reflection.diagLabels.put(reflection.arena, m.path, label);
        // Decision 551 — the root package's root module.
        if (m.root and m.package.len == 0 and !m.std_member) reflection.rootModule = m.path;
    }
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
/// (`env.itemOwners` — a module of this package beside `from "<pkg>"` or a
/// package beside a module path, decision 206) leaves its import for an import of its own that names
/// the module it resolved to by its key (`ImportSource.key`, `config` or
/// `log/levels` — written `import {charOf} from "config";` when formatted),
/// the item reduced to its leaf and its alias, so the backends' name-keyed
/// lookup reads the checker's answer, exactly that module, instead of
/// meeting the other declaration beside it (a key never reads as a basename:
/// the root package's `config` is not a dependency's `x/config`).
fn withImportSourcesNamed(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.itemOwners.count() == 0 and env.implicitEnumImports.count() == 0 and env.contextDefaultImports.count() == 0 and env.liftedStdTypes.count() == 0) return prog;
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    // Decisions 378, 379 — the `val` another module declares a context
    // type's default with, read by a `use inject(R)` field here under a
    // hidden alias (`Env.contextDefaultImports`).
    var lit = env.liftedStdTypes.iterator();
    while (lit.next()) |e| {
        var segs: std.ArrayListUnmanaged([]const u8) = .empty;
        var parts = std.mem.splitScalar(u8, e.value_ptr.*, '/');
        while (parts.next()) |part| try segs.append(arena, part);
        try segs.append(arena, e.key_ptr.*);
        const imports = try arena.dupe(ast.ImportPath, &.{.{ .segments = segs.items, .loc = .{ .line = 0, .col = 0 } }});
        try out.append(arena, .{ .use = .{ .imports = imports, .source = .{ .module = "std" } } });
    }
    var cit = env.contextDefaultImports.iterator();
    while (cit.next()) |e| {
        const imports = try arena.dupe(ast.ImportPath, &.{.{ .segments = try arena.dupe([]const u8, &.{e.value_ptr.name}), .alias = e.key_ptr.*, .loc = .{ .line = 0, .col = 0 } }});
        try out.append(arena, .{ .use = .{ .imports = imports, .source = .{ .key = e.value_ptr.module } } });
    }
    // 144 B-10 — an enum the module wrote by dot-shorthand only, imported
    // from the module that declares it (`Env.implicitEnumImports`).
    var iit = env.implicitEnumImports.iterator();
    while (iit.next()) |e| {
        const imports = try arena.dupe(ast.ImportPath, &.{.{ .segments = try arena.dupe([]const u8, &.{e.key_ptr.*}), .loc = .{ .line = 0, .col = 0 } }});
        try out.append(arena, .{ .use = .{ .imports = imports, .source = .{ .key = e.value_ptr.* } } });
    }
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

/// A run-time `Source(file, line, col)` (`env.usesSourceRecord`): the prelude
/// record `__Source` as a private declaration of the module, so every backend
/// builds it through its record path. A module declaring its own keeps it.
fn withSourceRecordDecl(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesSourceRecord) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, "__Source")) return prog,
        else => {},
    };
    var lx = Lexer.init(source_record_decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const decl_prog = try p.parse(arena);
    if (decl_prog.decls.len != 1) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, 1 + prog.decls.len);
    new_decls[0] = decl_prog.decls[0];
    @memcpy(new_decls[1..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// The declaration `withSourceRecordDecl` splices; keep it in sync with
/// `__Source` in `primitives.bp`.
pub const source_record_decl_src =
    \\type __Source(file: string, line: i32, col: i32)
;

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
/// Decision 298 — with them the record of one typed meta value an entry
/// carries (`DeclaredTypedMeta`); the function a `d.meta(T)` / `d.metaAll(T)`
/// read calls is the module's own (`typed_meta.withMetaHelper`).
fn withDeclaredDecls(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesDeclared) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, "Declared") or std.mem.eql(u8, t.name, "DeclaredMeta") or std.mem.eql(u8, t.name, "DeclaredTypedMeta")) return prog,
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
pub const declared_decl_src =
    \\type DeclaredMeta(key: string, value: string)
    \\type DeclaredTypedMeta(key: string, value: unknown)
    \\type Declared<T>(name: string, module: string, meta: DeclaredMeta[], returnTypeName: string, value: T, typedMeta: DeclaredTypedMeta[])
;

/// The declaration `withSourceLocationDecl` splices: private (the record is
/// per-module — only its fields matter, never its identity), the same four
/// fields as the `decl_reflection_src` entry. Keep the two in sync.
pub const source_location_decl_src =
    \\type SourceLocation(file: string, line: i32, column: i32, fnName: string)
;

/// Decision 519 — the builtin `Asset` record as a program declaration, when
/// the module wrote `@embed` (`env.usesAsset`): the same splice
/// `withSourceLocationDecl` makes for `SourceLocation`, so every backend builds
/// the constructor `@embed` was rewritten into through its record path. A
/// module declaring its own `Asset` keeps it.
fn withAssetDecl(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (!env.usesAsset) return prog;
    for (prog.decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, "Asset")) return prog,
        else => {},
    };
    var lx = Lexer.init(asset_decl_src);
    const tokens = try lx.scanAll(arena);
    var p = Parser.init(tokens);
    const decl_prog = try p.parse(arena);
    if (decl_prog.decls.len != 1) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, 1 + prog.decls.len);
    new_decls[0] = decl_prog.decls[0];
    @memcpy(new_decls[1..], prog.decls);
    return ast.Program{ .decls = new_decls };
}

/// Decision 519 — each function whose `@embed` reads a `comptime`
/// parameter's value (`env.embedParamFns`) takes one more parameter per such
/// `p`, `__bp_embed_<p>: Asset`, last — its specialisations (`<name>_$<n>`)
/// too: the `Asset` each call passes, read in the caller's package
/// (`Env.embedCallArgs`).
fn withEmbedParams(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.embedParamFns.count() == 0) return prog;
    const decls = try arena.dupe(ast.DeclKind, prog.decls);
    for (decls) |*d| switch (d.*) {
        .@"fn" => |*f| {
            const base = if (std.mem.indexOf(u8, f.name, "_$")) |at| f.name[0..at] else f.name;
            const names = env.embedParamFns.get(base) orelse continue;
            const params = try arena.alloc(ast.Param, f.params.len + names.len);
            @memcpy(params[0..f.params.len], f.params);
            for (names, params[f.params.len..]) |n, *p| p.* = .{
                .name = try embedMod.hiddenName(arena, n),
                .typeRef = .{ .named = "Asset" },
                .typeName = "Asset",
            };
            f.params = params;
            try embedMod.readHiddenParams(arena, f.body, f.params, names);
        },
        else => {},
    };
    return .{ .decls = decls };
}

/// The declaration `withAssetDecl` splices (`embed.decl_src`). Keep it in
/// sync with the `decl_reflection_src` entry.
pub const asset_decl_src = embedMod.decl_src;
const embedMod = @import("comptime/embed.zig");
const loadMod = @import("comptime/load.zig");
const reservedNames = @import("comptime/reserved_names.zig");

/// The records the compiler splices into the module that uses them
/// (`withSourceLocationDecl`, `withDeclaredDecls`, `withAssetDecl`): each is a
/// program declaration of that module, so its values are records like any
/// other (decision 21's tagged tuple on beam and erlang), never maps — in a
/// module that does not declare it as much as in one that does.
pub const spliced_record_names = [_][]const u8{ "SourceLocation", "Declared", "DeclaredMeta", "DeclaredTypedMeta", "Asset" };

pub fn isSplicedRecord(name: []const u8) bool {
    for (spliced_record_names) |n| if (std.mem.eql(u8, n, name)) return true;
    return false;
}

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

test "yield step prelude matches primitives.bp" {
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
/// enum `TypeDecl` so codegen sees `Color(_inner: Bp__Enum__Color)` alongside the
/// user-written variants. The parent's `sections()` carry the section
/// names; the wrapper payload's type-ref points at the mangled inner enum
/// name (matching `registerEnumSection`'s `Bp__<Enum>__<Path>` convention,
/// decision 836).
/// Returns a new enum TypeDecl with its variants set to (original variants ++
/// synthesised wrappers).
fn enrichEnumWithSectionWrappers(arena: std.mem.Allocator, e: ast.TypeDecl) !ast.TypeDecl {
    const wrappers = try arena.alloc(ast.EnumVariant, e.sections().len);
    for (e.sections(), 0..) |sec, i| {
        const mangled = try std.fmt.allocPrint(arena, ast.section_type_prefix ++ "{s}__{s}", .{ e.name, sec.name });
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
        /// Under `keep_resolved`: a copy of `program` taken before inference,
        /// which rewrites some of its nodes in place for the backends (a
        /// pipeline's call, a default's fill) — the resolved program's base.
        written: ?ast.Program = null,
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
    reflection: *reflectionMod.Reflection,
) !AnalysisResult {
    // The language server's session runs no comptime and marks no root: a
    // call leaving a catalogue default out type-checks as written there.
    if (types_only) return analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, false, reflection, null, &.{});
    return fillCatalogueDefaults(arena, mod, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, reflection);
}

/// Decision 551 — whether the root module is worth a probe: a function with a
/// catalogue default is declared in the program — one a module analysed
/// before exports (`defaultParamsKey`'s carried parameters), or the root's
/// own. Whether a call names it is the analysis's to say (an alias, a
/// namespace, a default function all reach it).
fn declaresCatalogueDefault(mod: Module, templateRegistry: *const std.StringHashMap(ast.FnDecl)) !bool {
    var it = templateRegistry.valueIterator();
    while (it.next()) |f| for (f.params) |p| if (typeinfoAll.isCatalogueDefault(p)) return true;
    // A probe: its tokens and tree are scratch (144 B-127).
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    var lx = Lexer.init(mod.source);
    const tokens = lx.scanAll(scratch) catch return false;
    var p = Parser.init(tokens);
    const program = p.parse(scratch) catch return false;
    return (try typeinfoAll.collectDefaults(scratch, program)).len > 0;
}

/// Decision 551 — call loc → the arguments appended to that call: a query
/// `@TypeInfo.all(<typeinfo_all.default_key_label>: "<key>")` per catalogue
/// default it leaves out.
const CatalogueInserts = std.AutoHashMapUnmanaged(ast.Loc, []const ast.CallArg);

/// One call of a module that leaves a catalogue default out: where, the
/// parameter's index among the callee's, and the key of the default's query.
const CatalogueDefaultCall = struct {
    loc: ast.Loc,
    param: usize,
    name: []const u8,
    key: ?[]const u8,
};

/// Every call the analysis accepted with a catalogue default left out
/// (`Env.defaultInjections`: the fill's slot of a `@TypeInfo.all` default is
/// empty), by location.
fn catalogueDefaultCalls(arena: std.mem.Allocator, env: *const envMod.Env) ![]const CatalogueDefaultCall {
    var out: std.ArrayListUnmanaged(CatalogueDefaultCall) = .empty;
    var it = env.defaultInjections.iterator();
    while (it.next()) |e| for (e.value_ptr.slots, 0..) |slot, pi| {
        if (slot != null or pi >= e.value_ptr.params.len) continue;
        const p = e.value_ptr.params[pi];
        if (!typeinfoAll.isCatalogueDefault(p)) continue;
        try out.append(arena, .{ .loc = e.key_ptr.*, .param = pi, .name = p.name, .key = typeinfoAll.defaultKeyOf(p.default.?.call.kind.call.args) });
    };
    std.mem.sort(CatalogueDefaultCall, out.items, {}, struct {
        fn lessThan(_: void, a: CatalogueDefaultCall, b: CatalogueDefaultCall) bool {
            if (a.loc.line != b.loc.line) return a.loc.line < b.loc.line;
            if (a.loc.col != b.loc.col) return a.loc.col < b.loc.col;
            return a.param < b.param;
        }
    }.lessThan);
    return out.items;
}

/// Decision 551 — a call that leaves out a `comptime` parameter whose default
/// is a `@TypeInfo.all(…)` query is answered for the program it is compiled
/// in. The module is analysed again with each such call given the query in
/// place of the default (`withInsertedArgs`) — the key of the query as the
/// declaring module resolved it (`infer.noteDefaultQueries`), so the names
/// `with:` writes resolve there — and the module reads `@TypeInfo.all` like
/// an entry point: its first analysis runs its decorators, the answer
/// (`typeinfo_all.plan`) lists every module's declarations but another
/// reader's, each `value` the declaration itself reached through an import
/// the answer adds, and the re-analysis types it. The call is legal only in
/// the root package's root module (`Reflection.rootModule`): refused anywhere
/// else, at the call. Each answer is recorded as 353's template answers are
/// (`Reflection.templateReads`, with the calling module as its reader): a
/// module analysed later that changes the catalogue makes the session compile
/// again, the calling module then analysed after every module but the readers
/// (`Reflection.defaultCallers`, `orderReaders`).
fn fillCatalogueDefaults(
    arena: std.mem.Allocator,
    mod: Module,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
    templateEvalCtx: ?envMod.TemplateEvalCtx,
    reflection: *reflectionMod.Reflection,
) !AnalysisResult {
    const at_root = if (reflection.rootModule) |r| std.mem.eql(u8, r, mod.path) else false;
    // The root is first analysed over a copy of the reflection (its decorators
    // record nothing that stays) when the program declares a catalogue
    // default: the module is then analysed again, its calls given their
    // queries. Any other module is analysed once, and a call leaving a
    // default out refused.
    const probe = at_root and try declaresCatalogueDefault(mod, templateRegistry);
    const scratch: *reflectionMod.Reflection = if (probe) blk: {
        const copy = try arena.create(reflectionMod.Reflection);
        copy.* = try reflection.probeCopy(arena);
        break :blk copy;
    } else reflection;
    const first = try analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, false, false, scratch, null, &.{});
    if (first != .success) {
        if (!probe) return first;
        return analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, false, false, reflection, null, &.{});
    }
    var res = first;
    const calls = try catalogueDefaultCalls(arena, &res.success.env);
    if (calls.len == 0) {
        if (!probe) return first;
        res.success.env.deinit();
        return analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, false, false, reflection, null, &.{});
    }
    const program = res.success.program;
    if (!at_root) {
        const c = calls[0];
        const name = if (typeinfoAll.callAt(program, c.loc)) |site| site.callee else "the function";
        const root_label = if (reflection.rootModule) |r| try std.fmt.allocPrint(arena, " ({s})", .{reflection.srcPaths.get(r) orelse r}) else "";
        const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` leaves out `{s}`, whose default `@TypeInfo.all` answers for the whole program — a call that leaves it out is written only in the package's root{s}", .{ diagnostics.typeinfo_all_default_outside_root, name, c.name, root_label });
        const hint = try std.fmt.allocPrint(arena, "Call `{s}` from the package's root, or pass the catalogue: `{s}({s}: @TypeInfo.all(with: …))` (decision 551).", .{ name, name, c.name });
        res.success.env.deinit();
        return .{ .typeError = validation.TypeError.custom(msg, hint).withLoc(c.loc) };
    }
    var inserts: CatalogueInserts = .empty;
    var names: std.AutoHashMapUnmanaged(ast.Loc, []const u8) = .empty;
    var i: usize = 0;
    while (i < calls.len) {
        const loc = calls[i].loc;
        var j = i;
        while (j < calls.len and calls[j].loc.eql(loc)) j += 1;
        defer i = j;
        // A call the analysis filled but no `f(…)` writes (a pipeline) keeps
        // its default unfilled; the re-analysis refuses it.
        const site = typeinfoAll.callAt(program, loc) orelse continue;
        try names.put(arena, loc, site.callee);
        var labelled = site.has_trailing;
        for (site.args) |a| if (a.label != null) {
            labelled = true;
        };
        var written = site.args.len;
        var extra: std.ArrayListUnmanaged(ast.CallArg) = .empty;
        for (calls[i..j]) |c| {
            const key = c.key orelse try reflectionMod.Reflection.defaultKey(arena, mod.path, site.callee, c.name);
            const at: ast.Loc = .{ .line = loc.line, .col = loc.col + ast.catalogue_default_col + c.param, .expansion = loc.expansion };
            const query = try typeinfoAll.defaultQueryCall(arena, key, at);
            // Positional when every earlier parameter is written in order;
            // by the parameter's name otherwise.
            if (!labelled and c.param == written) {
                try extra.append(arena, .{ .label = null, .value = query });
                written += 1;
            } else {
                try extra.append(arena, .{ .label = c.name, .value = query });
                labelled = true;
            }
        }
        try inserts.put(arena, loc, extra.items);
    }
    res.success.env.deinit();
    var again = try analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, false, false, reflection, &inserts, &.{});
    if (again != .success) return again;
    const left = try catalogueDefaultCalls(arena, &again.success.env);
    if (left.len > 0) {
        const msg = try std.fmt.allocPrint(arena, "{s}: this call leaves out `{s}`, whose default `@TypeInfo.all` is answered only at a call written `f(…)`", .{ diagnostics.typeinfo_all_default_outside_root, left[0].name });
        again.success.env.deinit();
        return .{ .typeError = validation.TypeError.custom(msg, "Write the call as `f(…)`, or pass the catalogue (decision 551).").withLoc(left[0].loc) };
    }
    // Each answer, for 353's staleness check.
    for (calls) |c| {
        const callee_name = names.get(c.loc) orelse continue;
        const key = c.key orelse try reflectionMod.Reflection.defaultKey(arena, mod.path, callee_name, c.name);
        const found = reflection.templateQueries.get(key) orelse continue;
        if (found.len != 1) continue;
        const text = switch (try typeinfoAll.templateAnswerText(arena, reflection, found[0], c.loc, mod.path)) {
            .ok => |t| t,
            .refused => continue,
        };
        try reflection.templateReads.append(reflection.arena, .{ .module = mod.path, .loc = c.loc, .query = found[0], .text = text, .reader = mod.path, .callee = callee_name });
    }
    try reflection.defaultCallers.put(reflection.arena, mod.path, {});
    return again;
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
///
/// Decision 580 — an executor's declarations (its function and the
/// `val __bp_init_<k>` that runs it) are a statement of the module's body at
/// the annotated declaration's position: placed right after that declaration
/// (`anchors`, indices of the pass-1 module, moved past the `prepended`
/// imports), after the executors placed there before, so the module's body
/// runs its `val`s and its executors in source order.
fn parseAndMergeContributions(
    arena: std.mem.Allocator,
    source: []const u8,
    original: ast.Program,
    contributions: []const []const u8,
    anchors: []const envMod.ExecutorAnchor,
    prepended: usize,
) !?ast.Program {
    var merged: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    try merged.appendSlice(arena, original.decls);
    // How many declarations were placed after each original declaration.
    const placed = try arena.alloc(usize, original.decls.len);
    @memset(placed, 0);
    var line_shift: usize = std.mem.count(u8, source, "\n") + 1;
    var offset_shift: usize = source.len + 1;
    for (contributions, 0..) |contrib, ci| {
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
        const anchor: ?usize = for (anchors) |an| {
            if (an.contribution == ci) break an.decl + prepended;
        } else null;
        if (anchor) |at| if (at < original.decls.len) {
            var before: usize = 0;
            for (placed[0 .. at + 1]) |n| before += n;
            try merged.insertSlice(arena, at + 1 + before, c_program.decls);
            placed[at] += c_program.decls.len;
            continue;
        };
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
        // A member a behavior is given has a body: its default (decision
        // 370 (2)'s rendered `pub fn …` read as `default fn …`).
        const source = if (is_behavior and std.mem.startsWith(u8, m.source, "pub fn ")) try std.mem.concat(arena, u8, &.{ "default fn ", m.source["pub fn ".len..] }) else m.source;
        const text = try std.fmt.allocPrint(arena, "{s}{s}\n}}", .{ prefix, source });

        const refuse = struct {
            fn at(a: std.mem.Allocator, mc: envMod.MemberContribution, comptime fmt: []const u8, args: anytype, hint: []const u8) !MemberMerge {
                var e = validation.TypeError.custom(try std.fmt.allocPrint(a, fmt, args), hint);
                if (mc.loc) |l| e = e.withLoc(l);
                return .{ .refused = e };
            }
        }.at;
        const not_one = "`decl.addMember(source)` takes one member: a single `fn` (an associated fn, or a method whose first parameter is `self: Self`) written as it would be in the type's body.";

        const parsed_method: ast.BehaviorMethod = parsed: {
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
        // Decision 669 — what the member reads resolves in the module that
        // wrote it (`MemberContribution.renames`).
        var method = try member_fn.renameMethod(arena, parsed_method, m.renames);
        try std_calls.rewriteWith(arena, m.stdCalls, ast.BehaviorMethod, &method);
        // Decision 887 (1) — a member a decorator adds reaches every importer.
        method.isPub = true;
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

/// Decision 567 — a type error inside a member or an associated type a
/// decorator wrote sits past the module's last line (their source is placed
/// after the module's lines, `mergeMembers`, `mergeAssocTypes`). It is located
/// at the annotation that ran the decorator, as `decorator-member-duplicate`
/// is, with the decorator's `decl.addMember` / `decl.addType` call as the
/// `called from` line. One annotation, one error: the first failure is the
/// only one the analysis reports.
fn locateInOutputs(arena: std.mem.Allocator, te: validation.TypeError, source: []const u8, env: *const Env) validation.TypeError {
    const at = (te.loc orelse return te).line;
    const o = resolved_origins.outputAt(env, source, at) orelse return te;
    return locatedAt(arena, te, o.loc, o.call);
}

/// `locateInOutputs` for a refusal of the target recorded by inference
/// (`envMod.TargetSite`), which `codegen/target_check.zig` raises at emit.
fn locateSite(arena: std.mem.Allocator, site: envMod.TargetSite, source: []const u8, env: *const Env) envMod.TargetSite {
    const te = locateInOutputs(arena, .{ .kind = .{ .unboundVariable = "" }, .loc = site.loc, .origin = site.origin, .frames = site.frames }, source, env);
    return .{ .loc = te.loc orelse site.loc, .origin = te.origin, .frames = te.frames };
}

fn locatedAt(arena: std.mem.Allocator, te: validation.TypeError, loc: ?ast.Loc, call: ?envMod.CallSite) validation.TypeError {
    var out = te;
    out.loc = loc orelse return te;
    out.origin = null;
    out.frames = &.{};
    if (call) |c| if (arena.alloc(validation.Frame, 1)) |one| {
        one[0] = .{ .file = c.file, .loc = c.loc };
        out.frames = one;
    } else |_| {};
    return out;
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
    lb: ?*levelB.Session,
) ![]const Module {
    // Every module's tokens and tree here are a probe's — what is kept is the
    // order, the readers' paths and the refusals, all in `arena` — so they are
    // scratch, gone when the order is made (144 B-127).
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    var readers: std.ArrayListUnmanaged(Module) = .empty;
    var others: std.ArrayListUnmanaged(Module) = .empty;
    var reader_programs: std.ArrayListUnmanaged(?ast.Program) = .empty;
    var other_programs: std.ArrayListUnmanaged(?ast.Program) = .empty;
    var reader_tokens: std.ArrayListUnmanaged([]const Token) = .empty;
    var other_tokens: std.ArrayListUnmanaged([]const Token) = .empty;
    // Indexes into `readers` of the dependencies' readers (decision 551).
    var dependency_readers: std.ArrayListUnmanaged(usize) = .empty;
    for (modules) |m| {
        // A module read back from the code cache's level B is no reader (a
        // reader's package is never stored) and imports none: not parsed.
        if (lb) |l| if (l.hitMeta(m) != null) {
            try others.append(arena, m);
            try other_programs.append(scratch, null);
            try other_tokens.append(scratch, &.{});
            continue;
        };
        // A module that does not parse is no reader; its own analysis
        // reports the parse error.
        var lx = Lexer.init(m.source);
        const tokens: []const Token = lx.scanAll(scratch) catch &.{};
        const program: ?ast.Program = if (tokens.len > 0) parsed: {
            var p = Parser.init(tokens);
            const parsed = p.parse(scratch) catch break :parsed null;
            break :parsed try ast.ImportDecl.withOwnPackage(scratch, parsed, m.package);
        } else null;
        if (program != null and try typeinfoAll.reads(scratch, program.?)) {
            try readers.append(arena, m);
            try reader_programs.append(scratch, program);
            try reader_tokens.append(scratch, tokens);
            try reflection.readers.put(arena, m.path, {});
            // Decision 551 — a dependency's reader answers for that
            // dependency alone, so it is analysed after the other modules of
            // its own package and before the packages that import it.
            if (m.package.len > 0) {
                try dependency_readers.append(scratch, readers.items.len - 1);
                continue;
            }
        } else {
            try others.append(arena, m);
            try other_programs.append(scratch, program);
            try other_tokens.append(scratch, tokens);
        }
    }
    // Each dependency reader joins `others` right after the last module of its
    // package (before the first module of the root package when it has none).
    for (dependency_readers.items) |ri| {
        const r = readers.items[ri];
        var at: usize = others.items.len;
        var last: ?usize = null;
        for (others.items, 0..) |o, k| {
            if (std.mem.eql(u8, o.package, r.package)) last = k;
            if (at == others.items.len and o.package.len == 0) at = k;
        }
        if (last) |k| at = k + 1;
        try others.insert(arena, at, r);
        try other_programs.insert(scratch, at, reader_programs.items[ri]);
        try other_tokens.insert(scratch, at, reader_tokens.items[ri]);
    }
    // Decision 551 — a module whose call had a catalogue default answered in
    // the first session is analysed after every other module but the
    // readers, so the answer it is given holds them all.
    var late: std.ArrayListUnmanaged(Module) = .empty;
    if (reflection.oracle) |o| if (o.defaultCallers.count() > 0) {
        var k: usize = 0;
        while (k < others.items.len) {
            if (!o.defaultCallers.contains(others.items[k].path)) {
                k += 1;
                continue;
            }
            try late.append(arena, others.items[k]);
            _ = others.orderedRemove(k);
            const lp = other_programs.orderedRemove(k);
            const lt = other_tokens.orderedRemove(k);
            try other_programs.append(scratch, lp);
            try other_tokens.append(scratch, lt);
        }
        // `others` and its programs stay index-aligned: the late modules
        // join the end of both, in their order.
        try others.appendSlice(arena, late.items);
    };
    if (readers.items.len == 0 and late.items.len == 0) return modules;
    for (readers.items, reader_programs.items, reader_tokens.items, 0..) |r, rp, rt, ri| {
        if (std.mem.indexOfScalar(usize, dependency_readers.items, ri) != null) continue;
        try others.append(arena, r);
        try other_programs.append(scratch, rp);
        try other_tokens.append(scratch, rt);
    }
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
                    // Decision 551 — a module analysed late for its catalogue
                    // default is imported by none (s23-i (d) (2)).
                    for (late.items) |r| {
                        if (std.mem.eql(u8, r.path, m.path)) continue;
                        const hit = for ([_]bool{ false, true }) |whole| switch (try u.leafSource(imp, scratch, whole)) {
                            .key => |key| if (std.mem.eql(u8, key, r.path)) break true,
                            .module => |path| if (std.mem.eql(u8, path, r.path) or std.mem.eql(u8, std.fs.path.basename(r.path), path)) break true,
                            .root => {},
                        } else false;
                        if (!hit) continue;
                        const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` is the package's root and answers a catalogue default for the whole program, so no module imports it", .{ diagnostics.typeinfo_all_imported, r.path });
                        try refusals.put(arena, idx, validation.TypeError.custom(msg, "Move what this module needs out of the root into a module of its own; the root imports it, never the other way round (decision 551).").withLoc(imp.loc));
                        break :scan;
                    }
                    for ([_]bool{ false, true }) |whole| switch (try u.leafSource(imp, scratch, whole)) {
                        // A `.key` is one module: the package plus the path.
                        .key => |key| for (readers.items) |r| {
                            if (std.mem.eql(u8, r.path, m.path) or !std.mem.eql(u8, key, r.path)) continue;
                            if (answersForItsPackage(r, m)) continue;
                            const msg = try std.fmt.allocPrint(arena, "{s}: `{s}` reads `@TypeInfo.all`, so it answers for the whole program and no module imports it", .{ diagnostics.typeinfo_all_imported, r.path });
                            try refusals.put(arena, idx, validation.TypeError.custom(msg, "Move what this module needs out of the entry point into a module of its own; the entry point imports it, never the other way round.").withLoc(imp.loc));
                            break :scan;
                        },
                        .module => |path| for (readers.items) |r| {
                            if (std.mem.eql(u8, r.path, m.path) or answersForItsPackage(r, m)) continue;
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

/// Decision 551 — a dependency's reader answers for that dependency alone, so
/// a module of another package imports it freely (`orderReaders` analyses it
/// after its own package's modules, before the packages that import it).
fn answersForItsPackage(reader: Module, importer: Module) bool {
    return reader.package.len > 0 and !std.mem.eql(u8, reader.package, importer.package);
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
            tok.line += line_shift;
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
                const leaf_src = try itemSource(u, imp, arena);
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

/// Decision 307 — the declaration an import item names, for a derived type's
/// source in another module (`derived_types.ImportLookup`): the module found
/// the way `assocOwners` finds an imported owner (the module the source names
/// first, then the wider passes). An item with no `from` answers its module's
/// key — the package plus the path (`ImportSource.key`, decisions 170, 337) —
/// and every pass admits that one module alone, so a source named in two
/// packages' same-named modules is the importing package's, never the other.
fn derivedTypeSource(ctx: *const anyopaque, arena: std.mem.Allocator, decl: ast.ImportDecl, imp: ast.ImportPath) error{OutOfMemory}!?ast.DeclKind {
    const typeDeclRegistry: *const std.StringHashMap(std.StringHashMap(ast.DeclKind)) = @ptrCast(@alignCast(ctx));
    const from_std = switch (decl.source) {
        .module => |m| std.mem.eql(u8, m, "std"),
        .root, .key => false,
    };
    const leaf = imp.leaf();
    const leaf_src = try itemSource(decl, imp, arena);
    for ([3]u2{ 0, 1, 2 }) |pass| {
        var it = typeDeclRegistry.iterator();
        while (it.next()) |e| {
            if (isStdPkgPath(e.key_ptr.*) != from_std) continue;
            if (!leaf_src.admits(e.key_ptr.*, pass)) continue;
            if (e.value_ptr.get(leaf)) |dk| return dk;
        }
    }
    return null;
}

/// `assoc` and the names of the types declared in `t`'s body (decision 330 (7)).
fn withNested(arena: std.mem.Allocator, assoc: []const []const u8, t: ast.TypeDecl) ![]const []const u8 {
    if (t.assocTypes.len == 0) return assoc;
    return std.mem.concat(arena, []const u8, &.{ assoc, try nested_types.namesOf(arena, t) });
}

/// The pass-2 env replaces pass 1's, where the decorators ran: carry their
/// runtime traces over, ahead of any pass-2 (template) evaluations.
fn keepPassOneTraces(pass_two: *Env, pass_one: *const Env) !void {
    pass_two.passOneOutputs = pass_one.outputRecords();
    try pass_two.comptimeTraces.insertSlice(pass_two.arena, 0, pass_one.comptimeTraces.items);
    // A `comptime` node of the source is inferred again by the re-analysis
    // (a decorator's output spliced, decisions 788 (2), 793 (5)): what it
    // prints once is the build's line, so each run pass 1 wrote is dropped
    // from pass 2's output once (the multiset of texts), a node only the
    // re-analysis meets (one a decorator wrote) keeping its own.
    var carried: std.ArrayListUnmanaged(bool) = .empty;
    defer carried.deinit(pass_two.arena);
    try carried.appendNTimes(pass_two.arena, false, pass_one.buildRuns.items.len);
    var i = pass_two.buildRuns.items.len;
    while (i > 0) {
        i -= 1;
        const run = pass_two.buildRuns.items[i];
        const text = pass_two.buildOutput.items[run.start .. run.start + run.len];
        for (pass_one.buildRuns.items, 0..) |r1, k| {
            if (carried.items[k]) continue;
            if (!std.mem.eql(u8, pass_one.buildOutput.items[r1.start .. r1.start + r1.len], text)) continue;
            carried.items[k] = true;
            try pass_two.buildOutput.replaceRange(pass_two.arena, run.start, run.len, &.{});
            break;
        }
    }
    try pass_two.buildOutput.insertSlice(pass_two.arena, 0, pass_one.buildOutput.items);
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
    reflection: *reflectionMod.Reflection,
    typeinfo_plan: ?typeinfoAll.Plan,
    hygiene: []const envMod.HygieneImport,
) anyerror!AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);
    env.modulePath = mod.path;
    env.inStd = mod.std_member;
    env.compilerBodies = declaresCompilerBodies(mod);
    env.package = mod.package;
    env.reflection = reflection;
    if (typeinfo_plan) |pl| {
        env.typeinfoAll = pl.rewrites;
        env.typeinfoAllBehaviors = pl.behaviors;
    }
    env.srcPath = try displaySrcPath(arena, mod);
    env.packageFiles = mod.files;
    // The prelude registration may have named `SourceLocation`; only the
    // program's own references count (`withSourceLocationDecl`).
    env.usesSourceLocation = false;
    env.usesSourceRecord = false;
    env.usesAsset = false;
    env.usesYieldStep = false;
    env.templateEval = templateEvalCtx;
    if (templateEvalCtx) |c| env.targetTrace = c.target_trace;
    env.skipDecoratorInvoke = true;
    env.typeDeclRegistry = typeDeclRegistry;
    env.exportsRegistry = registry;

    // Decision 216 (3): this module's own associated types exist now. The
    // contributions an `@emit` spliced in are imports of this package too.
    const merged = try ast.ImportDecl.withOwnPackage(arena, merged_in, mod.package);
    var owners = try assocOwners(arena, merged, mod.path, typeDeclRegistry, reflection);
    const unadopted = try assocTypes.expand(arena, merged, &owners);

    if (validation.validateComptime(unadopted)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    resolveImports(&env, unadopted, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    try written_names.bindRecorded(&env, hygiene);
    const with_expansions = withExpansionImports(arena, &env, unadopted, mod.package, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    const program = try adoptDefaults.expand(arena, with_expansions, try behaviorsReached(arena, &env.importedBehaviorDecls, typeDeclRegistry), env.importedImplements.items);
    const written: ?ast.Program = if (keep_resolved) try context_lower.deepCopy(ast.Program, arena, program) else null;
    const bindings = infer.inferProgramTyped(&env, program) catch |err| switch (err) {
        error.TypeError => {
            const te = inline_types.locatedAtCall(env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } });
            if (env.targetTrace) |t| t.build_output = env.buildOutput.items;
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };

    return .{ .success = .{ .bindings = bindings, .env = env, .program = program, .written = written } };
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
/// stdlib (`primitives.bp` + `@Decl` cluster + `CustomNode` + std's
/// modules) on every call.
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

/// Whether std's template is built (decision 780 (5)): a nested compile —
/// `compiler.load`'s (`comptime/load.zig`) — starts only then, never while
/// the one-time initialisation runs.
pub fn stdlibTemplateReady() bool {
    return stdlib_template_init.load(.acquire) == 2;
}

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

/// The imported behaviors (`Env.importedBehaviorDecls`) and, transitively,
/// what each `extends` in its own module — a parent the importer never names
/// (`Shape extends Named`, only `Shape` imported) — for `adopt_defaults.zig`.
fn behaviorsReached(
    arena: std.mem.Allocator,
    imported: *const std.StringHashMapUnmanaged(ast.BehaviorDecl),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
) !*const std.StringHashMapUnmanaged(ast.BehaviorDecl) {
    const out = try arena.create(std.StringHashMapUnmanaged(ast.BehaviorDecl));
    out.* = .empty;
    var pending: std.ArrayListUnmanaged(ast.BehaviorDecl) = .empty;
    var it = imported.iterator();
    while (it.next()) |e| {
        try out.put(arena, e.key_ptr.*, e.value_ptr.*);
        try pending.append(arena, e.value_ptr.*);
    }
    while (pending.pop()) |b| {
        if (b.extends.len == 0) continue;
        // The module that declares `b`: its registry holds this declaration.
        var mit = typeDeclRegistry.iterator();
        const decls = while (mit.next()) |m| {
            if (m.value_ptr.get(b.name)) |d| if (d == .behavior and d.behavior.methods.ptr == b.methods.ptr) break m.value_ptr;
        } else continue;
        for (b.extends) |parent| {
            if (out.contains(parent)) continue;
            const d = decls.get(parent) orelse continue;
            if (d != .behavior) continue;
            try out.put(arena, parent, d.behavior);
            try pending.append(arena, d.behavior);
        }
    }
    return out;
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
    reflection: *reflectionMod.Reflection,
    inserts: ?*const CatalogueInserts,
    carried: []const envMod.ImplementContribution,
) anyerror!AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);
    env.reflection = reflection;
    // Decision 575 (6) — the re-analysis on spliced text skips the decorators,
    // so a library's `compiler.implement` of the first pass comes with it.
    try env.implementContributions.appendSlice(arena, carried);
    // Capture provenance for `expr` templates: which file is being inferred.
    env.modulePath = mod.path;
    env.inStd = mod.std_member;
    env.compilerBodies = declaresCompilerBodies(mod);
    env.package = mod.package;
    // `@src().file` (decision 73): the package-relative display path.
    env.srcPath = try displaySrcPath(arena, mod);
    env.packageFiles = mod.files;
    // The prelude registration may have named `SourceLocation`; only the
    // program's own references count (`withSourceLocationDecl`).
    env.usesSourceLocation = false;
    env.usesSourceRecord = false;
    env.usesAsset = false;
    env.usesYieldStep = false;
    // Runtime-backed template expansion (F6-full) — null in tooling paths.
    env.templateEval = templateEvalCtx;
    if (templateEvalCtx) |c| env.targetTrace = c.target_trace;
    env.skipDecoratorInvoke = skip_invoke;
    env.typeDeclRegistry = typeDeclRegistry;
    env.exportsRegistry = registry;

    // The tokens are scratch: the tree holds no token, only slices of
    // `source`, so they are gone once the parse ends instead of staying the
    // session's (144 B-127).
    var token_scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer token_scratch.deinit();
    var lexer = Lexer.init(source);
    const tokens = lexer.scanAll(token_scratch.allocator()) catch |err| switch (err) {
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
    parser.refuse_removed_builtins = true;
    parser.refuse_type_properties = !isPreludeModule(mod);
    const parsed_source = parser.parse(arena) catch |err| switch (err) {
        // The caller renders the diagnostic (`ComptimeOutput.parseError`); a
        // library call must not write to stderr — a test runner reads it.
        error.UnexpectedToken => return .{ .parseError = .{ .parse = parser.parseError } },
        else => return err,
    };
    // Decision 805 (6) — a name the compiler keeps for itself, refused as
    // written (the first pass; the re-analysis reads the same text spliced).
    if (!skip_invoke and !mod.std_member and !loadMod.isLoadedPackage(mod.package)) if (try reservedNames.check(arena, source, parsed_source)) |te| {
        env.deinit();
        return .{ .typeError = te };
    };
    // Decision 551 — the queries a call leaving a catalogue default out is
    // given (`fillCatalogueDefaults`): this module then reads `@TypeInfo.all`.
    const inserted = if (inserts) |ins| try typeinfoAll.withInsertedArgs(arena, parsed_source, ins) else parsed_source;
    // Decisions 780, 782 — a module that loads a file declares the function
    // its reads are rewritten to call (`comptime/load.zig`).
    // Decisions 787, 792 — and the imports its `run()` calls are rewritten
    // to name (`loadMod.withRunImports`).
    const parsed_as_written = try loadMod.withRunImports(arena, try loadMod.withLoadHelper(arena, inserted));
    // Decision 309 — an embedded std module's brace imports name `std/<path>`.
    // A dependency's module marks its imports with its package, so a path
    // item names that package's module (decisions 170, 337).
    // Decision 582 (3): `import pkg;` is `import {pkg} from "pkg"`.
    const marked = if (isStdPkgPath(mod.path)) try embeddedStdProgram(arena, parsed_as_written) else try ast.ImportDecl.withOwnPackage(arena, try default_fn.packageNamespaces(arena, parsed_as_written), mod.package);
    // Decision 337: `mod m;` binds the namespace `m`, and a module namespace
    // of the package is walked as std's is (`mod_namespace.zig`).
    const parsed = if (reflection.modTree) |tree| switch (try mod_namespace.expand(arena, marked, tree, mod.path, mod.package)) {
        .ok => |p| p,
        .refused => |te| {
            env.deinit();
            return .{ .typeError = te };
        },
    } else marked;
    // Decisions 110 / 111 on the use side: `io.fs.f()` through a folder
    // namespace and `collections.Dict.empty()` through a module one reach the
    // checker and the backends as the one-dot forms they lower.
    // Decision 207: an inline parameter type becomes a record of the module.
    // Decision 289: an anonymous default is named `default`. Decision 582: a
    // module namespace written as a value is that module's default.
    const defaulted = switch (try default_fn.callableNamespaces(arena, try default_fn.nameAnonymous(arena, parsed), templateRegistry, registry)) {
        .ok => |p| p,
        .refused => |te| {
            env.deinit();
            return .{ .typeError = te };
        },
    };
    // Decision 297: a `comptime x: V | type T` parameter's two forms.
    // Decision 330 (7): a type declared in a type's body is a top-level type
    // under its owner's path.
    const namespaced = try std_namespace.expand(arena, defaulted);
    // Decision 669 — the `print` / `panic` this module's std imports bind,
    // kept for the members it hands on as text before `std_calls.expand`
    // drops an import every use of which was a call.
    for (try std_calls.itemsOf(arena, namespaced)) |it| {
        try reflection.stdCalls.put(reflection.arena, try reflectionMod.Reflection.scopeKey(reflection.arena, mod.path, it.local), it);
    }
    const hoisted = try nested_types.expand(arena, try value_or_type.expand(arena, try inline_types.expand(arena, try std_calls.expand(arena, namespaced, stdKeyOf(mod.path)))));
    // Decision 804 (1): a type implementing `Component<R>` is the component
    // its `compose` is the body of, and the record its `self` reads.
    const nested = switch (try component_types.expand(arena, hoisted)) {
        .ok => |r| blk: {
            for (r.composed) |c| try env.composedTypes.put(env.arena, c.record, c.component);
            break :blk r.program;
        },
        .refused => |te| {
            env.deinit();
            return .{ .typeError = te };
        },
    };
    // Decision 298: a module that reads a catalogue entry's typed meta
    // (`d.meta(T)`) declares the function the read calls, inferred with it.
    // Decision 307: `pub val RecipeTitle = Type.pick(Recipe, .title);` is the
    // record declaration it answers.
    const expanded = switch (try derived_types.expand(arena, try typed_meta.withMetaHelper(arena, nested), .{ .ctx = typeDeclRegistry, .find = derivedTypeSource })) {
        .ok => |p| p,
        .refused => |te| {
            env.deinit();
            return .{ .typeError = te };
        },
    };
    // Decision 216 (3): `Owner.Name` of an imported owner (or of this
    // module's, on a re-analysis) reaches the checker as the declared name.
    var owners = try assocOwners(arena, expanded, mod.path, typeDeclRegistry, reflection);
    const unadopted = try assocTypes.expand(arena, expanded, &owners);
    // Decision 216 (4): a module reading `@TypeInfo.all` is answered on its
    // re-analysis, after its own decorators ran.
    const typeinfo_queries = if (skip_invoke) &.{} else try typeinfoAll.collect(arena, unadopted);
    env.typeinfoAllPending = typeinfo_queries.len > 0;

    if (validation.validateComptime(unadopted)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    resolveImports(&env, unadopted, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    const with_expansions = withExpansionImports(arena, &env, unadopted, mod.package, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    // Decision 793 (3) — a top-level `comptime` block's call of another
    // module's function that writes `compiler.init`, expanded at the call
    // before the block's decorator runs (`expand_call.expandBlockCalls`).
    const with_block_calls = expand_call.expandBlockCalls(&env, with_expansions) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };
    // 144 B-19 — a type adopts the instance defaults of a behavior it
    // implements from another module (`adopt_defaults.zig`).
    const program = try adoptDefaults.expand(arena, with_block_calls, try behaviorsReached(arena, &env.importedBehaviorDecls, typeDeclRegistry), env.importedImplements.items);
    // Decisions 341, 434 — a host function a decorator of this module reaches
    // has one of the comptime runtime's three sources; decided when the
    // package is compiled, never at a consumer's build.
    if (try hostCells.checkDecorators(&env, program.decls, infer.isDecoratorParams)) |te| {
        env.deinit();
        return .{ .typeError = te };
    }
    // Decision 343 — each decorator invocation is independent: a body
    // writing a module-level `var` is refused at the write.
    if (try decoratorEval.checkIndependent(arena, program.decls, infer.isDecoratorParams)) |te| {
        env.deinit();
        return .{ .typeError = te };
    }
    const written: ?ast.Program = if (keep_resolved) try context_lower.deepCopy(ast.Program, arena, program) else null;
    const bindings = infer.inferProgramTyped(&env, program) catch |err| switch (err) {
        error.TypeError => {
            const te = inline_types.locatedAtCall(env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } });
            if (env.targetTrace) |t| t.build_output = env.buildOutput.items;
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
        // The declarations put before the module's own: an executor's anchor
        // (decision 580) moves past them.
        var prepended: usize = 0;
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
                    prepended += pl.imports.len;
                },
                .refused => |te| {
                    env.deinit();
                    return .{ .typeError = te };
                },
            }
        }
        // Decisions 384, 385 — the names a library member and a catalogue
        // entry's `@Expr` fields wrote elsewhere: each type imported under its
        // alias, each value bound by the re-analysis (`written_names.zig`).
        var hygiene: std.ArrayListUnmanaged(envMod.HygieneImport) = .empty;
        try hygiene.appendSlice(arena, env.hygieneImports.items);
        if (typeinfo_plan) |pl| try hygiene.appendSlice(arena, pl.values);
        if (hygiene.items.len > 0) {
            const imports = try written_names.typeImports(arena, hygiene.items);
            const grown = try arena.alloc(ast.DeclKind, imports.len + with_members.decls.len);
            @memcpy(grown[0..imports.len], imports);
            @memcpy(grown[imports.len..], with_members.decls);
            with_members = .{ .decls = grown };
            prepended += imports.len;
        }
        if (try parseAndMergeContributions(arena, source, with_members, env.contributions.items, env.executorAnchors.items, prepended)) |merged_written| {
            // Decisions 787, 792 — an executor that runs a loaded file names
            // what its `run()` is rewritten to (`loadMod.withRunImports`).
            const merged_program = try loadMod.withRunImports(arena, merged_written);
            // Decision 575 (6): a library's `compiler.implement` of this pass
            // joins the declarations the re-analysis reads.
            try infer.applyImplementContributions(&env, merged_program);
            var reanalysis = try analyzeMerged(arena, mod, merged_program, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, reflection, typeinfo_plan, hygiene.items);
            if (reanalysis == .typeError) reanalysis.typeError = locateInOutputs(arena, reanalysis.typeError, source, &env);
            if (reanalysis == .success) {
                // The target's refusals are the emit's (decision 798 (4)),
                // located as an inference error here would be.
                for (reanalysis.success.env.stdHostCalls.items) |*c| c.site = locateSite(arena, c.site, source, &env);
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
        var reanalysis = try analyzeSource(arena, mod, spliced, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, true, reflection, inserts, env.implementContributions.items);
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

    return .{ .success = .{ .bindings = bindings, .env = env, .program = program, .written = written } };
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
/// Decision 337 — every dotted name a module reads outside its imports, for
/// the CLI's dependency order (`mod_namespace.chains`).
pub const namespaceChains = mod_namespace.chains;

/// The embedded source of std's sidecar file `base` (`random.mjs`), or null.
pub fn stdSidecar(base: []const u8) ?[]const u8 {
    for (@import("std_prelude").std_sidecars) |sc| {
        if (std.mem.eql(u8, sc.name, base)) return sc.source;
    }
    return null;
}

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
/// canonical/documented copy lives in `libs/std/src/primitives.bp`'s compiler section; this minimal
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
/// `HookUse`, `HookCall` and the `TypeInfo<T>` a `use`'s type argument is
/// (`HookNode.async`, decision 375) and its stage (`HookNode.stage`,
/// decision 376); a
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
    \\pub type __DeclKind { Type, Behavior, Fn, Method, Field, Val, Element, Component }
    \\pub type __Span(start: i32, end: i32, line: i32)
    \\pub type SourceLocation(file: string, line: i32, column: i32, fnName: string)
    \\pub type Asset(path: string, bytes: bytes, size: i64, hash: string) {
    \\    pub declare fn text(self: Self) -> string;
    \\}
    \\pub behavior Decorator {
    \\    fn same(self: Self, other: Decorator) -> bool;
    \\}
    \\pub type __Decl__Annotation(name: string, args: string[], decorator: Decorator)
    \\pub type __Decl__Param(name: string, typeName: string)
    \\pub type __Decl__Field(name: string, typeName: string, annotations: __Decl__Annotation[])
    \\pub type __Decl__Method(name: string, params: __Decl__Param[], returnType: string, annotations: __Decl__Annotation[])
    \\pub type __Decl__Variant(name: string, fields: __Decl__Field[], annotations: __Decl__Annotation[], section: ?string)
    \\pub type DeclaredMeta(key: string, value: string)
    \\pub type DeclaredTypedMeta(key: string, value: unknown)
    \\pub type Declared<T>(name: string, module: string, meta: DeclaredMeta[], returnTypeName: string, value: T, typedMeta: DeclaredTypedMeta[])
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
    \\pub type HookCall(callee: ?Declared<unknown>, at: string)
    \\pub type Stage { Build, Run, Any }
    \\pub type __HookNode(function: Declared<unknown>, uses: HookUse[], calls: HookCall[], async: bool, stage: Stage)
    \\pub type __Decl(
    \\    kind: __DeclKind,
    \\    name: string,
    \\    fields: __Decl__Field[],
    \\    variants: __Decl__Variant[],
    \\    methods: __Decl__Method[],
    \\    returnType: string,
    \\    annotations: __Decl__Annotation[],
    \\    hooks: __HookNode[],
    \\    params: __Decl__Param[],
    \\    component: ?__Decl,
    \\    module: string,
    \\    owner: ?Declared<unknown>,
    \\    package: string) {
    \\    pub declare fn attr(self: Self, name: string) -> ?string;
    \\    pub declare fn fail(self: Self, message: string) -> void;
    \\    pub declare fn failAt(self: Self, span: __Span, message: string) -> void;
    \\    pub declare fn addMember(self: Self, source: string) -> void;
    \\    pub declare fn setMeta(self: Self, key: string, value: string) -> void;
    \\    pub declare fn addMeta<T>(self: Self, value: T) -> void;
    \\    pub declare fn addType(self: Self, name: string, source: string) -> void;
    \\    pub declare fn compile(self: Self, executor: fn()) -> void;
    \\    pub declare fn implement(self: Self, source: Implementation) -> void;
    \\}
    \\pub type __Source(file: string, line: i32, col: i32)
    \\pub type __ExprContext(source: __Source, text: string, multiline: bool)
    \\pub type __CustomNode(kind: string, span: __Span, label: string, ref: ?__Decl, children: __CustomNode[])
;

/// The `@ExprCustom` reference-tree type (expr-custom), registered into the
/// global env so a sub-language template body can BUILD a `CustomNode` tree
/// (`CustomNode(kind: …, span: …, …)`) and hand it to `q.custom`. Like the
/// `@Decl` cluster this mirrors the surface documented in
/// `libs/std/src/primitives.bp`'s compiler section; registered after `decl_reflection_src` so its
/// `Span` field type resolves. `Decl` (the `ref` field) is what `q.lookup`
/// answers (decision 415 (2)). Generic — the core never inspects `kind`/`label`.
const custom_ast_reflection_src =
    \\pub type __CustomNode(
    \\    kind: string,
    \\    span: __Span,
    \\    label: string,
    \\    ref: ?__Decl,
    \\    children: __CustomNode[],
    \\)
;

/// Decision 248 — the field descriptor `@makeRecord` reads, registered into
/// the global env; mirrors `libs/std/src/primitives.bp`'s compiler section's `pub type
/// RecordField`. `TypeInfo<T>` (decisions 216, 253) is in the `@Decl` cluster
/// above, since a `HookUse` names it (decision 277); its static `all` is
/// reached only as the builtin `@TypeInfo.all`, so the mirror leaves it out.
const type_info_src =
    \\pub type RecordField(
    \\    name: string,
    \\    typeName: string,
    \\)
;

/// Decision 252 — every mirror above of a type `primitives.bp`'s compiler section declares, in
/// registration order; `comptime/builtins.zig`'s drift test holds each type
/// they declare to its declaration (fields, variants, instance methods), the
/// internal `__Decl__X` names read through their aliases.
pub const builtin_type_mirrors = [_][]const u8{ decl_reflection_src, custom_ast_reflection_src, type_info_src, yield_step_src };

/// `YieldStep<T>` (decision 122) — the one step of both sequences, `Yield`
/// then `Done`, registered into the global env so an annotation, a `case` over
/// its variants and a `.next()` called by hand type-check. The canonical copy
/// is `libs/std/src/primitives.bp`'s compiler section's (`yield step prelude
/// matches primitives.bp` below reads both).
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
/// Decision 617 (1) — the contract a primitive type implements (`i32` →
/// `Signed`), read from `primitives.bp`.
const prelude_cache = @import("codegen/prelude_cache.zig");
pub const primitiveContract = prelude_cache.primitiveContract;
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

/// The module a lookup of `imp`'s leaf admits (`ImportSource.admits`): the
/// module its prefix names (`ImportDecl.leafSource`) — and, for an item with
/// no `from` and no path (`import {config};`), the module the item itself
/// names. Decision 337 refuses the shorthand (`refuseShorthand`), so such an
/// item names a module of the package, and a symbol of that name is looked
/// up there and nowhere else: no bare name reaches another module, a
/// dependency's or std's.
fn itemSource(u: ast.ImportDecl, imp: ast.ImportPath, arena: std.mem.Allocator) !ast.ImportSource {
    return u.leafSource(imp, arena, u.source == .root and !imp.isQualified());
}

/// Decision 337 (1) — `error[shorthand-import]` at an item with no `from`
/// whose first segment names no module of the package, its fix written: the
/// path of the one module of the package that declares the name `pub`, the
/// candidates when several do, `unresolved import` when none does.
fn refuseShorthand(env: *envMod.Env, tree: *const mod_tree.Tree, u: ast.ImportDecl, imp: ast.ImportPath) error{ TypeError, OutOfMemory } {
    const a = env.arena;
    const name = imp.segments[0];
    const who = try tree.declarers(a, u.ownPackage, env.modulePath, name);
    var item: std.ArrayListUnmanaged(u8) = .empty;
    try item.appendSlice(a, try imp.dotted(a));
    if (imp.activate) try item.append(a, '*');
    if (imp.alias) |al| try item.print(a, " as {s}", .{al});
    const hint = "An import names where its names come from: a module of this package by its path inside the braces (`import {config.splitPath};`), a package with `from` (`import {path.basename} from \"std\";`).";
    const msg = switch (who.len) {
        0 => try std.fmt.allocPrint(a, "{s}: unresolved import `{s}` — `{s}` names no module of this package, and no module of it declares `{s}` `pub`", .{ diagnostics.shorthand_import, item.items, name, name }),
        1 => try std.fmt.allocPrint(a, "{s}: `{s}` names no module of this package — write import {{{s}.{s}}};", .{ diagnostics.shorthand_import, name, try dottedKey(a, u.ownPackage, who[0]), item.items }),
        else => blk: {
            var fixes: std.ArrayListUnmanaged(u8) = .empty;
            for (who, 0..) |k, i| {
                if (i > 0) try fixes.appendSlice(a, if (i + 1 == who.len) " or " else ", ");
                try fixes.print(a, "import {{{s}.{s}}};", .{ try dottedKey(a, u.ownPackage, k), item.items });
            }
            break :blk try std.fmt.allocPrint(a, "{s}: `{s}` names no module of this package, and {d} modules declare it `pub` — write {s}", .{ diagnostics.shorthand_import, name, who.len, fixes.items });
        },
    };
    env.lastError = validation.TypeError.custom(msg, hint).withLoc(imp.loc);
    return error.TypeError;
}

/// A module key as an import item spells its path in the package
/// (`a/log/levels` in `a` → `log.levels`).
fn dottedKey(arena: std.mem.Allocator, package: []const u8, key: []const u8) ![]const u8 {
    const out = try arena.dupe(u8, mod_tree.localPath(package, key));
    std.mem.replaceScalar(u8, out, '/', '.');
    return out;
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

/// True when `source` declares a module-level `var`. A source that does not
/// parse declares none here; `analyzeModule` reports it later.
fn declaresModuleVar(source: []const u8) bool {
    // A probe: its tokens and tree are scratch (144 B-127).
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(scratch) catch return false;
    var p = Parser.init(tokens);
    const program = p.parse(scratch) catch return false;
    for (program.decls) |decl| switch (decl) {
        .val => |v| if (v.mutable) return true,
        else => {},
    };
    return false;
}

/// True when `path` is a "std" package registry key (`std/<module>`).
fn isStdPkgPath(path: []const u8) bool {
    return std.mem.startsWith(u8, path, "std/");
}

/// The std key of a std module's path (`std/io/terminal` → `io/terminal`),
/// null for any other module.
fn stdKeyOf(path: []const u8) ?[]const u8 {
    return if (isStdPkgPath(path)) path["std/".len..] else null;
}

/// Scans `modules` for `import {…} from "std"` declarations and returns the
/// module list with the required embedded std modules prepended (dependency
/// order, deduplicated). Modules that fail to parse pass through untouched —
/// `analyzeModule` reports the parse error later.
///
/// A module that declares a module-level `var` needs `std/beam` too, whether
/// or not it imports it: the BEAM emitters lower the binding's reads and
/// writes onto that module's host primitives (front 17, decision 43's layer
/// 2), so the module has to be in the build for the calls to answer. It is
/// analysed whatever the target — comptime never reads the target (decision
/// 798 (4)) — and the emit of a target that is not the BEAM leaves it out
/// when no module imports it (`codegen/target_check.zig` `withoutBeamStorage`).
fn expandStdImports(arena: std.mem.Allocator, modules: []const Module, lb: ?*levelB.Session) ![]const Module {
    var needed = [_]bool{false} ** std_pkg_modules.len;
    var any = false;
    for (modules) |mod| {
        // A module read back from the code cache's level B (144 B-60) is not
        // parsed: its entry's META names the std modules it needs.
        if (lb) |l| if (l.hitMeta(mod)) |mm| {
            for (mm.std_imports) |p| if (stdIndex(p)) |i| {
                needed[i] = true;
                any = true;
            };
            continue;
        };
        const needs = try stdNeedsOf(arena, mod);
        for (needs) |i| {
            needed[i] = true;
            any = true;
        }
        if (lb) |l| {
            const paths = try arena.alloc([]const u8, needs.len);
            for (needs, paths) |i, *p| p.* = std_pkg_modules[i].path;
            try l.noteStdNeeds(mod, paths);
        }
    }
    if (!any) return modules;

    // A std module that imports another std module needs it too, however deep
    // the chain goes, and each one is emitted after what it imports.
    const graph = try stdGraph();
    const beam_at = for (std_pkg_modules, 0..) |spm, i| {
        if (std.mem.eql(u8, spm.path, "std/beam")) break i;
    } else std_pkg_modules.len;
    var changed = true;
    while (changed) {
        changed = false;
        for (0..std_pkg_modules.len) |i| {
            if (!needed[i]) continue;
            for (graph.imports[i]) |dep| if (!needed[dep]) {
                needed[dep] = true;
                changed = true;
            };
            // A std module that declares a module-level `var` reaches
            // `std/beam` the same way a user module does (above), imported
            // or not.
            if (beam_at < std_pkg_modules.len and !needed[beam_at] and graph.declares_var[i]) {
                needed[beam_at] = true;
                changed = true;
            }
        }
    }

    var out: std.ArrayListUnmanaged(Module) = .empty;
    for (graph.order) |i| {
        const spm = std_pkg_modules[i];
        // An embedded std module is `libs/std/src/<name>.bp` inside its own
        // package, so that is what its `@src().file` answers (decision 73).
        if (needed[i]) try out.append(arena, .{
            .path = spm.path,
            .source = spm.source,
            .srcPath = try std.fmt.allocPrint(arena, "src/{s}.bp", .{spm.path["std/".len..]}),
            // std's own (decision 445): its `std:` cells are std's to write.
            .std_member = true,
        });
    }
    try out.appendSlice(arena, modules);
    return out.toOwnedSlice(arena);
}

/// The index in `std_pkg_modules` of the std module `path` (`std/<m>`).
fn stdIndex(path: []const u8) ?usize {
    for (std_pkg_modules, 0..) |spm, i| if (std.mem.eql(u8, spm.path, path)) return i;
    return null;
}

/// The std modules (indices into `std_pkg_modules`, ascending) module `mod`
/// needs itself: each `from "std"` item, `std/context` for a `@Component`, and
/// `std/beam` for a module-level `var` (`expandStdImports`). A
/// module that does not parse needs what its `@Component` says; its analysis
/// reports the error.
fn stdNeedsOf(arena: std.mem.Allocator, mod: Module) ![]const usize {
    var needed = [_]bool{false} ** std_pkg_modules.len;
    // The module's tokens and tree here are a probe's: scratch (144 B-127).
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    collect: {
        // Decisions 388, 819 — a program that writes `@Component` needs std's
        // `context` module: every component is lowered to a function over its
        // `Scope` and `Place`, which std's functions open and run
        // (`comptime/context_lower.zig`).
        if (!isStdPkgPath(mod.path) and std.mem.indexOf(u8, mod.source, "@Component") != null) {
            if (stdIndex("std/context")) |i| needed[i] = true;
        }
        var lx = Lexer.init(mod.source);
        const tokens = lx.scanAll(scratch) catch break :collect;
        var p = Parser.init(tokens);
        // Decision 606 (1) — `Component<R>` written bare is the prelude's
        // unless the module declares or imports its own.
        if (!isStdPkgPath(mod.path) and std.mem.indexOf(u8, mod.source, "Component<") != null and
            !parserTypes.preludeNameShadowed(&p, "Component"))
        {
            if (stdIndex("std/context")) |i| needed[i] = true;
        }
        // The same rewrite `analyzeSource` makes, so a module reached only
        // through a folder namespace (`io.fs.f()`) or a module's type
        // (`collections.Dict.empty()`) is embedded like any imported one.
        // Decision 780 — a module that loads a file imports std's
        // `compiler.Diagnostic` (`loadMod.withLoadHelper`), as `analyzeSource` adds it.
        const parsed = loadMod.withLoadHelper(scratch, p.parse(scratch) catch break :collect) catch break :collect;
        const expanded = std_namespace.expand(scratch, parsed) catch break :collect;
        // A namespace every use of which is a `print` / `panic` call is
        // dropped, as the compile drops it (144 B-151): its module is no
        // dependency.
        const program = std_calls.expand(scratch, expanded, null) catch break :collect;
        for (program.decls) |decl| switch (decl) {
            .val => |v| if (v.mutable) {
                if (stdIndex("std/beam")) |i| needed[i] = true;
            },
            .use => |u| {
                if (!importsStd(u, isStdPkgPath(mod.path))) continue;
                for (u.imports) |imp| {
                    // Decision 107 — the item names a module by its whole path
                    // (`io.fs`, the namespace form) or a symbol of the module
                    // its prefix names (`io.fs.readText`); a single segment is
                    // both spellings of `dict`. Whichever matches is needed.
                    const whole = try imp.fullPath(scratch);
                    // Decision 606 (2) — `print` / `panic` used only as calls
                    // is the call node and `std_calls.expand` above dropped its
                    // item: its module is no dependency. An item still here was
                    // read as a value (a local named `print` is read too) and
                    // the backends require its module, so it is needed.
                    const prefix = try imp.prefixPath(scratch);
                    for (std_pkg_modules, 0..) |spm, i| {
                        const key = spm.path["std/".len..];
                        if (std.mem.eql(u8, key, whole) or (prefix.len > 0 and std.mem.eql(u8, key, prefix))) needed[i] = true;
                    }
                }
            },
            else => {},
        };
    }
    var out: std.ArrayListUnmanaged(usize) = .empty;
    for (needed, 0..) |n, i| if (n) try out.append(arena, i);
    return out.items;
}

/// std's own import graph: each std module's std imports (`stdImportsOf`)
/// and the order every build emits them in (`stdModuleOrder`). std is
/// embedded in the binary, so it is computed once per process — every
/// compile used to parse every std module for it.
const StdGraph = struct {
    imports: []const []const usize,
    order: []const usize,
    /// Per std module, whether it declares a module-level `var`
    /// (`declaresModuleVar`): on erlang and beam it needs `std/beam`.
    declares_var: []const bool,
};
var std_graph_arena: std.heap.ArenaAllocator = undefined;
var std_graph: StdGraph = undefined;
/// 0 = not computed, 1 = computing, 2 = ready (as `stdlib_template_init`).
var std_graph_init: std.atomic.Value(u8) = .init(0);

fn stdGraph() !*const StdGraph {
    while (true) {
        const s = std_graph_init.load(.acquire);
        if (s == 2) return &std_graph;
        if (s == 0) {
            if (std_graph_init.cmpxchgStrong(0, 1, .acquire, .acquire)) |_| continue;
            std_graph_arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            errdefer {
                std_graph_arena.deinit();
                std_graph_init.store(0, .release);
            }
            const arena = std_graph_arena.allocator();
            const imports = try arena.alloc([]const usize, std_pkg_modules.len);
            const declares_var = try arena.alloc(bool, std_pkg_modules.len);
            for (std_pkg_modules, imports, declares_var) |spm, *im, *dv| {
                im.* = try stdImportsOf(arena, spm.source);
                dv.* = declaresModuleVar(spm.source);
            }
            std_graph = .{ .imports = imports, .order = try stdModuleOrder(arena), .declares_var = declares_var };
            std_graph_init.store(2, .release);
            return &std_graph;
        }
        std.atomic.spinLoopHint();
    }
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
    // The tokens are scratch: the tree holds none (144 B-127).
    var token_scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer token_scratch.deinit();
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(token_scratch.allocator()) catch |err| {
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
    // A probe: its tokens and tree are scratch, only the indices are kept
    // (144 B-127).
    var scratch_state = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer scratch_state.deinit();
    const scratch = scratch_state.allocator();
    var lx = Lexer.init(source);
    const tokens = lx.scanAll(scratch) catch return &.{};
    var p = Parser.init(tokens);
    const program = p.parse(scratch) catch return &.{};
    var out: std.ArrayListUnmanaged(usize) = .empty;
    for (program.decls) |decl| {
        if (decl != .use) continue;
        const u = decl.use;
        if (!importsStd(u, true)) continue;
        for (u.imports) |imp| {
            const whole = try imp.fullPath(scratch);
            if (std_calls.isDroppedItem(whole)) continue;
            const prefix = try imp.prefixPath(scratch);
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
/// (`stdImportsOf`), `std/compiler` first (decision 608), otherwise in
/// `std_pkg_modules` order. A cycle keeps the
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
    // Decision 608 — `compiler.bp` is self-contained and std's first module:
    // `primitives.bp` and every other module that names one of its types
    // (`#[compiler.external(…)]`'s `Implementation`) is inferred after it.
    if (stdIndex("std/compiler")) |c| try Visit.visit(arena, c, state, &out);
    for (0..n) |i| try Visit.visit(arena, i, state, &out);
    return out.toOwnedSlice(arena);
}

/// Decision 562 — `program` with the imports each function expanded here
/// from another module needs (`expand_call.importsFor`: the types and
/// namespaces its body names, under aliases no source writes), resolved as
/// any import of the module is and written ahead of its declarations, so the
/// checker and every backend read them as written.
fn withExpansionImports(
    arena: std.mem.Allocator,
    env: *envMod.Env,
    program: ast.Program,
    package: []const u8,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
) !ast.Program {
    const extra = try expand_call.importsFor(env, program.decls, package);
    const expanded: ast.Program = if (extra.len == 0) program else blk: {
        const marked = try ast.ImportDecl.withOwnPackage(arena, .{ .decls = extra }, package);
        try resolveImports(env, marked, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry);
        const grown = try arena.alloc(ast.DeclKind, marked.decls.len + program.decls.len);
        @memcpy(grown[0..marked.decls.len], marked.decls);
        @memcpy(grown[marked.decls.len..], program.decls);
        break :blk .{ .decls = grown };
    };
    // Decision 757 — the copies per type argument of the imported functions
    // this module's calls ask for, and the imports their names need
    // (`token_import.zig`).
    const planned = try token_import.plan(env, expanded, package, ExportedFns{ .arena = arena, .registry = templateRegistry });
    if (planned.copies.len == 0) return expanded;
    const marked = try ast.ImportDecl.withOwnPackage(arena, .{ .decls = try arena.dupe(ast.DeclKind, planned.imports) }, package);
    if (marked.decls.len > 0) try resolveImports(env, marked, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry);
    const grown = try arena.alloc(ast.DeclKind, marked.decls.len + expanded.decls.len + planned.copies.len);
    @memcpy(grown[0..marked.decls.len], marked.decls);
    @memcpy(grown[marked.decls.len..][0..expanded.decls.len], expanded.decls);
    @memcpy(grown[marked.decls.len + expanded.decls.len ..], planned.copies);
    return .{ .decls = grown };
}

/// A module's `pub fn` by its path and name, as that module exported it
/// (`defaultParamsKey`) — `token_import.plan`'s reach into a declaring module.
const ExportedFns = struct {
    arena: std.mem.Allocator,
    registry: *const std.StringHashMap(ast.FnDecl),

    pub fn fnOf(self: ExportedFns, module: []const u8, name: []const u8) ?ast.FnDecl {
        return self.registry.get(defaultParamsKey(self.arena, module, name) catch return null);
    }
};

fn resolveImports(
    env: *envMod.Env,
    program: anytype,
    registry: *std.StringHashMap(std.StringHashMap(*T.Type)),
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    templateRegistry: *const std.StringHashMap(ast.FnDecl),
    decoratorRegistry: *const std.StringHashMap(ast.FnDecl),
    extensionRegistry: *const std.StringHashMap(std.StringHashMap(ast.ImplementDecl)),
) !void {
    const contested = try contestedTypeNames(env, program, typeDeclRegistry);
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
                            // The types its signature names come with it, as
                            // types only (01 R2), as a named import's do: a
                            // template answering `@Expr<Label>` gives the
                            // call's value `Label`'s fields and methods.
                            if (typeDeclRegistry.get(e.key_ptr.*)) |decls| try infer.registerImportedSignatureClosure(env, decls, ty);
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
                    // Decision 337 — an item with no `from` names a module of
                    // the package by its first segment; the shorthand
                    // (`import {splitPath};`) is refused, its fix written.
                    if (u.source == .root and u.package == null and !u.activationOnly) if (env.reflection) |r| if (r.modTree) |tree| if (tree.known) {
                        if (!tree.isModule(try mod_tree.keyIn(env.arena, u.ownPackage, imp.segments[0]))) return refuseShorthand(env, tree, u, imp);
                    };
                    if (from_std) {
                        // Decision 637 — a std template (`import {code} from
                        // "std"`, the module's default; `import {code.code}`,
                        // by name) expands at its call as a library's does.
                        if (!imp.activate) {
                            const whole = try std.fmt.allocPrint(env.arena, "std/{s}", .{try std.mem.join(env.arena, "/", imp.segments)});
                            const prefix = try std.fmt.allocPrint(env.arena, "std/{s}", .{try imp.prefixPath(env.arena)});
                            const hit: ?struct { owner: []const u8, tfn: ast.FnDecl } = if (templateRegistry.get(try default_fn.key(env.arena, whole))) |f|
                                .{ .owner = whole, .tfn = f }
                            else if (imp.isQualified()) (if (templateRegistry.get(try comptimeRegistryKey(env.arena, prefix, imp.leaf()))) |f| .{ .owner = prefix, .tfn = f } else null) else null;
                            if (hit) |h| if (h.tfn.returnType) |rt| if (rt.isTemplateReturnType()) {
                                // Its value, as a library template's is bound
                                // (the call is checked against it first).
                                if (registry.get(h.owner)) |ex| if (ex.get(h.tfn.name)) |ty| try env.bind(imp.name(), ty);
                                try infer.registerImportedTemplateFn(env, imp.name(), h.tfn, h.owner);
                                try importTemplateSupport(env, decoratorRegistry, h.owner, h.tfn.name, h.tfn);
                                if (registry.getPtr(h.owner)) |ex| try env.templateOwnerExports.put(env.arena, h.owner, ex);
                            };
                        }
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
                    var leaf_src = try itemSource(u, imp, env.arena);
                    // Decision 337 (3) — a name the module re-exports
                    // (`pub val splitPath = mod2.splitPath;`, `pub type Pair =
                    // mod2.Pair;`) is the declaration it names: looked up
                    // there, and the backends told so (`itemOwners`).
                    var redirected = false;
                    if (leaf_src == .key) if (env.reflection) |r| if (r.modTree) |tree| {
                        if (try tree.reexportOf(env.arena, leaf_src.key, name)) |re| {
                            leaf_src = .{ .key = re.owner };
                            redirected = true;
                        }
                    };
                    // Decision 107's namespace form over a module of this
                    // package or a dependency: the item's whole path names a
                    // module (`import {jwt} from "sec"` → `sec/jwt`, `import
                    // {text};` → `text`), and the name binds a namespace its
                    // calls resolve against — ahead of the bare-name scan
                    // below, which would bind some other module's `text`.
                    // Decision 582 — the namespace always: no symbol named
                    // like the item wins over it, and written as a value it is
                    // the module's default (`default_fn.callableNamespaces`).
                    if (!imp.activate) switch (try u.leafSource(imp, env.arena, true)) {
                        .module, .key => |path| if (!isStdPkgPath(path)) if (registry.get(path)) |exports| {
                            try env.namespaces.modules.put(env.arena, local, exports);
                            try env.namespaces.paths.put(env.arena, local, path);
                            // 144 B-155 — a `comptime` that calls `ns.f(…)` carries `f`
                            // with its closure, as it carries an imported one.
                            try importTemplateAliasClosures(env, decoratorRegistry, path);
                            var eit = exports.keyIterator();
                            while (eit.next()) |fname| {
                                if (templateRegistry.get(try defaultParamsKey(env.arena, path, fname.*))) |pfn| {
                                    try env.namespaces.params.put(env.arena, try envMod.NamespaceImports.paramsKey(env.arena, local, fname.*), pfn.params);
                                    try env.importedFnDecls.put(env.arena, try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ local, fname.* }), pfn);
                                    // Decision 562 — `ns.f(…)` of a function expanded at its call site.
                                    if (try hooksMod.isExpandedFn(env.arena, pfn)) try env.expandedImports.put(env.arena, try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ local, fname.* }), .{ .decl = pfn, .owner = path });
                                    // Decision 757 — `ns.f(T, …)` of a function copied per type.
                                    if (try type_token.copiedPerType(env.arena, pfn)) try env.tokenImports.put(env.arena, try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ local, fname.* }), .{ .decl = pfn, .owner = path });
                                }
                                // Decision 719 — `ns.f(…)` of a template (a function with a
                                // `syntax` parameter) expands at its call as `f(…)` imported by
                                // name does: bound under `<ns>.<name>`.
                                if (templateRegistry.get(try comptimeRegistryKey(env.arena, path, fname.*))) |tfn| if (isTemplateFn(tfn) and ast.syntaxExprIndex(tfn.params) != null) {
                                    try infer.registerImportedTemplateFn(env, try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ local, fname.* }), tfn, path);
                                    try importTemplateSupport(env, decoratorRegistry, path, fname.*, tfn);
                                    if (registry.getPtr(path)) |ex| try env.templateOwnerExports.put(env.arena, path, ex);
                                };
                                // Decision 386 — the module's body-carrying
                                // decorators travel with the namespace, under
                                // `<ns>.<name>` (as a std module's do,
                                // `infer.registerStdDecorators`): `#[markers.tag]`
                                // runs `tag` as `#[tag]` imported by name does.
                                if (decoratorRegistry.get(try comptimeRegistryKey(env.arena, path, fname.*))) |dfn| {
                                    var support: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
                                    var si: usize = 0;
                                    while (decoratorRegistry.get(try decoratorSupportKey(env.arena, path, fname.*, si))) |sf| : (si += 1) {
                                        try support.append(env.arena, sf);
                                    }
                                    const conflict = if (decoratorRegistry.get(try decoratorConflictKey(env.arena, path, fname.*))) |c| c.name else null;
                                    const qualified = try std.fmt.allocPrint(env.arena, "{s}.{s}", .{ local, fname.* });
                                    try infer.registerImportedDecorator(env, qualified, dfn, path, support.items, conflict);
                                }
                            }
                            continue;
                        } else if (failedModule(env, path)) |failed| {
                            // The namespace's module was refused: a use of
                            // it names that module, not an unbound name.
                            try env.failedImports.put(env.arena, local, .{ .module = failed, .loc = imp.loc });
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
                            if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
                            // Decision 562 — the alias a function expanded
                            // here names its module's type under reaches a
                            // private one too: that module shares its
                            // privates (`expand_call.importsFor`).
                            const hygienic = if (imp.alias) |al| written_names.isTypeAlias(al) else false;
                            const found = e.value_ptr.get(name) orelse if (hygienic) e.value_ptr.get(try std.mem.concat(env.arena, u8, &.{ private_type_prefix, name })) else null;
                            if (found) |type_decl| {
                                // A behavior is not re-registered as a type:
                                // its value binding below stays what it was,
                                // and the importer only learns its methods.
                                if (type_decl == .behavior) {
                                    // Decision 831 (2) — bound under the name
                                    // the import gives it, an alias included;
                                    // its marks are its declaration's.
                                    try env.importedBehaviorDecls.put(env.arena, local, type_decl.behavior);
                                    var marks: std.ArrayListUnmanaged([]const u8) = .empty;
                                    try appendBehaviorMarks(env, typeDeclRegistry, e.key_ptr.*, type_decl.behavior, &marks, 0);
                                    try env.importedBehaviorMarks.put(env.arena, local, try marks.toOwnedSlice(env.arena));
                                    if (imp.alias == null) infer.takeNameFromPrelude(env, name);
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
                                // Decision 310 — two same-named types of two
                                // modules: the alias is this one's identity.
                                if (imp.alias) |al| if (contested.contains(name) and type_decl == .type_) {
                                    try env.renamedTypeImports.put(env.arena, al, .{ .name = name, .module = e.key_ptr.* });
                                    try infer.registerImportedTypeClosure(env, e.value_ptr.*, type_decl);
                                    try infer.registerRenamedImportedType(env, type_decl.type_, al);
                                    bound_type_decl = true;
                                    break;
                                };
                                if (!seen) {
                                    infer.registerImportedTypeClosure(env, e.value_ptr.*, type_decl) catch |err| return locateInImported(env, err, e.key_ptr.*, imp);
                                    infer.registerImportedTypeDecl(env, type_decl) catch |err| return locateInImported(env, err, e.key_ptr.*, imp);
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
                            if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
                            if (e.value_ptr.contains(name)) {
                                owner = e.key_ptr.*;
                                break;
                            }
                        }
                    }
                    // Another module the backends' name-keyed lookup would also
                    // read declares the name — one this lookup left out of
                    // reach: a module of this package beside `from "<pkg>"`, or
                    // the package `log` beside the module path `log.levelName`
                    // (decision 206). The backends must be told which module
                    // the item names (`withImportSourcesNamed`); std is never
                    // in such a scan.
                    if (redirected and owner.len > 0) try env.itemOwners.put(env.arena, imp.loc, owner);
                    if (owner.len > 0) {
                        var xit = registry.iterator();
                        while (xit.next()) |e| {
                            const k = e.key_ptr.*;
                            if (isStdPkgPath(k) or std.mem.eql(u8, k, owner)) continue;
                            if (!e.value_ptr.contains(name)) continue;
                            const left_out = outOfScope(scope, k);
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
                                if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
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
                                if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
                                if (e.value_ptr.get(name)) |ty_| {
                                    // Decision 310 — its signature names a
                                    // type this module holds under an alias.
                                    const ty = try infer.renameImportedType(env, ty_, e.key_ptr.*);
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
                    // Nothing analysed declares the name, and a module the
                    // item may name was refused earlier in the build: the name
                    // is not missing, its module did not check. A use of it is
                    // `import-of-failed-module` (`infer.unboundAt`), never
                    // `unbound variable` — which buried the one real error
                    // under one per importer, transitively. A name missing
                    // from a module that DID check reaches none of this.
                    if (!bound_type_decl and !bound_behavior and !bound_value and owner.len == 0) failed: {
                        for ([3]u2{ 0, 1, 2 }) |pass| {
                            var fit = (env.reflection orelse break :failed).failedModules.keyIterator();
                            while (fit.next()) |k| {
                                if (isStdPkgPath(k.*)) continue;
                                if (!leaf_src.admits(k.*, pass) or outOfScope(scope, k.*)) continue;
                                try env.failedImports.put(env.arena, local, .{ .module = k.*, .loc = imp.loc });
                                break :failed;
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
                        try env.importedFnDecls.put(env.arena, local, pfn);
                        // Decision 562 — a function expanded at its call site.
                        if (try hooksMod.isExpandedFn(env.arena, pfn)) try env.expandedImports.put(env.arena, local, .{ .decl = pfn, .owner = owner });
                        // Decision 757 — a function copied per type argument.
                        if (try type_token.copiedPerType(env.arena, pfn)) try env.tokenImports.put(env.arena, local, .{ .decl = pfn, .owner = owner });
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
                        // Decision 564 — the behavior its `@Decl<B>` names in its own module.
                        if (infer.declPatternName(dfn)) |bn| if (typeDeclRegistry.get(owner)) |decls| if (decls.get(bn)) |d| if (d == .behavior) {
                            if (env.decorators.getPtr(local)) |sig| sig.declBehavior = bn;
                        };
                    };
                    // 01-compiler/14 step 8 — an imported `val` its module
                    // knew at build: a template hole naming it reads the value.
                    if (owner.len > 0) if (decoratorRegistry.get(try buildValueKey(env.arena, owner, name))) |carrier| {
                        try env.importedBuildValues.put(env.arena, local, carrier.name);
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
                                try env.importedImplements.append(env.arena, impl_decl);
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

/// The module `path` names when the build refused it earlier (its key in
/// `Reflection.failedModules`), else null.
/// A refusal met while registering a declaration of another module of the
/// program (an imported type and its closure) is located in that module's
/// file (the error's `origin`), the importing module's `loc` the import item
/// that brought it — never the declaring file's line read against the
/// importer's file. `infer.locateInStd` is its std twin.
fn locateInImported(env: *envMod.Env, err: anyerror, module_path: []const u8, imp: ast.ImportPath) anyerror {
    if (err == error.TypeError) {
        if (env.lastError) |*te| if (te.origin == null) {
            const r = env.reflection orelse return err;
            const file = r.srcPaths.get(module_path) orelse return err;
            if (te.loc) |at| te.origin = .{ .file = file, .loc = at };
            te.loc = imp.loc;
        };
    }
    return err;
}

fn failedModule(env: *const envMod.Env, path: []const u8) ?[]const u8 {
    const r = env.reflection orelse return null;
    if (isStdPkgPath(path)) return null;
    return if (r.failedModules.getKey(path)) |k| k else null;
}

/// The `first` entry of a type this module declares in `contestedTypeNames`:
/// no module path can spell it.
const local_module_marker: []const u8 = "\x00local";

/// Decision 310 — the declared names two type import items of `program`
/// resolve to in two different modules (`import {m1.T as A}; import {m2.T as
/// B};`): each aliased item of such a name is the type's identity in this
/// module (`Env.renamedTypeImports`). A name this module declares itself
/// counts as one of the two (decision 603): a type of this module beside an
/// aliased import of a same-named type is two types, the import held under its
/// alias — a std leaf too (put in `Env.renamedTypeImports` here, registered by
/// `infer.preRegisterStdImportAliases`). An un-aliased import beside it, and an
/// un-aliased pair (decision 170),
/// stay `import-name-collision` — `noteExplicitTypeNames` refuses both.
fn contestedTypeNames(
    env: *envMod.Env,
    program: anytype,
    typeDeclRegistry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
) !std.StringHashMapUnmanaged(void) {
    var out: std.StringHashMapUnmanaged(void) = .empty;
    var first: std.StringHashMapUnmanaged([]const u8) = .empty;
    // Decision 603 — a type this module declares is one of the sources of its
    // name (held under the name, the module being the one that is not an
    // import's): an aliased import of a same-named type is the other, and is
    // held under its alias.
    var locals: std.StringHashMapUnmanaged(void) = .empty;
    for (program.decls) |decl| {
        const name = switch (decl) {
            .type_ => |t| t.name,
            .typeAlias => |a| a.name,
            .behavior => |b| b.name,
            else => continue,
        };
        try locals.put(env.arena, name, {});
        try first.put(env.arena, name, local_module_marker);
    }
    for (program.decls) |decl| {
        if (decl != .use) continue;
        const u = decl.use;
        const from_std = switch (u.source) {
            .module => |m| std.mem.eql(u8, m, "std"),
            .root, .key => false,
        };
        if (from_std) {
            // A std type leaf (`collections.Dict [as D]`) is one of the two:
            // it keeps its declared name, and the other module's aliased
            // item is the one held under its alias.
            for (u.imports) |imp| {
                if (!imp.isQualified()) continue;
                const name = imp.leaf();
                const path = try std.mem.concat(env.arena, u8, &.{ "std/", try imp.prefixPath(env.arena) });
                const d = (typeDeclRegistry.get(path) orelse continue).get(name) orelse continue;
                if (d != .type_) continue;
                // Decision 603 — beside a type of this module the aliased std
                // item is the one held under its alias
                // (`infer.preRegisterStdImportAliases`); un-aliased, it stays
                // `import-name-collision` (`noteExplicitTypeNames`).
                if (locals.contains(name)) {
                    if (imp.alias) |al| if (!std.mem.eql(u8, al, name)) {
                        try out.put(env.arena, name, {});
                        try env.renamedTypeImports.put(env.arena, al, .{ .name = name, .module = path });
                    };
                    continue;
                }
                const gop = try first.getOrPut(env.arena, name);
                if (!gop.found_existing) {
                    gop.value_ptr.* = path;
                } else if (!std.mem.eql(u8, gop.value_ptr.*, path)) {
                    try out.put(env.arena, name, {});
                }
            }
            continue;
        }
        const scope = packageScope(typeDeclRegistry, u.source);
        for (u.imports) |imp| {
            const name = imp.leaf();
            if (name.len == 0 or !std.ascii.isUpper(name[0])) continue;
            var leaf_src = try itemSource(u, imp, env.arena);
            if (leaf_src == .key) if (env.reflection) |r| if (r.modTree) |tree| {
                if (try tree.reexportOf(env.arena, leaf_src.key, name)) |re| leaf_src = .{ .key = re.owner };
            };
            const module: []const u8 = found: for ([3]u2{ 0, 1, 2 }) |pass| {
                var it = typeDeclRegistry.iterator();
                while (it.next()) |e| {
                    if (isStdPkgPath(e.key_ptr.*)) continue;
                    if (!leaf_src.admits(e.key_ptr.*, pass) or outOfScope(scope, e.key_ptr.*)) continue;
                    const d = e.value_ptr.get(name) orelse continue;
                    if (d != .type_) break :found "";
                    break :found e.key_ptr.*;
                }
            } else "";
            if (module.len == 0) continue;
            const gop = try first.getOrPut(env.arena, name);
            if (!gop.found_existing) {
                gop.value_ptr.* = module;
            } else if (!std.mem.eql(u8, gop.value_ptr.*, module)) {
                try out.put(env.arena, name, {});
            }
        }
    }
    return out;
}

/// Cross-module aggregation for the package-default DSL. A package's
/// `pub default mod` (the `import <pkg>` handle) and `pub default fn` (the
/// handler) may live in different modules; this pairs them — keyed by package key
/// (the module-path prefix before the first `/`, "" for the root package) — so
/// the handler can be aliased under the handle for `import <pkg>` to bind.
pub const DefaultDsl = struct {
    /// pkgKey -> default module name (= the import handle).
    modName: std.StringHashMap([]const u8),
    /// pkgKey -> the package's default handler fn (defining path + exported type).
    handler: std.StringHashMap(Handler),

    pub const Handler = struct { path: []const u8, type_: *T.Type, decl: ast.FnDecl };

    pub fn init(a: std.mem.Allocator) DefaultDsl {
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

/// Key of an exported `val`'s build value (`block_eval.exportedBuildValue`),
/// carried, as a conflict is, in a bodyless `FnDecl`'s name.
fn buildValueKey(arena: std.mem.Allocator, path: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}\x00{s}\x00build", .{ path, name });
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

/// `f` as a comptime module of an importer carries it: its `same` calls
/// lowered (decision 371) and, a function of this module (`fns`), its std
/// calls renamed (decision 341, `host_cells.Writer`); a function another
/// module brought was renamed when that module exported it.
fn exportedFn(arena: std.mem.Allocator, env: *envMod.Env, hosts: *hostCells.Writer, fns: *const std.StringHashMap(ast.FnDecl), f: ast.FnDecl) !ast.FnDecl {
    const lowered = try infer.lowerDecoratorSame(arena, env, fns, f);
    const own = fns.get(f.name) orelse return lowered;
    if (own.body.ptr != f.body.ptr) return lowered;
    return hosts.rewriteAs(f, lowered);
}

/// `support` (what `head` reaches) exported as `exportedFn` exports each
/// function, followed by the host and std functions the lot reaches
/// (`host_cells.hostSupport`, decision 341).
fn exportedSupport(arena: std.mem.Allocator, env: *envMod.Env, hosts: *hostCells.Writer, fns: *const std.StringHashMap(ast.FnDecl), head: ast.FnDecl, support: []const ast.FnDecl) ![]const ast.FnDecl {
    const out = try arena.alloc(ast.FnDecl, support.len);
    for (support, out) |sf, *o| o.* = try exportedFn(arena, env, hosts, fns, sf);
    const reached = try hostCells.hostSupport(env, fns, try std.mem.concat(arena, ast.FnDecl, &.{ &.{head}, out }));
    return std.mem.concat(arena, ast.FnDecl, &.{ out, reached });
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

/// The key under which a module's type-declaration map holds a type it
/// declares without `pub`: `"\x01" ++ name`. No import spells it; only a
/// comptime module carrying a function of that module reads it
/// (`block_eval.findDeclared`, 01-compiler/14 — emilia's `classRules` builds
/// its private `Placed`).
pub const private_type_prefix = "\x01";

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

/// Decision 356 — the build value of each module-level `val` a decorator
/// annotates whose initializer is `comptime` (`Reflection.declaredValues`):
/// what a template body's catalogue answer lifts as the entry's `value`.
/// Recorded for every module, the last one included (it exports nothing).
fn recordDeclaredValues(path: []const u8, decls: []const ast.DeclKind, succ_env: *const envMod.Env) !void {
    var env = succ_env.*;
    const r = env.reflection orelse return;
    const io = (env.templateEval orelse return).io;
    for (decls) |d| {
        if (d != .val) continue;
        const v = d.val;
        if (v.value.* != .comptime_) continue;
        const annotated = for (v.annotations) |a| {
            if (!a.is_builtin) break true;
        } else false;
        if (!annotated) continue;
        const json = (try blockEval.exportedBuildValue(&env, io, v)) orelse continue;
        try r.declaredValues.put(r.arena, try envMod.declIdentity(r.arena, path, v.name), try r.arena.dupe(u8, json));
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
    // that text resolves in this module wherever it is expanded. Decisions
    // 384, 385 — so does a module whose decorator hands a member on, or whose
    // annotation wrote an `@Expr` meta field (`written_names.sharesPrivates`).
    const declares_template = try sharesPrivates(arena, decls, env);
    // Decision 384 — a member a library decorator handed on names its
    // library's types under this module's checker-only aliases
    // (`written_names.typeImports`); an importer re-registers the type's
    // declaration in its own scope, where no alias is bound, so the exported
    // declaration names each type by its declared name (as a source import
    // does), resolved through the module's import scope
    // (`addImportedTypeScope`).
    try written_names.eraseTypeAliases(arena, decls, &env.typeAliases);
    // Decision 341 — what this module exports for a comptime module carries
    // its std calls renamed to the std functions it carries with it.
    var hosts = try hostCells.Writer.init(env, decls);
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
            // 01-compiler/14 step 8 — a `val` known at build exports its
            // value: an importer's template hole naming it reads it at build
            // (decision 355, `block_eval.exportedBuildValue`).
            if (b.decl == .val) if (env.templateEval) |ctx| if (try blockEval.exportedBuildValue(env, ctx.io, b.decl.val)) |json| {
                try decoratorRegistry.put(try buildValueKey(arena, path, b.name), conflictCarrier(json));
            };
            // `pub` nominal type declarations export their full AST decl too, so
            // the importing module can re-register the `TypeDef` (implements /
            // contextBase / fields) — not just the constructor value. Mirrors
            // the `from "std"` type-export path (`stdModuleTypes`), which is also
            // `pub`-only. Non-pub types still export their constructor (above)
            // for value use, but carry no cross-module `TypeDef`.
            switch (b.decl) {
                // A private one under `private_type_prefix`, which no import
                // spells: a function this module exports constructs it, and
                // a comptime module of an importer carries the function
                // (`block_eval.findDeclared`).
                .type_ => |t| if (t.isPub) try typeDecls.put(b.name, b.decl) else try typeDecls.put(try std.mem.concat(arena, u8, &.{ private_type_prefix, b.name }), b.decl),
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
                    // Decision 637 — with the templates its body calls at
                    // build lowered (`infer.lowerBuildTemplateCalls`).
                    if (rt.isTemplateReturnType()) {
                        const lowered = (try infer.lowerBuildTemplateCalls(env, f)).decl;
                        try templateRegistry.put(try comptimeRegistryKey(arena, path, b.name), try hosts.rewriteAs(lowered, try templateEval.relabelTupleReads(arena, &env.tupleLabelReads, lowered)));
                    }
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
                        // Decision 551 — a catalogue default travels as the
                        // query a call leaving it out is given: the key of its
                        // resolution here (`noteDefaultQueries`).
                        if (typeinfoAll.isCatalogueDefault(p.*)) {
                            const key = try reflectionMod.Reflection.defaultKey(arena, path, f.name, p.name);
                            p.default = (try typeinfoAll.defaultQueryCall(arena, key, d.getLoc())).*;
                            continue;
                        }
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
                    // Decision 371 — a decorator travels with its `same` calls
                    // lowered (`decorator_same.zig`), its own and those of the
                    // functions of this module it reaches.
                    const head = try exportedFn(arena, env, &hosts, &fns, f);
                    try decoratorRegistry.put(try comptimeRegistryKey(arena, path, b.name), head);
                    // The functions its body reaches travel with it
                    // (`decoratorSupportKey`) — its module's and the ones the
                    // module imports: the importer's module declares none of
                    // them, and the decorator module needs them; decision
                    // 341's host and std functions after them.
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    const carried = try exportedSupport(arena, env, &hosts, &fns, head, support.fns);
                    for (carried, 0..) |sf, i| try decoratorRegistry.put(try decoratorSupportKey(arena, path, b.name, i), sf);
                    if (support.conflict) |c| try decoratorRegistry.put(try decoratorConflictKey(arena, path, b.name), conflictCarrier(c));
                } else if (isTemplateFn(f)) {
                    // A template carries the functions its body reaches the
                    // same way (decision 331, calls included): the template
                    // module is built where the template is EXPANDED, whose
                    // module declares none of them. Same keys as a
                    // decorator's — a template is never one.
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    const relabelled = try arena.alloc(ast.FnDecl, support.fns.len);
                    for (support.fns, relabelled) |sf, *r| {
                        const rl = try relabelLocal(arena, env, &fns, sf);
                        const own = if (fns.get(sf.name)) |g| g.body.ptr == sf.body.ptr else false;
                        r.* = if (own) try hosts.rewriteAs(sf, rl) else rl;
                    }
                    const head = templateRegistry.get(try comptimeRegistryKey(arena, path, b.name)) orelse f;
                    // Decision 637 — the templates its body calls at build,
                    // and what they reach, travel with it.
                    const built = (try infer.lowerBuildTemplateCalls(env, f)).support;
                    const carried = try std.mem.concat(arena, ast.FnDecl, &.{ relabelled, built, try hostCells.hostSupport(env, &fns, try std.mem.concat(arena, ast.FnDecl, &.{ &.{head}, relabelled })) });
                    for (carried, 0..) |sf, i| try decoratorRegistry.put(try decoratorSupportKey(arena, path, b.name, i), sf);
                    if (support.conflict) |c| try decoratorRegistry.put(try decoratorConflictKey(arena, path, b.name), conflictCarrier(c));
                } else if (infer.isCarriableFn(f)) {
                    // A plain `pub fn` carries itself and what it reaches
                    // (`decoratorClosureKey`), so a decorator of a module
                    // that imports it can call it: entry 0 is the function,
                    // the rest are the functions of this module (and of its
                    // own imports) its body reaches.
                    const head = try exportedFn(arena, env, &hosts, &fns, f);
                    try decoratorRegistry.put(try decoratorClosureKey(arena, path, b.name, 0), head);
                    const support = try infer.decoratorSupport(arena, fns, &env.importedFnSupport, f);
                    if (support.conflict == null) {
                        const carried = try exportedSupport(arena, env, &hosts, &fns, head, support.fns);
                        for (carried, 1..) |sf, i| try decoratorRegistry.put(try decoratorClosureKey(arena, path, b.name, i), sf);
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
    // Decision 289 — the module's default function, for `default_fn.callableNamespaces`.
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
/// The prelude as the checker infers it: its tests out, and its primitive
/// types (`pub type i32 implement Signed { … }`, decision 617 (1)) out — a
/// primitive is the checker's own type, never a type of the environment; its
/// contract is read from the text where a method is resolved
/// (`prelude_cache.primitiveContract`).
fn preludeForInference(program: ast.Program, alloc: std.mem.Allocator) !ast.Program {
    // Decisions 617 (3), 496 — the members a width declares itself, as the
    // free functions a call of one is written as (`__i32_abs`).
    const with_members = try prelude_cache.withWidthMembers(alloc, program);
    var kept: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (with_members.decls) |decl| {
        if (decl == .@"test") continue;
        if (decl == .type_ and decl.type_.isPrimitive) continue;
        try kept.append(alloc, decl);
    }
    var out = with_members;
    out.decls = try kept.toOwnedSlice(alloc);
    return out;
}

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
/// Whether `mod`'s bodyless declarations are the compiler's (`Env.compilerBodies`):
/// std's `types.bp`, whose derived types the compiler
/// answers (`comptime/derived_types.zig`) until step B-140 writes them in
/// botopink.
fn declaresCompilerBodies(mod: Module) bool {
    return mod.std_member and (std.mem.eql(u8, mod.path, "types") or std.mem.eql(u8, mod.path, "std/types"));
}

/// Decision 575 (6) — std's `external.bp` (`Implementation`, the enums its
/// cells take, and the annotation `external`) into `env`, once: before the
/// prelude is inferred, so `primitives.bp`, the reflection cluster (whose
/// `Decl.implement` takes an `Implementation`) and every std module write
/// `#[external(…)]` with no import. Parsed into `env.arena`: the decorator
/// table keeps `external`'s declaration.
pub fn registerExternalPrelude(env: *Env) anyerror!void {
    if (env.lookupTypeDef("Implementation") != null) return;
    const prelude = @import("std_prelude");
    const program = try parseEmbeddedStd(env.arena, "external", prelude.external);
    const was_std = env.inStd;
    env.inStd = true;
    defer env.inStd = was_std;
    _ = try infer.inferProgram(env, program);
    // The enums' variants are reached through their type — `.Erlang(…)`
    // where an `Implementation` is expected, `Implementation.Erlang(…)` — and
    // never by a bare name: a program's own `Node` or `Delay` is its own.
    for (program.decls) |d| if (d == .type_ and !d.type_.isRecord()) for (d.type_.variants()) |v| {
        _ = env.bindings.remove(v.name);
        _ = env.ctorParams.remove(v.name);
        if (env.variantClaims.getPtr(v.name)) |claims| {
            var kept: std.ArrayListUnmanaged([]const u8) = .empty;
            for (claims.*) |c| if (!std.mem.eql(u8, c, d.type_.name)) try kept.append(env.arena, c);
            if (kept.items.len == 0) _ = env.variantClaims.remove(v.name) else claims.* = kept.items;
        }
    };
}

fn registerReflectionPrelude(env: *Env) anyerror!void {
    try registerExternalPrelude(env);
    // The cluster's bodyless members are the compiler's (a declaration
    // file's, `Env.compilerBodies`).
    const was_decl = env.compilerBodies;
    env.compilerBodies = true;
    defer env.compilerBodies = was_decl;
    const alloc = env.arena;
    // The tokens are scratch: the tree holds none (144 B-127).
    var token_scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer token_scratch.deinit();
    var lx = Lexer.init(decl_reflection_src);
    const tokens = try lx.scanAll(token_scratch.allocator());
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);
    _ = try infer.inferProgram(env, program);
}

/// Decision 539 (6) — the `pub behavior`s of `primitives.bp`'s compiler section a compiler rule
/// reads by name. Every other `pub behavior` declared there is **ambient**
/// (`isAmbientBehavior`): a program names it with no import, as a type — a
/// parameter's included, with its arguments (`fn f(m: Index<i32, i32>)`) — and
/// in an `implement` clause, which is checked against the declaration. Today
/// that leaves `Display`, `Closeable`, `Index` and `Slice`; a plain behavior
/// added to `primitives.bp`'s compiler section joins them with no compiler change.
pub const rule_read_behaviors = [_][]const u8{
    // The effect wrappers, written `Async<…>` / `Iter<…>` / … under their
    // body markers (`comptime/effect_chain.zig`).
    "Async",
    "Iter",
    "AsyncIter",
    // The component behavior a type implements (decisions 809 (1), 826 (3)).
    "Composable",
    // Markers whose `implement` a rule of `infer.zig` reads:
    // `implementsAnnotation` and `decorator_type_name`.
    "Annotation",
    "Decorator",
};

/// True when `b`, a behavior of `primitives.bp`'s compiler section, is ambient: public, and read
/// by no compiler rule (`rule_read_behaviors`).
/// Decision 831 (1), (2) — the identities a type implementing behavior `b`,
/// declared in module `path`, carries: `b`'s own, then through `extends` each
/// parent's, a parent resolved in `path`'s own declarations first, then among
/// the ambient behaviors, then as the one module of the program declaring a
/// behavior of that name. `depth` bounds a cyclic chain.
fn appendBehaviorMarks(
    env: *envMod.Env,
    registry: *std.StringHashMap(std.StringHashMap(ast.DeclKind)),
    path: []const u8,
    b: ast.BehaviorDecl,
    out: *std.ArrayListUnmanaged([]const u8),
    depth: usize,
) !void {
    const id = try ast.behaviorIdentity(env.arena, path, b.name);
    for (out.items) |seen| if (std.mem.eql(u8, seen, id)) return;
    try out.append(env.arena, id);
    if (depth >= 16) return;
    for (b.extends) |parent| {
        if (registry.get(path)) |decls| if (decls.get(parent)) |d| if (d == .behavior) {
            try appendBehaviorMarks(env, registry, path, d.behavior, out, depth + 1);
            continue;
        };
        if (env.ambientBehaviorDecls.get(parent)) |a| {
            try appendBehaviorMarks(env, registry, ast.ambient_behavior_module, a, out, depth + 1);
            continue;
        }
        var only: ?struct { path: []const u8, decl: ast.BehaviorDecl } = null;
        var count: usize = 0;
        var it = registry.iterator();
        while (it.next()) |e| if (e.value_ptr.get(parent)) |d| if (d == .behavior) {
            count += 1;
            only = .{ .path = e.key_ptr.*, .decl = d.behavior };
        };
        if (count == 1) try appendBehaviorMarks(env, registry, only.?.path, only.?.decl, out, depth + 1);
    }
}

pub fn isAmbientBehavior(b: ast.BehaviorDecl) bool {
    if (!b.isPub) return false;
    for (rule_read_behaviors) |name| if (std.mem.eql(u8, b.name, name)) return false;
    return true;
}

test "ambient behaviors: primitives.bp's public behaviors no rule reads (decision 539 (6))" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();
    var lx = Lexer.init(@import("std_prelude").builtins);
    var p = Parser.init(try lx.scanAll(arena));
    const program = try p.parse(arena);
    var ambient: std.ArrayListUnmanaged([]const u8) = .empty;
    var declared: std.StringHashMapUnmanaged(void) = .empty;
    for (program.decls) |d| if (d == .behavior) {
        try declared.put(arena, d.behavior.name, {});
        if (isAmbientBehavior(d.behavior)) try ambient.append(arena, d.behavior.name);
    };
    const want = [_][]const u8{ "Display", "Closeable", "Index", "Slice" };
    try std.testing.expectEqual(want.len, ambient.items.len);
    for (want, ambient.items) |w, a| try std.testing.expectEqualStrings(w, a);
    // A name the list keeps out that primitives.bp no longer declares is stale.
    for (rule_read_behaviors) |name| try std.testing.expect(declared.contains(name));
}

/// Decision 252 — every builtin's declaration into `env.builtinDecls`: each
/// top-level `declare fn` of `primitives.bp`'s compiler section and std's `print` / `panic`
/// (`std_calls.declarations`, decision 606 (2)), and each
/// static `declare fn` of a type there (`TypeInfo.all`). Parsed into
/// `env.arena`, which the declarations' slices outlive with the env.
fn registerBuiltinDecls(env: *Env) anyerror!void {
    const prelude = @import("std_prelude");
    // Decision 606 (2) — `print` and `panic` are `io/terminal.bp`'s and
    // `failure.bp`'s: their declarations are read from those modules.
    for (try std_calls.declarations(env.arena)) |f| try env.builtinDecls.put(f.name, .{
        .genericParams = f.genericParams,
        .params = f.params,
        .returnType = f.returnType,
    });
    for ([_][]const u8{prelude.builtins}, [_][]const u8{"primitives"}) |src, name| {
        const program = try parseEmbeddedStd(env.arena, name, src);
        for (program.decls) |decl| switch (decl) {
            .@"fn" => |f| if (f.isDeclare) try env.builtinDecls.put(f.name, .{
                .genericParams = f.genericParams,
                .params = f.params,
                .returnType = f.returnType,
            }),
            // Decision 539 (6) — the ambient behaviors a program names with no
            // import (`Env.ambientBehaviorDecls`).
            .behavior => |b| if (isAmbientBehavior(b))
                try env.ambientBehaviorDecls.put(env.arena, b.name, b)
            else if (b.isPub)
                try env.ruleReadBehaviorDecls.put(env.arena, b.name, b),
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

/// Decision 565 — a private bodied `fn` of `primitives.bp` (a `String`
/// method's wasm body, 164 s3) is the prelude's own: inferred with the prelude,
/// then taken out of the global environment it was flattened into, so a program
/// neither calls it nor collides with it. The wasm codegen reads it from the
/// prelude's parse (`prelude_cache.freeFn`) when a `fn:` cell names it.
fn hidePreludeBodies(env: *Env, program: ast.Program) void {
    for (program.decls) |d| {
        if (d != .@"fn") continue;
        const f = d.@"fn";
        if (f.isPub or f.isDeclare or f.body.len == 0) continue;
        _ = env.bindings.remove(f.name);
        _ = env.fnParams.remove(f.name);
        _ = env.fnDecls.remove(f.name);
        _ = env.ownDecls.remove(f.name);
    }
}

pub fn registerStdlib(env: *Env, gpa: std.mem.Allocator) anyerror!void {
    _ = gpa; // stdlib sources are now parsed into `env.arena` (see below)
    const prelude = @import("std_prelude");
    const sources = [_][]const u8{
        prelude.primitives,
    };
    // The prelude is std's (decision 445): its `std:` cells are std's to write.
    env.inStd = true;
    // Decision 575 (6) — `#[external(…)]` names `Implementation`.
    try registerExternalPrelude(env);
    // A bodied `fn` of the prelude (164 s3's wasm bodies, decision 565) reads
    // `true` / `false` as any program does: bound before the prelude is inferred.
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    for (sources) |src| {
        // Parse into `env.arena` (not a scratch arena): the interface decls for
        // primitive associated fns (`Array`, …) are retained in
        // `env.assocInterfaceDecls` and emitted by codegen, so they must outlive
        // this call.
        const alloc = env.arena;

        const parsed = try parseEmbeddedStd(alloc, "primitives", src);
        // Decision 800 (3) — the primitive types' own `implement` clauses,
        // which `preludeForInference` leaves out of the inference below.
        try infer.checkProgramSignatures(env, parsed);
        const program = try preludeForInference(parsed, alloc);
        // A prelude behavior's members keep `primitives.bp`'s locations
        // wherever a backend copies them (`ast.BehaviorMethod.from_prelude`).
        for (program.decls) |d| if (d == .behavior) for (d.behavior.methods) |*m| {
            m.from_prelude = true;
        };
        _ = try infer.inferProgram(env, program);
        hidePreludeBodies(env, program);
    }
    env.inStd = false;

    // The `@Decl` reflection cluster (annotation processors): register these
    // types into the global env so a decorator body type-checks — `decl.kind` /
    // `decl.name` / `decl.fields` / … and `decl.fail(…)`, plus the `Field` /
    // `Method` / `Param` / `Annotation` shapes it reads. This mirrors the surface
    // documented in `libs/std/src/primitives.bp`'s compiler section (kept there for tooling); it is
    // parsed from a dedicated minimal source here because the full `primitives.bp`'s compiler section
    // is the tooling/`@Expr` surface and is not consumed as a standalone program.
    try registerReflectionPrelude(env);
    // The internal sources below declare the compiler's own bodyless members.
    env.compilerBodies = true;

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
    // `@Iter` / `@AsyncIter`.
    {
        const alloc = env.arena;
        var lx = Lexer.init(yield_step_src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }

    // `panic`'s declaration (`failure.bp`, decision 606 (2)) is the `FnDecl` a
    // call's trailing default is read from (`expandTrailingDefaults` injects
    // `"panic"` into `panic()` before dispatch).
    env.compilerBodies = false;
    for (try std_calls.declarations(env.arena)) |f| try env.stdlibFnDecls.put(f.name, f);

    try registerBuiltinDecls(env);

    // A std module may import another (`import {json} from "std"`): each is
    // inferred after the ones it imports, and sees their exports, types and
    // functions exactly as a program's module does.
    // Decision 341 — each std module's declarations, for the functions a
    // comptime module carries (`host_cells.buildStdCarried`, below).
    var carried_modules: std.ArrayListUnmanaged(hostCells.StdModule) = .empty;
    for (try stdModuleOrder(env.arena)) |spm_index| {
        const spm = std_pkg_modules[spm_index];
        const mod_name = spm.path["std/".len..];
        // Each std module is inferred in a scratch env (so its fn names don't
        // flatten into — or collide across — the global env), sharing `env`'s
        // arena so the resulting types outlive the scratch maps.
        var env2 = Env.init(env.arena);
        // An embedded std module is std's (decision 445).
        env2.inStd = true;
        // `types.bp`'s derived types: their bodies are the compiler's
        // (`comptime/derived_types.zig`) until step B-140 writes them in
        // botopink, so `declare-without-implementation` is not their rule.
        env2.compilerBodies = std.mem.eql(u8, mod_name, "types");
        defer env2.deinit();
        try env2.registerBuiltins();
        env2.ambientBehaviorDecls = try env.ambientBehaviorDecls.clone(env.arena);
        env2.ruleReadBehaviorDecls = try env.ruleReadBehaviorDecls.clone(env.arena);
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
            var ait = env.stdModuleAllFns.iterator();
            while (ait.next()) |e| try env2.stdModuleAllFns.put(e.key_ptr.*, e.value_ptr.*);
        }
        for (sources) |src| {
            // The tokens are scratch: the tree holds none (144 B-127).
            var token_scratch = std.heap.ArenaAllocator.init(std.heap.page_allocator);
            defer token_scratch.deinit();
            var lx = Lexer.init(src);
            const tokens = try lx.scanAll(token_scratch.allocator());
            var p = Parser.init(tokens);
            const program = try preludeForInference(try p.parse(env.arena), env.arena);
            _ = try infer.inferProgram(&env2, program);
        }
        // Decision 330 (7): a std type's associated types are top-level types
        // of the module (`Type.Field` is `Type__Field`).
        const parsed_std = try std_calls.expand(env.arena, try embeddedStdProgram(env.arena, try stripTestDecls(try parseEmbeddedStd(env.arena, spm.path, spm.source), env.arena)), mod_name);
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
        // A carried function runs in a comptime module as every backend runs
        // it: its `@Result` / `@Option` method calls and each `return v` /
        // `throw e` of a `@Result` body written as the builtins its module's
        // inference recorded (`block_eval.withResultMethods`) — without them a
        // `throw` of std's escaped as an Erlang throw (`failure.attempt` at
        // build, decision 543).
        const carried_decls = try env.arena.dupe(ast.DeclKind, program.decls);
        for (carried_decls) |*d| if (d.* == .@"fn") {
            d.* = .{ .@"fn" = try blockEval.withResultMethods(&env2, d.@"fn") };
        };
        try carried_modules.append(env.arena, .{ .name = mod_name, .decls = carried_decls });

        // Collect the module's public type declarations so `import {…} from
        // "std"` can register them into the importing env (type export —
        // enables case patterns / annotations over e.g. `Order`).
        {
            var type_decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
            // Decision 576 (13) — a type this module exports that names an
            // alias it imports (`types.bp`'s `annotations: DeclAnnotation[]`,
            // `import {compiler.DeclAnnotation};`) names the alias's target:
            // an importer of the type need not import the alias.
            var imported_aliases: std.ArrayListUnmanaged(ast.TypeAliasDecl) = .empty;
            for (program.decls) |decl| if (decl == .use) for (decl.use.imports) |imp| {
                if (!imp.isQualified()) continue;
                const decls = env.stdModuleTypes.get(try imp.prefixPath(env.arena)) orelse continue;
                for (decls) |d| if (d == .typeAlias and std.mem.eql(u8, d.typeAlias.name, imp.leaf()) and d.typeAlias.target == .named)
                    try imported_aliases.append(env.arena, d.typeAlias);
            };
            for (program.decls) |decl| {
                const is_pub_type = switch (decl) {
                    .type_ => |t| t.isPub,
                    .typeAlias => |a| a.isPub,
                    else => false,
                };
                if (!is_pub_type) continue;
                if (decl == .type_ and imported_aliases.items.len > 0) {
                    var t = decl.type_;
                    for (imported_aliases.items) |a| t = try typeIdentity.renameTypeRefs(env.arena, t, a.name, a.target.named);
                    try type_decls.append(env.arena, .{ .type_ = t });
                } else try type_decls.append(env.arena, decl);
            }
            if (type_decls.items.len > 0) {
                try env.stdModuleTypes.put(mod_name, try type_decls.toOwnedSlice(env.arena));
            }
        }

        // STD-001 — collect every `pub fn` of this std module so a call's
        // host declarations (`infer.zig` `stdHostsOf`) are read without
        // re-parsing. The FnDecl slice points into `env.arena` (the
        // shared parse arena), so callers see stable references.
        {
            var fn_decls: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
            var all_decls: std.ArrayListUnmanaged(ast.FnDecl) = .empty;
            for (program.decls) |decl| {
                switch (decl) {
                    .@"fn" => |f| {
                        if (f.isPub) try fn_decls.append(env.arena, f);
                        try all_decls.append(env.arena, f);
                    },
                    else => {},
                }
            }
            if (fn_decls.items.len > 0) {
                try env.stdModuleFns.put(mod_name, try fn_decls.toOwnedSlice(env.arena));
            }
            // Decision 518 (4) — every function of the module, private ones
            // too, so STD-001 follows a call through the module's own bodies
            // to the host cell it reaches (`infer.zig` `stdUnsupportedReach`).
            if (all_decls.items.len > 0) {
                try env.stdModuleAllFns.put(mod_name, try all_decls.toOwnedSlice(env.arena));
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
    env.stdCarried = try hostCells.buildStdCarried(env.arena, carried_modules.items, &env.stdModules);
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
        return .{ .comptime_script = null };
    }

    var result = try evalMod.evaluate(allocator, entries.items);
    // The listing is all that leaves the fold: a folded value reaches the
    // backends as the literal the analysis spliced (`srcRewrites`, decision 798).
    var it = result.values.iterator();
    while (it.next()) |kv| {
        allocator.free(kv.key_ptr.*);
        allocator.free(kv.value_ptr.*);
    }
    result.values.deinit();
    return .{ .comptime_script = result.script };
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
/// ordinary comptime entries (`comptime_script` stays empty).
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
/// Returns a `ComptimeSession` whose outputs always have `.ok.comptime_script = null`. Caller must call `session.deinit(allocator)`.
/// B-139, decision 677 — std's `primitives` module is the prelude
/// (`registerStdlib`): registered into every environment before any module,
/// so std's own build, which holds every module under its `src/`, checks it
/// there. As a module it holds nothing more: its source is not analysed a
/// second time (its behaviors would redeclare themselves, its compiler
/// section is the compiler's).
fn withPreludeModuleEmpty(arena: std.mem.Allocator, modules: []const Module) ![]const Module {
    for (modules, 0..) |m, i| {
        if (!isPreludeModule(m)) continue;
        const out = try arena.dupe(Module, modules);
        out[i].source = "";
        return out;
    }
    return modules;
}

fn isPreludeModule(m: Module) bool {
    return m.std_member and m.package.len == 0 and std.mem.eql(u8, m.path, "primitives");
}

pub fn compileTypesOnly(
    allocator: std.mem.Allocator,
    modules_in: []const Module,
    eval_ctx: ?envMod.TemplateEvalCtx,
) !ComptimeSession {
    // Decision 787 — the loads of this compile, held for it alone.
    const saved_load = try loadMod.enter();
    defer loadMod.leave(saved_load);
    var session = ComptimeSession{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .outputs = .empty,
    };
    errdefer session.arena.deinit();

    const arena_alloc = session.arena.allocator();
    const modules = try withPreludeModuleEmpty(arena_alloc, modules_in);
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
    const all_modules = try orderReaders(arena_alloc, try expandStdImports(arena_alloc, modules, null), &reflection, &reader_refusals, null);
    const tree = try arena_alloc.create(mod_tree.Tree);
    tree.* = try mod_tree.build(arena_alloc, all_modules);
    reflection.modTree = tree;
    try recordSrcPaths(arena_alloc, &reflection, all_modules);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        if (reader_refusals.get(idx)) |te| {
            try session.outputs.append(allocator, .{ .name = name, .src = mod.source, .srcPath = mod.srcPath, .outcome = .{ .typeError = te } });
            try reflection.failedModules.put(arena_alloc, mod.path, {});
            continue;
        }
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, eval_ctx, true, &reflection);

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
                    // Decision 788 — a block's decorator named `comptime`.
                    .outcome = .{ .typeError = try te.blockNamed(arena_alloc, false) },
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
                    try infer.taskLowerings(&succ.env, &instance_lowerings);
                    try infer.unionValueLowerings(&succ.env, arena_alloc, &instance_lowerings);
                    try infer.textValueLowerings(&succ.env, arena_alloc, &instance_lowerings);
                }
                try recordDeclaredValues(mod.path, succ.program.decls, &succ.env);
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
                    if (b.decl == .@"fn" and !try hooksMod.isExpandedFn(arena_alloc, b.decl.@"fn")) try fn_decls.put(b.name, try syntax_param.eraseFn(arena_alloc, b.decl.@"fn", infer.isDecoratorParams(b.decl.@"fn".params)));
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
                // Lowering is best-effort here: a degraded module (decorator
                // `@emit` that couldn't type-check standalone, surfaced for the
                // LSP via the types-only fallback) may carry incomplete lowering
                // maps. The LSP reads `bindings`/`custom_ast`, not `transformed`,
                // so on a transform error we keep the untransformed program
                // rather than blanking the whole session.
                const transformed = blk_t: {
                    const t0 = transform.transform(
                        arena_alloc,
                        try syntax_param.eraseProgram(arena_alloc, try withoutExpandedFns(arena_alloc, program_for_transform), infer.isDecoratorParams),
                        fn_decls,
                        std.StringHashMap([]const ast.TypedExpr).init(arena_alloc),
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
                        &succ.env.localCalleeCalls,
                        &succ.env.embedCallArgs,
                        .backends,
                    ) catch break :blk_t program_for_transform;
                    const t = type_token.apply(arena_alloc, t0, &succ.env) catch t0;
                    const hygienic = withTemplateHygiene(arena_alloc, t, &succ.env, sharesPrivates(arena_alloc, program_for_transform.decls, &succ.env) catch true, program_for_transform.decls) catch break :blk_t t;
                    const with_assoc = withUsedAssocInterfaces(arena_alloc, hygienic, &succ.env) catch break :blk_t hygienic;
                    const with_enums = withSynthesisedEnumDecls(arena_alloc, with_assoc, &succ.env) catch with_assoc;
                    const with_src = withSourceRecordDecl(arena_alloc, withSourceLocationDecl(arena_alloc, with_enums, &succ.env) catch with_enums, &succ.env) catch with_enums;
                    const with_step0 = withYieldStepDecl(arena_alloc, with_src, &succ.env) catch with_src;
                    const with_step = with_step0;
                    const with_asset = withEmbedParams(arena_alloc, withAssetDecl(arena_alloc, with_step, &succ.env) catch with_step, &succ.env) catch with_step;
                    const erased = alias_erase.erase(arena_alloc, with_asset, &succ.env.typeAliases) catch with_asset;
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
                        .transformed = transformed,
                        .type_ids = type_ids,
                        .dispatch_rewrites = dispatch_rewrites,
                        .js_method_renames = js_method_renames,
                        .instance_lowerings = instance_lowerings,
                        .custom_ast = try collectCustomAst(arena_alloc, &succ.env),
                        .comptime_traces = succ.env.comptimeTraces.items,
                        .build_output = succ.env.buildOutput.items,
                        .template_expansions = succ.env.templateExpansions.count(),
                        .warnings = succ.env.warnings.items,
                        .sync_fns = succ.env.syncFns,
                        .sync_calls = succ.env.syncCalls,
                        .std_host_calls = succ.env.stdHostCalls.items,
                    } },
                });
            },
        }
        if (session.outputs.items[session.outputs.items.len - 1].outcome != .ok) try reflection.failedModules.put(arena_alloc, mod.path, {});
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
) !ComptimeSession {
    return compileWith(allocator, modules, io, build_root, null);
}

/// `compile` reading and writing the code cache's level B through `store`
/// (144 B-60): a dependency whose entry reads back is not analysed, one
/// analysed is handed to the store as an entry (`comptime/level_b.zig`).
pub fn compileWith(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    build_root: ?[]const u8,
    store: ?*levelB.Store,
) !ComptimeSession {
    // Decisions 787, 792 — the loaded files of this compile, and the ones a
    // `run()` reaches: each joins the program as a package of its own, and
    // the modules are compiled again with them (`loadMod.packageModules`),
    // until a compile reaches no package it lacks.
    const saved_load = try loadMod.enter();
    defer loadMod.leave(saved_load);
    var current = modules;
    var grown: std.ArrayListUnmanaged(Module) = .empty;
    defer grown.deinit(allocator);
    const extra = try std.heap.page_allocator.create(std.heap.ArenaAllocator);
    extra.* = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var extra_owned = true;
    defer if (extra_owned) {
        extra.deinit();
        std.heap.page_allocator.destroy(extra);
    };
    while (true) {
        loadMod.clearRuns();
        var session = try compileModules(allocator, current, io, build_root, store);
        const lacking = try lackingRuns(extra.allocator(), current);
        if (lacking.len == 0) {
            if (grown.items.len > 0) {
                session.loaded = extra;
                extra_owned = false;
            }
            return session;
        }
        session.deinit(allocator);
        // The packages join after every dependency, before the root package's
        // modules: a loaded package depends on std and on the caller's
        // dependencies alone.
        var targets: ?@import("./module.zig").Targets = null;
        for (current) |m| if (m.package.len == 0) {
            targets = m.targets;
            break;
        };
        var next: std.ArrayListUnmanaged(Module) = .empty;
        var placed = false;
        for (current) |m| {
            if (!placed and m.package.len == 0) {
                for (lacking) |e| try next.appendSlice(allocator, try loadMod.packageModules(extra.allocator(), e, targets));
                placed = true;
            }
            try next.append(allocator, m);
        }
        if (!placed) for (lacking) |e| try next.appendSlice(allocator, try loadMod.packageModules(extra.allocator(), e, targets));
        grown.deinit(allocator);
        grown = next;
        current = grown.items;
    }
}

/// The entries of the files a `run()` of the last compile reached whose
/// package is not among `modules`.
fn lackingRuns(arena: std.mem.Allocator, modules: []const Module) ![]const loadMod.Entry {
    var out: std.ArrayListUnmanaged(loadMod.Entry) = .empty;
    for (loadMod.runs()) |path| {
        const pkg = try loadMod.packageName(arena, path);
        const present = for (modules) |m| {
            if (std.mem.eql(u8, m.package, pkg)) break true;
        } else false;
        if (present) continue;
        const e = loadMod.entryOf(path) orelse continue;
        try out.append(arena, e);
    }
    return out.items;
}

fn compileModules(
    allocator: std.mem.Allocator,
    modules: []const Module,
    io: std.Io,
    build_root: ?[]const u8,
    store: ?*levelB.Store,
) !ComptimeSession {
    if (store) |st| st.stats = .{};
    // Decision 780 — a `compiler.load` of this compile shares its dependencies.
    const saved_build = loadMod.build_modules;
    loadMod.build_modules = modules;
    defer loadMod.build_modules = saved_build;
    // Decision 353 — a template body's `@TypeInfo.all` answers for the whole
    // program, every module's decorators applied. A session answers it from
    // the catalogue as it stands when the template is expanded; when a module
    // analysed later added an entry to an answer (`staleTemplateRead`), the
    // modules are compiled again with the first session's complete catalogue
    // as the oracle the answers are read from.
    var first = try compileOnce(allocator, modules, io, build_root, null, store);
    if (try staleTemplateRead(first.session.arena.allocator(), first.reflection) == null) return first.session;
    // The second session counts afresh; what the first staged stays staged
    // (a stored group's analysis reads no catalogue).
    if (store) |st| st.stats = .{};
    var second = compileOnce(allocator, modules, io, build_root, first.reflection, store) catch |err| {
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
        const now = switch (try typeinfoAll.templateAnswerText(arena, reflection, read.query, read.loc, read.reader)) {
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
    const msg = if (read.reader != null)
        try std.fmt.allocPrint(arena, "{s}: the call of `{s}` here takes `@TypeInfo.all(with: {s})` as its default, and the catalogue it answers changed after the call was compiled", .{ diagnostics.typeinfo_all_template_unstable, read.callee, read.query.label })
    else
        try std.fmt.allocPrint(arena, "{s}: the template expanded here reads `@TypeInfo.all(with: {s})`, and the declarations its answer builds change that catalogue", .{ diagnostics.typeinfo_all_template_unstable, read.query.label });
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
    modules_in: []const Module,
    io: std.Io,
    build_root: ?[]const u8,
    oracle: ?*const reflectionMod.Reflection,
    store: ?*levelB.Store,
) !CompiledOnce {
    var session = ComptimeSession{
        .arena = std.heap.ArenaAllocator.init(allocator),
        .outputs = .empty,
    };
    errdefer session.arena.deinit();

    const arena_alloc = session.arena.allocator();
    const modules = try withPreludeModuleEmpty(arena_alloc, modules_in);
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
    //
    // The code cache's level B (144 B-60): every dependency package's entry is
    // looked up before the pre-passes, std's once they named the std modules
    // the build needs; a hit is parsed by none of them.
    const regs: levelB.Registries = .{
        .registry = &registry,
        .type_decls = &type_decl_registry,
        .templates = &template_registry,
        .decorators = &decorator_registry,
        .extensions = &extension_registry,
        .dsl = &default_dsl,
        .reflection = reflection,
    };
    var lb_session: levelB.Session = undefined;
    const lb: ?*levelB.Session = if (store) |st| blk: {
        lb_session = try levelB.Session.init(arena_alloc, allocator, st);
        session.level_b_code = lb_session.code;
        break :blk &lb_session;
    } else null;
    if (lb) |l| try l.lookup(modules, .packages);
    const expanded = try expandStdImports(arena_alloc, modules, lb);
    if (lb) |l| try l.lookup(expanded, .std);
    var reader_refusals: std.AutoHashMapUnmanaged(usize, validation.TypeError) = .empty;
    const all_modules = try orderReaders(arena_alloc, expanded, reflection, &reader_refusals, lb);
    const tree = try arena_alloc.create(mod_tree.Tree);
    tree.* = try mod_tree.buildWith(arena_alloc, all_modules, if (lb) |l| try l.treeKnown(all_modules) else &.{});
    reflection.modTree = tree;
    try recordSrcPaths(arena_alloc, reflection, all_modules);
    if (lb) |l| l.plan(all_modules);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        if (lb) |l| if (l.hitOf(mod)) |h| {
            // The driver's own strings, as a live output carries them: they
            // outlive the session (a decoded copy is the session arena's).
            var out = h.output;
            out.name = name;
            out.src = mod.source;
            out.srcPath = mod.srcPath;
            try session.outputs.append(allocator, out);
            try l.replayHit(h, regs);
            continue;
        };
        if (reader_refusals.get(idx)) |te| {
            try session.outputs.append(allocator, .{ .name = name, .src = mod.source, .srcPath = mod.srcPath, .outcome = .{ .typeError = te } });
            try reflection.failedModules.put(arena_alloc, mod.path, {});
            if (lb) |l| l.abandon(mod);
            continue;
        }
        var snapshot: ?levelB.Snapshot = if (lb) |l| try l.begin(mod, regs) else null;
        defer if (snapshot) |*sn| sn.deinit();
        const target_trace = try arena_alloc.create(envMod.TargetTrace);
        target_trace.* = .{};
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, .{
            .io = io,
            .build_root = build_root orelse name,
            .target_trace = target_trace,
        }, false, reflection);

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
                    .target_trace = target_trace,
                });
            },
            .typeError => |te| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    // Decision 788 — a block's decorator named `comptime`.
                    .outcome = .{ .typeError = try te.blockNamed(arena_alloc, false) },
                    .target_trace = target_trace,
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
                    try infer.taskLowerings(&succ.env, &instance_lowerings);
                    try infer.unionValueLowerings(&succ.env, arena_alloc, &instance_lowerings);
                    try infer.textValueLowerings(&succ.env, arena_alloc, &instance_lowerings);
                }
                try recordDeclaredValues(mod.path, succ.program.decls, &succ.env);
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
                    // Stdlib fn decls (`print` / `panic`, decision 606 (2))
                    // come from `registerStdlib`'s parse of their modules.
                    // Seed them first so user-module
                    // bindings (next loop) win on name collision — a user-
                    // defined `panic` shadows the builtin, same as any other
                    // stdlib symbol.
                    var sit = succ.env.stdlibFnDecls.iterator();
                    while (sit.next()) |e| try fn_decls.put(e.key_ptr.*, e.value_ptr.*);
                }
                for (succ.bindings) |b| {
                    // Decision 562 — a function expanded at its call site has
                    // no run-time body and is never specialised: the check
                    // reads the body before its `.value` reads are erased.
                    if (b.decl == .@"fn" and !try hooksMod.isExpandedFn(arena_alloc, b.decl.@"fn")) {
                        try fn_decls.put(b.name, try syntax_param.eraseFn(arena_alloc, b.decl.@"fn", infer.isDecoratorParams(b.decl.@"fn".params)));
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
                // Before the lowering transform, which rewrites nodes in place.
                const resolved: ?ast.Program = if (keep_resolved) try resolvedProgram(arena_alloc, succ.written orelse succ.program, fn_decls, comptime_arrays, &succ.env, mod.source) else null;
                const transformed = try value_or_type.withTwinImports(arena_alloc, try withImportSourcesNamed(arena_alloc, try withImportTypeAliasesErased(arena_alloc, try alias_erase.erase(arena_alloc, try withEmbedParams(arena_alloc, try withAssetDecl(arena_alloc, try withYieldStepDecl(arena_alloc, try withDeclaredDecls(arena_alloc, try withSourceRecordDecl(arena_alloc, try withSourceLocationDecl(arena_alloc, try withSynthesisedEnumDecls(
                    arena_alloc,
                    try withUsedAssocInterfaces(arena_alloc, try withTemplateHygiene(arena_alloc, try context_lower.lower(arena_alloc, try type_token.apply(arena_alloc, try transform.transform(arena_alloc, try syntax_param.eraseProgram(arena_alloc, try withoutExpandedFns(arena_alloc, program_for_transform), infer.isDecoratorParams), fn_decls, comptime_arrays, &succ.env.method_lowerings, &succ.env.templateExpansions, &succ.env.srcRewrites, &succ.env.result_jump_lowerings, &succ.env.stdArrayLowerings, &succ.env.enumSectionRewrites, &succ.env.indexRewrites, &succ.env.optionalNullCases, succ.env.ctorParams, &succ.env.defaultInjections, &succ.env.resultPatternLocs, &succ.env.namespaces, &succ.env.localCalleeCalls, &succ.env.embedCallArgs, .backends), &succ.env), &succ.env), &succ.env, try sharesPrivates(arena_alloc, program_for_transform.decls, &succ.env), program_for_transform.decls), &succ.env),
                    &succ.env,
                ), &succ.env), &succ.env), &succ.env), &succ.env), &succ.env), &succ.env), &succ.env.typeAliases), &succ.env), &succ.env), &succ.env.typeArgTwins);

                var type_ids = std.StringHashMap(usize).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.typeId) |id| try type_ids.put(b.name, id);
                }

                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .srcPath = mod.srcPath,
                    .outcome = .{ .ok = .{
                        .resolved = resolved,
                        .bindings = succ.bindings,
                        .comptime_script = ct.comptime_script,
                        .transformed = transformed,
                        .type_ids = type_ids,
                        .dispatch_rewrites = dispatch_rewrites,
                        .js_method_renames = js_method_renames,
                        .instance_lowerings = instance_lowerings,
                        .custom_ast = try collectCustomAst(arena_alloc, &succ.env),
                        .comptime_traces = succ.env.comptimeTraces.items,
                        .build_output = succ.env.buildOutput.items,
                        .template_expansions = succ.env.templateExpansions.count(),
                        .warnings = succ.env.warnings.items,
                        .sync_fns = succ.env.syncFns,
                        .sync_calls = succ.env.syncCalls,
                        .std_host_calls = succ.env.stdHostCalls.items,
                    } },
                });
            },
        }
        // A refused module exports nothing: its importers name it (`import-of-failed-module`).
        if (session.outputs.items[session.outputs.items.len - 1].outcome != .ok) try reflection.failedModules.put(arena_alloc, mod.path, {});
        if (lb) |l| try l.end(mod, idx, session.outputs.items[session.outputs.items.len - 1], regs, if (snapshot) |*sn| sn else null, tree);
    }

    {
        // A module expanding a template whose body queries the catalogue
        // holds that program's answer as well (`templateReads`), a reader to
        // the build's files though it is not one to the analysis order.
        var all: std.StringArrayHashMapUnmanaged(void) = .empty;
        var it = reflection.readers.keyIterator();
        while (it.next()) |k| try all.put(arena_alloc, k.*, {});
        for (reflection.templateReads.items) |read| try all.put(arena_alloc, read.module, {});
        session.readers = all.keys();
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

test "stdModuleOrder: compiler is std's first module, and std admits no cycle (decision 608)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const order = try stdModuleOrder(a);
    try std.testing.expectEqual(std_pkg_modules.len, order.len);
    // `compiler.bp` imports no std module, and every module that names one of
    // its types imports it: it is inferred before any other.
    try std.testing.expectEqualStrings("std/compiler", std_pkg_modules[order[0]].path);
    try std.testing.expectEqual(@as(usize, 0), (try stdImportsOf(a, std_pkg_modules[order[0]].source)).len);
    // Each module comes after every std module it imports: no cycle.
    const position = try a.alloc(usize, order.len);
    for (order, 0..) |m, at| position[m] = at;
    for (std_pkg_modules, 0..) |spm, i| {
        for (try stdImportsOf(a, spm.source)) |dep| {
            if (position[dep] >= position[i]) {
                std.debug.print("std order: {s} is inferred before {s}, which it imports\n", .{ spm.path, std_pkg_modules[dep].path });
                return error.TestUnexpectedResult;
            }
        }
    }
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

test "declaresModuleVar: a module-level var is seen, a val and a local var are not" {
    try std.testing.expect(declaresModuleVar("var hits: i32 = 0;\npub fn f() -> i32 { return hits; }\n"));
    try std.testing.expect(!declaresModuleVar("pub val hits: i32 = 0;\n"));
    try std.testing.expect(!declaresModuleVar("pub fn f() -> i32 {\n    var n: i32 = 0;\n    n = n + 1;\n    return n;\n}\n"));
}
