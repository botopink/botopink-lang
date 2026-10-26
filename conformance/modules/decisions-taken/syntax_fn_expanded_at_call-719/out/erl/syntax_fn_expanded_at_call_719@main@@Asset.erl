-module(syntax_fn_expanded_at_call_719@main@@Asset).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, path) -> erlang:element(2, V);
'__bp_get'(V, bytes) -> erlang:element(3, V);
'__bp_get'(V, size) -> erlang:element(4, V);
'__bp_get'(V, hash) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "Asset", [{"path", erlang:element(2, V)}, {"bytes", erlang:element(3, V)}, {"size", erlang:element(4, V)}, {"hash", erlang:element(5, V)}]}.
