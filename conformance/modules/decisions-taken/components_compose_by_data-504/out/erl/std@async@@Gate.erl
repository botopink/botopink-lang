-module(std@async@@Gate).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, handle) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Gate", [{"handle", erlang:element(2, V)}]}.
