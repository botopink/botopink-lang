# Decision 611 — A build value an executor needs may be read in the decorator's body and enter the executor as a literal — `val declName = compiler.name(decl); compiler.init({ -> rkRegisterX(declName, decl); });` (cells `compile_executor_before_main`, `compile_executor_handle_typed`).

Both decorators register the annotated function under its name. `#[service]` reads the name in its body — `val declName = compiler.name(decl)!;` — and the executor uses `declName`: a build value read before the executor enters it as a literal. `#[job]` writes the same read inside the executor, `compiler.name(decl)!` in the run-time code; a `compiler.*` call there is evaluated at build and spliced as its answer, so the two forms compile to the same registration. Both executors run before `main`, in declaration order, and the program prints `mailer mail sent` and `cleanup tmp cleaned`.

Cells in this repository that also bear on it: `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/init_executor_before_main`, `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/run/src/cases/init_executor_handle_typed`, `modules/decisions-taken/compiler_call_in_executor_literal-614/cases/init_executor_reads_compiler`.

[draft/main.bp](draft/main.bp) · [draft/comptime/services.bp](draft/comptime/services.bp) · [draft/comptime/registry.bp](draft/comptime/registry.bp)
