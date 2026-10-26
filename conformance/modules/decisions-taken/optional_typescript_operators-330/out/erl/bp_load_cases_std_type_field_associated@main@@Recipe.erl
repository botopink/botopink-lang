-module(bp_load_cases_std_type_field_associated@main@@Recipe).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Recipe", [{"title", erlang:element(2, V)}]}.
