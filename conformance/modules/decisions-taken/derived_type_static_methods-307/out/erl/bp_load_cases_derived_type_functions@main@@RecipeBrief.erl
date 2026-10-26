-module(bp_load_cases_derived_type_functions@main@@RecipeBrief).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V);
'__bp_get'(V, servings) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "RecipeBrief", [{"title", erlang:element(2, V)}, {"servings", erlang:element(3, V)}]}.
