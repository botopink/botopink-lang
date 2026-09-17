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
| `wat_ast.zig` | **Types**: `ValType` (`i32`/`i64`/`f32`/`f64`, with `parse` for the backend's spelled type names), `Stack` (`none`/`value`/`terminated`, with `fits(?ValType)`), `Width` (`full`/`byte` — `…8_u` / `…8`), `MemArg` (`ty`, `width`, `offset`). **Instructions**: `Instr` (`const` with the numeral as spelled, `local_get`/`local_set`/`local_tee`, `global_get`/`global_set`, `op` = `<ty>.<name>`, `convert` (a fully-spelled conversion opcode), `load`/`store`, `call`, `br`/`br_if`, `drop`, `return`, `unreachable`, `memory_copy`, `if`, `block` (`block` or `loop`), `comment`). **Layout**: `Line` (instruction + `indent` + trailing `;; comment` + `folded`), `Seq` (lines + stack), `If.Arm.Layout` (`block` vs one-line `inline_`). **Forms**: `Param`, `Local`, `Func` (name, exports, params, result, `locals` as *lines* so a helper can group several, body), `Global`, `FuncType`/`Import`, `Memory`, `DataSegment` (offset + length prefix + raw bytes), `Item` (import/memory/start/data/global/func/comment), `Module` (items). **Invariants**: `Invalid`, `validateFunc`, `validateModule`, `declaresCall`. **Helpers**: `Helper` (symbol + group), `HelperGroup`, `HelperSet` (`require` closes over dependencies — `print_str`/`print_bool`/`print_f64` all pull in `print`). **`Builder`**: arena + `seq`/`param`/`localLines`/`func` (which validates) + `helper`. |
| `wat_emitter.zig` | `renderModule` (validates, then `(module …)`; there is no bare-form entry point). Owns: the two-space item column, the four-space body column and each construct's arm columns, `$`-prefixing, folded (`(call $main)`) vs flat form, inline `(then i32.const 0 return)` arms, `offset=` suppressed when zero, and the data-segment escaping (four little-endian length bytes as `\xx`, then `\n`/`"`/`\`/`\t`/`\r`/`\xx` for control bytes). |
| `wat_prelude.zig` | The runtime helpers wasm has no opcode for, as `Func` nodes: `print` (`$__write_bytes`, `$__print_nl`, `$__print_sp`, `$__print_i32`, `$__print_i32_raw`, `$__memmove`), `print_str`, `print_bool`, `print_f64`, `arr_at`, `str_concat`, `str_eq`, `str_slice`. `items(group)` returns a group's forms (functions plus the comments between them), `order` the order a module appends them in, `fd_write_import` the one host import the print group needs. Scratch layout below the data section (which starts at 256): `0..8` the WASI iovec, `8` the newline byte, `16..32` the bool text, `32..64` the float fraction, `64..128` the i32 digits. |

## Consumers

- `../wat.zig` — builds every instruction, function, global and data segment as
  nodes (`Emitter.emit`/`emitC`/`emitAt`/`note`/`item`, `Capture` + `open`/`seal`
  for a nested body), assembles the module's item order, and calls
  `renderModule`.

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
