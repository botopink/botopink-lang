# Decision 25 — Does `is` carry a pattern?

The example walks a list of `Token`s, a sum type with two payload variants and a unit one. For each token it asks `t is Token.Num` and keeps the answer in a `bool`: the test says which variant the value is and nothing more, so no payload name comes into scope. `describe` uses the same kind of test in an `if` to pick out `Eof` early, and then reads the payloads with a `case`, whose arms `Text(v)` and `Num(n)` are what bind `v` and `n`, with exhaustiveness checked over the three variants. The program prints, per token, `false` / `text hi`, `true` / `number 3`, `false` / `end`. Writing `t is Token.Num(n)` to get at the payload is not a second way to destructure: it is refused at the pattern (`is-variant-binding`).

Cells in this repository that also bear on it: `modules/is/run/src/cases/is_enum_variant`, `modules/is/run/src/cases/is_truth_table`, `modules/decisions-taken/comptime_param_value_or_type-297/refused/src/cases/is_type_outside_value_or_type`, `modules/decisions-taken/pattern_as_binding_refused-11/cells/assert_is_pattern` (the refusal, `is-variant-binding`).

[draft/main.bp](draft/main.bp)
