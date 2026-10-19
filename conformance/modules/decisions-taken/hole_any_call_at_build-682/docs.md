# Decision 682 — 380 folds at build an `Any` function that writes no `panic` / `throw`, no `print`, no module `var`, no function-value call and no method of a declared type; its calls through other such functions fold too.

`pad` and `twice` are `Any` functions that write no `panic` or `throw`, no `print`, no module `var`, no call through a function value and no method of a declared type; `pad` reads `SPACING`, a constant `val`. So `twice(3)` — every input known at build, every function such a function, `twice` reaching `pad` through its own calls — is computed by the comptime runtime where it is written, with no `comptime` keyword: the program holds `58` as a constant and prints it. `loud` writes `print`, an effect, so it never folds: `loud(5) + 1` runs when the program runs, printing `computing 5` and then `6`.

Cells in this repository that also bear on it: `modules/stage_of_functions`, `modules/fold_split_join_lambda`.

[draft/main.bp](draft/main.bp)
