# comptime_fn_name_shadowed_by_local

The reference text this cell shows (from `conformance/docs.md`, § Comptime parameters, beside `syntax x: T`):

> A function's name follows the scope rule whatever its parameters: a
> parameter or a local named like a function with `comptime` parameters is
> the value a call there calls, and every argument of that call is the
> value's — none of them is taken as a `comptime` one.
