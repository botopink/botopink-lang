# Decision 501 — A `bigint`'s type stays static: no widening to `unknown`, no `is` test, no `comptime` computing one.

In the example every `bigint` is known to be one from its type alone. `big` is the literal `9007199254740993n`, which `print` takes through its variadic `unknown` and prints whole. `total` folds a `bigint[]` into a `bigint` with `+`. `show` takes the union `i32 | bigint`, which is legal, and hands its argument to `print` without asking which member it holds. That question has no answer: `a is bigint`, or `a is i32` on a value that may hold a `bigint`, is refused `bigint-type-test`. Binding `big` to an `unknown` is refused `bigint-widened`, and a `comptime` computing a `bigint` is refused `comptime-bigint`. Those three lines are not in the program because each is a refusal; the program holds what stays legal.

The program prints `9007199254740993`, `9007199254741000`, `5` and `18014398509481986`.

Cells in this repository that bear on it: `modules/decisions-taken/bigint_decimal_strict_json-332/refused/src/cases/bigint_type_test`, `modules/decisions-taken/bigint_decimal_strict_json-332/refused/src/cases/bigint_into_unknown`, `modules/decisions-taken/bigint_decimal_strict_json-332/refused/src/cases/bigint_comptime`, `modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_arithmetic`, `modules/decisions-taken/bigint_decimal_strict_json-332/run/src/cases/bigint_in_containers`.

[draft/main.bp](draft/main.bp)
