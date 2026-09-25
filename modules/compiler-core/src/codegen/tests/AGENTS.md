# compiler-core/src/codegen/tests

> Path: `modules/compiler-core/src/codegen/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Codegen tests, split by feature (`values.zig` etc. for codegen, `wat.zig` for the
WAT backend, `externals.zig` for `#[@External.<Target>(…)]` FFI declarations,
`comptime_module.zig` for `erlang.emitComptimeModule`). Aggregated by the
sibling barrel `../tests.zig` for `test_root.zig`; shared harness
(`assertJs`/`assertJsError`/`configs`) lives in `helpers.zig`.
Snapshots are recorded per comptime runtime (front 18 step 4, decision 85):
`helpers.runtimes` lists them (`beam`, `wat`), `snapshot_configs` (every target) and
`test_mode_configs` (commonJS + erlang) are `configs` once per runtime with
`comptime_runtime` set, and a fixture lands at
`snapshots/codegen/<runtime>/<target>/<slug>.snap.md`
(`codegen/<runtime>/errors/<target>/` for `assertJsError`).
Every harness compile goes through `helpers.generate` — `codegen.generate`
with **every comptime evaluation run on both runtimes** (front 18,
`comptime/runtime/runtime.zig` `parity`): the fixture's runtime answers and the
other one is asked the same question; a difference fails the fixture as
`error.ComptimeRuntimeParity` with both answers printed. So each of the 33
fixtures with a `COMPTIME REPLY` is also a parity check between the BEAM and
the wat runtime.
`assertJsRunLog(src, expected)` compiles `src` for commonJS, runs it and
compares the entry's RUN LOG — for behaviour that lives in a sibling module
(`std/<mod>.js`) a single-module snapshot does not show.
`assertErlangRunLog(src, expected, needles)` is its erlang twin (front
`02-erlang`): it compiles for the erlang target, compares the RUN LOG and then
checks the emitted erlang for each needle. It writes **no** snapshot, which is
the point — a defect that makes `erlc` refuse the module, or a pattern that
matches nothing, is only visible by running it, and a row whose §5.1 fixture
does not type-check yet still has a statement-position shape that compiles.
`assertErlangTestModeContains(src, present, absent)` compiles `src` in **test
mode** for erlang and checks the entry module's emitted code for each `present`
needle and against each `absent` one. For a claim about the emitted `botopink
test` runner's own preamble — whether `'__bp_load_siblings'/0` is emitted at
all, and what it does with a sibling `compile:file/2` refuses — which no
`test { }` block can observe from the inside and no snapshot of a green program
shows. Both live in `std_package.zig`.
For multi-module assertions without a snapshot, `assertConsumerJs(modules, present, absent)`
generates every module (last = consumer `main`) and checks the consumer's JS
contains/omits given substrings — used by the disk-lib namespace test in
`features.zig` (`import {Lib} from "Lib"` → `const Lib = require(...)`).
Golden outputs live in `modules/compiler-core/snapshots/codegen/<target>/<slug>.snap.md` (`commonJS`, `erlang`, `beam`, `wasm`), comptime validation errors in `codegen/errors/<target>/`.

`externals.zig` closes with the one test here that has no fixture of its own:
**`no prelude template calls the method it patches`** lexes and parses the
prelude the compiler EMBEDS (`@import("std_prelude").primitives`, not the file
on disk) and fails on any behavior method whose `#[@External.Node]` template
calls the method it is about to become a `<Owner>.prototype.<m>` patch for.
`String.charCodeAt` was exactly that, and it made every `.charCodeAt(…)` in any
program that installed the `String` prelude — one `s.slice(…)` is enough — blow
the stack. The rule was already written down in `libs/std/AGENTS.md`; this is
what holds it.
The four `codegen ---- use … is a plain call` cells of `features.zig` record decision 88 (1.0.10-beta, front 19): `val c = use state(0)` is `const c = state(0)` on commonJS, as it already was on erlang, beam and wasm — their components carry `#[@context]`, the effect that lets a body activate a hook. They replaced the `… to useState` / `… infers dependency array` / `… empty deps` cells, whose snapshots recorded the React rename.

`assertTestModeRunLog(src, expected)` compiles `src` in **test mode** for both
`botopink test` targets, runs each module the way the CLI does
(`runtime.executeTestModule`: `node main.js` / `escript main.erl`) and asserts the
runner's output — `duration` lines dropped — equals `expected` on both, whatever the
exit status. It exists for 1.0.10-beta decision 74: a failing test exits non-zero,
which `assertJsTestMode`'s RUN LOG records as empty, and the snapshot harness never
executes an erlang test module. The `@src()` fixtures (`src_*`,
`test_body_try_on_an_error_fails_the_test`, `unknown_builtin_*`) live in
`builtins.zig`; the located diagnostics use `assertJsCompileError`.

`assertWasmRunLog(src, expected)` is the wasm twin of `assertJsRunLog`, for the
programs an all-backend snapshot cannot hold: decision 8 §10's `break <value>`
out of a condition loop does not compile on erlang at all
(`ConditionLoopValueUnsupported`), so `assertJsSingle` aborts before it can
record wasm's answer. `wat.zig`'s `String.at` fixture uses it for the other
reason: the method already answers on the other three backends, so an
all-backend fixture would move their snapshot directories, which front `05-wasm`
does not own.

`assertBeamRunLog(src, expected, needles)` is the beam twin of
`assertErlangRunLog` (front `03-beam`): it compiles for the beam target,
assembles and runs every emitted `.S` (`runtime.executeBeamAsm`), compares the
RUN LOG and checks the emitted assembly for each needle. No snapshot, for the
same reason: a beam row whose erlang or wasm half has not landed would record
another front's wrong answer in another front's directory. The `case`-pattern
rows of `control_flow.zig` use it.

`assertJsExpecting`, `assertJsError` and `assertJsTestMode` wrap their snapshot calls in `utils/snap.zig` `traceEnter(loc)`/`traceLeave`, so `BOTOPINK_SNAP_TRACE=<file>` records the test `file:line` for every codegen snapshot. A new helper that writes a snapshot must do the same, or `scripts/snap_audit.sh --mode=review` cannot attribute it.

## Pass/fail contract (spec 06, H3/H9/H10)

- `assertJs` / `assertJsSingle` **compare every backend before failing** and
  return the first error at the end, so one suite round writes every
  `.snap.md.new` (H10). Same for `assertJsError` and `assertJsTestMode`.
- A module that does not compile (parse error, type error, or comptime
  validation error) **fails the test** with `error.ModuleDidNotCompile`, and the
  snapshot records a `----- COMPILE DIAGNOSTIC -- <module>` section instead of
  an empty code section (H3/H9). Before this, 29 slugs × 4 backends were 0-byte
  snapshots that compared empty with empty and passed.
- `assertJsRefusedOnWasm(alloc, @src(), src)` (and `assertJsExpecting(…,
  .refused_on_wasm)` for a multi-module program) is the opt-in for a program
  that compiles on commonJS, erlang and beam and is **refused on wasm** — a call
  to a host-backed `declare fn` that names another target and no `wasm` one,
  which decision 67 refuses at the call site instead of lowering to a run-time
  trap. The wasm snapshot records the located diagnostic as its
  `COMPILE DIAGNOSTIC` section; the other three backends still have to compile,
  and the test fails if wasm ever starts accepting the program. Ten
  `externals.zig` fixtures carry it. `collectCompileDiagnostics` recovers a
  **backend** refusal through `codegen.generateWith` (`generate` drops the
  module, and the comptime front end has nothing to say about it), so the
  section holds the real message and location rather than "no diagnostic
  available".
- `assertJsCompileError(alloc, @src(), src)` is the opt-in for a test whose
  point *is* that the program does not compile: it records the diagnostic and
  fails if the source ever starts compiling. Every call site carries a comment
  naming the missing feature and the spec that owns it (`DOCUMENTED SKIP —`).
- `assertJsError` stays the helper for comptime validation errors that have a
  dedicated `codegen/<runtime>/errors/<target>/` snapshot.

`wat.zig` also carries the decision 8 §5 `case` fixtures front `05-wasm` took
from the three defects `01-checker` handed to the backends — a variant pattern
written as a path, the dot shorthand, an arm body whose last expression is its
value, a one-parameter arm binder, and a failing guard. They snapshot all four
backends like every other fixture: wasm answers each of them, and the
`KNOWN-WRONG` note above each names what commonJS, erlang and beam still answer,
so the front that takes its half shows the move in its own commit.

When adding a test file here, register it in `../tests.zig` or it will not run.
