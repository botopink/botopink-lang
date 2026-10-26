-module(std@async@@RetryPolicy).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, maxAttempts) -> erlang:element(2, V);
'__bp_get'(V, initialMillis) -> erlang:element(3, V);
'__bp_get'(V, multiplier) -> erlang:element(4, V);
'__bp_get'(V, maxMillis) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "RetryPolicy", [{"maxAttempts", erlang:element(2, V)}, {"initialMillis", erlang:element(3, V)}, {"multiplier", erlang:element(4, V)}, {"maxMillis", erlang:element(5, V)}]}.
