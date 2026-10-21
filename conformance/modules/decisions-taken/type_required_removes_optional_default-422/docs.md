# Decision 422 — `Type.required` removes a field's `?` and its `null` default together.

The example's `Recipe` has an optional `description` defaulting to `null` and an optional `servings` defaulting to `2`. `Type.required(Recipe)` answers `FullRecipe`. Its `description` is a plain `string` with no default, so `r.description.length()` needs no `?` and a `FullRecipe` must be given one. Its `servings` is an `i32` that keeps its default `2`. The program prints `no description` and `soup (3 chars, serves 2)`.

Cells in this repository that also bear on it: `modules/derived/cells/derived_type_declarations`, `modules/decisions-taken/derived_type_is_inline_type-629/refused/src/cases/record_spread_required`.

[draft/main.bp](draft/main.bp)
