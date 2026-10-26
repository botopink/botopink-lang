-module(std@compiler@@TupleType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, types) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "TupleType", [{"types", erlang:element(2, V)}]}.
