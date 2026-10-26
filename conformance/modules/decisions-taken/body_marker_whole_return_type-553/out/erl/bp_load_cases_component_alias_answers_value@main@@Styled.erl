-module(bp_load_cases_component_alias_answers_value@main@@Styled).
-export(['__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

'__bp_get'(V, className) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Styled", [{"className", erlang:element(2, V)}]}.

'__bp_behaviors'() -> ['Renderable'].
