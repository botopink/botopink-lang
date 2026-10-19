# Decision 132 — The `;` after a braced block becomes an error once every source is migrated

The example is `describe`, a function made of statements of both kinds. The braced ones are an `if` / `else`, a `for` over an array, a `while` and a `case`: each ends at its closing `}`, with no `;` after it. The braceless ones are a one-line `if (n > 2) print("big");` and the assignments: each ends at its `;`. A `;` written after a braced block's `}` is accepted by the parser and removed by `botopink format`, so this file, which is formatted, has none, and the formatter neither adds one nor needs one. A braceless statement keeps its `;`.

`describe(3)` prints `big`, `three`, `1`, `2`, `left 0` and `odd`; `describe(2)` prints `small`, `1`, `2`, `left 0` and `even`.

Cells in this repository that bear on it: `modules/comment_in_braced_block`, `modules/fn_expr_tail_semicolon`, `modules/lambda_last_statement_semicolon`.

[draft/main.bp](draft/main.bp)
