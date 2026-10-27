# Decision 998 — An executor may be an `async` lambda — `compiler.init({ async -> … })`, the marker inside the brace (584) — admitted only where 808 (2) writes its body into an `async` body, its `await`s that body's; `Module.mainAsync()` is read at build; `compiler.init` stays one function answering `void`, and a valued executor is refused; one `runCase` serves every case of 989 (9); answers 989-c; amends 575 (3), 615, 786 (1), 808 (1)–(2), 989 (9).

An executor may be `async`, `compiler.init({ async -> … })`, only where a run-time call expanded inside an `async`
body writes its statements, its `await`s that body's: one `runCase` over a sync and an async case, the loaded
package's kind read at build with `Module.mainAsync()` (`init_async_executor_in_async_body`,
`module_main_async_read_at_build`), on commonJS, erlang, beam and wasm.

[cells/init_async_executor_in_async_body/src/main.bp](cells/init_async_executor_in_async_body/src/main.bp)
[cells/module_main_async_read_at_build/src/main.bp](cells/module_main_async_read_at_build/src/main.bp)

An `async` executor in a body that is not `async` is `init-async-executor-outside-async`, at the `async`
(`init_async_executor_outside_async_refused`); an executor whose body ends in a value is `init-executor-value`, at
that value (`init_executor_value_refused`).

[cases/init_async_executor_outside_async_refused/src/main.bp](cases/init_async_executor_outside_async_refused/src/main.bp)
[cases/init_executor_value_refused/src/main.bp](cases/init_executor_value_refused/src/main.bp)
