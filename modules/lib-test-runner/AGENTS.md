# lib-test-runner

> Path: `modules/lib-test-runner/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink-lib-test` executable: the CI gate that runs
every discovered project's test suite on each requested backend and aggregates
the results into a lib×target matrix. Projects are discovered across the resolved
**root list** (`discovery.resolveRoots`: `BOTOPINK_LIB_ROOTS` env entries → for
each ancestor `D` of cwd, `D` itself when it holds a workspace manifest,
`D/repository/botopink-lang/libs`, `D/repository`, `D/libs` → any `--lib-root`
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

## Tree

```text
lib-test-runner/
├── AGENTS.md            ← you are here
└── src/                 ← built and tested by the workspace build.zig (no build.zig of its own)
    ├── main.zig         ← entry: resolve roots/binary → discover → run cells → matrix → exit
    ├── args.zig         ← CLI parsing (Target enum, node alias, =-form, all)  + unit tests
    ├── discovery.zig    ← `manifest.scanRoots` over the roots (packages + workspace members), "has tests" probe, `libSupportsTarget`/`libRunsTarget`, problems + unit tests (fixtures: ../manifest/tests/fixtures)
    ├── runner.zig       ← per-(lib,target) `botopink test` spawn (or `botopink build` for a test-less lib) + status classification + the cell's failed-test tally
    └── matrix.zig       ← Status enum, lib×target matrix render, summary + unit tests
```

## Commands

```bash
# from the workspace root (runs scripts/test-libs.sh, which pre-flights
# node/escript/erlc/wasmtime and then execs zig-out/bin/botopink-lib-test):
zig build test-libs                                   # every lib, commonJS+erlang
zig build test-libs -- --target erlang --lib rakun    # one target, one lib
zig build test-libs -- --target all --strict          # supported targets, strict
zig build test-libs -- --lib rakun --target erlang    # measure one restricted cell
zig build               # produces zig-out/bin/botopink-lib-test among the workspace executables
zig build test          # includes the args + discovery + matrix + runner unit tests (38)
```

## CLI surface

```
botopink-lib-test [--target <t>[,<t>…] | --target all] [--lib <name>]
                  [--filter <s>] [--strict] [--include-unsupported]
                  [--bin <path>] [--lib-root <dir>] [--json]
```

`--json` switches output from the text matrix to JSONL — see
"Test output passthrough" below for the schema.

- `--target` — repeatable / comma-separated. Accepts `commonJS|erlang|beam|wasm`
  plus the alias `node`→`commonJS`, and both `--target <t>` and `--target=<t>`.
  Default: `commonJS,erlang`. `all` expands to every *supported* target.
- `--lib <name>` — restrict to one project by name across roots (default: every
  project with a `botopink.json`).
- `--filter <s>` — forwarded to `botopink test --filter`.
- `--strict` — treat an unsupported target (beam/wasm) as a **failure** instead of
  a skip (default: skip with `~`, keeping the gate green until those backends run).
- `--include-unsupported` — run a cell the lib's `"targets"` whitelist excludes,
  instead of skipping it, and flag it `"restricted":true` in `--json`. The
  restriction is **measured**, not lifted: the lib's manifest is untouched and
  the cell's verdict is read against `scripts/restricted-targets.txt` by
  `scripts/test-libs.sh`, which always passes this flag. Orthogonal to
  `--strict`, which governs the *CLI-side* unsupported mark (beam/wasm) and is
  unaffected.
- `--bin <path>` — `botopink` binary path. Also read from `BOTOPINK_BIN`; defaults
  to `./zig-out/bin/botopink`, else the bare name `botopink` on `PATH`.
- `--lib-root <dir>` — extra root to scan; repeatable. Appended **after**
  `BOTOPINK_LIB_ROOTS` env entries and the walk-up roots. Useful for ad-hoc CI
  without mutating env (`botopink-lib-test --lib-root /tmp/store --lib foo`).

## Matrix legend & exit code

| Symbol | Meaning |
|---|---|
| `✓` | `botopink test` passed |
| `✗` | a red `.bp` test — the **only** status that fails the run. Also every cell of a lib with a **problem**, printed once per cell without a spawn: a refused manifest (`docs/botopink-json.md`), a workspace that does not expand, a name declared by two libraries, or a library member of a workspace that lists no `files` (`error: ships nothing: manifest has no "files" — …`, located on its manifest) |
| `–` | lib has no test blocks and **compiled** (`botopink build --target <t>`); nothing ran |
| `~` | target skipped: either not-yet-runnable (beam/wasm), or excluded by the lib's `"targets"` whitelist (see below). `--strict` flips the not-yet-runnable case to fail; the per-lib whitelist skips unless `--include-unsupported` is given, which runs the cell and marks it `restricted` instead. |

### Per-lib `"targets"` whitelist (`botopink.json`)

A lib may opt out of a backend with an explicit `"targets": [<list>]`
array in its `botopink.json`:

```json
{
  "name": "onze",
  "targets": ["commonJS"]
}
```

The runner reads this during discovery (the shared `manifest` parser) and
reports `~` for any requested target not in the list — without spawning
`botopink test`. Used by commonJS-only libs. The single-string `"target"`
field (canonical build target) is separate; the array field is only the
runner-side filter. A workspace member without `"targets"` inherits its
workspace's list and may only restrict it (a wider list is a located error
and a `✗` row).

Absent `"targets"` → every requested target is attempted. A malformed list
(non-array, a non-string entry) is a refused manifest — `✗` with the located
error, never silently widened.

**A restriction is never silent.** `--include-unsupported` takes the skip away:
the cell is spawned like any other, and its `cell_summary` carries
`"restricted":true` plus the child's own `"failed"`/`"ran"` tally.
`scripts/test-libs.sh` passes the flag on every run and checks that tally
against [`../../scripts/restricted-targets.txt`](../../scripts/restricted-targets.txt)
— the ledger that pins each hidden cell's **failed** count (never its passed
count), refusing an unlisted restriction, a stale line, and a count that moved
in either direction. The runner itself knows nothing of the ledger: with the
flag, a restricted cell that fails is an ordinary `✗` and the process exits
non-zero. Only the wrapper reads the pin.

**Exit non-zero iff at least one cell is `✗`.** A skipped target (`~`) never
reddens the gate. A lib with no `test` block is still **compiled** on each
target it does not opt out of (`runner.compileCell` spawns `botopink build
--target <t> --out .botopinkbuild/lib-test-build/<t>` in the lib's directory):
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
 "restricted":<bool>,"failed":<n>,"ran":<bool>}
```

- `restricted` — the lib's `"targets"` list excludes this target. `true` both on
  the skipped cell (without `--include-unsupported`) and on the cell that ran
  because of it, so a consumer can tell a restricted cell from an ordinary one
  in either mode.
- `failed` — the `"failed"` of the child's own terminating
  `{"event":"summary",…}` record: the number of red tests in this cell.
- `ran` — whether such a record existed at all. `false` for a cell that did not
  compile, one that ran `botopink build` (no `test` block), and one that was
  never spawned. `"ran":false` is **not** "zero failures": a cell that does not
  build has no test count, and conflating the two is what let a restricted
  erlang row read as green.

The run terminates with a single aggregated record:

```
{"event":"run_summary","passed":<cells_pass>,"failed":<cells_fail>,
 "no_tests":<n>,"skipped":<n>}
```

In JSON mode the text matrix is suppressed (stdout is pure JSONL); the
cyan stderr header is also suppressed so a piped stderr stays free of
ANSI noise. Spawn / compile errors still surface on stderr.

Schema for the inner `event:"test"` and `event:"summary"` records is
the upstream contract from
[`../compiler-cli/AGENTS.md`](../compiler-cli/AGENTS.md) (`--json`
section). Forward-compatible: a JSON consumer that does not recognise
a key should ignore it.

## Design contract

- **Orchestrate, don't reimplement.** Per-lib isolation falls out of spawning a
  child with `cwd = <lib_dir>` (the lib's own directory, under any resolved root):
  `botopink test` reads that lib's `botopink.json` and writes under that lib's
  own `.botopinkbuild/test-out/`. No global-cwd juggling. Per-lib is NOT
  per-run, though: that directory belongs to the checkout, which two gates
  share, so the child scopes its output one level further — per target and per
  run, `.botopinkbuild/test-out/<target>/<id>/`, the way `compileCell` already
  writes `.botopinkbuild/lib-test-build/<target>`.
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
