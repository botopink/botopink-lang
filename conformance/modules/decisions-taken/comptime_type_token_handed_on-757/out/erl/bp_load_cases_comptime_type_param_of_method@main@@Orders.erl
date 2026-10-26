-module(bp_load_cases_comptime_type_param_of_method@main@@Orders).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, total) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Orders", [{"total", erlang:element(2, V)}]}.
