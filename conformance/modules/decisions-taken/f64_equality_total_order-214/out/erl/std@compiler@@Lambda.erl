-module(std@compiler@@Lambda).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, params) -> erlang:element(2, V);
'__bp_get'(V, body) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Lambda", [{"params", erlang:element(2, V)}, {"body", erlang:element(3, V)}]}.
