-module(bp_load_cases_inline_param_type@main@@BpInline__scaled__props).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, n) -> erlang:element(2, V);
'__bp_get'(V, unit) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "BpInline__scaled__props", [{"n", erlang:element(2, V)}, {"unit", erlang:element(3, V)}]}.
