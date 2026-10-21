# Decision 255 — (1) A type name with explicit type arguments followed by `.member` or `(` is a type application — `Dict<string, unknown>

[run/src/cases/comptime_expression_is_block/mod.bp](run/src/cases/comptime_expression_is_block/mod.bp)
[refused/src/cases/comptime_expression_type_mismatch/mod.bp](refused/src/cases/comptime_expression_type_mismatch/mod.bp)
[refused/src/cases/type_application_argument_count/mod.bp](refused/src/cases/type_application_argument_count/mod.bp)
[refused/src/cases/type_application_argument_mismatch/mod.bp](refused/src/cases/type_application_argument_mismatch/mod.bp)
[refused/src/cases/type_application_on_a_field/mod.bp](refused/src/cases/type_application_on_a_field/mod.bp)
[run/src/cases/type_application_static_member/mod.bp](run/src/cases/type_application_static_member/mod.bp)
[run/src/cases/type_application_through_namespace/mod.bp](run/src/cases/type_application_through_namespace/mod.bp)
[refused/src/cases/type_application_through_namespace_mismatch/mod.bp](refused/src/cases/type_application_through_namespace_mismatch/mod.bp)
[refused/src/cases/type_application_variant_payload_mismatch/mod.bp](refused/src/cases/type_application_variant_payload_mismatch/mod.bp)

Proved also by [comptime_expression_static_call](../comptime_evaluated_and_lifted-266/run/src/cases/comptime_expression_static_call/mod.bp)
