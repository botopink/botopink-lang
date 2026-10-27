# Decision 436 — `botopink build --target erlang|beam` keeps needing `erl`; only comptime stops needing it.

The program does part of its work while it compiles — `table` is `comptime squares(5)`, and the first argument of the second `print` is folded at build — and the rest when it runs. It prints `1 4 9 16 25` and `BUILD RUN`. The comptime part runs on the wasm runtime for every target, so `botopink check --target erlang` of this program, and `botopink build --target commonJS` or `--target wasm`, spawn no `erl`: they succeed with no `erl` on `PATH`. Building or running it for erlang or beam still needs `erl` for what those targets themselves do — the OTP release check and the compile of the emitted `.erl` — and nothing else does.

Cells in this repository that also bear on it: `modules/decisions-taken/function_stage_propagated-376/cases/stage_comptime_block_in_run`.

[draft/main.bp](draft/main.bp)
