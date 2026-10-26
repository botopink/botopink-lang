# Decision 397 — A database query in a method body is written on the database context — `self.db.query "select * from User where active = true"` —, and `from User` names an entity whose table and columns erika reads from the type at build.

[cases/template_method_behavior_method/src/main.bp](cases/template_method_behavior_method/src/main.bp)
[cases/template_method_own_method/src/main.bp](cases/template_method_own_method/src/main.bp)
[cases/template_method_receiver_mismatch/src/main.bp](cases/template_method_receiver_mismatch/src/main.bp)

Proved also by [template_method_call](../query_template_assembled_at_build-415/run/src/cases/template_method_call/mod.bp)
Proved also by [template_method_not_in_scope](../query_template_assembled_at_build-415/refused/src/cases/template_method_not_in_scope/mod.bp)
