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
const template = @import("./comptime/template.zig");
const T = @import("./comptime/types.zig");
const Module = @import("./module.zig").Module;
const validation = @import("./comptime/error.zig");

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

pub const ComptimeOutput = struct {
    name: []const u8,
    src: []const u8,
    outcome: Outcome,

    pub const Outcome = union(enum) {
        ok: OkData,
        validationError: ComptimeError,
        /// Type inference failed (e.g. a type mismatch). Carries the located
        /// error so editors can render a diagnostic squiggle.
        typeError: TypeError,
        /// Source failed to parse (e.g. incomplete input during LSP editing).
        parseError: void,
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
fn withUsedAssocInterfaces(arena: std.mem.Allocator, prog: ast.Program, env: *const envMod.Env) !ast.Program {
    if (env.usedAssocInterfaces.count() == 0) return prog;
    var extra: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var it = env.usedAssocInterfaces.keyIterator();
    while (it.next()) |k| {
        const name = k.*;
        var already = false;
        for (prog.decls) |d| {
            if (d == .interface and std.mem.eql(u8, d.interface.name, name)) {
                already = true;
                break;
            }
        }
        if (already) continue;
        if (env.assocInterfaceDecls.get(name)) |decl| {
            try extra.append(arena, .{ .interface = decl });
        }
    }
    if (extra.items.len == 0) return prog;
    const new_decls = try arena.alloc(ast.DeclKind, extra.items.len + prog.decls.len);
    @memcpy(new_decls[0..extra.items.len], extra.items);
    @memcpy(new_decls[extra.items.len..], prog.decls);
    return ast.Program{ .decls = new_decls };
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
    parseError: void,
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
) !AnalysisResult {
    return analyzeSource(arena, mod, mod.source, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, false);
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

/// Analyze one module's `source`. On the first pass (`skip_invoke == false`) a
/// decorator body may contribute generated declarations via `@emit(...)`; if it
/// does, the contributions are spliced onto the source and the module is
/// re-analyzed ONCE with decorator invocation disabled (`skip_invoke == true`),
/// so the generated decls are inferred + emitted without re-running decorators.
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
) anyerror!AnalysisResult {
    var env = try infer.freshEnv(arena, std.heap.page_allocator);
    // Capture provenance for `expr` templates: which file is being inferred.
    env.modulePath = mod.path;
    // Runtime-backed template expansion (F6-full) — null in tooling paths.
    env.templateEval = templateEvalCtx;
    env.skipDecoratorInvoke = skip_invoke;

    var lexer = Lexer.init(source);
    const tokens = try lexer.scanAll(arena);

    var parser = Parser.init(tokens);
    const program = parser.parse(arena) catch |err| switch (err) {
        error.UnexpectedToken => return .parseError,
        else => return err,
    };

    if (validation.validateComptime(program)) |err_info| {
        env.deinit();
        return .{ .validationError = .{ .info = err_info } };
    }

    try resolveImports(&env, program, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry);
    const bindings = infer.inferProgramTyped(&env, program) catch |err| switch (err) {
        error.TypeError => {
            const te = env.lastError orelse validation.TypeError{ .kind = .{ .unboundVariable = "" } };
            env.deinit();
            return .{ .typeError = te };
        },
        else => return err,
    };

    // A decorator body contributed generated declarations (`@emit`): splice them
    // onto the source and re-analyze once (decorators off, to avoid re-emitting).
    if (!skip_invoke and env.contributions.items.len > 0) {
        const spliced = try spliceContributions(arena, source, env.contributions.items);
        const reanalysis = try analyzeSource(arena, mod, spliced, registry, typeDeclRegistry, templateRegistry, decoratorRegistry, extensionRegistry, templateEvalCtx, types_only, true);
        if (reanalysis == .success) {
            env.deinit();
            return reanalysis;
        }
        // The spliced (`@emit`ed) code did not type-check on its own — typically
        // because it references symbols that only resolve with the full project
        // graph (e.g. an example app applying a `from "<lib>"` decorator that the
        // LSP compiled without its dependencies). In the types-only/LSP path we
        // surface this module's pre-splice bindings so completion/hover degrade
        // rather than vanish (`inferProgramTyped` collected the source decls —
        // record, fields, imports — for exactly this case). The CLI
        // (`types_only == false`) keeps the real error instead, so codegen never
        // runs on a half-resolved module.
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
const decl_reflection_src =
    \\pub enum DeclKind { Record, Struct, Enum, Interface, Fn, Method, Field }
    \\pub struct Span { val start: i32, val end: i32, val line: i32 }
    \\pub struct Annotation { val name: string, val args: string[] }
    \\pub struct Param { val name: string, val typeName: string }
    \\pub struct Field { val name: string, val typeName: string, val annotations: Annotation[] }
    \\pub struct Method { val name: string, val params: Param[], val returnType: string, val annotations: Annotation[] }
    \\pub struct Decl {
    \\    val kind: DeclKind,
    \\    val name: string,
    \\    val fields: Field[],
    \\    val methods: Method[],
    \\    val returnType: string,
    \\    val annotations: Annotation[],
    \\    declare fn fail(self: Self, message: string);
    \\    declare fn failAt(self: Self, span: Span, message: string);
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
    \\pub struct CustomNode {
    \\    val kind: string,
    \\    val span: Span,
    \\    val label: string,
    \\    val ref: ?Binding,
    \\    val children: CustomNode[],
    \\}
;

/// Embedded builtin-type interface declarations. Unlike `std_pkg_modules`
/// these are flattened into the global type env at infer time (they declare the
/// methods available on primitives / arrays / strings). Tooling — the language
/// server — scans these sources to resolve receiver methods such as `42.abs()`,
/// `true.to_string()`, `xs.map(…)` and `"s".len()`.
pub const primitive_interfaces_src = @import("std_prelude").primitives;
// Array<T> and String interfaces live inside primitives.d.bp (the controller)
// in the interface model — there are no standalone array/string modules.
pub const array_interface_src = @import("std_prelude").primitives;
pub const string_interface_src = @import("std_prelude").primitives;

/// True when `path` is a "std" package registry key (`std/<module>`).
fn isStdPkgPath(path: []const u8) bool {
    return std.mem.startsWith(u8, path, "std/");
}

/// Scans `modules` for `import {…} from "std"` declarations and returns the
/// module list with the required embedded std modules prepended (dependency
/// order, deduplicated). Modules that fail to parse pass through untouched —
/// `analyzeModule` reports the parse error later.
fn expandStdImports(arena: std.mem.Allocator, modules: []const Module) ![]const Module {
    var needed = [_]bool{false} ** std_pkg_modules.len;
    var any = false;
    for (modules) |mod| {
        var lx = Lexer.init(mod.source);
        const tokens = lx.scanAll(arena) catch continue;
        var p = Parser.init(tokens);
        const program = p.parse(arena) catch continue;
        for (program.decls) |decl| switch (decl) {
            .use => |u| {
                const from_std = switch (u.source) {
                    .module => |m| std.mem.eql(u8, m, "std"),
                    .root => false,
                };
                if (!from_std) continue;
                for (u.imports) |imp| {
                    const want = imp.segments[imp.segments.len - 1];
                    for (std_pkg_modules, 0..) |spm, i| {
                        if (std.mem.eql(u8, spm.path["std/".len..], want)) {
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

    var out: std.ArrayListUnmanaged(Module) = .empty;
    for (std_pkg_modules, 0..) |spm, i| {
        if (needed[i]) try out.append(arena, .{ .path = spm.path, .source = spm.source });
    }
    try out.appendSlice(arena, modules);
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
                    .root => false,
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
                    var pit = registry.iterator();
                    while (pit.next()) |e| {
                        if (isStdPkgPath(e.key_ptr.*)) continue;
                        if (e.value_ptr.get(pkg)) |ty| {
                            try env.bind(pkg, ty);
                            break;
                        }
                    }
                    // Template-fn binding so the call expands at comptime.
                    if (templateRegistry.get(pkg)) |tfn| {
                        try infer.registerImportedTemplateFn(env, pkg, tfn);
                    }
                }
                for (u.imports) |imp| {
                    const name = imp.name();
                    if (from_std) {
                        // `import {bool} from "std"` — handled inside
                        // inference (`inferProgramTyped` marks `stdImports`,
                        // gating qualified calls on `env.stdModules`).
                        continue;
                    }
                    // Bare import: same-package (project root) resolution only —
                    // never resolves "std" package modules. An imported nominal
                    // type carries its full declaration across the module
                    // boundary (re-registered below) so its `TypeDef` metadata —
                    // `implements`/`contextBase`/fields — is visible here, not
                    // just its constructor value. This mirrors the `from "std"`
                    // type-export path (`stdModuleTypes` → `registerTypeDecl`).
                    var bound_type_decl = false;
                    var dit = typeDeclRegistry.iterator();
                    while (dit.next()) |e| {
                        if (isStdPkgPath(e.key_ptr.*)) continue;
                        if (e.value_ptr.get(name)) |type_decl| {
                            try infer.registerImportedTypeDecl(env, type_decl);
                            bound_type_decl = true;
                            break;
                        }
                    }
                    // Value/constructor binding. Skipped for nominal types whose
                    // declaration was just re-registered — `registerTypeDecl`
                    // already bound the constructor with the importing module's
                    // own type ids, and clobbering it with the exported `*T.Type`
                    // would reintroduce the defining module's ids.
                    if (!bound_type_decl) {
                        var it = registry.iterator();
                        while (it.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*)) continue;
                            if (e.value_ptr.get(name)) |ty| {
                                try env.bind(name, ty);
                                break;
                            }
                        }
                    }
                    // Imported template fns (`-> @Expr<…>`) carry their decl
                    // across modules so call sites here can expand them.
                    if (templateRegistry.get(name)) |tfn| {
                        try infer.registerImportedTemplateFn(env, name, tfn);
                    }
                    // Imported decorators (`comptime _: @Decl` first param) carry
                    // their decl across modules too, so `#[name(args)]` sites in
                    // THIS module argument-check against the marker and run its
                    // body over each annotated declaration at comptime. Without
                    // this a marker only fired in its defining module — a lib
                    // ships its decorators, but they are applied by importers.
                    if (decoratorRegistry.get(name)) |dfn| {
                        infer.registerImportedDecorator(env, name, dfn);
                    }
                    // Imported + activated extension (`import { Name* } from "mod"`):
                    // an `implement` block defined in another module is opted into
                    // THIS module's dispatch table only when the importer stars it.
                    // Local extensions auto-apply; imported ones are opt-in by `*`.
                    if (imp.activate) {
                        var eit = extensionRegistry.iterator();
                        while (eit.next()) |e| {
                            if (isStdPkgPath(e.key_ptr.*)) continue;
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

/// The package key for a module path: the segment before the first `/` (a lib
/// dependency is loaded as `<lib>/<stem>`), or "" for a root-package module.
fn pkgKey(path: []const u8) []const u8 {
    if (std.mem.indexOfScalar(u8, path, '/')) |i| return path[0..i];
    return "";
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
            // `pub` nominal type declarations export their full AST decl too, so
            // the importing module can re-register the `TypeDef` (implements /
            // contextBase / fields) — not just the constructor value. Mirrors
            // the `from "std"` type-export path (`stdModuleTypes`), which is also
            // `pub`-only. Non-pub types still export their constructor (above)
            // for value use, but carry no cross-module `TypeDef`.
            switch (b.decl) {
                .record => |r| if (r.isPub) try typeDecls.put(b.name, b.decl),
                .@"struct" => |s| if (s.isPub) try typeDecls.put(b.name, b.decl),
                .@"enum" => |e| if (e.isPub) try typeDecls.put(b.name, b.decl),
                else => {},
            }
            // Template fns export their declaration too — importing modules
            // expand their calls at comptime (the decl never reaches codegen).
            if (b.decl == .@"fn") {
                const f = b.decl.@"fn";
                if (f.returnType) |rt| {
                    if (rt.isTemplateReturnType()) try templateRegistry.put(b.name, f);
                }
                // Decorators (`comptime _: @Decl` first param) export their decl
                // too, so importing modules can run the body over their annotated
                // declarations — generic, by shape, no lib name involved.
                if (infer.isDecoratorParams(f.params)) try decoratorRegistry.put(b.name, f);
            }
        }
    }
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
    {
        const alloc = env.arena;
        var lx = Lexer.init(decl_reflection_src);
        const tokens = try lx.scanAll(alloc);
        var p = Parser.init(tokens);
        const program = try p.parse(alloc);
        _ = try infer.inferProgram(env, program);
    }

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

    for (std_pkg_modules) |spm| {
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
        for (sources) |src| {
            var lx = Lexer.init(src);
            const tokens = try lx.scanAll(env.arena);
            var p = Parser.init(tokens);
            const program = try stripTestDecls(try p.parse(env.arena), env.arena);
            _ = try infer.inferProgram(&env2, program);
        }
        var lx = Lexer.init(spm.source);
        const tokens = try lx.scanAll(env.arena);
        var p = Parser.init(tokens);
        const program = try stripTestDecls(try p.parse(env.arena), env.arena);
        const bindings = try infer.inferProgramTyped(&env2, program);

        // Collect the module's public type declarations so `import {…} from
        // "std"` can register them into the importing env (type export —
        // enables case patterns / annotations over e.g. `Order`).
        {
            var type_decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
            for (program.decls) |decl| {
                const is_pub_type = switch (decl) {
                    .record => |r| r.isPub,
                    .@"struct" => |s| s.isPub,
                    .@"enum" => |e2| e2.isPub,
                    else => false,
                };
                if (is_pub_type) try type_decls.append(env.arena, decl);
            }
            if (type_decls.items.len > 0) {
                try env.stdModuleTypes.put(mod_name, try type_decls.toOwnedSlice(env.arena));
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
    var default_dsl = DefaultDsl.init(arena_alloc);

    // `from "std"` imports pull the embedded std modules into the compilation.
    // Non-std libs are ordinary input modules: the driver supplies their `.bp`
    // sources and `resolveImports` binds `from "<lib>"` through the shared
    // registry — the core names no specific lib (std is the one exception).
    const all_modules = try expandStdImports(arena_alloc, modules);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, eval_ctx, true);

        switch (analysis) {
            .parseError => {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .parseError,
                });
            },
            .validationError => |verr| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .{ .validationError = verr.info },
                });
            },
            .typeError => |te| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
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
                for (succ.bindings) |b| {
                    if (b.decl == .@"fn") try fn_decls.put(b.name, b.decl.@"fn");
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
                        program_for_transform,
                        fn_decls,
                        std.StringHashMap([]const ast.TypedExpr).init(arena_alloc),
                        empty_vals,
                        &succ.env.method_lowerings,
                        &succ.env.templateExpansions,
                        &succ.env.result_jump_lowerings,
                        &succ.env.stdArrayLowerings,
                    ) catch break :blk_t program_for_transform;
                    break :blk_t withUsedAssocInterfaces(arena_alloc, t, &succ.env) catch program_for_transform;
                };

                var type_ids = std.StringHashMap(usize).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.typeId) |id| try type_ids.put(b.name, id);
                }

                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
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
    var type_decl_registry = std.StringHashMap(std.StringHashMap(ast.DeclKind)).init(arena_alloc);
    var template_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var decorator_registry = std.StringHashMap(ast.FnDecl).init(arena_alloc);
    var extension_registry = std.StringHashMap(std.StringHashMap(ast.ImplementDecl)).init(arena_alloc);
    var default_dsl = DefaultDsl.init(arena_alloc);

    // `from "std"` imports pull the embedded std modules into the compilation.
    // Non-std libs are ordinary input modules: the driver supplies their `.bp`
    // sources and `resolveImports` binds `from "<lib>"` through the shared
    // registry — the core names no specific lib (std is the one exception).
    const all_modules = try expandStdImports(arena_alloc, modules);

    for (all_modules, 0..) |mod, idx| {
        const name: []const u8 = if (mod.path.len > 0) mod.path else "main";
        const analysis = try analyzeModule(arena_alloc, mod, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, .{
            .io = io,
            .build_root = build_root orelse name,
        }, false);

        switch (analysis) {
            .parseError => {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .parseError,
                });
            },
            .validationError => |verr| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
                    .outcome = .{ .validationError = verr.info },
                });
            },
            .typeError => |te| {
                try session.outputs.append(allocator, .{
                    .name = name,
                    .src = mod.source,
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
                }
                if (idx < all_modules.len - 1) {
                    var env = succ.env;
                    try registerExports(arena_alloc, &registry, &type_decl_registry, &template_registry, &decorator_registry, &extension_registry, &default_dsl, mod.path, succ.bindings, succ.program.decls, &env);
                    // NOTE: no env.deinit() here — `env` is a copy whose hashmap
                    // internals are shared with `succ.env`, and the transform
                    // below still reads `succ.env.method_lowerings`. The env is
                    // arena-backed; the session arena reclaims it wholesale.
                }
                const ct = try evaluateComptime(arena_alloc, io, succ.bindings, runtime, build_root orelse name);

                var fn_decls = std.StringHashMap(ast.FnDecl).init(arena_alloc);
                var comptime_arrays = std.StringHashMap([]const ast.TypedExpr).init(arena_alloc);
                for (succ.bindings) |b| {
                    if (b.decl == .@"fn") {
                        try fn_decls.put(b.name, b.decl.@"fn");
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
                const transformed = try withUsedAssocInterfaces(arena_alloc, try transform.transform(arena_alloc, program_for_transform, fn_decls, comptime_arrays, ct.comptime_vals, &succ.env.method_lowerings, &succ.env.templateExpansions, &succ.env.result_jump_lowerings, &succ.env.stdArrayLowerings), &succ.env);

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
                        .dispatch_rewrites = dispatch_rewrites,
                        .js_method_renames = js_method_renames,
                        .instance_lowerings = instance_lowerings,
                        .custom_ast = try collectCustomAst(arena_alloc, &succ.env),
                    } },
                });
            },
        }
    }

    return session;
}
