# external_library_source_beside_wrap

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A decorator of the same module that wraps a function (`compiler.wrapWith`) does not lose a library's `compiler.implement` either.

Green before the fix of the re-analysis: the module's first analysis already kept the implementation, so this cell is a regression oracle, not a reproduction.
