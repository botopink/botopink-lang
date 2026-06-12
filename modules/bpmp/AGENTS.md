# bpmp · AGENTS.md

> Path: `modules/bpmp/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

`bpmp` — Boto Pink Package Manager + toolchain manager. A self-contained Zig
program. **No `compiler-core` import.** bpmp does not link the compiler; it
*spawns* it (same pattern as `lib-test-runner`) with `BOTOPINK_LIB_ROOTS`
pointing at its on-disk package store.

bpmp reads / writes three files in a project:

| File                  | Owned by | Read by                                  |
| --------------------- | -------- | ---------------------------------------- |
| `botopink.json`       | bpmp + compiler | compiler (src/files/dependencies); bpmp (botopink, requires) |
| `botopink.lock.json`  | bpmp only | bpmp (commit-pinned compiler-version replay)            |
| `botopink.lock`       | bpmp only | bpmp (commit-pinned object-form lib-dep replay) — v0.beta.20 `install-from-deps`     |

Compiler-facing fields pass through verbatim — bpmp only writes the
bpmp-facing `botopink` (compiler version constraint) and `requires`
(per-dep constraint), and appends to `dependencies` when adding a dep.

`botopink.lock` is the **v0.beta.20 install-from-deps** flavour — distinct
from `botopink.lock.json` (compiler distribution). It tracks object-form
`dependencies` (libs declared as `{ "<name>": { "git": ..., "branch": ... } }`)
keyed by their resolved 40-char commit SHA. `bpmp install` materialises each
into `$BPMP_HOME/store/<name>/<rev>/` and symlinks `<project>/.botopinkbuild/deps/<name>`
into it.

## Tree

```text
modules/bpmp/
├── AGENTS.md            ← you are here
├── docs.md              ← end-user tutorial
├── examples.md          ← three worked walk-throughs
└── src/
    ├── main.zig         ← entry point + command dispatch
    ├── cli.zig          ← Command/Context types + help renderer
    ├── version.zig      ← bpmp's own version string
    ├── manifest.zig     ← botopink.json read/write (preserves unknown fields)
    ├── lockfile.zig     ← botopink.lock.json read/write (schema-versioned, compiler-distribution)
    ├── lock.zig         ← botopink.lock read/write (v0.beta.20 install-from-deps — object-form libs)
    ├── dep/spec.zig     ← DepSpec / DepEntry mirror for bpmp (parallel to compiler-cli config.zig)
    ├── dep/clone.zig    ← `git clone --depth 1 [--branch …]` + atomic rename into CAS
    ├── dep/resolver.zig ← plan one Action per DepEntry (clone / reuse_cas / path_symlink / skip_legacy)
    ├── storage.zig      ← $BPMP_HOME layout resolution + mkdir-p
    ├── sha256.zig       ← file/byte hashing + sidecar verify
    ├── registry.zig     ← github.com URL shapes + ListTags signature
    ├── download.zig     ← content-addressed cache + sha256 verify + retry/backoff
    ├── extract.zig      ← tar.gz (std.tar+std.compress.flate) / zip (std.zip)
    ├── release.zig      ← shared "fetch sidecar + tarball + extract" for self update / use
    ├── resolver.zig     ← constraint solver (first-fit on highest tag)
    ├── semver.zig       ← Version + Constraint (caret/tilde/exact/>=/feat/latest)
    └── commands/
        ├── common.zig          ← shared error / hint / printf helpers
        ├── init.zig            ← `bpmp init`
        ├── install.zig         ← `bpmp install [<name>[@<spec>]]`
        ├── uninstall.zig       ← `bpmp uninstall <name> [--purge]`
        ├── use.zig             ← `bpmp use botopink <spec>`
        ├── list.zig            ← `bpmp list [--installed]`
        ├── pack.zig            ← `bpmp pack`
        ├── sync.zig            ← `bpmp sync [--update]`
        ├── run.zig             ← `bpmp run [-- <args>]`
        ├── self_update.zig     ← `bpmp self update [--check] [--toolchain]`
        ├── self_uninstall.zig  ← `bpmp self uninstall [--yes]`
        ├── version.zig         ← `bpmp version`
        └── env.zig             ← `bpmp env [--shell …]`
```

## Commands

```bash
zig build               # produce ./zig-out/bin/bpmp
zig build run -- help   # via the workspace dispatcher (cwd = botopink-lang/)
zig build test-bpmp     # bpmp unit tests (manifest / lockfile / semver / sha256 / …)
```

The `test-bpmp` step is **not** wired into `zig build test` (same as
`test-libs`/`test-vscode`) until the network surface (registry, download)
has hermetic fixtures.

## Storage layout (`$BPMP_HOME`)

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp  (Windows: %USERPROFILE%\.bpmp)
├── bin/
│   └── bpmp                                 # shim → active version's bpmp
├── botopink/
│   └── versions/
│       ├── <ver>/{botopink,botopink-lsp,botopink-lib-test,bpmp}
│       ├── dev/dev.path                     # sentinel file → user-supplied tree
│       └── stable                           # POSIX symlink / Windows junction → <ver>
├── packages/
│   └── <name>/versions/<ver>/{botopink.json,src/…}
├── store/                                   # v0.beta.20 install-from-deps CAS
│   └── <name>/<full-rev-40>/{botopink.json,root.bp,src/…}
├── cache/
│   ├── tarballs/<sha256>.<ext>              # content-addressed
│   └── manifests/                           # GH API response cache
└── lock                                     # fs flock (one bpmp at a time)
```

`storage.resolvePaths(gpa, env_map)` is the only thing that picks the paths
apart — every command goes through it.

## Env contract (`bpmp run` exports)

```text
PATH                = $BPMP_HOME/bin:$PATH
BOTOPINK_LIB_ROOTS  = <pkg_1_dir>:<pkg_2_dir>:…
                      one entry per installed package (lockfile order),
                      POSIX ':' / Windows ';' separator
```

The compiler / LSP / lib-test runner all honour `BOTOPINK_LIB_ROOTS` per
[`botopink-json-deps`](../../docs/botopink-json.md). bpmp is the producer;
the three tools are the consumers.

bpmp itself reads:

| Variable        | Effect                                                      |
| --------------- | ----------------------------------------------------------- |
| `BPMP_HOME`     | Override the install root (default `$HOME/.bpmp`).          |
| `HOME` / `USERPROFILE` | Fallback for the default install root.              |
| `GITHUB_TOKEN`  | Sent as `Authorization: Bearer` on api.github.com calls (auth'd rate limit; CI workflows already set this). |
| `SHELL`         | `bpmp env` shell auto-detection (override via `--shell`).   |

## Lockfile schema (`botopink.lock.json`, schema 1)

```jsonc
{
  "schema": 1,
  "generated_at": "<ISO-8601>",
  "botopink": { "version", "commit", "tag", "sha256", "source" },
  "packages": {
    "<name>": { "version", "commit", "tag", "constraint", "sha256", "source", "requires"[] }
  }
}
```

- **`commit` is the immutable pin** — replay fetches via
  `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz`. NEVER
  `archive/refs/tags/<tag>.tar.gz` (feat tags move).
- `version` / `tag` are informational (printed by `bpmp list`).
- `constraint` records the manifest's `requires.<name>` literal at resolve
  time — surfaces in `bpmp list` so a user can see *why* a pin was chosen.
- `sha256` is recomputed on every fetch and on cache hit — mismatch is a
  hard error with both digests in the message.
- Schema mismatch ⇒ explicit "run `bpmp sync --update`" hint (no
  auto-migration; the user is always in control of what bpmp pinned).

## Design contract

- **Orchestrate, don't reimplement.** bpmp spawns the toolchain; it does not
  link the compiler.
- **Additive manifest changes only.** Unknown fields in `botopink.json` are
  preserved on write (the compiler's loader already ignores them — schema is
  permissive by construction).
- **Lockfile pins by commit SHA, never by tag.** Reasoning in
  [`tasks/v0.beta.18/plan.md`](../../tasks/v0.beta.18/plan.md) §D5b — feat
  tags are moving, master/main tags are immutable, but using one rule
  (commit-pin) for every package keeps replay deterministic.
- **First-fit on highest tag, no backtracking.** A two-package conflict
  surfaces with both edges named; the user pins manually in `requires`.
- **Self-contained.** No `compiler-core` import. Carries no third-party
  Zig deps either — the only externals are GitHub's REST API + git-archive
  endpoints.

## Online-vs-offline behaviour

`download.zig` wires `std.http.Client` with sha256-verified streaming +
exponential-backoff retry; `extract.zig` wires `std.tar` + `std.zip` (gzip
via `std.compress.flate.Decompress`). The `release.zig` helper drives the
"fetch sidecar + tarball + extract" flow for the binary-installing commands.

| Command        | Behaviour                                                             |
| -------------- | --------------------------------------------------------------------- |
| `init`         | offline                                                               |
| `install <name>` | offline when the dep is object-form (clones into `$BPMP_HOME/store/` if needed, writes `botopink.lock`); else legacy compiler-distribution: manifest mutation only; §H6 warns when active toolchain is outside `botopink` range |
| `install` (no args) | when `botopink.json` carries any object-form dep → object-form path (clone each missing dep into `$BPMP_HOME/store/`, symlink under `.botopinkbuild/deps/`, write `botopink.lock`); else legacy: replays `botopink.lock.json` from cache → falls through to `download.fetch` on miss |
| `install --frozen` | object-form path; errors with **DEP-004** if any dep is missing from `botopink.lock`. CI mode. |
| `install --update` | object-form path; re-resolves branches, rewrites `botopink.lock` |
| `install --dry-run` | object-form path; prints planned actions, no IO |
| `uninstall`    | offline                                                               |
| `use botopink dev --from <dir>` | offline (sentinel file)                              |
| `use botopink <ver>` / `use botopink latest` | **online** — `release.installOne` for each of the 4 binaries; writes `stable` sentinel |
| `list` / `version` / `env`      | offline                                              |
| `pack`         | offline (writes `dist/<name>-<ver>.tar.gz` + `.sha256` sidecar)       |
| `sync`         | **online** — `registry.liveTags` per dep; reports drift; `--update` lockfile rewrite TBD |
| `run`          | offline (env compute + active-compiler probe)                         |
| `self update`  | **online** — `registry.fetchLatestRelease`; downloads bpmp asset; POSIX atomic-rename; Windows shows manual swap line |
| `self uninstall` | offline                                                             |

Things deliberately deferred from §H:
- `bpmp self update --toolchain` only hints; the toolchain reinstall ride
  along is left to `bpmp use botopink latest`.
- `bpmp sync --update` doesn't yet rewrite `botopink.lock.json` (pin
  resolution prints; rewrite needs the lockfile writer extended to take
  per-pin sha256 from the fetched archive).
- `bpmp install <name>`'s online resolver (after manifest mutation) is
  unchanged — it still hints "re-run once live"; the live half is the
  next `bpmp install` invocation which now hits the streaming layer.

See [`docs.md`](docs.md) for the end-user tutorial,
[`examples.md`](examples.md) for worked scenarios.
