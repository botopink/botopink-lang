-module(bp_load_cases_meta_field_tuple_and_field_key@main@@Span).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, range) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Span", [{"range", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
