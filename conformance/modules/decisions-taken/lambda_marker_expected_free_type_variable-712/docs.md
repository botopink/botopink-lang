# Decision 712 — B-116 P1's choices where no decision spoke, by the step's own list:

The example hands three typed function expressions to `run<R>(make: fn() -> R)`, whose expected return type `R` is a free type variable. The typed forms carry their own marker, and `R` is bound from what each one writes. `async fn() -> Async<i32> { … }` binds `R` to `Async<i32>`, which `main` awaits, printing `2`. `iter fn() -> Iter<i32> { … }` binds it to `Iter<i32>`, which the `for` walks, printing `1` and `2`. The unmarked `fn() -> i32 { … }` binds it to `i32`, printing `3`. A bare lambda that nothing types, `run({ async -> 2 })`, is `lambda-untyped`. Passing a lambda where the expected type is no function type is left to ordinary unification. Both answers stand as built until B-116 P4's codemod has run; then both are refused.

The program prints `2`, `1`, `2` and `3`.

Cells in this repository that bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/cells/marker_lambda_async`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/marker_lambda_iter`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/marker_lambda_without_expected_type`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/marker_lambda_type_mismatch`.

[draft/main.bp](draft/main.bp)
