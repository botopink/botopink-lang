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
├── botopink.json            ← `files` lists the two core files below (`primitives.bp`, `external.bp`)
├── test/                    ← compiled in test mode against the global env (no `mod` needed)
│   ├── result_test.bp       ← `@Result` method surface
│   ├── primitives_test.bp   ← tests of the `primitives.bp` interfaces, `String.parseInt` / `parseFloat`, the integer methods past 2^53 and the conversions included (green on commonJS + erlang)
│   ├── primitives_gaps_test.bp ← primitive tests that hit a compiler gap, each gap named with its owning front
│   └── unicode_test.bp      ← `unicode.normalize` against `tools/unicode-gen/NormalizationTest.txt`, every line of its six parts (§ unicode)
├── tools/unicode-gen/       ← the generator of `src/unicode_tables.bp` and of std-wasm's `case_tables.zig` (Zig, run by `zig build gen-unicode` — not part of the package) and the vendored Unicode data it reads (§ unicode)
└── src/
    ├── root.bp              ← module-tree root: twenty-four `pub mod` lines — the twenty-two root modules, `pub mod io;`, `pub mod testing;` (decision 106)
    │                        — core files flattened into the global type env (`std_core_files` in build.zig):
    ├── primitives.bp        ← primitive behavior registry (Number/Integer/Signed/Float, I32…F64, Bool, String, Function, Pair, Array); no tests (see `test/`). `Array.lastIndexOf` is a `default fn` over `reverse` + `indexOf` (beam's path) with an erlang and a node cell; wasm lowers it to std-wasm's `array.lastIndexOf*` (decision 442 (2)); every other `String` member but `toUpper` / `toLower` carries a `#[@external(.Wasm(std: "text.…"))]` cell naming the std-wasm function the wasm codegen calls (144 B-00g). Its slice helpers are free `declare fn`s (`stringSlice0(s, start)` — no `self`: `self-param-outside-type`), and their Node templates read a missing start as 0, because commonJS's `slice` patch is global. A trailing section `// ── the wasm bodies (front 164 s3)` holds the private `text<Name>OnWasm` bodies of `split`, `chars`, `lines`, `words`, `contains`, `startsWith`, `endsWith`, `indexOf`, `lastIndexOf`, `at`, `padStart`, `padEnd`, `repeat`, `replace`, `replaceAll`, `trim`, `trimStart`, `trimEnd` over the leaves `stringByteLength` / `stringByteAt` / `stringByteSlice` (`std: "text.byteLength"` …); each answers std-wasm's `text.zig` (decisions 441, 565). A private bodied `fn` here is the prelude's own: `registerStdlib` infers it with the prelude (`true` / `false` bound first) and then takes it out of the global environment (`hidePreludeBodies`), so no program calls or collides with it; the wasm codegen adopts it when a `String` method's `#[@external(.Wasm(body: …))]` cell names it. Nothing binds them until a `fn:` cell replaces a method's `std:` cell (s3 P1-d, decision 566). `String.parseInt()` / `String.parseFloat()` (1.0.11-beta front 97) are `default fn`s over four free cells — see *String numerals* below
    ├── external.bp          ← decision 575 (6): `WasmNeed`, `WasmHost`, `WasiAdapter`, the enum `Implementation` (`Erlang(template, body, inline, result)`, `JavaScript(template, body, result)`, `Wasm(template, op, std, wasi, body, host, needs, result)`) and `external(syntax decl: unknown, comptime ..sources: Implementation[])`, the annotation a bodyless `declare fn` names its sources with — `#[external(…)]` inside std, `#[@external(…)]` outside; a core file registered into every environment before the prelude (`comptime.zig` `registerExternalPrelude`), its variants reached through their type only; the parser reads its sources (`parser/implementations.zig`) until `#[builtin]` (B-139) marks it
    │   └ its last section   ← `// ── the compiler's declarations` (B-139: no `.d.bp`; read apart by `prelude.zig` — `primitives` the part the checker infers, `builtins` this section, which the compiler reads itself; std's own build does not analyse the `primitives` module a second time, `comptime.zig` `withPreludeModuleEmpty`): builtin surface: every `@name` builtin fn declared (decision 252 — `comptime/builtins.zig`'s table is held to it by a unit test, and a call to it is checked against it), @Result/@Task/@Component/@Iterator/@Stream (`YieldStep`)…, `Display` (decision 8 §7), `Closeable` (decision 539 (6), ambient), `Index`/`Slice` (decision 63, amended), `Target`, the checker's internal tree and declaration-handle forms (`__Expr`, `__ExprContext`, `__CustomNode`, `__Decl`, …) — what `compiler.bp`'s members read and answer —, `TypeInfo<T>` with its static `all` and `RecordField`, effect-wrapper rules
    │                        — the PURE root: same input, same output; imports nothing from `io/` (`std-root-imports-io`)
    ├── collections.bp       ← `Dict`, `Set`, `Queue`, `Order` (was `dict`, `sets`, `queue`, `order`)
    ├── decimal.bp           ← `Decimal` and `Rounding` (decision 332 (2)): Java's `BigDecimal` in pure botopink over `bigint`
    ├── math.bp  path.bp  url.bp  querystring.bp  json.bp  regex.bp  unicode.bp  string_builder.bp
    ├── unicode_tables.bp    ← GENERATED (`zig build gen-unicode`), never edited: `unicode`'s normalization data; a private `mod` of `root.bp` (§ unicode)
    ├── encoding.bp          ← base64 (was `base64`), hex, percent, the form codec
    ├── hash.bp              ← hex digests (was `crypto`), the base64url/HMAC digests, content hashes (was `content_hash`)
    ├── escape.bp  async.bp
    ├── failure.bp           ← `HostErrorName`, `HostError(message, kind, name, detail)`, `Failure(message, kind)` and `attempt` / `attemptTask` (decisions 431, 489, 492, 494)
    ├── bpp.bp               ← the `.bpp` role annotations (decision 361): `html`, `style`, `htmlPrelude`, `stylePrelude` — decorators in 302's shape — and `type Prelude()`, the marker's value
    ├── compiler.bp          ← `Compiler` (decisions 575 (3), 576, 578): the behavior whose members `compiler` answers — the module's default, `#[builtin] pub default declare val compiler: Compiler;` (decision 579), bound by `import {compiler} from "std"` (`import {compiler};` in std) —, held member for member, each parameter's arrival included (decision 616: `syntax` for a tree, `comptime` for a build value), to the compiler's table (`parser/compiler_surface.zig` `members`, test `comptime/tests/compiler_members.zig`), and decision 576 (13)'s aliases of the types a body is handed (`pub type Span = __Span;` … `DeclAnnotation`, `Param`, `Field`, `Method`, `HookNode`): a module imports them (`import {compiler.Span} from "std"`), a std module `import {compiler.DeclKind};`; a std type whose field names one of them is exported with the alias's target, so its importer need not import the alias (`comptime.zig`, `stdModuleTypes`); and decision 625 (2)'s typed AST: `Node`, the union of one record per kind `compiler.ast(node)` builds code from (`Name`, `Lit`, `Member`, `Call`, `Arg`, `List`, `Tuple`, `Binary`, `Unary`, `If`, `Lambda`, `Syntax`; decision 753's `Fn`, `FnParam`, `Return` and the type nodes `NamedType`, `ArrayType`, `TupleType`, `LabeledTupleType`, `OptionalType`, `FnType`, `GenericType`, `UnionType`), each with a field set of its own, held to `comptime/ast_build.zig`'s `kinds` by `comptime/tests/compiler_members.zig`
    ├── code.bp              ← `code` (decisions 625 (4), 637, 638, 753): the template that reads code written with `${…}` holes into `compiler.Node` records and answers `compiler.ast` of them — a `syntax` hole `Syntax(e)`, any other `Lit(v)`; its tokenizer and parser are botopink, the vocabulary `Node`'s, a text that is none refused at the call; `import {code} from "std"`
    ├── types.bp             ← `Type` (decisions 307, 308): the derived-type functions `keys`, `partial`, `required`, `merge` — compile-time only, every parameter `comptime x: T` (decisions 364, 575 (4)), `pick` / `omit` (`comptime ..fields: Type.Field<T>[]`, decision 267) and the associated `Type.Field<T>` — bodyless (the compiler is the body, `comptime/derived_types.zig`; `keys` the alias of `Type.Field<T>`) — and `Field<T>`'s `of` / `all`, answered by the checker (`infer.zig` § decision 308)
    ├── context.bp           ← contexts (decisions 354, 378, 379, 722, 723) and the render scope (388): `Context<T>(contextValue)`, `createContext` (a type's default at module level, a context to provide in a component), the hooks `provide` / `context` (`use` only; the compiler lowers each where it is written — the bodies panic), `RenderScope` (`RenderScope.root()`) and `Rendered<R>`, and the scope lowering's `Frame` / `push` / `find` (the read's context value when nothing of its type is provided) / `rendered` / `valueOf` / `root`
    ├── hooks.bp             ← decisions 755, 771, 774: `memo<T>(make: fn() -> T) -> Component<T>` (`use` only; lowered by the compiler where it is written — the body panics) and the slot functions the lowering calls, `slot` / `read`, over a cell per target (a process-dictionary entry keyed by a `make_ref()` on erlang and beam, an object on commonJS, `wasi: .CellNew` … on wasm)
    ├── erlang.bp  beam.bp   ← the target's surface — outside the criterion
    ├── io/                  ← talks to the world outside the process; may import from the root
    │   ├── mod.bp           ← `pub mod fs; http; net; clock; random; os; env; process; stdin; terminal;` (ten lines)
    │   ├── fs.bp  http.bp  net.bp
    │   ├── clock.bp         ← was `time`
    │   ├── random.bp        ← was `random` + `crypto.randomBytes`
    │   ├── os.bp  env.bp  process.bp   ← `process` also holds signals and spawned children (decision 506 (1), below)
    │   └── stdin.bp  terminal.bp       ← a CLI's host primitives (decision 506 (1), below)
    ├── testing/             ← the harness (`botopink test` only); may import from `io/` and the root
    │   ├── mod.bp           ← `pub mod asserts; mocks;`
    │   └── asserts.bp  mocks.bp   ← the snapshot engine left std for the `snap` library (decision 391)
    └── sidecars/random.mjs  ← Mulberry32 PRNG used by `io/random` (the only sidecar: `mocks` keeps its tables on `globalThis`, not in a `.mjs`)
```

## Importable modules

`import {<module>} from "std"` for a root module, `import {io.<module>}` /
`import {testing.<module>}` (or the group `io: {fs, clock}`) for the other two
categories, then qualified calls (`clock.nowMillis()`) — only the leaf of an
import path enters scope (decision 107), so `import {io.fs}` binds `fs`. A
folder is a namespace of its submodules (decision 110): `import {io} from
"std"; io.fs.readText(p)`. A `collections` constructor is called on its type
(`Dict.empty()`, `Set.fromList(xs)`, `Queue.empty()` — decision 111), reached
as a leaf or through the module namespace (`collections.Dict.empty()`). The table names each module
by its import path.

Inside std a module imports another by the brace form, with no `from` —
`import {path.relative};`, `import {io.fs};` — as any package imports its own
modules (decision 309): `from "std"` here is `error[module-import-with-from]`
at the source string. Embedded in a consumer's build the same import names
`std/path` (`comptime.zig` `embeddedStdProgram`).

| Before (flat, until front 23) | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`; `dict.empty()` → `Dict.empty()`, `sets.fromList(xs)` → `Set.fromList(xs)`, …) |
| `crypto` (the digests), `content_hash` | `hash` |
| `crypto.randomBytes`, `random` | `io.random` |
| `base64` (`encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe`) | `encoding` (`base64Encode`, `base64Decode` — `@Result`, `base64UrlEncode`, `base64UrlDecode` — `@Result`) |
| `time` | `io.clock` |
| `fs`, `http`, `net`, `os`, `env`, `process` | `io.fs`, `io.http`, `io.net`, `io.os`, `io.env`, `io.process` |
| `asserts`, `mocks` | `testing.asserts`, `testing.mocks` |
| `snapshots` | left std for the `snap` library (decision 391): `import {assertAs} from "snap";` with `"snap"` in `botopink.json` `"dependencies"` — `import {testing.snapshots} from "std"` answers the plain unknown-module error (407) |

| Module | Surface |
|---|---|
| `collections` | `type Dict<K, V>` (association list, `implement Index<K, V>`): `Dict.empty()`, `Dict.ofEntries(entries: Array<#(K, V)>)` (decision 174 — inserted in order, so a repeated key keeps its last value at the place of that last entry, as a chain of `insert` does), `at`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` · `type Set<T>`: `Set.empty()`, `Set.fromList(xs)`, `contains` (membership is `==`, so records dedup by value on every target — decision 210; `Array.indexOf` is the host's identity on commonJS), `size`, `isEmpty`, `insert`, `delete`, `toList`, `union`, `intersection`, `difference` · `type Queue<T>` (FIFO): `Queue.empty()`, `Queue.fromList(xs)`, `size`, `isEmpty`, `enqueue`, `dequeue`, `peek`, `toList` · `type Order` with the module fns `lt`, `eq`, `gt`, `toInt`, `reverse` |
| `bpp` | The contract between the toolchain and a framework that unfolds `.bpp` files (decision 361; 116's carve-out of this track): `import {bpp} from "std";` then `#[bpp.html]` on the template function the markup unfolds onto, `#[bpp.style]` on the style section's, and `#[bpp.htmlPrelude]` / `#[bpp.stylePrelude]` on the marker `val` of a prelude module (`pub val prelude = bpp.Prelude();` — a module takes no annotation, 315). Each decorator checks only where it sits — `html` / `style` a template function (its first parameter `syntax q: string`, decision 578), the two prelude roles a `val` (decision 356) — and refuses otherwise at the annotation; the counts and what a prelude module may hold are the CLI's (`compiler-cli/src/cli/bpp.zig`). `type Prelude()` is the marker's value. Pure, no import; cells `conformance/modules/bpp/{run,refused}/src/cases/bpp_*`, `conformance/modules/bpp/cells/bpp_*`, `modules/bpp/{run,refused}/src/cases/bpp_*` |
| `string_builder` | `type StringBuilder`: `empty`, `fromString`, `fromStrings`, `append`, `prepend`, `toString`, `length`, `isEmpty` |
| `math` | constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; trig + hyperbolic. **One answer on every target and every OS** (decisions 238, 259, 263): the operations IEEE 754 makes exact stay host calls (`abs`/`floor`/`trunc`/`sqrt`/`minF`/`maxF` — `op:` on wasm —, and `round`); every transcendental is a `fn:` private body under `// ── the bodies` that erlang, beam and wasm run (commonJS keeps V8's `Math.*`, which is the same fdlibm) — a port of the fdlibm V8 runs (`exp`, `expm1`, the logarithms, the trigonometry with `remPio2` for |x| ≤ 2^19·π/2 — beyond it a panic, `__kernel_rem_pio2` not ported (`decisions-pending.md` 263-a) —, `asin`/`acos`/`atan`/`atan2`, the hyperbolics) whose word operations are exact arithmetic (`highWord`, `lowWord`, `fromWords`, `withLowZero`); `roundHalfUp` is wasm's `round` (V8's ceil-based `Math.round`, not `f64.nearest`). `pow` is a bodied `fn` calling `powBody` on all four targets, commonJS included (a declaration whose every source is a `body:` cell is `external-all-bodies`, decision 610): a port of glibc's `pow` (2.28+) as x86-64 glibc runs it — the `__ieee754_pow_fma` build, whose compiler fused each `a * b + c`, so every fused multiply-add is computed exactly (`fusedMultiplyAdd`: Dekker's product, a two-sum and a sum rounded to odd — `sumRoundedToOdd`, `unitInFirstPlace`) — with glibc 2.44's 128-entry tables (`powInvc`/`powLogc`/`powLogctail`, `expHead`/`expTail`); ECMA-262's `pow(x, NaN)` / `pow(±1, ±Infinity)` = NaN first. A zero is tested with `isZero` and a sign with `signBit`, never `== 0.0` / `1 / v` alone: erlang and beam compare `-0.0` unequal to `0.0` (`=:=`) and have no `1 / 0`. Every host-bound `declare fn` carries `#[compiler.stage(.Any)]` (decision 376 (4)): a pure primitive, so a function calling it keeps the stage `Any`. `modules/decisions-taken/math_same_bits_every_target-263/cells/std_math_on_every_target` |
| `decimal` | `type Decimal(unscaled: bigint, scale: i32)` — Java's `BigDecimal` (decision 332 (2), 144 B-24; decision 500 keeps it in std when `json` leaves): `add` / `sub` (scale the larger of the two) and `mul` (scale their sum) exact; `div(other, scale, rounding)` at the scale given, rounded by `type Rounding { Up, Down, Ceiling, Floor, HalfUp, HalfDown, HalfEven, Unnecessary }` (Java's `RoundingMode`; `Unnecessary` aborts with `Decimal.div: rounding necessary` when the quotient is inexact, a zero divisor with `Decimal.div: division by zero`); `compare(other) -> i32` by numeric value whatever the scales; `toString()` the plain text, scale kept, never an exponent (a negative scale writes its zeros); the associated `Decimal.parse(text) -> @Result<Decimal, string>` (sign, digits, optional `.digits`, optional exponent; `Decimal.parse: "<text>" is not a decimal`). Pure `.bp` (no host cell), so it runs on the four targets: `conformance` `modules/decisions-taken/bigint_decimal_strict_json-332/cells/decimal_exact_arithmetic`, `modules/decisions-taken/bigint_decimal_strict_json-332/cells/decimal_div_rounding_necessary_aborts`, `modules/decisions-taken/bigint_decimal_strict_json-332/cells/decimal_div_by_zero_aborts`. `==` is the language's structural `==` (decision 348): `1.0` and `1.00` are `compare`-equal, not `==` — decision 332 (3) asks otherwise, an open question |
| `testing.asserts` | The canonical assertion API (1.0.10-beta front 01-std, `asserts-api.md`): every fn is `-> @Result<void, string>`, consumed with `try`, `actual` first, one literal message `asserts.<fn>: <what>` each — `isTrue`, `isFalse`, `equals`, `notEquals`, `approxEquals`, `deepEquals`, `isNil`, `isNotNil`, `isOk`, `isError`, `contains`, `notContains`, `startsWith`, `endsWith`, `matches(actual, pattern)`, `isEmpty`, `isNotEmpty`, `lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`, `throws<T>(body)`, `throwsWith<T>(body, needle)` (generic over the body's own type, decision 493), `fail(message)`, plus `errorText(r) -> string` (the `Error` payload, `""` for `Ok`). No `pub declare fn` (STD-001-clean on every target); `matches`/`deepEquals` sit on the private cells `regexMatches`/`canonical` (Node + Erlang; beam compiles the Erlang templates; wasm refuses the module where the two call their cells, called or not — decision 146 — so an import of `testing.asserts` is refused there: `conformance/modules/decisions-taken/asserts_throws_generic-493/cells/std_asserts_on_every_target` runs the rest on commonJS, erlang and beam and pins the wasm refusal at the import), and `throws`/`throwsWith` run the body under `failure.attempt` (decision 493; the private `tryCatch` cell is gone). A caught `@panic(text)` / `@todo(text)` is its own `text` on every target, so a `throwsWith` needle with a `"` or a `\` matches alike; any other raise is `attempt`'s host message — its JS `message` (else `String(e)`), the erlang reason by `~tp` (`badarg`, no `error:` class prefix). The old panicking `truthy`/`falsy`/`equal`/`notEqual`/`approxEqual`/`AssertError` are gone. Named `asserts` — `assert` is a keyword |
| `testing.mocks` | Mockito-style mocks over a `behavior` (1.0.10-beta front 01-std, `onze-migration.md`; decision 71) — 100 % of the retired `onze` library, Erlang templates carried over, Node templates inlining what `onze.mjs` held. Eight `pub declare fn` cells (`newMock`, `key`, `pushMatcher`, `invoke`, `beginVerify`, `whenCall`, `thenReturnCell`, `thenThrowCell`), the matchers `eq`/`anyInt`/`anyString` (matchers, **not** assertions — they push a descriptor and answer a dummy), the verify specs `atLeastOnce`/`times`/`never`, `pub type Stub` with `thenReturn`/`thenThrow`, `when(value)`, `verify(mock, spec)` and the `#[mock]` decorator. Mutable state is one cell per host process: `globalThis.__bp_mocks` on Node (the `emilia.bp:24` shape), the `'__bp_mocks_*'` process-dictionary keys on Erlang — **no `.mjs` sidecar**. The only std module with `pub declare fn`, so STD-001 refuses `import {testing.mocks} from "std"` on beam and wasm (the cells have to be exported: `#[mock]`'s emitted body calls them). a consumer reaches `#[mock]` as `#[mocks.mock]` — see *Tests* below |
| `path` | `separator`, `delimiter`, `split`, `isAbsolute`, `basename`, `dirname`, `extname`, `join`, `normalize`, `relative(src, dst)`, `resolve` (posix only); front 01: `withoutExtension`, `isInside(parent, child)` (the traversal guard — both sides through `resolve`, a relative child resolved against the parent, `..` and `../…` refused) |
| `io.random` | `float`, `coin` (the one boolean draw — its alias `bool()` was dropped: a declaration named like a primitive type is refused, front 97 under decision 174's note), `intInRange`, `pick`, `shuffle`, `seed`, `seededFloat` — NOT a CSPRNG; `randomBytes(n)` (hex of `n` strong bytes, was `crypto.randomBytes`); front 01: `secureToken(bytes)` (strong bytes as unpadded base64url: 32 → 43 chars), `uuidV4()` (`randomUUID` / 16 strong bytes with the version and variant bits rewritten in the Erlang template — no bitwise operators in botopink) |
| `querystring` | The query-string CODEC (RFC 3986 §3.4 and the form flavour): `parse(query)` and `parseForm(body)` -> `@Result<Array<#(string, string)>, string>` — split on `&` (empty fields dropped, duplicates kept in order), each field on its FIRST `=` (no `=` → empty value), both sides percent-decoded; `parse` strips a leading `?` and keeps `+`, `parseForm` reads `+` as a space and strips nothing. REFUSED (rakun's 03r-e rule, as an `Error`): a `%` not followed by two hex digits, an escape sequence that is not UTF-8, a control character (U+0000–U+001F, U+007F) raw or as its escape. `stringify(pairs) -> @Result<string, string>` percent-encodes both sides over the RFC 3986 unreserved set (`a b` → `a%20b`, `+` → `%2B`) and refuses a control character, so its text reads back through either parser. The percent codec is `encoding`'s, imported (`import {encoding.percentEncode, encoding.percentDecode, encoding.hexDecode};` — a std module imports another by the brace form, decision 309; `from "std"` inside std is `error[module-import-with-from]`); the refusals are decided in botopink before either cell runs. Walks strings by `at`, so a `%` reads its two digits by index. Runs on commonJS, erlang and beam; wasm refuses the import (STD-001: `encoding`'s cells have no wasm binding) |
| `io.clock` | `nowMillis`, `monotonicMillis`, `measureMillis`, `formatIso8601`; front 01: `type Civil(year, month, day, hour, minute, second, weekday)` (UTC, ISO weekday Monday = 1), `type Duration(millis: i64)`, `parseIso8601` (`@Result<i64, ClockError>`, `ClockError.NotRfc3339` — decision 486: the private `parseIso8601Host` writes `result: true`; RFC 3339 with the offset REQUIRED — Node's lenient `Date.parse` is gated by a shape check), `toCivil`, `offsetMinutes` (host timezone, minutes EAST of UTC; the three abort past RFC 3339's epochs, decision 497), `millis`/`seconds`/`minutes`/`hours` (take `i32`, widened by the private `wide` — std's `toI64()`, no host cell), `add`, `toMillis`, `sleep(ms)` (synchronous: `Atomics.wait` / `timer:sleep`), `deadline(d)` (an absolute epoch reading), `isExpired(at)`; front 97: `parseDuration(text) -> @Result<i64, string>` — milliseconds of digits followed by ONE unit, `ms` `s` `m` `h` `d` (`"30s"` → `30000`); no unit, a fraction, a sign, whitespace, an uppercase unit, two units and the empty string are `Error("clock.parseDuration: \"<text>\" is not a duration: digits, then one unit of ms, s, m, h or d")`, and a duration beyond 2^53 − 1 milliseconds is `… is out of range` (the count through `string.parseInt()`, the product against the private `largestExactMillis`, a literal — the bound stays, decision 498: a duration is handed on as a timer delay or a JSON number, both `f64`); pure `.bp`, the same texts on both targets |
| `url` | `type Url`, `parse`, `serialize` |
| `unicode` | `fromCodepoint` (a `fn:` body over `String.fromCodepoint` on all four targets, decision 262), `firstCodepoint`, `codepoints`, `type NormalizationForm`, `normalize(s, form)` — NFC, NFD, NFKC, NFKD by std's own botopink body on all four targets, over the generated `unicode_tables` (decision 333 (A), § unicode): no host normalizer, so every target answers the same for every code point; text whose code points are all below U+00A0 comes back as it is. Builds and runs on wasm (`modules/decisions-taken/unicode_normalize_in_botopink-333/cells/std_unicode_on_every_target`, one `.out`) |
| `io.process` | `exit`, `cwd`, `platform`, `pid` (`arch` is `io.os`'s — the duplicate was folded); front 01: `type Exit(status, stdout, stderr)`, `run(cmd, args)` (no shell; `@Result<Exit, HostError>` — `result: true` on the cell itself, no `ProcessError` for `run` (a public body over a cell with no wasm binding makes wasm refuse the whole module) — a process that ran is `Ok` whatever its status, `Error` only when it could not start; Erlang folds stderr into stdout through `stderr_to_stdout`, so `stderr` is `""` there), `runShell(cmd)` (`/bin/sh -c`, stdout+stderr as text, STATUS-LOSING on both targets). No `onSignal`: a closure handed to a host cell is unverified on erlang **Decision 506 (1), the CLI's half** (144 B-27 step 6): `type Signal { Int, Term, Hup, Winch }`; `type ProcessError { NotFound(command), PermissionDenied(command), NoSuchProcess(pid), Unsupported(message), Other(message) }`; `onSignal(s, handler) -> @Result<void, ProcessError>` (Node `process.on`; Erlang `os:set_signal/2` and a `gen_event` handler of `erl_signal_server` — a module, `bp_signal_handler`, compiled and loaded from source text on first use because a template is an expression — that calls, in order, the funs kept in `persistent_term`; **`Int` is `Unsupported` there**: `os:set_signal/2` takes no `sigint`, the VM keeps it for its break handler; `Winch` needs OTP 28, the project's floor); `spawn(cmd, args) -> @Result<Child, ProcessError>` over `type Child(pid, handle)` with `wait() -> @Task<i32>` (`128 + n` for a child ended by signal `n`; repeatable), `kill(s) -> @Result<void, ProcessError>` and `forwardSignals()` (`Term`, `Hup`, `Winch`, `Int` where `onSignal` takes it). The child shares the parent's stdout and stderr: inherited on Node; on Erlang the port carries stdout and stderr merged and `wait()` writes it to stdout while it waits (and the child's stdin is the port's pipe, not the parent's). Failures are told before anything starts — the Node cell looks `PATH` up itself, because `child_process.spawn` reports a missing binary on a later event. Cells `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_signal_handlers`, `std_io_process_spawn`, `std_io_process_forward_signals` (commonJS, erlang, beam; the wasm audit refuses them on the host bindings). A cell names the signal `process.Signal.Term`: the section `.Term` as an argument of `process.onSignal` is a bare `Term` on commonJS (a compiler row). |
| `io.stdin` | **Decision 506 (1).** `readLine() -> @Task<?string>` (the line without `\n` / `\r\n`, a last unterminated line included, `null` at the end — repeatedly), `isTTY()`, and the byte-level `readChunk() -> @Task<?string>` (whatever has arrived; `null` at the end). Node: one reader on `globalThis.__bpStdin` (buffer, queue of waiting reads, a pump) over `process.stdin`'s events, the stream paused whenever nobody waits so the process can exit, and a `readLine` waiting on a terminal does not block signal handlers; Erlang: `io:get_line/2` / `io:get_chars/3` with `{encoding, unicode}` (a `readChunk` after an Escape waits 50 ms for the rest of the sequence in a helper process whose answer the next read collects). `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_stdin_eof` (a cell's stdin is `/dev/null`); the lines themselves were read off a pipe by hand on the three targets. No wasm binding |
| `io.terminal` | **Decision 506 (1).** `stdoutIsTTY()`, `size() -> ?#(i32, i32)` (columns, rows; `null` with no terminal), `setRaw(on) -> @Result<void, TerminalError>` (`TerminalError { NotATerminal, Other(message) }`), `keys() -> @Stream<Key>`, `type Key { Char, Ctrl, Alt, Enter, Tab, Backspace, Delete, Escape, Up, Down, Left, Right, Home, End, PageUp, PageDown, Unknown }` and `parseKey(sequence)` (pure, std's tests pin it). Node: `tty.isatty`, `process.stdout.columns`, `setRawMode`; Erlang: `prim_tty:isatty/1`, `io:columns/0` (after `shell:start_interactive({noshell, cooked})`, which a TTY stdin lets `size()` start; else `stty -F /proc/<pid>/fd/1 size`), `shell:start_interactive({noshell, raw})` plus `stty … -isig` on `/proc/<pid>/fd/0` (the VM's raw mode keeps `ISIG`: Ctrl-C would open its break menu instead of arriving as `Ctrl("c")`). **`keys()` on Erlang** is the language's eager `@Stream`: it gathers every key before the first is yielded, so it ends only with the input — an interactive key loop reads `stdin.readChunk()` and `parseKey`. `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_terminal_not_a_tty`; the terminal's own answers were checked by hand under a pty (`script`) on the three targets. No wasm binding |
| `io.os` | `hostname`, `arch`, `cpuCount`, `tmpdir`, `userInfo` (`type UserInfo`), `eol`. `userInfo`'s Erlang template builds the record's run-time tuple by hand, so it names the type's module atom — `'std@io@os@@UserInfo'`; it still read `'std@os@@UserInfo'` from before the module moved under `io/`, which no test saw until another std module imported `io.os` (`testing.snapshots`, front 97) and `u.username` became a call into the type's module: `{error,undef}` |
| `io.env` | `read`, `write`, `clear`, `args`, `vars` (`get`/`set` are keywords) |
| `regex` | `matches`, `replace`, `replaceAll`, `splitOn`, `type Match`, `match`, `matchAll`; front 01: `type Regex(handle: unknown)`, `compile` (`@Result<Regex, HostError>`, `result: true`, the host's reason in `message` — no `RegexError`, for the wasm reason `io.process` gives), the host-backed METHOD `Regex.matches(input)` — `re.matches(input)`, the module's `matches(pattern, input)` without re-compiling; it was the free `runCompiled(r, input)` (`element(2, R)` on erlang — a record crosses into a cell as its tuple), `captures` (`?Array<string>`, group 0 first, `null` on no match, `""` for a group that did not take part), `namedCaptures` (`#(name, value)` pairs SORTED BY NAME — Erlang's `all_names` order, the Node cell sorts to agree), `escapeLiteral` (pure; backslash first) |
| `erlang` | Erlang BIF bindings (`abs`, `element`, `spawn`, `send`, …); the erlang codegen reads this file to know which names are BIFs |
| `json` | `parse`, `stringify` (validate + canonical re-encode, `@Result<string, HostError>`, `result: true` — no `JsonError`: a body over the unbound cell would make wasm refuse `std/json` whole, and `json.quote` / `array` / `object` / `decode` run on wasm); front 01 steps 11–13 (decisions 116, 117): `quote(s)` (one JSON string literal: `\"` `\\` `\b` `\f` `\n` `\r` `\t`, every other code point below U+0020 as lowercase `\u00xx`, nothing else — the erlang cell is a byte walk because `json:encode` writes UPPERCASE hex), `unquote(literal)` (`@Result<string, HostError>`, `result: true`, its wasm body `unquoteBody` building the `HostError`; exactly one string literal), `array(items)` / `object(fields)` (values ALREADY encoded; keys quoted, order kept); step 13: `type Json { Null, Bool(value), Num(value: f64), Str(value), Arr(items), Obj(members: Array<#(string, Json)>) }` and `decode(s) -> @Result<Json, string>` — a botopink reader (not `JSON.parse` / `json:decode`, which reorder keys and keep the last duplicate): members in document order, a duplicate member name refused, trailing text refused, the RFC number grammar exactly (`01` `+1` `.5` `1.` `NaN` `Infinity` refused), an `f64` overflow refused, `\u` escapes and surrogate pairs decoded, an unpaired surrogate and a raw control character refused; every error reads `json.decode: <what> at byte <n>` (UTF-8 bytes). The reader is a loop, not a recursion (`readValue` over the linked stack `Open`): how deep a document nests is bounded by memory alone on every target — the recursive reader overflowed node's stack between 1 000 and 1 500 levels where erlang read 3 000; "json.decode reads a document nested 3000 levels deep" pins it. One private conversion cell used by the reader, not a parser: `codepointText` (a `\u` escape). A numeral becomes its `f64` in botopink (decision 142, `numeralValue`): Clinger's fast path (≤ 15 digits, |e| ≤ 22), else exact big-integer arithmetic (15-bit limbs in `Array<i32>`, so every product stays below 2^31 on every target; integer quotients spelled `(a - a % b) / b`, which is exact on every target) — the quotient's 53 bits by shift-and-subtract, rounded half-to-even against the remainder, assembled with no int → float conversion (bits accumulated into an `f64`, scaled by exact powers of two); bit-identical to the host `strtod` on 3500 randomized numerals including every halfway point tried, and pinned by the test "json.decode rounds a numeral to the nearest f64, ties to even". Its loops never `throw` from inside a body — the erlang backend compiles a `throw` in an `if` branch beside `var`-assigning branches to an "unsafe variable" `erlc` refuses; they record the problem and throw after the loop. Tests build non-ASCII text with the private `codepointText` cell, never a literal: the erlang backend truncates a `\u{…}` above U+007F to one latin1 byte. **The readers are methods of `Json`** (1.0.11-beta front 97 — the accessors eight library files had each written): `kindName() -> string` (`null`, `a boolean`, `a number`, `a string`, `an array`, `an object` — what a diagnostic says it found), `isObject() -> bool`, `members() -> Array<#(string, Json)>` (document order; `[]` for a non-object), `field(key) -> ?Json` (the first member of that name; `null` when missing or not an object), `str() -> string` (`""` for a non-string), `items() -> Array<Json>` (`[]` for a non-array). None throws and none answers a `@Result`; a consumer's `membersOf(v)` / `fieldOf(membersOf(v), k)` / `strOf(v)` / `itemsOf(v)` becomes `v.members()` / `v.field(k)` / `v.str()` / `v.items()`. Pure `.bp` in the type's body (`filter`, `at`, `unwrapOr` — host-backed members only), one inline test per method over all six variants; measured from a consumer on commonJS, erlang and beam |
| `io.fs` | `type FsError`, `FsError.message()` (decision 563), `type FileStat`, `type File`, `readBytes`, `readText` (UTF-8 checked), `writeBytes`, `writeText`, `appendText`, `open`, `create`, `openAsset`, `exists` (a path of ANY kind — file, directory, device such as `/dev/null`, FIFO, socket; a symlink is followed, a dangling one is `false`: `existsSync` / `file:read_file_info`, which agree; `filelib:is_file` answered only files and directories), `list`, `mkdir`, `mkdirRecursive` (the directory and every missing one above it; one that is there is `Ok`, a file in the way an `Error` — Node `mkdirSync({ recursive: true })`, erlang `filelib:ensure_path/1`), `rm`, `copy`, `stat` (every fallible op answers `@Result<…, FsError>`, never a `string` error — decision 540; the dangling-link text below is the message of an `Other`); front 01: `walk(root)` (regular files, relative, `/`-separated, sorted; a missing or non-directory root, or an unreadable directory under it, is `Error`; a link is followed — to a file it is listed, to a directory it is walked; a DANGLING link is an `Error`, `Other(root, "fs.walk: dangling link \"<relative path>\"")` built by `walk` from the cell's `dangling` list, the same text on both targets and the first one in sorted order when there are several — decision 178; the Node cell reads `statSync` with `throwIfNoEntry: false` to tell it from a host failure). The paths do not depend on how the root is spelled (`dir`, `dir/`, `dir/.`, `./dir`, `dir/sub/..`, absolute or relative — one inline test per spelling, and `conformance` `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cells/std_fs_walk_root_spellings` from a consumer on commonJS, erlang and beam): the Erlang cell walks `file:list_dir/1` itself and builds each relative path from the names it descends through, because cutting the root's written length off `filelib:fold_files/5`'s full paths was wrong whenever `filename:join/2` had normalised them (a root ending in `/.`, which is what `path.join([dir, "."])` answers — `path.join` keeps a `.` segment on every target, `path.normalize` drops it — lost two characters of every path). `glob(pattern, root)` reads the pattern segment by segment by ONE rule on both targets (decision 177): `**` is zero or more directories, a segment with `*` `?` `[…]` `{a,b}` matches the names of one directory, any other segment is a name; a wildcard never matches a name starting with `.` unless the segment itself starts with the dot (`.*`, `.cache/*.bp` — so `?x`, `[.]x` and `{.a,b}` do not); `**` and a wildcard segment continue into REAL directories only — the walk does not descend through a link to a directory, though `*` lists the link as a name and a segment that names it (`linked/*.md`) goes through it; the last segment matches an entry of any kind, a final `**` is every entry at every depth, a trailing `/` keeps real directories; paths relative, `/`-separated, sorted, each once; a missing root is `Ok([])`. Both cells are the same walk and only the match of one segment against one directory is the host's (`fs.globSync(segment, { cwd })` / `filelib:wildcard/2`), with the dot rule applied over its answer — the two hosts' own whole-pattern matchers disagreed with each other and with themselves (`filelib:wildcard` matched dot names and walked links; `globSync` answered `lnk/b.txt` for `**/*` and not for `**/*.txt`). Not pinned: an alternative holding a `/` (the pattern is split first — it matches nothing), a `..` segment (read as a name), backslash escapes. `list` answers the host's order (sorted on Node, directory order on Erlang). `stat` (front 97 step 13, decision 319): the Node form reads `statSync` with `bigint: true` and answers `size` and `mtime` (`mtimeNs` floored to whole seconds, × 1000 — whole seconds on every target, as erlang reads it, decision 499) in the canonical form — a `number` within ±(2^53 − 1), a `BigInt` beyond; the Erlang `mtime` is whole seconds × 1000; `conformance` `modules/decisions-taken/stat_mtime_whole_seconds-499/cells/fs_stat_mtime_whole_seconds`; `conformance` `modules/decisions-taken/i64_is_64_bit_everywhere-319/cells/std_io_i64_canonical`. `removeTree(path) -> @Result<i32, FsError>` (front 97 — it was a private test cell): a file, a link (the link, never its target) or a whole directory tree, and `Ok` for a path that is not there (`rmSync` recursive + force / `file:del_dir_r/1`); what `testing.snapshots`' tests clear their scratch directories with. `rm` removes a FILE only on both hosts — a directory is `IsDirectory` (Node `ERR_FS_EISDIR`; Erlang answers `eperm`, so its template reads `read_link_info` first and answers `eisdir`), whatever its comment says of an empty one. Private test cells `scratchDir`/`workingDir`/`linkTo` — every walk/glob test builds its fixture under the host tmpdir and removes it. Imports `path.relative` (the relative-root tests). **Decision 540.** `pub type FsError { NotFound(path), PermissionDenied(path), IsDirectory(path), NotDirectory(path), AlreadyExists(path), InvalidUtf8(path, offset: i64), Other(path, message) }` — the same OS error the same variant on every target (the host cells write `result: true` and answer `@Result<R, HostError>` (decisions 431, 490), no cell catching by hand; `fsError`/`lift` read the `HostError`'s message — Node's `ENOENT: …` / `Path is a directory: …`, the reason atom `enoent` on Erlang — as the `FsError` of the path the caller wrote; `walk`'s dangling links are a field of the private `Walked` record, not an error, and `glob` answers a plain list). `exists` stays a `bool`. `readText` is `readBytes` + `utf8Offset` (a scan on Node, `unicode:characters_to_binary/3` on Erlang: the offset of the first byte of the first invalid sequence, `-1` when there is none) — `InvalidUtf8` on every target. The handle: `open(path)` (read; a directory is `IsDirectory` on Node too, whose `openSync` opens one) and `create(path)` (write, creating or truncating) answer a `File(location, handle)` — `handle` the host's and opaque: a `{ fd, mem, pos, buf }` object on Node, on Erlang the io device `open` makes (`[read, binary, read_ahead]` — never `raw`: a raw descriptor reads only in the process that opened it, and `chunks` / `lines` run in the stream's own process, 144 B-128) and the raw descriptor `create` makes — `File implement Closeable` (`Closeable` is the ambient `pub behavior Closeable { fn close(self: Self); }` of `primitives.bp`, decision 539 (6), taken by generic code with no import) with `path()`, `size()`, `read(n)` (empty at the end), `bytes()`, `text()`, `chunks(size = 65536)` and `lines()` (`@Stream<@Result<…, FsError>>`, a failure ends the stream; `lines` strips `\n` and `\r\n`, and its `InvalidUtf8` offset counts from the first line that call read), `hash()` (SHA-256 of the WHOLE file, lowercase hex, the position untouched), `write(b)` (an in-memory handle is `Other(path, "the file is open for reading")`, tested by `rawReadOnly`) and `close()` (a no-op on a closed or in-memory handle, a failure to close unreported). `openAsset(asset)` is the `File` over an embedded `Asset`'s bytes (decision 538): a `mem` handle (a `counters` cell for the position on Erlang), read-only, `close` a no-op; `a.open()` on an `Asset` is rewritten to `fs.openAsset(a)` by `infer.zig` `inferAssetOpen`, which needs the module to import `io.fs` (`embed-open-needs-fs`). A `Bytes` is measured with `b.length()`: the property form `b.length` is `string:length` on erlang and beam (a `badarg` on bytes that are not UTF-8). **No wasm binding**: the `wasi:filesystem` half is front 164's (`needs: [.Filesystem]`); a wasm build of `std/io/fs` is refused at the first body that calls a host cell without one (`utf8Offset` today), and a call reaching `io.fs` at the call by STD-001 (`reaches \`raw…\``). |
| `io.http` | `type Response`, `type Request(method, url, headers = [], body = null)`, `type Method` (`Get`, `Post`, `Put`, `Delete`, `Patch`, `Head`, `Options`; `verb()`), `type Header(name, value)`, `type HttpError { NotAllowedOnHost, Network(message), Timeout }`, `fetch(req: Request) -> @Task<@Result<Response, HttpError>>` (decision 623; `fetch(url)` is gone. A transport failure is `Error(HttpError)`: `fetch` maps the private `result: true` binding `fetchHost`'s `HostError` — a message naming a timeout is `Timeout`, any other `Network(message)` — decisions 486, 490; an HTTP error status is an `Ok` response), `fetchStatus` |
| `encoding` | The wire formats (front 01; decision 106 — was also `base64`, whose four tests sit at the foot of the file under these names): `base64Encode`/`base64Decode` (`@Result<string, EncodingError>`; the private `base64DecodeHost` writes `result: true`, and Node's silent truncation is caught by re-encoding), `base64UrlEncode`/`base64UrlDecode` (RFC 4648 §5, no padding, `replaceAll` not `replace`), `hexEncode`/`hexDecode` (lowercase; `@Result<string, EncodingError>`, validated before `Buffer.from` truncates), `percentEncode`/`percentDecode` (RFC 3986 unreserved set on BOTH targets — the Node cell also encodes `!'()*`; `@Result<string, EncodingError>`); `EncodingError { NotBase64, NotHex, NotPercentEncoded }` (decision 486), the `…Bytes` bridges answering it too, `formStringify(pairs)`/`formParse(q)` over `#(string, string)` (percent-aware, `+` read as space on parse, a field that does not decode keeps its raw text). Tests carry no non-ASCII literal: the erlang backend lowers one to a latin1 `<<"\x{e9}">>` and refuses a codepoint above U+00FF — non-ASCII enters through `hexDecode` |
| `hash` | Every hash, pure (decision 106). The hex digests (was `crypto`): `sha256`, `sha512`, `md5`, `hmacSha256` (hex strings). The digests in the shape they are compared in (front 01, the hmac half): `hmacSha256Base64Url(key, data)` (JWS HS256), `sha256Base64Url(data)` (43 chars), `sha1Base64(data)` (the RFC 6455 accept key only), `equalsConstantTime(a, b)` (`timingSafeEqual` / `crypto:hash_equals/2`; a length mismatch is `false`, never a throw). Base64url via `base64:encode/2` `#{mode => urlsafe, padding => false}` (OTP 26+). Tests pin RFC 4231-style, RFC 6455 §1.3 and empty-SHA-256 vectors. `pbkdf2Sha256(password, salt, iterations, length) -> string` (1.0.11-beta front 97; decision 175): PBKDF2-HMAC-SHA256, `length` BYTES of key as unpadded base64url (`pbkdf2Sync` / `crypto:pbkdf2_hmac/5`); `password` and `salt` are TEXT — their UTF-8 bytes, so a salt that is itself base64 is derived over its characters, not the bytes it encodes; `iterations` or `length` below 1 is a panic with one text on both targets (`hash.pbkdf2Sha256: iterations and length must be at least 1` — each host raised its own), never an empty key. Pinned by RFC 6070's inputs under SHA-256 (the RFC's own vectors are SHA-1) and RFC 7914 §11's two PBKDF2-HMAC-SHA-256 vectors, as base64url literals; a `pub fn` over the private cell `pbkdf2Derive`, with the private test cell `panicText`. The content hashes (was `content_hash`, 1.0.10-beta `01-std` front 03): `contentHash` (djb2 as lowercase hex, the `emilia.hashHex` templates verbatim — fast, trivially collidable, for filenames and internal keys) and `strongHash` (SHA-256 truncated to 32 hex, for input the caller did not choose). Both are `declare fn` with a Node and an Erlang cell — no bitwise operators or `toString(radix)` in the language, so the fold lives in the template; on wasm `contentHash` is std-wasm's, `#[@external(.Wasm(std: "hash.contentHash"))]` — the one implementation the wasm codegen transpiles and the comptime answers by (decision 440) — and `strongHash` is `fn:strongHashBody`. `String.trim` / `trimStart` / `trimEnd`, every other `String` method but the case mapping, and `Float.toString` (`primitives.bp`) carry `std:` cells too: on wasm they answer std-wasm's (decisions 441, 442). `cacheKey(parts)` / `strongCacheKey(parts)` hash a FRAMED key — `<length>:<part>` joined by `|`, the private `frame` being the only place parts are rendered — so `["user:1", "profile"]` and `["user", "1:profile"]` cannot collide; pure `.bp`. `etag(body)` answers `"<hash>"` WITH the RFC 9110 quotes, `weakEtag` `W/"<hash>"`, and `matches(body, ifNoneMatch)` is the 304 decision over an exact match, the `*` wildcard or a comma-separated candidate list (membership by `indexOf`, not `Array.contains` — a `default fn` a consumer's embedded copy would emit verbatim). `fingerprint(fileName, contents)` answers `app.<hash>.js` — the extension stays last, a leading dot is not a boundary, no extension means no trailing dot; the extension is measured as the last `.`-piece (written when Erlang's `lastIndexOf` answered a byte offset; the string indices agree since decision 169). Every expected hex in the inline tests is a literal, which is what pins the two targets to each other. `emilia.hashHex` is a duplicate now; collapsing it is a later, `emilia`-owned change |
| `io.net` | TCP and TLS, SERVER-ONLY (front 01). `type Listener`/`Socket`/`TlsListener`/`TlsSocket` (`handle: unknown`), `type Peer(host, port)`. What operates on one of them is a host-backed METHOD of its type, the same names on TCP and TLS: `Listener.port()` / `.accept(timeoutMillis)` / `.close()`, `Socket.recv(length, timeoutMillis)` / `.send(data)` (bytes sent) / `.close()` / `.peer()`, `TlsListener.port()` / `.accept(timeoutMillis)` (handshake included), `TlsSocket.recv` / `.send` / `.close()` — they were the free `listenerPort`, `accept`, `closeListener`, `recv`, `send`, `close`, `peer`, `tlsListenerPort`, `tlsAccept`, `tlsRecv`, `tlsSend`, `tlsClose`. The four that make one stay module functions: `listen(port, backlog)`, `connect(host, port, timeoutMillis)`, `tlsListen(port, certFile, keyFile)`, `tlsConnect(host, port, caFile, timeoutMillis)` (ALWAYS `verify_peer` + SNI — no unverified mode). The private test instrument `tlsEchoOnce(listener, length)` stays free: a method would be exported from `TlsListener`'s module. Every call answers `@Result`, the host reason as text (`timeout`, `econnrefused`, `closed`). Every commonJS cell is the refusal `Error("std/io/net: server-only")`, asserted by the tests; the erlang tests self-connect, time out, meet a closed port and handshake TLS against a throwaway CA `openssl` writes (OTP refuses a self-signed leaf: `selfsigned_peer`); every loopback operation expected to SUCCEED (or to be refused at once) gets a 10 s budget, which a green run never waits out and no scheduling delay crosses — only `accept(50)` with nothing pending is meant to expire |
| `escape` | No import (1.0.10-beta front 01-std-lib-enablement, decision 106 root); two private host cells `lineSeparator`/`paragraphSeparator` build U+2028/U+2029 (on wasm `fn: lineSeparatorText` / `fn: paragraphSeparatorText`, private bodies holding the literal — `modules/decisions-taken/external_wasm_binding_forms-238/cells/std_escape_on_every_target`), because the erlang backend lowers `"\u{2028}"` to the one byte `(` — a literal made `jsString` rewrite every parenthesis on erlang: `html` (`&` first, then `<` `>`), `attribute` (`html` + `"` `'`), `unescapeHtml` (the five entities, `&amp;` last), `jsString` (`\` `"` `<`→`\u003c`, `\n` `\r`, U+2028/U+2029 — a payload for a double-quoted JS string literal inside `<script>`); `scriptJson` (step 12, decision 116 rule 3: JSON text safe inside `<script>` — `&` `<` `>` U+2028 U+2029 as `\u` escapes, the same JSON value) |
| `async` | Combinators over `@Task<T>` (front 24 step E7, decisions 120/121/432 — a `@Task<T>` never fails; a fallible operation is `@Task<@Result<T, E>>`, the task that fails with `E`: on commonJS it rejects, and `await` reads `Error(e)`). TWO surfaces, because `@Task<T>` lowers EAGERLY on erlang (`await` is identity — `codegen/erlang.zig`). **Started tasks** — `allOf(Array<@Task<@Result<T, E>>>) -> @Task<@Result<Array<T>, E>>` (input order, stops at the first `Error` in input order), `all(Array<@Task<T>>) -> @Task<Array<T>>`, `race` — the guide's shape (`async.allOf([fetchUser(1), fetchUser(2)])`), written in botopink over `try await` / `await`; concurrent on commonJS, and on erlang honest rather than concurrent (`race` answers ELEMENT ZERO), with both behaviours asserted by the inline tests. **Unstarted tasks** — `runAll(Array<fn() -> @Task<T>>) -> @Task<Array<T>>`, `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` (`Error("timeout")`) — take thunks, so the erlang cell can `spawn` one process per task and gather by index and the node cell can call each thunk into `Promise.all` (the node cells of `runAll`, `raceOf` and `race` read a failing task's rejection as `await` does — `{ error }` for its failure, a crash re-thrown): genuinely concurrent on BOTH targets, and the surface a server front uses; a crash in a spawned task is re-raised (a crash is a bug, not a failure). `runAll` over `@Task<@Result<…>>` thunks is the settled view. Instruments `delay(millis, value)` (at least `millis` of the MONOTONIC clock on both targets — the Node cell re-arms its `setTimeout` from `performance.now()`, because a timer counts from libuv's cached loop time and fires early after a long synchronous stretch), `failed(message) -> @Task<@Result<T, string>>` (a failing task: `await` answers `Error(message)`) and the gate — `type Gate`, `newGate()`, `openGate(g)`, `awaitGate(g, millis) -> @Task<bool>` (`true` once open, `false` when the budget passes first; a pid-backed process on erlang, so it crosses into a spawned task) — which orders tasks by SIGNAL, not by clock; `errorText(r)` reads the `Error` side. The inline tests' verdicts do not depend on machine load: order and concurrency are told by gates (a crossed pair of `handshake`s can only both answer when the tasks run at the same time), durations only by LOWER bounds, never an upper bound on elapsed time; a gate's budget (`gateBudget`, 10 s) only turns a gate nobody opens into a red assertion instead of a hang. `allSettled` / `settleOf` / `unwrapAll` / `attempt` left with the rejection they settled (`specs/1.0.10-beta/decisions-pending.md` 24-g). NO cancellation: `raceOf`'s losers and `timeout`'s expired task run to completion. The erlang cells tag every reply with a `make_ref()` unique to their own call, so an expired task's late reply cannot be read by a later combinator in the same process. **Retry** (1.0.11-beta front 97; decision 170 — the natural names, which `rakun-messaging` also declares until its own step deletes them): `type RetryPolicy(maxAttempts: i32, initialMillis: i64, multiplier: f64, maxMillis: i64)`, `nextDelay(policy, attempt) -> ?i64` — the pause that follows attempt `attempt` (the first is 1), `initialMillis × multiplier^(attempt − 1)` rounded down and never above `maxMillis`, `null` past `maxAttempts`, below 1, or for a policy that is not usable (`RetryPolicy(3, 100, 2.0, 1000)` answers `100`, `200`, `400`, `null`) — and `retry(policy, work: fn() -> @Task<@Result<T, E>>) -> @Task<@Result<T, E>>`: `work` is run until it answers `Ok`, at most `maxAttempts` times, pausing `nextDelay(policy, n)` after failed attempt `n`; when every attempt fails the task fails with the LAST `Error`. No jitter, no `retry` over a plain `@Task`, no field that means "for ever" (decision 67): a policy is usable only with `maxAttempts` ≥ 1, both delays ≥ 0, `maxMillis` ≤ 2147483647 (the longest timer both targets arm) and `multiplier` ≥ 1.0, and `retry` over one that is not is fatal on both targets (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like `race([])`. The growth is one IEEE multiplication per attempt, in a loop that stops at the ceiling — the same operations in the same order on both targets, where a host `pow` would not promise the same last bit. A consumer builds the policy from a LEAF import (`import {async.RetryPolicy} from "std"`): `async.RetryPolicy(…)` through the module namespace is refused (`this "std" module has no such public function`), and `nextDelay(…).unwrapOr(0)` does not type-check (a literal does not widen to `i64` there) — read it with `!= null`. Private cells `millisAsFloat` / `wholeMillis` (their Node forms take and answer decision 319's canonical form: `Number` reads an `initialMillis` past 2^53 − 1, a whole number past it answers a `BigInt`; `delay`'s `i32` is the pause's `toI32()`) and the test cells `newCounter` / `countUp` / `countOf` / `panicOf` |
| `failure` | The failure records and the one way to contain a crash (decisions 431, 489, 490, 492, 494). `HostErrorName { Error, Throw, Exit }`, `HostError(message, kind, name, detail)` — what a `result: true` binding answers on the `Error` side (the backends build it) — and `Failure(message, kind)`. `attempt<T>(f: fn() -> T) -> @Result<T, Failure>`: `Ok` of `f`'s value, or `Error(Failure)` for a raise it caught; `attemptTask<T>(f: fn() -> @Task<T>) -> @Task<@Result<T, Failure>>`: the task `f` answers, awaited — a failing task `f` answers (432) is not a crash, its `@Result` is the value. Kinds: `panic` for the program's own aborts — `@panic` / `@todo` (and `x!`), a failed `assert`, an integer overflow or division by zero — its message the text the program wrote (decision 527: an `assert`'s is `assertion failed: <condition>[: <message>] at <file>:<line>:<col>`, a division by zero's `integer division by zero: <op> on <type> at <file>:<line>:<col>`, the same on every target); `host` for a raise of a host binding without `result: true` — on commonJS a binding declared outside std is a function of its module whose call runs through `__bp_host_mark`, which marks its raise `__bp_host` (decision 546), its message the host's text (JS `message` else `String(e)`); on erlang and beam only a binding declared outside std (a library's or the program's) has its calls wrapped to mark its raise `{bp_host, Text}` (decision 546, `codegen/beam/erl_template.zig` `hostMark`), `Text` the reason by `~tp`; `crash` for a raise nothing marked (on commonJS any raise that is not a panic and not marked — a method called on a mistyped value, a std binding's raise; on erlang and beam a `case` no arm matches, a std binding's raise — 495 audits each std binding), its message the reason by `~tp` on erlang and beam, the `Error`'s `message` else `String(e)` on commonJS. Both are bodyless with Node and Erlang templates (beam compiles the Erlang one): the Node forms read the backend's `__bp_panic` mark (`codegen/js/AGENTS.md` § Aborts are marked) or a test `assert`'s `__bp_assert_loc`, the Erlang forms the reasons `{panic, M}` / `{todo, M}` / `{integer_overflow, M}` / `{bp_assert, Msg, Where, M}`, and build `{'std@failure@@Failure', M, Kind}` (the regex `Match` precedent); `attemptTask`'s Node form answers a failing task (`__bp_fails`, rejected with the `Failure` under `__bp_failure`). On wasm (decision 518) both bind `fn:` private bodies, `attemptOnWasm` / `attemptTaskOnWasm`, over the private `caught<T>(f) -> @Result<T, string>` — `#[.Wasm(wasi: .Attempt, needs: [.Exceptions])]`, the thunk inside a `try_table` catching the program's aborts (`codegen/wat/AGENTS.md` § Exceptions and needs); its Node and Erlang forms exist because the bodies over it compile on every target, and nothing there calls it. Not yet (B-07-b): on wasm only `@panic` / `@todo` are raised as exceptions — an `assert`, an overflow, a division by zero and a host fault trap, which no `attempt` catches, and `attemptTask` contains only what the thunk raises before its task's first `await` — `conformance/modules/decisions-taken/failure_kinds_exact_every_target-527/cells/std_failure_attempt`, `std_failure_attempt_task`, `std_failure_attempt_host`, `std_failure_attempt_crash` |
| `types` | `type Type { … }`, a namespace type (decisions 307, 308, 329): `Type.keys(T)`, `Type.partial(T)`, `Type.required(T)`, `Type.merge(A, B)`, `Type.pick(T, ..fields)`, `Type.omit(T, ..fields)` (the fields a variadic `comptime ..fields: Type.Field<T>[]`, decision 267) — static compile-time functions answering a new record type, bound by a module-level `val`; declared bodyless (`comptime/derived_types.zig` answers `partial`, `required`, `pick`, `omit` and `merge` with the record declaration a module-level `val` names, `keys` with the alias of `Type.Field<T>` it names) — and the associated type `Type.Field<T>`, a run-time value too (`K.of(text)`, `K.all()`, `case` over its fields) |
| `context` | Decisions 354, 378, 379, 722, 723: `pub type Context<T>(contextValue: T)` — a context, its identity its value's type; `createContext<T>(value) -> Context<T>` declares `T`'s default as a module-level `val`'s initializer (one per type in the program) and makes a context to provide inside a component; `provide<T>(ctx) -> @Component<void>` (the context alone), `context<T>(ctx: Context<T>) -> @Component<T>` (a context value the module declares or imports, never a bare type — `context-read-by-type`) and `inject(comptime t: anytype)` (416: the record `T` built from its fields' contexts; `createContext(value, Behavior)` keys a context by a behavior), `use`d only and lowered by the compiler (`comptime/context_lower.zig`), so their bodies only panic. Decision 388: a `@Component<R>` at run time is a lambda over `RenderScope` — opaque, `pub type RenderScope(frames: unknown)` made only by `RenderScope.root()` (the checker refuses its construction, `render-scope-construction`) — and `c.run(scope)` (`primitives.bp`'s `Component.run`) answers `@Task<Rendered<R>>`, `pub type Rendered<R>(value: R, scope: RenderScope)`: the body's result and its children's scope. `Frame` / `push(scope, key, value)` / `find(scope, key, fallback)` / `rendered(value, scope)` / `valueOf(r)` / `root()` are what the scope lowering calls (imported under `bpScope…__` names), `find` answering the read's context value with no provider of its type above. On wasm the lowering is refused (`language-gaps.md`) |

`Type.partial`, `Type.required`, `Type.pick`, `Type.omit` and `Type.merge`
(`types.bp`) are bodyless: the compiler answers each call
(`comptime/derived_types.zig`, decision 307) with the record declaration it
derives. The bare names (`mergeRecords`, `partial`, `omit`, `pick`) mean
nothing to the compiler — a declaration of that name is the module's own
(`random.pick`). `mapFields` does not exist.

Adding an importable module:
1. Create `libs/std/src/<name>.bp` — or `io/<name>.bp` when it talks to the
   world outside the process, `testing/<name>.bp` when it is harness.
2. Add `pub mod <name>;` to `libs/std/src/root.bp` (or `io/mod.bp`,
   `testing/mod.bp`).

No `build.zig`, `prelude.zig`, or `compiler-core` edit — `build.zig`
(`stdPkgFilesFromRoot`) reads `root.bp` and generates the `std_pkg` registry.

A nested module follows the module-tree rule of any package: `pub mod <dir>;`
in `root.bp` resolves to `<dir>.bp` or the folder index `<dir>/mod.bp` —
exactly one, the build panics on both or neither — and a folder index's own
`pub mod <name>;` lines embed `<dir>/<name>.bp` under the registry key
`std/<dir>/<name>`, depth-first (decision 106's `io/` and `testing/`). A
consumer reaches it by path: `import {<dir>.<name>} from "std"` (the
namespace), `import {<dir>: {<name>: {f}}} from "std"` (a leaf), or
`import {<dir>} from "std"` and `<dir>.<name>.f()` — the folder index holds
`mod` lines only and is not a module of the registry, so the folder leaf is a
namespace of its submodules (decision 110), rewritten by
`comptime/std_namespace.zig` into the first form for each module reached.

Two things a module's own inline tests cannot see, because they only show when
a CONSUMER imports it (measured by front 01 from a scratch package importing
`{escape, encoding, hash, net, time, random, regex, path, fs}` on the flat tree
— today's `{escape, encoding, hash, regex, path, io: {net, clock, random, fs}}` —, green on both
targets):

- On erlang a std module compiled as a dependency loses the default-fn shim of
  a one-argument `String.slice(start)` — `string_slice/2 undefined`, and the
  whole module refuses to load. Write the end explicitly:
  `s.slice(start, s.length)`.
- On commonJS `import {io.process} from "std"` binds a local `process` that
  shadows Node's global, so the generated test runner's `process.argv` throws
  and nothing runs — a codegen defect (an imported module named after a host
  global is not renamed), not a std rule; until it is fixed, a consumer's test
  module does not import `process`.

A CALL of a std function that reaches a host-bound declaration with no
matching `@External` for the target — the function itself, or one its body
reaches through its module's own functions — raises `STD-001` at the call,
naming both; the import is never refused (decision 518 (4),
`comptime/tests/std_target_gating.zig`, `conformance/modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_unsupported_refused_at_the_call`).

`primitives.bp` declares `WasmNeed { Exceptions, Http }`, the closed enum of
`.Wasm`'s `needs:` (decision 518): a binding that needs a host feature
names it (`failure.caught`'s `needs: [.Exceptions]`), and the compiler hands the
host the matching flags.

## `#[.<Target>(…)(...)]` — host bindings

`#[.<Target>(…)(...)]` plus the signature define how a declaration lowers.
Targets come from `type Target { Node, Typescript, Erlang, Beam, Wasm }` in
`primitives.bp`, and `External` stays a second declaration rather than
`Target` itself: `Target` is a value a program holds and compares, `External.<T>`
an annotation whose every variant carries a payload the compiler reads (front
20 F9, the sentence in `primitives.bp`). Several annotations combine in one
`#[…]`, comma-separated.

- **A host function with an owner is a method of the owner.** One that
  operates on a value of one of the module's types is declared INSIDE that
  type with `declare fn`, `self` first, and called `value.m(…)` — `$0` is the
  receiver (`conformance/docs.md` § Host bindings; `io.net`'s sockets, `regex.Regex`).
  Owner-less ones — a constructor such as `listen`/`connect`/`compile`, or a
  function over primitives, `unknown` host terms or builtin types (`@Task`) —
  stay module functions, and so does a private test instrument, since a
  method is exported from its type's module. Two free functions that existed
  only because each type needed its own name (`tlsRecv` beside `recv`)
  collapse into one method name per type.
- **Module + symbol** — `#[@external(.Erlang("erlang", "abs"))]`: call
  `module:symbol(args)` with args in declaration order.
- **Single string** — `module` comes back empty from `externalFor` (`ast.zig`).
  On a behavior method it names the native method (`#[@external(.JavaScript("toReversed"))]`
  for `Array.reverse`, a call-site rename when it differs from the method name,
  never a prototype patch). The native method it names has to MATCH the
  signature: `Array.reverse` answers a reversed array and leaves the receiver
  alone on erlang and wasm, and named native `reverse`, which reverses in
  place, so commonJS alone also reversed the receiver — `toReversed` is the
  copying reader that answers what the signature says. On a `declare fn` it is a host expression
  (`#[@external(.JavaScript("process.cwd()"))]`) that commonJS renders verbatim at each
  call site, and the erlang backend renders the same way — the `:expr()()`
  lowering that used to keep `env`, `os` and `process` off erlang is gone
  (`botopink test --target erlang` in `libs/std`: `process.pid is positive`,
  `os.hostname is non-empty` and `env.write + env.read round-trips a value` all
  pass).
- **Relative module file** — `#[@external(.JavaScript("./file.mjs", "symbol"))]` is
  **not a supported form in `libs/std`**. On a behavior method both inference
  and the commonJS emitter skip it and the native JS method of the same name
  runs; on a `declare fn` it emits `require("./file.mjs")`, which throws unless
  the file is shipped next to the emitted module. Name the native method, write
  a template, or keep host code in a sidecar (below).
- **`inline`** — `#[@external(.Erlang("…", inline: true))]`
  opts the `(target, method)` pair out of the dispatch table so the emitter's
  hand-coded shape keeps emitting. Only that variant declares it, because
  only the erlang and beam emitters read it (both through `.Erlang`, `hasExternalInline` over the last
  argument); on `JavaScript` / `Wasm`, anywhere but last, or with a
  non-bool value it is refused at the annotation (front 20 F9, decision 67 —
  `comptime/infer.zig` `external_variants`, kept in step with the
  `pub type External` block by a drift test).
- **Template** — any `$` in the string switches to the shared renderer
  (`modules/compiler-core/src/comptime/primOpTemplate.zig`):

| Marker | Resolution |
|---|---|
| `$0` … `$N` | the N-th **declared parameter** — on a method `$0` is `self` (decision 5) |
| `$args` | every declared parameter, comma-separated (the receiver first on a method) |
| `$stringify(<inner>)` | going: decision 239 refuses it in every template, std included (the parser's refusal and the renderer's arm are `01-compiler`'s) — no std file writes it; a template that needs a value as text spells the host call out, as `Array.join`'s Erlang template does with `iolist_to_binary(io_lib:format("~p", [__E]))` |
| anything else | passthrough target syntax |

```bp
#[.JavaScript("""(process.env[$0] ?? null)"""),
  .Erlang("""(fun(__N) -> case os:getenv(binary_to_list(__N)) of false -> undefined; __V -> list_to_binary(__V) end end)($0)""")]
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
and `| 0` turned into `0` — commonJS answered `0` where erlang answered `-1`.
Arity branching
(`when(argc == N): "<template>"`) is also parsed (`ast.parseArityBranchArg`).

Templates are rendered by the commonJS, erlang and beam_asm backends; wat does
not use them. **`#[@external(.Wasm(…))]` is not a template** (decisions 238, 481): it
is one labelled cell — `op: "<wasm opcode>"` (the declared types must be the opcode's),
`fn: <a private bodied fn of the same module, same signature>`,
`wasi: .<Adapter>` (the list in `conformance/docs.md` § Host bindings) or std's own
`std: "<module>.<function>"` (std-wasm, decision 440) —, the arguments being
the declared parameters in order; a prefixed string (`"fn:…"`, `"op:…"`, `"wasi:…"`) is refused on every
target, anything else is refused at the annotation
on a wasm build. An algorithm with no wasm instruction stays in the library as
that private `fn` — the only std edit a wasm binding brings, never a public
one. The same private-fn binding, the labelled `body: <name>` (decisions 305, 610), binds a declaration on `JavaScript` and `Erlang`
(decision 263, `codegen/hostFnBinding.zig`): `math`'s transcendentals run
std's bodies on erlang and beam and `pow` is a bodied `fn` on every target, so
they answer the same bits on every target and OS. Bound today: `math` (every cell), `escape` (both cells), `hash` (every
cell: private bodies under `// ── the wasm bodies` at the end of `hash.bp` —
SHA-256/512, SHA-1, MD5, HMAC, PBKDF2, base64, the djb2 fold — in exact `f64`
arithmetic, a word stored as two 16-bit halves, the constants the standards'
hex read in place; `run/std_hash_{digests,macs,content}_on_every_target`) and
`io/random` (`float` `std: "random.float"` — decision 456, the host's entropy in a program, refused at comptime —, `seed` / `seededFloat`
`std: "random.seed"` / `std: "random.seededFloat"` — std-wasm's seeded stream, the
sidecar's Mulberry32, which also answers at comptime on every target and
refuses a draw before any seed there (decision 451) —, the rest `fn:` bodies at
the end of `io/random.bp`; `modules/decisions-taken/seeded_random_std_wasm-451/cells/std_random_on_every_target`,
`modules/decisions-taken/libraries_run_at_build_on_wasm-594/run/src/cases/comptime_random_seeded`, `modules/decisions-taken/seeded_random_std_wasm-451/refused/src/cases/comptime_random_unseeded`).
`Array.range` / `Array.repeat` build by doubling, a range of one being its
element, and wasm lowers them from their bodies (`modules/array/run/src/cases/array_range_and_repeat`); no
std module holds a module-level `var` (on erlang it lowers to `std@beam`,
which a std module does not import). `encoding`, `querystring` and `unicode`
build and run on wasm (their `fn:` bodies, decision 238; `unicode.normalize`
is plain botopink, decision 333 (A)). The other group-1 module, `json`, stays
refused on wasm until a decision binds its last cells: `json.parse` /
`json.stringify` (05w-j — every other `json` cell is bound; its
`parseFloat` test helper is inlined into its test, since `parseFloat` has no
wasm lowering and a top-level helper refused the module). Group 3 of decision 230 — `io/http`
(`fetch`), `async` (`gateHandle` and eleven more cells), `testing/mocks` (all
eight cells), `testing/asserts` (`canonical`) — is refused on wasm by a located
`std-unsupported-on-target`; whether that refusal is the design waits on the
maintainer (`97-a`, `97-b`, `97-c`, `110-a`).

## unicode — the generated normalization tables

`unicode.normalize` is std's botopink body on every target (decision 333 (A)):
decompose recursively (compatibility mappings too for NFKC / NFKD), put each
run of non-starters in canonical order (a stable sort by combining class),
then for NFC / NFKC recompose every unblocked pair whose primary composite is
not excluded; Hangul syllables decompose and compose by the algorithm
(Unicode §3.12). Its data is `src/unicode_tables.bp`, **generated, never
edited**: `combiningClass(cp)`, `canonicalDecomposition(cp)` and
`compatibilityDecomposition(cp)` (one level each — a tagged mapping only in the
second), `primaryComposite(first, second)` (0 for none) and `version()`. Each is
a `case` over the code point that dispatches to leaf functions of at most 64
arms — a single `case` of two thousand arms is past the beam assembler's limit
for one function — and the file is written at the formatter's canonical form.

- **The generator** — `tools/unicode-gen/main.zig`, built for the host and run by
  `zig build gen-unicode` (registered by one line of the root `build.zig`, which
  calls `tools/unicode-gen/build_step.zig`); nothing else of the build runs it:
  the generated file is committed and embedded like any std module. It reads
  `UnicodeData.txt`, `CompositionExclusions.txt`,
  `DerivedNormalizationProps.txt` and `SpecialCasing.txt`, vendored beside it,
  and refuses to write unless every vendored file matches its SHA-256 in
  `tools/unicode-gen/manifest.json` and the exclusions it derives (the listed
  ones, the singletons, the non-starter decompositions) are exactly
  `Full_Composition_Exclusion`. It writes a second file from the same data:
  std-wasm's `modules/std-wasm/src/case_tables.zig` — the simple case mappings
  (`UnicodeData.txt` fields 12–14) and the unconditional full ones
  (`SpecialCasing.txt`), as Zig `switch`es, which a `--target wasm` program's
  `toUpper` / `toLower` and the comptime's `string:uppercase` / `lowercase` /
  `titlecase` answer by (decision 443; `modules/std-wasm/AGENTS.md`).
- **The pinned version** — Unicode 17.0.0 (`manifest.json` `version`, `unicode_tables.version()`).
- **The conformance test** — `test/unicode_test.bp` reads the vendored
  `NormalizationTest.txt` (hashed by the same manifest) and checks every line of
  each of its six parts under the four forms, each part's line count pinned;
  `botopink test [--target erlang|beam] --filter NormalizationTest` reads
  `7 passed, 0 failed`. The file's other invariant (every code point not in part
  1 is its own normal form) is not walked: 1.1 million code points × 4 forms.
- **A Unicode bump** is one commit: replace the five `.txt` files with the new
  version's (`https://www.unicode.org/Public/<version>/ucd/`), write their
  SHA-256 and the version into `manifest.json`, run `zig build gen-unicode`,
  update the version and the per-part line counts `test/unicode_test.bp` pins,
  and run the conformance test on commonJS and erlang.
- **Where the tables live** — a flat sibling, `src/unicode_tables.bp`, declared
  `mod unicode_tables;` (private) in `root.bp` and imported by `unicode.bp` as
  `import {unicode_tables as tables};` (private in std's own tree; the embedded
  registry carries no visibility, so a consumer's `import {unicode_tables} from
  "std"` still resolves — front 97's compiler residual 11). The module tree resolves a `mod` only to
  `<name>.bp` or `<name>/mod.bp` beside the declaring file, so a
  `unicode/tables.bp` under the file module `unicode.bp` is unreachable
  (`decisions-pending.md` 97-s16-a).

## Tests

Inline `test "name" { … }` blocks live in the importable module files; the
`primitives.bp` interfaces are tested from `test/`, because a core file is
flattened into the global env and never compiled in test mode. From `libs/std`:

```bash
botopink test                      # commonJS (default) or --target erlang
botopink test --filter "dict"      # by name substring (the `collections` tests of `Dict`)
```

`botopink test` runs on commonJS, erlang, beam and wasm (a module's tests are a
unit of their own, decision 513). Each test's
stdout is captured under a `----- RUN LOG -----` fence; failures print
`FAIL <name> (<message>) at <file>:<line>` — see
[`../../modules/compiler-cli/AGENTS.md`](../../modules/compiler-cli/AGENTS.md)
§`botopink test` output format.

The snapshot engine (`testing.snapshots`, with its four `.snap` files) left std for the `snap`
library (`repository/snap`, decision 391): `import {assertAs} from "snap"`, and
`import {testing.snapshots} from "std"` is refused. What std keeps for it are the general
primitives it is written over — `@src()` / `SourceLocation`, `io.fs` (`mkdirRecursive` included),
`path`, `io.env` / `io.os`, and the `String` text methods below.

Decision 390 — std's values are verified by its inline literals (`assert … == "…"`,
`asserts.equals`, `asserts.throwsWith`), not by a `.snap`: the four `__snapshots__/`
path-rule files that pinned the engine's own file layout went with it to `snap` (391),
and std records no snapshot of its own.

`mocks`' ten inline tests are the eight of the retired `repository/onze/test/onze_test.bp`,
one for `anyString` (the old suite covered it from its example app, not its
test file), and one that pins `verify`'s failure message with the module's own `raisedText` cell
(`asserts.throwsWith`'s shape; a std module does not import the harness — an import of
`testing.asserts` links its host-only `canonical` and refuses every wasm program that reaches
`mocks`) —
`mocks.verify: <method> - expected exactly <n> matching call(s), got <m>` (Node appends
the recorded calls). They run on both targets — `botopink test [--target erlang] --filter
mocks` reads `10 passed, 0 failed`.

**A consumer writes `#[mocks.mock]`.** A `from "std"` namespace import
registers the module's decorators under `<handle>.<fn>` (`comptime/infer.zig`
`registerStdImportDecorators`), so `import {testing.mocks} from "std"` makes
`mock` the annotation `#[mocks.mock]` (an alias `as m`, `#[m.mock]`). It gives
the annotated `behavior` the associated type `<Name>.Mock` and the factory
`<Name>.mock()` (`decl.addType` / `decl.addMember`, decision 216), declared in
the module that hosts the behavior, so their bodies name the runtime through the
prefix of the annotation that fired them: bare here (`#[mock]`: `invoke`, `key`,
`newMock`), `mocks.invoke(…)` in a consumer. A leaf import of `mock` is
`std-decorator-leaf-import` — it would leave the generated code no handle — and a `#[mocks.<name>]` that names no
decorator of the module is `unknown-annotation` (conformance
`modules/std/cells/std_decorator_through_namespace`, `modules/std/cells/std_decorator_leaf_import`,
`modules/std/cells/std_decorator_unknown_through_handle`).

`async`'s twenty-nine inline tests run on both targets — `botopink test
[--target erlang] --filter "async: "` reads `29 passed, 0 failed`. Three of them are
WALL-CLOCK budgets (`allOf`/`settleOf` of three 60 ms tasks in under 120 ms, and
`timeout` of a 200 ms task under a 50 ms budget in under 150 ms): they are the
only assertions that can tell a concurrent combinator from a sequential map, so
they have to exist, and they are the flakiest cells in the file. Measured by
planting a sequential gather in each backend's `settleOf` cell in turn: the
serial node cell reds exactly the two commonJS elapsed cells and nothing else,
the serial erlang cell reds exactly the two erlang ones.

**No red cell.** `zig build test-libs` reads `std · commonJS: pass` and
`std · erlang: pass`, and nothing can list a red cell away (the known-red file
is deleted — `scripts/AGENTS.md` § test-libs.sh). The three rows this
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
#[.JavaScript("""require('./sidecars/random.mjs').seed($0)"""),
  .Erlang("""(fun(__S) -> rand:seed(exsplus, {__S, __S, __S}) end)($0)""")]
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

## Host failures — the audit (decisions 431, 486, 490, 495, 546)

A std binding fails in one of three ways, and each module says which:

1. **It can fail and says so.** The private cell writes `result: true` (490) and answers
   `@Result<T, HostError>`; the public function maps the `HostError` into the module's enum (486), the
   host's text in a `message` where the failure has one: `io.fs` (`FsError`, read from the host's own code —
   Node's message starts with `ENOENT`…, erlang's is `enoent`), `encoding` (`EncodingError`),
   `io.clock.parseIso8601` (`ClockError`), `io.http.fetchHost` (`fetch` maps it to an `HttpError`). A `Host(HostError)`
   variant appears only where a cell could fail in a way no variant names — none does today: each of these
   cells fails one way. `json.parse` / `stringify` / `unquote`, `regex.compile` and `io.process.run` answer the
   `HostError` itself, the cell public with `result: true`: a std-owned enum there (decision 486 names
   `JsonError`, `RegexError`, `ProcessError`) needs a public body over a cell wasm has no binding for, and wasm
   refuses a module for the first such body even when the program never calls it (the whole `std/json`, so
   `json.quote` stops importing; `import {io.process}`). It waits on the wasm backend refusing per reached call
   (a 164 row). No `.bp` or template catches by hand; a cell that must tell a host failure from data answers the
   data (`fs.walk`'s dangling links are a field of `Walked`, `glob`'s unreadable directories are an empty
   match), and one that validates before it decodes (`Bytes.toUtf8`: `buffer.isUtf8`; `hexBytesOf`;
   `stringToFloat`: `string:to_float/1`) raises nothing.
2. **It promises no raise.** Its inputs cannot make the host raise, so a raise is a defect of the audit (546) and
   reads as `crash`: `primitives` (the language's own aborts — overflow, `@panic` — are `panic`, not the host's),
   `math`, `collections`, `decimal`, `path`, `url`, `querystring`, `string_builder`, `escape`, `unicode`, `types`,
   `context`, `hash` (digests over valid arguments; `pbkdf2Sha256` refuses `iterations`/`length` below 1 by
   `@panic`), `encoding`'s encoders, `json.quote` and the botopink reader `decode` (an `Error` by data),
   `io.clock` (`nowMillis`, `monotonicMillis`, `formatIso8601`, `toCivil`, `offsetMinutes`, `sleep`),
   `io.env`, `io.os`, `io.random`, `io.process` (`exit`, `cwd`, `platform`, `pid`, `runShell`: a start failure is
   an empty output, not a raise), `io.fs.exists` and `io.fs.glob`, the `testing` helpers (`mocks`, `asserts`,
   `panicText` / `raisedText` / `panicOf`: all `attempt` / `attemptTask` over a body), `async`'s combinators
   (`delay`, `race`, `raceOf`, `spawnAll`: a crash of a task is re-raised by `erlang:raise/3`, kept, not
   converted; `raceOf([])` is a documented `error`). `io.fs`'s `rawGlob` swallows what a directory it cannot
   read raises (a documented empty match), and `raise`-free `rawReadOnly` / `memHandle`.
3. **It can raise on an input the caller must check, and is not converted.** Listed so the audit is complete,
   each an open question to the maintainer (decision 495 asks "`result: true` or promises no raise" and
   neither is honest):
   - `regex.matches`, `replace`, `replaceAll`, `splitOn`, `match`, `matchAll`, `captures`, `namedCaptures` —
     a malformed `pattern` makes `new RegExp` / `re:run` raise: validate with `compile` first.
   - `io.net` — `listen`, `connect`, `tlsListen`, `tlsConnect` and the methods of `Listener` / `Socket` /
     `TlsListener` / `TlsSocket` answer `@Result<T, string>` by converting the host's `{error, Reason}` by
     hand (no `try`, no `catch`) and refuse on commonJS; their typed error is `NetError` (decision 486 names
     no variants), not done here.
   - `io.process` `rawOnSignal` / `rawSpawn` / `rawKill` and `io.terminal`'s raw cells (144 B-27 step 6, decision 506):
     they classify the host's failure by hand into the `kind|message` text `ProcessError` / `TerminalError` read
     (`NotFound`, `PermissionDenied`, `NoSuchProcess`, `NotATerminal` …) and carry a `catch` in the template. They are
     not converted to `result: true`: the mapping from a `HostError`'s text to those variants is a design choice
     the decision does not fix (a question to the maintainer).
   - `erlang.bp` / `beam.bp` — the raw host surface, outside the criterion: a BIF's own raise is the BIF's.

The templates that keep a `try` / `catch` are not boundaries: `async`'s `spawnAll` / `raceOf` cells catch a task
process's exit only to re-raise it in the caller (`erlang:raise/3`, class and reason kept); `fs.rawGlob`'s
cells swallow an unreadable directory by rule (decision 177); `failure.attempt` / `attemptTask` and `caught` are
the boundary itself.

## Effect wrappers (the return is the effect)

There are no effect annotations (decision 118). `@Result<T, E>`, `@Task<T>`,
`@Component<T>` (with the owner marker `@Renderable`), `@Iterator<T>` and
`@Stream<T>` over `YieldStep<T>` — the chain `Component ⊃ Task`, `Stream ⊃ Task`
that `comptime/effect_chain.zig` restates and drift-tests — and default generic
parameters are documented in the effect-wrapper blocks of `src/primitives.bp`.
`@Future`, `@Generator`, `@ResultGenerator`, `@FutureGenerator` and `@Use` are
gone, not aliased (decision 127).

## Conventions

- **`Self<…>` in a generic declaration** (decision 8 §1.2, enforced by the checker —
  `comptime/AGENTS.md` § Generic types carry their arguments): `behavior Array<T>` writes
  `self: Self<T>`, `type Dict<K, V>` writes `self: Self<K, V>`; a declaration without type
  parameters writes `Self`. A written generic type carries all its arguments (`Dict<K, V>`,
  never `Dict`). A binding born as `[]` carries its element type (`var out: T[] = [];`) —
  the checker warns on the bare form (decision 8 §1.4).

- Stable, additive signatures — renames force snapshot churn.
- `.d.bp` files stay declarative (no bodies).
- **Every `.bp` and `.d.bp` of `libs/std` is at the formatter's canonical form**,
  and the commit hook keeps it there (decision 524: it formats each staged file;
  an edit here is written formatted with `botopink format <file>`). The
  `std_package_*` codegen snapshots and two LSP snapshots
  (`definition_std_module_member`, `completion_array_methods`) quote this source
  verbatim, so a change of layout in `src/collections.bp` or in a signature of
  `src/primitives.bp` re-records them in the same commit. `primitives.bp` parses whole since front 20: an unannotated
  `pub declare fn` takes the full signature (`field<T, F>(…) -> F`,
  `typeInfo<T>(comptime _: anytype) -> TypeInfo<T>`, `print(..values: unknown[])`), a behavior `val`
  member any type (`val fields: Field[];`). The compiler's external scanners read
  it (`scanDeclareFnExternal`) and stop on a parse failure, and
  `codegen/tests/builtins.zig` pins that it parses — so a form the parser refuses
  here reds a test, not a build.
- No Zig in `libs/std/` — loader/glue changes belong in `build.zig` / `compiler-core`. The one
  exception is `tools/unicode-gen/`, the generator decision 333 (A) places beside the package
  (§ unicode): a build tool, never embedded, never imported by the compiler.
- `get`/`set`/`test`/`from`/`assert` are keywords (`new`, `delegate` and `const` are identifiers since 06 N27) — pick other names (`empty`/`at`/`insert`, `matches`, `src`, `asserts`).
- Array equality in assertions uses `.join(...)` (`==` on arrays is reference equality in JS) — or `asserts.deepEquals`, which renders both sides on the same host.
- An `if (a < b || c > d)` condition does not parse today (the condition grammar stops at `||`); bind it to a `val` first (`asserts.between` does). A parser gap, not a std one.
- **Measured 2026-09-20, consumer side** (`import {testing: {asserts, snapshots}} from "std"` from a user package, when `snapshots` was std's under `botopink test`): a primitive interface `default fn` (`Bool.negate`, `Array.contains`, `Array.isEmpty`, …) is emitted verbatim (`condition.negate is not a function`) when a std module is compiled as a consumer's **embedded** import — the project compile of `libs/std` itself lowers it. `asserts`/`snapshots` therefore use only host-backed primitives (`== false`, `indexOf`, `.length`, `split`/`join`/`slice`/`indexOf`/`startsWith`/`endsWith`/`contains` on strings). A std module written with a default fn passes its own tests and breaks its consumers. Core gap (commonJS cross-module emission of embedded std modules).
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
- **Three parser/emitter shapes measured 2026-09-21 writing `async.bp`, each with
  a one-line workaround, none of them owned by std.**
  1. A `declare fn` whose parameter list is wrapped and closed with a TRAILING
     COMMA after a parameter whose type ends in a fn type does not parse —
     `pub declare fn f<T>(` / `t: fn() -> T,` / `) -> T;` reds `this token cannot
     appear here`, and with a generic return type it reds
     `generic-arg-skip-forbidden` instead. The same signature on ONE line, or
     wrapped without the trailing comma, compiles. Re-measured 2026-10-01: it no
     longer reproduces — the wrapped form with the trailing comma, which is what
     `botopink format` writes, parses with a plain and with a generic return
     type, and `src/async.bp` is formatted like the rest of `libs/std` (its
     DO-NOT-FORMAT banner is gone).
  2. (fixed by front 24, which made `@Task<@Result<T, E>>` parameters common)
     `Array<Array<T>>` — any doubled `>>` — as a parameter followed by another
     parameter used to red `generic-arg-skip-forbidden`: the inner list's `>>`
     left the outer close pending and the generic-argument loop read the
     parameter separator as its own. `parser/types.zig` now stops at a pending
     `>`.
  3. A `$N` marker called as a function in a Node template — `… => $0()` — emits
     `() => {…}()` when the argument is a closure literal, which is a JS
     `SyntaxError` (an arrow IIFE needs parentheses). Write `($0)()`.
- A `val` bound to a generic call is not generalised: the function it holds takes the argument
  types its first use fixed (`Function.constant`'s answer is `fn(unknown) -> A`, decision 668, so
  it takes any).
- Test an optional parameter with `!= null`, not truthiness: on commonJS
  `if (end)` is false for `0`.
- Pick a host call by semantics, not by name — `string:suffix/2` and
  `math:round/1` do not exist in OTP, `string:str/2` rejects binaries,
  `string:trim/1` strips both ends. Every host binding carries a test that
  asserts the value.

## One unit for every string index (decisions 169, 320)

`indexOf` and `lastIndexOf` answer an index `at`, `slice` and `length` can take, and the unit is the
codepoint on every target (decision 320): `"e\u{301}".length` is 2 and `.at(1)` is `"\u{301}"`,
`"👍".length` is 1. The Erlang templates of `length`, `at`, `indexOf`, `lastIndexOf` and the slice
helpers `stringSlice0` / `stringSlice1` work on the decoded codepoint list
(`unicode:characters_to_list/1`, re-encoded with `unicode:characters_to_binary/1`) — never
`string:length/1` / `string:slice/2,3`, which count grapheme clusters; the slice helpers normalise a
negative or out-of-range bound as the Node forms do. The two searches match over the bytes and
answer the codepoints of the text before the match. `test/primitives_test.bp` pins the BMP case with
a string built from code points (`a`, U+00E9, `b`, U+20AC, `c`, …); `conformance`
`modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_index_of_codepoints` pins combining marks and astral characters on the four targets
(commonJS's Node cells are `04-js` step 10's).
`String.charCodeAt` still indexes codepoints (`unicode:characters_to_list`) — the erlang front's.
The template is rendered by the erlang and beam backends; wasm's own `indexOf` is untouched.

## String numerals — `parseInt` / `parseFloat` (1.0.11-beta front 97)

`"42".parseInt() -> @Result<i64, string>` and `"1e3".parseFloat() -> @Result<f64, string>` are
`default fn`s of `behavior String`: the method decides in botopink which strings are numerals, so
every target refuses the same inputs with the same text, and a host cell only converts a string the
method has accepted.

| | accepted — the WHOLE string | `Error` (the text names the input) |
|---|---|---|
| `parseInt` | an optional `+` / `-`, then digits `0`–`9` (`"-0"` is `0`, `"007"` is `7`) | anything else — `""`, `"4 2"`, `"42x"`, `"0x2A"`, `"4.2"`, `"1e3"`, `"-"`: `parseInt: "<input>" is not an integer` · a numeral past the `i64` range, −2^63 … 2^63 − 1: `parseInt: "<input>" is out of range` |
| `parseFloat` | an optional sign, digits, an optional `.` with digits on both sides, an optional `e` / `E` exponent with an optional sign (`"1e3"`, `"+2.50E-2"`, `"42"`) | anything else — `".5"`, `"1."`, `"1e"`, `"NaN"`, `"Infinity"`, `"0x10"`, `" 1"`, `""`: `parseFloat: "<input>" is not a number` · an overflow: `parseFloat: "<input>" overflows f64`. An underflow is `0.0` |

- **The integer range is `i64`'s, exact on every target** (decision 176 as amended by 319). The
  Node cell reads the digits as a `BigInt` — never `Number`, under which `"9007199254740993"` is
  `9007199254740992` — and answers 319's canonical form: a `number` within ±(2^53 − 1), a `BigInt`
  beyond; `binary_to_integer/1` is exact at any size, and the erlang cell bounds it at the type's
  ends (written `1 bsl 63`: beam's template reader takes no literal past 64 bits).
  `conformance` `modules/decisions-taken/i64_is_64_bit_everywhere-319/run/src/cases/string_parse_int_i64_range` pins both ends on commonJS, erlang and beam.
- **`parseFloat` is the host's correctly rounded conversion** (`Number` / `binary_to_float/1`) of the
  numeral rewritten as `<digits>.<digits>e<exponent>` — the one form `binary_to_float/1` reads (it
  refuses `1e3` and `1.`). It answers `json.decode`'s `f64` bit for bit: `json.bp`'s test
  "json.decode and string.parseFloat answer the same f64 for a numeral" runs both over decision 142's
  boundary list (`5e-324`, `1.7976931348623157e308`, the halfway points, `9007199254740993`, …).
  `"-0".parseFloat()` is `-0.0`, which `==` tells from `0.0` on erlang (`=:=`) and not on commonJS.
- **The cells** are free `declare fn`s beside the slice helpers: `stringIsDigits(s)`,
  `stringToInteger(numeral)` and `stringToFloat(text, whole, fraction, exponent)` — the last two
  build the `@Result`. A refused numeral is `Error(…)` written in the body (decision 668 took away
  the cell that built it, `stringNumeralRefused<T>`, whose `T` no parameter bound).
- **The bodies call a method on `self` only** — `self.startsWith`, `self.indexOf` — and reach
  everything else through those cells and the slice helpers. Three emitter gaps met writing them,
  each worked around here, none std's:
  1. commonJS emitted `Ok(x)` / `Error(e)` of a `default fn` of this file as written
     (`ReferenceError: Ok is not defined` at the first call) — the `Ok` side is still built by a
     cell. `Error(…)` written in `parseInt` / `parseFloat` answers on every target
     (`conformance` `modules/decisions-taken/i64_is_64_bit_everywhere-319/run/src/cases/string_parse_int_i64_range`, `modules/string/run/src/cases/string_parse_float_every_target`).
     Reproduction: `return Ok(1);` in a new `default fn` of `behavior String`, called from a
     scratch project.
  2. commonJS emits `self.length()` of such a body as written (`self.length is not a function`),
     and erlang emits `opt.unwrapOr(d)` on an optional as a call to an undefined `unwrapOr/2`
     (`erlc` refuses the module) — the body cuts with open-ended `stringSlice0` and never reads
     `split(…).at(i)`.
  3. erlang lowers a method called on a LOCAL of such a body (`exponent.startsWith("+")`) through a
     lookup that another module's text can change: with `test/primitives_test.bp` grown by three
     tests, the second of two calls on one line came out as the bare `startsWith(Exponent, <<"+">>)`
     beside `'__bp_prim_startsWith'(Exponent, <<"-">>)`, and `erlc` refused the test module
     (`function startsWith/2 undefined`). A call on `self` lowers from the receiver's own behavior
     and is not exposed. Reproduction: the `parseFloat` body of this file at the commit that added
     it, with the three "one unit for every string index" tests appended to the test file.
- Runs on commonJS, erlang and beam (the Erlang templates). On wasm a call traps (`unreachable`),
  as `"a b".words()` and every other template-only `String` method does — the wasm front's.
- Both are prototype patches on commonJS (`String.prototype.parseInt = …`), so the nine
  `snapshots/codegen/commonJS/*` snapshots that print the `String` prelude carry the two
  bodies.
- Tests: `test/primitives_test.bp` (six tests — the accepted forms, every refusal's text, the range
  and the rounding boundaries) and the `json.bp` agreement test.

## Text methods for snapshots — `normalizeNewlines`, `trimTrailingNewlines`, `firstDifferingLine` (decisions 391, 402)

Three generic `String` methods, host templates on both targets (not `default fn`s: a `default fn` of
a std module breaks its consumers on commonJS, § above), the helpers the snapshot engine kept
privately before it left std:

| | answers |
|---|---|
| `s.normalizeNewlines()` | `\r\n` -> `\n`; a lone `\r` stays |
| `s.trimTrailingNewlines()` | `s` without its trailing `\n` characters — newlines only, never spaces or tabs (`trimEnd` takes all whitespace) |
| `a.firstDifferingLine(b)` | the 1-based number of the first line (split on `\n`) where the two texts differ; a text that is a prefix of the other in whole lines differs at the line after its last; `0` when they are equal |

Tests: `test/primitives_test.bp` (three). The nine `snapshots/codegen/commonJS/*`
snapshots that print the `String` prelude carry the three templates.

## Integers past 2^53 and the conversions (decision 319)

An `i64` / `u64` holds its whole range on every target; commonJS holds a value within ±(2^53 − 1)
as a `number` and one beyond as a `BigInt` (`modules/compiler-core/src/codegen/js/AGENTS.md` § 64-bit integers). The numeric tower's
methods answer alike on both sides of that edge:

- **`min`, `max`, `abs`, `isEven`, `isOdd`, `clamp`.** The emitter patches every numeric-tower
  method on `BigInt.prototype` as well as `Number.prototype` (`commonJS.zig` `prototypeAssign`), and
  each Node form here takes either kind: `min` / `max` / `abs` are written out with `<` (exact across
  the kinds) and answer an operand as it came — with `Math.*`'s answer on every pair of numbers
  (`NaN`, `-0`), and never calling `Math.min(` (a form that names `.min(` fails the guard
  "no prelude template calls the method it patches") — and `isEven` / `isOdd` take `% 2n` on a
  `BigInt`. `Float`'s `abs` carries the same form as `Signed`'s, since both patch
  `Number.prototype.abs`. `clamp` is the `default fn` over
  `max` / `min`. `conformance` `modules/decisions-taken/i64_is_64_bit_everywhere-319/cells/i64_number_methods_past_js_safe`.
- **The conversions** `toI32()`, `toI64()`, `toU32()`, `toU64()` and `toF64()` are `Integer`'s, so
  every integer width has the five. Each answers the value when the target type holds it exactly and
  otherwise aborts naming the value and the type — `toI32: 2147483648 does not fit i32`,
  `toF64: 9007199254740993 has no exact f64` — never a wrap, a saturation or a rounding. The erlang
  forms raise `{integer_overflow, What}` as an overflowing operator does; the Node forms throw
  `integer overflow: <What>` and answer the canonical form. `modules/decisions-taken/i64_is_64_bit_everywhere-319/run/src/cases/integer_conversions_exact`,
  `modules/decisions-taken/i64_is_64_bit_everywhere-319/cells/integer_conversion_to_i32_aborts`, `modules/decisions-taken/i64_is_64_bit_everywhere-319/cells/integer_conversion_to_f64_inexact_aborts`.
- **wasm** lowers a primitive method from its own table (`wat.zig`), whose integer rows are `i32`'s:
  a method called on an `i64` is refused there (`would narrow this i64 value to an i32 slot`), and the
  five conversions have no row (`has no lowering for the int method toI32/0`). The cells pin both
  refusals by `.wasm.expect` — rows of `01-compiler/05-wasm`.
- **std's Node templates over an `i64`** take and answer the canonical form: `io/clock`'s readings
  (`Date.now`, `Math.floor(performance.now())`, `Date.parse`) are `number`s within the range by
  construction, `wide` and `largestExactMillis` are botopink (`toI64()`, a literal), `io/fs`'s `stat`
  reads `bigint: true`, `async`'s `millisAsFloat` / `wholeMillis` convert either kind. `formatIso8601`,
  `toCivil` and `offsetMinutes` check RFC 3339's domain (decision 497), −62167219200000 …
  253402300799999 (0000-01-01T00:00:00Z … 9999-12-31T23:59:59.999Z), in botopink before the host
  form is reached, and abort past it naming the value (`clock.toCivil: <v> is past RFC 3339's range, -62167219200000 to 253402300799999`; ASCII, so
  erlang prints it as text), on every target: `modules/decisions-taken/clock_rfc3339_domain-497/cells/clock_rfc3339_domain` and the three
  `modules/clock_*_past_rfc3339_aborts`.
- `abs` of the type's minimum (`-2^63`, `-2^31`) answers `2^63` / `2^31`, a value outside the type,
  on commonJS, erlang and beam alike. Decision 496 makes it abort as unary `-` does (`integer
  overflow: abs on i64`), `abs` declared per width on `I32` and `I64` — not built: commonJS patches one
  `abs` on `Number.prototype` for every width (and `Float`), so a per-width bound needs a dispatch by
  the receiver's static type there, and erlang's primitive dispatch starts every integer at `Signed`.

## `bigint` — `behavior BigInt` (decision 332)

`bigint`'s surface is `primitives.bp`'s `behavior BigInt`, outside the numeric tower (a `bigint`
mixes with no other number): `toString()`, `toI64()` (aborts past −2^63 … 2^63 − 1, `toI64: <v> does
not fit i64`), `toF64()` (aborts unless exact, `toF64: <v> has no exact f64`), and two associated host
primitives of decision 262's form, written through the type's own name — `bigint.of(n: i64)` and
`bigint.parse(text)` (`@Result<bigint, string>`: an optional sign and digits of any length, else
`bigint.parse: "<text>" is not an integer`). The checker renames the receiver to `BigInt` for the
backends. commonJS patches the methods on `BigInt.prototype`, which the tower's patch writes too (an
`i64` past 2^53 is a `BigInt`): `BigInt.toI64`'s and `Integer.toI64`'s Node forms are one text, which
answers 319's canonical form (a `number` within ±(2^53 − 1)), and the two `toF64` forms are one text,
so the two patches are one function whichever runs last. wasm lowers the five itself (`wat.zig`, the
`bigint` helper group). `conformance/docs.md` § Numbers.

## `behavior Index` / `behavior Slice` (decision 63, amended)

`primitives.bp` declares both, ambient like `Display` and for the same reason: an index expression
has **no typing rule of its own** — `xs[0]` IS `xs.at(0)`, `d["k"]` IS `d.at("k")`, `xs[0..2]` IS
`xs.slice(0, 2)` and `xs[1..]` IS `xs.slice(1, null)` — so the syntax has to find the method without
the author having imported anything. `slice` takes two arguments rather than a range because there
is no `Range` type: `start..end` is an AST node, not a value.

`libs/std` answers them three times, in two different spellings, and the difference is a grammar
limit rather than a choice:

| type | behaviors | how it is written |
|---|---|---|
| `Dict<K, V>` (`collections.bp`) | `Index<K, V>` | `pub type Dict<K, V>(…) implement Index<K, V>` — the real clause; `lookup` was renamed `at` |
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

`primitives.bp` declares it, so a type writes `implement Display` with **no import** — `@print` has
to find a value's `display()` without the author having asked for it, which is the same reason every
other builtin behavior is ambient rather than a `pub mod`. One declaration, read by the §7 step of
all four backend fronts.

**`Dict<K, V>` implements it** (decision 8 §7, `00 · 01-checker` step 11): `Dict("a": 1, "b": 2)` — the
pairs in order, a string key or value quoted (`shown`, which asks `x is string` of the generic
value), anything else as it interpolates. It waited for `is` to have a run-time lowering on erlang;
measured on commonJS and erlang (`dict.bp`'s own test). wasm prints a `Dict` as a heap address and
traps in `display` — 05-wasm's rows.
