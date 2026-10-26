-module(bp_load_cases_is_fn_narrows_unknown@main@@Clock).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, zone) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Clock", [{"zone", erlang:element(2, V)}]}.
