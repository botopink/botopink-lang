-module(bp_load_cases_record_structural_equality@main@@Loose).
-export([equals/2, '__bp_get'/2, '__bp_format'/1]).

equals(Self, Other) ->
    true.

'__bp_get'(V, n) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Loose", [{"n", erlang:element(2, V)}]}.
