# context_optional_wide_number_through_scope

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> a value of any
> type crosses it, an `f64` or an `i64` provided or rendered there included —
> and a `?f64` or a `?i64`, with its number or `null`.

`Root` provides a `?f64` and a `?i64` twice — `1.25` and `9000000000`, then `null` and `null` —; `Label` reads them with `use context` and narrows them: `2.5 9000000001`, then `no rate no total`, on every target.
