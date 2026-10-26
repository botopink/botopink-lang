-module(conformance_lib@records@@Malformed).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, line) -> erlang:element(2, V);
'__bp_get'(V, reason) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Malformed", [{"line", erlang:element(2, V)}, {"reason", erlang:element(3, V)}]}.
