# Decision 365 — A deferred `after()` failure reaching the core's logger is front 17's step, not 128's.

A request defers two functions to run after its response: `audit`, which succeeds, and `metrics`, which raises. `drainAfter` runs each under `attempt`, so a raise is a value it can read rather than a crash, and reports every failure through the logger — the line `after: failed <id> <reason>` under the name `rakun.request.after`, the request's id as the correlation id. The program prints `response sent`, `audit written`, and `ERROR rakun.request.after [req-42] after: failed metrics metrics host down`. A deferred failure that reached no logger would be invisible in production, so it is never deleted.

Cells in this repository that also bear on it: `modules/decisions-taken/runtime_abort_prints_failure-535/cases/abort_text_panic`.

[draft/main.bp](draft/main.bp)
