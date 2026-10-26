-module(bp_load_cases_record_update@main@@Inner).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, v) -> erlang:element(2, V);
'__bp_get'(V, w) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Inner", [{"v", erlang:element(2, V)}, {"w", erlang:element(3, V)}]}.
