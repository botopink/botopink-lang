-module(std@io@http@@Response).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, status) -> erlang:element(2, V);
'__bp_get'(V, body) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Response", [{"status", erlang:element(2, V)}, {"body", erlang:element(3, V)}]}.
