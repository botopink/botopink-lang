# Decision 606 — No `#[builtin]` and no `@name`: the types and behaviors a program reaches without an import are declared in `primitives.bp`; what the compiler does is a member of `compiler`; the two std functions left are imported.

[cases/bare_print_call/src/main.bp](cases/bare_print_call/src/main.bp)
[cases/builtin_print_removed/src/main.bp](cases/builtin_print_removed/src/main.bp)
[cases/external_compiler_member/src/main.bp](cases/external_compiler_member/src/main.bp)
[cases/panic_from_failure/src/main.bp](cases/panic_from_failure/src/main.bp)
[cases/prelude_name_bare/src/main.bp](cases/prelude_name_bare/src/main.bp)
[cases/prelude_name_shadowed/src/main.bp](cases/prelude_name_shadowed/src/main.bp)
[cases/prelude_name_with_sigil/src/main.bp](cases/prelude_name_with_sigil/src/main.bp)
[cases/print_from_io_terminal/src/main.bp](cases/print_from_io_terminal/src/main.bp)
[cases/print_local_shadows_import/src/main.bp](cases/print_local_shadows_import/src/main.bp)
[cases/type_info_comptime_run_time/src/main.bp](cases/type_info_comptime_run_time/src/main.bp)
