-module(bp_load_cases_union_narrowing_flow_and_case@main@@Dot).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, label) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Dot", [{"label", erlang:element(2, V)}]}.
