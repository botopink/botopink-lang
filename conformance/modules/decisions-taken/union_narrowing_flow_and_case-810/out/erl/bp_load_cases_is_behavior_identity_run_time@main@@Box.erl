-module(bp_load_cases_is_behavior_identity_run_time@main@@Box).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, item) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"item", erlang:element(2, V)}]}.
