# async_block_both

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> An **await channel** is a `Async`, `Component` or `AsyncIter` return, an
> `async { }` block or a `stream` loop; `await` anywhere else is
> `await-without-async`. An ordinary function that holds a task either
> returns an `Async` too or hands the task on.
>
> **`async { … }` — a task in the middle of a function** (decision 124). The block
> creates a `Async` without declaring a separate function, in **any** function:
> it waits for nothing, it creates the task.
