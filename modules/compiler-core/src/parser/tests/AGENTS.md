# compiler-core/src/parser/tests

> Path: `modules/compiler-core/src/parser/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Parser tests, split by sub-grammar. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; shared harness lives in `helpers.zig`.
AST golden snapshots live in `modules/compiler-core/snapshots/parser/`.
`assertParser` wraps its snapshot call in `utils/snap.zig` `traceEnter(loc)`/`traceLeave`,
so `BOTOPINK_SNAP_TRACE=<file>` records the test `file:line`.

`decision8.zig` holds the grammar of [decision 8](../../../../../specs) rows N19–N22 — `unknown`,
union types, the `is` expression and the `Pattern { body }` `case` arm — in that order, one section
per row. A fixture there pins what *parses*; what it means is the checker half's, so a fixture may
still red in inference until N19–N22's checker rows land.

`surface.zig` holds the front-12 step-2 acceptance cases (`type`, `behavior`, field lists, separators) as structural
assertions — no snapshots — and compares the JSON dump of each old spelling with its new spelling.

When adding a test file here, register it in `../tests.zig` or it will not run.
