-module(bp_load_cases_type_param_generic_form@main@@Box).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"value", erlang:element(2, V)}]}.
