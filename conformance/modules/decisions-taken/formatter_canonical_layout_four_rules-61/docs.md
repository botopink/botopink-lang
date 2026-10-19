# Decision 61 — The formatter's canonical layout — four rules

The example is written in the layout `botopink format` prints, so formatting it changes nothing; each of its parts is one
of the four rules. The first call of `each` passes a lambda whose body is two statements: the body sits four columns
right of the call line and the closing `});` returns to the call's column. The second passes a lambda with an empty body,
which stays on its line as `{ x -> }` instead of opening three lines with a blank middle. `later` receives a lambda with
no parameter, and the one-line rule covers it like any other: `{ -> 3 + 4 }`. The signature of
`describeTheOrderLineForTheInvoice` does not fit one line, and is written one parameter per line with a trailing comma,
closing `) -> string {` on its own line — the trailing comma being what the formatter reads to keep that shape (166,
345). Run, it prints `2`, `4`, `7` and `pen x3 = 450`.

Cells that also bear on it: `modules/format_annotation_trailing_comma`, `modules/print_formatter`.

[draft/main.bp](draft/main.bp)
