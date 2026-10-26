-module(bp_load_cases_record_param_on_associated@main@@CardProps).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V);
'__bp_get'(V, featured) -> erlang:element(3, V);
'__bp_get'(V, size) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "CardProps", [{"title", erlang:element(2, V)}, {"featured", erlang:element(3, V)}, {"size", erlang:element(4, V)}]}.
