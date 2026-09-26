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
| `wat_prelude.zig` | The runtime helpers wasm has no opcode for, as `Func` nodes: `print` (`$__write_bytes`, `$__print_nl`, `$__print_sp`, `$__print_i32`, `$__print_i32_raw`, `$__memmove`), `print_str` (`$__print_str_raw` traps on a pointer below the data floor — decision 67, § below), `print_bool`, `print_f64`, `arr_at`, `str_concat`, `str_eq`, `str_slice` (transcribed line by line), then — one helper per group, built with the comptime constructors at the bottom of the file (`func`, `loop`, `when`, `whenElse`, `get`/`set`/`op`/…; `func` assigns each line the column its nesting puts it at) — `alloc` (bump, 4-byte aligned), `mem_eq`, `i32_abs`/`i32_min`/`i32_max`, `i32_to_str`, `f64_to_str` (float param — `typedFunc`), `str_case` (ASCII shift of a byte range), `str_index_of`, `str_starts_with`, `str_ends_with`, `str_at` (`s.at(i)` as a `?string`: `$__str_slice(s, i, i + 1)`, or `0` — absence — when `i32.ge_u` puts `i` outside `0..len`, which catches a negative index in the one compare `$__arr_at` needs two for), `str_trim` (mode bits: 1 start, 2 end), `str_split`, `str_repeat`, `arr_new`, `arr_slice` (host bound rules), `arr_reverse`, `arr_prepend`, `arr_push`, `arr_concat`, `arr_zip`, `arr_index_of_i32`/`_str`, `arr_join_str`/`_i32`, `print_arr_i32`, `print_arr_f32` (+`_raw`), `box_i32`, `arr_at_box`, `print_opt` (`$__print_null` — the bytes of `null`, decision 47's one spelling of absent, through scratch `176..180` — and `$__print_opt_i32`/`_bool`/`_str` +`_raw`), `assert_fail` (`$__write_err` — `fd_write` to fd 2 — and `$__assert_fail`, its literal text through scratch `188..208`), `print_shaped` (`$__print_quoted_raw` — a nested string, quoted with the source escapes — and `$__print_shaped_raw(v, shape, go)`, which walks a shape string — `i`/`f`/`b`/`s`, `[X`, `(XY…)` — writing `[a, b]` / `#(a, b)` and answering the address past the shape; `go = 0` only measures), `print_opt_tagged` (`$__print_opt_tagged` +`_raw` — a `?T` whose `T` is a record: `null` for `0`, `$__print_tagged_raw` otherwise; its own group, because the tagged printer reads a header four bytes behind the value and absence has to be answered before it is called), and `display_of` (`$__display_of(v)` answering `0` — the `Display` hook `$__print_tagged_raw` calls first, which `wat.zig` replaces with the module's dispatch, § below). `items(group)` returns a group's forms, `order` the order a module appends them in (declaration order, so the transcribed groups keep their place), `fd_write_import` the one host import the print group needs. Scratch layout below the data section (which starts at 256): `0..8` the WASI iovec, `8` the newline byte — and `9` the space of §7's `, ` separator (`putSep`), written beside it so the two bytes leave in one `fd_write` —, `16..32` the bool text, `32..64` the float fraction, `64..128` the i32 digits, `128..160` the digits `$__i32_to_str` writes backwards, `168..174` the fraction digits of `$__f64_to_str`. |

## Consumers

- `../wat.zig` — builds every instruction, function, global and data segment as
  nodes (`Emitter.emit`/`emitC`/`emitAt`/`note`/`item`, `Capture` + `open`/`seal`
  for a nested body), assembles the module's item order, and calls
  `renderModule`.

## Where this backend refuses to answer

wasm is the only backend that can answer **wrongly and silently** — a number,
exit 0, no diagnostic — because every value here is an `i32` and a pointer is a
number like any other. The rule this directory holds to: *where wasm cannot do a
shape, it traps*; a wrong value with exit 0 is a bug even when a fixture records
it. `Instr.unreachable` plus a `;;` comment naming the shape is the mechanism,
and 24 fixtures already use it.

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
[Decision 67](../../../../../specs/1.0.5-beta/decisions-taken.md#67-the-most-restrictive-behaviour-and-no-configuration-that-bypasses-it) settles it: the refusal is
located, and **no flag switches it off**. Ten `snapshots/codegen/beam/wasm/external_*`
fixtures moved from a `WASM TEXT` block with that trap to a
`COMPILE DIAGNOSTIC` section; their `externals.zig` tests carry the new
`refused_on_wasm` expectation, which still requires commonJS, erlang and beam to
compile and fails if wasm ever starts accepting one.

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

**The generic-parameter limit this leaves, deliberately.** Nothing here
monomorphises, so `Array<K>` and `?V` carry `K`/`V` as declared: `keys()` on a
`Dict<string, i32>` prints `[256,272]`, and `?V` with `V = string` prints an
address. `elemKindOfTypeRef` reads a type parameter as `.i32`, which is right for
the *slot* and wrong for the *text*. Fixing it needs the instantiated type at the
call site, which this backend does not have.

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

What is left in this class is the **generic-parameter limit** below, which is a
different cause: there the declared type is a type parameter, so no shape exists
to slice — and one more, reported on `fix/wasm-refusals` and not fixed there:

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
after it. This is [decision 67](../../../../../specs/1.0.10-beta/decisions-taken.md)
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

## Two run-time rules this backend implements first (2026-09-19)

**No loop has a value** ([decision 105](../../../../../specs/1.0.10-beta/decisions-taken.md),
superseding decision 55's value `break`): `break <v>` belongs to a generator
scope and ends it — `emitGenBreak` appends `v` and branches out of the
`iter` loop's `$__gen{n}` block, or returns a generator fn's array.

**A range pattern tests both ends** ([decision 53](../../../../../specs/1.0.5-beta/decisions-taken.md)):
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
* **`is` over a primitive.** Every value here is an `i32` in linear memory;
  `is i32` and `is string` cannot be told apart at run time. `lowerIsCall`
  traps with a note instead of answering `i32.const 0`, which would be a silent
  wrong answer.

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

## Rules

- **Layout is part of the model where the output depends on it** — as in
  `erl_ast.zig`. A `Line` carries its column because the historical layout is
  not uniform (an `if` arm's body keeps the function column, an optional-field
  guard and a loop's scaffolding indent to 8), and `Func.locals` is a list of
  lines because the hand-tuned helpers group declarations. Don't "tidy" these:
  `snapshots/codegen/beam/wasm/` is byte-compared, and 280 `WASM TEXT` blocks are
  expected to keep passing `wasmtime compile`.
- **Never widen a `raw` escape hatch into the model.** There is deliberately no
  raw-text instruction: a construct wat cannot lower yet emits an honest
  `Instr.comment` (`;; unsupported expr: …`) plus the `i32.const 0` carrier.
- **A helper is requested, never named.** Use `Builder.helper(.print_str)`, not
  a `call` with a literal `"__print_str"`. Adding a helper means adding it to
  `Helper`/`HelperGroup`/`HelperSet` and to `wat_prelude.items`/`order`.
- **Nodes borrow their slices.** Build them in an arena that outlives rendering
  (`wat.zig` uses the emitter's `reg_arena`, which dies after the module is
  rendered).
