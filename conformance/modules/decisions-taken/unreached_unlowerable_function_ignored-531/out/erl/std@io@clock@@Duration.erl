-module(std@io@clock@@Duration).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, millis) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Duration", [{"millis", erlang:element(2, V)}]}.
