# compile_executor_handle_mistyped

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> Inside the executor the decorator's `syntax decl` handle is the annotated
> declaration itself as a run-time value, with its declared type (decision 581
> (2)): `add(Module(name: name, lifecycle: lifecycle, make: decl))` is checked
> against `make`'s type for each annotated declaration, and a declaration whose
> type does not fit is refused at its annotation, the decorator's
> `compiler.compile` call its `called from` line (decision 567).
