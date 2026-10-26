-module(std@compiler@@Member).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, target) -> erlang:element(2, V);
'__bp_get'(V, member) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Member", [{"target", erlang:element(2, V)}, {"member", erlang:element(3, V)}]}.
