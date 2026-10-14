# modules/std-wasm

> Path: `modules/std-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

botopink's wasm runtime in Zig — std's functions, the stack, the heap (decisions 434 (2), 440, 441,
442, 447, 448, 449, 450, 454; front 144 B-00a, B-00e, B-00g, B-00i, B-30): std's host functions,
the Erlang terms with the OTP functions over them, and the heap a process allocates on (`heap.zig`).
One implementation for two consumers: the comptime
runtime, on every target (434 (5): a comptime result is std-wasm's answer whatever `--target`
says), and a `--target wasm` program, into which the codegen transpiles the functions it calls
(440 (2)). A std function is served by std-wasm only where its
`#[@External.Wasm(std: "<module>.<function>")]` cell names one of `root.exports` (440 (3)) —
there is no match by name. Everything a `--target wasm` program computes over values — text,
a number's text, arrays, `bigint` — is here, not in the codegen's `wat_prelude` (442 (2));
`root.program` lists the functions only the wasm codegen calls.

## Two value representations (decision 450 (4))

Each in its own file, both compiled into the one `std_wasm.wasm`:

| Representation | File | What a value is | Who computes over it |
|---|---|---|---|
| The wasm codegen's typed layout | `wasm.zig` | a string the address of its `u32` length with the bytes behind it; an array `[n][slot…]`; a `bigint` a limb block; an `f64` / `i32` / `i64` by its wasm type | a `--target wasm` program (the `std:` exports) |
| The Erlang terms | `term.zig` (+ `otp/*.zig`, `term_faces.zig`) | an `i32` pointer to a `Hdr`-prefixed cell: integers (i64), floats, interned atoms, binaries, cons cells and `[]`, tuples, maps, funs, a binary builder | the comptime runtime (the `rt_*` exports), and BEAM code beam-to-wasm translates |

The pure algorithms (`text`, `number`, `array`, `bigint`, `hash`, `random`) know neither layout:
each face turns its values into slices and back. Allocation is the caller's in both (decision
450 (5)): a program face's value comes from `env.bp_alloc` — a program's `$__alloc`; a term from
`env.bp_term_alloc(n, layout)` — the comptime's arena
(`compiler-core/src/comptime/runtime/wat/runtime_module.zig`), which drops the layout, or the
current process's heap in translated code (`heap.alloc`, 449 (3)) — with the layout of its cell
kind (`term.cellLayout`: each pointer field of the cell on wasm32, a term array
`pointersFrom(0)`, bytes `raw`; a comptime assertion holds the cells' words to it); and an atom,
interned and compared by address, with a copy of its name, from `env.bp_term_static(n)` —
outside every process's heap (`heap.static`), never moved. A term fun is called back through the caller's table
(`env.bp_call0` … `bp_call4`), so the module holds no function table; and no `var` starts as a
pointer, no `switch` answers a string and no table holds slices — any of those is a relocation in
the module's data (`__wasm_apply_data_relocs`), which `std_wasm_link.zig` refuses.

## Tree

```text
std-wasm/
├── AGENTS.md      ← you are here
└── src/
    ├── root.zig   ← the package: `exports` (each function by its `std:` name, its botopink types), `program` (the wasm codegen's own calls, by wasm types), `find`, `matches`, `signatureText`, `names`, `erlang_module`; re-exports the files below
    ├── hash.zig   ← `hash.contentHash`
    ├── case_tables.zig ← GENERATED (`zig build gen-unicode`): the case mappings as `switch`es (decision 443)
    ├── text.zig   ← the text algorithms behind std's string primitives (commonJS's `__bp_trim` and case helpers answer the same set and table, decision 521) (case over all of Unicode, titlecase, trim, graphemes, slice, reverse, find, split, replace; and a program's: code point length / offset / slice / `at`, `indexOf` / `lastIndexOf`, `charCodeAt`, `fromCodepoint`, `Split` / `Lines` / `Words`, pad, repeat, replace)
    ├── number.zig ← `shortFloat`: `float_to_binary(F, [short])` — fixed or `D.DDDeE` whichever is shorter, `D.DDDeE` from 2^53 on as OTP writes it —, std's `Float.toString`, and the text commonJS's `__bp_f64` ports (decision 521) (`NaN`, `Infinity`, `-Infinity` for the values OTP has no float for); `signedText` / `unsignedText`, an integer's digits; `isDigits`, `integerOf` and `floatOf`, what `String.parseInt` / `parseFloat`'s host helpers convert (`number.isDigits`, `number.toInteger`, `number.toFloat`, `number.numeralRefused`; `floatOf` correctly rounded over `bigint`'s limbs by hand — `std.fmt.parseFloat`'s slow path holds a table of slices)
    ├── array.zig  ← an array's algorithms over its slot words: `sliceRange`, `chunkCount`, `slidingCount`, `uniqueInto`, `search`
    ├── heap.zig   ← the heap (decisions 448, 449): a heap per process, `alloc` on the current one, copying collection (minor and major), the write barrier on mutable cells, a message copied between heaps (a cycle refused, decision 522), a heap released whole, exhaustion an error the program face traps on — § The heap
    ├── random.zig ← `io/random`'s seeded stream (decision 451): `Stream`, Mulberry32 as the commonJS sidecar draws it; no draw before a seed
    ├── bigint.zig ← `bigint`'s arithmetic over `u32` limbs (add, sub, mul, divmod, compare, decimal text both ways, `toI64`, `toF64`), tested against `std.math.big.int`
    ├── wasm.zig   ← the program face (`zig build std-wasm`): each export over a program's own strings, arrays and `bigint` blocks, allocating through `env.bp_alloc`; the seeded stream's state a `.bss` `Stream`, an unseeded draw `env.bp_random_f64`; it also exports every `rt_*` function of the term files under its own name
    ├── env.zig    ← what std-wasm imports from its caller: `bp_alloc` (a program face's value), `bp_term_alloc(n, layout)` and `bp_term_static(n)` (a term's, an atom's), `bp_random_f64`, `bp_call0` … `bp_call4`
    ├── term.zig   ← the Erlang terms (decision 450): cells (each allocated with its layout, `cellLayout`), atoms (`atomRank`; outside every heap, their names copied), numbers, binaries, lists, tuples, funs (`applyFun` through `env.bp_call<N>`), exceptions (`pending`, class, reason, and where the last raise was — `rt_raised_at` / `rt_raised_at_term`, decision 451 (3)), type tests (`Kind`), term order and equality (`compare`: iterative, an explicit work list, never the runtime's stack — decision 471), maps, the operators, the binary builder; `rt_reset`
    ├── term_faces.zig ← each `exports` entry's comptime face over terms, `rt_std_<symbol>` (a comptime `@compileError` refuses an entry without one)
    ├── otp.zig    ← the OTP table (`table`: `module:name/arity` → its `rt_*` export, `Bif`), the term files (`files`), `isRuntimeExport`
    └── otp/       ← the OTP functions and BIFs over terms: `erlang.zig` (BIFs, the process dictionary, `apply/2`), `lists.zig`, `maps.zig`, `string.zig`, `binary.zig`, `unicode.zig`, `math.zig`, `io_lib.zig` (`io_lib:format`, `io:format`, `rt_printed`, `rt_describe`), `json.zig` (`json:encode`), `etf.zig` (the ETF argument, `rt_etf_decode`)
```

## The functions (`root.exports`)

| `std:` name | Types | Bound by (std) |
|---|---|---|
| `hash.contentHash` | `(string) -> string` | `hash.contentHash` |
| `text.trim` | `(string) -> string` | `String.trim` (`primitives.bp`) |
| `text.trimStart` | `(string) -> string` | `String.trimStart` |
| `text.trimEnd` | `(string) -> string` | `String.trimEnd` |
| `number.floatToString` | `(f64) -> string` | `Float.toString` — and every float a wasm program turns into text |
| `text.length` | `(string) -> i32` | `String.length` (code points, decision 240) |
| `text.split`, `text.chars`, `text.lines`, `text.words` | `(string, string) -> string[]`, `(string) -> string[]` | `String.split`, `chars`, `lines`, `words` |
| `text.contains`, `text.startsWith`, `text.endsWith` | `(string, string) -> bool` | the `String` methods of those names |
| `text.indexOf`, `text.lastIndexOf` | `(string, string) -> i32` | code point indices |
| `text.at` | `(string, i32) -> ?string` | `String.at` |
| `text.charCodeAt` | `(string, i32) -> i32` | `String.charCodeAt` |
| `text.padStart`, `text.padEnd` | `(string, i32, string) -> string` | the pad cycled, by bytes |
| `text.repeat` | `(string, i32) -> string` | `String.repeat` |
| `text.replace`, `text.replaceAll` | `(string, string, string) -> string` | an empty pattern matches before every byte |
| `text.fromCodepoint` | `(i32) -> string` | `String.fromCodepoint` — no scalar value traps |
| `text.toUpper`, `text.toLower` | `(string) -> string` | `String.toUpper` / `toLower` — over all of Unicode, OTP's answer (below) |
| `random.seed` | `(i32) -> void` | `io.random.seed` — the stream restarts from the word's bits |
| `random.float` | `() -> f64` | `io.random.float` (decision 456) — an unseeded draw: in a program the host's entropy (`env.bp_random_f64`, as `seededFloat` before a seed); at comptime always refused with decision 451's message, never `comptime-host-cell-unavailable` (`rt_std_random__float`) |
| `random.seededFloat` | `() -> f64` | `io.random.seededFloat` — the next draw in `[0.0, 1.0)`; before any seed the host's entropy in a program, refused at comptime (below) |

The types a `std:` cell can spell (`Type`): `string`, `f64`, `i32`, `i64`, `bool`, `void`,
`string[]`, `?string`. Each export has its comptime face, `term_faces.zig`'s `rt_std_<symbol>` (a
`string[]` a list of binaries, a `bool` its atom, a `?string` the binary or `undefined`).

A `std:` cell is std's alone (decision 445): outside std's own modules (`Module.std_member` —
the embedded `std/…` modules, the prelude, and `libs/std` built, checked or tested as itself)
it is refused at the annotation on every target, naming the std function to call instead
(`Export.api`; cell `modules/external_wasm_std_outside_std`). Inside std, a `std:` cell naming
no entry, or on a declaration of other types (`matches`: the parameter and return types as
botopink spells them; a primitive behavior's `Self` is `string` on `String`, `f64` on
`Float`), is refused at the annotation (`comptime/infer.zig` `refuseStdBinding`;
`codegen/tests/wat.zig` pins both over a module of std's own).

## The program's own functions (`root.program`, decision 442 (2))

What the wasm codegen calls by itself — its arguments are the codegen's, not a declaration's:
a string's code point bounds, an array's slot words whatever its element type, an integer
by its carrier, a `bigint` block's address. A `std:` cell names none of them (`find` reads
`exports` alone) and the comptime runtime serves none (a comptime module reaches std's
methods through their `@External.Erlang` cells).

| Function | What the codegen calls it for |
|---|---|
| `text.slice(s, a, b)` | `s.slice(a, b)`, `s[a..b]`, `s[i]` — code point bounds, negative from the end, clamped |
| `number.i32ToString`, `i64ToString`, `u64ToString` | an integer as a fresh string (`toString`, interpolation) |
| `number.i64Text`, `u64Text` | an integer's text in std-wasm's one workspace (`[len][digits]`, overwritten by the next) — what `$__print_i64_raw` / `$__print_u64_raw` write, so a print allocates nothing |
| `array.reverse`, `slice`, `prepend`, `concat`, `zip`, `fill`, `flatten`, `chunked`, `sliding` | `Array`'s methods, a list pattern's rest, a spread |
| `array.joinStrings`, `joinInts`, `joinFloats` | `join` by the element kind |
| `array.indexOfWord`, `indexOfString`, `indexOfFloat` (+ `lastIndexOf…`) | `indexOf` / `contains` / `lastIndexOf` by the element kind (`f64.eq` over a float's cell) |
| `array.unique(xs, mode)` | `unique` — `0` the slot's word, `1` a float cell's bits, `2` a string's content |
| `bigint.add(x, y, flip)`, `negate`, `multiply`, `divmod(x, y, rem)`, `compare`, `equalOptional` | decision 332's operators over block addresses (a zero divisor traps) |
| `bigint.ofI64`, `toI64`, `toF64`, `toString`, `parse` | `BigInt.of`, `toI64()` / `toF64()` (trap past the range / unless exact), the digits, `BigInt.parse`'s numeral (`0` for none) |

| `heap.init(start)`, `spawn`, `enter(h)`, `alloc(n, layout)`, `cell(n, layout)`, `static(n)`, `write(field, v)`, `reserve(need, roots, n)`, `collect(roots, n, full)`, `copy(dst, v)`, `cycle()`, `release(h)`, `used(h)`, `termRoots()` | the heap (§ The heap) — not called by the codegen yet: `alloc` is still `wat_prelude`'s bump (144 B-30 box 3). `copy` answers `0` and `cycle()` `1` when the message holds a cycle (decision 522 5′): the caller raises `message contains a cycle` located at its send. `static` is memory outside every heap (an atom); `termRoots` makes the term library's statics (`term.rootCells`: the process dictionary, the pending exception, the printed text) roots of the current heap — what a host running translated BEAM code calls once its process's heap is current |

`text.toUpper` / `text.toLower` (`(string) -> string`, bound by `String.toUpper` / `toLower`)
map case over all of Unicode (decision 443): the simple mappings of `UnicodeData.txt` and the
unconditional full ones of `SpecialCasing.txt` (`ß` → `SS`, `ﬁ` → `FI`, `İ` → `i̇`), from
`case_tables.zig` — generated by `zig build gen-unicode` from the data std's `unicode` reads
(`libs/std/tools/unicode-gen`), as `switch`es: code, not data, so a program links the tables
only where it maps case. They answer OTP's (`string:uppercase` / `lowercase` / `titlecase`):
no conditional mapping — no final sigma, where a JS engine lowers a word-final `Σ` to `ς`
(`"ΟΔΟΣ".toLower()` is `"οδοσ"` on every target, commonJS through its helper over this table,
decision 521) — and no
language rule. Measured 2026-10-11 code point by code point against OTP 28 (all of U+0000 …
U+10FFFF, upper, lower and title): equal everywhere but the 56 letters Unicode 17 added that
OTP 28's Unicode 16 tables lack (U+A7CE … U+A7D5, U+16EA0 … U+16ED3), which std-wasm maps as
Unicode 17 and node does. The comptime runtime's `string:uppercase` / `lowercase` /
`titlecase` answer through the same functions (`text.caseInto`; its old limit 3 is gone).

The seeded random (decision 451) is `random.zig`'s `Stream` — Mulberry32 over one word,
the commonJS sidecar's (`libs/std/src/sidecars/random.mjs`) draw for draw — bound by the
`std:` cells on `io/random.bp`'s `seed` / `seededFloat`. It holds no entropy: before any
seed `next` answers null, and each face decides what that draw is. A program's
(`wasm.zig`) calls `env.bp_random_f64`, which `std_wasm_link.zig` binds to the program's
`$__wasi_random_f64` — the host's entropy, which stays in `wat_prelude` (it talks to the
host). The comptime's (`term_faces.zig`'s `rt_std_random__seededFloat`) raises
`{bp_wat_runtime, <<"an unseeded draw: …">>}`, which the build reports at the `comptime`
that reached it: a build has no entropy and never pretends to (cells
`modules/comptime_random_seeded`, `modules/comptime_random_unseeded`). Each comptime evaluation
starts from a fresh instance, so its stream is unseeded until its body seeds it, and one
seed answers the same draws on every build and every target.

## The heap (decisions 448, 449, 522; front 144 B-30)

`heap.zig` is erlang's memory model for a wasm program and for translated BEAM code: a heap per
process (a `@Task`; a BEAM process), `alloc` on the current process's heap, collection by copying
the live values, a value copied between heaps as an erlang message is, a heap released whole when its
process ends, and memory exhausted a trap — never damaged data (448 (4)). It is in `program`, never
bound by `std:`, and has no comptime face: the comptime keeps its arena (449 (4)). It allocates nothing
through `env.bp_alloc` — it is what `bp_alloc` becomes (box 3) — and takes its memory from the
program's linear memory itself (`memory.grow`). Natively (its tests) a buffer stands for that memory.
It was designed from the measurement in `compiler-core/src/codegen/wat/AGENTS.md` § How far a program
grows without collection: growth linear in the work, a live set of a few values.

- **The pool.** Every heap's memory comes from one pool over `[start, memory's end)` (`heap.init`:
  `start` is what the program leaves past its data and its stack): free regions in address order,
  coalesced when freed, the memory grown when none fits. A heap is a list of *chunks* from the pool; a
  released heap gives them back.
- **A block** is one `alloc`: an 8-byte header — the payload's size (bit 0 the remembered flag) and its
  *layout* — then the payload, 8-aligned and zeroed. A value may point anywhere inside its block (a
  record's value is its address plus four; a binary's bytes may be another's): each chunk keeps a
  bitmap of where its blocks start (one bit per 8 bytes), through which an address finds its block.
- **A layout** names the pointer words, so the collection knows both value representations (450 (4))
  without guessing: `raw` (0) none; `bitmap(b)` word `i` when bit `i` is set, for the first 31 words;
  `pointersFrom(k)` (`0x8000_0000 | k`) every word from `k` on. A pointer word holding no address of
  the heap (`0`, an ordinal, a literal of the data, an atom) is left alone. A block whose layout says
  less than it holds loses values at a collection, and one that says more rewrites scalars: the
  caller's layout is the contract.
- **Generations** (448 (2)). `alloc` bumps in the nursery and never collects or moves anything: a
  full nursery takes another chunk. A collection runs only at a *collection point* — `reserve(need,
  roots, n)` (when the nursery has fewer than `need` bytes free) or `collect(roots, n, full)` — whose
  `roots` are the address of `n` words, every value the caller keeps across it, rewritten in place.
  A *minor* collection copies what the roots, the remembered blocks and the static cells reach in the
  young generation into the old one and empties the nursery; a *major* one (when the old generation
  passes its limit, or `full`) copies everything live into fresh chunks and frees the rest. Both are
  Cheney's: iterative — the copies are the work list — so no recursion and no stack of their own (447,
  and `std_wasm_link.zig` refuses recursion).
- **The write barrier** is `write(field, v)`, the one store into a mutable cell (a `var`'s cell, a
  task's record): an old block written with a young value is remembered (once, by its flag) and scanned
  at the next minor collection; a cell outside every heap (a module's data) becomes a root of the heap
  for good. Every other value is immutable, so an old value never points at a younger one. A mutable
  cell is allocated as one (`cell(n, layout)`, `allocCell`): a flag of its header, kept by every
  collection and by a message copy.
- **Messages** (448 (3), decision 522). `copy(dst, v)` copies what `v` reaches on the current heap onto
  `dst`'s nursery, Cheney's scan over the copies; nothing of `dst` points into the sender's heap after it.
  The sharing inside the value is not kept, as erlang's message copy. Before copying anything it walks
  what `v` reaches in depth (`cyclic`: an explicit path on the pool, no recursion), marking each mutable
  cell while the walk is below it: a marked cell reached again is a cycle — `error.Cycle`, nothing
  written, every mark cleared; the caller raises `message contains a cycle` located at its send (522 5′),
  never an exhausted memory and a trap. A cell reached again on another path (shared, no cycle) is walked
  and copied again. Only a cell is marked: an immutable value points only at older ones, so every cycle
  passes through a cell.
- **Exhaustion** (448 (4)). When the pool cannot grow (`memory.grow` refused, or past 4 GiB), the
  operation answers `error.OutOfMemory` before writing what it answers; `wasm.zig`'s faces trap on it
  (`unreachable`). A collection that cannot get its to-space traps as well — the run ends; it never
  continues over a half-copied heap.

**The choices 448 leaves to measurement**, confirmed as built by decision 522 (its point 5 changed):

| Choice | Taken | Why |
|---|---|---|
| Generations | young and old; a survivor of one minor collection is promoted at once (erlang keeps it young once more, behind a high-water mark) | 448 (2) is generational (the barrier exists for old → young); the measured programs keep a few values live, so promoting at once costs little and keeps one scan |
| Interior pointers | a start bitmap per chunk (1/64 of the chunk) | a record's value is its address plus four; a binary's bytes and a sub-binary point inside blocks |
| Header | 8 bytes per block (size, layout) | the layout is the only way the collection tells a pointer from a scalar in the typed layout, which tags nothing |
| Sizes | nursery 64 KiB, doubled while more than half of it survives, at most 8 MiB; major when the old generation passes max(256 KiB, twice what the last major kept) | the measured garbage per unit of work runs from 68 bytes to 17.6 KiB |
| Collection points | only where the caller names its roots; `alloc` never collects | a wasm local is invisible to the collector: a value is safe to move only where the caller has written its roots down |
| Message sharing | not kept (a value reached twice is copied twice), as erlang's default; a cycle is detected and refused (`error.Cycle`), never copied (522 5′) | no forwarding written into the sender's live heap; a value is acyclic but through a mutable cell, so the walk marks only cells |
| Cells outside every heap | a root of the heap whose value they hold, for good | a module's `var` in the data is no block a collection could reach |

**Translated BEAM code's terms** (449 (3), 450 (4)) allocate on the current process's heap with
their cells' layouts (`term.cellLayout`), an atom outside every heap (`heap.static`), the term
library's statics roots for good (`heap.termRoots`); beam-to-wasm names its collection points
(`modules/beam-to-wasm/AGENTS.md` § Memory). `codegen/tests/wat.zig` links the term library onto a
heap as such a host does, collects it minor and major under garbage, and compares every kept term
(a decoded nested term, a list of them, a binary a builder made on the heap, the process
dictionary's) with a fresh one after it moved; and, on a memory capped at 16 pages, the same run
traps (`unreachable`) when the memory runs out, never answering a damaged term (448 (4)).

What remains for 144 B-30: `alloc` out of `wat_prelude` onto `heap.alloc` with each allocation's
layout, std-wasm's faces allocating with theirs, the codegen's roots at each collection point (task
frames, scheduler queues, cells) and its `var` stores through `write`; a bounded long-running cell;
the located `message contains a cycle` at a send — each waits on a choice no decision fixes yet:
what layout a word typed by a type parameter has (the backend does not monomorphise), where a
`@Task`'s record lives and how a value reaches another task's heap, and which code may collect
(a wasm local is invisible to a collection).

## How it is built and served

- **Into the comptime runtime** (decision 450 (3)) — the one wasm runtime: `std_wasm.wasm`'s
  runtime exports (`rt_*`: `term.zig`, `term_faces.zig`, `otp/*.zig`) are decoded by
  `std_wasm_link.zig` once per process and emitted into one standalone module
  (`compiler-core/src/comptime/runtime/wat/runtime_module.zig`: `env.bp_term_alloc` and
  `env.bp_term_static` bound to the comptime's arena, `env.bp_call<N>` to a `call_indirect` through the module's table, a 1 MiB
  stack, recursion allowed — each frame still checked against the stack's floor), into which each
  lowered comptime program is spliced (`link.zig`). There is no other build of the terms:
  `bp_wat_rt.wasm` is gone. It serves std-wasm three ways:
  - each entry of `exports` is the runtime export `rt_std_<symbol>` (`rt_std_hash__contentHash`,
    the name's dot written `__`); a comptime module calls it as `bp_std_wasm:<symbol>(…)` —
    `host_cells.forRuntime` rewrites a host function whose `std:` cell names the entry to that one
    cell (`stdCell`, `servedByStdWasm`), and `runtime/wat/lower.zig`'s BIF table maps the
    `bp_std_wasm` family (`std_wasm_bifs`) to the exports;
  - every OTP function of `otp.table` — the one table the lowering (`lower.zig` `bifs`) and
    beam-to-wasm (decision 450 (2)) bind a `module:name/arity` call by;
  - the text BIFs (`string:uppercase/1`, `lowercase/1`, `titlecase/1`, `trim/1,2`, `find/2`,
    `prefix/2`, `split/2,3`, `slice/2,3`, `reverse/1`, `length/1` (graphemes),
    `binary:replace/3,4`, `binary:split/2,3`, `float_to_binary/2` (`[short]`), and the `~p` /
    `json:encode` float text) answer through the same `text` / `number` functions a program's
    faces do — one face per algorithm (`text.Split` cuts every `sep` or the first, `Split.once`;
    `text.replacedLength` / `replaceInto` replace; `number.signedText` writes an integer).
- **Read by compiler-core** (`core_mod`, `core_test_mod`, the browser build's `web_core_mod`):
  `host_cells.zig`, `infer.zig` and `codegen/wat/host_binding.zig` read `exports`.
- **Into a `--target wasm` program** (decision 440 (2)): `wasm.zig` is compiled to
  `std_wasm.wasm`, a position-independent side module (`zig build-lib -dynamic -fPIC`, MVP plus
  bulk memory, `dylink.0`), embedded in compiler-core as the anonymous import `std_wasm.wasm`.
  A Zig `var` (the integer workspace) is `.bss`: wasm-ld gives the side module a start
  function that only zeroes it, which the decoder drops (a fresh instance's memory is zero);
  any other start is refused.
  `codegen/wat/std_wasm_link.zig` decodes the functions a program calls into `wat_ast` and
  `wat.zig` emits them as ordinary functions of the program — one module, its `.wat` the whole
  program, no host change. The side module imports `env.memory`, `env.__memory_base` (the program
  places the data after its own), `env.__stack_pointer` (a program global, a stack after the
  data sized from the code's frames, each frame checked against its floor — decision 447),
  `env.bp_alloc` (the program's `$__alloc`) and `env.bp_random_f64` (the program's
  `$__wasi_random_f64`, decision 451). It holds no
  function table, no start function and no pointer in its data — which is why `shortFloat` takes
  Ryu's digits from `std.fmt.float.render` and writes the exponent by hand rather than through
  `std.Io.Writer`, whose vtable is a function table: the decoder refuses all three.
- **The export names are the cells' text** (`std:hash.contentHash`), never the bare
  `hash.contentHash`: Zig names `hash.zig`'s own `contentHash` that, so an export of that name
  resolves to itself, and the optimizer compiles the recursion to `unreachable`.
- **Built by a `Run` of `zig build-lib`**, not `addLibrary`: wasm-ld warns that a shared library
  is "not yet stable" for every side module, and the build runner fails a compile step on any
  linker stderr. The warning goes to a captured file; a failed compile still fails the step.
- **Tests**: `zig build test` runs `src/root.zig`'s tests (one per function and algorithm; the
  term files natively — a fun runs only on wasm — with the OTP table's own checks);
  `codegen/tests/wat.zig` decodes every `std:` export (`wat: std-wasm ---- …`) and
  `comptime/runtime/wat/runtime_module.zig` links every `rt_*` one.

## Measured — what a comptime evaluation reaches (144 B-00a, 2026-10-11)

Measured over `conformance` (four targets, `--cold`), `zig build test` and `zig build test-libs`
(every library repository) on botopink-lang `239f789f`: every comptime module's Erlang text and
every host function `host_cells.forRuntime` carried were recorded (686 modules).

**Bodyless std host functions reached: one.**

| Function | BEAM runtime cell (before 434) | wat runtime cell (before 434) | std-wasm |
|---|---|---|---|
| `hash.contentHash` | `@External.Erlang` template (djb2 over `unicode:characters_to_list`, `integer_to_list(H, 16)`, `string:lowercase`) | `@External.Wasm(fn: contentHashBody)` (the botopink body, deleted by 440: the cell is `std:hash.contentHash`) | `hash.contentHash`, export `rt_std_hash__contentHash` |

No library build carries a host function at comptime; `unicode`, `json` and std's other modules
reach comptime only as botopink bodies lowered with the module.

**Primitive methods reached** (std `primitives.bp` cells, carried as `'__bp_prim_<m>'` shims whose
clauses are the methods' `@External.Erlang` templates, the same text on both runtimes before 434):
`toString`, `join`, `at`, `push`, `filter`, `append`, `split`, `indexOf`, `map`, `startsWith`,
`trim`, `toUpper`, `slice`, `replaceAll`, `length`, `endsWith`, `contains`, `chars`, `charCodeAt`,
`floor`, `toLower`, `all`, `any`, `trimEnd`, `trimStart`, `zip`, `reverse`. Their text BIFs answer
through `text` / `number` (above); the term-level ones (`lists:*`, `maps:*`, `erlang:element/2` …)
are the term library's, `term.zig` and `otp/*.zig`.

**Limits it keeps**: none of its own since decision 443 (case mapping answers over all of
Unicode); the comptime runtime's are `compiler-core/src/comptime/runtime/AGENTS.md` § Limits.
