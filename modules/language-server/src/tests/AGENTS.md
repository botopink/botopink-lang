# language-server/src/tests

> Path: `modules/language-server/src/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Feature-level tests for LSP behaviour and diagnostics. Every file here is
registered in [`../test_root.zig`](../test_root.zig) — add new suites there.

## Tree

```text
tests/
├── AGENTS.md
├── _warmup.zig           ← runs first: lazy-inits compiler-core's stdlib template
├── helpers.zig           ← assertion + setup helpers (compile, compileEval, multi-module)
├── snapshot.zig          ← snapshot read/write + the per-request renderers
├── snapshot_test.zig     ← unit tests for `snapshot.appendSourceWithCursor`
├── messages.zig          ← JSON-RPC frame reader (`messages.readMessage`)
├── diagnostics.zig       ← publishDiagnostics
├── formatting.zig        ← textDocument/formatting
├── hover.zig             ← textDocument/hover
├── definition.zig        ← textDocument/definition
├── symbols.zig           ← textDocument/documentSymbol
├── completion.zig        ← textDocument/completion (engine path: `engine.completion`)
├── completion_server.zig ← textDocument/completion through `Server.completionItems`
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

`completion_server.zig` drives the server's own decision — compile, then complete
with the module's bindings or without any — because the engine tests stayed green
while the server answered `null` for every document that did not type-check
(front 14 step 1). It builds a `Server` with `std.testing.io` and calls
`completionItems`, so no JSON frame is written; the framing itself is not covered.

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
  `.botopinkbuild/lsp-roots-*` for the `BOTOPINK_LIB_ROOTS` tests and
  `.botopinkbuild/lsp-graph-*` for the graph-problem tests (a dependency no root
  carries, a `files` entry that cannot be read, a `.bp` of the project's own
  `src` that cannot be read — mode `000`, which asserts the diagnostic is on that
  file and skips when the run is root and can read it anyway — and a healthy
  project that must report none), and resolves a real sibling project
  (`../../../rakun/examples/rakun/`) for the cache test — that test skips when the
  sibling checkout is absent. The graph-problem tests assert the **message, the
  manifest URI and the 0-based line/column** of the entry; the server half
  (`publishGraphProblems`) writes JSON-RPC frames to stdout, which a test cannot
  capture without taking over the test runner's own stream, so it is covered by
  the graph's contract rather than by a frame assertion.

`lifecycle.zig` drives the in-memory `FileCache` directly (no runtime, no disk).

Four tests here are **front 11's carve-out**, marked by a
`front 11 carve-out` banner comment: `hover.zig`'s two optional-rendering tests,
`signature_help.zig`'s `sig_optional_params` and `code_actions.zig`'s
`code_action_annotation_optional`. They belong with `engine.renderType`, which is
front 11's file — every one of them asserts that no rendered type contains
`optional<`, the checker's name for a type the surface only spells `?T`.

## Snapshot workflow

- Snapshots live under `../../snapshots/lsp/`.
- A **missing** snapshot fails the test (`error.SnapshotMissing`) and writes the
  candidate baseline as `<name>.snap.md.new`; set `BOTOPINK_SNAP_CREATE=1` to
  record it. Before spec 06 step 1 a first recording was accepted silently and
  nobody reviewed it (defect H4). Same contract as
  `compiler-core/src/utils/snap.zig`.
- `BOTOPINK_SNAP_TRACE=<file>` appends every checked snapshot path to the same
  trace as `compiler-core/src/utils/snap.zig`. The asserts take a literal slug,
  not `@src()`, so the location column is `-`; `scripts/snap_audit.sh
  --mode=review` resolves the test from the slug literal — keep one literal per
  slug.
- On mismatch a `<name>.snap.md.new` is written — review the diff and either
  promote it or fix the underlying bug. `*.snap.md.new` is git-ignored.
- Promote only intentional protocol/output changes; surprise changes usually
  signal a regression.
- Verify a changed response against the real server before promoting: `zig build`
  then drive `zig-out/bin/botopink-lsp` over stdio from a scratch project. LSP
  positions are 0-based — recount the cursor rather than trusting the fixture's
  comment.

## What the renderers print (spec 06, wave "language server")

A snapshot has to show what the request actually returns, or a test passes on a
rendering that hides the bug:

- `assertDocumentSymbols` prints `range`, `selectionRange` **and** the children,
  indented — an enum's variants and a record's fields are part of the outline.
- `assertCodeActions` prints each action's `documentChanges` edits (range →
  `newText`), not just kind and title.
- `assertSemanticTokens` prints the decoded tokens **and** the delta-encoded
  wire payload (`engine.encodeSemanticTokens`), so an encoding regression shows.
- `assertDefinitionIn` underlines the result in the file its URI names: pass the
  dependency's source as a `TargetSource` for a cross-module result. Plain
  `assertDefinition` underlines the document under the cursor only.

## Tests without a snapshot, on purpose

Some behaviour is an invariant a rendered file cannot state. These tests assert
it inline and deliberately write no snapshot — do not "restore" one:

- `definition.zig` "returned Location carries the correct URI" (the rendering
  duplicated `definition_val_usage`; the URI round-trip is the point).
- `references.zig` "returned ranges match token positions" (a subset of
  `references_include_decl`; every range is checked end-included instead).
- `signature_help.zig` "same-typed params get distinct, locatable labels"
  (`ParameterInformation.label` is highlighted by substring, so two same-typed
  parameters must not share a label).
