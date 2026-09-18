# compiler-cli/src/cli

> Path: `modules/compiler-cli/src/cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../../AGENTS.md`](../../../../AGENTS.md)

Per-subcommand implementations and shared helpers for the `botopink` CLI.

## Tree

```text
cli/
├── AGENTS.md          ← you are here
├── build.zig          ← `botopink build`    compile project, write outputs
├── check.zig          ← `botopink check`    type-check, no code emission
├── run.zig            ← `botopink run`      build + execute entry point
├── test_cmd.zig       ← `botopink test`     compile in test mode + run test blocks
├── format_cmd.zig     ← `botopink format`   format / check .bp files
├── new.zig            ← `botopink new`      scaffold a new project
├── clean.zig          ← `botopink clean`    delete out/ + .botopinkbuild/
├── migrate.zig        ← `botopink migrate`  generate the mod tree from src/ layout
├── config.zig         ← `botopink.json` loader + target + `entry` + `dependencies`
├── sources.zig        ← project-source loading: drives the module tree + fallback
├── resolver.zig       ← explicit module-tree resolver (`mod`/`pub mod` → files)
├── scanner.zig        ← blind `src/` walk (deprecated fallback + `test/` suite dir)
├── libs.zig           ← generic external-lib loader (root list → `<name>/` modules)
├── diagnostics.zig    ← shared compile diagnostics: located lex/parse/type rendering, named-set guard
└── reporter.zig       ← stdout/stderr helpers (status, errors, hints, warnings)
```

## Subcommands

| File | Command | Notes |
|---|---|---|
| `build.zig` | `botopink build [--target <t>] [--out <dir>] [--typescript]` | Driver — calls into compiler-core codegen. Exits 1 naming every module that produced no artifact (diagnostic rendered), writes what compiled, deletes the stale artifact of what did not. Also owns the shared `reportUnsupportedTarget` / `reportDependencyError` / `artifactExt` helpers. |
| `check.zig` | `botopink check [<path>]` | Same pipeline as `build`, stops after type inference. Loads the set `test` compiles — `src/` **and** `test/` — plus declared `dependencies`; `<path>` changes into that project first. |
| `run.zig` | `botopink run [--target <t>] [--module <name>] [--out <dir>] [-- <args>]` | Builds into `--out`, then spawns the runner for the target on `<out>/<module>.<ext>` (`node` / `escript` / `wasmtime`). `beam` only writes the `.S` artifact and prints the `erlc +from_asm` hint. |
| `test_cmd.zig` | `botopink test [--target <t>] [--filter <substr>] [--json]` | Compiles with `test_mode = true` (test blocks emit as a registry + runner; `main/0` not auto-invoked), writes to `.botopinkbuild/test-out/`, runs each test-containing module via `node` (commonJS) or `escript` (erlang); other targets are rejected. A module that fails to compile is rendered and named and fails the run (exit 1), but does not stop the modules that compiled from running their tests; `test-out/` is emptied first so no previous artifact survives. `--json` re-emits the test envelope as JSONL (`emitJsonl` + `parseFailLine` + `parseDurationMs`; schema in [`../../AGENTS.md`](../../AGENTS.md)). Loads declared `dependencies` so a consumer's tests can `import … from "<lib>"`; a dependency's own `test {}` blocks are NOT run. Bare imports (`import {x};`) resolve to a root `module.js` aggregator merging every src/dep module's exports; **`test/` suite modules are excluded** from it — they export nothing others consume, and cross-loading one (which may run module-load side effects like decorator `@emit`s) from another test's run would hit a half-built aggregator and crash. For nested dep module names (`<lib>/<module>`), a per-directory `module.js` shim re-exports the root aggregator so their bare-import `require("./module")` resolves. `check`/`test` skip declaration-only (`.d.bp`) dep modules. |
| `format_cmd.zig` | `botopink format [--check] [files...]` (alias `fmt`) | Round-trip stable formatting; defaults to every file in `src/`. A file that does not lex or parse is rendered with its location and counted as an error in both modes (exit 1). |
| `new.zig` | `botopink new <name> [--target <t>]` | Drops a project template. The template **prints** (`@print(greet("world"))`): a block's value is its `break` (semantics decision 2), so a body whose only statement is a string literal evaluates to nothing and `botopink run` shows an empty screen. `tests/cli_contract.sh` pins both the `@print` and the run output. |
| `clean.zig` | `botopink clean` | Removes `out/` and `.botopinkbuild/`; prints `Removed` only on success and exits 1 when a delete fails. |
| `migrate.zig` | `botopink migrate [--dry-run]` | Derives the explicit module tree from the current `src/` layout — prepends `pub mod X;` to each directory's index (`root.bp`/`main.bp` at the root, `mod.bp` per folder), creating index files as needed. Idempotent; defaults to `pub mod` to preserve the reachability the implicit scan gave. |

## Shared helpers

| File | Role |
|---|---|
| `config.zig` | Parses `botopink.json` (`name`, `version`, `target`, `entry` module-tree root, `dependencies`). `dependencies` accepts both the array form `["foo","bar"]` (bare names, resolver-only) and the object form `{ "foo": { "git": "...", "branch": "..." } }` (optional `rev` / `tag` / `path`). Both normalise into `[]DepEntry` (`spec == null` for bare names, `spec != null` for object form; `DepSpec` is mirrored by `bpmp/src/dep/spec.zig`). Diagnostics: **DEP-001** (invalid shape), **DEP-002** (object spec without `git`/`path`), **DEP-003** (more than one of `branch`/`rev`/`tag` — `rev > tag > branch` wins, warning only). |
| `sources.zig` | Loads a package's project modules: resolves the explicit module tree (`resolver.zig`), warns on orphaned `.bp`, and falls back to the deprecated blind scan when a package has no `main.bp`/`root.bp` root. Every command loads `src/` through here, so the resolver's checks (including the unresolved-import-source one) apply to `build`, `check` and `test` alike. It passes `proj.dependencyNames` as the resolver's `externals` and renders each `resolver.Diagnostic`, appending an `at: <file>:<line>:<col>` line when one is located. |
| `resolver.zig` | Builds the package's module set by following `mod`/`pub mod` from the root (`main.bp` binary / `root.bp` library, per `entry`). `mod Name;` resolves `Name.bp` or `Name/mod.bp` (exactly one); both/neither errors. Reports orphans, enforces path-visibility (an import may cross into a module only if every `mod` on its path is `pub mod` — a private `mod` is reachable only within its declaring module's subtree), checks that `import … from "a.b"` naming a package module actually exports the symbol (dotted = `mod` chain) — and, since the `externals` argument (`sources.zig` passes the project's `dependencies`), that the `from` names **something**: a package module, a declared dependency (`<dep>` or `<dep>.<module>`) or `std`, else `UnresolvedImportSource`. Both diagnostics carry `file:line:col`, read off the `from "…"` string token (`fromLocations` — `ast.ImportDecl` has no `Loc`). Finally it topologically orders modules so an imported module compiles before its importer. |
| `scanner.zig` | Blind `src/` walk (every `.bp` becomes a module), sorted by path. Deprecated fallback used only when no module-tree root exists; still drives the flat `test/` suite dir. |
| `libs.zig` | Resolves `dependencies` (`[]DepEntry`) to `<name>/` modules on disk (lib-agnostic — the core sees ordinary `Module[]` prefixed `<name>/`). `loadDependencies` searches `resolveLibRoots` (`BOTOPINK_LIB_ROOTS` entries, then the walk-up roots `D/repository/botopink-lang/libs`, `D/repository`, `D/libs`), then `resolveFallbackRoots` (`<project>/.botopinkbuild/deps/`, the symlink store written by `bpmp install`); none found → `LibsRootNotFound` (the commands add a `bpmp install` hint); a `files` entry that cannot be read → `LibFileNotFound`, after `renderMissingFile` prints the path and the manifest entry's location. `resolveBpmpStoreRoot` computes `$BPMP_HOME/store/` (else `$XDG_CACHE_HOME/bpmp/store/`, else `$HOME/.cache/bpmp/store/`) but is not yet consulted by the loader. `shipMjsSidecars` copies a lib's `.mjs` sidecars next to the emitted JS; `shipErlSidecars` is its erlang counterpart — it reads the `atom:atom(` qualifiers out of the emitted erlang (`QualifierIterator`) and copies the host `<atom>.erl` a lib keeps in `src/sidecars/` or `src/` into the output, so `#[@External.Erlang("host", "fn")]` resolves. Called by `test_cmd.zig`; the `build.zig` call site is still open (that output has no sibling loader). |
| `diagnostics.zig` | Shared by `build`/`check`/`test`: `renderOutcome` renders the diagnostic a comptime outcome carries — `printSyntaxError` for a lex/parse error (`ComptimeOutput.Outcome.parseError`'s `SyntaxError`), the type or validation error otherwise — with file, line and excerpt; `failedOutputs` renders the diagnostic every failed `codegen.generateWith` entry carries (`renderResult`) and names the failed non-declaration modules; `reportFailedModules` / `reportOrphans` print the summary lines. `printLexError` / `printParseError` are reused by `format`. |
| `reporter.zig` | Single source of truth for CLI text — `reporter.errMsg`, `warnMsg`, `warnDetail`, `hintMsg`, `stdout`, plus status lines (`compiling`, `compiled`, `checking`, `checked`, `formatChanged`, …). |

## Conventions

- Project `src/` is loaded through `sources.zig` (explicit module tree); the flat
  `test/` suite dir keeps the deterministic `scanner.zig` walk (sort by path).
- Errors, warnings, and hints go through `reporter.zig` so output style stays
  consistent (`error: …` / `warning: …` / `hint: …`).
