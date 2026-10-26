-module(bp_load_cases_template_lookup_meta@main@@Table).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, rows) -> erlang:element(3, V);
'__bp_get'(V, cached) -> erlang:element(4, V);
'__bp_get'(V, size) -> erlang:element(5, V);
'__bp_get'(V, tags) -> erlang:element(6, V).

'__bp_format'(V) -> {record, "Table", [{"name", erlang:element(2, V)}, {"rows", erlang:element(3, V)}, {"cached", erlang:element(4, V)}, {"size", erlang:element(5, V)}, {"tags", erlang:element(6, V)}]}.
