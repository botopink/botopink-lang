-module(bp_load_cases_comptime_type_token_handed_on@main@@Users).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, count) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Users", [{"count", erlang:element(2, V)}]}.
