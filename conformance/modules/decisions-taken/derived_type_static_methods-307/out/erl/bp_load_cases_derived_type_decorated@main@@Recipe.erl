-module(bp_load_cases_derived_type_decorated@main@@Recipe).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V);
'__bp_get'(V, description) -> erlang:element(3, V);
'__bp_get'(V, servings) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Recipe", [{"title", erlang:element(2, V)}, {"description", erlang:element(3, V)}, {"servings", erlang:element(4, V)}]}.
