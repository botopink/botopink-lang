# scripts · AGENTS.md

> Path: `scripts/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Installers, the release packaging helper, the gate, the
vscode-test wrapper, the snapshot audit tool, the user-docs fence checker, the comptime-path
benchmark, and the tracked git hooks.

## Tree

```text
scripts/
├── AGENTS.md          ← you are here
├── install.sh         ← POSIX one-liner installer
├── install.ps1        ← Windows one-liner installer
├── release-pack.sh    ← per-target archive + sha256 packer (used by release.yml)
├── gate.sh            ← the ordered local gate (staged checks + `zig fmt --check modules`, build, backend partition audit, test, test-bpmp, beam export audit, test-cli, test-conformance — the libraries included, decision 996 —, test-docs)
├── check-packaging.sh ← the packaging rule across the library repositories (front 98 step 2): a README per example member, an `assert<Subject>(loc: SourceLocation, …)` per `-test` member, no `"git"` to an ecosystem library from an example, every member listed by `botopink packages --list`; each failing path named, exit 1. Not called by `gate.sh` (that call is the gate's)
├── test-vscode.sh     ← locate the sibling vscode-extension, `npm ci` once, `npm test` (`zig build test-vscode`)
├── check-docs.sh      ← every `<!-- example: … -->` of the language reference names a conformance cell — `modules/<cell>`, `modules/<m>/cells/<c>` — or a case of a package, `modules/<m>/run/src/cases/<c>` / `refused/…` (decision 779; `modules/<m>/cases/<c>`, 765, while one remains) (`zig build test-docs`)
├── tsc-check.sh       ← `tsc --noEmit --strict` over every `.d.ts`, and `node --check` over every `.js`, a commonJS build of libs/std (the one package the compiler ships), the example projects and conformance/modules (and `modules/*/cases/*`, decision 765) emits (gate stage 11)
├── check-test-scratch.sh ← refuses a cwd-anchored `.botopinkbuild` path inside a `test` block or a `tests/` file (part of `zig build test`)
├── snap_audit.sh      ← read-only audit of every *.snap.md (7 modes)
├── beam_export_audit.sh ← assemble every beam snapshot module with every function exported
├── comptime_bench.sh  ← what the comptime path costs: build wall clock + the in-compiler stage split
├── macos-sim.sh       ← run a command on Linux as the macos-14 CI row would (§ Portability)
├── codemod-import-without-from.py ← decision 206's one-shot migration: `from "<a module of this package>"` → the brace form; `--shorthand`, decision 337's: `import {x};` → `import {<module>.x};` (§ below)
├── codemod-optional-operators.py ← decision 330's migration: `.unwrapOr(d)` on a `?T` → `?? d`, `result.<op>(r, …)` → `r.<op>(…)` (§ below)
├── codemod-component-contexts.py ← decision 354's migration: `@Component<C, R>` → `@Component<R>`, `@Context<C>` → `@Renderable`, `use @getContext(T)` reported (§ below)
├── codemod/external-implementations.py ← decision 575 (6)'s migration: every `#[@External.<T>(…)]` of one declaration → one `#[@external(.<T>(…), …)]` (`#[external(…)]` inside `libs/std/src`), labels kept, `fn:` → `body:`, the two-string `("m", "s")` → one template over the parameters (`"m:s($0, $1)"` erlang, `"M.s($0)"` / `$args` for a variadic on node, `"s(a, self)"` reordered), a host `${` → `\${`; `.bp` files in place, a `.zig` file's `\\` line strings as `.bp` text; `--check` lists
├── codemod/bodyless-decorators.py ← decision 604's migration: a bodyless decorator `[pub] declare fn name(comptime decl: @Decl, …);` → `[pub] fn name(…) {}`, a marker with an empty body, visibility, generics and the comments above kept; `.bp` files in place, `--check` lists every site as `path:line: name`
├── codemod-wasm-cells.py ← decision 481's migration: `.Wasm`'s prefixed strings → labelled cells (`"fn:x"` → `fn: x`, `"op:o"` → `op: "o"`, `"wasi:a_b"` → `wasi: .AB`, `"std:m.f"` → `std: "m.f"`) (§ below)
├── codemod-conformance-cells.py ← 144 B-29 step H: `tests/language/` → `conformance/` cells (`migrate`, `accept`, `audit` — § below)
├── pack-cells.py      ← decision 779: `apply <module>…` packs a module's 765 `cases/` into `run/` (the printing cases, one program, entry `runCase`) and `refused/` (the refused cases, one build), the rest into `cells/<case>/` unchanged; a case packs only when `botopink cell check` of its candidate package equals its old answers on every target (a failing candidate split in halves; each check memory-capped and timed out); a `run/` or `refused/` already there is kept and the new cases merge into it (rebuilt from its package plus the new cases, re-proved by the same check); `list` names the modules still holding `cases/`
├── consolidate-cells.py ← 144 B-157 (decision 765): `plan` homes every `conformance/modules/<cell>/` (INDEX.md, INDEX.ambiguous, generated, not committed; `conformance/modules/consolidate-homes.txt` overrides), `verify --base <ref>` is the oracle; its test is `consolidate-cells-test.py`
├── codemod/
│   ├── compiler_keyword.py      ← 144 B-136's migration (decisions 575 (4), (5), 576, 577, 578): `@Expr<T>` parameters → `comptime` / `expr`, `@Decl` → `expr d: unknown`, `x.text()` / `.fail` / the template model / a handle's reads and outputs → `compiler.*`, `@expr(v)` → `v`, `-> @Expr<T>` / `-> @ExprCustom<T>` → `-> T`, `type T` → `type<T>`, a bare `type` → `anytype`, a template's calls → `` name @`…` `` (§ below)
│   ├── test_compiler_keyword.py ← its unit tests (`python3 scripts/codemod/test_compiler_keyword.py`)
│   ├── implementation_javascript.py ← decision 618's migration: `Implementation.Node` → `JavaScript` — a source `.Node(…)` → `.JavaScript(…)`, `Implementation.Node` and a `.Node` mention in prose or a cell's answer follow; a name ending in `Node` (`ast.Node`), the old `External.Node` and the word Node are left alone; `.bp`, `.zig`, `.md`, `.sh`, `.snap` and `.json` in place, `--check` lists each file and its count (`scripts/codemod/implementation_javascript.py libs conformance modules scripts`; the libraries rerun it over their own trees)
│   ├── return_void.py           ← 144 B-21's migration (decision 622): every arrow-less `fn` — a named one (free, method, `default`, static, `declare`, bodyless or not) and a typed `fn` expression with a body — gains `-> void` after its parameters; a function type, a marked `fn`, an untyped `fn(x) { … }`, a body whose own scope returns a value or `throw`s are left and listed (`LEFT <path>:<line> <why>`), and so are the cells whose point is the missing arrow (`SKIP_CELLS`); `.bp` files in place, `--zig` the `\\` blocks and the one-line `"…"` literals of `.zig` files (a one-line literal under `src/parser/` or `src/format/` is left: those tests assert its columns), `--snapshots` moves a cell's recorded locations, `--check` lists (`scripts/codemod/return_void.py --snapshots conformance libs/std`; `--zig modules`; the libraries rerun it over their own trees)
│   ├── primitive_names.py       ← 144 B-148's migration (decision 641): every primitive type lowercase — `Array<T>` → `array<T>`, `Bytes` → `bytes`, the statics `String.fromCodepoint` / `Array.range` / `Array.repeat` / `Bytes.fromUtf8` / `BigInt.of` → `string.` / `array.` / `bytes.` / `bigint.`, `implement S for String` → `for string`; each rewrite keeps the length (no location moves); a name after a `.` (`Json.Bool`), a name the file declares itself (a variant `Bool(…)`, `type Bytes`), `extends String` and any other use are left and listed (`LEFT <path>:<line> <why>`); string contents never (a host's `Array.from`), a `//` / `///` comment's code spans only, a `////` line never; `.bp` files in place, `--zig` the `\\` blocks and the one-line `"…"` literals that hold a `fn` / `val` / `var` / `import` (`codegen/js/`, the parser's and the formatter's tests skipped), `--check` lists each file and its count (`scripts/codemod/primitive_names.py libs/std conformance modules`; `--zig modules`; the libraries rerun it over their own trees — a type spelt inside a string, `t.startsWith("Array<")`, is theirs to respell)
│   └── syntax_modifier.py       ← decision 616's migration: the parameter modifier `expr` → `syntax` (`expr decl: unknown` → `syntax decl: unknown`, `expr ..xs: T[]` too); in prose `` `expr` `` / `` `expr decl` `` / `-> expr T` follow, the article agreeing; `.bp`, `.md`, `.sh` and `.snap` in place, a `.zig` file's modifier only; `--check` lists each file and its count (`scripts/codemod/syntax_modifier.py libs conformance modules`)
├── lib/
│   ├── gate-mode.sh   ← which gate a checkout runs (`front/*` → step, anything else → full) and what a changed-file list reaches, from the backend partition (sourced by gate.sh; run directly it explains a branch and a file list)
│   ├── pool.sh        ← the bounded worker pool the shell runners share (sourced by ../conformance/run.sh), and `pool_share`, a stage's part of the gate's one total of jobs (sourced by gate.sh)
│   └── backend-partition-audit.js ← audits codegen/backend-partition.txt (decision 249): a listed file used by a file of another target fails the gate (stage 3 of gate.sh)
└── git-hooks/
    ├── pre-commit                 ← tracked hook, enabled by `git config core.hooksPath scripts/git-hooks` (see ../AGENTS.md §Local gate)
    ├── pre-merge-commit           ← the same gate for a merge that commits by itself (git runs this hook there, not pre-commit)
    └── lib/
        ├── format-staged.sh       ← `formatStaged`: `botopink format` applied to the commit's staged source files, into the index (decision 524; pre-commit only)
        └── runner-standalone.sh   ← the hook's runner → `gate.sh --staged --no-conformance`
```

## Installers — contract

Both scripts produce the **same** on-disk layout (see
[`modules/bpmp/AGENTS.md`](../modules/bpmp/AGENTS.md) §Storage layout):

```text
$BPMP_HOME/                                  # default: $HOME/.bpmp / %USERPROFILE%\.bpmp
├── bin/bpmp                                 # shim (symlink or copy)
└── botopink/versions/
    ├── <version>/{botopink, botopink-lsp, bpmp}
    └── stable                               # symlink → <version>
```

### Asset URLs they consume

```text
https://github.com/botopink/botopink-lang/releases/latest/download/<file>
https://github.com/botopink/botopink-lang/releases/download/<tag>/<file>
```

`<file>` is `<binary>-<version>-<target>.<ext>` plus a `.sha256` sidecar (single
line, 64 hex chars), matching `release-pack.sh` output. `<binary>` is one of
`botopink`, `botopink-lsp`, `bpmp`; `<ext>` is `tar.gz`
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

**Portability.** Every script runs under macOS's bash 3.2: a variable followed by a non-ASCII byte
is written braced (`${lib}·${target}`) — bash 3.2 reads the first byte of `·` as part of the name
under `set -u` (`lib\xc2: unbound variable`, the former `test-libs.sh` on macos-14). macOS's `xargs` is BSD's:
it drops an empty argument even under `-0`, so a NUL-separated record fed to `xargs -0 -n <k>`
never holds an empty field — `conformance/run.sh` pads `run_one`'s unused 4th field with `-`
(an empty one shifted every later group: `commonJS: command not found` on macos-14). A stock macOS has no GNU `timeout`: the runners call `with_timeout` (`scripts/lib/pool.sh` — `timeout`, else `gtimeout`, else perl's alarm), never `timeout` directly.
macOS's `awk` is BWK awk: a comparison inside an unparenthesized `print`/`printf` argument list is a
syntax error there (`printf "%s", n == 1 ? "" : "s"` — gawk accepts it), so the ternary is
parenthesized. Its `sed` and `grep` know no
`\x1b`-style escape (an ESC is `$(printf '\033')`), and `sed` takes `-E`, never GNU's `-r`; `sed -i`
always carries a suffix (`-i.bak`). `scripts/macos-sim.sh <command>` runs a command on Linux with
bash 3.2.57, BWK awk (`nawk`), BSD xargs' empty-argument drop, no GNU-only tool on PATH, the GNU-only
flags above refused, and a `TMPDIR` reached through a symbolic link with a trailing `/` — run a
stage under it before a change to a script lands.

## gate.sh

`scripts/gate.sh [--cold] [--staged] [--stage <name>]… [--prebuilt] [--portable]` — one ordered run (the STEP gate on a `front/*`
branch, the FULL gate everywhere else — § Step gate and full gate), stopping at the first
failing stage (stages 4b–12 run side by side and are reported in this order —
§ Where the gate's time goes): staged-file checks (`--staged`: conflict markers, `zig fmt
--check` on staged `.zig`, no staged `*.snap.new` / `*.snap.md.new` candidate) and, every run,
`zig fmt --check modules` (a `.zig` file red anywhere fails the gate, staged or not — the
whole-tree check is the stage; the staged one is a commit's fast path), then the
`erl` on PATH against the release the compiler emits for (decision 228: `OTP_RELEASE`,
read from `modules/manifest/src/root.zig` because nothing is built yet — another release,
or an `erl` that does not answer, stops the gate there with the compiler's message,
`` botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it
on PATH ``), `zig build -Doptimize=ReleaseSafe` (§ Build mode), the backend partition audit
(`lib/backend-partition-audit.js`), `zig build test` (`--cold` deletes
`modules/compiler-core/.botopinkbuild/runtime-cache` first, and every
`.botopinkbuild/cache/` under this checkout and each sibling library repository
— the code cache of the dependencies' compiled modules, the cell durations,
decision 225 — printing `gate: --cold deleted <dir>` for each, and passes
`--cold` to stages 8 and 9, § Warm and cold),
`zig build test-bpmp`, `scripts/beam_export_audit.sh`, `zig build test-cli`, `zig build test-conformance`
(`conformance/`, a red cell fails it; every package of `botopink packages --list` tested there, one program per
package per target — decision 996 took the libraries' stage into it, `conformance/AGENTS.md`), `zig build test-docs`
(`check-docs.sh`), `scripts/tsc-check.sh` (§ tsc-check.sh), `zig build test-web` (compiler-core for wasm32 and `modules/compiler-web/tests/smoke.js` under node, default build mode — CI's step, in the gate by decision 231). CI (`.github/workflows/test.yml`) runs the same stages, in the same build mode (decision 226), minus the
staged checks. The pre-commit hook runs `--staged`; the run
that decides a merge adds `--cold`. After the staged checks the script unsets
every `git rev-parse --local-env-vars` variable a hook inherits (`GIT_DIR`,
`GIT_INDEX_FILE`, …): a stage that runs `git` in a scratch repository (bpmp's
install tests) would otherwise act on the committing repository.

**Stages by name (decision 987).** `gate.sh --list-stages` prints the stage names in the order the
gate runs them (`fmt otp build backend-partition test test-bpmp beam-export-audit test-cli
test-conformance test-docs tsc-check test-web`; `--uses-binaries` prints the ones that run the
installed binaries); `--list-rows` prints CI's rows (decision 1004 (2)) — `<stage>`, or `<stage>
<target>` once per target for a stage split by target (`PER_TARGET_STAGES`: `test-conformance` on
commonJS, erlang, beam and wasm) —, `--uses-binaries` again narrowing them; `--stage <name>`
(repeatable) runs only those, in the gate's order, and never reads or writes the green-tree record;
`--target <t>` (repeatable) narrows the stages split by target to those targets (on the step gate, to
those the step also reaches); no `--stage` runs every stage as before. `--prebuilt`
says `zig-out/bin` is already built (a CI job that downloaded it): the stages that run the
binaries pass `-Dprebuilt=true` to `zig build` (build.zig leaves the install step out of
`test-cli`, `test-conformance` and `test-docs`), so nothing recompiles the compiler.
`--test-shards <N>` makes the `test` stage run `zig build test -Dtest-shards=<N>` (build.zig's default is the CPUs, at most 8); CI's unit job passes 8 on its 4-CPU runners, the suite mostly waiting on node / erl / wasmtime.

`--portable` builds for the baseline CPU (`-Dcpu=baseline` on every `zig build` of the gate): CI builds the
binaries on one runner and runs them on others, where a native build dies of SIGILL (exit 132). The
conformance stage's command is spelled once, in `gate.sh`'s `conformance_cmd`; the CI workflow
(`.github/workflows/test.yml`) only calls `gate.sh --cold --stage <name> [--target <t>]`, one job per row of
`--list-rows`, and keeps no list.

### tsc-check.sh

`scripts/tsc-check.sh [<project>…]` builds the library the compiler ships
(`libs/std/` — decision 326: the shared libraries are repositories of their
own, checked by their own gates), query's consumer cell
(`../query/conformance/modules/generic_loader_binding`, the sibling checkout's), every conformance cell (`conformance/modules/<cell>/`, each a project with its own
manifest, decision 475) and every `conformance/test/<project>/` with `botopink build --target commonJS
--typescript` into a scratch directory and runs `tsc --noEmit --strict --lib
es2022 --module commonjs` over each build's non-empty `.d.ts` files, one `tsc`
per project, (a `conformance/test/<project>/` that holds `test/` alone, as `botopink test` reads it, is built from a scratch copy whose `src/` is that `test/`) and `node --check` over each build's `.js` files (in parallel, one
`node` per file) — the run cells execute their module under node, this reaches
the modules nothing runs: the libraries' and the example's. A cell is left out
only structurally — its commonJS answer refuses a module (a `refused` record in
`snapshot/targets/commonJS/`, or in `snapshot/output/` with no commonJS departure
of its own) or its manifest's `"targets"` list has no `commonJS` — and a project that does not
build, or emits no `.d.ts` or no `.js`, is red; no `node` on `PATH` is a
refusal. `tsc` is
`npx -p typescript@<TS_VERSION>` (pinned in the script, so the verdict is a
function of the tree); no `npx` on `PATH` is a refusal, never a skip (decision
67). A planted typedef defect (`array<number>` for a `pub val` of an array)
reds `pub_val_across_modules` and `pub_val_in_a_test`; the `libs/` rows were
added after std's `testing/snapshots.d.ts` named the undeclared prelude record
`SourceLocation` (6 × `TS2304`) with no stage to see it — the six libraries
cost ~1.5 s of the stage's ~12 s. A planted host template that is not
JavaScript (`#[@external(.JavaScript("($0 +* 1"))]`) reds its project with node's
`SyntaxError` and the file. Since every cell has its own manifest (144 B-29 step H) the walk
reaches the former single-file cells too: 474 projects and 854 modules, every one accepted.

### Build mode

The binaries stages 4b–12 run are built `-Doptimize=ReleaseSafe`, the
mode `release.yml` ships: the gate runs the compiler a user installs. Every
`zig build` the gate starts passes the same `$opt`, so no stage reinstalls a
Debug `zig-out/bin/*` over the one the others are running; stage 4's unit-test
binaries are built in Debug, as before (`zig build test` installs nothing).
ReleaseSafe keeps every runtime safety check — bounds, overflow,
`unreachable`, `std.debug.assert`; what it leaves out is Debug's allocator,
whose leak report never changed an exit status (`std/start.zig`). The same
cell prints the same bytes under both modes; a Debug compiler spends ~12× the
CPU on it (a `rakun-stylesheet` erlang cell: 189 CPU-s against 15), and stages 8 and
9 are thousands of compiles. After a gate `zig-out/bin/` holds ReleaseSafe
binaries; a plain `zig build` puts Debug ones back.

### Stage times, the plan, the budget

Every stage's `✓` line ends with its wall clock and CPU-seconds —
`✓ zig build test-conformance — 3m41s wall, 2210 CPU-s` — measured with bash's
`time` keyword around the stage (the CPU of every child it waited for
included). Before stages 4b–12 start, `conformance/run.sh --list` (the libraries'
`libraries/<name>` jobs among them, one per name of `botopink packages --list` per target)
and `scripts/check-docs.sh --list` print the plan of stages 9 and 10, and after each its own
tally is held to its plan: `cells: <J> jobs — …, <A> audits` of the language
tests against the job lines, `docs: <N> references` against the reference lines. A
stage that ran fewer than its plan fails the gate, green or not — a stage
cannot be narrowed to win time. The last line is the total,
`gate: every stage passed — 4m52s wall, 2120 CPU-s (budget 7m30s)`,
timed from the gate's start (the gate keeps no lock, § No gate lock), against
`budget=450` at the top of the script — for 16 idle cores, 7m30s for this
milestone by decision 265 (the 5-minute target is deferred to the next
milestone). A run over it prints `gate: over budget`
in yellow with the load, and is not a red: a slow or shared machine is not a
broken tree.

### Warm and cold

Decision 510: no test result is cached. Every cell of stages 8 and 9 runs on every run — no
verdict is stored, none is answered from a store, and `conformance/run.sh` takes neither
`--cold` nor `--store-root`. `gate.sh --cold` deletes the runtime
cache and every `.botopinkbuild/cache/` (the erlang verdicts, the `.beam` cache, the cell
durations), naming each, so the run that decides a landing builds from nothing; it passes
nothing to the stages. A gate is made fast by the code cache of its dependencies (decision 509)
and by running only what a change reaches (below), never by skipping a run.

**The backend partition** (decision 249). The files the compiler is built from (the set
`modules/source-stamp/src/root.zig` hashes) partitioned by backend in ONE list,
[`../modules/compiler-core/src/codegen/backend-partition.txt`](../modules/compiler-core/src/codegen/backend-partition.txt):
a file listed under a target belongs to that target alone, every other file
(lexer, parser, checker, comptime and its runtimes, the preludes, the embedded
std and bundled packages, the CLI, the runners, `build.zig`, the list itself) is
shared. A file the list does not name is shared, so a new emitter file reaches
everything until it is listed. A job that compiles for no target (`reject/`, a
doc fence: `botopink check`) reaches every target's files. Editing `codegen/wat.zig`
reaches the wasm cells and the `check` jobs; editing `comptime/infer.zig` reaches
everything. The erlang target owns no file: `codegen/erlang.zig` lowers every
comptime body on every target, so it is shared (the list says why for each
emitter file it leaves shared). The list is audited on every gate run
(`lib/backend-partition-audit.js`, stage 3) — a listed file imported and used by a
file that is neither listed under the same target nor the list's `dispatcher`
(`codegen.zig`) fails the gate. The full gate runs everything at every landing, so a
wrong line can delay a red to the landing, never land one.

### No gate lock, one total of jobs

Decisions 468, 469, 508 (front 144 B-29 step J). **This gate keeps no lock and no
pool**: any number of runs, from any checkout or worktree, start at once and never
wait. Scheduling a machine's gates is the meta repository's `scripts/gate.sh` (its
pool of tokens, `gate.sh run`); the commit hook's `--no-conformance` run goes free,
outside it. What the gate offers that scheduler is `--jobs <N>` (a positive count,
the libraries' gate flag; default the machine's, `pool_default_jobs`), the run's
one total, split among the side-by-side stages by § One job budget, and
`--no-conformance`, the commit hook's gate — never a verdict.

### Step gate and full gate

Decision 460 (front 144 B-29 step G). **The branch decides the mode, structurally**
(decision 67): `gate.sh` reads the current branch and nothing else. There is no flag,
variable or file a commit sets that turns a check off, and no `--full`. The one flag that
narrows a run is `--no-conformance` (decision 470, below). The first line
of the run names the mode and why:

```text
gate: step gate (branch front/x): reaches wasm only; test-conformance on wasm
gate: step gate (branch front/x): reaches every backend (shared file: modules/compiler-core/src/comptime/infer.zig)
gate: full gate (branch feat): every stage, every cell, every library
gate: full gate (detached HEAD): every stage, every cell, every library
```

| Branch | Mode | What runs |
|---|---|---|
| `front/*` | step gate | every stage of the full gate; only the cells of stage 9 (`test-conformance`, the libraries included) are the step's reach |
| `feat`, `main`, a detached HEAD, any other branch | full gate | every stage, every cell, every library |

**The reach** is computed by `scripts/lib/gate-mode.sh` from the step's change: the
working tree against the merge-base with `origin/feat` (committed, staged, unstaged
and untracked files; renames count both paths), so a step gate covers the whole step,
not its last commit. Each file is mapped by
`modules/compiler-core/src/codegen/backend-partition.txt` (decision 249):

- listed under `commonJS`, `wasm` or `beam` → that target alone. A change that lists
  several files reaches the union of their targets (`--target wasm,beam` for
  `conformance/run.sh`).
- a `*.md` outside `tests/` and `libs/` → nothing: `modules/source-stamp` leaves every
  `*.md` out of every cell key. A change of only such files runs no cell (stages 8 and 9
  print `skipped by the step gate`); `test-docs` and every other stage still run.
- anything else → every cell, as today: the dispatcher (`codegen.zig`), the checker,
  comptime, the lexer/parser, std and the bundled libs (`libs/`), the preludes, the CLI,
  the runners, `build.zig`, the scripts, a snapshot, a `tests/` cell, a file the
  partition does not list (`codegen/erlang.zig` … — the partition's header says why
  the `erlang` target has no file of its own) and the partition file itself.
- no changed file to measure, or no `origin/feat` ref → every cell. The doubt goes to
  the wider run.

The libraries run inside stage 9, on its targets (decision 996). The `--list` plans that hold stages 9 and 10 to
their counts (§ Stage times, the plan, the budget) are read with the same `--target`, so
a narrowed stage is held to its narrowed plan (the root package's runs on the reached targets,
its one build before them); the restriction audits stay in every plan. Every stage that is not a cell set — formatting,
the OTP release, the build, the backend partition audit, `zig build test`, `test-bpmp`,
the beam export audit, `test-cli`, `test-docs`, `tsc-check`, `test-web` — runs in both
modes. Only the full gate writes the green-tree record (§ Green-tree record): a step
gate ran a subset, and a later `--staged` run on `feat` over the same bytes must not
skip stages because of it.

**`--no-conformance` is the hook's gate** (decision 470). The commit hook
(`git-hooks/lib/runner-standalone.sh`, for `pre-commit` and `pre-merge-commit`) runs
`gate.sh --staged --no-conformance`: the mode is still the branch's (a `front/*` branch
is the step gate), but the conformance stage — stage 9, `test-conformance` — does not
run, and the run prints `gate: conformance not run (--no-conformance)` after the mode
line. Every other stage runs as without the flag (`test-docs` checks the reference's
references and runs no cell, so it stays in the hook's gate). A `--no-conformance` run never writes the
green-tree record and is never a full gate; a run without the flag behaves exactly as
before. The conformance cells run in a front's Conformance step and at its landing
(below), and the GitHub pipeline re-checks with conformance after the push.

**A front's Conformance step and its landing run `gate.sh` WITH conformance** (no flag,
the default) — the FULL gate, and on a `front/*` branch there is no way to ask for
that, by design. The coordinator runs it on the main
checkout at a detached HEAD of the commit (the same script, a different checkout):

```sh
cd <main checkout>/repository/botopink-lang
git fetch <front worktree> front/<name> && git checkout --detach FETCH_HEAD   # or: git checkout --detach <commit>
scripts/gate.sh --cold          # "gate: full gate (detached HEAD): …"
```

and lands it on `feat` (a `feat` commit or merge runs the full gate again through the
hook). A front lands whole: the step gates of its steps are not evidence for the landing.

**Measured** (before 144 B-29 step H, when stage 9 ran `tests/language/` one job per cell and
target; 2026-10-11, one clone of this tree, a
`wat.zig` first-line comment as the only change; the library repositories' stores were
shared and warm, so `test-libs` numbers understate the cold cost; a second gate from
another thread began mid-way in the full run, load 7–14):

| Run | Stages 8 / 9 | Wall |
|---|---|---|
| step gate, branch `front/measure` — `reaches wasm only` | `test-libs` skipped (no commonJS/erlang cell); `test-conformance` 927 of 2715 jobs (523 wasm + 404 `reject/` `*` jobs; 19 audits) | 4m32s (load < 2 at start) |
| full gate, detached HEAD, same change | `test-libs` 164 jobs (5m40s), `test-conformance` 2715 jobs (7m21s) | 10m20s |
| step gate reaching every backend (this commit: `scripts/gate.sh` is shared) | the full cell sets | 10m00s |

**Measured, the hook's gate** (before 144 B-29 step H; 2026-10-11, `gate.sh --staged --no-conformance` on a
`front/*` branch; one fresh clone with a cold
`zig build`, load 5–16 from other threads' gates, the wait for their lock not counted;
`test-libs` ran against the shared, warm library stores):

| Change | Reach | Stages 8 / 9 | Wall |
|---|---|---|---|
| a comment in `codegen/wat.zig` | `wasm` only | `test-libs` skipped; `test-conformance` not run (`--no-conformance`) | 4m20s (`zig build` 3m12s, `zig build test` 34s, `test-cli` 1m07s) |
| a comment in `codegen.zig` (the dispatcher) | every backend | `test-libs` 164 jobs, 5m04s; `test-conformance` not run | 7m59s (`zig build` 2m53s, `test-cli` 3m20s under load) |

No stage, cell or check of the full gate is dropped and no verdict changed: the full
gate's plans and counts are the ones `--list` printed before.

### Green-tree record

`tree_key` hashes what a gate reads: this checkout's working tree and every
sibling library checkout the libraries' conformance jobs reach (`<checkout root>/repository/*`),
each as `git write-tree` would record it with every change added (a scratch
index seeded from the real one, so unchanged files are not re-read), plus
`zig version`, the OTP release and `node --version`. A gate that passes writes
the key it started from to `$(git rev-parse --git-path botopink-gate-green)` —
only when the key is the same at the end, so nothing moved under the run. A
`--staged` run (a commit, a merge) whose key was recorded green runs stage 1
and stops: nothing its diff can affect is left that a gate did not already run
on the same bytes and toolchain. Any other difference runs the whole gate, and
`--cold` never reads the record.

### Where the gate's time goes

The stages stay one ordered REPORT — the first failing stage in the order above
is the one reported, with the output and exit status the one-at-a-time gate
printed. Stages 1–4 still run one after the other, each only after the cheaper
ones passed. Stages 4b–12 only read what 2–4 built, and write their own scratch,
so they run side by side (`gate.sh` § side by side): each stage's stdout and
stderr are captured to one file, and once all of them have finished the blocks
are printed in stage order up to and including the first red one, whose failure
line ends the run with exit 1 — the stages after it are not printed, as the
serial gate never ran them. A red stage among 4b–12 therefore no longer saves the
time of the stages after it; that is the cost of a red run, never of a green
one. The time is otherwise saved inside the stages, by doing the same work once
and on every CPU, never by running less:

| Stage | What makes it fast | Where |
|---|---|---|
| `zig build test` | the compiler-core suite runs as `-Dtest-shards` processes (default: CPUs, at most 8), each the tests whose index is its own modulo the count; every test runs once and is reported by name, the summary's count is the unsharded one. The default runner is serial inside a process and the suite mostly waits on the node/erl/wasmtime its RUN LOGs spawn | [`../modules/test-shard/AGENTS.md`](../modules/test-shard/AGENTS.md) |
| `botopink test --target erlang` | `botopink test --target erlang` compiles each `.erl` of a run once (`precompileErlang`), not once per test module that loads it; the host-sidecar shipper resolves each library and probes each qualifier once per run | [`../modules/compiler-cli/src/cli/AGENTS.md`](../modules/compiler-cli/src/cli/AGENTS.md) (`test_cmd.zig`, `libs.zig`) |
| every stage that runs `botopink` | the binaries are ReleaseSafe (§ Build mode): ~12× less CPU per compile than Debug, the same output | § Build mode |
| tests that build fixtures | a test's scratch directory (`BOTOPINK_TEST_TMPDIR`) is the run directory's sibling, so no erlang runner compiles and loads the fixture projects a build test wrote (rakun-scheduling: ~6 500 `.erl` per test module); `botopink build --target erlang` answers a source the same OTP compiler already accepted from its verdict cache (rakun's build tests: 22 builds of one closure per cell) | [`../modules/compiler-cli/src/cli/AGENTS.md`](../modules/compiler-cli/src/cli/AGENTS.md) (`test_cmd.zig`, `build.zig`) |
| `test-conformance` | the root package built once into one `.bpr` (decision 990 (6)), then jobs (one target's run of the `.bpr`; a test suite on one target) run on `lib/pool.sh` — the former library runner's rule (one per CPU, bounded by `MemAvailable / 768 MiB`, each job admitted only while `procs_running` ≤ CPUs); verdicts are written one file per job and sorted before the report, so the output is byte for byte what `--jobs 1` prints. It used to be `--jobs 4` with no admission; measured under the usual shared load, 28.8 s → 18.3 s at +12 % CPU-seconds | [`../conformance/run.sh`](../conformance/run.sh) § parallel jobs |
| `test-docs` | since 144 B-29 step I it compiles nothing: every example of the reference is a conformance cell, and the stage only checks that each reference names one (it was a `botopink check` per fence on `lib/pool.sh`, 8.5 s → 1.5 s) | § check-docs.sh below |

### One job budget (gate.sh § job budget)

The side-by-side stages used to size one pool each to the whole machine: three
pools of about 16 jobs on 16 CPUs, load 4.7 rising to 26 in a cold gate. Now
`gate.sh` takes its total from `--jobs <N>` or else reads `pool_budget_jobs` once, after the build (at most one per CPU,
the largest whose estimated peak fits `MemAvailable` minus a 3 GiB reserve and the uncounted `test-web` and `test-cli`;
144 B-129 — the old `MemAvailable / 768 MiB` bound let ~10 `test-libs` jobs of 1–3.5 GiB run beside test-web's 7 GiB wasm
compile, and the hook alone took a 31 GB machine to 0–1 GB available), and passes each stage its share through the flag it
already had: `test-conformance` 80 % (`-- --jobs N`; the libraries' stage is part of it since decision 996, so its per-job figure is a library's, 3700 MiB),
`tsc-check.sh` 10 % (`--jobs N`, new, default unchanged) and `test-web` `-j`
10 %, at least 1 each (`pool_share` of `lib/pool.sh`) — 12 / 1 / 1 on 16 CPUs.
`modules/compiler-cli/tests/cli_contract.sh` holds the shares, the `--jobs` refusals and
`lib/gate-mode.sh`'s answers (§ Step gate and full gate) to their contract. `test-docs` had 5 % until 144
B-29 step I; it reads files and takes no share. The shares follow the stages' measured CPU-seconds. Each runner keeps its
own `procs_running` admission; no report changes. `zig build test` already runs
beside the ReleaseSafe build (§ ahead of the build): it finishes in 1m55 inside
the build's 3m10, with `MemAvailable` never below 10 GB of 30 GB, so it adds
nothing to the head.

**Only the stages this invocation runs are counted** (decision 1004 P0). `pool_budget_for` (`lib/pool.sh`) takes the
`--stage` names: with none, the whole gate's budget as above (`test-web` 7700 MiB + `test-cli` 3500 MiB as `budget_web_mib` /
`budget_cli_mib`); with `--stage`, the 11.2 GiB of those two is counted only for the one(s) named, and the pool
stages split 100 % among the pool stages named (`test-conformance` alone is 100 %, a stage not named costs nothing). Before this, a
CI job running one stage on a 16 GB runner still counted both fixed stages and ran at `job budget 1`. `cli_contract.sh` prints the
budget of a whole gate and of `--stage test-conformance` / `test-cli` on a 14 GiB / 4-CPU runner
and asserts each stage runs at least 3.

Measured on the 16-core / 30 GB machine, one cold gate alone, fresh
`.zig-cache`, load below 3 at start:

| Stage | Before: wall, CPU-s | After (8 / 4 / 1 / 1): wall, CPU-s |
|---|---|---|
| `zig build` ReleaseSafe | 3m17, 820 | 3m09, 819 |
| `zig build test` (beside the build) | 1m52 after it, cold | 1m53, 331 (hidden by the build) |
| `test-cli` | 4m42, 273 | 3m47, 261 |
| `test-libs` | 8m21, 2540 | 5m34, 1938 |
| `test-conformance` | 9m02, 1468 | 7m12, 1019 |
| `test-docs` | 23s | 32.6s, 28 |
| `tsc-check` | 55s | 55s, 47 |
| `test-web` | 1m10 | 1m11, 66 |
| whole gate | 12m27, 5680 | 10m24, 4616 (a second cold run: 10m36, 4665, every stage within 3 %) |

Finding: load still peaks near 28 (`procs_running` up to 60) with only 14 jobs,
because a job is about two runnable threads (a `botopink test` child plus its
spinning `erl`/`node`), not one. Halving the budget to 8 jobs (4 / 3 / 1 / 1)
ran green but slower, 10m46, `test-libs` 7m30 being the pole; a 6 / 6 split
turned two rakun timing tests red (`rakun·erlang` over max-connections 503,
`rakun-messaging·erlang` dlq) under the load. The wall is still over the 7m30
cold budget: `test-conformance` with 4 jobs is the pole and the remaining gain is
a work-conserving share (a token directory every runner reads), not a better
split.

`zig build` in stage 2 builds every binary the later stages run; `zig build
test-conformance` and `test-docs` re-enter the build graph, find it
up to date and run the installed `zig-out/bin/*`, so no stage rebuilds one.
Measured numbers, before and after, are in the meta workspace's
`specs/00-compiler-carry-over/11-tooling/README.md` § The gate's speed
and, per stage and per step, `specs/1.0.10-beta/00-compiler-carry-over/25-gate-perf/README.md`
§ Measurements.

## lib/pool.sh

Sourced, never run. The one statement of the pool rule for the shell runners —
the former library runner's:
`pool_default_jobs` (one per CPU, bounded by `MemAvailable / 768 MiB`, at
least 1), `pool_budget_jobs` (the gate's one total, bounded by the stages' measured peak memory; pure arithmetic over
its arguments, held by `cli_contract.sh`; the measured peaks and the `budget_*_mib` constants are in `gate.sh` § job
budget), `pool_check_jobs` (a `--jobs` value must be a positive count),
`pool_admit <dir>` (while a job of this run is in flight — a file in `<dir>` —
wait until `procs_running` ≤ CPUs; a run with nothing in flight is always
admitted) and `pool_job <dir> <cmd…>` (admit, mark, run, unmark). A caller runs
its jobs with `xargs -P "$jobs" bash -c '… pool_job …'` after `export -f` of
what they call, and makes its output independent of completion order — one
file per job, printed in its own order afterwards — which is what lets
`--jobs 1` and the default print the same bytes. bash 3.2 clean.

## lib/backend-partition-audit.js

Run by `node`, never sourced: `node scripts/lib/backend-partition-audit.js [--root <checkout>]`.
Reads the compiler's source set from `modules/source-stamp/src/root.zig` (`ROOTS`, `SKIP_DIRS`)
and `modules/compiler-core/src/codegen/backend-partition.txt`, and exits 1 naming the first
fault: a line that is not `<target> <path>`, a path listed twice, a name that is no target, a
listed file or `dispatcher` that is not a compiler source, or a listed file imported **and used**
by a `.zig` that is neither listed under the same target nor the dispatcher (`_ = @import(…)` is
not a use). `gate.sh` runs it as stage 3; the step gate's reach (`lib/gate-mode.sh`) and the code
cache's fingerprint trust the list because of it.

## codemod-import-without-from.py

Decision 206 (1.0.11-beta `01-compiler/129-import-without-from`): `from "<name>"`
names a package — std, a bundled package or a declared dependency — and a
module of the importing package is imported by its path inside the braces.
The script rewrites every import whose `from` named a module of its own
package, over any number of trees at once:

```sh
python3 scripts/codemod-import-without-from.py [--write] [--shorthand] [--format <botopink>] <root>...
```

- **`--shorthand` (decision 337).** Rewrites the shorthand instead: an import
  with no `from` whose item's first segment names no module of the package
  (`import {splitPath};`) gets the path of the one module of the package (its
  `src/` tree, plus the flat `test/` suite for a test file) that declares the
  name `pub` — the fix `shorthand-import` writes. Two declarers, or none, is
  `UNDECIDED`; a package whose directory holds a `*.expect` naming
  `shorthand-import` is left alone.

- **What it rewrites.** `import {a, b as c} from "x.y";` → `import {x.y.a, x.y.b as c};`
  (`x/y` → `x.y`), every leaf behind its dotted path — the spelling `botopink
  format` prints (the formatter flattens a group, so a group is never the
  canonical form); a brace list carrying a comment is kept verbatim inside one
  group per path segment instead. Nothing outside the import changes.
- **Which import names a module of the package.** A package is a
  `botopink.json` that is not a workspace, or a test's fixture project (a
  `src/` of `*.bp.fixture` sources whose manifest the test writes, rakun's
  `test/fixtures/<name>/`); its modules are its `src` tree (`x/mod.bp` is
  `x`), plus the flat `test/` suite for a test file. The source
  names a module by its full path, else by a last segment only one module
  has; it is the package's when that module exports every item (`pub fn` /
  `val` / `var` / `type` / `behavior` / `mod` / `implement` / `extend`, or a
  submodule for the namespace form). Otherwise a source whose first segment
  is a bundled or declared package keeps its `from` (it names the package),
  and anything else is printed `UNDECIDED` and left for a hand edit — a
  decorator-emitted name, or an item that resolved through the whole program
  to another module. A package directory holding a `*.expect` that names
  `module-import-with-from` (the language suite's cell pinning the refusal) is
  not touched.
- **Formatting.** With `--format`, each file it changed that `botopink format
  --check` accepted before is formatted after, so the trees stay canonical.
- **Output.** One `rewrite` line per import, one `UNDECIDED` line per import it
  left, and the tally; exit 1 when anything is undecided. Without `--write` it
  only reports.

A script and not a `botopink` subcommand: the old form is refused by the
compiler, whose diagnostic already writes the fix for one import
(`error[module-import-with-from]`); a subcommand would keep a reading of the
retired spelling inside the CLI for good, which decision 67 refuses. The script
migrates the seven repositories once and needs no build.

## codemod-component-contexts.py

Decision 354 (1.0.12-beta `01-compiler/134` step 6): `@Component<R>` is the one wrapper —
decision 128's base parameter is gone — a component's `R` implements the marker
`@Renderable` (the owner marker `@Context<C>` left), and `@getContext(T)` gave way to
contexts (`use provide` / `use context`). The script migrates a tree:

```sh
python3 scripts/codemod-component-contexts.py [--write] [--format <botopink>] [--ext <.ext>]... <root>...
```

- **`@Component<C, R>` → `@Component<R>`** — the second argument kept whatever it nests
  (`#(…)`, `fn(…) -> T`, generics; a `->` closes nothing), folded onto one line (a line
  broken inside a `//` comment included); a `@Component` of one argument is left alone.
- **`@Context<C>` → `@Renderable`**, in an `implement` clause or anywhere else.
- **`use @getContext(T)` is reported** `UNDECIDED <file>:<line>` (outside `//` prose) and the
  run exits 1: which component provides the context is the author's.
- Textual, over code, comments and string literals alike (a reflected return type compared
  as text is the same spelling). It reads `.bp`, `.d.bp` and `.bp.fixture` files, plus each
  `--ext` (`.md`, `.zig`, `.ts` for docs, the compiler's tests, the VS Code grammar tests);
  a `CHANGELOG.md` records the past and is not a target.
- With `--format`, each `.bp` / `.d.bp` it changed that `format --check` accepted before
  is formatted after. Without `--write` it only reports.

## git-hooks/

`git-hooks/pre-commit` is self-contained. It first sources `git-hooks/lib/format-staged.sh`
and runs `formatStaged` — `botopink format` applied to the commit (decision 524; § format-staged.sh
below) — then sources `git-hooks/lib/runner-standalone.sh`, which runs `gate.sh --staged
--no-conformance` of the committing checkout. `git-hooks/pre-merge-commit` runs the same gate, and
formats nothing (each side's blobs were formatted when they were committed): `git merge`
runs `pre-merge-commit`, **not** `pre-commit`, when a merge needs no conflict
resolution and records its commit itself, so without it an auto-merge was
never gated unless its author amended it (a merge that stops on a conflict is
committed with `git commit`, which runs `pre-commit`). Nothing installs them; a
clone enables both with `git config core.hooksPath scripts/git-hooks` (the
relative path resolves against the checkout's root, so every worktree runs its
own tracked hooks).

### format-staged.sh

`botopink format` is applied, never checked (decision 524, amending 66): no stage of `gate.sh`
fails on a file that is not canonical, and the commit hook formats what the commit records.
`formatStaged` formats **the version entering the commit** and never pulls in an unstaged change:

1. the staged source files (`git diff --cached --diff-filter=ACMR` over `*.bp`, `*.bpp`,
   `*.botopink` — `.d.bp` included) are checked out of the index (`git checkout-index --prefix`)
   into a scratch tree, with the `snapshot/output/` files of every directory above them;
2. `botopink format .` walks the scratch tree — the walk of the checkout, so decision 67's
   structural exemptions hold there too (a hidden directory, `node_modules`, a conformance cell's
   module whose `snapshot/output/<module>.snap` holds a `refused` record);
3. a staged file the formatter changed is written as a blob (`git hash-object -w`) and replaces
   the staged one in the index (`git update-index --cacheinfo`, its mode kept) — the committing
   index, `GIT_INDEX_FILE`, so `git commit -a` and `git commit <path>` are formatted too (under
   `git commit <path>` the real index git writes beside the committed one, `index.lock`, takes the
   blob as well, so the index matches the commit);
4. the working-tree file takes the formatted text only when it holds exactly the staged text; a
   file with unstaged changes keeps them, untouched, and the commit records the formatted staged
   version.

The formatter is this checkout's own build (`zig build -Doptimize=ReleaseSafe`, the gate's stage 2,
which the gate then finds cached), so a commit that changes the printer formats its sources with the
printer it commits. A file the formatter cannot parse is committed as written, its diagnostic
printed; a build that fails formats nothing (the gate's stage 2 then reports it). Nothing is built
when no source file is staged. A reformat moves what quotes the text it moves: `libs/std`'s source
is quoted verbatim by the `std_package_*` codegen snapshots and by two LSP snapshots
(`definition_std_module_member`, `completion_array_methods`), and a cell's `.snap` pins an
`at <file>:<L>:<C>` — write such a file formatted (`botopink format <file>`) before recording
what quotes it. `git commit --no-verify` skips the formatting with the gate.

## check-docs.sh

`scripts/check-docs.sh [--doc <file>]… [--list] [--self-test]` (`zig build test-docs`, the gate's
stage 10; decisions 461, 462) — every example of the language reference names a conformance cell.
The reference (`../conformance/docs.md`) holds no example of its own: an example is a line
`<!-- example: modules/<cell> -->` or `<!-- example: test/<suite> -->`, alone on its line, its path
relative to `conformance/`, and what it answers is the cell's, checked by `test-conformance`. The
docs checked are `conformance/docs.md`, every `conformance/modules/*/docs.md` and `README.md`
(`--doc` replaces the list):

| Line | Verdict |
|---|---|
| `<!-- example: modules/<cell> -->` | `conformance/modules/<cell>/` holds `botopink.json` and `src/main.bp`, or the line fails: `names no cell`; and a `docs.md` that is not empty — the reference text the cell shows (decision 462) —, or it fails: `names a cell whose docs.md is empty or missing` |
| `<!-- example: test/<suite> -->` | `conformance/test/<suite>` is a `.bp` file or a directory holding `botopink.json`, or the line fails: `names no suite` |
| a ```` ```botopink ```` fence | fails: a program in the reference is a cell; a table, a grammar or a layout sample is ```` ```text ```` |
| a line opening with `<!-- docs-check:` | fails: the directive of the inline fences this script compiled until 144 B-29 step I |
| a line opening with `<!-- example:` in another shape | fails |

Every failure is printed `✗ <doc>:<line> <why>`; the exit line is `docs: <N> references — <M>
missing, <F> refused lines`, and § Stage times holds `N` to the lines `--list` prints
(`<doc>:<line>\t<path>`, one per reference). Every run starts with the harness's own contract — a
synthetic suite and doc whose seven lines get known verdicts (a reference to a cell that exists ✓, to
one that does not ✗, to a cell whose `docs.md` is empty ✗, to a suite ✓, a ```` ```botopink ```` fence ✗, a `docs-check` line ✗, an
`example:` line with no path ✗); a verdict that differs fails the run before the docs are judged, and
`--self-test` runs only it. The script reads files and runs no compiler, so it takes no `--jobs`. bash 3.2 clean.

## check-test-scratch.sh

`scripts/check-test-scratch.sh [<dir>…]` (default `modules`), a dependency of
`zig build test` — **a test may not spell a cwd-anchored scratch path.**

Each test binary runs with its package directory as cwd, so the whole suite
writes into one shared checkout: a path that is fixed (scoped per test name but
not per run) is shared with every other process running the suite, and each
test empties its own root on the way in. Measured before the rule existed: one
`modules/compiler-cli` test binary is 89/89 green, four concurrent copies red
1–5 tests each (`cli.config.workspaceRefusal … FileNotFound`,
`cli.format_cmd decision 66 … expected 5, found 0`, and so on).

The one way to name such a path is the `test_scratch` module
([`../modules/test-scratch/AGENTS.md`](../modules/test-scratch/AGENTS.md)),
whose root carries a per-process segment. This script is the other half: it
walks every `<dir>/**/*.zig`, tracks `test` blocks (a top-level `test "`/`test {`
until the next column-0 `}`) and refuses a string literal that **begins**
`.botopinkbuild` inside one — and **anywhere** in a file under a `tests/`
directory, which is test-only as a whole: the harness helpers a test calls are
functions outside every `test` block, and that is how the build roots of
`codegen/tests/helpers.zig` and `comptime/tests/helpers.zig` and the eval roots
of `language-server/src/tests/helpers.zig` escaped the block-only scan (they are
`test_scratch` paths now).

It refuses, it does not warn, and no flag or environment variable turns it off
(decision 67). The only exemption is structural: a literal that does not start
at the cwd — `"…/.botopinkbuild/tmp/scratch.bp"` as fixture *content* under a
scratch root, or a reference to a production constant such as
`runtime.TMP_ROOT` — is not a cwd-anchored path and is not matched.

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
| `review`   | The review worksheet, `suite\tslug\ttest\tpaths\tverdict`, one row per unique snapshot: codegen per target, comptime per directory (`comptime/{ast,errors,templates}` — one file per slug since the layout dedup). `test` is the test `file:line` from the trace (comma-joined when several tests write the same path — a slug collision); a snapshot traced without a location falls back to the test-source string literal that names it (the LSP asserts take a literal slug); `ORPHAN` when no test checked it. `verdict` is seeded from the 1.0.1-beta review reports (`--reports=<dir>`, default `../../specs/1.0.1-beta/06-snapshot-review` from the bot-lang root): every table row whose `verdict` column — located by its header cell, never by index — names the slug, restricted to the row's backend cell, as `<verdict> [report:line]`; `-` when no report names it. Report rows with a verdict that name no snapshot on disk (renamed or deleted tests, tests without a snapshot, harness-level rows) go to `review-unmatched.tsv`. Exits 3 when a row has no test `file:line`. |

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

`scripts/comptime_bench.sh [--n LIST] [--repeat R] [--target T] [--project DIR]… [--keep]
[--no-build]` — the measurement
[`specs/1.0.12-beta/01-compiler/14-comptime-on-beam/`](../../../specs/1.0.12-beta/01-compiler/14-comptime-on-beam/README.md)
step 2 is held to, and whose table `18-comptime-runtimes` step 3 records, re-measured on the
reader's machine instead of quoted. Not a gate stage: it builds projects for tens of seconds.

| Instrument | What it measures |
| ---------- | ---------------- |
| E-1 | wall clock of one `botopink build`, best of `--repeat`, over a generated project with N call sites of **one** template whose literals are all distinct — so the memo cache in `comptime/infer.zig` never hits and each call site is a real evaluation — and the marginal ms per evaluation between consecutive N. |
| E-2 | the in-compiler split: one more build of the largest N (and of each `--project`), not one of the timed ones, with `BOTOPINK_COMPTIME_STAGES=<file>` (`modules/compiler-core/src/comptime/runtime/stages.zig`); one row per stage — runs, total, and ms per evaluation (an evaluation is one `module` line) — in the order an evaluation meets them: `memo_key`, `module`, `encode`, `lower`, `instance` / `run`, `listing`, `outcome`, then `TOTAL`. |

`--target` picks the build target (default `commonJS`); every target evaluates on the wasm comptime
runtime (decision 434), and none needs `erl` to compile. Every
project is generated or copied into a `mktemp -d` (deleted unless `--keep`): the script writes
nothing inside a repository. `--project DIR` copies a real project out of its checkout and builds it
there — a workspace member (a `{ "workspace": true }` dependency) is built inside a copy of its
enclosing workspace, and refused when no ancestor `botopink.json` declares `workspaces`;
`BOTOPINK_LIB_ROOTS` is inherited, which is how a project whose libraries live in a sibling
checkout resolves them.

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

## codemod-wasm-cells.py

Decision 481 (144 B-33): `.Wasm`'s cells are labelled arguments, each value of the kind it
names, and the prefixed strings are refused on every target. The script rewrites a tree:

```sh
python3 scripts/codemod-wasm-cells.py [--write] [--ext <.ext>]... <root>...
```

- `#[@external(.Wasm("fn:tanBody"))]` → `#[@external(.Wasm(body: tanBody))]`, `"op:f64.floor"` →
  `op: "f64.floor"`, `"wasi:race_of"` → `wasi: .RaceOf`, `"std:hash.contentHash"` →
  `std: "hash.contentHash"`; a `host:` beside the cell stays.
- Textual, over code and comments alike (`.Wasm("fn:…")` in prose becomes
  `.Wasm(body: …)`). It reads `.bp`, `.d.bp` and `.bp.fixture` files, plus each `--ext`;
  a root may be a file. A `CHANGELOG.md` is not a target.
- One `rewrite <file>: <n>` line per file and the count per root; without `--write` it only
  reports (a library's count before its own commit).

## codemod-optional-operators.py

Decision 330 (1.0.12-beta `01-checker` step 31): `?T` has no methods — its surface
is `??`, `?.`, `?.[]`, `?.()` and the postfix `!` — and the builtin `result`
namespace goes. The script migrates a tree before the refusals reach it:

```sh
python3 scripts/codemod-optional-operators.py [--write] [--once] [--compiler <botopink>] <root>...
```

- **`result.<op>(r, …)` → `r.<op>(…)`**, textually (`then` → `flatMap`, `unwrap` →
  `unwrapOr`; `result.map` only with two arguments; a `//` line is prose and
  left alone).
- **Which `.unwrapOr` reads a `?T` is the compiler's answer.** It runs `botopink
  check` in every project under each root (a `botopink.json` that is not a
  bare workspace) and rewrites the sites the compiler names:
  `optional-has-no-methods` on `unwrapOr` → `recv ?? d` (the default
  parenthesised when it holds an operator, the whole parenthesised beside a
  postfix link, a prefix `!` / `-`, `&&` / `||`); on `map` / `flatMap` whose
  lambda only projects its parameter (`x.map({ v -> v.name })`) → `x?.name`;
  `optional-operator-never-null` → the operator dropped (`a ?? b` is `a`, `a?.f`
  is `a.f`, `a!` is `a`). It repeats until the compiler names nothing it can
  rewrite (one error per module per run); the column is the compiler's, in
  bytes. Anything else is printed `UNDECIDED <file>:<line>:<col> <what>` and the
  run exits 1.
- **`--once`** stops after one compiler pass — std's sources are embedded in
  the compiler, so its sites move only when the compiler is rebuilt.
- The formatter (`<botopink> format`) is run over every file it changed that `format --check` left
  alone before the first rewrite; a file that was not canonical keeps its layout, so the diff is the
  rewrite.

## codemod-conformance-cells.py

144 B-29 step H's migration of the old `tests/language/` suite into `conformance/` (decisions 457,
466, 475), rerunnable over a copy of the old tree (`git archive <rev> tests/language | tar -x -C
<dir>` from a revision that still holds it):

```sh
scripts/codemod-conformance-cells.py migrate --from <dir>/tests/language --to conformance
botopink cell check conformance/modules           # writes a candidate for every refusal placeholder
scripts/codemod-conformance-cells.py accept  --from <dir>/tests/language --to conformance
scripts/codemod-conformance-cells.py audit   --from <dir>/tests/language --to conformance [--cells <ledger.tsv>]
```

`migrate` writes each `run/`, `reject/` and `modules/` cell as `conformance/modules/<cell>/` (its
`botopink.json` — the old manifest, or `{ "name": "<cell>", … }` with `"targets"` from a
`.targets` —, `src/`, an empty `docs.md`, and `snapshot/`), and each `test/` suite under
`conformance/test/`. Everything a sidecar states exactly is written exactly (`.out` /
`expected.out` → `out` and `no-final-newline`, `.exit` → `abort`, `.<t>.stderr` → `stderr`); a
refusal claim named only a part of the message, so it is written as a placeholder (`refused
<the claimed text>`, `at <the claimed place>`) that `botopink cell check` answers with a candidate.
`accept` renames a candidate over its snapshot only when every old claim of every target that reads
it still holds (a `refused` line containing the claimed text at the claimed place, the target
printing nothing); a candidate that changes an output is never accepted, it is a red for a person.
It then folds departures every target shares into `output/`. `audit` counts every old claim by kind
and checks each one against the new snapshots — the answer a target reads — exiting 1 on a claim no
record states. Measured on the migration: 381 `.out`, 23 `.exit`, 76 `run` `<t>.expect`, 50
`<t>.stderr`, 19 `.targets`, 405 `reject` `.expect`, 106 `expected.out`, 166 `modules` `<t>.expect`
and 1 manifest `"targets"` — every claim stated (1825 `out`, 86 `abort`, 242 per-target refusals,
1620 `reject` refusals over four targets, 50 `stderr`, 20 narrowings, 73 test suites byte for
byte).

## consolidate-cells.py

144 B-157's mapping of the cells into modules (decision 765), `plan` and `verify` only; nothing moves.

```sh
scripts/consolidate-cells.py plan [--allow-unslugged]
scripts/consolidate-cells.py verify --base <ref>
python3 scripts/consolidate-cells-test.py
```

`plan` homes each cell: (a) a ledger row whose text names it (`modules/<cell>` or `` `<cell>` ``), else (b) the
decisions its `////` header cites (a number or step spelling counts only when that row is a code-bearing row of
`decisions-taken.md`; a one-liner is followed to the row in force), else (c) outside, under the first `_` segment
of its name. Several rows: the highest-numbered code-bearing one is the home, the others "proved also by". (t)
`conformance/modules/consolidate-homes.txt` overrides all of it for the cells it lists — `<cell> <row> [also
<row>,<row>]` per line, `outside` as the row for a cell that proves none it cites; the one pass over the ambiguity
list writes it (765 (2)), a line only where the default is wrong; a row that is no slugged code-bearing row, or an
unknown cell, is refused, every line listed; `plan` and `apply` read it alike. It writes
`conformance/modules/INDEX.md` and `INDEX.ambiguous` (git-ignored scratch, never committed) and refuses, listing
them, while a code-bearing row has no `Cell` slug, unless `--allow-unslugged` (those rows' cells go outside).
`verify` compares the tree with a base commit: cell count, `.snap` files per output and target, record counts per
kind, manifests with `"targets"`, the multiset of (path inside the cell, sha256) over `src/`, `deps/`, `snapshot/`,
`botopink.json` and `docs.md`, and the `<!-- example:` count; exit 1 on any difference, 0 on the unchanged tree.

## codemod/compiler_keyword.py

144 B-136's migration of a tree to decisions 575 (4), (5) and 576 (6), source to source, over the
`.bp` files under each path (`builtins.d.bp`, `builtins_fns.d.bp` and `compiler.bp` of std are written
by hand and skipped):

```sh
python3 scripts/codemod/compiler_keyword.py [--check] [--measure] [--format <botopink>] [--imports] <path>...
python3 scripts/codemod/test_compiler_keyword.py
```

- **A parameter typed `@Expr<T>`** becomes `comptime x: T` when its body reads it as `x.value` and
  otherwise only fails at it (each read dropped; `x is type` counts as a value read; an unread one is
  `comptime` too), else `expr x: T`. `x.text()` →
  `compiler.text(x)`, `x.fail(m)` → `compiler.fail(m, at: x)`, `x.failAt(s, m)` → `compiler.fail(m, at:
  x, span: s)`, the template model `x.<m>(…)` (`source`, `context`, `lookup`, `bindings`; `x.parts()` is UNDECIDED, 577 (5) removed it)
  → `compiler.<m>(x, …)`, `x.build` / `note` / `tagDecl` / `annotate(…)` → `compiler.<m>(…)` (576 (2)), `return x.custom(ast, code);` →
  `compiler.custom(ast); return code;`.
- **A parameter typed `@Decl`** becomes `expr d: unknown` (`@Decl<T>` → `expr d: T`); `d.name` →
  `compiler.name(d)!`, `d.<r>` → `compiler.<r>(d)` (`module` → `moduleOf`), `d.meta(T)` →
  `compiler.meta<T>(d)`, the outputs `d.setMeta` / `addMeta` / `addMember` / `addType` / `wrapWith(…)` →
  `compiler.<m>(…)`, `d.addType(name, src)` → `compiler.addType(name, compiler.buildType(src))` (578
  (3)). The string `setMeta("key", value)` is left and counted. The same rules take a
  local bound from `x.lookup` / `tagDecl` / `annotate(…)` or from `d.owner`, and `d.owner!.<r>`; the
  elements of `methods`, `params`, `annotations`, `hooks` and `fields` are records and stay.
- A plain parameter `x: @Decl` / `@Decl<T>` / `Decl` (a helper taking a handle) → `x: unknown`.
- `@expr(v)` → `v`; `-> @Expr<T>` and `-> @ExprCustom<T>` → `-> T` (578); a record field `f: @Expr<T>`
  → `f: T`; `type T` in a type → `type<T>`; a bare `type` in a type → `anytype` (`type<T>`, `type(`,
  `type {` stay).
- **Decision 578:** a function declared `-> @Expr<…>` / `-> @ExprCustom<…>` whose first parameter
  (after a `self` receiver) is `@Expr<string>` is a template: that parameter becomes `expr q: string`
  whatever the body reads, a `q.value` read `compiler.text(q)`. B-136's interim `-> expr T` → `-> T`,
  its `comptime q: string` text parameter → `expr q: string` with each read `compiler.text(q)`.
- **Decision 577:** a call of a template (a function whose first parameter, after a `self` receiver,
  is `expr q: string`, in the same project — a cell with its `deps/`, std; `recv.name` for a
  template method; the name a package's default import binds when that package's `default fn` is a template) written `name "…"`, `name """…"""`,
  `name("lit")`, `#[name("lit")]` or `#[name "…"]` → `` name @`…` `` / `` #[name @`…`] ``, the
  string's escapes resolved to raw bytes (a backtick written `` \` ``), `${…}` kept as written. Any
  other call shape is printed `TEMPLATE-CALL`; a function declared `-> @Expr` that is no template by
  578 (1) `TEMPLATE-SIGNATURE`. The refusal cell `expr_call_outside_expr` keeps its call shape.
- **Decision 576 (13), with `--imports` only** (off by default; B-136's removal piece runs it): a file naming `Span`, `Part`, `Source`, `ExprContext`, `CustomNode`,
  `DeclKind`, `HookNode`, `Field`, `Method`, `Param` or `DeclAnnotation` (and not declaring or
  importing it otherwise) gains `import {compiler.<Name>} from "std";` — merged into its first `from
  "std"` import; in std itself `import {compiler.<Name>};`.
- The cells `removed_type_bare_param` and `expr_param_method` are skipped (refusal tests of the
  removed spellings). Comments and string contents are never rewritten (a `${…}`
  hole is code).
- What it cannot decide is printed `UNDECIDED <file>:<line> <what>` (a `.value` read on an `expr`
  parameter, a `custom(…)` that is not a whole `return`, a member with no rule) and left as written.
- `--check` writes nothing and exits 1 when a file would change; a second run over its output
  changes nothing. `--format <botopink>` runs that compiler's formatter over each changed file that
  was canonical before, through today's parser (the new spellings written back as `x: @Expr<T>`,
  `-> @Expr<T>`, `type T` for the formatter, and restored after); a file it cannot read keeps the
  codemod's layout and is named `UNFORMATTED`; the template texts, which today's formatter cannot read,
  are written after it ran. `--measure` prints what the run leaves for a person:
  reads with no 576 spelling, `Declared<`, the string `setMeta` sites by decorator and key with their
  readers, `addMeta`, `wrapWith`.
