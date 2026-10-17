# async_block_both

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> An **await channel** is a `@Task`, `@Component` or `@Stream` return, an
> `async { }` block or a `stream` loop; `await` anywhere else is
> `await-without-async`. An ordinary function that holds a Task either
> returns a `@Task` too or hands the Task on.
>
> **`async { … }` — a Task in the middle of a function** (decision 124). The block
> creates a `@Task` without declaring a separate function, in **any** function:
> it waits for nothing, it creates the Task.
