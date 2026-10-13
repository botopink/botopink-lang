# std_failure_attempt_task

The reference text this cell shows (from `conformance/docs.md`, § Results):

> `failure.attemptTask(f)` is its `@Task` form: it awaits the task `f` answers,
> and is `Error(Failure)` when that task crashed. A task that fails with its own
> `E` did not crash — its `@Result` is the value.
