-module(bp_load_cases_bigint_in_containers@main@@Ledger).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, total) -> erlang:element(2, V);
'__bp_get'(V, last) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Ledger", [{"total", erlang:element(2, V)}, {"last", erlang:element(3, V)}]}.
