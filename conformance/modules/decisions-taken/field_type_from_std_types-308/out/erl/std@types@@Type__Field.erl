-module(std@types@@Type__Field).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, owner) -> erlang:element(2, V);
'__bp_get'(V, name) -> erlang:element(3, V);
'__bp_get'(V, typeName) -> erlang:element(4, V);
'__bp_get'(V, annotations) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Type.Field", [{"owner", erlang:element(2, V)}, {"name", erlang:element(3, V)}, {"typeName", erlang:element(4, V)}, {"annotations", erlang:element(5, V)}]}.
