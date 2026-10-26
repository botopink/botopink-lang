-module(std@io@http@@Header).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, value) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Header", [{"name", erlang:element(2, V)}, {"value", erlang:element(3, V)}]}.
