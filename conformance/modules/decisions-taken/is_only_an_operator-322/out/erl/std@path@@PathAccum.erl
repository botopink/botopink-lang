-module(std@path@@PathAccum).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, isAbs) -> erlang:element(2, V);
'__bp_get'(V, parts) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "PathAccum", [{"isAbs", erlang:element(2, V)}, {"parts", erlang:element(3, V)}]}.
