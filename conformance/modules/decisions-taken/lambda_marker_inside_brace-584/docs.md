# Decision 584 — A lambda's marker is written inside the brace, before the parameters; a marked lambda's body is a function body; `async fn f()` with no return type is refused.

Each marked lambda writes its marker inside the brace, before its parameters. `inc` is `{ async x -> … }`, typed by its annotated `val`, and `await inc(4)` prints `9`. The same form goes where any lambda goes, trailing included: `twice(1) { async x -> … }` hands `twice` a step it awaits twice, and the program prints `7`. `twice` itself composes the two awaits without being marked, through `async { … }` — written with the brace right after `async`, that is always the block, never a lambda. `launch(3) { iter n -> … }` passes an iterator lambda: its body is a function body, so each `yield k` is an item (`3`, `2`, `1`) and `return "liftoff"` is the iterator's end value `R`, read as `Step.Done` and printed last. The third clause of the decision — `async fn f()` with no return type refused with `marker-type-mismatch`, "write `-> Async<…>`" — stops a program of its own; here `double` and `main` write `-> Async<…>` as every marked function must.

Cells in this repository that also bear on it: `modules/marker_lambda_async`, `modules/marker_lambda_iter`, `modules/marker_lambda_type_mismatch`, `modules/marker_type_mismatch`, `modules/lambda_tail_iter_loop`.

[draft/main.bp](draft/main.bp)
