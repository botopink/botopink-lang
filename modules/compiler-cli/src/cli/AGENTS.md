# compiler-cli/src/cli

> Path: `modules/compiler-cli/src/cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../../AGENTS.md`](../../../../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`./examples.md`](examples.md)

Per-subcommand implementations and shared helpers for the `botopink` CLI.

## Tree

```text
cli/
├── AGENTS.md          ← you are here
├── docs.md            ← subcommand pipeline + shared helpers reference
├── examples.md        ← `botopink` command recipes
├── build.zig          ← `botopink build`    compile project, write outputs
├── check.zig          ← `botopink check`    type-check, no code emission
├── run.zig            ← `botopink run`      build + execute entry point
├── test_cmd.zig       ← `botopink test`     compile in test mode + run test blocks
├── format_cmd.zig     ← `botopink format`   format / check .bp files
├── new.zig            ← `botopink new`      scaffold a new project
├── clean.zig          ← `botopink clean`    delete out/ + .botopinkbuild/
├── migrate.zig        ← `botopink migrate`  generate the mod tree from src/ layout
├── config.zig         ← `botopink.json` loader + target options + `entry` + `dependencies`
├── sources.zig        ← project-source loading: drives the module tree + fallback
├── resolver.zig       ← explicit module-tree resolver (`mod`/`pub mod` → files)
├── scanner.zig        ← legacy blind `src/` walk (deprecated fallback)
├── libs.zig           ← generic external-lib loader (`libs/<name>/` from disk)
└── reporter.zig       ← stdout/stderr helpers (status, errors, hints, warnings)
```

## Subcommands

| File | Command | Notes |
|---|---|---|
| `build.zig` | `botopink build` | Driver — calls into compiler-core codegen. |
| `check.zig` | `botopink check` | Same pipeline as `build`, stops after type infer. Loads declared `dependencies` (like `build`) so `import … from "<lib>"` type-checks. |
| `run.zig` | `botopink run` | After `build`, exec target via `comptime/runtime` helpers. |
| `test_cmd.zig` | `botopink test [--filter <substr>] [--json]` | Compiles with `test_mode = true` (test blocks emit as a registry + runner; `main/0` not auto-invoked), writes to `.botopinkbuild/test-out/`, runs each test-containing module via node (commonJS) or escript (erlang). WASM pending. `--json` captures each child's stdout and re-emits the §T envelope as JSONL (`emitJsonl` + `parseFailLine` in this file; schema in `../../AGENTS.md`). Loads declared `dependencies` so a consumer's tests can `import … from "<lib>"`; a dependency's own `test {}` blocks are NOT run (only the project's). Bare imports (`import {x};`) resolve to a root `module.js` aggregator merging every src/dep module's exports; **`test/` suite modules are excluded** from it — they export nothing others consume, and cross-loading one (which may run module-load side effects like decorator `@emit`s) from another test's run would hit a half-built aggregator and crash. For nested dep module names (`jhonstart/hooks`), a per-directory `module.js` shim re-exports the root aggregator so their bare-import `require("./module")` resolves. `check`/`test` skip declaration-only (`.d.bp`) deps — the regular pipeline parses declaration syntax for std only; external `.d.bp` (host-bound/gated surface) is not consumed there. |
| `format_cmd.zig` | `botopink format [--check]` | Round-trip stable formatting. |
| `new.zig` | `botopink new <name>` | Drops a project template. |
| `clean.zig` | `botopink clean` | Removes generated artifacts. |
| `migrate.zig` | `botopink migrate [--dry-run]` | Derives the explicit module tree from the current `src/` layout — prepends `pub mod X;` to each directory's index (`root.bp`/`main.bp` at the root, `mod.bp` per folder), creating index files as needed. Idempotent; defaults to `pub mod` to preserve the implicit-scan reachability of pre-migration packages. |

## Shared helpers

| File | Role |
|---|---|
| `config.zig` | Parses `botopink.json` (target, `entry` module-tree root, `dependencies`, etc). **v0.beta.20 `install-from-deps`**: `dependencies` accepts both the legacy `["foo","bar"]` array form (bare names → resolver-only) AND the new object form `{ "foo": { "git": "...", "branch": "..." } }` (with optional `rev` / `tag` / `path`). Both shapes normalise into `[]DepEntry` (`spec == null` legacy, `spec != null` object-form). Parser surfaces **DEP-001** (invalid shape), **DEP-002** (object spec without `git`/`path`), **DEP-003** (more than one of `branch`/`rev`/`tag` — `rev > tag > branch` wins, warning only). |
| `sources.zig` | Loads a package's project modules: resolves the explicit module tree (`resolver.zig`), warns on orphaned `.bp`, and falls back to the deprecated blind scan when a package has no `main.bp`/`root.bp` root. Every command loads `src/` through here. |
| `resolver.zig` | Builds the package's module set by following `mod`/`pub mod` from the root (`main.bp` binary / `root.bp` library, per `entry`). `mod Name;` resolves `Name.bp` or `Name/mod.bp` (exactly one); both/neither errors. Reports orphans, enforces path-visibility (an import may cross into a module only if every `mod` on its path is `pub mod` — a private `mod` is reachable only within its declaring module's subtree), checks that `import … from "a.b"` naming a package module actually exports the symbol (dotted = `mod` chain), and topologically orders modules so an imported module compiles before its importer. |
| `scanner.zig` | Legacy blind `src/` walk (every `.bp` becomes a module), returns modules sorted by path. Deprecated fallback used only when no module-tree root exists, and still drives the flat `test/` suite dir. |
| `libs.zig` | Resolves `dependencies` (now `[]DepEntry`) to `<name>/` modules on disk (lib-agnostic — the core never names a lib; sees them as ordinary `Module[]` prefixed `<name>/`). Resolution order per dep: project-local `libs/<name>/` → each entry of `BOTOPINK_LIB_ROOTS` → **v0.beta.20 fallback** `<project>/.botopinkbuild/deps/<name>/` (the per-project symlink store materialised by `bpmp install`). The `LibsRootNotFound` message gains a `bpmp install` hint when the project carries object-form deps. `resolveBpmpStoreRoot` exposes `$BPMP_HOME/store/` (or `$XDG_CACHE_HOME/bpmp/store/` / `$HOME/.cache/bpmp/store/`) for future direct-CAS lookup when `.botopinkbuild/deps/` has been wiped but the lockfile is still authoritative. |
| `reporter.zig` | Single source of truth for CLI text — use `reporter.errMsg`, `reporter.warnMsg`, `reporter.hintMsg`, etc. |

## Conventions

- Project `src/` is loaded through `sources.zig` (explicit module tree); the flat
  `test/` suite dir keeps the deterministic `scanner.zig` walk (sort by path).
- All errors, warnings, and hints must go through `reporter.zig` so output style
  stays consistent (`error: …` / `warning: …` / `hint: …`).
