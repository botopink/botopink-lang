-module(bp_load_cases_record_update@main@@Cfg).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, a) -> erlang:element(2, V);
'__bp_get'(V, revalidate) -> erlang:element(3, V);
'__bp_get'(V, name) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Cfg", [{"a", erlang:element(2, V)}, {"revalidate", erlang:element(3, V)}, {"name", erlang:element(4, V)}]}.
