# async_block_keeps_self

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> An `async { }` block is part of the function it sits in: it reads that
> function's `self` and locals, in a method, in a lambda the method answers
> and in a block nested in another.
