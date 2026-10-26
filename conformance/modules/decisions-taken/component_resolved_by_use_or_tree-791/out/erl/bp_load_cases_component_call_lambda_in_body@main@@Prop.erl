-module(bp_load_cases_component_call_lambda_in_body@main@@Prop).
-export(['__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

'__bp_get'(V, d) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Prop", [{"d", erlang:element(2, V)}]}.

'__bp_behaviors'() -> ['Renderable'].
