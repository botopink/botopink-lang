# lambda_omits_trailing_parameters

Decision 888: an untyped lambda written with fewer parameters than the function type it meets takes
that type's arity, the omitted ones trailing and unnamed — `{ scope -> … }` and `{ -> … }` as a
`fn(scope: Scope, key: Place) -> T | Async<T>`, `{ x -> x }` as a `fn(T, i32) -> T` —, on every
target; one parameter too many stays `arity`.

[src/main.bp](src/main.bp)
