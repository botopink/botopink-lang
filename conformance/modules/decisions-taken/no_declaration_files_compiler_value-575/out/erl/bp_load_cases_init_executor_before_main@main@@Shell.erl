-module(bp_load_cases_init_executor_before_main@main@@Shell).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Shell", [{"title", erlang:element(2, V)}]}.
