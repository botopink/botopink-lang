-module(bp_load_cases_tuple_in_type_parameter_slot@main@@Pair).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, t) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Pair", [{"t", erlang:element(2, V)}]}.
