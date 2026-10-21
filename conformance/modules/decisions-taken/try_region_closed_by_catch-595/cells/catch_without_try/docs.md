# catch_without_try

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A `catch` written after a call with no `try` before it (`parse(raw) catch 0l`) closes a region that
> holds no `try`, even when the call answers a `Result`, and is refused the same way: write
> `try parse(raw) catch 0l`:
