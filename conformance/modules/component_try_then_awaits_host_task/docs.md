# component_try_then_awaits_host_task

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Only a component whose own body awaits is a state machine** (decision 504),
> on every target: it writes `await` or `uses` an asynchronous hook (375 (1)).
> Calling a component runs nothing, so one that composes others stays direct
> even when it receives a component as a value; the render runs a direct
> component in place and waits only on a marked one, so a synchronous component
> pays nothing and a component waiting on the host (`delay`) lets the render go
> on once its task settles (`modules/component_awaits_host_task`). A body that
> keeps a bare `try` and then awaits is one too: the `try` leaves early with the
> error before the wait, and past it the render waits on the host as before.
