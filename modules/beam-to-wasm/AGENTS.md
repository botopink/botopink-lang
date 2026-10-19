# modules/beam-to-wasm

> Path: `modules/beam-to-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

A standalone utility, `.beam` in, wasm out (decisions 434 (3), 438; front 144 B-00b). It takes any
`.beam` files — erlc's output of a botopink cell or sidecar, the compiler's own assembler's, a
module any BEAM compiler produced (Erlang, Elixir, Gleam …) — and translates them whole, module by
module, a call from one module of the set to a function another exports followed. It reads
bytecode, never the language it came from. A BIF or OTP function is bound to the export std-wasm's
OTP table names (`std_wasm.otp.table`, decision 450 (2)) — std-wasm's implementations over its
Erlang terms, never translated from OTP's own `.beam`; no caller passes a table. What it does not convert — an opcode, a
call nothing serves, an operand or a literal of another kind — refuses the function that holds it,
named; the refusal reaches a caller only when a call reaches that function, located
(`` `re:run/3` in `mymod:f/1` ``). **It has no role in botopink for now (decision 452):** the
compiler's comptime never calls it — a host function reached at build answers by its `std:` cell
(std-wasm) or its `.Wasm(body: …)` cell, and an `.Erlang` cell never runs at
build — and compiler-core imports nothing of this module (`build.zig` wires it to its own tests
only). It stays a utility with its tests and fixtures, knowing only std-wasm; decision 439 (an
Erlang cell it refuses is final) no longer applies.

## Standalone (decision 438 (3))

`modules/beam-to-wasm` imports Zig's `std` — and may import std-wasm (`std_wasm`) — and nothing
else: no compiler-core, `manifest`, `bpmp`, AST, library resolution or diagnostic type. Root
`build.zig` checks it once the module graph is wired (`requireStandalone`, the last thing `build`
does): any other entry of the module's import table — or of its test module's — fails the build,
named, before a step runs. A file outside `src/` cannot be imported at all (Zig refuses a path
outside a module's root), so the import table is the whole check.
std-wasm is the one module it imports besides `std` (decision 450 (2)): its OTP table binds every
BIF and OTP call (`Bif` is std-wasm's `otp.Bif`), and its term library (`term.zig`, `otp/*.zig`)
is the runtime the translated code calls. A comptime check in `lower.zig` holds this module's view
of the term ABI to std-wasm's: every name `runtime` lists and every operator's export is one of
std-wasm's runtime exports (`otp.isRuntimeExport`), every `runtime.Kind` its number in
`term.Kind`.

## Tree

```text
beam-to-wasm/
├── AGENTS.md          ← you are here
└── src/
    ├── root.zig       ← `translateSet(arena, files) → SetResult{ ok: []ir.Module, refused: Refusal }`, `translate` (a set of one), `find`, `refusalReaching`, `testdata`
    ├── chunks.zig     ← the IFF container: `AtU8` (both forms), `Code`, `StrT`, `ImpT`, `ExpT`, `LitT` (zlib or stored, `std.compress.flate`)
    ├── code.zig       ← the instruction stream: every opcode of `genop.tab` (`genop`, OTP 28: 1–184) and the compact-term operands
    ├── lower.zig      ← BEAM instructions → `ir.Function`s; the runtime ABI it calls (`runtime`)
    ├── ir.zig         ← the answer: wasm functions as a structured instruction tree over `i32` terms
    └── testdata/
        ├── bp_cell_bang.beam, bp_cell_wrap.beam   ← the two measured cells, assembled by the compiler
        └── erlc/greeting{,_text}.{erl,beam}       ← two modules compiled by `erlc` outside botopink (OTP 28, `erlc +deterministic`)
```

## How a translation works

- **Input**: `.beam` bytes, a set, handed whole by the caller. The two `bp_cell_*.beam` fixtures
  were assembled by the compiler's own assembler (a template read the way the beam target reads
  every Erlang template) when the comptime still translated Erlang cells (decisions 434, 438);
  they stay as measured inputs.
- **The container**: `AtU8` in the length-byte form and OTP 28's compact form (a negative count,
  each length a compact `u`), `StrT` (what a `string` segment of `bs_create_bin` copies), `LitT`
  zlib-compressed or stored (an uncompressed size of 0, as OTP 28 writes a small table). The rest
  (`Line`, `Meta`, `Type`, `Attr`, `CInf`, `Dbgi`, `Docs` …) is skipped.
- **Decoding**: every opcode `genop.tab` numbers is read, with its operand count (`code.genop`), so a
  module decodes whole; operands include the extended `list`, `fr`, `alloc`, `literal` and `tr`
  (a typed register, read as its register). A number outside the table is a whole-module refusal
  (`opcode 200, which genop.tab (OTP 28) does not number`): nothing after it can be read.
- **Refusals**, per function, in order: a call nothing serves — `` `re:replace/4` `` (named first:
  what the code calls is what a reader can act on); an opcode the lowering has none for —
  `opcode 171 (make_fun3)`; an operand or a literal of a kind it does not convert. The function's
  `refused` holds it and its body is empty; the module's other functions translate.
  `refusalReaching(set, module, function)` walks the calls from a function through the set and
  answers the first refused function it reaches (or a callee no module of the set has), located —
  `Refusal{ what, module, function }`, formatted `` `what` in `module:function` ``. Whole-set
  refusals: a file that does not read as BEAM, two files of one module.
- **Calls**: `call` / `call_last` / `call_only` reach this module's function by its entry label;
  `call_ext*` naming a module of the set reach the function it exports (an unexported one is a call
  nothing serves); an `erlang` operator (`+`, `-`, `div`, `band` …, `runtime.operators`) or an OTP
  function of std-wasm's table (`Bif`) is a runtime export; anything else is a call nothing serves. A tail call is a call and a return (the stack, not
  a jump: an Erlang loop's depth is its iteration count, as on the comptime runtime). `bif*` /
  `gc_bif*` with a fail label clear the exception and jump there (a guard); with `{f,0}` it raises.
- **Control flow**: a BEAM function is a graph of labels, wasm's control is structured. A function
  becomes `block $raise (loop $dispatch (block $L<n> … (block $L<first> <dispatch on pc>) <code of
  first> …) <code of last>)`: leaving block `$L` lands on label `L`'s code, which falls through
  into the next label's as BEAM code does; a jump (and a failed test, and each `select_val` /
  `select_tuple_arity` arm) sets the local `pc` and branches to `$dispatch`. A call that leaves an
  exception pending (`rt_pending`) branches to `$raise`, and the function answers 0 — its caller
  tests `rt_pending` in turn, the convention of the comptime runtime's own lowering.
- **Registers**: `x<N>` a local (the first `arity` the parameters); `y<N>` a word of the function's
  frame on the process's root stack (§ Memory); `line` and `init_yregs` have nothing to do.
- **The runtime ABI** (`lower.runtime`): terms (`rt_nil`, `rt_atom`, `rt_bin`, `rt_int`,
  `rt_cons`, `rt_hd`, `rt_tl`, `rt_tuple`, `rt_tset`, `rt_elem`, `rt_tuple_arity`), tests (`rt_is`
  with `runtime.Kind`, `rt_eq`, `rt_eqx`, `rt_cmp`), the binary builder (`rt_bb_new`, `rt_bb_bin`,
  `rt_bb_int`, `rt_bb_utf8`, `rt_bb_end`), exceptions (`rt_pending`, `rt_clear`,
  `rt_function_clause`, `rt_badmatch`, `rt_case_clause`, `rt_if_clause`) and the operators.
  Each is std-wasm's (`modules/std-wasm/src/term.zig`), checked at compile time.
- **Output**: `ir.Module{ name, functions }` per file, for the caller to emit.

## Memory (decisions 448, 449 (3), 450 (5); 144 B-30)

Translated code's terms live on the current process's heap (std-wasm's `heap.zig`), collected by
copying; the host emitting the IR binds the term library's `env.bp_term_alloc(n, layout)` to
`heap.alloc` (each cell with its layout, `term.cellLayout`), `env.bp_term_static` (an atom) to
`heap.static`, and calls `heap.termRoots` once the process's heap is current (`ir.zig` § Memory).

- **A collection runs only at a collection point**: `test_heap Need Live` and `allocate_heap*
  StackNeed Need Live` lower to `collect{ need, live }` — `heap.reserve` of `need` bytes
  (`lower.needBytes`: a word 16 bytes, a float 24, a fun 32, the cells' sizes with their block
  headers; `{alloc, [{words, W}, {floats, F}, {funs, N}]}` decoded by kind), its roots x0 …
  x<Live − 1> (the host stores them beside the root stack, then loads them back) and the whole root
  stack. `alloc` itself never collects.
- **Every y register lives on the root stack**, never in a wasm local: `allocate*` pushes a frame of
  StackNeed words, zeroed (`frame_push`); `deallocate` pops it, and `call_last` / `call_ext_last`
  pop their `Dealloc` frame before the call — its y registers are dead once the arguments are in
  the x registers, so an Erlang loop's frames do not pile up. A function that pushes a frame keeps
  the stack's depth at its entry (`frame_save`) and a raise leaving it restores it
  (`frame_restore`). So a term a caller keeps across a call whose callee collects is a root and is
  moved with it; an x register is live across no call (BEAM's convention), and an `rt_*` call never
  collects.

## The opcodes converted

`label`, `func_info`, `int_code_end`, `line`, `executable_line`; calls `call`, `call_last`,
`call_only`, `call_ext`, `call_ext_last`, `call_ext_only`, `bif0`, `bif1`, `bif2`, `gc_bif1`,
`gc_bif2`, `gc_bif3`; frames `allocate`, `allocate_heap`, `allocate_zero`, `allocate_heap_zero`,
`test_heap`, `init`, `init_yregs`, `deallocate`, `return`; tests `is_lt`, `is_ge`, `is_eq`,
`is_ne`, `is_eq_exact`, `is_ne_exact`, `is_integer`, `is_float`, `is_number`, `is_atom`, `is_nil`,
`is_binary`, `is_list`, `is_nonempty_list`, `is_tuple`, `is_map`, `is_function`, `is_boolean`,
`test_arity`, `is_tagged_tuple`, `select_val`, `select_tuple_arity`, `jump`; data `move`, `swap`,
`get_list`, `get_hd`, `get_tl`, `get_tuple_element`, `put_list`, `put_tuple2`; errors `badmatch`,
`case_end`, `if_end`; `bs_create_bin` with `string`, `binary` (size `all`), `integer` (whole bytes,
no flags) and `utf8` segments. Everything else of `genop.tab` — funs (`make_fun3`, `call_fun2`),
`try` / `catch`, receive and messages, binary matching (`bs_start_match4`, `bs_match` …), maps
(`put_map_*`, `get_map_elements`), floats (`fmove` …), `trim`, `raise`, `apply` — is refused,
named, in the function that holds it: the set grows by a measured need (decision 435).

## Measured — what a comptime evaluation reached (144 B-00b, before decision 452)

Two measurements, each recording every comptime module's Erlang text
(`runtime.evalWithArg`) and every host function `host_cells.forRuntime` carried with its cells.

**Over `conformance` (four targets, `--cold`), `zig build test` and `zig build test-libs`
(botopink-lang before decision 434, 686 comptime modules)** — the cells:

| Cell | Where | Erlang template | Served by |
|---|---|---|---|
| `hash.contentHash` (std) | `modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/decorator_host_cells`, `modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/comptime_std_host_function`, `modules/decisions-taken/decorator_calls_host_comptime_cell-341/cases/decorator_imported_host_function`, `modules/hole_imported_val_known_at_build` | djb2 template | std-wasm (`std:hash.contentHash`, decision 440) — never translated |
| `bang` (test cell) | `modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/decorator_host_cells`, `modules/decisions-taken/decorator_calls_host_comptime_cell-341/cases/decorator_imported_host_function`, `comptime/tests/decorator_invocation.zig` | `<<($0)/binary, "!">>` | beam-to-wasm |
| `wrap` (test cell) | `modules/decisions-taken/decorator_calls_host_comptime_cell-341/cases/decorator_imported_host_function` | `<<"<", ($0)/binary, ">">>` | beam-to-wasm |

Their `.beam` (the compiler's assembler): `label`, `func_info`, `int_code_end`, `call_ext`,
`allocate`, `test_heap`, `deallocate`, `return`, `is_binary`, `jump`, `move`, `put_list`,
`init_yregs`; imports `erlang:iolist_to_binary/1`, `erlang:error/1`.

**Whole modules — every library repository under `repository/` at comptime (`zig build test-libs
--cold`, every library and every rakun member × commonJS, erlang; botopink-lang with B-00a–f, 350
comptime modules):**

- **Host functions carried: none.** No library comptime module — decorator, template or
  `comptime` body of erika, jhonstart, rakun, styled, css, emilia, onze, routing, validation, snap,
  json, yaml, markdown, dbcontext, actions, http, log — reaches a host function: no `bp_cell_`
  call, no `bp_std_wasm` call, no `.Erlang` cell to translate.
- **`.erl` sidecars and library modules reached: none.** Every remote call a library comptime
  module makes is OTP's, each already a BIF of the comptime runtime: `binary:match/2`, `part/3`,
  `replace/4`; `erlang:atom_to_binary/1`, `element/2`, `erase/1`, `error/1`, `float/1`,
  `integer_to_binary/1`, `is_atom/1` … `is_tuple/1`, `length/1`, `max/2`, `min/2`, `throw/1`,
  `trunc/1`, `tuple_to_list/1`; `io_lib:format/2`; `json:encode/1`; `lists:filter/2`, `foldl/3`,
  `foreach/2`, `join/2`, `map/2`, `member/2`, `nth/2`, `nthtail/2`, `reverse/1`, `sublist/2,3`,
  `zipwith/3`; `maps:get/2`, `map/2`; `string:find/2`, `lowercase/1`, `prefix/2`, `split/3`,
  `trim/1,2`, `uppercase/1`; `unicode:characters_to_binary/1`, `characters_to_list/1,2` — the
  comptime module's own lowering, never a translated `.beam`.
- So no library cell calls a function of another of its modules at comptime today: a whole-module
  translation has no library caller yet. Its need is measured by the `erlc` fixture: two modules,
  a call between them, the opcodes above plus `call`, `call_last`, `call_only`, `call_ext_last`,
  `call_ext_only`, `gc_bif2` (`+`), `is_nil`, `is_nonempty_list`, `is_eq_exact`, `get_list`,
  `get_tl`, `bs_create_bin`, `line`; OTP functions `lists:reverse/1`, `string:uppercase/1` and
  `string:titlecase/1` — the last one added to std-wasm (`text.titlecase`) for it.
  `erlang:get_module_info/1,2` (every `erlc` module's `module_info`) is served by nothing:
  refused where reached.

## Tests

`zig build test` runs `src/root.zig`'s tests: the chunk reader on a measured cell, each compact-term
tag and value width, the extended `literal` / `list` / `tr` / `fr` / `alloc` terms (`alloc` by kind), every `genop`
opcode decoding (and its table matching OTP's numbering), the two cells translated (one function,
its BIF calls, `put_list` conses, `is_binary`, literals materialised), an opcode outside the
converted ones refusing the function, by name and located, a file that is not BEAM; and `erlc`'s two modules translated as a set (`translateSet`: compact atoms, a stored
`LitT`, `StrT`, the call from `greeting` into `greeting_text`, local and tail calls, `get_list`,
`gc_bif` `+`, `is_eq_exact`, `bs_create_bin`; `shout_all/2`'s frame pushed, its `test_heap`
a collection point of its one live register, its tail call popping the frame first), the `module_info` functions refused only where
reached, a module left out of the set refused where the call is made, an OTP function std-wasm's
table lacks (`erlang:get_module_info/1`) refused where it is reached, two files of one module. Nothing else runs it: compiler-core no longer holds a consumer
of this module (decision 452). Regenerate the fixture with `erlc +deterministic greeting.erl greeting_text.erl` in `src/testdata/erlc/`.
