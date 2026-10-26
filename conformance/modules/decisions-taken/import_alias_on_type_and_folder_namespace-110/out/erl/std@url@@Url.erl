-module(std@url@@Url).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, scheme) -> erlang:element(2, V);
'__bp_get'(V, user) -> erlang:element(3, V);
'__bp_get'(V, password) -> erlang:element(4, V);
'__bp_get'(V, host) -> erlang:element(5, V);
'__bp_get'(V, port) -> erlang:element(6, V);
'__bp_get'(V, path) -> erlang:element(7, V);
'__bp_get'(V, query) -> erlang:element(8, V);
'__bp_get'(V, fragment) -> erlang:element(9, V).

'__bp_format'(V) -> {record, "Url", [{"scheme", erlang:element(2, V)}, {"user", erlang:element(3, V)}, {"password", erlang:element(4, V)}, {"host", erlang:element(5, V)}, {"port", erlang:element(6, V)}, {"path", erlang:element(7, V)}, {"query", erlang:element(8, V)}, {"fragment", erlang:element(9, V)}]}.
