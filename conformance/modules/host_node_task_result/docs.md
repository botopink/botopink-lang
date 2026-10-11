# host_node_task_result

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A host that answers later** is declared with a `@Task` return (decision 126).
> Declared `-> @Task<@Result<T, E>>`, a rejected Promise (Node) or an
> `{error, R}` (Erlang) becomes `Error(…)`; declared `-> @Task<T>`, a rejection is
> a fatal host failure — that form is for a host that guarantees it does not fail.
