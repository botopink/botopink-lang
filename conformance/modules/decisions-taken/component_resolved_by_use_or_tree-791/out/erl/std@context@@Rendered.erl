-module(std@context@@Rendered).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, scope) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Rendered", [{"value", erlang:element(2, V)}, {"scope", erlang:element(3, V)}]}.
