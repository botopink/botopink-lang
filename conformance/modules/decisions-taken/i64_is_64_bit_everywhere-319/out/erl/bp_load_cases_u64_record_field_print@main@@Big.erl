-module(bp_load_cases_u64_record_field_print@main@@Big).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, n) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Big", [{"n", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
