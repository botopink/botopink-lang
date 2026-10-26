-module(bp_load_cases_f64_equality_total_order@main@@F).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "F", [{"x", erlang:element(2, V)}]}.
