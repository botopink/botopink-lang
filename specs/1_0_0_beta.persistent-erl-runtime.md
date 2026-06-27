# Replace wasm3 comptime runtime with persistent Erlang subprocess

**Version:** 1.0.0-beta
**Status:** awaiting execution
**Created:** 2026-06-27
**Author:** ericfillipe

---

## Status

> The overall status tracks the spec lifecycle independently of individual steps:
> - **planning** — spec is being drafted, scope still under definition
> - **awaiting execution** — spec is ready, waiting to be picked up
> - **completed** — all steps are `completed`
> - **cancelled** — spec discarded (explicit cancel decision)

**Current:** awaiting execution

| Step   | Title                                      | Status    | Assignee |
|--------|--------------------------------------------|-----------|----------|
| Step 1 | Revert AtomVM vendoring and build wiring   | pending   |          |
| Step 2 | Create persistent erl host layer           | pending   |          |
| Step 3 | Switch comptime eval to persistent erl     | pending   |          |
| Step 4 | Replace inline WAT prelude with Pure Erlang| pending   |          |
| Step 5 | Migrate template/decorator eval to erl     | pending   |          |
| Step 6 | Remove wasm3 module and WAT runtime files  | pending   |          |
| Step 7 | Verify snapshots and full test suite       | pending   |          |

## Objective

Replace the embedded [wasm3](https://github.com/wasm3/wasm3) WebAssembly
interpreter (vendored at `modules/wasm3/`) with a **persistent `erl`
subprocess** — a long-lived Erlang/OTP VM spawned once at compiler startup
that executes BEAM bytecode for all comptime evaluations. Communication via
stdin/stdout JSON-line protocol.

The current pipeline lowers comptime `.bp` expressions to **WAT** (WebAssembly
Text), compiles WAT → binary WASM via a hand-rolled `wat_to_wasm.zig`, and
executes the module inside wasm3. The WAT prelude (`wat_runtime.zig`) contains
~160 lines of inline WAT for infrastructure (bump allocator, fd_write, error
handling, descriptor walkers) that `.bp` cannot express today.

By switching to persistent `erl`, the comptime pipeline becomes:

```
.bp comptime code → BEAM codegen (beam_asm.zig) → BEAM bytecode
                                                       ↓
                                    ┌──────────┐  stdin: "eval <beam_path>\n"
                                    │   erl    │ ←──────────────────────
                                    │(persist.)│
                                    └──────────┘  stdout: "<json>\n"
                                                       ↓
                                                   results
```

This eliminates the WAT prelude entirely: the existing `beam_asm.zig` and
`erlang.zig` codegen backends already lower `.bp` to BEAM, so comptime
expressions reuse the same path. Infrastructure that was hand-written in
WAT moves to **Pure Erlang** running inside the persistent `erl` process.
No C FFI, no vendored VM, no platform portability matrix.

**Why not AtomVM in-process?** AtomVM was evaluated and partially implemented
(Steps 1-4 of the original spec) but has blockers that make persistent `erl`
the pragmatic choice:

| Blocker | AtomVM | Persistent erl |
|---|---|---|
| `io:format` / stdlib | Needs estdlib bundling (~200 LOC shim) | Built-in |
| stdout capture | Needs dup/pipe shim in C FFI | `io:format` → stdout → pipe |
| Windows support | No platform layer (generic_unix only) | Full OTP support |
| Descriptor walkers | Need NIF registration in C | Pure Erlang |
| C FFI surface | ~40 C sources, `extern fn`, opaque pointers | Zero |
| Build complexity | Link C sources + libc + libm + pthreads | Zero |
| Debug | Segfault kills compiler | Stack trace in stderr |

**Why not Node.js?** Current `template_eval.zig` defaults to Node.js
(`persistent_node.zig`) for template/decorator evaluation. Consolidating
on `erl` means one runtime for everything — comptime vals, templates,
decorators — all share the same BEAM pipeline and the same persistent
process.

## Prerequisites

- `erl` and `erlc` on `PATH` (Erlang/OTP ≥ 24). Already documented in
  `AGENTS.md` as a requirement for `test-backends` and `test-libs --target
  erlang` — no new dependency.
- The BEAM codegen backend (`beam_asm.zig`) must be complete enough to lower
  all comptime expressions (literals, binary ops, collections, jumps,
  comptime blocks).
- The Erlang codegen backend (`erlang.zig`) must be complete enough to lower
  template/decorator bodies for the persistent erl path.

## Steps

Each step must be atomic and verifiable. Use the following statuses:

- **pending** — not started yet
- **open** — in progress
- **completed** — finished successfully
- **cancelled** — discarded (include the reason)

### Step 1 — Revert AtomVM vendoring and build wiring

**Status:** pending
**Assignee:**

**Description:**
The original Steps 1-4 introduced AtomVM vendoring (`modules/atomvm/`),
build graph wiring (`-Datomvm` flag, `atomvm.link()`, `atomvm.exposeHeaders()`),
and an `atomvm_host.zig` stub. This step undoes that work:

- Delete `modules/atomvm/` — entire directory
- Remove all `atomvm.link()` and `atomvm.exposeHeaders()` calls from
  root `build.zig`
- Remove `-Datomvm` build option and `build_options.use_atomvm` flag
- Delete `modules/compiler-core/src/comptime/runtime/atomvm_host.zig`
- Remove `if (@import("build_options").use_atomvm)` branching in
  `eval.zig:47` and `tests.zig:29`

The `beam.zig` file from original Step 4 is **kept** — it generates
Erlang source and spawns `erlc`/`erl` as subprocesses. It serves as
the starting point for Step 3.

**Acceptance criteria:**
- `modules/atomvm/` no longer exists
- `zig build` succeeds without AtomVM references
- No `use_atomvm` or `-Datomvm` in the codebase
- `beam.zig` still compiles and its unit tests pass

### Step 2 — Create persistent erl host layer

**Status:** pending
**Assignee:**

**Description:**
Create `modules/compiler-core/src/comptime/runtime/persistent_erl.zig` —
a Zig wrapper that spawns `erl` once and keeps it alive for the compiler
lifetime. Follows the same pattern as `persistent_node.zig` (the existing
Node.js persistent runner).

```zig
pub fn warm(allocator: std.mem.Allocator, io: std.Io) !void
pub fn eval(allocator: std.mem.Allocator, beam_path: []const u8) ![]u8
```

Internals:
- **Process-lifetime singleton** — same spinlock pattern as `wasm3_host`
  and `persistent_node`. Spawn `erl` once on first `warm()`, keep alive
  until process exit.
- **Server loop in Erlang** — the erl side runs a small receive loop:

```erlang
-module(botopink_comptime_server).
-export([start/0]).
start() ->
    case io:get_line("") of
        eof -> ok;
        "eval " ++ Path0 ->
            Path = string:trim(Path0),
            {ok, Mod, Beam} = compile:file(Path, [binary, return]),
            {module, _} = code:load_binary(Mod, "", Beam),
            Result = Mod:main(),
            io:format("~s~n", [Result]),
            start();
        "ping" ++ _ ->
            io:format("pong~n"),
            start()
    end.
```

- **Communication protocol:**
  - Zig → erl: `eval /tmp/comptime_<hash>.erl\n` via stdin
  - erl → Zig: one JSON line on stdout, terminated by `\n`
  - `ping\n` → `pong\n` for health check on warmup
  - Stderr captured separately for crash diagnostics

- **BEAM bytecode cache** — keyed by Wyhash of comptime entries.
  `beam_asm.zig` emits BEAM bytes in-process; cache avoids re-emitting
  identical modules across calls. Cache lives in tmp dir, evicted by
  `clean-tmp`.

- **Crash recovery** — if `erl` exits unexpectedly, detect via broken
  pipe on next `eval()`, respawn, and retry. Surface the stderr as a
  compiler diagnostic.

**Important:** do NOT write raw BEAM assembly in Zig. The host layer
only manages the subprocess lifecycle and communicates via the line
protocol. All Erlang/BEAM code is generated by the existing
`beam_asm.zig` codegen backend (comptime vals) or `erlang.zig` backend
(templates/decorators).

**Acceptance criteria:**
- `persistent_erl.zig` compiles
- `warm()` spawns `erl`, receives `pong` on ping
- `eval()` sends `eval <path>\n`, receives JSON result, returns it
- `erl` crash → broken pipe detected → respawn → retry succeeds
- Output cache returns identical result for identical BEAM bytes
- Unit test: round-trip a trivial Erlang module that writes `{"ok":true}`

### Step 3 — Switch comptime eval to persistent erl

**Status:** pending
**Assignee:**

**Description:**
Update `beam.zig` (created in original Step 4) to use `persistent_erl.eval()`
instead of spawning `erlc` + `erl` per evaluation.

Current `beam.zig:run()`:
1. Generates Erlang source via `buildScript()`
2. Writes `.erl` file to tmp dir
3. Spawns `erlc` to compile `.erl` → `.beam`
4. Spawns `erl -noshell -run <mod> main -run init stop`
5. Captures stdout
6. Parses JSON

New flow:
1. Emits BEAM bytecode directly via `beam_asm.zig` (no `.erl` file needed)
2. Writes `.beam` bytes to tmp dir (needed because `erl` loads from path)
3. Calls `persistent_erl.eval("/tmp/comptime_<hash>.erl")` — the persistent
   process compiles (via `compile:file`) and executes in one round-trip
4. Parses JSON (unchanged `parseResults()`)

Wire the persistent path into `eval.zig:evaluate()` — it becomes the
**only** comptime eval path (no more wasm3, no more `-Datomvm` flag).

The `buildScript()` function in `beam.zig` is replaced by `emitBeam()`
that uses `beam_asm.zig` to produce BEAM bytecode directly instead of
Erlang source text.

**Acceptance criteria:**
- `beam.zig:emitBeam()` produces valid BEAM bytecode for all comptime
  entry types (literals, binary ops, collections, jumps, comptime blocks)
- `zig build test` passes the comptime eval test suite via persistent erl
- Results are byte-identical to the wasm3 path for all existing comptime
  snapshot tests (snapshots regenerated)
- No `erlc` or `erl` spawn in `beam.zig` — all through `persistent_erl`

### Step 4 — Replace inline WAT prelude with Pure Erlang

**Status:** pending
**Assignee:**

**Description:**
The WAT prelude in `wat_runtime.zig` (~160 lines of inline WAT for bump
allocator, descriptor walkers, error handling) must be replaced by a
**Pure Erlang prelude module** that runs inside the persistent `erl`
process.

Create `modules/compiler-core/src/comptime/runtime/erl_prelude.zig` that
embeds a static Erlang module (`botopink_comptime_prelude.erl`) compiled
to BEAM and loaded into the persistent `erl` at warmup time. The prelude
provides:

**Descriptor walkers** — ported from `wat_runtime.zig:rawInfra()`:
- `prelude__text(Descriptor) → string()` — extract text from descriptor binary
- `prelude__lookup(Descriptor, Name) → term()` — scope lookup by name
- `prelude__bindings(Descriptor) → [{string(), term()}]` — all bindings
- `prelude__context(Descriptor) → term()` — context object
- `prelude__parts(Descriptor) → [{kind, text}]` — parts list

**Error handling:**
- `prelude__failRaw(Message, Param, Span) → no_return()` — throws
  `{comptime_fail, Message, Param, Span}`
- `prelude__compilerError(Message) → no_return()` — throws
  `{comptime_error, Message}`

**Descriptor format** — the same binary layout currently emitted by
`wat_runtime.zig:appendDescriptorBytes()`:

```
[text-len: i32][text bytes...]
[file-len: i32][file bytes...]
[line: i32][col: i32][multiline: i32]
[scope-count: i32][scope-entry...]
  scope-entry = [name-len: i32][name bytes...][kind: i32]
[parts-count: i32][part-entry...]
  part-entry = [kind: i32][text-len: i32][text bytes...]
```

The prelude module is compiled once (via `erlc` at build time or at
first warmup) and loaded into the persistent `erl`. Template/decorator
bodies call into these functions directly as Erlang module calls.

**Acceptance criteria:**
- All 6 descriptor walkers produce identical results to the WAT versions
- `prelude__failRaw` surfaces error messages correctly via the line protocol
- No inline WAT remains in the comptime runtime directory
- `wat_runtime.zig:rawInfra()` is deleted
- Template prelude tests pass on the erl path

### Step 5 — Migrate template/decorator eval to persistent erl

**Status:** pending
**Assignee:**

**Description:**
Update `template_eval.zig` and `decorator_eval.zig` to use the persistent
erl path instead of Node.js (primary) and WAT (fallback).

Currently both have:
- `evaluateNode()` — assembles JS module + JS prelude, runs via
  `persistent_node.eval()`. Stable, covers all template bodies today.
- `evaluateWat()` — assembles WAT module + WAT prelude, runs via
  `wasm3_host.runWat()`. Returns `error.EvalFailed` so caller falls
  back to Node.js. Incomplete (stub descriptor walkers).

Replace both with `evaluateErl()`:
1. Lower template body to Erlang source via `erlang.zig` codegen
2. Merge with the Erlang prelude module (Step 4) — prelude functions
   are already loaded in the persistent erl, template body calls them
3. Write merged `.erl` file to tmp dir
4. Call `persistent_erl.eval(path)` — the persistent process compiles
   and executes
5. Parse the JSON output (same format as today)

Remove `evaluateNode()` and `evaluateWat()` functions. Delete
`persistent_node.zig` (already slated for removal in front 09).

The template outcome enum (`Outcome`) and result format stay unchanged —
only the evaluation backend changes.

**Acceptance criteria:**
- `evaluateErl()` runs template bodies end-to-end
- `__expr`, `__code`, `__capture`, `Span`, `CustomNode` constructors work
- `__failRaw` / `__compilerError` surface errors correctly
- Template snapshot tests pass on the erl path
- Decorator snapshot tests pass on the erl path
- `persistent_node.zig` is deleted
- No Node.js dependency for template/decorator evaluation

### Step 6 — Remove wasm3 module and WAT runtime files

**Status:** pending
**Assignee:**

**Description:**
Once all tests pass on the persistent erl path, delete:
- `modules/wasm3/` — entire directory (~40 C sources)
- `modules/compiler-core/src/comptime/runtime/wasm3_host.zig`
- `modules/compiler-core/src/comptime/runtime/wat_runtime.zig`
- `modules/compiler-core/src/comptime/runtime/wat_to_wasm.zig`
- `modules/compiler-core/src/comptime/runtime/wasm.zig`
- `modules/compiler-core/src/comptime/runtime/persistent_node.zig`
- All `wasm3.link()` and `wasm3.exposeHeaders()` calls in `build.zig`

Update `modules/compiler-core/src/comptime/runtime/AGENTS.md` to document
the new persistent-erl-based architecture.

Update `modules/compiler-core/src/comptime.zig` — remove
`warmWasm3Runtime()`, add `warmErlRuntime()`.

**Acceptance criteria:**
- `zig build` succeeds without wasm3
- `zig build test` passes 100%
- No references to wasm3 or Node.js runtime remain in the codebase
- Runtime AGENTS.md reflects the persistent-erl architecture
- ~80 C source files removed from repository (wasm3 + atomvm)

### Step 7 — Verify snapshots and full test suite

**Status:** pending
**Assignee:**

**Description:**
Run the complete test matrix and regenerate all affected snapshots:
```bash
zig build test           # compiler-core + language-server + cli
zig build test-libs      # all libs/* packages on every backend
zig build test-backends  # BEAM/WASM/Erlang execution parity
```

Regenerate comptime snapshots under the new `erl` path. Snapshot files
must be byte-identical to the wasm3 output for all existing comptime
value evaluations. Template and decorator snapshots may differ in format
but must produce semantically equivalent results.

Update CI workflows if needed (`.github/workflows/test.yml`) — `erl` must
be installed on CI runners (already present for `test-libs --target
erlang`).

**Acceptance criteria:**
- Full test suite passes on all 3 platforms (Linux, macOS, Windows)
- Comptime snapshots regenerated and committed
- CI green

---

## Scope

This spec changes **only** the comptime evaluation runtime — the in-process
engine that executes `.bp` expressions at compile time (comptime blocks,
template bodies, decorator bodies). Every codegen backend stays exactly as
it is today:

| Backend       | File                        | Affected? |
|---------------|-----------------------------|-----------|
| commonJS      | `codegen/commonJS.zig`      | No        |
| TypeScript    | `codegen/typescript.zig`    | No        |
| Erlang        | `codegen/erlang.zig`        | No        |
| BEAM          | `codegen/beam_asm.zig`      | No        |
| WASM          | `codegen/wat.zig`           | No        |

The BEAM codegen backend (`beam_asm.zig`) is **reused** by the comptime
runtime to lower `.bp` expressions to BEAM bytecode, but the backend itself
is unchanged — it continues to serve user-facing `botopink build --target
beam` as before.

What changes:
- `comptime/runtime/` — wasm3 host + WAT prelude → persistent erl host +
  Pure Erlang prelude
- `modules/wasm3/` → deleted (vendored interpreter removed)
- `build.zig` — no longer links wasm3 or AtomVM
- External dependency: `erl` on `PATH` (already required for `test-backends`)

What does NOT change:
- User-facing codegen (all 5 targets produce identical output)
- Stdlib compilation (same `.bp` → same output per target)
- LSP analysis (comptime values are opaque to the LSP regardless of runtime)
- Snapshot format for non-comptime codegen tests

---

## Erlang subprocess vs. AtomVM in-process

The original spec targeted AtomVM as an in-process embedded VM. That path was
partially implemented (Steps 1-4) but had blockers that made persistent `erl`
the pragmatic choice:

### Advantages of `erl` subprocess (chosen path)

| Advantage | Detail |
|---|---|
| **Full OTP stdlib** | `io:format`, `lists`, `string`, `proplists` and every other OTP module available without any bundling work |
| **Battle-tested compiler** | `erlc` produces spec-compliant BEAM bytecode; no risk of codegen mismatches between `beam_asm.zig` and what the VM expects |
| **Works today** | Zero estdlib bundling, zero NIF shims — the existing `beam.zig:buildScript` generates valid Erlang |
| **Cross-platform now** | Erlang/OTP runs on Linux, macOS, and Windows today; AtomVM's `generic_unix` platform layer has no Windows support |
| **Process isolation** | A comptime module crash kills the child `erl`, not the compiler |
| **Debuggability** | The generated `.erl` file is inspectable and runnable manually |
| **No C FFI surface** | stdin/stdout line protocol — no `@cImport`, no opaque pointers, no `extern fn` declarations |
| **Removes ~80 C sources** | wasm3 (~40) + atomvm (~40) = ~80 vendored C files deleted from repository |

### Advantages of AtomVM in-process (rejected)

| Advantage | Detail |
|---|---|
| **No external dependency** | Statically linked, no `erl` on `PATH` |
| **Latency** | No subprocess communication overhead |
| **Single binary** | Self-contained executable |

### Why persistent erl wins

The latency gap (~0.2ms per eval for persistent erl vs ~0.03ms for AtomVM)
is **irrelevant** — comptime eval is < 2% of total compile time. The ~80
vendored C sources, C FFI surface, estdlib bundling, and missing Windows
support make AtomVM a net loss in maintainability for a gain the user
cannot measure.

---

## Spawn latency mitigation

The original Step 4 spawned `erlc` + `erl` per evaluation — two `fork`/`exec`
cycles (~50ms). The persistent erl approach eliminates this completely:

```
BEFORE (Step 4 original):          AFTER (persistent erl):
                                    ┌──────────┐
   buildScript() → .erl file        │   erl    │  spawned once at startup
        ↓                           │(persist.)│
   spawn erlc → .beam file          └────┬─────┘
        ↓                                │
   spawn erl -run main                   │ eval /tmp/foo.erl\n
        ↓                                ↓
   capture stdout                   [compiles, runs, returns JSON]
        ↓                                ↓
   parse JSON                       parse JSON
```

Per-evaluation latency: **~50ms → ~2ms** (25x improvement). Single `fork`/`exec`
at compiler startup, zero per evaluation.

### BEAM bytecode cache

On top of persistent erl, cache BEAM bytecode keyed by Wyhash of comptime
entries. `beam_asm.zig` emits BEAM bytes in-process — skip emission entirely
on cache hit, just write cached bytes to tmp dir. Cache lives in
`.botopinkbuild/tmp/`, evicted by `clean-tmp`.

---

## NIF analysis

The persistent erl path implements descriptor walkers in **Pure Erlang** —
zero C FFI, zero Zig↔Erlang boundary. NIFs (Zig → `.so` → erl) were
evaluated and rejected:

| | NIFs | Pure Erlang (chosen) |
|---|---|---|
| **Latência** | Sub-microsecond | JSON serialize + parse por chamada |
| **Build** | `.so`/`.dylib`/`.dll` + `erl_nif.h` + Zig cross-compilation | Zero |
| **Debug** | Segfault mata `erl`, estado Zig opaco | Stack trace Erlang legível |
| **Portabilidade** | 3 caminhos de build por plataforma | Idêntico em toda plataforma |
| **Manutenção** | Binding manual `enif_get_tuple`, `enif_get_list_cell`, … | Tipos nativos, sem tradução |

NIFs só se justificariam se JSON serialization dominasse o tempo total de
compilação — improvável considerando que parsing + inferência + codegen são
o gargalo real.

---

## Runtime tree (target state)

```text
runtime/
├── AGENTS.md              ← updated: persistent-erl architecture
├── persistent_erl.zig      ← NEW: erl subprocess singleton + line protocol
├── beam.zig               ← updated: uses persistent_erl.eval()
├── erl_prelude.zig         ← NEW: embeds Erlang prelude module (descriptor
│                             walkers, error handling, constructors)
├── wat_runtime.zig         ← DELETED
├── wat_to_wasm.zig         ← DELETED
├── wasm3_host.zig          ← DELETED
├── wasm.zig                ← DELETED
├── persistent_node.zig     ← DELETED (was already slated for front 09)
└── atomvm_host.zig         ← DELETED (reverted from original Step 3)
```

---

## Notes

- `erl` is already a documented dependency for `test-backends` and
  `test-libs --target erlang` — no new requirement.
- `persistent_node.zig` was already slated for removal (front 09); this
  spec includes it in the cleanup step since the erl path replaces it.
- The `template_runtime.bp` stdlib module's methods marked `#[@Host]`
  today (lookup, bindings, context, parts, failRaw, compilerError) become
  calls into the Pure Erlang prelude module.
- The `wat_to_wasm.zig` pure-Zig WAT compiler (~600 LOC) is also removed.
  The BEAM codegen backend (`beam_asm.zig`) already exists and is tested —
  no new compiler needs to be written.

---

## Changelog

| Date       | Change                             | Author      |
|------------|------------------------------------|-------------|
| 2026-06-27 | Spec created (AtomVM target)       | ericfillipe |
| 2026-06-27 | Rewritten: persistent erl subprocess replaces AtomVM in-process | ericfillipe |
