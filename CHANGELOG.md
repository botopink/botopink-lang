# Changelog

All notable changes to the botopink compiler workspace are documented in this file.

## Unreleased

### Added (v0.beta.22 — wat-runtime-as-bp-module)

- **F12 descriptor walker**: `appendDescriptorBytes` now emits a full F2 binary
  layout (text + file + line/col/multiline + scope entries + parts). Raw-infra WAT
  gains `__str_eq` (length-prefixed string comparison), `__skip_str` (field skip),
  `__capture__lookup` (scope entry walker), `__capture__bindings`,
  `__capture__context`, and `__capture__parts`. `Capture.context`/`lookup`/`bindings`
  in `template_runtime.bp` are now `#[@Host]` — the raw-infra WAT provides the real
  bodies.
- **F13 parts offset**: `partsOffsetInDescriptor` computes the byte offset of the
  parts section within a descriptor blob. `template_eval.evaluateWat` passes the
  correct parts pointer when constructing capture handles, so `Capture.parts`
  returns a real pointer for templates with `${…}` holes.
- **F1 scaffold** for the wat3 comptime prelude:
  `libs/std/src/template_runtime.bp` declares the records (`Capture` /
  `DeclHandle` / `Outcome` / `Span` / `CustomNode`), factory fns
  (`makeExpr` / `makeCode` / `makeCapture` / `makeSpan` / `makeCustomNode`),
  and stub bodies for the 10 `Capture` methods + 8 `DeclHandle` methods
  + `failRaw` / `compilerError`. The file is **inert** — not in `root.bp`
  (intentionally NOT a user-importable std module) and not yet referenced
  by `wat_runtime.zig`. F2 lands the wiring: `wat.codegenEmit` over this
  source, `(module …)` wrapper strip, raw-infra prefix, plus the
  naming-bridge string rewrites (`$Capture_…` → `$__capture__…` /
  `$DeclHandle_…` → `$__decl__…` / `$make<X>` → `$<X>`) so the historical
  export surface stays byte-stable across the swap.

### Added (v0.beta.22 — beam-target-template-output)

- **BEAM-target template consumer** for `#[@External.<targert>(...)]` primitive-op
  annotations (front 03 / spec 03). `codegen/beam_asm.zig`'s
  `tryEmitPrimAnnotation` now consults a new `prim_beam_templates` map
  before the existing erlang-derived dispatch + the inline
  `emitPrimMethod` switch: a `#[@External.Beam("""<.S body>""")]`
  annotation on a primitive interface method (the 1-body-arg form —
  collector keys on `bref.module.len == 0`, so `looksLikeTemplate` is
  not the discriminator) registers the body, and `renderBeamTemplate`
  pre-loads `recv` into `{x, 0}` + each positional arg into `{x, i+1}`
  (args in reverse order, then `recv` last, with `min_live = argc + 1`
  floored so earlier loads survive) and renders the body via the shared
  `comptime/primOpTemplate.zig` walker — `$self` → `{x, 0}`, `$N` →
  `{x, N+1}`, `$args` → the comma-separated `{x, 1..N}` list. Five
  arms shipped with templates (`libs/std/src/primitives.d.bp`):
  `String.toUpper` / `toLower` / `trim`, `Array.reverse` (all 0-arg,
  byte-equal vs the legacy `("mod", "sym")` bare-symbol path) and
  `String.endsWith` (1-arg — fixes the previous
  `%% prim method not lowered on beam (complex arg): suffix/2`
  placeholder; new snapshot
  `codegen/beam/beam/endswith_lowers_via_external_beam_single_line_body.snap.md`
  pins the e2e shape). The `emitPrimMethod` inline switch still owns
  arms needing labels (`isEmpty`), `gc_bif` arithmetic (2-arg `slice`),
  `make_fun3` helpers (`at` / `indexOf` / `join`) or `put_list` /
  `lists:append` register juggling (`prepend` / `push` / `append`) —
  migrating those needs the template grammar to grow `$label` /
  `$gc_bif` markers (see `codegen/AGENTS.md` §A6).

### Added (v0.beta.22 — generic-inference-finalize)

- **Regression guards for the v0.beta.19 §B / v0.beta.20 keystone generic-
  inference gaps** (`comptime/tests/infer_generics.zig`). The three shapes the
  v0.beta.22 spec 04 enumerated — chained method substitution
  (`xs.map(f).filter(g)` propagating the element type across the second hop),
  generic-fn back-prop from a typed binding (`val d: Dict<string, i32> =
  empty()` driving K/V), and structural-tuple unify across independently-
  resolved generics — were already closed by intervening v0.beta.20 work
  (`stdlib-backends-parity`'s `primMethodReturnTypeFromIface`,
  `beam-inline-prim-methods` register substitution, `prim-op-template-fix`).
  The three minimal-failing tests now pin the closures so a future
  regression in `inferTypeMethods` / `primMethodReturnTypeFromIface` /
  `unify`'s tuple arm trips the harness instead of silently re-opening the
  gap.
- **AGENTS.md sweep**. `codegen/AGENTS.md` `erlang.zig` row drops the
  "LINQ lib's inference gaps" wording from the **Remaining gaps** line;
  `comptime/AGENTS.md` `infer.zig` row trims the
  "LINQ-heavy stdlib lib still compiles" rider on the
  `inferTypeMethods` best-effort note (the best-effort skip stays — it
  still applies to method bodies that trip orthogonal gaps).

### Changed (v0.beta.22 — wasm3-as-module)

- **`vendor/wasm3/` → `modules/wasm3/`** (refactor only; zero behaviour
  change). The vendored interpreter now ships as a first-class Zig module
  with its own `build.zig` exporting `link(b, compile)` +
  `exposeHeaders(b, mod)` + the `wasm3_srcs`/`wasm3_cflags` arrays. The
  root `build.zig` lost the inline `wasm3_srcs` array and `linkWasm3` fn
  (~50 LOC) and imports the module via
  `@import("modules/wasm3/build.zig")`; each prior `linkWasm3(b, …)`
  callsite is now `wasm3.link(b, …)`, and the
  `core_mod.addIncludePath(…)` is `wasm3.exposeHeaders(b, core_mod)`. The
  `vendor/` directory is gone — future vendored C deps follow the same
  `modules/<name>/{AGENTS.md, README.md, LICENSE, build.zig, source/}`
  pattern.

### Changed (v0.beta.21 — wasm3-unified-runtime)

- **Single embedded comptime runtime** (`comptime/eval.zig` +
  `comptime/runtime/wasm.zig` + new `comptime/runtime/wasm3_host.zig` +
  new `comptime/runtime/wat_to_wasm.zig`). The pre-v0.beta.21 four-runtime
  architecture (`node` / `erlang` / `wasm` (wasmtime) / `beam`) dispatched
  every comptime val expression across four external runtimes — primarily
  as a cross-backend semantic-parity oracle. That oracle became redundant
  once codegen snapshots covered the target-syntax rendering path, and the
  four-runtime split required `wasmtime` / `erl` / `erlc` / `escript` on
  every dev box's PATH. This release collapses the four into a single
  in-process [wasm3](https://github.com/wasm3/wasm3) interpreter.
  - `comptime/runtime/{node,erlang,beam,persistent_erlang}.zig` and the
    sibling escript runner are deleted.
  - `eval.Runtime` enum and the `Config.comptimeRuntime` field are gone.
  - `wasm.run` now hands its WAT in-memory to `wasm3_host.runWat`; no
    intermediate `.wat` file is written.
  - `codegen/runtime.executeWat` switches off the `wasmtime` spawn path
    too; modules whose WAT shape exceeds the pure-Zig
    `wat_to_wasm.compile` subset (block/loop/if/br — slated for
    `templates-decorators-botopink-native`) return an empty RUN-LOG
    buffer, matching the legacy "wasmtime missing" behaviour.
  - `warmPersistentErlangRunner` is replaced by `warmWasm3Runtime`;
    `warmPersistentNodeRunner` stays (still used by `template_eval` /
    `decorator_eval`, until the follow-up spec migrates them off Node).
- **Vendored wasm3 v0.5.0** at `modules/wasm3/source/` (16 `.c` files
  + headers + LICENSE; pinned to upstream commit
  `6b8bcb1e07bf26ebef09a7211b0a37a446eafd52`). Linked into every
  `compiler-core`-importing Compile target via `wasm3.link(b, …)` from
  the `modules/wasm3/build.zig` module. WASI is provided by a
  single-function `fd_write` shim in `wasm3_host.zig`; none of the
  upstream `d_m3HasWASI` defines are set. (v0.beta.21 originally landed
  this at `vendor/wasm3/` with an inline `linkWasm3` fn; v0.beta.22
  front 06 `wasm3-as-module` repackaged it as a first-class module —
  see the entry above.)
- **Linux glibc workaround**: `build.zig` now pins to bundled glibc 2.38
  on linux-gnu native builds. Sidesteps the Zig 0.16 + glibc ≥ 2.42
  `.sframe` crt1.o relocation bug that surfaces once any Compile target
  calls `linkLibC()` (which `wasm3.link` does transitively). Other OSes
  and explicitly-pinned targets pass through unchanged.

### Added (v0.beta.20 — beam-inline-prim-methods)

- **`xs.join(sep)` / `xs.indexOf(item)` / `xs.at(i)` on BEAM**
  (`codegen/beam_asm.zig` `emitPrimMethod` array arm). The three
  array methods that v0.beta.19's `prim-op-annotation` left as BEAM
  gaps now lower to direct BEAM assembly instead of falling through
  to the `%% unresolved method call:` comment.
  - **F1 — `xs.join(sep)`** (`primJoin`). Lowers to
    `iolist_to_binary(lists:join(sep, lists:map(stringify, xs)))`;
    the per-element stringify fun ships via the lazily-emitted
    `'-bp_stringify-'/1` helper (`ensureStringifyHelper`) — a
    `make_fun3` closure that dispatches `is_binary` (pass through)
    / `is_integer` (`integer_to_binary`) / fallback
    (`io_lib:format("~p", [E])`). The whole iolist flattens to one
    binary via `erlang:iolist_to_binary/1` so the surface type is
    honoured. `[10, 20, 30].join(", ")` runs to `<<"10, 20, 30">>`,
    byte-identical with the erlang backend.
  - **F2 — `xs.indexOf(item)`** (`primIndexOf`). Lowers to a call
    into the lazily-emitted recursive synth helper
    `'-bp_indexOf-'/3 (L, X, I)` (`ensureIndexOfHelper`) — the
    running 0-based index travels through `{x, 2}` (replacing the
    erlang template's closed-over `__X`, since `make_fun3`'s
    free-var list is empty), tail-recursing through `call_only` so
    the linear scan doesn't grow the stack. Hit returns the
    running index, miss (`[]` arm) returns `-1`.
    `[1, 2, 3, 4].indexOf(3)` runs to `2`,
    `[1, 2, 3].indexOf(99)` runs to `-1`.
  - **F3 — `xs.at(i)`** (`primAt`). Lowers to a call into the
    bounds-safe helper `'-bp_at-'/2 (L, I)`
    (`ensureAtHelper`) — `(L, I)` spill to `(y1, y0)` so the
    `erlang:length/1` probe survives, then `is_ge` against `0` +
    `is_lt` against length on `y0` gate the
    `gc_bif '+' (I + 1)` + `call_ext_last lists:nth/2` tail call
    on hit, `undefined` (the `@Option` none atom mirroring the
    erlang backend) on miss. `[10, 20].at(0)` runs to `10`,
    `[10].at(5)` runs to `undefined`.
  - All three helpers cache on the `Emitter` (`at_helper_name` /
    `indexOf_helper_name` / `stringify_helper_name`, freed in
    `deinit`) so repeat call sites in a module share one helper
    body. Three new BEAM snapshots
    (`array_{join,indexof,at}_lowers_byte_identically_across_backends.snap.md`)
    pin the register shape + assert byte-identical RUN LOG against
    the erlang backend. The pre-existing
    `array_instance_default_fn_methods` / `iterator_fromlist` /
    `option_method_on_tuple_element` /
    `string_methods_map_to_native_js_names` BEAM snapshots also
    update to reflect the new shape — the chained ones with still-
    unresolved `fold` / `all` / `split` callees retain empty RUN
    LOGs because the unresolved siblings clobber the call-site
    register layout before execution can complete.

### Changed (v0.beta.20 — test-speed-tmp-consolidation)

- **Runtime output cache** (`runtime.zig`). Each `executeX` hashes
  (target + emitted code + aux modules + module name) into a SHA256
  key and short-circuits the subprocess on a cache hit, writing the
  entry under `<compiler-core>/.botopinkbuild/runtime-cache/<sha>`
  (prefixed with `OK:` so corrupt files re-execute). Cuts the
  warm-cache `js_values` filter from 41s → 17s; erlang+beam (which
  dominate at ~500ms/call cold thanks to BEAM VM startup) drop to
  ~80–95ms/call on a hit. Content-keyed so any change to the inputs
  misses naturally; toolchain upgrades (node/erl/wasmtime) are NOT
  in the key, so clear the cache dir after upgrading those. Reaped
  by `clean-tmp` alongside `tmp/`.
- **Per-backend subprocess timings** are written to
  `<compiler-core>/.botopinkbuild/runtime-timings.txt` every 16th
  `executeX` invocation (atomic counters, throttled to avoid
  file-write contention from parallel test threads). Read back
  with `cat …/runtime-timings.txt` after any test cycle —
  `node=…ms/Ncalls  erlang=…  beam=…  wasm=…`. Surfaces the
  per-backend bottleneck in one bash command without bespoke
  tooling.
- **Per-test scratch dirs consolidated under `.botopinkbuild/tmp/`.**
  `runtime.makeScratchDir` (single callsite for every `executeJavaScript` /
  `executeErlang` / `executeBeamAsm` / `executeWat`) now lands its
  per-execution dir at `<compiler-core>/.botopinkbuild/tmp/<hex>/` instead
  of a `.tmp-exec-<hex>/` sibling of the module root. The umbrella
  `.botopinkbuild/` `.gitignore` rule already swallows the path, so the
  now-redundant `**/.tmp-exec-*/` line is removed. `zig build clean-tmp`
  (auto-runs at the start of every `zig build test` cycle) reaps tmp
  entries older than 1 day, so a crashed test never leaks past a day and
  never as a root sibling. `runtime_scratch.zig` (new test) pins the
  layout: path starts with `.botopinkbuild/tmp/`, cleanup is atomic on
  success, leak on crash stays inside the tmp root.

### Added (v0.beta.20 — std-tail wave 2)

- **STD-001 runtime check** — `botopink build` / `botopink check` /
  lib-test now red on `import {<m>} from "std"` whose host-bound declares
  lack an `@external` for the active codegen target. `comptime.compile`
  threads the target name (`node` / `erlang` / `wasm`) through
  `analyzeSource` → `Env.target`; `registerStdlib` collects each module's
  `pub fn`/`pub declare fn` into `Env.stdModuleFns`; `markStdImports`
  walks the map and emits `std-unsupported-on-target: std/<m>.<fn> has
  no \`@external\` for target '<t>'`. Tooling paths (LSP, comptime
  tests) pass `null` and the check stays off.
- **`std/fs`** — `record FileStat { size: i64, mtime: i64, isDir: bool }`
  + 8 host-bound declares (`readText`, `writeText`, `exists`, `list`,
  `mkdir`, `rm`, `copy`, `stat`). Fallible ops return `@Result<_,
  string>` via the §A3 wrapper (Node sync `fs.*Sync` family + Erlang
  `file:*` BIFs lifted to `{ok, _} | {error, _}`).
- **`std/random.seed(s: i32)` + `seededFloat()`** — Mulberry32 sidecar
  at `libs/std/src/sidecars/random.mjs`; `seed` flips a module-local
  switch so subsequent `seededFloat` reads from the reproducible
  stream. Erlang side uses `rand:seed(exsplus, {S, S, S})` —
  `rand:uniform/0` reads the seeded state from the process dict
  automatically.
- **`std/crypto.randomBytes(n: i32) -> string`** — hex-encoded
  N-byte digest (2N chars) over `require('crypto').randomBytes` /
  `crypto:strong_rand_bytes`. The hex shape sidesteps the `Array<u8>`
  cross-backend representation gap.
- **CLI sidecar shipping — quote-style fix.** `shipMjsSidecars` now
  detects both `require("…")` and `require('…')` for `.mjs` sidecars.
  Required for §A2 templates that author single-quoted requires.

### Added (v0.beta.20 — std-tail follow-ups)

- **`std/json`** (V1) — `parse(s) -> @Result<string, string>` +
  `stringify(s) -> @Result<string, string>` via §A3 template-owned
  wrapper. Validates JSON syntax and returns the canonical re-encoded
  form (Node `JSON.stringify(JSON.parse($0))`, Erlang OTP 27+
  `json:encode(json:decode($0))`). Full `JsonValue` enum walker
  deferred — needs per-target recursive materialiser because bp enum
  tagged shape diverges from native host JSON.
- **`std/asserts.throws(body, message)`** — pure-bp wrapper over a
  private §A3 `tryCatch(body: fn() -> i32) -> @Result<i32, string>`
  template-owned declare. The body's return is `i32` rather than
  `unit` because bp's noreturn (`@panic`) doesn't unify with `unit`;
  callers append `0;` as the closure's tail sentinel.
- **CLI sidecar shipping (F2)** — `shipMjsSidecars` (the CLI's
  per-emit relative-require helper) now probes `<lib>/src/sidecars/<base>`
  before the flat `<lib>/src/<base>`, matching the std-tail convention
  for heavier per-target adapters. `libs/std/AGENTS.md` documents the
  convention.
- **`libs/std/src/examples.md`** — "Real-world examples" section with
  an env-driven CLI walkthrough plus a per-target coverage matrix
  (21 modules × 4 backends) feeding the eventual STD-001 diagnostic.

### Added (v0.beta.20 — std-tail)

- **`Option.expect<T>(default: T) -> T`** — proven-in-bounds unwrap surface
  on the `?T` builtin. Identical runtime semantics to `unwrapOr` (one extra
  arm in `inferResultOptionMethod` re-routes the lowering to the same
  `__bp_option_unwrapOr` builtin); the name is a documentation contract
  signalling "the absent branch is unreachable, this default is a sentinel".
  See `tasks/v0.beta.20/specs/std-tail.md` §option-expect for the rationale
  (Rust-style naming distinction without the panic).
- **`std/time.formatIso8601(epochMillis)`** — RFC-3339 / ISO-8601 string
  rendering. Node: `new Date($0).toISOString()`. Erlang:
  `calendar:system_time_to_rfc3339/2` with unit=second; fractional-second
  suffix differs (Node always renders `.000`, Erlang omits at second
  precision).
- **`std/asserts.matches(pattern, actual)`** — regex-based assertion that
  panics when `pattern` does not match `actual`. Self-contained — the
  regex template is duplicated inline (private `regexMatches` declare fn)
  rather than reaching across the std module tree.
- **`std/env.args() / env.vars()`** — program argv (Node:
  `process.argv.slice(2)`; Erlang: `init:get_plain_arguments/0`) and full
  env table as `(name, value)` pairs (Node: `Object.entries(process.env)`;
  Erlang: `os:list_env_vars/0`).
- **`std/os.userInfo() / os.eol()`** — calling user identity (`record
  UserInfo { uid, username }`) and platform line terminator. Erlang
  `userInfo` is best-effort: there is no equivalent BIF, so the template
  reads `$USER` and reports `uid=0` (informative, not POSIX-grade).
- **`std/unicode.codepoints(s)`** — string → `Array<i32>` codepoint
  decomposition. Node: `Array.from(s).map(c => c.codePointAt(0))`. Erlang:
  `unicode:characters_to_list($0, utf8)`.
- **`std/unicode.NormalizationForm` + `normalize(s, form)`** — pure-bp
  dispatcher over the four NFC/NFD/NFKC/NFKD forms, each backed by a
  per-form host fn (`String.prototype.normalize('<form>')` on Node,
  `unicode:characters_to_<form>_binary` on Erlang).
- **`std/regex.Match` record + `regex.match()` + `regex.matchAll()`** —
  first-match + global-match shapes. Each match site is a `Match { value,
  index }`; Node uses `String.prototype.match`/`matchAll`, Erlang uses
  `re:run` with `{capture, first, index}` projecting `binary:part/3` for
  the matched text.
- **`Array<T>` extension methods (F7.array_ext)** — `some` / `every` /
  `flat` aliases over `any`/`all`/`flatten` plus net-new `findIndex`,
  `fill`, `chunked`, `sliding`, `unique`, and host-backed `zip<U>` (Node:
  `slice + map`; Erlang: list comprehension over the prefix indices). The
  pure-bp defaults stay within the existing combinator surface (`forEach`,
  `at`, `slice`).
- **`String` extension methods (F7.string_ext)** — `padStart`, `padEnd`,
  `repeat`, `replaceAll`, `chars`, `lines`, `words`, `charCodeAt`,
  `lastIndexOf`. Each maps to the Node prototype method on commonJS plus
  an Erlang inline fn projecting the shape (binary copy, line split on
  CRLF, whitespace split).

### Added (v0.beta.19)

- **`std` gains seven modules** (`std-expansion` task — see
  `tasks/v0.beta.19/specs/std-expansion.md`). All ship with `////` header
  citations of the upstream Node + Erlang reference URLs and inline
  `test { … }` blocks (34 tests total). Green on commonJS + erlang via
  `botopink-lib-test --lib std`; module list also extends
  `libs/std/src/root.bp`.
  - `math` — constants `pi`/`e`/`tau`/`sqrt2`/`ln2`/`ln10`/`log2e`/`log10e`
    plus 25 host-bound fns + 5 pure-botopink derivations (`ceil`/`sign`/
    `cbrt`/`hypot`/`clamp`) covering arithmetic, rounding, powers, logs,
    and trigonometry. Rounding family returns `f64` (host APIs already
    return floats; staying in `f64` keeps the i32/i64 unifier out of
    pure-botopink chains).
  - `asserts` — runtime assertions (`truthy`/`falsy`/`equal<T>`/
    `notEqual<T>`/`approxEqual`/`contains`) + `record AssertError {
    message, file, line }` (`std-expansion-tail` F4.asserts) for
    structured failure shaping by the test runner. Pure botopink +
    `@panic` on failure — wat-safe. Named `asserts` (plural) because
    `assert` is a reserved keyword statement. `throws(body, message)`
    and `matches(pattern, actual)` remain deferred: `throws` needs §A3
    `#[@result] declare fn` for a host-level try/catch wrapper,
    `matches` needs §F7 `regex.test`.
  - `path` — posix forward-slash path manipulation (`split`/`isAbsolute`/
    `basename`/`dirname`/`extname`/`join`/`normalize`/`relative(src, dst)`/
    `resolve(segments)` + `separator`/`delimiter` constants). Pure
    botopink — wat-safe. `relative`/`resolve` (`std-expansion-tail`
    F4.path) use explicit head/tail recursion over the split parts so the
    `var` + `push` Erlang dead-store trap never fires; `relative` takes
    `(src, dst)` because `from` is the import keyword and does not parse
    as a parameter name.
  - `random` — `float()` (uniform `[0, 1)`), `coin()`, `bool()` (alias
    for `coin`), `pick<T>(xs)`, `intInRange(lo, hi)` (closed interval).
    Lowers to `Math.random` / `rand:uniform/0`. `shuffle<T>` + `seed`
    deferred (`std-expansion-tail` F4.random): `shuffle` needs an
    option-unwrap with a generic default; `seed` needs sidecar-shipped
    Mulberry32 on Node (lands with F2).
  - `querystring` — form-urlencoded `parse(query)` and `stringify(pairs)`.
    Pure botopink — wat-safe. URI percent-encoding deferred until
    `prim-op-annotation` lands the richer `#[@External.<targert>(...)]` template grammar.
  - `time` — `nowMillis()` returns Unix epoch milliseconds. Lowers to
    `Date.now(1000)` on Node (variadic ignores the arg) and
    `erlang:system_time(1000)` on Erlang (integer divisor selects the
    millisecond unit). `monotonicMillis()` and `measureMillis<T>(body)`
    (`std-expansion-tail` F4.time) extend the surface — `monotonicMillis`
    lowers to `erlang:monotonic_time(1000)` on Erlang and falls back to
    `Date.now(1000)` on Node until §A2 wires commonJS to consume
    per-callee templates (the receiver-bound `performance.now($0)`
    shape); `measureMillis` is pure botopink, composing two `nowMillis`
    reads around the body. `sleep` and `formatIso8601` remain deferred:
    both need either a chained host-call template (§A2) or
    `#[@future] declare fn` template ownership (§A3).
  - `url` — `record Url { scheme, user, password, host, port, path, query,
    fragment }` + `parse(s)` + `serialize(u)`. Pure botopink — wat-safe.
    Round-trip closed in bot-lang `5788bd7` (the prior `serialize`
    deferral lifted; see
    `tasks/v0.beta.19/specs/std-expansion-tail.md`).
  - `base64` — `encode(s)` / `decode(b)` + url-safe variants
    `encodeUrlSafe`/`decodeUrlSafe` (`std-expansion-tail` F5.base64).
    Node lowers via the §A2 chained-host-call template
    `Buffer.from($0, 'utf8').toString('base64')`; Erlang lowers to the
    `base64:encode/1`/`decode/1` BIFs. URL-safe variants are pure
    botopink — substitute `+`→`-`, `/`→`_`, drop `=` padding on encode;
    reverse + tail-recursive `padToMultipleOfFour` on decode.
  - `unicode` — `fromCodepoint(cp)` + `firstCodepoint(s)` (`std-expansion-tail`
    F7.unicode). Node: `String.fromCodePoint($0)` + `($0.codePointAt(0)
    ?? 0)`. Erlang: `unicode:characters_to_binary([$0], utf8)` +
    `unicode:characters_to_list`. `normalize(form)` + `codepoints(s)`
    deferred — `NormalizationForm` enum spans 4 flavors that don't
    compose under a single template without arity-on-enum dispatch.
  - `process` — `exit(code)` / `cwd()` / `platform()` / `arch()` /
    `pid()` (`std-expansion-tail` F6.process). Node lowers via §A2
    templates (`process.exit($0)`, `process.cwd()`, bare
    `process.platform` / `process.arch` / `process.pid` properties);
    Erlang uses `erlang:halt/1` for `exit` + arity-branched 0-arg
    templates for the rest (`file:get_cwd`/`os:type`/`erlang:system_info(system_architecture)`/`os:getpid`).
  - `os` — `hostname()` / `arch()` / `cpuCount()` / `tmpdir()`
    (`std-expansion-tail` F6.os). Node inlines `require('os')` per
    call (cheap — Node caches the require); Erlang uses `inet:gethostname/0`
    + `erlang:system_info(system_architecture)` +
    `erlang:system_info(schedulers_online)` + `os:getenv("TMPDIR")`
    with a `/tmp` fallback. `userInfo()` + `eol()` deferred — shape
    mismatch across backends isn't worth the wrapper churn yet.
  - `env` — `read(name) -> ?string` / `write(name, value)` /
    `clear(name)` (`std-expansion-tail` F6.env). Named `read`/`write`/
    `clear` rather than the spec's `get`/`set`/`unset` because
    `get`/`set` are reserved tokens (parser `isMemberName` — soft
    keywords introducing struct getters/setters). Node: `process.env[$0]`
    lookup with `?? null` for unset; assignment + `delete` for
    write/clear. Erlang: `os:getenv` → `false`→`undefined`,
    `os:putenv` + `os:unsetenv`. `args()` + `vars()` deferred —
    enumeration shapes differ cross-backend.
  - `crypto` — `sha256(data)` / `sha512(data)` / `md5(data)` /
    `hmacSha256(key, data)` (`std-expansion-tail` F8.crypto). All
    return hex-string digests (the canonical interchange shape).
    Node lowers via chained §A2 templates
    `require('crypto').createHash('<alg>').update($0).digest('hex')`
    and `createHmac('sha256', $0).update($1).digest('hex')`; Erlang
    uses `crypto:hash/2` + `crypto:mac(hmac, …)` hex-encoded via
    `io_lib:format("~2.16.0b", [B])` over `binary_to_list/1`.
    `randomBytes(n)` deferred — host's secure-random surface lifts
    to a byte-array return shape that crosses awkwardly without
    sidecars.
  - `regex` — `matches(pattern, input) -> bool` / `replace` /
    `replaceAll` / `splitOn` (`std-expansion-tail` F7.regex). Named
    `matches` rather than the spec's `test` because `test` is a
    reserved keyword. Node: chained §A2 templates over `new RegExp(...)`
    + `String.prototype.replace`/`split`. Erlang: `re:run`/`re:replace`/
    `re:split` with `{return, binary}` keeping the output a binary
    list. Patterns follow the host's native flavour (ECMAScript on
    Node, PCRE on Erlang). `record Match { value, index }` +
    `match`/`matchAll` deferred — per-backend position extraction
    diverges.

- **`#[@External.<targert>(...)]` template grammar for primitive-method lowering**
  (`prim-op-annotation` v0.beta.19)
  - `#[@External.<target>( "<template>")]` accepts a single template
    string with `$self` (the receiver expression) and `$0..$N` (positional
    argument N) substitution markers. Other bytes pass through verbatim
    as target syntax. Discriminator: any `$` byte. The legacy 3-arg form
    `#\[@External\.target("module", "symbol(args)")]` is unchanged.
  - The shared renderer lives at
    `modules/compiler-core/src/comptime/primOpTemplate.zig`. Backends
    detect the new form via `looksLikeTemplate(symbol)` and call
    `render(template, ctx)` where `ctx` is the backend-supplied emitter
    context exposing `writeByte` / `emitRecv` / `emitArg`.
  - **Arity branching** — `when(argc == N): "<template>"` clauses inside
    an `#[@External.<targert>(...)]` select a template body by call-site argument count.
    The predicate spells `argc` (no `$` sigil — the botopink lexer
    rejects bare `$` outside a string literal).
  - **Triple-quoted raw strings** — `"""…"""` carries the template body
    when it contains `"` (e.g. `Array.join`'s `io_lib:format("~p", …)`).
    The "indent the block" convention strips one leading newline after
    `"""` and one trailing newline before `"""`; inner indentation is
    preserved.
  - **Erlang backend migrated** for `Bool.negate`, `Array.{contains,
    isEmpty, push, append, prepend, indexOf, at, slice, join}`,
    `String.{contains, startsWith, split, slice}` — 14 of 15
    `emitPrimMethod` method-row switch arms in `codegen/erlang.zig`
    are gone; output is byte-identical at every site. Only the
    val-property method form `Array.{length, len, size}` stays on the
    inline switch (the `val length: i32` declaration is property-shaped,
    not method-shaped — needs a separate property-bridge annotation).
  - **BEAM, commonJS, wat backends not yet migrated.** BEAM's
    `tryEmitPrimAnnotation` short-circuits on template-form entries so
    its inline switch keeps owning the lowerings — byte-identical
    behaviour preserved while we land the erlang half.

### Changed (breaking)

- **BREAKING: unused stdlib builtins removed** — frente-a-compiler §U
  - 15 standalone fns and 1 interface in `libs/std/src/builtins.d.bp` had
    **zero authored callers** across `repository/**.{bp,d.bp}` at audit
    time (2026-06-13, re-verified at execution). Removed: `typeOf`,
    `typeName`, `sizeOf`, `alignOf`, `hasField`, `hasDecl`, `tagName`,
    `min`, `max`, `abs`, `as`, `block`, `src`, `compilerError`,
    `embedFile`, `root`, plus `pub interface AsyncIterable<T, E>`. The
    `@<tag>` capture forms (`@AsyncIterable`, `@src`, `@root`,
    `@embedFile`, `@compilerError`, `@as`, plus the capture-tag forms of
    `@trap` / `@module` whose fn counterparts are retained) follow the
    same removal — parser-driven via the underlying fn surface. The
    inference handler arms in `comptime/infer.zig` that resolved their
    return types are deleted; orphan section headers in `builtins.d.bp`
    are removed. **Kept** (non-trivial demand at audit time): `field`,
    `trap`, `module`, `external`, `panic`, `todo`, `emit`, and the six
    `#[@<effect>]` annotations (effect tags are owned by Frente B).
- **BREAKING: `*fn` prefix removed** — frente-a-compiler §S
  - The `*fn` async/generator prefix was deprecated in v0.beta.12 (when
    `#[@<effect>]` annotations took its place byte-identically) and is now
    hard-removed: the parser rejects `*fn` at every site (top-level decl,
    `val name = *fn`, anonymous `*fn(...)` expression) with an
    `error[deprecated-star-fn]` diagnostic that maps the return wrapper to
    its replacement annotation (`@Future<…>` → `#[@future]`, `@Result<…>` →
    `#[@result]`, `@Iterator<…>` → `#[@iterator]`,
    `@AsyncIterator<…>` → `#[@asyncGenerator]`, `@Generator<…>` →
    `#[@generator]`, `@Context<…>` → `#[@context]`). `EffectKind.fromStarReturn`
    and the lambda `isStarFn` AST field were deleted; the formatter, inference,
    and codegen no longer carry the legacy carrier. The codegen `%% *fn
    (async/generator) — eager lowering` markers were rewritten to `%% #[@future]
    / #[@asyncGenerator] — eager lowering`. Anonymous async/generator
    expressions (`val producer = *fn(n) { yield n; };`) are no longer
    expressible — there is no anonymous-fn syntax for effect annotations.

- **Explicit module system** (`mod` / `pub mod`, Rust-style) — module-system
  - A package now declares its module tree explicitly from a root
    (`main.bp` for a binary, `root.bp` for a library — `botopink.json` `entry`
    chooses, auto-detected as `main.bp` then `root.bp`) by following `mod` /
    `pub mod` declarations, instead of the compiler implicitly compiling every
    `.bp` under `src/`. `mod` is now a reserved keyword.
  - `mod Name;` resolves a sibling `Name.bp` **or** a folder index `Name/mod.bp`
    (exactly one — both/neither is an error). A `.bp` not reached through any
    `mod` path is reported **orphaned** and is not compiled.
  - **Path-visibility**: an import may cross into a module only if every `mod`
    on its path is `pub mod`; a private `mod` is reachable only within its
    declaring module's subtree. An `import … from "a.b"` that names a package
    module must publicly export the symbol.
  - **Migration**: packages without a `main.bp`/`root.bp` root still build via
    the legacy implicit `src/` scan, now **deprecated** behind a warning, to be
    removed in a future release. Add a root with `mod` declarations to opt in.

### Added

- **Record / array ergonomics for the UI framework** (jhonstart-language-gaps)
  - Records carry **function-typed fields** (`record State<T> { value: T, set: fn(next: T) }`);
    codegen stores the closure like any field.
  - `get` / `set` are **soft keywords** — usable as record field names,
    record-literal labels, destructuring names, member access, method-call
    names, and named-call labels (the hook shape `{ value, set }`, `s.set(x)`).
  - **Anonymous record types** as annotations / return types
    (`-> { value: T, set: fn(T) }`, `TypeRef.record_type` → structural `Type.record`).
  - A **function type returns an array** — `fn() -> T[]` (and `?T[]`, `T[][]`)
    parse + infer in any position (declaration, field, annotation).
  - **`Children` coercion**: an `Element[]` (any array), a single value
    implementing `@Context` (an `Element`), or a `string` coerces into a
    `Children`-typed parameter — the builder children model `div([a, b])` /
    `div(child)` / `div("text")`.

- **`@Result` / `@Option` method API** (stdlib)
  - `@Result<R, E>`: `.map`, `.flatMap`, `.unwrapOr`, `.isOk`, `.isError`.
  - `@Option<T>` (the canonical spelling of `?T`): `.map`, `.flatMap`, `.unwrapOr`.
  - Resolved by type inference and lowered inline per backend: `commonJS` and
    `erlang` emit the full form (`Ok`/`Error` tag match, option presence check);
    `beam` and `wasm` emit a documented stub.
  - Documented in `libs/std/src/builtins.d.bp`.
- **Method calls on expressions** — `CallExpr.receiver` is now an expression, so
  method chains (`a().map(f).unwrapOr(0)`) and zero-arg method calls (`r.isOk()`)
  parse and type-check.

## v0.0.13-beta (May 2026)

### Highlights

- **`use` hook codegen (F8)**
  - `use` is now a prefix operator (`val {v, s} = use state(0)`); the AST node
    collapsed to `Expr.useHook { inner }` and binding moved to `val`/`var`.
  - CommonJS lowers hooks to React: `state`→`useState`, `memo`→`useMemo`,
    `effect`→`useEffect` (via the `"use"+Capitalize` convention), with an
    inferred dependency array for `memo`/`effect`. Erlang/BEAM/WAT lower `use`
    transparently into the binding's slot.
  - Phantom `@Context` base structs emit no runtime code; the `.d.ts` erases
    `@Context<B, R>` to its Return type `R`.
  - Parser fix: no-param trailing lambdas `{ -> … }` now consume their arrow.
- **`try` / `catch` lower to `Ok`/`Error` pattern matching**
  - Across all four backends (commonJS, erlang, beam, wasm), `try`/`catch` now
    lower to a pattern match on the `@Result` tag instead of host exceptions
    (no JS `try/catch`, no Erlang `try…catch`, no BEAM `try`/`try_case`).
  - `try expr` propagates the `Error` variant via an early return (Erlang nests
    the remainder of the body inside the `{ok, V}` arm); `try expr catch h`
    keeps the `Ok` value or applies the handler (lambda handlers receive the
    unwrapped error).
  - Applying `try`/`catch` to a non-`@Result` value is now a compile-time error
    (`try on non-Result`).

- **Expression-flow refactor across compiler-core** (`b86c5de`)
  - `ast.ExprOf(phase)` now uses categorized families:
    `literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `call`, `function`, `collection`, `comptime_`.
  - Parser, formatter, comptime transform/specialization, JS/Erlang runtimes, and LSP integration were updated to the new shape.
  - Legacy variants such as `controlFlow`/`staticCall` are no longer active in the main AST flow.
- **Snapshot baseline refresh** (`b86c5de`, `e61ba77`)
  - Parser, comptime, and codegen snapshots were regenerated to match Zig `0.16.0` behavior and the new AST shape.
  - Obsolete snapshot files were removed where test semantics changed.
- **Codegen/runtime cleanup**
  - Runtime execution helpers are now centralized under `modules/compiler-core/src/codegen/runtime.zig`.
  - Stale path `modules/compiler-core/src/codegen/d` was removed from tracked sources.

### Maintenance

- **Ignore generated static library artifacts** (`e98f4f5`)
  - Added ignore rule for `format.o*.a` to avoid polluting commits with local Zig artifacts.

### Compatibility context in this release line

- `787e5c0` — Zig `0.16.0` compatibility and parser consistency fixes.
- `9b93b5c` — removed `staticCall` and aligned compiler/LSP code paths for Zig `0.16`.

## v0.0.12-beta (April 2026)

- Added full `language-server` module with diagnostics, hover, definition, references, rename, signature help, inlay hints, and formatting.
- Standardized parser parameter typing around `TypeRef`.
- Unified workspace build flow for compiler CLI + language server.
- Improved comptime/LSP resilience for incomplete sources.

## v0.0.11-beta (April 2026)

- Consolidated allocator style to **never store, always pass** in parser/codegen APIs.
- Added Erlang code generation backend parity and snapshot coverage improvements.
- Added/expanded language features including pipeline (`|>`), anonymous `fn` expressions, and richer pattern matching snapshots.
