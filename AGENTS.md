# botopink-lang · project AGENTS.md

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
├── docs.md                    ← language reference (.bp syntax + semantics); every fence compiles (`zig build test-docs`)
├── docs/                      ← botopink-json.md — the manifest schema (packages, workspaces, the dependency object) — see docs/AGENTS.md
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
│   ├── test-scratch/          ← `test_scratch` — per-process scratch paths; the test modules only
│   └── wasm3/                 ← vendored wasm3 (C): the wat comptime runtime runs on it, in-process
├── libs/                      ← bundled .bp libraries — see libs/AGENTS.md
│   └── std/                   ← standard library
├── examples/                  ← non-framework .bp example programs
├── tests/language/            ← botopink language tests of decision 8 (case, tuples, loop) — see tests/language/AGENTS.md
└── scripts/                   ← installers, release packing, snapshot audit, git hooks
```

Specs live in the meta workspace (`../../specs/`), not in this repo.

Golden snapshots live inside the owning package (`modules/compiler-core/snapshots/`,
`modules/language-server/snapshots/`) — tests run with the package as cwd.

## Workspace commands

```bash
zig build               # botopink + botopink-lsp + botopink-lib-test + bpmp
zig build test          # compiler-core + language-server + compiler-cli + lib-test-runner + manifest + test-scratch tests
zig build test -Dtest-filter=<name>   # only tests whose name matches
zig build run           # build and run the CLI
zig build test-cli      # every modules/compiler-cli/tests/*.sh (command contract, test tooling, recursion, backend parity)
zig build test-libs     # every visible .bp library's tests per backend (libs/ + sibling repository/*)
zig build test-backends # beam/wasm/erlang execution parity (modules/compiler-cli/tests/backend_exec.sh)
zig build test-bpmp     # bpmp unit tests
zig build test-vscode   # VS Code extension unit tests — scripts/test-vscode.sh finds the sibling checkout
zig build test-language # botopink language tests (tests/language/run.sh; `-- --compiler <botopink>` to run another binary)
zig build test-docs     # every `botopink` fence of docs.md/README.md compiles (scripts/check-docs.sh)
zig build clean-tmp     # reap scratch dirs older than 1 day (also runs before `zig build test`)
zig build compiler-web  # compiler-core for the browser → zig-out/web/ (wasm32-wasi; `-Doptimize=ReleaseSmall` is the shipped size)
zig build test-web      # the browser build's smoke test under node (modules/compiler-web/tests/smoke.js)
```

`zig build test` also runs two greps that refuse rather than warn (decision 67,
no flag turns either off):

- the **lib-agnostic gate** — it fails if `modules/compiler-core/src` names a
  non-std library (`rakun|jhonstart|erika`);
- **`scripts/check-test-scratch.sh`** — it fails if a `test` block names a
  cwd-anchored `.botopinkbuild` path. Each test binary runs with its package
  directory as cwd, so a fixed path is shared with every other process running
  the suite and the second one deletes the first one's fixtures mid-test (one
  `compiler-cli` test binary is 89/89 green; four concurrent copies were red
  1–5 tests each). The one way to spell such a path is the `test_scratch`
  module — see
  [`modules/test-scratch/AGENTS.md`](modules/test-scratch/AGENTS.md).

Comptime evaluation spawns a persistent `erl`, so `erl` (OTP 28+, decision 86's
floor) must be on `PATH` for `zig build test`; codegen snapshot RUN LOGs also use
`node`. `erlc` is a dependency of **`zig build` itself** (decision 83): it compiles
the comptime node's three resident modules once per source change and the
`.beam`s are embedded in the compiler, so a machine that only *runs* `botopink`
needs `erl` and never `erlc` — and a machine (or CI runner) that builds it needs
`erlc` on `PATH`, or the build stops at `run erlc`.

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
checkout can see (`<ancestor>/repository/*` — the meta workspace, or the repos CI
checks out) and in every **member** of a workspace among them (a `botopink.json`
with `"workspaces"`, one row per member, examples included), and reports each cell as pass, FAIL (with the failing module's
diagnostic), known red, restricted, skipped (with the reason) or no tests — a library with
no `test` block is still compiled (`botopink build --target <t>`), so it fails
its cell when it does not compile. A cell listed in
[`scripts/known-red-libs.txt`](scripts/known-red-libs.txt) is named with its
owning front and does not fail the run; an unlisted failure does, and so does a
listed cell that passes (delete its line).

A member may exclude a backend with `"targets"` in its `botopink.json`. That
used to make the cell invisible — skipped, `~`, failing nothing even under
`--strict`. It no longer can: the wrapper passes `--include-unsupported`, so
every restricted cell **runs**, and its failed-test count is pinned in
[`scripts/restricted-targets.txt`](scripts/restricted-targets.txt), strict in
both directions — an unlisted restriction fails, a line whose member no longer
restricts fails, and a count that moves either way fails. Only the *failed*
count is pinned, so a library adding a green test never has to touch this
repository. It is **not** part of `zig build
test` — it needs host runtimes on `PATH`:

| Backend    | Tool                     | Install hint                                     |
| ---------- | ------------------------ | ------------------------------------------------ |
| `commonJS` | `node` ≥ 20              | https://nodejs.org/en/download                   |
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
| Comptime `erl` runtime | [`modules/compiler-core/src/comptime/runtime/AGENTS.md`](modules/compiler-core/src/comptime/runtime/AGENTS.md) |
| CLI | [`modules/compiler-cli/AGENTS.md`](modules/compiler-cli/AGENTS.md) |
| LSP | [`modules/language-server/AGENTS.md`](modules/language-server/AGENTS.md) |
| bpmp | [`modules/bpmp/AGENTS.md`](modules/bpmp/AGENTS.md) |
| Per-process scratch paths for tests | [`modules/test-scratch/AGENTS.md`](modules/test-scratch/AGENTS.md) |
| `.bp` libraries | [`libs/AGENTS.md`](libs/AGENTS.md) · [`libs/std/AGENTS.md`](libs/std/AGENTS.md) |
| Examples | [`examples/AGENTS.md`](examples/AGENTS.md) |
| Scripts | [`scripts/AGENTS.md`](scripts/AGENTS.md) |
| `.bp` language reference (user-facing) | [`docs.md`](docs.md) |
| `botopink.json` schema (user-facing) | [`docs/botopink-json.md`](docs/botopink-json.md) · model: [`modules/manifest/AGENTS.md`](modules/manifest/AGENTS.md) |

## Release pipeline

| Workflow | Trigger | What |
| --- | --- | --- |
| `.github/workflows/test.yml` | push / PR to `main`, `feat` | job `test`: `zig build test` from a cold runtime cache, then `zig build test-cli`, `zig build test-language` (ubuntu + macos only — it needs `node` and `erl`) and `zig build test-docs`, on ubuntu-22.04 + macos-14 (hard gate) and windows-2022 (allowed to fail; OTP 28 is installed there too, because `zig build` runs `erlc`). Job `libs` (ubuntu, after `test`): checks out emilia/erika/jhonstart/onze/rakun at `feat` into `repository/<name>/` and runs `zig build test-libs` over every runnable target. |
| `.github/workflows/release.yml` | tag push `v*` | 5-target matrix (`linux-{x86_64,aarch64}`, `macos-{x86_64,aarch64}`, `windows-x86_64`) → `scripts/release-pack.sh` writes `dist/<binary>-<tag>-<target>.<ext>` + `.sha256` → `softprops/action-gh-release@v2` uploads to one Release. Prerelease iff the tag contains `-`. |

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

Library resolution (`modules/compiler-cli/src/cli/libs.zig`): roots from
`BOTOPINK_LIB_ROOTS` first, then for each ancestor `D` of cwd:
`D/repository/botopink-lang/libs`, `D/repository`, `D/libs`.

## Conventions

- **Keep AGENTS.md up to date.** Code, layout, or pipeline changes update the
  affected `AGENTS.md` in the same change.
- **`README.md` and `docs.md` stay in sync** with language features, CLI flags
  and syntax. Every ```` ```botopink ```` fence in them is compiled by `zig
  build test-docs`; an HTML comment on the line above the fence says how
  (`<!-- docs-check: body -->` wraps statements in `fn main`,
  `<!-- docs-check: project <name> <path> -->` writes one file of a multi-file
  project, `<!-- docs-check: skip <reason> -->` is the only escape and its
  reason is required and printed). A doc claim that the compiler does not yet
  honour belongs in the reference's "Decided, not yet implemented" table, with
  the front that closes it — never as an uncompiled example.
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
- **The libraries move to the return-is-the-effect surface** — front 24
  (decisions 118–128). The compiler refuses `#[@result]` … `#[@futureGenerator]`,
  `#[@use]`, `@Future`, `@Generator`, `@ResultGenerator`, `@FutureGenerator`,
  `@Use` and `@Iterator<T, E>`; jhonstart, rakun and emilia (and their examples)
  still write them, so their cells are listed in `scripts/known-red-libs.txt`
  under `24-effects-by-return` until each library's sweep (`front/24-libs`,
  `front/24-rakun`) lands and deletes its lines.

## Local gate

**The gate every front runs before landing is `zig build test && zig build
test-libs`**, with `zig build test` from a cold runtime cache. The full ordered
run is [`scripts/gate.sh`](scripts/gate.sh):

1. `--staged`: conflict markers and `zig fmt --check` on staged files;
2. `zig build`;
3. `scripts/format-check.sh` (`botopink format --check` over the compiler's canonical `.bp` trees — decision 66's caller; the trees, and the red ones with their causes, are named in the script);
4. `zig build test` (compiler-core, language-server, CLI and lib-test-runner unit suites; `--cold` deletes `modules/compiler-core/.botopinkbuild/runtime-cache` first — required for the run that decides a merge);
4b. `scripts/snap_audit.sh --mode=runtime-parity` (every codegen snapshot exists under `snapshots/codegen/beam/` and `…/wat/`, and each pair is equal once the `COMPTIME ERLANG`/`COMPTIME WAT` listings are set aside — front 18 step 4, decision 85; no allow-list);
5. `zig build test-bpmp` (the package manager's unit suite);
6. `scripts/beam_export_audit.sh` (every beam snapshot module assembles with every function exported);
7. `zig build test-cli` (the CLI contract, test tooling, recursion and backend execution scripts);
8. `zig build test-libs` (every visible library, known reds named; a library without tests is still compiled; every `"targets"`-restricted cell runs and is checked against `scripts/restricted-targets.txt`);
9. `zig build test-language` (tests/language — decision 8's `case`, tuples and `loop`; expected failures named);
10. `zig build test-docs` (every `botopink` fence of `docs.md` and `README.md` compiles).

`scripts/git-hooks/pre-commit` is the tracked pre-commit hook, self-contained in
every checkout (standalone clone or meta submodule): it sources
`scripts/git-hooks/lib/runner-standalone.sh`, which runs `scripts/gate.sh
--staged`. Enable it once per clone:

```sh
git config core.hooksPath scripts/git-hooks
```

The setting lives in the repository's shared config, and the relative path
resolves against the committing checkout's root, so every worktree runs the
hook its own tree tracks. It is enabled in the maintainer's botopink-lang
clone. The gate needs `node`, `erl`/`erlc`/`escript` and `wasmtime` on `PATH`.
Do not use `--no-verify`.

## Debugging tips & gotchas

### Persistent erl server (`comptime/runtime/persistent_erl.zig`)

Decorator and template bodies run in one long-lived `erl` process speaking
length-prefixed binary frames over stdin/stdout: `cmd 1` = compile+run `.erl`
(one-shot), `cmd 2` = compile+load `.erl` and answer the module atom, `cmd 3` =
call `<module>:main(<external term>)`, `cmd 4` = load `.beam` **bytes** carried
in the frame and answer the module atom (what `codegen/beam/beam_file.zig`
assembles). The evaluators use 2 + 3, so a module is compiled once per
**declaration** and every later call site sends cmd 3 alone with its own
capture. Comptime `val`s are folded in Zig (`comptime/eval.zig`).

- **`file:read/2` on `standard_io` can return a list, not a binary.** `read_frame/0`
  converts with `list_to_binary/1` before matching `<<Len:32/unsigned-big-integer>>`;
  keep that conversion when editing the server, or the server silently treats
  the frame as EOF and the Zig side blocks.
- **stdout is the frame channel only.** The server moves the default logger
  handler to `standard_error` and runs `main/0` with `standard_error` as its
  group leader, so `io:format/1` in a comptime body and a SIGTERM notice go to
  `.botopinkbuild/tmp/persistent_erl/erl.<id>.stderr.log` (write-only, truncated
  at each spawn; `<id>` is 64 random bits per process, so two compilers sharing
  this cwd do not truncate each other's live log). A reply length above `max_frame_len` (16 MiB) fails as
  `error.PersistentErlFrameTooLarge` with a message in `lastTransportError()`.
- **Timeouts.** `main` runs under `EVAL_TIMEOUT_MS` (10 s) inside erl. The
  Zig-side `readFrame` itself blocks without a timeout, so a wedged erl process
  still hangs the caller — wrap manual runs in `timeout`.
- **The three resident modules are embedded `.beam`s, not files** (decision 83).
  The server source is a Zig string (`comptime/runtime/server_source.zig`,
  `botopink_comptime_server`); beside it are the two comptime preludes
  `bp_comptime_template` and `bp_comptime_decorator`
  (`comptime/runtime/prelude.zig`), which carry the host glue every generated
  module used to copy. `zig build` renders the three `.erl` with
  `render_resident.zig` (host target), compiles them with `erlc +deterministic`
  and hands the `.beam`s to compiler-core as anonymous imports;
  `persistent_erl.zig` `@embedFile`s them and the spawn bootstrap
  (`erl -noshell -eval …`) loads them from stdin — one cmd-4 frame each — before
  `start/0` runs. Editing the server or a prelude re-runs `erlc` at the next
  build, nothing else; `.botopinkbuild/tmp/persistent_erl/` holds only
  `erl.<id>.stderr.log`, one per process. A generated module reaches the prelude through `-import`,
  so a missing prelude would be a run-time failure of every comptime
  evaluation, not a compile error. An `erl` below OTP 28 is refused by the
  bootstrap with both releases in the message (`error.PersistentErlBelowFloor`,
  decision 86); a `.beam` the running release cannot load is
  `__BP_ERL_LOAD_ERROR__` — the compiler was built with a newer `erlc` than the
  machine's `erl`.
- **Manual testing.** Frame = `struct.pack('>I', len(payload)) + payload`, payload
  = `b'\x01' + b'/path/to/mod.erl'` for the one-shot path (cmd 2 is the same
  payload with `b'\x02'`, cmd 3 is
  `b'\x03' + struct.pack('>H', len(mod)) + mod + term_to_binary_bytes`, and cmd 4
  is `b'\x04' + struct.pack('>H', len(mod)) + mod + beam_bytes`). Pipe three cmd-4
  frames of the resident `.beam`s (find them under
  `.zig-cache/o/*/resident-beam/`) and then the request into
  `erl -noshell -eval "<bootstrap_eval of persistent_erl.zig>"`; the first reply
  frame is the handshake (`ok`). Never use `-noinput` — it disables stdin reading.

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
  RUN LOG. `executeWat` runs `wasmtime` on the module's binary (`GenerateResult.wasm`).
- **Erlang/BEAM early exit.** Both skip `erlc`/`erl` when the generated code has
  no `_botopink_main` or no I/O (`io:format`). If a test unexpectedly spawns erl,
  check for `_botopink_main` or `@print` in the output.
- **Output cache.** Executions are content-keyed and cached under
  `.botopinkbuild/runtime-cache/`. Keys ignore toolchain versions — delete the dir
  after upgrading node/erl.

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
