# result_wide_payloads

The value a `@Result` holds is whole whatever its type: an `f64` or an `i64` comes back unchanged through `unwrapOr`, a `case` arm's binder, `try`, `try … catch` and `map`.
