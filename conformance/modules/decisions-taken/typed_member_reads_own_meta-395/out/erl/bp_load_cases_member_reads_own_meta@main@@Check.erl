-module(bp_load_cases_member_reads_own_meta@main@@Check).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V);
'__bp_get'(V, rule) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Check", [{"message", erlang:element(2, V)}, {"rule", erlang:element(3, V)}]}.
