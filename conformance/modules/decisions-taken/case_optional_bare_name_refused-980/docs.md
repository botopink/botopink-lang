# Decision 980 — A `?T` is matched by `null` and `_` alone: `case x { null { … } _ { … } }`, the second arm reading the value as `x!` (330); a binder arm is `case-bare-name-arm` (602) and a variant pattern over a `?T` (`.Some(v)`, `.None`, `Option.Some(value: v)`) is a located error naming the `null` form; restates 54 with 951 folded in, replacing them.

[cells/case_optional_bare_name_refused/src/main.bp](cells/case_optional_bare_name_refused/src/main.bp)
[cells/case_optional_variant_pattern_refused/src/main.bp](cells/case_optional_variant_pattern_refused/src/main.bp)
[cells/optional_case_null_and_binder/src/main.bp](cells/optional_case_null_and_binder/src/main.bp)
