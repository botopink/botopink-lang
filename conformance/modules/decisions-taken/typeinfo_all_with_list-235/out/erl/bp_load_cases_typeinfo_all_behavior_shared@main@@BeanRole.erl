-module(bp_load_cases_typeinfo_all_behavior_shared@main@@BeanRole).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, role) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "BeanRole", [{"role", erlang:element(2, V)}]}.
