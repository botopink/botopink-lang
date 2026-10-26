-module(bp_load_cases_union_narrowed_field_read@main@@B).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, size) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "B", [{"size", erlang:element(2, V)}]}.
