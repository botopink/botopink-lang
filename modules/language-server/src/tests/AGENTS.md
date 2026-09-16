# language-server/src/tests

> Path: `modules/language-server/src/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Feature-level tests for LSP behaviour and diagnostics. Every file here is
registered in [`../test_root.zig`](../test_root.zig) — add new suites there.

## Tree

```text
tests/
├── AGENTS.md
├── root.zig              ← older partial aggregator (not used by the build — see ../test_root.zig)
├── _warmup.zig           ← runs first: lazy-inits compiler-core's stdlib template
├── helpers.zig           ← assertion + setup helpers (compile, compileEval, multi-module)
├── snapshot.zig          ← snapshot read/write
├── snapshot_test.zig     ← shared snapshot test harness
├── messages.zig          ← JSON-RPC frame reader (`messages.readMessage`)
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
├── cross_module.zig      ← project-index requests (references / rename / import-missing)
└── project_graph.zig     ← project-graph compile + `ProjectGraph.resolveRoots`
```

`sublanguage.zig` uses `helpers.compileEval` (template-eval context on, unique
scratch root `.botopinkbuild/lsp-test/<n>` per call) so the `@ExprCustom`
`CustomNode` trees actually exist — template bodies run through compiler-core's
persistent `erl` comptime runtime, so `erl` must be on `PATH`.

Suites that touch **disk** (paths resolved against the test cwd,
`modules/language-server`):

- `cross_module.zig` materializes a tiny project under `.botopinkbuild/xmod-*`,
  points a `ProjectIndex` at it via `setRoot`, and exercises
  `crossModuleReferences` / `crossModuleRename` / the import-missing
  `codeAction`. Each test pre-deletes and deletes its dir on exit.
- `project_graph.zig` writes throwaway workspaces under
  `.botopinkbuild/lsp-roots-*` for the `BOTOPINK_LIB_ROOTS` tests, and resolves a
  real sibling project (`../../../rakun/examples/rakun/`) for the cache test — that
  test skips when the sibling checkout is absent.

`lifecycle.zig` drives the in-memory `FileCache` directly (no runtime, no disk).

## Snapshot workflow

- Snapshots live under `../../snapshots/lsp/`.
- A **missing** snapshot fails the test (`error.SnapshotMissing`) and writes the
  candidate baseline as `<name>.snap.md.new`; set `BOTOPINK_SNAP_CREATE=1` to
  record it. Before spec 06 step 1 a first recording was accepted silently and
  nobody reviewed it (defect H4). Same contract as
  `compiler-core/src/utils/snap.zig`.
- On mismatch a `<name>.snap.md.new` is written — review the diff and either
  promote it or fix the underlying bug. `*.snap.md.new` is git-ignored.
- Promote only intentional protocol/output changes; surprise changes usually
  signal a regression.
