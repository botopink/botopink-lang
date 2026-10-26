-module(bp_load_cases_fn_expr_optional_param_null@main@@Holder).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Holder", [{"name", erlang:element(2, V)}]}.
