# modules — package graph & cross-package design

> Path: `modules/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Root: [`../AGENTS.md`](../AGENTS.md)

This document explains how the four Zig packages under `modules/` fit
together — what each one owns, who imports whom, and which conventions are
shared across the workspace.

## Tree

```text
modules/
├── compiler-cli/        → `botopink` CLI       (depends on compiler-core)
├── compiler-core/       → main compiler lib    (depends on libs/std)
└── language-server/     → `botopink-lsp`       (depends on compiler-core)
```

The `.bp` libraries (`std`, `server`, `client`) live at the repo root under
[`../libs/`](../libs/AGENTS.md); `compiler-core` embeds `libs/std`'s prelude.

## Dependency graph

```text
                ┌──────────────────┐
                │ libs/std (.bp)   │
                └────────▲─────────┘
                         │ @embedFile + Env registration
                ┌────────┴─────────┐
                │  compiler-core   │  (lex → parse → infer → transform → codegen)
                └─┬────────────────┘
                  │ imported as `botopink`
       ┌──────────┴───────────┐
       ▼                      ▼
┌──────────────┐     ┌─────────────────┐
│ compiler-cli │     │ language-server │
└──────────────┘     └─────────────────┘
```

- **`compiler-core`** owns every compilation stage and is the only module that
  may walk the AST. It exposes its public API through `src/root.zig`.
- **`compiler-cli`** drives compilation from the shell. It never `@import`s
  internal compiler-core paths — only the `botopink` module re-exported by
  `src/root.zig`.
- **`language-server`** does the same as the CLI but over JSON-RPC. It funnels
  every call through a thin local `compiler.zig` wrapper so the protocol layer
  stays decoupled from the compiler.
- **`libs/std`** is data, not Zig code. Each `.bp` file is `@embedFile`'d via
  `modules/compiler-core/src/comptime/stdlib/prelude.zig` and pulled into the inference `Env` before each
  pass. It lives at the repo root, not under `modules/`.

## Per-package commands

```bash
cd modules/<package> && zig build           # compile
cd modules/<package> && zig build run       # run (cli + lsp only)
cd modules/<package> && zig build test      # tests (core + lsp)
```

The workspace root `build.zig` wires CLI + LSP together; per-package builds
remain independent so individual modules can be developed in isolation.

## Cross-package conventions (rationale)

| Rule | Why |
|---|---|
| English only in source, comments, commits | Reviewers and AI agents must read the same surface |
| New subdirectory → new `AGENTS.md` | Each dir is a contract; missing docs strand the next contributor |
| No standalone JS/WASM compiler | Both targets are produced natively in Zig under `compiler-core/src/codegen/` |
| `alloc: std.mem.Allocator` is passed as a parameter | Allocator is never a long-lived field; arena lifetime is controlled at the call site |
| Snapshot tests are the source of truth for outputs | Diffs are reviewed; surprise mismatches are bugs |

## Where to go next

- Single package deep-dive — open that package's `docs.md`.
- Cross-cutting language reference — [`../docs.md`](../docs.md) (the `.bp`
  reference manual).
- Pipeline overview — [`compiler-core/docs.md`](compiler-core/docs.md).
