-module(bp_load_cases_template_annotation@main@@Repository).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, statements) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Repository", [{"statements", erlang:element(2, V)}]}.
