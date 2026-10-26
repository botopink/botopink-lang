-module(std@compiler@@NamedType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, named) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "NamedType", [{"named", erlang:element(2, V)}]}.
