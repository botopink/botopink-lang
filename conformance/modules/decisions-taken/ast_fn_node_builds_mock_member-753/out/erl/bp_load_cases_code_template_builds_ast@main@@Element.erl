-module(bp_load_cases_code_template_builds_ast@main@@Element).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, tag) -> erlang:element(2, V);
'__bp_get'(V, kids) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Element", [{"tag", erlang:element(2, V)}, {"kids", erlang:element(3, V)}]}.
