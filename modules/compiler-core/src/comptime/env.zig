/// Type inference environment for the botopink type checker.
///
/// All Type/TypeCell allocations go through `arena`. The caller owns an
/// ArenaAllocator and frees it after type-checking is complete.
const std = @import("std");
const ast = @import("../ast.zig");
const reflectionMod = @import("reflection.zig");
const hooksMod = @import("hooks.zig");
const memberFnMod = @import("member_fn.zig");
const T = @import("./types.zig");
const template = @import("./template.zig");
const trace = @import("./trace.zig");

// ── type definitions ──────────────────────────────────────────────────────────

/// What `Env.aliasedWrapper` answers: the alias the source wrote and the
/// builtin wrapper (`"Result"`, `"Task"`, …, without `@`) it expands to.
pub const AliasedWrapper = struct {
    alias: []const u8,
    wrapper: []const u8,
};

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
        /// §1G — resolved default for each generic param (`null` when no
        /// `IDENT = TypeRef` was supplied). Same length as `genericParams`;
        /// fed into `resolveTypeRefInContext` to fill trailing-omitted args.
        genericDefaults: []const ?*T.Type = &.{},
        fields: []FieldDef,
        implements: []const []const u8 = &.{},
        /// True when this type implements the marker `@Renderable` (decision
        /// 354): a `@Component<R>` with this `R` is a component, not a hook.
        renderable: bool = false,
    };

    pub const Struct = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        /// §1G — resolved default for each generic param (`null` when none).
        genericDefaults: []const ?*T.Type = &.{},
        fields: []FieldDef,
        implements: []const []const u8 = &.{},
        /// True when this type implements the marker `@Renderable` (decision
        /// 354): a `@Component<R>` with this `R` is a component, not a hook.
        renderable: bool = false,
    };

    pub const Enum = struct {
        name: []const u8,
        id: usize,
        genericParams: []const []const u8,
        /// §1G — resolved default for each generic param (`null` when none).
        genericDefaults: []const ?*T.Type = &.{},
        variants: []VariantDef,
        implements: []const []const u8 = &.{},
        /// True when this type implements the marker `@Renderable` (decision
        /// 354): a `@Component<R>` with this `R` is a component, not a hook.
        renderable: bool = false,
    };

    /// True when this type implements `@Renderable` (decision 354).
    pub fn isRenderable(self: TypeDef) bool {
        return switch (self) {
            .record => |r| r.renderable,
            .struct_ => |s| s.renderable,
            .enum_ => |e| e.renderable,
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

    /// §1G — resolved defaults (same length as `genericParams()`). Slots are
    /// `null` when the param carried no default. Used by
    /// `resolveTypeRefInContext` to fill omitted trailing generic args at
    /// user-typeDef call sites (parallel to `builtinDefaultFilledArgs` for
    /// builtin wrappers).
    /// The generic parameters the type declares (`Pair<A, B>` → `A`, `B`).
    pub fn genericParams(self: TypeDef) []const []const u8 {
        return switch (self) {
            .record => |r| r.genericParams,
            .struct_ => |s| s.genericParams,
            .enum_ => |e| e.genericParams,
        };
    }

    pub fn genericDefaults(self: TypeDef) []const ?*T.Type {
        return switch (self) {
            .record => |r| r.genericDefaults,
            .struct_ => |s| s.genericDefaults,
            .enum_ => |e| e.genericDefaults,
        };
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

/// The declaration a type import item resolved to (`Env.importedTypeDecls`).
pub const ImportedTypeDecl = struct {
    /// The type's declared name (the item's leaf).
    name: []const u8,
    /// The module path that declares it (`catalog`, `srv/app`).
    module: []const u8,
};

// ── @Component capability scope ───────────────────────────────────────────────────

/// Capability information about the function body currently being inferred.
///
/// The function's return type decides whether `use` is allowed inside the body:
/// it must be `@Component<R>` (decisions 102, 128, 354). `null` on the
/// environment means no function body is currently being inferred (top-level
/// position).
pub const FnContext = struct {
    /// True when the function's return type is `@Component<R>`.
    implementsContext: bool,
    /// Rendered return type, used in the "`use` not allowed" diagnostic.
    returnDisplay: []const u8 = "void",
    /// True when the enclosing fn's return is `@Component<R>` — and only
    /// then (decisions 104, 118, 128, 354). It is the same flag as
    /// `Env.inContextFn`. A `use` in any other body is
    /// `useWithoutContextEffect`, which names the return to write.
    annotated: bool = false,
    /// The enclosing fn's name, for that diagnostic.
    fnName: []const u8 = "",
    /// Decision 354 — true when the return is `@Component<R>` with an `R` that
    /// implements `@Renderable`: a component, whose body may `use provide`.
    renderable: bool = false,
};

/// Decision 354 — what a name imported from std's `context` module declares.
pub const StdContextName = enum { context_type, provide, context };

/// Decision 354 (8) — a call recorded for the hidden context map: its value's
/// type and the callee it names. The lowering matches the callee too, since a
/// template's built code can share a location with another expansion's
/// (`language-gaps.md`, "Two template expansions in one module share the
/// locations of their built code").
pub const ComponentCall = struct { type_: *T.Type, callee: []const u8 };

/// Decision 371 — one `d.same(other)` on a `Decorator`: `other` is the
/// identity (`declIdentity`) of the decorator the argument names, or null when
/// the argument is a `Decorator` value (`b.decorator`) read as written.
pub const DecoratorSame = struct { other: ?[]const u8 };

/// Decision 372 — a `@typeInfo(X).meta.<decorator>.<key>` read of this
/// module's `X` whose decorator reads `.hooks` and had not run when the read
/// was inferred: `rewrite` is the string literal `srcRewrites` holds at `loc`,
/// filled once the decorator ran (`infer.zig` `answerDeferredMetaReads`).
pub const DeferredMetaRead = struct {
    loc: ast.Loc,
    rewrite: *ast.Expr,
    module: []const u8,
    name: []const u8,
    decorator: []const u8,
    key: []const u8,
};

/// Decision 354 (8) — a lambda recorded for the hidden context map: its type
/// and its parameter count (matched as `ComponentCall.callee` is).
pub const ComponentLambda = struct { type_: *T.Type, params: usize };

/// Decision 375 — the declaration a call or a `use` names, with the call's
/// type (null for a `use`, whose operand is a hook): only a call whose type
/// resolved to `@Component<R>` is one commonJS may leave unawaited.
pub const HookTarget = struct { ref: hooksMod.DeclRef, type_: ?*T.Type };

/// Decision 354 (8) — one `use provide(ctx, value)` / `use context(ctx)`:
/// which hook, the context's identity (`declIdentity` of the `val` that
/// declares it — the run-time key of the hidden map) and the `T` it carries.
pub const ContextUse = struct {
    kind: enum { provide, read },
    key: []const u8,
    /// The context's name as written, for the run-time `context-unbound`.
    name: []const u8,
    value_type: *T.Type,
};

/// How `throw` should be type-checked in the current function scope.
///
/// Set by `inferFnDecl` when entering a named function body and reset to
/// `.unchecked` inside nested function expressions (lambdas have no declared
/// return type). `inferJumpExpr` reads it to validate `throw` statements.
pub const ThrowContext = union(enum) {
    /// No declared return type (top-level or lambda) — `throw` is left unchecked.
    unchecked,
    /// The enclosing fn's return carries `@Result<D, E>` in some layer (the
    /// fallible channel, decision 121) — a thrown value must unify with `E`.
    result: *T.Type,
    /// Enclosing fn's declared return carries no `@Result` — `throw` / `try`
    /// are illegal.
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
/// `Env.namespaces` — what the transform needs to write `jwt.sign(x)` as a
/// call of an imported function: each qualified call's loc names its
/// namespace and function (`calls`), and every namespace import item is
/// replaced by one aliased leaf per function called through it
/// (`ns.aliasFor`), which every backend already lowers.
pub const NamespaceImports = struct {
    /// Bound name → the imported module's exports.
    modules: std.StringHashMapUnmanaged(std.StringHashMap(*T.Type)) = .empty,
    /// Bound name → the imported module's path (`@typeInfo(models.City)`
    /// reflects `City` of that module — decision 216).
    paths: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// Call loc → the namespace and the function it calls.
    calls: std.AutoHashMapUnmanaged(ast.Loc, Call) = .empty,
    /// `"<namespace>\x00<function>"` → the function's parameters as written
    /// (the exporting module's `defaultParamsKey` entry), so `ns.f(b: 1, a: 2)`
    /// is checked and lowered by label and a short call is filled (C-04).
    params: std.StringHashMapUnmanaged([]const ast.Param) = .empty,
    /// `00 · 01-std` — an imported name the import resolves to two modules'
    /// declarations (a bare `import {parse};` over two modules declaring
    /// `pub fn parse`): local name → the declaring module paths, sorted. The
    /// name is left unbound, `infer.unboundAt` refuses each use of it, located,
    /// naming the modules, and `transform.rewriteNamespaceImports` drops the
    /// item — an import no use reads is no refusal.
    ambiguous: std.StringHashMapUnmanaged([]const []const u8) = .empty,

    pub fn paramsKey(arena: std.mem.Allocator, namespace: []const u8, callee: []const u8) ![]const u8 {
        return std.fmt.allocPrint(arena, "{s}\x00{s}", .{ namespace, callee });
    }

    pub const Call = struct { namespace: []const u8, callee: []const u8 };

    /// The local name a namespace call is rewritten to: an import alias no
    /// source can spell (`$`), so it never collides with a declaration.
    pub fn aliasFor(arena: std.mem.Allocator, namespace: []const u8, callee: []const u8) ![]const u8 {
        return std.fmt.allocPrint(arena, "__bp_ns_{s}__{s}", .{ namespace, callee });
    }
};

/// One name of a template's library bound in the consumer (`Env.templateImports`).
pub const TemplateImport = struct {
    /// The module path the template was declared in.
    owner: []const u8,
    /// The name as that module declares it.
    name: []const u8,
};

/// Decisions 384, 385 — a name another module wrote, bound in this one under
/// `alias` (`templateAlias(module, name)`): a value through the binding and
/// `Env.templateImports`, a type through an import the re-analysis adds.
pub const HygieneImport = struct {
    alias: []const u8,
    module: []const u8,
    name: []const u8,
    isType: bool,
};

/// The key a module's PRIVATE function or value is exported under for its
/// templates' text (decision 112): a NUL no source name contains, so no
/// `import` can reach it.
pub fn templatePrivateKey(arena: std.mem.Allocator, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "\x00tpl\x00{s}", .{name});
}

/// The alias a name of the template module `owner` is bound under in a
/// consumer (decision 112, `Env.templateImports`): `__bp_tpl_<owner>__<name>`,
/// the owner's path with every non-alphanumeric byte as `_`. One spelling for
/// the built code's names (`infer.applyDslHygiene`), the functions a
/// `comptime` carries for them (`comptime.zig` `importTemplateSupport`) and
/// the constructor of a lifted record (`block_eval.zig`).
pub fn templateAlias(arena: std.mem.Allocator, owner: []const u8, name: []const u8) ![]const u8 {
    var mangled: std.ArrayListUnmanaged(u8) = .empty;
    for (owner) |ch| try mangled.append(arena, if (std.ascii.isAlphanumeric(ch)) ch else '_');
    return std.fmt.allocPrint(arena, "__bp_tpl_{s}__{s}", .{ mangled.items, name });
}

/// A declaration's identity as `lookup` answers it (decision 112):
/// `<module path>@@<Decl>` with the path's `/` written `@` — a dependency's
/// module path starts with its package (`shapesdsl/shapesdsl` →
/// `shapesdsl@shapesdsl@@area`, decision 109). A root-package module's path
/// carries no package here: the checker is not told the root package's name
/// (`decisions-pending.md` 01c-a), so its identity starts at the path.
pub fn declIdentity(arena: std.mem.Allocator, modulePath: []const u8, name: []const u8) ![]const u8 {
    const path = if (modulePath.len == 0) "main" else modulePath;
    const out = try std.fmt.allocPrint(arena, "{s}@@{s}", .{ path, name });
    for (out[0..path.len]) |*ch| if (ch.* == '/') {
        ch.* = '@';
    };
    return out;
}

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

/// Context active while inferring the body of an effect fn (a return of
/// `@Result`, `@Task`, `@Component`, `@Iterator` or `@Stream`, decision 118)
/// or of a prefixed `iter` / `stream` loop. Drives validation of `await` and
/// `yield`; `null`
/// inside normal functions and at the top level. (The type keeps its
/// historical name `StarFnCtx` for the field on `Env`; the `*fn` prefix it
/// alludes to was removed in v0.beta.19.)
pub const StarFnCtx = struct {
    /// `await` is permitted here — `@Task`, `@Component` or `@Stream`.
    allowsAwait: bool,
    /// `yield` is permitted here — `@Iterator` / `@Stream`.
    allowsYield: bool,
    /// `@Iterator<T>` / `@Stream<T>` item type that `yield <v>` AND
    /// `break <v>` values unify with (decision 122: `break v` emits `v` and
    /// ends — the last item is an item like the others, there is no
    /// completion channel); `null` when unknown or absent (`@Task`). When it
    /// is `@Result<U, E>`, a `U` is wrapped `Ok(v)`.
    iterItem: ?*T.Type,
    /// The label declared on the fn signature (`fn … -> @Iterator<T> :name`),
    /// used to scope `break :name` to the generator vs. an enclosing loop.
    /// Drives the §1I REGRAS DE ESCOPO disambiguation in the `.@"break"`
    /// type-checker.
    fnLabel: ?[]const u8,
    /// The specific effect kind this context was built from. Drives effect-
    /// specific rejections (RI* only inside `@Iterator` / `@Stream`, etc.).
    effect: ast.EffectKind,
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
    /// A method on a named type (record or enum) — the type's name.
    type_: []const u8,
    /// A field READ on a record or struct — the receiver's type name. Recorded
    /// for `p.x` where `x` is a declared field, which is what the backends that
    /// store a record positionally (13-module-identity's decision 21: erlang
    /// and beam store `{TypeAtom, F1, …}`) need to turn the field's NAME into
    /// its index. A method call records `.type_`; only a field read records
    /// this, so a backend that dispatches natively can ignore it.
    field_of: []const u8,
    /// Decision 122 — `seq.next()` called by hand on an `@Iterator<T>`
    /// (answers `YieldStep<T>`) or a `@Stream<T>` (answers
    /// `@Task<YieldStep<T>>`). commonJS maps the generator's `{ value, done }`
    /// onto the variants; the eager backends (erlang, beam, wasm), whose
    /// sequence is the list of its items, pop the head and rebind the receiver
    /// to the rest when it is a local name.
    sequence_next: SequenceKind,
    /// An arithmetic operator's result type, keyed by its operator's loc —
    /// `+`, `-`, `*`, `/`, `%`, a unary `-`, and a `+=` (keyed by its
    /// binding's loc). The tag keeps the name of its first reader: onze F7's
    /// `/`, which truncates toward zero and answers an integer over integers on
    /// every backend, and divides as floats over floats. Decision 264 reads
    /// the integer kinds for every operator: the result is checked against the
    /// type's range and aborts outside it (`ArithKind.range`). Absent when the
    /// operands' type was never resolved (a generic `T`); a backend then keeps
    /// its own reading, unchecked.
    division: ArithKind,
    /// A method call the VALUE answers, for a backend without native dispatch
    /// — the receiver's type name: its static type is a `behavior` declaring
    /// the method without a body, so the implementation is whichever type
    /// implements it, or a host-built value.
    by_value: []const u8,
    /// A method call on a nominal type this module has no declaration of — a
    /// `Dict` answered by an imported fn, whose type was never imported here.
    /// The name only: a backend that finds a record or enum of that name in
    /// the program asks the value, whose tag names its module (decision 21).
    unplaced_type: []const u8,
};

/// The numeric type an `InstanceLowering.division` records: a float, or one
/// of the sized integer types (decision 264).
pub const ArithKind = enum {
    float,
    i8,
    u8,
    i16,
    u16,
    i32,
    u32,
    i64,
    u64,
    isize,
    usize,

    pub fn isInt(k: ArithKind) bool {
        return k != .float;
    }

    /// The type's inclusive range, on every target (commonJS holds the 64-bit
    /// four as a number or a `BigInt`, decision 319). `isize` / `usize` are
    /// `i64` / `u64`, as the `is` test reads them on every target. Null for
    /// `.float`.
    pub fn range(k: ArithKind) ?struct { lo: i128, hi: i128 } {
        return switch (k) {
            .float => null,
            .i8 => .{ .lo = -128, .hi = 127 },
            .u8 => .{ .lo = 0, .hi = 255 },
            .i16 => .{ .lo = -32768, .hi = 32767 },
            .u16 => .{ .lo = 0, .hi = 65535 },
            .i32 => .{ .lo = std.math.minInt(i32), .hi = std.math.maxInt(i32) },
            .u32 => .{ .lo = 0, .hi = std.math.maxInt(u32) },
            .i64, .isize => .{ .lo = std.math.minInt(i64), .hi = std.math.maxInt(i64) },
            .u64, .usize => .{ .lo = 0, .hi = std.math.maxInt(u64) },
        };
    }
};

/// Which sequence a `.next()` (`InstanceLowering.sequence_next`) steps.
pub const SequenceKind = enum { iterator, stream };

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
/// One member a decorator body added to a type (`decl.addMember`, decision 216).
pub const MemberContribution = struct {
    /// The type the member joins — its name in this module.
    target: []const u8,
    /// The member's botopink source, as the body wrote it.
    source: []const u8,
    /// The annotation that ran the decorator: every refusal about the member
    /// is located here.
    loc: ?ast.Loc,
    /// The decorator as the annotation spells it (`entity`, `mocks.mock`).
    decorator: []const u8,
};

/// One associated type a decorator body declared (`decl.addType`, decision 216).
pub const TypeContribution = struct {
    /// The owner — the annotated type, or the type owning the annotated member.
    owner: []const u8,
    /// The associated type's own name (`Columns` in `City.Columns`).
    name: []const u8,
    /// Its shape, as it follows the name in a declaration (`(id: string)`).
    source: []const u8,
    loc: ?ast.Loc,
    decorator: []const u8,
};

/// The top-level name an associated type is declared under: `City.Columns`
/// is `City__Columns`. Not an enum section's `__Token__Text`: the backends
/// read that mangling as "a section of the enum `Token`" and take the outer
/// enum's module for the value's tag (`erlang.zig` `typeOwnerPath`), which an
/// associated type of a `behavior` does not have. A module declaring the
/// mangled name itself is refused where the type is added
/// (`decorator-type-duplicate`).
pub fn assocTypeName(arena: std.mem.Allocator, owner: []const u8, name: []const u8) ![]const u8 {
    return std.fmt.allocPrint(arena, "{s}__{s}", .{ owner, name });
}

/// Decision 252 — one builtin's declared signature (`Env.builtinDecls`).
pub const BuiltinDecl = struct {
    genericParams: []const ast.GenericParam,
    params: []const ast.Param,
    returnType: ?ast.TypeRef,
};

/// What a template module carries beside the template, or why it cannot be
/// built (`infer.Support`, stored per imported template).
pub const ComptimeSupport = struct {
    fns: []const ast.FnDecl,
    conflict: ?[]const u8 = null,
};

/// Decision 280 — one decorator parameter's value as the body receives it.
pub const DecoratorArgValue = struct {
    /// The value as botopink source.
    source: []const u8,
    /// Built by a function of the decorator module — an array, a record, a
    /// variant, a field key, `null` — rather than handed over as a literal
    /// term (a string, a number, a `bool`).
    built: bool,
    /// Decision 364 — the argument is not known while the program compiles
    /// and the body never reads the parameter: nothing is built, the body
    /// receives `undefined`.
    absent: bool = false,
    /// Where the argument is written; null for a default. `x.fail(…)`
    /// reports there (decision 364 (3)).
    loc: ?ast.Loc = null,
    /// Decision 370 (2) — the expression as the annotation wrote it (a
    /// default as the decorator declared it): what a member function the
    /// decorator hands to `decl.addMember(name, fn…)` reads in its place.
    lexeme: []const u8 = "",
};

pub const DecoratorSig = struct {
    params: []const ast.Param,
    fn_decl: ?ast.FnDecl = null,
    /// The leading parameter's type — `@Decl` or `@Decl<P>` (decision 280
    /// (2)); null for an annotation type (`implement @Annotation`).
    decl: ?ast.TypeRef = null,
    /// The decorator's type parameters (`fn check<T>(…)`), bound per
    /// application by `@Decl<P>` and the arguments.
    generics: []const ast.GenericParam = &.{},
    /// The functions of the decorator's own module its body calls, directly
    /// or through one another (`infer.decoratorSupport`) — compiled into the
    /// decorator module beside it. Filled for an IMPORTED decorator; a local
    /// one computes it from `Env.fnDecls` when it runs.
    support: []const ast.FnDecl = &.{},
    /// Why the imported decorator's module cannot be built (`infer.Support`):
    /// two functions it reaches share a name. Refused where it is applied.
    conflict: ?[]const u8 = null,
};

/// A type-directed lowering for a `return`/`throw`/`yield`/`break` jump inside
/// a body whose return carries a `@Result<D, E>` layer (decisions 119, 121,
/// 122). Recorded by inference keyed by the jump's source `Loc` and consumed by
/// the transform pass, which wraps the value in a `__bp_ok(…)` /
/// `__bp_error(…)` builtin call so every backend materialises the same
/// `{ok, V}` / `{error, E}` Result value:
///   - `wrap_ok`            — `return v` → `return __bp_ok(v)`
///   - `wrap_error`         — `throw e` → `return __bp_error(e)`
///   - `unwrap_passthrough` — `return try f()` → `return f()` (unwrap then
///                            re-wrap is the identity)
///   - `yield_ok`           — in an `@Iterator<@Result<U, E>>` / `@Stream<…>`
///                            scope, `yield v` / `break v` with `v: U` →
///                            `yield __bp_ok(v)` / `break __bp_ok(v)`
///   - `break_error`        — in that scope, `throw e` → `break __bp_error(e)`:
///                            the error is the last item and the sequence ends
pub const ResultJumpLowering = enum { wrap_ok, wrap_error, unwrap_passthrough, yield_ok, break_error };

/// What the nearest enclosing construct does with a `break` (decision 105 and
/// decision 2): a loop leaves it; a `comptime { … }` block and a `case` arm's
/// block take `break <value>` as their value; nothing else takes a bare
/// `break`, and a `break <value>` anywhere else needs a generator scope.
pub const BreakScope = enum { none, loop, valueBlock };

/// See `Env.stdTargetGates`.
pub const StdTargetGate = struct {
    module: []const u8,
    loc: ast.Loc,
};

pub const Env = struct {
    /// Arena allocator ---- all Type and TypeCell nodes are allocated here.
    arena: std.mem.Allocator,
    /// Value bindings: variable/function name → *Type.
    bindings: std.StringHashMap(*T.Type),
    /// The names whose most recent binder was a `val` (decision 38). `bind`
    /// clears a name — a `var`, a parameter, a pattern may all be assigned;
    /// `bindVal` sets it — and an assignment to a set name is refused.
    /// 01 R8 — the bindings that hold a TYPE rather than a value
    /// (`val T = i32;`, `val U = T;`). `resolveTypeName`'s bindings arm
    /// accepts these, a primitive and an imported constructor, and refuses
    /// every other binding: `val n = 5; val x: n = 7;` names a value.
    typeValueNames: std.StringHashMap(void),
    valNames: std.StringHashMap(void),
    /// The `var`s a condition has narrowed in the scope being walked, by name
    /// → the type the `var` was declared with. An assignment to a narrowed
    /// `var` is checked against that declared type (`x = x.next` inside
    /// `while (x != null)` assigns a `?Node`) and ends the narrowing: the name
    /// takes its declared type back for the rest of the scope.
    narrowedDecl: std.StringHashMapUnmanaged(*T.Type) = .empty,
    /// Front 17 — every module `var` of this module, by name → its
    /// `@BeamMemory` storage and the type it was bound with. The type pointer
    /// is how an assignment tells the module binding from a local that
    /// shadows it (`lookup(name)` answers the local's type then). Read by
    /// `infer.zig`'s `refuseMemoryWrite`.
    memoryVars: std.StringHashMapUnmanaged(MemoryVar) = .empty,
    /// Decision 168 — where a `keyed = true` module `var` may be named: the
    /// receiver of its row read `name.at(key)` or of its row write
    /// `name = name.insert(key, value)`, by the identifier's loc. Any other
    /// read of the binding is refused (`infer.zig` `refuseKeyedWholeRead`).
    keyedRowAccess: std.AutoHashMapUnmanaged(ast.Loc, void) = .empty,
    /// Decision 167 — the first `#[@BeamMemory]` annotation of a module whose
    /// `target` is not the BEAM; `infer.zig` `reportOffBeamMemory` refuses it
    /// once the module is inferred.
    offBeamMemory: ?ast.Loc = null,
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
    /// C-01 (13 half 1, step 5) — the module path each comptime-evaluated
    /// declaration (a template fn, a decorator with a body) was DECLARED in,
    /// keyed by the declaration's identity: the address of its body, which the
    /// defining module and every importer share because the registry hands the
    /// same `ast.FnDecl` across. A name is not an identity here — two modules
    /// may export a template of one name. Read by `comptimeOwnerOf` when the
    /// evaluator names its module atom (`bp@comptime@<path>__tpl__<decl>__<hash>`).
    comptimeOwners: std.AutoHashMap(usize, []const u8),
    /// 01 step 12 — every enum variant's constructor under its QUALIFIED name
    /// (`Shape.Circle`). The bare name is also bound in `bindings`, one flat
    /// table in which the last enum to declare a name wins; a written
    /// qualification is answered from here, so it cannot be overridden by
    /// another enum that declares the same variant.
    variantCtors: std.StringHashMap(*T.Type),
    /// 01 step 12 — bare variant name → every enum declaring it, in
    /// declaration order. Two or more claimants make the bare name ambiguous:
    /// a use that relies on the flat table is refused naming them.
    variantClaims: std.StringHashMap([]const []const u8),
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
    /// `@src().file` (1.0.10-beta decision 73): the display path of the file being
    /// inferred, relative to its package root, extension included
    /// (`src/emilia.bp`). Set by `comptime.zig` from `Module.srcPath`, or from
    /// `<name>.bp` when the driver did not supply one (tests, LSP).
    srcPath: []const u8 = "",
    /// `@src().fnName`: the name of the declaration whose body is being inferred
    /// — the fn name, `Type.method` for a method, the test name (or `test_<idx>`)
    /// inside a `test` block, `""` at module level. A lambda does not change it.
    currentFnName: []const u8 = "",
    /// Decision 364 — the parameters of the function whose body is being
    /// inferred: a `comptime x: @Expr<T>` among them (`Param.exprWrapped`) is
    /// read `x.value`, never `.value` of a type, and answers no other method
    /// but a decorator's `.fail(…)`.
    currentParams: []const ast.Param = &.{},
    /// `@src()` rewrites (decision 73): call-site location → the untyped
    /// `SourceLocation(file: …, line: …, column: …, fnName: …)` constructor call
    /// the transform pass splices in its place, so every backend lowers the
    /// builtin through its ordinary record-constructor path. Separate from
    /// `templateExpansions` so the comptime snapshot's "spliced program" trigger
    /// (`template_expansions > 0`) is not fired by a source location.
    srcRewrites: std.AutoHashMap(ast.Loc, *const ast.Expr),
    /// True once the module referenced the builtin `SourceLocation` record
    /// (`@src()` or a hand-written constructor / annotation). `comptime.zig`
    /// then prepends the record's declaration to the transformed program so the
    /// backends learn its field list the way they learn a user record's.
    usesSourceLocation: bool = false,
    /// True once the module referenced the prelude enum `YieldStep<T>`
    /// (decision 122 — an annotation, or a `.next()` called by hand on an
    /// `@Iterator` / `@Stream`). `comptime.zig` then prepends the enum's
    /// declaration to the transformed program, exactly as `usesSourceLocation`
    /// does for the record, so every backend builds and matches `Yield(value)`
    /// / `Done` through the enum path it already has.
    usesYieldStep: bool = false,
    /// E3.9 — where a `@Result` value came from, keyed by the (fresh) type
    /// node inference gave it: an `await`, a `for` item, or the `try` /
    /// `throw` that made an `async { }` block's value or an `iter` / `stream`
    /// item one. `unify.zig` copies it onto a `typeMismatch` whose `got` side
    /// is that node, and the hint names the fix for that source.
    resultOrigins: std.AutoHashMapUnmanaged(*T.Type, @import("error.zig").ResultOrigin) = .empty,
    /// Ordinal of the next `test` block in program order — the `test_<idx>`
    /// fallback name of an anonymous `test { … }` (the same index the commonJS
    /// registry uses). Reset by `inferProgram`/`inferProgramTyped`.
    testIndex: usize = 0,
    /// True while inferring the body of a template function (`-> @Expr<…>`).
    /// Gates the `@expr`/`@code` construction builtins.
    inTemplateFn: bool = false,
    /// Decision 354 (3) — true while inferring a decorator's body (a fn whose
    /// first parameter is `comptime _: @Decl`): compile-time evaluation with
    /// no render tree, where `use` is refused (`use-outside-render-tree`).
    inDecoratorFn: bool = false,
    /// Decision 370 (2) — the body of the decorator being inferred: a member
    /// function it hands to `decl.addMember(name, fn…)` reads none of its
    /// locals (`infer.zig` `inferMemberFnCall`). Null outside a decorator.
    decoratorBody: ?[]const ast.Stmt = null,
    /// Decision 370 (2) — the typed function expression `inferMemberFnCall`
    /// admits; every other typed one is `fn-expr-typed` at it.
    memberFnAt: ?ast.Loc = null,
    /// Decision 354 (3) — the number of `comptime { … }` / `comptime <expr>`
    /// enclosing the position being inferred; `use` is refused inside one.
    comptimeDepth: u32 = 0,
    /// Decision 354 — the local names an import from std's `context` module
    /// binds, by the declaration each one names: the type `Context<T>` and
    /// the two hooks `provide` / `context`, which the compiler lowers.
    stdContextNames: std.StringHashMapUnmanaged(StdContextName) = .empty,
    /// Decision 354 — where the body of the `@Component<R>` fn being inferred
    /// first renders a component (a call `inferComponentCall` answers with its
    /// `R`): a `use provide(…)` after it is refused, since the child rendered
    /// before it would not see the value. Null until one renders; saved and
    /// restored around each fn body.
    firstRenderAt: ?ast.Loc = null,
    /// Decision 357 — the construct enclosing the position being inferred
    /// that makes a `use` there conditional or repeated (an `if` / `else`,
    /// a loop, a lambda, …): a `use` is written at the top level of a
    /// `@Component` body only. Null at the body's top level; set by the
    /// outermost such construct and restored on its way out.
    useConstruct: ?[]const u8 = null,
    /// Decision 357 — the line of the first top-level statement of the body
    /// being inferred that may leave it early (`return`, `throw`, a bare
    /// `try`): a `use` after it does not run on every call. Saved and
    /// restored around every function and lambda body.
    earlyExitLine: ?usize = null,
    /// Decision 354 — the location of the `use` that is the whole statement
    /// being inferred, if one is: `use provide(…)` stands only there.
    useStatementLoc: ?ast.Loc = null,
    /// Decision 354 (2) — the value location of the module-level `val` whose
    /// initializer is being inferred: the one place `Context<T>()` may be
    /// written (a context's identity is its declaration).
    contextDeclSite: ?ast.Loc = null,
    /// Decision 354 — the module-level `val`s of this module declared
    /// `= Context<T>()`, by name.
    declaredContexts: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 354 (8) — each `use provide(…)` / `use context(…)`, by the
    /// `use`'s location: what the hidden context map lowers it to.
    contextUses: std.AutoHashMapUnmanaged(ast.Loc, ContextUse) = .empty,
    /// Decision 277 — the hook node of the top-level function whose body is
    /// being inferred (`hooks.zig`): each `use` and each `@Component` call
    /// written in it, lambdas included. Null outside such a body.
    hookBuilder: ?*hooksMod.Builder = null,
    /// Decision 277 — the node of each top-level function of this module whose
    /// body has been inferred, by name; published to the session
    /// (`Reflection.hookFns`) when the analysis ends.
    hookNodes: std.StringHashMapUnmanaged(hooksMod.Node) = .empty,
    /// Decision 375 — the declaration each call of a `@Component` function
    /// and each `use` of a declared hook names, by the call's (the `use`'s)
    /// location, wherever it is written: whether the target's node is
    /// synchronous decides whether commonJS awaits it.
    hookTargets: std.AutoHashMapUnmanaged(ast.Loc, HookTarget) = .empty,
    /// Decision 375 — this module's top-level functions whose node is
    /// synchronous (`infer.zig` `markHookAsync`): commonJS emits a plain
    /// `function` for one answering `@Component<R>`.
    syncFns: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 375 — the calls and `use`s (by `hookTargets`' location) whose
    /// target's node is synchronous: commonJS emits no `await` there.
    syncCalls: std.AutoHashMapUnmanaged(ast.Loc, void) = .empty,
    /// Decision 371 — each `d.same(other)` on a `Decorator` this module's
    /// inference typed, by the call's location (`infer.zig`
    /// `inferDecoratorSame`): the comptime runtime reads it as `==` of two
    /// identities (`decorator_same.zig`).
    decoratorSame: std.AutoHashMapUnmanaged(ast.Loc, DecoratorSame) = .empty,
    /// Decision 371 — this module's functions a decorator of it runs, inferred
    /// ahead of the run so its `same` calls are typed (by body pointer).
    decoratorBodiesChecked: std.AutoHashMapUnmanaged(usize, void) = .empty,
    /// Decision 371 — the module's imports and `val`s were bound ahead of
    /// Pass 2 for a decorator body inferred before its run.
    earlyValsBound: bool = false,
    /// Decision 372 — `"<declaration>\x00<decorator>"` for each annotation of
    /// a top-level declaration of this module whose decorator reads `.hooks`
    /// (`infer.zig` `noteHooksReaders`): such a decorator runs after Pass 2,
    /// so a `@typeInfo(X).meta.<decorator>.<key>` read inferred before it ran
    /// is answered once it has (`deferredMetaReads`).
    hooksReaders: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 372 — the identity of each decorator in `hooksReaders`: a
    /// `@TypeInfo.all` listing one is refused (`typeinfo-all-hooks-reader`).
    hooksReaderIds: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 372 — the `.hooks` readers of this analysis have run.
    hooksReadersRan: bool = false,
    /// Decision 372 — the meta reads waiting for a `.hooks` reader of this
    /// module, answered (or refused, `typeinfo-meta-missing`) when it ran.
    deferredMetaReads: std.ArrayListUnmanaged(DeferredMetaRead) = .empty,
    /// Decision 298 — the lines a typed meta read's answer is parsed on, one
    /// per read, past every line of the module (`infer.zig`
    /// `typedMetaRewriteLine`): no node of an answer shares a location with
    /// the module's own code or with another answer.
    typedMetaLines: usize = 0,
    /// Decision 354 (8) — every call whose value is, or may resolve to, a
    /// `@Component<R>`, by location, with that type: the calls that pass the
    /// hidden context map (`context_lower.zig`).
    componentCalls: std.AutoHashMapUnmanaged(ast.Loc, []const ComponentCall) = .empty,
    /// Decision 354 (8) — every lambda, by location, with its type: one that
    /// answers `@Component<R>` takes the hidden context map.
    componentLambdas: std.AutoHashMapUnmanaged(ast.Loc, ComponentLambda) = .empty,
    /// Decision 374 — every call of a host function (a bodyless `declare fn`,
    /// an `#[@External…]` binding — this module's or an imported one), by
    /// location: a `@Component` lambda that is one of its arguments captures
    /// the map where it is written (`context_lower.zig`).
    hostCalls: std.AutoHashMapUnmanaged(ast.Loc, void) = .empty,
    /// Decision 374 — a declared function answering `@Component<R>` named as
    /// an argument of a host call (`__jhTryComponent(Page)`), by the name's
    /// location, with its type: lowered to a lambda that calls it with the
    /// map in scope there.
    hostComponentRefs: std.AutoHashMapUnmanaged(ast.Loc, *T.Type) = .empty,
    /// Decision 354 (8) — the module's functions whose resolved return is
    /// `@Component<R>` (written, or through an alias such as `View`), by name:
    /// the ones that take the hidden context map.
    componentFns: std.StringHashMapUnmanaged(void) = .empty,
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
    /// 06 N30 — the annotation being resolved (`x: Foo` → `Foo`'s column), so an
    /// unknown type name reds at the annotation. Set through `atTypeRef`.
    typeRefLoc: ?ast.Loc = null,
    /// Decision 319 — set while the operand of a unary `-` that is an integer
    /// literal is inferred: the literal's range check reads `-<digits>`, so
    /// `-9223372036854775808l` is `i64`'s minimum, not `2^63` out of range.
    negatingLiteral: bool = false,
    /// 00 · 01-checker — the type the expression at the position being inferred
    /// is expected to produce, when the site knows it: a `val`'s annotation, a
    /// declared parameter, the body's return target, an array literal's element
    /// type. Read by `tryResolveEnumSectionPath` to choose among the enums whose
    /// section tree carries the same path (`.Color.Red.500` on both `Token` and
    /// `__Token__Border`) — the choice used to fall out of `typeDefs`' hash
    /// order. Nothing is unified from here: the site that set the expectation
    /// still unifies the inferred type itself.
    expectedType: ?*T.Type = null,
    /// C10 — annotations whose type name was not known yet when resolved; the
    /// second pass (`checkPendingTypeNames`) reds on the ones still unknown.
    pendingTypeNames: std.ArrayListUnmanaged(PendingTypeName) = .empty,
    /// Builtin `@Result`/`@Option` method calls discovered during inference,
    /// keyed by the call's source location. Drives the AST transform lowering.
    method_lowerings: std.AutoHashMap(ast.Loc, MethodLowering),
    /// `return`/`throw` jumps inside `-> @Result<…>` fns that must construct a
    /// Result value, keyed by the jump's source location. Drives the AST
    /// transform `__bp_ok`/`__bp_error` wrapping.
    result_jump_lowerings: std.AutoHashMap(ast.Loc, ResultJumpLowering),
    /// Decision 118 rule 1 — the effect wrapper an ALIASED return resolves to
    /// (`-> Parser<i32>` with `type Parser<T> = @Result<T, E>`), set while
    /// inferring that body: a capability used in it is
    /// `effect-wrapper-behind-alias`, naming the wrapper to write. Null when
    /// the return is written literally or is no wrapper at all.
    aliasWrapper: ?[]const u8 = null,
    /// Number of `async { }` blocks (decision 124) enclosing the position being
    /// inferred, counted from the nearest lambda. A `use` inside one is refused:
    /// the block is closed like a closure.
    asyncBlockDepth: u32 = 0,
    /// True while inferring a body whose fallible channel's `E` is INFERRED —
    /// an unannotated `async { }` block or an `iter` / `stream` loop with
    /// `throw` / `try` of its own (decisions 124, 125): its `throw` / `try`
    /// errors join one `E`, and two that do not unify are
    /// `gen-infer-conflicting-errors`.
    inferredErrorScope: bool = false,
    /// Capability scope of the function body currently being inferred (null at top level).
    fnContext: ?FnContext = null,
    /// C1 — the type a `return <value>` in the body currently being inferred
    /// must unify with: the declared return type, or an effect wrapper's inner
    /// channel (`@Result<R, E>` → R, `@Task<T>` → T — `U` when `T` is
    /// `@Result<U, E>` —, `@Component<T>` → the `T` of
    /// `@Component<T>`). Null where returns are not checked (no declared
    /// return type, template fns, top level).
    returnTarget: ?*T.Type = null,
    /// C1 — a bare `return;` must unify with `void` (fn decls with a declared
    /// return type; not lambdas, whose target is a shared fresh var).
    returnBareIsVoid: bool = false,
    /// C1 — the fn's whole declared return type, for a returned value that is
    /// already the wrapper (`return state(start)` in a `-> @Component<X>` hook).
    returnWhole: ?*T.Type = null,
    /// C1 — set while inferring a `case` block arm: its `return`s leave the
    /// enclosing fn, so the arm's lambda keeps the fn's return target.
    keepReturnTarget: bool = false,
    /// The generic-param map of the fn body being inferred, so annotations
    /// inside the body resolve `T` to the fn's own generic var.
    fnGenericMap: ?*std.StringHashMap(*T.Type) = null,
    /// C1 — the return targets of the trailing lambdas inferred last, read by
    /// `@block` to type the block as the value its `return`s carry.
    lastTrailingReturnTargets: []*T.Type = &.{},
    /// Decision 2 — where the statement being inferred is an `@block { … }`
    /// written as a whole statement (its value discarded). Set by the
    /// statement loops (`inferStmtsTyped`, `inferBodyStmts`) per statement
    /// and restored after it; the `@block` arm reads it to tell a statement
    /// block from one in value position, which needs a valued `return`.
    statementBlockLoc: ?ast.Loc = null,
    /// Decision 297 — the functions a call of this module passed a type to
    /// (`pick(User)` → `pick__type()`, `value_or_type.zig`): an import of one
    /// brings its type form along (`value_or_type.withTwinImports`).
    typeArgTwins: std.StringHashMapUnmanaged(void) = .empty,
    /// How `throw` is checked in the function body currently being inferred.
    throwContext: ThrowContext = .unchecked,
    /// Active effect-fn context while inferring its body (for `await`/`yield`
    /// rules). The field name is historical — see `StarFnCtx` above.
    starFn: ?StarFnCtx = null,
    /// True while inferring the body of a `-> @Component<R>` fn — the same
    /// question as `FnContext.annotated` (decision 104: one flag, set by the
    /// `@Component` return alone); cleared in a nested closure's and a
    /// prefixed loop's body.
    inContextFn: bool = false,
    /// Labels currently in scope (effect-fn label + enclosing loop labels),
    /// used to validate `yield :label` / `break :label`. Pushed/popped as
    /// scopes nest.
    labelStack: std.ArrayListUnmanaged([]const u8) = .empty,
    /// Number of loops (`for` / `while` / `loop`, the annotated `loop`
    /// included) currently enclosing the position being inferred, counted
    /// from the nearest fn, lambda or annotated-loop body. Read by the
    /// `.@"break"` / `.@"continue"` handlers: a bare `break` inside a loop
    /// leaves the loop and ends the generator only at depth 0; `continue`
    /// needs a loop. `yield` and `break <value>` do not read it (decision
    /// 105): they feed the nearest generator scope through every loop.
    loopDepth: u32 = 0,
    /// Decision 105 / decision 2 — what the nearest enclosing construct does
    /// with a `break`. `.loop` inside a loop body, `.valueBlock` inside a
    /// `comptime { … }` block or a `case` arm's block (where `break <value>`
    /// is the block's value), `.none` at a fn or lambda body.
    breakScope: BreakScope = .none,
    /// Decision 105 — the labels in scope OUTSIDE the nearest enclosing
    /// annotated loop. Its body is closed like a closure: a `break :outer` /
    /// `continue :outer` naming one of these is refused as crossing the
    /// border rather than as unbound.
    closedLabels: []const []const u8 = &.{},
    /// Number of prefixed loops (`iter loop { … }`) enclosing the
    /// position being inferred. Their body runs later, on demand, so a `use`
    /// inside one is refused (decision 105 — the annotated loop is closed).
    generatorLoopDepth: u32 = 0,
    /// The effect the return of the fn whose body is being inferred activates
    /// (decision 118), or null for a plain `fn` (and at module level). Read by
    /// the refusals, which name it.
    fnEffect: ?ast.EffectKind = null,
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
    /// §enum-sections F4 — synthesised inner enum declarations, keyed by mangled
    /// name (`__<EnumName>__<SectionPath>`). Built during F1 desugar alongside
    /// the type-def registration; consumed by the post-inference
    /// `withSynthesisedEnumDecls` pass which prepends them to `program.decls`
    /// so codegen emits each one as a top-level enum (the user-written outer
    /// enum already names its section wrappers via `_inner: __Enum__Section`
    /// payload type — these decls bind the referenced names).
    synthesisedEnumDecls: std.StringHashMap(ast.TypeDecl),
    /// §enum-sections F2 — untyped AST rewrites for a path-access expression
    /// (`.Color.Red.500`). The F2 resolver in `infer.zig` populates this map
    /// keyed by the outermost identAccess loc when the chain matches an
    /// enum-section path; the post-inference `withEnumSectionRewrites` pass
    /// (in `comptime.zig`) walks `program.decls` and substitutes each match
    /// with its qualified-ctor form (`Token.Color(__Token__Color.Red(…))`),
    /// so the codegen — which reads the untyped AST — emits the byte-correct
    /// shape instead of the bare `Color.Red.500` source-text fallback.
    enumSectionRewrites: std.AutoHashMap(ast.Loc, *const ast.Expr),
    /// Decision 8 §6 T4 — every tuple element this module reads by its label
    /// (`row.pop`), keyed by the access's loc, with the element's position.
    /// The transform reads the same fact off `enumSectionRewrites`; a comptime
    /// module is lowered from the untransformed AST, so `template_eval`
    /// `relabelTupleReads` rewrites the functions it carries from here
    /// (an untyped `x.kind` is a map read — `{badmap, {…}}` on a tuple).
    tupleLabelReads: std.AutoHashMapUnmanaged(ast.Loc, usize) = .empty,
    /// C-02 (decision 63, amended 2026-09-19) — the untyped rewrite of an index
    /// expression, keyed by the index node's own loc.
    ///
    /// `xs[k]` **is** `xs.at(k)`, `xs[a..b]` is `xs.slice(a, b)` and `xs[1..]`
    /// is `xs.slice(1, null)`: the index has no typing rule of its own, so
    /// `inferIndexExpr` builds the method call, types THAT, and leaves the call
    /// here for `comptime/transform.zig` to splice. Kept apart from
    /// `enumSectionRewrites` for the reason `srcRewrites` is kept apart from
    /// `templateExpansions`: one channel, one meaning.
    ///
    /// A tuple is the one receiver the `Index<K, V>` behavior cannot express —
    /// it needs a CONSTANT index and answers a type PER POSITION — so its
    /// rewrite is the positional member access every backend already emits
    /// (`t[0]` → `t._0`) rather than a method call.
    indexRewrites: std.AutoHashMap(ast.Loc, *const ast.Expr),
    /// Decision 54 — locs of the `case`s that are the optional's pattern form
    /// (`case x { null { … } v { … } }`), with the binder's name. Inference
    /// validates the shape and narrows the binder; the comptime transform
    /// rewrites the node into the equivalent `if (x) { v -> … } else { … }`,
    /// which is the lowering all four backends already have for an optional.
    /// Nothing below inference learns a new pattern.
    optionalNullCases: std.AutoHashMap(ast.Loc, []const u8),
    /// Interface declarations that expose associated functions (`default fn` with
    /// no `self`), keyed by name. Includes stdlib primitives (`Pair`, `Function`,
    /// `Array`) registered before user inference. Used to emit their namespace
    /// objects into the codegen output when a call site uses them.
    assocInterfaceDecls: std.StringHashMap(ast.BehaviorDecl),
    /// A program's own `behavior` named like one std already registered
    /// (`behavior String { default fn … }`) EXTENDS std's: its members are
    /// added to std's under the one name in `assocInterfaceDecls`, and this
    /// map keeps std's declaration as it was, so a re-registration of the
    /// program's decl merges against std's members only
    /// (`infer.registerInterfaceAssociatedFns`). Read by `comptime.zig`
    /// `withUsedAssocInterfaces`, which emits the merged declaration in place
    /// of the program's.
    stdBehaviorBase: std.StringHashMapUnmanaged(ast.BehaviorDecl) = .empty,
    /// `pub behavior` declarations this module IMPORTS, by name — read only to
    /// tell that a method call's receiver is typed by a behavior declaring the
    /// method (`InstanceLowering.behavior`). Kept apart from
    /// `assocInterfaceDecls`, whose entries codegen emits.
    importedBehaviorDecls: std.StringHashMapUnmanaged(ast.BehaviorDecl) = .empty,
    /// The `Ok(…)` / `Error(…)` patterns matched against a `@Result` subject,
    /// keyed by the arm's `patternLoc` (a `val assert`'s own loc). The
    /// transform writes each as `Result.Ok` / `Result.Error`, so a backend
    /// never reads the bare name as a variant of a user enum that declares
    /// one (`type Level { Info, Error }`).
    resultPatternLocs: std.AutoHashMapUnmanaged(ast.Loc, void) = .empty,
    /// Decision 107's namespace form over a module of the program's own
    /// package or a dependency (`import {jwt} from "sec"`, `import {jwt};`):
    /// the bound name, its module's exports, and the calls made through it.
    namespaces: NamespaceImports = .{},
    /// The handles a `from "std"` namespace import binds (`mocks` for
    /// `import {testing.mocks}`) → the module, for the annotation check: a
    /// `#[mocks.<name>]` names a decorator of that module or is refused.
    stdDecoratorHandles: std.StringHashMapUnmanaged([]const u8) = .empty,

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
    /// Local (alias-aware) names imported via `import {…} from "std"` that
    /// name a std MODULE (a namespace) → the module's key in `stdModules`
    /// (`dict` → `dict`, `import {io.fs}` → `fs` → `io/fs`). Marked during
    /// inference; only these gate qualified calls (`bool.negate(x)`) against
    /// `stdModules`. A symbol leaf (`import {io.fs.readText}`) is an ordinary
    /// value binding instead and is not here.
    stdImports: std.StringHashMap([]const u8),
    /// Every local name an `import` of this module binds → the item that
    /// bound it, so a second item binding the same name is
    /// `import-name-collision` (decision 107) at its own site.
    importBound: std.StringHashMap(ast.ImportPath),
    /// Public type declarations (`pub record`/`struct`/`enum`) of each "std"
    /// package module, keyed by module name. Populated by `registerStdlib`;
    /// `markStdImports` registers them into the importing env so case
    /// patterns and annotations see the exported types (e.g. `Order`).
    stdModuleTypes: std.StringHashMap([]const ast.DeclKind),
    /// STD-001 — full FnDecl slice of each "std" package module, keyed by
    /// module name. Populated by `registerStdlib` alongside `stdModuleTypes`.
    /// Consumed by `markStdImports` when `Env.target != null` to red
    /// `std-unsupported-on-target` on imports whose declares lack an
    /// `#[@External.<Target>(…)]` binding. Owns nothing — the FnDecl slices
    /// point into the arena where `registerStdlib` parsed them.
    stdModuleFns: std.StringHashMap([]const ast.FnDecl),
    /// STD-001 — a namespace import of a std module some of whose host-bound
    /// declares have no binding for the active target, keyed by the local
    /// name it binds. The refusal belongs to the CALL of such a function, so
    /// it waits here: a qualified call of one reds at the call, naming it
    /// (`checkStdGatedCall`), and an import none of whose unsupported
    /// functions is called reds at the import once the program is inferred
    /// (`reportStdTargetGates`). Arena-owned.
    stdTargetGates: std.StringArrayHashMapUnmanaged(StdTargetGate) = .empty,
    /// STD-001 — active codegen target name when this env is on the
    /// project-side compile path (null in tests / LSP / std-prelude
    /// inference). Set via `setTarget`; consumed by `markStdImports`.
    /// One of `"commonJS"` / `"erlang"` / `"beam"` / `"wasm"`.
    target: ?[]const u8 = null,
    /// Stdlib method calls on builtin-array receivers (`xs.isEmpty()` sugar).
    /// Key: call loc, value: { module, method }. Consumed by transform.
    stdArrayLowerings: std.AutoHashMap(ast.Loc, StdArrayLowering),
    /// Value-receiver instance method calls (`recv.method(args)`), keyed by call
    /// loc. Lets backends without native method dispatch lower record + builtin
    /// primitive methods. Empty contribution on commonJS (native dispatch).
    instanceLowerings: std.AutoHashMap(ast.Loc, InstanceLowering),
    /// Every arithmetic operator inferred (`+` `-` `*` `/` `%`, a unary `-`,
    /// a `+=`), keyed by its operator's loc, with its result type. Read once
    /// inference is done (the operands may be type variables when the operator
    /// is met) and turned into `InstanceLowering.division` entries.
    divisions: std.AutoHashMap(ast.Loc, *T.Type),
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
    /// Decision 216 (1) — the members decorator bodies gave the types of this
    /// module (`decl.addMember(source)`), in call order. `analyzeSource`
    /// parses each into the target type's body and re-analyzes the module, as
    /// it does with `contributions`. Allocated in `arena`.
    memberContributions: std.ArrayListUnmanaged(MemberContribution) = .empty,
    /// Decision 216 (3) — the associated types decorator bodies declared
    /// (`decl.addType(name, source)`), in call order; merged as top-level
    /// types named `__<Owner>__<Name>` before the re-analysis.
    typeContributions: std.ArrayListUnmanaged(TypeContribution) = .empty,
    /// Decision 280 — how each parameter of a decorator application reaches
    /// the body, keyed by the annotation's location: `infer.zig`
    /// `checkDecoratorArgs` writes it once the arguments are typed,
    /// `runDeclDecorators` reads it. Allocated in `arena`.
    decoratorArgValues: std.AutoHashMapUnmanaged(ast.Loc, []const DecoratorArgValue) = .empty,
    /// Decision 370 (2) — each decorator type parameter as one annotation
    /// bound it (`check<T>` on `Signup`: `T` is `Signup`), keyed like
    /// `decoratorArgValues`: a member function's types are spelled with them.
    decoratorTypeArgs: std.AutoHashMapUnmanaged(ast.Loc, []const memberFnMod.TypeArg) = .empty,
    /// Decision 216 (3) — set on the first analysis of a module whose
    /// decorators have not run yet: a dotted type name `Owner.Name` whose
    /// owner is a type is accepted unresolved (`resolveTypeName`), since the
    /// owner's decorators may still declare it; the first one taken is kept
    /// here and refused if no pass-2 re-analysis follows.
    assocTypesPending: bool = false,
    pendingAssocTypeName: ?struct { name: []const u8, loc: ?ast.Loc } = null,
    /// Decision 216 — the compile session's reflection (`reflection.zig`):
    /// where a decorator's `decl.setMeta` is recorded and `@typeInfo` reads.
    /// Null outside a session (unit helpers that infer one program alone).
    reflection: ?*reflectionMod.Reflection = null,
    /// Decision 216 (4) — the module reads `@TypeInfo.all`: its first
    /// analysis stops before bodies, and the re-analysis receives the answers.
    typeinfoAllPending: bool = false,
    /// Call loc → the `Declared<T>` array answering that `@TypeInfo.all`
    /// (`typeinfo_all.plan`), spliced through `srcRewrites`.
    typeinfoAll: std.AutoHashMapUnmanaged(ast.Loc, *const ast.Expr) = .empty,
    /// The module names the prelude records `Declared` / `DeclaredMeta`, so
    /// `comptime.zig` splices their declarations in (`withDeclaredDecls`).
    usesDeclared: bool = false,
    /// The names this module declares at top level (types, behaviors, fns,
    /// vals) — what `@typeInfo(Name)` reflects when no import binds `Name`.
    ownDecls: std.StringHashMapUnmanaged(void) = .empty,
    /// Erlang sent to and replies received from the `erl` runtime by every
    /// decorator / template evaluation in this module, in order (snapshots).
    /// Allocated in `arena`.
    comptimeTraces: std.ArrayListUnmanaged(trace.Entry) = .empty,
    /// Decision 57 (1.0.5-beta) — the checker's warning channel: diagnostics
    /// that do not stop the compilation, each a located `TypeError` rendered
    /// like an error. Filled through `warn`; surfaced as `OkData.warnings`.
    /// Decision 8 §1.4 (a binding that falls to `unknown`) and §4.3 (an `is`
    /// test that is always false) write here. Allocated in `arena`.
    warnings: std.ArrayListUnmanaged(@import("error.zig").TypeError) = .empty,
    /// 01 step 13 — the undo log of the body being inferred (`openBodyScope`).
    bodyScope: ?*std.ArrayListUnmanaged(BindUndo) = null,
    /// True while the operand of a `use` is inferred: a component call there
    /// is `use`'s to refuse, not an implicit render (`inferComponentCall`).
    inUseOperand: bool = false,
    /// The location of the call written as `use`'s operand: std's `provide`
    /// / `context` are hooks, legal only there (decision 354).
    useOperandLoc: ?ast.Loc = null,
    /// The location of the call written as `await`'s operand: a component call
    /// there keeps its wrapper, the `await` being written (`inferComponentCall`).
    awaitOperandLoc: ?ast.Loc = null,
    /// Decision 110 — an imported type's `as` name → the declared name
    /// (`registerImportedTypeAlias`); a constructor call through the alias is
    /// renamed at the call so no backend sees the alias.
    importedTypeAliases: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// An import item whose name another module the backends' name-keyed
    /// lookup would also read declares, out of the checker's reach: a BUNDLED
    /// package's module beside a shorthand `import {x};` (decision 170), a
    /// module of the importing package beside `from "<pkg>"`, or the package
    /// `log` beside the module path `import {log.levelName};` (decision 206).
    /// The item's loc → the module it resolved to, which the transformed
    /// program names (`from "<module>"`, `withImportSourcesNamed`) so the
    /// backends read the same answer.
    itemOwners: std.AutoHashMapUnmanaged(ast.Loc, []const u8) = .empty,
    /// The declaration each non-std type import item resolved to, by the
    /// local name the item binds (`resolveImports` in `comptime.zig`): its
    /// declared name and the module path that declares it. One declaration
    /// reached by two items — `import {catalog.Widget};` beside the
    /// `import {Widget as __bp_ti_0} from "catalog";` a `@TypeInfo.all`
    /// answer adds — is one type: registered once, and the same identity to
    /// decision 170's two-types check (`noteExplicitTypeNames`), however each
    /// item spells its source.
    importedTypeDecls: std.StringHashMapUnmanaged(ImportedTypeDecl) = .empty,
    /// Decision 170 — the type names this module declares or imports by name
    /// (`type Dict(…)`, `import {kit.store.Dict as OwnDict}` → `Dict`),
    /// collected before any import is marked (`noteExplicitTypeNames`). A std
    /// module NAMESPACE (`import {collections}`) registers its `pub` types
    /// bare only where no such name is taken: the declaration the module
    /// named wins over the one a namespace brings along implicitly.
    explicitTypeNames: std.StringHashMapUnmanaged(void) = .empty,
    /// Decision 147 (lg-a) — the body being inferred is a lambda's, whose
    /// fallible channel is its EXPECTED return's: the refusal of a `try` /
    /// `throw` there names the expected `fn(…) -> @Result<U, E>` form.
    inLambdaBody: bool = false,
    /// Decision 148 (lg-b) — how many lambda bodies enclose the expression
    /// being inferred (a `case` arm's block is not one), and, for each local
    /// a body bound, the depth it was bound at with the type it was bound to
    /// (a module-level binding is never noted). A write to a name bound at a
    /// shallower depth is a write to a captured `var`.
    lambdaDepth: u32 = 0,
    localDepth: std.StringHashMapUnmanaged(LocalDepth) = .empty,
    /// The lambda body being inferred may write captured `var`s: a `forEach`
    /// body, or a local closure called only at statement position.
    captureWriteOk: bool = true,
    /// Set by the site that infers the next lambda when that lambda is one of
    /// the two exempt shapes; consumed by `inferFunctionExprExpected`.
    nextLambdaExempt: bool = false,
    /// The `val f = { … }` names of the block being inferred whose every later
    /// use is a call at statement position (`f();`).
    statementClosures: std.StringHashMapUnmanaged(void) = .empty,
    /// An assignment's re-bind (narrowing restore) does not move a depth.
    suppressDepthNote: bool = false,
    /// A std module's `pub` type a namespace import did NOT register because
    /// `explicitTypeNames` holds its name → the std module key. A call into
    /// that namespace whose signature names the type is refused
    /// (`refuseShadowedStdSignature`): types are nominal by name, and the
    /// checker would read std's type as this module's.
    shadowedStdTypes: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// Decision 8 §1.3 — a top-level fn's declaration, for a call that writes
    /// its type arguments (`first<string>([])`): the generic parameters, the
    /// parameters and the return as written. Filled by `registerFnSignatures`.
    fnDecls: std.StringHashMapUnmanaged(ast.FnDecl) = .empty,
    /// A function this module IMPORTS, by the name it is bound under, with
    /// every function it reaches in its own module (the first entry is the
    /// imported function itself, under that name) — what a decorator of this
    /// module carries when its body calls it (`infer.decoratorSupport`).
    importedFnSupport: std.StringHashMapUnmanaged([]const ast.FnDecl) = .empty,
    /// A template this module IMPORTS, by its body's address (as
    /// `comptimeOwners`), with the functions of its own module its body
    /// reaches (`infer.decoratorSupport`, exported by `comptime.zig`
    /// `registerExports`) — compiled into the template module beside it
    /// (decision 331, calls included). A local template computes it from
    /// `fnDecls` when it is expanded.
    importedTemplateSupport: std.AutoHashMapUnmanaged(usize, ComptimeSupport) = .empty,
    /// Decision 331 — the declarations of the module being inferred
    /// (`inferProgramTyped` sets them): the types and functions a `comptime`
    /// evaluated on the runtime carries (`block_eval.zig`).
    moduleDecls: []const ast.DeclKind = &.{},
    /// Decision 331 — every module's type declarations the build analysed so
    /// far, by module path (`comptime.zig`'s `typeDeclRegistry`): where
    /// `block_eval.zig` finds a type of another package the block reaches.
    /// Null in tooling that analyses one module.
    typeDeclRegistry: ?*const std.StringHashMap(std.StringHashMap(ast.DeclKind)) = null,
    /// Decision 331 — the last synthetic column a lifted `comptime` value's
    /// node took (`block_eval.Lifter.nextLoc`): each node is located apart,
    /// since the lowering tables are keyed by location.
    comptimeLiftSeq: usize = 0,
    /// Decision 112 — the exports of each module an imported template was
    /// declared in, by module path, private functions and values included
    /// under `templatePrivateKey`: the names the template's own text may use.
    templateOwnerExports: std.StringHashMapUnmanaged(*const std.StringHashMap(*T.Type)) = .empty,
    /// Decision 112 — a name a template's LIBRARY wrote into the built code,
    /// bound under an alias that no source can spell, and the declaration it
    /// stands for (`dsl_hygiene.zig`). `comptime.zig` imports each alias from
    /// its owner so the backends lower it as a cross-module reference.
    templateImports: std.StringArrayHashMapUnmanaged(TemplateImport) = .empty,
    /// Decision 112 — each imported name, by the name it is bound under, with
    /// the module that declares it and its declared name: what a template's
    /// `lookup` answers for it (`infer.buildScopeSnapshot`).
    importOwners: std.StringHashMapUnmanaged(TemplateImport) = .empty,
    /// Decisions 384, 385 — every module's exports the build analysed so far,
    /// by module path (`comptime.zig`'s registry), private functions and
    /// values of a module that shares them under `templatePrivateKey`
    /// (`written_names.zig`). Null in tooling that analyses one module.
    exportsRegistry: ?*const std.StringHashMap(std.StringHashMap(*T.Type)) = null,
    /// Decisions 384, 385 — a name written in another module that this
    /// module's re-analysis binds under its alias (`written_names.zig`): a
    /// library member's names (`infer.memberFnSource`) and a catalogue
    /// entry's `@Expr` names (`typeinfo_all.zig`), recorded on the first
    /// analysis and handed to the second (`comptime.zig` `analyzeMerged`).
    hygieneImports: std.ArrayListUnmanaged(HygieneImport) = .empty,
    /// Decision 395 (1) — the decorator's type parameters while the member it
    /// hands on is typed (`infer.inferMemberFnCall`): `@typeInfo(T)` of one of
    /// them is the read's type alone (`infer.typedMetaReadOfTypeParam`).
    memberFnGenerics: ?*const std.StringHashMap(*T.Type) = null,
    /// Decision 8 §3.2 — where an inferred union was born: the `if` or `case`
    /// whose branches disagreed. A use the union refuses names it, so the
    /// author sees the widening and not only the refusal.
    unionOrigins: std.AutoHashMapUnmanaged(*T.Type, struct { loc: ast.Loc, kind: []const u8 }) = .empty,
    /// 01 step 13 — each name a top-level body introduced (it was unbound
    /// before the body), mapped to that body's name, for the diagnostic a
    /// later use outside it gets. Allocated in `arena`.
    closedLocals: std.StringHashMapUnmanaged([]const u8) = .empty,
    /// Decision 8 §1.4 — bindings born as `[]` with no annotation, turned into
    /// warnings once the module is inferred (`infer.zig` `flushBirthWarnings`).
    birthWarnings: std.ArrayListUnmanaged(@import("infer.zig").BirthWarning) = .empty,
    /// Set on the second analysis pass (after splicing contributions) so
    /// decorators are not re-invoked — no re-contribution, no infinite loop.
    skipDecoratorInvoke: bool = false,
    /// Fn declarations parsed by `registerStdlib` from `builtins_fns.d.bp`
    /// (todo / panic / trap / emit / module / field). Made
    /// available to `transform.expandTrailingDefaults` so a bare `todo()` /
    /// `panic()` call site at user code resolves to the parsed `FnDecl` and
    /// its trailing literal default lands in `c.args` before dispatch.
    stdlibFnDecls: std.StringHashMap(ast.FnDecl),
    /// Decision 252 — every builtin's declaration, parsed by
    /// `registerStdlib` from `builtins.d.bp` and `builtins_fns.d.bp` and keyed
    /// by the name after `@` (`TypeInfo.all` for the static method). A call to
    /// a builtin held `.declaration` (`comptime/builtins.zig`) is checked
    /// against it (`infer.zig` `checkBuiltinArguments`).
    builtinDecls: std.StringHashMap(BuiltinDecl),
    /// Constructor parameter lists for record / struct / enum-variant types,
    /// keyed by the bare type name (`Config`) for records/structs and the
    /// `Enum.Variant` qualified path (`Level.Error`) for enum variants. Each
    /// `[]ast.Param` carries the original `default` Expr so transform's
    /// `expandTrailingDefaults` can inject them at call sites — same rule as
    /// free-fn defaults; constructors take the same arity-check shape.
    ctorParams: std.StringHashMap([]const ast.Param),
    /// Decision 329 — the namespace types in scope (`type Type { fn … }`), by
    /// declared name: a call of the name constructs nothing and is refused.
    namespaceTypes: std.StringHashMap(void),
    /// Decision 330 — set while `recv?.m(args)` is typed the way it was
    /// before the optional lost its methods (`infer.inferOptionalOperator`):
    /// the method is the payload's, read through `?.`.
    inOptionalChain: bool = false,
    /// Type guard function info, keyed by function name. A type guard
    /// `fn f(x: T) -> x is NarrowedT` narrows `x` from `T` to `NarrowedT`
    /// when called in an `if` condition or as a statement (assertion mode).
    typeGuardFns: std.StringHashMap(TypeGuardInfo),
    /// C-04 (01 step 7, N1) — call sites where inference accepted a call that
    /// omitted an argument because the parameter declares a default, keyed by
    /// the call's `ast.Loc`. `transform` reads the plan and materialises it, so
    /// every backend sees a complete call and none of them learns a new rule.
    /// A call short of a REQUIRED argument is never recorded here — that is N2,
    /// and it stays the arity error it has always been.
    defaultInjections: std.AutoHashMap(ast.Loc, DefaultFill),
    /// C-04 — the declared parameter list of every top-level `fn` of this
    /// module, keyed by name; the mirror of `stdlibFnDecls` for the program's
    /// own functions. A `T.func` carries no defaults, so without this the
    /// free-fn call path cannot tell an omitted trailing default (N1) from a
    /// missing required argument (N2).
    fnParams: std.StringHashMap([]const ast.Param),
    /// C-04 — the declared parameter list of every inherent method, keyed
    /// `"<Type>.<method>"` and **including** `self`, exactly as written.
    /// `setInherentMethodType` stores TYPES, which carry no defaults.
    inherentMethodParams: std.StringHashMap([]const ast.Param),
    /// Decision 8 §1.3 — the declaration of every inherent method, keyed
    /// `"<Type>.<method>"`: `recv.m<T>(…)` pins the method's own type
    /// parameters, which only the declaration names in order.
    inherentMethodDecls: std.StringHashMap(ast.BehaviorMethod),
    /// 01 R2 — the constructor and variant bindings a type registered as a
    /// TYPE only gave up (`registerTypesOnly`): not in scope, but still where
    /// a generic type's registration cells are read from
    /// (`instantiateFieldType`), so two instances never share one cell.
    typeOnlyCtors: std.StringHashMap(*T.Type),
    /// Type aliases in scope (`type Parser<T> = @Result<T, ParseError>;`,
    /// decision 118 rule 1), the module's own and the imported ones. An alias
    /// is transparent: `resolveTypeRefInContext` substitutes its target. Never
    /// a typedef and never a binding. Arena-owned; std's template has none.
    typeAliases: std.StringHashMapUnmanaged(ast.TypeAliasDecl) = .empty,
    /// The aliases being expanded right now, innermost last: an alias met
    /// again while it is on this stack is `type-alias-recursive`.
    aliasExpanding: std.ArrayListUnmanaged([]const u8) = .empty,

    pub fn init(arena: std.mem.Allocator) Env {
        return .{
            .arena = arena,
            .bindings = std.StringHashMap(*T.Type).init(arena),
            .valNames = std.StringHashMap(void).init(arena),
            .typeValueNames = std.StringHashMap(void).init(arena),
            .typeDefs = std.StringHashMap(TypeDef).init(arena),
            .fnTypeparams = std.StringHashMap([]const TypeparamConstraint).init(arena),
            .fnExprParams = std.StringHashMap([]const ExprParamInfo).init(arena),
            .exprCaptures = std.AutoHashMap(ast.Loc, []const template.CapturedExpr).init(arena),
            .templateLowerings = std.AutoHashMap(ast.Loc, TemplateOp).init(arena),
            .templateFns = std.StringHashMap(ast.FnDecl).init(arena),
            .comptimeOwners = std.AutoHashMap(usize, []const u8).init(arena),
            .variantCtors = std.StringHashMap(*T.Type).init(arena),
            .variantClaims = std.StringHashMap([]const []const u8).init(arena),
            .templateExpansions = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .srcRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
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
            .synthesisedEnumDecls = std.StringHashMap(ast.TypeDecl).init(arena),
            .enumSectionRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .indexRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .optionalNullCases = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .assocInterfaceDecls = std.StringHashMap(ast.BehaviorDecl).init(arena),
            .usedAssocInterfaces = std.StringHashMap(void).init(arena),
            .dispatchRewrites = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .jsMethodRenames = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .stdModules = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena),
            .stdImports = std.StringHashMap([]const u8).init(arena),
            .importBound = std.StringHashMap(ast.ImportPath).init(arena),
            .stdModuleTypes = std.StringHashMap([]const ast.DeclKind).init(arena),
            .stdModuleFns = std.StringHashMap([]const ast.FnDecl).init(arena),
            .stdArrayLowerings = std.AutoHashMap(ast.Loc, StdArrayLowering).init(arena),
            .instanceLowerings = std.AutoHashMap(ast.Loc, InstanceLowering).init(arena),
            .divisions = std.AutoHashMap(ast.Loc, *T.Type).init(arena),
            .implicitStdModules = std.StringHashMap(void).init(arena),
            .decorators = std.StringHashMap(DecoratorSig).init(arena),
            .stdlibFnDecls = std.StringHashMap(ast.FnDecl).init(arena),
            .builtinDecls = std.StringHashMap(BuiltinDecl).init(arena),
            .ctorParams = std.StringHashMap([]const ast.Param).init(arena),
            .namespaceTypes = std.StringHashMap(void).init(arena),
            .defaultInjections = std.AutoHashMap(ast.Loc, DefaultFill).init(arena),
            .fnParams = std.StringHashMap([]const ast.Param).init(arena),
            .inherentMethodParams = std.StringHashMap([]const ast.Param).init(arena),
            .inherentMethodDecls = std.StringHashMap(ast.BehaviorMethod).init(arena),
            .typeOnlyCtors = std.StringHashMap(*T.Type).init(arena),
            .typeGuardFns = std.StringHashMap(TypeGuardInfo).init(arena),
        };
    }

    /// True when `label` is in scope for a `yield`/`break` target.
    pub fn hasLabel(self: *Env, label: []const u8) bool {
        for (self.labelStack.items) |l| {
            if (std.mem.eql(u8, l, label)) return true;
        }
        return false;
    }

    /// Clone every populated hashmap from `template` onto a fresh env
    /// using `arena` as the backing allocator for the new env's hashmaps.
    /// `*Type` and decl pointers in cloned entries continue to point into
    /// the template's arena — the template lives for the lifetime of the
    /// process, so the references stay valid. All mutable state
    /// (level, jump lowerings, label stack, etc.) is freshly initialised.
    ///
    /// Avoids the ~83ms/call cost of re-parsing + re-inferring the stdlib
    /// (`primitives.bp`, `@Decl` cluster, `CustomNode`, `builtins_fns.d.bp`)
    /// on every `freshEnv`, which `registerStdlib` did unconditionally.
    /// Lex + parse + infer of the test snippet itself only costs ~µs.
    pub fn cloneFromTemplate(tmpl: *const Env, arena: std.mem.Allocator) !Env {
        var env = try cloneFromTemplateFields(tmpl, arena);
        // T17 — the reflection records' spellings (`Param` = `__Decl__Param`,
        // `comptime.zig` `decl_reflection_src`) are the template's only
        // aliases every module sees; no other template alias is in scope.
        var ait = tmpl.typeAliases.iterator();
        while (ait.next()) |e| switch (e.value_ptr.target) {
            .named => |n| if (std.mem.startsWith(u8, n, "__Decl__")) try env.typeAliases.put(arena, e.key_ptr.*, e.value_ptr.*),
            else => {},
        };
        return env;
    }

    fn cloneFromTemplateFields(tmpl: *const Env, arena: std.mem.Allocator) !Env {
        return .{
            .arena = arena,
            .bindings = try tmpl.bindings.cloneWithAllocator(arena),
            .valNames = try tmpl.valNames.cloneWithAllocator(arena),
            .typeValueNames = try tmpl.typeValueNames.cloneWithAllocator(arena),
            .typeDefs = try tmpl.typeDefs.cloneWithAllocator(arena),
            .fnTypeparams = try tmpl.fnTypeparams.cloneWithAllocator(arena),
            .fnExprParams = try tmpl.fnExprParams.cloneWithAllocator(arena),
            .exprCaptures = std.AutoHashMap(ast.Loc, []const template.CapturedExpr).init(arena),
            .templateLowerings = std.AutoHashMap(ast.Loc, TemplateOp).init(arena),
            .templateFns = try tmpl.templateFns.cloneWithAllocator(arena),
            .comptimeOwners = try tmpl.comptimeOwners.cloneWithAllocator(arena),
            .variantCtors = try tmpl.variantCtors.cloneWithAllocator(arena),
            .variantClaims = try tmpl.variantClaims.cloneWithAllocator(arena),
            .templateExpansions = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .srcRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .customAstByLoc = std.AutoHashMap(ast.Loc, CustomAstEntry).init(arena),
            .templateEvalCache = std.StringHashMap(*const ast.Expr).init(arena),
            .nextId = tmpl.nextId,
            .nextTypeId = tmpl.nextTypeId,
            .level = 0,
            .lastError = null,
            .method_lowerings = std.AutoHashMap(ast.Loc, MethodLowering).init(arena),
            .result_jump_lowerings = std.AutoHashMap(ast.Loc, ResultJumpLowering).init(arena),
            .fnContext = null,
            .throwContext = .unchecked,
            .starFn = null,
            .labelStack = .empty,
            .extensions = try tmpl.extensions.cloneWithAllocator(arena),
            .activations = try tmpl.activations.cloneWithAllocator(arena),
            .inherentMethods = try cloneNestedSet(tmpl.inherentMethods, arena),
            .inherentMethodTypes = try cloneNestedTypeMap(tmpl.inherentMethodTypes, arena),
            .synthesisedEnumDecls = try tmpl.synthesisedEnumDecls.cloneWithAllocator(arena),
            .enumSectionRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .indexRewrites = std.AutoHashMap(ast.Loc, *const ast.Expr).init(arena),
            .optionalNullCases = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .assocInterfaceDecls = try tmpl.assocInterfaceDecls.cloneWithAllocator(arena),
            .usedAssocInterfaces = std.StringHashMap(void).init(arena),
            .dispatchRewrites = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .jsMethodRenames = std.AutoHashMap(ast.Loc, []const u8).init(arena),
            .stdModules = try tmpl.stdModules.cloneWithAllocator(arena),
            .stdImports = std.StringHashMap([]const u8).init(arena),
            .importBound = std.StringHashMap(ast.ImportPath).init(arena),
            .stdModuleTypes = try tmpl.stdModuleTypes.cloneWithAllocator(arena),
            .stdModuleFns = try tmpl.stdModuleFns.cloneWithAllocator(arena),
            .stdArrayLowerings = std.AutoHashMap(ast.Loc, StdArrayLowering).init(arena),
            .instanceLowerings = std.AutoHashMap(ast.Loc, InstanceLowering).init(arena),
            .divisions = std.AutoHashMap(ast.Loc, *T.Type).init(arena),
            .implicitStdModules = std.StringHashMap(void).init(arena),
            .decorators = try tmpl.decorators.cloneWithAllocator(arena),
            .stdlibFnDecls = try tmpl.stdlibFnDecls.cloneWithAllocator(arena),
            .builtinDecls = try tmpl.builtinDecls.cloneWithAllocator(arena),
            .ctorParams = try tmpl.ctorParams.cloneWithAllocator(arena),
            .namespaceTypes = try tmpl.namespaceTypes.cloneWithAllocator(arena),
            .defaultInjections = std.AutoHashMap(ast.Loc, DefaultFill).init(arena),
            .fnParams = try tmpl.fnParams.cloneWithAllocator(arena),
            .inherentMethodParams = try tmpl.inherentMethodParams.cloneWithAllocator(arena),
            .inherentMethodDecls = try tmpl.inherentMethodDecls.cloneWithAllocator(arena),
            .typeOnlyCtors = try tmpl.typeOnlyCtors.cloneWithAllocator(arena),
            .typeGuardFns = try tmpl.typeGuardFns.cloneWithAllocator(arena),
        };
    }

    fn cloneNestedSet(src: std.StringHashMap(std.StringHashMap(void)), arena: std.mem.Allocator) !std.StringHashMap(std.StringHashMap(void)) {
        var out = std.StringHashMap(std.StringHashMap(void)).init(arena);
        var it = src.iterator();
        while (it.next()) |e| try out.put(e.key_ptr.*, try e.value_ptr.cloneWithAllocator(arena));
        return out;
    }

    fn cloneNestedTypeMap(src: std.StringHashMap(std.StringHashMap(*T.Type)), arena: std.mem.Allocator) !std.StringHashMap(std.StringHashMap(*T.Type)) {
        var out = std.StringHashMap(std.StringHashMap(*T.Type)).init(arena);
        var it = src.iterator();
        while (it.next()) |e| try out.put(e.key_ptr.*, try e.value_ptr.cloneWithAllocator(arena));
        return out;
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
        self.comptimeOwners.deinit();
        self.variantCtors.deinit();
        self.variantClaims.deinit();
        self.templateExpansions.deinit();
        self.srcRewrites.deinit();
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
        self.importBound.deinit();
        self.stdModuleTypes.deinit();
        self.stdModuleFns.deinit();
        self.stdArrayLowerings.deinit();
        self.instanceLowerings.deinit();
        self.divisions.deinit();
        self.implicitStdModules.deinit();
        self.decorators.deinit();
        self.stdlibFnDecls.deinit();
        self.builtinDecls.deinit();
        self.ctorParams.deinit();
        self.namespaceTypes.deinit();
        self.defaultInjections.deinit();
        self.fnParams.deinit();
        self.inherentMethodParams.deinit();
        self.inherentMethodDecls.deinit();
        self.typeOnlyCtors.deinit();
        self.typeGuardFns.deinit();
        self.synthesisedEnumDecls.deinit();
        self.enumSectionRewrites.deinit();
        self.indexRewrites.deinit();
        self.optionalNullCases.deinit();
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

    /// C-04 — store `typeName.method`'s parameters AS WRITTEN (`self` included),
    /// the only place the `default` expressions survive registration.
    pub fn setInherentMethodParams(self: *Env, typeName: []const u8, method: []const u8, params: []const ast.Param) !void {
        const key = try std.fmt.allocPrint(self.arena, "{s}.{s}", .{ typeName, method });
        try self.inherentMethodParams.put(key, params);
    }

    /// C-04 — `typeName.method`'s parameters as written, `self` included.
    pub fn getInherentMethodParams(self: *Env, typeName: []const u8, method: []const u8) ?[]const ast.Param {
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ typeName, method }) catch return null;
        return self.inherentMethodParams.get(key);
    }

    /// Decision 8 §1.3 — store `typeName.method`'s declaration.
    pub fn setInherentMethodDecl(self: *Env, typeName: []const u8, method: ast.BehaviorMethod) !void {
        const key = try std.fmt.allocPrint(self.arena, "{s}.{s}", .{ typeName, method.name });
        try self.inherentMethodDecls.put(key, method);
    }

    /// Decision 8 §1.3 — `typeName.method`'s declaration, if one was registered.
    pub fn getInherentMethodDecl(self: *Env, typeName: []const u8, method: []const u8) ?ast.BehaviorMethod {
        var buf: [256]u8 = undefined;
        const key = std.fmt.bufPrint(&buf, "{s}.{s}", .{ typeName, method }) catch return null;
        return self.inherentMethodDecls.get(key);
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
        try self.noteBind(name);
        try self.bindings.put(name, ty);
        _ = self.valNames.remove(name);
        try self.noteLocalDepth(name, ty);
    }

    pub const LocalDepth = struct { depth: u32, ty: *T.Type };

    fn noteLocalDepth(self: *Env, name: []const u8, ty: *T.Type) !void {
        if (self.bodyScope == null or self.suppressDepthNote) return;
        try self.localDepth.put(self.arena, name, .{ .depth = self.lambdaDepth, .ty = ty });
    }

    /// The lambda depth `name`'s current binding was made at, when it is a
    /// local of a body (null for a module-level binding or an unknown name).
    pub fn localBindDepth(self: *Env, name: []const u8) ?u32 {
        const ld = self.localDepth.get(name) orelse return null;
        const cur = self.bindings.get(name) orelse return null;
        if (cur != ld.ty) return null;
        return ld.depth;
    }

    /// 01 step 13 — one entry of a body's undo log: what `name` was bound to
    /// (and whether as a `val`) before the body bound it.
    pub const BindUndo = struct { name: []const u8, prev: ?*T.Type, wasVal: bool };

    /// Record `name`'s current binding in the open body scope, if any, before
    /// it is overwritten.
    fn noteBind(self: *Env, name: []const u8) !void {
        const log = self.bodyScope orelse return;
        try log.append(self.arena, .{ .name = name, .prev = self.bindings.get(name), .wasVal = self.valNames.contains(name) });
    }

    /// 01 step 13 — a body's bindings end with the body. `bindings` is one flat
    /// table, so a `val` declared inside one `fn` used to stay bound for every
    /// declaration inferred after it: `fn later() { return v; }` checked
    /// against another function's local, and a local named like an exported
    /// fn retyped it for the next function. `openBodyScope` starts an undo
    /// log; `closeBodyScope` replays it backwards, which puts every name the
    /// body bound (parameters, locals, pattern binders) back exactly as it was.
    pub fn openBodyScope(self: *Env, log: *std.ArrayListUnmanaged(BindUndo)) ?*std.ArrayListUnmanaged(BindUndo) {
        const outer = self.bodyScope;
        self.bodyScope = log;
        return outer;
    }

    pub fn closeBodyScope(self: *Env, log: *std.ArrayListUnmanaged(BindUndo), outer: ?*std.ArrayListUnmanaged(BindUndo), owner: []const u8) void {
        self.bodyScope = outer;
        if (outer == null) for (log.items) |u| {
            if (u.prev == null and !self.closedLocals.contains(u.name))
                self.closedLocals.put(self.arena, u.name, owner) catch {};
        };
        var i = log.items.len;
        while (i > 0) {
            i -= 1;
            const u = log.items[i];
            if (u.prev) |p| {
                self.bindings.put(u.name, p) catch {};
            } else {
                _ = self.bindings.remove(u.name);
            }
            if (u.wasVal) {
                self.valNames.put(u.name, {}) catch {};
            } else {
                _ = self.valNames.remove(u.name);
            }
        }
        log.clearRetainingCapacity();
    }

    /// A module `var`'s storage and bound type — see `memoryVars`.
    pub const MemoryVar = struct { memory: ast.Memory, ty: *T.Type };

    /// `bind` for a `val` — local or module-level: the name is then refused
    /// as an assignment target until something else binds it (decision 38).
    pub fn bindVal(self: *Env, name: []const u8, ty: *T.Type) !void {
        try self.noteBind(name);
        try self.bindings.put(name, ty);
        try self.valNames.put(name, {});
        try self.noteLocalDepth(name, ty);
    }

    /// Was `name`'s most recent binder a `val`?
    pub fn isVal(self: *Env, name: []const u8) bool {
        return self.valNames.contains(name);
    }

    pub fn lookupTypeDef(self: *Env, name: []const u8) ?TypeDef {
        return self.typeDefs.get(name);
    }

    /// The type alias `name` names, if one is in scope.
    pub fn lookupTypeAlias(self: *const Env, name: []const u8) ?ast.TypeAliasDecl {
        return self.typeAliases.get(name);
    }

    /// The alias a written type goes through, with the builtin wrapper it
    /// finally stands for. `type Parser<T> = @Result<T, E>;` makes `-> Parser<i32>`
    /// answer `.{ .alias = "Parser", .wrapper = "Result" }`; an alias of an
    /// alias is followed (`type P2<T> = Parser<T>;` answers `.alias = "P2"`,
    /// the name written). Null when `ref` is not an alias, or the alias ends at
    /// a type that is not a builtin `@Wrapper<…>`.
    ///
    /// This is the reading decision 118 rule 1 needs: the declared return
    /// `TypeRef` keeps the alias spelling (the checker substitutes only when it
    /// builds the type), so the effect checker asks this on `FnDecl.returnType`
    /// to tell "the wrapper written in the return" (activates) from "the
    /// wrapper behind an alias" (types the function, activates nothing —
    /// `effect-wrapper-behind-alias` when the body uses a capability).
    pub fn aliasedWrapper(self: *const Env, ref: ast.TypeRef) ?AliasedWrapper {
        const written = aliasNameOf(ref) orelse return null;
        var decl = self.typeAliases.get(written) orelse return null;
        var depth: usize = 0;
        while (depth < 32) : (depth += 1) {
            switch (decl.target) {
                .generic => |g| if (g.is_builtin) return .{ .alias = written, .wrapper = g.name },
                else => {},
            }
            const next = aliasNameOf(decl.target) orelse return null;
            decl = self.typeAliases.get(next) orelse return null;
        }
        return null;
    }

    /// The name a type reference spells when it could be an alias: `Name` or
    /// `Name<…>` (not a builtin, not a union).
    fn aliasNameOf(ref: ast.TypeRef) ?[]const u8 {
        return switch (ref) {
            .named => |n| n,
            .generic => |g| if (g.is_builtin or ref.unionMembers() != null) null else g.name,
            else => null,
        };
    }

    /// Record the typeparam constraints for a function (keyed by name).
    pub fn registerTypeparams(self: *Env, name: []const u8, constraints: []const TypeparamConstraint) !void {
        try self.fnTypeparams.put(name, constraints);
    }

    /// Look up the typeparam constraints for a function, or null if it has none.
    pub fn lookupTypeparams(self: *Env, name: []const u8) ?[]const TypeparamConstraint {
        return self.fnTypeparams.get(name);
    }

    /// Record a warning (decision 57). Inference may walk one expression more
    /// than once (the untyped and the typed pass), so a warning already
    /// recorded at the same location with the same text is not repeated.
    pub fn warn(self: *Env, w: @import("error.zig").TypeError) !void {
        for (self.warnings.items) |seen| {
            const same_loc = if (seen.loc) |a| (if (w.loc) |b| a.line == b.line and a.col == b.col else false) else w.loc == null;
            if (!same_loc) continue;
            if (seen.kind == .custom and w.kind == .custom and std.mem.eql(u8, seen.kind.custom.message, w.kind.custom.message)) return;
        }
        try self.warnings.append(self.arena, w);
    }

    /// C-01 — record the module path `decl` was declared in (see
    /// `comptimeOwners`). A bodyless declaration is never evaluated and has no
    /// identity to key by, so it is not recorded. The first owner stays: the
    /// defining module registers its own declaration before any importer sees it.
    pub fn noteComptimeOwner(self: *Env, decl: ast.FnDecl, owner: []const u8) !void {
        if (decl.body.len == 0) return;
        const gop = try self.comptimeOwners.getOrPut(@intFromPtr(decl.body.ptr));
        if (!gop.found_existing) gop.value_ptr.* = owner;
    }

    /// The module path `decl` was declared in, or "" when nothing recorded it
    /// (the compiler's own tests evaluate a declaration no module owns).
    pub fn comptimeOwnerOf(self: *const Env, decl: ast.FnDecl) []const u8 {
        if (decl.body.len == 0) return "";
        return self.comptimeOwners.get(@intFromPtr(decl.body.ptr)) orelse "";
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
            "i8",  "u8",  "i16",  "u16",    "i32",  "u32",  "i64",      "u64",  "isize", "usize",
            // float types
            "f32", "f64",
            // other primitives
            "bool", "string", "void", "v128",
            // No `any` (1.0.5 decision 31): a written `any` is refused by
            // `resolveTypeRefInContext` as `any-type-removed`, naming
            // `unknown`, the type that holds any value.
            // The declared return of `@panic` / `todo` / `trap`
            // (`libs/std/src/builtins_fns.d.bp`, `builtins.d.bp`): a type no
            // module declares, so C10's second pass needs it named here.
            "noreturn",
            // special
            "Self",
        };
        for (primitives) |p| {
            const ty = try self.namedType(p);
            try self.bind(p, ty);
        }
        // No `print` / `println` binding: printing is the builtin `@print`
        // (`@println`, `@debug`), which every backend lowers. A bare
        // `print(x)` type-checked here and then lowered on commonJS alone —
        // erlang emitted a call to an undefined local, beam an unresolved
        // call, wasm a trap — so it is unbound, and `unboundAt` names the
        // builtin.
    }

    // ── level management ──────────────────────────────────────────────────────

    pub fn enterLevel(self: *Env) void {
        self.level += 1;
    }

    pub fn exitLevel(self: *Env) void {
        self.level -= 1;
    }

    /// 06 N30 — the type annotation being resolved right now (`x: Foo` → the
    /// column of `Foo`). `resolveTypeName` attaches it to an unknown-type error
    /// so the caret lands on the annotation instead of the file. Set and
    /// restored by the inference sites that know the declaration.
    pub fn atTypeRef(self: *Env, loc: ?ast.Loc) ?ast.Loc {
        const prev = self.typeRefLoc;
        if (loc) |l| {
            if (l.line != 0) self.typeRefLoc = l;
        }
        return prev;
    }

    // ── type name resolution ──────────────────────────────────────────────────

    /// Resolve a string type name (from AST) to a *Type.
    /// Generic parameters are looked up in `genericMap` first.
    /// N28 — `Token.Text.Size` → `__Token__Text__Size`, the name
    /// `registerEnumSection` files a section's typedef under. The dotted form is
    /// what the author writes; the mangled one never appears in source.
    pub fn mangleSectionPath(self: *Env, path: []const u8) ![]const u8 {
        var buf: std.ArrayList(u8) = .empty;
        var it = std.mem.splitScalar(u8, path, '.');
        while (it.next()) |seg| {
            try buf.appendSlice(self.arena, "__");
            try buf.appendSlice(self.arena, seg);
        }
        return buf.toOwnedSlice(self.arena);
    }

    /// N28 — the dotted path of a registered section whose segments, run
    /// together, spell `flat` (`TokenText` → `Token.Text`), or null. Lets an
    /// annotation written in the pre-decision flat spelling say what to write.
    fn sectionPathForFlatName(self: *Env, flat: []const u8) !?[]const u8 {
        var it = self.typeDefs.iterator();
        while (it.next()) |e| {
            const key = e.key_ptr.*;
            if (!std.mem.startsWith(u8, key, "__")) continue;
            var run: std.ArrayList(u8) = .empty;
            defer run.deinit(self.arena);
            var dotted: std.ArrayList(u8) = .empty;
            var segs = std.mem.splitSequence(u8, key[2..], "__");
            var first = true;
            while (segs.next()) |seg| {
                try run.appendSlice(self.arena, seg);
                if (!first) try dotted.append(self.arena, '.');
                try dotted.appendSlice(self.arena, seg);
                first = false;
            }
            if (std.mem.eql(u8, run.items, flat)) return try dotted.toOwnedSlice(self.arena);
            dotted.deinit(self.arena);
        }
        return null;
    }

    /// C10 second pass — after every declaration of the module is registered,
    /// an annotation that still names nothing is an error at the annotation.
    pub fn checkPendingTypeNames(self: *Env) !void {
        // The list belongs to the program that filled it: `registerStdlib` runs
        // one inference per std module on the same env, and a name left pending
        // by one must not red in the next.
        defer self.pendingTypeNames.clearRetainingCapacity();
        for (self.pendingTypeNames.items) |p| {
            if (self.typeDefs.get(p.name) != null) continue;
            if (self.bindings.get(p.name) != null) continue;
            // A `behavior` names a type in annotation position (`-> Counter`)
            // without being a typedef: its decl is recorded here.
            if (self.assocInterfaceDecls.get(p.name) != null) continue;
            if (isCompilerKnownTypeName(p.name)) continue;
            const e = @import("error.zig").TypeError.unknownTypeName(p.name);
            self.lastError = if (p.loc) |l| e.withLoc(l) else e;
            return error.TypeError;
        }
    }

    pub fn resolveTypeName(
        self: *Env,
        name: []const u8,
        genericMap: std.StringHashMap(*T.Type),
    ) !*T.Type {
        // Generic parameters bound in the current function/type
        if (genericMap.get(name)) |ty| return ty;
        // Decision 8 §2 — `unknown` is a type the compiler owns, not a name a
        // module declares. It has to answer before the two-pass `pendingTypeNames`
        // walk below, which reds a name nothing declared: an annotation the
        // parser located (`-> unknown`, `x: unknown`) would otherwise be
        // reported as an undeclared type.
        if (std.mem.eql(u8, name, ast.unknown_type_name)) return self.namedType(name);
        // Decision 207 — an inline `type(…)` the module pass did not declare:
        // it stands on a parameter of something that is not a top-level `fn`.
        if (std.mem.eql(u8, name, ast.inline_type_name)) {
            const e = @import("error.zig").TypeError.custom(
                @import("diagnostics.zig").inline_type_position ++ ": an inline `type(…)` is the type of a top-level `fn`'s parameter only — not a method's, a behavior member's or a host declaration's",
                "Name the type (`type LinkProps(…)`) and write the name in this signature.",
            );
            self.lastError = if (self.typeRefLoc) |l| e.withLoc(l) else e;
            return error.TypeError;
        }
        // N28 — a section of an enum-shaped `type` is named by its path
        // (`Token.Text`, `Token.Text.Size`, decision 8 §5.3b). The section's
        // typedef is registered under the mangled `__Token__Text` form by
        // `registerEnumSection`; the dotted spelling is the written one.
        if (std.mem.indexOfScalar(u8, name, '.') != null) {
            const mangled = try self.mangleSectionPath(name);
            if (self.typeDefs.get(mangled)) |_| return self.namedType(mangled);
            // Decision 216 (3) — `Owner.Name` before the owner's decorators
            // ran: accepted for now, decided by the re-analysis (or refused
            // after the decorators, when none follows).
            if (self.assocTypesPending) {
                const head = name[0..std.mem.indexOfScalar(u8, name, '.').?];
                if (self.ownDecls.contains(head) or self.lookupTypeDef(head) != null) {
                    if (self.pendingAssocTypeName == null) self.pendingAssocTypeName = .{ .name = name, .loc = self.typeRefLoc };
                    return self.freshVar();
                }
            }
            const e = @import("error.zig").TypeError.unknownTypeName(name);
            self.lastError = if (self.typeRefLoc) |l| e.withLoc(l) else e;
            return error.TypeError;
        }
        // Registered user-defined types — bare name on a generic typeDef
        // (`r: Result`, `-> Pair`) means "any args". Produce `Name<fresh, …>`
        // so it unifies with the constructor's `Name<T_cell, …>` return type;
        // the call-site instance pins the fresh vars to concrete types.
        if (self.typeDefs.get(name)) |td| {
            const params = switch (td) {
                .record => |r| r.genericParams,
                .struct_ => |s| s.genericParams,
                .enum_ => |e| e.genericParams,
            };
            if (params.len == 0) return self.namedType(name);
            const args = try self.arena.alloc(*T.Type, params.len);
            for (params, 0..) |_, i| args[i] = try self.freshVar();
            return self.namedTypeArgs(name, args);
        }
        // An imported `behavior` is the nominal type its own module names
        // (`-> Request` there is `Request`), not the display name its import
        // binding carries (`behavior Request { … }`): resolved to that, an
        // alias or a signature written against the imported behavior never
        // unified with a value the declaring module typed.
        if (self.importedBehaviorDecls.contains(name)) return self.namedType(name);
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
            // A primitive is bound to itself (`registerBuiltins`); a `val`
            // bound to a type is recorded in `typeValueNames`. A binding of
            // function type keeps the arm's old answer: std's `Array` and
            // imported constructors whose return is not spelled like the
            // binding (`Array` → `array<T>`) are read through it, and a
            // variant constructor used as a type is not R8's question.
            //
            // A declaration's own binding — what a `type`/`behavior` binds its
            // name to, and what an import of one carries — is typed by the
            // declaration's display name (`behavior Request { … }`, the R1
            // builders), which no value's type can spell: it holds a space.
            const declBinding = d.* == .named and std.mem.indexOfScalar(u8, d.named.name, ' ') != null;
            if (d.isNamed(name) or d.* == .func or declBinding or self.typeValueNames.contains(name)) return ty;
            // 01 R8 — any other binding is a value, and a value is not a type.
            const e = @import("error.zig").TypeError.custom(
                try std.fmt.allocPrint(self.arena, "'{s}' is a value, not a type", .{name}),
                "a type position takes a type: a `type` or `behavior` declaration, a primitive, or a `val` bound to one (`val T = i32;`)",
            );
            self.lastError = if (self.typeRefLoc) |l| e.withLoc(l) else e;
            return error.TypeError;
        }
        // N28 — the flat spelling of a section type (`TokenText` for
        // `Token.Text`) is a name the author had to guess from a mangling the
        // language never showed. It is not a type: name the path instead.
        if (try self.sectionPathForFlatName(name)) |dotted| {
            const e = @import("error.zig").TypeError.custom(
                try std.fmt.allocPrint(self.arena, "the type '{s}' is not defined in this scope", .{name}),
                try std.fmt.allocPrint(self.arena, "a section is named by its path: use `{s}`", .{dotted}),
            );
            self.lastError = if (self.typeRefLoc) |l| e.withLoc(l) else e;
            return error.TypeError;
        }
        // C10 — a name nothing declares. It cannot red here: a record may
        // annotate a type declared further down the file, and registration
        // resolves fields in declaration order. Record it with the annotation's
        // location and let `checkPendingTypeNames` (run once every decl is
        // registered) red on what is still unknown — the second pass of C10's
        // two-pass resolution.
        //
        // Only an annotation the parser located enters the list (`typeRefLoc`,
        // set by `resolveParamType` / `resolveFieldType`). A resolution with no
        // annotation in scope is a synthesised or re-entered one — a generic
        // parameter resolved outside the context that binds it, a signature
        // rebuilt from a stored type — and has neither a caret to red at nor a
        // source the user wrote. Compiler-known names never enter the list.
        if (self.typeRefLoc != null and !isCompilerKnownTypeName(name)) {
            self.pendingTypeNames.append(self.arena, .{
                .name = name,
                .loc = self.typeRefLoc,
            }) catch {};
        }
        return self.namedType(name);
    }
};

/// C10 — an annotation that named no known type when it was resolved. Checked
/// again once every declaration of the module is registered, so a forward
/// reference (`type A(b: B)` above `type B(…)`) resolves and only a name
/// nothing declares reds.
pub const PendingTypeName = struct {
    name: []const u8,
    loc: ?ast.Loc,
};

/// C10 — names the compiler knows without any module declaring them, so the
/// two-pass registration cannot see them as typedefs:
///
/// - `Children` is the markup child list a UI library annotates, coerced by
///   `childrenCoercion` in `infer.zig`.
/// - `Binding` is the opaque name `q.lookup` yields inside a template body; it
///   is the `ref` field of the registered `CustomNode`
///   (`comptime.zig` `custom_ast_reflection_src`) and is declared by no module.
fn isCompilerKnownTypeName(name: []const u8) bool {
    const known = [_][]const u8{ "Children", "Binding" };
    for (known) |k| if (std.mem.eql(u8, name, k)) return true;
    return false;
}

/// Type guard information for narrowing at call sites.
/// `fn f(x: T) -> x is NarrowedT` records the param index and narrowed type name.
pub const TypeGuardInfo = struct {
    paramIndex: usize,
    narrowedTypeName: []const u8,
};

/// C-04 (01 step 7, N1) — how a call that omitted an argument lines up with the
/// callee's parameters. Inference writes one of these into `Env.defaultInjections`
/// the moment it *accepts* such a call; `comptime/transform.zig` materialises it
/// and nothing else, so the checker and the lowering can never disagree about
/// which argument was filled in.
pub const DefaultFill = struct {
    /// The callee's parameters, in declaration order. For a method this is the
    /// list the ARGUMENTS line up with — `self` is already dropped.
    params: []const ast.Param,
    /// One entry per parameter: the index of the argument the call wrote, or
    /// `null` for a parameter that takes its own declared `default`.
    slots: []const ?usize,
};

/// C-04 — plan the fill for a call of `labels.len` arguments against `params`.
///
/// Answers `null` when the call needs no fill (it wrote an argument for every
/// parameter) and `error.CannotFill` when it cannot have one: a parameter left
/// without an argument and without a `default` is a missing REQUIRED argument,
/// which is N2's arity error and must stay one.
///
/// An argument whose label names a parameter claims that parameter's slot, so
/// `P(y: 2)` against `type P(x: i32 = 0, y: i32)` fills `x` from its default —
/// the rule the plain tail-append cannot express, because `y` is the trailing
/// parameter and `y` is required. Unlabelled arguments take the remaining slots
/// in order. Any label that names no parameter (a `..` record-update spread,
/// most of all) abandons the plan: those calls have their own paths and their
/// own diagnostics.
pub fn planDefaultFill(
    arena: std.mem.Allocator,
    params: []const ast.Param,
    labels: []const ?[]const u8,
) !?DefaultFill {
    if (labels.len > params.len) return error.CannotFill;
    // A complete call needs no plan unless a label moves an argument (01 —
    // `diff(b: 1, a: 10)`, `P(y: "a", x: 1)`): the plan is then a pure
    // reorder into declaration order, which every consumer applies alike.
    if (labels.len == params.len) {
        var any_label = false;
        for (labels) |l| if (l != null) {
            any_label = true;
        };
        if (!any_label) return null;
    }

    const slots = try arena.alloc(?usize, params.len);
    @memset(slots, null);

    // Pass 1 — every labelled argument claims the parameter it names.
    var claimed = try arena.alloc(bool, labels.len);
    @memset(claimed, false);
    for (labels, 0..) |maybe_label, ai| {
        const label = maybe_label orelse continue;
        const pi = for (params, 0..) |p, i| {
            if (std.mem.eql(u8, p.name, label)) break i;
        } else return error.CannotFill;
        if (slots[pi] != null) return error.CannotFill; // the same slot twice
        slots[pi] = ai;
        claimed[ai] = true;
    }

    // Pass 2 — the rest take the free slots in declaration order.
    var pi: usize = 0;
    for (labels, 0..) |_, ai| {
        if (claimed[ai]) continue;
        while (pi < params.len and slots[pi] != null) pi += 1;
        if (pi >= params.len) return error.CannotFill;
        slots[pi] = ai;
        pi += 1;
    }

    // Pass 3 — N2: every slot the call left empty must declare a default.
    for (slots, params) |slot, p| {
        if (slot == null and p.default == null) return error.CannotFill;
    }
    // A complete call whose labels name the parameters in order moves nothing.
    if (labels.len == params.len) {
        const identity = for (slots, 0..) |slot, i| {
            if (slot == null or slot.? != i) break false;
        } else true;
        if (identity) return null;
    }
    return DefaultFill{ .params = params, .slots = slots };
}
