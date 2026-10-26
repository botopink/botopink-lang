-module(bp_load_cases_inline_param_type@main@@BpInline__link__props).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, href) -> erlang:element(2, V);
'__bp_get'(V, label) -> erlang:element(3, V);
'__bp_get'(V, external) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "BpInline__link__props", [{"href", erlang:element(2, V)}, {"label", erlang:element(3, V)}, {"external", erlang:element(4, V)}]}.
