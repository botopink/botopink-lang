# block_jump_label_continue_nested_shapes

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> A label on `continue` names a loop as it does on `break`: `continue :outer` from a nested loop's body, or
> from a `case` arm's block, ends the inner loops and starts the named loop's next round.

Two shapes of it: the named loop's body holds a `while` that continues it, and one inner loop continues two
enclosing labelled loops.
