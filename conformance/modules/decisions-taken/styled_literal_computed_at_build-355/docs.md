# Decision 355 — A `styled` literal is computed at build when every hole is known at build; at render only when a hole is not.

The decision is `rakun-style`'s `styled` literal; its rule is botopink-lang's folding, and this program shows the rule with the literal written as a plain function. `rule` builds a CSS rule whose class is std's content hash of its declarations. `code`'s argument is made of a literal and `tab4`, a `val` whose initializer is known at build, and `rule` calls only `Any` functions, so `code` is computed while the program compiles and is a constant of it. `badge`'s argument holds the parameter `color`, a run-time value, so its rule is computed when it is called — at render, for a component. What decides is each hole's value, never the literal's text: the program prints the constant rule, the rule built for `blue`, and `true` for the constant matching the same rule computed at run time.

Cells in this repository that also bear on it: `modules/decisions-taken/function_stage_propagated-376/cells/stage_of_functions`, `modules/fold/cases/fold_split_join_lambda`.

[draft/main.bp](draft/main.bp)
