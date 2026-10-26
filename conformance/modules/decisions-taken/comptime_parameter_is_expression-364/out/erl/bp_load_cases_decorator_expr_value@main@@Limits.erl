-module(bp_load_cases_decorator_expr_value@main@@Limits).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, min) -> erlang:element(2, V);
'__bp_get'(V, max) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Limits", [{"min", erlang:element(2, V)}, {"max", erlang:element(3, V)}]}.
