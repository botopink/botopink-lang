-module(std@io@http@@Request).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, method) -> erlang:element(2, V);
'__bp_get'(V, url) -> erlang:element(3, V);
'__bp_get'(V, headers) -> erlang:element(4, V);
'__bp_get'(V, body) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Request", [{"method", erlang:element(2, V)}, {"url", erlang:element(3, V)}, {"headers", erlang:element(4, V)}, {"body", erlang:element(5, V)}]}.
