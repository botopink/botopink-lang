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
├── botopink.json
└── src/
    ├── root.bp              ← module-tree root: one `pub mod <name>;` per importable std module
    │                        — core files flattened into the global type env (`std_core_files` in build.zig):
    ├── primitives.bp        ← primitive interface registry (Number/Integer/Signed/Float, I32…F64, Bool, String, Function, Pair, Array) + inline tests
    ├── builtins.d.bp        ← builtin surface: print, @Result/@Iterator/@Future…, `Target`/`External`/`Host` annotations, std.syntax (`Expr`, `CustomNode`, …), `@Decl` reflection, effect-annotation rules
    ├── builtins_fns.d.bp    ← builtin fns with literal defaults (`todo`, `panic`)
    │                        — importable modules (declared in root.bp):
    ├── order.bp  dict.bp  sets.bp  string_builder.bp  queue.bp
    ├── math.bp  asserts.bp  path.bp  random.bp  querystring.bp  time.bp  url.bp
    ├── base64.bp  unicode.bp  process.bp  os.bp  env.bp  crypto.bp  regex.bp
    ├── erlang.bp  json.bp  fs.bp  http.bp
    │                        — not declared in root.bp, not referenced by build.zig:
    ├── reflect.bp           ← `mergeRecords`
    ├── types.bp             ← `mapFields`, `partial`, `omit`, `pick`
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
- **Single string** — `#[@External.Node("reverse")]`, `#[@External.Node("process.cwd()")]`:
  `module` comes back empty from `externalFor` (`ast.zig`) and the backend emits
  the string as a native call/expression.
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
and one trailing newline are stripped. Arity branching
(`when(argc == N): "<template>"`) is also parsed (`ast.parseArityBranchArg`).

Templates are rendered by the commonJS, erlang and beam_asm backends; wat does
not use them.

## Tests

Inline `test "name" { … }` blocks live in the module files. From `libs/std`:

```bash
botopink test                      # commonJS (default) or --target erlang
botopink test --filter "dict"      # by name substring
```

`botopink test` supports only the commonJS and erlang targets. Each test's
stdout is captured under a `----- RUN LOG -----` fence; failures print
`FAIL <name> (<message>) at <file>:<line>` — see
[`../../modules/compiler-cli/AGENTS.md`](../../modules/compiler-cli/AGENTS.md)
§`botopink test` output format.

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
- Erlang codegen gotchas for pure-bp modules:
  - `+` on strings lowers to numeric `+` (`badarith`); concatenate with `[a, b].join("")`.
  - `var out = []; xs.forEach({ x -> out.push(x) })` discards the push (Erlang never rebinds `Out`); use `filter`/`map` or head/tail recursion.
