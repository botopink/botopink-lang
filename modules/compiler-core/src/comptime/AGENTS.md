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
├── template.zig       ← `@Expr` templates: CapturedExpr, PlainArg, ScopeSnapshot, CustomNode, fail diagnostics
├── template_eval.zig  ← runtime-backed template body evaluation (erl)
├── decorator_eval.zig ← runtime-backed decorator body invocation (erl)
├── primOpTemplate.zig ← shared `#[@External.<Target>("…")]` template renderer (receiver marker / $N / $args / $stringify)
├── snapshot.zig       ← comptime snapshot helpers
├── trace.zig          ← decorator/template runtime exchanges shown in snapshots
├── tests.zig          ← barrel: aggregates tests/<feature>.zig
├── tests/             ← comptime tests, split by feature — see tests/AGENTS.md
├── stdlib/            ← std prelude embedding — see stdlib/AGENTS.md
└── runtime/           ← persistent `erl` comptime runtime + the resident prelude — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.contextBase`, `FnContext`, `TemplateEvalCtx` (`{ io, build_root }`), the `@src()` state (`srcPath` — the package-relative file `Module.srcPath` or `<name>.bp`; `currentFnName` — fn / `Type.method` / test name, set by `inferFnDecl`, `inferTypeMethods`, `inferTestDecl`; `srcRewrites` — call loc → the `SourceLocation(…)` constructor call the transform splices; `usesSourceLocation` — the program named the prelude record, so `comptime.zig` prepends its declaration; `testIndex` — the `test_<idx>` fallback counter), static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`), the `"std"` package tables (`stdModules`: module → fn exports; `stdModuleTypes`: module → pub type decls, registered into the importer by `markStdImports`; `stdModuleFns`: module → fn decls, used by `markStdImports` to reject a `from "std"` import whose `declare fn`s have no `@external` for `Env.target` (`std-unsupported-on-target`); `stdImports`: names imported via `from "std"`, which win over same-named value bindings like the primitive `bool`), the `decorators` table (name → `DecoratorSig{ params, fn_decl }`), and the loc-keyed lowering maps `method_lowerings` (`@Result`/`@Option` methods + the builtin `result` namespace), `result_jump_lowerings` (`return`/`throw` → `__bp_ok`/`__bp_error` in `#[@result]` fns), `jsMethodRenames` (type-directed JS-only renames, e.g. `string.contains` → `includes`, recorded only when the receiver's static type makes a global rename unsafe — `Set` also declares `contains`), and `instanceLowerings` (see `infer.zig`). `valNames` / `bindVal` / `isVal` (decision 38): `bindVal` binds a `val` — local or module-level — and marks the name; `bind` (a `var`, a parameter, a pattern) clears it, and `infer.zig` refuses an assignment to a marked name. |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. `registerExtensions` + `resolveReceiverCall` implement static extension dispatch. `registerFnSignatures` (via `buildFnSignatureType`) binds every top-level `fn` signature before any body is inferred, so mutually-recursive / forward-referenced fns resolve. Ends with `validateProgram` — `implement`/interface coverage + getter/setter checks. Top-level `test { … }` bodies type-check like void fn bodies via `inferTestDecl`; `assert cond` unifies `cond` with `bool`. **`@src()`** (1.0.10-beta decision 73): `inferSrcBuiltin` — intercepted in `inferCallExpr` before the arguments are inferred — refuses any argument or trailing lambda (`src-takes-no-arguments`, at the `@`), builds the untyped `SourceLocation(file: env.srcPath, line: L, column: C, fnName: env.currentFnName)` call with four literals, records it in `env.srcRewrites` and infers **it**, so the typed AST carries the record type; a hand-written `SourceLocation(…)` call or annotation sets `env.usesSourceLocation` too. `inferBuiltinCallReturnType`'s fallback is no longer a silent `void`: a name outside `runtime_builtin_names` (`print`/`println`/`debug`/`panic`/`todo`/`trap`/`compilerError`/`module`/`emit`/`is`), the parser's `[]` index sugar and `env.stdlibFnDecls` is `unknown-builtin`, located at the `@`, suggesting the nearest known name when one is an edit away (`editDistanceIsOne`). A bare `return;` inside a `#[@result]` body records `.wrap_ok` too (decision 74 — `-> @Result<void, E>`). `inferTypeMethods` walks record/enum method bodies (generics, `Self`, params) to type the calls and record their lowerings; it is **strict** (06 C9 — it used to swallow `error.TypeError` into `lastError = null`, so a real mismatch inside a method only failed at run time), and it stores the signature of a method that annotates NO return type, taking the return from its body's `return`s (`registerInherentMethodTypes` stores one only for an annotated method). It runs from the TYPED `inferDeclTyped` only — the untyped `inferDecl` never walks method bodies, which is why a method-body row asserts through `assertComptimeCompileError`, not `assertTypeErrorSnap`. A method call on a receiver whose type is a nominal `Env.lookupTypeDef` knows, that no inherent method, behavior member, fn-typed field or primitive dispatch answers, is `unknownMethod` — or `methodNotActive` when a non-activated `implement` block declares it (`typeAnswersMember` / `behaviorDeclaresMember` are what keep an adopted `default fn` and a `#(value, set)`-shaped fn field legal). Everything else stays the permissive fresh var: an unresolved type variable, and a named type the env cannot open (an imported record, a wrapper, a forward reference). Value-receiver instance calls are recorded in `env.instanceLowerings`: `.record <typeName>` or `.prim <PrimKind>` (array/string/bool/int/float — non-JS backends map it to a host op); commonJS ignores the table. `primMethodReturnTypeFromIface` derives a primitive method's return type from its interface signature so chains (`xs.filter(f).at(0)` → `?T`) keep tracking; `length`/`len`/`size` read the interface field. `primMethodParamTypes` is its mirror on the argument side and is read **before** the call's arguments are inferred: a lambda argument over a builtin-primitive receiver is typed from the method's declared signature (`filter(self, pred: fn(item: T) -> bool)`) instead of fresh vars, so `xs.filter({ e -> e.name.contains("x") })` resolves `e` and the `contains` → `includes` JS rename fires inside the lambda — it used to emit `.contains(…)` verbatim and die at run time. Only the PARAMETERS are pushed down (`inferFunctionExprExpected`'s `params_only`): the declared return is not a constraint the lambda must meet, because `Array.forEach`'s `action` is declared `-> void` and a body whose every path `return`s types its tail as void while the `return`s have already fixed the return target. Generic-inference regression guards live in `tests/infer_generics.zig`. A generic enum's unit variant (`Option.None`) carries one fresh var per generic param (C7). `lhs |> f` with `f` a function value types as `f(lhs)`; a pipeline whose RHS arity does not take the piped value is an `arityMismatch` at the RHS (C12). **Tuple labels** (decision 8 §6, 06 N24) live on the `named` type node (`Type.named.labels`), so `instantiateType` carries them — a generic signature (`fn ref<T>() -> #(current: T)`) used to lose them and `r.current` red "this tuple has no element labeled". `row.pop` records a positional rewrite (`row._1`) under `env.enumSectionRewrites`; `inferTupleLabelCall` does the same for a labelled element of FUNCTION type CALLED like a method (`#(value, set: fn(…))`, `c.set(9)` → `c._1(9)`), which the member-access path never saw, and the backends lower `._N(…)` as an index/`element/2`/`call_fun` apply. A constructor call with a `..` spread is a record update: the spread unifies with the record, each labelled arg with the field it names, an unknown label reds at the label (C11). `@RecordKeys(T)` is `array<string>` and `@field(v, "x")` has the field's type (C6). `&&` / `||` / `!` unify TARGET-first and locate at the OPERAND (06 C3): they passed the operand as `unifyAt`'s `a`, so `1 && true` read "expected i32, got bool" with the caret on the whole expression. `-` and `*`/`/`/`%`/`-` constrain their operands to a numeric type (`requireNumericOperand`, permissive for an unresolved type variable and for any name it does not know to be non-numeric): `"a" * "b"` and `-"s"` used to check, since unifying two strings with each other succeeds and `-` constrained nothing. `+` keeps its string concatenation. The branches of an `if` unify only when BOTH end in something that has a value (`stmtsYieldValue`): decision 2 makes a block not-a-value, and unifying a branch that ends in an assignment or a `val`/`var` reds `if (p) { out = …; } else { taking = false; }` with "expected array, got bool" — a shape a library in this repository writes in a `takeWhile`, and the same in a plain fn. Deleting the unification outright waits for the row that removes block-as-value. A condition loop (`loop (cond)` / `loop { … }`, iter typed `bool`) with a parameter is an error at the parameter (N26); a loop that is one only by its type is recorded in `env.conditionLoops`, which `transform.zig` turns into `LoopExpr.condition` for the backends. An unresolved enum-section path points its caret at the first segment that does not resolve (N17). **Decision 38 — a `val` is immutable**, local or module-level: `refuseValAssign` (at the assignment's `.name` target) reds `` `x` is a `val` and cannot be assigned `` with a hint naming `var x = …`; it used to check and then throw on node (`const`), not compile on erlang and not validate on wasm. **Front 17 step 3** — `validateMemoryAnnotations` checks every `#[@BeamMemory.<member>]` on a module binding: the binding is a `var`; the member is `ProcessDict`, `Ets` or `PersistentTerm`; every argument is `keyed` with `true`/`false`; and `keyed = true` needs a `Dict` (decision 51 — an `i32` or a list has no key). Steps 4–5 (the BEAM lowering) are not started. |
| `unify.zig` | Unification with substitution + occurs check. `unify(env, a, b)` is **target-first**: `a` is what the context expects and `b` what was written, which is what makes its two one-way rules sound — an expected `?T` accepting a plain `T`, and decision 8 §2.1's `unknown` (`isUnknown`), which accepts every type **into** it and none **out** of it. The `unknown` rule sits above the kind match because it holds against every kind on the other side, not only `.named`; an unbound variable on either side still links, so inference deciding a type is never mistaken for a use. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`), plus `validateComptime` — the gate that decides what may appear inside `comptime` / `comptime { … }`: literals, arithmetic, comparisons and `&&`/`||`, `not`/`-`, array literals, pipelines, `if`, `break`, and identifiers that the block itself declared. `validateBody` threads that scope on the Zig stack (a `val`/`var` validates its initialiser in the scope before it, then validates the rest of the block with the new name in scope) and mirrors the `Scope` `eval.zig` builds with real values. A ctor or any other call stays rejected on purpose — see the `comptime record lit` skip in `tests/eval_pipeline.zig` for why (one literal text has no cross-backend record form). Two structurally legal folds are refused too, located at the expression (`ComptimeError.reason`): a constant zero divisor (`divisionByZero`, C4b) and negating a string (`negatedNonNumber`). |
| `effect_chain.zig` | The effect chain (decision 95 of 1.0.10-beta). `clauses` restates the `extends` clauses `libs/std/src/builtins.d.bp` declares on the six wrappers; `wrapperImplements` closes them transitively; `grants(eff, cap)` answers whether a body carrying `eff` may write `try` / `await` / `use` / `yield`, and is the ONE question all four legality checks ask. `refusal` builds the diagnostic, which names the level the body would need (decision 67). Its drift test reads `builtins.d.bp` through `std_prelude` and fails in both directions — a clause here that the file does not declare, and one the file declares that is not here — because the file is documentation the compiler does not parse and a copy nobody checks is a copy that drifts. `@Generator` carries no clause on purpose (question 97). |
| `diagnostics.zig` | Stable diagnostic-code constants (R1–R21, RF1–RF5, RI1–RI6, RC1–RC6, RG1–RG4, D1–D6, `std-unsupported-on-target`, `src-takes-no-arguments`, `unknown-builtin`, `effect-try-without-fallible-channel`, `option-expect-removed`) plus the `all_codes` table. Messages live at the firing site. |
| `eval.zig` | `ComptimeEntry` / `RunResult` / `evaluate(allocator, entries)` — folds each comptime `val` in Zig (`valueOf`: literals, arithmetic, `not`/`-`, `@TypeOf` name, `@typeInfo`/record literals as objects, a comptime block's / `if`'s / `case`'s / loop's `break` value) and writes the literal backends splice in (`3`, `6.28`, `"text"`, `[1, 2]`, `true`, `null`; objects and nested lists are `null`). **Every operand carries its kind** (`Value`): `binary` folds int arithmetic as int, promotes to `f64` as soon as one side is a float (`3.14 * 2.0 → 6.28`), concatenates two strings on `+`, and returns a `boolean` for `==`/`!=`/`<`/`<=`/`>`/`>=`/`&&`/`||` — so an `if` inside a folded block takes the arm its condition really selects. Anything irreducible (a record operand, a non-constant zero divisor) folds to `null`, never to a stand-in `0`; a constant zero divisor or a negated string never gets here (`validateComptime` refuses it). A `comptime { … }` block has a `Scope`: `blockResult`/`execStmt` declare its `val`/`var` locals, apply `=`/`+=`, and follow an `if` into the arm that `break`s; a nested arm gets a child scope. `RunResult.script` is the listing shown in snapshots as `COMPTIME VALUES`: one `ct_N: <declaration> → literal` per entry, the declaration formatted by `comptime.zig` `evaluateComptime` (`ComptimeEntry.source`; continuation lines aligned). An identifier that is neither a block local nor `true`/`false`/`null` is `error.UnsupportedComptimeValue`. |
| `render.zig` | `extractLine` / `padSpaces` / `digitWidth` helpers for diagnostic rendering. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. Applies `method_lowerings` (`__bp_<domain>_<op>(…)`), `result_jump_lowerings` (`tryLowerResultJump` — a bare `return;` wraps `null`, decision 74), `templateExpansions`, `srcRewrites` (the `@src()` → `SourceLocation(…)` splice, only onto the builtin call at that loc), and `enumSectionRewrites` (`rewriteExpr`). Walks `fn` and `test { … }` bodies, including `assert` subexpressions. **Method bodies** (`type` and `implement` methods) never went through this walk — the backends lower them from the parsed AST — so they receive only the `@src()` splice, through a second `src_only` aggregator whose other maps are empty and which skips the one unconditional rewrite (the `${}` desugar); the full walk over method bodies is a separate change (it moves `record_method_with_todo_placeholder` on erlang: `@todo()` would get its default injected there as in a fn body). **Default-value expansion** (`expandTrailingDefaults` / `expandTrailingDefaultsWithParams`): when a call supplies fewer args than the callee's params and every missing trailing param has a `.default`, it appends `is_default_inj` args pointing at the param's own default Expr (no new Exprs materialized) — for free-fn calls (`fn_decls`, which also includes `env.stdlibFnDecls`) and record/enum-variant ctor calls (`ctor_params` from `env.ctorParams`; variants registered under bare and `Enum.Variant` names). Drops template fns and decorator fns from the output decls. |
| `template.zig` | `@Expr` template infrastructure: `CapturedExpr` (argument bound to a `comptime p: @Expr<T>` param, captured unevaluated with provenance), `PlainArg` (`{ paramName, source }` — a non-`@Expr` param or decorator argument that received a literal; `toExpr` turns its lexeme into an `erl_ast` expression), `ScopeSnapshot` (origin scope: caller's top-level decls + imports; `toJsonAlloc` feeds the memo key), `CustomNode` + `parseCustomNodeFromTree` (from `template_eval.CustomNodeTree`), and `mapSpanToLoc`/`failDiagnostic` (rustc-style `fail`/`failAt` diagnostics inside the caller's `"""…"""`). With contiguous text `mapSpanToLoc` counts newlines up to `span.start`; for holed multiline templates it falls back to `capture.loc.line + span.line - 1` (`span.line` is 1-based, line 1 = opening `"""` line). |
| `template_eval.zig` | Runs a template body that the V1 classifier cannot reduce. `buildModule` lowers the template `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode; host enums `BindingKind`/`DeclKind`; host records `Span`/`CustomNode`/`Binding`/`Source`/`Context`, so `Span(5, 9, 1)` / `CustomNode(kind: …)` build maps) and passes `main/0` as an `erl_ast` form (`mainForms`). The rest of the host glue is **resident** in `bp_comptime_template` (`runtime/prelude.zig`), declared to the emitter as `ComptimeModule.resident` and reached by the `-import` it writes, so nothing but the body, its shims and `main/0` is compiled per evaluation. `main/1` destructures an argument tuple and calls the body with it, so the module carries **nothing** from the call site and its content hash is a hash of the declaration: one `.erl` per template, not one per call site. Each `@Expr` parameter's element is `captureToTerm(capture)` — a map tagged `'__bp_capture' => Param` with `text` (raw literal text; holes appear as their `__bp_hole_<param>_<i>` placeholder), `parts` (`#{kind => <<"Text">>, text, span}` / `#{kind => <<"Interp">>, code => Placeholder, span}`), `source`, `context` and `bindings` (`#{name, kind => 'Record_'}`); a plain parameter's element is `plainArgTerm` — the same value `PlainArg.toExpr` renders, as a term, with `lexemeBytes` resolving the escapes `erl_emitter.writeStringFromLexeme` resolves; a lexeme carrying `\u{…}` has **no** exact term (the emitter renders it as Erlang's `\x{…}`, which truncates to a byte in a plain binary) and stays a literal in the module, which keys the module by that literal too. The tuple reaches the node as an external term (`runtime/etf.zig`), never as source text re-parsed there. `ensureModule` stages the `.erl` only when it is not already on disk, and the listing is rendered once per module atom (`cachedListing`/`rememberListing`) rather than once per call site — `emitComptimeModule` re-parses the embedded preludes on every emit, which is the whole of an evaluation's remaining compiler-side cost. Host functions, all resident: `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2` (binding map or `undefined`), `ref/1` (`Binding.ref()` — replies with the binding's **name** as code, so a hit splices a bare caller-scope reference instead of a value), `build/2`, `custom/3`, `fail/2`, `failAt/3`, `compilerError/1`, `expr/1`, `code/1`. `main/1` replies with JSON by result shape — `code`, `value` (`@expr`), `custom` (tree + code), `capture` (`return q`), `fail` (message/param/span), `error` — with `undefined` mapped to `null`. The module atom and file (`.botopinkbuild/tmp/template/bp@comptime__tpl__<template>__<16 hex>.erl`) are A2's declaration-qualified atom (`codegen/crossModule.erlDeclAtom(.of("bp/comptime"), .tpl, tfn.name, hash)`), so a stack trace and a `tmp/template/` listing name WHICH template they came from; the hash is the same Wyhash of the generated code, which no longer sees the capture, so an identical body is still the identical module and re-loading it is still a no-op. The `bp/comptime` half is a placeholder for the OWNING module's path, which does not reach the evaluator: it is handed an `ast.FnDecl` (whose `Loc` has a line and a column and no file) and `comptime.zig`'s template registry is a `StringHashMap(ast.FnDecl)` with no owner either, so `ui@panel__tpl__panel__<hash>` needs the module name threaded onto `env.TemplateEvalCtx` — `env.zig` and `comptime.zig`, which front 13 does not own. `writeModule` stages the file under a random sibling name and renames it into place, so concurrent evaluations of the same body (parallel tests, two processes sharing a cwd) never compile a half-written file (`decorator_eval.zig` uses it too); `writeModule` stages the file under a random sibling name and renames it into place, so concurrent evaluations of the same body (parallel tests, two processes sharing a cwd) never compile a half-written file (`decorator_eval.zig` uses it too); `persistent_erl.evalDetailed` runs it; `parseOutcome` maps the reply to `Outcome` (`value` → `TypedValue`, `ast` → `CustomNodeTree` with `ref: ?NodeBinding{name, kind}`), and compile/runtime failures become `err` with the Erlang diagnostic. A **transport** failure (the node died, the frame stream desynchronised) becomes `err` carrying `persistent_erl.lastTransportError()`; one with no message is `erl`/`erlc` missing and stays `error.EvalFailed`, so the caller's PATH hint still fires. A body method call that no primitive type and no host function answers (`emitComptimeModule`'s `unsupported_method` slot) becomes `err` naming the method, its argument count and its `line:col` in the body. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument). Inline tests cover reply parsing. |
| `decorator_eval.zig` | Runs a decorator body over the declaration it annotates. Input: a native `DeclHandle` (`kind`/`name`/`fields: []FieldHandle`/`variants`/`methods`/`returnType`/`annotations`; `variants` lists an enum-shaped `type`'s variant and section names and is empty otherwise — with `DeclKind.Type` covering both shapes it is how a decorator tells a record from an enum) built by `infer.zig`. `buildModule` lowers the decorator `FnDecl` with `codegen/erlang.zig` `emitComptimeModule` (untyped mode, `DeclKind` as host enum, `Span` as host record, `main/0` exported) and passes `main/1` as a `codegen/beam/erl_ast.zig` form built with `Ast.Builder` (`mainForms`); it destructures the argument tuple, so the module carries nothing from the declaration it runs over and its hash is a hash of the decorator plus its annotation arguments. `fail/2`, `failAt/3`, `compilerError/1` (throw a tagged rejection) and `emit/1` / `'__bp_emitted'/0` (process-dictionary accumulator) are **resident** in `bp_comptime_decorator` (`runtime/prelude.zig`), reached by the `-import` the emitter writes. `main/1`'s argument is `handleToTerm(handle)` (a `codegen/beam/term.zig` map — `kind` as atom, names as binaries, annotation args as raw lexemes) followed by the annotation arguments (`templateEval.plainArgTerm`; missing → `undefined`), encoded by `runtime/etf.zig` and replies with JSON `{kind: ok, contributions} \| {kind: fail, message, span} \| {kind: error, message}`. The module atom and file (`.botopinkbuild/tmp/decorator/decorator_<hash>.erl`) come from the code's hash, which no longer sees the handle. `persistent_erl.evalDetailed` runs it; `parseOutcome` maps the reply to `Outcome` (`ok` / `fail{message, span}` / `err`), and compile/runtime failures become `err` with the Erlang diagnostic (truncated to 4 KiB). A body method call that no primitive type and no host function answers becomes `err` naming the method, its argument count and its `line:col`. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument). Inline tests cover the module shape and reply parsing. |
| `primOpTemplate.zig` | Shared renderer for `#[@External.<Target>("<template>")]` primitive-op templates. Substitutes `receiver_marker` (the receiver — written only by `parser/template_markers.zig`, which translates the source's positional markers, decision 5; `$self` is no marker), `$<N>` (positional arg after the receiver), `$args` (all positional args, comma-separated) and `$stringify(<inner>)` (recursive render bracketed by the backend's `emitStringifyOpen`/`emitStringifyClose`, e.g. erlang `iolist_to_binary(io_lib:format("~p", [`…`]))`, node `JSON.stringify(`…`)`) through a backend-supplied ctx (`writeByte`/`writeAll`/`emitRecv`/`emitArg`/`argc`); other bytes pass through verbatim. Errors: `PrimOpArgIndexOutOfRange`, `PrimOpStringifyMalformed`, `PrimOpStringifyUnsupported`. `looksLikeTemplate(s)` (`$`-bearing) separates a template from the `module:symbol` form in erlang's `tryEmitPrimAnnotation`. **Arity branching** (`when(argc == N): "<template>"`): `parser.zig parseAnnotationCall` keeps each clause as one arg, `ast.parseArityBranchArg` extracts `{argc, template}`, the backend picks the matching branch (no match → falls through). **Triple-quoted** bodies: `ast.zig unquoteAnnotationArg` strips the fences plus one leading and one trailing newline. **BEAM consumer**: `codegen/beam_asm.zig renderBeamTemplate` uses the same walker with `emitRecv` → `{x, 0}` and `emitArg(i)` → `{x, i+1}` after pre-loading receiver/args; BEAM bodies are `#[@External.Beam("""<.S body>""")]` and are detected by `bref.module.len == 0`, not `looksLikeTemplate` (a body may have no `$` marker). |
| `snapshot.zig` | Snapshot helpers. `assertComptimeAst` records one file per test at `snapshots/comptime/ast/<slug>.snap.md` — the layout is `tests/AGENTS.md`'s table. **Type text**: `typeNameIn` renders an inferred `*T.Type` in one of two spellings (`TypeRender.mode`). `.diagnostic` is what `typeNameOf` and the error renderers print and what the `comptime/errors/` and `codegen/**/errors/` snapshots record — frozen: a `.func` collapses to its return type and every `.typeVar` is `?`. `.ast` is the `TYPED AST JSON` spelling: a `.func` reads `fn(<params>) -> <ret>`, `optional<T>` reads `?T` (as `array<T>` already reads `T[]`) unless its inner is itself unknown, and a `.typeVar` splits — `.generic` renders the declared type parameter (`GenericNamer.bind`, matched through the annotation by `bindGenericNames`, never guessed by position) or falls back to `'a`, `'b` by first appearance, while `.unbound` keeps `?`. **`?` means exactly one thing in a snapshot: the checker does not know**, so nothing else may render as it. `fn_def` params and return type come from the binding's inferred `.func` type; a record field, a method signature and an enum-variant payload go through the syntactic `typeRefName` instead — they are annotations the declaration wrote and are not bindings of their own (`infer.zig` `buildRecordDeclName` renders the same text into the record's type name). Inline tests pin all of it. **Declaration shapes**: `record_def` / `enum_def` / `interface_def` / `implement_def` carry `generic`, plus `implements` (an inline `record(…) implement I { }`), `fields`, `variants` with their payload types, nested `sections`, `extends`, and `methods` (`declare fn` slots included; an `implement` method has no `return_type` — the AST carries no return annotation there and the signature it satisfies is the behavior's). Every one of them is omitted when empty. An `implement` block declares no binding, so `buildSnapshot` reads those off `OkData.transformed.decls` in source order after the declarations that do bind. `record_def`/`enum_def` carried an `"id"` until 1.0.5-beta: it was `0` in all 71 snapshots that had it, because `resolveTypeId` looked a structural type name up in a map keyed by the declared one, and decision 19 removed the field. The `type_ids` plumbing in `../comptime.zig` (`:114`, `:1311-1313`, `:1324`, `:1490-1492`, `:1503`) is now dead and belongs to whoever owns that file. Section order: `SOURCE CODE`, `COMPTIME ERLANG` / `COMPTIME REPLY` per runtime evaluation, `COMPTIME VALUES` (when comptime vals exist), `BOTOPINK TRANSFORM CODE` (whenever a comptime val folded, a template/decorator ran, **or** the module expanded a template at all — `OkData.template_expansions`, so the V1-driver pass-through / `@expr` / `@code` expansions that never reach the `erl` runtime are recorded too; spec 06 H8/C1), `TYPED AST JSON`. A module whose outcome is not `.ok` writes a `COMPILE DIAGNOSTIC` section instead of stopping after `SOURCE CODE` (H3). Also owns the shared diagnostic renderers `renderTypeErrorBody` / `renderParseErrorBody` / `renderOutcomeDiagnostic` / `appendDiagnosticSection`, reused by `comptime/tests/helpers.zig` (`renderTypeError`) and by the codegen harness. |
| `trace.zig` | `Entry{kind: template/decorator, name, erl, reply}` — one per `template_eval`/`decorator_eval` run, appended to `Env.comptimeTraces` (surfaced as `OkData.comptime_traces`; `analyzeModule` keeps pass-1 decorator traces across the `@emit` re-analysis). `erl` is the `listing` build of the module (lowered body + `main/1`) followed by `main/1`'s argument as comment lines — the input half of the evaluation, which is no longer inside the module; `reply` is the JSON `main/0` printed, or `compile error: …` / `runtime error: …`. `render`/`renderAlloc` write the `COMPTIME ERLANG` and `COMPTIME REPLY` sections (JSON re-indented). |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` (plus the inline tests of `eval.zig`, `trace.zig`, `primOpTemplate.zig`, `snapshot.zig`, `diagnostics.zig`, `template_eval.zig`, `decorator_eval.zig`, `runtime/persistent_erl.zig`, `runtime/prelude.zig`); harness in `tests/helpers.zig`. |

## Effect annotations (`#[@<effect>]`)

A function's effect is `ast.FnDecl.effect: ?EffectKind` (`result` / `future` /
`generator` / `iterator` / `futureGenerator` / `context`), set by the parser from
a `#[@<effect>]` builtin annotation. The `*fn` prefix is rejected by the parser
(`deprecated-star-fn`). `inferFnDecl` validates the effect: it must match the
return wrapper (`effectMatchesReturn`); an effect on an interface method is an
error (`validateEffectAnnotations`), and so is one on a bodyless `declare fn` —
except `#[@result]` / `#[@future]` on a `declare fn` that carries an `@external`
annotation and returns the matching wrapper (`@Result<R, E>` / `@Future<T, E>`):
the host template owns the wrapper shape (used by `libs/std/src/asserts.bp`
`tryCatch` and `libs/std/src/http.bp` `fetch`).

**A lower-case `#[@external(…)]` binds nothing, and says so** (R3, decision 8 §8, decision 15).
Only the capitalised path form `External.<Target>` is read as host-backed (`FnDecl.isExternal`,
`ast.zig`'s `startsWith("External.")`), so `#[@external(node, "…")]` fell through as an unknown
annotation and was dropped — the `declare fn` bound no host and `check` exited 0 in silence.
`refuseLowerCaseExternal`, called from `inferFnDecl`'s annotation loop, reds at the annotation and
spells the target capitalised. It fires on the `@`-prefixed builtin form only: `#[external(…)]`
without the `@` is a user-defined attribute and means something else.

**The wrapper without its annotation is an error too** (06 N25, decision 8 § 9).
`@Future` / `@Iterator` / `@FutureGenerator` already demanded one; `@Result` did not — a plain
`fn f() -> @Result<D, E>` was accepted and deliberately given NO special treatment (`return` did
not wrap, `throw` stayed a raw host exception), which is a second, unwritten Result calculus.
`inferFnDecl` now reds it with `effect-missing-annotation`. Every `-> @Result` in `libs/std` already
carried `#[@result]`, so nothing there moved.

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

**The effects are a chain** (decision 95 of 1.0.10-beta). `effect_chain.zig`
owns the order — `@Future` and `@Iterator` extend `@Result`, `@FutureGenerator`
and `@Context` extend `@Future`, `@Generator` extends nothing (question 97: no
error channel, so no `try` and no `throw`) — and every legality check asks
`effectChain.grants(eff, cap)` instead of switching on an effect kind. The
clauses are declared in `libs/std/src/builtins.d.bp` on the wrapper
declarations; that file is not parsed into the type env, so `effect_chain.zig`
restates them and carries a drift test that reads the file and fails if the two
disagree. Adding a wrapper is a row in `clauses` and nothing else. The refusals
are built by `effectChain.refusal`, which names the level the body would need
(decision 67 — located, no flag).

The body context `starCtxFromEffect` → `env.starFn: ?StarFnCtx{ allowsAwait,
allowsYield, iterItem, effect }` is built for **every** effect (it is null only
in a plain `fn`), with `allowsAwait` / `allowsYield` read off the chain. Before
1.0.10-beta it was null for `#[@result]` and `#[@context]`, and the `yield`
guard was written `if (env.starFn) |ctx|` — so a `yield` in either body was
accepted rather than refused. `throw` is gated separately, by
`env.throwContext`, and bare `try` — the propagating form, which returns the
`Error` out of the body — asks the chain through `env.fnEffect`, guarded by the
same `throwContext == .plain` test `throw` uses so a lambda and a `test` block
stay lenient. `try … catch` propagates nothing and is not gated.

**Which scope a `yield` targets is asked before the chain is**, exactly as
`break`'s §1I REGRAS DE ESCOPO rule does and off the same `env.loopDepth`: a
`yield` inside a loop feeds that loop's array (decision 8 § 10's comprehension,
condition loops included), a labelled one feeds the scope it names, and only a
`yield` that reaches the function is the effect's.

`inEffectContext(env, .future)` fires `#[@future]`-only
rejections (RF1/RF2/RF5) without firing inside other effects.
`resultVariantCallName` / `futureConstructorCallName` /
`builtinRequiredGenericArgs` drive the syntactic rejections. Codegen reads
`f.effect` directly (`commonJS.zig fnKeyword`: future → `async function`,
generator/iterator → `function*`, futureGenerator → `async function*`,
result/context → plain `function`) — which is why `await` inside a
`#[@context]` body, legal since decision 95, runs on erlang, wasm and beam and
is a JS `SyntaxError` on commonJS. The legality is front 20's and the keyword is
the backend's; the row is written up as a handoff in `tests/language/run/effect_chain.bp`.

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
  `Result`/`Future`/`Iterator`/`Generator`/`FutureGenerator`/`Context` interfaces
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

## `@Context<B, R>` capability inference

`use` is a **prefix operator** (`use <hookcall>`); bindings come from the
enclosing `val`/`var` (`val {v, s} = use state(0)`, `use effect(…)` for void).
AST node: `Expr.useHook { inner }`. It is gated by the function's return type
**and** its effect annotation (decisions 88, 89 and 90 of 1.0.10-beta, front 19):

- The return must implement `@Context<ContextBase, Return>` — directly
  (`fn f() -> @Context<Element, R>`, a custom hook) or via a named type whose
  `implement` clause lists `@Context<…>` (`fn Widget() -> Element`, a component
  whose owner type is `Element`). The return is read through `@Future<T>` first
  (`unwrapContextOwner`, decision 89 — **only** `@Future`, one level), so
  `-> @Future<Element>` is owned by `Element`.
- The fn must carry an effect annotation: `#[@context]`, or (decision 90) a
  **wrapper effect** — every effect but `#[@context]`, `#[@future]` in practice
  — whose unwrapped return type owns the context; `isWrapperEffect` is the
  predicate. A body with **no** annotation activates nothing: a `-> Element`
  without one is an ordinary fn; a `-> @Context<B, R>` without one is a hook
  declaration whose body activates nothing. R5 is unamended — one annotation per
  fn, so `#[@future] #[@context]` stays `effect-duplicate-annotation`, which is
  why the wrapper effect has to be enough on its own.
- Every `use` in the body must return `@Context<B, _>` with the **same**
  `ContextBase` (transitive through custom hooks).

Wiring in `infer.zig`: `contextBaseFromImplements` computes `TypeDef.contextBase`;
`inferFnDecl` records the body's capability in `env.fnContext`
(`contextInfoFromReturn(env, returnType, effect, name)` → `FnContext
{implementsContext, base, annotated, fnName}`, where `annotated` is the
`#[@context]`-or-wrapper-effect test above and `returnDisplay` stays the return
type **as written**, `@Future<Element>` and not `Element`); `inferUseHookExpr`
checks `implementsContext` (else `useNotAllowed`), then `annotated` (else
`useWithoutContextEffect` — `use-without-context-effect`, RC7 in
`diagnostics.zig`, located at the `use` and naming the fn and its return type),
then `validateUseBase` (`useNotContext`, `contextMismatch`) and types the prefix
as `R`. `effectMatchesReturn(env, .context, T)` accepts the `@Context<…>` wrapper
or a named type with a `contextBase`, so `#[@context] fn … -> Element` passes
the effect ↔ wrapper check, and `returnTargetFor` makes such a body's `return`
unify with the owner type as written. `val {v, s} = use …` binds leniently via
`bindUseDestructure`; a tuple `R` binds fresh vars (front 19 step 3).

Codegen lowers `use f(x)` to `f(x)` on **every** target — the prefix is the
activation the checker validated, never a rename or an inferred dependency
array (decision 88 deleted commonJS's React mapping). Phantom `@Context` base
structs are erased — see `codegen/AGENTS.md`. Documented for users in
`docs.md` § *use — imports, activation, and hooks*.

## `return` checking (06 C1)

Every `return <value>` unifies with the body's **return target** (`env.returnTarget`), located at
the value:
- a fn with a declared return type → that type; a type guard (`-> x is T`) → `bool`, which is also
  what its signature and every call of it are typed as (06 C5: `T` lives in `FnDecl.typeGuardType`
  and narrows the argument in the branch the guard proves — `env.typeGuardFns` is filled from that
  slot; before C5 `T` sat in `returnType`, so the call was typed `T` and the narrowing at the `if`
  was unreachable);
- an effect body → the wrapper's inner channel: `#[@result]` → `R` of `@Result<R, E>`,
  `#[@future]` → `T`, `#[@generator]` → `R` of `@Generator<T, R>`; any `-> @Context<B, X>` → `X`;
- a lambda → its expected return type, else a fresh var shared by its `return`s; a trailing
  lambda (`@block { … }`, `use memo { -> … }`) owns its `return`s too, and `@block` is typed as the
  value they carry;
- no declared return type, a template fn (`-> @Expr<…>`), an iterator effect → unchecked.

A value that already is the declared wrapper (`return state(start)` in a `-> @Context<B, X>` hook,
a `@Result` / `@Future` passthrough, `try` / `catch` forms) unifies with the whole declared type or
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

**Not implemented, and why.** §2.4 (a `pub` declaration whose *inferred* type contains `unknown` is
an error) and §1.4 (a non-`pub` binding falling to `unknown` **warns**) both need a channel
`comptime/**` does not have: there is no warning path here at all, only `TypeError`. Indexing —
§2.2's fourth refusal — has no syntax to refuse: `a[0]` is a parse error in this grammar.

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

§4.2 is `checkIsTestableType`: a primitive, a named type's constructor and a tuple are testable as
they are; a generic type is testable only applied to `unknown`. `Box<i32>` is the section's own
error — a run-time test can see that a value is a `Box` and cannot see what is in it, so
`Box<i32>` would be a promise the test does not keep, while `Box<unknown>` says exactly what it can
answer. Each member of a union is checked in turn.

Narrowing has one channel, not two: `if (x is T)` writes into the same
`guardArgName` / `guardNarrowedType` pair C5 built for the type-guard fn form (`-> x is T`), so the
branch rebinds the name exactly as a guard call does. Only a plain **name** narrows — narrowing is a
rebinding, and there is nothing to rebind for `f().x`.

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
`case` the author wrote. The channel is `conditionLoops`' (decision 8 §10):
inference decides, the transform edits, codegen is told nothing new.

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
`inferDeclTyped`, `inferBindingExpr`), a plain positional call's declared
parameters (`inferCallExpr`), the body's return target (`inferJumpExpr`) and an
expected `Array<T>`'s element type (`inferCollectionExpr`).

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
the positional form. The name-mismatch warning (T7) is not implemented — the
checker has no warning channel (06).

`comptime.zig withSynthesisedEnumDecls` (after `transform` /
`withUsedAssocInterfaces`) prepends every `env.synthesisedEnumDecls` entry as a
top-level enum `TypeDecl` and adds the section-wrapper variants to each parent enum,
so backends emit them through the normal enum path.

Parser-side invariants (`parser/decls.zig parseEnumItem` → `raiseUnexpected`):
numeric variant names only inside sections, without payload, and never as a
section name; duplicate section names are rejected.

## Children

- [`runtime/AGENTS.md`](runtime/AGENTS.md) — persistent `erl` comptime runtime.
- [`stdlib/AGENTS.md`](stdlib/AGENTS.md) — std prelude embedding.
- [`tests/AGENTS.md`](tests/AGENTS.md) — comptime tests.
