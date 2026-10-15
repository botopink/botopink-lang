# block_jump_label_reaches_loop

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A labelled `break :outer` in a block or in a `case` arm's block leaves the loop it names, from however
> many loops in, and a bare `return` in a `case` arm that yields ends the enclosing generator, so
> nothing after the `case` is emitted:
