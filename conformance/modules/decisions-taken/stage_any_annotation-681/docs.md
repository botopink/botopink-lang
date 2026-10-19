# Decision 681 — A function's stage is written only as `#[stage(.Any)]` (663's spelling of `#[Stage.Any]`), `stage` imported from the std module that owns it; `Build` and `Run` follow from resources and are never written — `#[stage(.Build)]` / `#[stage(.Run)]` are refused by `stage` itself at the argument.

The example declares the host function `triple` with `#[compiler.external(…)]` and `#[stage(.Any)]`, where `stage` is imported from std. Being `Any`, `triple` may be called inside a `comptime`. Its `.Wasm(body: tripleBody)` form answers at build, so `atBuild` is the constant `42` and the run-time call gives `42` too. Nothing in the program writes `Build` or `Run`. `label` is `Build` because it reads a `comptime` parameter, and `main` is `Run` because it prints. Writing `#[stage(.Build)]` or `#[stage(.Run)]` would be refused by `stage` at the argument. The program prints `42`, `42` and `[any]`.

Cells in this repository that also bear on it: `modules/decisions-taken/function_stage_propagated-376/cases/stage_imported`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_of_functions`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_build_and_run`.

[draft/main.bp](draft/main.bp)
