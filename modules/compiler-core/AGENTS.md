# compiler-core

> Path: `modules/compiler-core/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../AGENTS.md`](../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Main Zig library: lexer, parser, AST, type inference, comptime, codegen and
formatter. Imported as the `botopink` module by `compiler-cli` and
`language-server`.

## Tree

```text
compiler-core/
├── AGENTS.md            ← you are here
├── build.zig            ← build graph (`zig build [run|test]`)
├── build.zig.zon        ← deps (stdlib)
├── src/                 ← all compiler stages — see src/AGENTS.md
└── snapshots/           ← all .snap.md test fixtures — see snapshots/AGENTS.md
    ├── parser/          ← AST snapshots
    ├── codegen/         ← codegen output (erlang/, node/, errors/)
    └── comptime/        ← comptime + type-error snapshots
```

## Commands (run from this directory)

```bash
zig build               # compile
zig build test          # run all tests
zig build run           # run CLI stub (main.zig)
zig build test -- --test-filter "import decl"
```

## High-level pipeline

```text
source → lex → parse → infer (HM) → transform (specialize) → codegen → target
                              ↘  format.zig   round-trippable formatter
                              ↘  print.zig    rustc-style diagnostics
```

## Children

| Dir | Purpose |
|---|---|
| [`src/`](src/AGENTS.md) | Implementation of every stage. |
| [`snapshots/`](snapshots/AGENTS.md) | Test fixtures for parser/codegen/comptime. |

## Notes

- No standalone Node.js or WASM compiler — JS and Erlang are emitted natively
  in Zig under `src/codegen/`.
- Comptime evaluation is target-agnostic; the runtime backends live in
  [`src/comptime/runtime/`](src/comptime/runtime/AGENTS.md).
- For language syntax notes (records / enums / pipeline `|>` / numeric literals
  / etc.) see the workspace [`docs.md`](../../docs.md).

Full pipeline diagram, AST model, public API table, and snapshot system
overview live in [`./docs.md`](docs.md).
