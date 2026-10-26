-module(bp_load_cases_decorator_host_cells@main@@Point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> erlang:element(2, V);
'__bp_get'(V, y) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Point", [{"x", erlang:element(2, V)}, {"y", erlang:element(3, V)}]}.
