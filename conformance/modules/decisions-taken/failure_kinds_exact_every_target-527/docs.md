# Decision 527 — `Failure`'s kinds exact on every target: wasm never imitates a host raise; an unmarked raise is `crash`; a failing `assert` and an integer division by zero are `panic`; a host raise's message is `~tp` without the stack.

[cases/assert_failure_is_panic/src/main.bp](cases/assert_failure_is_panic/src/main.bp)
[cases/int_division_by_zero_is_panic/src/main.bp](cases/int_division_by_zero_is_panic/src/main.bp)
[cases/std_asserts_throws_over_attempt/src/main.bp](cases/std_asserts_throws_over_attempt/src/main.bp)
[cases/std_failure_attempt/src/main.bp](cases/std_failure_attempt/src/main.bp)
[cases/std_failure_attempt_crash/src/main.bp](cases/std_failure_attempt_crash/src/main.bp)
[cases/std_failure_attempt_host/src/main.bp](cases/std_failure_attempt_host/src/main.bp)

Proved also by [abort_text_crash](../runtime_abort_prints_failure-535/cases/abort_text_crash/src/main.bp)
Proved also by [abort_text_overflow](../runtime_abort_prints_failure-535/cases/abort_text_overflow/src/main.bp)
