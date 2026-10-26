-module(bp_load_cases_record_update@main@@Outer).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, inner) -> erlang:element(2, V);
'__bp_get'(V, n) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Outer", [{"inner", erlang:element(2, V)}, {"n", erlang:element(3, V)}]}.
