# block_break_reaches_loop

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A block is a scope of the enclosing function, never a closure (decision 541): an `await` in a block
> or in a `case` arm's block waits for the enclosing task, a `yield` feeds the enclosing generator, and
> a bare `break` leaves the enclosing loop. A block that ends a function body is its tail:
