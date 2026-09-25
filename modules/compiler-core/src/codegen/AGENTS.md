# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`
(`generateWith(alloc, modules, io, config, options)` runs the comptime session,
then the selected backend's `codegenEmit`, which returns one `ModuleOutput` per
module — a failed one carrying its diagnostic). On a host that cannot spawn a
process (`../comptime/runtime/runtime.zig` `can_spawn` — the browser build,
`modules/compiler-web/`) `options.execute` is refused with
`error.NoExecutorOnThisHost` and `runtime.zig` is never analysed; the executors
below exist on native hosts only.

Top-level `test { … }` declarations (`DeclKind.@"test"`) are **skipped by every
backend** in normal `build`/`run` output — they are only collected and emitted
under `botopink test` (`Config.test_mode`): commonJS emits
`async function __bp_test_N` functions + a `__bp_tests` registry +
`__bp_run_tests()` runner; erlang emits `'__bp_test_N'/0` functions +
`'__bp_run_one'/1` / `'__bp_run_tests'/1` + a `main/1` escript entry. In test
mode `assert` lowers to a recoverable per-test failure (JS: throwing
`__bp_assert`; Erlang: `erlang:error({bp_assert, Msg, Loc})`) and `fn main/0`
is not auto-invoked. BEAM and WAT have no test runner.

## Tree

```text
codegen/
├── AGENTS.md         ← you are here
├── config.zig        ← Config / TargetSource (commonJS|erlang|beam|wasm) / TypeDefLang
├── moduleOutput.zig  ← GenerateResult, ModuleOutput
├── crossModule.zig   ← backend-agnostic cross-module link index (exports + imported set)
├── patterns.zig      ← backend-agnostic pattern facts (does a pattern bind names?)
├── commonJS.zig      ← CommonJS backend: builds the JS model (blind: iterates transformed AST)
├── js/               ← JS/TS code model + the only JS/`.d.ts` writers — see [`js/AGENTS.md`](js/AGENTS.md)
├── erlang.zig        ← Erlang source emitter (blind)
├── beam_asm.zig      ← BEAM Assembly `.S` emitter
├── beam/             ← BEAM term model + shared `.erl`/`.S` emitters — see [`beam/AGENTS.md`](beam/AGENTS.md)
├── wat.zig           ← WAT backend: lowers to the wat code model, writes no text
├── wat/              ← WAT code model + emitter + runtime helpers — see [`wat/AGENTS.md`](wat/AGENTS.md)
├── typescript.zig    ← `.d.ts` backend: builds the TypeScript declaration model
├── runtime.zig       ← executes generated code in tests (RUN LOG capture)
├── snapshot.zig      ← codegen snapshot builder / assertions
├── tests.zig         ← barrel: aggregates tests/<feature>.zig + js/*.zig + beam/*.zig for test_root.zig
└── tests/            ← codegen tests, split by feature
    ├── helpers.zig             ← shared harness (`assertJs`/`assertJsError`/`configs`/…)
    ├── values.zig              ← val/fn/call/operators/assign/self/comments
    ├── aggregates.zig          ← array/tuple/record
    ├── control_flow.zig        ← case/loop/if/try/throw/catch
    ├── comptime.zig            ← comptime folding/specialization/validation
    ├── builtins.zig            ← builtin/stdlib/assert
    ├── dispatch.zig            ← extension dispatch (implement/interface/delegate)
    ├── features.zig            ← lambda/enum/destructure/star/import/range/pipeline/hooks
    ├── externals.zig           ← `#[@External.<Target>(…)]` FFI declarations
    ├── narrowing.zig           ← state narrowing (null checks, case variants, type guards)
    ├── std_package.zig         ← `from "std"` qualified calls, a method on the type an imported module answers, builtin `result` namespace
    ├── wat.zig                 ← WAT backend codegen
    ├── dts_skips_templates.zig ← `.d.ts` drops `@Expr`/`@ExprCustom` template fns
    ├── runtime_scratch.zig     ← pins the `.botopinkbuild/tmp/<hex>/` scratch layout
    └── comptime_module.zig     ← `emitComptimeModule` (untyped lowerings, primitive-method shims, host enums, variable versioning)
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config` (`targetSource`, `typeDefLanguage`, `build_root`, `test_mode`, `packages` — decision 109's package owner of each module, `comptime_runtime`), `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `TypeDefLang`, `ComptimeRuntime` (`beam` \| `wat`). `comptime_runtime` null — every driver — is decision 84 (the target's VM: erlang/beam → beam, commonJS/wasm → wat); the codegen harness sets it to generate one program under both runtimes. No CLI flag or build option reaches it. |
| `moduleOutput.zig` | `AmbiguousVariant` (a bare variant name more than one enum of the program declares, written where nothing says which — `variant`, and two of the enums; `diagnostic(alloc)` renders the refusal with both qualified spellings, and the erlang emitter raises it through the same errdefer slot pattern `MissingExternal` uses). `MissingExternal` (06 C13 — the host-backed fn a backend has no `#[@External.<Target>(…)]` for: name, target and call site; `diagnostic(alloc)` renders it as a `Diagnostic.type`, so the failure reaches the driver LOCATED and only that module fails, instead of `error.MissingExternalTarget` aborting the build with its own name). `GenerateResult` (`js`, `typedef`, `units`, `comptime_script`, `comptime_err`, `diagnostic`, `run_output`; `failed()`) and `ModuleOutput` — shared between targets. `Unit` is one EXTRA module a source file produced on a BEAM target — policy 3 of `13-module-identity`: a `type` declared in the file is a module of its own, `atom` (`crossModule.typeAtom`, `app@models@@Person` — decision 109) being both the `-module` and the artifact's basename, `code` its text. commonJS and wasm produce none — a class already is the type's identity there (decision 5) and wasm is single-module. Everywhere the file's own module goes, its units go with it: `cli/build.zig` writes them, `runtime.zig` compiles and loads them as `AuxFile`s, `snapshot.zig` renders one section each. A module whose comptime outcome is `.parseError`/`.typeError` is not skipped: every backend's `codegenEmit` appends `ModuleOutput.failedModule`, whose owned `Diagnostic` (`syntax`: the `SyntaxError` with its slices copied; `type`: the rendered message and location) outlives the comptime session. `Module` lives in `../module.zig` |
| `crossModule.zig` | **Cross-module link index** built once over every module's transformed program (`build(alloc, outputs)`). `exports` maps a `pub` symbol → `ExportInfo{module, kind, is_class, fields, methods, is_external, erlang_backed, arity}` (emitting module path, decl kind, whether construction needs `new`/the owner's map shape, and a record's declared field order, its methods as `MethodSig{name, arity}` — the arity is half a method's identity, so a consumer can ask whether two types of the program claim one `name/arity`, whether a `fn` export is host-backed, and whether that host-backed one carries an `erlang` target usable at its declared arity — the erlang backend routes such an import to the owner's wrapper, see [erlang](#erlang)); host-backed `#[@External.<Target>(…)]` fns are indexed too, so a consumer importing one `from "<lib>"` links to the owner like any other export. `imported` is the set of names some module imports. **`exports` is keyed by the bare symbol NAME, and a name is unique inside a module and never over a program** — `libs/std` declares `parse` in `json`, in `querystring` and in `url` today — so a plain `get` answered with whichever module the walk reached last, no dissent check and no diagnostic. `owners` is the population that collapse threw away: EVERY `pub` declaration of a name, in walk order. `pick(name, source, arity)` asks the question properly — the module the import's own `from "<mod>"` NAMES answers first (`ast.ImportSource.namesModule`: the full path or its last segment; a PACKAGE handle names the package and narrows nothing), then the arity the CALL takes (`ExportInfo.arity`, the `MethodSig` widening on the plain-`fn` axis), and when neither separates the candidates the answer is `.contested`, never the first one (decision 67). `picked` is the same for a caller with a dynamic fallback: a contest reads as absent. `export_faults` keys a `Contested` by the CONSUMER module path — a name several modules export is not itself the defect (refusing the declaration would refuse `libs/std`, thirteen of whose names collide), what cannot be answered is a consumer reaching for the bare name with nothing saying which — and every backend's `codegenEmit` turns it into a located diagnostic exactly as `atomFault` is turned, because the collapse is in this index and not in any one emitter. Consumed by commonJS, erlang and beam_asm; wat only uses it to flag unlinkable imports and to pick which module it links in. **It also owns the Erlang/BEAM module atom** (option A, amended by decision 109): `erlAtom(alloc, ModuleId)` renders the owning PACKAGE and the module path as one legal UNQUOTED atom — `package ++ "@" ++ path`, lowercase · `/` → `@` · anything outside `[a-z0-9_@]` → `_` · a run of `_` collapsed to one so `__` stays free for the comptime qualifier — so `main` of package `myapp` is `myapp@main`, `std/math` is `std@math` and `web/api/http` is `myapp@web@api@http`. `ModuleId` is `{path, package, package_in_path}`; `Packages{root, deps}` (`Config.packages`, set by the CLI from `botopink.json` — `libs.packagesOf`) answers `idOf(path)`: a path whose first segment names a dependency (the embedded `std` always does, `EMBEDDED_PACKAGE`) is that dependency's, with the package already in the path, and every other path is the root package's. A module of no package (`Packages.root` empty: compiled outside any `botopink.json`) renders no atom — `error.MissingPackage`, which `build` turns into the located `no_package` fault, so an erlang/BEAM compilation without a manifest is refused and never given a fallback name. The compiler's own tests compile under the implicit manifest `test` (`TEST_PACKAGE`, `test_packages`, set on every `tests/helpers.configs` entry and used by the runtime harness) — `test@main`, `test@main@@Person`. The comptime evaluators' modules live in `COMPILER_PACKAGE`, `bp` (`bp@comptime__tpl__…`), which `manifest` refuses as a `name`. A package that does not start with a lowercase letter is `error.InvalidPackageName`, never quoted (`manifest.nameRefusal` refuses it first). Every atom holds an `@`, so none is an OTP module's name: option A's `RESERVED` list and its `bp@` prefix are gone. It was the path's BASENAME, which made `models/user` and `services/user` the same module and let eleven `libs/std` modules shadow the OTP module of the same name node-wide. `declAtom(alloc, id, decl)` names the module a DECLARATION becomes (decision 109): `erlAtom(id) ++ "@@" ++ <Decl>`, the declaration KEEPING ITS CASE (only a character outside `[A-Za-z0-9_]` folds to `_`), so `type SourceLocation` in `main.bp` of `myapp` is `myapp@main@@SourceLocation` and `type File` in std's `io/fs.bp` is `std@io@fs@@File` — still an unquoted atom, and `DECL_SEP` (`@@`) can occur in no module atom (a path segment is never empty) and be produced by no source name. `<Decl>` is a `type`'s own name or the `val` an `implement` block is bound to (`pond_pkg@pond@@PatoNada`; nothing emits an `implement` module yet), and an inline `type Pato(…) implement Swimmer { … }` clause's methods are `pond_pkg@pond@@Pato`'s. `erlDeclAtom(alloc, id, Kind, decl, ?hash)` is left to the COMPTIME producers only (`bp@comptime__<tpl|dec>__<decl>__<16 hex>`) — `Kind` has no `t`/`b`/`im` any more. `typeAtom(alloc, id, decl)` is the identity of a `type` — `declAtom(id, decl)`, so `type Person` in `app/models.bp` of `myapp` is `myapp@app@models@@Person`: the module policy 3 puts its methods in AND the tag half 3 puts inside every value it builds, one renderer because the tag has to name the module that formats it — and `variantAtom(alloc, id, decl, variant)` appends `__v__<variant>` (the variant lowercased, its `_` runs collapsed) so the five `Circle`s of the ecosystem stay five atoms: `myapp@main@@Shape__v__circle`. `decodeAtom` is `split("@@")` for a declaration or a variant tag (the last `__v__` of the declaration half splits off the variant), the `__` qualifier for a comptime module, and the module half's first `@` for the package (`Decoded.package`; an atom with no `@` is `UndecodableAtom`). The atom is the identity on the two BEAM targets only: a commonJS value's identity is its class prototype (decision 5) and a wasm value's is its descriptor's ADDRESS (decision 22), whose bytes hold the bare declaration name `@print` shows — neither carries a module-qualified string, so nothing there spells the atom, `outputStem(target, alloc, id)` gives the artifact's basename (the atom for erlang/beam, the module path for commonJS/wasm), and `ATOM_MAX_BYTES` is 250 (the `<atom>.bea#` filename limit, not the atom limit). `CrossModule.atomFor(path)` reads the atom `build` rendered once per module and `ownerModuleAtom(name)` the owning module's; `atomFault(path)` is the **collision check** — two paths rendering one atom (`duplicate`), a module of no package (`no_package`), a package name that cannot start an atom (`invalid_package`) or an over-long atom (`too_long`), each which the erlang and BEAM `codegenEmit`s turn into a located diagnostic instead of letting one module silently overwrite the other. The same check runs over each module's **type** atoms (`duplicate_decl`, `too_long`), and it is **case-insensitive** (decision 109): `Person`/`person` are two atoms (`main@@Person`, `main@@person`) but one `.erl` on a case-insensitive file system, so the pair is refused and the message names both atoms; `Foo-Bar`/`Foo_Bar` fold to one atom outright and the message says so (`FooBar`/`Foo_Bar` do not collide); pinned by a `build` test on each — across modules the path already tells them apart, so this half is per module and fails the module as a whole. `moduleBasename(path)` survives for the places that compare a SOURCE-level name (an `import { order } from "std"` namespace, a `wat.zig` import segment) and is no longer a module atom |
| `patterns.zig` | **Backend-agnostic pattern facts.** `bindsNames(pattern, ctx, isVariant)` answers whether a pattern binds at least one name — the question every backend asks before lowering a `val assert P = e [catch h];` (decision 8 § 9), which binds `P`'s names in the ENCLOSING scope. A pattern that binds nothing (`val assert 42 = answer catch 0;`) is a pure check and keeps the single-expression lowering it always had. `isVariant` is the backend's own variant table (a bare identifier is a binding only when it names no variant) |
| `js/` | JS/TS code model + emitters shared by `commonJS.zig` and `typescript.zig`: `js_ast.zig` (`Expr`/`Stmt`/`Pattern`/`Block`/`Class`/`Item` + the `.d.ts` `TsDecl`/`TsType` + `Builder`), `js_emitter.zig` (the only writer of JavaScript: reserved-word renaming, string escaping, parenthesisation, indentation, semicolons), `ts_emitter.zig` (the only writer of `.d.ts`). The backends build nodes and write no target text. The remaining `js_ast` bridges pin the shapes the current lowering still emits illegally. See [`js/AGENTS.md`](js/AGENTS.md) |
| `beam/` | BEAM term model + emitters shared by `erlang.zig`, `beam_asm.zig` and the comptime evaluators: `term.zig` (`Term`), `erl_emitter.zig` (Erlang source: atom quoting incl. reserved words, variables, module names, binaries), `beam_emitter.zig` (`.S` operands and `move`s). One quoting rule for `.erl` and `.S`. See [`beam/AGENTS.md`](beam/AGENTS.md) |
| `commonJS.zig` | CommonJS backend — builds `js/js_ast.zig` nodes, rendered by `js/js_emitter.zig`. See [commonJS](#commonjs) below |
| `erlang.zig` | Erlang source emitter. See [erlang](#erlang) below |
| `beam_asm.zig` | BEAM Assembly `.S` emitter, assembled with `erlc +from_asm`. See [beam_asm](#beam_asm) below |
| `wat/` | WebAssembly-text code model and the only writer of `.wat`: `wat_ast.zig` (`Module`/`Item`/`Func`/`Seq`/`Instr` + `Builder` + the invariants), `wat_emitter.zig` (s-expression layout, `$` names, data escaping), `wat_prelude.zig` (the runtime helpers as built nodes). See [`wat/AGENTS.md`](wat/AGENTS.md) |
| `wat.zig` | WAT backend: builds `wat/wat_ast.zig` nodes and hands them to the emitter. See [wat](#wat) below |
| `typescript.zig` | `.d.ts` typedef backend (optional secondary output, `Config.typeDefLanguage`) — builds `js/js_ast.zig` `TsDecl` nodes, rendered by `js/ts_emitter.zig`. Type declarations only — no call lowering. A package import in the `.d.ts` keeps only names the owner emits (`CrossModule.exports`): a template fn or a lib namespace handle has no declaration there, so `import { html } from "view"` is dropped instead of dangling. Parameter types come from `Param.typeRef` (the parser leaves the legacy `typeName` empty; an unannotated position is `any`, a zero-argument generic such as `@Decl` is the bare name). Skips template fns (`TypeRef.isTemplateReturnType()`) and phantom `@Context` structs, erases `@Context<B, R>` to `R`, renders an anonymous `TypeRef.record_type` as `{ f: T; … }`. **A botopink primitive takes its TypeScript spelling** (`primitiveTsName`: every integer and float width plus `int`/`uint`/`float`/`isize`/`usize` → `number`, `bool` → `boolean`, `char` → `string`; `string`, `void` and `unknown` are spelled the same) — a `.d.ts` naming `i32` is not TypeScript. **An enum declares the class the JavaScript builds** (decision 5): `readonly tag` as the union of the variant names, a `static` factory per payload variant returning the enum type, a `static readonly` singleton per payload-less one, and each enum method as a `static` whose `self` is typed as the enum. It was a TypeScript `enum` of strings or a discriminated union of plain objects before, and the `.js` beside it built neither. **Decision 8 §3's union `A | B`** rides on `TypeRef.generic` under the reserved name `ast.union_type_name` (`"|"`), and takes TypeScript's own union (`TsType.union_`) rather than the generic path's `|<A, B>`, which is not TypeScript. **The `import { … };` shorthand** resolves through `CrossModule.exports` here too, one `import` per owning file, where it used to write the literal `from "./module"` |
| `runtime.zig` | Test-side execution for the snapshot `----- RUN LOG -----` block. See [runtime](#runtime) below. `executeTestModule` runs a **test-mode** module the way `botopink test` does (`node main.js` / `escript main.erl`) and answers its output whatever the exit status — the decision-74 FAIL line is a non-zero exit, which the snapshot path records as an empty RUN LOG, and `executeErlang` never runs a test module (no `_botopink_main`) |
| `snapshot.zig` | `buildSnapshot` / `buildSnapshotMulti` / `assertCodegen` / `assertCodegenError` — paths `codegen/<comptime runtime>/<target>/<slug>` and `codegen/<comptime runtime>/errors/<target>/<slug>` (front 18 step 4, decision 85), the runtime being `Config.comptime_runtime`, which the harness sets on every recorded generation (`runtimeDir`: none is `error.SnapshotWithoutComptimeRuntime`); `writeComptimeSections` writes `GenerateResult.comptime_trace` (`COMPTIME ERLANG` under `beam/`, `COMPTIME WAT` under `wat/` — the runtime that evaluated — then `COMPTIME REPLY`, rendered by `comptime/trace.zig`) then `COMPTIME VALUES` for every backend. A `SnapInput` with `result == null` (the module never reached the backend) or with `comptime_err` set writes a `COMPILE DIAGNOSTIC` section instead of the code section — spec 06 H3, which used to leave such snapshots empty. `writeUnitSections` adds one `----- ERLANG -- <atom>.erl` / `----- BEAM ASSEMBLY -- <atom>.S` section per `GenerateResult.units` entry, so a cell shows every module its program loads and `beam_export_audit.sh` — which keys on the `{module, …}` form, not on the fixture — assembles each of them. `writeRunLog` is the one writer of the `----- RUN LOG -----` section on every backend, and it normalises the `botopink test` envelope's `  duration <digits>ms` line to `  duration <ms>ms` (`isDurationLine`: the two-space indent, the word, digits, `ms` — nothing a program prints by accident): that line is the runner's wall clock around each test body, the ONE nondeterministic line of the envelope, and a snapshot pinning its digits (`src_in_a_test` recorded `0ms`) failed on any machine slower than the one that wrote it — `1ms` under load, the only line that differed. `tests/helpers.zig`'s `stripDurationLines` is the same rule for `assertTestModeRunLog`, which writes no snapshot |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` plus the `beam/*.zig` and `wat/wat_emitter.zig` unit tests; harness in `tests/helpers.zig` (`assertJs`, `assertJsSingle`, `assertJsError`, `assertJsTestMode`, `assertJsContains`, `assertJsNotContains`, `assertJsRunLog`, `assertDtsContains`, `assertConsumerJs`, `configs` — one config per target). The snapshot-free helpers are what a **single backend's** row uses: a snapshot carries the same program through all four, so a commonJS-only fixture would write into the erlang, beam and wasm snapshot directories other fronts own |

### commonJS

- **Model, not text**: every `build*` method returns a `js/js_ast.zig` node and
  `js/js_emitter.zig` renders the module (`writeProgram`). The backend owns the
  lowering decisions listed below; quoting, the reserved-word rename, string
  escaping, parenthesisation, indentation and semicolons belong to the emitter.
  Nodes are built in one arena that is freed once the module is rendered. The
  only text this file still composes is a comment's wording, a `require` path
  and the fixed test-harness source (`Item.runtime`).
- **Module-level `val` / `var`** (`buildValDecl`, front 17 step 2, decision 38):
  `const` for a `val`, `let` for a `var` — the choice `buildStmt` already made
  for a local from `localBind.mutable`. Node's `Assignment to constant variable`
  on a reassigned `const` is what made decision 38 a compile-time rule; the
  front's problem program prints `2` on node.
- **`@print` / `@println` / `@debug`** (decision 8 §7, `buildPrintCall`) lower to
  the on-demand prelude helper `__bp_print(a, b)`, not to `console.log`: each
  argument is written by `__bp_show` — a top-level string bare, a nested string
  quoted with the source escapes, an array `[1, 2]`, a tuple `#(1, "a")`, a
  record `Point(x: 1, y: 2)`, a variant `Shape.Square(side: 4)` /
  `Shape.Nothing`, a type implementing `Display` its own `display()` (nested
  too), anything else `util.inspect`. §7 supersedes decision 1a's no-spaces
  text.
  A botopink value is told from a host object by the `__bp` marker its
  prototype carries (decision 5) — never by a `constructor` test, so a `Map` or
  a `@Result`'s `{ ok }` keeps `console.log`'s own text. The name comes from
  `__bp` plus the variant's `tag`, and the fields from `Object.keys(value)`,
  which is exactly the payload in declaration order because both markers live
  on the prototype.
  **Two things the formatter cannot read off the value**, and both reach it as
  the static print shape the call site passes
  (`__bp_print_as([["#", null, null]], p)`): a **tuple**, which is a JS array,
  and an **`f64`**, because JavaScript has one number type and §7 wants `5.0`.
  `printShape`/`typeShape` recover a shape from a tuple or float literal, an
  array literal of those, a local or parameter bound to one (`print_shapes`), a
  top-level fn's declared return type, and a primitive method's declared return
  type (`zip` → `Array<#(T, U)>`); `"f"` is the float leaf, `f64`/`f32` in a
  written type. A tuple whose shape nothing recovers prints as an array, and an
  `f64` whose shape nothing recovers prints as an integer — `for (xs) { v ->
  break v * 0.15; }` is the measured case, and a union member (decision 26) is
  the other, since a union carries no single leaf.
- **`@Result`** is `{ ok: V } | { error: E }`; `__bp_ok`/`__bp_error` build it for
  `return`/`throw` in `#[@result]` fns; `try`/`catch` lower to `"error" in _r`
  pattern matching. A `case` arm `Ok(v)` / `Err(e)` / `Error(e)` that names no
  variant the module declares tests the key the same way (`if ("ok" in _s)`,
  `const v = _s.ok;`), never `_s.tag` — a Result carries no tag (C5).
- **A value is a class instance** (1.0.5-beta decision 5): `buildRecord` emits
  `class Point`, `buildEnum` emits `class Shape` plus a `class Shape$Circle
  extends Shape` per variant, a `static` factory per payload variant, and a
  singleton `Shape.Dot = new Shape$Dot()` per payload-less one. Each class
  carries `prototype.__bp` (the source name — the §7 formatter's marker) and
  each variant subclass `prototype.tag` (its own name). The full table is in
  [`js/AGENTS.md`](./js/AGENTS.md#what-a-value-is-105-beta-decision-5).
- **`==` on tuples** (decision 8 §6 T6) is structural: when either side's print
  shape is a tuple, `==` lowers to the `__bp_eq` prelude helper and `!=` to its
  negation. A tuple is a JS array, so `===` compared references and two equal
  tuples were unequal.
  **The defect is wider than tuples, and the helper is already wider**
  (decision 35): `===` answers `false` for *every* composite value, measured as
  `record → false`, `[1,2,3] → false`, `#(1,"a") → false`, `Circle(2.0) → false`,
  `"abc" → true`, with wasm the same and erlang `true` throughout by accident of
  representation. Decision 35 settles it structurally for all four, as a
  consequence of decision 37: without mutation, identity is unobservable.
  `__bp_eq` walks arrays and tuples element-wise and a class instance by
  constructor plus own fields — the one shape decision 5 gave a record and a
  variant.
  **Only a tuple reaches it today**, because this backend walks the *untyped*
  AST (`buildExpr(e: ast.Expr)`) and the only thing it can learn about an
  operand is the static print shape, which says "holds a tuple" and nothing
  else. Turning the row on for a record, an array or a variant needs the
  operand's type at the site — a per-`Loc` mark from inference, the way
  `method_lowerings` already does it — which crosses `01-checker`.
- **Loops are statements** (decision 105, front 22): `for (xs) { x -> … }` is
  `for (const x of xs)`, `for await (gen) { x -> … }` is `for await (const x of
  gen)`, `while (cond) { … }` and `loop { … }` are `while` — every one built by
  `buildLoopStmt` under `LoopCtx.stmt`, where `break;` / `continue;` are the
  native statements. No loop has a value: the comprehension, the search and
  decision 52's `null` of decision 8 §10 are gone, and a `break <v>` reaches
  this backend only inside a generator scope, where it is `yield v; return;`
  (`buildBreakStmt`) from any loop depth. **`#[@generator] loop { … }`**
  (`buildGeneratorLoop`) is a `function*` IIFE whose body runs under
  `while (true)` — the captured `var`s are the closure's, so a counter the body
  reassigns is generator state for free; `#[@futureGenerator] loop` is
  `async function*`. `a...b` materialises one more element than `a..b`.
- **`x is T`** (decision 8 §4, `buildIsCall`/`isTest`) tests the **value**, not
  where it came from, which is what makes one lowering answer for a known
  static type and for a value arriving through `unknown` or a union: an integer
  type is `typeof === "number"` + `Number.isInteger` + its range, `f64` any
  number, `string`/`bool` the primitive, a tuple an array of the right arity
  with each element tested, `?T` null-or-`T`, an array its constructor only
  (§4.2 — an element type is not checkable), and a **named type** an
  `instanceof`, free under decision 5. A **variant path** (`x is Token.Text`)
  is `(_v instanceof Token && _v.tag === "Text")` when `Token` is an enum this
  module declares with that variant or imports by name, and `(_v != null &&
  _v.tag === "Text")` for any other path — `Token.Text` is a factory and
  `Token.Eof` a singleton, never a class, so the written `instanceof` threw
  `TypeError`. The subject is bound in an arrow
  (`((_v) => …)(x)`) only when the test reads it more than once, so a call on
  the left is evaluated once. An unrecognised spelling answers `false`. The
  parser synthesises this as the `is` builtin call with the type on `isType`
  (`ast.is_builtin_name`); before the lowering it fell through to the
  unrecognised-builtin path and wrote `@is(p)` into the module — a `@` is not
  JavaScript, and `build` exited 0 on a file node cannot parse.
- **Variant payload arms**: `collectVariantFields` indexes every local payload
  variant's declared field names; `Circle(r) ->` binds positionally
  (`const { radius: r } = _s;`). A variant declared in another module keeps the
  binding as the key. A payload-less variant arm tests `_s.tag === "Name"` —
  always, in every module.
- **A variant's identity is its `tag`, never its class.** A payload-less arm
  used to test `_s instanceof <Enum>$<Variant>` whenever the bare name was
  unique in the module, and `tag` only when it repeated. A class is
  per-emitted-COPY identity and a copy is emitted per module for every enum a
  module cannot `require` — an enum SECTION desugars into an inner enum that no
  module exports, so `Token.Text.Size` is re-emitted in each module that names
  it. A value built in a consuming package was then never `instanceof` the
  class the library matched against: the arm did not fire, no later arm did
  either, and the whole `case` answered `undefined` at exit 0, with no
  diagnostic. `tag` is a string on the prototype, so it crosses every copy,
  module and package boundary, and it is what `variantTest`, the payload arms
  and `@Result` already used. `unit_variant_names` therefore records only the
  NAMES, to tell a variant from a binding. Pinned by
  `tests/language/modules/package_variant_identity/`, which one package cannot
  express. `is`/`val assert` still test `instanceof` (below) and inherit the
  same limit wherever a class is re-emitted.
- **One spelling can name both a `type` and a variant, and the arm tests
  BOTH** (`patternTest`'s `.ident`, `isDeclaredVariantName`). Decision 8 §5.3b
  says which one a `case` arm means — the SUBJECT's type does, and a section's
  leaves are written bare (`Bold`, `Block`) — but this emitter walks the
  untyped AST and has no subject type, so a name that is a `class_names` entry
  AND a declared variant becomes `(_s instanceof Block || _s.tag === "Block")`.
  The subject makes at most one of the two possible: a variant singleton is
  `instanceof` no class, and a class instance carries no `tag`. Emitted as the
  `instanceof` alone — which is what half 3's step 16 wrote, because §3.3's arm
  over `Person | Vec` needs it — emilia's `Token.Layout` arm never fired:
  `output` exports a record `Block`, the section carries a `Block` leaf, and
  `tokenDeclarations(.Layout.Block)` answered the empty string at exit 0 while
  erlang and wasm answered `display:block` (223 passed / 2 failed against
  225 / 0, from one source). Pinned by
  `tests/language/run/case_arm_name_is_also_a_type.bp`, which runs on all four.
  The other two backends resolve the collision by PRECEDENCE instead, and each
  gets the mirror case wrong: erlang's `patternNodeExtra` asks `enum_variants`
  first, so a `case` over a union of records whose arm names a record some enum
  also declares as a variant matches the variant atom and dies with
  `case_clause`; wasm's `findVariant` searches every enum for a bare name, so a
  SECTION whose name also names a record answers its parent's first arm. Both
  are reported, neither is this backend's.
- **Self tail calls are a LOOP, not a frame** (`selfTailLoop`, D6 of
  1.0.10-beta `00 · 04-js`). V8 has no tail-call elimination, so `return f(…)`
  inside `f` cost a stack frame per round and a few thousand rounds ended the
  program — while erlang and beam, whose VMs drop the frame, ran the same
  source to the end. `std`'s `random.intInRange` found it: its `floorWalk`
  helper is hand-written tail recursion, one frame per unit of range, so a
  range of a few thousand was `RangeError: Maximum call stack size exceeded` on
  node and a correct answer everywhere else. Measured: the old shape took
  10 000 rounds and not 20 000.
  The rewrite runs on the BUILT js nodes, after the body is lowered: every
  `return <self>(a, b);` becomes `{ <temps> <assignments> continue; }` and the
  body becomes the body of a `while (true)`. An argument that READS a parameter
  is staged in a `__bp_tc<i>` temporary, because the assignments happen in
  order and an earlier one would be visible to a later argument; an argument
  that IS its own parameter is dropped. A call inside a loop of the function's
  own continues a LABELLED loop (`__bp_tc:`), since a bare `continue` would go
  round that inner loop. Falling off the end of the body becomes an explicit
  `return;` — inside the loop it would otherwise start another round.
  **What still recurses**, and this is the limit a reader may rely on, not an
  oversight: a call that is not in tail position (`return 1 + f(n - 1)`);
  MUTUAL recursion (`a` → `b` → `a`) — a trampoline would have to change every
  call site and every module's calling convention, which is a far larger price
  than the shape is worth; a call through anything but the function's own name
  (`this.m(…)`, a value holding the function); a function that creates a
  closure reading one of its parameters (the closure outlives the round that
  made it, so reassigning the parameter would change what it sees); one that
  names `arguments` (sloppy mode maps it onto the parameters); one with a
  destructuring or defaulted parameter (nothing to assign to); one that binds
  its own name locally; and anything but a plain `function` — a generator's
  `return f(…)` resumes an iterator rather than ending one, and an `async`
  one's answer is a promise. Pinned by
  `tests/language/run/self_tail_recursion.bp` (every target) and three
  `control_flow.zig` cells that RUN.
- **`.len`**: `s.len` / `arr.len` on a typed string/array (inference records
  `.prim` in `instance_lowerings`, threaded in as `Emitter.lowerings`) emits
  the native `.length` property; a record field named `len` is untouched (C3).
- **Static extension dispatch**: `implement`/`extend` blocks emit as namespace
  objects (`buildExtensionNamespace`: `const Sym = { m(self){…} }`, no prototype
  patching); an activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the
  loc-keyed `dispatch_rewrites` map.
- **Method renames**: the loc-keyed `js_method_renames` map (from inference) is
  consulted first, then the annotation-derived `prim_node_renames`
  (`s.contains` → `s.includes`). That type-naive map skips a name that two
  primitive behaviors send to different host symbols — `at` is `String.at` →
  native `charAt` and `Array.at` → native `at` since decision 63's amendment —
  because it is what the `Array` default-fn bodies materialised as prototype
  patches are emitted with (`first`'s `self.at(0)` became `this.charAt(0)` on an
  array and threw on node); such a call keeps its own name unless inference typed
  the receiver. The disagreement is read off the WHOLE embedded std registry
  (`ambiguous_prim_renames`, filled while `collectBuiltinNodeDispatch` parses
  `primitives.bp`), not only the program's behaviors: with a String `default fn`
  in use the scanned program carries the String behavior alone, `at → charAt`
  looked unambiguous there, and `parts.at(0)` on a typed `string[]` — whose
  per-loc rename is "none", `Array.at` being its own host symbol — fell through
  to it as `parts.charAt(0)` (`libs/std`'s `querystring.bp`, caught by
  test-libs). The type-naive map is still what `append → concat` rides on for a
  typed receiver (a `default fn` with a `Node` symbol takes the default-fn
  path, which records no per-loc rename), so it is not gated on typing. A rename to `length` on a no-arg call emits
  the native `.length` **property** without parens (a `member` node, not a
  `call`); inference
  records it only for typed array/string receivers, so a record `length()`
  method is untouched. **A rename names a native method that matches the
  SIGNATURE**, not one that shares the botopink name: `Array.reverse` answers a
  reversed array and leaves the receiver alone (`lists:reverse/1` on erlang, a
  fresh array on wasm), and native `Array.prototype.reverse` reverses in place,
  so while the annotation read `#[@External.Node("reverse")]` commonJS alone
  also reversed the receiver — a fold that read it again answered one thing
  there and another everywhere else, at exit 0. It names `toReversed`
  (ES2023, node 20) since `fix/js-instanceof-boundary`, and the rename is
  type-naive, so it reaches every `.reverse()` call site and not only the ones
  inference typed. Pinned by
  `tests/language/run/array_reverse_answers_a_new_array.bp`, which reads the
  receiver AFTER the call — no commonJS snapshot exercises `reverse` at all.
- **The only external spelling is `#[@External.<Target>(…)]`.** `FnDecl.isExternal`
  (`ast.zig`) matches on the `External.` prefix, so the retired lowercase
  `#[@external(<target>, …)]` and the retired bracket form `@[external(…)]` match
  nothing: a declaration carrying one parses, type-checks and is silently
  host-less — every backend then reports the fn as unbound. Turning the
  lowercase spelling into a located parse error is a parser change and belongs
  to front 06; until then, the form is inert, not supported.
- **Externals**: `#[@External.Node("module", "symbol")]` fns (`collectExternals`)
  lower to `const { symbol: name } = require("module");` (a JS global such as
  `Math` is referenced directly). A symbol carrying `$` markers or
  `when($argc == N)` branches is a template rendered inline at each call site
  (`user_node_templates`); so is a 1-arg form without markers
  (`#[@External.Node("process.cwd()")]`), a bare host expression rendered
  verbatim — neither emits an import binding or a `require(…)`. A `pub`
  template fn is also emitted as a real function whose `$N` holes are its
  parameters (`buildTemplateWrapper`; an arity-branched one tests
  `arguments.length`, a template naming a `self` receiver gets none) plus `exports.<name>`, so a
  cross-module call through the module object (`env.write(…)` after
  `import {env} from "std"`) resolves; calls in the owning module still inline
  the template. A fn with no `node` target raises
  `MissingExternalTarget` when called.
- **A template on a BEHAVIOR method is a prototype patch, not a call-site
  render** (`buildInterface`): it becomes `<Owner>.prototype.<m> =
  function(…){ return <template with $0 = this[.valueOf()]> }` and every call
  site dispatches through it. So the template must not call the method it
  patches — it would call the patch. `String.charCodeAt` read
  `(($0.charCodeAt($1) ?? -1) | 0)`, and since the whole `String` prelude is
  installed into any module using a member that needs a patch (`slice` does;
  `split`/`indexOf`/`startsWith` do not), one `s.slice(…)` made every
  `.charCodeAt(…)` in the PROGRAM blow the stack. The template body is opaque
  host text (`js_ast.Expr.host`), so there is nothing to rewrite into a call of
  the original; the rule is instead **gated** by
  `codegen/tests/externals.zig`'s `no prelude template calls the method it
  patches`, which walks the embedded prelude. Pinned end to end by
  `tests/language/run/string_char_code_after_slice.bp`.
- **`assert`** (semantics decision 4): outside test mode it is always fatal —
  `__bp_assert_fatal(cond, msg, "<module>.bp:<line>")`, a prelude helper that
  throws `Error("<msg> at <file>:<line>")` (`"assertion failed"` without a
  message), so node exits non-zero naming both. Test mode is unchanged: the
  `__bp_assert` harness helper throws for the runner to catch per test.
- **`try` inside a `test` body** (1.0.10-beta decision 74): `buildTryStmt`'s
  `.propagate` arm emits `throw new Error(typeof e === "string" ? e :
  JSON.stringify(e))` while `Emitter.in_test_body` is set (by `buildTestFn`;
  cleared in `buildArrow`/`buildLambda`), so the runner's `catch` prints
  `FAIL <name>  (<e>)  at <file>:<line>`. Everywhere else the arm keeps its
  `return _tryN;`.
- **`val assert P = e [catch h];`** (decision 8 § 9): the IIFE the construct has
  always lowered to — the pattern check, then the subject or the handler's value
  — is bound to `_assert<N>` and `appendPatternBinds` declares the pattern's own
  names from it, in the enclosing block where the statements after it read them
  (`buildStmts`, not `buildStmt`: one botopink statement becomes several JS
  ones). A pattern that binds nothing keeps the bare IIFE. `buildPatternCheck`
  tests an `Ok`/`Err`/`Error` that no module declares with `"ok" in _match`, the
  same key test the `case` arms use — `_match instanceof Ok` named a class no
  module ever emits, so every `val assert Ok(…)` took its handler.
- **A tuple element called by position** (`c._1(9)`, what 06 N24's labelled
  `c.set(9)` becomes) is an INDEX, never a property: `c[1](9)`. erlang applies
  `element(2, C)`, beam takes the same route as a record field holding a fun
  (read, then `call_fun`), and wasm cannot apply it at all — it has no function
  values, so the module traps.
- **Prelude helpers** (`js/js_prelude.zig`): a call `recv.m(args)` whose
  receiver inference recorded as a primitive (`instance_lowerings` `.prim`)
  and whose native JS method disagrees with the declaration calls a helper
  instead — `s.at(i)` is `__bp_string_char_at(s, i)` (`null` out of
  range). An open-ended range is `__bp_range_from(start)`. `Emitter.helper` marks it, and only marked helpers are declared at
  the top of the module. Interface default-fn bodies are not inferred, so a
  `at` inside one stays native.
- **Duplicate test names**: two `test "x"` blocks in one module print
  `warning: duplicate test name "x" in <mod>.bp:<line>` to stderr; both run.
- **Cross-module linking** (`crossModule.zig`): `from "<pkg>"` imports become
  `require("./<path>.js")` of the owning file (declaration-only names such as
  decorators emit nothing); imported records are marked as classes so
  construction emits `new`; a `pub` fn, record or enum always emits
  `exports.X` (its `.d.ts` declares it exported, and a module-object consumer
  such as `order.Order` needs it), while a `pub implement` is exported only
  when another module imports it.
- **The `import { … };` shorthand** (1.0.5-beta decision 3) names no module, so
  it resolves exactly the way a `from "<pkg>"` import does: name by name through
  the cross-module export index, one `require("<prefix><owner>.js")` per owning
  module. It used to fall through to a branch that wrote the literal word —
  `require("./module")` at the project root, `require("../module")` under a
  package prefix — a path nothing emits, so the program built and then died at
  run time. The namespace-handle block below is skipped for it: the shorthand
  names no package, so there is no handle to bind.
- **A path and a group bind their leaf (decision 107)**: every backend reads
  `imp.leaf()` (the exported name), `imp.name()` (the local binding — the
  alias when written) and `ImportDecl.leafSource` (the module the prefix
  names, handed to `CrossModule.picked` in place of the decl's `from`), so
  `import {url.parse, json: {parse as parseJson}}` reaches two owners.
  commonJS destructures `{ leaf: alias }` (`js.ObjectPattern.Prop.bind`) —
  from `std/<prefix>.js` for a std symbol leaf, or binds the module object
  for a std namespace leaf (`comptimeMod.isStdModule` decides which;
  `import {io.fs}` → `require("./std/io/fs.js")`); erlang keys `std_imports`
  local name → std module path and maps an alias back to the declared name
  at the remote call (`import_aliases`); beam records `imported_fn_owners`
  (local → owner atom + declared name) ahead of the name-keyed
  `crossOwnerOf`; wat, which links statically, registers the alias beside the
  declared name in every fn table and maps it back at the `call`
  (`import_aliases`).
- **Lib namespace object**: when an import names the lib itself
  (`import {Lib} from "Lib"`) and that name has no emitted symbol, `emitUse`
  binds the lib's module object (`buildUse`: `const Lib = require(…)`, or
  `Object.assign({}, …)` across several modules) so `Lib.member(...)` resolves.
- **Import dedup**: `seen_imports` lowers each binding name to at most one
  `const { … } = require(…)` per module (repeated imports, e.g. from several
  `@emit`s, would otherwise redeclare `const x`).
- A record's no-`self` associated fn (`Response.ok(…)`) is a `static` class method.
- **Interface associated fns** (`Pair.of`) emit into a namespace object, except
  on JS-global-backed primitives (`isJsGlobalNamespace(jsPrototypeOwner(name))`:
  `Array`/`String`/numeric/`Bool`), where they become statics on the existing
  global (`Array.range = function…`) — `const Array = {}` would shadow the
  global.
- **Bare `throw`** (JS-6, decided): rejected, not a rethrow. The parser
  requires an operand (`throw [new] <expr>`), so `throw;` is a parse error on
  every backend (`throw_bare_throw_inside_try_catch_is_rejected` pins it on all
  four) and `js.Stmt.throw_` carries a required operand; a null operand
  reaching commonJS is `error.ThrowWithoutOperand`. The erlang twin
  (`erlang.zig`'s `raw("")` for a null `throw_`) is equally unreachable.
- **Destructuring**: a destructuring parameter takes no default
  (`function greet({ name })`); a nameless `..` in a record or list pattern
  ignores the rest, which JS destructuring already does, so it emits no rest
  element — and a nameless `..` in an array *literal* contributes nothing.
- **Case tests** (`patternTest`): a pattern that matches anything (`_`, an
  alternative that is `_`, a **binding**) has no `if`; a multi-subject arm
  (`case a, b { 0, 0 -> … }`, subject `[a, b]`) tests the conjunction over
  `_s[i]`; a shape with no test is `false`. Decision 8 §5's shapes ride on
  `Pattern.variant` under `shape`, and each has a test of its own: `.tuple`
  (`#(0, s)`) is `Array.isArray` plus the arity — `>=` when `..` is written —
  plus each element's test at `_s[i]`; `.range` (`1...5`) is `_s >= lo && _s <=
  hi`, both ends included; `.variant` is the `tag` compare (or the `"ok" in _s`
  key test for an `Ok`/`Err` naming no declared variant) conjoined with each
  **nested** payload pattern's test (`.Some(#(a, b))`).
- **A bare name in a pattern is a test or a binding** (`isBindingName`): a
  variant path (`.None`), a primitive type spelling (`i32` — §5.2's type-test
  arm, which takes §4.1's run-time test, the one `x is T` builds) and a
  capitalised or declared name are **tests**; anything else binds and matches
  anything. That is what tells `Red` from the `s` of `#(0, s)`.
- **A pattern's bindings come from one place** (`appendPatternBinds`), which a
  `case` arm and a `val assert` share: a payload field is read by the **label
  the pattern wrote** when it wrote one and by the declared field at that
  position otherwise (`.Rect(height: h, width: w)` reads `height` for `h`, §5.1
  P4), a tuple element from `subject[i]`, and a nested pattern recursively from
  the field it stands for.
- **A pattern's variant name is taken bare** (`bareVariantName`): the
  constructor writes the declared name onto `<Variant>.prototype.tag`, while a
  pattern keeps the path it was *written* with (`ast.Pattern`: `Shape.Circle`,
  `.Circle`, `Circle` are all the same variant, §5.1 P8), so every read of a
  pattern's name — the `tag` test, the `variant_fields` field lookup that makes
  `Circle(r)` bind positionally, and `resultKey` — drops everything up to the
  last `.`. A `Pattern.ident` carrying a `.` is a variant path, never a
  binding, so the guarded-identifier arm (`x when (…)`) does not take it.
- **An arm block's value is its last expression** (`buildCaseBody`): a
  `break <value>` in the block still wins, and otherwise the block's final
  statement is returned when it is unambiguously a value
  (`isArmValueExpr` — a literal, identifier, operator, call, collection or
  function; a trailing `val`, `if`, `loop` or jump stays a statement). Without
  it the arm's value was dropped *and* execution fell through into the
  following arms.
- **A one-parameter arm block binds the subject** (`_ { v -> … }`): the arm
  lambda's single parameter is `const v = _s;` at the top of the arm — the only
  scope where the subject is in hand. The checker types it as the subject
  narrowed by the arm's pattern.
- **A lambda's last statement is a return position** (`buildLambdaTail`): a JS
  arrow block does not auto-return, so every expression form `buildExpr` gives a
  value to is `return`ed there — the same rule `buildIfLast` applies one level
  down, and the same rule a `val x = <e>;` binding already gets. The whitelist
  that used to decide it (`isImplicitReturnExpr`) listed only the categories
  that are *always* a value, so an `if`, a `loop` and a `try`/`catch` tail fell
  through to `buildStmt` and were written as statements —
  `(x) => { (() => { … })(); }` — and the arrow answered `undefined`. A `case`
  never had the defect (it is a `.collection`). Still statements: a jump, a
  binding, a `use` hook, and any `if`/`loop` whose body jumps out of the lambda
  (`exprJumps`), because a `return` cannot cross the IIFE the value form wraps
  it in. `try`/`catch` goes through `buildTryStmt` with the `.ret` head, not
  `.discard`.
- **`comptime { … }` with no `break <e>`** in value position is `undefined`
  (a block's value comes only from `break`).
- **None is loose**: botopink has one none value and JavaScript spells it two
  ways (`?.` answers `undefined`, so does `Array.at` past the end), so `==` and
  `!=` against a `null` literal lower to the loose `==`/`!=` — and so does the
  **optional-binding** guard (`if (val e = …)`, and the `a ?? b` that desugars
  into it): `if (n != null)`. Under a strict `!==`, `o.inner?.v ?? 9` answered
  `undefined` where erlang and wasm answered `9`. Every other `==` is `===`.
- **Index** (`buildIndexCall`, decision 30): `receiver[index]` reaches the
  backend as the builtin call `ast.index_builtin_name` (`"[]"`) over
  `(receiver, index)`, so one node carries the element read and the slice. A
  `range` index is `.slice(start, end)` — `.slice(start)` when open-ended, the
  one place an open-ended range is not `__bp_range_from`; any other index is a
  JS index, which answers an array's element, a tuple's member (a tuple is a JS
  array) and a string's character alike. **A `Dict` read `d["k"]` is not
  lowered**: a `Dict` is a botopink record over a `pairs` association list, so
  the read is `d.at("k")`, and choosing that needs the *receiver's type* —
  which this backend does not have (`instanceLowerings` carries a kind only for
  call sites `comptime/infer.zig` recorded, and it does not type this call at
  all yet: `xs[0]` is still `void`). Today `d["k"]` emits the JS property read
  and answers `undefined`. `01-checker` types the call by the receiver; the
  dict arm lands with it.
- **Ranges**: `a..b` materializes `Array.from({length: Math.max(0, b - a)}, …)`,
  `a...b` the same with `b + 1` (decision 105: inclusive); an open-ended `a..`
  is the lazy `__bp_range_from(a)` prelude generator (`function*` counting up
  forever), so `for (x..) { i -> … break; }` runs. There is no index binder
  (decision 105): `for (0..xs.length) { i -> }` is the spelling.
- **Enum methods**: variant values carry no methods (a payload variant is a
  plain `{ tag, … }` object, a nullary one its name). A method whose first
  parameter is `self` or typed `Self` takes the value as a real first parameter
  (`area: function(self) {…}`), and a call `recv.area()` whose receiver
  inference typed as an enum this module declares (`enum_recv_methods`) or
  imports by name (`imported_enums`) lowers to `Shape.area(recv)`
  (`enumMethodOwner`). A method with no parameters that reads `self`
  implicitly keeps the `this` body and is not lowered.
- **User interface `default fn`s**: an interface that is not a JS global owns
  no constructor, so its instance defaults are copied as class methods into
  every local record that implements it and does not define the method
  (`appendInterfaceDefaults`, following `extends`); nothing is patched onto
  `Iface.prototype`. An implementer in another module does not get them yet.
  A module that redeclares a primitive interface (`behavior Number { fn
  max(self: Self, other: Self) -> Self; … }`) replaces the prelude's
  declaration; a bodyless member without its own `@External.Node` takes the
  prelude's (`prelude_iface_externals`), so `Number.prototype.max` is still
  patched.
- **Builtin dispatch is for free calls**: `builtin_node_dispatch` (`print`,
  `todo`, …) applies only to a call with no receiver — `d.print()` on a record
  is the record's method.
- **Tuple index**: `t._N` and the bare `t.N` are `t[N]`.
- **Effects**: `effectShape` is the one table — it answers the two JS
  modifiers (`is_async`, `is_generator`) an effect asks for, and `FnShape
  .keyword()` spells them as `async function` / `function*` /
  `async function*` for a declaration. A **method** carries its effect on its
  annotation list, not on an `effect` field (`ast.BehaviorMethod` has none), so
  `methodEffect` reads it back: a record's own body, a record's `implement`
  block and an enum's body all route through it, and a class member spells the
  same two modifiers without the `function` word (`static async *name`,
  `js/js_ast.zig`'s `ClassMember.is_async` / `.is_generator`). Reading
  `ast.FnDecl.effect` alone is what made `#[@iterator] fn each(self: Self)`
  emit a plain method whose `loop … yield` lowered to a value-dropping
  `.map()`. A `behavior`'s `default fn` is the one method kind that never
  carries one — the checker refuses `effect-on-behavior-method-forbidden`.
  Inside a generator, `return <iter>` becomes `yield* <iter>; return;` and
  `for (xs) { x -> yield x; }` becomes `for…of`.
- **A labelled argument claims its slot**: `docs.md` § Parameters with defaults
  — "a parameter the call names by label keeps the argument it was given,
  whichever position it is in". `labelledArgs` places the arguments of a
  **fully-written labelled call** into the slots their labels name, for the two
  call shapes whose slot names this backend knows: a record constructor
  (`record_fields`, its own records and — through
  `CrossModule.picked(name, u.source, null)`, so the declaration the import
  NAMES answers and not whichever module the walk reached last — the ones it
  imports) and an enum variant reached through its own enum (`variant_fields`
  + `variant_owner`, guarded by `variantSlotsFor` so a method that happens to
  share a variant's spelling is never re-ordered, and so a variant name TWO
  enums of the module declare claims nothing: `variant_fields` is keyed by the
  bare name and keeps one entry, so there is no slot list that is certainly its
  own).
  Anything else — a call mixing labelled and positional arguments, a label
  naming no declared field, a trailing lambda, an arity that is not the slot
  count — keeps the positional path byte-identical rather than placing on a
  guess (decision 67). **A free function's and a method's parameters are not
  claimable here**: the checker still types a labelled call by position
  (1.0.10-beta `00 · 01-checker`, the full-arity labelled row), so re-ordering
  them in one backend would type against one parameter and pass another.
- **Control flow (no statement in expression position)**: a jump is a
  statement, so every position that can hold one is lowered by `buildStmt`:
  - an `if` in statement position whose branches `return` / `break` /
    `continue` (or, inside a generator scope, `break <v>`) is a JS `if` statement
    (`buildIfStmt`; the `if (val e = …)` form keeps its binding in a `{ … }`
    block). Any other `if` stays the value IIFE, and a jumping `if` in a value
    position is `error.JumpInValuePosition`;
  - a loop is a statement (decision 105): `for…of` / `for await…of` / `while`
    (`buildLoopStmt`, `loop_ctx = .stmt`), `break;` / `continue;` native, and
    inside a generator scope `break <v>` is `yield v; return;`; an annotated
    `loop` is the generator IIFE (`buildGeneratorLoop`) — see the row above;
  - `return case … { … }` where an arm returns from the function (the
    `#[@result]` wrap puts `__bp_ok(…)` around a whole `case`, so `Fail -> throw
    e` is `return __bp_error(e)` inside it) lowers the `case` to statements in
    a block (`buildReturnCaseStmt`): value arms `return ({ ok: v })`, the jump
    arm keeps its own `return`;
  - `throw` in value position is a one-statement IIFE; a binding in value
    position is `error.BindingInValuePosition`. `try x catch return y` in value
    position still returns from the value IIFE (the `try`'s value becomes `y`);
    the statement-position lowering is the one that leaves the function.

### erlang

- **One module per `type` — policy 3 of `13-module-identity`.** A source file
  emits its own module plus one per `type` it declares
  (`crossModule.typeAtom` → `myapp@main@@Person`, `std@dict@@Dict` — decision 109; `test@main@@Person` in the snapshots, which compile under the implicit test manifest), carried out
  as `GenerateResult.units`. A type's instance methods, its associated fns and
  the behavior `default fn`s it adopts are that module's, exported under **the
  names the programmer wrote** — the module boundary is what erlang's flat
  function namespace lacked, so `recordMethodAtom`, `record_method_collisions`,
  `isRecordMethodCollision` and `collectRecordMethodCollisions` are **gone**:
  two types can each declare `greet/1` and there is no collision left to mangle.
  `openTypeUnit` / `closeTypeUnit` bracket a unit: the file module's helper state
  (`needs_*`, `prim_shims`, `needed_instance_defaults`) is set aside for its
  duration, so each module carries exactly the helpers its own bodies reached,
  and `cur_type` decides the shape of every call made inside — a call to this
  type's own methods is local, one into the file's functions is a remote call
  the file module then exports (`fileCall` → `file_exports_needed`, which is why
  the `-export` form is written into a placeholder and filled once every
  declaration is lowered). `typeCall` is the single site that spells a method
  call: local inside that type's module, `atom:m(Recv, …)` everywhere else,
  with `typeModuleAtom` answering the owner's atom for an imported type.
  A receiver inference left untyped (a behavior's `default fn` records no
  lowering) routes through `method_owners` — `method/arity` → the one local type
  declaring or adopting it; two claimants leave no entry and the bare call
  stands, which is what the receiver's own tag will decide in half 3.
  **"The one type declaring the method" is counted over the PROGRAM, not over
  this file** (`methodOwnerContested`), the method axis of the field count
  below: `method_owners` sees only this file's declarations and `imported_fns`
  is keyed by the method NAME alone, first writer wins, with no arity and no
  dissent check, so with two imported records declaring `toArray` the export
  index's hash iteration order picked the owner — `Grouping`'s body over a
  `Query` tuple, which is `{error, badarg}` when the field offset is past the
  tuple and a neighbouring field's value when it is not. Both populations vote
  now — this file's `method_owners` entry and every `pub` record/enum of
  `CrossModule.owners`, matched on `name/arity` (`ExportInfo.methods` is
  `crossModule.MethodSig{name, arity}`, not a bare name; `owners` rather than
  `exports` because two modules declaring one type NAME are one entry there,
  and the second `describe/1` never got to vote), skipping this file's own
  declaration by MODULE rather than by name for the same reason — and one dissenting
  declaration sends the call to `'__bp_method'/3` (`dynamicMethodNode`,
  `method_helper_form`), which applies `element(1, V)`'s module, keeping the
  `maps:get` dispatch for a map receiver exactly as `'__bp_field'/2` does.
  Pinned by `tests/language/modules/method_name_collision`, and measured on the
  consumer library that found it: 1 passed / 8 failed → 9 / 0 on erlang.
  **A `type` with no bodied method emits no module**: an artifact holding one
  `-module` line is not written and no snapshot section shows one. Half 3 gives
  every type a `format/1` and the unit stops being empty then.
  **A `behavior` emits no module of its own** (decision 23: a behavior has no
  run-time representation; were it reopened, its module would be
  `<package>@<path>@@<Behavior>` like every declaration's, decision 109). That is a
  deliberate departure from policy 3 §2.2, which would put a behavior's
  associated `default fn` in a module of its own and emit it once: the assoc default keeps
  `interfaceAssocAtom`'s mangled local (`array_range/2`) in **every** consuming
  module, as it always has. Decision 23 is newer than §2.2 and wins; §2.2's
  "emitted once" is therefore still open, and it is the behavior module that
  would close it.
- **Cross-module calls are remote calls.** Erlang resolves a bare `f(X)` in the
  CALLING module, so a name this module imports but never defines must name its
  owner: `imported_fns` (built in `collectImportedTypes` from the cross index)
  maps an imported `pub fn`, and every method of a `pub` type of a module this
  one imports from, to the owner atom — `test@a:twice(X)`, `test@lib:thenReturn(S, V)`. The
  owner atom is `Emitter.atomOf(path)`, i.e. `CrossModule.atomFor` — the whole
  module path joined with `@` (`std@dict:insert/3`), never the basename.
  A local definition of the same name and arity wins (an `@emit`ed body can
  define `find/2` beside an imported `find`). A method is reached in **the
  TYPE's** module, not the file's (policy 3, below): `imported_fns` maps it to
  `crossModule.typeAtom(owner path, type)`, so `stub.thenReturn(v)` is
  `test@lib@@Stub:thenReturn/2` and the owner's type module exports it — unless
  more than one type of the program declares that `name/arity`, in which case no
  owner belongs in the call at all and the value's tag answers
  (`methodOwnerContested`, above). **An import that names a MODULE, not a
  symbol, registers that module's types too.** `import {dict} from "std"` binds
  the module `std/dict`; `Dict` is never named by the consumer, so the cross
  index was never consulted for it and `dict.empty().insert("a", 1)` emitted a
  bare local `insert(D, K, V)` — `function insert/3 undefined`, a program that
  runs on commonJS and does not compile on erlang. `collectNamespaceModuleTypes`
  answers a `use` name that matches no `pub` export but *is* the basename of some
  export's module: every pub record of that module joins `imported_types` and its
  methods join `imported_fns`, so the call becomes `std@dict:insert/3` — the
  namespace the program writes is still the basename, the atom it lowers to is
  the module's (`stdModuleAtom`). It leaves
  `record_fields` alone — a consumer that constructs the record imports it by
  name, which is the branch above. **A typed method call asks
  `methodOwnerModule`, not `imported_types`.** That map is written for an
  imported **record** and by `collectNamespaceModuleTypes`; the `import { … }`
  **enum** arm writes only `enum_variants`/`enum_names`, because a tagged tuple is
  module-independent while the enum's methods are not. So
  `Shape.Square(side: 4).area()` on an imported enum came out as a bare local
  `area({'Square', 4})` while `geometry.erl` exported `area/1` —
  `function area/1 undefined`, the enum half of the two record landings above.
  `methodOwnerModule` is the erlang twin of `beam_asm.zig`'s (`448b935`) and reads
  the same two sources: `imported_types` first, then the cross index for kind
  `record` **or `enum`** with the method in the export's `methods`. A module never
  calls itself remotely, and the guard compares the module PATH (`std/dict`) as
  well as the atom (`dict`) — `module_name` is the path, the atom is its basename,
  so comparing only one made `dict.bp`'s own `merge` emit `dict:insert/3`.
  **A host-backed `declare fn` another
  module imports is answered by an owner-side wrapper.** It emits no function of
  its own — the annotation renders at each call site — so an imported one used
  to stay a bare call and fail as `function <name>/<arity> undefined`. The owner
  now emits `externalWrapperForm`: a function of the declared name and parameters
  whose single-expression body is that same rendering applied to them
  (`hostKey(V) -> iolist_to_binary(io_lib:format("~0tp", [V])).`, a
  `(module, symbol)` external `hostLen(Xs) -> erlang:length(Xs).`) — the erlang
  twin of the commonJS `exports.name = name` re-export. The wrapper is emitted
  and exported for **every** `pub` host-backed `declare fn` (`externalWrapperNeeded`:
  `isPub and isExternal() and body.len == 0`) — decision 64. It used to ask
  `CrossModule.imported` (the BARE-name import route), which is why a *qualified*
  std host call (`import { erlang } from "std"` then `erlang.self()`) resolved,
  type-checked, emitted `'std@erlang':self()` and died `undef`: the import names
  the module, never the symbol, and `out/erl/std@erlang.erl` was two lines of
  code. `pub` is the promise that the name is callable from outside; whether this
  build reaches it does not decide whether the module is complete, so a
  single-module program with a `pub declare fn` now carries the wrapper too
  (`snapshots/codegen/beam/erlang/external_*` moved by exactly that function and its
  export). The export pass and the decl loop share `externalWrapperEmits`, so
  `-export` never names a wrapper that was skipped. A declaration with no `erlang` target (or an
  arity-branched one with no branch for its parameter count) gets no wrapper and
  is not marked `erlang_backed` in the cross index: the consumer keeps its bare
  call, and erlc names the gap.
- **A record emits the `default fn`s it adopts with `implement`.** A behavior's
  bodied instance default is part of the implementing record's surface — commonJS
  puts it on the class (`appendInterfaceDefaults`), and without a counterpart
  erlang emitted no function at all: `bag.isEmpty()` fell through to the untyped
  primitive shim and aborted at run time with
  `{bp_unsupported_method, <<"isEmpty">>, 0, #{items => []}}` while commonJS
  answered. `recordForms` now emits each adopted default (following `extends`)
  in the record's own module beside its methods, and `self_record_type` makes
  `self.size()` inside such a body resolve through the record — a local call
  there, since both are that module's. Which ones are emitted
  is decided once, in `collectAdoptedIfaceDefaults`, after `collectLocalFnArities`:
  **only a default whose `<name>/<arity>` is free in the module and claimed by
  exactly one record.** Inference records no lowering for a call to an adopted
  default (the method belongs to the behavior, not to the record), so the call
  site can only be the bare name; with two implementors one emitted `isEmpty/1`
  would answer both receivers and read fields the other does not have. Such a
  module keeps the run-time abort until a receiver like that is typed (06 N15).
- **A field of function type is applied, not called.** `c.set(9)` on
  `type Cell(value: i32, set: fn(next: i32) -> i32)` reads the field and
  applies it (`(element(3, C))(9)` since half 3); the record emits no `set/2`.
  `fn_typed_fields` (built in `collectTypeShapes`) carries the pairs, and the
  name-only set backs the untyped fallback, where inference records no lowering
  for a call on a field.
- **Test mode loads its siblings.** `escript <module>.erl` compiles and loads
  that module only, so a cross-module call would be `undef` at run time: in test
  mode a module that reaches another one emits `'__bp_load_siblings'/0`, which
  compiles and loads every other `.erl` the runner wrote beside it before the
  tests run. "Reaches another one" is `imported_fns`, `imported_types`,
  **`std_imports`** and a type module of its own — the std route was missing, so
  `import {querystring} from "std"` emitted the remote `std@querystring:parse/1`
  in a module whose runner never loaded `std@querystring` and the test died
  `{error,undef}`.
  A sibling that does **not** compile refuses the run (decision 67):
  `'__bp_dead_module'/2` names the file, prints `compile:file/2`'s own
  diagnostic on `standard_error` (so `--json`'s stdout stays pure JSONL) and
  `halt(1)`s before a single test runs. It used to be skipped in silence on the
  reading that "its own cell reports it", which holds only for a module of the
  project under test — a DEPENDENCY module has no cell, so a dead one was
  indistinguishable from an absent one.
- **Single-assignment versioning:** Erlang variables bind once, so a name already
  bound in the function gets a fresh variable on every later binding — `=`, `+=`
  or a shadowing `val i = i - 1` lowers to `Count@1 = Count + 1` and later reads
  resolve to the current version (`emitBind`/`varRef`, `var_current`/`var_next`
  reset per fn; versions are never reused so separate `case` arms can't
  collide). **Pattern bindings version too** (`patternBindVar`): erlang patterns
  do not shadow, so `case sh { Square(s) -> … }` with `s` already a parameter
  would MATCH against it (`{'Square', S@1}` is the binding), and a name bound by
  one clause of an earlier `case` is "unsafe" in a later one. A version bound
  inside a `case`/`fun` and read after it is left as an Erlang compile error
  (unsafe/unbound) rather than silently wrong.
- **An index expression dispatches on the receiver at run time.** Decision 30's
  `xs[0]`, `d["k"]`, `s[0]` and the slice `xs[0..2]` are **one** AST node — the
  builtin call `[]` over `(receiver, index)` (`ast.index_builtin_name`), the
  slice being the same node with a `range` second argument. `01-checker` does not
  type it yet, so `indexNode` emits `'__bp_index'/2` and `'__bp_slice'/3`, guard
  sequences in the shape `'__bp_len'/2` and the `'__bp_prim_<m>'` shims already
  use: a list and a tuple by position (`undefined` outside the range — what
  `Array.at` answers, and what commonJS's `xs[0]` answers), a string by
  **character**, not by byte (`string:slice/3` is UTF-8 aware), and anything else
  raising `{bp_unsupported_index, Recv, I}`. The range is read as two bounds
  rather than lowered as an expression — the range lowering materialises
  `lists:seq/2`, a whole list of indices, where a slice wants `From` and `To` —
  and an open end (`xs[0..]`) keeps the atom `infinity` that lowering already
  writes. **A `Dict` is deliberately not a clause:** it is the map
  `#{pairs => …}`, so `maps:get/3` would answer `undefined` for a key that is
  present; `d["k"]` has to reach `Dict.at`, which is a lowering only the
  checker can record once it types the receiver.
- **A `case` pattern's variant name is the last segment of its written path.**
  `ast.Pattern` carries the name exactly as written — `Shape.Circle`, `.Some`,
  `Circle` are three spellings of one variant — while the constructor emits the
  bare tag (`Maybe.Some(v: 7)` → `{'Some', 7}`). Matching the written form gave
  `{'.Some', V}`, which matches nothing, and a nullary `.None` rendered as the
  bare token `.None`, which is `syntax error before: '.'`. `variantTag` now
  drops the path (`bareVariantName`), and a `.ident` pattern carrying a `.` is a
  variant, never a binding (`isVariantPath`, the same rule `bindsNames`'
  `isVariant` callback applies). Handed over by `01-checker`, whose `infer.zig`
  resolves the same paths with the same two helpers.
- **A one-parameter arm binds the whole subject as an erlang alias.** `_ { v -> … }`
  and `.Some(v) { w -> … }` (decision 8 §5.3) name the matched value in the arm
  body's single lambda parameter; nothing bound it, so the body read a variable
  the clause never introduced (`variable 'V' is unbound`). `armPatternNode` puts
  the name on the clause pattern — `V = {'Some', R}` — which binds it without
  evaluating the subject twice; on a wildcard pattern the variable simply *is*
  the pattern (`V ->`, not `V = _`). A zero-parameter lambda is the ordinary
  `Pattern { body }` arm and binds nothing. An arm whose value is its final
  expression is already right here: an erlang clause body's last expression is
  its value, so `caseBodyNode` needs nothing (the commonJS/beam/wasm IIFE shape
  is where that half of the handover lands).
- **A tuple pattern is the bare erlang tuple** (`tuplePatternNode`). Decision 8
  §5.1 P6's `#(a, b)` rides `ast.Pattern.variant` with `shape == .tuple` and an
  EMPTY name, so the variant lowering prepended the tag atom of a variant with no
  name — `{'', 0, S}`, which no constructor builds, so every tuple arm died with
  `case_clause`. `shape` is now read: `.tuple` writes the elements and nothing
  else, and `.range` (§5.2's `1...9`) keeps the tagged shape until front 02 step 3
  lowers it.
- **`..` writes the fields it stands for** (`variantPayloadSlots`). §5.1 P7's
  `rest` was never read: `Rect(width: w, ..)` was emitted `{'Rect', W}` against the
  `{'Rect', 5, 9}` a constructor builds, and `Circle(..)` collapsed to the bare
  atom `'Circle'`. An erlang tuple pattern has a fixed arity, so the slots the
  pattern does not name have to be written as `_` — which needs the variant's
  declared arity, kept in `variant_fields` (filled beside `enum_variants`, for
  imported enums too). The same map gives P4 its meaning on erlang: a WRITTEN
  label names a POSITION in the tagged tuple, so `.Rect(height: h, width: w)`
  fills slot 0 with `w` (`slotIndex`). A variant whose declaration this module
  never saw keeps the written arity — there is nothing to pad to.
- **A tuple under `..` is a guard, because erlang has no variable-arity tuple
  pattern.** `#(a, ..)` matches a fresh clause variable (`freshPatternVar`), its
  shape becomes `when is_tuple(T), tuple_size(T) >= N`, and each element the
  pattern named becomes an `element/2` read — a `=:=` test in the guard for a
  literal or a nullary variant, a binding the clause body opens with for a name.
  A COMPOSITE element under `..` (`#(Circle(r), ..)`) becomes a body match, which
  raises `badmatch` instead of falling through to the next arm; nothing in the
  language suite writes one, and it is named here rather than papered over. So is
  the other residual of moving a binding into the body: an arm guard cannot read a
  name bound there (`#(a, ..) when (a > 0)`), because an erlang guard runs before
  the body.
- **A primitive type pattern is a clause guard, not a binder**
  (`primitiveTypeName`, `appendPrimTypeGuards`). Decision 8 §5.2's `case v { i32 { … }
  string { … } }` tests the subject's TYPE; erlang has no pattern that does, and
  emitted as the plain binders `I32` / `String` the first arm matched every
  subject, so the whole union answered through it. The arm keeps its variable and
  the test becomes a guard on it — `I32 when is_integer(I32), (I32 >= …), (I32 =< …)`.
  The spelling table and the range table are deliberate twins of commonJS's
  `primitiveTypeName` / `integerRange` / `isTest`: `f32`/`f64`/`float` are
  `is_number` because commonJS's is `typeof === "number"`, which an integer
  satisfies too. Disagree on the set and the two backends take different arms.
- **What a pattern needs beside its clause head travels in `PatternExtras`** —
  guard tests, and the `element/2` bindings a guard-tested element stands for.
  `armClause` carries one per clause, puts the pattern's guards BEFORE the arm's
  own `when (…)`, and opens the clause body with the bindings. The `val assert`
  path (`assertPatternStmts`) passes null, because its pattern is lowered twice —
  once as a `case` test, once as the enclosing match that binds — and is lowered
  exactly as it was.
- **No loop has a value on erlang** (decision 105). Decision 8 §10's
  `{Group, Value}` pair for a condition loop's `break <value>` and §9's
  `__bp_cond_yield` accumulator in the loop's variable group left with the
  loop's value: a `break <v>` or a `yield` belongs to the nearest generator
  scope (§ Loops above), which collects under its own key, and the variable
  group a loop threads is only the variables its body reassigns.
- **The two embedded preludes are parsed once per process, not once per
  emission** (`prelude_cache`). `collectPrimErlangDispatch` re-lexed and
  re-parsed `primitives.bp`, and `noAutoImportRefs`'s catalog re-parsed
  `std/erlang`, on **every** `emitErlangModule` — both are comptime-embedded
  strings, so it was the same bytes and the same parse each time. Memoising them
  in an arena of their own (over the page allocator, so no caller's allocator and
  no test-allocator leak) takes `collectPrimErlangDispatch` from **4.615 ms to
  2.380 ms** per call (20 calls, Debug) and `botopink build --target erlang` over
  `libs/std`'s 27 modules from **309 ms to 239 ms**. What remains is the
  per-emitter deep copy of the triples it keeps, which is by design. It is safe
  because nothing writes to the cached AST: the nodes borrow only comptime source,
  `collectIfaceErlangDispatch` copies every triple into the emitter's own
  allocator, and the BIF table is read-only. The lock is a spin over
  `std.atomic.Mutex.tryLock` — zig 0.16 has no blocking mutex outside `std.Io`,
  the test runner compiles on several threads, and after the first parse there is
  nothing to contend for. Handed over by `14-comptime-on-beam`.
- **Modules are `erl_ast` forms**: `emitErlangModule` builds every form in one
  arena and renders them with `erl_emitter.writeForms`: `-module`
  (`crossModule.erlAtom(module_path)` — the path joined with `@`),
  `-compile({no_auto_import,…})` (`noAutoImportRefs`), `-export`s, then each
  declaration after a `.blank` — `topValForms` (see **Module-level `val`s** below), `fnForms` (parameters, destructured
  tuples, plain `yield` generators as lists), `recordForms`/`enumForms`/
  `interfaceForms`/`implementForms`/`extendForms` (a `%%` comment plus method
  functions), `use`/`delegate`/external-fn comments, `testFunction` — the comptime
  helper and host forms, the `'_botopink_init'/0` module body (see **Module-level
  `val`s** below), the `'_botopink_main'/0` + `main/1` entrypoint wrapper and,
  in test mode, the runner (`testRunnerForms`: `'__bp_run_one'/1`,
  `'__bp_run_tests'/1`, `main/1`).
- **Bodies are `erl_ast` nodes**: `emitBodyFrom` builds an `Ast.Body` with
  `bodyNode(b, body, start, indent)` and renders it with `erl_emitter.writeBody`.
  Statements (`stmtExpr`: `return`, `bindExpr` for `val`/`=`/`+=` with versioning,
  destructuring, comments) and the body-level lowerings — `propagateTryExpr`,
  `earlyReturnIfExpr`, `foldFusionExpr`, `mutatingExpr` — are nodes.
- **Expressions are `erl_ast` nodes**: `emitExpr` renders `exprNode(b, e)`, which
  models literals, identifiers (variables with versions, top-level `val` calls,
  enum members, tuple index `element/2`, primitive length, `'__bp_len'`, map
  field access and `?.` as an applied inline `fun`), binary/unary operators,
  lambdas, grouped/array (with spread)/tuple/range/record/interface literals,
  jumps, `if`/`try … catch` expressions, `loop` and `case` (`caseNode`: OR patterns
  expand to one clause per alternative; the pattern is lowered BEFORE the guard and
  the body so both read the names it binds (`armGuards`); `patternNode` for
  variables, enum-variant atoms, variant tuples `{'Circle', R}` (or the bare atom
  `'Lt'` for a payload-less variant — exactly what the constructor builds), list/cons
  and multi-subject tuples), binding expressions (`bindingNode`), `use` and comptime
  forms (`comptimeNode`: `assert` as an inline `case` raising
  `erlang:error({bp_assert, Msg, <<"mod.bp:Line">>})` — always fatal, in and out of
  test mode (semantics decision 4); the test runner is what catches it).
  A `try` without `catch` inside a `test` body (`Emitter.in_test_body`, set by
  `testFunction`, cleared in a `fun`) raises the same shape on its Error arm —
  `{error, E} -> erlang:error({bp_assert, E, <<"mod.bp:Line">>})` with the test's
  own line (`test_loc`) — so the runner prints `FAIL <name>  (<E>)  at …`
  (1.0.10-beta decision 74); elsewhere the arm stays `{error, E}`.
  A `val assert P = e [catch h];` whose pattern binds names is lowered at STATEMENT
  position (`assertPatternStmts`): the subject is staged in `BpAssert<line>_<col>`,
  a `case` over it decides the value (the subject when the pattern matched, the
  handler otherwise — the parser's `@panic(…)` for the handler-less form), and an
  outer `P = …` match is what binds, in the enclosing clause. Erlang needs that
  outer match: a name bound by a single `case` clause is "unsafe" after the case.
  The test clause's own binders render as `_` (`Emitter.pattern_discard`), and the
  subject is staged rather than re-emitted in the arm — it used to be evaluated
  twice. A pattern that binds nothing keeps the old single-`case` expression.
  Record/interface literal keys are atoms (quoted when PascalCase or reserved); an
  array spread concatenates (`[1, 2] ++ Rest`, `nameRefNode` for the spread name);
  a leading-dot enum shorthand (`.Black`) is the variant atom.
- **Calls are `erl_ast` nodes** (`callNode`): pipelines apply inside out
  (`pipelineNode`); builtins (`builtinCallNode`) render their `#[@External.Erlang(…)]`
  template, `@block` as an applied `fun`, or the `__bp_*` result/option ops
  (`resultOptionNode`, inline `fun`+`case`); `plainCallNode` does receiver dispatch
  (std module, activated extension, enum constructor tuple, imported/local
  associated fn, mangled interface assoc, module-qualified call, primitive
  (`primMethodNode`) / record instance methods, Array default-fn fallback),
  user templates, externals, record constructor maps and fun-typed locals. Host
  templates (`primOpTemplate`) become `seq` nodes (`templateNode`): the template
  text stays verbatim around the receiver/argument nodes. Every other call is a
  `call` node (`module:name`, a mangled atom — quoted by `writeAtom` when it has
  to be) or an `apply` of a variable (a fn-typed local); a state that cannot
  happen (an unknown `__bp_*` op, an empty OR pattern) is an emit error, never an
  empty `raw`.
- **Mutation through branches and loops** (`mutatingExpr`): a statement-level
  `if` / `for (xs) { x -> … }` / `xs.forEach({ x -> … })` that reassigns variables
  bound before it (looking through nested `if`/`loop`/`forEach`) returns the new
  values instead of binding them inside a `case` arm or `fun`:
  `Acc@1 = case C of true -> …, Acc@2; _ -> Acc end` and
  `Acc@3 = lists:foldl(fun(X, Acc@1) -> …, Acc@2 end, Acc, Xs)`; several
  variables travel as a tuple. Arms are built first (the group's fresh versions
  are known only afterwards). Arms ending in `return`,
  indexed/`await`/yielding loops keep the plain lowering; the older
  `var acc = …; xs.forEach(…)` fold fusion still takes precedence.
  A receiver mutation counts as a reassignment (`receiverMutation`): a
  statement `out.push(x)` on a `var` local (`mutable_locals`; not a parameter
  or a field access) whose receiver is an Array (the inferred
  `.prim = .array` lowering, or any local in a comptime body, where the shim
  answers `push` for lists only) is marked by `collectMutations` and lowered as
  the rebinding `Out@1 = (Out ++ [X])` — in straight-line position too — so the
  group-out expression reads the grown list. The mutation is name-driven
  (`push`); `codegen/beam_asm.zig` has no equivalent yet.
  A local closure whose body reassigns variables of the enclosing function
  (`val emit = { t -> toks = toks.append([t]); }`) cannot rebind what it
  captured, so it is lowered with those variables as an extra last parameter and
  answers their new values (`mutatingClosureExpr`, `mutating_closures`):
  `Emit = fun(T, Toks@1) -> …, Toks@2 end`. A statement-position call rebinds
  them — `Toks@3 = Emit(X, Toks)` — and counts as a mutation for an enclosing
  `if`/`loop`/`forEach` (`closureMutation`). A call whose value is used keeps the
  plain application.
- **Comptime modules:** `emitComptimeModule(alloc, name, program, .{ host_enums,
  host_records, exports, forms, resident, listing, unsupported_method })` lowers an untyped decorator/template body with
  the same emitter — `host_enums` join `enum_names` (`DeclKind.Type` →
  `'Record'`), `host_records` (`HostRecord{name, fields}`) join `record_fields`
  so host record constructors build maps, `exports` (`[]erl_ast.FnRef`) are prepended to `-export`,
  `listing = true` renders only the lowered decls and `forms` (no header,
  exports, `-import` or helpers — the `COMPTIME ERLANG` snapshot section, not a compilable
  module), `forms` (`[]erl_ast.Form`) are rendered after the
  `'__bp_add'/2` / `'__bp_len'/2` helpers; the `untyped` flag routes `+` to
  `'__bp_add'` (binary concat or arithmetic) and `.len`/`.length`/`.size` without an
  instance lowering to `'__bp_len'(X, Field)`.
  `resident = .{ module, forms, refs }` (`../comptime/runtime/prelude.zig`) says
  those host forms live in a module built once at server warmup rather than here:
  they are **not** rendered, `comptime_helper_forms` is not appended either
  (the prelude carries it), and an `-import(<module>, <refs>)` directive after
  `-export` makes the body's bare calls resolve there. The body's own text is
  unchanged by it, which is why the move re-records no snapshot.
  **Primitive methods** in a body (`untypedPrimCallNode`, reached from
  `plainCallNode` after the Array fallbacks): a value-receiver call
  `recv.m(args)` that a host form defines (`name/argc+1` in `forms` **or** in
  `resident.forms` — `q.text()`, `decl.fail(msg)`) stays the bare local call,
  so where a method lowers does not depend on which side of the `-import` its
  host lives; one that some primitive kind
  answers becomes `'__bp_prim_m'(Recv, Args…)`. `primShimForms` emits one shim
  per reached `(m, argc)`, behind the `!listing` gate: a clause per kind in
  `prim_shim_kinds` (`is_list`/`is_binary`/`is_boolean`/`is_integer`/`is_float`)
  whose body is the typed path's own lowering (`primHostMethodNode` — annotation,
  inline cases, Array fallbacks — else `primDefaultShimNode`, which calls the
  instance `default fn` with omitted trailing params filled from their declared
  defaults), then a clause raising `{bp_unsupported_method, <<"m">>, Argc, Recv}`
  (`toString/0` formats through `'__bp_text'` instead). The prelude's bodied
  instance defaults (`String.slice`, `Array.first`) are indexed by
  `collectPreludeInstanceDefaults` for **every** module, off the process-wide
  `prelude_cache` (whose arena outlives the emit, so a reached body may be
  lowered from it); shims and the defaults they reach drain to a fixpoint.
  It was guarded on `comptime_module != null`, and an ordinary module holds
  `primitives.bp`'s `behavior` decls only when its own compile unit carries them
  — which a `libs/std` module compiled as a DEPENDENCY (`from "std"`) does not.
  Five std modules emitted a bare local `slice/3` nothing defines and were
  refused by `erlc`: `path`, `querystring`, `queue`, `snapshots`, `url`
  (`tests/language/run/std_default_fn_in_a_std_module.bp`). So BIF-named
  methods (`length`, `abs`, `floor`) dispatch on the receiver too. A call nothing
  answers is recorded in `unsupported_method` (when set, compilable emit only)
  and the emit fails with `error.UnsupportedComptimeMethod`; the evaluators turn
  it into a located diagnostic. `primErlangDispatchCount` exposes the size of the
  prelude's dispatch table for a regression test.
  **A typed module uses the same shims** where inference recorded no lowering
  for a value-receiver call (a method on `Array.range(0, 5)`'s result, a local
  inside an inlined interface default) and the module defines no
  `callee/argc+1` function of its own (`local_fn_arities`): the shims are
  emitted after the reached instance defaults. A `.len`/`.length`/`.size` read
  with no lowering, on a field no record of the module declares, is
  `'__bp_len'(X, Field)` (`len_helper_form`, emitted on demand). Tests: `tests/comptime_module.zig`.
- **Names**: variables are spelled once, in the module arena, by `varRef` /
  `versionedVar` (`Count`, `Count@2`) over `beam/erl_emitter.zig`'s `varName`;
  `erlangModule` aliases its `moduleName`, and atoms are quoted by the emitter. `erlang.zig` writes no Erlang text itself: the emitter
  builds `erl_ast` nodes and forms and `erl_emitter` renders them (`raw` remains
  only for host template text — see [`beam/AGENTS.md`](beam/AGENTS.md)). Comments are
  `erl_ast.Comment` nodes: source comments keep their level (`//` → `%`, `///` →
  `%%`, `////` → `%%%`, `commentNode`), and the `%%` notes the backend writes
  (declaration headers, `continue`, unsupported field assignment) carry only
  their text.
- **A record is a tagged tuple** (13-module-identity half 3, decision 21's T2):
  a constructor lowers to `{TypeAtom, F1, …, Fn}`, the fields in the DECLARED
  order from `collectTypeShapes`, a field the call does not fill `undefined`, and
  `TypeAtom` is `crossModule.typeAtom` of the module that DECLARES the type
  (`typeOwnerPath` → `recordTagAtom`), so a consumer building an imported record
  writes the owner's atom. Two types with the same fields are therefore two
  terms — `Person(name:"a",age:1) == Vec(name:"a",age:1)` answers `false`, where
  a bare map answered `true`. Field access is `element(N + 1, Recv)` whenever the
  receiver's type can be placed — inference's `InstanceLowering.field_of`, `self`
  inside the type's own module, or the one record declaring the name
  (`recordTypeOfReceiver`) — and `'__bp_field'(Recv, name)` when it cannot, which
  asks the tag's module (`'__bp_get'/2`) at run time and keeps the `maps:get` for
  a map receiver (a `@Behavior(…)` literal, a `Dict`). **"The one record
  declaring the name" is counted over the PROGRAM, not over this file**
  (`uniqueRecordWithField`): `record_fields` holds what the module declares plus
  what it imports BY NAME, so a file that imports one record carrying `rest`
  while the value in hand is a different record carrying `rest` read at the wrong
  offset — a neighbouring field's value when the offset is in range, `{error,
  badarg}` when it is not. Every `pub` record of `CrossModule.owners` votes now
  (`exports` keeps ONE entry per name and could not see the second declaration),
  and one dissenting declaration sends the read to `'__bp_field'/2`. Pinned by
  `tests/language/modules/field_name_collision`, where the guess answered `1` on
  erlang and `2` on commonJS.
  **The TYPE NAME is counted the same way** (`typeNameContested`): inference
  records a receiver's type as a NAME (`InstanceLowering.field_of` / `.type_`)
  and a name the program declares twice places nothing — `parser` and `net` may
  each declare `pub type Outcome` with its own field order and its own
  `describe`. The offset came from whichever declaration the index kept, so
  erlang read `net`'s `.tag` at `parser`'s offset and printed the NEIGHBOURING
  field at exit 0 where commonJS and wasm printed the right one, and the typed
  method call ran `language_tests@parser@@Outcome:describe/1` over a `net` tuple. A
  contested name sends the read to `'__bp_field'/2` and the call to
  `'__bp_method'/3`, which ask the value's own tag. Pinned by
  `tests/language/modules/type_name_collision`. Tuple index `t._N` and the
  bare `t.N` → `element(N+1, T)`. No `-record` declarations are emitted. Optional
  chaining `?.` guards on `undefined` via an immediate fun. A record
  destructuring (`val { x, y } = p`, a `{ name, .. }` parameter, a `try` head) is
  the tuple pattern `{TypeAtom, X, Y, _}` (`destructPatternExprOf`) — the slots
  it does not name are `_`, so `..` adds nothing; the record is the parameter's
  written type, else the one record declaring every named field
  (`recordOfDestruct`), and a program where neither answers keeps the map pattern
  it had. `#(a, b)` stays a tuple pattern. The names bind through
  `patternBindVar` (versioned when already bound). **A comptime module keeps the
  map shape** everywhere (`Emitter.untyped`): its values never leave the build.
- **The host boundary adopts** (`'__bp_adopt'/3`, `adoptHostResult`): a
  `declare fn` bound to a host whose return type NAMES a record
  (`external_record_returns`, filled in `collectExternals`; `recordNameOfReturn`
  looks through `?T`, `T[]` and the builtin `@Result<T, E>` / `@Future<T>` /
  `@Option<T>` / `Array<T>`, and deliberately NOT through a user generic) has its
  answer adopted into decision 21's shape at the three places a host call is
  written — the `pub` wrapper `externalWrapperForm` emits, and the
  `externals` / `user_erlang_templates` branches of `plainCallNode`. A
  `#{field => V}` map becomes `{TypeAtom, F1, …, Fn}` in declared field order (a
  key the map omits is `undefined`), a list adopts element by element, an
  `{ok, V}` adopts inside the ok arm, and a value that already carries its tag
  passes through — so adopting twice is adopting once. **The host is the one
  place the sweep cannot reach**: a consumer library ships an `.erl` sidecar this
  compiler does not own, and every host that wrote a record before half 3 wrote a
  map. Without this, a sidecar answering `#{status => 404, body => <<>>}` for a
  two-field record was read as `element(2, …)` and died with `{error, badarg}`
  and an empty RUN LOG — measured on the largest library outside this repository
  — and `libs/std`'s own `fs.stat` and `http.fetch` still built maps after half 3
  swept `os.userInfo` / `regex.match` / `regex.matchAll` by hand. Pinned by
  `tests/language/run/external_host_record.bp`.
- **`x is T` and a `case` arm naming a type** (decision 8 §4.2 and §3.3):
  `typeTestNode` writes ONE boolean expression that is also a legal erlang
  guard, so the two share a lowering — `is_binary` / `is_boolean` / `is_float`
  / `is_integer` plus a range for a primitive, `is_list` for an array, `true`
  for `unknown`, `V =:= undefined orelse …` for `?T`, and for a named `type`
  what half 3 made testable: a record is `is_tuple(V) andalso tuple_size(V)
  =:= N andalso element(1, V) =:= <its atom>`, an enum every tag it builds
  joined by `orelse` (`enum_variant_names` keeps the DECLARATION order, so one
  program emits one test). `isTestNode` binds a non-variable subject through an
  immediate fun, because the test reads it more than once. A `case` arm naming
  a type appends the same expression to the arm's guards
  (`patternNodeExtra`'s `.ident`): written as the bare binder it was, the first
  arm of a `case` over `Person | Vec` matched every subject.
- **Enums**: `Order.Lt` → the variant atom, `Color.Rgb(r, g, b)` →
  `{VariantAtom, R, G, B}`, and since half 3 the tag is
  `crossModule.variantAtom` — the enum's type atom plus `__v__` plus the variant,
  `test@main@@Shape__v__circle` — rendered against the module that declares the
  ENUM. `variantTag` is the one choke point (constructor, `case` pattern, guard
  and the `.Variant` shorthand all go through it); `variant_enum` gives the enum
  back from a bare `.Circle`, and a variant this module cannot place (a comptime
  host enum) keeps the bare name.
  **Which enum a bare name belongs to is a counted question**
  (`rememberVariantOwner` / `variant_contested`). `variant_enum` was filled with
  `getOrPutValue` — first writer wins, no dissent check, no diagnostic — and its
  own comment mitigated the hazard for a `case` SUBJECT only, so outside a
  `case` a bare `.Circle` took whichever enum the decl walk indexed first. With
  `Shape` and `Hole` both declaring `Circle`, a `Hole` value written `.Circle`
  was tagged `language_tests@main@@Shape__v__circle` and the `case` over it died with
  `case_clause` at run time, from a program that compiled without a word — and
  wasm answered correctly from the same source. A name two enums declare names
  neither now: `enumOfVariantPath` refuses to answer from it (the written
  qualifier and the `case` subject hint still do), and a written path that
  nothing places sets `Emitter.ambiguous_variant`, which `emitErlangModule`
  raises as `error.AmbiguousVariant` and the driver renders through
  `moduleOutput.AmbiguousVariant` — a diagnostic naming both enums and both
  qualified spellings. Decision 67: refuse rather than guess. Pinned by
  `tests/language/run/variant_name_collision.bp` (the qualified spelling, on
  every target) and `run/variant_name_ambiguous.bp` (the refusal, erlang only —
  see its header for why the other three rows are not this cell's shape). `Ok`/`Err` keep the `@Result` runtime tags.
  A bare `.ident` case pattern is the atom when it names a
  known variant (`enum_variants`), else a variable. `enum_variants` also holds
  the variants of every `pub enum` the module imports — by name, or with its
  module (`import {order} from "std"` brings `std/order`'s `Lt`/`Eq`/`Gt`);
  `codegenEmit` indexes them over every module (`EnumExport`), since the
  cross-module index carries an enum's name only. Without it an imported
  variant pattern was a fresh variable that matched anything. Case arms also lower list
  patterns (`[]`/`[X]`/`[First | Rest]`).
- **Calls**: a PascalCase receiver is a module reference (`isModuleRef`) →
  remote `list:map(…)`; a receiver naming a local record calls the local
  associated fn. A no-receiver call to a fn-typed local (`locals`) is a fun
  application `F(args)`.
- **Control flow**: `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`,
  whose subject runs inside `try … catch error:R -> {error, R} end` — `@todo()` /
  `@panic` in a `#[@result]` callee raise, and a `case` alone cannot catch that;
  an `if` whose then-branch returns nests the rest of the body in the false arm
  (`earlyReturnIfExpr`) — the binding form `if (x) { s -> return …; }` too, as
  `case X of undefined -> <rest>; S -> <then> end` (its `case` value used to be
  discarded). A binding-form `if` in any position is exactly those two clauses:
  `undefined` runs the `else` body (it sat behind an unreachable `false` clause)
  and no `_ -> ok` catch-all follows. `&&`/`||` are
  `andalso`/`orelse` — botopink short-circuits, erlang's `and`/`or` do not.
  `if (x)` on a nullable local (`?T`, or a parameter defaulting to `null`) is the
  null test `(X =/= undefined)`, not a boolean test (`condNode`).
- **Loops are statements** (decision 105, front 22), lowered by shape:
  - `for (xs) { x -> … }` → `lists:foreach`; one that reassigns outer variables →
    `lists:foldl` threading them (`mutatingFoldExpr`); one that `break`s or
    `continue`s → a named fun that walks the list (`[X | Rest]`) and recurses
    (`recursiveLoopCall`, the condition loop's machinery), because a fold cannot
    be stopped from inside;
  - an open-ended range `for (x..)` → a named fun that counts up and recurses
    (`fun __Loop(I) -> …, __Loop(I + 1) end`), since `lists:seq/2` has no `infinity`;
  - `while (cond) { … }` / `loop { … }` → a named fun that tests, runs the body
    and recurses (`conditionLoopNode`): `{Out@3, I@3} = (fun __Loop({Out@1, I@1})
    -> case Cond of true -> …, __Loop({Out@2, I@2}); _ -> {Out@1, I@1} end
    end)({Out, I})`, threading the variables the body reassigns (with none it
    answers `ok`; a nested one is `__Loop1`, …; `loop`'s literal `true` is not
    tested). Inside it (`cond_loop`, cleared behind a fun boundary) a bare
    `break` throws `{'__bp_cond_break', Group}` caught around the call, and a
    `continue` throws `{'__bp_cond_continue', Group}` caught around the body, so
    the recursion carries the variables at the jump; each loop's `catch` binds
    its own `__BpGroupN`.
  - **A generator scope** — a `#[@generator]`/`#[@iterator]`/`#[@futureGenerator]`
    fn or method (whose effect `methodEffect` reads off the annotations), or an
    annotated `loop` — is eager: its items are pushed onto a list held in the
    process dictionary under a fresh `make_ref()` (`GenScope`, `genPush`), so a
    `yield` reaches the NEAREST scope from inside an `if`, a `lists:foreach` fun or
    a loop's named fun without threading an accumulator. `break <v>` pushes and
    ends the scope from any depth: `throw({'__bp_gen_end', Key, Group, V})`,
    caught by the scope (`genEndCatch`, the key matched by a guard). A fn answers
    `lists:reverse(erlang:erase(Key))` (`generatorFnBody`); a flat `yield` list
    stays the literal list (`isPlainYieldGenerator`). `#[@generator] loop { … }`
    (`generatorLoopNode`) runs as `loop { … }` does and is the list, the
    variables it reassigns rebound after it — so a captured `var` counter is the
    generator's state; `#[@futureGenerator] loop` is the same list (`await` is
    identity here).
  - `a..b` → `lists:seq(A, B - 1)`, `a...b` → `lists:seq(A, B)`.
  A value-less `break` in a `lists:foreach` is `erlang:throw('__bp_break')` and
  its loop is wrapped in the `try … catch throw:'__bp_break' -> ok end` that ends
  it (`loopBreakCatch`, `hasBareBreak`).
- **Module-level `val`s** (`topValForms`): erlang has no module-level storage, so a
  NAMED `val` is always a 0-arity function and a bare reference to it is the call
  `name()` (`top_vals`); a lambda-valued one applies what it answers,
  `(add())(10, 20)`. A comptime `val` keeps its `%% comptime val x` header and
  carries the expression as its body; a `comptime { … break e; }` block is the
  function body itself — its statements, then the `break` value
  (`comptimeBlockBody`; no `break` → `ok`), and in expression position the same
  body as an applied `fun`. Each val function starts a fresh variable scope.
  Value-less jumps have a value node: `return;`/bare `try`/bare `yield` →
  `undefined`, bare `throw;` → `erlang:throw(undefined)`.
- **The module body** (`'_botopink_init'/0`, `initForms`): a module-level `val` is
  evaluated ONCE, in declaration order, at module load — `docs.md` § `val`, and
  what `const x = f();` does on commonJS. `'_botopink_init'/0` is that body: a
  `_`-named statement inline (it has no reader, and `val _ = …` twice would
  collide on `'_'/0`), a named `val` as the call to its 0-arity reader. It is
  emitted in EVERY mode and called from both entrypoints — `'_botopink_main'/0`
  before `main/0`, and the test runner's `main/1` before the first test
  (`testRunnerForms(…, run_init)`). A rule that held only in test mode is how the
  gap was born: the wrapper was not emitted there at all, so a decorator's
  `@emit`ted `val _scan_X = scan("X");` never ran and a library whose model is
  module-load self-registration was untestable on this backend.
  It is emitted only when some runtime `val`'s initialiser CAN have an effect
  (`initialiserCanHaveEffect`: anything but literals, operators, collection
  literals, field reads and a lambda *value*; an unrecognised node counts as
  effectful). A constant initialiser evaluated per read cannot be told apart
  from one evaluated once, so it needs neither the init nor the cache.
  Such an effectful named `val` caches its value under
  `persistent_term:{<module atom>, <name>}` on first evaluation
  (`cachedValueExpr`) — node-wide, like the module-level binding it stands for,
  not per process. `'_botopink_init'/0` is exported: a module with neither
  `main/0` nor tests has nothing that calls it locally, and erlc would report it
  unused. **Nothing calls it for that module** — cross-module module-load effects
  wait on the build path having a sibling loader at all.
- **Strings**: `+` over a `string` is binary concatenation, flattened into ONE
  construction — `a + b + c` → `<<"a", (b())/binary, C/binary>>` (`stringConcatNode`).
  `isStringExpr` decides: a string literal, a `+` chain with a string operand, a
  parameter declared `string` or a `val` bound to a string (`string_locals`), and a
  module-level `fn`/`val` that answers one (`string_names`, `collectStringNames`).
  Otherwise `+` is arithmetic when either operand is provably a number (`numKind`:
  number literals, parameters declared with a numeric type and `val`s bound to a
  numeric expression — `num_locals`/`num_names` —, primitive length reads, and
  `-`/`*`/`/`/`%` results), and `'__bp_add'(A, B)` when neither operand is proven
  either way (a generic lambda's `{ acc, s -> acc + s }`): two binaries
  concatenate at runtime, anything else adds (`add_helper_form`, emitted on
  demand). `s += x` follows the same three-way rule. `/` is `div` unless an
  operand is provably a float, where it is `/` (`div` raises `badarith` on a
  float). Inside a chain proven to be a string,
  an operand that is not itself provably a string (`"value: " + v`, `v: i32`) is
  the segment `('__bp_text'(V))/binary` — `'__bp_text'/1` answers a binary as
  itself and anything else as its `~p` rendering, emitted once per module when a
  segment reached it (`needs_text_helper`, `text_helper_form`); a bare `V/binary`
  raised `badarg`. Binary-literal segments render as plain strings
  (`beam/erl_emitter.zig`), non-simple ones are parenthesised. **beam must render
  the same bytes** (spec 04-beam B3).
- **`@Result` constructors and patterns** share one tag table (`resultTag`):
  `Ok(v)` → `{ok, V}`, `Err(e)` / `new Error(msg)` → `{error, E}`, and the `Ok`/`Err`
  case arms match those tags. A user enum variant of the same name wins.
- **Static extension dispatch**: `implement`/`extend` methods are local functions
  keeping `self` as the first param (`keep_self`); activated `recv.m(args)`
  (`dispatch_rewrites`) and qualified `Sym.m(obj)` (`ext_names`) lower to
  `m(recv, args)`.
- **Externals**: `#[@External.Erlang("module", "symbol")]` fns emit no decl and
  calls lower to `module:symbol(Args)` (`externals`); `$`-marker / `when(…)`
  symbols render inline (`user_erlang_templates`), and so does a 1-arg form
  without markers (`#[@External.Erlang("list_to_integer(os:getpid())")]`) — a bare
  host expression names no module, and as `module:symbol` it came out
  `:expr()()`; no `erlang` target →
  `MissingExternalTarget`. The `%% external fn <name> …` comment each declaration
  leaves names what backs it — `-> <module>:<symbol>`, `-> erlang template`, or
  `(no erlang target)`; a templated one used to be filed under the last of those.
  A `pub` external another module imports also emits a wrapper (see
  **A host-backed `declare fn` …** under [Cross-module](#erlang) above).
  A template is the string literal's raw LEXEME and goes
  into the `.erl` verbatim, so `dupeTemplate` resolves `\"` to `"` first (an
  `io_lib:format(\"~p\", …)` template used to open an unterminated string).
- **`@print` / `@println` / `@debug`** (cross-backend semantics decisions 1 and 1a)
  lower to `'__bp_print'([A, B, …])`, not to a template: the helper
  (`print_helper_form`, emitted once per module that prints, typed and comptime
  alike, together with `'__bp_show'/2` — `show_helper_form`) prints each argument
  as `'__bp_show'(V, true)` renders it, joined by a space, then `~n`. The text is
  picked at run time: a top-level binary is its text (`hi`, not `<<"hi">>`); a
  nested binary is quoted with the source escapes (`"say \"hi\""`); a list is
  `[E1, E2]` and a tuple `#(E1, E2)` — decision 8 §7's one separator, `", "`.
  **A value that knows its own type prints as the source writes it** (§7, half 3):
  a tagged tuple and a bare atom both reach `'__bp_tagged'/2`, which cuts any
  `__v__` segment off the tag to get the declaring module, and — only when that
  module is loadable and exports `'__bp_format'/1` — renders what it answers
  through `'__bp_render'/1`: `{record, "Point", [{"x", 1}, …]}` →
  `Point(x: 1, y: 2)`, `{variant, "Shape.Dot", []}` → `Shape.Dot`, and
  `{text, …}` → a `Display` implementation's own string, nested containers
  included. Everything else — a Result `{ok, V}`, a host tuple, a plain atom,
  `true`/`false`/`undefined` — keeps the `~p` it had. Numeric formatting stays
  divergent by design: `~p` of `1.0` is `1.0` where commonJS writes `1`.
- **Every `type` has a module, and it answers about its own values** (half 3):
  `recordIdentityForms` / `enumIdentityForms` put `'__bp_format'/1` — and
  `'__bp_get'/2` for a record with fields — into the unit `openTypeUnit` opened,
  so a `type` that declares no method is still a module: the tag has to name
  something loadable for `'__bp_tagged'` to reach the formatter. A type whose
  declaration carries a one-parameter `display` (decision 8 §7's `Display`)
  formats as `{text, display(V)}`.
- **Cross-module**: an imported record joins `record_fields` + `imported_types` +
  `type_owner_path` (`collectImportedTypes`), so construction inlines the owner's
  tuple shape carrying the OWNER's atom (there is no constructor function to call
  remotely) and
  `Response.ok(…)` calls into the owner module atom (`http:ok(…)`); the owner
  exports a `pub` type's associated fns when another module imports it, and a
  `pub implement`/`extend` another module activates (`import {PatoNada*} …`) is
  exported too and reached remotely (`pond:swim(Donald)`). An imported **enum**
  joins `enum_names` only, so its method call resolves through
  `methodOwnerModule`'s link-index arm — see
  [Cross-module calls are remote calls](#erlang).
- **An associated `fn` on an `enum`** (`Shape.unit()` — no `self`) is a plain
  local function, exactly as `enumForms` emits it. `memberCallNode`'s
  qualified-payload-variant branch has to check that the callee is a variant **of
  that enum** (`enum_variant_of`, keyed `<Enum>.<Variant>`, with
  `enum_variants_known` saying whose list the emitter has seen): it used to fire
  on any `EnumName.callee(...)`, so `Shape.unit()` became the tagged tuple
  `{unit}` — erlc clean, and the program died at run time with
  `{case_clause,{unit}}` inside the method that matched on it. A comptime **host**
  enum (`ComptimeModule.host_enums`) has no declaration to check against and is
  deliberately absent from `enum_variants_known`, so it keeps the tuple.
- **Interface associated `default fn`s** (`Array.range`, `Pair.of`):
  `interfaceForms` emits each no-`self` body as a local function
  (`collectInterfaces`); `Interface.method(...)` calls it (reserved words quoted,
  e.g. `'of'`).
- **Interface INSTANCE `default fn`s** (`xs.all(pred)`, `n.clamp(lo, hi)`,
  `b.nor(other)`): a `default fn` with a `self` receiver and a body lands in
  `iface_instance_defaults`; a value-receiver call walks the receiver's `extends`
  chain and lowers to the mangled local `bool_nor(Self, Other)`, noting the form as
  needed. `instanceDefaultForms` drains that set to a fixpoint at the end of the
  module (a default body may call another), so only the defaults a call site
  actually reached are emitted. Inside such a body the receiver's type is `Self`,
  which inference leaves unlowered: `selfPrimKind` re-derives the primitive kind
  from the owning interface (following `-> Self` methods through chained calls) and
  bare callees also resolve against the std prelude template index
  (`preludeHelperNode`, `in_iface_default`).
- **Value-receiver instance methods**: record/enum/struct methods keep `self`
  (`isAssocMethod` gates `keep_self`); `recv.m(args)` lowers via the loc-keyed
  `instance_lowerings` table — `.record` → local (or `owner:`) call, `.prim` →
  `emitPrimMethod` (see [Primitive methods](#primitive-methods)).
  `arr.length`/`s.length` field access also lowers through `instance_lowerings`.
- **A method on a host-supplied `behavior`** (`behaviorMethodNode`): a `behavior`
  no type in the program implements is a runtime boundary — the host builds the
  value — and decision 23 gives the behavior itself no run-time representation,
  so there is no module to call into and inference records no lowering. The value
  IS the dispatch table: a `val` member already reads as `maps:get(tag, G)`, so a
  method reads the same way and applies what it finds,
  `(maps:get(greet, G))(G, <<"ana">>)`. The receiver is passed explicitly — the
  arity the declaration writes (`fn greet(self: Self, who: string)`) and the one
  a botopink `@Greeter(…)` literal already builds on both backends — so a host
  can store a plain `fun mod:f/2` instead of a per-value closure.
  It fires last, only when the receiver is an identifier whose DECLARED type
  (`local_types`, from a parameter annotation or `val x: T = …`) names a
  `behavior`: one this module declares (`local_behaviors`, method present with no
  body and matching arity) or one it imports that no module exports
  (`imported_behaviors` — a behavior never reaches the cross-module index). A
  local function of that name taking the receiver first, or a `method_owners`
  entry, wins. Before this, such a call fell through to a bare local
  `greet(G, …)` that no module defines and erlc refused the whole file.
- **`forEach` accumulator fusion** (`detectFoldFusion`/`emitFoldFusion`):
  `var acc = init;` followed by `recv.forEach({ p -> <mutate acc> })` fuses into
  `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)` (a closure can't
  rebind a captured var). `classifyFoldStmt` recognizes `acc = e`, `acc += e`,
  `acc.push(x)` and a single-assignment `if`/`else`; anything else is not fused.
- **Effects**: non-`#[@result]` effect fns are lowered eagerly (a `@Future<T>`
  is `T`; a body of only `yield`s is a list); `__bp_future_resolved`/`rejected`
  markers become the value / `throw`.
- Structural `==`/`!=` is `=:=`/`=/=`.

### beam_asm

- **One module per `type` — policy 3, the same split `erlang.zig` made.** A
  source file emits its own `.S` plus one per `type` it declares
  (`crossModule.typeAtom` → `test@main@@Contador`, `std@dict@@Dict`), carried
  out as `GenerateResult.units`. This backend mangled **every** method as
  `'<Owner>_<method>'`, not only a colliding one, so a unit both moves its
  functions and renames them: `'Contador_atual'/1` in `main` becomes `atual/1`
  in `test@main@@Contador`, and the call site becomes
  `{call_ext, 1, {extfunc, test@main@@Contador, atual, 1}}`. `methodFnName` is
  the one place the choice is made (bare inside that type's own module, mangled
  everywhere else), `typeModuleAtom` answers the module and `typeMethodModule`
  answers it **only when the type is what declares the method** — an
  `implement` / `extend` block's method on the same type stays the file
  module's mangled local, because an `implement` block emits no module yet
  (its module would be `<package>@<path>@@<val>`, decision 109).
  A `behavior`'s `default fn` likewise keeps `'<Iface>_<method>'` wherever
  `emitNeededDefaults` puts it (decision 23).
- **A unit is a whole module, so it gets a whole module's state**
  (`openTypeUnit` / `closeTypeUnit`): its own writer, its own `fn_labels`, its
  own `{labels, N}` counting from 1, its own `deferred_lambdas`,
  `needed_defaults` and `needed_prim_shims` — drained into it before it closes,
  so a unit carries exactly the helper shims its own bodies reached. The file
  module gets all of it back. A `type` with no bodied method emits no unit.
  Four call sites cross the new boundary — a module-level `val` read, the
  value-receiver call, the bare local call and a `val` holding a fun — and each
  goes through `tryFileCall`: a `call_ext` into the file module plus an entry in
  `file_exports_needed`, which the `{exports, …}` header picks up because it is
  written after pass 2.
- **Comprehensions** (`lowerLoop`, `emitYield`): a `loop` whose body `yield`s
  or `break`s with a value (directly or in an `if`/`case` arm, not in a nested
  loop or lambda) appends each value to a fresh array (`$__arr_push`; a float
  as its f32 bits), and that array is the loop's value — the erlang reading
  of `break <v>`. An `#[@iterator]`/`#[@generator]` fn body that yields runs
  eagerly into one fn-level array it returns (`renderAccumulatingBody`); a
  `@Iterator<T>` is then an array of `T`. A bare `break` branches out of the
  loop, `continue` out of the iteration's `(block $__next …)`. An f32 array
  prints as `[115,287.5,460]` (`$__print_arr_f32`).
- **Coverage**: numerics, locals, calls, booleans, assign, throw, strings,
  `@print`, field access/assign, arrays, tuples, records/structs and behavior
  literals (a `type`'s values are decision 21's tagged tuple
  `{TypeAtom, F1, …}` — `put_tuple2` with the atom of the module that DECLARES
  the type, a field the call does not fill `undefined`; a behavior literal and
  an all-labelled anonymous construct have no declared order and stay
  `put_map_assoc` maps keyed by field name; the anonymous
  `record { … }` literal is gone since front 12 step 4), case (all patterns + guards via
  `emitGuardPre`/`emitGuardPost`; a bare `.ident` arm naming a nullary enum
  variant — local, imported by name, or from a `from "std"` module — is a match
  test against that atom, not a binding — `enum_variants`; `Ok`/`Err` arms test
  the `ok`/`error` tags — `variantTag`),
  `if` as value (`emitValueIf`) and as
  statement (`emitIf` — the false branch falls through, never an early
  `return`; the binding form `if (x) { v -> … }` runs when `x` is not
  `undefined` — `emitIfTest`), try/catch (a real `try`/`try_case` section around
  the subject, then `is_tagged_tuple`), ranges (`lists:seq(A, B - 1)`),
  loops, pipeline, closures, `call_fun`, `@Result`/`@Option` ops
  (`lowerResultOptionOp`: `{ok, V}`/`{error, E}` and bare value / `undefined`,
  mirroring erlang), optional chaining (`lowerIdentAccess`: `is_eq` on
  `undefined`, then the tagged-tuple read below, or `is_map` +
  `get_map_elements` for a receiver whose type this emit cannot place),
  `comptime` nodes
  (`lowerComptime`: a folded expression/block is its value), `await e` (eager:
  the value of `e`).
- **`@print` / `@println` / `@debug`** (`lowerPrint`, `ensurePrintHelper`) lower
  to `'__bp_print'([A, B, …])`, whose four synthesised functions are decision 8
  §7's formatter: `'__bp_print'/1` joins the arguments with a space and ends the
  line, `'__bp_show'/2` renders one value, and `'-bp_show_top-'/1` /
  `'-bp_show_elem-'/1` are the one-argument wrappers `lists:map` needs (they are
  `'__bp_show'(V, true)` and `'__bp_show'(V, false)`). A top-level binary is its
  own text, a nested one `io_lib:write_string(unicode:characters_to_list(V))` —
  `"say \"hi\""`, source escapes and all, in one call instead of a per-character
  walk — a list `[E1, E2]`, a tuple `#(E1, E2)`. **A value that knows its own
  declaration prints as the source writes it** (§7 F2/F3/F4, half 3): a tagged
  tuple and a bare atom both reach `'__bp_tagged'/2`, which cuts any `__v__`
  segment off the tag with `string:split/2` to get the declaring module, loads
  it and asks for `'__bp_format'/1` only when `erlang:function_exported/3` says
  it answers; `'__bp_render'/1` turns the description into text
  (`{record, "Point", [{"x", 1}, …]}` → `Point(x: 1, y: 2)`,
  `{variant, "Shape.Dot", []}` → `Shape.Dot`, `{text, …}` → a `Display`
  implementation's own string) with `'-bp_render_pair-'/1` rendering one
  `label: value` through `'__bp_show'/2`. Everything else is `~p`: an integer, a
  float (which keeps its `.0`), `true`/`false`/`undefined`, a `@Result`
  `{ok, V}`, a host tuple, and any atom no loadable module formats.
  It replaced the per-value format-verb machinery (`'__bp_print_fmt'/1` +
  `'__bp_print_sep'/1`, `~ts` for a binary and `~p` for everything else), which
  printed every compound value as an **Erlang term** — decision 1a never reached
  this backend, so a nested string came out `<<"a">>` and a tuple `{1,<<"a">>}`.
- **A record field is read positionally, never through a call** (half 3):
  `is_tagged_tuple` on the receiver's own atom and arity, then
  `get_tuple_element`. `erlang:element/2` is wrong here even though it is what
  the tuple-index read uses — a `call_ext` frees every x-register, and
  `self.side * self.side` holds the first read in `{x, 1}` across the second
  (`{{x,1},not_live}` out of the loader's consistency check, measured on
  `surface_type_and_behavior_…`). The record is placed by inference's
  `InstanceLowering.field_of`, by `self` inside the type's own module, or by the
  one record declaring the name (`recordTypeOfReceiver`); a destructuring
  (`emitDestructFromX0`) resolves the same way from the parameter's written type
  and binds each slot with `get_tuple_element`. A receiver that resolves to
  nothing keeps the map read.
- **`x is T` and a `case` arm naming a type** (decision 8 §4.2 and §3.3):
  `emitTypeTestBranch` emits tests that FALL THROUGH on a match and jump to a
  fail label otherwise, leaving `{x, 0}` untouched, so `lowerIsCall` (which
  answers `true`/`false`) and the `.ident` case arm share one lowering. A
  record is `is_tagged_tuple` on its own atom and arity; an enum is every tag it
  builds, the unit ones by `is_ne_exact` (which branches when the two ARE
  equal) and the payload ones by `is_tagged_tuple` + a jump. **One divergence
  from the erlang twin, deliberate:** a TUPLE type is tested by `is_tuple` and
  `test_arity` but NOT element by element — reading an element is a call, and a
  call frees the register the remaining tests read; erlang tests the elements
  because a guard may call `element/2`.
- **Every `type`'s module answers about its own values** (`emitTypeIdentity`):
  `'__bp_get'/2` turns a field name into its position for the reads the emitter
  could not place, and `'__bp_format'/1` describes the value for
  `'__bp_render'/1`. A `type` that declares no bodied method is still a module —
  the tag has to name something loadable.
- **The index expression** (`lowerIndexExpr`, `ensureIndexHelper`,
  `ensureSliceHelper`): decision 30 reaches every backend as the builtin call
  `"[]"` over `(receiver, index)` (`ast.zig:1717-1740`), so `xs[0]`, `d["k"]`,
  `s[0]` and the slice `xs[0..2]` are one shape. It used to fall into the
  unrecognised-builtin path — `xs[0]` printed the whole list and `xs[2]` printed
  `ok`. The **slice** is told apart here, from the AST, because lowering a
  `range` as a value would build the `lists:seq/2` list a slice does not need;
  the **receiver** is told apart by its runtime tag inside the helper, since the
  checker's half of decision 30 is `01-checker`'s and beam has no type at the
  call site. `'__bp_index'(Recv, Idx)`: a map → `maps:get(Idx, Recv, undefined)`,
  a binary → `string:slice(Recv, Idx, 1)`, a tuple → `element(Idx + 1, Recv)`,
  anything else → the bounds-checked `'-bp_at-'/2` `xs.at(i)` already uses, so
  an out-of-range index answers `undefined` instead of raising.
  `'__bp_slice'(Recv, Start, End)` is half-open like every other `..`, with
  `End` the atom `infinity` for `xs[0..]` (the convention `lowerRange` uses): a
  binary → `string:slice/2,3`, anything else → `lists:sublist/3`, both of which
  clamp. Measured: `10 · 30 · undefined · e · a · [10,20] · [20,30] · el · llo`.
- **`case` arms** (`armBlock`, `lowerArmBody`, `emitArmTail`, `bindArmParam`):
  decision 8 §5 spells an arm `Pattern { body }`, and the parser reads that
  block as a lambda (`ast.Expr.function`, `.lambda` syntax, at most one
  parameter). Lowering it as an expression built a closure with `make_fun3` and
  dropped it, so every statement in the arm was dead and the arm's value was a
  `#Fun<…>` — a `case` printing from its arms printed nothing, and
  `break r * r` reached `integer_to_binary/1` as a fun (01's defect 2,
  2026-09-18). The block now runs in the enclosing frame: its value is the last
  statement when that is a value expression (`armValueTail`, the set
  `emitLambdaBody` reads), unless a `break` carries one, which wins; a body that
  already `return`s suppresses the dead `{jump, end}`. Its bindings take this
  frame's y-slots (`countLocalsInExpr`'s `.case` arm), which a lambda's did not.
  A one-parameter arm (`_ { n -> … }`) binds `n` to the subject, which
  `lowerCase` parks in one stack slot allocated only when some arm asks for it —
  so a `case` with no binder arm keeps the assembly it had (01's defect 3).
  A pattern keeps the path the author wrote (`Shape.Circle`, `.Circle`), but the
  constructor emits the bare atom `'Circle'`, so `variantTag` and the `.ident`
  arm take the last `.`-separated segment (`bareVariantName`); §5.1 P8 — a name
  carrying a `.` is a variant, never a binding (`isVariantPath`) (01's defect 1).
- **Module shape**: every *named* top-level `val` is a 0-arity function
  (reserved, emitted and — when `pub` — exported whether or not the module has a
  `main/0`), so a read is a local call; a `val` holding a fun is read, parked on
  the stack and applied with `call_fun`. Only `_`-named synthetic statements run
  in order inside `'_botopink_main'/0` before it calls `main/0`. This is the
  shape erlang had before `'_botopink_init'/0` (§ **The module body**): the
  statements run only when a `main/0` exists, a named `val`'s initialiser runs
  once per READ rather than once at load, and neither runs under `botopink test`.
  `tests/language/expected-failures.txt` carries the beam row of
  `run/module_init_order.bp`.
- **Emission**: `beam_asm.zig` writes no target text. It builds typed operands
  (`Op`/`Dst` = `beamEmitter.Operand`/`Dest`) and calls one `beam_emitter.write*`
  function per `.S` line, the module preamble included (`writeModuleForm` /
  `writeExports` / `writeAttributes` / `writeLabels`, sections joined with
  `std.mem.concat`); that file owns atom quoting, operand shape, indentation
  and the trailing `.` (see [`beam/AGENTS.md`](beam/AGENTS.md)). A missing
  instruction is added to the emitter's vocabulary, never printed at the call
  site. The single verbatim passthrough is a `#[@External.Beam]` template body.
- **Identifiers never become atoms**: a name resolves to a stack slot, a
  module-level `val` (local call), an imported `pub val` (`call_ext`), or
  `true`/`false`. Anything else emits `%% unresolved identifier: n` and aborts
  with `erlang:error({unresolved_identifier, n})` at run time — it used to be
  the atom of its own name, so the program printed the word. A call nothing
  defines aborts the same way (`{unresolved_call, F, N}` /
  `{unresolved_method, F, N}`). (Not a compile error: several fixtures whose
  source names undefined identifiers still compile on every backend — the
  checker's gap.)
- **A builtin this backend does not lower aborts the same way**
  (`lowerBuiltinCall`'s tail, `{unsupported_builtin, Name, Argc}`). It used to
  emit **only** a `%%` comment and fall through, so the call left whatever was
  already in `{x, 0}` — the receiver, or the previous statement's `ok` — and the
  program ran to completion with a wrong answer and exit 0. That is how
  `12-language-tests` found the index expression before `lowerIndexExpr` existed,
  and `x is T` still shows it: `@print(v is i32)` on a `v: unknown` printed the
  receiver and then `ok` three times for four tests, where erlang refuses to
  compile (`function is/1 undefined`) and commonJS answers the four booleans
  (only `commonJS.zig` has `buildIsCall`). Decision 8 §4's run-time test is
  unlowered on erlang, beam and wasm alike; the abort makes that visible instead
  of silently wrong. No beam snapshot reached this path, so nothing was
  re-recorded.
- **Closures** (`emitMakeFun`, `closureEnv`): a lambda or loop body's free
  variables — every name it reads that the enclosing frame binds — travel in
  `make_fun3`'s environment (`test_heap` with `{words, NumFree}`) and arrive
  as extra parameters after the fun's own, spilled to stack slots like params.
  `Live` honours the `min_live` floor; lambda bodies reset it to 0. The **eight**
  places that emit a fun value are classified one by one in
  [`beam/AGENTS.md`](beam/AGENTS.md#closure-values-make_fun3--every-build-site-classified):
  every one is a real fun — four feed a `lists:*` higher-order call, four are a
  written lambda or a loop body — and **none** is a block as a value, because
  `@block { … }` runs in the current frame on this backend and the `case`-arm
  block that did build a throwaway closure was removed by `ae813cc8`. The
  13 `make_fun3` hits `grep` finds in `beam_asm.zig` are all comments.
- **Mutation threading** (`lowerMutatingFold`, `emitGroupFun`): a statement
  `for (xs) { x -> … }` or `xs.forEach({ x -> … })` whose body reassigns names of the enclosing frame
  (`=`, `+=`, `out.push(v)`, a mutating closure call, nested
  `if`/`loop`/`forEach`) lowers to `lists:foldl/3` with those names as the
  accumulator (one value, or a tuple), unpacked back into the caller's slots
  (`unpackGroupFromX0`); `break`/`continue` return the group. A statement `out.push(v)` on a local Array stores the grown list back
  into its slot (`receiverMutation`).
- **Mutating closures** (`lowerMutatingClosure`, `mutating_closures`): a local
  `val emit = { w -> out = out + w; }` whose body reassigns names of the
  enclosing frame takes them as one extra argument after its own (the group)
  and answers their new values — a fun cannot write its caller's stack slots.
  A statement-position call (`closureMutation`, `lowerClosureMutationCall`)
  passes the group, applies the fun and stores what it answers back, and counts
  as a mutation for an enclosing `loop`/`forEach`, so the fold threads the
  names on out. Parity with erlang's `mutatingClosureExpr`: a call whose value
  is used keeps the plain application (and raises `badarity`).
- **Loops are statements** (decision 105). `for (xs) { x -> … }` is a
  `lists:foreach` fun (`lowerLoop`); `while (cond) { … }` / `loop { … }` run
  in the enclosing frame (`lowerConditionLoop`): `{label, Top}`, the condition
  as a test jumping to `Exit`, the body, `{jump, {f, Top}}`, `{label, Exit}`.
  The variables it reassigns are this frame's registers, so nothing is
  threaded; `break` jumps to `Exit` and `continue` to `Top` (`cond_loop`,
  matched by the output buffer so a lambda's jumps never take it), and its
  body's slots are counted into the frame (`countLocalsInExpr`). `a...b` is
  `lists:seq(A, B)`, `a..b` `lists:seq(A, B - 1)`.
  **A generator scope** — a `#[@generator]`/`#[@iterator]`/`#[@futureGenerator]`
  fn (`emitGeneratorBody`) or an annotated `loop` (`lowerGeneratorLoop`) — is
  eager: a y-slot accumulator (`GenLoop`, matched by the output buffer like
  `cond_loop`) that each `yield v` conses onto (`genPush`), reversed with
  `lists:reverse/1` at the scope's `Exit`. `break <v>` pushes and jumps to that
  `Exit` from any loop depth; a bare `break` or `return;` with no loop to leave
  jumps there too. A `for` that yields inside a scope is walked in the frame
  (`lowerInFrameFor`: `is_nonempty_list` / `get_list` over a y-slot list), so
  its `yield`s reach the accumulator; `countGenForSlots` adds its slots to the
  frame. A captured `var` is the frame's register, so an annotated loop's
  counter is read after it at its last value. Generator METHODS are not scopes
  yet (a method's effect is not read here — `run/effect_method.bp` is red on
  beam for that reason and others). A body that yields outside any scope is
  `error.ConditionLoopValueUnsupported` (`condLoopYieldsValue`) — the checker
  refuses it first.
- **Calls**: module-qualified `List.map(…)` → `call_ext`/`call_ext_last`
  (trailing lambdas materialized as funs); `from "std"` qualified calls
  (`math.floor(x)`) → `call_ext` via `collectStdImports`; interface
  associated `default fn`s emit as mangled locals `'Interface_method'`
  (`reserveInterfaceMethods`/`emitInterfaceAssoc`); a record-typed receiver
  (`c.atual()`, `.record` instance lowering) calls `'<Type>_<method>'` with the
  receiver first, or applies a fun-typed field (`s.set(v)` — also when inference
  recorded no lowering but a known record declares the field); a record method
  that reads `self` without declaring it takes it as an implicit first
  parameter (`hasImplicitSelf`); a destructuring parameter binds its names in
  the prologue; `Ok(v)`/`Err(e)`/`Error(msg)` build the `@Result` tuple.
- **Host-backed `declare fn`s** (`lowerExternalCall`; never emitted as local
  functions): an `@External.Beam` `.S` body renders at the call site; an
  `@External.Erlang("mod", "sym")` is a `call_ext`; an `@External.Erlang`
  template (`"base64:encode($0)"`, arity branches included) is Erlang source,
  evaluated at run time by the synthesised `'__bp_erl_eval'(Source, Bindings)`
  (`erl_scan` → `erl_parse` → `erl_eval`, markers bound as `__BpSelf`/`__BpAN`)
  — correct but interpreted on every call (≈ 50× a direct call); its cost and
  the open keep-or-compile decision are in [`beam/AGENTS.md`](beam/AGENTS.md).
  A module that only DECLARES a `pub` host-backed fn therefore exports nothing
  and defines nothing, and a qualified call from another module
  (`erlang.self()` → `{call_ext, 0, {extfunc, std@erlang, self, 0}}`) is `undef`
  — decision 64's beam half. `hostDeclareWrapperNeeded(f)` (`isPub and
  isHostDeclare`) is the predicate, **declared and not wired**: the three
  `isHostDeclare` sites (reserve, export, emit) still skip every host declare,
  and the wrapper body (parameters in `x` registers, then `lowerExternalCall`)
  is C-03's open beam bullet.
  No beam or erlang target raises `MissingExternalTarget`. A call to an
  external another module declares lowers the same way.
- **Primitive methods** (`emitPrimMethod`), walking the receiver kind's
  interface chain (`primIfaceChain`: `I32 → Signed → Integer → Number`, …):
  an `@External.Beam` template, then an `@External.Erlang("mod", "sym")` host
  call, then the inline BEAM-irreducible arms (`emitPrimInline`), then an
  `@External.Erlang` template through `'__bp_erl_eval'/2`, then a bodied
  interface `default fn` (`Array.fold`, `Number.clamp`) emitted on demand as
  `'<Iface>_<method>'(Self, …)` (`callIfaceDefault`/`emitNeededDefaults`,
  omitted trailing params filled from their declared defaults). Inside such a
  body inference recorded nothing, so `self`'s kind (`self_prim_kind`) drives
  the lowering of `self.m(…)`/`self.length`.
- **A primitive method on an untyped receiver** (`ensurePrimShim`,
  `emitPrimShimFn`, `primKindDeclares`): a lambda parameter carries no declared
  type, so inference records no instance lowering for it and
  `xs.map({ x -> x.toUpper() })` reached the `{unresolved_method, toUpper, 1}`
  abort at run time while the same call on a named local ran (measured
  2026-09-18 at `bef762b`; it is front 14 step 3's blocker). Such a call now
  goes through `'__bp_prim_<callee>'(Recv, Arg0, …)`, one clause per primitive
  kind that answers it — guarded by that kind's BEAM type test (`is_list`,
  `is_binary`, `is_boolean`, `is_integer`, `is_float`), bodied by
  `emitPrimMethod`'s own lowering, so the typed tables stay the single source of
  truth — then the same `{unresolved_method, …}` abort. The BEAM twin of
  `erlang.zig`'s `primShimForm`. Three gates keep it off every path that was
  already right: inference recorded **nothing** for the receiver (a receiver it
  typed keeps the abort), some primitive interface **declares** the method
  (`prim_beam_templates` / `prim_erlang_dispatch` / `iface_defaults`, all keyed
  `<Iface>.<method>`), and the program's own `behavior` declarations do **not**
  name it (`user_behavior_methods` — `Bounded.clamp` on a record is a user
  type's method that failed to resolve, not `Number.clamp`). A clause is lowered
  into a scratch buffer before the guard that jumps past it can be written —
  `emitPrimMethod` decides whether it can answer while it emits — and dropped
  whole when it cannot, so the rendered function is a list of sections joined
  with `std.mem.concat`, never text written at the call site.
- **Static extension dispatch**: `implement`/`extend` methods are emitted and
  exported as `'<target>_<method>'`; activated `recv.m(args)` and qualified
  `Sym.m(obj)` call it with the receiver prepended (`ext_by_name`,
  `extMangledName`, `lowerExtCall`); a block another module declares (star
  import) is a `call_ext` into its owner (`importedExtension`).
- **Strings**: a `+` chain is concatenation when an operand is provably a
  string (`isStringExpr`: literal, string local/param, string top-level name,
  `fn … -> string`) — its segments become a list, each rendered by
  `'-bp_stringify-'/1` (a binary is itself, an integer `integer_to_binary`,
  anything else its `~p` text), flattened by `iolist_to_binary/1`; a non-string
  operand concatenates as text instead of raising `badarith`. String `+=` too.
- **Numbers** (`numKind`, `NumKind`, `num_locals`/`count_nums`/`num_names`,
  parity with erlang): an operand is provably numeric when it is a number
  literal, a local/param/module name bound or declared numeric, a primitive
  member read (`s.length`), a call to a `fn` declared numeric, or arithmetic
  over them. A `+` with such an operand is the `'+'` gc_bif; a `+` proven
  neither string nor number (`{ x, y -> x + y }`, record fields, destructured
  values — `addIsDynamic`) calls the synthesised `'__bp_add'/2` (two binaries
  → `iolist_to_binary([A, B])`, anything else `'+'`), and so does `x += v` on a
  name and value both unproven. `/` is the `'/'` gc_bif when an operand is
  provably a float, `'div'` otherwise. `exprMayCall` counts the helper call.
- **`erlc +from_asm` invariants**: comparisons use only `is_lt`/`is_ge` (no
  `is_gt`/`is_le` — operands swap, `comparisonTestOp`); `{allocate, N, A}` is
  followed by `{init_yregs, …}` (`emitFrame`); `countLocalsRec` counts every
  stack slot the lowering takes — `val`s, case-arm/destructure/binding-`if`
  bindings, array-literal and concatenation accumulators, the `try` tag, a
  **loop's iterable** (lowered in the enclosing frame whichever loop it is), and
  `stagingSlots` — so the frame is sized correctly. Every decision the count
  mirrors (string-ness via `count_strings`, `exprMayCall`) is taken from the
  same AST and tables in both passes. Under-counting is not a wrong value, it is
  a module the assembler refuses (`{invalid_store, {y, N}}`, "Internal
  consistency check failed"), and `beam_export_audit.sh` cannot find it unless a
  snapshot carries the shape: `for ([1, 2, 3]) { x -> … }`, a loop over a
  literal rather than over a name, had no cell and counted nothing until
  `tests/control_flow.zig`'s "a loop over an array literal" fixture.
- **Registers**: parameters are spilled to `y0..y{arity-1}` by `bindParams` +
  `emitParamSpill` right after `allocate`, so the whole x-file is scratch and a
  `self.field` read cannot overwrite `self`.
- **Operand staging** (`stageOperands`/`stageCall`/`placeStaged`/
  `emitParallelMove`): every site that evaluates several operands — call
  arguments, tuple/record/map construction, `gc_bif` and comparison operands,
  ranges, pipelines, primitive-method layouts, templates — stages them through
  one helper. A simple term (literal, stack slot) is read in place; the last
  non-simple operand stays in `{x, 0}`; the others go to x-registers above
  `scratchBase()` with `raiseLive` — or to stack slots when a later operand may
  call (`exprMayCall`), since a `call`/`call_ext`/`call_fun` frees the whole
  x-file. The final layout is one parallel move. `scripts/beam_export_audit.sh`
  assembles every snapshot module with every function exported, which is what
  surfaces a liveness bug in a function nothing exports.
- **Register-liveness gotchas**: a BEAM `Live` count is a *prefix* — claiming
  `{x, 2}` claims `{x, 0}` and `{x, 1}` too, and an unwritten register in that
  range is `not_live`/`uninitialized_reg`; a construction's `Live` is
  `max(min_live, staged.x_top)`, never padded to 1 when nothing was staged. An
  array literal reserves one cons cell per element *after* evaluating it, with
  the tail accumulator on the stack. A length read uses the `length` gc_bif
  rather than `erlang:length/1`. A field assignment is `maps:update/3` (a call,
  so the receiver needs no static map type).
- **An associated `fn` on a `type`** (`Shape.unit()`, `Response.ok(…)`):
  `typeAssocCall` — a function of the TYPE's own module under policy 3, local
  only while that module is the one being emitted. `record_fields` /
  `enum_names` are what tell a PascalCase receiver that names a type from one
  that names a module. Without that the receiver was lowercased into a module
  atom and the call was `shape:unit()`, `{undef,[{shape,unit,[],[]}…]}` against
  a module nothing emits.
- **Cross-module**: the module atom is the whole module path joined with `@`
  (`crossModule.erlAtom`, read through `Emitter.atomOf`); an imported record
  joins `record_fields` + `imported_types` (`collectRecordShapes`, which holds
  the TYPE's atom under policy 3, not the owner file's), its associated fn
  lowers to `call_ext` into that module (`test@http@@Response:ok(…)`),
  and the owner exports `'Type_method'/arity` when imported elsewhere. A field
  read on a `call_ext` result emits `is_map` before `get_map_elements` (the
  result is typed `any`, which the loader rejects otherwise). An imported
  `pub fn`/`pub val` resolves through `crossOwnerOf` to a remote `call_ext` (a
  `pub val` is a 0-arity function the owner exports, so a bare reference is a
  call). A destructure emits the same `is_map` narrowing, and writes every
  binding slot on *both* arms of the test — the validator reports
  `{unassigned, {y, N}}` after the merge otherwise.
- **Builtins**: `@print`/`@println`/`@debug` (semantics decision 1) build the
  argument list and call the synthesised `'__bp_print'/1`, which formats every
  value on one line, space-separated — a binary through `~ts` (its text),
  anything else through `~p` — the verb picked at run time, byte-identical to
  the erlang backend's helper. Numeric formatting stays `~p` (`1.0`, where
  commonJS prints `1`): an intended divergence. `assert cond[, msg]` (decision
  4) is always fatal: `erlang:error({bp_assert, Msg, <<"<mod>.bp:<line>">>})`
  when the condition is not `true`; `val assert P = e [catch h]` is a two-arm
  case whose bindings stay visible (a y-register each). Its subject is still
  emitted twice — once as the case subject, once as the matched arm's body — so
  an effectful subject runs twice; and a list pattern binds nothing, the same
  gap `case` has on beam. `@todo`/`@panic` → `erlang:error/1`; `__bp_*` ops
  at register level.
- **Effects**: non-`#[@result]` effect fns get an eager body;
  `__bp_future_rejected` → `erlang:throw/1`.
- **Known gaps**: a value-less `if` yields `undefined` (B10, checker's
  question); a comptime value the transform parks in a number literal but is
  not a number (a folded array) aborts with `{unlowered_comptime_value, Text}`
  (the transform's gap); `%% prim method not lowered on beam (…)` comments
  mark the remaining arity mismatches.

### wat

**The backend builds a model; `wat/wat_emitter.zig` renders it.** Nothing in
`wat.zig` writes `.wat` text — lowering appends `wat_ast.Line`s to the open
sequence (`emit`/`emitC`/`emitAt`/`note`), collects top-level forms with `item`,
and `emitWat` assembles the module and calls `renderModule`. A nested body (an
`if` arm, a `loop` body) is lowered into a `Capture` and `seal`ed with the stack
effect its context expects. See [`wat/AGENTS.md`](wat/AGENTS.md) for the model.

**The emitted module must load.** Every snapshot under
`snapshots/codegen/beam/wasm/` is expected to pass `wasmtime compile`; a shape the
backend cannot lower yet emits an honest `;; …` placeholder rather than
something that fails validation. The four rules that keep it that way — the
first three are now enforced by the model, not by discipline:

1. **Locals are hoisted.** `declareLocal` is the *only* way a `(local …)`
   reaches the output: it queues into `pending_locals`, `renderBody` lowers the
   body into a detached sequence, and `localLines` hands the declarations to the
   function node — the model has no local-declaration instruction, so there is
   nowhere else to put one. Scratch names (`$__mem{n}`, `$_try{n}`) are
   pre-counted by `countMems` / `countTrys`, which must walk **every**
   sub-expression — a method call's `receiver` included, or `[1,2].at(0)` sets
   an undeclared `$__mem0`. `nextMem` and the try lowerings also declare the
   slot they take (idempotent), so a construct the counters do not walk — an
   inlined lambda body — still gets one.
2. **One value discipline** (`Tail` = `value` | `none` | `terminated`).
   `exprTail` is the single classifier; every arm of `lowerExpr` must agree with
   it. `emitStmt` normalises to what the context asked for (pushes a zero, or
   `drop`s). `ifIsStatementForm` is shared by `lowerIfExpr`, `exprTail` and
   `fnHasResult` so a two-void-arm `if` is emitted without `(result …)`, is not
   `drop`ped, and does not give its function a `(result …)` it never fills. The
   answer is then *carried*: `stackOf` tags each sequence, and
   `wat_ast.Builder.func` refuses a body that does not match the signature.
3. **No reference to a symbol the module does not define.** `registerSymbols`
   records every fn signature and global up front; a callee nothing resolves
   traps as `unreachable ;; unresolved call: f/N` (never a folded value — a
   program that needs it fails loudly), and a bodyless `declare fn` is skipped:
   a call to one that carries `#[@External.<Target>(…)]` for another target is
   refused at compile time (decision 67, above), and one that carries no
   external annotation at all traps. A single dangling `call`/`global.get` rejects the whole module, so
   `renderModule` validates every `call` against the module's functions and
   imports before writing anything. The runtime helpers go
   further: `Builder.helper` is the only way to name one and marks it for
   emission in the same act.
4. **Types are recovered and coerced, never assumed.** `wasmTypeOf` recovers a
   value type from the literal spelling, a local/param/global's declared type or
   a callee's registered result; `lowerCoerced` + `emitConvert` meet the type
   the context wants. `return`, the implicit fn tail and every `case` arm coerce
   to `cur_result`; `storeSlotExpr` picks `f32.store` vs `i32.store`.

- **Coverage**: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`,
  `assert`, `val assert` (`lowerAssertPattern`: the subject is staged in
  `$__assert_<n>`, `emitPatternTest` decides, a mismatch runs the handler — the
  parser's `@panic(…)` traps, a written `catch <value>` replaces the staged
  subject — and `bindPattern` binds the names in the function's locals. A
  pattern `emitPatternTest` has no real test for, a record constructor say,
  is lowered as a plain binding rather than as "never matches":
  `patternTestIsReal`. A list pattern binds nothing, the same gap its `case`
  arms have), globals, case, pipeline (`a |> f` → `call $f`), range loops
  (`lowerRangeLoop`; `a...b` tests `gt_s` where `a..b` tests `ge_s`), condition
  loops (`lowerConditionLoop`: `i32.eqz` + `br_if $__break` at the top of each
  iteration) and array loops (`lowerCollectionLoop` — a float array's element
  is an `f32` slot, bound to an `f32` local), every one a statement (decision
  105); the annotated `loop` (`lowerGeneratorLoop`, below),
  primitive methods, function values, `@print` via WASI `fd_write`,
  `_botopink_main`/`_start`.
- **Known gaps** (loadable, but not yet right):
  - `loop` over anything that is not a range or a known array emits
    `i32.const 0 ;; loop over unknown iterable` — `isArrayExpr` accepts an array
    literal, a name bound to an array, an `Array<T>`/`T[]`/`@Iterator<T>`
    parameter or fn result, an array-returning primitive method and an
    annotated `loop`, and nothing else, because walking the layout of a non-array
    would read its first word as an element count and trap;
  - an array of tuples/records prints as the element addresses (no printer);
  - every function value's parameters and result are `i32`;
  - a lifted lambda's captures are threaded only through calls on the closure
    local it was bound to (`val f = { … }; f(x)`): a closure passed as an
    argument, stored in a field or returned still works on the snapshot it was
    made with, and a capture it only reads is that snapshot too;
  - **shapes with no lowering anywhere** — `List.map(xs, f)` and
    `List.map(xs) { … }` (`call_qualified_module_call_resolves_arity`,
    `call_qualified_module_call_with_trailing_lambda_arity`): `List` is
    declared nowhere, `libs/std` included. commonJS emits `List.map(…)` against
    an unbound `List`, erlang `list:map/2` and beam `call_ext list:map/2` (no
    such module; `lists` is not what the source names), wasm traps
    `unreachable ;; unresolved call: map/N`. The fixtures pin the call's arity
    and have no `main`; the shape needs a `List` to exist before any backend
    can lower it;
  - an `f64` aggregate field round-trips at `f32` precision (4-byte slots), and
    is read back as a raw `i32.load` unless the field's declared type is known.
- **Non-constant top-level `val`s** (`emitGlobalVal` → `deferred_globals`): a
  wasm `(global …)` accepts only a constant initialiser, so an array/tuple/call
  initialiser declares a zeroed mutable global and is evaluated in
  `$__init_globals`, which the module's `(start …)` runs ahead of `_start`.
  These used to stay at the `(i32.const 0)` placeholder, so every read saw `0`.
- **Module-level `var`** (front 17 step 2, decision 38): `emitGlobalVal` sets
  `.mutable` from `ValDecl.mutable` on the folded-numeric and `numberLit` paths
  too (the other three already declared a mutable global), so `global.set $hits`
  validates; a `val` keeps its immutable global. Verified by running: the
  front's problem program prints `2` under wasmtime.
- **`val x = comptime { … break v; }`** (`folded_globals`): the comptime pass
  folds the block into `comptime_vals["ct_<N>"]`, N counting the module's
  `val`s and `fn`s in order (commonJS reads it the same way). A folded numeral
  is a constant global — `f64` when it has a fraction or exponent — and a
  folded `"…"` string an interned one; the block itself never reaches
  `$__init_globals`, which used to leave the global at `0`.
- **Folded comptime values are not always numerals**: the comptime pass parks a
  rendered value (an array, a record) in a `numberLit` node, so
  `val C = comptime ["a"]` reached codegen as the text `["a"]` and emitted
  `f32.const ["a"]` — a parse error. `isNumericLiteral` guards every
  `{t}.const {n}` site; a non-numeric one is interned as a string constant.
- **Booleans**: `true`/`false` are identifiers lowered to `i32.const 1`/`0`
  (never `global.get $true`, which references an undefined global).
- **Parameters always have a name**: `paramSymbol` synthesizes `$__p{i}` for a
  destructuring parameter the source did not name — `(param $ i32)` is a WAT
  parse error, and `wat_ast.Builder.param` refuses to build one.
- **Entrypoint** (`emitEntrypointWrapper`): calls `$main` and `drop`s its
  result when `main` returns a value (`main_returns_value`).
- **The primitive methods wasm does not lower trap, they never answer.**
  `primCallRes` is the table; a method missing from it emits
  `unreachable ;; prim method not lowered on wasm: <kind>.<name>/<argc>`.
  Audited against `libs/std/src/primitives.bp` on 2026-09-18 — not lowered, each
  verified to trap under wasmtime: **string** `charCodeAt`, `chars`,
  `lastIndexOf`, `lines`, `padEnd`, `padStart`, `replace`, `replaceAll`,
  `words`; **array** `chunked`, `find`, `pop`, `range`, `sliding`, `unique`;
  **float** `toString`; **Pair** `first`, `of`, `second`, `swap`.
  `toUpperCase` / `toLowerCase` — the host spellings `primitives.bp` gives
  `toUpper` / `toLower` through `#[@External.Node(…)]`, which source writes and
  commonJS answers — used to be in that list and are now lowered to
  `$__str_case` like their botopink names.
  **string `at`** left it on 2026-09-21: it is the reader decision 63's
  amendment gave every indexable type (`charAt` before it), it is what `s[i]`
  rewrites to, and commonJS, erlang and beam all answered it while `s.at(1)`
  trapped here. It lowers to `$__str_at` — `$__str_slice(s, i, i + 1)` behind an
  `i32.ge_u` bounds test — and answers a `?string` whose absence is the pointer
  `0`, which `optInfoOf` routes to `$__print_opt_str`; printed as a plain
  string it used to read a length out of the WASI iovec at address 0 and
  answer garbage with exit 0 — since `00 · 05-wasm` `$__print_str_raw` traps
  on any pointer below the data floor (256) instead, see
  [`wat/AGENTS.md`](wat/AGENTS.md). `tests/language/run/string_at.bp` pins it
  on all four targets.
- **A `?T` box holding an `f32`** (`fs.at(0)` on a float array) prints through
  `$__print_opt_f32`, its own helper group. Read as a boxed `i32` it printed the
  float's **bits** — `1069547520` for `1.5`, exit 0, no diagnostic.
- **`==` between tuples compares elements** (decision 8 §6 T6; T5 — labels take
  no part): `tupleEqShape` + `emitTupleEq`. Both sides are pointers into the
  bump heap, so `i32.eq` on them answered `false` for `#(1, "a") == #(1, "a")`.
  The print shape is static (`(is)`), so the comparison is emitted element by
  element — `i`/`b` as an `i32`, `f` as the `f32` the slot holds, `s` through
  `$__str_eq` (the words are addresses), `(` by recursing through the pointer.
  A shape holding an array (`[X`) is **not** compared this way and keeps the
  pointer comparison: `[X` has no closing code and an array's length is only
  known at run time.
- **A tuple element is printed by its own shape** (`tupleElemShapeOf` +
  `shapeSpan`): `@print(t.1)` answered `256` and answers `x`, `@print(row.name)`
  answered `256` and answers `SP`. `printShapeOf` already built the tuple's whole
  shape (`((ii)s)`, `(si)`) but its contract is to answer containers, and
  `isStringExpr` — what `@print` asks about a **single** value — could not ask it;
  `tupleElemShapeOf` slices element `N` out and both readers use it, so string
  `+`, string `==` and `str_locals` follow. A label is not a separate case: the
  checker resolves `row.name` to `row._0` (§6 T4) before this backend sees it, so
  the member is always `_N` or a bare `N`. An element that is itself a container
  prints as one too (`t.0` → `#(1, 2)`), which is **ahead of commonJS**: it prints
  `[1, 2]` there, dropping the `#` marker when no shape hint is passed — `04-js`'s
  row, so the fixture for this is wasm-only.
- **A generator scope collects into an array** (decision 105): a generator
  fn's body (`renderAccumulatingBody`, `$__yield_fn`) or an annotated `loop`
  (`lowerGeneratorLoop`, `$__yield{n}` inside `(block $__gen{n} …)`) — each
  `yield v` appends (`emitYield`), and `break <v>` appends and ends the scope
  from any loop depth (`emitGenBreak`: `br $__gen{n}`, or the fn's
  `return` of what it collected). The loop is the array. Every other loop is a
  statement: decision 8 §10's search (`$__found{n}`), decision 52's
  `$__got{n}` flag and `$__print_loop_i32` / `$__print_null`, and the
  valueless-loop `null` all left with the loop's value.
- **§7 F1 — a separator inside an array or a tuple is `, `, not `,`**
  (`wat_prelude.putSep`): `@print([1, 2])` writes `[1, 2]` and `@print(#(1, "a"))`
  writes `#(1, "a")`, where decision 1a's text had no space at all
  (`[1,2]`, `#(1,"a")`). Four sites write a separator and all four now call it:
  `$__print_arr_i32_raw`, `$__print_arr_f32_raw` and `$__print_shaped_raw`'s
  array (`[X`) and tuple (`(XY…)`) arms. The two bytes go through the scratch
  cells at **8 and 9** in one `fd_write`, so the separator still costs one call.
  commonJS and beam already wrote the space; **erlang does not** — that is
  `02-erlang` step 1 F1, and until it lands `snapshots/codegen/beam/erlang/` is the
  only directory whose logs still read `[1,2]`.
- **§7 F5 — an `f64` always carries its decimal part** (`$__print_f64_raw`):
  `@print(5.0)` writes `5.0`, `9.0` and `[115.0, 287.5, 460.0]`, where the
  printer used to drop a whole number's fraction entirely (`5`, `9`,
  `[115,287.5,460]`). The fraction digits are already written; only the "was any
  of them non-zero" test changes. **`$__f64_to_str` is not this path**: it is
  what a float concatenated into a string (`"x" + 5.0`, `5.0.toString()`) takes,
  and commonJS answers `x5` there, so it still drops the fraction.
- **Decision 30's index expression** (`lowerIndex`): the parser lands `xs[0]`
  as the reserved builtin call `ast.index_builtin_name` (`"[]"`) over
  `(receiver, index)`, and `xs[0..2]` is the same node with a `range` where the
  index goes. One node, four readings, told apart by the receiver and by whether
  the index is a range: `xs[i]` → `$__arr_at` (the element, `0` out of range),
  `xs[a..b]` → `$__arr_slice`, `s[i]` → `$__str_slice(s, i, i+1)` (the one-byte
  string), `s[a..b]` → `$__str_slice`. A float array's slots are `f32`, so the
  four bytes `$__arr_at` answers are reinterpreted rather than printed as an
  integer. `indexArgs` is what `isStringExpr` / `isArrayExpr` / `elemKindOf` /
  `wasmTypeOf` ask, so `val sub = xs[1..]` is an array local and `s[1]` a string
  one. **`xs[i]` answers `T`, not `?T`** — which of the two decision 30 means is
  `01-checker`'s to settle (`ast.zig:1734`); a receiver that is neither an array
  nor a string (a `Dict`) traps rather than answering a number nothing put there.
  Before the lowering the form left **nothing on the stack** and `wasmtime`
  refused the whole module. Two shapes the first lowering still got wrong, both
  with exit 0: **`rows[1][0]`**, where the element is itself an array —
  `indexElemShape` strips one `[` off the receiver's print shape (`[[i` → `[i`,
  `[(is)` → `(is)`), which is what tells `rows[1]` from `xs[1]`; without it the
  inner index reached `unreachable` — and **`xs[0..2].length`**, where inference
  records the `.prim` instance lowering only for a receiver it typed, so the
  index node reached the field-access stub and answered `i32.const 0`. When the
  `.prim` note is absent, `lowerIdentAccess` asks this backend's own
  `isArrayExpr` / `isStringExpr`; neither is ever true of a record, so a field
  actually named `length` still resolves.
- **A pattern's variant name arrives with the path it was written with**
  (decision 8 §5.1 P8): `Shape.Circle`, `.Circle`. The constructor stores the
  bare `Circle`, so `findVariant` compares against `bareVariantName` — the last
  `.`-separated segment — and looks the enum a path names up first.
  `isVariantPath` is what tells a variant from a binding: a `.ident` carrying a
  `.` is never bound, and a path no enum here declares is an arm that can never
  match (`zero ;; unknown variant pattern`), not a catch-all. Before this, a
  dotted arm never matched and fell into the next one.
- **An arm body is inlined, never lifted** (`lowerArmBody`, §5.1 P1/P3). An arm
  written `Pattern { … }` — and the pre-decision-8 `-> { … }` block arm —
  arrives as an `ast.Expr.function` with `syntax == .lambda`: a leading
  `name ->` binds the whole matched value and the last expression is the arm's
  value. Lowering it as a *value* put the body in the function table and left
  the arm answering a closure-cell address, so the body never ran
  (`case_or_patterns_with_block_arm_body` recorded a `$__lambda0` and a 4-byte
  cell where `"odd"` belonged). A lambda of more than one parameter is still a
  function value and keeps the old path.
- **A `case` guard is emitted** (`emitGuardChain`, §5.3): after the pattern's
  names are bound, `(if <guard> (then <body>) (else <rest of the chain>))`. A
  guard makes even `_` refutable. This backend used to drop guards entirely, so
  a guarded arm matched unconditionally — `classify` answered `"positive"` for
  every `n`.
- **`case` patterns** (`emitPatternTest` + `bindPattern`): numbers, strings
  (`$__str_eq`), `or`, and variants. A variant of an all-unit enum is its tag;
  a variant of an enum with any payload is a `[tag, …fields]` pointer — its
  unit variants are allocated as a one-slot `[tag]` cell (`emitUnitVariant`),
  so the tag is always the first word. `Ok(v)`/`Err(e)` read a `@Result`'s
  `[tag, payload]`. A bare name that is a variant of some enum (`Lt ->`) is a
  tag test, not a binding. Payload bindings take the variant field's type (a
  float field is an `f32` slot). List and multi-subject patterns have no test
  yet and run their arm.
- **A pattern binding that shadows a local of another type** (`Square(s)`
  inside `fn area(s: Shape)`) is stored in a fresh `s__<n>` local; the arm's
  uses resolve to it (`resolveName`) until the arm ends.
- **String `+` with a non-string operand** renders the operand first
  (`lowerConcatOperand`): an integer through `$__i32_to_str`, a float through
  `$__f64_to_str` (the same digits `$__print_f64` writes), a bool as
  `true`/`false` — the rule erlang's E2 fix follows (`integer_to_binary/1`).
- **`assert cond[, msg]` is always fatal** (decision 4 of the 1.0.2-beta
  semantics decisions): a false condition writes
  `<module>.bp:<line>: assertion failed[: <msg>]` to stderr
  (`$__assert_fail` over `$__write_err`, fd 2) and traps. The harness records
  both as the `RUNTIME TRAP (wasmtime):` block. It used to lower to nothing.
- **`throw` inside a fn returning `@Result`** returns an Error Result
  (`lowerThrow`) — the transform rewrites the common forms into
  `return __bp_error(…)`, but a `throw` inside a `case` arm reaches the
  backend as a `throw`. Anywhere else a `throw` traps.
- **`Ok(v)` / `Err(e)` / `new Error(msg)` the transform left as calls** build
  the same `[tag, payload]` pair as `__bp_ok` / `__bp_error` (`lowerPlainCall`),
  the lowering beam and erlang give them (`{error, Msg}`); a user enum variant
  of the same name wins. `throw new Error("…")` in a fn that does not return a
  `@Result` used to trap on `unresolved call: Error/1` before reaching its own
  trap.
- **Aggregates in linear memory**: tuples/arrays/records/enum payloads are
  contiguous 4-byte slots in the bump heap (`$__heap_ptr`); a type registry from
  `record`/`enum` decls distinguishes construction from calls; construction
  stashes the base in a `$__mem{n}` local; enum payloads are `[tag, …fields]`.
- **Strings** are length-prefixed: the value is a pointer to a 4-byte length
  word followed by the bytes (`internString`). `+` → `$__str_concat`, `==`/`!=`
  → `$__str_eq`, slicing → `$__str_slice`. These fire on *any* string-typed
  operand (`isStringExpr`: literals, `string` params/locals/globals, fns
  declared `-> string`), not only on literal-vs-literal — when they fired only
  for literals, `s == "yes"` compared **pointers** (passing by accident because
  identical literals share an address) and `a + b` added them.
- **Shapes are recovered where the value is made, and carried by name**: a
  string/bool/record/array shape comes from a literal, a parameter's declared
  type, a fn's declared return type (a type guard `-> x is T` is a bool; a
  `-> @Result<string, …>` makes `try f()` / `f() catch …` a string), a fn body
  that returns a string when the specialisation pass cleared its return type,
  a tuple literal's element (for
  `val #(a, b) = #(…)`), an array's element shape (for a loop parameter) and a
  top-level `val`'s initialiser (`str_globals`, `global_rec_types`). A value
  whose shape nothing recovers still prints through `$__print_i32`.
- **`@print` of an array of strings, a tuple or an array of tuples** (semantics
  decision 1a) goes through `$__print_shaped_raw(v, shape, 1)`: the emitter
  interns a shape string (`i` i32, `f` f32 slot, `b` bool, `s` string, `[X` array
  of `X`, `(XY…)` tuple) recovered by `printShapeOf` from a tuple / array
  literal, a local bound to one (`print_shape_locals`), `zip`, and a declared type
  that spells a tuple, labeled or not (`typeRefShape` over a parameter, a fn
  result or an annotation; `ast.TypeRef.tupleElems`); nested strings print quoted with the source escapes
  (`$__print_quoted_raw`). A flat `i32`/`f32` array keeps `$__print_arr_*`.
- **String literals are unescaped at interning** (`literalBytes`): the lexer keeps
  `\"`, `\\`, `\n`, `\r`, `\t`, `\0`, `\$`, `\u{…}` verbatim, and the data segment
  holds the bytes they stand for, so `@print("q\"t")` writes `q"t` like commonJS
  and erlang (it wrote `q\"t` before).
- **`@print` picks a helper by operand type**: `$__print_str` writes the bytes
  of a length-prefixed string, `$__print_bool` writes `true`/`false`,
  `$__print_f64` writes an integer part plus up to 6 trimmed fraction digits,
  and `$__print_i32` formats digits into scratch memory. Each group is emitted
  exactly when something asked for it — `Builder.helper` hands out the symbol
  and sets the flag together. The helpers themselves are nodes in
  `wat/wat_prelude.zig`; the scratch layout they assume is documented there.
- **Primitive instance methods** (`lowerPrimMethod`): `emitWat` is handed
  `instance_lowerings`, the receiver family inference recorded per call loc
  (`array`/`string`/`bool`/`int`/`float`). `primCallRes` is the one table of
  what wasm lowers and what each leaves on the stack — `exprTail`,
  `wasmTypeOf`, `isStringExpr`, `isBoolExpr` and `isArrayExpr` all read it. A
  method lowers to an opcode (`f64.floor`, `i32.rem_s`), a runtime helper
  (`$__str_case`, `$__arr_join_i32`, …), or — for `map`/`filter`/`forEach`/
  `fold`/`all`/`any`/`count`/`findIndex` over a literal lambda — a counted walk
  of the array blob with the lambda's parameters bound to locals and its body
  inlined (`lowerArrayHof`). `xs.push(v)` rebinds the receiver (a name or a
  record field) to a grown copy. A method the table does not list traps:
  `unreachable ;; prim method not lowered on wasm: <kind>.<name>/<n>`.
  Element shape (`ElemKind`: `i32`/`f32`/`str`) is recovered from array
  literals, `T[]`/`Array<T>` annotations and the op that produced the array;
  `join`/`indexOf`/`contains` and a lambda's element parameter use it. An
  `i32` array prints as `[1,2,3]` (`$__print_arr_i32`).
- **Function values** (`lowerLambdaValue`, `lowerValueCall`): a lambda used as
  a value is lifted into `$__lambda{n}(env, a0, …) -> i32` and listed in the
  module's `(table funcref (elem …))`; the value is a pointer to an environment
  cell — `[table index][captured local]…`, the captures copied at creation.
  `f(a)` on a local/global/record field holding one is `call_indirect`
  with the cell as the first argument. **A capture the lambda assigns is
  threaded** (`Captured.threaded`, `bodyAssigns`): inside the lifted lambda
  every `=`/`+=` to it is written back to its environment slot
  (`writeBackCapture`, `env_slots`), and a call through the local the closure
  was bound to (`closure_locals`) copies the caller's local into the slot
  before the call and back out after (`syncCaptures`) — a markup template's
  `val emit = { w -> out = out + w; }` called directly and from a loop. The
  **parameters' shapes** come from those same calls: an argument proven a
  string makes the parameter a string inside the lifted body
  (`Lifted.param_str`), and `isStringExpr` judges a call through the closure
  local by the body with each parameter taking its argument's shape
  (`closureCallIsString`), so `val cat = { x, y -> x + y }; cat("ab", "cd")`
  concatenates and prints a string (it used to add the two pointers). A top-level fn used as a value is a
  closure over a trampoline `$__fnref_<fn>`. Every parameter and the result are
  `i32`. A lambda passed straight to an array method or a `@Result`/`@Option`
  op is inlined instead, which is what lets `forEach` assign outer locals.
- **Interface associated `default fn`s** (`Pair.of`, `Function.compose`) are
  registered as `$<Iface>_<name>` and emitted only when a call reaches them
  (`emitPendingFns`, after the declarations and `$__init_globals`). A record's
  own fn called on the type (`Response.ok(…)`) calls `$<Record>_<fn>`.
- **Host-backed `declare fn`** (`#[@External.<Target>(…)]`, no body) — *the
  decision, reversed 2026-09-21 under decision 67*: wasm has no host to bind one
  to and no WASI call stands in for an arbitrary host symbol, so a call to one
  that names another target and no `wasm` one is a **compile-time refusal**,
  located at the call site: `` `<name>` has no `#[@External.<Target>(…)]` for the
  wasm backend `` — the same `moduleOutput.MissingExternal` diagnostic commonJS,
  erlang and beam raise (06 C13), threaded out of `emitWat` by its `missing`
  slot and collected by `codegenEmit`, so only that module fails. `registerSymbols`
  fills `external_missing` (the `isExternal()` subset of `host_fns`) and
  `lowerPlainCall` reads it. It used to be a **documented trap** —
  `unreachable ;; host-backed declare fn <name>/<n>: no wasm host` — on the
  argument that "the other three targets compile the same module, and a program
  that never reaches the call still runs"; the first half is false (commonJS
  refuses it, and erlang/beam only compile it because they *have* the host) and
  the second made wasm the only backend that compiled such a program and then
  died at run time with exit 134. A bodyless `declare fn` with **no**
  `#[@External.<Target>(…)]` at all keeps the trap, which is the same cut
  commonJS's `externals_missing` makes. The primitive methods
  `libs/std/src/primitives.bp` declares host-backed (`toUpper`, `join`, `at`, …)
  are not in this class — they are lowered natively (`lowerPrimMethod`).
- **Record inherent methods** (`lowerRecordMethod`): a call inference tagged
  `.record` lowers to `call $<Record>_<method>` with the receiver as `self`. A
  record method with a declared return type always has a `(result …)`, even
  when its body only throws.
- **Methods**: `implement`/`extend` methods (`emitExtensionMethods`) and record
  methods (`emitInterfaceMethods`) emit as `$<owner>_<method>` with `self` as a
  real `i32` param (synthesized when the body references `self` without
  declaring it — `bodyReferencesSelf`); dispatch lowers to `call $<target>_m`
  (`lowerDispatchCall`).
- **Field access by name**: `recv.field` resolves the receiver type via
  `local_types`, `record_field_types` and `self_type`; an unknown receiver emits
  `i32.const 0` with `;; (unknown receiver type)`. `?.` on records tests the
  pointer for `0` (none).
- **`@Result`**: a pointer to `[tag, payload]` (tag `0` = Ok). `map`/`flatMap`
  inline a literal lambda body (param bound to a `$_res{n}` local).
  `try`/`catch` → `if` on the tag.
- **`?T` / `@Option` — the carrier (decision 3 of the 1.0.2-beta semantics
  decisions: box, `0` is null)**: an optional is an i32 offset into linear
  memory, `0` = none. A pointer-shaped `T` (string, record, array) is its own
  offset; a scalar `T` (integer, bool, float) lives in a 4-byte box
  (`$__box_i32`), so a present `0` is not none. The box is made where a `T`
  flows into a declared `?T` — a `return` from a `-> ?T` fn, an annotated
  binding or global, an argument for a `?T` parameter, a `?T` record field —
  and by `xs.at(i)`/`first()` over a SCALAR element (`$__arr_at_box`; a
  string, record, array or tuple element is its own offset through
  `$__arr_at`, and `arrayElemOpt` is the one place that decides which — the
  writer and `optInfoOf` both read it, see [`wat/AGENTS.md`](wat/AGENTS.md))
  and `recv?.scalarField`. The
  payload is read by `if (x) { v -> … }`, `@print` (`$__print_opt_*`: none
  prints `undefined`), a `==`/`!=` against a value (none equals nothing),
  string `+` (none renders `undefined`) and `unwrapOr`/`map`/`flatMap` (a
  scalar `map` result is boxed again). `x == null` compares the offset with 0
  whatever `x` holds. An `if` with no `else` whose arm yields a string is a
  `?string` (absent when the condition is false) — what that value should be
  is decision 2's question, not settled here. Which declarations say "optional" is read from the
  declared `TypeRef`s (`typeRefOf`: params, return types, annotations, record
  fields, tuple elements); an `__bp_option_*` receiver of unknown type is
  taken as boxed unless its default is a string, record or array.

| Backend | `null` / none | present `?T` |
|---|---|---|
| commonJS | `null` | the value |
| erlang | `undefined` | the value |
| beam | `{atom, undefined}` | the value |
| wasm | `i32.const 0` | a pointer `T` itself; a scalar `T` boxed in a 4-byte cell |
- **Effects**: eager; `__bp_future_rejected` → `unreachable`.
- **Cross-module: static linking** (`collectLinks`): wasm has no module linking
  at run time, so a module that imports from another gets the owner's
  declarations emitted into it — transitively, dependencies first, minus the
  owner's `main`, tests and any name the consumer defines, and without the
  owner's exports. An import resolves through the export index
  (`import {double} from "math"`) or by module basename
  (`import {order} from "std"`). Each linked declaration is lowered with its
  own module's loc-keyed tables (`rewrites`, `instance_lowerings`).
- **Comptime-only builtins** (`@emit`, `@compilerError`, `Binding.ref`) have
  no wasm lowering: they only run inside comptime bodies, which the comptime
  pass evaluates on `erl`. A program module that reaches one traps
  (`unreachable ;; comptime-only builtin: <name>`). The single-fn `emitFnWat`
  hook, the raw-WAT prelude it was concatenated with and `Module.externs` were
  deleted with it — nothing called them.

### runtime

- `executeJavaScript` (`node`), `executeErlang` (`erlc` + `erl`),
  `executeBeamAsm` (`erlc +from_asm` + `erl`, assembling sibling `.S` aux modules
  so cross-module runs link), `executeWat` (`wasmtime run <module>.wasm` — the binary; the `.wat` text only where no binary was produced).
  The scratch file of an erlang/BEAM module is named by its module ATOM
  (`erlModuleAtom` → `crossModule.erlAtom` over `test_packages`, exactly as the codegen it runs, so `std/dict` is `std@dict.erl` and `main` is `test@main.erl`; `HARNESS_VERSION` was bumped with it, so no cached RUN LOG of the old spelling answers) and
  `-s <atom>` runs it; a second module of the program claiming an atom already
  taken is a loud `HARNESS ERROR:` RUN LOG, where the aux loop used to overwrite
  the first file silently — pinned by a test per backend (`my__mod/user` and
  `my_mod/user` both render `test@my_mod@user`), which found the check reading a
  freed key: `seen` keys on the atom slices it is handed, so every aux atom is
  kept in `aux_atoms` until the function returns, never freed per iteration.
  An `AuxFile` whose `atom` is set is a per-`type`
  module (`GenerateResult.units`, policy 3): its NAME already is an atom, so it
  is written as it stands instead of being rendered a second time, which would
  prepend the package a second time and lowercase the declaration half of `<package>@<path>@@<Decl>`. A `.wat` carries no module
  atom, so its scratch file keeps the basename.
  Captured text is stdout with stderr appended after a newline (wasm: stdout
  then stderr, no separator).
- **`executeWat` — the decision (06-wasm step 3): it executes.** It was turned
  on once a trap became a visible block and W1 had closed, so reaching
  `unreachable` means the program aborted rather than the backend giving up. It
  runs `wasmtime run` in a scratch dir (the `_start` export) on the module's
  **binary** (`GenerateResult.wasm`, `wat/wasm_binary_emitter.zig`, front 18) —
  so every wasm RUN LOG checks the binary emitter against the recorded fixture —
  and on the `.wat` text only where no binary was produced; the cache key is the
  bytes run,
  through the content-keyed cache, with no aux leg (imports are linked into the
  module statically) and **no** early bail on modules that print nothing (a
  silent module can still trap, and the trap must show). A missing `wasmtime`
  is an empty, uncached log. `HARNESS_VERSION` was bumped with it. Every wasm
  RUN LOG was re-recorded against a direct `wasmtime run` of the module and
  compared with commonJS/erlang; the known-wrong ones are pinned with a comment
  in their test.
- **A wasm trap is a visible block** (`runtimeTrapLog`): what the module
  printed, then `RUNTIME TRAP (wasmtime):` and the `wasm trap: …` line — never
  an empty log, and never the backtrace (its code offsets move with every
  lowering). Same shape as `COMPILE ERROR (<tool>):`.
- **Exit status, never output length** (`runCaptured` → `RunStatus`): a
  successful `erlc`/`erlc +from_asm` prints nothing and a program that prints
  nothing is not a failure, so the two can only be told apart by how the process
  ended. `.ok` = exited 0; `.failed` = ran, non-zero exit (deterministic —
  recordable and cacheable); `.unavailable` = missing binary, spawn error or
  timeout (host-dependent — never recorded, never cached, RUN LOG stays empty).
  Inferring failure from an empty buffer is what kept BEAM from ever executing
  and made an `erlc` warning swallow the whole run (spec 06 H1/H2).
- **What makes a RUN LOG**:
  - compile/assemble exits 0 → run the program, **warnings are dropped**;
  - compile/assemble exits non-zero → the RUN LOG is
    `COMPILE ERROR (erlc):` / `COMPILE ERROR (erlc +from_asm):` followed by the
    diagnostics, so a module a backend emits wrong (loader-validator rejections
    included) is visible instead of silently empty — error lines only, since
    `compileFailureLog` filters `Warning:` lines and OTP's `%  7| …` source
    echo so the block stays stable across OTP releases;
  - the program exits 0 → its captured output is the RUN LOG;
  - the program exits non-zero (crash, `badarith`, `init terminating`) → empty
    RUN LOG: the partial stdout comes with a stack trace not worth pinning;
  - a `node` run exits non-zero **and** `node --check` rejects the module →
    the RUN LOG is `COMPILE ERROR (node --check):` followed by
    `<module>.js:<line>`, node's source echo and caret, and the `SyntaxError:`
    line (stack frames and the `Node.js v…` banner dropped). A module that
    parses always runs, so checking only after a failed run sees every
    unparseable module; the node cache key is tagged `node+check` so entries
    recorded before this capture miss.
- **Determinism**: `erlc`/`erl` are spawned **with the scratch dir as their
  cwd** (`-o .`, `-pa .`, bare `<module>.erl` / `<module>.S` in argv), so
  diagnostics quote `main.erl:4:5:` instead of the random
  `.botopinkbuild/tmp/<hex>/` path, and an `erl_crash.dump` from a crashing
  fixture lands in the scratch dir that is deleted right after instead of in the
  repo tree. No absolute path can reach a snapshot.
- **Scratch layout**: every run mints `<cwd>/.botopinkbuild/tmp/<hex>/` via
  `makeScratchDir` (`TMP_ROOT`); cwd is `modules/compiler-core/` under
  `zig build test`. `build.zig`'s `clean-tmp` step (a dependency of the core
  test run) removes entries older than 1 day. `tests/runtime_scratch.zig` pins
  the layout.
- **Early bail**: `executeErlang`/`executeBeamAsm` return `""` without spawning
  when the code (entry + aux modules) has no `_botopink_main` or no
  `io:format`/`io:put_chars`/`io:fwrite` reference — a module that never writes
  also never reports a compile error.
- **Output cache** (`CACHE_ROOT = ".botopinkbuild/runtime-cache"`): the key is a
  SHA256 over `HARNESS_VERSION` + target tag + module name + code + aux modules;
  a hit skips the subprocess. Entries are prefixed `OK:` (anything else is a
  miss) and hold the final RUN LOG — an output, a `COMPILE ERROR` block or the
  empty string of a crash. An entry is **staged under a random sibling name and
  renamed into place**, never written in place: the path is content-keyed, so
  two writers agree on the bytes, but they share this cwd (parallel tests, two
  `zig build test` processes over one checkout) and a truncate-and-write is not
  one step — a reader arriving mid-write got a SHORT entry that still began
  `OK:`, and a truncated tail came back as the program's output with nothing
  saying so. Same shape as `comptime/template_eval.zig`'s `writeModule`, which
  stages precisely against this. Bump `HARNESS_VERSION` whenever the harness records
  something different for unchanged inputs, otherwise a warm cache hides the
  change. Toolchain versions are **not** part of the key — delete the cache dir
  after upgrading node/OTP. Nothing reaps it: `clean-tmp` only touches `tmp/`,
  and CI always runs cold (the directory is git-ignored).

## Primitive methods

Primitive-receiver methods (`xs.map(f)`, `s.toUpper()`) are tagged `.prim` in
`instance_lowerings` and lowered by each backend's `emitPrimMethod`:

1. **Annotation-driven first** — `tryEmitPrimAnnotation` looks up the
   interface method's `#[@External.<Target>(…)]` annotation in
   `libs/std/src/primitives.bp` (walking `extends` chains; erlang starts an
   integer receiver's walk at `Signed`, which reaches `Integer` and `Number` —
   from `Integer` it never found `Signed.abs`). A plain
   `("mod", "sym")` pair becomes a host call; a symbol with markers is rendered
   by `comptime/primOpTemplate.zig` (the receiver, `$0..$N`, `$args` — the source's
   positional markers translated by `parser/template_markers.zig`, decision 5 —
   `$stringify(…)`, `when($argc == N)` arity branches, `"""…"""` raw bodies).
   commonJS and erlang also route builtins (`print`, `todo`, `panic`, …) through
   `tryEmitBuiltinAnnotation`.
2. **BEAM templates** — `#[@External.Beam("""<.S body>""")]` registers in
   `prim_beam_templates`; `renderBeamTemplate` pre-loads each positional arg into
   `{x, i+1}` (reverse order) and the receiver into `{x, 0}` last
   (`min_live = argc + 1`), then renders the receiver → `{x, 0}`, `$N` → `{x, N+1}`,
   `$args` → `{x, 1..N}`. In tail position it emits `call_ext` + `return`
   rather than `call_ext_last`. A BEAM template wins over the erlang-derived
   dispatch and the inline switch.
3. **Inline switch** — what templates can't express:
   - beam_asm: array `contains`/`len`/`prepend`/`push`/`append`/`isEmpty`,
     2-arg `slice` (`primArraySlice2`, `gc_bif` arithmetic), `at`/`indexOf`/`join`
     (synthesized helper fns `ensureAtHelper`/`ensureIndexOfHelper`/
     `ensureStringifyHelper`); string `split`, 1-arg `slice`,
     `contains`/`startsWith` (`primCmpAgainstNomatch`). Returning `false` falls
     back to the local-call path. The template grammar has no label / `gc_bif` /
     helper-fn markers, so these stay inline.
   - erlang: array `len`/`length`/`size` → `length/1`, int/float `toString`
     fallback, and BIF-shaped fallbacks for un-annotated default fns
     (`forEach`, `fold`, `drop`, `take`, `toList`).

## Quick-reference rules

- Emitters are **blind** — they never inspect `ExprKind.comptime_`; the
  transform pass has already resolved everything.
- `fn main()` triggers an entry-point wrapper (`_botopink_main()` in JS;
  quoted `'_botopink_main'/0` in Erlang — plain atoms can't start with `_`).
- `commonJS.emitFnJs` is a pub single-fn emission hook with no
  program context. `emitJsonString` copies validated escape pairs verbatim
  (re-escaping would double source escapes); only real control chars and
  unescaped quotes (multiline content) are escaped.
- Expr templates: template fns (`-> @Expr<…>` / `@ExprCustom<…>`) are
  comptime-only — the transform pass substitutes every call site
  (`env.templateExpansions`, loc-keyed) and drops the declarations, so emitters
  never see them (nor `@expr`/`@code`). `typescript.zig` mirrors the drop via
  `TypeRef.isTemplateReturnType()`.
- Decorators (first param `comptime _: @Decl`) are dropped by the transform pass
  too; their bodies run in the persistent `erl` comptime runtime
  (`comptime/decorator_eval.zig`). Decls a body contributes via `@emit` are
  spliced into the module and emitted as ordinary declarations.
- `use` hooks: `use f(x)` lowers to `f(x)` on every backend (decision 88 of
  1.0.10-beta, front 19); `val`/`var` does the binding. CommonJS used to map
  hooks to React (`state` → `useState`, an inferred dependency array for
  `memo`/`effect`/… from the names earlier hooks bound) — `hookName`,
  `hookTakesDeps`, `buildHookCall`, `buildHookDeps`, `hook_state` are gone: the
  emitted name was never declared, and the client runtime supplies hook
  semantics through what `f` does. `#[@context]` is a plain function on every
  backend (the annotation gates `use` in the checker; the three eager-lowering
  comments exclude it beside `#[@result]`). Phantom `@Context` base structs
  (`isPhantomContextStruct`: implements `@Context`, no members) emit no runtime
  code. A record/struct with fields (incl. `record implement … { fields }`)
  emits a real constructor (`emitStruct` — field initializers become param
  defaults).
- A function-typed record field (`set: fn(next: T)`) is stored like any field;
  the `Children` coercion is type-level only.

## Effects (`#[@<effect>]`)

| Effect | commonJS | erlang | beam_asm | wat |
|---|---|---|---|---|
| `#[@result]` | plain `function`; `__bp_ok`/`__bp_error` build `{ok: V}`/`{error: E}`; `try`/`catch` via `"error" in _r` | plain fun; `{ok, V}`/`{error, E}`; `try`/`catch` → `case … of` | plain local; `put_tuple2` pair; `try`/`catch` → `is_tagged_tuple` | `[tag, payload]` in linear memory; `try`/`catch` → `if` on the tag |
| `#[@future]` | `async function`; resolved/rejected markers → native `return`/`throw` | eager (`@Future<T>` is `T`); rejected → `throw` | eager; rejected → `erlang:throw/1` | eager; rejected → `unreachable` |
| `#[@generator]` / `#[@iterator]` | `function*` (`return <iter>` → `yield*`) | eager; a body of only `yield`s → list | eager body | eager body |
| `#[@futureGenerator]` | `async function*` | eager | eager body | eager body |
| `#[@context]` | plain `function` | plain fun | plain local | plain func |

**Open, measured 2026-09-21 at front 20's landing: a `#[@context]` body may now
`await`, and commonJS cannot emit it.** Decision 95 made the effects a chain —
`@Context` extends `@Future` extends `@Result` — so `await` inside a
`#[@context]` body is legal, and `try` with it. `try` lowers everywhere (it is
the same propagate/`catch` shape the `#[@result]` row describes). `await` does
not: the `#[@context]` row above is a plain `function` on commonJS, so the
emitted `await` is

```
SyntaxError: await is only valid in async functions and the top level bodies of modules
```

while erlang, wasm and beam run it (their `@Future<T>` is eager, so `await` is
the identity and the row needs nothing).

**Taken by `00 · 04-js` (2026-09-21), narrowly.** `contextShape` raises the
`async` flag for a `#[@context]` function whose **built body** carries an
`await` of its own (`AwaitScan`: a nested arrow, function or class member owns
its own `await` and stops the walk). JavaScript has exactly one legal home for
an `await`, so a body that emits one has to be `async` or the module is not
JavaScript; and reading the built body rather than the declared effect means
the only programs whose output moves are the ones node refused to load at all.
A `#[@context] fn … -> Element` that awaits nothing — decision 88's component,
which is every one written today — keeps its plain `function`, and its caller
keeps receiving an `Element`.

**What was deliberately NOT taken**: making every `#[@context]` an `async
function` regardless of its body, which is the wider and more readable
contract (a caller could tell from the signature). It would change what every
component's caller receives, and that is the maintainer's call. The cost of
the narrow rule is that two `#[@context]` functions with the same signature can
have different call contracts; the cost of the wide one is every component.

What a caller receives on commonJS is unchanged in kind: a suspending function
hands back a promise, exactly as `#[@future]` already does (`@print(f())` prints
`Promise { <pending> }` on commonJS and the value on erlang and wasm — measured,
pre-existing, and not this row's). `tests/language/run/effect_context_await.bp`
pins the row and prints every value from inside the awaiting body for that
reason; `run/effect_chain.bp` carries `use` and `try`.

Effect rejection diagnostics (R*, RF*, RI*, RC*, RG* codes) live in
`comptime/diagnostics.zig`; `comptime/infer.zig`'s `inEffectContext` uses the
`effect` field of `comptime/env.zig`'s `StarFnCtx` so each family's rejections
fire only inside the right effect body. Which body operations each effect may
hold is `comptime/effect_chain.zig`, not a table here: the four checks
(`try`/`await`/`use`/`yield`) ask it the same question.

## Tuple labels (decision 8 §6)

No backend reads a tuple label. `row.label` reaches codegen already rewritten to
`row._N` by the checker (`comptime/AGENTS.md`), and a labeled tuple type
(`ast.TypeRef.labeledTuple`) is the positional tuple everywhere: `.d.ts` tuple
(`typescript.zig`), commonJS/wasm print shapes via `TypeRef.tupleElems`.

**Closed on beam** (03 step 3 D5, re-verified 2026-09-18 by assembling and
running, not by reading the `.S`): every shape 06 N24 landed answers on beam what
it answers on erlang — a label read through a return type, through a parameter
type and through a written annotation (`SP`, `13`, `RJ`, `3`, `12`, `2`), a
labelled element of **function** type applied as a method (`c.set(9)` → `18`), a
bare digit index under an `Option.map` (`2`, `true`) and a chained positional
access with a method on the element (`2`, `x`, `7`). The fixtures are
`snapshots/codegen/beam/beam/tuple_labels_resolve_to_positions_on_every_backend`,
`…_a_labeled_element_of_function_type_is_called_like_a_method`,
`…_a_bare_digit_index_and_an_option_map_over_a_found_pair` and
`…_chained_positional_access_and_a_method_on_an_element`. What is **not** closed
is a label behind a `?T` (`rs.at(0).b`): the rewrite never fires there, which is
decision 45's row and the checker's, not a backend's.
