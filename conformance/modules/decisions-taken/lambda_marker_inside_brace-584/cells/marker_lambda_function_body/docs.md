# marker_lambda_function_body

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> A marked lambda's body is a function body, as an `iter fn`'s: a `return`
> leaves it — `return;` ends an iteration, `return v` is the iterator's `R`
> (553 (2)) — a `continue` at its top level is `continue-outside-loop`, and
> `break <value>` is `marker-lambda-break-value`.
