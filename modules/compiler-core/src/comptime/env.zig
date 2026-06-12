/// Type inference environment for the botopink type checker.
///
/// All Type/TypeCell allocations go through `arena`. The caller owns an
/// ArenaAllocator and frees it after type-checking is complete.
const std = @import("std");
const ast = @import("../ast.zig");
const T = @import("./types.zig");
const template = @import("./template.zig");

// ── type definitions ──────────────────────────────────────────────────────────

/// A field inside a record, struct, or enum variant.
pub const FieldDef = struct {
    name: []const u8,
    type_: *T.Type,
};

/// One variant inside an enum type definition.
pub const VariantDef = struct {
    name: []const u8,
    fields: []FieldDef,
};

/// A registered type shape: record, struct, or enum.
pub const TypeDef = union(enum) {
    record: Record,
    struct_: Struct,
    enum_: Enum,

    pub const Record = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        fields: []FieldDef,
        implements: []const []const u8 = &.{},
        /// ContextBase name when this type implements `@Context<B, R>` inline; null otherwise.
        contextBase: ?[]const u8 = null,
    };

    pub const Struct = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        fields: []FieldDef,
        implements: []const []const u8 = &.{},
        /// ContextBase name when this type implements `@Context<B, R>` inline; null otherwise.
        contextBase: ?[]const u8 = null,
    };

    pub const Enum = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        variants: []VariantDef,
        implements: []const []const u8 = &.{},
        /// ContextBase name when this type implements `@Context<B, R>` inline; null otherwise.
        contextBase: ?[]const u8 = null,
    };

    /// The `ContextBase` of this type when it implements `@Context<B, R>` inline.
    /// Returns null for types that do not implement `@Context`.
    pub fn contextBase(self: TypeDef) ?[]const u8 {
        return switch (self) {
            .record => |r| r.contextBase,
            .struct_ => |s| s.contextBase,
            .enum_ => |e| e.contextBase,
        };
    }

    /// Return the fields slice for record or struct types; null for enums.
    pub fn fields(self: TypeDef) ?[]FieldDef {
        return switch (self) {
            .record => |r| r.fields,
            .struct_ => |s| s.fields,
            .enum_ => null,
        };
    }

    /// Look up a field by name. Returns null if not found or if this is an enum.
    pub fn findField(self: TypeDef, name: []const u8) ?*FieldDef {
        const flds = self.fields() orelse return null;
        for (flds) |*f| {
            if (std.mem.eql(u8, f.name, name)) return f;
        }
        return null;
    }
};

// ── static extension dispatch ───────────────────────────────────────────────────

/// A named `implement … for T` block, registered for static extension dispatch.
/// Every entry is declared in the current module (imports do not register here),
/// so `obj.method()` resolves to one without any activation — local extensions
/// are auto-applied.
pub const ExtEntry = struct {
    /// The dispatch symbol, e.g. "PatoNada".
    name: []const u8,
    /// The type this block implements methods for, e.g. "Pato".
    target: []const u8,
    /// Interfaces named in the `implement` block.
    interfaces: []const ast.TypeRef = &.{},
    /// Method names declared in the block.
    methods: []const []const u8,
};

// ── @Context capability scope ───────────────────────────────────────────────────

/// Capability information about the function body currently being inferred.
///
/// The function's return type decides whether `use` is allowed inside the body:
/// the return must implement `@Context<ContextBase, Return>`. All `use` calls in
/// the body must agree on the same `ContextBase`. `null` on the environment means
/// no function body is currently being inferred (top-level position).
pub const FnContext = struct {
    /// True when the function's return type implements `@Context<_, _>`.
    implementsContext: bool,
    /// The `ContextBase` name when `implementsContext` is true; null otherwise.
    base: ?[]const u8 = null,
    /// Rendered return type, used in the "`use` not allowed" diagnostic.
    returnDisplay: []const u8 = "void",
};

/// How `throw` should be type-checked in the current function scope.
///
/// Set by `inferFnDecl` when entering a named function body and reset to
/// `.unchecked` inside nested function expressions (lambdas have no declared
/// return type). `inferJumpExpr` reads it to validate `throw` statements.
pub const ThrowContext = union(enum) {
    /// No declared return type (top-level or lambda) — `throw` is left unchecked.
    unchecked,
    /// Enclosing fn returns `@Result<D, E>` — a thrown value must unify with `E`.
    result: *T.Type,
    /// Enclosing fn has a declared non-`@Result` return type — `throw` is illegal.
    plain,
};

/// Metadata for one `comptime name: expr T` parameter of a function
/// (expr-templates F4). Recorded at fn-declaration time; call sites capture
/// the matching argument **unevaluated** (unified against the inner `T`)
/// instead of unifying it against `expr T` directly.
pub const ExprParamInfo = struct {
    /// Index of this parameter in the function's parameter list.
    paramIndex: usize,
    /// The parameter's name (for diagnostics and capture provenance).
    paramName: []const u8,
};

/// One reference-AST entry produced by a `q.custom(tree, code)` template
/// expansion (expr-custom): the canonical `CustomNode` root plus the provenance
/// a tooling consumer needs to map a node's (template-relative) `span` to an
/// absolute document position. Generic — no sub-language is named.
pub const CustomAstEntry = struct {
    /// The called template function's name (e.g. the DSL entry point).
    callee: []const u8,
    /// The reference tree (reference-only; never lowered).
    root: template.CustomNode,
    /// Source file of the template literal ("" for main).
    file: []const u8,
    /// 1-based line/column of the template literal's opening quote.
    line: usize,
    col: usize,
};

/// A compiler-provided template method resolved by inference (expr-templates
/// F4): `text`/`parts`/`source`/`context`/`lookup`/`bindings`/`fail`/`failAt`
/// on an `expr` receiver, plus `ref` on a `Binding`. Mirrors `MethodLowering`:
/// keyed by the call's source `Loc` and consumed by the call-site expansion
/// pass (F6). Instances only exist at comptime — no codegen backend ever sees
/// these calls.
pub const TemplateOp = enum { value, text, parts, source, context, lookup, bindings, build, custom, fail, failAt, ref };

/// Everything the inference-time template evaluator needs to run a template
/// body in the external eval runtime (expr-templates F6-full). Null in
/// tooling paths (`compileTypesOnly` / LSP) — only the full `compile`
/// pipeline evaluates template bodies.
pub const TemplateEvalCtx = struct {
    io: std.Io,
    build_root: []const u8,
};

/// Constraint metadata for one `comptime ...: typeparam` parameter of a function.
/// Recorded at fn-declaration time and consulted at each call site.
pub const TypeparamConstraint = struct {
    /// Index of this parameter in the function's parameter list.
    paramIndex: usize,
    /// The parameter's name (for diagnostics).
    paramName: []const u8,
    /// Accepted type names (e.g. `string`, `int`, `bool`). Empty means
    /// the typeparam is unconstrained and accepts a value of any type.
    names: []const []const u8,
};

// ── environment ───────────────────────────────────────────────────────────────

/// Context active while inferring the body of a `*fn` (async / generator).
/// Drives validation of `await` and `yield`; `null` inside normal functions
/// and at the top level.
pub const StarFnCtx = struct {
    /// `await` is permitted here — async function (`@Future`) or async
    /// generator (`@AsyncIterator`).
    allowsAwait: bool,
    /// `yield` (and generator delegation) is permitted here — `@Iterator` /
    /// `@Generator` / `@AsyncIterator`. False for a pure `@Future`.
    allowsYield: bool,
    /// `@Iterator<T>` / `@Generator<T, _>` / `@AsyncIterator<T, _>` item type
    /// that `yield` values must unify with; `null` when unknown (anonymous
    /// `*fn`) or absent (`@Future`).
    iterItem: ?*T.Type,
};

/// The type-checking environment.
///
/// Owns no memory itself ---- all allocations go through `arena`.
/// Deinit only frees the hash map metadata; the arena frees everything else.
/// A type-directed lowering decision for a builtin method call (`@Result` /
/// `@Option` methods like `.map` / `.unwrapOr`). Recorded by inference, keyed by
/// the call's source `Loc`, and consumed by the AST transform pass which rewrites
/// the untyped call node into a `__bp_<domain>_<op>(receiver, args...)` builtin
/// call that each codegen backend lowers to its native form.
pub const MethodLowering = struct {
    pub const Domain = enum { result, option };
    pub const Op = enum { map, flatMap, unwrapOr, isOk, isError };
    domain: Domain,
    op: Op,
    /// True for builtin-namespace qualified calls (`result.map(r, f)`,
    /// `result.unwrap(r, 0)`) — the receiver is the namespace identifier, not a
    /// value, so the transform drops it and keeps the args as-is. False for
    /// method form (`x.map(f)`) where the receiver becomes the first arg.
    qualified: bool = false,
};

/// A type-directed lowering for a stdlib-module method call on a builtin-array
/// receiver: `xs.method(args)` where `xs: Array<T>` dispatches to the named
/// stdlib module's function. Recorded by inference, keyed by call loc; consumed
/// by the transform to rewrite `xs.method(args)` → `module.method(xs, args)`.
pub const StdArrayLowering = struct {
    module: []const u8,
    method: []const u8,
};

/// The builtin-primitive family of a method-call receiver. Lets a backend that
/// has no native method dispatch (erlang/beam/wasm) map `xs.map(f)` /
/// `s.toUpper()` / `n.abs()` to the host's equivalent (`lists:map(F, Xs)`, …).
pub const PrimKind = enum { array, string, bool, int, float };

/// How a value-receiver instance call `recv.method(args)` lowers on backends
/// without native method dispatch. Recorded by inference keyed by call loc.
///   - `prim`   — the receiver is a builtin primitive; the backend maps
///                `(PrimKind, method)` to its host operation.
///   - `record` — the receiver is a record/struct/enum value; the method is a
///                plain function taking the receiver first. The payload is the
///                receiver's nominal type name; the backend resolves a local
///                call (`method(Recv, args)`) vs an imported owner module
///                (`owner:method(Recv, args)`) from its own import index.
pub const InstanceLowering = union(enum) {
    prim: PrimKind,
    record: []const u8,
};

/// A recognized decorator's signature, minus its leading `comptime _: @Decl`
/// parameter. `params` are the trailing argument parameters an `#[d(args)]`
/// application type-checks against (arity + types). Populated generically for
/// any fn whose first parameter is `comptime _: @Decl` — no lib knowledge. The
/// slice points into the AST arena (the decl's own `params`), so it is stable.
///
/// `fn_decl` carries the full decorator function (with body) when it has one —
/// `pub fn d(comptime _: @Decl) { … }`. It is run over the annotated declaration
/// at comptime (P2: placement/argument rules live in the body). `null` for a
/// bodyless `declare fn` marker, which only gets argument validation.
pub const DecoratorSig = struct {
    params: []const ast.Param,
    fn_decl: ?ast.FnDecl = null,
};

/// A type-directed lowering for a `return`/`throw` jump inside a fn returning
/// `@Result<D, E>`. Recorded by inference keyed by the jump's source `Loc` and
/// consumed by the transform pass, which wraps the value in a `__bp_ok(…)` /
/// `__bp_error(…)` builtin call (and rewrites `throw` into a `return`) so every
/// backend materialises the same `{ok, V}` / `{error, E}` Result value.
/// `unwrap_passthrough` handles `return try f()`: unwrapping then immediately
/// re-wrapping is the identity, so the transform drops the `try` and returns
/// `f()`'s Result directly.
pub const ResultJumpLowering = enum { wrap_ok, wrap_error, unwrap_passthrough };

pub const Env = struct {
    /// Arena allocator ---- all Type and TypeCell nodes are allocated here.
    arena: std.mem.Allocator,
    /// Value bindings: variable/function name → *Type.
    bindings: std.StringHashMap(*T.Type),
    /// Registered type definitions: type name → TypeDef.
    typeDefs: std.StringHashMap(TypeDef),
    /// Per-function typeparam constraints: function name → constraint list.
    /// Only functions with at least one `typeparam` parameter appear here.
    fnTypeparams: std.StringHashMap([]const TypeparamConstraint),
    /// Per-function `expr` meta-kind params: function name → param info list.
    /// Only functions with at least one `expr` parameter appear here (F4).
    fnExprParams: std.StringHashMap([]const ExprParamInfo),
    /// Unevaluated `expr` arguments captured at call sites, keyed by the
    /// call's source location; consumed by the expansion pass (F6).
    exprCaptures: std.AutoHashMap(ast.Loc, []const template.CapturedExpr),
    /// Compiler-provided template method calls (`text`/`parts`/`lookup`/
    /// `fail`/`failAt`/`ref`) keyed by call loc; consumed by expansion (F6).
    templateLowerings: std.AutoHashMap(ast.Loc, TemplateOp),
    /// Template functions (`-> expr [T]` return): name → declaration. Calls to
    /// these are expanded at comptime (F6); the decls never reach codegen.
    templateFns: std.StringHashMap(ast.FnDecl),
    /// Call-site expansions: call loc → the expanded (untyped) expression that
    /// replaces the call. Recorded by inference (post splice + re-check); the
    /// transform pass rewrites the untyped AST from this map.
    templateExpansions: std.AutoHashMap(ast.Loc, *const ast.Expr),
    /// Reference ASTs from `q.custom(tree, code)` (expr-custom): call loc → the
    /// canonical `CustomNode` tree + provenance. Sibling of `templateExpansions`
    /// — the `code` half lives there and reaches codegen; this `ast` half is
    /// reference-only (tooling/LSP), never lowered. Exposed via the read API in
    /// `root.zig`/`comptime.zig`.
    customAstByLoc: std.AutoHashMap(ast.Loc, CustomAstEntry),
    /// V1 origin-scope snapshot of the module being inferred (top-level decls
    /// + imports); attached to every `expr` capture for `lookup` resolution.
    scopeSnapshot: ?*template.ScopeSnapshot = null,
    /// Module path of the file being inferred ("" for main) — capture provenance.
    modulePath: []const u8 = "",
    /// True while inferring the body of a template function (`-> @Expr<…>`).
    /// Gates the `@expr`/`@code` construction builtins.
    inTemplateFn: bool = false,
    /// Runtime-backed template evaluation context (F6-full). Null in tooling
    /// paths — non-V1 template bodies then raise the V1 driver error.
    templateEval: ?TemplateEvalCtx = null,
    /// Memoization for runtime-backed expansions: hash(callee + capture
    /// texts) → the expanded expression. The expansion is still re-inferred
    /// per call site; only the external evaluation is skipped.
    templateEvalCache: std.StringHashMap(*const ast.Expr),
    /// Monotonically increasing counter for fresh type variable IDs.
    nextId: T.TypeId,
    /// Monotonically increasing counter for type definition IDs (record$$0, struct$$1, ...).
    nextTypeId: usize,
    /// Current let-binding level for generalization.
    level: usize,
    /// The most recent type error (set before returning `error.TypeError`).
    lastError: ?@import("error.zig").TypeError,
    /// Builtin `@Result`/`@Option` method calls discovered during inference,
    /// keyed by the call's source location. Drives the AST transform lowering.
    method_lowerings: std.AutoHashMap(ast.Loc, MethodLowering),
    /// `return`/`throw` jumps inside `-> @Result<…>` fns that must construct a
    /// Result value, keyed by the jump's source location. Drives the AST
    /// transform `__bp_ok`/`__bp_error` wrapping.
    result_jump_lowerings: std.AutoHashMap(ast.Loc, ResultJumpLowering),
    /// Capability scope of the function body currently being inferred (null at top level).
    fnContext: ?FnContext = null,
    /// How `throw` is checked in the function body currently being inferred.
    throwContext: ThrowContext = .unchecked,
    /// Active `*fn` context while inferring its body (for `await`/`yield` rules).
    starFn: ?StarFnCtx = null,
    /// Labels currently in scope (`*fn` label + enclosing loop labels), used to
    /// validate `yield :label` / `break :label`. Pushed/popped as scopes nest.
    labelStack: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Registered `implement`/`extend` blocks, keyed by activation symbol name.
    extensions: std.StringHashMap(ExtEntry),
    /// Activation set: symbols enabled for extension dispatch in this file
    /// (`name*` imports and bare `name*;` statements).
    activations: std.StringHashMap(void),
    /// Inherent methods declared directly on a type (struct/record/enum bodies
    /// and inline `implement`), keyed by type name → set of method names.
    inherentMethods: std.StringHashMap(std.StringHashMap(void)),
    /// Resolved signatures of inherent methods, keyed type name → method name →
    /// `fn(self: Instance, params…) -> Ret`. Lets `recv.method(args)` recover the
    /// method's real return type (the type's generic cells are instantiated per
    /// call site). Populated alongside `inherentMethods` during registration.
    inherentMethodTypes: std.StringHashMap(std.StringHashMap(*T.Type)),
    /// Interface declarations that expose associated functions (`default fn` with
    /// no `self`), keyed by name. Includes stdlib primitives (`Pair`, `Function`,
    /// `Array`) registered before user inference. Used to emit their namespace
    /// objects into the codegen output when a call site uses them.
    assocInterfaceDecls: std.StringHashMap(ast.InterfaceDecl),
    /// Interface names actually used as an associated-fn call receiver
    /// (`Pair.of(...)`), recorded during inference so codegen emits only the
    /// namespaces that are needed.
    usedAssocInterfaces: std.StringHashMap(void),
    /// Resolved external-dispatch rewrites: call-site location → extension symbol
    /// to qualify with. Consumed by the transform pass to lower `obj.m(args)` to
    /// `Sym.m(obj, args)` without monkey-patching.
    dispatchRewrites: std.AutoHashMap(ast.Loc, []const u8),
    /// Type-directed JS method renames: call-site location → the native JS method
    /// name to emit instead of the source `callee`. Recorded by inference when the
    /// receiver's static type makes a global name-map unsafe (e.g. `s.contains(x)`
    /// on a `string` lowers to `s.includes(x)`, but `Set.contains` must stay).
    /// JS-specific — only the commonJS backend reads it.
    jsMethodRenames: std.AutoHashMap(ast.Loc, []const u8),
    /// `"std"` package module exports: module name (`option`, `result`, …) →
    /// exports table (pub fn name → inferred type). Shared registry tables,
    /// populated by the compile session before inference.
    stdModules: std.StringHashMap(std.StringHashMap(*T.Type)),
    /// Local (alias-aware) names imported via `import {…} from "std"` —
    /// marked during inference; only these gate qualified calls
    /// (`bool.negate(x)`) against `stdModules`.
    stdImports: std.StringHashMap(void),
    /// Public type declarations (`pub record`/`struct`/`enum`) of each "std"
    /// package module, keyed by module name. Populated by `registerStdlib`;
    /// `markStdImports` registers them into the importing env so case
    /// patterns and annotations see the exported types (e.g. `Order`).
    stdModuleTypes: std.StringHashMap([]const ast.DeclKind),
    /// Stdlib method calls on builtin-array receivers (`xs.isEmpty()` sugar).
    /// Key: call loc, value: { module, method }. Consumed by transform.
    stdArrayLowerings: std.AutoHashMap(ast.Loc, StdArrayLowering),
    /// Value-receiver instance method calls (`recv.method(args)`), keyed by call
    /// loc. Lets backends without native method dispatch lower record + builtin
    /// primitive methods. Empty contribution on commonJS (native dispatch).
    instanceLowerings: std.AutoHashMap(ast.Loc, InstanceLowering),
    /// Stdlib modules implicitly required via array method dispatch; used by
    /// the compile session to prepend synthetic imports for the codegen.
    implicitStdModules: std.StringHashMap(void),
    /// Decorators recognized in this module (and its imports), name → trailing
    /// signature. A decorator is any fn whose first param is `comptime _: @Decl`;
    /// this is the lib-agnostic registry used to type-check `#[d(args)]` argument
    /// arity + types at every annotation site. Lib knowledge lives in the
    /// decorator body, never here.
    decorators: std.StringHashMap(DecoratorSig),
    /// Top-level declaration sources a decorator body contributed via `@emit(...)`
    /// while inferring this module. `analyzeModule` splices them into the module
    /// and re-analyzes it (a wiring decorator builds singletons / DI / router as
    /// ordinary code). Allocated in `arena`; no explicit deinit needed.
    contributions: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Set on the second analysis pass (after splicing contributions) so
    /// decorators are not re-invoked — no re-contribution, no infinite loop.
    skipDecoratorInvoke: bool = false,

    pub fn init(arena: std.mem.Allocator) Env {
        return .{
            .arena = arena,
            .bindings = std.StringHashMap(*T.Type).init(arena),
            .typeDefs = std.StringHashMap(TypeDef).init(arena),
            .fnTypeparams = std.StringHashMap([]const TypeparamConstraint).init(arena),
            .fnExprParams = std.StringHashMap([]const ExprParamInfo).init(arena),
            .exprCaptures = std.AutoHashMap(ast.Loc, []const template.CapturedExpr).init(arena),
            .templateLowerings = std.AutoHashMap(ast.Loc, TemplateOp).init(arena),
            .templateFns = std.StringHashMap(ast.FnDecl).init(arena),
            .templateExpansions = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .customAstByLoc = std.AutoHashMap(ast.Loc, CustomAstEntry).init(arena),
            .templateEvalCache = std.StringHashMap(*const ast.Expr).init(arena),
            .nextId = 0,
            .nextTypeId = 0,
            .level = 0,
            .lastError = null,
            .method_lowerings = std.AutoHashMap(ast.Loc, MethodLowering).init(arena),
            .result_jump_lowerings = std.AutoHashMap(ast.Loc, ResultJumpLowering).init(arena),
            .fnContext = null,
            .throwContext = .unchecked,
            .starFn = null,
            .labelStack = .empty,
            .extensions = std.StringHashMap(ExtEntry).init(arena),
            .activations = std.StringHashMap(void).init(arena),
            .inherentMethods = std.StringHashMap(std.StringHashMap(void)).init(arena),
            .inherentMethodTypes = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena),
            .assocInterfaceDecls = std.StringHashMap(ast.InterfaceDecl).init(arena),
            .usedAssocInterfaces = std.StringHashMap(void).init(arena),
            .dispatchRewrites = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .jsMethodRenames = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .stdModules = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena),
            .stdImports = std.StringHashMap(void).init(arena),
            .stdModuleTypes = std.StringHashMap([]const ast.DeclKind).init(arena),
            .stdArrayLowerings = std.AutoHashMap(ast.Loc, StdArrayLowering).init(arena),
            .instanceLowerings = std.AutoHashMap(ast.Loc, InstanceLowering).init(arena),
            .implicitStdModules = std.StringHashMap(void).init(arena),
            .decorators = std.StringHashMap(DecoratorSig).init(arena),
        };
    }

    /// True when `label` is in scope for a `yield`/`break` target.
    pub fn hasLabel(self: *Env, label: []const u8) bool {
        for (self.labelStack.items) |l| {
            if (std.mem.eql(u8, l, label)) return true;
        }
        return false;
    }

    pub fn deinit(self: *Env) void {
        self.bindings.deinit();
        self.typeDefs.deinit();
        self.method_lowerings.deinit();
        self.result_jump_lowerings.deinit();
        self.fnTypeparams.deinit();
        self.fnExprParams.deinit();
        self.exprCaptures.deinit();
        self.templateLowerings.deinit();
        self.templateFns.deinit();
        self.templateExpansions.deinit();
        self.customAstByLoc.deinit();
        self.templateEvalCache.deinit();
        self.extensions.deinit();
        self.activations.deinit();
        var it = self.inherentMethods.valueIterator();
        while (it.next()) |set| set.deinit();
        self.inherentMethods.deinit();
        var itt = self.inherentMethodTypes.valueIterator();
        while (itt.next()) |set| set.deinit();
        self.inherentMethodTypes.deinit();
        self.dispatchRewrites.deinit();
        self.jsMethodRenames.deinit();
        // Note: stdModules values are shared registry export tables — owned by
        // the compile session, not this env. Only the outer maps are ours.
        self.stdModules.deinit();
        self.stdImports.deinit();
        self.stdModuleTypes.deinit();
        self.stdArrayLowerings.deinit();
        self.instanceLowerings.deinit();
        self.implicitStdModules.deinit();
        self.decorators.deinit();
    }

    // ── extension dispatch helpers ────────────────────────────────────────────

    /// Record that `typeName` has an inherent method `method`.
    pub fn addInherentMethod(self: *Env, typeName: []const u8, method: []const u8) !void {
        const gop = try self.inherentMethods.getOrPut(typeName);
        if (!gop.found_existing) gop.value_ptr.* = std.StringHashMap(void).init(self.arena);
        try gop.value_ptr.put(method, {});
    }

    /// True if `typeName` declares an inherent method `method`.
    pub fn hasInherentMethod(self: *Env, typeName: []const u8, method: []const u8) bool {
        const set = self.inherentMethods.get(typeName) orelse return false;
        return set.contains(method);
    }

    /// Store the resolved signature of `typeName.method` (self-first FnType).
    pub fn setInherentMethodType(self: *Env, typeName: []const u8, method: []const u8, ty: *T.Type) !void {
        const gop = try self.inherentMethodTypes.getOrPut(typeName);
        if (!gop.found_existing) gop.value_ptr.* = std.StringHashMap(*T.Type).init(self.arena);
        try gop.value_ptr.put(method, ty);
    }

    /// The resolved signature of `typeName.method`, if one was registered.
    pub fn getInherentMethodType(self: *Env, typeName: []const u8, method: []const u8) ?*T.Type {
        const set = self.inherentMethodTypes.get(typeName) orelse return null;
        return set.get(method);
    }

    pub fn isActivated(self: *Env, name: []const u8) bool {
        return self.activations.contains(name);
    }

    // ── type constructors ─────────────────────────────────────────────────────

    /// Allocate a fresh unbound type variable at the current level.
    pub fn freshVar(self: *Env) !*T.Type {
        const id = self.nextId;
        self.nextId += 1;
        const cell = try self.arena.create(T.TypeCell);
        cell.* = .{ .state = .{ .unbound = .{ .id = id, .level = self.level } } };
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .typeVar = cell };
        return ty;
    }

    /// Allocate a named type with zero type arguments.
    pub fn namedType(self: *Env, name: []const u8) !*T.Type {
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .named = .{ .name = name, .args = &.{} } };
        return ty;
    }

    /// Allocate a named type with the given type arguments (args are copied).
    pub fn namedTypeArgs(self: *Env, name: []const u8, args: []const *T.Type) !*T.Type {
        const argsCopy = try self.arena.dupe(*T.Type, args);
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .named = .{ .name = name, .args = argsCopy } };
        return ty;
    }

    /// Allocate a union type (types slice is used as-is ---- caller ensures lifetime).
    pub fn unionType(self: *Env, types: []*T.Type) !*T.Type {
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .union_ = types };
        return ty;
    }

    /// Allocate a function type (params slice is copied).
    pub fn funcType(self: *Env, params: []const *T.Type, ret: *T.Type) !*T.Type {
        const paramsCopy = try self.arena.dupe(*T.Type, params);
        const ty = try self.arena.create(T.Type);
        ty.* = .{ .func = .{ .params = paramsCopy, .ret = ret } };
        return ty;
    }

    // ── bindings ──────────────────────────────────────────────────────────────

    pub fn lookup(self: *Env, name: []const u8) ?*T.Type {
        return self.bindings.get(name);
    }

    pub fn bind(self: *Env, name: []const u8, ty: *T.Type) !void {
        try self.bindings.put(name, ty);
    }

    pub fn lookupTypeDef(self: *Env, name: []const u8) ?TypeDef {
        return self.typeDefs.get(name);
    }

    /// Record the typeparam constraints for a function (keyed by name).
    pub fn registerTypeparams(self: *Env, name: []const u8, constraints: []const TypeparamConstraint) !void {
        try self.fnTypeparams.put(name, constraints);
    }

    /// Look up the typeparam constraints for a function, or null if it has none.
    pub fn lookupTypeparams(self: *Env, name: []const u8) ?[]const TypeparamConstraint {
        return self.fnTypeparams.get(name);
    }

    /// Record the `expr` meta-kind params for a function (keyed by name).
    pub fn registerExprParams(self: *Env, name: []const u8, params: []const ExprParamInfo) !void {
        try self.fnExprParams.put(name, params);
    }

    /// Look up the `expr` params for a function, or null if it has none.
    pub fn lookupExprParams(self: *Env, name: []const u8) ?[]const ExprParamInfo {
        return self.fnExprParams.get(name);
    }

    pub fn registerTypeDef(self: *Env, name: []const u8, def: TypeDef) !void {
        try self.typeDefs.put(name, def);
    }

    /// Allocate a unique type definition ID (monotonically increasing).
    pub fn allocTypeId(self: *Env) usize {
        const id = self.nextTypeId;
        self.nextTypeId += 1;
        return id;
    }

    // ── builtins ──────────────────────────────────────────────────────────────

    /// Register the primitive built-in types so they can be looked up by name.
    pub fn registerBuiltins(self: *Env) !void {
        const primitives = [_][]const u8{
            // integer types
            "i8",  "u8",  "i16",  "u16",    "i32",  "u32",  "i64",  "u64", "isize", "usize",
            // float types
            "f32", "f64",
            // other primitives
            "bool", "string", "void", "v128",
            // special
            "Self",
        };
        for (primitives) |p| {
            const ty = try self.namedType(p);
            try self.bind(p, ty);
        }
        // Built-in functions bound with placeholder void type.
        // These are runtime functions — actual types are resolved during codegen.
        try self.bind("print", try self.namedType("void"));
        try self.bind("println", try self.namedType("void"));
    }

    // ── level management ──────────────────────────────────────────────────────

    pub fn enterLevel(self: *Env) void {
        self.level += 1;
    }

    pub fn exitLevel(self: *Env) void {
        self.level -= 1;
    }

    // ── type name resolution ──────────────────────────────────────────────────

    /// Resolve a string type name (from AST) to a *Type.
    /// Generic parameters are looked up in `genericMap` first.
    pub fn resolveTypeName(
        self: *Env,
        name: []const u8,
        genericMap: std.StringHashMap(*T.Type),
    ) !*T.Type {
        // Generic parameters bound in the current function/type
        if (genericMap.get(name)) |ty| return ty;
        // Registered user-defined types
        if (self.typeDefs.contains(name)) return self.namedType(name);
        // Primitive / built-in names
        if (self.bindings.get(name)) |ty| {
            // A name bound to a *constructor function* (`fn(fields…) -> Name`)
            // names a nominal type in annotation position, not a value. This is
            // the case for an imported record/struct/enum: the import binds its
            // constructor as a value, but the type definition lives in the
            // defining module, so the `typeDefs` check above missed it here.
            // Resolve to the named type the constructor builds, so it unifies
            // with the same nominal type as seen by the defining module.
            const d = ty.deref();
            if (d.* == .func and d.func.ret.isNamed(name)) {
                return self.namedType(name);
            }
            return ty;
        }
        // Fallback: treat as an opaque named type (forward reference, etc.)
        return self.namedType(name);
    }
};
