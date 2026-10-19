# Decision 732 — (a): `Async<T>` is the one name of an `async` body's return type; `Task` is no name of the prelude.

Every task in the program is typed `Async<…>`, the one name of an `async` body's return type. `load` is marked `async` and returns the value, wrapped; `cached` is unmarked, so it returns an `Async<string>` itself, through `Async.resolve`; `both` composes the two in an `async { … }` block, itself an `Async` whose value is its tail. A caller sees no difference between them, and the program prints `user 1`, `cached 2` and `user 3, cached 3`. `Task` is no name of the prelude: an older text's `Task<User>` or `Task<Result<Response, HttpError>>` reads `Async<User>` and `Async<Result<Response, HttpError>>`, and a program writing `Task` is naming nothing.

Cells in this repository that also bear on it: `modules/decisions-taken/task_methods_withdrawn_async_block-523/cells/task_compose_by_async_block`, `modules/decisions-taken/brace_without_arrow_is_block-525/cells/async_block_tail_value`, `modules/decisions-taken/task_behaves_as_promise-392/cells/task_starts_when_made`.

[draft/main.bp](draft/main.bp)
