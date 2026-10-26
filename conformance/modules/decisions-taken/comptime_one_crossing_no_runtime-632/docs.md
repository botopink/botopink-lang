# Decision 632 — No `runtime` keyword: a line runs on the side of the body it is written in; `comptime` is the one crossing from run-time code into the build, `compiler.init` the one crossing from a build body into the program.

The example crosses between the build and the run in the two directions, each with one word. In `main` the `comptime { … }` block is a build body: it reads `Book`'s `Sort` meta with `compiler.typeInfo(Book).meta(Sort)`, and its `print("read at build")` runs at build, written to the build's output, not the program's. The block's tail, `s`, crosses into the program as a literal, so `print(o?.by ?? "none")` runs when the program runs and prints `title`. Nothing marks that line as run time, because a line runs on the side of the body it is written in. In the other direction, the decorator `sortBy` ([draft/comptime/sorting.bp](draft/comptime/sorting.bp)) is a build body, and `compiler.init` is its one way to put code into the program: the executor `record(name)` runs before `main`, so `sorted()` prints `Book`. There is no `runtime` keyword. In a run-time body it would say nothing, and in a build body it would be `compiler.init` spelled a second way.

The program prints `title` and `Book`.

Cells in this repository that bear on it: `modules/comptime/cases/comptime_block_value`, `modules/decisions-taken/comptime_evaluated_and_lifted-266/run/src/cases/comptime_block_in_body`, `modules/decisions-taken/function_stage_propagated-376/cells/stage_comptime_block_in_run`, `modules/decisions-taken/no_declaration_files_compiler_value-575/cells/init_executor_before_main`.

[draft/main.bp](draft/main.bp)
