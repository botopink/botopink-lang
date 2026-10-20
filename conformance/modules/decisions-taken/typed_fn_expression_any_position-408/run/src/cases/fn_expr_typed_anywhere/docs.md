# fn_expr_typed_anywhere

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda's parameters take the types of the position it is passed to or the
> `val` it is bound to; `fn(a, b) { … }` is the same function written with
> `fn`. The braced lambda stays untyped (decision 328): `val inc: fn(x: i32) ->
> i32 = { x -> x + 1 };`. The typed function expression `fn(x: T, …) -> R { … }`
> is legal in every position (decision 408) — a `val`, a `var`, an argument, a
> return and the member a decorator hands to `compiler.addMember(name, fn…)` alike;
> every parameter typed or none, and with a parameter typed the `-> R` written (`-> void` when it answers nothing, decision 622). Where the
> position has a type, the written types are checked against it — `val f: fn(x:
> i32) -> i32 = fn(x: string) -> i32 { … };` is refused at the expression; with
> none, the written types are the function's:
