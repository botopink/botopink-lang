-module(std@compiler@@Return).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, result) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Return", [{"result", erlang:element(2, V)}]}.
