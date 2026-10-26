-module(std@compiler@@RunFailure).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, kind) -> erlang:element(2, V);
'__bp_get'(V, message) -> erlang:element(3, V);
'__bp_get'(V, output) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "RunFailure", [{"kind", erlang:element(2, V)}, {"message", erlang:element(3, V)}, {"output", erlang:element(4, V)}]}.
