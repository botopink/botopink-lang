-module(std@io@fs@@Walked).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, files) -> erlang:element(2, V);
'__bp_get'(V, dangling) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Walked", [{"files", erlang:element(2, V)}, {"dangling", erlang:element(3, V)}]}.
