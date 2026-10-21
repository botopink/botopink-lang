# Decision 129 — Type aliases: four restrictions stand, `as` reaches an imported alias

`shapes` declares the generic alias `Pair<A, B>` for a tuple, and `main` imports it under another name with `as`: `P` is legal, a name the checker alone knows — the alias has no emitted identity, so nothing of `P` reaches the compiled program. `Id` is a plain local alias of `i32`. `swap` writes `P<Id, string>` with both arguments and answers the tuple reversed. `left` then writes `P` with no arguments: a generic alias is never read as `P<fresh, fresh>`, and the program is refused at that `P` with `type-alias-arity`. The decision's three other refusals each stop a program of their own, so they are not in this one: a parameter default on an alias (`type P<T = i32> = …`, `type-alias-generic-default`, at the parse), an annotation on an alias (`type-alias-annotated`), and an alias taking a name already in scope (`type Dict = i32;`, `type-alias-name-taken` — an alias never shadows).

Cells in this repository that also bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/cells/type_alias`, `modules/type/run/src/cases/type_alias_declarations`.

[draft/main.bp](draft/main.bp) · [draft/shapes.bp](draft/shapes.bp)
