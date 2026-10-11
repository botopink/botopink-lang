# modules/std-wasm

> Path: `modules/std-wasm/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

std's host functions implemented in Zig and compiled to wasm (decisions 434 (2), 440, 441,
442; front 144 B-00a, B-00e, B-00g). One implementation for two consumers: the comptime
runtime, on every target (434 (5): a comptime result is std-wasm's answer whatever `--target`
says), and a `--target wasm` program, into which the codegen transpiles the functions it calls
(440 (2)). A std function is served by std-wasm only where its
`#[@External.Wasm("std:<module>.<function>")]` cell names one of `root.exports` (440 (3)) —
there is no match by name. Everything a `--target wasm` program computes over values — text,
a number's text, arrays, `bigint` — is here, not in the codegen's `wat_prelude` (442 (2));
`root.program` lists the functions only the wasm codegen calls.

## Tree

```text
std-wasm/
├── AGENTS.md      ← you are here
└── src/
    ├── root.zig   ← the package: `exports` (each function by its `std:` name, its botopink types), `program` (the wasm codegen's own calls, by wasm types), `find`, `matches`, `signatureText`, `names`, `erlang_module`; re-exports the five below
    ├── hash.zig   ← `hash.contentHash`
    ├── text.zig   ← the text algorithms behind std's string primitives (case, titlecase, trim, graphemes, slice, reverse, find, split, replace; and a program's: code point length / offset / slice / `at`, `indexOf` / `lastIndexOf`, `charCodeAt`, `fromCodepoint`, `Split` / `Lines` / `Words`, pad, repeat, replace)
    ├── number.zig ← `shortFloat`: `float_to_binary(F, [short])`, std's `Float.toString` (`NaN`, `Infinity`, `-Infinity` for the values OTP has no float for); `signedText` / `unsignedText`, an integer's digits
    ├── array.zig  ← an array's algorithms over its slot words: `sliceRange`, `chunkCount`, `slidingCount`, `uniqueInto`, `search`
    ├── bigint.zig ← `bigint`'s arithmetic over `u32` limbs (add, sub, mul, divmod, compare, decimal text both ways, `toI64`, `toF64`), tested against `std.math.big.int`
    └── wasm.zig   ← the program face (`zig build std-wasm`): each export over a program's own strings, arrays and `bigint` blocks, allocating through `env.bp_alloc`
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

The types a `std:` cell can spell (`Type`): `string`, `f64`, `i32`, `i64`, `bool`, `void`,
`string[]`, `?string`. Each export has its comptime face, `rt.zig`'s `rt_std_<symbol>` (a
`string[]` a list of binaries, a `bool` its atom, a `?string` the binary or `undefined`).

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
A `std:` cell naming no entry, or on a declaration of other types (`matches`: the parameter
and return types as botopink spells them; a primitive behavior's `Self` is `string` on
`String`, `f64` on `Float`), is refused at the annotation on every target
(`comptime/infer.zig` `refuseStdBinding`; cells `reject/external_wasm_std_unknown`,
`reject/external_wasm_std_types`).

`String.toUpper` / `toLower` are not bound: `text.caseMap` maps ASCII and refuses any other
letter (the comptime runtime's limit 3), so it is not the function a wasm program's
`$__str_case` is.

The seeded random (`io/random`'s `seed` / `seededFloat`, `wasi:seed_u32` / `wasi:seeded_f64`)
is still the prelude's: its draw before any seed is the host's (`$__wasi_random_f64`), and
what the comptime answers for a `std:` cell over it is open (144 B-00g's report).

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
  A Zig `var` (the integer workspace) is `.bss`: wasm-ld gives the side module a start
  function that only zeroes it, which the decoder drops (a fresh instance's memory is zero);
  any other start is refused.
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
