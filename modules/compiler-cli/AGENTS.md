# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── botopink.json        ← module manifest (`version` drives the auto-tag)
├── build.zig            ← standalone build graph + `run` + `test` steps
├── build.zig.zon        ← dependency manifest (compiler-core)
├── tests/               ← end-to-end CLI scripts — `zig build test-cli` runs all four
│   ├── cli_contract.sh      ← the command contract (rows C1–C13) against the real binary
│   ├── mutual_recursion.sh  ← forward-ref + mutual recursion runs on every backend
│   ├── mutual_recursion/    ← fixture project for the script above
│   ├── backend_exec.sh      ← backend execution parity (numeric / records /
│   │                          examples/modules); `zig build test-backends`
│   ├── backend_exec/        ← numeric + records fixture projects
│   ├── test_tooling.sh      ← `botopink test` behaviours: empty test, --filter
│   │                          (multi / none), assert message, mixed pass/fail exit
│   └── test_tooling/        ← pass + fail fixture projects
└── src/
    ├── AGENTS.md
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
        └── AGENTS.md
```

## Commands

```bash
zig build               # produce ./zig-out/bin/botopink
zig build run -- help
zig build run -- version
zig build test          # CLI unit tests (main.zig parsers / config / libs / resolver / migrate / test_cmd / diagnostics)

# The workspace root `zig build test` also runs these tests (root = src/main.zig,
# cwd = modules/compiler-cli).

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
> fixes its backend: `examples/modules` on erlang (cross-module calls emitted
> unqualified — `function lucky/0 undefined`; the erlang front) and the `numeric`
> fixture on BEAM (call-result arithmetic fails `beam_validator`; the beam front).
> The `std` suite on erlang is covered by `zig build test-libs`, not a script.

## External libs (generic loader)

`cli/libs.zig` is the driver-side half of the lib-agnostic package mechanism. A
project's `botopink.json` `dependencies` are resolved from disk against an
ordered **root list** (`resolveLibRoots`): `BOTOPINK_LIB_ROOTS` entries first,
then, walking up from cwd, each ancestor `D` contributes — when present —
`D/repository/botopink-lang/libs` (bundled libs), `D/repository` (sibling
projects), and `D/libs` (flat tree), de-duplicated first-occurrence-wins. After
those, `resolveFallbackRoots` adds `<project>/.botopinkbuild/deps/` (the symlink
store written by `bpmp install`). `<name>` resolves to the **first root** holding
`<name>/botopink.json`; the loader reads its `{src, files}` (`LibManifest`) and
feeds the lib's modules into compilation prefixed by name (`<name>/<module>`).
The compiler core never names a lib — it sees ordinary `Module[]` and resolves
`from "<name>"` through the shared import registry. `std` is embedded and not
loaded here. `shipMjsSidecars` resolves an owning lib's `.mjs` through the same
root list.

**Unknown `botopink.json` fields are ignored.** `LibManifest` reads only `src`
and `files`; the project loader (`config.zig`) reads `name`/`version`/`target`/
`entry`/`dependencies`. Anything else — including the bpmp-facing `botopink`
(compiler version constraint) and `requires` (per-dep version constraint) —
passes through untouched, so adding an optional field needs no change here.

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
| `build [--target T] [--out D] [--typescript]` | `botopink.json`, the `src/` module tree, each declared dependency | `D/<module>.<ext>` for every module that compiled (+ `.d.ts`, + `.mjs` sidecars on commonJS); the previous artifact of a module that did not compile is deleted | **open:** `codegen.generate` still executes each emitted module (see below) | every module compiled and its artifact is on disk | no project, unsupported target, unresolvable tree or dependency, or **any** module failed — each failing module is rendered (file, line, excerpt) and named in `N module(s) failed to compile: a, b` |
| `run [--target T] [--module M] [--out D] [-- args…]` | what `build` reads | what `build` writes, into `D` | the target runner on `D/M.<ext>` (`beam` only prints the `erlc +from_asm` hint) | the program's own 0 | `build`'s code, or the program's |
| `check [<path>]` | `botopink.json`, `src/` **and** `test/`, dependencies — in `<path>` when given | nothing | `erl` (comptime) | every module type-checks | at least one diagnostic, each with file, line and excerpt; failing modules named |
| `test [--target T] [--filter S] [--json]` | `botopink.json`, `src/`, `test/`, dependencies | `.botopinkbuild/test-out/**`, emptied first | the target runner per module with tests (`node` / `escript`) | every module compiled **and** every test passed | a module failed to compile, or a test failed; the modules that compiled still ran their tests and are reported |
| `format [files…]` | the files, else `src/` | the files, in place | nothing | every file parsed and is now canonical | a file could not be read, lexed or parsed (rendered with its location) |
| `format --check [files…]` | as above | nothing | nothing | every file parsed **and** already canonical | a file would change, or could not be read, lexed or parsed |
| `new <name> [--target T]` | nothing | `<name>/{botopink.json,src/main.bp,.gitignore}` | nothing | scaffolded with a supported target | bad name, or a target outside `commonJS\|erlang\|beam\|wasm` |
| `clean` | nothing | deletes `out/` and `.botopinkbuild/` | nothing | both are gone (`Removed <dir>/` printed per success) | a delete failed |
| `migrate [--dry-run]` | the `src/` tree | index files (`root.bp`/`main.bp`/`mod.bp`) — **none** under `--dry-run` | nothing | the tree is covered | `src/` unreadable |

Cross-command rules:

- **Arguments.** Every parser in `main.zig` rejects an unknown flag, a positional
  the command does not take and an unsupported target (exit 1, with the token
  named). `--flag value` and `--flag=value` are equivalent. A `botopink.json`
  whose `target` is unsupported fails the command instead of degrading to
  commonJS (`ProjectConfig.parsedTarget` returns `null`).
- **`build`, `check` and `test` agree**: on the same tree either all three exit
  0 or all three exit 1. They share `cli/diagnostics.zig`: a lex/parse preflight
  (located errors, the module is left out so the rest still compile), and a
  guard that compares the **named** module set handed to `codegen.generate` with
  the named set it returned — never counts, which `from "std"` expansion
  inflates. When a module is missing, the comptime pipeline is re-run on the
  failure path only to render its diagnostic.
- **Orphans.** A `.bp` file no `mod` path reaches is warned per file and counted
  once (`N module(s) not reached by any `mod` path were not compiled`).
- **Dependencies.** A missing dependency is named (`dependency 'server' was not
  found under any library root`).

Open (not the CLI's files):

- **`build`/`test` execute the program they compile.** `codegen.generate`
  (`modules/compiler-core/src/codegen.zig`) runs every emitted module through
  `runtime.execute*` and stores stdout on `run_output`, which no command reads.
  The fix is an "execute" flag on `codegen.Config` that the snapshot harness sets
  and the CLI leaves off — a compiler-core change.
- **The diagnostic is re-derived, not carried.** The four backends' `codegenEmit`
  still `continue` on `.parseError`/`.typeError`, and `ComptimeOutput.outcome`'s
  `parseError` carries no payload (a lex error aborts the session). The CLI works
  around both (preflight + `explainFailures`); the root fix belongs to the
  backend and comptime owners.

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
