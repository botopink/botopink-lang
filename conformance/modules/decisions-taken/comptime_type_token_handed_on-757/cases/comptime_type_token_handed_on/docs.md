# comptime_type_token_handed_on

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A type to test against travels as a `comptime t: type<T>` parameter — `fn
> count<T>(self: Registry, comptime t: type<T>) -> i32 { … if (e is t) … }`, called
> `r.count(Users)`, `T` inferred from `t`. The parameter is the function's
> specialisation (decisions 417, 757): the call compiles to the function's copy for
> `Users`, where `t` is `Users` — `v is t` is `v is Users`, an ordinary run-time test
> with one answer on every target, narrowing `v` to `T` in its branch — and `t`
> handed on to another call (`self.count(t)`) is a `comptime` argument known at
> build, the call of the copy for the same type. The type itself never reaches run
> time. Never a comparison by name.
