# std

> Path: `libs/std/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)

Botopink standard library. `src/` is **`.bp`-only**. `build.zig` embeds the files
as compile-time strings and `modules/compiler-core/src/comptime/stdlib/prelude.zig`
exposes them to the compiler.

## Tree

```text
std/
├── AGENTS.md
├── botopink.json            ← `files` lists the three core files below
├── test/                    ← compiled in test mode against the global env (no `mod` needed)
│   ├── result_test.bp       ← `@Result` method surface
│   ├── primitives_test.bp   ← tests of the `primitives.bp` interfaces (green on commonJS + erlang)
│   └── primitives_gaps_test.bp ← primitive tests that hit a compiler gap, each gap named with its owning front
└── src/
    ├── root.bp              ← module-tree root: one `pub mod <name>;` per importable std module
    │                        — core files flattened into the global type env (`std_core_files` in build.zig):
    ├── primitives.bp        ← primitive interface registry (Number/Integer/Signed/Float, I32…F64, Bool, String, Function, Pair, Array); no tests (see `test/`)
    ├── builtins.d.bp        ← builtin surface: print, @Result/@Iterator/@Future…, `Target`/`External`/`Host` annotations, std.syntax (`Expr`, `CustomNode`, …), `@Decl` reflection, effect-annotation rules
    ├── builtins_fns.d.bp    ← builtin fns with literal defaults (`todo`, `panic`)
    │                        — importable modules (declared in root.bp):
    ├── order.bp  dict.bp  sets.bp  string_builder.bp  queue.bp
    ├── math.bp  asserts.bp  path.bp  random.bp  querystring.bp  time.bp  url.bp
    ├── base64.bp  unicode.bp  process.bp  os.bp  env.bp  crypto.bp  regex.bp
    ├── erlang.bp  json.bp  fs.bp  http.bp
    └── sidecars/random.mjs  ← Mulberry32 PRNG used by `random`
```

## Importable modules

`import {<module>} from "std"`, then qualified calls (`dict.empty()`).

| Module | Surface |
|---|---|
| `order` | `enum Order`, `lt`, `eq`, `gt`, `toInt`, `reverse` |
| `dict` | `record Dict<K, V>` (association list): `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` |
| `sets` | `record Set<T>`: `empty`, `fromList`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `union`, `intersection`, `difference` (named `sets` — `set` is a keyword) |
| `string_builder` | `record StringBuilder`: `empty`, `fromString`, `fromStrings`, `append`, `prepend`, `toString`, `length`, `isEmpty` |
| `queue` | `record Queue<T>` (FIFO): `empty`, `fromList`, `size`, `isEmpty`, `enqueue`, `dequeue`, `peek`, `toList` |
| `math` | constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; trig + hyperbolic |
| `asserts` | `truthy`, `falsy`, `equal`, `notEqual`, `approxEqual`, `contains`, `throws`, `matches`, `record AssertError` (named `asserts` — `assert` is a keyword) |
| `path` | `separator`, `delimiter`, `split`, `isAbsolute`, `basename`, `dirname`, `extname`, `join`, `normalize`, `relative(src, dst)`, `resolve` (posix only) |
| `random` | `float`, `coin`, `bool`, `intInRange`, `pick`, `shuffle`, `seed`, `seededFloat` |
| `querystring` | `parse`, `stringify` |
| `time` | `nowMillis`, `monotonicMillis`, `measureMillis`, `formatIso8601` |
| `url` | `record Url`, `parse`, `serialize` |
| `base64` | `encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe` |
| `unicode` | `fromCodepoint`, `firstCodepoint`, `codepoints`, `enum NormalizationForm`, `normalize` |
| `process` | `exit`, `cwd`, `platform`, `arch`, `pid` |
| `os` | `hostname`, `arch`, `cpuCount`, `tmpdir`, `userInfo` (`record UserInfo`), `eol` |
| `env` | `read`, `write`, `clear`, `args`, `vars` (`get`/`set` are keywords) |
| `crypto` | `sha256`, `sha512`, `md5`, `hmacSha256`, `randomBytes` (hex strings) |
| `regex` | `matches`, `replace`, `replaceAll`, `splitOn`, `record Match`, `match`, `matchAll` |
| `erlang` | Erlang BIF bindings (`abs`, `element`, `spawn`, `send`, …); the erlang codegen reads this file to know which names are BIFs |
| `json` | `parse`, `stringify` (validate + canonical re-encode, `@Result<string, string>`) |
| `fs` | `record FileStat`, `readText`, `writeText`, `exists`, `list`, `mkdir`, `rm`, `copy`, `stat` (fallible ops return `@Result`) |
| `http` | `record Response`, `fetch`, `fetchStatus` (`@Future`) |

`mergeRecords(A, B)`, `partial(T)`, `omit(T, "f")` and `pick(T, ["f"])` are
comptime type functions implemented in the compiler
(`comptime/infer.zig` `tryResolveTypeManipulationCall`), not std source; a
declaration of the same name in scope wins over them (`random.pick`).
`mapFields` does not exist.

Adding an importable module:
1. Create `libs/std/src/<name>.bp`.
2. Add `pub mod <name>;` to `libs/std/src/root.bp`.

No `build.zig`, `prelude.zig`, or `compiler-core` edit — `build.zig`
(`stdPkgFilesFromRoot`) reads `root.bp` and generates the `std_pkg` registry.

Importing a std module on a target where its host-bound declarations have no
matching `@External` raises `STD-001` (`comptime/tests/std_target_gating.zig`).

## `#[@External.<Target>(...)]` — host bindings

`#[@External.<Target>(...)]` plus the signature define how a declaration lowers.
Targets come from `enum Target { Node, Typescript, Erlang, Beam, Wasm }` in
`builtins.d.bp`. Several annotations combine in one `#[…]`, comma-separated.

- **Module + symbol** — `#[@External.Erlang("erlang", "abs")]`: call
  `module:symbol(args)` with args in declaration order.
- **Single string** — `module` comes back empty from `externalFor` (`ast.zig`).
  On an interface method it names the native method (`#[@External.Node("reverse")]`,
  a call-site rename when it differs from the method name, never a prototype
  patch). On a `declare fn` it is a host expression
  (`#[@External.Node("process.cwd()")]`) that commonJS renders verbatim at each
  call site; the erlang backend still lowers the marker-less form to
  `:expr()()`, which does not compile (owned by F5 erlang), so `env`, `os` and
  `process` do not build on erlang yet.
- **Relative module file** — `#[@External.Node("./file.mjs", "symbol")]` is
  **not a supported form in `libs/std`**. On an interface method both inference
  and the commonJS emitter skip it and the native JS method of the same name
  runs; on a `declare fn` it emits `require("./file.mjs")`, which throws unless
  the file is shipped next to the emitted module. Name the native method, write
  a template, or keep host code in a sidecar (below).
- **Template** — any `$` in the string switches to the shared renderer
  (`modules/compiler-core/src/comptime/primOpTemplate.zig`):

| Marker | Resolution |
|---|---|
| `$self` | receiver expression |
| `$0` … `$N` | N-th positional argument |
| `$args` | all positional args, comma-separated |
| `$stringify(<inner>)` | text rendering of `<inner>` — Erlang `iolist_to_binary(io_lib:format("~p", [...]))`, Node `JSON.stringify(...)`; unsupported on BEAM/WAT |
| anything else | passthrough target syntax |

```bp
#[@External.Node("""(process.env[$0] ?? null)"""),
  @External.Erlang("""(fun(__N) -> case os:getenv(binary_to_list(__N)) of false -> undefined; __V -> list_to_binary(__V) end end)($0)""")]
pub declare fn read(name: string) -> ?string;
```

Triple-quoted strings (`"""…"""`) hold templates that contain `"`; one leading
and one trailing newline are stripped, and the text reaches the backend as
written. Write every template that needs a quote or a backslash triple-quoted:
a plain string keeps its escapes as raw lexemes (`"\\n"` becomes the two
characters `\\n` in the emitted code). The lexer still validates escapes inside
`"""…"""` — only `\n \r \t \\ \" \0 \$ \u{…}` are accepted, so a JS `\s` fails
the whole file with an unlocated `LexicalError`.

A template on a `declare fn` names its arguments positionally: commonJS numbers
them from `$0`, while erlang binds the first parameter of a `primitives.bp`
helper to `$self` (see `stringSlice0/1`). A template on an interface method
becomes a `<Owner>.prototype.<m>` patch on commonJS, so it must not call the
native method of the same name (the patch would call itself), and a
`default fn` body is patched the same way — `stringSlice*`/`arraySlice*`
therefore cut without `.slice`. `@External.Beam` bodies are `.S`
instructions: the receiver arrives in `{x, 0}`, argument N in `{x, N+1}`, the
result leaves in `{x, 0}`, and a `gc_bif` live count must cover every
register it reads or that is read later. Arity branching
(`when(argc == N): "<template>"`) is also parsed (`ast.parseArityBranchArg`).

Templates are rendered by the commonJS, erlang and beam_asm backends; wat does
not use them.

## Tests

Inline `test "name" { … }` blocks live in the importable module files; the
`primitives.bp` interfaces are tested from `test/`, because a core file is
flattened into the global env and never compiled in test mode. From `libs/std`:

```bash
botopink test                      # commonJS (default) or --target erlang
botopink test --filter "dict"      # by name substring
```

`botopink test` supports only the commonJS and erlang targets. Each test's
stdout is captured under a `----- RUN LOG -----` fence; failures print
`FAIL <name> (<message>) at <file>:<line>` — see
[`../../modules/compiler-cli/AGENTS.md`](../../modules/compiler-cli/AGENTS.md)
§`botopink test` output format.

Known red (the `std` cells in `scripts/known-red-libs.txt`):

| Target | What fails | Owner |
|---|---|---|
| commonJS | `test/primitives_gaps_test.bp`: `array chunked partitions`, `array sliding window of 2` — `while` inside an interface `default fn` lowers to an undefined `while_` | F8 js-bridges |
| erlang | `env`, `os`, `process` do not compile — a marker-less 1-arg `@External.Erlang` on a `declare fn` lowers to `:expr()()` | F5 erlang |
| erlang | `test/primitives_gaps_test.bp` does not compile — a method call on an `Array.range(…)` result is not lowered (`join/2`, `map/2`, `filter/2` undefined, `.length` as `maps:get`), and `chunked`/`sliding` lower `while` to `while/2` | F5 erlang |

Also known, not a red cell: `n.abs()` on an `i32` receiver resolves on
erlang only because `abs/1` is an auto-imported BIF — the erlang backend maps
an int receiver to `Integer` and walks up its `extends` chain, never down to
`Signed` — and beam leaves it `%% unresolved` (numeric receivers map to no
interface). Owned by F5 erlang and F4 beam.

## Sidecars

Host code that does not fit a one-line template lives at
`libs/std/src/sidecars/<m>.{mjs,erl}` and is required from the annotation:

```bp
#[@External.Node("""require('./sidecars/random.mjs').seed($0)"""),
  @External.Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)""")]
pub declare fn seed(s: i32) -> unit;
```

`shipMjsSidecars` (`modules/compiler-cli/src/cli/libs.zig`) copies sidecars next
to the emitted module, probing `<lib>/src/sidecars/<base>` and `<lib>/src/<base>`,
so the relative `require` resolves both in the lib's own build/test and when the
lib is a dependency. Sidecars ship verbatim.

## Effect annotations

`#[@result]`, `#[@future]`, `#[@generator]`, `#[@iterator]`,
`#[@asyncGenerator]`, `#[@context]` and default generic parameters are
documented in the effect-annotations block of `src/builtins.d.bp`.

## Conventions

- Stable, additive signatures — renames force snapshot churn.
- `.d.bp` files stay declarative (no bodies).
- No Zig in `libs/std/` — loader/glue changes belong in `build.zig` / `compiler-core`.
- `new`/`get`/`set`/`test`/`from`/`assert` are keywords — pick other names (`empty`/`lookup`/`insert`, `matches`, `src`, `asserts`).
- Array equality in assertions uses `.join(...)` (`==` on arrays is reference equality in JS).
- A trailing default on an interface method is not expanded at the call site
  yet: `s.slice(1)` fails to check (`'slice' expects 2 argument(s)`); pass both
  bounds.
- A `val` bound to a generic call is not generalised: `val f = Function.constant(42)`
  accepts one argument type only.
- Test an optional parameter with `!= null`, not truthiness: on commonJS
  `if (end)` is false for `0`.
- Pick a host call by semantics, not by name — `string:suffix/2` and
  `math:round/1` do not exist in OTP, `string:str/2` rejects binaries,
  `string:trim/1` strips both ends. Every host binding carries a test that
  asserts the value.
