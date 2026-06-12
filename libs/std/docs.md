# std — embedded standard library

> Path: `libs/std/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`src/examples.md`](src/examples.md)
> Parent: [`../AGENTS.md`](../AGENTS.md)

The botopink standard library. Declarations are written in `.bp` (`src/` is
`.bp`-only), embedded as compile-time strings via `@embedFile` from the loader
in `modules/compiler-core/src/comptime/stdlib/prelude.zig`, and registered
into the type-inference `Env` before each pass.

## Tree

```text
std/
├── botopink.json      ← package metadata
└── src/               ← .bp/.d.bp source files only
    ├── primitives.d.bp  ← I32/U32/I64/U64/F32/F64/Bool interfaces
    ├── array.d.bp       ← generic Array<T> interface
    ├── string.d.bp      ← String interface
    └── builtins.d.bp    ← compiler/runtime builtins (typeOf, sizeOf, panic, …)
```

## How the stdlib reaches the compiler

```text
libs/std/src/*.bp            (.bp-only sources)
            │  build.zig std_bp_files → anonymous imports
            ▼
compiler-core/src/comptime/stdlib/prelude.zig   (@embedFile bundles)
            │
            ▼
compiler-core/src/comptime/env.zig
            │  registerStdlib(&env, gpa)
            ▼
        type Env populated
            │
            ▼
        inferProgramTyped(...)
```

`compiler-core/src/comptime/env.zig` calls
`inferMod.registerStdlib(&env, gpa)` before each inference pass. That
helper imports the `std_prelude` Zig module and registers every embedded `.bp` string
into the type environment. By the time user code is type-checked the
stdlib is already in scope.

## Why interfaces, not implementations

stdlib `.bp` files declare **interfaces only** — method signatures, no
bodies. The actual implementations land in target output through codegen
(JS uses host `Array` / `String`; Erlang uses lists / binaries). This
keeps the compiler's surface stable across targets while letting each
backend emit idiomatic code.

```text
// std/src/array.d.bp
interface Array<T> {
    fn length(): i32,
    fn at(i: i32): T,
    // …
}
```

Adding a method here = signature only. Codegen translates the call to the
appropriate target idiom.

## Conventions

| Rule | Why |
|---|---|
| Keep declarations stable and additive | Any rename forces snapshot churn across every codegen/comptime suite |
| Adding a `.bp` file → add it to `std_bp_files` in the root `build.zig` + `pub const <name> = @embedFile("<name>.bp");` in `compiler-core/src/comptime/stdlib/prelude.zig` | Otherwise inference will not see it |
| Keep interfaces declarative (no method bodies) | The type checker consumes them; codegen knows the implementations |

## What the stdlib currently exposes

| File | Highlights |
|---|---|
| `primitives.d.bp` | `interface I32 { fn to_string(): string, fn abs(): i32, fn max(o: i32): i32, … }`, plus `U32`, `I64`, `U64`, `F32`, `F64`, `Bool` |
| `array.d.bp` | `Array<T>` with `length`, `at`, `push`, `pop`, `contains`, `slice`, `join`, `reverse`, `indexOf`, `forEach`, `map`, `filter` |
| `string.d.bp` | `String` with `len`, `split`, `to_upper`/`to_lower`, `contains`, `starts_with`, `ends_with`, `trim*`, `replace`, `slice`, `char_at`, `index_of`, `to_string` |
| `builtins.d.bp` | Reflection (`typeOf`, `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `field`, `tagName`), numeric (`min`, `max`, `abs`, `as`), control-flow (`block`), runtime (`panic`, `trap`, `src`) |
| `math.bp` | Constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`; `abs`/`floor`/`round`/`trunc`/`ceil`/`sign`/`minF`/`maxF`/`clamp`; `sqrt`/`pow`/`cbrt`/`exp`/`ln`/`log2`/`log10`/`hypot`; `sin`/`cos`/`tan`/`asin`/`acos`/`atan`/`atan2`/`sinh`/`cosh`/`tanh` |
| `asserts.bp` | Runtime assertions — `truthy`/`falsy`/`equal<T>`/`notEqual<T>`/`approxEqual`/`contains` + `record AssertError { message, file, line }`. Pure botopink + `@panic` — wat-safe. Module named `asserts` (plural) since `assert` is a reserved keyword. |
| `path.bp` | Posix forward-slash path manipulation — `split`/`isAbsolute`/`basename`/`dirname`/`extname`/`join`/`normalize`/`relative(src, dst)`/`resolve(segments)` + `separator`/`delimiter` constants. Pure botopink — wat-safe. |
| `random.bp` | `float()` (uniform `[0, 1)`), `coin()` (boolean draw), `bool()` (alias for `coin`), `pick<T>(xs)` (pick random element from `Array<T>`), `intInRange(lo, hi)` (closed interval). |
| `querystring.bp` | `parse(query)` → `Array<#(string, string)>` and `stringify(pairs)` → `string`. Pure botopink — wat-safe; URI percent-encoding deferred. |
| `time.bp` | `nowMillis()` returns Unix epoch milliseconds (`Date.now(1000)` on Node, `erlang:system_time(1000)` on Erlang); `monotonicMillis()` returns the host's monotonic clock in millis (Erlang `erlang:monotonic_time(1000)`; Node falls back to `Date.now(1000)` until §A2 templates land on commonJS); `measureMillis<T>(body)` returns `#(T, i64)` with the body's result and elapsed millis. |
| `url.bp` | `record Url { scheme, user, password, host, port, path, query, fragment }` + `parse(s)` + `serialize(u)` for the standard `scheme://[user[:password]@]host[:port][/path][?query][#fragment]` shape. Pure botopink — wat-safe. |
| `base64.bp` | `encode(s)` / `decode(b)` + url-safe variants `encodeUrlSafe`/`decodeUrlSafe`. Node: §A2 chained `Buffer.from($0, 'utf8').toString('base64')`. Erlang: `base64:encode/1` / `base64:decode/1`. |
| `unicode.bp` | `fromCodepoint(cp)`, `firstCodepoint(s)`. Node: `String.fromCodePoint($0)` / `s.codePointAt(0) ?? 0`. Erlang: `unicode:characters_to_binary([$0], utf8)` / `unicode:characters_to_list`. `normalize` / `codepoints` deferred. |
| `process.bp` | `exit(code)` / `cwd()` / `platform()` / `arch()` / `pid()`. Node via §A2 templates; Erlang via `erlang:halt` + arity-branched 0-arg templates over `file:get_cwd`/`os:type`/`erlang:system_info`/`os:getpid`. |
| `os.bp` | `hostname()` / `arch()` / `cpuCount()` / `tmpdir()`. Node: inline `require('os').hostname()` etc. Erlang: `inet:gethostname` / `erlang:system_info(schedulers_online)` / `os:getenv("TMPDIR")` fallback to `/tmp`. |
| `env.bp` | `read(name) -> ?string` / `write(name, value)` / `clear(name)`. Node: `process.env[$0]` access + assignment + `delete`. Erlang: `os:getenv` returning `false`→`undefined` + `os:putenv` + `os:unsetenv`. Named `read`/`write`/`clear` because `get`/`set` are reserved tokens. |
| `crypto.bp` | `sha256(data)` / `sha512(data)` / `md5(data)` / `hmacSha256(key, data)` — hex-digest strings. Node: chained `require('crypto').createHash('<alg>').update($0).digest('hex')`. Erlang: `crypto:hash`/`crypto:mac` hex-encoded via `io_lib:format`. |
| `regex.bp` | `matches(pattern, input) -> bool` / `replace` / `replaceAll` / `splitOn`. Node: `new RegExp(...)` + `String.prototype.{replace,split}`. Erlang: `re:run`/`re:replace`/`re:split` with `{return, binary}`. Named `matches` because `test` is a reserved keyword. |

Concrete usage snippets: [`src/examples.md`](src/examples.md).

## See also

- The Zig wiring → [`src/docs.md`](src/docs.md).
- How HM inference uses these declarations →
  [`../../modules/compiler-core/src/comptime/docs.md`](../../modules/compiler-core/src/comptime/docs.md).
- Codegen translates stdlib calls per target →
  [`../../modules/compiler-core/src/codegen/docs.md`](../../modules/compiler-core/src/codegen/docs.md).
