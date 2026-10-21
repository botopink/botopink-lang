# Decision 415 — `self.db.query "…"` is assembled wholly at build through `@Decl`: the template method's receiver and literal are both `comptime` expressions, and `q.lookup(name)` answers the call site's declaration as a read-only `?@Decl` whose data meta is read at build.

[cells/decorator_decl_module/src/main.bp](cells/decorator_decl_module/src/main.bp)
[cells/template_bindings_decls/src/main.bp](cells/template_bindings_decls/src/main.bp)
[cells/template_lookup_decl/src/main.bp](cells/template_lookup_decl/src/main.bp)
[run/src/cases/template_lookup_decl_members/mod.bp](run/src/cases/template_lookup_decl_members/mod.bp)
[refused/src/cases/template_lookup_decl_write/mod.bp](refused/src/cases/template_lookup_decl_write/mod.bp)
[run/src/cases/template_lookup_meta/mod.bp](run/src/cases/template_lookup_meta/mod.bp)
[refused/src/cases/template_lookup_meta_expr_field/mod.bp](refused/src/cases/template_lookup_meta_expr_field/mod.bp)
[refused/src/cases/template_lookup_meta_hooks_pending/mod.bp](refused/src/cases/template_lookup_meta_hooks_pending/mod.bp)
[cells/template_lookup_meta_other_module/src/main.bp](cells/template_lookup_meta_other_module/src/main.bp)
[run/src/cases/template_lookup_meta_same_module/mod.bp](run/src/cases/template_lookup_meta_same_module/mod.bp)
[run/src/cases/template_method_call/mod.bp](run/src/cases/template_method_call/mod.bp)
[refused/src/cases/template_method_not_in_scope/mod.bp](refused/src/cases/template_method_not_in_scope/mod.bp)

