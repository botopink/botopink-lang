# comptime_optional_fn_tested_against_null

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A function or a type argument is checked at the argument and never run at
> build (decision 364 (3)). An optional function-typed `comptime` argument is
> tested against `null` as any `?T` is — `if (rule == null) { … }`, the function
> type no exception (decision 735): `#[check("…")]` on a rule function and
> `#[check("…", rule)]` on a type are one decorator, and an ordinary function's
> `comptime rule: ?fn(v: T) -> bool` takes `null` or a function the same way.
