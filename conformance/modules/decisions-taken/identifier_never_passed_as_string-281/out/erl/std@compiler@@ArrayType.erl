-module(std@compiler@@ArrayType).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, elem) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "ArrayType", [{"elem", erlang:element(2, V)}]}.
