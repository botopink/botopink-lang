# compiler-core/src/codegen

> Path: `modules/compiler-core/src/codegen/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Per-target codegen backends. The public façade lives at `../codegen.zig`.

Top-level `test { … }` declarations (`DeclKind.@"test"`) are **skipped by every
backend** in normal `build`/`run` output — they are only collected and emitted
under `botopink test` (`Config.test_mode`): commonJS emits `__bp_test_N`
functions + a `__bp_tests` registry + `__bp_run_tests()` runner; erlang emits
`'__bp_test_N'/0` functions + a `'__bp_run_tests'/1` runner + `main/1` escript
entry. In test mode `assert` lowers to a recoverable per-test failure
(JS: throwing `__bp_assert`; Erlang: `erlang:error({bp_assert, Msg, Loc})`)
and `fn main/0` is not auto-invoked. WASM runner pending.

## Tree

```text
codegen/
├── AGENTS.md         ← you are here
├── docs.md           ← design notes: blind emitters, entry-point convention
├── examples.md       ← `.bp` → JS / Erlang side-by-side
├── config.zig        ← Config / TargetSource (commonJS|erlang|beam|wasm) / ComptimeRuntime / TypeDefLang
├── moduleOutput.zig  ← shared types: Module, ModuleOutput, GenerateResult
├── crossModule.zig   ← backend-agnostic cross-module link index (exports + imported set), shared by every emitter
├── commonJS.zig      ← CommonJS emitter (blind: iterates transformed AST)
├── erlang.zig        ← Erlang emitter (blind)
├── beam_asm.zig      ← BEAM Assembly `.S` emitter (broad coverage; a few cross-backend gaps remain — see row below)
├── wat.zig           ← WebAssembly Text `.wat` emitter (length-prefixed strings w/ `.len`/`.slice`; lambdas/array-loops/stdlib-Result methods are deferred gaps)
├── typescript.zig    ← TypeScript `.d.ts` typedef generator
├── runtime.zig       ← runtime helpers used when executing generated JS/Erlang in tests
├── snapshot.zig      ← snapshot helpers for codegen tests
├── tests.zig         ← barrel: aggregates tests/<feature>.zig for test_root.zig
└── tests/            ← codegen tests, split by feature
    ├── helpers.zig         ← shared harness (`assertJs`/`assertJsError`/`configs`/…)
    ├── values.zig       ← val/fn/call/operators/assign/self/comments
    ├── aggregates.zig   ← array/tuple/record
    ├── control_flow.zig ← case/loop/if/try/throw/catch
    ├── comptime.zig     ← comptime folding/specialization/validation
    ├── builtins.zig     ← builtin/stdlib/assert
    ├── dispatch.zig     ← extension dispatch (implement/interface/delegate)
    ├── features.zig     ← lambda/enum/destructure/star/import/range/pipeline/hooks
    └── wat.zig             ← WAT backend codegen
```

## Files

| File | Role |
|---|---|
| `config.zig` | `Config`, `TargetSource` (`commonJS` \| `erlang` \| `beam` \| `wasm`), `ComptimeRuntime`, `TypeDefLang` |
| `moduleOutput.zig` | `Module`, `ModuleOutput`, `GenerateResult` — shared between targets |
| `crossModule.zig` | Backend-agnostic **cross-module link index** built once over every module's transformed program (`build(outputs)`). `exports` maps a `pub` symbol → `{module, kind, is_class, fields}` (its emitting module path, decl kind, whether construction needs `new`/a map ctor, and a record's declared field order); a `pub fn` is indexed **including host-backed `#[@External.<targert>(...)]` declarations** (the owning module re-exports the host symbol under the fn name, so a consumer importing it `from "<lib>"` must `require` that owner like any other export); `imported` is the set of names some module imports. `ownerModuleAtom(name)`/`moduleBasename(path)` give the Erlang/BEAM module atom (`web/http` → `http`). commonJS, erlang, beam_asm, and wat all consume this one analysis (replaces the old commonJS-local `CrossModule`) |
| `commonJS.zig` | CommonJS emitter — iterates already-transformed AST. A `@Result` is `{ ok: V } \| { error: E }` (`"error" in _r` test); `__bp_ok`/`__bp_error` construct it for `return`/`throw` in `#[@result]` fns. `try`/`catch` lower to **`"error" in _r` pattern matching** (statement-level for propagation; see [`./docs.md`](docs.md)). Static extension dispatch (F6): `implement`/`extend` blocks emit as namespace objects (`const Sym = { m(self){…} }`, no prototype patching) and activated `obj.m(args)` lowers to `Sym.m(obj, args)` via the loc-keyed `dispatch_rewrites` map. Type-directed method renames arrive via the loc-keyed `js_method_renames` map (commonJS-only): a recorded site emits the native name (`s.contains` → `s.includes` on a `string`) in place of `jsBuiltinMethodName(callee)`. A rename to `length` on a no-arg call is special: `arr.len()`/`.size()`/`.length()` and `str.length()` are the native `.length` **property**, so it emits `recv.length` *without* call parens (`as_property` — inference records the `length` rename only for typed array/string receivers, so a `record` `length()` method is untouched). `@[external(node, "module", "symbol")]` fns (F1): the decl lowers to `const { symbol: name } = require("module");`; an external fn with no `node` target errors (`MissingExternalTarget`) when called. **F6 duplicate test names**: collecting `test_entries` warns to stderr (`warning: duplicate test name "x" in <mod>.bp:<line>`) when two `test "x"` blocks in a module share a name — both still run. **Cross-module linking**: the shared `crossModule.zig` index (built once in `codegenEmit`) resolves `from "<pkg>"`/multi-module imports to `require("./<path>.js")` of the file that actually emits each name (declaration-only names like decorators emit no `require`), marks imported records as classes so construction emits `new`, and emits `exports.X` only for `pub` types another module imports. **Lib namespace object**: when the import names the lib itself (`import {Lib} from "Lib"`) and that name has no emitted symbol of its own — a comptime template fn whose only runtime use is `Lib.member(...)` — `emitUse` also binds the lib's whole module object (`const Lib = require("./<pkg>/<mod>.js");`, or `Object.assign({}, …)` across the lib's modules) so `Lib.member(...)` resolves at runtime, parity with the destructured bare form. Generic — the core names no specific lib. A record's no-`self` associated fn (`Response.ok(…)`) emits as a `static` class method. **Half-open ranges** (`a..b`): JS has no range literal, so a range materializes a real array `Array.from({length: Math.max(0, b - a)}, (_, __i) => a + __i)` (parity with `lists:seq(a, b-1)`); an open-ended `a..` throws (a finite array can't be a lazy infinite range). **Interface associated fns** (`Pair.of`, `Array.range`) emit into a namespace object (`const Pair = {}; Pair.of = function…`), EXCEPT when the interface is a JS-global-backed primitive (`Array`/`String`/numeric tower/`Bool`, via `isJsGlobalNamespace(jsPrototypeOwner(name))`): there the fns are statics on the existing global (`Array.range = function…`) — a `const Array = {}` would shadow the global and leave the later `Array.prototype.*` instance-method patches setting properties on `undefined`. **Import dedup**: a binding name is lowered to at most one `const { … } = require(…)` per module (the `seen_imports` set) — several `@emit`s each importing the runtime fn they call (or any repeated import) would otherwise redeclare `const x` twice, a JS `SyntaxError` |
| `erlang.zig` | Erlang emitter — same shape as `commonJS.zig`. **`#[@External.<targert>(...)]` template form (`prim-op-annotation`):** `tryEmitPrimAnnotation` checks whether the parsed `@external(erlang, …)` symbol carries `$`-markers (`$self`, `$N`) via `comptime/primOpTemplate.zig`; if so it renders the template body verbatim (with substitutions) instead of the legacy `mod:sym(args)` shape. This lets a prim method be expressed as `($self ++ [$0])` / `lists:member($0, $self)` / `(not $self)` etc. without a switch arm. **Records are maps at runtime**: constructor calls lower to `#{field => V, …}` map literals (labeled args use the label, positional args the declared field order — `collectTypeShapes` registry), field access lowers to `maps:get(field, Recv)` (atom-quoted via `atomName`), tuple index `t._N` → `element(N+1, T)`; the invalid `-record(PascalCase, …)` decls are gone (comment only). Qualified enum members `Order.Lt` → the variant atom; payload constructors `Color.Rgb(r, g, b)` → tagged tuple `{'Rgb', R, G, B}` (matches case-arm patterns). **Optional chaining `?.`** guards on `undefined` via an immediate fun (`(fun(undefined) -> undefined; (R) -> maps:get(f, R) end)(Recv)`). Case arms lower list patterns (`[]`/`[X]`/`[First \| Rest]`) and constructor patterns (unit → atom, payload → `{tag, …}` tuple); module-qualified calls (`List.map(…)`) emit remote calls `list:map(…)` with the PascalCase receiver lowercased to a valid module atom — except a receiver naming a **local record** (`Response.ok(…)`) calls the bare local associated fn `ok(…)` (emitted in this module), not a remote `response:ok`. `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end`; propagation nests the body tail in the `{ok, V}` arm; an `if` whose then-branch ends in `return` nests the rest of the body in the false arm (`emitEarlyReturnIf` — Erlang has no early return); `__bp_ok`/`__bp_error` construct `{ok, V}`/`{error, E}` for `return`/`throw` in `#[@result]` fns. Static extension dispatch (F6): `implement`/`extend` methods emit as bare local functions keeping `self` as the explicit first param (`swim(Self) -> …`, `keep_self` flag); activated `recv.m(args)` (via `dispatch_rewrites`) and qualified `Sym.m(obj)` (receiver is an extension block name in `ext_names`) both lower to the local call `m(recv, args)` instead of a remote `recv:m/Sym:m` call. `@[external(erlang, "module", "symbol")]` fns (F1): the decl emits nothing (comment only, excluded from `-export`) and calls lower to the remote `module:symbol(Args)` (`externals` map); no `erlang` target → `MissingExternalTarget` when called. **Cross-module** (`crossModule.zig`): a record/struct imported `from "<pkg>"` joins `record_fields` (so construction inlines the owner-shaped `#{…}` map, positional args keyed by the owner's field order) + `imported_types` (`collectImportedTypes`); its associated fn (`Response.ok(…)`) lowers to a remote call into the owning module atom (`http:ok(…)`), never the lowercased type name (`response:ok`); the owner `-export`s a `pub` type's assoc fns when another module imports it. **Interface associated `default fn`s** (`Array.range`, `Pair.of`, `Function.compose`): `emitInterface` emits each no-`self` `default fn` body as a bare local function (`collectInterfaces` records `"Interface.method"` qnames), and an `Interface.method(...)` call resolves to that local fn (reserved-word-quoted via `fnAtom`, e.g. `'of'`) instead of a remote `array:range` — the interface decl is inlined into each consuming module. This is what makes `Array.range`/`repeat` (pure-botopink recursive `[head, ..tail]` builders) run on erlang. **Value-receiver instance methods** (`stdlib-backends-parity`): a record/enum/struct method keeps `self` as its first param (`isAssocMethod` gates `keep_self` in `emitRecord`/`emitEnum`/`emitStruct`), and a call `recv.m(args)` lowers via the loc-keyed `instance_lowerings` table (recorded by inference): a `.record` entry → the local `m(Recv, args)` (or `owner:m(Recv, args)` for an imported type), a `.prim` entry → the erlang host op (`emitPrimMethod`: `xs.map(f)`→`lists:map(F, Xs)`, plus `filter`/`forEach`/`reverse`/`append`(`++`)/`prepend`/`push`/`at`(bounds-safe `lists:nth`)/`slice`(`lists:sublist`)/`join`(`iolist_to_binary∘lists:join`, each element first rendered to text by a `lists:map` `is_binary`/`is_integer`→`integer_to_binary`/`io_lib:format` fun so `[10,20].join(",")` is `"10,20"`, not the raw byte iolist)/`indexOf`/`contains`(`lists:member`)/`len`; strings → `string:uppercase`/`lowercase`/`trim`/`length`/`slice`/`find`/`prefix`/`split`). `arr.length`/`s.length`/`.len` field access also lowers via `instance_lowerings` to `length(…)`/`string:length(…)` (not `maps:get(length, …)`). **`forEach` accumulator fusion** (`detectFoldFusion`/`emitFoldFusion`): `var acc = init;` immediately followed by `recv.forEach({ p -> <mutate acc> })` has no immutable-Erlang form (a closure can't rebind a captured var — it would `badmatch`), so the pair fuses into a single `Acc = lists:foldl(fun(P, Acc) -> <body> end, Init, Recv)` (the accumulator reuses its name as the fun's 2nd param so reads resolve). Recognized lambda bodies (`classifyFoldStmt`): `acc = e` (→ `e`), `acc += e` (→ `Acc + e`), `acc.push(x)` (→ `Acc ++ [x]`), and `if (c) { acc = t } [else { acc = e }]` (→ `case c of true -> t; _ -> e\|Acc end`); anything else falls back unfused. This powers the stdlib `fold`/`merge`/`mapValues`/`union`/`fromList` methods. **Locals tracking**: `locals` (per-function, reset in `emitFn`, fed by params/`val`/lambda params) lowers a no-receiver call to a fn-typed local as a fun application `F(args)`, not a bare `f(args)`. **Enum case patterns**: a bare `.ident` pattern emits the atom `'Lt'` when it names a known variant (`enum_variants`), else an erlang variable `X` — previously a variant pattern leaked as an unbound var matching anything. **Erlang stdlib suite** (`std_erlang.sh`): now fully green — `order` 3/3, `dict` 12/12, `queue` 7/7, `sets` 9/9 (the `forEach`-accumulator fusion + the `join` element-stringification closed the last blockers). **Remaining gaps**: structural `==`/`!=` is `=:=`/`=/=` (already deep on tuples/maps/lists), but `?T` option chaining through chained method results is still open (the v0.beta.19 §B / v0.beta.20 keystone generic-inference gaps closed in v0.beta.22 — see `tasks/v0.beta.22/specs/04-generic-inference-finalize.md`; chained `Array.map().filter()` substitution, generic-fn back-prop from a typed binding, and the structural-tuple unify arm are all covered by `comptime/tests/infer_generics.zig` regression guards) |
| `beam_asm.zig` | BEAM Assembly `.S` emitter. Full coverage: numerics, locals, calls, decl methods, booleans, assign, throw, strings, `@print`, field access/assign, arrays, tuples, **executable closures** (`emitMakeFun`: `{test_heap, {alloc, [{funs, 1}]}, Live}` + `make_fun3` with a `{x, 0}` dest — `make_fun2` is rejected by `+from_asm` on this OTP; `Live` honours a `min_live` floor so scratch x-registers live across the allocation survive), **fun application (`call_fun`)** for local-bound (`val f = {…}`) and `syntax fn` parameters, case (all patterns **+ `pat if guard` guards** via `emitGuardPre`/`emitGuardPost` — restore subject + fall through on guard failure), **`if`-as-value** (`emitValueIf` — value in `{x,0}`, falls through, no spurious branch `return`), **`if`-as-statement** (`emitIf` — a bare else-less `if` is a statement: the false branch FALLS THROUGH to the following statements, never `move undefined`+`return.`; emitting an early `return.` there would turn `if (n==0){return…}; return f(n-1)` — a mutual-recursion base-case guard — into unreachable dead code, the mutual-recursion regression), try/catch (`is_tagged_tuple` list form `[{x,0}, N, {atom,Tag}]` on `{ok,_}`/`{error,_}`, expr + stmt), ranges (half-open `a..b` → `lists:seq(A, B - 1)`; `lowerRange` floors its scratch base at 1 so `main/0` doesn't clobber `start`; the loop materializes the iterable *before* building the body closure so a `lists:seq` call doesn't clobber the stashed fun — `loop (0..n)` was crashing `lists:foreach([_],[_])`), pipeline, method calls, **module-qualified remote calls** (`List.map(…)` → `{call_ext, N, {extfunc, list, map, N}}` / `call_ext_last` in tail, with trailing lambdas materialized as fun arguments), **primitive-receiver instance methods** (`xs.map(f)`, `s.toUpper()` — the loc-keyed `instance_lowerings` map from inference tags the receiver's primitive family; `emitPrimMethod` lowers the directly-host-callable ones to `call_ext`: `lists:map/filter/foreach/reverse/member`, `erlang:length`, `string:length/uppercase/lowercase/trim/split` + 1-arg `slice`. Three register layouts — recv-only `fn(Recv)`, `fn(Fun,Recv)` for map/filter/foreach, `fn(Arg,Recv)` for `member`. The `fn(Fun,Recv)` layout `move {x,0},{x,1}`s the list into both registers so the closure's `make_fun3` (always writes `{x,0}`) lands the fun in `x0` while the list survives in `x1` — correct at any arity (`lowerPrimFunArg` raises `min_live` so the closure's `test_heap` keeps `x1`). The array-literal builder stashes its cons accumulator at `max(cur_arity,1)` so a 0-arity fn no longer aliases `x0` and conses `[Elem\|Elem]`. An unrecognised prim method — a `default fn` like `fold`/`all` (the following ARE lowered: `prepend`/`push`/`append` (`put_list`/`lists:append`) + `isEmpty` (`=:= []`) + `s.contains(needle)` / `s.startsWith(prefix)` (`call_ext binary:match/2` and `string:prefix/2` followed by a `=/= nomatch` boolean via `primCmpAgainstNomatch` — string-literal args land directly in `{x, 1}` via `emitStringLiteral`, sidestepping `simpleTerm`'s numeric-only support) + 2-arg `xs.slice(start, end)` (`primArraySlice2`: `gc_bif '+'` for `start+1` into `{x, 1}` then `gc_bif '-'` for `end-start` into `{x, 2}`, both honouring `min_live` to preserve the receiver/preceding scratch slots, then `call_ext lists:sublist/3` — both args must be `simpleTerm`-reducible (reg-resident ident or literal int), complex sub-exprs fall back to the local-call path) + `xs.join(sep)` / `xs.indexOf(item)` / `xs.at(i)` (`beam-inline-prim-methods` — F1 `primJoin` ships a per-element stringify closure via `ensureStringifyHelper` + `make_fun3`, then `lists:map` + `lists:join` + `iolist_to_binary`; F2 `primIndexOf` lazily emits a 3-arg synth helper `'-bp_indexOf-'/3` tail-recursing through `call_only` with the running index in `{x, 2}` and `-1` on the empty-list arm; F3 `primAt` emits the bounds-safe `'-bp_at-'/2` helper that spills `(L, I)` to y-slots so the `erlang:length/1` call survives, then `is_ge`/`is_lt` against length + `gc_bif '+'` for `I+1` + `call_ext_last lists:nth/2` on hit, `undefined` on miss — same `undefined` atom the erlang backend uses for `@Option` none)) — returns `false` and falls through to the value-receiver local-call path, parity with erlang's bare-`callee(Recv,…)` fallthrough), **interface associated `default fn`s** (`reserveInterfaceMethods`/`emitInterfaceAssoc` emit each no-`self` `default fn` as the mangled local `'Interface_method'`; an `Interface.method(...)` call resolves to it — `Array.range`/`repeat` build with `[head, ..tail]` spread, `head` bound to a `val` so it spills to a y-slot and survives the recursive call's x-register clobber). Three register-liveness fixes this required, all reused by other code: the array-literal `test_heap` counts only the x-registers an element actually reads (a y-slot `val` adds none — `cur_arity + 1` over-claimed the uninitialised scratch slot, `{x,k}, not_live`); `gc_bif` and `materializeCallArgs` honour `min_live` so a complex arg's arithmetic preserves the scratch slots holding already-materialised args (`repeat(value, times - 1)`); and `lowerLambda`/loop-lambda reset `min_live` to 0 for the closure's fresh frame (an outer stash floor would over-claim inside the closure), **optional chaining `?.`** (`recv?.member` — `lowerIdentAccess` guards on `{atom, undefined}` with `is_eq`: an `undefined` receiver short-circuits to `undefined`, otherwise `is_map`+`get_map_elements` reads the field and a non-map/missing-key also yields `undefined`; chains `a?.b?.c` compose through `{x, 0}`, parity with the erlang guarding fun), **record/struct constructors** (`AppError(code:, msg:)` → `put_map_assoc` building a `#{…}` map keyed by field-name atoms), **`@Result`/`@Option` methods** (`__bp_result_*`/`__bp_option_*` → `lowerResultOptionOp`: a `@Result` is the idiomatic OTP pair `{ok, V}\|{error, E}` and a `@Option` the bare payload or atom `undefined`, mirroring the Erlang backend; `__bp_ok`/`__bp_error` build the pair for `return`/`throw` inside `#[@result]` fns; `map`/`flatMap` apply the closure via `call_fun` and `map` rewraps with `put_tuple2`; `unwrapOr`/`isOk`/`isError` are tag tests — a bare-tail lambda body now returns its value via `emitLambdaBody`), loops, **static extension dispatch (F6)** (`implement`/`extend` methods reserved/emitted/exported as `'<target>_<method>'`; activated `recv.m(args)` via `dispatch_rewrites` → `call '<target>_m'(recv, args)` prepending the receiver; qualified `Sym.m(obj)` where `Sym` is an extension block → `call '<target>_m'(obj, args)` — see `ext_by_name`/`extMangledName`/`lowerExtCall`). **`erlc +from_asm`-correctness invariants** (validated by assembling + running the snapshots): comparisons use only `is_lt`/`is_ge` — BEAM has no `is_gt`/`is_le`, so `>`/`<=` swap operands (`comparisonTestOp`); atoms are quoted when not a valid unquoted atom (`atomName`/`isUnquotedAtom` — PascalCase enum tags `'Circle'`, `.dotIdent`, comptime-specialized `'execute_$0'`, component fns `'Widget'`); `{allocate, N, A}` is followed by `{init_yregs, …}` (`emitFrame`) so GC points never see uninitialised y-slots; `countLocalsRec` counts case-arm + destructure bindings so the frame is sized correctly. **Cross-module** (`crossModule.zig`): the module atom is the path **basename** (`web/http` → `http`; a slash is invalid in a module atom); a record/struct imported `from "<pkg>"` joins `record_fields`+`imported_types` (`collectRecordShapes`) so construction emits `put_map_assoc` (positional args keyed by the owner's field order) and its associated fn (`Response.ok(…)`) lowers to `call_ext` into the owner (`http:'Response_ok'(…)`) — a local record calls `'Type_method'` directly; the owner exports `'Type_method'/arity` when imported elsewhere; a field read after a cross-module call emits `is_map` before `get_map_elements` (the `call_ext` result is typed `any`, which the loader rejects). `runtime.executeBeamAsm` assembles sibling `.S` modules so a cross-module run links. **Remaining gaps**: `negation_in_expression` `gc_bif` Live count; and cross-backend cases (also broken on Erlang): non-std cross-module fn imports, `#[@future]` async/`await`, typed-value method dispatch (`p.parse()`). `from "std"` qualified calls (`math.floor(x)` etc.) now lower to `{call_ext, _, {extfunc, <mod>, <callee>, _}}` via `collectStdImports`. BEAM `lowerBuiltinCall` still hardcodes `@print` at the register level (the inline-`io:format`/heap-cons shape isn't a clean `$args` template lowering yet); commonJS and erlang both consume the shared `@external` template via `tryEmitBuiltinAnnotation`. **v0.beta.22 front 03 (`beam-target-template-output`)** added the BEAM-target template consumer (`prim_beam_templates` + `renderBeamTemplate`): an `#[@External.Beam("""<.S body>""")]` annotation on a primitive interface method registers the body, and `tryEmitPrimAnnotation` pre-loads `recv` → `{x, 0}` + each positional arg → `{x, i+1}` (args in reverse order, then `recv` last, with `min_live = argc + 1` keeping earlier loads alive) and renders via the shared `primOpTemplate.zig` walker — `$self` → `{x, 0}`, `$N` → `{x, N+1}`, `$args` → the comma-separated `{x, 1..N}` list. Five arms shipped: `String.toUpper`/`toLower`/`trim`, `Array.reverse` (0-arg, byte-equal vs the legacy bare-symbol path) + `String.endsWith` (1-arg — fixes the previous `unresolved` placeholder). The `emitPrimMethod` inline switch still owns arms needing labels (`isEmpty`), `gc_bif` arithmetic (2-arg `slice`), `make_fun3` helpers (`at`/`indexOf`/`join`) or `put_list`/`lists:append` register juggling (`prepend`/`push`/`append`); migrating those needs the template grammar to grow `$label`/`$gc_bif` markers (deferred — see §A6). Tail-position template calls emit `call_ext` + a trailing `{deallocate, N}.\n    return.\n` (via `emitReturn`) rather than `call_ext_last` — semantically equivalent but one extra instruction; arms used in tail position should stay on the inline `emitPrimMethod` path for byte-equality. |
| `wat.zig` | WebAssembly Text `.wat` emitter. Full coverage: numerics, locals, calls, assign, `!x`, null, `@todo`/`@panic`, globals, `_botopink_main`, case, pipeline (`a \|> f` → `call $f`), lambdas, loops (KNOWN GAP: `loop (…)` currently produces invalid wasm — stack-discipline bug in `lowerLoop`/`lowerRangeLoop`, affects both array and range iterables; recorded, not faked), `@print` via WASI `fd_write`. **Booleans** — `true`/`false` are bound as identifiers (bool builtins), not literals; the `.ident` path lowers them to `i32.const 1`/`0` (wasm has no bool type — same `i32` a comparison yields), NOT `global.get $true` (which referenced a never-defined global and failed to compile, blocking the whole module). **Entrypoint wrapper** (`emitEntrypointWrapper`) — `_botopink_main`/`_start` `(call $main)` and `drop`s the result when `main` returns a value (`main_returns_value`), or the value would be left on the stack at block end (invalid wasm). **Aggregates in linear memory** — tuples/arrays/records/enum payloads are contiguous 4-byte slots in the bump heap (a type registry built from `record`/`enum` decls distinguishes construction calls from function calls, since codegen is untyped); construction stashes the base in a `$__mem{n}` scratch local, destructuring and `t._N` access load by `offset`; enum payloads are `[tag, …fields]`. **Strings** — literal `+` → `$__str_concat` (`memory.copy`), literal `==`/`!=` → `$__str_eq` (byte loop). `try`/`catch` → `if` on the tag `i32` (payload at `offset=4`). **Static extension dispatch (F6)**: `implement`/`extend` methods emit as linear-memory functions `$<target>_<method>` keeping `self` as a real `i32` param (`emitExtensionMethods`); activated `recv.m(args)` (via `dispatch_rewrites`) and qualified `Sym.m(obj)` lower to `call $<target>_m` pushing the receiver (`lowerDispatchCall`). **Record member methods (`wat-refactor` F2)**: `record { … fn m(self) { … } }` and `record { … fn m(self) { … } }` emit alongside extensions as `$<owner>_<method>` (`emitInterfaceMethods`/`emitStructMethods`); a member fn whose body references `self` but lacks an explicit `self: Self` param gets an implicit `(param $self i32)` synthesised (`bodyReferencesSelf` scan) so the bare `self.field` reads through a real local instead of a `global.get $self` to a non-existent global. **Record field access by name (F2)**: `recv.field` walks a best-effort `local_types` map (let-binds to a record_ctor, params typed `Rec`, fn-return types, chained `recv.a.b` via `record_field_types`) plus `self_type` in method bodies; an unknown receiver stays at `i32.const 0` with a `;; (unknown receiver type)` comment. `recv.field = v` / `recv.field += v` store at the same offset (`+=` uses one `$__mem{n}` scratch for the load-add-store). **Optional chaining `?.` on records (F3)**: `recv?.field` lowers to `local.tee $__mem{k}` + `i32.eqz` + `(if (result i32) (then i32.const 0) (else local.get $__mem{k} i32.load offset=N))` — the null pointer convention from the `?T` carrier shape (none = `i32.const 0`, some = base pointer). Chains compose through fresh scratch slots. **`@Result`/`@Option` methods** (`__bp_result_*`/`__bp_option_*` → `lowerResultOptionOp`: a `@Result` is a pointer to `[tag, payload]` (tag `0` = Ok, like `try`/`catch`; `__bp_ok`/`__bp_error` allocate the pair for `return`/`throw` in `#[@result]` fns), a `@Option` the bare value with `0` = None; `map`/`flatMap` **inline the closure body** — there are no first-class funs here, so a literal lambda's param binds to a `$_res{n}` local and `map` rewraps via a fresh heap slot; `unwrapOr`/`isOk`/`isError` are tag loads/branches). **Cross-module**: KNOWN GAP — wasm stays single-module (no module-linking story yet). A `from "<pkg>"` import that resolves to a concrete emitted symbol in another module emits an explicit `;; cross-module import not linked (wasm single-module)` comment (`emitWat` consults `crossModule.zig`) rather than silently emitting a `call $sym` to a missing function; erlang/beam handle these via remote calls. `wasmtime` runner |
| `typescript.zig` | `.d.ts` typedef generator (optional secondary output). Extension dispatch (F6) needs no call-site rewrite here: `.d.ts` is type-only and `implement`/`extend` blocks are invisible to the binding list, so there are no method-call sites to lower. **`prim-op-annotation` out-of-scope**: emits type declarations only, no call lowering, so there are no callee-keyed `mem.eql` switches to migrate to annotation-driven templates |
| `runtime.zig` | Test-side runtime helpers (executes generated code). **Per-test scratch layout**: every `executeX` mints a dir under `<cwd>/.botopinkbuild/tmp/<hex>/` via `makeScratchDir` (single callsite, `TMP_ROOT = ".botopinkbuild/tmp"`) — the cwd is `modules/compiler-core/` under `zig build test`. The umbrella `.gitignore .botopinkbuild/` rule swallows the tree, and `build.zig`'s `clean-tmp` step (`find … -mtime +1 -exec rm -rf {} +`) reaps entries older than 1 day at the start of every `zig build test` cycle. A crashed test therefore never leaks past a day, and never as a `.tmp-exec-*/` sibling of the module root (`runtime_scratch.zig` pins the layout). **Two-level fast path** (cold-spawn budget is the dominant cost — each `erlc`/`erl`/`erlc +from_asm` is ~500–700ms cold on Linux): (1) **no-I/O early bail** — `executeErlang` returns `""` before any spawn when the generated code has no `io:format`/`io:put_chars`/`io:fwrite` (and the same for the BEAM `.S` extfunc references in `executeBeamAsm`), since a fixture without `@print` would produce an empty RUN LOG anyway; `executeErlang` also early-bails if the code carries no `_botopink_main` (library-style fixture). The check looks at the entry code AND every aux module — only one writer is enough to keep the spawn live. The cold-pass speedup is ~22% (the bulk of the codegen test suite passes through a no-print branch since most tests pin source/codegen text and not stdout). (2) **Output cache** (`CACHE_ROOT = ".botopinkbuild/runtime-cache"`): each `executeX` hashes its inputs (target tag + emitted code + aux modules + module name) into a 64-char hex SHA256 key (length-prefixed components — collision-free) and short-circuits the entire `node` / `erlc`+`erl` / `erlc +from_asm` / `wasm3` subprocess on a cache hit. Every cached entry is prefixed with `OK:` so a corrupt/truncated file is treated as a miss and re-executed. Content-keyed, so any change to the inputs (compiler output, std library) misses naturally; toolchain upgrades (node/erl) are NOT folded into the key — clear the cache dir after upgrading those. Reaped by `clean-tmp` together with `tmp/`. **Warm-run speedup**: the second `zig build test` after a clean cache currently lands at ~16s (vs ~3m20s on the original spawning-every-time path), a 12× wall-clock win — every `@print`-bearing fixture skips its erlc+erl pair on the rerun. **`prim-op-annotation` out-of-scope**: host-side glue (process spawning, file paths, aux-module aggregation), not a backend lowering — `mem.eql` hits are on module path / shell-arg strings, no callee dispatch to migrate |
| `snapshot.zig` | Codegen snapshot harness |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig`; harness in `tests/helpers.zig` (`assertJs`, `assertJsSingle`, `assertJsError`, `configs`) |

## Quick-reference rules

- Emitters are **blind** — they never inspect `ExprKind.comptime_`; the
  transform pass has already resolved everything. Full rationale in
  [`./docs.md`](docs.md).
- `fn main()` triggers an entry-point wrapper (`_botopink_main()` in JS;
  quoted `'_botopink_main'/0` atom in Erlang). The Erlang atom **must**
  be quoted because plain atoms can't start with `_`.
- Erlang module-qualified calls: a PascalCase receiver (`List`) is a module
  reference → emitted as a remote call `list:map(…)` (lowercased via
  `erlangModule`); a lowercase receiver is treated as a value method call and
  left as-is (`isModuleRef` distinguishes them). Arity is the argument count
  (args + trailing lambdas).
- BEAM ASM and WAT backends cover the language broadly and reuse the
  existing comptime runtimes (`erlang` for BEAM, `node` for WASM). `print`
  / `println` / `debug` lower through the shared `@external` template
  (`console.log($args)` on commonJS, `io:format("~p~n", [$args])` on
  erlang); BEAM keeps its register-level inline shape for now. BEAM ASM
  resolves `from "std"` qualified calls (`math.floor(3.7)` →
  `{call_ext, 1, {extfunc, math, floor, 1}}`) via `collectStdImports` —
  parity with the erlang backend. BEAM ASM still emits
  `%% unresolved`/`%% unsupported` comments for a few cross-backend /
  separate-feature cases (non-std cross-module imports, mutable closure
  capture across `lists:foreach`, `#[@future]` async/`await`, Fase 9
  polish) — see the `beam_asm.zig` row above and
  [`/TODO.md`](../../../../TODO.md).
- `commonJS.emitFnJs` is the one **pub** single-fn emission hook — the
  comptime template evaluator (`comptime/template_eval.zig`) uses it to run
  template bodies in node. `emitJsonString` copies validated escape PAIRS
  verbatim (re-escaping the backslash doubled source escapes — `"\n"` used
  to print a literal `\n`); only real control chars and unescaped quotes
  (multiline content) are escaped.
- Expr templates: template fns (`-> @Expr<…>`) are comptime-only — the
  transform pass substitutes every call site with its expansion
  (`env.templateExpansions`, loc-keyed) and drops the declarations, so
  emitters never see them (nor the `@expr`/`@code` construction builtins,
  which only occur inside template bodies). The typescript `.d.ts` emitter
  mirrors the drop via `TypeRef.isTemplateReturnType()` — any fn / method /
  interface-method whose return type is `@Expr<…>` or `@ExprCustom<…>` is
  skipped (the runtime-untargetable surface stays out of the `.d.ts`).
- Decorators (annotation processors): a decorator fn (first param
  `comptime _: @Decl`) is comptime-only too — the transform pass drops it next
  to the template-fn drop, so emitters never see its body's comptime builtins
  (`@emit` → `__emit`, `@compilerError` → `__compilerError`, the `decl.*`
  reflection / `__decl`). Those builtins only run inside a decorator body in the
  `decorator_eval` node runtime; the decls a body contributed via `@emit` are
  already spliced into the module and ARE emitted as ordinary declarations.
- `use` hooks (F8): `use` is a transparent prefix; `val`/`var` does the binding.
  CommonJS maps hooks to React (`state`→`useState`, `memo`→`useMemo`, …) via the
  `use`+Capitalize convention (`writeHookName`); `memo`/`effect`/`callback` get an
  inferred dependency array — the reactive names (bound by earlier hooks, tracked
  in `Emitter.hook_state`) the lambda reads, via `identInExpr`. Erlang/BEAM/WAT
  lower `use` transparently (the call result lands in a binding/slot). Phantom
  `@Context` base structs (`isPhantomContextStruct`: implements `@Context`, no
  members) emit no runtime code; the `.d.ts` erases `@Context<B, R>` to `R`. A
  record that *does* carry fields (incl. `record implement … { fields }`) emits a
  real constructor assigning each field, exactly like `record` (`emitStruct` —
  field initializers become param defaults); the standalone
  `implement <Iface> for <Type>` form accepts a generic interface
  (`Iface<A, B>`, `@Context<…>`), and `StructField`/`ImplementDecl.interfaces`
  both carry full `TypeRef`s so suffixed field types (`E[]`) and generic
  interfaces parse.
- a function-typed record field (`set: fn(next: T)`) needs no special
  handling — it is stored like any field (the closure lands in
  the constructor: `new State(0, (n) => {})`). The `Children` coercion is purely
  type-level (the argument value passes through unchanged). `typescript.zig`
  renders an anonymous `TypeRef.record_type` as a `{ f: T; … }` object type.

## §A6 — annotation-driven-builtins tail closure

`§A1`–`§A5` migrated the bulk of primitive-method lowering to consult
`#\[@External\.target(…)]` annotations in `libs/std/src/primitives.d.bp`
instead of `mem.eql(callee, "…")` switches; `prim-op-annotation` (the
`primOpTemplate.zig` shared renderer) added `$self`/`$0..$N` substitution
markers, `when(argc == N)` arity branching, `"""…"""` raw templates, and
`$stringify($self)` / `$stringify($N)` text-of-value coercion (erlang:
`iolist_to_binary(io_lib:format("~p", [...]))`, node: `JSON.stringify(...)`;
beam/wat unsupported in this wave), which absorbed 9 erlang Family-1 arms
+ the commonJS `@todo`/`@panic` dispatch. v0.beta.22 front 03
(`beam-target-template-output`) extends the renderer to **BEAM**: a
`#[@External.Beam("""<.S body>""")]` annotation registers in
`prim_beam_templates`, and `tryEmitPrimAnnotation` pre-loads `recv` →
`{x, 0}` + each positional arg → `{x, i+1}` (args in reverse order, then
`recv` last, with `min_live = argc + 1` floored so earlier loads
survive) and renders the body via the shared walker — `$self` → `{x, 0}`,
`$N` → `{x, N+1}`, `$args` → the comma-separated `{x, 1..N}` list. Five
arms shipped with templates: `String.toUpper` / `toLower` / `trim`,
`Array.reverse` (all 0-arg, byte-equal vs the legacy `("mod", "sym")`
bare-symbol path) and `String.endsWith` (1-arg — fixes the previous
`%% prim method not lowered on beam (complex arg)` placeholder). The
residual hardcoded arms remain **irreducible** until the template
grammar grows label/`gc_bif` markers:

- **BEAM ASM** (`beam_asm.zig` `emitPrimMethod`): array `prepend`/`push`/
  `append` (`put_list` + `lists:append`-with-`{x,_}`-juggling),
  `isEmpty` (`is_eq` + label branch), 2-arg `xs.slice` (`gc_bif '+'` /
  `gc_bif '-'`), `xs.at` / `xs.indexOf` / `xs.join` (synth helper fns
  via `ensureAtHelper` / `ensureIndexOfHelper` / `ensureStringifyHelper`
  + `make_fun3`), string `contains` / `startsWith` (`call_ext`
  + `=/= nomatch` boolean via labels), 1-arg `string:slice` (recv-then-
  simpleTerm pattern that string-literal args can't satisfy). These
  emit register stashes / label allocation / inline funs the current
  template DSL can't substitute (`$self` / `$N` / `$args` only — no
  `$label` allocator, no `$gc_bif`, no `$make_fun3` helper). A future
  grammar extension would unlock them; today they keep using the inline
  `emitPrimMethod` switch.
- **erlang** (`erlang.zig` `emitPrimMethod`): the `len`/`length`/`size`
  arm dispatching to the `length/1` BIF — this is field-access (`arr.length`
  is a `val length: i32` intrinsic) lowering through the method-call path,
  not a primitive method declaration. A clean migration would require
  annotation support on `val` declarations.
- **commonJS** (`commonJS.zig`): the `length-as-property` special case is
  not a switch arm but an emit-form decision (JS `.length` is a property,
  not a call) gated by inference's per-loc renames map. No annotation
  shape captures the property-vs-call distinction.
- **wat** (`wat.zig`): the `.len` arm reads the string-length prefix from
  linear memory — a wasm-untyped emit-form decision tied to wasm's
  prefix-length string layout, not a method dispatch.
- **erlang accumulator-pattern recognizer** (`erlang.zig:90`,
  `singleAssignValue`): a static analyser that detects the `acc.push(x)`
  shape inside a loop body to fuse into a `lists:foldl` — pattern-based
  optimisation, not method dispatch; the `callee == "push"` check is the
  pattern matcher's discriminator, not a codegen arm.

**§A6 acceptance** (spec): "snapshot diff is empty against `feat` HEAD
before this section" — satisfied (no codegen behaviour changed). The
irreducible allow-list above is recorded so a future `prim-op-annotation`
extension (BEAM bytecode templates, `val`-annotation support) has a clear
target list.

**§A7** (the byte-identical-add-via-annotation gate using a new prim
method like `Array.zip`) is **unblocked on BEAM** by v0.beta.22 front 03
(`prim_beam_templates` + the renderer above) but `Array.zip` itself is
still scoped to a follow-up — its template body is a structural BEAM
sequence (`lists:zipwith` over `lists:sublist`'d prefixes) that needs
hand-crafting once an author picks it up. The 3-of-4 gate (commonJS +
erlang + BEAM; wat excluded per the §A6 footnote on `wat.zig`) is the
shipping target.

## Effects (`#[@<effect>]`)

The full effect-annotation contract — what each marker (`#[@result]` /
`#[@future]` / `#[@generator]` / `#[@iterator]` / `#[@asyncGenerator]` /
`#[@context]`) requires, permits, forbids, and lowers to — is
[`tasks/v0.beta.19/specs/frente-b-rules-tooling.md`](../../../../tasks/v0.beta.19/specs/frente-b-rules-tooling.md).
The rules track is the authoritative ruleset; this row is the per-backend
lowering surface.

| Effect | commonJS | erlang | beam_asm | wat |
|---|---|---|---|---|
| `#[@result]` | plain `function`; `__bp_ok` / `__bp_error` build `{ok: V}` / `{error: E}`; `try`/`catch` lower via `"error" in _r` pattern matching | plain `fun`; `__bp_ok`/`__bp_error` build `{ok, V}` / `{error, E}`; `try`/`catch` → `case … of {ok, V} -> …; {error, E} -> … end` | plain mangled local; `lowerResultOptionOp` builds `{ok, V}` / `{error, E}` via `put_tuple2`; `try`/`catch` → `is_tagged_tuple` | linear-memory `[tag, payload]` (tag 0 = Ok); `__bp_ok`/`__bp_error` allocate the pair; `try`/`catch` → `if` on the tag |
| `#[@future]` | `async function`; bare `return <t>;` becomes a resolved Promise, bare `throw <e>;` becomes a rejection — both JS-native; the spec's `@Future.resolved`/`@Future.rejected` AST forms are rejected by RF1/RF2/RF5 before reaching codegen | gated on Frente A §D-D4 (spawn body as process, `await` joins) | gated on Frente A §D-D4 | out of scope (no Promise analog) |
| `#[@generator]` | `function*` | gated on Frente A §D-D4 / §B-B4 | gated on §D-D4 | out of scope |
| `#[@iterator]` | `function*` adapter (yield → `{value, done: false}`, `break <C>` → `{value: <C>, done: true}` once F4I lands) | extends primitive-iterator machinery with `{yield, T}` / `{iter_error, E}` / `{iter_done, C}` once F4I lands | gated | out of scope |
| `#[@asyncGenerator]` | `async function*` (same shape as iterator, suspended on `await`) | gated on §D-D4 | gated | out of scope |
| `#[@context]` | scope-stack array; push on `use`-block entry, pop on exit; `@getContex` is a `findFrame(T)` walk (gated on F4C) | process-dictionary scope (gated on F4C) | gated on F4C | out of scope (no tree-walking model) |

Rejection diagnostics — R1–R17 + RF1–RF5 + RI1–RI6 + RC1–RC6 + RG1–RG4 —
all carry stable codes from `comptime/diagnostics.zig`. The `effect`
field on `comptime/env.zig`'s `StarFnCtx` lets `inEffectContext(env, ...)`
in `comptime/infer.zig` distinguish a `#[@future]` body from
`#[@iterator]` / `#[@asyncGenerator]` / `#[@generator]` so each family's
rejections fire only inside the right context.

For the `.bp` → target translation gallery see
[`./examples.md`](examples.md); for the full API surface and snapshot
format see [`./docs.md`](docs.md).
