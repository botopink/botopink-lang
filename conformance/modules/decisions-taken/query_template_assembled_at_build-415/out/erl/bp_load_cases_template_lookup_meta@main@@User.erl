-module(bp_load_cases_template_lookup_meta@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V);
'__bp_get'(V, email) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "User", [{"id", erlang:element(2, V)}, {"email", erlang:element(3, V)}]}.
