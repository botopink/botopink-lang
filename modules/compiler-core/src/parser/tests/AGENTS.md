# compiler-core/src/parser/tests

> Path: `modules/compiler-core/src/parser/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Parser tests, split by sub-grammar. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; shared harness lives in `helpers.zig`.
AST golden snapshots live in `modules/compiler-core/snapshots/parser/`.
`assertParser` wraps its snapshot call in `utils/snap.zig` `traceEnter(loc)`/`traceLeave`,
so `BOTOPINK_SNAP_TRACE=<file>` records the test `file:line`.

`decision8.zig` holds the grammar of [decision 8](../../../../../../../specs/1.0.4-beta/08-review-backlog/decision-8-language.md) rows N19–N22 — `unknown`,
union types, the `is` expression and the `Pattern { body }` `case` arm — in that order, one section
per row. A fixture there pins what *parses*; what it means is the checker half's, so a fixture may
still red in inference until N19–N22's checker rows land.

`language_surface.zig` holds front 15's rows — the forms the project's documents write against the
grammar that has to accept them (`specs/1.0.10-beta/00-compiler-carry-over/15-language-surface/`).
One section per row, named `R<n>`. A row that **hoists a rule** carries its regressions beside its
new forms: the point of hoisting is that the arms which already worked keep working, so the two are
asserted in one test. R10 is the decided-against forms (step 3): one
`expectErrorAt(src, kind, line, col)` per kind — the shared harness in `helpers.zig`, which
`surface.zig`'s `expectError` is an alias of — beside an `assertParser` of the neighbouring forms
that still parse, and one rendered-message case so the code, the caption and the hint are pinned.

`surface.zig` holds the front-12 step-2 acceptance cases (`type`, `behavior`, field lists, separators) as structural
assertions — no snapshots — and compares the JSON dump of each old spelling with its new spelling.

`declarations.zig` ends with front 17's rows (decision 38): `var` at module level
(`ValDecl.mutable`), `#[@BeamMemory.Ets(keyed = true)] var` carrying the annotation on
the binding with its `keyed` label, and an unlabelled argument having no label —
structural assertions, no snapshot. `surface.zig` carries the front's two `expectError`
cases: an annotated `val` shorthand (`#[@BeamMemory.Ets] val add = fn …`) is
`unexpectedToken` **at the annotation** (`1:1`), and `var` reads no shorthand at all.

`errors.zig` carries the static-prefix cells of `use` (front 19 of 1.0.10-beta): the
bare `use …;` after a `return`, row 4b (`val c = use …` after a `return`, refused at the
`use` token) and row 4c (a `use` inside an `if`'s own block); `expressions.zig`'s
`use multiple hooks in function` and `errors.zig`'s `lambda return does not end the
enclosing static prefix` pin what still parses — a lambda body is a fresh scope.

`type_alias.zig` holds the type-alias declaration (decision 118 rule 1): `[pub] type Name<A, B> = T;`
parses to `DeclKind.typeAlias` (structural assertions), `type Box<T>(v: T)` stays a record, and the
three refusals — a missing `;`, `type-alias-generic-default` at the `=`, `type-alias-annotated` at
the annotation.

When adding a test file here, register it in `../tests.zig` or it will not run.
