# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`
(`generate(alloc, modules, io, config)` runs the comptime session, then the
selected backend's `codegenEmit`).

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
├── commonJS.zig      ← CommonJS emitter (blind: iterates transformed AST)
├── erlang.zig        ← Erlang source emitter (blind)
├── beam_asm.zig      ← BEAM Assembly `.S` emitter
├── beam/             ← BEAM term model + shared `.erl`/`.S` emitters — see [`beam/AGENTS.md`](beam/AGENTS.md)
├── wat.zig           ← WebAssembly Text `.wat` emitter
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← executes generated code in tests (RUN LOG capture)
├── snapshot.zig      ← codegen snapshot builder / assertions
├── tests.zig         ← barrel: aggregates tests/<feature>.zig + beam/*.zig for test_root.zig
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
    ├── std_package.zig         ← `from "std"` qualified calls + builtin `result` namespace
    ├── wat.zig                 ← WAT backend codegen
    ├── dts_skips_templates.zig ← `.d.ts` drops `@Expr`/`@ExprCustom` template fns
    ├── runtime_scratch.zig     ← pins the `.botopinkbuild/tmp/<hex>/` scratch layout
    └── comptime_module.zig     ← `emitComptimeModule` (untyped lowerings, host enums, variable versioning)
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config` (`targetSource`, `typeDefLanguage`, `build_root`, `test_mode`), `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `TypeDefLang` |
| `moduleOutput.zig` | `GenerateResult` (`js`, `typedef`, `comptime_script`, `comptime_err`, `run_output`) and `ModuleOutput` — shared between targets. `Module` lives in `../module.zig` |
| `crossModule.zig` | **Cross-module link index** built once over every module's transformed program (`build(alloc, outputs)`). `exports` maps a `pub` symbol → `ExportInfo{module, kind, is_class, fields}` (emitting module path, decl kind, whether construction needs `new`/the owner's map shape, and a record's declared field order); host-backed `#[@External.<Target>(…)]` fns are indexed too, so a consumer importing one `from "<lib>"` links to the owner like any other export. `imported` is the set of names some module imports. `ownerModuleAtom(name)` / `moduleBasename(path)` give the Erlang/BEAM module atom (`web/http` → `http`). Consumed by commonJS, erlang and beam_asm; wat only uses it to flag unlinkable imports |
| `beam/` | BEAM term model + emitters shared by `erlang.zig`, `beam_asm.zig` and the comptime evaluators: `term.zig` (`Term`), `erl_emitter.zig` (Erlang source: atom quoting incl. reserved words, variables, module names, binaries), `beam_emitter.zig` (`.S` operands and `move`s). One quoting rule for `.erl` and `.S`. See [`beam/AGENTS.md`](beam/AGENTS.md) |
| `commonJS.zig` | CommonJS emitter. See [commonJS](#commonjs) below |
| `erlang.zig` | Erlang source emitter. See [erlang](#erlang) below |
| `beam_asm.zig` | BEAM Assembly `.S` emitter, assembled with `erlc +from_asm`. See [beam_asm](#beam_asm) below |
| `wat.zig` | WebAssembly Text emitter. See [wat](#wat) below |
| `typescript.zig` | `.d.ts` typedef generator (optional secondary output, `Config.typeDefLanguage`). Type declarations only — no call lowering. Skips template fns (`TypeRef.isTemplateReturnType()`) and phantom `@Context` structs, erases `@Context<B, R>` to `R`, renders an anonymous `TypeRef.record_type` as `{ f: T; … }` |
| `runtime.zig` | Test-side execution for the snapshot `----- RUN LOG -----` block. See [runtime](#runtime) below |
| `snapshot.zig` | `buildSnapshot` / `buildSnapshotMulti` / `assertCodegen` / `assertCodegenError` |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` and the `beam/*.zig` unit tests; harness in `tests/helpers.zig` (`assertJs`, `assertJsSingle`, `assertJsError`, `assertJsTestMode`, `assertJsContains`, `assertConsumerJs`, `configs` — one config per target) |

### commonJS

- **`@Result`** is `{ ok: V } | { error: E }`; `__bp_ok`/`__bp_error` build it for
  `return`/`throw` in `#[@result]` fns; `try`/`catch` lower to `"error" in _r`
  pattern matching.
- **Static extension dispatch**: `implement`/`extend` blocks emit as namespace
  objects (`emitExtensionNamespace`: `const Sym = { m(self){…} }`, no prototype
  patching); an activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the
  loc-keyed `dispatch_rewrites` map.
- **Method renames**: the loc-keyed `js_method_renames` map (from inference) is
  consulted first, then the annotation-derived `prim_node_renames`
  (`s.contains` → `s.includes`). A rename to `length` on a no-arg call emits
  the native `.length` **property** without parens (`as_property`); inference
  records it only for typed array/string receivers, so a record `length()`
  method is untouched.
- **Externals**: `#[@External.Node("module", "symbol")]` fns (`collectExternals`)
  lower to `const { symbol: name } = require("module");` (a JS global such as
  `Math` is referenced directly). A symbol carrying `$` markers or
  `when($argc == N)` branches is a template rendered inline at each call site
  (`user_node_templates`). A fn with no `node` target raises
  `MissingExternalTarget` when called.
- **Duplicate test names**: two `test "x"` blocks in one module print
  `warning: duplicate test name "x" in <mod>.bp:<line>` to stderr; both run.
- **Cross-module linking** (`crossModule.zig`): `from "<pkg>"` imports become
  `require("./<path>.js")` of the owning file (declaration-only names such as
  decorators emit nothing); imported records are marked as classes so
  construction emits `new`; `exports.X` is emitted only for `pub` symbols
  another module imports.
- **Lib namespace object**: when an import names the lib itself
  (`import {Lib} from "Lib"`) and that name has no emitted symbol, `emitUse`
  binds the lib's module object (`const Lib = require(…)`, or
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
- **Ranges**: `a..b` materializes `Array.from({length: Math.max(0, b - a)}, …)`;
  an open-ended `a..` throws at runtime.
- **Effects**: `fnKeyword` picks `async function` / `function*` /
  `async function*`; inside a generator, `return <iter>` becomes
  `yield* <iter>; return;` and `loop (xs) { x -> yield x }` becomes `for…of`.

### erlang

- **Single-assignment versioning:** Erlang variables bind once, so a name already
  bound in the function gets a fresh variable on every later binding — `=`, `+=`
  or a shadowing `val i = i - 1` lowers to `Count@1 = Count + 1` and later reads
  resolve to the current version (`emitBind`/`varRef`, `var_current`/`var_next`
  reset per fn; versions are never reused so separate `case` arms can't
  collide). A version bound inside a `case`/`fun` and read after it is left as an
  Erlang compile error (unsafe/unbound) rather than silently wrong.
- **Comptime modules:** `emitComptimeModule(alloc, name, program, .{ host_enums,
  exports, tail })` lowers an untyped decorator/template body with the same
  emitter — `host_enums` join `enum_names` (`DeclKind.Record` → `'Record'`),
  `exports` are prepended to `-export`, `tail` is raw Erlang appended after the
  `'__bp_add'/2` / `'__bp_len'/2` helpers; the `untyped` flag routes `+` to
  `'__bp_add'` (binary concat or arithmetic) and `.len`/`.length` without an
  instance lowering to `'__bp_len'(X, Field)`. Tests: `tests/comptime_module.zig`.
- **Names**: `atomName`/`fnAtom`/`erlangVar`/`erlangModule` are aliases of
  `beam/erl_emitter.zig`; `emitBinary` delegates to
  `erl_emitter.writeBinaryFromLexeme`.
- **Records are maps**: constructors lower to `#{field => V, …}` (positional args
  use the declared field order from `collectTypeShapes`); field access is
  `maps:get(field, Recv)`; tuple index `t._N` → `element(N+1, T)`. No `-record`
  declarations are emitted. Optional chaining `?.` guards on `undefined` via an
  immediate fun.
- **Enums**: `Order.Lt` → the variant atom; `Color.Rgb(r, g, b)` →
  `{'Rgb', R, G, B}`. A bare `.ident` case pattern is the atom when it names a
  known variant (`enum_variants`), else a variable. Case arms also lower list
  patterns (`[]`/`[X]`/`[First | Rest]`).
- **Calls**: a PascalCase receiver is a module reference (`isModuleRef`) →
  remote `list:map(…)`; a receiver naming a local record calls the local
  associated fn. A no-receiver call to a fn-typed local (`locals`) is a fun
  application `F(args)`.
- **Control flow**: `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`;
  an `if` whose then-branch returns nests the rest of the body in the false arm
  (`emitEarlyReturnIf`). `a..b` → `lists:seq(A, B - 1)`.
- **Static extension dispatch**: `implement`/`extend` methods are local functions
  keeping `self` as the first param (`keep_self`); activated `recv.m(args)`
  (`dispatch_rewrites`) and qualified `Sym.m(obj)` (`ext_names`) lower to
  `m(recv, args)`.
- **Externals**: `#[@External.Erlang("module", "symbol")]` fns emit no decl and
  calls lower to `module:symbol(Args)` (`externals`); `$`-marker / `when(…)`
  symbols render inline (`user_erlang_templates`); no `erlang` target →
  `MissingExternalTarget`.
- **Cross-module**: an imported record joins `record_fields` + `imported_types`
  (`collectImportedTypes`), so construction inlines the owner's map shape and
  `Response.ok(…)` calls into the owner module atom (`http:ok(…)`); the owner
  exports a `pub` type's associated fns when another module imports it.
- **Interface associated `default fn`s** (`Array.range`, `Pair.of`):
  `emitInterface` emits each no-`self` body as a local function
  (`collectInterfaces`); `Interface.method(...)` calls it (reserved words quoted,
  e.g. `'of'`).
- **Value-receiver instance methods**: record/enum/struct methods keep `self`
  (`isAssocMethod` gates `keep_self`); `recv.m(args)` lowers via the loc-keyed
  `instance_lowerings` table — `.record` → local (or `owner:`) call, `.prim` →
  `emitPrimMethod` (see [Primitive methods](#primitive-methods)).
  `arr.length`/`s.length` field access also lowers through `instance_lowerings`.
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

- **Coverage**: numerics, locals, calls, booleans, assign, throw, strings,
  `@print`, field access/assign, arrays, tuples, records/structs
  (`put_map_assoc` maps), case (all patterns + guards via
  `emitGuardPre`/`emitGuardPost`), `if` as value (`emitValueIf`) and as
  statement (`emitIf` — the false branch falls through, never an early
  `return`), try/catch (`is_tagged_tuple`), ranges (`lists:seq(A, B - 1)`),
  loops, pipeline, closures, `call_fun`, `@Result`/`@Option` ops
  (`lowerResultOptionOp`: `{ok, V}`/`{error, E}` and bare value / `undefined`,
  mirroring erlang), optional chaining (`lowerIdentAccess`: `is_eq` on
  `undefined`, then `is_map` + `get_map_elements`).
- **Names**: `atomName` = `erlEmitter.atomText`; string literals, atom moves and
  function names go through `beam/beam_emitter.zig` and `erlEmitter.atom(...)`.
- **Closures** (`emitMakeFun`): `test_heap` with `{alloc, [{funs, 1}]}` +
  `make_fun3` into `{x, 0}` (`make_fun2` is rejected by `+from_asm`). `Live`
  honours the `min_live` floor so scratch x-registers survive the allocation;
  lambda bodies reset `min_live` to 0 for their fresh frame.
- **Calls**: module-qualified `List.map(…)` → `call_ext`/`call_ext_last`
  (trailing lambdas materialized as funs); `from "std"` qualified calls
  (`math.floor(x)`) → `call_ext` via `collectStdImports`; interface
  associated `default fn`s emit as mangled locals `'Interface_method'`
  (`reserveInterfaceMethods`/`emitInterfaceAssoc`).
- **Static extension dispatch**: `implement`/`extend` methods are emitted and
  exported as `'<target>_<method>'`; activated `recv.m(args)` and qualified
  `Sym.m(obj)` call it with the receiver prepended (`ext_by_name`,
  `extMangledName`, `lowerExtCall`).
- **`erlc +from_asm` invariants**: comparisons use only `is_lt`/`is_ge` (no
  `is_gt`/`is_le` — operands swap, `comparisonTestOp`); `{allocate, N, A}` is
  followed by `{init_yregs, …}` (`emitFrame`); `countLocalsRec` counts case-arm
  and destructure bindings so the frame is sized correctly.
- **Register-liveness gotchas**: the array-literal `test_heap` counts only the
  x-registers an element reads; `gc_bif` and `materializeCallArgs` honour
  `min_live` so already-materialized args survive; the range loop materializes
  the iterable before building the body closure (a `lists:seq` call would
  clobber the stashed fun); a `val` bound before a recursive call spills to a
  y-slot and survives the call.
- **Cross-module**: the module atom is the path basename; an imported record
  joins `record_fields` + `imported_types` (`collectRecordShapes`), its
  associated fn lowers to `call_ext` into the owner (`http:'Response_ok'(…)`),
  and the owner exports `'Type_method'/arity` when imported elsewhere. A field
  read on a `call_ext` result emits `is_map` before `get_map_elements` (the
  result is typed `any`, which the loader rejects otherwise).
- **Builtins**: `lowerBuiltinCall` hardcodes `@print` (`io:format("~p~n", …)`),
  `@todo`/`@panic` (`erlang:error/1`) and `__bp_*` ops at register level.
- **Effects**: non-`#[@result]` effect fns get an eager body;
  `__bp_future_rejected` → `erlang:throw/1`.
- Unhandled shapes emit `%% unsupported: …` / `%% unresolved …` /
  `%% prim method not lowered on beam (…)` comments instead of mis-emitting.

### wat

- **Coverage**: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`,
  globals, case, pipeline (`a |> f` → `call $f`), range loops
  (`lowerRangeLoop`), `@print` via WASI `fd_write`, `_botopink_main`/`_start`.
- **Known gaps**: lambdas lower to a `i32.const 0 ;; lambda` placeholder;
  non-range loops emit `i32.const 0 ;; loop over non-range`; unhandled shapes
  emit `;; unsupported …` comments.
- **Booleans**: `true`/`false` are identifiers lowered to `i32.const 1`/`0`
  (never `global.get $true`, which references an undefined global).
- **Entrypoint** (`emitEntrypointWrapper`): calls `$main` and `drop`s its
  result when `main` returns a value (`main_returns_value`).
- **Aggregates in linear memory**: tuples/arrays/records/enum payloads are
  contiguous 4-byte slots in the bump heap (`$__heap_ptr`); a type registry from
  `record`/`enum` decls distinguishes construction from calls; construction
  stashes the base in a `$__mem{n}` local; enum payloads are `[tag, …fields]`.
- **Strings**: literal `+` → `$__str_concat`, literal `==`/`!=` → `$__str_eq`.
- **Methods**: `implement`/`extend` methods (`emitExtensionMethods`) and record
  methods (`emitInterfaceMethods`) emit as `$<owner>_<method>` with `self` as a
  real `i32` param (synthesized when the body references `self` without
  declaring it — `bodyReferencesSelf`); dispatch lowers to `call $<target>_m`
  (`lowerDispatchCall`).
- **Field access by name**: `recv.field` resolves the receiver type via
  `local_types`, `record_field_types` and `self_type`; an unknown receiver emits
  `i32.const 0` with `;; (unknown receiver type)`. `?.` on records tests the
  pointer for `0` (none).
- **`@Result`/`@Option`**: a `@Result` is a pointer to `[tag, payload]` (tag `0`
  = Ok); a `@Option` is the bare value with `0` = none. `map`/`flatMap` inline a
  literal lambda body (param bound to a `$_res{n}` local). `try`/`catch` → `if`
  on the tag.
- **Effects**: eager; `__bp_future_rejected` → `unreachable`.
- **Cross-module**: single-module only. An import resolving to another module's
  export emits `;; cross-module import not linked (wasm single-module)`.
- `emitFnWat` is a pub single-fn hook (wat analogue of `commonJS.emitFnJs`).

### runtime

- `executeJavaScript` (`node`), `executeErlang` (`erlc` + `erl`),
  `executeBeamAsm` (`erlc +from_asm` + `erl`, assembling sibling `.S` aux modules
  so cross-module runs link). `executeWat` is currently a stub that returns an
  empty RUN LOG. Only stdout is captured; a non-zero exit yields `""`.
- **Scratch layout**: every run mints `<cwd>/.botopinkbuild/tmp/<hex>/` via
  `makeScratchDir` (`TMP_ROOT`); cwd is `modules/compiler-core/` under
  `zig build test`. `build.zig`'s `clean-tmp` step (a dependency of the core
  test run) removes entries older than 1 day. `tests/runtime_scratch.zig` pins
  the layout.
- **Early bail**: `executeErlang`/`executeBeamAsm` return `""` without spawning
  when the code (entry + aux modules) has no `_botopink_main` or no
  `io:format`/`io:put_chars`/`io:fwrite` reference.
- **Output cache** (`CACHE_ROOT = ".botopinkbuild/runtime-cache"`): inputs
  (target tag, code, aux modules, module name) hash to a SHA256 key; a hit skips
  the subprocess. Entries are prefixed `OK:` (anything else is a miss). Toolchain
  versions are not part of the key — delete the cache dir after upgrading
  node/OTP. `clean-tmp` does not reap it.

## Primitive methods

Primitive-receiver methods (`xs.map(f)`, `s.toUpper()`) are tagged `.prim` in
`instance_lowerings` and lowered by each backend's `emitPrimMethod`:

1. **Annotation-driven first** — `tryEmitPrimAnnotation` looks up the
   interface method's `#[@External.<Target>(…)]` annotation in
   `libs/std/src/primitives.bp` (walking `extends` chains). A plain
   `("mod", "sym")` pair becomes a host call; a symbol with markers is rendered
   by `comptime/primOpTemplate.zig` (`$self`, `$0..$N`, `$args`,
   `$stringify(…)`, `when($argc == N)` arity branches, `"""…"""` raw bodies).
   commonJS and erlang also route builtins (`print`, `todo`, `panic`, …) through
   `tryEmitBuiltinAnnotation`.
2. **BEAM templates** — `#[@External.Beam("""<.S body>""")]` registers in
   `prim_beam_templates`; `renderBeamTemplate` pre-loads each positional arg into
   `{x, i+1}` (reverse order) and the receiver into `{x, 0}` last
   (`min_live = argc + 1`), then renders `$self` → `{x, 0}`, `$N` → `{x, N+1}`,
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
- `commonJS.emitFnJs` / `wat.emitFnWat` are pub single-fn emission hooks with no
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
- `use` hooks: `use` is a transparent prefix; `val`/`var` does the binding.
  CommonJS maps hooks to React (`state` → `useState`, …) via `writeHookName`;
  `memo`/`effect`/`callback` get an inferred dependency array from the reactive
  names (`hook_state`) the lambda reads (`identInExpr`). Erlang/BEAM/WAT lower
  `use` transparently. Phantom `@Context` base structs
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
| `#[@asyncGenerator]` | `async function*` | eager | eager body | eager body |
| `#[@context]` | plain `function` | plain fun | plain local | plain func |

Effect rejection diagnostics (R*, RF*, RI*, RC*, RG* codes) live in
`comptime/diagnostics.zig`; `comptime/infer.zig`'s `inEffectContext` uses the
`effect` field of `comptime/env.zig`'s `StarFnCtx` so each family's rejections
fire only inside the right effect body.
