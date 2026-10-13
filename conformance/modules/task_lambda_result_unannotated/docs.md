# task_lambda_result_unannotated

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> The lambda's type is the same written or not: bound without an annotation
> (`val failing = { n -> async { throw "inner"; } }`) it is still a function
> answering `@Task<@Result<…>>`, and its `await` reads back as `Error(e)`; a
> lambda a function or method returns takes its parameters from the declared
> `fn(n: i32) -> …`, so `n.toString()` in it resolves:
