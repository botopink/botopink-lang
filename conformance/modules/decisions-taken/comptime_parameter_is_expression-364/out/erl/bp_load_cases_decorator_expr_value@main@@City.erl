-module(bp_load_cases_decorator_expr_value@main@@City).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> erlang:element(2, V);
'__bp_get'(V, name) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "City", [{"code", erlang:element(2, V)}, {"name", erlang:element(3, V)}]}.
