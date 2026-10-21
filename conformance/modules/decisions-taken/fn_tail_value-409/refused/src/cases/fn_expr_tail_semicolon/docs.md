# fn_expr_tail_semicolon

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda's and a function expression's last expression written without `;` is
> its value, as a named function's is (§ fn — function, decision 409):
> `val inc = fn(x: i32) -> i32 { x + 1 };`, `{ x -> x + 1 }`. With `;` a typed
> function expression's last expression is a statement, so one with `-> R` then
> needs a `return`:
