# Decision 416 — Dependency injection rides the context tree: `use inject(T)` builds a record whose every field is read from the context of its field's type, and `createContext(value, Behavior)` keys a context by the behavior its value implements.

[cases/context_behavior_implemented_indirectly/src/main.bp](cases/context_behavior_implemented_indirectly/src/main.bp)
[cells/context_behavior_method_find/src/main.bp](cells/context_behavior_method_find/src/main.bp)
[cases/context_behavior_not_implemented/src/main.bp](cases/context_behavior_not_implemented/src/main.bp)
[cases/inject_behavior/src/main.bp](cases/inject_behavior/src/main.bp)
[cells/inject_behavior_keyed/src/main.bp](cells/inject_behavior_keyed/src/main.bp)
[cells/inject_default_imported/src/main.bp](cells/inject_default_imported/src/main.bp)
[cases/inject_field_undeclared/src/main.bp](cases/inject_field_undeclared/src/main.bp)
[cases/inject_not_record_enum/src/main.bp](cases/inject_not_record_enum/src/main.bp)
[cells/inject_record/src/main.bp](cells/inject_record/src/main.bp)
[cases/inject_test_root_fake/src/main.bp](cases/inject_test_root_fake/src/main.bp)
