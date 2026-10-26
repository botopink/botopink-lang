-module(std@code@@Lexed).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, toks) -> erlang:element(2, V);
'__bp_get'(V, err) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Lexed", [{"toks", erlang:element(2, V)}, {"err", erlang:element(3, V)}]}.
