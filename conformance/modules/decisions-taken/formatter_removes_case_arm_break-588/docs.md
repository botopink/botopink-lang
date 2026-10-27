# Decision 588 — 525 and 525-a (3): the formatter removes, once, the last `;` of a `case` arm used as a value and the arm's `break <value

`area` reads a `case` as a value, and each arm's value is its tail — its last expression, written without `;`: `squared * 3` for a circle, `n * n` for a square, `0` for a dot. The program prints `12 9 0`. This is the form `botopink format` writes when it meets the older spelling: an arm that ended in `break squared * 3;`, or in `squared * 3;` with its `;`, has the `break` and the last `;` removed once, making the arm's tail its value. Everywhere else the formatter prints a block's last expression as written, neither adding nor removing its `;`.

Cells in this repository that also bear on it: `modules/decisions-taken/lambda_answers_last_expression-541/cases/case_arm_break_value_removed`, `modules/decisions-taken/fn_tail_value-409/cases/fn_tail_case_arm_block`.

[draft/main.bp](draft/main.bp)
