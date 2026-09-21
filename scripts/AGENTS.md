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
├── gate.sh            ← the ordered local gate (staged checks, build, format-check, test, test-bpmp, beam export audit, test-cli, test-libs, test-language, test-docs)
├── format-check.sh    ← `botopink format --check` over the compiler's canonical `.bp` trees — decision 66's caller; the red trees and their causes are in its header
├── test-libs.sh       ← runtime pre-flight + `botopink-lib-test` wrapper with known reds (`zig build test-libs`)
├── known-red-libs.txt ← library cells known red, each with its owning front
├── test-vscode.sh     ← locate the sibling vscode-extension, `npm ci` once, `npm test` (`zig build test-vscode`)
├── check-docs.sh      ← compiles every `botopink` fence of docs.md/README.md (`zig build test-docs`)
├── snap_audit.sh      ← read-only audit of every *.snap.md (6 modes)
├── beam_export_audit.sh ← assemble every beam snapshot module with every function exported
├── comptime_bench.sh  ← what the comptime path costs: build wall clock + the in-node compile/load/run split
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
failing stage: staged-file checks (`--staged`: conflict markers, `zig fmt
--check` on staged `.zig`), `zig build`, `scripts/format-check.sh` (`botopink
format --check` over the compiler's canonical `.bp` trees — decision 66's
caller), `zig build test` (`--cold` deletes
`modules/compiler-core/.botopinkbuild/runtime-cache` first), `zig build
test-bpmp`, `scripts/beam_export_audit.sh`, `zig build test-cli`, `zig build
test-libs`, `zig build test-language` (`tests/language/`, expected failures in
`tests/language/expected-failures.txt`), `zig build test-docs`
(`check-docs.sh`). CI (`.github/workflows/test.yml`) runs the same stages minus the
staged checks. The pre-commit hook runs `--staged`; the run
that decides a merge adds `--cold`. After the staged checks the script unsets
every `git rev-parse --local-env-vars` variable a hook inherits (`GIT_DIR`,
`GIT_INDEX_FILE`, …): a stage that runs `git` in a scratch repository (bpmp's
install tests) would otherwise act on the committing repository.

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
in `--json` mode and prints one line per cell — `pass`, `FAIL`, `known red — <front>
<reason>`, `skipped — <reason>`, `no tests` (the library has no `test` block and
compiled; one that does not compile is a `FAIL`) — after that cell's diagnostics, and a
count summary. Exit `1` when an unlisted cell fails or a listed known red passes;
otherwise `0` (or the runner's own error exit). An explicit `--json` argument
bypasses all of this and execs the runner raw. `BOTOPINK_KNOWN_RED_LIBS`
overrides the list path.

## known-red-libs.txt

`<lib> <target> <owner> <reason…>` per line, `#` comments. The owning front
deletes its line in the commit that turns the cell green, which makes the cell
a hard assert. Live entries: `jhonstart commonJS` and `jhonstart erlang`, owned
by the 1.0.10-beta jhonstart library front — `src/hooks.bp:109` writes `use` in
a `-> Element` body without `#[@context]`, which decision 88 (front 19,
`use-without-context-effect`) refuses until the library adds the annotation.

## check-docs.sh

`scripts/check-docs.sh [--compiler <botopink>] [--doc <file>]… [--list]`
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

## test-vscode.sh

Finds the `vscode-extension` checkout (`BOTOPINK_VSCODE_DIR`, else the first
`<ancestor>/repository/vscode-extension` or `<ancestor>/vscode-extension` walking
up from this repo), runs `npm ci` when `node_modules/` is absent, then execs
`npm test`. Exits 1 when the checkout or `npm` is missing — never a silent pass.

## snap_audit.sh

`scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}`, and
`--mode={orphans,review} --trace=<file> [--reports=<dir>]` — pure shell +
`awk` + `grep`, read-only, no build needed. Reports go to
`build/snap-audit/<mode>.tsv` (git-ignored).

| Mode       | Purpose |
| ---------- | ------- |
| `runlog`   | Classify every codegen snapshot as silent / observable / deferred-observable, with RUN LOG state (`nonempty`/`empty`/`missing`). |
| `legacy`   | Grep every snapshot's SOURCE block for retired surface (`*fn`, legacy `@external(<target>, …)`, `@[name]`, `when($argc==N)`, `string.length()`, `value:length()`). |
| `values`   | Dump `(backend, source_sha1, path, runlog_text)` for observable codegen snapshots with a non-empty RUN LOG, for cross-checking against an external runner. |
| `coverage` | Pivot of `runlog` by backend × label × state; printed and saved. |
| `orphans`  | `kind\tpath` for every `*.snap.md` on disk (compiler-core + language-server) that no test checked in the traced run (`orphan`), and every traced path absent from disk (`missing`). Exits 3 when either list is non-empty. |
| `review`   | The review worksheet, `suite\tslug\ttest\tpaths\tverdict`, one row per unique snapshot: codegen per target, the four `comptime/<runtime>/` copies collapsed into one row with every path. `test` is the test `file:line` from the trace (comma-joined when several tests write the same path — a slug collision); a snapshot traced without a location falls back to the test-source string literal that names it (the LSP asserts take a literal slug); `ORPHAN` when no test checked it. `verdict` is seeded from the 1.0.1-beta review reports (`--reports=<dir>`, default `../../specs/1.0.1-beta/06-snapshot-review` from the bot-lang root): every table row whose `verdict` column — located by its header cell, never by index — names the slug, restricted to the row's backend cell, as `<verdict> [report:line]`; `-` when no report names it. Report rows with a verdict that name no snapshot on disk (renamed or deleted tests, tests without a snapshot, harness-level rows) go to `review-unmatched.tsv`. Exits 3 when a row has no test `file:line`. |

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
there; `BOTOPINK_LIB_ROOTS` is inherited, which is how a project whose libraries live in a sibling
checkout resolves them. A module that takes its data as an argument exports `main/1` rather than
`main/0` and cannot be run without that argument, so the `main()` column reads `-` for it while the
compile columns — what this front moves — stay comparable across steps.

## beam_export_audit.sh

`scripts/beam_export_audit.sh [--jobs=N] [--keep=<dir>] [<snap.md>…]` — needs
`erlc` on `PATH`, read-only. Extracts every `----- BEAM ASSEMBLY -- <m>.S` block
from `modules/compiler-core/snapshots/codegen/beam/`, rewrites its
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
