# Decision 583 — Every function is typed where it is written.

Each lambda in the example gets its type from where it is written. `apply`'s parameter `f: fn(i32) -> i32` types `{ n -> n * 2 }`, the annotation on `inc` types `{ n -> n + 1 }`, and `adder`'s return type types the lambda it returns. Where no position gives a type, the function is written in its typed form, `fn(n: f64) -> f64 { … }`, as `half` is. The last binding, `val later = { n -> n * 3 }`, has neither an annotation nor a typed position. The call `later(2)` on the next line does not type it after the fact, so the program is refused at the lambda with `lambda-untyped`, and the message names both fixes: write `fn(n: T) -> R { … }`, or type the `val`.

Cells in this repository that also bear on it: `modules/decisions-taken/lambda_types_from_context-328/cells/lambda_param_untyped_method_refused`.

[draft/main.bp](draft/main.bp)
