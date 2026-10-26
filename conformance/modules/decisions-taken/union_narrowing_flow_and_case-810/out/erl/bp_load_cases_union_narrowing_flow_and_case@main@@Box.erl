-module(bp_load_cases_union_narrowing_flow_and_case@main@@Box).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, item) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"item", erlang:element(2, V)}]}.
