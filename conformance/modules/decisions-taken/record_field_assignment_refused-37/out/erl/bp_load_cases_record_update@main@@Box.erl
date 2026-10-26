-module(bp_load_cases_record_update@main@@Box).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, tag) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Box", [{"value", erlang:element(2, V)}, {"tag", erlang:element(3, V)}]}.
