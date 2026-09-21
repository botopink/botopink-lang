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

`language_surface.zig` holds front 15's rows — the forms the project's documents write against the
grammar that has to accept them (`specs/1.0.5-beta/15-language-surface/`). One section per row, named
`R<n>`. A row that **hoists a rule** carries its regressions beside its new forms: the point of
hoisting is that the arms which already worked keep working, so the two are asserted in one test.

`surface.zig` holds the front-12 step-2 acceptance cases (`type`, `behavior`, field lists, separators) as structural
assertions — no snapshots — and compares the JSON dump of each old spelling with its new spelling.

`declarations.zig` ends with front 17's rows (decision 38): `var` at module level
(`ValDecl.mutable`), `#[@BeamMemory.Ets(keyed = true)] var` carrying the annotation on
the binding with its `keyed` label, and an unlabelled argument having no label —
structural assertions, no snapshot.

`errors.zig` carries the static-prefix cells of `use` (front 19 of 1.0.10-beta): the
bare `use …;` after a `return`, row 4b (`val c = use …` after a `return`, refused at the
`use` token) and row 4c (a `use` inside an `if`'s own block); `expressions.zig`'s
`use multiple hooks in function` and `errors.zig`'s `lambda return does not end the
enclosing static prefix` pin what still parses — a lambda body is a fresh scope.

When adding a test file here, register it in `../tests.zig` or it will not run.
