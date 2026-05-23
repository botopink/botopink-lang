# language-server/src/tests

> Path: `modules/language-server/src/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Snapshots: [`../../snapshots/lsp/AGENTS.md`](../../snapshots/lsp/AGENTS.md)
> Docs: [`./docs.md`](docs.md)

Feature-level tests for LSP behaviour and diagnostics.

## Tree

```text
tests/
├── AGENTS.md
├── docs.md               ← harness structure + determinism rules
├── root.zig              ← test aggregator
├── helpers.zig           ← assertion + setup helpers
├── snapshot.zig          ← snapshot read/write
├── snapshot_test.zig     ← shared snapshot test harness
├── diagnostics.zig       ← publishDiagnostics
├── formatting.zig        ← textDocument/formatting
├── hover.zig             ← textDocument/hover
├── definition.zig        ← textDocument/definition
├── symbols.zig           ← textDocument/documentSymbol
├── completion.zig        ← textDocument/completion
├── references.zig        ← textDocument/references
├── rename.zig            ← textDocument/rename
├── signature_help.zig    ← textDocument/signatureHelp
├── folding_range.zig     ← textDocument/foldingRange
├── prepare_rename.zig    ← textDocument/prepareRename
├── code_actions.zig      ← textDocument/codeAction
└── type_definition.zig   ← textDocument/typeDefinition
```

## Snapshot workflow

- Snapshots live under [`../../snapshots/lsp/`](../../snapshots/lsp/AGENTS.md).
- On mismatch a `<name>.snap.md.new` is written — review the diff and either
  promote it or fix the underlying bug.
- Promote only intentional protocol/output changes; surprise changes usually
  signal a regression.
