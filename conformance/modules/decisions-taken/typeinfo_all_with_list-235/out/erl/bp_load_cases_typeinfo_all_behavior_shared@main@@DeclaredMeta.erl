-module(bp_load_cases_typeinfo_all_behavior_shared@main@@DeclaredMeta).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, value) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "DeclaredMeta", [{"key", erlang:element(2, V)}, {"value", erlang:element(3, V)}]}.
