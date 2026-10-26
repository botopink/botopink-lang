-module(bp_load_cases_compiler_ordinary_name@main@@Tool).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, compiler) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Tool", [{"compiler", erlang:element(2, V)}]}.
