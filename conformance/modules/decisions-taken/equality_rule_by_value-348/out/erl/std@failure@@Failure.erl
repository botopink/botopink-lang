-module(std@failure@@Failure).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, kind) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Failure", [{"message", erlang:element(2, V)}, {"kind", erlang:element(3, V)}]}.
