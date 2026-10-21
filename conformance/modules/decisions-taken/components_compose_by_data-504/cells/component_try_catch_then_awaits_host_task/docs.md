# component_try_catch_then_awaits_host_task

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> A body that
> keeps a bare `try` and then awaits is one too: the `try` leaves early with the
> error before the wait, and past it the render waits on the host as before.
> A `try … catch` never leaves: the `catch` value stands for the error and the
> body waits on the host the same way.

`load("x")` parses `7` and waits on `delay` (`loaded 14`); `load("")` takes the `catch` value `1` and waits the same way (`loaded 2`), on every target and both wasm hosts.
