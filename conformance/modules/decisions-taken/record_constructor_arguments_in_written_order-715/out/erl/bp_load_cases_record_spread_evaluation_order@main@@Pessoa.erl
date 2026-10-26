-module(bp_load_cases_record_spread_evaluation_order@main@@Pessoa).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, nome) -> erlang:element(2, V);
'__bp_get'(V, idade) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Pessoa", [{"nome", erlang:element(2, V)}, {"idade", erlang:element(3, V)}]}.
