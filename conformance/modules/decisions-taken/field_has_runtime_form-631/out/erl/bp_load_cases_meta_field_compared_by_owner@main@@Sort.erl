-module(bp_load_cases_meta_field_compared_by_owner@main@@Sort).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, by) -> erlang:element(2, V);
'__bp_get'(V, then) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Sort", [{"by", erlang:element(2, V)}, {"then", erlang:element(3, V)}]}.
