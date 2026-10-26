-module(conformance_lib@sections@@Section).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, target) -> erlang:element(3, V);
'__bp_get'(V, body) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Section", [{"name", erlang:element(2, V)}, {"target", erlang:element(3, V)}, {"body", erlang:element(4, V)}]}.
