-module(bp_load_cases_decorator_decl_pattern@main@@EventHandler).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, event) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "EventHandler", [{"event", erlang:element(2, V)}]}.
