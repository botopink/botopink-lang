# modules/beam-to-wasm

> Path: `modules/beam-to-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

`.beam` bytecode translated to wasm (decision 434 (3), front 144 B-00b): code that exists only as
BEAM — a host function's `@External.Erlang` / `@External.Beam` cell, an `.erl` sidecar — runs at
comptime on the one comptime runtime, wasm. It converts a **named subset** (decision 435): the
opcodes and BIFs the measurement below lists, each BIF served by the comptime runtime (its term
library and std-wasm); anything else is refused, named, and the compiler reports it at the call
site of the function the code serves. The subset grows by a measured need, never by OTP's size.

## Tree

```text
beam-to-wasm/
├── AGENTS.md          ← you are here
└── src/
    ├── root.zig       ← `translate(arena, bytes, bifs) → Result{ ok: ir.Module, refused: what }`
    ├── chunks.zig     ← the IFF container: `AtU8`, `Code`, `ImpT`, `ExpT`, `LitT` (zlib, `std.compress.flate`)
    ├── code.zig       ← the instruction stream: opcodes (`genop.tab` numbers) and compact-term operands
    ├── lower.zig      ← BEAM instructions → `ir.Function`s; the runtime ABI it calls (`runtime`)
    ├── ir.zig         ← the answer: wasm functions as a structured instruction tree over `i32` terms
    └── testdata/      ← `bp_cell_bang.beam`, `bp_cell_wrap.beam`: the two measured cells, assembled by the compiler
```

## How a translation works

- **Input**: `.beam` bytes. At comptime the compiler produces them itself — a cell's template read
  and lowered the way the beam target compiles every Erlang template
  (`compiler-core/src/codegen/beam/erl_template.zig`) and assembled by
  `codegen/beam/beam_file.zig`; no `erlc` runs while compiling
  (`compiler-core/src/comptime/runtime/wat/cells.zig`).
- **Refusals, in order**: a file that does not read as BEAM; an import (`ImpT`) the runtime has no
  BIF for — `` `re:replace/4` `` (named first: what the code calls is what a reader can act on); an
  opcode outside the subset — `opcode 8 (call_ext_last)` (decoding stops there: its arity is not
  known); an operand or a literal of a kind it does not convert.
- **Control flow**: a BEAM function is a graph of labels, wasm's control is structured. A function
  becomes `block $raise (loop $dispatch (block $L<n> … (block $L<first> <dispatch on pc>) <code of
  first> …) <code of last>)`: leaving block `$L` lands on label `L`'s code, which falls through
  into the next label's as BEAM code does; a jump (and a failed test) sets the local `pc` and
  branches to `$dispatch`. A call that leaves an exception pending (`rt_pending`) branches to
  `$raise`, and the function answers 0 — its caller tests `rt_pending` in turn, the convention of
  the comptime runtime's own lowering.
- **Registers** are locals `x<N>` (the first `arity` the parameters) and `y<N>`; the frame and
  heap opcodes have nothing to do (a y register is a local of the call; terms live on the runtime's
  arena).
- **The runtime ABI** (`lower.runtime`): `rt_nil`, `rt_atom(ptr, len)`, `rt_bin(ptr, len)`,
  `rt_int(i64)`, `rt_cons(h, t)`, `rt_is(t, kind)` (`kind_binary` = 1, checked against `rt.zig`'s
  `Kind` at compiler-core's compile time), `rt_pending`, `rt_function_clause`; a BIF is the export
  the caller's `Bif` table names (compiler-core passes its wat lowering's table,
  `lower.beam_to_wasm_bifs`).
- **Output**: `ir.Module{ name, functions }`; compiler-core's wat lowering emits each function a
  comptime module calls (`bp_cell_<hash>:t/N`) into the program (`emitCellFunction`) and lists it
  in the `COMPTIME WAT` section.

## Measured — what a comptime evaluation reaches (144 B-00b, 2026-10-11)

Measured over `tests/language` (four targets, `--cold`), `zig build test` and `zig build test-libs`
(every library repository) on botopink-lang `239f789f` (686 comptime modules recorded):

| Cell | Where | Erlang template | Wasm cell |
|---|---|---|---|
| `hash.contentHash` (std) | `run/decorator_host_cells`, `run/comptime_std_host_function`, `modules/decorator_imported_host_function`, `modules/hole_imported_val_known_at_build` | djb2 template | `fn:contentHashBody` — served by std-wasm first, never translated |
| `bang` (test cell) | `run/decorator_host_cells`, `modules/decorator_imported_host_function`, `modules/decorator_erlang_cell_only`, `comptime/tests/decorator_invocation.zig` | `<<($0)/binary, "!">>` | `fn:bangBody` (absent in `decorator_erlang_cell_only`) |
| `wrap` (test cell) | `modules/decorator_imported_host_function` | `<<"<", ($0)/binary, ">">>` | `fn:wrapBody` |

- **`.erl` sidecars reached at comptime: none** — no comptime module calls a library module
  (jhonstart's `jhonstart_render`, rakun's sidecars …); the BEAM comptime node never loaded one, so
  such a call was `undef` before 434 as well. A sidecar call is refused, named, like any import the
  runtime has no BIF for.
- **`@External.Beam("module", "symbol")` host functions reached: none.**
- **The opcode subset** — the compiler's BEAM lowering of the two cells' template modules:
  `label` 1, `func_info` 2, `int_code_end` 3, `call_ext` 7, `allocate` 12, `test_heap` 16,
  `deallocate` 18, `return` 19, `is_binary` 53, `jump` 61, `move` 64, `put_list` 69,
  `init_yregs` 172; operands `x`, `y`, `atom`, `nil`, `integer`, `literal` (a binary, an atom, an
  integer, `[]`), `f` labels, `{list, …}`.
- **The BIFs** — every import of those modules: `erlang:iolist_to_binary/1`, `erlang:error/1`;
  bound to the comptime runtime's whole BIF table, the same one its lowering of a comptime module
  calls (`erlang`, `lists`, `maps`, `string`, `binary`, `unicode`, `math`, `io_lib`, `json`).

## Tests

`zig build test` runs `src/root.zig`'s tests: the chunk reader on a measured cell, each compact-term
tag and value width, the extended `literal` / `list` terms, an unknown opcode stopping the stream,
the two cells translated (one function, its BIF calls, `put_list` conses, `is_binary`, literals
materialised), a call outside the BIF table refused by name, an opcode outside the subset refused
by name, a file that is not BEAM. compiler-core's `runtime/wat/cells.zig` tests the producer side.
