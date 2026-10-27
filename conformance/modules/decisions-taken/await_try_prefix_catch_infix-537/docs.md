# Decision 537 — Decision 523's example `async { (try await t catch 0) * 2 }` is refused by `try-await-operand`

[cells/await_postfix_binds_tighter/src/main.bp](cells/await_postfix_binds_tighter/src/main.bp)
[cells/catch_lowest_precedence/src/main.bp](cells/catch_lowest_precedence/src/main.bp)
[cells/try_await_prefix_operators/src/main.bp](cells/try_await_prefix_operators/src/main.bp)

Proved also by [marker_lambda_async](../body_marker_whole_return_type-553/cases/marker_lambda_async/src/main.bp)
