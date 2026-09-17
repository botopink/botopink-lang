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
    ├── std_package.zig         ← `from "std"` qualified calls + builtin `result` namespace
    ├── wat.zig                 ← WAT backend codegen
    ├── dts_skips_templates.zig ← `.d.ts` drops `@Expr`/`@ExprCustom` template fns
    ├── runtime_scratch.zig     ← pins the `.botopinkbuild/tmp/<hex>/` scratch layout
    └── comptime_module.zig     ← `emitComptimeModule` (untyped lowerings, primitive-method shims, host enums, variable versioning)
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config` (`targetSource`, `typeDefLanguage`, `build_root`, `test_mode`), `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `TypeDefLang` |
| `moduleOutput.zig` | `GenerateResult` (`js`, `typedef`, `comptime_script`, `comptime_err`, `run_output`) and `ModuleOutput` — shared between targets. `Module` lives in `../module.zig` |
| `crossModule.zig` | **Cross-module link index** built once over every module's transformed program (`build(alloc, outputs)`). `exports` maps a `pub` symbol → `ExportInfo{module, kind, is_class, fields}` (emitting module path, decl kind, whether construction needs `new`/the owner's map shape, and a record's declared field order); host-backed `#[@External.<Target>(…)]` fns are indexed too, so a consumer importing one `from "<lib>"` links to the owner like any other export. `imported` is the set of names some module imports. `ownerModuleAtom(name)` / `moduleBasename(path)` give the Erlang/BEAM module atom (`web/http` → `http`). Consumed by commonJS, erlang and beam_asm; wat only uses it to flag unlinkable imports |
| `js/` | JS/TS code model + emitters shared by `commonJS.zig` and `typescript.zig`: `js_ast.zig` (`Expr`/`Stmt`/`Pattern`/`Block`/`Class`/`Item` + the `.d.ts` `TsDecl`/`TsType` + `Builder`), `js_emitter.zig` (the only writer of JavaScript: reserved-word renaming, string escaping, parenthesisation, indentation, semicolons), `ts_emitter.zig` (the only writer of `.d.ts`). The backends build nodes and write no target text. The four `js_ast` bridges pin the shapes the current lowering still emits illegally. See [`js/AGENTS.md`](js/AGENTS.md) |
| `beam/` | BEAM term model + emitters shared by `erlang.zig`, `beam_asm.zig` and the comptime evaluators: `term.zig` (`Term`), `erl_emitter.zig` (Erlang source: atom quoting incl. reserved words, variables, module names, binaries), `beam_emitter.zig` (`.S` operands and `move`s). One quoting rule for `.erl` and `.S`. See [`beam/AGENTS.md`](beam/AGENTS.md) |
| `commonJS.zig` | CommonJS backend — builds `js/js_ast.zig` nodes, rendered by `js/js_emitter.zig`. See [commonJS](#commonjs) below |
| `erlang.zig` | Erlang source emitter. See [erlang](#erlang) below |
| `beam_asm.zig` | BEAM Assembly `.S` emitter, assembled with `erlc +from_asm`. See [beam_asm](#beam_asm) below |
| `wat/` | WebAssembly-text code model and the only writer of `.wat`: `wat_ast.zig` (`Module`/`Item`/`Func`/`Seq`/`Instr` + `Builder` + the invariants), `wat_emitter.zig` (s-expression layout, `$` names, data escaping), `wat_prelude.zig` (the runtime helpers as built nodes). See [`wat/AGENTS.md`](wat/AGENTS.md) |
| `wat.zig` | WAT backend: builds `wat/wat_ast.zig` nodes and hands them to the emitter. See [wat](#wat) below |
| `typescript.zig` | `.d.ts` typedef backend (optional secondary output, `Config.typeDefLanguage`) — builds `js/js_ast.zig` `TsDecl` nodes, rendered by `js/ts_emitter.zig`. Type declarations only — no call lowering. Skips template fns (`TypeRef.isTemplateReturnType()`) and phantom `@Context` structs, erases `@Context<B, R>` to `R`, renders an anonymous `TypeRef.record_type` as `{ f: T; … }` |
| `runtime.zig` | Test-side execution for the snapshot `----- RUN LOG -----` block. See [runtime](#runtime) below |
| `snapshot.zig` | `buildSnapshot` / `buildSnapshotMulti` / `assertCodegen` / `assertCodegenError`; `writeComptimeSections` writes `GenerateResult.comptime_trace` (`COMPTIME ERLANG` / `COMPTIME REPLY`, rendered by `comptime/trace.zig`) then `COMPTIME VALUES` for every backend. A `SnapInput` with `result == null` (the module never reached the backend) or with `comptime_err` set writes a `COMPILE DIAGNOSTIC` section instead of the code section — spec 06 H3, which used to leave such snapshots empty |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` plus the `beam/*.zig` and `wat/wat_emitter.zig` unit tests; harness in `tests/helpers.zig` (`assertJs`, `assertJsSingle`, `assertJsError`, `assertJsTestMode`, `assertJsContains`, `assertConsumerJs`, `configs` — one config per target) |

### commonJS

- **Model, not text**: every `build*` method returns a `js/js_ast.zig` node and
  `js/js_emitter.zig` renders the module (`writeProgram`). The backend owns the
  lowering decisions listed below; quoting, the reserved-word rename, string
  escaping, parenthesisation, indentation and semicolons belong to the emitter.
  Nodes are built in one arena that is freed once the module is rendered. The
  only text this file still composes is a comment's wording, a `require` path
  and the fixed test-harness source (`Item.runtime`).
- **`@Result`** is `{ ok: V } | { error: E }`; `__bp_ok`/`__bp_error` build it for
  `return`/`throw` in `#[@result]` fns; `try`/`catch` lower to `"error" in _r`
  pattern matching.
- **Static extension dispatch**: `implement`/`extend` blocks emit as namespace
  objects (`buildExtensionNamespace`: `const Sym = { m(self){…} }`, no prototype
  patching); an activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the
  loc-keyed `dispatch_rewrites` map.
- **Method renames**: the loc-keyed `js_method_renames` map (from inference) is
  consulted first, then the annotation-derived `prim_node_renames`
  (`s.contains` → `s.includes`). A rename to `length` on a no-arg call emits
  the native `.length` **property** without parens (a `member` node, not a
  `call`); inference
  records it only for typed array/string receivers, so a record `length()`
  method is untouched.
- **Externals**: `#[@External.Node("module", "symbol")]` fns (`collectExternals`)
  lower to `const { symbol: name } = require("module");` (a JS global such as
  `Math` is referenced directly). A symbol carrying `$` markers or
  `when($argc == N)` branches is a template rendered inline at each call site
  (`user_node_templates`); so is a 1-arg form without markers
  (`#[@External.Node("process.cwd()")]`), a bare host expression rendered
  verbatim — neither emits an import binding or a `require(…)`. A template fn
  emits no `exports.<name>`, so a cross-module call (`env.read(…)` after
  `import {env} from "std"`) does not resolve yet. A fn with no `node` target raises
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
  collide). **Pattern bindings version too** (`patternBindVar`): erlang patterns
  do not shadow, so `case sh { Square(s) -> … }` with `s` already a parameter
  would MATCH against it (`{'Square', S@1}` is the binding), and a name bound by
  one clause of an earlier `case` is "unsafe" in a later one. A version bound
  inside a `case`/`fun` and read after it is left as an Erlang compile error
  (unsafe/unbound) rather than silently wrong.
- **Modules are `erl_ast` forms**: `emitErlangModule` builds every form in one
  arena and renders them with `erl_emitter.writeForms`: `-module`,
  `-compile({no_auto_import,…})` (`noAutoImportRefs`), `-export`s, then each
  declaration after a `.blank` — `topValForms` (see **Module-level `val`s** below), `fnForms` (parameters, destructured
  tuples, plain `yield` generators as lists), `recordForms`/`enumForms`/
  `interfaceForms`/`implementForms`/`extendForms` (a `%%` comment plus method
  functions), `use`/`delegate`/external-fn comments, `testFunction` — the comptime
  helper and host forms, the `'_botopink_main'/0` + `main/1` entrypoint wrapper and,
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
  forms (`comptimeNode`: `assert` as an inline `case` in test mode, `assertPattern`).
  Record/interface literal keys are atoms (quoted when PascalCase or reserved); an
  array spread concatenates (`[1, 2] ++ Rest`, `nameRefNode` for the spread name);
  a leading-dot enum shorthand (`.Black`) is the variant atom.
- **Calls are `erl_ast` nodes** (`callNode`): pipelines apply inside out
  (`pipelineNode`); builtins (`builtinCallNode`) render their `@external(erlang, …)`
  template, `@block` as an applied `fun`, or the `__bp_*` result/option ops
  (`resultOptionNode`, inline `fun`+`case`); `plainCallNode` does receiver dispatch
  (std module, activated extension, enum constructor tuple, imported/local
  associated fn, mangled interface assoc, module-qualified call, primitive
  (`primMethodNode`) / record instance methods, Array default-fn fallback),
  user templates, externals, record constructor maps and fun-typed locals. Host
  templates (`primOpTemplate`) become `seq` nodes (`templateNode`): the template
  text stays verbatim around the receiver/argument nodes. Heads the backend has
  always written as spelled (`mod:sym`, mangled atoms, `Var`) use `headCall`.
- **Mutation through branches and loops** (`mutatingExpr`): a statement-level
  `if` / `loop (xs) { x -> … }` / `xs.forEach({ x -> … })` that reassigns variables
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
- **Comptime modules:** `emitComptimeModule(alloc, name, program, .{ host_enums,
  host_records, exports, forms, listing, unsupported_method })` lowers an untyped decorator/template body with
  the same emitter — `host_enums` join `enum_names` (`DeclKind.Record` →
  `'Record'`), `host_records` (`HostRecord{name, fields}`) join `record_fields`
  so host record constructors build maps, `exports` (`[]erl_ast.FnRef`) are prepended to `-export`,
  `listing = true` renders only the lowered decls and `forms` (no header,
  exports or helpers — the `COMPTIME ERLANG` snapshot section, not a compilable
  module), `forms` (`[]erl_ast.Form`) are rendered after the
  `'__bp_add'/2` / `'__bp_len'/2` helpers; the `untyped` flag routes `+` to
  `'__bp_add'` (binary concat or arithmetic) and `.len`/`.length`/`.size` without an
  instance lowering to `'__bp_len'(X, Field)`.
  **Primitive methods** in a body (`untypedPrimCallNode`, reached from
  `plainCallNode` after the Array fallbacks): a value-receiver call
  `recv.m(args)` that a host form defines (`name/argc+1` in `forms` — `q.text()`,
  `decl.fail(msg)`) stays the bare local call; one that some primitive kind
  answers becomes `'__bp_prim_m'(Recv, Args…)`. `primShimForms` emits one shim
  per reached `(m, argc)`, behind the `!listing` gate: a clause per kind in
  `prim_shim_kinds` (`is_list`/`is_binary`/`is_boolean`/`is_integer`/`is_float`)
  whose body is the typed path's own lowering (`primHostMethodNode` — annotation,
  inline cases, Array fallbacks — else `primDefaultShimNode`, which calls the
  instance `default fn` with omitted trailing params filled from their declared
  defaults), then a clause raising `{bp_unsupported_method, <<"m">>, Argc, Recv}`
  (`toString/0` formats through `'__bp_text'` instead). The prelude's bodied
  instance defaults (`String.slice`, `Array.first`) are indexed for comptime
  modules by `collectPreludeInstanceDefaults` (the parse lives until the module is
  rendered); shims and the defaults they reach drain to a fixpoint. So BIF-named
  methods (`length`, `abs`, `floor`) dispatch on the receiver too. A call nothing
  answers is recorded in `unsupported_method` (when set, compilable emit only)
  and the emit fails with `error.UnsupportedComptimeMethod`; the evaluators turn
  it into a located diagnostic. `primErlangDispatchCount` exposes the size of the
  prelude's dispatch table for a regression test. Tests: `tests/comptime_module.zig`.
- **Names**: `atomName`/`fnAtom`/`erlangVar`/`erlangModule` are aliases of
  `beam/erl_emitter.zig`. `erlang.zig` writes no Erlang text itself: the emitter
  builds `erl_ast` nodes and forms and `erl_emitter` renders them (`raw` remains
  only for host template text and names written as spelled). Comments are
  `erl_ast.Comment` nodes: source comments keep their level (`//` → `%`, `///` →
  `%%`, `////` → `%%%`, `commentNode`), and the `%%` notes the backend writes
  (declaration headers, `continue`, unsupported field assignment) carry only
  their text.
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
  (`emitEarlyReturnIf`). `a..b` → `lists:seq(A, B - 1)`. `&&`/`||` are
  `andalso`/`orelse` — botopink short-circuits, erlang's `and`/`or` do not.
  `if (x)` on a nullable local (`?T`, or a parameter defaulting to `null`) is the
  null test `(X =/= undefined)`, not a boolean test (`condNode`).
- **Loops** lower by shape, not by name:
  - a body producing a value per item (`yield`, or `break <expr>`) → `lists:map`;
  - a body that is one `else`-less `if` ending in `break <expr>` → `lists:filtermap`
    with `{true, V}` / `false` (`filterMapFunBody`) — the filter+map botopink means;
  - `loop (xs, 0..) { item, i -> … }` → `lists:enumerate(Start, Xs)` and a single
    `{I, Item}` tuple parameter (`lists:map/foreach` pass ONE element, so two fun
    parameters never matched);
  - an open-ended range `loop (x..)` → a named fun that counts up and recurses
    (`fun __Loop(I) -> …, __Loop(I + 1) end`), since `lists:seq/2` has no `infinity`;
  - everything else → `lists:foreach`.
  A value-less `break` is `erlang:throw('__bp_break')` and its loop is wrapped in
  the `try … catch throw:'__bp_break' -> ok end` that ends it (`loopBreakCatch`,
  `hasBareBreak`).
- **Module-level `val`s** (`topValForms`): erlang has no module-level storage, so a
  NAMED `val` is always a 0-arity function and a bare reference to it is the call
  `name()` (`top_vals`); a lambda-valued one applies what it answers,
  `(add())(10, 20)`. A comptime `val` keeps its `%% comptime val x` header and
  carries the folded expression as its body. Only the `_`-named synthetic
  statements (top-level expression statements) stay inside `'_botopink_main'/0`,
  where they keep their single, ordered evaluation. The trade-off is that a named
  `val`'s initialiser runs once per read.
- **Strings**: `+` over a `string` is binary concatenation, flattened into ONE
  construction — `a + b + c` → `<<"a", (b())/binary, C/binary>>` (`stringConcatNode`).
  `isStringExpr` decides: a string literal, a `+` chain with a string operand, a
  parameter declared `string` or a `val` bound to a string (`string_locals`), and a
  module-level `fn`/`val` that answers one (`string_names`, `collectStringNames`).
  Everything it cannot prove stays arithmetic. Binary-literal segments render as
  plain strings (`beam/erl_emitter.zig`), non-simple ones are parenthesised.
- **`@Result` constructors and patterns** share one tag table (`resultTag`):
  `Ok(v)` → `{ok, V}`, `Err(e)` / `new Error(msg)` → `{error, E}`, and the `Ok`/`Err`
  case arms match those tags. A user enum variant of the same name wins.
- **Static extension dispatch**: `implement`/`extend` methods are local functions
  keeping `self` as the first param (`keep_self`); activated `recv.m(args)`
  (`dispatch_rewrites`) and qualified `Sym.m(obj)` (`ext_names`) lower to
  `m(recv, args)`.
- **Externals**: `#[@External.Erlang("module", "symbol")]` fns emit no decl and
  calls lower to `module:symbol(Args)` (`externals`); `$`-marker / `when(…)`
  symbols render inline (`user_erlang_templates`); no `erlang` target →
  `MissingExternalTarget`. A template is the string literal's raw LEXEME and goes
  into the `.erl` verbatim, so `dupeTemplate` resolves `\"` to `"` first (an
  `io_lib:format(\"~p\", …)` template used to open an unterminated string).
  `builtinAnnotationNode` widens a fixed format string paired with the variadic
  `$args` marker to one control sequence per argument, so `@print(a, b, c)` is
  `io:format("~p ~p ~p~n", [A, B, C])` and not a `badarg`.
- **Cross-module**: an imported record joins `record_fields` + `imported_types`
  (`collectImportedTypes`), so construction inlines the owner's map shape
  (records are maps — there is no constructor function to call remotely) and
  `Response.ok(…)` calls into the owner module atom (`http:ok(…)`); the owner
  exports a `pub` type's associated fns when another module imports it, and a
  `pub implement`/`extend` another module activates (`import {PatoNada*} …`) is
  exported too and reached remotely (`pond:swim(Donald)`).
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
  `@print`, field access/assign, arrays, tuples, records/structs and anonymous
  `record { … }` / interface literals (all `put_map_assoc` maps keyed by field
  name), case (all patterns + guards via
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
  `undefined`, then `is_map` + `get_map_elements`), `comptime` nodes
  (`lowerComptime`: a folded expression/block is its value).
- **Module shape**: every *named* top-level `val` is a 0-arity function
  (reserved, emitted and — when `pub` — exported whether or not the module has a
  `main/0`), so a read is a local call; a `val` holding a fun is read, parked on
  the stack and applied with `call_fun`. Only `_`-named synthetic statements run
  in order inside `'_botopink_main'/0` before it calls `main/0`. Parity with the
  erlang backend's `topValForms`.
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
- **Closures** (`emitMakeFun`, `closureEnv`): a lambda or loop body's free
  variables — every name it reads that the enclosing frame binds — travel in
  `make_fun3`'s environment (`test_heap` with `{words, NumFree}`) and arrive
  as extra parameters after the fun's own, spilled to stack slots like params.
  `Live` honours the `min_live` floor; lambda bodies reset it to 0.
- **Mutation threading** (`lowerMutatingFold`): a statement `loop (xs) { x -> … }`
  or `xs.forEach({ x -> … })` whose body reassigns names of the enclosing frame
  (`=`, `+=`, `out.push(v)`, nested `if`/`loop`/`forEach`) lowers to
  `lists:foldl/3` with those names as the accumulator (one value, or a tuple),
  unpacked back into the caller's slots; `break`/`continue` return the group. A
  statement `out.push(v)` on a local Array stores the grown list back into its
  slot (`receiverMutation`).
- **Loops**: `loop (xs, 0..) { item, i -> … }` iterates
  `lists:enumerate(Start, Xs)` and binds both names from the pair with the
  `element/2` guard BIF; the comprehension shape (a single else-less `if` whose
  branch ends in `break v`) lowers through `lists:filtermap/2`; an eager
  `#[@iterator]` body ending in a yielding loop returns that loop's list.
- **Calls**: module-qualified `List.map(…)` → `call_ext`/`call_ext_last`
  (trailing lambdas materialized as funs); `from "std"` qualified calls
  (`math.floor(x)`) → `call_ext` via `collectStdImports`; interface
  associated `default fn`s emit as mangled locals `'Interface_method'`
  (`reserveInterfaceMethods`/`emitInterfaceAssoc`); a record-typed receiver
  (`c.atual()`, `.record` instance lowering) calls `'<Type>_<method>'` with the
  receiver first, or applies a fun-typed field (`s.set(v)`); a record method
  that reads `self` without declaring it takes it as an implicit first
  parameter (`hasImplicitSelf`); a destructuring parameter binds its names in
  the prologue; `Ok(v)`/`Err(e)`/`Error(msg)` build the `@Result` tuple.
- **Host-backed `declare fn`s** (`lowerExternalCall`; never emitted as local
  functions): an `@External.Beam` `.S` body renders at the call site; an
  `@External.Erlang("mod", "sym")` is a `call_ext`; an `@External.Erlang`
  template (`"base64:encode($0)"`, arity branches included) is Erlang source,
  evaluated at run time by the synthesised `'__bp_erl_eval'(Source, Bindings)`
  (`erl_scan` → `erl_parse` → `erl_eval`, markers bound as `__BpSelf`/`__BpAN`).
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
- **`erlc +from_asm` invariants**: comparisons use only `is_lt`/`is_ge` (no
  `is_gt`/`is_le` — operands swap, `comparisonTestOp`); `{allocate, N, A}` is
  followed by `{init_yregs, …}` (`emitFrame`); `countLocalsRec` counts every
  stack slot the lowering takes — `val`s, case-arm/destructure/binding-`if`
  bindings, array-literal and concatenation accumulators, the `try` tag, and
  `stagingSlots` — so the frame is sized correctly. Every decision the count
  mirrors (string-ness via `count_strings`, `exprMayCall`) is taken from the
  same AST and tables in both passes.
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
- **Cross-module**: the module atom is the path basename; an imported record
  joins `record_fields` + `imported_types` (`collectRecordShapes`), its
  associated fn lowers to `call_ext` into the owner (`http:'Response_ok'(…)`),
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
  when the condition is not `true`; `assert Pat = e catch h` is a two-arm case
  whose bindings stay visible. `@todo`/`@panic` → `erlang:error/1`; `__bp_*` ops
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
`snapshots/codegen/wasm/` is expected to pass `wasmtime compile`; a shape the
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
   an undeclared `$__mem0`.
2. **One value discipline** (`Tail` = `value` | `none` | `terminated`).
   `exprTail` is the single classifier; every arm of `lowerExpr` must agree with
   it. `emitStmt` normalises to what the context asked for (pushes a zero, or
   `drop`s). `ifIsStatementForm` is shared by `lowerIfExpr`, `exprTail` and
   `fnHasResult` so a two-void-arm `if` is emitted without `(result …)`, is not
   `drop`ped, and does not give its function a `(result …)` it never fills. The
   answer is then *carried*: `stackOf` tags each sequence, and
   `wat_ast.Builder.func` refuses a body that does not match the signature.
3. **No reference to a symbol the module does not define.** `registerSymbols`
   records every fn signature and global up front; an unresolved callee becomes
   an `;; unresolved call: f/N` stub and a bodyless `declare fn` is skipped
   entirely. A single dangling `call`/`global.get` rejects the whole module, so
   `renderModule` validates every `call` against the module's functions,
   imports and declared externs before writing anything. The runtime helpers go
   further: `Builder.helper` is the only way to name one and marks it for
   emission in the same act.
4. **Types are recovered and coerced, never assumed.** `wasmTypeOf` recovers a
   value type from the literal spelling, a local/param/global's declared type or
   a callee's registered result; `lowerCoerced` + `emitConvert` meet the type
   the context wants. `return`, the implicit fn tail and every `case` arm coerce
   to `cur_result`; `storeSlotExpr` picks `f32.store` vs `i32.store`.

- **Coverage**: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`,
  globals, case, pipeline (`a |> f` → `call $f`), range loops
  (`lowerRangeLoop`) and array loops (`lowerCollectionLoop`), `@print` via WASI
  `fd_write`, `_botopink_main`/`_start`.
- **Known gaps** (loadable, but not yet right):
  - lambdas as *values* lower to `i32.const 0 ;; lambda` (no table /
    `call_indirect`); a lambda passed to `map`/`filter`/`@Result` chaining is
    inlined instead (`inlineLambdaBody`), which is why those work;
  - `loop` over anything that is not a range or a known array blob emits
    `i32.const 0 ;; loop over unknown iterable` — `isArrayExpr` is deliberately
    narrow (array literal, or a name bound to one, via `arr_locals`/
    `arr_globals`), because walking the layout of a non-array would read its
    first word as an element count and trap;
  - a `loop` used as a *comprehension* (`yield`/`break <v>` accumulating into a
    new array) runs its body but always yields `0`;
  - `case` only discriminates numeric and `or`-of-numeric patterns; a variant
    pattern (`Circle(r) ->`) runs the first arm and leaves its payload binding
    unset;
  - an `f64` aggregate field round-trips at `f32` precision (4-byte slots), and
    is read back as a raw `i32.load` unless the field's declared type is known.
- **Non-constant top-level `val`s** (`emitGlobalVal` → `deferred_globals`): a
  wasm `(global …)` accepts only a constant initialiser, so an array/tuple/call
  initialiser declares a zeroed mutable global and is evaluated in
  `$__init_globals`, which the module's `(start …)` runs ahead of `_start`.
  These used to stay at the `(i32.const 0)` placeholder, so every read saw `0`.
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
- **`@print` picks a helper by operand type**: `$__print_str` writes the bytes
  of a length-prefixed string, `$__print_bool` writes `true`/`false`,
  `$__print_f64` writes an integer part plus up to 6 trimmed fraction digits,
  and `$__print_i32` formats digits into scratch memory. Each group is emitted
  exactly when something asked for it — `Builder.helper` hands out the symbol
  and sets the flag together. The helpers themselves are nodes in
  `wat/wat_prelude.zig`; the scratch layout they assume is documented there.
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
- `emitFnWat` is a pub single-fn hook (wat analogue of `commonJS.emitFnJs`). It
  renders *forms*, not a module: the caller concatenates them with the
  `wat_runtime` prelude, which is where `$__str_concat_rt`, `$__emit`,
  `$__compilerError` and `$__binding_ref` are defined. Those four are built with
  `Builder.externCall`, so a module that emits one records it in
  `Module.externs` rather than tripping the undefined-call check — see the KNOWN
  GAP note in `wat.zig`: nothing defines them in the whole-program path.

### runtime

- `executeJavaScript` (`node`), `executeErlang` (`erlc` + `erl`),
  `executeBeamAsm` (`erlc +from_asm` + `erl`, assembling sibling `.S` aux modules
  so cross-module runs link). `executeWat` is a stub that returns an empty RUN
  LOG (a runtime is spec 03 step 2). Captured text is stdout with stderr
  appended after a newline.
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
    RUN LOG: the partial stdout comes with a stack trace not worth pinning.
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
  empty string of a crash. Bump `HARNESS_VERSION` whenever the harness records
  something different for unchanged inputs, otherwise a warm cache hides the
  change. Toolchain versions are **not** part of the key — delete the cache dir
  after upgrading node/OTP. Nothing reaps it: `clean-tmp` only touches `tmp/`,
  and CI always runs cold (the directory is git-ignored).

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
