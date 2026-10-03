# lib-test-runner

> Path: `modules/lib-test-runner/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink-lib-test` executable: the CI gate that runs
every discovered project's test suite on each requested backend and aggregates
the results into a lib×target matrix. Projects are discovered across the resolved
**root list** (`discovery.resolveRoots`: `BOTOPINK_LIB_ROOTS` env entries → for
each ancestor `D` of cwd, `D` itself when it holds a workspace manifest,
`D/repository/botopink-lang/libs`, `D/repository`, `D/libs`, stopping after the
first `D` that holds `repository/` — the enclosing checkout, so a meta worktree
under `.tasks/<name>` runs in place and sees only its own libraries
(`manifest.isCheckoutRoot`, decision 143) → any `--lib-root`
flag entries; de-duped first-occurrence-wins) by the shared
`manifest.scanRoots` (`modules/manifest`): a root's child holding a
`botopink.json` is a lib, and a child (or root) whose manifest declares
`"workspaces"` contributes every **member** it expands to — `modules/*`,
`examples/*` — as a lib named by its manifest, one row each; the umbrella is not
a row (decision 75). Two plain packages with one name keep first-root-wins; two
members with one name are both `✗` with a located error. It **shells out to the
installed `botopink` binary** (`botopink test --target <t>` with `cwd` set to
each lib's own directory) and touches no compiler internals — so it carries
**no `compiler-core` dependency** (only the std-only `manifest` module). Its
job is discovery + fan-out + aggregation + exit code, nothing the compiler
already does.

**The manifest decides the matrix.** A lib runs on the targets its
`botopink.json` declares and on no other; a target its `"targets"` list excludes
is not a cell, and the exclusion is audited on every run (§ The restriction
audit). No flag, variable or list runs an excluded target, skips an audit, or
makes a red cell anything but red (decision 67).

## Tree

```text
lib-test-runner/
├── AGENTS.md            ← you are here
└── src/                 ← built and tested by the workspace build.zig (no build.zig of its own)
    ├── main.zig         ← entry: resolve roots/binary → discover → plan every (lib, target) pair (`Cell.Kind.of`: cell, audit or not-runnable) → `--list`, or worker pool → emit in order → matrix → exit
    ├── args.zig         ← CLI parsing (Target enum, `isSupported`, node alias, =-form, all)  + unit tests
    ├── discovery.zig    ← `manifest.scanRoots` over the roots (packages + workspace members), "has tests" probe, `libSupportsTarget` (the one rule that says whether a pair is a cell), problems + unit tests (fixtures: ../manifest/tests/fixtures)
    ├── runner.zig       ← per-(lib,target) `botopink test` spawn (or `botopink build` for a test-less lib), split into `capture*` (spawn, capture, classify — thread-safe, writes nothing) and `emit*` (the cell's output, exactly as a serial run wrote it) + the cell's failed-test tally, read from the child's run total + the restriction audit (`captureAudit`, `classifyAudit`, `emitAudit`)
    ├── doc_quotes.zig   ← a workspace document quoting the tool's member list is checked against the tool + unit tests
    ├── schedule.zig     ← the order the pool STARTS cells in: the duration history of each cell's cache root (`<root>/.botopinkbuild/cache/lib-test/durations.tsv`), longest last time first, unknown cells first + unit tests
    ├── result_store.zig ← the cell-result store (decision 229): the key (binaries, toolchain, every library's bytes, the cell), load / save / reap of `<root>/.botopinkbuild/cache/results/lib-test/` + unit tests
    └── matrix.zig       ← Status enum, lib×target matrix render, summary + unit tests
```

## Commands

```bash
# from the workspace root (runs scripts/test-libs.sh, which pre-flights
# node/escript/erlc/wasmtime and then execs zig-out/bin/botopink-lib-test):
zig build test-libs                                   # every lib, commonJS+erlang
zig build test-libs -- --target erlang --lib rakun    # one target, one lib
zig build test-libs -- --lib std --lib rakun          # two libs, in that order, one report
zig build test-libs -- --target all --strict          # supported targets, strict
zig build test-libs -- --lib rakun --target commonJS  # an excluded pair: no cell runs, the exclusion is audited
zig build test-libs -- --list                         # the plan, nothing spawned: `cell:*` lines are the cells, `audit` the excluded pairs
zig build test-libs -- --cold                         # every cell runs; the result store is not read, the passes are written
zig build               # produces zig-out/bin/botopink-lib-test among the workspace executables
zig build test          # includes the args + discovery + matrix + runner + schedule + doc_quotes + result_store + main unit tests
```

## CLI surface

```
botopink-lib-test [--target <t>[,<t>…] | --target all] [--lib <name>]…
                  [--filter <s>] [--strict] [--bin <path>] [--lib-root <dir>]
                  [--json] [--list] [--jobs <n>] [--cold] [--store-root <dir>]
```

`--json` switches output from the text matrix to JSONL — see
"Test output passthrough" below for the schema.

- `--target` — repeatable / comma-separated. Accepts `commonJS|erlang|beam|wasm`
  plus the alias `node`→`commonJS`, and both `--target <t>` and `--target=<t>`.
  Default: `commonJS,erlang`. `all` expands to every *supported* target.
- `--lib <name>` — restrict to the named project across roots; repeatable
  (decision 258): every name given runs, in the order given (the plan, the
  cells and the report follow it), in one report, a name given twice once
  (`args.appendLib`, `discovery.discover`'s `only` list). A name that matches
  no library fails the run, each such name printed (`main.zig`). Default: every
  project with a `botopink.json`, sorted by name.
- `--filter <s>` — forwarded to `botopink test --filter`.
- `--strict` — treat an unsupported target (beam/wasm) as a **failure** instead of
  a skip (default: skip with `~`, keeping the gate green until those backends run).
- `--list` — print the plan and spawn nothing: one tab-separated
  `<lib> <target> <kind>` line per pair, in discovery order. `cell:test`,
  `cell:compile`, `cell:nothing-to-compile` and `cell:problem` are the cells the
  manifests declare (their count is the run's `passed + failed + no-tests`);
  `audit` is a pair the manifest excludes and the run audits; `not-runnable` an
  excluded target `botopink test` cannot run. Exit 0 (1 when a workspace
  document disagrees with the tool).
- `--bin <path>` — `botopink` binary path. Also read from `BOTOPINK_BIN`; defaults
  to `./zig-out/bin/botopink`, else the bare name `botopink` on `PATH`.
- `--jobs <n>` — how many cells run at once (a positive count; `0` or a
  non-number is refused). Default: one per CPU, bounded by memory
  (`MemAvailable / 768 MiB` from `/proc/meminfo` where it exists — a `botopink
  test` child peaks around 400 MB plus its `erl`/`node`, and several gates share
  one machine). Scheduling only — see "Parallel cells" below.
- `--cold` — do not read the result store (§ The result store): every
  spawning cell runs, and its passes are written. `scripts/gate.sh --cold`
  passes it.
- `--store-root <dir>` — keep the result store in `<dir>` instead of each
  library's `<cache root>/.botopinkbuild/cache/results/lib-test/` (the tests'
  scratch stores).
- `--lib-root <dir>` — extra root to scan; repeatable. Appended **after**
  `BOTOPINK_LIB_ROOTS` env entries and the walk-up roots. Useful for ad-hoc CI
  without mutating env (`botopink-lib-test --lib-root /tmp/store --lib foo`).

## Matrix legend & exit code

| Symbol | Meaning |
|---|---|
| `✓` | `botopink test` passed |
| `✗` | a red `.bp` test — the only **cell** status that fails the run. Also every cell of a lib with a **problem**, printed once per cell without a spawn: a refused manifest (`docs/botopink-json.md`), a workspace that does not expand, a name declared by two libraries, or a library member of a workspace that lists no `files` (`error: ships nothing: manifest has no "files" — …`, located on its manifest) |
| `–` | lib has no test blocks and **compiled** (`botopink build --target <t>`); nothing ran |
| `~` | the target is one `botopink test` cannot run yet (beam/wasm), whether the lib declares it or excludes it. `--strict` flips it to fail. |
| `·` | not a cell: the lib's `"targets"` list excludes the target, and the restriction audit proved the exclusion structural (see below) |
| `!` | not a cell, and the audit **refused** the exclusion — the lib builds on the excluded target, or its build fails there for another reason. Fails the run. |

### Per-lib `"targets"` whitelist (`botopink.json`)

A lib may opt out of a backend with an explicit `"targets": [<list>]`
array in its `botopink.json`:

```json
{
  "name": "onze",
  "targets": ["commonJS"]
}
```

The runner reads this during discovery (the shared `manifest` parser), and
`discovery.libSupportsTarget` is the one rule that says whether a requested
(lib, target) pair is a cell: a target not in the list is **not a cell** — no
`botopink test` is spawned for it, in any mode, under any flag. The
single-string `"target"` field (canonical build target) is separate. A
workspace member without `"targets"` inherits its workspace's list and may only
restrict it (a wider list is a located error and a `✗` row).

Absent `"targets"` → every requested target is attempted. A malformed list
(non-array, a non-string entry) is a refused manifest — `✗` with the located
error, never silently widened.

### The restriction audit

A restriction is never silent, and never a place to keep a red. For each
(lib, excluded target) pair whose target `botopink test` can run
(`args.Target.isSupported` — commonJS and erlang today), the runner spawns

```
botopink build --target <excluded> --out .botopinkbuild/lib-test-build/<t>/<id>
```

in the lib's directory (`runner.captureAudit`; the output directory is the
compile-only cell's, per target and per run, removed when the audit ends) and
classifies the outcome (`runner.classifyAudit`):

| Outcome | Verdict |
|---|---|
| the build is refused, and its **first** `error` line is the missing host binding — `` `f` has no `#[@External.<Target>(…)]` for the <backend> backend ``, or the same reached through a bodied function (`` `g` calls `f`, which has no … ``) | `ok` — the exclusion is **structural**: the lib cannot run there. `·` |
| the build succeeds | `not_structural` — the exclusion hides a cell that could run. `!`, the run fails |
| the build fails and its first error is anything else (a parse error, a type error, a compiler gap, the closing `N module(s) failed` alone) | `not_structural` — the exclusion hides a red. `!`, the run fails |
| the build fails and prints no `error` line | `not_structural`. `!`, the run fails |

A refused exclusion prints the build's own output (when it failed) and

```
error: the restriction is not structural — `<lib>` excludes `<t>` in its "targets", and <what the audit found>
  → delete the "targets" line, or file the compiler row that makes the build refuse it
```

on stderr, in both modes. The compiler's refusal carries no error id, so the
classifier reads its fixed text (`runner.HOST_BINDING_MARK`, the message of
`MissingExternal.diagnostic` in `compiler-core/src/codegen/moduleOutput.zig`);
it names no library. If the compiler rewords the refusal every audit answers
`not_structural` and the run fails — the audit can stop accepting, it cannot
start accepting something else — and
`../compiler-cli/tests/test_tooling.sh` holds the two together with three real
builds (structural, builds, another error). The "first error" rule is
deliberate: a build that reports any other error first is a red in its own
right, whatever follows it. The beam-only template refusal (`` `f`'s
`#[@External.Erlang(…)]` template does not compile for the beam backend ``) is a
different diagnostic — the binding exists — and is not accepted.

An excluded target `botopink test` cannot run (beam, wasm) is neither a cell nor
an audit: no cell could exist there, so the exclusion hides nothing the run
could measure. It is reported as the CLI's own limit is — `~`, or `✗` under
`--strict` — without a spawn. When `botopink test` learns a backend,
`Target.supported` widens and its exclusions are audited from then on.

The audit costs one `botopink build` per excluded pair — the dependency-closure
compile the cell would have cost, no test run — and the pairs run on the same
worker pool as the cells (§ Parallel cells).

**Exit non-zero iff at least one cell is `✗` or one exclusion is `!`.** A
target `botopink test` cannot run (`~`) and an audited exclusion (`·`) never
redden the gate. A lib with no `test` block is still **compiled** on each
target it does not opt out of (`runner.compileCell` spawns `botopink build
--target <t> --out .botopinkbuild/lib-test-build/<t>/<id>` in the lib's
directory — `<id>` is 64 random bits per cell run, and the directory is removed
when the cell ends):
`–` when it compiles, `✗` when it does not — a library that never wrote a test
cannot break silently. A project whose `src/` holds no `.bp` file at all (a
tooling repository carrying a `botopink.json`, e.g. `vscode-extension`) has
nothing to compile and stays `–`. The build's output goes to stderr, so `--json` stdout
stays pure JSONL.

## Test output passthrough

Each child `botopink test` invocation produces the per-test envelope
documented in
[`../compiler-cli/AGENTS.md`](../compiler-cli/AGENTS.md#botopink-test-output-format):

```
TEST <file>:<line> <name>
----- RUN LOG -----
\`\`\`logs
<captured stdout>
\`\`\`
  duration <ms>ms
  ok | FAIL <name>  …
```

**The cell's count is the child's run total**, never a module's own
summary: `botopink test` prints one `<P> passed, <F> failed` per module
and ends with `total: <P> passed, <F> failed in <N> module(s)` in text
mode, or one aggregated `{"event":"summary",…}` under `--json`
(`runner.parseChildSummary`, `parseTextTotal`). A test cell whose child
exited 0 with **no** run total is a `✗` with the line `botopink test
exited 0 but printed no run total` — nothing says how many tests ran.

In text mode (no flag) the runner **re-emits the child's stdout
untouched**: a downstream tool that needs to attribute the envelope
to a lib uses the cyan section header written to **stderr**
(`── <lib> · <target> ──`) immediately before the cell's stdout — a
deliberate choice over per-line text prefixing, which would corrupt
the fenced ```` ```logs ```` blocks.

### `--json` mode

`botopink-lib-test --json` passes `--json` to each spawned
`botopink test`, parses each JSONL record on the child's stdout, and
re-emits with two extra leading keys spliced in immediately after the
opening `{`:

```
{"lib":"<name>","target":"<t>","event":"test",…original keys…}
{"lib":"<name>","target":"<t>","event":"summary","passed":<P>,"failed":<F>}
```

Per cell the runner also writes one structured record (so a consumer
can match every spawned cell to its outcome without re-parsing the
text matrix):

```
{"event":"cell_summary","lib":"<name>","target":"<t>",
 "status":"pass|fail|skipped_unsupported|no_tests",
 "failed":<n>,"ran":<bool>,"from_store":<bool>}
```

- `failed` — the `"failed"` of the child's own terminating
  `{"event":"summary",…}` record: the number of red tests in this cell.
- `ran` — whether such a record existed at all. `false` for a cell that did not
  compile, one that ran `botopink build` (no `test` block), and one that was
  never spawned. `"ran":false` is **not** "zero failures": a cell that does not
  build has no test count.
- `from_store` — the cell did not run: its captured output (the records above
  it, its stderr) and its verdict are a stored pass whose key equals this run's
  (§ The result store).

A pair the lib's `"targets"` list excludes has no `cell_summary` — it is not
a cell. An audited one has, in its place in the stream,

```
{"event":"restriction_audit","lib":"<name>","target":"<t>",
 "status":"ok|not_structural","from_store":<bool>,"line":"<text>","at":"<file>:<line>:<col>"}
```

- `line` — for `ok`, the refusal that proves the exclusion structural (the
  build's first `error` line, ANSI removed); for `not_structural`, what the
  audit found instead: `` `botopink build --target <t>` succeeds ``, the build's
  first error line, or `the build failed and printed no error line`. A JSON
  string (`"` and `\` escaped).
- `at` — the `--> <file>:<line>:<col>` under that error line; empty when there
  is none.

(An excluded target `botopink test` cannot run is a `cell_summary` with
`skipped_unsupported`, or `fail` under `--strict`.)

Before any cell, one record per discovered library names the directory
its cells run in:

```
{"event":"lib","lib":"<name>","dir":"<dir>"}
```

and, when a workspace document disagrees with the tool (§ Documents
that quote the tool), one `{"event":"doc_quote_mismatch"}`.

Before it, one record says what the result store did:

```
{"event":"result_store","jobs":<spawning pairs>,"ran":<R>,"from_store":<S>,
 "written":<passes stored>,"note":"<text>"}
```

— `note` is empty, or why nothing was read or written (`--cold: …`, `never
stored: <why>`, `<n> not written: their inputs moved during the run`). Text mode
prints `result store: <J> jobs — <R> run, <S> from store` after the matrix, and a
cell answered from the store ends its stderr header with `(from store)`.

The run terminates with a single aggregated record:

```
{"event":"run_summary","passed":<cells_pass>,"failed":<cells_fail>,
 "no_tests":<n>,"skipped":<n>,"audited":<ok audits>,"not_structural":<refused audits>}
```

In JSON mode the text matrix is suppressed (stdout is pure JSONL); the
cyan stderr header is also suppressed so a piped stderr stays free of
ANSI noise. Spawn / compile errors still surface on stderr.

Schema for the inner `event:"test"` and `event:"summary"` records is
the upstream contract from
[`../compiler-cli/AGENTS.md`](../compiler-cli/AGENTS.md) (`--json`
section). Forward-compatible: a JSON consumer that does not recognise
a key should ignore it.

## Documents that quote the tool

A workspace root's documents (`*.md` directly in the workspace
directory) quote the refusal `botopink build` prints there, and that
refusal enumerates every member. A list kept as prose is merged as
prose: emilia front 39's merge took one side's copy of it whole and
dropped the member the other side had added, in a hunk git resolved
without a conflict. So `doc_quotes.check` reads every quote of `…run
this command inside one of its members: <list>` (up to the closing
backtick, whitespace collapsed — a quote may wrap) and compares it with
`manifest.Workspace.memberList`, the list the tool renders. An elided
quote (`…`) enumerates nothing and is not checked. A mismatch prints
`<file>:<line>: the workspace refusal is quoted with the members …, but
the tool prints …` and fails the run (exit 1, both modes); no flag turns
it off.

## Stale binary

`botopink-lib-test` refuses to start when the checkout it (and the
`botopink` beside it) was built from has changed since the build
(`source_stamp.checkFresh` over `build_stamp`, embedded by `build.zig` —
[`../source-stamp/AGENTS.md`](../source-stamp/AGENTS.md)): a library run
against a stale compiler measures the previous compiler. `botopink
test` makes the same check of its own binary, so a hand-run cell is
covered too. Exit 1, naming the checkout and `run zig build there`.

## Parallel cells

`main.zig` plans every (lib, target) pair in discovery order first
(`Cell.Kind.of`) — problem, not-runnable and nothing-to-compile pairs are
decided from discovery alone and spawn nothing — then runs the spawning ones
(`compile`, `test_run`, `audit`) on `--jobs`
workers (`std.Io.concurrent`; each worker claims the next cell in START order
— `schedule.zig`, below —
captures it into its slot with a page-backed arena of its own, and sets the
slot's `std.Io.Event`). The main thread walks the plan in order, waits for each
slot, and is the **only** writer of stdout/stderr: each cell's header, captured
child stdout (JSONL spliced under `--json`), captured child stderr and
`cell_summary` are written exactly as the serial runner wrote them, one cell at
a time. The child's output was always captured whole before being re-emitted,
so the stream — and the exit code, the matrix, `run_summary`, and everything
`scripts/test-libs.sh` reads from it — is byte for byte what `--jobs 1` prints;
only the timing values the children print (`duration_ms`, `Compiled in …`)
differ between any two runs. When no worker can be started the main thread runs
each cell as it reaches it (the serial runner).

**Start order** (`schedule.zig`). A pool that takes cells in discovery order
starts the slowest cell whenever discovery reaches it, and the run then waits
for it alone: onze-cli, discovered late, was 222 s of a 473 s `test-libs`
stage, started at 244 s. Each worker therefore claims the cells in descending
order of how long they took last time — the duration history,
`<ms>\t<lib>\t<target>\t<kind>` lines in
`<root>/.botopinkbuild/cache/lib-test/durations.tsv`, one file per cache root
(`schedule.cacheRoot`, over `manifest.findCacheRoot`: the workspace root of the cell's library, else the
library's own directory — where `botopink test` keeps that library's caches,
decision 225), each holding its own libraries' cells, all read before the
start order is taken and each rewritten after every run by staging and
renaming; deleting the root's `.botopinkbuild/` (or `gate.sh --cold`) deletes
it — with the cells it has no time for first (a new cell may
be the long one) and plan order among ties. The history is a hint and nothing
else: every spawning cell still runs exactly once, the output is still emitted
in plan order (so `--jobs 1` and the default print the same bytes), and a
missing, unreadable or stale file only changes which cell starts first. No
flag or variable reads or skips it.

Before a worker starts a cell it waits for a free CPU (`Pool.admit`): while this
run already has a cell in flight, it polls `procs_running` — the runnable
threads right now, 4th field of `/proc/loadavg` — every 200 ms until it is at
most the CPU count. Up to five gates share the maintainer's machine; sized to
CPUs alone the pools put the load at ~140 on 16 CPUs, and `std/async`'s
"settleOf runs its tasks concurrently" (three 60 ms tasks under 120 ms) went
red. A run with nothing in flight is always admitted, so it cannot wait on
other gates forever; without `/proc/loadavg` nothing waits.

Concurrency inside one library directory was already the contract: two gates
over one checkout run the same cells side by side, so `botopink test` writes to
`.botopinkbuild/test-out/<target>/<id>/`, the comptime module cache is written
by rename, and `compileCell` writes `.botopinkbuild/lib-test-build/<target>/<id>/`,
per target and per run: a per-target directory alone was shared by two gates
reaching the same (lib, target) cell.

The two cells of one library DO run side by side with one cwd, so a library's
tests must not write under it: `botopink test` hands every test runner its own
scratch directory in `BOTOPINK_TEST_TMPDIR` (`<run dir>.tmp`, beside the run
directory so no erlang runner's sibling walk reaches what a test writes there,
removed with the run). rakun's build tests used to write their fixture projects to the member's
`.botopinkbuild/tmp/`, and each cell's `rm -rf` of a fixture landed between
the other cell's write and compile: `rakun-data·commonJS` measured 6, `build`,
1 failed on three consecutive gates, and the erlang cells of `rakun-data` and
`rakun-security` went red now and then.

## The result store

Decision 229 of 1.0.11-beta (front `00-gate/133-gate-speed`), `result_store.zig`.
A run without `--cold` answers a spawning cell (`compile`, `test_run`, `audit`)
from a stored **pass** when the cell's key is equal, before the pool starts —
the cell is marked done with the stored capture and no worker takes it — and
the pool runs the rest; every cell is still emitted in plan order, so the stream
is the one the run would print but for the `from_store` marks.

The key is the SHA-256 of:

- the compiler and the toolchain, as `node <checkout>/scripts/lib/result-store.js
  compiler --bin <botopink>` prints them (`result_store.global`, `<checkout>`
  being `build_stamp.source_root`) — one computation for the three stores:
  the `botopink --version` `build:` line (Zig version, optimize mode, target
  triple), the compiler's sources partitioned by backend (decision 249,
  `../compiler-core/src/codegen/backend-partition.txt`; the shared files in
  every key, a backend's own files only in the keys of cells on that target —
  an audit's target is the one it excludes), and the toolchain (`node
  --version`, the OTP release, `wasmtime --version`, the platform, 14
  environment variables — every runtime in every key). A binary not built from
  the checkout's sources, a partition that fails its audit, or a checkout
  without the script stores nothing, and the `note` says why;
- **the library universe**: every package the run's roots hold — each child of a
  root carrying a `botopink.json`, or a root that is itself a workspace — every
  directory and file by path, executable bit and content, `.git` and
  `.botopinkbuild` left out. A cell compiles its package and its dependency
  closure, and its tests may read their whole repository (onze-assets walks its
  siblings), so rather than decide which packages a cell reads every key holds
  all of them: a byte changed in any library runs every cell;
- the cell: its library's name and directory, the target, the kind, and
  `--filter`, `--strict`, `--json`.

Every run writes — `--cold` too (decision 249): it only never reads. Only a pass
is written (`.pass`, `.no_tests` — compiled —, a structural
`.excluded`; a spawn error never), and only when the global part of the key,
computed again after the run, is unchanged — nothing the keys read moved under
the run. Nothing is stored at all when the universe holds bytes the hash cannot
see — a symbolic link, or a `.botopinkbuild/deps/` (the `bpmp install` store
the compiler resolves dependencies through); the `note` names it. An entry is
the captured cell (status, the test count, the audit's line and location, the
child's stdout and stderr) at `<cache root>/.botopinkbuild/cache/results/lib-test/<kk>/<key>`
(`schedule.cacheRoot`'s root, decision 225), staged and renamed; a hit refreshes
its time and entries unused for 7 days are deleted after every run. A cell
answered from the store keeps its last duration in `durations.tsv`.
`rm -rf .botopinkbuild` (or `gate.sh --cold`) wipes it; `--cold` never reads it
and writes its passes. The shell runners keep the same store
(`../../scripts/lib/result-store.js`), and
`../compiler-cli/tests/result_store.sh` holds the rule end to end.

## Design contract

- **Orchestrate, don't reimplement.** Per-lib isolation falls out of spawning a
  child with `cwd = <lib_dir>` (the lib's own directory, under any resolved root):
  `botopink test` reads that lib's `botopink.json` and writes under that lib's
  own `.botopinkbuild/test-out/`. No global-cwd juggling. Per-lib is NOT
  per-run, though: that directory belongs to the checkout, which two gates
  share, so the child scopes its output one level further — per target and per
  run, `.botopinkbuild/test-out/<target>/<id>/`, and `compileCell` writes
  `.botopinkbuild/lib-test-build/<target>/<id>/` the same way.
- **Unsupported-target detection is child-driven**, not a hard-coded list: the
  runner scans the child's output for `"currently supports only"`. The moment
  `botopink test` learns `beam`/`wasm`, that target stops being skipped here with
  no change — only the default/`all` set widens (`args.Target.supported`).
- **No lib coupling, no core code.** The runner names no specific lib and imports
  nothing from `compiler-core`; its only import is the std-only `manifest`
  module, so its reading of `botopink.json` is the compiler's.

## Env

| Variable             | Read by                                | Effect                                                                 |
| -------------------- | -------------------------------------- | ---------------------------------------------------------------------- |
| `BOTOPINK_LIB_ROOTS` | `src/discovery.zig:resolveRoots`       | Prepends extra lib roots before the walk-up roots.                     |
| `BOTOPINK_BIN`       | `src/main.zig:resolveBin`              | Override `botopink` binary path (`--bin` takes precedence).            |

**`BOTOPINK_LIB_ROOTS` contract** (mirrors
[`compiler-cli`](../compiler-cli/AGENTS.md#env)):

- Path separator: `:` on POSIX, `;` on Windows (via `std.fs.path.delimiter`).
- Entries prepended to the walk-up result; the combined list (env → walk-up →
  `--lib-root`) is de-duplicated first-occurrence-wins (env always shadows a
  duplicate walk-up root).
- Non-existent entries silently dropped (a typo must not break a run that does
  not need the missing root).
- Empty entries and a trailing delimiter dropped.
- Relative entries resolved against cwd.
- Unset / empty → walk-up roots (plus `--lib-root`) only.
- `init.environ_map` is threaded into `discovery.resolveRoots`; tests pass `null`.

See the root [`AGENTS.md`](../../AGENTS.md) for workspace commands and the
[`modules/AGENTS.md`](../AGENTS.md) package table.

## Scratch paths in tests

A unit test in this package that writes to disk takes its path from the
`test_scratch` module — `test_scratch.path(io, "<case>/…")`,
`test_scratch.remove(io, "<case>")` — never a hand-spelled
`.botopinkbuild/<case>` (`scripts/check-test-scratch.sh` refuses that, decision 67, no flag).
The test cwd is this package's directory, shared by every process running the
suite; a per-case-but-not-per-run path let a second `zig build test` empty the
first one's fixtures mid-test. See
[../test-scratch/AGENTS.md](../test-scratch/AGENTS.md).
