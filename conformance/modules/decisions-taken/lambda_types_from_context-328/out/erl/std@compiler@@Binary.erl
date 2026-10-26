-module(std@compiler@@Binary).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, op) -> erlang:element(2, V);
'__bp_get'(V, lhs) -> erlang:element(3, V);
'__bp_get'(V, rhs) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Binary", [{"op", erlang:element(2, V)}, {"lhs", erlang:element(3, V)}, {"rhs", erlang:element(4, V)}]}.
