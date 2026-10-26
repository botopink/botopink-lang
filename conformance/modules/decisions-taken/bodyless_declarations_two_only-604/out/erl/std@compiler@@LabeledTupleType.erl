-module(std@compiler@@LabeledTupleType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, types) -> erlang:element(2, V);
'__bp_get'(V, labels) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "LabeledTupleType", [{"types", erlang:element(2, V)}, {"labels", erlang:element(3, V)}]}.
