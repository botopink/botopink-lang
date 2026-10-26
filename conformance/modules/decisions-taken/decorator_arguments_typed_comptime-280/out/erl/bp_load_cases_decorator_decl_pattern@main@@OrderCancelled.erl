-module(bp_load_cases_decorator_decl_pattern@main@@OrderCancelled).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "OrderCancelled", [{"id", erlang:element(2, V)}]}.
