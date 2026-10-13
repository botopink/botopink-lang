# optional_if_null_initializer

An `if` one of whose arms is `null`, written into a `?T` slot — a `val`, a `var` assignment, a
`return` — is absent when that arm runs and the other arm's value otherwise, a present `0` included,
through an `else if` chain and for a `?f64`, on every target (decision 330).
