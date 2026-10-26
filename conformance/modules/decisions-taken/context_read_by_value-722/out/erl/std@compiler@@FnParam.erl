-module(std@compiler@@FnParam).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, annotation) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "FnParam", [{"name", erlang:element(2, V)}, {"annotation", erlang:element(3, V)}]}.
