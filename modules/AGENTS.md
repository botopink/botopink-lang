# modules/

> Path: `modules/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

All Zig packages live here. Each package ships its own `build.zig` and `AGENTS.md`.
The bundled `.bp` libraries (`std`/`server`/`client`) live alongside under
[`../libs/`](../libs/AGENTS.md). The **VS Code extension** is a sibling project
at [`../../vscode-extension/`](../../vscode-extension/AGENTS.md), not a module
here — it ships and versions separately from the language core.

## Tree

```text
modules/
├── AGENTS.md                ← you are here
├── compiler-cli/            ← `botopink` CLI executable
│   ├── build.zig
│   ├── build.zig.zon
│   └── src/                 ← main + cli/ (commands)
├── compiler-core/           ← library: lexer / parser / AST / infer / codegen
│   ├── build.zig
│   ├── build.zig.zon
│   ├── src/                 ← all compiler stages
│   └── snapshots/           ← parser / codegen / comptime snapshots
├── language-server/         ← `botopink-lsp` LSP executable
│   ├── build.zig
│   ├── build.zig.zon
│   ├── src/                 ← JSON-RPC server + LSP features + tests
│   └── snapshots/lsp/       ← LSP feature snapshots
├── lib-test-runner/         ← `botopink-lib-test` — per-lib/per-backend test gate
│   ├── build.zig
│   ├── build.zig.zon
│   └── src/                 ← discovery + fan-out + matrix (self-contained)
├── bpmp/                    ← `bpmp` — Boto Pink Package Manager + toolchain manager
│   ├── AGENTS.md
│   └── src/                 ← manifest + lockfile + semver + resolver + commands
└── wasm3/                   ← vendored wasm3 interpreter (C) — embedded comptime runtime
    ├── AGENTS.md
    ├── README.md            ← upstream pin + excluded content + upgrade procedure
    ├── LICENSE
    ├── build.zig            ← exports link() + exposeHeaders() + wasm3_srcs/cflags
    └── source/              ← byte-identical upstream `source/` (16 .c + headers)
```

## Packages

| Package | Output | Depends on | AGENTS |
|---|---|---|---|
| `compiler-cli/` | `botopink` executable | `compiler-core` | [link](compiler-cli/AGENTS.md) |
| `compiler-core/` | library (lexer → codegen) | [`libs/std`](../libs/std/AGENTS.md) | [link](compiler-core/AGENTS.md) |
| `language-server/` | `botopink-lsp` executable | `compiler-core` | [link](language-server/AGENTS.md) |
| `lib-test-runner/` | `botopink-lib-test` executable | none (shells out to `botopink`) | [link](lib-test-runner/AGENTS.md) |
| `bpmp/` | `bpmp` executable | none (spawns `botopink`) | [link](bpmp/AGENTS.md) |
| `wasm3/` | vendored C interpreter (no standalone output) | none (consumed by `compiler-core`) | [link](wasm3/AGENTS.md) |
| `../../vscode-extension/` | VS Code `.vsix` extension (sibling project) | `language-server` (runtime) | [link](../../vscode-extension/AGENTS.md) |

## Per-package commands

```bash
cd modules/<package> && zig build           # compile
cd modules/<package> && zig build run       # run (cli + lsp only)
cd modules/<package> && zig build test      # tests (core + lsp + lib-test-runner units)
```

The workspace `../build.zig` wires CLI + LSP + lib-test-runner together, plus a
`zig build test-libs` step that runs every `libs/` project's tests per backend via
`botopink-lib-test` (needs `node`/`escript` on `PATH`; not part of `zig build
test`). See the root [`AGENTS.md`](../AGENTS.md) for top-level commands.

## Cross-package conventions

- English only in source, comments, docs and commit messages.
- When adding a new subdirectory under a package, create an `AGENTS.md` for it
  and link it from the parent. Add a `docs.md` if the directory deserves a
  detailed module explanation.
- Codegen is implemented entirely in Zig under `compiler-core/`. There is **no**
  standalone Node.js/WASM compiler.

For the package dependency graph and full cross-package conventions see
[`./docs.md`](docs.md).
