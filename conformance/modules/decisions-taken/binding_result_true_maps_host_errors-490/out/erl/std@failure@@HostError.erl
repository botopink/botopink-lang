-module(std@failure@@HostError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V);
'__bp_get'(V, name) -> erlang:element(4, V);
'__bp_get'(V, detail) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "HostError", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}, {"name", erlang:element(4, V)}, {"detail", erlang:element(5, V)}]}.
