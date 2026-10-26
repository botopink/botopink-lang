-module(bp_load_cases_optional_chain_record_fields@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, address) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "User", [{"name", erlang:element(2, V)}, {"address", erlang:element(3, V)}]}.
