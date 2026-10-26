-module(bp_load_cases_optional_chain_lambda_generic@main@@Owner).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, holder) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Owner", [{"holder", erlang:element(2, V)}]}.
