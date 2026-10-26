-module(bp_load_cases_template_method_own_method@main@@Visitor).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, who) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Visitor", [{"who", erlang:element(2, V)}]}.
