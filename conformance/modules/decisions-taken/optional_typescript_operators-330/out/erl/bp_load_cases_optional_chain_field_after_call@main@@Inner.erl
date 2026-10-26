-module(bp_load_cases_optional_chain_field_after_call@main@@Inner).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Inner", [{"x", erlang:element(2, V)}]}.
