> Decision 575 (5) — `type<T>` is the type of the type `T`: a `comptime`
> parameter written `comptime t: type<T>` takes a type, and the type
> argument binds `T` for the rest of the signature — here the decorator's
> declaration pattern `fn() -> T`, and in `orDefault` the fallback.
