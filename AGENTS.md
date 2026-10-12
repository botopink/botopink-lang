# botopink-lang · project AGENTS.md

`decisions-taken.md` is generated — from the meta repository's `specs/<milestone>/decisions-taken.md` by `scripts/decisions-split.py`; edit it there, never here.

Guidance for AI agents working on the botopink **language core** — the CLI,
the LSP, the compiler, the lib-test-runner, `bpmp`, and the bundled `std` lib.
The libraries (emilia/erika/jhonstart/onze/rakun) and the VS Code extension are
**siblings** under `repository/` in the meta workspace — see
[`../../AGENTS.md`](../../AGENTS.md) for the workspace overview and worktree
workflow.

> Convention: source, comments, commit messages and docs are in **English**.
> Each directory ships its own `AGENTS.md` — read the closest one first, then
> walk up the tree.

## Project tree

```text
botopink-lang/                 ← language core (this project)
├── AGENTS.md                  ← you are here
├── README.md                  ← public-facing intro
├── build.zig                  ← workspace build graph
├── .github/workflows/         ← test.yml (push/PR) + release.yml (tags)
├── modules/                   ← all Zig packages — see modules/AGENTS.md
│   ├── bpmp/                  ← `bpmp` package + toolchain manager
│   ├── compiler-cli/          ← `botopink` CLI
│   ├── compiler-core/         ← lexer, parser, AST, infer, comptime, codegen
│   ├── compiler-web/          ← the browser build of compiler-core: botopink.wasm + glue.js + the demo page
│   ├── language-server/       ← `botopink-lsp` LSP server
│   ├── lib-test-runner/       ← `botopink-lib-test` (test-libs gate)
│   ├── manifest/              ← the shared `botopink.json` model (std only; imported by the four above)
│   ├── source-stamp/          ← `source_stamp` — a library run refuses a binary older than its checkout's sources
│   ├── std-wasm/              ← botopink's wasm runtime in Zig: std's host functions (bound by `std:` cells) and the Erlang terms with the OTP functions, compiled to `std_wasm.wasm` — a `--target wasm` program's and the comptime runtime's (decisions 434, 440, 450)
│   ├── beam-to-wasm/          ← a standalone utility: any `.beam` set translated to wasm whole, module by module (std + std-wasm only); no part of the compiler or any botopink build (decisions 434, 438, 452)
│   ├── test-scratch/          ← `test_scratch` — per-process scratch paths; the test modules only
│   ├── test-shard/            ← the compiler-core test runner: the suite split across processes (`-Dtest-shards`)
│   └── wasm3/                 ← vendored wasm3 (C): the wat comptime runtime runs on it, in-process
├── libs/                      ← the bundled .bp library — see libs/AGENTS.md
│   └── std/                   ← standard library, the one package the compiler ships (decision 326)
├── examples/                  ← generic-loader-binding alone, waiting to move to erika — see examples/AGENTS.md
├── conformance/               ← the language reference and its conformance suite (decisions 457, 461, 462, 466, 475):
│                                docs.md (the reference, the manifest schema included; every example a cell),
│                                modules/<cell>/ checked by `botopink cell check`, test/ suites by
│                                `botopink test --json` — see conformance/AGENTS.md
└── scripts/                   ← installers, release packing, snapshot audit, git hooks
```

Specs live in the meta workspace (`../../specs/`), not in this repo.

Golden snapshots live inside the owning package (`modules/compiler-core/snapshots/`,
`modules/language-server/snapshots/`) — tests run with the package as cwd.

## Workspace commands

```bash
zig build               # botopink + botopink-lsp + botopink-lib-test + bpmp
zig build test          # compiler-core + language-server + compiler-cli + lib-test-runner + manifest + test-scratch + std-wasm + beam-to-wasm tests
zig build test -Dtest-filter=<name>   # only tests whose name matches
zig build test -Dtest-shards=<n>      # compiler-core as n processes side by side (default: CPUs, at most 8) — modules/test-shard
zig build run           # build and run the CLI
zig build test-cli      # every modules/compiler-cli/tests/*.sh (command contract, test tooling, the wasm core module's --invoke main)
zig build test-libs     # every visible .bp library's tests per backend (libs/ + sibling repository/*)
zig build test-backends # the wasm core module's --invoke main (modules/compiler-cli/tests/backend_exec.sh)
zig build test-closure-invariant # one library built under two consumers, its files compared byte for byte on every target (modules/compiler-cli/tests/closure_invariant.sh, decision 509 (2)); alone — `test-cli` runs it too
zig build test-bpmp     # bpmp unit tests
zig build test-vscode   # VS Code extension unit tests — scripts/test-vscode.sh finds the sibling checkout
zig build test-conformance # the conformance suite (conformance/run.sh: every cell by `botopink cell check`, every test/ suite; `-- --compiler <botopink>` to run another binary)
zig build test-docs     # every example of conformance/docs.md (and each cell's docs.md, README.md) names a conformance cell (scripts/check-docs.sh)
zig build clean-tmp     # reap scratch dirs older than 1 day (also runs before `zig build test`)
zig build gen-unicode   # regenerate libs/std/src/unicode_tables.bp from the pinned Unicode data (libs/std/AGENTS.md § unicode)
zig build std-wasm      # modules/std-wasm → zig-out/lib/std_wasm.wasm, the side module a wasm program and the comptime runtime decode (decisions 440, 450)
zig build compiler-web  # compiler-core for the browser → zig-out/web/ (wasm32-wasi; `-Doptimize=ReleaseSmall` is the shipped size)
zig build test-web      # the browser build's smoke test under node (modules/compiler-web/tests/smoke.js)
```

`zig build test` also runs three greps that refuse rather than warn (decision 67,
no flag turns any off):

- the **lib-agnostic gate** — it fails if `modules/compiler-core/src` names a
  non-std library (`rakun|jhonstart|erika`);
- the **labelled-cells gate** — it fails if a `.bp` under `libs/` writes a
  prefixed binding string (`"fn:…"`, `"op:…"`, `"wasi:…"`): a binding cell is
  the labelled argument `fn: name`, `op: "…"`, `wasi: .X` (decision 305);
- **`scripts/check-test-scratch.sh`** — it fails if a `test` block, or any line
  of a file under a `tests/` directory (the harness helpers), names a
  cwd-anchored `.botopinkbuild` path. Each test binary runs with its package
  directory as cwd, so a fixed path is shared with every other process running
  the suite and the second one deletes the first one's fixtures mid-test (one
  `compiler-cli` test binary is 89/89 green; four concurrent copies were red
  1–5 tests each). The one way to spell such a path is the `test_scratch`
  module — see
  [`modules/test-scratch/AGENTS.md`](modules/test-scratch/AGENTS.md).

Comptime runs on wasm only (decision 434): every target's decorator, template
and `comptime` evaluation runs on the wat runtime, wasm3 inside the compiler, so
compiling spawns no `erl` and building the compiler runs no `erlc`. `erl` / `erlc`
(OTP 28+) are needed for the erlang and beam **targets' own** tests: the codegen
snapshot RUN LOGs and the beam export audit under `zig build test` and the gate,
and `botopink build/run/test --target erlang|beam` (and so `test-cli`,
`test-libs`, `test-conformance`), which needs exactly the release the
compiler emits for — `OTP_RELEASE` in `modules/manifest/src/root.zig`, printed by
`botopink --version` — and refuses any other `erl` on `PATH` (decision 228,
`modules/compiler-cli/src/cli/otp.zig`); codegen snapshot RUN LOGs also use
`node`.

Per-test scratch dirs live under `modules/compiler-core/.botopinkbuild/tmp/<hex>/`
(one root for every `executeJavaScript` / `executeErlang` / `executeBeamAsm`
invocation). See
[`modules/compiler-core/src/codegen/AGENTS.md`](modules/compiler-core/src/codegen/AGENTS.md)
(`runtime.zig` row) for the layout contract. Everything else a test writes goes
under `modules/<pkg>/.botopinkbuild/test-scratch/<id>/` — `<id>` per **process**
— through the `test_scratch` module
([`modules/test-scratch/AGENTS.md`](modules/test-scratch/AGENTS.md)), which is
the only way to name one. `zig build clean-tmp` reaps both at a 1-day TTL.

`test-libs` is the lib ecosystem gate (`botopink-lib-test`): it runs
`botopink test --target <t>` in `libs/std` and in every sibling library the
checkout can see (`<ancestor>/repository/*` of the enclosing checkout — the meta
workspace or a worktree of it, or the repos CI checks out) and in every **member** of a workspace among them (a `botopink.json`
with `"workspaces"`, one row per member, examples included), and reports each cell as pass, FAIL (with the failing module's
diagnostic) or no tests — a library with
no `test` block is still compiled (`botopink build --target <t>`), so it fails
its cell when it does not compile. **A cell that exists is green or the run
fails**: no file lists a red cell away or pins a failed count, and no flag or
environment variable changes a verdict (decision 67). A workspace document that
quotes the tool's member list is checked against the tool, and a stale
`botopink` (its checkout's sources changed since it was built) is refused
before any cell runs.

**The manifest decides the matrix.** A member may exclude a backend with
`"targets"` in its `botopink.json`; an excluded target is not a cell and is
never run. The exclusion is **audited on every run** instead: `botopink build
--target <excluded>` must be refused, its first error the missing host binding
(`has no #[@External.<Target>(…)]`) — the member structurally cannot run there.
A member that builds on the target it excludes, or fails there for any other
reason, fails the run by name ([`scripts/AGENTS.md`](scripts/AGENTS.md)
§ test-libs.sh). `zig build test-libs -- --list` prints the plan — cells and
audits — without running it. `test-libs` is **not** part of `zig build
test` — it needs host runtimes on `PATH`:

| Backend    | Tool                     | Install hint                                     |
| ---------- | ------------------------ | ------------------------------------------------ |
| `commonJS` | `node` ≥ 22              | https://nodejs.org/en/download                   |
| `erlang`   | `escript` (OTP)          | `apt-get install erlang` · `brew install erlang` |
| `beam`     | `escript` + `erlc` (OTP) | same as erlang                                   |
| `wasm`     | `wasmtime`               | `curl https://wasmtime.dev/install.sh \| bash`   |

The `scripts/test-libs.sh` wrapper warns about missing runtimes (advisory — the
runner's per-target skip-or-fail decides) before starting the runner. Forward args via `--`, e.g.
`zig build test-libs -- --target erlang --lib rakun`. See
[`modules/lib-test-runner/AGENTS.md`](modules/lib-test-runner/AGENTS.md).

## AGENTS index

Each directory's `AGENTS.md` owns its tree, file list and conventions; this file
does not mirror them. Entry points:

| Area | Doc |
|---|---|
| Zig packages | [`modules/AGENTS.md`](modules/AGENTS.md) |
| Compiler core (pipeline, stages) | [`modules/compiler-core/AGENTS.md`](modules/compiler-core/AGENTS.md) |
| Codegen backends | [`modules/compiler-core/src/codegen/AGENTS.md`](modules/compiler-core/src/codegen/AGENTS.md) |
| Shared BEAM term layer | [`modules/compiler-core/src/codegen/beam/AGENTS.md`](modules/compiler-core/src/codegen/beam/AGENTS.md) |
| Comptime (infer, templates, decorators) | [`modules/compiler-core/src/comptime/AGENTS.md`](modules/compiler-core/src/comptime/AGENTS.md) |
| Comptime runtime (wasm) | [`modules/compiler-core/src/comptime/runtime/AGENTS.md`](modules/compiler-core/src/comptime/runtime/AGENTS.md) |
| CLI | [`modules/compiler-cli/AGENTS.md`](modules/compiler-cli/AGENTS.md) |
| LSP | [`modules/language-server/AGENTS.md`](modules/language-server/AGENTS.md) |
| bpmp | [`modules/bpmp/AGENTS.md`](modules/bpmp/AGENTS.md) |
| Per-process scratch paths for tests | [`modules/test-scratch/AGENTS.md`](modules/test-scratch/AGENTS.md) |
| `.bp` libraries | [`libs/AGENTS.md`](libs/AGENTS.md) · [`libs/std/AGENTS.md`](libs/std/AGENTS.md) |
| Conformance suite (the language's cells; the former `tests/language` and `examples/`) | [`conformance/AGENTS.md`](conformance/AGENTS.md) |
| Examples (one left, waiting to move to erika) | [`examples/AGENTS.md`](examples/AGENTS.md) |
| Scripts | [`scripts/AGENTS.md`](scripts/AGENTS.md) |
| `.bp` language reference (user-facing) | [`conformance/docs.md`](conformance/docs.md) — every example a cell of `conformance/modules/` |
| `botopink.json` schema (user-facing) | [`conformance/docs.md`](conformance/docs.md) § The manifest schema · model: [`modules/manifest/AGENTS.md`](modules/manifest/AGENTS.md) |

## Release pipeline

| Workflow | Trigger | What |
| --- | --- | --- |
| `.github/workflows/test.yml` | push / PR to `main`, `feat` | job `test`, on ubuntu-22.04 (no macos row), hard: `scripts/gate.sh --cold` — the repository's one gate WITH conformance (decisions 466, 470, 477), every stage it declares; the workflow keeps no list of stages of its own, and a front's Conformance step reads this run. The steps before it install what the gate runs: zig 0.16.0, the compiler's OTP release (decisions 227, 228: a step reads `OTP_RELEASE` from `modules/manifest/src/root.zig`, then `erlef/setup-beam`, then a step that fails the job unless `erl` reports that release), wasmtime, node 22, and every library — emilia/erika/jhonstart/onze/rakun/actions/http/log/routing/validation/css/styled/snap/json/yaml/markdown/dbcontext — at `feat` into `repository/<name>/` for the gate's `test-libs` stage. There is no windows row (1.0.11-beta gate-f: a row that cannot fail measures nothing; it returns hard or not at all). |
| `.github/workflows/release.yml` | tag push `v*` | No Erlang/OTP: building runs no `erlc` (decision 434). 5-target matrix (`linux-{x86_64,aarch64}`, `macos-{x86_64,aarch64}`, `windows-x86_64`) → `scripts/release-pack.sh` writes `dist/<binary>-<tag>-<target>.<ext>` + `.sha256` → `softprops/action-gh-release@v2` uploads to one Release. Prerelease iff the tag contains `-`. |

Asset naming (the contract bpmp and the install scripts rely on):

```text
<binary>-<version>-<target>.<ext>          # tar.gz on POSIX, zip on Windows
<binary>-<version>-<target>.<ext>.sha256   # single 64-hex-char line
```

`<binary>` is one of `botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`;
`release-pack.sh` skips binaries that are missing.

## Manifest

Every project or library carries a `botopink.json` at its root (parsed by
`modules/compiler-cli/src/cli/config.zig`): `name`, `version`, `target`, optional
`entry`, and `dependencies`. Unknown fields are ignored.

`dependencies` accepts two shapes: an array of bare names (`["foo","bar"]`,
resolver-only) or an object (`{ "foo": { "git": "...", "branch": "..." } }`,
optional `rev` / `tag` / `path`). `bpmp install` consumes the object form,
cloning each entry into its store and linking it under
`<project>/.botopinkbuild/deps/<name>`; `botopink.lock` pins each dep to a
commit SHA, and `bpmp install --frozen` fails when a dep has no lockfile entry.
`bpmp link [<checkout>]` writes the same links to a local checkout instead —
`.botopinkbuild/deps/<name>` → `<checkout>/repository/<name>`, nothing cloned, a
dependency with no local repository named and refused (decision 483).

Library resolution (`modules/compiler-cli/src/cli/libs.zig` `dependencyTiers`;
the language server the same): a `git` dependency is looked up tier by tier
(decision 483) — `BOTOPINK_LIB_ROOTS` first, then the project's
`.botopinkbuild/deps/` links (`manifest.depsRoots`: a workspace member's own,
then its workspace root's), and only then, as a fallback, the walk-up roots: for
each ancestor `D` of cwd, `D/repository/botopink-lang/libs`, `D/repository`,
`D/libs` — up to the first `D` that holds `repository/` (the enclosing checkout,
`manifest.isCheckoutRoot`), so a meta worktree under `.tasks/<name>` sees only its
own libraries (decision 143). A link wins over the walk-up; `path` and
`workspace` dependencies resolve as before.
Each loaded module carries its package (`Module.package`); a module is its package plus
its path, so two packages' `theme` modules are two modules to the checker, every backend
and the comptime runtimes (decisions 170, 337 — `compiler-core/src/comptime/AGENTS.md`
§ A module is its package plus its path).

## Conventions

- **Keep AGENTS.md up to date.** Code, layout, or pipeline changes update the
  affected `AGENTS.md` in the same change.
- **The reference is `conformance/docs.md`, and every example in it is a cell**
  (decisions 461, 462): a language feature, its syntax and its refusals are
  written there, and an example is a line `<!-- example: modules/<cell> -->`
  (or `test/<suite>`) naming the conformance cell that shows it — its `src/`
  and its answer on every target, never an inline fence. Beside each cell, its
  `docs.md` quotes the reference text it shows. `zig build test-docs` checks
  that every example names a cell and that no ```` ```botopink ```` fence is
  left inline; a table, a grammar or a layout sample is fenced as ```` ```text ````.
  `README.md` keeps the tool's own documentation (install, commands, layout) and
  links the reference. A doc claim that the compiler does not yet honour belongs
  in the reference's "Decided, not yet implemented" table, with the front that
  closes it — never as an example whose cell is not green.
- **A behaviour change carries its cells** (decision 458): a step that adds,
  changes or refuses observable behaviour writes the cells that prove it under
  `conformance/modules/<cell>/` (`botopink cell new`, then `botopink cell
  check`; a person renames each candidate it writes, never a flag), red on the
  parent and green on the step. A cell's answer is never edited to match the
  compiler (`conformance/AGENTS.md`).
- **English only** for source, comments, commits and compiler docs.
- **One fact, one source.** Each fact lives in a single file; others link to it.
- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an
  allocator — it is passed as `alloc: std.mem.Allocator` to the method that
  needs it.
- Type annotations use `TypeRef` (`named`, `array`, `tuple_`, `optional`,
  `function`, `generic`). Generic types use the `is_builtin` flag to distinguish
  `@Result<D, E>` (builtin) from `MyType<T>` (user).
- The surface declares a record-shaped or enum-shaped `type` and a `behavior`;
  the shorthand and long-form spellings map to the same AST nodes, which keep
  their historical internal names (`record`, `enum`, `interface`).
- Formatter must be round-trip stable: `format(parse(src))` re-parses to an
  equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across cycles.

## Open handoffs to the sibling libraries

A rule this repository implements whose other half belongs to a library under
`repository/` in the meta workspace. Written here because the core cannot land
it and must not silently wait for it.

- **`Element` carries its base type** — decisions 96, 102, 118 and 128 of 1.0.10-beta.
  `@Context<Base>` is the owner marker (one parameter); a hook is
  `fn … -> @Component<Base, T>` and a component `fn … -> @Component<Base, Element>`
  (the return is the effect — there is no annotation; the base is always
  written). The checker holds the rule that **every `use` in one function
  resolves against the same base**.

## Local gate

**[`scripts/gate.sh`](scripts/gate.sh) is the one gate — the commit hook's, CI's
and a person's** (decisions 466, 470, 477). The commit hook runs it as
`scripts/gate.sh --staged --no-conformance`: every stage but the conformance cells
(`conformance/`). The GitHub pipeline (`.github/workflows/test.yml`) runs
`scripts/gate.sh --cold` WITH conformance on every push to `feat`, and a front's
Conformance step reads that run; conformance runs locally only to reproduce a red
it reports. Its stages — 1–4 one after the other, 4b–12 side by side and reported
in this order, the first red one ending the run (`scripts/AGENTS.md` § Where the
gate's time goes):

1. `--staged`: conflict markers and `zig fmt --check` on staged files, and a staged snapshot candidate (`*.snap.new`, `*.snap.md.new` — `git add -f` gets past `.gitignore`) is refused; then, on every run, `zig fmt --check modules` — a `.zig` file red anywhere in the tree fails the gate, staged or not;
2. `zig build -Doptimize=ReleaseSafe` — the mode `release.yml` ships, and the binaries every later stage runs (every `zig build` of the gate passes the same flag; stage 4's unit tests stay Debug);
3. `scripts/format-check.sh` (`botopink format --check` over the compiler's canonical `.bp` trees — decision 66's caller; `TREES` in the script names them, and every tracked `.bp` is under one or structurally exempt);
4. `zig build test` (compiler-core, language-server, CLI and lib-test-runner unit suites; `--cold` deletes `modules/compiler-core/.botopinkbuild/runtime-cache` and every `.botopinkbuild/cache/` of this checkout and each sibling library repository first, naming each — required for the run that decides a merge);
5. `zig build test-bpmp` (the package manager's unit suite);
6. `scripts/beam_export_audit.sh` (every beam snapshot module assembles with every function exported);
7. `zig build test-cli` (the CLI contract, test tooling and the wasm core module's `--invoke main`);
8. `zig build test-libs` (every visible library on the targets its manifest declares — a cell that exists is green or the stage fails; a library without tests is still compiled; every target a `"targets"` list excludes is audited, and an exclusion that is not structural fails the stage);
9. `zig build test-conformance` (the conformance suite, `conformance/`: every cell of `conformance/modules/` by `botopink cell check` on every target its manifest declares — its answers against `snapshot/output/` and `snapshot/targets/<t>/`, every `"targets"` narrowing audited against the compiler's host-binding refusal — and every `conformance/test/` suite by `botopink test --json` on commonJS, erlang and beam, after the runner's own `--self-test`);
10. `zig build test-docs` (every `<!-- example: … -->` of `conformance/docs.md`, of each cell's `docs.md` and of `README.md` names a conformance cell or suite, and no ```` ```botopink ```` fence is left inline — `scripts/check-docs.sh`);
11. `scripts/tsc-check.sh` (every `.d.ts` a commonJS build of `libs/std` — the one package the compiler ships —, the example projects, every conformance cell whose commonJS answer compiles and every `conformance/test/` project emits passes `tsc --noEmit --strict`, typescript pinned, through `npx`, and every `.js` it emits passes `node --check`).

**Step gate and full gate** (decision 460). The branch decides, never a flag or a
variable (decision 67): on a `front/*` branch `gate.sh` runs the STEP gate — every
stage, but the cells of `test-libs` and `test-conformance` are only those the step's
change reaches by the backend partition (a change in one backend's files runs that
target's cells; a change in any shared file, std included, runs every cell); on
`feat`, `main`, a detached HEAD or any other branch it runs the FULL gate. The first
line printed says which and why. **The hook's gate is without conformance**
(decision 470): `scripts/git-hooks/lib/runner-standalone.sh` runs `scripts/gate.sh
--staged --no-conformance`, which skips the conformance stage (`test-conformance`)
and prints `gate: conformance not run (--no-conformance)`; every other stage runs as
the branch's mode says, and such a run never writes the green-tree record. A front's
Conformance step and its landing run `scripts/gate.sh` WITH conformance (the default,
no flag) on the main checkout at a detached HEAD of the commit (`scripts/gate.sh
--cold` there); a front lands whole, and the GitHub pipeline re-checks with
conformance after (`scripts/AGENTS.md` § Step gate and full gate).

The side-by-side stages share one job budget: `gate.sh` computes it once
(CPUs bounded by memory) and hands each stage its share through its `--jobs`
flag — `test-libs` 50 %, `test-conformance` 30 %, `tsc-check` 10 %,
`test-web` `-j` 10 % (`scripts/AGENTS.md` § One job budget).

No test result is cached (decision 510): every cell of stages 8 and 9 runs on every
run; `--cold` only deletes the caches the compiler builds from (`scripts/AGENTS.md`
§ Warm and cold). The backend partition (decision 249,
`modules/compiler-core/src/codegen/backend-partition.txt`) decides what a step gate
runs, and `scripts/lib/backend-partition-audit.js` audits it on every gate run. The
budget is 7m30s (decision 265 — the 5-minute target is deferred to the next
milestone).

One gate with conformance runs at a time per machine: a second one waits for
the lock, naming the holder's pid, checkout and start time; a `--no-conformance`
run (the commit hook's) takes no lock (decision 508). A `--staged` run whose
working tree, sibling libraries and toolchain were already gated green runs
stage 1 only (`scripts/AGENTS.md` § Green-tree record).

`scripts/git-hooks/pre-commit` is the tracked pre-commit hook, self-contained in
every checkout (standalone clone or meta submodule): it sources
`scripts/git-hooks/lib/runner-standalone.sh`, which runs `scripts/gate.sh
--staged --no-conformance`. `scripts/git-hooks/pre-merge-commit` runs the same for a merge that
commits by itself — git runs that hook there, not `pre-commit`, so an
auto-merge used to be ungated. Enable both once per clone:

```sh
git config core.hooksPath scripts/git-hooks
```

The setting lives in the repository's shared config, and the relative path
resolves against the committing checkout's root, so every worktree runs the
hook its own tree tracks. It is enabled in the maintainer's botopink-lang
clone. The gate needs `node` (with the `npx` it ships), `erl`/`erlc`/`escript` and `wasmtime` on `PATH`.
Do not use `--no-verify`.

## Debugging tips & gotchas

### The comptime runtime (`comptime/runtime/`)

- **One runtime, wasm, in-process** (decision 434): a comptime module is the
  Erlang text `codegen/erlang.zig`'s untyped mode writes, parsed, lowered to
  wasm and linked into std-wasm's term library (`comptime/runtime/wat/`,
  `modules/std-wasm`, decoded from `std_wasm.wasm` once per process), run on
  wasm3 (`persistent_wat.zig`). No child process, no pipe, no file; a runaway
  body is a runaway wasm3 call on the compiler's thread (limit 1 of
  `comptime/runtime/AGENTS.md` § Limits) — wrap manual runs in `timeout`.
- **A body's `io:format`** goes to a buffer in the module's own memory, never to
  the compiler's stdout.
- **Host functions** reached at build answer by std-wasm (`modules/std-wasm`) —
  the function their `@External.Wasm(std: "…")` cell names (decision 440) —, else
  their `@External.Wasm(fn: …)` cell (`comptime/host_cells.zig`); none is
  refused (`comptime-host-cell-unavailable`). An `@External.Erlang` cell never
  runs at build, and compiler-core imports nothing of `modules/beam-to-wasm`
  (decision 452).

### Comptime specialization (`comptime/transform.zig`)

- **`extractComptimeLiteral` only handles literal nodes.** A comptime param
  receiving an identifier (`scale(2, base)`) takes the non-specialized branch;
  `base` is folded to a literal in Phase 2, so specialization only triggers for
  direct literal arguments.
- **Phase ordering matters.** Phase 1 scans for specialization, Phase 2 rewrites
  calls and inlines comptime vals, Phase 3 drops fully-specialized functions and
  injects the specialized ones.

### Runtime execution (`codegen/runtime.zig`)

- **Spawns are bounded.** `executeJavaScript`, `executeErlang` and
  `executeBeamAsm` go through `runWithTimeout` (120 s); a timeout yields an empty
  RUN LOG. Every `erl` / `erlc` / `escript` among them first passes the OTP
  release check (`src/otp.zig`, decision 228): on another release the executor
  fails with `error.OtpReleaseRefused`, it does not record an empty RUN LOG. `executeWat` runs `wasmtime` on the module's binary (`GenerateResult.wasm`).
- **Erlang/BEAM early exit.** Both skip `erlc`/`erl` when the generated code has
  no `_botopink_main` or no I/O (`io:format`). If a test unexpectedly spawns erl,
  check for `_botopink_main` or `@print` in the output.
- **Output cache.** Executions are content-keyed and cached under
  `.botopinkbuild/runtime-cache/`. Keys ignore toolchain versions — delete the dir
  after upgrading node/erl.
- **The code cache** (decision 509, `modules/compiler-cli/src/cli/code_cache.zig`).
  `build`, `run`, `test` and `cell check` keep a DEPENDENCY's compiled module —
  the `.beam` of std's or a library's `.erl` (erlang) or `.S` (beam) — in
  `<cache root>/.botopinkbuild/cache/code/`, the workspace root (else the
  project; a cell's, its `conformance/modules/` workspace), by the hash of the
  bytes compiled and the OTP compiler's version, and link it (hard link, else
  copy) into the run's own output; the package under test is compiled every
  time. `--cold` reads nothing and writes what it compiled; `rm -rf
  .botopinkbuild`, `botopink clean` and `gate.sh --cold` delete it, and each job
  reaps one random shard (entries unused for 7 days). The cell durations of `test-libs`
  (`cache/lib-test/`) live beside it; no build cache is outside a
  `.botopinkbuild/`.

### General

- **Stale processes.** Hung tests leave orphan `erl`/`node` processes:
  `pkill -f botopink_comptime_server`. The SIGTERM notice goes to
  `erl.<id>.stderr.log`, not the frame stream: a live compiler's in-flight request
  fails as a transport error and the next one respawns the server.
- **Scratch dirs.** Safe to delete manually: `rm -rf .botopinkbuild/tmp/[0-9a-f]*`
  and `rm -rf modules/*/.botopinkbuild/test-scratch/*` (`zig build clean-tmp`
  does both at a 1-day TTL).
- **Snapshot mismatches** write `<slug>.snap.md.new` next to the snapshot; do not
  commit `.snap.md.new` files.
