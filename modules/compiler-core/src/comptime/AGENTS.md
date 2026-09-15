# compiler-core/src/comptime

> Path: `modules/compiler-core/src/comptime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Hindley-Milner type inference, comptime evaluation, and the AST transform
pass that specializes comptime calls. The façade is `../comptime.zig`
(`ComptimeSession`, `compile`, `compileTypesOnly`, `evaluateComptime`,
`registerStdlib`).

## Tree

```text
comptime/
├── AGENTS.md          ← you are here
├── types.zig          ← core Type union(enum)
├── env.zig            ← Env (binding name → *Type), registries, loc-keyed lowering tables
├── infer.zig          ← `inferProgramTyped` — HM walk, decorators, template expansion
├── unify.zig          ← type-variable unification + occurs check
├── error.zig          ← structured TypeError with source ranges + hints
├── diagnostics.zig    ← stable diagnostic-code string constants
├── eval.zig           ← comptime val evaluation entry (→ runtime/beam.zig)
├── render.zig         ← source-line helpers for diagnostic rendering
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()`
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── template.zig       ← `@Expr` templates: CapturedExpr, PlainArg, ScopeSnapshot, CustomNode, fail diagnostics
├── template_eval.zig  ← runtime-backed template body evaluation (erl)
├── decorator_eval.zig ← runtime-backed decorator body invocation (erl)
├── primOpTemplate.zig ← shared `#[@External.<Target>("…")]` template renderer ($self / $N / $args / $stringify)
├── snapshot.zig       ← comptime snapshot helpers
├── tests.zig          ← barrel: aggregates tests/<feature>.zig
├── tests/             ← comptime tests, split by feature — see tests/AGENTS.md
├── stdlib/            ← std prelude embedding — see stdlib/AGENTS.md
└── runtime/           ← persistent `erl` comptime runtime — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.contextBase`, `FnContext`, `TemplateEvalCtx` (`{ io, build_root }`), static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`), the `"std"` package tables (`stdModules`: module → fn exports; `stdModuleTypes`: module → pub type decls, registered into the importer by `markStdImports`; `stdModuleFns`: module → fn decls, used by `markStdImports` to reject a `from "std"` import whose `declare fn`s have no `@external` for `Env.target` (`std-unsupported-on-target`); `stdImports`: names imported via `from "std"`, which win over same-named value bindings like the primitive `bool`), the `decorators` table (name → `DecoratorSig{ params, fn_decl }`), and the loc-keyed lowering maps `method_lowerings` (`@Result`/`@Option` methods + the builtin `result` namespace), `result_jump_lowerings` (`return`/`throw` → `__bp_ok`/`__bp_error` in `#[@result]` fns), `jsMethodRenames` (type-directed JS-only renames, e.g. `string.contains` → `includes`, recorded only when the receiver's static type makes a global rename unsafe — `Set` also declares `contains`), and `instanceLowerings` (see `infer.zig`). |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. `registerExtensions` + `resolveReceiverCall` implement static extension dispatch. `registerFnSignatures` (via `buildFnSignatureType`) binds every top-level `fn` signature before any body is inferred, so mutually-recursive / forward-referenced fns resolve. Ends with `validateProgram` — `implement`/interface coverage + getter/setter checks. Top-level `test { … }` bodies type-check like void fn bodies via `inferTestDecl`; `assert cond` unifies `cond` with `bool`. `inferTypeMethods` walks record/enum method bodies (generics, `Self`, params) to type the calls and record their lowerings; it is **best-effort** (a body that trips an inference gap is skipped, not an error). Value-receiver instance calls are recorded in `env.instanceLowerings`: `.record <typeName>` or `.prim <PrimKind>` (array/string/bool/int/float — non-JS backends map it to a host op); commonJS ignores the table. `primMethodReturnTypeFromIface` derives a primitive method's return type from its interface signature so chains (`xs.filter(f).at(0)` → `?T`) keep tracking; `length`/`len`/`size` read the interface field. Generic-inference regression guards live in `tests/infer_generics.zig`. |
| `unify.zig` | Unification with substitution + occurs check. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`). |
| `diagnostics.zig` | Stable diagnostic-code constants (R1–R21, RF1–RF5, RI1–RI6, RC1–RC6, RG1–RG4, D1–D6, `std-unsupported-on-target`) plus the `all_codes` table. Messages live at the firing site. |
| `eval.zig` | `ComptimeEntry` / `RunResult` / `evaluate()` — routes comptime val entries to `runtime/beam.zig` (persistent erl). |
| `render.zig` | `extractLine` / `padSpaces` / `digitWidth` helpers for diagnostic rendering. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. Applies `method_lowerings` (`__bp_<domain>_<op>(…)`), `result_jump_lowerings` (`tryLowerResultJump`), `templateExpansions`, and `enumSectionRewrites` (`rewriteExpr`). Walks `fn` and `test { … }` bodies, including `assert` subexpressions. **Default-value expansion** (`expandTrailingDefaults` / `expandTrailingDefaultsWithParams`): when a call supplies fewer args than the callee's params and every missing trailing param has a `.default`, it appends `is_default_inj` args pointing at the param's own default Expr (no new Exprs materialized) — for free-fn calls (`fn_decls`, which also includes `env.stdlibFnDecls`) and record/enum-variant ctor calls (`ctor_params` from `env.ctorParams`; variants registered under bare and `Enum.Variant` names). Drops template fns and decorator fns from the output decls. |
| `template.zig` | `@Expr` template infrastructure: `CapturedExpr` (argument bound to a `comptime p: @Expr<T>` param, captured unevaluated with provenance), `PlainArg` (`{ paramName, source }` — a non-`@Expr` param or decorator argument that received a literal; `toExpr` turns its lexeme into an `erl_ast` expression), `ScopeSnapshot` (origin scope: caller's top-level decls + imports; `toJsonAlloc` feeds the memo key), `CustomNode` + `parseCustomNodeFromTree` (from `template_eval.CustomNodeTree`), and `mapSpanToLoc`/`failDiagnostic` (rustc-style `fail`/`failAt` diagnostics inside the caller's `"""…"""`). With contiguous text `mapSpanToLoc` counts newlines up to `span.start`; for holed multiline templates it falls back to `capture.loc.line + span.line - 1` (`span.line` is 1-based, line 1 = opening `"""` line). |
| `template_eval.zig` | Runs a template body that the V1 classifier cannot reduce. `buildModule` lowers the template `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode; host enums `BindingKind`/`DeclKind`; host records `Span`/`CustomNode`/`Binding`/`Source`/`Context`, so `Span(5, 9, 1)` / `CustomNode(kind: …)` build maps) and passes the host glue + `main/0` as `erl_ast` forms (`hostForms`). Each `@Expr` parameter receives `captureToTerm(capture)` — a map tagged `'__bp_capture' => Param` with `text` (raw literal text; holes appear as their `__bp_hole_<param>_<i>` placeholder), `parts` (`#{kind => <<"Text">>, text, span}` / `#{kind => <<"Interp">>, code => Placeholder, span}`), `source`, `context` and `bindings` (`#{name, kind => 'Record_'}`); plain parameters receive `PlainArg.toExpr`. Host functions: `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2` (binding map or `undefined`), `build/2`, `custom/3`, `fail/2`, `failAt/3`, `compilerError/1`, `expr/1`, `code/1`. `main/0` replies with JSON by result shape — `code`, `value` (`@expr`), `custom` (tree + code), `capture` (`return q`), `fail` (message/param/span), `error` — with `undefined` mapped to `null`. The module atom and file (`.botopinkbuild/tmp/template/template_<hash>.erl`) come from the code's hash; `persistent_erl.evalDetailed` runs it; `parseOutcome` maps the reply to `Outcome` (`value` → `TypedValue`, `ast` → `CustomNodeTree` with `ref: ?NodeBinding{name, kind}`), and compile/load/runtime failures become `err` with the Erlang diagnostic. Inline tests cover reply parsing. |
| `decorator_eval.zig` | Runs a decorator body over the declaration it annotates. Input: a native `DeclHandle` (`kind`/`name`/`fields: []FieldHandle`/`methods`/`returnType`/`annotations`) built by `infer.zig`. `buildModule` lowers the decorator `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode, `DeclKind` as host enum, `main/0` exported) and passes the host glue as `codegen/beam/erl_ast.zig` forms built with `Ast.Builder` (`hostForms`): `fail/2`, `failAt/3`, `compilerError/1` (throw a tagged rejection), `emit/1` (process-dictionary accumulator) and `main/0`, which calls the decorator with `handleToTerm(handle)` (a `codegen/beam/term.zig` map — `kind` as atom, names as binaries, annotation args as raw lexemes) plus the annotation arguments (`template.PlainArg.toExpr`: string/number/bool lexeme → expression; missing → `undefined`) and replies with JSON `{kind: ok, contributions} \| {kind: fail, message, span} \| {kind: error, message}`. The module atom and file (`.botopinkbuild/tmp/decorator/decorator_<hash>.erl`) come from the code's hash. `persistent_erl.evalDetailed` runs it; `parseOutcome` maps the reply to `Outcome` (`ok` / `fail{message, span}` / `err`), and compile/load/runtime failures become `err` with the Erlang diagnostic (truncated to 4 KiB). Inline tests cover the module shape and reply parsing. |
| `primOpTemplate.zig` | Shared renderer for `#[@External.<Target>("<template>")]` primitive-op templates. Substitutes `$self` (receiver), `$<N>` (positional arg), `$args` (all positional args, comma-separated) and `$stringify(<inner>)` (recursive render bracketed by the backend's `emitStringifyOpen`/`emitStringifyClose`, e.g. erlang `iolist_to_binary(io_lib:format("~p", [`…`]))`, node `JSON.stringify(`…`)`) through a backend-supplied ctx (`writeByte`/`writeAll`/`emitRecv`/`emitArg`/`argc`); other bytes pass through verbatim. Errors: `PrimOpArgIndexOutOfRange`, `PrimOpStringifyMalformed`, `PrimOpStringifyUnsupported`. `looksLikeTemplate(s)` (`$`-bearing) separates a template from the `module:symbol` form in erlang's `tryEmitPrimAnnotation`. **Arity branching** (`when(argc == N): "<template>"`): `parser.zig parseAnnotationCall` keeps each clause as one arg, `ast.parseArityBranchArg` extracts `{argc, template}`, the backend picks the matching branch (no match → falls through). **Triple-quoted** bodies: `ast.zig unquoteAnnotationArg` strips the fences plus one leading and one trailing newline. **BEAM consumer**: `codegen/beam_asm.zig renderBeamTemplate` uses the same walker with `emitRecv` → `{x, 0}` and `emitArg(i)` → `{x, i+1}` after pre-loading receiver/args; BEAM bodies are `#[@External.Beam("""<.S body>""")]` and are detected by `bref.module.len == 0`, not `looksLikeTemplate` (a body may have no `$` marker). |
| `snapshot.zig` | Snapshot helpers. |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` (plus the inline tests of `primOpTemplate.zig`, `diagnostics.zig`, `template_eval.zig`, `decorator_eval.zig`); harness in `tests/helpers.zig`. |

## Effect annotations (`#[@<effect>]`)

A function's effect is `ast.FnDecl.effect: ?EffectKind` (`result` / `future` /
`generator` / `iterator` / `asyncGenerator` / `context`), set by the parser from
a `#[@<effect>]` builtin annotation. The `*fn` prefix is rejected by the parser
(`deprecated-star-fn`). `inferFnDecl` validates the effect: it must match the
return wrapper (`effectMatchesReturn`); an effect on an interface method is an
error (`validateEffectAnnotations`), and so is one on a bodyless `declare fn` —
except `#[@result]` / `#[@future]` on a `declare fn` that carries an `@external`
annotation and returns the matching wrapper (`@Result<R, E>` / `@Future<T, E>`):
the host template owns the wrapper shape (used by `libs/std/src/asserts.bp`
`tryCatch` and `libs/std/src/http.bp` `fetch`).

The body context `starCtxFromEffect` → `env.starFn: ?StarFnCtx{ allowsAwait,
allowsYield, iterItem, effect }` gates `await` (future/asyncGenerator), `yield`
(generator/iterator/asyncGenerator) and `throw` (via `env.throwContext` for
`#[@result]`). `inEffectContext(env, .future)` fires `#[@future]`-only
rejections (RF1/RF2/RF5) without firing inside other effects.
`resultVariantCallName` / `futureConstructorCallName` /
`builtinRequiredGenericArgs` drive the syntactic rejections. Codegen reads
`f.effect` directly (`commonJS.zig fnKeyword`: future → `async function`,
generator/iterator → `function*`, asyncGenerator → `async function*`,
result/context → plain `function`).

Default-parameter diagnostics: D5 (defaulted param followed by a required one)
fires from `parser/decls.parseParamList`; D2 (positional arg after a named one)
from `parser/exprs.parseCallArgs`. The remaining D-codes are reserved constants.

`break [:label] [<expr>]` lives on the Jump AST as `@"break": struct { label:
?[]const u8, value: ?*Expr }` (mirrors `.yield`). Unbound labels (RI5) use the
same `env.labelStack` as `yield :label` (RI4) — declare the target with
`loop :name (…)` or `#[@iterator] fn … -> @Iterator<…> :name`.

## Testing helpers (`tests/helpers.zig`)

```zig
try h.assertInfersOk(std.testing.allocator, source);
try h.assertTypeErrorSnap(std.testing.allocator, @src(), source);
try h.assertComptimeAst(std.testing.allocator, @src(), modules);
```

## `@Expr` templates

`@Expr<E>` is the builtin expression type (named type `"Expr"` with one arg).
The generic parameter is **mandatory** — a result type only the expansion knows
is an ordinary fn generic (`fn yaml<T>(…) -> @Expr<T>`). `@Expr` params require
the `comptime` modifier (checked in `inferFnDecl`).

An argument bound to a `comptime p: @Expr<T>` parameter is type-checked in the
caller and captured **unevaluated**:

- `inferFnDecl` records `@Expr` params (`env.fnExprParams`) and registers fns
  returning `@Expr<…>`/`@ExprCustom<…>` as template fns (`env.templateFns`);
  `env.inTemplateFn` gates the construction builtins while their bodies infer.
- `buildScopeSnapshot` collects the module's top-level decls + imports into
  `env.scopeSnapshot` — the origin scope for `lookup`/`bindings` (function
  locals are not visible).
- `captureExprArg` unifies the argument with the inner `T`, requires a literal
  string, and records a `template.CapturedExpr` in `env.exprCaptures` (keyed by
  call loc) with text/parts, the opening-line location (the lexer stamps
  multiline literals with their *closing* line), module path and scope.
- `inferTemplateMethod` resolves the comptime-only methods on `@Expr` receivers
  (`value`/`text`/`parts`/`source`/`context`/`lookup`/`bindings`/`build`/
  `custom`/`fail`/`failAt`) and `ref()` on `Binding`, recording
  `env.templateLowerings`. The contract is `interface Expr<E>` in
  `libs/std/src/builtins.d.bp`, alongside `Span`/`Part`/`Binding`/`Source`/
  `Context` and the `@ExprCustom` carrier.
- Construction is **explicit**: `@expr(value)` (lift a comptime value) and
  `@code(text)` (parse generated source) are typed in
  `inferBuiltinCallReturnType` and only valid inside a template function.

Call-site expansion (`expandTemplateCall`, from `inferCallExpr`):
`classifyTemplateBody` reduces `return <@Expr param>`, `return @expr(E)` (E must
not reference the template's own params) and `return @code("…")` by inspection.
Anything richer goes to `expandTemplateCallViaRuntime` when `env.templateEval`
is set (always in `compile`; in `compileTypesOnly` only when an eval ctx is
passed) — otherwise the V1 "cannot expand" error. The runtime path requires
`captures.len + plainArgs.len == tfn.params.len`, memoizes by callee + capture texts + scope JSON + plain arg
values in `env.templateEvalCache` (holed captures and `@ExprCustom` calls are
never memoized), and maps the outcome: `code` → `parseCodeText` +
`substituteHoles`; `capture` → the captured node; `value` → `valueToAstLiteral`
(`TypedValue` → literal / array / anonymous record); `custom` → `code` spliced
like `code`, tree via `template.parseCustomNodeFromTree` into
`env.customAstByLoc`; `fail` → `failDiagnostic`.
`finishExpansion` re-infers the expansion in the caller's env, unifies against a
concrete `@Expr<T>` / `CustomExpr<T>` bound, and records it in
`env.templateExpansions`; transform substitutes it and drops the template fns.

Holed templates: each `${…}` part is exposed to the body as a
`__bp_hole_<param>_<i>` placeholder; `substituteHoles` splices the caller's hole
AST back after parsing and walks every expression-bearing position (closure/fn
bodies, branches, loops, bindings, jumps), so a placeholder inside a lambda body
still resolves.

Cross-module: `registerExports` publishes template `FnDecl`s into
`comptime.zig`'s `template_registry`; `resolveImports` registers them via
`registerImportedTemplateFn`, so calls expand in the importing module
(template-built code re-infers in the **caller's** scope — no hygiene).
Imported `pub` nominal types carry their AST decl the same way
(`type_decl_registry` → `registerImportedTypeDecl`) so the importer sees the
full `TypeDef` (`implements`/`contextBase`/fields), not just the constructor
binding; `resolveTypeName` (env.zig) maps a constructor binding back to its
named type in annotations.

**Package-default DSL**: a package may declare one `pub default mod <handle>;`
(`ModDecl.isDefault`) and one `pub default fn` (`FnDecl.isDefault`), in any
module. `registerExports` pairs them per package (`pkgKey` = module-path prefix
before the first `/`) and aliases the handler under the handle in both the
value-export table and `template_registry`. `import <handle> [, { … }] [from "…"]`
(`ImportDecl.package`) binds `<handle>` in `resolveImports`, so `<handle> "…"`
resolves through the ordinary template path. `validateUniqueDefaults` rejects a
second default mod/fn in one module. For an external lib the default mod's
module must be listed in the lib's `botopink.json` `files`.

### `@ExprCustom<T>` — code plus a reference tree

A template fn may return `@ExprCustom<T>` to carry the executable `code` *and* a
generic reference AST built by a sub-language (SQL, markup, …).
`TypeRef.isExprCustomType` (grouped with `@Expr` under `isTemplateReturnType`)
resolves it to the `CustomExpr<T>` struct (`{ code: Expr<T>, ast: CustomNode }`)
in `resolveTypeRefInContext`. The body packs both halves with
`q.custom(tree, code)`; `tree` is a `CustomNode`
(`{ kind, span, label, ref: ?Binding, children }`) whose `kind`/`label` are
opaque lib-chosen tags — the core never branches on them. `CustomNode` is
registered as a constructible record via `custom_ast_reflection_src` in
`registerStdlib`.

Expansion outcome `.custom { code, ast }`: `code` is spliced exactly like a
`.code` outcome; `ast` is converted with `template.parseCustomNodeFromTree` and
stored in `env.customAstByLoc` (loc → callee + root + template file/line/col) —
never lowered, never reaches codegen. `comptime.zig` surfaces the entries on
`OkData.custom_ast` (`[]CustomAstEntry`, re-exported by `root.zig`). Tooling opts
into expansion via `compileTypesOnly(allocator, modules, eval_ctx)`; the LSP
(`language-server/src/compiler.zig`) passes a ctx when it has an eval root, and
with `null` templates stay unexpanded and no runtime is touched.

## Annotation processors / decorators

A **decorator** is an ordinary comptime function whose first parameter is
`comptime _: @Decl` (`TypeRef.isDeclType`). Both `fn` (with body) and bodyless
`delegate` forms are recognized. The core provides only the generic protocol —
recognize → reflect → invoke → apply; marker meaning lives in the lib body.

- `registerFnSignatures` calls `registerDecoratorSig` for every top-level `fn`
  and `delegate`, recording the trailing params and the body-carrying `FnDecl`
  in `env.decorators`.
- The reflection cluster (`enum DeclKind { Record, Struct, Enum, Interface, Fn,
  Method, Field }` + `record Decl`/`Field`/`Method`/`Param`/`Annotation`/`Span`)
  is registered by `registerStdlib` from `decl_reflection_src` (a mirror of
  `libs/std/src/builtins.d.bp` — keep in sync). `Decl` is a record so the array
  members `fields`/`methods`/`annotations` resolve.
- `registerStdlib` also parses `libs/std/src/builtins_fns.d.bp` (the parseable
  `declare fn` slice: `todo`/`panic`/`trap`/`emit`/…) into `env.stdlibFnDecls`,
  which `compile`/`compileTypesOnly` merge into transform's `fn_decls` so
  trailing defaults are injected at bare `todo()`/`panic()` calls. The synthetic
  `Result`/`Future`/`Iterator`/`Generator`/`AsyncIterator`/`Context` interfaces
  stay doc-only in `builtins.d.bp` (they are pre-registered by
  `Env.registerBuiltins`).
- `@compilerError(message)` — generic compile-time rejection usable from a
  decorator or template body without a `@Decl` handle. commonJS lowers it to
  `__compilerError`; the decorator and template Erlang modules define
  `compilerError/1` (a tagged throw reported like `fail`).
- `validateDecorators` walks every declaration's annotations (record/enum/fn/
  interface + methods + record fields) and `checkDecoratorArgs` type-checks
  `#[name(args)]` for recognized decorators: arity (honoring trailing defaults)
  and a lexical kind check (`string`/numeric/`bool`/enum member). Unknown
  markers stay lenient.
- **Invocation:** `invokeDecorators` (skipped when `env.skipDecoratorInvoke` or
  no `env.templateEval`) builds a `decorator_eval.DeclHandle` per annotated
  decl — `Fn`, `Record` (with `FieldHandle`s), `Enum`, `Interface`, plus
  per-`Field` and per-`Method` handles — and `runDeclDecorators` calls
  `decoratorEval.evaluate` for each body-carrying decorator (annotation args
  become `PlainArg`s). `fail` and `err` become a `TypeError` (coarse loc; the
  message carries the detail — for `err`, the Erlang compile/runtime
  diagnostic); `ok` appends `@emit` sources to `env.contributions`. An
  evaluator that cannot run at all (no `erl`/`erlc`) reports "the decorator
  evaluator failed to run".
- **Order:** `validateDecorators` + `invokeDecorators` run in
  `inferProgram(Typed)` right after `registerFnSignatures` (handles read only the
  AST). If there are contributions, body inference is deferred:
  `inferProgramTyped` still returns the source decls' bindings (imports, types,
  fn signatures), then `comptime.zig analyzeSource` re-analyzes with the
  contributions — `parseAndMergeContributions` + `analyzeMerged` (AST append),
  falling back to `spliceContributions` + a full re-analysis when a contribution
  does not parse standalone — with `skipDecoratorInvoke = true` (no loop). So an
  `@emit`ed decl is visible to any body (including `test {}` under
  `botopink test`). In `types_only` (LSP) a failed re-analysis falls back to the
  pass-1 bindings; the full `compile` keeps the error.
- Member-level annotations parse on record bodies (`parser/decls.zig
  parseRecordBody`): `RecordField`/methods carry `annotations`, so
  `#[getMapping]` on a method and `#[inject]`/`#[value]` on a field reach both
  passes.
- Decorator fns are comptime-only: `transform.zig` drops any fn whose first
  param is `comptime _: @Decl`; the decls it contributed stay.
- **Cross-module:** `registerExports` publishes decorator `FnDecl`s into
  `comptime.zig`'s `decorator_registry`; `resolveImports` rehydrates them via
  `infer.registerImportedDecorator`, so `#[name(args)]` in an importing module
  both arg-checks and runs the body (mirror of the template registry path).

## `@Context<B, R>` capability inference

`use` is a **prefix operator** (`use <hookcall>`); bindings come from the
enclosing `val`/`var` (`val {v, s} = use state(0)`, `use effect { … }` for void).
AST node: `Expr.useHook { inner }`. It is gated by the function's return type:

- The return must implement `@Context<ContextBase, Return>` — directly
  (`fn f() -> @Context<Element, R>`) or via a named type whose `implement`
  clause lists `@Context<…>`.
- Every `use` in the body must return `@Context<B, _>` with the **same**
  `ContextBase` (transitive through custom hooks).

Wiring in `infer.zig`: `contextBaseFromImplements` computes `TypeDef.contextBase`;
`inferFnDecl` records the body's capability in `env.fnContext`
(`contextInfoFromReturn`); `inferUseHookExpr` checks `env.fnContext` then
`validateUseBase` and types the prefix as `R`. Diagnostics: `useNotAllowed`,
`useNotContext`, `contextMismatch`. `val {v, s} = use …` binds leniently via
`bindUseDestructure`.

Codegen lowers `use` per target (commonJS → React hooks with inferred
dependency arrays; other targets treat `use` as a transparent prefix). Phantom
`@Context` base structs are erased — see `codegen/AGENTS.md`.

## Anonymous record types + `Children` coercion

- `resolveTypeRefInContext` lowers `TypeRef.record_type` (`{ f: T, … }`) to a
  structural `Type.record`, unified field-by-field (same field set + order)
  with a `record { … }` literal.
- `childrenCoercion` (checked in `unifyAt`, target-first) lets an argument bind
  to a `Children` parameter when it is `Children`, any array, a `string` (text
  child), or a single `@Context` value (one-element list). One-directional.
- A function-typed record field (`set: fn(next: T)`) is an ordinary `Type.func`
  field.

## `case` exhaustiveness + reachability

`checkCaseExhaustiveness` (infer.zig) checks a single-subject `case` on an
**enum** or **string** subject after the arms are typed:

- **Coverage** — an unguarded arm covers a variant when it is a bare variant
  ident or `Variant(payload)` with an irrefutable payload (bindings/wildcards).
  Refined payloads (`Ok(1)`) don't cover. OR-patterns cover each alternative.
- **Catch-all** — `_` or a non-variant identifier. A `string` subject is only
  exhaustive with a catch-all.
- **Guards** — a guarded arm neither covers a variant nor shadows later arms.
- **Diagnostics** — `nonExhaustive` (missing variants, or a wildcard request)
  and `redundantPattern` (arm after a catch-all, or a repeated variant).

## Enum sections

`registerEnum` desugars `EnumDecl.sections` into enum-of-enum form: each section
becomes a synthesised inner enum registered as `__<EnumName>__<SectionPath>`
(segments joined by `__`), and the parent gains one wrapper variant per
top-level section (`Section(_inner: __EnumName__Section)`). `registerEnumSection`
recurses depth-first. Pure-digit variant names (`EnumVariant.numeric`) are
mangled with a `__` prefix (`500` → `__500`) — a single `_` would trip
commonJS's `tupleIndexMember` heuristic (`t._N` → `t[N]`). Inner enums live in
the type-def table only; their variant names are not bound at top level.

Path access (`.Color.Red.500`): `tryResolveEnumSectionPath` collects a
`dotIdent`-rooted chain (≥ 2 segments) and `resolveSectionPathInEnum` walks
registered enums through `_inner` fields, returning qualified nested ctor calls
typed against the parent enum. A chain rooted at a plain `.ident`
(`Color.Red.X`) keeps the normal identAccess path. `buildSectionPathRewrite`
builds the equivalent untyped ctor chain into `env.enumSectionRewrites` (keyed by
the outer identAccess loc) and `transform.zig rewriteExpr` substitutes it;
synthesised nodes carry loc `{line=0, col=0}` so the rewrite is not re-triggered.

`comptime.zig withSynthesisedEnumDecls` (after `transform` /
`withUsedAssocInterfaces`) prepends every `env.synthesisedEnumDecls` entry as a
top-level `EnumDecl` and adds the section-wrapper variants to each parent enum,
so backends emit them through the normal enum path.

Parser-side invariants (`parser/decls.zig parseEnumItem` → `raiseUnexpected`):
numeric variant names only inside sections, without payload, and never as a
section name; duplicate section names are rejected.

## Children

- [`runtime/AGENTS.md`](runtime/AGENTS.md) — persistent `erl` comptime runtime.
- [`stdlib/AGENTS.md`](stdlib/AGENTS.md) — std prelude embedding.
- [`tests/AGENTS.md`](tests/AGENTS.md) — comptime tests.
