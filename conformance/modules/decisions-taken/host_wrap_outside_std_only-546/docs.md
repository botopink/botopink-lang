# Decision 546 — Wrapping every host call costs 15–21 % on erlang and beam (decisions 492, 527 (1); 144 B-07)

`readSector` is a binding the program declares, outside std, without `result: true`, and its host raises. On erlang
and beam the compiler wraps calls of exactly such a binding, so `attempt` reports the raise as `Error host`. commonJS
wraps every such call and answers the same. `tryReadSector` raises the same way but declares `result: true`. Its
failure is a value, `Error(HostError(…))`, which the `catch` block receives, printing `caught host` before falling back
to `-1`. No `attempt` is involved there. std's own bindings are not wrapped. Each is audited instead, either
`result: true` or listed as promising no failure, so the cost of the wrapper never reaches std's loops, and a std
binding that raises anyway reads as `crash`. The last part runs a failing `assert` with a message under `attempt`. It
prints `panic: assertion failed: n >= 0: a sector number is never negative at src/main.bp:…`: the condition, the
program's message and the location, in that order. The manifest, [draft/botopink.json](draft/botopink.json), keeps
the program to the three targets that have a host to raise. wasm never imitates a host raise.

Cells in this repository that also bear on it: `modules/decisions-taken/failure_kinds_exact_every_target-527/cells/std_failure_attempt_host`,
`modules/decisions-taken/failure_kinds_exact_every_target-527/cells/std_failure_attempt_crash`,
`modules/decisions-taken/result_is_checked_error-431/cells/try_catch_host_raise_propagates`,
`modules/assert/cases/assert_message_aborts`.

[draft/main.bp](draft/main.bp)
