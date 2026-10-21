# lambda_tail_iter_loop

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> With `iter` or `stream` in front, the loop is an expression worth the iterator
> (or the stream), `T` being the type of its `yield` / `break v`.

A lambda whose tail expression is that loop answers the generator: `for` over the
call walks 1, 2, 3 on every target.
