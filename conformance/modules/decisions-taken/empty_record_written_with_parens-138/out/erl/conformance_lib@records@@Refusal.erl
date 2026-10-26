-module(conformance_lib@records@@Refusal).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, at) -> erlang:element(3, V);
'__bp_get'(V, label) -> erlang:element(4, V);
'__bp_get'(V, frames) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Refusal", [{"message", erlang:element(2, V)}, {"at", erlang:element(3, V)}, {"label", erlang:element(4, V)}, {"frames", erlang:element(5, V)}]}.
