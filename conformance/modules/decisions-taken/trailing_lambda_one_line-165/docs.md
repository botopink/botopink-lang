# Decision 165 — A trailing lambda whose body is one expression prints on one line when it fits, arrow or not (`h1 { "my blog" }`), as it

The example is the formatter's output. `h1 { -> "my blog" }` and `twice(1) { n -> n * 2 }` were written over three lines each; their bodies are one expression and fit, so `botopink format` prints each on one line, the parameterless one with its arrow. The third lambda holds a `val` and a tail, two statements, and keeps one per line. The program prints `<h1>my blog</h1>`, `4` and `15`.

Cells in this repository that also bear on it: `modules/decisions-taken/brace_without_arrow_is_block-525/cases/trailing_lambda_call`.

[draft/main.bp](draft/main.bp)
