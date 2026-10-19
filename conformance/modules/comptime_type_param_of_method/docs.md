# comptime_type_param_of_method

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> A `comptime` parameter of the enclosing function or type method is itself known
> at build: handed on to another `comptime` parameter it is a known argument, a
> type method's (`fn times(self: Self, comptime n: i32)`, `scaled(n, …)`) as a
> function's.
