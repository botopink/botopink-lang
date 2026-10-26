-module(bp_load_cases_compiler_decorator_three_kinds@main@@Violation).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, message) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Violation", [{"message", erlang:element(2, V)}]}.
