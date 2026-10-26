-module(bp_load_cases_typeinfo_all_list@main@@Service).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, role) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Service", [{"role", erlang:element(2, V)}]}.
