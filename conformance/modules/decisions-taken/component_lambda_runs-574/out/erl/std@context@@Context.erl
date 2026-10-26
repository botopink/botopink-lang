-module(std@context@@Context).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, contextValue) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Context", [{"contextValue", erlang:element(2, V)}]}.
