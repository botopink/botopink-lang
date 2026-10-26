-module(bp_load_cases_record_structural_equality@main@@Team).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, lead) -> erlang:element(2, V);
'__bp_get'(V, size) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Team", [{"lead", erlang:element(2, V)}, {"size", erlang:element(3, V)}]}.
