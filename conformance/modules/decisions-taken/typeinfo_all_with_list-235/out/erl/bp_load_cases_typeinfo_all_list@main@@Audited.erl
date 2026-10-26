-module(bp_load_cases_typeinfo_all_list@main@@Audited).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, audit) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Audited", [{"audit", erlang:element(2, V)}]}.
