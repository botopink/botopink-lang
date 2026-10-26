-module(std@io@os@@UserInfo).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, uid) -> erlang:element(2, V);
'__bp_get'(V, username) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "UserInfo", [{"uid", erlang:element(2, V)}, {"username", erlang:element(3, V)}]}.
