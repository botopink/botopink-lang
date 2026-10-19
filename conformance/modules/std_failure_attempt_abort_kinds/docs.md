# std_failure_attempt_abort_kinds

The reference text this cell shows (from `conformance/docs.md`, § Results):

> **A crash is contained by `attempt`.** `panic`, `x!` over `null`, a
> failed `assert`, an integer overflow or division by zero, and a raise from a
> host binding without `result: true` are defects, never in a signature. std's
> `failure.attempt(f)` runs `f` and answers `Result<T, Failure>`: `Ok` of its
> value, or `Error(Failure(message, kind))` for the crash it caught — `kind` is
> `"panic"` for the program's own abort, its message the text the program wrote.
