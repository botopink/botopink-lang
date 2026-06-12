# language-server/snapshots/lsp

> Path: `modules/language-server/snapshots/lsp/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Tests: [`../../src/tests/AGENTS.md`](../../src/tests/AGENTS.md)

Golden snapshots for every LSP feature, organised by feature prefix.

## Tree

```text
lsp/
├── AGENTS.md
└── *.snap.md      ← LSP feature fixtures (grouped by prefix below)
```

## File naming

| Prefix | Feature |
|---|---|
| `code_action_*` | `textDocument/codeAction` |
| `completion_*` | `textDocument/completion` |
| `definition_*` | `textDocument/definition` |
| `folding_*` | `textDocument/foldingRange` |
| `hover_*` | `textDocument/hover` |
| `inlay_hints_*` | `textDocument/inlayHint` |
| `prepare_rename_*` | `textDocument/prepareRename` |
| `references_*` | `textDocument/references` |
| `rename_*` | `textDocument/rename` |
| `semantic_tokens_*` | `textDocument/semanticTokens` |
| `sig_*` | `textDocument/signatureHelp` |
| `symbols_*` | `textDocument/documentSymbol` |
| `type_definition_*` | `textDocument/typeDefinition` |
| `sublanguage_*` | `@ExprCustom` overlay (tokens + hover) |

## Rules

- One scenario per file. Keep names short and self-explanatory.
- Output must be deterministic — no timestamps, no absolute paths, sorted
  arrays where applicable.
- Don't commit `.snap.md.new` files.
