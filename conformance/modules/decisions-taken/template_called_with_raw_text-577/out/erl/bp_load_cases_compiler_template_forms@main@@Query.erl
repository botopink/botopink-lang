-module(bp_load_cases_compiler_template_forms@main@@Query).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, sql) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Query", [{"sql", erlang:element(2, V)}]}.
