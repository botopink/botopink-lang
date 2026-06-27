# Replace wasm3 comptime runtime with AtomVM

**Version:** 1.0.0-beta                                                   <!-- canonical format; filename uses underscores: 1_0_0_beta.[name].md -->
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
| Step 1 | Vendor AtomVM as a Zig module              | completed |          |
| Step 2 | Wire AtomVM into the build graph           | completed |          |
| Step 3 | Port comptime runtime host layer           | pending   |          |
| Step 4 | Switch comptime codegen from WAT to BEAM   | pending   |          |
| Step 5 | Replace inline WAT prelude with BP/Zig     | pending   |          |
| Step 6 | Migrate template/decorator eval to BEAM    | pending   |          |
| Step 7 | Remove wasm3 module and WAT runtime files  | pending   |          |
| Step 8 | Verify snapshots and full test suite       | pending   |          |

## Objective

Replace the embedded [wasm3](https://github.com/wasm3/wasm3) WebAssembly
interpreter (vendored at `modules/wasm3/`) with
[AtomVM](https://github.com/atomvm/AtomVM) — a lightweight Erlang VM that
executes BEAM bytecode — as the sole in-process comptime runtime.

The current pipeline lowers comptime `.bp` expressions to **WAT** (WebAssembly
Text), compiles WAT → binary WASM via a hand-rolled `wat_to_wasm.zig`, and
executes the module inside wasm3. The WAT prelude (`wat_runtime.zig`) contains
~160 lines of inline WAT for infrastructure (bump allocator, fd_write, error
handling, descriptor walkers) that `.bp` cannot express today.

By switching to AtomVM, the comptime pipeline becomes:

```
.bp comptime code → BEAM codegen → BEAM bytecode → AtomVM interpreter → results
```

This eliminates the WAT prelude entirely: the existing `beam_asm.zig` and
`erlang.zig` codegen backends already lower `.bp` to BEAM, so comptime
expressions can reuse the same path. Infrastructure that was hand-written in
WAT moves either to `.bp` (preferred) or to the Zig host layer — never
directly to raw BEAM assembly.

## Prerequisites

- AtomVM must be embeddable as a C library (static or shared) and expose a
  C API for: create VM, load BEAM module, call exported function, capture
  stdout.
- AtomVM must support the Erlang/BEAM subset that `beam_asm.zig` emits
  (basic arithmetic, pattern matching, tuples, lists, atoms, binaries, tail
  calls, module functions).
- AtomVM must compile on Linux, macOS, and Windows (the wasm3 cross-platform
  matrix must be preserved).
- The BEAM codegen backend must be complete enough to lower all comptime
  expressions (literals, binary ops, collections, jumps, comptime blocks).

## Steps

Each step must be atomic and verifiable. Use the following statuses:

- **pending** — not started yet
- **open** — in progress
- **completed** — finished successfully
- **cancelled** — discarded (include the reason)

### Step 1 — Vendor AtomVM as a Zig module

**Status:** completed
**Assignee:**

**Description:**
Create `modules/atomvm/` following the same pattern as `modules/wasm3/`:
`AGENTS.md`, `README.md` (upstream pin), `LICENSE`, `build.zig` (exports
`link()` + `exposeHeaders()`), and vendored upstream `source/` tree.
Pin a specific AtomVM release tag.

The `build.zig` integration contract mirrors wasm3's:
- `exposeHeaders(b, mod)` — adds include path for `@cImport`
- `link(b, compile)` — adds C sources + libc to a Compile target

**Acceptance criteria:**
- `modules/atomvm/` directory exists with the standard module layout
- `build.zig` compiles when `@import`ed by the root build
- AtomVM C sources compile without warnings on all 3 platforms

### Step 2 — Wire AtomVM into the build graph

**Status:** completed
**Assignee:**

**Description:**
Replace every `wasm3.link(b, target)` and `wasm3.exposeHeaders(b, mod)` call
in the root `build.zig` with the AtomVM equivalents. Targets to update:
- `core_mod` (exposeHeaders)
- `core_tests` (link)
- `lsp_tests` (link)
- `cli_tests` (link)
- `cli_exe` (link)
- `lsp_exe` (link)

Do NOT remove wasm3 yet — keep both linked during the transition. Add a build
option flag (`-Datomvm`) to gate the new path so CI stays green while the port
is in progress.

**Acceptance criteria:**
- `zig build` succeeds with AtomVM linked alongside wasm3
- `zig build -Datomvm` enables the new code path
- No regressions in `zig build test` (wasm3 path still active by default)

### Step 3 — Port comptime runtime host layer

**Status:** pending
**Assignee:**

**Description:**
Create `modules/compiler-core/src/comptime/runtime/atomvm_host.zig` — the
Zig wrapper over AtomVM's C API, replacing `wasm3_host.zig`. It must expose:

```zig
pub fn runBeam(allocator: std.mem.Allocator, beam_bytes: []const u8) ![]u8
pub fn warm(allocator: std.mem.Allocator) !void
```

Internals:
- Process-lifetime VM singleton (same spinlock pattern as wasm3_host)
- Per-call fresh context: create VM → load BEAM module → call entry →
  capture stdout → destroy VM
- Output cache (same Wyhash + ring-buffer pattern as `OutCache`)
- BEAM bytecode cache (avoid recompiling identical modules)
- I/O shim: intercept Erlang's `io:format` / `io:put_chars` output
  and redirect to a capture buffer (analogous to the WASI `fd_write` shim)

**Important:** do NOT write raw BEAM assembly in Zig. The host layer only
manages the VM lifecycle and captures output. All Erlang/BEAM code is
generated by the existing `beam_asm.zig` codegen backend.

**Acceptance criteria:**
- `atomvm_host.zig` compiles
- `runBeam` loads a trivial hand-crafted BEAM module and captures its output
- `warm` pre-initializes the VM singleton without errors
- Unit test: round-trip a BEAM module that writes "hello" to stdout

### Step 4 — Switch comptime codegen from WAT to BEAM

**Status:** pending
**Assignee:**

**Description:**
Create `modules/compiler-core/src/comptime/runtime/beam.zig` (mirroring
`wasm.zig`) with:
- `buildScript(alloc, entries) ![]u8` — lowers `ComptimeEntry` list to a
  BEAM module (using `beam_asm.zig` codegen), wrapping results in a JSON
  array written to stdout via `io:format`
- `parseResults(alloc, data, out)` — same JSON parser as today (unchanged)

Wire it into `eval.zig:evaluate()` behind the `-Datomvm` flag. The BEAM
module's entry point (`_botopink_main` or equivalent) must:
1. Build the JSON array `[{"id":"...","value":...}, ...]`
2. Write it to stdout via `io:format("~s", [Json])`
3. Return cleanly

The `buildScript` function replaces the WAT `buildScript` in `wasm.zig` —
it emits BEAM bytecode instead of WAT text, reusing the existing
`beam_asm.zig` emitter and `erlang.zig` expression lowerer.

**Acceptance criteria:**
- `beam.zig:buildScript` produces valid BEAM bytecode for all comptime
  entry types (literals, binary ops, collections, jumps, comptime blocks)
- `zig build test -Datomvm` passes the comptime eval test suite
- Results are byte-identical to the wasm3 path for all existing comptime
  snapshot tests

### Step 5 — Replace inline WAT prelude with BP/Zig

**Status:** pending
**Assignee:**

**Description:**
The WAT prelude in `wat_runtime.zig` (~160 lines of inline WAT for bump
allocator, descriptor walkers, error handling) must be replaced. Two-tier
strategy:

**Tier 1 — move to `.bp`:** The `template_runtime.bp` stdlib module already
compiles to WAT via `compileBpBodies()`. With the BEAM codegen path, this
module compiles to BEAM natively. Extend it to cover the remaining
infrastructure that was hand-written in WAT:
- Bump allocator → implement in `.bp` using a mutable global
- `__failRaw` / `__compilerError` → BP functions that throw Erlang errors
- Descriptor walkers (`__str_eq`, `__capture__lookup`, `__capture__bindings`,
  `__capture__context`, `__capture__parts`) → BP functions operating on
  binary descriptor format (unwrap to Erlang terms at the edge)

**Tier 2 — Zig fallback:** Anything `.bp` genuinely cannot express (e.g.,
raw memory layout of the descriptor binary) stays in Zig but as clean
Erlang-term constructors, never as raw BEAM assembly. Host-provided
functions exposed to the BEAM module via AtomVM's foreign-function interface.

Delete `wat_runtime.zig:rawInfra()` entirely. The 3-layer prelude
architecture (rawInfra + compileBpBodies + merge) collapses to a single
BEAM module compiled from `template_runtime.bp` plus host-provided NIFs.

**Acceptance criteria:**
- No inline WAT remains in the comptime runtime directory
- `template_runtime.bp` compiles to BEAM and covers all infrastructure
- Descriptor walkers produce identical results to the WAT versions
- Template/decorator eval tests pass on the BEAM path

### Step 6 — Migrate template/decorator eval to BEAM

**Status:** pending
**Assignee:**

**Description:**
Update `template_eval.zig` and `decorator_eval.zig` to use the BEAM path
instead of the WAT path. Currently both have a `evaluateWat()` function
that assembles a WAT module (prelude + user body) and runs it via
`wasm3_host.runWat()`.

Replace with `evaluateBeam()`:
1. Compile `template_runtime.bp` → BEAM module (cached)
2. Compile user template body → BEAM functions
3. Merge both into a single BEAM module
4. Load into AtomVM via `atomvm_host.runBeam()`
5. Parse the JSON output (unchanged format)

Keep the Node.js fallback path active (`evaluateNode`) for templates that
the BEAM path cannot yet handle. Remove the WAT-specific `evaluateWat`
function.

**Acceptance criteria:**
- `evaluateBeam` runs template bodies end-to-end
- `__expr`, `__code`, `__capture`, `Span`, `CustomNode` constructors work
- `__failRaw` / `__compilerError` surface errors correctly
- Template snapshot tests pass on the BEAM path

### Step 7 — Remove wasm3 module and WAT runtime files

**Status:** pending
**Assignee:**

**Description:**
Once all tests pass on the AtomVM path and the `-Datomvm` gate is removed
(making AtomVM the default), delete:
- `modules/wasm3/` — entire directory
- `modules/compiler-core/src/comptime/runtime/wasm3_host.zig`
- `modules/compiler-core/src/comptime/runtime/wat_runtime.zig`
- `modules/compiler-core/src/comptime/runtime/wat_to_wasm.zig`
- `modules/compiler-core/src/comptime/runtime/wasm.zig`
- `modules/compiler-core/src/comptime/runtime/persistent_node.zig` — legacy
  Node runner (already slated for removal in front 09)
- All `wasm3.link()` and `wasm3.exposeHeaders()` calls in `build.zig`

Update `modules/compiler-core/src/comptime/runtime/AGENTS.md` to document
the new AtomVM-based architecture.

Update `modules/compiler-core/src/comptime.zig` — remove `warmWasm3Runtime()`,
add `warmAtomvmRuntime()`.

**Acceptance criteria:**
- `zig build` succeeds without wasm3
- `zig build test` passes 100%
- No references to wasm3 remain in the codebase (outside git history)
- Runtime AGENTS.md reflects the AtomVM architecture

### Step 8 — Verify snapshots and full test suite

**Status:** pending
**Assignee:**

**Description:**
Run the complete test matrix and regenerate all affected snapshots:
```bash
zig build test           # compiler-core + language-server + cli
zig build test-libs      # all libs/* packages on every backend
zig build test-backends  # BEAM/WASM/Erlang execution parity
```

Regenerate comptime snapshots under the new BEAM path. Snapshot files
must be byte-identical to the wasm3 output for all existing comptime
value evaluations. Template and decorator snapshots may differ in format
but must produce semantically equivalent results.

Update CI workflows if needed (`.github/workflows/test.yml`).

**Acceptance criteria:**
- Full test suite passes on all 3 platforms (Linux, macOS, Windows)
- Comptime snapshots regenerated and committed
- CI green

---

## Workflow

1. **Planning phase** — draft the spec steps and acceptance criteria. Status: `planning`.
2. **Ready** — change status to `awaiting execution`.
3. **Start execution** — the agent must ask for confirmation before proceeding. If confirmed, create a git worktree under `.spec/` and a branch named `spec/<filename>` (filename without `.md` extension). E.g.:
   ```
   git worktree add .spec/1_0_0_beta.atomvm-runtime -b spec/1_0_0_beta.atomvm-runtime feat
   ```
4. **Work through steps** — update each step's status as you go (`pending` → `open` → `completed`).
5. **Finish execution** — once all steps are `completed`:
   - Update the spec status to `completed`.
   - Merge the worktree branch into the remote version branch. If this is the **first spec** of the version, create the version branch from `feat`:
     ```
     # First spec: push directly to create the version branch
     git push origin spec/<filename>:refs/heads/spec/<version>
     ```
     Subsequent specs merge into the existing version branch:
     ```
     git fetch origin spec/<version>   # e.g. spec/1.0.0-beta
     git worktree add .spec/_integrate-<name> -b integrate/<name> origin/spec/<version>
     # in the integration worktree: git merge --no-ff spec/<filename>
     git push origin integrate/<name>:spec/<version>
     ```
   - Remove the worktree and delete the remote feature branch:
     ```
     git worktree remove .spec/<name> && git worktree remove .spec/_integrate-<name>
     git push origin --delete spec/<filename>
     git branch -d spec/<filename> integrate/<name>
     git worktree prune
     ```
6. **Version completion** — when all specs under a version are done, integrate into `feat` with clean history:
   ```
   git fetch origin spec/<version>
   git checkout -b spec/<version> origin/spec/<version>
   git rebase -i feat
   ```
   Reorganize commits via interactive rebase so each spec maps to a single clear, well-described commit. Keep all changes intact — only restructure history. Then verify everything passes:
   ```
   zig build test
   zig build test-libs   # if runtimes available
   ```
   Once verified, merge into `feat` and clean up:
   ```
   git checkout feat
   git merge --no-ff spec/<version>
   git push origin feat
   git branch -d spec/<version>
   git push origin --delete spec/<version>
   ```

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
runtime to lower `.bp` expressions to BEAM bytecode that AtomVM executes,
but the backend itself is unchanged — it continues to serve user-facing
`botopink build --target beam` as before.

What changes:
- `comptime/runtime/` — wasm3 host + WAT prelude → AtomVM host + BEAM codegen
- `modules/wasm3/` → `modules/atomvm/` (vendored interpreter swap)
- `build.zig` — link AtomVM instead of wasm3

What does NOT change:
- User-facing codegen (all 5 targets produce identical output)
- Stdlib compilation (same `.bp` → same output per target)
- LSP analysis (comptime values are opaque to the LSP regardless of runtime)
- Snapshot format for non-comptime codegen tests

## Notes

- AtomVM must be evaluated for embeddability before step 3 begins. If AtomVM
  cannot be embedded as a C library with a clean API, fall back to spawning
  it as a child process (like the retired Node.js runner in
  `persistent_node.zig`) — but that path is strictly worse for latency.
- The `wat_to_wasm.zig` pure-Zig WAT compiler (~600 LOC) is also removed.
  The BEAM codegen backend (`beam_asm.zig`) already exists and is tested —
  no new compiler needs to be written.
- `persistent_node.zig` was already slated for removal (front 09); this spec
  includes it in the cleanup step since it references the old 4-runtime
  architecture that is fully retired by this change.
- The `template_runtime.bp` stdlib module gains Erlang/BEAM as a compilation
  target. Methods marked `#[@Host]` today are skipped in WAT; they become
  AtomVM NIFs (native implemented functions) or pure Erlang implementations.

## Changelog

| Date       | Change                             | Author      |
|------------|------------------------------------|-------------|
| 2026-06-27 | Spec created                       | ericfillipe |
