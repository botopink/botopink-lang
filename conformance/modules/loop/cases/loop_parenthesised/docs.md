# loop_parenthesised

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> `loop (xs) { x -> … }` and `loop (cond)` are `removed-loop-parenthesised`, naming `for` and `while`. `while` and `loop` bind nothing, so a binder on one is `loop-binds-nothing`, refused at the binder. `loop await` does not exist either: a stream is walked with `for await`, and the parser refuses the `await` after `loop`, located at it.
