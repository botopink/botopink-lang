# Decision 598 — `compiler.Field<T>` carries a field's default as `defaultValue`: the default as written, `null` when the field has none.

`#[describeDefaults]` reads `Profile`'s fields with `compiler.fields(decl)` and, for each `compiler.Field<T>`, tests `f.defaultValue != null` — the one test for "has a default" — and reads the default's code with `compiler.text(f.defaultValue!)`. The default is the code as written, never a value the build computed: `email has no default`, `name = defaultName()`, `age = 0` and `nickname = null` (a default of `null` is a default, so `defaultValue` holds the node `null`, not the absence). `main` prints the four lines the decorator recorded as typed meta, then builds a `Profile` with only `email` and prints `anonymous 0 -`: each default is evaluated where the record is built, at run time.

Cells in this repository that also bear on it: `modules/decisions-taken/derived_type_static_methods-307/run/src/cases/derived_type_functions`.

[draft/main.bp](draft/main.bp) · [draft/comptime/defaults.bp](draft/comptime/defaults.bp)
