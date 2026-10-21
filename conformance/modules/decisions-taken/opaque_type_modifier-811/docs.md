# Decision 811 — `opaque` is a modifier of a type: its constructor and its fields are used only inside the type's own methods; `Composition<T>` is an opaque type holding the function, made by the compiler through a method without `pub` and run through its `pub fn resolve`; `Scope` and `Module` are opaque; answers 809-b; amends 388 (2), 792 (3), 809 (1), (6), 810 (5).

`opaque`, written before `type` (`[pub] opaque type X(…) { … }`), closes a record to everything outside its own
methods: `X(…)` is written only inside them and a field is read only there — not elsewhere in the type's module
either (decision 814 (1)); a method written without `pub` is called anywhere in the type's module and from no other
(814 (2)), the compiler's own lowering reaching one from any module under a name no source spells. Outside, an `X`
is named, passed, stored, compared with `==` and tested with `is` — the cell `opaque_type_through_methods`, on the
four targets, makes a `Token` through `Token.of`, reads it through its `pub` methods (one sharing a field's name),
calls its method without `pub` from a function of its module, keeps two in an array, compares them and tests one
out of a union.

Each refusal is located: `Token(…)` written in `main` is `opaque-construction`, naming the methods that make one
(`opaque_construction`); `t.uses` read in `main` is `opaque-field` (`opaque_field`), as a pattern of the fields is
(`opaque_pattern`); `Token.bumped(…)`, a method without `pub`, called from another module's `main` is
`opaque-method` (`opaque_method`).

std's `compiler.Module` is opaque (811 (4)): `compiler.load` answers one through its method without `pub`, and its
fields are read through `name()` and `path()` — the cells of decisions 786, 787, 792 and 806.

[cells/opaque_type_through_methods/src/main.bp](cells/opaque_type_through_methods/src/main.bp)
[cells/opaque_construction/src/main.bp](cells/opaque_construction/src/main.bp)
[cells/opaque_field/src/main.bp](cells/opaque_field/src/main.bp)
[cells/opaque_method/src/main.bp](cells/opaque_method/src/main.bp)
[cells/opaque_pattern/src/main.bp](cells/opaque_pattern/src/main.bp)
