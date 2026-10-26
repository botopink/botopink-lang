-module(bp_load_cases_comptime_value_or_type_union@main@@Atom).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, initial) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Atom", [{"key", erlang:element(2, V)}, {"initial", erlang:element(3, V)}]}.
