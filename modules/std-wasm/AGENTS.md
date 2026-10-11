# modules/std-wasm

> Path: `modules/std-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

std's host functions implemented in Zig and compiled to wasm (decisions 434 (2), 440, 441;
front 144 B-00a, B-00e). One implementation for two consumers: the comptime runtime, on
every target (434 (5): a comptime result is std-wasm's answer whatever `--target` says), and
a `--target wasm` program, into which the codegen transpiles the functions it calls (440 (2)).
A std function is served by std-wasm only where its `#[@External.Wasm("std:<module>.<function>")]`
cell names one of `root.exports` (440 (3)) — there is no match by name.

## Tree

```text
std-wasm/
├── AGENTS.md      ← you are here
└── src/
    ├── root.zig   ← the package: `exports` (each function by its `std:` name, its botopink types), `find`, `matches`, `signatureText`, `names`, `erlang_module`; re-exports the three below
    ├── hash.zig   ← `hash.contentHash`
    ├── text.zig   ← the text algorithms behind std's string primitives (case, titlecase, trim, graphemes, slice, reverse, find, split, replace)
    ├── number.zig ← `shortFloat`: `float_to_binary(F, [short])`, std's `Float.toString` (`NaN`, `Infinity`, `-Infinity` for the values OTP has no float for)
    └── wasm.zig   ← the program face (`zig build std-wasm`): each export over a program's own strings, allocating through `env.bp_alloc`
```

## The functions (`root.exports`)

| `std:` name | Types | Bound by (std) |
|---|---|---|
| `hash.contentHash` | `(string) -> string` | `hash.contentHash` |
| `text.trim` | `(string) -> string` | `String.trim` (`primitives.bp`) |
| `text.trimStart` | `(string) -> string` | `String.trimStart` |
| `text.trimEnd` | `(string) -> string` | `String.trimEnd` |
| `number.floatToString` | `(f64) -> string` | `Float.toString` — and every float a wasm program turns into text |

A `std:` cell naming no entry, or on a declaration of other types (`matches`: the parameter
and return types as botopink spells them; a primitive behavior's `Self` is `string` on
`String`, `f64` on `Float`), is refused at the annotation on every target
(`comptime/infer.zig` `refuseStdBinding`; cells `reject/external_wasm_std_unknown`,
`reject/external_wasm_std_types`).

`String.toUpper` / `toLower` are not bound: `text.caseMap` maps ASCII and refuses any other
letter (the comptime runtime's limit 3), so it is not the function a wasm program's
`$__str_case` is.

## How it is built and served

- **Into the comptime runtime.** Root `build.zig` creates one `std_wasm` module (no target:
  each importer compiles it for its own) and gives it to the wat comptime runtime's term library
  (`compiler-core/src/comptime/runtime/wat/rt.zig`, compiled to `bp_wat_rt.wasm` for
  `wasm32-freestanding`, MVP). `rt.zig` serves it two ways:
  - each entry of `exports` is a runtime export `rt_std_<symbol>` (`rt_std_hash__contentHash`,
    the name's dot written `__`); a comptime module calls it as `bp_std_wasm:<symbol>(…)` —
    `host_cells.forRuntime` rewrites a host function whose `std:` cell names the entry to that one
    cell (`stdCell`, `servedByStdWasm`), and `runtime/wat/lower.zig`'s BIF table maps the
    `bp_std_wasm` family (`std_wasm_bifs`) to the exports. A comptime `@compileError` in `rt.zig`
    refuses an entry without its export;
  - the OTP BIFs the comptime module's primitive methods call — `string:uppercase/1`,
    `lowercase/1`, `titlecase/1` (reached by a `.beam` beam-to-wasm translates: its `erlc`
    fixture, decision 438 (2)), `trim/1,2`, `find/2`, `prefix/2`, `split/2,3`, `slice/2,3`, `reverse/1`,
    `length/1` (graphemes), `binary:replace/3,4`, `float_to_binary/2` (`[short]`), and the `~p` /
    `json:encode` float text — answer through `text` and `number`.
- **Read by compiler-core** (`core_mod`, `core_test_mod`, the browser build's `web_core_mod`):
  `host_cells.zig`, `infer.zig` and `codegen/wat/host_binding.zig` read `exports`.
- **Into a `--target wasm` program** (decision 440 (2)): `wasm.zig` is compiled to
  `std_wasm.wasm`, a position-independent side module (`zig build-lib -dynamic -fPIC`, MVP plus
  bulk memory, `dylink.0`), embedded in compiler-core as the anonymous import `std_wasm.wasm`.
  `codegen/wat/std_wasm_link.zig` decodes the functions a program calls into `wat_ast` and
  `wat.zig` emits them as ordinary functions of the program — one module, its `.wat` the whole
  program, no host change. The side module imports `env.memory`, `env.__memory_base` (the program
  places the data after its own), `env.__stack_pointer` (a program global, a stack after the
  data sized from the code's frames) and `env.bp_alloc` (the program's `$__alloc`). It holds no
  function table, no start function and no pointer in its data — which is why `shortFloat` takes
  Ryu's digits from `std.fmt.float.render` and writes the exponent by hand rather than through
  `std.Io.Writer`, whose vtable is a function table: the decoder refuses all three.
- **The export names are the cells' text** (`std:hash.contentHash`), never the bare
  `hash.contentHash`: Zig names `hash.zig`'s own `contentHash` that, so an export of that name
  resolves to itself, and the optimizer compiles the recursion to `unreachable`.
- **Built by a `Run` of `zig build-lib`**, not `addLibrary`: wasm-ld warns that a shared library
  is "not yet stable" for every side module, and the build runner fails a compile step on any
  linker stderr. The warning goes to a captured file; a failed compile still fails the step.
- **Tests**: `zig build test` runs `src/root.zig`'s tests (one per function and algorithm);
  `codegen/tests/wat.zig` decodes every export (`wat: std-wasm ---- …`).

## Measured — what a comptime evaluation reaches (144 B-00a, 2026-10-11)

Measured over `tests/language` (four targets, `--cold`), `zig build test` and `zig build test-libs`
(every library repository) on botopink-lang `239f789f`: every comptime module's Erlang text and
every host function `host_cells.forRuntime` carried were recorded (686 modules).

**Bodyless std host functions reached: one.**

| Function | BEAM runtime cell (before 434) | wat runtime cell (before 434) | std-wasm |
|---|---|---|---|
| `hash.contentHash` | `@External.Erlang` template (djb2 over `unicode:characters_to_list`, `integer_to_list(H, 16)`, `string:lowercase`) | `@External.Wasm("fn:contentHashBody")` (the botopink body, deleted by 440: the cell is `std:hash.contentHash`) | `hash.contentHash`, export `rt_std_hash__contentHash` |

No library build carries a host function at comptime; `unicode`, `json` and std's other modules
reach comptime only as botopink bodies lowered with the module.

**Primitive methods reached** (std `primitives.bp` cells, carried as `'__bp_prim_<m>'` shims whose
clauses are the methods' `@External.Erlang` templates, the same text on both runtimes before 434):
`toString`, `join`, `at`, `push`, `filter`, `append`, `split`, `indexOf`, `map`, `startsWith`,
`trim`, `toUpper`, `slice`, `replaceAll`, `length`, `endsWith`, `contains`, `chars`, `charCodeAt`,
`floor`, `toLower`, `all`, `any`, `trimEnd`, `trimStart`, `zip`, `reverse`. Their text BIFs answer
through `text` / `number` (above); the term-level ones (`lists:*`, `maps:*`, `erlang:element/2` …)
are the term library's, `rt.zig`.

**Limits it keeps** (the comptime runtime's, `compiler-core/src/comptime/runtime/AGENTS.md` §
Limits): `text.caseMap` refuses a non-ASCII letter (limit 3) rather than answer differently from a
target.
