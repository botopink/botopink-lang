-module(std@compiler@@If).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, 'cond') -> erlang:element(2, V);
'__bp_get'(V, then) -> erlang:element(3, V);
'__bp_get'(V, otherwise) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "If", [{"cond", erlang:element(2, V)}, {"then", erlang:element(3, V)}, {"otherwise", erlang:element(4, V)}]}.
