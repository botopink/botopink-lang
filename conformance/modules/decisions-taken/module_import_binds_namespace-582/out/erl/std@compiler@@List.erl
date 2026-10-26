-module(std@compiler@@List).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, items) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "List", [{"items", erlang:element(2, V)}]}.
