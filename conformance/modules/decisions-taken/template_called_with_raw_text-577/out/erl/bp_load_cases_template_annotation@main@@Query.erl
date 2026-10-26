-module(bp_load_cases_template_annotation@main@@Query).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, sql) -> erlang:element(2, V);
'__bp_get'(V, params) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Query", [{"sql", erlang:element(2, V)}, {"params", erlang:element(3, V)}]}.
