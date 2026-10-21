# Decision 595 — `try` opens a region; `catch` closes it and handles the failure of every `try` written in it.

Every `try` sends its failure to the nearest region that holds it, and a `catch` closes a region and handles every
failure inside it. In `sumOrZero` the region is the whole expression left of `catch`: both parsed operands belong to it,
so `"x"` turns the sum into the fallback `0l`. `describe` writes the region as a block, `try { … }`, whose value is its
last expression without `;`; its handler binds the region's error as `e`, typed `ParseError`, and reads it with a `case`,
so `""` answers `empty` and `"x"` answers `not a number: x`. `checked` converts the failure with `catch throw`, so it
becomes the function's own `Result<i32, string>`, and `logged` handles it with a block that prints and ends in the
fallback `-1l`. `sum` has no `catch`: its region is the function itself, which needs the `Result` it declares. Each region
fails with one error type, `ParseError`; `parse` itself turns `parseInt`'s `string` error into a `ParseError` with `catch throw`. The program prints `5`, `0`, `20`, `empty`, `not a number: x`, `9`, `true`, `7`,
`fallback for `, `-1` and `2`.

Cells that also bear on it: `modules/decisions-taken/await_try_prefix_catch_infix-537/cells/catch_lowest_precedence`, `modules/try/run/src/cases/try_start_positions`,
`modules/try/cells/try_catch_handler_mismatch`, `modules/decisions-taken/await_try_prefix_catch_infix-537/cells/try_await_prefix_operators`, `modules/decisions-taken/body_marker_whole_return_type-553/refused/src/cases/try_in_plain_fn`.

[cells/beam_try_catch_result_void/src/main.bp](cells/beam_try_catch_result_void/src/main.bp)
[cells/catch_region_covers_left_side/src/main.bp](cells/catch_region_covers_left_side/src/main.bp)
[cells/catch_without_try/src/main.bp](cells/catch_without_try/src/main.bp)
[cells/try_block_catch_binder/src/main.bp](cells/try_block_catch_binder/src/main.bp)
[cells/try_block_catch_empty/src/main.bp](cells/try_block_catch_empty/src/main.bp)
[cells/try_block_catch_rethrow/src/main.bp](cells/try_block_catch_rethrow/src/main.bp)
[cells/try_block_catch_value/src/main.bp](cells/try_block_catch_value/src/main.bp)
[cells/try_block_catch_void_statement/src/main.bp](cells/try_block_catch_void_statement/src/main.bp)
[cells/try_in_catch_body_propagates/src/main.bp](cells/try_in_catch_body_propagates/src/main.bp)
[cells/try_region_cannot_fail/src/main.bp](cells/try_region_cannot_fail/src/main.bp)
[cells/try_region_errors_differ/src/main.bp](cells/try_region_errors_differ/src/main.bp)
