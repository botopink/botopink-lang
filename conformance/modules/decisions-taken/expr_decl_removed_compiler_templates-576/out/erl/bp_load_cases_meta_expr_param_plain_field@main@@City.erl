-module(bp_load_cases_meta_expr_param_plain_field@main@@City).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "City", [{"name", erlang:element(2, V)}]}.
