-module(conformance_lib@observe@@Observed).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, snap) -> erlang:element(3, V);
'__bp_get'(V, stderr) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Observed", [{"name", erlang:element(2, V)}, {"snap", erlang:element(3, V)}, {"stderr", erlang:element(4, V)}]}.
