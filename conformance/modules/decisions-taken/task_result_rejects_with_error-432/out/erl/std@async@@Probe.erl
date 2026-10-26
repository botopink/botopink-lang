-module(std@async@@Probe).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Probe", [{"id", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
