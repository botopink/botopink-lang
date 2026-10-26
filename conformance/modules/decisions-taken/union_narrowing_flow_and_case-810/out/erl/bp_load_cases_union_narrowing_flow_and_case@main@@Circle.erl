-module(bp_load_cases_union_narrowing_flow_and_case@main@@Circle).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, r) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Circle", [{"r", erlang:element(2, V)}]}.
