# compiler-cli

> Path: `modules/compiler-cli/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md) · Examples: [`src/cli/examples.md`](src/cli/examples.md)

Package that builds the `botopink` CLI executable. Depends on `compiler-core`.

## Tree

```text
compiler-cli/
├── AGENTS.md            ← you are here
├── build.zig            ← package build graph + `run` + `test` steps
├── build.zig.zon        ← dependency manifest (compiler-core)
├── tests/               ← end-to-end CLI scripts (NOT in `zig build test`)
│   ├── std_erlang.sh        ← `bp test --target erlang` over libs/std
│   ├── mutual_recursion.sh  ← forward-ref + mutual recursion runs on every backend
│   ├── mutual_recursion/    ← fixture project for the script above
│   ├── backend_exec.sh      ← backend EXECUTION parity (numeric/records/modules
│   │                          on node/erlang/beam/wasm); `zig build test-backends`
│   ├── backend_exec/         ← numeric + records fixture projects
│   ├── test_tooling.sh      ← `botopink test` behaviours: empty test, --filter
│   │                          (multi / none), assert-message, mixed pass/fail exit
│   └── test_tooling/         ← pass + fail fixture projects
└── src/
    ├── AGENTS.md
    ├── docs.md          ← argv parser layout, dispatch flow
    ├── main.zig         ← argv parser, subcommand dispatcher
    └── cli/             ← one file per subcommand + shared helpers
        ├── AGENTS.md
        ├── docs.md      ← subcommand pipeline + shared helpers
        └── examples.md  ← `botopink` command recipes
```

## Commands

```bash
zig build               # produce ./zig-out/bin/botopink
zig build run -- help
zig build run -- version
zig build test          # CLI unit tests (e.g. the generic lib loader)

# End-to-end scripts under tests/ build the CLI + spawn runtimes, so they are
# NOT part of `zig build test` — run them directly:
bash modules/compiler-cli/tests/std_erlang.sh        # stdlib suite on erlang
bash modules/compiler-cli/tests/mutual_recursion.sh  # mutual recursion on every backend
bash modules/compiler-cli/tests/backend_exec.sh      # numeric/records/modules per backend
bash modules/compiler-cli/tests/test_tooling.sh      # `botopink test` behaviours

# backend_exec.sh is also reachable from the repo root as a single build step
# (skips any absent runtime; sets BOTOPINK_SKIP_BUILD so it reuses the install):
zig build test-backends
```

> **Pinned backend reds** (recorded, not regressions — Front-A codegen gaps that
> `backend_exec.sh` surfaces and keeps visible): BEAM mis-codegens integer
> arithmetic combined with calls (`f(n-1) + …` / 2-arg arithmetic calls trip
> `beam_validator`), `case…of` enum dispatch (returns the wrong arm), and lambdas
> (a `#Fun` mis-applied to `*`); the erlang backend emits cross-module package
> calls unqualified (`area` vs `geometry:area`). The harness builds these (erlc
> must accept the asm) but treats the run as informational, flagging loudly if a
> red ever starts passing so the pin can be promoted to a hard assert.

## External libs (generic loader)

`cli/libs.zig` is the driver-side half of the lib-agnostic package mechanism. A
project's `botopink.json` `dependencies: ["<name>", …]` are resolved from disk
against an ordered **root list** (`resolveLibRoots`): walking up from cwd, each
ancestor `D` contributes — when present — `D/repository/botopink-lang/libs`
(bundled libs), `D/repository` (sibling projects), and `D/libs` (legacy flat
tree), de-duplicated nearest-first. `<name>` resolves to the **first root**
holding `<name>/botopink.json`; the loader reads its `{src, files}` and feeds the
lib's modules into compilation prefixed by name (`<name>/<module>`). On today's
flat tree only the `D/libs` branch fires, so the list is `[<ancestor>/libs]` —
byte-identical to the former single-root walk. The compiler core never names a
lib — it just sees ordinary `Module[]` and resolves `from "<name>"` through the
shared import registry. `std` is the one embedded exception and is not loaded
here. `shipMjsSidecars` resolves an owning lib's `.mjs` through the same root
list.

## CLI behavior contract

- Exit `0` on success, non-zero on command failure.
- All user-facing status/errors must go through `src/cli/reporter.zig`.
- Keep command options aligned with help text in `src/main.zig` and the
  `cli/<cmd>.zig` implementation.

See [`src/AGENTS.md`](src/AGENTS.md) for the dispatch flow and
[`src/cli/AGENTS.md`](src/cli/AGENTS.md) for the per-command list.
