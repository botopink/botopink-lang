-module(bp_load_cases_meta_typed@main@@Entity).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, table) -> erlang:element(2, V);
'__bp_get'(V, columns) -> erlang:element(3, V);
'__bp_get'(V, weight) -> erlang:element(4, V);
'__bp_get'(V, audited) -> erlang:element(5, V);
'__bp_get'(V, level) -> erlang:element(6, V);
'__bp_get'(V, alias) -> erlang:element(7, V).

'__bp_format'(V) -> {record, "Entity", [{"table", erlang:element(2, V)}, {"columns", erlang:element(3, V)}, {"weight", erlang:element(4, V)}, {"audited", erlang:element(5, V)}, {"level", erlang:element(6, V)}, {"alias", erlang:element(7, V)}]}.
