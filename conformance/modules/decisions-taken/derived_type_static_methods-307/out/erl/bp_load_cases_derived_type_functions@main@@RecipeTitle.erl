-module(bp_load_cases_derived_type_functions@main@@RecipeTitle).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "RecipeTitle", [{"title", erlang:element(2, V)}]}.
