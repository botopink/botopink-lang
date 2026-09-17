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
├── docs.md                    ← language reference (.bp syntax + semantics)
├── build.zig                  ← workspace build graph
├── .github/workflows/         ← test.yml (push/PR) + release.yml (tags)
├── modules/                   ← all Zig packages — see modules/AGENTS.md
│   ├── bpmp/                  ← `bpmp` package + toolchain manager
│   ├── compiler-cli/          ← `botopink` CLI
│   ├── compiler-core/         ← lexer, parser, AST, infer, comptime, codegen
│   ├── language-server/       ← `botopink-lsp` LSP server
│   └── lib-test-runner/       ← `botopink-lib-test` (test-libs gate)
├── libs/                      ← bundled .bp libraries — see libs/AGENTS.md
│   └── std/                   ← standard library
├── examples/                  ← non-framework .bp example programs
└── scripts/                   ← installers, release packing, snapshot audit, git hooks
```

Specs live in the meta workspace (`../../specs/`), not in this repo.

Golden snapshots live inside the owning package (`modules/compiler-core/snapshots/`,
`modules/language-server/snapshots/`) — tests run with the package as cwd.

## Workspace commands

```bash
zig build               # botopink + botopink-lsp + botopink-lib-test + bpmp
zig build test          # compiler-core + language-server + compiler-cli tests
zig build test -Dtest-filter=<name>   # only tests whose name matches
zig build run           # build and run the CLI
zig build test-cli      # every modules/compiler-cli/tests/*.sh (command contract, test tooling, recursion, backend parity)
zig build test-libs     # every visible .bp library's tests per backend (libs/ + sibling repository/*)
zig build test-backends # beam/wasm/erlang execution parity (modules/compiler-cli/tests/backend_exec.sh)
zig build test-bpmp     # bpmp unit tests
zig build test-vscode   # VS Code extension unit tests — scripts/test-vscode.sh finds the sibling checkout
zig build clean-tmp     # reap scratch dirs older than 1 day (also runs before `zig build test`)
```

`zig build test` also runs a lib-agnostic gate: it fails if
`modules/compiler-core/src` names a non-std library (`rakun|jhonstart|erika`).

Comptime evaluation spawns a persistent `erl`, so `erl`/`erlc` (OTP 27+) must be
on `PATH` for `zig build test`; codegen snapshot RUN LOGs also use `node`.

Per-test scratch dirs live under `modules/compiler-core/.botopinkbuild/tmp/<hex>/`
(one root for every `executeJavaScript` / `executeErlang` / `executeBeamAsm`
invocation). See
[`modules/compiler-core/src/codegen/AGENTS.md`](modules/compiler-core/src/codegen/AGENTS.md)
(`runtime.zig` row) for the layout contract.

`test-libs` is the lib ecosystem gate (`botopink-lib-test`): it runs
`botopink test --target <t>` in `libs/std` and in every sibling library the
checkout can see (`<ancestor>/repository/*` — the meta workspace, or the repos CI
checks out), and reports each cell as pass, FAIL (with the failing module's
diagnostic), known red, skipped (with the reason) or no tests — a library with
no `test` block is still compiled (`botopink build --target <t>`), so it fails
its cell when it does not compile. A cell listed in
[`scripts/known-red-libs.txt`](scripts/known-red-libs.txt) is named with its
owning front and does not fail the run; an unlisted failure does, and so does a
listed cell that passes (delete its line). It is **not** part of `zig build
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
| `.bp` libraries | [`libs/AGENTS.md`](libs/AGENTS.md) · [`libs/std/AGENTS.md`](libs/std/AGENTS.md) |
| Examples | [`examples/AGENTS.md`](examples/AGENTS.md) |
| Scripts | [`scripts/AGENTS.md`](scripts/AGENTS.md) |
| `.bp` language reference (user-facing) | [`docs.md`](docs.md) |

## Release pipeline

| Workflow | Trigger | What |
| --- | --- | --- |
| `.github/workflows/test.yml` | push / PR to `main`, `feat` | job `test`: `zig build test` from a cold runtime cache, then `zig build test-cli`, on ubuntu-22.04 + macos-14 (hard gate) and windows-2022 (allowed to fail). Job `libs` (ubuntu, after `test`): checks out emilia/erika/jhonstart/onze/rakun at `feat` into `repository/<name>/` and runs `zig build test-libs` over every runnable target. |
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
  and syntax.
- **English only** for source, comments, commits and compiler docs.
- **One fact, one source.** Each fact lives in a single file; others link to it.
- `Parser.init(tokens)` and `Lexer.init(source)` do **not** store an
  allocator — it is passed as `alloc: std.mem.Allocator` to the method that
  needs it.
- Type annotations use `TypeRef` (`named`, `array`, `tuple_`, `optional`,
  `function`, `generic`). Generic types use the `is_builtin` flag to distinguish
  `@Result<D, E>` (builtin) from `MyType<T>` (user).
- Record/enum/interface shorthand decls map to the same AST nodes as long-form
  declarations.
- Formatter must be round-trip stable: `format(parse(src))` re-parses to an
  equivalent AST.
- Pipeline `|>` is left-associative — preserve stable formatting across cycles.

## Local gate

**The gate every front runs before landing is `zig build test && zig build
test-libs`**, with `zig build test` from a cold runtime cache. The full ordered
run is [`scripts/gate.sh`](scripts/gate.sh):

1. `--staged`: conflict markers and `zig fmt --check` on staged files;
2. `zig build`;
3. `zig build test` (compiler-core, language-server, CLI and lib-test-runner unit suites; `--cold` deletes `modules/compiler-core/.botopinkbuild/runtime-cache` first — required for the run that decides a merge);
4. `zig build test-bpmp` (the package manager's unit suite);
5. `scripts/beam_export_audit.sh` (every beam snapshot module assembles with every function exported);
6. `zig build test-cli` (the CLI contract, test tooling, recursion and backend execution scripts);
7. `zig build test-libs` (every visible library, known reds named; a library without tests is still compiled).

`scripts/git-hooks/pre-commit` is the tracked pre-commit hook. It delegates to the
superproject's `scripts/git-hooks/lib/test-runner.sh` when that file exists;
otherwise it sources `scripts/git-hooks/lib/runner-standalone.sh`, which runs
`scripts/gate.sh --staged`. Install it once per clone with
`scripts/install-hooks.sh` (the hooks directory is shared by every worktree; the
installed shim runs the tracked hook of whichever checkout is committing). The
gate needs `node`, `erl`/`erlc`/`escript` and `wasmtime` on `PATH`. Do not use
`--no-verify`.

## Debugging tips & gotchas

### Persistent erl server (`comptime/runtime/persistent_erl.zig`)

Decorator and template bodies run in one long-lived `erl` process speaking
length-prefixed binary frames over stdin/stdout (`cmd 1` = compile+run `.erl`).
Comptime `val`s are folded in Zig (`comptime/eval.zig`).

- **`file:read/2` on `standard_io` can return a list, not a binary.** `read_frame/0`
  converts with `list_to_binary/1` before matching `<<Len:32/unsigned-big-integer>>`;
  keep that conversion when editing the server, or the server silently treats
  the frame as EOF and the Zig side blocks.
- **stdout is the frame channel only.** The server moves the default logger
  handler to `standard_error` and runs `main/0` with `standard_error` as its
  group leader, so `io:format/1` in a comptime body and a SIGTERM notice go to
  `.botopinkbuild/tmp/persistent_erl/erl.stderr.log` (write-only, truncated at
  each spawn). A reply length above `max_frame_len` (16 MiB) fails as
  `error.PersistentErlFrameTooLarge` with a message in `lastTransportError()`.
- **Timeouts.** `main/0` runs under `EVAL_TIMEOUT_MS` (10 s) inside erl; the
  server's `erlc` compile is bounded at 120 s. The Zig-side `readFrame` itself
  blocks without a timeout, so a wedged erl process still hangs the caller —
  wrap manual runs in `timeout`.
- **Server source is a Zig string literal** (`botopink_comptime_server`). It is
  compiled once into `.botopinkbuild/tmp/persistent_erl/<hash>/`, keyed by the
  source's hash, so editing the server invalidates the build by itself and a warm
  directory skips `erlc`. The build happens in a uniquely named staging
  directory renamed onto `<hash>/`, so compiler processes or test binaries
  sharing a cwd never compile or load a half-written file. Clearing it is safe:
  ```bash
  rm -rf .botopinkbuild/tmp/persistent_erl
  ```
- **Manual testing.** Frame = `struct.pack('>I', len(payload)) + payload`, payload
  = `b'\x01' + b'/path/to/mod.erl'`. Pipe into
  `erl -noshell -pa .botopinkbuild/tmp/persistent_erl/<hash> -eval 'botopink_comptime_server:start()'`.
  Never use `-noinput` — it disables stdin reading.

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
  RUN LOG. `executeWat` is a stub that returns an empty RUN LOG.
- **Erlang/BEAM early exit.** Both skip `erlc`/`erl` when the generated code has
  no `_botopink_main` or no I/O (`io:format`). If a test unexpectedly spawns erl,
  check for `_botopink_main` or `@print` in the output.
- **Output cache.** Executions are content-keyed and cached under
  `.botopinkbuild/runtime-cache/`. Keys ignore toolchain versions — delete the dir
  after upgrading node/erl.

### General

- **Stale processes.** Hung tests leave orphan `erl`/`node` processes:
  `pkill -f botopink_comptime_server`. The SIGTERM notice goes to
  `erl.stderr.log`, not the frame stream: a live compiler's in-flight request
  fails as a transport error and the next one respawns the server.
- **Scratch dirs.** Safe to delete manually: `rm -rf .botopinkbuild/tmp/[0-9a-f]*`.
- **Snapshot mismatches** write `<slug>.snap.md.new` next to the snapshot; do not
  commit `.snap.md.new` files.
