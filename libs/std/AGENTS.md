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
    ├── primitives.bp        ← primitive behavior registry (Number/Integer/Signed/Float, I32…F64, Bool, String, Function, Pair, Array); no tests (see `test/`)
    ├── builtins.d.bp        ← builtin surface: print, @Result/@Iterator/@Future/@FutureGenerator…, `Display` (decision 8 §7), `Index`/`Slice` (decision 63, amended), `Target`/`External`/`Host` annotations, std.syntax (`Expr`, `ExprContext`, `CustomNode`, …), `@Decl` reflection, effect-annotation rules
    ├── builtins_fns.d.bp    ← builtin fns with literal defaults (`todo`, `panic`)
    │                        — importable modules (declared in root.bp):
    ├── order.bp  dict.bp  sets.bp  string_builder.bp  queue.bp
    ├── math.bp  asserts.bp  path.bp  random.bp  querystring.bp  time.bp  url.bp
    ├── base64.bp  unicode.bp  process.bp  os.bp  env.bp  crypto.bp  regex.bp
    ├── erlang.bp  json.bp  fs.bp  http.bp  snapshots.bp  mocks.bp
    ├── content_hash.bp      ← the content-hash half of the future `hash.bp` (1.0.10-beta `01-std` front 03); front 23 folds it into `hash.bp` with `crypto.bp`
    ├── __snapshots__/<suite>/<slug>.snap  ← recorded by `snapshots` from the inline tests (decision 72); a `.snap.new` beside one is a candidate a person reviews and renames
    └── sidecars/random.mjs  ← Mulberry32 PRNG used by `random` (the only sidecar: `mocks` keeps its tables on `globalThis`, not in a `.mjs`)
```

## Importable modules

`import {<module>} from "std"`, then qualified calls (`dict.empty()`).

| Module | Surface |
|---|---|
| `order` | `type Order`, `lt`, `eq`, `gt`, `toInt`, `reverse` |
| `dict` | `type Dict<K, V>` (association list, `implement Index<K, V>`): `empty`, `at`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` |
| `sets` | `type Set<T>`: `empty`, `fromList`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `union`, `intersection`, `difference` (named `sets` — `set` is a keyword) |
| `string_builder` | `type StringBuilder`: `empty`, `fromString`, `fromStrings`, `append`, `prepend`, `toString`, `length`, `isEmpty` |
| `queue` | `type Queue<T>` (FIFO): `empty`, `fromList`, `size`, `isEmpty`, `enqueue`, `dequeue`, `peek`, `toList` |
| `math` | constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; trig + hyperbolic |
| `asserts` | The canonical assertion API (1.0.10-beta front 01-std, `asserts-api.md`): every fn is `#[@result] -> @Result<void, string>`, consumed with `try`, `actual` first, one literal message `asserts.<fn>: <what>` each — `isTrue`, `isFalse`, `equals`, `notEquals`, `approxEquals`, `deepEquals`, `isNil`, `isNotNil`, `isOk`, `isError`, `contains`, `notContains`, `startsWith`, `endsWith`, `matches(actual, pattern)`, `isEmpty`, `isNotEmpty`, `lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`, `throws(body)`, `throwsWith(body, needle)`, `fail(message)`, plus `errorText(r) -> string` (the `Error` payload, `""` for `Ok`). No `pub declare fn` (STD-001-clean on every target); `matches`/`deepEquals`/`throws`/`throwsWith` sit on the private cells `regexMatches`/`canonical`/`tryCatch` (Node + Erlang). The old panicking `truthy`/`falsy`/`equal`/`notEqual`/`approxEqual`/`AssertError` are gone. Named `asserts` — `assert` is a keyword |
| `snapshots` | The snapshot engine (1.0.10-beta front 01-std, `snapshots.md`; decisions 72, 67): `path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap` (suite = text before the first `": "` of `loc.fnName`, slug = the compiler's `slugify` rule ported byte-for-byte in `slugOf`), `pathNamed(loc, name)`, `suiteOf`, `slugOf` — pure, every backend; `assertText(loc, actual)` (the spec's `assert` — a keyword, so renamed), `assertAs(loc, subject, actual)`, `assertNamed(loc, name, actual)`, `assertNamedAs(loc, name, subject, actual)` — `#[@result]`, `-> @Result<void, string>`; the `.snap` is `botopink-snap 1` / `test: <name>` / `subject: <subject>` / blank / body; missing or mismatch writes `<path>.new` and answers `Error`, a match deletes a stale `.new`; **no update flag of any kind** — a person renames the `.new`. Private cells `readFile`/`writeFile`/`removeFile`/`removeTree`/`exists`/`tmpDir` (Node + Erlang; STD-001-clean) — every inline engine test makes a `tmpDir()` scratch and removes it again with `removeTree`, so a run leaves nothing under the host's tmpdir. `loc` must be the CALLER's `@src()` |
| `mocks` | Mockito-style mocks over a `behavior` (1.0.10-beta front 01-std, `onze-migration.md`; decision 71) — 100 % of the retired `onze` library, Erlang templates carried over, Node templates inlining what `onze.mjs` held. Eight `pub declare fn` cells (`newMock`, `key`, `pushMatcher`, `invoke`, `beginVerify`, `whenCall`, `thenReturnCell`, `thenThrowCell`), the matchers `eq`/`anyInt`/`anyString` (matchers, **not** assertions — they push a descriptor and answer a dummy), the verify specs `atLeastOnce`/`times`/`never`, `pub type Stub` with `thenReturn`/`thenThrow`, `when(value)`, `verify(mock, spec)` and the `#[mock]` decorator. Mutable state is one cell per host process: `globalThis.__bp_mocks` on Node (the `emilia.bp:24` shape), the `'__bp_mocks_*'` process-dictionary keys on Erlang — **no `.mjs` sidecar**. The only std module with `pub declare fn`, so STD-001 refuses `import {mocks} from "std"` on beam and wasm (the cells have to be exported: `#[mock]`'s emitted body calls them). `#[mock]` fires in THIS module only — see *Tests* below |
| `path` | `separator`, `delimiter`, `split`, `isAbsolute`, `basename`, `dirname`, `extname`, `join`, `normalize`, `relative(src, dst)`, `resolve` (posix only) |
| `random` | `float`, `coin`, `bool`, `intInRange`, `pick`, `shuffle`, `seed`, `seededFloat` |
| `querystring` | `parse`, `stringify` |
| `time` | `nowMillis`, `monotonicMillis`, `measureMillis`, `formatIso8601` |
| `url` | `type Url`, `parse`, `serialize` |
| `base64` | `encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe` |
| `unicode` | `fromCodepoint`, `firstCodepoint`, `codepoints`, `type NormalizationForm`, `normalize` |
| `process` | `exit`, `cwd`, `platform`, `arch`, `pid` |
| `os` | `hostname`, `arch`, `cpuCount`, `tmpdir`, `userInfo` (`type UserInfo`), `eol` |
| `env` | `read`, `write`, `clear`, `args`, `vars` (`get`/`set` are keywords) |
| `crypto` | `sha256`, `sha512`, `md5`, `hmacSha256`, `randomBytes` (hex strings) |
| `content_hash` | The content-hash half of `hash.bp` (1.0.10-beta `01-std` front 03, decision 106; lands flat, `00 · 23-std-purity` folds it into `hash.bp`): `contentHash` (djb2 as lowercase hex, the `emilia.hashHex` templates verbatim — fast, trivially collidable, for filenames and internal keys) and `strongHash` (SHA-256 truncated to 32 hex, for input the caller did not choose). Both are `declare fn` with a Node and an Erlang cell — no bitwise operators or `toString(radix)` in the language, so the fold lives in the template and neither runs on beam or wasm. Every expected hex in the inline tests is a literal, which is what pins the two targets to each other. `emilia.hashHex` is a duplicate now; collapsing it is a later, `emilia`-owned change |
| `regex` | `matches`, `replace`, `replaceAll`, `splitOn`, `type Match`, `match`, `matchAll` |
| `erlang` | Erlang BIF bindings (`abs`, `element`, `spawn`, `send`, …); the erlang codegen reads this file to know which names are BIFs |
| `json` | `parse`, `stringify` (validate + canonical re-encode, `@Result<string, string>`) |
| `fs` | `type FileStat`, `readText`, `writeText`, `exists`, `list`, `mkdir`, `rm`, `copy`, `stat` (fallible ops return `@Result`) |
| `http` | `type Response`, `fetch`, `fetchStatus` (`@Future`) |

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
Targets come from `type Target { Node, Typescript, Erlang, Beam, Wasm }` in
`builtins.d.bp`. Several annotations combine in one `#[…]`, comma-separated.

- **Module + symbol** — `#[@External.Erlang("erlang", "abs")]`: call
  `module:symbol(args)` with args in declaration order.
- **Single string** — `module` comes back empty from `externalFor` (`ast.zig`).
  On a behavior method it names the native method (`#[@External.Node("toReversed")]`
  for `Array.reverse`, a call-site rename when it differs from the method name,
  never a prototype patch). The native method it names has to MATCH the
  signature: `Array.reverse` answers a reversed array and leaves the receiver
  alone on erlang and wasm, and named native `reverse`, which reverses in
  place, so commonJS alone also reversed the receiver — `toReversed` is the
  copying reader that answers what the signature says. On a `declare fn` it is a host expression
  (`#[@External.Node("process.cwd()")]`) that commonJS renders verbatim at each
  call site, and the erlang backend renders the same way — the `:expr()()`
  lowering that used to keep `env`, `os` and `process` off erlang is gone
  (`botopink test --target erlang` in `libs/std`: `process.pid is positive`,
  `os.hostname is non-empty` and `env.write + env.read round-trips a value` all
  pass).
- **Relative module file** — `#[@External.Node("./file.mjs", "symbol")]` is
  **not a supported form in `libs/std`**. On a behavior method both inference
  and the commonJS emitter skip it and the native JS method of the same name
  runs; on a `declare fn` it emits `require("./file.mjs")`, which throws unless
  the file is shipped next to the emitted module. Name the native method, write
  a template, or keep host code in a sidecar (below).
- **Template** — any `$` in the string switches to the shared renderer
  (`modules/compiler-core/src/comptime/primOpTemplate.zig`):

| Marker | Resolution |
|---|---|
| `$0` … `$N` | the N-th **declared parameter** — on a method `$0` is `self` (decision 5) |
| `$args` | every declared parameter, comma-separated (the receiver first on a method) |
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

Markers are positional over the declared parameters on every target (decision 5):
`$self` is refused and so is a `$N` past the last parameter, both with a location
(`template-self-marker`, `template-marker-out-of-range`). The parser maps the
source form to the renderers' receiver convention (`parser/template_markers.zig`),
so a helper whose first parameter is `self` (`stringSlice0/1`) reads the same on
erlang and commonJS. A template on a behavior method
becomes a `<Owner>.prototype.<m>` patch on commonJS, so it must not call the
native method of the same name (the patch would call itself), and a
`default fn` body is patched the same way — `stringSlice*`/`arraySlice*`
therefore cut without `.slice`. **That rule is now gated**, because it was
written here and broken anyway: `String.charCodeAt` read
`(($0.charCodeAt($1) ?? -1) | 0)`, and since the `String` prelude is installed
into any module using a member that needs a patch (one `s.slice(…)` is enough),
every `.charCodeAt(…)` in the program blew the stack — a library adopted "never
call `String.slice`" as a house rule rather than find it. `js: external ---- no
prelude template calls the method it patches`
(`codegen/tests/externals.zig`) walks the embedded prelude and fails on the
shape. `charCodeAt` names native `codePointAt`, which no behavior member
patches, and which is also what the `?? -1` was written for: out of range it
answers `undefined` where `charCodeAt` answers `NaN`, which `??` does not catch
and `| 0` turned into `0` — commonJS answered `0` where erlang answered `-1`. `@External.Beam` bodies are `.S`
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

`snapshots`' own path-rule tests record ordinary snapshots under
`src/__snapshots__/snapshots/` (four files, committed); its engine tests run
against a scratch directory under the host tmpdir. A red snapshot run leaves a
`*.snap.new` beside the `.snap` (git-ignored); review it, then `mv` it over the
`.snap` to record — there is no flag that does it for you (decision 67).

`mocks`' nine inline tests are the eight of the retired `repository/onze/test/onze_test.bp`
plus one for `anyString` (the old suite covered it from its example app, not its
test file). They run on both targets — `botopink test [--target erlang] --filter
mocks` reads `9 passed, 0 failed`.

**`#[mock]` fires only inside `mocks.bp`.** `@emit` splices its text into the
module that hosts the annotated `behavior`, and the emitted method bodies name
the runtime bare (`invoke`, `key`, `newMock`). That resolves here and nowhere
else: `import {mocks} from "std"` binds the module handle, never its functions
(a bare `import {mock, …} from "std"` is `unknown "std" module in import`), and
`#[mocks.mock]` is not registered as a decorator at all — a qualified
annotation name never reaches `env.decorators`, so the marker silently does
nothing and `mockUserRepo` comes out unbound. A consumer therefore writes the
double by hand over the qualified runtime, which works in full
(`mocks.invoke`/`mocks.key`/`mocks.newMock`/`mocks.when(…).thenReturn`/
`mocks.verify`, all measured 2026-09-21 from a scratch package on commonJS).
Closing the gap needs two changes, both recorded in
`specs/1.0.10-beta/01-std/onze-migration.md` § *Language gaps*: registering a
std module's `@Decl`-shaped `pub fn`s in `env.decorators` under `<mod>.<fn>`
(`comptime/infer.zig` `markStdImports`), and an emission that resolves in both
places — `#[mock]` cannot emit one text that is bare here and qualified there.

**No known red cell.** `scripts/known-red-libs.txt` carries no line, and
`zig build test-libs` reads `std · commonJS: pass` and `std · erlang: pass`
(11 passed, 0 failed, 0 known red across the workspace). The three rows this
section used to carry were re-measured with
`botopink test [--target erlang]` in `libs/std` and all three are green:
`test/primitives_gaps_test.bp` is **13 passed, 0 failed on both targets**
(`array chunked partitions` and `array sliding window of 2` included, and every
method call on an `Array.range(…)` result), and `env`, `os` and `process`
compile and pass on erlang.

Also known, not a red cell: `n.abs()` on an `i32` receiver resolves on
erlang only because `abs/1` is an auto-imported BIF — the erlang backend maps
an int receiver to `Integer` and walks up its `extends` chain, never down to
`Signed` — and beam leaves it `%% unresolved` (numeric receivers map to no
behavior). The erlang half is what `botopink test` exercises; the beam half is
not re-measured here, because `botopink test` does not run beam. Owned by
1.0.5-beta `02-erlang` and `03-beam`.

## Sidecars

Host code that does not fit a one-line template lives at
`libs/std/src/sidecars/<m>.{mjs,erl}` and is required from the annotation:

```bp
#[@External.Node("""require('./sidecars/random.mjs').seed($0)"""),
  @External.Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)""")]
pub declare fn seed(s: i32) -> unit;
```

A host runtime that needs mutable state does **not** get a sidecar for it:
`mocks` keeps its six tables in one lazily created `globalThis.__bp_mocks` cell
inside each Node template (the shape `emilia.bp:24` uses) and in the
`'__bp_mocks_*'` process-dictionary keys inside each Erlang template, so
`sidecars/` holds exactly one file.

`shipMjsSidecars` (`modules/compiler-cli/src/cli/libs.zig`) copies sidecars next
to the emitted module, probing `<lib>/src/sidecars/<base>` and `<lib>/src/<base>`,
so the relative `require` resolves both in the lib's own build/test and when the
lib is a dependency. Sidecars ship verbatim.

## Effect annotations

`#[@result]`, `#[@future]`, `#[@generator]`, `#[@iterator]`,
`#[@futureGenerator]`, `#[@context]` and default generic parameters are
documented in the effect-annotations block of `src/builtins.d.bp`.

## Conventions

- Stable, additive signatures — renames force snapshot churn.
- `.d.bp` files stay declarative (no bodies).
- **Every `.bp` here is at the formatter's canonical form, and `format --check`
  does not cover all of it.** The default scan is `src/**`, excluding `.d.bp`, so
  `test/` and `builtins_fns.d.bp` have to be named explicitly:
  `botopink format --check src/builtins_fns.d.bp test/*.bp`. `builtins.d.bp`
  cannot be formatted at all — `fn await(self: Self)` in the `Future` behavior
  is a parse error (`await` is a keyword), which is a parser row, not a
  formatter one. Front 20 removed the file's other unparseable form: the five
  intrinsics at the foot (`field` / `trap` / `emit` / `module` / `getContex`)
  are `pub declare fn … -> …;` now, like every other bodyless fn here.
- No Zig in `libs/std/` — loader/glue changes belong in `build.zig` / `compiler-core`.
- `get`/`set`/`test`/`from`/`assert` are keywords (`new`, `delegate` and `const` are identifiers since 06 N27) — pick other names (`empty`/`at`/`insert`, `matches`, `src`, `asserts`).
- Array equality in assertions uses `.join(...)` (`==` on arrays is reference equality in JS) — or `asserts.deepEquals`, which renders both sides on the same host.
- An `if (a < b || c > d)` condition does not parse today (the condition grammar stops at `||`); bind it to a `val` first (`asserts.between` does). A parser gap, not a std one.
- **Measured 2026-09-20, consumer side** (`import {asserts, snapshots} from "std"` from a user package under `botopink test`): a primitive interface `default fn` (`Bool.negate`, `Array.contains`, `Array.isEmpty`, …) is emitted verbatim (`condition.negate is not a function`) when a std module is compiled as a consumer's **embedded** import — the project compile of `libs/std` itself lowers it. `asserts`/`snapshots` therefore use only host-backed primitives (`== false`, `indexOf`, `.length`, `split`/`join`/`slice`/`indexOf`/`startsWith`/`endsWith`/`contains` on strings). A std module written with a default fn passes its own tests and breaks its consumers. Core gap (commonJS cross-module emission of embedded std modules).
- **Measured 2026-09-20, erlang consumer side**: any `from "std"` import from a user package under `botopink test --target erlang` is `{error,undef}` — `test_cmd.zig` writes the module as `std/<name>.erl` while its atom is `std@<name>`, and `erlc` refuses the mismatch (`Module name 'std@math' does not match file name 'math'`), so `__bp_load_siblings` never loads it. Pre-existing (`math` fails the same way); `botopink run` is not affected. Toolchain gap, owned by the CLI.
- A trailing default on a behavior method **is** expanded at the call site since
  1.0.10-beta's C-04: `s.slice(1)` is the open-ended slice, because `slice`'s
  `end` is `?i32 = null` and the declared default is what the method receives.
  Measured 2026-09-21: `"hello".slice(2)` answers `llo` on commonJS, erlang and
  beam. `s.slice(2, null)` still means the same thing, and is what an index
  expression `s[1..]` rewrites to (decision 63, amended).
- **An open end is a backend defect on wasm, and on beam for arrays** — and it is
  not the default's: written out with no default involved, `s.slice(2, null)`
  traps on wasm (`__str_slice`, out of bounds memory access) byte for byte as
  `s.slice(2)` does, and `xs.slice(2, null)` on an ARRAY answers `0` on wasm and
  `badarith` on beam where commonJS and erlang answer. Unowned; it is
  `String.slice` / `Array.slice`'s lowering of a `null` bound. The wasm trap is
  what `snapshots/codegen/wasm/string_slice_without_end_arg_slices_to_source_length.snap.md`
  records since C-04 — the snapshot used to pin the arity error, which hid it.
- A `val` bound to a generic call is not generalised: `val f = Function.constant(42)`
  accepts one argument type only.
- Test an optional parameter with `!= null`, not truthiness: on commonJS
  `if (end)` is false for `0`.
- Pick a host call by semantics, not by name — `string:suffix/2` and
  `math:round/1` do not exist in OTP, `string:str/2` rejects binaries,
  `string:trim/1` strips both ends. Every host binding carries a test that
  asserts the value.

## `behavior Index` / `behavior Slice` (decision 63, amended)

`builtins.d.bp` declares both, ambient like `Display` and for the same reason: an index expression
has **no typing rule of its own** — `xs[0]` IS `xs.at(0)`, `d["k"]` IS `d.at("k")`, `xs[0..2]` IS
`xs.slice(0, 2)` and `xs[1..]` IS `xs.slice(1, null)` — so the syntax has to find the method without
the author having imported anything. `slice` takes two arguments rather than a range because there
is no `Range` type: `start..end` is an AST node, not a value.

`libs/std` answers them three times, in two different spellings, and the difference is a grammar
limit rather than a choice:

| type | behaviors | how it is written |
|---|---|---|
| `Dict<K, V>` (`dict.bp`) | `Index<K, V>` | `pub type Dict<K, V>(…) implement Index<K, V>` — the real clause; `lookup` was renamed `at` |
| `Array<T>` (`primitives.bp`) | `Index<i32, T>`, `Slice<T[]>` | a comment naming the conformance |
| `string` (`primitives.bp`) | `Index<i32, string>`, `Slice<string>` | a comment; `charAt` was renamed `at` |

**Why the last two are comments.** `Array` and `string` are `behavior` declarations — the primitive
registry — and `parseBehaviorDecl` reads only an `extends` clause, whose members are bare
identifiers (`parser/decls.zig:593`), so neither `behavior Array<T> implement Index<i32, T>` nor
`extends Index<i32, T>` parses. The separate block form does parse for a builtin target
(`ArrayIndex implement Index<i32, T> for Array { … }`) but it is not a conformance *declaration*: it
requires the methods **in its own body** (`comptime/infer.zig:463-486`) and does not consult the
target's existing members, so `for string { }` reds with *'string' does not implement 'at'* even
though `String.at` is declared two hundred lines above. A type's inline clause is not checked against
an ambient behavior either (`validateInlineImplements` skips an interface the program does not
declare), so `Dict`'s clause is documentation the compiler does not yet verify — the same blind spot
decision 58's note already records.

## `behavior Display` (decision 8 §7, decision 27)

`builtins.d.bp` declares it, so a type writes `implement Display` with **no import** — `@print` has
to find a value's `display()` without the author having asked for it, which is the same reason every
other builtin behavior is ambient rather than a `pub mod`. One declaration, read by the §7 step of
all four backend fronts.

**`Dict<K, V>` does not implement it yet, and the reason is measured, not forgotten.** §7's own
example is `Dict("a": 1, "b": 2)` — a string key quoted, any other key bare. `K` is generic, so
nothing static decides which, and the test has to be `p._0 is string` at run time (decision 8 §4).
Written that way, `zig build test-libs` gives `std · commonJS: pass` and `std · erlang: FAIL`
(`escript: There were compilation errors.`): `x is T` has a run-time lowering on commonJS only.
The implementation lands with `is` on erlang, beam and wasm — `02-erlang`, `03-beam` and `05-wasm`
step 2 — not before, because a `libs/std` that only compiles on one backend is worse than a `Dict`
that prints its `pairs`.
