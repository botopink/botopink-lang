# lambda_semicolon_not_a_value

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda answers its last expression written without `;` (decision 541): `{ x -> x + 1 }`
> answers `x + 1`. With `;` the expression is a statement and the lambda answers nothing, so it stands
> where a function returning `void` is expected even though its last call answers a value, and where
> a function returning a value is expected it is refused, at the lambda. (An untyped `fn(x) { … }`
> keeps the value of its last statement, `;` or not; a typed function expression with `-> R` refuses
> a `;`-terminated last expression, as above.)
