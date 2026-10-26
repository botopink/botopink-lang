-module(bp_load_cases_comptime_decorator_section_value@main@@Mark).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, labels) -> erlang:element(2, V);
'__bp_get'(V, fallback) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Mark", [{"labels", erlang:element(2, V)}, {"fallback", erlang:element(3, V)}]}.
