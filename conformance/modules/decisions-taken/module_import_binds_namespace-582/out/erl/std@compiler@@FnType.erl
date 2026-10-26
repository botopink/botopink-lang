-module(std@compiler@@FnType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, params) -> erlang:element(2, V);
'__bp_get'(V, returns) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "FnType", [{"params", erlang:element(2, V)}, {"returns", erlang:element(3, V)}]}.
