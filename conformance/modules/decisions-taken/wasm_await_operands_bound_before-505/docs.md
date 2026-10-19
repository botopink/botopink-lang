# Decision 505 — The wasm backend binds each operand evaluated before an `await` in its statement to a frame local (A-normal form); until then the located refusal stays.

In the example, `pair(label("x"), await answer(21))` evaluates `label("x")` before the `await` of the same statement. On wasm, where an asynchronous function is a resumable state machine, the backend keeps that operand in a frame local before suspending, so `label` runs once and the statement resumes with its value. The program prints `label x` and then `x42` on every target, as written. Until that lands, wasm refuses the statement at the `await` instead of running `label` twice.

Cells in this repository that also bear on it: `modules/decisions-taken/task_behaves_as_promise-392/cells/task_await_after_call_refused_on_wasm`.

[draft/main.bp](draft/main.bp)
