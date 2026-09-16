# scripts · AGENTS.md

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Installers, the release packaging helper, the gate, the lib-test and
vscode-test wrappers, the snapshot audit tool, and the tracked git hooks.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── install.sh         ← POSIX one-liner installer
├── install.ps1        ← Windows one-liner installer
├── release-pack.sh    ← per-target archive + sha256 packer (used by release.yml)
├── gate.sh            ← the ordered local gate (staged checks, build, test, test-cli, test-libs)
├── install-hooks.sh   ← install the pre-commit shim into the repository's hooks dir
├── test-libs.sh       ← runtime pre-flight + `botopink-lib-test` wrapper with known reds (`zig build test-libs`)
├── known-red-libs.txt ← library cells known red, each with its owning front
├── test-vscode.sh     ← locate the sibling vscode-extension, `npm ci` once, `npm test` (`zig build test-vscode`)
├── snap_audit.sh      ← read-only audit of every *.snap.md (4 modes)
└── git-hooks/
    ├── pre-commit                 ← tracked hook (see ../AGENTS.md §Local gate)
    └── lib/runner-standalone.sh   ← standalone runner → `gate.sh --staged`
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
--check` on staged `.zig`), `zig build`, `zig build test` (`--cold` deletes
`modules/compiler-core/.botopinkbuild/runtime-cache` first), `zig build
test-cli`, `zig build test-libs`. The pre-commit hook runs `--staged`; the run
that decides a merge adds `--cold`.

## install-hooks.sh

Writes `<git common dir>/hooks/pre-commit`, a shim that execs the tracked
`scripts/git-hooks/pre-commit` of the committing checkout (the hooks dir is
shared across worktrees). Refuses to overwrite a foreign hook without `--force`.

## test-libs.sh

Resolves the core dir (meta layout `repository/botopink-lang/` or this repo's
root), exits `1` if `zig-out/bin/botopink-lib-test` is not built, warns (without
gating) for each missing `node`/`escript`/`erlc`/`wasmtime`, then runs the runner
in `--json` mode and prints one line per cell — `pass`, `FAIL`, `known red — <front>
<reason>`, `skipped — <reason>`, `no tests` — after that cell's diagnostics, and a
count summary. Exit `1` when an unlisted cell fails or a listed known red passes;
otherwise `0` (or the runner's own error exit). An explicit `--json` argument
bypasses all of this and execs the runner raw. `BOTOPINK_KNOWN_RED_LIBS`
overrides the list path.

## known-red-libs.txt

`<lib> <target> <owner> <reason…>` per line, `#` comments. The owning front
deletes its line in the commit that turns the cell green, which makes the cell
a hard assert.

## test-vscode.sh

Finds the `vscode-extension` checkout (`BOTOPINK_VSCODE_DIR`, else the first
`<ancestor>/repository/vscode-extension` or `<ancestor>/vscode-extension` walking
up from this repo), runs `npm ci` when `node_modules/` is absent, then execs
`npm test`. Exits 1 when the checkout or `npm` is missing — never a silent pass.

## snap_audit.sh

`scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}` — pure shell +
`awk` + `grep`, read-only, no build needed. Reports go to
`build/snap-audit/<mode>.tsv` (git-ignored).

| Mode       | Purpose |
| ---------- | ------- |
| `runlog`   | Classify every codegen snapshot as silent / observable / deferred-observable, with RUN LOG state (`nonempty`/`empty`/`missing`). |
| `legacy`   | Grep every snapshot's SOURCE block for retired surface (`*fn`, legacy `@external(<target>, …)`, `@[name]`, `when($argc==N)`, `string.length()`, `value:length()`). |
| `values`   | Dump `(backend, source_sha1, path, runlog_text)` for observable codegen snapshots with a non-empty RUN LOG, for cross-checking against an external runner. |
| `coverage` | Pivot of `runlog` by backend × label × state; printed and saved. |

## See also

- [`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) — the `bpmp` CLI surface used after install.
