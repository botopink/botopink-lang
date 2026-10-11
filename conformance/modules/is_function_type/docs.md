# is_function_type

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> `x is fn(<params>) -> T` narrows an `unknown` to that function type, and a call
> through the narrowed name type-checks against it (decision 254) — the form a
> catalogue of factories held as `unknown` is read with. Calling an `unknown`
> without the test is the refusal above. The run-time check is the **arity**, on
> every target, because a function value carries no trace of its parameter or
> return types: erlang and beam test `is_function(F, N)`, commonJS `typeof f ===
> "function" && f.length === N`, and wasm boxes a function value entering an
> `unknown` slot under a descriptor naming its arity and compares that
> descriptor. A function of the right arity and another return type passes the
> test; what it answers is the caller's to trust.
