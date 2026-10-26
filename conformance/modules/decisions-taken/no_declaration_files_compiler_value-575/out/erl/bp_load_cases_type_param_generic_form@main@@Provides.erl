-module(bp_load_cases_type_param_generic_form@main@@Provides).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Provides", [{"name", erlang:element(2, V)}]}.
