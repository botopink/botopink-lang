# type_parameter_unbound

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> A function's or a method's type parameter is **bound by a parameter** (decision
> 668): it occurs in a parameter's type — directly (`x: T`), inside one
> (`items: Array<T>`, `f: fn(T) -> R`, `self: Self<Array<E>>`), or as the type
> token `comptime t: type<T>` —, and the return type follows from the arguments.
> The return type alone never binds one: `fn first<T>(r: Registry) -> ?T` is
> `type-parameter-unbound` at the declaration, naming `T`, since nothing at a call
> would fix `T` but the caller's wish. A caller that names the type passes it as
> the token (`fn failed<T>(comptime t: type<T>, message: string)`, called
> `failed(i32, "down")`); a method that holds only for some receivers says so in
> `self`'s type (`flatten<E>(self: Self<Array<E>>)`); where no type is meant the
> answer is `unknown`.
