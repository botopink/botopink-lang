# language-server/src/tests — LSP feature test harness

> Path: `modules/language-server/src/tests/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Feature-level tests for LSP behaviour. One file per LSP feature; the
shared harness lives in `helpers.zig` + `snapshot.zig` +
`snapshot_test.zig`.

## Tree

```text
tests/
├── root.zig              ← test aggregator (entry for `zig build test`)
├── helpers.zig           ← assertion + setup helpers
├── snapshot.zig          ← snapshot read/write
├── snapshot_test.zig     ← shared snapshot test harness
├── code_actions.zig      ← textDocument/codeAction
├── completion.zig        ← textDocument/completion
├── definition.zig        ← textDocument/definition
├── diagnostics.zig       ← publishDiagnostics
├── folding_range.zig     ← textDocument/foldingRange
├── formatting.zig        ← textDocument/formatting
├── hover.zig             ← textDocument/hover
├── prepare_rename.zig    ← textDocument/prepareRename
├── references.zig        ← textDocument/references
├── rename.zig            ← textDocument/rename
├── signature_help.zig    ← textDocument/signatureHelp
├── symbols.zig           ← textDocument/documentSymbol
└── type_definition.zig   ← textDocument/typeDefinition
```

## How a test is shaped

Every feature file follows the same pattern: load a small `.bp` snippet,
construct a fake JSON-RPC request, invoke the engine, snapshot the
response. The shared harness handles framing and JSON serialisation so
each test focuses on its feature.

```zig
test "hover on val binding" {
    try expectHover(alloc, @src(),
        \\val pi = 3.14;
        \\val tau = pi * 2.0;
        ,
        .{ .line = 1, .col = 11 },  // cursor on `pi`
    );
}
```

The snapshot is keyed off `@src()` — see [`../docs.md`](../docs.md) for the
naming rules.

## Snapshot workflow

Same as the rest of the workspace:

1. First run creates `../../snapshots/lsp/<name>.snap.md`.
2. Subsequent runs compare. On mismatch a `<name>.snap.md.new` is written.
3. Review the `.new` file — promote it over the old `.snap.md` only when
   the change is intentional. Surprises are usually regressions.

Don't commit `.snap.md.new` files.

## Determinism

LSP responses must be byte-stable to make snapshot diffing useful:

- Sort arrays where the protocol does not specify order (e.g. completion
  items, document symbols).
- Strip absolute paths from URIs — substitute a project-relative form.
- Never include wall-clock timestamps.

The harness enforces some of this automatically; the rest is up to the
test author.

## See also

- LSP feature surface → [`../docs.md`](../docs.md).
- Snapshot fixtures → [`../../snapshots/lsp/AGENTS.md`](../../snapshots/lsp/AGENTS.md).
- Shared snapshot helpers reused from compiler-core →
  [`../../../compiler-core/src/utils/docs.md`](../../../compiler-core/src/utils/docs.md).
