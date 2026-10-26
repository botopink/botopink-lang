-module(bp_load_cases_union_narrowed_field_read@main@@A).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, tag) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "A", [{"tag", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
