-module(bp_load_cases_meta_field_tuple_and_field_key@main@@Sort).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, by) -> erlang:element(2, V);
'__bp_get'(V, keys) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Sort", [{"by", erlang:element(2, V)}, {"keys", erlang:element(3, V)}]}.
