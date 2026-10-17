# host_node_task_result

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A host that answers later** is declared with a `@Task` return (decision 126).
> With `result: true` and `-> @Task<@Result<T, HostError>>`, a rejected Promise
> (Node) or a raise or `{error, R}` (Erlang) becomes `Error(HostError(…))`;
> declared `-> @Task<T>`, a rejection is a fatal host failure — that form is for a
> host that guarantees it does not fail.
