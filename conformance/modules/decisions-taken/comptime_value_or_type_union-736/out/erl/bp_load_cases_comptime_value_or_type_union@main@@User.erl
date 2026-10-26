-module(bp_load_cases_comptime_value_or_type_union@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "User", [{"name", erlang:element(2, V)}]}.
