-module(bp_load_cases_meta_field_compared_by_owner@main@@Book).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V);
'__bp_get'(V, pages) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Book", [{"title", erlang:element(2, V)}, {"pages", erlang:element(3, V)}]}.
