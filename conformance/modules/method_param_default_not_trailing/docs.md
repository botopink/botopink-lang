# method_param_default_not_trailing

The reference text this cell shows (from `conformance/docs.md`, § Parameters with defaults):

> end: ?i32 = null)`). Wherever it is declared, **a default is trailing**: a
> parameter or field with a default is followed only by others with defaults
> (`fn lead(a: i32 = 1, b: i32)` and `type Port(number: i32 = 80, host: string)`
> are refused at `b` and `host`; the diagnostic is `fn-param-default-trailing-only` for a function's or a method's parameters and `field-default-trailing-only` for a record's fields and a variant's payload).
