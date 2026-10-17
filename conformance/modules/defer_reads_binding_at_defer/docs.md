# defer_reads_binding_at_defer

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> The names a deferred expression reads bind where `defer` is written; only their values are read late. A `val`
> written after the `defer` that shadows a name the deferred expression reads is another binding, and the
> deferred expression does not see it:
