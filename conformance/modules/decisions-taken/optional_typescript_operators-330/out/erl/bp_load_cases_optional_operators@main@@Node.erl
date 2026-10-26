-module(bp_load_cases_optional_operators@main@@Node).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, tags) -> erlang:element(3, V);
'__bp_get'(V, next) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Node", [{"name", erlang:element(2, V)}, {"tags", erlang:element(3, V)}, {"next", erlang:element(4, V)}]}.
