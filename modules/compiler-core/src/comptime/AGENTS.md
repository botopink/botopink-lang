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
├── analysis_entry.zig ← the code cache's level B entry (144 B-60): the container (magic, key, length, SHA-256, section table; `unpack` proves it whole or answers `error.Doubt`) and the encoding — `Encoder(skips).encode(T, &v)` / `Decoder(skips).decode(T)`, generic over `@typeInfo` (every field written unless `default_skips` names it: `TypedBinding.typedExpr`, `OkData.custom_ast`; a type with no rule is a compile error), strings interned in STRINGS — a slice of a source the binary embeds (std's prelude and modules, `embedded_sources`) written by place and read back as a slice of the same bytes, so `codegen/erlang.zig` `slicesIntoPrelude` answers as it did live —, pointers and slices through an identity table keyed by (address, length, element type) so sharing survives (within one entry: across two entries a shared node is copied), hash maps sorted by key, array hash maps in insertion order, a struct declaring `entry_as_string` as the string its `entryText` renders, read back through `fromEntryText` (`trace.Listing`, 144 B-127); `write` / `read` an entry of META (the package, the target, the modules, and per module its `ModuleMeta` — what `expandStdImports`, `orderReaders` and the module tree learn by parsing it: its std imports, whether it reads `@TypeInfo.all`, its `mod_tree.Known`), STRINGS, then per module its ANALYSIS (`Analysis`: the name, the `srcPath` and the `OkData`; never the source text, which the driver holds and sets on the output read back) and its JOURNAL (`Journal`: per map of the session — the five registries, the default DSL, every journaled field of `Reflection` — the keys removed and the entries put, a map of maps per inner map, `reset` when replaced whole; a list's appended items; a test holds `journaled_reflection` ++ `unjournaled_reflection` to `Reflection`'s fields), then CODE (S4): none, or one per module after every ANALYSIS and JOURNAL — `CodeUnit` (`wasm_artifact` and the module's `GenerateResult` but `code_skips`: diagnostic, comptime error, warnings, run output, the test unit — decision 513 (3)), self-contained (its own strings: `encodeCode` / `decodeCode`) so a build or a `test` adds it to an entry `check` wrote without encoding the rest; `read` gives the sections undecoded (`Decoded.code`), a count that is neither none nor one per module malformed; inside the compiler key's partition, so its change moves every key
├── level_b.zig        ← the code cache's level B inside a compile (144 B-60 S2): `Store` (the driver's — the CLI's `analysis_store.Cache` — key / read / discard / stage, and `Stats`); `Session` — `groupOf` (an embedded std module its own group, a dependency package one, the package under test none), `lookup` (packages before `expandStdImports`, std after: a hit decoded into the session arena when its META names the same modules and target; a miss with a key recorded), `hitOf` / `hitMeta` (by module, a dependency's alone: a module of the package under test at a dependency module's path is never answered by its entry), `plan` (a recording group's modules contiguous in the order, else not stored), `begin` / `end` around each analysed module (a `Snapshot` of every journaled map before, its difference after; at the group's last module the entry encoded — before any consumer is analysed, before codegen — and staged; not stored when a module is not `ok`, reads `@TypeInfo.all` or expanded a template that read the catalogue), `replayHit` (the output's place taken, the journal replayed in order); `Code` (S4, `ComptimeSession.level_b_code`) — the CODE of the hits that carry it (`take`: a module's unit decoded and owned by the emit's allocator, `Stats.modules_code_read`; not used when emitted with another `wasm_artifact`; the `.d.ts` dropped when the build asks none) and the entries still without it, those this compile staged and those read without one (`records`; `record`: once the emit returned, each such entry whose modules all emitted is packed again with their CODE and staged, `Stats.code_staged`, and the `.d.ts` made for CODE alone dropped from the outputs); a test holds `owned_result_fields` ++ `code_skips` to `GenerateResult`'s fields. Every target skips: a dependency's unit is lowered against its own closure (509 (2)) — wasm links a dependency's bodies into each consumer's unit, lowered there, never into the dependency's own
├── env.zig            ← Env (binding name → *Type), registries, loc-keyed lowering tables
├── infer.zig          ← `inferProgramTyped` — HM walk, decorators, template expansion
├── unify.zig          ← type-variable unification + occurs check
├── error.zig          ← structured TypeError with source ranges + hints
├── diagnostics.zig    ← stable diagnostic-code string constants
├── eval.zig           ← comptime val folding (literals, arithmetic, @TypeOf)
├── render.zig         ← source-line helpers for diagnostic rendering
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()`
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── context_lower.zig  ← decision 388: a `@Component` is a lambda over a `RenderScope`, lowered on the transformed AST
├── alias_erase.zig    ← type aliases erased for the backends (reflective `TypeRef` walk; a return alias of a wrapper stays)
├── inline_types.zig   ← decision 207: a parameter's inline `type(…)` becomes a record `BpInline__<fn>__<param>` of the module, and a call's field labels its constructor call (`expand`, run by `analyzeSource` after `std_namespace`)
├── derived_types.zig  ← decision 307: `pub val RecipeTitle = Type.pick(Recipe, .title);` — a module-level `val` over std's `Type.partial` / `required` / `pick` / `omit` / `merge` (the receiver bound to std's `types.Type`) becomes the record declaration it answers, named after the `val`, its annotations on the type and each field the source's (`expand`, run by `analyzeSource` after `nested_types`; an imported source through `comptime.zig` `derivedTypeSource`, by its module's key — the package plus the path, decisions 170 and 337; `modules/derived_type_two_packages`); the `derived-type-*` refusals. `pub val RecipeKey = Type.keys(Recipe);` becomes the alias `pub type RecipeKey = Type.Field<Recipe>;` (decision 308, `keysAlias`), and a module importing such an alias gets `import {types.Type__Field} from "std";` (`withFieldKeyImport`) — the record its keys construct
├── expr_param.zig     ← decisions 364, 575 (4): a non-template function's `comptime x: T` / `expr x: T` parameter (`Param.exprWrapped`, the internal tree form the parser reads it into) — `eraseFn` / `eraseProgram` turn `x.value` into `x` for the code that runs (the transformed program and `fn_decls`, `comptime.zig`; a decorator's body and support, `infer.zig` `runDeclDecorators`), and a decorator's `compiler.fail(m, at: x)` (written onto the handle's `x.fail(m)`) into the prelude's `'__bp_failArg'(j, m)`; `useOf` answers whether a body reads a parameter (and its `.value`)
├── member_fn.zig      ← decision 370 (2): a decorator's `decl.addMember(name, fn(self: T) -> R { … })` — `collect` (the body's member functions, in `eraseFn`'s order), `boundNames` / `freeNames` / `typeNames`, `render` (the member's source: each read parameter replaced by its argument as written, each type parameter by its binding, `Self` for the owner)
├── value_or_type.zig  ← decision 297: `comptime x: V | type<T>` — the function keeps its value form (`typeRef` = `V`, `Param.typeArgOf` = `T`, `x is type` folded false) and gains a type-form twin `<f>__type` without `x` (`x is type` true); `infer.zig` types a type argument as `V` with `T` bound to it and records the call's rewrite to the twin (`noteTypeArgCall`, `env.typeArgTwins`), `withTwinImports` brings the twin along an import; a `comptime` parameter's argument that reads a run-time value is `comptime-arg-not-known` (280 (0))
├── default_fn.zig     ← decision 289: an anonymous `pub default fn (…)` named `default` (a keyword no source spells); `import {m.card};` naming a module that holds a default rewritten to `import {m.card.<default> as card};` (`analyzeSource`, first; the default registered under `default_fn.key(path)` in `templateRegistry` by `registerExports`)
├── mod_tree.zig       ← decision 337: the session's module tree (a backtick `mod` name or path segment keys the module by the file name it spells, decision 561 — `keyIn`, the child keys) (`Reflection.modTree`, built by `compile` / `compileTypesOnly` from every non-std module; `buildWith` takes a module's `Known` entry and re-exports instead of parsing it — level B's hit, `knownOf` what a recording group stores): each module's `mod` children (a root's child is top-level, a folder's nests), its `pub` names and types, and the re-exports (`pub val f = ns.f;` / `pub type T = ns.T;`, a namespace then the same name); `known` is false for file-path keys (the language server's session)
├── mod_namespace.zig  ← decision 337 (2)–(3): `mod m;` binds the namespace `m` — the item `import {m};` (the child's path) added when the module reads it — in a body, or at the head of a dotted name in a decorator argument's lexeme (`#[each(markers.email)]`, outside a string); `ns.child` (a `mod` child, `private-module` from outside a plain `mod`'s parent), `ns.Type` (type, constructor, variant path) and `ns.value` (value position) rewritten as `std_namespace` does for std, over the package's own modules and a dependency's module an item `from "<pkg>"` names whole (`import {shapes} from "kit"`, its items added in a `use … from "<pkg>"` of their own, 144 B-10); a re-exporting type alias dropped for the item that brings the type under its name; `redundant-module-import` and a declaration named like a `mod` (`import-name-collision`); `chains` — every dotted name a module reads, for the CLI resolver's order (`analyzeSource`, first)
├── std_namespace.zig  ← decisions 110/111 on the use side: `io.fs.f()` through a std folder namespace, `collections.Dict.empty()` and a type's constructor `url.Url(…)` through a module one, rewritten on the parsed program into the one-dot / leaf forms (`analyzeSource`, `expandStdImports`)
├── template.zig       ← templates: CapturedExpr, PlainArg, ScopeSnapshot, CustomNode, fail diagnostics
├── template_eval.zig  ← runtime-backed template body evaluation (through runtime/runtime.zig's dispatcher)
├── decorator_eval.zig ← runtime-backed decorator body invocation (erl; the same refusal)
├── decorator_same.zig ← decision 371: `d.same(other)` lowered to `==` of two identities for the comptime runtime
├── block_eval.zig     ← decisions 266/331: a `comptime` the Zig folder cannot read, run on the comptime runtime and lifted
├── host_cells.zig     ← decisions 341, 434: the host and std functions a comptime module carries (std's renamed `__bp_std__<module>__<name>`), each host function's source at comptime — std-wasm, else `.Wasm(body: …)` (`forRuntime`; decision 452), a decorator's host functions checked at its package's compile (`checkDecorators`)
├── hooks.zig          ← decision 277: the hook node of each function, `decl.hooks` and its term
├── typed_meta.zig     ← decision 298 + 370 (1): typed meta keyed by its record type — `asCall` / `collect` (a decorator body's `decl.setMeta(v)` / `decl.addMeta(v)`, in `eraseFn`'s order), `ctorOf` (the record constructor written at the call), `Shape` / `render` (the value the body built, JSON, written back as the constructor's arguments — an `expr` field as the annotation wrote its argument, a tuple `#(…)` (the prelude's `meta_json` writes it `{"tuple": […]}`), a `Type.Field<T>` its `.name`, read with a generic record's one parameter spelled as the annotated declaration, `infer.zig` `fieldKeyOwnerParam`; 144 B-19), `withMetaHelper` (a module reading a catalogue entry's typed meta declares `declared__metaAll__<T>`, inferred with it)
├── reflection.zig     ← decision 216: what decorators record for reflection (`decl.setMeta`, `decl.addType`; decision 298's typed meta), one per compile session
├── typeinfo_all.zig   ← decision 216 (4): `@TypeInfo.all(with: d)` — the program's declarations carrying `d`, answered as a `Declared<unknown>[]` (decision 254)
├── builtins.zig       ← decision 252: the table of every `@name` builtin the compiler implements, held to `libs/std/src/builtins.d.bp` by its unit tests
├── adopt_defaults.zig ← 144 B-19: a type implementing a behavior of another module receives a copy of each bodied instance `default fn` it does not write (what the behavior extends included, `comptime.zig` `behaviorsReached`), its locations moved past the module's lines (`first_line`), before the module is checked — so every backend lowers it as the type's own method; a generic behavior is not adopted this way
├── assoc_types.zig    ← decision 216 (3): `Owner.Name` (an associated type) rewritten on the parsed program into the declared `Owner__Name`, its import item added
├── nested_types.zig   ← decision 330 (7): a type declared in a type's body (`TypeDecl.assocTypes`) hoisted as the top-level `Owner__Name` shown `Owner.Name` (`expand`, run by `analyzeSource` after `value_or_type` and on every embedded std module)
├── dsl_hygiene.zig    ← decision 112: a template's built code — the library's names resolve in the library
├── written_names.zig  ← decisions 384, 385: a name resolves where it was written — each module's scope published (`Reflection.scopes`), a library member's and an annotation's `expr` names bound in the reader under `templateAlias`
├── primOpTemplate.zig ← shared `#[.<Target>(…)("…")]` template renderer (receiver marker / $N / $args)
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
| `type_identity.zig` | Decision 310 — a type's identity by its module where two same-named imported types meet in one module: `renameDecl` (a declaration registered under its alias, its own name in its signatures renamed, printed as declared) and `renameType` (an imported value's type with its named types renamed — copies only the paths that change). § Decision 310 below. |
| `env.zig` | Type environment — scopes, builtins + stdlib, `TypeDef.isRenderable` (decision 354), `FnContext`, `TemplateEvalCtx` (`{ io, build_root }`), `comptimeOwners` (C-01 — a template's or body-carrying decorator's declaring module path, keyed by the declaration's body address; `noteComptimeOwner` / `comptimeOwnerOf`, read when the evaluator names its module atom), the `@src()` state (`srcPath` — the package-relative file `Module.srcPath` or `<name>.bp`; `currentFnName` — fn / `Type.method` / test name, set by `inferFnDecl`, `inferTypeMethods`, `inferTestDecl`; `srcRewrites` — call loc → the `SourceLocation(…)` constructor call the transform splices; `usesSourceLocation` — the program named the prelude record, so `comptime.zig` prepends its declaration; `usesYieldStep` — the same for the prelude enum `YieldStep<T>` (decision 122); `testIndex` — the `test_<idx>` fallback counter), static-extension-dispatch tables (`extensions`, `activations`, `inherentMethods`, `dispatchRewrites`), the `"std"` package tables (`stdModules`: module → fn exports; `stdModuleTypes`: module → pub type decls, registered into the importer by `markStdImports`; `stdModuleFns`: module → fn decls, used by `markStdImports` to reject a `from "std"` import whose `declare fn`s have no `@external` for `Env.target` (`std-unsupported-on-target`); `stdImports`: the local name of each std MODULE imported as a namespace → its path inside std (`dict` → `dict`; `import {io.fs}` → `fs` → `io/fs`), which wins over same-named value bindings like the primitive `bool` — a symbol leaf such as `import {io.fs.readText}` is an ordinary value binding instead; `importBound`: every local name this module's imports bind → the item, for `import-name-collision`), the `decorators` table (name → `DecoratorSig{ params, fn_decl }`), and the loc-keyed lowering maps `method_lowerings` (`@Result` methods — `?T` has none since decision 330, and the builtin `result` namespace is gone), `namespaceTypes` (decision 329's namespace types: a call of the name is `namespace-type-construction`), `inOptionalChain` (decision 330: `recv?.m(args)` typed through the payload), `result_jump_lowerings` (`return`/`throw`/`yield`/`break` → `__bp_ok`/`__bp_error` in bodies whose return carries a `@Result` layer), `jsMethodRenames` (type-directed JS-only renames, e.g. `string.contains` → `includes`, recorded only when the receiver's static type makes a global rename unsafe — `Set` also declares `contains`), and `instanceLowerings` (see `infer.zig`). **C-02 (decision 63, amended)** — `indexRewrites` (index loc → the untyped expression the index IS: `xs.at(k)`, `xs.slice(a, b)`, or a tuple's positional `t._0`), kept as its own channel beside `enumSectionRewrites` for the reason `srcRewrites` is kept beside `templateExpansions`: one channel, one meaning. **C-04 (01 step 7)** — the three tables that carry a parameter's declared `default` past registration, since a `T.func` drops it: `fnParams` (top-level `fn` name → params as written, the mirror of `stdlibFnDecls` for the program's own fns), `inherentMethodParams` (`"<Type>.<method>"` → params as written, `self` included; `set`/`getInherentMethodParams`), and `defaultInjections` (call loc → `DefaultFill`, written by inference the moment it ACCEPTS a call that omitted an argument, read by `transform.zig`). `planDefaultFill` is the one rule both sides obey: a labelled argument claims the parameter it names, the rest take the free slots in declaration order, and a slot left empty with no `default` is `error.CannotFill` — N2's arity error, unchanged. `memoryVars` (front 17 — each module `var` → its `ast.Memory` and bound type, read by `infer.zig`'s `refuseMemoryWrite`); `keyedRowAccess` (decision 168 — the identifier locs where a `keyed: true` var may be named: the receiver of its row read or row write) and `offBeamMemory` (decision 167 — the first `#[@BeamMemory]` of a module whose `target` is not the BEAM); `valNames` / `bindVal` / `isVal` (decision 38): `bindVal` binds a `val` — local or module-level — and marks the name; `bind` (a `var`, a parameter, a pattern) clears it, and `infer.zig` refuses an assignment to a marked name. `InstanceLowering.by_value` (a method a `behavior` declares without a body, on a receiver typed by the behavior — the value answers) and `.unplaced_type` (a method on a nominal type this module never imported); decision 432's `taskAwaits` (every `await` → its operand's type), `taskReturns` (every `return` of a whole `@Task` wrapper) and `failingTaskBlocks` (an `async { }` whose body builds its `@Result`), which `infer.taskLowerings` turns, once inference is done, into `InstanceLowering.task_await` / `.task_return` (the operand a `@Task<X>`, `X` a `@Result`, `unknown` or a type left open — and, for `await`, any operand not typed as a `@Task` or a `@Component`: a call through a record's function field is typed by its settled value) and `.failing_task_block` — commonJS's failing-task lowering (`codegen/js/AGENTS.md` § Failing tasks), which the other backends ignore; decision 150's `unionValues` (a `case` / `if` typed a union → the union and each arm's type), which `infer.unionValueLowerings` turns into `InstanceLowering.union_value` for wasm (§ union types); `importedBehaviorDecls` (the `pub behavior`s this module imports — an imported behavior is the nominal type its own module names, `resolveTypeName`); `ambientBehaviorDecls` (decision 539 (6) — `builtins.d.bp`'s `Display` and `Closeable`, read last by `behaviorDecl`, § Ambient behaviors); `resultPatternLocs` (an `Ok` / `Error` pattern over a `@Result` subject, written `Result.<name>` by the transform); `localCalleeCalls` (a free call whose callee is a parameter or a local, never the module function of the name in the transform); `namespaces` (`NamespaceImports`: decision 107's namespace form over a module of the program — the bound name → the module's exports, and each call made through it). |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. Ends with `validateProgram` — `implement`/interface coverage. Top-level `test { … }` bodies type-check like void fn bodies via `inferTestDecl`; `assert cond` unifies `cond` with `bool`. **`@src()`** (1.0.10-beta decision 73): `inferSrcBuiltin` — intercepted in `inferCallExpr` before the arguments are inferred — refuses any argument or trailing lambda (`src-takes-no-arguments`, at the `@`), builds the untyped `SourceLocation(file: env.srcPath, line: L, column: C, fnName: env.currentFnName)` call with four literals, records it in `env.srcRewrites` and infers **it**, so the typed AST carries the record type; a hand-written `SourceLocation(…)` call or annotation sets `env.usesSourceLocation` too. **C-02 (decision 63, amended 2026-09-19) — an index IS a method call**: `inferIndexExpr`, intercepted in `inferCallExpr` before the arguments are inferred, types `xs[k]` as `xs.at(k)`, `xs[a..b]` as `xs.slice(a, b)` and `xs[1..]` as `xs.slice(1, null)` — the index expression has no typing rule of its own and the type is whatever the method answers (`?V` for `Index<K, V>.at`), which is what makes a library's own `Matrix` indexable with **no compiler change**. The untyped call is recorded in `env.indexRewrites` under the INDEX NODE'S OWN loc and then inferred, so every loc-keyed plan the method call produces (its lowering, C-04's fill) is found again by the node `transform.zig` splices. The receiver is typed once here, because only its type tells a tuple from everything else: `inferTupleIndexExpr` is the checker's one special case — a tuple needs a CONSTANT index and answers a type PER POSITION, which `at(key: K) -> ?V` cannot say with one `V` — and it rewrites to the positional member access every backend already emits (`t[0]` → `t._0`), refusing a computed index and a position the type has not got, each located. `inferBuiltinCallReturnType` first holds the call to its declaration (`checkBuiltinArguments`, decision 252 — rows `.declaration` of `builtins.zig`), and its fallback is no longer a silent `void`: a name outside `builtins.table` and the parser's `is` / `[]` sugar is `unknown-builtin`, located at the `@`, suggesting the nearest known name when one is an edit away (`editDistanceIsOne`). A builtin DECLARED `-> noreturn` answers it (`@panic`, `@todo`, `@trap`, `@compilerError`; `builtins.neverReturns`) instead of `void`, so `val x: i32 = @todo();` and `return @panic(…);` type; `@module()`, declared `-> module` and lowered by no target, is `builtin-not-lowered` at the `@` (`modules/builtin_module_not_lowered`). `finishUnion` drops a `noreturn` member beside any other (an `if` branch, a `case` arm) (`if (c) { a } else { @todo() }` is `a`'s type). A bare `return;` inside a `-> @Result` body records `.wrap_ok` too (decision 74 — `-> @Result<void, E>`). `inferTypeMethods` walks record/enum method bodies (generics, `Self`, params) to type the calls and record their lowerings; it is **strict** (06 C9 — it used to swallow `error.TypeError` into `lastError = null`, so a real mismatch inside a method only failed at run time), and it stores the signature of a method that annotates NO return type, taking the return from its body's `return`s (`registerInherentMethodTypes` stores one only for an annotated method). It runs from the TYPED `inferDeclTyped` only — the untyped `inferDecl` never walks method bodies, which is why a method-body row asserts through `assertComptimeCompileError`, not `assertTypeErrorSnap`. A method call on a receiver whose type is a nominal `Env.lookupTypeDef` knows, that no inherent method, behavior member, fn-typed field or primitive dispatch answers, is `unknownMethod` — or `methodNotActive` when a non-activated `implement` block declares it (`typeAnswersMember` / `behaviorDeclaresMember` are what keep an adopted `default fn` and a `#(value, set)`-shaped fn field legal). Everything else stays the permissive fresh var: an unresolved type variable, and a named type the env cannot open (an imported record, a wrapper, a forward reference). Value-receiver instance calls are recorded in `env.instanceLowerings`: `.record <typeName>` or `.prim <PrimKind>` (array/string/bool/int/float — non-JS backends map it to a host op), and `.sequence_next <SequenceKind>` for a `.next()` by hand on an `@Iterator` / `@Stream` (decision 122 — the one entry commonJS ignoreads too). A **field read** on a record or struct records `.field_of <typeName>` at the access's loc (13-module-identity half 3): under decision 21 erlang and beam store a record as `{TypeAtom, F1, …}`, and the field's name does not carry its index — the backends turn the name into `element(N + 1, V)` with it, and fall back to a run-time lookup when nothing recorded the receiver's type. `primMethodReturnTypeFromIface` derives a primitive method's return type from its interface signature so chains (`xs.filter(f).at(0)` → `?T`) keep tracking; `length`/`len`/`size` read the interface field. A primitive receiver answers only what its interface chain declares (a `fn` method, a `val` field, `len`/`size`) or an `extend` block on it adds: `refuseUndeclaredPrimMethod` refuses anything else as `unknown-primitive-method`, located at the method name, suggesting the declared method whose `.Node` host symbol is the name written (`"abc".toUpperCase()` → `toUpper`) or one an edit away (pending 0203-a, answered (b)); silent only when the interface is not registered. `primMethodParamTypes` is its mirror on the argument side and is read **before** the call's arguments are inferred: a lambda argument over a builtin-primitive receiver is typed from the method's declared signature (`filter(self, pred: fn(item: T) -> bool)`) instead of fresh vars, so `xs.filter({ e -> e.name.contains("x") })` resolves `e` and the `contains` → `includes` JS rename fires inside the lambda — it used to emit `.contains(…)` verbatim and die at run time. Only the PARAMETERS are pushed down (`inferFunctionExprExpected`'s `params_only`): the declared return is not a constraint the lambda must meet, because `Array.forEach`'s `action` is declared `-> void` and a body whose every path `return`s types its tail as void while the `return`s have already fixed the return target. **C-04 (01 step 7)** — a call may omit an argument whose parameter declares a `default` (N1), and a call missing a REQUIRED one is still the arity error it was (N2). Three call paths judge it, each by planning the fill with `recordDefaultFill` → `env.planDefaultFill` and recording it under the call's loc for `transform.zig`: the free-fn / record- and enum-ctor path (`calleeParams` reads `env.fnParams`, `env.ctorParams`, `env.stdlibFnDecls`; a comptime / `expr` / template callee is excluded, its machinery being driven by the argument INDEX), the interface `default fn` on a primitive receiver (`"x".slice(1)` — `im.params[1..]` carries the default), and the instance method (`makeMethodCall` — inference never arity-checked this shape, so what was missing there was only the fill: `b.bump()` used to reach node as `bump()` and answer `NaN`). `unifyFilledArgs` unifies each argument with the parameter it LANDED in, not the one at its position — `P(y: 2)` against `type P(x: i32 = 0, y: i32)` puts its one argument in the second slot. Also reached: an imported fn (every plain `pub fn` exports its parameters as written — `comptime.zig`'s `defaultParamsKey`, a default that is not closed dropped — into the importer's `env.fnParams`), a call through a namespace import (`NamespaceImports.params`) and a `"std"`-package qualified call (`stdFnParams` over `env.stdModuleFns`), both through `planQualifiedCall`. A pipeline is a call too: `lhs |> f(args…)` / `lhs |> f` short of `f`'s parameters, or labelled, is planned by `planPipelineFill` under the pipeline's loc, and `transform.zig` writes every `lhs |> f(args…)` with a plain-call RHS out as `f(lhs, args…)` (`pipelineIsCall` / `pipelineAsCall`) — the backends read the node as `f(args…)(lhs)`: commonJS called the result and erlang's emitter crashed. A behavior's ASSOCIATED fn (`Scale.by(2)`, a member with no `self`) is reached too: its `T.func` is all the call site holds, so `inferAssociatedFnCall` reads the parameters as written from the behavior's declaration (`associatedFnParams` over `env.assocInterfaceDecls`) and plans the fill or the labelled reorder there (`modules/associated_fn_default`, `modules/associated_fn_missing_required`). Not reached, deliberately: a call carrying a `..` spread (a record update: the spread supplies every field) and a function VALUE (its type carries no defaults — a short call is the arity error). **Labels name parameters on every call path (`front/checker-rows-2`)**: a complete labelled call is planned as a reorder (`planLabelledCall`) and unified by the slot each argument lands in on the free-fn / ctor path, the instance method, the associated call (`associatedCallReturnType` — `Box.make(count: 3, label: "b")`), the namespace call and the std call; a label in a call of a function VALUE (no declaration, only a positional type) is `label-on-function-value` (`refuseLabelsOnFunctionValue`, also on a tuple's function element). **A duplicate `pub` name is refused at the consumer's use (`00 · 01-std`)**: when the first registry scan that finds an imported leaf finds it in two modules (a package handle), `comptime.zig` binds nothing and records the owners in `NamespaceImports.ambiguous`; `unboundAt` turns each use into `ambiguous-import-use`, located, naming both, and `transform.rewriteNamespaceImports` drops the unread item. The scans narrow by `ast.ImportSource.admits` — the module the source names, then the package, then the program — and a source is read as the PATH it spells: `from "app.not_found"` and `from "app/not_found"` both name `app/not_found` (pass 0: the full path, or its last segment), and at pass 1 the path below a package's root names that package's module (`site/app/not_found` for a module of `site` writing it) — after the full path, so a project's own module wins over a dependency's of the same relative path. A dotted source used to be compared byte for byte with the `/` path, and a path of several segments below a package had no reading at all: both named nothing and reached the whole-program scan — where a second module declaring the name (a std module included) made the import that said which module it meant `ambiguous-import-use`, or the backends' `declared pub by … and by …` (`crossModule.pick` shares the predicates) (`conformance/modules/import_same_fn_name_{by_module,two_aliases,in_dependency}`, and `import_sibling_path_beside_std_name` for a std module as the second declarer; `tests/infer_decls.zig`'s `import source` tests). `ImportDecl.leafSource` composes a `/` path under a dotted source for the same reason (`import {c} from "a.b"` binds the namespace `a/b/c`). What is still refused: a package handle two of whose modules declare the name (`modules/import_ambiguous_from_package`); a bare `import {x};` is the shorthand, refused at the item (decision 337, `shorthand-import`). **One local name is one declaration**: `resolveImports` refuses a second import that binds a name another import already bound to a DIFFERENT declaration — `import {title} from "app.page"; import {title} from "app.blog.page";` — as `import-name-collision` at the second item, naming both modules (`env.importOwners` holds the first; the same declaration imported twice, as an `@emit` contribution does, passes). `noteImportBindings` compares the item's path and not its source, so it read the two as one repeated item, the second binding replaced the first, and the backends disagreed (commonJS called the first, erlang and wasm the second) — `modules/import_same_name_twice_unaliased`; under aliases both are legal and each reaches its own declaration, a std module's included (`modules/import_same_fn_name_two_aliases`, `import_same_fn_name_std_and_package_aliases`). A module-level `fn` / `val` / `var` named like an item the module's own imports bind is the same collision, at the declaration's name (`refuseDeclsNamedLikeImports`, ahead of registration in both entries — commonJS used to declare the name twice and refuse to load; `modules/fn_named_like_import`, `modules/val_named_like_import`). **A std module's decorators travel with its namespace import** (`registerStdImportDecorators`, ahead of `validateDecorators` in both entries): `import {testing.mocks} from "std"` registers each `pub fn d(expr decl: unknown, comptime …)` of the module under `mocks.d` through `registerImportedDecorator`, its module functions carried by `decoratorSupport`, and notes the handle in `Env.stdDecoratorHandles`; a plain `#[mocks.x]` naming no decorator of the module is `unknown-annotation`, and a leaf import of a std decorator is `std-decorator-leaf-import` (`markStdImports`). Generic-inference regression guards live in `tests/infer_generics.zig`. A generic enum's unit variant (`Option.None`) carries one fresh var per generic param (C7). `lhs |> f` with `f` a function value types as `f(lhs)`; a pipeline whose RHS arity does not take the piped value is an `arityMismatch` at the RHS (C12). **Tuple labels** (decision 8 §6, 06 N24) live on the `named` type node (`Type.named.labels`), so `instantiateType` carries them — a generic signature (`fn ref<T>() -> #(current: T)`) used to lose them and `r.current` red "this tuple has no element labeled". `row.pop` records a positional rewrite (`row._1`) under `env.enumSectionRewrites`; `inferTupleLabelCall` does the same for a labelled element of FUNCTION type CALLED like a method (`#(value, set: fn(…))`, `c.set(9)` → `c._1(9)`), which the member-access path never saw, and the backends lower `._N(…)` as an index/`element/2`/`call_fun` apply. A constructor call with a `..` spread is a record update: the spread unifies with the record, each labelled arg with the field it names, an unknown label reds at the label (C11). `@RecordKeys(T)` is `array<string>` and `@field(v, "x")` has the field's type (C6); `@typeInfo(T)` is `TypeInfo<T>` (decisions 248, 253 — the record `type_info_src` registers; a non-name argument leaves `T` open). `&&` / `||` / `!` unify TARGET-first and locate at the OPERAND (06 C3): they passed the operand as `unifyAt`'s `a`, so `1 && true` read "expected i32, got bool" with the caret on the whole expression. `-` and `*`/`/`/`%`/`-` constrain their operands to a numeric type (`requireNumericOperand`, permissive for an unresolved type variable and for any name it does not know to be non-numeric): `"a" * "b"` and `-"s"` used to check, since unifying two strings with each other succeeds and `-` constrained nothing. `+` keeps its string concatenation. The branches of an `if` unify only when BOTH end in something that has a value (`stmtsYieldValue`): decision 2 makes a block not-a-value, and unifying a branch that ends in an assignment or a `val`/`var` reds `if (p) { out = …; } else { taking = false; }` with "expected array, got bool" — a shape a library in this repository writes in a `takeWhile`, and the same in a plain fn. Deleting the unification outright waits for the row that removes block-as-value. **Decision 105 (front 22)** — the three loops are statements typed `void` (`inferLoopExpr`): a `while` condition unifies with `bool`; a `for` binds its one name to the ITEM (an array's element, `i32` for a range, an iterator's `T` — `@Iterator<T>` in any body, a `@Result` item handed over as is (decision 122), a `@Stream<T>` only through `for await` (`for-over-stream` / `for-await-expects-stream`)); `for` over a `bool` is `for-over-condition`. `iter loop { … }` / `stream loop { … }` (`inferGeneratorLoop`, decision 125 — `iter while` / `iter for` reach it as the prefixed `loop`) is an expression worth `@Iterator<T>` / `@Stream<T>` (`T` fresh; `@Result<U, E>` when the body has `throw` / `try` of its own, `ast.bodyFails`) and its body is a **closed generator scope**: `starFn`/`fnEffect`/`throwContext`/`useAnchor`/`aliasWrapper`/`returnWhole` replaced for the body, the outer labels moved to `env.closedLabels` (a `break :outer` naming one is `generator-loop-closed-scope`), `loopDepth` restarted at 1, `generatorLoopDepth` counted (a `use` inside is `generator-loop-closed-scope`, behind the parser's static-prefix refusal). The old bool-promotion channel (`env.conditionLoops`) is gone — the parser decides the form. An unresolved enum-section path points its caret at the first segment that does not resolve (N17). **Decision 38 — a `val` is immutable**, local or module-level: `refuseValAssign` (at the assignment's `.name` target) reds `` `x` is a `val` and cannot be assigned `` with a hint naming `var x = …`; it used to check and then throw on node (`const`), not compile on erlang and not validate on wasm. **Annotation families (decision 15, front 17 step 3's recorded row)** — `refuseUnknownAnnotations` (after `validateDecorators`, both program entries) walks every `@`-prefixed annotation on a `fn`, a module `val`/`var`, a type, its fields and methods, and a behavior and its methods: the family (the name up to the first `.`) is `External`, `BeamMemory` or `Host` (`builtin_annotation_families`), or the whole name is an annotation type in `env.decorators`; anything else is `unknown-annotation` at the annotation, naming the family an edit away (`@BeamMemroy` → `@BeamMemory`). The lower-case `@external` keeps `refuseLowerCaseExternal`'s message; the removed effect annotations are the parser's. **Front 17 step 3** — `validateMemoryAnnotations` checks every `#[@BeamMemory.<member>]` on a module binding: the binding is a `var`; the member is `ProcessDict`, `Ets` or `PersistentTerm`; every argument is `keyed` with `true`/`false`; and `keyed: true` needs a `Dict` (decision 51 — an `i32` or a list has no key). **Decision 167** (amends 43) — when `Env.target` is set and is neither erlang nor beam, the same function records the annotation (`Env.offBeamMemory`) and `reportOffBeamMemory` (after `reportStdTargetGates`, once the module is inferred, so the annotation's own rules answer first on every target — `reject/` cells run `botopink check`, whose default target is commonJS) refuses it at its location: "`#[@BeamMemory]` has no meaning on the <t> backend", the target named as `--target` spells it (`node` → `commonJS`); a null target (the language server) reads it as a BEAM target would. **Front 17 step 4** — the same function refuses an `Ets` initialiser that is not a literal or `comptime` expression (`ast.isMemorySeed` — a missing table is re-seeded from it, design §5(d); not purity), and records every module `var` in `Env.memoryVars`; `refuseMemoryWrite` (beside `refuseValAssign`, at the same assignment) refuses a write to a `PersistentTerm` var (written once, at load — §5(a)) and, under `Ets`, a write that recomputes the value from its own (`ast.classifyMemoryWrite` → `.recompose`, §5(b); a `Dict` exempt, decision 42) or an increment of a non-integer (decision 40). The binding is the module's only while `lookup(name)` answers the type it was recorded with, so a local that shadows it is not refused. **Decision 168** — `keyed: true` is `Ets`'s argument alone, never on a `pub` var (an importer would read it whole), and its seed is `Dict.empty()` or `Dict.ofEntries([…])` of literal `#(key, value)` entries (`isKeyedSeed`); the var is then named only as the receiver of its row read `name.at(key)` (`noteKeyedRowRead`, from `inferExprTyped`'s `.call` arm) or of its row write `name = name.insert(key, value)` with a key and a value that do not read it (`checkKeyedWrite`, before the assignment's value is inferred — a row computed from the var's own rows is the recompose refusal, any other write names the one form); every other read is refused at the identifier (`refuseKeyedWholeRead`, in `inferIdentifierExpr`). On erlang and beam alike: the annotation's contract does not depend on which BEAM target runs it. **Declaration names (C-19)** — `buildRecordDeclName`, `buildEnumDeclName` and `buildInterfaceDeclName` name a `type`/`behavior` declaration's binding in the 1.0.3 surface, sharing `appendGenericParamsStr`: `type Name<G>(f: T, …)` (fields inline, body omitted), `type Name<G> { V, V(f: T) }` (compact, as the formatter prints it) and `behavior Name<G> {\n    val x: T;\n    fn m<G>(params) -> R;\n}` (a method keeps its generics and return type). The name is the binding's type, not the instances' (those are `named` by the declared name alone), so the LSP prints it verbatim as completion `detail`; `record { … }` / `enum { … }` / `interface { … }` were the pre-1.0.3 spellings and no longer parse. Pinned by `snapshots/lsp/completion_{decorator_record,type_enum_detail,behavior_detail}`. The legacy `StructDecl` builders (`buildStructDeclName`, `registerStruct`, `validateStructAccessors`, `structFieldType`) are deleted (01 R1): `DeclKind` has no struct variant, so nothing called them, and the one that named a declaration spelled `struct { … }`, a surface that no longer parses. Language-gaps sweep: a method call on a behavior-typed receiver records `.by_value` (`behaviorDeclaresBodyless`), a call of a record's function-typed field records `.type_`, and a method on an unimported nominal records `.unplaced_type`; an implementer converts to its behavior at an annotated `val` and a `var` assignment (`unifyArgument`), as at a parameter; a method call is arity-checked like a function call (`makeMethodCall`); `noteResultPattern` records a `@Result` pattern; `decoratorSupport` collects the module functions a decorator body reaches; a qualified call through a namespace import resolves in `Env.namespaces`. A method body sets `returnWhole` like a fn body, so a returned value already the declared wrapper passes through. **Checker rows (`front/checker-rows`)**: an array literal whose expected element type is a BEHAVIOR meets it element by element (`unifyArgument`), so `val ps: Array<Plugin> = [A(…), B(…)]` holds two implementers; any other expectation stays a hint (it may be a scheme's generic variable). The declaration handle's type names are the type as the source spells it (`declTypeName` — `TypeRef.format`: `Array<string>`, `string[]`, `fn(i32) -> i32`, `#(string, string)`, `?i32`, `@Task<Element>`), never a head and never empty. **01 step 9 — no unlocated unification error**: `unify.zig` sees types, not source, so infer.zig reaches it only as `unifyUnlocated` — inside `unifyAt` / `unifyErrorChannel`, or under a caller that stamps the place with `locateLast` (an `or`-pattern alternative, a union member, a `case`'s arms, a destructured `val`). A call of a behavior's bodyless method on a value of the behavior answers the declared return, `Self` the receiver (`behaviorMethodCallType`) — it was a fresh variable, so a primitive method chained on it found no lowering. A primitive method's own type parameter is what its argument says (`map<U>`'s `U` the lambda's return, a `void`-typed lambda saying nothing; `primMethodReturnTypeFromIface`). Every std module but `std/primitives` dispatches a `default fn` of a primitive interface like any caller (`resolveStdArrayMethod`), so its interface is marked used and commonJS emits the prototype method. A record's constructor pattern binds its names with the record's field types, by label when one is written (`recordPatternFieldTypes`). |
| `unify.zig` | Unification with substitution + occurs check (a failing `unify` copies the `got` side's `Env.resultOrigins` entry onto its `typeMismatch` — E3.9, below). `unify(env, a, b)` is **target-first**: `a` is what the context expects and `b` what was written, which is what makes its two one-way rules sound — an expected `?T` accepting a plain `T`, and decision 8 §2.1's `unknown` (`isUnknown`), which accepts every type **into** it and none **out** of it. The `unknown` rule sits above the kind match because it holds against every kind on the other side, not only `.named`; an unbound variable on either side still links, so inference deciding a type is never mistaken for a use. A third one-way rule: `noreturn` on the VALUE side is the bottom type and unifies with anything, linking nothing (`val x = @todo();` leaves `x` open); an expected `noreturn` still refuses a value. |
| `error.zig` | Structured type errors with source ranges and hints (incl. `missingMethod`/`unknownMethod`/`unknownInterface`/`ambiguousMethod`), plus the comptime gates. `validateComptime` (decisions 266, 331) is the module-level one: a `comptime` may call, loop, build records and lambdas — the comptime runtime runs it (`block_eval.zig`) — but may not read a module-level `val` the block does not declare itself (`'greeting' is a runtime identifier`); two folds that evaluate to an error stay refused, located (`ComptimeError.reason`): a constant zero divisor (`divisionByZero`, C4b) and a negated string (`negatedNonNumber`). The walk is reflective and allocates nothing (`ReadCheck`, `declares`). `isFoldable` is the narrower rule of what `eval.zig` folds in Zig — literals, arithmetic, comparisons, `&&`/`||`, `not`/`-`, array literals, pipelines, `if`, `break` and the block's own locals (`validateBody` threads that scope on the Zig stack, mirroring `eval.zig`'s `Scope`). |
| `effect_chain.zig` | The effect chain (decisions 118, 120, 128 of 1.0.10-beta). `clauses` restates the `extends` clauses `libs/std/src/builtins.d.bp` declares on the wrappers (`Component ⊃ Task`, `Stream ⊃ Task`; `Iterator` has none; `Result` is outside the chain); `wrapperImplements` closes them transitively; `grants(eff, cap)` answers whether a body whose return activates `eff` may write `await` / `use` / `yield`, and is the ONE question those legality checks ask — `throw` / `try` read the fallible channel instead (`infer.zig` `fallibleErrorOf`, decision 121). `refusal` builds the diagnostic, which names the returns that would grant it (decision 67). Its drift tests read `builtins.d.bp` through `std_prelude` and fail in both directions — a clause here that the file does not declare, one the file declares that is not here, a wrapper `EffectKind` names that the file does not declare, and a removed wrapper (`Future`, `Generator`, …) the file still declares. |
| `diagnostics.zig` | Stable diagnostic-code constants (R1–R21, RF1–RF5, RI1–RI6, RC1–RC6, RG1–RG4, D1–D6, `std-unsupported-on-target`, `src-takes-no-arguments`, `unknown-builtin`, `builtin-arguments`, `unknown-primitive-method`, `unknown-annotation`, `effect-try-without-fallible-channel`, `optional-operator-never-null`, `optional-has-no-methods`, `nullish-beside-logical`, `namespace-type-construction`) plus the `all_codes` table. Messages live at the firing site. |
| `embed.zig` | Decision 519 — `@embed(comptime path) -> Asset`. `checkPath` (an absolute path → `.absolute`, a `..` segment → `.outside_package`), `hashHex` (SHA-256, lowercase hex — `Asset.hash`), `asset` (the untyped `Asset(path:, bytes:, size:, hash:)` constructor a read answers, `bytes` a `bytesLit`), `decl_src` (`size: i64`, decision 538) / `typeDecl` (the private record `comptime.zig` `withAssetDecl` splices and a `comptime`'s module carries, `block_eval.findType`). A path through a `comptime` parameter: `paramOfArg` (`p.value` / `p`), `embedParams` (the parameters a body's `@embed` reads, scanned from the `FnDecl` — this module's or an imported one's closure head), `hiddenName` (`__embed_<p>`), `readHiddenParams` (rewrites each such `@embed` in place to the hidden parameter, specialised copies included). The checker half is `infer.zig` `inferEmbedBuiltin` (the read through `Env.packageFiles`, the rewrite in `srcRewrites` and `embedRewrites`, the fresh type node in `assetTypes` that `inferAssetText` reads for `a.text()`; `inferAssetOpen` rewrites `a.open()` (decision 538) into the call `<fs>.openAsset(a)` of std's `io.fs` — `<fs>` the name the module gave `io/fs` in `stdImports`, `embed-open-needs-fs` when it imported none — recorded in `srcRewrites` and spliced by `transform.zig` beside the `text` literal), `noteEmbedCall` (a call's `Asset` arguments, read in the caller's package, `Env.embedCallArgs`, appended by `transform.zig`) and `comptime.zig` `withEmbedParams` (the hidden parameters). |
| `eval.zig` | `ComptimeEntry` / `RunResult` / `evaluate(allocator, entries)` — folds each comptime `val` in Zig (`valueOf`: literals, arithmetic, `not`/`-`, `@TypeOf` name, `@typeInfo`/record literals as objects, a comptime block's / `if`'s / `case`'s / loop's `break` value) and writes the literal backends splice in (`3`, `6.28`, `"text"`, `[1, 2]`, `true`, `null`; objects and nested lists are `null`). **Every operand carries its kind** (`Value`): `binary` folds int arithmetic as int, promotes to `f64` as soon as one side is a float (`3.14 * 2.0 → 6.28`), concatenates two strings on `+`, and returns a `boolean` for `==`/`!=`/`<`/`<=`/`>`/`>=`/`&&`/`||` — so an `if` inside a folded block takes the arm its condition really selects. Anything irreducible (a record operand, a non-constant zero divisor) folds to `null`, never to a stand-in `0`; a constant zero divisor or a negated string never gets here (`validateComptime` refuses it). A `comptime { … }` block has a `Scope`: `blockResult`/`execStmt` declare its `val`/`var` locals, apply `=`/`+=`, and follow an `if` into the arm that `break`s; a nested arm gets a child scope. `RunResult.script` is the listing shown in snapshots as `COMPTIME VALUES`: one `ct_N: <declaration> → literal` per entry, the declaration formatted by `comptime.zig` `evaluateComptime` (`ComptimeEntry.source`; continuation lines aligned). An identifier that is neither a block local nor `true`/`false`/`null` is `error.UnsupportedComptimeValue`. `foldToExpr(arena, te, loc)` (decision 266) answers a body's `comptime` the same way, as plain AST — a number literal (a negative one whole, `-5`), a string, `true`/`false`, `null`, an array of them; null for a record or a non-finite float: `infer.zig` `foldBodyComptime` calls it for every `comptime` node `error.zig` `isFoldable` admits and records the literal in `Env.srcRewrites` at the node's loc, and `transform.zig` `rewriteExpr` splices it — so no backend meets a foldable `comptime` in a body (`modules/comptime_block_in_body`). A node holding a call, a loop or a record runs on the comptime runtime instead (`block_eval.zig`, decision 331). `ComptimeEntry.lifted` is that value as the formatter writes it: `comptime.zig` `evaluateComptime` lists a module-level `val`'s lifted value (`Env.srcRewrites`) in place of a fold. |
| `render.zig` | `extractLine` / `padSpaces` / `digitWidth` helpers for diagnostic rendering. |
| `expand_call.zig` | Decision 562 — a call of a function whose every parameter is `comptime x: T` and whose body reads one (the parser's `.value` form) (`hooks.isExpandedFn`; not a decorator, a template, a component, a host declaration, nor one taking a type) is replaced by the code its body emits. `infer.zig` `inferCallExpr` types the call as written (arity, 417's `comptime-arg-not-known`, 551's catalogue default), then `expand` walks the body with each parameter bound to its argument (`env.srcRewrites` gives a `@TypeInfo.all` query its answer): a `for` over a value known at build or a range is unrolled, an `if` decided, a `val` whose value reaches no run-time value bound, `x.fail(…)` reported at the argument, `return` the expansion's value — each value computed as a `comptime` of it in the caller (`evalBuild` → `infer.inferExprTyped` of a `comptime` node, read back from `srcRewrites`; data — a literal, a record, an array — taken as written; a constant `val` of the module substituted by its initializer). `runRead` tells what reaches the run time: a local the expansion emitted, an entry's `value` (a `Declared(…)` bound at build), a builtin call, a call that is not `infer.callFoldable` (a host, a `Run` function), a method on a name the expansion does not bind; a loop's bound or a condition reaching one is `run-in-build` at it, naming it. Every other statement is emitted, a copy per iteration in an expansion of its own (`Env.expansionCount`), parameters, `val`s and fields of records known at build written as constants (`Copier`); a name of another declaring module (a call's callee included) is bound under its alias (`written_names.bindValue`, the module sharing its privates); its types and namespace imports are imported before the caller is inferred (`importsFor`, from `Reflection.scopes` — `written_names.publish` records each namespace import, `WrittenName.namespace`; `comptime.zig` `withExpansionImports` resolves them as written imports, a type under `written_names.typeAliasOf`, a private one found by that alias, a namespace under `templateAlias`) and named by those aliases in the copies, a `TypeRef` included; a type of that name the caller holds from elsewhere is `import-name-collision` at the call (`typeAliasIn`), and `withTemplateHygiene` makes such a module's private types public to the backends. A refusal located in a copy of another module's body gets that module's file as decision 532's `origin` (its `diagLabelOf`) and the call as its `called from` frame (`locateInOwner`; the caller's own nodes are copied into expansions of their own, `caller_exps`). The statements are a block (decision 525; one that binds nothing is written in place) recorded in `Env.templateExpansions` and spliced by `transform.zig`; the declaration is dropped before the transform (`comptime.zig` `withoutExpandedFns`) and never specialised (`trySpecializeCall`). Not inside a `comptime`, a decorator or a template body, nor without a comptime runtime (the language server). Imported ones: `Env.expandedImports` (`comptime.zig`, by name or `ns.f`). Cells `modules/comptime_expand_*`. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. A comptime parameter read anywhere in the body — a method's receiver and a member read included (`identInExpr`, `x.value.split(",")`) — gets its `const`; the specialization keeps the source's declared return and type parameters (`SpecializedFn.return_type`, injected by `transform.zig`), so a backend reads what it answers (wasm's `fn_arr_elem`). Cell `modules/expr_param_value_receiver`. |
| `context_lower.zig` | Decision 388 — a `@Component<R>` at run time is a lambda over an opaque `RenderScope` (replacing 354 (8)'s hidden map, 374's capture and 387), run by `comptime.zig` on the transformed module (after `transform.transform`; std's `context` module itself is skipped). A fn, a `type` method or a behavior method whose written return is `@Component<R>` itself (`writesComponent`; a bodyless behavior method's return too), and an `implement` method whose behavior declares one, answer `{ bpScope__ -> body' }`; a function typed by an alias (`-> StyledView`) is no component body (118: the alias activates nothing) and answers the lambda another body made, so its hooks node is asynchronous (`infer.zig` `finishHookNode`) and a run of what it answers is awaited: their return becomes `fn(unknown) -> unknown` and their effect none, so a call only makes the lambda and no backend wraps it in a Task. In `body'` each `return v` answers `bpScopeRendered__(v, <kids>)` (a body that ends without one answers `rendered(null, kids)`); `use provide(C, v);` binds `val bpScopeKids__N = bpScopePush__(<kids>, "<C's identity>", v);`; `use context(C)` is `bpScopeFind__(bpScope__, …)`; any other `use h(…)` runs the hook with the received scope, `bpScopeValue__(await (h(…))(bpScope__))`; an `await` of a component value — written (`Env.componentAwaits`, recorded by `inferJumpExpr`) or spliced around a call the checker renders in a body (`Env.componentCalls` at the `await`'s own location) — runs it with the children's scope (`R` `@Renderable`) or the received one (a hook), and outside every component body (a plain function, `main`, a test, a lambda) with `bpScopeRoot__()`; `c.run(scope)` (`Env.componentRuns`, `infer.zig` `inferComponentRun`) is the call of the lambda `c` is. The `await` is left out where the target's node is synchronous (`Env.syncCalls`, 375), so a synchronous component's lambda awaits nothing. A host function answering `@Component` (`Env.hostCalls`, `noteHostCall`) answers the host's value, which nothing runs. A body that keeps a bare `try` (one the transform did not turn into a `return`) runs the statements after its last provide as an inner closure whose answer — the value, or the error the `try` returns early — is the result (`hasBareTry`, `bpScopeResult__`). A lambda is no body: nothing is captured. std's `context.push` / `find` / `rendered` / `valueOf` / `root` are imported under the `bpScope…__` names when the module needs them; `comptime.zig` `expandStdImports` puts std's `context` in every program that writes `@Component`. The pass writes into deep copies (`deepCopy`) of the declarations it lowers — a type's methods, never its shape — since `botopink test` checks a library module again for each test module. The reflective walk is `dsl_hygiene.zig`'s. Decision 504 — each call whose value crosses one of std's `unknown` slots carries the checker's type of that value as its one type argument (`carry`, `callCarrying`; `infer.typeRefOfType` writes a checker type back, null for a variable, a union or a structural record): `bpScopePush__<T>` / `bpScopeFind__<T>` (the context's value type), `bpScopeValue__<R>` (what the run renders), `bpScopeRendered__<R>` (the body's written `@Component<R>`, `Frame.renders`; `bpScopeResult__` is annotated `R`), and a run `(c)(scope)` from `c.run(scope)` carries `Rendered<R>` (`Env.componentRuns` holds `R`). erlang, beam and commonJS ignore a call's type arguments; the wasm backend reads them (`codegen/wat/scope_carry.zig`). Not reached: the comptime runtimes (`erlang.zig` `emitComptimeModule` lowers the parsed program) — `language-gaps.md` row 354-comptime. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. A call with a receiver is never a call of the module's function of that name (`localFnOf`): a module marker `startsWith(expr decl: unknown, comptime prefix: string)` had `t.startsWith("?")`'s argument stripped as a comptime one (`modules/method_named_like_module_fn`). Nor is a free call inference resolved to a parameter or a local of the name (`Env.localCalleeCalls`, the nearest binding): a local named like a function with `comptime` parameters kept none of its arguments (`modules/comptime_fn_name_shadowed_by_local`). A template expansion is substituted until the node is no expanded call: code a template built may itself be a template call, expanded under its own loc (`modules/template_call_in_built_code`). Applies `method_lowerings` (`__bp_<domain>_<op>(…)`), `result_jump_lowerings` (`tryLowerResultJump` — a bare `return;` wraps `null`, decision 74), `templateExpansions`, `srcRewrites` (the `@src()` → `SourceLocation(…)` splice, only onto the builtin call at that loc), `enumSectionRewrites` (`rewriteExpr`), and **`index_rewrites`** (C-02 — the index expression's method call takes the `[]` node's place, after the `@src()` splice and before C-04's fill, so the spliced call still reaches its own lowering, its fill and any nested index; applied by BOTH aggregators, the `src_only` one included, because an index in a method body is the same expression it is in a fn body). Walks `fn` and `test { … }` bodies, including `assert` subexpressions, a parenthesised expression (`.grouped` — `(xs.at(0).unwrapOr(d)).v`, onze F9; an `if` inside a group is `if-operand` since `residual-checker-3`), a unary operand (`-xs.at(0).unwrapOr(1)`) and, in `rewriteStmt`, a call statement (handed to `rewriteExpr` whole, so the loc-keyed rewrites it applies — a record update's complete constructor call, a template expansion, `@src()`, a default fill — reach a call whose value is a lambda's last statement: `xs.map({ b -> Brk(..b, active: false) })` built `Brk(b, false)`, `modules/record_update_on_lambda_parameter`) and every expression statement it has no arm for (the value of an `if` branch — `else s.slice(1) + "/x"` never received its default fill, so erlang called an undefined `string_slice/2`, onze F6; `conformance/modules/string_slice_in_if_branch`). **Method bodies** (`type` and `implement` methods) never went through this walk — the backends lower them from the parsed AST — so they receive the `@src()` splice and the `@Result`/`@Option` `method_lowerings` (onze F4 — `xs.at(i).unwrapOr(d)` in a method was left a call to an undefined `unwrapOr`; `conformance/modules/unwrap_or_positions`), through a second `src_only` aggregator whose other maps are empty; the one unconditional rewrite, the `${}` desugar, runs in both (no backend lowers a template: `return "${n}: ${joined}";` in a type's `pub fn` reached every backend's `stringTemplate => unreachable`, `conformance/modules/template_in_type_method`), so the method walk runs whatever the maps hold; the full walk over method bodies is a separate change (it moves `record_method_with_todo_placeholder` on erlang: `@todo()` would get its default injected there as in a fn body). **Default-value expansion**, in two layers. `applyDefaultFill` (C-04, 01 step 7 N1) is the live one: `rewriteExpr` and `rewriteStmt` look the call's loc up in `default_injections` (`env.defaultInjections`) and rebuild `c.args` from the plan inference recorded — one argument per parameter, in declaration order, the omitted ones `is_default_inj` refs to the param's own default Expr (no new Exprs materialized). It runs BEFORE `tryLowerMethodCall` / `tryLowerStdArrayCall`, which reshape the argument list they are handed, and it runs in BOTH aggregators, the `src_only` one included — a method body's call sites need their defaults as much as a fn body's do. It applies the plan only while the plan still describes the call in front of it (every slot's argument index in range, and as many of them as the call has arguments), so a call some other rewrite got to first is left alone. `expandTrailingDefaults` / `expandTrailingDefaultsWithParams` is the older tail-append, still reached from `rewriteCall` for the two shapes inference never judges — builtin `@fn()` calls and qualified `Enum.Variant(args)` — via `fn_decls` (which also includes `env.stdlibFnDecls`) and `ctor_params` (from `env.ctorParams`; variants registered under bare and `Enum.Variant` names); it is a no-op on a call `applyDefaultFill` already completed. Drops template fns and decorator fns from the output decls. Method bodies (the `src_only` aggregator) receive the `@Result` jump wrappings too — a method returning `@Result` lowers its `throw`/`return` like a function. A `case` at statement position is walked like one in value position (`rewriteStmt`; decision 54's `?T` form still becomes its `if` first), so a `throw` in its arms is the function's `return __bp_error(e)` (144 B-22 step 6) — left unwalked it stayed a raw throw on erlang, beam and commonJS. `qualifyResultPattern` writes a `@Result` pattern as `Result.Ok`/`Result.Error`; `rewriteNamespaceImports` + `namespaceCall` turn `jwt.sign(x)` through `import {jwt} from "sec"` into the aliased import `jwt.sign as __bp_ns_jwt__sign` every backend lowers. **`boolLiteralArm`** (`front/checker-rows-2`): a `case` arm whose pattern is `true` / `false` (carried as `.ident`, which every backend bound as a NAME — `case b { true {…} false {…} }` took its first arm for both) becomes a binder `__bp_case_bool_<i>` and a guard comparing it with the literal, conjoined with a written guard; one binder per bool element of a `.multi` pattern (`modules/case_bool_literal_arms`). |
| `template.zig` | Template infrastructure: `CapturedExpr` (argument bound to an `expr p: T` param, captured unevaluated with provenance), `PlainArg` (`{ paramName, source, call }` — a non-`expr` param or decorator argument that received a literal; `call` names the decorator-module function that builds a decorator argument no literal term carries (decision 280); `toExpr` turns its lexeme into an `erl_ast` expression), `ScopeSnapshot` (origin scope: caller's top-level decls + imports; `toJsonAlloc` feeds the memo key), `CustomNode` + `parseCustomNodeFromTree` (from `template_eval.CustomNodeTree`), and `mapSpanToLoc`/`failDiagnostic` (rustc-style `compiler.fail` diagnostics inside the caller's `` @`…` `` text). With contiguous text `mapSpanToLoc` counts newlines up to `span.start` — on the text's own line it starts after its opening, two bytes for `` @` `` (`CapturedExpr.templateText`, decision 577); for holed multiline templates it falls back to `capture.loc.line + span.line - 1` (`span.line` is 1-based, line 1 = the opening line). |
| `template_eval.zig` | Runs a template body that the V1 classifier cannot reduce. `buildModule` lowers the template `FnDecl` — with the functions its body reaches and the record and enum types they name (decision 331, calls included: `evaluate`'s `support` and `types`, which `infer.zig` `expandTemplateCallViaRuntime` computes as a decorator's — `infer.decoratorSupport` over `Env.fnDecls` and `Env.importedFnSupport` for a local template, `Env.importedTemplateSupport` (by body address, exported by `comptime.zig` `registerExports` under the decorator support keys) for an imported one, then `block_eval.typesReached` skipping `injected_names`) — with `codegen/erlang.zig` `emitComptimeModule` (untyped mode; host enum `DeclKind`; host records `Span`/`CustomNode`/`Source`/`ExprContext`, so `Span(5, 9, 1)` / `CustomNode(kind: …)` build maps) and passes `main/0` as an `erl_ast` form (`mainForms`). The rest of the host glue is **resident** in `bp_comptime_template` (`runtime/prelude.zig`), declared to the emitter as `ComptimeModule.resident` and reached by the `-import` it writes, so nothing but the body, its shims and `main/0` is compiled per evaluation. `main/1` destructures an argument tuple and calls the body with it, so the module carries **nothing** from the call site and its content hash is a hash of the declaration: one `.erl` per template, not one per call site. Each tree parameter's element is `captureToTerm(capture)` — a map tagged `'__bp_capture' => Param` with `text` (raw literal text; holes appear as their `__bp_hole_<param>_<i>` placeholder), `parts` (`#{kind => <<"Text">>, text, span}` / `#{kind => <<"Interp">>, code => Placeholder, span}`), `source`, `context`, `bindings` (each the word's `compiler.lookup` handle when the call computed it — `CapturedExpr.handles`, decision 415 (2) —, else `#{name, kind => 'Type', identity, local}`) and `words` — **decision 237: a capture carries only the bindings its text names**: `appendWords` reads the words of the literal's own text (a word is a maximal `[A-Za-z0-9_]` run whose first byte is not a digit — a botopink identifier's shape; a hole contributes none, nor does its placeholder), deduplicated in order of first appearance, and `bindings` is one scope probe per word, in that order (`<Card title="x"><Badge/></Card>` → `Card`, `Badge`; `"cfg-0"` → none), so the argument is O(text), never O(scope); a plain parameter's element is `plainArgTerm` — the same value `PlainArg.toExpr` renders, as a term, with `lexemeBytes` resolving the escapes `erl_emitter.writeStringFromLexeme` resolves; a lexeme carrying `\u{…}` has **no** exact term (the emitter renders it as Erlang's `\x{…}`, which truncates to a byte in a plain binary) and stays a literal in the module, which keys the module by that literal too. The tuple reaches the runtime as an external term (`runtime/etf.zig`), never as source text re-parsed there. The compilable module is emitted once per **declaration and plan** (`emitKey` → `cachedEmit`/`rememberEmit`, process-lifetime; the key is the declarations' formatted source, the owner, and which `main/1` slots are bound or literal — text, never an address, so an edited declaration in the language server is a new key; `decorator_eval.zig` shares the memo and adds to its key the names of the located functions and, by `appendLocs`, every `ast.Loc` of their declarations — their calls are emitted as frames with their file, line and column (decisions 451 (3), 532), which the formatted source drops, so one decorator compiled at another position in one process (another test, a conformance cell with the same text, an edit above it in the language server) is another key and never raises at the earlier build's lines; `located_errors.zig` holds it), rather than once per call site: `emitComptimeModule` re-lexes and re-parses the embedded `builtins.d.bp` and `primitives.bp` on every emit (`codegen/erlang.zig` `collectBuiltinErlangDispatch`, 02's), which was 55 % of an N=200 build (front 14 step 2). `decorator_eval.zig` shares the memo under its own kind (`"dec"`). Host functions, all resident: `text/1`, `parts/1`, `source/1`, `context/1`, `bindings/1`, `lookup/2` (the handle; `undefined` for a word of the text the scope lacks; a name that is not a word of the text fails the template at its literal — `lookup("<name>"): not a word of the template's text; …`, decision 237), `build/2`, `custom/3`, `fail/2`, `failAt/3`, `compilerError/1`, `expr/1`, `code/1`. `main/1` replies with JSON by result shape — `code`, `value` (`@expr`), `custom` (tree + code), `capture` (`return q`), `fail` (message/param/span), `error` — with `undefined` mapped to `null`. The module atom and file (`.botopinkbuild/tmp/template/bp@comptime@<owner path>__tpl__<template>__<16 hex>.erl`) are A2's declaration-qualified atom (`codegen/crossModule.erlDeclAtom(ownerId(owner), .tpl, tfn.name, hash)`), so a stack trace and a `tmp/template/` listing name WHICH template they came from **and the file it was declared in** (C-01, 13 half 1 step 5): `ownerId` puts the owning module's path under the compiler's own `bp@comptime` namespace (`shapesdsl/shapesdsl` → `bp@comptime@shapesdsl@shapesdsl__tpl__shapesdsl__<hash>`; `crossModule.decodeAtom` reads package `bp`, path `comptime/<owner>` back). The owner is `evaluate`'s `owner` argument, which inference reads off `Env.comptimeOwnerOf(tfn)`: the declaring module records it (`registerFnSignatures`) and an importer records the module that exported it (`comptime.zig` `resolveImports`), keyed by the declaration's body address rather than its name. A declaration no module owns (the unit tests here) keeps `bp@comptime__tpl__…`. The namespace stays `bp` rather than the owner's package: the module is content-addressed scratch shared by every package of the build. The hash is the same Wyhash of the generated code, which no longer sees the capture, so an identical body is still the identical module and re-loading it is still a no-op. `runtime/runtime.zig` `evalWithArg` runs it on the wasm comptime runtime (decision 434), which lowers the text once per atom — and this file imports neither executor; `parseOutcome` maps the reply to `Outcome` (`value` → `TypedValue`, `ast` → `CustomNodeTree` with `ref: ?NodeBinding{name, kind}`), and compile/runtime failures become `err` with the Erlang diagnostic. A lifted map's key order is the reply's canonical one (`typedValue` sorts it — `runtime/reply_order.zig`). A body method call that no primitive type and no host function answers (`emitComptimeModule`'s `unsupported_method` slot) becomes `err` naming the method, its argument count and its `line:col` in the body. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument): the runtime's own listing of the module (`runtime.listingOf`) with `main/1`'s argument under it as comment lines (`argumentListing`, rendered only when a trace is kept — no Erlang listing of the module is rendered for it). `memoKey(arena, callee, captures, plainArgs)` is `infer.zig`'s template memo key: the callee, each capture's text with the scope entries of its **words** (kind, declaration name, identity — or a miss), and each plain argument's lexeme — O(text) like the argument (decision 237), never the whole scope's JSON per call site. On a host that lacks the compilation's runtime (the browser build) the dispatcher answers `unavailable` naming it. Inline tests cover reply parsing. `relabelTupleReads(arena, reads, f)` copies `f` with every tuple element read by its label (`x.kind`) read by its position (`x._0`), from `Env.tupleLabelReads` (inference records each label read's loc and position there, beside the transform's `enumSectionRewrites` entry): the comptime module is lowered untyped from the AST as written, where a label read is a map read (`{badmap, …}`). A local template and its local functions are relabelled with this module's reads where they are expanded; an exported template and the functions it carries are relabelled by `comptime.zig` `registerExports` with its module's reads (`relabelLocal`: only a function of that module — a read is keyed by location). **Decision 355 (01-compiler/14 step 8):** an `Interp` part also carries `known` and `value` (`interpTerm`) — the hole's build value from `CapturedExpr.holeValues` (`infer.zig` `withHoleValues` → `block_eval.holeValue`), `known => false, value => undefined` for a hole computed at render; the spelling is `14s8-a`. |
| `dsl_hygiene.zig` | Decision 112 — each name of a template's built code resolves in the scope of whoever wrote it. `userSpans` finds the consumer's spans (each capture's text, where it reappears verbatim in the built code); `apply` walks the parsed expansion reflectively and renames every other name the template's module declares — a `pub` one, or a private one exported for templates under `envMod.templatePrivateKey` — to an alias `__bp_tpl_<owner>__<name>` (`infer.applyDslHygiene` binds it module-wide and records it in `Env.templateImports`). Names the built code binds itself (lambda parameters, `val`s) and names the library does not declare keep resolving at the call site. `comptime.zig` `withTemplateHygiene` imports each alias from its owner (`import {<path>.<name> as <alias>} from "<pkg>"`) and marks a template-declaring module's private functions and values `pub` for the backends only. A template declared in the module that expands it is left alone. `e.lookup(name)` answers the declaration: the capture's `bindings` carry `local` (the name the call site spells — what `lookup` matches and `ref()` splices), `name` (the declared one) and `identity` (`envMod.declIdentity`, `<module path>@@<Decl>` with `/` as `@`; a root-package path carries no package — 01c-a). |
| `written_names.zig` | Decisions 384, 385 — a name resolves where it was written, wherever the code holding it is read. `publish` (end of `inferProgram` / `inferProgramTyped`) records each top-level `fn` / `val` / `type` / type alias of the module and each import followed to its owner (`Env.importOwners`) in `Reflection.scopes` (`written(module, name)` → `WrittenName{module, name, isType}`). `bindValue` binds a value of another module under `envMod.templateAlias(module, name)` module-wide and records it in `Env.templateImports` (`comptime.zig` `withTemplateHygiene` imports it for the backends), reading `Env.exportsRegistry` — a private through `templatePrivateKey`; `typeImports` writes a type's aliased import for a re-analysis (`import {Violation as __bp_tpl_rules__Violation} from "rules";`), `bindRecorded` re-binds the values (`Env.hygieneImports`, handed by `comptime.zig` `analyzeSource` to `analyzeMerged`). `renameArgs` renames the names of a typed meta value's constructor arguments as written (`dsl_hygiene.applyAll`, formatted back) — `Binder` binds them in the reading module (`infer.zig` `inferTypedMetaRead`), `Collector` records them for a catalogue's re-analysis (`typeinfo_all.zig` `typedSlots`, `Plan.values`). `sharesPrivates` — a module declaring a decorator that hands a member on, or holding an annotation's `expr` meta — exports its privates under `templatePrivateKey` and is marked `pub` for the backends, as a template's module is. `eraseTypeAliases` (`comptime.zig` `registerExports`): a member's type aliases (`Bp__bp_tpl_…`) are this module's checker names only, so the exported type declaration names each type as declared — an importer of the type re-registers its methods' signatures in its own scope (`modules/decorator_member_type_travels`; the libraries' `#[validated]` types imported elsewhere were `unknown type 'Bp__bp_tpl_…'`). `typeNameTaken`: a type this module already holds under the name from elsewhere (decision 310's gap). |
| `block_eval.zig` | Decisions 266, 331 (`01-checker` step 21) — a `comptime <expr>` / `comptime { … }`, at module level or in a body, that `error.zig` `isFoldable` does not admit (a call, a loop, a lambda, a record) runs on the comptime runtime — wasm for every target (decision 434), the one decorators and templates run on — never on the build target, and its value is written into the program. `prepare` copies the block into `'__bp_ct_value'/0` (its own `break v` → `return v`, an `if` arm's too; a loop's stays), splices what inference answered under a builtin's loc (`@TypeInfo.all`, `@src()`) and routes every liftable function value through a maker `'__bp_fn_<i>'/0`: a top-level function written as a value (a lambda calling it) and a lambda reading nothing the block declares (`Preparer.captures`). One code site with no environment makes every evaluation `=:=` to the maker's answer, which is how `'__bp_lift'/2` names a fun on the way back; a value that reaches a module the evaluation does not carry (an `@TypeInfo.all` thunk) is a stub that `@panic`s if the block calls it. `collectSupport` gathers, to a fixed point, the module's functions the code reads (`Env.fnDecls`), imported ones with their closure (`Env.importedFnSupport`), host functions (`#[@External.*]`), and the record/enum types it names (`findType`: `Env.moduleDecls`, std's `Env.stdModuleTypes`, the one module of `Env.typeDeclRegistry` declaring it) with the methods it calls on anything and the helpers of the type's module those reach; a name a body declares itself (a parameter, a local) is no reference (`readFree`). `evaluate` emits it with `codegen/erlang.zig` `emitComptimeModule` (untyped; the decorator prelude resident; `Declared`/`DeclaredMeta`/`SourceLocation` as host records) beside `main/1`, `'__bp_fns'/0` and `'__bp_lift'/2` (raw text, read by the runtime), runs it through `runtime.evalWithArg`, records a `trace` entry (`comptime block`) and reads the reply (`Value`: null, bool, integer, `{float}`, string, list, `{tuple}`, `{record}` map, `{atom}`, `{fn: index \| null}`, `{resource}`). `lift` turns it into the AST every backend emits — a literal (a suffix where the expected type needs one, decision 247; a string's escapes written back), an array, a tuple (labels from the type), a record as its constructor call by labels (the expected type, else the one carried or prelude type with exactly those fields; each field's value against the field's declared type — an enum it names, or the expected type's argument for a type parameter, so `Theme(mode: Mode.Dark)` and `comptime createContext(Mode.Light)`'s `Context(value: …)` lift their atom, `Lifter.fieldHint`, cells `modules/comptime_enum_in_record`, `modules/context_enum_default`), a function as the node the block wrote — each node at a column of its own past any line (`Env.comptimeLiftSeq`), since lowerings are keyed by location; it is not inferred again (the `comptime` was typed, and every function it holds is a node inference already walked). `comptime-value-not-liftable` (located at the `comptime`): a lambda capturing the block's state, a resource, an atom, a non-finite float, a record no reached type declares. `runtimeRead` is `validateComptime`'s twin for a body: a local, a parameter or a module-level `val` read inside is `'x' is a runtime identifier`, at the identifier. `typesReached` gives a decorator module the record and enum types its functions name (a package record an imported helper builds — `routing`'s `parseSegment` building a `Segment`) — `decorator_eval.evaluate`'s `types`. **01-compiler/14 step 8.** A template call the block or a carried function reaches is the code its expansion built (`Env.templateExpansions` by the call's loc: `Preparer.replace`; `expandedFn` copies a function of this module with `expansions_only`); the template module's functions that code names under their aliases are carried as imported ones (`comptime.zig` `importTemplateAliasClosures` binds every `pub fn` closure of the template's module in `Env.importedFnSupport` under `envMod.templateAlias`); a template call left unexpanded (a function declared after the `comptime`) is refused at the `comptime` naming the call (`unexpandedTemplateCall`, called by `infer.foldBodyComptime` and `holeValue`). A lifted record is called by its type's declared name; a type of a module this one neither declares nor imports is imported where the value is written (`Lifter.constructorName`: `Env.templateImports` under the alias, `Env.importedTypeAliases` erasing it). **Decision 355 — a hole's build value**: `knownAtBuild` (a literal, `true`/`false`, a `comptime`, a non-`var` module `val` whose initializer is, a template call already expanded whose arguments all are — `14s8-b`) and `holeValue` (a `val` chain followed to its initializer; a string or `null` literal written directly; anything else evaluated as a `comptime` with `Preparer.inline_vals`, a module `val` read as its initializer; `valueTerm` gives the template module the term — a record its untagged map; a raise is `HoleValue.refused`, refused at the hole by `infer.withHoleValues`, `14s8-c`). **Sections of an enum** (`conformance/docs.md` § Sections of an enum). The module is emitted from the AST as written, where a section path (`.Pad.All.4`) is a chain of map reads (`{badmap, 'Pad'}`): the `Preparer` and `expandedFn` apply inference's untyped rewrites as `transform.zig` does (`sectionRewrite` over `Rewrites.of(env)`: `Env.enumSectionRewrites` — a path chain, a call's callee and arguments — and `Env.indexRewrites` — a leading-dot variant, a leading-dot constructor `.Hover(…)`, a section's payload leaf); `sectionRewritten` / `sectionRewrittenExpr` are the same copy for a decorator's functions (`infer.sameLoweredFn`) and a decorator argument (`infer.decoratorArgValue`). `findType` gives an enum carrying sections with a wrapper variant `<Section>(_inner: __<Enum>__<Section>)` per section (`withSectionWrappers`) and answers a section's own type `__<Enum>__<Section>[__<Sub>…]` from the enum's declaration (`sectionType`: a numeric leaf `__4`, a wrapper per sub-section — what `comptime.zig` `withSynthesisedEnumDecls` gives the backends); `readTypeShape` reads an enum's payload types, so the sections a carried enum names are carried. An exported function arrives already rewritten (the exporting module's transform rewrote its AST in place). A function of this module declared after the `comptime` was not inferred, so a section path in it has no rewrite: `unresolvedSectionPath` refuses the `comptime` naming the path, its root's `line:col` and the function (`modules/comptime_section_path_declared_after`), beside `unexpandedTemplateCall`. On the way back the `Lifter` writes an atom or a tagged tuple as the variant of the expected enum (`enumHint`, `?Tok` read as `Tok`; `variant`): `Tok.Bold`, `Tok.Hover(inner: …)`, a section as its wrapper chain `Tok.Pad(_inner: __Tok__Pad.All(_inner: __Tok__Pad__All.__8))`, each payload against its field's type; an atom no expected enum declares stays `comptime-value-not-liftable`. Cells: `modules/comptime_enum_section_value`, `modules/comptime_decorator_section_value`, `modules/comptime_imported_section_path`. 01-compiler/14 step 8 — **an imported `val` known at build**: a module exports, beside a `pub val` whose initializer is known at build, its value (`exportedBuildValue`, evaluated without a trace, written by `termJson` and carried in `decoratorRegistry` under `<path>\x00<name>\x00build`); `resolveImports` binds it in `Env.importedBuildValues`, and `knownAtBuild` / `holeValue` read a hole naming it as a `val` of the module (`modules/hole_imported_val_known_at_build`). **A private type of another module** a carried function constructs (emilia's `Placed`) is found under `comptime.private_type_prefix` (`findDeclared`). **Decision 451 (3) — a raise is located at the call that raised**: the block's functions and the functions of this module it reaches (`Support.located`) are emitted with `ComptimeModule.located`, so each call they write is a frame (`codegen/erlang.zig` `framed`, decision 532); a raise leaves its frames in the process dictionary, `main/1`'s `catch` replies them as `frames` (`'__bp_frames'/1`), and `parseReply` answers `Outcome.raised` (`framesOf`, innermost first, each with its file) — reported at the first, in its own file, every other a `called from` line down to the `comptime` expression that ran it (`infer.foldBodyComptime`, `block_eval.raisedError`, `holeValue`). `decorator_eval` does the same for a decorator of this module and its helpers (`evaluate`'s `located`, `Outcome.raised`; the annotation is the frame), and `template_eval` for another module's template and its module's functions (`evaluate`'s `located`, keyed as a decorator's; refused at the call site, the message naming the template's file). A call of another module's function is a frame in that module's file (decision 532: `Support.located` names the imported closures' functions with their files); a call a template expansion wrote takes the frame of the template's use (`Preparer.use_loc`: every location of the copied expansion is the use's).  A comptime module carries what the transform does for the program: each `@Result` method call as its `__bp_<domain>_<op>` builtin and each `@Result` body's `return` / `throw` as `__bp_ok` / `__bp_error` (`withResultMethods`, cell `modules/comptime_result_methods`); a number literal's suffix is stripped where the erlang emitter writes it, and a lifted number's after the transform splices it (cell `modules/comptime_wide_literal`). |
| `host_cells.zig` | Decisions 341, 331 — what a body that runs at build may call on the host. **std travels**: `comptime.registerStdlib` builds `Env.stdCarried` once (`buildStdCarried`), each function with its module's own `@Result` / `@Option` lowerings applied (`block_eval.withResultMethods` over the module's inference: a `return v` / `throw e` of a `@Result` body is `__bp_ok` / `__bp_error`, as every backend writes it): every std function renamed `__bp_std__<module>__<name>` (`mangle`), its calls of its module's functions and of the std functions it imports renamed so, an `.Wasm(body: x)` binding naming `x`'s carried name; `Writer` renames the std calls a module writes — through a namespace (`hash.contentHash(x)`) or a leaf import — reading the module's own `import … from "std"` (`stdTable`), one copy per function (`Env.stdRewritten`, so two closures carrying a function carry one). `hostSupport` answers what a comptime module's functions need beside them: the bodyless host functions they name, the function a `fn:` binding names and what it calls, the carried std closure. Called by `block_eval.prepare` / `collectSupport`, `infer.zig`'s decorator and template evaluation (a local body), and `comptime.zig` `registerExports` (`exportedFn` / `exportedSupport`: an export carries its std calls renamed and its host functions). **The comptime runtime resolves each host function in order** (`forRuntime`, in each evaluator's `buildModule`; decision 434 (4)): a host function whose `.Wasm(std: "<module>.<function>")` cell names a function `modules/std-wasm` implements (`stdWasm.exports`, `stdCell`; decision 440 (3) — never a match by name; a name std-wasm lacks is `comptime-host-cell-unavailable`, and refused at the annotation by `infer.zig` `refuseStdBinding` first) becomes one cell `.Erlang("bp_std_wasm", "<symbol>")` (`servedByStdWasm`) — the module writes `bp_std_wasm:hash__contentHash(S)`, the wat lowering calls `rt_std_hash__contentHash`; else `fn <f>(…) { return <x>(…); }` for `.Wasm(body: x)` (`callOf`); one adapter has a form at build, `wasi: .Attempt` (std's `failure.caught`, decisions 518, 543 — `attemptAtBuild`: the thunk under an Erlang `try` catching `{panic, M}`, `{todo, M}` and a failed assert's panic text, so `attempt` answers in a comptime body as in a wasm program; cell `modules/comptime_attempt_at_build`); none → refused naming both cells (`comptime-host-cell-unavailable`). An `.Erlang` cell never runs at build (decision 452: it binds the erlang and beam targets alone; beam-to-wasm is a standalone utility botopink does not call, and compiler-core imports nothing of it — `build.zig` wires it to its own tests only). **A decorator's host functions are checked when its package is compiled** (`checkDecorators`, from `comptime.zig` `analyzeSource` before inference; decisions 341, 434): a host function a decorator reaches — in its body, a function of its module, a std or an imported closure — that neither cell serves (`unservedReason`) is refused at the call, whatever the package's `targets`. Cells: `modules/decorator_host_cells`, `modules/comptime_std_host_function`, `modules/decorator_imported_host_function`, `modules/comptime_host_cell_unavailable`, `modules/comptime_host_cell_unavailable_erlang_only`, `modules/comptime_erlang_cell_ignored_fn_serves`; `decorator_invocation.zig`'s round trip (the reply byte-identical on beam and wat). |
| `decorator_eval.zig` | Runs a decorator body over the declaration it annotates. Input: a native `DeclHandle` (`kind`/`name`/`fields: []FieldHandle`/`variants`/`methods`/`returnType`/`annotations`; `variants` lists an enum-shaped `type`'s variant and section names and is empty otherwise — with `DeclKind.Type` covering both shapes it is how a decorator tells a record from an enum; `owner` — decision 526, `decl.owner` — the `Declared<unknown>` term (`hooks.zig` `declaredTerm`) of the type or behavior that holds an annotated method or field, set by `infer.zig` `withOwner` from `runDeclDecorators`' member owner, `undefined` on every other handle) built by `infer.zig`. `buildModule` lowers the decorator `FnDecl` — with the functions of its own module its body reaches, directly or through one another (`infer.decoratorSupport`: computed from `Env.fnDecls` for a local decorator, carried beside an imported one in `decoratorRegistry` under `comptime.zig` `decoratorSupportKey`; a function the module IMPORTS travels with what it reaches in its own module — `comptime.zig` registers every `pub fn`'s closure under `decoratorClosureKey` and the importer binds it in `Env.importedFnSupport`; two DIFFERENT functions of one name reaching one decorator module are refused where the decorator is applied, `infer.Support.conflict`) — with `codegen/erlang.zig` `emitComptimeModule` (untyped mode, `DeclKind` as host enum, `Span` as host record, `main/0` exported) and passes `main/1` as a `codegen/beam/erl_ast.zig` form built with `Ast.Builder` (`mainForms`); it destructures the argument tuple, so the module carries nothing from the declaration it runs over and its hash is a hash of the decorator plus its annotation arguments. `fail/2`, `failAt/3`, `compilerError/1` (throw a tagged rejection) and `emit/1` / `'__bp_emitted'/0` (process-dictionary accumulator) are **resident** in `bp_comptime_decorator` (`runtime/prelude.zig`), reached by the `-import` the emitter writes. `main/1`'s argument is `handleToTerm(handle)` (a `codegen/beam/term.zig` map — `kind` as atom, names as binaries, annotation args as raw lexemes) followed by one value per parameter (`templateEval.plainArgTerm`, or `undefined` for a plan built by a `PlainArg.call` function), encoded by `runtime/etf.zig` and replies with JSON `{kind: ok, contributions} \| {kind: fail, message, span} \| {kind: error, message}`. The module atom and file (`.botopinkbuild/tmp/decorator/bp@comptime@<owner path>__dec__<decorator>__<hash>.erl`, `templateEval.ownerId` — the same owner rule as a template's) come from the code's hash, which no longer sees the handle. `runtime/runtime.zig` `evalWithArg` runs it on the wasm comptime runtime — this file imports no executor; `parseOutcome` maps the reply to `Outcome` (`ok` / `fail{message, span}` / `err`), compile/runtime failures become `err` with the runtime's diagnostic (truncated to 4 KiB), and an `unavailable` runtime (none on this host, a broken `erl` transport) becomes `err` with its reason. A body method call that no primitive type and no host function answers becomes `err` naming the method, its argument count and its `line:col`. Every run appends a `trace.Entry` (`evaluate`'s `traces` argument): the runtime's own listing of the module (`runtime.listingOf`) with `main/1`'s argument under it as comment lines (`argumentListing`, rendered only when a trace is kept — no Erlang listing of the module is rendered for it). `memoKey(arena, callee, captures, plainArgs)` is `infer.zig`'s template memo key: the callee, each capture's text with the scope entries of its **words** (kind, declaration name, identity — or a miss), and each plain argument's lexeme — O(text) like the argument (decision 237), never the whole scope's JSON per call site. A runtime the host lacks (the browser build) is refused by the dispatcher with the runtime named. Decision 280: a plan whose `PlainArg.call` is set calls that zero-argument builder in `main/1` instead of binding a term; the host records `__bp_FieldKey` / `__bp_DeclAnnotation` lower a field key to the map a `decl.fields` entry is. Decision 277: `DeclHandle.hooks` (the terms `hooks.nodesToTerm` built) is the handle's `hooks` entry, and every annotation map carries `decorator`, the identity `DeclHandle.decoratorIds` gives its name. Inline tests cover the module shape and reply parsing. **Each invocation is independent** (decision 343): `checkIndependent` (from `comptime.zig` `analyzeSource`, before inference) refuses a decorator whose body — or a function of its module the body calls — writes a module-level `var` (`moduleVarWrite`), `decorator-writes-module-var` at the write, the hint pointing at `@TypeInfo.all(with: …)` at the entry point (`modules/decorator_writes_module_var`; a duplicate refused there naming both, `modules/typeinfo_all_duplicate_at_entry`); it used to be `unbound variable` at the read. | **Memory (144 B-117):** a call's module source and tree, encoded argument, runtime reply and listing build are scratch (a `page_allocator` arena freed at the end of `evaluate`), and `infer.runDeclDecorators` / `runTagAnnotation` erase the decorator and its support functions into a scratch arena of their own; only the `Outcome` and the trace entry (`listing`, `reply`) live in the session arena. `tests/decorator_invocation.zig` bounds the resident-set growth of 60 calls by what their traces keep.
| `hooks.zig` | Decision 277 — `decl.hooks: HookNode[]`. The model (`DeclRef`, `Annotation` with its decorator's identity, `TypeArg`, `Use`, `Call`, `Node`, `FnInfo`), `Builder` (one node being recorded), `nodesToTerm` (the `HookNode` maps a decorator body reads; a `Declared`'s `value` is `undefined`, its `meta` every entry keyed `<decorator>.<key>` through `MetaSource`) and `readsMember` (the reflective walk telling whether a decorator or a function it reaches reads `.hooks`). The computation is `infer.zig`'s: `inferFnDecl` gives a top-level function's body a `Builder` (`Env.hookBuilder`, `isModuleFn`; a lambda keeps its function's); `inferUseHookExpr` records each `use` (`noteHookUse`: the hook's declaration — `hookCalleeDecl`, null over a parameter or a local —, its annotations resolved in its module, the explicit type arguments `hookTypeArg`, std's `provide` / `context` with the context `val`, 354 (4)); `noteComponentCall` records each call (`noteHookCall`, not a `use`'s own operand, not a function value), kept when its type resolved to `@Component<R>` (`finishHookNode` → `Env.hookNodes`). Decision 389 — a `@Component` function named as a value (`inferIdentifierExpr` → `noteComponentValue`: `itens.map(Card)`, a `val`, a record field, any argument; not a local) is an edge as a call is, and a component value the checker cannot follow — a function value or a method called, or a declared function whose own return is no `@Component` answering one through its type arguments (`noteHookCall`) — is an edge with `callee: null` (`Builder.dynamicCalls` with its place; `HookCall.callee` is `?Declared<unknown>`), the edges sorted into body order. Cells `modules/decl_hooks_component_value`, `modules/decl_hooks_dynamic_call`. The end of a module's analysis publishes every top-level function (`publishHookFns` → `Reflection.hookFns`, by `declIdentity`; a host — `declare fn`, `#[@External…]` — and std's `context` module get no node). `invokeDecorators(…, .hooksReaders)` fills a function's handle with `declHooksTerm` → `declHooks`, only when one of its decorators reads `.hooks` (`decoratorsReadHooks`): breadth-first from the function, each node's `use`s and calls merged by position, each function once (`hookNodeOf`: this module's node, recorded by Pass 2; another module's from the session). **Decision 372 (provisional) — a `.hooks` reader runs last:** `inferProgram(Typed)` runs a module's decorators in two phases (`DecoratorPhase`): `invokeDecorators(…, .plain)` before the bodies runs every decorator that reads no `.hooks` (`decoratorReadsHooks`, per annotation) and records every catalogue entry, a reader's included; after Pass 2, `runHooksReaders` runs the readers over the inferred bodies (in whichever analysis infers them — the first, or the re-analysis that spliced the first phase's members and types; once, `Env.hooksReadersRan`). A reader records meta or refuses: `refuseHooksReaderOutputs` refuses, at the call (`outputCall`: `@emit(…)`, `addMember(…)` / `addType(…)` on a receiver), a decorator of the module that reads `.hooks` in its body or a function of its module it reaches — `decorator-hooks-output`, at the decorator's name when the call is in a function of another module —, and an emit, member or type a reader's run returns anyway is the same refusal at the annotation. A `@typeInfo(X).meta.<d>.<k>` read of this module's `X` whose `#[d]` is a reader (`noteHooksReaders` → `Env.hooksReaders`) is inferred as a pending `""` literal in `srcRewrites` (`Env.deferredMetaReads`) and filled, or refused `typeinfo-meta-missing` at the read, when the reader ran (`answerDeferredMetaReads`). A `@TypeInfo.all` whose `with:` names a reader of this module (`Env.hooksReaderIds`) is `typeinfo-all-hooks-reader` at the name (`refuseCatalogueOfHooksReader`): its answer is spliced before the reader runs. Cells: `modules/decl_hooks_reads_member`, `modules/decorator_hooks_output`, `modules/decorator_hooks_output_member_fn` (decision 370's `addMember(name, fn…)`), `modules/typeinfo_all_hooks_reader`. `runDeclDecorators` completes every handle with its annotations' decorator identities (`completeHandle`, `annotationDecoratorId`: an alias or a namespace gives the declaration, a builtin is `@<name>`). Decision 375 — `Node.is_async` (the term's `async`): `Builder.is_async` is set by a written `await` (`inferJumpExpr`), an `async { … }` (`inferAsyncBlock`), a `use` with `hook: null` or of a host hook (`noteHookUse`) and a call of a host function answering `@Task` / `@Component` (`noteAsyncCall`, `hostCallee`); a call of a function value or a method is kept by type (`Builder.dynamicCalls`) and makes the node asynchronous when it resolves to `@Component<R>` or stays open (`finishHookNode`). `markHookAsync` runs once the module's bodies are inferred, before the `.hooks` readers: a node reaching an asynchronous one through a `use` or a call is asynchronous until nothing changes (a cycle with one asynchronous node is asynchronous); a target with no node (a host, a declaration the session did not publish) is asynchronous, std's `provide` / `context` are not (`hookTargetAsync`). It then fills `Env.syncFns` and `Env.syncCalls` (every call of a `@Component` and `use` of a hook, by location, `Env.hookTargets`, whose target is synchronous), which `comptime.zig` hands commonJS as `OkData.sync_fns` / `sync_calls`. Cells: `run/decl_hooks_*`, `modules/decl_hooks_imported`, `modules/decl_hooks_async`, `modules/decl_hooks_async_imported`, `modules/component_sync_plain_function`. Question 04s12-a's answer (1) — a `@Component` method is marked by its body as a top-level function is: `inferTypeMethods` gives its body a `Builder` and keeps it in `Env.methodHooks` (`<Type>.<method>`); `noteAsyncCall` notes each method call's target (`Env.methodCallTargets`), and a top-level function's call of such a method is an edge (`Env.methodEdges`) instead of an asynchronous mark; `markHookAsync` marks the methods (their `await`s, the hooks they `use`, the components they call), re-marks the nodes reaching an asynchronous one, and puts the synchronous methods in `Env.syncFns` and their calls in `Env.syncCalls` — commonJS's `methodShape` and its `await` drop read them. A behavior's `default fn` (inferred under the behavior's name, `inferBehaviorDefaultBodies`) and an enum's method are keyed the same way; a call of an adopted `default fn` resolves through the type's `implements` (`noteMethodCallTarget`). Cells `modules/component_method_sync`, `modules/component_default_fn_sync`. **Decision 376 — `Node.stage` (`Build`, `Run`, `Any`; the term's `stage`, `builtins.d.bp`'s `Stage`, a host enum of the decorator and template modules):** `inferFnDecl` sets `Builder.build` from `hooks.buildResource` (the first read, outside a `comptime`, of a `comptime` parameter or the declaration handle; none in a function expanded at its call site, `hooks.isExpandedFn`, decision 562); `noteStageCall` (every call, nothing under a `comptime`, `Env.comptimeDepth`) sets `Builder.run` for a host function not declared `#[@Stage.Any]` (`hostStage`) and a std function that reaches one (`stdCallee` — a std namespace or a leaf import, `Env.stdLeafFns` —, `stdStage`: the std module's published stage, else `stdFnStage` over its declarations), and records each call of a declaration (`Builder.stageCalls`); a method, a function value and std's `provide` / `context` give nothing. `finishHookNode` keeps them (`Env.stageFacts`); `markStages` (after `markHookAsync`, before the readers) computes each function's stage in declaration order (`stageOfOwn`: own resources joined with the callees' stages, `stageOfRef` — another module's as `publishHookFns` published it, `FnInfo.stage`; a cycle adds nothing; a decorator's or a template's body is `Build`), and `Build` with `Run` is `build-and-run` at the second, naming the first. Cells `modules/stage_of_functions`, `modules/stage_imported`, `modules/stage_build_and_run`, `modules/stage_comptime_block_in_run`. **Decision 380 — `Node.foldable`:** a function is computed at build when it is `any` and neither it nor a callee writes a `StageFacts.blocker` (`hooks.foldBlocker`: `@panic` / `@todo` / `@trap` / `throw`, `@print` / `@println` / `@debug`, a module `var`; `noteStageCall`: a function value or a method of a declared type, `callOnPureReceiver`, a record or variant constructor being data, `isConstructorCall`); a template call gives its caller no stage (the built code does). A host function is foldable only when the comptime runtime answers it — a `std:` cell or a `fn:` body (`servedAtBuild`; an `op:` instruction is the wasm target's). `block_eval.knownAtBuild` admits a call of such a function with arguments known at build (`Env.foldableCall` → `callFoldable`; this module's function computed on demand, `foldableNow` / `factsComplete`, one declared later not), an operator and a group over values known at build — so a `${…}` hole or a `val` named by one is computed at build (355). Cells `modules/hole_any_call_at_build`, `modules/hole_any_call_raises`, `modules/styled_holes_known_at_build`. |
| `decorator_same.zig` | Decision 371 — `d.same(other)`, `fn same(self: Self, other: Decorator) -> bool` of `builtins.d.bp`'s `Decorator`. The checker types it (`infer.zig` `inferDecoratorSame`, from `inferCallExprWith` when the receiver is a `Decorator`): `other` is a decorator's name — `decoratorNameId`: the identity `annotationDecoratorId` gives an annotation of that spelling, an alias and a namespace resolved here; a local of the body shadows the name, but for the self-recursion binding of the decorator's own name — or a `Decorator` value; anything else is the mismatch at the argument (`modules/decorator_same_not_decorator`). Each call is recorded in `Env.decoratorSame` by location. A `Decorator` is carried on the comptime runtime as its identity (`hooks.zig` `annotationsTerm`), so `lower` copies a function with each recorded call replaced by `receiver == other`, a name in `other` the string literal of its identity; `mentionsSame` is the syntactic test. A local decorator's run lowers it and the functions of its module it reaches (`infer.zig` `sameLoweredFn`: a body that writes `same` — or a section path, `block_eval.writesSectionPath`, carried rewritten — is inferred ahead of the run, once, after the module's imports and `val`s); `comptime.zig` `registerExports` lowers an exported decorator, its support and a `pub fn`'s closure with the module's own calls (`infer.lowerDecoratorSame`, only a function of that module — a call is keyed by location). Cell: `modules/decorator_same` (a same-named decorator of another package). |
| `reflection.zig` | Decision 216 — the compile session's `Reflection` (`comptime.zig` `compile` / `compileTypesOnly` create it, threaded to every module's `Env.reflection`): `meta`, keyed by `env.declIdentity(module, name)`, the `MetaEntry{decorator, key, value}` list each `decl.setMeta` appended while the declaration's module was analysed (`addMeta` answers false for a key the decorator already set), `typedMeta` keyed the same way — decision 298's `TypedMetaEntry{typeModule, typeName, typePub, args, repeat, hasExpr, annotationModule, decorator}` list (`addTypedMeta` false for a second value of a type held once) — and `decoratorMetaTypes` (`decoratorKey(module, decorator)` → the `MetaCallType` of each typed meta call of its body, resolved where it is declared), and `assoc`, keyed the same way by owner, the names of its associated types (`addAssoc` false for a second one of a name). Written before any body of the module is inferred, read by `@typeInfo` and `assoc_types.zig` in that module and in every importer. Decision 353: `templateQueries` (a template body's resolved queries, `TemplateQuery`), `templateReads` (each answer given, `TemplateRead`) and `oracle` (an earlier session's complete reflection a template answer is read from). Decision 277: `hookFns`, each analysed module's top-level functions with their hook nodes (`hooks.zig`). |
| `builtins.zig` | Decision 252. `table` — one row per `@name` builtin call the checker or a backend implements: its name (`TypeInfo.all` for the static method), the signature its declaration spells (`renderSignature`'s canonical `name<G>(comptime p: T = d, …) -> R`), whether it is COMPTIME-ONLY, and how a call is held (`Held`): `.declaration` (arity, labels and argument types against `Env.builtinDecls` — `infer.zig` `checkBuiltinArguments`, `builtin-arguments`), or `.own_rule` (`@src`, `@typeInfo`, `@comptimeError` refuse first by their own rule; `@TypeInfo.all` is held `.declaration` — its `with:` typed by `decoratorArgumentType`, `checkCatalogueArguments`, decision 268 — after `typeinfo_all.plan`'s shape rule). `@print`/`@println`/`@debug` are declared `(..values: unknown[])` (decision 267) and held `.declaration`: `checkDeclaredArguments` binds every unlabelled argument past the fixed parameters to the variadic, each against its element type, and refuses a label naming it. `@getContext` left with decision 354: a hand-written `@getContext(…)` is `unknown-builtin`, naming `use context(C)` (`modules/getcontext_removed`). `find`, `neverReturns` (read by `inferBuiltinCallReturnType`'s fallback and `callNeverReturns`) and the `unknown-builtin` suggestions all read the table. `collectDeclared` parses `builtins.d.bp` + `builtins_fns.d.bp` (every top-level `declare fn` — an unannotated one is a `DelegateDecl` — and every static `declare fn` of a type), `drift` compares both ways; `methods` — the builtin methods inference implements on a builtin type (`Result`'s five; `infer.zig` reads `hasMethod`) — and `collectTypes` / `typeDrift` walk the types: every type `comptime.zig` `builtin_type_mirrors` registers (the declaration-handle cluster, `CustomNode`, `TypeInfo`, `RecordField`, `YieldStep`; `__Decl__X` read through its alias) has a declaration with the same fields, variants and instance methods, and every `methods` row its `declare fn` in the owner's body (an instance method of an owner with no row is named too); the tests fail naming the builtin (`undeclared`, `unimplemented`, `signature` with both spellings) and prove each kind against an altered copy of the file. `comptime.zig` `registerBuiltinDecls` fills `Env.builtinDecls` from the same two files (copied into each std module's scratch env). |
| `assoc_types.zig` | Decision 216 (3). `expand(arena, program, owners)` rewrites, in place and reflectively (the `std_namespace.zig` walk), every use of an associated type into the top-level type its decorator declared (`env.assocTypeName`: `City.Columns` → `City__Columns` — not the `__Token__Text` of an enum section, which the backends read as "a section of the enum `Token`" and tag with the outer enum's module): a `TypeRef` `Owner.Name`, a call `Owner.Name(…)` (the receiver dropped — a constructor call), a path `Owner.Name.Variant` (the inner access becomes the name). `owners` (`comptime.zig` `assocOwners`) maps each local name to its owner — a type or behavior of the module with entries in `Reflection.assoc`, or an imported one, found the way `resolveImports` finds a type, under an alias too; for an imported owner the item of every associated type used is appended to the owner's import declaration. A type declared in the owner's body (decision 330 (7), `nested_types.zig`) is an associated type too: `assocOwners` adds its name for a type of the module and for an imported one — std's included, whose owners answer only through their body (`Type.Field<T>`); a generic use `Owner.Name<T>` is rewritten like a plain one. Runs in `analyzeSource` (after `std_namespace.expand`), in `analyzeMerged` (where the module's own associated types exist) and on every embedded std module `registerStdlib` infers, with the owners its own body declares — so a member of `Type` taking `comptime ..fields: Type.Field<T>[]` reaches an importer as `Type__Field`, not as a dotted name its env cannot resolve. A value of one prints under its owner's path (`City.Columns(…)`, `City.Size.Small`): `mergeAssocTypes` sets `TypeDecl.displayName`, which every backend's record and enum display reads through `printedName()` — commonJS's `prototype.__bp`, erlang's and beam's `'__bp_format'/1`, wasm's descriptor name. |
| `typeinfo_all.zig` | Decision 216 (4). `reads(program)` is the test `comptime.zig` `orderReaders` moves a module by — a CALL of `@TypeInfo.all` in its parse outside a template function's body (`collect`; `isTemplateFn` = a fn whose first parameter is `expr q: string`), so a comment or a string literal spelling it reads nothing (`modules/typeinfo_all_spelled_in_string`), and neither does a template body's query (decision 353, below): every module reading `@TypeInfo.all` is analysed after all the others (noted in `Reflection.readers`), and an import of one is `typeinfo-all-imported` at the import. `collect(program)` finds the queries; a module with any stops its first analysis before bodies (`Env.typeinfoAllPending`). After the first analysis ran the module's own decorators, `plan` resolves each query: `with:` names a body-carrying decorator (labels checked — `typeinfo-all-arguments`), identified by its declaring module and name — a query whose `with:` names anything else is left unanswered, and inference holds the call to its declaration (`with: Decorator | Decorator[]`, decision 268: `infer.zig` `checkCatalogueArguments`, where `decoratorArgumentType` gives a decorator's name the type `Decorator` and an array literal of them `Decorator[]`, so anything else is the ordinary mismatch at the argument); the answer is every `Reflection.declared` entry carrying it — every module but the other readers, plus the reader itself — sorted by module path then recording order (source order), as an array literal of `Declared<unknown>(name:, module:, meta: [DeclaredMeta(key:, value:)…], returnTypeName:, value:)` (`returnTypeName` the function's declared return type as spelled, `""` for a type — decision 256, `DeclaredEntry.returnTypeName`) whose `value` is the function, or for types `{ -> T.<member>() }` (`member:` required, `typeinfo-all-needs-member`, unless every listed decorator's `expr decl: B` names a behavior — decision 564 below; one kind per query, `typeinfo-all-mixed`). **Decision 564 — a decorator's behavior.** `resolve` reads each decorator's `expr decl: B` (`declBehavior`: a `behavior` of the module, or `DecoratorSig.declBehavior`, which `comptime.zig` `resolveImports` sets for an imported decorator from its module's `typeDeclRegistry`) into `TemplateQuery.typed` / `.behavior` (the one behavior every listed decorator names, null when they differ); with no `member:` such a type entry's `value` is `null` and `Plan.behaviors` (→ `Env.typeinfoAllBehaviors`) has `inferCatalogueAnswer` type the answer `Declared<B>[]` (a default's parameter likewise, `noteDefaultQueries`). `infer.zig` `checkDecoratorArgs` refuses `#[d]` on a declaration that is not a type implementing `B` (`typeImplementsBehavior`), and `refuseBehaviorCallOnEntry` refuses `d.value.f()` (`d: Declared<B>`, `f` a function of `B`) outside a 562 expansion (`Env.inExpansion`: an expanded function's body, `expand_call.expand`). Cells: `modules/decorator_decl_behavior_not_implemented`, `typeinfo_all_behavior_typed`, `typeinfo_all_behavior_shared`, `typeinfo_all_behavior_none_shared`, `typeinfo_all_behavior_call_outside_expansion`. A declaration of another module is reached through an `import {N as __bp_ti_<k>} from "<path>"` the plan adds, so it must be `pub` (`typeinfo-all-private`). The re-analysis (`analyzeMerged`) gets the answers in `Env.typeinfoAll`; inference splices one at its call through `srcRewrites` and types it `Declared<unknown>[]` whatever its entries are (decision 254, `inferCatalogueAnswer`: each entry inferred alone, met by `Declared<unknown>` and given that type, so entries of different value types never unify with each other; a use narrows `value` with `is`), and sets `usesDeclared`, which splices the prelude records into the module (`withDeclaredDecls`). `with:` takes one decorator or a list of them (decision 235): one answer in the one order, a declaration carrying two listed decorators once, its meta from every listed one; a name listed twice is `typeinfo-all-arguments`. **Decision 353 — a template body's query.** `collectTemplates` finds each template function's queries; `infer.zig` `noteTemplateQueries` (after the module's decorators ran) resolves their arguments in the template's own module (`resolve`, the same argument rules and decorator identity `plan` uses, refused at the query) and records them in `Reflection.templateQueries` under `Reflection.templateKey(owner, name)`. `infer.zig` `answerTemplateQueries`, from `expandTemplateCallViaRuntime` (a body with queries is never reduced by `classifyTemplateBody`), answers each for the program the call is compiled in (`answerForTemplate`: every module's entries — no reader excluded — from `Reflection.oracle` when set, else the session's reflection; the rules of `checkEntries` — one kind, `member:` for types, `pub` — refused at the expansion), as `Declared(name:, module:, meta:, returnTypeName:, value: null)` literals substituted into a copy of the template (`substitute`, by call loc; the registries keep the queries) with `Declared`/`DeclaredMeta` added to the module's types, and appends a `Reflection.TemplateRead`. A template body's call is never put in `srcRewrites` (the transform would splice the rewrite into the declaration every importer shares). Decision 356 — an entry's `value` is `null` but for a `val` whose initializer is `comptime`: its build value (`comptime.zig` `recordDeclaredValues`, every module, `block_eval.exportedBuildValue` → `Reflection.declaredValues`, journaled for level B) lifted as a literal (`buildValueSource`: a string, a number, a `bool`, `null`, an array or a tuple of those; a record's or a variant's is not yet). A template body's read of `.value` on a `Declared` is recorded (`Reflection.templateValueReads`, by `templateKey`, `Env.currentTemplateFn`) and refused at an expansion whose answer holds an entry with no build value (`TemplateAnswer.unvalued`) — at the read when the template is the expanding module's, else at the expansion naming it (`typeinfo-all-template-value`). `comptime.zig` `compile` runs `compileOnce`; when an answer differs from the final catalogue (`staleTemplateRead`, a module analysed after the expansion added an entry) it compiles again with the first session's reflection as the oracle, and a read the final catalogue still disagrees with is `typeinfo-all-template-unstable` at the expansion (`refuseStaleRead`). `compileTypesOnly` is one session (the tooling's answers are the catalogue as it stands). `orderReaders` also refuses `import pkg from "pkg"` naming a reader that holds the package's default fn, at the handle (`handleLoc`). Cells: `modules/template_reads_program_catalogue`, `template_catalogue_two_themes`, `template_catalogue_private`, `typeinfo_all_imported_package_default`, `modules/typeinfo_all_template_value`, `template_reads_val_build_value`, `template_val_value_not_comptime`. **Decision 551 — a catalogue default.** A top-level non-template `fn`'s `comptime` parameter whose default is a `@TypeInfo.all(…)` call (`isCatalogueDefault`) is admitted by `infer.zig` `refuseComptimeDefaults` and makes no reader (`collect` skips it). `collectDefaults` finds them; `infer.zig` `noteDefaultQueries` (beside `noteTemplateQueries`) resolves each in the declaring module (`resolve`; a `with:` naming no decorator refused at the default), holds the parameter's type to `Declared<unknown>[]` at the default, and records the one query in `Reflection.templateQueries` under `Reflection.defaultKey(module, fn, param)` (journaled for level B with the declaring package). `comptime.zig` `registerExports` exports the parameter with its default replaced by `defaultQueryCall(key)` — `@TypeInfo.all(<default_key_label>: "<key>")`, a NUL label no source writes; `expr_param.eraseFn` drops the default from the code that runs. `comptime.zig` `fillCatalogueDefaults` (from `analyzeModule`, not for `types_only`): a call the analysis filled with such a default (`catalogueDefaultCalls`, `Env.defaultInjections`) is refused outside the root package's root module (`Module.root`, `Reflection.rootModule`; `typeinfo-all-default-outside-root` at the call); in the root — first analysed over `Reflection.probeCopy` whenever the program declares a catalogue default (`declaresCatalogueDefault`), so its decorators record nothing twice — the module is analysed again with each such call given the query (`withInsertedArgs`, `callAt`; positional when every earlier parameter is written in order, else labelled; at the call's loc plus `ast.catalogue_default_col` and the parameter's index): the module reads `@TypeInfo.all` as an entry point does, and `resolve` hands `plan` the recorded query (`defaultKeyOf`). Each answer is a `TemplateRead` with its `reader` (another reader's entries left out, `templateAnswerText`'s `reader`) and `callee`; the module goes in `Reflection.defaultCallers`, and a second session (`compile`'s stale path) moves it after every module but the readers (`orderReaders`, the oracle's `defaultCallers`), an import of it then `typeinfo-all-imported`. Cells: `modules/typeinfo_all_default_at_caller`, `typeinfo_all_default_outside_root`, `typeinfo_all_default_override`; unit tests `tests/catalogue_default.zig` and `level_b.zig`'s catalogue-default round trip. |
| `primOpTemplate.zig` | Shared renderer for `#[.<Target>(…)("<template>")]` primitive-op templates. Substitutes `receiver_marker` (the receiver — written only by `parser/template_markers.zig`, which translates the source's positional markers, decision 5; `$self` is no marker), `$<N>` (positional arg after the receiver), `$args` (all positional args, comma-separated) through a backend-supplied ctx (`writeByte`/`writeAll`/`emitRecv`/`emitArg`/`argc`); other bytes pass through verbatim. `$stringify(…)` is no marker (decision 239): the parser refuses it (`template-stringify-marker`), the renderer has no arm and no backend an `emitStringify*` callback — its bytes would pass through as host text. Error: `PrimOpArgIndexOutOfRange`. `looksLikeTemplate(s)` (`$`-bearing) separates a template from the `module:symbol` form in erlang's `tryEmitPrimAnnotation`. **Arity branching** (`when(argc == N): "<template>"`): `parser.zig parseAnnotationCall` keeps each clause as one arg, `ast.parseArityBranchArg` extracts `{argc, template}`, the backend picks the matching branch (no match → falls through). **Triple-quoted** bodies: `ast.zig unquoteAnnotationArg` strips the fences plus one leading and one trailing newline. |
| `snapshot.zig` | Snapshot helpers. `assertComptimeAst` records one file per test at `snapshots/comptime/ast/<slug>.snap.md`, **without** the runtime exchanges; `assertComptimeExchange(runtime, slug, outputs)` records those (`buildExchange`: source + every `trace` entry) at `snapshots/comptime/runtime/<beam|wat>/<slug>.snap.md` when a decorator or template ran (front 18 step 4, `snapshot-layout.md` § 6) — the layout is `tests/AGENTS.md`'s table. **Type text**: `typeNameIn` renders an inferred `*T.Type` in one of two spellings (`TypeRender.mode`). `.diagnostic` is what `typeNameOf` and the error renderers print and what the `comptime/errors/` and `codegen/**/errors/` snapshots record — frozen: a `.func` collapses to its return type and every `.typeVar` is `?`. `.ast` is the `TYPED AST JSON` spelling: a `.func` reads `fn(<params>) -> <ret>`, `optional<T>` reads `?T` (as `array<T>` already reads `T[]`) unless its inner is itself unknown, and a `.typeVar` splits — `.generic` renders the declared type parameter (`GenericNamer.bind`, matched through the annotation by `bindGenericNames`, never guessed by position) or falls back to `'a`, `'b` by first appearance, while `.unbound` keeps `?`. **`?` means exactly one thing in a snapshot: the checker does not know**, so nothing else may render as it. `fn_def` params and return type come from the binding's inferred `.func` type; a record field, a method signature and an enum-variant payload go through the syntactic `typeRefName` instead — they are annotations the declaration wrote and are not bindings of their own (`infer.zig` `buildRecordDeclName` renders the same text into the record's type name). Inline tests pin all of it. **Declaration shapes**: `record_def` / `enum_def` / `interface_def` / `implement_def` carry `generic`, plus `implements` (an inline `record(…) implement I { }`), `fields`, `variants` with their payload types, nested `sections`, `extends`, and `methods` (`declare fn` slots included; an `implement` method has no `return_type` — the AST carries no return annotation there and the signature it satisfies is the behavior's). Every one of them is omitted when empty. An `implement` block declares no binding, so `buildSnapshot` reads those off `OkData.transformed.decls` in source order after the declarations that do bind. `record_def`/`enum_def` carried an `"id"` until 1.0.5-beta: it was `0` in all 71 snapshots that had it, because `resolveTypeId` looked a structural type name up in a map keyed by the declared one, and decision 19 removed the field. The `type_ids` plumbing in `../comptime.zig` (`:114`, `:1311-1313`, `:1324`, `:1490-1492`, `:1503`) is now dead and belongs to whoever owns that file. Section order: `SOURCE CODE`, `COMPTIME VALUES` (when comptime vals exist), `BOTOPINK TRANSFORM CODE` (whenever a comptime val folded, a template/decorator ran, **or** the module expanded a template at all — `OkData.template_expansions`, so the V1-driver pass-through / `@expr` / `@code` expansions that never reach the `erl` runtime are recorded too; spec 06 H8/C1), `TYPED AST JSON`. A module whose outcome is not `.ok` writes a `COMPILE DIAGNOSTIC` section instead of stopping after `SOURCE CODE` (H3). Also owns the shared diagnostic renderers `renderTypeErrorBody` / `renderParseErrorBody` / `renderOutcomeDiagnostic` / `appendDiagnosticSection` — every location box names its file (`┌─ main.bp:L:C`, `moduleFile` = the module's `SOURCE CODE` header name; 01 step 9) — reused by `comptime/tests/helpers.zig` (`renderTypeError`) and by the codegen harness. |
| `trace.zig` | `Entry{kind: template/decorator/comptime, name, listing, lang, reply}` — one per `template_eval`/`decorator_eval`/`block_eval` run, appended to `Env.comptimeTraces` (surfaced as `OkData.comptime_traces`; `analyzeModule` keeps pass-1 decorator traces across the `@emit` re-analysis). `erl` is the `listing` build of the module (lowered body + `main/1`) followed by `main/1`'s argument as comment lines — the input half of the evaluation, which is no longer inside the module; `reply` is the JSON `main/0` printed, or `compile error: …` / `runtime error: …`. `listing` is the generated module's functions as the wasm comptime runtime lowered them (`runtime.listingOf`), followed by `main/1`'s argument as comments — a `Listing`, built when it is read (144 B-127): the entry keeps the module's atom and the argument lines, and `Listing.render` lowers the functions again from the text `runtime/wat/program.zig`'s cache keeps by atom (`listing`); a refused build, or a listing the code cache read back, is its text whole (`Listing.whole`). The code cache writes a `Listing` as the string it renders (`entry_as_string`, `analysis_entry.zig`), so an entry holds the bytes it held when the listing was a string. `render`/`renderAlloc` write the `COMPTIME WAT` and `COMPTIME REPLY` sections (JSON re-indented, **objects' keys sorted** — `runtime/reply_order.zig`: the order a map iterated in is not part of the reply). |
| `tests.zig` | Barrel aggregating `tests/<feature>.zig` (plus the inline tests of `eval.zig`, `trace.zig`, `primOpTemplate.zig`, `snapshot.zig`, `diagnostics.zig`, `template_eval.zig`, `decorator_eval.zig`, `runtime/runtime.zig`, `runtime/prelude.zig`, `runtime/wat/cells.zig`); harness in `tests/helpers.zig`. |

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
Only the capitalised path form `.<Target>` is read as host-backed (`FnDecl.isExternal`,
`ast.zig`'s `startsWith("External.")`), so `#[@external(node, "…")]` fell through as an unknown
annotation and was dropped — the `declare fn` bound no host and `check` exited 0 in silence.
`refuseLowerCaseExternal`, called from `inferFnDecl`'s annotation loop, reds at the annotation and
spells the target capitalised. It fires on the `@`-prefixed builtin form only: `#[external(…)]`
without the `@` is a user-defined attribute and means something else.

**An `inline` no emitter reads is refused** (front 20 F9, decision 67). `External`'s flag is read
by `codegen/erlang.zig` and `codegen/beam_asm.zig` alone (`hasExternalInline`, over the labelled
`inline:`), so `builtins.d.bp` declares it on `Erlang` alone — and until this rule the
checker never read that declaration, so `#[@external(.Node("…", inline: true))]` checked and ran
as a switch that did nothing. `external_variants` restates the four variants with their
`declares_inline` and `declares_result` bits (`comptime/tests/infer_decls.zig` reads `builtins.d.bp`
through `std_prelude` and fails in both directions when they drift), and `refuseUnreadInline` reds at
the annotation for the two unread shapes: the flag on `Node` / `Wasm` / `Typescript`, and a value
that is not `true` / `false`. It runs from `validateExternalAnnotation` for a `declare fn` and from
`validateExternalInline` — a program walk beside `validateEffectAnnotations` — for a behavior's and
a type's methods, which the two emitters read the same way.

**`External`'s flags are labelled; `result: true` answers a `@Result<…, HostError>`** (decisions
431 (2), 487, 488, 490). `inline:` and `result:` are read by their label in any order
(`ast.isExternalFlagArg` / `ast.externalFlagSet`; `ast.externalRefOf` skips every flag), and a bare
positional `true` / `false` is refused at the argument (`refuseBareBoolFlag`). `refuseResultReturn`,
from `validateExternalInline` on a `declare fn` and on every method, refuses at the annotation a
`result:` that is not a bool and a `result: true` whose declared return is not `@Result<…, HostError>`
or `@Task<@Result<…, HostError>>` — `HostError` std's `failure.HostError` by module identity
(`isStdHostError`: a `from "std"` item `failure.HostError` binding the name, or `failure`'s own
type inside that std module; a module's own `HostError` is not it). A `result:` beside an `op:` cell or a `fn:`
cell (on any variant) is refused whatever its value (decision 491), and so is one on a variant whose
`external_variants` row has no `declares_result`. `conformance/modules/external_result_return` (refused) and
`external_result_return_accepted` (the accepted shapes) are its cells. The codegen of `result: true` is
the backends' (144 B-05).

**A binding is one labelled cell** (decisions 305, 481). The parser reads `fn: tanBody` on every
`.<Target>(…)`, and `op: "f64.floor"`, `wasi: .Delay` and `std: "hash.contentHash"` on `.Wasm`
(a keyword is a label there), and hands each on as the binding text the backends and `host_cells.zig` read
(`ast.translateExternalCells`: `"fn:tanBody"`, `"wasi:delay"`), the spelling kept in `source_args`.
`checkExternalCells`, from `validateExternalInline` on every target, refuses at the argument a prefixed string
(`"fn:tanBody"`, naming `fn: tanBody`; `"op:…"` / `"wasi:…"` on another target name `.Wasm`'s cell), a
value of the wrong kind (`fn: "x"`, `op: f64`, `wasi: "delay"`, `std: x`), a label `.Wasm` does not take,
a second cell, an opcode `wat/host_binding.zig` `findOp` does not hold and an adapter it does not list; a `fn:`
name the module does not bind is the ordinary `unbound variable` at the argument (`moduleBinds`), and one it
binds is resolved against the module (`codegen/hostFnBinding.zig` `resolve`); `refuseStdBinding` checks `std:`;
`refuseWasmSignature` reads a module-level `declare fn`'s `op:` / `wasi:` cell with the wasm backend's own reader
(`wat/host_binding.zig` `parse` over `signatureOf`), so an opcode or an adapter whose types differ from the
declaration's is refused at the annotation on every target, with the wasm build's message (144 B-23).
Cells: `modules/external_wasm_prefixed_{fn,op,wasi,std}_refused`, `modules/external_prefixed_fn_refused`,
`modules/external_fn_unbound`, `modules/external_wasm_op_type_on_every_target`,
`modules/external_wasm_adapter_signature_on_every_target`, `modules/external_wasm_task_adapter_shape`.

**The rules of hooks** (decision 357). A `use` stands at the top level of its
`@Component` body. `Env.useConstruct` names the outermost construct a `use` may
not stand in — set by `enterUseConstruct` on an `if` / `else` (after its
condition), the right operand of `&&` / `||` / `??`, a `catch` handler, a
`case` arm, a loop (`iter` / `stream` ones included) and a lambda, restored on
the way out — and `Env.earlyExitLine` the first top-level statement of the body
that may leave it early (`ast.exprMayExitEarly`: a `return`, a `throw`, a bare
`try` in the statement's own scope), noted by `inferBodyStmts`. Both are cleared
around every fn body (and the line around every lambda body); a `use` under
either is `use-not-top-level` at the `use`, naming the construct or the line.
The parser no longer reads where a `use` stands.

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
`await-without-async`.

**Only `@Result` fails** (decision 121). `throw` / bare `try` read the FALLIBLE
CHANNEL, computed from the return apart from the level: `fallibleErrorOf(eff,
retType)` answers the `E` of the `@Result<U, E>` layer — the return itself for
`-> @Result`, the value `T` of `@Task<T>` / `@Component<T>`, the item of
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
`@Component<X>` → `X` (`unwrapTaskType`) and propagates nothing.

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
outside one it is `break-value-outside-generator` — and a `comptime` block's value is its tail
(the `break` the parser wraps it in, `env.breakScope == .valueBlock`); a `case` arm's block takes none
(`env.breakScope == .armBlock`, `block-break-value`, decision 541 (3)).
A bare `break` leaves the nearest loop, ends the generator scope at loop depth 0
(`iterator_jump_lowerings .wrap_done_void`), and is `break-outside-loop` with
nothing to leave; `continue` with no loop is `continue-outside-loop`. A lambda
body restarts `loopDepth` at 0 and `breakScope` at `.none`; a `case` arm's block (and so a block
`{ … }`) restarts nothing — a bare `break` / `continue` in it reaches the enclosing loop (decision 541 (2)).

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
`for await` needs an await channel (`await-without-async`) and a
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
`tests/effects.zig` and `conformance/modules/result_hint_*`.

**Decision 124 — `async { … }`.** The parser writes the block as a
`.function` node with `syntax = .asyncBlock` and no parameters (a closure called
in place). `inferAsyncBlock` types it `@Task<T>`: `T` from its `return`s (a
`return` leaves the block — `returnTarget` / `returnWhole` are the block's), and
`@Result<U, E>` when the body has `throw` / `try` of its own (`ast.bodyFails`) —
unless the position expects a `@Task<X>` (an annotated `val`), which pins the
value and so opens or closes the fallible channel. The body awaits (`starFn` is
a `.task` context), never yields, and never `use`s (`env.asyncBlockDepth`,
refused with `use-without-component`); the enclosing labels are closed.
Where the `E` is inferred (`env.inferredErrorScope`: an unannotated block, or an
`iter` / `stream` loop whose item became a `@Result`), every `throw` / `try`
joins it through `unifyErrorChannel`, and two errors that do not unify are
`gen-infer-conflicting-errors`.

**Decision 553 (4) — a marked lambda.** The parser writes `async { x -> b }`, `iter { x -> b }` and
`async iter { x -> b }` as the unmarked lambda returning the block form they name
(`parser/AGENTS.md`), `FunctionExpr.kind.marker` set, so the block's own context admits `await` /
`yield` and the four backends lower nothing new. `inferFunctionExpr` keeps the position's expectation
for a marked lambda, and `checkLambdaMarker` (the top of `inferFunctionExprExpected`) reads the marker
against it (147): none, or a type still free, is `marker-lambda-without-expected-type`, an expected
function type whose return is another wrapper is `marker-type-mismatch`, both at the marker; an
expected return still free agrees (the body makes the wrapper). A typed `fn` expression's marker is
the parser's to check. A `component { -> … }` lambda (decision 574) is a `component fn`: its body is checked as a component body
(`starFn` `.component`, `inContextFn`, an annotated `fnContext`, no `useConstruct`, no hook node of the
enclosing function's), its `return`s and its tail answer the `R` of the expected `@Component<R>`, and the
lambda answers `@Component<R>`; `Env.componentLambdas` records it by location with its `R`, and
`context_lower.zig` lowers its body as a `component fn`'s (`lowerComponentLambda`: the tail made its
`return`, then `lowerComponentBody`), so `{ x -> body }` becomes `{ x -> return { bpScope__ -> body' } }`
and the parameters and captures are closed over by the inner lambda on every backend. A declaration's marker sets `FnDecl.effect` (the parser), so
`starCtxFromEffect` admits by it; an unmarked body that yields still compiles until P4.

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

## Templates

A template is a function whose first parameter is `expr q: string`, the template text (decisions 577, 578),
called `` name @`…` `` and answering `T` (the type of the code it builds), `anyvalue` or `anytype`; the checker's
internal tree type is the builtin generic `__Expr<T>` (named type `"Expr"` with one arg, `ast.expr_type_name`), which
no source spells. A result type only the expansion knows is `anyvalue` or an ordinary fn generic
(`fn yaml<T>(expr q: string) -> T`).

An argument bound to an `expr p: T` parameter is type-checked in the
caller and captured **unevaluated**:

- `inferFnDecl` records the tree params (`env.fnExprParams`) and registers a fn whose
  first parameter is `expr q: string` as a template fn (`env.templateFns`; the parser
  reads it onto the internal `__Expr` / `__ExprCustom` return form, `parser/compiler_surface.zig`);
  `env.inTemplateFn` gates the construction builtins while their bodies infer.
- `buildScopeSnapshot` collects the module's top-level decls + imports into
  `env.scopeSnapshot` — the origin scope for `lookup`/`bindings` (function
  locals are not visible); a capture carries only the entries whose name is a
  word of its text (decision 237, `template_eval.zig` `captureToTerm`).
- **A declaration looked up** (decision 415 (2), (3)): when the body (or a
  function it reaches) calls `lookup` / `bindings`,
  `expandTemplateCallViaRuntime` (and `templateAnnotationCapture`) runs
  `withLookupHandles`: each word of the text the scope names gets the handle
  `lookupHandle` builds — the declaration found in `Env.moduleDecls` or, for
  an import (`Env.importOwners`, an alias answering the declaration),
  `Env.typeDeclRegistry`; `decorator_eval.DeclHandle` with `module` and
  `lookup` (`identity`, `local` — what `lookup/2` matches and a `CustomNode`'s
  `ref` hands the language server —, `meta`: `Reflection.typedMetaOf`, each
  value's term from its constructor's arguments and the record's defaults,
  `lookupMetaTerm` → `decorator_eval.metaArgsTerm`). A declaration of this
  module whose `.hooks` reader has not run (decision 372) carries
  `{'__bp_pending', Name}` for `meta`, and the prelude's
  `'__bp_methodMetaAll'/2` refuses its read `typeinfo-meta-hooks-pending` at
  the literal. `compiler.meta<T>(d)` / `compiler.metaAll<T>(d)` on any declaration handle in a template body
  is `inferTagMetaRead` (a record with an `expr` field is
  `template-lookup-meta-expr-field`), lowered by `expr_param.eraseMetaReads`
  (run when the body annotates or looks up). `setMeta` / `addMeta` /
  `addMember` / `addType` / `wrapWith` on a declaration handle that is not the template's
  own `expr decl: unknown` parameter is `template-lookup-decl-write` at the call. Cells:
  `modules/template_lookup_decl`, `_decl_write`, `_meta`, `_meta_expr_field`,
  `_meta_other_module`, `_meta_same_module`, `_meta_hooks_pending`.
- `captureExprArg` unifies the argument with the inner `T`, requires a literal
  string, and records a `template.CapturedExpr` in `env.exprCaptures` (keyed by
  call loc) with text/parts, the opening-line location (the lexer stamps
  multiline literals with their *closing* line), module path and scope.
- `inferTemplateMethod` resolves the comptime-only members the surface's `compiler.<m>(q, …)` becomes on the
  internal tree receiver (`value`/`text`/`source`/`context`/`lookup`/`bindings`/`build`/
  `custom`/`fail`/`tagDecl`/`annotate`), recording
  `env.templateLowerings`. The contract a body sees is std's `Compiler` in
  `libs/std/src/compiler.bp`; the checker's own carriers are `behavior __Expr<E>` and
  `__Span`/`__Source`/`__ExprContext`/`__ExprCustom`; `lookup` answers `?__Decl` and
  `bindings` `__Decl[]` (decision 415 (2), below).
- Construction is **explicit**: `@expr(value)` (lift a comptime value) and
  `@code(text)` (parse generated source) are typed in
  `inferBuiltinCallReturnType` and only valid inside a template function.

Call-site expansion (`expandTemplateCall`, from `inferCallExpr`):
`classifyTemplateBody` reduces `return <tree param>`, `return @expr(E)` (E must
not reference the template's own params) and `return @code("…")` by inspection.
Anything richer goes to `expandTemplateCallViaRuntime` when `env.templateEval`
is set (always in `compile`; in `compileTypesOnly` only when an eval ctx is
passed) — otherwise the V1 "cannot expand" error. The runtime path requires
`captures.len + plainArgs.len == tfn.params.len`, memoizes by `templateEval.memoKey` (callee + capture texts + the scope entries
of their words + plain arg values) in `env.templateEvalCache` (holed captures and `compiler.custom` calls are
never memoized), and maps the outcome: `code` → `parseCodeText` +
`substituteHoles`; `capture` → the captured node; `value` → `valueToAstLiteral`
(`TypedValue` → literal / array / tuple — a tuple takes the labels its template body gives it: `liftShapeOf` reads `return @expr(#(server, debug))` and the `val server = #(host, port)` bindings before it, so the lifted `tupleLit.labels` make `cfg.server.port` resolve; an Erlang tuple crosses the bridge as `{"$tuple": [...]}` (`'__bp_json'/1`), a host map lifts as a tuple labeled by its keys); `custom` → `code` spliced
like `code`, tree via `template.parseCustomNodeFromTree` into
`env.customAstByLoc`; `fail` → `failDiagnostic`.
`finishExpansion` (`finishExpansionBuilt`) re-infers the expansion in the
caller's env — the call's type is the built code's, decision 426 (1) —, unifies
the template's `T` (`__Expr<T>` / `CustomExpr<T>` internally) bound with it (a free `T` takes the built
type; `unknown` holds anything), and records it in `env.templateExpansions`;
transform substitutes it and drops the template fns. A built type outside the
bound is `template-build-outside-bound` at the template's `build`: the run
replies which build it answered (`template_eval.numberBuilds` numbers each `compiler.build(q, src)` as the prelude's `q.build(src,
i)`, the prelude's `build/3` records `i`, `Extras.build`), located there for a
template of this module and at the call naming the file for another's. The
run's `compiler.note(message)`s (`Extras.notes`) are kept by the call's location
(`Env.templateNotes`), and `unifyAt` puts them on a `typeMismatch` at that
location (`— note: …`); a memoized expansion keeps both (`Env.templateEvalBuilt`).
Cells: `modules/template_call_typed_by_expansion`,
`template_call_expected_mismatch`, `template_build_outside_bound`,
`template_note_on_mismatch`.

Built code is located by its expansion (decision 429): `builtCodeOrigin` hands
each parse of built text (`@code`, `code`, `custom`) the module's next id
(`Env.expansionCount`) and the literal's line and column (`compiler.source(q)`, the
first capture; the call with none), and `parseCodeText` stamps every token with
both — `ast.Loc` is (line, column, expansion), its line and column the offset
in the built string read from the literal. So a diagnostic in built code points
at the literal, and every plan keyed by location reads the pair: each
`AutoHashMap(ast.Loc, …)` of `Env` and the backends (the default-argument plan
`defaultInjections`, C-04; `instanceLowerings` / `method_lowerings` /
`dispatchRewrites`, the erlang field-access and lambda plans;
`componentCalls` / `componentLambdas`; …), `Loc.eql` where two locations are
compared, and the names made from a location (`__bp_opt_…`, erlang's
`BpAssert…`, wat's `__anon_L…_C…`) carry a non-zero expansion. `dsl_hygiene`
reads a node's offset back through the same origin. A synthetic location made
from a node's (`loc.col + optional_synthetic_col`, an inline type's ctor, a
lifted node) keeps the node's expansion. `modules/template_two_alike_expansions`,
`modules/template_default_arg_two_expansions`,
`modules/template_built_code_diagnostic_located`.

`recv?.m(args)` over a nominal payload: the written call (typed over the `?T`)
records no instance lowering of its own, so `inferOptionalOperator` copies the
`.type_` lowering the synthesised link over the binder recorded (at
`loc.col + optional_synthetic_col`) to the written call's loc; beam reads that
loc and, without it, called the variant's atom as a module for an imported enum
(`undef` `'std@json@@Json__v__str':str/1`). A primitive's lowering is not
copied (`?.` over it stays the guard). `modules/optional_enum_method_imported`.

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
full `TypeDef` (`implements`/`renderable`/fields), not just the constructor
binding; `resolveTypeName` (env.zig) maps a constructor binding back to its
named type in annotations.

**Which module an import resolves in.** Both registries are keyed by module
PATH, and `resolveImports` used to walk them taking the first entry that held
the name — so `from "<mod>"`, the one thing that says WHICH module the import
means, was consulted by neither. A name is unique inside a module and never
over a program: `libs/std` declares `parse` in `json`, in `querystring` and in
`url` today. Measured, a module importing `Outcome` from `"parser"` was bound
to `"net"`'s record and the program was refused against the wrong record's
fields ("expected i32, got string"). Both loops run three passes now
(`ast.ImportSource.admits(path, pass)`): the module the source NAMES answers
first (`namesModule` — the full path or its last segment), then the modules of
the PACKAGE it names (`inPackage` — `from "web"` covers every `web/…` path,
bounded by the slash, so `web-app/…` is not `web`'s), then the whole registry.
Without the package pass a `from "<pkg>"` handle narrowed nothing, and two
libraries of one build declaring one name (a server library's `Response` and
an HTML library's, both loaded by an application that uses the two) made every
such import ambiguous — inside either library's own modules too
(`conformance/modules/import_same_name_from_two_packages`). A bare
`import { … };` and a module not yet analysed still reach the scan they
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
`io.fs`) binds the namespace (`stdImports`) and registers the module's `pub`
types as TYPES only (`registerStdTypeDecl(.type_only)`: the constructor and
variant bindings taken back into `typeOnlyCtors`, as a namespace of the
program's own module — `failure`'s `HostErrorName.Error` never shadows
`Error`), a prefix that is one binds the leaf as a value (`env.bind`) or
registers the one `pub type` it names, after the closure of the types its
fields and methods name (`registerImportedTypeClosure` over the module's `pub`
types, as a leaf of the program's own module). A refusal met while registering
a std declaration is located in its file (`locateInStd`: the error's `origin`
is `libs/std/src/<mod>.bp`, its `loc` the import item). A dot-shorthand
variant of a std enum the module never names (`.Error` where a `HostErrorName`
is expected) is imported for the backends through `liftedStdTypes`
(`noteImplicitEnum`). Three
refusals, each located at the item: `import-name-collision` (a second item
binding a name already bound — `noteImportBindings`, over every `use` decl,
an identical repeated item excepted because an `@emit` contribution re-imports
what its module already imports) and `import-alias-on-activation` (the
dispatch rewrite emits the extension's declared name). An alias on a TYPE or a
type alias is legal (decision 110): `registerImportedTypeAlias` registers the
declaration under its own name and the alias as a checker-local type alias of
it; a constructor call through the alias is renamed to the declared name at the
call, and any other use in expression position — a receiver (`D.empty()`,
`S.Dark`, `S.Custom(9)`) or a bare value — is renamed by
`importedTypeAliasReceiver` / `inferIdentifierExpr` (`importedTypeAliasTarget`,
which leaves a shadowing local alone) and recorded in `env.indexRewrites` under
the alias identifier's own loc, which `transform.zig` splices (a plain name for
a plain name); `comptime.zig`'s `withImportTypeAliasesErased` drops the alias from
the import items the backends read, so no backend sees it. A `resolveImports`
refusal is the module's `typeError`, like one from inference.

**A std namespace reached through two dots (decisions 110 rule 2, 111).**
`std_namespace.expand` runs on the parsed program before `resolveImports`
(and in `expandStdImports`, so the reached modules are embedded):
`import {io} from "std"` names a FOLDER of std (no module of that key, some
module under it) and `io.fs.f()` becomes the namespace of `io/fs` bound as
`__bp_ns_io_fs` (a name no source can spell), with the item `io.fs as
__bp_ns_io_fs` added; `collections.Dict` after `import {collections}` becomes
`Dict` with the item `collections.Dict` added — the leaf form, so the checker
and the four backends see nothing new. The folder item leaves the list, only the
modules the program reaches are imported (STD-001 checks those), a module that
declares its own top-level `Dict` keeps `collections.Dict` as written, and a
member that names nothing (`io.nope`) stays and is refused as the unbound
folder name, located. The same leaf rule holds in TYPE position — `fn f() ->
collections.Dict<string, i32>` is `Dict` with the item added (`rewriteTypeRef`,
a `.named` or a non-builtin `.generic`); a module declaring its own `Dict` keeps
the dotted name, and the checker refuses it as an unknown type (the `.generic`
arm of `resolveTypeRefInContext` sends a dotted name through `resolveTypeName`'s
dotted rule — it used to become a nominal type spelled with a dot). A module's
`pub fn` in VALUE position (`apply(path.basename, p)`, not a call) is the
function it names: the item `path.basename as __bp_ns_path__basename`, the
reference rewritten to that local. Cells: `conformance/modules/import_std_folder_namespace`,
`import_std_type_through_module`, `modules/std_namespace_type_in_signature`,
`modules/std_namespace_fn_as_value`, `modules/std_namespace_type_beside_own_type`.
A package's module namespace (`import {report} from "v"`) gets neither yet: its
types and functions are known only to `comptime.zig`'s `resolveImports`.

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

### `compiler.custom` — code plus a reference tree

A template that calls `compiler.custom(ast: CustomNode)` carries the executable `code` *and* a
generic reference AST built by a sub-language (SQL, markup, …). The parser makes
such a template the internal custom carrier (`__ExprCustom<T>`; `TypeRef.isExprCustomType`, grouped
with the tree type under `isTemplateReturnType`), which resolves to the `CustomExpr<T>` struct
(`{ code: __Expr<T>, ast: CustomNode }`) in `resolveTypeRefInContext`. The surface body's
`compiler.custom(tree)` and `return e` become `q.custom(tree, code)`; `tree` is a `CustomNode`
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
`expr decl: unknown` — the declaration handle (decision 575 (4); the parser reads it onto the
internal `__Decl` / `__Decl<P>`, `TypeRef.isDeclType`) —, every
further parameter `comptime x: T` or `expr x: T` (decisions 280, 364, 575 — the parser
keeps `T` in `typeRef` and sets `Param.exprWrapped`, § Every `comptime`
parameter holds a value or a tree). Both `fn` (with body) and bodyless
`delegate` forms are recognized. The core provides only the generic protocol —
recognize → reflect → invoke → apply; marker meaning lives in the lib body.

- `registerFnSignatures` calls `registerDecoratorSig` for every top-level `fn`
  and `delegate`, recording the trailing params and the body-carrying `FnDecl`
  in `env.decorators`.
- The reflection cluster (`type DeclKind { Type, Behavior, Fn, Method, Field, Val }` +
  `type Decl`/`Field`/`Method`/`Param`/`Annotation`/`Span`)
  is registered by `registerStdlib` from `decl_reflection_src` (a mirror of
  `libs/std/src/builtins.d.bp` — keep in sync). The handle's record is `__Decl`, so the array
  members `fields`/`methods`/`annotations` resolve. T17: `Annotation`, `Param`,
  `Field` and `Method` are declared `__Decl__<Name>` (shown `Decl.<Name>`) and
  spelled through prelude aliases — the template's only aliases a module's env
  inherits (`Env.cloneFromTemplate`); a module that declares or imports a type
  of one of those names takes the name (`infer.zig` `dropReflectionAlias`), and
  a handle's `m.params` / `decl.fields` keep the reflection's identity. A
  `behavior` the module declares, or imports un-aliased (`comptime.zig`
  `resolveImports`, beside `importedBehaviorDecls`), takes its name the same way
  (`infer.zig` `takeNameFromPrelude`): the alias, a prelude typedef of the name
  (`Result`, `Field`, `Declared`) and a bare variant binding (`DeclKind.Component`,
  `Stage.Any`) leave the module's scope, so every type position reads the
  module's behavior; `refuseResultMemberAccess` stands down for a `behavior
  Result` as for a `type Result`. Cells: `modules/behavior_named_like_prelude_value`,
  `behavior_named_like_prelude_type`, `import_behavior_named_like_prelude`.
- `registerStdlib` also parses `libs/std/src/builtins_fns.d.bp` (the parseable
  `declare fn` slice: `todo`/`panic`/`trap`/`emit`/…) into `env.stdlibFnDecls`,
  which `compile`/`compileTypesOnly` merge into transform's `fn_decls` so
  trailing defaults are injected at bare `todo()`/`panic()` calls. The synthetic
  `Result`/`Task`/`Component`/`Iterator`/`Stream`/`Context` interfaces
  stay doc-only in `builtins.d.bp` (they are pre-registered by
  `Env.registerBuiltins`). `registerBuiltins` binds no `print` / `println`:
  printing is `@print` / `@println` / `@debug`, which every backend lowers, and
  a bare `print(x)` is `unbound variable 'print' — printing is the builtin
  `@print`` (`unboundAt`, `modules/bare_print_call`). It used to type-check
  against a placeholder binding and lower on commonJS alone — erlang emitted
  an undefined local, beam an unresolved call, wasm a trap.
- `@compilerError(message)` — generic compile-time rejection usable from a
  decorator or template body without a declaration handle. commonJS lowers it to
  `__compilerError`; the decorator and template Erlang modules define
  `compilerError/1` (a tagged throw reported like `fail`).
- `validateDecorators` (decision 280, `01-checker` step 24) first refuses a
  decorator of the module whose parameter after the handle is not `comptime`
  (`refuseNonComptimeDecoratorParams`, `decorator-param-not-comptime` at the
  parameter, `ast.Param.loc`) and a `comptime` default on any other function
  or method (`refuseComptimeDefaults`, `comptime-default-outside-decorator`
  at the default — no call site fills one), then walks every declaration's annotations
  (record/enum/fn/module-level `val` (decision 356)/interface + methods +
  record fields) with the declaration's type (`DecoratedDecl`: a fn's
  signature or a `val`'s binding type copied, a type with fresh generics, a
  field's declared type; null for a method); a decorator on a module `var` is
  refused at the annotation (`116-c`) and `checkDecoratorArgs`
  type-checks `#[name(args)]` for recognized decorators:
  `mapDecoratorArgs` meets the arguments with the parameters (positional
  first, then labelled by name, a variadic last parameter taking the rest;
  an unknown label, a parameter given twice, a positional after a labelled one
  and a surplus argument are refused at the argument, `ast.Annotation.argLoc`);
  an omitted parameter needs a closed default (`isClosedDecoratorDefault`:
  `comptime.isClosedDefault` or a variant `.Name`) — one naming a binding is
  refused at the annotation, since the body runs in its own module. The
  parameter types are resolved here with the decorator's generics fresh
  (`DecoratorSig.generics`; an imported decorator's types came with its
  import); `__Decl<P>` (`DecoratorSig.decl`, the internal handle type) is unified with the declaration's
  type first, binding `P`'s parameters — a mismatch is refused at the
  annotation, both shapes spelled (`decoratorSpelling`). Each argument is
  re-parsed from its lexeme at its own location (`parseDecoratorArg` pads the
  source so every node keeps its file position) and checked: a `comptime t:
  anytype` parameter takes a type name (`isTypeArgName`; a string or a value is
  a mismatch, an unknown name the unknown-type error); a call that is not a
  constructor, a module `var`, or a `val` holding one is not known at build
  (`decoratorArgNotKnownAt`, below); `.name` against
  `Type.Field<T>` (`Type__Field` after the associated-type rewrite) is a field
  of `T` and against an enum a variant, case-exact (`checkDotNameArg`); any
  other value is inferred with the parameter as its expectation
  (`env.expectedType` — an integer literal widens, `.Name` resolves) and
  unified with it (a value meets `?T` as a `T`). Decision 364 (2): an
  argument not known at build (`decoratorArgNotKnownAt` — a call that is not
  a constructor, a module `var`, a `val` holding one) is
  `decorator-value-not-comptime` at it only when the body reads the parameter
  (`expr_param.useOf(dfn, name).reads` — any use but as `.fail`'s receiver);
  one the body never reads is accepted and reaches it as `undefined`
  (`DecoratorArgValue.absent`, `PlainArg.absent`), nothing built. A body that
  reads `x.value` of a parameter the annotation binds to a function type is
  `expr-value-of-function` at the argument. What each parameter hands the
  body is recorded in `Env.decoratorArgValues` under the annotation's
  location (`decoratorArgValue`), with the argument's location
  (`DecoratorArgValue.loc`) a `x.fail` reports at.
- **Invocation:** `invokeDecorators` (skipped when `env.skipDecoratorInvoke` or
  no `env.templateEval`) builds a `decorator_eval.DeclHandle` per annotated
  decl — `Fn`, `Val` (a module-level `val`, decision 356 — a decorator on a module `var` is refused by `validateDecorators` at the annotation, question `116-c`: its name and
  its declared type as written, `""` when none; it owns no type, so
  `addMember` / `addType` are refused at the annotation naming "the val", and
  it is catalogued as `DeclaredEntry.Kind.val` — one `@TypeInfo.all` query
  answers functions, `val`s or types, `typeinfo_all.zig` `kindClass`),
  `Type` (a record shape with `FieldHandle`s, an enum shape with
  `variants`), `Behavior`, plus
  per-`Field` and per-`Method` handles — and `runDeclDecorators` calls
  `decoratorEval.evaluate` for each body-carrying decorator with one
  `PlainArg` per parameter, from `Env.decoratorArgValues`: a string, a
  number or a `bool` is the literal term it is; a function or a type is its
  name as written, which no body reads (its tree has no `.value`,
  decision 364 (3)); anything
  else — an array, a record (a module `val` inlined as its value), a variant,
  `null`, a default (`defaultLexeme`, the formatter's rendering) — is built by
  a zero-argument function `__bp_decorator_arg_<n>` of the decorator module
  (`builtArgFn`, `PlainArg.call`), which the module's own lowering compiles
  beside the body, so the value has the body's representation — a section
  path in it (`.Pad.All.4`) is written as the qualified constructor inference
  resolved (`block_eval.sectionRewrittenExpr`, then `defaultLexeme`), since the
  module re-reads the source untyped; a field key
  `.name` is built as `__bp_FieldKey(name, typeName, annotations)`, a host
  record of the decorator module (`decorator_eval.zig`) — the map a
  `decl.fields` entry is (`fieldKeySource`; the field's type name and
  annotations from the declaring module's AST, a type imported from another
  module gives the checker's spelling and no annotations). `fail` and `err` become a `TypeError` at the annotation (a parameter's `x.fail` at its argument, decision 364 (3))
  (`ast.Annotation.loc`, via `decoratorError`; a `failAt` span is reported there
  too, since a declaration has no template text to map it onto) whose message
  carries the detail — for `err`, the Erlang compile/runtime diagnostic, unless
  the decorator is the module's own: its body and the module's helpers it
  reaches are inferred first (`inferFnDecl`), since bodies are not yet checked
  when decorators run, so a type error there (`decl.nope`) is the checker's,
  located in the body (`reject/decorator_{body,helper}_unknown_field`). A body that
  raises is refused at the call that raised, in the file that call is written in
  (decisions 451 (3), 532): the comptime module frames every call of the decorator and of the
  functions it carries, whichever module wrote them (`erlang.ComptimeModule.located`: name and file;
  `infer.locatedFns`; the file from `Env.srcPathOf`, the session's `Reflection.srcPaths`, recorded
  before any module is analysed; a template the using module declares is located in that module's own file,
  with its use as the last `from`) — `try Call catch error:R -> '__bp_push'(File, Line, Col, R),
  erlang:raise(error, R, []) end`, the frames kept in the process dictionary with the reason they
  belong to and replied by `'__bp_frames'(Reason)` (`Outcome.raised.frames`, innermost first) —, and
  `infer.raisedFrom` / `block_eval.raisedError` build the `TypeError`: `origin` the innermost call
  when it is not in this module's file (the report is located there), `loc` the first call in this
  module's file (where an editor shows it), `frames` the `called from` lines down to the entry — the
  annotation, the template's use, the `comptime`, the hole (`TypeError.withRaise`). The CLI prints
  them under the excerpt (`= called from src/main.bp:9:3`, `diagnostics.renderLocatedNotes`), a cell
  claims them with `from` records (`cell_snap.zig`). A call inside a template's expansion is a
  frame at the template's use, the expansion's one line in the file (`block_eval.Preparer.use_loc`).
  A body method nothing answers names `file:line:col` (`unsupportedText`'s `owner_file`)
  (`modules/decorator_raise_names_body_file`, 144 B-23). Another module's template
  is located the same way (`template_eval.evaluate`'s `located`: the template and
  the functions it reaches; `Outcome.raised`): refused at the call that raised,
  in `src/tpl.bp:3:5`, the call that expanded it the `called from` line
  (`modules/template_raise_names_body_file`; `tests/templates.zig`);
  the module's own template keeps the unlocated reply; `ok`
  carries the body's outputs in call order (`decorator_eval.Contribution`, one
  tagged map per call on the prelude's list): an `@emit` source goes to
  `env.contributions`, a `decl.addMember(source)` (decision 216 (1)) to
  `env.memberContributions` with its target — the annotated `type`/`behavior`,
  or the type owning an annotated field or method; from a `fn`'s decorator it
  is `decorator-member-without-type` at the annotation; a `decl.setMeta(key,
  value)` (decision 216 (2)) is recorded at once in `env.reflection` under the
  decorator's own name (`dfn.name`, never the `orm.entity` an annotation
  spells) — from a field's or a method's decorator it is
  `decorator-meta-on-member`, a key set twice `decorator-meta-duplicate`; a
  `decl.addType(name, source)` (decision 216 (3)) goes to
  `env.typeContributions` with its owner (as for a member; from a `fn`'s
  decorator `decorator-type-without-owner`) and into `Reflection.assoc` at
  once — a name that is not a type name is `decorator-type-name`, a second
  one of a name `decorator-type-duplicate`. An
  evaluator that cannot run at all (no `erl`/`erlc`) reports "the decorator
  evaluator failed to run".
- **Order:** `validateDecorators` + `invokeDecorators(…, .plain)` run in
  `inferProgram(Typed)` right after `registerFnSignatures` (handles read only the
  AST); a decorator that reads `.hooks` runs after Pass 2 instead
  (`runHooksReaders`, decision 372 — `hooks.zig`'s row). If there are contributions, body inference is deferred:
  `inferProgramTyped` still returns the source decls' bindings (imports, types,
  fn signatures), then `comptime.zig analyzeSource` re-analyzes with the
  contributions — `parseAndMergeContributions` + `analyzeMerged` (AST append),
  falling back to `spliceContributions` + a full re-analysis when a contribution
  does not parse standalone — with `skipDecoratorInvoke = true` (no loop). So an
  `@emit`ed decl is visible to any body (including `test {}` under
  `botopink test`). Members join their type first: `comptime.zig`
  `mergeMembers` parses each source inside a `type __bp_member() { … }` (or
  `behavior`) wrapper, its tokens placed after the module's lines and every
  `@emit` contribution, and appends the one `fn` to the target's `methods` — so
  the member is the type's own to inference, to `registerExports` (it travels
  with the type to every importer) and to every backend. A source that is not
  exactly one `fn` is `decorator-member-not-one-fn`, a name the type already
  has (field, variant, member) `decorator-member-duplicate`, both at the
  annotation. A record-shaped type's members are closed: `infer.zig`'s
  type-qualified call (`City.f(…)`, after decision 62's
  `associatedCallReturnType`) refuses a name the type neither declares nor
  answers through a field or an implemented behavior as
  `unknown-associated-fn` at the call. Associated types follow (`mergeAssocTypes`): each source is
  parsed as `[pub] type <Owner>__<Name><source>` — `pub` when the owner is —
  and appended as a top-level type; one that is not one type is
  `decorator-type-not-one-type`, a name the owner already answers (variant,
  member) or the module already declares `decorator-type-duplicate`. Before
  the decorators run, pass 1 accepts a dotted type name whose head is a type
  (`Env.assocTypesPending`, `resolveTypeName`) on credit; with no re-analysis
  to follow, `refusePendingAssocType` reports it as the unknown type it is. In `types_only` (LSP) a failed re-analysis falls back to the
  pass-1 bindings; the full `compile` keeps the error.
- Member-level annotations parse on record bodies (`parser/decls.zig
  parseRecordBody`): `RecordField`/methods carry `annotations`, so
  `#[getMapping]` on a method and `#[inject]`/`#[value]` on a field reach both
  passes.
- Decorator fns are comptime-only: `transform.zig` drops any fn whose first
  param is the declaration handle (`expr decl: unknown`); the decls it contributed stay.
- **Cross-module:** `registerExports` publishes decorator `FnDecl`s into
  `comptime.zig`'s `decorator_registry`; `resolveImports` rehydrates them via
  `infer.registerImportedDecorator`, so `#[name(args)]` in an importing module
  both arg-checks and runs the body (mirror of the template registry path).
  A namespace import of a module (`import {markers} from "web"`) registers each
  of the module's decorators under `<ns>.<name>` (decision 386), as a std
  module's are under `<handle>.<name>` (`registerStdDecorators`): `#[markers.tag]`
  runs `tag` (`modules/decorator_through_namespace`).

## The template annotation `` #[f @`…`] `` (decisions 311, 577, `01-checker` step 29)

The parser keeps `` #[f @`…`] `` as `ast.Annotation.template` (the text as a
string literal, `templateText` its raw bytes, `templateLoc` where it starts;
`args` empty). `f` is a template function whose second parameter is the handle —
`fn f(expr q: string, expr decl: unknown) -> R`,
`member_fn.isTemplateAnnotation` (question s29-a); `member_fn.declParamIndex`
/ `declParamName` answer `1` / `decl` for it, so everything keyed on a
decorator's handle — `typed_meta.collect`, `member_fn.collect`,
`checkTypedMetaCalls`, the body's `decl.setMeta(v)` / `decl.addMember(name,
fn…)` typing (`infer.zig` `currentDeclParam`) and `expr_param.eraseFn` — reads
the template's body as a decorator's.

- **Check** (`infer.zig`): `checkTemplateAnnotations` (from
  `validateDecorators`) resolves the name with `templateFnNamed` (an imported
  template, or a local one from `Env.fnDecls` — decorators run before the
  bodies that fill `Env.templateFns`) and refuses at the annotation
  `template-annotation-not-template`, `template-annotation-without-decl` and,
  for `#[f(…)]`, `#[f]` or `#[f "…"]` naming a template, `expr-call-outside-expr`
  (decision 577 (3)); a call `` f @`…` `` of an annotation template is
  `template-annotation-only` at the call. A template text holds no hole
  (decision 577 (5)): code the template builds from it is checked where it is
  spliced (`annotatedSites` lists every annotation with its declaration).
- **Run**: `runDeclDecorators` takes a template annotation as a decorator whose
  function is the template (`DecoratorSig` with no parameters of its own):
  `templateAnnotationCapture` captures the literal as `captureExprArg` does at
  a call site (`parseDecoratorArg` re-reads it at its own location), and
  `decorator_eval.evaluate` gets it as `capture`: `annotationPlans` binds the
  capture term (`template_eval.captureToTerm`) to `q` and the handle to
  `decl`, the module (emit key `ann`) carries `prelude.captureForms` — the
  template prelude's capture API and result constructors — beside `main/1`,
  and imports the decorator prelude for the handle. A `lookup/2` failure
  (template tag) and `compiler.fail` is reported at the annotation;
  the value the body returns is not used. The outputs are a decorator's;
  `unplaceholderContributions` rewrites each `__bp_hole_<q>_<i>` in a source
  or a typed meta string into the hole's expression as written
  (`parser/exprs.zig` `holeSources`), so a meta names the method's parameter.
- **`decl.params`**: `DeclHandle.params` (`paramHandles`) — a function's or a
  method's own parameters, `Param(name, typeName)`, `self` included.
- **A method's typed meta** (question s29-b): `invokeDecorators` runs a
  type's or a behavior's methods' decorators before the owner's;
  `recordTypedMeta` keeps a method's value in `Env.methodTypedMeta`
  (`recordMethodTypedMeta`, `decorator_eval.metaValueTerm` — the record's
  map, a variant its atom; `decorator-meta-twice` per method and type) and
  `withMethodMeta` puts the owner's on its handle, each `decl.methods` entry
  carrying `meta => [#{type, value}]`. The owner's body reads `m.meta(T)` /
  `m.metaAll(T)` (`inferMethodMetaRead`: `?T` / `T[]`, `T` written by its
  declared name), which `expr_param.eraseForRun` turns into the prelude's
  `'__bp_methodMeta'/2` / `'__bp_methodMetaAll'/2`; `typed_meta.withMetaHelper`
  skips decorator and template bodies (such a read is no catalogue read).
- **A tag is a declaration handle** (decision 302): a template body builds a tag's
  handle with `compiler.tagDecl(kind, name, attrs)` (`DeclKind.Element` /
  `DeclKind.Component`; the template prelude's `tagDecl/4`) and runs the
  annotation written at a span of its text with `compiler.annotate(decl, at)`
  (`annotate/3`). The run is replayed: the N-th `annotate` of a run answers
  the capture's N-th `'__bp_annotations'` entry (`CapturedExpr.tagAnswers`),
  and past them throws `'__bp_template_need'`, which `main/1` replies as
  `{"kind":"need", decl, span}` (`template_eval.Outcome.need`; only a body
  that writes `annotate` gets the reset and the clause).
  `expandTemplateCallViaRuntime` then runs `runTagAnnotation` — the span's
  text parsed as one annotation, located on the caller's text, its name a
  decorator of the caller's scope, its arguments checked by
  `checkDecoratorArgs`, the body run by `decorator_eval.evaluate` over the
  tag's `DeclHandle` (`attrs`, `component` — the component function's own
  handle —, `tagMeta`) — and evaluates the body again with the answer.
  Typed meta is the one channel (`decorator-meta-twice` at the second
  `setMeta` of a type on a tag); `addMember`, `addType`, `@emit` and the
  string `setMeta` are `tag-annotation-output`. The body reads
  `compiler.meta<T>(d)` / `compiler.metaAll<T>(d)` (`inferTagMetaRead`, refused on a
  decorator's own handle), lowered by `expr_param.eraseMetaReads` to the
  prelude's `'__bp_methodMeta'/2`; `compiler.attr(d, name)` is `attr/2` in both
  preludes. Cells: `modules/tag_decl_meta`,
  `modules/tag_annotation_add_member`, `modules/tag_annotation_meta_twice`.

**Decision 425 — a template call expands wherever an expression may stand.**
Inference expands every template call it types (`Env.templateExpansions` by
the call's location); `transform.zig` splices them in a function's and a
`test`'s body, and — through the method-body aggregator (`src_agg`, which now
carries the expansions) — in a type's, an `implement`'s and a behavior
default's method bodies; `rewriteStmt` walks a destructuring initializer
(`localBindDestruct`). A record field's or a top-level function parameter's
default holding a template call is inferred once after Pass 2
(`expandTemplateFieldDefaults`), so the default fill (`injectedDefault`, which
shares the node) carries the expansion. `refuseUnexpandedTemplateCalls`
(`UnexpandedTemplateCall`, a reflective AST walk skipping template and
decorator bodies) refuses any call of a template function left without an
expansion, at the call (`template-call-unexpanded`; a unit test in
`tests/templates.zig` pins it — no program reaches it). The nearest binding
wins: a free call whose callee is a parameter or a local (`Env.localBindDepth`)
is that value's — no capture, no expansion, recorded in
`templateMethodDeclined` so the backstop lets it through, and
`transform.localFnOf` never takes a template for the module function of the
name. A template function named without a call is refused where it is read
(`template-function-value`, `inferIdentifierExpr`). Cells:
`modules/template_name_shadowed_by_local`, `modules/template_function_value`,
`modules/template_in_module_val_lambda`,
`modules/template_in_type_method`, `modules/template_destructuring_init`,
`modules/template_in_lambda`, `modules/template_in_argument`,
`modules/template_in_field_default`, `modules/template_in_case_arm`.

**A template method (decisions 311 (3), 397 (3), 415 (1)).** A template
function whose first parameter is `expr self: R` and second
`expr q: string` (`ast.isTemplateMethodSignature`, over the internal form the parser reads them onto, `comptime self: __Expr<R>` and `comptime q: __Expr<…>`; the parser's
`self-param-outside-type` refusal lets exactly that signature through) is
called `` value.method @`…` ``: `inferCallExprWith`, once the receiver is typed,
sends a method call whose callee is such a template of the call site's scope
(`templateMethodNamed` — local or imported, never a method of the receiver's
own type) to `inferTemplateMethodCall`, which checks the receiver against `R`
(`unifyArgument`, so a behavior accepts an implementer), captures it as the
`self` capture (`text` the receiver as written, `defaultLexeme`), captures each
literal with `captureExprArg` and expands the call as `expandTemplateCall`
does. The comptime module names the receiver parameter `__bp_self`
(`template_eval.renameTemplateSelf`): the erlang lowering drops a parameter
named `self`. `refuseUnexpandedTemplateCalls` covers the method form too,
except a call `inferCallExprWith` resolved to the receiver type's own method
or a `"std"` namespace's function (`Env.templateMethodDeclined`, by the call's
location): no expansion is owed there. The receiver's own method is
`receiverHasMethod`: an inherent one, one a behavior the type implements
declares (its `default fn` included, through `extends`), or, on a value of a
behavior, one that behavior declares. Cells: `modules/template_method_call`
(a local template over a type and over a behavior, an imported one over a
generic behavior, in a method body), `modules/template_method_own_method`,
`modules/template_method_behavior_method`.

## A `comptime` / `expr` parameter holds a value or a tree (decisions 364, 575)

Every `comptime` or `expr` parameter other than the declaration handle is written `comptime x: T` or
`expr x: T` — a decorator's, a template function's, any function's, a
method's, a `declare fn`'s (std's `types.bp` included). Decision 364 had the checker
hold each as an `@Expr<T>` the source wrote; 575 and 576 moved that wrapper off the surface, and the
parser reads the surface onto the same internal form (`__Expr<T>`).

- **Parse.** A template function keeps
  its tree parameters in the internal form (§ Templates). Every other
  function has the wrapper read off once after the parse
  (`parser/expr_params.zig`): `Param.typeRef` is `T` and `Param.exprWrapped`
  is set, so every rule that reads a `comptime` parameter's type — a
  decorator's argument check, `value_or_type.zig` (`comptime x: Box<T> | type<T>`),
  the type-parameter constraints (`comptime t: type string | int`), the transform's
  specialisation, a backend's signature — reads `T`. A variadic is
  `comptime ..xs: T[]` (`parser/decls.zig` `checkVariadicParam` reads
  through the wrapper). The formatter prints the surface form back.
- **Decision 576 (1).** `@Expr`, `@ExprCustom` and `@Decl` are gone from the surface (the parser refuses
  them, `removed-expr-type`); the checker's tree type, custom carrier and declaration handle are the
  internal `__Expr<T>` / `__ExprCustom<T>` / `__Decl` (`ast.expr_type_name` and siblings), the handle a
  record of `comptime.zig` `decl_reflection_src` that no std module declares (`builtins.zig`'s drift
  test exempts it), shown `Expr` / `Decl` in a diagnostic (`error.zig` `internalShown`). std's
  `builtins.d.bp` keeps `@expr` / `@code` as the compiler's own builtins (`-> __Expr<T>`); a written
  `@expr` is refused by `parser/compiler_surface.zig`. The string `decl.addMember(source)` and
  `addType(name, source)` stay until a type can be written as a value (B-140).
- **Decision 575 (4)'s surface.** `comptime x: T` (`Param.arrival = .value`)
  and `expr x: T` (`.expr`) parse into this same internal form, and
  `parser/compiler_surface.zig` reads a `comptime x: T`'s bare reads as
  `x.value`, `compiler.*` onto the handle / the template site / the builtins,
  and a template's returns as lifted trees (`parser/AGENTS.md`
  § `comptime`, `expr` and `compiler`). 364 (4)'s `comptime-param-not-expr`
  is gone (575 reverts it). `type<T>`, `T` a type parameter of the function,
  binds `T` from the type argument (`resolveTypeRefInContext`, a decorator's
  argument check `checkDecoratorArgs`), and is no constraint.
  `compiler.text(x)` on a decorator's `expr` parameter is the argument as the
  annotation wrote it (`'__bp_argText'(j)`, `decorator_eval.zig` hands the
  texts to `main/1` as `{Arguments, Texts}` when the body reads one).
  A member a decorator writes reads the body's locals (575 (4), the tree
  rule): `refuseCaptures` admits them in a member (not yet in a wrapper),
  the body hands their values with it (`decl.addMember(name, k, [v, …])`,
  `member_fn.capturedLocals`) and `memberFnSource` splices each as a literal
  (`member_fn.literalSource`: a string, a number, a `bool`, `null`, an array
  of those; any other value is `decorator-member-captures`).
- **Decision 576 (13) — the types of `compiler.bp` are imported.** The
  records and enum the compiler hands a body (`Span`, `Source`,
  `ExprContext`, `CustomNode`, `DeclKind`, `HookNode`, `DeclAnnotation`,
  `Param`, `Field`, `Method`) are registered under internal names
  (`__Span`, …, `__Decl__Annotation`; `builtins.d.bp`, the mirror
  `decl_reflection_src`, which also carries `__Source`, `__ExprContext` and
  `__CustomNode` for a std module's scratch env) and spelled through
  `libs/std/src/compiler.bp`'s aliases (`pub type Span = __Span;`). A
  module imports one (`import {compiler.Span} from "std"`, a std module
  `import {compiler.DeclKind};`): `infer.zig` `preRegisterStdImportAliases`
  enters the imported aliases before the module's own types and
  signatures register, and `bindAliasNamespace` makes the alias the
  declared name at a call and a receiver as decision 110's `import {T as
  A}` does (`Span(0, 1, 1)`, `DeclKind.Fn`). The comptime modules take the
  alias names beside the internal ones (`decorator_eval.zig` /
  `template_eval.zig` `host_enums`, `host_records`, `injected_names`).
  `env.zig` `sectionPathForFlatName` skips a one-segment internal name, so a
  program's own `Source` is its own.
- **Decision 577 — the template text.** A capture of `` name @`…` `` /
  `` #[name @`…`] `` holds the text's raw bytes (`captureExprArg`'s
  `templateText`, `templateAnnotationCapture`'s `Annotation.templateText`),
  `CapturedExpr.templateText` marks the two-byte opening `template.mapSpanToLoc`
  counts, and a string value a template answers is lifted escaped
  (`valueToAstLiteral`, `block_eval.stringLexeme`).
- **Body.** `inferFnDecl` and `inferTypeMethods` bind an `exprWrapped`
  parameter as `__Expr<T>` (the signature keeps `T`, so a call checks the
  argument against `T`) and set `Env.currentParams`. `x.value` (the
  `identAccess` arm on an `__Expr<T>` receiver) is `T`; `refuseExprValueRead`
  refuses it for a type-kind parameter (`expr-value-of-type`) and a function
  or optional function `T` (`expr-value-of-function`), at the read — also
  `x.value(…)` (`inferTemplateMethod`). Any other member of an `__Expr` is the
  unknown field; a method of a parameter's tree is `expr-param-method`
  but a decorator's `x.fail(…)` (template captures keep every template
  method).
- **What runs.** `expr_param.zig` erases the reads: `x.value` → `x`, before
  the transform (`eraseProgram` over the analysed program, `eraseFn` over
  `fn_decls`, `comptime.zig`) and over a decorator's body and support
  (`runDeclDecorators`), where `x.fail(m)` becomes `'__bp_failArg'(j, m)`
  (the prelude throws the fail tag with the span `#{arg => J}`;
  `decorator_eval.parseOutcome` reads it as `Outcome.fail.arg`, reported at
  that argument's `DecoratorArgValue.loc`).
- **Templates.** A capture carries `value` (the text) when the template body
  reads `compiler.text(q)` (`CapturedExpr.valueRead`); a template text holds no hole
  (decision 577 (5)), so the value is always known at build.
- **Handed on — a typed member (decision 370 (2)).** `decl.addMember(name,
  fn(self: T) -> R { … })`: the parser reads a function expression's
  parameter types and `-> R` (`FunctionExpr.paramTypes` / `.returnType`,
  dumped only when written; the formatter prints them); the member is named
  by `Env.memberFnAt` and arrives with its written signature as the expected
  type — any other typed function expression is typed where it stands
  (decision 408, `inferFunctionExprExpected` / `writtenFnType`: the written
  types are the function's, unified with the position's function type when
  it has one and refused at the expression naming both). `infer.zig` `inferMemberFnCall` (reached first in
  `inferCallExprWith` for `<handle param>.addMember` with two arguments in a
  decorator's body) types the function as the program's code: its written
  signature with the decorator's type parameters in scope, each `exprWrapped`
  parameter rebound from `__Expr<T>` to `T`, `Env.currentParams` emptied;
  `refuseMemberFnShape` refuses a parameter without a type
  (`decorator-member-fn-untyped`) and a read of the handle or of a local of
  the decorator's body (`Env.decoratorBody`, `decorator-member-captures`); a
  second argument that is no function expression is `decorator-member-not-fn`.
  `expr_param.useOf` does not count a read inside the member, so an argument
  not known at build (`t("…")`) is no `.value` read; `eraseFn` hands the
  runtime `decl.addMember(name, <k>)` (`k` in `member_fn.collect`'s order),
  the prelude's `addMember/3` replies `memberFn` with `name` and `index`.
  `runDeclDecorators` → `memberFnSource` renders the member
  (`member_fn.render`) from `DecoratorArgValue.lexeme` (each argument as the
  annotation wrote it, a default as declared) and `Env.decoratorTypeArgs`
  (each type parameter as `checkDecoratorArgs` bound it) and appends it to
  `Env.memberContributions`, merged like a string member (`comptime.zig`
  `mergeMembers`). A decorator of the module runs before its body is checked,
  so `memberFnSource` runs `refuseMemberFnShape` itself; it refuses a `self`
  that is not the owner and an unbound type parameter
  (`decorator-member-type`). **Decision 384** — for a decorator of another
  module, `memberRenames` renames every name and non-primitive type the
  member writes beyond the parameters, its own locals and the type
  parameters to what it resolves to in the decorator's module
  (`written_names.zig`, `Reflection.scopes`): `member_fn.render` writes the
  alias `__bp_tpl_<module>__<name>`, `Env.hygieneImports` hands it to the
  re-analysis (a value bound, a type imported under the alias); a private
  helper travels as a template's does (`sharesPrivates`). A name the
  decorator's module neither declares nor imports keeps resolving in the
  annotated module; a type the annotated module holds under the same name
  from elsewhere is `import-name-collision` at the annotation (decision 310's
  gap, `modules/decorator_member_type_same_name`). In an expression the
  member's type parameter is spelled as the annotated type
  (`@typeInfo(T)` → `@typeInfo(Conta)`, decision 395). The names a typed
  function expression reads are no support of the decorator
  (`ast.collectNames` skips it): the member runs with the program. A method
  body takes `enum_section_rewrites` too (`transform.zig`'s method
  aggregator), so decision 110's `D(…)` of an imported type's alias — how a
  member constructs its library's type — reaches the backends renamed. The typed meta half
  (370 (1), a record with `expr` fields) is § Typed meta below.
  An ordinary function's argument stays known at build
  (`comptime-arg-not-known`, `value_or_type.zig`'s rule).
- **Handed on — a wrapper (decision 316).** `decl.wrapWith({ call -> … })`
  wraps the annotated function or method. `infer.zig` `inferWrapWithCall`
  (reached beside `inferMemberFnCall`) types the lambda as the program's code,
  as a member function is (each `exprWrapped` parameter its `T`,
  `refuseMemberCaptures`), against `fn(call: __Decl__Call<A, R>) -> answer`:
  the call value (`comptime.zig` `decl_reflection_src`) has `args` — a tuple of
  the decorator handle's `fn(…) -> R` pattern's parameters, `unknown` under `fn(..) -> R`
  (the parser's `TypeRef.function.anyParams`, written only as the handle pattern's, `any-params-outside-decl` elsewhere; `checkDecoratorArgs` meets only
  its return with the declaration's) — and `run: fn() -> R`; `answer` met with
  `R` afterwards is `decorator-wrap-type` at the lambda; no lambda at the call
  is `decorator-wrap-not-lambda`. `eraseFn` hands the runtime
  `decl.wrapWith(<k>)` (`member_fn.collectWrappers`'s order), the prelude's
  `wrapWith/2` replies `wrap`; `runDeclDecorators` refuses one from a decorator
  on anything but a function or a method of a type
  (`decorator-wrap-without-function`, at the annotation) and appends the
  rendered lambda (`wrapperSource` → `member_fn.renderWrapper`, splices and
  384's renames as a member's) to `Env.wrapContributions`. `comptime.zig`
  `mergeWrappers` then rewrites each wrapped declaration, its wrappers in
  annotation order (first written outermost): a call type `BpWrapCall__<f>`
  (`BpWrapCall__<Owner>__<m>`; upper-case first, the BEAM reads a constructor
  so), one `__bp_wrapper_<f>_<k>` per wrapper holding it as a typed `val`
  (`val __bp_w: fn(call: C) -> R = …`; a lambda handed straight to a
  parameter reads its parameter's fields wrongly on wasm), the function's body
  replaced by the chain of calls, and the original body kept as the private
  `__bp_wrapped_<f>` (a method's as a private method of its type). The
  function keeps its name, signature and annotations, so every caller — an
  importer too — runs the wrapper. A generic function or owner is
  `decorator-wrap-generic`; a `declare fn` and a method outside a `type`'s
  body `decorator-wrap-without-function`. `decoratorEval.moduleVarWrite`
  skips a wrapper and a member function (they run with the program), and
  `written_names.sharesPrivates` counts a wrapper as it counts a member.
- **Handed on — an executor (decision 575 (3)).** `compiler.compile(f)` (the
  handle's `decl.compile(f)`; `parser/compiler_surface.zig` makes a named
  executor `{ -> f() }`, the call its tail) compiles run-time code beside the annotated
  declaration. `infer.zig` `inferCompileCall` types the lambda as a wrapper's
  (each `exprWrapped` parameter its `T`, `refuseCaptures` with the body's locals
  allowed) and checks the executor against `fn()` (decision 409): a tail that
  answers a value is refused at it by `refuseValueTailInVoid`, a named executor
  that answers one at its name. `eraseFn` hands the
  runtime `decl.compile(<k>)` or `decl.compile(<k>, [locals…])`
  (`member_fn.collectExecutors`'s order, `capturedLocals` as a member's), the
  prelude's `compile/2` / `compile/3` reply `compile`; `runDeclDecorators`
  appends `executorSource` to `Env.contributions`: the executor rendered as
  `fn __bp_executor_<k>() { … }` (splices, the locals as literals and 384's
  renames as a member's; its statements as written, tails kept) and `val _bp_init_<k> =
  __bp_executor_<k>();`. The module-level `val` joins the module's body
  (decision 140): commonJS runs it at load, erlang and beam in
  `'_botopink_init'/0` (the entry calls its imports' first, dependencies
  first), wasm in the start — so the program's init list is modules in
  dependency order, declarations in source order, calls in order, before
  `main`. `moduleVarWrite` skips an executor and `sharesPrivates` counts one,
  so a private helper of a library decorator's module resolves where the
  executor lands. **Decision 580:** the executor is a statement of the module's
  body at the annotated declaration's position — `runDeclDecorators` records an
  `Env.executorAnchors` entry (the contribution, `Env.decoratedDeclIndex` set by
  `invokeDecorators`, the annotation and the `compiler.compile` call), and
  `comptime.zig` `parseAndMergeContributions` inserts the executor's
  declarations right after that declaration (past the imports prepended before
  the module's own), so a `val` below it runs after it; a type error inside one
  is located at the annotation, the call its `called from` line
  (`locateInOutputs`, decision 567). **Decision 581 (2):** the handle is
  admitted in an executor (`refuseCaptures`' `handle`): `inferCompileCall` types
  it as a free type in the decorator's body, and `executorSource` splices it as
  the annotated declaration's name, so the module checks it with its declared
  type (`modules/compile_executor_handle_typed`,
  `modules/compile_executor_handle_mistyped`).

## Typed meta (decisions 298, 370 (1))

`decl.setMeta(v)` (one argument) and `decl.addMeta(v)` record a value keyed by
its record type (`typed_meta.zig`); the two-argument string `setMeta(key,
value)` stands beside it until the library sites migrate (130 step 8).

- **Where the decorator is declared.** `validateDecorators` →
  `checkTypedMetaCalls` walks every decorator of the module
  (`typed_meta.collect`): `v` is a record type's constructor written at the
  call, resolved in the module (own, imported, `ns.Name` — `metaCtorTarget`;
  `decorator-meta-not-record`), each field's `Shape` — a string, an integer, a
  float (`f32` suffixed `f`), a `bool`, a variant of a payload-less enum
  declared in the record's module, an array or an optional of those, or an
  `expr x: T` field (`Field.exprWrapped`, `parser/expr_params.zig`) —
  (`metaFieldShape`, `decorator-meta-field-type`), and an `expr` field
  given exactly a decorator parameter, such a parameter given no other field
  (`decorator-meta-expr-arg`). The types go to `Reflection.decoratorMetaTypes`.
  In the body, `inferTypedMetaCall` (from `inferCallExprWith`) types `v` with
  each handed-on parameter rebound from `__Expr<T>` to `T`; a typed meta call on a
  handle that is not the decorator's own parameter is `decorator-meta-not-record`.
- **What runs.** `expr_param.eraseFn` turns the call into
  `'__bp_typedMeta'(k, v)` (`k` in `collect`'s order) and each handed-on
  parameter into the host record `__bp_ExprRef(__bp_expr: j)`; `useOf` counts
  no use for it, so an argument not known at build reaches no `.value`. The
  prelude walks the value (`'__bp_metaJson'/1`: `undefined` → `null`) and
  replies `typedMeta` with `index` and `data` (`decorator_eval.Contribution`).
- **Recorded.** `runDeclDecorators` → `recordTypedMeta`: `typed_meta.render`
  writes `data` back as the constructor's arguments by the call's
  `MetaCallType` (an `expr` field as `DecoratorArgValue.lexeme`), refused
  from a field's or a method's decorator (`decorator-meta-on-member`) and for a
  second value of a type held once (`decorator-meta-twice`), at the annotation.
  A `.hooks` reader may record typed meta (decision 372).
- **Read.** `inferTypedMetaRead` answers `@typeInfo(X).meta(T)` /
  `.metaAll(T)` (the record type resolved by `reflectedDecl`, `metaReadType`;
  `typeinfo-meta-type`) as `[T(…), …].first()` / `[T(…), …]`, parsed on a line
  of its own past the module (`typedMetaRewrite`, `Env.typedMetaLines`) and
  typed in the reading module; `meta(T)` over several values is
  `typeinfo-meta-several`, a declaration of this module a `.hooks` reader
  annotates, before it ran, `typeinfo-meta-hooks-pending`. **Decision 385** —
  a value with `expr` fields read outside the annotation's module has every
  name its arguments wrote bound where the annotation wrote them
  (`written_names.renameArgs` with a `Binder`): a private rule reached, a
  same-named function of the reader never captured
  (`modules/meta_expr_read_elsewhere`). **Decision 395** — in a member a
  decorator hands on, `@typeInfo(T)` of the decorator's type parameter is
  typed as the read alone (`typedMetaReadOfTypeParam`: `C<…>[]` / `?C<…>`,
  answered nowhere); the rendered member reads `@typeInfo(<the type>)` and is
  answered and checked again in the annotated type's module.
  `comptime @typeInfo(X).metaAll(T)` is the checker's answer itself
  (`inferComptimeExpr`, `isTypedMetaRead`): the list a build constant, no
  comptime runtime, each `expr` field run with the program; `for (comptime
  …)` parses (`parser/exprs.zig` `parseForExpr`). `modules/member_reads_own_meta`. `inferDeclaredMetaRead` answers `d.meta(T)` /
  `d.metaAll(T)` on a `Declared` as `declared__metaAll__<T>(d.typedMeta,
  "<type identity>")` (`.first()`), the function `typed_meta.withMetaHelper`
  declared in the module (non-generic: wasm binds no type parameter a read's
  type alone fixes), its type tokens placed at the read's argument; a generic
  record is refused there (`typeinfo-meta-type`, question `130-s8-d`), and in a
  decorator's or a template's body (`typeinfo-meta-at-build`). `transform.zig`
  splices both answers at the call's loc.
- **Carried.** `typeinfo_all.zig` `typedSlots` writes each entry's
  `typedMeta: [DeclaredTypedMeta(key: "<identity>", value: { -> T(…) }), …]`,
  a type of another module through an `import {T as Bp__ti_<n>}` the answer
  adds (capitalised: an aliased constructor takes its fields' labels), a
  private one refused (`typeinfo-all-private`), an `expr` value of another
  module's annotation with its names bound where they were written (385:
  `written_names.Collector`, `Plan.values`, bound by the re-analysis); a
  template body's answer
  carries `[]`. `DeclaredTypedMeta` and the `typedMeta` field are in
  `comptime.zig` `decl_reflection_src` / `declared_decl_src`, the template
  mirror (`template_declared_src`), `block_eval.zig`'s prelude records and
  `builtins.d.bp`.

## Reflection reads — `@typeInfo` (decision 216 (2))

`@typeInfo(X).name` and `@typeInfo(X).meta.<decorator>.<key>` are string
constants answered by the checker: `inferTypeinfoRead` (reached from the
`identAccess` arm before anything else) walks the chain down to the builtin
call, resolves `X` with `reflectedDecl` — a name of `Env.ownDecls` (this
module's top level, `noteOwnDecls`), an imported name through
`Env.importOwners` (an alias answers the declaration), or `ns.Name` through
`NamespaceImports.paths` — and records the literal in `env.srcRewrites` under
the access's own loc, which `transform.zig` splices in place of the access
node. A longer chain (`….table.length`) answers null at its outer link and
reaches the read as a receiver. `@typeInfo(T)` used as a value is a
`TypeInfo<T>` (`name`, `module`, `fields`, `methods`, `meta` — decision 253;
`inferBuiltinCallReturnType`); the older structural enum `TypeInfo` and its
`EnumVariant` / `TypeInfoKind` are gone (decision 248 folds it in), and the
members other than `name` and `meta` are `typeinfo-unknown-member` until they
are answered. Refusals, located: another member
or a meta read without its key `typeinfo-unknown-member`, an `X` nothing
declares or imports `typeinfo-unknown-declaration`, a key the decorator did not
set `typeinfo-meta-missing` naming the keys it has, the lowercase
`@typeinfo(…)` / `@typeinfo.all(…)` `typeinfo-lowercase` naming `@typeInfo` /
`@TypeInfo.all`, and `@typeInfo.all(…)` `typeinfo-all-on-function` naming
`@TypeInfo.all` — the catalogue is a static method of the type (decision 253)
(`inferCallExpr`). Without an evaluation context (tooling that does not run
decorators) a meta read is `""` rather than a refusal.

`@TypeInfo.all(with: d)` (decision 216 (4), `typeinfo_all.zig`) answers the
program's declarations carrying `d`; `reflection.zig` records them as each
module's decorators run (`runDeclDecorators`' `declared` argument, top-level
declarations only).

## `use` capability inference (decisions 88, 102, 104, 128, 354, 357)

`use` is a **prefix operator** (`use <call>`); bindings come from the
enclosing `val`/`var` (`val {v, s} = use state(0)`, `use effect(…)` for void).
AST node: `Expr.useHook { inner }`. The wrapper is one, `@Component<R>`
(decision 354 — 128's base parameter is gone), activated by writing it as the
return (`EffectKind.component`): a **component** is the `@Component<R>` whose
`R` implements the marker `@Renderable` (`TypeDef.isRenderable`, set by
`implementsRenderable`; `isComponentType`), and any other `@Component<R>` is
read with `use` (`isHookType`). The parser refuses `@Component<R>` at the
base (`componentBaseParamRemoved`), `@Renderable` (`contextMarkerRemoved`) and
`@Renderable<…>`.

- Only a `-> @Component<R>` body activates: `FnContext.annotated` and
  `env.inContextFn` are one flag, set by that return and by nothing else
  (decisions 104, 118). A `use` elsewhere is `useWithoutComponent`
  (`use-without-component`, RC7), located at the `use` and naming the fn
  and its return type. Before it: `use-outside-render-tree` (354 (3)) in a
  decorator body (`Env.inDecoratorFn`), a template body (`Env.inTemplateFn`)
  or a `comptime` (`Env.comptimeDepth`), and `use-not-top-level` (357, above).
- The operand is read with `use`: `validateUseOperand` refuses a component
  (a component is called) and anything that is no `@Component` at all
  (`useNotContext`). The prefix is typed as `R` (`bindingSourceType`).
- `await` accepts `@Component<R>` too (`unwrapTaskType` → `R`): every caller
  awaits a component (decision 104); a component called inside a `@Component`
  body is awaited by the transform (`inferComponentCall`).

**Contexts** (decisions 354, 378, 379). std's `context` module declares
`Context<T>(contextValue)`, `createContext`, `provide` and `context`;
`noteImportBindings` records the local names a leaf import of them binds
(`Env.stdContextNames`), and `stdContextCallee` also reads a call through the
namespace. `checkStdContextCall` refuses a call of either hook that is not a
`use`'s operand and a `Context(…)` construction (a context is made by
`createContext`). `noteContextDeclaration` reads a module-level `val` of type
`Context<T>` as `T`'s default only when `[comptime] createContext(…)`
initializes it (`context-not-declared` otherwise), one per type in the
program (`context-declared-twice`, naming the first): `Env.contextDefaults`,
published as `Reflection.contextDefaults` (journaled, `analysis_entry.zig`).
A context's identity is its value's type by its declared name
(`contextTypeKey`). `contextReadCall` types `context(T)` as `@Component<T>`
from the type its argument names (any other argument is `context-not-declared`);
`noteContextUse` holds `use provide(ctx)` to a component's body
(`FnContext.renderable`) before its first render (`Env.firstRenderAt`, set by
`inferComponentCall`) and records each use in `Env.contextUses` with its key;
`resolveContextReads`, once the bodies are inferred, gives each read its
type's default — this module's `val`, or another analysed module's through a
hidden import (`Env.contextDefaultImports`, added by `comptime.zig`
`withImportSourcesNamed`) — or refuses the read (`context-not-declared`,
question B-17-g's narrow reading). A lifted `comptime` value of a std type
the module does not import (`Context`) imports it for the backends
(`Env.liftedStdTypes`). A context is its value at run time: `context_lower.zig`
writes each `createContext(v)` (`Env.createContextCalls`) and each lifted
`Context(…)` as `v`, so a value of any type crosses the scope as it does (504;
wasm's `scope_carry.zig` carries `find`'s fallback in its cell as `push`'s
value). Cells `modules/context_default`,
`modules/context_default_imported`, `modules/context_undeclared_type`,
`modules/context_declared_twice`, `modules/context_val_alias`. Decision 416:
`contextReadCall` also types `inject(R)` (`@Component<R>`, a record only,
`inject-not-record`) and `createContext(v, B)` (`Context<B>`, `v`'s type
implementing `B` by its `implements`, `context-behavior-not-implemented`);
`noteContextUse` records an `inject` with its fields (`InjectField`: each
field's key, its default from `Env.ctorParams`), `resolveContextReads` gives
each field its type's declared default (`contextDefaultRef`) or keeps its own,
else refuses the field at the `inject`; a read of a behavior with no declared
default is refused naming `createContext(value, B)`, never a constructor call
(`modules/context_behavior_undeclared`); `context_lower.injectRecord` writes
`R(f: find(scope, key, <fallback>), …)`. Cells `modules/inject_record`,
`modules/inject_behavior_keyed`, `modules/inject_test_root_fake`,
`modules/inject_field_undeclared`, `modules/inject_behavior`,
`modules/context_behavior_not_implemented`.

**The render scope** (388). `noteComponentCall` records every call whose value
is, or may resolve to, a `@Component<R>` (`Env.componentCalls`), the `await`
inference every `await` of one (`Env.componentAwaits`), `inferComponentRun`
every `c.run(scope)` (`Env.componentRuns`, answering `@Task<Rendered<R>>`), and
`noteHostCall` every call of a host (`Env.hostCalls`); `context_lower.zig`
reads them once types are resolved — see its row. A `RenderScope` is made only
by `RenderScope.root()`: its construction is `render-scope-construction`
(`checkStdContextCall`, `StdContextName.render_scope`).

`val {v, s} = use …` binds leniently via `bindUseDestructure`; `val #(a, b) =
use …` (front 19 step 3) binds each name to the element of a tuple `R` at its
position, commits an unresolved `R` to a tuple of the pattern's arity, and
refuses another arity or a non-tuple `R` at the binding (`useTupleArity` —
`use-tuple-arity`, decision 67).

Codegen lowers `use f(x)` to `f(x)` on erlang, wasm and beam and to
`await f(x)` on commonJS, where every `@Component` body is an `async function`
(decision 104). Documented for users in `conformance/docs.md` § *use — imports,
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
  `@Task<T>` → `T` and `@Component<T>` → `T` — `U` when that `T` is `@Result<U, E>`;
- a lambda → its expected return type, else a fresh var shared by its `return`s; a trailing
  lambda (`use memo { -> … }`) owns its `return`s too. A block `{ … }` (decision 525) owns none:
  it is a `case` arm's block (`keepReturnTarget`), its `return` the function's;
- no declared return type, a template fn (`expr q: string`), a sequence body (`@Iterator` /
  `@Stream` that yields: `return <expr>` is `iter-mixed-yield-return` there, decision 123) → unchecked.

A value that already is the declared wrapper (`return state(start)` in a `-> @Component<X>` hook,
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
  child), or a single `@Renderable` value (one-element list). One-directional.
- A function-typed record field (`set: fn(next: T)`) is an ordinary `Type.func`
  field.

## `@emit` fallback bindings (06 N23)

When a decorator `@emit`s code, the spliced re-analysis does the full inference. If it fails, the
binding list handed back is built tolerantly from imports, type declarations, `fn` signatures **and
`val`s**: a decl that fails to infer (a `val` referencing a generated decl) contributes nothing, a
well-typed one binds, so the language server still lists it.

## Every comptime error snapshot has a box (01 step 9)

The implement/extend/behavior coverage refusals, the two `pub default` duplicates and the two
activation refusals were raised with no location — their declarations carried none. `TypeDecl`,
`ImplementDecl`, `ExtendDecl`, `ImplementMethod` and `ModDecl` now record where they are written
(`ast.zig`, left out of the dump, so no parser snapshot moved), and `locatedAt` attaches it: a
missing method at the `implement` keyword or the inline type's name, an unknown / ambiguous method
at the method's name, the duplicate default at the second one, an activation at its item. With the
annotation-position refusals located earlier, `snapshots/comptime/errors/` has no box-less file.

## Explicit type arguments at a use (decision 8 §1.3)

`Box<i32>(value: 1)` and `first<string>([], "none")`: the parser keeps the `<…>` on
`CallExpr.call.typeArgs` (`parser/exprs.zig` `parseExplicitTypeArgs` — only when `<` touches the
name, the items parse as types, `>` closes and `(` follows; `a < b` stays a comparison), and
`applyExplicitTypeArgs` pins the callee's type parameters in order: a constructor's are its type's
(`Box<T>`, the result type's arguments unified with them), a generic fn's are its own — its
declaration (`Env.fnDecls`) is re-read with each parameter bound to its argument and unified with
the call's positional arguments and result; a method's (`ctx.resolve<T>(…)`) are its own, from
its declaration (`Env.inherentMethodDecls`, keyed `"<Type>.<method>"`), with the type's parameters
bound to the receiver's arguments. A count that does not match, or type arguments on a callee with
none, is refused at the call.

**A type application** (decision 255 (1)) — `Dict<string, unknown>.empty()`, `Opt<i32>.None`: the
parser keeps the list on `CallExpr.call.receiverTypeArgs` / `identAccess.receiverTypeArgs`, and
`resolveTypeApplication` resolves it against the receiver — a declared type (an import alias is
its declared name), as many arguments as it declares parameters, else refused at the receiver.
`applyReceiverTypeArgs` (after `applyExplicitTypeArgs` on every call) then unifies: a generic
enum's variant answers `Type<Args>`; an inherent fn (`Env.inherentMethodDecls`) has its declared
parameters and return re-read with the type's parameters bound to the arguments, `Self` to
`Type<Args>` and its own type parameters fresh, so `Dict<string, unknown>.empty()` is a
`Dict<string, unknown>` and `Box<i32>.make("x")` is the mismatch at the argument; any other member
is refused at the call. Without a call (`inferIdentifierExpr`'s `identAccess` arm) only a unit
variant is read — its type carries the arguments instead of fresh variables — and anything else
(`Box<i32>.value`) is refused at the member.

## Three rules the effects guide's page needs (maintainer, 24-box-1)

- **`try x catch null` is a `?U`.** The handler is the other way the expression ends: a `null`
  (any `?U`) handler makes the whole an optional of the success value — `val post = try await
  loadPost(id) catch null;` is a `?Post` — and any other handler must be the success type, the
  mismatch located at the handler (`tryCatch` arm of `inferBranchExpr`).
- **A `noreturn` call ends a branch.** `stmtsAlwaysExit(env, …)` also answers true for a branch
  whose last statement calls a builtin `@panic`/`@todo`/`@trap`/`@compilerError` or any function
  declared `-> noreturn` (`callNeverReturns`), so `if (post == null) { notFound(); }` narrows
  `post` below; `refuseFallingOffTheEnd` reads the same predicate.
- **A component called inside a component body renders there** (decisions 104, 118, 128):
  `inferComponentCall` types a call answering `@Component<R>` whose `R` implements `@Renderable`,
  made inside a `@Component` body, as `R`, and splices `await`
  around it through the index channel (`transform.zig` wraps the call and leaves the copy it wraps
  alone) — on commonJS a component is an `async function`. As `use`'s operand (`Env.inUseOperand`)
  the call keeps its wrapper, so `use Counter()` is still refused by name; as `await`'s own operand
  (`Env.awaitOperandLoc`, the call's location — a component call in its arguments still renders) it
  keeps it so a written `await view(props)` answers `T` (`modules/component_call_awaited`); outside a
  component body or under another base it keeps it too. An array literal's elements unify located at the element
  that disagrees.

## A label names the parameter it fills, in a complete call too

`env.planDefaultFill` planned a call only when it omitted an argument; a COMPLETE call was zipped
positionally by every consumer, so `P(y: "a", x: 1)` typed `"a"` against `x`, `diff(b: 1, a: 10)`
answered `-9`, `s.slice(end: 3, start: 1)` sliced backwards, `Shape.Rect(height: 2, width: 5)` was
`205` on erlang, and a fully-labelled self tail call (`sum(n: n - 1, acc: acc + n)`) assigned its
arguments crosswise and never ended. A complete call whose labels move an argument now gets a plan
too — a pure reorder (`planLabelledCall`, which also refuses a label naming no parameter and a
parameter given twice) — recorded in `defaultInjections` and applied by `transform.zig`'s
`applyDefaultFill` (which now accepts a call as long as the plan), so every backend receives the
arguments in declaration order and the checker unifies each with the parameter its label names.
Reached by the plain fn / record-constructor path, a qualified enum-variant constructor, a
primitive's interface `default fn` and an instance method. A `..` spread (a record update) is not
planned.

An injected default is the parameter's own node (`injectedDefault`, shared by `applyDefaultFill`
and `expandTrailingDefaultsWithParams`) — except a leading-dot unit variant (`target: Target =
.Top`), which is written out `Target.Top`, qualified by the parameter's declared enum (a plain name,
or a `?` over one): the default was typed in its declaration and no call-site rewrite
(`indexRewrites`) reached it, so commonJS read a bare `Top` (`ReferenceError`) and beam the atom
`'Top'` (`conformance/modules/imported_enum_field`). A section path keeps the written node. The
qualifier is the declared name: a consumer that does not import the enum still cannot name it —
the import closure's, not this fill's.

## A default travels with an imported function (C-04 across a module boundary)

`Env.fnParams` held only the module's own functions, so a call to an imported one that omitted a
trailing default was the arity error of a required argument (`'text' expects 2 argument(s), got 1`
for a library's `text("hi")`), and every library call site spelled the default by hand. A `pub fn`
whose parameters declare a default now exports them as written (`registerExports`, under
`defaultParamsKey(path, name)` in the template registry, a key no import item can spell), and the
importer puts them in `Env.fnParams` under its local name, so the fill and the label reorder run as
for a local call. Only a **closed** default travels (`isClosedDefault`: a literal, `true` / `false`,
a sign, an array or tuple literal of those): a default naming a binding of the declaring module
cannot be written at the importer's call site, so that parameter is exported without it and omitting
it stays the arity error. `conformance/modules/default_argument_across_modules` (a sibling module
and a path dependency, on all four targets) and `modules/default_argument_open_across_modules` (the
refusal).

## Decision 2 is enforced (01 R7)

A value leaves a function body through `return` or its tail (decision 409).
`refuseFallingOffTheEnd` (after `inferFnDecl`'s body) refuses a plain `fn` whose written return type
has a value and whose body can reach its end — `stmtsMayFallThrough` / `exprMayFallThrough`: the
last statement is not a `return`/`throw`/`break`, an `if`/`else` or `case` every branch of which
ends that way, a bare `loop { }`, or a `noreturn` builtin (`@panic`, `@todo`, `@trap`,
`@compilerError`). Located at the return type. A wrapper return is judged by what running off the
end hands out: a `@Result` in any layer — `@Result<void, E>` included, whose `ok` position is the
empty `return;` (decision 74) — and a `@Task` / `@Component` whose value layer is a value are
refused; one whose value layer is `void` / `noreturn` falls through as a `void` fn does. `@Iterator`
/ `@Stream`, a type guard, a `declare`/`@External` fn and a template fn are not judged.
`refuseValuelessIf` refuses an `if` without `else` bound by a `val`/`var` (local or module-level).
Each backend's block-as-value lowering loses its producers: erlang's tail `case`, beam's
`make_fun3`, commonJS's IIFE, wasm's `;; lambda` (residual-rows R7 names them for the four fronts).

## A body's tail (decision 409)

A function body's last expression written without `;` is its value. The parser marks it
(`ast.Stmt.tail`, `parser.zig` `parseBlockBody` with `markTail`: a `fn` / method / behavior default
body, a function expression, a lambda) and, where the written return has a value (`returnTail`:
not `void` / `noreturn`, not a wrapper whose value layer is `void`, not a generator that yields),
wraps it in `return` located at the expression (`tail = .returned`) — so this checker, the
evaluators and every backend read the `return` it means, and `fn bad(x: i32) -> i32 { "a" }` is
the return's mismatch at the `"a"`; a tail every path of which already leaves (`if (c) return a
else return b`, `@panic(…)`) is left alone. In a body answering nothing — no `-> R` or `-> void`, a
`fn`, a type's method (one without `->` whose `return`s carry no value) or a typed function
expression — a `tail = .value` statement must be `void` (`refuseValueTailInVoid`, at the tail). A
typed function expression answers its written return: with `-> R` a body that can run off its end
is refused at the expression (`stmtsMayFallThrough`), and its tail does not type it. A lambda and an
untyped `fn(x) { … }` keep the value of their last statement as before — except that a lambda
whose last expression statement is written with `;` answers nothing (decision 541 (1)):
`discardUnwrittenTail` appends a typed bare `return` after it, so every backend reads a lambda that ends in a
statement, and the lambda's type is `void` (`{ x -> bump(x); }` stands where `fn(i32) -> void` is expected and is
refused, at the lambda, where `fn(i32) -> i32` is); a last expression already `void` / `noreturn` needs nothing.

## Blocks (decision 525)

A `{` without `->` is a block, never a closure. The parser lands it as `case true { _ { … } }`
flagged `isBlock` (`parser/AGENTS.md` § Blocks), so it is typed as a `case` arm's block: its
`return` keeps the enclosing function's target (`keepReturnTarget`), and its value is its tail.
`inferStmtsTyped` keeps each statement's `tail`, which `caseArmValueType` reads: an arm's value is
its last statement when it is a tail (`tail == .value`), a top-level `break <value>` still winning;
an arm whose last statement is written with `;` contributes nothing. The refusals, each located:

- `case-arm-no-value` — a `case` used as a value (not a whole statement: `env.statementBlockLoc`,
  set per statement by `statementBlockLocOf` for a `case` or a block) whose type is not `void`, one
  of whose arms answers nothing (`armAnswersNothing`: no tail, a `void` tail; a jump or a
  `noreturn` last statement leaves instead) — at the arm's pattern;
- **A trailing lambda is the call's last argument** (decision 525, `ast.lowerTrailingLambdas`): `f(x) { n -> … }` is
  `f(x, { n -> … })` and `b.run { -> 10 }` is `b.run({ -> 10 })`, so the parameter it fills is checked and bound as
  a lambda argument's is (`lowerTrailingLambdas` at the head of `inferCallExprWith`) and `transform.zig`'s
  `rewriteExpr` lowers the program the same way, so no backend meets a trailing lambda on a non-builtin call. A
  labelled trailing lambda (`erro: { … }`) and a block are left as written (`inferTrailingLambdasTyped`); cell
  `modules/trailing_lambda_call`;
- `block-not-function` — a block handed where a function is expected: a trailing `{` without `->`
  (`TrailingLambda.isBlock`, refused in `inferTrailingLambdasTyped` at its `{`), a block whose
  position's expected type is a function (`refuseBlockShape`), and a block argument of a
  function-typed parameter (`unifyArgument` reads `env.blockLocs`, the blocks inferred so far);
- `block-void-value` — a block whose value is `void` handed where `unknown` is expected (the
  position's expectation, or `unifyArgument`);
- `block-break-value` — a written `break <value>` meant as a block's value: in a block's own
  statements and `if` branches (`blockBreakValue`; a loop and a closure are scopes of their own),
  in `comptime { … }`, whose tail the parser wrapped in the block's `break` (`tail = .returned`,
  skipped), and in a `case` arm's block (decision 541 (3): `BreakScope.armBlock`, refused where the
  `break` is typed; a generator scope's `break <value>` is the generator's and stays).

`@block` is a parse error (`removed-block-builtin`), and `builtins.d.bp` no longer declares it.
`await`, `yield`, `break` and `continue` in a block or a `case` arm's block reach the enclosing function or
loop (decision 541 (2)): `inferFunctionExprExpectedInner` keeps `starFn`, the label stack, `loopDepth`,
`asyncBlockDepth` and `inferredErrorScope` for an arm's block (`env.keepReturnTarget`), as it keeps the return
target. `try e` and `await e` are values, so a block or an arm may end in one (`valueJump`).

## Decisions 44 and 45 (C-18)

**44** — `?T` is the one optional spelling: `optional<T>` (the checker's own internal name, which a
written annotation reached and checked clean) and `Option<T>` / `Optional<T>` are refused at the
annotation with the `@Option<T>` diagnostic's text, unless the module declares a type of that name.
**45** — a member read off a `?T` with a plain `.` is refused naming `?.` (the field-read arm of
`inferIdentifierExpr`): `rs.at(0).b` used to check and answer `undefined` / `bad map`, the label
rewrite never firing on an optional receiver. `x?.field`, narrowing, and the index of C-02
(`rows[0]?.length`) are the spellings; a METHOD on an optional (`unwrapOr`, …) is not a member read.
A read written after a `?.` link is not off a `?T` the program holds: it continues the chain
(decision 330, TypeScript's rule, as a method there does) — `p(true)?.me().x`, `a?.b.c`.
`inferOptionalChainField` types it as the `if` over the chain so far (`if (<chain>) { n -> n.x }
else { null }`, binder `__bp_optf_<line>_<col>`), recorded in `enumSectionRewrites` under the
access's loc for the transform to splice, and answers the access as a `?.` link so a link after it
continues too (`continuesOptionalChain`).

## STD-001 refuses at the call, never at the import (C-03, decision 518 (4))

`std-unsupported-on-target` belongs to the call of a std function that reaches a
host-bound declaration with no binding for the target, and names it at the call.
`inferCallExprWith` asks `stdCallee` which std function a call names — through a
namespace (`clock.nowMillis()`, a folder's `io.clock.…` after `std_namespace`'s
rewrite) or a leaf import (`node()` after `import {erlang.node}`) — and
`checkStdCall` refuses it when `stdUnsupportedReach` finds a declaration with no
binding: the function itself, or one its body reaches through its module's own
functions (`Env.stdModuleAllFns`, every `fn` of the module, private ones too,
followed by `ast.collectNames`) — the message then names both
(``std/io/clock.nowMillis reaches `systemTimeWithUnit`, which has no …``). An
import is never refused: `std/failure`, `erlang`, `io/process` import on every
target, and a declaration nothing calls costs nothing. A function value taken
without a call is the backend's refusal. Cells:
`conformance/modules/std_unsupported_refused_at_the_call`,
`modules/std_unsupported_names_the_call`, `modules/std_erlang_node`,
`modules/import_std_folder_namespace`, `modules/std_asserts_host_cell_on_wasm`.

## `needs:` on `.Wasm` (decision 518)

`refuseNeedsArg` (beside `refuseHostArg`, on every `declare fn`, method and
behavior method, every target) holds `needs:` to std's closed enum `WasmNeed {
Exceptions, Http }` (`builtins.d.bp`; the compiler's copy is `ast.WasmNeed`, a
test keeps them in step): a list, each item `.Exceptions` or `.Http`, on
`.Wasm` alone — anything else is refused at the annotation
(`conformance/modules/external_wasm_needs_unknown`). `checkExternalCells` and the
arity count skip it, as they skip `host:`; the parser reads the `[…]` list as
one argument.

## An integer literal takes the width its position asks for (01-std's handover)

`inferLiteralExpr` types an integer literal as the integer type `env.expectedType` names (through
one `?T`, `expectedIntegerType`), `i32` when nothing asks — so `val k: i64 = 1000;` and an `i64`
parameter take a literal. The default of `unwrapOr` is inferred under the payload of the `?T` /
`@Result<T, E>` it is called on (`unwrapOrDefaultExpected`, read before the call's arguments are
inferred), so `delay(n).unwrapOr(0)` over `?i64` types the `0` as `i64`
(`conformance/modules/unwrap_or_literal_width`). Decision 209 — an integer **literal** whose
position expects `f64` (`expectsFloat`, through one `?T`: a `val` annotation, an argument, a field,
a return, an element of an expected `f64[]`, the other operand of an arithmetic or ordering
operator) is typed `f64` and re-spelt as a float literal through `env.indexRewrites`, as the array
join does; an `i32` value never widens (`run/integer_literal_fits_f64`,
`modules/i32_value_never_widens`). `==` / `!=` do not widen (`equalityOperandExpectation`): between
an `f64` and an integer literal they are refused at the literal, `comparing f64 with an integer
literal — write 2.0` (decision 215, `inferBinaryOpExpr`; `modules/f64_equals_integer_literal`,
`modules/f64_not_equals_integer_literal` — the old B2 expectation `2.0 == 2` is `false`). `inferExprTypedInner` lets `.literal`, `.unaryOp` and `.binaryOp` keep the
expectation; `inferBinaryOpExpr` hands it on only to the operands of an arithmetic operator
(`3 * 86400000` passed to an `i64`), and types a literal operand of an arithmetic or comparison
operator from the other operand (`n * 1000`, `1000 - n`, `x > 0`). The arithmetic `unify` of the
two operands is `unifyAt` the right operand now (01 step 9), so `x + y` with `x: i64, y: i32` reds at
`y` instead of at no location. A float literal is `f64` as before.

Decision 319 — the width it takes is a range: `refuseIntegerOutOfRange` refuses an integer literal,
suffixed or not, that its type has no value for, at the literal (`val e: i32 = 3000000000;` and an
unannotated `3000000000` were accepted; `modules/integer_literal_unsuffixed_out_of_range`,
`modules/integer_literal_unsuffixed_default_out_of_range`). The operand of a unary `-` that is an
integer literal is read as the negative value (`env.negatingLiteral`, set by `inferUnaryOpExpr`), so
a signed type's minimum is written as itself — `-9223372036854775808l` was refused as `2^63` — and
`-129` is below `i8` (`modules/integer_literal_below_minimum`, `modules/integer_literal_type_minimum`).
A negated literal takes its width from the other operand of an arithmetic or comparison operator as
the literal does (`isIntegerLiteralOperand`): `value >= -9007199254740991` over an `i64` typed it
`i32`, which the range check then refused (validation's `vSafeInt`). `modules/i64_full_width` writes its
literal past the `i32` range with `l`: unsuffixed and with nothing asking it is an `i32` (247).

Decision 247's suffix leaves the program in `transform.zig`'s `rewriteExpr` for every number literal
(`lexer.numberBackendText`, idempotent), whatever its position: a `case` arm's guard and a fn
parameter's default are walked there too, so `if s.mtime > 5l` and `v: i64 = 7l` reach no backend with
their `l` (`modules/numeric_suffix_positions`). A method's parameter default, a record field default and
a guard in a method body need no walk of their own: measured on all four targets, none carries the suffix
(inference strips them with the rest), and the same cell holds them.

## `bigint`, an integer of any size (decision 332, front `01-compiler/139`)

`bigint` is a primitive (`Env.registerBuiltins`, `scalar_type_names`), its literal suffixed `n`
(`lexer.number_suffixes`): `inferLiteralExpr` types `42n` `bigint` with no range check, and the
literal keeps its `n` in the program the backends lower (`lexer.numberBackendText` — the one
literal whose text names its type, `lexer.isBigintText`). An unsuffixed literal where a `bigint` is
expected is refused at the literal naming the spelling (`expectsBigint`: `val x: bigint = 2` and
`2n + 1` — the right operand takes the left one's type — answer `write 2n` / `write 1n`). `bigint`
is not in `isIntType`: it joins no numeric promotion, so `2n * a` with `a: i64` and `2n + 1.5` are
the ordinary mismatch, located at the right operand. An arithmetic operator over two records
`ArithKind.bigint` (`range()` null: no overflow check on any backend). The methods are
`primitives.bp`'s `behavior BigInt` (`primitiveInterfaceName`, `PrimKind.bigint`); `bigint.of(n)` /
`bigint.parse(text)` (`inferPrimitiveStaticCall`, entered when the receiver names the primitive and no
binding shadows it — `registerBuiltins` binds a primitive's name to its type) type each argument
against the associated function's parameter (`bigint.of(5)` reads `5` as an `i64`) through
`inferAssociatedFnCall`, and rename the receiver to `BigInt` through `env.indexRewrites` (decision
110's alias channel), so every backend renders decision 262's associated host primitive. Question
139-a's answer (the most restrictive reading, built): a `bigint` does not widen to `unknown`
(`unify.zig`, `bigint-widened`; `@print`'s variadic `unknown` takes one — `checkDeclaredArguments`),
`is` and a type pattern neither test for one nor test a subject that holds one (`bigint-type-test`),
and a `comptime` whose value holds one is refused at the `comptime` (`foldBodyComptime`,
`comptime-bigint`: the folder and the comptime runtimes hold 64 bits). Cells:
`modules/bigint_arithmetic`, `modules/bigint_in_containers`, `modules/bigint_to_i64_aborts`,
`modules/bigint_division_by_zero`, `modules/bigint_across_modules`, `reject/bigint_*`.

## `Bytes`, an immutable byte sequence (decision 346, 144 B-12 step 32)

`Bytes` is a primitive (`Env.registerBuiltins`, `scalar_type_names`, `primKindOfName` →
`PrimKind.bytes`) whose behavior shares its name (`primitives.bp`'s `behavior Bytes`,
`primitiveInterfaceName("Bytes")` is `"Bytes"`): a method call on a `Bytes` value skips the
inherent-method and behavior-typed-receiver paths of `inferCallExprWith` (which the shared name
would otherwise enter) and is the primitive's, `length` renamed to commonJS's property as an array's
and a string's are. `Bytes.fromUtf8(s)` is `inferPrimitiveStaticCall`'s, as `bigint.of` is. No
literal is `Bytes` and nothing converts: a string where `Bytes` is expected, and `Bytes` where a
`string` is, are the ordinary mismatch at the value. The most restrictive reading of the rest
(decision 67): `Bytes` does not widen to `unknown` (`unify.zig`, `bytes-widened` — so `@print` does
not take one: erlang holds `Bytes` and a `string` alike), `is` and a type pattern do not test it
(`bytes-type-test`), a `comptime` whose value holds one is refused (`comptime-bytes`), and an
operator other than `==` / `!=` is refused at the `Bytes` operand (`+` — and so a string template,
which `inferLiteralExpr` joins with `+` — answers "no text to join"). `==` / `!=` over `Bytes` records
`InstanceLowering.prim = .bytes` at the operator, which wasm reads to compare the bytes. A `std:`
cell spells `?Bytes` (`spelledType`). Cells: `modules/bytes_*`.

Decisions 472, 533 — an arithmetic error while a `comptime` runs (the runtime's `{error,badarith}`) is
`comptime-badarith: an error occurred when evaluating an arithmetic expression — \`<expression>\``,
built by `block_eval.badarithRefusal` at the two places that run a block (`foldBodyComptime`,
`holeValue`). A division or a remainder by zero adds `(division by zero)` wherever it is — alone, inside a
larger expression, in a function the block calls — and is located at the operator that divides: a
comptime module lowers `/` and `%` through `'__bp_cdz'/1` (`codegen/erlang.zig` `cdz_helper_form`), which
raises `{bp_wat_runtime, <<"division by zero">>}` on a `0` divisor (integer or float), inside
a frame at the operator (decision 532); `parseReply` / the decorator and template
replies read that term as the plain text `division by zero` (`block_eval.divisionByZero`, as an unseeded
draw), and `badarithRefusal` names the cause. Any other `badarith` (a float overflow) stays without it,
located at the innermost located call it left, else at the expression. Cells:
`modules/comptime_float_division_by_zero`, `comptime_integer_division_by_zero`,
`comptime_remainder_by_zero`, `comptime_nested_division_by_zero`, `comptime_division_by_zero_in_helper`,
`hole_any_call_raises`; the deep-equality cell is
`modules/comptime_deep_structure_equality` (decision 471, std-wasm's `compare`).

Decisions 451 (3), 456 — an unseeded draw at build (`random.float()`, `seededFloat()` before a `seed`) is
refused with the plain text `an unseeded draw: a build has no entropy, call \`random.seed\` first (decision
451)`, no Erlang term and no `the comptime block raised:` prefix, the same on the `comptime` and the decorator
forms: `block_eval.unseededDraw` drops the runtime's `{error,{bp_wat_runtime,<<"…">>}}` wrapper in `parseReply`
and `decorator_eval.parseOutcome`. Cells: `modules/comptime_random_unseeded`, `comptime_random_float_unseeded`,
`decorator_random_float_unseeded`.

## One variant table, four symptoms (01 step 12)

Every enum variant's constructor is bound under its bare name in `Env.bindings`, where the last
enum to declare a name wins. Four spellings read that table and answered the wrong enum; each now
asks the question its position has:

- **Qualified** — `Shape.Circle(r: 3)` reads `Env.variantCtors["Shape.Circle"]` (every variant of
  every enum, section wrappers `Token.Color` and section variants `__Token__Color.Hex` included),
  so another enum's `Circle` cannot answer it (row 3c, the step's gate).
- **Leading dot** — `.Red` takes the enum the position expects (`expectedEnumDeclaring`, the rule
  `.Circle(…)` already had), spliced in as `Warm.Red` through the index channel so every backend
  sees the qualified form (`transform.zig` replaces a `dotIdent` node carrying an identifier
  rewrite). A section type is an enum too, so `val b: Token.Layout.Break = .Zeta;` resolves the
  section leaf; with no expectation a section leaf is refused naming its section
  (`sectionOwningLeaf`) rather than reported unbound. The right side of `==` / `!=` expects the
  left side's type. A `?Place` position expects a `Place`: `.Here` there is `Place.Here` (a
  `val`'s annotation, a field, a parameter); unqualified it was a bare `Here` on commonJS
  (`ReferenceError`) and the atom `'Here'` on beam (`modules/optional_payload_enum_value`).
- **Bare, with several claimants** — `Env.variantClaims` lists every enum declaring a name; a use
  that reaches a claimant's constructor through the flat table while two or more claim it is
  refused, naming them (`refuseAmbiguousVariant`, decision 67). A name that is also a type or a
  behavior (`Array.range`) is read as that.
- **A payload leaf in a section path** — `.Color.Hex("#abc")` / `Token.Color.Hex("#abc")`
  (`tryResolveSectionPayloadCall`): the carrier is chosen as for a unit path (the enum written,
  the one carrier, or the expected one, else ES5), and the qualified constructor chain is spliced
  in through the index channel.
- `Token.Text.Italic` where `Token.Text` is expected is a value of the section
  (`sectionValueForExpected`), not of `Token`.

- **The comptime registries** — `comptime.zig`'s template and decorator registries are keyed by
  the exporting module and the name (`comptimeRegistryKey`, `<path>\x00<name>`), and
  `resolveImports` looks a name up under the module its import resolves to: two modules exporting
  a `tag` template or a `validated` decorator no longer leave whichever registered last
  (`modules/template_name_collision`). A package's default handler stays under its bare handle.

Not reached: a `case` arm's leading-dot pattern is resolved against the subject by the backends,
and wasm's `findVariant` still takes the first enum declaring the name (05-wasm).

## An import of a refused module names it (`import-of-failed-module`)

A module the build refused (a lex, parse, validation or type error, a `@TypeInfo.all` reader
refusal) registers no exports, so its importers used to read every name they took from it as
`unbound variable`, at its first use, and their own importers the same, transitively — the one real
error buried under one line per importer. `compileOnce` and `compileTypesOnly` record each refused
module in `Reflection.failedModules`; `resolveImports` records in `Env.failedImports` an item that
binds nothing while a refused module is one its source admits (the passes and the scope the value
scan uses), and a namespace item (`import {shapes};`, `mod shapes;`) whose module was refused; and
`unboundAt` turns a use of such a name into `import-of-failed-module` **at the import item**, naming
the module and its file (`` `area` comes from `shapes`, which failed to check — its own errors are reported
there (src/shapes.bp) ``, the label the failed module's own diagnostics print, `Reflection.diagLabels`: `src/shapes.bp` for a program module, `a/client.bp` for a dependency's; decision 545) — one wording for a name and a namespace, since a refused module exports nothing and
`import {components.Card};` cannot tell the two apart. The refused module keeps its own error. Nothing real is hidden: an importer reports one error, its first, as before; a name
missing from a module that checked reaches none of this and stays `unbound variable` (the resolver's
`imported symbol is not exported` catches it first in a build). Pinned by
`conformance/modules/import_of_failed_module` and `tests/infer_decls.zig`'s `import of a failed
module` tests.

## A local ends with its body (01 step 13)

`Env.bindings` is one flat table, and a body's parameters and locals used to stay in it: a `val` of
one `fn` was bound for every declaration inferred after it, and a local named like a module
declaration retyped that declaration for the next function. `inferFnDecl`, `inferTestDecl` and
each method of `inferTypeMethods` now open a **body scope** (`Env.openBodyScope`): every `bind` /
`bindVal` inside records what the name was bound to before (`BindUndo`), and `closeBodyScope`
replays the log backwards, so every name the body bound — parameters, locals, pattern binders — is
back exactly as it was. A name a top-level body introduced is remembered in `Env.closedLocals`, so a
later use outside it reds `unbound variable 'v' — `v` is a local of `holder`, …` (`unboundAt`).
Closures do not open a scope of their own yet: a lambda's parameter is visible to the rest of the
enclosing body, never beyond it.

## Generic types carry their arguments (decision 8 §1.1, §1.2 — 01 step 6, C-15)

§1.1 — a written use of a `type` with type parameters supplies every parameter without a default:
`fn get(b: Box)` is `Box needs 1 type argument` and `Pair<i32>` for `Pair<A, B>` is `Pair needs 2
type arguments, 1 given`, located at the annotation (`resolveTypeRefInContext`, `requiredGenericArgs`,
`refuseGenericArity`). `env.resolveTypeName`'s "a bare generic name means any arguments" tail is no
longer reached from a written annotation.

§1.2 — `Self` follows §1.1. `checkSelfSpelling` walks every `type`'s and `behavior`'s method
signatures at the declaration (before `Self` is bound to a receiver, where the declaration that was
wrong can no longer be named): bare `Self` in a declaration with type parameters is `Self needs N
type argument(s)`; `Self<…>` in one without is refused too. `Self<U>` resolves to the declaration's
own type over the written arguments (`Box<U>`); where `Self` is bound to a non-generic implementer
of a generic behavior (A1), `Self<…>` is that implementer as it is, so `Point(x: 1).map({ x -> "a" })`
reds against `Mappable<i32>` while `Box(value: 1).map({ x -> "a" })` is a `Box<string>`. `libs/std`
writes `Self<…>` in all its generic declarations; the backends read either spelling through
`ast.TypeRef.isSelf()`.

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
do not print them yet. Writers: §1.4's `flushBirthWarnings`, §4.3's `warnAlwaysFalseIs` and §6 T7's `warnTupleLabelMismatch`.

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
that agree still unify, so one branch pins the other's variables exactly as before. Decision 150 (D5) adds the array literal: with no element type expected (or an unbound
variable), `arrayLiteralJoin` unifies the elements that agree and makes the disagreeing ones union
members (`[1, "a"]` is `(i32 | string)[]`, `[1, null]` is `?i32[]`), records the first widening
element in `Env.unionOrigins` (kind `array element`, named by the refusal at the use), and applies
§3.2's one numeric rule — an integer **literal** fits `f64` when another element is an `f64`, typed
`f64` and re-spelt as a float literal (`1` → `1.0`, `0xFF` → `255.0`) through `env.indexRewrites`,
literal for literal, which `transform.zig` splices. Two function-typed elements always unify
(`caseArmTypesAgree`, below), so an array of lambdas stays one element type. An expected behavior or union is the
element type every element meets; any other expected element type keeps the old rule (each element
unified with the first), so `total([1, 2.5])` against `f64[]` is still the mismatch at the `1`. Every join — `case` arms, `if` branches, array elements —
asks `caseArmTypesAgree`, and two function types always agree there (rows 28/31 of `language-gaps.md`,
1.0.11-beta `01-checker` step 2): a function is never a union member beside another, so two arms
`fn(string) -> string` unify into one type, and two whose arity or parameters differ are the located
mismatch at the second arm instead of a `fn | fn` union nothing can call.

§3.3's use rule is `refuseUnknownUse`, shared with §2.2 (see above): a union receiver is refused at
arithmetic, `+`, an ordering comparison, a field read and a method call. §3.3 allows a use every
member allows; deciding that means re-resolving the operation once per member, which is not built,
so the refusal is total — more than §3.3 asks, and never wrong. §3.2's diagnostic names the branch that
widened it: an `if` or `case` whose branches made a union records its location in
`Env.unionOrigins`, and the refusal at the use appends "(the `if` at L:C made it one: its branches
disagree)" — the use is the caret, the widening is in the text (`TypeError` carries one `Loc`).

A `case` or `if` the checker types a union also records itself in `Env.unionValues` (its loc → the
union and each arm's own type, in arm order: `caseTypeFromArms` fills one slot per arm, null for an
arm that answers nothing; an `if`'s `then` and `else`), which `infer.unionValueLowerings` turns,
once the module is inferred and every arm's variable is as resolved as it will be, into
`InstanceLowering.union_value` at that loc: the union written back (`infer.typeRefOfType`, the one
checker-type-to-`TypeRef` writer, shared with `context_lower.zig`; `unknown` when a member has no
written form — a type variable, a structural record) and each arm's written type. The wasm backend,
which boxes a union member by its static type, reads it (`codegen/wat/AGENTS.md` § A generic
payload and a union value in an `unknown` slot); erlang, beam and commonJS ignore it.

`error.zig` `typeLabelAlloc` spells a type as a source writes it in a mismatch message: a union as
`A | B`, an optional as `?T` (decision 2 — `optional` is the checker's internal name and no
spelling), an array as `T[]`, a section as its path (`Token.Text`, not `__Token__Text`); every
other kind is `typeLabel`'s own text. The snapshot renderer's `expected:` / `found:` lines are
`snapshot.zig`'s and keep their frozen spelling.

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

The same table decides three more places, each through `collectCondNarrowings` and `bindNarrowed`:

- **The right operand of `&&` / `||`** (`inferBinaryOpExpr`) — it runs only where the left operand held
  (`&&`: the left's then side) or failed (`||`: its else side), so `x != null && x.f` and
  `x == null || x.f` read `x` narrowed. This is what an `if` / `while` condition written that way
  needs too: the condition is inferred before any branch is. `x != null || x.f` narrows nothing —
  the right side runs where `x` IS null (`modules/narrow_or_keeps_optional`).
- **A `while` body** (`inferLoopExpr`) — the then side of the condition, restored when the body ends.
- **A narrowed `var` stays assignable at its DECLARED type.** `bindNarrowed` records the declared
  type in `env.narrowedDecl`; an assignment to the name checks the value against it (`x = x.next`
  inside `while (x != null)` assigns a `?Node`) and **ends the narrowing** — the name takes the
  declared type back for the rest of the scope (`modules/narrow_ends_at_assignment`). The snapshot
  restores the entry, and restores a `val` as a `val` (`PatternBindingSnapshot.wasVal`).
  Pinned by `modules/narrow_in_logical_operands` on all four targets.

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
| `if (x)` on a `?T`, no binder | refused — "type mismatch: expected bool, got ?string". There is no truthiness on an optional; `if (x) { v -> … }` is the form (`modules/if_optional_needs_a_binder`) |
| `o.inner != null` | only a plain NAME narrows, above. `o.inner.v` answers on commonJS and erlang today, by accident: nothing the rename touches is on that path |
| `case x { null { … } v { … } }` | narrows already, and not through this channel — a 1-parameter arm binds the whole matched value narrowed by its own pattern (§ `case` and `comptime` block types), which is why the `null` arm leaves `v` the payload |

**Not implemented.** §4.3 (`a is string` on a statically-known `i32` is a *warning*, always false)
needs the warning channel `comptime/**` does not have — the same gap §2.4 and §1.4 hit. §4.1's
"an integral `f64` is converted to the tested integer type inside the block" is each backend's
run-time half. D4 (whether `is` grows a payload pattern) stands as the parser left it: the located
`is-variant-binding` refusal, with `case` the only reader of a payload.

## a record is immutable (decision 37)

`p.age = 31` and `self.count += 1` both checked and both mutated in place. The decided form is a new
value — `Person(..p, age: 31)` — which the constructor's `..` spread builds (06 C11; the checker
matches each label to its field, and `rewriteRecordUpdate` records the complete positional call —
the labelled value, or `base.<field>` inferred under a loc of its own: the base's line, its column
with the field index + 1 in the upper half of `usize`, bit `@bitSizeOf(usize) / 2` — 32 natively, 16
on wasm32, where a shift by 32 does not compile — in `enumSectionRewrites`,
whose call rewrite in `transform.zig` then moves the arguments too; the base must be a name or a
path of names, anything else would run once per copied field), so
`refuseRecordFieldAssign` (the `.fieldAccess` target of the `.assign` walk) reds at the assignment
and spells that form out, naming the receiver when it is a plain name it can spread.

## a field key at run time (decision 308)

`pub val RecipeKey = Type.keys(Recipe);` is the alias `type RecipeKey = Type.Field<Recipe>;`
(`derived_types.zig` `keysAlias`). A key's value is std's `Type.Field<T>` record (`name`, `typeName`,
`annotations`); the checker types each written form through the ordinary expression it means and records
it in `Env.fieldKeyRewrites` under the written node's loc, which `transform.zig` (`field_keys`) swaps whole
— the rewrite's own nodes at `ast.field_key_synthetic_col`, so no backend learns a node:

- `.title` where the position expects a `Type.Field<T>` (an annotation, a parameter, `key = .title` on a
  `var` of that type, the right of `==` / `??`) — `inferFieldKeyLiteral`: `Type__Field("title",
  "<the field's type>", [])`, an unknown field the `unknown field` error at the `.name`;
- `case key { .title -> …; .a | .b -> …; _ -> … }` — `inferFieldKeyCase`: exhaustive over `T`'s fields
  (`not exhaustive: missing field(s) .servings` at the `case`, a field twice `redundantPattern`), run as
  the `case` over `key.name` with string patterns and a last `_` arm that panics;
- `K.of(text)` / `K.all()` with `K` an alias of `Type.Field<T>` — `inferFieldKeyStatic`: a `case` over
  `text` answering each key or `null`, and the array of every key in declaration order.

A module importing such an alias imports std's `Type__Field` (`withFieldKeyImport`), and
`assoc_types.zig` adds no item a module already imports (`modules/field_key_runtime`,
`field_key_case_missing`, `field_key_unknown_field`, `type_keys_outside_val`).

## a spread copies a record's fields (decision 359)

Since decision 529 (3) the parser no longer produces the argument labelled `ast.spread_arg_label` (decision 37's older
`..base` update): `..src` is the record spread below, so the label's handling in `infer.zig` (`rewriteRecordUpdate`, the
`".."` branches of the call paths) is residue, no source reaches it. A variadic callee refuses the spread by 267's
`variadic-spread` before `inferRecordSpread` runs.

`Pessoa(..old, nome: "Ana")` (decision 529 (3): `..` is the one spelling; `...` is only the inclusive range and
`...src` is `spread-dot-dot-dot` at the parser) — the parser reads `..src` at the start of a call argument as the
argument labelled `ast.record_spread_label`, the `..` token on `CallArg.spreadLoc`; the formatter
prints it back. `inferRecordSpread` (intercepted in `inferCallExpr` before the arguments are
inferred) judges it: the callee is a record's constructor (an import alias of one included) or the
call is `call-spread` at the `..` (267: a function call takes no spread); each source is a value of
the record's own type or of a type whose lineage names it (`Env.derivedTypes`, filled from
`TypeDecl.derivedFrom` / `derivedPartial`, which `derived_types.zig` computes: `pick`, `omit` and
`merge` carry their sources' — by declared name, so a source named through an import alias
(`Pessoa as P`) records `Pessoa` — `partial` and `required` carry none), else `record-spread-type`, and
a `Type.partial` value is `record-spread-partial`, both at the `..`; the arguments apply left to
right, the later winning; a field no spread and no label supplies takes its default or is
`record-spread-missing-field` at the call; a label written twice or an unlabelled argument is
`record-spread-arguments`. It records the complete positional call in `enumSectionRewrites` — each
field the last supplier's value, `src.<field>` read under a loc of its own as above, or the
default. A source that is not a name or a path of names is bound once, by a `val
__bp_spread_<line>_<col>_<exp>` in an `if (true) { …; Name(…) } else { @panic(…) }` block (the
construction at `ast.spread_synthetic_col` past the call's column), which `transform.zig` splices
whole in the call's place. A labelled value a later spread overrides supplies no field but is still
typed against it and, unless it is a name path or a plain literal, evaluated in that block after the
sources, its value dropped (`record_spread_evaluation_order`, `record_spread_overridden_label_type`).
A source of a type that is no record is named in its source spelling (`?Pessoa`,
`record_spread_optional`). Cells: `modules/record_spread`, `record_spread_other_type`,
`record_spread_partial`, `record_spread_missing_field`, `call_spread`, `record_spread_import_alias`,
and the Conformance step's `record_spread_across_modules`, `record_spread_nested`,
`record_spread_call_source`, `record_spread_label_twice`, `record_spread_positional_argument`,
`record_spread_beside_record_update`, `record_spread_derived_partial`, `record_spread_required`.
Decision 37's `..base` above is untouched.

## a record parameter `..props: R` (decision 529 (2))

`fn Card(..props: CardProps, onClick: fn() -> void)` — the parser reads `..name: T` with `T` a named
non-primitive type as `Param.recordParam` (an array stays the variadic of 267, `..v: i32` the
parser's `variadic-not-array`). The parameter is an ordinary parameter of type `R` for every pass and
backend: only the call changes. `checkRecordParams` (`inferFnDecl`) refuses at the declaration a
second record parameter (`record-param-twice`, at its `..`), an `R` that is no record
(`record-param-not-record`, at the type), a name that is both a parameter and a field of `R`
(`record-param-clash`, at the parameter) and a variadic beside it (`record-param-variadic`, at the
variadic). `packRecordParamCall` (intercepted in `inferCallExprWith` ahead of the record spread, for a
plain call whose callee `calleeParams` answers with a record parameter) gathers the labels naming a
field of `R` and the `..src` spread into one construction `R(…)` at `loc + ast.record_param_synthetic_col`,
the argument labelled with the record parameter's name, keeps the other arguments (a positional one
past the record parameter labelled with its parameter), marks the call `recordPacked` and records it
under the call's loc in `indexRewrites` — the transform splices it like a variadic's packed call. The
construction then runs the record's own rules (359: the later supplier wins, `record-spread-missing-field`,
`record-spread-type` / `record-spread-partial` at the `..`; defaults from `R`'s fields); a label that
names neither is `record-param-label` at the label. A plain function takes no spread (`call-spread`).
Not reached: a method or an associated function with a record parameter, a tag (529 (1), (4), (5)).
Cells: `record_param`, `record_param_twice`, `record_param_not_record`, `record_param_clash`,
`record_param_variadic`, `record_param_default`, `record_param_unknown_label`,
`record_param_spread_other_type`.

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
types make a union (decision 8 §3.2). A jump arm and a `void` arm contribute nothing; in a `case`
used as a value, an arm that answers nothing beside arms that answer a value is `case-arm-no-value`
(§ Blocks).

**An arm body is a lambda BODY, not a lambda value** (decision 8 §5.1 P3). `Pattern { body }` lands
as the same lambda node the older block arm produced, so `caseArmValueType` reads it as one: a
top-level `break <value>` names the arm's value and wins, and otherwise the body's **tail** — its
last expression written without `;` (decision 525) — is the value (a jump tail contributes nothing,
§3.2). Before this only the `break` half
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
typed as its tail (decision 525), which the parser wrapped in the block's `break`, `void` without
one.

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
  value exports; `import {Parser as P}` binds `P` as a checker-local alias of it (decision 110,
decisions-pending 129 point 4 reversed by the maintainer).
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
name the module does not declare is found among the types it IMPORTS: `registerExports`
(`addImportedTypeScope`) records each imported type, and the imported-type scope of the module it
came from, in the module's type-decl map under `"\x00" ++ name` — a key no import item can spell, so
nothing is re-exported — and the closure reads it there (onze F2: `Canvas(outlines: Array<Outline>)`
where `Outline` and its `Point` live in two other modules of the package). A std type leaf the module
imports (`import {collections.Dict} from "std"`) is recorded there too, so `RouteMatch(params:
Dict<…>)` imported from another package gives its importer `Dict`'s methods — a method chain on the
field (`found.params.at(k).unwrapOr("")`) used to lower as a bare `unwrapOr/2` on erlang. A name
found in neither is left to the ordinary unknown-type diagnostic. Cells:
`conformance/modules/import_type_closure`,
`conformance/modules/import_type_closure_across_modules`,
`conformance/modules/narrowed_optional_std_field_across_packages`. An imported FUNCTION brings the
types its signature names the same way (`registerImportedSignatureClosure`, from the module that
exports it): `import {matchPath}` alone gives `?RouteMatch`'s fields and methods to the value it
returns, through a narrowing or an optional binder. A package handle's template (`import shelf from "shelf"`, `shelf "x"`)
brings its signature's types the same way (144 B-68; cell `conformance/modules/template_answer_method`): the call's value
is the library's `Label`, so `built.size.toString()` resolves. The constructor and variant bindings a type-only
registration takes back are kept in `Env.typeOnlyCtors`, out of scope, because a generic type's
field instantiation reads its registration cells from them (`instantiateFieldType`).

## `/` over integers is integer division (onze F7)

`inferBinaryOpExpr` records every arithmetic operator (`+` `-` `*` `/` `%`; `inferUnaryOpExpr` a unary
`-`, the `assign` arm a `+=` under its binding's loc) in `env.divisions` (loc → result type). Once
inference is done, `comptime.zig` turns each resolved one into `InstanceLowering.division` (an
`env.ArithKind`: the integer type, or `.float`; `infer.arithKind` — nothing for a string `+`), never
over another lowering at the same loc. The integer kinds drive decision 264's range check on every
backend (`codegen/AGENTS.md` § Integer overflow); for `/` the backends read: commonJS
writes `Math.trunc(a / b)` for an integer one, erlang and beam take `div` / `'/'` from it before their
own operand heuristics, wasm's typed `i32.div_s` already truncated. A `/` whose type never resolved (a
generic `T`) records nothing. A number literal with an exponent is a float (`isFloatLiteralText`:
`5e-324`, `1e3`; `0x1E` stays an integer) — it was typed `i32`. Cells:
`conformance/modules/integer_division_truncates`, `conformance/modules/float_literal_spellings`.

## `any` is deleted (1.0.5 decision 31, C-18)

`Env.registerBuiltins` no longer binds `any`, and `resolveTypeRefInContext` refuses a written `any`
— in any type position: a parameter, a return, a field, a `val` annotation, a type argument, an
alias target — as `any-type-removed` (`diagnostics.any_type_removed`), located at the annotation,
naming `unknown`. `any` was a closed type no botopink value inhabited: `val a: any = 1` read
"expected any, got i32", and a host parameter typed `any` refused every botopink value
(`erlang.element(1, t)`). The host vocabularies (`std/erlang`, `std/beam`), the opaque handles
(`io.net`'s sockets, `regex.Regex`) and the libraries write `unknown`, which takes any value and is
tested with `is` before it is used as another type (`modules/any_type_removed`,
`modules/host_unknown_parameter`). A generic parameter, a type or an alias NAMED `any` is not refused.

## Every type error is located (C-21)

`tests/located_errors.zig` walks every `conformance/modules/*` through `comptime.compile` and
requires each type error to carry a `loc`; the harness helpers (`assertTypeErrorSnap`,
`assertComptimeAstExpecting`, `typeErrorMessage`, the decorator helper) require the same of every
unit test's error. Two raisers were unlocated and are located now: a decorator argument of the wrong
kind (`checkDecoratorArgs` — at the annotation, through `decoratorError`) and `@comptimeError()`
with no message (at the call). A site that stamps a location conditionally (`if (a.loc) |l|`,
`env.typeRefLoc`) stays conditional: the location is absent only for a synthesized annotation or a
type the compiler resolves with no annotation in front of it.

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
— except a name the module declares a `type` of, read in its own declaration before it is
registered (`type Element(children: Element[])` beside the prelude's unit variant
`DeclKind.Element`; cell `modules/type_named_like_decl_kind`) —
or the value (a module `val`), since neither carries its annotation's location. The location is added
after the fact by `locateTypeRefError`, not through `typeRefLoc`, which would also enter every
unresolved local annotation into C10's pending list. Cells: `infer_errors.zig` `type position: …`.

## A behavior-typed parameter or field accepts an implementer (01 R4)

An argument meets its parameter through `unifyArgument`: a parameter — or a record constructor's
field — whose type is a behavior accepts a value whose type `implement`s it, directly or through the
behavior's `extends` chain (`behaviorReaches`), and everything else goes to `unifyAt`. The same
`behaviorCoercion` already served `return` of an implementer from a `-> Behavior` fn. The coercion is
target-first and only widens (implementer → behavior); a record that does not implement the behavior
reds at the value. Cells: `infer_errors.zig` `behavior-typed field …`. Whether a type implements a
behavior is one answer, `typeImplementsBehavior` (its own clause or a behavior reaching the target
through `extends`), which `createContext(value, B)`'s check (416 (2)) asks too
(`conformance/modules/context_behavior_implemented_indirectly`). An extension block (`Sym implement B
for T`) makes no `T` a `B` value: it dispatches statically, and no backend dispatches a behavior call on
a `T` to it.

## One type of a name per module, and a std namespace yields to it (decision 170)

Types are nominal by name in the checker, so one module holds one type of a name.
`noteExplicitTypeNames` (both program entries, before any import is marked) collects the names this
module declares (`type`, a type alias, `behavior`) or imports by name from a module that is not std
(the item's leaf — `import {kit.store.Dict as OwnDict}` names `Dict`) into `Env.explicitTypeNames`,
and refuses a second SOURCE of one type name — a `type Dict(…)` beside `import {collections.Dict as
D} from "std"`, a type of this module beside an aliased import of a same-named type (question
B-23-a) — as `import-name-collision` at the second import item, naming both (each used to resolve
silently to whichever registered last; `modules/own_type_beside_std_type_import`). Two FUNCTIONS of
one name under two aliases stay legal: a function is bound by its local name.

**Decision 310 — two imported types of one declared name are two types.** `comptime.zig`
`contestedTypeNames` finds the declared names two type import items of the module resolve to in
two different modules — a std leaf (`collections.Dict [as D]`) counts and keeps its declared name,
so only the other module's aliased item is renamed (a name the module declares itself is left out:
B-23-a's case stays refused); `resolveImports` registers each ALIASED item of such a name under its alias
(`Env.renamedTypeImports`, `infer.registerRenamedImportedType` → `type_identity.zig` `renameDecl`:
the declaration named the alias, printed as declared, its own name in its signatures renamed), binds
no checker alias, and renames the types of every value it imports from another module
(`infer.renameImportedType`: a type the owner names that is a renamed import's declaration —
the owner's own, or one it imported, matched through the `"\x00"` scope — is spelled by the alias;
the same rename applies to a module namespace's call (`inferCallExpr`'s namespace branch, a
namespace-qualified type read by `metaReadType`), a template's hygiene binding (`applyDslHygiene`) and
`written_names.bindValue`, and `memberRenames` names a decorator member's type by the alias this
module holds it under, `written_names.renamedAliasOf`, before any hygiene import).
`noteExplicitTypeNames` notes such an item under its alias, so `import {a.p.Policy as APolicy};
import {b.p.Policy as BPolicy};` (or one of the two un-aliased) is legal; two un-aliased items stay
`import-name-collision` (170). The alias stays in the transformed program (it is not in
`importedTypeAliases`), and each backend maps it back to the declared name in the declaring module:
erlang and beam key the type by the alias and spell its atoms by the declared name
(`type_declared`), beam reads the alias's link-index entry (`aliased_type_exports`), wasm's
`linkTypeRenames` maps the alias to the linked declaration, commonJS binds the class under the alias
(`const {Policy: APolicy} = require(…)`). Cells: `modules/import_two_types_one_name`,
`import_two_enums_one_name`, `import_same_type_name_two_packages_one_aliased`.

A source is the DECLARATION an item resolved to, not its spelling: `resolveImports` (`comptime.zig`)
records each non-std type item's declared name and declaring module path in
`Env.importedTypeDecls`, by the local name it binds, and two items that resolved to one module path
are one source — `import {catalog.Widget} from "kit";` beside the `import {Widget as __bp_ti_0}
from "kit/catalog";` a `@TypeInfo.all` answer adds (C1: refused as `kit:catalog` vs `kit/catalog`).
The refusal still names each source as spelled. The same declaration reached a second time is not
registered again (`registerImportedTypeDecl` would rebind its constructor, and an alias bound to
the first one would stop naming the type — the erlang answer's thunk called `make` on an unbound
`__bp_ti_<n>`). Cell: `modules/typeinfo_all_type_also_imported`, all four targets.

A std module **namespace** (`import {collections}`) registers its `pub` types bare only where
`explicitTypeNames` does not hold the name (`markStdImports`): the declaration the module named wins
over the one the namespace brings along implicitly, and the skipped type is noted in
`Env.shadowedStdTypes`. A call through that namespace whose signature names the shadowed type
(`collections.lt()` answering std's `Order` in a module with its own `type Order`) is refused at
the call as `ambiguous-import-use` (`refuseShadowedStdSignature`), since the checker would read
std's type as the module's (`modules/std_namespace_beside_own_type`,
`modules/std_namespace_beside_aliased_type`, `modules/std_namespace_signature_names_shadowed_type`).

## A module is its package plus its path (decisions 170, 337)

Two packages may each hold a module of one name — `emilia/theme` and `styled/theme` — and they
are two modules. `Module.package` (filled by the CLI's dependency loader, empty for the root
package) is stamped on every import of the module before any lookup reads it
(`ast.ImportDecl.withOwnPackage`, in `analyzeSource`, `analyzeMerged` and `orderReaders`), so
`ImportDecl.leafSource` answers an item with no `from` (`import {theme.make};`) as
`ImportSource.key` — the registry key of exactly that module (`emilia/theme`; `theme` in the root
package). A `.key` never widens: `namesModule` is byte equality, `inPackage` is false and every
pass of `admits` admits that one module, so neither the basename reading (`theme` naming any
`…/theme`) nor the whole-program pass reaches another package's module. An item with no path
(`import {config};`) names its module the same way (`comptime.zig` `itemSource`). The shorthand
(`import {make};`, no module) is refused (decision 337, below). `withImportSourcesNamed` hands the backends the checker's answer as a
`.key` too, so a root module `config` is never read as a dependency's `x/config`. The comptime
block runtime finds a type the block reaches (`block_eval.findType`) by module: the one the module
imports under that name, else the one module it imports from that declares it, else the one module
of the build — two answers at any step answer none (it used to compare locations, and two `Ns`
declared on the same line of two packages' `theme` were one). Cell:
`conformance/modules/two_packages_one_module_name`, four targets; unit test `infer: import
source ---- two packages' modules of one name are two modules`.

## The shorthand goes; `mod m;` binds `m` (decision 337)

`resolveImports` refuses an item with no `from` whose first segment names no module of the
package (`mod_tree.Tree.isModule` over `ownPackage` + the segment): `shorthand-import` at the
item, its fix written by `refuseShorthand` — `write import {config.splitPath};` when one module of
the package declares the name `pub` (`Tree.declarers`), every candidate when several do,
`unresolved import` when none does. The search it replaced (`outsideShorthandReach`, the bare item
read as `.root` and widened to the whole program) is deleted; `ambiguous-import-use` stays for a
`from "<pkg>"` handle alone. A name a module re-exports (`pub val splitPath = mod2.splitPath;`,
`pub type Pair = mod2.Pair;`, `Tree.reexports`) is looked up in the module that declares it and
handed to the backends through `itemOwners`, so `import {mod1.Pair}` is `mod2`'s `Pair`, one type.
`mod_namespace.zig` binds the namespace a `mod` declares and walks it (`private-module`,
`redundant-module-import`). Cells: `conformance/modules/mod_binds_namespace`,
`mod_namespace_cascade`, `mod_reexport_by_val`, `import_nested_module_namespace`,
`private_module_through_namespace`, `redundant_module_import`, `declaration_named_like_module`,
`shorthand_import_one_candidate`, `shorthand_import_several_candidates`, `modules/shorthand_import`.

## A behavior's `default fn` body is checked (another front's finding)

The typed `.behavior` arm runs `inferBehaviorDefaultBodies`: every `default fn` that carries a body
goes through `inferTypeMethods` against its own signature, `self` typed as the behavior (`Self`),
so an unbound call or a mismatch inside one is refused (`modules/behavior_default_fn_body_checked`;
nothing walked these bodies, and `inferTypeMethods`' doc named a strict pass that did not exist). A
`-> @Result` default fn records its `return` / `throw` wrappings, and `transform.zig` walks
`.behavior` default bodies with the method-body (`src_only`) aggregator, so every backend wraps
them. The `.by_value` instance lowerings a `Self`-typed receiver records inside a default body are
dropped again: the body is emitted once per implementer, which the backends dispatch statically. A
call of an adopted default on an implementer answers the member's declared return
(`adoptedDefaultCallType`, `Self` the receiver) instead of a fresh variable
(`test/behavior_default_fn_result`). A bare `Ok(…)` in a default body is now `unbound variable
'Ok'`, as in any body.

## A lambda's fallible channel is its expected return's (decision 147, lg-a)

`inferFunctionExprExpected` no longer gives a lambda body `throwContext = .unchecked`. Under an
expected `fn(…) -> @Result<U, E>` the body's channel is `.result(E)` — `returnTarget` the payload
`U`, `returnWhole` the `@Result`, so `return v` is wrapped `Ok(v)`, `throw e` `Error(e)` and `try`
propagates, and a body ending in a `return` / `throw` has the expected `@Result` as its value; under
any other expected return, or none, it is `.plain`, and a `try` / `throw` is
`effect-try-without-fallible-channel` at the keyword, the message naming the lambda's expected
return (`Env.inLambdaBody`, read by `fallibleChannelRefusal`). `inferExprTyped` keeps the
expectation for a `.function` node and `inferFunctionExpr` reads it only when it is a fallible
function type, so a lambda passed to a `fn(x: T) -> @Result<U, E>` parameter takes the channel; it
clears the expectation before the body. A `case` arm's block body (`keepReturnTarget`) is not a
lambda for this: it keeps the enclosing channel, so its `throw` is the function's (row 29 —
`return case v { … _ -> { throw "x"; } }` answers `Error("x")` on commonJS, wasm and beam; erlang
lowers the arm's throw as a raw `throw`, its backend's row). Cells: `modules/try_in_lambda_without_result`,
`modules/lambda_result_return_try`.

A lambda written in `return` position (`return { n -> … };`) takes its parameters from the
function type the enclosing fn or method declares (`inferJumpExpr` reads `returnWhole`, which a
method sets, before `returnTarget`, which only a fn sets), through `inferFunctionExprExpected`, as a
`val f: fn(…) -> R = { … }` does: `n.toString()` in the body resolves against `i32` and records
its instance lowering (a backend without native method dispatch refused the call otherwise);
conformance cell `task_lambda_method_to_string`.

A lambda written where no type is expected (an unannotated `val`; `inferFunctionExpr` sets
`Env.lambdaWithoutExpected`) records each parameter's fresh variable in `Env.freeLambdaParams`; a
lambda a parameter receives is typed by it, a free type parameter of the callee included. A method call whose receiver is still a free variable when checked
(`val f = { n -> n.toString() }; f(2)`: `n` is `i32` only once `f(2)` is) is typed by a fresh
variable and kept in `Env.pendingReceiverCalls`; `resolvePendingReceiverCalls` (once the module's
bodies and the `.hooks` readers ran, before `checkPendingTypeNames`) answers each with the receiver's
type now known — the instance lowering, the commonJS rename and the primitive method's return type,
or `unknown-method` — so wasm, erlang and beam lower it as commonJS dispatches it. A lambda
parameter still free there is refused at the call, "cannot infer the type of `n`" (decision 328);
a receiver that is no lambda parameter stays permissive. Cells
`modules/lambda_param_typed_by_later_call`, `modules/lambda_param_untyped_method_refused`,
`modules/lambda_arg_generic_param_method`.

Because the lambda now UNIFIES its return with the expectation, the expectation a plain call reads
(`declParamTypes` in `inferCallExpr`) is a fresh instance of the callee's signature —
`instantiateCtorType` then `instantiateGenericType`, as the arm that types the call does — never the
registration-time cells: inside a generic type's own methods, `Schema(run: { … })` answering
`Schema<?T>` bound the constructor's `T` and the next `Schema(…)` (`Schema<Array<T>>`) was
"expected ?_[], got ?_" (`validation`'s `schemas.bp`). Cell: `modules/generic_ctor_fallible_lambda_fresh`.

## A lambda writes a captured `var` only in two shapes (decision 148, lg-b)

`Env.lambdaDepth` counts the lambda bodies around the expression (a `case` arm's block is not one),
and `Env.localDepth` records, for every local a body binds (`bind` / `bindVal` with a body scope
open), the depth and the type it was bound to — so a module-level binding, or a name whose current
binding is another one, is never matched. An assignment to a local bound at a shallower depth is
`captured-var-write` at the write (`refuseCapturedVarWrite`, on every target: on the BEAM a closure
gets a copy of what it captures), unless the lambda is one of the two shapes the site that infers it
marks through `Env.nextLambdaExempt` → `Env.captureWriteOk`: a `forEach` body (an array receiver,
or one whose type is still open) and a local closure (`val f = { … }`) whose every later use in its
block is a call at statement position, also inside an `if`, a loop or a `forEach` body
(`noteStatementClosures`, `onlyStatementCalls`, `usesName` — `ast.exprMentions` counts any lambda as
a use). A counter shared across calls is a module-level `var`
(`modules/captured_var_write_in_lambda`, `modules/closure_capture_statement_position`).

## The occurs check is named as the mismatch it is

`unifyAt` turns `unify.zig`'s occurs-check failure (`recursiveType`) into `type mismatch: expected
`T`, got `?T` — the second holds the first`, spelling a generic fn's type parameter by name
(`genericSpelling` over `Env.fnGenericMap`) — `return xs[0];` under `fn first<T>(xs: T[]) -> T`
answered `recursive type detected`, which named neither (an index is `?T`, decision 63;
`modules/generic_index_answers_optional`, `modules/generic_index_optional_return`). A declared type
parameter is still a flexible variable inside its body: `fn f<T>(x: T) -> T { return 1; }` checks as
`fn(i32) -> i32` and reds only at a call with another type.

The other direction is the widening a concrete type already had: an expected `?T` takes a value of
the variable `T` it wraps (`unify.zig`'s `.named` arm, an unbound variable that occurs in the
optional's argument unifies with the argument, not with the optional) — `fn some<T>(v: T) -> ?T {
return v; }` checks, and a `?T` returned where `T` is expected stays the mismatch
(`modules/generic_value_widens_to_optional`, `modules/generic_optional_never_narrows`).

## A program's primitive behavior extends std's

A program's own `behavior` named like one std registered — a primitive's controller interface
(`behavior String { default fn … }`) or any other — EXTENDS std's: `extendStdBehavior`
(`registerInterfaceAssociatedFns`) puts std's declaration with the program's members added (and the
`extends` joined) under the one name in `Env.assocInterfaceDecls`, so every reader of that table —
the checker's dispatch and the backends' — sees both; `Env.stdBehaviorBase` keeps std's original, so
a second registration of the program's decl merges against std's members only. A member std's
declaration already has is `behavior-member-redeclared` at the program's member. `comptime.zig`
`withUsedAssocInterfaces` emits the merged declaration in place of the program's (std's own default
fns, `slice`'s default fill included, would be missing otherwise). A primitive behavior's default
bodies type `self` as the primitive (`primitiveOfInterface`: `String` → `string`, `Array<T>` →
`array<T>`), and `transform.zig` walks a behavior's default bodies whichever rewrite map is set
(`self.slice(1)`'s fill). Cells: `test/program_primitive_behavior_extends_std`,
`modules/program_primitive_behavior_redeclares_std`.

## An inline parameter type (decision 207)

`fn link(props: type(href: string, label: string = "x"))` — the parser keeps the fields on
`Param.inlineFields` (typeRef `ast.inline_type_name`); `inline_types.expand` declares the record
`BpInline__link__props` before the fn (PascalCase: beam reads a constructor call by its first
letter), points the parameter at it, and rewrites each call of the same module whose labels name
fields of the inline type (and no parameter) into `link(props: BpInline__link__props(…))`, the
constructor call at a synthetic column past any written one (`inline_types.locatedAtCall` takes it
off a diagnostic again). Everything after that is an ordinary record. The checker's rules:
`refuseInlineParamRules` (one inline parameter per fn; no field named like another parameter, each
`inline-type-position` at the type), `refuseInlineFieldsAcrossModules` (a call from another module
that writes the fields — the type is not exported), `Env.resolveTypeName` (an inline type the pass
did not declare: a method's, a behavior member's or a host declaration's parameter), and a left-out
field without a default named at the call (`missing field `label` of the props of `link``).
`error.zig` `namedByOwner` spells every `BpInline__f__p` in a message as ``the p of `f` ``,
and `assocTypesShown` every hoisted associated type `Owner__Name` as `Owner.Name` (144 B-19).

## A record value is not callable (`language-gaps.md` row 32)

A plain call `g(…)` whose callee is a binding of a **record, enum or primitive** type — a value,
not a function and not a constructor — is `callee-not-a-function` at the call (`refuseCallOfValue`,
the `.named` arm of the free-call switch), naming the value's type and, for a record, the field read
the author likely meant (`g.a`). It used to answer the value's own type, so `val g = G(a: "x");
g().a` checked and the backends failed at run time (`g is not a function`, `{badfun, …}`). A name
that is the type itself (a constructor reached by its own name), a function-typed field
(`h.f(2)`, a method-call path) and an imported `pub val` alike follow the rule
(`modules/call_of_record_value`, `modules/call_of_imported_record_value`).

## A name is bound once where it stands in its function (decisions 152, 205)

`refuseRedeclaredBindings` walks a function's body once before it is inferred (a fn, a method, a
`test`, a behavior's default fn, and a lambda — another function — on its own when it is inferred),
with the parameters as the first bindings: a `val` / `var` / destructured name, an `if` binder, a
loop binder or a `case` arm's binder that reuses a name an enclosing block of the same function (or
a parameter) already bound is `binding-redeclared` at the second binding, naming the first (its
`line:col`, or "as a parameter") — in every block and every `case` arm, a `case` arm's block body
included (it is not a lambda). A sibling block's bindings end with it (`walkNestedBlock`), so two `if`
branches may each bind `n`; the strictest reading of decision 205 (any name bound anywhere earlier
in the function) is not applied — measured, it refuses 1 674 sites of `libs/std` and the libraries,
and the reading is the maintainer's to confirm. erlang rebound a reused name (`N@k`), commonJS refused
to load (`already declared`), and the backends miscompiled an inner shadow
(`modules/binding_redeclared_in_body`, `modules/binding_shadows_parameter`,
`modules/binding_shadows_in_inner_block`, `modules/case_arm_binder_reuses_name`).

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

`val Circle(r) = s;`, `val Person(name, age) = p;`, `val Pair(Circle(r), n) = p;` and
`val [..rest] = xs;` bind through `bindDestructPattern`, which asks `destructCovers` whether the
pattern matches every value and then runs the `case` arm walk (`bindPatternNamesForSubject`) typed by
the subject, leaving the names in the enclosing scope — as `val`s unless the binding is `var`. The
spread-only list binds through the same walk (it was admitted and bound nothing: `unbound variable
'rest'`, 144 B-22 step 13).

**The failure behaviour is decided: a pattern that can fail does not check.** The bare form has no
failure path of its own, so it is accepted only where the pattern matches every value of the
subject's type: the one variant of a one-variant `type`, a record's own constructor (all binders, or
fewer with `..`), a list pattern that is only a spread — and a constructor's argument may be such a
constructor in turn (`val Pair(Circle(r), n) = p;`, `destructCovers` recursing over each field's
type). Anything else — a variant of a many-variant
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
reference (`type Outer(inner: Inner)` above `type Inner(…)`) therefore checks. A generic application's head name
(`Bogus<i32, i32>`) is recorded the same way by `resolveTypeRefInContext`'s `.generic` arm
(`Env.notePendingTypeName`) and refused with the bare name's text; a dotted or mangled (`Type__Field`) head, a
builtin `@Name`, `Self`, `Array` and a type parameter in scope are not recorded. A `val`/`var` annotation
carries its own `typeLoc` (144 B-111), but a body's type parameters are not in the generic map, so a name cannot
enter the pending list: `resolveAnnotationAt` looks every written name up at once (`refuseUnknownTypeName`, the bare
name and a generic application's head, through `typeNameDeclared`) and refuses `unknown type` at the annotation; any
other refusal in the annotation stays at the value. A type method body's parameters (the owner's and the
method's) are in `Env.methodGenericMap`, which only this lookup reads. So do an imported
typedef (the constructor binding) and a `behavior` name in type position
(`Env.assocInterfaceDecls`). The list is cleared per program: `registerStdlib` infers one std module
per call on one env, and a name left pending by one must not red in the next.

**A std module may import another** (`import {encoding.percentEncode} from "std"` in
`querystring`). `registerStdlib` infers the std modules in `stdModuleOrder` — each after the std
modules it imports (`stdImportsOf`, a lexical scan of its `from "std"` items) — and hands each
scratch env the exports, types and functions of those already registered, so the import resolves as
a program's does; `expandStdImports` embeds the std modules a needed std module imports, transitively,
in the same order.

Only an annotation the parser located enters the list. `Env.typeRefLoc` is set by
`resolveParamType` / `resolveFieldType` / `resolveReturnType` (infer.zig) from `Param.typeLoc`,
`Field.typeLoc` and `FnDecl`/`BehaviorMethod`'s `returnTypeLoc`; a resolution with none in scope is a
synthesised or re-entered one (a generic parameter resolved outside the context that binds it) and
stays permissive. Two names are compiler-known without a declaration and never red:
`Children` (coerced by `childrenCoercion`) and `Binding` (what `compiler.lookup` yields, the `ref` field of
the registered `CustomNode`). `noreturn` is a registered primitive (`Env.registerBuiltins`), the
declared return of `@panic` / `todo` / `trap`.

**Not covered yet**: a top-level bodyless `declare fn` parses as a `DelegateDecl`, whose signature is
never resolved — an unknown type in one is still accepted. A non-type *value* binding in annotation
position (`val n = 5; val x: n = 7;`) also still checks; it is
[types-as-values A1](../../../../../../specs/1.0.4-beta/06-checker/types-as-values.md)'s, which replaces the
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
clause names **and this program declares** — or reads ambient (decision 539 (6), below) —, every method the behavior declares with no body must be
provided. A `default fn` carries its own body, so implementing it is optional. Provided means either
a member of the type's own body that has a body (`typeDeclProvidesMethod` — a `declare fn` member is
an abstract slot typed from its signature and provides nothing), or a member of some
`implement <Behavior> for <this type>` block in the same program, unqualified or qualified with that
behavior (`separateImplementProvides`); writing both halves is legal and the inline clause is what
names the contract.

**Ambient behaviors (decision 539 (6), 144 B-96, B-107).** Every `pub behavior` of `builtins.d.bp` that
no compiler rule reads is ambient — a program writes it with no import (`comptime.zig`
`isAmbientBehavior`): `Display`, `Closeable`, `Index<K, V>` and `Slice<V>` today. The ones a rule
reads by name are `rule_read_behaviors` (the effect wrappers `Task`, `Iterator`, `Stream`,
`Component`; the reflection carriers `__Expr`, `__Decl`; the markers `Annotation`, `Renderable`,
`Decorator`), and a unit test fails when the derived set changes or the list names a behavior the
file no longer declares. `registerBuiltinDecls` keeps their declarations in `Env.ambientBehaviorDecls` (cloned into every
module's env and every std module's). `validateProgram` checks an `implement` of one, inline or in a
block, as a behavior of the program's own, unless the program declares or imports its own of the name;
`checkPendingTypeNames` takes the name as a type (`fn f(c: Closeable)`, `fn f(m: Index<i32, i32>)`), and
`Env.behaviorDecl` (own, else imported, else ambient unless a type of the name is in scope —
`type Index(column: string)`) is what every behavior lookup of `infer.zig` reads, so a call on such a
value is `InstanceLowering.by_value`. Never emitted. An imported behavior stays unchecked in both forms
— its members are not visible here.

## A type-qualified call to a type's own method (decision 62)

`Counter.zero()` — a call to an **associated** fn of a registered type, through the type — came back
a fresh type variable. The signature was already there: `registerInherentMethodTypes` stores every
method of a `type` under `inherentMethodTypes[<type>][<method>]` with `Self` resolved to the type,
associated ones included. Nothing read it for the type-qualified form, only for
`recv.method(args)` (`methodCallReturnType`).

`associatedCallReturnType` reads it, instantiated fresh per call site so the type's shared generic
cells never collapse across two calls. Unlike the instance form there is no receiver to unify `self`
against: every declared parameter lines up with an argument. A labelled or short call is planned as a
std module's fn is (`planQualifiedCall`: the labels reordered, a missing parameter filled from its
default); any other count is the arity error at the call — it used to fall through to a fallback that
checked nothing, so `Bag.of("p", "q")` against one parameter compiled
(`modules/associated_fn_too_many_arguments`, `modules/associated_fn_missing_argument`,
`modules/associated_fn_of_type_default`).

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
`conformance/modules/loop_item_method`, which asserts the VALUE.

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
read exactly where it threw on the call. §A4's per-call prototype rename (`primMethodNodeRename`,
`String.contains` ⇒ `includes`) unwraps the same layer, so `s?.contains("x")` over a `?string` is
`s?.includes("x")` (`…?.contains is not a function`, exit 1, before;
`modules/optional_method_absent_receiver`).

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

A numeric leaf stands alone (`language-gaps.md` row 22, 1.0.11-beta `01-checker` step 3): the parser
reads `.50` as a `dotIdent` named `50`, and `inferIdentifierExpr` looks it up under the mangled
`__50` — by the position's expected section only (`expectedEnumDeclaring`), never through the flat
table; with nothing expected it is `sectionOwningLeaf`'s refusal naming the section, as an identifier
leaf is. A qualified variant constructor (`Tok.Size(percent: .100, …)`) infers its arguments under
the variant's field types (`env.variantCtors` / `env.ctorParams` under `Enum.Variant`, labels
honoured), so a payload variant may declare a section-typed field and take a leading-dot leaf. A
`.50` **pattern** is not built (the pattern grammar and the backends' match on the mangled name are
not this row); compare with `==` or read through a function.

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
an identifier chain, an array literal, a leading-dot call and a generic type's
constructor called with no type arguments (`isUnappliedGenericCtorCall`: the
expectation pins its parameters as written type arguments do —
`val t: Sort<Book> = Sort(by: .title)` is `Sort<Book>(by: .title)`, so a field key
resolves; `inferCallExprWith` reads it once and clears it before the arguments),
and the sites that know a position's
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
for an argument whose parameter is not knowable. A complete labelled call has
no fill to invert, and there a label still names its parameter: the slot is the
parameter of that name (`Event(name: "a", ts: 0)` reads `ts: i64` at its second
argument, whatever order the labels come in — an integer literal read no
expectation there and stayed `i32`; `conformance/modules/integer_literal_labelled_field`).
`calleeParams` is read once, above the argument loop, and the arity arm's
default fill reads that same list.

**ES5** — when two enums carry the path and the expectation says nothing,
`raiseAmbiguousSectionPath` refuses at the head segment, naming every candidate
(sorted, because the set comes off a hash map). It is not a pick: the candidates
are different types, the program means one of them, and picking is the defect
this closed. ES4 (a head that matched, a tail that did not) collects EVERY enum
whose head segment is a section wrapper: one is blamed by name, several are
narrowed by the position's expected type (`expectedEnumAmong`), and with no
expectation the refusal names them all, sorted (`no enum has the path … — "A"
and "B" each have a section …`) — it used to blame the first the iterator met
(`modules/section_path_es4_expected_enum`, `modules/section_path_es4_every_head`).
The refusal's hint names the fully qualified spelling, which is the way out of
an ambiguity a position cannot type.

Tuple labels (decision 8 §6) ride the same map: a `tuple` type carries
`named.labels` (from a written `#(name: T, …)` type — `ast.TypeRef.labeledTuple`
— or, T1, from the plain variables a `#(…)` literal is built from; `unify` never
compares them). `row.label` on a labeled tuple resolves the element type and puts
`row._N` into `env.enumSectionRewrites` under the access loc, so every backend
sees a positional access; an unknown or ambiguous label is a located error naming
the positional form. **T7** is a warning (decision 57's channel): `unifyAt` compares, before it
unifies, a labeled written tuple type with a value whose labels came from the variables it was
built from (T1), and a position whose two labels differ warns "the variable `city` fills the
element labeled `name`" (`warnTupleLabelMismatch`) — the written label wins (T3). A labeled
CONSTRUCTION (`#(x: 1, y: 2)`) stays the parser's `tuple-literal-label` refusal: T1 says
construction has no labels.

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

## A variadic parameter (decision 267)

`inferCallExpr` (now `inferCallExprWith`, which takes a receiver already typed)
asks `variadicCalleeParams` whether the callee's last parameter is variadic — a
plain call by name (`calleeParams`: the module's `fn`s, imported ones, std's),
a method or an associated function by its receiver's type
(`Env.getInherentMethodParams`, `self` dropped; a receiver naming a type reads
that type). If so, `packVariadicCall` refuses a spread argument
(`variadic-spread`), a label on a variadic argument or a trailing lambda
(`variadic-label`) and a call short of a fixed argument (`'f' expects at least
N argument(s)`), packs the arguments past the fixed ones into one array literal
at the call's loc, marks the call `variadicPacked`, records it in
`Env.indexRewrites` and re-enters with it — the arguments are then typed
against `T[]` as any array argument (each element against `T`, located at the
element). `transform.zig` splices the packed call over the program's (the
index channel's `variadicPacked` arm), so erlang, beam and wasm read one list /
array argument; commonJS writes it back as a rest call (`codegen/AGENTS.md`).
Cells: `modules/variadic_parameter`, `modules/variadic_parameter_host`,
`modules/variadic_spread_at_call`, `modules/variadic_label`.

## `Dict.bump` on a non-integer `V` (decision 534)

`inferCallExprWith` refuses `d.bump(k, by)` on a receiver typed `Dict<K, V>` whose `V` is a concrete
type that is not an integer (`isIntType`; an unresolved type variable passes), located at the method
name: "`Dict.bump` counts integers alone — the values of this `Dict` are a `f64`". The keyed-var write
(`checkKeyedWrite`) keeps its own message for a `keyed: true` var. Cell: `modules/dict_bump_non_integer`.

## `defer` (decision 539)

A deferred statement is inferred as a path of its own (`enterDefer` / `leaveDefer`, the three sites that infer a
statement list: `inferBodyStmts`, `inferStmtsTyped` and a method body): `Env.deferActive` with the nesting it began
at (`deferLambdaDepth`, `deferAsyncDepth`, `deferGeneratorDepth`, `deferLabelFloor`), `loopDepth` and `breakScope` reset,
so a nested function, `async` block or generator loop — other paths — is not "the body" (`inDeferBody`).
`refuseInDefer`, the first thing `inferJumpExpr` does in the body, refuses what would leave the path the deferred code
runs on, located at the jump: `defer-return`, `defer-break` / `defer-continue` (only when the jump leaves the body: a loop
wholly inside it may break, a label naming a loop outside it is refused), `defer-yield` and `defer-await`. `throw` and a
propagating `try` are not refused (decision 539 (5) names neither), and the deferred value is discarded, never checked:
no `Closeable` rule exists (539 (6)). `Stmt.deferred` is copied onto the typed statement. Cells
`defer_refuses_return` / `_break` / `_continue` / `_yield` / `_await`.
