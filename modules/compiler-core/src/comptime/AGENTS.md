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
├── eval.zig           ← comptime val folding (literals, arithmetic, @TypeOf)
├── render.zig         ← source-line helpers for diagnostic rendering
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()`
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── alias_erase.zig    ← type aliases erased for the backends (reflective `TypeRef` walk; a return alias of a wrapper stays)
├── template.zig       ← `@Expr` templates: CapturedExpr, PlainArg, ScopeSnapshot, CustomNode, fail diagnostics
├── template_eval.zig  ← runtime-backed template body evaluation (through runtime/runtime.zig's dispatcher)
├── decorator_eval.zig ← runtime-backed decorator body invocation (erl; the same refusal)
├── primOpTemplate.zig ← shared `#[@External.<Target>("…")]` template renderer (receiver marker / $N / $args / $stringify)
├── snapshot.zig       ← comptime snapshot helpers
├── trace.zig          ← decorator/template runtime exchanges shown in snapshots
├── tests.zig          ← barrel: aggregates tests/<feature>.zig
├── tests/             ← comptime tests, split by feature — see tests/AGENTS.md
├── stdlib/            ← std prelude embedding — see stdlib/AGENTS.md
└── runtime/           ← the two comptime runtimes (BEAM, wat) + the dispatcher + the resident prelude — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.contextBase`, `FnContext`, `TemplateEvalCtx` (`{ io, build_root }`), `comptimeOwners` (C-01 — a template's or body-carrying decorator's declaring module path, keyed by the declaration's body address; `noteComptimeOwner` / `comptimeOwnerOf`, read when the evaluator names its module atom), the `@src()` state (`srcPath` — the package-relative file `Module.srcPath` or `<name>.bp`; `currentFnName` — fn / `Type.method` / test name, set by `inferFnDecl`, `inferTypeMethods`, `inferTestDecl`; `srcRewrites` — call loc → the `SourceLocation(…)` constructor call the transform splices; `usesSourceLocation` — the program named the prelude record, so `comptime.zig` prepends its declaration; `usesYieldStep` — the same for the prelude enum `YieldStep<T>` (decision 122); `testIndex` — the `test_<idx>` fallback counter), static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`), the `"std"` package tables (`stdModules`: module → fn exports; `stdModuleTypes`: module → pub type decls, registered into the importer by `markStdImports`; `stdModuleFns`: module → fn decls, used by `markStdImports` to reject a `from "std"` import whose `declare fn`s have no `@external` for `Env.target` (`std-unsupported-on-target`); `stdImports`: the local name of each std MODULE imported as a namespace → its path inside std (`dict` → `dict`; `import {io.fs}` → `fs` → `io/fs`), which wins over same-named value bindings like the primitive `bool` — a symbol leaf such as `import {io.fs.readText}` is an ordinary value binding instead; `importBound`: every local name this module's imports bind → the item, for `import-name-collision`), the `decorators` table (name → `DecoratorSig{ params, fn_decl }`), and the loc-keyed lowering maps `method_lowerings` (`@Result`/`@Option` methods + the builtin `result` namespace), `result_jump_lowerings` (`return`/`throw`/`yield`/`break` → `__bp_ok`/`__bp_error` in bodies whose return carries a `@Result` layer), `jsMethodRenames` (type-directed JS-only renames, e.g. `string.contains` → `includes`, recorded only when the receiver's static type makes a global rename unsafe — `Set` also declares `contains`), and `instanceLowerings` (see `infer.zig`). **C-02 (decision 63, amended)** — `indexRewrites` (index loc → the untyped expression the index IS: `xs.at(k)`, `xs.slice(a, b)`, or a tuple's positional `t._0`), kept as its own channel beside `enumSectionRewrites` for the reason `srcRewrites` is kept beside `templateExpansions`: one channel, one meaning. **C-04 (01 step 7)** — the three tables that carry a parameter's declared `default` past registration, since a `T.func` drops it: `fnParams` (top-level `fn` name → params as written, the mirror of `stdlibFnDecls` for the program's own fns), `inherentMethodParams` (`"<Type>.<method>"` → params as written, `self` included; `set`/`getInherentMethodParams`), and `defaultInjections` (call loc → `DefaultFill`, written by inference the moment it ACCEPTS a call that omitted an argument, read by `transform.zig`). `planDefaultFill` is the one rule both sides obey: a labelled argument claims the parameter it names, the rest take the free slots in declaration order, and a slot left empty with no `default` is `error.CannotFill` — N2's arity error, unchanged. `memoryVars` (front 17 — each module `var` → its `ast.Memory` and bound type, read by `infer.zig`'s `refuseMemoryWrite`); `valNames` / `bindVal` / `isVal` (decision 38): `bindVal` binds a `val` — local or module-level — and marks the name; `bind` (a `var`, a parameter, a pattern) clears it, and `infer.zig` refuses an assignment to a marked name. |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. `ExprTypeLog` / `expr_type_log` — a tooling hook, null by default: when installed (through `comptime.setExprTypeLog`), `inferExprTyped` records every expression's type under `env.srcPath` and its location (the outer node wins a shared location); `botopink migrate effects` reads it to tell a fallible `@Future<U, E>` from an infallible one; thread-local. `effect_migration_files` — the checker's half of the codemod's migration-only mode (decisions-pending 24-d; null everywhere else, set only through `comptime.setEffectMigration`): in a listed file (`env.srcPath`) `await` of a `@Task<@Result<U, E>>` answers `U`, a `for` / `for await` over an `@Iterator` / `@Stream` of `@Result<T, E>` binds `T`, `throw` / `try` are not refused for want of a `@Result` layer, and the pre-122 `YieldStep<T, E>` is read as `YieldStep<T>` (not refused by RG5's `generic-arg-count-exceeded`; its `Yield(v)` binds `T`), with `.next()` on an `@Iterator` / `@Stream` of `@Result<T, E>` answering `YieldStep<T>` to match — the pre-front-24 meaning (`legacyEffects`, `legacyPropagated`). `registerExtensions` + `resolveReceiverCall` implement static extension dispatch. `registerFnSignatures` (via `buildFnSignatureType`) binds every top-level `fn` signature before any body is inferred, so mutually-recursive / forward-referenced fns resolve. Ends with `validateProgram` — `implement`/interface coverage + getter/setter checks. Top-level `test { … }` bodies type-check like void fn bodies via `inferTestDecl`; `assert cond` unifies `cond` with `bool`. **`@src()`** (1.0.10-beta decision 73): `inferSrcBuiltin` — intercepted in `inferCallExpr` before the arguments are inferred — refuses any argument or trailing lambda (`src-takes-no-arguments`, at the `@`), builds the untyped `SourceLocation(file: env.srcPath, line: L, column: C, fnName: env.currentFnName)` call with four literals, records it in `env.srcRewrites` and infers **it**, so the typed AST carries the record type; a hand-written `SourceLocation(…)` call or annotation sets `env.usesSourceLocation` too. **C-02 (decision 63, amended 2026-09-19) — an index IS a method call**: `inferIndexExpr`, intercepted in `inferCallExpr` before the arguments are inferred, types `xs[k]` as `xs.at(k)`, `xs[a..b]` as `xs.slice(a, b)` and `xs[1..]` as `xs.slice(1, null)` — the index expression has no typing rule of its own and the type is whatever the method answers (`?V` for `Index<K, V>.at`), which is what makes a library's own `Matrix` indexable with **no compiler change**. The untyped call is recorded in `env.indexRewrites` under the INDEX NODE'S OWN loc and then inferred, so every loc-keyed plan the method call produces (its lowering, C-04's fill) is found again by the node `transform.zig` splices. The receiver is typed once here, because only its type tells a tuple from everything else: `inferTupleIndexExpr` is the checker's one special case — a tuple needs a CONSTANT index and answers a type PER POSITION, which `at(key: K) -> ?V` cannot say with one `V` — and it rewrites to the positional member access every backend already emits (`t[0]` → `t._0`), refusing a computed index and a position the type has not got, each located. `inferBuiltinCallReturnType`'s fallback is no longer a silent `void`: a name outside `runtime_builtin_names` (`print`/`println`/`debug`/`panic`/`todo`/`trap`/`compilerError`/`module`/`emit`/`is`), the parser's `[]` index sugar and `env.stdlibFnDecls` is `unknown-builtin`, located at the `@`, suggesting the nearest known name when one is an edit away (`editDistanceIsOne`). A bare `return;` inside a `-> @Result` body records `.wrap_ok` too (decision 74 — `-> @Result<void, E>`). `inferTypeMethods` walks record/enum method bodies (generics, `Self`, params) to type the calls and record their lowerings; it is **strict** (06 C9 — it used to swallow `error.TypeError` into `lastError = null`, so a real mismatch inside a method only failed at run time), and it stores the signature of a method that annotates NO return type, taking the return from its body's `return`s (`registerInherentMethodTypes` stores one only for an annotated method). It runs from the TYPED `inferDeclTyped` only — the untyped `inferDecl` never walks method bodies, which is why a method-body row asserts through `assertComptimeCompileError`, not `assertTypeErrorSnap`. A method call on a receiver whose type is a nominal `Env.lookupTypeDef` knows, that no inherent method, behavior member, fn-typed field or primitive dispatch answers, is `unknownMethod` — or `methodNotActive` when a non-activated `implement` block declares it (`typeAnswersMember` / `behaviorDeclaresMember` are what keep an adopted `default fn` and a `#(value, set)`-shaped fn field legal). Everything else stays the permissive fresh var: an unresolved type variable, and a named type the env cannot open (an imported record, a wrapper, a forward reference). Value-receiver instance calls are recorded in `env.instanceLowerings`: `.record <typeName>` or `.prim <PrimKind>` (array/string/bool/int/float — non-JS backends map it to a host op), and `.sequence_next <SequenceKind>` for a `.next()` by hand on an `@Iterator` / `@Stream` (decision 122 — the one entry commonJS ignoreads too). A **field read** on a record or struct records `.field_of <typeName>` at the access's loc (13-module-identity half 3): under decision 21 erlang and beam store a record as `{TypeAtom, F1, …}`, and the field's name does not carry its index — the backends turn the name into `element(N + 1, V)` with it, and fall back to a run-time lookup when nothing recorded the receiver's type. `primMethodReturnTypeFromIface` derives a primitive method's return type from its interface signature so chains (`xs.filter(f).at(0)` → `?T`) keep tracking; `length`/`len`/`size` read the interface field. `primMethodParamTypes` is its mirror on the argument side and is read **before** the call's arguments are inferred: a lambda argument over a builtin-primitive receiver is typed from the method's declared signature (`filter(self, pred: fn(item: T) -> bool)`) instead of fresh vars, so `xs.filter({ e -> e.name.contains("x") })` resolves `e` and the `contains` → `includes` JS rename fires inside the lambda — it used to emit `.contains(…)` verbatim and die at run time. Only the PARAMETERS are pushed down (`inferFunctionExprExpected`'s `params_only`): the declared return is not a constraint the lambda must meet, because `Array.forEach`'s `action` is declared `-> void` and a body whose every path `return`s types its tail as void while the `return`s have already fixed the return target. **C-04 (01 step 7)** — a call may omit an argument whose parameter declares a `default` (N1), and a call missing a REQUIRED one is still the arity error it was (N2). Three call paths judge it, each by planning the fill with `recordDefaultFill` → `env.planDefaultFill` and recording it under the call's loc for `transform.zig`: the free-fn / record- and enum-ctor path (`calleeParams` reads `env.fnParams`, `env.ctorParams`, `env.stdlibFnDecls`; a comptime / `@Expr` / template callee is excluded, its machinery being driven by the argument INDEX), the interface `default fn` on a primitive receiver (`"x".slice(1)` — `im.params[1..]` carries the default), and the instance method (`makeMethodCall` — inference never arity-checked this shape, so what was missing there was only the fill: `b.bump()` used to reach node as `bump()` and answer `NaN`). `unifyFilledArgs` unifies each argument with the parameter it LANDED in, not the one at its position — `P(y: 2)` against `type P(x: i32 = 0, y: i32)` puts its one argument in the second slot. Not reached, deliberately: a call carrying a `..` spread, a pipeline RHS, an interface ASSOCIATED fn (`Pair.of`, whose `T.func` is all the site has), a `"std"`-package qualified call, and an imported fn (`env.fnParams` is this module's). Generic-inference regression guards live in `tests/infer_generics.zig`. A generic enum's unit variant (`Option.None`) carries one fresh var per generic param (C7). `lhs |> f` with `f` a function value types as `f(lhs)`; a pipeline whose RHS arity does not take the piped value is an `arityMismatch` at the RHS (C12). **Tuple labels** (decision 8 §6, 06 N24) live on the `named` type node (`Type.named.labels`), so `instantiateType` carries them — a generic signature (`fn ref<T>() -> #(current: T)`) used to lose them and `r.current` red "this tuple has no element labeled". `row.pop` records a positional rewrite (`row._1`) under `env.enumSectionRewrites`; `inferTupleLabelCall` does the same for a labelled element of FUNCTION type CALLED like a method (`#(value, set: fn(…))`, `c.set(9)` → `c._1(9)`), which the member-access path never saw, and the backends lower `._N(…)` as an index/`element/2`/`call_fun` apply. A constructor call with a `..` spread is a record update: the spread unifies with the record, each labelled arg with the field it names, an unknown label reds at the label (C11). `@RecordKeys(T)` is `array<string>` and `@field(v, "x")` has the field's type (C6). `&&` / `||` / `!` unify TARGET-first and locate at the OPERAND (06 C3): they passed the operand as `unifyAt`'s `a`, so `1 && true` read "expected i32, got bool" with the caret on the whole expression. `-` and `*`/`/`/`%`/`-` constrain their operands to a numeric type (`requireNumericOperand`, permissive for an unresolved type variable and for any name it does not know to be non-numeric): `"a" * "b"` and `-"s"` used to check, since unifying two strings with each other succeeds and `-` constrained nothing. `+` keeps its string concatenation. The branches of an `if` unify only when BOTH end in something that has a value (`stmtsYieldValue`): decision 2 makes a block not-a-value, and unifying a branch that ends in an assignment or a `val`/`var` reds `if (p) { out = …; } else { taking = false; }` with "expected array, got bool" — a shape a library in this repository writes in a `takeWhile`, and the same in a plain fn. Deleting the unification outright waits for the row that removes block-as-value. **Decision 105 (front 22)** — the three loops are statements typed `void` (`inferLoopExpr`): a `while` condition unifies with `bool`; a `for` binds its one name to the ITEM (an array's element, `i32` for a range, an iterator's `T` — `@Iterator<T>` in any body, a `@Result` item handed over as is (decision 122), a `@Stream<T>` only through `for await` (`for-over-stream` / `for-await-expects-stream`)); `for` over a `bool` is `for-over-condition`. `iter loop { … }` / `stream loop { … }` (`inferGeneratorLoop`, decision 125 — `iter while` / `iter for` reach it as the prefixed `loop`) is an expression worth `@Iterator<T>` / `@Stream<T>` (`T` fresh; `@Result<U, E>` when the body has `throw` / `try` of its own, `ast.bodyFails`) and its body is a **closed generator scope**: `starFn`/`fnEffect`/`throwContext`/`useAnchor`/`aliasWrapper`/`returnWhole` replaced for the body, the outer labels moved to `env.closedLabels` (a `break :outer` naming one is `generator-loop-closed-scope`), `loopDepth` restarted at 1, `generatorLoopDepth` counted (a `use` inside is `generator-loop-closed-scope`, behind the parser's static-prefix refusal). The old bool-promotion channel (`env.conditionLoops`) is gone — the parser decides the form. An unresolved enum-section path points its caret at the first segment that does not resolve (N17). **Decision 38 — a `val` is immutable**, local or module-level: `refuseValAssign` (at the assignment's `.name` target) reds `` `x` is a `val` and cannot be assigned `` with a hint naming `var x = …`; it used to check and then throw on node (`const`), not compile on erlang and not validate on wasm. **Front 17 step 3** — `validateMemoryAnnotations` checks every `#[@BeamMemory.<member>]` on a module binding: the binding is a `var`; the member is `ProcessDict`, `Ets` or `PersistentTerm`; every argument is `keyed` with `true`/`false`; and `keyed = true` needs a `Dict` (decision 51 — an `i32` or a list has no key). **Front 17 step 4** — the same function refuses an `Ets` initialiser that is not a literal or `comptime` expression (`ast.isMemorySeed` — a missing table is re-seeded from it, design §5(d); not purity), refuses `keyed = true` when `Env.target` is erlang or beam (no row-per-key lowering yet), and records every module `var` in `Env.memoryVars`; `refuseMemoryWrite` (beside `refuseValAssign`, at the same assignment) refuses a write to a `PersistentTerm` var (written once, at load — §5(a)) and, under `Ets`, a write that recomputes the value from its own (`ast.classifyMemoryWrite` → `.recompose`, §5(b); a `Dict` exempt, decision 42) or an increment of a non-integer (decision 40). The binding is the module's only while `lookup(name)` answers the type it was recorded with, so a local that shadows it is not refused. Every target: the annotation's contract does not depend on where it runs. **Declaration names (C-19)** — `buildRecordDeclName`, `buildEnumDeclName` and `buildInterfaceDeclName` name a `type`/`behavior` declaration's binding in the 1.0.3 surface, sharing `appendGenericParamsStr`: `type Name<G>(f: T, …)` (fields inline, body omitted), `type Name<G> { V, V(f: T) }` (compact, as the formatter prints it) and `behavior Name<G> {\n    val x: T;\n    fn m<G>(params) -> R;\n}` (a method keeps its generics and return type). The name is the binding's type, not the instances' (those are `named` by the declared name alone), so the LSP prints it verbatim as completion `detail`; `record { … }` / `enum { … }` / `interface { … }` were the pre-1.0.3 spellings and no longer parse. Pinned by `snapshots/lsp/completion_{decorator_record,type_enum_detail,behavior_detail}`. `buildStructDeclName` (the legacy `StructDecl`) still spells `struct { … }` — 01's R1 row. |
| `unify.zig` | Unification with substitution + occurs check (a failing `unify` copies the `got` side's `Env.resultOrigins` entry onto its `typeMismatch` — E3.9, below). `unify(env, a, b)` is **target-first**: `a` is what the context expects and `b` what was written, which is what makes its two one-way rules sound — an expected `?T` accepting a plain `T`, and decision 8 §2.1's `unknown` (`isUnknown`), which accepts every type **into** it and none **out** of it. The `unknown` rule sits above the kind match because it holds against every kind on the other side, not only `.named`; an unbound variable on either side still links, so inference deciding a type is never mistaken for a use. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`), plus `validateComptime` — the gate that decides what may appear inside `comptime` / `comptime { … }`: literals, arithmetic, comparisons and `&&`/`||`, `not`/`-`, array literals, pipelines, `if`, `break`, and identifiers that the block itself declared. `validateBody` threads that scope on the Zig stack (a `val`/`var` validates its initialiser in the scope before it, then validates the rest of the block with the new name in scope) and mirrors the `Scope` `eval.zig` builds with real values. A ctor or any other call stays rejected on purpose — see the `comptime record lit` skip in `tests/eval_pipeline.zig` for why (one literal text has no cross-backend record form). Two structurally legal folds are refused too, located at the expression (`ComptimeError.reason`): a constant zero divisor (`divisionByZero`, C4b) and negating a string (`negatedNonNumber`). |
| `effect_chain.zig` | The effect chain (decisions 118, 120, 128 of 1.0.10-beta). `clauses` restates the `extends` clauses `libs/std/src/builtins.d.bp` declares on the wrappers (`Component ⊃ Task`, `Stream ⊃ Task`; `Iterator` has none; `Result` is outside the chain); `wrapperImplements` closes them transitively; `grants(eff, cap)` answers whether a body whose return activates `eff` may write `await` / `use` / `yield`, and is the ONE question those legality checks ask — `throw` / `try` read the fallible channel instead (`infer.zig` `fallibleErrorOf`, decision 121). `refusal` builds the diagnostic, which names the returns that would grant it (decision 67). Its drift tests read `builtins.d.bp` through `std_prelude` and fail in both directions — a clause here that the file does not declare, one the file declares that is not here, a wrapper `EffectKind` names that the file does not declare, and a removed wrapper (`Future`, `Generator`, …) the file still declares. |
| `diagnostics.zig` | Stable diagnostic-code constants (R1–R21, RF1–RF5, RI1–RI6, RC1–RC6, RG1–RG4, D1–D6, `std-unsupported-on-target`, `src-takes-no-arguments`, `unknown-builtin`, `effect-try-without-fallible-channel`, `option-expect-removed`) plus the `all_codes` table. Messages live at the firing site. |
| `eval.zig` | `ComptimeEntry` / `RunResult` / `evaluate(allocator, entries)` — folds each comptime `val` in Zig (`valueOf`: literals, arithmetic, `not`/`-`, `@TypeOf` name, `@typeInfo`/record literals as objects, a comptime block's / `if`'s / `case`'s / loop's `break` value) and writes the literal backends splice in (`3`, `6.28`, `"text"`, `[1, 2]`, `true`, `null`; objects and nested lists are `null`). **Every operand carries its kind** (`Value`): `binary` folds int arithmetic as int, promotes to `f64` as soon as one side is a float (`3.14 * 2.0 → 6.28`), concatenates two strings on `+`, and returns a `boolean` for `==`/`!=`/`<`/`<=`/`>`/`>=`/`&&`/`||` — so an `if` inside a folded block takes the arm its condition really selects. Anything irreducible (a record operand, a non-constant zero divisor) folds to `null`, never to a stand-in `0`; a constant zero divisor or a negated string never gets here (`validateComptime` refuses it). A `comptime { … }` block has a `Scope`: `blockResult`/`execStmt` declare its `val`/`var` locals, apply `=`/`+=`, and follow an `if` into the arm that `break`s; a nested arm gets a child scope. `RunResult.script` is the listing shown in snapshots as `COMPTIME VALUES`: one `ct_N: <declaration> → literal` per entry, the declaration formatted by `comptime.zig` `evaluateComptime` (`ComptimeEntry.source`; continuation lines aligned). An identifier that is neither a block local nor `true`/`false`/`null` is `error.UnsupportedComptimeValue`. |
| `render.zig` | `extractLine` / `padSpaces` / `digitWidth` helpers for diagnostic rendering. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. Applies `method_lowerings` (`__bp_<domain>_<op>(…)`), `result_jump_lowerings` (`tryLowerResultJump` — a bare `return;` wraps `null`, decision 74), `templateExpansions`, `srcRewrites` (the `@src()` → `SourceLocation(…)` splice, only onto the builtin call at that loc), `enumSectionRewrites` (`rewriteExpr`), and **`index_rewrites`** (C-02 — the index expression's method call takes the `[]` node's place, after the `@src()` splice and before C-04's fill, so the spliced call still reaches its own lowering, its fill and any nested index; applied by BOTH aggregators, the `src_only` one included, because an index in a method body is the same expression it is in a fn body). Walks `fn` and `test { … }` bodies, including `assert` subexpressions. **Method bodies** (`type` and `implement` methods) never went through this walk — the backends lower them from the parsed AST — so they receive only the `@src()` splice, through a second `src_only` aggregator whose other maps are empty and which skips the one unconditional rewrite (the `${}` desugar); the full walk over method bodies is a separate change (it moves `record_method_with_todo_placeholder` on erlang: `@todo()` would get its default injected there as in a fn body). **Default-value expansion**, in two layers. `applyDefaultFill` (C-04, 01 step 7 N1) is the live one: `rewriteExpr` and `rewriteStmt` look the call's loc up in `default_injections` (`env.defaultInjections`) and rebuild `c.args` from the plan inference recorded — one argument per parameter, in declaration order, the omitted ones `is_default_inj` refs to the param's own default Expr (no new Exprs materialized). It runs BEFORE `tryLowerMethodCall` / `tryLowerStdArrayCall`, which reshape the argument list they are handed, and it runs in BOTH aggregators, the `src_only` one included — a method body's call sites need their defaults as much as a fn body's do. It applies the plan only while the plan still describes the call in front of it (every slot's argument index in range, and as many of them as the call has arguments), so a call some other rewrite got to first is left alone. `expandTrailingDefaults` / `expandTrailingDefaultsWithParams` is the older tail-append, still reached from `rewriteCall` for the two shapes inference never judges — builtin `@fn()` calls and qualified `Enum.Variant(args)` — via `fn_decls` (which also includes `env.stdlibFnDecls`) and `ctor_params` (from `env.ctorParams`; variants registered under bare and `Enum.Variant` names); it is a no-op on a call `applyDefaultFill` already completed. Drops template fns and decorator fns from the output decls. |
| `template.zig` | `@Expr` template infrastructure: `CapturedExpr` (argument bound to a `comptime p: @Expr<T>` param, captured unevaluated with provenance), `PlainArg` (`{ paramName, source }` — a non-`@Expr` param or decorator argument that received a literal; `toExpr` turns its lexeme into an `erl_ast` expression), `ScopeSnapshot` (origin scope: caller's top-level decls + imports; `toJsonAlloc` feeds the memo key), `CustomNode` + `parseCustomNodeFromTree` (from `template_eval.CustomNodeTree`), and `mapSpanToLoc`/`failDiagnostic` (rustc-style `fail`/`failAt` diagnostics inside the caller's `"""…"""`). With contiguous text `mapSpanToLoc` counts newlines up to `span.start`; for holed multiline templates it falls back to `capture.loc.line + span.line - 1` (`span.line` is 1-based, line 1 = opening `"""` line). |
| `template_eval.zig` | Runs a template body that the V1 classifier cannot reduce. `buildModule` lowers the template `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode; host enums `BindingKind`/`DeclKind`; host records `Span`/`CustomNode`/`Binding`/`Source`/`Context`, so `Span(5, 9, 1)` / `CustomNode(kind: …)` build maps) and passes `main/0` as an `erl_ast` form (`mainForms`). The rest of the host glue is **resident** in `bp_comptime_template` (`runtime/prelude.zig`), declared to the emitter as `ComptimeModule.resident` and reached by the `-import` it writes, so nothing but the body, its shims and `main/0` is compiled per evaluation. `main/1` destructures an argument tuple and calls the body with it, so the module carries **nothing** from the call site and its content hash is a hash of the declaration: one `.erl` per template, not one per call site. Each `@Expr` parameter's element is `captureToTerm(capture)` — a map tagged `'__bp_capture' => Param` with `text` (raw literal text; holes appear as their `__bp_hole_<param>_<i>` placeholder), `parts` (`#{kind => <<"Text">>, text, span}` / `#{kind => <<"Interp">>, code => Placeholder, span}`), `source`, `context` and `bindings` (`#{name, kind => 'Record_'}`); a plain parameter's element is `plainArgTerm` — the same value `PlainArg.toExpr` renders, as a term, with `lexemeBytes` resolving the escapes `erl_emitter.writeStringFromLexeme` resolves; a lexeme carrying `\u{…}` has **no** exact term (the emitter renders it as Erlang's `\x{…}`, which truncates to a byte in a plain binary) and stays a literal in the module, which keys the module by that literal too. The tuple reaches the node as an external term (`runtime/etf.zig`), never as source text re-parsed there. The listing is rendered once per module atom (`cachedListing`/`rememberListing`) rather than once per call site — `emitComptimeModule` re-parses the embedded preludes on every emit, which is the whole of an evaluation's remaining compiler-side cost. Host functions, all resident: `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2` (binding map or `undefined`), `ref/1` (`Binding.ref()` — replies with the binding's **name** as code, so a hit splices a bare caller-scope reference instead of a value), `build/2`, `custom/3`, `fail/2`, `failAt/3`, `compilerError/1`, `expr/1`, `code/1`. `main/1` replies with JSON by result shape — `code`, `value` (`@expr`), `custom` (tree + code), `capture` (`return q`), `fail` (message/param/span), `error` — with `undefined` mapped to `null`. The module atom and file (`.botopinkbuild/tmp/template/bp@comptime@<owner path>__tpl__<template>__<16 hex>.erl`) are A2's declaration-qualified atom (`codegen/crossModule.erlDeclAtom(ownerId(owner), .tpl, tfn.name, hash)`), so a stack trace and a `tmp/template/` listing name WHICH template they came from **and the file it was declared in** (C-01, 13 half 1 step 5): `ownerId` puts the owning module's path under the compiler's own `bp@comptime` namespace (`shapesdsl/shapesdsl` → `bp@comptime@shapesdsl@shapesdsl__tpl__shapesdsl__<hash>`; `crossModule.decodeAtom` reads package `bp`, path `comptime/<owner>` back). The owner is `evaluate`'s `owner` argument, which inference reads off `Env.comptimeOwnerOf(tfn)`: the declaring module records it (`registerFnSignatures`) and an importer records the module that exported it (`comptime.zig` `resolveImports`), keyed by the declaration's body address rather than its name. A declaration no module owns (the unit tests here) keeps `bp@comptime__tpl__…`. The namespace stays `bp` rather than the owner's package: the module is content-addressed scratch shared by every package of the build. The hash is the same Wyhash of the generated code, which no longer sees the capture, so an identical body is still the identical module and re-loading it is still a no-op. `runtime/runtime.zig` `evalWithArg` runs it on the compilation's runtime — the BEAM runtime stages the `.erl` once per atom (staged and renamed, so concurrent evaluations never compile a half-written file), the wat runtime lowers the same text — and this file imports neither executor; `parseOutcome` maps the reply to `Outcome` (`value` → `TypedValue`, `ast` → `CustomNodeTree` with `ref: ?NodeBinding{name, kind}`), and compile/runtime failures become `err` with the Erlang diagnostic. A runtime the dispatcher reports `unavailable` (none on this host; the `erl` node died or its frame stream desynchronised) becomes `err` with the reason; `erl` missing altogether stays `error.EvalFailed`, so the caller's PATH hint still fires. A lifted map's key order is the reply's canonical one (`typedValue` sorts it — `runtime/reply_order.zig`). A body method call that no primitive type and no host function answers (`emitComptimeModule`'s `unsupported_method` slot) becomes `err` naming the method, its argument count and its `line:col` in the body. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument). On a host that lacks the compilation's runtime (the browser build) the dispatcher answers `unavailable` naming it. Inline tests cover reply parsing. |
| `decorator_eval.zig` | Runs a decorator body over the declaration it annotates. Input: a native `DeclHandle` (`kind`/`name`/`fields: []FieldHandle`/`variants`/`methods`/`returnType`/`annotations`; `variants` lists an enum-shaped `type`'s variant and section names and is empty otherwise — with `DeclKind.Type` covering both shapes it is how a decorator tells a record from an enum) built by `infer.zig`. `buildModule` lowers the decorator `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode, `DeclKind` as host enum, `Span` as host record, `main/0` exported) and passes `main/1` as a `codegen/beam/erl_ast.zig` form built with `Ast.Builder` (`mainForms`); it destructures the argument tuple, so the module carries nothing from the declaration it runs over and its hash is a hash of the decorator plus its annotation arguments. `fail/2`, `failAt/3`, `compilerError/1` (throw a tagged rejection) and `emit/1` / `'__bp_emitted'/0` (process-dictionary accumulator) are **resident** in `bp_comptime_decorator` (`runtime/prelude.zig`), reached by the `-import` the emitter writes. `main/1`'s argument is `handleToTerm(handle)` (a `codegen/beam/term.zig` map — `kind` as atom, names as binaries, annotation args as raw lexemes) followed by the annotation arguments (`templateEval.plainArgTerm`; missing → `undefined`), encoded by `runtime/etf.zig` and replies with JSON `{kind: ok, contributions} \| {kind: fail, message, span} \| {kind: error, message}`. The module atom and file (`.botopinkbuild/tmp/decorator/bp@comptime@<owner path>__dec__<decorator>__<hash>.erl`, `templateEval.ownerId` — the same owner rule as a template's) come from the code's hash, which no longer sees the handle. `runtime/runtime.zig` `evalWithArg` runs it on the compilation's runtime (the BEAM runtime stages it under `.botopinkbuild/tmp/decorator/`; the wat runtime lowers the same text) — this file imports neither executor; `parseOutcome` maps the reply to `Outcome` (`ok` / `fail{message, span}` / `err`), compile/runtime failures become `err` with the runtime's diagnostic (truncated to 4 KiB), and an `unavailable` runtime (none on this host, a broken `erl` transport) becomes `err` with its reason. A body method call that no primitive type and no host function answers becomes `err` naming the method, its argument count and its `line:col`. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument). A runtime the host lacks (the browser build) is refused by the dispatcher with the runtime named. Inline tests cover the module shape and reply parsing. |
| `primOpTemplate.zig` | Shared renderer for `#[@External.<Target>("<template>")]` primitive-op templates. Substitutes `receiver_marker` (the receiver — written only by `parser/template_markers.zig`, which translates the source's positional markers, decision 5; `$self` is no marker), `$<N>` (positional arg after the receiver), `$args` (all positional args, comma-separated) and `$stringify(<inner>)` (recursive render bracketed by the backend's `emitStringifyOpen`/`emitStringifyClose`, e.g. erlang `iolist_to_binary(io_lib:format("~p", [`…`]))`, node `JSON.stringify(`…`)`) through a backend-supplied ctx (`writeByte`/`writeAll`/`emitRecv`/`emitArg`/`argc`); other bytes pass through verbatim. Errors: `PrimOpArgIndexOutOfRange`, `PrimOpStringifyMalformed`, `PrimOpStringifyUnsupported`. `looksLikeTemplate(s)` (`$`-bearing) separates a template from the `module:symbol` form in erlang's `tryEmitPrimAnnotation`. **Arity branching** (`when(argc == N): "<template>"`): `parser.zig parseAnnotationCall` keeps each clause as one arg, `ast.parseArityBranchArg` extracts `{argc, template}`, the backend picks the matching branch (no match → falls through). **Triple-quoted** bodies: `ast.zig unquoteAnnotationArg` strips the fences plus one leading and one trailing newline. **BEAM consumer**: `codegen/beam_asm.zig renderBeamTemplate` uses the same walker with `emitRecv` → `{x, 0}` and `emitArg(i)` → `{x, i+1}` after pre-loading receiver/args; BEAM bodies are `#[@External.Beam("""<.S body>""")]` and are detected by `bref.module.len == 0`, not `looksLikeTemplate` (a body may have no `$` marker). |
| `snapshot.zig` | Snapshot helpers. `assertComptimeAst` records one file per test at `snapshots/comptime/ast/<slug>.snap.md`, **without** the runtime exchanges; `assertComptimeExchange(runtime, slug, outputs)` records those (`buildExchange`: source + every `trace` entry) at `snapshots/comptime/runtime/<beam|wat>/<slug>.snap.md` when a decorator or template ran (front 18 step 4, `snapshot-layout.md` § 6) — the layout is `tests/AGENTS.md`'s table. **Type text**: `typeNameIn` renders an inferred `*T.Type` in one of two spellings (`TypeRender.mode`). `.diagnostic` is what `typeNameOf` and the error renderers print and what the `comptime/errors/` and `codegen/**/errors/` snapshots record — frozen: a `.func` collapses to its return type and every `.typeVar` is `?`. `.ast` is the `TYPED AST JSON` spelling: a `.func` reads `fn(<params>) -> <ret>`, `optional<T>` reads `?T` (as `array<T>` already reads `T[]`) unless its inner is itself unknown, and a `.typeVar` splits — `.generic` renders the declared type parameter (`GenericNamer.bind`, matched through the annotation by `bindGenericNames`, never guessed by position) or falls back to `'a`, `'b` by first appearance, while `.unbound` keeps `?`. **`?` means exactly one thing in a snapshot: the checker does not know**, so nothing else may render as it. `fn_def` params and return type come from the binding's inferred `.func` type; a record field, a method signature and an enum-variant payload go through the syntactic `typeRefName` instead — they are annotations the declaration wrote and are not bindings of their own (`infer.zig` `buildRecordDeclName` renders the same text into the record's type name). Inline tests pin all of it. **Declaration shapes**: `record_def` / `enum_def` / `interface_def` / `implement_def` carry `generic`, plus `implements` (an inline `record(…) implement I { }`), `fields`, `variants` with their payload types, nested `sections`, `extends`, and `methods` (`declare fn` slots included; an `implement` method has no `return_type` — the AST carries no return annotation there and the signature it satisfies is the behavior's). Every one of them is omitted when empty. An `implement` block declares no binding, so `buildSnapshot` reads those off `OkData.transformed.decls` in source order after the declarations that do bind. `record_def`/`enum_def` carried an `"id"` until 1.0.5-beta: it was `0` in all 71 snapshots that had it, because `resolveTypeId` looked a structural type name up in a map keyed by the declared one, and decision 19 removed the field. The `type_ids` plumbing in `../comptime.zig` (`:114`, `:1311-1313`, `:1324`, `:1490-1492`, `:1503`) is now dead and belongs to whoever owns that file. Section order: `SOURCE CODE`, `COMPTIME VALUES` (when comptime vals exist), `BOTOPINK TRANSFORM CODE` (whenever a comptime val folded, a template/decorator ran, **or** the module expanded a template at all — `OkData.template_expansions`, so the V1-driver pass-through / `@expr` / `@code` expansions that never reach the `erl` runtime are recorded too; spec 06 H8/C1), `TYPED AST JSON`. A module whose outcome is not `.ok` writes a `COMPILE DIAGNOSTIC` section instead of stopping after `SOURCE CODE` (H3). Also owns the shared diagnostic renderers `renderTypeErrorBody` / `renderParseErrorBody` / `renderOutcomeDiagnostic` / `appendDiagnosticSection`, reused by `comptime/tests/helpers.zig` (`renderTypeError`) and by the codegen harness. |
| `trace.zig` | `Entry{kind: template/decorator, name, listing, lang, reply}` — one per `template_eval`/`decorator_eval` run, appended to `Env.comptimeTraces` (surfaced as `OkData.comptime_traces`; `analyzeModule` keeps pass-1 decorator traces across the `@emit` re-analysis). `erl` is the `listing` build of the module (lowered body + `main/1`) followed by `main/1`'s argument as comment lines — the input half of the evaluation, which is no longer inside the module; `reply` is the JSON `main/0` printed, or `compile error: …` / `runtime error: …`. `lang` (`erlang` \| `wat`) says what `listing` is: the Erlang the BEAM runtime ran, or the generated module's functions as the wat runtime lowered them (`runtime.listingOf`), each followed by `main/1`'s argument as comments. `render`/`renderAlloc` write the `COMPTIME ERLANG` (or `COMPTIME WAT`) and `COMPTIME REPLY` sections (JSON re-indented, **objects' keys sorted** — `runtime/reply_order.zig`: the order a runtime's map iterated in is not part of the reply, and the BEAM's is its atom table's). |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` (plus the inline tests of `eval.zig`, `trace.zig`, `primOpTemplate.zig`, `snapshot.zig`, `diagnostics.zig`, `template_eval.zig`, `decorator_eval.zig`, `runtime/persistent_erl.zig`, `runtime/runtime.zig`, `runtime/prelude.zig`); harness in `tests/helpers.zig`. |

## The return is the effect (decisions 118–128 of 1.0.10-beta)

A function's effect is `ast.FnDecl.effect: ?EffectKind` (`result` / `task` /
`iterator` / `stream` / `component`), set by the PARSER from the syntactic
return: `EffectKind.fromReturnType` reads a builtin generic written with its `@`
as the outermost return type (`-> @Task<User>`); `EffectKind.ofFn` drops the
effect of an `@Iterator` / `@Stream` whose body neither `yield`s nor `break v`s
in its own scope (`ast.bodyYields`) — a FACTORY, an ordinary function returning
a ready iterator (decision 123). A method's effect is read the same way
(`EffectKind.ofMethod`). There is no effect annotation: the six
(`#[@result]` … `#[@futureGenerator]`) and the pre-121 names are parse errors
(`effect-annotation-removed`, `parser.zig` `parseAnnotations`), and so are the
removed wrappers (`effect-type-removed`, `iterator-error-param-removed`,
`parser/types.zig`). A function has one return, so it has one effect — R1–R5,
`effect-missing-annotation`, `effect-missing-wrapper` and
`effect-duplicate-annotation` left with the annotations. An ALIAS to a wrapper
(`-> Parser<i32>` with `type Parser<T> = @Result<T, E>`) types the function
and activates nothing: `inferFnDecl` sets `env.aliasWrapper` (`aliasedWrapperOf`)
and a capability used under it is `effect-wrapper-behind-alias`
(`refuseBehindAlias`).

**A lower-case `#[@external(…)]` binds nothing, and says so** (R3, decision 8 §8, decision 15).
Only the capitalised path form `External.<Target>` is read as host-backed (`FnDecl.isExternal`,
`ast.zig`'s `startsWith("External.")`), so `#[@external(node, "…")]` fell through as an unknown
annotation and was dropped — the `declare fn` bound no host and `check` exited 0 in silence.
`refuseLowerCaseExternal`, called from `inferFnDecl`'s annotation loop, reds at the annotation and
spells the target capitalised. It fires on the `@`-prefixed builtin form only: `#[external(…)]`
without the `@` is a user-defined attribute and means something else.

**An `inline` no emitter reads is refused** (front 20 F9, decision 67). `External`'s flag is read
by `codegen/erlang.zig` and `codegen/beam_asm.zig` alone (`hasExternalInline`, over the LAST
argument), so `builtins.d.bp` declares it on `Erlang` and `Beam` alone — and until this rule the
checker never read that declaration, so `#[@External.Node("…", inline = true)]` checked and ran
as a switch that did nothing. `external_variants` restates the five variants with their
`declares_inline` bit (`comptime/tests/infer_decls.zig` reads `builtins.d.bp` through
`std_prelude` and fails in both directions when they drift), and `refuseUnreadInline` reds at
the annotation for the three unread shapes: the flag on `Node` / `Wasm` / `Typescript`, the flag
anywhere but last, and a value that is not `true` / `false`. It runs from
`validateExternalAnnotation` for a `declare fn` and from `validateExternalInline` — a program
walk beside `validateEffectAnnotations` — for a behavior's and a type's methods, which the two
emitters read the same way.

**One `ContextBase` per function** (decision 96 of 1.0.10-beta). The anchor is
a property of the BODY, not of each activation: `env.useAnchor` records the
base the first `use` resolved against, with its line, and is cleared by
`inferFnDecl` around every body. `validateUseBase` asks two questions in order
— the anchor's, which reds a second `use` anchored elsewhere
(`contextBaseMixed`, naming both bases and the line that fixed the first), and
then, only for the first `use` of a body, RC2's, which reds a `use` anchored at
a base the RETURN TYPE never named (`contextMismatch`). The two coincide
wherever the return type names a base, which is every shape that parses today.
Measured at front 20's landing: the premise decision 96 corrects — "RC2 asks
only that a hook be anchored at a subtype of the body's base" — was true of the
DOCUMENTATION (`builtins.d.bp` § 1C, now rewritten) and never of this checker,
which has always compared the two names for equality. The library half — the
owner type of a component declaring a base type of its own, instead of being
its own base — belongs to the framework that declares that type, and is
written up in the root `AGENTS.md` § Open handoffs. Nothing here changes when
it lands: the anchor reads whatever the first type argument says.

**The effects are a chain** (decisions 118, 120, 128). `effect_chain.zig`
owns the order — `@Component` and `@Stream` extend `@Task`, `@Iterator` extends
nothing — and every level check (`await`, `use`, `yield`) asks
`effectChain.grants(eff, cap)` instead of switching on an effect kind. The
clauses are declared in `libs/std/src/builtins.d.bp` on the wrapper
declarations; that file is not parsed into the type env, so `effect_chain.zig`
restates them and carries drift tests that read the file and fail if the two
disagree. Adding a wrapper is a row in `clauses` and nothing else. The refusals
are built by `effectChain.refusal`, which names the returns that would grant the
capability (decision 67 — located, no flag). `await` in an `@Iterator` (or an
`iter` loop) is `iter-await`; elsewhere without an await channel it is
`effect-await-without-task`.

**Only `@Result` fails** (decision 121). `throw` / bare `try` read the FALLIBLE
CHANNEL, computed from the return apart from the level: `fallibleErrorOf(eff,
retType)` answers the `E` of the `@Result<U, E>` layer — the return itself for
`-> @Result`, the value `T` of `@Task<T>` / `@Component<C, T>`, the item of
`@Iterator<T>` / `@Stream<T>` — and `inferFnDecl` sets `env.throwContext =
.result(E)` from it (`.plain` for a declared return without one, `.unchecked`
with no declared return: a lambda, a `test` block). `throw` / `try` under
`.plain` are `effect-try-without-fallible-channel` (the old
`effect-throw-without-fallible-channel` merged into it). `try … catch`
propagates nothing and is not gated.

**`return` wraps through every layer** (decision 119). `returnTargetFor` gives a
`return` the value layer's `U` when that layer is `@Result<U, E>`, the value `T`
otherwise; `result_jump_lowerings` records `wrap_ok` for a plain value, nothing
for a value that passes through (`valuePassesThrough`: a `@Result`, or the whole
declared wrapper), `unwrap_passthrough` for `return try f()`, `wrap_error` for a
`throw`. In a sequence whose item is `@Result<U, E>` (`unifyItem`), `yield v` /
`break v` with `v: U` records `yield_ok` (the transform wraps `__bp_ok(v)`) and
`throw e` records `break_error` (the transform writes `break __bp_error(e)`:
the error is the last item and the sequence ends). A `return <v>` in a body that
yields is `iter-mixed-yield-return` (decision 123); in an `iter` / `stream`
loop it is `iterator-return-forbidden`. `await` types `@Task<X>` / 
`@Component<C, X>` → `X` (`unwrapTaskType`) and propagates nothing.

The body context `starCtxFromEffect` → `env.starFn: ?StarFnCtx{ allowsAwait,
allowsYield, iterItem, effect }` is built for **every** effect (it is null only
in a plain `fn`), with `allowsAwait` / `allowsYield` read off the chain. A
`test` block gets a `.task` context, so a test may `await` directly.

**A `yield` feeds the nearest generator scope** (decisions 105, 125) — an
`@Iterator` / `@Stream` fn or method that yields, or an `iter` / `stream` loop —
through every unprefixed `for` / `while` / `loop` between them; `env.loopDepth`
plays no part. `yield :label` must name that scope's label (`fnLabel`: a fn's
signature label or the prefixed loop's) — a plain loop's label is `yield-label-not-generator`, an unknown one
`yield-label-unbound`. `break <value>` is the same jump with an end: it emits the
value and ends the nearest generator scope (its value unifies with the scope's
`iterItem`, the completion channel `C` of the old RI2/RI3 is gone — decision 103);
outside one it is the value of a `comptime` block or a `case` arm's block
(`env.breakScope == .valueBlock`, decision 2) or `break-value-outside-generator`.
A bare `break` leaves the nearest loop, ends the generator scope at loop depth 0
(`iterator_jump_lowerings .wrap_done_void`), and is `break-outside-loop` with
nothing to leave; `continue` with no loop is `continue-outside-loop`. A lambda
body restarts `loopDepth` at 0 and `breakScope` at `.none` (a `case` arm's block
keeps `.valueBlock`).

`inEffectContext(env, kind)` fires the sequence-only rejections (RI1,
`iter-mixed-yield-return`). `resultVariantCallName` /
`builtinRequiredGenericArgs` drive the syntactic rejections. Codegen reads
`f.effect` directly (`commonJS.zig effectShape`: task → `async function`,
iterator → `function*`, stream → `async function*`, component → `async
function` (decision 104), result → plain `function`).

Default-parameter diagnostics: D5 (defaulted param followed by a required one)
fires from `parser/decls.parseParamList`; D2 (positional arg after a named one)
from `parser/exprs.parseCallArgs`. The remaining D-codes are reserved constants.

`break [:label] [<expr>]` lives on the Jump AST as `@"break": struct { label:
?[]const u8, value: ?*Expr }` (mirrors `.yield`). Unbound labels (RI5) use the
same `env.labelStack` as `yield :label` (RI4) — declare the target with
`for :name (…)` / `while :name (…)` / `loop :name {`, `fn … -> @Iterator<…> :name`
or `iter loop :name {`.

**Decision 122 — sequences.** `@Iterator<T>` and `@Stream<T>` share one step
enum, `YieldStep<T> = { Yield(value), Done }`; there is no iterable behavior and
no completion channel (`StarFnCtx` carries the item type only). A `break <v>`
that targets the generator scope (top-level position, or `break :label` with the
scope's label) unifies `v` with the item (`unifyItem`); the backends lower it as
decision 105's generator-scope `break <v>` (emit and end). A `for` over any
`@Iterator<X>` is legal in any function and binds `X` — a `@Result` when `X` is
one: there is no implicit `try`. `for` over a `@Stream` is `for-over-stream`;
`for await` needs an await channel (`effect-await-without-task`) and a
`@Stream<T>` (`for-await-expects-stream`). RG5 (`generic-arg-count-exceeded`,
`builtinMaxGenericArgs`) refuses a type argument past a builtin wrapper's
declared arity; no effect wrapper declares a default any more — and past a
declared type's own parameters (`TypeDef.genericParams`, at the annotation):
`YieldStep<T, E>` is refused with a hint naming `YieldStep<@Result<T, E>>`.
`YieldStep<T>` is a real type: `comptime.zig` registers `yield_step_src` (the
`builtins.d.bp` declaration, pinned by the `yield step prelude matches
builtins.d.bp` test) into the global env, so an annotation, `case` over
`Yield(v)` / `Done` and a `.next()` type-check. `.next()` by hand
(`inferSequenceNext`) on an `@Iterator<T>` answers `YieldStep<T>`, on a
`@Stream<T>` `@Task<YieldStep<T>>`, and records `InstanceLowering.sequence_next`
(`SequenceKind.iterator` / `.stream`) at the call's loc. Naming the type (a
`.named` / `.generic` ref, or a `.next()`) sets `env.usesYieldStep`, and
`withYieldStepDecl` prepends the private declaration to the transformed program
— the `SourceLocation` splice — so every backend builds and matches the variants
through its own enum path; a module declaring its own `YieldStep` keeps it.

**Decision 119 — `effect-return-ambiguous-nesting`.** In a nested
`-> @Result<@Result<U, E>, E>` (the value layer's `U` is itself a `@Result`), a
returned `@Result` that is not the whole wrapper fits two layers — wrapped
`Ok(…)`, or passed through — and is refused at the `return` rather than read one
way (`looksWhole` tells the whole wrapper apart: its first argument is a
`@Result`).

**E3.9 — the hint of the migration's most common error.** A `typeMismatch` with
a `@Result` on exactly one side renders `error.zig` `resultMismatchHint`, one
text per source of the `@Result` (`ResultOrigin`): after `await t` it suggests
`try await t`; on a `for` / `for await` item, `try r`; either way `case` /
`catch` handles it instead. A value inferred as `@Result` — an `async { }`
block's value, an `iter` / `stream` item — also points at the first `try` /
`throw` of its own block that made it one (`ast.bodyFirstFail` /
`bodyFirstThrow`, line:column). The origin rides on the type: `markResultSource`
gives the `await`'s value and the loop's item a fresh copy of the `@Result`
node, recorded in `Env.resultOrigins` (inheriting the `made_at` of the node it
copies), `noteInferredResult` records the block's / loop's own node, and
`unify.zig`'s `unify` copies the origin of the `got` side onto the
`typeMismatch` it fails with (`noteResultOrigin`). A `@Result` of no recorded
origin keeps the one text naming all three. Pinned by the three `E3.9` rows of
`tests/effects.zig` and `tests/language/reject/result_hint_*.bp`.

**Decision 124 — `async { … }`.** The parser writes the block as a
`.function` node with `syntax = .asyncBlock` and no parameters (a closure called
in place). `inferAsyncBlock` types it `@Task<T>`: `T` from its `return`s (a
`return` leaves the block — `returnTarget` / `returnWhole` are the block's), and
`@Result<U, E>` when the body has `throw` / `try` of its own (`ast.bodyFails`) —
unless the position expects a `@Task<X>` (an annotated `val`), which pins the
value and so opens or closes the fallible channel. The body awaits (`starFn` is
a `.task` context), never yields, and never `use`s (`env.asyncBlockDepth`,
refused with `use-without-context-effect`); the enclosing labels are closed.
Where the `E` is inferred (`env.inferredErrorScope`: an unannotated block, or an
`iter` / `stream` loop whose item became a `@Result`), every `throw` / `try`
joins it through `unifyErrorChannel`, and two errors that do not unify are
`gen-infer-conflicting-errors`.

**Decision 125 — `iter` / `stream` loops.** The parser writes `iter while` /
`iter for` as the prefixed `loop { <the written loop>; break; }`
(`LoopExprOf.prefixedKeyword` keeps the written keyword for the formatter), so
`inferGeneratorLoop` types ONE shape: worth `@Iterator<T>` / `@Stream<T>`, `T`
fresh, and — when the body has `throw` / `try` of its own (`ast.bodyFails`) —
`@Result<U, E>` with `throwContext = .result(E)` (decision 125: the item becomes
a `@Result` on its own). The body is closed: the enclosing effect, labels, `use`
anchor, throw channel, alias and return target are replaced for it.

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
  `env.templateLowerings`. The contract is `behavior Expr<E>` in
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
(`TypedValue` → literal / array / tuple — a tuple takes the labels its template body gives it: `liftShapeOf` reads `return @expr(#(server, debug))` and the `val server = #(host, port)` bindings before it, so the lifted `tupleLit.labels` make `cfg.server.port` resolve; an Erlang tuple crosses the bridge as `{"$tuple": [...]}` (`'__bp_json'/1`), a host map lifts as a tuple labeled by its keys); `custom` → `code` spliced
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

**Which module an import resolves in.** Both registries are keyed by module
PATH, and `resolveImports` used to walk them taking the first entry that held
the name — so `from "<mod>"`, the one thing that says WHICH module the import
means, was consulted by neither. A name is unique inside a module and never
over a program: `libs/std` declares `parse` in `json`, in `querystring` and in
`url` today. Measured, a module importing `Outcome` from `"parser"` was bound
to `"net"`'s record and the program was refused against the wrong record's
fields ("expected i32, got string"). Both loops run twice now
(`ast.ImportSource.namesModule` — the full path or its last segment): the
module the source NAMES answers first, and the old whole-registry scan is the
second pass, so a `from "<pkg>"` handle covering several modules, a bare
`import { … };` and a module not yet analysed all reach exactly the scan they
reached before.

**Only the leaf of an import path enters scope (decision 107).** An item is
an `ImportPath{segments, activate, alias, loc}` in either spelling — the
parser flattens `io: {fs: {readText as read}}` to the same segments as
`io.fs.readText as read`. `resolveImports` looks the LEAF (`imp.leaf()`) up in
the module the prefix names (`ImportDecl.leafSource`: `import {html.div} from
"web"` narrows to `web/html`, the bare `import {shapes.circle.name};`
to `shapes/circle`, the same `namesModule` narrowing as a `from`), and binds
it under `imp.name()` — the alias when one is written — so the template and
decorator registries are keyed by the alias too. `markStdImports` does the
same over `env.stdModules`: a whole path that is a std module (`dict`,
`io.fs`) binds the namespace (`stdImports`), a prefix that is one binds the
leaf as a value (`env.bind`) or registers the one `pub type` it names. Three
refusals, each located at the item: `import-name-collision` (a second item
binding a name already bound — `noteImportBindings`, over every `use` decl,
an identical repeated item excepted because an `@emit` contribution re-imports
what its module already imports), `import-alias-on-type` (a type's identity is
its declared name on every backend) and `import-alias-on-activation` (the
dispatch rewrite emits the extension's declared name). A `resolveImports`
refusal is the module's `typeError`, like one from inference.

**The root of std is pure (decision 106).** `checkStdRootPurity`, first in
`markStdImports`, refuses an import item whose first segment is `io` in a
module at `std/<name>` (one segment — `env.modulePath`) when the list reads the
std package, bare (`.root`) or `from "std"`: `std-root-imports-io`, located at
the item. `std/io/*` and `std/testing/*` are two segments deep and not
checked; neither is user code. No configuration (decision 67). Proved with a
module AT the path `std/probe` (`codegen/tests/std_package.zig`), not by
editing `libs/std`.

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
- The reflection cluster (`type DeclKind { Type, Behavior, Fn, Method, Field }` +
  `type Decl`/`Field`/`Method`/`Param`/`Annotation`/`Span`)
  is registered by `registerStdlib` from `decl_reflection_src` (a mirror of
  `libs/std/src/builtins.d.bp` — keep in sync). `Decl` is a record so the array
  members `fields`/`methods`/`annotations` resolve.
- `registerStdlib` also parses `libs/std/src/builtins_fns.d.bp` (the parseable
  `declare fn` slice: `todo`/`panic`/`trap`/`emit`/…) into `env.stdlibFnDecls`,
  which `compile`/`compileTypesOnly` merge into transform's `fn_decls` so
  trailing defaults are injected at bare `todo()`/`panic()` calls. The synthetic
  `Result`/`Task`/`Component`/`Iterator`/`Stream`/`Context` interfaces
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
  decl — `Fn`, `Type` (a record shape with `FieldHandle`s, an enum shape with
  `variants`), `Behavior`, plus
  per-`Field` and per-`Method` handles — and `runDeclDecorators` calls
  `decoratorEval.evaluate` for each body-carrying decorator (annotation args
  become `PlainArg`s). `fail` and `err` become a `TypeError` at the annotation
  (`ast.Annotation.loc`, via `decoratorError`; a `failAt` span is reported there
  too, since a declaration has no template text to map it onto) whose message
  carries the detail — for `err`, the Erlang compile/runtime diagnostic; `ok`
  appends `@emit` sources to `env.contributions`. An
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

## `use` capability inference (decisions 88, 96, 102, 104, 128)

`use` is a **prefix operator** (`use <hookcall>`); bindings come from the
enclosing `val`/`var` (`val {v, s} = use state(0)`, `use effect(…)` for void).
AST node: `Expr.useHook { inner }`. `@Context<Base>` is the owner MARKER a type
implements (`type Element(…) implement @Context<ElementBase>`); the `use`
wrapper is one, `@Component<C, T>` (decision 128), activated by writing it as
the return (`EffectKind.component`): a hook returns any `T`, a
component returns an owner at its own base (`T: @Context<C>`, `isComponentType`).

- Only a `-> @Component<C, T>` body activates: `FnContext.annotated` and
  `env.inContextFn` are one flag, set by that return and by nothing else
  (decisions 104, 118 — decisions
  89/90 and their `unwrapContextOwner` / `isWrapperEffect` are deleted). A
  `use` elsewhere is `useWithoutContextEffect` (`use-without-context-effect`,
  RC7), located at the `use` and naming the fn and its return type — checked
  first, so a `-> @Task` body and a plain `-> string` body get the same
  refusal. A `use` inside a nested closure is the same code: a lambda clears
  `env.starFn`, and `use`, like `await`, is not inherited.
- `inferFnDecl` refuses a component whose `T` owns a context at a base other
  than its `C` (`effect-wrapper-mismatch`, located at the return type); any
  other `T` is a legal hook return (decision 128); `@Component<T>` with one
  argument is an arity error (`builtinRequiredGenericArgs`). A bare owner
  (`-> Element`) is an ordinary return that activates nothing.
- The base is READ, never unwrapped (`contextInfoFromReturn`): the `C` of
  `@Component<C, _>`, for a hook and a component alike.
- The operand is a hook: `validateUseBase` reads `hookBaseOfType` (`C` of a
  hook's `@Component<C, _>`); a component operand is refused (a component is called),
  anything else is `useNotContext`. Every `use` in the body shares the base
  (decision 96: `contextMismatch` against the declared base at the first `use`,
  `contextBaseMixed` at a later one). The prefix is typed as `T`
  (`bindingSourceType`).
- `await` accepts `@Component<C, T>` too (`unwrapTaskType` → `T`):
  every caller awaits a component (decision 104).

`contextBaseFromImplements` computes `TypeDef.contextBase` from the marker.
`val {v, s} = use …` binds leniently via `bindUseDestructure`; `val #(a, b) =
use …` (front 19 step 3) binds each name to the element of a tuple `T` at its
position, commits an unresolved `T` to a tuple of the pattern's arity, and
refuses another arity or a non-tuple `T` at the binding (`useTupleArity` —
`use-tuple-arity`, decision 67).

Codegen lowers `use f(x)` to `f(x)` on erlang, wasm and beam and to
`await f(x)` on commonJS, where every `@Component` body is an `async function`
(decision 104). Phantom `@Context` base structs are erased — see
`codegen/AGENTS.md`. Documented for users in `docs.md` § *use — imports,
activation, and hooks*.

## `return` checking (06 C1)

Every `return <value>` unifies with the body's **return target** (`env.returnTarget`), located at
the value:
- a fn with a declared return type → that type; a type guard (`-> x is T`) → `bool`, which is also
  what its signature and every call of it are typed as (06 C5: `T` lives in `FnDecl.typeGuardType`
  and narrows the argument in the branch the guard proves — `env.typeGuardFns` is filled from that
  slot; before C5 `T` sat in `returnType`, so the call was typed `T` and the narrowing at the `if`
  was unreachable);
- an effect body → the wrapper's value layer (decision 119): `@Result<R, E>` → `R`,
  `@Task<T>` → `T` and `@Component<C, T>` → `T` — `U` when that `T` is `@Result<U, E>`;
- a lambda → its expected return type, else a fresh var shared by its `return`s; a trailing
  lambda (`@block { … }`, `use memo { -> … }`) owns its `return`s too, and `@block` is typed as the
  value they carry;
- no declared return type, a template fn (`-> @Expr<…>`), a sequence body (`@Iterator` /
  `@Stream` that yields: `return <expr>` is `iter-mixed-yield-return` there, decision 123) → unchecked.

A value that already is the declared wrapper (`return state(start)` in a `-> @Component<B, X>` hook,
a `@Result` passthrough, `try` / `catch` forms) unifies with the whole declared type or
is left alone. A named type returned where the fn declares a behavior it implements is accepted.
Body annotations resolve the fn's generic params (`env.fnGenericMap`). A bare `return;` unifies
with `void` in a fn with a declared return type.

## `Children` coercion

- The anonymous record type `{ f: T }` and literal `record { … }` left the
  surface in front 12 step 4 (they are tuples, decision 8 §6); `Type.record`
  stays in the type model for the structural types inference still builds.
- `childrenCoercion` (checked in `unifyAt`, target-first) lets an argument bind
  to a `Children` parameter when it is `Children`, any array, a `string` (text
  child), or a single `@Context` value (one-element list). One-directional.
- A function-typed record field (`set: fn(next: T)`) is an ordinary `Type.func`
  field.

## `@emit` fallback bindings (06 N23)

When a decorator `@emit`s code, the spliced re-analysis does the full inference. If it fails, the
binding list handed back is built tolerantly from imports, type declarations, `fn` signatures **and
`val`s**: a decl that fails to infer (a `val` referencing a generated decl) contributes nothing, a
well-typed one binds, so the language server still lists it.

## `unknown` (decision 8 §2, 1.0.4's 06 N19)

`unknown` reaches inference as `TypeRef.named` under the reserved spelling `ast.unknown_type_name`;
the lexer makes it a keyword and `isReservedWord` refuses it as a user name, so no source can mean
anything else by it. `Env.resolveTypeName` answers it before the two-pass `pendingTypeNames` walk —
it is a type the compiler owns, not one a module declares, and a located annotation (`-> unknown`)
would otherwise be reported as an undeclared name.

§2.1 is `unify.zig`'s one-way rule (above). §2.2 — what an `unknown` value does **not** answer — is
`infer.zig` `refuseUnknownUse`, called at four sites, because each of them has a permissive tail that
would otherwise accept silently:

| Use | Site | Why it needed its own refusal |
|---|---|---|
| arithmetic `- * / %` | `requireNumericOperand` | it returns early for any name it does not know to be non-numeric |
| `+` | the `.add` arm of `inferBinaryOpExpr` | `+` also concatenates, so it never went through `requireNumericOperand` |
| `<` `>` `<=` `>=` | the ordering arm of `inferBinaryOpExpr` | §2.2 names only `==` / `!=` as allowed; an ordering comparison reads the value's magnitude exactly as `+` does |
| a field read | `inferIdentifierExpr`'s `identAccess` | no typedef answers `unknown`, so the member fell through to a fresh variable |
| a method call | the receiver path of `inferCallExpr` | the same permissive fresh-var tail 06 C9 left for imported and wrapper types |

`@print(x)`, `x == y`, `x != y`, assigning to another `unknown` and passing to a generic parameter
stay allowed, and each reaches inference by a path this is not on.

§2.4 — a `pub val` with no written type whose inferred type contains `unknown` is refused at the
value (`refusePublicUnknown`, both the typed and the untyped `.val` arm); a written `unknown`
(`pub val v: unknown = …`, `pub fn parse(s: string) -> unknown`) checks. A `fn`'s return type is
written, never inferred (§1.1), so the rule has no `fn` half: an unannotated `fn` is `void`.

§1.4 — a binding born as an unannotated `[]` (`var out = [];`, local or module-level) is recorded in
`Env.birthWarnings` and, once the module is inferred, becomes a **warning** naming the annotation to
write with the element type the program settled on — `var out: i32[] = [];`, or `unknown[]` when
nothing did (`flushBirthWarnings`). The rest of §1.4 — a type argument decided only where the value
is born, later uses never changing it (`val z = Option.None;` → `Option<unknown>`) — is not built:
it would turn a use that pins a variable today into an error, across the libraries.

## The warning channel (decision 57)

`Env.warnings` is a list of located `TypeError`s that do not stop the compilation; `Env.warn` adds
one (a warning already recorded at the same location with the same text is not repeated — the
untyped and the typed pass may walk one expression twice). `comptime.zig` surfaces the list as
`OkData.warnings`, and `botopink check` renders each like an error under `warning:`
(`compiler-cli/src/cli/diagnostics.zig` `renderOutcome`); `build`, `test` and the language server
do not print them yet. Writers: §1.4's `flushBirthWarnings` and §4.3's `warnAlwaysFalseIs`.

## union types (decision 8 §3, 1.0.4's 06 N20)

`A | B` reaches inference as `TypeRef.generic` under the reserved name
`ast.union_type_name` (`"|"`), members as arguments, read back with `unionMembers()`.
`resolveTypeRefInContext` builds a real `T.Type.union_` from them, so a union annotation is a union
type and no longer a nominal type spelled `|` ("expected |, got i32").

Construction always goes through **`unionOf`** / **`finishUnion`**, never `Env.unionType` directly,
so every union in the checker is normalised the same way:

- `appendUnionMember` flattens a nested union (`(A | B) | C` is `A | B | C`) and drops a duplicate
  by `sameTypeShape` — a structural, **non-unifying** comparison, because a probe that unified would
  leave the alternative it rejected linked and there is no way to roll that back. An **unbound**
  variable is not a distinct alternative: it unifies with what is already there, so a union never
  carries a `?` member that says nothing.
- `finishUnion` collapses a one-member union to that member and applies §3.2's **optional
  absorption**: an optional member makes the whole union optional over the union of its inner type
  and every other member, so `if (c) { 1 } else { null }` is `?i32` and — recursively — `?A | ?B` is
  §3.4's `Option<A | B>`.
- **No other head joins.** §3.4 also lists `Box`, `@Result` and `Dict`, but a join is sound only
  when the type's parameter is *read* and never written: joining `Box<i32> | Box<string>` would let
  a `set(v: T)` store a `string` in what is really a `Box<i32>`. The "only read" member-signature
  walk is not built; those members stay side by side, which refuses more than §3.4 and is never
  wrong. Arrays never join — that is §3.4's own rule.

`unify` treats a union one-way, as it does `?T` and `unknown`: a **member** is assignable to the
union, and the union to a member only after narrowing. `memberAccepting` picks the target member by
shape (never by trial unification, for the reason above); a member still unbound accepts anything.
Union-to-union asks that every member the value may be is one the target accepts — the target may be
wider, never narrower. The arity-for-arity walk this replaced could only accept a union written in
exactly the same member order.

§3.2's inference sources: a `case` (`caseTypeFromArms`, already there since 06 C2a) and an `if`
whose two branches both produce a value and disagree — that is a union now, not an error. Branches
that agree still unify, so one branch pins the other's variables exactly as before.

§3.3's use rule is `refuseUnknownUse`, shared with §2.2 (see above): a union receiver is refused at
arithmetic, `+`, an ordering comparison, a field read and a method call. §3.3 allows a use every
member allows; deciding that means re-resolving the operation once per member, which is not built,
so the refusal is total — more than §3.3 asks, and never wrong. §3.2's two-location diagnostic (the
use **and** the branch that widened it) is not built either: `TypeError` carries one `Loc`.

`error.zig` `typeLabelAlloc` spells a union out as `A | B` in a mismatch message; every other kind
is `typeLabel`'s own text, so a message that goes through it renders byte-identically to one that
does not.

**Gap, not owned here:** `(i32 | string)[]` does not parse — a parenthesised type is not in the
grammar, so §3.1's "array of the union" has no spelling. `i32 | string[]` binds as `i32` or
`string[]`, which is right.

## `x is T`, and narrowing (decision 8 §4, 1.0.4's 06 N21)

The parser lands `x is T` as the `is` builtin call (`ast.is_builtin_name`) with the value as its
only argument and the tested type in the call's `isType` slot. `inferBuiltinCallReturnType` had no
arm for the name, so the call was typed `void` ("expected bool, got void"). It is intercepted
**before** that function now, because the slot it needs is on the AST node and not among the typed
arguments, and the typed node it builds **carries `isType` forward** — the four backends lower their
run-time test from it.

§4.3 is `warnAlwaysFalseIs`: `a is string` on a value whose type is one concrete head — a
primitive or a declared `type` — that the tested type cannot be is a **warning** (the program still
checks). `unknown`, a union, an optional and a behavior are what `is` exists to test and never warn;
numbers are tested by range (§4.1), so a number tested against another number type never warns
either. A dotted tested name (`Token.Text`) and a name the module does not know are left alone.

§4.2 is `checkIsTestableType`: a primitive, a named type's constructor and a tuple are testable as
they are; a generic type is testable only applied to `unknown`. `Box<i32>` is the section's own
error — a run-time test can see that a value is a `Box` and cannot see what is in it, so
`Box<i32>` would be a promise the test does not keep, while `Box<unknown>` says exactly what it can
answer. Each member of a union is checked in turn.

Narrowing has one channel, not two: `if (x is T)` writes into the same channel C5 built for the
type-guard fn form (`-> x is T`), so the branch rebinds the name exactly as a guard call does. Only
a plain **name** narrows — narrowing is a rebinding, and there is nothing to rebind for `f().x` or
for `o.inner`.

The channel is a **list** (`CondNarrowing`, one entry per name, with the type the name takes on each
SIDE of the condition), not the single `guardArgName` / `guardNarrowedType` pair it started as. One
slot could only ever narrow the last name a condition tested, and `if (a != null && b != null)`
tests two.

## The null test narrows (`x != null`, `x == null`)

The form a reader reaches for first, and the one that did not narrow at all: `if (first != null)`
did not rebind `first`, so the body still saw a `?Record`, a field read off it was a fresh type
variable, and commonJS — which needs the receiver's type to know `.length()` is JavaScript's
`length` PROPERTY — emitted a call on a number (`TypeError: first.key.length is not a function`,
exit 1) where erlang, needing no receiver type to lower a primitive method, printed `3`. Four
library fronts of this milestone wrote `.at(i) ?? fallback` or an annotated `val` around it and
recorded a local gotcha instead.

`collectCondNarrowings` reads the condition and answers the list above. The leaf is the null test in
either operand order (`x != null`, `null != x`, and the two `==` spellings); the combinators take
exactly one side each, which is the whole of their rule:

| Condition | Narrowed where | Why |
|---|---|---|
| `x != null` | the then branch | it holds only when `x` does |
| `x == null` | the **else** branch | the mirror; the negative form is one field, not a second mechanism |
| `a && b` | then, both halves | `&&` holds only when both do. Its failure names neither half, so an `&&` narrows nothing on the else side |
| `a \|\| b` | else, both halves | `\|\|` FAILS only when both fail — the shape `if (a == null \|\| b == null) { return …; }` needs |
| `not a` | the two sides swapped | — |

A name whose type is not an `optional` is skipped rather than refused (`optionalPayloadOf`): `x !=
null` on a non-optional is a comparison this rule has no opinion about, and an unresolved type
VARIABLE is an inference gap that must not be narrowed to a guess.

**The guard clause outlives its `if`** — `if (x == null) { return …; }` and then the rest of the
block. That is not a branch narrowing, so it is not `inferBranchExpr`'s: `narrowAfterEarlyExit` is
applied by the statement walk, for an `if` with no `else` whose then-branch cannot fall through
(`stmtsAlwaysExit` — a `return`, `throw`, `break` or `continue` in tail position), and it is
restored when the block ends. Only a **`val`** narrows this way: a `var` can be assigned below the
guard, and a narrowing that outlives the statement would carry a type the name no longer has. A
narrowed `val` stays a `val` (`bindNarrowed`), or decision 38 would stop refusing it as an
assignment target.

Three statement walks had to agree, and each was its own `for` loop: `inferStmtsTyped` (branch
bodies, loop bodies, lambda and trailing-lambda bodies, `comptime` blocks) and `inferBodyStmts`,
which is the shared walk a plain `fn`, a record method and a `test` block now go through for exactly
this reason.

**What does NOT narrow**, each measured rather than assumed:

| Shape | Today |
|---|---|
| `if (x)` on a `?T`, no binder | refused — "type mismatch: expected bool, got optional". There is no truthiness on an optional; `if (x) { v -> … }` is the form (`reject/if_optional_needs_a_binder.bp`) |
| `while (x != null) { … }` | the body is NOT narrowed. A condition loop's whole point is that the body reassigns the name it tests (`cur = es.at(i)`), and a narrowed `cur` would red that assignment — narrowing the body would break the programs that work today. `?string` and `?T[]` bodies run anyway, because the `.length()` rename unwraps one optional layer by itself; a `?Record` field read in one is still a call on commonJS |
| `o.inner != null` | only a plain NAME narrows, above. `o.inner.v` answers on commonJS and erlang today, by accident: nothing the rename touches is on that path |
| `case x { null { … } v { … } }` | narrows already, and not through this channel — a 1-parameter arm binds the whole matched value narrowed by its own pattern (§ `case` and `comptime` block types), which is why the `null` arm leaves `v` the payload |

**Not implemented.** §4.3 (`a is string` on a statically-known `i32` is a *warning*, always false)
needs the warning channel `comptime/**` does not have — the same gap §2.4 and §1.4 hit. §4.1's
"an integral `f64` is converted to the tested integer type inside the block" is each backend's
run-time half. D4 (whether `is` grows a payload pattern) stands as the parser left it: the located
`is-variant-binding` refusal, with `case` the only reader of a payload.

## a record is immutable (decision 37)

`p.age = 31` and `self.count += 1` both checked and both mutated in place. The decided form is a new
value — `Person(..p, age: 31)` — which the constructor's `..` spread already builds (06 C11), so
`refuseRecordFieldAssign` (the `.fieldAccess` target of the `.assign` walk) reds at the assignment
and spells that form out, naming the receiver when it is a plain name it can spread.

Only a receiver whose type is a record **this module registered** is refused. Everything else keeps
assigning, for the reasons 06 C9 left its own fresh var: a receiver still an unresolved type
variable is an inference gap, and a named type the env cannot open — an imported record, a wrapper,
a host object a library binds — is not something this rule can speak for.

Measured on this HEAD: zero occurrences in `libs/std`, in the three `examples/` projects and in the
eleven `test-libs` cells, so the rule cost no migration. The one occurrence the 1.0.5-beta spec
predicted would move, `snapshots/codegen/**/field_assign_self_field_update.snap.md`, **does not**:
its fixture writes the types-as-values surface (`val Counter = type(count: i32 = 0) { … }`), where
`self` is never typed as `Counter` and the typedef is not registered, so nothing here reaches it.
That is R8 / types-as-values A1's ground, not decision 37's.

## `case` and `comptime` block types (06 C2)

A `case` is typed from its arms (`caseTypeFromArms`): arms that agree unify, arms of different
types make a union (decision 8 §3.2). A jump arm and a `void` arm contribute nothing.

**An arm body is a lambda BODY, not a lambda value** (decision 8 §5.1 P3). `Pattern { body }` lands
as the same lambda node the older block arm produced, so `caseArmValueType` reads it as one: a
top-level `break <value>` names the arm's value and wins, and otherwise the body's **tail
expression** is the value (a jump tail contributes nothing, §3.2). Before this only the `break` half
was read, and only for a 0-parameter lambda — `0 { "zero" }` contributed nothing at all and the
`case` typed `void`, while `_ { n -> … }` was unified against a `function`. `isArmBodyLambda` is the
0-**or**-1-parameter test, so both forms keep the enclosing fn's return target
(`env.keepReturnTarget`).

**A 1-parameter arm binds the whole matched value, narrowed** (§5.1 P1/P5). `inferCaseArmBody`
passes the subject — narrowed by that arm's own pattern — as the expected parameter type of the
body lambda, so the body resolves methods and operators against the real type rather than a fresh
variable. A **type pattern** (`i32 { n -> … }`, §5.2 — `typePatternType`) narrows the binder to the
tested type; every other pattern leaves the subject's own, which is P5's answer for them, the
payload bindings having already come from `bindPatternNamesForSubject`.

**A variant path resolves to its last segment** (§5.1 P8 — `bareVariantName`, `isVariantPath`).
`.Circle`, `Shape.Circle` and `Maybe.Some` all reach inference as written, because the leading `.`
is what tells a variant path from a binding; every variant table here is keyed by the bare name, so
the written form matched nothing and every variant read as missing. A name carrying a `.` is never a
catch-all either — a path that names no variant of the subject is a mistake, not a binder.
`codegen/erlang.zig` keeps a twin of the same rule (`variantTag`).

Pattern bindings are typed (06 C8, `bindPatternNamesForSubject`): a binder is the subject type; a
variant payload binding takes the variant field's type instantiated against the subject's generic
args (`variantPayloadTypes`; `@Result<R, E>` `Ok` → R, `Err`/`Error` → E; `?T` `Some` → T); list
elements take the element type and the spread the array type; an OR pattern unifies a name across
its alternatives. An unknown subject type leaves the bindings fresh. A `comptime { … }` block is
typed as its `break <value>`, `void` without one.

A section of an enum-shaped `type` is a type named by its path (06 N28, decision 8 §5.3b):
`Token.Text`, `Token.Text.Size` resolve in type position through `Env.resolveTypeName`, which
mangles the dotted path to the `__Token__Text` name `registerEnumSection` files the typedef under.
The parser carries the dotted spelling in `TypeRef.named` (`parser/types.zig`). The pre-decision flat
spelling (`TokenText`) reds with a hint naming the path (`Env.sectionPathForFlatName`). A section
declares no methods — `EnumSection` has no slot for them and nothing needs one yet.

## The three N25 diagnostics, located (01 R9)

- (decision 118 removed `effect-missing-annotation`: a `-> @Result<…>` return is the effect.)
- `val assert Ok(n) = f() catch 0;` is "after `catch` the value is not a @Result", with the caret on the
  `catch` — `AssertPattern.catchLoc`, set by the parser and left out of the AST dump.
- A removed effect annotation (a parse error, `parser.zig` `parseAnnotations`) puts the caret on the
  annotation's name, not on the body's `{`.

The `reject/` cells `wrapper_without_annotation`, `val_assert_after_catch` and `two_effect_markers`
pin all three.

## Type aliases (decision 118 rule 1)

`[pub] type Name<A, B> = Target;` parses to `DeclKind.typeAlias` (`ast.TypeAliasDecl`). An alias
is a **transparent** name, never a typedef and never a value:

- **Scope.** `Env.typeAliases` (name → decl). `registerTypeAliases` puts every alias of the module
  in scope **before** any `type` registers (a field may name an alias declared further down), then
  resolves each target once at `targetLoc` — unknown names go through `pendingTypeNames` like any
  annotation. An imported alias arrives through `registerTypeDecl` (the `from "std"` type export,
  `registerImportedTypeDecl`); `registerAliasClosure` brings the types its target names, as types
  only (01 R2). `registerExports` puts a `pub` alias in the type-decl registry and never in the
  value exports; `import {Parser as P}` is refused like any type (`import-alias-on-type`).
- **Substitution.** `resolveTypeRefInContext` expands `Name` / `Name<args>` (not a generic param
  of the scope) with `expandTypeAlias`: each argument resolved in the caller's generic map, the
  target resolved in a map holding only the alias's own parameters. Arity must match exactly —
  a bare generic alias too — or `type-alias-arity`; an alias met again while it is on
  `Env.aliasExpanding` is `type-alias-recursive`. `checkTypeAliasDecl` (pass 2) refuses a name a
  typedef or primitive has (`type-alias-name-taken`); the typed binding carries the target's type
  for hover and the `.d.ts`.
- **What the effect checker reads.** The AST keeps the alias as written: `FnDecl.returnType` of
  `fn f() -> Parser<i32>` is `generic{ name = "Parser" }`. `Env.aliasedWrapper(ref)` answers
  `{ .alias = "Parser", .wrapper = "Result" }` when `ref` goes through an alias (followed through
  aliases of aliases) that ends at a builtin `@Wrapper<…>`, and null for a literal wrapper or an
  alias of a plain type. `effect-wrapper-behind-alias` (front `24-effects-by-return`) is: the
  body uses a capability and `aliasedWrapper(returnType) != null`. An alias on a function that
  uses no capability is legal — it only passes a value along.
- **Backends.** `alias_erase.erase` runs on the transformed program (both `comptime.zig` sites):
  every `TypeRef` naming an alias becomes its target, except a declared return that ends at a
  builtin wrapper, which keeps the alias name (its arguments erased) so no backend lowers it as
  an effect. The `.d.ts` emits a `pub` alias as `export declare type Name<T> = …;`.

## Importing a type brings its type closure (01 R2)

`import { User } from "users"` where `User(role: Role)` used to red `unknown type 'Role'` until `Role` was
named too. `comptime.zig`'s import loop now calls `registerImportedTypeClosure` before
`registerImportedTypeDecl`: the types the declaration mentions — field, variant-field and method
signature types, transitively, from the module the import names — are registered as **types only**
(the constructor and variant bindings their registration adds are removed again), so naming a type
in the clause is still what brings its constructor into scope: `Role(name: "x")` stays unbound. A
name the module does not declare is left to the ordinary unknown-type diagnostic. Cell:
`tests/language/modules/import_type_closure`.

## A behavior's associated fn through its own name (01 R6)

`Array.range(0, 3)` resolves through `registerInterfaceAssociatedFns`' `Array.range` binding even
though `Array` itself is bound (a function-typed binding in std): the guard that keeps a value of the
same name on method dispatch now lets a behavior's own, non-`val` name through. The call types as
`array<i32>`, so a method on its result (`.map`) records its primitive lowering — erlang emits
`lists:map(…, array_range(0, 3))` instead of the `'__bp_prim_map'` run-time helper. Cell:
`infer_errors.zig` `associated fn: …`.

## A type position takes a type, not any binding (01 R8)

`Env.resolveTypeName`'s bindings arm used to answer any binding's type, so `val n = 5; val x: n = 7;`
checked. It now accepts four kinds of binding only: one of function type (an imported constructor —
the reason the arm exists — and std's `Array`, whose return is `array<T>`), a declaration's own binding
(typed by the declaration's display name, `behavior Request { … }`, which holds a space no value's
type can), a primitive (bound to itself by `registerBuiltins`), and a `val` recorded in
`Env.typeValueNames` — `noteTypeValue` marks `val T = i32;` / `val U = T;` when the value is a name
that is itself a type, and clears the mark when a value shadows it. Any other binding — a value — is
`'n' is a value, not a type`, located at the `val` (a local)
or the value (a module `val`), since neither carries its annotation's location. The location is added
after the fact by `locateTypeRefError`, not through `typeRefLoc`, which would also enter every
unresolved local annotation into C10's pending list. Cells: `infer_errors.zig` `type position: …`.

## A behavior-typed parameter or field accepts an implementer (01 R4)

An argument meets its parameter through `unifyArgument`: a parameter — or a record constructor's
field — whose type is a behavior accepts a value whose type `implement`s it, directly or through the
behavior's `extends` chain (`behaviorReaches`), and everything else goes to `unifyAt`. The same
`behaviorCoercion` already served `return` of an implementer from a `-> Behavior` fn. The coercion is
target-first and only widens (implementer → behavior); a record that does not implement the behavior
reds at the value. Cells: `infer_errors.zig` `behavior-typed field …`.

## A call whose callee is an expression (01 handover 15, front 15's handover)

`adder(3)(4)` and `.Circle(radius: 1)` both reach `inferCallExpr` with `callee == ""` and the callee in
`calleeExpr` (the parser's chain link). Two readings, decided in that order:

- **a leading-dot head** (`.dotIdent`) is the variant constructor the dot names. The expected type of
  the position (`val s: Shape = …`, a typed parameter, a typed array's element) must be an enum
  declaring the variant; the call is then typed as `Shape.Circle(…)` and that untyped call is
  recorded in `env.indexRewrites`, which the transform splices in — so no backend learns the shape.
  With no such expected type it is a located refusal naming the two spellings that work (decision 67
  — no guess by bare variant name). `inferExprTyped` keeps the expectation alive for this one call
  shape (`isLeadingDotCall`) and `inferCallExpr` clears it before the arguments.
- **anything else** is a function value: `calleeExpr` is inferred and must be a `fn` taking the
  written arguments; the call's type is its return, and a count it does not take is an arity error
  at the `(`. The typed node keeps `calleeExpr`; lowering it is each backend's (C-09's backend half).

## `val <Pattern> = <expr>;` — a pattern in binding position (01 R5)

`val Circle(r) = s;`, `val Person(name, age) = p;` and `val [..rest] = xs;` bind through
`bindDestructPattern`, which runs the `case` arm walk (`bindPatternNamesForSubject`) typed by the
subject and leaves the names in the enclosing scope — as `val`s unless the binding is `var`.

**The failure behaviour is decided: a pattern that can fail does not check.** The bare form has no
failure path of its own, so it is accepted only where the pattern matches every value of the
subject's type: the one variant of a one-variant `type`, a record's own constructor (all binders, or
fewer with `..`), a list pattern that is only a spread. Anything else — a variant of a many-variant
`type`, a list pattern with elements, a subject whose type is not known yet — is
`refutable-val-pattern` at the binding, whose hint names `val assert <Pattern> = e;` (a fatal
mismatch) and `case`. No bypass (decision 67), and nothing is left for a backend to decide: every
program that checks destructures without a test. The cells are `infer_errors.zig`'s
`val destructure: …` tests.

## `val assert <pattern> = <expr> [catch <handler>]` (06 C12, decision 8 § 9)

The subject and the handler are inferred like any other expression. Both used to swallow
`error.TypeError` into a fresh type variable, so a subject naming nothing compiled and only failed at
run time — beam aborted with `{unresolved_identifier, …}`, erlang did not compile the emitted module,
wasm trapped. They no longer swallow: an unbound name reds at the name.

**The pattern binds, in the enclosing scope.** `inferComptimeExpr` runs
`bindPatternNamesForSubject` — the same walk a `case` arm uses — and deliberately drops the
snapshots that walk collects, so `val assert Ok(n) = parse("42"); @print(n);` reads `n: i32` in the
statements after it. Before this the construct bound nothing at all and every name in a pattern was
`unbound variable`.

**The handler-less form is the one that asserts a variant.** `val assert Ok(n) = parse("42");` (a
failure being a fatal assert) parses: `parser/exprs.zig` `assertFatalHandler` desugars it into the
handler `@panic("assert pattern did not match")` and records `AssertPattern.fatal = true`. The AST
therefore keeps ONE shape, every backend's existing handler lowering already emits the fatal path,
and the flag is only what lets the checker tell the two forms apart. The `assert-pattern-missing-catch`
parse error it replaces is gone.

`checkAssertPatternSubject` reds two things. A `@Result` subject with a written `catch`
(`val assert Ok(n) = parse("42") catch 0;`) — decision 8 § 9's own error: `catch` already yields the
success value, so the pattern would be asserted against the unwrapped one. And a variant pattern
naming no variant the subject's type can hold, when that type is a scalar the env knows holds none;
an unregistered name stays permissive (a forward reference, an imported type).

`throw` carries the error channel's own value (`throw "empty"`), not a constructor — `Error` is
bound to nothing.

## Unknown type names (06 C10 + N30)

An annotation naming a type nothing declares **reds, at the annotation**. Resolution is two-pass
because registration walks the declarations in source order: `Env.resolveTypeName`'s last arm records
the name in `Env.pendingTypeNames` with the annotation's location and still answers an opaque named
type, and `Env.checkPendingTypeNames` — called at the end of both `inferProgram` and
`inferProgramTyped`, after every declaration is registered — reds on what is still unknown. A forward
reference (`type Outer(inner: Inner)` above `type Inner(…)`) therefore checks, and so do an imported
typedef (the constructor binding) and a `behavior` name in type position
(`Env.assocInterfaceDecls`). The list is cleared per program: `registerStdlib` infers one std module
per call on one env, and a name left pending by one must not red in the next.

Only an annotation the parser located enters the list. `Env.typeRefLoc` is set by
`resolveParamType` / `resolveFieldType` / `resolveReturnType` (infer.zig) from `Param.typeLoc`,
`Field.typeLoc` and `FnDecl`/`BehaviorMethod`'s `returnTypeLoc`; a resolution with none in scope is a
synthesised or re-entered one (a generic parameter resolved outside the context that binds it) and
stays permissive. Two names are compiler-known without a declaration and never red:
`Children` (coerced by `childrenCoercion`) and `Binding` (what `q.lookup` yields, the `ref` field of
the registered `CustomNode`). `noreturn` is a registered primitive (`Env.registerBuiltins`), the
declared return of `@panic` / `todo` / `trap`.

**Not covered yet**: a top-level bodyless `declare fn` parses as a `DelegateDecl`, whose signature is
never resolved — an unknown type in one is still accepted. A non-type *value* binding in annotation
position (`val n = 5; val x: n = 7;`) also still checks; it is
[types-as-values A1](../../../../specs/1.0.4-beta/06-checker/types-as-values.md)'s, which replaces the
bindings arm with a real `type` kind.

## `case` exhaustiveness + reachability

A match *into* a section (`Text(Bold)`) refines the arm: it never counts as covering the wrapper
variant, so the `case` still has to handle the section's other values or end in `_` (decision 8
§5.4). `variantPayloadIrrefutable` decides this — a payload name is a binder unless it names a
variant of the payload's own type.

`checkCaseExhaustiveness` (infer.zig) checks a single-subject `case` after the arms are typed, over
the **domain** its subject draws from (`CaseDomain`, `caseSubjectDomain` — decision 8 §5.4). It knew
two domains and returned before looking at an arm for anything else, which is why
`case x { 0 { … } 1 { … } }` on an `i32` compiled:

| Domain | Subject | Covered by |
|---|---|---|
| `enum_` | a `type` with variants | every variant |
| `union_` | `A \| B` (§3.3) | every member named by a type pattern (`sameNamedType`) |
| `open` | `string`, `i32`, `unknown` | `_`, or a type pattern naming the subject's own type (§5.4's "a type covered whole") — and `unknown` has no such pattern, so it always needs `_` |

- **Coverage** — an unguarded arm covers a variant when it is a bare variant
  ident or `Variant(payload)` with an irrefutable payload (bindings/wildcards).
  Refined payloads (`Ok(1)`) don't cover. OR-patterns cover each alternative.
  `patternIsIrrefutable` decides nested payloads: a tuple pattern of binders
  matches every tuple, so `.Some(#(a, b))` covers `Some` (§5.1 P6/P7). It used to
  answer `false` for every nested pattern.
- **Catch-all** — `_` or a non-variant identifier. A **type pattern is not a
  catch-all**: `case x { i32 { … } }` used to stand in for `_`.
- **Guards** — a guarded arm neither covers anything nor shadows later arms.
- **Diagnostics** — `nonExhaustive` (missing variants or members, or a wildcard
  request) and `redundantPattern` (arm after a catch-all, or a repeated variant).
  The message reads **`case` on '<T>' is not exhaustive: …**, the text
  `1.0.4-beta/MIGRATION.md:300` publishes for this rule (`not exhaustive`,
  `use _ {`); a union's uncovered entries read as **members** and an enum's as
  **variants** (`nonExhaustive.missingLabel`, `TypeError.nonExhaustiveOf`), and a
  union prints spelled out (`i32 | string`) because its identity *is* its members.
  `comptime/snapshot.zig` builds its own shorter title, so the error snapshots do
  not carry this text.

`open_case_domain_names` is **`i32` and `string` only** — the two §5.4 names by hand. `f64`, `bool`
and the sized integers are the same kind of unbounded domain, so
`case x { 0 { … } 1 { … } }` on an `f64` still compiles; widening the list is a language rule and is
reported rather than assumed. Measured: `test-libs` is 11/0 with `i32` in, so it costs no migration.

## Decision 8 §5.1 P7 — a variant pattern names every field, or ends with `..`

`checkCaseArmArity` runs beside `checkCaseExhaustiveness`, over the same single
subject. For an arm whose pattern is a written variant payload (`shape ==
.variant`, no `rest`, a resolvable declaration), fewer elements than the variant
declares is `missing required field '<name>' on type '<Variant>'` at
`arm.patternLoc` — the first field the pattern does not reach. The fields a
pattern does not name are dropped at run time, and `..` is the spelling that
says so; without the rule `.Rect(width: w)` silently dropped `height`.

A whole-payload binding (`Ok ok`) stands for the payload entire and is skipped,
as are the tuple and range shapes that ride the same node, and any variant whose
declaration the env cannot resolve. `variantPayloadFieldNames` is the lookup —
the names beside `variantPayloadTypes`' types.

## Decision 54 — an optional is matched by `null` and a binder

`case x { null { A } v { B } }` is the **one** pattern form a `?T` has, and it
is settled here because it is the subject's type that decides it. The parser
reads `null` as a pattern and lets a bare name follow it
(`parser/AGENTS.md` § decision 54); everything below is `infer.zig`'s:

| Function | What it settles |
|---|---|
| `isNullPattern` | the `.ident "null"` spelling the parser lands; `null` is a keyword token, so nothing else can carry that name |
| `optionalInner` | the `T` of a `?T` |
| `optionalNullCaseBinder` | the subject is an optional; the arms are exactly two, unguarded, `null` then a binder; neither body takes a parameter (§5.1 P1's whole-value binder means nothing where the binder *is* the payload). Answers the binder's name, `""` for `_` |
| `refuseVariantPatternOverOptional` | `.Some(v)` / `.None` — and any variant-shaped arm — over a `?T` is a located error naming the `null` form |

The binder is bound to the **payload**, narrowed, not to the optional, and the
exhaustiveness walk is skipped for the form: `null` and a binder are the two
halves of an optional, so it is covered by construction, and `null` is not a
catch-all the walk would count.

**The lowering is a rewrite, not a backend feature.** Inference records the
`case`'s loc and its binder in `Env.optionalNullCases`; `transform.zig`'s
`rewriteOptionalNullCase` swaps the whole node for
`if (<subject>) { <binder> -> B } else { A }` before codegen reads the AST. That
is a lowering all four backends already have, so no code generator learned a
pattern — and the formatter, which reads the parser's AST, still writes the
`case` the author wrote. Inference decides, the transform edits, codegen is told
nothing new.

## The inline `implement <Behavior> { }` is checked (decision 58)

`validateProgram` collects the program's behaviors and then validates **both** implementing forms.
It used to visit only `.implement` decls: `TypeDecl.implement: []TypeRef` was never read, so
`type Money(cents: i32) implement Display { }` checked with `Display` declared in the same file, and
with the long-registered `Generator` too — the inline clause asserted that the type satisfied the
behavior and nothing verified the assertion. Only the separate block was covered (the
`implement_missing_a_required_interface_method` snapshot family).

`validateInlineImplements` runs the same coverage rule as `validateImplement`: for each behavior the
clause names **and this program declares**, every method the behavior declares with no body must be
provided. A `default fn` carries its own body, so implementing it is optional. Provided means either
a member of the type's own body that has a body (`typeDeclProvidesMethod` — a `declare fn` member is
an abstract slot typed from its signature and provides nothing), or a member of some
`implement <Behavior> for <this type>` block in the same program, unqualified or qualified with that
behavior (`separateImplementProvides`); writing both halves is legal and the inline clause is what
names the contract.

**The blind spot both forms share**, and it is deliberate: an interface this program does not declare
is skipped, so the ambient `Display` from `libs/std` is unchecked in the inline form exactly as it is
in the block form. Closing it needs the interface-member registry, and doing it here would red every
implementation the registry cannot open.

## A type-qualified call to a type's own method (decision 62)

`Counter.zero()` — a call to an **associated** fn of a registered type, through the type — came back
a fresh type variable. The signature was already there: `registerInherentMethodTypes` stores every
method of a `type` under `inherentMethodTypes[<type>][<method>]` with `Self` resolved to the type,
associated ones included. Nothing read it for the type-qualified form, only for
`recv.method(args)` (`methodCallReturnType`).

`associatedCallReturnType` reads it, instantiated fresh per call site so the type's shared generic
cells never collapse across two calls. Unlike the instance form there is no receiver to unify `self`
against: every declared parameter lines up with an argument, so the arity must match exactly.

What that fixed is two backends, not the checker's own answer: `val c = Counter.zero(); c.bump()`
recorded no `env.instanceLowerings` entry for `bump`, because `c` had no nominal type for
`resolveReceiverCall` to read. beam emitted `{unresolved_method, bump, 1}` through `erlang:error/1`
and wasm trapped on `unreachable`, while commonJS and erlang were right because neither needs the
type. And the checker now answers what it was silent on — `val s: string = Counter.zero();` reds.

Deliberate limits, both the instance form's existing policy: no signature is read when the method
carries **no return-type annotation** (none is stored, and the true type comes from body inference,
which is not available at registration), nor under a trailing lambda, nor on an arity mismatch —
the plain-call path owns that diagnostic.

## A `for` parameter binds the ITEM (decision 8 §10, decision 105)

`inferLoopExpr` bound every parameter of a loop to `env.freshVar()` with no link to what was
being iterated, so nothing inside the body had a type — and nothing derived from the parameter did
either: a field read off it, a `val` bound from it, a chain starting at it.

What that cost was one backend, not the checker's own answer. commonJS records the `.length()` →
native `length` PROPERTY rename only for a receiver inference resolved as a named `string` or
`array`, so an untyped receiver kept its call parens and the emitted module called a number:
`for (xs) { x -> x.length() }` over an `Array<string>` was `TypeError: x.length is not a function`
at exit 1, while erlang — which needs no receiver type to lower a primitive method — printed the
length. Measured by a consuming library while it wrote a configuration reader; pinned by
`tests/language/run/loop_item_method.bp`, which asserts the VALUE.

The parameter binds the collection's element: `array` gives its type argument, a generator
`@Iterator<X>` its `X` (decision 122: a `@Result` stays a `@Result` — no implicit `try`), a `Range` gives `i32` (§10
counts a range in integers; `a...b` is the same node with `inclusive` set), `for await` keeps the
`@Stream<T>` item it already resolved, and an iterated expression still a type variable
keeps the fresh one, where a fresh one is exactly right. There is no second parameter since decision
105: the index is `for (0..xs.length) { i -> }`.

## `.length()` through ONE optional layer

The `.len()` / `.size()` / `.length()` → native `length` PROPERTY rename (`env.jsMethodRenames`,
read only by commonJS) fires on a receiver whose type is the named `string` or `array`. A `?string`
is neither, so `xs.at(0)?.length()` and `es.at(0)?.key.length()` kept their call parens and the
emitted module called a number — `TypeError: … .length is not a function`, exit 1, where erlang
printed it. The rename now also unwraps one `optional` layer, and ONLY the rename does: nothing
else about an optional receiver is treated as a primitive one, so the call's own type is still
whatever the branches below it give it. `?string` and `?array` are the only families that qualify,
and `.length` is the same answer for either with or without the `?` — a null value throws on the
read exactly where it threw on the call.

**The gap this did not close is closed**, by narrowing rather than by this rename: a field read off
a `?Record` receiver was a fresh variable, because the member-access path finds no `TypeDef` for
`optional` and `if (first != null)` did not rebind `first`. It does now (§ The null test narrows),
so `val first = es.at(0); if (first != null) { first.key.length() }` answers `3` on commonJS,
erlang and beam. What is still this rename's and not narrowing's: a receiver that stays an optional
because no test was written — `xs.at(0)?.length()` — which is what the unwrap above is for.

## Enum sections

`registerEnum` desugars an enum `TypeDecl`'s `sections()` into enum-of-enum form: each section
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
typed against the parent enum. A chain rooted at a plain `.ident` is a section
path too when that identifier names an enum and at least two segments follow it
(`Token.Color.Red.500`, 00 · 01-checker): the root IS the owner, so the path is
resolved in that enum alone — no candidate set, no expectation read, and a
chain that does not resolve is handed back to the normal identAccess path
(which is also where the two-segment `Color.Red` variant access stays).
`buildSectionPathRewrite`
builds the equivalent untyped ctor chain into `env.enumSectionRewrites` (keyed by
the outer identAccess loc) and `transform.zig rewriteExpr` substitutes it;
synthesised nodes carry loc `{line=0, col=0}` so the rewrite is not re-triggered.

**Which enum carries the path is the expected type's answer** (00 · 01-checker).
`env.typeDefs` holds the synthesised section enums beside the declared ones, so
more than one enum can carry one path — emilia's `Token` and its own
`__Token__Border` both carry `Color.Red.500`. The resolver used to return the
FIRST hit of the `typeDefs` iterator, which made the answer a function of the
map's hash order: it changed with the number of enums in the program and took
six declared cells out of reach in every spelling. So `enumCarriesSectionPath`
(the predicate form of `resolveSectionPathInEnum` — the two walk the same steps
and must keep agreeing) collects every carrier, and `expectedEnumAmong` picks
the one `env.expectedType` names (through one `?T`). `env.expectedType` is a
hint and never unified from here: `inferExprTyped` clears it for every node but
an identifier chain and an array literal, and the sites that know a position's
type set it around that sub-expression — a `val`'s annotation (`inferDecl`,
`inferDeclTyped`, `inferBindingExpr`), a plain call's declared parameters
(`inferCallExpr`), the body's return target (`inferJumpExpr`) and an expected
`Array<T>`'s element type (`inferCollectionExpr`).

In `inferCallExpr` the parameter an argument is read from is not always the one
at its own index: a label claims the parameter it names (C-04), so
`argumentParamSlots` inverts `planDefaultFill`'s plan rather than working a
second mapping out — two mappings could disagree and the expectation would name
the wrong enum. It allocates nothing for a positional call (`null` means
"argument `i` is parameter `i`") and answers `params.len` — no expectation —
for an argument whose parameter is not knowable. `calleeParams` is read once,
above the argument loop, and the arity arm's default fill reads that same list.

**ES5** — when two enums carry the path and the expectation says nothing,
`raiseAmbiguousSectionPath` refuses at the head segment, naming every candidate
(sorted, because the set comes off a hash map). It is not a pick: the candidates
are different types, the program means one of them, and picking is the defect
this closed. ES4 (a head that matched, a tail that did not) is unchanged and
still names the FIRST enum whose head segment is a section wrapper — that
choice is the iterator's, and it decides only which enum the message blames.
The refusal's hint names the fully qualified spelling, which is the way out of
an ambiguity a position cannot type.

Tuple labels (decision 8 §6) ride the same map: a `tuple` type carries
`named.labels` (from a written `#(name: T, …)` type — `ast.TypeRef.labeledTuple`
— or, T1, from the plain variables a `#(…)` literal is built from; `unify` never
compares them). `row.label` on a labeled tuple resolves the element type and puts
`row._N` into `env.enumSectionRewrites` under the access loc, so every backend
sees a positional access; an unknown or ambiguous label is a located error naming
the positional form. The name-mismatch warning (T7) is not implemented; the
warning channel it waited for exists now (decision 57, above).

`comptime.zig withSynthesisedEnumDecls` (after `transform` /
`withUsedAssocInterfaces`) prepends every `env.synthesisedEnumDecls` entry as a
top-level enum `TypeDecl` and adds the section-wrapper variants to each parent enum,
so backends emit them through the normal enum path.

Parser-side invariants (`parser/decls.zig parseEnumItem` → `raiseUnexpected`):
numeric variant names only inside sections, without payload, and never as a
section name; duplicate section names are rejected.

## Children

- [`runtime/AGENTS.md`](runtime/AGENTS.md) — the comptime runtimes (BEAM, wat) and the dispatcher.
- [`stdlib/AGENTS.md`](stdlib/AGENTS.md) — std prelude embedding.
- [`tests/AGENTS.md`](tests/AGENTS.md) — comptime tests.

## Scratch paths in tests

A unit test in this package that writes to disk takes its path from the
`test_scratch` module — `test_scratch.path(io, "<case>/…")`,
`test_scratch.remove(io, "<case>")` — never a hand-spelled
`.botopinkbuild/<case>` (`scripts/check-test-scratch.sh` refuses that, decision 67, no flag).
The test cwd is this package's directory, shared by every process running the
suite; a per-case-but-not-per-run path let a second `zig build test` empty the
first one's fixtures mid-test. See
[../../../test-scratch/AGENTS.md](../../../test-scratch/AGENTS.md).
