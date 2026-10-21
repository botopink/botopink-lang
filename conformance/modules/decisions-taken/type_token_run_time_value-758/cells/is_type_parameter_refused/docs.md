# is_type_parameter_refused

The reference text this cell shows (from `conformance/docs.md`, § Union types, `unknown`, and `is`):

> A type parameter is erased at run time, so `v is T` with `T` a type parameter
> of the enclosing function (or of its type) can be decided by no target: it is
> refused at the test, `is-type-parameter`, naming the parameter and the two forms
> that work, `comptime t: type<T>` and `t: type<T>` (decisions 667, 758):
