# composition_function_again

Decision 815 (with 819 (1)): `Composition<T>` is `fn(scope: Scope, key: Place) -> T | Async<T>`. A
lambda of that type is a component without hooks, which `run` resolves; called by hand it takes a
`Scope` and a `Place` and answers its value. A function answering a member of a union fits where one
answering the union is expected (returns only): `viewOf(member)`.

[src/main.bp](src/main.bp)
