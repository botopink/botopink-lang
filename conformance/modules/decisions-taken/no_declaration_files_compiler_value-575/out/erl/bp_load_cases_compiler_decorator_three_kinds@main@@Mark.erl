-module(bp_load_cases_compiler_decorator_three_kinds@main@@Mark).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, text) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Mark", [{"text", erlang:element(2, V)}]}.
