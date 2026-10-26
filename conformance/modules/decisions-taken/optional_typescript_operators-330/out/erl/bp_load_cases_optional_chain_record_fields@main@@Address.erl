-module(bp_load_cases_optional_chain_record_fields@main@@Address).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, street) -> erlang:element(2, V);
'__bp_get'(V, zip) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Address", [{"street", erlang:element(2, V)}, {"zip", erlang:element(3, V)}]}.
