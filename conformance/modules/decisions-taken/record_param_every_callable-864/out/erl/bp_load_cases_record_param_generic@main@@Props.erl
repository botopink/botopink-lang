-module(bp_load_cases_record_param_generic@main@@Props).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Props", [{"value", erlang:element(2, V)}, {"label", erlang:element(3, V)}]}.
