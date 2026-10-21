# task_lambda_result_unannotated

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> A lambda answering an `async { }` block is typed where it is written, as any
> lambda is (decision 583): bound without an annotation (`val failing = { n ->
> async { throw "inner"; } }`) it is refused `lambda-untyped`; a lambda a
> function or method returns takes its parameters from the declared `fn(n:
> i32) -> …`, so `n.toString()` in it resolves:
