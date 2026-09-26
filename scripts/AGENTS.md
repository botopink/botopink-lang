# scripts · AGENTS.md

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Installers, the release packaging helper, the gate, the lib-test and
vscode-test wrappers, the two library-cell ledgers, the snapshot audit tool, the user-docs fence checker, the comptime-path
benchmark, and the tracked git hooks.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── install.sh         ← POSIX one-liner installer
├── install.ps1        ← Windows one-liner installer
├── release-pack.sh    ← per-target archive + sha256 packer (used by release.yml)
├── gate.sh            ← the ordered local gate (staged checks, build, format-check, test, test-bpmp, beam export audit, test-cli, test-libs, test-language, test-docs)
├── format-check.sh    ← `botopink format --check` over the compiler's canonical `.bp` trees — decision 66's caller; the red trees and their causes are in its header
├── test-libs.sh       ← runtime pre-flight + `botopink-lib-test` wrapper with known reds and the restricted-targets ledger (`zig build test-libs`)
├── known-red-libs.txt ← library cells known red, each with its owning front
├── restricted-targets.txt ← the ledger: every cell a member's `"targets"` list hides, with its measured failed count
├── test-vscode.sh     ← locate the sibling vscode-extension, `npm ci` once, `npm test` (`zig build test-vscode`)
├── check-docs.sh      ← compiles every `botopink` fence of docs.md/README.md (`zig build test-docs`)
├── check-test-scratch.sh ← refuses a cwd-anchored `.botopinkbuild` path inside a `test` block (part of `zig build test`)
├── snap_audit.sh      ← read-only audit of every *.snap.md (7 modes)
├── beam_export_audit.sh ← assemble every beam snapshot module with every function exported
├── comptime_bench.sh  ← what the comptime path costs: build wall clock + the in-node compile/load/run split
├── lib/
│   └── pool.sh        ← the bounded worker pool the shell runners share (sourced by ../tests/language/run.sh and check-docs.sh)
└── git-hooks/
    ├── pre-commit                 ← tracked hook, enabled by `git config core.hooksPath scripts/git-hooks` (see ../AGENTS.md §Local gate)
    └── lib/runner-standalone.sh   ← the hook's runner → `gate.sh --staged`
```

## Installers — contract

Both scripts produce the **same** on-disk layout (see
[`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) §Storage layout):

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp / %USERPROFILE%\.bpmp
├── bin/bpmp                                 # shim (symlink or copy)
└── botopink/versions/
    ├── <version>/{botopink, botopink-lsp, botopink-lib-test, bpmp}
    └── stable                               # symlink → <version>
```

### Asset URLs they consume

```text
https://github.com/botopink/botopink-lang/releases/latest/download/<file>
https://github.com/botopink/botopink-lang/releases/download/<tag>/<file>
```

`<file>` is `<binary>-<version>-<target>.<ext>` plus a `.sha256` sidecar (single
line, 64 hex chars), matching `release-pack.sh` output. `<binary>` is one of
`botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`; `<ext>` is `tar.gz`
(POSIX) or `zip` (Windows).

### Integrity model

1. Fetch `<archive>` + `<archive>.sha256` over HTTPS only.
2. Compute sha256 of `<archive>`; compare to the sidecar's first token.
3. Mismatch ⇒ exit 1 with both digests printed. No partial install.

`install.sh` uses `curl --proto '=https' --tlsv1.2 -sSfL` when available
(falling back to `wget --https-only -qO-`); `install.ps1` uses
`Invoke-WebRequest -UseBasicParsing`.

### Env / flags

| Variable / flag                              | install.sh | install.ps1                          | Effect                                                |
| -------------------------------------------- | ---------- | ------------------------------------ | ----------------------------------------------------- |
| `--target <tuple>`                           | ✓          | `-Target`                            | Override OS/arch detection.                           |
| `--version <v>` / `BOTOPINK_VERSION`         | ✓          | `-Version` / `$env:BOTOPINK_VERSION` | Pin release tag (default: `latest`).                  |
| `--install-dir <p>` / `BOTOPINK_INSTALL_DIR` | ✓          | `-InstallDir`                        | Override `$BPMP_HOME`.                                |
| `--force` / `BOTOPINK_INSTALL_FORCE=1`       | ✓          | `-Force`                             | Overwrite an existing install.                        |
| `--modify-path` / `--no-modify-path`         | ✓          | (manual)                             | Append PATH export to detected shell rc (idempotent). |
| `--quiet`                                    | ✓          | `-Quiet`                             | Suppress non-error output.                            |
| `--help`                                     | ✓          | `-Help`                              | Print usage and exit 0.                               |

Exit codes: `0` success (an unknown flag in `install.sh` prints usage and exits
0); `1` any failure (download, sha256 mismatch, clobber refusal, …).

### Clobber refusal

If `$BPMP_HOME` is non-empty and `--force` / `BOTOPINK_INSTALL_FORCE=1` is not
set, both scripts exit 1 pointing at `bpmp self update`, `bpmp self uninstall`,
or `BOTOPINK_INSTALL_FORCE=1`. They never prompt — `curl | sh` runs in non-TTY
contexts (CI, Dockerfile).

### Platform notes

- **macOS:** binaries are not codesigned; `install.sh` prints an
  `xattr -d com.apple.quarantine ~/.bpmp/botopink/versions/stable/*` hint.
- **Windows:** `install.ps1` tries `New-Item -ItemType SymbolicLink`; without
  developer mode or admin it falls back to a directory copy and prints a note.

## release-pack.sh

`scripts/release-pack.sh <target> <version> <ext>` runs per matrix cell in
`release.yml`. It reads `zig-out/bin/`, writes
`dist/<binary>-<version>-<target>.<ext>` plus `.sha256`, and skips missing
binaries. Each archive holds **one file** at top level, so the installer extracts
straight into `$BPMP_HOME/botopink/versions/<v>/`.

See [`../AGENTS.md`](../AGENTS.md) §Release pipeline and
[`../.github/workflows/release.yml`](../.github/workflows/release.yml).

## gate.sh

`scripts/gate.sh [--cold] [--staged]` — one ordered run, stopping at the first
failing stage (stages 4b–10 run side by side and are reported in this order —
§ Where the gate's time goes): staged-file checks (`--staged`: conflict markers, `zig fmt
--check` on staged `.zig`), `zig build`, `scripts/format-check.sh` (`botopink
format --check` over the compiler's canonical `.bp` trees — decision 66's
caller), `zig build test` (`--cold` deletes
`modules/compiler-core/.botopinkbuild/runtime-cache` first),
`snap_audit.sh --mode=runtime-parity` (front 18 step 4: the codegen tree under
both comptime runtimes, pairs equal but for their listing sections), `zig build
test-bpmp`, `scripts/beam_export_audit.sh`, `zig build test-cli`, `zig build
test-libs` (every `"targets"`-restricted cell included, checked against
`restricted-targets.txt`), `zig build test-language` (`tests/language/`, expected failures in
`tests/language/expected-failures.txt`), `zig build test-docs`
(`check-docs.sh`). CI (`.github/workflows/test.yml`) runs the same stages minus the
staged checks. The pre-commit hook runs `--staged`; the run
that decides a merge adds `--cold`. After the staged checks the script unsets
every `git rev-parse --local-env-vars` variable a hook inherits (`GIT_DIR`,
`GIT_INDEX_FILE`, …): a stage that runs `git` in a scratch repository (bpmp's
install tests) would otherwise act on the committing repository.

### Where the gate's time goes

The stages stay one ordered REPORT — the first failing stage in the order above
is the one reported, with the output and exit status the one-at-a-time gate
printed. Stages 1–4 still run one after the other, each only after the cheaper
ones passed. Stages 4b–10 only read what 2–4 built, and write their own scratch,
so they run side by side (`gate.sh` § side by side): each stage's stdout and
stderr are captured to one file, and once all of them have finished the blocks
are printed in stage order up to and including the first red one, whose failure
line ends the run with exit 1 — the stages after it are not printed, as the
serial gate never ran them. A red stage among 4b–10 therefore no longer saves the
time of the stages after it; that is the cost of a red run, never of a green
one. The time is otherwise saved inside the stages, by doing the same work once
and on every CPU, never by running less:

| Stage | What makes it fast | Where |
|---|---|---|
| `zig build test` | the compiler-core suite runs as `-Dtest-shards` processes (default: CPUs, at most 8), each the tests whose index is its own modulo the count; every test runs once and is reported by name, the summary's count is the unsharded one. The default runner is serial inside a process and the suite mostly waits on the node/erl/wasmtime its RUN LOGs spawn | [`../modules/test-shard/AGENTS.md`](../modules/test-shard/AGENTS.md) |
| `test-libs` | cells run on a bounded worker pool (one per CPU, bounded by `MemAvailable / 768 MiB`, each cell admitted only while `procs_running` ≤ CPUs) and are emitted in discovery order, byte for byte what `--jobs 1` prints | [`../modules/lib-test-runner/AGENTS.md`](../modules/lib-test-runner/AGENTS.md) § Parallel cells |
| `test-libs` (erlang cells) | `botopink test --target erlang` compiles each `.erl` of a run once (`precompileErlang`), not once per test module that loads it; the host-sidecar shipper resolves each library and probes each qualifier once per run | [`../modules/compiler-cli/src/cli/AGENTS.md`](../modules/compiler-cli/src/cli/AGENTS.md) (`test_cmd.zig`, `libs.zig`) |
| `test-language` | cells run on `lib/pool.sh` — the `test-libs` rule (one per CPU, bounded by `MemAvailable / 768 MiB`, each cell admitted only while `procs_running` ≤ CPUs); verdicts are written one file per cell and sorted before the report, so the output is byte for byte what `--jobs 1` prints. It used to be `--jobs 4` with no admission; measured under the usual shared load, 28.8 s → 18.3 s at +12 % CPU-seconds | [`../tests/language/run.sh`](../tests/language/run.sh) § parallel cells |
| `test-docs` | the `botopink check` of every fence runs on `lib/pool.sh`; the report is written in fence order with a placeholder per check and printed once the pool drains, so the output is byte for byte the serial run's. 8.5 s → 1.5 s | § check-docs.sh below |

`zig build` in stage 2 builds every binary the later stages run; `zig build
test-libs`, `test-language` and `test-docs` re-enter the build graph, find it
up to date and run the installed `zig-out/bin/*`, so no stage rebuilds one.
Measured numbers, before and after, are in the meta workspace's
`specs/1.0.10-beta/00-compiler-carry-over/11-tooling/README.md` § The gate's speed
and, per stage and per step, `specs/1.0.10-beta/00-compiler-carry-over/25-gate-perf/README.md`
§ Measurements.

## lib/pool.sh

Sourced, never run. The one statement of the pool rule for the shell runners —
`botopink-lib-test`'s (`../modules/lib-test-runner/AGENTS.md` § Parallel cells):
`pool_default_jobs` (one per CPU, bounded by `MemAvailable / 768 MiB`, at
least 1), `pool_check_jobs` (a `--jobs` value must be a positive count),
`pool_admit <dir>` (while a job of this run is in flight — a file in `<dir>` —
wait until `procs_running` ≤ CPUs; a run with nothing in flight is always
admitted) and `pool_job <dir> <cmd…>` (admit, mark, run, unmark). A caller runs
its jobs with `xargs -P "$jobs" bash -c '… pool_job …'` after `export -f` of
what they call, and makes its output independent of completion order — one
file per job, printed in its own order afterwards — which is what lets
`--jobs 1` and the default print the same bytes. bash 3.2 clean.

## format-check.sh

`scripts/format-check.sh` — stage 3 of `gate.sh` and a step of CI's `test` job:
`zig-out/bin/botopink format --check <tree>` for every tree in its `TREES`
array, which names the trees the gate holds canonical (`examples/modules`
today). `format --check` on a directory reaches every `.bp` and `.d.bp` under it
(nested projects included) and structurally leaves out hidden directories,
`node_modules` and a `reject/<n>.bp` beside its `<n>.expect`
(`modules/compiler-cli/src/cli/format_cmd.zig`); the list is not a skip list
and there is no other way to exempt a file (decision 67). A tree that is red
today — `libs/std`, `examples/generic-loader-binding`, `examples/stdlib-tour`,
`tests/language`, `modules/compiler-cli/tests` — is named in the script's header
with its cause and the row that owns it, and joins `TREES` when that row
lands. Exit `0` when every listed tree is canonical; `1` naming the tree and
the files, with the `Unchanged` lines filtered out.

## git-hooks/

`git-hooks/pre-commit` is self-contained: it sources
`git-hooks/lib/runner-standalone.sh`, which runs `gate.sh --staged` of the
committing checkout. Nothing installs it; a clone enables it with `git config
core.hooksPath scripts/git-hooks` (the relative path resolves against the
checkout's root, so every worktree runs its own tracked hook).

## test-libs.sh

Resolves the core dir (meta layout `repository/botopink-lang/` or this repo's
root), exits `1` if `zig-out/bin/botopink-lib-test` is not built, warns (without
gating) for each missing `node`/`escript`/`erlc`/`wasmtime`, then runs the runner
in `--json --include-unsupported` mode — discovery is the runner's, workspace members included, so
the script exports no root — and prints one line per cell — `pass`, `FAIL`, `known red — <front>
<reason>`, `restricted — <n> failed, as pinned (<front> <reason>)` (or `does not build, as pinned`),
`skipped — <reason>`, `no tests` (the library has no `test` block and
compiled; one that does not compile is a `FAIL`) — after that cell's diagnostics, and a
count summary. Exit `1` when an unlisted cell fails, a listed known red passes,
or the restricted-targets ledger is refused (§ below);
otherwise `0` (or the runner's own error exit). An explicit `--json` argument
bypasses all of this and execs the runner raw — without `--include-unsupported`,
so a raw run still skips the restricted cells. `BOTOPINK_KNOWN_RED_LIBS`
and `BOTOPINK_RESTRICTED_TARGETS` override the two list paths.

The script always passes `--include-unsupported`, so **no cell is skipped for
being outside a member's `"targets"` list** — a restriction costs its cells'
wall time on every run (measured: under a minute for the whole omitted matrix,
of which rakun's erlang cell is ~18 s) and buys a measured line instead of
silence.

## known-red-libs.txt

`<lib> <target> <owner> <reason…>` per line, `#` comments. The owning front
deletes its line in the commit that turns the cell green, which makes the cell
a hard assert. **Live entries**: front 21 step 2's window — `jhonstart`
(both rows), `jhonstart-counter commonJS`, `jhonstart-html` (both rows),
`jhonstart-todo commonJS` and `emilia-card commonJS` (it renders through
jhonstart). The compiler spells decisions 102/104 (`#[@use]`, `@Use<C, T>`,
`@Component<T>`, `@Context<Base>`) and the library still writes
`#[@context]` / `@Context<Element, R>`; the lines are deleted by the compiler
commit after the jhonstart sweep (front 21 step 4), and the two restricted
cells the same window moved (`emilia-card erlang`, `jhonstart-todo erlang`,
`0 → build`) go back to `0` in that commit.

## restricted-targets.txt

`<lib> <target> <n-failed> <owner> <reason…>` per line, `#` comments. One line
per cell a member's `botopink.json` `"targets"` list excludes — the cells that
used to be `~`, `17 skipped`, failing nothing even under `--strict`. That
silence is how a regression landed green: the erlang row of the largest library
in the workspace was not tested at all.

`<n-failed>` is the number of **failing tests**, or the token `build` when the
cell does not compile (no test ran, so it has no count — reading that as "0
failed" is the blindness the file closes). **Only the failed count is pinned,
never the passed count**: a library that adds a green test moves nothing here,
so an ordinary library commit never has to touch this repository. Writing a
line is a measurement — run the cell
(`zig build test-libs -- --lib <lib> --target <target>`) and copy what it
prints.

Three refusals, strict in both directions, no warning row (decision 67 —
fail beats warn):

| Refusal | Fires when | Fix |
|---|---|---|
| **missing line** | a restricted cell has no line | measure the cell, then add the line — a new restriction cannot enter silently |
| **stale line** | the cell ran *without* a restriction (the member widened its `targets`), or, on a run with no arguments, the cell does not exist at all | delete the line; the cell is an ordinary assert now |
| **moved count** | the measured count ≠ the pinned count, **up or down** | up is a regression; down is a fix, banked by editing the number in the same commit |

A filtered run (`--lib`/`--target`/`--filter`) judges only the cells it ran, so
the stale-line refusal's "no cell at all" arm is restricted to an unfiltered
run. A restricted cell never consults `known-red-libs.txt`: its verdict is this
file's alone. The ledger covers the targets `botopink test` can actually run: a
restricted cell on a not-yet-runnable backend is reported as an unmeasured skip
and asserts nothing — except under `--strict --target beam|wasm`, where the
runner reports it as a plain failure and the ledger reads it as a `build` red.
Nothing in the gate uses that combination (`--target all` expands to the
runnable set).

The `<owner>` is the front that owns the member's `targets` array in
`specs/<milestone>/fronts.md` — the front that will delete the line by widening
the array — not whoever measured it. Eighteen cells are listed today across
five repositories; `erika-linq erlang` (8 red tests) is the largest thing a
restriction hides and the only one whose owner is a residuals front rather than
a library track.

## check-docs.sh

`scripts/check-docs.sh [--compiler <botopink>] [--doc <file>]… [--list] [--jobs <n>]`
(`zig build test-docs`) — extracts every ```` ```botopink ```` fence of the user
docs (default `docs.md README.md`) into a scratch project and runs `botopink
check` on it. An HTML comment on the line above the fence chooses the treatment:
none (a whole module), `<!-- docs-check: body -->` (statements wrapped in `fn
main() { … }`), `<!-- docs-check: project <name> <path> -->` (one file of a
multi-file project — every fence with the same `<name>` is written at its
`<path>` and the project is checked once, one of them at `src/main.bp`) and
`<!-- docs-check: skip <reason> -->` (the only escape, for a fence that is a
table rather than a module; the reason is required and printed). A failing
fence, an unknown directive, a `skip` with no reason and a named project with no
`src/main.bp` each fail the run and name the doc and the fence's line. `--list`
prints every fence with its directive and compiles nothing. State for a named
project lives in the scratch tree (`.name`, `.origin`, `src/main.bp`), not in an
associative array, so the script runs under the macOS runner's bash 3.2.
The checks run on `lib/pool.sh` (`--jobs`, default one per CPU bounded by
memory): the report is written in fence order with a `\001CHECK <k>`
placeholder per check, and printed after the pool has drained with each
placeholder replaced by its verdict line, so any `--jobs` prints the serial
run's bytes.

## check-test-scratch.sh

`scripts/check-test-scratch.sh [<dir>…]` (default `modules`), a dependency of
`zig build test` — **a test may not spell a cwd-anchored scratch path.**

Each test binary runs with its package directory as cwd, so the whole suite
writes into one shared checkout: a path that is fixed (scoped per test name but
not per run) is shared with every other process running the suite, and each
test empties its own root on the way in. Measured before the rule existed: one
`modules/compiler-cli` test binary is 89/89 green, four concurrent copies red
1–5 tests each (`cli.config.workspaceRefusal … FileNotFound`,
`cli.format_cmd decision 66 … expected 5, found 0`, and so on).

The one way to name such a path is the `test_scratch` module
([`../modules/test-scratch/AGENTS.md`](../modules/test-scratch/AGENTS.md)),
whose root carries a per-process segment. This script is the other half: it
walks every `<dir>/**/*.zig`, tracks `test` blocks (a top-level `test "`/`test {`
until the next column-0 `}`) and refuses a string literal that **begins**
`.botopinkbuild` inside one.

It refuses, it does not warn, and no flag or environment variable turns it off
(decision 67). The only exemption is structural: a literal that does not start
at the cwd — `"…/.botopinkbuild/tmp/scratch.bp"` as fixture *content* under a
scratch root, or a reference to a production constant such as
`runtime.TMP_ROOT` — is not a cwd-anchored path and is not matched.

## test-vscode.sh

Finds the `vscode-extension` checkout (`BOTOPINK_VSCODE_DIR`, else the first
`<ancestor>/repository/vscode-extension` or `<ancestor>/vscode-extension` walking
up from this repo), runs `npm ci` when `node_modules/` is absent, then execs
`npm test`. Exits 1 when the checkout or `npm` is missing — never a silent pass.

## snap_audit.sh

`scripts/snap_audit.sh --mode={runlog,legacy,values,coverage,runtime-parity}`, and
`--mode={orphans,review} --trace=<file> [--reports=<dir>]` — pure shell +
`awk` + `grep`, read-only, no build needed. Reports go to
`build/snap-audit/<mode>.tsv` (git-ignored).

| Mode       | Purpose |
| ---------- | ------- |
| `runlog`   | Classify every codegen snapshot as silent / observable / deferred-observable, with RUN LOG state (`nonempty`/`empty`/`missing`). |
| `legacy`   | Grep every snapshot's SOURCE block for retired surface (`*fn`, legacy `@external(<target>, …)`, `@[name]`, `when($argc==N)`, `string.length()`, `value:length()`). |
| `values`   | Dump `(backend, source_sha1, path, runlog_text)` for observable codegen snapshots with a non-empty RUN LOG, for cross-checking against an external runner. |
| `coverage` | Pivot of `runlog` by backend × label × state; printed and saved. |
| `runtime-parity` | Front 18 step 4, a gate stage: every `codegen/<beam\|wat>/…` and `comptime/runtime/<beam\|wat>/…` file has its pair, and each pair is `diff`-equal once `withoutListings` sets aside the `COMPTIME ERLANG`/`COMPTIME WAT` fenced bodies (the only text the runtimes may differ in). A difference or a missing member prints a unified diff / a `MISSING` line and exits 3 — a defect in one runtime, never re-recorded away; no allow-list. |
| `orphans`  | `kind\tpath` for every `*.snap.md` on disk (compiler-core + language-server) that no test checked in the traced run (`orphan`), and every traced path absent from disk (`missing`). Exits 3 when either list is non-empty. |
| `review`   | The review worksheet, `suite\tslug\ttest\tpaths\tverdict`, one row per unique snapshot: codegen per target, comptime per directory (`comptime/{ast,errors,templates}` — one file per slug since the layout dedup). `test` is the test `file:line` from the trace (comma-joined when several tests write the same path — a slug collision); a snapshot traced without a location falls back to the test-source string literal that names it (the LSP asserts take a literal slug); `ORPHAN` when no test checked it. `verdict` is seeded from the 1.0.1-beta review reports (`--reports=<dir>`, default `../../specs/1.0.1-beta/06-snapshot-review` from the bot-lang root): every table row whose `verdict` column — located by its header cell, never by index — names the slug, restricted to the row's backend cell, as `<verdict> [report:line]`; `-` when no report names it. Report rows with a verdict that name no snapshot on disk (renamed or deleted tests, tests without a snapshot, harness-level rows) go to `review-unmatched.tsv`. Exits 3 when a row has no test `file:line`. |

### The trace (`BOTOPINK_SNAP_TRACE`)

`orphans` and `review` read the file a full, unfiltered
`BOTOPINK_SNAP_TRACE=/abs/trace zig build test` appended to — one line per
checked snapshot, written by `modules/compiler-core/src/utils/snap.zig` and
`modules/language-server/src/tests/snapshot.zig` (format and append-safety in
[`modules/compiler-core/src/utils/AGENTS.md`](../modules/compiler-core/src/utils/AGENTS.md#snapshot-trace-botopink_snap_trace)).
A filtered run makes every skipped snapshot look like an orphan.

```sh
rm -f /tmp/snap.trace
BOTOPINK_SNAP_TRACE=/tmp/snap.trace zig build test
scripts/snap_audit.sh --mode=orphans --trace=/tmp/snap.trace
scripts/snap_audit.sh --mode=review  --trace=/tmp/snap.trace
```

## comptime_bench.sh

`scripts/comptime_bench.sh [--n LIST] [--repeat R] [--reps N] [--target T]
[--project DIR]… [--keep] [--no-build]` — the measurement
[`specs/1.0.5-beta/14-comptime-on-beam/`](../../../specs/1.0.5-beta/14-comptime-on-beam/README.md)
is built on, so its numbers are re-measured on the reader's machine instead of quoted. Not a gate
stage: it builds projects and spends tens of seconds inside `erl`.

Two instruments, `evidence.md`'s E-1 and E-2:

| Instrument | What it measures |
| ---------- | ---------------- |
| E-1 | wall clock of one `botopink build`, best of `--repeat`, over a generated project with N call sites of **one** template whose literals are all distinct — so the memo cache in `comptime/infer.zig` never hits and each call site is a real evaluation. Reports the `.erl` modules and bytes the build left behind, and the marginal ms per evaluation. |
| E-2 | the in-node split — `compile:file` / `code:load_binary` / `main()` — measured inside a single `erl` over every module under the project's `.botopinkbuild/tmp/{template,decorator}`, `--reps` timed rounds after one untimed warm-up call each. |

Every project is generated or copied into a `mktemp -d` (deleted unless `--keep`): the script writes
nothing inside a repository. `--project DIR` copies a real project out of its checkout and builds it
there — a workspace member (a `{ "workspace": true }` dependency) is built inside a copy of its
enclosing workspace, and refused when no ancestor `botopink.json` declares `workspaces`; `BOTOPINK_LIB_ROOTS` is inherited, which is how a project whose libraries live in a sibling
checkout resolves them. A module that takes its data as an argument exports `main/1` rather than
`main/0` and cannot be run without that argument, so the `main()` column reads `-` for it while the
compile columns — what this front moves — stay comparable across steps.

## beam_export_audit.sh

`scripts/beam_export_audit.sh [--jobs=N] [--keep=<dir>] [<snap.md>…]` — needs
`erlc` on `PATH`, read-only. Extracts every `----- BEAM ASSEMBLY -- <m>.S` block
from `modules/compiler-core/snapshots/codegen/beam/beam/`, rewrites its
`{exports, […]}` form to name **every** `{function, …}` form, and assembles it
with `erlc +from_asm`. A recorded module exports only its entrypoints, and
`erlc +from_asm` drops an unexported function before `beam_validator` runs, so
a register-liveness bug in a method nothing exports stays invisible in the
RUN LOG; this audit makes it a rejection. Each rejected module prints
`REJECTED <slug> <module>` plus the validator's function, offset and reason;
the last line is `beam_export_audit: <ok>/<total> modules assembled`. Exit `0`
when every module assembled, `1` on any rejection, `2` on an argument error or
a missing `erlc`. Stage 6 of `gate.sh`, and a step of CI's `test` job on
ubuntu and macos.

## See also

- [`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) — the `bpmp` CLI surface used after install.
