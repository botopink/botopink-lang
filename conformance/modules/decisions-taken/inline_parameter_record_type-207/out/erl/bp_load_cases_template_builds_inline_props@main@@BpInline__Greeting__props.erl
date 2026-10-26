-module(bp_load_cases_template_builds_inline_props@main@@BpInline__Greeting__props).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, greeting) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "BpInline__Greeting__props", [{"name", erlang:element(2, V)}, {"greeting", erlang:element(3, V)}]}.
