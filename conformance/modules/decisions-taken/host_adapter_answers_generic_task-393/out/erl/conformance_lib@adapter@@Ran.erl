-module(conformance_lib@adapter@@Ran).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, printed) -> erlang:element(2, V);
'__bp_get'(V, failed) -> erlang:element(3, V);
'__bp_get'(V, failure) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Ran", [{"printed", erlang:element(2, V)}, {"failed", erlang:element(3, V)}, {"failure", erlang:element(4, V)}]}.
