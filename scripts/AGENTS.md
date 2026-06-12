# scripts · AGENTS.md

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Two installer scripts + the release packaging helper + the snapshot
meta-audit tool.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── release-pack.sh    ← per-target archive + sha256 packer (used by release.yml)
├── install.sh         ← POSIX one-liner installer
├── install.ps1        ← Windows one-liner installer
└── snap_audit.sh      ← meta-audit of every *.snap.md (4 read-only modes)
```

## Installers — contract

Both scripts produce the **same** on-disk layout (see
[`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) §Storage):

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

`<file>` shape (matches `release-pack.sh` output):

```text
<binary>-<version>-<target>.<ext>
<binary>-<version>-<target>.<ext>.sha256       (single line: <64hex>)
```

`<binary>` is one of `botopink`, `botopink-lsp`, `botopink-lib-test`,
`bpmp`. `<ext>` is `tar.gz` (POSIX) or `zip` (Windows). The sha256
sidecar is mandatory — both scripts abort with both digests on
mismatch.

### Integrity model

1. Fetch `<archive>` + `<archive>.sha256` over HTTPS only.
2. Compute sha256 of `<archive>`; compare to the sidecar's first token.
3. Mismatch ⇒ exit 1 with both digests printed. No partial install.

The POSIX script uses `curl --proto '=https' --tlsv1.2 -sSfL` when
available (falling back to `wget --https-only -qO-`). The PowerShell
script uses `Invoke-WebRequest -UseBasicParsing`.

### Env / flags

| Variable / flag                                  | install.sh | install.ps1 | Effect                                                  |
| ------------------------------------------------ | ---------- | ----------- | ------------------------------------------------------- |
| `--target <tuple>`                               | ✓          | `-Target`   | Override OS/arch detection.                             |
| `--version <v>` / `BOTOPINK_VERSION`             | ✓          | `-Version` / `$env:BOTOPINK_VERSION` | Pin release tag (default: `latest`). |
| `--install-dir <p>` / `BOTOPINK_INSTALL_DIR`     | ✓          | `-InstallDir`                       | Override `$BPMP_HOME`.                  |
| `--force` / `BOTOPINK_INSTALL_FORCE=1`           | ✓          | `-Force`                            | Overwrite an existing install.          |
| `--modify-path`                                  | ✓          | (manual)    | Append PATH export to detected shell rc (idempotent).   |
| `--quiet`                                        | ✓          | `-Quiet`    | Suppress non-error output.                              |
| `--help` / `-Help`                               | ✓          | ✓           | Print usage and exit 0.                                 |

`--modify-path` greps the target rc file for `$BPMP_HOME/bin` before
appending — idempotent across re-runs.

### Exit codes

| Code | When                                                           |
| ---- | -------------------------------------------------------------- |
| 0    | Success.                                                       |
| 1    | Any failure (download, sha256 mismatch, clobber refusal, …).   |
| 2    | Unknown CLI flag (install.sh only).                            |

### Clobber refusal

If `$BPMP_HOME` is non-empty and `--force` / `BOTOPINK_INSTALL_FORCE=1`
is not set, both scripts exit 1 with the three-line remediation:

```text
error: $BPMP_HOME (~/.bpmp) already exists.
       To upgrade, run:    bpmp self update
       To start over, run: bpmp self uninstall   (then re-run this installer)
       To force overwrite: BOTOPINK_INSTALL_FORCE=1 sh install.sh
```

This is the one big departure from rustup's interactive installer —
piping `curl | sh` happens in non-TTY contexts (CI, Dockerfile), so we
do not prompt.

### macOS quarantine note

After install on macOS, `install.sh` prints a hint about
`xattr -d com.apple.quarantine ~/.bpmp/botopink/versions/stable/*`.
v0.beta.18 does not codesign the binaries; notarisation is on the
roadmap.

### Windows symlink fallback

`install.ps1` first tries `New-Item -ItemType SymbolicLink`. Without
developer mode or admin, this errors — the script falls back to a
directory copy and prints a one-line note ("future `bpmp self update`
may take a tick longer to swap"). This mirrors rustup's behaviour.

## release-pack.sh

`scripts/release-pack.sh <target> <version> <ext>` is the helper
`release.yml` invokes per matrix cell. Reads from `zig-out/bin/`,
writes to `dist/<binary>-<version>-<target>.<ext>` with a sidecar
`.sha256`. Each archive carries **one file** at top level — no
embedded directory — so the install script can extract straight into
`$BPMP_HOME/botopink/versions/<v>/`.

See [`../AGENTS.md`](../AGENTS.md) §Release pipeline for the matrix
shape and [`../.github/workflows/release.yml`](../.github/workflows/release.yml)
for the per-step wiring.

## snap_audit.sh

`scripts/snap_audit.sh --mode={runlog,legacy,values,coverage}` is a
pure-shell, read-only auditor of every `*.snap.md` in the workspace:

| Mode       | Purpose                                                                                                           | Output                       |
| ---------- | ----------------------------------------------------------------------------------------------------------------- | ---------------------------- |
| `runlog`   | Classify every codegen snap as `(a)` silent / `(b)` observable / `(c)` deferred-observable + capture RUN LOG state. | `build/snap-audit/runlog.tsv`   |
| `legacy`   | Grep every snap's SOURCE block for retired surface (`*fn`, legacy `@external(<target>, …)`, `@[name]`, `when($argc==N)`, `string.length()`, `value:length()`). | `build/snap-audit/legacy.tsv`   |
| `values`   | Dump `(backend, source_sha1, path, runlog_b64)` for every `(b)` codegen snap with non-empty RUN LOG so F3 can cross-check values against an external runner. | `build/snap-audit/values.tsv`   |
| `coverage` | Pivot of `runlog` by backend × label × state; prints the matrix to stdout and saves a copy.                        | `build/snap-audit/coverage.tsv` |

Pure shell + `awk` + `grep -nE` (no compiler-core dependency — runs
from any worktree without a build). Reports under `build/snap-audit/`
are git-ignored.

Authored by
[`tasks/v0.beta.20/specs/snap-audit.md`](../../../tasks/v0.beta.20/specs/snap-audit.md) — see that spec for the audit's full intent + the F0–F5 phase list.

## See also

- [`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) — what the user
  does *after* install (the `bpmp` CLI surface).
- [`tasks/v0.beta.18/specs/install-script.md`](../../../tasks/v0.beta.18/specs/install-script.md)
  — the authoring intent.
- [`tasks/v0.beta.18/specs/release-workflows.md`](../../../tasks/v0.beta.18/specs/release-workflows.md)
  — the producer of the assets these scripts consume.
