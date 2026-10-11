# modules/std-wasm

> Path: `modules/std-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

std's host functions implemented in Zig and compiled to wasm (decision 434 (2), front 144
B-00a). A std function reached at comptime answers std-wasm's text, whatever the build's
target (434 (5)), and needs no per-binding `@External.Wasm` cell to run there.

## Tree

```text
std-wasm/
├── AGENTS.md      ← you are here
└── src/
    ├── root.zig   ← the package: `functions` (the std functions served whole), `find`, `erlang_module`; re-exports the three below
    ├── hash.zig   ← `hash.contentHash`
    ├── text.zig   ← the text algorithms behind std's string primitives (case, trim, graphemes, slice, reverse, find, split, replace)
    ├── number.zig ← `shortFloat`: `float_to_binary(F, [short])`, std's `Float.toString`
    └── wasm.zig   ← the package alone as a wasm module (`zig build std-wasm`): C-ABI exports over linear memory
```

## How it is built and served

- **Into the comptime runtime.** Root `build.zig` creates one `std_wasm` module (no target: each
  importer compiles it for its own) and gives it to the wat comptime runtime's term library
  (`compiler-core/src/comptime/runtime/wat/rt.zig`, compiled to `bp_wat_rt.wasm` for
  `wasm32-freestanding`, MVP): the `.wasm` the comptime runtime links every lowered comptime module
  into carries std-wasm. `rt.zig` serves it two ways:
  - each entry of `functions` is an export `rt_std_<symbol>` (`rt_std_hash__contentHash`); a
    comptime module calls it as `bp_std_wasm:<symbol>(…)` — `host_cells.forRuntime` rewrites a
    std host function std-wasm serves to that one cell (`servedByStdWasm`), and
    `runtime/wat/lower.zig`'s BIF table maps the `bp_std_wasm` family (`std_wasm_bifs`) to the
    exports. A comptime `@compileError` in `rt.zig` refuses an entry without its export;
  - the OTP BIFs the comptime module's primitive methods call — `string:uppercase/1`,
    `lowercase/1`, `trim/1,2`, `find/2`, `prefix/2`, `split/2,3`, `slice/2,3`, `reverse/1`,
    `length/1` (graphemes), `binary:replace/3,4`, `float_to_binary/2` (`[short]`), and the `~p` / `json:encode` float text — answer through
    `text` and `number`.
- **Read by compiler-core** (`core_mod`, `core_test_mod`, the browser build's `web_core_mod`):
  `host_cells.zig` reads `functions` to know what std-wasm serves.
- **Alone**: `zig build std-wasm` → `zig-out/lib/std_wasm.wasm` (`wasm.zig`): `std_alloc`,
  `std_reset`, `std_hash_contentHash`, `std_text_caseMap`, `std_text_trim`,
  `std_number_floatToString` — a text argument `(ptr, len)`, a text answer packed
  `ptr << 32 | len` in a `u64` (all ones when refused). The face a `--target wasm` program links
  (144 B-00e).
- **Tests**: `zig build test` runs `src/root.zig`'s tests (one per function and algorithm).

## Measured — what a comptime evaluation reaches (144 B-00a, 2026-10-11)

Measured over `tests/language` (four targets, `--cold`), `zig build test` and `zig build test-libs`
(every library repository) on botopink-lang `239f789f`: every comptime module's Erlang text and
every host function `host_cells.forRuntime` carried were recorded (686 modules).

**Bodyless std host functions reached: one.**

| Function | BEAM runtime cell (before 434) | wat runtime cell (before 434) | std-wasm |
|---|---|---|---|
| `hash.contentHash` | `@External.Erlang` template (djb2 over `unicode:characters_to_list`, `integer_to_list(H, 16)`, `string:lowercase`) | `@External.Wasm("fn:contentHashBody")` (the botopink body) | `hash.contentHash`, export `rt_std_hash__contentHash` |

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
