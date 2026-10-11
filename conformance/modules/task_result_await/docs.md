# task_result_await

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> `@Task<T>` is a value that has not arrived yet, and `await` unwraps it. A Task
> **never fails** (decision 120): if the operation can go wrong, the value is a
> `@Result`, and `await` hands over that `@Result`. To propagate the error,
> combine it with `try`:
