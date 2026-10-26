-module(bp_load_cases_optional_member_default@main@@Y).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V);
'__bp_get'(V, name) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Y", [{"id", erlang:element(2, V)}, {"name", erlang:element(3, V)}]}.
