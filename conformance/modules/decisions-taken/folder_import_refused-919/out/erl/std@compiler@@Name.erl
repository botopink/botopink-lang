-module(std@compiler@@Name).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Name", [{"name", erlang:element(2, V)}]}.
