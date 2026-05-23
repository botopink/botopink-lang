# modules/

> Path: `modules/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

All Zig packages live here. Each package ships its own `build.zig` and `AGENTS.md`.

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
├── stdlib/                  ← .bp standard-library declarations
│   ├── botopink.json
│   └── src/                 ← prelude.zig + *.bp interface files
└── vscode-extension/        ← VS Code extension (syntax + LSP client)
    ├── package.json
    ├── language-configuration.json
    ├── syntaxes/             ← TextMate grammar + markdown injection
    ├── snippets.json
    └── src/                  ← TypeScript LSP client (extension.ts)
```

## Packages

| Package | Output | Depends on | AGENTS |
|---|---|---|---|
| `compiler-cli/` | `botopink` executable | `compiler-core` | [link](compiler-cli/AGENTS.md) |
| `compiler-core/` | library (lexer → codegen) | `stdlib` | [link](compiler-core/AGENTS.md) |
| `language-server/` | `botopink-lsp` executable | `compiler-core` | [link](language-server/AGENTS.md) |
| `stdlib/` | embedded `.bp` source strings | — | [link](stdlib/AGENTS.md) |
| `vscode-extension/` | VS Code `.vsix` extension | `language-server` (runtime) | [link](vscode-extension/AGENTS.md) |

## Per-package commands

```bash
cd modules/<package> && zig build           # compile
cd modules/<package> && zig build run       # run (cli + lsp only)
cd modules/<package> && zig build test      # tests (core + lsp)
```

The workspace `../build.zig` wires CLI + LSP together. See the root
[`AGENTS.md`](../AGENTS.md) for top-level commands.

## Cross-package conventions

- English only in source, comments, docs and commit messages.
- When adding a new subdirectory under a package, create an `AGENTS.md` for it
  and link it from the parent. Add a `docs.md` if the directory deserves a
  detailed module explanation.
- Codegen is implemented entirely in Zig under `compiler-core/`. There is **no**
  standalone Node.js/WASM compiler.

For the package dependency graph and full cross-package conventions see
[`./docs.md`](docs.md).
