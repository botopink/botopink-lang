# botopink-lang · project AGENTS.md

Guidance for AI agents working on the botopink **language core** — the CLI,
the LSP, the compiler, the lib-test-runner, and the bundled `std`/`server`/
`client` libs. The frameworks (erika/jhonstart/onze/rakun) and the VS Code
extension live as **siblings** under [`../`](../) — see [`../AGENTS.md`](../AGENTS.md)
for the workspace overview.

> Convention: source, comments, commit messages and docs are all in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree. Detailed architectural explanations live in sibling
> `docs.md` files; concrete `.bp` / CLI usage in sibling `examples.md` files.

## Project tree

```text
botopink-lang/                 ← language core (this project)
├── AGENTS.md                  ← you are here
├── README.md                  ← public-facing intro
├── CHANGELOG.md               ← release notes (current: v0.0.13-beta)
├── docs.md                    ← language reference (.bp syntax + semantics)
├── build.zig                  ← workspace build graph (CLI + LSP + lib-test-runner)
├── test_format.zig            ← ad-hoc formatter smoke
├── test_pub.zig               ← ad-hoc pub-decl smoke
├── modules/                   ← all Zig packages — see modules/AGENTS.md
│   ├── compiler-cli/          ← `botopink` CLI
│   ├── compiler-core/         ← lexer, parser, AST, infer, comptime, codegen
│   ├── language-server/       ← `botopink-lsp` LSP server
│   └── lib-test-runner/       ← `botopink-lib-test` (test-libs gate)
├── libs/                      ← bundled .bp libraries — see libs/AGENTS.md
│   ├── std/                   ← standard library (prelude loaded at infer time)
│   ├── server/                ← server-side interfaces (scaffold)
│   └── client/                ← client-side interfaces (scaffold)
└── examples/                  ← non-framework .bp example programs
```

Two workspace-globals live **above** the `repository/` root (i.e. outside
this project): `tasks/` (versioned spec sets — the roadmap) and `scripts/`
(workspace maintenance scripts: `install-tooling.sh`, `doc-health.sh`,
`status.sh`). The frameworks (`erika`, `jhonstart`, `onze`, `rakun`) and the
`vscode-extension` are siblings of this project under `repository/`.

Golden snapshots live inside the owning package (`modules/compiler-core/snapshots/`,
`modules/language-server/snapshots/`) — `zig build test` runs with the package as cwd.

## Workspace commands

```bash
zig build             # compile CLI + language-server + lib-test-runner + bpmp
zig build test        # run compiler-core + language-server tests
zig build run         # run the CLI entry point
zig build test-libs   # run every libs/ project's tests per backend
zig build test-vscode # run the VS Code extension's pure-fn unit suite
zig build test-bpmp   # run bpmp's unit tests
zig build test-backends # backend-execution parity (needs node/erlc/erl/wasmtime)
zig build clean-tmp   # reap per-test scratch dirs under modules/compiler-core/.botopinkbuild/tmp/ older than 1 day (auto-runs at start of `zig build test`)
```

Per-test scratch dirs live under `modules/compiler-core/.botopinkbuild/tmp/<hex>/`
(single root for every `executeJavaScript` / `executeErlang` / `executeBeamAsm`
/ `executeWat` invocation). The umbrella `.botopinkbuild/` `.gitignore` rule
swallows them; `clean-tmp` reaps stale entries before each `zig build test`
cycle so crashed-test leaks never accumulate beyond a day. See
[`modules/compiler-core/src/codegen/AGENTS.md`](modules/compiler-core/src/codegen/AGENTS.md)
(`runtime.zig` row) for the layout contract.

`test-libs` is the lib ecosystem's CI gate (`botopink-lib-test`): it runs
`botopink test --target <t>` in each `libs/<lib>` and exits non-zero iff any
cell fails. **Deliberately not part of `zig build test`** — needs host
runtimes on `PATH`:

| Backend    | Tool                              | Install hint                                  |
| ---------- | --------------------------------- | --------------------------------------------- |
| `commonJS` | `node` ≥ 20                       | https://nodejs.org/en/download                |
| `erlang`   | `escript` (OTP)                   | `apt-get install erlang` · `brew install erlang` |
| `beam`     | `escript` + `erlc` (OTP)          | same as erlang                                |
| `wasm`     | `wasmtime`                        | `curl https://wasmtime.dev/install.sh \| bash` |

The shared `scripts/test-libs.sh` wrapper pre-flights these probes (K1 of
v0.beta.19 §K) and prints a clean warning before the runner fires — a
missing backend is advisory, not a hard gate (the runner's per-target
skip-or-fail is the authority). `scripts/install-tooling.sh` runs the same
probes after installing the LSP / extension. Forward args via `--`, e.g.
`zig build test-libs -- --target erlang --lib rakun`. See
[`modules/lib-test-runner/AGENTS.md`](modules/lib-test-runner/AGENTS.md).

`test-vscode` invokes `scripts/test-vscode.sh`, which lazy-runs `npm ci` on
first use (gated on a marker under `repository/vscode-extension/node_modules/`)
and then `npm test --silent`. K2 of v0.beta.19 §K — a fresh clone runs
`zig build test-vscode` without a prior manual `npm install`.

Per-package commands live in each package's `build.zig` — see
[`modules/AGENTS.md`](modules/AGENTS.md).

## AGENTS index

Each directory ships its own `AGENTS.md` that **owns** its tree, file list and
conventions — read the closest one, then walk up. This root file does **not**
mirror those trees (that would drift); the two tables below are the index into the
deeper design/example docs. Entry points: [`modules/AGENTS.md`](modules/AGENTS.md),
[`libs/AGENTS.md`](libs/AGENTS.md), and — for the spec/roadmap layer —
[`tasks/AGENTS.md`](../../tasks/AGENTS.md). Snapshot counts and similar volatile figures
live in the owning leaf, never here.

## Where deep content lives

| Topic | Doc |
|---|---|
| Full compiler pipeline + AST model + public API | [`modules/compiler-core/docs.md`](modules/compiler-core/docs.md) |
| Façade pattern + allocator rule | [`modules/compiler-core/src/docs.md`](modules/compiler-core/src/docs.md) |
| Backend design (emitters are blind) | [`modules/compiler-core/src/codegen/docs.md`](modules/compiler-core/src/codegen/docs.md) |
| HM inference + Aggregator transform | [`modules/compiler-core/src/comptime/docs.md`](modules/compiler-core/src/comptime/docs.md) |
| CLI lifecycle | [`modules/compiler-cli/docs.md`](modules/compiler-cli/docs.md) |
| LSP layered design | [`modules/language-server/docs.md`](modules/language-server/docs.md) |
| Stdlib loading + interface conventions | [`libs/std/docs.md`](libs/std/docs.md) |
| `.bp` libraries group (std/server/client) | [`libs/AGENTS.md`](libs/AGENTS.md) |
| VS Code extension design + LSP wiring | [`../vscode-extension/docs.md`](../vscode-extension/docs.md) (sibling project) |
| `.bp` language reference (user-facing) | [`docs.md`](docs.md) |

## Release pipeline

CI is split between push/PR and tag push:

| Workflow                     | Trigger          | What                                                       |
| ---------------------------- | ---------------- | ---------------------------------------------------------- |
| `.github/workflows/test.yml` | push / PR        | `zig build test` on ubuntu-22.04 + macos-14 + windows-2022 (hard gate); `zig build test-libs -- --target commonJS` opt-in (windows allowed to fail until escript/newline shim spec lands). |
| `.github/workflows/release.yml` | tag push `v*` | 5-target × 4-binary matrix (`linux-{x86_64,aarch64}`, `macos-{x86_64,aarch64}`, `windows-x86_64`) → `scripts/release-pack.sh` writes `dist/<binary>-<tag>-<target>.<ext>` + `.sha256` → `softprops/action-gh-release@v2` uploads to a single Release. Prerelease iff the tag contains `-`. |

Asset naming convention (the only contract bpmp and the install script know):

```text
<binary>-<version>-<target>.<ext>          # tar.gz on POSIX, zip on Windows
<binary>-<version>-<target>.<ext>.sha256   # single 64-hex-char line
```

`<binary>` is one of `botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`
(the last lands in the same v0.beta.18 set; `release-pack.sh` silently skips
missing binaries so the matrix is stable across the lands). Targets, Zig
target strings, and the runner pin matrix are kept in lockstep between
`release.yml`, `release-pack.sh`, [`docs/botopink-json.md`](docs/botopink-json.md),
and `tasks/v0.beta.18/plan.md` §D3.

## Manifest schema

Every project or library carries a `botopink.json` at its root. The
authoritative schema (compiler-facing fields + bpmp-facing additions +
`BOTOPINK_LIB_ROOTS` env contract) lives in
[`docs/botopink-json.md`](docs/botopink-json.md). The schema is **purely
additive** — unknown fields are ignored, so adding a manifest field never
breaks existing libs.

**v0.beta.20 `install-from-deps`**: `dependencies` accepts two shapes —
the legacy array of bare names (`["foo","bar"]`, resolver-only) and the
new object form (`{ "foo": { "git": "...", "branch": "..." } }`, with
optional `rev` / `tag` / `path`). The object form is what `bpmp install`
consumes: each entry is cloned into `$BPMP_HOME/store/<name>/<rev>/`
(global CAS shared across projects on the host) and symlinked under
`<project>/.botopinkbuild/deps/<name>`. A sibling `botopink.lock` file
pins each dep to its resolved 40-char commit SHA for reproducible
replays. `bpmp install --frozen` is the CI gate.

## Where concrete examples live

| Topic | Doc |
|---|---|
| `botopink` CLI command usage | [`modules/compiler-cli/src/cli/examples.md`](modules/compiler-cli/src/cli/examples.md) |
| `.bp` token / numeric literal syntax | [`modules/compiler-core/src/lexer/examples.md`](modules/compiler-core/src/lexer/examples.md) |
| `.bp` declarations / expressions / statements | [`modules/compiler-core/src/parser/examples.md`](modules/compiler-core/src/parser/examples.md) |
| `.bp` source → JS / Erlang side-by-side | [`modules/compiler-core/src/codegen/examples.md`](modules/compiler-core/src/codegen/examples.md) |
| `comptime` usage in `.bp` | [`modules/compiler-core/src/comptime/examples.md`](modules/compiler-core/src/comptime/examples.md) |
| `botopink format` before/after | [`modules/compiler-core/src/format/examples.md`](modules/compiler-core/src/format/examples.md) |
| Using the stdlib (Array, String, builtins) | [`libs/std/src/examples.md`](libs/std/src/examples.md) |
| Minimal runnable `.bp` program | [`examples/hello.bp`](examples/hello.bp) |

## Conventions

- **AGENTS.md must always be kept up to date.** Whenever code, layout, or
  pipeline behaviour changes, update the affected `AGENTS.md` / `docs.md`
  in the same change. Each directory's `AGENTS.md` is the contract for
  that directory — stale docs are worse than missing docs.
- **`README.md` and `docs.md` (language reference) must also stay in sync.**
  When a language feature, CLI flag, syntax form, or compiler-visible
  behaviour changes, update both files alongside the code.
- **English only** — everything: source, comments, commits, and all docs,
  including planning/status files (`tasks/**/plan.md`, `status.md`, specs) and
  filenames.
- **Neutrality.** Knowledge (specs, templates, scripts) lives in neutral,
  version-controlled folders so any agent can use it; `AGENTS.md` is the open
  portability anchor. Tool-specific dirs (`.claude/`, `.cursor/`, …) may hold
  *triggers* that point to this content, never a source of truth.
- **One fact, one source.** Each fact lives in a single file; the others link or
  derive. The spec/roadmap layer's contract is [`tasks/AGENTS.md`](../../tasks/AGENTS.md).
- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an
  allocator — it is always passed as `alloc: std.mem.Allocator` to the
  method that needs it.
- Type annotations always use `TypeRef` (`named`, `array`, `tuple_`,
  `optional`, `function`, `generic`). Generic types use `is_builtin`
  flag to distinguish `@Result<D, E>` (builtin) from `MyType<T>` (user).
- Record/struct/enum/interface shorthand decls map to the same AST nodes
  as long-form declarations.
- Formatter must be round-trip stable: `format(parse(src))` must re-parse
  to an equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across
  cycles.

## Parallel tasks (git worktrees)

> The spec/roadmap model (sets, specs, the 5-phase workflow, slug rule, trust
> order) lives in [`tasks/AGENTS.md`](../../tasks/AGENTS.md). This section owns only the
> **exact git mechanics** that contract points back to.

Independent features are developed in parallel, one **git worktree per task**
under `.tasks/<name>/`, each on its own `task/<name>` branch. `feat` is the
integration branch (it receives the merges); `main` is **not** — it diverges
and lacks the task base. Always branch off `feat`, and run all remote git
operations over **SSH** (`git@github.com:botopink/botopink-lang.git`).

### Create a task

```bash
# from the main worktree (on feat), one per independent feature:
git worktree add .tasks/<name> -b task/<name> feat
```

Pick names that touch **disjoint files** where possible so tasks run without
blocking each other; when two tasks share a backend file (e.g. `beam_asm.zig`
or `wat.zig`), note the collision in both TODO.md files so integration expects
the conflict.

### Feed a task — `TODO.md` is the per-task execution checklist

Each worktree carries its own `.tasks/<name>/TODO.md` (the live execution state,
seeded from the spec's steps). Its shape and the spec→worktree→completion flow are
defined in [`tasks/AGENTS.md`](../../tasks/AGENTS.md).

Tool paths (Read/Edit/Write) must target the worktree
(`.../botopink-lang/.tasks/<name>/...`), never the main repo — it is easy to
edit the wrong tree. Do not `cd` into the main repo in Bash; the hook resets
cwd to the worktree.

### On completion — commit, update remote feature, delete the task

1. **Commit** inside the worktree (no `cd`): `git add -A && git commit -m "…"`.
   The pre-commit gate is tracked at `scripts/git-hooks/pre-commit` and
   wired up via `scripts/install-hooks.sh` (see [Local gate](#local-gate)
   below). It runs `zig fmt` + `zig build` + `zig build test` + a
   `botopink test` loop over every `libs/<name>/` package — the commit
   only lands if it compiles and tests pass. Do not use `--no-verify`.
2. **Update the remote feature** (integrate into `feat`, over SSH). The main
   `feat` worktree is often dirty with other WIP, so integrate via a throwaway
   worktree based on the remote:
   ```bash
   git fetch origin feat
   git worktree add .tasks/_integrate-<name> -b integrate/<name> origin/feat
   #   in it:  git merge --no-ff task/<name>  →  resolve  →  zig build test
   git push origin integrate/<name>:feat      # fast-forward, never --force
   ```
   `feat` refactors the AST fast; an old task merge conflicts in
   `infer.zig` / `env.zig` / `error.zig` / `tests.zig`. Take `feat`'s version
   and re-apply the task edits on the new AST rather than stitching markers.
   Task `.snap.md` files were generated on the old base — delete the task's and
   regenerate by running `zig build test` under `feat` (missing snapshots are
   recreated).
3. **Delete the task** once integrated:
   ```bash
   git worktree remove .tasks/<name> && git worktree remove .tasks/_integrate-<name>
   git branch -d task/<name> integrate/<name>
   git worktree prune
   ```

### Open parallel tasks

The live set of in-flight tasks lives in the active spec set's `status.md`
(see [`tasks/AGENTS.md`](../../tasks/AGENTS.md)) — not duplicated here.

## Recent commit context

| Commit | Summary |
|---|---|
| `611275f` | feat: lower try/catch to `Ok`/`Error` pattern matching across all backends (+ `tryOnNonResult` inference error) |
| `a42d948` | feat: add `Expr.useHook` AST variant for use-hooks in function bodies |
| `1888bfb` | feat: reject old `from "mod"` import syntax with migration hint |
| `65f990d` | feat: use syntax migration `from "mod"` → `= @root()` / `= @module()` |
| `8a79f94` | feat: `@Result<D, E>` generic syntax with `is_builtin` flag, snapshot refresh |
| `7991edc` | feat: wasm/beam comptime runtimes, `@print` test coverage, TODO roadmap |
| `4cf9e60` | test: refresh WAT snapshots — memory, data section, WASI print |
| `76f247a` | test: refresh BEAM + Erlang snapshots with run log output |
| `1705da2` | feat(wasm): linear memory, WASI `@print`, case, loops |
| `d090e36` | feat(beam): test_heap guards, real loops, dead code fix |
| `f9a1a13` | refactor: rename snapshot dirs `beam_asm` → `beam`, `wat` → `wasm` |

Current release: see [`CHANGELOG.md`](CHANGELOG.md) (v0.0.13-beta, May 2026).

When editing files: consult the closest `AGENTS.md` first, then parent
docs up to this root file. For design rationale read the sibling
`docs.md`; for concrete syntax / CLI usage read the sibling
`examples.md`.

## Local gate

`scripts/git-hooks/pre-commit` is the tracked source of truth for the
local pre-commit gate. Install it from the
[botopink/projects][meta] meta workspace by running
`scripts/install-hooks.sh` — the script walks `.gitmodules` and
symlinks the meta's hook plus a per-submodule shim into every git dir.
The same shim also works when this lib is cloned standalone: it falls
back to the self-contained `scripts/git-hooks/lib/runner-standalone.sh`,
which mirrors the meta's `lib/runners/botopink-lang.sh` runner inline.

What the gate runs (inside `repository/botopink-lang/`):

1. `zig fmt --check` on every staged `.zig` file.
2. `zig build` then `zig build test`.
3. `botopink test` in every `libs/<name>/` package with `.bp` sources.

The compiler binary is `zig-out/bin/botopink` (produced by step 2);
the loop short-circuits with a clear error if it's missing. `zig
build test-libs` (the cross-backend lib-test matrix) is **not** in
the default gate because it needs node/escript/wasmtime — call
[`scripts/test-libs.sh`][test-libs] (ships in-tree under bot-lang) when
those runtimes are present.

[meta]: https://github.com/botopink/projects
[test-libs]: https://github.com/botopink/botopink-lang/blob/feat/scripts/test-libs.sh
