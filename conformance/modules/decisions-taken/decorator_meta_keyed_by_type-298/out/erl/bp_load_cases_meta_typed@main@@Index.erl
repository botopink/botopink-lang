-module(bp_load_cases_meta_typed@main@@Index).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, column) -> erlang:element(2, V);
'__bp_get'(V, unique) -> erlang:element(3, V);
'__bp_get'(V, order) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Index", [{"column", erlang:element(2, V)}, {"unique", erlang:element(3, V)}, {"order", erlang:element(4, V)}]}.
