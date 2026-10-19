# Decision 668 — A function's type parameter is always bound by a parameter, never by the return type alone.

Every type parameter of a function is bound by a parameter, and the return type then follows from the arguments.
`first<T>` binds `T` through `items: T[]`, `apply<T, R>` binds both through `value: T` and `f: fn(x: T) -> R`, and
`absent<T>` binds it through the type token `comptime t: type<T>`, so `absent(string)` is a `?string`. `nothing<T>()`
names `T` only in its return type: nothing at a call fixes `T` but the caller's wish, and its body cannot act on it, so
the declaration is refused at `T`, `type-parameter-unbound`, and the program does not run. Written with `absent`'s token
it would print `3`, `20`, `null`, `null`.

[draft/main.bp](draft/main.bp)
