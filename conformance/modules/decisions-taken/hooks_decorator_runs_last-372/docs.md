# Decision 372 — Provisional ("for now"; a second splice for a `.hooks` reader's outputs is weighed on a concrete case): a decorator that reads `.hooks` runs last in its module and only records meta or refuses.

[cells/decl_hooks_reads_member/src/main.bp](cells/decl_hooks_reads_member/src/main.bp)
[refused/src/cases/decorator_hooks_output/mod.bp](refused/src/cases/decorator_hooks_output/mod.bp)
[refused/src/cases/decorator_hooks_output_member_fn/mod.bp](refused/src/cases/decorator_hooks_output_member_fn/mod.bp)
[refused/src/cases/typeinfo_all_hooks_reader/mod.bp](refused/src/cases/typeinfo_all_hooks_reader/mod.bp)

Proved also by [template_lookup_meta_hooks_pending](../query_template_assembled_at_build-415/refused/src/cases/template_lookup_meta_hooks_pending/mod.bp)
Proved also by [template_lookup_meta_same_module](../query_template_assembled_at_build-415/run/src/cases/template_lookup_meta_same_module/mod.bp)
