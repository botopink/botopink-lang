-module(bp_load_cases_template_in_field_default@main@@Conf).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, label) -> erlang:element(2, V);
'__bp_get'(V, size) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Conf", [{"label", erlang:element(2, V)}, {"size", erlang:element(3, V)}]}.
