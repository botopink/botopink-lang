-module(bp_load_cases_meta_expr_field_literal@main@@Signup).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, handle) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Signup", [{"handle", erlang:element(2, V)}]}.
