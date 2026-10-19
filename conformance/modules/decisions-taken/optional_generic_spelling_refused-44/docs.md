# Decision 44 — `optional<i32>` is not a valid spelling

`half` answers `?i32`: a number when `n` is even, `null` when it is not. The first `val` spells the optional the one way the language has, `?i32`, and reads it with `??`. The second writes `optional<i32>` — the checker's own internal name for the same type — and the program stops there: the annotation is refused at `optional`, and the refusal names `?T` as the spelling to write, exactly as `Option<T>` and `Optional<T>` are refused. Nothing runs; had the second line read `val odd: ?i32 = half(7);`, the program would print `4` and `-1`.

Cells in this repository that also bear on it: `modules/decisions-taken/optional_typescript_operators-330/cases/optional_operators`, `modules/decisions-taken/optional_case_null_and_binder-54/cases/optional_null_pattern`, `modules/decisions-taken/optional_typescript_operators-330/cases/optional_has_no_methods`.

[draft/main.bp](draft/main.bp)
