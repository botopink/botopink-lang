-module(std@compiler@@Fn).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, params) -> erlang:element(2, V);
'__bp_get'(V, ret) -> erlang:element(3, V);
'__bp_get'(V, body) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Fn", [{"params", erlang:element(2, V)}, {"ret", erlang:element(3, V)}, {"body", erlang:element(4, V)}]}.
