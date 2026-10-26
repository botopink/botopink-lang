-module(bp_load_cases_derived_type_functions@main@@NotedDog).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V);
'__bp_get'(V, breed) -> erlang:element(4, V);
'__bp_get'(V, text) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "NotedDog", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}, {"breed", erlang:element(4, V)}, {"text", erlang:element(5, V)}]}.
