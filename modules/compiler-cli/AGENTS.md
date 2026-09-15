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
├── tests/               ← end-to-end CLI scripts (NOT in `zig build test`)
│   ├── std_erlang.sh        ← `botopink test --target erlang` over libs/std
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
zig build test          # CLI unit tests (config / libs / resolver / migrate / test_cmd)

# The workspace root `zig build test` also runs these tests (root = src/main.zig,
# cwd = modules/compiler-cli).

# End-to-end scripts under tests/ build the CLI + spawn runtimes, so they are
# NOT part of `zig build test` — run them directly:
bash modules/compiler-cli/tests/std_erlang.sh        # stdlib suite on erlang
bash modules/compiler-cli/tests/mutual_recursion.sh  # mutual recursion on every backend
bash modules/compiler-cli/tests/backend_exec.sh      # numeric/records/modules per backend
bash modules/compiler-cli/tests/test_tooling.sh      # `botopink test` behaviours

# backend_exec.sh is also a workspace build step (skips any absent runtime;
# sets BOTOPINK_SKIP_BUILD so it reuses the installed CLI):
zig build test-backends
```

> **Pinned backend reds** in `backend_exec.sh`: the `records` fixture on BEAM
> (`case` enum dispatch / lambda codegen — `pin_beam_red`: erlc must accept the
> asm, the run is informational) and `examples/modules` on erlang (cross-module
> package calls emitted unqualified — `pin_run_red`). Both flag loudly if the red
> starts passing so the pin can be promoted to a hard assert. BEAM is not run on
> the `numeric` fixture at all (call-result arithmetic fails `beam_validator`).

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

## CLI behavior contract

- Exit `0` on success, non-zero on command failure.
- User-facing status/errors go through `src/cli/reporter.zig` (a few legacy
  diagnostic paths in `build`/`check`/`clean`/`format` still call
  `std.debug.print` directly).
- Keep command options aligned with the `HELP` text in `src/main.zig` and the
  `cli/<cmd>.zig` implementation.

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
