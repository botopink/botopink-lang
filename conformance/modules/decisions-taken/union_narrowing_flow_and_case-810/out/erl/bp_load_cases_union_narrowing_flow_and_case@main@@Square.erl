-module(bp_load_cases_union_narrowing_flow_and_case@main@@Square).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, side) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Square", [{"side", erlang:element(2, V)}]}.
