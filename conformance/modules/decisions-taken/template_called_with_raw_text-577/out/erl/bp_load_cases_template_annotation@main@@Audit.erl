-module(bp_load_cases_template_annotation@main@@Audit).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, level) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Audit", [{"level", erlang:element(2, V)}]}.
