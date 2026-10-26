# optional_chain_lambda_generic

Decision 330: a `?.` chain read through a lambda parameter that a generic `apply<T, R>(x: T, f: fn(T) -> R)` types as
`?Holder` is the chain it is outside the lambda, though another record (`Other`) declares a field `entry` too: `a` when
every link is present, `none` at the absent one.
