# std_failure_types

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> std's `failure` module declares the types (decisions 489, 492):
> `HostErrorName` (`Error`, `Throw`, `Exit`), `HostError(message, kind, name,
> detail)` with `detail: ?string`, and `Failure(message, kind)`, whose `kind` is
> `"panic"`, `"host"` or `"crash"`:
