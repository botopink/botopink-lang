# Decision 121 — Only `@Result` fails

`parsePort` returns `Result<i32, PortError>`, so its body may `throw` and may propagate with `try`. Here a failing
`parseInt` is converted with `catch throw PortError.NotANumber(…)`. `fetchPort` returns `Async<Result<i32, PortError>>`.
The task itself never fails. The `Result` sits one layer in, which is what makes its `try parsePort(s)` legal; awaiting
the task answers that `Result`, so `task.isOk()` is `true` for `"8000"` and `failed.isError()` is `true` for the empty
string. `portOrDefault` returns a bare `i32`, with no `Result` in any layer. It cannot propagate, so it closes the
region with `try … catch 8080`, and `"x"` gives `8080`. `describe` consumes the `Result` with `case` and prints one
line per outcome: `port 443`, `empty`, `not a number: http`, `too big: 70000`. The last line shows `try await … catch`
in `main`, whose `Async<void>` carries no `Result`: the `catch` handles the failure and `-1` is printed. Writing
`throw` in `portOrDefault`, or a propagating `try` in `main`, would be `effect-try-without-fallible-channel`, because
neither return holds a `Result`.

Cells in this repository that also bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/cells/task_await_result`,
`modules/decisions-taken/body_marker_whole_return_type-553/cells/component_result_try_await`,
`modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/generator_result_items_lazy`.

[draft/main.bp](draft/main.bp)
