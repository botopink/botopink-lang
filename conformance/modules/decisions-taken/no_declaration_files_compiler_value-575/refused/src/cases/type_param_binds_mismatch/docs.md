> Decision 575 (5) — the type argument of a `comptime t: type<T>` binds
> `T`: here `T` is already `i32` from the declaration pattern `fn() -> T`,
> so the type argument `string` is refused where it is written.
