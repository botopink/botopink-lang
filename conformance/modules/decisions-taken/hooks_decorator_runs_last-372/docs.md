# Decision 372 — Provisional ("for now"; a second splice for a `.hooks` reader's outputs is weighed on a concrete case): a decorator that reads `.hooks` runs last in its module and only records meta or refuses.

[cases/decl_hooks_reads_member/src/main.bp](cases/decl_hooks_reads_member/src/main.bp)
[cases/decorator_hooks_output/src/main.bp](cases/decorator_hooks_output/src/main.bp)
[cases/decorator_hooks_output_member_fn/src/main.bp](cases/decorator_hooks_output_member_fn/src/main.bp)
[cases/typeinfo_all_hooks_reader/src/main.bp](cases/typeinfo_all_hooks_reader/src/main.bp)

Proved also by [template_lookup_meta_hooks_pending](../query_template_assembled_at_build-415/cases/template_lookup_meta_hooks_pending/src/main.bp)
Proved also by [template_lookup_meta_same_module](../query_template_assembled_at_build-415/cases/template_lookup_meta_same_module/src/main.bp)
