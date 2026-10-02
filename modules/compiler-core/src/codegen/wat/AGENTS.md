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

## Files

| File | Role |
|---|---|
| `wat_ast.zig` | **Types**: `ValType` (`i32`/`i64`/`f32`/`f64`, with `parse` for the backend's spelled type names), `Stack` (`none`/`value`/`terminated`, with `fits(?ValType)`), `Width` (`full`/`byte` — `…8_u` / `…8`), `MemArg` (`ty`, `width`, `offset`). **Instructions**: `Instr` (`const` with the numeral as spelled, `local_get`/`local_set`/`local_tee`, `global_get`/`global_set`, `op` = `<ty>.<name>`, `convert` (a fully-spelled conversion opcode), `load`/`store`, `call`, `call_indirect` (an inline `FuncType`), `br`/`br_if`, `drop`, `return`, `unreachable`, `memory_copy`, `if`, `block` (`block` or `loop`), `comment`). **Layout**: `Line` (instruction + `indent` + trailing `;; comment` + `folded`), `Seq` (lines + stack), `If.Arm.Layout` (`block` vs one-line `inline_`). **Forms**: `Param`, `Local`, `Func` (name, exports, params, result, `locals` as *lines* so a helper can group several, body), `Global`, `FuncType`/`Import`, `Memory`, `DataSegment` (offset + length prefix + raw bytes), `Item` (import/memory/start/table/data/global/func/comment — `table` is `(table funcref (elem $f …))`, each name checked against the module's functions), `Module` (items). **Invariants**: `Invalid`, `validateFunc`, `validateModule`, `declaresCall`. **Helpers**: `Helper` (every symbol is `__<tag>`; `group`), `HelperGroup` (`deps` — the groups a group's functions call into), `HelperSet` (an `EnumSet`; `require` closes over `deps`). **`Builder`**: arena + `seq`/`param`/`localLines`/`func` (which validates) + `helper`. |
| `wat_emitter.zig` | `renderModule` (validates, then `(module …)`; there is no bare-form entry point). Owns: the two-space item column, the four-space body column and each construct's arm columns, `$`-prefixing, folded (`(call $main)`) vs flat form, inline `(then i32.const 0 return)` arms, `offset=` suppressed when zero, and the data-segment escaping (four little-endian length bytes as `\xx`, then `\n`/`"`/`\`/`\t`/`\r`/`\xx` for control bytes). |
| `wasm_binary_emitter.zig` | `encodeModule(alloc, Module) → []u8`: the binary format of the module the text emitter renders — validated first (`validateModule`), then sections type · import · function · table · memory · global · export · start · element · code · data, LEB128, one type per distinct signature (imports' and functions' types first, then each `call_indirect`'s), locals as runs of one type, no custom section. Every name the text spells is resolved to an index — functions (imports first, then definitions, in item order), globals, locals (params then declared), branch labels (depth, every `if` counted) — and a name that resolves to nothing (`UnknownName`), an operator the MVP table (`opcodes`: numeric, conversions, sign extension, `trunc_sat`) does not know (`UnknownOp`) or a numeral that does not parse (`BadNumeral`, the text format's spellings: sign, `0x`, `_`, `inf`/`nan`) is an error, never a guess. `wat.zig`'s `emitWat` renders both from one `Module` (`GenerateResult.js` the text, `.wasm` the binary); `codegen/runtime.zig`'s `executeWat` runs the **binary**, so every wasm RUN LOG is the binary emitter's answer checked against the recorded fixture. The browser build's page instantiates the same bytes. `Encoder` (with `typeIndex`/`funcIndex`/`funcBody`), `Bytes`, `section`, `uleb`/`sleb`, `name`, `valType`, `funcType` and `constInstr` are public for `comptime/runtime/wat/link.zig`, which pre-seeds an `Encoder` with a prebuilt module's index spaces and encodes a lowered comptime program's functions against the merged numbering. |
| `wat_prelude.zig` | The runtime helpers wasm has no opcode for, as `Func` nodes: `print` (`$__write_bytes`, `$__print_nl`, `$__print_sp`, `$__print_i32`, `$__print_i32_raw`, `$__memmove`), `print_str` (`$__print_str_raw` traps on a pointer below the data floor — decision 67, § below), `print_bool`, `print_f64`, `arr_at`, `str_concat`, `str_eq`, `str_slice` (transcribed line by line), then — one helper per group, built with the comptime constructors at the bottom of the file (`func`, `loop`, `when`, `whenElse`, `get`/`set`/`op`/…; `func` assigns each line the column its nesting puts it at) — `alloc` (bump, 4-byte aligned), `mem_eq`, `i32_abs`/`i32_min`/`i32_max`, `i32_to_str`, `f64_to_str` (float param — `typedFunc`), `str_case` (ASCII shift of a byte range), `str_index_of`, `str_starts_with`, `str_ends_with`, `str_at` (`s.at(i)` as a `?string`: a negative `i` first counted from the end (`i + len`, decision 139, as in `$__arr_at` / `$__arr_at_box`), then `$__str_slice(s, i, i + 1)`, or `0` — absence — when `i32.ge_u` puts `i` outside `0..len`, which catches a still-negative index in the one compare `$__arr_at` needs two for), `str_trim` (mode bits: 1 start, 2 end), `str_split`, `str_repeat`, `str_char_code`, `str_last_index_of`, `str_pad`, `str_replace` (§ The primitive method table), `arr_new`, `arr_slice` (host bound rules), `arr_reverse`, `arr_prepend`, `arr_push`, `arr_concat`, `arr_zip`, `arr_index_of_i32`/`_str`, `arr_join_str`/`_i32`, `print_arr_i32`, `print_arr_f32` (+`_raw`), `box_i32`, `arr_at_box`, `print_opt` (`$__print_null` — the bytes of `null`, decision 47's one spelling of absent, through scratch `176..180` — and `$__print_opt_i32`/`_bool`/`_str` +`_raw`), `assert_fail` (`$__write_err` — `fd_write` to fd 2 — and `$__assert_fail`, its literal text through scratch `188..208`), `print_shaped` (`$__print_quoted_raw` — a nested string, quoted with the source escapes — and `$__print_shaped_raw(v, shape, go)`, which walks a shape string — `i`/`f`/`b`/`s`, `[X`, `(XY…)` — writing `[a, b]` / `#(a, b)` and answering the address past the shape; `go = 0` only measures), `print_opt_tagged` (`$__print_opt_tagged` +`_raw` — a `?T` whose `T` is a record: `null` for `0`, `$__print_tagged_raw` otherwise; its own group, because the tagged printer reads a header four bytes behind the value and absence has to be answered before it is called), `display_of` (`$__display_of(v)` answering `0` — the `Display` hook `$__print_tagged_raw` calls first, which `wat.zig` replaces with the module's dispatch, § below), `unknown`, `print_unknown`, `arr_last_index_of_i32`/`_str`, and the five groups `01-compiler/05-wasm` step 1 added (§ The primitive method table): `str_lines`, `str_words`, `arr_unique`, `arr_flatten`, `arr_chunked`, `arr_sliding`, `arr_fill`. `items(group)` returns a group's forms, `order` the order a module appends them in (declaration order, so the transcribed groups keep their place), `fd_write_import` the one host import the print group needs. Scratch layout below the data section (which starts at 256): `0..8` the WASI iovec, `8` the newline byte — and `9` the space of §7's `, ` separator (`putSep`), written beside it so the two bytes leave in one `fd_write` —, `16..32` the bool text, `32..64` the float fraction, `64..128` the i32 digits, `128..160` the digits `$__i32_to_str` writes backwards, `168..174` the fraction digits of `$__f64_to_str`. |

## Consumers

- `../wat.zig` — builds every instruction, function, global and data segment as
  nodes (`Emitter.emit`/`emitC`/`emitAt`/`note`/`item`, `Capture` + `open`/`seal`
  for a nested body), assembles the module's item order, and calls
  `renderModule`.

## Where this backend refuses to answer

wasm is the only backend that can answer **wrongly and silently** — a number,
exit 0, no diagnostic — because every value here is an `i32` and a pointer is a
number like any other. The rule this directory holds to: *where wasm cannot
lower a construct, it refuses at compile time; where it cannot do a shape at
run time, it traps*; a wrong value with exit 0 is a bug even when a fixture
records it. A lowering that cannot proceed — a name nothing binds, a field on
a receiver nothing types, a pattern naming no variant, a dispatch with no
function, a builtin or an expression kind with no lowering — is
`Emitter.refuse(loc, …)`: `error.WasmLoweringRefused`, carried to the driver as
a located diagnostic that fails the module (`Emitter.Refusal`, the slot
`emitWat` fills beside `MissingExternal`'s). Every such site used to write
`i32.const 0` with a `;; note` and go on, so the program ran and printed a
wrong value at exit 0 (`00 · 110-gate-wasm`); no `i32.const 0` stands for a
value this backend could not produce any more, and the three `emitC(zero, …)`
left are the `0` a `null` IS (`?.` on an absent receiver, an absent optional
compared or propagated). `Instr.unreachable` plus a `;;` comment naming the
shape is the run-time half, and 24 fixtures use it.

**A host-backed `declare fn` with no wasm host is REFUSED, not trapped**
(`wat.zig`'s `external_missing` + `lowerPlainCall`). A `declare fn` carrying
`#[@External.<Target>(…)]` for some other target and none for `wasm` has no
symbol here and never claimed to have one, so the call fails where it is
written:

```
error: `listToBinary` has no `#[@External.<Target>(…)]` for the wasm backend
  --> src/main.bp:21:12
```

That is the diagnostic commonJS, erlang and beam already print (06 C13's
`moduleOutput.MissingExternal`, target named `wasm`), reaching the driver as a
located `Diagnostic.type` through `emitWat`'s `missing` slot — the same wiring
`commonJS.zig` and `erlang.zig` have. It used to lower to `unreachable ;;
host-backed declare fn …/N: no wasm host` "so the module still loads", which made
this the only backend where the program compiled and then died at run time
(exit 134, stdout empty) — the divergence
`tests/language/run/external_erlang_only.targets` existed to hold wasm out of.
[Decision 67](../../../../../../../specs/1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) settles it: the refusal is
located, and **no flag switches it off**. Ten `snapshots/codegen/beam/wasm/external_*`
fixtures moved from a `WASM TEXT` block with that trap to a
`COMPILE DIAGNOSTIC` section; their `externals.zig` tests carry the new
`refused_on_wasm` expectation, which still requires commonJS, erlang and beam to
compile and fails if wasm ever starts accepting one.

**A function that reaches such a cell is refused where the call is written,
called or not** (decision 146 — "an error for whatever has no target"). Every
bodied function is emitted — `emitDecl` lowers each `fn` and each method, and
`registerSymbols` queues each behavior's associated `default fn` that has no
type parameter — so a body that calls an `external_missing` cell meets
`lowerPlainCall`'s refusal whether or not anything calls the function: the rule
commonJS, erlang and beam hold by emitting every function, and the diagnostic
they print (`tests/language/run/external_wrapper_keeps_refusal.bp`,
`run/external_wrapper_associated_default.bp`). wasm used to drop such a
function and refuse only a call of it (`collectHostBound` / `host_bound` /
`MissingExternal.via`, all gone), which let a module import on wasm when some
of its functions needed a host; no module does now. **One shape is still lowered
only when a call reaches it**: an associated `default fn` with a type parameter
of its own or of its behavior (`behavior Probe<A> { default fn f(x: A) … }`),
which commonJS refuses uncalled and wasm accepts. Queueing those too emits the
primitive behaviors' (`Array.range`, `Array.repeat`, `Pair.of`, …) into every
module that carries the behavior — measured: 14 wasm fixtures change and a
two-line `flatMap` program's `.wat` goes from 12 to 17 functions — which is
`05-wasm`'s to weigh.

**A refused module takes its consumers with it, each at its own import**
(`codegenEmit`'s `relocateLinkedRefusals`). The linked declarations are emitted
INTO the consumer, so the consumer meets the same refusal at a location of the
linked module's file — which the driver would print against the consumer's
(`src/main.bp:101:9` for a call at `std/testing/asserts.bp:101:9`). The refused
module reports its own diagnostic in its own file; each consumer that links it
(`Linked.via`: the consumer's import item the link walk came through) reports
`` `canonical` has no `#[@External.<Target>(…)]` for the wasm backend — in
`std/testing/asserts`, which this import links `` at that import
(`run/std_asserts_on_every_target.wasm.expect`,
`run/std_asserts_host_cell_on_wasm.wasm.expect`,
`modules/labelled_call_by_label/wasm.expect`).

A **bodyless `declare fn` with no `#[@External.<Target>(…)]` at all** keeps the
old trap. That is the same cut commonJS makes — its `externals_missing` is filled
only for an `isExternal()` fn — and it is what an interface's bodyless method
shape lands in.

**A record or a variant reaching `@print` traps** (`wat.zig`'s `namedShapeOf`,
consulted first in `lowerPrintArg`). Decision 8 §7's F2 and F3 want
`Point(x: 1, y: 2)` and `Shape.Square(side: 4)`; both need a value that knows
which named type it is at run time, which is `13-module-identity`'s subject, not
this backend's. Until then the numeric printer wrote the value's heap address —
`tests/language/run/print_formatter.bp` printed `328`, `336`, `344` — so the
printer now traps instead. commonJS needs no such interim: a class instance
carries its constructor's name and already answers §7's text. When 13 lands, the
trap is one branch to delete.

The walk covers the value, an array or tuple **literal** holding one, and a
record recovered through a field or a fn return type. **Not** covered, and still
answering an address: a *local* bound to such a container (`val ps =
[Point(x: 1, y: 2)]; @print(ps)`) — the element shapes tracked per local are
`i32`/`f32`/`str`, and a record is an `i32` slot like every other pointer.

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
the absent key printed `0` (`run/index_dict`, `run/index_at_optional`). A method
declared `-> ?i32` boxes its `return` like a fn (`cur_ret_typeref` is set in
`emitMemberFn`), and a `?T[]` of a scalar prints as the array or `null`
(`arrayScalarCode`, `run/index_user_type`).

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
  `Pair<string>.matched` compared words while `left: A` read as `A`;
- **a constructor of a generic record answers its type arguments**
  (`ctorTypeRef`, `record_generics`): `Pair(left: s, right: "ab").matched()`,
  a local bound to one, an array literal of them (`typeRefOf`'s `arrayLit`
  arm) and a HOF's element parameter over such an array specialise like a
  written `Pair<string>`;
- **a parameter written `Pair<T>`** binds `T` from its argument's type
  arguments (`bindParam`), and a field read through a receiver typed
  `Pair<string>` is a `string` (`recvTypeArg`): `eqPair(Pair(left: s, …))`;
- **a generic fn NAMED as an argument** whose parameter is written as a
  function type, or **bound** to a `val` written with one, is the copy that
  type binds (`specializeByFnType`, `specCopy`): `apply(same, s, "ab")`
  against `f: fn(a: string, b: string) -> bool` called a trampoline over the
  generic body, and `val held: fn(…) -> bool = same` too (its call also
  prints as a bool now — `isBoolExpr` reads a function value's declared
  return).

**A function in a generic record's field answers its declared return**
(`ctorTypeRef` + `fnRefTypeRef`, `recvTypeArgRef`, `genericRetByFnArg`):
`Box(value: shout)` is a `Box<fn(s: string) -> string>`, so `h.value("b")`, a
local `val k = h.value` called, and the same through `wrap(shout)` over `fn
wrap<T>(v: T) -> Box<T>` answer a string (a bool, …) — they printed its heap
address (`320`) or a bool as `1`. A function type has no specialisation; only
the result type is read. Not covered: a LAMBDA stored in the field
(`Box(value: { s -> s + "?" })`) — its parameter is a word here, so the body
converts it as an integer (`300?`), which is the lambda parameter typing
`lowerLambdaValue` has no source for (`run/generic_field_fn_value.bp`).

`run/generic_string_equality.bp` pins every way a type parameter gets a
string bound on four targets, `modules/method_on_unimported_type` (`Dict.at`
with a key `split` built) included — it already passed at the open, through
`specializeMethod`. **What stays**: a call whose arguments and context say
nothing about the type keeps the one generic body — a generic fn stored in
a field or bound with no written type, a parameter type `bindParam` does not
read (it reads a bare `T`, `T[]` / `Array<T>` and a generic record's direct
type arguments) — and there `==` between two
type-parameter values compares words (a composite bound where the body
compares with `==` IS specialised, § Structural equality) and `elemKindOfTypeRef` reads a type
parameter as `.i32`. A string carries no header (it is a bare
`[len][bytes]` blob), so a body cannot ask the value what it is: the copy is
the only cure, and `run/generic_body_specialized.bp` pins the shapes that
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

`run/optional_record_carrier.bp` pins the whole family on all four targets, and
`run/optional_length_method.bp` lost its `.targets` sidecar with it.

**A `case` used as a VALUE is a string in BOTH arm spellings** (`armIsString`).
A BRACE arm — `case x { 5 { "five" } … }` — parses its body as a parameterless
block, which reaches codegen as a lambda node; a lambda VALUE is a closure
pointer, so `isStringExpr` said no, `val a = case …` was typed `i32` and
`@print(a)` wrote the arm's heap address (`256`) at exit 0. The ARROW spelling
(`5 -> "five";`) was right all along, which is what made the defect
syntax-dependent. `armIsString` is the only position allowed to look through a
lambda node, and `run/case_value_string_arms.bp` pins both spellings on four
targets.

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
"none"` print the string's address. `run/map_record_field_strings.bp` and
`run/map_record_field_length.bp` pin both.

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
unguarded path. `run/optional_chain_method.bp` pins it.

A `val c: ?T = …` keeps the VALUE's carrier (`opt_locals` from `optInfoOf` of
the initializer, not only when unannotated): `cs[1]` over an all-unit enum's
array is a box, and read as the bare ordinal `c == Color.Green` answered
`false`. An optional-binding `if`'s binder is the then-arm's name only
(`restoreBinderFlags`): every `a ?? b` binds `__bp_nullish`, and a string
payload left in `str_locals` made the next `??` over an `i32` print as a
string. `tests/language/run/index_answer_typed_optional.bp`.

## Two run-time rules this backend implements first (2026-09-19)

**No loop has a value** ([decision 105](../../../../../../../specs/1.0.10-beta/decisions-taken.md),
superseding decision 55's value `break`): `break <v>` belongs to a generator
scope and ends it — `emitGenBreak` appends `v` and branches out of the
`iter` loop's `$__gen{n}` block, or returns a generator fn's array; a bare
`break` at a generator fn's own level ends it the same way (`emitGenEnd`,
decision 103).

**A range pattern tests both ends** ([decision 53](../../../../../../../specs/1.0.5-beta/decisions-taken.md)):
`1...9` arrives as a `.variant` whose `shape` is `.range` with the two bounds in
`payload.literals`; before `emitPatternTest` read the shape it fell into the
variant-tag path, found no variant named `""` and answered `0` for every value.
Now it is `subj >= low and subj <= high` (`emitRangeBound`), a float bound
truncated like a `numberLit` pattern's; a string bound has no ordering here and
answers `0`. `tests/language/run/case_range_value.bp` pins the five points.

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

* `$__print_tagged_raw` (in the `print_shaped` group, because the two call each
  other) writes decision 8 §7's text: `Point(x: 1, y: 2)`, `Shape.Dot`,
  `Shape.Circle(radius: 4)`. The shape walker gained a `T` arm that calls it, so
  a container of records names each element's type — `[Point(x: 1, y: 2), …]` —
  read from each element's own header, not from the print site.
* `x is T` and a `case` arm naming a type are `subj >= 256 && load(subj - 4) ==
  <descriptor>`, an enum's variants joined by `or` (`lowerIsCall`,
  `emitNamedTypeTest`). The bounds guard is load-bearing: an `i32` that is not a
  pointer would otherwise read four bytes of whatever sits below it.

**What this backend still cannot do, and why it traps rather than guessing:**

* **A variant of an ALL-UNIT enum has no header.** `Color.Red` is `i32.const 0`
  with no allocation, so there is nothing four bytes behind it. `@print` of one
  keeps the trap, and `is` over such an enum answers no test. Boxing it would
  make `Color.Red == Color.Red` a pointer comparison, which is a worse answer
  than none.
* **A value whose type nothing proves cannot go in the box** — a type
  parameter's slot (`Maybe.Some(value: v)` over a `T`: nothing monomorphises
  here, so `v` is a raw `i32` that may be a pointer), a result nothing typed.
  `lowerAsUnknown` traps (`unknown: no static type to box this value by`)
  rather than boxing a guess, which would answer `is` and `==` wrongly.

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
matched everything (`number 364`, a heap address). `tests/language/run/unknown_by_value.bp`
pins it on four targets.

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
during lowering would shift. `tests/language/run/display_print.bp` prints `$5`
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
`Out`'s slot. `tests/language/run/behavior_method_dispatch_by_value.bp`.

**Every header read is guarded against a value below the heap floor**
(`emitHeaderLoad`): wasm's `i32.and` does not short-circuit, so `x is T` and a
`case` arm's type test loaded `subj - 4` for an all-unit enum's ordinal too —
out of bounds for `0`. The address is `(subj - 4) * (subj >= floor)`. A `case`
arm whose name is BOTH a record of the module and some enum's variant
(`type Block(…)` beside `Token.Layout { Block, … }`) tests both — the record's
header, `or` the variant's identity (`emitVariantIdentityTest`: an all-unit
ordinal, or a payload variant's descriptor, never a load of a record's first
field as a tag); `tests/language/run/case_arm_record_named_like_a_variant.bp`.

**An all-unit enum's value prints by name** (`unitEnumOf`,
`unitEnumShape`): its value is the ordinal, with no header, so the print shape
carries the names — `E k [ <n> Enum.Variant ] * k`, which `$__print_shaped_raw`
indexes by the ordinal. A member written by its path, a name, a parameter, a
field, a call and an `if` value typed by the enum take it, as do an array, a
tuple and a record field of one (`typeRefShape`). `?Color` is a BOX like
`?i32` (`optInfoOfTypeRef`): unboxed, a present `Color.Red` (ordinal `0`) was
absent. A literal trapped and a name printed the ordinal
(`tests/language/run/unit_enum_print_by_name.bp`).

**A `case` reads a bare or dot-shorthand arm in its subject's enum**
(`enumOfSubject` → `subject_enums` → `case_enum_hint`, read by
`findVariant`): a parameter, a local, a call typed by the enum, `self`, and a
section written as a path (`Token.Layout.Break` → `__Token__Layout__Break`).
Set for the WHOLE subject only — a payload's own pattern keeps the
program-wide lookup. One flat table answered the first enum declaring the name
(`run/variant_leading_dot_two_enums_case`,
`modules/enum_section_leaf_beside_variant`).

**A multi-subject `case a, n { … }`** lowers each subject once, into
`<subject local>_<i>` (`multiSubjectLocal`); a `.multi` arm tests and binds
each pattern against its own subject, a primitive type over an `unknown`
subject by its box. It tested nothing, and the first arm answered every call
(`run/case_multi_subject_patterns.bp`).

**A record's constructor pattern** (`val assert Person(n, a) = p catch …`)
tests the value's header (`recordPatternType`, `emitNamedTypeTest`) and binds
each name from the field it stands at, by label when one is written
(`recordPatternField`, `recordFieldAccess` — the ordinary field read, a boxed
float included). It tested and bound nothing
(`run/val_assert_record_pattern.bp`).

**A generic call answers its argument's shape** (`generic_result_arg`,
`genericResultArg`): `fn ident<T>(x: T) -> T` has one body, so `ident("a")`
is a string, `ident(true)` a bool, `ident(P(…))` a `P` — every shape predicate
asks the argument. `o.unwrapOr(d)` answers the default's shape. A string
printed as its address (`run/generic_call_result_shape.bp`); a string, a bool
or a float bound to a type parameter calls a specialisation (above).

**A function named as an array method's argument** (`xs.map(inc)`, an imported
fn, a local holding one) is inlined as the lambda `{ p -> inc(p) }`
(`hofLambdaAt`), the arity the method hands it. It trapped (`map needs a literal
lambda`; `modules/hof_named_function`).

**A value `if` has its own type** (`ifValueType`, `emitBranchValue`): an arm
yielding a float makes it an `f64` wherever it stands, each arm converted to
it. It took the enclosing function's result type, so an `f64` `if` in a
function answering nothing was `(if (result i32)` around two `f64`s — the
module refused (`run/if_value_float.bp`; `testing.asserts.approxEquals` binds
one).

## Decision 8 §5's pattern shapes (`01-compiler/05-wasm` step 3, C-07's wasm twins)

Three pattern shapes had no wasm test, and two of them answered at exit 0:

| Shape | Was | Is |
|---|---|---|
| a tuple pattern in a `case` (`#(0, s)`, `#(a, ..)`, `#(#(0, b), s)`) | refused — `` `` names no variant `` | `emitTuplePatternTest` / `bindTuplePattern`: each element that tests something is loaded from its slot (`i * 4`, no header) and tested in the chain a variant's payload literals use; a binder takes the element's shape (`noteTupleElemLocal`: a string prints as text, a float slot is read as `f32`); `..` skips the rest |
| a list pattern (`[]`, `[x]`, `[1, b]`, `[a, ..rest]`) | **irrefutable** — `[x]` took a `[]` arm, exit 0 | `emitListPatternTest`: the length (exactly the elements, or at least them with a spread), then each number literal; `bindListPattern` binds each element by the array's element shape and a named spread to `$__arr_slice(xs, n, …)`. Only `[..]` / `[..rest]` is irrefutable (`patternIsIrrefutable`) |
| `true` / `false` inside a pattern | a **binder** named `true` — every arm matched, exit 0 | the bool literal (`isBoolLitName`): `subj == 1` / `subj == 0` |

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
the shapes the checker keeps, its RUN LOG commonJS's (beam answers it too;
erlang's `erlc` refuses the lambda's re-binding, `02-erlang`'s row). The
inner-block and `case`-arm halves of the machinery stay, though a checked
program no longer reaches them.

**A lambda's bindings are its own** (decision 205: a lambda body is a
function of its own). An inlined HOF body's `val k` and its parameter `e`
over an enclosing `k` / `e` take the same `bindTarget` local and are undone at
the body's end, so the enclosing names keep their values;
`tests/language/run/lambda_binds_name_of_enclosing_fn.bp` (02-erlang's cell)
pins it on four targets. A lifted lambda (`{ e -> e * 2 }` as a value) is a
function of its own already.

## Function values, and the lowering that is not there

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
`lowerArmBody` inlines it instead. `@block { … }` is inlined by `lowerBuiltin`,
and a bare `{ 1 + 2 }` in value position does not parse at all ("this token cannot
appear here"). So decision 2's enforcement leaves nothing dead here.

## Methods, binders and the module body (`00 · 05-wasm`, the rows no step named)

Each of these answered `0` at exit 0 or trapped where the other three backends
answered, and each was a red wasm cell of `tests/language`:

- **An enum's methods are emitted** (`registerInterfaceSigs` / `emitInterfaceMethods`
  take every `type`, not only records): `Shape.Rect(…).counts(3)` was an
  `unresolved call` trap. An enum's associated fn called on the type
  (`Shape.unit()`) is `assocSym`'s, as a record's is — it took the variant path
  and answered `0 ;; unknown variant`. `exprReferencesSelf` walks a `case`'s
  subject and arms, so `fn name() { case (self) { … } }` gets its `$self`.
- **A method declared `-> @Iterator<T>` / `-> @Stream<T>` accumulates its
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
  `Integer` / `Float` (… `I32`, `F64`) is registered per primitive kind it
  covers, and a call on such a receiver whose method the table does not list
  is a copy of the default with `Self` written as the receiver's primitive
  (`String_tailShout__string`, `Number_clampTo__i32`), emitted once through
  the member path (`emitMemberFn` marks a primitive-typed `self`), the
  receiver as `self`. `primRes` reads its declared return for every shape
  predicate. Inside such a copy — any specialisation — a primitive method's
  result is typed by what it answers (`typeRefOf`), so `self.max(lo).min(hi)`
  and `val tail = self.slice(1); tail.startsWith(…)` find their primitive.
  Every program-declared default of a primitive trapped (`prim method not
  lowered on wasm`). `Array<T>`'s defaults are not covered: their `self` is
  `Self<T>`, which no copy substitutes, and they keep the trap.
- **A primitive method on a call inside an adopted default** reads the
  callee's declared return (`primKindAt`'s fallback): inference typed the
  default's body against `Self`, so `self.twice().toString()` in `Sq`'s copy
  of `Shape.label` had a type variable for a receiver and no lowering —
  `unresolved call: toString/0`, a trap in `Sq_label`. `Sq_twice -> i32` says
  it is an integer; the fallback answers only a primitive whose table has the
  method (`run/behavior_default_adopted_by_two_types`, 02-erlang's cell).
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
  `alias_erase`, and touches plain calls only. Before, the first declaration
  won and `import {parse as parse2} from "two"` answered `one`'s `parse`
  (`modules/linked_fn_name_collision`, `modules/namespace_import_module`). A
  module-level `val` / `var` two modules declare is mangled the same way
  (`link_mangled_vals`), but its reads are not rewritten in the AST — a
  parameter or a local of the same name must still shadow it. They resolve
  while their module is emitted: `global_renames` (the module's own mangled
  `val`s and every import of one, `linkValRenames`) is set per declaration
  and per `$__init_globals` entry (`deferred_renames`), and `resolveName`
  answers the mangled global for a name no local holds — so every shape
  predicate and every `global.get` / `global.set` reads the module's own. It
  read the first declaration's value at exit 0
  (`modules/linked_val_name_collision`). A `type` (record or enum), a
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
  `0` at exit 0 (`modules/import_same_name_from_two_packages`,
  `modules/import_same_enum_name_from_two_packages`). A plain call of a
  function declared to answer an enum is a variant to the print path
  (`enumReturnedBy`, `namedShapeOf`, `isTaggedValue`): `@print(stop())` over
  a linked module's `fn stop() -> Signal` printed the value's address.
- **A variant reached through its enum is the enum's** (`callKind`):
  `__Token__Layout.Size(…)` — what a section path desugars to — built the
  RECORD `Size` when one of that name was in scope, and `.Layout.Size.Large`
  answered the section's first arm (`display:block`).
- **A `_`-named top-level statement runs at module load**, in `$__init_globals`
  in source order with the named `val`s (`deferred_stmts`); it was dropped. A
  synthetic statement that only calls `main()` is skipped, as on the BEAM.

## The primitive method table (`00 · 05-wasm` step 6, `01-compiler/05-wasm` step 1)

`primCallRes` is the table of what a primitive method lowers to; a method it
does not list traps (`prim method not lowered on wasm`). Audited against every
member `libs/std/src/primitives.bp` declares — **every member is listed now**:

| Family | Lowered |
|---|---|
| `String` | every member — `charCodeAt` (`$__str_char_code`: the code point at code-point index `i`, decoded from the UTF-8 sequence it walks to; `-1` out of range), `lastIndexOf` (`$__str_last_index_of`), `padStart`/`padEnd` (`$__str_pad`, the pad cycled), `replace`/`replaceAll` (`$__str_replace`; an empty pattern matches before every byte), `chars` (`$__str_split` on `""`, which cuts before every UTF-8 codepoint, as `split("")` does), `lines` (`$__str_lines`: cut at `\n`, a `\r` right before it dropped — node's `/\r?\n/`, erlang's `[<<"\r\n">>, <<"\n">>]` —, the last line keeping a trailing `\r`, `""` one empty line) and `words` (`$__str_words`: the runs of bytes that are not ` `/`\t`/`\n`/`\r`) |
| `Array` | every member — `find` (`filter` then `at(0)`, the `?T` `at` answers); `lastIndexOf` (`$__arr_last_index_of_i32` / `_str`, `indexOf`'s equality from the last slot down); `pop` on a local or a global (the `?T` `at(-1)` answers, then the name rebound to `$__arr_slice(xs, 0, len - 1)` — a blob is a value, as `push` rebinds it to a grown copy); `unique` (`$__arr_unique(xs, mode)`: consecutive duplicates dropped, `primitives.bp`'s body, compared by the element's word (`0` — an integer, a bool, an all-unit enum's ordinal), its `f32` (`1`) or a string's content (`2`), `uniqueMode` reading the receiver's shape); `flatten` / `flat` (`$__arr_flatten`, over a receiver whose shape is `[[…`); `flatMap(f)` (`map(f)` inlined, then `$__arr_flatten` — the body `primitives.bp` writes — when `f`'s tail is an array, `lambdaTailShape`); `chunked` / `sliding` (`$__arr_chunked` / `$__arr_sliding`, arrays of `$__arr_slice`s; `n <= 0` none); `fill(v)` (`$__arr_fill(len, v)`, `Array.repeat(v, xs.length)`, a float stored as its `f32` bits) |
| `Integer`, `Bool` | all |
| `Float` | all — `toString` (`$__f64_to_str`, `5.0` → `5` as on node) |

**What still traps, by name** (`tests/wat.zig` `unique over records and
flatMap over a scalar trap, never answer`): `unique` over records, arrays or
tuples (`unique over elements with no wasm equality`) — decision 210 now gives
`[P(x: 1), P(x: 1)].unique().length` one answer, `1` on commonJS, erlang and
beam, and this row is still a trap here: `$__arr_unique` compares words and
strings, and calling `$__eq_<T>` from it is open; `flatMap` whose function answers no array known here
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

The step-1 cells ran into five more places where a container's element was
printed or compared as the word its slot holds — each a wrong value at exit 0,
each fixed where the shape is decided:

| Written | Was | Is | Where |
|---|---|---|---|
| `@print([true, false])`, `bs.reverse()`, `for (bs) { b -> @print(b) }` | `[1, 0]`, `1` | `[true, false]`, `true` | `printShapeOf` answers `[b` for an array of bools (a literal, a written `bool[]`); `arrayElemOpt` boxes the element as a bool (`bs.at(0)` → `true`); `elemIsBool` marks a loop's and a HOF's binder |
| `rows.at(1)`, `rows[0]`, `ps[1]` over `[[1, 2], [3]]` / `[#(1, "a"), …]` | `280`, `268`, `376` | `[3]`, `[1, 2]`, `#(2, "b")` | `OptInfo.shape`: a `?T` whose payload is an array or a tuple prints `null` or by its shape (`lowerPrintArg`) |
| `[[1], [2]].reverse()`, `bs.filter(…)` | the rows' addresses | `[[2], [1]]` | `printShapeOf` reads a `keepsElements` method's receiver |
| `var names: string[] = []; names.push("a")`, `var rows: i32[][] = []` | `[256]`, `[280]` | `["a"]`, `[[1]]` | `noteAnnotatedArray`: a written array type decides a local's shape, element kind and record over what the initialiser suggested — `[]` says nothing. It moved std's `Dict.display` (`var parts: string[] = []` … `parts.join(", ")`) from `$__arr_join_i32` to `_str`: three `std_package_*` wasm snapshots' text, no RUN LOG |
| `xs.map({ x -> x > 1 })` | `[0, 1]` | `[false, true]` | `newArrShape`'s `map` arm |

`snapshots/codegen/{beam,wat}/wasm/index_a_nested_index_a_slice_s_length_and_a_tuple_element`
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
keep `call`. `tests/language/run/tail_self_call.bp` pins it on four targets.

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
| record | each field at `i * 4`: a string by `$__str_eq`, an `f64` by `$__f64_eq` over its box (`storeBoxedF64`), an integer, bool or all-unit enum by `i32.eq`, a composite by its own `$__eq_<T>`, a field written as one of the record's type parameters by the argument `T` spells (`Box<string>`), or as a word when it spells none |
| payload enum | the ordinals at slot 0 (`i32.ne` → `0`), then the matching variant's payload at `(i + 1) * 4` — a float is the `f32` the slot holds; a unit variant is equal on its ordinal |
| tuple | each element at `i * 4`, a float as its `f32` slot |
| array | the lengths, then a `$brk`/`$cont` loop over `4 + i * 4` (locals `$n`, `$i`) |
| `?X` | both absent is `a == b` above; one absent answers `0`; a pointer payload (a record, a variant, a container, a string) is compared directly, a box's payload by the payload's own compare |

**A float under `==` is a total order** (decision 214, Java's `Double.compare` and
Kotlin's data class): NaN equals NaN and `0.0` differs from `-0.0`, bare and as a
part alike. `lowerBinOp`'s float `==` / `!=` and every float part call
`$__f64_eq` (a record field's boxed `f64`) or `$__f32_eq` (a tuple element, a
variant payload, an array element — the `f32` slot), written only when called:
both NaN (`x != x`, which canonicalises every NaN payload) `or` the same bits
(`i64.reinterpret_f64` / `i32.reinterpret_f32`, then `eq`). `<`, `>`, `<=`, `>=`
keep the IEEE `f64.lt` family. `tests/language/run/f64_equality_total_order.bp`
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
compares words. `tests/language/run/record_structural_equality.bp`.

## Rules

- **Layout is part of the model where the output depends on it** — as in
  `erl_ast.zig`. A `Line` carries its column because the historical layout is
  not uniform (an `if` arm's body keeps the function column, an optional-field
  guard and a loop's scaffolding indent to 8), and `Func.locals` is a list of
  lines because the hand-tuned helpers group declarations. Don't "tidy" these:
  `snapshots/codegen/beam/wasm/` is byte-compared, and 280 `WASM TEXT` blocks are
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
