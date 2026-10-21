# Decision 416 — Dependency injection rides the context tree: `use inject(T)` builds a record whose every field is read from the context of its field's type, and `createContext(value, Behavior)` keys a context by the behavior its value implements.

[cells/context_behavior_implemented_indirectly/src/main.bp](cells/context_behavior_implemented_indirectly/src/main.bp)
[cells/context_behavior_method_find/src/main.bp](cells/context_behavior_method_find/src/main.bp)
[refused/src/cases/context_behavior_not_implemented/mod.bp](refused/src/cases/context_behavior_not_implemented/mod.bp)
[refused/src/cases/inject_behavior/mod.bp](refused/src/cases/inject_behavior/mod.bp)
[cells/inject_behavior_keyed/src/main.bp](cells/inject_behavior_keyed/src/main.bp)
[cells/inject_default_imported/src/main.bp](cells/inject_default_imported/src/main.bp)
[refused/src/cases/inject_field_undeclared/mod.bp](refused/src/cases/inject_field_undeclared/mod.bp)
[refused/src/cases/inject_not_record_enum/mod.bp](refused/src/cases/inject_not_record_enum/mod.bp)
[cells/inject_record/src/main.bp](cells/inject_record/src/main.bp)
[cells/inject_test_root_fake/src/main.bp](cells/inject_test_root_fake/src/main.bp)
