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
│   ├── primitives_test.bp   ← tests of the `primitives.bp` interfaces, `String.parseInt` / `parseFloat` included (green on commonJS + erlang)
│   └── primitives_gaps_test.bp ← primitive tests that hit a compiler gap, each gap named with its owning front
└── src/
    ├── root.bp              ← module-tree root: seventeen `pub mod` lines — the fifteen root modules, `pub mod io;`, `pub mod testing;` (decision 106)
    │                        — core files flattened into the global type env (`std_core_files` in build.zig):
    ├── primitives.bp        ← primitive behavior registry (Number/Integer/Signed/Float, I32…F64, Bool, String, Function, Pair, Array); no tests (see `test/`). `Array.lastIndexOf` is a `default fn` over `reverse` + `indexOf` (beam's path) with an erlang and a node cell; wasm lowers it to `$__arr_last_index_of_*`. Its slice helpers are free `declare fn`s (`stringSlice0(s, start)` — no `self`: `self-param-outside-type`), and their Node templates read a missing start as 0, because commonJS's `slice` patch is global. `String.parseInt()` / `String.parseFloat()` (1.0.11-beta front 97) are `default fn`s over four free cells — see *String numerals* below
    ├── builtins.d.bp        ← builtin surface: print, @Result/@Task/@Component/@Iterator/@Stream (`YieldStep`)…, `Display` (decision 8 §7), `Index`/`Slice` (decision 63, amended), `Target`/`External`/`Host` annotations, std.syntax (`Expr`, `ExprContext`, `CustomNode`, …), `@Decl` reflection, effect-wrapper rules
    ├── builtins_fns.d.bp    ← builtin fns with literal defaults (`todo`, `panic`)
    │                        — the PURE root: same input, same output; imports nothing from `io/` (`std-root-imports-io`)
    ├── collections.bp       ← `Dict`, `Set`, `Queue`, `Order` (was `dict`, `sets`, `queue`, `order`)
    ├── math.bp  path.bp  url.bp  querystring.bp  json.bp  regex.bp  unicode.bp  string_builder.bp
    ├── encoding.bp          ← base64 (was `base64`), hex, percent, the form codec
    ├── hash.bp              ← hex digests (was `crypto`), the base64url/HMAC digests, content hashes (was `content_hash`)
    ├── escape.bp  async.bp
    ├── erlang.bp  beam.bp   ← the target's surface — outside the criterion
    ├── io/                  ← talks to the world outside the process; may import from the root
    │   ├── mod.bp           ← `pub mod fs; http; net; clock; random; os; env; process;` (eight lines)
    │   ├── fs.bp  http.bp  net.bp
    │   ├── clock.bp         ← was `time`
    │   ├── random.bp        ← was `random` + `crypto.randomBytes`
    │   └── os.bp  env.bp  process.bp
    ├── testing/             ← the harness (`botopink test` only); may import from `io/` and the root
    │   ├── mod.bp           ← `pub mod asserts; snapshots; mocks;`
    │   ├── asserts.bp  snapshots.bp  mocks.bp
    │   └── __snapshots__/<suite>/<slug>.snap  ← recorded by `snapshots` from its inline tests (decision 72); a `.snap.new` beside one is a candidate a person reviews and renames
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

| Before (flat, until front 23) | After |
|---|---|
| `dict`, `sets`, `queue`, `order` | `collections` (`Dict`, `Set`, `Queue`, `Order`; `dict.empty()` → `Dict.empty()`, `sets.fromList(xs)` → `Set.fromList(xs)`, …) |
| `crypto` (the digests), `content_hash` | `hash` |
| `crypto.randomBytes`, `random` | `io.random` |
| `base64` (`encode`, `decode`, `encodeUrlSafe`, `decodeUrlSafe`) | `encoding` (`base64Encode`, `base64Decode` — `@Result`, `base64UrlEncode`, `base64UrlDecode` — `@Result`) |
| `time` | `io.clock` |
| `fs`, `http`, `net`, `os`, `env`, `process` | `io.fs`, `io.http`, `io.net`, `io.os`, `io.env`, `io.process` |
| `asserts`, `snapshots`, `mocks` | `testing.asserts`, `testing.snapshots`, `testing.mocks` |

| Module | Surface |
|---|---|
| `collections` | `type Dict<K, V>` (association list, `implement Index<K, V>`): `Dict.empty()`, `Dict.ofEntries(entries: Array<#(K, V)>)` (decision 174 — inserted in order, so a repeated key keeps its last value at the place of that last entry, as a chain of `insert` does), `at`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` · `type Set<T>`: `Set.empty()`, `Set.fromList(xs)`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `union`, `intersection`, `difference` · `type Queue<T>` (FIFO): `Queue.empty()`, `Queue.fromList(xs)`, `size`, `isEmpty`, `enqueue`, `dequeue`, `peek`, `toList` · `type Order` with the module fns `lt`, `eq`, `gt`, `toInt`, `reverse` |
| `string_builder` | `type StringBuilder`: `empty`, `fromString`, `fromStrings`, `append`, `prepend`, `toString`, `length`, `isEmpty` |
| `math` | constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; trig + hyperbolic |
| `testing.asserts` | The canonical assertion API (1.0.10-beta front 01-std, `asserts-api.md`): every fn is `-> @Result<void, string>`, consumed with `try`, `actual` first, one literal message `asserts.<fn>: <what>` each — `isTrue`, `isFalse`, `equals`, `notEquals`, `approxEquals`, `deepEquals`, `isNil`, `isNotNil`, `isOk`, `isError`, `contains`, `notContains`, `startsWith`, `endsWith`, `matches(actual, pattern)`, `isEmpty`, `isNotEmpty`, `lengthIs`, `includes`, `notIncludes`, `between`, `greaterThan`, `lessThan`, `throws(body)`, `throwsWith(body, needle)`, `fail(message)`, plus `errorText(r) -> string` (the `Error` payload, `""` for `Ok`). No `pub declare fn` (STD-001-clean on every target); `matches`/`deepEquals`/`throws`/`throwsWith` sit on the private cells `regexMatches`/`canonical`/`tryCatch` (Node + Erlang; beam compiles the Erlang templates; wasm refuses the module where the four call their cells, called or not — decision 146 — so an import of `testing.asserts` is refused there: `tests/language/run/std_asserts_on_every_target.bp` runs the rest on commonJS, erlang and beam and pins the wasm refusal at the import). `tryCatch` answers a `@panic(text)` / `@todo(text)` as its own `text` on both targets — the erlang cell reads the raised binary, not its `~p` rendering (where `"` came back escaped), so a `throwsWith` needle with a `"` or a `\` matches alike; any other raise is its JS `message` / erlang `Class:Reason`. The old panicking `truthy`/`falsy`/`equal`/`notEqual`/`approxEqual`/`AssertError` are gone. Named `asserts` — `assert` is a keyword |
| `testing.snapshots` | The snapshot engine (1.0.10-beta front 01-std, `snapshots.md`; decisions 72, 67): `path(loc)` = `<dir of loc.file>/__snapshots__/<suite>/<slug>.snap` (suite = text before the first `": "` of `loc.fnName`, slug = the compiler's `slugify` rule ported byte-for-byte in `slugOf`), `pathNamed(loc, name)`, `suiteOf`, `slugOf` — pure, every backend; `assertText(loc, actual)` (the spec's `assert` — a keyword, so renamed), `assertAs(loc, subject, actual)`, `assertNamed(loc, name, actual)`, `assertNamedAs(loc, name, subject, actual)` — `-> @Result<void, string>`; the `.snap` is `botopink-snap 1` / `test: <name>` / `subject: <subject>` / blank / body; missing or mismatch writes `<path>.new` and answers `Error`, a match deletes a stale `.new`; **no update flag of any kind** — a person renames the `.new`. **No host cell of its own** (1.0.11-beta front 97 — it used to re-declare six of `fs.bp`'s): it reads with `fs.readText`, writes with `fs.writeText` after making the missing parent directories (`ensureDir`, over `fs.exists` / `fs.mkdir` / `path.dirname`), removes a stale `.new` with `fs.rm`, and imports `io.fs`, `io.os`, `io.env`, `io.process as host` and two leaves of `path` — so it runs where `io/fs` runs (commonJS, erlang, beam) and the import is refused on wasm (STD-001), where `botopink test` does not run anyway. The imports are chosen for a consumer, whose build embeds them: `io/process` under the alias `host` (a module-level `process` shadows Node's global) and NOT `io/random`, whose `.mjs` sidecar cannot be shipped to a consumer that resolves std from the compiler (`module 'std/io/random' requires "./sidecars/random.mjs", but its library 'std' resolves to no package directory` — measured from a package outside the checkout). Every inline engine test makes a scratch directory `bpsnap-<pid>-<n>` under `BOTOPINK_TEST_TMPDIR` (the per-run directory `botopink test` names; the host tmpdir outside a run) and removes it again with `fs.removeTree`. Measured from a consumer package on commonJS and erlang: a missing snapshot writes the `.new` under a `__snapshots__/<suite>/` it had to create and answers `Error`; renamed, the next run answers `Ok`. `loc` must be the CALLER's `@src()` |
| `testing.mocks` | Mockito-style mocks over a `behavior` (1.0.10-beta front 01-std, `onze-migration.md`; decision 71) — 100 % of the retired `onze` library, Erlang templates carried over, Node templates inlining what `onze.mjs` held. Eight `pub declare fn` cells (`newMock`, `key`, `pushMatcher`, `invoke`, `beginVerify`, `whenCall`, `thenReturnCell`, `thenThrowCell`), the matchers `eq`/`anyInt`/`anyString` (matchers, **not** assertions — they push a descriptor and answer a dummy), the verify specs `atLeastOnce`/`times`/`never`, `pub type Stub` with `thenReturn`/`thenThrow`, `when(value)`, `verify(mock, spec)` and the `#[mock]` decorator. Mutable state is one cell per host process: `globalThis.__bp_mocks` on Node (the `emilia.bp:24` shape), the `'__bp_mocks_*'` process-dictionary keys on Erlang — **no `.mjs` sidecar**. The only std module with `pub declare fn`, so STD-001 refuses `import {testing.mocks} from "std"` on beam and wasm (the cells have to be exported: `#[mock]`'s emitted body calls them). a consumer reaches `#[mock]` as `#[mocks.mock]` — see *Tests* below |
| `path` | `separator`, `delimiter`, `split`, `isAbsolute`, `basename`, `dirname`, `extname`, `join`, `normalize`, `relative(src, dst)`, `resolve` (posix only); front 01: `withoutExtension`, `isInside(parent, child)` (the traversal guard — both sides through `resolve`, a relative child resolved against the parent, `..` and `../…` refused) |
| `io.random` | `float`, `coin`, `bool`, `intInRange`, `pick`, `shuffle`, `seed`, `seededFloat` — NOT a CSPRNG; `randomBytes(n)` (hex of `n` strong bytes, was `crypto.randomBytes`); front 01: `secureToken(bytes)` (strong bytes as unpadded base64url: 32 → 43 chars), `uuidV4()` (`randomUUID` / 16 strong bytes with the version and variant bits rewritten in the Erlang template — no bitwise operators in botopink) |
| `querystring` | The query-string CODEC (RFC 3986 §3.4 and the form flavour): `parse(query)` and `parseForm(body)` -> `@Result<Array<#(string, string)>, string>` — split on `&` (empty fields dropped, duplicates kept in order), each field on its FIRST `=` (no `=` → empty value), both sides percent-decoded; `parse` strips a leading `?` and keeps `+`, `parseForm` reads `+` as a space and strips nothing. REFUSED (rakun's 03r-e rule, as an `Error`): a `%` not followed by two hex digits, an escape sequence that is not UTF-8, a control character (U+0000–U+001F, U+007F) raw or as its escape. `stringify(pairs) -> @Result<string, string>` percent-encodes both sides over the RFC 3986 unreserved set (`a b` → `a%20b`, `+` → `%2B`) and refuses a control character, so its text reads back through either parser. The percent codec is `encoding`'s, imported (`import {encoding.percentEncode, encoding.percentDecode, encoding.hexDecode} from "std"` — a std module imports another like a program's does); the refusals are decided in botopink before either cell runs. Walks strings by `at`, so a `%` reads its two digits by index. Runs on commonJS, erlang and beam; wasm refuses the import (STD-001: `encoding`'s cells have no wasm binding) |
| `io.clock` | `nowMillis`, `monotonicMillis`, `measureMillis`, `formatIso8601`; front 01: `type Civil(year, month, day, hour, minute, second, weekday)` (UTC, ISO weekday Monday = 1), `type Duration(millis: i64)`, `parseIso8601` (`@Result<i64, string>`, RFC 3339 with the offset REQUIRED — Node's lenient `Date.parse` is gated by a shape check), `toCivil`, `offsetMinutes` (host timezone, minutes EAST of UTC), `millis`/`seconds`/`minutes`/`hours` (take `i32`: a literal is `i32` and never widens, so they cross a private identity cell `wide`), `add`, `toMillis`, `sleep(ms)` (synchronous: `Atomics.wait` / `timer:sleep`), `deadline(d)` (an absolute epoch reading), `isExpired(at)`; front 97: `parseDuration(text) -> @Result<i64, string>` — milliseconds of digits followed by ONE unit, `ms` `s` `m` `h` `d` (`"30s"` → `30000`); no unit, a fraction, a sign, whitespace, an uppercase unit, two units and the empty string are `Error("clock.parseDuration: \"<text>\" is not a duration: digits, then one unit of ms, s, m, h or d")`, and a duration beyond 2^53 − 1 milliseconds is `… is out of range` (the count through `string.parseInt()`, the product against the private cell `largestExactMillis`); pure `.bp`, the same texts on both targets |
| `url` | `type Url`, `parse`, `serialize` |
| `unicode` | `fromCodepoint`, `firstCodepoint`, `codepoints`, `type NormalizationForm`, `normalize` |
| `io.process` | `exit`, `cwd`, `platform`, `pid` (`arch` is `io.os`'s — the duplicate was folded); front 01: `type Exit(status, stdout, stderr)`, `run(cmd, args)` (no shell; `@Result<Exit, string>` — a process that ran is `Ok` whatever its status, `Error` only when it could not start; Erlang folds stderr into stdout through `stderr_to_stdout`, so `stderr` is `""` there), `runShell(cmd)` (`/bin/sh -c`, stdout+stderr as text, STATUS-LOSING on both targets). No `onSignal`: a closure handed to a host cell is unverified on erlang |
| `io.os` | `hostname`, `arch`, `cpuCount`, `tmpdir`, `userInfo` (`type UserInfo`), `eol`. `userInfo`'s Erlang template builds the record's run-time tuple by hand, so it names the type's module atom — `'std@io@os@@UserInfo'`; it still read `'std@os@@UserInfo'` from before the module moved under `io/`, which no test saw until another std module imported `io.os` (`testing.snapshots`, front 97) and `u.username` became a call into the type's module: `{error,undef}` |
| `io.env` | `read`, `write`, `clear`, `args`, `vars` (`get`/`set` are keywords) |
| `regex` | `matches`, `replace`, `replaceAll`, `splitOn`, `type Match`, `match`, `matchAll`; front 01: `type Regex(handle: unknown)`, `compile` (`@Result`, the host's reason on a bad pattern), the host-backed METHOD `Regex.matches(input)` — `re.matches(input)`, the module's `matches(pattern, input)` without re-compiling; it was the free `runCompiled(r, input)` (`element(2, R)` on erlang — a record crosses into a cell as its tuple), `captures` (`?Array<string>`, group 0 first, `null` on no match, `""` for a group that did not take part), `namedCaptures` (`#(name, value)` pairs SORTED BY NAME — Erlang's `all_names` order, the Node cell sorts to agree), `escapeLiteral` (pure; backslash first) |
| `erlang` | Erlang BIF bindings (`abs`, `element`, `spawn`, `send`, …); the erlang codegen reads this file to know which names are BIFs |
| `json` | `parse`, `stringify` (validate + canonical re-encode, `@Result<string, string>`); front 01 steps 11–13 (decisions 116, 117): `quote(s)` (one JSON string literal: `\"` `\\` `\b` `\f` `\n` `\r` `\t`, every other code point below U+0020 as lowercase `\u00xx`, nothing else — the erlang cell is a byte walk because `json:encode` writes UPPERCASE hex), `unquote(literal)` (`@Result`, exactly one string literal), `array(items)` / `object(fields)` (values ALREADY encoded; keys quoted, order kept); step 13: `type Json { Null, Bool(value), Num(value: f64), Str(value), Arr(items), Obj(members: Array<#(string, Json)>) }` and `decode(s) -> @Result<Json, string>` — a botopink reader (not `JSON.parse` / `json:decode`, which reorder keys and keep the last duplicate): members in document order, a duplicate member name refused, trailing text refused, the RFC number grammar exactly (`01` `+1` `.5` `1.` `NaN` `Infinity` refused), an `f64` overflow refused, `\u` escapes and surrogate pairs decoded, an unpaired surrogate and a raw control character refused; every error reads `json.decode: <what> at byte <n>` (UTF-8 bytes). One private conversion cell used by the reader, not a parser: `codepointText` (a `\u` escape). A numeral becomes its `f64` in botopink (decision 142, `numeralValue`): Clinger's fast path (≤ 15 digits, |e| ≤ 22), else exact big-integer arithmetic (15-bit limbs in `Array<i32>`, so every product stays below 2^31 on every target; integer quotients spelled `(a - a % b) / b`, which is exact on every target) — the quotient's 53 bits by shift-and-subtract, rounded half-to-even against the remainder, assembled with no int → float conversion (bits accumulated into an `f64`, scaled by exact powers of two); bit-identical to the host `strtod` on 3500 randomized numerals including every halfway point tried, and pinned by the test "json.decode rounds a numeral to the nearest f64, ties to even". Its loops never `throw` from inside a body — the erlang backend compiles a `throw` in an `if` branch beside `var`-assigning branches to an "unsafe variable" `erlc` refuses; they record the problem and throw after the loop. Tests build non-ASCII text with the private `codepointText` cell, never a literal: the erlang backend truncates a `\u{…}` above U+007F to one latin1 byte. **The readers are methods of `Json`** (1.0.11-beta front 97 — the accessors eight library files had each written): `kindName() -> string` (`null`, `a boolean`, `a number`, `a string`, `an array`, `an object` — what a diagnostic says it found), `isObject() -> bool`, `members() -> Array<#(string, Json)>` (document order; `[]` for a non-object), `field(key) -> ?Json` (the first member of that name; `null` when missing or not an object), `str() -> string` (`""` for a non-string), `items() -> Array<Json>` (`[]` for a non-array). None throws and none answers a `@Result`; a consumer's `membersOf(v)` / `fieldOf(membersOf(v), k)` / `strOf(v)` / `itemsOf(v)` becomes `v.members()` / `v.field(k)` / `v.str()` / `v.items()`. Pure `.bp` in the type's body (`filter`, `at`, `unwrapOr` — host-backed members only), one inline test per method over all six variants; measured from a consumer on commonJS, erlang and beam |
| `io.fs` | `type FileStat`, `readText`, `writeText`, `exists` (a path of ANY kind — file, directory, device such as `/dev/null`, FIFO, socket; a symlink is followed, a dangling one is `false`: `existsSync` / `file:read_file_info`, which agree; `filelib:is_file` answered only files and directories), `list`, `mkdir`, `rm`, `copy`, `stat` (fallible ops return `@Result`); front 01: `walk(root)` (regular files, relative, `/`-separated, sorted; a missing or non-directory root, or an unreadable directory under it, is `Error`; a link is followed — to a file it is listed, to a directory it is walked; a DANGLING link is an `Error` naming it, `fs.walk: dangling link "<relative path>"`, the same text on both targets and the first one in sorted order when there are several — decision 178; the Node cell reads `statSync` with `throwIfNoEntry: false` to tell it from a host failure). The paths do not depend on how the root is spelled (`dir`, `dir/`, `dir/.`, `./dir`, `dir/sub/..`, absolute or relative — one inline test per spelling, and `tests/language` `run/std_fs_walk_root_spellings` from a consumer on commonJS, erlang and beam): the Erlang cell walks `file:list_dir/1` itself and builds each relative path from the names it descends through, because cutting the root's written length off `filelib:fold_files/5`'s full paths was wrong whenever `filename:join/2` had normalised them (a root ending in `/.`, which is what `path.join([dir, "."])` answers — `path.join` keeps a `.` segment on every target, `path.normalize` drops it — lost two characters of every path). `glob(pattern, root)` reads the pattern segment by segment by ONE rule on both targets (decision 177): `**` is zero or more directories, a segment with `*` `?` `[…]` `{a,b}` matches the names of one directory, any other segment is a name; a wildcard never matches a name starting with `.` unless the segment itself starts with the dot (`.*`, `.cache/*.bp` — so `?x`, `[.]x` and `{.a,b}` do not); `**` and a wildcard segment continue into REAL directories only — the walk does not descend through a link to a directory, though `*` lists the link as a name and a segment that names it (`linked/*.md`) goes through it; the last segment matches an entry of any kind, a final `**` is every entry at every depth, a trailing `/` keeps real directories; paths relative, `/`-separated, sorted, each once; a missing root is `Ok([])`. Both cells are the same walk and only the match of one segment against one directory is the host's (`fs.globSync(segment, { cwd })` / `filelib:wildcard/2`), with the dot rule applied over its answer — the two hosts' own whole-pattern matchers disagreed with each other and with themselves (`filelib:wildcard` matched dot names and walked links; `globSync` answered `lnk/b.txt` for `**/*` and not for `**/*.txt`). Not pinned: an alternative holding a `/` (the pattern is split first — it matches nothing), a `..` segment (read as a name), backslash escapes. `list` answers the host's order (sorted on Node, directory order on Erlang). `removeTree(path) -> @Result<i32, string>` (front 97 — it was a private test cell): a file, a link (the link, never its target) or a whole directory tree, and `Ok` for a path that is not there (`rmSync` recursive + force / `file:del_dir_r/1`); what `testing.snapshots`' tests clear their scratch directories with. `rm` removes a FILE only on both hosts — a directory is `Error` (`ERR_FS_EISDIR` / `eperm`), whatever its comment says of an empty one. Private test cells `scratchDir`/`workingDir`/`linkTo` — every walk/glob test builds its fixture under the host tmpdir and removes it. Imports `path.relative` (the relative-root tests) |
| `io.http` | `type Response`, `fetch(url) -> @Task<@Result<Response, string>>` (a transport failure is `Error(message)` — the Node template catches the rejection, the Erlang one maps `{error, R}`, decision 126; an HTTP error status is an `Ok` response), `fetchStatus` |
| `encoding` | The wire formats (front 01; decision 106 — was also `base64`, whose four tests sit at the foot of the file under these names): `base64Encode`/`base64Decode` (`@Result`; Node's silent truncation is caught by re-encoding), `base64UrlEncode`/`base64UrlDecode` (RFC 4648 §5, no padding, `replaceAll` not `replace`), `hexEncode`/`hexDecode` (lowercase; `@Result`, validated before `Buffer.from` truncates), `percentEncode`/`percentDecode` (RFC 3986 unreserved set on BOTH targets — the Node cell also encodes `!'()*`; `@Result`), `formStringify(pairs)`/`formParse(q)` over `#(string, string)` (percent-aware, `+` read as space on parse, a field that does not decode keeps its raw text). Tests carry no non-ASCII literal: the erlang backend lowers one to a latin1 `<<"\x{e9}">>` and refuses a codepoint above U+00FF — non-ASCII enters through `hexDecode` |
| `hash` | Every hash, pure (decision 106). The hex digests (was `crypto`): `sha256`, `sha512`, `md5`, `hmacSha256` (hex strings). The digests in the shape they are compared in (front 01, the hmac half): `hmacSha256Base64Url(key, data)` (JWS HS256), `sha256Base64Url(data)` (43 chars), `sha1Base64(data)` (the RFC 6455 accept key only), `equalsConstantTime(a, b)` (`timingSafeEqual` / `crypto:hash_equals/2`; a length mismatch is `false`, never a throw). Base64url via `base64:encode/2` `#{mode => urlsafe, padding => false}` (OTP 26+). Tests pin RFC 4231-style, RFC 6455 §1.3 and empty-SHA-256 vectors. `pbkdf2Sha256(password, salt, iterations, length) -> string` (1.0.11-beta front 97; decision 175): PBKDF2-HMAC-SHA256, `length` BYTES of key as unpadded base64url (`pbkdf2Sync` / `crypto:pbkdf2_hmac/5`); `password` and `salt` are TEXT — their UTF-8 bytes, so a salt that is itself base64 is derived over its characters, not the bytes it encodes; `iterations` or `length` below 1 is a panic with one text on both targets (`hash.pbkdf2Sha256: iterations and length must be at least 1` — each host raised its own), never an empty key. Pinned by RFC 6070's inputs under SHA-256 (the RFC's own vectors are SHA-1) and RFC 7914 §11's two PBKDF2-HMAC-SHA-256 vectors, as base64url literals; a `pub fn` over the private cell `pbkdf2Derive`, with the private test cell `panicText`. The content hashes (was `content_hash`, 1.0.10-beta `01-std` front 03): `contentHash` (djb2 as lowercase hex, the `emilia.hashHex` templates verbatim — fast, trivially collidable, for filenames and internal keys) and `strongHash` (SHA-256 truncated to 32 hex, for input the caller did not choose). Both are `declare fn` with a Node and an Erlang cell — no bitwise operators or `toString(radix)` in the language, so the fold lives in the template and neither runs on beam or wasm. `cacheKey(parts)` / `strongCacheKey(parts)` hash a FRAMED key — `<length>:<part>` joined by `|`, the private `frame` being the only place parts are rendered — so `["user:1", "profile"]` and `["user", "1:profile"]` cannot collide; pure `.bp`. `etag(body)` answers `"<hash>"` WITH the RFC 9110 quotes, `weakEtag` `W/"<hash>"`, and `matches(body, ifNoneMatch)` is the 304 decision over an exact match, the `*` wildcard or a comma-separated candidate list (membership by `indexOf`, not `Array.contains` — a `default fn` a consumer's embedded copy would emit verbatim). `fingerprint(fileName, contents)` answers `app.<hash>.js` — the extension stays last, a leading dot is not a boundary, no extension means no trailing dot; the extension is measured as the last `.`-piece (written when Erlang's `lastIndexOf` answered a byte offset; the string indices agree since decision 169). Every expected hex in the inline tests is a literal, which is what pins the two targets to each other. `emilia.hashHex` is a duplicate now; collapsing it is a later, `emilia`-owned change |
| `io.net` | TCP and TLS, SERVER-ONLY (front 01). `type Listener`/`Socket`/`TlsListener`/`TlsSocket` (`handle: unknown`), `type Peer(host, port)`. What operates on one of them is a host-backed METHOD of its type, the same names on TCP and TLS: `Listener.port()` / `.accept(timeoutMillis)` / `.close()`, `Socket.recv(length, timeoutMillis)` / `.send(data)` (bytes sent) / `.close()` / `.peer()`, `TlsListener.port()` / `.accept(timeoutMillis)` (handshake included), `TlsSocket.recv` / `.send` / `.close()` — they were the free `listenerPort`, `accept`, `closeListener`, `recv`, `send`, `close`, `peer`, `tlsListenerPort`, `tlsAccept`, `tlsRecv`, `tlsSend`, `tlsClose`. The four that make one stay module functions: `listen(port, backlog)`, `connect(host, port, timeoutMillis)`, `tlsListen(port, certFile, keyFile)`, `tlsConnect(host, port, caFile, timeoutMillis)` (ALWAYS `verify_peer` + SNI — no unverified mode). The private test instrument `tlsEchoOnce(listener, length)` stays free: a method would be exported from `TlsListener`'s module. Every call answers `@Result`, the host reason as text (`timeout`, `econnrefused`, `closed`). Every commonJS cell is the refusal `Error("std/io/net: server-only")`, asserted by the tests; the erlang tests self-connect, time out, meet a closed port and handshake TLS against a throwaway CA `openssl` writes (OTP refuses a self-signed leaf: `selfsigned_peer`); every loopback operation expected to SUCCEED (or to be refused at once) gets a 10 s budget, which a green run never waits out and no scheduling delay crosses — only `accept(50)` with nothing pending is meant to expire |
| `escape` | No import (1.0.10-beta front 01-std-lib-enablement, decision 106 root); two private host cells `lineSeparator`/`paragraphSeparator` build U+2028/U+2029, because the erlang backend lowers `"\u{2028}"` to the one byte `(` — a literal made `jsString` rewrite every parenthesis on erlang: `html` (`&` first, then `<` `>`), `attribute` (`html` + `"` `'`), `unescapeHtml` (the five entities, `&amp;` last), `jsString` (`\` `"` `<`→`\u003c`, `\n` `\r`, U+2028/U+2029 — a payload for a double-quoted JS string literal inside `<script>`); `scriptJson` (step 12, decision 116 rule 3: JSON text safe inside `<script>` — `&` `<` `>` U+2028 U+2029 as `\u` escapes, the same JSON value) |
| `async` | Combinators over `@Task<T>` (front 24 step E7, decisions 120/121 — a Task never fails; a fallible operation is `@Task<@Result<T, E>>`). TWO surfaces, because `@Task<T>` lowers EAGERLY on erlang (`await` is identity — `codegen/erlang.zig`). **Started tasks** — `allOf(Array<@Task<@Result<T, E>>>) -> @Task<@Result<Array<T>, E>>` (input order, stops at the first `Error` in input order), `all(Array<@Task<T>>) -> @Task<Array<T>>`, `race` — the guide's shape (`async.allOf([fetchUser(1), fetchUser(2)])`), written in botopink over `try await` / `await`; concurrent on commonJS, and on erlang honest rather than concurrent (`race` answers ELEMENT ZERO), with both behaviours asserted by the inline tests. **Unstarted tasks** — `runAll(Array<fn() -> @Task<T>>) -> @Task<Array<T>>`, `raceOf`, `timeout(task, millis) -> @Task<@Result<T, string>>` (`Error("timeout")`) — take thunks, so the erlang cell can `spawn` one process per task and gather by index and the node cell can call each thunk into `Promise.all`: genuinely concurrent on BOTH targets, and the surface a server front uses; a crash in a spawned task is re-raised (a crash is a bug, not a failure). `runAll` over `@Task<@Result<…>>` thunks is the settled view. Instruments `delay(millis, value)` (at least `millis` of the MONOTONIC clock on both targets — the Node cell re-arms its `setTimeout` from `performance.now()`, because a timer counts from libuv's cached loop time and fires early after a long synchronous stretch), `failed(message) -> @Task<@Result<T, string>>` (an `Error` value — it does not reject) and the gate — `type Gate`, `newGate()`, `openGate(g)`, `awaitGate(g, millis) -> @Task<bool>` (`true` once open, `false` when the budget passes first; a pid-backed process on erlang, so it crosses into a spawned task) — which orders tasks by SIGNAL, not by clock; `errorText(r)` reads the `Error` side. The inline tests' verdicts do not depend on machine load: order and concurrency are told by gates (a crossed pair of `handshake`s can only both answer when the tasks run at the same time), durations only by LOWER bounds, never an upper bound on elapsed time; a gate's budget (`gateBudget`, 10 s) only turns a gate nobody opens into a red assertion instead of a hang. `allSettled` / `settleOf` / `unwrapAll` / `attempt` left with the rejection they settled (`specs/1.0.10-beta/decisions-pending.md` 24-g). NO cancellation: `raceOf`'s losers and `timeout`'s expired task run to completion. The erlang cells tag every reply with a `make_ref()` unique to their own call, so an expired task's late reply cannot be read by a later combinator in the same process. **Retry** (1.0.11-beta front 97; decision 170 — the natural names, which `rakun-messaging` also declares until its own step deletes them): `type RetryPolicy(maxAttempts: i32, initialMillis: i64, multiplier: f64, maxMillis: i64)`, `nextDelay(policy, attempt) -> ?i64` — the pause that follows attempt `attempt` (the first is 1), `initialMillis × multiplier^(attempt − 1)` rounded down and never above `maxMillis`, `null` past `maxAttempts`, below 1, or for a policy that is not usable (`RetryPolicy(3, 100, 2.0, 1000)` answers `100`, `200`, `400`, `null`) — and `retry(policy, work: fn() -> @Task<@Result<T, E>>) -> @Task<@Result<T, E>>`: `work` is run until it answers `Ok`, at most `maxAttempts` times, pausing `nextDelay(policy, n)` after failed attempt `n`; when every attempt fails the LAST `Error` is answered, a value and never a rejection. No jitter, no `retry` over a plain `@Task`, no field that means "for ever" (decision 67): a policy is usable only with `maxAttempts` ≥ 1, both delays ≥ 0, `maxMillis` ≤ 2147483647 (the longest timer both targets arm) and `multiplier` ≥ 1.0, and `retry` over one that is not is fatal on both targets (`async.retry: maxAttempts must be at least 1 (the first attempt)`), like `race([])`. The growth is one IEEE multiplication per attempt, in a loop that stops at the ceiling — the same operations in the same order on both targets, where a host `pow` would not promise the same last bit. A consumer builds the policy from a LEAF import (`import {async.RetryPolicy} from "std"`): `async.RetryPolicy(…)` through the module namespace is refused (`this "std" module has no such public function`), and `nextDelay(…).unwrapOr(0)` does not type-check (a literal does not widen to `i64` there) — read it with `!= null`. Private cells `millisAsFloat` / `wholeMillis` / `timerMillis` and the test cells `newCounter` / `countUp` / `countOf` / `panicOf` |

`mergeRecords(A, B)`, `partial(T)`, `omit(T, "f")` and `pick(T, ["f"])` are
comptime type functions implemented in the compiler
(`comptime/infer.zig` `tryResolveTypeManipulationCall`), not std source; a
declaration of the same name in scope wins over them (`random.pick`).
`mapFields` does not exist.

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

Importing a std module on a target where its host-bound declarations have no
matching `@External` raises `STD-001` (`comptime/tests/std_target_gating.zig`).

## `#[@External.<Target>(...)]` — host bindings

`#[@External.<Target>(...)]` plus the signature define how a declaration lowers.
Targets come from `type Target { Node, Typescript, Erlang, Beam, Wasm }` in
`builtins.d.bp`, and `External` stays a second declaration rather than
`Target` itself: `Target` is a value a program holds and compares, `External.<T>`
an annotation whose every variant carries a payload the compiler reads (front
20 F9, the sentence in `builtins.d.bp`). Several annotations combine in one
`#[…]`, comma-separated.

- **A host function with an owner is a method of the owner.** One that
  operates on a value of one of the module's types is declared INSIDE that
  type with `declare fn`, `self` first, and called `value.m(…)` — `$0` is the
  receiver (`docs.md` § Host bindings; `io.net`'s sockets, `regex.Regex`).
  Owner-less ones — a constructor such as `listen`/`connect`/`compile`, or a
  function over primitives, `unknown` host terms or builtin types (`@Task`) —
  stay module functions, and so does a private test instrument, since a
  method is exported from its type's module. Two free functions that existed
  only because each type needed its own name (`tlsRecv` beside `recv`)
  collapse into one method name per type.
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
- **`inline`** — `#[@External.Erlang("…", inline = true)]` (or `@External.Beam`)
  opts the `(target, method)` pair out of the dispatch table so the emitter's
  hand-coded shape keeps emitting. Only those two variants declare it, because
  only the erlang and beam emitters read it (`hasExternalInline`, over the last
  argument); on `Node` / `Wasm` / `Typescript`, anywhere but last, or with a
  non-bool value it is refused at the annotation (front 20 F9, decision 67 —
  `comptime/infer.zig` `external_variants`, kept in step with the
  `pub type External` block by a drift test).
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
botopink test --filter "dict"      # by name substring (the `collections` tests of `Dict`)
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

**A consumer writes `#[mocks.mock]`.** A `from "std"` namespace import
registers the module's decorators under `<handle>.<fn>` (`comptime/infer.zig`
`registerStdImportDecorators`), so `import {testing.mocks} from "std"` makes
`mock` the annotation `#[mocks.mock]` (an alias `as m`, `#[m.mock]`). `@emit`
splices its text into the module that hosts the annotated `behavior`, so the
emitted bodies name the runtime through the prefix of the annotation that fired
them: bare here (`#[mock]`: `invoke`, `key`, `newMock`), `mocks.invoke(…)` in a
consumer. A leaf import of `mock` is `std-decorator-leaf-import` — it would
leave the emitted code no handle — and a `#[mocks.<name>]` that names no
decorator of the module is `unknown-annotation` (tests/language
`run/std_decorator_through_namespace`, `reject/std_decorator_leaf_import`,
`reject/std_decorator_unknown_through_handle`).

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

## Effect wrappers (the return is the effect)

There are no effect annotations (decision 118). `@Result<T, E>`, `@Task<T>`,
`@Component<C, T>` (with the owner marker `@Context<Base>`), `@Iterator<T>` and
`@Stream<T>` over `YieldStep<T>` — the chain `Component ⊃ Task`, `Stream ⊃ Task`
that `comptime/effect_chain.zig` restates and drift-tests — and default generic
parameters are documented in the effect-wrapper blocks of `src/builtins.d.bp`.
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
- **Every `.bp` and `.d.bp` of `libs/std` is at the formatter's canonical form,
  and `scripts/format-check.sh` holds it there** (`libs/std` is one of its
  `TREES`: an edit here is followed by `botopink format libs/std`). The
  `std_package_*` codegen snapshots and two LSP snapshots
  (`definition_std_module_member`, `completion_array_methods`) quote this source
  verbatim, so a change of layout in `src/collections.bp` or in a signature of
  `src/primitives.bp` re-records them in the same commit. `builtins.d.bp` parses whole since front 20: an unannotated
  `pub declare fn` takes the full signature (`field<T, F>(…) -> F`,
  `getContext<T>(comptime _: type) -> Component<T, any>`), a behavior `val`
  member any type (`val fields: Field[];`). The compiler's external scanners read
  it (`scanDeclareFnExternal`) and stop on a parse failure, and
  `codegen/tests/builtins.zig` pins that it parses — so a form the parser refuses
  here reds a test, not a build.
- No Zig in `libs/std/` — loader/glue changes belong in `build.zig` / `compiler-core`.
- `get`/`set`/`test`/`from`/`assert` are keywords (`new`, `delegate` and `const` are identifiers since 06 N27) — pick other names (`empty`/`at`/`insert`, `matches`, `src`, `asserts`).
- Array equality in assertions uses `.join(...)` (`==` on arrays is reference equality in JS) — or `asserts.deepEquals`, which renders both sides on the same host.
- An `if (a < b || c > d)` condition does not parse today (the condition grammar stops at `||`); bind it to a `val` first (`asserts.between` does). A parser gap, not a std one.
- **Measured 2026-09-20, consumer side** (`import {testing: {asserts, snapshots}} from "std"` from a user package under `botopink test`): a primitive interface `default fn` (`Bool.negate`, `Array.contains`, `Array.isEmpty`, …) is emitted verbatim (`condition.negate is not a function`) when a std module is compiled as a consumer's **embedded** import — the project compile of `libs/std` itself lowers it. `asserts`/`snapshots` therefore use only host-backed primitives (`== false`, `indexOf`, `.length`, `split`/`join`/`slice`/`indexOf`/`startsWith`/`endsWith`/`contains` on strings). A std module written with a default fn passes its own tests and breaks its consumers. Core gap (commonJS cross-module emission of embedded std modules).
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
  what `snapshots/codegen/beam/wasm/string_slice_without_end_arg_slices_to_source_length.snap.md`
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
- A `val` bound to a generic call is not generalised: `val f = Function.constant(42)`
  accepts one argument type only.
- Test an optional parameter with `!= null`, not truthiness: on commonJS
  `if (end)` is false for `0`.
- Pick a host call by semantics, not by name — `string:suffix/2` and
  `math:round/1` do not exist in OTP, `string:str/2` rejects binaries,
  `string:trim/1` strips both ends. Every host binding carries a test that
  asserts the value.

## One unit for every string index (decision 169)

`indexOf` and `lastIndexOf` answer an index `at`, `slice` and `length` can take, on each target: on
erlang the unit of `string:length/1` (the two used to answer the match's BYTE offset, so
`s.at(s.indexOf(x))` read the wrong character past any non-ASCII text), on commonJS UTF-16 units, as
before. Inside the BMP the two targets count alike, and `test/primitives_test.bp` pins that with a
string built from code points (`a`, U+00E9, `b`, U+20AC, `c`, …); they differ past a character
outside the BMP — a `language-gaps.md` row, not this file's. The erlang unit is `string:length/1`'s
because that is what `length` / `at` / `slice` are bound to there (`string:length`, `string:slice`):
it counts grapheme clusters, which is the codepoint count except over a combining sequence.
`String.charCodeAt` still indexes codepoints (`unicode:characters_to_list`) — the erlang front's.
The template is rendered by the erlang and beam backends; wasm's own `indexOf` is untouched.

## String numerals — `parseInt` / `parseFloat` (1.0.11-beta front 97)

`"42".parseInt() -> @Result<i64, string>` and `"1e3".parseFloat() -> @Result<f64, string>` are
`default fn`s of `behavior String`: the method decides in botopink which strings are numerals, so
every target refuses the same inputs with the same text, and a host cell only converts a string the
method has accepted.

| | accepted — the WHOLE string | `Error` (the text names the input) |
|---|---|---|
| `parseInt` | an optional `+` / `-`, then digits `0`–`9` (`"-0"` is `0`, `"007"` is `7`) | anything else — `""`, `"4 2"`, `"42x"`, `"0x2A"`, `"4.2"`, `"1e3"`, `"-"`: `parseInt: "<input>" is not an integer` · a numeral beyond ±9007199254740991 (2^53 − 1): `parseInt: "<input>" is out of range` |
| `parseFloat` | an optional sign, digits, an optional `.` with digits on both sides, an optional `e` / `E` exponent with an optional sign (`"1e3"`, `"+2.50E-2"`, `"42"`) | anything else — `".5"`, `"1."`, `"1e"`, `"NaN"`, `"Infinity"`, `"0x10"`, `" 1"`, `""`: `parseFloat: "<input>" is not a number` · an overflow: `parseFloat: "<input>" overflows f64`. An underflow is `0.0` |

- **The integer range is the one every target counts exactly.** An `i64` is a JavaScript number on
  commonJS, which stops counting by one at 2^53; `binary_to_integer/1` is exact at any size. Refusing
  past ±(2^53 − 1) on both is what makes the two answer the same value for every input (measured:
  `"9007199254740993"` is `9007199254740992` under `Number` and exact under Erlang).
- **`parseFloat` is the host's correctly rounded conversion** (`Number` / `binary_to_float/1`) of the
  numeral rewritten as `<digits>.<digits>e<exponent>` — the one form `binary_to_float/1` reads (it
  refuses `1e3` and `1.`). It answers `json.decode`'s `f64` bit for bit: `json.bp`'s test
  "json.decode and string.parseFloat answer the same f64 for a numeral" runs both over decision 142's
  boundary list (`5e-324`, `1.7976931348623157e308`, the halfway points, `9007199254740993`, …).
  `"-0".parseFloat()` is `-0.0`, which `==` tells from `0.0` on erlang (`=:=`) and not on commonJS.
- **The cells** are free `declare fn`s beside the slice helpers: `stringIsDigits(s)`,
  `stringToInteger(numeral)`, `stringToFloat(text, whole, fraction, exponent)` and
  `stringNumeralRefused<T>(before, text, after)` — the last three build the `@Result` and its text.
- **The bodies call a method on `self` only** — `self.startsWith`, `self.indexOf` — and reach
  everything else through those cells and the slice helpers. Three emitter gaps met writing them,
  each worked around here, none std's:
  1. commonJS emits `Ok(x)` / `Error(e)` of a `default fn` of this file as written
     (`ReferenceError: Ok is not defined` at the first call) — the `@Result` is built by a cell.
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
  `snapshots/codegen/{beam,wat}/commonJS/*` snapshots that print the `String` prelude carry the two
  bodies.
- Tests: `test/primitives_test.bp` (six tests — the accepted forms, every refusal's text, the range
  and the rounding boundaries) and the `json.bp` agreement test.

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

`builtins.d.bp` declares it, so a type writes `implement Display` with **no import** — `@print` has
to find a value's `display()` without the author having asked for it, which is the same reason every
other builtin behavior is ambient rather than a `pub mod`. One declaration, read by the §7 step of
all four backend fronts.

**`Dict<K, V>` implements it** (decision 8 §7, `00 · 01-checker` step 11): `Dict("a": 1, "b": 2)` — the
pairs in order, a string key or value quoted (`shown`, which asks `x is string` of the generic
value), anything else as it interpolates. It waited for `is` to have a run-time lowering on erlang;
measured on commonJS and erlang (`dict.bp`'s own test). wasm prints a `Dict` as a heap address and
traps in `display` — 05-wasm's rows.
