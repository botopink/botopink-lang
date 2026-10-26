-module(std@compiler@@Call).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, callee) -> erlang:element(2, V);
'__bp_get'(V, args) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Call", [{"callee", erlang:element(2, V)}, {"args", erlang:element(3, V)}]}.
