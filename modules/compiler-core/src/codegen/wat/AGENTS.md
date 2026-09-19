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
├── wat_emitter.zig   ← the only writer: s-expressions, indentation, `$` names, data escaping
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
| `wat_prelude.zig` | The runtime helpers wasm has no opcode for, as `Func` nodes: `print` (`$__write_bytes`, `$__print_nl`, `$__print_sp`, `$__print_i32`, `$__print_i32_raw`, `$__memmove`), `print_str`, `print_bool`, `print_f64`, `arr_at`, `str_concat`, `str_eq`, `str_slice` (transcribed line by line), then — one helper per group, built with the comptime constructors at the bottom of the file (`func`, `loop`, `when`, `whenElse`, `get`/`set`/`op`/…; `func` assigns each line the column its nesting puts it at) — `alloc` (bump, 4-byte aligned), `mem_eq`, `i32_abs`/`i32_min`/`i32_max`, `i32_to_str`, `f64_to_str` (float param — `typedFunc`), `str_case` (ASCII shift of a byte range), `str_index_of`, `str_starts_with`, `str_ends_with`, `str_trim` (mode bits: 1 start, 2 end), `str_split`, `str_repeat`, `arr_new`, `arr_slice` (host bound rules), `arr_reverse`, `arr_prepend`, `arr_push`, `arr_concat`, `arr_zip`, `arr_index_of_i32`/`_str`, `arr_join_str`/`_i32`, `print_arr_i32`, `print_arr_f32` (+`_raw`), `box_i32`, `arr_at_box`, `print_opt` (`$__print_undefined` — the bytes of `undefined` through scratch `176..185` — and `$__print_opt_i32`/`_bool`/`_str` +`_raw`), `assert_fail` (`$__write_err` — `fd_write` to fd 2 — and `$__assert_fail`, its literal text through scratch `188..208`), `print_shaped` (`$__print_quoted_raw` — a nested string, quoted with the source escapes — and `$__print_shaped_raw(v, shape, go)`, which walks a shape string — `i`/`f`/`b`/`s`, `[X`, `(XY…)` — writing `[a,b]` / `#(a,b)` and answering the address past the shape; `go = 0` only measures). `items(group)` returns a group's forms, `order` the order a module appends them in (declaration order, so the transcribed groups keep their place), `fd_write_import` the one host import the print group needs. Scratch layout below the data section (which starts at 256): `0..8` the WASI iovec, `8` the newline byte, `16..32` the bool text, `32..64` the float fraction, `64..128` the i32 digits, `128..160` the digits `$__i32_to_str` writes backwards, `168..174` the fraction digits of `$__f64_to_str`. |

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
made `d.lookup("a").unwrapOr(0)` answer `0` for a key that is present — the
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
  return shape was invisible: `Dict.lookup`'s `?V` read as a box, `hasKey()`
  printed `0`/`1` for a `bool`, `values()` and a `string`-returning method printed
  a **pointer**.

**The generic-parameter limit this leaves, deliberately.** Nothing here
monomorphises, so `Array<K>` and `?V` carry `K`/`V` as declared: `keys()` on a
`Dict<string, i32>` prints `[256,272]`, and `?V` with `V = string` prints an
address. `elemKindOfTypeRef` reads a type parameter as `.i32`, which is right for
the *slot* and wrong for the *text*. Fixing it needs the instantiated type at the
call site, which this backend does not have.

**Two silent wrong answers remain**, measured over `snapshots/codegen/wasm/` on
2026-09-18 and left for their own row: a **string** reaching `@print` through a
shape `isStringExpr` does not recognise, so the address is printed instead of the
text. (A third, `record_a_method_named_print_is_called_on_the_record`
— `@print(d.print())` → `276` — is fixed by the method-symbol registration
above, and its fixture now records `doc:hi`.)

| Fixture | Written | Printed | Means |
|---|---|---|---|
| `tuple_chained_positional_access_and_a_method_on_an_element` | `@print(t.1)` | `256` | `x` |
| `tuple_labels_resolve_to_positions_on_every_backend` | `@print(row.name)` | `256` | `SP` |

Both are a **labelled or positional tuple element whose type is a string**: the
element's shape is known to `printShapeOf` (it builds `((ii)s)` for the tuple) but
not to `isStringExpr`, which is what `@print` asks for a single value.

The class was found by scanning every `RUN LOG` in the directory for a bare
integer ≥ 256 (the first data offset) or a bracketed list of them. Six files
matched: the three above, and three whose numbers are the value the program
actually computes (`loop_filter_with_conditional_break` `[250,400]`,
`template_end_to_end_generic_expr_via_code_builtin` `8081`,
`template_end_to_end_yaml_model_computes_a_labeled_tuple` `8005`). **No fixture
printed a record or a variant**, which is why the trap above re-recorded no
existing file — the addresses §7 owes were only ever in the language cells. Any
new fixture whose log holds such a number is worth re-reading against this table.

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

## Rules

- **Layout is part of the model where the output depends on it** — as in
  `erl_ast.zig`. A `Line` carries its column because the historical layout is
  not uniform (an `if` arm's body keeps the function column, an optional-field
  guard and a loop's scaffolding indent to 8), and `Func.locals` is a list of
  lines because the hand-tuned helpers group declarations. Don't "tidy" these:
  `snapshots/codegen/wasm/` is byte-compared, and 280 `WASM TEXT` blocks are
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
