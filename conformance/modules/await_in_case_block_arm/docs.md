# await_in_case_block_arm

An `await` stands in a `case` arm's `{ … }` block as it does in an expression arm: the block is
no function (decision 541 (2)), so the enclosing function's `Task` is its own. A regression
guard for the fix of decision 541 (2); an `await` in a function that does not return `Task`
stays refused (`effect_await_*` cells).
