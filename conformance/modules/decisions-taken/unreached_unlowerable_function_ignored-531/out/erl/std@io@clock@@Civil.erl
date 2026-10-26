-module(std@io@clock@@Civil).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, year) -> erlang:element(2, V);
'__bp_get'(V, month) -> erlang:element(3, V);
'__bp_get'(V, day) -> erlang:element(4, V);
'__bp_get'(V, hour) -> erlang:element(5, V);
'__bp_get'(V, minute) -> erlang:element(6, V);
'__bp_get'(V, second) -> erlang:element(7, V);
'__bp_get'(V, weekday) -> erlang:element(8, V).

'__bp_format'(V) -> {record, "Civil", [{"year", erlang:element(2, V)}, {"month", erlang:element(3, V)}, {"day", erlang:element(4, V)}, {"hour", erlang:element(5, V)}, {"minute", erlang:element(6, V)}, {"second", erlang:element(7, V)}, {"weekday", erlang:element(8, V)}]}.
