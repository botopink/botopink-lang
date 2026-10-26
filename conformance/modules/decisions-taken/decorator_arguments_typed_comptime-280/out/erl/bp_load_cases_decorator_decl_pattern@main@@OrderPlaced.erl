-module(bp_load_cases_decorator_decl_pattern@main@@OrderPlaced).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V);
'__bp_get'(V, total) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "OrderPlaced", [{"id", erlang:element(2, V)}, {"total", erlang:element(3, V)}]}.
