# Decision 999 — A program's `main` answering `Error(e)` writes `failed: <text>` to stderr — `<text>` what `print` writes for `e` (530), as `run()`'s `.Failed` carries it (806 (1)) — and the process exits 1 on every target, `async` or not; `Ok` and `void` exit 0; a crash keeps 535's text and status; amends 535, 870, 56; answers 989-e (a).

[cells/main_error_exits_one/src/main.bp](cells/main_error_exits_one/src/main.bp)
[cells/main_async_error_exits_one/src/main.bp](cells/main_async_error_exits_one/src/main.bp)
[cases/main_ok_exits_zero/src/main.bp](cases/main_ok_exits_zero/src/main.bp)
[cases/main_async_ok_exits_zero/src/main.bp](cases/main_async_ok_exits_zero/src/main.bp)
