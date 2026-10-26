-module(std@compiler@@Tuple).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, elems) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Tuple", [{"elems", erlang:element(2, V)}]}.
