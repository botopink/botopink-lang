-module(bp_load_cases_derived_type_functions@main@@Dog).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Dog", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}]}.
