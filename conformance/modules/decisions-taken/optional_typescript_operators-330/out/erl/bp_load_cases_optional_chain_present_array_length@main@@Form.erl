-module(bp_load_cases_optional_chain_present_array_length@main@@Form).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, fields) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Form", [{"fields", erlang:element(2, V)}]}.
