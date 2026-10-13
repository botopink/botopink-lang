# std_failure_attempt

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **A crash is contained by `attempt`.** `@panic`, `@todo`, `x!` over `null`, a
> failed `assert`, an integer overflow or division by zero, and a raise from a
> host binding without `result: true` are defects, never in a signature. std's
> `failure.attempt(f)` runs `f` and answers `@Result<T, Failure>`: `Ok` of its
> value, or `Error(Failure(message, kind))` for the crash it caught — `kind` is
> `"panic"` for the program's own abort, its message the text the program wrote,
> and `"host"` for a host raise, its message the host's text (a JavaScript
> `Error`'s `message`, the erlang reason by `~tp`). The program goes on after a
> contained crash. On wasm `attempt` runs the thunk under wasm exception
> handling (decision 518): a program reaching it raises its aborts as an
> exception, which `attempt` catches as `panic`; a trap is no exception and
> ends the program.
