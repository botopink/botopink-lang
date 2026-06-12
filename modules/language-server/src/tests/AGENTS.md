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
├── type_definition.zig   ← textDocument/typeDefinition
├── semantic_tokens.zig   ← textDocument/semanticTokens
├── inlay_hints.zig       ← textDocument/inlayHint
├── sublanguage.zig       ← `@ExprCustom` overlay: tokens + diagnostics + hover/def
├── lifecycle.zig         ← `files.FileCache` didOpen→didChange→didClose
└── cross_module.zig      ← project-index requests (references / rename / import-missing)
```

`sublanguage.zig` uses `helpers.compileEval` (template-eval context on, unique
scratch root per call) so the `@ExprCustom` `CustomNode` trees actually exist —
it spawns `node`, like the comptime template tests.

`cross_module.zig` is the only suite that touches **disk**: it materializes a
tiny project under a unique `.botopinkbuild/xmod-*` dir (resolved against the
test cwd, this module's root), points a `ProjectIndex` at it via `setRoot`, and
exercises `crossModuleReferences` / `crossModuleRename` / the import-missing
`codeAction` — the requests that only fire once a workspace root is known. Each
test deletes its dir on exit (and pre-deletes on entry, so a crashed run leaves
no stale fixture). `lifecycle.zig` drives the in-memory `FileCache` directly (no
`node`, no disk); writing it surfaced a double-dup leak in `FileCache.change`'s
unopened-uri fallback, since fixed.

## Snapshot workflow

- Snapshots live under [`../../snapshots/lsp/`](../../snapshots/lsp/AGENTS.md).
- On mismatch a `<name>.snap.md.new` is written — review the diff and either
  promote it or fix the underlying bug.
- Promote only intentional protocol/output changes; surprise changes usually
  signal a regression.
