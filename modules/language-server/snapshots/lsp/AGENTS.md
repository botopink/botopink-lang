# language-server/snapshots/lsp

> Path: `modules/language-server/snapshots/lsp/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Tests: [`../../src/tests/AGENTS.md`](../../src/tests/AGENTS.md)

Golden snapshots for every LSP feature. **50 files** organised by feature
prefix.

## File naming

| Prefix | Feature |
|---|---|
| `completion_*` | `textDocument/completion` |
| `definition_*` | `textDocument/definition` |
| `hover_*` | `textDocument/hover` |
| `references_*` | `textDocument/references` |
| `rename_*` | `textDocument/rename` |
| `sig_*` | `textDocument/signatureHelp` |
| `symbols_*` | `textDocument/documentSymbol` |

## Rules

- One scenario per file. Keep names short and self-explanatory.
- Output must be deterministic — no timestamps, no absolute paths, sorted
  arrays where applicable.
- Don't commit `.snap.md.new` files.
