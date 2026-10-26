# Decision 415 — `self.db.query "…"` is assembled wholly at build through `@Decl`: the template method's receiver and literal are both `comptime` expressions, and `q.lookup(name)` answers the call site's declaration as a read-only `?@Decl` whose data meta is read at build.

[cells/decorator_decl_module/src/main.bp](cells/decorator_decl_module/src/main.bp)
[cells/template_bindings_decls/src/main.bp](cells/template_bindings_decls/src/main.bp)
[cells/template_lookup_decl/src/main.bp](cells/template_lookup_decl/src/main.bp)
[cases/template_lookup_decl_members/src/main.bp](cases/template_lookup_decl_members/src/main.bp)
[cases/template_lookup_decl_write/src/main.bp](cases/template_lookup_decl_write/src/main.bp)
[cases/template_lookup_meta/src/main.bp](cases/template_lookup_meta/src/main.bp)
[cases/template_lookup_meta_expr_field/src/main.bp](cases/template_lookup_meta_expr_field/src/main.bp)
[cases/template_lookup_meta_hooks_pending/src/main.bp](cases/template_lookup_meta_hooks_pending/src/main.bp)
[cells/template_lookup_meta_other_module/src/main.bp](cells/template_lookup_meta_other_module/src/main.bp)
[cases/template_lookup_meta_same_module/src/main.bp](cases/template_lookup_meta_same_module/src/main.bp)
[cases/template_method_call/src/main.bp](cases/template_method_call/src/main.bp)
[cases/template_method_not_in_scope/src/main.bp](cases/template_method_not_in_scope/src/main.bp)

