-module(bp_load_cases_meta_expr_field_literal@main@@Check).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Check", [{"message", erlang:element(2, V)}]}.
