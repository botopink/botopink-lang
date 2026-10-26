# try_block_catch_void_statement

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A region whose value is `void` is a statement, and its handler is a block with at least one
> statement. An empty handler `catch { }` is refused `catch-empty`: a failure is handled (a value, a
> statement, a `throw`) or left to propagate, never swallowed in silence:
