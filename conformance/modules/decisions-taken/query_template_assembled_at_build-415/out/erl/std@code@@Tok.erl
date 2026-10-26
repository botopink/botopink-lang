-module(std@code@@Tok).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, kind) -> erlang:element(2, V);
'__bp_get'(V, text) -> erlang:element(3, V);
'__bp_get'(V, hole) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Tok", [{"kind", erlang:element(2, V)}, {"text", erlang:element(3, V)}, {"hole", erlang:element(4, V)}]}.
