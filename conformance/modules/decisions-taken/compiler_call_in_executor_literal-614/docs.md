# Decision 614 — Both forms are valid: a `compiler.*` call inside an executor is evaluated at build and enters the executor as a literal, exactly as a `val` read before it does — `compiler` exists only at build, so where it runs is never ambiguous; the refusal `syntax-captures-build` goes.

[cells/init_executor_reads_compiler/src/main.bp](cells/init_executor_reads_compiler/src/main.bp)

Proved also by [init_executor_compiler_arg_at_run_time](../compiler_call_in_tree_evaluated_at_build-642/cells/init_executor_compiler_arg_at_run_time/src/main.bp)
