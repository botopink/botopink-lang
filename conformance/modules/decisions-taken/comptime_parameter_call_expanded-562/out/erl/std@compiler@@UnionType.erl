-module(std@compiler@@UnionType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, members) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "UnionType", [{"members", erlang:element(2, V)}]}.
