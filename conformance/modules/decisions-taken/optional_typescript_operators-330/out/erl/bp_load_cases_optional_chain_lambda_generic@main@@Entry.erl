-module(bp_load_cases_optional_chain_lambda_generic@main@@Entry).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Entry", [{"name", erlang:element(2, V)}]}.
