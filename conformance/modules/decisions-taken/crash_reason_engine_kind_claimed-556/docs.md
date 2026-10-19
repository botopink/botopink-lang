# Decision 556 — A `crash`'s reason is the engine's; a cell claims the kind

The example raises the same crash twice. `notText` is a host binding declared to answer a `string` whose cells answer the number `5`. Calling `trim()` on that value raises inside the program's own code after the binding has returned, so the raise is a `crash`, not a `host` failure.

The first time, `failure.attempt` contains it, and `show` prints the `Failure`'s `kind`, `crash`, which is the same on every target. The `message` is not printed: it is the engine's reason, and that text differs between Node and the BEAM.

The second time nothing contains it. The program has printed `before`, ends there and writes `crash: <the engine's reason>` to stderr, so `after` never prints. The cell's snapshot claims `abort` and `stderr crash:`, the kind alone. No target keeps its own copy of the reason under `snapshot/targets/`.

The program prints `crash` and `before`, then aborts.

Cells in this repository that bear on it: `modules/decisions-taken/runtime_abort_prints_failure-535/cases/abort_text_crash`, `modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_failure_attempt_crash`.

[draft/main.bp](draft/main.bp)
