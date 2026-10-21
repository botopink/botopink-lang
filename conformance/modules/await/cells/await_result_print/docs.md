# await_result_print

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> An awaited `Result` is the value it is: `print` of `await f(x)` answers
> `Ok(21)` or `Error("negative")` on every target, for a generic `f`, a plain one
> and an `async { }` block that fails.
