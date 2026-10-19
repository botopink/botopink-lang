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

Cells that also bear on it: `modules/catch_lowest_precedence`, `modules/try_start_positions`,
`modules/try_catch_handler_mismatch`, `modules/try_await_prefix_operators`, `modules/try_in_plain_fn`.

[draft/main.bp](draft/main.bp)
