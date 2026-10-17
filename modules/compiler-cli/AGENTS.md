# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── botopink.json        ← module manifest (`version` drives the auto-tag)
├── tests/               ← end-to-end CLI scripts — `zig build test-cli` runs all five
│   ├── cli_contract.sh      ← the command contract (rows C1–C13, plus a type
│   │                          error's `= hint:` under its excerpt from `check`
│   │                          and `build`, plus the
│   │                          build-does-not-execute and `new`-scaffold-prints
│   │                          rows, and a built erlang / beam program loading
│   │                          its `.erl` sidecar under `erl -pa out/<target>`,
│   │                          and 1 200 modules under a deep `--out` within a
│   │                          1 MiB ARG_MAX, and the OTP release rows: `--version`,
│   │                          an `erl` shim answering 29 / 28, a manifest `"otp"`,
│   │                          and `build` / `test` printing the checker warning
│   │                          `check` prints — decision 57, and `botopink cell`:
│   │                          a passing cell, a mismatch's `.snap.new` and
│   │                          exit 1, a new cell's candidates and manifest, a
│   │                          departing target, no majority, every way a
│   │                          `"targets"` narrowing is refused, a cell without
│   │                          `botopink.json`, malformed input; and `check`
│   │                          of `local_dependency`, a type its dependency's
│   │                          `.d.bp` declares — decisions 514, 515)
│   │                          against the real binary
│   ├── backend_exec.sh      ← the wasm core module's `--invoke main` (a `wasi`
│   │                          build's core module run on its own); `zig build
│   │                          test-backends`
│   ├── backend_exec/        ← the numeric fixture (`main() -> i32` answering 55)
│   ├── closure_invariant.sh ← decision 509 (2)'s invariant (144 B-60): the library
│   │                          `shelf` built under `plain` and under `crowded`
│   │                          (a second dependency, its own module and std
│   │                          declaring `shelf`'s names again), every file of
│   │                          `shelf` — `.js`, `.d.ts`, `.erl`, `.S`, `.wat` —
│   │                          compared byte for byte; and under `hosted`
│   │                          (erlang, beam: a consumer binding a BEAM host
│   │                          — `shelf/demo`'s entry point loads no sidecar
│   │                          for it); in `test-cli`, and alone as
│   │                          `zig build test-closure-invariant`
│   ├── closure_invariant/   ← its fixture: `shelf`, `rival`, `plain`, `crowded`, `hosted`
│   ├── test_tooling.sh      ← `botopink test` behaviours: empty test, --filter
│   │                          (multi / none), assert message, a failing `try`, the
│   │                          FAIL line's `src/main.bp:<line>` (commonJS + erlang),
│   │                          mixed pass/fail exit, the `.snap.new` candidate list;
│   │                          `botopink-lib-test` compiles a test-less library,
│   │                          and prints under `--jobs 4` what `--jobs 1` prints;
│   │                          a test reads its module's private fn and `val` on
│   │                          all four targets, a dependency's tests never run
│   │                          (decision 513), and a second run reads the
│   │                          dependency's level B entry with its CODE (not
│   │                          rewritten) with the same results (144 B-60);
│   │                          a `"targets"` exclusion is never run and is audited
│   │                          (structural / builds / another error — runner and
│   │                          `scripts/test-libs.sh`); `BOTOPINK_BIN` in a test;
│   │                          a dependency's erlang host `.erl` is shipped and reached
│   ├── test_tooling/        ← pass + fail fixture projects
│   └── cell/                ← fixture cells of `botopink cell` (§ Cells): prints,
│   │                          aborts, departs, narrowed, refused — each with its
│   │                          own `botopink.json`, each green
│   │                          under `botopink cell check`; cli_contract.sh copies
│   │                          them before it edits one
│   └── cell-workspace/      ← a workspace of cells with nested member entries
│   │                          (`group/*`, `second/group/*`, 144 B-113): each cell
│   │                          inherits the workspace's dependency in `cell check`'s
│   │                          copy; a workspace itself, so not a member of
│   │                          `conformance/modules/` (workspaces do not nest)
│   └── code_cache.sh        ← the code cache (decision 509) and the workspace a cell
│   │                          inherits from (512): a member that writes its name alone
│   │                          builds against its workspace's dependency; two members
│   │                          over one dependency compile it once (the entries' inodes
│   │                          kept, the second member's `.beam` a link to the first's
│   │                          entry); `test` and `build` link the entries `run`
│   │                          stored (a dependency's production unit is one under
│   │                          all three, decision 513); `cell check` keeps the store where the cells
│   │                          live; the member's own module never stored; a changed
│   │                          byte misses; `--cold` rewrites every entry; two
│   │                          concurrent writers leave whole entries, nothing staged.
│   │                          An inode it compares is pinned by a link of its own
│   │                          (here, in level_b.sh and test_tooling.sh): ext4 reuses a
│   │                          freed inode at once, so an entry written twice could land
│   │                          on the inode it was read at
│   └── level_b.sh           ← the code cache's level B (144 B-60): over the closure
│   │                          invariant's fixture, `build --cold`, a build that
│   │                          writes `.botopinkbuild/analysis/`, one that reads it —
│   │                          every file the same bytes on commonJS (+ `.d.ts`),
│   │                          erlang, beam, wasm and wasm's browser host; `plain`
│   │                          reads the `shelf` entry `crowded` wrote; an entry
│   │                          read by `build`, `check` and `test` is never
│   │                          rewritten (its inode), a changed byte writes anew;
│   │                          across invocations a file rewritten with the same
│   │                          bytes reads the entry (the key is by content),
│   │                          another target leaves it, a truncated one is
│   │                          discarded and written whole again (as `--cold`);
│   │                          an entry `check` wrote gets its CODE from the next
│   │                          build (larger, once), read after, the same bytes
│   └── analysis_equivalence.sh ← level B over real libraries (144 B-60, guard 2,
│   │                          `test-analysis-equivalence`): two conformance cells
│   │                          each of rakun's packages `rakun`, `rakun-bpp` and
│   │                          `rakun-stylesheet` (`conformance/<package>/<feature>/<cell>`, decision 548) — the checkout's
│   │                          sibling, the first ancestor's `repository/rakun`,
│   │                          copied to scratch with the other siblings linked —
│   │                          built `--cold`, writing the library's entry and
│   │                          reading it, the same bytes on every target the
│   │                          suite declares; the library's entry must exist
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
                        # libs / resolver / test_cmd /
                        # diagnostics / clean;
                        # root = src/main.zig, cwd = modules/compiler-cli) — main.zig's
                        # `test { _ = @import(...) }` block pulls every cli/ file in; a
                        # file not listed there has its tests silently skipped

# End-to-end scripts under tests/ spawn the CLI and runtimes, so they are NOT
# part of `zig build test`. From the workspace root:
zig build test-cli      # all seven scripts, in order, against the installed CLI
zig build test-backends # backend_exec.sh alone
zig build test-closure-invariant # closure_invariant.sh alone (also in test-cli)
zig build test-analysis-equivalence # analysis_equivalence.sh alone (also in test-cli)

# Or directly (each builds the CLI unless BOTOPINK_SKIP_BUILD=1 is set;
# cli_contract.sh also takes BOTOPINK_BIN=<binary> and BPMP_BIN=<bpmp> to test another build):
bash modules/compiler-cli/tests/cli_contract.sh      # command contract C1–C13
bash modules/compiler-cli/tests/test_tooling.sh      # `botopink test` behaviours
bash modules/compiler-cli/tests/code_cache.sh        # the code cache and workspace inheritance
bash modules/compiler-cli/tests/backend_exec.sh      # the wasm core module's --invoke main
bash modules/compiler-cli/tests/closure_invariant.sh # a library's output under two consumers (509 (2))
bash modules/compiler-cli/tests/level_b.sh           # level B: cold, writing and reading builds the same bytes
bash modules/compiler-cli/tests/analysis_equivalence.sh # level B over rakun, rakun-bpp and rakun-stylesheet cells
```

> **Every assertion is hard** — there are no pinned reds, and a missing runtime
> fails the script. **What a program answers is not here**: the language half
> these scripts held moved to conformance cells in 144 B-29 step H, each run on
> the four targets by `botopink cell check` — `backend_exec.sh`'s numeric
> program (`conformance/modules/tail_recursive_sum`: `55` everywhere, beam
> included, which the script had left out), its records / enum / `case` /
> lambda program (`record_enum_case_lambda`, wasm included) and the `mod` /
> `pub mod` package (`modules`, the former `examples/modules`, on all four);
> `mutual_recursion.sh`'s forward reference and `isEven` ↔ `isOdd`
> (`mutual_recursion_forward_reference`; the script and its fixture are gone);
> `test_tooling.sh`'s `assert cond, "msg"` and `try` (`assert_message_aborts`,
> `conformance/test/assert_and_try.bp`). The scripts keep the CLI's contract:
> `cli_contract.sh`, `test_tooling.sh`'s report (`--filter`, the totals, the FAIL
> line's message and `src/main.bp:<line>`, the `*.snap.new` list),
> and `backend_exec.sh`'s `wasm --invoke main`.
> The `std` suite on erlang is covered by `zig build test-libs`, not a script.

## External libs (generic loader)

`cli/libs.zig` is the driver-side half of the lib-agnostic package mechanism. A
project's `botopink.json` `dependencies` — the object form only (decision 76;
`conformance/docs.md` § The manifest schema) — are resolved by the shared
`manifest.resolveDependency` (`modules/manifest`): `{ "path": … }` from the
project directory (must hold a package of that name; a sibling member of the
enclosing workspace is refused with `use { "workspace": true }`);
`{ "workspace": true }` to the sibling member of the enclosing workspace
(`config.load` finds it — `ProjectConfig.workspace`); `{ "git": … }` by name
across the **lookup tiers** (`dependencyTiers`, decision 483), the first tier
that carries the name answering: `BOTOPINK_LIB_ROOTS` entries (when set); then
the project's `.botopinkbuild/deps/` and, for a workspace member, its workspace
root's (`manifest.depsRoots`, one tier each — the links `bpmp install` writes
into its store and `bpmp link` into a local checkout's `repository/<name>`); and
last, as the fallback, the **root list** (`resolveLibRoots`): `BOTOPINK_LIB_ROOTS`
entries again, then, walking up from cwd, each ancestor `D` contributes — when
present — `D` itself when its `botopink.json` is a workspace (its members),
`D/repository/botopink-lang/libs` (bundled libs), `D/repository` (sibling
projects), and `D/libs` (flat tree), de-duplicated first-occurrence-wins; the walk
stops after the first `D` that holds `repository/` — the enclosing checkout
(`manifest.isCheckoutRoot`), so a meta worktree under `.tasks/<name>` never sees the
main checkout's libraries a second time (decision 143). Each tier is one
`manifest.scanRoots`, so a name two tiers carry is the earlier tier's (a link
wins over the walk-up, an env root over a link) and never "declared by two
libraries"; every package of the closure looks its `git` dependencies up in the
project's tiers. A dependency reached through a link resolves its own `path`
and `workspace` dependencies from the link's target when the link is the
package itself — `linkFreeDir` — so a git dependency with a `"subdir"` finds
its `../<sibling>` and its workspace inside the checkout (decision 344).
`manifest.scanRoots` turns the roots into
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
`require` to reach it. `std`'s `.mjs` sidecars (`libs/std/src/sidecars/*.mjs`) are embedded in the binary beside its modules (`build.zig` `stdSidecarFiles` → `std_sidecars`, `comptime_pipeline.stdSidecar`) and `shipMjsSidecars` ships them from that copy — never from a `std` directory, which a project outside any checkout (a library's cell, a published binary) does not have (144 B-49). `std` — the one bundled package (decision 326) — is the exception to "declared, then found on disk": it is embedded in the binary, and `libs.loadDependencies` refuses it listed in `dependencies`. Every other library (`routing`, `actions`, … included) is declared and found on disk like any dependency.

`shipErlSidecars` is the erlang counterpart: a `#[.Erlang("host",
"fn")]` lowers to `host:fn(…)`, and `host` is a module the library authors in
erlang and keeps beside its `.bp` sources (`<lib>/src/sidecars/<host>.erl`, else
`<lib>/src/<host>.erl`; a project-own module probes `src/sidecars/` then `src/`).
It scans every emitted erlang module for `atom:atom(` qualifiers and copies the
ones it finds a source file for into the output — so a qualifier naming an OTP
module or another module of this build is a no-op, with no lib names in the
code. **Three callers**: `botopink test` (`test_cmd.zig`, into the run's directory —
the test runner's `__bp_load_siblings/0` compiles and loads every `.erl` beside
the script; the copy lands before `precompileErlang`, so a host module is
compiled once per run like every other `.erl`), `botopink build --target erlang`
(into `<out>/erl/`, where `botopink run` compiles every `.erl` onto the code
path) and `botopink build --target beam` (into `<out>/beam/`, beside the `.S`
files, where the assembled entry's `'__bp_load_siblings'/0` compiles and loads
them at start — `codegen/beam_asm.zig`). The beam build reads the same host
modules out of BEAM assembly (`{extfunc, host, fn, N}`), and a host module that
is neither shipped nor on the Erlang code path is the same located refusal on
both targets.

**A build is a program without `botopink run`.** `out/beam/` runs as
`erlc +from_asm -o out/beam out/beam/*.S` and then `erl -noshell -pa out/beam
-eval "'<entry atom>':main([]), halt()."` from any directory — the entry's
loader compiles the shipped `.erl`. `out/erl/` runs the same way once **every**
`.erl` in it is compiled (`erlc -o out/erl out/erl/*.erl`): a plain erlang build
emits no sibling loader (the emitter's half, 02-erlang step 9), so compiling the
entry alone leaves the sidecar `undef`. Pinned by `tests/cli_contract.sh` on
`conformance/modules/erlang_host_sidecar_shipped`.

### The erlang runner reaches one module

`cli/run.zig` spawns `escript <out>/<module>.erl`. `escript` compiles **only the
file it is handed** and has no code-path flag (`escript -pa out out/main.erl` →
`escript: illegal operation on a directory: 'out'`), so every call into a sibling
module is `undef` at run time even though the emitted code is right. Measured on
four projects, each of which prints its expected output once the modules are on a
code path:

| project | escript today | emitted call |
|---|---|---|
| `conformance/modules/two_modules` | `undefined function geometry:norm/1` | `geometry:norm/1` — qualified, correct |
| `conformance/modules/mod_tree` | `undefined function shapes:describe/0` | `shapes:describe/0` |
| `conformance/modules/std_import` | `undefined function dict:empty/0` | `dict:empty/0` |
| `conformance/modules/modules` | `undefined function geometry:area/2` | `geometry:area/2`, `shapes:describe/0`, `shapes:lucky/0` |

The shape that works is the one the beam arm of the language runner (`tests/language/run.sh`, before 144 B-29 step H) already
uses: `erlc -o <out_dir>` over every emitted `.erl` **found recursively** — the
file layout nests (`out/shapes/circle.erl`, `out/std/dict.erl`) while the module
atom is flat, so `-o <out_dir>` is what puts each `.beam` where a single
`-pa <out_dir>` looks — then `erl -noshell -pa <out_dir> -eval "<module>:main([]), halt()."`.
`main([])` and not `main()`: `main/1` is always exported, while `main/0` is
emitted only when `main` is `pub` (`conformance/modules/modules` declares `fn main()` and
exports just `'_botopink_main'/0, main/1`). A crash's exit status moves from
escript's `127` to `erl`'s `1`.

`cli/run.zig` belongs to front `13-module-identity`, together with the `-pa` row
of its output-layout step — so this is recorded here, not fixed here.

**Unknown `botopink.json` fields are ignored; known ones are checked.** The
shared `manifest` model (`modules/manifest/src/root.zig`, schema in
`conformance/docs.md` § The manifest schema) is the one parser: `config.zig` projects it into
`ProjectConfig` (`name`/`version`/`target`/`entry`/`dependencies`/`files`, the
enclosing `workspace`) and `libs.zig` reads a dependency's `src`/`files` from
it. A manifest named `std` is refused (decision 453) unless
the project directory is the bundled `libs/std` (`manifest.isBundledStd`, asked by `config.load`; contract case "a package named std is refused at its manifest" in `tests/cli_contract.sh`). The bpmp-facing `botopink` (compiler version constraint) and `requires`
(per-dep version constraint) pass through untouched. A refused manifest — not
JSON, the retired string-array `dependencies`, a dependency without a source, a
workspace where a package is needed — is a located diagnostic printed by
`config.load`/`libs.loadDependencies` before `ConfigInvalid`/`LibManifestInvalid`,
and the commands add nothing after it; a dependency's manifest is located relative to the working
directory (`deps/p/botopink.json`), as its modules are. `botopink test` inside a workspace member
that is a library and lists no `files` fails with `ships nothing: manifest has
no "files"` (decision 75).

## Env

| Variable              | Read by                                  | Effect                                                                 |
| --------------------- | ---------------------------------------- | ---------------------------------------------------------------------- |
| `BOTOPINK_LIB_ROOTS`  | `cli/libs.zig:resolveLibRoots`, `dependencyTiers` | The first lookup tier of a `git` dependency (before the `.botopinkbuild/deps/` links, decision 483), and prepended to the walk-up roots. |
| `BOTOPINK_BIN`        | the tests `botopink test` runs — **set** by `cli/test_cmd.zig:testTmpEnv` (`TEST_BIN_ENV`) | "The compiler running me": the absolute path of this `botopink` executable, exported to every test runner when the variable is unset; a value the caller set passes through untouched. |
| `BOTOPINK_TEST_TMPDIR` | the tests `botopink test` runs — **set** by `cli/test_cmd.zig:testTmpEnv` (`TEST_TMPDIR_ENV`) | The run's own scratch directory, absolute (§ below). |

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
| `build [--target T] [--out D] [--typescript] [--cold]` | `botopink.json`, the `src/` module tree, each declared dependency | `D/<stem><ext>` for every module that compiled (+ `.d.ts`, + `.mjs` sidecars on commonJS, + host `.erl` sidecars under `D/erl/` and `D/beam/`); the previous artifact of a module that did not compile is deleted. The **stem** is the module ATOM under `D/erl/` or `D/beam/` for the erlang and BEAM targets (`std/math` → `D/erl/std@math.erl`), because `erlc` refuses a `-module` atom that differs from its file's basename; commonJS, its `.d.ts` and wasm keep the mirrored `D/<module path>` tree, because a `require` target and a wasm import segment ARE the module path (`cli/build.zig` `artifactPath`/`targetSubdir`) | the program is never run — `codegen.generateWith(…, .{ .execute = false })` emits only; on **erlang** one `erl` compiles every written `.erl` in memory with the OTP compiler (`checkErlang`), because a build that only transpiled proved nothing about erlang — a DEPENDENCY's module whose exact bytes the same OTP compiler already compiled is answered from the code cache `<cache root>/.botopinkbuild/cache/code/` (decision 509, `src/cli/code_cache.zig`; the project's own modules are compiled every time, a refusal is compiled and printed every time; `--cold` reads nothing); on **erlang and BEAM** one `erl` asks the code path about the host modules no sidecar answers (`libs.absentFromCodePath`) | every module compiled, its artifact is on disk, and on erlang the OTP compiler accepted every emitted module | no project, unsupported target, unresolvable tree or dependency, **any** module failed — each failing module is rendered (file, line, excerpt) and named in `N module(s) failed to compile: a, b` — or, on erlang, the OTP compiler refused an emitted module (each refusal printed `<file>:<line>:<col>: <message>`, then `the OTP compiler refused emitted erlang`) — or, on erlang and BEAM, a host module is neither shipped nor on the Erlang code path, a sidecar file is named like a module atom the build emits (located on the file, naming the module), or `erl` could not be run |
| `run [--target T] [--module M] [--out D] [--cold] [-- args…]` | what `build` reads | what `build` writes, into `D` | `node` / `wasmtime` on `D/M.<ext>`; on **erlang** what `erlc -o D/erl` over every emitted `.erl` does — a job of the command's `erl` session (`cli/otp.zig`), the VM that answered the release and ran `build`'s check, reading the files from a list file, so no command line grows with the program (`cli/arglist.zig`) — and then `erl -noshell -pa D/erl -eval "M:main([]), halt()."` (with `+sbwt none +sbwtdcpu none +sbwtdio none` first: no scheduler busy wait, the default scheduler count); on **beam** the same for `erlc +from_asm -o D/beam` over every emitted `.S`, and then `erl -noshell -pa D/beam -eval "'M':main([]), halt()."` — the entry's `'__bp_load_siblings'/0` compiles and loads the host `.erl` files the build shipped beside them | the program's own 0 | `build`'s code, or the program's — on erlang a **crash is `1`**, `erl`'s status, where `escript` used to exit `127` (see "the erlang runner reaches one module") |
| `check [<path>]` | `botopink.json`, `src/` **and** `test/`, dependencies — in `<path>` when given | nothing | `erl` (comptime) | every module type-checks | at least one diagnostic, each with file, line and excerpt; failing modules named |
| `test [--target T] [--filter S] [--json] [--cold]` | `botopink.json`, `src/`, `test/`, dependencies | `.botopinkbuild/test-out/<target>/<id>/**` — one directory per RUN and per TARGET (`id` is 64 random bits), removed again when the run ends; its `<id>.tmp` sibling is the tests' scratch directory, named in `BOTOPINK_TEST_TMPDIR` and removed with it. Never the shared `test-out/` root: `botopink-lib-test` runs every cell with `cwd = <lib dir>`, so two gates over one library checkout used to empty each other's output mid-run and red a library nobody owned | the target runner per module with tests (`node` / `escript` / `erl`, after one `erlc +from_asm` over the run's `.S` on beam) | every module compiled **and** every test passed; the last stdout line is the run's total, `total: <P> passed, <F> failed in <N> module(s)` | a module failed to compile, a test failed, a module's runner printed no summary line (it stopped before its tests finished — named), or the binary is **stale**: its checkout's sources changed since it was built (`source_stamp`, refused before anything runs); the modules that compiled still ran their tests and are reported |
| `format [paths…]` | the files and directories named, else the current directory — every `.bp` **and** `.d.bp` under it (`src/**`, `test/**`, `examples/**`, the projects nested inside), not entering hidden directories or `node_modules`, and not reaching a conformance cell's refused module: a `.bp` under a cell (a directory holding `snapshot/output/`, decisions 457, 475) whose `snapshot/output/<module>.snap` holds a `refused` record — a module every target refuses, written to be refused (every former `reject/` cell, and `conformance/modules/lexer_error_in_imported_module/src/pattern.bp`); a refusal only a `snapshot/targets/<t>/` departure states, an answer, no snapshot or no cell leaves the file in the walk (144 B-29 step H; `format_cmd.zig`'s tests). The exemption is the directory's shape, decision 67: no skip list, pragma or environment variable | the files, in place | nothing | every file parsed and is now canonical (ending with one newline) | a file could not be read, lexed or parsed (rendered with its location) |
| `format --check [paths…]` | as above | nothing | nothing | every file parsed **and** already canonical | a file would change (one `Formatted <path>` line each, then `N file(s) would be reformatted`), or could not be read, lexed or parsed. No gate stage calls it: the formatter is applied by the commit hook, never checked (decision 524) |
| `new <name> [--target T]` | nothing | `<name>/{botopink.json,src/main.bp,.gitignore}` — the scaffolded `main.bp` **prints** (see "the scaffold runs" below) | nothing | scaffolded with a supported target | bad name, or a target outside `commonJS\|erlang\|beam\|wasm` |
| `clean` | nothing | deletes `out/` and `.botopinkbuild/` whole (with `.botopinkbuild/deps/`, the `bpmp install` links, and `.botopinkbuild/cache/`, every build cache, and `.botopinkbuild/build/comptime/`, the compiled comptime modules `build`, `check` and `test` keep under their cache root through `bp.comptime_runtime.useCompiledCache` — decision 543, `--cold` reading none), and in a workspace member the workspace root's `.botopinkbuild/cache/` and `.botopinkbuild/analysis/` | nothing | both are gone (`Removed <dir>/` printed per success) | a delete failed |
| `cell new <path>` | nothing | `<path>/src/main.bp` (it prints `hello`) and `<path>/docs.md` | nothing | scaffolded | `<path>` exists |
| `cell check [--jobs <N>] [--cold] <cell\|directory>…` | each cell, in the order the paths are given, a cell reached twice checked once (a directory holding `src/`; a directory argument is walked for them, not into a cell, a hidden directory, `node_modules` or a `deps` directory): `src/`, `snapshot/`, `targets`, an optional `botopink.json` — never `docs.md` | `<file>.snap.new` candidates under the cell's `snapshot/` (the previous run's deleted first); a scratch copy under `.botopinkbuild/tmp/cell-<id>/` of the current directory, removed when the cell ends. Never an accepted `.snap` | `node`, `erl`, `wasmtime` — the built program; the build itself runs in process | every cell answers its accepted snapshots on every target it declares, and every narrowing stands | a mismatch (candidate written, difference shown), a new cell, a tool that could not run, a malformed cell, or no cell found (§ Cells) |

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
  (`renderOutcome`'s `.ok` arm, `renderLocatedAs`), and the language server
  publishes each as a diagnostic of severity Warning; `build` and `test` do not
  print them yet: `codegen.generateWith` drops the comptime session (and its
  `OkData.warnings`) before it returns, and `ModuleOutput` carries no warnings
  — a compiler-core field, not this package's.
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
  `conformance/test/src_at_package_root`).
- **`from` names a package; an import names something.** `import … from
  "<name>"` must resolve to a package — `std` or a declared
  dependency (`<dep>` or `<dep>.<module>`) — and a package wins its name over a
  module of this package named like it (decision 206: `from "log"` is the
  dependency `log` beside a module `log`). A `from` naming a module of this
  package (the `mod` tree, dotted path) is `error[module-import-with-from]`,
  located at the source string with an excerpt, writing the brace form as the
  fix (`"geometry" is a module of this package — write import
  {geometry.area};`, `resolver.braceForm`; pinned by
  `conformance/modules/import_own_module_with_from`). A `from` naming the
  package ITSELF is the same refusal, std included,
  in `src/`, `test/` and a dependency's own sources alike (decision 309:
  `"shapes" is this package — write import {geometry.area};`;
  `conformance/modules/import_own_package_with_from`,
  `dependency_imports_itself_with_from`, `tests/cli_contract.sh`); anything else is
  `unresolved import source "<name>" — declare it in botopink.json
  "dependencies"`, located at the source string with an excerpt. Only a
  **direct** dependency is importable (decision 242): a package another
  dependency brings into the build (`core` under a declared `starter`) is
  refused the same way until this package declares it
  (`conformance/modules/transitive_package_import`, four targets). A
  dependency's own modules answer the same rule against THEIR manifest when a
  consumer loads them (`libs.loadOne` → `resolver.checkSources`), located at
  the dependency's file relative to the working directory
  (`conformance/modules/dependency_imports_undeclared_package`). A module of the package is
  imported by its path inside the braces (`import {shapes.circle.name};`), and
  a path that names a module which *does* exist but does not export the leaf
  is the other error (`imported symbol is not exported by the named module`),
  also located.
  It is not raised against a module that does not lex or parse
  (`Analysis.broken`): its export list is unknown, not empty, and the compile
  reports the module's own located error instead (onze F8,
  `conformance/modules/lexer_error_in_imported_module`).
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
- **An import under `from "…"` depends on no module of this package**
  (`resolver.importOwner`): the clause names a package (decision 206) — never
  the project module named like it, nor whichever project module declares a
  `pub` of the same name (`ImportRef.has_from`); a brace import depends on the
  module its path names. A `pub fn attempt` beside
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
  `<run dir>.tmp` and names it, absolute, in `BOTOPINK_TEST_TMPDIR` for every
  runner it spawns (`test_cmd.zig`, `TEST_TMPDIR_ENV`, `testTmpDir`); it goes
  with the run directory when the run ends. It is the run directory's
  SIBLING, not its `tmp/`: an erlang runner loads every `.erl` under its own
  directory (`'__bp_load_siblings'/0`), so a fixture project a test built
  inside the run directory — its `out/erl/` — was compiled and loaded by every
  test module that ran after it (rakun-scheduling: ~6 500 fixture sources per
  module, about five CPU-minutes each, and a fixture's modules loaded over the
  run's own). Pinned by row C3d (an uncompilable `.erl` left in the scratch
  directory by each of three test modules; every module still runs), which reds
  against a pre-fix binary. A test that writes files — a fixture project it
  compiles, a pid file, a certificate — writes them there, never under the
  library's own directory: the commonJS and erlang cells of one library run
  side by side with that directory as their cwd. rakun's build tests wrote
  their fixture projects to `.botopinkbuild/tmp/<member>-fixtures/<name>`,
  each cell `rm -rf`'d a fixture before writing it, and the pinned
  `rakun-data·commonJS` count read 6, `build`, 1 on three consecutive gates.
  Pinned by row C3c of `tests/cli_contract.sh` (two concurrent runs, two
  distinct absolute directories beside their runs, both removed), which reds
  against a pre-fix binary.
- **A test spawns the compiler that is running it.** `botopink test` exports
  `BOTOPINK_BIN` — the absolute path of its own executable
  (`std.process.executablePathAlloc`) — to every runner it spawns, when the
  variable is not already in the environment (`test_cmd.zig`, `TEST_BIN_ENV`);
  a value the caller set is passed through untouched. A test that builds a
  fixture project reads the compiler from there, so it spawns the right one in
  every layout: a path relative to the library's checkout
  (`../../../botopink-lang/zig-out/bin/botopink`) exists in the meta workspace
  only, and a library's fixture-build tests would fail in CI's layout the day
  CI ran them. Neither `botopink-lib-test` nor `scripts/test-libs.sh` sets the
  variable. Pinned by the `[env]` rows of `tests/test_tooling.sh` (unset → the
  running binary; pre-set → the pre-set value; commonJS and erlang).
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
- **The build line.** `botopink --version` ends with `build: zig <version>
  <optimize mode> <arch>-<os>-<abi> <source hash> <source root>` (`main.zig`
  `BUILD_LINE`, from `builtin` and `build_stamp`): how the binary was built and
  from which sources.
- **One OTP release** (decision 228 of 1.0.11-beta). `botopink --version` prints
  `otp: 28` (`manifest.OTP_RELEASE`); `build`/`run`/`test` on erlang or beam ask
  the `erl` on PATH for its release first — the first line of the command's one
  compile `erl`, the session (`cli/otp.zig`) — and refuse another —
  exit 1, nothing written, the refusal naming both releases; a manifest `"otp"`
  other than 28 is a located manifest error, and a closure whose packages pin two
  releases is refused at the later pin naming the first manifest. Pinned by
  `tests/cli_contract.sh` with `erl` shims answering 29 and 28 (every other call
  handed to the real `erl`). On a machine whose `erl` is another release, every
  erlang / beam row of the CLI suites is refused — that is the decision.
- **Workspaces and the dependency object.** Pinned by `tests/cli_contract.sh`:
  a member builds and tests against a sibling declared `{ "workspace": true }`
  with no root export; a library member without `files` fails its own `test`
  with `ships nothing`; `build`/`check`/`test` on the umbrella are refused
  naming the members; a `path` to a sibling is refused naming the fix; the
  string-array `dependencies` is refused naming the rewrite; a `path`
  dependency resolves with no library root at all; a git dependency's
  `"subdir"` (decision 344), over a local bare repository: `bpmp install`
  clones once at the tag, links the package at the subdir, and `run` reaches
  its `path` sibling at that tag; two dependencies on the repository share one
  checkout; every refusal (no `git`, absolute, `..`, no `botopink.json`, a
  workspace, another package's name, a `path` leaving the checkout, two refs)
  is located and links nothing. Those rows red against the parent's `bpmp` and
  `botopink` (`BPMP_BIN=` / `BOTOPINK_BIN=`). Decision 483: with no link the
  walk-up's `repository/` answers; `bpmp link` with no argument links to the
  enclosing checkout, `bpmp link <checkout>` replaces that link and the build
  then reads the link, not the walk-up; `BOTOPINK_LIB_ROOTS` wins over the link;
  a project under no `repository/` resolves from its links alone; `bpmp link`
  with no enclosing checkout, and with a dependency the checkout does not hold
  (named, located, nothing linked), exits 1.
- **A host sidecar ships through the resolved dependency, or the build fails.**
  The `.mjs` a `#[@external(.Node("./x.mjs", …))]` requires is copied from the
  directory the dependency resolved to — a `{ "workspace": true }` member, a
  `{ "path": … }` package outside every library root, a name a second checkout
  also declares — and never from whichever entry of that name the roots happen
  to carry. A sidecar a module requires and the build cannot ship is a located
  error on the `dependencies` entry and exit 1, never a silent exit 0
  (decision 67 of 1.0.10-beta: no flag reduces it to a warning). Pinned by
  `tests/cli_contract.sh`, whose four rows red against a pre-fix binary
  (`BOTOPINK_BIN=<old>`). The owner of a module's sidecars is the
  package the build's module table gives it (`libs.sidecarPackage` over
  `Config.packages`): `rakun/http` → `rakun`; a module in a folder of the
  project itself (`io/random` in `libs/std`'s own `botopink test`, `orm/entity`)
  is the project's and probes its `src/sidecars/`, whatever package a library
  root carries under that folder's name (T16). On erlang and BEAM a sidecar file
  named like a module atom the build emits is a located build error naming both
  (C-25).
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
each `*.snap.new` the `snap` library wrote for a missing or a mismatched
snapshot, package-relative, dot directories and `node_modules` not entered
(`snapshotCandidates`):

```
----- SNAPSHOT CANDIDATES — a mismatch or a missing snapshot; record one by renaming it without `.new`, never commit it -----
  src/__snapshots__/snap/first.snap.new
```

Under `--json` the same block goes to stderr, so stdout stays JSONL. The
pre-commit gate refuses a staged candidate (`scripts/gate.sh --staged`).

**Backends**: `botopink test` runs `commonJS` (via `node`; stdout captured
per test through a `process.stdout.write` override), `erlang` (via `escript`;
`io:format` output lands inside the fence through the group leader) and `beam`
(every module of the run written as `<atom>.S` in the run's directory,
assembled once with `erlc +from_asm`, each test unit's runner run with
`erl -noshell -pa <dir> -eval "'<atom>':main(init:get_plain_arguments()),
halt()." -extra [filter]` — the same envelope, the same group-leader capture)
and `wasm` on the `wasi` host (each test unit, a `.wat` component linking the
whole program, run with `wasmtime run` and the flags its `botopink.needs` section asks for — `-W exceptions=y`, `-S http`, none when it names no need (decision 518, `run.wasmtimeFlags`); the filter is not read, and a
failing `assert` traps, ending the module's run inside that test's fence — it
is reported as a module whose runner printed no summary). A `browser` host is
refused.

**What runs is the module's test unit** (decision 513, 144 B-64): the
production modules `test` writes are the bytes `build` writes, and each module
of the package under test that declares tests has a test unit beside them —
`__test__/<module path>.js` (commonJS), `'__test__@<pkg>@<mod>'.erl` in its
module's directory (erlang), `'__test__@<pkg>@<mod>'.S` (beam),
`__test__/<module path>.wat` (wasm) — which reaches the module's private
functions and `val`s through the production unit's reserved export
(`codegen/AGENTS.md`). A dependency has no test unit: its tests never run for
a consumer, and its production unit is the one `build` and `run` compile, so
the code cache serves it to all three.

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

## Cells — `botopink cell` (decision 464)

A **cell** states one piece of behaviour any implementation of botopink must
give (decision 457) — its source and its answers, no generated code:

```text
<cell>/botopink.json                       its own manifest (decision 475 (1)): its package
                                           name, `"targets"` when narrowed, a path dependency,
                                           a named wasm host — what its workspace
                                           (`conformance/modules/botopink.json`, decision 512)
                                           does not declare for every cell
<cell>/src/<module>.bp                     the program; src/main.bp holds `pub fn main`
<cell>/snapshot/output/<module>.snap       the answer on every target
<cell>/snapshot/targets/<t>/<module>.snap  target <t>'s departure, only where it departs
<cell>/docs.md                             the reference text beside it (decision 462) — never read
```

`botopink cell new <path>` scaffolds `botopink.json` (`{ "name": "<the directory's name>",
"version": "0.0.1", "src": "src/" }` — a name the manifest refuses is refused here), `src/main.bp`
and `docs.md`. The suite these commands serve is `../../conformance/` (`conformance/AGENTS.md`).
`botopink cell check <cell|directory>…` (`src/cli/cell.zig`) builds each cell
**in this process** — `build.zig`'s pipeline over a scratch copy of the cell
made afresh for each target (a program that writes into its working directory
finds it as it would alone; the copy's manifest has its relative `path` dependencies made absolute against the cell's own directory, and its `BOTOPINK_LIB_ROOTS` carries the command's roots, the cell's `.botopinkbuild/deps/` tiers and the walk-up from the cell, so a cell run from any directory resolves its dependencies as it does in place, and a library's cells need no per-cell `deps/` workspace of links; a cell that is a member of a workspace — every `conformance/modules/` is one, decision 512 — is copied into a scratch workspace of its own whose manifest is the cell's workspace's, its `path` dependencies made absolute, and whose one member is the cell, so it inherits what it inherits in place and no sibling is read; its `"targets"`, when it writes none, are its workspace's; its dependencies' compiled modules are kept in the cell's own cache root (`code_cache.root_override`: its workspace's `.botopinkbuild/cache/code/`), never in the scratch copy; the report is written with a retried write, never dropped; one process checks any number of cells one after another (144 B-29 step H: no process per cell), each cell's allocations in an arena of its own freed once its report is out, so the process holds one cell's at a time (a module the erlang backend refuses frees the type units it had rendered — `codegen/tests/externals.zig` — so a long share's memory stays flat per cell); under `--jobs N` each of N workers is a `botopink cell check --jobs 1 <cell>…` process over a **share** of the cells (`shareSize`: about two shares per job, at most 32 cells), its report cut into each cell's section by the cell's verdict line (`sectionFor`), and a cell its process left with no verdict line (the process died on it) checked again in a process of its own (`needsAlone`, a pure decision pinned by a unit test over a report cut short); the parent adds a `FAIL <cell>` line when a cell's section holds no verdict line, so every cell found is reported in the cells' order and the summary's count is the cells found — `cli_contract.sh` counts a directory with two cells that cannot run), with `reporter.sink` and the manifest module's
`manifest.sink` (where `Located.print` writes: a manifest's, a dependency's and
a sidecar's refusals) pointed at a buffer, so a refusal is read off exactly the
text `botopink build` prints — and runs the built program (`run.programArgv`: `node`,
`erl` after the in-session compile of every `.erl` / `.S`, `wasmtime`; `node --import <data: URL>` so an uncaught abort writes the `Failure` text, decision 535, `bp.otp.node_abort_import`), its
stdout, stderr and exit status captured, on every declared target. Then, per
module and target, the accepted answer is `snapshot/targets/<t>/<m>.snap` when
it exists, else `snapshot/output/<m>.snap`, else empty, and it is compared with
what the target answered:

- **equal on every target** → `ok   <cell>`; a run where every cell is ok exits 0;
- **a departure that no longer holds** → `targets/<t>/<m>.snap.new` beside it;
- **`output/` holds on some targets, not on others** → `targets/<t>/<m>.snap.new`
  for each other target, reported as a departure to review;
- **no target holds `output/`, or there is none** (a new cell: no `.snap` at
  all, every module that answers and `main` get candidates) → the targets'
  answers grouped: all agreeing → `output/<m>.snap.new` only; a strict majority
  → `output/<m>.snap.new` from it and `targets/<t>/<m>.snap.new` for each other
  target, a departure to review; no strict majority → `targets/<t>/<m>.snap.new`
  for every target and `no majority — a person chooses …`: the tool never
  decides the language's answer.

Each candidate is printed with a line diff (`- ` accepted, `+ ` observed) and
the run exits 1. An accepted `.snap` is never written; a person accepts a
candidate by renaming it, as `snap`'s `.new` flow (decision 67: there is no
update flag, and `check` refuses any flag). The candidates are the run's
output: `check` deletes a cell's old `*.snap.new` before it runs it.

A cell without `botopink.json` fails (decision 475 (1): no implicit package),
and so does a leftover `targets` file. A target that gives no answer fails the
cell by name and writes nothing — a runtime that cannot be run (never skipped),
a program past 300 s, a build that fails naming no refusal, `erl` on another OTP
release, or the two wasm hosts disagreeing (decision 334: on wasm the cell runs
as the `wasi` build under `wasmtime` **and** the `browser` build under `node`
unless its manifest names its host — the `browser` manifest is the cell's with
`"wasm": { "host": "browser" }` added last, so every location in the cell's own
manifest is the same in both builds —, and both must answer alike: the same
text, or, when both refuse, the same modules refused at the same places, since
a refusal may name the host it was built for). The manifest's `"targets"`
narrows the cell to the targets it names (an array of target names, in any
order; an unknown target, one named twice, none, all four or a value that is
not an array is malformed), and each target it leaves out is **audited**:
`botopink build --target <t>` must refuse the cell on a host binding (`has no #[@external(.<Target>(…))]`,
`std-unsupported-on-target:`, `` `#[@BeamMemory]` has no meaning on the <t>
backend``) — a build that accepts it, or refuses it otherwise, fails the cell
(`conformance/AGENTS.md` § Narrowing a cell). A `snapshot/` holding anything
but `output/` and `targets/<t>/`, a departure for a target the cell does not
run, and a malformed `.snap` (named `<file>:<line>: <reason>`) fail the cell.

### The `.snap` format

One module's answer, a record per line; `src/cli/cell_snap.zig` is the one
place it is written, read and compared:

```text
botopink-cell 1                 the format and its version — always line 1
refused <message line>          the compiler refuses the module: its `error…` line
at <file>:<line>:<col>          … and where, when the diagnostic is located
label <text>                    after `at`: the label printed beside the caret, as printed (decision 485);
                                absent when the caret has none; the `hint` lines are not claimed
from <file>:<line>:<col>        after `at` and `label`: one `called from` line of a raise at build (decision 532),
                                innermost first, down to the program's call, annotation or `comptime`
out <text>                      one line the program printed (`out` alone: an empty line)
no-final-newline                the last `out` line ended without `\n`
abort                           the program exits non-zero (the number is never pinned)
stderr <text>                   with `abort`: the program's stderr contains <text>
```

```text
botopink-cell 1                         botopink-cell 1
out 3                                   refused error[namespace-type-self]: a namespace type has no value, …
abort                                   at src/main.bp:7:15
stderr integer overflow: + on i32 at src/main.bp:6:14
```

The records come in that order (`refused`, `at`, `label`, `from`); a `from` follows its `at`, read off the `= called from …` lines under the first `-->` of the refusal; a `label` belongs to a refusal and follows its `at`
(anywhere else it is a malformed `.snap`, located); a changed or vanished label is a red, a candidate
beside the accepted file like any other difference. A refusal and an output never share a file;
a record's text is never empty; a file parses only when rendering what it
parsed gives back its bytes, so each answer has one spelling. The header alone
is the empty answer — a module that compiles and, for `main`, a program that
printed nothing and exited 0 — and a missing file answers the same. Everything
is compared exactly but `stderr`, which is a claim that the abort names its
cause: the stderr (ANSI stripped) must contain the text, because the rest of a
runtime's stderr — a stack trace, absolute paths, a crash-dump notice — is not
the language's answer. `check` never writes a `stderr` line of its own; a
candidate keeps the accepted claims that still hold.

What a target answered, as `.snap`s: a build that fails gives every `error…`
line it printed (the `N module(s) failed to compile` summary aside) with the
first `--> <file>:<L>:<C>` under it and the text beside the first caret line below that (`label`), filed under the module that file is
(`src/shapes/circle.bp` → `shapes/circle.snap`; an unlocated refusal is
`main`'s) — a refusal the compiler cascades into an importer is that
importer's answer too; a build that succeeds gives `main.snap`: stdout, and
`abort` when the exit status is not 0 or the program died of a signal.

### Choices made here, for the maintainer to confirm

1. **The format** above: line-oriented records, `botopink-cell 1` as its first
   line; an abort is `abort` with no status (decision 457 "that it aborts";
   `conformance/AGENTS.md` § Never pin an erlang exit status); `stderr` is
   containment, not equality, and lives wherever the abort's words are
   claimed — `targets/<t>/` per decision 457, `output/` allowed when every
   target names the same text.
2. **A departure replaces `output/` for its module on its target, whole** — it
   is that target's full answer, not a patch over `output/` (an abort's stderr
   claim on commonJS repeats the `out` lines).
3. **The cell's package and manifest** — decided by 475 (1): every cell has its
   own `botopink.json`, and `check` refuses a cell without one. The migration of
   `tests/language` named each cell's package after the cell, and every cell's package is its directory's
   name (decision 511); the `targets` file became the manifest's `"targets"`.
4. **The entry** is `src/main.bp`, required in every cell, its `main` the
   program; the other modules are what its `mod` tree reaches. Snapshots are
   named after the module's file under `src/` (`x/mod.bp` → `x/mod.snap`).
5. **Majority** is strict (more than half of the targets that read `output/`):
   two against two is no majority.
6. **A cell whose module answers nothing** needs no file; a new cell is one
   with no `.snap` at all, and its `main` always gets a candidate, so an empty
   answer is accepted by a person, never by default.

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
correctly qualified emitted code — three `conformance/modules/*` cells and
`conformance/modules/modules` failed on erlang for that reason alone.

Two shapes that look like the fix and are not:

```
$ escript -pa out out/main.erl
escript: illegal operation on a directory: 'out'
$ ERL_FLAGS="-pa out" escript out/main.erl      # unchanged: no .beam exists yet
```

The compile step is the missing half, not the code path. `cli/run.zig`
(`erlangArgv`) does what the beam arm of the language runner (`tests/language/run.sh`, before 144 B-29 step H) already did:

1. what `erlc -o <out_dir>/erl` over **every** emitted `.erl`, found recursively,
   does — one `erl` reading the files from a list file (`compileAll`), since
   `erlc` takes them on its command line only — a module left uncompiled is an
   `undef` at run time, not a compile error;
2. `erl -noshell -pa <out_dir>/erl -eval "<module>:main([]), halt()."`

Two details that are load-bearing:

- **`main([])`, not `main()`.** `main/1` is always exported — it is the escript
  entry point — while `main/0` is emitted only when `main` is `pub`. A runner
  calling `main:main()` fails with `undef` on any project whose entry is a plain
  `fn main()`, `conformance/modules/modules` included. The asymmetry itself lives in
  `codegen/erlang.zig` and is not changed here.
- **A crashing program now exits `1`.** `erl` returns 1 where `escript` returned
  127 (measured on a `1 / 0` program). The 127 was escript's artefact, nothing
  asserted it, and it is not mapped back — the table above says `1`.
