-module(bp_load_cases_comptime_optional_fn_tested_against_null@main@@Amount).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, v) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Amount", [{"v", erlang:element(2, V)}]}.
