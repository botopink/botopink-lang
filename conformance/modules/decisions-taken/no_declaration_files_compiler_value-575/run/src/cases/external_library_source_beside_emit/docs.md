# external_library_source_beside_emit

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> Nor does a decorator of the same module that emits a declaration.

Green before the fix of the re-analysis: the module's first analysis already kept the implementation, so this cell is a regression oracle, not a reproduction.
