# external_library_source_beside_member

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A library's `compiler.implement` survives the module's re-analysis: a decorator of the same module that adds a member (`compiler.addMember`) does not lose it.

Green before the fix of the re-analysis: the module's first analysis already kept the implementation, so this cell is a regression oracle, not a reproduction.
