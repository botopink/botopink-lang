# compiler-core/src/codegen/wat

> Path: `modules/compiler-core/src/codegen/wat/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The WebAssembly-text code model and the emitter that renders it. `../wat.zig`
lowers botopink into these nodes and writes **no target text at all**; every
byte of `.wat` comes out of `wat_emitter.zig`. Same split as the Erlang side
(`../beam/erl_ast.zig` + `erl_emitter.zig`), for the same reason: when the
backend prints, nothing owns the shape of an instruction, and the bugs are
text bugs.

## Tree

```text
wat/
├── AGENTS.md         ← you are here
├── wat_ast.zig       ← the code model (`Module`/`Item`/`Func`/`Seq`/`Instr`) + `Builder` + the invariants
├── wat_emitter.zig   ← the only text writer: s-expressions, indentation, `$` names, data escaping
├── wasm_binary_emitter.zig ← the same model in the binary format (what an engine instantiates)
├── browser_loader.zig ← decision 334: the `browser` host's loader (`<module>.mjs`) beside the binary; drives the host tasks from the event loop (394)
├── host_binding.zig  ← decisions 238, 440: what `#[@external(.Wasm("…"))]` names — `op:` / `fn:` / `wasi:` / `std:`, the opcode table, the adapter list
├── reach.zig         ← decision 518 (2): the functions a lowered module reaches (call graph from exports, start, the table once a `call_indirect` is reached, task starts)
├── needs.zig         ← decision 518: the `botopink.needs` custom section read back (binary, text) and the `wasmtime run` flags it asks for
├── std_wasm_link.zig ← decision 440 (2): std-wasm's program face (`std_wasm.wasm`) decoded into the model, linked into the program
├── runtime_unit.zig  ← decisions 1021 (2), 1026: the runtime core `std@__rt` (memory, heap, allocator, the panic tag, the WASI imports) and std's units `std@<path>`, cut from std-wasm, which a program imports
├── wat_reader.zig    ← front 164 s3: a `.wat` text read into the model — the compiler's own s-expression reader, no tool; type names resolved against the codegen's (549), a located error for a text that does not read
├── std_leaves.zig    ← front 164 s3: std-wasm's `.wat` leaves (`modules/std-wasm/wat/`, embedded), found by name, read into the GC module that calls one
├── scope_carry.zig   ← decision 504: each module's render-scope values typed by the checker's type the scope lowering carries
├── repr.zig          ← front 164 s2: `Repr` — what a lowered value is (a scalar, or a reference and its kind) — and `Mode` (`.linear` / `.gc`)
├── typecheck.zig     ← front 164 s2: the operand-stack type check a GC module passes before it is kept
├── engine.zig        ← decisions 1032, 1034 (R0): the embedded wasmtime engine, one per process (exceptions, GC, component model, parallel compilation, epoch interruption; `incrementEpoch` for SIGINT / a watchdog), and `precompiled(cache_dir, bytes, kind, cold)` — `.wat` or binary → compiled code through `<dir>/<sha256(tag ‖ wasmtime version ‖ settings ‖ bytes)>.cwasm`, staged `<path>.<rand>.tmp` then renamed (`writeAtomic`); comptime's `persistent_wat.zig` has its own engine until 1033
├── runner.zig        ← decisions 1032, 1034 (R0): `run` a component whose core units the linker defines by name (`instance_add_module`), WASI p2, `wasi:cli/run@0.2.0`'s `run`; `Outcome{status, stdout?, trap?}` (exit status from `wasmtime_error_exit_status`, a trap is `wasm trap: <message>`, status 1); holds the import-name probe test
└── wat_prelude.zig   ← the runtime helpers (`$__print_i32`, `$__str_concat`, …) as built nodes
```

## What the model makes unrepresentable

The wave before this one had to repair five defects in the emitted text. The
model exists so none of them can be written again:

| Defect | Why it cannot be expressed |
|---|---|
| `(local …)` in the middle of a body | There is no local-declaration instruction. Locals are `Func.locals`, and the emitter writes them between the signature and the first instruction — the only place WAT accepts them. |
| A value left on the stack | Every `Seq` carries the `Stack` it leaves (`none` / `value: ValType` / `terminated`). `Builder.func` and `validateModule` reject a body whose stack disagrees with the declared `(result …)`, and the same check runs on every `if` arm. |
| `(param $ i32)` | `Param.name` is checked non-empty by `Builder.param` (and again by `validateFunc`). An unnamed parameter cannot be constructed. |
| `call $undefined` | `validateModule` walks every `call` against the module's own functions and its imports, before a byte is written — there is no extern category, so a symbol nothing defines cannot be called. A **runtime helper** is stronger still: `Builder.helper` is the only way to obtain its symbol, and it marks the helper's group for emission in the same act — "called" and "defined" are one operation. |
| A specialised fn with no result type | The same check as "a value left on the stack": a body whose stack is `.value` cannot go into a `Func` with `result == null`. |

## WasmGC in the model (front 164 s2, decision 544)

The model carries WasmGC: a module's GC types are one `Item.types` (at most one, before anything naming
them), in index order, split into `(rec …)` groups where a `TypeDef` `opens_group` (`groupEnd`; a type names
only types of its own group or an earlier one, which `validateModule` checks), a value type may be an abstract
reference or `ValType.def(k)` — the nullable `(ref null $t)` of the module's `k`-th type —, and the GC instructions address types by that index (`struct_new`,
`struct_get`, `array_new_data`, `ref_cast`, … — the `Instr` row above). Both emitters render them and
`validateModule` checks every index; `wasm_binary_emitter.gc_test_module` is the module both emitters'
tests render, the bytes and the text `wasmtime run -W gc=y --invoke f` answers `9` for. A module that
declares GC types needs `gc` (§ Exceptions and needs).

**The lowering in two modes** (front 164 s2). `../wat.zig` carries every value's representation as a
`repr.Repr` — `i32` / `i64` / `f64` / `bool`, or `ref(kind)` (`str`, `arr`, `tuple`, `record`, `enum_`,
`closure`, `task`, `cell`, `unknown`, `bytes`, `bigint`) — in its locals, globals, function signatures,
captures and cells (`wasmTypeOf` answers one for an expression, `watType` for a written type), and
`Emitter.mode` turns it into a declaration's value type (`vtOf`): in `.linear` every reference and every
`bool` is the `i32` word; in `.gc` a string is `(ref null $str)`, `$str` being `(array (mut i8))`, the
first type of the module's group (`wat_prelude.gc_str_def`). `emitWat` lowers each module in `.gc` first
and, when that lowering refuses — it meets a value shape with no GC form yet (`Emitter.gcGap`,
`error.GcFallback`: an address of a value, a linear-memory instruction in a function it wrote, a helper
group with no GC form, a value crossing into std-wasm that the marshal has no form for), or the module it
built does not pass `typecheck.zig` — lowers it again in `.linear`, which answers for the module (its
refusals are the module's). A linear module renders byte for byte as before the two modes existed.

What `.gc` lowers today (front 164 s2 P1, P2): scalars, booleans and strings — a string literal is a passive
segment `$__d<k>` built once, at instantiation, into the global `$__s<k>` (`emitStrLit`; the start function
`$__init_strs` builds them, then calls `$__init_globals` when the module has one), `+` and templates
(`$__str_concat`, a hole's text through std-wasm or `text_capture`), `==` (`$__str_eq`), `@print`, a
`case` over strings or answering one, string parameters, results, locals and globals (a `comptime` string
`val` too), an `@panic` / `assert` message (`$__panic_fail` over a GC string), std-wasm's string
functions through the marshal (`emitStdCall`, below) — and, from P2, the shapes that were words in linear
memory:

| Value | In a GC module |
|---|---|
| a record | one struct type per declaration, `rec_<Name>`, a typed field per declared field (an `f64` / `i64` field is the number itself, no cell); `lowerRecordCtor` is `struct.new`, a read `struct.get`, `recv.f = v` `struct.set`; a method's `self` is the record |
| a generic record or enum (P2b) | still one struct type per declaration (never per instantiation): each field or payload that names a type parameter is erased (`gcErasedRepr`) — `T` and `?T` an `anyref`, `T[]` / `Array<T>` an `arr_any`, `#(K, V)` a tuple; the constructor boxes a scalar argument by its print shape (`gcGenericArg`: an `i32` in `box_i32`, a `bool` in `box_bool`, a reference as it is, an array literal of words or floats boxed into an `arr_any` by `$__arr_box_<class>`), and refuses a value whose text the slot would not print as linear memory does (a float, an all-unit enum's ordinal, a `u64`, a container of bools); a read where the receiver's type arguments are known (`Box<i32>`'s `b.value`, a `case` binder by `tparamArgOf`) unboxes or casts to them; the printer prints a type parameter's slot by what it holds (`U`); a type parameter's value in a generic body is an `anyref` (`registerFn` / `registerInterfaceSigs` type a signature under its parameters), `==` over two of them `$__unk_eq`, and a call that binds a generic `fn`'s or method's type parameters calls a copy written in its arguments' types whatever they bind (`specializeFor` / `specializeMethod`, which linear memory makes for a string, a bool or a float only; a tuple argument binds its tuple type, `eqBindParam`, decision 568); a generic record's own `display` is not called by its printer (linear memory refuses that call, `refuseUnboundTemplateCalls`); writing a type parameter's field (`recv.f = v`, P3) boxes the value as a constructor's argument does, and `==` over a generic record or enum compares each erased slot at the type its arguments name — the written ones (`Pair<i32, string>`, an array literal's `Box<i32[]>`: `eqTypeOf`, `ctorTypeRef`), or, when no type argument is written (`Pair(left: 1, right: "x") == …`), by the structural `$__unk_eq` (`gcEqErasedSlot`, decision 569; `gcEqFunc`, `eqFieldType`, P3); a generic method of a type with no type parameter (`MathOps.first<T>`) is specialised as a generic type's is (`generic_methods`, P3) |
| an enum with payloads | the value is an `anyref`; each variant is its own struct type `var_<Enum>_<Variant>` (a unit variant of such an enum a struct with no field), the tag test `ref.test` (null is none), a payload read `ref.cast` and `struct.get` (`gcLoadPayload`); an all-unit enum stays its `i32` ordinal |
| an array | `arr_i32` / `arr_f64` / `arr_any` by the class of its elements (`Repr.Elem`): a word or a bool, a float, anything else — a reference, or a scalar in its box; `push` copies (`$__arr_push_<class>`), `xs[i]` / `at` / `first` read through `$__arr_at_<class>` / `$__arr_at_opt_<class>` (a negative index counts from the end, out of range is the neutral value / null) |
| a tuple | `tuple`, `(sub final $arr_any (array (mut anyref)))` — a subtype of `arr_any` of its own (decision 568; `GcTy.tuple`, `$arr_any` declared open only in a module that holds one), so every reader of an `arr_any` reads it and `ref.test $tuple` tells it from an array; built by `array.new_fixed $tuple` (`gcTupleLit`, `zip`'s pairs), every scalar element boxed (`box_i32` for an `i32` and a `bool`, `box_f64`, `box_i64`), `t._N` the element unboxed by the tuple's declared type or its print shape; a local, a parameter or a field of a tuple type is declared `arr_any` |
| `?T` | `T` a reference: the nullable reference itself; `T` a scalar: an `anyref` holding its box, null for absent (`gcOptPayload` / `gcOptRepr` from `OptInfo`); `null` into such a slot is `ref.null`, a scalar into it is boxed by `lowerBoxedInto`; `if (o) { v -> … }`, `a ?? b`, `x!`, `== null` test `ref.is_null` |
| `@Result<A, E>` | `result`, a struct of a tag (0 = Ok, 1 = Error) and an `anyref` payload; `case`, `try`, `unwrapOr`, `isOk` / `isError` read it |
| `unknown` (P2b) | an `anyref`: a reference as it is (a string, an array, a tuple, a record, a variant), a scalar in its box — `box_i32`, `box_f64`, `box_bool`, the last a subtype of `box_i32` (`TypeDef.super`), so a reader of a word takes either and `ref.test $box_bool` tells a bool (`gcAsUnknown`, `lowerAsUnknown`'s GC form; a `case` / `if` into it boxes arm by arm, its value an `anyref`); `is` a primitive by value (`$__unk_int_in`, `$__unk_is_num`, `ref.test`), the narrowed / arm binder its payload (`$__unk_as_i32`, `$__unk_as_f64`, a cast), `==` `$__unk_eq` (numbers by value, strings by content, bools by value, else by structure — `$__unk_eq_ref`, decision 569: both absent or the same reference, else a tuple, an array, a record, a variant, a `@Result` or a boxed `i64` of one type part by part, a word by `i32.eq`, a float by `$__f64_eq`, a reference by `$__unk_eq`, through one `$__unk_eq_<arr|tuple>` / `$__unk_eq_s<k>` per type; written after the lowering over the module's types, `gcUnkEqRef`; a function value or a task equal only to itself), `@print` `$__unk_print_raw`, and the `U` shape (a union array's element, a type parameter's slot) `$__unk_print_q`, a string quoted. A function value (P3, `gcAsUnknown`) is its `closure` as it is, cast back by `emitConvert`; `Bytes` has none yet. A float goes into a generic slot in `box_f64`, an array of words, floats or strings (a static `[i` / `[f` / `[s` shape) as it is, printed by `$__print_arrs` (`gcArrsPrinter`, written after the lowering over the array types the module holds); a tuple as it is, tested first and printed `#(…)` by `$__print_tuple` (each element by `U`), when every element of its print shape prints by its box (`gcGenericArg`; a bool, an all-unit enum's ordinal or a `u64` element keeps the module in linear memory). A record's `unknown` field prints by `U` (`gcDeclPrinter`) and is read as the `anyref` it is (`gcIsUnknownRepr`) |
| a function value (P3) | `closure`, the open struct `{idx, mark}` (`idx` the lambda's slot in the function table, `mark` a component's, decision 504), and per lifted lambda `n` its subtype `env<n> {idx, mark, c0, c1, …}` — one mutable typed field per capture, copied when the value is made (`gcClosureNew`). A lambda is two functions: `$__lambda<n>__b(env, a0, …)`, typed like any function (the environment as its own struct, each parameter the repr of the declared function type or of the argument a call through its local passed, the answer the declared one or the one the body gives), and `$__lambda<n>(closure, anyref…) -> anyref`, the table's entry, which casts the closure to its environment, unboxes each argument by the body's parameter repr, calls the body and boxes the answer (`gcEmitLifted`). So `call_indirect` carries one type per arity (`gcClosureSig`) and a call site (`gcValueCall`) needs only the declared function type of its callee: arguments boxed (`gcBox`), the answer unboxed (`gcUnbox`) by `gcSigRepr`. A capture a lambda assigns (`var`) is a field the body writes in place (`writeBackCapture`), and a call through a known closure local copies the captured locals into the environment before and out of it after (`gcSyncCaptures`), as linear memory does with the closure cell. A top-level `fn` named as a value is a trampoline of the same shape over its signature (`gcFnRefWrapper`); a lambda written against a declared function type (an annotation, a field, an argument, a typed `fn(x: i32) -> i32 { … }`) takes its parameter and answer types from it (`expected_fn`, `Lifted.param_ft` / `ret_ft`); an untyped fn expression called where it is written (`(fn(s) { return s + "x"; })("a")`) is typed by its arguments as a closure local's call types it — its lambda is the one lowered with the callee (`gcValueCall`), and its answer a string when its body is, a `return` counted (`inlineCallIsString`, `bodyIsString`); conformance cell `fn_expression_string_parameter` |
| a component (P3) | a `@Component<T>` written anywhere is the `fn(unknown) -> unknown` lambda `scope_carry.zig` makes it; a run (`bpScopeRaw__run<n>(c, scope)`) is `gcRun`: the closure called with the scope as an `unknown` through `call_indirect`, its answer converted to the type the wrapper declares. The scope's wrappers (`push`, `find`, `rendered`, `valueOf`) are ordinary GC functions: a value crosses the scope in its box, not as the bare word linear memory passes (the `isWrapper` word and cell passing is off in `.gc`). A body that cannot return (`@panic`, std's `use context(…)` stubs) leaves the stack polymorphic (`renderBody`); a component whose body awaits is a state machine (P4, decision 504): its closure's `mark` is `1`, and a run reads the mark — a marked lambda's answer is its `$task`, awaited where the run is awaited inside a machine (`emitSuspension` with the mark, the answer an `anyref` cast to `$task` only when marked), run to its end elsewhere (`$__task_block_on`) |
| a task (P4) | `$task`, a struct of its state, its waiters (`$waiter`, a list), its value (an `anyref`: a scalar in its box, a reference as it is — shared, never copied), its frame (a `structref`, the machine's `$frame<n>`), its `kind`, its ready-queue link and a combinator's two words; a host task pending is a `$hostn` node; § `@Async` as a state machine |
| a union array (P2b) | an `arr_any` whose elements are each `unknown` (`gcArrayLit`), printed `[U` |
| `Dict<K, V>` (P2b) | std's own `type Dict<K, V>(pairs: Array<#(K, V)>)`: a generic record, so its struct is `rec_Dict` with one `arr_any` field of tuples, each key and value boxed by the tuple; its methods are std's bodies (insertion order kept by `pairs`), lowered with the array walks below |
| `==` | `$__eq_<T>` by the type's parts (`gcEqFunc`): a record by fields, an enum by variant then payload, an array / tuple by elements, an optional by presence then payload, a float by `$__f64_eq` |
| `@print` | a printer function per shape (`i b f l u s T E…`, `[X`, `(XY…)`, `?X` / `!X`, `R<ok><err>`: `gcPrinter`) and per record / variant declaration (`gcDeclPrinter`, a record's `display` first), written into the module; a nested record or enum value is printed by `$__print_tagged_raw(anyref)`, a chain of `ref.test` over the module's declared types (`gcTaggedPrinter`) |

The array walks with a closure written at the call (`map`, `filter`, `forEach`, `all`, `any`, `count`,
`findIndex`, `fold`; P2b) inline the closure's body into a loop over the GC array (`gcArrayHof`), `map`'s
answer an array of the class of what the body answers (`gcMapTail`, which `wasmTypeOf` reads too);
`r.map(f)` / `r.flatMap(f)` over a `@Result` inline `f` the same way (`gcResultMap`). An `@Iter<T>` is a
generator handle, its body a resumable state machine (§ Generators as state machines), and so is a `@AsyncIter<T>`
and a `stream` loop (144 B-142). A `try` inside a generator machine whose item is a `@Result` (decision 122) answers
the `Error` as the last item and ends the handle (`gcTryPropagate`); over any other item it is not lowered.

A `bigint` (decision 1021 (8), (10)) is its block's bytes, `[L][limbs…]`, in the string's byte array (`vtOf`
gives `.bigint` the `$str` type): a literal is a GC string global of those bytes (`lowerBigintLiteral`), and every
`bigint.*` call goes through a wrapper `$__gcstd_bigint_<fn>` (`gcStdWrapper`) that copies each block into the
marshal arena (`$__gc_to_lin_big`: `$__gc_to_lin_str`, the block past its length word) and the answer out
(`$__lin_to_gc_big`: `4 + |L|` bytes; the `opt` forms a `?bigint`'s null as `0`), so the equalities and printers
written after the functions (`gcEqValues`, the shape `n` of `gcGenShapePrinter`) call one with no locals of the
caller; `bigint.parse` answers a `$result` (`gcBigintParse`), a `?bigint` prints `null` or its digits. A `bigint`
into an `unknown` slot falls back (`emitConvert`: it would read as a string). The other GC gaps decision 1021 (10)
names are lowered too: a `catch { e -> … }` binder is the `$result`'s payload unboxed to the error's repr
(`gcBindResultErr`), `try f() catch h` into a declared `?T` answers the optional's repr (`gcTryCatchInto`), an `if`
answering `null` into a boxed optional boxes arm by arm (`gcOptIf`) and into a reference takes the other arm's repr
(`ifValueType` skips the `null` arm, `branchLastStmt` answers the null reference), `<` / `>` / `<=` / `>=` over two
strings is `$__str_cmp`'s sign (the `str_cmp` group, GC only), a `case` arm that assigns runs as a statement
(`lowerArmBodyStmts`), and a `case` whose arms all answer one scalar in a function answering a reference answers
that scalar (`gcCaseScalarArms`). Every other value is a word in
linear memory (`alloc`, the bump heap, exhaustion a trap — decision 448 (4)). The module's types are built once the module is lowered, in groups that depend only on declarations
(decision 1021 (9), `gcBuildTypes`): (i) the **prelude group**, `gc_prelude_defs`, emitted whole in every module that
names a GC type at fixed indices (`GcPrelude`: `$str`, `$arr_i32`/`$arr_f64`/`$arr_any` (open), `$tuple`,
`$box_i32` (open)/`$box_i64`/`$box_f64`/`$box_bool`, `$closure`, `$result`, `$exn`, `$task`, `$waiter`, `$hostn`,
`$gen`, `$cell`; the closure call signatures are function types after the groups, structural); (ii) one group per
strongly connected component of the **declared** types — records and payload-enum variants, an edge a field naming
another (an array, an optional, a tuple, a `Result` erase to prelude types, a type parameter's slot to `anyref`) —,
members ordered by their declared name `<pkg>@<path>.<Type>` (`gc_type_keys`, set by `gcKeyTypes` from the module that
declares it, unmangled; a spliced record is `std@builtin.<Type>`), the groups in that order with each after the ones
it names, every field typed from the declaration (`gcBuildDefs`), each group closed by its **brand** (`gcBrandDef`: a
struct no code names whose 32 fields spell a hash of the members' declared names, two bits a field — two groups
written alike are one type, so without it `Person(name, age)` and `Vec(name, age)`, or two variants of one shape,
would be one type and `is` / a `case` could not tell them apart); (iii) the module's **private** types — lambda
environments, state-machine frames, an enum's box, an anonymous record, a declared type naming one of them — in one
group after, in the lowering's order. The lowering numbers types as it asks for them (`gc_types`, a type's fields may
ask for more); `gcBuildTypes` answers the renumbering (`gc_perm`) and `finishGc` applies it to every item through
`gcRemapItem`. Two modules naming one declared type carry byte-identical prelude and shared groups (`tests/wat.zig`,
`decision 1021 (9)`).
`reprOf` is `watType` for a written type with the references added in a GC module (`memberRepr` for a
method's parameters and answer), `gcReprOfExpr` the same for an expression `wasmTypeOf` took for a word.
A record the compiler splices (`comptime.spliced_record_names`: `Asset`, `SourceLocation`, `Declared`, `DeclaredMeta`,
`DeclaredTypedMeta`) that a module only NAMES — a dependency's `pathOf(a: Asset)` reading `a.path`, `show(all:
Declared<unknown>[])` reading `d.name` — is no declaration of it: `spliceNamedRecords` adds the source (`declared_decl_src`,
`source_location_decl_src`, `asset_decl_src`) to the declarations, before `pruneUnreached`, when a declaration's strings name
one of its types and no declaration holds any, so the read finds the record's slot as in the module that spliced it
(144 B-95, B-97; `conformance/modules/{embed,declared}_field_read_other_module`, on all four targets). An array of a
generic record (`Declared<unknown>[]`) gives its lambda parameter the record (`elemRecordOfTypeRef`).
The GC pass lowers only the declarations the module can reach by name (`pruneUnreached`): a linked module
brings all of its own, and one without a GC form sent a module that never named it to linear memory. A
function a linked declaration brought that still touches linear memory (std's `Dict.fold`, over a closure)
and that nothing reaches (`reach.zig`, no export) is a stub that traps (`finishGc`, `gc_linked_fns`); one of
the module's own, or a reached one, sends the module to linear memory (P2b). The
linear pass links everything, as it always did, unless the whole lowering refused the module: its retry
lowers what is reached (`Plan.reached_only`, decision 531, below).
Shapes that sent a module to linear memory and are lowered in GC form (164 s2): an `if` one of whose arms is
an empty array literal takes the other arm's type (`ifValueType`; `emptyArrayArmOther` notes the local's array,
in both lowerings); a `case` whose arms are literals of one type answers that type where the enclosing
function answers the other kind (`gcCaseArmsType`); `try r` answers the `Ok` type of `r`'s `Result`
(`gcReprOfExpr`, `typeRefOf`); a primitive's method is never the module's free function of its name
(`resultShapeOf`: `actual.contains(needle)` beside `fn contains(…) -> Result<…>`); `xs.fill(v)` is an array of
`v`'s class (`gcArrayOp`, `array.new`); `recv?.m(args)` over an optional record or enum
(`gcOptionalTypedMethod`); `Self` in an enum's method is its `$enum_<owner>` (`emitMemberFn` sets
`sig_owner`); `indexOf`, `lastIndexOf` and `contains` over an array of class `any` whose elements are no
strings (a type-parameter slot, std's `asserts.includes`) compare a number, a string or a bool by value and any
other reference by identity (`$__unk_same`, `__arr_indexOfEq_any`), as the linear lowering's word compare
and commonJS do; `r.unwrapOr(d)` answers the reference the `Result`'s `Ok` type or the default names
(`gcReprOfExpr`); a lambda written in a generic function keeps its type parameters (`Lifted.fn_tparams`,
`owner_tparams`, set by `gcEmitLifted`), and an argument against a parameter typed by a type parameter out of
scope (the function value `compose<A, B, C>` answers) crosses boxed in its own repr (`gcValueCall`); `o ?? d`
over an optional array is an array (`isArrayExpr`, `printShapeOf` by the optional's declared payload) and its
empty `[]` default takes the branch's array type (`branchLastStmt`); a `[]` element of a tuple returned against
its declared `#(…)` takes its slot's type (`expected_tuple`, `gcTupleLit`); a value whose GC repr is a string
prints as one (`lowerPrintArg`: `f()._1`) — `conformance/modules/nullish/cells/nullish_default_optional_array`, whose wasm
answers were addresses before. Measured by building every conformance unit for wasm with `gc_debug` on; the test
`wat: gc ---- an empty array arm, a case of its own type, …` and the ones after it pin them.

**std-wasm across the boundary** (decision 544's answer 4, until front 164 s3): std-wasm reads and writes
linear memory, so `emitStdCall` marshals a GC module's call — each string or `Bytes` argument copied into the
marshal arena (`$__gc_to_lin_str`, the `std_marshal` group, through `$__alloc`), a `string[]` as std-wasm's
`[n][s0][s1]…` (`$__gc_to_lin_strs`, written into the module by `gcMarshalStrs` — the helpers that touch
linear memory are the one place a GC module's own text does, `gc_marshal_funcs`), an `?string` / `?Bytes` as
its string or `0`, an `?i32` as its 4-byte box or `0`; the answer copied out the other way
(`$__lin_to_gc_str`, `$__lin_to_gc_strs`, …); and `$__heap_ptr` put back after the call, so nothing
std-wasm allocated outlives it (std-wasm never calls back). `gcStdSig` is the signature a call is marshalled
by (a `std:` export's own, or the program face's), `GcStd` the types that have a marshal; an array's words
(`array.*`) have none, and a `bigint`'s go through `gcStdWrapper` (above) — the array operations a GC module needs are its own functions
(`gcArrOp`: `slice`, `reverse`, `concat`, `prepend`, `fill`, `indexOf`, `lastIndexOf`, `join`; P2b:
`$__arr_unique_<class>` — std-wasm's three equalities, a word, a float by its bits, a string by content —,
`$__arr_flatten_<class>`, `$__arr_chunked_<class>` / `$__arr_sliding_<class>` by std-wasm's counts and
`slice`), and a
`std:` host-binding wrapper (`emitHostBinding`) marshals its call the same way. The I/O stays linear: a GC
string is written by copying it into the arena (`$__print_str_raw`'s GC form), a float's text is std-wasm's
in the arena, put back after.

## Files

| File | Role |
|---|---|
| `reach.zig` | `reached(alloc, items, edges)` — the names of the functions reachable from an exported function, the start function and (once a reached function holds a `call_indirect`) every table entry; `$__task_resume`'s calls to the task steps are no edge, a task-starting function reaching its step is (`Edge`, `Emitter.task_edges`). `dropCallers(arena, items, gone)` — removes the named functions and, repeatedly, every function calling one that went (the caller promises none is reachable); a table keeps its indexes (a gone entry becomes `$__bp_dead`, which traps) and the task dispatcher drops the arm of a gone step. |
| `needs.zig` | Decision 518: `section` (`botopink.needs`), `needsOf(binary)`, `needsOfText(text)` — the needs a module names, one per line (a component's every section, the runtime unit's too) —, and `wasmtimeArgs(needs)` (`-W exceptions=y`, `-S http`, `-W gc=y`; at most `max_args` flags); `codegen.wasmNeeds` for the CLI (§ Exceptions and needs). |
| `repr.zig` | Front 164 s2: `Repr` (`i32`/`i64`/`f64`/`bool`/`ref: Kind` — `str`, `arr`, `tuple`, `record`, `enum_`, `closure`, `task`, `cell`, `unknown`, `bytes`, `bigint`, `result`; `num` — the scalar class an opcode is spelled with, a `bool` and a reference the `i32` word —, `isFloat`/`isI64`/`isWord`/`isRef`/`isStr`/`isArrRef`/`eql`/`name`; `Repr.string`) and `Mode` (`linear`/`gc`), § WasmGC in the model. |
| `typecheck.zig` | Front 164 s2: `checkModule(alloc, module, skip, *Diag)` — every function not `skip`ped walked with an operand stack and its control frames: each instruction pops its operands' types (a GC reference by subtyping: `def(k)` under `eqref`/`anyref` and `arrayref`/`structref` by its kind, and under its declared supertypes, `subtype`) and pushes its answer; a branch, `return`, `throw` or `unreachable` leaves the polymorphic stack; a `try_table`'s catches are checked against the labels they branch to (the tag's values, front 164 s2 P4); an instruction it does not type (an operator outside its table) is `Unsupported`. `wat.zig` runs it over a GC module (std-wasm's decoded functions skipped) and lowers a module that fails in linear memory. |
| `wat_ast.zig` | **Types**: `ValType` (`i32`/`i64`/`f32`/`f64`, with `parse` for the backend's spelled type names; WasmGC's — § WasmGC in the model — the packed storage types `i8`/`i16`, the abstract references `anyref`/`eqref`/`i31ref`/`structref`/`arrayref`/`funcref`/`externref`, and `def(k)`, the nullable `(ref null $t)` of the module's `k`-th GC type, `defIndex`/`isRef`/`isPacked`/`heapText`; a non-exhaustive `enum(u16)`, so `==` compares two types), **GC types**: `TypeDef` (a name and a `struct` of `Field`s or an `array` of one; `super`, an earlier type it is a subtype of, `final`, and `opens_group`, a type that starts a new `(rec …)` group (`groupEnd`) — `(sub [final] [$super] …)`, the binary's `0x50` / `0x4F`), `Field` (name, storage type, `mutable`), `FieldRef` / `Ext`, `Stack` (`none`/`value`/`terminated`, with `fits(?ValType)`), `Width` (`full`/`byte`/`half`/`word` — `…8_u` / `…16_u` / `…32_u` on a load, `…8` / `…16` / `…32` on a store; the narrower two are decoded std-wasm code's), `MemArg` (`ty`, `width`, `signed` — a narrow load's `_s` —, `offset`). **Instructions**: `Instr` (`const` with the numeral as spelled, `local_get`/`local_set`/`local_tee`, `global_get`/`global_set`, `op` = `<ty>.<name>`, `convert` (a fully-spelled conversion opcode), `load`/`store`, `call`, `call_indirect` (an inline `FuncType`), `br`/`br_if`, `br_table` (labels + default), `drop`, `select`, `return`, `unreachable`, `memory_copy`, `memory_fill`, `if` (an optional `label`, which decoded code branches to), `block` (`block` or `loop`), `comment`; WasmGC's `struct_new`/`struct_new_default`/`struct_get`/`struct_set`, `array_new`/`array_new_default`/`array_new_fixed`/`array_new_data`/`array_get`/`array_set`/`array_len`/`array_copy`/`array_fill`, `ref_null`/`ref_is_null`/`ref_eq`/`ref_as_non_null`/`ref_test`/`ref_cast`/`ref_i31`/`i31_get`, every type an index into the module's group). **Layout**: `Line` (instruction + `indent` + trailing `;; comment` + `folded`), `Seq` (lines + stack), `If.Arm.Layout` (`block` vs one-line `inline_`). **Forms**: `Param`, `Local`, `Func` (name, exports, params, result, `locals` as *lines* so a helper can group several, body), `Global`, `FuncType`/`Import`, `ImportFrom` (decision 1021 (2): an optional `import` on a `Memory`, a `Global` — no initialiser, and it precedes every defined global — and a `Tag`, which also takes `exports`), `Memory` (`min_pages`, an optional `max_pages` — the tests' cap on a heap that exhausts it), `DataSegment` (offset + length prefix + raw bytes; a `null` prefix is a raw segment — std-wasm's data; a `passive` name makes it a passive segment, `(data $name "…")`, the bytes an `array.new_data` reads), `Item` (types — the module's GC types in their `(rec …)` groups, `typesOf(m)` — /import/memory/start/table/data/global/func/comment — `table` is `(table funcref (elem $f …))`, each name checked against the module's functions), `Module` (items). **Invariants**: `Invalid`, `validateFunc`, `validateModule` (also every GC type index, struct field and passive segment an instruction or a value type names — `UndefinedType`, `UndefinedData` — and no packed type outside a field, `PackedValue`; a supertype an earlier, open type; a field naming only its own group or an earlier one), `declaresCall`, `declaresData`. **Helpers**: `Helper` (every symbol is `__<tag>`; `group`), `HelperGroup` (`deps` — the groups a group's functions call into), `HelperSet` (an `EnumSet`; `require` closes over `deps`). **`Builder`**: arena + `seq`/`param`/`localLines`/`func` (which validates) + `helper`. |
| `wat_emitter.zig` | `renderModule` (validates, then `(module …)`; there is no bare-form entry point; each GC group as `(rec (type $t (struct (field $f …) …)) …)`, a `(ref null $t)` spelled by its type's name, a reference global initialised `(ref.null …)`, a passive segment `(data $name "…")`). `renderComponent(alloc, w, Module)` (decision 334, § The `wasi` host's component): the module embedded as `(core module $main …)` — its `(start …)` dropped and the start function exported `__bp_init` — inside the fixed frame `component_imports` / `component_adapter_*` / `component_run_export` (the preview 2 imports, the preview 1 shim, scratch and adapter modules, the table fixup, `wasi:cli/run`), and before it, when the module imports `std@__rt`, the runtime unit as `(core module $rt …)`, instantiated first (§ The runtime core and std's units); `renderItemsOf(w, Module)` a module's items with no `(module …)` around them; a `wasi_snapshot_preview1` import outside `preview1_adapted` (`fd_write`, `random_get`) is `UnadaptedPreview1Import`, which `wat.zig` refuses located. A name after `$` goes through `id` (decision 561): one holding a backtick identifier has each byte that is no WAT `idchar`, and `\` itself, written `\` and two hex digits (`` $`add\20one` ``), any other name as it is. Owns: the two-space item column, the four-space body column and each construct's arm columns, `$`-prefixing, folded (`(call $main)`) vs flat form, inline `(then i32.const 0 return)` arms, `offset=` suppressed when zero, and the data-segment escaping (four little-endian length bytes as `\xx`, then `\n`/`"`/`\`/`\t`/`\r`/`\xx` for control bytes). |
| `wasm_binary_emitter.zig` | `encodeModule(alloc, Module) → []u8`: the binary format of the module the text emitter renders — validated first (`validateModule`), then sections type · import (the functions, then — decision 1021 (2) — an imported memory, the imported globals and tags, each first in its index space) · function · table · memory · tag (13, decision 518) · global · export (a tag's too) · start · element · data count (12, when a segment is passive) · code · data · the module's custom sections (`botopink.needs`), LEB128, the GC types first, one `rec` group each (`0x4E` and its size; the running index over the groups is the type index, `Encoder.defs`), then one type per distinct signature (imports' and functions' types first, then the tags', then each `call_indirect`'s), a `(ref null $t)` written `0x63` and the index (`valTypeInto`), a GC instruction `0xFB` and its opcode, locals as runs of one type; `throw` as `0x08` and `try_table` as `0x1F` with its `catch` clauses (§ Exceptions and needs); `memory.size` / `memory.grow` as `0x3F 0x00` / `0x40 0x00` (decision 261, a test pins the bytes). Every name the text spells is resolved to an index — functions (imports first, then definitions, in item order), globals, locals (params then declared), branch labels (depth, every `if` counted) — and a name that resolves to nothing (`UnknownName`), an operator the MVP table (`opcodes`: numeric, conversions, sign extension, `trunc_sat`) does not know (`UnknownOp`) or a numeral that does not parse (`BadNumeral`, the text format's spellings: sign, `0x`, `_`, `inf`/`nan`) is an error, never a guess. `wat.zig`'s `emitWat` renders both from one `Module` (`GenerateResult.js` the text, `.wasm` the binary); `codegen/runtime.zig`'s `executeWat` runs the **binary**, so every wasm RUN LOG is the binary emitter's answer checked against the recorded fixture. The browser build's page instantiates the same bytes. `opcodes` is public for `std_wasm_link.zig`, which decodes by the same table. `Encoder` (with `typeIndex`/`funcIndex`/`funcBody`), `Bytes`, `section`, `uleb`/`sleb`, `name`, `valType`, `funcType` and `constInstr` are public for `comptime/runtime/wat/link.zig`, which pre-seeds an `Encoder` with a prebuilt module's index spaces and encodes a lowered comptime program's functions against the merged numbering. |
| `host_binding.zig` | **Decision 238's closed vocabulary**, pure (text and value types in, a `Binding` or a message out): `parse(alloc, text, Signature)` reads the binding text the parser makes of each labelled cell (decision 481, `ast.translateExternalCells`: `op: "f64.floor"` → `op:f64.floor`) — `op:` against `findOp`'s table (the MVP numeric instructions by shape — integer `clz`/`ctz`/`popcnt`/`eqz`, the binary ops, the comparisons; float `abs`/`neg`/`ceil`/`floor`/`trunc`/`nearest`/`sqrt`, `add`…`copysign`, the comparisons; the conversions — no memory, control, local or global instruction) and checks the declared parameter and return types are exactly the opcode's (a comparison or `eqz` answers `bool`); splits `fn:` (the module resolves it); reads `wasi:` against `adapters` (`.RandomF64` names `random_f64`; the task adapters `.Delay`, `.Race`, `.RaceOf`, `.SpawnAll`, checked by `Shape` over one type parameter — decision 393; `.Attempt`, `fn() -> T` → `@Result<T, string>`, the shapes `thunk_t` / `result_t` — decision 518); `.CaptureOpen` / `.CaptureClose`, `() -> string` / `(string) -> string`, a `run()`'s capture over `text_capture`'s `$__cap_begin` / `$__cap_end` — decision 989 (1), the `string` slot; `.Target`, `() -> string`, whose wrapper is the literal `wasm` — std's `io.os.target()`, decision 989 (7)); reads `std:` against `std_wasm.exports` (decision 440 (3): `Binding.std_`, its types checked by the caller — `wat.zig` with `std_wasm.matches`, the checker on every target). `signatureOf(alloc, f)` is the `Signature` a `declare fn` writes (the numeric slots, `self` skipped, `@Async<T>` read as `T`; the shapes over one type parameter) — the one reading `wat.zig` `checkHostBinding` and the checker's `infer.refuseWasmSignature` (every target) both pass to `parse`. `instrOf` gives an `op:`'s instruction. Anything else is a `Refused` message, naming the cell as written (`ast.wasmCellDisplay`). `codegen/tests/wat.zig` holds `adapters` and `conformance/docs.md` § Host bindings' table to each other |
| `wat_prelude.zig` | The runtime helpers decision 442 (1) keeps, as `Func` nodes — what defines a value's representation or talks to the host, and nothing that only computes over values (§ What stays in `wat_prelude`): `print` (`$__write_bytes`, `$__print_nl`, `$__print_sp`, `$__print_i32`, `$__print_i32_raw`, `$__memmove`), `print_str` (`$__print_str_raw` traps on a pointer below the data floor — decision 67, § below), `print_bool`, `print_f64` (the I/O; the text is std-wasm's `number.floatToString`), `arr_at`, `str_concat`, `str_eq` (transcribed line by line), then — one helper per group, built with the comptime constructors at the bottom of the file (`func`, `loop`, `when`, `whenElse`, `get`/`set`/`op`/…; `func` assigns each line the column its nesting puts it at) — `alloc` (bump, 4-byte aligned: the program's one heap, std-wasm's too), `i32_abs`/`i32_min`/`i32_max`, `arr_new`, `arr_push`, `print_arr_i32`, `print_arr_f64` (+`_raw`, each slot's cell), `box_i32`, `arr_at_box`, `print_opt` (`$__print_null` — the bytes of `null`, decision 47's one spelling of absent, through scratch `176..180` — and `$__print_opt_i32`/`_bool`/`_str` +`_raw`), `assert_fail` (`$__write_err` — `fd_write` to fd 2 — and `$__assert_fail`, its literal text through scratch `188..208`), `panic_raise` / `wasi_attempt` (decision 518's exception helpers, § Exceptions and needs), `print_shaped` (`$__print_quoted_raw` — a nested string, quoted with the source escapes — and `$__print_shaped_raw(v, shape, go)`, which walks a shape string — `i`/`f`/`b`/`s`, `l`/`u` (an `i64` / `u64` cell; `print_shaped` requires `print_i64` and `print_u64`), `[X`, `(XY…)`, `?X` / `!X`, `R<ok><err>` (a `@Result`'s `{ tag, payload }` pair, written `Ok(x)` / `Error(y)` by the shape of its side; `typeRefShape` builds it from a declared `@Result<A, B>`, `printShapeOf` from an expression `resultShapeOf` knows) — writing `[a, b]` / `#(a, b)` and answering the address past the shape; `go = 0` only measures), `print_opt_tagged` (`$__print_opt_tagged` +`_raw` — a `?T` whose `T` is a record: `null` for `0`, `$__print_tagged_raw` otherwise; its own group, because the tagged printer reads a header four bytes behind the value and absence has to be answered before it is called), `display_of` (`$__display_of(v)` answering `0` — the `Display` hook `$__print_tagged_raw` calls first, which `wat.zig` replaces with the module's dispatch, § below), `unknown`, `print_unknown`; decision 238's adapter `wasi_random_f64` (`$__wasi_random_f64`, with `random_get_import` — 8 bytes into scratch `208..216` —, the host's entropy, which std-wasm's `random.seededFloat` also draws before any seed, decision 451 (2)); decision 392's scheduler (`task`, `task_resume`, `task_poll`, `task_host`, `task_delay`, `task_race`, `task_race_of`, `task_spawn_all`, with `task_host_poll_wasi`, `bp_ready` and the `bp_host_*` imports — § `@Async` as a state machine); and § Numbers' groups: `box_f64`, `print_i64` (the I/O of std-wasm's `number.i64Text`), `box_i64`, `print_opt_i64`, `int_chk` (`$__i32_add_chk` … `$__i64_mul_chk`), `i32_range_chk` / `i64_range_chk` (decision 264's narrower types, groups of their own), and decision 319's `print_u64` (`number.u64Text`), `u64_chk`, `print_opt_u64`; decision 332's `bigint` — no function: the marker of a module that prints a `bigint` in a container, which substitutes `print_shaped_items_bigint` (the shaped printer with the `n` code, calling std-wasm's `bigint.toString`); `print_opt_f64` is `print_opt_f32` renamed (a `?f64` is its cell); `text_capture` (the global `$__cap`, `$__cap_begin` / `$__cap_end`; also what std's `compiler.Module` opens around a `run()`, decision 989 (1)) — a value's printed text as a string: while a capture is open, `$__write_bytes` appends to a copy of the capture string instead of calling `fd_write` (`print_items_capture`, substituted for `print` in a module holding the group), so `lowerConcatOperand` writes a template hole or a `string +` of an enum value as `@print` writes it (`isEnumValueExpr`; `conformance/modules/enum/run/src/cases/enum_value_template_hole`) — the ordinal's digits or a cell's address before —, and of every value that is no string, boolean, float, `i64` or known integer (`lowerCapturedPrint`: a record, an array, a tuple, an optional — `null` when absent, where `undefined` was written —, a `Display` type; decision 530, `conformance/modules/decisions-taken/template_hole_writes_print_text-530/run/src/cases/template_hole_prints_every_value`), where the value's address was written. A tuple's `toString()` is that capture too (`isTupleToString`, 144 B-122: the call lowers to `lowerCapturedPrint` of the receiver and `isStringExpr` knows its answer is a string). `items(group)` returns a group's forms, `order` the order a module appends them in (declaration order, so the transcribed groups keep their place), `fd_write_import` the one host import the print group needs, `gcItems(group, capture)` a group's form in a GC module (front 164 s2: its own items when it moves no string; `$__print_str`/`_raw`, `$__print_f64_raw`, `$__str_concat`, `$__str_eq`, `text_capture`'s `$__cap` and the capturing `$__write_bytes` over `(ref null $str)`, `print_shaped`'s `$__print_quoted_raw` over a GC string alone — the shape walker and the tagged printer are generated per module, § WasmGC in the model —, `panic_fail`'s `$__panic_fail` over a GC string, `display_of` none; null for a group with no GC form yet), `gcDeps` the groups a GC form adds (the marshal arena's `alloc`), `std_marshal` (`$__gc_to_lin_str`, `$__lin_to_gc_str`), `gc_str_def`/`gc_str_index`/`gc_str_ref` the `$str` type, `stdSymbol` the program symbol of a std-wasm function a helper calls (`HelperGroup.stdCalls` names each group's, so a module holding the group links them). Scratch layout below the data section (which starts at 256): `0..8` the WASI iovec, `8` the newline byte — and `9` the space of §7's `, ` separator (`putSep`), written beside it so the two bytes leave in one `fd_write` —, `16..32` the bool text, `64..128` the i32 digits. An `i64`'s and a `u64`'s text is std-wasm's workspace (`number.i64Text` / `u64Text`), a float's std-wasm's (§ std-wasm in the program). |
| `scope_carry.zig` | Decision 504 (§ Components): `carry(arena, Program) → Program` — a copy of the module's declarations that hold a written `@Component<…>` or a call of the scope lowering's functions (`needs`), with `@Component<R>` written `fn(unknown) -> unknown` (a host declaration's types stay, `isHost`), `bpScopePush__` / `bpScopeRendered__` calls renamed to one wrapper each (`bpScopeRaw__push` / `bpScopeRaw__rendered`), and each `bpScopeFind__<T>` / `bpScopeValue__<R>` / `bpMemoRead__<T>` (decision 771, `…memo<n>`) and each run `(c)(scope)` carrying `Rendered<R>` a call of a wrapper of its own (`bpScopeRaw__find<n>`, `…value<n>`, `…run<n>`) declared to answer that type, appended to the module. `push` and `rendered` keep the type they carry, and `valueArg` names the position of the value they carry in: a float or an `i64` crosses as its cell's address (§ Components). No type at all leaves the call as written. `isWrapper` names the wrappers (a mangled one too). |
| `runtime_unit.zig` | Decisions 1021 (2), 1026, § The runtime core and std's units: `get()` — the core and the units, built once per process (a spin lock over a page-allocator arena), the same bytes for every program: `Runtime.core` / `core_text` / `core_bytes`, `.end` (past std-wasm's data and stack: the program's data floor and the heap's start), `.pages`, `coreFor(arena, pages)` (the core with its memory starting with `pages`, the composition's), `.units` (each `Unit`: `name`, `file_name`, `module`, `deps`, `host_fs`, `text`, `bytes`; in dependency order), `closure(arena, names)` (the units named and what they import, in that order), `std_refs` / `leaf_refs` (each std-wasm function and each leaf: its unit, export and type), `.graph`; `failure()`; `importsOf(arena, binary)` (the `std@` modules a binary imports and its memory import's pages), `importsRuntime(binary)`; `unitName(path)` (`io/fs` → `std@io@fs`); `name`, `file_name`, the export names (`memory`, `__heap_ptr`, `__alloc`, `__bp_panic`; `std:` / `wat:`). |
| `std_wasm_link.zig` | Decision 440 (2): `link(arena, wanted, floor, *Diag) → Linked{ items, end }` — the functions of `std_wasm.wasm` (embedded, `module_bytes`) the program reaches, decoded into the model: the exports `wanted` names (`<module>.<function>`, emitted as `entryName` — `__std_number_floatToString`) and what they call, each other function `__std_f<n>`, locals `p<n>`/`l<n>`, every block, loop and `if` labelled `b<n>` (a branch to the function's own block wraps the body in `block $fn`); the stack-pointer global `$__std_sp`, the raw data segments at the first 8-aligned address at or past `floor`, the functions. `global.get $__memory_base` is the constant base, `env.bp_alloc` is `$__alloc` (`env.bp_term_alloc` and `env.bp_term_static`, the term library's, are bound to nothing: no program function reaches a term), `__stack_pointer` is `$__std_sp`, initialised to the top of a stack sized from the code (each prologue's `global.get $sp; i32.const N; i32.sub`, summed along the deepest call chain); every prologue's new pointer passes through `$__std_sp_check` (`stack_check`, emitted beside the global: the pointer, or a trap below the stack's floor — decision 447 (3)), and a read of `__stack_pointer` that is no prologue is refused; `end`, past data and stack, is where the heap starts. `env.bp_random_f64` is `$__wasi_random_f64` (`random_import`, decision 451 (2)): `Linked.random` says a linked function calls it, and `wat.zig` then holds the `wasi_random_f64` group and its `random_get` import. std-wasm's data is placed only when a function the program reaches reads `__memory_base` (a function that addresses no table, literal or `var` of std-wasm's links none of it). A start function that only zeroes `.bss` (what wasm-ld writes for a Zig `var`) is dropped — a fresh instance's memory is zero. A module that is no side module (`dylink.0`), or holds a function table, another start function, a global of its own, another import, an export not named `std:<module>.<function>`, a passive segment, a recursive call, a read of the stack pointer outside a prologue, an `f32.const` or an opcode outside the MVP and bulk memory is `error.Unsupported`, named in `Diag`. `linkModule` takes other bytes (the tests); `programExports(arena, bytes, *Diag)` every program-face export, as `wanted` names one; `decodeWhole(arena, bytes, floor, *Diag)` all of them decoded (`WholeFn`: the function, its program-face names, label, hash), with the data and the stack they share — what std's units are cut from. `Linked.funcs` lists, in the order of the functions among `items`, each one's symbol, label (`std:<module>.<function>` for an export, the symbol for a helper) and `hash` — the first 12 hex of the sha256 of its code-section entry in `std_wasm.wasm`; `emitWat` copies it into `GenerateResult.std_funcs`, and `snapshot.zig` writes each such function as the one line `;; <label> — from std_wasm.wasm (sha256 <hash>)` with its body omitted (decision 446) — the snapshot's rendering only: the emitter, `botopink build --target wasm` and the binary the RUN LOG runs keep every body. A test flips a byte inside one function and expects exactly one hash to move. |

## Consumers

- `../wat.zig` — builds every instruction, function, global and data segment as
  nodes (`Emitter.emit`/`emitC`/`emitAt`/`note`/`item`, `Capture` + `open`/`seal`
  for a nested body), assembles the module's item order, and calls
  `renderModule`.

## The `wasi` host's component (decision 334, front `01-compiler/140` step 3)

A wasm build is the artifact its host runs. On `wasi` (the default; `"wasm": {
"host": … }` in `botopink.json`) that is a **WASI preview 2 component**, in
text: the CLI's build sets `Config.wasm_artifact`, and `emitWat` renders its
one `Module` through `renderComponent` instead of `renderModule`
(`Artifact.component`); the binary beside it (`GenerateResult.wasm`) and every
other driver — the codegen snapshots, `codegen/runtime.zig`'s RUN LOG, the WAT
comptime runtime — keep the core module, so the snapshots record what the
backend lowers and the comptime runtime keeps the core-module subset.

The component is the module, untouched but for its start, inside a fixed
frame (under `Config.wasm_units` with the runtime unit's `$rt` ahead of it, § The runtime core and
std's units, which is then what imports `wasi_snapshot_preview1`'s `fd_write` and `random_get`; else, and
on the `browser` host, the module imports them itself); a preview 1 adapter the compiler writes serves them over
preview 2 (`wasi:cli/stdout` / `stderr` and `wasi:io/streams`'
`blocking-write-and-flush`, 4096 bytes at a time through a scratch memory of its
own; `wasi:random/random`'s `get-random-u64`). The adapter reads the module's
memory, so it is instantiated after the module, and the module's imports are
trampolines through a table the fixup fills (`$p1_shim`, `$p1_fixup`) — the
shape `wit-component` gives a preview 1 adapter. A start function would run
before that table is filled, so the start is dropped and its function
exported as `__bp_init`; the `wasi:cli/run` export calls it, then `_start`.
A trap traps the same way (`wasmtime` exits 134 with the trap message), and
every wasm cell of `conformance` runs through this frame
(`botopink run --target wasm` is `wasmtime run <flags> <file>`, the flags
those the module's `botopink.needs` section asks for — § Exceptions and needs).

**The `browser` host (step 6).** `Artifact.browser` renders the module as a host
runs it (`wat_ast.startAsExport`: the start dropped, its function exported
`__bp_init`) in both forms, and the CLI writes the binary as `<module>.wasm`
beside the `.wat` with the loader `browser_loader.zig` renders as
`<module>.mjs` — the same two preview 1 imports in JavaScript (`fd_write` on
the console, `fs.writeSync` under node; `random_get` on
`crypto.getRandomValues`), then `__bp_init` and `_start`. `botopink run` is
`node <module>.mjs`.

`wasi:clocks/monotonic-clock` and `wasi:io/poll` join the frame when the
module has host tasks (it imports `bp_host`, § below): `component_host_*` add
the two instances, a `$bp_shim` of trampolines `$main` is instantiated with, a
`$bp_scratch` memory whose `realloc` answers one fixed region (a `poll` answers
one list, copied out before the next), the `$bp_adapter` (`delay` is
`subscribe-duration`, `wait` is `poll`, `drop` the pollable's drop) and its
fixup. A module without host tasks renders the frame unchanged.
`wasi:http/outgoing-handler` joins it with `io/http`'s `fetch` (std's `02/97`
step 17). The binary emitter does not encode components: `wasmtime` runs the
text, and the `browser` host runs the core module's binary.

## Exceptions and needs (decision 518)

**A binding names the host features it needs** — `#[.Wasm(…, needs:
[.Exceptions])]`, from std's `WasmNeed { Exceptions, Http }` (the checker holds
the values, `comptime/AGENTS.md` § `needs:`). `checkHostBindings` records each
binding's `needs` (`HostBound.needs`, `ast.wasmNeedsOf`) and gathers them over
the program and the modules it links into `Emitter.needs`, then keeps only those of the bindings the program REACHES (`emitWat`: when the first pass's `reach.reached` finds fewer needs than the bindings name, a second pass runs with those needs forced and the unreached needs-bearing bindings not emitted, `Plan`; `reach.dropCallers` removes what only they were called from — a program that links `std/failure` and never calls `attempt` carries no section and runs without `-W exceptions=y`, `tests/wat.zig` pins it); the module then
carries them in the custom section `botopink.needs` (`wat_ast.Item.custom`:
`(@custom "botopink.needs" "exceptions\0a")` in the text, section 0 after the
data in the binary), one name per line, and no section when it needs none.
`needs.zig` reads it back — `needsOf` from the binary (`codegen/runtime.zig`'s
`executeWat`), `needsOfText` from a `wasi` build's component text (the CLI's
`run` and `test`, `run.wasmtimeFlags`) — and `wasmtimeArgs` hands
wasmtime only `-W exceptions=y` / `-S http` / `-W gc=y`; node runs exceptions and GC by default.
No annotation of a program turns a feature on or off (decision 67), and a
binding that forgets its need fails visibly: wasmtime refuses to parse a
`try_table` without the flag.

**`Gc`: a module declaring GC types** (WasmGC, front 164 s2, decision 544) carries `gc` whatever its
bindings name — `emitWat` adds it once the module's items hold a `types` group — and runs under `wasmtime
run -W gc=y`; node and the browser run GC by default. std's `WasmNeed` holds `Gc` too, so a binding can
name it.

**`Exceptions`: the program's aborts as a wasm exception.** When `needs` holds
`.exceptions` (`Emitter.exceptions`, known before any body is lowered), the
module declares the tag `$__bp_panic (param i32)` (`wat_prelude.panic_tag`,
`wat_ast.Item.tag`; the binary's tag section, 13), and `@panic` / `@todo`
lower to `$__panic_raise(msg, print)` (`panic_raise`): a cell `[msg, print]`
thrown — `msg` the text the program wrote, else `panic` / `not implemented` as
the other targets spell it, `print` whether an uncaught one writes it (a
`@panic` with a message, as without exceptions). `_botopink_main` runs `main`
inside a `try_table` catching the tag; what escapes is written as `@panic`
writes it (`$__panic_fail`) and traps, so an uncaught abort answers exactly
what it answered before. `$__panic_fail` writes `panic: ` (scratch `188`), the message and a newline — the line
commonJS, erlang and beam write (decision 535): `@panic`, `@todo` with a message and `assert` do on wasm
(`conformance/modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_panic`); so do an integer overflow and an integer division or remainder by zero
(decision 527 (3), § Checked integer arithmetic). The adapter `wasi: .Attempt` (`host_binding.zig`,
shapes `fn() -> T` → `@Result<T, string>`) is `$__wasi_attempt(f)`
(`wasi_attempt`): the thunk called through the table inside a `try_table`
whose `catch` branches to the block around it — a `@Result` pair, `Ok` of the
thunk's word or `Error` of the abort's message. std's `failure.attempt` /
`attemptTask` bind it through private bodies (`libs/std/AGENTS.md`). The model
has the forms it needs: `Instr.throw`, `Block.Kind.try_table` with its
`catches` (labels resolved outside the try_table, as the format reads them),
`Item.tag`, `Item.custom`; `validateModule` refuses a `throw` or a `catch`
naming no tag (`UndefinedTag`). A program that needs no exception renders
byte for byte as before.

**Checked integer arithmetic** (front 164 s2c, decision 527 (3)). Every checked helper takes its
**site** as a last argument — the message the abort writes, `integer overflow: <op> on <type> at
<file>:<line>:<col>` or `integer division by zero: …`, an interned string in linear memory (an `i32`) and a
`$str` global in a `.gc` module (`Emitter.emitCheckSite`, pushed by `emitArith` after the operands; the
type is the one inference recorded at the operator, else the carrier's). A site argument, not a
`$__site` global set before each operation: it is one `const` per operation instead of two instructions,
and it needs no state a nested or re-entered call could overwrite. `$__i32_add_chk` … `$__u64_mul_chk`,
the range checks, `$__i32_nz` / `$__i64_nz` (the divisor of an integer `/` or `%`, answered back when
not zero; the dividend waits under it) and `$__i32_divs` / `$__i64_divs` (a signed `/`: the zero divisor, then
`MIN / -1` with its own overflow site, else the quotient) call `$__chk_fail(site)`, the group `chk_fail`: `$__panic_raise(site,
1)` when the module has exceptions (so `attempt` answers `Error(panic)` and goes on), else `$__panic_fail`
(`panic: <message>`) and a trap. In a `.gc` module (front 164 s2 P4) the tag is `$__bp_panic (param anyref)`,
its payload an `$exn {msg, print}` (`gc_panic_raise`, `gc_chk_fail_raise`); `_botopink_main` and a `defer`
region catch an `anyref` and cast it; `$__wasi_attempt(f)` calls the thunk's `$closure` through the table
(`(closure) -> anyref`) inside the `try_table` and answers a `$result` — `Ok` of the thunk's boxed answer,
`Error` of the `$exn`'s message. `INT_MIN / -1` is checked by `$__i32_divs` / `$__i64_divs`, an overflow abort like the rest.

**What it does not cover** (144 B-07-b): a host fault traps — no exception, so no `attempt` catches
it; a thunk's word is an `i32` (a float or `i64` answer is not boxed for the
adapter); `attemptTask` contains what the thunk raises before its task's first
`await` — an abort in a later step of the task is not caught. A generic
`declare fn` a binding binds is read for its return as a bodied generic is
(`host_generic_decls`, `genericRetByFnArg` binding a thunk's `T` — `fn() -> T`
or `fn() -> @Async<T>` — from what the argument answers, through a namespace
call too, and `resultShapeOf` reading that shape), so `case` over
`await failure.attemptTask(…)` types a nested `@Result`.

## `@Async` as a state machine (decisions 392–394, front 140 step 4)

A task is a record in linear memory (`wat_prelude.zig` § decision 392's
scheduler: state, waiters, an 8-byte value, frame, `kind`, queue link); a
`@Async<T>` value is its address (`watType`, `isTaskTypeRef`). It starts when it
is made and runs to its first `await`; it settles once.

**In a GC module** (front 164 s2 P4, decision 544) the same scheduler runs over GC structs
(`wat_prelude.zig` § the scheduler in a GC module): `$task`, `$waiter`, `$hostn`, the ready queue and the
pending host tasks as reference globals. The prelude's GC forms name the module's types by slot
(`GcSlot`, an index at `gc_slot_base`), which `wat.zig` resolves when it writes the group into the module
(`gcRemapItem`, `gcSlotted`). A `@Async<T>` is `Repr.ref(.task)` (`gcReprOfType`, `wasmTypeOf` for any
task expression); a machine's frame is `$frame<n>` (`Repr.Kind.frame`, `GcTy.frame`, its slots' types in
`gc_frames`), made by `struct.new_default` in `$f` and cast back from the task in `$f__body`
(`gcEmitStateMachine`); the step settles with the answer boxed (`$__task_settle(t, anyref)`), and an
`await` reads the `value` field unboxed to what the task settles with (`Settled`, `gcAwaitedRead`: the
`T` of its `@Async<T>`, a generic one bound by the call or read off the value the shape readers see,
an `async { }` block's by `gcBlockRepr`, a block bound to a local by `gc_block_locals`); a task whose
`T` nothing here tells keeps its module in linear memory, since a box read as another kind traps. A
settled task drops its waiters and its frame (`$__task_wake`): the codegen breaks the cycles it makes
(question 544-a, (a)). An `async { }` block is a lifted lambda whose body is the machine
(`gcEmitLifted`), its wrapper answering the `$task`. `race` / `raceOf` / `spawnAll` take an `arr_any`
(the GC forms build their arrays as GC arrays, `gcTaskHelper`, without the linear `arr_new`); a thunk is
called through the table as `(closure) -> anyref`. `spawnAll` settles with an `arr_any`, so a call whose
answers are words or floats keeps its module in linear memory (`gcSpawnAllAnswers`). A gate is a `$task`
in an `unknown`. The `wasi` poll copies the pollables into linear-memory scratch for `bp_host.wait` and
gives it back (`gc_task_host_poll_wasi`). `try r catch h` over a `$result` is `gcTryCatch`.

- **Lowering** (`wat.zig` § decision 392). A `-> @Async<T>` fn (and each
  specialisation), a method answering one and an `async { }` block are lowered
  with `Emitter.machine` set, then laid out by `emitStateMachine` as three
  functions: `$f(args) -> i32` (a frame of 8 + 8 × locals bytes, the arguments
  stored, `$__task_start(kind, frame)`), `$f__body(task) -> T` (every local
  restored from the frame, `$__seek` set while the frame's resume index is not
  reached) and `$f__step(task)` (the body, then `$__task_settle_<T>` unless
  `$__task_suspended`). `$__task_resume` is the module's dispatch over every
  step by `kind` (`taskResumeFunc`, substituted for the prelude's trap).
- **Re-entry.** Every statement of a machine runs under `!$__seek || lo <=
  $__state <= hi` (`emitGuardedStmt`, the await range its lowering handed
  out); an `if`'s condition is kept in `__cnd<n>` and read back
  (`lowerCondition`), a `case`'s subject (`__case_<d>_<n>`, one local per
  `case`) and a loop's start (iterable, counters) are skipped (`guardStart`),
  a `while` condition answers `1`. `lowerAwait` gives each `await` an index:
  the operand into `$__aw<k>`, and when still pending the frame saved (the
  `save_marker` comment line `withFrameSaves` replaces), `k` stored, the task
  waited on (`$__task_wait`), a zero returned. Re-entering at `k` clears
  `$__seek` and loads the settled value. `return t` of a task is `return await
  t` (`adoptTask`). Because an operand evaluated before an `await` in the same
  statement runs again on re-entry, a call there is refused
  (`checkAwaitOrder`).
- **An `await` in a `case` arm** (a generic function as a plain one, a `return await t` arm, an
  `if` branch, a `case` nested in an arm) needs nothing beyond the guard above: each arm is a statement
  of the machine, its `await` index inside the range of the `case` statement, and the `case` subject is
  kept in its `__case_<d>_<n>` local, so re-entry skips the subject and lands in the arm. Conformance
  cell `task_await_in_case_arm`; std's `failure.attemptTask` on wasm is that shape. A `case` arm that
  is a `{ … }` block holding an `await` is refused by the checker on every target
  (`await-without-async`), so no backend meets it.
- **Outside a machine** (a plain function, a direct component lambda) `await`
  of a task is `$__task_block_on`: the ready tasks run until it settles; one
  still waiting on the host traps, on both hosts. A component lambda whose body
  awaits is a machine (§ Components), so a component waiting on the host no
  longer meets it. `await` of anything that is not a task
  (`isTaskExpr`) is the identity it always was. A task is known by its type: `typeRefOf` answers an array literal of task calls as an array of tasks (a `for` binder over it is a task) and an index / `at` / `first` / `last` / `pop` read off an array of tasks as a `?@Async<T>` (`xs[1] ?? t` stays one), and `xs[1]!` (the `__bp_opt_` `if` the checker makes of it, `optOperatorParts`) answers the `T`, so `await xs[1]!` settles it; conformance cells `task_array_awaited_in_for`, `await_postfix_binds_tighter`.
  A local bound to a lambda written without an annotation whose last statement is an `async { }` block (`val failing = { n -> async { throw "inner"; } }`) is typed by `lambdaTaskTypeRef` at its binding: `fn(i32) -> @Async<@Result<V, E>>` (`@Async<V>` when the block cannot fail), `V` and `E` read off the block's `return` / `throw` operands as the transform leaves them (`__bp_ok(v)` / `__bp_error(e)`, `scanBlockReturns`) — the checker's type is not handed to this backend, so without it the `await` was the identity and `Error(e)` printed the handle; conformance cell `task_lambda_result_unannotated`.
  An awaited `@Result` keeps its type through `await`, so `@print` and the `Ok(v)` / `Error(e)` binders of a `case` read it (it printed the cell's address otherwise): `await twice(21)` over `fn twice<T>(v: T) -> @Async<@Result<T, string>>` binds `T` from the plain-`T` arguments (`bindAwaitedGeneric`), and `val t = async { … throw e … }` is typed `@Async<@Result<V, E>>` at its binding when the block fails (`failingAsyncTypeRef`, sharing `asyncBlockTaskType` with `lambdaTaskTypeRef`); conformance cell `await_result_print`.
- **The scheduler.** `_start` ends with `$__task_finish`: drain the ready queue,
  then `$__task_host_poll` (the `wasi` host's, `task_host_poll_wasi`, over
  `bp_host.wait`) until nothing is pending. On `browser` the poll answers `0` and
  the loader drives the rest from the event loop, calling `__bp_ready(id)`.
- **Adapters** (decision 393; `host_binding.zig`): `wasi: .Delay` `(i32, T) ->
  @Async<T>`, `wasi: .Race` `(Array<@Async<T>>) -> @Async<T>`, `wasi: .RaceOf`
  `(Array<fn() -> @Async<T>>) -> @Async<T>`, `wasi: .SpawnAll` `(Array<fn() ->
  @Async<T>>) -> @Async<Array<T>>` — checked by shape at the annotation
  (`taskShapeOf`), one list for both hosts (decision 394). A task carries its
  `T` in one word: a float or an `i64` reaching an adapter is refused at the
  call (`refuseWideTaskValues`, `lowerCoerced`). The shape readers see an
  awaited adapter as the argument binding its `T` (`taskAdapterProxy`), an
  `async { }` block as its value (`asyncBlockValue`).
- **Gates** (decision 334, std's `async`; `task_gate`): pending tasks over
  fixed types. `wasi: .GateNew` `() -> unknown` is a task no host answers;
  `wasi: .GateOpen` `(unknown) -> void` settles it with `1`, after dropping
  the timer of each wait still pending on it (`$__task_host_cancel`,
  `bp_host.drop` — the `browser` loader imports `drop` for it and clears the
  timeout), so an open gate leaves no timer behind; `wasi: .GateAwait`
  `(unknown, i32) -> @Async<bool>` races the gate and a `delay` of `0`, the
  delay kept in the task's `+28` word. An adapter over fixed types that
  answers a task says so (`Adapter.answers_task`, checked against the
  declared `@Async`).
- **Memo cells** (decision 771, std's `hooks`; `memo_cell`): a `use memo` slot
  is a heap cell `[filled, value]` — `wasi: .CellNew` `() -> unknown` (empty),
  `.CellFilled` `(unknown) -> bool`, `.CellGet` `(unknown) -> unknown`,
  `.CellSet` `(unknown, unknown) -> void`. In a GC module the
  cell is the struct `$cell {filled: mut i32, value: mut anyref}` (`GcTy.heap_cell`,
  `GcSlot.cell`; `gc_memo_cell_*` over `anyref`, an empty cell answers `filled` 0), so
  a module that reaches it stays in GC. The
  slot's value is read back through `scope_carry.zig`'s `bpScopeRaw__memo<n>`
  wrapper, declared to answer the `T` the `read` carries.

## Generators as state machines (decisions 105, 125, 392; 144 B-128, B-142)

**The choice: a generator reuses the `@Async` machine, its `yield`s the suspension points.** In a GC module
an `@Iter<T>` is `Repr.ref(.gen)`, a `$gen` struct (`GcTy.gen`: `state` 0 live / 1 ended, `kind`, `frame`,
`value` the item last produced in its box, `src`, `aux`, `left`). Each `next` runs the body up to its next
`yield`; nothing runs before the first, so an endless body is consumed one item at a time and a handle is
stateful (a second `for` over an exhausted one reads nothing).

- **The body** is lowered with `Emitter.machine` set exactly as a task's (`beginGenMachine`): the same
  `$frame<n>` of every local, the same resume guards (`emitStmt`, `lowerCondition`, `guardStart`). `yield v`
  (`emitGenYield`) boxes `v` into the handle's `value`, saves the frame, records its index and answers `1`;
  entered again at that index it goes on after the `yield`. The end of the sequence (`emitGenMachineEnd`: a
  bare `break` / `return`, the body's end) answers `0`. `emitGenMachine` writes `$g(args) -> (ref $gen)` (the
  frame, the arguments stored, the body's `kind`; it runs nothing) and `$g__body(gen) -> i32`.
- **An `iter fn`** (and a method answering `@Iter<T>`) is that machine, its item the declared `T`.
  **An `iter` loop** (`iter while` / `iter for`, a marked lambda `{ iter -> … }` — decision 553's desugaring)
  is a lifted lambda whose body is the loop unprefixed (`lowerGenLoopValue`), its closure called where the
  loop is written answering the handle, as an `async { }` block's answers its task; its item is read off its
  first `yield` where it is written (`genLoopItem`).
- **A captured `var` is one variable on both sides** (decision 105): the handle keeps the lambda's
  environment in `aux`, every entry of the body reads the captures from it, and the body writes the ones it
  assigns back (`writeBackCapture`). In the function that made it, a step (`for`, `toArray`, `next()`) and a
  call handing the local on (`line(g)`, `lowerGenSyncedCall`) copy every capture in before and the assigned
  ones out after (`genSyncCaptures`, `gen_locals` — a local of a derived iterator syncs its source's). A call
  through a closure local copies every capture in too (`gcSyncCaptures`), so a lambda made before a
  generator ran reads what it wrote.
- **The consumers**: `for (g)` (`lowerGenFor`: `$__gen_next` per iteration, the item unboxed into the binder;
  re-entering a machine inside an iteration takes no step), `g.next()` (`Yield(item)` / `Done`, the item
  in the erased payload's box), `toArray()`, and `take(n)` / `drop(n)` / `map(f)` / `filter(f)` (a derived
  `$gen` over `src`: `left` the count, `aux` the closure, called as `(closure, anyref) -> anyref`), and
  `flatMap(f)` (144 B-142: the same derived `$gen`, the inner generator `f` answered for the source's last
  item held in `frame` and stepped while it lasts; closing it closes the inner one, then the source).
  `$__gen_next(g)` answers `0` once the sequence ended and drops the frame; `$__gen_resume` (`genResumeFunc`)
  dispatches by `kind`: `0`–`4` the derived iterators (`GenKind`), `gen_body_base` (5) + i each body of
  `gen_kinds`.
- **The walks** (144 B-142): `forEach(f)`, `some(f)`, `every(f)`, `reduce(f, init)` and `find(f)` step the
  handle in place (`lowerGenWalk`), the closure called on each item through the table; `some` / `every` / `find`
  stop at the item that answered, `find`'s answer the `?T` of the item (the item's box as it is, a reference
  cast to its type; `optInfoOf` reads it off the item). A generator method is lowered before the dispatch,
  which would read `find` / `flatMap` as another type's. `g.toArray()` printed directly prints by its item's shape (`printShapeOf`).
- **A `@Result` item** (decision 122): the transform already wrote `yield v` as `yield __bp_ok(v)` and
  `throw e` as `break __bp_error(e)`; a failing `try` stores its `Error` in `value`, runs the defers, marks
  the handle ended and answers `1` — no resume point, so the expression holding the `try` is never entered
  again. An `iter` loop's `@Result` item is read off its first `__bp_ok(v)` and `__bp_error(e)`
  (`genResultItem`); a `for` binder the first `yield` reads is typed by what its loop walks while the item
  is read (`installGenBinders`).
- **`defer` and closing** (144 B-142): a `defer` runs at the sequence's end (`emitGenMachineEnd`, the body's
  close) and when a consumer leaves before it: each `yield` records the defers pending there
  (`gen_close_arms`), and the body, entered with `left` at -1, runs the arm of the point it rests on and
  answers `0`. `$__gen_close(g)` (`genCloseFunc`) closes a derived iterator's source, enters a live body
  that way, and ends the handle; a `for` and a walk call it once they are done (`emitGenClose`), a no-op
  on an exhausted handle. A `return`, a `break :outer` or another exit past the `for` closes it too: while
  its body is lowered the handle is pending on `defer_stack` (a `DeferEntry` whose `gen_close` names it),
  below the iteration's own defers and the loop's floor, so the exit runs them first and then `$__gen_close`,
  and a plain `break` / `continue` leaves it to the close after the loop.
- **A `@AsyncIter<T>`** (144 B-142) is the same handle (`reprOf`, `isIteratorTypeRef`): a `@AsyncIter` fn, a
  method answering one, a `stream` loop; `for await` steps it as `for` does. An `await` in its body runs the
  task to its end where the step is taken (`$__task_block_on`, `lowerAwait`): the machine suspends at its
  `yield`s only.
- **What keeps a module in linear memory**, where an iterator is still the eager array: an item whose type
  nothing here tells, a method over a handle not listed above. A `yield :l` naming an
  enclosing generator scope still has no machine (`genLabelsOwn`); the checker refuses every such program
  today (`yield-label-unbound`), so no module reaches it.

## Components (decisions 388, 504)

A `@Component<R>` is a lambda over a `RenderScope` on every target (388); the scope lowering
(`comptime/context_lower.zig`) moves values through std's `context` functions in `unknown` slots
— a provided value (`push`), a body's result (`rendered`), the value a context read answers
(`find`) and the value a run answers (`valueOf`, `Rendered<R>`). This backend boxes and unboxes
only by a static type, so the lowering writes on each such call the checker's type of the value
as its one type argument, and `emitWat` rewrites every module's program — its own and each
linked one — through `scope_carry.carry` before anything is registered:

- **a value crosses the scope as its own word.** `bpScopeRaw__push` / `bpScopeRaw__rendered` are
  plain wrappers over std's function; `lowerPlainCall` passes a wrapper's arguments as they are
  (`scopeCarry.isWrapper`) and never boxes a word: std's body only stores and returns it. A float
  or an `i64` the call carries (its type argument, `scopeCarry.valueArg`'s position) crosses as the
  address of its 8-byte cell (`lowerCellWord`), as a function value's capture and answer do; one
  nothing types is refused;
- **a value read back is typed by its wrapper's declared return** — `bpScopeRaw__find<n>(s, k, n)
  -> T`, `bpScopeRaw__value<n>(r) -> R`, `bpScopeRaw__run<n>(c, s) -> Rendered<R>` — so every
  reader (a field, a concatenation, a printer, a destructure) asks a declared return as of any
  function; the wrapper's `return` passes the word as it is (`Emitter.raw_return`), or loads the
  cell of a declared float or `i64` (`modules/decisions-taken/component_is_lambda_over_render_scope-388/cells/context_wide_number_through_scope`);
- **`@Component<R>` is written `fn(unknown) -> unknown`** wherever a program writes it (a
  parameter, a field, an annotation): the value is the lambda's closure cell;
- a call of std's `find` / `valueOf` outside a wrapper — the checker left the type unresolved — is
  refused at the call;
- **only a lambda whose body awaits is a state machine** (504): `lowerLambdaValue` makes a
  component lambda (its one parameter `bpScope__`) a machine when `context_lower.containsAwait`
  finds an `await` outside its nested lambdas — a written one, or the one the lowering writes
  around a run of an asynchronous node (375) — and its closure cell carries the mark one word
  behind the pointer (`emitClosureCell`: `1` a machine, `0` direct). A run
  (`bpScopeRaw__run<n>(c, scope)`, every `await c` / `use h(…)` / `c.run(scope)` the lowering
  wrote with a carried type) is lowered in place (`lowerRun`): the lambda called, its mark read;
  a direct lambda's word is its `Rendered`, a machine's is its task — awaited where the run is
  awaited inside a machine (`emitSuspension` with the mark: it suspends only on a pending task,
  and reads the settled value only of a task), run to its end elsewhere (`$__task_block_on`). A
  synchronous component pays nothing, and a task's address is never told from a `Rendered` by its
  word (`modules/decisions-taken/components_compose_by_data-504/cells/component_awaits_host_task`);
- **a body that keeps a bare `try` runs its tail as an inner closure** (`context_lower`
  `lowerComponentBody`), awaited in place when the tail awaits — `await ({ -> rest })()`. That
  awaited call is lowered as an `async { rest }` block (`innerClosureBlock`): the closure is a
  state machine inside the component's, so a task the host still holds suspends both instead of
  trapping in `$__task_block_on` (`modules/decisions-taken/components_compose_by_data-504/cells/component_try_then_awaits_host_task`).

The general rows the component cells met, each kept: a lambda captures the names of a called
expression too (`collectIdents` reads `calleeExpr`: `(state(start))(scope)` captured `start`);
a capture keeps its written type and its bool shape (`Captured.typeref`, `bool_`), so a field
of an element of a captured `Rule[]` is a string inside the lambda as outside it; a local
shadows a function of its name (`lowerPlainCall`, `calleeSymbol`: `val #(n, push) = …;
push(n)` beside std's linked `push`); and a written empty body answering `void` (`fn discard(…) ->
void {}`) is a function of the module, not a host one (`isBodyless`).

## Where this backend refuses to answer

wasm is the only backend that can answer **wrongly and silently** — a number,
exit 0, no diagnostic — because every value here is an `i32` and a pointer is a
number like any other. The rule this directory holds to: *where wasm cannot
lower a construct, it refuses at compile time* — never a module that traps at
run time on a shape the other backends run, and never a wrong value with exit
0, even when a fixture records it. A lowering that cannot proceed — a name nothing binds, a field on
a receiver nothing types, a pattern naming no variant, a dispatch with no
function, a builtin or an expression kind with no lowering — is
`Emitter.refuse(loc, …)`: `error.WasmLoweringRefused`, carried to the driver as
a located diagnostic that fails the module (`Emitter.Refusal`, the slot
`emitWat` fills beside `MissingExternal`'s). Every such site used to write
`i32.const 0` with a `;; note` and go on, so the program ran and printed a
wrong value at exit 0 (`00 · 110-gate-wasm`); no `i32.const 0` stands for a
value this backend could not produce any more, and the three `emitC(zero, …)`
left are the `0` a `null` IS (`?.` on an absent receiver, an absent optional
compared or propagated).

**No lowering gap is a run-time trap** (`00 · 110-gate-wasm`, the refusals
rule). The `unreachable` sites that stood for a shape this backend could not
lower — 26 `emitC`/`emitCf` plus the bare ones, six of them added by `05-wasm`
— are refusals at the source location: `is` over a type with no descriptor, a
value boxed as `unknown` that nothing types, an all-unit enum value with no
printed form, a comptime-only builtin (`@emit`, `@compilerError`, `ref`) in a
program body, an index or slice on a receiver nothing types, a call nothing
resolves (`unresolved call`), a call of a bodyless `declare fn` with no
`#[@external(.<Target>(…))]` at all, a primitive method with no lowering, a
higher-order method given a function value, `flatMap` / `flatten` / `unique`
over elements whose shape is unknown, `.next()` with no `YieldStep`, `pop` /
`push` on a receiver that cannot be rebound (`pop` on a record's field is
lowered now, as `push`'s is), a loop over an iterable that is not an array or
a range, a lambda parameter nothing types (refused where the lambda is
written, `Lifted.loc`), and dispatch by value over an implementer whose values
carry no header (an all-unit enum) or whose method has another wasm signature.
The method-level ones read the call's location from `Emitter.call_loc`, which
`lowerExpr`'s `.call` arm sets. Each has a `tests/wat.zig` fixture
(`assertWasmRefusedAt`: the message and `line:col`).

**What keeps an `unreachable`** is the program's own semantics and nothing
else: `assert` (after `$__assert_fail`), `@panic` / `@todo` (a `@panic` with a string message writes it to stderr first, `$__panic_fail`, as the other targets do), a `throw` with
nothing to unwind to, a rejected `#[@future]`, and the end of
`$__bdispatch_<m>_<n>`'s chain, which `lowerBehaviorDispatch`'s refusal makes
unreachable — plus the generic bodies below.

**What a call binds a type parameter by** (`specializeFor`, `bindParam`, 144 B-25): an argument's value
shape; an `Array<@Async<T>>` argument's tasks as their values, an `Array<fn() -> @Async<T>>` one by its
first thunk's answer (std's `async.all`, `runAll`); a function-typed parameter (`work: fn() ->
@Async<@Result<T, E>>`) by every type parameter the argument's answer binds in one walk
(`bindByShape`, `fnArgReturn`: a lambda's last expression, or a value of a written function type —
std's `async.retry` and the `retryFrom` it passes `work` on to). A call through a namespace item
(`async.delay(…)`, the namespace its receiver) is the plain call to every shape reader and to
specialisation (`isNamespaceReceiver`). Each was a word read for a string at exit 0
(`conformance/modules/decisions-taken/std_async_on_every_target-690/cells/std_async_on_every_target`, `generic_thunk_result_binds`).

**A generic body traps only where no execution meets it.** A `fn` with type
parameters, a method of a generic `type` and a lambda lifted out of either are
emitted once, generic (`Emitter.cur_template`); a call whose arguments bind
the type parameters goes to a copy (`specializeFor` / `specializeMethod`, and
`x is T` over a parameter now asks for one — `callsMethodOn`). A construct a
bound type parameter would make lowerable (`refuseUnlessTemplate`: the
`unknown` box, an unresolved method on a `T`, a `T` iterated, …) is, in the
generic body, an `unreachable` that marks the body (`template_traps`), and
every call that reaches a generic body unspecialised is recorded
(`template_calls`: a plain or associated call, a record method, a generic fn
used as a value, a behavior dispatch, `@print` of a generic `type` declaring
`display`). After emission `refuseUnboundTemplateCalls` closes the marks over
the calls between generic bodies and refuses the first concrete call into a
marked one — `@print(Box(value: 1))` over `Box<T>.display` calling
`shown(self.value)`, `d.display()` on a `Dict<string, i32>`. A refusal raised
while emitting another module's code (a linked declaration, or a copy the
consumer's call specialised from one — `Emitter.foreign_origin`) is located
at the consumer's import or call, its message ending "in another module's code
this line reaches". So is one inside the copy of a std prelude `default fn`
(`primitives.bp`'s, `ast.BehaviorMethod.from_prelude`, `ensurePrimDefault`):
it is located at the program's call that reached it, never at the prelude's
line under the program's file name. **Not covered**: `@print` of a value whose static type
nothing names reaches `$__display_of` unrecorded.

**A host-backed `declare fn` with no wasm binding is REFUSED, not trapped**
(one with `#[@external(.Wasm("…"))]` is bound — § Host bindings)
(`wat.zig`'s `external_missing` + `lowerPlainCall`). A `declare fn` carrying
`#[@external(.<Target>(…))]` for some other target and none for `wasm` has no
symbol here and never claimed to have one, so the call fails where it is
written:

```
error: `listToBinary` has no `#[@external(.<Target>(…))]` for the wasm backend
  --> src/main.bp:21:12
```

That is the diagnostic commonJS, erlang and beam already print (06 C13's
`moduleOutput.MissingExternal`, target named `wasm`), reaching the driver as a
located `Diagnostic.type` through `emitWat`'s `missing` slot — the same wiring
`commonJS.zig` and `erlang.zig` have. It used to lower to `unreachable ;;
host-backed declare fn …/N: no wasm host` "so the module still loads", which made
this the only backend where the program compiled and then died at run time
(exit 134, stdout empty) — the divergence
`conformance/run/external_erlang_only.targets` existed to hold wasm out of.
[Decision 67](../../../../../../../specs/1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) settles it: the refusal is
located, and **no flag switches it off**. Ten `snapshots/codegen/wasm/external_*`
fixtures moved from a `WASM TEXT` block with that trap to a
`COMPILE DIAGNOSTIC` section; their `externals.zig` tests carry the new
`refused_on_wasm` expectation, which still requires commonJS, erlang and beam to
compile and fails if wasm ever starts accepting one.

**A bodyless function is a `declare fn`, never an empty body** (`isBodyless`):
`registerFn` and `emitFn` skip a function with no body of its own — a `declare fn`
(the parser promotes a bodyless `fn` with a return type to one) or a bodyless member
answering a value — and emit `fn f() {}`, which does nothing. Reading an empty body
as bodyless emitted no `pub fn main() {}` for `_start` to call (`compilation failed
UndefinedCall`) and refused every call of an empty `fn`
(`conformance/modules/fn/run/src/cases/fn_empty_main`, `modules/fn/run/src/cases/fn_empty_body_call`).

**A method of a behavior only a host builds is refused on the host binding** (`lowerPlainCall`):
`g.greet("ana")` over `behavior Greeter` that no type of the program implements has no function
to call — the value comes from a `declare fn` answering `Greeter` (`external_missing` maps each
such function to the named type it answers). When one of them has no wasm cell, the call is refused
as that function's missing `#[@external(.Wasm(…))]`, not as an unresolved call, so a `"targets"`
narrowing (`conformance/test/behavior_host_dispatch/`) stands on a host binding as the runner's
audit requires (`conformance/modules/behavior/cells/behavior_host_value_wasm_refused`).

**A function of the root package that reaches such a cell is refused where the
call is written, called or not** (decision 146 — "an error for whatever has no
target"). Every bodied function of the root package is emitted — `emitDecl`
lowers each `fn` and each method, and `registerSymbols` queues each behavior's
associated `default fn` that has no type parameter — so a body that calls an
`external_missing` cell meets `lowerPlainCall`'s refusal whether or not anything
calls the function: the rule commonJS, erlang and beam hold by emitting every
function, and the diagnostic they print
(`conformance/modules/external/cells/external_wrapper_keeps_refusal`,
`modules/external/cells/external_wrapper_associated_default`). wasm used to drop
such a root-package function and refuse only a call of it (`collectHostBound` /
`host_bound` / `MissingExternal.via`, all gone). **One shape is
still lowered only when a call reaches it**: an associated `default fn` with a
type parameter of its own or of its behavior (`behavior Probe<A> { default fn
f(x: A) … }`), which commonJS refuses uncalled and wasm accepts. Queueing those
too emits the primitive behaviors' (`Array.range`, `Array.repeat`, …)
into every module that carries the behavior — measured: 14 wasm fixtures change
and a two-line `flatMap` program's `.wat` goes from 12 to 17 functions — which
is `05-wasm`'s to weigh.

**A dependency's function the program never reaches is not lowered and stops
nothing; one it reaches is refused at the call** (decision 531; std is a
dependency — `crossModule.Packages.idOf(…).package_in_path`, read through
`build_packages`). Two mechanisms:

- `dropUnlowerableDependencyFns`, after `checkHostBindings`: a dependency's
  bodied `fn` whose body reaches — itself or through the dependency's other
  functions — a host function with no wasm cell is dropped from the
  declarations, recorded in `unlowered_reach` (and `external_missing`); a
  method of a dependency's type, behavior, `implement` or `extend` block the
  same way (`dropUnloweredMethods`, `unlowered_methods`, by `Type.method`); a
  dependency's `test` block that names one is dropped too. A call that still
  reaches one is refused where it is written: `` `viaHost` reaches `host`,
  which has no implementation for the wasm backend ``
  (`conformance/modules/decisions-taken/unreached_unlowerable_function_ignored-531/cells/dependency_unbound_host_reached_refused`,
  `dependency_unbound_host_method_refused`). For std the checker refuses the
  call first (STD-001, `std-unsupported-on-target`, decision 518 (4)).
- `emitWat`'s retry: when both lowerings refuse a module that links a
  dependency or is one, it is lowered again with `Plan.reached_only` —
  `pruneUnreached` in the linear pass too, and a dependency's own module
  rooted at its `val`s alone, its `test` blocks never — first in GC form, then
  in linear memory; the first refusal stands when the retry refuses too. A
  dependency function wasm cannot lower for another reason (an unresolved call
  in `std/io/clock`'s `durationCount`, a behavior no type implements in
  `testing.mocks`' fixtures) stops nothing while the program does not reach it
  (`conformance/modules/decisions-taken/unreached_unlowerable_function_ignored-531/cells/std_unbound_host_module_imports`,
  `dependency_unbound_host_unreached`).

**A refused module takes its consumers with it, each at its own import**
(`codegenEmit`'s `relocateLinkedRefusals`) — now only a module that refuses
what its consumer reaches. The linked declarations are emitted INTO the
consumer, so the consumer meets the same refusal at a location of the linked
module's file — which the driver would print against the consumer's. The
refused module reports its own diagnostic in its own file; each consumer that
links it (`Linked.via`: the consumer's import item the link walk came through)
reports `` <message> — in `<module>`, which this import links `` at that import.

A **bodyless `declare fn` with no `#[@external(.<Target>(…))]` at all** is
refused at its call too (`lowerPlainCall`); it kept the old trap until
`00 · 110-gate-wasm`'s refusals rule.

**A record or a variant reaching `@print` with no printed form is refused**
(it trapped until the refusals rule; `wat.zig`'s `namedShapeOf`,
consulted first in `lowerPrintArg`). Decision 8 §7's F2 and F3 want
`Point(x: 1, y: 2)` and `Shape.Square(side: 4)`; both need a value that knows
which named type it is at run time, which is `13-module-identity`'s subject, not
this backend's. Until then the numeric printer wrote the value's heap address —
`conformance/modules/print/run/src/cases/print_formatter` printed `328`, `336`, `344`. A value
that carries its header prints by it now; what is left with no printed form is
refused at the argument. commonJS needs no such interim: a class instance
carries its constructor's name and already answers §7's text.

The walk covers the value, an array or tuple **literal** holding one, and a
record recovered through a field or a fn return type. **Not** covered, and still
answering an address: a *local* bound to such a container (`val ps =
[Point(x: 1, y: 2)]; @print(ps)`) — the element shapes tracked per local are
`i32`/`f64`/`str`, and a record is an `i32` slot like every other pointer.

**A `?T`'s writer and its reader must agree about the box.** Two disagreements
made `d.at("a").unwrapOr(0)` answer `0` for a key that is present — the
defect the front's step 3 names, and *not* the `forEach` accumulator it suspected
(that works):

- **An assignment into a declared `?T` boxes, like the binding that declared the
  slot.** `var h: ?i32 = null; h = 5;` stored the bare `5`, and the reader took it
  for a box *address*: `@print(h)` answered `16777216`. `boxesInto` decides, from
  the slot's `local_typerefs` entry, at the assignment as it already did at the
  binding.
- **A method's declared return type is registered under the symbol its call
  emits** (`registerInterfaceSigs` → `fn_ret_typerefs`, `str_fns`, `bool_fns`,
  `fn_arr_elem`), and the shape predicates resolve that symbol through
  `resolvedCallSym` — `recordMethodSym` (inference's per-loc note, the path
  `lowerRecordMethod` itself takes) before `calleeSymbol`. Without it a method's
  return shape was invisible: `Dict.at`'s `?V` read as a box, `hasKey()`
  printed `0`/`1` for a `bool`, `values()` and a `string`-returning method printed
  a **pointer**.

**A `?V` over a type parameter is always a box** (`optInfoOfTypeRef`, C-18's
wasm half). Nothing here monomorphises, so the payload of `Dict<K, V>.at`'s `?V`
may be a scalar, and a present `0` has to differ from absence: the writer —
inside the generic body, where `owner_tparams` / `fn_tparams` put `V` in scope —
boxes into `$__box_i32`, and the reader — at the call, where the method's
registered return reads `?__tparam` (`eraseOptTypeParam`) — unboxes. Unboxed,
the absent key printed `0` (`modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/index_dict`, `modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/index_at_optional`). A method
declared `-> ?i32` boxes its `return` like a fn (`cur_ret_typeref` is set in
`emitMemberFn`), and a `?T[]` of a scalar prints as the array or `null`
(`arrayScalarCode`, `modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/index_user_type`).

**A call that binds a type parameter to a string, a bool or a float calls a
specialisation** (`specializedCallee` / `specializeFor` for a free `fn` and a
behavior's generic associated `default fn`, `specializeMethod` for a method of
a generic `type`). One body answers for every type here, each type parameter an
`i32` word, so a string bound to one printed and compared as a word (`Dict.at`
found a key `split` built only when it was the same pointer as the literal) and
a float was narrowed. The call's arguments (`x: T`, the elements of
`xs: Array<T>`, `bindParam`) and a method's receiver type arguments
(`Dict<string, i32>`) bind the type parameters, and the call goes to a copy of
the declaration with them substituted in every written type
(`substTypeParams`: `x: T`, `-> ?T`, a body's annotations) —
`Dict_at__K_string__V_i32`, lowered like any other function, emitted by
`emitPendingFns` under the declaring module's maps. A copy is made too when
the body calls a method on a value of the parameter (`x.toString()`,
`xs.at(0)`, `callsMethodOn`) whatever it binds: inference saw a type variable
there and recorded no lowering, so inside a copy (`in_spec`) `primKindAt`
reads the receiver's substituted type. `01-compiler/05-wasm` step 2 closed
the shapes that bound a string and still reached the one body:

- **a method copy reads its owner's fields by the substitution**
  (`field_subs` / `fieldSub`, set from `GenericMethod.subs` while
  `emitPendingFns` emits it): `self.left == self.right` in
  `Pair<string>.matched` compared words while `left: A` read as `A`. The
  substitution is deep (`fieldSub` runs `substTypeParams` over the whole written
  type): `pairs: Array<#(K, V)>` of `Dict<string, f64>`'s copy reads
  `Array<#(string, f64)>`, so a `forEach` / `filter` binder over it knows its
  tuple shape `(sf)` and `p._1` is read through its `f64` cell — before, it was
  read as an `i32` word and converted, and `Dict<string, f64>.at` answered the
  cell's address (`8976.0` for `1.5`, `modules/dict/cells/dict_float_value`). A copy also
  types its own `self` (`Emitter.emitMemberFn`: `local_typerefs` `self` is the
  copy's `Self<string, f64>` under the owner's name), so a call on `self` inside
  it (`bump`'s `self.at(key)`) specialises by the receiver's arguments too, not
  only by its own `key: K`;
- **a constructor of a generic record answers its type arguments**
  (`ctorTypeRef`, `record_generics`): `Pair(left: s, right: "ab").matched()`,
  a local bound to one, an array literal of them (`typeRefOf`'s `arrayLit`
  arm) and a HOF's element parameter over such an array specialise like a
  written `Pair<string>`;
- **a parameter written `Pair<T>`** binds `T` from its argument's type
  arguments (`bindParam`), and a field read through a receiver typed
  `Pair<string>` is a `string` (`recvTypeArg`): `eqPair(Pair(left: s, …))`;
  and a field read through one whose argument is a RECORD is that record
  (`recordTypeOfExpr`'s `identAccess` arm applies `recvTypeArg`):
  `route.data.title` of `route: Route<string, Post>` reads `Post`'s slot —
  it was an unknown record, so `"<h1>" + route.data.title` printed the
  string's address (`modules/generic/run/src/cases/generic_record_nested_field_concat`);
- **a generic fn NAMED as an argument** whose parameter is written as a
  function type, or **bound** to a `val` written with one, is the copy that
  type binds (`specializeByFnType`, `specCopy`): `apply(same, s, "ab")`
  against `f: fn(a: string, b: string) -> bool` called a trampoline over the
  generic body, and `val held: fn(…) -> bool = same` too (its call also
  prints as a bool now — `isBoolExpr` reads a function value's declared
  return).

**A lambda written as the argument of a generic type's method is written against the type the
method declares** (`methodLambdaExpectations`, `Lifted.param_tref`): `Bag(items: [1, 2]).map({ x ->
x.toString() })` over `map<U>(f: fn(x: T) -> U)` gives `x` the receiver's argument (`ctorTypeRef`
binds `T` from a field written `Array<T>` / `T[]` by its elements, `bindParam`), so `toString`
resolves as the integer's (`primKindAt` reads a parameter's `local_typerefs`), `bindMethodRet`
types the answer `Bag<string>`, and a composite field read through that receiver is
`Array<string>` (`recvTypeArgRef` writes the receiver's arguments into `Array<T>`). It was
`cannot resolve the call toString/0` (`conformance/modules/generic/run/src/cases/generic_method_lambda_param_typed`).

**A function in a generic record's field answers its declared return**
(`ctorTypeRef` + `fnRefTypeRef`, `recvTypeArgRef`, `genericRetByFnArg`):
`Box(value: shout)` is a `Box<fn(s: string) -> string>`, so `h.value("b")`, a
local `val k = h.value` called, and the same through `wrap(shout)` over `fn
wrap<T>(v: T) -> Box<T>` answer a string (a bool, …) — they printed its heap
address (`320`) or a bool as `1`. A function type has no specialisation; only
the result type is read. A call through such a local answering an array is an
array (`isArrayExpr` / `elemKindOf` read `valueCallTypeRef`); a generic record
built in place keeps its own type arguments (`Box(value: Box(value: hi))` is a
`Box<Box<fn() -> string>>`, and `recvTypeArg` names a generic argument by its
record), as does any argument whose type is written (`typeRefOf`) —
`conformance/modules/generic/run/src/cases/generic_field_fn_value_nested`. A function value answering
an `f64` is still refused (`call_indirect` answers an `i32`).

**A lambda argument is typed by the parameter it is passed for.** A call of a
module function sets `expected_fn` from the parameter's declared function type
(`fn_param_typerefs`), so `{ p -> p.nome }` for `fn(Pessoa) -> Pessoa` reads
`Pessoa`'s field and `{ s -> "a" + s }` for `fn(string) -> string`
concatenates (`modules/lambda/run/src/cases/lambda_param_shared_field`). A call of a module-level
`val` written as a lambda (`global_lambdas`) is judged as a closure local's is
(`modules/decisions-taken/template_call_expands_any_expression-425/run/src/cases/template_in_module_val_lambda`).

**A lambda in such a field is typed where it is used, or is refused.** The field
says nothing (`T`), so `lowerRecordCtor` leaves the lifted lambda's
`param_known` false unless the constructor stands where a type is written for
it (`expected_ctor`: a parameter `b: Box<fn(s: string) -> string>`, a `val`'s
annotation, the function's return type — the lambda is then written against
the type argument, `expected_fn`). A call through the field of the local the
constructor is bound to (`lam.value("e")`) or through a local read from that
field (`val lf = lam.value`) types it from its arguments, as a closure
local's call does (`field_closures`, `fieldClosureOf`; `closureCallIsString`
judges the result). A parameter the body reads that nothing typed REFUSES the
lambda where it is written (`lambda parameter `s`: nothing gives it a type the
wasm backend can see`, `Lifted.loc`) — the record passed through a generic fn
and called on the result is that shape. It printed `300?` for `"d" + "?"` at
exit 0, then trapped at the lambda's entry. Any other lambda keeps
`param_known` true: its slot types it, or an integer reading is what it always
had (`modules/generic/cells/generic_field_fn_value`, `tests/wat.zig`'s refusal fixture).

`modules/generic/run/src/cases/generic_string_equality` pins every way a type parameter gets a
string bound on four targets, `modules/method/run/src/cases/method_on_unimported_type` (`Dict.at`
with a key `split` built) included — it already passed at the open, through
`specializeMethod`. **What stays**: a call whose arguments and context say
nothing about the type keeps the one generic body — a generic fn stored in
a field or bound with no written type, a parameter type `bindParam` does not
read (it reads a bare `T`, `T[]` / `Array<T>` and a generic record's direct
type arguments) — and there `==` between two
type-parameter values compares words (a composite bound where the body
compares with `==` IS specialised, § Structural equality); so is a method of a generic `type` whose receiver binds a record and whose body compares with `==` or calls a method on `self` or a parameter — `Set<Point>.contains` / `union` — and a type-qualified call such as `Set.fromList(xs)` takes the same path (`specializeMethod`) and `elemKindOfTypeRef` reads a type
parameter as `.i32`. A string carries no header (it is a bare
`[len][bytes]` blob), so a body cannot ask the value what it is: the copy is
the only cure, and `modules/generic/run/src/cases/generic_body_specialized` pins the shapes that
reach it. `fieldSub` is owner-wide: inside a copy of `Pair<string>`'s method,
a `Pair` of another instantiation reads its fields as `string` too.

**A tuple element is printed by its own shape, not by its address**
(`tupleElemShapeOf`). This was the last silent wrong-answer class the directory
carried, and it was two fixtures:

| Fixture | Written | Printed | Means | Now |
|---|---|---|---|---|
| `tuple_chained_positional_access_and_a_method_on_an_element` | `@print(t.1)` | `256` | `x` | `x` |
| `tuple_labels_resolve_to_positions_on_every_backend` | `@print(row.name)` | `256` | `SP` | `SP` |
| the same | `@print(local.a)` | `264` | `RJ` | `RJ` |

Both are a **labelled or positional tuple element whose type is a string**. A
label is not a separate case: the checker resolves `row.name` to `row._0` before
this backend sees it (§6 T4), so the member is always `_N` or a bare `N`. The
element's shape *was* known — `printShapeOf` builds `((ii)s)` for the tuple and
`(si)` for a `#(name: string, pop: i32)` — but only to `printShapeOf`, whose
contract is to answer **containers**; `isStringExpr` is what `@print` asks about a
**single** value, and it had no way to ask. `tupleElemShapeOf` slices element `N`
out of the receiver's shape and both readers now ask it, so `str_locals`, string
`+` and string `==` follow for free (`val s = t.1; s + "!"` answered `256!`).
`shapeSpan` is the Zig twin of `$__print_shaped_raw`'s `go = 0` measuring mode and
has to keep agreeing with it — they walk the same strings.

Because `printShapeOf` asks too, an element that is itself a **container** prints
as one: `t.0` of `#(#(1, 2), "x")` answered `296` and answers `#(1, 2)`, and `u.0`
of `#(["a", "b"], 3)` answered `312` and answers `["a", "b"]`. Here wasm is ahead
of commonJS, which prints `[1, 2]` for `t.0` — it drops the `#` marker when the
shape hint is absent. That is `04-js`'s row, which is why the fixture pinning
these is `assertWasmRunLog` and not an all-backend snapshot.

**A `?T` element is its optional's carrier** (`01-compiler/05-wasm` step 5;
`optElemShape`, `valueShapeOf`, `typeRefShape`'s tuple arm, `optInfoOf`'s
tuple-element arm). Its shape is `?X` when the slot is the payload's own
pointer or 8-byte cell (a string, a record, a container, a `?f64`, a `?i64`)
and `!X` when the payload is a scalar in a `$__box_i32` cell; `0` is absence
in both, printed `null`, and `t._N` reads the carrier the code names. Read
through the payload's code, `#(1, [7].at(0))` printed `#(1, 328)` and
`t._1` the box at exit 0. A `?T` whose payload this backend cannot name (a
`?T` over a type parameter, an all-unit enum) is refused where the tuple is
built — in a generic body the body is marked (`template_traps`) and a concrete
call reaching it unspecialised is refused —, and `@print` of a tuple with no shape is refused rather than printed
as its address. A generic method's declared `#(Q<T>, ?T)` is read at the call
with its `?T` erased to `?__tparam` (`eraseOptTypeParam` walks a tuple's
elements), the box its body wrote — `Queue.dequeue()._1.unwrapOr(-1)` printed
the box's address. `modules/tuple/run/src/cases/tuple_optional_element`; the `tests/wat.zig` RUN LOGs
`a ?T element prints and reads as its payload or null` and `the answer keeps
the payload's tuple shape`.

The class was found by scanning every `RUN LOG` in the directory for a bare
integer ≥ 256 (the first data offset) or a bracketed list of them. Six files
matched: the two above, `record_a_method_named_print_is_called_on_the_record`
(`@print(d.print())` → `276`, fixed by the method-symbol registration above and
now recording `doc:hi`), and three whose numbers are the value the program
actually computes (`loop_filter_with_conditional_break` `[250]` — it read
`[250, 400]` until decision 55, below —,
`template_end_to_end_generic_expr_via_code_builtin` `8081`,
`template_end_to_end_yaml_model_computes_a_labeled_tuple` `8005`). **No fixture
printed a record or a variant**, which is why the trap above re-recorded no
existing file — the addresses §7 owes were only ever in the language cells. Any
new fixture whose log holds such a number is worth re-reading against this table.

What is left in this class is the **generic-parameter limit** above — the
calls nothing specialises, a narrower set since `01-compiler/05-wasm` step 2 —,
which is a different cause: there the declared type is a type parameter, so no
shape exists to slice — and one more, reported on `fix/wasm-refusals` and not
fixed there:

**`$__print_str_raw` guards its own null** (`00 · 05-wasm`, 1.0.10-beta). A
string here is a length-prefixed blob in a data segment or on the heap, and both
start at the data floor (256); everything below it is the scratch area, and
`0..8` is the WASI iovec itself. So a pointer below the floor is not a string —
it is an absent `?string` whose shape nothing registered — and the helper traps
(`unreachable`, wasmtime 134, a backtrace naming `$__print_str_raw`) instead of
loading a length from address 0 and writing whatever bytes sit there. Measured
both ways by disabling the `s.at(i)` arm of `optInfoOf` and rebuilding:
`@print(s.at(3))` on `"abc"` wrote garbage at exit 0 before the guard (six spaces
at the tip the row was written against, a bare newline at `2e6bb4ac`) and traps
after it. This is [decision 67](../../../../../../../specs/1.0.10-beta/decisions-taken.md)
— the most restrictive behaviour, and no flag that turns it off — and it is the
reason the hand-maintained list below is no longer a silent trap: an optional
shape nobody registered is now loud.

## Host bindings (decision 238, `01-compiler/05-wasm` step 5)

`#[@external(.Wasm(…))]` is one labelled cell of a closed vocabulary (decision 481 —
the checker refuses a prefixed string, a value of the wrong kind, an unknown label
and a second cell on every target, `infer.zig` `checkExternalCells`, and resolves
`fn:`), read before anything is registered (`wat.zig` `checkHostBindings`, over the program and its
linked modules, each `declare fn` against its OWN module):

| Cell | Check | Lowering (`emitHostBinding`) |
|---|---|---|
| `op: "<opcode>"` | `host_binding.zig` `findOp`; the declared parameters and return are exactly the opcode's types (`bool` for a comparison) | a function of the declared name: `local.get` of each parameter, the instruction |
| `std: "<module>.<function>"` | `host_binding.zig` against `std_wasm.exports`; the declared parameter and return types are the function's exactly (`std_wasm.matches`; the checker refuses a mismatch on every target, `infer.refuseStdBinding`) | a function of the declared name that calls the std-wasm function, transpiled into the module (§ std-wasm in the program) |
| `fn: <name>` | the declaring module has a `fn <name>` with a body, not `pub`, of the same written parameter types in order and the same return (`hostFnBinding.resolve` — the check commonJS, erlang and beam run on their own `fn:` bindings — compared as `TypeRef.format` spells them) | a function of the declared name that calls `<name>` — the mangled name when a linked module's function was mangled (`link_mangled`) |
| `wasi: .<Adapter>` | `host_binding.zig` `adapters` (the list `conformance/docs.md` § Host bindings documents); the signature is the adapter's | a function that calls the adapter's prelude helper (`random_f64` → `$__wasi_random_f64`, which brings the `random_get` import); a written `-> void` answers the `0` its caller drops (a `std:` function answering nothing, `random.seed`, alike) |

A bound declaration is registered like a bodied `fn` (`registerFn` skips the
host path when `host_bindings` holds the name), so calls, shapes and
cross-module links read it as one. A binding outside the vocabulary — another
prefix, an unknown opcode, an opcode of another type, a misspelt or `pub` or
differently-typed `fn:`, an unlisted adapter, two strings — is refused at the
annotation (`Emitter.refuse`, the annotation's `loc`; in a linked module at the
consumer's import). The arguments are always the declared parameters, so there
is no marker, no target text and no address in a binding, and no prelude
helper's name is any library's contract. The check runs on a wasm build; a
binding on a module no wasm build reaches is not read (the checker half that
would read it on every target is `01-checker`'s — `comptime/infer.zig`'s
`external_variants` walk).

**The host a binding serves (decision 334, front `01-compiler/140` step 2).** A
wasm build binds to one runtime, named by `botopink.json`'s `"wasm": { "host":
… }` (`wasi`, the default — wasmtime, WASI preview 2 — or `browser` — JS imports,
JSPI) and carried in as `Config.wasm_host`. A binding may name the host it
serves, `#[@external(.Wasm(op: "f64.floor", host: .Wasi))]`; one written without
`host:` serves every host. The build's `#[@External.<Member>]` lookup carries
the host (`ast.WasmHost.lookupName`: `wasm` is `wasi`'s, `wasm.browser` the
browser's; `ast.ExternalLookup.of` splits it), so `externalFor` returns the
binding serving the build's host and passes a binding for the other one by —
a `declare fn` bound on the other host only is `external_missing` on this one,
and std's gate (`comptime/infer.zig` `externalSpelling`) reads
`std-unsupported-on-target: … for target 'wasm' on host 'wasi'`.
`checkHostBindings` reads and checks **every** wasm binding of a `declare fn`,
whichever host it serves (`checkHostBinding`), and records the one serving
the build's host: a misspelt `.Browser` `fn:` is refused on a `wasi` build. The
checker refuses `host:` on another variant, a value other than `.Wasi` /
`.Browser`, and a second binding for one host (an unhosted binding beside a
hosted one included) — `refuseHostArg`, `refuseWasmHostTwice`; cells
`modules/decisions-taken/wasm_host_profiles_wasi_browser-334/refused/src/cases/external_wasm_host_unknown`, `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/refused/src/cases/external_host_on_node`,
`modules/decisions-taken/wasm_host_profiles_wasi_browser-334/refused/src/cases/external_wasm_host_twice`, `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/refused/src/cases/external_wasm_host_beside_unhosted`,
`modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cells/external_wasm_host_binding`, `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cells/wasm_host_from_manifest`.

`std/math` is the first user: `abs`, `floor`, `trunc`, `sqrt`, `minF`, `maxF`
are `op:`; `round` is `fn: roundHalfUp` (V8's ceil-based rule — `f64.nearest`
rounds a half to even); the rest are `fn:` bodies that port fdlibm as Node's V8
runs it (`deps/v8/src/base/ieee754.cc`) with exact arithmetic standing for its
word operations — bit for bit the commonJS answer on a 6 500-input fuzz — and
`pow` a port of glibc's (decision 259), which every target runs. erlang and
beam bind the same bodies (decision 263), so a transcendental is the same bits
on every target and every OS. `std/escape`'s two separators are `fn:` bodies
holding the literal. `std/hash` binds every cell with `fn:` — SHA-256, SHA-512,
SHA-1, MD5, HMAC, PBKDF2, base64 and the djb2 fold in exact `f64` arithmetic
(a word a whole number below 2^32, stored in an `Array<i32>` as two 16-bit
halves, its constants the standards' hex read in place) —, identical to
commonJS on a 180-input fuzz of every cell (1 987 lines, astral characters
included). `std/io/random` binds `float` to std-wasm's `std: "random.float"`, `seed` /
`seededFloat` to `std: "random.seed"` / `std: "random.seededFloat"`
(decision 451: the commonJS sidecar's Mulberry32, its state a `.bss` word of
std-wasm's — a std module cannot hold it, a module-level `var` lowers to
`std@beam` on erlang; a draw before any seed is the host's,
`env.bp_random_f64` linked to `$__wasi_random_f64`) — and `shuffle`,
`secureToken`, `uuidV4`, `randomBytes` to `fn:` bodies over `float()`
(= `random_get` here); the seeded draws equal the sidecar's bit for bit
(`random.zig`'s tests, `tests/wat.zig`).

A `fn:` target is compared with the declaration as written, **its own
module's qualification dropped** (`sameSignature` / `typeText`): linking a
module qualifies a `pub` declaration's types for its consumers
(`std/io/random/Array<T>`) and leaves the private body's as written, so
`shuffle<T>(xs: Array<T>)` was refused in every program that imported it.

What the std bodies ran into — each a limit of this backend, measured while
binding `hash` and `io/random`, and each still open:

| Limit | What happens | Status |
|---|---|---|
| `i64` was lowered as `i32` | an `i64` local, parameter, return, record field, tuple element, `?i64` and closure capture is an `i64` (§ Numbers); an `i64` in an array, a variant's payload or a `@Result` is refused where it enters — the bodies still use exact `f64` | fixed / refused |
| a float in an array was stored as its `f32`, and `xs.at(i).unwrapOr(0.0)` on an `Array<f64>` was invalid code | every float slot holds its `f64` cell (§ Numbers); `unwrapOr` over a `?f64` answers an `f64` | fixed |
| `Float.toString` wrote six fraction digits; a float ≥ 2^31 trapped in the prelude's float text | std-wasm's shortest digits (§ Numbers, decision 441) — `0.26642920868471265` prints whole | fixed |
| `Array.range` / `Array.repeat` recurse once per element through a spread (`primitives.bp`), O(n²) memory | the bodies double an array (a range of one is its element); an associated `default fn` whose cells name other targets only (their `.JavaScript` template) is lowered from its body, as erlang and beam lower it — skipped, `Array.range(0, 3)` was an unresolved call; a local bound to an array in such a body has the array's methods (`primKindAt`). `conformance/modules/array/run/src/cases/array_range_and_repeat` | fixed |

## Numbers: a float's text, the 8-byte cells, integers that do not wrap

`00 · gate-wasm-wrong-answers` closed three wrong answers at exit 0 and the
class beside them. What each number is here, and what is refused:

- **A float's text is std-wasm's** (decision 441). `@print`, `toString`,
  `"${x}"` and `"s" + x` all call the function `Float.toString`'s `std:`
  cell names, `number.floatToString`, transpiled into the module: OTP's `float_to_binary(x, [short])`, the text
  of erlang, beam and the comptime — the shortest digits that read back as
  `x` (Ryu), in fixed notation or as `D.DDDeE` when that is shorter (`5.0`,
  `0.30000000000000004`, `1.0e21`, `5.0e-324`, `1.152921504606847e18`), and
  `NaN`, `Infinity`, `-Infinity` for the values only a wasm program's
  arithmetic makes; from 2^53 on always `D.DDDeE` (`9.007199254740992e15`), as
  OTP writes it. commonJS writes the same text through its `__bp_f64` port
  (decision 521). It was
  V8's `BignumDtoa` transcribed over 40-limb bignums (commonJS's text), and
  before that six fraction digits that trapped past `2^31`.
- **A float in a 4-byte slot is the address of its `f64` cell**
  (`$__box_f64`; `lowerSlotWord`, `emitToFloatSlot` / `emitFromFloatSlot`):
  an array or tuple element, a variant's payload, a record field (as before),
  a closure capture, a `?f64` (`OptInfo.cell = .f64` — a float array's
  `at(i)` is the slot's own cell). A cell is never written again, except a
  closure's capture, which is its own. `ElemKind.f64`, the shape code `f`,
  `$__print_arr_f64`, std-wasm's `array.indexOfFloat` (`f64.eq`, as
  `Array#indexOf`), `array.joinFloats`, `array.unique`'s mode 1 (the cell's
  bits) read the cell. It was
  narrowed to an `f32` in the slot: `[1.1]` read back `1.100000023841858`, and
  a tuple element, `join` and a record printed through its shape answered bits
  or addresses.
- **An `i64` is an `i64`** — a local (a written type wins over the value's:
  `bindingLocalType`), a parameter, a return, a method's (`memberValType`),
  an integer literal past the `i32` range (`numLitType`), `u32` and `u64`
  (both held as `i64`). A record's `i64` field, a tuple's `i64` element and a
  `?i64` hold an 8-byte cell (`$__box_i64`, shape code `l` — `u` for a `u64`,
  whose bits print unsigned — `$__print_opt_i64` / `$__print_opt_u64`); a
  closure capture too. A tuple literal boxes each element whose own type is
  64-bit (`lowerTupleLitAs`; the checker types an element by itself, so
  `#(1, true)` is never a `#(i64, bool)`), and every element reader goes by
  the shape's cell (`shapeCell`: `t.N`, `val #(a, b)`, a `case` binder, a
  `for` element, `==` — `$__eq_<T>` compares a tuple slot as a record
  `field`, and a tuple literal compared with a typed tuple is built with
  that tuple's widths, `lowerTupleEqAgainst`); a pattern that TESTS a 64-bit
  element is refused. It prints (`$__print_i64`, the digits std-wasm's
  `number.i64Text`) and turns into text (`number.i64ToString`) in all its
  digits.
- **Nothing narrows silently.** `lowerCoerced` and `emitConvert` refuse a
  float or an `i64` asked for as a narrower word (`lossyConversion`) — the
  backstop that turns every slot with no wide reader into a located refusal:
  an `i64` element of an array, an `i64` / float payload of a
  `@Result` (`__bp_ok`), a function value's float or `i64` argument or answer
  where nothing says the function's type (it was `i32.trunc_f64_s`), an
  integer method over an `i64` but `toString`.
- **A function value's float or 64-bit argument and answer travel in a cell.**
  The indirect call carries words, so the caller passes such an argument as
  its `$__box_f64` / `$__box_i64` cell and reads such an answer out of one
  (`valueCallCells`: the lambda the closure local holds, else the function
  type of the local — a `?fn(…)` binder's included — or of the expression the
  callee is), and the lambda reads its parameter out of the cell and boxes
  its answer (`Lifted.param_cell` / `ret_cell`, from the function type it is
  written against); a top-level function's trampoline does the same from its
  signature. Both sides read the written function type, so a caller and a
  callee that know it agree; a caller that does not refuses the argument
  (`modules/decisions-taken/optional_typescript_operators-330/run/src/cases/optional_float_function_value`).
- **An `if` with a `null` arm into a `?T` slot boxes arm by arm**
  (`lowerBoxedIfArms`): `val n: ?i32 = if (c) 3 else null` boxes the `3` and
  leaves the `null` arm the `0` of absence — boxing the whole `if` made an
  absent `n` a present `0` (`modules/decisions-taken/optional_typescript_operators-330/run/src/cases/optional_if_null_initializer`).
  `Option.map` over or to a cell type is refused at the call.
- **Arithmetic over a boxed optional is refused** (`lowerBinOp`): `xs[i]`
  answers `?T`, and `[1, 2][0] + 1` added to the box's address (`269`).
- **`?.[]`, `?.()` and the postfix `!`** (decision 330) reach the backend as an
  `if` over the optional with a `__bp_opt_<line>_<col>` binder
  (`optOperatorParts`). `xs?.[k]` answers the link's own optional (`optInfoOf`
  reads the arm), and `x!` its payload (`isStringExpr`, `isBoolExpr`,
  `printShapeOf`, `wasmTypeOf`, `recordTypeOfExpr` read the operand's
  `OptInfo`). A `?.()` over a function answering a plain value boxes its
  answer as a `?T` of that type is (`optLinkBoxInfo`: the link's type, else the
  return of the `?fn(…) -> T` the operand holds; `lowerIfExpr`), so `?? d` and
  `@print` read it as any `?T` (`modules/decisions-taken/optional_typescript_operators-330/cells/optional_call_operator`,
  `modules/decisions-taken/optional_typescript_operators-330/cells/optional_call_plain_answers`); a link whose type is not known here is
  refused at the operand. Over an optional array of records, `xs?.[k]` / `xs?.at(k)` answer the record's own
  pointer (`optLinkElemRecord`, `chainedCallOpt`), so `first!.name` and `p?.title` read the record's slot
  (`modules/decisions-taken/optional_typescript_operators-330/cells/optional_index_record_field`,
  `modules/decisions-taken/optional_typescript_operators-330/cells/optional_array_at_record`); an array or a tuple
  element of a tuple literal bound by `val #(a, b) = …` keeps its shape (`noteTupleElemShape`,
  `modules/decisions-taken/prelude_has_no_pair_or_function-738/cells/tuple_destructure_array_element`). `o ?? d` reads its shape and
  its bool-ness as `o.unwrapOr(d)` does (`nullishParts`):
  `(rs.at(1) ?? #("", ""))._1` printed the string's address. `xs.map({ n -> Y(…) })`
  holds the record its lambda answers (`elemRecordOf`), so `built.at(1)?.id` reads the field
  (`modules/decisions-taken/optional_typescript_operators-330/run/src/cases/optional_member_default`).
- **A cell enters only where its reader knows it.** An array's elements share
  one kind (`lowerElemWord`: a float anywhere in a literal makes every slot a
  cell, `[1, 2.5]`); a float pushed or prepended into an array no type says
  holds floats (`var xs = []`) is refused at the value. A float in a record
  field or a variant payload its declaration does not type as one
  (`Box<T>(value: T)`, `Some(v: T)`), and a float or `i64` inside an argument
  whose parameter is a container of a type parameter of an unspecialised
  generic `fn` (`#(A, B)`, `Array<T>`), are refused: the one generic body
  reads them as words (`264` for `1.1`).
- **One wasm local has one type.** A binder whose name the function already
  declared with another width is a local of its own (`bindTargetAs`: a `val`,
  a `for` element, a HOF's element and accumulator); a HOF's element parameter
  is the element's width while a shape question is asked about the body
  (`holdElemParam`), and a `for` / HOF element that is a tuple or an array
  takes its shape (`noteElemShape`), as a destructured tuple element does
  from the tuple's print shape (`noteTupleElemByShape`) — `val #(a, b) = t`
  printed the string `b` as its address. A record destructuring
  (`val { class, id } = t`, `localBindDestruct` `.names`) types each binder by
  its field as the constructor form `val Tag(c, i) = t` does (`str_locals`,
  `bool_locals`, `local_types`): a string binder concatenated as a number
  (`modules/record/run/src/cases/record_field_reserved_word`).
- **Integers do not wrap** (`emitArith`, `int_chk`): an `i32` `+`/`-`/`*`
  (and a negation, a `+=`) is computed in `i64` and checked back — except a
  type's minimum written as itself (`-2147483648`, `-9223372036854775808l`,
  decision 319; `negatedMinimum`), the constant: `0 - 2^63` trapped the
  checked `sub`, and `2^31` alone read as an `i64` the slot refused; an `i64`
  one by the signs or by dividing back. A result outside the type traps —
  commonJS and erlang answer the wide number, which no `i32` holds; wasm
  answered the wrapped one at exit 0. A type narrower than its carrier —
  `i8`, `u8`, `i16`, `u16` in an `i32`, `u32` in an `i64` — then
  checks its own range (`emitRangeCheck`, `$__i32_range_chk` /
  `$__i64_range_chk`), the type inference recorded at the operator
  (decision 264): `127 + 1` on `i8` and `0 - 1` on `u32` trap. A `u64` /
  `usize` is `0 … 2^64 − 1` in its `i64` carrier (decision 319): the
  operator inference typed `u64` (`isU64At`), or an operand declared one
  (`isU64Expr`), takes `div_u`, `rem_u`, `lt_u` … `ge_u`, and its `+ - *` the
  unsigned checks `$__u64_{add,sub,mul}_chk` (group `u64_chk`, no range check
  after); `@print`, `toString` and a string operand write its digits through
  std-wasm's `number.u64Text` / `u64ToString` (`print_u64`) — a `u64` record field
  or tuple element by the shape code `u`, a `?u64` by `$__print_opt_u64`,
  `o ?? d` over a `?u64` (typed by the payload, `typeRefOf` through `nullishParts`; a `@Result`'s `unwrapOr` the same way) and a
  `?u64` a null test narrowed (`isNarrowedName`) as a `u64`. Division keeps wasm's
  own traps (`/ 0`, `MIN / -1`), where erlang raises too.

Cells (four targets, one `.out`): `modules/decisions-taken/wasm_prints_std_wasm_text-441/cells/float_shortest_text`,
`modules/float/run/src/cases/float_slot_keeps_f64`, `modules/i64/cells/i64_full_width`, `modules/u64/cells/u64_tuple_slot`,
`modules/decisions-taken/i64_is_64_bit_everywhere-319/run/src/cases/u64_record_field_print`, `modules/optional/cells/optional_u64_to_string`; refused on wasm
(`.wasm.expect`): `modules/optional/cells/optional_index_arithmetic`, `modules/i64/cells/i64_in_array_slot`,
`modules/fn/cells/fn_value_float_argument`, `modules/untyped/cells/untyped_array_float_push`
(`modules/generic/cells/generic_field_float` is answered since 164 s2 P3: a float in a generic slot is boxed). `tests/wat.zig` pins the forms erlang spells
otherwise or cannot make (`1e+21`, `5e-324`, `Infinity`, `NaN`) and the
overflow trap as RUN LOGs.

## The runtime core and std's units (decisions 1021 (2), 1026, piece P3)

The module a snapshot runs (`.module`) imports, instead of carrying them, the **runtime core**
`std@__rt` and the **std units** `std@<path>` it reaches (`runtime_unit.zig`); so does a `wasi`
program's component (`Artifact.component`) under `Config.wasm_units`, which stays off until the C-API
runner composes units (decision 1037 (5): no program is written with a unit's text, so the component
links std-wasm in as before P3); the `browser` host keeps one module with std-wasm linked in until
its loader instantiates several (P6). All are the same bytes for every program and are cut once per
compiler build (decision 1032 (4)): `zig build` runs `src/std_units_main.zig --blob`, which serializes
the cut (`runtime_unit.serialize`: the core's and each unit's text and bytes, the dependency graph,
every `std:` / leaf reference with its type), and compiler-core embeds it (`std_units.bin`); `get()`
reads it (`deserialize`) and no compiler process cuts std-wasm; `built()` cuts it now (the tool's,
and the test that the embedded blob is the one the sources cut). `coreFor` starts the core's memory with
more pages by rewriting the one memory line and section (`withMinPagesText` / `withMinPagesBinary`,
equal to the model's rendering by test). Under `wasm_units` the CLI writes `std@__rt.wasm` and each unit
the program reaches beside its `.wat` (`build.zig` `writeRuntimeUnits`, a file already holding the bytes
left alone), and `zig build std-wasm` writes them all into `zig-out/lib/std-wasm/`.

**The core** holds what is no std module's:

| The core exports | The program unit |
|---|---|
| `memory` — `0..256` the print helpers' scratch, std-wasm's data at 256 and its stack, then from `Runtime.end` the program's data, then the heap | imports it and exports it again as its own `memory` (what the component's adapters read); its `min_pages` the pages its data reaches, and the composition starts the core's memory with that many (`Runtime.coreFor`: the reserve is sized at link time, no fixed limit) |
| `__heap_ptr` (mutable), starting at `Runtime.end` | imports it; a module with data of its own starts with `$__bp_reserve`, which moves it past that data, then calls the start it had (`reserveData`) |
| `__alloc` | imports it when it holds the `alloc` group |
| `fd_write`, `random_get` (forwarded to `wasi_snapshot_preview1`: the one unit importing the host's WASI), `__wasi_random_f64` | imports them from `std@__rt` |
| `__bp_panic`, `(param anyref)` | a GC module with exceptions imports it; a linear-memory module declares its own `(param i32)` tag |
| `__std_sp`, `__std_sp_check` (std-wasm's stack), and the decoded helpers several std units share, by their symbols | — |

**A std unit** holds one std module's functions: std-wasm's `root.units` names the std module of each
std-wasm module (`text` → `string`, `number`, `bytes`, `array`, `bigint`, `heap`, `hash`, `encoding`,
`random` → `io/random`, `fs` → `io/fs`), and the unit exports its decoded functions as
`std:<module>.<function>`, its `.wat` leaves as `wat:<module>.<function>` (symbols `__wat_<m>_<f>`,
apart from a decoded function of the same name), read against the canonical prelude rec group
(decision 1021 (9)) it declares alone, with the prelude's marshal helpers and `$__random_state` it
names. It imports the core's memory, globals and functions, the functions of the units it calls (by
symbol) and its own host functions (`std@io@fs` imports `bp_fs`). A decoded helper goes to the one unit
whose walk from its exports and leaves reaches it (the walk stops at another unit's export, which is an
import), else to the core with everything it calls. Today's graph (`Runtime.graph`): every unit imports
the core alone, but `std@array`, which imports `std@number`; the core holds 17 shared helpers.

A program unit imports each std-wasm function and each leaf it calls from its unit, under the symbol
its calls name (`(import "std@number" "std:number.floatToString" (func $__std_number_floatToString …))`,
a leaf typed as the module reads it, so `finishGc` renumbers it with the module's types); a leaf's
prelude names are its unit's, never the module's (`noteLeaf`). The runtime's needs (the core's GC and
exceptions, a leaf unit's GC) are its own `botopink.needs`: a program unit's section stays what its
bindings reach (decision 518), and a run takes all of them (`needs.needsOfText` unions every section of
the component; `codegen/runtime.zig` adds the preloaded units'). The component frame renders `$rt`,
then each reached unit `$std@<path>` in dependency order (`Runtime.closure`), then `$main`; instantiates
`$rt` with the preview 1 shim, each unit with `$rt`, the units it imports and `$fs_shim` when it imports
`bp_fs`, and `$main` with `$rt` and its units. `codegen/runtime.zig`'s RUN LOG runs a module that imports
the core as `wasmtime run --preload std@__rt=std@__rt.wasm --preload std@<path>=… <module>` (their
bytes in the cache key). Not in the core yet: the scheduler's globals, the shared function table and the
type registry (P4); `$__write_bytes` and the GC print helpers stay with the program unit (they name its
per-program capture state). `modules/compiler-cli/tests/wasm_runtime_unit.sh` and
`wasm_std_unit_per_module.sh` (cell `wasm_std_unit_per_module`) are the oracles.

## std-wasm in the program (decisions 440, 441, front 144 B-00e)

On `wasi` and in the snapshots std-wasm is std's units' (§ The runtime core and std's units); what
follows is how it is linked into a `browser` module, and how the units are decoded.

std's functions written in Zig (`modules/std-wasm`) are the program's own: a
`#[@external(.Wasm(std: "<module>.<function>"))]` binding, a primitive method whose
`std:` cell `primitives.bp` writes (`String.trim` / `trimStart` / `trimEnd`,
`Float.toString` — `wat.zig` `std_method_exports`, held to the cells by
`codegen/tests/wat.zig`) and every float turned into text call a std-wasm
function, and `emitWat` transpiles the ones the module calls
(`Emitter.std_exports`, plus each held prelude group's `HelperGroup.stdCalls`)
from `std_wasm.wasm` into it (`std_wasm_link.zig`): one module, its
`.wat` the whole program, the binary from the same model, no import and no host
change. Its layout, after the program's interned data:

    256 … data floor  the program's data
    base              std-wasm's data (Ryu's tables, its literals, its `var`s), 8-aligned —
                      only when a linked function addresses it (`__memory_base`)
    … top             std-wasm's stack, sized from its frames; `$__std_sp` starts at `top`,
                      and a frame reaching below the stack's floor traps (§ The stack)
    top …             the heap: `$__heap_ptr` starts at `top`, `memory` has the pages `top` needs

A module that calls no std-wasm function links nothing and is unchanged.
`$__str_trim`, `$__f64_fmt` and the bignum `$__dtoa` group left the prelude
with B-00e; every other helper that only computes over values left it with
B-00g (§ What stays in `wat_prelude`).

Size, measured 2026-10-11 against the parent compiler (`browser` host for the
binary, which a `wasi` build writes as component text only):

| Program | Before | After |
|---|---|---|
| hello world (`@print("hello, world")`) | 530-byte binary, 4 444-byte `.wat` | the same bytes — nothing linked |
| `@print(1.5)` | 2 865-byte binary, 31 071-byte `.wat` | 7 202-byte binary (+4 337), 75 123-byte `.wat` |
| std's `hash` module (`botopink build --target wasm` in `libs/std`, the one std module that changes) | 15 537-byte binary, 140 053-byte `.wat` | 18 079-byte binary (+2 542), 167 975-byte `.wat` |
| onze's blog (`examples/blog`, `wasi`) | the page refused (std `json`, `io/fs`; 05-wasm step 5's group 3); of its modules that build, five change | refused alike; `actions/id` 140 747 → 168 745, `css/sheet` 124 643 → 128 712, `onze-assets/style_module` 173 652 → 201 628, `onze-bundler/scan` 78 244 → 82 214, `std/hash` 146 400 → 174 322 bytes of `.wat` |

The cost is std-wasm's float text (Ryu's code and tables against the bignum
transcription it replaces); `contentHash` and `trim` are smaller than the
bodies they replace.

## std-wasm's `.wat` leaves (front 164 s3, decision 549)

A leaf is a hand-written function of `modules/std-wasm/wat/*.wat` — `(func $<module>.<function> …)`,
one file per leaf or small group, each listed in `build.zig` (`std_wasm_leaf_files`) and embedded as
`std_wasm_wat/<file>` (`std_leaves.files`). `host_binding.parse` of `std: "<module>.<function>"`
answers a `Std` binding carrying std-wasm's export (`wasm`), the leaf (`leaf`), or both while the
export stays. A **WasmGC module** calls the leaf: `emitStdCall` (a primitive method's call, a `std:`
wrapper's) pushes the values as the module holds them and calls `$__std_<module>_<function>` — no
marshal, nothing in linear memory —, records it in `Emitter.std_leaves`, and `emitWat` reads each
recorded leaf (`std_leaves.read` over `wat_reader.read`), with the leaves it calls, into the module
as ordinary functions: a leaf nothing calls is never in the module. A **module lowered in linear
memory** keeps std-wasm's export (§ std-wasm in the program); a `std:` cell naming a leaf with no
export is refused there, and in a GC module its declaration's types must be the leaf's
(`checkLeafSignature`). A leaf is GC code: the operand-stack type check reads it
(`isLinkedStdFunc` skips only std-wasm's linear functions).

`wat_reader.zig` reads what `wat_emitter.zig` writes: `(func $name (param $p <type>)… (result
<type>)? (local $l <type>)… body)`, the body flat (`local.get $s`), folded (`(i32.add (local.get $a)
(i32.const 1))`) or structured (`(block $l (result t)? …)`, `(loop …)`, `(if (result t)? <folded
condition>… (then …) (else …)?)`); numeric opcodes from `host_binding`'s table, the GC instructions
of the model, `call` of another leaf by its `$<module>.<function>`. A leaf names the codegen's types
— `$str`, `$arr_i32`, `$arr_f64`, `$arr_any`, `$box_i32`, `$box_i64`, `$box_f64`, `$result` — which
`Emitter.leafTypeIndex` resolves (declaring the type in the module's group on first use); every
reference is `(ref null …)`. A `(type …)` or `(rec …)` form is refused at the declaration, and so is
anything the model has no node for (a memory instruction, a numeric local or label, a flat
`block … end`): a located error, `modules/std-wasm/wat/<file>:<line>:<col>: <message>`. Today's
leaves: `text.length`, `text.charCodeAt`, `text.byteLength`, `text.byteAt`, `text.byteSlice` and `text.fromCodepoint` (`text.wat`), `number.i32ToString`, `number.i64ToString` and `number.u64ToString` (`number.wat`, with their internal body `number.decimal`; a GC module's `print_i64` / `print_u64` groups register the two 64-bit leaves and write their `$str` through `$__print_str_raw`, so the groups need `print_str`, `gcDeps`, and link no `number.i64Text`); the unit test `std_leaves: every leaf
reads` reads each against the codegen's type names. Front 164 s3 P2-d / P2-e (decision 585): `bytes.length`, `bytes.at` and `bytes.ofWords` (`bytes.wat`), `random.float`, `random.seed` and `random.seededFloat` (`random.wat`). A leaf may also name the prelude's own functions and globals, never declare them (`std_leaves.prelude_funcs` / `prelude_globals`: `$__wasi_random_f64`, `$__random_state`): the reader's `Names.global` and `callee` answer only those, `Emitter.noteLeaf` requires the helper group each stands for (`wasi_random_f64`, `random_state` — the `i64` global holding Mulberry32's word, `-1` before a seed) when the leaf is called, and `wat_prelude.gcItems` has their GC forms.

## What stays in `wat_prelude` (decision 442, front 144 B-00g)

`wat_prelude.zig` keeps what defines a value's representation or talks to the
host; everything that only computes over values is Zig, transpiled into the
program as std-wasm is (§ std-wasm in the program).

**A `String` method bound by `fn:` (decision 565, front 164 s3 P1-b).** A `String` method whose wasm
cell is `#[@external(.Wasm(body: <name>))]` is a call of `<name>`, a private bodied fn taking the receiver
first and then the method's parameters, of the same types (`hostFnBinding.resolve` over the method seen
as a fn, `stringMethodAsFn`): `lowerPrimMethod` asks `stringFnCellOf` before any other lowering and
`lowerStringFnCell` emits the call. A program's own `behavior String` member is registered with its body
(`registerSymbols` → `registerStringFnCell`, `Emitter.string_fn_cells`; `primRes` and `optInfoOf` read
the body's declared return, so a `?string` prints as absent). A member of `primitives.bp` is read from
the prelude at the call (`preludeStringFnCell`): its body, a private fn of `primitives.bp`, is adopted
with every private fn it calls (`adoptPreludeHostFn`: a bodied private prelude fn registered and queued
in `spec_pending`, a refusal inside it reported at the call), and where the method keeps a
`std_method_exports` row the body's answer is converted to what that row's std-wasm call leaves.
`primitives.bp` binds none of its methods so yet (decision 566: after s2 P5); `codegen/tests/wat.zig`
proves the path over a program module.

**The rule for a new helper (442 (3)).** It stays in `wat_prelude` when it
reads or writes the layout the codegen decides (a box, an array's or a
string's cell, a value's header, the heap pointer) or talks to the host (a
WASI call, the `@Async` protocol); it is Zig — a function of
`modules/std-wasm`, with its Zig unit tests — when it only takes values and
answers values. A std declaration whose types a `std:` cell spells carries the
cell (`primitives.bp`, `std_method_exports`); a function whose arguments are
the codegen's own (code point bounds, slot words by element kind, an integer
by its carrier, a `bigint` block) is a `root.program` entry the codegen calls
by name (`Emitter.stdCall`).

**What stays (442 (1)).** Memory and representation: `alloc` (the program's
one heap — std-wasm imports it as `env.bp_alloc` and never brings its own),
`box_i32` / `box_f64` / `box_i64`, `arr_at_box`, `arr_new`,
`arr_push`, `arr_at`, `str_concat`, `str_eq`. The arithmetic
operators: `int_chk`, `u64_chk`, `i32_range_chk`, `i64_range_chk`, `i32_abs` /
`i32_min` / `i32_max`. Output: `print` (`fd_write`, `$__write_bytes`, and
`$__print_i32`'s digits through scratch `64..128`), `print_str`, `print_bool`,
`print_opt*`, `print_shaped`, `print_tagged`, `print_unknown`, `display_of`,
and the I/O half of `print_f64` / `print_i64` / `print_u64` / `print_arr_*` —
the text is std-wasm's (`HelperGroup.stdCalls`). The language runtime: the
`@Async` scheduler (`task*`), `unknown`, `assert_fail`. And the host's
entropy, `wasi_random_f64` (`random_get`): it talks to the host (442 (3)),
and std-wasm's seeded stream draws it before any seed (decision 451 (2)).

The `HelperGroup` list, checked against 442 (1) after the seeded stream left:
`print`, `print_str`, `print_bool`, `print_f64`, `arr_at`, `str_concat`,
`str_eq`, `alloc`, `i32_abs`, `i32_min`, `i32_max`,
`arr_new`, `arr_push`, `print_arr_i32`, `print_arr_f64`, `box_i32`,
`arr_at_box`, `print_opt`, `print_opt_f64`, `assert_fail`, `panic_fail`, `print_shaped`
(with `$__print_tagged_raw`), `print_opt_tagged`, `display_of`, `unknown`,
`print_unknown`, `wasi_random_f64`, `box_f64`, `print_i64`, `box_i64`,
`print_opt_i64`, `int_chk`, `i32_range_chk`, `i64_range_chk`, `print_u64`,
`u64_chk`, `print_opt_u64`, the `task*` groups and `bigint` (no function: the
marker that swaps in the shaped printer's `n` code). `str_slice` and `mem_eq`
are gone (decision 455): no lowering called them once `s[a..b]` and `s[i]`
became std-wasm's `text.slice`.

**What left (442 (2)), now std-wasm's** (`modules/std-wasm/AGENTS.md` has each
function): the text helpers (`str_split`, `str_replace`, `str_pad`,
`str_lines` / `str_words`, `str_cp_*`, `str_from_cp`, `str_char_code`,
`str_index_of` / `str_last_index_of`, `str_starts_with` / `str_ends_with`,
`str_repeat`, `str_at`, and `str_case` — the ASCII shift that left `é`
unchanged at exit 0, now `text.toUpper` / `toLower` over all of Unicode,
decision 443), a number's text (`i32_to_str`, `i64_to_str`,
`u64_to_str`, `int_fmt`, `u64_fmt`, `f64_to_str`), the array helpers
(`arr_reverse`, `arr_slice`, `arr_concat`, `arr_prepend`, `arr_zip`,
`arr_fill`, `arr_join_*`, `arr_index_of_*` / `arr_last_index_of_*`,
`arr_unique`, `arr_flatten`, `arr_chunked`, `arr_sliding`), `bigint`'s
twenty-one `bn_*` (`bigint.zig`) and the seeded random (`wasi_seed_state`,
`wasi_seed_u32`, `wasi_seeded_f64` and the adapters `wasi:seed_u32` /
`wasi:seeded_f64`, now `random.seed` / `random.seededFloat` bound by `std:`
cells on `io/random.bp`, decision 451). Every wasm RUN LOG and `run/` cell answers
as before (the 43 codegen snapshots that linked one show each function as one
hash line, decision 446).

**The stack (decision 447).** `$__std_sp` is the program's one stack — std-wasm's
frames only, live for the call that made them; the codegen keeps every value in
wasm locals or on the heap (`$__alloc`) and never puts one on it, as erlang keeps
a term on the process heap. `std_wasm_link.zig` sizes it at link as the deepest
path of frames among the functions the program links (recursion is refused
there, so the path is finite) and places it between std-wasm's data and the
heap. **An overflow traps:** every frame-taking function's prologue (`global.get
$__std_sp; i32.const N; i32.sub`) passes the new pointer through
`$__std_sp_check`, which traps (`unreachable`) when it lies below the stack's
floor — signed, so a frame larger than the pointer traps too — and a read of the
stack pointer that is no prologue is refused at link, so no frame escapes the
check. The other way 447 (3) allows — the stack laid out first, below every data
segment, so that going past its end is an out-of-bounds access — was not taken:
it moves the print helpers' scratch (`0..256`) and the data floor (`256`, which
is also the heap-floor test `heap_floor` that tells a pointer from an ordinal) by
a size known only after linking (the stack's size depends on what the program
links), rewriting every data address in every wasm snapshot. The check is one function (nine lines) beside
`$__std_sp` in each module that links a frame-taking function and one `call` per
prologue inside the transpiled bodies (which a snapshot shows as one hash line,
decision 446). `tests/wat.zig` drives a frame past the stack's end and expects
the trap.

The check and the seeded stream's move (decision 451), measured 2026-10-11
against the parent compiler (`browser` host, binary and `.wat` bytes):

| Program | Before | After |
|---|---|---|
| hello world | 530, 4 444 | byte for byte the same — nothing linked |
| `@print(1.5)` | 7 303, 76 087 | 7 327 (+24), 76 358 — the check and one `call` per prologue |
| a `bigint` program (`modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_arithmetic`) | 13 428, 142 849 | 13 477 (+49), 143 420 |
| `seed(42)` then `@print(seededFloat())` | 10 429, 108 232 | 10 489 (+60), 108 808 — the stream is std-wasm's, its state a `.bss` word in std-wasm's data |

A program that links std-wasm's data at all carries the stream's state with it
(the data is placed whole, § std-wasm in the program): the heap of the four
codegen snapshots that link it starts 16 bytes later.

Size, measured 2026-10-11 against the parent compiler (`browser` host for
the binary):

| Program | Before | After |
|---|---|---|
| hello world (`@print("hello, world")`) | 530-byte binary, 4 444-byte `.wat` | byte for byte the same — nothing linked |
| `@print(1.5)` | 7 202-byte binary, 75 123-byte `.wat` | 7 303 (+101), 76 075 |
| text methods (`split` / `join`, `indexOf`, `replaceAll`, `padStart`) | 1 996-byte binary, 20 678-byte `.wat` | 3 542 (+1 546), 36 939 |
| `@print("straße é".toUpper())` (decision 443) | 708-byte binary, 6 387-byte `.wat` — and it printed `STRAßE é` | 11 899 (+11 191), 243 380 — `STRASSE É`: the case tables are code (`case_tables.zig`), linked only where case is mapped, never std-wasm data |
| a `bigint` program (`modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_arithmetic`) | 12 021-byte binary, 124 781-byte `.wat` | 13 428 (+1 407), 142 837 |
| onze's blog (`examples/blog`, `wasi`): the page refused alike (std `json`, `io/fs`); its 59 modules that build | 2 581 307 bytes of `.wat` | 3 006 854 (+16 %): 30 modules change, e.g. `routing/match` 135 437 → 154 055, `std/encoding` 88 294 → 111 861, `actions/state` 93 319 → 117 079 |

The cost is Zig's code against the hand-written WAT it replaces, and the
heap starting past std-wasm's stack (`std.mem.indexOf`'s table is a frame).
std-wasm's data (Ryu's tables, the integer workspace) is placed only when a
reached function addresses it. A decoded function's nesting indents its lines
to column 40 at most (`std_wasm_link.zig` `deeper`): LLVM lowers the case
tables' `switch`es to hundreds of nested blocks.

## How far a program grows without collection (decision 448, front 144 B-30)

`$__alloc` bumps `$__heap_ptr` and never frees: every value a program makes
stays in linear memory until the program ends. Measured 2026-10-12, before any
collector was designed (448: the design follows this), on the compiler at
`feat`, each program built `--target wasm` (`wasi`) and run by `wasmtime` with
`-W max-memory-size` bisected to the smallest memory (64 KiB pages) the run
completes in. The live data of every program below is a few integers: what
grows is garbage.

| Program | N | Smallest memory | Growth |
|---|---|---|---|
| hello world | — | 1 page | — |
| a loop building one string per iteration (`"item-" + i.toString() + "-" + "payload"`, its length summed) | 10³ · 10⁴ · 10⁵ | 64 KiB · 640 KiB · 6 656 KiB | ~68 bytes per iteration, linear |
| a request loop: a request line parsed (`split`, a record), a response built (`join`, `toUpper`, concatenation, the length's text), its length summed | 10³ · 10⁴ · 10⁵ | 704 KiB · 6 976 KiB · 70 976 KiB | ~727 bytes per request, linear |
| the same loop as `@Async`s: `serve(n) -> @Async<i32>` awaiting `handle(i) -> @Async<string>` per request | 10³ · 10⁴ · 10⁵ | 320 KiB · 3 200 KiB · 32 768 KiB | ~335 bytes per request (the task record and its frame included), linear |
| a page render: ten records of three nodes each (`attrs`, `children`) rendered to HTML by `map` / `join` / concatenation, ~950 bytes of HTML per page | 10² · 10³ · 10⁴ | 1 664 KiB · 16 704 KiB · 171 840 KiB | ~17.6 KiB per page (18 times the HTML it answers), linear |

- **Linear in the work, whatever the live set.** A server answering the
  request loop's requests reaches wasm32's 4 GiB after ~5.9 million requests,
  the page render after ~240 000 pages; a host that caps memory lower stops it
  sooner.
- **Exhaustion traps today.** At the cap, `memory.grow` answers `-1` and
  `$__alloc` executes `unreachable` (the request loop under a 32 MiB cap:
  `wasm trap: wasm 'unreachable' instruction executed` in `__alloc` ←
  `__str_concat`); decision 448 (4) keeps that, never damaged data.
- **Values are not written after they are made.** `push` answers a copy with
  the element appended (`$__arr_push`; quadratic in a loop of pushes, which the
  page render's ten cards pay), concatenation and every std-wasm function
  answer fresh blocks: a block never points at a younger one. The exceptions
  are the language runtime's own records — a `@Async` record (state, waiters,
  value) and its frame are written after they are made — and a `var`'s cell
  (448 (2)).
- **onze's pages do not build on wasm**: `examples/blog` (`wasi`) is refused
  in 67 modules — its element library's element module (`the wasm backend walks an array or a
  range; nothing shows this iterable is one`), std's `json` and `io/fs`
  (`fs.readText` has no `.Wasm(…)`). The page render above is their
  shape (an element tree rendered to a string); onze is measured when its pages
  build.

## `Bytes` (decision 346)

A `Bytes` is laid out as a string is — the address of its `u32` byte count, the bytes behind it —
and is no string: `primCallRes` answers `.i32` for its methods, never `.str`, so nothing prints it
as text. `Bytes.fromUtf8(s)` is the string's own address (`isBytesFromUtf8`; both are immutable),
`length()` the count word, `concat` `$__str_concat`, `slice` std-wasm's `bytes.slice` (byte bounds,
`slice`'s normalisation; an absent end the largest `i32`), and `toUtf8()` the same address in an
`Ok` once std-wasm's `bytes.isUtf8` accepts it, else the `Error` text the other targets write
(`lowerBytesMethod`). `typeRefOf` / `resultShapeOf` answer `Bytes` and `@Result<string, string>`
for those calls. `==` / `!=` read inference's `prim = .bytes` at the operator and compare through
`$__str_eq`. `stdSpelling` spells `?Bytes` for `encoding`'s decoders' `std:` cells. A `Bytes`
build constant (decisions 519, 520: `@embed`'s `Asset.bytes`, a `comptime`'s lifted `Bytes` — the
AST's `bytesLit`) is a data segment of its raw bytes in the string layout (`internString`).

## `bigint` — the runtime library (decision 332, front `01-compiler/139` step 4)

A `bigint` is the address of an immutable block, `[L][limb0][limb1]…`: `L` the limbs' byte count
(four per limb), negated for a negative value and `0` for zero; the limbs little-endian `u32`s with
no zero limb on top, so one value has one spelling. A literal (`lowerBigintLiteral`) is its
magnitude interned as a data segment — the string layout, its length word the `L` of a positive
value (`-5n` is a negation); a segment that is no UTF-8 text writes its bytes past ASCII escaped
(`wat_emitter.zig` `dataSegment`). Every operation allocates its answer: std-wasm's `bigint.*` (`modules/std-wasm/src/bigint.zig`,
decision 442 (2)), transpiled into the module, the codegen passing the blocks' addresses — the
limbs are the Zig module's own business:

| std-wasm function | What |
|---|---|
| `bigint.add(x, y, flip)` | `x + y`, or `x - y` when `flip` (sign and magnitude) |
| `bigint.negate`, `bigint.multiply` | `-x`; `x * y` schoolbook over `u32` limbs with `u64` carries |
| `bigint.divmod(x, y, rem)` | `x / y` truncated toward zero, or `x % y` with `x`'s sign; a zero `y` traps — by one limb through `divWord`, by more a bit at a time |
| `bigint.compare`, `bigint.equalOptional` | `-1` / `0` / `1`; `==` over two `?bigint`s (absent both, or present and equal) |
| `bigint.ofI64`, `bigint.toI64`, `bigint.toF64` | `bigint.of(n)`; `toI64()` traps past the range, `toF64()` unless exact (≤ 53 significant bits, below 2^1024) |
| `bigint.toString`, `bigint.parse` | decimal text (chunks of 10^9); a numeral of `bigint.parse` (`+`/`-` then digits), `0` for none — `lowerBigintAssoc` builds the `@Result` pair and its `Error` text |

Their Zig unit tests and a property test against `std.math.big.int` (carry, divmod, the text
round-trip) are `zig build test`'s. Size: § What stays in `wat_prelude`.

What reads a `bigint` (`isBigintExpr`, from `typeRefOf`: a literal, an operator inference typed
`bigint` — `isBigintAt` —, `bigint.of`, a fold over one, an `if` answering one, a declared type):
`lowerBinOp` (`lowerBigintBinOp`, before the string and structural rows), `lowerNeg`, `+=` on a local
or a field, `@print` and a string operand (`bigint.toString`), the methods (`primCallRes`' `.bigint`
rows, `PrimRes.i64` for `toI64`), a number pattern and a range bound (by `bigint.compare`). In a
container the slot holds the address: the print shape `n` (`typeRefShape`, `fieldShape`; `?n` for
a `?bigint` field) is read by `print_shaped_raw_bigint`, the shaped printer the module substitutes
when it holds the group (`print_shaped_items_bigint`), and `$__eq_<T>`, a tuple's `==` and an
array's compare it by `bigint.compare` (`emitValueEq`, `emitTupleEq`, `eqTypeOfShape`); an array's
element is a pointer (`elemIsPointer`), so `xs.at(i)` / `xs[i]` answer it unboxed, `0` its absence.
A `?bigint` prints `null` or the digits. Refused, located: a `bigint` in a union
(`lowerAsUnknown`, "has no `bigint` in a union yet" — erlang, beam and commonJS run it; the checker
keeps a `bigint` out of `unknown` and out of `is`). `modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_arithmetic`,
`modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_in_containers`, `modules/decisions-taken/bigint_decimal_strict_json-332/cells/bigint_to_i64_aborts` and `modules/decisions-taken/bigint_decimal_strict_json-332/cells/bigint_division_by_zero` (`.exit`
alone: a trap writes no text) run here on both hosts.

## String indices count codepoints (decision 240)

A string is `[byte count][UTF-8 bytes]`; `length`, `at`, `slice`, `indexOf`,
`lastIndexOf`, `s[i]` and `s[a..b]` count **codepoints**, as erlang and beam do
(decision 169 on the fourth target), so an index one answers is one another
reads. `lowerStringMethod`, `lowerIndex`, `lowerStrSlice`, the `.length` of
`lowerCollectionMethod` and `lowerIdentAccess` call std-wasm's `text.length`,
`text.at`, `text.indexOf`, `text.lastIndexOf` and `text.slice`, which count
the bytes that are not `10xxxxxx` continuations; `text.slice` normalises its
bounds as `slice` does (a negative one from the end, clamped, an end before
the start is the start), so an open end is the largest i32. `modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_index_of_codepoints`:
`"a—bXc".indexOf("X")` is `3` and `.at(3)` is `X` on four targets (it was `5`
and a broken byte on wasm).

## A function value bound by a `val`

`val g = greet` with no written type types `g` by `greet`'s declaration
(`fnRefTypeRef` at the `.localBind`, and for a module-level `val` in
`registerSymbols` / `typeFnValueGlobals` once every signature is known), as a
written `fn(…) -> string` already did — so `g()` prints the string, `y()` a
bool. It printed the string's address (`256`) at exit 0
(`modules/fn/cells/fn_value_bound_by_val`).

## The carrier of a `?T` (`00 · 05-wasm`, 1.0.10-beta)

**`arrayElemOpt` is the one place that decides what `xs.at(i)` / `xs.first()`
answers, and both the writer and the reader take their answer from it.** A
payload that is already a POINTER — a string, a record, an array, a tuple — is
its own offset, and `0` is absence; only a scalar (an integer, a bool, a float)
goes in a `$__box_i32` cell, because a present `0` has to be distinguishable from
none. While the two sides decided separately — `lowerArrayMethod` picking
`$__arr_at` or `$__arr_at_box`, `optInfoOf` reporting the shape — a RECORD
element fell between them: `ElemKind` cannot tell a record from an integer (both
are an `i32` slot), so the element was WRITTEN boxed and READ as a bare pointer,
one indirection short at every reader. Every line of it answered a heap address
at exit 0:

| Written | Was | Is |
|---|---|---|
| `es.at(0)?.key.length()` | `276` | `3` |
| `val k: string = first.key;` inside `if (first != null)` | `272` | `abc` |
| `@print(es.at(0))` | `296` | `Entry(key: "abc")` |
| `rows[1][0]` over `[[1, 2], [3, 4]]` | `0` | `3` |

Four readers had to learn the same thing, and each is named where it sits:

- **`elemRecordOf`** answers the record type an array's elements name — an array
  literal of constructor calls, a local or global bound to one, a declared
  `Entry[]`, and the array methods that keep their receiver's elements
  (`keepsElements`). `arr_elem_recs` / `arr_elem_rec_globals` carry it per name,
  beside `arr_elem_locals`, because `ElemKind` has no room for it.
- **`elemIsPointer`** answers the other pointer element — an array or a tuple —
  off the print shape (`[[i`, `[(is)`), which is the one place a nested container
  is already tracked.
- **`recordTypeOfExpr`** recovers the record through `xs.at(i)` / `xs.first()`,
  and through `a ?? b` (the transform pass writes that as `if (a) { <this> ->
  <this> } else { b }`, so the binder is what tells it from an ordinary `if`, and
  the default arm is the one that names the type). That is what makes
  `(es.at(9) ?? Entry(key: "zz")).key` a declared `string` and not a number.
- **`elemKindOf`'s `identAccess` arm** reads the field's declared type instead of
  answering `.i32` unconditionally, so `self.cells.at(0)` over a `cells:
  string[]` field is a `?string` and not a boxed `?i32`.

**A name a `!= null` test narrows is its PAYLOAD for the branch**
(`narrowed_opts`, `collectNullTestNames`, `applyNarrowing`/`dropNarrowing` in
`lowerIfExpr`). Inside the branch `optInfoOf` answers nothing for that name and a
boxed payload is loaded at every read — the same unboxing the optional-binding
form `if (ns.at(0)) { n -> … }` has always done. `!= null` narrows the then
branch, `== null` the else branch, `&&` both of its halves on the holding side
and `||` both on the failing side; only a bare NAME is narrowable, which is the
limit the checker draws too. Without it a narrowed `?i32` was read as its box and
`n + 1` answered a heap address at exit 0. `00 · 01-checker` owns the checker's
half of this rule; this is only the carrier's.

**`$__print_opt_tagged`** (+`_raw`) is the printer a `?T` whose `T` is a record
takes: the tagged printer reads a header four bytes behind the value, so absence
has to be answered before it is called. Its own helper group, last in declaration
order, so a module that never prints one renders exactly as it did before.

**A loop's and a HOF's element parameter carries the element's record type**
(`lowerCollectionLoop`, `lowerArrayHof`, both through `elemRecordOf`). The
binder is one ELEMENT, so `for (es) { e -> @print(e.key) }` and
`es.filter({ e -> e.n > 1 })` need the record type or the field read falls to
the unique-field guess and prints the field's ADDRESS — `284` for `"abc"`, exit
0. Two `local_types` registrations, at the two binders.

`modules/decisions-taken/shorthand_import_refused-337/run/src/cases/optional_record_carrier` pins the whole family on all four targets, and
`modules/optional/cells/optional_length_method` lost its `.targets` sidecar with it.

**A `case` used as a VALUE is a string in BOTH arm spellings** (`armIsString`).
A BRACE arm — `case x { 5 { "five" } … }` — parses its body as a parameterless
block, which reaches codegen as a lambda node; a lambda VALUE is a closure
pointer, so `isStringExpr` said no, `val a = case …` was typed `i32` and
`@print(a)` wrote the arm's heap address (`256`) at exit 0. The ARROW spelling
(`5 -> "five";`) was right all along, which is what made the defect
syntax-dependent. `armIsString` is the only position allowed to look through a
lambda node, and `modules/case/cells/case_value_string_arms` pins both spellings on four
targets.
A brace arm with a binder (`_ { n -> "max " + n.toString(); }`) is a lambda node
with one parameter, and `armIsString` reads its block too (`armLambda`): it
said no, and `val s = case d.age { 3 { "three"; } _ { n -> … } }` printed the
string's address. `modules/case/cells/case_binder_arm_string_value`.

**A `map`'s element shape is asked with the element bound** (`holdElemParam` /
`releaseElemParam`, in `elemKindOf`'s `map` arm). The shape of `es.map({ e ->
e.key })` is decided before the lambda is lowered, by asking `isStringExpr` of
its tail — and `e`'s record type used to be registered only inside
`lowerArrayHof`, so `e.key` was a field of an unknown name, the result an `i32`
array, and `ks.at(0)?.length()` read the box as a string pointer (`276`, exit
0). The parameter is bound for the question and released after it. Beside it,
**an optional-binding `if` is a string when EITHER arm proves it**
(`isStringExpr`'s `.if_` arm): `a ?? b` is written as one, its payload arm reads
a binder nothing typed, and requiring both arms made `["x", "yz"].at(1) ??
"none"` print the string's address. `modules/map/run/src/cases/map_record_field_strings` and
`modules/map/run/src/cases/map_record_field_length` pin both.

**A method on the rest of a `?.` chain runs under the chain's guard**
(`lowerChainedCall`, `00 · 05-wasm` step 9). `?.` short-circuits everything
after it, but only the link written with `?.` carried the guard: in
`es.at(1)?.key.length().toString()` the `length()` read a length from address 0
when the entry was absent (the WASI iovec, exit 0) and `toString()` found no
receiver type at all and trapped. A primitive method whose receiver continues a
`?.` chain (`isOptionalChain`) is now lowered as `recv; tee; eqz; if (result
i32) 0 else <unbox a boxed receiver; the method on it; box a scalar result>`,
the receiver's family read off the chain (`chainPayloadKind`: the previous
guarded link's result, a field's declared type, a string). The whole expression
is the `?T` the checker typed — `optInfoOf` answers it (`chainedCallOpt`) — and
prints `null` or its value. A float result has no box here and keeps the
unguarded path. `modules/optional/run/src/cases/optional_chain_method` pins it. The link written with
A field written as an array read through `?.` is an array payload
(`chainPayloadKind`: `m?.list.join(",")` resolves `join/1`, the payload bound with its
element shape — `modules/meta/cells/meta_list_method_on_optional`), and `elemKindOf` reads a `o ?? d`'s
elements off the optional's type, an empty `[]` default adding none
(`(m?.list ?? []).join(",")` joins strings as strings — `modules/meta/cells/meta_list_coalesced_method`).
A lifted lambda keeps the `rewrites`, `instance_lowerings` and `global_renames` of the module
it is written in (`Lifted.rewrites` / `lowerings` / `renames`, swapped in by `emitPendingFns`): it is
lowered after its module's declarations, when the emitter holds another module's, and a linked
component's `5.toString()` or `[1, 2].map(Card)` lost their primitive methods
(`modules/array/run/src/cases/array_map_component_imported`, `modules/decisions-taken/component_value_is_hooks_node-389/cells/decl_hooks_dynamic_call`).
`?.` itself (`s?.length()`, `find(k)?.contains("x")`, `xs.at(i)?.slice(1, 3)`)
is lowered the same way (`chainedCallKind`: the plan inference recorded, else
the family of the receiver's `?T` payload — its type, or a string element's
`OptInfo`); an absent `s` read a length off address 0
(`modules/decisions-taken/optional_typescript_operators-330/run/src/cases/optional_method_absent_receiver`).
`recv?.m(args)` over a method of a record or an enum the program declares is
guarded the same way (`lowerOptionalTypedMethod`, `optionalTypedMethod`): the
receiver once, `0` when absent, else `<Owner>_<method>` called on the payload
(the optional's payload type names the owner, so nothing dispatches by value —
an all-unit enum's ordinal has no header to dispatch on), its answer boxed as a
`?R` of the method's declared return (`optionalTypedMethodOpt`, also what
`optInfoOf` answers; `wasmTypeOf` says `i32`), a method answering an optional
left as it is. Unguarded, an enum's dispatcher trapped on an absent receiver, a
record's method read its fields off address 0, and a present `0` read as absent
(`modules/decisions-taken/optional_typescript_operators-330/run/src/cases/optional_record_method_absent_receiver`,
`modules/decisions-taken/optional_typescript_operators-330/cells/optional_enum_method_absent_receiver`).

A `val c: ?T = …` keeps the VALUE's carrier (`opt_locals` from `optInfoOf` of
the initializer, not only when unannotated): `cs[1]` over an all-unit enum's
array is a box, and read as the bare ordinal `c == Color.Green` answered
`false`. An optional-binding `if`'s binder is the then-arm's name only
(`restoreBinderFlags`): every `a ?? b` binds `__bp_nullish`, and a string
payload left in `str_locals` made the next `??` over an `i32` print as a
string. `conformance/modules/decisions-taken/negative_index_counts_from_end-139/run/src/cases/index_answer_typed_optional`. A binder of another
width than the local its name already holds (`x ?? 0.0` after `n ?? 0` in one
function) is a local of its own the arm's reads resolve to (`binder_alias`), and
the `if`'s value type reads the binder's width off the condition
(`ifValueType`), not off the stale local.

`recv?._N` — decision 45's `?.label` over an optional tuple — reads the element
only when the tuple is there (`lowerOptionalField`, as a record field's `?.`): a
scalar element goes in a box (a present `0` is not absence), a float's or an
`i64`'s slot is its cell, a string or a container its own pointer, an element
that is itself optional its own carrier (`optInfoOfElemShape`, from the
receiver's payload shape, `optTupleElemShapeOf`). It loaded from address `0`
and answered whatever the WASI iovec held (`8`).
`conformance/modules/decisions-taken/optional_member_access_needs_safe_call-45/run/src/cases/tuple_label_through_absent_optional`.

A record's `?f64` (`?i64`) field holds the `?`'s box — the value's cell, `0`
absent — and is read as that box, not as the field's number (`fieldCellIn`: an
optional field has no cell of its own to load; the constructor, a field read, a
destructuring `val`, whose binder is an optional local, and `wasmTypeOf` all ask
it). Read through the bare name (`fieldTypeIn` drops the `?`), `F(x: null)`
stored a `0.0` cell and `f.x` loaded the `f64` into `$__print_opt_f64`, which
validation refused. `conformance/modules/record/run/src/cases/record_optional_float_field`.

A `?Place` over an enum with a payload variant is the variant's tagged cell or
`0`, and prints through `$__print_opt_tagged` (`optPayloadEnumOf`: a local, a
field, a call); the integer printer answered the cell's address and `null` as
`0`. A leading-dot unit variant names its enum's descriptor (`dotIdent`): with
the enum unnamed it carried descriptor `0` and printed `R(q: )`.
`conformance/modules/optional/cells/optional_payload_enum_value`.

## Two run-time rules this backend implements first (2026-09-19)

**No loop has a value** ([decision 105](../../../../../../../specs/1.0.10-beta/decisions-taken.md),
superseding decision 55's value `break`): `break <v>` belongs to a generator
scope and ends it — `emitGenBreak` appends `v` and branches out of the
`iter` loop's `$__gen{n}` block, or returns a generator fn's array; a bare
`break` at a generator fn's own level ends it the same way (`emitGenEnd`,
decision 103); a bare `return` in a generator fn does the same from any arm
(`conformance/modules/decisions-taken/lambda_answers_last_expression-541/run/src/cases/case_arm_return_in_yielding_arm`).

**A loop's label is read** (front 164 s2c): `wat.zig`'s `loop_stack` holds the
loops being lowered with their labels (`for :outer (…)`). A labelled loop gets two
extra blocks: `$__lbrk_<label>` around its `$__break` block and `$__lnext_<label>`
around one iteration's body, and `emitLoopJump` sends `break :label` /
`continue :label` there — out of every loop between, running the defers of each
iteration crossed (`LoopFrame.floor`); a bare jump, or a label no loop carries,
still branches to the innermost `$__break` / `$__next`. A `case` arm's block is no
closure, so its jumps take the same `br`; `bodyContinues` looks for a `continue` through `if` branches, blocks and
`case` arms, so a bare `continue` there wraps the iteration in `$__next` as a top-level one does. `conformance/modules/block_jump_label_*`,
`block_continue_reaches_loop`.

**A range pattern tests both ends** ([decision 53](../../../../../../../specs/1.0.5-beta/decisions-taken.md)):
`1...9` arrives as a `.variant` whose `shape` is `.range` with the two bounds in
`payload.literals`; before `emitPatternTest` read the shape it fell into the
variant-tag path, found no variant named `""` and answered `0` for every value.
Now it is `subj >= low and subj <= high` (`emitRangeBound`), a float bound
truncated like a `numberLit` pattern's; a string bound has no ordering here and
answers `0`. `conformance/modules/case/cells/case_range_value` pins the five points.

**A `case` subject keeps its wasm type** (`lowerCase`). A subject is lowered as
`wasmTypeOf` says (`i64` for an `i64`, a `u64` and a `u32`; `f64` for a float), its
`__case_<d>` local declared as that type, and not coerced to `i32` — which refused the
`case` (`would narrow this i64 value to an i32 slot`). In a multi-subject `case` each
subject's own local (`multiSubjectLocal`) takes its own type, so an `i64`, `u64` or `f64`
among several is compared whole. A number pattern against such a subject is `<ty>.const`
+ `<ty>.eq`, a range bound `<ty>.ge_s` / `le_s` (`ge_u` / `le_u` for a `u64` subject,
`u64_subjects`, so a value past `i64`'s top is above the bounds; `ge` / `le` for a float), and
a binder or an arm's lambda parameter takes the subject local's type (`bindPattern`,
`lowerArmBody`). `conformance/modules/case/cells/case_wide_integer_scrutinee`.

## The value knows its own declaration (2026-09-21, `13-module-identity` half 3)

**Decision 22** put the box on every backend, wasm included. A value a
declaration builds now carries a **descriptor header**: one `i32` holding the
address of a data blob the emitter interned, written at the allocation's base
with the VALUE being `base + 4`. The header is BEHIND the pointer on purpose —
every field offset is what it was, so no read moved and nothing in the
`optInfoOf`/`uniqueFieldOffset` family had to learn a new shape.

The descriptor is length-prefixed, because a wasm loop reads a byte and
advances:

    'R' <n> Name       <k> [ <n> field <shape…> ] * k     a record
    'V' <n> Enum.Var   <k> [ <n> field <shape…> ] * k     ONE variant

A field's shape is the same self-delimiting code `$__print_shaped_raw` walks,
and that function answers the address just past it, so the descriptor stores no
length for it. A record's fields start at the pointer; a variant's start one
slot in, because slot 0 holds the ordinal the `case` arms test. **One
descriptor per variant, not per enum**: a variant IS a declaration for the
purpose of identity, and that is what lets the printer name `Shape.Circle`
without walking past the variants before it.

A field written as one of the declaration's type parameters (`value: T`), or as
an array or a tuple of one (`items: Array<T>`, `kids: T[]`), has the shape `G`
(`isGenericField`), and a value of a generic declaration carries one more slot
after its fields: the address of its `G` fields' argument shapes, one after
another in field order, interned by the construction site (`genericShapes`,
each `valueShapeOf` its argument). The descriptor stays one per declaration, so
identity tests are untouched; `$__print_tagged_raw` walks those shapes (`q`) at
each `G`. `Q(items: [7])` over `Q<T>(items: Array<T>)` printed `Q(items: 308)`,
and `B(v: o)` over a `?i32` the box's address
(`conformance/modules/generic/run/src/cases/generic_record_prints_its_arguments`). A `?T` field keeps
its declared box shape, a record or enum argument its header. A value built where
the argument's shape is unknown (a parameter typed `T` of a generic body) reads
as a word, `i`.

* `$__print_tagged_raw` (in the `print_shaped` group, because the two call each
  other) writes decision 8 §7's text: `Point(x: 1, y: 2)`, `Shape.Dot`,
  `Shape.Circle(radius: 4)`. The shape walker gained a `T` arm that calls it, so
  a container of records names each element's type — `[Point(x: 1, y: 2), …]` —
  read from each element's own header, not from the print site. A field whose
  declared type is an enum with a payload variant is `T` too, and an optional
  field is its payload's `?X` / `!X` (`fieldShape`: `?Place` is `?T`, `?Target`
  over an all-unit enum `!E…`, `?string` `?s`); each fell to `i` and printed the
  cell's address (`place: 316`). `@print` of a name or a field DECLARED as such
  an enum (`payloadEnumOfName`, read before `namedShapeOf`) is the tagged
  printer for the same reason (`modules/imported/run/src/cases/imported_enum_field`).
* `x is T` and a `case` arm naming a type are `subj >= 256 && load(subj - 4) ==
  <descriptor>`, an enum's variants joined by `or` (`lowerIsCall`,
  `emitNamedTypeTest`). The bounds guard is load-bearing: an `i32` that is not a
  pointer would otherwise read four bytes of whatever sits below it.

**What this backend still cannot do, and why it refuses rather than guessing:**

* **A variant of an ALL-UNIT enum has no header.** `Color.Red` is `i32.const 0`
  with no allocation, so there is nothing four bytes behind it. `is` over such
  an enum is refused, and so is dispatch by value over one. Boxing it would
  make `Color.Red == Color.Red` a pointer comparison, which is a worse answer
  than none.
* **A value whose type nothing proves cannot go in the box** — a type
  parameter's slot (`Maybe.Some(value: v)` over a `T`: nothing monomorphises
  here, so `v` is a raw `i32` that may be a pointer), a result nothing typed.
  `lowerAsUnknown` refuses (`cannot box this value as `unknown``) rather than
  boxing a guess, which would answer `is` and `==` wrongly — in a generic body,
  the concrete call that reaches it unspecialised is refused instead
  (§ Where this backend refuses to answer).

**Decision 8 §11's box — `unknown` and unions over primitives** (`00 · 05-wasm`
step 2 D1–D4). A value entering an `unknown` or union slot (`boxesInto` /
`lowerBoxedInto` — a `val` annotation, an argument, a return, a field, an
assignment) carries a header behind its pointer, the SAME header C-01 gave a
declared value: a record or a variant already has one and goes in as it is; a
primitive is boxed — `[descriptor][payload]` (`lowerAsUnknown`), the descriptor
`'P' <n> name` (`primDescriptorAddr`; `i32`, `f64` with an 8-byte payload,
`bool`, `string`, `array`, `tuple`) — and `null` is `0`. One field answers both
"which primitive" and "which declaration", so 13's named-type tests read an
`unknown` value unchanged. The readers are the prelude's `unknown` group:
`$__unknown_kind` (the descriptor's tag, or the primitive name's first letter),
`$__unknown_int_in` (§4.1 by value: a boxed `i32` in range, or a boxed `f64`
that is a whole number in range — `3.0 is i32`, `300 is i8` false),
`$__unknown_as_i32` / `_f64`, `$__unknown_eq` (§2.3: numbers by value, strings
by content), and `$__print_unknown` (+`_raw`). `x is T` over a primitive puts
its operand in the box and asks (`lowerIsCall` → `emitPrimTest`); `if (x is T)`
reads an unboxed alias of `x` inside the branch (`narrowUnknown`); a `case` over
an `unknown` subject tests a primitive-type arm and binds its payload unboxed
(`unknown_subjects`, `arm_unbox`) — as a plain identifier it was a binding that
matched everything (`number 364`, a heap address). `conformance/modules/unknown/run/src/cases/unknown_by_value`
pins it on four targets.
A run-time type token (decision 758, `__bp_type_token(T)`) is the address of a static blob
(`typeTokenAddr`): `[0][n][d0]…` the type's descriptors, or a primitive's test (`[1][lo][hi]` an
integer type, `[2]` a float, `[3]` `bool`, `[4]` `string`, `[5]` `unknown`); `x is t` over one
puts `x` in the box and calls `$__is_type_token` (group `is_type_token`, over `unknown`). A GC
module has no address for it and falls back to linear.
A TUPLE in the box (`boxTupleAsUnknown`) is `[desc "tuple"][the tuple][arity][box 0]…`:
the tuple stays the payload's first word, and each element goes in an `unknown`
box of its own, typed from the literal's elements or the tuple type's, so
`x is #(i32, string)` (`lowerIsTuple`) tests the arity and then each element as a
primitive or named `is` does — by value, `#(2.0, "a") is #(i32, string)` holds.
An element nothing types (a nested tuple, a function, an `i64` cell) writes arity
`-1`, and `is` over that box traps. An element of an `unknown[]` walked by
`map`/`filter`/… is an `unknown` local (`elemTypeRefOf`), not a value to box.
`conformance/modules/is/run/src/cases/is_truth_table` holds §4.1 × §4.2 on four targets.

**§7's `Display` half is answered by the module, not the descriptor**
(`00 · 05-wasm` step 1 F4). `$__print_tagged_raw` first asks `$__display_of(v)`
for the text `v`'s own `display(self) -> string` answers and writes it when it
is not `0`. The prelude's `display_of` group answers `0` for every value, so the
group renders alone; `wat.zig`'s `displayDispatch` substitutes the module's own
form whenever a record type has both a descriptor (some value of it was built)
and a `<Type>_display` method: one `v >= 256 && load(v - 4) == <descriptor>`
compare per such type, calling the method. It is written after lowering, from
the interned descriptor addresses, rather than as a table index stored in the
descriptor — table indices are handed out as lambdas are lifted, so one interned
during lowering would shift. `conformance/modules/display/cells/display_print` prints `$5`
and `[$1, $2]` on all four targets. An enum's methods are not consulted, as on
commonJS (`js/AGENTS.md` § What a value is).

**A method called through a behavior-typed value is answered the same way**
(`lowerBehaviorDispatch`, `behaviorDispatchFunc`). Where inference placed the
receiver on a behavior (`.by_value`, the behavior's own name) or nowhere (a
lambda parameter typed by an alias naming it), the call is `$__bdispatch_<method>_<n>`,
written after lowering like `$__display_of`: one header compare per descriptor
of each record and payload-enum variant declaring `<Type>_<method>` with the
same signature, calling it, and `unreachable` for a value none of them built.
The first implementer's symbol answers the shape queries (`resolvedCallSym`:
a string, a bool, an array's elements), since every implementer answers the
behavior's one declared type. A record recovered from the receiver expression
is no longer used for a behavior call — `Array<Request>`'s elements were all
read as the first literal's type. A lambda written against a declared function
type also types a record parameter (`Lambda.param_rec`), so `out.tag` reads
`Out`'s slot. `conformance/modules/behavior/run/src/cases/behavior_method_dispatch_by_value`.
`exprTail` reads the same first implementer's signature for a call inference
placed (`.by_value`, or a `.type_` naming no record or enum): a method declared
with no return pushes nothing, so a function ending in `c.close()` takes no
`(result i32)` it never fills (`conformance/modules/behavior/run/src/cases/behavior_method_no_return_by_value`).
A `.by_value` method whose name a function of the module or its imports also
holds (`r.find(1)` beside std `context`'s `find`, which the scope lowering links)
dispatches by the value before the function is considered
(`behaviorMethodShadowsFn`, in `lowerPlainCall` and `resolvedCallSym`): the
function took the receiver's place and answered `0`.
`conformance/modules/decisions-taken/inject_rides_context_tree-416/cells/context_behavior_method_find`.
A `.by_value` call answers what its implementers declare when every one declares the
same (`byValueRetTypeRef`, read first by `typeRefOf`): the dispatcher calls
`<Type>_<method>`, so `m.at(k) ?? -1` on an `Index<string, i32>` reads `Registry.at`'s
`?i32` as the box it is — it read the box's address. And a `slice` dispatched by value
(`answeredByValue`) is not the string slice the untyped fallback `isStrSlice` takes,
in `lowerExpr` and `isStringExpr` alike (`conformance/modules/decisions-taken/negative_index_counts_from_end-139/cells/ambient_index_parameter`).

**A `@Result`'s `map` / `flatMap`** inline their closure (`lowerResultOptionOp`).
A function named as a value (`r.flatMap(half)`, a local holding one) is the
closure `{ v -> f(v) }` (`resultClosureArg`). The shape of the call's answer
(`resultShapeOf`) reads the closure's tail with its parameter bound to the
receiver's `Ok` payload (`bindLambdaParamType`) — a `map` over an `i64` payload
was read as a word and printed the cell's address — and a `flatMap` answers its
closure's tail's shape. Inside the body the parameter carries the payload's type
(`local_typerefs`), so a primitive method on it (`{ n -> n.toString() }`) finds its
family where inference recorded no lowering (`primKindAt`).
`conformance/modules/result/run/src/cases/result_i64_map_flat_map`.

**Every header read is guarded against a value below the heap floor**
(`emitHeaderLoad`): wasm's `i32.and` does not short-circuit, so `x is T` and a
`case` arm's type test loaded `subj - 4` for an all-unit enum's ordinal too —
out of bounds for `0`. The address is `(subj - 4) * (subj >= floor)`. A `case`
arm whose name is BOTH a record of the module and some enum's variant
(`type Block(…)` beside `Token.Layout { Block, … }`) tests both — the record's
header, `or` the variant's identity (`emitVariantIdentityTest`: an all-unit
ordinal, or a payload variant's descriptor, never a load of a record's first
field as a tag); `conformance/modules/case/cells/case_arm_record_named_like_a_variant`.

**An all-unit enum's value prints by name** (`unitEnumOf`,
`unitEnumShape`): its value is the ordinal, with no header, so the print shape
carries the names — `E k [ <n> Enum.Variant ] * k`, which `$__print_shaped_raw`
indexes by the ordinal. A member written by its path, a name, a parameter, a
field, a call and an `if` value typed by the enum take it, as do an array, a
tuple and a record field of one (`typeRefShape`). `?Color` is a BOX like
`?i32` (`optInfoOfTypeRef`): unboxed, a present `Color.Red` (ordinal `0`) was
absent. A literal trapped and a name printed the ordinal
(`conformance/modules/unit/cells/unit_enum_print_by_name`).

**A `case` reads a bare or dot-shorthand arm in its subject's enum**
(`enumOfSubject` → `subject_enums` → `case_enum_hint`, read by
`findVariant`): a parameter, a local, a call typed by the enum, `self`, and a
section written as a path (`Token.Layout.Break` → `Bp__Token__Layout__Break`).
Set for the WHOLE subject only — a payload's own pattern keeps the
program-wide lookup. One flat table answered the first enum declaring the name
(`modules/variant/run/src/cases/variant_leading_dot_two_enums_case`,
`modules/enum/run/src/cases/enum_section_leaf_beside_variant`).

**A multi-subject `case a, n { … }`** lowers each subject once, into
`<subject local>_<i>` (`multiSubjectLocal`); a `.multi` arm tests and binds
each pattern against its own subject, a primitive type over an `unknown`
subject by its box. It tested nothing, and the first arm answered every call
(`modules/decisions-taken/multi_subject_bare_name_refused-602/cells/case_multi_subject_patterns`).

**A record's constructor pattern** (`val assert Person(n, a) = p catch …`)
tests the value's header (`recordPatternType`, `emitNamedTypeTest`) and binds
each name from the field it stands at, by label when one is written
(`recordPatternField`, `recordFieldAccess` — the ordinary field read, a boxed
float included). It tested and bound nothing
(`modules/val/run/src/cases/val_assert_record_pattern`). Each binder carries the field's whole
declared type (`noteFieldBinder` → `noteTypedBinder`, as a parameter does), so
`Dog(age: a)` over `age: ?i32` is a `?i32` and `"${a ?? 0}"` unboxes it — read
as a plain word it printed the box's address
(`modules/case/cells/case_record_labelled_fields`).

**A generic call answers its argument's shape** (`generic_result_arg`,
`genericResultArg`): `fn ident<T>(x: T) -> T` has one body, so `ident("a")`
is a string, `ident(true)` a bool, `ident(P(…))` a `P` — every shape predicate
asks the argument. `o.unwrapOr(d)` answers the payload's shape — an
`@Result`'s declared payload, the optional's own, else a container default's
(an empty `[]` says nothing) — so `r.unwrapOr([])` over an `@Result<Array<#(
string, string)>, …>` and `rows.at(1).unwrapOr(#("", ""))._1` print their
strings, not addresses (`modules/std/run/src/cases/std_querystring_on_every_target`). A string
printed as its address (`modules/generic/run/src/cases/generic_call_result_shape`); a string, a bool
or a float bound to a type parameter calls a specialisation (above).

**A function named as an array method's argument** (`xs.map(inc)`, an imported
fn, a local holding one) is inlined as the lambda `{ p -> inc(p) }`
(`hofLambdaAt`), the arity the method hands it. It trapped (`map needs a literal
lambda`; `modules/hof/cells/hof_named_function`).

**A value `if` has its own type** (`ifValueType`, `emitBranchValue`): an arm
yielding a float makes it an `f64` wherever it stands, each arm converted to
it. It took the enclosing function's result type, so an `f64` `if` in a
function answering nothing was `(if (result i32)` around two `f64`s — the
module refused (`modules/if/run/src/cases/if_value_float`; `testing.asserts.approxEquals` binds
one). With no float arm it is the first arm's integer type, not the function's:
`val d = if (c < 58) c - 48 else c - 87` in a function answering `f64` was
`(if (result f64)` around two `i32`s (`tests/wat.zig` `an integer
if-expression inside a float function`; `std/hash`'s `hexValue`).

## Decision 8 §5's pattern shapes (`01-compiler/05-wasm` step 3, C-07's wasm twins)

Three pattern shapes had no wasm test, and two of them answered at exit 0:

| Shape | Was | Is |
|---|---|---|
| a tuple pattern in a `case` (`#(0, s)`, `#(a, ..)`, `#(#(0, b), s)`) | refused — `` `` names no variant `` | `emitTuplePatternTest` / `bindTuplePattern`: each element that tests something is loaded from its slot (`i * 4`, no header) and tested in the chain a variant's payload literals use; a binder takes the element's shape (`noteTupleElemLocal`: a string prints as text, a float is read from its slot's cell); `..` skips the rest |
| a list pattern (`[]`, `[x]`, `[1, b]`, `[a, ..rest]`) | **irrefutable** — `[x]` took a `[]` arm, exit 0 | `emitListPatternTest`: the length (exactly the elements, or at least them with a spread), then each number literal; `bindListPattern` binds each element by the array's element shape and a named spread to std-wasm's `array.slice(xs, n, …)`. Only `[..]` / `[..rest]` is irrefutable (`patternIsIrrefutable`) |
| `true` / `false` inside a pattern | a **binder** named `true` — every arm matched, exit 0 | the bool literal (`isBoolLitName`): `subj == 1` / `subj == 0` |
| `null` inside a pattern (`Box(label: null, n: k)`) | a **binder** named `null` — every arm matched, exit 0 | the absent word (`isLitPatternName`, never a binder): `subj == 0` (`modules/case/cells/case_record_field_null`) |

The subject local carries what the patterns read (`noteSubjectShape`, in
`lowerCase` and `lowerAssertPattern`): a tuple's or an array's print shape,
an array's element kind. A tuple pattern over a subject whose element types
nothing knows, and a float element or list element against a literal, are
refused by name. A tuple or list binder has no instance lowering from
inference at its loc, so `primKindAt` reads its declared element type
(`tuple_binders`) — `#(n, "x") { n.toString() }` was an `unresolved call`
trap. Five `val assert [..] = …` / `case_list_patterns_*` wasm snapshots moved
(their text — the length test and the binders — not a RUN LOG; each program
re-run with prints, answering erlang's values).

**A payload typed by a type parameter takes the subject's argument**
(`subject_generic`, `substSubjectParam`, `payloadFieldLocal`): a `case` over a
value written `Maybe<#(i32, i32)>` records the subject's written type, and a
variant pattern's nested pattern (`.Some(#(a, b))`) is bound from a payload read
as the argument (`#(i32, i32)`) instead of the bare `T`, so a tuple pattern finds
its element types (`conformance/modules/case/run/src/cases/case_generic_variant_tuple_payload`; it
was refused as "does not know the element types of this tuple pattern's
subject").

The fixtures are `tests/wat.zig`'s `a tuple pattern tests its literals and
binds its elements`, `` `..` skips the rest and a bool literal in a tuple
pattern is tested ``, `a type pattern is chosen by the value` and `a list
pattern tests its length and literals and binds the rest`, each RUN LOG
erlang's and beam's for the program. The rows another backend answers
differently are named at the fixture: commonJS emits `const true = …` for a
bool in a tuple pattern, answers `other` for an enum type arm over a variant,
tests no literal in a list pattern and answers a function for a brace arm
over one (`04-js`); erlang binds `true` (`02-erlang`); beam leaves list
binders unresolved (`03-beam`).

## A generic payload and a union value in an `unknown` slot (decision 8 §3.2, §5.1 P5, §5.3)

A payload declared as a type parameter (`Some(value: T)`) has no type of its
own in the backend, which does not monomorphise; `unknown` boxing needs one.
What is typed, and where:

| Where | What the backend does |
|---|---|
| a generic enum constructor written where its value is an `unknown` (`val s: unknown = Maybe.Some(value: "abc")`, an `unknown` argument, a return) | `ctor_box = .all`: `lowerEnumCtor` boxes every payload declared as one of the enum's type parameters (`lowerAsUnknown`, by the argument's static type) — `boxesInto` / `isGenericEnumCtor` |
| the same constructor where a `Name<…>` with an `unknown` / union argument is expected (`innerSize(Maybe.Some(value: "abc"))` over `Maybe<i32 \| string>`) | `ctor_box = .args`: only the parameters whose argument is an `unknown` / union are boxed (`ctorUnionArgs`, `ctorBoxes`) |
| `bindPayloadName` | a payload declared as a type parameter is typed by `tparamArgOf`: the matching argument of the subject's recorded `Name<…>` type (`lowerCase` records the subject's `typeRefOf` for its `__case_<n>` local), else the `unknown` of an `unknown` subject; a binder of an `unknown` / union is an `unknown` (`local_typerefs`), of a plain type an ordinary typed binder |
| `case` / `if` in an `unknown` slot (`return case m { … }` in a fn answering `i32 \| string`; `val v = if (c) 2 else "two"`) | the value of each arm goes in on its own: `pending_case_box` → `case_box` read by `lowerArmBody`, and `lowerBoxedIf` with `force` for an `if`. Each arm is boxed by the checker's type of that arm when the checker typed the `case` / `if` a union (`InstanceLowering.union_value` at its loc, decision 150 — `unionValueOf`, `unionArmTypes`; `pending_case_arms` → `case_arm_types` → `arm_box_as` → `box_as`, which `lowerAsUnknown` reads before the value's own shape), else by the one type the whole `case` / `if` is boxed as: a block arm's tail a local nothing annotates (`Circle(r) { val d = r * 2; d; }`) is boxed by it, where it was refused ("nothing gives it a static type here"). An unannotated `val` bound to such a `case` / `if` is a local typed by the recorded union (`local_typerefs`), its value boxed arm by arm — whatever the arms' shape (values, blocks, lambda arms), over an `unknown` subject, in a state machine; before the record, a probe re-derived the arms' members in the backend and missed every shape but plain values, and `case v { i32 {…} string {…} }` read a string's address as a number at exit 0 (`conformance/modules/case/cells/case_value_union_binding`, `conformance/modules/decisions-taken/mixed_literals_infer_union-150/run/src/cases/case_if_union_value_shapes`) |
| `case x { Pat when (v is T) { … v … } }` | `emitGuardChain` narrows `v` in the arm body as `if (v is T)` does in its block (`narrowUnknown`) |

A typed generic value that flows into an `unknown` without being a constructor
there (a `Maybe<i32>` local passed to an `unknown` parameter) keeps its raw
payload; a `case` over it binds the payload as the `unknown` its subject
makes it, which it is not — the box of such a value is not rebuilt (a
`case_exhaustive`-shaped design the specs have not fixed). `unknown_subjects`
is re-decided on every `case` (`__case_<n>` names repeat across functions; a
stale entry read a later `case n { i32 { m -> … } }` as a test of an `unknown`).
Fixtures: `tests/wat.zig`'s `a type parameter's slot matched out of an
unknown is an unknown` and `a field read on a guard-narrowed type parameter's
slot`; the cell `conformance/modules/unknown/run/src/cases/unknown_generic_payload`.

## A re-binding is a local of its own (decisions 152, 205)

Decision 152 refuses a second binding of one name in one body, and decision 205
makes the body the whole function: an inner block's `val`, a loop's binder and a
`case` arm's binder over a name visible there are the checker's
`binding-redeclared`. What reaches this backend is a lambda — a function of its
own — binding a name its enclosing function holds (a parameter, or a `val` of
its body), and sibling blocks each binding one name. A wasm function is ONE
local namespace and a HOF's lambda is inlined into it, so the lambda's
`val k = "lambda"` wrote the outer `$k`, and `k` read after the call answered
the inner value (the pre-pass `emitLocalDecls` also registered the inner
binding's shape under the shared name, so the outer `k` printed as the string).
Now:

- `bindTarget` gives a `val` / `var`, a `for` binder (`lowerCollectionLoop`,
  `lowerRangeLoop`) and a HOF binder (`lowerArrayHof`) the name itself, or a
  fresh `<name>__sh<n>` when a parameter (`isParamLocal`) or a binding of an
  enclosing, still open statement list (`bound_names`) holds it;
  `installShadow` aliases the name to it once the value is lowered
  (`val x = x + 1` reads the outer one);
- `scopeMark` / `scopeRestore` undo both at the end of each statement list
  (`emitBody`, `emitBranchValue`, `emitIterationBody`, `inlineLambdaBody`,
  `lowerArmBody`, the two loops and `lowerArrayHof`), so a sibling block's
  binding reuses its local exactly as before — no snapshot moved;
- a `case` binder over such a name goes through `bindName`, which aliases it
  too; an arm's binders are undone by restoring the aliases as they were
  before the arm (`restoreAliases`) instead of clearing every alias, which
  also dropped a re-binding around the `case`;
- `emitLocalDecls` registers nothing for a re-binding — its lowering (`emitStmtRaw`) does,
  under its own local.

`tests/wat.zig` `a lambda's binding shadows the outer one only inside it` pins
the shapes the checker keeps, its RUN LOG commonJS's (erlang and beam answer
it too). The
inner-block and `case`-arm halves of the machinery stay, though a checked
program no longer reaches them.

**A lambda's bindings are its own** (decision 205: a lambda body is a
function of its own). An inlined HOF body's `val k` and its parameter `e`
over an enclosing `k` / `e` take the same `bindTarget` local and are undone at
the body's end, so the enclosing names keep their values;
`conformance/modules/decisions-taken/shadowing_in_inner_blocks_refused-205/run/src/cases/lambda_binds_name_of_enclosing_fn` (02-erlang's cell)
pins it on four targets. A lifted lambda (`{ e -> e * 2 }` as a value) is a
function of its own already.

## `defer` on wasm (decision 539, front 164 s2b)

`Emitter.defer_stack` holds `DeferEntry`s: the statement, the aliases its names had at the `defer` (names bind there,
the value is read late — `writeDefer` puts them back while it lowers the code, so a `val` written later over a
module-level name, which `bindTarget` gives a local of its own, is not the one it reads), and `ran_flag`.

- **Where a `defer` is built.** Every statement list that keeps the stack goes through `emitStmtsFrom`: `emitBody`, a
  loop's iteration, a `case` arm (`lowerArmBodyStmts`), an `if` branch answering a value (`emitBranchValue`,
  `lowerBoxedArm`), an inlined lambda (`inlineLambdaBody`, a `forEach`'s body). A list that answers a value passes a
  `LastHook`: its last statement is lowered and converted by the site inside the panic region, whose result type is
  the type the site hands on (`Repr`); a block other than the function's own takes it from the last expression.
- **A panic in the block** runs the block's defers: the region is `emitDeferRegion` whatever list holds the `defer`,
  with exceptions on.
- **Once.** An inline exit (`runDefers`: `return`, `break`, `continue`, `try`) inside a region sets the entry's
  `ran_flag` before writing its code; the handler writes the code only while the flag is `0`, so a deferred statement
  that panics on the exit path is not run again by the region it sits in. The flag is cleared at each entry of the
  region.

## Function values, and the lowering that is not there

**A function value in an `unknown` slot is boxed under its arity** (decision 254).
`lowerAsUnknown` puts a lambda, a top-level fn named as a value or a name declared
`fn(…) -> R` (`fnValueArity`) in a tagged box whose descriptor is the interned
`'P' <n> "fn/<arity>"` (`fnDescriptorAddr`) and whose payload is the closure cell.
`x is fn(<params>) -> T` compares that descriptor (`lowerIsCall`), and the branch it
guards reads the closure out of the box through an alias typed by the tested
function type (`narrowUnknownFn`), so `lowerValueCall` — which loads the callee
through `resolveName` — applies the cell and answers `T`. The arity is all the
test can read back: a closure cell carries no parameter or return types.

**This backend has function values.** A lambda used as a value is lifted into
`$__lambda{n}(env, a0, …)`, listed in the module's `(table funcref (elem …))`, and
applied with `call_indirect`; the value itself is a pointer to an environment cell
holding the table index and one 4-byte slot per capture. A top-level fn used as a
value gets a `$__fnref_<name>` trampoline. Five shapes, all answering as commonJS
does: a lambda in a local, a lambda passed as a `fn(…)` parameter, a top-level fn
passed or bound, and — since front 05 step 7 — one read out of an **aggregate
slot**, `t._1(2)` / `o.step(10)` / a labelled element the checker resolved to its
position (`c.set` → `_1`). That last was the only gap, and the reason the trap it
left read as "wasm has no function values".

**Calling the result of a call** — `adder(3)(4)` (01 handover 15) arrives with
the callee in `calleeExpr` and `callee == ""`; `lowerValueCall` lowers that
expression and applies it like any other function value. What the call answers
is the function type's return (`valueCallTypeRef`, for a `calleeExpr` and for a
local or global declared — or bound to a call declared — `fn(…) -> R`), which
is how `greeter("a")("b")` and `f("b")` after `val f = greeter("a")` are strings
to the printer rather than their heap address. The lambda such a fn returns is
typed from the declared return: `expected_fn`, set at a `return { … }` and at an
annotated `val f: fn(…) -> … = { … }`, gives `lowerLambdaValue` its parameter
types, so `{ x -> p + x }` under `-> fn(x: string) -> string` concatenates.
A lambda written as an argument of a call to a plain fn is typed the same way
from the parameter's declared function type (`expected_fn` set per argument in
`lowerPlainCall`), so `{ n -> n.startsWith(p) }` for `gone: fn(name: string) ->
bool` has a string `n` (cell `lambda_arg_param_type`).

**Three record/array recoveries onze's blog on wasm needed** (cells
`children_for_walk`, `unwrap_or_record_field`): a record field declared
`Children` is the `[len][e0]…` blob of the array the program built (the
coercion is type-level only), so `for (e.children)` walks it (`isChildrenTyped`
in `isArrayExpr`; the element is an untyped word); and `r.unwrapOr(d)` /
`o.unwrapOr(d)` answers the record of its default, else the `@Result`'s declared
ok payload (`recordTypeOfExpr`), so a field read off it never falls to the
unique-field guess that refuses a name some record declares as a float.

**A pattern in binding position** — `val Circle(r) = s;` / `val Sq(side) = q;`
— reads each binding off the slot of the declared field at its position (a
record from offset 0, a variant through `bindPattern` from offset 4). The checker
(01 R5) lets through only a pattern that cannot fail, so there is no test. It
used to fall to "unsupported destructure pattern" and bind nothing — `0`, exit 0.

**A lambda handed straight to an array method is not lifted**: `lowerArrayHof`
inlines its body into a counted walk, which is what lets `forEach` assign an outer
local.

**There is no block-as-value lowering to delete** — the row 1.0.4's note opened,
measured on 2026-09-18:

| Measurement | Count |
|---|---|
| `;; lambda` in `../wat.zig` and all of `wat/**` | **0** |
| sites that make a function value | **3** — `lowerExpr`'s `.function` arm, `lowerValueCall`'s trailing lambdas, `lowerFnRef` |
| of those, sites a **block** can reach | **0** |

The one producer that ever lifted a block was the `case` arm: a `Pattern { … }`
arm arrives as an `ast.Expr.function`, and lowering it as a *value* put the body in
the table and left the arm answering a closure-cell address
(`case_or_patterns_with_block_arm_body` recorded `$__lambda0` plus a 4-byte cell).
`lowerArmBody` inlines it instead. Its binder (`DogB { d -> … }`) is the
record a tested arm names when the arm names one (`arm_record`, set by
`emitArmChain`, read and cleared by `lowerArmBody` so a nested `case` binds its
own), else the subject's type: over a `DogB | CatB` union it took the subject's,
which a union has none of, and `d.name` printed an address
(`modules/case/cells/case_record_union_binder`). A block `{ … }` (decision 525; `@block`
is removed) is a `case true { _ { … } }` (`ast.CollectionExpr.case.isBlock`),
lowered as any `case`; `exprYields` / `exprHasYield` read its body in place, and
the `case` string classifier skips an arm whose block ends in a `return` /
`throw` (`bodyTail(…) == .terminated`), so a block whose tail is a `case` with a
returning arm concatenates as a string (`modules/decisions-taken/brace_without_arrow_is_block-525/run/src/cases/block_return_leaves_function`).

`blockReturnValue` reads an `async { … }` block's first returned value (its
tail is the block's `return`, decision 525) for `asyncBlockValue`, the shape the
classifiers read a task's value with.

## Methods, binders and the module body (`00 · 05-wasm`, the rows no step named)

Each of these answered `0` at exit 0 or trapped where the other three backends
answered, and each was a red wasm cell of `conformance`:

- **An enum's methods are emitted** (`registerInterfaceSigs` / `emitInterfaceMethods`
  take every `type`, not only records): `Shape.Rect(…).counts(3)` was an
  `unresolved call` trap. An enum's associated fn called on the type
  (`Shape.unit()`) is `assocSym`'s, as a record's is — it took the variant path
  and answered `0 ;; unknown variant`. `exprReferencesSelf` walks a `case`'s
  subject and arms, so `fn name() { case (self) { … } }` gets its `$self`.
- **A method declared `-> @Iter<T>` / `-> @AsyncIter<T>` accumulates its
  yields** (`methodYieldsEagerly` → `renderAccumulatingBody`), as a fn does; its
  body was rendered plain, every `yield` dropped.
- **`opt.map({ x -> … })` is a registered optional** (`optInfoOf`): boxed when
  the closure answers a scalar, a pointer otherwise — what
  `lowerResultOptionOp` builds. Unregistered, a `return` into `-> ?i32` boxed
  the box (an address printed), and a `map` answering a string was read one
  indirection too far by the `flatMap` after it.
- **A program's own `default fn` of a primitive behavior is called**
  (`prim_defaults`, `primBehaviorKinds`, `lowerPrimDefault`): a `default fn`
  with a `self` in the program's `behavior String` / `Bool` / `Number` /
  `Integer` / `Signed` / `Float` is registered per primitive kind it
  covers (the kinds of the widths whose `implement` clause reaches it,
  `prelude_cache.kindsReaching`, decision 617 (1)), and a call on such a receiver whose method the table does not list
  is a copy of the default with `Self` written as the receiver's primitive
  (`String_tailShout__string`, `Number_clampTo__i32`), emitted once through
  the member path (`emitMemberFn` marks a primitive-typed `self`), the
  receiver as `self`. `primRes` reads its declared return for every shape
  predicate. Inside such a copy — any specialisation — a primitive method's
  result is typed by what it answers (`typeRefOf`), so `self.max(lo).min(hi)`
  and `val tail = self.slice(1); tail.startsWith(…)` find their primitive.
  Every program-declared default of a primitive trapped (`prim method not
  lowered on wasm`). An `Array<T>` default's copy writes `Self<T>` (and a
  bare `Self`) as the receiver's array type and `T` as its element
  (`ensurePrimDefault`, `primArrayElemName`: a record, a bool by its shape,
  else the element kind — `Array_second__arr_string`); `substTypeParams`
  replaces a generic `Self<…>` whole for it, `emitMemberFn` marks an array
  `self` and, inside any copy, types each parameter by its written type, and
  the call answers the copy's declared return (`typeRefOf`, so a `?T` result
  is the optional its element makes).
- **A primitive method on a call inside an adopted default** reads the
  callee's declared return (`primKindAt`'s fallback): inference typed the
  default's body against `Self`, so `self.twice().toString()` in `Sq`'s copy
  of `Shape.label` had a type variable for a receiver and no lowering —
  `unresolved call: toString/0`, a trap in `Sq_label`. `Sq_twice -> i32` says
  it is an integer; the fallback answers only a primitive whose table has the
  method (`modules/behavior/run/src/cases/behavior_default_adopted_by_two_types`, 02-erlang's cell).
- **A type adopts its behaviors' `default fn`s** (`adoptedDefaults`,
  `methodsWithDefaults`): each one the type does not write is emitted as its own
  `$<Type>_<method>`, through `extends` too — `Money(…).clamp(lo, hi)` over
  `Bounded`'s default and `Bag(…).isEmpty()` through `Counted extends Sized`
  were `unresolved call` traps. A method call on a record value answers the
  record its declared return names (`recordTypeOfExpr`), so `self.max(lo).min(hi)`
  finds `Money_min` — and `Stub(n: 1).where().file` read the `SourceLocation`
  fields as numbers (`308 3 16 320`, exit 0) until it did.
- **A method on a value of an IMPORTED type** resolves through the receiver's
  record type (`recordMethodSym`'s fallback to `recordTypeOfExpr`): inference
  records no note for it, so `queryOf(xs).toArray().length` answered `0`.
- **The optional binder takes the payload's record type** (`lowerIfExpr`,
  `local_types`), so `if (hitOf()) { h -> h.rest.length }` reads the declared
  slot instead of `0`.
- **A behavior literal's `self` method is called with its receiver**
  (`self_method_fields`, `lowerValueCall`): `g.greet(who)` over `@Greeter(greet:
  { self, who -> … })` passed one argument fewer than the lifted lambda takes (a
  trap). The lambda's parameters take their types from the behavior's
  declaration of the method (`lowerBehaviorLit` → `expected_params`), and the
  call's result is judged by the lambda's body (`fieldLambdaCallIsString`) — it
  printed the string's address.
- **A function two linked modules declare is mangled per module**
  (`emitWat`, `link_mangled`, `linkRenames`, `renameLinkedCalls`). This backend
  links every module the program imports into ONE namespace: the first
  declaration keeps its name, a later one is emitted as `<module>/<name>`
  (`two/parse`), and every call that means it — its own module's, an
  importer's plain or aliased import, a namespace call's synthesised alias
  (`__bp_ns_jwt__sign`) — is rewritten to that name in a COPY of the calling
  module's declarations (a linked module's program is shared with its own
  emission). The rewrite is a reflective walk over the AST, like
  `alias_erase`, and touches plain calls — and a call through a namespace
  item the transform pass leaves as written (`import {querystring, url} from
  "std"`, `url.parse(…)`): `linkRenames` keys each mangled function of the
  module the item names `<namespace>.<fn>`, and the call becomes the plain
  mangled one, its receiver dropped. That call dropped the receiver and
  called the bare name — `url.parse(…).host` read `querystring`'s array and
  printed `0` at exit 0 (`modules/std/run/src/cases/std_namespace_calls_same_name`). Before, the first declaration
  won and `import {parse as parse2} from "two"` answered `one`'s `parse`
  (`modules/linked/run/src/cases/linked_fn_name_collision`, `modules/decisions-taken/shorthand_import_refused-337/cells/namespace_import_module`). A
  module-level `val` / `var` two modules declare is mangled the same way
  (`link_mangled_vals`), but its reads are not rewritten in the AST — a
  parameter or a local of the same name must still shadow it. They resolve
  while their module is emitted: `global_renames` (the module's own mangled
  `val`s and every import of one, `linkValRenames`) is set per declaration
  and per `$__init_globals` entry (`deferred_renames`), and `resolveName`
  answers the mangled global for a name no local holds — so every shape
  predicate and every `global.get` / `global.set` reads the module's own. It
  read the first declaration's value at exit 0
  (`modules/linked/run/src/cases/linked_val_name_collision`). A `type` (record or enum), a
  `behavior`, an `implement` and an `extend` block two modules declare are
  mangled the same way (`link_mangled_types`, `linkTypeRenames`,
  `renameLinkedTypes`): the later declaration is registered as
  `<module>/<Name>` and every reference its module and its importers write is
  renamed in the same reflective walk — a type in a signature, an annotation
  or a type argument, a constructor call, an `Enum.Variant` read or call, a
  `case` arm's path (`<module>/Shape.Circle`), an `extend`/`implement`
  target. The registries stay keyed by that name, so `fieldOffsetIn`,
  `findVariant` and the descriptors see two types; only the text a value
  prints under is the bare name again (`displayTypeName`). Before, such a
  declaration was DROPPED at link time: two packages each declaring `type
  Response` linked the first one's layout into both and `ok().html` printed
  `0` at exit 0 (`modules/import/cells/import_same_name_from_two_packages`,
  `modules/import/cells/import_same_enum_name_from_two_packages`). A plain call of a
  function declared to answer an enum is a variant to the print path
  (`enumReturnedBy`, `namedShapeOf`, `isTaggedValue`): `@print(stop())` over
  a linked module's `fn stop() -> Signal` printed the value's address.
- **A variant reached through its enum is the enum's** (`callKind`):
  `Bp__Token__Layout.Size(…)` — what a section path desugars to — built the
  RECORD `Size` when one of that name was in scope, and `.Layout.Size.Large`
  answered the section's first arm (`display:block`).
- **A `_`-named top-level statement runs at module load**, in `$__init_globals`
  in source order with the named `val`s (`deferred_stmts`); it was dropped. A
  synthetic statement that only calls `main()` is skipped, as on the BEAM.

## The primitive method table (`00 · 05-wasm` step 6, `01-compiler/05-wasm` step 1)

`primCallRes` is the table of what a primitive method lowers to; a method it
does not list is refused at the call (`primNotLowered`). Audited against every
member `libs/std/src/primitives.bp` declares — **every member is listed now**:

| Family | Lowered |
|---|---|
| `String` | every member — each through the std-wasm function its `std:` cell in `primitives.bp` names (`std_method_exports`; decision 442 (2)) — `toUpper` / `toLower` over all of Unicode, OTP's answer (decision 443: `ß` → `SS`, no final sigma, `modules/std-wasm/AGENTS.md`); `charCodeAt` (`text.charCodeAt`: the code point at code-point index `i`, decoded from the UTF-8 sequence it walks to; `-1` out of range), `lastIndexOf`, `padStart`/`padEnd` (the pad cycled, by bytes), `replace`/`replaceAll` (an empty pattern matches before every byte), `chars` (one string per UTF-8 codepoint, as `split("")` does), `lines` (cut at `\n`, a `\r` right before it dropped — node's `/\r?\n/`, erlang's `[<<"\r\n">>, <<"\n">>]` —, the last line keeping a trailing `\r`, `""` one empty line) and `words` (the runs of bytes that are not ` `/`\t`/`\n`/`\r`) |
| `Array` | every member — `find` (`filter` then `at(0)`, the `?T` `at` answers); `lastIndexOf` (std-wasm's `array.lastIndexOfWord` / `String` / `Float`, `indexOf`'s equality from the last slot down); `pop` on a local, a global or a record's field (the `?T` `at(-1)` answers, then the name — or the field — rebound to `array.slice(xs, 0, len - 1)`: a blob is a value, as `push` rebinds it to a grown copy; any other receiver may be an array another name holds, and is refused); `unique` (`array.unique(xs, mode)`: every duplicate dropped, each value kept at its first occurrence (decision 217), `primitives.bp`'s body, compared by the element's word (`0` — an integer, a bool, an all-unit enum's ordinal), the bits of its `f64` (`1`) or a string's content (`2`), `uniqueMode` reading the receiver's shape); `flatten` / `flat` (`array.flatten`, over a receiver whose shape is `[[…`); `flatMap(f)` (`map(f)` inlined, then `array.flatten` — the body `primitives.bp` writes — when `f`'s tail is an array, `lambdaTailShape`); `chunked` / `sliding` (`array.chunked` / `array.sliding`, arrays of slices; `n <= 0` none); `fill(v)` (`array.fill(len, v)`, `Array.repeat(v, xs.length)`, a float as the one cell every slot shares) |
| `Integer`, `Bool` | all — decision 319's conversions `toI32` / `toI64` / `toU32` / `toU64` / `toF64` (`lowerIntConversion`): the receiver's carrier (`i32`, or `i64` read unsigned for a `u64`) tested against the target's range — `toF64` of an `i64` by truncating the nearest `f64` back, the carrier's top tested first — then the value in the target's carrier (a `u32` in an `i64`), or `<name>: <digits> does not fit <type>` / `has no exact f64` to stderr and a trap; `typeRefOf` names the target type, so a `u64` answer prints and converts unsigned |
| `Float` | all — `toString` (`number.floatToString`, decision 441) |

**What is still refused, by name** (`tests/wat.zig` `unique over records,
flatMap over a scalar and flatten over scalars are refused at the call`; each
trapped at run time until `00 · 110-gate-wasm`): `unique` over records, arrays
or tuples — decision 210 now gives `[P(x: 1), P(x: 1)].unique().length` one
answer, `1` on commonJS, erlang and beam, and this row is still a refusal
here: `array.unique` compares words, float bits and strings, and calling `$__eq_<T>` from
it is open; `flatMap` whose function answers no array known here
(node keeps the scalar, erlang fails); `flatten` / `flat` over elements no
shape says are arrays.

`newArrShape` is what these results ARE to every shape predicate —
`printShapeOf`, `elemKindOf`, `elemIsPointer`: `unique` keeps its receiver's
shape, `flatten` drops one `[`, `flatMap` is its function's array, `chunked` /
`sliding` add one, `fill` is `[` plus its value's shape, and `map` is `[` plus
its function's tail when that is a bool (`[b`) or a container. So
`[1, 2, 3].chunked(2).at(1)` prints `[3]` and not the row's address.

Byte-level, like every string helper here but `charCodeAt`: an ASCII string
answers as the other backends do, a multi-byte one by bytes.

## Shapes a container carries (`01-compiler/05-wasm` step 1)

The step-1 cells (and decision 150's union array) ran into these places where a container's element was
printed or compared as the word its slot holds — each a wrong value at exit 0,
each fixed where the shape is decided:

| Written | Was | Is | Where |
|---|---|---|---|
| `@print([true, false])`, `bs.reverse()`, `for (bs) { b -> @print(b) }` | `[1, 0]`, `1` | `[true, false]`, `true` | `printShapeOf` answers `[b` for an array of bools (a literal, a written `bool[]`); `arrayElemOpt` boxes the element as a bool (`bs.at(0)` → `true`); `elemIsBool` marks a loop's and a HOF's binder |
| `rows.at(1)`, `rows[0]`, `ps[1]` over `[[1, 2], [3]]` / `[#(1, "a"), …]` | `280`, `268`, `376` | `[3]`, `[1, 2]`, `#(2, "b")` | `OptInfo.shape`: a `?T` whose payload is an array or a tuple prints `null` or by its shape (`lowerPrintArg`) |
| `[[1], [2]].reverse()`, `bs.filter(…)` | the rows' addresses | `[[2], [1]]` | `printShapeOf` reads a `keepsElements` method's receiver |
| `var names: string[] = []; names.push("a")`, `var rows: i32[][] = []` | `[256]`, `[280]` | `["a"]`, `[[1]]` | `noteAnnotatedArray`: a written array type decides a local's shape, element kind and record over what the initialiser suggested — `[]` says nothing. It moved std's `Dict.display` (`var parts: string[] = []` … `parts.join(", ")`) from `$__arr_join_i32` to `_str`: three `std_package_*` wasm snapshots' text, no RUN LOG |
| `xs.map({ x -> x > 1 })` | `[0, 1]` | `[false, true]` | `newArrShape`'s `map` arm |
| `[3, "abcd"]`, `val ys: (i32 \| string)[] = [2, "b", 3]`, `xs[1]`, `xs.at(7)`, `for (xs) { x -> size(x) }` | `[3, 256]`, a trap in `$__print_unknown_raw` | `[3, "abcd"]`, `abcd`, `null`, `7` | decision 150: an array literal whose elements disagree (`unionArrayLitTypeRef`, numbers alone widen instead) or that stands where a union array is written (`expected_union_array`: a `val`'s annotation, a parameter, the return) holds each element in `lowerAsUnknown`'s box; its shape is `[U`, which `$__print_shaped_raw` prints by the box (`print_shaped_unknown`, a marker group as `bigint` is); an element read (`xs[i]`, `at`, `first`, `last`, `pop`) is the union's box, `0` absent (`elemIsPointer`). `conformance/modules/decisions-taken/mixed_literals_infer_union-150/run/src/cases/array_literal_union_elements` |

`snapshots/codegen/wasm/index_a_nested_index_a_slice_s_length_and_a_tuple_element`
recorded `304` and `376` for `rows[1]` and `ps[1]`; it records `[3, 4]` and
`#(2, "b")`, erlang's text.

## Self-recursion in tail position (`00 · 05-wasm` step 9)

**`return f(args)` inside `fn f` is a branch, not a call** (`noteSelfTailCalls`,
`lowerSelfTailCall`, `wrapTailLoop` in `../wat.zig`). wasm has no tail calls
unless the tail-call proposal is enabled, and wasmtime's default does not enable
it: `count(100000, 0)` trapped `call stack exhausted` (exit 134) where the other
three backends answer. Every argument is evaluated onto the stack, the
parameters are re-bound from it in reverse — so `sumTo(n - 1, acc + n)` reads the
OLD `n` in both — and `br $__tail` restarts the body, which `emitFn` wraps in
`(loop $__tail (result …) …)` **only when such a call exists**, so no other
function's text moves. Only the explicit `return f(…)` spelling is recognised
(reached through `if` arms and loop bodies, never through a lambda); a method, a
lifted lambda, a destructured parameter and an accumulating (generator) body
keep `call`. `conformance/modules/tail/run/src/cases/tail_self_call` pins it on four targets.

## Structural equality (decision 210)

`==` compares by value: two values are equal when they have the same type and
their fields are equal, field by field and recursively; `!=` is the negation, and
`==` never calls user code — a method named `equals` has no role (decision 211).
Before it, two equal records answered `false` here (two heap pointers, `i32.eq`),
and so did two equal arrays, two payload variants and two allocated unit variants
(`Shape.Dot` is a fresh one-slot cell). `lowerBinOp` asks `lowerStructuralEq`
after its null, `unknown`, boxed-optional and string rows, so none of those moved:

| Operands (`eqTypeOf`) | Lowering |
|---|---|
| a primitive — a scalar, a bool, a string, an all-unit enum's ordinal, `?` of one — or a type nothing recovers on both sides | the instruction it always had |
| both one composite type — a record, a payload enum, a tuple, an array, `?` of one — or one side that and the other unrecovered | `call $__eq_<T>` (`i32.eqz` after it for `!=`) |
| two different types, either composite | both operands run and are dropped, then `i32.const 0` (`1` for `!=`) |

`eqTypeOf` reads the static type the way the rest of this backend does — a name
`eq_local_types` recorded for a `val` (`val t = #(P(x: 1), 2)`), `recordTypeOfExpr`,
a variant constructor or a unit variant read off its enum (`eqEnumOf`),
`unitEnumOf`, `typeRefOf`, a tuple or array literal of recovered elements, and the
print shape (`eqTypeOfShape`: `i` `f` `b` `s` `[X` `(…)`).

`$__eq_<T>` is requested the first time the module compares a `T`
(`eq_requests`) and written after lowering, after the behavior dispatchers; each
may request the equality of a part. The symbol is prefix notation with each
constructor's arity (`__eq_Person`, `__eq_Array_Person`, `__eq_Tuple2_i32_string`,
`__eq_Opt_Node`, `__eq_Box_string`). Its first test is the pointers — `a == b`
answers `1` at once — then the parts in order, each `i32.eqz` → `return 0`, so
the first difference ends it, and `1` past the last:

| `T` | parts |
|---|---|
| record | each field at `i * 4`: a string by `$__str_eq`, an `f64` by `$__f64_eq` over its cell, an `i64` by `i64.eq` over its cell (`EqSlot.field`), an integer, bool or all-unit enum by `i32.eq`, a composite by its own `$__eq_<T>`, a field written as one of the record's type parameters by the argument `T` spells (`Box<string>`), or as a word when it spells none |
| payload enum | the ordinals at slot 0 (`i32.ne` → `0`), then the matching variant's payload at `(i + 1) * 4` — a float is the `f64` its slot's cell holds; a unit variant is equal on its ordinal |
| tuple | each element at `i * 4`, a float as its cell's `f64` |
| array | the lengths, then a `$brk`/`$cont` loop over `4 + i * 4` (locals `$n`, `$i`) |
| `?X` | both absent is `a == b` above; one absent answers `0`; a pointer payload (a record, a variant, a container, a string) is compared directly, a box's payload by the payload's own compare |

**A float under `==` is a total order** (decision 214, Java's `Double.compare` and
Kotlin's data class): NaN equals NaN and `0.0` differs from `-0.0`, bare and as a
part alike. `lowerBinOp`'s float `==` / `!=` and every float part call
`$__f64_eq` over the `f64` (a slot's cell, `EqSlot.word` / `.field`, or an
optional's box, `.cell`), written only when called: both NaN (`x != x`, which
canonicalises every NaN payload) `or` the same bits (`i64.reinterpret_f64`,
then `eq`). There is no `f32` anywhere: a declared `f32` is held as the `f64`
it is on commonJS. `<`, `>`, `<=`, `>=`
keep the IEEE `f64.lt` family. `conformance/modules/decisions-taken/f64_equality_total_order-214/run/src/cases/f64_equality_total_order`
pins the zeros on four targets; the NaN half is `tests/wat.zig`'s `f64 ---- NaN
equals NaN under ==` RUN LOG, since erlang and beam never produce a NaN. No hash is
computed at construction, nothing is interned, and there is no global table.

**A generic `T`**: one body here answers every type, each type parameter an `i32`
word, so a body cannot compare two `T` values by value — a string has no header
and an integer is not a pointer. A call whose argument binds `T` to a composite,
to a function whose body compares with `==` / `!=` (`comparesValues`), calls a
copy with `T` written as the composite (`eqBindParam`, `specializeFor`): the
copy's `a == b` is `call $__eq_<T>`. `same(Person(…), Person(…))` is
`same__T_Person`, `same(#(1, "a"), …)` `same__T_Tuple2_i32_string`. What stays is
the **What stays** limit above (§ Where this backend refuses to answer): a call nothing specialises keeps the one body and
compares words. `conformance/modules/decisions-taken/equality_is_structural-210/run/src/cases/record_structural_equality`.

## Rules

- **Layout is part of the model where the output depends on it** — as in
  `erl_ast.zig`. A `Line` carries its column because the historical layout is
  not uniform (an `if` arm's body keeps the function column, an optional-field
  guard and a loop's scaffolding indent to 8), and `Func.locals` is a list of
  lines because the hand-tuned helpers group declarations. Don't "tidy" these:
  `snapshots/codegen/wasm/` is byte-compared, and 280 `WASM TEXT` blocks are
  expected to keep passing `wasmtime compile`.
- **Never widen a `raw` escape hatch into the model.** There is deliberately no
  raw-text instruction, and no placeholder value either: a construct wat cannot
  lower is `Emitter.refuse(loc, …)` — a located compile error — never an
  `Instr.comment` plus an `i32.const 0` carrier (§ Where this backend refuses to
  answer).
- **A helper is requested, never named.** Use `Builder.helper(.print_str)`, not
  a `call` with a literal `"__print_str"`. Adding a helper means adding it to
  `Helper`/`HelperGroup`/`HelperSet` and to `wat_prelude.items`/`order`.
- **Nodes borrow their slices.** Build them in an arena that outlives rendering
  (`wat.zig` uses the emitter's `reg_arena`, which dies after the module is
  rendered).

## Generic calls in linear mode

- `genericFnArgElem` reads the element kind of an `R[]` a generic fn answers (`fn mapAll<T, R>(items: T[], f: fn(T) -> R) -> R[]`) off the function argument's tail, its parameter bound to an element of the `T[]` argument (string, bool as the `[b` print shape, float, else i32); cell `generic_fn_result_array_string_bool`.
- `genericRetRecord` names the record a generic `-> ?T` / `-> T` answer holds (the `T[]` argument's element or the `T` argument), so `?.field` finds its slot; cell `generic_answer_record_field_read`.
- A generic method answering `-> ?T` / `-> T` (`first<T>(self, …, fallback: ?T) -> ?T`) is registered as a generic method even on a type with no type parameter (`answersOwnTypeParam`), and `specializeMethod` binds `T` through a `?T` parameter and copies the method per record bound: the one body boxed the answer as a scalar. The copy's return type is read from `fn_ret_typerefs` by `recordTypeOfExpr`; cell `generic_method_optional_answer`.
- A lambda stored in an optional function-typed field is written against the function type (`lowerLambdaValue` unwraps `?fn`), and `valueCallTypeRef` answers the return of a value narrowed from `?fn`; cell `optional_fn_field_narrowed_call`.
