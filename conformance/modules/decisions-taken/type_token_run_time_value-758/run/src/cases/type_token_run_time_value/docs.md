# type_token_run_time_value

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A type also travels as a run-time value (decision 758): `t: type<T>` without
> `comptime` is the type's identity, crossing to run time as a `Field(Book,
> "pages")` does — one function for every type, `t` handed on as any value
> (`self.count(t)`), and `T` still bound by the parameter, so a `-> ?T` stays typed.
> `x is t` is tested at run time by the same rules as the literal `x is Users`: a
> record and an enum by identity, a primitive by value as each target tests it. A
> run-time `t` handed to a `comptime t: type<T>` parameter is
> `comptime-arg-not-known`; `comptime t: type<T>` stays the form of every read at
> build.
