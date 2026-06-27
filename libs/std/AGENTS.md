# std

> Path: `libs/std/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/examples.md`](src/examples.md)

Botopink standard library. `src/` is **`.bp`-only** (language-neutral source).
The files are embedded as compile-time strings and loaded by `compiler-core`
into the type environment during inference; the embed/loader glue lives in
`modules/compiler-core/src/comptime/stdlib/prelude.zig`, next to its consumer.

## Tree

```text
std/
├── AGENTS.md          ← you are here
├── docs.md            ← how the stdlib reaches the compiler + conventions
├── botopink.json      ← package metadata
├── src/               ← .bp source modules (inline tests only in non-generic modules)
│   ├── docs.md            ← registry + per-file roles
│   ├── examples.md        ← stdlib usage in `.bp` (Array, String, builtins)
│   ├── root.bp            ← module-tree root: `pub mod <name>;` per std module (source of truth)
│   ├── primitives.d.bp    ← numeric + bool interfaces
│   ├── array.d.bp         ← generic Array<T> interface
│   ├── string.d.bp        ← String interface methods
│   ├── builtins.d.bp      ← @field / @panic / @todo / @emit / … + std.syntax `@Expr`/`@ExprCustom` surface (NOT embedded yet — see below)
│   ├── bool.bp            ← `bool` std module  ◀ inline tests (5 blocks)
│   ├── pair.bp            ← `pair` std module
│   ├── order.bp           ← `order` std module (`pub enum Order`)  ◀ inline tests (3 blocks)
│   ├── list.bp            ← `list` std module (over Array<T>)
│   ├── int.bp             ← `int` std module  ◀ inline tests (5 blocks)
│   ├── float.bp           ← `float` std module  ◀ inline tests (4 blocks)
│   ├── string.bp          ← `string` std module  ◀ inline tests (7 blocks)
│   ├── iterator.bp        ← `iterator` std module (lazy `#[@iterator]` generators + eager higher-order ops)
│   ├── dict.bp            ← `dict` std module (`pub record Dict<K,V>`)
│   ├── sets.bp            ← `sets` std module (`pub record Set<T>`)
│   ├── function.bp        ← `function` std module (`identity`/`compose`/`flip`/`constant`)
│   ├── io.d.bp            ← `io` std module (decl — `#[@External.<targert>(...)]` backed)
│   ├── string_builder.bp  ← `string_builder` std module (`pub record StringBuilder`)
│   ├── queue.bp           ← `queue` std module (`pub record Queue<T>`, FIFO)
│   ├── template_runtime.bp ← wat3 comptime prelude — compiler-internal (NOT in `root.bp`; wired via `std_internal_files` in `build.zig`)
│   │                      — external test suites (generic modules + builtins), co-located:
│   ├── array_test.bp      ← builtin Array<T> surface: join/reverse/indexOf/at/map/filter/slice
│   ├── option_test.bp     ← ?T builtin methods (map/flatMap/unwrapOr) + `?.` chaining
│   ├── result_test.bp     ← builtin result namespace: map/then/unwrap/isOk/isError
│   ├── pair_test.bp       ← pair module: of/first/second/swap/mapFirst/mapSecond
│   ├── list_test.bp       ← list module: fold/map/filter/range/append/prepend/flatten/all/any
│   ├── iterator_test.bp   ← iterator module: range/toList/fold/map/filter/take
│   ├── dict_test.bp       ← dict module: empty/insert/lookup/hasKey/delete/size/fold/merge/mapValues
│   ├── set_test.bp        ← sets module: empty/insert/contains/delete/fromList/union/intersection/difference
│   ├── function_test.bp   ← function module: identity/compose/flip/constant
│   └── queue_test.bp      ← queue module: empty/enqueue/peek/dequeue/toList/fromList
```

## Source modules (src/)

| File | Role |
|---|---|
| `primitives.d.bp` | `interface I32 { … }`, `interface U32 { … }`, …, `interface Bool { … }`. |
| `array.d.bp` | `interface Array<T>` — `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter`. |
| `string.d.bp` | `interface String` — `len`, `split`, `to_upper/lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string`. |
| `builtins.d.bp` (`std.syntax` section) | Data model for `@Expr` templates: `record Span`, `enum Part`, `enum BindingKind`, `record Binding`, `record Source`, `record Context`, and `interface Expr<E>`. Plus the **`@ExprCustom` carrier** (expr-custom): `record CustomNode` (`kind`/`span`/`label`/`ref`/`children` — opaque sub-language tree), `record CustomExpr<T>` (`{ code, ast }`), and `Expr.custom(ast, code)`. Comptime-only; no codegen. The compiler-consumed `CustomNode` is registered via `comptime.zig custom_ast_reflection_src`. |
| `builtins.d.bp` | Reflection (`@field(obj, "name")`), runtime (`panic`/`todo`/`trap`), `emit(source)` — a decorator body contributes generated top-level declarations (wiring) spliced into its module — and `module()`/`external`. Also the **`@Decl` reflection model** (annotation processors): `enum DeclKind`, `record Annotation/Param/Field/Method/Span`, and **`record Decl`** (`kind`/`name`/`fields`/`methods`/`returnType`/`annotations` + `fail`/`failAt`). A decorator is a comptime fn whose first param is `comptime _: @Decl`; the core serializes the annotated declaration into this handle. The compiler-consumed copy of the `@Decl` cluster + the recognized builtins are registered programmatically (`comptime.zig decl_reflection_src` / `inferBuiltinCallReturnType`); this file is the documented surface (not embedded by `prelude.zig`). |
| `bool.bp` | `negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` — pure-operator logic. `option`/`result` are NOT std modules (builtin namespaces). |
| `int.bp` | `absoluteValue`, `min`, `max`, `clamp`, `isEven`, `isOdd`, `toString`. |
| `float.bp` | `absoluteValue`, `min`, `max`, `clamp`, `toString`; `floor`, `ceiling`, `round`, `squareRoot` via `#[@External.<targert>(...)]`. |
| `string.bp` | `split`, `trim`, `trimStart`, `trimEnd`, `contains`, `startsWith`, `endsWith`, `slice`, `replace`, `toUpper`, `toLower`, `join`. |
| `iterator.bp` | Lazy producers: `range(start, stop)`, `repeat(value, times)`, `fromList(xs)` via `#[@iterator]`. Eager consumers (return `Array`): `toList`, `map`, `filter`, `take`. Fold: `fold`. (JS codegen lowers generator delegation `return <iter>` → `yield*` and `loop { yield }` → `for…of`.) |
| `dict.bp` | `pub record Dict<K, V>` (association list over `Array<#(K, V)>`). `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues`. O(n) lookup. |
| `sets.bp` | `pub record Set<T>` (deduplicated `Array<T>`). `empty`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `fromList`, `union`, `intersection`, `difference`. (Named `sets.bp` — `set` is a keyword.) |
| `function.bp` | `identity`, `compose` (left-to-right), `flip`, `constant`. Pure combinators. |
| `io.d.bp` | `print`, `println`, `debug` — host-backed via `#[@External.<targert>(...)]`. Declaration-only. |
| `string_builder.bp` | `pub record StringBuilder` (wraps `Array<string>`). `empty`, `append`, `prepend`, `toString`, `fromString`, `fromStrings`, `length`, `isEmpty`. |
| `queue.bp` | `pub record Queue<T>` (FIFO, front at index 0). `empty`, `size`, `isEmpty`, `enqueue`, `dequeue` (returns `#(Queue<T>, ?T)`), `peek`, `toList`, `fromList`. O(n) enqueue (copy-on-write). |
| `template_runtime.bp` | **Compiler-internal — NOT importable.** wat3 comptime prelude. Records: `Capture` / `DeclHandle` / `Outcome` / `Span` (3-slot `{start,end,line}`) / `CustomNode` (5-slot `{kind,span,label,ref,children}`). Factories: `makeExpr` / `makeCode` / `makeCapture` / `makeSpan` / `makeCustomNode`. Error helpers: `failRaw` / `compilerError`. The wat backend lowers the records + methods; `modules/compiler-core/src/comptime/runtime/wat_runtime.zig` strips the `(module …)` wrapper, prefixes the raw-infra block (memory, bump allocator, fd_write, `$__bp_err`), and renames `$Capture_…` → `$__capture__…` / `$DeclHandle_…` → `$__decl__…` / `$makeExpr` → `$__expr` / `$makeCode` → `$__code` / `$makeCapture` → `$__capture` / `$makeSpan` → `$Span` / `$makeCustomNode` → `$CustomNode` so the historical export list `template_eval.zig` calls stays byte-identical. NOT declared in `root.bp` (intentionally — keeps it out of `import {…} from "std"`); wired as an anonymous import on `std_prelude` via `std_internal_files` in `build.zig`. |

## The `#[@External.<targert>(...)]` vocabulary (annotation-driven builtins, §A)

`#[@External.<targert>(...)]` + the method signature are the single source of truth for how a
builtin method lowers. The `Target` enum (`builtins.d.bp`) value is written bare
(`erlang`), dot-variant (`.Erlang`) or qualified (`Target.Erlang`) — all matched
case-insensitively, so legacy bare-lowercase annotations keep working.

- **Form A (positional)** — `#[@External.Erlang( "lists", "reverse")]`:
  `target`, `module`, `symbol`. Args follow the method's declaration order.
- **Form B (keyword args)** — `#[@External.<Targert>("lists",
  method: "reverse(self)")]`: the language's own `name: value` labels. The labels
  are cosmetic; Form B normalises to the same positional shape as Form A.
- **Call template** — the `symbol`/`method` string may carry `"sym(arg, self)"` to
  fix the host argument order and receiver position (`contains` → `lists:member(item,
  self)`, `map` → `lists:map(action, self)`). A bare `"sym"` uses declaration order.
- **Node prototype shorthand** — omitting `module` on node
  (`#[@External.Node("reverse")]`) means "emit the native JS prototype
  method `recv.reverse(args)` directly", with no host `require`. A different symbol
  is a rename (`append` → `"concat(self, item)"`).

`FnDecl.externalFor`/`InterfaceMethod.externalFor` (`ast.zig`) resolve the
`(module, symbol)` for a target at both arities (`module` comes back `""` for the
node shorthand); the parser keeps an enum/member chain (`Target.Erlang`) as one
argument lexeme and drops the keyword labels.

### Template grammar (`prim-op-annotation`)

The 2-arg form `#[@External.<target>( "<template>")]` accepts a **template
body** instead of a host symbol. The body is the target-language source bytes,
with substitution markers the shared renderer
(`comptime/primOpTemplate.zig`) walks:

| Marker | Resolution |
|---|---|
| `$self` | The receiver expression (already evaluated by the caller) |
| `$0`, `$1`, … `$N` | The N-th positional call argument |
| `$stringify(<inner>)` | Target's "render value as text" wrap; `<inner>` is rendered recursively, so it may contain `$self`/`$N` or be free target-language text (e.g. a lambda's bound var name) |
| any other byte | Passthrough — target syntax (erlang, JS, beam asm, wat instructions) |

**`$stringify(...)` per target** — produces a target-language expression whose
runtime value is the textual rendering of `<inner>`:

| Target | Expansion of `$stringify($e)` |
|---|---|
| `erlang` | `iolist_to_binary(io_lib:format("~p", [$e]))` |
| `node` | `JSON.stringify($e)` |
| `beam_asm` / `wat` | not supported in this wave — reserved for follow-up |

Discriminator: any `$` byte in the symbol switches the dispatch from the
legacy `mod:sym(args)` shape to the renderer. Otherwise (no `$`), the
existing Form A / Form B path runs unchanged.

Examples (erlang):

```bp
#[@External.Erlang( "lists:member($0, $self)")]
fn contains(self: Self, x: T) -> bool

#[@External.Erlang( "[$0 | $self]")]
default fn prepend(self: Self, item: T) -> Self

#[@External.Erlang( "($self =:= [])")]
default fn isEmpty(self: Self) -> bool
```

**Arity branching** — when the lowering depends on the call-site argc, list
`when(argc == N): "<template>"` clauses inside the same annotation. The first
matching `when` is rendered; the predicate uses `argc` (no `$` sigil — `$argc`
would lex as a bare `$` outside a string literal):

```bp
#[@External.Erlang(
    when(argc == 1): "lists:nthtail($0, $self)",
    when(argc == 2): "lists:sublist($self, ($0) + 1, (($1) - ($0)))")]
fn slice(self: Self, start: i32, end: i32) -> Self
```

**Triple-quoted raw strings** (`"""…"""`) — when the template body itself
contains `"`, use the existing `multilineStringLiteral` form. The lexer keeps
the bytes verbatim; the unquoter strips one leading newline immediately after
`"""` and one trailing newline immediately before `"""` (the "indent the
block" convention); inner indentation is preserved.

```bp
#[@External.Erlang( """iolist_to_binary(lists:join($0, lists:map(fun(__E) -> if is_binary(__E) -> __E; is_integer(__E) -> integer_to_binary(__E); is_list(__E) -> __E; true -> iolist_to_binary(io_lib:format("~p", [__E])) end end, $self)))""")]
fn join(self: Self, sep: string) -> string
```

**Per-target reach (today)** — erlang backend reads the full template
grammar. BEAM short-circuits on template-form entries (its inline switch
keeps owning the lowering, byte-identical to before). commonJS does not use
per-callee templates (it relies on `jsMethodRenames` for type-directed name
remapping and native dispatch). wat is not yet wired.

## Tests

All tests live in `src/` — there is no separate `test/` directory. Run with:

```bash
cd libs/std && botopink test            # all suites
botopink test --filter "array map"      # by name substring
```

**Non-generic modules** carry inline `test { … }` blocks directly in their
`src/` file (Zig-style co-location): `bool.bp`, `int.bp`, `float.bp`,
`order.bp`, `string.bp`. `*.d.bp` files are excluded from compilation.

**Generic modules** (pair, list, iterator, dict, sets, function, queue) use
external `*_test.bp` files (co-located in `src/`) because `registerStdlib` processes
each module's source (including inline test blocks) with `.generic` type
variables not yet instantiated — any call to a generic function inside an
inline test block throws `TypeError.typeMismatch`, cascading to all
`freshTestEnv` consumers. Non-generic modules are immune (their functions
have no type variables), which is why inline tests work there.

**Output format (§T)**: each `test "name" { … }` block's stdout is
captured and surfaced under a `----- RUN LOG -----` fence. Assertion
failures surface in the same channel as a `FAIL <name> (<message>) at
<file>:<line>` line. See
[`../../modules/compiler-cli/AGENTS.md#botopink-test-output-format-§t`](../../modules/compiler-cli/AGENTS.md)
for the full envelope contract.

### Coverage (commonJS target)

| Surface | Covered |
|---|---|
| `String` | `split`, `.length`, `trim`, `slice` · **F7.string_ext (std-tail)** — `padStart`, `padEnd`, `repeat`, `replaceAll`, `chars`, `lines`, `words`, `charCodeAt`, `lastIndexOf` |
| `Array<T>` | `join`, `reverse`, `indexOf`, `at`, `map`, `filter`, `slice` · **F7.array_ext (std-tail)** — `some`/`every`/`flat` (aliases over `any`/`all`/`flatten`), `findIndex`, `fill`, `chunked`, `sliding`, `unique`, host-backed `zip<U>` |
| `?T` (option) | `map`, `flatMap`, `unwrapOr`, **`expect` (std-tail)** — proven-in-bounds unwrap; `?.` member access |
| `result` namespace | `map`, `then`, `unwrap`, `isOk`, `isError` |
| `bool` module | `negate`, `nor`, `nand`, `exclusiveOr`, `exclusiveNor` |
| `order` module | `lt`/`eq`/`gt`, `toInt`, `reverse`, `case` over `Order` |
| `pair` module | `of`, `first`, `second`, `swap`, `mapFirst`, `mapSecond` |
| `list` module | `fold`, `map`, `filter`, `range`, `append`, `prepend`, `flatten`, `all`, `any`, `find`, `count`, `take`, `drop`, `reverse`, `first`, `rest`, `contains`, `isEmpty`, `flatMap` |
| `int` module | `absoluteValue`, `min`, `max`, `clamp`, `isEven`, `isOdd`, `toString` |
| `float` module | `absoluteValue`, `min`, `max`, `clamp`, `toString` |
| `iterator` module | `range`, `toList`, `fold`, `map`, `filter`, `take` |
| `dict` module | `empty`, `lookup`, `hasKey`, `insert`, `delete`, `size`, `isEmpty`, `keys`, `values`, `fold`, `merge`, `mapValues` |
| `sets` module | `empty`, `contains`, `size`, `isEmpty`, `insert`, `delete`, `toList`, `fromList`, `union`, `intersection`, `difference` |
| `function` module | `identity`, `compose`, `flip`, `constant` |
| `queue` module | `empty`, `enqueue`, `peek`, `dequeue`, `toList`, `fromList` |
| `math` module | constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; `sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`/`sinh`/`cosh`/`tanh` |
| `asserts` module | `truthy`, `falsy`, `equal<T>`, `notEqual<T>`, `approxEqual`, `contains`, **`matches(pattern, actual)` (std-tail)** — regex-backed assertion; `record AssertError { message, file, line }` for test-runner failure shaping. `throws(body, message)` deferred — needs §A3 `#[@result] declare fn` for a host-level try/catch wrapper. |
| `path` module | constants `separator`/`delimiter`; `split`, `isAbsolute`, `basename`, `dirname`, `extname`, `join`, `normalize`, `relative(src, dst)`, `resolve(segments)` (pure botopink — posix forward-slash; `relative`/`resolve` use head/tail recursion to sidestep the `var` + `push` Erlang dead-store trap) |
| `random` module | `float()`, `coin()`, `bool()`, `pick<T>(xs)`, `intInRange(lo, hi)`. **`seed(s: i32)` + `seededFloat()` (std-tail)** — `libs/std/src/sidecars/random.mjs` ships a Mulberry32 PRNG; `seed` flips a module-local switch so subsequent `seededFloat` reads from the reproducible stream (Node) / process-dict (Erlang via `rand:seed(exsplus, {S,S,S})`). `shuffle<T>` DEFERRED — pure-bp Fisher–Yates over generic `Array<T>` is circular even with `Option.expect(sentinel)`. |
| `querystring` module | `parse(query) -> Array<#(string, string)>`, `stringify(pairs) -> string` (pure botopink; URI percent-encoding deferred until prim-op-annotation lands) |
| `time` module | `nowMillis()` (epoch milliseconds — `Date.now(1000)` on Node, `erlang:system_time(1000)` on Erlang), `monotonicMillis()` (host monotonic clock — `Date.now` on Node until §A2 wires `performance.now`; `erlang:monotonic_time(1000)` on Erlang), `measureMillis<T>(body)` (returns `#(T, i64)` — the body's result paired with the elapsed wall-clock millis), **`formatIso8601(epochMillis)` (std-tail)** — ISO-8601/RFC-3339 string (Node `toISOString()`; Erlang `calendar:system_time_to_rfc3339` at second precision). `sleep` deferred — needs `#[@future] declare fn` (§A3). |
| `url` module | `record Url { scheme, user, password, host, port, path, query, fragment }` + `parse(s)` + `serialize(u)` (pure botopink — splits scheme/fragment/query/authority/userinfo/host:port via per-segment `String.split` + per-char walk for the port; `serialize` rebuilds the canonical shape via `[a, b].join("")` cross-backend string concat). |
| `base64` module | `encode(s)` / `decode(b)` via §A2 chained `Buffer.from($0, 'utf8').toString('base64')` on Node + `base64:encode`/`decode` on Erlang. URL-safe variants `encodeUrlSafe`/`decodeUrlSafe` substitute `+/`→`-_` and pad with `=` via tail-recursive `padToMultipleOfFour`. |
| `unicode` module | `fromCodepoint(cp)` (Node `String.fromCodePoint($0)`; Erlang `unicode:characters_to_binary([$0], utf8)`); `firstCodepoint(s)` pure-bp over the host's first-codepoint extractor; **`codepoints(s)` (std-tail)** — string → `Array<i32>`; **`NormalizationForm` + `normalize(s, form)` (std-tail)** — pure-bp dispatch over NFC/NFD/NFKC/NFKD with one host fn per form. |
| `process` module | `exit(code)` / `cwd()` / `platform()` / `arch()` / `pid()`. Node lowers via §A2 templates (`process.exit($0)`, `process.cwd()`, bare `process.platform` / `process.arch` / `process.pid` properties). Erlang uses `erlang:halt/1` for `exit`; the other 4 use arity-branched 0-arg templates (`when(argc == 0): "<tmpl>"`) so the template-path dispatch fires without a `$N` marker — `file:get_cwd/0` + `os:type/0` + `erlang:system_info(system_architecture)` + `os:getpid/0`. `hostname()` lives in `os` (which has `os.hostname()` on Node). |
| `os` module | `hostname()` / `arch()` / `cpuCount()` / `tmpdir()` / **`userInfo()` (std-tail)** — `record UserInfo { uid, username }` (best-effort on Erlang via `$USER` env var) / **`eol()` (std-tail)** — `"\n"` on POSIX / `"\r\n"` on Windows. Node inlines `require('os')` per call. |
| `env` module | `read(name) -> ?string` / `write(name, value)` / `clear(name)`. Named `read`/`write`/`clear` rather than `get`/`set`/`unset` because `get`/`set` are reserved tokens. Node: `process.env[$0]` lookup with `?? null`; Erlang: `os:getenv`/`putenv`/`unsetenv`. **`args() -> Array<string>` + `vars() -> Array<#(string, string)>` (std-tail)** — Node `process.argv.slice(2)` + `Object.entries(process.env)`; Erlang `init:get_plain_arguments/0` + `os:list_env_vars/0` projected via `list_to_binary`. |
| `crypto` module | `sha256(data)` / `sha512(data)` / `md5(data)` (hex digests) + `hmacSha256(key, data)`. Node: chained §A2 templates `require('crypto').createHash('<alg>').update($0).digest('hex')` + `createHmac('sha256', $0).update($1).digest('hex')`. Erlang: `crypto:hash/2` + `crypto:mac(hmac, …)` hex-encoded via `io_lib:format("~2.16.0b", [B])` list comprehension over `binary_to_list/1`. **`randomBytes(n) -> string` (std-tail)** — hex-encoded N-byte digest (2N chars) over `require('crypto').randomBytes` / `crypto:strong_rand_bytes`; hex sidesteps the `Array<u8>` cross-backend rep gap. |
| `regex` module | `matches(pattern, input) -> bool` / `replace` / `replaceAll` / `splitOn`. Named `matches` (not `test` — reserved keyword). Node: chained §A2 templates over `new RegExp(...)` + `String.prototype.replace`/`split`. Erlang: `re:run`/`re:replace`/`re:split` with `{return, binary}`. **`record Match { value, index }` + `match(pattern, input) -> ?Match` + `matchAll(pattern, input) -> Array<Match>` (std-tail)** — first-match + global-match shapes; Node `String.prototype.match`/`matchAll` with `.index`/`.value` projection; Erlang `re:run` with `[{capture, first, index}]` projecting `binary:part/3` for the matched text. |
| `json` module **(std-tail)** | `parse(s) -> @Result<string, string>` + `stringify(s) -> @Result<string, string>` — validates JSON syntax and returns the canonical re-encoded form. Node: `JSON.parse(JSON.stringify($0))`; Erlang: `json:encode(json:decode($0))` (OTP 27+). Full `JsonValue` enum walker deferred — needs per-target recursive materialiser. |
| `fs` module **(std-tail)** | `record FileStat { size: i64, mtime: i64, isDir: bool }` + 8 host-bound declares (`readText` / `writeText` / `exists` / `list` / `mkdir` / `rm` / `copy` / `stat`). Fallible ops return `@Result<_, string>` via the §A3 wrapper; sync Node `fs.*Sync` family + Erlang `file:*` BIFs lifted to the uniform `{ok, _} | {error, _}` shape. |

**Blocked — snake_case method JS mapping**: `s.to_upper()` etc. are emitted verbatim;
no JS equivalent. Add tests when typed-value dispatch lands.

**Blocked — Erlang/BEAM**: escript loads only the entry module; std modules are
unreachable. All coverage is commonJS-only.

> **erika is no longer a std module.** The C#/LINQ `Query<T>` + `erika "…"`
> template graduated to its own package — now a workspace sibling at
> [`../../../erika/`](../../../erika/). `std` ships it nowhere (dropped from
> `build.zig` `std_pkg_files`); it is reached only through the generic
> `from "erika"` loader (resolved across roots).

## Module tree (`root.bp`)

`src/root.bp` is the explicit module-tree root of the `std` package (the module
system's std pilot): one `pub mod <name>;` per importable std module. It is the
**single source of truth** for the std module set — `build.zig`
(`stdPkgFilesFromRoot`) reads `root.bp`, embeds exactly the declared modules, and
generates the `std_pkg` registry compiler-core discovers generically.

When adding an importable std module (`import {…} from "std"`):
1. Drop `libs/std/src/<name>.bp`.
2. Add `pub mod <name>;` to `libs/std/src/root.bp`.

That's it — no `build.zig`, `prelude.zig`, or `compiler-core` edit. (The ambient
declaration modules `primitives.d.bp` / `builtins.d.bp` are NOT importable
packages: they are flattened into the global type env, wired separately via
`std_core_files` in `build.zig` + `prelude.zig`, and so are not declared in
`root.bp`.)

## Wave 1 modules (v0.beta.19 std-expansion)

`math` is the first §W1 module to land. Surface mirrors the intersection of
the `Math` global (Node, <https://nodejs.org/api/>) and `math:*`
(Erlang, <https://www.erlang.org/doc/apps/stdlib/math.html>) plus a small
pure-botopink shell (`ceil`/`sign`/`cbrt`/`hypot`/`clamp`) that composes the
host primitives instead of carrying their inline-arithmetic templates. Every
host-bound `pub declare fn` carries the same shape on all three backends:
`#[@External.Mode("<NS>", "<sym>"), @External.erlang( "<mod>", "<sym>"),
@external(beam, "<mod>", "<sym>")]`. The rounding family (`floor`/`ceil`/
`round`/`trunc`) returns `f64` (not `i64`) so a chained derivation never
trips the i32/i64 unifier — the host rounding semantics are unchanged, but
strict-equality (`=:=`) tests on `erlang:round/1`'s integer result are
bounded with `>`/`<` rather than equated against a float literal.

## Wave 2 module (v0.beta.19 std-expansion)

`path` is pure-botopink posix path manipulation: `split`, `isAbsolute`,
`basename`, `dirname`, `extname`, `join`, `normalize` + the `separator` /
`delimiter` constants. Reference: Node <https://nodejs.org/api/path.html>
+ Erlang <https://www.erlang.org/doc/apps/stdlib/filename.html>. Forward-
slash separator only; the `path_win32` sibling can land later if a target
needs backslash semantics.

Two Erlang-codegen traps the implementation deliberately sidesteps:
- **`var` + `push` dead store.** A pattern like `var out = []; xs.forEach({
  x -> if (…) out.push(x); });` lowers to `(Out ++ [X])` whose result is
  discarded — Erlang's immutable runtime never rebinds `Out`. `path.split`
  / `path.normalize` use `filter` instead (which round-trips through
  `lists:filter/2`); `path.join` uses `map` + `filter` + `Array.join`
  rather than `flatMap` / `Array.fold` because both also fall back to the
  same `var` + `push` shape on Erlang.
- **String `+` is numeric `+`.** `"foo" + "bar"` on Erlang emits
  `<<"foo">> + <<"bar">>` and reds with `badarith`. The module avoids
  `+` for string concatenation: `[a, b].join("")` round-trips through
  `lists:join("", …)` + `iolist_to_binary/1` on Erlang and
  `Array.prototype.join("")` on Node, both string-safe. This pattern is
  the workaround for any pure-botopink module that needs cross-backend
  string concat before `prim-op-annotation` lands.

`relative(src, dst)` and `resolve(segments)` close the §W2 path API
(`std-expansion-tail` F4.path). Both use explicit head/tail recursion
over the split parts — `commonPrefixCount` walks two arrays in lockstep,
`makeUps`/`applyPieces` build the answer functionally — so the `var` +
`push` Erlang dead-store trap never fires. `relative` takes `(src, dst)`
rather than `(from, to)` because `from` is the reserved import keyword;
the parameter name is `src` to keep the call site readable.

## Wave 5 module (v0.beta.19 std-expansion)

`asserts` is the pure-botopink assertion surface: `truthy`/`falsy`/`equal`/
`notEqual`/`approxEqual`/`contains`. Reference:
<https://nodejs.org/api/assert.html>. Every fn lowers to a comparison +
`@panic("…")` on failure with no host binding (cross-backend safe, wat
included). The module is named `asserts` (plural) because the unqualified
`assert` is a reserved keyword statement — the qualified-call style stays
unchanged: `import {asserts} from "std";` → `asserts.truthy(x)`.

`approxEqual` open-codes `abs(a - b)` with an inline `if (diff >= 0.0) {
diff } else { 0.0 - diff }` rather than importing `math.abs`; the import
clashed with the builtin generic `abs<T>` from `builtins.d.bp`, and the
inline shape keeps `asserts` lib-self-contained (no `from "std/math"` hop
inside `std` itself).

## Wave-tail roadmap (v0.beta.19 std-expansion-tail)

The follow-up task to `std-expansion` lives at
[`../../tasks/v0.beta.19/specs/std-expansion-tail.md`](../../tasks/v0.beta.19/specs/std-expansion-tail.md).
It closes the 12 modules `std-expansion` deferred (`json`, `base64`, `env`,
`fs`, `process`, `os`, `regex`, `unicode`, `array_ext`, `string_ext`, `http`,
`crypto`), the in-module tails on the 5 landed §W1/§W2/§W5 modules
(`path.relative/resolve`, `random.intInRange/bool/shuffle/seed`,
`time.monotonicMillis/sleep/formatIso8601/measureMillis`,
`asserts.throws/matches/AssertError`, `url` verification), the F6
`STD-001` `std-unsupported-on-target` import-site diagnostic (now active —
`comptime.compile` threads the target name through to `Env.target`;
`markStdImports` reds when an imported std module's host-bound declares
have no `@external` match), and the F7 examples-CLI + per-target
coverage doc.

The `http` module landed under `v0.beta.22/ecosystem-and-snap-tail` F0:
the surface is `fetch(url) -> @Future<Response>` over a `#[@future]`
declare fn (parser §A3 exception extended from `@result` to also cover
`@future` when an `@external` annotation is present — the host template
owns the Promise/native-future wrapper shape). Node lowers to a chained
`globalThis.fetch + .text()` Promise; erlang lowers to
`inets:start + ssl:start + httpc:request/4` under the erlang eager
`@Future<T>` resolves-to-`T` rule. No runtime tests — `fetch` needs
network access; the parser-side gate
(`parser/tests/effect_rejections.zig::R1 §A3`) pins the §A3 acceptance.

## Sidecar adapters (std-tail F2)

Some host bindings need code that doesn't fit a one-line `#[@External.<targert>(...)]`
template — a userland PRNG (Mulberry32), an HTTP client wrapping
`node:http` as a Promise, a base64 URL-safe table. The std convention
places those at:

```
libs/std/src/sidecars/<m>.{mjs,erl}
```

The bp module annotates its declares with the sibling-path require:

```bp
#[@External.Node("require('./<m>.mjs').<fn>($0)")]
pub declare fn <fn>(arg: T) -> R;
```

The CLI's `shipMjsSidecars` (`modules/compiler-cli/src/cli/libs.zig`)
probes both `<lib>/src/sidecars/<base>` and the flat `<lib>/src/<base>`
when copying the source next to the emitted module — so a sidecar's
relative `require("./<m>.mjs")` resolves both in the lib's own
`botopink test`/`build` AND when the lib is loaded as a dependency.

No transpile, no minify — the adapter is plain target source. Sidecars
ship verbatim; the lib-test out-dir builder picks them up the same way
the project build does.

## Conventions

- Stable, additive signatures — renames force snapshot churn.
- Interface declarations (`.d.bp`) must stay declarative (no method bodies).
- No Zig in `libs/std/` — loader/glue changes belong in `compiler-core`.
- Method receivers must be `val`-bound identifiers — literal receivers don't parse yet.
- Equality assertions on arrays use `.join(...)` (structural `==` is reference equality in JS).
- `new`/`get`/`set` are keyword tokens — use `empty`/`lookup`/`insert` instead.

## Effect annotations

The six `#[@<effect>]` markers (`#[@result]` · `#[@future]` · `#[@generator]`
· `#[@iterator]` · `#[@asyncGenerator]` · `#[@context]`) and the §1G default
generic parameters are specified in
[`tasks/v0.beta.19/specs/frente-b-rules-tooling.md`](../../tasks/v0.beta.19/specs/frente-b-rules-tooling.md).
The `§ effect annotations` block at the bottom of `builtins.d.bp` mirrors §4
of that spec verbatim — it is the type-env-side summary readers of the
stdlib see when they hover an annotation. Any rule change touches both
surfaces in the same commit.
