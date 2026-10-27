# Decision 601 — A value of an enum section prints as the leaf's whole path, as written, on every target.

A value of an enum section prints as the leaf's whole path, as it is written. `Token.Color.White` prints
`Token.Color.White` and `Token.Layout.Break.After` prints `Token.Layout.Break.After`; `Token.After`, a leaf of the same
name at the top level, stays a text of its own, `Token.After`. A value written with the leading dot, `.Color.Black`,
prints its whole path too, and so does every other place that writes a value as text: `string + enum` gives
`picked Token.Color.Black`, a template hole the same text, and a list prints each item's path. No name of the
backend's own — a section's wrapper record, `_inner`, `Bp__Token__Color` — reaches the output, on any of the four targets.

Cells that also bear on it: `modules/decisions-taken/comptime_runs_at_build-331/run/src/cases/comptime_enum_section_value`, `modules/enum/run/src/cases/enum_section_expected_type`,
`modules/enum/cases/enum_section_ambiguous_path`, `modules/enum/run/src/cases/enum_section_leaf_beside_variant`.

[cases/enum_section_prints_full_path/src/main.bp](cases/enum_section_prints_full_path/src/main.bp)
