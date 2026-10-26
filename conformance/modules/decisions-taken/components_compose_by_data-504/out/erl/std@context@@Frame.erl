-module(std@context@@Frame).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, value) -> erlang:element(3, V);
'__bp_get'(V, parent) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Frame", [{"key", erlang:element(2, V)}, {"value", erlang:element(3, V)}, {"parent", erlang:element(4, V)}]}.
