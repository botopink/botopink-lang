# Decision 808 — A function whose every parameter is `comptime` is expanded at build wherever it is called; its `compiler.init` becomes a program-start init only in a top-level `comptime` block, and anywhere else the executor's body is written where the call is; amends 788 (2), 793 (3).

A run-time call of such a function is expanded at build (808 (2)): the `compiler.init({ -> … })` it reaches
writes the executor's body at the call, run when that line runs — `init_at_call_order` prints `antes`, the
case, `depois`; under an `if` it runs only when the branch does (`init_at_call_if_not_taken`); a run-time
call from another module's function, or of another module's function, is expanded alike, the executor's
names resolved where they were written (`init_at_call_other_module`). In its own module a `pub` such function
type-checks with `compiler.init` typed `void` and leaves the program (808 (1), `init_at_call_pub_own_module`).
A `comptime { … }` written in a function body that calls one runs at build and writes the executor's body
where the block is, run each time the enclosing function runs (808 (4), `init_at_call_body_block`). A call
from a decorator's body, from a template's body and under a `comptime` that answers a value is refused
`compiler-output-outside-decorator`, at the call (808 (3), `init_at_call_from_decorator`,
`init_at_call_from_template`, `init_at_call_in_value_comptime`). The build lines are held by compiler unit tests: `cell check` records none
(decision 796).

[cases/init_at_call_order/src/main.bp](cases/init_at_call_order/src/main.bp)
[cases/init_at_call_if_not_taken/src/main.bp](cases/init_at_call_if_not_taken/src/main.bp)
[cases/init_at_call_body_block/src/main.bp](cases/init_at_call_body_block/src/main.bp)
[cases/init_at_call_pub_own_module/src/main.bp](cases/init_at_call_pub_own_module/src/main.bp)
[cases/init_at_call_other_module/src/main.bp](cases/init_at_call_other_module/src/main.bp)
[cases/init_at_call_from_decorator/src/main.bp](cases/init_at_call_from_decorator/src/main.bp)
[cases/init_at_call_from_template/src/main.bp](cases/init_at_call_from_template/src/main.bp)
[cases/init_at_call_in_value_comptime/src/main.bp](cases/init_at_call_in_value_comptime/src/main.bp)

Proved also by [block_calls_other_module_pub](../module_comptime_block_rules-793/cells/block_calls_other_module_pub/src/main.bp)
