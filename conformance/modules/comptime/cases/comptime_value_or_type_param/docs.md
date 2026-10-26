# comptime_value_or_type_param

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> A `comptime` parameter may take **a value or a type** (decision 297):
> `comptime source: Box<T> | type<T>`. A `Box<T>` argument binds `T` from
> it; a type argument binds `T` to that type; the body tells them apart with
> `source is type`, decided while the program compiles — only the branch taken
> is emitted, and where `source is type` holds, reading `source` is
> `type-arg-read`. The argument of an ordinary function's `comptime` parameter is
> known at compile time: a local or a non-`comptime` parameter is
> `comptime-arg-not-known` at the argument.
