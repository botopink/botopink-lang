# Decision 704 — No cancellation in std's async: a losing racer and an expired timeout run to completion and their results are dropped; `raceOf` / `timeout` document it.

`raceOf` runs two racers concurrently and answers the first to complete: the program prints `fast`. Nothing cancels the loser. Each racer counts itself in the module `var` `finished` when it completes, and after a pause longer than the slow racer's the count is `2`: `slow` ran to completion and its result was dropped. `timeout` gives a third racer a budget shorter than its work and answers `Error("timeout")` — the program prints `true` for `isError()` — and again the task keeps running: after another pause the count is `3`. The contract is the result and the order of the answers; std's async has no cancellation, no tokens and no linked processes.

Cells in this repository that also bear on it: `modules/decisions-taken/std_async_on_every_target-690/cells/std_async_on_every_target`.

[draft/main.bp](draft/main.bp)
