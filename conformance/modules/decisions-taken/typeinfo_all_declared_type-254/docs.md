# Decision 254 — `@TypeInfo.all(…)` is declared `-> Declared<unknown>[]`, one fixed type whatever the program declares; every use narrows

[refused/src/cases/call_unknown_without_narrowing/mod.bp](refused/src/cases/call_unknown_without_narrowing/mod.bp)
[cells/is_fn_narrows_unknown/src/main.bp](cells/is_fn_narrows_unknown/src/main.bp)
[cells/is_fn_wrong_arity_fails/src/main.bp](cells/is_fn_wrong_arity_fails/src/main.bp)
[cells/typeinfo_all_registration/src/main.bp](cells/typeinfo_all_registration/src/main.bp)
[refused/src/cases/typeinfo_all_value_unknown/mod.bp](refused/src/cases/typeinfo_all_value_unknown/mod.bp)

Proved also by [typeinfo_all_list](../typeinfo_all_with_list-235/cells/typeinfo_all_list/src/main.bp)
Proved also by [typeinfo_all_unknown_value](../bean_registry_built_at_comptime-256/cells/typeinfo_all_unknown_value/src/main.bp)
