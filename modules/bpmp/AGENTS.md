# bpmp · AGENTS.md

> Path: `modules/bpmp/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

`bpmp` — Boto Pink Package Manager + toolchain manager. A self-contained Zig
program. **No `compiler-core` import.** bpmp does not link the compiler; it
*spawns* it (same pattern as `lib-test-runner`) with `BOTOPINK_LIB_ROOTS`
pointing at its on-disk package store.

bpmp reads / writes three files in a project:

| File                  | Owned by | Read by                                  |
| --------------------- | -------- | ---------------------------------------- |
| `botopink.json`       | bpmp + compiler | compiler (`src`/`files`/`dependencies`); bpmp (`botopink`, `requires`, `dependencies`) |
| `botopink.lock.json`  | bpmp only (`lockfile.zig`) | compiler-distribution / version-constraint lockfile (pins by commit) |
| `botopink.lock`       | bpmp only (`lock.zig`) | object-form lib-dep lockfile (pins by resolved git SHA) |

Compiler-facing fields pass through verbatim — bpmp only writes the
bpmp-facing `botopink` (compiler version constraint) and `requires`
(per-dep constraint), and adds a `{ "<name>": { "git": "<url>" } }` entry to
`dependencies` when adding a dep. `dependencies` is the object form only
(decision 76): the shared `manifest` module (`modules/manifest`, std only) is
the parser of record — `dep/spec.zig` re-exports its `DepEntry`/`DepSpec`/`DepRef`
and returns its located refusals — and `manifest.zig`'s typed view lists the
keys of that object (the retired string array is `ManifestInvalid`).

`botopink.lock` tracks `dependencies`
(`{ "<name>": { "git": ..., "branch"|"rev"|"tag": ... } }` or `{ "path": ... }`;
a `{ "workspace": true }` entry is a sibling member the compiler reads from the
tree and is skipped) keyed by their resolved 40-char commit SHA. `bpmp install` materialises each git
dep into `<store>/<name>/<rev>/` and symlinks `<project>/.botopinkbuild/deps/<name>`
to it (path deps are symlinked directly); the compiler's lib loader picks up
`.botopinkbuild/deps/` as a fallback root.

## Tree

```text
modules/bpmp/
├── AGENTS.md            ← you are here
├── build.zig.zon        ← no build.zig: built/tested by the workspace build.zig
└── src/
    ├── main.zig         ← entry point + command table/dispatch (+ test aggregator)
    ├── cli.zig          ← Command/Context types + help renderer
    ├── version.zig      ← bpmp's own version string
    ├── manifest.zig     ← botopink.json read/write (preserves unknown fields)
    ├── lockfile.zig     ← botopink.lock.json read/write (schema-versioned)
    ├── lock.zig         ← botopink.lock read/write (object-form libs)
    ├── dep/spec.zig     ← DepSpec / DepEntry from the shared `manifest` module + `parseFromManifest` (located refusals)
    ├── dep/clone.zig    ← `git clone --quiet [--depth 1] [--branch …]` (+ checkout for `rev:`) + atomic rename into the store
    ├── dep/resolver.zig ← plan one Action per DepEntry (clone / reuse_cas / path_symlink / skip_workspace);
    │                      probes the store for pinned commits; each Action carries its `ref`
    ├── storage.zig      ← $BPMP_HOME layout resolution + mkdir-p
    ├── sha256.zig       ← file/byte hashing + sidecar verify
    ├── registry.zig     ← github.com URL shapes + tag/release lookups
    ├── download.zig     ← content-addressed cache + sha256 verify + retry/backoff
    ├── extract.zig      ← tar.gz (std.tar + std.compress.flate) / zip (std.zip)
    ├── release.zig      ← shared "fetch sidecar + tarball + extract" for self update / use
    ├── resolver.zig     ← constraint solver (highest matching tag, no backtracking)
    ├── semver.zig       ← Version + Constraint (caret/tilde/exact/>=/feat/latest)
    └── commands/
        ├── common.zig          ← shared error / hint / printf helpers
        ├── init.zig            ← `bpmp init`
        ├── install.zig         ← `bpmp install [<name>[@<spec>]] [--frozen|--update|--dry-run]`
        ├── uninstall.zig       ← `bpmp uninstall <name> [--purge]`
        ├── use.zig             ← `bpmp use botopink <ver>|latest|dev --from <dir>`
        ├── list.zig            ← `bpmp list [--installed]`
        ├── pack.zig            ← `bpmp pack`
        ├── sync.zig            ← `bpmp sync` (per-dep source from `git:`; no `--update`)
        ├── run.zig             ← `bpmp run [-- <args>]`
        ├── self_update.zig     ← `bpmp self update [--check] [--toolchain]`
        ├── self_uninstall.zig  ← `bpmp self uninstall [--yes]`
        ├── version.zig         ← `bpmp version`
        └── env.zig             ← `bpmp env [--shell …]`
```

## Commands

```bash
# from the workspace root (bpmp has no standalone build.zig)
zig build                  # produces ./zig-out/bin/bpmp (with the other executables)
./zig-out/bin/bpmp help
zig build test-bpmp        # bpmp unit tests (manifest / lockfile / semver / sha256 / …)
```

`test-bpmp` is **not** part of `zig build test` (the network surface — registry,
download — has no hermetic fixtures). Whether it joins the gate is a `build.zig`
decision owned by the cli-gate front (1.0.2-beta F2); until then run it by hand
whenever `modules/bpmp/**` changes. Tests that need a scratch directory take it from the `test_scratch` module
([`../test-scratch/AGENTS.md`](../test-scratch/AGENTS.md)) —
`test_scratch.path(testing.io, "bpmp-tests/<test>")`, which lands under
`.botopinkbuild/test-scratch/<per-process id>/bpmp-tests/<test>/` in the test
cwd (`modules/bpmp`, git-ignored). It used to be a fixed
`.botopinkbuild/bpmp-tests/<test>/`, which two processes sharing this checkout
emptied for each other. The `install.zig` clone tests build a local fixture repo with
`git` (hermetic: identity, signing and hooks overridden per call) and clone it
over `file://`; they skip when `git` is not installed.

## Storage layout (`$BPMP_HOME`)

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp  (Windows: %USERPROFILE%\.bpmp)
├── bin/
│   └── bpmp                                 # shim → active version's bpmp
├── botopink/
│   └── versions/
│       ├── <ver>/{botopink,botopink-lsp,botopink-lib-test,bpmp}
│       ├── dev/dev.path                     # sentinel file → user-supplied tree
│       └── stable                           # sentinel file containing the active <ver>
├── packages/
│   └── <name>/versions/<ver>/{botopink.json,src/…}
├── cache/
│   ├── tarballs/<sha256>.<ext>              # content-addressed
│   └── manifests/                           # GH API response cache
└── lock                                     # fs flock (one bpmp at a time)
```

`storage.resolvePaths(gpa, env_map)` resolves these paths — every command goes
through it.

The object-form dep **store** is resolved separately (`install.zig`
`resolveStoreRoot`): `$BPMP_HOME/store/`, else `$XDG_CACHE_HOME/bpmp/store/`,
else `$HOME/.cache/bpmp/store/`; layout `<store>/<name>/<full-rev-40>/`.

## Env contract (`BOTOPINK_LIB_ROOTS`)

```text
BOTOPINK_LIB_ROOTS  = <pkg_1_dir>:<pkg_2_dir>:…
                      one entry per botopink.lock.json package
                      ($BPMP_HOME/packages/<name>/versions/<ver>), lockfile order,
                      POSIX ':' / Windows ';' separator
```

The compiler, LSP and lib-test runner all honour `BOTOPINK_LIB_ROOTS` (see
[`compiler-cli`](../compiler-cli/AGENTS.md#env)). bpmp is the producer; the
three tools are the consumers.

bpmp itself reads:

| Variable        | Effect                                                      |
| --------------- | ----------------------------------------------------------- |
| `BPMP_HOME`     | Override the install root (default `$HOME/.bpmp`).          |
| `HOME` / `USERPROFILE` | Fallback for the default install root.              |
| `XDG_CACHE_HOME` | Store root fallback for object-form deps when `BPMP_HOME` is unset. |
| `GITHUB_TOKEN`  | Sent as `Authorization: Bearer` on api.github.com calls (auth'd rate limit). |
| `BPMP_DEFAULT_ORG` | `bpmp sync` only: GitHub owner for a bare-name dependency (`<org>/<name>`). Unset ⇒ such deps are reported as having no source. No org is built in. |
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
  `https://github.com/<owner>/<repo>/archive/<commit>.tar.gz`. Never
  `archive/refs/tags/<tag>.tar.gz` (feat tags move).
- `version` / `tag` are informational (printed by `bpmp list`).
- `constraint` records the manifest's `requires.<name>` literal at resolve
  time, so `bpmp list` can show *why* a pin was chosen.
- `sha256` is verified on fetch and on cache hit — mismatch is a hard error
  with both digests in the message.
- Schema mismatch ⇒ explicit hint to move the lockfile aside and re-add each
  package with `bpmp install <name>` (no auto-migration).

## Lockfile schema (`botopink.lock`, version 1)

```jsonc
{
  "generated_by": "bpmp <ver>",
  "lockfile_version": 1,
  "deps": {
    "<name>": { "git": "<url>", "rev": "<sha-40>", "path": "<abs>"|null, "fetched_at": "<ISO-8601 UTC>" }
  }
}
```

`git`/`rev` are empty for `path` deps.

## Design contract

- **Orchestrate, don't reimplement.** bpmp spawns the toolchain; it does not
  link the compiler.
- **Additive manifest changes only.** Unknown fields in `botopink.json` are
  preserved on write (the compiler's loader ignores them).
- **Lockfiles pin by commit SHA, never by tag** — feat tags move, so one
  commit-pin rule keeps replay deterministic for every package.
- **Highest matching tag, no backtracking.** A two-package conflict surfaces
  with both edges named; the user pins manually in `requires`.
- **Self-contained.** No `compiler-core` import and no third-party Zig deps —
  the only externals are GitHub's REST API + archive endpoints and `git`
  (object-form deps).

## Command behaviour

`download.zig` wires `std.http.Client` with sha256-verified streaming +
exponential-backoff retry; `extract.zig` wires `std.tar` + `std.zip` (gzip via
`std.compress.flate.Decompress`). `release.zig` drives the "fetch sidecar +
tarball + extract" flow for the binary-installing commands.

| Command        | Behaviour                                                             |
| -------------- | --------------------------------------------------------------------- |
| `init`         | offline                                                               |
| `install` / `install <name>` with object-form deps in `botopink.json` | plans each dep (`dep/resolver.zig`): reuse the store entry pinned by `botopink.lock` (or a spec `rev:`) **when `<store>/<name>/<rev>/` exists**, otherwise clone that exact rev; symlink a `path` dep (resolved against the project root); or `git clone` the entry's own `branch:`/`tag:` (default HEAD only when it names no ref). Symlinks under `.botopinkbuild/deps/` — never to a target that does not exist; writes `botopink.lock`. `<name>` restricts to one declared dep. |
| `install --frozen` | object-form path, never clones (CI mode); errors naming the dep with **DEP-004** when it has no `botopink.lock` entry (and no spec `rev:`), and **DEP-005** when its pinned commit is not in the store |
| `install --update` | object-form path; ignores the existing `botopink.lock` and re-resolves |
| `install --dry-run` | object-form path; prints planned actions, no IO |
| `install <name>[@<spec>]` (no deps declared yet) | offline manifest mutation only: writes `{ "<name>": { "git": "<url>" } }` + `requires`; `<name>` is `<owner>/<name>` (GitHub), a git URL, or a bare name under `BPMP_DEFAULT_ORG` — with no source to write it is refused (decision 76); prints a hint that pinning commit + sha256 is not wired yet |
| `install` (no args, no object-form deps) | reads `botopink.lock.json`; reports packages already present under `$BPMP_HOME/packages/`, and only hints for missing ones (no download yet) |
| both non-object-form `install` paths | warn when the active toolchain (`stable`) is outside the manifest's `botopink` range |
| `uninstall`    | offline (manifest + `botopink.lock.json`)                             |
| `use botopink dev --from <dir>` | offline (sentinel file)                              |
| `use botopink <ver>` / `use botopink latest` | **online** — `release.installOne` for each of the 4 binaries; writes the `stable` sentinel |
| `list` / `version` / `env`      | offline                                              |
| `pack`         | offline (writes `dist/<name>-<ver>.tar.gz` + `.sha256` sidecar)       |
| `sync`         | **online** — reads each dep's tags from its own `git:` source (GitHub only; `path:` and `{ "workspace": true }` deps and other hosts are skipped with a note); reports drift against `botopink.lock.json`, exit 1 on drift. Never rewrites the lockfile; `--update` is refused. |
| `run`          | offline — computes `BOTOPINK_LIB_ROOTS` and the active compiler path and prints the command it *would* exec (no spawn yet) |
| `self update`  | **online** — `registry.fetchLatestRelease`; downloads the bpmp asset; POSIX atomic rename; Windows prints the manual swap line. `--toolchain` only hints `bpmp use botopink latest`. |
| `self uninstall` | offline                                                             |
