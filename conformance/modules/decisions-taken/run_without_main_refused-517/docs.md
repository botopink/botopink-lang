# Decision 517 — `botopink run` of a program with no `fn main` is a located error, the same message on every target and host.

`src/main.bp` is the package's entry module, and this one declares a type and two functions but no `fn main`. Running it
is refused before anything runs, with one located message on every target and host: the entry module declares no
`fn main`, so there is nothing to run. Before the rule each target answered in its own way — wasm on wasi named a missing
`wasi:cli/run` export, wasm in the browser and commonJS exited 0 having done nothing, and erlang and beam failed with a
raw `error:undef`.

Cells that also bear on it: `modules/run/cells/run_without_main`, `modules/fn/run/src/cases/fn_empty_main`.

[draft/main.bp](draft/main.bp)
