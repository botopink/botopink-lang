# Decision 606 — No `#[builtin]` and no `@name`: the types and behaviors a program reaches without an import are declared in `primitives.bp`; what the compiler does is a member of `compiler`; the two std functions left are imported.

[refused/src/cases/bare_print_call/mod.bp](refused/src/cases/bare_print_call/mod.bp)
[refused/src/cases/builtin_print_removed/mod.bp](refused/src/cases/builtin_print_removed/mod.bp)
[run/src/cases/external_compiler_member/mod.bp](run/src/cases/external_compiler_member/mod.bp)
[cells/panic_from_failure/src/main.bp](cells/panic_from_failure/src/main.bp)
[cells/prelude_name_bare/src/main.bp](cells/prelude_name_bare/src/main.bp)
[run/src/cases/prelude_name_shadowed/mod.bp](run/src/cases/prelude_name_shadowed/mod.bp)
[refused/src/cases/prelude_name_with_sigil/mod.bp](refused/src/cases/prelude_name_with_sigil/mod.bp)
[run/src/cases/print_from_io_terminal/mod.bp](run/src/cases/print_from_io_terminal/mod.bp)
[run/src/cases/print_local_shadows_import/mod.bp](run/src/cases/print_local_shadows_import/mod.bp)
[run/src/cases/type_info_comptime_run_time/mod.bp](run/src/cases/type_info_comptime_run_time/mod.bp)
