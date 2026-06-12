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
- **Test-mode codegen** (§T `----- RUN LOG -----` envelope per test): each
  backend's `__bp_run_tests` emitter wraps every `test "name" { … }` body
  with a fixed `TEST <file>:<line> <name>` header + a fenced ```logs``` block
  capturing the body's stdout. See
  [`../compiler-cli/AGENTS.md#botopink-test-output-format-§t`](../compiler-cli/AGENTS.md)
  for the full contract; emitters in `src/codegen/commonJS.zig`
  (`__bp_run_tests`) and `src/codegen/erlang.zig` (`__bp_run_one`) implement
  the commonJS + erlang halves today.

Full pipeline diagram, AST model, public API table, and snapshot system
overview live in [`./docs.md`](docs.md).

## Tagging

`compiler-core` is auto-tagged on push by
[`../../.github/workflows/tag.yml`](../../.github/workflows/tag.yml) (path
filter: `modules/compiler-core/**`):

- `compiler-core/<version>-feat` — moving; force-updated on each feat push.
- `compiler-core/<version>` — immutable; created once per master/main push.
  Re-push without bumping `botopink.json.version` → red gate.

`<version>` is `botopink.json.version` (this module's local manifest, NOT
the workspace `v*` release tags). Bumping the tag is a one-line edit to
`botopink.json` in the same PR that lands the changes you want tagged.
Spec: [`tasks/v0.beta.18/specs/module-auto-tag.md`](../../tasks/v0.beta.18/specs/module-auto-tag.md).
