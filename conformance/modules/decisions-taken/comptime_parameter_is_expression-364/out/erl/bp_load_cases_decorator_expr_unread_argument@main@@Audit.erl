-module(bp_load_cases_decorator_expr_unread_argument@main@@Audit).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, audited) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Audit", [{"audited", erlang:element(2, V)}]}.
