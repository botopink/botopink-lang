-module(std@io@fs@@FileStat).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, size) -> erlang:element(2, V);
'__bp_get'(V, mtime) -> erlang:element(3, V);
'__bp_get'(V, isDir) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "FileStat", [{"size", erlang:element(2, V)}, {"mtime", erlang:element(3, V)}, {"isDir", erlang:element(4, V)}]}.
