-module(std@compiler@@Lit).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Lit", [{"value", erlang:element(2, V)}]}.
