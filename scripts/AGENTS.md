# scripts · AGENTS.md

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Installers, the release packaging helper, the gate, the lib-test and
vscode-test wrappers, the snapshot audit tool, the user-docs fence checker, the comptime-path
benchmark, and the tracked git hooks.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── install.sh         ← POSIX one-liner installer
├── install.ps1        ← Windows one-liner installer
├── release-pack.sh    ← per-target archive + sha256 packer (used by release.yml)
├── gate.sh            ← the ordered local gate (staged checks + `zig fmt --check modules`, build, format-check, test, test-bpmp, beam export audit, test-cli, test-libs, test-language, test-docs)
├── format-check.sh    ← `botopink format --check` over the compiler's canonical `.bp` trees (`TREES`) — decision 66's caller
├── test-libs.sh       ← runtime pre-flight + `botopink-lib-test` wrapper: one line per cell and per audited exclusion, one summary line (`zig build test-libs`)
├── test-vscode.sh     ← locate the sibling vscode-extension, `npm ci` once, `npm test` (`zig build test-vscode`)
├── check-docs.sh      ← compiles every `botopink` fence of docs.md/README.md (`zig build test-docs`)
├── tsc-check.sh       ← `tsc --noEmit --strict` over every `.d.ts` a commonJS build of libs/ (std + the bundled packages), the example projects and tests/language/modules emits (gate stage 11)
├── check-test-scratch.sh ← refuses a cwd-anchored `.botopinkbuild` path inside a `test` block or a `tests/` file (part of `zig build test`)
├── snap_audit.sh      ← read-only audit of every *.snap.md (7 modes)
├── beam_export_audit.sh ← assemble every beam snapshot module with every function exported
├── comptime_bench.sh  ← what the comptime path costs: build wall clock + the in-node compile/load/run split
├── codemod-import-without-from.py ← decision 206's one-shot migration: `from "<a module of this package>"` → the brace form (§ below)
├── lib/
│   ├── pool.sh        ← the bounded worker pool the shell runners share (sourced by ../tests/language/run.sh and check-docs.sh)
│   └── result-store.js ← the cell-result store of run.sh and check-docs.sh: keys, lookup, save (decision 229)
└── git-hooks/
    ├── pre-commit                 ← tracked hook, enabled by `git config core.hooksPath scripts/git-hooks` (see ../AGENTS.md §Local gate)
    ├── pre-merge-commit           ← the same gate for a merge that commits by itself (git runs this hook there, not pre-commit)
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

**Portability.** Every script runs under macOS's bash 3.2: a variable followed by a non-ASCII byte
is written braced (`${lib}·${target}`) — bash 3.2 reads the first byte of `·` as part of the name
under `set -u` (`lib\xc2: unbound variable`, `test-libs.sh` on macos-14).

## gate.sh

`scripts/gate.sh [--cold] [--staged]` — one ordered run, stopping at the first
failing stage (stages 4b–12 run side by side and are reported in this order —
§ Where the gate's time goes): staged-file checks (`--staged`: conflict markers, `zig fmt
--check` on staged `.zig`, no staged `*.snap.new` / `*.snap.md.new` candidate) and, every run,
`zig fmt --check modules` (a `.zig` file red anywhere fails the gate, staged or not — the
whole-tree check is the stage; the staged one is a commit's fast path), then the
`erl` on PATH against the release the compiler emits for (decision 228: `OTP_RELEASE`,
read from `modules/manifest/src/root.zig` because nothing is built yet — another release,
or an `erl` that does not answer, stops the gate there with the compiler's message,
`` botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it
on PATH ``), `zig build -Doptimize=ReleaseSafe` (§ Build mode), `scripts/format-check.sh` (`botopink
format --check` over the compiler's canonical `.bp` trees — decision 66's
caller), `zig build test` (`--cold` deletes
`modules/compiler-core/.botopinkbuild/runtime-cache` first, and every
`.botopinkbuild/cache/` under this checkout and each sibling library repository
— the erlang verdicts, the `.beam` cache, the cell durations, the cell-result
store, decision 225 — printing `gate: --cold deleted <dir>` for each, and passes
`--cold` to stages 8–10, § Warm and cold),
`snap_audit.sh --mode=runtime-parity` (front 18 step 4: the codegen tree under
both comptime runtimes, pairs equal but for their listing sections), `zig build
test-bpmp`, `scripts/beam_export_audit.sh`, `zig build test-cli`, `zig build
test-libs` (every cell the manifests declare, and an audit of every target a
manifest excludes — § test-libs.sh), `zig build test-language` (`tests/language/`, a red cell fails
it), `zig build test-docs`
(`check-docs.sh`), `scripts/tsc-check.sh` (§ tsc-check.sh), `zig build test-web` (compiler-core for wasm32 and `modules/compiler-web/tests/smoke.js` under node, default build mode — CI's step, in the gate by decision 231). CI (`.github/workflows/test.yml`) runs the same stages, in the same build mode (decision 226), minus the
staged checks. The pre-commit hook runs `--staged`; the run
that decides a merge adds `--cold`. After the staged checks the script unsets
every `git rev-parse --local-env-vars` variable a hook inherits (`GIT_DIR`,
`GIT_INDEX_FILE`, …): a stage that runs `git` in a scratch repository (bpmp's
install tests) would otherwise act on the committing repository.

### tsc-check.sh

`scripts/tsc-check.sh [<project>…]` builds every library the compiler ships
(`libs/<pkg>/` — `std` and each bundled package: `actions`, `http`, `log`,
`routing`, `validation`), every project under `examples/` and every
`tests/language/modules/<cell>/` with `botopink build --target commonJS
--typescript` into a scratch directory and runs `tsc --noEmit --strict --lib
es2022 --module commonjs` over each build's non-empty `.d.ts` files, one `tsc`
per project. A cell is left out only structurally — a `commonJS.expect` (the
program is refused there) or a manifest `"targets"` list without `commonJS` —
and a project that does not build, or emits no `.d.ts`, is red. `tsc` is
`npx -p typescript@<TS_VERSION>` (pinned in the script, so the verdict is a
function of the tree); no `npx` on `PATH` is a refusal, never a skip (decision
67). A planted typedef defect (`array<number>` for a `pub val` of an array)
reds `pub_val_across_modules` and `pub_val_in_a_test`; the `libs/` rows were
added after std's `testing/snapshots.d.ts` named the undeclared prelude record
`SourceLocation` (6 × `TS2304`) with no stage to see it — the six libraries
cost ~1.5 s of the stage's ~12 s.

### Build mode

The binaries stages 3 and 4b–12 run are built `-Doptimize=ReleaseSafe`, the
mode `release.yml` ships: the gate runs the compiler a user installs. Every
`zig build` the gate starts passes the same `$opt`, so no stage reinstalls a
Debug `zig-out/bin/*` over the one the others are running; stage 4's unit-test
binaries are built in Debug, as before (`zig build test` installs nothing).
ReleaseSafe keeps every runtime safety check — bounds, overflow,
`unreachable`, `std.debug.assert`; what it leaves out is Debug's allocator,
whose leak report never changed an exit status (`std/start.zig`). The same
cell prints the same bytes under both modes; a Debug compiler spends ~12× the
CPU on it (an `emilia-*` erlang cell: 189 CPU-s against 15), and stages 8 and
9 are thousands of compiles. After a gate `zig-out/bin/` holds ReleaseSafe
binaries; a plain `zig build` puts Debug ones back.

### Stage times, the plan, the budget

Every stage's `✓` line ends with its wall clock and CPU-seconds —
`✓ zig build test-libs — 3m41s wall, 2210 CPU-s` — measured with bash's
`time` keyword around the stage (the CPU of every child it waited for
included). Before stages 4b–12 start, `scripts/test-libs.sh --list`,
`tests/language/run.sh --list` and `scripts/check-docs.sh --list` print the
plan of stages 8, 9 and 10, and after each of the three its own tally is held
to its plan: `P + F + N` cells and `A + X` audits of `test-libs:` against the
`cell:*` and `audit` lines, `cells: <J> jobs — …, <A> audits` of the language
tests against the job lines, `docs: <N> fences` against the fence lines. A
stage that ran fewer than its plan fails the gate, green or not — a stage
cannot be narrowed to win time. The last line is the total,
`gate: every stage passed — 4m52s wall, 2120 CPU-s (budget 5m00s cold)`,
timed from the lock (a wait for another gate is not counted), against
`budget_cold=300` / `budget_warm=60` at the top of the script — decision 229 of
1.0.11-beta, for 16 idle cores. A run over it prints `gate: over budget`
in yellow with the load, and is not a red: a slow or shared machine is not a
broken tree.

### Warm and cold

Decisions 229 and 249 (front `00-gate/133-gate-speed`): stages 8, 9 and 10 keep a
**cell-result store** under `.botopinkbuild/cache/results/` — `lib-test/` of
each library's cache root (`botopink-lib-test`,
[`../modules/lib-test-runner/AGENTS.md`](../modules/lib-test-runner/AGENTS.md)
§ The result store), `language/` and `docs/` of this checkout (`lib/result-store.js`,
below). A warm run (no `--cold`) answers a job from a stored **pass** only when
the job's key is equal — the compiler's build configuration and its sources
partitioned by backend (below), the toolchain (`node`, the OTP release,
`wasmtime`, the environment a compiler or runtime reads) and the SHA-256 of
every byte the job reads; nothing decides what a change can affect.
A failure is never stored and always runs. Each stage prints `result store: <N>
jobs — <R> run, <S> from store` (`fences` for stage 10), and § counts holds `N`
and `R + S` to the stage's plan — the pairs of `test-libs --list` that spawn
(`cell:test`, `cell:compile`, `audit`), the job lines of `run.sh --list`, the
fence lines of `check-docs.sh --list`. `--cold` deletes every store with the
other caches and passes `--cold` to the three stages, which then never read it
and write the passes they ran (decision 249): the run that decides a landing
executes everything, and the warm run after it answers from what it ran.

**The compiler's part of a key** (decision 249). Not the binary's bytes — a
binary moves with any source — but the files it is built from (the set
`modules/source-stamp/src/root.zig` hashes) partitioned by backend in ONE list,
[`../modules/compiler-core/src/codegen/backend-partition.txt`](../modules/compiler-core/src/codegen/backend-partition.txt):
a file listed under a target is in that target's keys only, every other file
(lexer, parser, checker, comptime and its runtimes, the preludes, the embedded
std and bundled packages, the CLI, the runners, `build.zig`, the list itself) is
shared and in every key, and so are the Zig version, optimize mode and target
triple. A file the list does not name is shared, so a new emitter file re-runs
everything until it is listed. A job that compiles for no target (`reject/`, a
doc fence: `botopink check`) holds every target's files. Editing `codegen/wat.zig`
re-runs the wasm cells and the `check` jobs; editing `comptime/infer.zig` re-runs
everything. The erlang target owns no file: `codegen/erlang.zig` lowers every
comptime body on every target, so it is shared (the list says why for each
emitter file it leaves shared). Two guards make the partition safe to trust,
each stopping the whole run from reading or writing the store and naming why:
the binary must carry, on `botopink --version`'s `build:` line, the hash of
exactly the sources the key reads (a binary not rebuilt after an edit is
refused), and the list is audited — a listed file imported and used by a file
that is neither listed under the same target nor the list's `dispatcher`
(`codegen.zig`) fails the audit. `--cold` still runs everything at every
landing, so a wrong line can delay a red to the landing, never land one.

### Gate lock

**One gate per machine.** The stages already use every CPU, and two gates
side by side took far more than twice as long and starved each other's
timing-sensitive tests. `gate.sh` takes `${XDG_RUNTIME_DIR:-$HOME/.cache}/botopink/gate.lock`
before its first stage — a directory made with `mkdir` (atomic, and the macOS
runner's bash 3.2 has no `flock`) holding the holder's `pid`, `checkout` and
`since` — and removes it on exit. A second gate, from any checkout or worktree,
prints `gate: another gate holds the lock — pid <n>, <checkout>, since <time>;
waiting for it to finish` once and polls every 5 s; a lock whose pid is no
longer alive (a killed gate) is taken over. No flag or variable skips the wait.

### Green-tree record

`tree_key` hashes what a gate reads: this checkout's working tree and every
sibling library checkout `test-libs` reaches (`<checkout root>/repository/*`),
each as `git write-tree` would record it with every change added (a scratch
index seeded from the real one, so unchanged files are not re-read), plus
`zig version`, the OTP release and `node --version`. A gate that passes writes
the key it started from to `$(git rev-parse --git-path botopink-gate-green)` —
only when the key is the same at the end, so nothing moved under the run. A
`--staged` run (a commit, a merge) whose key was recorded green runs stage 1
and stops: nothing its diff can affect is left that a gate did not already run
on the same bytes and toolchain. Any other difference runs the whole gate, and
`--cold` never reads the record.

### Where the gate's time goes

The stages stay one ordered REPORT — the first failing stage in the order above
is the one reported, with the output and exit status the one-at-a-time gate
printed. Stages 1–4 still run one after the other, each only after the cheaper
ones passed. Stages 4b–12 only read what 2–4 built, and write their own scratch,
so they run side by side (`gate.sh` § side by side): each stage's stdout and
stderr are captured to one file, and once all of them have finished the blocks
are printed in stage order up to and including the first red one, whose failure
line ends the run with exit 1 — the stages after it are not printed, as the
serial gate never ran them. A red stage among 4b–12 therefore no longer saves the
time of the stages after it; that is the cost of a red run, never of a green
one. The time is otherwise saved inside the stages, by doing the same work once
and on every CPU, never by running less:

| Stage | What makes it fast | Where |
|---|---|---|
| `zig build test` | the compiler-core suite runs as `-Dtest-shards` processes (default: CPUs, at most 8), each the tests whose index is its own modulo the count; every test runs once and is reported by name, the summary's count is the unsharded one. The default runner is serial inside a process and the suite mostly waits on the node/erl/wasmtime its RUN LOGs spawn | [`../modules/test-shard/AGENTS.md`](../modules/test-shard/AGENTS.md) |
| `test-libs` | cells run on a bounded worker pool (one per CPU, bounded by `MemAvailable / 768 MiB`, each cell admitted only while `procs_running` ≤ CPUs) and are emitted in discovery order, byte for byte what `--jobs 1` prints | [`../modules/lib-test-runner/AGENTS.md`](../modules/lib-test-runner/AGENTS.md) § Parallel cells |
| `test-libs` (erlang cells) | `botopink test --target erlang` compiles each `.erl` of a run once (`precompileErlang`), not once per test module that loads it; the host-sidecar shipper resolves each library and probes each qualifier once per run | [`../modules/compiler-cli/src/cli/AGENTS.md`](../modules/compiler-cli/src/cli/AGENTS.md) (`test_cmd.zig`, `libs.zig`) |
| every stage that runs `botopink` | the binaries are ReleaseSafe (§ Build mode): ~12× less CPU per compile than Debug, the same output | § Build mode |
| `test-libs` (tests that build fixtures) | a test's scratch directory (`BOTOPINK_TEST_TMPDIR`) is the run directory's sibling, so no erlang runner compiles and loads the fixture projects a build test wrote (rakun-scheduling: ~6 500 `.erl` per test module); `botopink build --target erlang` answers a source the same OTP compiler already accepted from its verdict cache (rakun's build tests: 22 builds of one closure per cell) | [`../modules/compiler-cli/src/cli/AGENTS.md`](../modules/compiler-cli/src/cli/AGENTS.md) (`test_cmd.zig`, `build.zig`) |
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

## lib/result-store.js

Run by `node`, never sourced. The cell-result store of `../tests/language/run.sh`
and `check-docs.sh` (decision 229; `botopink-lib-test` keeps the same store in
Zig, `../modules/lib-test-runner/src/result_store.zig`, with the same probes and
the same environment list). Four subcommands:

| Command | What |
|---|---|
| `keys --spec <f> --out <f> --base <dir> --compiler <botopink> [--global-file <name>=<path>]… [--global-tree <name>=<dir>]… [--global-text <t>] [--scratch <dir>]` | one key per spec line `<id>\t<label>\t<input>…` — SHA-256 over the version tag, the toolchain, the compiler's build and shared sources and the sources of the target the label's first word names (every target's for `*`), every global file and tree, the label and every input (`<path>` or `<name>=<path>`, relative to `--base`; a file by content and executable bit, a directory as every path, directory and file in it). Writes `<id>\t<key>` or `<id>\t-\t<why>` for an input it cannot enumerate: a symbolic link, a manifest dependency that is `git` or a `path` leaving the input, a library root above `--scratch` |
| `lookup --store <dir> --keys <f> --work <dir> --out <f>` | every keyed entry present is copied to `<work>/<id>` (its time refreshed) and its id listed |
| `save --store <dir> --before <f> --after <f> --work <dir> --hits <f> --pass lines-ok\|exists` | every job that ran, whose key is the same in `--after` (computed again after the run), and whose verdict is a pass (`lines-ok`: every line's third tab field `ok` or `audit`; `exists`: the file exists) is written, staged and renamed; prints `<written> <moved>`; deletes entries unused for 7 days |
| `toolchain` | the toolchain part of every key |
| `compiler --bin <botopink>` | the compiler and toolchain part of every key — `why <reason>` when nothing may be stored, else `build …`, `shared <hex>`, `target <t> <hex>` per target, then the toolchain; `botopink-lib-test` takes its keys' compiler part from here |
| `source-hash --root <checkout>` | the hash `source_stamp` computes over a checkout — what a binary built from it prints on its `build:` line (the tests' shim compilers use it) |

The id names the verdict file and is not part of the key: two jobs with one label
and the same inputs are one job. The store is `<dir>/<kk>/<key>`.

## codemod-import-without-from.py

Decision 206 (1.0.11-beta `01-compiler/129-import-without-from`): `from "<name>"`
names a package — std, a bundled package or a declared dependency — and a
module of the importing package is imported by its path inside the braces.
The script rewrites every import whose `from` named a module of its own
package, over any number of trees at once:

```sh
python3 scripts/codemod-import-without-from.py [--write] [--format <botopink>] <root>...
```

- **What it rewrites.** `import {a, b as c} from "x.y";` → `import {x.y.a, x.y.b as c};`
  (`x/y` → `x.y`), every leaf behind its dotted path — the spelling `botopink
  format` prints (the formatter flattens a group, so a group is never the
  canonical form); a brace list carrying a comment is kept verbatim inside one
  group per path segment instead. Nothing outside the import changes.
- **Which import names a module of the package.** A package is a
  `botopink.json` that is not a workspace, or a test's fixture project (a
  `src/` of `*.bp.fixture` sources whose manifest the test writes, rakun's
  `test/fixtures/<name>/`); its modules are its `src` tree (`x/mod.bp` is
  `x`), plus the flat `test/` suite for a test file. The source
  names a module by its full path, else by a last segment only one module
  has; it is the package's when that module exports every item (`pub fn` /
  `val` / `var` / `type` / `behavior` / `mod` / `implement` / `extend`, or a
  submodule for the namespace form). Otherwise a source whose first segment
  is a bundled or declared package keeps its `from` (it names the package),
  and anything else is printed `UNDECIDED` and left for a hand edit — a
  decorator-emitted name, or an item that resolved through the whole program
  to another module. A package directory holding a `*.expect` that names
  `module-import-with-from` (the language suite's cell pinning the refusal) is
  not touched.
- **Formatting.** With `--format`, each file it changed that `botopink format
  --check` accepted before is formatted after, so the trees stay canonical.
- **Output.** One `rewrite` line per import, one `UNDECIDED` line per import it
  left, and the tally; exit 1 when anything is undecided. Without `--write` it
  only reports.

A script and not a `botopink` subcommand: the old form is refused by the
compiler, whose diagnostic already writes the fix for one import
(`error[module-import-with-from]`); a subcommand would keep a reading of the
retired spelling inside the CLI for good, which decision 67 refuses. The script
migrates the seven repositories once and needs no build.

## format-check.sh

`scripts/format-check.sh` — stage 3 of `gate.sh` and a step of CI's `test` job:
`zig-out/bin/botopink format --check <tree>` for every tree in its `TREES`
array, which names the trees the gate holds canonical: `examples` (every
example project and `hello.bp`), `libs/std`, `libs/routing`, `libs/actions`,
`libs/validation`, `libs/log`, `libs/http`, `modules/compiler-cli/tests`, `modules/manifest/tests` and
`tests/language` — every tracked `.bp` of the checkout is under one of them.
`format --check` on a directory reaches every `.bp` and `.d.bp` under it
(nested projects included) and structurally leaves out hidden directories,
`node_modules`, a `reject/<n>.bp` beside its `<n>.expect` and a
`modules/<cell>/` file the cell's `<target>.expect` names that does not lex or
parse (`modules/compiler-cli/src/cli/format_cmd.zig`) — under `tests/language`,
every `reject/` cell and `modules/lexer_error_in_imported_module/src/pattern.bp`;
the list is not a skip list and there is no other way to exempt a file
(decision 67). A tree that is red is a red gate, fixed by `botopink format
<tree>` in a reformat-only commit; a tree the printer cannot round-trip is a
formatter defect (`01-compiler/16-formatter`), fixed in the printer. A reformat
carries what quotes the text it moves, in the same commit: `libs/std`'s source
is quoted verbatim by the `std_package_*` codegen snapshots and by two LSP
snapshots (`definition_std_module_member`, `completion_array_methods`), and a
`modules/<cell>/<target>.expect` pins a `<file>:<L>:<C>` the reformat of that
file can move. Exit `0` when every listed tree is canonical;
`1` naming the tree and the files, with the `Unchanged` lines filtered out.

## git-hooks/

`git-hooks/pre-commit` is self-contained: it sources
`git-hooks/lib/runner-standalone.sh`, which runs `gate.sh --staged` of the
committing checkout. `git-hooks/pre-merge-commit` runs the same: `git merge`
runs `pre-merge-commit`, **not** `pre-commit`, when a merge needs no conflict
resolution and records its commit itself, so without it an auto-merge was
never gated unless its author amended it (a merge that stops on a conflict is
committed with `git commit`, which runs `pre-commit`). Nothing installs them; a
clone enables both with `git config core.hooksPath scripts/git-hooks` (the
relative path resolves against the checkout's root, so every worktree runs its
own tracked hooks).

## test-libs.sh

Resolves the core dir (meta layout `repository/botopink-lang/` or this repo's
root), exits `1` if `zig-out/bin/botopink-lib-test` is not built, warns (without
gating) for each missing `node`/`escript`/`erlc`/`wasmtime`, then runs the runner
in `--json` mode — discovery is the runner's, workspace members included, so
the script exports no root — and prints one line per (library, target) pair
after that pair's diagnostics, and one summary line.

**The manifest decides the matrix.** A member runs on the targets its
`botopink.json` declares and on no other: a target its `"targets"` list excludes
is not a cell, and nothing runs it. **A cell that exists is green or the run
fails** — there is no file that lists a red cell away or pins how many of its
tests may fail, and **no flag or environment variable changes any of it**
(decision 67; 1.0.11-beta gate-a). The two ledger files this script used to
read, the variables that swapped them and the runner's flag that ran an excluded
cell are deleted, not hidden.

**A restriction is audited on every run** (gate-d). For each target a member
excludes that `botopink test` can run, the runner spawns `botopink build
--target <excluded>` in the member and accepts the exclusion only when the build
is refused and its first error is the missing host binding (`` `f` has no
`#[@External.<Target>(…)]` for the <backend> backend ``): the member structurally
cannot run there. A member that builds on the target it excludes, or whose build
fails there for any other reason, fails the run — the exclusion would hide a cell
that could run, or a red that is somebody's to fix. The remedy is in the
message: delete the `"targets"` line, or file the compiler row that makes the
build refuse it. The rule is the runner's
([`../modules/lib-test-runner/AGENTS.md`](../modules/lib-test-runner/AGENTS.md)
§ The restriction audit); this script only prints its verdict.

| Line | Meaning | Fails the run |
|---|---|---|
| `pass` | the library compiled and every test passed | no |
| `FAIL` | a module did not compile or a test failed; the diagnostic is above the line | **yes** |
| `no tests — …` | no `test` block; the `.bp` sources compiled (`botopink build`) — one that does not compile is a `FAIL` | no |
| `excluded by "targets" — structural: <refusal> (<file>:<line>:<col>)` | not a cell; the audit quotes the refusal that proves the exclusion | no |
| `NOT STRUCTURAL — excluded by "targets", and <what the audit found>` | not a cell; the audit refused the exclusion | **yes** |
| `NOT RUNNABLE — …` | the target is one `botopink test` cannot run (beam, wasm); met only when such a target is asked for by name. Nothing ran, and a pair that did not run is never a pass | **yes** |

The summary is `test-libs: <P> passed, <F> failed, <N> without tests, <A>
restrictions audited`, with `, <X> restrictions not structural` and `, <S> not
runnable by botopink test` appended when they are not zero (each fails the run); `<P> + <F> + <N>` is
the number of cells the manifests declare for the requested targets, and
`--list` prints that plan without running it (`cell:*` lines are cells, `audit`
lines the excluded pairs). Exit `1` when a cell fails, an exclusion is not
structural, a requested target is one `botopink test` cannot run, or a workspace document quotes the tool's member list and disagrees
with it (`../modules/lib-test-runner/AGENTS.md` § Documents that quote the
tool); otherwise the runner's own exit (`0`, or its error exit for bad arguments
or no library root). An explicit `--json` or `--list` argument execs the runner
raw: its output, not a verdict.

The summary is preceded by the runner's result-store line, `result store: <J>
jobs — <R> run, <S> from store` (with the runner's note in parentheses when it
read or wrote nothing: `--cold`, a universe it cannot hash, inputs that moved),
and a pair answered from a stored pass ends its own line with `(from store)`
(§ Warm and cold; the store is the runner's).

The audit costs one `botopink build` per excluded (member, target) pair — the
dependency-closure compile the cell would have cost, and no test run. The pairs
run on the same worker pool as the cells.

## check-docs.sh

`scripts/check-docs.sh [--compiler <botopink>] [--doc <file>]… [--list] [--jobs <n>] [--self-test]`
(`zig build test-docs`) — extracts every ```` ```botopink ```` fence of the user
docs (default `docs.md README.md`) into a scratch project and runs `botopink
check` on it. An HTML comment on the line above the fence chooses the treatment:

| Directive | Treatment | Verdict |
|---|---|---|
| none | a whole module, `src/main.bp` | must compile |
| `<!-- docs-check: body -->` | statements wrapped in `fn main() { … }` | must compile |
| `<!-- docs-check: project <name> <path> -->` | one file of a multi-file project — every fence with the same `<name>` is written at its `<path>` and the project is checked once, one of them at `src/main.bp`; the fence may be of any language (a ```` ```json ```` fence at `botopink.json` is the manifest, whose `dependencies` resolve by name through the library roots the script sets: `libs/`, the sibling checkouts next to the repository and under `repository/`) | the project must compile; its verdict counts for every fence written into it |
| `<!-- docs-check: reject [body] <expectation> -->` | code the compiler must refuse; `body` wraps it in `fn main` first | `botopink check` must exit non-zero and its first `error` line must contain `<expectation>` verbatim — an error id (`iter-await`) or a message (`'f' expects 2 argument(s), got 0`); a fence that compiles, or is refused with another first diagnostic, fails (the doc claims a refusal the compiler does not make); one refusal per fence, the checker stops at the first |

There is no directive that skips a fence (1.0.11-beta decision gate-e): a table,
a grammar or a layout sample is not code and is fenced as ```` ```text ````. A
failing fence, an unknown directive, a directive on a fence that is not
```` ```botopink ```` (`project` excepted), a `reject` with no expectation and a
named project with no `src/main.bp` each fail the run and name the doc and the
fence's line. `--list` prints every fence with its directive and compiles
nothing. Every run starts with the harness's own contract — a synthetic doc of
nine fences with known verdicts (a `reject` that compiles ✗, one refused with
another diagnostic ✗, the right one ✓, a `reject body` ✓, a `skip` directive ✗, a
module that does not compile ✗, one that does ✓, a `reject` with no expectation
✗, a `body` directive on a ```` ```text ```` fence ✗); a verdict that differs
fails the run before the docs are judged, and `--self-test` runs only it. The
exit line is `docs: <N> fences — <N> checked, 0 skipped, <F> failed` with
`checked + failed = fences` (`0 skipped` is a constant). State for a named
project lives in the scratch tree (`.name`, `.origin`, `.files`, `src/main.bp`),
not in an associative array, so the script runs under the macOS runner's bash
3.2. The checks run on `lib/pool.sh` (`--jobs`, default one per CPU bounded by
memory): the report is written in fence order with a `\001CHECK <k>`
placeholder per check, and printed after the pool has drained with each
placeholder replaced by its verdict line, so any `--jobs` prints the serial
run's bytes.

**The result store** (§ Warm and cold). A deferred check whose key equals a
stored pass is answered from `<repo>/.botopinkbuild/cache/results/docs/` (its
`<k>.ok` is written before the pool starts, and the pool skips it); every other
check runs. The key (`lib/result-store.js`) is the compiler's build and every
backend's sources (`check` is target-independent), this
script, `lib/pool.sh`, `lib/result-store.js`, the toolchain, every package the
library roots hold (each child of `libs/`, of the sibling directory and of
`repository/` that carries a `botopink.json` — what a fence's `dependencies` can
name) and the check's own scratch project whole — the fence's text, the
manifest, every file of a named project — with its mode and expectation; never
the check's number or the doc's line, so moving a fence does not move its key.
A project whose manifest has a `git` dependency is never stored (the docs' one
such project, `library`, is named on a `never stored` line). The harness's nine
fences always run. The exit line is preceded by `result store: <N> fences — <R>
run, <S> from store` (a fence judged without the compiler counts as run);
`--cold` never reads the store and writes its passes, `--store-root <dir>`
keeps it elsewhere.

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
`.botopinkbuild` inside one — and **anywhere** in a file under a `tests/`
directory, which is test-only as a whole: the harness helpers a test calls are
functions outside every `test` block, and that is how the build roots of
`codegen/tests/helpers.zig` and `comptime/tests/helpers.zig` and the eval roots
of `language-server/src/tests/helpers.zig` escaped the block-only scan (they are
`test_scratch` paths now).

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
| `runtime-parity` | Front 18 step 4, a gate stage: every `codegen/<beam\|wat>/…` and `comptime/runtime/<beam\|wat>/…` file has its pair, and each pair is `diff`-equal once `withoutListings` sets aside the `COMPTIME BEAM ASSEMBLY`/`COMPTIME WAT` fenced bodies (and a legacy `COMPTIME ERLANG`) (the only text the runtimes may differ in). A difference or a missing member prints a unified diff / a `MISSING` line and exits 3 — a defect in one runtime, never re-recorded away; no allow-list. |
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
RUN LOG; this audit makes it a rejection. A `----- COMPTIME BEAM ASSEMBLY`
block — a comptime body the compiler lowered and assembled itself and the node
loads with no validator in between (front 14 step 3) — is assembled the same
way, so this is where `beam_validator` reads the comptime lowering's output;
pass `modules/compiler-core/snapshots/comptime/runtime/beam/*.snap.md` to
cover the comptime tree's five. Each rejected module prints
`REJECTED <slug> <module>` plus the validator's function, offset and reason;
the last line is `beam_export_audit: <ok>/<total> modules assembled`. Exit `0`
when every module assembled, `1` on any rejection, `2` on an argument error or
a missing `erlc`. Stage 6 of `gate.sh`, and a step of CI's `test` job on
ubuntu and macos.

## See also

- [`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) — the `bpmp` CLI surface used after install.
