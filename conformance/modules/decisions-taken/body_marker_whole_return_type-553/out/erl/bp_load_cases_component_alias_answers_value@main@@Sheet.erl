-module(bp_load_cases_component_alias_answers_value@main@@Sheet).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Sheet", [{"name", erlang:element(2, V)}]}.
