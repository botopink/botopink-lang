# Decision 423 — A derived type carries the fields and their annotations only.

`Recipe` has two fields, an annotation on `title`, a method and an `implement Titled` clause. `Type.pick(Recipe, .title)` builds `RecipeTitle`, and what it carries is the picked field with its annotation, nothing more: the program prints `title 1` — the field and its one annotation. `RecipeTitle` has no `heading` method and does not implement `Titled`; behaviour for it is written on it, here the free function `heading(r: RecipeTitle)`, which prints `title: Moqueca`, while `Recipe`'s own method still prints `MOQUECA`.

Cells in this repository that also bear on it: `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_functions`, `modules/derived/cells/derived_type_declarations`, `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_decorated`.

[draft/main.bp](draft/main.bp) · [draft/comptime/labels.bp](draft/comptime/labels.bp)
