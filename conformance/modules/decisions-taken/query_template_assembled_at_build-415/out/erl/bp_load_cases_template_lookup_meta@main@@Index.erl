-module(bp_load_cases_template_lookup_meta@main@@Index).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, column) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Index", [{"column", erlang:element(2, V)}]}.
