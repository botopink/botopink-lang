-module(std@compiler@@Unary).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, op) -> erlang:element(2, V);
'__bp_get'(V, operand) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Unary", [{"op", erlang:element(2, V)}, {"operand", erlang:element(3, V)}]}.
