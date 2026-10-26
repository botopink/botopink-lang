# is_async_answers_a_task

Decision 967: `v is Async<unknown>` answers whether `v` is a task, settled or not — commonJS's
`instanceof Promise`, wasm's `ref.test` over the runtime's `$task`, its state not read. On erlang and
beam no value is a task: a call answering `Async<T>` answers its settled `T`, so the test is `false`
for every value there (`snapshot/targets/erlang/`, `snapshot/targets/beam/`). An `await` over a
`T | Async<T>` reads the `T` on the four targets.

[src/main.bp](src/main.bp)
