-module(bp_load_cases_use_conditional_argument@main@@Theme).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, mode) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Theme", [{"mode", erlang:element(2, V)}]}.
