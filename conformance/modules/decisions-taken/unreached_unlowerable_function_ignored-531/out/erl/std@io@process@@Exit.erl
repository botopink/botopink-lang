-module(std@io@process@@Exit).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, status) -> erlang:element(2, V);
'__bp_get'(V, stdout) -> erlang:element(3, V);
'__bp_get'(V, stderr) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Exit", [{"status", erlang:element(2, V)}, {"stdout", erlang:element(3, V)}, {"stderr", erlang:element(4, V)}]}.
