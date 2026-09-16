# compiler-core/src/parser/tests

> Path: `modules/compiler-core/src/parser/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Parser tests, split by sub-grammar. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; shared harness lives in `helpers.zig`.
AST golden snapshots live in `modules/compiler-core/snapshots/parser/`.
`assertParser` wraps its snapshot call in `utils/snap.zig` `traceEnter(loc)`/`traceLeave`,
so `BOTOPINK_SNAP_TRACE=<file>` records the test `file:line`.

When adding a test file here, register it in `../tests.zig` or it will not run.
