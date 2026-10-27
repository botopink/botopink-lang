# comptime_reflection_types_at_runtime

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> The records these reads answer are user surface with a run-time form (decision
> 1071 (1)): `compiler.Field`, `compiler.Method`, `compiler.Variant`,
> `compiler.Param`, `compiler.DeclAnnotation` and the enum `compiler.DeclKind`
> are std's types. Their fields are read as any record's; only std builds one —
> `Field(…)` written in a program is `opaque-construction`, the record named,
> never the variant `DeclKind.Field`.
