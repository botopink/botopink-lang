# modules/

> Path: `modules/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

All Zig packages live here. Each package ships its own `AGENTS.md`.
The bundled `.bp` standard library lives alongside under
[`../libs/`](../libs/AGENTS.md). The **VS Code extension** is a sibling project
at [`../../vscode-extension/`](../../vscode-extension/AGENTS.md), not a module
here — it ships and versions separately from the language core.

## Tree

```text
modules/
├── AGENTS.md                ← you are here
├── compiler-cli/            ← `botopink` CLI executable
│   ├── src/                 ← main + cli/ (commands)
│   └── tests/               ← end-to-end shell scripts (not in `zig build test`)
├── compiler-core/           ← library: lexer / parser / AST / infer / comptime / codegen
│   ├── src/                 ← all compiler stages
│   └── snapshots/           ← parser / codegen / comptime snapshots
├── compiler-web/            ← the browser build of compiler-core (`zig build compiler-web` → zig-out/web/)
│   ├── src/web_root.zig     ← the wasm32-wasi exports: bp_add_source / bp_compile / bp_output_*
│   ├── glue.js              ← WASI shim + `Botopink.Compiler` + the Worker protocol (no dependency)
│   ├── index.html           ← the demo page
│   └── tests/smoke.js       ← `zig build test-web`: the build answers like the native compiler, under node
├── language-server/         ← `botopink-lsp` LSP executable
│   ├── src/                 ← JSON-RPC server + LSP features + tests
│   └── snapshots/lsp/       ← LSP feature snapshots
├── lib-test-runner/         ← `botopink-lib-test` — per-lib/per-backend test gate
│   └── src/                 ← discovery + fan-out + matrix (self-contained)
├── manifest/                ← the shared `botopink.json` model (packages, workspaces, dependencies)
│   ├── src/                 ← root.zig — parser, workspace expansion, discovery, resolution
│   └── tests/fixtures/      ← the manifests its unit tests read
├── wasm3/                   ← vendored wasm3 (C, v0.5.0): the wat comptime runtime's engine, in-process
├── test-scratch/            ← `test_scratch` — the one way a TEST spells a path it writes to
│   └── src/root.zig         ← per-process scratch root; given to the test modules only
├── source-stamp/            ← `source_stamp` — the stale-binary refusal of a library run
│   └── src/root.zig         ← the content hash of the sources the binaries are built from
├── test-shard/              ← the compiler-core test runner: one shard of the suite per process
│   └── runner.zig           ← zig's default runner restricted by `BOTOPINK_TEST_SHARD=<i>/<n>`
└── bpmp/                    ← `bpmp` — Boto Pink Package Manager + toolchain manager
    ├── build.zig.zon        ← no own build.zig; built by the workspace build.zig
    └── src/                 ← manifest + lockfiles + semver + resolver + commands
```

## Packages

| Package | Output | Depends on | AGENTS |
|---|---|---|---|
| `compiler-cli/` | `botopink` executable | `compiler-core`, `manifest` | [link](compiler-cli/AGENTS.md) |
| `compiler-core/` | library (lexer → codegen) | [`libs/std`](../libs/std/AGENTS.md) | [link](compiler-core/AGENTS.md) |
| `compiler-web/` | `botopink.wasm` (wasm32-wasi) + `glue.js` + `index.html` | `compiler-core` | [link](compiler-web/AGENTS.md) |
| `language-server/` | `botopink-lsp` executable | `compiler-core`, `manifest` | [link](language-server/AGENTS.md) |
| `lib-test-runner/` | `botopink-lib-test` executable | `manifest` only (shells out to `botopink`) | [link](lib-test-runner/AGENTS.md) |
| `manifest/` | library (the `botopink.json` model) | `std` only | [link](manifest/AGENTS.md) |
| `test-scratch/` | library (`test_scratch` — per-process scratch paths for tests) | `std` only | [link](test-scratch/AGENTS.md) |
| `source-stamp/` | library (`source_stamp` — the hash `build.zig` embeds in `botopink` and `botopink-lib-test`; a library run refuses a binary whose checkout moved) | `std` only | [link](source-stamp/AGENTS.md) |
| `test-shard/` | the compiler-core test binary's runner (`build.zig` `.test_runner`), run as `-Dtest-shards` processes | `std` only | [link](test-shard/AGENTS.md) |
| `wasm3/` | C sources linked into every native artifact that imports `compiler-core` (`link`), headers for its `@cImport` (`exposeHeaders`) | libc | [link](wasm3/AGENTS.md) |
| `bpmp/` | `bpmp` executable | `manifest` only (spawns `botopink`) | [link](bpmp/AGENTS.md) |
| `../../vscode-extension/` | VS Code `.vsix` extension (sibling project) | `language-server` (runtime) | [link](../../vscode-extension/AGENTS.md) |

## Commands

The workspace [`../build.zig`](../build.zig) builds every executable
(`botopink`, `botopink-lsp`, `botopink-lib-test`, `bpmp`) and owns the steps:

```bash
zig build                  # build all four executables into zig-out/bin/
zig build run -- <args>    # build + run the botopink CLI
zig build test             # compiler-core + language-server + compiler-cli + lib-test-runner + manifest + test-scratch tests
                           # (+ lib-agnostic grep gate over compiler-core/src)
                           # (+ scripts/check-test-scratch.sh — no cwd-anchored .botopinkbuild path in a test or a tests/ file)
zig build test -Dtest-filter=<substr>
zig build test -Dtest-shards=<n>   # compiler-core split across n processes (default: CPUs, at most 8; 1 = one process)
zig build test-bpmp        # bpmp unit tests          (not part of `test`)
zig build test-libs        # every libs/ project per backend via botopink-lib-test
zig build test-vscode      # VS Code extension unit tests (needs node/npm)
zig build test-backends    # compiler-cli/tests/backend_exec.sh (needs runtimes)
zig build clean-tmp        # reap compiler-core/.botopinkbuild/tmp and every
                           # modules/*/.botopinkbuild/test-scratch root older than 1 day
zig build compiler-web     # compiler-core for the browser → zig-out/web/ (fixed wasm32-wasi target)
zig build test-web         # its smoke test under node (needs node; not part of `test`)
```

No package carries a `build.zig` of its own (`bpmp` keeps only a `build.zig.zon`):
every command runs from the workspace root, which derives the `std` module list
from `libs/std/src/root.bp` (a second build graph once built a compiler with 5 of
the std modules). The lib-test-runner's unit tests run under the workspace
`zig build test` (root `src/main.zig`, cwd `modules/lib-test-runner`). See the root
[`AGENTS.md`](../AGENTS.md) for top-level commands.

## Cross-package conventions

- English only in source, comments, docs and commit messages.
- When adding a new subdirectory under a package, create an `AGENTS.md` for it
  and link it from the parent.
- Codegen is implemented entirely in Zig under `compiler-core/`. There is **no**
  standalone Node.js/WASM compiler: `compiler-web/` is compiler-core itself built
  for `wasm32-wasi`, with the comptime runtime and the RUN LOG executors compiled
  out (`compiler-core/src/comptime/runtime/runtime.zig`).
- Comptime evaluation (templates, decorators) runs through compiler-core's
  persistent `erl` process (`compiler-core/src/comptime/runtime/persistent_beam.zig`);
  the CLI and the LSP share that pipeline.
