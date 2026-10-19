# Decision 337 — The shorthand import goes; `mod m;` binds the namespace `m` in the module that declares it.

[cells/mod_binds_namespace/src/main.bp](cells/mod_binds_namespace/src/main.bp)
[run/src/cases/mod_namespace_cascade/mod.bp](run/src/cases/mod_namespace_cascade/mod.bp)
[run/src/cases/mod_reexport_by_val/mod.bp](run/src/cases/mod_reexport_by_val/mod.bp)
[cells/namespace_import_module/src/main.bp](cells/namespace_import_module/src/main.bp)
[run/src/cases/optional_record_carrier/mod.bp](run/src/cases/optional_record_carrier/mod.bp)
[cells/private_module_through_namespace/src/main.bp](cells/private_module_through_namespace/src/main.bp)
[refused/src/cases/redundant_module_import/mod.bp](refused/src/cases/redundant_module_import/mod.bp)
[refused/src/cases/shorthand_import/mod.bp](refused/src/cases/shorthand_import/mod.bp)
[cells/shorthand_import_one_candidate/src/main.bp](cells/shorthand_import_one_candidate/src/main.bp)
[cells/shorthand_import_several_candidates/src/main.bp](cells/shorthand_import_several_candidates/src/main.bp)

Proved also by [declaration_named_like_module](../module_import_binds_namespace-582/cells/declaration_named_like_module/src/main.bp)
Proved also by [mod_namespace_callable_default](../module_import_binds_namespace-582/cells/mod_namespace_callable_default/src/main.bp)
