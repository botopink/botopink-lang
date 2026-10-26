# main_async_ok_exits_zero

The reference text this cell shows (from `conformance/docs.md`, § Builtins):

> An entry `main` that answers `Error(e)` writes `failed: <text>` to stderr — `<text>` what `print` writes for
> `e` — and the process exits 1 on every target, `async` or not (decision 999); `Ok` and `void` exit 0, and a
> crash keeps the text and the status of decision 535. Only the entry: a loaded package's `main` answers
> `run()`'s `.Failed`, and prints nothing.
