# parameter_defaults_record

The reference text this cell shows (from `conformance/docs.md`, § Parameters with defaults):

> A call **may leave out an argument whose parameter declares a default**, and the
> declared expression is what the function receives. A default may be declared on
> a free `fn`, on a record's fields (where it is the constructor's default), on a
> variant's payload and on a method — including a `behavior`'s `default fn`, which
> is where `"hello".slice(1)` gets its open end from (`slice(self, start: i32,
> end: ?i32 = null)`). Wherever it is declared, **a default is trailing**: a
> parameter or field with a default is followed only by others with defaults
> (`fn lead(a: i32 = 1, b: i32)` and `type Port(number: i32 = 80, host: string)`
> are refused at `b` and `host`).
