-module(std@compiler@@Syntax).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, e) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Syntax", [{"e", erlang:element(2, V)}]}.
