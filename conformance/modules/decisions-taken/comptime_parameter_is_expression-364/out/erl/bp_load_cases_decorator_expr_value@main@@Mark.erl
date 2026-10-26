-module(bp_load_cases_decorator_expr_value@main@@Mark).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, shown) -> erlang:element(2, V);
'__bp_get'(V, weight) -> erlang:element(3, V);
'__bp_get'(V, level) -> erlang:element(4, V);
'__bp_get'(V, min) -> erlang:element(5, V);
'__bp_get'(V, max) -> erlang:element(6, V);
'__bp_get'(V, key) -> erlang:element(7, V);
'__bp_get'(V, tags) -> erlang:element(8, V).

'__bp_format'(V) -> {record, "Mark", [{"shown", erlang:element(2, V)}, {"weight", erlang:element(3, V)}, {"level", erlang:element(4, V)}, {"min", erlang:element(5, V)}, {"max", erlang:element(6, V)}, {"key", erlang:element(7, V)}, {"tags", erlang:element(8, V)}]}.
