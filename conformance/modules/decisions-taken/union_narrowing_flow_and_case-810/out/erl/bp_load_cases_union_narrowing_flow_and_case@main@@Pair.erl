-module(bp_load_cases_union_narrowing_flow_and_case@main@@Pair).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, left) -> erlang:element(2, V);
'__bp_get'(V, right) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Pair", [{"left", erlang:element(2, V)}, {"right", erlang:element(3, V)}]}.
