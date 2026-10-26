-module(bp_load_cases_stream_loop_no_failure@main@@Ticker).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, s) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Ticker", [{"s", erlang:element(2, V)}]}.
