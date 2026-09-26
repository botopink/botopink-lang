# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── botopink.json        ← module manifest (`version` drives the auto-tag)
├── tests/               ← end-to-end CLI scripts — `zig build test-cli` runs all four
│   ├── cli_contract.sh      ← the command contract (rows C1–C13, plus the
│   │                          build-does-not-execute and `new`-scaffold-prints
│   │                          rows) against the real binary
│   ├── mutual_recursion.sh  ← forward-ref + mutual recursion runs on every backend
│   ├── mutual_recursion/    ← fixture project for the script above
│   ├── backend_exec.sh      ← backend execution parity (numeric / records /
│   │                          examples/modules); `zig build test-backends`
│   ├── backend_exec/        ← numeric + records fixture projects
│   ├── test_tooling.sh      ← `botopink test` behaviours: empty test, --filter
│   │                          (multi / none), assert message, a failing `try`, the
│   │                          FAIL line's `src/main.bp:<line>` (commonJS + erlang),
│   │                          mixed pass/fail exit, the `.snap.new` candidate list;
│   │                          `botopink-lib-test` compiles a test-less library,
│   │                          and prints under `--jobs 4` what `--jobs 1` prints;
│   │                          a dependency's erlang host `.erl` is shipped and reached
│   └── test_tooling/        ← pass + fail fixture projects
└── src/
    ├── AGENTS.md
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
        └── AGENTS.md
```

## Commands

```bash
# from the workspace root (the package has no build.zig of its own)
zig build               # produce zig-out/bin/botopink
zig build run -- help
zig build run -- version
zig build test          # includes the CLI unit tests (main.zig parsers / config /
                        # libs / resolver / migrate / test_cmd /
                        # diagnostics / clean;
                        # root = src/main.zig, cwd = modules/compiler-cli) — main.zig's
                        # `test { _ = @import(...) }` block pulls every cli/ file in; a
                        # file not listed there has its tests silently skipped

# End-to-end scripts under tests/ spawn the CLI and runtimes, so they are NOT
# part of `zig build test`. From the workspace root:
zig build test-cli      # all four scripts, in order, against the installed CLI
zig build test-backends # backend_exec.sh alone

# Or directly (each builds the CLI unless BOTOPINK_SKIP_BUILD=1 is set;
# cli_contract.sh also takes BOTOPINK_BIN=<binary> to test another build):
bash modules/compiler-cli/tests/cli_contract.sh      # command contract C1–C13
bash modules/compiler-cli/tests/test_tooling.sh      # `botopink test` behaviours
bash modules/compiler-cli/tests/mutual_recursion.sh  # mutual recursion on every backend
bash modules/compiler-cli/tests/backend_exec.sh      # numeric/records/modules per backend
```

> **Every cell is a hard assert** — there are no pinned reds. A missing runtime
> skips its cells by name. **Cells not run**, each restored by the front that
> fixes it: `examples/modules` on erlang (**not** a backend defect — the emitted
> code is correct; `cli/run.zig` runs `escript out/main.erl`, which compiles only
> the file it is handed, so the sibling module is `undef` at run time. See "the
> erlang runner reaches one module" below; front `13-module-identity` owns the
> file) and the `numeric` fixture on BEAM (call-result arithmetic fails
> `beam_validator`; the beam front).
> The `std` suite on erlang is covered by `zig build test-libs`, not a script.

## External libs (generic loader)

`cli/libs.zig` is the driver-side half of the lib-agnostic package mechanism. A
project's `botopink.json` `dependencies` — the object form only (decision 76;
`docs/botopink-json.md`) — are resolved by the shared
`manifest.resolveDependency` (`modules/manifest`): `{ "path": … }` from the
project directory (must hold a package of that name; a sibling member of the
enclosing workspace is refused with `use { "workspace": true }`);
`{ "workspace": true }` to the sibling member of the enclosing workspace
(`config.load` finds it — `ProjectConfig.workspace`); `{ "git": … }` by name
against an ordered **root list** (`resolveLibRoots`): `BOTOPINK_LIB_ROOTS`
entries first, then, walking up from cwd, each ancestor `D` contributes — when
present — `D` itself when its `botopink.json` is a workspace (its members),
`D/repository/botopink-lang/libs` (bundled libs), `D/repository` (sibling
projects), and `D/libs` (flat tree), de-duplicated first-occurrence-wins; the walk
stops after the first `D` that holds `repository/` — the enclosing checkout
(`manifest.isCheckoutRoot`), so a meta worktree under `.tasks/<name>` never sees the
main checkout's libraries a second time (decision 143). After
those, `resolveFallbackRoots` adds `<project>/.botopinkbuild/deps/` (the symlink
store written by `bpmp install`). `manifest.scanRoots` turns the roots into
entries — a root's child holding a manifest, or every **member** of a workspace
found there, named by its manifest — and `<name>` resolves to the first entry so
named (a workspace by that name is refused with its member list; a name two
members declare is refused on both). Dependencies are transitive (decision 143):
each dependency's own entries resolve from its manifest and directory, every
package loads once, after the packages it depends on; one import name meaning two
directories in a build, or a cycle between packages, is refused, located. The loader reads the resolved manifest's
`{src, files}` and feeds the lib's modules into compilation prefixed by name
(`<name>/<module>`).
The compiler core never names a lib — it sees ordinary `Module[]` and resolves
`from "<name>"` through the shared import registry. `std` is embedded and not
loaded here. `shipMjsSidecars` resolves an owning lib's `.mjs` through the same
root list, and never writes outside the output directory: a `require` whose path
escapes it (a lib's `../../src/x.mjs` authored for its own build) ships the file to
`<out>/<lib>/<base>` (project-own: `<out>/<base>`) and rewrites that module's
`require` to reach it. The bundled packages (`std` and the libraries `build.zig`'s `bundled_packages` names — decisions 115–117) are the exception to "declared, then found on disk": `libs.loadDependencies` loads the ones a module imports from the copy embedded in the binary, and refuses one listed in `dependencies`.

`shipErlSidecars` is the erlang counterpart: a `#[@External.Erlang("host",
"fn")]` lowers to `host:fn(…)`, and `host` is a module the library authors in
erlang and keeps beside its `.bp` sources (`<lib>/src/sidecars/<host>.erl`, else
`<lib>/src/<host>.erl`; a project-own module probes `src/sidecars/` then `src/`).
It scans every emitted erlang module for `atom:atom(` qualifiers and copies the
ones it finds a source file for into the output — so a qualifier naming an OTP
module or another module of this build is a no-op, with no lib names in the
code. **Wired into `botopink test` only** (`test_cmd.zig`): the test runner's
`__bp_load_siblings/0` compiles and loads every `.erl` beside the script, so
copying is all it takes there (the copy lands before `precompileErlang`, so a
host module is compiled once per run like every other `.erl`). `botopink build`/`run` emit no such loader and do
not copy, so the `build.zig` call site is still open (front
`13-module-identity`'s file: `if (target == .erlang) { _ = libs.shipErlSidecars(gpa, io, outputs, out_dir, env_map) catch 0; }`
beside the existing `if (target == .commonJS)`). It only becomes *useful* once an
erlang `build`/`run` output can reach **any** sibling module, which is the next
section — a different defect with a different cause.

### The erlang runner reaches one module

`cli/run.zig` spawns `escript <out>/<module>.erl`. `escript` compiles **only the
file it is handed** and has no code-path flag (`escript -pa out out/main.erl` →
`escript: illegal operation on a directory: 'out'`), so every call into a sibling
module is `undef` at run time even though the emitted code is right. Measured on
four projects, each of which prints its expected output once the modules are on a
code path:

| project | escript today | emitted call |
|---|---|---|
| `tests/language/modules/two_modules` | `undefined function geometry:norm/1` | `geometry:norm/1` — qualified, correct |
| `tests/language/modules/mod_tree` | `undefined function shapes:describe/0` | `shapes:describe/0` |
| `tests/language/modules/std_import` | `undefined function dict:empty/0` | `dict:empty/0` |
| `examples/modules` | `undefined function geometry:area/2` | `geometry:area/2`, `shapes:describe/0`, `shapes:lucky/0` |

The shape that works is the one the beam arm of `tests/language/run.sh` already
uses: `erlc -o <out_dir>` over every emitted `.erl` **found recursively** — the
file layout nests (`out/shapes/circle.erl`, `out/std/dict.erl`) while the module
atom is flat, so `-o <out_dir>` is what puts each `.beam` where a single
`-pa <out_dir>` looks — then `erl -noshell -pa <out_dir> -eval "<module>:main([]), halt()."`.
`main([])` and not `main()`: `main/1` is always exported, while `main/0` is
emitted only when `main` is `pub` (`examples/modules` declares `fn main()` and
exports just `'_botopink_main'/0, main/1`). A crash's exit status moves from
escript's `127` to `erl`'s `1`.

`cli/run.zig` belongs to front `13-module-identity`, together with the `-pa` row
of its output-layout step — so this is recorded here, not fixed here.

**Unknown `botopink.json` fields are ignored; known ones are checked.** The
shared `manifest` model (`modules/manifest/src/root.zig`, schema in
`docs/botopink-json.md`) is the one parser: `config.zig` projects it into
`ProjectConfig` (`name`/`version`/`target`/`entry`/`dependencies`/`files`, the
enclosing `workspace`) and `libs.zig` reads a dependency's `src`/`files` from
it. The bpmp-facing `botopink` (compiler version constraint) and `requires`
(per-dep version constraint) pass through untouched. A refused manifest — not
JSON, the retired string-array `dependencies`, a dependency without a source, a
workspace where a package is needed — is a located diagnostic printed by
`config.load`/`libs.loadDependencies` before `ConfigInvalid`/`LibManifestInvalid`,
and the commands add nothing after it. `botopink test` inside a workspace member
that is a library and lists no `files` fails with `ships nothing: manifest has
no "files"` (decision 75).

## Env

| Variable              | Read by                                  | Effect                                                                 |
| --------------------- | ---------------------------------------- | ---------------------------------------------------------------------- |
| `BOTOPINK_LIB_ROOTS`  | `cli/libs.zig:resolveLibRoots`           | Prepends extra lib roots before the walk-up roots.                     |

**`BOTOPINK_LIB_ROOTS` contract:**

- Path separator: `:` on POSIX, `;` on Windows (matches `PATH`; via
  `std.fs.path.delimiter`).
- Entries are prepended to the walk-up result, then the combined list is
  de-duplicated first-occurrence-wins (an env entry always shadows a
  duplicate walk-up root).
- Non-existent entries are **silently dropped** — a typo must not break a
  build that does not need the missing root.
- Empty entries (`a::b`, trailing `:`) are dropped.
- Relative entries are resolved against the process cwd.
- Unset or empty value → walk-up roots only.

The same hook is mirrored in
[`language-server/src/project_graph.zig`](../language-server/AGENTS.md#env)
and
[`lib-test-runner/src/discovery.zig:resolveRoots`](../lib-test-runner/AGENTS.md#env)
so the CLI, the LSP, and the lib-test runner see the same root list.
bpmp sets it when spawning the compiler (`bpmp run`).

## Command contract

What each command promises. A row the code does not meet yet is marked
**open**, with the owner of the fix. Every row is exercised by
`tests/cli_contract.sh` (`zig build test-cli`) or by a `main.zig` unit test.

| Command | Reads | Writes | Spawns | Exit 0 | Exit 1 |
|---|---|---|---|---|---|
| `build [--target T] [--out D] [--typescript]` | `botopink.json`, the `src/` module tree, each declared dependency | `D/<stem><ext>` for every module that compiled (+ `.d.ts`, + `.mjs` sidecars on commonJS); the previous artifact of a module that did not compile is deleted. The **stem** is the module ATOM under `D/erl/` or `D/beam/` for the erlang and BEAM targets (`std/math` → `D/erl/std@math.erl`), because `erlc` refuses a `-module` atom that differs from its file's basename; commonJS, its `.d.ts` and wasm keep the mirrored `D/<module path>` tree, because a `require` target and a wasm import segment ARE the module path (`cli/build.zig` `artifactPath`/`targetSubdir`) | the program is never run — `codegen.generateWith(…, .{ .execute = false })` emits only; on **erlang** one `erl` compiles every written `.erl` in memory with the OTP compiler (`checkErlang`), because a build that only transpiled proved nothing about erlang | every module compiled, its artifact is on disk, and on erlang the OTP compiler accepted every emitted module | no project, unsupported target, unresolvable tree or dependency, **any** module failed — each failing module is rendered (file, line, excerpt) and named in `N module(s) failed to compile: a, b` — or, on erlang, the OTP compiler refused an emitted module (each refusal printed `<file>:<line>:<col>: <message>`, then `the OTP compiler refused emitted erlang`) or `erl` could not be run |
| `run [--target T] [--module M] [--out D] [-- args…]` | what `build` reads | what `build` writes, into `D` | `node` / `wasmtime` on `D/M.<ext>`; on **erlang** `erlc -o D/erl` over every emitted `.erl` and then `erl -noshell -pa D/erl -eval "M:main([]), halt()."` (`beam` only prints the `erlc +from_asm` hint) | the program's own 0 | `build`'s code, or the program's — on erlang a **crash is `1`**, `erl`'s status, where `escript` used to exit `127` (see "the erlang runner reaches one module") |
| `check [<path>]` | `botopink.json`, `src/` **and** `test/`, dependencies — in `<path>` when given | nothing | `erl` (comptime) | every module type-checks | at least one diagnostic, each with file, line and excerpt; failing modules named |
| `test [--target T] [--filter S] [--json]` | `botopink.json`, `src/`, `test/`, dependencies | `.botopinkbuild/test-out/<target>/<id>/**` — one directory per RUN and per TARGET (`id` is 64 random bits), removed again when the run ends; its `tmp/` is the tests' scratch directory, named in `BOTOPINK_TEST_TMPDIR`. Never the shared `test-out/` root: `botopink-lib-test` runs every cell with `cwd = <lib dir>`, so two gates over one library checkout used to empty each other's output mid-run and red a library nobody owned | the target runner per module with tests (`node` / `escript`) | every module compiled **and** every test passed; the last stdout line is the run's total, `total: <P> passed, <F> failed in <N> module(s)` | a module failed to compile, a test failed, a module's runner printed no summary line (it stopped before its tests finished — named), or the binary is **stale**: its checkout's sources changed since it was built (`source_stamp`, refused before anything runs); the modules that compiled still ran their tests and are reported |
| `format [paths…]` | the files and directories named, else the current directory — every `.bp` **and** `.d.bp` under it (`src/**`, `test/**`, `examples/**`, the projects nested inside), not entering hidden directories or `node_modules`, and not reaching a `reject/<n>.bp` that has its `<n>.expect` beside it (the language suite's rejected program — decision 66; the exemption is the directory's shape, decision 67: no skip list, pragma or environment variable) | the files, in place | nothing | every file parsed and is now canonical (ending with one newline) | a file could not be read, lexed or parsed (rendered with its location) |
| `format --check [paths…]` | as above | nothing | nothing | every file parsed **and** already canonical | a file would change (one `Formatted <path>` line each, then `N file(s) would be reformatted`), or could not be read, lexed or parsed. `scripts/format-check.sh` (gate stage 3, CI) calls it over the compiler's canonical trees |
| `new <name> [--target T]` | nothing | `<name>/{botopink.json,src/main.bp,.gitignore}` — the scaffolded `main.bp` **prints** (see "the scaffold runs" below) | nothing | scaffolded with a supported target | bad name, or a target outside `commonJS\|erlang\|beam\|wasm` |
| `clean` | nothing | deletes `out/` and `.botopinkbuild/` | nothing | both are gone (`Removed <dir>/` printed per success) | a delete failed |
| `migrate [--dry-run]` | the `src/` tree | index files (`root.bp`/`main.bp`/`mod.bp`) — **none** under `--dry-run` | nothing | the tree is covered | `src/` unreadable |

Cross-command rules:

- **Arguments.** Every parser in `main.zig` rejects an unknown flag, a positional
  the command does not take and an unsupported target (exit 1, with the token
  named). `--flag value` and `--flag=value` are equivalent. A `botopink.json`
  whose `target` is unsupported fails the command instead of degrading to
  commonJS (`ProjectConfig.parsedTarget` returns `null`).
- **`build`, `check` and `test` agree**: on the same tree either all three exit
  0 or all three exit 1. They share `cli/diagnostics.zig`. Every failed module
  carries its located diagnostic in `ComptimeOutput.outcome` — a lex or parse
  error included (`.parseError` holds the `SyntaxError`; a lex error no longer
  aborts the session, so the other modules still compile and get diagnosed).
  `build`/`test` read the same diagnostic from `codegen.generateWith`'s result:
  every module comes back, a failed one with `result.diagnostic` (lex, parse,
  type) or `result.comptime_err` (validation), and `diagnostics.failedOutputs`
  renders each and names the failed non-declaration modules (a module with no
  entry at all is named too). No command re-runs the comptime pipeline to
  explain a failure. A checker **warning** (decision 57 — `OkData.warnings`)
  fails nothing: `check` renders each one like an error under `warning:`
  (`renderOutcome`'s `.ok` arm, `renderLocatedAs`); `build` and `test` do not
  print them yet, since `codegen.generateWith`'s result does not carry them.
- **Orphans.** A `.bp` file that **nothing** reaches is warned per file and
  counted once (`N module(s) not reached by any `mod` path were not compiled`).
  A module has two routes into a build and reachability means either: a `mod`
  path from the root, or the manifest's `files`, which ships it to a consumer
  that is not this package's module tree. `libs/std` is the second kind —
  `src/primitives.bp` is ambient, embedded into the global type env by
  `build.zig`'s `std_core_files` and declared in `libs/std`'s `files`, never in
  `root.bp`'s `pub mod` chain. Knowing only the first route, the check warned
  about it on every gate run. A file in neither is still an orphan, which is the
  case the warning exists for. The walk skips what is not this package's tree
  (`resolver.inOwnTree`): a hidden directory, the flat `test/` suite when the
  source root is the project root, and a directory holding its own
  `botopink.json` (a nested package, such as a local `path` dependency).
- **The source root is the manifest's `src`.** `build`, `check` and `test` load
  the project's modules from `ProjectConfig.srcDir()` — `"src/"` → `src`,
  `"."` → the project root. They used to read a hard-coded `src/`, so a package
  whose `src` is `"."` compiled nothing: `check` answered "no source files found
  in src/ or test/" and a test could not import a nested module (onze F5,
  `tests/language/modules/src_at_package_root`).
- **An import names something.** `import … from "<name>"` must resolve to a
  package module (the `mod` tree, dotted path), to a declared dependency
  (`<dep>` or `<dep>.<module>`) or to `std`; otherwise `build`, `check` and
  `test` exit 1 with `unresolved import source — no such module or dependency`,
  naming what the `from` said and where (`at: src/main.bp:1:20`). A `from` that
  names a module which *does* exist but does not export the symbol is the other
  error (`imported symbol is not exported by the named module`), also located.
  It is not raised against a module that does not lex or parse
  (`Analysis.broken`): its export list is unknown, not empty, and the compile
  reports the module's own located error instead (onze F8,
  `tests/language/modules/lexer_error_in_imported_module`).
  Before this, an import naming nothing bound nothing and said nothing: exit 0,
  with code emitted.
- **Two loaders, one import rule.** `src/` is a package and loads through
  `sources.load` → `resolver.resolve`, which applies the rule as pass F4. The
  flat `test/` directory is **not** a package — `check` and `test` discover it
  with `scanner.scanSourcesWithFiles`, which never calls the resolver — so those
  two commands run `sources.checkFlatImports` over it, which hands
  `resolver.checkSources` the resolved `src/` modules together with the flat
  ones. A `*_test.bp` may therefore import the package it tests, and still
  cannot name a module that does not exist. `format` scans without checking:
  it rewrites files and resolves nothing.
- **An import under `from "…"` depends only on what the clause names**
  (`resolver.importOwner`): the project module the clause names, or nothing
  when it names std or a library — never whichever project module declares a
  `pub` of the same name (`ImportRef.has_from`). A `pub fn attempt` beside
  another module's `import {match.attempt} from "routing"` drew an edge to the
  declarer, formed a cycle, and compiled an importer before the module it
  imports (`unbound variable` at an unrelated call). `checkVisibility` reads
  the same owner. Only a from-less import falls back to the bare-name owner.
- **A comptime validation error's box names its file**
  (`diagnostics.renderValidationError`, `fileLabel`).
- **Compiling does not execute.** `build` and `test` call
  `codegen.generateWith` with `.execute = false`: no `node`/`erl`/`wasmtime`
  spawn and no `.botopinkbuild/runtime-cache` entry at build time (`test` runs
  each test module once, through its runner). Only the codegen snapshot harness
  executes (`codegen.generate`, which sets the flag). Pinned by
  `tests/cli_contract.sh`.
- **Two runs in one checkout do not empty each other's output.** `botopink test`
  writes to `.botopinkbuild/test-out/<target>/<id>/` — per target and per run,
  `id` being 64 random bits — and removes that directory when the run ends; the
  shared `test-out/` root is never written to directly. `botopink-lib-test`
  runs every cell with `cwd = <lib dir>`, so two gates over one library checkout
  (two worktrees, or a gate and a hand-run `botopink test`) used to empty each
  other's output mid-run and leave the loser reporting a library red owned by
  nobody: `Cannot find module …/x_test.js` under node, or an `{error,undef}`
  storm under escript once the `.erl` siblings its runner loads had been
  replaced by the other target's `.js`. Pinned by row C3b of
  `tests/cli_contract.sh`, which reds against a pre-fix binary
  (`BOTOPINK_BIN=<old>`).
- **A test's scratch directory is the run's own.** `botopink test` creates
  `<run dir>/tmp` and names it, absolute, in `BOTOPINK_TEST_TMPDIR` for every
  runner it spawns (`test_cmd.zig`, `TEST_TMPDIR_ENV`); it goes with the run
  directory when the run ends. A test that writes files — a fixture project it
  compiles, a pid file, a certificate — writes them there, never under the
  library's own directory: the commonJS and erlang cells of one library run
  side by side with that directory as their cwd. rakun's build tests wrote
  their fixture projects to `.botopinkbuild/tmp/<member>-fixtures/<name>`,
  each cell `rm -rf`'d a fixture before writing it, and the pinned
  `rakun-data·commonJS` count read 6, `build`, 1 on three consecutive gates.
  Pinned by row C3c of `tests/cli_contract.sh` (two concurrent runs, two
  distinct absolute directories inside their runs, both removed), which reds
  against a pre-fix binary.
- **The scaffold runs.** `botopink new` writes a program whose `main` calls
  `@print`. A block's value is its `break` (semantics decision 2), so the old
  template — a body whose only statement was the literal `"Hello, world!"` —
  compiled, ran and printed nothing, and the README's quick start had no
  visible effect. Pinned by `tests/cli_contract.sh` (the `@print` in the written
  file, and `Hello, world!` on stdout from `botopink run`).
- **Dependencies.** A missing dependency is named (`dependency 'server' was not
  found under any library root`). A dependency's `files` entry that cannot be
  read is `LibFileNotFound`: `libs.loadOne` prints the path it looked for,
  located at the entry in the dependency's `botopink.json`
  (`--> <lib>/botopink.json:L:C`), and the commands add nothing after it.
  Pinned by `tests/cli_contract.sh`.
- **Workspaces and the dependency object.** Pinned by `tests/cli_contract.sh`:
  a member builds and tests against a sibling declared `{ "workspace": true }`
  with no root export; a library member without `files` fails its own `test`
  with `ships nothing`; `build`/`check`/`test` on the umbrella are refused
  naming the members; a `path` to a sibling is refused naming the fix; the
  string-array `dependencies` is refused naming the rewrite; a `path`
  dependency resolves with no library root at all.
- **A host sidecar ships through the resolved dependency, or the build fails.**
  The `.mjs` a `#[@External.Node("./x.mjs", …)]` requires is copied from the
  directory the dependency resolved to — a `{ "workspace": true }` member, a
  `{ "path": … }` package outside every library root, a name a second checkout
  also declares — and never from whichever entry of that name the roots happen
  to carry. A sidecar a module requires and the build cannot ship is a located
  error on the `dependencies` entry and exit 1, never a silent exit 0
  (decision 67 of 1.0.10-beta: no flag reduces it to a warning). Pinned by
  `tests/cli_contract.sh`, whose four rows red against a pre-fix binary
  (`BOTOPINK_BIN=<old>`). A module name with a `/` is a dependency's
  (`rakun/http` → owner `rakun`) unless the project's own `src` holds
  `<name>.bp` — a module in a folder of the project itself (`io/random` in
  `libs/std`'s own `botopink test`) probes the project's `src/sidecars/`
  (`libs.zig` `shipMjsSidecars`).
- **`botopink test` on erlang writes a module's type units beside it.** A
  `type` is an erlang module of its own (policy 3); `test_cmd.zig` writes each
  unit, named by its atom, in the directory of the module that declares it, so
  the runner of a module in a folder (`io/net`), which loads the `.erl` files
  of its own directory and below, finds them (a unit at the root of the run
  was `{error,undef}` there).

### `botopink test` output format

Each `test "name" { … }` block emits a fixed envelope (generated by the
commonJS and erlang test runners in compiler-core codegen) so downstream
tooling (lib-test-runner, `--json` consumers) can parse per-test outcomes:

```
TEST <file>:<line> <name>
----- RUN LOG -----
\`\`\`logs
<captured stdout>
\`\`\`
  duration <ms>ms
  ok   <name>          | (or)
  FAIL <name>  (<err>)  at <file>:<line>
```

`  duration <ms>ms` sits between the fence-close and the ok/FAIL line
(monotonic clock around the test body); parsers that don't recognise it skip it.
The runner closes with a single summary line: `<P> passed, <F> failed`.
Exit code is non-zero when any test fails.

`<file>` is the package-relative source path the driver scanned
(`src/main.bp`, `test/foo_test.bp` — `Module.srcPath`, the file `@src().file`
names), on the TEST line, the FAIL line and an `assert`'s location alike; a
dependency's is `<its src>/<file>` with a trailing `/` of `src` dropped
(`libs.loadOne`).

After the results the run lists every snapshot candidate the project holds —
each `*.snap.new` `testing.snapshots` wrote for a missing or a mismatched
snapshot, package-relative, dot directories and `node_modules` not entered
(`snapshotCandidates`):

```
----- SNAPSHOT CANDIDATES — a mismatch or a missing snapshot; record one by renaming it without `.new`, never commit it -----
  src/__snapshots__/snap/first.snap.new
```

Under `--json` the same block goes to stderr, so stdout stays JSONL. The
pre-commit gate refuses a staged candidate (`scripts/gate.sh --staged`).

**Backends**: `botopink test` runs only `commonJS` (via `node`; stdout captured
per test through a `process.stdout.write` override) and `erlang` (via `escript`;
`io:format` output lands inside the fence through the group leader). Other
targets are rejected with "currently supports only the commonJS and erlang
targets".

**`--json` (JSONL)**: `botopink test --json` captures each child runner's
stdout, parses the envelope above, and re-emits one JSON object per line
(stderr passes through). Schema:

- per test: `{"event":"test","module":"<src-name>","file":"<path>",
  "line":<u32>,"name":"<test name>","status":"ok"|"fail",
  "run_log":"<captured stdout>","duration_ms":<u32>,
  "error_message":"…","error_file":"…","error_line":<u32>}` — the
  three `error_*` keys appear only on `"status":"fail"`; `duration_ms` appears
  only when the envelope carries a `duration` line. Strings are RFC 8259 §7
  escaped.
- per module that did not finish (its runner printed no `<P> passed, <F>
  failed` line — it did not load, or died mid-run):
  `{"event":"module_crashed","module":"<src-name>","exit":<n>}`; it counts as
  ONE failure in the summary, so a crashed module never reads as `"failed":0`.
- end of run: `{"event":"summary","passed":<P>,"failed":<F>}` — one record
  aggregated across every module the run touched.

The parser lives in `cli/test_cmd.zig` (`emitJsonl` + `parseFailLine` +
`parseDurationMs`); unknown envelope lines are skipped. Text mode (no flag)
inherits stdio so the envelope streams live.

See [`src/AGENTS.md`](src/AGENTS.md) for the dispatch flow and
[`src/cli/AGENTS.md`](src/cli/AGENTS.md) for the per-command list.

## Tagging

`compiler-cli` is auto-tagged on push by
[`../../.github/workflows/tag.yml`](../../.github/workflows/tag.yml) (path
filter: `modules/compiler-cli/**`):

- `compiler-cli/<version>-feat` — moving; force-updated on each feat push.
- `compiler-cli/<version>` — immutable; created once per master/main push.
  Re-push without bumping `botopink.json.version` → red gate.

`<version>` is this module's `botopink.json.version` (not the workspace `v*`
release tags). Bump it in the same change you want tagged.

## The erlang runner reaches one module

`botopink run --target erlang` ran `escript out/main.erl`, and `escript` compiles
**only the file it is handed**. Every cross-module call in a multi-module program
was therefore `undefined function <mod>:<fn>` at run time, with correct and
correctly qualified emitted code — three `tests/language/modules/*` cells and
`examples/modules` failed on erlang for that reason alone.

Two shapes that look like the fix and are not:

```
$ escript -pa out out/main.erl
escript: illegal operation on a directory: 'out'
$ ERL_FLAGS="-pa out" escript out/main.erl      # unchanged: no .beam exists yet
```

The compile step is the missing half, not the code path. `cli/run.zig`
(`runErlang`) does what the beam arm of `tests/language/run.sh` already did:

1. `erlc -o <out_dir>/erl` over **every** emitted `.erl`, found recursively — a
   module left uncompiled is an `undef` at run time, not a compile error;
2. `erl -noshell -pa <out_dir>/erl -eval "<module>:main([]), halt()."`

Two details that are load-bearing:

- **`main([])`, not `main()`.** `main/1` is always exported — it is the escript
  entry point — while `main/0` is emitted only when `main` is `pub`. A runner
  calling `main:main()` fails with `undef` on any project whose entry is a plain
  `fn main()`, `examples/modules` included. The asymmetry itself lives in
  `codegen/erlang.zig` and is not changed here.
- **A crashing program now exits `1`.** `erl` returns 1 where `escript` returned
  127 (measured on a `1 / 0` program). The 127 was escript's artefact, nothing
  asserted it, and it is not mapped back — the table above says `1`.
