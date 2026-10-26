-module(std@code@@Ps).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, nodes) -> erlang:element(2, V);
'__bp_get'(V, pos) -> erlang:element(3, V);
'__bp_get'(V, err) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Ps", [{"nodes", erlang:element(2, V)}, {"pos", erlang:element(3, V)}, {"err", erlang:element(4, V)}]}.
