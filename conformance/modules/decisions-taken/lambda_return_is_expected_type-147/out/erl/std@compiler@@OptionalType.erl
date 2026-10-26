-module(std@compiler@@OptionalType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, inner) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "OptionalType", [{"inner", erlang:element(2, V)}]}.
